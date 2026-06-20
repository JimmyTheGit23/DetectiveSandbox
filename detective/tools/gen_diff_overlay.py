#!/usr/bin/env python3
"""
差分 overlay 生成器 v2 —— 解决 Gemini 整图重绘导致的色偏问题。

v1 问题：
  Gemini 生成闭眼变体时会整图重绘，导致：
  - 非眼部区域有微小色偏（全身 ~30000 像素差异）
  - 衣服/配饰区域出现伪差异（如左侧"红圈"）
  - 低阈值 diff overlay 会把这些色偏全部叠加到渲染层

v2 方案：
  1. ROI 限制空间范围
  2. 高阈值过滤 Gemini 噪声
  3. **色差修正**：对每个 overlay 像素，按 diff 大小混合颜色
     - diff >> threshold（真正闭眼变化）→ 用 variant 颜色
     - diff ≈ threshold（Gemini 色偏噪声）→ 向 base 颜色回拉
  4. 高斯羽化 alpha → 无硬边

用法：
  python3 tools/gen_diff_overlay.py \
    --base assets/cn/portraits/prologue_shen_qingyue.png \
    --variant assets/cn/portraits/anim_layers/shen_qingyue/blink_clean.png \
    --output assets/cn/portraits/anim_layers/shen_qingyue/eyes_layer.png \
    --threshold 35 --feather 3.5 --color-fix-strength 0.7
"""

from __future__ import annotations
import argparse
import sys
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageFilter


def generate_diff_overlay(
    base_path: Path,
    variant_path: Path,
    output_path: Path,
    threshold: float = 35.0,
    feather_radius: float = 3.5,
    min_alpha: int = 8,
    roi: tuple[int, int, int, int] | None = None,
    color_fix_strength: float = 0.7,
) -> dict[str, Any]:
    """基于两张图的像素差异生成 overlay，带色差修正。

    Args:
        base_path: 原始基准图（如睁眼完整立绘）
        variant_path: 变体图（如闭眼完整立绘，同尺寸）
        output_path: 输出 overlay PNG 路径
        threshold: RGB 差异阈值（欧氏距离），低于此值视为"未变化"
        feather_radius: alpha 羽化半径（px），越大过渡越柔和
        min_alpha: alpha 最小保留值，低于此值裁为零
        roi: 可选的 (x, y, w, h) 兴趣区域
        color_fix_strength: 色差修正强度 (0~1)
            0 = 完全用 variant 颜色（不修正，等同 v1）
            1 = 完全用 base 颜色（修正到和原图一样，但闭眼效果会被削弱）
            0.7 = 推荐值，对低 diff 像素强修正，高 diff 像素弱修正
    """
    base = Image.open(base_path).convert("RGBA")
    variant = Image.open(variant_path).convert("RGBA")

    if base.size != variant.size:
        print(f"  ⚠️ 尺寸不匹配: {base.size} vs {variant.size}, 尝试缩放...")
        variant = variant.resize(base.size, Image.Resampling.LANCZOS)

    W, H = base.size
    arr_b = np.array(base, dtype=np.float32)
    arr_v = np.array(variant, dtype=np.float32)

    # ── Step 1: 计算逐像素 RGB 欧氏距离 ──
    rgb_diff = np.linalg.norm(arr_b[:, :, :3] - arr_v[:, :, :3], axis=2)

    # ── Step 2: 生成变化区域 mask ──
    var_alpha = arr_v[:, :, 3]
    changed_mask = (rgb_diff > threshold) & (var_alpha > 30)

    # ── Step 2b: ROI 限制 ──
    if roi is not None:
        rx, ry, rw, rh = roi
        roi_mask = np.zeros((H, W), dtype=bool)
        roi_mask[ry:ry + rh, rx:rx + rw] = True
        changed_mask = changed_mask & roi_mask
        print(f"  ROI: ({rx},{ry}) {rw}×{rh}")

    # ── Step 3: alpha mask + 高斯羽化 ──
    mask_uint8 = (changed_mask.astype(np.uint8)) * 255
    mask_img = Image.fromarray(mask_uint8, mode="L")
    blurred = mask_img.filter(ImageFilter.GaussianBlur(radius=feather_radius))
    alpha_arr = np.array(blurred, dtype=np.float32)
    alpha_arr[alpha_arr < min_alpha] = 0

    # ── Step 4: 色差修正 ──
    # 核心思路：diff 小 = Gemini 噪声 → 多用 base 颜色
    #          diff 大 = 真正闭眼 → 保留 variant 颜色
    #
    # blend_factor[y,x] = 1 表示完全用 variant, 0 表示完全用 base
    # 使用 sigmoid 映射：diff 在 threshold 附近快速过渡
    if color_fix_strength > 0:
        # 对有 alpha 的像素计算 blend factor
        active = alpha_arr > min_alpha
        if active.any():
            # 归一化 diff: diff / threshold → 0~1 附近
            # diff 越大，blend_factor 越接近 1（用 variant）
            # diff 刚过 threshold，blend_factor ~ 0.5
            norm_diff = np.zeros_like(rgb_diff)
            norm_diff[active] = rgb_diff[active] / max(threshold * 1.5, 1.0)

            # sigmoid 平滑过渡
            k = 6.0  # 陡度
            blend_factor = 1.0 / (1.0 + np.exp(-k * (norm_diff - 0.6)))

            # 用 color_fix_strength 缩放 blend 范围
            # strength=0.7 时，最小 blend_factor 从 0 变到 0.3
            min_blend = color_fix_strength * 0.4
            blend_factor = min_blend + (1.0 - min_blend) * blend_factor

            # 对每个 RGB 通道做混合
            output = arr_b.copy()  # 从 base 开始
            for c in range(3):
                output[:, :, c] = (
                    arr_b[:, :, c] * (1.0 - blend_factor)
                    + arr_v[:, :, c] * blend_factor
                )
            output[:, :, 3] = alpha_arr

            fixed_px = int(np.sum(active & (blend_factor < 0.9)))
            print(f"  色差修正: {fixed_px}px 被回拉到 base 颜色 (fix={color_fix_strength})")
        else:
            output = arr_v.copy()
            output[:, :, 3] = alpha_arr
    else:
        output = arr_v.copy()
        output[:, :, 3] = alpha_arr

    # ── 统计 ──
    total_px = W * H
    nonzero = int(np.sum(alpha_arr > min_alpha))
    pct = nonzero / total_px * 100
    if nonzero > 0:
        ys, xs = np.where(alpha_arr > min_alpha)
        bbox = f"x={xs.min()}~{xs.max()}, y={ys.min()}~{ys.max()}"
        bbox_w = int(xs.max() - xs.min())
        bbox_h = int(ys.max() - ys.min())
    else:
        bbox = "N/A"
        bbox_w = bbox_h = 0

    result = Image.fromarray(np.clip(output, 0, 255).astype(np.uint8))
    result.save(output_path, optimize=True)
    file_kb = output_path.stat().st_size / 1024

    return {
        "size": (W, H),
        "nonzero_pixels": nonzero,
        "pct_nonzero": round(pct, 2),
        "bbox": bbox,
        "bbox_size": (bbox_w, bbox_h),
        "file_kb": round(file_kb, 1),
    }


def main() -> None:
    ap = argparse.ArgumentParser(description="生成分层立绘差分 overlay (v2 色差修正)")
    ap.add_argument("--base", required=True, help="原始基准图路径")
    ap.add_argument("--variant", required=True, help="变体图路径（闭眼/张嘴等）")
    ap.add_argument("--output", required=True, help="输出 overlay PNG 路径")
    ap.add_argument("--threshold", type=float, default=35.0,
                    help="RGB 差异阈值（默认35，越大越严格）")
    ap.add_argument("--feather", type=float, default=3.5,
                    help="alpha 羽化半径 px（默认3.5）")
    ap.add_argument("--min-alpha", type=int, default=8,
                    help="alpha 最小保留值（默认8，低于此归零）")
    ap.add_argument("--roi", type=str, default=None,
                    help="ROI 区域 'x,y,w,h'")
    ap.add_argument("--color-fix", type=float, default=0.7,
                    help="色差修正强度 0~1（默认0.7，0=不修正）")
    args = ap.parse_args()

    base_path = Path(args.base)
    variant_path = Path(args.variant)
    output_path = Path(args.output)

    for p in [base_path, variant_path]:
        if not p.exists():
            print(f"✗ 文件不存在: {p}")
            sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    roi: tuple[int, int, int, int] | None = None
    if args.roi:
        parts = [int(x.strip()) for x in args.roi.split(",")]
        if len(parts) == 4:
            roi = (parts[0], parts[1], parts[2], parts[3])
        else:
            print(f"✗ ROI 格式错误: {args.roi}, 需要 'x,y,w,h'")
            sys.exit(1)

    print(f"基准: {base_path.name}")
    print(f"变体: {variant_path.name}")
    print(f"参数: threshold={args.threshold}, feather={args.feather}, roi={roi}, color_fix={args.color_fix}")

    stats = generate_diff_overlay(
        base_path, variant_path, output_path,
        threshold=args.threshold,
        feather_radius=args.feather,
        min_alpha=args.min_alpha,
        roi=roi,
        color_fix_strength=args.color_fix,
    )

    print(f"  ✓ 输出: {output_path}")
    print(f"  尺寸: {stats['size'][0]}×{stats['size'][1]}")
    print(f"  有效像素: {stats['nonzero_pixels']}px ({stats['pct_nonzero']}%)")
    print(f"  包围盒: {stats['bbox']} ({stats['bbox_size'][0]}×{stats['bbox_size'][1]})")
    print(f"  文件大小: {stats['file_kb']}KB")


if __name__ == "__main__":
    main()
