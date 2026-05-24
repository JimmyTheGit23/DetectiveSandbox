# 临川驿案 - Project Rules

## Art Generation Rules (Image Assets)

### API & Tools
- Use **Gemini API** for image generation: `gemini-2.5-flash-image` (supports image-to-image with `responseModalities: ["IMAGE", "TEXT"]`)
- Fallback model: `gemini-2.0-flash` (text-only, no image gen), do NOT use `-exp` suffix models (deprecated)
- API Key: configured in environment or passed directly
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
- Note: `gemini-2.5-flash-image` may return 503 during high demand - implement retry with exponential backoff (15s, 30s, 45s)

### Character Consistency (CRITICAL)
- **All character illustrations MUST use image-to-image generation** to maintain consistency
- When generating a character portrait, ALWAYS provide the existing character portrait(s) as reference input
- Reference images location: `res://assets/cn/portraits/`
- The generated image must match the character's established appearance (face shape, hair style, clothing style)

### Background & Cutout Workflow
1. **Generate with solid color background** - use pure green (`#00FF00`) as default
2. **Choose background color that does NOT appear in the character** - e.g., if character wears green, use magenta (`#FF00FF`) instead
3. **Step 1 - Background removal**: Use `rembg` (AI-based) to remove background → transparent PNG
4. **Step 2 - Green despill (CRITICAL)**: Run aggressive green spill removal algorithm (see below)
5. **Step 3 - Verification**: Check `green_in_dark` pixel count < 100 before accepting

### Green Spill Removal - Known Issue & Solution

**Problem**: When using green screen backgrounds, `rembg` removes the bulk of the background but leaves green contamination in:
- Hair edges and thin strands (most visible on dark/black hair)
- Hairpin and small accessories near the edge
- Semi-transparent edge pixels where green bleeds through
- Dark areas where even a few green channel values are noticeable

**Why simple chroma-key fails**: The green isn't uniform - it mixes with anti-aliased edges, creating pixels that are part-green part-subject. `rembg` preserves these as semi-transparent but doesn't desaturate the green channel.

**Solution - 5-Pass Despill Algorithm** (must run AFTER rembg):
```python
# Pass 1: Remove very-green semi-transparent edge pixels (set alpha=0)
# Pass 2: In dark areas (hair, R<100, B<100), clamp G to max(R, B)
# Pass 3: In medium areas with green shift (G > R+15 and G > B+15), reduce G to avg(R,B)
# Pass 4: Hairpin area (upper 1/3 of image) - same clamp as Pass 2 with lower threshold
# Pass 5: Edge band detection (2px erosion) - clamp G on all edge pixels
```

**Acceptance criteria after despill**:
- `strong_green` (G > R+25 and G > B+25) pixels: **must be 0**
- `green_in_dark` (dark area green tint) pixels: **must be < 100** (ideally < 50)

**Alternative approach if green spill persists**: 
- Use magenta (`#FF00FF`) background instead - less spill on black hair
- But requires same despill logic targeting magenta channel instead

### Art Style Guidelines
- Style: Semi-realistic anime/illustration (半写实古风插画)
- Reference the "assistant" companion character style already in the project
- Characters wear period-appropriate Chinese traditional clothing (Ming Dynasty era)
- Half-body or upper-body composition for portraits
- Clean linework with soft shading
- Consistent lighting (soft front-lit, slight rim light)
- **CRITICAL: Scene backgrounds must NOT contain any Chinese text/characters** — AI-generated Chinese is always garbled. Prompt must explicitly say "NO TEXT, NO CHARACTERS, NO WRITING". Signs/lanterns should be blank or have only abstract weathering.

### File Naming Convention
- Main characters: `prologue_{character_name}.png`
- Character emotions: `prologue_{character_name}_{emotion}.png`
- Actors (generic NPCs): `actor_{role_name}.png`
- Companions: `companion_{name}_{emotion}.png`

### Image Specifications
- Portrait size: approximately 832x1248 (2:3 ratio)
- **Composition: 3/4 body portrait — from head to KNEES** (not just waist/half-body)
- Character should fill ~85% of canvas height (head near top, knees near bottom)
- Character is displayed bottom-aligned in game (lower body flush with screen bottom)
- Format: PNG with transparent background (after cutout)
- Keep arms/hands visible when possible for expressiveness

### Character Reference - 沈清月 (Shen Qingyue)
- **Face**: Based on reference photo - petite oval face, large round doe-like eyes, straight blunt bangs, delicate features, youthful (18-20)
- **Hair**: Black, long flowing with straight bangs; ponytail/half-updo with hairpin accessory
- **Clothing**: Purple-maroon/burgundy (紫红色/酒红色) traditional hanfu/Chinese robe with black collar/trim, brown leather belt, ornamental pouch (荷包)
- **Personality**: Cold, calculating, with hidden depth
- **Expressions needed**: neutral, cold_smile, cracking (showing vulnerability), broken (emotional collapse)
- **Reference files**: `prologue_shen_qingyue.png` (use as image-to-image reference for ALL emotion variants)

## Complete Image Generation Workflow (Step by Step)

```
1. Prepare references:
   - Face reference photo (if establishing new character)
   - Existing character portrait (for emotion variants / consistency)

2. Call Gemini API:
   - Model: gemini-2.5-flash-image
   - Input: reference image(s) + detailed prompt
   - responseModalities: ["IMAGE", "TEXT"]
   - Prompt must specify: SOLID PURE GREEN (#00FF00) background
   
3. Background removal:
   - Tool: rembg (Python: `from rembg import remove`)
   - Input: greenscreen PNG → Output: RGBA PNG
   
4. Green despill (MANDATORY):
   - Run 5-pass despill algorithm
   - Dependencies: PIL/Pillow, numpy, scipy.ndimage
   
5. Verification:
   - Analyze strong_green and green_in_dark pixel counts
   - Accept only if strong_green == 0 and green_in_dark < 100
   
6. Replace target file and keep greenscreen version for re-processing if needed
   - Greenscreen files: `{name}_greenscreen.png` (intermediate, can be deleted after verification)
   - Backup old versions: `_backup_{name}.png`
```
