# GDD 07 — 技术架构与开发路线

> 技术选型、架构概览、开发里程碑

---

## 1. 技术栈

| 组件 | 选择 | 说明 |
|------|------|------|
| 游戏引擎 | Godot 4.x | 已初始化项目，2D 侦探游戏最优选 |
| 脚本语言 | GDScript | Godot 原生，迭代最快 |
| 数据格式 | JSON | 对话树、剧本数据、配置 |
| 剧本生成 | Python + 本地 LLM | 开局前预生成，运行时不调用 |
| 约束校验 | Python | 纯规则校验器 |
| 版本控制 | Git | 当前已初始化 |
| 像素精度 | 16×16 | 基础 Tile/角色/物品单元格尺寸 |
| 调色板 | 16-32 色限定 | 暗色调侦探风，确保全局统一 |
| 美术生成 | AI 生成 + 色键处理 | #FF00FF 背景→去除→透明 PNG |
| 纹理过滤 | Nearest | 保持像素锐利，禁用抗锯齿 |

---

## 2. Godot 项目架构（规划）

```
detective/
├── project.godot
├── docs/                          # 设计文档（当前）
│   ├── GDD_00_Overview.md
│   ├── GDD_01_ScriptEngine.md
│   ├── GDD_02_KnowledgeModel.md
│   ├── GDD_03_DialogueSystem.md
│   ├── GDD_04_PlayerActions.md
│   ├── GDD_05_GameFlow.md
│   ├── GDD_06_ResourceSystems.md
│   └── GDD_07_TechArchitecture.md
│
├── scenes/                        # 场景文件
│   ├── main/                      # 主场景
│   │   ├── MainGame.tscn
│   │   ├── TitleScreen.tscn
│   │   └── GameOver.tscn
│   ├── locations/                 # 地点场景
│   │   ├── town_square.tscn
│   │   ├── bakery.tscn
│   │   └── ...
│   └── ui/                        # UI 场景
│       ├── DialoguePanel.tscn
│       ├── Notebook.tscn
│       ├── MiniMap.tscn
│       └── HUD.tscn
│
├── scripts/                       # GDScript
│   ├── core/                      # 核心系统
│   │   ├── GameManager.gd         # 游戏全局管理
│   │   ├── TimeManager.gd         # 时间系统
│   │   ├── ResourceManager.gd     # 资源管理
│   │   └── SaveManager.gd         # 存档系统
│   ├── npc/                       # NPC 系统
│   │   ├── NPCBase.gd
│   │   ├── NPCKnowledge.gd
│   │   └── NPCSchedule.gd
│   ├── dialogue/                  # 对话系统
│   │   ├── DialogueManager.gd
│   │   ├── OptionFilter.gd
│   │   └── EffectExecutor.gd
│   ├── investigation/             # 调查系统
│   │   ├── EvidenceManager.gd
│   │   ├── ContradictionDetector.gd
│   │   └── DeductionBoard.gd
│   ├── player/                    # 玩家
│   │   ├── PlayerController.gd
│   │   ├── PlayerInventory.gd
│   │   └── CognitiveSystem.gd
│   └── ui/                        # UI 逻辑
│       ├── NotebookUI.gd
│       ├── DialogueUI.gd
│       └── HUDUI.gd
│
├── data/                          # 游戏数据
│   ├── templates/                 # 犯罪模板
│   │   └── template_xxx.json
│   ├── scripts_generated/         # 预生成的剧本
│   │   └── script_xxx.json
│   ├── dialogue_trees/            # 预生成的对话树
│   │   └── npc_xxx.json
│   └── config/                    # 配置
│       ├── balance.json           # 数值平衡参数
│       └── locations.json         # 地点配置
│
├── assets/                        # 美术资源（16×16 像素风，PNG 格式）
│   ├── characters/                # 角色 Sprite（16×16 per frame）
│   ├── tilesets/                  # 场景 Tile 集（16×16 per tile）
│   ├── locations/                 # 场景背景（Tile 拼接）
│   ├── items/                     # 物品图标（16×16）
│   ├── ui/                        # UI 素材（可用 32×32 或 64×64 倍率）
│   └── audio/                     # 音效/音乐
│
└── tools/                         # 开发工具
    ├── script_generator/          # 剧本生成器（Python）
    │   ├── generator.py
    │   ├── validator.py
    │   └── templates/
    └── balance_tuner/             # 数值调试工具
```

---

## 3. 核心系统依赖关系

```
GameManager (中央调度)
    ├── TimeManager (时间推进)
    ├── ResourceManager (资源管理)
    │   ├── CognitiveSystem (认知负荷)
    │   ├── CoinSystem (金币)
    │   └── AlertnessSystem (凶手警觉度)
    ├── DialogueManager (对话系统)
    │   ├── OptionFilter (选项过滤)
    │   └── EffectExecutor (效果执行)
    ├── NPCManager (NPC 管理)
    │   ├── NPCKnowledge (知识系统)
    │   └── NPCSchedule (日程系统)
    ├── InvestigationManager (调查系统)
    │   ├── EvidenceManager (证据管理)
    │   └── ContradictionDetector (矛盾检测)
    └── PlayerController (玩家控制)
        └── PlayerInventory (物品栏)
```

---

## 4. 开发路线图（MVP 三阶段）

### Phase 1: 核心循环验证（4-6 周）

**目标**: 用最小范围验证「探索 → 对话 → 收集线索 → 推理」核心循环

| 任务 | 说明 |
|------|------|
| 场景导航 | 3 个地点，点击移动 |
| 时间系统 | 基础时间推进 |
| 对话系统 | 选项制对话，1 个 NPC，10 个对话节点 |
| 证据系统 | 基础收集和查看 |
| 笔记本 | 线索列表（简化版） |
| 手写剧本 | 1 套手写固定剧本用于测试 |

**验证标准**: 玩家可以通过对话和搜索收集线索，在笔记本中查看

---

### Phase 2: 系统丰富（6-8 周）

**目标**: 完善全部资源系统，增加内容量

| 任务 | 说明 |
|------|------|
| 认知负荷 | 完整实现含阈值效果 |
| NPC 信任度 | 多级信任度影响对话 |
| 凶手警觉度 | 隐藏值 + 凶手反制行为 |
| 金币系统 | 商店 + 送礼 + 道具 |
| 笔记本完善 | 四页签全部实现 |
| 隐秘行动 | 潜入 + 跟踪 + 翻找 |
| 内容扩充 | 6+ NPC，8+ 场景，3 套手写剧本 |
| 结局系统 | 5 种结局分支 |

**验证标准**: 完整一局可从头玩到尾，体验完整

---

### Phase 3: AI 生成 + 打磨（4-6 周）

**目标**: 接入剧本生成器，打磨体验

| 任务 | 说明 |
|------|------|
| 犯罪模板 | 制作 10+ 犯罪骨架模板 |
| 剧本生成器 | Python 工具，模板 + LLM 填槽 |
| 约束校验器 | 自动验证剧本一致性 |
| 对话树生成 | 基于角色知识自动生成对话选项 |
| UI 打磨 | 动画、转场、音效 |
| 数值调平 | 基于测试反馈调整平衡 |
| 重玩性 | 成就系统、速通模式 |

**验证标准**: 可生成不同剧本并完整游玩，体验流畅

---

## 5. 存档系统设计

| 项目 | 说明 |
|------|------|
| 自动存档 | 每天结束时自动存档 |
| 手动存档 | 3 个手动存档槽位 |
| 存档内容 | 当前天数/时段、所有资源值、NPC 状态（信任度/知识 L2）、已获线索、已发现矛盾、全局标记、凶手警觉度 |
| 存档格式 | JSON |
| 反作弊 | 存档哈希校验（防修改） |

---

## 6. 美术资源规格

### 6.1 总体风格

| 项目 | 规格 |
|------|------|
| 美术风格 | 2D Top-Down 极简像素风（类 Undertale） |
| 基础单元格 | 16×16 像素 |
| 调色板 | 限定 16-32 色，暗色调侦探风 |
| 资源格式 | PNG（透明背景） |
| 纹理过滤 | Nearest（像素锐利，禁用平滑） |

### 6.2 各类资源尺寸

| 资源类型 | 尺寸 | 说明 |
|----------|------|------|
| 场景 Tile | 16×16 | TileMap 基础单元 |
| 角色 Sprite | 16×16 per frame | 四方向行走动画，每方向 2-4 帧 |
| 物品图标 | 16×16 | 证据、道具等 |
| NPC 对话头像 | 32×32 或 48×48 | 对话面板中使用，可为 2x/3x 倍率 |
| UI 元素 | 32×32 / 64×64 | 按钮、图标等，按需使用倍率 |

### 6.3 Godot 渲染设置

| 设置项 | 值 | 说明 |
|--------|-----|------|
| Viewport 拉伸模式 | `canvas_items` | 像素完美缩放 |
| Viewport 拉伸纵横比 | `keep` | 保持比例 |
| 默认纹理过滤 | `Nearest` | 全局禁用线性过滤 |
| 设计分辨率 | 320×180 或 384×216 | 低分辨率渲染，窗口放大显示 |

### 6.4 AI 生成工作流

```
1. AI 生成图片（纯紫色 #FF00FF 背景）
2. 色键去除紫色背景 → 导出透明 PNG
3. 像素化缩放至目标尺寸（16×16 / 32×32）
4. 调色板映射（将颜色限定到统一色板）
5. 导入 Godot，设置 Import → Filter = Nearest
```

### 6.5 分阶段美术策略

| 阶段 | 美术状态 |
|------|----------|
| Phase 1-2 | 纯色块占位图 + 极简轮廓像素（功能验证优先） |
| Phase 3 | AI 生成像素素材，统一调色板后替换全部占位图 |
