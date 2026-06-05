#!/usr/bin/env python3
"""
Regenerate Zhou's wife with the same standardized portrait scale as Shen.

Requires:
  GEMINI_API_KEY=<key> python3 tools/regenerate_zhou_wife_gemini.py

Raw green-screen drafts are written to:
  assets/ai_raw/portraits/zhou_wife_standard
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
from dataclasses import dataclass
from pathlib import Path

from portrait_generation_spec import NPC_KNEE_UP_SPEC, fit_subject_to_spec


ROOT = Path(__file__).resolve().parent.parent
PORTRAITS_DIR = ROOT / "assets" / "cn" / "portraits"
RAW_DIR = ROOT / "assets" / "ai_raw" / "portraits" / "zhou_wife_standard"
MODEL = "gemini-2.5-flash-image"

GREEN_BG = """
CRITICAL BACKGROUND REQUIREMENT:
- Use a completely flat, uniform, solid pure high-saturation chroma green background (#00FF00, RGB 0,255,0).
- Zero texture, zero noise, zero variation, zero shadow, zero gradient, no floor plane.
- Do not use bright chroma green anywhere in the character, clothing, hair, skin, accessories, or props.
- No text, no writing, no watermark, no signature, no UI, no decorative border.
"""

STYLE = """
ART STYLE:
- Match the project's semi-realistic Chinese historical anime portrait style.
- Ming Dynasty Jiangnan detective game character portrait, clean linework, soft painterly shading, polished game portrait quality.
- Transparent-ready silhouette with crisp edges after chroma-key removal.
"""

ZHOU_IDENTITY = """
ZHOU'S WIFE IDENTITY:
- Zhou's wife, a 35-year-old Chinese merchant's wife in Ming Dynasty mourning.
- Mature adult woman, not a young heroine and not a teenage face.
- Oval face with slightly prominent cheekbones, sorrowful but sharp almond eyes, downturned outer corners, thin lips, and a worried brow.
- Fair skin with a small tear mole below her left eye. Keep the tear mole subtle but visible in every expression.
- Hair parted near the center and pulled into a simple bun with a plain wooden hairpin; a few loose strands may frame her face.
- Plain white mourning robe with round collar or simple cross-over mourning closure, modest cloth folds, no ornate jewelry, no colorful robe.
- She should read as grief-stricken, suspicious, and strong-willed, not soft, cute, glamorous, or villainous.
"""

SCALE_LOCK = """
STANDARD PORTRAIT SCALE LOCK:
- Output must match Shen Qingyue's standardized portrait specifications: 848x1264 canvas, one knee-up character, visible figure about 96% of canvas height.
- Keep the top of hair close to the top margin and the lower body/robe reaching the bottom edge naturally.
- The camera distance, head size, body size, and overall character footprint must stay consistent across all Zhou's wife expressions.
- Actions and hand gestures may change to match the expression, but they must stay inside the same portrait scale and framing.
- Do not create bust-up, waist-up, hip-up, close-up, full-body, seated, or kneeling portraits.
- Keep hands, sleeves, robe, and knee-line crop inside the canvas.
"""

BASE_PROMPT = """
Create the new canonical standard portrait for Zhou's wife.
Use the supplied Zhou reference as the identity source only: preserve her age, face type, tear mole, mourning robe, hair bun, plain wooden hairpin, and grieving merchant-wife character.
Use the supplied Shen portrait only as the scale/framing reference: same canvas ratio, same knee-up distance, same visible character height, same top and bottom placement. Do not copy Shen's face, hair, pose, robe color, accessories, or personality.
Expression: base grief, red eyes from crying, restrained suspicion under mourning, hands clasping a white handkerchief or robe edge.
"""

VARIANT_RULES = """
IMAGE-TO-IMAGE CONSISTENCY:
- Use the canonical Zhou base portrait as the identity and scale anchor.
- Preserve her face, age, tear mole, hair bun, wooden hairpin, white mourning robe, and overall costume silhouette.
- You may change facial expression, head angle, hands, and upper-body gesture for the target emotion.
- Do not change camera distance, character size, visible height, or knee-up crop.
- Do not copy Shen Qingyue, Lingyao, or any other character.
- Generate one full clean character portrait only.
"""


@dataclass(frozen=True)
class Target:
    key: str
    emotion: str
    prompt: str
    old_reference: str = ""
    use_new_base: bool = True
    temperature: float = 0.25


TARGETS: list[Target] = [
    Target(
        key="prologue_zhou_wife",
        emotion="base",
        use_new_base=False,
        temperature=0.18,
        prompt=BASE_PROMPT,
    ),
    Target(
        key="prologue_zhou_wife_silent",
        emotion="silent_grief",
        old_reference="prologue_zhou_wife_silent.png",
        prompt="""
Silent grief. Eyes downcast, face pale and drawn, lips pressed thin, pain held in rather than shown loudly.
Hands still and restrained, clutching a handkerchief or sleeve. Tear mole visible.
""",
    ),
    Target(
        key="prologue_zhou_wife_screaming",
        emotion="screaming",
        temperature=0.30,
        prompt="""
Screaming in grief and rage. Mouth open, eyes wet, one hand raised in accusation while the other clutches her chest or sleeve.
Raw uncontrolled grief, but keep the same portrait scale and mourning identity. Tear mole visible.
The head, face, neck, shoulders, torso, and robe must stay the same size as the canonical base portrait; this is not a close-up.
""",
    ),
    Target(
        key="prologue_zhou_wife_accusing",
        emotion="accusing",
        old_reference="prologue_zhou_wife_accusing.png",
        temperature=0.28,
        prompt="""
Accusing gesture. One finger points forward, eyes blazing with anger and grief, posture rigid with righteous fury.
Her face is mature and sorrowful, not cute. Tear mole visible.
""",
    ),
    Target(
        key="prologue_zhou_wife_interrogating",
        emotion="interrogating",
        old_reference="prologue_zhou_wife_interrogating.png",
        temperature=0.28,
        prompt="""
Interrogating under pressure. Lean slightly forward within the same framing, eyes sharp and piercing, mouth open mid-question, hands gesturing emphatically.
Suspicion and grief both visible. Tear mole visible.
""",
    ),
    Target(
        key="prologue_zhou_wife_suspicious",
        emotion="suspicious",
        old_reference="prologue_zhou_wife_suspicious.png",
        prompt="""
Suspicious study. Eyes narrowed, head slightly tilted, one eyebrow raised, lips pressed into a thin doubtful line.
Keep a controlled mourning posture and the same figure scale. Tear mole visible.
""",
    ),
    Target(
        key="prologue_zhou_wife_trembling",
        emotion="trembling",
        old_reference="prologue_zhou_wife_trembling.png",
        prompt="""
Trembling with suppressed emotion. Lips quivering, eyes glistening, shoulders tense, hands clasped tightly or shaking near the waist.
Barely holding herself together. Tear mole visible.
""",
    ),
    Target(
        key="prologue_zhou_wife_relieved",
        emotion="relieved",
        prompt="""
Relieved after terrible uncertainty. Eyes still red but softer, lips parted in a quiet breath, shoulders relaxing slightly.
The grief remains, but some tension leaves her face. Tear mole visible.
The head, face, neck, shoulders, torso, and robe must stay the same size as the canonical base portrait; this is not a close-up.
""",
    ),
]


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
    if not (bg[1] > bg[0] + 18 and bg[1] > bg[2] + 18):
        print(f"  raw background is not green-screen-like enough: median={tuple(int(x) for x in bg)}")
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
        print(f"  raw green-screen coverage too low: {coverage:.1%}")
        return False

    data[visited, 0] = 0
    data[visited, 1] = 255
    data[visited, 2] = 0
    data[visited, 3] = 255
    Image.fromarray(data, "RGBA").save(path)
    print(f"  normalized green-screen background to #00FF00 ({coverage:.1%} of image)")
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
        print(f"  pure green border check failed: median={tuple(int(x) for x in med)}")
    return bool(ok)


def call_gemini(api_key: str, parts: list[dict], output_path: Path, temperature: float) -> bool:
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


def clean_alpha_matte(img, low_threshold: int = 24, high_threshold: int = 248):
    import numpy as np
    from PIL import Image

    data = np.array(img.convert("RGBA"))
    alpha = data[:, :, 3]
    data[:, :, 3] = np.where(
        alpha < low_threshold,
        0,
        np.where(alpha > high_threshold, 255, alpha),
    ).astype(np.uint8)
    data[data[:, :, 3] == 0, :3] = 0
    return Image.fromarray(data, "RGBA")


def remove_tiny_alpha_clusters(img):
    import numpy as np
    from scipy import ndimage
    from PIL import Image

    data = np.array(img.convert("RGBA"))
    visible = data[:, :, 3] > 8
    labels, count = ndimage.label(visible)
    if count == 0:
        return Image.fromarray(data)
    sizes = ndimage.sum(visible, labels, range(1, count + 1))
    for label, size in enumerate(sizes, start=1):
        if size < 180:
            data[:, :, 3][labels == label] = 0
            data[:, :, :3][labels == label] = 0
    return Image.fromarray(data)


def largest_alpha_component_bbox(img) -> tuple[int, int, int, int] | None:
    import numpy as np
    from scipy import ndimage

    data = np.array(img.convert("RGBA"))
    visible = data[:, :, 3] > 8
    labels, count = ndimage.label(visible)
    if count == 0:
        return None
    best: tuple[int, int, int, int, int] | None = None
    for label in range(1, count + 1):
        ys, xs = np.where(labels == label)
        if len(xs) == 0:
            continue
        item = (len(xs), int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
        if best is None or item[0] > best[0]:
            best = item
    if best is None:
        return None
    return best[1], best[2], best[3], best[4]


def crop_full_body_to_knee_up_if_needed(img):
    img = img.convert("RGBA")
    bbox = largest_alpha_component_bbox(img)
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    visible_w = right - left
    visible_h = bottom - top
    if visible_w >= int(NPC_KNEE_UP_SPEC.canvas_width * 0.55):
        return img

    knee_bottom = int(round(top + visible_h * 0.79))
    cropped = img.crop((0, 0, img.width, knee_bottom))
    return fit_subject_to_spec(cropped, NPC_KNEE_UP_SPEC)


def fit_to_base_footprint(img, base_path: Path):
    from PIL import Image

    if not base_path.exists():
        return img
    base = Image.open(base_path).convert("RGBA")
    base_bbox = largest_alpha_component_bbox(base)
    bbox = largest_alpha_component_bbox(img)
    if base_bbox is None or bbox is None:
        return img

    target_h = base_bbox[3] - base_bbox[1]
    target_bottom_margin = base.height - base_bbox[3]
    left, top, right, bottom = bbox
    pad = NPC_KNEE_UP_SPEC.crop_padding
    crop_left = max(0, left - pad)
    crop_top = max(0, top - pad)
    crop_right = min(img.width, right + pad)
    crop_bottom = min(img.height, bottom + pad)
    cropped = img.crop((crop_left, crop_top, crop_right, crop_bottom))

    visible_w = right - left
    visible_h = bottom - top
    rel_left = left - crop_left
    rel_bottom = bottom - crop_top
    if visible_h <= 0:
        return img

    scale = min(img.width / cropped.width, target_h / visible_h)
    resized = cropped.resize(
        (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", img.size, (0, 0, 0, 0))
    paste_x = round((img.width - visible_w * scale) / 2 - rel_left * scale)
    paste_y = round(img.height - target_bottom_margin - rel_bottom * scale)
    canvas.paste(resized, (paste_x, paste_y), resized)
    return canvas


def postprocess(raw_path: Path, tmp_final_path: Path, base_path: Path | None) -> bool:
    sys.path.insert(0, str(ROOT / "tools"))
    from defringe_portrait import despill_green_from_hair, remove_chroma_background
    from remove_purple_bg import verify_portrait
    from PIL import Image

    remove_chroma_background(str(raw_path), str(tmp_final_path))
    despill_green_from_hair(str(tmp_final_path), str(tmp_final_path))
    cleaned = remove_tiny_alpha_clusters(Image.open(tmp_final_path).convert("RGBA"))
    fitted = fit_subject_to_spec(cleaned, NPC_KNEE_UP_SPEC)
    fitted = crop_full_body_to_knee_up_if_needed(fitted)
    fitted = remove_tiny_alpha_clusters(fitted)
    if base_path is not None and base_path.exists():
        fitted = fit_to_base_footprint(fitted, base_path)
    fitted = clean_alpha_matte(fitted)
    fitted.save(tmp_final_path)
    return verify_portrait(str(tmp_final_path))


def backup_and_replace(tmp_final_path: Path, final_path: Path, backup_dir: Path, dry_run: bool) -> None:
    if dry_run:
        print(f"  dry-run: would replace {final_path.relative_to(ROOT)}")
        return
    backup_dir.mkdir(parents=True, exist_ok=True)
    if final_path.exists():
        shutil.copy2(final_path, backup_dir / final_path.name)
    shutil.move(str(tmp_final_path), str(final_path))
    print(f"  replaced: {final_path.relative_to(ROOT)}")


def make_prompt(target: Target) -> str:
    if target.use_new_base:
        target_rules = VARIANT_RULES
    else:
        target_rules = "BASE GENERATION: create the canonical Zhou base portrait from the references."
    return "\n".join([
        GREEN_BG,
        STYLE,
        NPC_KNEE_UP_SPEC.framing_prompt,
        ZHOU_IDENTITY,
        SCALE_LOCK,
        target_rules,
        f"TARGET EMOTION: {target.emotion}",
        target.prompt,
    ])


def build_parts(target: Target, base_path: Path) -> list[dict]:
    parts: list[dict] = []
    if target.use_new_base and base_path.exists():
        parts.append({"text": "Reference A: canonical Zhou's wife base portrait. Preserve this identity, face, tear mole, white mourning robe, hair bun, wooden hairpin, and standardized scale."})
        parts.append(inline_image(base_path))
        if target.old_reference:
            old = PORTRAITS_DIR / target.old_reference
            if old.exists():
                parts.append({"text": "Reference B: old expression reference. Use only for emotion/gesture idea; do not copy its old canvas scale, crop, face size, or inconsistent pose."})
                parts.append(inline_image(old))
    else:
        zhou_base = PORTRAITS_DIR / "prologue_zhou_wife.png"
        shen_scale = PORTRAITS_DIR / "prologue_shen_qingyue.png"
        parts.append({"text": "Reference Z: Zhou's wife identity reference. Preserve her face type, tear mole, white mourning robe, hair bun, wooden hairpin, and grieving merchant-wife role. Ignore old canvas size and crop."})
        parts.append(inline_image(zhou_base))
        if shen_scale.exists():
            parts.append({"text": "Reference S: standardized portrait scale reference only. Use this for canvas ratio, knee-up distance, visible character height, top margin, bottom placement, and game portrait footprint. Do not copy identity, clothing, colors, accessories, face, or pose."})
            parts.append(inline_image(shen_scale))

    parts.append({"text": make_prompt(target)})
    return parts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", action="append", help="Generate only specific target key(s). Base always runs first when needed.")
    parser.add_argument("--use-existing-base", action="store_true", help="When --only is used, do not auto-regenerate base before variants.")
    parser.add_argument("--skip-generate", action="store_true", help="Use existing raw drafts and only postprocess/replace.")
    parser.add_argument("--dry-run", action="store_true", help="Generate/postprocess but do not replace final assets.")
    parser.add_argument("--sleep", type=float, default=4.0, help="Delay between Gemini calls.")
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key and not args.skip_generate:
        print("GEMINI_API_KEY is required unless --skip-generate is used.", file=sys.stderr)
        return 2

    stamp = time.strftime("%Y%m%d_%H%M%S")
    backup_dir = PORTRAITS_DIR / f"backup_zhou_wife_standard_{stamp}"
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    requested = set(args.only or [])
    targets = TARGETS
    if requested:
        targets = [
            t for t in TARGETS
            if t.key in requested
            or (
                not args.use_existing_base
                and t.key == "prologue_zhou_wife"
                and any(x != "prologue_zhou_wife" for x in requested)
            )
        ]
        if not targets:
            print(f"No matching targets: {sorted(requested)}", file=sys.stderr)
            return 2

    base_path = PORTRAITS_DIR / "prologue_zhou_wife.png"
    success = 0
    failed = 0

    for idx, target in enumerate(targets, 1):
        final_path = PORTRAITS_DIR / f"{target.key}.png"
        raw_path = RAW_DIR / f"{target.key}_green_raw.png"
        tmp_final_path = RAW_DIR / f"{target.key}_final_tmp.png"
        print(f"\n[{idx}/{len(targets)}] {target.key} ({target.emotion})")

        if not args.skip_generate:
            parts = build_parts(target, base_path)
            if not call_gemini(api_key, parts, raw_path, target.temperature):
                failed += 1
                continue
            time.sleep(args.sleep)
        elif not raw_path.exists():
            print(f"  missing raw draft: {raw_path.relative_to(ROOT)}")
            failed += 1
            continue

        variant_base = base_path if target.use_new_base else None
        if not postprocess(raw_path, tmp_final_path, variant_base):
            print(f"  postprocess/verify failed; keeping draft: {raw_path.relative_to(ROOT)}")
            failed += 1
            continue

        backup_and_replace(tmp_final_path, final_path, backup_dir, args.dry_run)
        if target.key == "prologue_zhou_wife" and not args.dry_run:
            base_path = final_path
        success += 1

    print(f"\nDone: {success} succeeded / {failed} failed")
    if success > 0:
        print(f"Backup dir: {backup_dir.relative_to(ROOT)}")
        print(f"Raw drafts: {RAW_DIR.relative_to(ROOT)}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
