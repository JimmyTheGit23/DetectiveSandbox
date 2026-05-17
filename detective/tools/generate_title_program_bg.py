#!/usr/bin/env python3
"""使用 Gemini 3 Pro Image (nano-banana-pro) 生成"推理者计划"主界面背景。

设计意图：
- 跨时代、跨风格的"推理者计划"主屏背景
- 中心是一个发光的圆形终端 / 全息卷宗墙 / 时空交错的卷宗
- 周围漂浮着代表不同时代不同案件的元素剪影：
    明代竹简 / 维多利亚怀表 / 老式打字机 / 现代手机 / 未来全息卡
- 整体冷色调（深蓝/墨绿/靛紫），少量琥珀金高光
- 不出现任何文字、字母、数字（标题会由游戏 UI 绘制）
- 16:9 横幅，1280x720（保留更多顶部留白给标题）

输出：
  assets/ai_raw/scenes/title_program_<ts>.png      草图（原始 Gemini 输出）
  assets/cn/scenes/title_screen.png                覆盖现有标题图（备份到 title_screen.png.bak）
"""
from __future__ import annotations
import os, sys, time, base64, shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "assets/ai_raw/scenes"
FINAL = ROOT / "assets/cn/scenes/title_screen.png"
BACKUP = ROOT / "assets/cn/scenes/title_screen.png.bak"

PROMPT = (
    "Cinematic title screen background, 16:9 widescreen, no text, no letters, no numbers, no logo. "
    "Theme: 'Detective Program' — a clandestine recruitment platform that selects elite reasoners from across history. "
    "Composition: a vast dim circular chamber, dark teal and deep indigo tones with subtle amber rim light. "
    "Centerpiece: a glowing translucent holographic dossier wall / starmap of cases, faint blueprint lines, soft volumetric light. "
    "Foreground silhouettes scattered like puzzle shards: a Ming dynasty bamboo slip, a Victorian pocket watch, a 1940s noir typewriter, "
    "a modern smartphone with case file, a futuristic holographic data card, an antique magnifying glass and red string. "
    "These are arranged in a slowly orbiting halo around the central chamber, suggesting different eras converging into one investigation. "
    "Atmosphere: mysterious, focused, sober, slightly melancholic; high contrast cinematic lighting, soft fog at edges, "
    "subtle film grain. NO characters, NO faces. Empty composition with strong negative space on the upper third for a title overlay. "
    "Style: painterly digital matte painting, modern AAA game key art quality. "
    "Aspect ratio 16:9, intended resolution 1280x720."
)


def main() -> int:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("缺少 GEMINI_API_KEY", file=sys.stderr)
        return 2
    try:
        from google import genai
        from google.genai import types
    except Exception as e:
        print("缺少 google-genai：.venv-tts/bin/pip install google-genai", file=sys.stderr)
        raise

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    ts = int(time.time())
    raw_path = RAW_DIR / f"title_program_{ts}.png"

    client = genai.Client(api_key=api_key)
    # 用 Gemini 3 Pro Image 模型
    resp = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=PROMPT,
        config=types.GenerateContentConfig(
            response_modalities=["IMAGE"],
            image_config=types.ImageConfig(aspect_ratio="16:9"),
        ),
    )
    parts = resp.candidates[0].content.parts if resp.candidates else []
    img_bytes = None
    for p in parts:
        inline = getattr(p, "inline_data", None)
        if inline and getattr(inline, "data", None):
            data = inline.data
            if isinstance(data, str):
                data = base64.b64decode(data)
            img_bytes = data
            break
    if not img_bytes:
        print("Gemini 没返回图片", file=sys.stderr)
        return 3
    raw_path.write_bytes(img_bytes)
    print(f"saved raw -> {raw_path.relative_to(ROOT)}  ({len(img_bytes)} bytes)")

    # 缩放到 1280x720 并落到正式路径（覆盖前先备份）
    try:
        from PIL import Image
    except Exception:
        print("缺 Pillow，无法缩放；直接复制原图，请人工裁切。", file=sys.stderr)
        if FINAL.exists() and not BACKUP.exists():
            shutil.copy2(FINAL, BACKUP)
        shutil.copy2(raw_path, FINAL)
        return 0

    im = Image.open(raw_path).convert("RGB")
    target = (1280, 720)
    # 等比覆盖式裁切
    src_w, src_h = im.size
    scale = max(target[0] / src_w, target[1] / src_h)
    new = im.resize((int(src_w * scale), int(src_h * scale)), Image.LANCZOS)
    nx = (new.size[0] - target[0]) // 2
    ny = (new.size[1] - target[1]) // 2
    out = new.crop((nx, ny, nx + target[0], ny + target[1]))

    if FINAL.exists() and not BACKUP.exists():
        shutil.copy2(FINAL, BACKUP)
        print(f"backup -> {BACKUP.relative_to(ROOT)}")
    out.save(FINAL, "PNG", optimize=True)
    print(f"saved final -> {FINAL.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
