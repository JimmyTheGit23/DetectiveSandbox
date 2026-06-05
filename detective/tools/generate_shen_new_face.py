#!/usr/bin/env python3
"""
Generate a new Shen Qingyue base portrait using a user-supplied face/hair
reference image, keeping the current body design.

Usage:
  GEMINI_API_KEY=<key> python3 tools/generate_shen_new_face.py \
      --face-ref assets/ai_raw/portraits/shen_qingyue_boss/reference_face.png

The script:
  1. Crops the face/hair region from the reference image
  2. Uses the current portrait as body/pose reference
  3. Calls Gemini image-to-image with unified 848x1264 spec
  4. Post-processes: green screen removal, fit to spec, crop to knee-up
  5. Backs up the old portrait and replaces it
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import shutil
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from portrait_generation_spec import NPC_KNEE_UP_SPEC, fit_subject_to_spec

PORTRAITS_DIR = ROOT / "assets" / "cn" / "portraits"
RAW_DIR = ROOT / "assets" / "ai_raw" / "portraits" / "shen_qingyue_boss"
MODEL = "gemini-2.5-flash-image"
CANVAS = NPC_KNEE_UP_SPEC.canvas  # (848, 1264)

# ── Unified Portrait Spec Prompt ──────────────────────────────────────────────
UNIFIED_SPEC = """
UNIFIED PORTRAIT SPEC (MANDATORY):
- Canvas: exactly 848x1264 pixels, 2:3 aspect ratio.
- Character occupies exactly 80% of canvas height (~1011px).
- Knee-up framing: character from top of hair to around the knees.
- Top margin: ~52px above hair. Bottom margin: ~64px below knees.
- Side padding: at least 64px on each side.
- Head line at 15-18% of canvas height.
- Standing pose, 3/4 view or slight angle, weight on feet.
- No sitting, no kneeling, no crouching, no leaning.
- No full body (no feet/shoes visible).
- No waist-up or bust crop; must show down to knees.
- Transparent-ready silhouette with crisp edges after chroma-key removal.
"""

# ── Background ────────────────────────────────────────────────────────────────
GREEN_BG = """
CRITICAL BACKGROUND REQUIREMENT:
- Use a completely flat, uniform, solid pure high-saturation chroma green
  background (#00FF00, RGB 0,255,0).
- Do NOT use any other shade of green, magenta, purple, or any colored background.
- ZERO texture, ZERO noise, ZERO variation, ZERO shadow, ZERO gradient.
- No text, no characters, no writing, no watermark, no UI elements.
"""

# ── Art Style ─────────────────────────────────────────────────────────────────
STYLE = """
ART STYLE:
- Semi-realistic Chinese historical anime portrait style.
- Ming Dynasty Jiangnan detective game character portrait.
- Painterly digital illustration with ink-wash texture influence.
- Clean linework, soft warm front light, subtle rim light.
- Polished game portrait quality, not rough sketch.
"""

# ── Character Identity ────────────────────────────────────────────────────────
SHEN_IDENTITY = """
SHEN QINGYUE IDENTITY:
- A memorable final-boss heroine-antagonist, age around 28.
- Tall and poised, refined but dangerous. Mature adult woman, not teenage.
- Face: mature narrow oval face, refined cheekbones, straight nose bridge,
  restrained lips, calm sharp eyes. Elegant danger.
- Eyes: narrow almond eyes with slightly lowered lids, long fine lashes,
  calm half-lidded gaze, subtle outer-corner lift. NOT round, NOT big,
  NOT doe-like, NOT angry triangles.
- Eyebrows: slim elegant arched brows, softly curved and controlled.
  NOT thick, NOT straight, NOT harsh.
- Do not draw any beauty mark, mole, tear mole, facial dot, or freckle on her face.
- Hair: black high bun with hair sticks. TWO loose side hair strands/tendrils
  must hang beside the cheeks and jaw, framing both sides of the face.
- Accessory: asymmetrical silver hairpin shaped like a slender medicinal
  snake / herb branch, subtle but iconic.
- Clothing: wine-burgundy robe with black scholar/legalist collar and dark
  leather belt. Subtle restrained darker embroidery, fine trim at collar/cuffs.
- Include a small dark herbal medicine pouch and one tiny glass herb vial
  at the waist belt.
- Mood: cold legal intelligence, controlled venom, elegant menace.
"""

# ── Face Lock ─────────────────────────────────────────────────────────────────
FACE_LOCK = """
FACE AND HAIR LOCK:
- The face MUST match Reference F0 (the face/hair crop from the user reference).
- Preserve her approximate age: about 28 years old, mature and composed.
- Preserve the reference's eye shape, eyebrow shape, eyelid weight, calm gaze,
  nose, lips, and cheek contour.
- Preserve the reference's hair style: high bun with hairpin, two loose side
  tendrils framing the face. These side hair strands are mandatory.
- Do NOT simplify into a generic anime face, younger girl face, or different
  heroine face.
- Do NOT remove the side tendrils.
"""

# ── Body Lock ─────────────────────────────────────────────────────────────────
BODY_LOCK = """
BODY AND POSE LOCK:
- Use the supplied canonical portrait (Reference A) as the body/pose source.
- Preserve: body angle, raised hand gesture, relaxed opposite arm, shoulder
  line, belt, pouch placement, robe folds, and camera framing.
- Preserve the same character scale: head size, shoulder width, belt position,
  hand positions.
- The bottom of the character must reach the knee line. A portrait ending at
  the belt, hip, pouch, upper thigh, or mid-thigh is INVALID.
- Shen Qingyue is standing upright, NOT sitting, NOT kneeling.
- The lower robe must hang vertically from a standing body down to the knee area.
- Keep both hands visible and the lower robe silhouette inside the canvas.
"""

# ── Standard Prompt ───────────────────────────────────────────────────────────
BASE_PROMPT = """
Create the new canonical standard portrait for Shen Qingyue.
- Keep the same raised hand gesture, same body angle, same outfit, same medicine
  pouch, same hair silhouette from Reference A.
- Replace the face and hairstyle to match Reference F0 exactly.
- Pull the camera back and extend the lower robe/body so the character is shown
  from top of hair to around the knees.
- Make the head smaller and the camera farther back if needed to fit knee-up.
- The image is INVALID if it ends at her belt, hip, pouch, upper thigh, or
  mid-thigh; include the standing figure down to the knee area.
- Only clean the expression into a neutral cold appraisal.
- Do not add a beauty mark, mole, tear mole, facial dot, or freckle.
- Generate one full clean character portrait only.
"""


def mime_type(path: Path) -> str:
    return "image/jpeg" if path.suffix.lower() in {".jpg", ".jpeg"} else "image/png"


def inline_image(path: Path) -> dict:
    return {
        "inline_data": {
            "mime_type": mime_type(path),
            "data": base64.b64encode(path.read_bytes()).decode("utf-8"),
        }
    }


def extract_image(result: dict, output_path: Path) -> bool:
    parts = result.get("candidates", [{}])[0].get("content", {}).get("parts", [])
    for part in parts:
        data = part.get("inlineData", part.get("inline_data", {})).get("data")
        if data:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_bytes(base64.b64decode(data))
            print(f"  raw saved: {output_path.relative_to(ROOT)}")
            return True
    print("  no image data in Gemini response")
    return False


def normalize_green_screen(path: Path) -> bool:
    from collections import deque
    import numpy as np
    from PIL import Image

    img = Image.open(path).convert("RGBA")
    data = np.array(img)
    rgb = data[:, :, :3].astype(np.int16)
    h, w, _ = rgb.shape

    border = np.concatenate([
        rgb[:8, :, :].reshape(-1, 3),
        rgb[h - 8:, :, :].reshape(-1, 3),
        rgb[:, :8, :].reshape(-1, 3),
        rgb[:, w - 8:, :].reshape(-1, 3),
    ], axis=0)
    bg = np.median(border, axis=0)
    bg_is_greenish = bg[1] > bg[0] + 18 and bg[1] > bg[2] + 18
    if not bg_is_greenish:
        print(f"  background not green-screen: median={tuple(int(x) for x in bg)}")
        return False

    dist = np.linalg.norm(rgb.astype(np.float32) - bg.astype(np.float32), axis=2)
    greenish = (rgb[:, :, 1] > rgb[:, :, 0] + 10) & (rgb[:, :, 1] > rgb[:, :, 2] + 10)
    candidate = (dist < 86.0) & greenish

    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()

    def push(y: int, x: int) -> None:
        if 0 <= y < h and 0 <= x < w and candidate[y, x] and not visited[y, x]:
            visited[y, x] = True
            q.append((y, x))

    for x in range(w):
        push(0, x)
        push(h - 1, x)
    for y in range(h):
        push(y, 0)
        push(y, w - 1)

    while q:
        y, x = q.popleft()
        push(y - 1, x)
        push(y + 1, x)
        push(y, x - 1)
        push(y, x + 1)

    coverage = float(visited.sum()) / float(h * w)
    if coverage < 0.10:
        print(f"  green-screen coverage too low: {coverage:.1%}")
        return False

    data[visited, 0] = 0
    data[visited, 1] = 255
    data[visited, 2] = 0
    data[visited, 3] = 255
    Image.fromarray(data, "RGBA").save(path)
    print(f"  normalized green-screen ({coverage:.1%})")
    return True


def validate_pure_green_border(path: Path) -> bool:
    import numpy as np
    from PIL import Image

    data = np.array(Image.open(path).convert("RGBA"))
    rgb = data[:, :, :3].astype(np.int16)
    h, w, _ = rgb.shape
    border = np.concatenate([
        rgb[:4, :, :].reshape(-1, 3),
        rgb[h - 4:, :, :].reshape(-1, 3),
        rgb[:, :4, :].reshape(-1, 3),
        rgb[:, w - 4:, :].reshape(-1, 3),
    ], axis=0)
    med = np.median(border, axis=0)
    ok = med[1] >= 245 and med[0] <= 12 and med[2] <= 12
    if not ok:
        print(f"  green border check failed: median={tuple(int(x) for x in med)}")
    return bool(ok)


def postprocess(raw_path: Path, tmp_final_path: Path) -> bool:
    from defringe_portrait import despill_green_from_hair, remove_chroma_background
    from remove_purple_bg import verify_portrait
    from PIL import Image

    remove_chroma_background(str(raw_path), str(tmp_final_path))
    despill_green_from_hair(str(tmp_final_path), str(tmp_final_path))
    fitted = fit_subject_to_spec(Image.open(tmp_final_path).convert("RGBA"), NPC_KNEE_UP_SPEC)
    fitted.save(tmp_final_path)
    return verify_portrait(str(tmp_final_path))


def crop_face_hair_reference(base_path: Path, out_path: Path) -> None:
    """Crop the face and hair region from the reference image."""
    from PIL import Image

    img = Image.open(base_path).convert("RGBA")
    bbox = img.getbbox()
    if bbox is not None:
        img = img.crop(bbox)
    w, h = img.size
    # Crop center 40% width, top 50% height (face + hair)
    crop_w = int(w * 0.50)
    crop_h = int(h * 0.55)
    left = max(0, (w - crop_w) // 2)
    top = 0
    ref = img.crop((left, top, min(w, left + crop_w), min(h, top + crop_h)))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    ref.resize((640, 640), Image.Resampling.LANCZOS).save(out_path)
    print(f"  face/hair ref: {out_path.relative_to(ROOT)}")


def crop_body_reference(base_path: Path, out_path: Path) -> None:
    """Extract the body/pose from the current portrait for reference."""
    from PIL import Image

    img = Image.open(base_path).convert("RGBA")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    # Use the full current portrait as body reference
    img.save(out_path)
    print(f"  body ref: {out_path.relative_to(ROOT)}")


def remove_tiny_alpha_clusters(img):
    import numpy as np
    from scipy import ndimage
    from PIL import Image

    img = img.convert("RGBA")
    data = np.array(img)
    visible = data[:, :, 3] > 8
    labels, count = ndimage.label(visible)
    if count == 0:
        return img
    sizes = ndimage.sum(visible, labels, range(1, count + 1))
    for label, size in enumerate(sizes, start=1):
        if size < 180:
            data[:, :, 3][labels == label] = 0
            data[:, :, :3][labels == label] = 0
    return Image.fromarray(data)


def crop_avatar(base_path: Path, avatar_path: Path) -> None:
    from PIL import Image

    img = Image.open(base_path).convert("RGBA")
    w, h = img.size
    crop_h = int(h * 0.35)
    crop_size = min(w, crop_h)
    left = (w - crop_size) // 2
    cropped = img.crop((left, 0, left + crop_size, crop_size))
    avatar_path.parent.mkdir(parents=True, exist_ok=True)
    cropped.resize((128, 128), Image.Resampling.LANCZOS).save(avatar_path)
    print(f"  avatar: {avatar_path.relative_to(ROOT)}")


def call_gemini(api_key: str, parts: list[dict], output_path: Path,
                temperature: float = 0.18) -> bool:
    url = (f"https://generativelanguage.googleapis.com/v1beta/models/"
           f"{MODEL}:generateContent?key={api_key}")
    payload = {
        "contents": [{"parts": parts}],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": temperature,
            "imageConfig": {"aspectRatio": "2:3"},
        },
    }
    waits = [15, 30, 45]
    for attempt in range(1, 5):
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=180) as resp:
                if not extract_image(json.loads(resp.read().decode("utf-8")), output_path):
                    return False
                if normalize_green_screen(output_path) and validate_pure_green_border(output_path):
                    return True
                if attempt < 4:
                    wait = waits[min(attempt - 1, len(waits) - 1)]
                    print(f"  retrying for pure #00FF00 green-screen in {wait}s...")
                    time.sleep(wait)
                    continue
                return False
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace") if exc.fp else ""
            print(f"  HTTP {exc.code}: {exc.reason}")
            if exc.code in {429, 500, 502, 503, 504} and attempt < 4:
                wait = waits[min(attempt - 1, len(waits) - 1)]
                print(f"  retrying in {wait}s...")
                time.sleep(wait)
                continue
            print(f"  response: {body[:800]}")
            return False
        except Exception as exc:
            print(f"  request failed: {type(exc).__name__}: {exc}")
            if attempt < 4:
                wait = waits[min(attempt - 1, len(waits) - 1)]
                print(f"  retrying in {wait}s...")
                time.sleep(wait)
                continue
            return False
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate new Shen Qingyue portrait with updated face")
    parser.add_argument("--face-ref", required=True,
                        help="Path to the new face/hair reference image")
    parser.add_argument("--dry-run", action="store_true",
                        help="Generate but do not replace final assets")
    parser.add_argument("--skip-generate", action="store_true",
                        help="Use existing raw draft and only postprocess")
    parser.add_argument("--sleep", type=float, default=4.0)
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key and not args.skip_generate:
        print("GEMINI_API_KEY is required.", file=sys.stderr)
        return 2

    face_ref_path = Path(args.face_ref).resolve()
    if not face_ref_path.exists():
        print(f"Reference image not found: {face_ref_path}", file=sys.stderr)
        return 2

    stamp = time.strftime("%Y%m%d_%H%M%S")
    backup_dir = PORTRAITS_DIR / f"backup_shen_new_face_{stamp}"
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    # Prepare references
    face_hair_ref = RAW_DIR / "new_face_hair_ref.png"
    crop_face_hair_reference(face_ref_path, face_hair_ref)

    current_portrait = PORTRAITS_DIR / "prologue_shen_qingyue.png"
    body_ref = RAW_DIR / "current_body_ref.png"
    crop_body_reference(current_portrait, body_ref)

    # Build Gemini prompt
    parts = [
        {"text": "Reference F0: NEW face/hair canon for Shen Qingyue. "
                 "Match this exact face shape, eye shape, eyebrow shape, nose, lips, "
                 "cheek contour, hair style (high bun with hairpin, two loose side tendrils), "
                 "drop earrings, and expression. "
                 "Use ONLY the face and hair; do NOT copy the background color, "
                 "pose, hands, clothing, or jewelry from this reference."},
        inline_image(face_hair_ref),
        {"text": "Reference F1: Full face/hair source for identity confirmation. "
                 "Preserve eyes, brows, age, side hair strands, and overall face energy. "
                 "Ignore pose, hands, color, jewelry, and background."},
        inline_image(face_ref_path),
        {"text": "Reference A: CANONICAL BODY/POSE SOURCE. "
                 "Prespose this exact full portrait: same canvas, same character size, "
                 "same raised-hand pose, same belt and pouch placement, same robe, "
                 "same framing. Only change the face and hair to match Reference F0."},
        inline_image(body_ref),
        {"text": "\n".join([
            GREEN_BG,
            STYLE,
            UNIFIED_SPEC,
            NPC_KNEE_UP_SPEC.framing_prompt,
            SHEN_IDENTITY,
            FACE_LOCK,
            BODY_LOCK,
            BASE_PROMPT,
            "IMAGE-TO-IMAGE RULES:",
            "- The face and hair MUST match Reference F0 exactly.",
            "- The body pose, clothing, belt, pouch, and framing MUST match Reference A.",
            "- If any text instruction conflicts with a reference image, the reference wins.",
            "- Do not add a beauty mark, mole, tear mole, facial dot, or freckle.",
            "- Generate exactly one clean character portrait.",
        ])},
    ]

    raw_path = RAW_DIR / "prologue_shen_qingyue_new_face_green_raw.png"
    tmp_final_path = RAW_DIR / "prologue_shen_qingyue_new_face_final_tmp.png"

    if not args.skip_generate:
        print(f"\n[1/1] Generating new Shen Qingyue portrait...")
        if not call_gemini(api_key, parts, raw_path, temperature=0.18):
            print("  generation failed")
            return 1
        time.sleep(args.sleep)
    elif not raw_path.exists():
        print(f"  missing raw draft: {raw_path.relative_to(ROOT)}")
        return 1

    print(f"\n[postprocess]")
    if not postprocess(raw_path, tmp_final_path):
        print("  postprocess/verify failed")
        return 1

    # Remove isolated noise before saving.
    from PIL import Image
    img = Image.open(tmp_final_path)
    img = remove_tiny_alpha_clusters(img)
    img.save(tmp_final_path)

    if not args.dry_run:
        final_path = PORTRAITS_DIR / "prologue_shen_qingyue.png"
        backup_dir.mkdir(parents=True, exist_ok=True)
        if final_path.exists():
            shutil.copy2(final_path, backup_dir / final_path.name)
        shutil.move(str(tmp_final_path), str(final_path))
        print(f"\n  replaced: {final_path.relative_to(ROOT)}")

        # Generate avatar
        avatar_path = PORTRAITS_DIR / "avatars" / "shen_qingyue.png"
        if avatar_path.exists():
            shutil.copy2(avatar_path, backup_dir / "avatar_shen_qingyue.png")
        crop_avatar(final_path, avatar_path)
    else:
        print(f"\n  dry-run: output at {tmp_final_path.relative_to(ROOT)}")

    print(f"\nDone!")
    print(f"Raw draft: {raw_path.relative_to(ROOT)}")
    if not args.dry_run:
        print(f"Backup: {backup_dir.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
