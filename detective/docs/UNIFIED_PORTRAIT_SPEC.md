# 统一立绘规范 v1.0

## 画布尺寸

所有角色立绘统一使用 **848×1264** 像素（宽:高 = 2:3）。

| 参数 | 值 | 说明 |
|------|-----|------|
| canvas_width | 848 | 固定 |
| canvas_height | 1264 | 固定 |
| aspect_ratio | 2:3 | Gemini 生成比例 |

## 角色占比

| 参数 | 值 | 说明 |
|------|-----|------|
| subject_height_ratio | 0.80 | 角色高度占画布高度的 80%（约 1011px） |
| top_margin | ~52px | 头顶到画布顶边的留白 |
| bottom_margin | ~64px | 膝盖下方到画布底边的留白 |
| side_padding | ~64px | 角色最左/最右到画布边缘的最小留白 |

## 截断位置

- **膝盖截断（Knee-up）**：角色从头顶显示到膝盖位置
- 膝盖线位于画布底部上方约 64px 处
- 不允许出现：仅胸部、腰部、臀部、大腿中段截断
- 不允许出现：全身像（露出脚/鞋）

## 头部位置

- 头顶位于画布顶部下方约 50-60px
- 眼线位于画布高度的 15%-18% 处（约 y=190-228px）
- 头宽约占画布宽度的 25%-30%

## 姿态要求

- 站姿为主，重心稳定
- 双手可见（至少一只手在画面内）
- 肩线水平或微侧，不超过 15° 倾斜
- 身体朝向：3/4 侧面或正面

## 背景

- 纯色背景用于抠图（绿色 #00FF00 或紫色 #FF00FF）
- 最终输出为透明背景 PNG

## 文件命名

```
prologue_{npc_id}_{emotion}.png
```

示例：
- `prologue_shen_qingyue.png`（基础表情）
- `prologue_shen_qingyue_bold.png`（bold 情绪）
- `prologue_lu_zhao.png`（主角基础）
- `prologue_lu_zhao_cold.png`（主角 cold 情绪）

## 当前问题

| 角色 | 当前尺寸 | 问题 |
|------|----------|------|
| agui | 848×1264 | ✓ 符合规范 |
| fisherman_wang | 832×1248 / 1024×1024 | ✗ 尺寸不统一，有方形图 |
| lao_fan | 848×1264 | ✓ 符合规范 |
| li_zheng | 603×900 | ✗ 尺寸偏小 |
| lu_zhao | 603×900 | ✗ 尺寸偏小 |
| shen_qingyue | 848×1264 | ✓ 符合规范 |
| zhou_demao | 848×1264 | ✓ 符合规范 |
| zhou_wife | 603×900 | ✗ 尺寸偏小 |

**需要重新生成的角色**：fisherman_wang、li_zheng、lu_zhao、zhou_wife

## Gemini 生成提示词模板

```
UNIFIED PORTRAIT SPEC:
- Canvas: exactly 848x1264 pixels, 2:3 aspect ratio.
- Character occupies exactly 80% of canvas height (~1011px).
- Knee-up framing: character from top of hair to knees.
- Top margin: ~52px above hair. Bottom margin: ~64px below knees.
- Side padding: at least 64px on each side.
- Head line at 15-18% of canvas height.
- Standing pose, 3/4 view or front view, weight on feet.
- No sitting, no kneeling, no crouching.
- No full body (no feet/shoes visible).
- No waist-up or bust crop.
- Transparent-ready silhouette with crisp edges.
```
