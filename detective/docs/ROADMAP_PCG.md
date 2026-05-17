# 《七日蝉鸣》PCG 路线图

> **起草日期**: 2026-05-17  
> **范围**: 程序化案件生成（Procedural Case Generation）从 0 → 1 → N 的实现路径  
> **关联文档**: [DEV_PLAN.md](DEV_PLAN.md)（总开发计划）、[GDD_01_ScriptEngine.md](GDD_01_ScriptEngine.md)（脚本引擎设计）

---

## 0. 路线图全景

```
       【M1 PCG 主线】          【M2 资产抽象层】          【M3 PCG × 资产闭环】
       ───────────────         ──────────────────         ─────────────────────
       骨架模板          ┐    演员库 / 场景库 / BGM库   ┐    选角策略
       约束校验器        ├──→ AssetResolver 间接层      ├──→ 自动装配
       对话树派生        ┘    临川驿案迁移              ┘    跨案件复用
       手写案件→生成案件      硬编码清零                     N 案规模化
```

**核心约束**：M1 必须先完成，证明"程序化生成的剧本能在 Godot 内被加载并通关"；M2 在 M1 之后立刻开展，否则 M1 产出的剧本仍然依赖手工美术。M3 是两者合流后的稳定态。

---

## M1 · PCG 主线先行（必须先完成）

> **目标**：在不动现有资产体系的前提下，先把"程序化生成 → 校验 → 加载 → 通关"的纵切链路打通。这是整个 PCG 体系的脊柱，资产抽象是它的左右臂——没有脊柱，臂没处长。

### M1.1 犯罪骨架模板（Crime Skeleton）

| 任务 | 产出 | 说明 |
|------|------|------|
| 定义骨架 Schema | `tools/pcg/schemas/template_schema.json` | 描述案件类型/动机类别/受害者类别/凶手类别/手法类别/关键物证槽位/时间线槽位 |
| 制作 10+ 骨架模板 | `tools/pcg/templates/*.json` | 毒杀、密室、坠楼伪装、走失、冒名顶替、家族秘辛、劫案误伤、连环案首发等 |
| 骨架可视化检查工具 | `tools/pcg/inspect_template.py` | 给定模板渲染出"动机/手法/关键时间点"三视图，方便审稿 |

**完成标志**：人工审阅 10 套骨架，每套都能讲出一个完整侦探故事的"骨"。

### M1.2 填槽生成器（Filler）

| 任务 | 产出 | 说明 |
|------|------|------|
| 角色槽位填充 | `tools/pcg/fillers/character_filler.py` | 暂用占位姓名/年龄/职业/动机，**不指定立绘和声线**（M2 接管） |
| 时间线填充 | `tools/pcg/fillers/timeline_filler.py` | 把骨架中的关键时间点扩展为 D1-D7 + 时段的完整时间表，含 NPC 行程 |
| 物证/线索填充 | `tools/pcg/fillers/clue_filler.py` | 按"必要证据 / 干扰证据 / 矛盾证词"三类铺设 |
| 主生成器 CLI | `tools/pcg/generate.py` | `python generate.py --template poison_killing --seed 42 → case.json` |

**完成标志**：单条命令产出语义完整的 `case.json`，含 6-10 个 NPC 占位、8-12 个地点占位、~30 条线索。

### M1.3 约束校验器（Validator）

| 任务 | 产出 | 说明 |
|------|------|------|
| 时间线一致性 | `validator/timeline_check.py` | 凶手作案时间不冲突；NPC 不分身；不在场证明可被证伪 |
| 物证可达性 | `validator/clue_reachability.py` | 必要证据均能被玩家在 D1-D7 内通过合法路径获得 |
| 可解性 | `validator/solvability.py` | 至少存在一条"凶手+动机+手法+证据"组合能通过指认判定 |
| 矛盾合法性 | `validator/contradiction_check.py` | 矛盾对必须可被现有证据揭露，不能成为永久死循环 |
| 校验报告 | `validator/report.md` | 失败原因可读，便于回滚到生成器调参 |

**完成标志**：100 次随机生成中 ≥ 95 次通过校验；失败用例自动写入 `tools/pcg/regression/`。

### M1.4 对话树派生（Dialogue Derivation）

| 任务 | 产出 | 说明 |
|------|------|------|
| NPC 知识层定义 | `data/cases/{case_id}/knowledge/{npc_id}.json` | "这个 NPC 知道什么 / 愿意说什么 / 在何条件下松口" |
| 对话节点派生 | `tools/pcg/dialogue_gen.py` | 根据知识层 + 信任度阈值自动派生选项树（不写自然语言对白时先用骨架文本） |
| LLM 修辞润色（可选） | `tools/pcg/llm_polish.py` | 把骨架文本转成符合古代背景的台词，离线批处理 |

**完成标志**：生成的对话树可被 Godot 现有 `DialogueManager` 直接加载，玩家能完整问出案件所有必要线索。

### M1.5 Godot 端加载器

| 任务 | 产出 | 说明 |
|------|------|------|
| `ScriptLoader.gd` | `scripts/core/ScriptLoader.gd` | 读取 `case.json` → 注入 `GameManager` 状态 |
| 开局流程 | "选择预制案件 / 加载生成案件" 二选一 UI | 临川驿案保留为预制 |
| 通关验证 | 至少 1 个生成案件能从序章打到结局 | 美术资产可仍用临川驿案的同款（M2 解决） |

**M1 验收**：选择"加载生成案件"，可完整游玩通关；当前所有立绘/语音可能错位（同一个立绘被多个角色复用），但**逻辑上完整可玩**。这是有意识的"先打通再美化"。

---

## M2 · 资产抽象层（紧接 M1）

> **目标**：把 M1 暴露的"立绘错位、语音错配"问题彻底解决——引入演员制和资产注册表，让 M1 生成的案件可以"选角"而不是"手工调资产"。

> **依据**：与 [DEV_PLAN.md](DEV_PLAN.md) W14.5 节点完全对应，详细设计另见 `.codebuddy` 中的 asset-abstraction-system 计划。

### M2.1 三大注册表

| 注册表 | 文件 | 内容 |
|--------|------|------|
| 演员库 | `data/actors/registry.json` | actor_id → {display_name, portrait, voice_config, tags} |
| 场景库 | `data/scenes/registry.json` | scene_id → {name, background, tags, mood} |
| BGM 库 | `data/bgm/registry.json` | track_id → {file, tags, mood, tempo} |

**关键**：演员/场景/BGM 都带**标签**（性别/年龄/职业/气质/室内外/紧张温馨…），M3 选角时按标签匹配。

### M2.2 AssetResolver 统一解析

| 任务 | 产出 | 说明 |
|------|------|------|
| `AssetResolver.gd` | `scripts/core/AssetResolver.gd` | 入口三件套：`get_portrait(npc_id)` / `get_scene_bg(location_id)` / `get_bgm(mood_tag)` |
| 解析路径 | npc_id → casting.json → actor_id → registry → portrait | 三级跳，全表 O(1) 查询 |
| 兼容回退 | 找不到 casting 时回退到 `npcs.json` 直查 | 临川驿案旧数据零迁移即可继续运行 |

### M2.3 临川驿案迁移（迁移而非重写）

| 任务 | 产出 |
|------|------|
| 把现有 8 个 NPC 注册为演员 | `data/actors/registry.json` 首批条目 |
| 把现有 9 个场景注册为场景库 | `data/scenes/registry.json` 首批条目 |
| 把现有 8 首 BGM 按氛围打标 | `data/bgm/registry.json` 首批条目 |
| 编写 `casting.json`（演员↔角色 1:1 映射） | `data/cases/linchuan_inn/casting.json` |
| `npcs.json` 角色专属字段（名字/头衔/介绍）迁入 casting | npcs.json 瘦身为 NPC 行为定义 |
| `locations.json` 加 `scene_type` 字段 | 引用场景库 |
| `bgm_config.json` 用 `mood_tag` 替代硬编码 | 替代 `BgmPlayer.BGM_MAP` |

### M2.4 运行时改造（最小侵入）

| 文件 | 改动 |
|------|------|
| `scripts/core/VoicePlayer.gd` | 路径解析走 AssetResolver；新目录 `voices/{actor_id}/{case_id}/`，旧路径回退 |
| `scripts/audio/BgmPlayer.gd` | 删除 `const BGM_MAP`，改运行时加载 `bgm_config.json` |
| `scripts/dialogue/DialogueManager.gd` | `_emit_current()` 取 portrait 改走 AssetResolver |
| `scripts/main/MainGame.gd` / `ui/MapPanel.gd` / `ui/RightMenu.gd` | 硬编码资产路径迁入注册表或常量集中区 |

### M2.5 工具与文档

| 任务 | 产出 |
|------|------|
| 注册表校验器 | `tools/pcg/validate_registry.py`（悬空引用、标签拼写、文件存在性） |
| TTS 工具适配新目录 | `tools/generate_voices.py` 输出到 `{actor_id}/{case_id}/` |
| 架构文档 | `docs/ASSET_ARCHITECTURE.md` |

**M2 验收**：
1. 临川驿案在新系统下完整通关，行为与旧版一致；
2. 新建一个"哑案件"——只写 `case.json` + `casting.json`（复用临川驿案的演员、场景、BGM），不新增任何美术，可加载并对话；
3. `validate_registry.py` 通过，CI 钩子就位。

---

## M3 · PCG × 资产闭环（合流）

> **目标**：让 M1 生成器学会调用 M2 的资产库——生成 N 个案件，零美术成本。

### M3.1 选角策略（Casting Picker）

| 任务 | 产出 | 说明 |
|------|------|------|
| 角色画像 → 演员检索 | `tools/pcg/casting_picker.py` | 给定角色标签集（性别+年龄+职业+气质），从演员库选最匹配的 |
| 同案唯一性约束 | 同一案件内不重复用同一个 actor_id | 除非案件本身需要"双胞胎/伪装"等设定 |
| 跨案件分散度 | 跨 case 统计同 actor_id 出现频次，过高时降权 | 防止玩家审美疲劳 |
| 降级匹配 | 标签部分匹配时按权重降级 | 演员库不足时仍能产出可玩案件 |

### M3.2 选景与配乐

| 任务 | 产出 |
|------|------|
| 地点 → 场景库 | `scene_picker.py`：根据地点功能（居住/审讯/案发/交易…）选 scene_id |
| 氛围 → BGM 库 | `bgm_picker.py`：根据案件章节情绪曲线（开局神秘 → 中段紧张 → 结局沉重）选 mood_tag 序列 |
| 一致性约束 | 同一地点跨章节使用同一 scene_id，除非剧情要求"环境变化" | 防止穿帮 |
| **新场景检测** | `scene_picker` 若无标签覆盖度 ≥ 阈值的候选，必须输出 `art_todo.new_scene` 项而非降级匹配 | 对应 ASSET_ARCHITECTURE §6.1 R1 |
| **开场≠案发约束** | 生成器为每个案件分配 `prologue_bg` 与 `main_scene_bg`，必须**指向不同 background 路径**；若两者只能指向同一资产，则强制写入 `art_todo.prologue_bg`（待新绘） | 对应 R2 |

### M3.3 端到端集成

| 任务 | 产出 |
|------|------|
| 生成器主管线 | `python pcg/generate.py --seed N` 一键产出 `case.json` + `casting.json` |
| 装配后校验 | 校验器扩展：检测 casting 是否覆盖所有 NPC、scene 是否覆盖所有 location |
| Godot 加载器扩展 | `ScriptLoader.gd` 同时加载 case.json + casting.json，交给 AssetResolver |
| 批量回归 | `pcg/batch_test.py` 生成 50 个案件 → 抽 10 个在 Godot headless 跑剧本可达性 |

### M3.4 资产库扩充节奏

> 资产库不是一次性建满的，而是按"每 N 个案件，增 K 个演员"节奏滚动扩充。

| 阶段 | 演员库规模 | 场景库规模 | BGM 库规模 |
|------|----------|-----------|-----------|
| M2 完成时 | 8（临川驿案首批） | 9 | 8 |
| M3 试运行 | 15（补足常见职业空缺） | 12 | 10 |
| 公测前 | 20-25（覆盖所有标签组合） | 15-18 | 12-15 |

新增美术按"标签优先级"补足，先补"商人/书生/老妪/官差"等高频职业。

**M3 验收**：
1. 一条命令生成 10 个案件，全部通过校验；
2. 抽 3 个在 Godot 内通关，立绘/语音/场景与角色身份匹配，无明显违和；
3. 单个新案件从"按下生成键"到"在 Godot 内打开"≤ 30 秒。

---

## 里程碑时间盘

| 里程碑 | 周次（对齐 DEV_PLAN） | 准入条件 | 退出条件 |
|--------|---------------------|---------|---------|
| M1 PCG 主线 | W15 – W16 | DEV_PLAN W14 完成（存档+联调） | 生成案件可在 Godot 内通关（美术可错位） |
| M2 资产抽象 | W14.5（提前到 W14 之后立刻插入） | DEV_PLAN W14 完成 | 临川驿案迁移完毕 + 哑案件验证通过 |
| M3 闭环 | W17 – W18 | M1 + M2 均完成 | 10 案批量生成、3 案通关、库扩充计划立项 |

> **执行顺序冲突说明**：M1 与 M2 在时间上存在交叠的可能。建议执行顺序为 **M2 略先于 M1**（即 W14.5 → W15-16），因为：
> - M2 的范围明确、风险低（机械迁移）
> - M2 完成后，M1 在生成阶段就可以直接产出 casting.json，不用走"先错位通关再回头修"的弯路
> - 与 DEV_PLAN.md 已经把 W14.5 排在 W15 前的设计一致

---

## 风险登记

| 风险 | 影响 | 缓冲 |
|------|------|------|
| 模板表达力不足 | 生成案件套路化、玩家审美疲劳 | 模板 ≥ 10 套 + 槽位允许嵌套小骨架 |
| 校验器漏检 | 通关到一半发现死路 | 校验失败用例进回归集；新发现的 bug 模式立即转化为新校验规则 |
| 演员库覆盖不全 | 选角降级匹配产生违和 | 标签优先级 + 必要时人工补图（按使用频次反向驱动美术外包） |
| LLM 润色失控 | 台词出戏、风格不统一 | 离线批处理 + 人工抽检 + 风格 prompt 模板锁定 |
| 跨模块改造耦合 | M2 改运行时打破临川驿案 | 强制兼容回退；每次改动后跑一次完整临川驿案回归 |
| **背景占位导致玩家串戏** | 浔阳楼复用临川驿场景图，玩家无法在视觉上区分案件 | manifest.art_status 三档 + R1/R2 强制校验；占位期仅允许 placeholder/partial，禁止 release |
| **开场图与案发图同图** | 序章氛围与案发现场无视觉差，开场仪式感缺失 | R2 硬约束：preview_image / prologue_bg ≠ main_scene 背景；生成器若选不出第二张，自动写 art_todo |

---

## 立项与归档约定

- 每个里程碑结束写一篇 `docs/REVIEW_PCG_M{n}.md`，记录实际偏差、未覆盖问题、下阶段输入。
- `tools/pcg/` 目录与 `data/cases/` 是 PCG 唯一权威产物源，不允许散落到其他位置。
- 生成器与校验器的版本号写入 `case.json` 头部 `meta.generator_version`，便于回放定位。

---

## 当前状态

- [x] DEV_PLAN.md 已新增 W14.5 资产抽象节点
- [x] 资产抽象专项设计（演员制 + 三大注册表）已落定
- [x] **M2 资产抽象层全部完成** ✅ (2026-05-17)
  - [x] M2.1 三大注册表（演员 8 / 场景 9 / BGM 8）
  - [x] M2.2 `AssetResolver.gd` autoload + 三级路径回退
  - [x] M2.3 临川驿案迁移（`casting.json` + `bgm_config.json` + `locations.scene_type`）
  - [x] M2.4 运行时改造（DialogueManager / MainGame / VoicePlayer / BgmPlayer / TalkPanel / NotebookPanel）
  - [x] M2.5 校验脚本 `tools/validate_registry.py` + `docs/ASSET_ARCHITECTURE.md`
  - [x] M2.6 哑案件 `data/cases/_smoke_test/` 零美术通过校验
  - [x] M2.7 Godot 运行时回归（通过 MCP 自动化）：8 NPC + 6 地点 + 11 BGM 键全绿，主题曲实际播放成功
- [x] **M1.1 犯罪骨架模板层完成** ✅ (2026-05-17)
  - [x] `tools/pcg/schemas/template_schema.json` 完整字段定义（roles/timeline_slots/evidence_slots/contradictions/red_herrings/solution_skeleton/endings_pattern/constraints）
  - [x] `tpl_001_old_grudge_poisoning`（★4，临川驿案脱壳参照）
  - [x] `tpl_002_jealousy_fall_disguised`（★3，情敌伪装坠楼）
  - [x] `tpl_003_impersonation_inheritance`（★5，冒名顶替继承）
  - [x] `tools/pcg/inspect_template.py` 模板可视化检查工具，含 10 条健康检查规则
  - [x] `tools/pcg/README.md` 设计原则 + Schema 速查 + 编写新模板 SOP
- [x] **美术资产规则 R1-R5 立项** ✅ (2026-05-17)
  - [x] ASSET_ARCHITECTURE.md §6.1 写入硬性规则：R1 新场景必须新背景 / R2 开场图≠案发图 / R3 必要时新增立绘 / R4 art_status 三档 / R5 占位期 art_todo
  - [x] 两个现有案件 manifest.json 登记 art_status：linchuan_inn=partial（R2 待补），xunyang_pavilion=placeholder（R1/R2 待补）
  - [ ] validate_registry.py 扩展 R1/R2/R3 发布级校验项（待 art_status=release 案件出现前完成即可）
- [ ] **下一步：M1.2 填槽器**（character/timeline/clue filler，输出 case.json + casting.json + dialogues/*.json）
- [ ] M1.3 约束校验器
- [ ] M1.4 对话树派生
- [ ] M1.5 Godot 端 ScriptLoader 接入
- [ ] M3 闭环（选角策略 + 端到端集成）等待 M1 完成后启动
