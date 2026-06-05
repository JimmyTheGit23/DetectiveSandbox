#!/usr/bin/env python3
"""
老范（石矶渡船家）二次元风格立绘生成器。

保持老范的人物形态特征（头巾、旱烟杆、粗布衣、黝黑皮肤），
将画风从写实水墨风改为与凌瑶一致的半写实二次元古风。

用法：
  python tools/generate_lao_fan_anime.py --api-key <GEMINI_API_KEY>
  python tools/generate_lao_fan_anime.py --api-key <KEY> --only base
  python tools/generate_lao_fan_anime.py --api-key <KEY> --dry-run

输出：
  assets/cn/portraits/prologue_lao_fan.png          (基础)
  assets/cn/portraits/prologue_lao_fan_collapsed.png (崩溃)
  assets/cn/portraits/prologue_lao_fan_frozen.png    (僵住)
  assets/cn/portraits/prologue_lao_fan_shaken.png    (动摇)
  assets/cn/portraits/prologue_lao_fan_sneering.png  (冷笑)
"""

from __future__ import annotations
import argparse
import base64
import io
import json
import os
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("需要 Pillow: pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
PORTRAIT_DIR = ROOT / "assets" / "cn" / "portraits"
DRAFT_DIR = ROOT / "assets" / "ai_raw" / "portraits"

from portrait_generation_spec import NPC_KNEE_UP_SPEC, autocrop_rgba, fit_subject_to_spec

# ─── Gemini API 配置 ───
GEMINI_MODEL = "gemini-2.5-flash-image"
IMAGEN_MODEL = "imagen-4.0-generate-001"
GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
IMAGEN_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:predict?key={key}"
MAX_RETRIES = 3
RETRY_DELAY = 15  # seconds

# ─── 老范角色基础描述 ───
LAO_FAN_BASE = (
    "Three-quarter portrait of a 50-55 year old Ming Dynasty river boatman (船家) "
    "who has been running a ferry on the Jingjiang River for twenty years. "
    "Weathered dark tanned skin from years of sun and wind, lean muscular build visible "
    "through an open rough-spun earth-brown cotton tunic revealing his chest. "
    "A worn off-white cloth bandana wrapped around his head with the knot at the back. "
    "A traditional Chinese long-stemmed tobacco pipe (旱烟杆) held loosely in his mouth or hand. "
    "Deep-set cunning eyes with crow's feet, thin lips often curved in a knowing smirk. "
    "Short grey-streaked stubble on his chin. Strong calloused hands. "
    "Wearing a faded indigo-brown short hanfu tunic with rolled-up sleeves, "
    "a coarse hemp sash tied at the waist, loose dark trousers. "
    "The overall look is weathered, worldly, and sly — a man who has seen everything on the river."
)

# ─── 风格基底（与凌瑶一致的半写实二次元古风） ───
STYLE_ANIME = (
    "\n\n"
    "CRITICAL STYLE: Semi-realistic anime illustration fused with Chinese ink-wash aesthetics. "
    "Clean confident line art with soft cel-shading and watercolor-textured fills. "
    "Slightly stylized proportions — larger expressive eyes than pure realism, "
    "but NOT chibi, NOT cartoon, NOT flat vector. "
    "The character should look like a high-quality anime character in a Chinese historical setting. "
    "Vibrant yet muted ink-tinted color palette. "
    "Three-quarter portrait, subject facing slightly toward camera-left, eye-level framing. "
    f"{NPC_KNEE_UP_SPEC.framing_prompt}"
    "IMPORTANT: solid pure magenta background #FF00FF, completely flat, no gradient, no shadow on the background, "
    "background fills entire frame except the character silhouette — this background will be removed via chroma key. "
    "Sharp clean silhouette edges — absolutely NO magenta tint bleeding into hair, clothing or skin. "
    "No text, no watermark, no UI, no extra characters in frame, no decorative borders, no environment elements behind subject. "
    "Lighting: soft warm key light from upper-right, gentle ambient fill. "
    "Style consistent with anime-influenced Chinese detective game character portraits."
)

# ─── 5 个表情变体 ───
VARIANTS = [
    {
        "key": "prologue_lao_fan",
        "filename": "prologue_lao_fan.png",
        "variant_name": "base",
        "emotion_prompt": (
            "Expression: sly and composed, a faint knowing smirk playing on his thin lips, "
            "eyes half-lidded with a calculating glint — the look of a man who knows more than he says. "
            "Posture: standing with arms behind his back, tobacco pipe clenched between his teeth, "
            "chin slightly raised with casual confidence."
        ),
    },
    {
        "key": "prologue_lao_fan_collapsed",
        "filename": "prologue_lao_fan_collapsed.png",
        "variant_name": "collapsed",
        "emotion_prompt": (
            "Expression: completely broken and defeated, face drained of color beneath the tan, "
            "mouth hanging open, eyes unfocused and hollow, all bravado gone. "
            "Posture: slumped forward, knees buckling, one hand reaching out to steady himself "
            "against something unseen, the other hanging limp at his side. "
            "The pipe has fallen from his mouth."
        ),
    },
    {
        "key": "prologue_lao_fan_frozen",
        "filename": "prologue_lao_fan_frozen.png",
        "variant_name": "frozen",
        "emotion_prompt": (
            "Expression: stunned and frozen, eyes wide open in shock, pupils contracted, "
            "face rigid and pale, mouth pressed into a tight line. "
            "The look of someone caught completely off guard, trapped like a deer in lantern light. "
            "Posture: stiff and rigid, shoulders hunched up tense, hands gripping the pipe "
            "so tightly his knuckles are white. Body language screams 'cornered'."
        ),
    },
    {
        "key": "prologue_lao_fan_shaken",
        "filename": "prologue_lao_fan_shaken.png",
        "variant_name": "shaken",
        "emotion_prompt": (
            "Expression: visibly shaken and disturbed, brow furrowed with worry, "
            "eyes darting sideways nervously, sweat beads on his temple. "
            "Jaw clenched, a muscle twitching in his cheek. "
            "Posture: leaning back slightly as if recoiling, one hand raised defensively "
            "near his chest, shoulders turned inward. "
            "The pipe still in his mouth but forgotten, a thin trail of smoke rising."
        ),
    },
    {
        "key": "prologue_lao_fan_sneering",
        "filename": "prologue_lao_fan_sneering.png",
        "variant_name": "sneering",
        "emotion_prompt": (
            "Expression: contemptuous sneer, one corner of his mouth pulled up in a bitter mocking grin, "
            "eyes narrowed with disdain and dark amusement. One eyebrow raised. "
            "The look of a man who finds the whole situation beneath him. "
            "Posture: leaning against an invisible wall, arms crossed over his chest, "
            "head tilted back slightly, pipe held between two fingers like a conductor's baton."
        ),
    },
]


# ─── API 调用 ───

def generate_image_gemini(prompt: str, api_key: str) -> bytes | None:
    """调用 Gemini API 生成图像，返回 PNG bytes。"""
    for attempt in range(MAX_RETRIES):
        result = _try_gemini_generate(prompt, api_key)
        if result is not None:
            return result
        if attempt < MAX_RETRIES - 1:
            print(f"  [RETRY] 等待 {RETRY_DELAY}s 后重试 ({attempt+2}/{MAX_RETRIES})...")
            time.sleep(RETRY_DELAY)

    # Fallback to Imagen
    print("  [FALLBACK] 尝试 Imagen 模型...")
    return _try_imagen_generate(prompt, api_key)


def _try_gemini_generate(prompt: str, api_key: str) -> bytes | None:
    url = GEMINI_URL.format(model=GEMINI_MODEL, key=api_key)
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]}
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"  [API ERROR] {e.code}: {body[:300]}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  [ERROR] {e}", file=sys.stderr)
        return None

    candidates = result.get("candidates", [])
    if not candidates:
        print("  [ERROR] No candidates in response", file=sys.stderr)
        return None

    parts = candidates[0].get("content", {}).get("parts", [])
    for part in parts:
        if "inlineData" in part:
            mime = part["inlineData"].get("mimeType", "")
            if "image" in mime:
                return base64.b64decode(part["inlineData"]["data"])

    print("  [ERROR] No image in response", file=sys.stderr)
    return None


def _try_imagen_generate(prompt: str, api_key: str) -> bytes | None:
    url = IMAGEN_URL.format(model=IMAGEN_MODEL, key=api_key)
    payload = {
        "instances": [{"prompt": prompt}],
        "parameters": {"sampleCount": 1}
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"  [IMAGEN ERROR] {e}", file=sys.stderr)
        return None

    predictions = result.get("predictions", [])
    if predictions and "bytesBase64Encoded" in predictions[0]:
        return base64.b64decode(predictions[0]["bytesBase64Encoded"])
    return None


# ─── 后处理 ───

def _color_distance(r1: int, g1: int, b1: int, r2: int, g2: int, b2: int) -> float:
    """欧几里得颜色距离。"""
    return ((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2) ** 0.5


def remove_magenta(img: Image.Image, threshold: float = 40.0) -> Image.Image:
    """色键去除洋红色/玫红色背景（支持 Gemini API 实际生成的色值）。"""
    return remove_chroma(img, threshold)


def remove_chroma(img: Image.Image, threshold: float = 40.0) -> Image.Image:
    """
    色键去除背景。使用颜色距离匹配多种背景色：
    - Gemini API 实际生成的玫红色 RGB(217,54,127) 附近
    - 纯绿色 #00FF00
    - 纯洋红色 #FF00FF
    """
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    targets = [
        (217, 54, 127),   # Gemini 实际生成的背景色
        (217, 54, 128),
        (218, 54, 127),
        (0, 255, 0),      # 纯绿色
        (255, 0, 255),    # 纯洋红
    ]
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            min_dist = min(_color_distance(r, g, b, tr, tg, tb) for tr, tg, tb in targets)
            if min_dist < threshold:
                pixels[x, y] = (0, 0, 0, 0)
    return img


# ─── 主流程 ───

def generate_one(variant: dict, api_key: str, dry_run: bool = False) -> bool:
    """生成单个表情变体。"""
    prompt = LAO_FAN_BASE + "\n\n" + variant["emotion_prompt"] + STYLE_ANIME

    print(f"\n── [{variant['variant_name']}] {variant['key']}")
    print(f"    prompt 长度: {len(prompt)} 字符")

    if dry_run:
        print(f"    [dry-run] 跳过 API 调用")
        return True

    # 生成草图
    raw_bytes = generate_image_gemini(prompt, api_key)
    if not raw_bytes:
        print(f"    [FAIL] 图像生成失败")
        return False

    img = Image.open(io.BytesIO(raw_bytes)).convert("RGBA")
    print(f"    原始尺寸: {img.size}")

    # 保存草图
    DRAFT_DIR.mkdir(parents=True, exist_ok=True)
    ts = int(time.time())
    draft_path = DRAFT_DIR / f"{variant['key']}_anime_{ts}.png"
    img.save(draft_path, "PNG")
    print(f"    [DRAFT] → {draft_path.relative_to(ROOT)}")

    # 色键去背 + 标准化
    img = remove_chroma(img)
    img = autocrop_rgba(img, padding=NPC_KNEE_UP_SPEC.crop_padding)
    img = fit_subject_to_spec(img, NPC_KNEE_UP_SPEC)

    # 保存终稿
    out_path = PORTRAIT_DIR / variant["filename"]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path, "PNG")
    print(f"    [OK] → {out_path.relative_to(ROOT)}  ({img.size[0]}x{img.size[1]})")

    return True


def main():
    ap = argparse.ArgumentParser(
        description="老范二次元风格立绘生成器（保持人物特征，改为半写实二次元画风）"
    )
    ap.add_argument("--api-key", default=os.environ.get("GEMINI_API_KEY"),
                    help="Gemini API key（或设置 GEMINI_API_KEY 环境变量）")
    ap.add_argument("--only", choices=["base", "collapsed", "frozen", "shaken", "sneering"],
                    help="只生成指定表情变体")
    ap.add_argument("--dry-run", action="store_true", help="只打印 prompt，不调用 API")
    ap.add_argument("--skip-postprocess", action="store_true", help="跳过后处理（保留原图）")
    args = ap.parse_args()

    if not args.dry_run and not args.api_key:
        print("需要 --api-key 或环境变量 GEMINI_API_KEY", file=sys.stderr)
        sys.exit(1)

    # 选择要生成的变体
    targets = VARIANTS
    if args.only:
        targets = [v for v in VARIANTS if v["variant_name"] == args.only]
        if not targets:
            print(f"未知变体: {args.only}", file=sys.stderr)
            sys.exit(1)

    PORTRAIT_DIR.mkdir(parents=True, exist_ok=True)
    DRAFT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"老范二次元风格立绘生成器")
    print(f"共 {len(targets)} 个变体待生成")
    print(f"目标: 保持老范人物形态 → 画风改为半写实二次元（与凌瑶一致）")

    ok, fail = 0, 0
    for v in targets:
        if generate_one(v, args.api_key or "", args.dry_run):
            ok += 1
        else:
            fail += 1

    print(f"\n=== 完成：{ok} 成功 / {fail} 失败 ===")
    if ok > 0 and not args.dry_run:
        print("\n生成的文件：")
        for v in targets:
            print(f"  assets/cn/portraits/{v['filename']}")
        print("\n后续步骤：")
        print("  1) 检查生成的图片质量，不满意可重新运行 --only <variant>")
        print("  2) portrait_expressions.json 无需修改（路径不变）")
        print("  3) 在 Godot 编辑器中预览效果")


if __name__ == "__main__":
    main()
