#!/usr/bin/env python3
"""
AI 生成素材处理工具
- 色键去除（#FF00FF 紫色 / #00FF00 绿色背景）
- 像素化缩放
- 输出透明 PNG
"""

import sys
import os
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Installing Pillow and numpy...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "numpy"])
    from PIL import Image
    import numpy as np


def remove_chroma_key(img: Image.Image, tolerance: int = 60) -> Image.Image:
    """去除紫色(#FF00FF)和绿色(#00FF00)背景"""
    img = img.convert("RGBA")
    data = np.array(img)
    
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    
    # 紫色 #FF00FF 区域
    magenta_mask = (r > 200) & (g < tolerance) & (b > 200)
    
    # 绿色 #00FF00 区域
    green_mask = (r < tolerance) & (g > 200) & (b < tolerance)
    
    # 合并掩码
    bg_mask = magenta_mask | green_mask
    
    # 设为透明
    data[bg_mask] = [0, 0, 0, 0]
    
    return Image.fromarray(data)


def pixelate_and_resize(img: Image.Image, target_size: tuple) -> Image.Image:
    """像素化缩放到目标尺寸"""
    # 先缩小到目标尺寸（用 NEAREST 保持像素感）
    img = img.resize(target_size, Image.Resampling.NEAREST)
    return img


def process_character(input_path: str, output_path: str, size: int = 16):
    """处理角色 Sprite"""
    img = Image.open(input_path)
    img = remove_chroma_key(img)
    img = pixelate_and_resize(img, (size, size))
    img.save(output_path)
    print(f"  ✓ Character: {output_path} ({size}x{size})")


def process_scene(input_path: str, output_path: str, width: int = 384, height: int = 216):
    """处理场景背景（匹配游戏分辨率）"""
    img = Image.open(input_path)
    img = remove_chroma_key(img)
    img = pixelate_and_resize(img, (width, height))
    img.save(output_path)
    print(f"  ✓ Scene: {output_path} ({width}x{height})")


def process_items(input_path: str, output_dir: str, size: int = 16):
    """处理物品图标（尝试切割 sprite sheet）"""
    img = Image.open(input_path)
    img = remove_chroma_key(img)
    # 整张图缩放保存
    img = pixelate_and_resize(img, (size * 5, size))  # 5 个物品横排
    img.save(os.path.join(output_dir, "items_sheet.png"))
    print(f"  ✓ Items sheet: {output_dir}/items_sheet.png")
    
    # 同时保存整图缩放版（后续在 Godot 中可以用 AtlasTexture 切割）
    img_full = Image.open(input_path)
    img_full = remove_chroma_key(img_full)
    img_full = pixelate_and_resize(img_full, (size * 6, size * 6))
    img_full.save(os.path.join(output_dir, "items_full.png"))
    print(f"  ✓ Items full: {output_dir}/items_full.png")


def main():
    base = Path(__file__).parent.parent
    chars_dir = base / "assets" / "characters"
    locs_dir = base / "assets" / "locations"
    items_dir = base / "assets" / "items"
    
    processed_dir = base / "assets" / "processed"
    processed_dir.mkdir(exist_ok=True)
    (processed_dir / "characters").mkdir(exist_ok=True)
    (processed_dir / "locations").mkdir(exist_ok=True)
    (processed_dir / "items").mkdir(exist_ok=True)
    
    print("=== 处理角色素材 ===")
    char_files = sorted(chars_dir.glob("*.png"))
    char_names = ["detective", "baker_tom", "innkeeper_mary", "sheriff"]
    for i, (cf, name) in enumerate(zip(char_files, char_names)):
        if cf.name == ".gdkeep":
            continue
        process_character(str(cf), str(processed_dir / "characters" / f"{name}.png"), size=16)
        # 同时生成 2x 版本用于对话头像
        process_character(str(cf), str(processed_dir / "characters" / f"{name}_portrait.png"), size=48)
    
    print("\n=== 处理场景素材 ===")
    loc_files = sorted(locs_dir.glob("*.png"))
    loc_names = ["town_square", "bakery", "inn"]
    for lf, name in zip(loc_files, loc_names):
        if lf.name == ".gdkeep":
            continue
        process_scene(str(lf), str(processed_dir / "locations" / f"{name}_bg.png"))
    
    print("\n=== 处理物品素材 ===")
    item_files = sorted(items_dir.glob("*.png"))
    for itf in item_files:
        if itf.name == ".gdkeep":
            continue
        process_items(str(itf), str(processed_dir / "items"))
    
    print("\n✅ 全部处理完成！素材在 assets/processed/ 目录下")


if __name__ == "__main__":
    main()
