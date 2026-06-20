#!/usr/bin/env python3
"""
为指定角色生成「眨眼帧」「说话口型帧」——立绘动态化用。

做法（image-to-image）：以现有立绘为基准，只修改眼睛/嘴巴，其余像素尽量保持，
保证脸部位置天然对齐，可直接作为 DialogueBox 的整图帧（_idle_0/_idle_1 / _talk_0/_talk_1）。

生成后自动：
  - 统一缩放回原立绘尺寸（保证逐帧对齐）
  - 若输出为不透明背景，则按四角颜色做近似抠图（粗处理；正式可再过 remove_purple_bg）

用法：
  GEMINI_API_KEY=xxx python3 tools/gen_portrait_anim_frames.py --char shen_qingyue
  可选 --base 指定基准立绘路径；--dry-run 只打印不调用 API。

输出：
  assets/cn/portraits/<base名>_idle_0.png   睁眼（= 原图副本）
  assets/cn/portraits/<base名>_idle_1.png   闭眼
  assets/cn/portraits/<base名>_talk_0.png   闭嘴（= 原图副本）
  assets/cn/portraits/<base名>_talk_1.png   张嘴（说话）

已知角色眼/嘴坐标(848x1264 companion规格, 从视觉标尺+像素检测校准):
  EYE_MOUTH_COORDS: dict[str, dict] — 每个 key=角色id, value含:
    eyes: [{'cx','cy','rw','rh'}, ...]  每只眼的椭圆参数(中心x/y, 半宽/半高)
    mouth: {'cx','cy','w','h'}           嘴巴椭圆参数
  新角色请先用 --detect 模式生成标尺图来手动校准坐标。
"""

# ── 已知角色的眼/嘴坐标(848×1264 companion) ──────────────────────
EYE_MOUTH_COORDS: dict[str, dict] = {
    "shen_qingyue": {
        "eyes": [
            {"cx": 421, "cy": 294, "rw": 28, "rh": 14},   # 画面左眼(角色右眼)
            {"cx": 495, "cy": 296, "rw": 29, "rh": 14},   # 画面右眼(角色左眼,上方有发丝)
        ],
        "mouth": {"cx": 460, "cy": 392, "w": 50, "h": 12},
        "lid_color": [223, 190, 173],  # 统一眼睑肤色(RGB)
    },
}
from __future__ import annotations
import argparse
import os
import sys
from io import BytesIO
from pathlib import Path

import json
import re

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
PORTRAITS = ROOT / "assets" / "cn" / "portraits"
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"

DEFAULT_BASE = {
    "shen_qingyue": PORTRAITS / "prologue_shen_qingyue.png",
}

PROMPT_BLINK = """Edit this character illustration: make the character's EYES FULLY CLOSED, as if mid-blink.

ABSOLUTE REQUIREMENTS:
- Keep EVERYTHING else 100% identical: exact same pose, body, hands, hair, clothing, accessories, colors, lighting, framing, and the SAME transparent background.
- ONLY the eyes change — gently closed eyelids (natural relaxed blink, NOT squinting, NOT smiling).
- Do not move or redraw the head, face shape, or any feature other than the eyelids.
- Output the FULL image at the same size and composition as the input, with transparent background preserved.
This is one frame of a subtle blinking animation for a visual novel."""

PROMPT_TALK = """Edit this character illustration: make the character's MOUTH OPEN as if speaking a syllable.

ABSOLUTE REQUIREMENTS:
- Keep EVERYTHING else 100% identical: exact same pose, body, hands, hair, clothing, accessories, colors, lighting, framing, eyes/expression, and the SAME transparent background.
- ONLY the mouth changes — slightly open mouth mid-speech (natural, relaxed, not exaggerated, not smiling widely).
- Do not move or redraw anything other than the mouth area.
- Output the FULL image at the same size and composition as the input, with transparent background preserved.
This is one frame of a talking animation for a visual novel."""


def setup_client():
    if not API_KEY:
        raise RuntimeError("请设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
    from google import genai
    return genai.Client(api_key=API_KEY)


def _gen_raw(client, src: Path, prompt: str, target_size) -> Image.Image | None:
    """调用 image-to-image，返回生成的整图（尺寸对齐到 target_size）。"""
    from google.genai import types
    with open(src, "rb") as f:
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
            print(f"  [text] {part.text[:160]}")
    return None


def _locate_features(client, src: Path, size) -> dict:
    """用 Gemini 视觉定位眼/嘴像素框，返回 {'eyes':[x,y,w,h],'mouth':[x,y,w,h]}。"""
    from google.genai import types
    with open(src, "rb") as f:
        img_part = types.Part.from_bytes(data=f.read(), mime_type="image/png")
    prompt = (
        f"This is a {size[0]}x{size[1]} character portrait. Return ONLY JSON with pixel "
        "bounding boxes (origin top-left, x right, y down) for: "
        "\"eyes\": box covering BOTH eyes (include eyelids, small margin); "
        "\"mouth\": box covering the mouth (small margin). "
        "Format strictly: {\"eyes\":[x,y,w,h],\"mouth\":[x,y,w,h]}"
    )
    r = client.models.generate_content(model="gemini-2.5-flash", contents=[img_part, prompt])
    m = re.search(r"\{.*\}", r.text or "", re.S)
    if not m:
        raise RuntimeError("无法定位眼/嘴坐标：" + str(r.text)[:120])
    return json.loads(m.group(0))


def _composite_region(base: Image.Image, gen: Image.Image, region, feather=10, pad=8) -> Image.Image:
    """只把 gen 的 region 区域（羽化边缘）合成回 base，消除全局漂移。"""
    W, H = base.size
    x, y, w, h = region
    x0, y0 = max(0, x - pad), max(0, y - pad)
    x1, y1 = min(W, x + w + pad), min(H, y + h + pad)
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([x0, y0, x1, y1], radius=12, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(feather))
    return Image.composite(gen, base, mask)


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
    stem = base_path.with_suffix("")
    print(f"基准：{base_path.name}  尺寸 {size}")
    if args.dry_run:
        print("  [dry-run] 将生成 idle_0/idle_1/talk_0/talk_1（含眼嘴定位+局部合成）")
        return

    # idle_0 / talk_0 = 原图副本（睁眼、闭嘴）
    base.save(Path(f"{stem}_idle_0.png")); print("  saved _idle_0 (copy)")
    base.save(Path(f"{stem}_talk_0.png")); print("  saved _talk_0 (copy)")

    client = setup_client()

    # 1) 定位眼/嘴
    feats = _locate_features(client, base_path, size)
    print(f"  features: {feats}")

    # 2) 生成闭眼整图 → 仅合成眼部
    blink = _gen_raw(client, base_path, PROMPT_BLINK, size)
    if blink is not None:
        out = _composite_region(base, blink, feats["eyes"])
        out.save(Path(f"{stem}_idle_1.png")); print("  saved _idle_1 (eyes composited)")

    # 3) 生成张嘴整图 → 仅合成嘴部
    talk = _gen_raw(client, base_path, PROMPT_TALK, size)
    if talk is not None:
        out = _composite_region(base, talk, feats["mouth"])
        out.save(Path(f"{stem}_talk_1.png")); print("  saved _talk_1 (mouth composited)")

    print("完成。重新打开项目让 Godot 导入新 png 即可。")


if __name__ == "__main__":
    main()
