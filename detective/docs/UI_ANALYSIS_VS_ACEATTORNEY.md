# 游戏 UI 表现/逻辑分析 · 对比逆转裁判

> 分析时间：2026-06-05 | 基于当前代码库全量审查

---

## 一、当前 UI 架构总览

### 1.1 文件结构

| 模块 | 脚本文件 | 场景文件 | 职责 |
|------|---------|---------|------|
| **主控** | [`MainGame.gd`](scripts/main/MainGame.gd) | [`MainGame.tscn`](scenes/main/MainGame.tscn) | 全局协调、面板开关、背景切换、通知 |
| **对话框** | [`DialogueBox.gd`](scripts/ui/DialogueBox.gd:1) (1869行) | 内嵌于 MainGame | NPC对话+叙述+选项，逆转裁判式全屏立绘 |
| **对峙** | [`ConfrontationPanel.gd`](scripts/ui/ConfrontationPanel.gd:1) (3056行) | [`ConfrontationPanel.tscn`](scenes/ui/ConfrontationPanel.tscn) | 交叉询问系统（威慑/举证） |
| **底部菜单** | [`RightMenu.gd`](scripts/ui/RightMenu.gd:1) (391行) | 内嵌于 MainGame | 6个功能按钮（移动/对话/调查/笔记/讨论/地图） |
| **笔记本** | [`NotebookPanel.gd`](scripts/ui/NotebookPanel.gd:1) (1099行) | [`NotebookPanel.tscn`](scenes/ui/NotebookPanel.tscn) | 证物/线索/记录/人物 4个Tab |
| **地图** | [`MapPanel.gd`](scripts/ui/MapPanel.gd:1) (428行) | [`MapPanel.tscn`](scenes/ui/MapPanel.tscn) | 全镇地图+地点标记 |
| **探索** | [`SearchOverlay.gd`](scripts/ui/SearchOverlay.gd:1) (803行) | 叠加层 | 场景热点探索 |
| **探索(旧)** | [`SearchPanel.gd`](scripts/ui/SearchPanel.gd:1) (208行) | [`SearchPanel.tscn`](scenes/ui/SearchPanel.tscn) | 列表式探索 |
| **对话选择** | [`TalkPanel.gd`](scripts/ui/TalkPanel.gd:1) (137行) | [`TalkPanel.tscn`](scenes/ui/TalkPanel.tscn) | NPC选择列表 |
| **移动** | [`MovePanel.gd`](scripts/ui/MovePanel.gd:1) (138行) | [`MovePanel.tscn`](scenes/ui/MovePanel.tscn) | 子地点移动 |
| **讨论** | [`DiscussPanel.gd`](scripts/ui/DiscussPanel.gd:1) (142行) | 无场景（纯代码） | 助手话题选择 |
| **时间过场** | [`DayTransition.gd`](scripts/ui/DayTransition.gd:1) (60行) | 内嵌于 MainGame | 黑屏+打字机时间卡 |
| **打字机** | [`TypewriterEffect.gd`](scripts/ui/TypewriterEffect.gd:1) (276行) | 无（纯逻辑Node） | 逐字显示+节奏控制+音效 |
| **NPC场景层** | [`NpcSceneLayer.gd`](scripts/ui/NpcSceneLayer.gd:1) (297行) | 无（动态创建） | 非对话时NPC常驻立绘 |
| **场景特效** | [`SceneFXLayer.gd`](scripts/ui/SceneFXLayer.gd) | 无（动态创建） | 粒子/氛围特效 |
| **结局** | [`EndingScreen.gd`](scripts/ui/EndingScreen.gd:1) (119行) | 内嵌于 MainGame | 结局文字+进度结算 |
| **设置** | [`SettingsPanel.gd`](scripts/ui/SettingsPanel.gd) | [`SettingsPanel.tscn`](scenes/ui/SettingsPanel.tscn) | 设置/存档/重置 |
| **案件选择** | [`CaseSelectPanel.gd`](scripts/ui/CaseSelectPanel.gd) | [`CaseSelectPanel.tscn`](scenes/ui/CaseSelectPanel.tscn) | 多案件选择 |

### 1.2 所有UI均为代码动态构建

**关键发现：几乎所有 UI 都是在 GDScript 中用 `new()` 动态创建的，而非在编辑器场景中预置。** 仅 [`NotebookPanel.tscn`](scenes/ui/NotebookPanel.tscn)、[`TalkPanel.tscn`](scenes/ui/TalkPanel.tscn) 等少数场景有基础节点树，但内部内容也是代码填充。

这意味着：
- ✅ 灵活，可运行时调整布局
- ❌ 不可在编辑器中预览/调整
- ❌ 调试困难，无法在场景树面板中直观查看
- ❌ 样式分散在各处，难以统一管理

---

## 二、与逆转裁判的 UI 对比分析

### 2.1 对话系统

| 维度 | 逆转裁判 | 本作 | 差距评估 |
|------|---------|------|---------|
| **对话框位置** | 底部固定横条（~1/3高度） | 底部固定横条（[`DialogueBox.gd:79`](scripts/ui/DialogueBox.gd:79) `DIALOGUE_FRAME_HEIGHT=222`） | ✅ 一致 |
| **立绘显示** | 全屏居中大立绘，下半身被对话框遮挡 | 全屏居中大立绘（[`DialogueBox.gd:11`](scripts/ui/DialogueBox.gd:11) `portrait_rect`）+ 左下角头像（主角/助手） | ✅ 已实现，且有创新（主角/助手用小头像） |
| **说话人名字** | 对话框左上角 | 对话框内左上（[`DialogueBox.gd:246`](scripts/ui/DialogueBox.gd:246)） | ✅ 一致 |
| **打字机效果** | 逐字显示+打字音效 | [`TypewriterEffect.gd`](scripts/ui/TypewriterEffect.gd:1) 支持节奏控制、音效profile、暂停标记 | ✅ **超越**（更精细） |
| **点击跳过** | 点击任意处跳过当前文字 | 左键点击跳过（[`DialogueBox.gd:156`](scripts/ui/DialogueBox.gd:156)） | ✅ 一致 |
| **对话日志** | 无原版（重制版有） | 有日志按钮（[`DialogueBox.gd:23`](scripts/ui/DialogueBox.gd:23) `_log_button`） | ✅ 额外功能 |
| **选项系统** | 无（纯线性） | 支持多选项+条件过滤+叙述选项 | ✅ **超越** |

**对话系统结论：已达到或超越逆转裁判水平。**

---

### 2.2 对峙（交叉询问）系统

| 维度 | 逆转裁判 | 本作 | 差距评估 |
|------|---------|------|---------|
| **状态机** | 证词浏览→威慑/举证 | [`State`枚举](scripts/ui/ConfrontationPanel.gd:13) 8个状态（TITLE_ANIM→DEFEAT） | ✅ 更完整 |
| **信心条** | 左上角生命条（脉动动画） | 左上角文字标签（[`ConfrontationPanel.gd:195`](scripts/ui/ConfrontationPanel.gd:195)） | ⚠️ **缺失视觉表现** |
| **证词导航** | ◀▶箭头+圆点指示器 | ✅ 完全实现（[`ConfrontationPanel.gd:308-354`](scripts/ui/ConfrontationPanel.gd:308)） | ✅ 一致 |
| **威慑按钮** | 左侧大按钮 | 底部按钮栏（[`ConfrontationPanel.gd:370`](scripts/ui/ConfrontationPanel.gd:370)） | ⚠️ 位置不同，见下文 |
| **举证按钮** | 右侧大按钮 | 底部按钮栏（[`ConfrontationPanel.gd:392`](scripts/ui/ConfrontationPanel.gd:392)） | ⚠️ 位置不同，见下文 |
| **证据面板** | 全屏证据册（左侧详情+右侧网格） | 居中弹窗（[`ConfrontationPanel.gd:416`](scripts/ui/ConfrontationPanel.gd:416)） | ⚠️ 尺寸偏小 |
| **镜头切换** | 主角说话=左侧滑入，证人=居中 | ✅ [`CAMERA_SWITCH_ENABLED`](scripts/ui/ConfrontationPanel.gd:84) 已实现 | ✅ 一致 |
| **击破动画** | 证词碎裂+闪红 | 有BREAK_ANIM状态 | ⚠️ 需确认演出效果 |
| **证人反应** | 立绘表情变化+抖动 | [`PortraitState`](scripts/ui/ConfrontationPanel.gd:87) NORMAL/SHAKEN/COLLAPSED | ✅ 有状态但演出力度未知 |

#### 🔴 对峙系统核心问题

**问题1：威慑/举证按钮位置不直观**

逆转裁判的威慑（追问）和举证按钮是**屏幕两侧的大按钮**，视觉权重极高，玩家一眼就知道该做什么。本作将它们放在**底部操作栏**（[`ConfrontationPanel.gd:356-411`](scripts/ui/ConfrontationPanel.gd:356)），与证词区紧邻，视觉层级降低。

**问题2：信心条只是文字**

[`_confidence_label`](scripts/ui/ConfrontationPanel.gd:195) 只是一个 `Label`，显示文字而非逆转裁判式的**脉动血条/心形图标**。这大大削弱了紧张感。

**问题3：证物册弹窗尺寸受限**

[`_evidence_panel`](scripts/ui/ConfrontationPanel.gd:416) 固定为 `960×720`（offset -480~480, -360~360），在1280×720的viewport中几乎占满屏幕，但内部Grid只有6列×3页（EVIDENCE_PER_PAGE=18），证物图标偏小。

---

### 2.3 底部菜单栏

| 维度 | 逆转裁判 | 本作 | 差距评估 |
|------|---------|------|---------|
| **菜单位置** | 调查阶段底部横向菜单 | 底部居中牌匾式按钮（[`RightMenu.gd`](scripts/ui/RightMenu.gd:1)） | ✅ 一致 |
| **按钮数量** | 移动/对话/调查（3个） | 移动/对话/调查/笔记/讨论/地图（6个） | ⚠️ 偏多，见下文 |
| **按钮样式** | 图标+文字 | 双行文字（主标题+副标题）无图标 | ⚠️ 缺少图标辨识度 |
| **锁定提示** | 锁定时灰色+tooltip | 有锁定状态+tooltip（[`RightMenu.gd:297`](scripts/ui/RightMenu.gd:297)） | ✅ 一致 |
| **动画** | 无 | 悬浮缩放+颜色变化 | ✅ **超越** |

#### ⚠️ 菜单栏问题

**问题：6个按钮过多**

逆转裁判调查阶段只有3个按钮（移动/对话/调查）。本作6个按钮中，"讨论"和"地图"可以考虑：
- "讨论"在无搭档时隐藏（已实现），但有搭档时仍然增加认知负担
- "地图"可以合并到"移动"中（长距离移动=地图，短距离=子地点移动）
- "笔记"可以改为随时按键（如 Tab 键）呼出，而非占一个菜单位

---

### 2.4 场景表现

| 维度 | 逆转裁判 | 本作 | 差距评估 |
|------|---------|------|---------|
| **背景切换** | 淡入淡出 | [`_set_background()`](scripts/main/MainGame.gd:367) 支持fade | ✅ 一致 |
| **NPC常驻立绘** | 调查场景中NPC立绘居中 | [`NpcSceneLayer.gd`](scripts/ui/NpcSceneLayer.gd:1) 支持1/2/3+NPC分槽 | ✅ **超越**（多NPC支持） |
| **NPC立绘动画** | 待机呼吸+说话口型 | [`_load_animation_frames()`](scripts/ui/DialogueBox.gd:466) 多帧动画+微抖动 | ✅ 有框架，待资源 |
| **场景特效** | 无（2D静态） | [`SceneFXLayer.gd`](scripts/ui/SceneFXLayer.gd) 粒子/氛围 | ✅ **超越** |
| **时间过场** | 文字淡入 | [`DayTransition.gd`](scripts/ui/DayTransition.gd:1) 黑屏+打字机 | ✅ 风格化更好 |

---

### 2.5 笔记本/证据系统

| 维度 | 逆转裁判 | 本作 | 差距评估 |
|------|---------|------|---------|
| **Tab分类** | 证物/人物/记录 | 证物/线索/记录/关键信息/人物（5个Tab） | ✅ 更丰富 |
| **证物详情** | 左图右文 | [`NotebookPanel.gd:79`](scripts/ui/NotebookPanel.gd:79) 列表项含图标+名称+描述预览，点击弹详情 | ✅ 功能完整 |
| **搜索功能** | 无（原版） | 无 | — |
| **证物图标** | 每个证物有独立图标 | 有图标路径系统（[`evidence_icons/`](scripts/ui/NotebookPanel.gd:123)） | ✅ 一致 |

---

### 2.6 地图系统

| 维度 | 逆转裁判 | 本作 | 差距评估 |
|------|---------|------|---------|
| **地图形式** | 无（直接选地点列表） | 全镇地图+可点击标记（[`MapPanel.gd`](scripts/ui/MapPanel.gd:1)） | ✅ **超越** |
| **地点信息** | 简单列表 | 标记+信息面板+NPC在场人数 | ✅ 更丰富 |
| **已访问标记** | 无 | 有visited状态 | ✅ 额外功能 |

---

## 三、核心问题清单（按严重度排序）

### 🔴 P0 · 严重影响体验

#### 1. 对峙模式信心条缺少视觉表现
- **现状**：[`_confidence_label`](scripts/ui/ConfrontationPanel.gd:195) 仅显示文字 "信心: 3/3"
- **逆转裁判**：心形图标+脉动动画+扣血闪红
- **影响**：玩家无法直观感受"再错一次就完了"的紧张感
- **建议**：改用 TextureProgressBar + 心形/玉佩图标，扣血时添加屏幕震动+红色闪烁

#### 2. 对峙威慑/举证按钮位置不直观
- **现状**：底部操作栏（[`ConfrontationPanel.gd:356`](scripts/ui/ConfrontationPanel.gd:356)），与证词区紧邻
- **逆转裁判**：屏幕左侧（威慑）和右侧（举证）的大按钮，视觉权重极高
- **影响**：新手玩家可能不知道该点哪里，降低"主动出击"的爽感
- **建议**：改为屏幕两侧大按钮，或至少放大底部按钮并添加图标

#### 3. 全部UI纯代码构建，无可视化编辑
- **现状**：[`DialogueBox.gd`](scripts/ui/DialogueBox.gd:1) 1869行、[`ConfrontationPanel.gd`](scripts/ui/ConfrontationPanel.gd:1) 3056行，全部用 `new()` 动态创建
- **影响**：
  - 无法在编辑器中预览最终效果
  - 调试时需要运行游戏才能看到布局
  - 修改样式需要阅读大量代码定位
  - 新开发者上手极难
- **建议**：核心面板（对话框、对峙面板）迁移到 `.tscn` 场景文件，仅保留逻辑脚本

---

### ⚠️ P1 · 影响体验

#### 4. 底部菜单按钮缺少图标
- **现状**：[`RightMenu.gd`](scripts/ui/RightMenu.gd:1) 按钮只有双行文字（如"移动/行踪"），无图标
- **assets/cn/ui/` 目录已有图标**：`icon_accuse.png`、`icon_discuss.png`、`icon_map.png`、`icon_move.png`、`icon_notebook.png`、`icon_search.png`、`icon_talk.png`
- **影响**：图标资源已存在但未使用，按钮辨识度低
- **建议**：在按钮中添加对应图标（上方图标+下方文字），提升视觉辨识度

#### 5. 笔记本面板缺少搜索/过滤功能
- **现状**：[`NotebookPanel.gd`](scripts/ui/NotebookPanel.gd:1) 有5个Tab但无搜索
- **逆转裁判**：重制版有搜索功能
- **影响**：证物/线索数量多时（35+条）查找困难
- **建议**：添加顶部搜索栏或按关键词过滤

#### 6. 地图面板缺少"已去过的地点"视觉区分
- **现状**：[`MapPanel.gd`](scripts/ui/MapPanel.gd:98) 有 `visited` 状态但标记样式差异不明显
- **影响**：玩家无法快速区分已探索和未探索地点
- **建议**：未探索地点用暗色标记+问号，已探索用亮色+勾号

#### 7. 设置按钮右上角孤立
- **现状**：[`MainGame.gd:192`](scripts/main/MainGame.gd:192) 设置按钮在右上角，与底部菜单栏分离
- **影响**：设置按钮的位置不符合移动端/手柄操作习惯（通常在菜单内）
- **建议**：将设置按钮移入底部菜单栏最右侧，或在菜单栏上方添加一个小齿轮图标

#### 8. 叙述模式缺少视觉差异化
- **现状**：[`DialogueBox.gd:175`](scripts/ui/DialogueBox.gd:175) 叙述模式复用同一个对话框，仅隐藏立绘
- **逆转裁判**：旁白模式有独特的文字样式（如斜体、不同背景色）
- **影响**：玩家难以区分"NPC说话"和"旁白叙述"
- **建议**：叙述模式下改变对话框颜色/透明度，或使用不同字体样式

---

### 💡 P2 · 锦上添花

#### 9. 对峙证物册可增加"相关性提示"
- **逆转裁判**：部分版本在选中证物时高亮相关证词
- **建议**：在证物详情旁显示"可能与第X句证词相关"的提示

#### 10. 地图可增加"路线动画"
- **逆转裁判**：移动时有简短的行走过渡
- **建议**：地点切换时添加简短的墨笔划线过渡动画

#### 11. 对话选项可增加"助手反应"
- **逆转裁判**：选错选项时助手会吐槽
- **建议**：[`DiscussPanel.gd`](scripts/ui/DiscussPanel.gd:1) 的闲聊系统已有此基础，可扩展到普通对话选项

---

## 四、UI 架构改进建议

### 4.1 样式统一化

当前样式问题：每个面板独立定义 `StyleBoxFlat`，颜色值硬编码在代码中。

**建议**：创建统一的 UI 主题资源：
```
assets/cn/ui/theme_ui.tres
├── BoxColors: ColorPalette (金/纸/墨/红/绿)
├── PanelNormal: StyleBoxFlat
├── PanelHover: StyleBoxFlat
├── ButtonGold: StyleBoxFlat
├── ButtonBlue: StyleBoxFlat (威慑)
└── ...
```

### 4.2 核心面板迁移到 .tscn

优先迁移：
1. **DialogueBox** → `scenes/ui/DialogueBox.tscn`（最常使用）
2. **ConfrontationPanel** → `scenes/ui/ConfrontationPanel.tscn`（已有但内部仍大量代码构建）
3. **RightMenu** → `scenes/ui/RightMenu.tscn`

### 4.3 动画系统统一化

当前动画分散在各处（Tween创建）。建议提取通用动画工具：
```
scripts/ui/UIAnimator.gd
├── flash_screen(color, duration)     # 闪屏
├── shake_node(node, intensity)       # 抖动
├── slide_in(node, direction)         # 滑入
├── pulse_scale(node, amount, speed)  # 脉动
└── fade_in_out(node, in_t, hold, out_t) # 淡入淡出
```

---

## 五、总结

### 做得好的地方（已达到或超越逆转裁判）

1. ✅ **对话系统**：打字机效果、角色音效profile、打字节奏控制超越逆转裁判
2. ✅ **NPC场景立绘**：多NPC分槽位显示、边缘渐隐shader、常驻+对话切换
3. ✅ **探索系统**：场景热点叠加模式（SearchOverlay）比逆转裁判的列表式更直观
4. ✅ **地图系统**：逆转裁判无地图，本作有全镇地图+地点标记
5. ✅ **叙述选项系统**：逆转裁判无此机制，本作支持条件分支叙述
6. ✅ **助手讨论系统**：逆转裁判的助手对话是纯线性的，本作有话题选择+次数限制
7. ✅ **场景特效层**：粒子/氛围效果，逆转裁判无此系统

### 需要改进的地方（对比逆转裁判的差距）

1. 🔴 **对峙信心条**：缺少视觉化表现（心形图标+动画），紧张感不足
2. 🔴 **对峙按钮布局**：威慑/举证按钮位置不直观，应移至屏幕两侧
3. 🔴 **UI全部代码构建**：无可视化编辑，维护成本极高
4. ⚠️ **菜单按钮无图标**：图标资源已存在但未使用
5. ⚠️ **笔记本无搜索**：证物多时查找困难
6. ⚠️ **叙述模式无视觉差异**：与普通对话难以区分
7. ⚠️ **设置按钮位置孤立**：与底部菜单栏分离

### 优先级建议

| 优先级 | 改进项 | 预估工作量 | 影响面 |
|--------|-------|-----------|--------|
| P0-1 | 对峙信心条视觉化 | 1-2天 | 对峙体验 |
| P0-2 | 对峙按钮布局调整 | 1天 | 对峙体验 |
| P0-3 | 核心面板迁移到.tscn | 3-5天 | 长期维护 |
| P1-4 | 菜单按钮添加图标 | 0.5天 | 日常操作 |
| P1-5 | 笔记本搜索功能 | 1-2天 | 信息管理 |
| P1-8 | 叙述模式视觉差异化 | 0.5天 | 叙事体验 |
