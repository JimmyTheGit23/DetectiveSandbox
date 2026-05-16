"""中国风新方案资源后处理：
- 场景插图：缩放到 1280x720，覆盖游戏画面
- 立绘：保持比例缩放到 768 高，作为对话立绘
- UI 图标：紫底色键去除 + 切片 6 个图标
"""
from __future__ import annotations
from PIL import Image
import numpy as np
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / 'assets/ai_raw'
OUT = ROOT / 'assets/cn'


def find_one(pattern: str, base: Path) -> Path | None:
    files = sorted(base.glob(f'{pattern}*.png'))
    return files[-1] if files else None


def remove_magenta(img: Image.Image, tol: int = 70) -> Image.Image:
    img = img.convert('RGBA')
    arr = np.array(img)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    mag = (r > 200) & (g < tol) & (b > 200)
    mag2 = (r > 180) & (g < 120) & (b > 180) & (r.astype(int) + b.astype(int) > g.astype(int) * 3)
    arr[mag | mag2] = [0, 0, 0, 0]
    return Image.fromarray(arr)


def autocrop(img: Image.Image, padding: int = 0) -> Image.Image:
    arr = np.array(img.convert('RGBA'))
    alpha = arr[:, :, 3]
    nz = np.argwhere(alpha > 10)
    if nz.size == 0:
        return img
    y0, x0 = nz.min(axis=0)
    y1, x1 = nz.max(axis=0)
    return img.crop((max(0, x0 - padding), max(0, y0 - padding),
                     min(arr.shape[1], x1 + 1 + padding),
                     min(arr.shape[0], y1 + 1 + padding)))


def process_scene(src: Path, out_path: Path, target=(1280, 720)):
    img = Image.open(src).convert('RGB')
    # 智能裁剪：原图可能有偏白边缘（接近纯白但稍带色偏）
    arr = np.array(img)
    h, w = arr.shape[:2]
    # 把"非常浅"的像素都视作白边（阈值放宽到 230）
    # 同时要求 R/G/B 都很亮（避免误裁亮色画面）
    tol = 230
    mask = (arr[:, :, 0] > tol) & (arr[:, :, 1] > tol) & (arr[:, :, 2] > tol)
    # 一行"几乎全白"才算白边（>95% 像素）
    row_white_ratio = mask.mean(axis=1)
    col_white_ratio = mask.mean(axis=0)
    threshold = 0.92
    y0 = 0
    while y0 < h and row_white_ratio[y0] > threshold:
        y0 += 1
    y1 = h
    while y1 > y0 and row_white_ratio[y1 - 1] > threshold:
        y1 -= 1
    x0 = 0
    while x0 < w and col_white_ratio[x0] > threshold:
        x0 += 1
    x1 = w
    while x1 > x0 and col_white_ratio[x1 - 1] > threshold:
        x1 -= 1
    if y1 - y0 > 100 and x1 - x0 > 100:
        img = img.crop((x0, y0, x1, y1))
    # 保持比例，按目标比例 16:9 居中裁剪
    src_w, src_h = img.size
    target_ratio = target[0] / target[1]
    src_ratio = src_w / src_h
    if src_ratio > target_ratio:
        # 原图更宽，左右裁
        new_w = int(src_h * target_ratio)
        x = (src_w - new_w) // 2
        img = img.crop((x, 0, x + new_w, src_h))
    else:
        new_h = int(src_w / target_ratio)
        y = (src_h - new_h) // 2
        img = img.crop((0, y, src_w, y + new_h))
    img = img.resize(target, Image.Resampling.LANCZOS)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path, 'PNG')
    try:
        print(f'  scene: {out_path.relative_to(ROOT)}')
    except ValueError:
        print(f'  scene: {out_path}')


def process_portrait(src: Path, out_path: Path, target_h: int = 900):
    """立绘按比例缩放到目标高度，保持原始比例。"""
    img = Image.open(src).convert('RGBA')
    src_w, src_h = img.size
    scale = target_h / src_h
    new_w = int(src_w * scale)
    img = img.resize((new_w, target_h), Image.Resampling.LANCZOS)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path, 'PNG')
    print(f'  portrait: {out_path.relative_to(ROOT)} ({new_w}x{target_h})')


def process_ui_icons(src: Path, out_dir: Path):
    """UI 图标 atlas (1024x1024 紫底 3x3 = 9 个圆形图标) 切到 6 个。"""
    img = Image.open(src)
    img = remove_magenta(img)
    arr = np.array(img.convert('RGBA'))
    h, w = arr.shape[:2]
    # 3x3 网格
    cell_w = w // 3
    cell_h = h // 3
    # 想要的 6 个 (按行列坐标)：地图(0,0) 对话(0,1) 移动(0,2) 探索(1,1) 笔记本(2,1) 指证(2,2)
    mapping = [
        ('icon_map.png', 0, 0),
        ('icon_talk.png', 0, 1),
        ('icon_move.png', 0, 2),
        ('icon_search.png', 1, 1),
        ('icon_notebook.png', 2, 1),
        ('icon_accuse.png', 2, 2),
    ]
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, row, col in mapping:
        sub = img.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
        sub = autocrop(sub, padding=4)
        # 缩放到 128x128
        sub = sub.resize((128, 128), Image.Resampling.LANCZOS)
        sub.save(out_dir / name)
        print(f'  icon: {(out_dir / name).relative_to(ROOT)}')


def main():
    print('=== 场景插图 ===')
    scenes = [
        ('Late_Ming_Dynasty_China__tradi_2026-05-16T07-04-47', 'post_station.png'),     # 临川驿后院
        ('Late_Ming_Dynasty_China__tradi_2026-05-16T07-05-37', 'shen_residence.png'),   # 沈砚秋宅
        ('Late_Ming_Dynasty_China__tradi_2026-05-16T07-05-41', 'yamen.png'),            # 县衙
        ('Late_Ming_Dynasty_China__tradi_2026-05-16T07-05-45', 'spring_wind_tower.png'),  # 春风楼
        ('Late_Ming_Dynasty_China__tradi_2026-05-16T07-05-50', 'guanyin_temple.png'),   # 观音庙
        ('Late_Ming_Dynasty_China__tradi_2026-05-16T07-05-51', 'market.png'),           # 集市
        ('Hand_drawn_ink_painting_style_', 'town_map.png'),                              # 全镇地图
        ('Traditional_Chinese_ink_painti', 'prologue.png'),                              # 序章插图
    ]
    for prefix, out_name in scenes:
        src = find_one(prefix, RAW / 'scenes')
        if not src:
            print(f'  ! 未找到: {prefix}')
            continue
        process_scene(src, OUT / 'scenes' / out_name)

    print()
    print('=== 立绘（按生成顺序） ===')
    portrait_files = sorted((RAW / 'portraits').glob('*.png'))
    portrait_names = [
        'lu_zhao.png',          # 主角 陆昭（监察御史）
        'liu_wenqing.png',      # 知县 柳文卿
        'su_wan.png',           # 沈夫人 苏婉
        'gu_qingxuan.png',      # 白衣公子 顾清玄  (07:06:44)
        'zhao_dayou.png',       # 驿丞 赵大有
        'xiao_cui.png',         # 花魁 小翠
        'daoming.png',          # 道明法师
        'ma_san.png',           # 捕头 马三
    ]
    # 文件名按时间戳排序后是：
    # 07:06:28 lu_zhao
    # 07:06:32 liu_wenqing
    # 07:06:36 su_wan
    # 07:06:44 gu_qingxuan  (但被生成为 :44，可能在 :47 之前)
    # 07:06:47 zhao_dayou
    # 07:06:49 xiao_cui
    # 07:06:55 daoming
    # 07:06:57 ma_san
    for src, name in zip(portrait_files, portrait_names):
        process_portrait(src, OUT / 'portraits' / name)

    print()
    print('=== UI 图标 ===')
    ui_src = find_one('A_set_of_6_traditional_Chinese', RAW / 'ui')
    if ui_src:
        process_ui_icons(ui_src, OUT / 'ui')

    print()
    print('Done!')


if __name__ == '__main__':
    main()
