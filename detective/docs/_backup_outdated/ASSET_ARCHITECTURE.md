# 资产架构（Asset Architecture）

> **状态**: M2 资产抽象层落地（2026-05-17）  
> **相关计划**: [ROADMAP_PCG.md](ROADMAP_PCG.md) M2 节、[DEV_PLAN.md](DEV_PLAN.md) W14.5  
> **核心思想**: 演员制 —— 把"剧本角色"和"演员（资产实体）"解耦，让资产跨案件复用，新增案件零美术成本。

---

## 1. 总览

### 旧架构（耦合）

案件数据直接写死资产路径，新增案件 = 重画立绘 + 重做语音 + 重画背景：

```
data/cases/linchuan_inn/npcs.json
└── "liu_wenqing": { "portrait": "res://assets/cn/portraits/liu_wenqing.png" }
                                  └── 角色 ID 与立绘文件名硬绑定
```

### 新架构（解耦）

引入"资产注册表 + 选角表 + 资产解析器"三层间接：

```
案件数据层      :  npc_id (柳文卿) ──────────┐
                                              ↓
案件 casting    :  casting.json: liu_wenqing → actor_district_magistrate
                                              ↓
全局资产库      :  actors/registry.json: actor_district_magistrate
                                              ↓
实际文件        :  res://assets/cn/portraits/liu_wenqing.png
                  res://assets/cn/voices/actor_district_magistrate/.../*.wav
```

> 同一个 `actor_district_magistrate` 在案件 A 中扮演"柳文卿（共谋者）"，在案件 B 中可以扮演"周明远（受害者父亲）"——立绘和声线完全复用。

---

## 2. 三大注册表

| 注册表 | 文件 | 主体字段 | 标签维度 |
|--------|------|---------|---------|
| 演员库 | `data/actors/registry.json` | `actor_id → {portrait, voice_config, tags, description}` | 性别 / 年龄段 / 职业类 / 性格类 |
| 场景库 | `data/scenes/registry.json` | `scene_id → {background, tags, mood}` | 室内外 / 场景类型 / 规模 / 情绪基调 |
| BGM 库 | `data/bgm/registry.json` | `track_id → {file, tags, mood, tempo, loop_friendly}` + `mood_index` | 氛围 / 节奏 / 是否适合长循环 |

**注意**：所有注册表都允许带 `_comment`、`_schema` 字段作为内嵌文档，运行时自动跳过。

---

## 3. 案件级数据

每个案件目录 `data/cases/<case_id>/` 内：

| 文件 | 作用 | 是否必需 |
|------|------|---------|
| `casting.json` | 演员→角色映射，承载角色专属信息（姓名、头衔、自我介绍、是否凶手） | 推荐（缺失时回退到 npcs.json 的字段） |
| `locations.json` | 地点定义；通过 `scene_type` 字段引用场景库 | 必需 |
| `bgm_config.json` | 地点/状态 → BGM 标签 / 曲目映射 | 推荐（缺失时回退到 BgmPlayer 内置 BGM_MAP） |
| `npcs.json` | NPC 行为定义（dialogue 入口等）；保留 `portrait/name/title/intro` 作为兼容回退字段 | 必需 |
| 其他 | `case.json / day_events.json / dialogues/* / evidence.json …` 不变 | 视情况 |

### 3.1 casting.json 示例

```json
{
  "case_id": "linchuan_inn",
  "casting": {
    "daoming": {
      "actor_id": "actor_elder_monk",
      "role_name": "道明法师",
      "role_title": "观音庙住持",
      "role_intro": "六十多岁，眼神清明……",
      "is_culprit": true
    }
  }
}
```

### 3.2 bgm_config.json 引用语法

```json
{
  "locations": {
    "guanyin_temple": "mood:solemn",
    "yamen": "track:investigation_dark",
    "post_station": "investigation_dark"
  }
}
```

- `mood:xxx` —— 走 `bgm/registry.json.mood_index` 反查（取首条匹配）
- `track:xxx` —— 直接命中 `tracks` 字典
- 裸字符串 —— 等同于 `track:xxx`

---

## 4. 运行时解析层

`scripts/core/AssetResolver.gd` 是 autoload，提供以下查询接口：

| 方法 | 输入 | 输出 |
|------|------|------|
| `get_actor_id_for_npc(npc_id)` | 角色 ID | 演员 ID（无 casting 时返回 ""） |
| `get_portrait(npc_id, npcs_data)` | 角色 ID + 兼容回退用的 npcs_data | 立绘 res:// 路径 |
| `get_role_info(npc_id, npcs_data)` | 角色 ID | `{name, title, intro, is_culprit}` |
| `resolve_voice_path(npc_id, node_id)` | 角色 ID + 对话节点 ID | wav 路径（自动按三级回退查找） |
| `get_voice_config(npc_id)` | 角色 ID | `{style, pitch}` 供 TTS 工具使用 |
| `get_scene_background(location_def)` | 地点字典 | 背景 res:// 路径 |
| `get_scene_background_by_id(scene_id)` | 场景 ID | 背景 res:// 路径 |
| `resolve_bgm_track(key)` | 地点 ID / mood 标签 / track ID | 真实 track_id |
| `resolve_bgm_file(key)` | 同上 | wav 路径 |

### 4.1 兼容回退链（保证临川驿案任何时刻都可玩）

| 资产 | 优先级 1 | 优先级 2 | 优先级 3 |
|------|---------|---------|---------|
| 立绘 | casting → actor → portrait | 旧 `npcs.json.portrait` | 隐藏头像 |
| 角色名 | casting.role_name | 旧 `npcs.json.name` | npc_id |
| 背景 | scene_type → registry → background | 旧 `locations.json.background` | 不切换 |
| 语音 | `voices/{actor_id}/{case_id}/{node_id}.wav` | `voices/{actor_id}/{node_id}.wav` ⚠ 仅 voice_status=full | **❌ 不再回退到 `voices/{npc_id}/`** |
| 序章 | `voices/_prologue/{case_id}/{node_id}.wav` | `voices/_prologue/{node_id}.wav` ⚠ 仅 voice_status=full | 静默 |
| 事件 | `voices/_events/{case_id}/{evt_id}_{idx}.wav` | `voices/_events/{evt_id}_{idx}.wav` ⚠ 仅 voice_status=full | 静默 |
| BGM | bgm_config → mood/track | `BgmPlayer.BGM_MAP`（旧硬编码） | 静音 |

### 4.2 语音严格隔离（关键防错乱机制）

**问题背景**：同一个 `npc_id`（比如 `ma_san`、`liu_wenqing`）在不同案件中可能扮演完全不同的角色。如果允许跨案件回退，浔阳楼案的 `ma_san` 就会错播临川驿案 `ma_san` 的语音 —— **角色身份、台词内容、情绪全部错位**。

**解决方案**：所有语音必须放在 `voices/{actor_id}/{case_id}/...` 或 `voices/_prologue|_events/{case_id}/...` 路径下；运行时按案件 `manifest.voice_status` 决定是否允许"演员通用台词"作为兜底：

| voice_status | 案件专属（`{actor_id}/{case_id}/`） | 演员通用（`{actor_id}/`） | 旧路径（`{npc_id}/`） |
|--------------|---|---|---|
| `full`     | ✅ 优先 | ✅ 兜底 | ❌ 永不 |
| `partial`  | ✅ 唯一 | ❌ 静默 | ❌ 永不 |
| `missing`  | ⚠ 即使存在也跳过查找，直接静默 | ❌ | ❌ |

**关键规则**：
- 没有语音的案件，**绝不**用任何其他案件的语音兜底——**宁可静默**也不要错乱。
- 序章 / 事件叙述也按案件分槽：`voices/_prologue/<case_id>/...`、`voices/_events/<case_id>/...`

---

## 5. 目录约定

```
detective/
├── data/
│   ├── actors/registry.json          # 演员库
│   ├── scenes/registry.json          # 场景库
│   ├── bgm/registry.json             # BGM 库
│   └── cases/<case_id>/
│       ├── casting.json              # 选角表
│       ├── bgm_config.json           # 案件 BGM 配置
│       ├── locations.json            # 地点定义（含 scene_type）
│       ├── npcs.json                 # NPC 行为（保留兼容字段）
│       └── ...
├── assets/cn/
│   ├── portraits/<actor_id>.png      # 立绘按演员 ID 命名（可与旧 npc_id 同名共存）
│   ├── scenes/<scene_id>.png         # 背景按场景 ID 命名
│   ├── bgm/<track_id>.wav            # BGM 按 track_id 命名
│   └── voices/
│       ├── <actor_id>/<case_id>/<node_id>.wav    # 新规范：演员 + 案件 二级目录
│       ├── <actor_id>/<node_id>.wav              # 跨案件共用台词
│       └── <npc_id>/<node_id>.wav                # 兼容旧目录
└── scripts/core/AssetResolver.gd
```

---

## 6. 新增案件的 SOP

1. **零美术起步**——直接复用现有演员库 / 场景库 / BGM 库即可起步（验证剧本骨架是否成立）。
2. 在 `data/cases/<new_case_id>/` 下创建：
   - `casting.json`：把每个新案件的 npc_id 映射到一个已有 actor_id，注意同案不重复用同一个 actor（除非剧情需要）
   - `locations.json`：每个地点写 `scene_type` 引用场景库
   - `bgm_config.json`：每个地点写 `mood:xxx` 或 `track:xxx`
3. 写好 `npcs.json`（dialogue 入口、初始状态）、`case.json`、`dialogues/*` 等剧本数据。
4. 运行 `python tools/validate_registry.py --case <new_case_id>` 校验引用合法。
5. **进入正式制作前**，按 §6.1 检查美术资产清单——剧本通过校验 ≠ 案件可发布。

### 6.1 案件美术资产硬性规则（Art Asset Rules）

> 这一节是**强约束**：违反任意一条都不允许把案件标记为可发布（manifest.art_status = "release"）。
> 规则的目的是防止"立绘 / 背景 / 序章插图错位 → 玩家串戏"。

#### R1 · 新场景必须新背景（No Scene Reuse Without New Art）

- 新案件如果引入了**任何**当前 `data/scenes/registry.json` 中没有覆盖的场景概念，必须先给场景库新增条目并配套**新绘背景图**，再在 `locations.json` 中通过 `scene_type` 引用。
- 反向规则：**绝不允许**为了省事把"新场景概念"复用旧 `scene_id`（例如把"画舫船头"硬塞 `scene_pleasure_house`），因为画面与文字描述不一致会立刻穿帮。
- 旧场景（`scene_post_station` / `scene_pleasure_house` 等）只能用于**功能与气质都吻合**的地点。

#### R2 · 开场图与案发图必须不同（Prologue ≠ Crime Scene）

- 每个案件至少需要两张主美术：
  1. **序章/开场图**：用于章节开篇的氛围铺陈（注册到 `scene_<case_id>_prologue` 或独立资产）
  2. **案发图**：实际案发地点的背景（在 `locations.json` 中作为 `main_scene` 引用）
- 这两张图**必须是不同的画面**——构图、主体、时段、氛围都应有可识别区分。即便剧情把"案发就发生在序章那个亭子"，序章图也应当采用"事发前空镜 / 远景 / 不同光线 / 不同视角"，与案发图形成对照。
- 检查：`manifest.json.preview_image` 与 `locations[main_scene].scene_type → background` 不能指向同一文件路径。

#### R3 · 新角色气质必要时新增立绘（Actor When Needed）

- 当案件中某个 npc_id 的"性别+年龄+职业+气质"组合**在演员库中没有任何标签覆盖度 ≥ 0.7 的候选**，必须新增 actor 条目 + 新立绘，再在 casting 中引用。
- 不允许把"少女花魁"硬选成"中年知府"演员，再靠对话掩饰——立绘错位是玩家最敏感的违和点。
- 演员复用是优势但有边界：**同一案件内不重复用同一个 actor_id**（双胞胎/伪装等剧情需要除外，需在 casting.json 内显式注释 `_reuse_reason`）。

#### R4 · manifest 必须声明美术状态

每个案件的 `manifest.json` 必须包含 `art_status` 字段，取值：

| art_status | 含义 | 准入条件 |
|------------|------|---------|
| `placeholder` | 仅用占位资产（复用旧背景），用于剧本验证 | 不可发布，仅供内部回归 |
| `partial`  | 已具备开场图+案发图，其他次要场景仍占位 | 可作为 demo，标题界面需挂"美术制作中"角标 |
| `release`  | R1/R2/R3 全部满足，所有引用资产均存在且各自独立 | 可发布 |

校验工具应在 `release` 状态下额外执行 R1/R2/R3 检查（见 §8 校验工具的扩展项）。

#### R5 · 占位期的标识

`art_status != "release"` 时，`preview_image` 允许指向旧场景图，但应在 `manifest.json` 内同时写明 `art_todo`，列出所有待替换/待新增的资产，例如：

```json
{
  "art_status": "placeholder",
  "art_todo": {
    "preview_image":  "需新绘：浔阳楼夜雨远景（替换 spring_wind_tower.png 占位）",
    "main_scene_bg":  "需新绘：浔阳楼后院·坠落痕（pavilion_courtyard 当前复用 post_station）",
    "prologue_bg":    "需新绘：序章夜雨独立画面（不得与案发图同图）",
    "new_actors":     []
  }
}
```

`art_todo` 同时是后续美术外包/AI 生成任务的输入清单。

---

## 7. 资产扩充原则

- **演员库优先按"标签覆盖度"扩充**，而不是凭单个案件需要。每补一个演员，就补足"性别×年龄段×职业类"组合中缺失的格子。
- **场景库按"功能"扩充**：居住/审讯/案发/交易/宗教/野外/水域/官方机构…
- **BGM 库按"情绪曲线"扩充**：神秘 / 紧张 / 温馨 / 肃穆 / 喧闹 / 高潮 / 悲凉 / 释然…
- 每次扩充后必须更新 `_comment` / `description` 字段，并跑 `validate_registry.py`。

---

## 8. 校验工具

```bash
# 校验全部案件
python tools/validate_registry.py

# 仅校验指定案件
python tools/validate_registry.py --case linchuan_inn
```

基础校验项（始终生效）：
- 三大注册表中的所有 portrait / background / wav 文件存在
- BGM mood_index 中所有 track_id 在 tracks 中存在
- 案件 casting.json 中的所有 actor_id 在演员库中存在
- 案件 locations.json 中的所有 scene_type 在场景库中存在
- 案件 bgm_config.json 中的所有 `mood:xxx` / `track:xxx` 引用合法

发布级校验项（仅当 `manifest.art_status == "release"` 时强制）：
- **R1**：案件 `locations.json` 中引用的每个 `scene_type` 必须存在于 `scenes/registry.json`，**且**该场景的 `description` / `tags` 与案件中地点的 `description` 在功能与气质上不冲突（可由人工评审，工具仅做硬性 ID 存在性检查）
- **R2**：`manifest.preview_image`（或 `prologue_bg`）与 `locations[main_scene].scene_type → background` **指向不同文件路径**
- **R3**：`casting.json` 中所有 actor_id 解析后的立绘文件均存在；同案件内 actor_id 不重复（除非 casting.json 中显式标注 `_reuse_reason`）
- **R4**：`art_status` 字段存在，取值在 `placeholder / partial / release` 内
- **R5**：当 `art_status != "release"` 时，`art_todo` 字段必须存在，列出待办美术清单

退出码非 0 即视为校验失败，建议在 CI 中作为提交门禁。

---

## 9. 与 PCG 的衔接（M3）

资产抽象层的最终目的是为 PCG 服务。在 [ROADMAP_PCG.md](ROADMAP_PCG.md) M3 阶段：

- `tools/pcg/casting_picker.py` 根据"角色画像（性别+年龄+职业+气质）"从 `actors/registry.json` 选最匹配的 actor_id。
- `tools/pcg/scene_picker.py` 根据"地点功能"从 `scenes/registry.json` 选 scene_id。
- `tools/pcg/bgm_picker.py` 根据"情绪曲线"从 `bgm/registry.json.mood_index` 选 track_id。
- 生成器输出的 `case.json + casting.json` 通过 `validate_registry.py` 后即可在 Godot 内加载游玩，**全程零新增美术**。

---

## 10. 已知限制与未来工作

- **声线 vs 演员一对一**：目前每个 actor 绑定一组 voice_config，无法表达"同一立绘不同声线"的情况。如需支持，可在 casting 中额外允许覆盖 `voice_config_override`。
- **演员相似度去重**：M3 选角时若需避免相邻案件用同一 actor，应在 actor 中额外打"外观哈希"标签。
- **多语言**：当前仅 `cn` 一套。未来可在路径中插入 `/<lang>/` 维度，AssetResolver 增加 `current_lang` 字段。
- **运行时切换案件**：当前 AssetResolver.load_case() 由 GameManager 启动时调用一次。若未来支持运行时切案件，需要清理 voice 缓存等。
