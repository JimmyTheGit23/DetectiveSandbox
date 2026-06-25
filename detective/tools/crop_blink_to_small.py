#!/usr/bin/env python3
"""把全帧 848x1264 的 eyes overlay 裁成 ROI 大小的小贴图,
并按 hard_cut_bottom 行硬切掉超出眼区的残留。

输入: assets/cn/portraits/anim_layers/<char>/eyes_{half,closed,open}.png
输出: 同目录下 small/eyes_{half,closed}.png  (ROI 大小)
配置: 直接写在 CONFIG 字典里
"""
from __future__ import annotations
import sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]  # detective/

CONFIG = {
    "lingyao": {
        "src_dir": "assets/cn/portraits/anim_layers/lingyao",
        # 真实眼睛带: src_y=[325..367] (y<325 是右眉, y>367 是脸颊溢出)
        "roi": (300, 325, 215, 43),
        # 上硬切=325(避开眉毛), 下硬切=367(避开脸颊)
        "hard_cut_top": 325,
        "hard_cut_bottom": 367,
        "frames": ["eyes_half.png", "eyes_closed.png"],
    },
    "shen_qingyue": {
        "src_dir": "assets/cn/portraits/anim_layers/shen_qingyue",
        # 实测 overlay bbox: x=[318..617] y=[280..329], 但 y=312..329 是
        # Gemini 改脸颊的溢出残留(18 行), 实际眼睛/下睫毛在 y=280..311
        "roi": (315, 278, 305, 34),
        # 硬切 y > 311 (脸颊皮肤变化区)
        "hard_cut_bottom": 311,
        "frames": ["eyes_half.png", "eyes_closed.png"],
    },
}


def process(char: str) -> None:
    cfg = CONFIG[char]
    src_dir = ROOT / cfg["src_dir"]
    out_dir = src_dir / "small"
    out_dir.mkdir(exist_ok=True)
    rx, ry, rw, rh = cfg["roi"]
    cut_bottom = cfg["hard_cut_bottom"]
    cut_top = cfg.get("hard_cut_top", 0)

    for fname in cfg["frames"]:
        src = src_dir / fname
        if not src.exists():
            print(f"  ! 跳过(不存在): {src}")
            continue
        img = Image.open(src).convert("RGBA")
        W, H = img.size
        arr = np.array(img, dtype=np.uint8)
        # 1) 全图先做硬切: y > hard_cut_bottom 或 y < hard_cut_top 的像素置为透明
        arr[cut_bottom + 1:, :, 3] = 0
        if cut_top > 0:
            arr[:cut_top, :, 3] = 0
        # 2) 裁出 ROI
        cropped = arr[ry:ry + rh, rx:rx + rw, :]
        out_path = out_dir / fname
        Image.fromarray(cropped).save(out_path, optimize=True)
        a = cropped[:, :, 3]
        nz = int((a > 12).sum())
        if nz > 0:
            ys, xs = np.where(a > 12)
            print(f"  ✓ {fname}: 输出 {rw}x{rh}, 有效像素 {nz}, "
                  f"局部 bbox y=[{ys.min()},{ys.max()}] x=[{xs.min()},{xs.max()}] "
                  f"({out_path.stat().st_size/1024:.1f}KB)")
        else:
            print(f"  ! {fname}: 输出为空!")
    print(f"\n输出目录: {out_dir}")


def main():
    char = sys.argv[1] if len(sys.argv) > 1 else "lingyao"
    if char not in CONFIG:
        print(f"未配置角色 {char}, 可选: {list(CONFIG.keys())}")
        sys.exit(1)
    print(f"=== 处理 {char} ===")
    process(char)


if __name__ == "__main__":
    main()
