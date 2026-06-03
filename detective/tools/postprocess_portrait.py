#!/usr/bin/env python3
"""
立绘后处理脚本：裁切透明边框 + 标准化尺寸。
用法：
  python tools/postprocess_portrait.py <input.png> [output.png] [--target-width 848] [--target-height 1264]
"""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image
import numpy as np


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


def fit_to_portrait(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """缩放到目标尺寸，居底对齐。"""
    src_w, src_h = img.size
    scale = min(target_w / src_w, target_h / src_h)
    new_w = max(1, int(src_w * scale))
    new_h = max(1, int(src_h * scale))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    paste_x = (target_w - new_w) // 2
    paste_y = target_h - new_h
    canvas.paste(resized, (paste_x, paste_y), resized)
    return canvas


def main():
    ap = argparse.ArgumentParser(description="立绘后处理：裁切 + 标准化尺寸")
    ap.add_argument("input", help="输入 PNG 路径")
    ap.add_argument("output", nargs="?", help="输出 PNG 路径（默认覆盖原文件）")
    ap.add_argument("--target-width", type=int, default=848, help="目标宽度（默认 848）")
    ap.add_argument("--target-height", type=int, default=1264, help="目标高度（默认 1264）")
    ap.add_argument("--padding", type=int, default=4, help="裁切边距像素（默认 4）")
    args = ap.parse_args()

    inp = Path(args.input)
    outp = Path(args.output) if args.output else inp

    img = Image.open(inp).convert("RGBA")
    print(f"原始尺寸: {img.size}")

    img = autocrop(img, padding=args.padding)
    print(f"裁切后: {img.size}")

    img = fit_to_portrait(img, args.target_width, args.target_height)
    print(f"标准化后: {img.size}")

    img.save(outp, "PNG")
    print(f"已保存: {outp}")


if __name__ == "__main__":
    main()
