#!/usr/bin/env python3
"""
整图帧动态立绘生成器 —— 紫色背景 + 抠图流程。

策略：
  1. 原图加紫底 → Gemini 生成闭眼版、张嘴版（紫底）
  2. remove_purple_bg.py 抠图得到透明背景
  3. 引擎内整图切换：idle_0↔idle_1(眨眼), silent↔talk(说话)

用法：
  GEMINI_API_KEY=xxx python3 tools/gen_portrait_frames.py --char shen_qingyue
"""

from __future__ import annotations
import argparse, os, sys
from io import BytesIO
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
PORTRAITS = ROOT / "assets" / "cn" / "portraits"
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"

DEFAULT_BASE = {
    "shen_qingyue": PORTRAITS / "prologue_shen_qingyue.png",
}

PROMPT_BLINK = """This is a character portrait with a SOLID MAGENTA (#FF00FF) background.

Edit ONLY the character's eyes: make them FULLY CLOSED (natural relaxed blink, gentle eyelids).
- Keep the SOLID MAGENTA (#FF00FF) background EXACTLY as is — do NOT change the background color or pattern
- Keep EVERYTHING else identical: pose, hair, eyebrows, nose, mouth, clothing, accessories, hands, body, lighting
- ONLY the eyes change from open to closed
- Output at the EXACT same size (848x1264)"""

PROMPT_TALK = """This is a character portrait with a SOLID MAGENTA (#FF00FF) background.

Edit ONLY the character's mouth: make it OPEN as if speaking a syllable (natural, slightly open, relaxed).
- Keep the SOLID MAGENTA (#FF00FF) background EXACTLY as is — do NOT change the background color or pattern
- Keep EVERYTHING else identical: pose, hair, eyebrows, eyes, nose, clothing, accessories, hands, body, lighting
- ONLY the mouth changes from closed to slightly open
- Output at the EXACT same size (848x1264)"""


def setup_client():
    if not API_KEY:
        raise RuntimeError("请设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
    from google import genai
    return genai.Client(api_key=API_KEY)


def _gen_image(client, src_path: Path, prompt: str, target_size: tuple) -> Image.Image | None:
    from google.genai import types
    with open(src_path, "rb") as f:
        img_part = types.Part.from_bytes(data=f.read(), mime_type="image/png")
    resp = client.models.generate_content(
        model=MODEL,
        contents=[img_part, prompt],
        config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
    )
    for part in resp.candidates[0].content.parts:
        if getattr(part, "inline_data", None) is not None:
            img = Image.open(BytesIO(part.inline_data.data)).convert("RGBA")
            if img.size != target_size:
                img = img.resize(target_size, Image.LANCZOS)
            return img
        if getattr(part, "text", None):
            print(f"  [text] {part.text[:200]}")
    return None


def make_purple_bg(src_path: Path, out_path: Path) -> Path:
    """将透明背景的立绘转为紫色背景版本。"""
    img = Image.open(src_path).convert("RGBA")
    arr = np.array(img)
    mask_transparent = arr[:, :, 3] == 0
    arr[mask_transparent, 0] = 255  # R
    arr[mask_transparent, 1] = 0    # G
    arr[mask_transparent, 2] = 255  # B
    arr[mask_transparent, 3] = 255  # A
    result = Image.fromarray(arr)
    result.save(out_path)
    return out_path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--char", default="shen_qingyue")
    ap.add_argument("--base", default="")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    base_path = Path(args.base) if args.base else DEFAULT_BASE.get(args.char)
    if base_path is None or not base_path.exists():
        print(f"找不到基准立绘：{base_path}")
        sys.exit(1)

    base = Image.open(base_path).convert("RGBA")
    size = base.size
    print(f"基准：{base_path.name}  尺寸 {size}")

    out_dir = PORTRAITS / "anim_layers" / args.char
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.dry_run:
        print("  [dry-run] 将生成 idle_0/idle_1/talk_0/talk_1")
        return

    # ── Step 0: 生成紫底原图 ──
    purple_path = out_dir / "purple_bg_base.png"
    if not purple_path.exists():
        print("生成紫底原图...")
        make_purple_bg(base_path, purple_path)
        print(f"  ✓ {purple_path}")

    # ── Step 0b: 抠图 idle_0 (原图紫底版 → 透明底) ──
    idle_0_path = out_dir / "idle_0.png"
    if not idle_0_path.exists():
        print("抠图 idle_0...")
        os.system(f"python3 {ROOT / 'tools' / 'remove_purple_bg.py'} {purple_path} {idle_0_path}")
    else:
        print(f"  idle_0.png 已存在，跳过")

    client = setup_client()

    # ── Step 1: 生成闭眼整图 ──
    print("\n[1/2] 生成闭眼整图...")
    blink_img = _gen_image(client, purple_path, PROMPT_BLINK, size)
    if blink_img:
        blink_raw_path = out_dir / "idle_1_raw.png"
        blink_img.save(blink_raw_path)
        
        # 检查紫色背景是否保留
        arr = np.array(blink_img)
        purple = (arr[:,:,0] > 200) & (arr[:,:,1] < 60) & (arr[:,:,2] > 200)
        purple_pct = purple.sum() / (arr.shape[0] * arr.shape[1]) * 100
        print(f"  紫色背景保留: {purple_pct:.1f}%")
        
        if purple_pct > 10:
            # 紫色背景保留，可以抠图
            idle_1_path = out_dir / "idle_1.png"
            print(f"  抠图中...")
            os.system(f"python3 {ROOT / 'tools' / 'remove_purple_bg.py'} {blink_raw_path} {idle_1_path}")
            print(f"  ✓ idle_1.png")
        else:
            print(f"  ⚠️ 紫色背景丢失，保存原始版本备用")
            blink_img.save(out_dir / "idle_1_notpurple.png")
    else:
        print("  ✗ 生成失败")

    # ── Step 2: 生成张嘴整图 ──
    print("\n[2/2] 生成张嘴整图...")
    talk_img = _gen_image(client, purple_path, PROMPT_TALK, size)
    if talk_img:
        talk_raw_path = out_dir / "talk_1_raw.png"
        talk_img.save(talk_raw_path)
        
        arr = np.array(talk_img)
        purple = (arr[:,:,0] > 200) & (arr[:,:,1] < 60) & (arr[:,:,2] > 200)
        purple_pct = purple.sum() / (arr.shape[0] * arr.shape[1]) * 100
        print(f"  紫色背景保留: {purple_pct:.1f}%")
        
        if purple_pct > 10:
            talk_1_path = out_dir / "talk_1.png"
            print(f"  抠图中...")
            os.system(f"python3 {ROOT / 'tools' / 'remove_purple_bg.py'} {talk_raw_path} {talk_1_path}")
            print(f"  ✓ talk_1.png")
        else:
            print(f"  ⚠️ 紫色背景丢失，保存原始版本备用")
            talk_img.save(out_dir / "talk_1_notpurple.png")
    else:
        print("  ✗ 生成失败")

    print("\n完成！重新打开项目让 Godot 导入新 png 即可。")


if __name__ == "__main__":
    main()
