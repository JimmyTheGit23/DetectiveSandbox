# 《七日蝉鸣》开发计划

> **起草日期**: 2026-05-15  
> **预计总周期**: 14-20 周（约 3.5-5 个月）  
> **开发模式**: 单人/小团队，每周可投入 20-40 小时

---

## 总览甘特图

```
Week  1  2  3  4  5  6  7  8  9  10 11 12 13 14 14.5 15 16 17 18 19 20
      ├──── P1: 核心循环 ────┤
                              ├────── P2: 系统丰富 ──────────┤
                                                              ├ 资产层 ┤
                                                                       ├──── P3: AI + 打磨 ────┤
```

---

## Phase 1: 核心循环验证（W1 – W6）

> **里程碑**: 用 3 个场景 + 2 个 NPC + 1 套手写剧本跑通「探索 → 对话 → 收线索 → 笔记本查看」

### W1 — 项目骨架 & 场景导航

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 搭建 Godot 项目目录结构（scenes/scripts/data/assets） | 空目录 + 占位文件 | P0 |
| 实现 `GameManager` 单例 + 场景切换框架 | GameManager.gd | P0 |
| 制作 3 个占位场景（广场/面包店/旅馆），可点击切换 | .tscn × 3 | P0 |
| 实现小地图 UI（地点列表形式，非真实地图） | MiniMap.tscn | P1 |
| 移动时间消耗逻辑（地点间距离→消耗分钟数） | 移动模块 | P1 |

**本周验收**: 点击地点名可切换场景，HUD 显示当前位置

---

### W2 — 时间系统 & HUD

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 实现 `TimeManager`（天数、时段、游戏内分钟） | TimeManager.gd | P0 |
| 行为消耗时间→时间推进→时段变化 | 时间消耗接口 | P0 |
| HUD 显示：当前天数、时段、时钟 | HUD.tscn | P0 |
| 时段变化→场景可达性控制（夜晚关闭商店等） | 条件检查 | P1 |
| 天结束→自动推进至下一天早晨 | 日切逻辑 | P1 |

**本周验收**: HUD 实时显示 D1 早晨/白天/黄昏/夜晚，行为消耗时间可推进到下一天

---

### W3 — 对话系统（核心）

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 定义对话树 JSON Schema | schema.json | P0 |
| 实现 `DialogueManager`（加载 JSON→显示选项→处理选择） | DialogueManager.gd | P0 |
| 实现 `OptionFilter`（条件检查，决定哪些选项可见） | OptionFilter.gd | P0 |
| 实现 `EffectExecutor`（执行选项效果：获得线索/修改数值） | EffectExecutor.gd | P0 |
| 对话 UI 面板（NPC 头像 + 台词 + 选项按钮列表） | DialoguePanel.tscn | P0 |
| 手写 1 个 NPC（面包师 Tom）的对话树（10+ 节点） | baker_tom.json | P1 |

**本周验收**: 可与面包师对话，选项根据条件动态显示/隐藏，选择后产生效果

---

### W4 — 调查系统 & 证据

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 实现 `EvidenceManager`（证据收集/存储/查询） | EvidenceManager.gd | P0 |
| 场景可交互物品系统（高亮 + 点击检查 + 收集） | InteractableItem.gd | P0 |
| 搜索机制（对区域搜索→发现隐藏物品） | 搜索逻辑 | P1 |
| 在 3 个场景中放置测试证据（5-8 件） | 场景数据 | P1 |
| 手写第 2 个 NPC（旅馆老板娘 Mary）对话树 | innkeeper_mary.json | P1 |

**本周验收**: 可在场景中发现并收集证据，证据显示在物品栏中

---

### W5 — 笔记本系统（简化版）

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 笔记本 UI 框架（Tab 切换） | Notebook.tscn | P0 |
| 线索板页：列出所有已收集的物证和证词 | 线索板 UI | P0 |
| 人物档案页：NPC 头像 + 基本信息 + 信任度 | 人物页 UI | P1 |
| 探索/推演模式切换（Tab 键） | 模式切换 | P1 |
| 线索详情查看（点击线索→展开描述） | 详情弹窗 | P1 |

**本周验收**: Tab 打开笔记本，可查看收集到的线索和 NPC 信息

---

### W6 — 手写剧本 & Phase 1 联调

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 编写完整测试剧本 #1（毒杀案，2 嫌疑人 + 1 凶手） | script_test_001.json | P0 |
| 序章流程（开场对白→警长教学→自由行动） | 序章场景 | P0 |
| 全流程联调：序章→探索→对话→收证据→笔记本 | 修 bug | P0 |
| 基础音效（点击/切换/对话） | .ogg × 5 | P2 |
| Phase 1 回顾：记录问题和改进点 | REVIEW_P1.md | P1 |

**Phase 1 验收**: 玩家可以完成「进入小镇→与 2 个 NPC 对话→收集证据→在笔记本中查看」完整流程

---

## Phase 2: 系统丰富（W7 – W14）

> **里程碑**: 完整一局可从头玩到结局，6+ NPC，8+ 场景，全部资源系统就位

### W7 — 资源系统全面实现

| 任务 | 产出 | 优先级 |
|------|------|--------|
| `CognitiveSystem`（认知负荷增减 + 四级阈值效果） | CognitiveSystem.gd | P0 |
| `CoinSystem`（金币消费 + 商店购买） | CoinSystem.gd | P0 |
| 对话次数限制（每日总次数 + 单 NPC 上限） | 计数器逻辑 | P0 |
| HUD 扩展：显示认知负荷条、金币、对话剩余次数 | HUD 更新 | P0 |
| 认知负荷视觉效果（50+画面失真、70+文字模糊） | Shader / 后处理 | P2 |

**本周验收**: 资源面板完整显示，认知过高时有视觉反馈，金币可消费

---

### W8 — NPC 信任度 & 凶手警觉度

| 任务 | 产出 | 优先级 |
|------|------|--------|
| NPC 信任度系统（0-100，六级阈值影响可用选项） | TrustSystem.gd | P0 |
| 送礼机制（消耗金币提升信任） | 送礼 UI + 逻辑 | P1 |
| `AlertnessSystem`（隐藏凶手警觉度） | AlertnessSystem.gd | P0 |
| 警觉度触发：30%证据销毁、60%假线索、80%推理陷阱 | 事件触发器 | P0 |
| 间接提示系统（物品失踪/证词改变/威胁信） | 提示事件 | P1 |

**本周验收**: 信任度影响对话选项数量，凶手警觉度超阈值触发对应事件

---

### W9 — 隐秘行动系统

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 潜入机制（条件判定 + 发现概率计算） | StealthAction.gd | P0 |
| 跟踪 NPC（选择跟踪→时间消耗→结果反馈） | FollowAction.gd | P1 |
| 翻找/撬锁（工具需求 + 成功/失败分支） | SearchAction.gd | P1 |
| 偷听机制（NPC 间对话的窃听） | EavesdropAction.gd | P1 |
| 被发现后果（信任度归零 + 警觉度上升） | 惩罚逻辑 | P0 |

**本周验收**: 可执行潜入/跟踪等隐秘操作，有成功/失败反馈

---

### W10 — 笔记本完善（四页签）

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 人物档案页完善：关系图谱可视化、嫌疑标记 | 关系图 UI | P0 |
| 时间线页：可视化事件时间轴 + 空白时段高亮 | Timeline UI | P0 |
| 线索板增强：矛盾自动高亮、线索拖拽关联 | 关联编辑器 | P1 |
| 指认页：凶手/动机/手法/证据选择 + 信心度 | Accusation UI | P0 |
| `ContradictionDetector`（自动检测矛盾证词对） | ContradictionDetector.gd | P0 |

**本周验收**: 笔记本四页签全部可用，矛盾自动标记，可在指认页草拟推理

---

### W11 — 结局系统 & 指认判定

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 指认提交流程（D7 限定 + 确认弹窗 + 不可撤回） | 提交逻辑 | P0 |
| 结局判定引擎（匹配凶手/动机/手法/证据→5 种结局） | EndingJudge.gd | P0 |
| 5 种结局场景（完美破案/基本破案/冤案/未解/陨落） | Ending.tscn × 5 | P0 |
| 结局评分系统（6 维度加权评分） | ScoringSystem.gd | P1 |
| 昏迷机制（认知 100→昏迷→损失一天） | 昏迷逻辑 | P1 |

**本周验收**: D7 可提交指认，根据正确性进入不同结局并显示评分

---

### W12-W13 — 内容扩充

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 新增 4 个 NPC（总计 6 个），各含完整对话树 | npc_xxx.json × 4 | P0 |
| 新增 5 个场景（总计 8 个），含可交互物品 | .tscn × 5 | P0 |
| 编写完整剧本 #2（密室案） | script_002.json | P0 |
| 编写完整剧本 #3（坠楼伪装） | script_003.json | P1 |
| NPC 日程系统（不同时段出现在不同地点） | NPCSchedule.gd | P0 |
| 特殊事件脚本（D1 追悼会、D2 深夜外出等） | events.json | P1 |
| 推理陷阱场景（凶手 80% 警觉度触发） | TrapScene.tscn | P1 |

**本周验收**: 3 套完整剧本可选择游玩，NPC 按日程在场景间移动

---

### W14 — 存档系统 & Phase 2 联调

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 存档系统（自动存档 + 3 手动槽位） | SaveManager.gd | P0 |
| 读档/续玩流程 | 存档 UI | P0 |
| 标题画面（新游戏/继续/设置） | TitleScreen.tscn | P0 |
| 七日全流程联调（序章→D1-D7→结局） | 修 bug | P0 |
| Phase 2 回顾：记录问题、收集测试反馈 | REVIEW_P2.md | P1 |

**Phase 2 验收**: 选择剧本后可完整游玩 7 天至结局，所有资源系统正常运转，可存读档

---

### W14.5 — 资产抽象层（演员制） ⭐ PCG 前置依赖

> **里程碑**: 把资产（立绘/场景/语音/BGM）从案件数据中解耦，建立可跨案件复用的资产库；为 W15 剧本生成扫清障碍。

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 设计三大注册表 Schema（演员库 / 场景库 / BGM 库） | `data/actors/registry.json`、`data/scenes/registry.json`、`data/bgm/registry.json` | P0 |
| 实现 `AssetResolver.gd`：统一资产解析（角色 → 演员 → 立绘/语音；地点 → 场景；氛围 → BGM） | AssetResolver.gd | P0 |
| 临川驿案改造：新增 `casting.json`（演员→角色映射），`npcs.json` 中的角色专属信息（名字、头衔、介绍）迁入选角表 | casting.json | P0 |
| 临川驿案改造：`locations.json` 改用 `scene_type` 引用场景库；`bgm_config.json` 改用氛围标签引用 BGM 库 | 案件数据 | P0 |
| `VoicePlayer.gd` 改造：路径解析改用 `AssetResolver`，目录结构升级为 `voices/{actor_id}/{case_id}/{node_id}.wav`，保留旧路径回退 | VoicePlayer.gd | P0 |
| `BgmPlayer.gd` 改造：移除硬编码 `BGM_MAP`，改为从 `bgm_config.json` + 注册表运行时加载 | BgmPlayer.gd | P0 |
| `DialogueManager.gd` 改造：`portrait` 获取改走 `AssetResolver`（角色→演员→立绘） | DialogueManager.gd | P0 |
| 硬编码路径清理：`MainGame.gd` / `MapPanel.gd` / `RightMenu.gd` 中的资产路径迁入注册表或常量层 | 代码清理 | P1 |
| 工具脚本对齐：`generate_voices.py` / `generate_event_voices.py` 输出目录改为 `{actor_id}/{case_id}/`；新增 `validate_registry.py` 校验注册表完整性 | tools/*.py | P1 |
| 文档：撰写 `docs/ASSET_ARCHITECTURE.md`，描述演员制、目录约定、新增案件资产的 SOP | 架构文档 | P0 |
| 兼容性回归：临川驿案在新系统下完整通关一遍，确认无回退 | 回归报告 | P0 |

**本周验收**:  
1. 临川驿案完全通过 `AssetResolver` 间接层运行，无任何案件数据直接引用具体资产路径；  
2. 新增一个"假案件"（仅 1-2 个 NPC），仅通过编写 `casting.json` 即可复用现有所有立绘/语音/场景，无需新增美术资源；  
3. 注册表校验脚本通过，CI 可自动检测悬空引用。

> **美术资产硬性规则（R1-R5）** ⚠ 详见 `docs/ASSET_ARCHITECTURE.md` §6.1
> - **R1**：新案件如引入新场景概念，必须新增背景图，禁止把"画舫"复用为"酒楼"等强行套用
> - **R2**：开场图（preview/prologue）与案发图（main_scene 背景）必须不同——构图、视角、时段、氛围都要可识别区分
> - **R3**：演员标签覆盖度 < 0.7 的新角色必须新增立绘
> - **R4**：每个案件 manifest 必须声明 `art_status` ∈ {placeholder, partial, release}
> - **R5**：非 release 状态必须填 `art_todo` 列出待办美术清单
> 这条规则同时影响 W14.5（注册表/校验扩展）、W15（生成器输出 art_todo）、W19（案件发布前最后一关美术替换）。

---

### 动态行为系统（W14.5 同期落地，2026-05-17）

第二案 `xunyang_pavilion` 已升级为"动态可演"案件，作为 PCG 的能力基线：

- **NPC schedule**：`data/cases/<case>/schedules.json`，每个 NPC 有 D{1..3}_P{0..7} 的位置/活动表，带 default + overrides
- **凶手 culprit_actions**：`data/cases/<case>/culprit_actions.json`，确定时刻 + ±jitter 抖动；每次新游戏用 `case_seed` 解算实际时刻；存档恢复保持一致
- **运行时调度**：`GameManager.get_active_npcs_at(loc, day, period)` + `_run_culprit_tick()`（advance_period 时跑一次）
- **撞见遭遇剧情**：在 `day_events.json` 中以 `auto_play=true` 标识，玩家在凶手行动地点时自动播叙述；不弹按钮、不可错过
- **地图 NPC 徽章**：`MapPanel` 在每个地点标牌右侧显示当前时段实际人数徽章，hover 展开人名

> **未来案件**只要写 `schedules.json` + `culprit_actions.json` 即可启用此机制；缺失时自动回退到静态 `locations.json.npcs`（向后兼容）。

#### TODO（暂记，不阻塞当前节奏）

| 待办 | 范围 | 触发优先级 |
|------|------|-----------|
| 浔阳案 83 条对话/事件语音补录 | `tools/tts/` 批跑（待 TTS 后端确定）；含 4 条新增"撞见遭遇"叙述 + qing_xuan 12 节点破绽对话 + 4 NPC 新增对话 | 案件正式发布前必做；当前 manifest.voice_status=missing |
| schedule 编辑器/可视化工具 | `tools/pcg/inspect_schedule.py`：以时段 × 地点矩阵打印 NPC 流向；冲突高亮（同一 NPC 同时间在两地）| M3 PCG 选角阶段需要 |
| culprit_actions 自动校验 | `validate_registry.py` 加 R6：`leaves_trace.evidence_id` 必须在 evidence.json 中存在 | 写新案件时容易忘 |
| 撞见遭遇支持立绘对话化 | 当前是纯 narration；未来可把"凶手反应"做成立绘+对话+一次选项的小段落 | 体验提升项 |

## Phase 3: AI 生成 + 打磨（W15 – W20）

> **里程碑**: 可自动生成不同剧本并完整游玩，体验流畅。  
> **前置条件**: W14.5 资产抽象层完成 —— 生成器输出的剧本只需选角和挑场景，无需生成新美术。

### W15-W16 — 剧本生成工具链（Python）

> **依赖**: W14.5 资产抽象层。生成器只需挑选演员/场景/BGM 标签，不再生成新美术。

| 任务 | 产出 | 优先级 |
|------|------|--------|
| 定义犯罪骨架模板 JSON Schema（含 casting 占位） | template_schema.json | P0 |
| 制作 10+ 犯罪骨架模板 | template_xxx.json × 10 | P0 |
| 实现剧本生成器（模板选取 + 随机/LLM 填槽 + 自动选角） | generator.py | P0 |
| 选角策略：根据角色标签（性别/年龄/职业）从演员库匹配候选 | casting_picker.py | P0 |
| 实现约束校验器（时间线/物证/可解性/矛盾检查 + 资产引用合法性） | validator.py | P0 |
| 对话树自动生成（基于 NPC 知识层自动派生选项） | dialogue_gen.py | P1 |
| 生成器 CLI + 批量生成测试 | cli.py | P1 |

**本周验收**: 运行 `python generator.py` 可输出完整合法剧本 JSON（含 casting.json），Godot 端无需新增任何美术即可加载游玩

---

### W17-W18 — Godot 接入 & UI 打磨

| 任务 | 产出 | 优先级 |
|------|------|--------|
| Godot 端剧本加载器（读取生成的 JSON + casting → 通过 AssetResolver 装配） | ScriptLoader.gd | P0 |
| 开局流程：选择「生成新剧本」或「选择预制剧本」 | 开局 UI | P0 |
| 演员库扩充：补足常用职业/年龄/性别组合的立绘和声线（目标 15-20 演员） | 演员库资产 | P1 |
| 场景库扩充：补足常用古代场景类型（客栈/衙门/庙宇/集市/书房/卧房...） | 场景库资产 | P1 |
| UI 动画（场景转场、对话气泡、笔记本翻页） | 动画 | P2 |
| 背景音乐 + 环境音效（按氛围标签分类入库） | 音频资源 | P2 |

**本周验收**: 可选择 AI 生成的剧本开局并完整游玩；演员/场景库规模足以支撑至少 5 个不同主题的随机案件

---

### W19-W20 — 数值调平 & 上线准备

| 任务 | 产出 | 优先级 |
|------|------|--------|
| Playtest × 5+（找人试玩收集反馈） | 反馈报告 | P0 |
| 数值平衡调整（时间/认知/金币/信任度曲线） | balance.json 更新 | P0 |
| 成就系统（10-15 个成就） | AchievementSystem.gd | P1 |
| 速通模式（完美破案后解锁） | 速通逻辑 | P2 |
| 设置菜单（音量/文字速度/自动存档开关） | Settings.tscn | P1 |
| 最终 bug 修复 + 性能优化 | — | P0 |
| 打包导出（Windows / macOS / Linux） | 可执行文件 | P0 |
| 发布物料准备（截图/简介/README） | 发布素材 | P1 |

**Phase 3 验收**: 可分发的完整游戏，AI 生成剧本稳定可玩，体验流畅

---

## 风险 & 缓冲

| 风险项 | 影响 | 缓冲策略 |
|--------|------|----------|
| 对话树内容量巨大 | P2 内容扩充可能超时 | 先保证 1 套完整剧本，其余用模板快速复制 |
| 认知负荷视觉效果实现复杂 | Shader 开发耗时 | 先用简单屏幕变色，后期替换 |
| AI 生成质量不稳定 | P3 生成器可能产出不合法剧本 | 约束校验器严格把关，不通过则重新生成 |
| 美术资源不足 | 视觉体验打折 | 优先用占位素材，风格统一比精致更重要 |
| 资产硬编码扩散 | 新增案件需重做美术，PCG 不可行 | W14.5 引入 `AssetResolver` 间接层 + 演员制；新增案件零美术成本 |
| 演员库不够泛化 | 生成的角色撞脸/不匹配剧本设定 | 演员注册表带标签（性别/年龄/职业/气质），生成器按标签筛选；不足时按标签优先级降级匹配 |
| 数值不平衡 | 玩家体验割裂 | 预留 W19-W20 专门调平，配置外置便于热调 |

---

## 每日/每周节奏建议

| 时间 | 活动 |
|------|------|
| 周一 | 回顾上周进度，确认本周目标 |
| 周二-周五 | 开发实现 |
| 周五晚 | 自测当周产出，记录 bug |
| 周末（可选） | 文档更新 + 下周规划 |
| 每阶段末 | 写回顾文档，调整后续计划 |

---

## 当前状态

- [x] 设计文档归档完成（GDD_00 – GDD_07）
- [x] **Phase 1 Week 1 — 搭建项目骨架 & 场景导航** ✅ (2026-05-15)
  - [x] project.godot 配置（384×216 像素渲染、Nearest 过滤、canvas_items 拉伸）
  - [x] GameManager 单例（场景切换、地点配置加载、状态管理）
  - [x] 3 个占位场景（广场/面包店/旅馆）+ 不同背景色区分
  - [x] HUD 显示当前位置名称和描述
  - [x] 小地图 UI（地点列表 + 点击切换 + 移动耗时显示）
  - [x] 地点间距离 → 移动分钟数消耗逻辑
  - [x] 完整目录结构（scenes/scripts/data/assets 全部就位）
- [x] **Phase 1-2 跨周期内容实装**（临川驿案）✅
  - [x] 对话系统（DialogueManager + 对话树 JSON）
  - [x] 序章 / 多日事件 / 多 NPC 对话脚本
  - [x] 角色立绘 + 场景背景 + BGM + TTS 语音全套接入
  - [x] VoicePlayer / BgmPlayer / EvidenceManager 等核心管线就绪
- [x] **W14.5 — 资产抽象层（演员制）** ✅ (2026-05-17)
  - [x] M2.1 三大注册表落地：`data/actors/registry.json`（8 演员）/ `data/scenes/registry.json`（9 场景）/ `data/bgm/registry.json`（8 BGM + mood_index）
  - [x] M2.2 `AssetResolver.gd` 实装并注册为首个 autoload，提供 portrait/role_info/voice_path/scene_bg/bgm_track 统一解析与三级回退
  - [x] M2.3 临川驿案迁移：新增 `casting.json` + `bgm_config.json`，`locations.json` 加 `scene_type` 字段（旧字段保留兼容）
  - [x] M2.4 运行时改造：`DialogueManager` / `MainGame` / `VoicePlayer` / `BgmPlayer` / `TalkPanel` / `NotebookPanel` 全部走 AssetResolver；`GameManager._load_data()` 主动调用 `load_case()`
  - [x] M2.5 工具与文档：`tools/validate_registry.py`（一次过：8/9/8 + 1 案件）+ `docs/ASSET_ARCHITECTURE.md` 架构文档
  - [x] M2.6 验收：哑案件 `data/cases/_smoke_test/`（仅 3 份配置 + 0 美术）通过校验，证明新增案件零美术成本可行
  - [x] M2.7 编辑器内运行时回归（通过 Godot MCP Pro 自动化完成）✅ (2026-05-17)
    - [x] AssetResolver autoload 在游戏运行时正确实例化、加载注册表、加载 case
    - [x] 8 个 NPC 全部 actor_id/portrait/role_info 解析合法（8/8）
    - [x] 6 个地点 scene_type → 背景路径解析合法（6/6）
    - [x] 11 个 BGM 键（含 mood / track 两种语法）解析合法（11/11）
    - [x] 主题曲走新链路成功播放（log: `[BGM] play('main_theme') → main_theme`）
    - [x] 标题画面截图视觉正常
- [ ] **下一步：M1 PCG 主线**（参见 `docs/ROADMAP_PCG.md`）
  - [x] M1.1 犯罪骨架模板 Schema + 3 套模板（poisoning ★4 / fall_disguised ★3 / impersonation ★5）+ inspect_template.py + README
  - [ ] M1.2 填槽生成器（character / timeline / clue filler，输出 case.json + casting.json + dialogues/*.json）
  - [ ] M1.3 约束校验器（时间线 / 物证 / 可解性 / 矛盾）
  - [ ] M1.4 对话树派生（NPC 知识层 → 选项树）
  - [ ] M1.5 Godot 端 ScriptLoader 接入

- [x] **多案件 UI + 第二案件 + 回归基线**（2026-05-17 同期）✅
  - [x] **多案件 UI**：`data/cases/_index.json` 案件索引 + `CaseSelectPanel.tscn/gd` 卡片选择面板 + `GameManager.switch_case()` 切换流程 + 案件分槽存档（`user://saves/<case_id>.json`）+ 旧存档自动迁移
  - [x] **第二案件**：`data/cases/xunyang_pavilion/`（浔阳楼·夜雨红绸案）完整数据：11 份基础 JSON + 7 份 NPC 对话树 + 6 地点 17 搜索点 + 9 件证据 + 2 件日程事件 + 5 档结局。**零美术新增**，全部复用 M2 资产抽象层（8/8 NPC / 6/6 地点 / 12/12 BGM 解析通过运行时回归）
  - [x] **未生成语音清单**：`tools/audit_voices.py` 自动扫描 + `docs/MISSING_VOICES.md` 生成（含每条文本预览、预期 wav 路径、按 NPC→actor 分组），方便未来批量 TTS
  - [x] **回归基线**：`tools/regression/run_static.py`（L1 静态：注册表 + 案件文件齐全 + casting 对齐 + 模板 schema + 语音清单）+ `tools/regression/runtime_check.gd`（L2 运行时：通过 MCP 注入验证）+ `docs/REGRESSION_SOP.md`（含已知陷阱、二层结构、何时跑哪层）—— 作为所有未来任务的退出门禁
