# 序章音乐增强建议

## 概述

分析序章中哪些场景增加音乐会更好，提升整体氛围和情感体验。

---

## 1. 当前音乐覆盖分析

### 1.1 已有音乐的场景

| 场景 | 音乐 | 效果 |
|------|------|------|
| 船舱恐慌 | `ferry_prologue_escape` | ✅ 紧张感强 |
| 岸边救援 | `ferry_prologue_shore` | ✅ 劫后余生 |
| 客栈调查 | `ferry_inn_investigation` | ✅ 安静调查 |
| 码头调查 | `ferry_dock_investigation` | ✅ 阴冷氛围 |
| 指认紧张 | `accuse_tension` | ✅ 高潮紧张 |
| 阿贵对峙 | `ferry_confrontation` | ✅ 对峙激烈 |
| 法庭开场 | `ferry_court_opening` | ✅ 庄重肃穆 |

### 1.2 缺少音乐的场景

| 场景 | 当前状态 | 建议音乐 | 优先级 |
|------|---------|---------|--------|
| 开场独白 | 无音乐 | 可选：轻柔主题曲 | 低 |
| 沉船逃生中间 | 只有音效 | 继续 `ferry_prologue_escape` | 中 |
| 周氏下跪 | 无音乐 | 新增：悲伤主题 | 高 |
| 阿贵指认 | 无音乐 | 新增：紧张对峙 | 高 |
| 里正调解 | 无音乐 | 新增：庄重调解 | 中 |
| 决心调查 | 无音乐 | 新增：坚定主题 | 中 |
| 沈清月对峙 | 配置可能有问题 | 修复配置 | 高 |

---

## 2. 详细增强建议

### 2.1 周氏下跪场景（高优先级）

**当前：** `day2_body_5` 和 `day2_zhou_1` 没有音乐

**场景描述：** 周氏在丈夫尸体前下跪哭泣，是情感爆发点

**建议：**
```csv
day2_body_5,,res://assets/cn/scenes/prologue_cg_zhou_kneel.png,day2_zhou_1,,,,,"{""sfx"": ""crowd_murmur"", ""bg_offset_y"": -100, ""bgm"": ""grief_theme""}"
```

**新增音乐需求：**
- **音乐ID：** `grief_theme`
- **风格：** 悲伤、哀婉、二胡/古琴
- **节奏：** 慢
- **情绪：** 悲痛、绝望、失去

### 2.2 阿贵指认场景（高优先级）

**当前：** `day2_agui_appears` 到 `day2_agui_2b` 没有持续音乐

**场景描述：** 阿贵突然指认陆昭是凶手，场面紧张

**建议：**
```csv
day2_agui_appears,,res://assets/cn/scenes/prologue_ferry_dock.png,day2_agui_1,,,,,"{""bgm"": ""accuse_tension""}"
```

**效果：** 复用已有的 `accuse_tension`，营造紧张氛围

### 2.3 里正调解场景（中优先级）

**当前：** `day2_lizheng_appear` 到 `day2_lizheng_5b` 没有音乐

**场景描述：** 钱里正出现，试图调解局面

**建议：**
```csv
day2_lizheng_appear,,res://assets/cn/scenes/prologue_ferry_dock.png,day2_lizheng_1,,,,,"{""bgm"": ""authority_theme""}"
```

**新增音乐需求：**
- **音乐ID：** `authority_theme`
- **风格：** 庄重、官方、调解
- **节奏：** 中等
- **情绪：** 权威、调解、稳定

### 2.4 决心调查场景（中优先级）

**当前：** `day2_framed_resolve` 之后没有专属音乐

**场景描述：** 陆昭决心查明真相，凌瑶加入

**建议：**
```csv
day2_framed_resolve,,,day2_framed_resolve_b,,,,,"{""bgm"": ""resolve_theme""}"
```

**新增音乐需求：**
- **音乐ID：** `resolve_theme`
- **风格：** 坚定、决心、希望
- **节奏：** 中等偏快
- **情绪：** 决心、希望、正义

### 2.5 沈清月对峙配置修复（高优先级）

**当前配置：**
```csv
confrontation_final,shen_qingyue,true,,accuse,pursuit,cornered,10
```

**问题：** `accuse`、`pursuit`、`cornered` 可能不是有效的 track_id

**建议修复：**
```csv
confrontation_final,shen_qingyue,true,,ferry_confrontation,ferry_court_opening,confrontation_final,10
```

**或者新增专属音乐：**
- **音乐ID：** `shen_confrontation`
- **风格：** 冷冽、危险、优雅
- **节奏：** 慢-快渐进
- **情绪：** 智慧对决、心理博弈

---

## 3. 新增音乐清单

### 3.1 高优先级（建议新增）

| 音乐ID | 用途 | 风格 | 时长 |
|--------|------|------|------|
| `grief_theme` | 周氏下跪 | 悲伤、哀婉 | 2-3分钟 |
| `shen_confrontation` | 沈清月对峙 | 冷冽、危险 | 3-4分钟 |

### 3.2 中优先级（可选新增）

| 音乐ID | 用途 | 风格 | 时长 |
|--------|------|------|------|
| `authority_theme` | 里正调解 | 庄重、官方 | 2分钟 |
| `resolve_theme` | 决心调查 | 坚定、希望 | 2分钟 |

### 3.3 低优先级（可选）

| 音乐ID | 用途 | 风格 | 时长 |
|--------|------|------|------|
| `opening_theme` | 开场独白 | 神秘、引人入胜 | 1-2分钟 |

---

## 4. 音乐配置修改

### 4.1 prologue_nodes.csv 修改

**周氏下跪场景：**
```csv
day2_body_5,,res://assets/cn/scenes/prologue_cg_zhou_kneel.png,day2_zhou_1,,,,,"{""sfx"": ""crowd_murmur"", ""bg_offset_y"": -100, ""bgm"": ""grief_theme""}"
```

**阿贵指认场景：**
```csv
day2_agui_appears,,res://assets/cn/scenes/prologue_ferry_dock.png,day2_agui_1,,,,,"{""bgm"": ""accuse_tension""}"
```

**里正调解场景：**
```csv
day2_lizheng_appear,,res://assets/cn/scenes/prologue_ferry_dock.png,day2_lizheng_1,,,,,"{""bgm"": ""authority_theme""}"
```

**决心调查场景：**
```csv
day2_framed_resolve,,,day2_framed_resolve_b,,,,,"{""bgm"": ""resolve_theme""}"
```

### 4.2 confrontations.csv 修改

**沈清月对峙配置修复：**
```csv
confrontation_final,shen_qingyue,true,,ferry_confrontation,ferry_court_opening,confrontation_final,10,第二阶段对峙：沈清月（FINAL BOSS）。击破阿贵后进入。难度更高——她用逻辑防御而非哭诉。
```

---

## 5. 音乐生成建议

### 5.1 使用 AI 生成音乐

可以使用 Suno AI 或其他音乐生成工具创建新音乐：

**grief_theme 提示词：**
```
中国传统悲伤音乐，二胡独奏，古琴伴奏，慢节奏，哀婉动人，
适合丧亲场景，表达悲痛和绝望，明代风格，约2分钟
```

**shen_confrontation 提示词：**
```
紧张对峙音乐，琵琶急奏，古琴低音，节奏渐快，
冷冽危险氛围，智慧对决感，约3-4分钟
```

**authority_theme 提示词：**
```
庄重官方音乐，编钟点缀，古筝稳重，中等节奏，
权威调解氛围，约2分钟
```

**resolve_theme 提示词：**
```
坚定决心音乐，鼓点渐强，笛声悠扬，中等偏快节奏，
正义希望感，约2分钟
```

### 5.2 复用现有音乐

**可复用的音乐：**
- `accuse_tension` → 阿贵指认场景
- `ferry_dock_investigation` → 里正调解（降低音量）
- `main_theme` → 决心调查（变奏）

---

## 6. 实施步骤

### 步骤 1：修复沈清月对峙配置（立即）

```bash
# 修改 confrontations.csv
# 将 accuse,pursuit,cornered 改为有效的 track_id
```

### 步骤 2：为周氏下跪添加音乐（高优先级）

```bash
# 生成 grief_theme 音乐
# 修改 prologue_nodes.csv
# 编译测试
```

### 步骤 3：为阿贵指认添加音乐（高优先级）

```bash
# 复用 accuse_tension
# 修改 prologue_nodes.csv
# 编译测试
```

### 步骤 4：生成其他音乐（中优先级）

```bash
# 生成 authority_theme
# 生成 resolve_theme
# 修改配置
# 编译测试
```

---

## 7. 预期效果

### 7.1 情感曲线增强

**当前：**
```
开场(寂静) → 沉船(紧张) → 获救(舒缓) → 调查(安静) → 发现尸体(紧张) → 对峙(激烈) → 结局
```

**增强后：**
```
开场(寂静) → 沉船(紧张) → 获救(舒缓) → 调查(安静) → 发现尸体(紧张) → 周氏下跪(悲伤) → 指认(紧张) → 调解(庄重) → 决心(坚定) → 对峙(激烈) → 结局
```

### 7.2 沉浸感提升

- 周氏下跪场景增加悲伤音乐，增强情感冲击
- 阿贵指认场景增加紧张音乐，增强戏剧张力
- 沈清月对峙使用专属音乐，突出最终BOSS地位

---

## 8. 总结

### 8.1 优先级排序

| 优先级 | 场景 | 建议 |
|--------|------|------|
| 高 | 沈清月对峙配置 | 修复配置或新增音乐 |
| 高 | 周氏下跪 | 新增 `grief_theme` |
| 高 | 阿贵指认 | 复用 `accuse_tension` |
| 中 | 里正调解 | 新增 `authority_theme` |
| 中 | 决心调查 | 新增 `resolve_theme` |
| 低 | 开场独白 | 可选新增 |

### 8.2 工作量估算

- 修复配置：15分钟
- 新增1首音乐（AI生成）：30分钟
- 修改CSV并测试：30分钟

**总计：约2-3小时（完成所有增强）**

---

*文档版本：1.0*
*最后更新：2026-05-30*