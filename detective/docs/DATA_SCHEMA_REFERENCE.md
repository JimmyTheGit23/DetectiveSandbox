# 案件数据表字段参考

本文档记录第一阶段已支持的 CSV 表结构。

## 通用写法

- 空单元格表示不输出该字段。
- 多值字段支持逗号或分号分隔，如 `flag_a,flag_b`。
- `requires` / `when` 支持条件 DSL，也支持直接填写 JSON。
- 路径字段保持 Godot `res://` 格式。

## `characters.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | 角色 ID |
| `name` | 是 | 显示名 |
| `title` | 否 | 身份 |
| `intro` | 否 | 卷宗介绍 |
| `dialogue_id` | 否 | 对话文件 ID，默认同 `npc_id` |
| `actor_id` | 否 | 演员资产 ID |
| `portrait` | 否 | 立绘路径 |
| `always_in_notebook` | 否 | 是否默认进卷宗 |
| `is_victim` | 否 | 是否死者 |
| `is_player` | 否 | 是否玩家角色 |
| `is_culprit` | 否 | 是否真凶 |

## `evidence_items.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `item_id` | 是 | 证据/线索 ID |
| `type` | 是 | `evidence` / `clue` / `testimony` / `record` |
| `name` | 是 | 名称 |
| `description` | 是 | 描述 |
| `category` | 否 | 分类 |
| `hidden` | 否 | 是否隐藏 |
| `meta_clue` | 否 | 是否元线索 |
| `icon` | 否 | 图标路径 |
| `tags` | 否 | 标签列表 |
| `phase` | 否 | 阶段 |
| `source` | 否 | 来源备注，仅供写作维护 |
| `writer_note` | 否 | 编剧备注，不进运行时 JSON |

## `locations.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `location_id` | 是 | 地点 ID |
| `name` | 是 | 地点名 |
| `parent` | 否 | 父地点 |
| `description` | 否 | 描述 |
| `unlock_phase` | 否 | 解锁阶段 |
| `background` | 否 | 背景图 |
| `scene_type` | 否 | 场景类型 |
| `npcs` | 否 | NPC 列表 |

## `location_links.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `from_location` | 是 | 当前地点 |
| `target_location` | 是 | 目标地点 |
| `name` | 是 | 按钮文本 |
| `description` | 否 | 描述 |
| `requires` | 否 | 条件 |
| `time_cost` | 否 | 耗时 |

## `search_points.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `location_id` | 是 | 地点 ID |
| `point_id` | 是 | 搜索点 ID |
| `name` | 是 | 显示名 |
| `time_cost` | 否 | 耗时 |
| `hint_rect` | 否 | 热区，四个浮点数 |
| `unlock_condition` | 否 | 解锁条件 |
| `locked_hint` | 否 | 锁定提示 |

## `search_results.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `location_id` | 是 | 地点 ID |
| `point_id` | 是 | 搜索点 ID |
| `variant_id` | 否 | 分支 ID，默认 `default` |
| `when` | 否 | 条件；有值时编译到 `conditional` |
| `intro_text` | 否 | 多步骤调查前文 |
| `narration` | 否 | 调查文本 |
| `gain_evidence` | 否 | 获得证据 |
| `gain_clue` | 否 | 获得线索 |
| `set_flags` | 否 | 设置 flag |
| `trigger_dialogue` | 否 | 触发对话 NPC |
| `trigger_dialogue_start` | 否 | 触发对话节点 |
| `time_cost` | 否 | 耗时 |

## `search_sub_choices.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `location_id` | 是 | 地点 ID |
| `point_id` | 是 | 搜索点 ID |
| `variant_id` | 否 | 对应结果分支，默认 `default` |
| `choice_id` | 否 | 子选项 ID，仅供维护 |
| `order` | 是 | 顺序 |
| `text` | 是 | 选项文本 |
| `narration` | 是 | 选择后文本 |
| `gain_evidence` | 否 | 获得证据 |
| `gain_clue` | 否 | 获得线索 |
| `set_flags` | 否 | 设置 flag |
| `requires` | 否 | 条件 |

## `dialogue_nodes.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | NPC ID |
| `node_id` | 是 | 节点 ID |
| `is_start` | 否 | 是否起点 |
| `text` | 否 | 单页文本 |
| `emotion` | 否 | 情绪 |
| `set_flags` | 否 | 进入节点设置 flag |
| `gain_evidence` | 否 | 获得证据 |
| `gain_clue` | 否 | 获得线索 |
| `trigger_confrontation` | 否 | 是否触发对峙 |
| `confrontation_key` | 否 | 对峙 key |
| `end` | 否 | 是否结束 |
| `writer_note` | 否 | 编剧备注 |

## `dialogue_lines.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | NPC ID |
| `node_id` | 是 | 节点 ID |
| `order` | 是 | 顺序 |
| `speaker_id` | 否 | 说话人 ID |
| `speaker` | 否 | 显示名 |
| `type` | 否 | `dialogue` / `narration` / `inner_thought` |
| `text` | 是 | 台词 |
| `emotion` | 否 | 情绪 |
| `requires` | 否 | 条件 |
| `highlight` | 否 | 高亮词列表 |
| `record_type` | 否 | 卷宗记录类型 |
| `record_title` | 否 | 卷宗标题 |
| `record_text` | 否 | 卷宗内容 |
| `record_id` | 否 | 卷宗记录 ID |

## `dialogue_options.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | NPC ID |
| `node_id` | 是 | 当前节点 |
| `order` | 是 | 顺序 |
| `text` | 是 | 选项文本 |
| `goto` | 是 | 目标节点，特殊值 `__exit__` |
| `type` | 否 | `ask` / `press` / `observe` / `challenge` / `exit` |
| `requires` | 否 | 条件 |
| `set_flags` | 否 | 设置 flag |
| `hide_after_visit` | 否 | 访问后隐藏 |
| `min_hub_visits` | 否 | 解锁所需分支访问数 |
| `cost_time` | 否 | 耗时 |

## `confrontations.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `confrontation_id` | 是 | 对峙 ID，对应运行时 `case.json` 中的 key |
| `suspect` | 否 | 被对峙 NPC ID |
| `is_final` | 否 | 是否最终对峙 |
| `background` | 否 | 背景图 |
| `bgm` | 否 | 基础对峙 BGM |
| `bgm_break` | 否 | 旧字段；当前兼作开场 BGM |
| `bgm_break_actual` | 否 | 击破证词后的 BGM |
| `bgm_final_round` | 否 | 最后一轮 BGM |
| `confidence` | 否 | 信心值 |
| `writer_note` | 否 | 备注 |

## `confrontation_lines.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `confrontation_id` | 是 | 对峙 ID |
| `section` | 是 | `intro_dialogue` / `victory_dialogue` / `defeat_dialogue` / `epilogue_text` |
| `order` | 是 | 顺序 |
| `speaker_id` | 否 | 稳定说话人 ID，优先于显示名；支持 NPC ID、`lu_zhao`、`xia_lingyao` |
| `speaker` | 否 | 说话人显示名；旁白可留空 |
| `text` | 是 | 文本 |
| `emotion` | 否 | 文本/演出情绪 |
| `portrait_emotion` | 否 | 立绘表情 key；留空时使用 `emotion` |
| `portrait_override` | 否 | 强制指定立绘资源路径 |

## `testimony_sets.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `confrontation_id` | 是 | 所属对峙 ID |
| `order` | 是 | 证词组顺序 |
| `testimony_id` | 是 | 证词 ID |
| `witness` | 否 | 证人 NPC ID |
| `title` | 是 | 证词标题 |
| `mode` | 否 | 特殊交互模式；`forced_proof` 表示读完后强制举证自证，不进入普通证词浏览 |
| `proof_statement_id` | 否 | `forced_proof` 使用：证物选择时引用/判定的焦点陈述 |
| `proof_evidence` | 否 | `forced_proof` 使用：自证所需的正确证物 |
| `proof_alt_evidence` | 否 | `forced_proof` 使用：备选正确证物，支持 `[]` / JSON 数组 / 分号列表 |
| `proof_prompt` | 否 | `forced_proof` 使用：证物册顶部显示的自证焦点提示 |
| `skip_title_card` | 否 | 是否跳过证词标题卡；适合反压、临时自证等非正式证词段 |
| `writer_note` | 否 | 备注 |

## `testimony_lines.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `testimony_id` | 是 | 证词 ID |
| `section` | 是 | `preamble` / `readthrough_end_hint` / `transition_dialogue` / `fail_dialogue` |
| `order` | 是 | 顺序 |
| `speaker_id` | 否 | 稳定说话人 ID，优先于显示名 |
| `speaker` | 否 | 说话人显示名 |
| `text` | 是 | 文本 |
| `emotion` | 否 | 文本/演出情绪 |
| `portrait_emotion` | 否 | 立绘表情 key；留空时使用 `emotion` |
| `portrait_override` | 否 | 强制指定立绘资源路径 |

## `testimony_statements.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `testimony_id` | 是 | 所属证词 ID |
| `statement_id` | 是 | 语句 ID |
| `order` | 是 | 顺序；追加句可用 `3.1` |
| `speaker_id` | 否 | 稳定说话人 ID，优先于显示名 |
| `speaker` | 否 | 说话人显示名 |
| `text` | 是 | 证词文本 |
| `emotion` | 否 | 文本/演出情绪 |
| `portrait_emotion` | 否 | 立绘表情 key；留空时使用 `emotion` |
| `portrait_override` | 否 | 强制指定立绘资源路径 |
| `is_contradiction` | 否 | 是否矛盾句 |
| `counter_evidence` | 否 | 正解证据 |
| `alt_evidence` | 否 | 备选证据，支持 `[]` / JSON 数组 / 分号列表 |
| `break_evidence` | 否 | 旧字段兼容 |
| `press_add_trigger` | 否 | 威慑哪句后追加本句 |
| `press_add_after` | 否 | 追加到哪句后面 |
| `writer_note` | 否 | 备注 |

## `testimony_press_lines.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `statement_id` | 是 | 证词语句 ID |
| `order` | 是 | 顺序 |
| `speaker_id` | 否 | 稳定说话人 ID，优先于显示名 |
| `speaker` | 否 | 说话人显示名 |
| `text` | 是 | 威慑对白 |
| `emotion` | 否 | 文本/演出情绪 |
| `portrait_emotion` | 否 | 立绘表情 key；留空时使用 `emotion` |
| `portrait_override` | 否 | 强制指定立绘资源路径 |

## `testimony_break_lines.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `statement_id` | 是 | 被击破的语句 ID |
| `order` | 是 | 顺序 |
| `speaker_id` | 否 | 稳定说话人 ID，优先于显示名 |
| `speaker` | 否 | 说话人显示名 |
| `text` | 是 | 击破对白 |
| `emotion` | 否 | 文本/演出情绪 |
| `portrait_emotion` | 否 | 立绘表情 key；留空时使用 `emotion` |
| `portrait_override` | 否 | 强制指定立绘资源路径 |

## `testimony_wrong_reactions.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `statement_id` | 是 | 证词语句 ID |
| `evidence_id` | 是 | 错误证据 ID；通用反馈用 `_default` |
| `order` | 是 | 顺序 |
| `speaker_id` | 否 | 稳定说话人 ID，优先于显示名 |
| `speaker` | 否 | 说话人显示名 |
| `text` | 是 | 错证反馈文本 |
| `emotion` | 否 | 文本/演出情绪 |
| `portrait_emotion` | 否 | 立绘表情 key；留空时使用 `emotion` |
| `portrait_override` | 否 | 强制指定立绘资源路径 |

## `progression_phases.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `phase_id` | 是 | 阶段 ID |
| `order` | 是 | 阶段顺序 |
| `title` | 是 | 阶段标题 |
| `description` | 否 | 阶段说明 |
| `hint` | 否 | 当前阶段提示 |
| `locations` | 否 | 本阶段解锁地点列表 |
| `unlock_condition` | 否 | 解锁条件；空值会编译为 `null` |
| `writer_note` | 否 | 备注 |

## `progression_unlocks.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `unlock_type` | 是 | `panel_unlock` / `search_point_unlock` / `npc_unlock` / `confrontation_unlock` |
| `target_id` | 是 | 目标 ID；搜索点格式为 `location_id.point_id` |
| `condition` | 否 | 解锁条件；空值会编译为 `null` |
| `locked_hint` | 否 | 锁定提示 |
| `writer_note` | 否 | 备注 |

## `phase_notifications.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `phase_id` | 是 | 阶段 ID |
| `speaker` | 否 | 提示说话人 |
| `text` | 是 | 阶段解锁提示文本 |

## `npc_state_initial.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | NPC ID |
| `stat` | 是 | 状态名，如 `composure` / `openness` / `trust` / `defense` |
| `value` | 是 | 初始值 |

## `npc_state_transitions.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | NPC ID |
| `order` | 是 | 顺序 |
| `event` | 是 | 触发事件，如 `evidence_obtained:evidence_hull_hole` |
| `delta` | 是 | 状态变化 JSON，如 `{"composure":-1}` |
| `writer_note` | 否 | 备注 |

## `day_events.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `event_id` | 是 | 事件 ID |
| `order` | 是 | 事件顺序 |
| `title` | 是 | 事件标题 |
| `hint` | 否 | 事件按钮提示 |
| `trigger` | 是 | 触发条件 JSON |
| `effects` | 否 | 效果 JSON，如 `{"set_flag":["x"]}` |
| `auto_play` | 否 | 是否自动播放 |
| `writer_note` | 否 | 备注 |

## `day_event_lines.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `event_id` | 是 | 事件 ID |
| `order` | 是 | 台词顺序 |
| `line_kind` | 是 | `text` 表示纯旁白字符串；`dict` 表示带 speaker 的对象 |
| `speaker` | 否 | 说话人 |
| `text` | 是 | 文本 |
| `emotion` | 否 | 情绪 |
| `voice_path` | 否 | 语音路径 |

## `schedule_defaults.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | NPC ID |
| `role_note` | 否 | 角色备注，编译为 `_role` |
| `location` | 否 | 默认所在地 |
| `activity` | 否 | 默认活动 |
| `public` | 否 | 是否公开可见 |

## `schedule_overrides.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | NPC ID |
| `time_key` | 是 | 精确时段，如 `D1_P6` |
| `location` | 是 | 所在地 |
| `activity` | 否 | 活动 |
| `public` | 否 | 是否公开可见 |

## `schedule_conditional_overrides.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 是 | NPC ID |
| `order` | 是 | 顺序 |
| `if_flag` | 是 | 满足该 flag 后启用 |
| `location` | 是 | 所在地 |
| `activity` | 否 | 活动 |
| `public` | 否 | 是否公开可见 |

## `culprit_actions.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `action_id` | 是 | 行动 ID |
| `order` | 是 | 顺序 |
| `culprit` | 否 | 行动者 NPC ID |
| `day_period` | 是 | 基准时段，如 `D2_P3` |
| `jitter` | 否 | 随机抖动时段数 |
| `intent` | 否 | 行动意图说明 |
| `trace_evidence_id` | 否 | 留下的证据 ID |
| `trace_location` | 否 | 留痕地点 |
| `trace_discoverable_after` | 否 | 可发现时段 |
| `if_witnessed` | 否 | 玩家撞见后设置的 flag |
| `writer_note` | 否 | 备注 |

## `portrait_expressions.csv`

| 字段 | 必填 | 说明 |
|---|---|---|
| `npc_id` | 否 | NPC ID，仅用于维护和校验 |
| `base_portrait` | 是 | 基础立绘路径，即 `characters.csv` / `casting.json` 中的 portrait |
| `emotion` | 是 | 表情 key；普通对话用 `crying` / `nervous` 等，对峙可用 `confrontation` / `confrontation_shaken` / `confrontation_collapsed` |
| `portrait` | 是 | 该表情对应的实际 PNG 资源路径 |
| `writer_note` | 否 | 备注 |

立绘统一解析规则：对峙中央大立绘和底部对话头像都使用 `speaker_id + portrait_emotion/emotion` 查 `portrait_expressions.csv`；若未命中，会按文件名后缀回退，最后回退到 `characters.csv` 的基础 `portrait`。
