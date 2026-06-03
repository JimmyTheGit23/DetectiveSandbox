# 序章「渡口沉舟」成品化改造计划

关联方案：`docs/design/ace-attorney-style-interaction-upgrade.md`

目标版本：把序章从“可玩的教学案”升级为“剧本、美术、交互都可作为正式产品样板的第一案”。

---

## 1. 改造目标

### 1.1 玩家体验目标

玩家最终体验应从：

> 点地点 → 拿证据 → 对话中直接出示 → NPC 认罪

升级为：

> 现场发现异常 → 询问 NPC 记录证词 → 复查现场补强证据 → 公堂逐句审证词 → 抓住破绽出示证据 → NPC 狡辩、改口、崩溃

### 1.2 成品品质目标

- 剧本：有五幕结构、误导线、人物防线、证词链、最终击破爽点。
- 交互：调查、对话、复查、对峙形成闭环，不再让普通对话提前结案。
- 美术：序章所有关键场景、CG、证据卡、对峙背景、NPC 多状态立绘统一成“古风水墨悬疑”风格。
- 演出：发现疑点、记录证词、获得物证、击破谎言都有明确视觉反馈。

---

## 2. 当前问题清单

### 2.1 剧本问题

当前 `data/cases/prologue_ferry/dialogues/agui.json` 中存在普通对话提前破案：

- `【出示遣散字据】`
- `【出示浮囊】`
- `confession` 普通对话自白

当前 `data/cases/prologue_ferry/dialogues/lao_fan.json` 中存在普通对话提前供出共犯：

- `【出示船底破洞证据】`
- `【出示赌债字据】`
- `show_iou` 中老范直接供出阿贵

这会削弱对峙阶段存在感。

### 2.2 交互问题

当前 `case.json` 的 `confrontation.rounds` 仍是“单句谎言 + 选证据”的简化结构，尚未达到文档目标：

- 缺少多句证词浏览。
- 缺少逐句追问。
- 缺少“当前句 + 当前证据”匹配判断。
- 缺少 NPC 分阶段防守、改口、崩溃。

### 2.3 探索问题

当前 `search_results.json` 已能产出证据/线索，但缺少更明确的类型化体验：

- 观察 / 翻找 / 比对 / 复查 / 求证 / 现场复原还未在数据层清晰表达。
- 关键线索发现后，缺少“证词记录”“疑点记录”“时间线更新”的数据闭环。
- 复查热点逻辑还不够强，例如“先听老范撞礁说，再回残船复查钉眼”。

### 2.4 美术问题

已有基础资源：

- 场景：`prologue_cold_open.png`、`prologue_ferry_inn.png`、`prologue_ferry_dock.png`、`prologue_wreck_site.png`、`prologue_river_bend.png`、`prologue_ferry_map.png`
- CG：`prologue_cg_zhou_kneel.png`、`prologue_cg_lingyao_rush.png`、`prologue_cg_letter.png`
- 立绘：`prologue_agui.png`、`prologue_lao_fan.png`、`prologue_zhou_wife.png`、`prologue_fisherman_wang.png`、`prologue_li_zheng.png`

缺口：

- 阿贵、老范没有多情绪状态立绘。
- 对峙阶段缺少专属公堂 / 临时审断场景。
- 关键证据缺少证据卡图标。
- 缺少击破演出素材：墨字、斩线、证据飞入、NPC 崩溃差分。
- 场景缺少可调查局部特写图：船底破洞、浮囊、遣散字据、赌债字据、湿信。

---

## 3. 新版五幕剧本结构

### 第一幕：雨夜沉船，表面真相

目标：建立“夜船撞礁翻覆”的表面解释。

内容：

- 开场 CG：三日阴雨、周氏跪求、残船拖上岸。
- 阿贵哭诉：“船突然晃，水涌进来，我抱船板活下来。”
- 老范说：“水涨礁没，谁知撞上暗礁。”
- 凌瑶只提示异常：“说法都顺，但太顺了。”

产出：

- 证词：阿贵“抱船板活下来”。
- 证词：老范“撞礁说”。
- 疑点：两名生还者都把事故说成天灾。

### 第二幕：第一个异常，船不是撞坏的

目标：玩家通过现场勘查发现“人为破坏”。

调查链：

1. 观察残船外部，只看到破洞被淤泥糊住。
2. 听老范说“撞礁裂船”。
3. 复查残船船底，镜头推进，发现整齐凿痕与两圈钉眼。
4. 记录疑点：破洞不像撞击。
5. 获得物证：船底人工破洞、船底钉痕。

产出：

- 物证：`evidence_hull_hole`
- 物证：`evidence_nail_marks`
- 疑点：船底活板被拆装过。

### 第三幕：红鲱鱼，老范高度可疑

目标：让玩家合理怀疑老范，但不让老范直接供出阿贵。

调查链：

1. 钱里正说明暗礁是本地常识。
2. 老范被追问航道后转移责任：“客人催得急。”
3. 翻找老范杂物，发现赌债字据。
4. 王大爷证实老范生还时间有矛盾。
5. 老范压力上升，但只承认“判断失误”“怕担责”，不认合谋。

产出：

- 物证：`evidence_gambling_iou`
- 线索：`clue_wrong_channel`
- 线索：`clue_fan_alibi_hole`
- 误导：老范看起来像主犯。

### 第四幕：阿贵露出破绽

目标：让玩家从“老范主犯”转向“阿贵主谋 / 共同作案”。

调查链：

1. 周氏说阿贵上船前被骂、即将被遣散。
2. 搜周氏房间获得遣散字据。
3. 观察阿贵衣物：外衣湿、里衣只微潮。
4. 调查阿贵房间得到可疑包袱线索。
5. 复查下游芦苇丛，发现牛皮浮囊。
6. 王大爷补充深夜密谈。

产出：

- 物证：`evidence_dismissal_note`
- 物证：`evidence_float_bladder`
- 线索：`clue_agui_dry_inner`
- 线索：`clue_secret_meeting`
- 证词：阿贵“抱船板活下来”。

### 第五幕：公堂对峙，三轮击破

目标：把所有调查成果用于对峙，不在普通对话中提前认罪。

三轮结构：

| 轮次 | 主题 | 破绽句 | 击破证据 | 结果 |
|---|---|---|---|---|
| 第一轮 | 阿贵如何生还 | “谁也不可能提前准备逃生。” | `evidence_float_bladder` | 阿贵改口：浮囊是捡的 / 别人塞的 |
| 第二轮 | 沉船原因 | “船是撞礁裂开的。” | `evidence_hull_hole` / `evidence_nail_marks` | 阿贵推给老范 |
| 第三轮 | 杀人动机 | “老爷待我不薄，我没有害他的理由。” | `evidence_dismissal_note`，追加 `evidence_gambling_iou` | 阿贵崩溃，供出合谋 |

---

## 4. 数据与脚本改造计划

### P0：核心对峙可玩化

目标：先让 `ConfrontationPanel` 达到文档中的逆转式基础体验。

改造项：

1. 扩展 `case.json` 对峙数据结构：
   - `rounds[].statements[]`
   - `statements[].press_dialogue`
   - `solution.statement_id`
   - `solution.evidence`
   - `wrong_reactions`
   - `break_level`: `normal` / `key` / `final`
2. 改造 `scripts/ui/ConfrontationPanel.gd`：
   - 支持上一句 / 下一句。
   - 支持追问当前证词。
   - 支持对当前证词出示证据。
   - 错误扣信心。
   - 正确击破后进入下一轮。
3. 保持兼容旧 `lie + counter_evidence` 数据，避免其他案子断裂。
4. 增加 GM 入口：直接进入序章对峙并补齐关键证据。

验收标准：

- 玩家能在一轮中浏览至少 4 句证词。
- 玩家必须选中正确句子并出示正确证据才能击破。
- 错误证据、错句证据有不同反馈。
- 三轮击破后进入结局结算。

### P1：序章剧本逆转化

目标：删除普通对话提前破案，重写调查与对话链。

改造文件：

- `data/cases/prologue_ferry/dialogues/agui.json`
- `data/cases/prologue_ferry/dialogues/lao_fan.json`
- `data/cases/prologue_ferry/dialogues/zhou_wife.json`
- `data/cases/prologue_ferry/dialogues/fisherman_wang.json`
- `data/cases/prologue_ferry/dialogues/li_zheng.json`
- `data/cases/prologue_ferry/search_results.json`
- `data/cases/prologue_ferry/evidence.json`
- `data/cases/prologue_ferry/progression.json`
- `data/cases/prologue_ferry/day_events.json`
- `data/cases/prologue_ferry/case.json`

具体动作：

1. 阿贵普通对话：
   - 删除 `show_dismissal`、`show_bladder`、`confession` 认罪链。
   - 替换为“问话 / 追问 / 观察 / 试探 / 记录”。
   - 阿贵最多露怯、改口、转移，不认罪。
2. 老范普通对话：
   - 删除直接出示船底破洞和赌债字据导致供认的链路。
   - 老范只承认“怕担责”“欠债”，不承认合谋。
3. 凌瑶提示降直白度：
   - 从“肯定人为”“去指证吧”改为“这里说法不合”“也许该回现场看看”。
4. 增加证词记录：
   - 阿贵“抱船板活下来”。
   - 阿贵“老爷待我很好”。
   - 老范“撞礁说”。
   - 老范“水涨礁没”。
5. 增加复查闭环：
   - 老范提出撞礁说后，船底热点进入“可复查”。
   - 发现可疑包袱后，下游芦苇丛热点进入“可复查”。

验收标准：

- 普通调查阶段无法让阿贵或老范认罪。
- 玩家能自然积累三轮对峙所需证据和证词。
- 所有关键结论都由“调查 + 对峙”完成，而非 NPC 直接解释。

### P2：探索表现与记录系统

目标：让搜证从“点击拿线索”变为“分层调查”。

改造项：

1. `search_results.json` 增加结果类型字段：
   - `result_type`: `observation` / `suspicion` / `testimony` / `evidence` / `timeline`
   - `action_type`: `observe` / `search` / `compare` / `recheck` / `verify` / `reconstruct`
2. `SearchOverlay.gd` 支持不同发现演出：
   - 疑点：墨圈标记。
   - 证词：卷宗纸条写入。
   - 物证：证据卡弹出。
   - 时间线：时间轴新增。
3. 热点状态增强：
   - 未调查：微弱呼吸光。
   - 已调查：变暗 / 打勾。
   - 可复查：金色闪烁。
   - 已成证据：小证物标记。
4. 笔记本增加分类呈现：
   - 物证
   - 证词
   - 疑点
   - 时间线
   - 人物关系

验收标准：

- 关键证据获得时有明显卡片化反馈。
- 证词记录区别于物证获得。
- 至少 3 个热点支持条件复查。

### P3：美术成品化

目标：补齐序章作为正式样板案所需的全部视觉资产。

#### 3.1 场景与 CG

| 类型 | 资源建议名 | 用途 | 优先级 |
|---|---|---|---|
| CG | `prologue_cg_shipwreck_rain.png` | 雨夜沉船开场 | 高 |
| CG | `prologue_cg_hull_closeup.png` | 船底破洞特写 | 高 |
| CG | `prologue_cg_float_bladder.png` | 牛皮浮囊发现 | 高 |
| CG | `prologue_cg_confrontation_hall.png` | 临时公堂 / 客栈审断 | 高 |
| CG | `prologue_cg_agui_breakdown.png` | 阿贵最终崩溃 | 高 |
| 局部图 | `evidence_dismissal_note.png` | 遣散字据证据卡 | 中 |
| 局部图 | `evidence_gambling_iou.png` | 赌债字据证据卡 | 中 |
| 局部图 | `evidence_wet_letter.png` | 泡烂密信证据卡 | 中 |

#### 3.2 NPC 多状态立绘

阿贵：

- `normal`：低头怯懦
- `panic`：眼神游移、冒汗
- `defensive`：攥拳辩解
- `cornered`：脸色发白
- `breakdown`：失控崩溃

老范：

- `normal`：老油条、抽烟
- `smirk`：敷衍讥笑
- `defensive`：不耐烦
- `shaken`：烟杆掉落
- `cornered`：低头闪躲

周氏：

- `grief`：悲痛
- `suspicious`：犹疑
- `relieved`：结案释然

凌瑶：

- `thinking`：压低声音提醒
- `alert`：发现异常
- `angry`：对凶手愤怒

#### 3.3 美术生成流程

1. 不把 API 密钥写入仓库、脚本或文档。
2. 使用本机环境变量读取密钥，例如 `GEMINI_API_KEY`。
3. 先生成 `assets/ai_raw/prologue_ferry/` 原图。
4. 人工筛选后移动到：
   - `assets/cn/scenes/`
   - `assets/cn/portraits/`
   - `assets/cn/evidence/`
5. 统一做后处理：
   - 去边缘杂色。
   - 统一色温：冷雨、青灰、旧纸金。
   - 保持 16:9 场景构图。
   - 立绘透明背景，留足右侧边缘，避免裁切。
6. Godot 导入后检查：
   - `.import` 正常生成。
   - UI 中不拉伸变形。
   - 雨雾特效与场景光色统一。

通用提示词方向：

> 明代江南渡口，连日阴雨，水墨厚涂，悬疑推理游戏背景，冷青灰色调，细节清晰，电影感构图，古风写实，no modern objects, no text, no watermark

验收标准：

- 序章关键节点不再复用其他案件视觉。
- 所有关键证据都有图像化呈现。
- 阿贵和老范在对峙中至少各有 4 个状态切换。
- 最终击破有独立 CG 或强演出差分。

### P4：演出与音频 polish

目标：补齐“发现”“记录”“击破”的爽感。

改造项：

1. 发现疑点：
   - 背景暗化。
   - 局部墨圈。
   - 低频鼓点。
2. 记录证词：
   - 卷宗纸条展开。
   - 关键句被墨线圈住。
3. 获得物证：
   - 证据卡飞入笔记本。
   - 盖章音效。
4. 对峙击破：
   - BGM 瞬停。
   - “异议 / 破”字样斩入。
   - 证据卡飞到证词句上。
   - NPC 立绘震动、退后、切状态。
5. 最终击破：
   - 红黑墨爆。
   - 阿贵崩溃差分。
   - BGM 切胜利段。

验收标准：

- 普通击破、关键击破、最终击破视觉等级不同。
- 错误出示有明确但不喧宾夺主的反馈。
- 音频切换不和当前 BGM 冲突。

---

## 5. 推荐实施顺序

### 第 1 轮：先把“逆转式玩法”跑通

范围：P0 + 部分 P1

- 扩展 `ConfrontationPanel` 多句证词。
- 改写 `case.json` 三轮对峙。
- 删除阿贵 / 老范普通对话中的直接认罪链。
- 保证序章可从开场一路通到结局。

### 第 2 轮：重写调查闭环

范围：P1 + 部分 P2

- 重排证据出现顺序。
- 增加证词记录和疑点记录。
- 增加复查热点。
- 降低凌瑶提示直白度。

### 第 3 轮：补齐核心美术

范围：P3 高优先级资产

- 生成并接入对峙背景。
- 生成阿贵、老范多状态立绘。
- 生成船底破洞、浮囊、崩溃 CG。
- 更新数据中的 portrait / scene / evidence icon 引用。

### 第 4 轮：演出 polish

范围：P2 + P4

- 搜证发现卡片化。
- 证词记录演出。
- 击破分级演出。
- 音效和 BGM 状态切换。

### 第 5 轮：成品验收

范围：全流程测试与文本打磨

- 完整通关 3 次：完美、普通、失败。
- 检查所有文本是否仍有“提前给答案”。
- 检查所有 UI 是否溢出。
- 检查所有场景雨、雾、淡入淡出是否合理。
- 检查案件完成后返回案件选择流程。

---

## 6. 分工式任务拆解

### 剧本任务

1. 重写阿贵对话：保留破绽，不给认罪。
2. 重写老范对话：增强红鲱鱼，不提前供出阿贵。
3. 重写三轮对峙证词。
4. 增加证词 / 疑点 / 时间线文本。
5. 重写凌瑶提示，保持“提醒异常，不给答案”。

### 交互任务

1. `ConfrontationPanel` 支持多句证词。
2. `ConfrontationPanel` 支持追问。
3. `ConfrontationPanel` 支持当前句出示证据。
4. 搜索结果类型化。
5. 热点复查状态化。
6. GM 直接进入序章对峙。

### 美术任务

1. 对峙场景。
2. 阿贵状态立绘。
3. 老范状态立绘。
4. 船底破洞特写。
5. 浮囊特写。
6. 阿贵崩溃 CG。
7. 证据卡图标。
8. 击破 UI 素材。

### 验收任务

1. 序章普通调查无提前认罪。
2. 三轮对峙必须通过“句子 + 证据”击破。
3. 完美通关能解释全部证据。
4. 普通 / 失败结局仍能闭合。
5. 所有新图不串风格、不裁切、不含现代物件和文字水印。

---

## 7. 关键改造文件索引

- `data/cases/prologue_ferry/case.json`
- `data/cases/prologue_ferry/dialogues/agui.json`
- `data/cases/prologue_ferry/dialogues/lao_fan.json`
- `data/cases/prologue_ferry/dialogues/zhou_wife.json`
- `data/cases/prologue_ferry/dialogues/fisherman_wang.json`
- `data/cases/prologue_ferry/dialogues/li_zheng.json`
- `data/cases/prologue_ferry/search_results.json`
- `data/cases/prologue_ferry/evidence.json`
- `data/cases/prologue_ferry/progression.json`
- `data/cases/prologue_ferry/day_events.json`
- `scripts/ui/ConfrontationPanel.gd`
- `scripts/ui/SearchOverlay.gd`
- `scripts/ui/NotebookPanel.gd`
- `scripts/main/MainGame.gd`
- `scripts/core/GameManager.gd`
- `scripts/core/InvestigatorService.gd`
- `scripts/ui/SettingsPanel.gd`

---

## 8. 最小可交付版本定义

如果只做一个最小但质量明显提升的版本，应包含：

1. 普通对话不再提前认罪。
2. 三轮多句证词对峙可玩。
3. 阿贵 / 老范至少各 3 个状态立绘。
4. 船底破洞、牛皮浮囊、对峙场景、阿贵崩溃 4 张核心新图。
5. 发现证据与击破证词有明显演出。
6. 序章从开场到结局流程无断点。

这版完成后，序章即可作为后续所有案件的制作模板。
