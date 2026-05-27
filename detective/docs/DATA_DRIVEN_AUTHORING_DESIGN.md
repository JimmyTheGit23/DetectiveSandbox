# 数据驱动写作与案件数据表设计

本文档归档“证据、对话、证词等数据抽离为数据表”的设计方案，并作为后续制作的总纲。

## 目标

- 编剧/策划维护 `CSV` 或表格源数据，不直接改 Godot 脚本。
- 运行时继续读取 `data/cases/<case_id>/*.json`，降低重构风险。
- 通过编译器把 `data/case_tables/<case_id>/*.csv` 转成运行时 JSON。
- 通过校验器提前发现 ID 重复、引用不存在、对话跳转错误、证据无来源等问题。

## 工作流

```text
编剧填写 CSV / 表格
        ↓
tools/data_compiler/validate_case_tables.py 校验
        ↓
tools/data_compiler/compile_case.py 编译
        ↓
data/cases/<case_id>/*.json
        ↓
Godot 运行时读取
```

第一阶段不改运行时代码，只新增表格源数据、编译器和校验器。

## 目录约定

```text
data/
  case_tables/
    prologue_ferry/
      characters.csv
      locations.csv
      location_links.csv
      search_points.csv
      search_results.csv
      search_sub_choices.csv
      evidence_items.csv
      dialogue_nodes.csv
      dialogue_lines.csv
      dialogue_options.csv

  cases/
    prologue_ferry/
      casting.json
      npcs.json
      locations.json
      evidence.json
      search_results.json
      case.json
      dialogues/
        agui.json
        fisherman_wang.json
```

`data/case_tables/` 是人工维护源数据；`data/cases/` 是运行时数据。短期内允许继续人工维护运行时 JSON，但最终以表格源数据为准。

## ID 命名规范

| 类型 | 格式 | 示例 |
|---|---|---|
| 案件 | 小写英文 + 下划线 | `prologue_ferry` |
| NPC | 角色英文短名 | `agui`, `lao_fan` |
| 证据 | `evidence_核心名` | `evidence_hull_hole` |
| 线索 | `clue_核心名` | `clue_fan_alibi_hole` |
| 地点 | 地点英文短名 | `ferry_dock` |
| 搜索点 | 表内拆成 `location_id` + `point_id` | `ferry_dock.dock_body_examine` |
| 对话节点 | `hub` / `ask_xxx` / `challenge_xxx` | `ask_channel` |
| 证词 | `testimony_证人或阶段` | `testimony_wang` |
| 证词语句 | `证词短名_序号` | `wang_3` |

## 已支持表格

当前已覆盖：角色、地点、搜索点、探索结果、证据、普通对话、对峙、证词、威慑、举证、击破、错证反馈。

```text
characters.csv                    → npcs.json + casting.json
locations.csv                     → locations.json
location_links.csv                → locations.json.sub_locations
search_points.csv                 → locations.json.search_points
evidence_items.csv                → evidence.json
search_results.csv                → search_results.json
search_sub_choices.csv            → search_results.json.sub_choices
dialogue_nodes.csv                → dialogues/<npc_id>.json
dialogue_lines.csv                → dialogues/<npc_id>.json nodes[].lines
dialogue_options.csv              → dialogues/<npc_id>.json nodes[].options
confrontations.csv                → case.json confrontation entries
confrontation_lines.csv           → intro/victory/defeat/epilogue
testimony_sets.csv                → confrontation.testimonies[]
testimony_lines.csv               → preamble/readthrough/fail/transition
testimony_statements.csv          → testimony.statements[]
testimony_press_lines.csv         → statement.press[]
testimony_break_lines.csv         → statement.break_dialogue[]
testimony_wrong_reactions.csv     → statement.wrong_reactions
progression_phases.csv            → progression.json phases[]
progression_unlocks.csv           → panel/search_point/npc/confrontation unlock
phase_notifications.csv           → progression.json phase_notifications
npc_state_initial.csv             → npc_states.json initial
npc_state_transitions.csv         → npc_states.json transitions
day_events.csv                    → day_events.json events[]
day_event_lines.csv               → day_events.json events[].narration
schedule_defaults.csv             → schedules.json default
schedule_overrides.csv            → schedules.json overrides
schedule_conditional_overrides.csv → schedules.json conditional_overrides
culprit_actions.csv               → culprit_actions.json actions[]
portrait_expressions.csv          → portrait_expressions.json portraits
```

## 条件 DSL

表格中的 `requires`、`when` 可写简化条件：

```text
flag:wang_talked_once
evidence:evidence_hull_hole
clue:clue_fan_alibi_hole
visited:lao_fan.ask_rescue
not(flag:agui_confessed)
all(evidence:evidence_hull_hole, clue:clue_agui_dry_inner)
any(evidence:evidence_wrong_channel, clue:clue_reef_common_knowledge)
state(agui.defense>=3)
day>=2
period>=5
```

也可以直接填写 JSON 条件，例如：

```json
{"all":[{"flag":"hull_sabotage_known"},{"flag":"agui_motive_known"}]}
```

## 效果字段

第一阶段保持现有运行时字段，避免改 `DialogueManager` / `GameManager`：

- `set_flags`：逗号或分号分隔。
- `gain_evidence`：获得证据 ID。
- `gain_clue`：获得线索 ID。
- `trigger_confrontation`：是否触发对峙。
- `confrontation_key`：对峙键名。

## 迁移计划

1. 归档本设计文档。
2. 新增 `tools/data_compiler/` 工具链。
3. 从现有 `data/cases/prologue_ferry/` 反向导出第一批 CSV。
4. 校验 CSV。
5. 编译到预览目录，与现有 JSON 做差异对比。
6. 稳定后再允许 `--write-runtime` 写回 `data/cases/`。

## 风险控制

- 编译器默认输出到 `data/case_tables/<case_id>/_compiled/`，不会直接覆盖运行时数据。
- 只有显式传入 `--write-runtime` 才写回 `data/cases/<case_id>/`。
- 校验器允许增量迁移：没有表格的模块继续使用现有 JSON。
