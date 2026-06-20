---
name: portrait-blink-animation
description: 为本项目 Godot 立绘生成眨眼/说话动态分层 overlay。当用户要求给某角色做眨眼动画、说话口型、动态立绘、让立绘"活起来"时使用。基于差分 overlay 方案：body(原图)+eyes(眨眼层)+mouth(说话层)分层叠加。触发词：眨眼、说话口型、动态立绘、让立绘动起来、给XX做眨眼、blink、动态化。
---

# 立绘眨眼/说话动画生成 Skill

为 DetectiveSandbox 项目的角色立绘生成眨眼和说话口型的分层动画 overlay。

## 何时使用

- 用户要求给某角色（沈清月、凌瑶、陆昭等）做眨眼/说话动画
- 用户说"让立绘动起来""动态立绘""说话口型""眨眼"
- 需要把静态立绘升级为分层动画

## 核心方案

**分层叠加，绝不用整图序列帧**（否则美术量爆炸）：

```
body(原始完整立绘, 不动) 
  + eyes_overlay(眨眼: 半闭/全闭, 全帧透明, 只眼区有像素)
  + mouth_overlay(说话: 张嘴, 全帧透明, 只嘴区有像素)
```

眨眼序列：`睁眼 → 半闭(60ms) → 全闭(100ms) → 半闭(60ms) → 睁眼`，随机间隔 2.5~5s。

## 关键经验（踩过的坑，必须遵守）

1. **AI 生成整图有全局漂移**：Gemini「只改眼睛」会重绘整张图，全身有色偏。
   → 必须用**差分 overlay**：对比原图和闭眼变体，只提取真正变化的像素。

2. **眉毛绝对不能动**（用户硬性要求）：
   - 眉毛在 y≈250~272，眼睛在 y≈283~300（沈清月坐标，其他角色需重新定位）
   - ROI 的 y 起点必须 **避开眉毛**（设在眉眼间隔处，如 y=280）
   - 生成后**硬切**：`alpha[:HARD_CUT_TOP, :] = 0`，物理保证眉毛区零像素

3. **不要用椭圆遮罩填充**：会产生可见的渐变"圈"。用纯差分检测（diff>阈值才保留）。

4. **格式用 PNG 不用 WebP**：Godot 对 WebP 导入链路不稳定，会导致 overlay 加载失败（眨眼不动）。

5. **嘴巴 overlay 默认隐藏**：mouth 层只在说话状态显示，否则会看到嘴巴"圈"。

## 完整工作流

### 步骤 1：确认角色基础立绘存在
```
assets/cn/portraits/prologue_<role>.png   # 睁眼+闭嘴的完整立绘
```

### 步骤 2：定位眉毛/眼睛/嘴巴坐标
**每个角色坐标不同，必须重新定位！** 用扫描脚本找眉毛带和眼睛带的 y 分界：
```bash
# 先用单只眼睛的紧凑窗口(避免头发/发饰深色干扰检测), 例如左眼区:
python3 .codebuddy/skills/portrait-blink-animation/scripts/locate_features.py \
  --char <role> --x0 380 --x1 475 --y0 245 --y1 310
```
> ⚠️ 默认窗口太宽会把头发算进来检测不到间隔。先框单只眼睛区域。
> 沈清月实测: 眉毛带 y=[245,272], 眉眼间隔 y=[272,283], 眼睛带 y=[283,300]。
> 据此确定 HARD_CUT_TOP=280 左右(取间隔中间偏下)。

输出眉毛带 y 范围、眼睛带 y 范围、左右眼 x 中心，据此确定：
- `EYE_ROI = (x, y_眼区起点, w, h)`  —— y起点设在眉眼间隔处，避开眉毛
- `HARD_CUT_TOP = y_眼区起点`        —— 硬切线
- `MOUTH_ROI = (x, y, w, h)`         —— 嘴巴区域

### 步骤 3：Gemini 生成闭眼/张嘴变体（紫底 + 抠图）
```bash
GEMINI_API_KEY=xxx python3 tools/gen_blink_frames.py --char <role>
```
该脚本会：生成半闭眼/全闭眼紫底图 → 抠图 → 用 diff overlay（含眉毛硬切）生成 `eyes_half.png`/`eyes_closed.png`。
> Prompt 已含 8 条硬约束（DO NOT change eyebrows/forehead）。

### 步骤 4：用差分法生成最终 overlay（如需手动调参）
```bash
python3 .codebuddy/skills/portrait-blink-animation/scripts/gen_overlay.py \
  --base assets/cn/portraits/prologue_<role>.png \
  --variant assets/cn/portraits/anim_layers/<role>/blink_closed_clean.png \
  --output assets/cn/portraits/anim_layers/<role>/eyes_closed.png \
  --roi "320,280,300,45" --cut-top 280 --threshold 18 --feather 3.0
```

### 步骤 5：引擎接入
参考 `scripts/ui/DynamicPortraitTestV2.gd`，加载路径：
```gdscript
var base := "res://assets/cn/portraits/anim_layers/<role>/"
_tex_eyes_half   = load(base + "eyes_half.png")
_tex_eyes_closed = load(base + "eyes_closed.png")
_tex_mouth_open  = load(base + "mouth_layer.png")
```
所有层用 `_make_full_layer`（848×1264 全帧，相同锚点，`focus_mode=FOCUS_NONE` 防焦点框）。

### 步骤 6：验证
- 在 Godot 编辑器 F6 运行 `DynamicPortraitTestV2.tscn`，按 **B 键**触发眨眼
- 检查：眉毛不动、身体不动、只有眼睛闭合、无可见"圈"

## 参数速查（沈清月已验证，新角色需按步骤2重新定位）

| 参数 | 沈清月值 | 含义 |
|---|---|---|
| EYE_ROI | (320, 280, 300, 45) | 眼区差分范围，y起点避开眉毛 |
| HARD_CUT_TOP | 280 | 硬切线，y<此值强制透明 |
| MOUTH_ROI | (440, 372, 85, 46) | 嘴区差分范围 |
| threshold | 18 | RGB差异阈值，>此值才算变化 |
| feather | 3.0 | alpha羽化半径 |

## 产出文件结构
```
assets/cn/portraits/anim_layers/<role>/
  blink_half_clean.png      # Gemini半闭眼抠图(中间产物)
  blink_closed_clean.png    # Gemini全闭眼抠图(中间产物)
  talk_clean.png            # Gemini张嘴抠图(中间产物)
  eyes_half.png             # ★半闭眼 overlay(引擎用)
  eyes_closed.png           # ★全闭眼 overlay(引擎用)
  mouth_layer.png           # ★张嘴 overlay(引擎用)
  blink_frames.json         # 帧配置(记录ROI等参数)
```
