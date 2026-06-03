# 元背景与长期路线图 · Detective Program

> 起草日期：2026-05-17  
> 作用：归档"推理精英选拔计划"这一系列推理游戏的元背景设计、长期路线和分阶段落地方案。本文是策划与工程共识文档，后续实现以此为基准。

---

## 1. 元背景设定（meta lore）

将现有零散的"古风推理案件"重新定位为一个更大的世界框架：

> 玩家是某个秘密机构「**推理者计划**（Detective Program）」征召的真实推理者。  
> 系统通过一系列不同时空、不同风格的"模拟推理事件"（即每一个案件）来选拔与训练能力。  
> 每完成一个案件，玩家的 **推理等级（Detective Rank）** 提升，并解锁更高难度 / 不同风格的案件。  
> 最终需要多名调查员合作面对一个"真正的世界级谜题"——**拯救世界**。

### 1.1 这套元设定带来的好处

- 解释了案件可以跨风格、跨时代（明清古风、近现代、奇幻、未来均可）
- 解释了双人 / 多人合作不突兀（同一机构同一计划的调查员被连接）
- 提供了一个明确的收束终点（终章）
- 不需要现有古风案件让步：临川驿、浔阳楼仍以"古风模拟卷宗"身份存在

### 1.2 命名建议

- 计划名：`Detective Program`（中文：推理者计划 / 调查员计划）
- 玩家角色统一称：`Investigator` / 调查员
- 调查员个人标识：`codename`（代号），不一定是真名
- 终章代号：`Final Case` / `世界级谜题`

---

## 2. 系统层次概览

整个体系分为两层：

### 2.1 Meta 层（玩家本人，跨案件）

- 调查员档案（codename / rank / xp / 通关记录）
- 案件解锁状态
- meta 线索（每个案件埋一片）
- meta 偏好与设置

### 2.2 Case 层（具体案件，案件内）

- 现有模型完全保留：`manifest.json` / `case.json` / `locations.json` / `dialogues/...` / `schedules.json` / `voice_profiles.json` 等
- 仅新增**可选的 meta 字段**：rank_required / style / category / theme_pack / meta_clue / rewards

两层之间通过"案件结算"产生交互：通关 → 给 XP → 更新 rank → 解锁新案件 → 可能拼上一片 meta 线索。

---

## 3. 需要新增/扩展的内容

### 3.1 数据

- `user://investigator.json`：调查员个人档案（持久化，跨案件）
- `data/cases/_index.json` 字段扩展：rank_required / style / category / theme_pack
- 每个案件 `manifest.json` 字段扩展：theme_pack / rewards / meta_clue
- `data/meta/ranks.json`（新增）：等级曲线
- `data/meta/themes/`（新增）：theme pack 资源索引

### 3.2 UI

- 主标题屏 → 调查员主屏（个人终端 + 案件列表 + 等级条）
- 通关结算屏（结局画面之后追加 XP / rank up / 解锁提示）
- 案件卡（带 rank/style/coop 标签）

### 3.3 引擎能力

- `InvestigatorService` autoload：负责加载/保存调查员档案、加 XP、检查解锁
- 案件结算钩子：在 `GameManager.judge_accusation` 完成后通知 InvestigatorService
- theme pack 切换（先抽接口，不必立即多主题）

---

## 4. 跨风格 / 跨时代支持

后续案件可能是：

- 明清古风（现有）
- 近现代（民国 / 现代日系本格 / 黑色硬汉派）
- 异国（西方维多利亚 / 北欧雪夜 / 蒸汽朋克）
- 未来 / 科幻 / 软奇幻

要点：

- 引擎层（GameManager / DialogueManager / MapPanel / RightMenu / 笔记本 / 指证）**保持不变**
- 视觉表现通过 `theme_pack` 切换：颜色、字体、按钮装饰、对话框边框、过场动效
- 资源命名仍按"案件 ID"隔离：`data/cases/<id>/...`、`assets/cn/voices/<actor>/<case>/...`
- 不同主题可以共享一些通用组件（指证仪式、日切过场骨架），但风格皮肤换掉

---

## 5. 双人 / 多人合作案件（coop）

放在中长期落地。设计前提：

- 在元层"两位调查员被同一个计划连接"，叙事自然
- 数据上：`data/cases/<id>/coop.json` 定义两个角色、两条调查线、共享/私有线索映射、协作触发器
- 信息分配：共享 vs 私有
- 时间同步：建议统一时段，每方在每段时间内行动一次
- 指证阶段需两人都同意
- 技术路线：**先 hot-seat 本地两人共用一台设备**，验证机制后再扩展联机

---

## 6. 终章 / 拯救世界

设计要点：

- 必须 rank ≥ 上限
- 必须前面所有案件都通关
- 引入"前面每个案件中埋的一片 meta 线索"
- 多人合作完成（即使 coop 阶段先 hot-seat，也保持"叙事上是合作"）
- 终章不限定古风风格，可以打破第四面墙：揭示"推理者计划"的真相

前提工作：所有案件从一开始就需要预埋 `meta_clue` 字段。

---

## 7. 分阶段落地（迭代顺序）

| 阶段 | 目标 | 工作量 | 备注 |
|------|------|--------|------|
| **P0 当前**（已完成） | 引擎 + 两个独立案件 + 语音 + UI | — | 已具备完整可玩闭环 |
| **P1（下一步）** | Meta 层与等级系统 | 小，1–2 周 | 调查员档案 + 主屏改造 + 结算给 XP（**本文档第二部分详细设计**） |
| **P2** | 主题包抽离 | 中，1 周 | 把现有古风 UI 抽成 `ming_qing` 主题包；为现代/异国案件留接口 |
| **P3** | Meta 线索 / 终章框架预埋 | 小，1 周 | 给现有 2 案补 `meta_clue`，记录到 investigator |
| **P4** | 第三案件：现代 / 异国风 | 大，3–4 周 | 验证非古风也跑同一引擎 |
| **P5** | 双人合作原型 | 大，4 周 | hot-seat 模式先验证 |
| **P6** | 终章合作收束 | 大 | 在前面所有内容稳定后做 |

---

## 8. 设计原则

- **元层不能破坏单案体验**：单独玩任何一个案件仍是完整故事
- **现有案件零破坏**：不强制要求老案件支持新机制，只通过"默认值"接入
- **theme 切换不能改变核心 UX**：按钮位置、对话框结构、笔记本结构、指证流程保持一致；只换皮
- **meta 线索要"自然出现"**：不要变成生硬收集任务

---

# 第二部分 · P1 设计：调查员档案 / 等级 / 通关结算

> 本节是 P1 的具体设计，作为下一步实现的依据。  
> 目标：在不破坏现有任何案件玩法的前提下，把"玩家"这一概念从单案抽出，形成跨案件的成长曲线，为后续 theme 包、coop、终章打好基础。

---

## 1. 目标

1. 玩家有一份持久档案：代号、等级、累计经验、已通关案件、解锁案件
2. 标题屏升级为"调查员主屏"，显示当前等级与可玩案件
3. 案件通关后自动结算 XP，更新等级与解锁
4. 不破坏现有两案的存档、对话、推理流程

---

## 2. 数据模型

### 2.1 调查员档案 `user://investigator.json`

```jsonc
{
  "version": 1,
  "codename": "陆昭",            // 玩家自取，默认 = "无名调查员"
  "rank": 2,
  "xp": 240,
  "xp_to_next": 400,             // 由 ranks.json 计算得到，可缓存
  "cleared_cases": {
    "linchuan_inn": {
      "best_ending": "perfect",  // perfect/good/partial/bad/timeout
      "first_cleared_at": "2026-05-17T20:14:00",
      "play_count": 1,
      "earned_xp": 180
    },
    "xunyang_pavilion": {
      "best_ending": "good",
      "first_cleared_at": "...",
      "play_count": 1,
      "earned_xp": 120
    }
  },
  "unlocked_cases": ["linchuan_inn", "xunyang_pavilion"],
  "meta_flags": {},              // 终章预留：拼图 / 暗号 / 隐藏触发
  "settings_ref": "settings.cfg" // 现有 SettingsService 不动
}
```

> 路径选择：与案件存档 `user://saves/<case>.json` 区分，**永不与案件存档绑定**。卸载 / 重置某个案件存档不应清掉调查员档案。

### 2.2 等级曲线 `data/meta/ranks.json`

```jsonc
{
  "_comment": "Rank 表。当前共 5 级，留 6~10 给未来扩展。",
  "ranks": [
    { "rank": 1, "title": "实习侦探",  "xp_required": 0   },
    { "rank": 2, "title": "见习调查员", "xp_required": 200 },
    { "rank": 3, "title": "正式调查员", "xp_required": 500 },
    { "rank": 4, "title": "高级调查员", "xp_required": 900 },
    { "rank": 5, "title": "首席调查员", "xp_required": 1400 }
  ],
  "ending_xp": {
    "perfect": 200,
    "good": 140,
    "partial": 80,
    "bad": 30,
    "timeout": 20
  },
  "replay_xp_multiplier": 0.3,    // 重玩同案件给 30%
  "first_clear_bonus": 50         // 首次通关额外 +50
}
```

### 2.3 案件索引 `data/cases/_index.json` 字段扩展

为了不破坏现有解析，新增字段都给默认值：

```jsonc
{
  "default_case": "linchuan_inn",
  "cases": [
    {
      "id": "linchuan_inn",
      "manifest": "res://data/cases/linchuan_inn/manifest.json",
      "order": 1,
      "locked": false,
      "tag": "首部曲",
      "voice_status": "full",

      // 新增 ↓（向后兼容）
      "rank_required": 1,
      "style": "ming_qing",
      "category": "solo",
      "base_xp_ending": null,    // null 表示用 ranks.json 默认
      "preview_blurb": "万历廿三年，临川夜雨。古井旁的诡案，等你来明断。"
    },
    {
      "id": "xunyang_pavilion",
      "manifest": "res://data/cases/xunyang_pavilion/manifest.json",
      "order": 2,
      "locked": false,
      "tag": "二部曲",
      "voice_status": "full",
      "rank_required": 2,
      "style": "ming_qing",
      "category": "solo",
      "preview_blurb": "浔阳夜雨，红绸断处。是失足，还是被推下楼？"
    }
  ]
}
```

字段说明：

- `rank_required`：解锁所需等级。低于该等级时在主屏列表里灰显
- `style`：仅用于 UI 标签和将来选 theme，运行时不读
- `category`：`solo` / `coop_2p` / `final`，决定走哪条入口
- `base_xp_ending` / `preview_blurb`：可选

### 2.4 案件 manifest 字段扩展（可选）

为后续案件预留，但**现有两案先不强制改**：

```jsonc
{
  // 旧字段保留
  "id": "...",
  "title": "...",
  ...

  // 新增（全部可选）
  "theme_pack": "ming_qing",
  "meta_clue": {
    "id": "shard_03_yin",
    "name": "玉简·阴",
    "description": "通关此案后，调查员档案中浮现的一片不属于这个时代的玉简。",
    "unlock_at_ending": ["perfect", "good"]
  },
  "rewards": {
    "xp_override": null,            // 不填则用 ranks.json
    "unlock_cases": []              // 通关后额外解锁哪些案件 ID
  }
}
```

---

## 3. 引擎结构

### 3.1 新增 autoload：`InvestigatorService`

文件：`scripts/core/InvestigatorService.gd`，注册为 autoload。

职责：

- 启动时加载 `user://investigator.json`，缺失则创建默认档案
- 加载 `data/meta/ranks.json` 等级曲线
- 提供以下接口：
  - `get_codename()` / `set_codename(name)`
  - `get_rank()` / `get_rank_title()` / `get_xp()` / `xp_to_next_rank()`
  - `add_xp(amount: int) -> Dictionary`：返回 `{rank_up: bool, old_rank, new_rank}`
  - `record_case_cleared(case_id, ending_id) -> Dictionary`：内部计算 XP、更新 cleared_cases、检查解锁
  - `is_case_unlocked(case_id) -> bool`
  - `get_visible_cases() -> Array`：返回主屏要显示的案件列表（含锁定态）
- 提供信号：
  - `xp_changed(new_xp, delta)`
  - `rank_changed(old_rank, new_rank)`
  - `case_cleared(case_id, ending_id, earned_xp)`
  - `case_unlocked(case_id)`

### 3.2 GameManager 钩子

`scripts/core/GameManager.gd` 中 `judge_accusation()` 完成后追加：

```gdscript
# 现有逻辑得到 ending_id 后：
if Engine.has_singleton("InvestigatorService") or get_node_or_null("/root/InvestigatorService"):
    var iv := get_node_or_null("/root/InvestigatorService")
    if iv:
        iv.record_case_cleared(ACTIVE_CASE, ending_id)
```

注意：

- timeout 结局也算"已结束"，给少量 XP
- 不要在 `judge_accusation` 内部 emit 主屏 UI，由 `InvestigatorService` 自己发信号

### 3.3 主屏改造（HomeScreen）

把现有"标题屏 + 案件选择面板"重组为：

- 顶部：`代号：xx    Lv.x（rank_title）    [xp_bar] xp/xp_to_next`
- 中部：案件卡列表，按 order 排序
  - 已通关：金色边、显示"最佳结局"
  - 进行中（有存档）：标"⏳ 进行中"
  - 已解锁未玩：可点
  - 未解锁：灰显 + `Lv.X 解锁`
  - 终章 / coop：特殊样式（暂时仅显示 placeholder）
- 底部：[继续上次进度] [选择案件] [设置] [退出]
- 第一次进入时弹一次"设置代号"

实现路径：

- 改 `MainGame.gd` 的 `_show_title()` 中"标题按钮组"生成逻辑
- 或者新建 `scripts/ui/HomeScreen.gd` + 场景文件，由 `MainGame` 实例化

建议先在现有标题屏基础上**渐进式增强**：先在顶部加调查员状态条，再把案件卡列表替代原"选择案件"按钮的二级面板。

### 3.4 通关结算屏

`scenes/ui/EndingScreen.tscn` 之后追加一个轻量结算覆盖层（或在 EndingScreen 内部加段动画）：

```
本案结局：「明镜高悬」
本次获得经验：+180 XP
（首次通关 +50 奖励）

[XP 进度条动画]

→ 你升到了 Lv.3 「正式调查员」
→ 新案件解锁：「港口失踪案」
```

事件流：

```
GameManager.judge_accusation
  → set_state(STATE_ENDING)
  → InvestigatorService.record_case_cleared(...)
  → MainGame._show_ending(ending_id)
     - 显示原结局
     - 监听 InvestigatorService.case_cleared / rank_changed
     - 在结局界面追加结算段
```

---

## 4. 文件清单

P1 阶段会新增 / 修改的文件：

- 新增
  - `data/meta/ranks.json`
  - `scripts/core/InvestigatorService.gd`
  - （可选）`scripts/ui/HomeScreen.gd` / `scenes/ui/HomeScreen.tscn`
  - 若选 EndingScreen 内增强，则不新增场景
- 修改
  - `project.godot`：注册 InvestigatorService autoload
  - `data/cases/_index.json`：新增 `rank_required` / `style` / `category` / `preview_blurb`
  - `scripts/core/GameManager.gd`：在 `judge_accusation` 完成后通知 InvestigatorService
  - `scripts/main/MainGame.gd`：标题屏顶部加调查员状态条；案件卡显示锁定 / 已通关
  - `scripts/ui/CaseSelectPanel.gd`：根据 unlocked 状态决定可点 / 灰显
  - `scripts/ui/EndingScreen.gd`：追加 XP / 升级 / 解锁信息

---

## 5. 兼容与回滚

- **首次启动**：未发现 `user://investigator.json` → 自动创建一份默认档案（rank=1, xp=0, codename=空，弹设置代号）
- **现有玩家**：原有 `user://saves/<case>.json` 保留，案件存档不动；通关时自动补 cleared_cases 记录
- **缺失字段**：`_index.json` 没填 `rank_required` 默认视为 1（不锁）
- **若关闭 InvestigatorService**：所有改动走 `has_singleton` 判断，缺失时游戏仍可正常通关，只是不写档案、不结算

---

## 6. 验收清单（P1）

完成 P1 时应满足：

- [ ] 首次启动出现"设置代号"流程
- [ ] 主屏顶部能看到代号、等级、XP 进度
- [ ] 案件卡能正确显示 锁定 / 已解锁 / 进行中 / 已通关 + 最佳结局
- [ ] 完成一个案件后：结算页面显示获得 XP、是否升级、是否解锁新案件
- [ ] 重玩同案件给 30% XP（参数可调）
- [ ] 不引入新平台依赖、不破坏现有两案存档
- [ ] 静态回归通过：`python3 tools/regression/run_static.py`

---

## 7. 待决策项

下列问题需要在 P1 实施前确认（建议默认值如下）：

| 项目 | 候选 | 建议默认 |
|------|------|----------|
| 最大 rank 数量 | 5 / 10 | **5**，留扩展 |
| 是否允许跳关（高 rank 可挑战低 rank 锁） | 是 / 否 | **否**：保持解锁顺序，但允许重玩已通关案件 |
| bad/timeout 结局是否给 XP | 是 / 否 | **是**，少量（鼓励再试） |
| 重玩 XP 比例 | 0~1.0 | **0.3** |
| 代号是否被 NPC 称呼 | 是 / 否 | **暂否**（不破坏现有"陆大人"称呼） |
| 终章是否一次性 | 是 / 否 | **否**（已通关后可重玩） |
| coop 优先 hot-seat 还是联网 | hot-seat / 联网 | **hot-seat 优先** |

---

## 8. 时间预估

P1 拆解（按建议默认值）：

| 任务 | 预估 |
|------|------|
| ranks.json + InvestigatorService 骨架 | 0.5 天 |
| 主屏顶部状态条 + 代号设置流程 | 1 天 |
| 案件卡显示锁定 / 已通关 / 最佳结局 | 1 天 |
| 通关结算（XP / 升级 / 解锁） | 1 天 |
| `_index.json` 字段扩展 + 旧案件接入 | 0.5 天 |
| 联调 + 静态回归 | 0.5 天 |
| **合计** | **约 4.5 天 / ~1 周** |
