"""AI 生成素材后处理工具：
- 紫色 #FF00FF 色键去除（含半透明边缘）
- 自动裁剪到内容包围盒
- 保持长宽比缩放到目标像素尺寸（NEAREST，保留像素感）
- 调色板量化（可选）

Usage:
  python3 tools/process_ai_assets.py
"""
from __future__ import annotations
from PIL import Image
import numpy as np
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# 紫色色键阈值
def remove_magenta(img: Image.Image, tol: int = 70) -> Image.Image:
    img = img.convert('RGBA')
    arr = np.array(img)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    # 主紫色
    mag = (r > 200) & (g < tol) & (b > 200)
    # 半透明紫色边缘：粉紫斑点
    mag2 = (r > 180) & (g < 120) & (b > 180) & (r.astype(int) + b.astype(int) > g.astype(int) * 3)
    arr[mag | mag2] = [0, 0, 0, 0]
    return Image.fromarray(arr)


def autocrop(img: Image.Image, padding: int = 0) -> Image.Image:
    """裁剪到非透明像素的最小外接矩形"""
    arr = np.array(img.convert('RGBA'))
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


def fit_into(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """保持比例缩放到 target_w x target_h，不足部分透明居中。
    使用 NEAREST 保留像素感。"""
    src_w, src_h = img.size
    scale = min(target_w / src_w, target_h / src_h)
    new_w = max(1, int(src_w * scale))
    new_h = max(1, int(src_h * scale))
    img = img.resize((new_w, new_h), Image.Resampling.NEAREST)
    canvas = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    canvas.paste(img, ((target_w - new_w) // 2, target_h - new_h), img)  # 底部对齐（适合大部分立体物件）
    return canvas


def process_object(src_path: Path, out_path: Path, target_size: tuple, bottom_align: bool = True):
    img = Image.open(src_path)
    img = remove_magenta(img)
    img = autocrop(img, padding=2)
    target_w, target_h = target_size
    src_w, src_h = img.size
    scale = min(target_w / src_w, target_h / src_h)
    new_w = max(1, int(src_w * scale))
    new_h = max(1, int(src_h * scale))
    img = img.resize((new_w, new_h), Image.Resampling.NEAREST)
    canvas = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    if bottom_align:
        canvas.paste(img, ((target_w - new_w) // 2, target_h - new_h), img)
    else:
        canvas.paste(img, ((target_w - new_w) // 2, (target_h - new_h) // 2), img)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path)
    print(f'  {out_path.relative_to(ROOT)}: {target_w}x{target_h}')


def process_seamless_tile(src_path: Path, out_path: Path, target_size: int = 64):
    """将 1024x1024 seamless tile 缩到 target_size x target_size，可作为 tile 重复铺。"""
    img = Image.open(src_path).convert('RGB')
    img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)
    print(f'  {out_path.relative_to(ROOT)}: {target_size}x{target_size}')


# ========================
# 配置：源 -> 目标 + 尺寸
# ========================
RAW_OBJ = ROOT / 'assets/ai_raw/objects'
RAW_TILE = ROOT / 'assets/ai_raw/tilesets'
OUT_OBJ = ROOT / 'assets/ai_processed/objects'
OUT_TILE = ROOT / 'assets/ai_processed/tilesets'


def find_one(prefix: str, base: Path = RAW_OBJ):
    files = sorted(base.glob(f'{prefix}*.png'))
    return files[-1] if files else None


def main():
    print('=== 处理 AI 物件（紫底色键） ===')
    # 物件 -> 目标尺寸（按场景比例：32px = 1 tile）
    objects = [
        # (前缀, 输出名, 目标 (w,h))
        ('A_single_Victorian_cast_iron_g', 'gas_lamp.png',     (48, 96)),
        ('A_single_ornate_Victorian_ston', 'fountain.png',     (128, 96)),
        ('A_single_Victorian_cast_iron_p', 'park_bench.png',   (96, 48)),
        ('A_single_wooden_Victorian_publ', 'notice_board.png', (96, 96)),
        ('A_single_round_cast_iron_sewer', 'manhole.png',      (32, 32)),
        ('A_single_yellow_and_black_poli', 'police_tape.png',  (96, 32)),
        ('A_single_old_wooden_barrel_wit', 'barrel.png',       (40, 48)),
        ('A_small_evidence_number_marker', 'evidence_marker.png', (24, 32)),
        ('A_single_small_Victorian_iron_', 'wall_sconce.png',  (32, 48)),
        ('A_single_tall_Victorian_shop_b', 'shop_building.png', (192, 224)),
    ]
    for prefix, out_name, size in objects:
        src = find_one(prefix)
        if not src:
            print(f'  ! 缺少: {prefix}')
            continue
        process_object(src, OUT_OBJ / out_name, size)

    print()
    print('=== 处理 AI 地板/墙体 tile（seamless） ===')
    tiles = [
        ('A_SEAMLESS_TILEABLE_pixel_art__2026-05-16T04-36-06', 'cobblestone_seamless.png', 256),
        ('A_SEAMLESS_TILEABLE_pixel_art__2026-05-16T04-36-10', 'brick_wall_seamless.png',  256),
    ]
    for prefix, out_name, size in tiles:
        src = find_one(prefix, RAW_TILE)
        if not src:
            print(f'  ! 缺少: {prefix}')
            continue
        process_seamless_tile(src, OUT_TILE / out_name, size)

    print()
    print('Done!')


if __name__ == '__main__':
    main()
