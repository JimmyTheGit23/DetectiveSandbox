#!/usr/bin/env python3
"""
Generate Shen Qingyue base portrait by copying the face from
prologue_shen_qingyue_objection_magenta.png exactly, while keeping
the current body (wine-burgundy robe, belt, pouch, raised hand).

Usage:
  GEMINI_API_KEY=<key> python3 tools/generate_shen_face_exact.py
"""

from __future__ import annotations

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

# Key files
FACE_REF = PORTRAITS_DIR / "prologue_shen_qingyue_objection_magenta.png"
BODY_REF = PORTRAITS_DIR / "prologue_shen_qingyue.png"


def inline_image(path: Path) -> dict:
    return {
        "inline_data": {
            "mime_type": "image/png",
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
        print(f"  not green-screen: median={tuple(int(x) for x in bg)}")
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
        push(0, x); push(h - 1, x)
    for y in range(h):
        push(y, 0); push(y, w - 1)
    while q:
        y, x = q.popleft()
        push(y-1, x); push(y+1, x); push(y, x-1); push(y, x+1)

    coverage = float(visited.sum()) / float(h * w)
    if coverage < 0.10:
        print(f"  green coverage too low: {coverage:.1%}")
        return False

    data[visited, 0] = 0; data[visited, 1] = 255; data[visited, 2] = 0; data[visited, 3] = 255
    Image.fromarray(data, "RGBA").save(path)
    print(f"  normalized green ({coverage:.1%})")
    return True


def validate_green_border(path: Path) -> bool:
    import numpy as np
    from PIL import Image
    data = np.array(Image.open(path).convert("RGBA"))
    rgb = data[:, :, :3].astype(np.int16)
    h, w, _ = rgb.shape
    border = np.concatenate([rgb[:4,:,:].reshape(-1,3), rgb[h-4:,:,:].reshape(-1,3),
                             rgb[:,:4,:].reshape(-1,3), rgb[:,w-4:,:].reshape(-1,3)], axis=0)
    med = np.median(border, axis=0)
    ok = med[1] >= 245 and med[0] <= 12 and med[2] <= 12
    if not ok:
        print(f"  green border fail: median={tuple(int(x) for x in med)}")
    return bool(ok)


def postprocess(raw_path, tmp_final):
    from defringe_portrait import despill_green_from_hair, remove_chroma_background
    from remove_purple_bg import verify_portrait
    from PIL import Image
    remove_chroma_background(str(raw_path), str(tmp_final))
    despill_green_from_hair(str(tmp_final), str(tmp_final))
    fitted = fit_subject_to_spec(Image.open(tmp_final).convert("RGBA"), NPC_KNEE_UP_SPEC)
    fitted.save(tmp_final)
    return verify_portrait(str(tmp_final))


def remove_tiny_clusters(img):
    import numpy as np
    from scipy import ndimage
    from PIL import Image
    img = img.convert("RGBA")
    data = np.array(img)
    visible = data[:,:,3] > 8
    labels, count = ndimage.label(visible)
    if count == 0: return img
    sizes = ndimage.sum(visible, labels, range(1, count+1))
    for label, size in enumerate(sizes, start=1):
        if size < 180:
            data[:,:,3][labels==label] = 0
            data[:,:, :3][labels==label] = 0
    return Image.fromarray(data)


def crop_avatar(base_path, avatar_path):
    from PIL import Image
    img = Image.open(base_path).convert("RGBA")
    w, h = img.size
    crop_size = min(w, int(h * 0.35))
    left = (w - crop_size) // 2
    cropped = img.crop((left, 0, left + crop_size, crop_size))
    avatar_path.parent.mkdir(parents=True, exist_ok=True)
    cropped.resize((128, 128), Image.Resampling.LANCZOS).save(avatar_path)
    print(f"  avatar: {avatar_path.relative_to(ROOT)}")


def call_gemini(api_key, parts, output_path, temperature=0.1):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={api_key}"
    payload = {
        "contents": [{"parts": parts}],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": temperature,
            "imageConfig": {"aspectRatio": "2:3"},
        },
    }
    for attempt in range(1, 5):
        try:
            req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"}, method="POST")
            with urllib.request.urlopen(req, timeout=180) as resp:
                if not extract_image(json.loads(resp.read().decode("utf-8")), output_path):
                    return False
                if normalize_green_screen(output_path) and validate_green_border(output_path):
                    return True
                if attempt < 4:
                    time.sleep(15 * attempt)
                    continue
                return False
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace") if exc.fp else ""
            print(f"  HTTP {exc.code}: {exc.reason}")
            if exc.code in {429, 500, 502, 503, 504} and attempt < 4:
                time.sleep(15 * attempt); continue
            print(f"  {body[:500]}")
            return False
        except Exception as exc:
            print(f"  {type(exc).__name__}: {exc}")
            if attempt < 4: time.sleep(15 * attempt); continue
            return False
    return False


def main():
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key:
        print("GEMINI_API_KEY required", file=sys.stderr); return 2

    if not FACE_REF.exists():
        print(f"Face reference not found: {FACE_REF}"); return 2
    if not BODY_REF.exists():
        print(f"Body reference not found: {BODY_REF}"); return 2

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime("%Y%m%d_%H%M%S")
    backup_dir = PORTRAITS_DIR / f"backup_shen_exact_face_{stamp}"

    # Build parts: face ref is DOMINANT, body ref is secondary
    parts = [
        # Reference 0: FACE SOURCE (this is the face we want to COPY)
        {"text": (
            "Reference 0 — FACE AND HAIR CANON (copy this exactly):\n"
            "This is the EXACT face and hairstyle that must appear in the output.\n"
            "Copy her face shape, eye shape, eyebrow shape, nose, lips, expression, "
            "hair style (high bun with crossed hairpins), loose side tendrils, "
            "earrings, clean unmarked skin, and overall facial identity.\n"
            "The face in the output MUST be recognizable as this same woman.\n"
            "Do NOT change her age, face shape, eye shape, or expression.\n"
            "Ignore the pink robe, necklace, magenta background, and hand pose — "
            "only use the FACE and HAIR from this reference."
        )},
        inline_image(FACE_REF),

        # Reference 1: BODY SOURCE (this is the body/clothing we want)
        {"text": (
            "Reference 1 — BODY, CLOTHING, AND POSE (copy this exactly):\n"
            "Copy this portrait's body pose, clothing (wine-burgundy robe with black collar), "
            "leather belt with buckle, medicine pouch, raised left hand gesture, "
            "right arm at side, standing upright posture, and knee-up framing.\n"
            "Do NOT copy the face from this reference — the face comes from Reference 0.\n"
            "Keep the same character scale, canvas framing, and body proportions."
        )},
        inline_image(BODY_REF),

        # Prompt
        {"text": (
            "Create a single character portrait by COMBINING the two references:\n"
            "- FACE and HAIR: copy exactly from Reference 0 (the magenta background portrait). "
            "The face must be the same woman: same oval face, same half-lidded almond eyes, "
            "same thin arched eyebrows, same nose, same lips, same confident expression, "
            "same high bun with crossed hairpins, same two loose side tendrils, "
            "same drop earrings, no beauty mark, no mole, no tear mole, no facial dot.\n"
            "- BODY and CLOTHING: copy exactly from Reference 1 (the wine-burgundy robe portrait). "
            "Keep the wine-burgundy robe, black collar, leather belt, medicine pouch, "
            "raised hand gesture, standing pose, and knee-up framing.\n"
            "- Canvas: exactly 848x1264 pixels, 2:3 ratio.\n"
            "- Character from top of hair to around the knees (knee-up).\n"
            "- Background: flat solid chroma green (#00FF00) for transparency.\n"
            "- Style: semi-realistic Chinese historical anime, clean linework, soft lighting.\n"
            "- This is a hybrid: Reference 0's head on Reference 1's body."
        )},
    ]

    raw_path = RAW_DIR / "shen_exact_face_green_raw.png"
    tmp_final = RAW_DIR / "shen_exact_face_final_tmp.png"

    print("\n[1/1] Generating Shen Qingyue with exact face from objection_magenta...")
    if not call_gemini(api_key, parts, raw_path, temperature=0.1):
        print("  generation failed"); return 1
    time.sleep(4)

    print("\n[postprocess]")
    if not postprocess(raw_path, tmp_final):
        print("  postprocess failed"); return 1

    from PIL import Image
    img = Image.open(tmp_final)
    img = remove_tiny_clusters(img)
    img.save(tmp_final)

    final_path = PORTRAITS_DIR / "prologue_shen_qingyue.png"
    backup_dir.mkdir(parents=True, exist_ok=True)
    if final_path.exists():
        shutil.copy2(final_path, backup_dir / final_path.name)
    shutil.move(str(tmp_final), str(final_path))
    print(f"\n  replaced: {final_path.relative_to(ROOT)}")

    avatar_path = PORTRAITS_DIR / "avatars" / "shen_qingyue.png"
    if avatar_path.exists():
        shutil.copy2(avatar_path, backup_dir / "avatar_shen_qingyue.png")
    crop_avatar(final_path, avatar_path)

    print(f"\nDone! Backup: {backup_dir.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
