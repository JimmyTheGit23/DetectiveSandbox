#!/usr/bin/env python3
"""差分 overlay 生成器（含眉毛硬切）—— 眨眼/说话 overlay 最终方案。

对比原图(睁眼)和变体(闭眼/张嘴抠图)，只提取 ROI 内真正变化的像素，
其余全透明。硬切保证眉毛区零像素 → 眨眼时眉毛绝不动。

用法:
  python3 gen_overlay.py \
    --base assets/cn/portraits/prologue_shen_qingyue.png \
    --variant assets/cn/portraits/anim_layers/shen_qingyue/blink_closed_clean.png \
    --output assets/cn/portraits/anim_layers/shen_qingyue/eyes_closed.png \
    --roi "320,280,300,45" --cut-top 280 --threshold 18 --feather 3.0
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter


def gen_overlay(base_path, variant_path, output_path, roi, cut_top=0,
                threshold=18.0, feather=3.0, min_alpha=15):
    base = Image.open(base_path).convert("RGBA")
    variant = Image.open(variant_path).convert("RGBA")
    if variant.size != base.size:
        variant = variant.resize(base.size, Image.Resampling.LANCZOS)
    W, H = base.size
    arr_b = np.array(base, dtype=np.float32)
    arr_v = np.array(variant, dtype=np.float32)

    # 1) 真实变化检测: ROI 内 diff>阈值 且变体该处有内容
    rgb_diff = np.linalg.norm(arr_b[:, :, :3] - arr_v[:, :, :3], axis=2)
    changed = (rgb_diff > threshold) & (arr_v[:, :, 3] > 30)
    rx, ry, rw, rh = roi
    rm = np.zeros((H, W), dtype=bool)
    rm[ry:ry + rh, rx:rx + rw] = True
    changed = changed & rm

    # 2) 羽化 alpha
    blurred = Image.fromarray((changed.astype(np.uint8)) * 255).filter(
        ImageFilter.GaussianBlur(radius=feather))
    alpha = np.array(blurred, dtype=np.float32)
    alpha[alpha < min_alpha] = 0

    # 3) ★ 硬切: y<cut_top 强制透明, 物理保证眉毛区零像素
    if cut_top > 0:
        alpha[:cut_top, :] = 0

    out = arr_v.copy()
    out[:, :, 3] = alpha
    p = Path(output_path)
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(p, optimize=True)

    act = alpha > min_alpha
    if act.any():
        ys, xs = np.where(act)
        print(f"  ✓ {p.name}: {int(act.sum())}px bbox y=[{ys.min()},{ys.max()}] "
              f"x=[{xs.min()},{xs.max()}] (上边界{ys.min()}应>={cut_top}) "
              f"{p.stat().st_size/1024:.0f}KB")
    else:
        print(f"  ⚠️ {p.name}: 空! 检查 ROI/阈值")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True)
    ap.add_argument("--variant", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--roi", required=True, help="'x,y,w,h'")
    ap.add_argument("--cut-top", type=int, default=0, help="硬切线 y, <此值强制透明(避免眉毛动)")
    ap.add_argument("--threshold", type=float, default=18.0)
    ap.add_argument("--feather", type=float, default=3.0)
    ap.add_argument("--min-alpha", type=int, default=15)
    a = ap.parse_args()
    roi = tuple(int(x) for x in a.roi.split(","))
    if len(roi) != 4:
        print("ROI 格式错误，需 'x,y,w,h'")
        sys.exit(1)
    gen_overlay(Path(a.base), Path(a.variant), Path(a.output), roi,
                a.cut_top, a.threshold, a.feather, a.min_alpha)


if __name__ == "__main__":
    main()
