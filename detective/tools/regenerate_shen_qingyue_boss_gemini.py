#!/usr/bin/env python3
"""
Regenerate Shen Qingyue as a more distinctive boss portrait set using Gemini
image-to-image, then remove the magenta key background and replace the existing
project assets non-destructively.

Requires:
  GEMINI_API_KEY=<key> python3 tools/regenerate_shen_qingyue_boss_gemini.py

The script writes raw magenta drafts to assets/ai_raw/portraits/shen_qingyue_boss
and backs up replaced portraits under assets/cn/portraits/backup_shen_qingyue_boss_<timestamp>.
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
RAW_DIR = ROOT / "assets" / "ai_raw" / "portraits" / "shen_qingyue_boss"
MODEL = "gemini-2.5-flash-image"
CANVAS = NPC_KNEE_UP_SPEC.canvas
SHARP_SEED_NAME = "prologue_shen_qingyue_sharp.png"
FACE_SEED_NAME = "prologue_shen_qingyue_objection_magenta.png"

GREEN_BG = """
CRITICAL BACKGROUND REQUIREMENT:
- Shen Qingyue's clothing is wine-burgundy/red-purple, so the chroma key MUST be maximum-contrast pure green.
- Use a completely flat, uniform, solid pure high-saturation chroma green background (#00FF00, RGB 0,255,0).
- Do not use sage green, olive green, moss green, pale green, gray-green, yellow-green, painterly green, or any desaturated green.
- ZERO texture, ZERO noise, ZERO variation, ZERO shadow, ZERO gradient in the background.
- Do not use bright chroma green anywhere in the character, clothing, hair, skin, accessories, or props.
- No text, no characters, no writing, no watermark, no signature, no UI, no decorative border.
"""

BOSS_IDENTITY = """
NEW SHEN QINGYUE BOSS IDENTITY:
- A memorable final-boss heroine-antagonist, not a soft heroine face.
- Age around 28, tall and poised, refined but dangerous. She should read as a mature adult woman, not a teenage heroine and not early-20s ingenue.
- Face: use the standardized base portrait as the exact face canon: mature narrow oval face, refined cheekbones, straight nose bridge, restrained lips, calm sharp eyes, and elegant danger.
- Eyes: match the reference eyes closely: narrow almond eyes with slightly lowered lids, long fine lashes, calm half-lidded gaze, subtle outer-corner lift, not round, not big, not doe-like, not angry triangles.
- Eyebrows: match the reference eyebrows closely: slim elegant arched brows, softly curved and controlled, not thick, not straight, not harsh.
- Do not draw any beauty mark, mole, tear mole, facial dot, or freckle on her face.
- Avoid round doe eyes, a soft small oval face, innocent expression, widow-like grief, heroine warmth, or any face template that reads as Lingyao/young heroine/tragic widow.
- Hair: black high bun with hair sticks, based on the standardized base portrait. Two loose side hair strands/tendrils must hang beside the cheeks and jaw, framing both sides of the face. Keep the mature side-parted front hair and wispy cheek locks; no short bob, no blunt bangs, no missing side tendrils.
- Accessory: asymmetrical silver hairpin shaped like a slender medicinal snake / herb branch, subtle but iconic.
- Clothing: keep the established wine-burgundy robe with black scholar/legalist collar and dark leather belt, but add subtle refined decoration: restrained darker embroidery, fine trim at collar/cuffs/hem, and a slightly richer merchant texture. Do not overdecorate.
- Include a small dark herbal medicine pouch and one tiny glass herb vial / medicine bottle at the waist belt; no readable labels.
- Mood: cold legal intelligence, controlled venom, elegant menace, hidden grief under discipline. She should feel dry, incisive, efficient, and socially dangerous rather than warm, sorrowful, nurturing, or romantic.
"""

FACE_LOCK = """
FACE AND HAIR LOCK:
- The face must be recognizable as the woman in the standardized base portrait.
- Preserve her approximate age: about 28 years old, mature and composed.
- Preserve the reference's eye shape, eyebrow shape, eyelid weight, calm gaze, nose, lips, and cheek contour.
- Preserve the reference's two loose side tendrils framing the face. These side hair strands are mandatory.
- Do not simplify her into a generic anime face, younger girl face, stern masculine face, or a different heroine face.
- Do not remove the side tendrils; do not replace them with a bob haircut or blunt bangs.
"""

STYLE = """
ART STYLE:
- Match the project's existing semi-realistic Chinese historical anime portrait style.
- Ming Dynasty Jiangnan detective game character portrait, painterly digital illustration with ink-wash texture.
- Clean linework, soft warm front light, subtle rim light, polished game portrait quality.
- Use the locked portrait framing spec below exactly.
- Transparent-ready silhouette with crisp edges after chroma-key removal.
"""

POSE_LOCK = """
CANONICAL POSE LOCK:
- Use the supplied canonical Shen Qingyue portrait as the single image-to-image source.
- Treat the source portrait as an edit target, not loose inspiration.
- Shen Qingyue is standing upright. She is NOT sitting, kneeling, crouching, leaning on a chair, or resting on any seat.
- Preserve the same body angle, raised right-hand gesture, relaxed opposite arm, shoulder line, belt, pouch placement, hair silhouette, and camera framing.
- Preserve the same visible character scale: hair top, eye line, shoulder line, belt line, hand positions, and knee cutoff must stay at the same canvas coordinates.
- Do not invent a new pose, do not cross the arms, do not add an umbrella, do not change the hands, and do not move the medicine pouch.
- Variants may change only the facial expression and very small facial tension. The body pose, outfit, hair, and framing must remain the same.
"""

STRICT_I2I_LOCK = """
STRICT IMAGE-TO-IMAGE CONSISTENCY:
- Output must look like the same base image with only facial expression edited.
- Keep canvas ratio, camera distance, head size, body size, and knee-up crop identical to the reference.
- Keep the same transparent-ready silhouette and character footprint; no taller, shorter, larger, smaller, closer, or farther figure.
- Keep the raised hand, sleeves, belt, pouch, robe folds, shoulders, torso angle, and lower-body cutoff unchanged.
- Do not use any old expression portrait as a composition source. Do not remix the pose from memory.
- If a requested expression would require changing the pose, ignore that pose change and keep the base pose.
"""

BASE_FROM_SHARP_LOCK = """
STANDARD BASE FROM SHARP:
- Use the sharp portrait as the identity and upper-body pose reference only.
- The sharp source is cropped too close; do NOT preserve its hip/thigh cutoff.
- Pull the camera back and extend the lower robe/body naturally until the portrait reaches around the knees.
- The bottom of the character must reach the knee line. A portrait ending at the belt, hip, pouch, upper thigh, or mid-thigh is invalid.
- Make the head and upper body smaller if necessary so the standing figure fits from hair top to knees.
- Shen Qingyue is standing upright, weight on her feet, not seated.
- The lower robe must hang vertically from a standing body down to the knee area.
- Show enough lower robe below the belt that the knees are clearly implied or visible under the robe silhouette.
- Do not draw a seated lap, bent seated thighs, diagonal skirt spread, chair, stool, bench, cushion, or any seated pose cue.
- Keep the same raised-hand gesture, torso angle, belt, pouch, robe palette, hair, face, and cold merchant-boss identity.
- The final standard base must be a true knee-up portrait, not waist-up, not hip-up, not mid-thigh.
- Keep both hands visible and keep the lower robe silhouette inside the canvas.
"""


@dataclass(frozen=True)
class Target:
    key: str
    emotion: str
    prompt: str
    old_pose_reference: str = ""
    use_new_base: bool = True
    temperature: float = 0.25


TARGETS: list[Target] = [
    Target(
        key="prologue_shen_qingyue",
        emotion="base",
        use_new_base=False,
        temperature=0.18,
        prompt="""
Create the new canonical standard portrait from the supplied sharp portrait.
Keep the same raised hand gesture, same body angle, same outfit, same medicine pouch, same hair silhouette, and same face design from the sharp reference.
Pull the camera back and extend the lower robe/body so the character is shown from top of hair to around the knees.
The image is invalid if it ends at her belt, hip, pouch, upper thigh, or mid-thigh; include the standing figure down to the knee area.
Make the head smaller and the camera farther back if needed.
She is standing upright, not sitting; the lower robe hangs naturally and vertically from a standing body.
No seated lap, no bent seated thighs, no slanted seated skirt, no chair or seat.
The face must match the standardized Shen identity: about 28 years old, narrow half-lidded eyes, slim arched eyebrows, mature calm expression, clean unmarked skin, and two loose side tendrils beside the cheeks.
Only clean the expression into a neutral cold appraisal. Do not add a beauty mark, mole, tear mole, facial dot, or freckle. Do not redesign her.
""",
    ),
    Target(
        key="prologue_shen_qingyue_confrontation",
        emotion="confrontation",
        old_pose_reference="prologue_shen_qingyue_confrontation.png",
        prompt="""
Final confrontation portrait.
Expression: calm legal pressure, cold focus, a faint threat in the eyes.
Keep the new base identity and canonical pose exactly: same face, hair, hairpin, robe palette, belt pouch, raised hand, body angle, and framing.
""",
    ),
    Target(
        key="prologue_shen_qingyue_bold",
        emotion="bold",
        old_pose_reference="prologue_shen_qingyue_bold.png",
        temperature=0.22,
        prompt="""
Public merchant mask.
Expression: bold, fearless, slightly amused challenge; not cute, not cheerful.
Keep the new base identity and canonical pose exactly.
""",
    ),
    Target(
        key="prologue_shen_qingyue_cooperative",
        emotion="cooperative",
        old_pose_reference="prologue_shen_qingyue_cooperative.png",
        prompt="""
False cooperation mask.
Expression: courteous smile that does not reach the eyes, calculating and controlled.
Keep the new base identity and canonical pose exactly.
""",
    ),
    Target(
        key="prologue_shen_qingyue_cold_smile",
        emotion="cold_smile",
        old_pose_reference="prologue_shen_qingyue_cold_smile.png",
        prompt="""
Cold smile expression.
Expression: a thin icy smile, one eyebrow barely raised, eyes narrow and predatory.
Keep the new base identity and canonical pose exactly.
""",
    ),
    Target(
        key="prologue_shen_qingyue_sharp",
        emotion="sharp",
        old_pose_reference="prologue_shen_qingyue_sharp.png",
        prompt="""
Sharp legal rebuttal portrait.
Expression: narrow phoenix eyes, cutting gaze, lips firm as if delivering a legal trap.
Keep the new base identity and canonical pose exactly.
""",
    ),
    Target(
        key="prologue_shen_qingyue_deflecting",
        emotion="deflecting",
        old_pose_reference="prologue_shen_qingyue_deflecting.png",
        prompt="""
Deflecting and evasive portrait.
Expression: side glance, controlled irritation, hiding a calculation.
Keep the new base identity and canonical pose exactly.
""",
    ),
    Target(
        key="prologue_shen_qingyue_cold_fury",
        emotion="cold_fury",
        old_pose_reference="prologue_shen_qingyue_cold_fury.png",
        temperature=0.28,
        prompt="""
True boss mask slipping.
Expression: cold fury, eyes bright and blade-like, smile gone, anger controlled rather than explosive.
Keep the new base identity and canonical pose exactly.
""",
    ),
    Target(
        key="prologue_shen_qingyue_cracking",
        emotion="cracking",
        old_pose_reference="prologue_shen_qingyue_cracking.png",
        temperature=0.28,
        prompt="""
Cracking under pressure.
Expression: the legal mask fractures; lips slightly parted, eyes tense, grief visible for one second.
Keep the new base identity and canonical pose exactly.
""",
    ),
    Target(
        key="prologue_shen_qingyue_broken",
        emotion="broken",
        old_pose_reference="prologue_shen_qingyue_broken.png",
        temperature=0.28,
        prompt="""
Emotional collapse after the father motive is exposed.
Expression: exhausted, hollow-eyed, restrained tears without melodrama.
Keep the new base identity and canonical pose exactly.
""",
    ),
    Target(
        key="prologue_shen_qingyue_victory",
        emotion="victory",
        old_pose_reference="prologue_shen_qingyue_victory.png",
        temperature=0.22,
        prompt="""
Victory through legal loophole.
Expression: faint tired victory smile, calm superiority, one last unreadable glance.
Keep the new base identity and canonical pose exactly. Do not add an umbrella or prop.
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
    """Force a generated green-screen background to exact #00FF00 before cutout."""
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


def postprocess(raw_path: Path, tmp_final_path: Path, align_to_base: bool = True) -> bool:
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
    if align_to_base:
        fitted = fit_to_base_footprint(fitted)
    fitted = remove_inner_background_residue(fitted)
    fitted = remove_hair_tip_background_residue(fitted)
    fitted = clean_alpha_matte(fitted)
    fitted.save(tmp_final_path)
    return verify_portrait(str(tmp_final_path))


def clean_alpha_matte(img, low_threshold: int = 24, high_threshold: int = 248):
    """Remove low-alpha haze and clear RGB under fully transparent pixels."""
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


def remove_inner_background_residue(img):
    """Remove non-edge background islands trapped between Shen's torso and right sleeve."""
    import numpy as np
    from scipy import ndimage
    from PIL import Image

    data = np.array(img.convert("RGBA"))
    rgb = data[:, :, :3].astype(np.int16)
    alpha = data[:, :, 3]

    h, w = alpha.shape
    region = np.zeros((h, w), dtype=bool)
    # The standardized Shen pose leaves a negative-space hole around the waist/right sleeve.
    # Gemini sometimes paints that inner background tan instead of pure green, so flood fill
    # cannot reach it. Keep this region narrow to avoid touching face, hand, belt, or pouch.
    region[730:min(970, h), 470:min(660, w)] = True

    max_rgb = rgb.max(axis=2)
    min_rgb = rgb.min(axis=2)
    saturation = max_rgb - min_rgb
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    candidate = (
        region
        & (alpha > 20)
        & (max_rgb > 105)
        & (saturation < 95)
        & (r > 75)
        & (g > 70)
        & (b > 55)
        # Exclude burgundy robe folds: they are redder and darker than the painted background island.
        & ~((r > g + 30) & (r > b + 25))
    )

    labels, count = ndimage.label(candidate)
    for label in range(1, count + 1):
        ys, xs = np.where(labels == label)
        if len(xs) < 260:
            continue
        x1, y1, x2, y2 = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
        if (y2 - y1) < 24 or (x2 - x1) < 12:
            continue
        data[:, :, 3][labels == label] = 0
        data[:, :, :3][labels == label] = 0

    return Image.fromarray(data, "RGBA")


def remove_hair_tip_background_residue(img):
    """Remove tiny low-saturation background slivers trapped on Shen's left hair tips."""
    import numpy as np
    from scipy import ndimage
    from PIL import Image, ImageFilter

    data = np.array(img.convert("RGBA"))
    rgb = data[:, :, :3].astype(np.int16)
    alpha = data[:, :, 3]
    h, w = alpha.shape

    region = np.zeros((h, w), dtype=bool)
    # Standardized Shen head position: this is outside the face, near the left
    # hair/tendril contour where Gemini sometimes leaves tan/gray chroma residue.
    region[235:min(325, h), 245:min(330, w)] = True

    transparent = alpha < 8
    edge_band = np.array(
        Image.fromarray((transparent.astype(np.uint8) * 255), "L").filter(ImageFilter.MaxFilter(size=13))
    ) > 0
    max_rgb = rgb.max(axis=2)
    min_rgb = rgb.min(axis=2)
    saturation = max_rgb - min_rgb
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    core = (
        region
        & edge_band
        & (alpha > 20)
        & (max_rgb > 105)
        & (max_rgb < 235)
        & (saturation < 95)
        & (r > 80)
        & (g > 70)
        & (b > 55)
        # Exclude warm facial skin; target the flatter gray/tan artifact.
        & ~((r > g + 42) & (r > b + 55))
    )

    labels, count = ndimage.label(core)
    keep = np.zeros(core.shape, dtype=bool)
    for label in range(1, count + 1):
        ys, xs = np.where(labels == label)
        size = len(xs)
        if size < 12 or size > 500:
            continue
        x1, y1, x2, y2 = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
        if (x2 - x1) > 35 or (y2 - y1) > 65:
            continue
        keep[labels == label] = True

    if not np.any(keep):
        return img

    dilated = np.array(
        Image.fromarray((keep.astype(np.uint8) * 255), "L").filter(ImageFilter.MaxFilter(size=5))
    ) > 0
    fringe_ok = (
        region
        & (alpha > 0)
        & (max_rgb > 65)
        & (saturation < 130)
        & (r > 50)
        & (g > 45)
        & (b > 38)
    )
    final = keep | (dilated & fringe_ok)
    data[:, :, 3][final] = 0
    data[:, :, :3][final] = 0
    return Image.fromarray(data, "RGBA")


def fit_to_base_footprint(img):
    """Match expression variants to the standardized base portrait's visible height and bottom."""
    from PIL import Image

    base_path = PORTRAITS_DIR / "prologue_shen_qingyue.png"
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
    """Gemini may obey standing but return a full-body figure; crop it back to knee-up."""
    img = img.convert("RGBA")
    bbox = img.getbbox()
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
    pose_rules = BASE_FROM_SHARP_LOCK if not target.use_new_base else "\n".join([POSE_LOCK, STRICT_I2I_LOCK])
    return "\n".join([
        GREEN_BG,
        STYLE,
        NPC_KNEE_UP_SPEC.framing_prompt,
        BOSS_IDENTITY,
        FACE_LOCK,
        pose_rules,
        f"TARGET EMOTION: {target.emotion}",
        target.prompt,
        """
IMAGE-TO-IMAGE RULES:
- Keep the same project style and the canonical Shen Qingyue identity.
- Use the supplied canonical portrait as the only body, clothing, camera, and pose source.
- If any text instruction conflicts with the reference pose or reference framing, the reference image wins.
- Exception for the standard base only: the sharp source crop may be too close, so the standard base must pull back to the locked knee-up framing.
- Do not add a beauty mark, mole, tear mole, facial dot, or freckle in any variant.
- Avoid resemblance to the heroine Lingyao or Zhou's wife: no round heroine eyes, no innocent softness, no grieving widow look, no soft sympathetic wife face.
- Keep Shen clearly distinct from both Lingyao and Zhou's wife: longer face, sharper cheekbones, thinner lips, cooler eyes, more androgynous, more severe, more merchant-sharp, less nurturing, less tragic.
- Generate one full clean character portrait only.
""",
    ])


def build_parts(target: Target, base_path: Path | None) -> list[dict]:
    parts: list[dict] = []
    if target.use_new_base and base_path is not None and base_path.exists():
        face_ref_path = RAW_DIR / f"{base_path.stem}_face_ref.png"
        crop_face_reference(base_path, face_ref_path)
        parts.append({"text": "Reference A0: canonical Shen Qingyue face lock. Match this exact face shape, eye shape, nose bridge, lip shape, clean unmarked skin, hairline, and severe expression energy. Use only for facial identity; do not change scale."})
        parts.append(inline_image(face_ref_path))
        parts.append({"text": "Reference A1: CANONICAL EDIT TARGET. Preserve this exact full portrait: same canvas, same character size, same top-of-hair position, same eye line, same raised-hand pose, same belt and pouch placement, same knee-up cutoff. Change only the requested facial expression."})
        parts.append(inline_image(base_path))
    else:
        sharp_seed = ensure_sharp_seed()
        face_seed = ensure_face_seed()
        face_hair_ref = RAW_DIR / f"{Path(FACE_SEED_NAME).stem}_face_hair_ref.png"
        crop_face_hair_reference(face_seed, face_hair_ref)
        parts.append({"text": "Reference F0: Shen Qingyue desired face and hair canon. Match her mature 28-year-old face, narrow half-lidded almond eyes, slim arched eyebrows, nose, lips, cheek contour, high bun, hair sticks, and two loose side tendrils. Ignore any beauty mark or facial dot if present. Use only the face and hair; do NOT copy the raised palms pose, pink robe color, necklace, earrings, or magenta background."})
        parts.append(inline_image(face_hair_ref))
        parts.append({"text": "Reference F1: full face/hair source for identity confirmation only. Preserve the eyes, brows, age, and side hair strands. Ignore pose, hands, color, jewelry, and background."})
        parts.append(inline_image(face_seed))
        parts.append({"text": "Reference S: CANONICAL EDIT TARGET. Use this exact sharp portrait as the foundation: same canvas, same character size, same raised-hand pose, same hair, same clothing, same medicine pouch, same framing and knee-up cutoff. Remove/ignore any beauty mark or stray facial dot and make the expression neutral-cold."})
        parts.append(inline_image(sharp_seed))

    parts.append({"text": make_prompt(target)})
    return parts


def ensure_face_seed() -> Path:
    seed_path = RAW_DIR / f"{Path(FACE_SEED_NAME).stem}_canonical_face_seed.png"
    if not seed_path.exists():
        source = PORTRAITS_DIR / FACE_SEED_NAME
        if not source.exists():
            raise FileNotFoundError(f"Missing face seed: {source}")
        seed_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, seed_path)
        print(f"  canonical face seed saved: {seed_path.relative_to(ROOT)}")
    return seed_path


def ensure_sharp_seed() -> Path:
    seed_path = RAW_DIR / f"{Path(SHARP_SEED_NAME).stem}_canonical_seed.png"
    if not seed_path.exists():
        source = PORTRAITS_DIR / SHARP_SEED_NAME
        if not source.exists():
            raise FileNotFoundError(f"Missing sharp seed: {source}")
        seed_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, seed_path)
        print(f"  canonical seed saved: {seed_path.relative_to(ROOT)}")
    return seed_path


def crop_face_reference(base_path: Path, face_ref_path: Path) -> None:
    from PIL import Image

    img = Image.open(base_path).convert("RGBA")
    bbox = img.getbbox()
    if bbox is not None:
        img = img.crop(bbox)
    w, h = img.size
    crop_w = int(w * 0.52)
    crop_h = int(h * 0.42)
    left = max(0, (w - crop_w) // 2)
    top = 0
    face = img.crop((left, top, min(w, left + crop_w), min(h, top + crop_h)))
    face_ref_path.parent.mkdir(parents=True, exist_ok=True)
    face.resize((512, 512), Image.Resampling.LANCZOS).save(face_ref_path)


def crop_face_hair_reference(base_path: Path, face_ref_path: Path) -> None:
    from PIL import Image

    img = Image.open(base_path).convert("RGBA")
    bbox = img.getbbox()
    if bbox is not None:
        img = img.crop(bbox)
    w, h = img.size
    crop_w = int(w * 0.40)
    crop_h = int(h * 0.46)
    left = max(0, (w - crop_w) // 2)
    top = 0
    ref = img.crop((left, top, min(w, left + crop_w), min(h, top + crop_h)))
    face_ref_path.parent.mkdir(parents=True, exist_ok=True)
    ref.resize((640, 640), Image.Resampling.LANCZOS).save(face_ref_path)


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
    print(f"  avatar updated: {avatar_path.relative_to(ROOT)}")


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
    backup_dir = PORTRAITS_DIR / f"backup_shen_qingyue_boss_{stamp}"
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    requested = set(args.only or [])
    targets = TARGETS
    if requested:
        targets = [
            t for t in TARGETS
            if t.key in requested
            or (
                not args.use_existing_base
                and t.key == "prologue_shen_qingyue"
                and any(x != "prologue_shen_qingyue" for x in requested)
            )
        ]
        if not targets:
            print(f"No matching targets: {sorted(requested)}", file=sys.stderr)
            return 2

    base_path = PORTRAITS_DIR / "prologue_shen_qingyue.png"
    success = 0
    failed = 0

    for idx, target in enumerate(targets, 1):
        final_path = PORTRAITS_DIR / f"{target.key}.png"
        raw_path = RAW_DIR / f"{target.key}_green_raw.png"
        tmp_final_path = RAW_DIR / f"{target.key}_final_tmp.png"
        print(f"\n[{idx}/{len(targets)}] {target.key} ({target.emotion})")

        if not args.skip_generate:
            parts = build_parts(target, base_path if target.use_new_base else None)
            if not call_gemini(api_key, parts, raw_path, target.temperature):
                failed += 1
                continue
            time.sleep(args.sleep)
        elif not raw_path.exists():
            print(f"  missing raw draft: {raw_path.relative_to(ROOT)}")
            failed += 1
            continue

        if not postprocess(raw_path, tmp_final_path, align_to_base=target.use_new_base):
            print(f"  postprocess/verify failed; keeping draft: {raw_path.relative_to(ROOT)}")
            failed += 1
            continue

        backup_and_replace(tmp_final_path, final_path, backup_dir, args.dry_run)
        if target.key == "prologue_shen_qingyue" and not args.dry_run:
            base_path = final_path
        success += 1

    if not args.dry_run and success > 0:
        avatar_path = PORTRAITS_DIR / "avatars" / "shen_qingyue.png"
        if base_path.exists():
            if avatar_path.exists():
                backup_dir.mkdir(parents=True, exist_ok=True)
                shutil.copy2(avatar_path, backup_dir / "avatar_shen_qingyue.png")
            crop_avatar(base_path, avatar_path)

    print(f"\nDone: {success} succeeded / {failed} failed")
    if success > 0:
        print(f"Backup dir: {backup_dir.relative_to(ROOT)}")
        print(f"Raw drafts: {RAW_DIR.relative_to(ROOT)}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
