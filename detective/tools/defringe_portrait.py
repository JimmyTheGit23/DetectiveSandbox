from __future__ import annotations

from collections import deque
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageFilter


def _border_rgb(data: np.ndarray) -> np.ndarray:
    h, w, _ = data.shape
    border = np.concatenate([
        data[0, :, :3],
        data[h - 1, :, :3],
        data[:, 0, :3],
        data[:, w - 1, :3],
    ], axis=0)
    return np.median(border, axis=0)


def _connected_background_mask(rgb: np.ndarray, bg: np.ndarray, tolerance: float = 70.0) -> np.ndarray:
    h, w, _ = rgb.shape
    dist = np.linalg.norm(rgb.astype(np.float32) - bg.astype(np.float32), axis=2)

    # 只把紫/绿纯色底作为候选，避免误删衣服/肤色。
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    bg_is_green = bg[1] > bg[0] + 15 and bg[1] > bg[2] + 15
    bg_is_purple = bg[0] > bg[1] + 15 and bg[2] > bg[1] + 15
    if bg_is_green:
        chroma_candidate = (g > r + 30) & (g > b + 30)
    elif bg_is_purple:
        chroma_candidate = (r > g + 22) & (b > g + 22)
    else:
        chroma_candidate = np.ones((h, w), dtype=bool)

    # flood fill 从画布边缘向内扩展，仅依赖距离阈值。
    # chroma_candidate 对暗绿色背景误判率高，改为只用距离。
    candidate = dist < tolerance
    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()

    def push(y: int, x: int) -> None:
        if 0 <= y < h and 0 <= x < w and candidate[y, x] and not visited[y, x]:
            visited[y, x] = True
            q.append((y, x))

    for x in range(w):
        push(0, x)
        push(h - 1, x)
    for y in range(h):
        push(y, 0)
        push(y, w - 1)

    while q:
        y, x = q.popleft()
        push(y - 1, x)
        push(y + 1, x)
        push(y, x - 1)
        push(y, x + 1)

    return visited


def _defringe_visible_chroma(data: np.ndarray) -> np.ndarray:
    """清掉已经透明化后仍可见的紫/绿描边 — 仅限极窄边缘，不伤角色。"""
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    transparent = a < 8
    transparent_img = Image.fromarray((transparent.astype(np.uint8) * 255), mode="L")
    # 只取 5px 边缘带（原来 27px 太宽，会吃掉角色）
    edge_band = np.array(transparent_img.filter(ImageFilter.MaxFilter(size=5)), dtype=np.uint8) > 0

    purple = (a > 8) & edge_band & (r > g + 12) & (b > g + 12) & (((r + b) * 0.5) > g + 18)
    blue_purple = (a > 8) & edge_band & (b > g + 15) & (r > g + 5)
    green = (a > 8) & edge_band & (g > r + 15) & (g > b + 15)
    fringe = purple | blue_purple | green
    if not np.any(fringe):
        return data

    # 最外层色键污染不做灰化，直接透明，避免在深色背景上出现灰边。
    data[:, :, 3][fringe] = 0

    # 对紧邻透明区域的低 alpha 雾边再收一次 — 只收 3px（原来 9px 太宽）。
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    transparent = a < 8
    transparent_img = Image.fromarray((transparent.astype(np.uint8) * 255), mode="L")
    tight_edge = np.array(transparent_img.filter(ImageFilter.MaxFilter(size=3)), dtype=np.uint8) > 0
    edge_haze = tight_edge & (a > 0) & (a < 64)
    data[:, :, 3][edge_haze] = 0

    return data


def remove_chroma_background(path: str, out_path: str | None = None) -> None:
    """移除AI立绘的紫色/绿色纯色背景，并做去边。"""
    if out_path is None:
        out_path = path

    img = Image.open(path).convert("RGBA")
    data = np.array(img, dtype=np.float32)
    rgb = data[:, :, :3].astype(np.uint8)
    bg = _border_rgb(data).astype(np.float32)

    bg_mask = _connected_background_mask(rgb, bg)

    # 扩大一点背景区域，吃掉紧贴人物的色边 — 只扩 1 像素（用 3x3 MaxFilter），避免吃掉角色。
    bg_img = Image.fromarray((bg_mask.astype(np.uint8) * 255), mode="L")
    bg_expanded = bg_img.filter(ImageFilter.MaxFilter(size=3))
    bg_soft = bg_expanded.filter(ImageFilter.GaussianBlur(radius=0.8))
    bg_alpha = np.array(bg_soft, dtype=np.float32) / 255.0

    alpha = data[:, :, 3]
    alpha = alpha * (1.0 - bg_alpha)
    data[:, :, 3] = np.clip(alpha, 0, 255)

    # 全局色键：处理人物手臂/烟杆/发丝围出的内部孔洞；这些区域不连到画布边缘，不能只靠 flood fill。
    # 仅在已确认是背景色的区域应用，避免误删角色像素。
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    global_purple = (a > 0) & (r > g + 30) & (b > g + 30) & (((r + b) * 0.5) > g + 45)
    global_green = (a > 0) & (g > r + 45) & (g > b + 45)
    data[:, :, 3][global_purple | global_green] = 0

    # 第一遍：处理半透明色边 — 仅限紧邻透明区域的极窄边缘（3px）。
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    transparent_for_edge = a < 8
    transparent_img_edge = Image.fromarray((transparent_for_edge.astype(np.uint8) * 255), mode="L")
    narrow_edge = np.array(transparent_img_edge.filter(ImageFilter.MaxFilter(size=3)), dtype=np.uint8) > 0
    edge = narrow_edge & (a > 3) & (a < 245)
    purple = edge & (r > g + 12) & (b > g + 12)
    green = edge & (g > r + 15) & (g > b + 15)
    fringe = purple | green
    if np.any(fringe):
        neutral = np.median(data[~bg_mask & (a > 200), :3], axis=0) if np.any(~bg_mask & (a > 200)) else np.array([120, 100, 85])
        data[fringe, 0] = data[fringe, 0] * 0.55 + neutral[0] * 0.45
        data[fringe, 1] = data[fringe, 1] * 0.55 + neutral[1] * 0.45
        data[fringe, 2] = data[fringe, 2] * 0.55 + neutral[2] * 0.45

    # 第二遍：处理仍然不透明、但肉眼可见的紫/绿外描边。
    data = _defringe_visible_chroma(data)

    result = Image.fromarray(np.clip(data, 0, 255).astype(np.uint8), mode="RGBA")
    result.save(out_path)
    print(f"Saved transparent portrait: {out_path}")


def despill_green_from_hair(path: str, out_path: str | None = None) -> int:
    """
    Post-rembg green spill removal - specifically targets green contamination
    in dark areas (hair) and semi-transparent edges that rembg misses.

    Known issue: When using green (#00FF00) backgrounds, rembg removes the bulk
    but leaves green channel contamination in:
    - Black/dark hair strands (G slightly > R and B, very visible on dark pixels)
    - Hairpin/accessory areas near edges
    - Semi-transparent edge pixels

    This function runs 5 passes:
    1. Remove very-green semi-transparent edge pixels (alpha → 0)
    2. Clamp green in dark areas (hair) to max(R, B)
    3. Reduce green in medium areas with green shift
    4. Fix hairpin area (upper 1/3 of image)
    5. Edge band detection + green clamping

    Returns number of pixels modified.
    """
    if out_path is None:
        out_path = path

    img = Image.open(path).convert("RGBA")
    data = np.array(img, dtype=np.float64)
    original = data.copy()
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]

    visible = a > 0

    # Pass 1: Very-green semi-transparent edge pixels → fully transparent
    semi_transparent = (a > 0) & (a < 200)
    very_green_edge = semi_transparent & (g > r + 40) & (g > b + 40)
    data[very_green_edge, 3] = 0
    # Mild green edge: reduce green channel
    mild_green_edge = semi_transparent & (g > r + 15) & (g > b + 15) & ~very_green_edge
    data[mild_green_edge, 1] = (data[mild_green_edge, 0] + data[mild_green_edge, 2]) / 2

    # Pass 2: Dark areas (hair) - clamp G to max(R, B)
    dark_area = visible & (a > 100) & (r < 100) & (b < 100)
    green_in_hair = dark_area & (g > np.maximum(r, b) + 3)
    max_rb = np.maximum(r, b)
    data[green_in_hair, 1] = max_rb[green_in_hair]

    # Pass 3: Medium-tone areas with noticeable green shift
    medium_area = visible & (a > 100) & ~dark_area
    green_shifted = medium_area & (g > r + 15) & (g > b + 15)
    avg_rb = (r + b) / 2
    excess = g - avg_rb
    data[green_shifted, 1] = avg_rb[green_shifted] + np.minimum(excess[green_shifted] * 0.1, 5)

    # Pass 4: Hairpin / upper-third area (often picks up green from background)
    h, w = data.shape[:2]
    upper_third = np.zeros_like(visible)
    upper_third[:h // 3, :] = True
    hairpin_green = upper_third & visible & (a > 100) & (g > r + 8) & (g > b + 8)
    data[hairpin_green, 1] = np.maximum(r[hairpin_green], b[hairpin_green])

    # Pass 5: Edge band - erode alpha mask, treat outer 2px ring aggressively
    from scipy import ndimage
    alpha_binary = (data[:, :, 3] > 50).astype(np.uint8)
    interior = ndimage.binary_erosion(alpha_binary, iterations=2)
    edge_band = (alpha_binary > 0) & ~interior
    edge_green = edge_band & (data[:, :, 1] > data[:, :, 0] + 5) & (data[:, :, 1] > data[:, :, 2] + 5)
    data[edge_green, 1] = np.maximum(data[edge_green, 0], data[edge_green, 2])

    data = np.clip(data, 0, 255).astype(np.uint8)
    result = Image.fromarray(data)
    result.save(out_path, "PNG")

    changed = np.any(data != original.astype(np.uint8), axis=2).sum()
    print(f"despill_green_from_hair: fixed {changed} pixels → {out_path}")
    return int(changed)


# 旧入口名保留，兼容已有调用。
def defringe_purple(path: str, out_path: str | None = None) -> None:
    remove_chroma_background(path, out_path)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python defringe_portrait.py <image.png> [output.png] [--despill-green]")
        sys.exit(1)
    inp = sys.argv[1]
    outp = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else inp
    if not Path(inp).exists():
        print(f"File not found: {inp}")
        sys.exit(1)
    if "--despill-green" in sys.argv:
        despill_green_from_hair(inp, outp)
    else:
        remove_chroma_background(inp, outp)
