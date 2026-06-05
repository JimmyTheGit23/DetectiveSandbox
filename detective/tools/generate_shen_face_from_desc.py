#!/usr/bin/env python3
"""
Generate Shen Qingyue portrait with face matching the user's reference image,
described entirely through text prompts (no reference image file needed).

Usage:
  GEMINI_API_KEY=<key> python3 tools/generate_shen_face_from_desc.py
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

GREEN_BG = """
CRITICAL BACKGROUND REQUIREMENT:
- Use a completely flat, uniform, solid pure high-saturation chroma green
  background (#00FF00, RGB 0,255,0).
- ZERO texture, ZERO noise, ZERO variation, ZERO shadow, ZERO gradient.
- No text, no characters, no writing, no watermark, no UI elements.
"""

STYLE = """
ART STYLE:
- Semi-realistic Chinese historical anime portrait style.
- Ming Dynasty Jiangnan detective game character portrait.
- Painterly digital illustration with ink-wash texture influence.
- Clean linework, soft warm front light, subtle rim light.
- Polished game portrait quality.
"""

UNIFIED_SPEC = """
UNIFIED PORTRAIT SPEC (MANDATORY):
- Canvas: exactly 848x1264 pixels, 2:3 aspect ratio.
- Character occupies exactly 80% of canvas height (~1011px).
- Knee-up framing: character from top of hair to around the knees.
- Top margin: ~52px above hair. Bottom margin: ~64px below knees.
- Side padding: at least 64px on each side.
- Standing pose, 3/4 view, weight on feet.
- No sitting, no kneeling, no crouching.
- No full body (no feet/shoes visible).
- No waist-up or bust crop; must show down to knees.
"""

# ── Detailed face description from user's reference image ────────────────────
FACE_DESCRIPTION = """
EXACT FACE AND HAIR DESIGN (match this description precisely):

FACE SHAPE:
- Soft oval face with a gently pointed chin.
- Smooth, refined jawline. Not angular, not round.
- Cheekbones are subtle, not prominent.
- Face reads as early-to-mid 20s, youthful but not childish.

EYES:
- Dark brown/black almond-shaped eyes.
- Slightly downturned at the outer corners (not upturned, not cat-eye).
- Medium size — not large doe-eyes, not narrow slits.
- Subtle natural eyeliner effect on upper lid.
- Calm, confident, slightly appraising gaze.
- Eyelids: single eyelid or very subtle double eyelid.
- Lashes: fine, natural, not heavy or dramatic.

EYEBROWS:
- Thin, slightly arched brows.
- Elegant gentle curve — not straight, not sharply angled.
- Not thick, not sparse. Naturally groomed look.

NOSE:
- Straight nose bridge, medium height.
- Refined tip, not button nose, not hooked.
- Proportional to face.

LIPS:
- Natural pink/rose color.
- Medium fullness — not thin, not overly full.
- Slight confident half-smile, corners barely turned up.
- Lips slightly parted in some expressions.

HAIR (CRITICAL):
- Black hair styled in a HIGH BUN (topknot) on top of the head.
- The bun is adorned with a decorative HAIRPIN/ORNAMENT (silver or jade).
- TWO LOOSE STRANDS/TENDRILS of hair hang down on BOTH SIDES of the face,
  framing the cheeks and jaw. These side tendrils are MANDATORY.
- The side tendrils are slightly wavy/curly, reaching to jaw level.
- Front hair is parted slightly off-center.
- Hair has natural volume and shine, not flat.

EARRINGS:
- Drop earrings (pearl or stone teardrop shape).
- Elegant, not oversized.

EXPRESSION:
- Confident, slightly sly/secretive half-smile.
- Eyes convey intelligence and composure.
- Overall energy: composed, shrewd, attractive but dangerous.
"""

SHEN_BODY = """
SHEN QINGYUE BODY AND CLOTHING:
- A memorable heroine-antagonist, age around 28.
- Tall and poised, refined but dangerous.
- Clothing: wine-burgundy/dark red traditional Chinese robe with black
  scholar/legalist collar and cuffs.
- Dark leather belt with buckle at the waist.
- Small dark herbal medicine pouch and tiny glass herb vial at the belt.
- Left hand raised in a gesturing pose (palm up, fingers slightly spread).
- Right arm relaxed at side.
- Standing upright, 3/4 body angle.
- Mood: cold legal intelligence, controlled elegance.
- No beauty mark, no mole, no tear mole, no facial dot, no freckle.
"""

BASE_PROMPT = """
Create the canonical standard portrait for Shen Qingyue.
- The face and hair MUST match the detailed face description above exactly.
- The body pose, clothing, belt, pouch, and framing MUST match Reference A.
- Pull the camera back to show from top of hair to around the knees.
- Make the head smaller if needed to fit knee-up framing.
- The image is INVALID if it ends at the belt, hip, or thigh.
- She is standing upright, NOT sitting.
- Do not add a beauty mark, mole, tear mole, facial dot, or freckle.
- Generate exactly one clean character portrait.
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
    q = deque()

    def push(y, x):
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


def postprocess(raw_path, tmp_final_path):
    from defringe_portrait import despill_green_from_hair, remove_chroma_background
    from remove_purple_bg import verify_portrait
    from PIL import Image

    remove_chroma_background(str(raw_path), str(tmp_final_path))
    despill_green_from_hair(str(tmp_final_path), str(tmp_final_path))
    fitted = fit_subject_to_spec(Image.open(tmp_final_path).convert("RGBA"), NPC_KNEE_UP_SPEC)
    fitted.save(tmp_final_path)
    return verify_portrait(str(tmp_final_path))


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


def crop_avatar(base_path, avatar_path):
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


def call_gemini(api_key, parts, output_path, temperature=0.15):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={api_key}"
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
                    print(f"  retrying for pure green-screen in {wait}s...")
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--sleep", type=float, default=4.0)
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key:
        print("GEMINI_API_KEY required", file=sys.stderr)
        return 2

    RAW_DIR.mkdir(parents=True, exist_ok=True)

    # Use current portrait as body/pose reference only
    body_ref = PORTRAITS_DIR / "prologue_shen_qingyue.png"
    if not body_ref.exists():
        body_ref = RAW_DIR / "current_body_ref.png"

    stamp = time.strftime("%Y%m%d_%H%M%S")
    backup_dir = PORTRAITS_DIR / f"backup_shen_face_desc_{stamp}"

    parts = [
        {"text": "Reference A: CANONICAL BODY/POSE SOURCE. "
                 "Use this portrait ONLY for body pose, clothing, belt, pouch, "
                 "hand position, robe folds, and overall framing. "
                 "Do NOT copy the face from this reference — the face is described "
                 "in the text prompts below and must match that description exactly."},
        inline_image(body_ref),
        {"text": "\n".join([
            GREEN_BG,
            STYLE,
            UNIFIED_SPEC,
            NPC_KNEE_UP_SPEC.framing_prompt,
            FACE_DESCRIPTION,
            SHEN_BODY,
            BASE_PROMPT,
            "IMAGE-TO-IMAGE RULES:",
            "- The face and hair MUST match the detailed text description exactly.",
            "- The body pose, clothing, belt, pouch MUST match Reference A.",
            "- If text description conflicts with Reference A face, the TEXT WINS.",
            "- Do not add a beauty mark, mole, tear mole, facial dot, or freckle.",
            "- Generate exactly one clean character portrait.",
            "- LOW temperature for maximum consistency with the description.",
        ])},
    ]

    raw_path = RAW_DIR / "prologue_shen_qingyue_face_desc_green_raw.png"
    tmp_final = RAW_DIR / "prologue_shen_qingyue_face_desc_final_tmp.png"

    print("\n[1/1] Generating Shen Qingyue with reference face description...")
    if not call_gemini(api_key, parts, raw_path, temperature=0.15):
        print("  generation failed")
        return 1
    time.sleep(args.sleep)

    print("\n[postprocess]")
    if not postprocess(raw_path, tmp_final):
        print("  postprocess failed")
        return 1

    from PIL import Image
    img = Image.open(tmp_final)
    img = remove_tiny_alpha_clusters(img)
    img.save(tmp_final)

    final_path = PORTRAITS_DIR / "prologue_shen_qingyue.png"
    if not args.dry_run:
        backup_dir.mkdir(parents=True, exist_ok=True)
        if final_path.exists():
            shutil.copy2(final_path, backup_dir / final_path.name)
        shutil.move(str(tmp_final), str(final_path))
        print(f"\n  replaced: {final_path.relative_to(ROOT)}")
        avatar_path = PORTRAITS_DIR / "avatars" / "shen_qingyue.png"
        if avatar_path.exists():
            shutil.copy2(avatar_path, backup_dir / "avatar_shen_qingyue.png")
        crop_avatar(final_path, avatar_path)
    else:
        print(f"\n  dry-run: {tmp_final.relative_to(ROOT)}")

    print(f"\nDone! Backup: {backup_dir.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
