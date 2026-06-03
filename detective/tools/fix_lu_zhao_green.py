#!/usr/bin/env python3
"""
修复陆昭官服版立绘：绿底去背 + 正确缩放（保留帽翅）。
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

VARIANTS = ["lu_zhao", "lu_zhao_cold", "lu_zhao_serious", "lu_zhao_surprised", "lu_zhao_confrontation_pose"]


def is_green_hue(r: int, g: int, b: int, sat_threshold: float = 0.20) -> bool:
    """判断像素是否属于绿色色相范围。"""
    h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    hue_deg = h * 360
    # 绿色色相范围：60°-170°
    if 60 <= hue_deg <= 170 and s > sat_threshold and v > 0.15:
        return True
    return False


def remove_green_bg(img: Image.Image) -> Image.Image:
    """去除绿色背景：HSV色相 + 颜色距离 + 漫灌填充。"""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    # Pass 1: HSV 色相范围去除绿色像素
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if is_green_hue(r, g, b, sat_threshold=0.15):
                pixels[x, y] = (0, 0, 0, 0)
    
    # Pass 2: 颜色距离补充去除（处理渐变区域）
    green_targets = [(0, 255, 0), (0, 200, 0), (50, 255, 50), (100, 200, 100), (0, 180, 0)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            min_dist = min(((r-tr)**2 + (g-tg)**2 + (b-tb)**2)**0.5 for tr, tg, tb in green_targets)
            if min_dist < 35:
                pixels[x, y] = (0, 0, 0, 0)
    
    # Pass 3: 漫灌填充清理残留
    visited = set()
    queue = deque()
    seeds = [(0,0),(w-1,0),(0,h-1),(w-1,h-1),(w//2,0),(w//2,h-1),(0,h//2),(w-1,h//2)]
    for sx, sy in seeds:
        r, g, b, a = pixels[sx, sy]
        if a > 0:
            queue.append((sx, sy))
            visited.add((sx, sy))
    
    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        if a > 0 and is_green_hue(r, g, b, sat_threshold=0.10):
            pixels[x, y] = (0, 0, 0, 0)
            for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                nx, ny = x+dx, y+dy
                if 0<=nx<w and 0<=ny<h and (nx,ny) not in visited:
                    visited.add((nx,ny))
                    queue.append((nx,ny))
    
    return img


def defringe(img: Image.Image, radius: int = 2) -> Image.Image:
    """边缘去绿色残留。"""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    edge = set()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                for dy in range(-radius, radius+1):
                    for dx in range(-radius, radius+1):
                        nx, ny = x+dx, y+dy
                        if 0<=nx<w and 0<=ny<h:
                            nr,ng,nb,na = pixels[nx,ny]
                            if na > 10:
                                edge.add((nx,ny))
                                break
                    else: continue
                    break
    for x, y in edge:
        r,g,b,a = pixels[x,y]
        if a == 0: continue
        green_bias = max(0, g - max(r, b))
        if green_bias > 25 and g > 120:
            f = min(1.0, green_bias / 100.0) * 0.5
            new_g = int(g * (1 - f * 0.4))
            new_r = int(r + (g - r) * f * 0.2)
            pixels[x,y] = (max(0,min(255,new_r)), max(0,min(255,new_g)), max(0,min(255,b)), a)
    return img


def autocrop(img: Image.Image, padding: int = 6) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        return img
    l,t,r,b = bbox
    return img.crop((max(0,l-padding*2), max(0,t-padding), min(img.width,r+padding*2), min(img.height,b+padding)))


def fit_to_portrait(img: Image.Image) -> Image.Image:
    """缩放到 603×900，居底对齐，保留完整宽度。"""
    src_w, src_h = img.size
    scale = min(PORTRAIT_W / src_w, PORTRAIT_H / src_h)
    new_w = max(1, int(src_w * scale))
    new_h = max(1, int(src_h * scale))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (PORTRAIT_W, PORTRAIT_H), (0, 0, 0, 0))
    canvas.paste(resized, ((PORTRAIT_W - new_w) // 2, PORTRAIT_H - new_h), resized)
    return canvas


def find_latest_draft(key: str) -> Path | None:
    drafts = sorted(DRAFT_DIR.glob(f"{key}_anime_*.png"), key=lambda p: p.stat().st_mtime)
    return drafts[-1] if drafts else None


def main():
    for v in VARIANTS:
        draft = find_latest_draft(v)
        if not draft:
            print(f"  [SKIP] {v}")
            continue
        print(f"── {v}")
        img = Image.open(draft).convert("RGBA")
        print(f"    草图: {img.size}")
        
        img = remove_green_bg(img)
        img = defringe(img)
        img = autocrop(img, padding=6)
        print(f"    裁剪后: {img.size}")
        
        img = fit_to_portrait(img)
        out = FINAL_DIR / f"{v}.png"
        img.save(out, "PNG")
        print(f"    [OK] → {out.relative_to(ROOT)}  ({img.size[0]}x{img.size[1]})")
    
    print("\n=== 完成 ===")


if __name__ == "__main__":
    main()
