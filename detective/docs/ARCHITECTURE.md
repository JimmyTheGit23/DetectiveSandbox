# 游戏框架三层架构（2026-07-23 重构）

## 分层总览

```
Layer 1  流程骨架层（冻结，不改）     scripts/core/flow/FlowRunner.gd
Layer 2  钩子骨架层（持续追加钩子点）  scripts/core/hooks/HookBus.gd
Layer 3  内容执行层（纯数据/效果）     scripts/core/effects/EffectRegistry.gd
                                      + data/case_tables/*/  (CSV + json_docs)
```

- **Layer 1**：大阶段状态机。定义"什么是大阶段"（search/event/confrontation/ending…），
  驱动 `阶段进入 → 钩子 → 转移条件求值 → 下一阶段`。不认识任何案件内容。
- **Layer 2**：统一事件订阅中心。新机制 = 加新钩子点 + 注册新订阅，不改框架。
- **Layer 3**：所有"内容效果"的唯一执行点 + 全部案件数据（CSV/json_docs）。

数据流向：内容数据（CSV）→ CaseTableLoader 编译 → GameManager 状态 →
mutator 发钩子（HookBus）→ 订阅者响应（day_events / progression / FlowRunner）→
效果落库（EffectRegistry）。

## Layer 2 内置钩子清单（HookBus 常量，新机制在此追加）

| 钩子 | payload | 说明 |
|---|---|---|
| `flag.set` | {flag_id} | flag 设置（订阅：day_events(20)、progression(10)、FlowRunner(5)） |
| `evidence.added` | {evidence_id} | 获得证据（同上） |
| `clue.added` | {clue_id} | 获得线索（同上） |
| `location.changed` | {location_id} | 地点切换（订阅：day_events） |
| `node.visited` | {npc_id, node_id} | 对话节点访问（订阅：day_events） |
| `npc_state.changed` | {npc_id, stat, value} | NPC 状态机数值变化 |
| `time.advanced` | {day, period} | 预留 |
| `flow.started` / `flow.finished` | {flow_id} | 流程起止 |
| `phase.entering/entered/exiting` | {phase_id, phase_type} | 大阶段生命周期 |
| `search.resolved` | {location_id, point_id, result} | 搜查完成 |
| `dialogue.ended` | {npc_id} | 对话结束 |
| `option.chosen` | {npc_id, node_id, option_index} | 选项选择 |
| `confrontation.finished` | {confront_key, result, mistakes} | 对峙结束 |
| `save.loaded` | {} | 读档完成 |
| `case.switched` | {case_id} | 案件切换 |

订阅：`HookBus.subscribe(name, callable, priority)`，priority 大者先执行，同步调用。
检查链优先级约定：day_events=20，progression=10，FlowRunner=5。

## Layer 3 内置效果（EffectRegistry，新机制 register_effect 追加）

执行顺序固定（与旧行为一致）：`set_flag → gain_clue → auto_done_flag → gain_evidence → unlock_phase → change_location`，
自定义效果在其后按字典序执行。

- `set_flag` / `gain_clue` / `gain_evidence`：string | array；gain_evidence 支持 context.hold_obtain_display
- `unlock_phase`：阶段解锁
- `change_location`：切地点（advance=false）
- `auto_done_flag`：事件完成自动落 `<id>_done`
- 自定义：`EffectRegistry.register_effect("my_fx", func(value, ctx): ...)`

调用：`EffectRegistry.apply_effects(effects_dict, context)`。
GameManager.apply_event_effects / DialogueManager._apply_narration_effects /
CompanionService._apply_banter_effects 均为薄封装。

## Layer 1 flow 数据格式（json_docs.csv，doc_id="flow"）

```jsonc
{
  "start": "cabin",
  "phases": [
    {"id": "cabin", "type": "search",
     "next_when": {"flag": "cabin_phase_done"},  // 转移条件（evaluate_condition 口径）
     "next": "accused",
     "enter_effects": {"set_flag": "..."}        // 可选
    }
  ],
  "confrontation_routes": {
    "confrontation_wang": {
      "match_suspect": "agui",             // 可选：suspect 匹配才生效
      "victory_flags": ["..."],            // 胜利 flags（<key>_completed 之前设置）
      "final_flags": ["..."],              // final 对峙结束无论胜败都设置
      "ending_override": "prologue_fixed", // final 结局覆盖
      "victory_buffer": [{"speaker":..,"text":..,"emotion":..}],  // 胜利缓冲台词
      "victory_event": "evt_x",            // 胜利后单事件
      "victory_event_chain": ["evt_a","evt_b"]  // 胜利后事件链
    }
  },
  "resume_markers": {                       // 读档恢复阶段判断（任一命中）
    "any_flags": ["cabin_phase_done"], "any_clues": ["clue_travel_notes"]
  },
  "forced_confrontation": {                 // 强制对峙（教学对峙）
    "confront_key": "confrontation_wang",
    "when": {"all": [{"flag": "accused_of_murder"}, {"not": {"flag": "confrontation_wang_completed"}}]},
    "location": "ferry_inn"
  }
}
```

阶段类型常量：`PHASE_PROLOGUE / SEARCH / EVENT / CONFRONTATION / ACCUSATION / ENDING`。
读档后阶段不入档：FlowRunner 从 start 按已存 flag 快进推导（幂等）。
`FlowRunner.has_flow()` = 本案件是否走线性流程路由（替代原 `ACTIVE_CASE == "prologue_ferry"` 硬编码）。

## 条件求值单一口径（GameManager.evaluate_condition）

唯一求值器（CompanionService 第二套已删，仅保留 default 短路薄封装）。支持键：
`flag / not_flag / has_flag`（别名）、`evidence / clue / has_evidence / has_clue`（别名）、
`evidence_count_gte / clue_count_gte / evidence_ratio_gte`、
`visited`（npc.node 两段 / 地点单段）、`not_visited`、`location / location_unlocked`、
`npc_location / npc_activity`、`state`（npc.stat + lt/lte/gt/gte/eq）、
`day / day_gte / day_lte`（剧情日，见下）、`total_periods_used_gte`、
`not / all / any`。

## 剧情日机制（序章为准，无时段消耗制）

- 时间 = 叙事标签，由 `time_progression.csv` 的 flag→day/时辰 映射驱动。
- `GameManager.get_story_day()`：第一个 trigger 满足的行决定剧情日（带防递归保护）。
- `GameManager.get_total_days()`：time_progression 最大 day。
- `day / day_gte / day_lte` 条件、CompanionService 每日限流，全部按剧情日。
- `get_current_time_label()` 的 era_prefix 从 `manifest.subtitle` 推导。

## 其他数据化迁移（P4）

| 原硬编码 | 现数据位置 |
|---|---|
| MainGame GM_PRESETS / 预设映射 | json_docs `gm_presets` → GameManager.gm_presets_data |
| CompanionService banter 序章特判 | companion_config.csv `banter_suppress_until_flag` |
| _play_event_now 沉船特判 | 删除（day_events effects 已含全部字段） |
| get_current_time_label era_prefix | manifest.subtitle 推导 |
| BgmPlayer BGM_MAP | 删除（各案 bgm_config 全覆盖；未覆盖 id 按"id 即曲目名"回退） |
| MapPanel 坐标/地图图 | json_docs `map_config` → GameManager.map_config_data |
| ConfrontationPanel 判决大字 | confrontations.csv `verdict_text` 列 |
| AssetResolver 立绘缩放/支点 | portrait_expressions.csv `screen_scale` / `pivot_y` 列 |
| GameManager._repair_loaded_save_state | 保留（旧存档迁移代码，仅 prologue_ferry） |

## 已知遗留（不属本次范围）

- 临川驿案 `total_periods_used_gte` 伪时间（搜索次数累计）仍在使用；序章流程不依赖。
- `evt_lizheng_pressure`（序章 day_gte:2 + not agui_confessed_mastermind）在剧情日语义下仍不触发（与旧行为一致）。
- tools/ 下 3 个脚本预存编译错误（SfxGenerator.gd / dialogue_path_tester.gd / runtime_check.gd），与本框架无关。

## 编辑器注意事项

- 新增 autoload 后，运行中的编辑器需重启才能让 GDScript 编译器识别新标识符
  （headless/导出运行时无此问题，autoload 从 project.godot 全新加载）。
- 编辑器内 execute_editor_script 访问不到游戏 autoload 实例；验证请用 headless 测试场景。
