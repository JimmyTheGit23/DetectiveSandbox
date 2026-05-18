#!/usr/bin/env python3
"""
从半身像中裁剪出统一规格的圆形头像（128x128 正方形，取顶部脸区域）。
输出到 assets/cn/portraits/avatars/ 目录。
"""
import os
from PIL import Image

# NPC 半身像路径
PORTRAITS_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "cn", "portraits")
OUTPUT_DIR = os.path.join(PORTRAITS_DIR, "avatars")

# 需要裁剪的 NPC 列表
NPCS = [
    "lu_zhao",
    "liu_wenqing",
    "su_wan",
    "zhao_dayou",
    "gu_qingxuan",
    "xiao_cui",
    "daoming",
    "ma_san",
]

# 输出尺寸
OUTPUT_SIZE = 128

# 裁剪区域：取图片顶部多少比例作为脸部区域
# 对于半身像，脸通常在顶部 30-40% 区域
FACE_TOP_RATIO = 0.0    # 从顶部开始
FACE_BOTTOM_RATIO = 0.35  # 到 35% 处


def crop_face_avatar(input_path: str, output_path: str):
    """从半身像裁剪出正方形头像"""
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size

    # 计算脸部区域
    top = int(h * FACE_TOP_RATIO)
    bottom = int(h * FACE_BOTTOM_RATIO)
    face_height = bottom - top

    # 取正方形区域（以脸部区域高度为边长，水平居中）
    crop_size = face_height
    if crop_size > w:
        crop_size = w

    left = (w - crop_size) // 2
    right = left + crop_size

    # 如果脸区域高度大于宽度，调整 bottom
    if face_height > crop_size:
        bottom = top + crop_size

    # 裁剪
    cropped = img.crop((left, top, right, bottom))

    # 缩放到目标尺寸
    cropped = cropped.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.LANCZOS)

    # 保存
    cropped.save(output_path, "PNG")
    print(f"  ✓ {os.path.basename(output_path)} ({OUTPUT_SIZE}x{OUTPUT_SIZE})")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"输出目录: {OUTPUT_DIR}")
    print(f"头像尺寸: {OUTPUT_SIZE}x{OUTPUT_SIZE}")
    print(f"裁剪区域: 顶部 {int(FACE_TOP_RATIO*100)}% ~ {int(FACE_BOTTOM_RATIO*100)}%")
    print()

    for npc_id in NPCS:
        input_path = os.path.join(PORTRAITS_DIR, f"{npc_id}.png")
        output_path = os.path.join(OUTPUT_DIR, f"{npc_id}.png")

        if not os.path.exists(input_path):
            print(f"  ✗ {npc_id}.png 未找到，跳过")
            continue

        crop_face_avatar(input_path, output_path)

    print(f"\n完成！共生成 {len([f for f in os.listdir(OUTPUT_DIR) if f.endswith('.png')])} 个头像")


if __name__ == "__main__":
    main()
