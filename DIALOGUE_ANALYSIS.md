# 阿贵对话文件分析 (Agui Dialogue Analysis)

**生成日期**: 2026-05-21
**案件**: 序章「渡口沉舟」(Prologue: Ferry Wreck)
**文件位置**: `detective/data/cases/prologue_ferry/dialogues/agui.json`

---

## 1. 核心问题点

### 问题1: "小的想说实话" 的逻辑矛盾
**位置**: `agui.json` → `show_bladder` 节点 (第206行)

```json
{
  "speaker_id": "agui",
  "text": "大人。小的想说实话。"
}
```

**分析**:
- 这句话出现在发现**浮囊证据**之后
- 按剧本逻辑，阿贵应该是逐步被质证、露出马脚的主犯，而非主动认罪者
- 当前效果: 让玩家觉得"真凶想认罪了"，而非"真凶被抓住了"
- 理想效果: 应该表现为被逼得无法狡辩，而非主动示弱

**建议修改**: 改为更具有防守姿态或被迫感的台词

---

## 2. 对峙系统 vs "指证"菜单的流程变更

### 当前系统架构 (从代码分析)

**agui.json 中的对峙触发** (第54-77行):
```json
{
  "text": "（对峙）证据够了。说实话吧。",
  "goto": "confession",
  "requires": {
    "all": [
      { "evidence": "evidence_hull_hole" },           // 船底凿痕
      { "evidence": "evidence_float_bladder" },       // 浮囊
      {
        "any": [
          { "evidence": "evidence_dismissal_note" },  // 遣散字据
          { "evidence": "evidence_gambling_iou" }     // 赌债字据
        ]
      }
    ]
  },
  "type": "confrontation"
}
```

**case.json 中的完整对峙流程** (第13-229行):
- 包含3个大证词环节 (testimony_1/2/3)
- 每个证词下有4-5个子陈述 (statements)
- 每个陈述可触发进一步的质证 (press)
- 包含"破局对话" (break_dialogue) - 当玩家用关键证据反驳时
- 包含胜利/失败分支:
  - **胜利**: 玩家成功指正所有矛盾 → 阿贵认罪
  - **失败**: 证据不足 → 阿贵狡辩成功

**新需求分析**:
✅ 已完成: 对峙系统已在 `case.json` 详细定义
✅ 已完成: 不再依赖单独的"指证"菜单选项
✅ 需要验证: 对话菜单中的"指证"是否已完全移除或标记为废弃

---

## 3. 对话内容分析

### 3.1 情感/表情字段使用情况

**✅ 已实装的 emotion 字段** (5处使用):

| 位置 | 角色 | 台词 | 情感 |
|------|------|------|------|
| intro:L89 | agui | 那天……那天夜里…… | `nervous` |
| intro:L94 | agui | 到了江心，突然船就晃… | `panic` |
| intro:L102 | agui | 小的只记得呛了好多水… | `nervous` |
| press_alibi:L145 | agui | 小的……小的也不知道… | `defensive` |
| press_alibi:L156 | xia_lingyao | 冬天的江水…… | `thinking` |

**❌ 缺失 emotion 字段的台词** (53处):

大量关键台词缺少情感标注，包括:
- `hub` 节点开场 (L6) - "大人……小的、小的实在是太害怕了"
- `ask_relationship` (L128) - 全段无标注
- `show_dismissal` (L175) - "二两银子……十二年……" 的沉重台词无标注
- `show_bladder` 的多个不同阶段 (L194, L198, L202, L206) - 从惊慌到沉默再到觉悟的过程无标注
- `confession` 全段 (L234-248) - 开始对峙的所有台词无标注

### 3.2 主角台词重复模式

**高频词汇分析**:

在 `case.json` 的对峙流程中:
- 主角使用"他无法解释"类型的评价约 8 次
- 主角使用"你……"的质疑句式约 12 次
- 重复的数据引用 ("二两银子"、"浮囊"、"破洞") 但表述机械

**例子**:
```json
{ "speaker": "你", "text": "那我们就从那晚说起。你把当时的情况，一句一句说清楚。" },
{ "speaker": "你", "text": "那好。一条一条过。你说的每一句话——我都有东西反驳。" }
```

**问题**: 两句都是"一句一句"和"一条一条"的重复表述

---

## 4. 人物肖像系统

### 4.1 阿贵的可用表情变体

**已生成的portraits** (共6个variant):
```
✅ prologue_agui.png                           (基础态)
✅ prologue_agui_collapsed.png                 (崩溃态)
✅ prologue_agui_shaken.png                    (惊吓态)
✅ prologue_agui_confrontation.png             (对峙_常态)
✅ prologue_agui_confrontation_collapsed.png   (对峙_崩溃)
✅ prologue_agui_confrontation_shaken.png      (对峙_惊吓)
```

**其他角色的variants**:
- lao_fan: 基础、collapsed、shaken (3个)
- zhou_wife: 基础 (1个)
- fisherman_wang: 基础 (1个)
- li_zheng: 基础 (1个)

### 4.2 Emotion 字段与肖像映射

**casting.json 现状**:
- 无 emotion/portrait 字段
- 仅记录 actor_id 映射
- npcs.json 中的 portrait 字段只有单一路径:
  ```json
  "portrait": "res://assets/cn/portraits/prologue_agui.png"
  ```

**需要扩展的字段**:
```json
"emotion_variants": {
  "default": "prologue_agui.png",
  "nervous": "prologue_agui.png",
  "panic": "prologue_agui_shaken.png",
  "defensive": "prologue_agui.png",
  "collapsed": "prologue_agui_collapsed.png",
  "confrontation_default": "prologue_agui_confrontation.png",
  "confrontation_collapsed": "prologue_agui_confrontation_collapsed.png",
  "confrontation_shaken": "prologue_agui_confrontation_shaken.png"
}
```

---

## 5. 文件结构总览

### case.json 的对峙部分 (confrontation 字段)

```
confrontation:
├─ suspect: "agui"
├─ intro_dialogue: [3条 intro 台词]
├─ testimonies[]: [3个大证词]
│  ├─ testimony_1: "那晚的行踪"
│  │  └─ statements[]: [4个陈述]
│  │     ├─ s1_1: 为何上船 (press + 反驳)
│  │     ├─ s1_2: 一直在舱里 (press + 进阶陈述 s1_2b)
│  │     │  └─ press_adds: [破局对话]
│  │     ├─ s1_3: 翻船过程 (press)
│  │     └─ s1_4: 上岸后 (press)
│  │
│  ├─ testimony_2: "沉船原因"
│  │  └─ statements[]: [4个陈述]
│  │     ├─ s2_1: 撞暗礁说 (press)
│  │     ├─ s2_2: 大破洞说 (press + 破局) ⭐ 关键证词
│  │     ├─ s2_3: 翻船常事 (press)
│  │     └─ s2_4: 我是受害者 (press)
│  │
│  └─ testimony_3: "主仆关系"
│     └─ statements[]: [4个陈述]
│        ├─ s3_1: 老爷对我不薄 (press)
│        ├─ s3_2: 遣散是体恤 (press + 破局) ⭐ 关键证词
│        ├─ s3_3: 心里有怨但不敢 (press)
│        └─ s3_4: 全是巧合 (press)
│
├─ victory_dialogue: [5条，最终认罪台词]
└─ defeat_dialogue: [3条，狡辩成功台词]
```

---

## 6. 当前"指证"菜单状态

### agui.json 中的 "指证" 选项

在 `hub` 节点的 options 数组中 (第54-77行):
```json
{
  "text": "（对峙）证据够了。说实话吧。",
  "goto": "confession",
  "requires": { ... },
  "type": "confrontation"
}
```

**状态分析**:
- ✅ 已经标记为 `type: "confrontation"` 而非单独的"指证"类型
- ✅ 触发条件明确 (三种证据组合)
- ✅ 跳转到 `confession` 节点后设置 `trigger_confrontation: true`
- ❓ 需要确认: UI 层是否正确处理这个 `type: "confrontation"` 来显示"对峙"按钮

---

## 7. 总体评估与建议

| 项目 | 状态 | 优先级 | 建议 |
|------|------|--------|------|
| 流程架构 | ✅ 完善 | - | case.json 的对峙系统设计完整 |
| "小的想说实话" 台词 | ❌ 逻辑矛盾 | 🔴 高 | 改为被逼无奈或沉默反应 |
| emotion 字段覆盖 | ⚠️ 部分覆盖 | 🟠 中 | 为所有关键台词补充 emotion |
| 肖像映射系统 | ⚠️ 缺失 | 🟠 中 | 在 casting.json 中定义 emotion→portrait 映射 |
| 主角台词机械感 | ⚠️ 待改进 | 🟡 低 | 逐个润色避免重复 |
| UI 集成 | ❓ 待验证 | - | 确认对峙菜单是否正确渲染 |

---

## 8. 附录: 完整代码统计

- **agui.json**: 257 行，7 个主要节点
- **case.json**: 314 行
  - confrontation 部分: 216 行 (L13-229)
  - 包含 3 个 testimony，共 13 个 statement
- **casting.json**: 50 行 (6个角色)
- **npcs.json**: 49 行 (6个角色)
- **肖像文件**: 6个 variant + 其他角色变体

