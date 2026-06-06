#!/usr/bin/env python3
"""
Generate Lu Zhao (陆昭) protagonist portraits in anime style matching companion_lingyao.

Generates 6 emotion variants:
  - base:       默认表情，沉稳内敛的年轻书生/御史
  - cold:       冷静质问，最常用的表情
  - nervous:    紧张不安，失印失身份后的狼狈
  - serious:    严肃专注，推理时的专注
  - surprised:  惊讶，重大发现时
  - defeated:   败局后的不甘与落寞

Usage:
  GEMINI_API_KEY=<key> python3 tools/generate_lu_zhao_anime.py
  python tools/generate_lu_zhao_anime.py --api-key <KEY>
  python tools/generate_lu_zhao_anime.py --only base
  python tools/generate_lu_zhao_anime.py --dry-run

Output:
  assets/cn/portraits/prologue_lu_zhao.png          (base)
  assets/cn/portraits/prologue_lu_zhao_cold.png      (cold)
  assets/cn/portraits/prologue_lu_zhao_nervous.png   (nervous)
  assets/cn/portraits/prologue_lu_zhao_serious.png   (serious)
  assets/cn/portraits/prologue_lu_zhao_surprised.png (surprised)
  assets/cn/portraits/prologue_lu_zhao_defeated.png  (defeated)
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import os
import shutil
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("需要 Pillow: pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from portrait_generation_spec import NPC_KNEE_UP_SPEC, fit_subject_to_spec

PORTRAITS_DIR = ROOT / "assets" / "cn" / "portraits"
RAW_DIR = ROOT / "assets" / "ai_raw" / "portraits" / "lu_zhao_anime"
MODEL = "gemini-2.5-flash-image"
MAX_RETRIES = 4
RETRY_DELAY = 15

# ─── Background & Style ───

GREEN_BG = """
CRITICAL BACKGROUND REQUIREMENT:
- Use a completely flat, uniform, solid pure high-saturation chroma green
  background (#00FF00, RGB 0,255,0).
- ZERO texture, ZERO noise, ZERO variation, ZERO shadow, ZERO gradient.
- No text, no characters, no writing, no watermark, no UI elements.
- No green color anywhere in the character, clothing, hair, skin, accessories, or props.
"""

STYLE = """
ART STYLE:
- Anime / manga illustration style, matching the companion_lingyao portrait exactly.
- Clean cel-shaded linework with soft shadows.
- Bright, warm color palette. NOT dark, NOT moody, NOT painterly.
- Semi-realistic proportions in anime style (slightly enlarged eyes, refined features).
- Ming Dynasty Jiangnan setting, but rendered in modern anime game art style.
- Polished game portrait quality, consistent with the game's companion art style.
- Three-quarter view, subject facing slightly toward camera-left, eye-level framing.
"""

UNIFIED_SPEC = """
UNIFIED PORTRAIT SPEC (MANDATORY):
- Canvas: exactly 848x1264 pixels, 2:3 aspect ratio.
- Character occupies approximately 80% of canvas height (~1011px).
- Knee-up framing: character from top of hair to around the knees.
- Top margin: ~52px above hair. Bottom margin: ~64px below knees.
- Side padding: at least 64px on each side.
- Standing pose, 3/4 view or front-facing.
- No sitting, no kneeling, no crouching.
- No full body (no feet/shoes visible).
- No waist-up or bust crop; must show down to knees.
"""

# ─── Character Identity ───

LU_ZHAO_FACE = """
EXACT FACE AND HAIR DESIGN:

FACE SHAPE:
- Young man, age around 22-25, with refined and handsome features.
- Oval face with a defined but not overly angular jawline.
- Fair skin with a slight pallor — he nearly drowned and has been through trauma.
- Clean-shaven, no facial hair.

EYES:
- Sharp, intelligent dark brown eyes with a keen observational gaze.
- Slightly narrowed by default — the eyes of someone who is always analyzing.
- Well-defined eyebrows, straight and dark.
- When serious, his gaze becomes piercing and unwavering.

NOSE:
- Straight, refined nose — neither too large nor too small.
- Classical scholar's profile.

LIPS:
- Thin but well-shaped lips.
- Often set in a neutral, controlled line.
- Rarely smiles — when he does, it's subtle and brief.

HAIR:
- Black hair, pulled up into a neat topknot (束发) secured with a simple white ribbon/cord.
- A few loose strands framing the face near the temples.
- Hair is slightly disheveled from the river ordeal — not perfectly groomed.
- Some strands may fall across the forehead.
"""

LU_ZHAO_BODY = """
LU ZHAO BODY AND CLOTHING:
- Young scholar, lean and wiry build — not muscular, but not frail.
- Height: above average for Ming Dynasty.
- Clothing: plain white/cream cotton scholar's robe (旧棉袍) — the borrowed clothes
  from the innkeeper after losing his official garments in the river.
- Simple cross-over collar (交领), loose-fitting, slightly wrinkled.
- A cloth belt (布腰带) at the waist.
- The robe is slightly too large for him — it's not his own clothes.
- NO official robe, NO hat, NO insignia — he is disguised as an ordinary scholar.
- Hands visible — one may hold a scroll or be clenched in thought.
- Standing upright with good posture despite the humble clothes —
  the bearing of someone educated and authoritative beneath the disguise.
"""

BASE_PROMPT = """
Create the canonical standard portrait for Lu Zhao (陆昭), the protagonist.
- He is a young imperial inspector disguised as an ordinary scholar.
- The face, hair, and clothing MUST match the detailed descriptions above exactly.
- He wears a plain white/cream borrowed scholar's robe — NOT an official robe.
- The body pose, clothing, and framing MUST match the specifications.
- Pull the camera back to show from top of hair to around the knees.
- The image is INVALID if it ends at the belt, hip, or thigh.
- He is standing upright, NOT sitting.
- Generate exactly one clean character portrait.
- The style MUST match the anime art style of companion_lingyao — clean cel-shaded linework, bright colors, NOT dark or painterly.
"""

# ─── Emotion Variants ───

VARIANTS = [
    {
        "key": "prologue_lu_zhao",
        "filename": "prologue_lu_zhao.png",
        "variant_name": "base",
        "temperature": 0.15,
        "emotion_prompt": """
Expression: Calm, composed, and quietly contemplative.
Eyes looking slightly to the side as if observing and analyzing.
Mouth in a neutral line — controlled and reserved.
The look of a young man who is constantly thinking, weighing every detail.
Posture: standing upright with hands behind his back or one hand resting on his belt.
Scholarly bearing despite the humble borrowed clothes.
""",
    },
    {
        "key": "prologue_lu_zhao_cold",
        "filename": "prologue_lu_zhao_cold.png",
        "variant_name": "cold",
        "temperature": 0.18,
        "emotion_prompt": """
Expression: Cold, stern, and penetrating — the look of an interrogator.
Eyes narrowed and fixed directly on the viewer, sharp as a blade.
Brows slightly furrowed with controlled intensity.
Mouth set in a firm, unyielding line.
One hand pointing forward accusingly or holding a scroll of evidence.
Posture: leaning slightly forward, shoulders squared, projecting authority.
The aura of someone who sees through lies and will not be deceived.
""",
    },
    {
        "key": "prologue_lu_zhao_nervous",
        "filename": "prologue_lu_zhao_nervous.png",
        "variant_name": "nervous",
        "temperature": 0.20,
        "emotion_prompt": """
Expression: Nervous and unsettled, brow furrowed with worry.
Eyes darting slightly, not quite meeting the viewer's gaze.
Lips pressed together tightly, jaw tense.
A subtle sheen of sweat on the forehead.
Posture: shoulders slightly hunched, one hand gripping his sleeve or clenching at his side.
The look of a man who has lost everything — official seal, documents, identity —
and is trying to maintain composure while feeling the weight of vulnerability.
""",
    },
    {
        "key": "prologue_lu_zhao_serious",
        "filename": "prologue_lu_zhao_serious.png",
        "variant_name": "serious",
        "temperature": 0.18,
        "emotion_prompt": """
Expression: Deeply focused and determined, eyes sharp with analytical intensity.
Brows drawn together in concentration, not anger.
Mouth slightly open as if about to deliver a crucial observation.
One hand raised with a finger extended — the gesture of someone connecting the dots.
Posture: standing tall, weight forward on his feet, engaged and alert.
The look of an inspector who has found the thread and is about to pull it loose.
""",
    },
    {
        "key": "prologue_lu_zhao_surprised",
        "filename": "prologue_lu_zhao_surprised.png",
        "variant_name": "surprised",
        "temperature": 0.22,
        "emotion_prompt": """
Expression: Genuine surprise and revelation, eyes widened in sudden understanding.
Eyebrows raised, forehead creased with shock.
Mouth slightly open, catching a breath.
One hand raised near his chest in an involuntary reaction.
Posture: body tensed, leaning back slightly as if hit by a revelation.
The look of someone who just connected pieces that were hiding in plain sight —
a rare crack in his composed exterior.
""",
    },
    {
        "key": "prologue_lu_zhao_defeated",
        "filename": "prologue_lu_zhao_defeated.png",
        "variant_name": "defeated",
        "temperature": 0.22,
        "emotion_prompt": """
Expression: Quiet defeat and bitter acceptance, eyes downcast with restrained pain.
Brows drawn together in anguish, not anger.
Mouth turned down slightly, jaw tight with suppressed emotion.
Hands at his sides, fingers slightly curled — the gesture of someone who knows
he has the truth but cannot prove it.
Posture: shoulders dropped slightly, head tilted down, the weight of injustice visible.
The look of a man who won the logic but lost the law —
who knows the killer walks free tonight.
""",
    },
]


# ─── API Calls ───

def generate_image_gemini(prompt: str, api_key: str, temperature: float = 0.15) -> bytes | None:
    for attempt in range(MAX_RETRIES):
        result = _try_gemini_generate(prompt, api_key, temperature)
        if result is not None:
            return result
        if attempt < MAX_RETRIES - 1:
            wait = RETRY_DELAY * (attempt + 1)
            print(f"  [RETRY] 等待 {wait}s 后重试 ({attempt + 2}/{MAX_RETRIES})...")
            time.sleep(wait)
    return None


def _try_gemini_generate(prompt: str, api_key: str, temperature: float) -> bytes | None:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={api_key}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": temperature,
            "imageConfig": {"aspectRatio": "2:3"},
        },
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"  [API ERROR] {e.code}: {body[:500]}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  [ERROR] {type(e).__name__}: {e}", file=sys.stderr)
        return None

    candidates = result.get("candidates", [])
    if not candidates:
        print("  [ERROR] No candidates in response", file=sys.stderr)
        return None

    parts = candidates[0].get("content", {}).get("parts", [])
    for part in parts:
        inline = part.get("inlineData") or part.get("inline_data", {})
        data_str = inline.get("data")
        if data_str:
            return base64.b64decode(data_str)

    print("  [ERROR] No image in response", file=sys.stderr)
    return None


# ─── Green Screen Processing ───

def normalize_green_screen(path: Path) -> bool:
    from collections import deque
    import numpy as np

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


# ─── Post-processing ───

def postprocess(raw_path: Path, tmp_final_path: Path) -> bool:
    from defringe_portrait import despill_green_from_hair, remove_chroma_background
    from remove_purple_bg import verify_portrait

    remove_chroma_background(str(raw_path), str(tmp_final_path))
    despill_green_from_hair(str(tmp_final_path), str(tmp_final_path))
    fitted = fit_subject_to_spec(Image.open(tmp_final_path).convert("RGBA"), NPC_KNEE_UP_SPEC)
    fitted.save(tmp_final_path)
    return verify_portrait(str(tmp_final_path))


def postprocess_rembg(src_path: Path, tmp_final_path: Path) -> bool:
    """Fallback: use rembg for non-green backgrounds."""
    from rembg import remove
    from defringe_portrait import despill_green_from_hair
    from remove_purple_bg import verify_portrait

    img = Image.open(src_path)
    result = remove(img)
    result.save(tmp_final_path)
    despill_green_from_hair(str(tmp_final_path), str(tmp_final_path))
    fitted = fit_subject_to_spec(Image.open(tmp_final_path).convert("RGBA"), NPC_KNEE_UP_SPEC)
    fitted.save(tmp_final_path)
    return verify_portrait(str(tmp_final_path))


def remove_tiny_alpha_clusters(img: Image.Image) -> Image.Image:
    import numpy as np
    from scipy import ndimage

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
    img = Image.open(base_path).convert("RGBA")
    w, h = img.size
    crop_h = int(h * 0.35)
    crop_size = min(w, crop_h)
    left = (w - crop_size) // 2
    cropped = img.crop((left, 0, left + crop_size, crop_size))
    avatar_path.parent.mkdir(parents=True, exist_ok=True)
    cropped.resize((128, 128), Image.Resampling.LANCZOS).save(avatar_path)
    print(f"  avatar: {avatar_path.relative_to(ROOT)}")


# ─── Generate One Variant ───

def generate_one(variant: dict, api_key: str, dry_run: bool = False) -> bool:
    full_prompt = "\n".join([
        "STYLE REFERENCE: Use the exact same anime art style as companion_lingyao. "
        "Clean cel-shaded linework, bright warm colors, semi-realistic anime proportions. "
        "NOT dark, NOT painterly, NOT realistic illustration style. "
        "This must look like it belongs in the same game as the companion portraits.",
        GREEN_BG,
        STYLE,
        UNIFIED_SPEC,
        NPC_KNEE_UP_SPEC.framing_prompt,
        LU_ZHAO_FACE,
        LU_ZHAO_BODY,
        BASE_PROMPT,
        variant["emotion_prompt"],
        "GENERATION RULES:",
        "- The face, hair, and clothing MUST match the detailed text description exactly.",
        "- The style MUST match companion_lingyao anime art style — clean, bright, cel-shaded.",
        "- Do NOT use dark/moody/painterly style.",
        "- Generate exactly one clean character portrait.",
        "- He wears a PLAIN WHITE scholar's robe — NOT an official robe with crane embroidery.",
        "- No hat, no official insignia — he is disguised as an ordinary scholar.",
    ])

    name = variant["variant_name"]
    key = variant["key"]
    temp = variant.get("temperature", 0.15)

    print(f"\n── [{name}] {variant['filename']}")
    print(f"    prompt 长度: {len(full_prompt)} 字符, temperature: {temp}")

    if dry_run:
        print(f"    [dry-run] 跳过 API 调用")
        return True

    raw_path = RAW_DIR / f"{key}_green_raw.png"
    raw_bytes = generate_image_gemini(full_prompt, api_key, temperature=temp)
    if not raw_bytes:
        print(f"    [FAIL] 图像生成失败")
        return False

    img = Image.open(io.BytesIO(raw_bytes)).convert("RGBA")
    print(f"    原始尺寸: {img.size}")

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    img.save(raw_path, "PNG")
    print(f"    raw saved: {raw_path.relative_to(ROOT)}")

    # Try green screen removal first
    green_ok = normalize_green_screen(raw_path) and validate_pure_green_border(raw_path)

    tmp_final = RAW_DIR / f"{key}_final_tmp.png"

    if green_ok:
        print(f"\n    [postprocess]")
        if not postprocess(raw_path, tmp_final):
            print(f"    [FAIL] postprocess failed")
            return False
    else:
        # Fallback to rembg
        print(f"\n    [postprocess via rembg]")
        if not postprocess_rembg(raw_path, tmp_final):
            print(f"    [FAIL] rembg postprocess failed")
            return False

    # Clean up tiny clusters
    img_final = remove_tiny_alpha_clusters(Image.open(tmp_final))
    img_final.save(tmp_final)

    # Save final
    final_path = PORTRAITS_DIR / variant["filename"]
    final_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(tmp_final), str(final_path))
    print(f"    [OK] → {final_path.relative_to(ROOT)}  ({img_final.size[0]}x{img_final.size[1]})")

    # Generate avatar (only for base)
    if name == "base":
        avatar_path = PORTRAITS_DIR / "avatars" / "lu_zhao.png"
        crop_avatar(final_path, avatar_path)

    return True


# ─── Main ───

def main():
    parser = argparse.ArgumentParser(
        description="陆昭二次元风格立绘生成器（多表情变体）"
    )
    parser.add_argument(
        "--api-key",
        default=os.environ.get("GEMINI_API_KEY", "").strip(),
        help="Gemini API key（或设置 GEMINI_API_KEY 环境变量）",
    )
    parser.add_argument(
        "--only",
        choices=["base", "cold", "nervous", "serious", "surprised", "defeated"],
        help="只生成指定表情变体",
    )
    parser.add_argument("--dry-run", action="store_true", help="只打印 prompt，不调用 API")
    parser.add_argument("--sleep", type=float, default=4.0, help="每次生成间的等待秒数")
    args = parser.parse_args()

    if not args.dry_run and not args.api_key:
        print("需要 --api-key 或环境变量 GEMINI_API_KEY", file=sys.stderr)
        return 2

    RAW_DIR.mkdir(parents=True, exist_ok=True)

    targets = VARIANTS
    if args.only:
        targets = [v for v in VARIANTS if v["variant_name"] == args.only]
        if not targets:
            print(f"未知变体: {args.only}", file=sys.stderr)
            return 1

    print("=" * 60)
    print("陆昭（Lu Zhao）二次元风格立绘生成器")
    print(f"共 {len(targets)} 个变体待生成")
    print(f"画风：与凌瑶一致的半写实二次元古风")
    print(f"规范：{NPC_KNEE_UP_SPEC.canvas_width}x{NPC_KNEE_UP_SPEC.canvas_height} 膝上立绘")
    print(f"模型：{MODEL}")
    print("=" * 60)

    # Backup existing portraits
    stamp = time.strftime("%Y%m%d_%H%M%S")
    backup_dir = PORTRAITS_DIR / f"backup_lu_zhao_anime_{stamp}"
    backup_dir.mkdir(parents=True, exist_ok=True)
    for v in targets:
        src = PORTRAITS_DIR / v["filename"]
        if src.exists():
            shutil.copy2(src, backup_dir / v["filename"])
    avatar_src = PORTRAITS_DIR / "avatars" / "lu_zhao.png"
    if avatar_src.exists():
        shutil.copy2(avatar_src, backup_dir / "avatar_lu_zhao.png")
    print(f"\n已备份到: {backup_dir.relative_to(ROOT)}")

    ok, fail = 0, 0
    for i, v in enumerate(targets):
        if generate_one(v, args.api_key or "", args.dry_run):
            ok += 1
        else:
            fail += 1
        if i < len(targets) - 1 and not args.dry_run:
            print(f"  等待 {args.sleep}s...")
            time.sleep(args.sleep)

    print(f"\n{'=' * 60}")
    print(f"完成：{ok} 成功 / {fail} 失败")
    print(f"{'=' * 60}")

    if ok > 0 and not args.dry_run:
        print("\n生成的文件：")
        for v in targets:
            print(f"  assets/cn/portraits/{v['filename']}")
        print(f"  assets/cn/portraits/avatars/lu_zhao.png")
        print("\n后续步骤：")
        print("  1) 在 Godot 编辑器中预览效果")
        print("  2) 如需重新生成单个表情: --only <base|cold|nervous|serious|surprised|defeated>")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
