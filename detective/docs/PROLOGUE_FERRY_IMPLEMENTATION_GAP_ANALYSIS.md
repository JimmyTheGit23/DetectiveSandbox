# 《渡口沉舟》序章优化版 — 实现差距分析

> 对照文档：`docs/PROLOGUE_FERRY_OPTIMIZED_FLOW.md`  
> 分析时间：2026-05-30

---

## 当前总体状态

数据表当前能通过校验：`validate_case_tables.py --case prologue_ferry` 为 `0 warning`。

但“能通过校验”不等于“流程符合最终设计”。当前最大问题是：

1. 船舱自由调查未真正接入序章流程。
2. 船沉后没有直接进入王大爷对峙。
3. 被指控后仍保留旧版自由调查/两天查案节奏。
4. 王大爷对峙仍偏向“玩家去凑证据解锁”，而不是“剧情直接进入，用已有事实反驳钱里正推理”。
5. 船舱阶段新增了独立 NPC ID，但 `locations.csv` 仍指向旧 NPC ID，存在接入不一致。

---

## 已完成项

| 模块 | 状态 | 说明 |
|---|---:|---|
| 设计文档归档 | ✅ | 已归档到 `docs/PROLOGUE_FERRY_OPTIMIZED_FLOW.md` |
| `confrontation_wang` 数据 | ✅ | `confrontations.csv` 已新增 |
| 王大爷证词集 | ✅ | `testimony_sets.csv` 已新增 `testimony_wang_self` |
| 王大爷证词 | ✅ | `testimony_statements.csv` 已新增 `wang_s1`/`wang_s2`/`wang_s3` |
| 王大爷击破台词 | ✅ | `testimony_break_lines.csv` 已新增对应击破对话 |
| 船底破洞证据 | ✅ | `evidence_hull_hole` 已存在 |
| 逃生时间证据 | ✅ | `evidence_cabin_escape_time` 已存在 |
| 章节结尾文本 | ✅ | `prologue_lines.csv` 已有 `chapter_end_seal`/`chapter_end_uniform`/`chapter_end_resolve` |
| 场景资源画风处理 | ✅ | 重新确认优先复用项目内已有场景图；过写实生成图已清理 |
| 官印/官服道具 | ✅ | 已重新基于项目内参考生成到 `assets/ai_processed/props/` |
| 表格校验 | ✅ | 当前 `validate_case_tables.py --case prologue_ferry` 为 0 warning |

---

## 未完成 / 需要继续做

### 1. 船舱开场没有真正接入流程

**问题**：

`prologue_lines.csv` 中已新增：

- `cabin_prologue_1`
- `cabin_prologue_2`
- `cabin_prologue_3`
- `cabin_free_explore`

但 `prologue_nodes.csv` 当前开头仍是：

```csv
opening_monologue_1 -> opening_monologue_2 -> opening_monologue_3 -> opening_monologue_4 -> time_card_opening -> cabin_1
```

也就是说，新增的 `cabin_prologue_*` 和 `cabin_free_explore` 还没有进入实际播放链路。

**需要做**：

- 将序章起点改为 `cabin_prologue_1`，或把 `cabin_prologue_*` 接入旧 `opening_monologue_*` 之前/之后。
- 明确 `cabin_free_explore` 之后如何进入船舱自由调查。

---

### 2. 船舱自由调查未真正可玩

**问题**：

已新增船舱阶段 NPC：

- `agui_cabin`
- `lao_fan_cabin`
- `zhou_de_gui_cabin`

但 `locations.csv` 的 `ferry_cabin` 仍写的是：

```csv
agui;lao_fan;zhou_de_gui
```

其中：

- `agui` 和 `lao_fan` 是旧调查阶段 NPC，会进入案发后的对话树。
- `zhou_de_gui` 并不是 `characters.csv` 中的有效 NPC ID；有效的是 `victim_zhou_demao` 和新增的 `zhou_de_gui_cabin`。

**需要做**：

- 将 `ferry_cabin` 的 NPC 列表改为：

```csv
agui_cabin;lao_fan_cabin;zhou_de_gui_cabin
```

- 确认引擎是否允许 `phase_0` 进入自由地图/地点探索。
- 增加“船舱调查结束”机制，例如 `cabin_explore_done` flag 或一个“休息/入睡”选项，触发沉船剧情。

---

### 3. 船沉后没有直接进入王大爷对峙

**问题**：

当前 `prologue_nodes.csv` 在被指控后结束到：

```csv
day2_start_game,end=true
```

这会进入旧版自由调查节奏，而不是直接 `auto_start_confrontation: confrontation_wang`。

`day_events.csv` 目前只是设置 `accused_of_murder`：

```json
{"set_flag": ["accused_of_murder"]}
```

没有自动触发 `confrontation_wang`。

**需要做**：

- 在被指控剧情末尾或 `evt_accused_of_murder` 中加入自动启动：

```json
{"auto_start_confrontation": "confrontation_wang"}
```

- 或在 `prologue_nodes.csv` 中从 `day2_lizheng_5b` 后直接进入对峙触发节点。

---

### 4. 王大爷对峙的解锁条件不符合“直接对峙”设计

**问题**：

`progression_unlocks.csv` 当前要求：

```json
all: [
  evidence_hull_hole,
  evidence_cabin_escape_time,
  evidence_lingyao_identity
]
```

这意味着玩家需要先获得多个证据才能解锁王大爷对峙。与“船沉后直接进入王大爷对峙”的设计不一致。

另外，`evidence_cabin_escape_time` 当前只在 `evidence_items.csv` 中定义，没有在 `prologue_lines.csv`/`prologue_nodes.csv` 的流程里明确 `gain_evidence`。

**需要做**：

- 若采用“剧情直接对峙”，应移除或弱化 `confrontation_wang` 解锁条件。
- 在凌瑶辩护台词处自动授予：

```text
gain_evidence:evidence_cabin_escape_time
```

- 船底破洞可在船沉时自动获得：当前 `prologue_lines.csv` 已写 `gain_evidence:evidence_hull_hole`，但还需确认该 node 已被 `prologue_nodes.csv` 正确播放。

---

### 5. 王大爷证词还不够“纯事实陈述”

**问题**：

当前 `testimony_statements.csv` 中：

```text
手里还攥着个铁家伙。我当时以为是什么随身物件。现在想来……那不会是凶器吧？
上岸后，有位姑娘跑过来'接应'。这也太巧了吧？
```

这两句已经带有推断和暗示，不是纯事实陈述。

**需要做**：

改成更中性的事实表达，例如：

```text
那人右手垂在身侧，像攥着一件长条形的东西。我离得远，看不清是什么。
后来有个年轻姑娘从岸边跑过去，扶住了那个人。我只看到这些。
```

把“凶器”“接应”“太巧了”这类推理交给钱里正说。

---

### 6. 钱里正的错误推理在对峙开场中不够明确

**问题**：

`confrontation_lines.csv` 当前 `confrontation_wang` 开场是让王大爷重复证词，然后直接问陆昭“有什么证据反驳”。

缺少关键设计点：

> 钱里正把阿贵证词、王大爷证词、凌瑶出现这三件事串起来，推理主角是凶手。

**需要做**：

在 `confrontation_wang` 开场中新增钱里正推理段：

```text
阿贵说你蹲在船底舱口，手里有铁器。
王大爷说船沉后一刻钟内有人爬上岸。
凌瑶又正好在岸边把你带走。
陆大人，这三件事连起来，你让我怎么信你不是凶手？
```

---

### 7. `dialogue_lines.csv` 中周德茂船舱台词字段异常

**问题**：

当前 `dialogue_lines.csv` 末尾的周德茂船舱台词有多行类似：

```csv
zhou_de_gui_cabin,ask_business,1,zhou_de_gui_c不算大。就是混口饭吃。,serious,,,,,,
```

这会把 `zhou_de_gui_c不算大。就是混口饭吃。` 当作 `speaker_id`，而不是文本。

虽然校验脚本没有报错，但运行时对话内容很可能显示异常或为空。

**需要做**：

改为标准格式：

```csv
zhou_de_gui_cabin,ask_business,1,zhou_de_gui_cabin,,,不算大。就是混口饭吃。,serious,,,,,,
```

并统一修正 `ask_business`、`ask_night_ferry`、`ask_servant` 相关行。

---

### 8. `case_partially_resolved` 的触发条件可能过早

**问题**：

`day_events.csv` 当前：

```json
evt_case_partially_resolved trigger = { flag: shen_confrontation_triggered }
```

这可能在沈清月对峙刚触发时就设置 `case_partially_resolved`，而不是对峙结束、伪证转折完成后才设置。

**需要做**：

确认对峙胜利/结尾实际产生的 flag。如果有 `confrontation_final_completed` 或类似 flag，应改成对峙完成后触发。

---

### 9. 章节结尾文本存在，但未接入实际播放链

**问题**：

`prologue_lines.csv` 有：

- `chapter_end_seal`
- `chapter_end_uniform`
- `chapter_end_resolve`

但当前未看到 `prologue_nodes.csv` 中有对应 node，也未看到 `day_events.csv` 自动播放这些节点。

**需要做**：

- 在 `prologue_nodes.csv` 添加章节结尾节点链。
- 在 `evt_chapter_end` 中触发该结尾剧情，或确认现有系统如何通过 day event 播放 prologue node。

---

## 优先级建议

### P0：先修流程阻塞

1. 接入 `cabin_prologue_*` 和 `cabin_free_explore`。
2. 修正 `ferry_cabin` NPC 列表。
3. 增加船舱调查结束进入沉船的触发。
4. 被指控后自动触发 `confrontation_wang`。
5. 修正 `evidence_cabin_escape_time` 的实际获得时机。

### P1：修叙事一致性

1. 王大爷证词改为纯事实陈述。
2. 钱里正补足错误推理台词。
3. `confrontation_wang` 解锁条件改为直接触发逻辑。

### P2：修数据质量和后续收束

1. 修正周德茂船舱台词 CSV 字段异常。
2. 修正 `case_partially_resolved` 触发条件。
3. 接入章节结尾节点。
4. 重新 validate + compile。

---

## 下一步建议执行顺序

1. 先修船舱阶段接入：`prologue_nodes.csv`、`locations.csv`、`dialogue_lines.csv`。
2. 再修被指控后直接对峙：`day_events.csv`、`progression_unlocks.csv`、`confrontation_lines.csv`。
3. 然后修王大爷证词和钱里正推理：`testimony_statements.csv`、`testimony_break_lines.csv`、`confrontation_lines.csv`。
4. 最后修章节结尾接入和事件 flag：`prologue_nodes.csv`、`day_events.csv`。
5. 运行验证和编译。
