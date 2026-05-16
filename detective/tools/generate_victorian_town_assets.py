#!/usr/bin/env python3
"""
英伦探案风广场美术资源生成器
目标：稳定、连续、Godot-ready 的 32x32 pixel tileset + object atlas

说明：
- 地面 tiles 严格按拓扑分类，center 只能和 center 混用
- 物件单独 atlas，透明背景，独立碰撞
- 风格：低饱和、阴雨、维多利亚/英伦小镇、侦探推理氛围
"""

from PIL import Image, ImageDraw
from pathlib import Path
import math

OUT = Path("assets/tilesets")
OUT.mkdir(parents=True, exist_ok=True)
T = 32

P = {
    # dark victorian/noir palette
    "void": (0, 0, 0, 0),
    "stone_a": (72, 76, 82, 255),
    "stone_b": (82, 86, 92, 255),
    "stone_c": (58, 62, 68, 255),
    "stone_hi": (105, 108, 115, 255),
    "mortar": (38, 40, 45, 255),
    "wet": (42, 52, 68, 150),
    "wet_hi": (100, 125, 145, 95),
    "brick_a": (76, 48, 42, 255),
    "brick_b": (96, 58, 48, 255),
    "brick_dark": (45, 30, 28, 255),
    "wood_a": (82, 55, 36, 255),
    "wood_b": (112, 75, 45, 255),
    "wood_dark": (45, 30, 22, 255),
    "iron": (55, 58, 64, 255),
    "iron_hi": (118, 122, 130, 255),
    "brass": (176, 135, 55, 255),
    "lamp": (255, 214, 105, 255),
    "lamp_glow": (255, 210, 90, 100),
    "paper": (188, 174, 135, 255),
    "paper_dark": (120, 105, 80, 255),
    "water": (35, 58, 84, 255),
    "water_hi": (74, 105, 135, 255),
    "tape": (210, 185, 60, 255),
    "tape_dark": (100, 82, 25, 255),
}

def put(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), P[c] if isinstance(c, str) else c)

def rect(draw, xy, c):
    draw.rectangle(xy, fill=P[c] if isinstance(c, str) else c)

def line(draw, xy, c, width=1):
    draw.line(xy, fill=P[c] if isinstance(c, str) else c, width=width)

# ─────────────────────────────────────────────
# 地面 tileset：8列 x 4行
# row0: cobblestone center variants (连续中心地板)
# row1: edge/corner placeholders（后续 terrain 用）
# row2: wet/crack overlay（透明叠加）
# row3: brick/curb/manhole/base variants
# ─────────────────────────────────────────────

def draw_cobble_center(img, tx, ty, seed=0):
    bx, by = tx*T, ty*T
    d = ImageDraw.Draw(img)
    rect(d, (bx, by, bx+T-1, by+T-1), "mortar")
    # irregular stone blocks within 32x32, but all edges use mortar so seamless
    for yy in range(0, T, 8):
        offset = (seed * 3 + yy // 8 * 5) % 7
        x = -offset
        while x < T:
            w = 7 + ((x + yy + seed) % 5)
            h = 7
            x1, y1 = max(1, x+1), yy+1
            x2, y2 = min(T-2, x+w), min(T-2, yy+h)
            if x1 < x2 and y1 < y2:
                base = ["stone_a", "stone_b", "stone_c"][(seed + x + yy) % 3]
                rect(d, (bx+x1, by+y1, bx+x2, by+y2), base)
                # subtle top highlight
                line(d, (bx+x1, by+y1, bx+x2, by+y1), "stone_hi")
                # dark bottom/right
                line(d, (bx+x1, by+y2, bx+x2, by+y2), "stone_c")
                line(d, (bx+x2, by+y1, bx+x2, by+y2), "stone_c")
            x += w + 1
    # small dirt speckles, avoid borders for seamlessness
    for i in range(10):
        x = 2 + ((seed*17 + i*7) % 28)
        y = 2 + ((seed*11 + i*13) % 28)
        put(img, bx+x, by+y, "stone_c")

def draw_edge_tile(img, tx, ty, direction):
    # Start from center then add darker curb on one side
    draw_cobble_center(img, tx, ty, tx + ty*8)
    bx, by = tx*T, ty*T
    d = ImageDraw.Draw(img)
    if direction == "top": rect(d, (bx, by, bx+31, by+5), "brick_dark")
    if direction == "bottom": rect(d, (bx, by+26, bx+31, by+31), "brick_dark")
    if direction == "left": rect(d, (bx, by, bx+5, by+31), "brick_dark")
    if direction == "right": rect(d, (bx+26, by, bx+31, by+31), "brick_dark")

def draw_wet_overlay(img, tx, ty, seed=0):
    bx, by = tx*T, ty*T
    d = ImageDraw.Draw(img)
    # transparent base
    # puddle blob
    pts = []
    cx, cy = bx+16, by+17
    for a in range(0, 360, 30):
        r = 7 + ((seed + a) % 5)
        pts.append((cx + int(math.cos(math.radians(a))*r*1.5), cy + int(math.sin(math.radians(a))*r)))
    d.polygon(pts, fill=P["wet"])
    line(d, (bx+10, by+14, bx+21, by+13), "wet_hi")
    line(d, (bx+12, by+19, bx+24, by+18), "wet_hi")

def draw_crack_overlay(img, tx, ty, seed=0):
    bx, by = tx*T, ty*T
    d = ImageDraw.Draw(img)
    x, y = bx + 6 + seed % 8, by + 7 + (seed*3) % 6
    pts = [(x,y), (x+5,y+3), (x+8,y+8), (x+13,y+11), (x+18,y+18), (x+23,y+22)]
    line(d, pts, (25, 26, 30, 210), 2)
    line(d, (pts[2][0], pts[2][1], pts[2][0]-5, pts[2][1]+6), (25,26,30,180), 1)
    line(d, (pts[3][0], pts[3][1], pts[3][0]+5, pts[3][1]-4), (25,26,30,180), 1)

def draw_brick_tile(img, tx, ty, seed=0):
    bx, by = tx*T, ty*T
    d = ImageDraw.Draw(img)
    rect(d, (bx,by,bx+31,by+31), "brick_dark")
    for row in range(0, 32, 8):
        off = 8 if (row//8 + seed) % 2 else 0
        for x in range(-off, 32, 16):
            color = "brick_a" if (x+row+seed) % 3 else "brick_b"
            rect(d, (bx+x+1, by+row+1, bx+x+15, by+row+7), color)
            line(d, (bx+x+1, by+row+1, bx+x+15, by+row+1), "stone_hi")

def draw_ground_tileset():
    img = Image.new("RGBA", (8*T, 4*T), (0,0,0,0))
    # row 0 center variants
    for x in range(8):
        draw_cobble_center(img, x, 0, x)
    # row 1 edge/corner variants
    dirs = ["top", "bottom", "left", "right", "top", "bottom", "left", "right"]
    for x, direction in enumerate(dirs):
        draw_edge_tile(img, x, 1, direction)
    # row 2 overlays
    for x in range(4):
        draw_wet_overlay(img, x, 2, x)
    for x in range(4,8):
        draw_crack_overlay(img, x, 2, x)
    # row 3 brick/curb variants
    for x in range(4):
        draw_brick_tile(img, x, 3, x)
    for x in range(4,8):
        draw_cobble_center(img, x, 3, x+20)
        d=ImageDraw.Draw(img)
        bx,by=x*T,3*T
        rect(d,(bx,by+24,bx+31,by+31),"brick_dark")
    img.save(OUT / "victorian_ground_32.png")
    print("victorian_ground_32.png", img.size)

# ─────────────────────────────────────────────
# 物件 atlas：8列 x 4行，透明背景
# 0,0 gas lamp 1x2; 1,0 bench 2x1; 3,0 fountain 3x3; 6,0 notice board 2x2
# 0,2 manhole; 1,2 newspaper; 2,2 police tape 2x1; 4,2 crate; 5,2 evidence marker
# ─────────────────────────────────────────────

def draw_gas_lamp(img, tx, ty):
    bx, by = tx*T, ty*T
    d=ImageDraw.Draw(img)
    # glow
    d.ellipse((bx+6,by+0,bx+26,by+18), fill=P["lamp_glow"])
    rect(d,(bx+12,by+9,bx+20,by+17),"iron")
    rect(d,(bx+14,by+11,bx+18,by+15),"lamp")
    rect(d,(bx+10,by+17,bx+22,by+20),"iron_hi")
    rect(d,(bx+15,by+20,bx+17,by+55),"iron")
    rect(d,(bx+10,by+55,bx+22,by+62),"iron")
    rect(d,(bx+7,by+62,bx+25,by+64),"iron_hi")

def draw_bench(img, tx, ty):
    bx, by = tx*T, ty*T
    d=ImageDraw.Draw(img)
    rect(d,(bx+2,by+6,bx+61,by+11),"wood_b")
    rect(d,(bx+2,by+15,bx+61,by+21),"wood_a")
    line(d,(bx+2,by+6,bx+61,by+6),"wood_dark")
    line(d,(bx+2,by+15,bx+61,by+15),"wood_dark")
    rect(d,(bx+8,by+21,bx+12,by+29),"iron")
    rect(d,(bx+50,by+21,bx+54,by+29),"iron")

def draw_fountain(img, tx, ty):
    bx,by=tx*T,ty*T
    d=ImageDraw.Draw(img)
    cx,cy=bx+48,by+52
    d.ellipse((cx-42,cy-26,cx+42,cy+26), fill=P["stone_c"], outline=P["stone_hi"], width=3)
    d.ellipse((cx-34,cy-20,cx+34,cy+20), fill=P["water"], outline=P["mortar"], width=2)
    rect(d,(cx-8,cy-32,cx+8,cy+8),"stone_b")
    rect(d,(cx-4,cy-42,cx+4,cy-32),"stone_hi")
    line(d,(cx-20,cy-10,cx-8,cy-14),"water_hi",2)
    line(d,(cx+8,cy-14,cx+22,cy-10),"water_hi",2)

def draw_notice(img, tx, ty):
    bx,by=tx*T,ty*T
    d=ImageDraw.Draw(img)
    rect(d,(bx+7,by+8,bx+57,by+45),"wood_dark")
    rect(d,(bx+11,by+12,bx+53,by+41),"wood_a")
    rect(d,(bx+15,by+16,bx+49,by+37),"paper")
    line(d,(bx+18,by+21,bx+45,by+21),"paper_dark")
    line(d,(bx+18,by+27,bx+43,by+27),"paper_dark")
    line(d,(bx+18,by+33,bx+39,by+33),"paper_dark")
    rect(d,(bx+12,by+45,bx+17,by+63),"wood_dark")
    rect(d,(bx+47,by+45,bx+52,by+63),"wood_dark")

def draw_manhole(img, tx, ty):
    bx,by=tx*T,ty*T
    d=ImageDraw.Draw(img)
    d.ellipse((bx+5,by+8,bx+27,by+26), fill=P["iron"], outline=P["iron_hi"], width=2)
    for x in range(10,24,4): line(d,(bx+x,by+10,bx+x-4,by+24),"mortar",1)

def draw_newspaper(img, tx, ty):
    bx,by=tx*T,ty*T
    d=ImageDraw.Draw(img)
    rect(d,(bx+7,by+10,bx+24,by+22),"paper")
    line(d,(bx+9,by+13,bx+22,by+13),"paper_dark")
    line(d,(bx+9,by+17,bx+20,by+17),"paper_dark")
    rect(d,(bx+5,by+18,bx+22,by+25),"paper_dark")

def draw_tape(img, tx, ty):
    bx,by=tx*T,ty*T
    d=ImageDraw.Draw(img)
    rect(d,(bx+2,by+12,bx+62,by+19),"tape")
    for x in range(4,62,10):
        line(d,(bx+x,by+12,bx+x+7,by+19),"tape_dark",2)
    rect(d,(bx+2,by+8,bx+5,by+28),"iron")
    rect(d,(bx+59,by+8,bx+62,by+28),"iron")

def draw_object_atlas():
    img = Image.new("RGBA", (8*T,4*T), (0,0,0,0))
    draw_gas_lamp(img,0,0)
    draw_bench(img,1,0)
    draw_fountain(img,3,0)
    draw_notice(img,6,0)
    # row 2 is intentionally reserved for the 3x3 fountain footprint (cols 3-5).
    # Small props are placed on row 3 to avoid atlas overlap.
    draw_manhole(img,0,3)
    draw_newspaper(img,1,3)
    draw_tape(img,2,3)
    # crate
    d=ImageDraw.Draw(img); bx,by=4*T,3*T
    rect(d,(bx+4,by+6,bx+28,by+28),"wood_a"); line(d,(bx+4,by+6,bx+28,by+28),"wood_dark",2); line(d,(bx+28,by+6,bx+4,by+28),"wood_dark",2)
    # evidence marker
    bx=5*T
    rect(d,(bx+12,by+6,bx+20,by+24),"paper"); line(d,(bx+12,by+6,bx+20,by+6),"tape",2)
    img.save(OUT / "victorian_objects_32.png")
    print("victorian_objects_32.png", img.size)

if __name__ == "__main__":
    draw_ground_tileset()
    draw_object_atlas()
    print("done")
