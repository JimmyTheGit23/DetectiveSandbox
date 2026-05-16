# Asset Credits / 素材授权记录

本项目原型阶段使用以下外部成熟像素素材包作为场景基础资源。

## 1. Chequered Ink — RPG Tilesets

- 来源: https://chequered.ink/rpg-tilesets/
- 使用文件:
  - `assets/vendor/chequered_ink/woodland_town.png`
  - 处理后: `assets/tilesets/vendor_woodland_32.png`
- 用途: 小镇广场户外地形、树木、标识、装饰物。
- 授权摘要（页面说明）:
  - 免费用于任何用途，包括商业用途。
  - 可署名或不署名。
  - 不得将未修改的原始素材作为自己的素材包出售或再分发。
- 备注: 建议正式发布前再次截图留存授权页面。

## 2. OpenGameArt — [16x16] Indoor RPG Tileset

- 来源: https://opengameart.org/content/16x16-indoor-rpg-tileset
- 作者: armisius
- 作者 itch.io: https://tilation.itch.io/
- 使用文件:
  - `assets/vendor/opengameart_indoor/all_in_one.png`
  - `assets/vendor/opengameart_indoor/furniture.png`
  - `assets/vendor/opengameart_indoor/walls_floor_doors.png`
  - `assets/vendor/opengameart_indoor/carpets.png`
  - 处理后:
    - `assets/tilesets/vendor_indoor_all_32.png`
    - `assets/tilesets/vendor_indoor_furniture_32.png`
    - `assets/tilesets/vendor_indoor_walls_32.png`
- 用途: 面包店、旅馆室内地板、墙壁、家具、装饰。
- 授权: CC-BY 3.0
- 署名要求: 需要在 credits 中提及作者页面或 OpenGameArt 页面。

## 当前处理方式

- 原始素材保存在 `assets/vendor/`。
- 游戏内使用 `assets/tilesets/*_32.png`，由 16×16 素材以 Nearest 方式放大为 32×32。
- 所有瓦片按 32×32 网格在 Godot 中绘制，保持像素锐利。
