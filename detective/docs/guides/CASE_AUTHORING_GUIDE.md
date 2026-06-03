# 案件编写规范与约束指南

> **面向对象**：协同开发者（新案件作者）  
> **基于版本**：临川驿案（linchuan_inn）v1  
> **最后更新**：2026-05-19  
> **关联文档**：[META_FRAMEWORK_ROADMAP.md](META_FRAMEWORK_ROADMAP.md) · [ROADMAP_PCG.md](ROADMAP_PCG.md) · [ASSET_ARCHITECTURE.md](ASSET_ARCHITECTURE.md)

---

## 一、总体架构概览

```
data/cases/<case_id>/
├── manifest.json          ← 案件元信息（标题/难度/预览等）
├── case.json              ← 指证答案 + 结局分支
├── casting.json           ← 选角表（全局演员 → 本案角色）
├── npcs.json              ← NPC 定义 + 名字解锁规则
├── npc_states.json        ← NPC 状态机（数值 + 转换规则）
├── locations.json         ← 地点定义 + 搜索点
├── evidence.json          ← 证据 + 线索定义
├── search_results.json    ← 搜索结果映射（条件产出）
├── progression.json       ← 渐进式开放系统（阶段/面板/解锁）
├── day_events.json        ← 时间线事件（自动叙述）
├── prologue.json          ← 序章对话树
├── bgm_config.json        ← 背景音乐配置
├── companion/
│   ├── companion.json     ← 助手配置
│   ├── banter.json        ← 被动旁白规则
│   └── discussions.json   ← 主动讨论台词
└── dialogues/
    ├── <npc_id>.json      ← 每个 NPC 一个对话树文件
    └── ...
```

### 全局共享资源（无需每案重写）

| 文件 | 用途 |
|------|------|
| `data/actors/registry.json` | 全局演员库（立绘/声线/标签） |
| `data/companions/registry.json` | 助手库（固定形象） |
| `data/bgm/registry.json` | BGM 库 |
| `data/scenes/registry.json` | 场景资源注册表 |
| `data/cases/_index.json` | 案件索引（入口） |
| `data/meta/ranks.json` | 等级经验表 |

---

## 二、核心设计约束

### 2.1 演员/角色分离原则

- **演员（Actor）**：全局资源，拥有立绘、声线配置、气质标签
- **角色（Role）**：案件内身份，通过 `casting.json` 分配

```json
// casting.json 示例
"npc_id": {
  "actor_id": "actor_white_robed_scholar",  // 引用全局演员
  "role_name": "顾清玄",                     // 本案名字
  "role_title": "游学公子",                   // 本案头衔
  "role_intro": "自称沈砚秋旧友的白衣公子",
  "is_culprit": true                         // 是否凶手（仅一人）
}
```

**约束**：
- NPC 数量视案件难度和规模灵活调整（参见下方难度分级表）
- 必须有且仅有 1 个 `is_player: true` 条目
- 必须有且仅有 1 个 `is_culprit: true` 条目（多凶手案件为后续扩展预留）
- `actor_id` 必须在 `actors/registry.json` 中存在
- 如需新演员形象，先在 `actors/registry.json` 中注册

### 2.1.1 难度分级与规模建议

| 难度 | NPC 数量 | 地点 | 物证 | 线索 | 渐进阶段 | 预估天数 | 预估时长 |
|------|---------|------|------|------|---------|---------|---------|
| 简单 | 4-6 | 3-4 | 6-8 | 8-12 | 2 | 3-5 | 1-2h |
| 中等 | 7-9 | 5-7 | 10-15 | 12-20 | 3 | 5-7 | 2-4h |
| 困难 | 10-14 | 7-10 | 15-20 | 18-30 | 4-5 | 7-10 | 4-6h |
| 复杂 | 15+ | 10+ | 20+ | 25+ | 5+ | 10+ | 6h+ |

**注意事项**：
- NPC 越多，需要的对话文件、状态机、选角条目、助手旁白也成比例增加
- 大型案件建议划分「核心嫌疑人」和「辅助证人/路人」两类：
  - **核心嫌疑人**：拥有完整对话树 + 状态机 + 谎言系统
  - **辅助NPC**：对话树较短，可能仅提供线索/气氛，无需状态机
- 后续版本可能支持：多凶手、共犯体系、NPC 间关系网络、跨案件NPC复现
- 规模扩大时，务必保证**条件可达性**和**时间兜底**仍然成立

### 2.2 时间系统

- 每案设定 `estimated_days` 天（根据难度分级灵活调整，参见 2.1.1）
- 每日 **14 个时段**（从清晨到深夜）
- 总时段 = days × 14 = 时间预算（简单案件约 42-70，困难案件可达 140+）
- 玩家每次行动消耗时段：对话选项 `cost_time`、搜索点 `time_cost`
- 时间预算应与 NPC 数量、证据总量匹配：确保玩家在正常游玩下能接触到 70-80% 的内容
- 日程事件按 `total_periods_used_gte` 触发

### 2.3 指证系统约束

`case.json` 必须定义：

| 字段 | 类型 | 约束 |
|------|------|------|
| `culprit` | String | NPC ID，必须在 casting 中标记 `is_culprit`（当前仅支持单凶手，后续可扩展） |
| `motive` | String | 动机枚举值 |
| `method` | String | 手法枚举值 |
| `key_evidence` | Array[String] | 关键证据 ID 列表（仅 type=evidence） |
| `min_evidence_required` | Int | 完美结局需提交的最低证据数 |
| `suspects` | Array[String] | 全部嫌疑人 NPC ID 列表 |
| `motive_options` | Array[Object] | 动机选项（id + label） |
| `method_options` | Array[Object] | 手法选项（id + label） |
| `endings` | Object | 结局分支定义 |

**结局分支必须包含 5 种**：`perfect`、`good`、`partial`、`bad`、`timeout`

---

## 三、条件表达式系统

所有条件字段（`when`、`requires`、`condition`、`unlock_condition`）使用统一的条件表达式语法：

### 3.1 原子条件

| 类型 | 格式 | 说明 |
|------|------|------|
| 拥有证据 | `{ "evidence": "evidence_xxx" }` | 玩家已获得指定物证 |
| 拥有线索 | `{ "clue": "clue_xxx" }` | 玩家已获得指定线索 |
| 旗标已设 | `{ "flag": "flag_name" }` | 指定 flag 已被设置 |
| 旗标未设 | `{ "not_flag": "flag_name" }` | 指定 flag 未被设置 |
| 否定包装 | `{ "not": { ... } }` | 内部条件取反 |
| NPC 状态 | `{ "state": "npc.attr", "gte": N }` | NPC 属性 >= N |
| NPC 状态 | `{ "state": "npc.attr", "lte": N }` | NPC 属性 <= N |
| 时间条件 | `{ "day_gte": N }` | 当前日 >= N |
| 时段条件 | `{ "total_periods_used_gte": N }` | 累计消耗时段 >= N |
| 已访问节点 | `{ "visited": "npc_id.node_id" }` | 玩家已访问某对话节点 |
| 证据数量 | `{ "evidence_count_gte": N }` | 已获得证据总数 >= N |
| 线索数量 | `{ "clue_count_gte": N }` | 已获得线索总数 >= N |

### 3.2 组合条件

| 类型 | 格式 | 说明 |
|------|------|------|
| AND | `{ "all": [ ...条件数组 ] }` | 所有子条件同时满足 |
| OR | `{ "any": [ ...条件数组 ] }` | 任一子条件满足 |

### 3.3 命名规范

- **证据 ID**：`evidence_` 前缀，如 `evidence_secret_letter`
- **线索 ID**：`clue_` 前缀，如 `clue_handkerchief`
- **Flag**：小写蛇形命名，如 `shen_house_broken`、`liu_alarmed`
- **事件 Flag**：`evt_` 前缀 + `_done` 后缀，如 `evt_day2_break_in_done`

---

## 四、对话树编写规范

### 4.1 文件结构

```json
{
  "_comment": "设计者注释",
  "start": "intro",                    // 默认入口节点
  "start_variants": [                  // 条件入口（优先级从高到低）
    { "when": { ... }, "goto": "node_id" }
  ],
  "nodes": {
    "node_id": { ... }                 // 节点字典
  }
}
```

### 4.2 节点字段

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `text` | String | 是* | NPC 的台词（与 text_variants 二选一） |
| `text_variants` | Array | 是* | 条件台词变体 |
| `options` | Array | 是 | 玩家选项列表 |
| `lie` | Object | 否 | 标记此节点为谎言 |
| `reveal_lie` | Object | 否 | 揭穿指定谎言 |
| `set_flags` | Array[String] | 否 | 设置 flag |
| `gain_clue` | String | 否 | 获得线索 |
| `gain_evidence` | String | 否 | 获得物证 |

### 4.3 选项字段

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `text` | String | 是 | 选项文字 |
| `goto` | String | 是 | 跳转目标（`"__exit__"` = 结束对话） |
| `requires` | Condition | 否 | 显示条件 |
| `cost_time` | Number | 否 | 消耗时段数 |
| `hide_after_visit` | Boolean | 否 | 选过后隐藏 |

### 4.4 谎言系统

```json
// 标记谎言
"lie": {
  "is_lie": true,
  "reason": "隐瞒的真实原因",
  "exposed_by_node": "reveal_node_id"
}

// 揭穿谎言
"reveal_lie": { "lie_node": "原始谎言节点ID" }
```

**约束**：
- 每个谎言节点的 `exposed_by_node` 必须指向一个实际存在的节点
- 揭穿节点通常需要特定证据作为 `requires` 前提
- 揭穿时系统自动触发 NPC 的 composure 下降

### 4.5 设计原则

1. **多层入口**：NPC 根据调查进度呈现不同开场（start_variants）
2. **单次选项**：关键证据出示用 `hide_after_visit: true`
3. **时间成本**：出示证据和深入追问应设 `cost_time`（防止穷举）
4. **渐进揭示**：NPC 的状态值（composure/trust/openness）决定对话分支走向
5. **节点命名**：使用语义化 ID（如 `show_letter`、`confront_alibi`）

---

## 五、NPC 状态机规范

### 5.1 定义格式（`npc_states.json`）

```json
"npc_id": {
  "initial": { "composure": 5, "mask": 5 },
  "transitions": [
    { "on": "node_visited:node_id", "delta": { "composure": -1 } },
    { "on": "evidence_obtained:evidence_id", "delta": { "mask": -2 } },
    { "on": "flag_set:flag_name", "delta": { "trust": 1 } },
    { "on": "clue_obtained:clue_id", "delta": { "composure": -1 } }
  ]
}
```

### 5.2 标准状态维度

| 维度 | 范围 | 用途 | 适用角色 |
|------|------|------|---------|
| `composure` | 0-5 | 镇定度（0=崩溃） | 所有 NPC |
| `mask` | 0-5 | 伪装度（仅凶手） | 凶手 |
| `trust` | 0-5 | 对玩家的信任 | 盟友/中立NPC |
| `openness` | 0-5 | 开放程度 | 胆怯/被动NPC |

### 5.3 触发事件类型

| 事件格式 | 触发时机 |
|---------|---------|
| `node_visited:<node_id>` | 对话中玩家选择到达该节点 |
| `evidence_obtained:<evidence_id>` | 获得物证时 |
| `clue_obtained:<clue_id>` | 获得线索时 |
| `flag_set:<flag_name>` | 设置 flag 时 |

### 5.4 设计约束

- delta 值建议 ±1 到 ±2，避免状态跳变过大
- 凶手的 `mask` 和 `composure` 应独立下降路径
- 确保状态 0 时对话树有对应的 `text_variants` 分支

---

## 六、地点与搜索系统

### 6.1 地点定义（`locations.json`）

```json
"location_id": {
  "name": "中文名",
  "description": "场景描述",
  "scene_type": "scene_xxx",            // 对应 scenes/registry.json
  "background": "res://assets/.../bg.png",
  "unlock_phase": "phase_N",            // 属于哪个渐进阶段
  "npcs": ["npc_id_1", "npc_id_2"],     // 常驻 NPC
  "search_points": [
    { "id": "point_id", "name": "中文名", "time_cost": N }
  ]
}
```

### 6.2 搜索结果（`search_results.json`）

Key 格式：`location_id.point_id`

```json
"location_id.point_id": {
  "default": {
    "narration": "叙述文本",
    "clue": "clue_xxx",          // 或 "evidence": "evidence_xxx"
  },
  "after_clue:clue_id": {        // 条件产出（二次搜索）
    "narration": "新发现文本",
    "evidence": "evidence_xxx"
  },
  "conditional": [                // 条件搜索（如约见场景）
    {
      "when": { ... },
      "narration": "...",
      "trigger_dialogue": "npc_id",
      "set_flags": ["flag"]
    }
  ]
}
```

**约束**：
- 每个搜索点至少有一个 `default` 结果
- `after_clue:xxx` / `after_evidence:xxx` 用于二次搜索解锁新证据
- 搜索结果可以触发对话（`trigger_dialogue`）

---

## 七、渐进式开放系统

### 7.1 阶段定义（`progression.json`）

```json
"phases": [
  {
    "id": "phase_1",
    "title": "阶段标题",
    "description": "描述",
    "hint": "给玩家的提示",
    "locations": ["loc_1", "loc_2"],     // 此阶段解锁的地点
    "unlock_condition": null             // null = 初始阶段
  },
  {
    "id": "phase_2",
    "unlock_condition": { ... }          // 条件表达式
  }
]
```

### 7.2 其他解锁类型

| 类型 | 位置 | 说明 |
|------|------|------|
| 面板解锁 | `panel_unlock` | 指证面板/笔记本等功能面板 |
| 搜索点解锁 | `search_point_unlock` | 特定搜索点需要前置条件 |
| NPC 解锁 | `npc_unlock` | NPC 出现的条件 |
| 阶段通知 | `phase_notifications` | 阶段解锁时助手的提示台词 |

### 7.3 设计原则

- **Phase 1** 永远无条件（`unlock_condition: null`）
- 阶段解锁建议同时提供**条件解锁**和**时间兜底**（`total_periods_used_gte`）
- 避免死锁：确保玩家一定能通过时间推进到达后续阶段

---

## 八、日程事件系统

### 8.1 事件格式（`day_events.json`）

```json
{
  "id": "evt_unique_id",
  "trigger": { ... },                    // 条件表达式
  "title": "事件标题",
  "hint": "悬浮提示",
  "narration": [                         // 叙述序列
    "纯文本旁白",
    { "speaker": "角色名", "text": "台词", "portrait": "npc_id" }
  ],
  "effects": {
    "set_flag": "flag_name",             // 或 ["flag1", "flag2"]
    "gain_clue": "clue_xxx",
    "gain_evidence": "evidence_xxx",
    "unlock_hint": "location_id"
  }
}
```

### 8.2 设计约束

- 每个事件必须有 `{ "not": { "flag": "evt_xxx_done" } }` 防止重复触发
- 叙述数组支持混合类型：纯字符串 = 旁白，对象 = 对话
- 事件按 `total_periods_used_gte` 排布时间线
- 助手（凌瑶）应在关键事件中有反应台词

---

## 八B、NPC 日程表（可选）

> 浔阳楼案引入。NPC 按时段出现在不同地点，让案件世界更鲜活。

### 8B.1 格式（`schedules.json`）

```json
"npc_id": {
  "_role": "角色描述",
  "default": {
    "location": "location_id",       // 默认地点
    "activity": "activity_tag",      // 正在做什么
    "public": true                   // 玩家是否可见
  },
  "overrides": {
    "D1_P5": {                       // Day_Period 格式
      "location": "location_id",
      "activity": "activity_tag",
      "public": false,               // false=秘密行动
      "motive_hidden": "真实意图描述（不暴露给玩家）"
    }
  }
}
```

### 8B.2 设计约束

- `D{n}_P{m}` 格式：D=天数（从1开始），P=时段（从0开始）
- `public: false` 的行动，玩家只有"恰好在同一地点同一时段"才能目击
- 凶手和红鲱鱼的可疑行为都应记录在日程中
- 与 `culprit_actions.json` 配合使用

---

## 八C、凶手罪后行动（可选）

> 浔阳楼案引入。凶手在案发后的清理/销毁行为，可被玩家目击。

### 8C.1 格式（`culprit_actions.json`）

```json
{
  "actions": [
    {
      "id": "ca_unique_id",
      "culprit": "npc_id",
      "day_period": "D1_P5",          // 何时执行
      "jitter": 1,                    // 时间浮动（±时段数）
      "intent": "描述真实意图",
      "leaves_trace": {
        "evidence_id": "evidence_xxx", // 留下的证据
        "location": "location_id",     // 在哪留下
        "discoverable_after": "D1_P6"  // 何时可被发现
      },
      "if_witnessed": "flag_name"      // 被目击时设置的flag
    }
  ]
}
```

### 8C.2 设计约束

- 每个罪后行动必须 `leaves_trace` 留下可发现的证据
- `if_witnessed` flag 可触发日程事件（如目击场景叙述）
- 建议 3-5 个罪后行动，覆盖案发后 D1-D3
- 红鲱鱼的可疑行为放在 `schedules.json` 而非此文件

---

## 八D、子地点系统（可选）

> 浔阳楼案引入。大型建筑内部可划分为多个子地点，通过导航连接。

### 8D.1 格式（在 `locations.json` 中扩展）

```json
"parent_location": {
  "name": "...",
  "is_hub": true,                    // 标记为枢纽地点
  "children": ["child_1", "child_2"], // 子地点列表
  "sub_locations": [
    {
      "target": "child_1",
      "name": "导航按钮文字",
      "description": "导航描述"
    }
  ]
},
"child_location": {
  "name": "...",
  "parent": "parent_location",       // 指向父地点
  "sub_locations": [
    { "target": "parent_location", "name": "返回xxx", "description": "..." }
  ]
}
```

### 8D.2 设计约束

- `is_hub: true` 的地点在地图面板中作为入口显示
- 子地点不单独出现在地图中，通过父地点进入
- `parent`/`children` 关系必须双向一致
- 子地点仍需独立的 `unlock_phase`
- 适用于：酒楼（正厅/后院/闺阁）、府邸（前院/内堂/书房）等复合场景

---

## 九、证据与线索规范

### 9.1 定义格式（`evidence.json`）

```json
"evidence_xxx": {
  "type": "evidence",          // evidence = 实物证据，可用于指证
  "name": "中文显示名",
  "description": "详细描述（玩家在笔记本中看到的）"
},
"clue_xxx": {
  "type": "clue",              // clue = 线索/情报，不可直接指证
  "name": "中文显示名",
  "description": "详细描述"
}
```

### 9.2 设计约束

| 约束项 | 说明 |
|--------|------|
| 总证据数 | 视难度分级（简单 6-8 / 中等 10-15 / 困难 15-20 / 复杂 20+） |
| 总线索数 | 视难度分级（简单 8-12 / 中等 12-20 / 困难 18-30 / 复杂 25+） |
| key_evidence | 从全部 evidence 中选 40-60% 作为关键证据 |
| min_evidence_required | 建议为 key_evidence 数量的 50-70% |
| 排除证据 | 建议至少有 1-2 件「排除用」证据（引导玩家排除嫌疑人） |
| 描述文风 | 以第二人称叙述，带推理暗示但不直接点破 |
| ID 命名 | `evidence_` / `clue_` 前缀 + 描述性蛇形命名 |

### 9.3 获取渠道

证据/线索通过以下途径获得：
1. **搜索** → `search_results.json` 中配置
2. **对话** → 节点的 `gain_clue` / `gain_evidence`
3. **日程事件** → `effects.gain_clue` / `effects.gain_evidence`

---

## 十、助手系统规范

### 10.1 配置文件（`companion/companion.json`）

```json
{
  "companion_id": "xia_lingyao",         // 引用 companions/registry.json
  "role_name": "凌瑶",
  "actor_id": "actor_tomboy_courier",
  "available_topics": ["next_direction", "suspect_now", "evidence_ready", "chitchat"],
  "limits": {
    "topic_id": { "per_day": N, "cost_period": N, "cost_cognitive": N }
  },
  "banter_max_per_day": 8,
  "lock_on_final_day": true
}
```

### 10.2 被动旁白（`companion/banter.json`）

```json
{
  "rules": [
    {
      "id": "rule_unique_id",
      "when": { "trigger": "trigger_type" },
      "lines": [
        "助手独白字符串",
        [                                 // 多人对话
          { "speaker": "凌瑶", "text": "..." },
          { "speaker": "陆昭", "text": "..." }
        ]
      ]
    }
  ]
}
```

**触发类型**：
| trigger | 触发时机 |
|---------|---------|
| `lie_exposed` | 揭穿谎言后 |
| `gain_evidence` | 获得物证后 |
| `gain_clue` | 获得线索后 |
| `after_npc_talk:<npc_id>` | 与特定NPC对话后 |
| `arrive_location:<loc_id>` | 到达特定地点时 |
| `phase_unlocked:<phase_id>` | 阶段解锁时 |

### 10.3 主动讨论（`companion/discussions.json`）

按 topic 分组，每个 topic 有多条带条件的建议台词：

```json
"topic_name": {
  "rules": [
    {
      "when": { ... },
      "lines": ["台词1", "台词2"]
    }
  ]
}
```

**约束**：
- 闲聊（chitchat）使用 `pool` 结构（无条件随机抽取）
- 策略讨论应根据当前进度给出不同建议
- 助手性格一致性：活泼、直白、偶尔冒失

---

## 十一、写作风格约束

### 11.1 文本风格

| 维度 | 规范 |
|------|------|
| 时代背景 | 明清（万历年间），语言半文半白 |
| 叙述人称 | 第二人称（"你查看了……"） |
| 对话风格 | 文言与白话混合，符合角色身份 |
| 证据描述 | 提供推理线索但不直接揭示答案 |
| 旁白语气 | 冷静克制，偶带诗意 |

### 11.2 角色语言风格参考

| 类型 | 风格 | 示例 |
|------|------|------|
| 官员 | 书面、含蓄 | "此事……容某再想想。" |
| 百姓 | 口语化 | "大人您说得是……可小的确实不知道啊。" |
| 助手 | 活泼、直白 | "嘿嘿嘿，露馅了吧！" |
| 僧人 | 佛语、谦逊 | "施主，贫僧有一言相告。" |
| 花魁 | 灵巧、闪烁 | "公子……奴家不敢乱说的。" |

### 11.3 推理设计原则

1. **三层线索**：每条真相至少需要 3 条独立线索/证据佐证
2. **误导线**：至少设置 2-3 条指向非凶手的嫌疑线索
3. **排除法**：提供可排除嫌疑人的证据
4. **动机递进**：凶手动机应逐步揭示，不可一步到位
5. **时间紧迫**：关键证据应分散在不同阶段，制造紧迫感

---

## 十二、新案件创建清单

### 12.1 必需文件

- [ ] `manifest.json` — 案件元信息
- [ ] `case.json` — 答案与结局
- [ ] `casting.json` — 选角表
- [ ] `npcs.json` — NPC 定义
- [ ] `npc_states.json` — 状态机
- [ ] `locations.json` — 地点（视难度，简单 3-4 / 中等 5-7 / 困难 7-10）
- [ ] `evidence.json` — 证据线索（参见难度分级表）
- [ ] `search_results.json` — 搜索结果
- [ ] `progression.json` — 渐进开放
- [ ] `day_events.json` — 日程事件（视规模，简单 4-6 / 中等 6-10 / 困难 10-15）
- [ ] `prologue.json` — 序章对话
- [ ] `bgm_config.json` — BGM 配置
- [ ] `companion/companion.json` — 助手配置
- [ ] `companion/banter.json` — 被动旁白
- [ ] `companion/discussions.json` — 主动讨论
- [ ] `dialogues/<npc_id>.json` — 每个 NPC 一个对话文件

**可选文件（视案件复杂度决定是否使用）**：

- [ ] `schedules.json` — NPC 日程表（NPC按时段出现在不同地点）
- [ ] `culprit_actions.json` — 凶手罪后行动（可被目击的清理行为）
- [ ] `voice_profiles.json` — TTS 配音设定（如使用外部TTS）

### 12.2 注册步骤

1. 在 `data/cases/_index.json` 添加新案件条目
2. 确认 `casting.json` 中所有 `actor_id` 在 `actors/registry.json` 中存在
3. 确认 `companion_id` 在 `companions/registry.json` 中存在
4. 确认所有 `scene_type` 在 `scenes/registry.json` 中有对应

### 12.3 自检要点

| 检查项 | 说明 |
|--------|------|
| ID 唯一性 | 所有证据/线索/flag/节点 ID 不能与其他案件冲突 |
| 条件可达性 | 每个阶段/证据/NPC 必须有至少一条可达路径 |
| 时间兜底 | 所有渐进阶段必须有时间兜底解锁条件 |
| 结局可达 | 5 种结局每种至少对应一种合理的游戏路径 |
| 谎言闭环 | 每个 `lie` 必须有对应的 `reveal_lie` 节点 |
| 状态归零 | NPC composure=0 时对话树必须有对应分支 |
| 助手覆盖 | 所有关键事件/证据获取后都应有助手反应 |
| 文本校验 | 无错别字、人物称谓一致、时代用语合理 |
| NPC 分类 | 明确区分「核心嫌疑人」和「辅助NPC」，确认各自需要的文件齐全 |
| 时间预算 | 总时段是否足够覆盖所有 NPC 对话 + 搜索点（建议预算 ≥ 必要行动×1.5） |
| 规模匹配 | 地点数/证据数/阶段数是否与NPC数量匹配（避免内容空洞或过度拥挤） |

---

## 十三、关键设计模式总结

### 模式 A：渐进式审讯

```
初次对话 → 获取基础信息
        → 获得线索后解锁新选项（requires）
        → 出示证据触发谎言揭穿
        → composure 下降 → 解锁更深层对话
        → 最终坦白/崩溃
```

### 模式 B：信任积累

```
初次接触（trust=1）→ 冷淡/警惕
  → 完成特定对话（trust+1）
  → 秘密约见（trust+1）
  → 打开信息阀门（trust≥3）
```

### 模式 C：条件搜索链

```
首次搜索 → 获得基础线索
  → 带着线索/证据回来 → after_clue 触发新发现
  → 交叉比对 → 获得关键物证
```

### 模式 D：凶手伪装

```
凶手初始（mask=5）→ 主动接近/帮助
  → 玩家质疑（mask-1）
  → 笔迹对比等（mask-2）
  → mask≤2 → 对话切换为防守模式
  → 最终证据链完整 → 可指证
```

---

## 附录 A：临川驿案数据统计（中等难度参考基准）

| 类别 | 数量 | 说明 |
|------|------|------|
| NPC | 7 人（不含玩家） | 全部为核心嫌疑人/证人 |
| 地点 | 6 个 | 分三阶段渐进开放 |
| 搜索点 | 17 个 | 平均每地点 2-3 个 |
| 物证 (evidence) | 12 件 | 含 1 件排除用 |
| 线索 (clue) | 16 条 | |
| 关键证据 | 7 件 | 占物证总数 58% |
| 日程事件 | 8 个 | |
| 渐进阶段 | 3 个 | |
| 对话节点（约） | ~120 个 | |
| 助手台词 | ~140 条 | |
| 游戏时长（预估） | 2-4 小时 | |

> **注**：此为「中等」难度案件的参考基准。更大规模案件按比例扩展即可。

---

## 附录 C：后续扩展预留

以下特性尚未实装，但数据结构应预留兼容空间：

| 特性 | 预留方案 | 状态 |
|------|---------|------|
| **多凶手/共犯** | `case.json` 中 `culprit` 可扩展为数组；`casting.json` 支持多个 `is_culprit` | 规划中 |
| **NPC 关系网** | 新增 `relationships.json`，定义 NPC 间的关系类型与亲密度 | 规划中 |
| **跨案件 NPC 复现** | 同一 `actor_id` 在不同案件的 `casting.json` 中扮演不同角色 | 已支持 |
| **辅助 NPC 轻量模板** | 无状态机、仅有简短对话的 NPC，对话文件可简化为单节点 | 建议实装 |
| **NPC 日程表** | NPC 按时段出现在不同地点，增加调查的时间规划维度 | 规划中 |
| **多助手切换** | `companion.json` 支持配置多个助手，玩家可选择 | 规划中 |
| **分支结局细化** | 不止 5 种结局，支持按证据组合产生更多变体 | 规划中 |
| **DLC/章节式案件** | 大型案件分为多个「章」，每章独立存档但共享进度 | 规划中 |

**对当前写作的影响**：
- 为每个 NPC 使用**全局唯一**的 `npc_id`，避免跨案件冲突
- 对话节点 ID 建议加 NPC 前缀或保持语义唯一性
- Flag 命名建议：`<case_id>_<flag_name>` 格式，方便未来多案件共存调试

---

## 附录 B：案件索引条目格式

```json
{
  "id": "new_case_id",
  "manifest": "res://data/cases/new_case_id/manifest.json",
  "order": 3,
  "locked": true,
  "tag": "三部曲",
  "voice_status": "missing",
  "rank_required": 3,
  "style": "ming_qing",
  "category": "solo",
  "preview_blurb": "简短预览文字。"
}
```

| 字段 | 说明 |
|------|------|
| `order` | 排列顺序 |
| `locked` | 是否默认锁定（需完成前序案件解锁） |
| `rank_required` | 要求调查员等级 |
| `style` | 时代风格标签 |
| `category` | `"solo"` = 单人, `"duo"` = 双人 |
| `voice_status` | `"full"` / `"partial"` / `"missing"` |

---

## 附录 D：Meta 框架（推理者计划）

> 详细设计见 `docs/META_FRAMEWORK_ROADMAP.md`

### 元背景设定

所有案件存在于一个更大的世界框架中：

> 玩家是秘密机构「**推理者计划**（Detective Program）」征召的调查员。  
> 每个案件是一场"模拟推理事件"，完成后提升 **推理等级（Detective Rank）**，解锁更高难度/不同风格的案件。  
> 最终多名调查员合作面对"世界级谜题"——终章。

**这套设定对案件写作的影响**：

1. 案件可以跨时代跨风格（明清/现代/维多利亚/科幻均可）
2. 每个案件仍是独立完整故事，单独玩不受 meta 层影响
3. 后续可能有双人合作案件（`category: "coop_2p"`）

### 调查员成长系统

| 等级 | 称号 | 累计 XP |
|------|------|---------|
| 1 | 实习侦探 | 0 |
| 2 | 见习调查员 | 200 |
| 3 | 正式调查员 | 500 |
| 4 | 高级调查员 | 900 |
| 5 | 首席调查员 | 1400 |

**XP 来源**：

| 结局 | 基础 XP | 首次通关加成 | 重玩系数 |
|------|---------|-------------|---------|
| perfect | 200 | +50 | ×0.3 |
| good | 140 | +50 | ×0.3 |
| partial | 80 | +50 | ×0.3 |
| bad | 30 | +50 | ×0.3 |
| timeout | 20 | +50 | ×0.3 |

### 案件写作中的 Meta 字段

`manifest.json` 中可选添加：

```json
{
  "theme_pack": "ming_qing",           // 主题包（决定UI皮肤）
  "meta_clue": {                       // Meta 线索（终章拼图碎片）
    "id": "shard_03_yin",
    "name": "玉简·阴",
    "description": "通关后浮现的不属于这个时代的玉简",
    "unlock_at_ending": ["perfect", "good"]
  },
  "rewards": {
    "xp_override": null,               // null=用默认XP表
    "unlock_cases": ["next_case_id"]   // 通关后解锁的案件
  }
}
```

### 对当前案件写作的约束

| 约束 | 说明 |
|------|------|
| `rank_required` | 在 `_index.json` 中设定，决定案件解锁顺序 |
| `style` | 标记时代风格（`ming_qing` / `modern` / `victorian` / `scifi`） |
| `category` | `solo` / `coop_2p` / `final` |
| `meta_clue` | 可选，建议每个案件埋一个，为终章做铺垫 |
| 元层不破坏单案 | 玩家不看 meta 层也能完整体验案件 |
| meta 线索自然融入 | 不能变成生硬收集任务，应与案件本身叙事有机结合 |

### 跨风格/跨时代案件注意事项

- **引擎层不变**：GameManager / DialogueManager / 笔记本 / 指证流程保持一致
- **视觉换皮**：通过 `theme_pack` 切换颜色、字体、边框、动效
- **资源隔离**：`data/cases/<id>/` + `assets/<locale>/voices/<actor>/<case>/` 按案件ID隔离
- **写作风格适配**：不同时代的对话风格应与 `style` 匹配（参见§11.1）

### 双人合作案件（预留）

设计前提：
- 数据上新增 `data/cases/<id>/coop.json` 定义两条调查线
- 信息分配：共享 vs 私有线索
- 时间同步：统一时段制
- 指证需两人共同确认
- 技术路线：先 hot-seat 本地共用设备，后续扩展联机

---

## 附录 E：PCG（程序化案件生成）路线

> 详细设计见 `docs/ROADMAP_PCG.md`

### PCG 对案件写作的影响

PCG 系统分三个里程碑，理解其架构有助于手写案件时保持数据兼容：

```
M1 PCG主线（骨架模板→填槽→校验→对话派生→Godot加载）
M2 资产抽象层（演员库/场景库/BGM库 + AssetResolver + 选角表）  ← 已完成
M3 闭环（自动选角 + 端到端生成 + 批量验证）
```

### 手写案件需遵守的 PCG 兼容规范

| 规范 | 说明 | 原因 |
|------|------|------|
| 严格使用 `casting.json` | 角色-演员映射必须通过选角表，不可在对话/脚本中硬编码立绘路径 | M3 选角器需统一入口 |
| `locations.json` 带 `scene_type` | 每个地点引用场景库中的场景类型 | M3 自动选景需要标签匹配 |
| `bgm_config.json` 使用 mood tag | 不硬编码BGM文件路径 | M3 自动配乐 |
| 证据/线索 ID 全局唯一 | 不同案件的证据ID不能重复 | PCG生成器+校验器需要全局去重 |
| `case.json` 头部预留 `meta` 字段 | `"meta": { "generator_version": "manual", "template_id": null }` | 区分手写与PCG生成的案件 |

### 犯罪骨架模板（供参考）

PCG 已定义的模板类型，手写案件也可参考这些"故事骨架"获取灵感：

| 模板 | 难度 | 核心模式 |
|------|------|---------|
| `old_grudge_poisoning` | ★4 | 旧怨+慢性毒杀+嫁祸 |
| `jealousy_fall_disguised` | ★3 | 情敌+坠楼伪装自杀 |
| `impersonation_inheritance` | ★5 | 冒名顶替+遗产争夺+多重身份 |

### 资产库现状与扩充

| 资产类型 | 当前规模 | 公测目标 |
|---------|---------|---------|
| 演员库 | 22 个 | 25-30 |
| 场景库 | 9 个 | 15-18 |
| BGM 库 | 8 首 | 12-15 |

**新案件如需新演员/场景**：
1. 先检查现有库是否有匹配标签的资产
2. 若无，在 `manifest.json` 中标记 `"art_status": "placeholder"`
3. 在 `art_todo` 中记录需要的新资产
4. 新资产就绪后更新注册表 + 改 `art_status` 为 `"partial"` 或 `"full"`

### 美术资产硬性规则（R1-R5）

| 规则 | 内容 |
|------|------|
| **R1** | 新场景（location）必须有独立背景图，不可复用其他案件的背景 |
| **R2** | 序章/开场背景 ≠ 案发现场背景（保证开场仪式感） |
| **R3** | 核心NPC必须有专属立绘，不可与同案其他NPC共享演员 |
| **R4** | `art_status` 三档：`placeholder`(占位) / `partial`(部分) / `full`(完整) |
| **R5** | 占位期必须在 manifest 中写明 `art_todo` 列表，标记缺失资产 |

> **发布约束**：`art_status` 为 `placeholder` 的案件不可对外发布，仅供内部测试。
