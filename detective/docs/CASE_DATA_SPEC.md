# 案例数据规范（Case Data Specification）

## 目录

1. [概述](#概述)
2. [目录结构](#目录结构)
3. [核心数据文件](#核心数据文件)
4. [对话系统](#对话系统)
5. [证据系统](#证据系统)
6. [地点与搜索](#地点与搜索)
7. [事件系统](#事件系统)
8. [日程与进度](#日程与进度)
9. [编译流程](#编译流程)
10. [验证与测试](#验证与测试)
11. [最佳实践](#最佳实践)

---

## 概述

本规范定义了侦探沙盒游戏（Detective Sandbox）中案例数据的标准格式。作者可以按照此规范提交 CSV 或 Markdown 文件，通过编译工具自动生成游戏运行时所需的 JSON 数据。

### 设计原则

- **数据驱动**：所有游戏内容通过数据表定义，无需修改代码
- **编译生成**：CSV → JSON 的单向编译流程，确保数据一致性
- **模块化**：每个案例独立目录，便于管理和扩展
- **可验证**：提供自动化验证工具，确保数据完整性

---

## 目录结构

```
data/case_tables/
├── {case_id}/                    # 案例 ID（小写字母+下划线）
│   ├── _compiled/                # 编译输出目录（自动生成）
│   │   ├── case.json
│   │   ├── casting.json
│   │   ├── dialogue/
│   │   └── ...
│   │
│   ├── case_info.csv             # 案例基本信息
│   ├── case_meta.csv             # 案例元数据（凶手、动机、结局）
│   ├── characters.csv            # 角色定义
│   ├── locations.csv             # 地点定义
│   ├── location_links.csv        # 地点连接
│   ├── search_points.csv         # 搜索点
│   ├── search_results.csv        # 搜索结果
│   ├── search_sub_choices.csv    # 搜索子选项
│   ├── evidence_items.csv        # 证据/线索
│   │
│   ├── prologue_nodes.csv        # 序章节点
│   ├── prologue_lines.csv        # 序章台词
│   ├── prologue_choices.csv      # 序章选项
│   │
│   ├── dialogue_nodes.csv        # NPC 对话节点
│   ├── dialogue_lines.csv        # NPC 对话台词
│   ├── dialogue_options.csv      # NPC 对话选项
│   │
│   ├── confrontation_lines.csv   # 对峙台词
│   ├── confrontations.csv        # 对峙配置
│   │
│   ├── day_events.csv            # 日间事件
│   ├── day_event_lines.csv       # 日间事件台词
│   │
│   ├── testimony_*.csv           # 证词系统相关
│   ├── npc_state_*.csv           # NPC 状态
│   ├── schedule_*.csv            # 日程安排
│   ├── progression_*.csv         # 进度解锁
│   └── ...
```

---

## 核心数据文件

### 1. case_info.csv - 案例基本信息

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✓ | 案例 ID，小写字母+下划线，如 `prologue_ferry` |
| `title` | string | ✓ | 案例标题，如「渡口沉舟」 |
| `subtitle` | string | | 副标题，如「万历廿二年 · 腊月 · 荆江」 |
| `order` | int | | 排序序号，0 为第一个 |
| `difficulty` | enum | ✓ | 难度：`simple` / `medium` / `hard` |
| `estimated_days` | int | ✓ | 预计游戏天数 |
| `max_days` | int | ✓ | 最大天数限制 |
| `main_scene` | string | ✓ | 主场景 ID |
| `preview_image` | path | | 预览图片路径 |
| `synopsis` | string | ✓ | 案例简介（1-2句话） |
| `intro` | string | | 详细介绍 |
| `era` | string | ✓ | 时代背景，如 `ming_wanli` |
| `locale` | string | ✓ | 地区，如 `cn` |
| `companion` | string | | 同伴角色 ID |
| `is_tutorial` | bool | | 是否为教学关卡 |
| `voice_status` | enum | | 语音状态：`ready` / `missing` |
| `scenes` | JSON | ✓ | 场景文件映射 |
| `files` | JSON | ✓ | 数据文件映射 |
| `directories` | JSON | ✓ | 目录映射 |
| `rewards` | JSON | | 通关奖励 |

**示例：**

```csv
id,title,subtitle,order,difficulty,estimated_days,max_days,main_scene,preview_image,synopsis,intro,era,locale,companion,is_tutorial,voice_status,scenes,files,directories,rewards
prologue_ferry,渡口沉舟,万历廿二年 · 腊月 · 荆江,0,simple,2,2,ferry_inn,res://assets/cn/scenes/prologue_ferry_dock.png,荆江石矶渡，商人溺亡。是暗礁翻船的意外，还是另有蹊跷？,教学序章：石矶渡冬雨命案。,ming_wanli,cn,xia_lingyao,true,missing,"{""prologue"": ""prologue.json"", ""epilogue_meta"": ""epilogue_meta.json""}","{""case"": ""case.json"", ""casting"": ""casting.json"", ""npcs"": ""npcs.json"", ""npc_states"": ""npc_states.json"", ""evidence"": ""evidence.json"", ""locations"": ""locations.json"", ""search_results"": ""search_results.json"", ""progression"": ""progression.json"", ""day_events"": ""day_events.json"", ""bgm_config"": ""bgm_config.json""}","{""dialogues"": ""dialogues/"", ""companion"": ""companion/""}","{""xp"": 50, ""unlock_cases"": [""xunyang_pavilion""]}"
```

### 2. case_meta.csv - 案例元数据

定义案件的核心逻辑：凶手、动机、手法、结局。

| 字段 | 类型 | 说明 |
|------|------|------|
| `key` | string | 元数据键名 |
| `value` | JSON | 元数据值 |

**必需的键值对：**

| key | value 格式 | 说明 |
|-----|-----------|------|
| `culprit` | string | 凶手角色 ID |
| `motive` | string | 主要动机 ID |
| `method` | string | 作案手法 ID |
| `min_evidence_required` | int | 最少需要的证据数量 |
| `key_evidence` | string[] | 关键证据 ID 列表 |
| `suspects` | JSON | 嫌疑人配置 |
| `motives` | JSON | 动机选项 |
| `methods` | JSON | 手法选项 |
| `endings` | JSON | 各结局配置 |

**嫌疑人配置格式：**

```json
[
  {
    "id": "agui",
    "name": "阿贵（死者仆从）",
    "unlock": [],                    // 解锁条件
    "unlock_hint": ""                // 解锁提示
  },
  {
    "id": "shen_qingyue",
    "name": "沈清月（药材商之女）",
    "unlock": [{"flag": "confrontation_triggered"}],
    "unlock_hint": "击破阿贵后解锁"
  }
]
```

**动机/手法配置格式：**

```json
[
  {
    "id": "revenge_greed",
    "name": "图财报复（十二年换二两银）",
    "unlock": [{"evidence": "evidence_dismissal_note"}],
    "unlock_hint": "继续调查后解锁"
  }
]
```

**结局配置格式：**

```json
{
  "perfect": {
    "title": "「舟覆人明」结局",
    "narration": "你揭破了全部真相。\n\n..."
  },
  "good": {
    "title": "「水落石出」结局",
    "narration": "..."
  },
  "partial": {
    "title": "「半截真相」结局",
    "narration": "..."
  },
  "bad": {
    "title": "「沉冤江底」结局",
    "narration": "..."
  },
  "timeout": {
    "title": "「雨停人散」结局",
    "pre_narration": [                  // 超时结局可有前置剧情
      {
        "speaker": "",
        "text": "第三天。清晨。\n\n雨终于停了。"
      }
    ],
    "narration": "两天过去，雨停了。\n\n..."
  }
}
```

### 3. characters.csv - 角色定义

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `npc_id` | string | ✓ | 角色 ID，小写字母+下划线 |
| `name` | string | ✓ | 角色名称 |
| `title` | string | | 角色头衔/身份 |
| `intro` | string | | 角色简介 |
| `dialogue_id` | string | | 对话文件 ID（通常与 npc_id 相同） |
| `actor_id` | string | | 演员 ID（用于配音系统） |
| `portrait` | path | | 头像路径 |
| `always_in_notebook` | bool | | 是否始终显示在笔记本中 |
| `is_victim` | bool | | 是否为受害者 |
| `is_player` | bool | | 是否为玩家角色 |
| `is_culprit` | bool | | 是否为凶手 |

**示例：**

```csv
npc_id,name,title,intro,dialogue_id,actor_id,portrait,always_in_notebook,is_victim,is_player,is_culprit
agui,阿贵,死者仆从,跟随周德茂十二年的老仆。,agui,,res://assets/cn/portraits/prologue_agui.png,,,,
lu_zhao,陆昭,巡按御史,玩家本人。途经石矶渡时被卷入命案。,,actor_imperial_inspector,res://assets/cn/portraits/prologue_lu_zhao.png,,,True,
shen_qingyue,沈清月,药材商之女,浔阳沈氏药材行独女，替父追债。,shen_qingyue,,res://assets/cn/portraits/prologue_shen_qingyue.png,,,,True
```

---

## 对话系统

### 对话节点 (dialogue_nodes.csv)

定义 NPC 对话的节点结构。

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `npc_id` | string | ✓ | 角色 ID |
| `node_id` | string | ✓ | 节点 ID（同一 NPC 内唯一） |
| `is_start` | bool | | 是否为起始节点 |
| `text` | string | | 节点主文本（可选，通常由 dialogue_lines 提供） |
| `emotion` | string | | 情绪状态 |
| `set_flags` | string | | 设置的标志位（分号分隔） |
| `gain_evidence` | string | | 获得的证据 ID |
| `gain_clue` | string | | 获得的线索 ID |
| `trigger_confrontation` | bool | | 是否触发对峙 |
| `confrontation_key` | string | | 对峙配置键名 |
| `end` | bool | | 是否为结束节点 |
| `writer_note` | string | | 作者备注 |

**示例：**

```csv
npc_id,node_id,is_start,text,emotion,set_flags,gain_evidence,gain_clue,trigger_confrontation,confrontation_key,end,writer_note
agui,hub,true,你……你是昨晚同船的那位？听说里正给了你两天。你要问什么……问吧。,crying,,,,,,,
agui,intro,,,,agui_talked_once,,,,,,
agui,confession,,,,confrontation_triggered,,,True,,,
```

### 对话台词 (dialogue_lines.csv)

定义节点内的具体台词。

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `npc_id` | string | ✓ | 角色 ID |
| `node_id` | string | ✓ | 节点 ID |
| `order` | int | ✓ | 台词顺序 |
| `speaker_id` | string | | 说话者 ID（为空则使用 npc_id） |
| `speaker` | string | | 说话者显示名（覆盖角色名） |
| `type` | string | | 台词类型 |
| `text` | string | ✓ | 台词内容 |
| `emotion` | string | | 情绪 |
| `requires` | JSON | | 显示条件 |
| `highlight` | string | | 高亮关键词（分号分隔） |
| `record_type` | string | | 记录类型（如 `testimony`） |
| `record_title` | string | | 记录标题 |
| `record_text` | string | | 记录内容 |
| `record_id` | string | | 记录 ID |

**示例：**

```csv
npc_id,node_id,order,speaker_id,speaker,type,text,emotion,requires,highlight,record_type,record_title,record_text,record_id
agui,intro,1,agui,,,那天晚上……老爷急着过江，老范说夜里也能走。小的只是跟着上了船，哪敢多嘴。,grief,,,,,,
agui,intro,2,agui,,,到了江心，突然船就晃得厉害——然后水就涌进来了！什么都看不见！小的拼命去拉老爷的手，没拉住……,grief,,水涌进来;没拉住,,,,
agui,press_alibi,1,agui,,,小的不会水……当时什么都看不见，只觉得冷。手里好像抓到了一块板子——死死抱住不敢放。,grief,,抱着一块船板,testimony,证词记录：阿贵的生还说法,阿贵声称自己抱着一块船板漂上岸。,
```

### 对话选项 (dialogue_options.csv)

定义玩家可选择的对话选项。

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `npc_id` | string | ✓ | 角色 ID |
| `node_id` | string | ✓ | 节点 ID |
| `order` | int | ✓ | 选项顺序 |
| `text` | string | ✓ | 选项文本 |
| `goto` | string | ✓ | 跳转目标（节点 ID 或特殊值） |
| `type` | string | | 选项类型：`ask` / `press` / `observe` / `confrontation` |
| `requires` | JSON | | 显示条件 |
| `set_flags` | string | | 选择后设置的标志位 |
| `hide_after_visit` | bool | | 访问后隐藏 |
| `min_hub_visits` | int | | 最少访问 hub 次数后显示 |
| `cost_time` | int | | 选择消耗的时间 |

**特殊跳转值：**

- `__exit__`：退出对话
- `__confront__`：进入对峙模式
- `hub`：返回对话中心

**示例：**

```csv
npc_id,node_id,order,text,goto,type,requires,set_flags,hide_after_visit,min_hub_visits,cost_time
agui,hub,1,问问当晚发生了什么,intro,ask,,,,,
agui,hub,2,你和周德茂关系怎样？,ask_relationship,press,"[{""flag"":""agui_talked_once""}]",,,,
agui,hub,3,你是怎么从水里活下来的？,press_alibi,press,"[{""flag"":""agui_talked_once""}]",,,,
agui,hub,4,你被遣散的时候，心里没怨气？,show_dismissal,press,"[{""evidence"":""evidence_dismissal_note""}]",,,,
agui,confession,1,开始对峙,__confront__,confrontation,,,,,
```

---

## 证据系统

### 证据/线索 (evidence_items.csv)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `item_id` | string | ✓ | 证据 ID，小写字母+下划线 |
| `type` | enum | ✓ | 类型：`evidence`（物证）/ `clue`（线索） |
| `category` | string | | 分类 |
| `name` | string | ✓ | 显示名称 |
| `description` | string | ✓ | 详细描述 |
| `hidden` | bool | | 是否默认隐藏 |
| `meta_clue` | bool | | 是否为元线索（影响推理） |
| `icon` | path | | 图标路径 |
| `tags` | string | | 标签（分号分隔） |
| `phase` | string | | 出现阶段 |
| `source` | string | | 来源说明 |
| `writer_note` | string | | 作者备注 |

**示例：**

```csv
item_id,type,category,name,description,hidden,meta_clue,icon,tags,phase,source,writer_note
evidence_hull_hole,evidence,,船底人工破洞,沉船底部有一处明显的人工凿痕。木板边缘整齐，不像撞击所致——更像是被人从内侧用凿子打开的活板。,,,,,,,
clue_wife_suspicion,clue,,周氏的怀疑,周氏说：阿贵这两天表现很反常。案发后他哭得比谁都凶，但平时他跟老爷关系并不好——上船前还被老爷骂了一顿。,,,,,,,
```

**证据与线索的区别：**

- **evidence（物证）**：实体物品或客观事实，可在对峙中出示
- **clue（线索）**：信息或推断，用于解锁对话选项或触发事件

---

## 地点与搜索

### 地点 (locations.csv)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `location_id` | string | ✓ | 地点 ID |
| `name` | string | ✓ | 显示名称 |
| `parent` | string | | 父地点 ID（用于层级结构） |
| `description` | string | | 地点描述 |
| `unlock_phase` | string | | 解锁阶段 |
| `background` | path | | 背景图片路径 |
| `scene_type` | string | | 场景类型 |
| `npcs` | string | | 出现的 NPC（分号分隔） |

**示例：**

```csv
location_id,name,parent,description,unlock_phase,background,scene_type,npcs
ferry_inn,石矶渡·客栈,,江畔一间简陋的客栈，土墙木梁，屋顶漏雨。冬雨绵绵，门口泥泞不堪。,phase_1,res://assets/cn/scenes/prologue_ferry_inn.png,scene_prologue_ferry_inn,li_zheng
zhou_room,周氏房间,ferry_inn,一间狭小的偏房。桌上散着纸笔，墙角堆着包袱行李。,phase_1,res://assets/cn/scenes/prologue_zhou_room.png,scene_prologue_zhou_room,zhou_wife
```

### 地点连接 (location_links.csv)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `from_location` | string | ✓ | 起始地点 ID |
| `target_location` | string | ✓ | 目标地点 ID |
| `name` | string | | 连接显示名称 |
| `description` | string | | 连接描述 |
| `requires` | JSON | | 通过条件 |
| `cost_time` | int | | 通过消耗时间 |

### 搜索点 (search_points.csv)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `location_id` | string | ✓ | 所在地点 ID |
| `point_id` | string | ✓ | 搜索点 ID |
| `name` | string | ✓ | 显示名称 |
| `time_cost` | int | | 搜索消耗时间 |
| `hint_rect` | string | | 提示区域（格式：`x;y;width;height`，0-1 范围） |
| `unlock_condition` | JSON | | 解锁条件 |
| `locked_hint` | string | | 锁定时的提示文本 |

**示例：**

```csv
location_id,point_id,name,time_cost,hint_rect,unlock_condition,locked_hint
ferry_inn,inn_lobby,客栈大堂,0,0.0;0.22;0.75;0.68,,
zhou_room,zhou_desk,桌上纸笔砚台,0,0.245;0.45;0.505;0.45,,
agui_room,agui_clothes,晾着的湿衣物,0,0.057;0.25;0.77;0.4,,
```

### 搜索结果 (search_results.csv)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `location_id` | string | ✓ | 地点 ID |
| `point_id` | string | ✓ | 搜索点 ID |
| `variant_id` | string | | 变体 ID（默认 `default`） |
| `intro_text` | string | | 搜索介绍文本 |
| `narration` | string | | 搜索结果叙述 |
| `gain_evidence` | string | | 获得的证据 ID |
| `gain_clue` | string | | 获得的线索 ID |
| `set_flags` | string | | 设置的标志位 |
| `when` | JSON | | 条件触发（用于变体） |
| `trigger_dialogue` | string | | 触发的对话 ID |
| `time_cost` | int | | 消耗时间 |

### 搜索子选项 (search_sub_choices.csv)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `location_id` | string | ✓ | 地点 ID |
| `point_id` | string | ✓ | 搜索点 ID |
| `variant_id` | string | | 变体 ID |
| `order` | int | ✓ | 选项顺序 |
| `text` | string | ✓ | 选项文本 |
| `narration` | string | | 选择后叙述 |
| `gain_evidence` | string | | 获得证据 |
| `gain_clue` | string | | 获得线索 |
| `set_flags` | string | | 设置标志位 |
| `requires` | JSON | | 显示条件 |

---

## 事件系统

### 日间事件 (day_events.csv)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `event_id` | string | ✓ | 事件 ID |
| `title` | string | ✓ | 事件标题 |
| `hint` | string | | 事件提示 |
| `trigger` | JSON | ✓ | 触发条件 |
| `effects` | JSON | ✓ | 事件效果 |
| `auto_play` | bool | | 是否自动播放 |
| `writer_note` | string | | 作者备注 |

**触发条件格式：**

```json
{
  "all": [                           // 所有条件都满足
    {"evidence": "evidence_hull_hole"},  // 拥有证据
    {"flag": "some_flag"},               // 标志位为真
    {"not": {"flag": "done_flag"}},      // 标志位为假
    {"evidence_count_gte": 2},           // 证据数量 >= 2
    {"day_gte": 2},                      // 天数 >= 2
    {"location": "ferry_inn"}            // 当前在某地点
  ]
}
```

**事件效果格式：**

```json
{
  "set_flag": ["flag1", "flag2"],     // 设置标志位
  "auto_start_confrontation": "key"   // 自动开始对峙
}
```

**示例：**

```csv
event_id,title,hint,trigger,effects,auto_play,writer_note
evt_hull_discovered,人为破坏,（你发现了船底的人工破洞）,"{""all"": [{""evidence"": ""evidence_hull_hole""}, {""not"": {""flag"": ""evt_hull_discovered_done""}}]}","{""set_flag"": [""evt_hull_discovered_done"", ""hull_sabotage_known""]}",,
```

---

## 日程与进度

### 进度阶段 (progression_phases.csv)

定义游戏的时间阶段。

| 字段 | 类型 | 说明 |
|------|------|------|
| `phase_id` | string | 阶段 ID |
| `name` | string | 阶段名称 |
| `day` | int | 触发天数 |
| `description` | string | 阶段描述 |

### 进度解锁 (progression_unlocks.csv)

定义内容的解锁条件。

| 字段 | 类型 | 说明 |
|------|------|------|
| `unlock_type` | string | 解锁类型：`location` / `npc` / `search_point` |
| `target_id` | string | 目标 ID |
| `phase` | string | 解锁阶段 |
| `requires` | JSON | 解锁条件 |

---

## 编译流程

### 前置条件

1. 安装 Python 3.8+
2. 确保 `tools/data_compiler/` 目录完整

### 编译命令

```bash
# 编译指定案例（预览模式，输出到 _compiled 目录）
python tools/data_compiler/compile_case.py prologue_ferry

# 编译并写入运行时目录（正式使用）
python tools/data_compiler/compile_case.py prologue_ferry --write-runtime

# 编译所有案例
python tools/data_compiler/compile_case.py --all
```

### 编译输出

编译后会在 `_compiled` 目录生成以下 JSON 文件：

- `case.json` - 案例核心数据
- `casting.json` - 角色配置
- `npcs.json` - NPC 数据
- `npc_states.json` - NPC 状态
- `evidence.json` - 证据数据
- `locations.json` - 地点数据
- `search_results.json` - 搜索结果
- `progression.json` - 进度配置
- `day_events.json` - 日间事件
- `dialogue/` - 对话文件目录
  - `{npc_id}.json` - 每个 NPC 的对话树

### 验证命令

```bash
# 验证数据完整性
python tools/data_compiler/validate_case_tables.py prologue_ferry

# 验证所有案例
python tools/data_compiler/validate_case_tables.py --all
```

---

## 验证与测试

### 自动验证项

验证工具会检查：

1. **必填字段**：所有标记为必填的字段不能为空
2. **引用完整性**：证据、NPC、地点等 ID 引用必须存在
3. **对话图完整性**：
   - 起始节点必须存在
   - 所有 `goto` 目标必须有效
   - 不能有死循环（除了显式的循环对话）
4. **证据链完整性**：
   - 关键证据必须有获取途径
   - 对峙条件必须可达成
5. **搜索点完整性**：
   - 每个搜索点必须有对应的搜索结果
   - 搜索结果中的证据/线索 ID 必须有效

### 手动测试

编译后可以在游戏中测试：

1. 启动游戏
2. 选择对应案例
3. 按照预期流程游玩
4. 检查：
   - 对话是否正确显示
   - 证据是否正确获取
   - 事件是否正确触发
   - 结局是否可达成

---

## 最佳实践

### 命名规范

- **ID 命名**：小写字母 + 下划线，如 `agui`、`evidence_hull_hole`
- **文件命名**：与 ID 保持一致，如 `agui.json`
- **标志位命名**：描述性名称，如 `agui_talked_once`、`hull_sabotage_known`

### 对话设计

1. **Hub 节点**：每个 NPC 应有 `hub` 节点作为对话入口
2. **选项分层**：
   - `ask`：基础询问，无条件
   - `press`：追问，需要前置条件（如已询问过基础问题）
   - `observe`：观察，需要特定证据或线索
3. **退出选项**：每个节点都应有 `__exit__` 选项
4. **循环设计**：使用 `hub` 节点实现对话循环

### 证据设计

1. **证据分级**：
   - 核心证据：直接指向凶手或手法
   - 辅助证据：提供背景信息或解锁其他证据
   - 红鲱鱼：误导性信息
2. **获取途径**：每个证据至少有一个明确的获取途径
3. **描述质量**：描述应具体、有细节，避免模糊表述

### 事件设计

1. **触发条件**：避免过于复杂的条件组合
2. **防重复**：使用 `not` 条件防止事件重复触发
3. **效果明确**：事件效果应清晰，避免副作用

### 常见问题

**Q: 如何实现条件对话？**
A: 在 `dialogue_lines.csv` 中使用 `requires` 字段，格式为 JSON 条件对象。

**Q: 如何实现多结局？**
A: 在 `case_meta.csv` 的 `endings` 中定义所有结局，通过证据组合和标志位触发不同结局。

**Q: 如何添加新的搜索点？**
A: 
1. 在 `search_points.csv` 添加搜索点定义
2. 在 `search_results.csv` 添加搜索结果
3. 如有子选项，在 `search_sub_choices.csv` 添加

**Q: 如何实现 NPC 状态变化？**
A: 使用 `npc_state_transitions.csv` 定义状态转换规则，或在对话中使用 `set_flags` 改变状态。

---

## 附录

### A. 条件语法

```json
// 拥有证据
{"evidence": "evidence_id"}

// 拥有线索
{"clue": "clue_id"}

// 标志位为真
{"flag": "flag_name"}

// 标志位为假
{"not": {"flag": "flag_name"}}

// 已访问对话节点
{"visited": "npc_id.node_id"}

// 未访问对话节点
{"not": {"visited": "npc_id.node_id"}}

// 证据数量 >= N
{"evidence_count_gte": N}

// 当前天数 >= N
{"day_gte": N}

// 当前在某地点
{"location": "location_id"}

// 组合条件（所有）
{"all": [condition1, condition2, ...]}

// 组合条件（任一）
{"any": [condition1, condition2, ...]}
```

### B. 特殊节点类型

- `time_card`：时间卡片显示
- `centered`：居中显示文本
- `end`：对话结束节点

### C. 情绪列表

- `cold` - 冷淡
- `serious` - 严肃
- `grief` - 悲伤
- `nervous` - 紧张
- `panic` - 恐慌
- `defensive` - 防备
- `shaken` - 动摇
- `crying` - 哭泣
- `worried` - 担忧
- `anxious` - 焦虑
- `determined` - 坚定
- `shocked` - 震惊
- `smirk` - 得意
- `evasive` - 回避
- `angry` - 愤怒
- `cheerful` - 开朗

### D. 参考案例

完整示例请参考：
- `data/case_tables/prologue_ferry/` - 序章「渡口沉舟」
- `data/case_tables/xunyang_pavilion/` - 第一章「浔阳水阁」

---

*文档版本：1.0*
*最后更新：2026-05-30*