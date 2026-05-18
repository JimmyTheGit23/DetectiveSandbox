#!/usr/bin/env python3
"""
生成助手凌瑶的立绘 + 讨论图标。
直接调用 Gemini API（gemini-2.0-flash-exp 的图像生成端点）。

用法：
  python tools/generate_companion_assets.py --api-key <KEY>

输出：
  assets/cn/portraits/companion_lingyao.png   (603x900 RGBA)
  assets/cn/ui/icon_discuss.png               (128x128 RGBA)
"""

from __future__ import annotations
import argparse
import base64
import json
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

try:
    from PIL import Image
    import io
except ImportError:
    print("需要 Pillow: pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
PORTRAIT_DIR = ROOT / "assets" / "cn" / "portraits"
UI_DIR = ROOT / "assets" / "cn" / "ui"

PORTRAIT_W = 603
PORTRAIT_H = 900
ICON_SIZE = 128

# Gemini imagen API
GEMINI_MODEL = "gemini-2.5-flash-image"
IMAGEN_MODEL = "imagen-4.0-generate-001"
GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
IMAGEN_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:predict?key={key}"
MAX_RETRIES = 3
RETRY_DELAY = 10  # seconds


def generate_image_gemini(prompt: str, api_key: str) -> bytes | None:
    """调用 Gemini API 生成图像，返回 PNG bytes。支持重试和 Imagen 备选。"""
    import time as _time

    # 方式 1: 尝试 Gemini flash image model
    for attempt in range(MAX_RETRIES):
        result = _try_gemini_generate(prompt, api_key)
        if result is not None:
            return result
        if attempt < MAX_RETRIES - 1:
            print(f"  [RETRY] 等待 {RETRY_DELAY}s 后重试 ({attempt+2}/{MAX_RETRIES})...")
            _time.sleep(RETRY_DELAY)

    # 方式 2: 尝试 Imagen 模型
    print("  [FALLBACK] 尝试 Imagen 模型...")
    result = _try_imagen_generate(prompt, api_key)
    if result is not None:
        return result

    return None


def _try_gemini_generate(prompt: str, api_key: str) -> bytes | None:
    """Gemini generateContent with responseModalities IMAGE."""
    url = GEMINI_URL.format(model=GEMINI_MODEL, key=api_key)
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt}
                ]
            }
        ],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"]
        }
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"  [API ERROR] {e.code}: {body[:300]}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  [ERROR] {e}", file=sys.stderr)
        return None

    # 从响应中提取图像
    candidates = result.get("candidates", [])
    if not candidates:
        print("  [ERROR] No candidates in response", file=sys.stderr)
        return None

    parts = candidates[0].get("content", {}).get("parts", [])
    for part in parts:
        if "inlineData" in part:
            mime = part["inlineData"].get("mimeType", "")
            if "image" in mime:
                b64 = part["inlineData"]["data"]
                return base64.b64decode(b64)

    print("  [ERROR] No image found in response parts", file=sys.stderr)
    return None


def _try_imagen_generate(prompt: str, api_key: str) -> bytes | None:
    """Imagen predict endpoint fallback."""
    url = IMAGEN_URL.format(model=IMAGEN_MODEL, key=api_key)
    payload = {
        "instances": [{"prompt": prompt}],
        "parameters": {"sampleCount": 1}
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"  [IMAGEN ERROR] {e.code}: {body[:300]}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  [IMAGEN ERROR] {e}", file=sys.stderr)
        return None

    predictions = result.get("predictions", [])
    if predictions and "bytesBase64Encoded" in predictions[0]:
        return base64.b64decode(predictions[0]["bytesBase64Encoded"])

    print("  [IMAGEN] No image in response", file=sys.stderr)
    return None


def remove_chroma(img: Image.Image, threshold: int = 80) -> Image.Image:
    """色键去除绿色背景 #00FF00（主要）或紫色背景 #FF00FF（备选）。"""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # 绿色色键（主要）
            if r < threshold and g > (255 - threshold) and b < threshold:
                pixels[x, y] = (0, 0, 0, 0)
            # 紫色/洋红色键（备选）
            elif r > (255 - threshold) and g < threshold and b > (255 - threshold):
                pixels[x, y] = (0, 0, 0, 0)
    return img


def autocrop(img: Image.Image, padding: int = 4) -> Image.Image:
    """裁剪透明边框。"""
    bbox = img.getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(img.width, right + padding)
    bottom = min(img.height, bottom + padding)
    return img.crop((left, top, right, bottom))


def fit_to_portrait(img: Image.Image) -> Image.Image:
    """缩放到 603x900，居底对齐。"""
    src_w, src_h = img.size
    scale = min(PORTRAIT_W / src_w, PORTRAIT_H / src_h)
    new_w = max(1, int(src_w * scale))
    new_h = max(1, int(src_h * scale))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (PORTRAIT_W, PORTRAIT_H), (0, 0, 0, 0))
    paste_x = (PORTRAIT_W - new_w) // 2
    paste_y = PORTRAIT_H - new_h
    canvas.paste(resized, (paste_x, paste_y), resized)
    return canvas


def fit_to_icon(img: Image.Image) -> Image.Image:
    """缩放到 128x128，居中。"""
    img = autocrop(img, padding=2)
    src_w, src_h = img.size
    scale = min(ICON_SIZE / src_w, ICON_SIZE / src_h) * 0.85  # 留边距
    new_w = max(1, int(src_w * scale))
    new_h = max(1, int(src_h * scale))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    paste_x = (ICON_SIZE - new_w) // 2
    paste_y = (ICON_SIZE - new_h) // 2
    canvas.paste(resized, (paste_x, paste_y), resized)
    return canvas


# ─── 提示词 ───

PORTRAIT_PROMPT = (
    "Half-body portrait of a beautiful young woman, a Ming Dynasty Jianghu female escort / caravan courier. "
    "She is a classical Chinese beauty (古风美少女) — elegant, graceful, and attractive. "
    "Slender build, fair luminous skin, elegant oval face with refined features. "
    "Beautiful phoenix eyes (丹凤眼) with clear bright pupils, delicate arched eyebrows like willow leaves, "
    "straight nose, soft rosy lips with a gentle confident smile. "
    "Hair in a high ponytail secured with a DARK RED (not pink, not magenta) silk ribbon that trails in the breeze, "
    "a few loose wisps framing her temples. The ribbon color must be deep vermilion red, NOT pink or magenta. "
    "Wearing a fitted dark indigo short fighting hanfu with subtle silver-thread trim at collar and cuffs, "
    "leather cross-body strap with a small courier pouch, narrow red sash cinched at the waist, "
    "a short dao sword sheathed horizontally at the small of her back. "
    "Expression: bright-eyed and spirited, a poised yet lively look — beautiful and capable, "
    "the look of someone clever and brave who acts before she thinks. "
    "Posture: standing with weight shifted to one leg, one hand resting on the leather strap, "
    "head tilted slightly with lively curiosity. "
    "\n\n"
    "CRITICAL STYLE REQUIREMENTS: This must be a REALISTIC painterly digital illustration "
    "fused with traditional Chinese ink-wash (水墨) brushwork. NOT cartoon, NOT anime, NOT chibi. "
    "The character must look like a real person painted in traditional Chinese art style. "
    "Ancient Chinese Ming Dynasty Jiangnan character portrait. Half-body waist-up shot, three-quarter angle, "
    "subject facing slightly toward camera-left, eye-level framing. "
    "IMPORTANT: solid pure GREEN background #00FF00, completely flat, no gradient, no shadow on the background, "
    "background fills entire frame except the character silhouette — this background will be removed via chroma key. "
    "Sharp clean silhouette edges — absolutely NO green tint bleeding into hair, clothing or skin. "
    "No text, no watermark, no UI, no extra characters in frame, no decorative borders, no environment elements behind subject. "
    "Lighting: soft warm key light from upper-right, gentle ambient fill. "
    "Style consistent with traditional Chinese guqin-era detective game character portraits, ink-tinted color palette. "
    "REALISTIC proportions, adult female face structure, NOT childlike or cartoonish."
)

ICON_PROMPT = (
    "A simple flat-style UI icon for a 'Discussion' or 'Chat' button in a Chinese ancient detective game. "
    "The icon shows two overlapping speech bubbles — one slightly larger and one smaller, "
    "both in warm gold/amber color with thin dark outlines, suggesting a conversation between two people. "
    "A small ink-brush quill or calligraphy pen rests on the smaller bubble. "
    "Style: clean, minimal, flat icon design suitable for a game UI button. "
    "IMPORTANT: solid pure magenta background #FF00FF, completely flat. "
    "No text, no extra decoration. The icon should look elegant and match a traditional Chinese aesthetic."
)


def main():
    ap = argparse.ArgumentParser(description="生成助手凌瑶立绘 + 讨论图标")
    ap.add_argument("--api-key", default=os.environ.get("GEMINI_API_KEY"), help="Gemini API key")
    ap.add_argument("--only", choices=["portrait", "icon"], help="只生成其中一个")
    ap.add_argument("--skip-postprocess", action="store_true", help="跳过色键去背（保留原图）")
    args = ap.parse_args()

    if not args.api_key:
        print("需要 --api-key 或环境变量 GEMINI_API_KEY", file=sys.stderr)
        sys.exit(1)

    PORTRAIT_DIR.mkdir(parents=True, exist_ok=True)
    UI_DIR.mkdir(parents=True, exist_ok=True)

    # ─── 生成立绘 ───
    if args.only is None or args.only == "portrait":
        print("── 生成凌瑶立绘 ──")
        raw_bytes = generate_image_gemini(PORTRAIT_PROMPT, args.api_key)
        if raw_bytes:
            img = Image.open(io.BytesIO(raw_bytes)).convert("RGBA")
            print(f"  原始尺寸: {img.size}")
            if not args.skip_postprocess:
                img = remove_chroma(img)
                img = autocrop(img, padding=4)
                img = fit_to_portrait(img)
            out_path = PORTRAIT_DIR / "companion_lingyao.png"
            img.save(out_path, "PNG")
            print(f"  [OK] → {out_path.relative_to(ROOT)}  ({img.size[0]}x{img.size[1]})")
        else:
            print("  [FAIL] 立绘生成失败")

    # ─── 生成图标 ───
    if args.only is None or args.only == "icon":
        print("\n── 生成讨论图标 ──")
        raw_bytes = generate_image_gemini(ICON_PROMPT, args.api_key)
        if raw_bytes:
            img = Image.open(io.BytesIO(raw_bytes)).convert("RGBA")
            print(f"  原始尺寸: {img.size}")
            if not args.skip_postprocess:
                img = remove_chroma(img)
                img = fit_to_icon(img)
            out_path = UI_DIR / "icon_discuss.png"
            img.save(out_path, "PNG")
            print(f"  [OK] → {out_path.relative_to(ROOT)}  ({img.size[0]}x{img.size[1]})")
        else:
            print("  [FAIL] 图标生成失败")

    print("\n=== 完成 ===")
    print("后续步骤：")
    print("  1) 检查生成的图片质量，如不满意可重新运行")
    print("  2) 凌瑶立绘已存为 companion_lingyao.png")
    print("     在 actors/registry.json 中 actor_tomboy_courier 的 portrait 可继续沿用")
    print("     或在 CompanionService 中直接引用 companion_lingyao.png")


if __name__ == "__main__":
    main()
