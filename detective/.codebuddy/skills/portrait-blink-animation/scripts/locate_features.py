#!/usr/bin/env python3
"""角色面部特征定位器 —— 自动找眉毛带/眼睛带的 y 分界。

每个角色立绘的眉毛、眼睛位置不同，眨眼 ROI 必须按角色重新定位，
否则 ROI 圈到眉毛会导致眨眼时眉毛变形（用户明确禁止）。

用法: python3 locate_features.py --char shen_qingyue
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
PORTRAITS = ROOT / "assets" / "cn" / "portraits"


def locate(char, x0, x1, y0, y1):
    base_path = PORTRAITS / f"prologue_{char}.png"
    if not base_path.exists():
        print(f"找不到立绘: {base_path}")
        sys.exit(1)
    arr = np.array(Image.open(base_path).convert("RGBA"))
    r, g, b = arr[:, :, 0].astype(int), arr[:, :, 1].astype(int), arr[:, :, 2].astype(int)
    dark = (r < 110) & (g < 90) & (b < 90)
    active = [(y, int(dark[y, x0:x1].sum())) for y in range(y0, y1) if dark[y, x0:x1].sum() > 3]
    if not active:
        print("未检测到深色特征，请调整 --x0/--x1/--y0/--y1")
        sys.exit(1)
    ys = [y for y, c in active]
    gaps = [(ys[i-1], ys[i], ys[i]-ys[i-1]) for i in range(1, len(ys)) if ys[i]-ys[i-1] > 3]
    print(f"\n=== {char} 面部特征定位 ===")
    print(f"深色像素行: y=[{min(ys)},{max(ys)}]")
    if gaps:
        bb, et, gp = max(gaps, key=lambda x: x[2])
        print(f"眉毛带 y=[{min(ys)},{bb}]  眉眼间隔 y=[{bb},{et}](gap={gp})  眼睛带 y=[{et},{max(ys)}]")
        roi_y = et - 1
        eye_top = et
    else:
        print("未检测到明显眉眼间隔，请人工目测")
        eye_top = roi_y = (min(ys) + max(ys)) // 2
    band = dark[eye_top:max(ys)+1, x0:x1]
    if band.any():
        _, ex = np.where(band)
        ex = ex + x0
        roi_x = max(0, ex.min() - 10)
        roi_w = (ex.max() + 10) - roi_x
        xm = (ex.min()+ex.max())//2
        print(f"左眼中心 x≈{int(ex[ex<xm].mean()) if (ex<xm).any() else xm}, 右眼中心 x≈{int(ex[ex>=xm].mean()) if (ex>=xm).any() else xm}")
    else:
        roi_x, roi_w = x0, x1 - x0
    roi_h = max(ys) - roi_y + 10
    print(f"\n★ EYE_ROI = ({roi_x}, {roi_y}, {roi_w}, {roi_h})   HARD_CUT_TOP = {roi_y}")
    print(f'  gen_overlay.py: --roi "{roi_x},{roi_y},{roi_w},{roi_h}" --cut-top {roi_y}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--char", required=True)
    ap.add_argument("--x0", type=int, default=360)
    ap.add_argument("--x1", type=int, default=600)
    ap.add_argument("--y0", type=int, default=240)
    ap.add_argument("--y1", type=int, default=370)
    a = ap.parse_args()
    locate(a.char, a.x0, a.x1, a.y0, a.y1)


if __name__ == "__main__":
    main()
