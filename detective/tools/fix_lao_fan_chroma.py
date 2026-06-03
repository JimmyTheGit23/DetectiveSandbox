#!/usr/bin/env python3
"""
修复老范立绘的色键去背问题。
使用更鲁棒的颜色距离算法替代简单阈值判断。
"""

from __future__ import annotations
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("需要 Pillow: pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
DRAFT_DIR = ROOT / "assets" / "ai_raw" / "portraits"
FINAL_DIR = ROOT / "assets" / "cn" / "portraits"

PORTRAIT_W = 603
PORTRAIT_H = 900

# 需要重新处理的变体
VARIANTS = [
    "prologue_lao_fan",
    "prologue_lao_fan_collapsed",
    "prologue_lao_fan_frozen",
    "prologue_lao_fan_shaken",
    "prologue_lao_fan_sneering",
]


def color_distance(r1: int, g1: int, b1: int, r2: int, g2: int, b2: int) -> float:
    """欧几里得颜色距离。"""
    return ((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2) ** 0.5


def remove_magenta_advanced(img: Image.Image, distance_threshold: float = 40.0) -> Image.Image:
    """
    高级色键去除洋红色/玫红色背景。
    Gemini API 生成的背景实际颜色约为 RGB(217, 54, 127)，非纯 #FF00FF。
    使用颜色距离匹配多个目标色值。
    """
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    # Gemini 实际生成的背景色目标（从采样数据得出）
    targets = [
        (217, 54, 127),   # 主要背景色
        (217, 54, 128),   # 微变体
        (218, 54, 127),   # 微变体
        (255, 0, 255),    # 纯洋红（兼容）
    ]
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            
            # 检查是否接近任一目标背景色
            min_dist = min(color_distance(r, g, b, tr, tg, tb) for tr, tg, tb in targets)
            
            if min_dist < distance_threshold:
                pixels[x, y] = (0, 0, 0, 0)
    
    return img


def autocrop(img: Image.Image, padding: int = 4) -> Image.Image:
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
    """缩放到 603×900，居底对齐。"""
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


def find_latest_draft(key: str) -> Path | None:
    """找到最新的草图文件。"""
    drafts = sorted(DRAFT_DIR.glob(f"{key}_anime_*.png"), key=lambda p: p.stat().st_mtime)
    return drafts[-1] if drafts else None


def main():
    for variant in VARIANTS:
        draft = find_latest_draft(variant)
        if not draft:
            print(f"  [SKIP] {variant}: 未找到草图")
            continue
        
        print(f"\n── 处理 {variant}")
        print(f"    草图: {draft.relative_to(ROOT)}")
        
        img = Image.open(draft).convert("RGBA")
        print(f"    原始尺寸: {img.size}")
        
        # 高级色键去背
        img = remove_magenta_advanced(img, distance_threshold=55.0)
        
        # 裁剪透明边框
        img = autocrop(img, padding=4)
        print(f"    裁剪后: {img.size}")
        
        # 标准化
        img = fit_to_portrait(img)
        
        # 保存
        out_path = FINAL_DIR / f"{variant}.png"
        img.save(out_path, "PNG")
        print(f"    [OK] → {out_path.relative_to(ROOT)}  ({img.size[0]}x{img.size[1]})")
    
    print("\n=== 完成 ===")


if __name__ == "__main__":
    main()
