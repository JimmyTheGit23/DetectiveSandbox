# generate-portrait

Generate or regenerate a character portrait using the Gemini API image-to-image workflow with **magenta (#FF00FF) chroma-key** background and **magenta-only despill** algorithm.

## When to Use
- Creating a new character portrait from scratch (with face reference photo)
- Generating emotion variants for an existing character
- Regenerating a character with updated art style or face reference
- Generating confrontation/objection pose portraits
- Any time a character illustration asset is needed

## Workflow

1. **Identify references**: Find existing character portrait in `assets/cn/portraits/` and any face reference photos
2. **Generate via Gemini API**: Use `gemini-2.5-flash-image` with image-to-image, **magenta (#FF00FF) background**
3. **Chroma-key removal**: Apply `tools/remove_purple_bg.py` (magenta-only despill built-in)
4. **Verify**: Run verification script below; ensure `magenta_spill == 0`
5. **Normalize**: Resize to standard canvas (848×1264 for companion, 603×900 for NPC/prologue)
6. **Replace/save**: Put final PNG in `assets/cn/portraits/` with correct naming

## Key Rules
- ALWAYS use **magenta (#FF00FF)** background — NOT green (#00FF00). Green causes more visible spill on dark hair and is harder to despill without affecting skin/clothing colors.
- ALWAYS use existing character portrait as reference (image-to-image) for consistency
- ALWAYS run magenta despill after chroma-key — never skip this step
- ALWAYS verify spill counts before accepting
- Backup existing files before replacing (copy to `backup_<type>_vN/` directory)
- For emotion variants: use the base portrait as sole reference, only describe expression changes

## API Details
- Model: `gemini-2.5-flash-image`
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent`
- responseModalities: `["IMAGE", "TEXT"]`
- Retry on 503 with exponential backoff (20s, 40s, 60s)

## Chroma-Key Algorithm (Magenta-Only Despill)

The improved algorithm has 7 steps:

### Step 1: Corner-based background sampling
```python
# Sample 5px border strips, compute median RGB as background reference
border = concat(top_edge, bottom_edge, left_edge, right_edge)
bg_color = median(border, axis=0)
```

### Step 2: Flood-fill from borders
```python
# BFS from canvas edges; mark connected pixels within threshold of bg_color as background
# Only expand into alpha==0 (already transparent) border pixels, threshold <50
```

### Step 3: Small cluster removal (<3000 px)
```python
# Remove small connected components (Gemini watermarks, noise spots)
# Keep only clusters > 3000 pixels
```

### Step 4: Magenta-only despill (CRITICAL)
```python
# Only correct pixels that are ACTUALLY magenta-tinted:
#   is_magenta = fg & (min(R,B) > G + 8) & (|R-B| < 50)
#
# This distinguishes magenta spill from:
#   - Normal warm skin: R > G > B (NOT magenta, because R >> B)
#   - Blue clothing: B > G > R (NOT magenta, because B >> R)
#   - Brown/dark: R > G >> B (NOT magenta, because R >> B)
#
# Spill correction:
spill_amt = clip((min(R,B) - G - 8) / 40, 0, 1)
r_fix = where(is_magenta, r - (r - g) * spill_amt, r)
b_fix = where(is_magenta, b - (b - g) * spill_amt, b)
```

### Step 5: Zero RGB for fully transparent pixels
```python
# Prevent premultiply bleed on dark backgrounds
data[alpha == 0, :3] = 0
```

### Step 6: Alpha Gaussian blur
```python
# Smooth alpha edges (radius=0.8)
alpha_blurred = GaussianBlur(alpha, radius=0.8)
```

### Step 7: Resize to standard canvas
```python
# Companion: 848×1264 (LANCZOS resampling, bottom-aligned)
# NPC/Prologue: 603×900 (LANCZOS resampling, bottom-aligned)
```

## File Naming
- `companion_{name}.png` - companion base portrait
- `companion_{name}_{emotion}.png` - companion emotion variant
- `companion_{name}_confrontation_normal.png` - confrontation standing pose
- `companion_{name}_confrontation_pose.png` - confrontation dramatic pose
- `prologue_{name}.png` - prologue character portrait
- `prologue_{name}_{emotion}.png` - prologue emotion variant
- `actor_{role}.png` - generic NPC actor

## Verification Script
```python
import numpy as np
from PIL import Image

data = np.array(Image.open("OUTPUT.png").convert("RGBA"))
r, g, b, a = data[:,:,0].astype(int), data[:,:,1].astype(int), data[:,:,2].astype(int), data[:,:,3]
visible = a > 10

# Check for magenta spill residue
is_magenta_spill = visible & (np.minimum(r, b) > g + 8) & (np.abs(r - b) < 50)
magenta_spill = is_magenta_spill.sum()

# Check for pure magenta background residue
pure_magenta = visible & (r > 230) & (g < 30) & (b > 230)
bg_residue = pure_magenta.sum()

assert magenta_spill == 0, f"FAIL: magenta spill = {magenta_spill}"
assert bg_residue == 0, f"FAIL: bg residue = {bg_residue}"
print(f"PASS: magenta_spill={magenta_spill}, bg_residue={bg_residue}")
```

## Prompt Template for Magenta Background
```
Based on this character reference image, generate a new portrait of the SAME character.

CRITICAL BACKGROUND REQUIREMENT:
- The background MUST be a completely flat, uniform, solid pure magenta color (#FF00FF, RGB 255,0,255)
- ZERO texture, ZERO noise, ZERO variation in the background
- Every single pixel in the background area must be EXACTLY (255, 0, 255)
- Do NOT add any patterns, gradients, shadows, or brush strokes to the background
- The background must be perfectly flat and clean like a computer-generated solid fill
- The character must NOT contain this pure magenta color anywhere in clothing or skin

CHARACTER CONSISTENCY (MOST IMPORTANT):
- You MUST preserve the EXACT same character from the reference image
- Same clothing, same colors, same patterns, same hairstyle
- Same face shape, same eye style, same hair color
- This is image-to-image, NOT creating a new character

[Expression/Pose description here]

Upper body portrait, from waist up. Completely flat solid magenta background (#FF00FF, RGB 255,0,255).
```

## Full Documentation
See `docs/CHROMAKEY_REMBG_WORKFLOW.md` for complete algorithm details and troubleshooting.
