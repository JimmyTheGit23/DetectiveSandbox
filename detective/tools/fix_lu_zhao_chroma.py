#!/usr/bin/env python3
"""
修复陆昭立绘 v2：
- HSV 色相范围去除洋红色背景（比颜色距离更鲁棒）
- 漫灌填充清理残留背景碎片
- 边缘 defringe 去除粉色轮廓
- 保留帽子宽度
"""

from __future__ import annotations
import sys
from pathlib import Path
from collections import deque

try:
    from PIL import Image
    import colorsys
except ImportError:
    print("需要 Pillow: pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
DRAFT_DIR = ROOT / "assets" / "ai_raw" / "portraits"
FINAL_DIR = ROOT / "assets" / "cn" / "portraits"

PORTRAIT_W = 603
PORTRAIT_H = 900

VARIANTS = [
    "lu_zhao", "lu_zhao_cold", "lu_zhao_serious", "lu_zhao_surprised",
    "lu_zhao_confrontation_pose",
    "prologue_lu_zhao", "prologue_lu_zhao_cold", "prologue_lu_zhao_serious",
    "prologue_lu_zhao_surprised", "prologue_lu_zhao_nervous", "prologue_lu_zhao_defeated",
]


def is_magenta_hue(r: int, g: int, b: int, sat_threshold: float = 0.25, hue_min: float = 300, hue_max: float = 350) -> bool:
    """判断像素是否属于洋红/粉红色相范围。"""
    h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    hue_deg = h * 360
    # 洋红色相范围：300°-350°（品红-洋红），饱和度不能太低
    if hue_min <= hue_deg <= hue_max and s > sat_threshold and v > 0.15:
        return True
    # 也覆盖接近纯红偏粉的区域：350°-360° 和 0°-10°
    if (350 <= hue_deg or hue_deg <= 10) and s > sat_threshold and v > 0.15:
        # 需要 R 明显高于 G 才算
        if r > g + 30 and r > b:
            return True
    return False


def remove_background_hsv(img: Image.Image) -> Image.Image:
    """HSV 色相范围去背景 + 边缘漫灌清理。"""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    # Pass 1: HSV 色相范围去除洋红色像素
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if is_magenta_hue(r, g, b, sat_threshold=0.20):
                pixels[x, y] = (0, 0, 0, 0)
    
    # Pass 2: 漫灌填充——从四角和边中点开始，清除连通的残留背景碎片
    visited = set()
    queue = deque()
    
    # 种子点：四角 + 四边中点
    seeds = [
        (0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
        (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2),
        # 加更多边缘种子
        (w // 4, 0), (3 * w // 4, 0), (w // 4, h - 1), (3 * w // 4, h - 1),
    ]
    
    for sx, sy in seeds:
        if 0 <= sx < w and 0 <= sy < h:
            r, g, b, a = pixels[sx, sy]
            if a > 0:  # 只从非透明像素开始漫灌
                queue.append((sx, sy))
                visited.add((sx, sy))
    
    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        
        # 如果这个像素是洋红色调或非常暗（背景碎片），设为透明
        if a > 0 and (is_magenta_hue(r, g, b, sat_threshold=0.15) or (r > 150 and g < 80 and b > 80)):
            pixels[x, y] = (0, 0, 0, 0)
            # 向四方向扩展
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    visited.add((nx, ny))
                    queue.append((nx, ny))
    
    return img


def defringe(img: Image.Image, radius: int = 2) -> Image.Image:
    """边缘去粉色：对透明像素邻近的非透明像素降低洋红成分。"""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    edge_pixels = set()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                for dy in range(-radius, radius + 1):
                    for dx in range(-radius, radius + 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h:
                            nr, ng, nb, na = pixels[nx, ny]
                            if na > 10:
                                edge_pixels.add((nx, ny))
                                break
                    else:
                        continue
                    break
    
    for x, y in edge_pixels:
        r, g, b, a = pixels[x, y]
        if a == 0:
            continue
        magenta_bias = max(0, r - g)
        if magenta_bias > 30 and r > 140:
            factor = min(1.0, magenta_bias / 120.0) * 0.6
            new_r = int(r * (1 - factor * 0.4))
            new_g = int(g + (r - g) * factor * 0.3)
            new_b = int(b * (1 - factor * 0.2))
            pixels[x, y] = (max(0, min(255, new_r)), max(0, min(255, new_g)), max(0, min(255, new_b)), a)
    
    return img


def autocrop_safe(img: Image.Image, padding: int = 6) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        return img
    l, t, r, b = bbox
    return img.crop((max(0, l - padding * 2), max(0, t - padding), min(img.width, r + padding * 2), min(img.height, b + padding)))


def fit_to_portrait(img: Image.Image) -> Image.Image:
    src_w, src_h = img.size
    scale = min(PORTRAIT_W / src_w, PORTRAIT_H / src_h)
    new_w, new_h = max(1, int(src_w * scale)), max(1, int(src_h * scale))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (PORTRAIT_W, PORTRAIT_H), (0, 0, 0, 0))
    canvas.paste(resized, ((PORTRAIT_W - new_w) // 2, PORTRAIT_H - new_h), resized)
    return canvas


def find_latest_draft(key: str) -> Path | None:
    drafts = sorted(DRAFT_DIR.glob(f"{key}_anime_*.png"), key=lambda p: p.stat().st_mtime)
    return drafts[-1] if drafts else None


def main():
    for variant in VARIANTS:
        draft = find_latest_draft(variant)
        if not draft:
            print(f"  [SKIP] {variant}")
            continue
        
        print(f"\n── {variant}")
        img = Image.open(draft).convert("RGBA")
        
        img = remove_background_hsv(img)
        img = defringe(img, radius=2)
        img = autocrop_safe(img, padding=6)
        print(f"    裁剪后: {img.size}")
        
        img = fit_to_portrait(img)
        out = FINAL_DIR / f"{variant}.png"
        img.save(out, "PNG")
        print(f"    [OK] → {out.relative_to(ROOT)}")
    
    print("\n=== 完成 ===")


if __name__ == "__main__":
    main()
