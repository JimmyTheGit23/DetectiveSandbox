"""
紫色底抠图工具 v2.0：将AI生成的紫色(#FF00FF)背景图片转为透明背景。

v2.0 新增：
  - 从边缘 BFS flood fill 连通背景区（防止误删角色内部紫色区域）
  - 小连通簇清除（<3000px，去除 Gemini 水印/噪点）
  - Magenta-only despill（min(R,B)>G+8 且 |R-B|<50 → 修正R/B通道）
  - 全透明像素 RGB 清零（防止 premultiply 渗色）
  - 画布标准化模式（--portrait，输出 848×1264 或 603×900）

用法：
  python remove_purple_bg.py <输入图片或目录> [输出路径]
  python remove_purple_bg.py input.png output.png --portrait --canvas 848x1264
  python remove_purple_bg.py input.png output.png --no-despill
"""
from __future__ import annotations

from collections import deque
from PIL import Image, ImageFilter
import numpy as np
import sys
import os
import glob
from pathlib import Path
from scipy import ndimage

from portrait_generation_spec import NPC_KNEE_UP_SPEC, fit_subject_to_spec

PURPLE_R, PURPLE_G, PURPLE_B = 255, 0, 255  # #FF00FF

# 标准画布尺寸
CANVAS_COMPANION = (848, 1264)  # 伙伴角色
CANVAS_NPC = (603, 900)         # NPC/序章角色


def _border_rgb(data: np.ndarray, border_px: int = 5) -> np.ndarray:
    """从四边取条带，返回中位数 RGB 作为背景参考色。"""
    h, w, _ = data.shape
    top = data[:border_px, :, :3].reshape(-1, 3)
    bottom = data[h - border_px:, :, :3].reshape(-1, 3)
    left = data[:, :border_px, :3].reshape(-1, 3)
    right = data[:, w - border_px:, :3].reshape(-1, 3)
    strips = np.concatenate([top, bottom, left, right], axis=0)
    return np.median(strips, axis=0)


def _flood_fill_background(rgb: np.ndarray, bg: np.ndarray, threshold: float = 78.0) -> np.ndarray:
    """BFS 从画布边缘扩展，标记与背景色连通的紫色区域。"""
    h, w, _ = rgb.shape
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    dist = np.linalg.norm(rgb.astype(np.float32) - bg.astype(np.float32), axis=2)

    # 紫色候选：距离背景色近 且 颜色偏紫
    chroma_candidate = (r > g + 20) & (b > g + 20)
    candidate = (dist < threshold) & chroma_candidate

    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()

    def push(y: int, x: int) -> None:
        if 0 <= y < h and 0 <= x < w and candidate[y, x] and not visited[y, x]:
            visited[y, x] = True
            q.append((y, x))

    # 从四边入队
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


def _remove_small_clusters(alpha: np.ndarray, min_size: int = 3000) -> np.ndarray:
    """删除面积小于 min_size 的连通分量（去除水印/噪点）。"""
    binary = (alpha > 0).astype(np.int32)
    labeled, num_features = ndimage.label(binary)
    if num_features == 0:
        return alpha

    # 找到最大簇（角色主体）
    sizes = ndimage.sum(binary, labeled, range(1, num_features + 1))
    max_label = np.argmax(sizes) + 1

    # 保留所有大于 min_size 的簇（可能有手臂/烟杆形成的独立区域）
    result = alpha.copy()
    for i in range(1, num_features + 1):
        if sizes[i - 1] < min_size:
            result[labeled == i] = 0

    return result


def _magenta_only_despill(data: np.ndarray) -> np.ndarray:
    """Magenta-only despill：只修正 R≈B>G 的紫色溢色，不影响正常颜色。

    判定条件：min(R,B) > G + 8 且 |R-B| < 50
    - 暖色皮肤 R>G>B → min(R,B)=B, B>G+8? 通常否 → 不修正
    - 蓝色衣服 B>G>R → min(R,B)=R, R>G+8? 通常否 → 不修正
    - 棕色 R>G>>B → min(R,B)=B, B>G+8? 否 → 不修正
    - 紫色溢色 R≈B>G → min(R,B)>G+8 且 |R-B|<50 → 修正
    """
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    fg = a > 0

    rb_min = np.minimum(r, b)
    rb_diff = np.abs(r.astype(np.int16) - b.astype(np.int16))

    # 紫色溢色判定
    is_magenta = fg & (rb_min > g + 8) & (rb_diff < 50)

    if not np.any(is_magenta):
        return data

    # 溢色程度 0~1
    spill_amt = np.clip((rb_min[is_magenta] - g[is_magenta] - 8) / 40.0, 0, 1)

    # 修正 R/B 通道：往 G 通道靠拢
    data[is_magenta, 0] = r[is_magenta] - (r[is_magenta] - g[is_magenta]) * spill_amt
    data[is_magenta, 2] = b[is_magenta] - (b[is_magenta] - g[is_magenta]) * spill_amt

    return data


def _remove_edge_halo(data: np.ndarray) -> np.ndarray:
    """去除紫底色键后发丝/边缘的绿色/黄色光晕（Gemini 伪影）。

    Gemini 在紫底上生成深色头发时，常在发丝边缘产生绿色/黄色描边。
    这些不是角色正常颜色，需要去除。
    """
    r = data[:, :, 0].astype(np.int16)
    g = data[:, :, 1].astype(np.int16)
    b = data[:, :, 2].astype(np.int16)
    a = data[:, :, 3].astype(np.int16)

    visible = a > 10

    # 先清零全透明像素的 RGB，防止中值滤波时混入紫色背景
    data[data[:, :, 3] == 0, :3] = 0

    # 绿色光晕：G 显著高于 R 和 B（AI 紫底发丝伪影）
    green_halo = visible & (g > r + 15) & (g > b + 15)

    # 黄色光晕：R≈G 显著高于 B，且饱和度较高（避免误伤正常肤色）
    max_rgb = np.maximum(np.maximum(r, g), b)
    min_rgb = np.minimum(np.minimum(r, g), b)
    with np.errstate(divide='ignore', invalid='ignore'):
        saturation = np.where(max_rgb > 0, (max_rgb - min_rgb).astype(np.float32) / max_rgb, 0)
    yellow_halo = visible & (saturation > 0.35) & (np.abs(r - g) < 30) & (np.minimum(r, g) > b + 20)

    halo = green_halo | yellow_halo
    if not np.any(halo):
        return data

    # 1. 低 alpha 边缘直接透明化（半透明伪影，通常是真正的边缘）
    semi = halo & (a < 200)
    data[semi, 3] = 0

    # 2. 高 alpha 光晕：先用 5x5 邻域中值替换（覆盖大片光晕区域）
    opaque = halo & (a >= 200)
    if np.any(opaque):
        med_r = ndimage.median_filter(data[:, :, 0], size=5)
        med_g = ndimage.median_filter(data[:, :, 1], size=5)
        med_b = ndimage.median_filter(data[:, :, 2], size=5)
        data[opaque, 0] = med_r[opaque]
        data[opaque, 1] = med_g[opaque]
        data[opaque, 2] = med_b[opaque]

        # 3. 检查替换后是否仍有光晕（中值窗口内全是光晕的情况）
        r2 = data[:, :, 0].astype(np.int16)
        g2 = data[:, :, 1].astype(np.int16)
        b2 = data[:, :, 2].astype(np.int16)
        still_green = visible & (g2 > r2 + 15) & (g2 > b2 + 15)
        still_yellow = visible & (np.abs(r2 - g2) < 30) & (np.minimum(r2, g2) > b2 + 20)
        still_halo = still_green | still_yellow
        if np.any(still_halo):
            # 先去饱和（拉向灰度），若仍光晕则直接透明化
            gray = ((r2[still_halo] + g2[still_halo] + b2[still_halo]) / 3.0)
            data[still_halo, 0] = gray * 0.6 + r2[still_halo] * 0.4
            data[still_halo, 1] = gray * 0.6 + g2[still_halo] * 0.4
            data[still_halo, 2] = gray * 0.6 + b2[still_halo] * 0.4

            # 二次检查：去饱和后仍然光晕的，直接透明
            r3 = data[:, :, 0].astype(np.int16)
            g3 = data[:, :, 1].astype(np.int16)
            b3 = data[:, :, 2].astype(np.int16)
            stubborn_green = visible & (g3 > r3 + 15) & (g3 > b3 + 15)
            stubborn_yellow = visible & (np.abs(r3 - g3) < 30) & (np.minimum(r3, g3) > b3 + 20)
            stubborn = stubborn_green | stubborn_yellow
            if np.any(stubborn):
                data[stubborn, 3] = 0

    return data


def remove_purple_bg(path: str, out_path: str = None, no_despill: bool = False,
                     portrait: bool = False, canvas_size: tuple = None) -> None:
    """将紫色(#FF00FF)背景去除，转为透明。v2.0 增强版。

    Args:
        path: 输入图片路径
        out_path: 输出路径（默认覆盖原文件）
        no_despill: 跳过 magenta despill（像素素材用）
        portrait: 启用画布标准化模式
        canvas_size: 画布尺寸 (w,h)，默认 848x1264
    """
    if out_path is None:
        out_path = path

    img = Image.open(path).convert("RGBA")
    data = np.array(img, dtype=np.float32)
    rgb = data[:, :, :3].astype(np.uint8)

    # ── Step 1: 角采样背景色 ──
    bg = _border_rgb(data).astype(np.float32)

    # ── Step 2: BFS flood fill 背景连通区 ──
    bg_mask = _flood_fill_background(rgb, bg)

    # 将背景区设为全透明
    data[bg_mask, 3] = 0

    # ── 全局色键：处理角色手臂/烟杆围出的内部孔洞 ──
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    global_purple = (a > 0) & (r > g + 18) & (b > g + 18) & (((r + b) * 0.5) > g + 32)
    data[:, :, 3][global_purple] = 0

    # ── Step 3: 小簇清除 ──
    alpha = data[:, :, 3].copy()
    alpha = _remove_small_clusters(alpha, min_size=3000)
    data[:, :, 3] = alpha

    # ── alpha 1px 侵蚀（切掉最外层色边） ──
    alpha = data[:, :, 3]
    h, w = alpha.shape
    shifted_up = np.zeros_like(alpha)
    shifted_down = np.zeros_like(alpha)
    shifted_left = np.zeros_like(alpha)
    shifted_right = np.zeros_like(alpha)
    shifted_up[1:, :] = alpha[:-1, :]
    shifted_down[:-1, :] = alpha[1:, :]
    shifted_left[:, 1:] = alpha[:, :-1]
    shifted_right[:, :-1] = alpha[:, 1:]
    eroded = np.where(
        (alpha > 100) & (shifted_up > 100) & (shifted_down > 100) &
        (shifted_left > 100) & (shifted_right > 100), alpha, 0
    )
    data[:, :, 3] = eroded

    if not no_despill:
        # ── Step 4: Magenta-only despill ──
        data = _magenta_only_despill(data)

        # ── 半透明边像素去紫 ──
        semi = (data[:, :, 3] > 5) & (data[:, :, 3] < 245)
        if np.any(semi):
            r_s, g_s, b_s = data[semi, 0], data[semi, 1], data[semi, 2]
            bias_s = ((r_s + b_s) / 2.0) - g_s
            has_purple = bias_s > 5
            if np.any(has_purple):
                avg = (r_s[has_purple] + g_s[has_purple] + b_s[has_purple]) / 3.0
                strength = np.clip(bias_s[has_purple] / 40.0, 0.0, 0.8)
                idx = np.where(semi)
                py, px = idx[0][has_purple], idx[1][has_purple]
                data[py, px, 0] = avg + (data[py, px, 0] - avg) * (1.0 - strength)
                data[py, px, 2] = avg + (data[py, px, 2] - avg) * (1.0 - strength)

        # ── Step 4b: 去除绿色/黄色边缘光晕 ──
        data = _remove_edge_halo(data)

    # ── Step 5: 全透明像素 RGB 清零 ──
    data[data[:, :, 3] == 0, :3] = 0

    # ── Step 6: Alpha 高斯模糊 ──
    alpha_channel = np.clip(data[:, :, 3], 0, 255).astype(np.uint8)
    alpha_img = Image.fromarray(alpha_channel, mode='L')
    radius = 0.8 if not no_despill else 0.5
    smoothed = alpha_img.filter(ImageFilter.GaussianBlur(radius=radius))
    data[:, :, 3] = np.array(smoothed, dtype=np.float32)

    result = Image.fromarray(np.clip(data, 0, 255).astype(np.uint8))

    # ── Step 7: 画布标准化（可选）──
    if portrait:
        if canvas_size is None:
            canvas_size = CANVAS_COMPANION
        if tuple(canvas_size) == NPC_KNEE_UP_SPEC.canvas:
            result = fit_subject_to_spec(result, NPC_KNEE_UP_SPEC)
        else:
            target_w, target_h = canvas_size

            alpha_arr = np.array(result)[:, :, 3]
            nz = np.argwhere(alpha_arr > 10)
            if nz.size > 0:
                y0, x0 = nz.min(axis=0)
                y1, x1 = nz.max(axis=0)
                result = result.crop((x0, y0, x1 + 1, y1 + 1))

            src_w, src_h = result.size
            scale = min(target_w / src_w, target_h / src_h)
            new_w = max(1, int(src_w * scale))
            new_h = max(1, int(src_h * scale))
            resized = result.resize((new_w, new_h), Image.Resampling.LANCZOS)
            canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
            paste_x = (target_w - new_w) // 2
            paste_y = target_h - new_h
            canvas.paste(resized, (paste_x, paste_y), resized)
            result = canvas

    result.save(out_path)
    print(f"Saved: {out_path}")


def verify_portrait(path: str) -> bool:
    """验证抠图质量：仅检查边缘色键残留，避免误伤角色本身的红紫服装。"""
    data = np.array(Image.open(path).convert("RGBA"))
    r, g, b, a = data[:, :, 0].astype(int), data[:, :, 1].astype(int), data[:, :, 2].astype(int), data[:, :, 3]
    visible = a > 10

    # 只检查紧邻透明区域的窄边带，避免把角色衣服本身的酒红/紫红纹理误判成溢色。
    alpha_img = Image.fromarray((visible.astype(np.uint8) * 255), mode="L")
    edge_band = np.array(alpha_img.filter(ImageFilter.MaxFilter(size=5)), dtype=np.uint8) > 0
    edge_band &= visible

    magenta_edge = edge_band & (r > 220) & (g < 60) & (b > 220)
    green_edge = edge_band & (g > r + 45) & (g > b + 45)

    # 角落/边框处不应残留任何可见纯色键背景。
    h, w = a.shape
    border = np.zeros_like(visible, dtype=bool)
    border[:3, :] = True
    border[-3:, :] = True
    border[:, :3] = True
    border[:, -3:] = True
    border_residue = border & visible & (
        ((r > 220) & (g < 60) & (b > 220)) |
        ((g > 220) & (r < 60) & (b < 60))
    )

    magenta_spill = int(magenta_edge.sum())
    green_spill = int(green_edge.sum())
    bg_residue = int(border_residue.sum())

    if magenta_spill > 24 or green_spill > 24 or bg_residue > 0:
        print(
            f"FAIL [{path}]: magenta_spill={magenta_spill}, "
            f"green_spill={green_spill}, bg_residue={bg_residue}"
        )
        return False
    print(
        f"PASS [{path}]: magenta_spill={magenta_spill}, "
        f"green_spill={green_spill}, bg_residue={bg_residue}"
    )
    return True


def process_directory(dir_path: str, **kwargs) -> None:
    """处理目录下所有png文件。"""
    for f in sorted(glob.glob(os.path.join(dir_path, "*.png"))):
        if f.endswith(".import"):
            continue
        remove_purple_bg(f, **kwargs)


if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description="紫底抠图工具 v2.0")
    ap.add_argument("input", help="输入图片或目录")
    ap.add_argument("output", nargs="?", help="输出路径")
    ap.add_argument("--no-despill", action="store_true", help="跳过 magenta despill（像素素材用）")
    ap.add_argument("--portrait", action="store_true", help="启用画布标准化模式")
    ap.add_argument("--canvas", help="画布尺寸 WxH（如 848x1264），默认 848x1264")
    ap.add_argument("--verify", action="store_true", help="只验证，不处理")
    args = ap.parse_args()

    if args.verify:
        if os.path.isdir(args.input):
            for f in sorted(glob.glob(os.path.join(args.input, "*.png"))):
                if not f.endswith(".import"):
                    verify_portrait(f)
        else:
            verify_portrait(args.input)
        sys.exit(0)

    canvas_size = None
    if args.canvas:
        parts = args.canvas.lower().split("x")
        canvas_size = (int(parts[0]), int(parts[1]))

    kwargs = dict(no_despill=args.no_despill, portrait=args.portrait, canvas_size=canvas_size)

    if os.path.isdir(args.input):
        process_directory(args.input, **kwargs)
    else:
        remove_purple_bg(args.input, args.output, **kwargs)
