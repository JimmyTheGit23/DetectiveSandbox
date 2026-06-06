#!/usr/bin/env python3
"""
Generate Fisherman Wang (王大爷) portrait in anime style matching companion_lingyao.

Generates 4 emotion variants:
  - base:       默认表情，严肃沉稳的老渔翁
  - evasive:    回避/讲述时的表情
  - guilty:     伪证被拆穿后的愧疚
  - angry:      愤怒，揭露真相时的激愤

Usage:
  GEMINI_API_KEY=<key> python3 tools/generate_fisherman_wang_anime.py
  python tools/generate_fisherman_wang_anime.py --api-key <KEY>
  python tools/generate_fisherman_wang_anime.py --only base
  python tools/generate_fisherman_wang_anime.py --dry-run

Output:
  assets/cn/portraits/prologue_fisherman_wang.png          (base)
  assets/cn/portraits/prologue_fisherman_wang_evasive.png   (evasive)
  assets/cn/portraits/prologue_fisherman_wang_guilty.png    (guilty)
  assets/cn/portraits/prologue_fisherman_wang_angry.png     (angry)
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
RAW_DIR = ROOT / "assets" / "ai_raw" / "portraits" / "fisherman_wang_anime"
MODEL = "gemini-2.5-flash-image"
MAX_RETRIES = 4
RETRY_DELAY = 15  # seconds

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

WANG_FACE = """
EXACT FACE AND HAIR DESIGN:

FACE SHAPE:
- Weathered, angular face with strong cheekbones.
- Age around 65-70, but still sturdy and sharp.
- Deep-set wrinkles on forehead, around eyes, and on cheeks.
- Strong jawline, slightly gaunt.
- Sun-weathered skin, tanned bronze complexion.

EYES:
- Narrow, deep-set eyes with a sharp, observant gaze.
- Small pupils, light brown/amber iris color.
- Crow's feet wrinkles at the corners.
- Eyes convey a lifetime of experience on the river.
- Slight squint, as if accustomed to looking into bright water reflections.

EYEBROWS:
- Thick, bushy, silver-grey eyebrows.
- Slightly unruly, not groomed.

NOSE:
- Large, slightly bulbous nose.
- Sun-weathered, slightly reddened tip.

LIPS:
- Thin lips, slightly chapped from wind and sun.
- Often set in a firm, no-nonsense line.

FACIAL HAIR:
- Short, scruffy silver-white beard and mustache.
- Not neatly trimmed — slightly wild, like a fisherman's beard.
- Stubble on cheeks and jawline.

HAIR:
- Silver-white hair, thin and wispy on top.
- Hair pulled back into a small messy knot/bun at the back.
- Some loose strands around the ears and temples.
- Weathered, windblown look.
"""

WANG_BODY = """
WANG BODY AND CLOTHING:
- Elderly fisherman, age around 65-70, but still physically capable.
- Lean, wiry build — not frail, but not bulky.
- Clothing: traditional dark blue/grey Chinese fisherman's robe (short sleeves rolled up).
- Straw rain cape (蓑衣) draped over shoulders — but NOT covering the body, just resting on shoulders.
- Simple cloth belt at the waist.
- Standing upright, slightly hunched forward from years of work.
- Overall look: authentic Ming Dynasty river fisherman, rendered in anime style.
"""

BASE_PROMPT = """
Create the canonical standard portrait for Fisherman Wang (王大爷 / fisherman_wang).
- The face and hair MUST match the detailed face description above exactly.
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
        "key": "prologue_fisherman_wang",
        "filename": "prologue_fisherman_wang.png",
        "variant_name": "base",
        "temperature": 0.15,
        "emotion_prompt": """
Expression: Serious, weathered, no-nonsense expression.
Eyes carry a sharp intelligence despite the aged appearance.
Mouth set in a firm, neutral line — not smiling, not angry.
Overall: a tough old river fisherman who has seen everything.
Posture: standing upright with arms at his sides, weight settled.
Hands visible — one slightly clenched, the other relaxed.
""",
    },
    {
        "key": "prologue_fisherman_wang_evasive",
        "filename": "prologue_fisherman_wang_evasive.png",
        "variant_name": "evasive",
        "temperature": 0.20,
        "emotion_prompt": """
Expression: Guarded and evasive, eyes looking slightly away from the viewer.
Brow furrowed with mild worry, as if choosing words carefully.
Mouth slightly open mid-sentence, lips parted as if speaking reluctantly.
A hint of guilt and defensiveness in the posture — shoulders slightly turned.
Posture: one hand raised slightly in a dismissive gesture, the other gripping his fishing rope.
The look of a man who knows something but doesn't want to get involved.
""",
    },
    {
        "key": "prologue_fisherman_wang_guilty",
        "filename": "prologue_fisherman_wang_guilty.png",
        "variant_name": "guilty",
        "temperature": 0.20,
        "emotion_prompt": """
Expression: Deep guilt and shame, eyes downcast, unable to meet the viewer's gaze.
Face flushed with embarrassment beneath the weathered tan.
Mouth turned down in a grimace of self-disgust.
Brows drawn together in remorse.
Posture: slightly hunched, shoulders drooping, one hand reaching up to scratch the back of his head in shame.
The look of an honest man who has been caught in a lie and despises himself for it.
""",
    },
    {
        "key": "prologue_fisherman_wang_angry",
        "filename": "prologue_fisherman_wang_angry.png",
        "variant_name": "angry",
        "temperature": 0.22,
        "emotion_prompt": """
Expression: Righteous anger and indignation, eyes blazing with fury.
Mouth open in mid-shout, showing teeth, jaw clenched between words.
Bushy silver eyebrows drawn down hard, veins visible on his temple.
One hand pointing forward accusingly, the other clenched into a fist at his side.
Posture: leaning forward aggressively, body tense with outrage.
The look of a man who has witnessed injustice and can no longer stay silent.
""",
    },
]


# ─── API Calls ───

def generate_image_gemini(prompt: str, api_key: str, temperature: float = 0.15) -> bytes | None:
    """Call Gemini API to generate image, return PNG bytes."""
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
        url,
        data=data,
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
    """Normalize the green screen background to pure #00FF00."""
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
    """Verify the border pixels are pure green."""
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
    """Remove green background, despill, and fit to spec."""
    from defringe_portrait import despill_green_from_hair, remove_chroma_background
    from remove_purple_bg import verify_portrait

    remove_chroma_background(str(raw_path), str(tmp_final_path))
    despill_green_from_hair(str(tmp_final_path), str(tmp_final_path))
    fitted = fit_subject_to_spec(Image.open(tmp_final_path).convert("RGBA"), NPC_KNEE_UP_SPEC)
    fitted.save(tmp_final_path)
    return verify_portrait(str(tmp_final_path))


def remove_tiny_alpha_clusters(img: Image.Image) -> Image.Image:
    """Remove isolated alpha pixel clusters."""
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
    """Crop a 128x128 avatar from the top portion of the portrait."""
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
    """Generate a single emotion variant."""
    full_prompt = "\n".join([
        "STYLE REFERENCE: Use the exact same anime art style as companion_lingyao. "
        "Clean cel-shaded linework, bright warm colors, semi-realistic anime proportions. "
        "NOT dark, NOT painterly, NOT realistic illustration style. "
        "This must look like it belongs in the same game as the companion portraits.",
        GREEN_BG,
        STYLE,
        UNIFIED_SPEC,
        NPC_KNEE_UP_SPEC.framing_prompt,
        WANG_FACE,
        WANG_BODY,
        BASE_PROMPT,
        variant["emotion_prompt"],
        "GENERATION RULES:",
        "- The face, hair, and beard MUST match the detailed text description exactly.",
        "- The style MUST match companion_lingyao anime art style — clean, bright, cel-shaded.",
        "- Do NOT use dark/moody/painterly style.",
        "- Generate exactly one clean character portrait.",
    ])

    name = variant["variant_name"]
    key = variant["key"]
    temp = variant.get("temperature", 0.15)

    print(f"\n── [{name}] {variant['filename']}")
    print(f"    prompt 长度: {len(full_prompt)} 字符, temperature: {temp}")

    if dry_run:
        print(f"    [dry-run] 跳过 API 调用")
        return True

    # Generate raw
    raw_path = RAW_DIR / f"{key}_green_raw.png"
    raw_bytes = generate_image_gemini(full_prompt, api_key, temperature=temp)
    if not raw_bytes:
        print(f"    [FAIL] 图像生成失败")
        return False

    img = Image.open(io.BytesIO(raw_bytes)).convert("RGBA")
    print(f"    原始尺寸: {img.size}")

    # Save raw
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    img.save(raw_path, "PNG")
    print(f"    raw saved: {raw_path.relative_to(ROOT)}")

    # Normalize green screen
    if not normalize_green_screen(raw_path):
        print(f"    [WARN] green screen normalization failed, trying to proceed anyway")
    if not validate_pure_green_border(raw_path):
        print(f"    [WARN] pure green border check failed, trying to proceed anyway")

    # Postprocess
    tmp_final = RAW_DIR / f"{key}_final_tmp.png"
    print(f"\n    [postprocess]")
    if not postprocess(raw_path, tmp_final):
        print(f"    [FAIL] postprocess failed")
        return False

    # Clean up tiny clusters
    img = Image.open(tmp_final)
    img = remove_tiny_alpha_clusters(img)
    img.save(tmp_final)

    # Save final
    final_path = PORTRAITS_DIR / variant["filename"]
    final_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(tmp_final), str(final_path))
    print(f"    [OK] → {final_path.relative_to(ROOT)}  ({img.size[0]}x{img.size[1]})")

    # Generate avatar
    avatar_path = PORTRAITS_DIR / "avatars" / "fisherman_wang.png"
    crop_avatar(final_path, avatar_path)

    return True


# ─── Main ───

def main():
    parser = argparse.ArgumentParser(
        description="王大爷二次元风格立绘生成器（多表情变体）"
    )
    parser.add_argument(
        "--api-key",
        default=os.environ.get("GEMINI_API_KEY", "").strip(),
        help="Gemini API key（或设置 GEMINI_API_KEY 环境变量）",
    )
    parser.add_argument(
        "--only",
        choices=["base", "evasive", "guilty", "angry"],
        help="只生成指定表情变体",
    )
    parser.add_argument("--dry-run", action="store_true", help="只打印 prompt，不调用 API")
    parser.add_argument("--sleep", type=float, default=4.0, help="每次生成间的等待秒数")
    args = parser.parse_args()

    if not args.dry_run and not args.api_key:
        print("需要 --api-key 或环境变量 GEMINI_API_KEY", file=sys.stderr)
        return 2

    RAW_DIR.mkdir(parents=True, exist_ok=True)

    # Select targets
    targets = VARIANTS
    if args.only:
        targets = [v for v in VARIANTS if v["variant_name"] == args.only]
        if not targets:
            print(f"未知变体: {args.only}", file=sys.stderr)
            return 1

    print("=" * 60)
    print("王大爷（Fisherman Wang）二次元风格立绘生成器")
    print(f"共 {len(targets)} 个变体待生成")
    print(f"画风：与凌瑶一致的半写实二次元古风")
    print(f"规范：{NPC_KNEE_UP_SPEC.canvas_width}x{NPC_KNEE_UP_SPEC.canvas_height} 膝上立绘")
    print(f"模型：{MODEL}")
    print("=" * 60)

    # Backup existing portraits
    stamp = time.strftime("%Y%m%d_%H%M%S")
    backup_dir = PORTRAITS_DIR / f"backup_fisherman_wang_anime_{stamp}"
    backup_dir.mkdir(parents=True, exist_ok=True)
    for v in targets:
        src = PORTRAITS_DIR / v["filename"]
        if src.exists():
            shutil.copy2(src, backup_dir / v["filename"])
    avatar_src = PORTRAITS_DIR / "avatars" / "fisherman_wang.png"
    if avatar_src.exists():
        shutil.copy2(avatar_src, backup_dir / "avatar_fisherman_wang.png")
    print(f"\n已备份到: {backup_dir.relative_to(ROOT)}")

    ok, fail = 0, 0
    for i, v in enumerate(targets):
        if generate_one(v, args.api_key or "", args.dry_run):
            ok += 1
        else:
            fail += 1
        # Sleep between generations
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
        print(f"  assets/cn/portraits/avatars/fisherman_wang.png")
        print("\n后续步骤：")
        print("  1) 在 Godot 编辑器中预览效果")
        print("  2) 如需重新生成单个表情: --only <base|evasive|guilty|angry>")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
