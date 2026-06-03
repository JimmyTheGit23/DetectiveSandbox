# 数据驱动写作与案件数据表设计

本文档归档“证据、对话、证词等数据抽离为数据表”的设计方案，并作为后续制作的总纲。

## 目标

- 编剧/策划维护 `CSV` 或表格源数据，不直接改 Godot 脚本。
- Godot 运行时直接读取 `data/case_tables/<case_id>/*.csv`，由 `CaseTableLoader.gd` 在内存中组装为既有系统需要的字典结构。
- `data/cases/<case_id>/*.json` 仅作为历史兼容/导出来源，不再是案件运行时主数据源。
- 通过校验器提前发现 ID 重复、引用不存在、对话跳转错误、证据无来源等问题。

## 工作流

```text
编剧填写 CSV / 表格
        ↓
tools/data_compiler/validate_case_tables.py 校验
        ↓
Godot 运行时 CaseTableLoader.gd 读取 CSV
        ↓
内存 Dictionary：locations_data / npcs_data / case_data / dialogues / companion / manifest ...
        ↓
既有 UI 与玩法系统继续消费这些 Dictionary
```

当前阶段已经改造运行时代码：案件索引、核心案件数据、对话、序章、尾声、助手、BGM/casting/表情映射均从 `data/case_tables/` 读取。`tools/data_compiler/compile_case.py` 保留为离线预览/兼容工具，不再是运行时必经步骤。

## 目录约定

```text
data/
  case_tables/
    case_index.csv
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
      json_docs.csv

  cases/
    prologue_ferry/
      *.json   # 历史数据/导出来源，不再作为案件运行时主数据源
```

`data/case_tables/` 是当前运行时主数据源；`data/cases/` 保留用于历史兼容、反向导出和人工比对。新增案件必须提供 `data/case_tables/<case_id>/`。

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

当前已覆盖：案件索引、角色、地点、搜索点、探索结果、证据、普通对话、对峙、证词、威慑、举证、击破、错证反馈、进度、NPC 状态、日程、凶手行动、表情立绘，以及 `json_docs.csv` 承载的 manifest/序章/尾声/助手/BGM 等复杂文档。

```text
case_index.csv                    → GameManager.case_index
json_docs.csv                     → manifest / prologue / epilogue_meta / companion / bgm_config / legacy base docs
characters.csv                    → npcs_data + casting
locations.csv                     → locations_data
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

## 迁移状态

1. `prologue_ferry`、`xunyang_pavilion`、`linchuan_inn` 均已具备 `data/case_tables/<case_id>/` 表格目录。
2. `data/case_tables/case_index.csv` 已替代 `data/cases/_index.json` 成为运行时案件索引。
3. `CaseTableLoader.gd` 在运行时直接读取 CSV，并组装为既有 UI/玩法代码使用的 Dictionary。
4. `tools/data_compiler/export_case_tables.py --all --index` 可从历史 JSON 重新导出 CSV；`compile_case.py` 仅保留为预览/兼容工具。

## 风险控制

- 复杂文档暂由 `json_docs.csv` 承载，保证运行时不再打开 `data/cases/<case_id>/*.json`。
- 后续可逐步把 `json_docs.csv` 中的 prologue、companion、bgm_config 等继续拆成更细的结构化表。
- 如果制作导出版，需要确认 Godot export preset 会包含 `data/case_tables/**/*.csv` 原始文件。
