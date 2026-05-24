# generate-portrait

Generate or regenerate a character portrait using the Gemini API image-to-image workflow. Follows the complete pipeline: reference preparation → Gemini generation → rembg cutout → green despill → quality verification.

## When to Use
- Creating a new character portrait from scratch (with face reference photo)
- Generating emotion variants for an existing character
- Regenerating a character with updated art style or face reference
- Any time a character illustration asset is needed

## Workflow

1. **Identify references**: Find existing character portrait in `assets/cn/portraits/` and any face reference photos
2. **Generate via Gemini API**: Use `gemini-2.5-flash-image` with image-to-image, green (#00FF00) background
3. **Background removal**: Apply `rembg` to get transparent PNG
4. **Green despill**: Run `tools/defringe_portrait.py --despill-green` to clean hair/edge contamination
5. **Verify**: Ensure `strong_green == 0` and `green_in_dark < 100`
6. **Replace/save**: Put final PNG in `assets/cn/portraits/` with correct naming

## Key Rules
- ALWAYS use existing character portrait as reference (image-to-image) for consistency
- ALWAYS run despill after rembg - never skip this step
- ALWAYS verify green pixel counts before accepting
- Keep `_greenscreen.png` intermediate files until verification passes
- Backup existing files before replacing (`_backup_` prefix)
- For emotion variants: use the base portrait as sole reference, only describe expression changes

## API Details
- Model: `gemini-2.5-flash-image`
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent`
- responseModalities: `["IMAGE", "TEXT"]`
- Retry on 503 with exponential backoff (20s, 40s, 60s)

## File Naming
- `prologue_{name}.png` - main portrait
- `prologue_{name}_{emotion}.png` - emotion variant
- `actor_{role}.png` - generic NPC
- `companion_{name}_{emotion}.png` - companion character

## Verification Script
```python
import numpy as np
from PIL import Image

data = np.array(Image.open("OUTPUT.png").convert("RGBA"))
r, g, b, a = data[:,:,0].astype(int), data[:,:,1].astype(int), data[:,:,2].astype(int), data[:,:,3]
visible = a > 10
strong_green = (visible & (g > r + 25) & (g > b + 25)).sum()
green_in_dark = (visible & (r < 80) & (b < 80) & (g > r + 5) & (g > b + 5)).sum()
assert strong_green == 0 and green_in_dark < 100, f"FAIL: sg={strong_green}, gid={green_in_dark}"
```

## Full Documentation
See `docs/CHARACTER_DESIGN_WORKFLOW.md` section 六B for complete code examples and troubleshooting.
