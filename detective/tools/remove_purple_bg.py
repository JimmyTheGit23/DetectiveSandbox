"""
紫色底抠图工具：将AI生成的紫色(#FF00FF)背景图片转为透明背景。
用法：python remove_purple_bg.py <输入图片或目录> [输出路径]
"""
from PIL import Image, ImageFilter
import numpy as np
import sys
import os
import glob

PURPLE_R, PURPLE_G, PURPLE_B = 255, 0, 255  # #FF00FF

def purple_bias_score(r, g, b):
    """返回紫偏分数：(R+B)/2 - G，越大越偏紫"""
    return ((r + b) / 2.0) - g


def remove_purple_bg(path: str, out_path: str = None) -> None:
    """将紫色(#FF00FF)背景去除，转为透明。增强版：紫偏检测 + alpha收缩。"""
    if out_path is None:
        out_path = path

    img = Image.open(path).convert("RGBA")
    data = np.array(img, dtype=np.float32)
    r, g, b = data[:, :, 0], data[:, :, 1], data[:, :, 2]

    # ── 策略1：纯亮紫背景 → 完全透明 ──
    dist = np.abs(r - PURPLE_R) + g + np.abs(b - PURPLE_B)
    is_bright_purple = dist < 200
    data[is_bright_purple, 3] = 0

    # ── 策略2：放宽的紫偏检测 ──
    bias = purple_bias_score(r, g, b)
    # 紫偏>8 即视为有紫色调，直接透明
    is_purple_tint = (bias > 8) & (np.maximum(r, b) > 30)
    data[is_purple_tint, 3] = 0

    # ── 策略3：alpha通道收缩1像素（关键）──
    # 把非透明区域的边缘向内缩1px，直接切掉最外层像素（通常是紫边）
    alpha = data[:, :, 3]
    h, w = alpha.shape
    # 创建收缩后的alpha：只有上下左右都不透明的像素才保留
    shifted_up = np.zeros_like(alpha)
    shifted_down = np.zeros_like(alpha)
    shifted_left = np.zeros_like(alpha)
    shifted_right = np.zeros_like(alpha)
    shifted_up[1:, :] = alpha[:-1, :]
    shifted_down[:-1, :] = alpha[1:, :]
    shifted_left[:, 1:] = alpha[:, :-1]
    shifted_right[:, :-1] = alpha[:, 1:]
    # 收缩：只有自身和四邻域都>100才算不透明
    eroded = np.where((alpha > 100) & (shifted_up > 100) & (shifted_down > 100) &
                      (shifted_left > 100) & (shifted_right > 100), alpha, 0)
    data[:, :, 3] = eroded

    # ── 策略4：颜色去紫（对半透明像素）──
    semi = data[:, :, 3] > 5
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

    # ── 策略5：alpha平滑 ──
    alpha_img = Image.fromarray(np.clip(data[:, :, 3], 0, 255).astype(np.uint8), mode='L')
    smoothed = alpha_img.filter(ImageFilter.GaussianBlur(radius=0.5))
    data[:, :, 3] = np.array(smoothed, dtype=np.float32)

    result = Image.fromarray(np.clip(data, 0, 255).astype(np.uint8))
    result.save(out_path)
    print(f"Saved: {out_path}")


def process_directory(dir_path: str) -> None:
    """处理目录下所有png文件。"""
    for f in glob.glob(os.path.join(dir_path, "*.png")):
        # 跳过 .import 文件
        if f.endswith(".import"):
            continue
        remove_purple_bg(f)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python remove_purple_bg.py <image.png|directory> [output.png]")
        sys.exit(1)
    inp = sys.argv[1]
    if os.path.isdir(inp):
        process_directory(inp)
    else:
        outp = sys.argv[2] if len(sys.argv) > 2 else inp
        remove_purple_bg(inp, outp)
