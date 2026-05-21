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


def _connected_background_mask(rgb: np.ndarray, bg: np.ndarray, tolerance: float = 78.0) -> np.ndarray:
    h, w, _ = rgb.shape
    dist = np.linalg.norm(rgb.astype(np.float32) - bg.astype(np.float32), axis=2)

    # 只把紫/绿纯色底作为候选，避免误删衣服/肤色。
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    bg_is_green = bg[1] > bg[0] + 35 and bg[1] > bg[2] + 35
    bg_is_purple = bg[0] > bg[1] + 25 and bg[2] > bg[1] + 25
    if bg_is_green:
        chroma_candidate = (g > r + 28) & (g > b + 28)
    elif bg_is_purple:
        chroma_candidate = (r > g + 20) & (b > g + 20)
    else:
        chroma_candidate = np.ones((h, w), dtype=bool)

    candidate = (dist < tolerance) & chroma_candidate
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
    """清掉已经透明化后仍可见的紫/绿描边。"""
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    transparent = a < 8
    transparent_img = Image.fromarray((transparent.astype(np.uint8) * 255), mode="L")
    # 放宽边缘带：Gemini img2img 常把纯紫底压成一圈暗紫/灰紫半透明边。
    edge_band = np.array(transparent_img.filter(ImageFilter.MaxFilter(size=27)), dtype=np.uint8) > 0

    purple = (a > 8) & edge_band & (r > g + 8) & (b > g + 8) & (((r + b) * 0.5) > g + 12)
    blue_purple = (a > 8) & edge_band & (b > g + 10) & (r > g + 2)
    green = (a > 8) & edge_band & (g > r + 12) & (g > b + 12)
    fringe = purple | blue_purple | green
    if not np.any(fringe):
        return data

    # 最外层色键污染不做灰化，直接透明，避免在深色背景上出现灰边。
    data[:, :, 3][fringe] = 0

    # 对紧邻透明区域的低 alpha 雾边再收一次。
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    transparent = a < 8
    transparent_img = Image.fromarray((transparent.astype(np.uint8) * 255), mode="L")
    tight_edge = np.array(transparent_img.filter(ImageFilter.MaxFilter(size=9)), dtype=np.uint8) > 0
    edge_haze = tight_edge & (a > 0) & (a < 96)
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

    # 扩大一点背景区域，吃掉紧贴人物的色边。
    bg_img = Image.fromarray((bg_mask.astype(np.uint8) * 255), mode="L")
    bg_expanded = bg_img.filter(ImageFilter.MaxFilter(size=3))
    bg_soft = bg_expanded.filter(ImageFilter.GaussianBlur(radius=1.2))
    bg_alpha = np.array(bg_soft, dtype=np.float32) / 255.0

    alpha = data[:, :, 3]
    alpha = alpha * (1.0 - bg_alpha)
    data[:, :, 3] = np.clip(alpha, 0, 255)

    # 全局色键：处理人物手臂/烟杆/发丝围出的内部孔洞；这些区域不连到画布边缘，不能只靠 flood fill。
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    global_purple = (a > 0) & (r > g + 18) & (b > g + 18) & (((r + b) * 0.5) > g + 32)
    global_green = (a > 0) & (g > r + 28) & (g > b + 28)
    data[:, :, 3][global_purple | global_green] = 0

    # 第一遍：处理半透明色边。
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    edge = (a > 3) & (a < 245)
    purple = edge & (r > g + 8) & (b > g + 8)
    green = edge & (g > r + 8) & (g > b + 8)
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


# 旧入口名保留，兼容已有调用。
def defringe_purple(path: str, out_path: str | None = None) -> None:
    remove_chroma_background(path, out_path)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python defringe_portrait.py <image.png> [output.png]")
        sys.exit(1)
    inp = sys.argv[1]
    outp = sys.argv[2] if len(sys.argv) > 2 else inp
    if not Path(inp).exists():
        print(f"File not found: {inp}")
        sys.exit(1)
    remove_chroma_background(inp, outp)
