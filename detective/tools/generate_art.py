#!/usr/bin/env python3
"""
正规像素美术资源生成工具
生成标准 16x16 tileset sprite sheet + 角色 sprite sheet
所有资源按正规游戏开发规范制作
"""

from PIL import Image, ImageDraw
import os

TILE = 16  # 基础瓦片尺寸
OUT = "assets/tilesets"
CHAR_OUT = "assets/characters_final"

os.makedirs(OUT, exist_ok=True)
os.makedirs(CHAR_OUT, exist_ok=True)

# ════════════════════════════════════════════
# 调色板（暗色调侦探风，限定 24 色）
# ════════════════════════════════════════════

P = {
    # 地板
    "wood_light":    (120, 85, 55),
    "wood_mid":      (95, 65, 40),
    "wood_dark":     (70, 48, 28),
    "wood_plank":    (85, 58, 35),
    "stone_light":   (130, 130, 135),
    "stone_mid":     (100, 100, 108),
    "stone_dark":    (72, 72, 80),
    "cobble_light":  (115, 115, 120),
    "cobble_dark":   (85, 85, 92),
    # 墙壁
    "wall_light":    (90, 75, 60),
    "wall_mid":      (65, 52, 38),
    "wall_dark":     (45, 35, 25),
    "brick_light":   (140, 80, 55),
    "brick_dark":    (105, 58, 38),
    # 物件
    "metal":         (160, 165, 170),
    "metal_dark":    (110, 115, 120),
    "gold":          (220, 190, 50),
    "red":           (180, 50, 40),
    "green_leaf":    (60, 110, 50),
    "green_dark":    (40, 75, 32),
    "water":         (50, 80, 140),
    "water_light":   (70, 110, 170),
    "candle":        (255, 210, 100),
    "candle_glow":   (255, 240, 180),
    # 通用
    "black":         (20, 18, 22),
    "shadow":        (30, 28, 35),
}

def px(img, x, y, color_name):
    """在 sprite sheet 中的某个位置画单个像素"""
    if color_name in P:
        img.putpixel((x, y), (*P[color_name], 255))

def fill_tile(img, tx, ty, color_name):
    """用单色填充一个 16x16 tile 区域"""
    c = (*P[color_name], 255)
    for y in range(ty * TILE, (ty + 1) * TILE):
        for x in range(tx * TILE, (tx + 1) * TILE):
            img.putpixel((x, y), c)

def draw_rect(img, x1, y1, x2, y2, color_name):
    c = (*P[color_name], 255)
    for y in range(y1, y2):
        for x in range(x1, x2):
            img.putpixel((x, y), c)

# ════════════════════════════════════════════
# 1. 地板 Tileset（8 列 x 4 行 = 32 tiles）
#    行0: 木地板（4 变体 + 木板线变体）
#    行1: 石地板（4 变体）
#    行2: 鹅卵石地面（4 变体）
#    行3: 特殊地板（地毯、泥土等）
# ════════════════════════════════════════════

def make_floor_tileset():
    W, H = 8 * TILE, 4 * TILE
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # --- 行 0: 木地板 ---
    for variant in range(8):
        bx = variant * TILE
        by = 0
        # 基础木色
        base = P["wood_mid"] if variant % 2 == 0 else P["wood_light"]
        plank = P["wood_dark"] if variant % 2 == 0 else P["wood_plank"]
        for y in range(TILE):
            for x in range(TILE):
                # 木板线（每 4 像素一条水平线）
                if y % 4 == 0:
                    img.putpixel((bx + x, by + y), (*plank, 255))
                else:
                    # 加一点随机纹理感
                    c = base if (x + y + variant) % 7 != 0 else plank
                    img.putpixel((bx + x, by + y), (*c, 255))

    # --- 行 1: 石地板 ---
    for variant in range(8):
        bx = variant * TILE
        by = TILE
        for y in range(TILE):
            for x in range(TILE):
                # 石板纹理：大块石板 + 缝隙
                is_gap = (x % 8 == 0) or (y % 8 == 0)
                if is_gap:
                    img.putpixel((bx + x, by + y), (*P["stone_dark"], 255))
                else:
                    c = P["stone_light"] if (x + y + variant * 3) % 5 > 1 else P["stone_mid"]
                    img.putpixel((bx + x, by + y), (*c, 255))

    # --- 行 2: 鹅卵石 ---
    for variant in range(8):
        bx = variant * TILE
        by = 2 * TILE
        for y in range(TILE):
            for x in range(TILE):
                # 不规则鹅卵石
                val = (x * 7 + y * 13 + variant * 37) % 17
                if val < 3:
                    img.putpixel((bx + x, by + y), (*P["cobble_dark"], 255))
                elif val < 8:
                    img.putpixel((bx + x, by + y), (*P["cobble_light"], 255))
                else:
                    img.putpixel((bx + x, by + y), (*P["stone_mid"], 255))

    # --- 行 3: 特殊地板 ---
    # 3-0: 深色地板
    for y in range(TILE):
        for x in range(TILE):
            c = P["wall_dark"] if (x + y) % 3 == 0 else P["shadow"]
            img.putpixel((x, 3 * TILE + y), (*c, 255))
    # 3-1 ~ 3-3: 地毯
    for variant in range(1, 4):
        bx = variant * TILE
        by = 3 * TILE
        carpet_c = [(140, 40, 40), (40, 60, 120), (80, 50, 100)][variant - 1]
        carpet_edge = tuple(max(0, c - 30) for c in carpet_c)
        for y in range(TILE):
            for x in range(TILE):
                if x == 0 or x == 15 or y == 0 or y == 15:
                    img.putpixel((bx + x, by + y), (*carpet_edge, 255))
                else:
                    img.putpixel((bx + x, by + y), (*carpet_c, 255))
    # 填充剩余
    for variant in range(4, 8):
        bx = variant * TILE
        by = 3 * TILE
        for y in range(TILE):
            for x in range(TILE):
                c = P["wood_dark"]
                img.putpixel((bx + x, by + y), (*c, 255))

    img.save(f"{OUT}/floor_tiles.png")
    print(f"  floor_tiles.png ({W}x{H}, {W // TILE * H // TILE} tiles)")
    return img

# ════════════════════════════════════════════
# 2. 墙壁 Tileset（8 列 x 2 行 = 16 tiles）
# ════════════════════════════════════════════

def make_wall_tileset():
    W, H = 8 * TILE, 2 * TILE
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # 行 0: 木墙壁变体
    for v in range(8):
        bx, by = v * TILE, 0
        for y in range(TILE):
            for x in range(TILE):
                if y < 3:
                    c = P["wall_dark"]
                elif y < 5:
                    c = P["wall_mid"]
                else:
                    is_plank = (y % 3 == 0)
                    c = P["wall_dark"] if is_plank else P["wall_light"]
                    if (x + v * 5) % 11 == 0:
                        c = P["wall_mid"]
                img.putpixel((bx + x, by + y), (*c, 255))

    # 行 1: 砖墙变体
    for v in range(8):
        bx, by = v * TILE, TILE
        for y in range(TILE):
            for x in range(TILE):
                # 砖块纹理：交错排列
                brick_row = y // 4
                offset = 4 if brick_row % 2 == 1 else 0
                is_mortar = (y % 4 == 0) or ((x + offset) % 8 == 0)
                if is_mortar:
                    c = P["wall_dark"]
                else:
                    c = P["brick_light"] if (x + y + v) % 5 > 1 else P["brick_dark"]
                img.putpixel((bx + x, by + y), (*c, 255))

    img.save(f"{OUT}/wall_tiles.png")
    print(f"  wall_tiles.png ({W}x{H}, {W // TILE * H // TILE} tiles)")
    return img

# ════════════════════════════════════════════
# 3. 物件 Tileset（8 列 x 6 行 = 48 tiles）
#    家具、装饰、道具——每个物件占 1~4 个 tile
# ════════════════════════════════════════════

def make_object_tileset():
    W, H = 8 * TILE, 6 * TILE
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    def put(x, y, c):
        if 0 <= x < W and 0 <= y < H:
            img.putpixel((x, y), c if len(c) == 4 else (*c, 255))

    # --- 桌子 (0,0) 2x1 ---
    for y in range(2, 14):
        for x in range(2, 30):
            put(x, y, P["wood_mid"])
    for x in range(2, 30):
        put(x, 2, P["wood_dark"])
        put(x, 13, P["wood_dark"])
    for y in range(2, 14):
        put(2, y, P["wood_dark"])
        put(29, y, P["wood_dark"])
    # 桌腿
    for y in range(14, 16):
        put(4, y, P["wood_dark"]); put(5, y, P["wood_dark"])
        put(26, y, P["wood_dark"]); put(27, y, P["wood_dark"])

    # --- 椅子 (2,0) 1x1 ---
    bx = 2 * TILE
    for y in range(4, 14):
        for x in range(3, 13):
            put(bx + x, y, P["wood_light"])
    put(bx + 3, 14, P["wood_dark"]); put(bx + 12, 14, P["wood_dark"])
    # 靠背
    for x in range(3, 13):
        put(bx + x, 2, P["wood_dark"]); put(bx + x, 3, P["wood_dark"])

    # --- 书架 (3,0) 1x2 ---
    bx = 3 * TILE
    for y in range(0, 32):
        for x in range(1, 15):
            put(bx + x, y, P["wood_mid"])
    # 层板
    for shelf_y in [0, 8, 16, 24, 31]:
        for x in range(0, 16):
            put(bx + x, shelf_y, P["wood_dark"])
    # 书本
    books = [(180, 40, 40), (40, 80, 160), (60, 130, 60), (200, 180, 50)]
    for shelf in range(4):
        sy = shelf * 8 + 1
        for i, bc in enumerate(books):
            for y in range(sy + 1, sy + 7):
                put(bx + 2 + i * 3, y, bc)
                put(bx + 3 + i * 3, y, bc)

    # --- 柜台 (4,0) 2x1 ---
    bx = 4 * TILE
    for y in range(3, 14):
        for x in range(1, 31):
            put(bx + x, y, P["wood_light"])
    for x in range(1, 31):
        put(bx + x, 3, P["wood_dark"])
        put(bx + x, 13, P["wood_dark"])

    # --- 烤炉 (6,0) 2x2 ---
    bx = 6 * TILE
    for y in range(0, 30):
        for x in range(1, 31):
            c = P["brick_dark"] if (x + y) % 5 < 2 else P["brick_light"]
            put(bx + x, y, c)
    # 炉门
    for y in range(10, 24):
        for x in range(8, 24):
            put(bx + x, y, P["black"])
    # 火焰
    for y in range(14, 22):
        for x in range(11, 21):
            put(bx + x, y, (255, 120, 30))
    for y in range(16, 20):
        for x in range(13, 19):
            put(bx + x, y, P["candle"])

    # --- 蜡烛 (0,2) 1x1 ---
    bx, by = 0, 2 * TILE
    # 底座
    for x in range(5, 11):
        put(bx + x, by + 12, P["metal"])
        put(bx + x, by + 13, P["metal_dark"])
    # 蜡烛体
    for y in range(5, 12):
        put(bx + 7, by + y, (240, 230, 210))
        put(bx + 8, by + y, (230, 220, 200))
    # 火焰
    put(bx + 7, by + 3, P["candle"])
    put(bx + 8, by + 3, P["candle"])
    put(bx + 7, by + 4, P["candle_glow"])
    put(bx + 8, by + 4, P["candle_glow"])

    # --- 壁灯 (1,2) ---
    bx, by = TILE, 2 * TILE
    for y in range(2, 8):
        put(bx + 6, by + y, P["metal"]); put(bx + 7, by + y, P["metal"])
        put(bx + 8, by + y, P["metal"]); put(bx + 9, by + y, P["metal"])
    put(bx + 7, by + 1, P["candle"]); put(bx + 8, by + 1, P["candle"])
    put(bx + 7, by + 0, P["candle_glow"])

    # --- 喷泉 (2,2) 2x2 ---
    bx, by = 2 * TILE, 2 * TILE
    # 圆形水池
    center_x, center_y = 16, 16
    for y in range(32):
        for x in range(32):
            dx, dy = x - center_x, y - center_y
            dist = (dx * dx + dy * dy) ** 0.5
            if dist < 14:
                put(bx + x, by + y, P["water"])
            elif dist < 15:
                put(bx + x, by + y, P["stone_dark"])
            elif dist < 16:
                put(bx + x, by + y, P["stone_mid"])
    # 中心柱
    for y in range(8, 24):
        for x in range(14, 18):
            put(bx + x, by + y, P["stone_light"])
    # 水花
    for x in [10, 12, 20, 22]:
        put(bx + x, by + 10, P["water_light"])
        put(bx + x, by + 11, P["water_light"])

    # --- 花盆 (4,2) ---
    bx, by = 4 * TILE, 2 * TILE
    for y in range(8, 15):
        for x in range(4, 12):
            put(bx + x, by + y, P["brick_dark"])
    for x in range(5, 11):
        for y in range(3, 8):
            put(bx + x, by + y, P["green_leaf"])
    put(bx + 7, by + 2, P["green_dark"]); put(bx + 8, by + 2, P["green_dark"])

    # --- 长椅 (5,2) 2x1 ---
    bx, by = 5 * TILE, 2 * TILE
    for y in range(4, 10):
        for x in range(1, 31):
            put(bx + x, by + y, P["wood_mid"])
    for x in range(1, 31):
        put(bx + x, by + 4, P["wood_dark"])
    # 腿
    put(bx + 2, by + 10, P["wood_dark"]); put(bx + 3, by + 10, P["wood_dark"])
    put(bx + 28, by + 10, P["wood_dark"]); put(bx + 29, by + 10, P["wood_dark"])
    # 靠背
    for y in range(1, 4):
        for x in range(1, 31):
            put(bx + x, by + y, P["wood_dark"])

    # --- 麻袋 (7,2) ---
    bx, by = 7 * TILE, 2 * TILE
    for y in range(3, 14):
        for x in range(3, 13):
            r = ((x - 8) ** 2 + (y - 8) ** 2) ** 0.5
            if r < 6:
                put(bx + x, by + y, (180, 160, 110))
            elif r < 7:
                put(bx + x, by + y, (150, 130, 90))

    # --- 灯柱 (0,4) 1x2 ---
    bx, by = 0, 4 * TILE
    for y in range(6, 30):
        put(bx + 7, by + y, P["metal"]); put(bx + 8, by + y, P["metal"])
    # 灯罩
    for y in range(2, 6):
        for x in range(5, 11):
            put(bx + x, by + y, P["metal_dark"])
    put(bx + 7, by + 1, P["candle_glow"]); put(bx + 8, by + 1, P["candle_glow"])
    # 底座
    for x in range(5, 11):
        put(bx + x, by + 30, P["metal_dark"]); put(bx + x, by + 31, P["metal_dark"])

    # --- 床 (1,4) 2x2 ---
    bx, by = TILE, 4 * TILE
    # 床框
    for y in range(2, 30):
        for x in range(1, 31):
            put(bx + x, by + y, P["wood_mid"])
    # 被子
    for y in range(4, 22):
        for x in range(3, 29):
            put(bx + x, by + y, (180, 180, 200))
    # 枕头
    for y in range(22, 28):
        for x in range(5, 27):
            put(bx + x, by + y, (220, 220, 230))

    # --- 楼梯 (3,4) 1x2 ---
    bx, by = 3 * TILE, 4 * TILE
    for step in range(8):
        sy = step * 4
        shade = 60 + step * 8
        for y in range(sy, sy + 4):
            for x in range(2, 14):
                put(bx + x, by + y, (shade, shade - 10, shade - 20))

    img.save(f"{OUT}/object_tiles.png")
    print(f"  object_tiles.png ({W}x{H})")
    return img

# ════════════════════════════════════════════
# 4. 角色 Sprite Sheet
#    每个角色: 4 方向 x 2 帧 = 8 帧
#    排列: 每行一个方向(下/左/右/上), 每行 2 帧
#    单帧 16x16, sheet = 32 x 64 per character
# ════════════════════════════════════════════

def draw_character_frame(img, bx, by, body, hat, pants, shoe, skin, eye, extra=None):
    """在 (bx,by) 处绘制一个 16x16 的 top-down 角色帧"""
    def put(x, y, c):
        if 0 <= bx + x < img.width and 0 <= by + y < img.height:
            img.putpixel((bx + x, by + y), (*c, 255))

    # 帽子 (y:1-4)
    for y in range(1, 4):
        for x in range(5, 11):
            put(x, y, hat)
    for x in range(4, 12):
        put(x, 4, hat)  # 帽檐

    # 脸 (y:5-7)
    for y in range(5, 7):
        for x in range(6, 10):
            put(x, y, skin)
    # 眼睛
    put(6, 5, eye); put(9, 5, eye)

    # 身体 (y:7-12)
    for y in range(7, 12):
        for x in range(5, 11):
            put(x, y, body)
    # 额外装饰（围裙/徽章等）
    if extra:
        for ex, ey, ec in extra:
            put(ex, ey, ec)

    # 裤子 (y:12-14)
    for y in range(12, 14):
        put(6, y, pants); put(7, y, pants)
        put(8, y, pants); put(9, y, pants)

    # 鞋 (y:14-15)
    put(6, 14, shoe); put(7, 14, shoe)
    put(8, 14, shoe); put(9, 14, shoe)


def draw_character_walk(img, bx, by, body, hat, pants, shoe, skin, eye, extra=None):
    """绘制行走帧（脚部偏移）"""
    def put(x, y, c):
        if 0 <= bx + x < img.width and 0 <= by + y < img.height:
            img.putpixel((bx + x, by + y), (*c, 255))

    # 帽子
    for y in range(1, 4):
        for x in range(5, 11):
            put(x, y, hat)
    for x in range(4, 12):
        put(x, 4, hat)

    # 脸
    for y in range(5, 7):
        for x in range(6, 10):
            put(x, y, skin)
    put(6, 5, eye); put(9, 5, eye)

    # 身体
    for y in range(7, 12):
        for x in range(5, 11):
            put(x, y, body)
    if extra:
        for ex, ey, ec in extra:
            put(ex, ey, ec)

    # 裤子 + 行走姿势（一脚前一脚后）
    for y in range(12, 14):
        put(5, y, pants); put(6, y, pants)  # 左脚前
        put(9, y, pants); put(10, y, pants)  # 右脚后

    put(5, 14, shoe); put(6, 14, shoe)
    put(9, 14, shoe); put(10, 14, shoe)


def make_character_sheet(name, body, hat, pants, shoe, skin, eye, extra=None):
    """生成角色 sprite sheet: 32x64 (2帧 x 4方向)"""
    sheet = Image.new("RGBA", (2 * TILE, 4 * TILE), (0, 0, 0, 0))

    # 4 方向: down(0), left(1), right(2), up(3)
    for direction in range(4):
        by = direction * TILE
        # 帧 0: 站立
        draw_character_frame(sheet, 0, by, body, hat, pants, shoe, skin, eye, extra)
        # 帧 1: 行走
        draw_character_walk(sheet, TILE, by, body, hat, pants, shoe, skin, eye, extra)

    sheet.save(f"{CHAR_OUT}/{name}_sheet.png")

    # 同时生成单帧用于当前系统兼容
    single = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw_character_frame(single, 0, 0, body, hat, pants, shoe, skin, eye, extra)
    single.save(f"assets/processed/characters/{name}.png")

    # 头像 3x 放大
    portrait = single.resize((48, 48), Image.Resampling.NEAREST)
    portrait.save(f"assets/processed/characters/{name}_portrait.png")

    print(f"  {name}_sheet.png (32x64, 8 frames)")


# ════════════════════════════════════════════
# 执行生成
# ════════════════════════════════════════════

if __name__ == "__main__":
    print("=== 生成地板 Tileset ===")
    make_floor_tileset()

    print("\n=== 生成墙壁 Tileset ===")
    make_wall_tileset()

    print("\n=== 生成物件 Tileset ===")
    make_object_tileset()

    print("\n=== 生成角色 Sprite Sheet ===")

    # 侦探
    make_character_sheet("detective",
        body=(45, 55, 90), hat=(101, 67, 33), pants=(55, 60, 80),
        shoe=(40, 35, 30), skin=(220, 190, 150), eye=(30, 30, 30))

    # 面包师 Tom
    make_character_sheet("baker_tom",
        body=(160, 120, 70), hat=(240, 240, 235), pants=(130, 95, 55),
        shoe=(80, 60, 40), skin=(220, 185, 140), eye=(50, 40, 30),
        extra=[(6, 8, (240, 240, 235)), (7, 8, (240, 240, 235)),
               (8, 8, (240, 240, 235)), (9, 8, (240, 240, 235)),
               (6, 9, (240, 240, 235)), (9, 9, (240, 240, 235))])

    # 旅馆老板娘 Mary
    make_character_sheet("innkeeper_mary",
        body=(120, 60, 120), hat=(120, 70, 50), pants=(100, 50, 100),
        shoe=(70, 50, 70), skin=(230, 195, 160), eye=(45, 35, 30))

    # 警长 Harris
    make_character_sheet("sheriff",
        body=(75, 95, 55), hat=(65, 80, 50), pants=(60, 75, 45),
        shoe=(50, 45, 35), skin=(210, 180, 140), eye=(40, 35, 30),
        extra=[(7, 9, (220, 190, 50))])  # 金色徽章

    print("\n✅ 全部美术资源生成完成!")
    print(f"  Tilesets: {OUT}/")
    print(f"  Characters: {CHAR_OUT}/")
    print(f"  Processed: assets/processed/characters/")
