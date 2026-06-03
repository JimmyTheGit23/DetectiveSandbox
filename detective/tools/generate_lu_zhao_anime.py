#!/usr/bin/env python3
"""
主角陆昭二次元风格立绘生成器。

生成两个版本：
  1. 便装版（prologue_lu_zhao）— 白色圆领便服，用于序章日常对话
  2. 官服版（lu_zhao）— 深蓝官服+乌纱帽，用于正式场景

画风：与凌瑶一致的半写实二次元古风（clean line art + soft cel-shading）

用法：
  python tools/generate_lu_zhao_anime.py --api-key <KEY>
  python tools/generate_lu_zhao_anime.py --api-key <KEY> --version casual
  python tools/generate_lu_zhao_anime.py --api-key <KEY> --version official --only base
  python tools/generate_lu_zhao_anime.py --dry-run
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

PORTRAIT_W = 603
PORTRAIT_H = 900

# ─── Gemini API 配置 ───
GEMINI_MODEL = "gemini-2.5-flash-image"
IMAGEN_MODEL = "imagen-4.0-generate-001"
GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
IMAGEN_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:predict?key={key}"
MAX_RETRIES = 3
RETRY_DELAY = 15

# ─── 陆昭角色基础描述 ───
# 便装版：落水后穿的白色便服（序章场景：凭证遗失，无法自证身份）
CASUAL_BASE = (
    "Half-body portrait of a young 25 year old Ming Dynasty scholar-official (巡按御史) "
    "traveling incognito after losing his credentials in a river accident. "
    "Youthful handsome face with refined elegant features, smooth skin, NO facial hair — clean-shaven. "
    "Sharp intelligent eyes that miss nothing, well-defined jawline, straight nose. "
    "Hair pulled back in a simple topknot secured with a white cloth ribbon, "
    "a few loose strands framing his temples from the river ordeal. "
    "The face reads as a precocious young talent — someone who earned his imperial appointment unusually early. "
    "Wearing a plain white/light grey round-collar (圆领) scholar's hanfu robe, "
    "slightly wrinkled from sleeping rough, with a simple cloth sash at the waist. "
    "The robe is clean but clearly not his finest — a young man stripped of his rank but not his dignity. "
    "Build: lean and upright, the posture of someone trained in official protocol. "
    "Overall impression: calm, composed, observant — a young detective hiding in plain sight."
)

# 官服版：正式巡按御史官服
OFFICIAL_BASE = (
    "Half-body portrait of a young 25 year old Ming Dynasty Imperial Inspector (巡按御史) "
    "in full court attire. "
    "Youthful handsome face with refined elegant features, smooth skin, NO facial hair — clean-shaven. "
    "Sharp intelligent authoritative dark eyes, well-defined jawline, straight nose. "
    "The face reads as a brilliant young official who earned his position through exceptional talent. "
    "Hair hidden under a traditional black Ming Dynasty official hat (乌纱帽). "
    "CRITICAL HAT DETAIL: The hat MUST have two short horizontal wing-like extensions (帽翅/展脚) "
    "protruding from each side of the hat, like flat black sticks extending sideways. "
    "These wings should be SHORT — about the width of the head — NOT extending beyond the character's shoulders. "
    "The wings are the defining feature of a Ming Dynasty official hat. "
    "Wearing a dark indigo official court robe (官服) with a white crane rank embroidery square (补子) on the chest, "
    "intricate cloud-pattern borders, a jade belt-plaque at the waist. "
    "Holding a folding fan (折扇) in one hand, the other hand resting at his side. "
    "Build: lean and upright, commanding presence despite his youth. "
    "Overall impression: young but authoritative, composed, eyes like a hawk — the unmistakable bearing of imperial authority."
)

# ─── 风格基底 ───
STYLE_ANIME_MANGENTA = (
    "\n\n"
    "CRITICAL STYLE: Semi-realistic anime illustration fused with Chinese ink-wash aesthetics. "
    "Clean confident line art with soft cel-shading and watercolor-textured fills. "
    "Slightly stylized proportions — larger expressive eyes than pure realism, "
    "but NOT chibi, NOT cartoon, NOT flat vector. "
    "Vibrant yet muted ink-tinted color palette. "
    "Half-body waist-up shot, three-quarter angle, "
    "subject facing slightly toward camera-left, eye-level framing. "
    "IMPORTANT: solid pure magenta background #FF00FF, completely flat, no gradient, no shadow on the background, "
    "background fills entire frame except the character silhouette — this background will be removed via chroma key. "
    "Sharp clean silhouette edges — absolutely NO magenta tint bleeding into hair, clothing or skin. "
    "No text, no watermark, no UI, no extra characters in frame, no decorative borders, no environment elements behind subject. "
    "Lighting: soft warm key light from upper-right, gentle ambient fill. "
    "Style consistent with anime-influenced Chinese detective game character portraits."
)

# 绿底版本：用于深色服饰角色（如官服），绿色与黑色反差更大，去背更干净
STYLE_ANIME_GREEN = (
    "\n\n"
    "CRITICAL STYLE: Semi-realistic anime illustration fused with Chinese ink-wash aesthetics. "
    "Clean confident line art with soft cel-shading and watercolor-textured fills. "
    "Slightly stylized proportions — larger expressive eyes than pure realism, "
    "but NOT chibi, NOT cartoon, NOT flat vector. "
    "Vibrant yet muted ink-tinted color palette. "
    "Half-body waist-up shot, three-quarter angle, "
    "subject facing slightly toward camera-left, eye-level framing. "
    "IMPORTANT: solid pure bright green background #00FF00, completely flat, no gradient, no shadow on the background, "
    "background fills entire frame except the character silhouette — this background will be removed via chroma key. "
    "Sharp clean silhouette edges — absolutely NO green tint bleeding into hair, clothing or skin. "
    "No text, no watermark, no UI, no extra characters in frame, no decorative borders, no environment elements behind subject. "
    "Lighting: soft warm key light from upper-right, gentle ambient fill. "
    "Style consistent with anime-influenced Chinese detective game character portraits."
)

# 默认使用洋红底（向后兼容）
STYLE_ANIME = STYLE_ANIME_MANGENTA

# ─── 便装版变体 ───
CASUAL_VARIANTS = [
    {
        "key": "prologue_lu_zhao",
        "filename": "prologue_lu_zhao.png",
        "variant_name": "base",
        "emotion_prompt": (
            "Expression: calm and composed, a neutral unreadable face with the faintest hint of curiosity, "
            "eyes steady and observant — the look of a man quietly analyzing everyone around him. "
            "Posture: standing upright with hands clasped behind his back, weight evenly distributed, "
            "head held high with quiet confidence."
        ),
    },
    {
        "key": "prologue_lu_zhao_cold",
        "filename": "prologue_lu_zhao_cold.png",
        "variant_name": "cold",
        "emotion_prompt": (
            "Expression: cold and authoritative, eyes narrowed to icy slits, jaw clenched, "
            "lips pressed into a thin hard line. The look of someone about to deliver a devastating accusation. "
            "Posture: standing rigidly straight, one hand extended forward with an accusatory finger, "
            "the other hand gripping a scroll at his side. Shoulders squared with imperial authority."
        ),
    },
    {
        "key": "prologue_lu_zhao_serious",
        "filename": "prologue_lu_zhao_serious.png",
        "variant_name": "serious",
        "emotion_prompt": (
            "Expression: serious and focused, brow slightly furrowed in concentration, "
            "eyes sharp and calculating, mouth set in a determined line. "
            "The look of a detective deep in thought, connecting clues. "
            "Posture: standing with one hand on his chin in a thinking pose, "
            "weight shifted slightly forward, eyes looking into the distance."
        ),
    },
    {
        "key": "prologue_lu_zhao_surprised",
        "filename": "prologue_lu_zhao_surprised.png",
        "variant_name": "surprised",
        "emotion_prompt": (
            "Expression: subtle surprise — not dramatic, but the slight widening of the eyes "
            "and a barely-parted mouth that shows this composed man has been caught off guard. "
            "Eyebrows raised slightly. Posture: leaning back just a fraction, "
            "one hand raised instinctively near his chest, the other hand frozen mid-gesture."
        ),
    },
    {
        "key": "prologue_lu_zhao_nervous",
        "filename": "prologue_lu_zhao_nervous.png",
        "variant_name": "nervous",
        "emotion_prompt": (
            "Expression: tense and guarded, brow furrowed with worry, eyes darting sideways, "
            "jaw tight, a muscle visible in his cheek. Sweat bead on temple. "
            "The look of a man whose identity is being questioned and has no proof. "
            "Posture: arms crossed defensively over his chest, shoulders slightly hunched, "
            "standing with weight shifted back as if bracing for an attack."
        ),
    },
    {
        "key": "prologue_lu_zhao_defeated",
        "filename": "prologue_lu_zhao_defeated.png",
        "variant_name": "defeated",
        "emotion_prompt": (
            "Expression: exhausted and defeated, eyes downcast with dark circles beneath, "
            "face pale and drawn, mouth slightly open as if too tired to speak. "
            "Hair slightly disheveled, loose strands falling over his face. "
            "Posture: slumping slightly, shoulders dropping, one hand hanging limply at his side, "
            "the other hand loosely holding his robe. The weight of false accusation showing."
        ),
    },
]

# ─── 官服版变体 ───
OFFICIAL_VARIANTS = [
    {
        "key": "lu_zhao",
        "filename": "lu_zhao.png",
        "variant_name": "base",
        "emotion_prompt": (
            "Expression: composed and authoritative, a neutral face with the quiet intensity of a seasoned investigator, "
            "eyes sharp and penetrating, the faintest hint of a knowing smile. "
            "Posture: standing tall and straight, one hand holding a closed folding fan at his side, "
            "the other hand resting naturally. Imperial bearing."
        ),
    },
    {
        "key": "lu_zhao_cold",
        "filename": "lu_zhao_cold.png",
        "variant_name": "cold",
        "emotion_prompt": (
            "Expression: ice-cold authority, eyes like frozen daggers, jaw set like stone, "
            "no trace of mercy on his face. The look of an imperial inspector about to pass judgment. "
            "Posture: standing ramrod straight, one hand pointing accusingly forward, "
            "fan tucked under the other arm. Every line of his body radiates authority."
        ),
    },
    {
        "key": "lu_zhao_serious",
        "filename": "lu_zhao_serious.png",
        "variant_name": "serious",
        "emotion_prompt": (
            "Expression: deeply serious and contemplative, brow furrowed, eyes narrowed in analysis, "
            "lips pressed together thoughtfully. "
            "Posture: standing with one hand on the fan held against his chin, "
            "the other arm crossed beneath it, head slightly tilted — the classic detective thinking pose."
        ),
    },
    {
        "key": "lu_zhao_surprised",
        "filename": "lu_zhao_surprised.png",
        "variant_name": "surprised",
        "emotion_prompt": (
            "Expression: rare moment of surprise — eyes widened, eyebrows raised, "
            "mouth slightly parted. For a man who always seems in control, this is a crack in the armor. "
            "Posture: leaning back slightly, one hand raised with the fan half-open, "
            "the other hand gripping his sleeve. A fraction of a second of vulnerability."
        ),
    },
    {
        "key": "lu_zhao_confrontation_pose",
        "filename": "lu_zhao_confrontation_pose.png",
        "variant_name": "confrontation",
        "emotion_prompt": (
            "Expression: fierce determination mixed with righteous anger, eyes blazing with conviction, "
            "brow sharply furrowed, mouth open mid-accusation. "
            "Posture: dramatic confrontational pose — one arm extended forward pointing accusingly, "
            "the other hand slamming a folding fan against his open palm. "
            "Body leaning forward aggressively. The pose of a man delivering the final blow in a courtroom showdown."
        ),
    },
]


# ─── API 调用 ───

def generate_image_gemini(prompt: str, api_key: str) -> bytes | None:
    for attempt in range(MAX_RETRIES):
        result = _try_gemini_generate(prompt, api_key)
        if result is not None:
            return result
        if attempt < MAX_RETRIES - 1:
            print(f"  [RETRY] 等待 {RETRY_DELAY}s 后重试 ({attempt+2}/{MAX_RETRIES})...")
            time.sleep(RETRY_DELAY)
    print("  [FALLBACK] 尝试 Imagen 模型...")
    return _try_imagen_generate(prompt, api_key)


def _try_gemini_generate(prompt: str, api_key: str) -> bytes | None:
    url = GEMINI_URL.format(model=GEMINI_MODEL, key=api_key)
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]}
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
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
        print("  [ERROR] No candidates", file=sys.stderr)
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
    payload = {"instances": [{"prompt": prompt}], "parameters": {"sampleCount": 1}}
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
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
    return ((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2) ** 0.5


def remove_chroma(img: Image.Image, threshold: float = 40.0) -> Image.Image:
    """色键去除背景：自动检测并去除洋红色或绿色背景。"""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    # 检测背景主色调：采样左上角判断是绿底还是洋红底
    sample_colors = []
    for sx, sy in [(5, 5), (10, 5), (5, 10), (w - 5, 5), (w // 2, 5)]:
        r, g, b, a = pixels[sx, sy]
        if a > 0:
            sample_colors.append((r, g, b))
    
    # 判断是否为绿底
    avg_g = sum(c[1] for c in sample_colors) / max(len(sample_colors), 1)
    avg_r = sum(c[0] for c in sample_colors) / max(len(sample_colors), 1)
    is_green_dominant = avg_g > avg_r + 50
    
    if is_green_dominant:
        targets = [(0, 255, 0), (0, 200, 0), (50, 255, 50)]
    else:
        targets = [(217, 54, 127), (217, 54, 128), (218, 54, 127), (255, 0, 255)]
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            min_dist = min(_color_distance(r, g, b, tr, tg, tb) for tr, tg, tb in targets)
            if min_dist < threshold:
                pixels[x, y] = (0, 0, 0, 0)
    return img


def autocrop(img: Image.Image, padding: int = 4) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        return img
    l, t, r, b = bbox
    return img.crop((max(0, l - padding), max(0, t - padding), min(img.width, r + padding), min(img.height, b + padding)))


def fit_to_portrait(img: Image.Image) -> Image.Image:
    src_w, src_h = img.size
    scale = min(PORTRAIT_W / src_w, PORTRAIT_H / src_h)
    new_w, new_h = max(1, int(src_w * scale)), max(1, int(src_h * scale))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (PORTRAIT_W, PORTRAIT_H), (0, 0, 0, 0))
    canvas.paste(resized, ((PORTRAIT_W - new_w) // 2, PORTRAIT_H - new_h), resized)
    return canvas


# ─── 主流程 ───

def generate_one(variant: dict, base_desc: str, api_key: str, dry_run: bool = False, style: str = STYLE_ANIME) -> bool:
    prompt = base_desc + "\n\n" + variant["emotion_prompt"] + style
    print(f"\n── [{variant['variant_name']}] {variant['key']}  (prompt: {len(prompt)} chars)")

    if dry_run:
        return True

    raw_bytes = generate_image_gemini(prompt, api_key)
    if not raw_bytes:
        print(f"    [FAIL] 图像生成失败")
        return False

    img = Image.open(io.BytesIO(raw_bytes)).convert("RGBA")
    print(f"    原始尺寸: {img.size}")

    DRAFT_DIR.mkdir(parents=True, exist_ok=True)
    ts = int(time.time())
    draft_path = DRAFT_DIR / f"{variant['key']}_anime_{ts}.png"
    img.save(draft_path, "PNG")
    print(f"    [DRAFT] → {draft_path.relative_to(ROOT)}")

    img = remove_chroma(img)
    img = autocrop(img, padding=4)
    img = fit_to_portrait(img)

    out_path = PORTRAIT_DIR / variant["filename"]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path, "PNG")
    print(f"    [OK] → {out_path.relative_to(ROOT)}  ({img.size[0]}x{img.size[1]})")
    return True


def main():
    ap = argparse.ArgumentParser(description="陆昭二次元风格立绘生成器（便装版 + 官服版）")
    ap.add_argument("--api-key", default=os.environ.get("GEMINI_API_KEY"))
    ap.add_argument("--version", choices=["casual", "official", "all"], default="all",
                    help="生成哪个版本：casual(便装) / official(官服) / all(两者)")
    ap.add_argument("--only", help="只生成指定变体名（如 base, cold, serious 等）")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not args.dry_run and not args.api_key:
        print("需要 --api-key 或 GEMINI_API_KEY 环境变量", file=sys.stderr)
        sys.exit(1)

    PORTRAIT_DIR.mkdir(parents=True, exist_ok=True)
    DRAFT_DIR.mkdir(parents=True, exist_ok=True)

    versions = []
    if args.version in ("casual", "all"):
        versions.append(("便装版", CASUAL_BASE, CASUAL_VARIANTS, STYLE_ANIME_MANGENTA))
    if args.version in ("official", "all"):
        versions.append(("官服版", OFFICIAL_BASE, OFFICIAL_VARIANTS, STYLE_ANIME_GREEN))

    for ver_name, base_desc, variants, style in versions:
        print(f"\n{'='*50}")
        print(f"  {ver_name} — 陆昭")
        print(f"{'='*50}")

        targets = variants
        if args.only:
            targets = [v for v in variants if v["variant_name"] == args.only]
            if not targets:
                print(f"  未找到变体: {args.only}")
                continue

        ok, fail = 0, 0
        for v in targets:
            if generate_one(v, base_desc, args.api_key or "", args.dry_run, style=style):
                ok += 1
            else:
                fail += 1
        print(f"\n  {ver_name} 完成：{ok} 成功 / {fail} 失败")

    print(f"\n{'='*50}")
    print("全部完成。portrait_expressions.json 无需修改（文件名不变）。")


if __name__ == "__main__":
    main()
