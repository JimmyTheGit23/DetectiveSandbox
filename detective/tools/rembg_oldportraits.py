#!/usr/bin/env python3
"""把老立绘（带米色背景）批量去背成透明 PNG，统一到与新批次一致的规格。

工作流：
  1. rembg（U2Net）智能去背 → RGBA（人物保留，背景透明）
  2. autocrop 到非透明像素的最小外接矩形
  3. 保持比例缩放后嵌入 603×900 画布，居底对齐
  4. 原文件先备份到 assets/cn/portraits/_backup_before_rembg/

用法：
  python3 tools/rembg_oldportraits.py            # 全部 8 张
  python3 tools/rembg_oldportraits.py lu_zhao    # 单张
"""
from __future__ import annotations
import sys
import shutil
from pathlib import Path
from PIL import Image
import numpy as np
from rembg import remove, new_session

ROOT = Path(__file__).resolve().parent.parent
PORT_DIR = ROOT / "assets/cn/portraits"
BACKUP_DIR = PORT_DIR / "_backup_before_rembg"
BACKUP_DIR.mkdir(parents=True, exist_ok=True)

PORTRAIT_W = 603
PORTRAIT_H = 900

# 8 张老立绘
OLD_KEYS = [
    "lu_zhao", "liu_wenqing", "su_wan", "zhao_dayou",
    "gu_qingxuan", "xiao_cui", "daoming", "ma_san",
]


def autocrop_rgba(img: Image.Image, padding: int = 4) -> Image.Image:
    arr = np.array(img.convert("RGBA"))
    alpha = arr[:, :, 3]
    nz = np.argwhere(alpha > 10)
    if nz.size == 0:
        return img
    y0, x0 = nz.min(axis=0)
    y1, x1 = nz.max(axis=0)
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(arr.shape[1] - 1, x1 + padding)
    y1 = min(arr.shape[0] - 1, y1 + padding)
    return img.crop((x0, y0, x1 + 1, y1 + 1))


def fit_into_603x900(img: Image.Image) -> Image.Image:
    sw, sh = img.size
    scale = min(PORTRAIT_W / sw, PORTRAIT_H / sh)
    nw = max(1, int(sw * scale))
    nh = max(1, int(sh * scale))
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (PORTRAIT_W, PORTRAIT_H), (0, 0, 0, 0))
    paste_x = (PORTRAIT_W - nw) // 2
    paste_y = PORTRAIT_H - nh  # 居底对齐
    canvas.paste(img, (paste_x, paste_y), img)
    return canvas


def process_one(key: str, session) -> bool:
    src = PORT_DIR / f"{key}.png"
    if not src.exists():
        print(f"  [skip] missing: {src}")
        return False
    # 备份原图（只备份一次）
    backup = BACKUP_DIR / f"{key}.png"
    if not backup.exists():
        shutil.copy2(src, backup)
        print(f"  [backup] {backup.relative_to(ROOT)}")

    src_img = Image.open(backup).convert("RGBA")
    # rembg 智能去背
    out = remove(src_img, session=session)
    # autocrop + 标准化
    out = autocrop_rgba(out, padding=4)
    out = fit_into_603x900(out)
    out.save(src, "PNG")
    arr = np.array(out)
    vis = (arr[:, :, 3] > 0).mean() * 100
    print(f"  [OK]  {key:<14}  visible={vis:5.1f}%  ({PORTRAIT_W}x{PORTRAIT_H})")
    return True


def main() -> None:
    targets = sys.argv[1:] or OLD_KEYS
    print(f"准备处理 {len(targets)} 张老立绘 …")
    session = new_session("u2net")  # 通用人物去背
    for k in targets:
        if k not in OLD_KEYS:
            print(f"  [warn] {k} 不在已知老立绘清单内，仍尝试处理")
        process_one(k, session)
    print("\nDone. 备份在 assets/cn/portraits/_backup_before_rembg/")
    print("如需回滚：cp _backup_before_rembg/<key>.png <key>.png")


if __name__ == "__main__":
    main()
