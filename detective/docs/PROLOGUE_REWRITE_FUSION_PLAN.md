# 序章《渡口沉舟》融合改写方案

> 状态：计划就绪，待执行
> 创建时间：2026-05-31
> 方案类型：融合方案（新剧本叙事精华 + 现有系统框架）

---

## 一、总体思路

将逆转裁判叙事风格融合进现有序章《渡口沉舟》，**保留已建成的渐进式调查系统、ConfrontationPanel 对峙引擎、证据/线索收集系统**，嫁接新方案的叙事精华（五幕结构、庭审博弈、伏笔体系、序章败局）。

### 核心原则
- 保留船舱自由探索（Phase 0）→ 加入新方案背景设定
- 保留沉船逃生密室系统 → 优化死因细节（蓝色草药迷晕）
- 改造被诬告段落 → 加入王老伯伪证和当庭驳证桥段
- 保留渐进式调查系统 → 重新设计线索链，融入官印暗线和草药香囊伏笔
- 改造两轮对峙 → confrontation（老范+阿贵互相甩锅）+ confrontation_final（沈青月翻盘+序章败局）
- 改造结局 → defeat 流程改为"沈青月翻盘→陆昭惨败→下一章伏笔"
- **新增**：沈清月作为公开对手（讼师身份），贯穿所有对峙场景，形成逆转裁判式三方博弈

---

## 二、核心需求

### 1. 凌瑶角色升级
- **当前**：金鳞镖局跑信的信使
- **改为**：金鳞镖局首席镖师（武艺高强+精通验尸+市井情报搜集+心思敏锐）
- **影响文件**：characters.csv、companion/banter.json、companion/discussions.json、prologue_lines.csv、shore 相关节点

### 2. 王大爷改造为伪证者
- **当前**：打渔老翁，提供一般线索
- **改为**：江边常住百姓，贪小便宜，收周氏银两捏造目击证词
- **当庭驳证桥段**：
  - 破绽1：当夜浓雾遮眼，江岸至商船距离超百丈，肉眼无法分辨人物身形
  - 破绽2：当夜狂风呼啸，浪声震耳，无法听清争执声响，证词自相矛盾
  - 破绽3：陆昭初到此地，与死者仅一面之缘，无财仇私怨，无杀人动机
- **影响文件**：fisherman_wang.json、prologue_lines.csv（码头指控场景）

### 3. 死因优化
- **当前**：直接溺亡（面色青紫，已僵）
- **改为**：被特制蓝色草药迷晕→失去行动能力→随沉船坠入江中溺亡
- **物证链**：
  - 指甲缝隙残留微量特殊蓝色草药碎屑
  - 脖颈处有极淡压痕
  - 该草药市面罕见，仅有少数专职草药商贩持有
- **影响文件**：evidence_items.csv、evidence.json、search_results.json、prologue_lines.csv

### 4. 官印暗线伏笔
- **剧情**：陆昭官印沉船后落入江底 → 被老范拾取 → 老范与沈青月暗线交易 → 官印落入幕后势力
- **后续用途**：可随时用来栽赃陆昭渎职、私藏官印，成为致命隐患
- **影响文件**：evidence.json、agui.json、lao_fan.json、companion/discussions.json、prologue_lines.csv

### 5. 草药香囊伏笔
- **剧情**：沈青月交付定金时遗落专属刺绣香囊 → 但沈青月提前利用客栈后院守卫盲区潜入陆昭客房 → 用高仿赝品调换真品
- **终局翻盘**：沈青月当场指出香囊绣线配色不同、草药配比杂乱缺少核心辅料 → 凌瑶核验证实 → 物证失效
- **影响文件**：evidence.json、shen_qingyue.json、companion/banter.json、confrontation_final testimonies

### 6. 对峙改造（沈清月作为公开对手）
#### confrontation（阿贵中BOSS）
- **当前**：单一对峙阿贵
- **改为**：老范先咬死触礁意外 → 陆昭抛出证据 → 老范慌乱反咬阿贵 → 阿贵否认反泼脏水 → 陆昭双重施压（动机+浮囊采购记录）→ 阿贵心理防线崩塌坦白全部真相
- **沈清月角色**：作为"讼师"出席，为老范/阿贵辩护，质疑陆昭的证据链
  - intro_dialogue：沈清月以"周家生意伙伴"身份出席，发表开场白
  - testimonies 中嵌入她的"异议"：如"陆公子，你所谓的'浮囊采购记录'不过是一张没有署名的收据"
  - 凌瑶搭档提示：穿插对沈清月的怀疑
- **影响文件**：case.json（confrontation 段）、agui.json、lao_fan.json、prologue_lines.csv

#### confrontation_final（沈清月FINAL BOSS）
- **当前**：沈清月对峙，击破后定罪
- **改为**：沈清月从"辩护席"走到"被告席" → 陆昭罗列证词 → 沈清月从容拆解 → 抛出香囊物证 → 沈清月当场翻盘（赝品调换）→ 孤证不立、伪证作废 → 陆昭惨败，沈清月从容离去
- **沈清月角色转换**：从"讼师"变为"被告"，角色彻底反转
  - intro_dialogue：沈清月被传唤至公堂，从辩护席走到被告席
  - testimonies：她不再是辩护方，而是直接反驳陆昭的指控
  - 终局翻盘：香囊赝品 + 孤证不立 + 从容离去
- **影响文件**：case.json（confrontation_final 段）、MainGame.gd（序章败局流程适配）

### 7. 序章败局实现
- **当前流程**：confrontation_final defeat → judge_confrontation("defeat") → "bad" ending → _show_ending
- **改造方案**：
  - confrontation_final 的 defeat_dialogue 改为沈清月翻盘台词
  - case.json 的 endings 中新增 "prologue_defeat" 结局
  - MainGame.gd 的 _on_confrontation_finished：当 confront_key == "confrontation_final" 且 result == "defeat" 时，走 prologue_defeat 结局
  - prologue_defeat 包含：陆昭惨败叙事、沈清月离去、官印暗线伏笔、主角心态变化、set_flag("prologue_defeated") 进入下一章

### 8. 沈清月作为公开对手（讼师身份）
- **表面身份**：浔阳沈氏药材行独女，兼通律法，受周氏之托协助审理此案
- **公开理由**：与周家有生意往来，周氏请求她帮忙"主持公道"
- **实际暗线**：真正的幕后黑手，以"辩护方"身份出现在每次对峙中，表面保护证人，实则引导错误方向
- **三场对峙中的角色**：
  - 王大爷伪证场景：以"客观分析"为名，质疑陆昭的辩驳，加固伪证可信度
  - 老范+阿贵对峙：为从犯辩护，质疑证据链，保护棋子
  - 终局翻盘：从"辩护方"变为"被告"，撕下伪装，香囊翻盘
- **三人关系**：
  - 陆昭（理性调查者）vs 沈清月（智力对手）→ 每次对峙都是逻辑交锋
  - 凌瑶（直觉型搭档）始终怀疑沈清月 → "这个女人不对劲"
  - 终局时凌瑶亲手验证香囊赝品 → 直觉被证实
- **影响文件**：case.json（confrontation/confrontation_final 的 intro_dialogue/testimonies）、fisherman_wang.json、prologue_lines.csv、companion/banter.json、companion/discussions.json
- **对标角色**：御剑怜侍（对手）+ 美柳千奈美（幕后黑手）

### 9. 阿贵确认为周德茂仆从
- **当前状态**：characters.csv 已正确设定（"死者仆从"、"死者仆从（船舱阶段）"）
- **无需修改**

---

## 三、新方案五幕结构（融合版）

### 序幕：哲学独白 → 时间卡（保留现有）
```
哲学独白4句 → DayTransition时间卡("万历廿二年·腊月·亥时") → 陆昭自我介绍
```

### 第一幕：船舱夜话（保留自由探索，优化背景设定）
- Phase 0：船舱自由探索
  - 与阿贵对话（紧张仆从，十二年老仆）
  - 与老范对话（二十年船家，夜间行船）
  - 与周德茂对话（精明布商，五十两货银）
- 观察：铁撬棍、船舱结构、各人行李
- **新增**：陆昭提及官印在防水锦袋中（伏笔铺垫）

### 第二幕：沉船逃生（保留密室系统，优化死因细节）
- 3回合行动限制密室逃脱
- 沉船过程：发现船底方形破洞（人为凿穿）
- 逃生：铁撬撬开天窗 → 甲板 → 江水漂流
- **新增**：陆昭官印锦袋受撞击脱落沉入深水（伏笔铺垫）

### 第三幕：获救暖场（优化凌瑶设定）
- 岸边被凌瑶救起（金鳞镖局首席镖师）
- 客栈暖场对话
- **新增**：凌瑶提及验尸知识（为后续尸检铺垫）
- **新增**：陆昭发现掌心受伤（撬天窗时磨破）

### 第四幕：被诬告指控（加入王大爷伪证+当庭驳证+沈清月出场）
- 次日发现周德茂尸体
- 周氏指控陆昭
- 阿贵作证（看见陆昭蹲在船底舱口）
- **新增**：王大爷作伪证（收周氏银两，捏造夜间目击）
- **新增**：沈清月首次出场（以"药材商之女"身份，受周氏之托协助审理）
- 里正介入，要求陆昭自证清白
- **新增**：当庭驳证环节（三重破绽击破王大爷伪证）
- **新增**：沈清月以"客观分析"为名，质疑陆昭的辩驳，加固伪证可信度
- 凌瑶协助拆解指控，同时内心对沈清月产生怀疑
- 进入自由调查（day2_start_game）

### 第五幕：全域调查（保留渐进系统，重新设计线索链+沈清月暗线）
- Phase 1：初步调查
  - 码头勘察沉船残骸（船底破洞证据）
  - 问询周氏（坦白知晓走私+行贿作伪证）
  - **新增**：问询王大爷（追加线索，阿贵与草药女子江岸私谈）
  - **新增**：问询里正（老范案发当夜已上岸+沈青月案发前夜登船+频繁出入客栈后院）
  - **新增**：与沈清月交谈（表面客气，暗中试探陆昭的调查进度）
- Phase 2：深入追查
  - **新增**：走访茶馆得知老范拾取玉锦物件（官印暗线）
  - 二次约谈阿贵（故作悲痛，矢口否认，漏洞百出）
  - **新增**：凌瑶提醒"沈清月这个人不对劲，她每次出现都恰到好处"
- Phase 3：追查幕后
  - 阿贵对峙（confrontation：老范+阿贵互相甩锅+沈清月作为"讼师"辩护→阿贵招供出沈青月）
  - 收尾调查（蓝色草药确认+草药香囊发现）

### 第六幕：终局庭审（沈清月从辩护席到被告席+序章败局）
- 沈清月被传唤至公堂（从"讼师"变为"被告"，角色反转）
- 第一轮对峙：陆昭罗列证词线索 → 沈清月从容拆解（口供为从犯片面之词）
- 第二轮对峙：抛出草药香囊物证 → 沈清月当场翻盘（赝品调换）
- **凌瑶验证**：凌瑶亲手核验香囊，发现确实是赝品——她的直觉终于被证实
- **序章败局**：孤证不立、伪证作废，沈清月从容离去
- **沈清月离场暗语**：隐晦侧目看向陆昭，暗示她与朝堂内部势力有所勾结
- 陆昭惨败，留下执念（set_flag("prologue_defeated")）
- **凌瑶安慰**：凌瑶表示"我从一开始就觉得那个女人不对劲，下次不会再让她得逞"

---

## 四、执行步骤（11步）

| # | 任务 | 依赖 | 影响文件 |
|---|------|------|----------|
| 1 | 修改凌瑶角色设定为金鳞镖局首席镖师 | - | characters.csv, banter.json, discussions.json, prologue_lines.csv |
| 2 | 改造王大爷为作伪证者，重写对话树 | - | fisherman_wang.json, prologue_lines.csv |
| 3 | 优化死因细节：新增蓝色草药迷晕证据链 | #1 | evidence_items.csv, evidence.json, search_results.json, prologue_lines.csv |
| 4 | 加入官印暗线伏笔 | #3 | evidence.json, agui.json, lao_fan.json, discussions.json, prologue_lines.csv |
| 5 | 加入草药香囊伏笔 | #3 | evidence.json, shen_qingyue.json, banter.json, prologue_lines.csv |
| 6 | 改造沈清月为公开对手（讼师身份），贯穿所有对峙场景 | #2#4#5 | case.json, fisherman_wang.json, prologue_lines.csv, banter.json, discussions.json |
| 7 | **新增**：ConfrontationPanel 对手立绘系统（右侧立绘+镜头切换） | #6 | ConfrontationPanel.gd (~120行), case.json (opponent_id 字段) |
| 8 | 改造 confrontation（阿贵对峙）：老范+阿贵互相甩锅+沈清月辩护 | #7 | case.json (confrontation 段) |
| 9 | 改造 confrontation_final（沈清月）：从辩护席到被告席+翻盘+序章败局 | #5#8 | case.json (confrontation_final 段), MainGame.gd |
| 10 | 更新同伴讨论和被动旁白（凌瑶对沈清月的怀疑） | #9 | discussions.json, banter.json |
| 11 | 验证全流程数据一致性 | #10 | 所有修改文件，运行编译脚本 |

---

## 五、关键技术方案

### 5.1 序章败局实现（MainGame.gd 修改）

```gdscript
# 当前流程：confrontation_final defeat → bad ending
# 改造后：
func _on_confrontation_finished(result: String, mistakes: int) -> void:
    _close_subpanel()
    var confront_key: String = GameManager.active_confrontation_key
    if result == "victory":
        # ... 现有胜利逻辑 ...
    else:
        # 序章败局：沈清月翻盘
        if confront_key == "confrontation_final":
            GameManager.set_flag("prologue_defeated")
            var defeat_lines = _confrontation_data.get("defeat_dialogue", [])
            if defeat_lines.size() > 0:
                DialogueManager.play_adhoc_narration(defeat_lines, func():
                    _play_prologue_defeat_ending()
                )
            else:
                _play_prologue_defeat_ending()
        else:
            # 其他对峙走原有失败逻辑
            var ending_id = GameManager.judge_confrontation(result, mistakes)
            _show_ending(ending_id)
```

### 5.2 王大爷伪证对话树结构（fisherman_wang.json）

```json
{
  "start": "hub",
  "nodes": {
    "hub": {
      "text": "老朽昨夜亲眼所见，江上小舟二人打斗，绝无差错！",
      "options": [
        {"text": "当夜浓雾遮眼，你如何看清？", "goto": "press_fog", "type": "press", "requires": [{"clue": "clue_weather_fog"}]},
        {"text": "狂风浪声震耳，你如何听见争执？", "goto": "press_wind", "type": "press", "requires": [{"clue": "clue_weather_storm"}]},
        {"text": "你收了周氏多少银两？", "goto": "press_bribe", "type": "press", "requires": [{"flag": "zhou_wife_bribe_exposed"}]},
        {"text": "先告辞", "goto": "__exit__"}
      ]
    },
    "press_fog": { "text": "这……老朽……老朽眼神好……", "set_flags": ["wang_fog_crack"] },
    "press_wind": { "text": "那……那风向不对的时候……", "set_flags": ["wang_wind_crack"] },
    "press_bribe": { "text": "我……我……（支支吾吾）", "set_flags": ["wang_bribe_crack"] },
    "debunked": {
      "text": "老朽……老朽认了。是周家娘子给了我五两银子，让我这么说的……",
      "set_flags": ["wang_testimony_debunked", "self_cleared"]
    }
  }
}
```

### 5.3 官印暗线证据链

```
evidence_seal_lost（陆昭自述官印丢失）
  ↓
clue_agui_seal_rumor（茶馆店小二：老范捡到玉锦物件）
  ↓
evidence_seal_fan_possessed（确认老范拾取官印）
  ↓
flag: seal_traded_to_shen（老范与沈青月暗线交易官印）
```

### 5.4 草药香囊伏笔链

```
evidence_blue_herb_residue（死者指甲缝蓝色草药碎屑）
  ↓
clue_herb_sachet_found（江岸发现沾染草药香气的刺绣香囊）
  ↓
evidence_herb_sachet（核心物证：沈青月专属香囊）
  ↓
[终局翻盘] 沈青月指出赝品破绽 → 物证失效
```

### 5.5 沈清月作为公开对手的三方博弈结构

```
┌─────────────────────────────────────────────────────────────┐
│                    三人关系定位                               │
├─────────────────────────────────────────────────────────────┤
│  陆昭（玩家）                                                │
│  ├─ 公开身份：巡江御使，负责审案                              │
│  ├─ 实际立场：辩护方/调查者                                   │
│  ├─ 与沈清月：智力博弈，每次对峙都是逻辑交锋                  │
│  └─ 与凌瑶：搭档互补，陆昭负责推理，凌瑶负责直觉              │
│                                                              │
│  凌瑶（搭档）                                                │
│  ├─ 公开身份：金鳞镖局首席镖师                                │
│  ├─ 实际立场：调查辅助+直觉型洞察                             │
│  ├─ 与沈清月：本能不信任，"这个女人不对劲"                    │
│  └─ 终局作用：亲手验证香囊赝品，直觉被证实                    │
│                                                              │
│  沈清月（对手）                                              │
│  ├─ 公开身份：药材商之女兼讼师，受周氏之托                    │
│  ├─ 实际立场：幕后黑手，以"辩护方"身份引导错误方向            │
│  ├─ 与陆昭：表面尊重，实则操控                                │
│  └─ 终局反转：从辩护席走到被告席，撕下伪装                    │
└─────────────────────────────────────────────────────────────┘
```

**三场对峙中的互动模式**：

| 对峙场景 | 陆昭（辩护方） | 沈清月（对手） | 凌瑶（搭档） |
|----------|----------------|----------------|--------------|
| 王大爷伪证 | 拆解伪证三重破绽 | 以"客观分析"加固伪证 | 提供天气/距离等事实依据 |
| 老范+阿贵 | 双重施压逼供 | 为从犯辩护，质疑证据链 | 发现沈清月的"帮忙"时机太巧 |
| 终局翻盘 | 抛出香囊物证 | 从辩护方变为被告方，当场翻盘 | 亲手验证香囊，发现是赝品 |

**沈清月在各对峙中的台词设计思路**：

```
【王大爷伪证 - 沈清月辩护】
沈清月："里正大人，此案疑点甚多，容我代为询问。
          陆公子，王大爷年逾六旬，夜半目力虽不如年轻人，
          但江面月光映水，辨人轮廓并非不可能。你凭什么断定他看不见？"

【老范+阿贵对峙 - 沈清月辩护】
沈清月："陆公子，你对两个下人严刑逼供，这算什么御史？
          你所谓的'浮囊采购记录'，不过是一张没有署名的收据。这能证明什么？"

【终局翻盘 - 沈清月亮牌】
沈清月："（微笑）陆公子，你费尽心思收集的证据……
          可惜，每一件我都提前处理过了。
          你以为你在查案，其实你一直在我的棋盘上。"
```

### 5.6 对手立绘系统（ConfrontationPanel 扩展）

#### 布局设计

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  [-520..-60]      [居中]        [1080+]         │
│   屏幕外左侧      NPC/证人      屏幕外右侧      │
│                                                 │
│  [30..490]                       [560..1080]    │
│   主角可见位                     对手可见位      │
│                                                 │
└─────────────────────────────────────────────────┘
```

#### 镜头切换逻辑

核心规则：**谁说话谁显示，其他人移出屏幕**

| 立绘 | 锚点 | 可见位置 | 屏幕外位置 | 朝向 |
|------|------|----------|------------|------|
| NPC/证人 | 居中 (0.5) | offset: -260..260 | 不移动，直接淡出 | 朝前 |
| 主角 | 左侧 (0.0) | offset: 30..490 | offset: -520..-60 | 朝右 |
| 对手 | 右侧 (1.0) | offset: -490..-30 | offset: 60..520 | 朝左 (flip_h=true) |

#### 状态转换表

| 当前状态 | 说话者 | 动画 | 新状态 |
|----------|--------|------|--------|
| `npc` | 主角 | NPC淡出 + 主角从左滑入 | `protagonist` |
| `npc` | 对手 | NPC从左滑出 + 对手从右滑入 | `opponent` |
| `protagonist` | NPC | 主角从左滑出 + NPC淡入居中 | `npc` |
| `protagonist` | 对手 | 主角从左滑出 + 对手从右滑入 | `opponent` |
| `opponent` | NPC | 对手从右滑出 + NPC淡入居中 | `npc` |
| `opponent` | 主角 | 对手从右滑出 + 主角从左滑入 | `protagonist` |

#### ConfrontationPanel.gd 修改点

```
新增变量：
├── _opponent_rect: TextureRect      # 对手立绘（右侧）
├── _opponent_id: String             # 当前对手 NPC ID
└── _current_camera_view 扩展："npc" | "protagonist" | "opponent"

新增函数：
├── _setup_opponent_portrait()       # 创建对手立绘节点
├── _camera_switch_to_opponent()     # 镜头切到对手（当前角色从左滑出，对手从右滑入）
└── _update_opponent_portraits()     # 更新对手立绘纹理+表情

修改函数：
├── _auto_camera_switch()            # 识别 speaker 是对手时切到右侧
├── _play_contradiction_hit()        # 反驳成功时对手抖动（而非NPC抖动）
└── _setup_ui()                      # 初始化对手立绘节点
```

#### case.json 数据结构扩展

```json
{
  "confrontation": {
    "suspect": "agui",
    "opponent_id": "shen_qingyue",   // 新增：对手 NPC ID
    "opponent_role": "讼师",          // 新增：对手身份描述
    "intro_dialogue": [
      {"speaker": "沈清月", "text": "里正大人，容我代为询问。", "emotion": "cooperative"}
    ],
    "testimonies": [
      {
        "witness": "lao_fan",
        "statements": [
          {"text": "那晚风浪太大，我也没看清。"},
          {"speaker_override": "shen_qingyue", "text": "陆公子，风浪之中视线受阻，这不是很正常吗？"}
        ]
      }
    ]
  }
}
```

#### 修改量评估

| 文件 | 修改内容 | 行数 |
|------|----------|------|
| `ConfrontationPanel.gd` | 新增对手立绘槽位+镜头切换+动画 | ~120行 |
| `case.json` | 新增 `opponent_id` 字段 | ~2行 |
| 立绘资源 | 无需新增，复用现有沈清月立绘 | 0 |

---

## 六、注意事项

1. **CSV 修改需保持列对齐**，避免 CaseTableLoader 编译错误
2. **evidence.json 由 evidence_items.csv 编译生成**，需同时修改 CSV 源文件
3. **confrontation 的 testimonies 数据量大**（当前约 2500 行），修改时需精确插入
4. **banter.json 的 when 条件**需与 progression 的 flag/evidence 对齐
5. **所有 dialogue JSON 为手写**，不经过编译
6. **运行时编译**：prologue_nodes/lines.csv 修改后，运行时由 CaseTableLoader._compile_prologue 自动编译
7. **compile_case.py**：evidence_items.csv、confrontation_lines.csv 等修改后需运行 compile_case.py 重新生成 JSON

---

## 七、美术资源与音效资源分析

### 7.1 立绘资源现状

#### 已有立绘（可直接使用）

| 角色 | 已有表情 | 数量 | 状态 |
|------|----------|------|------|
| **陆昭** | base, cold, serious, surprised, confrontation_pose + prologue系列 | 10 | ✅ 完整 |
| **凌瑶** | base, anxious, cheerful, confrontation_normal/pose, determined, embarrassed, shocked, worried | 9 | ✅ 完整 |
| **阿贵** | base, broken, collapsed, confrontation系列, crying, nervous, nervous_fixed, shaken, shocked | 11 | ✅ 完整 |
| **老范** | base, collapsed, frozen, shaken, sneering | 5 | ✅ 完整 |
| **沈清月** | base, bold, broken, cold_fury, cold_smile, confrontation, cooperative, cracking, deflecting, sharp | 10 | ✅ 完整 |
| **周氏** | base, screaming, silent, trembling | 4 | ✅ 完整 |
| **里正** | base, evasive, gossip, nervous, shocked, sighing, stern | 7 | ✅ 完整 |
| **王大爷** | base, angry, evasive | 3 | ✅ 完整 |
| **周德茂** | base（仅1张） | 1 | ⚠️ 仅基础表情 |

#### 需要补充的立绘

| 角色 | 需要的表情 | 用途 | 优先级 |
|------|-----------|------|--------|
| **王大爷** | `confession`（坦白伪证时）、`guilty`（被拆穿后） | 当庭驳证桥段 | 高 |
| **周德茂** | `cabin_portrait`（船舱阶段对话用） | 船舱自由探索 | 中 |
| **凌瑶** | `forensic`（验尸时的专业表情）、`angry`（怒斥伪证时） | 死因分析+驳证桥段 | 中 |
| **陆昭** | `defeated`（序章败局时的挫败表情） | 终局败局 | 中 |
| **沈清月** | `victory`（翻盘成功时的从容表情） | 终局翻盘 | 中 |

#### 立绘缺失统计

- **王大爷**：仅3张，需补充 confession/guilty（用于伪证拆穿场景）
- **周德茂**：仅1张，船舱阶段对话需要 cabin 表情
- **其他角色**：现有立绘基本充足，可复用已有表情

### 7.2 场景背景图现状

#### 已有场景（可直接使用）

| 场景 | 文件 | 用途 | 状态 |
|------|------|------|------|
| 船舱（陆昭房间） | `prologue_ship_cabin_lu_room.png` | 船舱自由探索 | ✅ |
| 船舱（进水） | `prologue_ship_cabin_rising.png` | 沉船逃生 | ✅ |
| 天窗破洞 | `prologue_ship_skylight_break.png` | 逃生场景 | ✅ |
| 甲板沉没 | `prologue_ship_deck_sinking.png` | 沉船过程 | ✅ |
| 深水 | `prologue_dark_water.png` | 游泳逃生 | ✅ |
| 岸边救援 | `prologue_shore_rescue.png` | 获救场景 | ✅ |
| 客栈 | `prologue_ferry_inn.png` | 客栈暖场+调查 | ✅ |
| 码头 | `prologue_ferry_dock.png` | 码头调查 | ✅ |
| 尸体发现 | `prologue_cold_open.png` | 发现尸体 | ✅ |
| 周氏下跪 | `prologue_cg_zhou_kneel.png` | 指控场景 | ✅ |
| 纯黑 | `pure_black.png` | 哲学独白+过场 | ✅ |
| 地点卡/时间卡 | `locations_card.png`, `time_card_bg.png` | 过场卡 | ✅ |

#### 需要补充的场景

| 场景 | 用途 | 优先级 | 说明 |
|------|------|--------|------|
| **公堂/客栈大厅** | 当庭驳证+终局对峙 | 高 | 当前用 `prologue_confrontation_hall.png`，需确认是否适配"客栈临时公堂"设定 |
| **茶馆** | 官印暗线调查 | 中 | 可复用 `prologue_ferry_inn.png` 或新建 |
| **沈清月房间** | 终局对峙场景 | 中 | 当前用 `prologue_ferry_inn.png`，可新建独立背景 |
| **船舱（阿贵房间）** | 船舱探索阶段 | 低 | 可复用 `prologue_ship_cabin_lu_room.png` 变体 |

### 7.3 音效/BGM 资源现状

#### 已有 BGM（registry.json 中注册）

| BGM Key | 文件 | 用途 | 状态 |
|---------|------|------|------|
| `ferry_prologue_escape` | `bgm/ferry_prologue_escape.ogg` | 沉船逃生 | ✅ |
| `ferry_prologue_shore` | `bgm/ferry_prologue_shore.ogg` | 岸边救援 | ✅ |
| `ferry_inn_investigation` | `bgm/ferry_inn_investigation.ogg` | 客栈调查 | ✅ |
| `ferry_dock_investigation` | `bgm/ferry_dock_investigation.ogg` | 码头调查 | ✅ |
| `accuse` | `sfx/accuse.ogg` | 对峙开始 | ✅ |
| `pursuit` | `sfx/pursuit.ogg` | 对峙突破 | ✅ |
| `confrontation` | `sfx/confrontation.ogg` | 对峙基础 | ✅ |
| `cornered` | `sfx/cornered.ogg` | 最终轮对峙 | ✅ |
| `ferry_court_opening` | `bgm/ferry_court_opening.ogg` | 庭审开场 | ✅ |
| `accuse_tension` | `bgm/accuse_tension.ogg` | 指控紧张 | ✅ |

#### 已有音效

| 音效 | 文件 | 用途 | 状态 |
|------|------|------|------|
| `water_rush` | `sfx/water_rush.wav` | 水涌入 | ✅ |
| `glass_break` | `sfx/glass_break.wav` | 天窗破碎 | ✅ |
| `ship_creak` | `sfx/ship_creak.wav` | 船体断裂 | ✅ |
| `splash` | `sfx/splash.wav` | 落水 | ✅ |
| `rain_ambient` | `sfx/rain_ambient.wav` | 雨声环境 | ✅ |
| `crowd_murmur` | `sfx/crowd_murmur.wav` | 人群骚动 | ✅ |
| `objection` | `sfx/objection.ogg` | 异议（逆转裁判风格） | ✅ |
| `evidence_slam` | `sfx/evidence_slam.ogg` | 出示证据 | ✅ |
| `testimony_tap` | `sfx/testimony_tap.ogg` | 威慑证词 | ✅ |
| `judge_gavel` | `sfx/judge_gavel.ogg` | 惊堂木 | ✅ |
| `dramatic_pause` | `sfx/dramatic_pause.ogg` | 戏剧性停顿 | ✅ |
| `truth_reveal` | `sfx/truth_reveal.ogg` | 真相揭示 | ✅ |
| `pressure_hit` | `sfx/pressure_hit.ogg` | 施压 | ✅ |

#### 需要补充的 BGM/音效

| 资源 | 用途 | 优先级 | 说明 |
|------|------|--------|------|
| **伪证拆穿 BGM** | 王大爷当庭驳证场景 | 高 | 可复用 `pursuit` 或新建专用 BGM |
| **序章败局 BGM** | 沈清月翻盘后陆昭惨败 | 高 | 需要悲伤/挫败感的 BGM，当前无对应 |
| **沈清月专属 BGM** | 终局对峙时沈清月出场 | 中 | 可复用 `cornered` 或新建 |
| **官印发现音效** | 茶馆得知官印下落 | 低 | 可复用 `truth_reveal` |
| **香囊出示音效** | 抛出草药香囊物证 | 低 | 可复用 `evidence_slam` |

### 7.4 证据图标资源

#### 已有证据图标

- `assets/cn/ui/evidence/` 目录下有 2 个证据图标
- `assets/cn/ui/evidence_icons/` 目录下有 41 个证据图标

#### 需要补充的证据图标

| 证据 | 图标需求 | 优先级 |
|------|----------|--------|
| `evidence_blue_herb_residue`（蓝色草药碎屑） | 蓝色草药/粉末图标 | 高 |
| `evidence_neck_marks`（脖颈压痕） | 脖颈/勒痕图标 | 高 |
| `evidence_herb_sachet`（草药香囊） | 香囊/药包图标 | 高 |
| `evidence_seal_lost`（官印丢失） | 官印/印章图标 | 中 |
| `evidence_seal_fan_possessed`（老范拾取官印） | 官印+人像图标 | 中 |

### 7.5 资源需求汇总

#### 必须新增（高优先级）

| 类型 | 资源 | 数量 | 生成方式 |
|------|------|------|----------|
| 立绘 | 王大爷 confession/guilty 表情 | 2 | AI 生成（nano-banana-pro + chromakey） |
| 证据图标 | 蓝色草药碎屑、脖颈压痕、草药香囊 | 3 | AI 生成或图标库 |
| BGM | 序章败局 BGM（悲伤/挫败感） | 1 | AI 生成（MiniMax Music API） |

#### 建议新增（中优先级）

| 类型 | 资源 | 数量 | 生成方式 |
|------|------|------|----------|
| 立绘 | 周德茂 cabin 表情 | 1 | AI 生成 |
| 立绘 | 凌瑶 forensic/angry 表情 | 2 | AI 生成 |
| 立绘 | 陆昭 defeated 表情 | 1 | AI 生成 |
| 立绘 | 沈清月 victory 表情 | 1 | AI 生成 |
| 证据图标 | 官印相关 | 2 | AI 生成或图标库 |
| 场景 | 沈清月房间独立背景 | 1 | AI 生成 |

#### 可复用现有资源（低优先级）

| 需求 | 复用方案 |
|------|----------|
| 伪证拆穿 BGM | 复用 `pursuit` |
| 沈清月出场 BGM | 复用 `cornered` |
| 官印发现音效 | 复用 `truth_reveal` |
| 香囊出示音效 | 复用 `evidence_slam` |
| 茶馆场景 | 复用 `prologue_ferry_inn.png` |
| 沈清月房间场景 | 复用 `prologue_ferry_inn.png` |
| 公堂场景 | 复用 `prologue_confrontation_hall.png` |

---

## 八、本轮修订修改点归档（2026-06-01）

> 来源：对《融合改写方案》与项目现状、逆转裁判式体验的对比分析。
> 目的：不推翻原方案，在落地前收敛风险，强化玩家参与感、对手压迫感和序章败局的情绪合理性。

### 8.1 核心修订结论

原方案方向保留：

```text
沈清月作为公开对手贯穿对峙
  ↓
王大爷伪证、老范/阿贵甩锅、草药香囊翻盘
  ↓
序章以陆昭败局收束，留下后续追查动机
```

本轮修订后，执行原则调整为：

```text
沈清月前期是理性讼师，不是一眼反派
王大爷伪证要让玩家亲手拆，不做纯剧情自动拆穿
每场对峙至少一次沈清月主动反向假说
终局采用“机制胜利，剧情败局”
短期少改引擎，优先把沈清月台词放入 dialogue 队列
```

### 8.2 必须纳入原计划的新增原则

1. **机制胜利，剧情败局**
   - `confrontation_final` 不应设计成玩家信心归零后的失败。
   - 推荐做法：玩家完成最终击破后，进入沈清月香囊赝品翻盘剧情。
   - 玩家感受应是“我推理对了，但证据被对手提前布局废掉”，而不是“我输了所以剧情失败”。

2. **沈清月前期保持理性对手形象**
   - 前期不直接表现为恶意反派。
   - 她应以懂律法、讲证据、表面公正的讼师身份出现。
   - 她的反驳必须有一定合理性，避免玩家过早锁定她是真凶。

3. **沈清月每场对峙至少提出一次反向假说**
   - 她不能只是替证人圆谎。
   - 她需要像逆转裁判中的检察官一样主动反压玩家。

4. **王大爷伪证做成半玩法**
   - 不新增系统。
   - 使用现有 `choices` / `requires` / `set_flags` 做“三破绽拆证词”。
   - 目标是保留玩家亲手击破伪证的参与感。

5. **短期收敛 `statements` 中的多说话人复杂度**
   - 沈清月发言优先放在 `intro_dialogue`、`transition_dialogue`、`press`、`break_dialogue`、`wrong_reactions`、`victory_dialogue`、`defeat_dialogue`。
   - 不建议大量放进普通 `statements`，除非同步扩展 `ConfrontationPanel.gd` 的 statement speaker 镜头逻辑。

### 8.3 对现有计划的具体修改点

| 原计划位置 | 原表述/风险 | 修订方向 |
|---|---|---|
| 核心原则 | confrontation_final 以 `defeat` 流程进入败局 | 改为玩家完成最终击破后进入剧情败局 |
| 执行步骤 | 沈清月公开对手与对手立绘系统绑定过紧 | 先用 dialogue 队列完成对手压迫感，立绘系统可作为增强项 |
| 王大爷伪证 | 容易变成剧情自动拆穿 | 改为三破绽 flag 流程：浓雾、浪声、收银动机 |
| 沈清月台词 | 计划中倾向塞入 `testimonies/statements` | 优先放入 press、break、transition、wrong_reactions |
| 终局败局 | 容易让玩家感觉努力无效 | 明确“玩家逻辑胜利，剧情被香囊赝品翻盘” |
| 命名 | 文档中存在“沈青月/沈清月”混用 | 项目内统一为“沈清月”，ID 统一为 `shen_qingyue` |
| 字段 | 示例中使用 `speaker_override` | 推荐使用标准 `speaker` + `speaker_id`，避免未支持字段 |
| 幕结构 | 文档标题写“五幕”，实际有序幕+六幕 | 后续修订时统一为“序幕 + 六幕”或“六段式序章结构” |

### 8.4 推荐替换执行步骤（归档版）

后续正式改计划时，建议将“执行步骤（11步）”替换为以下 12 步：

| # | 任务 | 依赖 | 影响文件 |
|---|------|------|----------|
| 1 | 统一命名与数据键：沈清月/王大爷/confrontation key/speaker 字段规范 | - | 全局文档、`case.json`、dialogue JSON |
| 2 | 修改凌瑶角色设定为金鳞镖局首席镖师 | #1 | `characters.csv`, `banter.json`, `discussions.json`, `prologue_lines.csv` |
| 3 | 改造王大爷为作伪证者，并做成半玩法拆证词流程 | #1 | `fisherman_wang.json`, `prologue_lines.csv` |
| 4 | 优化死因细节：新增蓝色草药迷晕证据链 | #2 | `evidence_items.csv`, `evidence.json`, `search_results.json`, `prologue_lines.csv` |
| 5 | 加入官印暗线伏笔 | #4 | `evidence.json`, `agui.json`, `lao_fan.json`, `discussions.json`, `prologue_lines.csv` |
| 6 | 加入草药香囊伏笔 | #4 | `evidence.json`, `shen_qingyue.json`, `banter.json`, `prologue_lines.csv` |
| 7 | 改造沈清月为公开对手：理性讼师身份 + 每场对峙至少一次反向假说 | #3#5#6 | `case.json`, `fisherman_wang.json`, `prologue_lines.csv`, `banter.json`, `discussions.json` |
| 8 | 对手立绘系统：右侧立绘 + 谁说话谁显示（可作为增强项） | #7 | `ConfrontationPanel.gd`, `case.json` |
| 9 | 改造 `confrontation`：老范+阿贵互相甩锅+沈清月辩护反压 | #8 | `case.json` |
| 10 | 改造 `confrontation_final`：玩家机制胜利后进入沈清月翻盘败局 | #6#9 | `case.json`, `MainGame.gd` |
| 11 | 更新同伴讨论和被动旁白：凌瑶对沈清月的直觉怀疑 | #10 | `discussions.json`, `banter.json` |
| 12 | 验证全流程数据一致性：重新编译 CSV、检查解锁条件链闭合 | #11 | 所有修改文件 |

### 8.5 沈清月发言位置规范

| 数据位置 | 推荐程度 | 用途 |
|---|---|---|
| `intro_dialogue` | 高 | 对峙开场，展示讼师身份 |
| `transition_dialogue` | 高 | 证词段落之间提出反驳或新假说 |
| `press` | 高 | 玩家威慑时插话保护证人 |
| `break_dialogue` | 高 | 玩家出示正确证据后尝试补救 |
| `wrong_reactions` | 高 | 玩家出错时嘲讽或反压 |
| `victory_dialogue` / `defeat_dialogue` | 高 | 对峙收束与终局翻盘 |
| `statements` | 低 | 短期不建议大量使用 |

### 8.6 王大爷伪证半玩法流程

```text
王大爷坚称目击
  ↓
玩家质疑浓雾：set_flag("wang_fog_crack")
  ↓
玩家质疑风浪：set_flag("wang_wind_crack")
  ↓
玩家指出收银动机：set_flag("wang_bribe_crack")
  ↓
三个 flag 齐备
  ↓
解锁最终追问：“你的证词漏洞百出。”
  ↓
王大爷承认收钱作伪证
  ↓
set_flag("wang_testimony_debunked")
set_flag("self_cleared")
```

### 8.7 沈清月反向假说清单

| 场景 | 反向假说 |
|---|---|
| 王大爷伪证 | 陆昭是唯一生还者，反而最有机会毁船灭口 |
| 老范/阿贵对峙 | 浮囊可能只是船家常备用具，不等于预谋杀人 |
| 草药线索 | 蓝色草药只能证明死者接触过药，不代表沈清月下药 |
| 香囊物证 | 香囊可能是有人嫁祸，甚至可能是陆昭伪造证据 |
| 终局败局 | 孤证不立，伪证作废，陆昭所谓铁证反成破绽 |

### 8.8 终局败局推荐流程

```text
玩家完成 confrontation_final 全部关键击破
  ↓
系统判定 result == "victory"
  ↓
陆昭抛出核心物证：草药香囊
  ↓
沈清月指出香囊已被调换为赝品
  ↓
凌瑶核验证实赝品
  ↓
香囊物证失效，阿贵/老范口供也因伪证风险被削弱
  ↓
当庭无法定罪
  ↓
沈清月从容离场
  ↓
陆昭保留真相判断，但输给证据规则和对手提前布局
  ↓
set_flag("prologue_truth_reached")
set_flag("prologue_defeated")
```

### 8.9 后续落地前待确认事项

- `ConfrontationPanel.gd` 是否已经支持 statement 内按 `speaker` 切镜头。
- `case.json` 中是否支持 `transition_dialogue`，若不支持则改用现有 `break_dialogue` / `intro_dialogue` / `victory_dialogue`。
- `speaker_id` 是否已有统一读取逻辑；若没有，先用 `speaker` 文本匹配，避免新增字段扩大改动。
- `confrontation_final` 的败局应从 `victory` 分支进入，还是用新增 `twist_defeat_dialogue` 字段承接，需要结合 `MainGame.gd` 实际流程确认。
- `progression.json` 中新增证据、搜索点、NPC 对话解锁条件必须闭环。

### 8.10 美术与音效扩充清单（落地版）

> 原则：优先补“会直接影响剧情理解和对峙情绪”的资源；可复用现有资源的暂不新增。若后续使用 AI 生成图片资源，默认采用纯紫色 `#FF00FF` 背景生成，再程序色键去底导出透明 PNG 后导入工程。

#### 8.10.1 必须补充：高优先级美术资源

| 类型 | 资源 | 建议 ID / 文件名 | 用途 | 优先级 |
|---|---|---|---|---|
| 角色立绘 | 王大爷坦白伪证 | `fisherman_wang_confession.png` | 三破绽被击破后承认收银作伪证 | 高 |
| 角色立绘 | 王大爷心虚/愧疚 | `fisherman_wang_guilty.png` | 玩家连续威慑后逐步露怯 | 高 |
| 证据图标 | 蓝色草药碎屑 | `evidence_blue_herb_residue.png` | 死因从直接溺亡升级为迷晕后溺亡 | 高 |
| 证据图标 | 脖颈压痕 | `evidence_neck_marks.png` | 证明死者生前遭控制/压制 | 高 |
| 证据图标 | 草药香囊 | `evidence_herb_sachet.png` | 终局核心物证，后续被赝品翻盘 | 高 |
| 证据图标 | 草药香囊赝品 | `evidence_fake_herb_sachet.png` | 终局“机制胜利，剧情败局”的视觉锚点 | 高 |

#### 8.10.2 建议补充：中优先级美术资源

| 类型 | 资源 | 建议 ID / 文件名 | 用途 | 优先级 |
|---|---|---|---|---|
| 角色立绘 | 凌瑶验尸专业表情 | `lingyao_forensic.png` | 强化“首席镖师 + 验尸能力”设定 | 中 |
| 角色立绘 | 凌瑶愤怒/护主表情 | `lingyao_angry.png` | 王大爷伪证、终局败局时增强搭档情绪 | 中 |
| 角色立绘 | 陆昭败局表情 | `luzhao_defeated.png` | 序章败局结尾，表现首次惨败 | 中 |
| 角色立绘 | 沈清月胜利微笑 | `shen_qingyue_victory.png` | 香囊赝品翻盘后从容离场 | 中 |
| 角色立绘 | 周德茂船舱阶段 | `zhou_demao_cabin.png` | Phase 0 船舱夜话，避免死者只有基础立绘 | 中 |
| 证据图标 | 官印遗失 | `evidence_seal_lost.png` | 陆昭官印沉船丢失伏笔 | 中 |
| 证据图标 | 锦袋/官印残线索 | `evidence_seal_cloth_wrap.png` | 老范拾取官印、后续幕后交易线索 | 中 |

#### 8.10.3 可暂缓：低优先级美术资源

| 类型 | 资源 | 建议用途 | 暂缓理由 |
|---|---|---|---|
| 场景背景 | 茶馆 | 官印暗线调查 | 可先复用 `prologue_ferry_inn.png` |
| 场景背景 | 客栈后院守卫盲区 | 香囊调包伏笔 | 可先用文字叙述或复用客栈背景 |
| 场景背景 | 沈清月房间 | 终局前调查/试探 | 当前可复用客栈背景 |
| 场景背景 | 客栈临时公堂强化版 | 王大爷伪证与终局对峙 | 先确认 `prologue_confrontation_hall.png` 是否足够 |
| UI 演出 | 沈清月“异议”切入图 | 对手压迫感 | 需先确认对手立绘系统是否落地 |

#### 8.10.4 必须补充：高优先级音效/BGM

| 类型 | 资源 | 建议 ID / 文件名 | 用途 | 优先级 |
|---|---|---|---|---|
| BGM | 序章败局主题 | `prologue_defeat.ogg` | 沈清月翻盘、陆昭首次惨败 | 高 |
| BGM | 伪证拆穿推进曲 | `false_testimony_pursuit.ogg` | 王大爷三破绽逐步击破 | 高 |
| SFX | 香囊翻盘冲击音 | `sachet_twist_hit.ogg` | 沈清月指出香囊为赝品的瞬间 | 高 |
| SFX | 证词崩裂音 | `testimony_crack.ogg` | 王大爷、阿贵、老范心理防线松动 | 高 |

#### 8.10.5 建议补充：中优先级音效/BGM

| 类型 | 资源 | 建议 ID / 文件名 | 用途 | 优先级 |
|---|---|---|---|---|
| BGM | 沈清月主题 | `shen_qingyue_theme.ogg` | 她作为理性讼师登场时使用，避免过早反派化 | 中 |
| BGM | 沈清月压迫主题 | `shen_qingyue_pressure.ogg` | 终局从辩护方转为被告后使用 | 中 |
| SFX | 官印线索发现 | `seal_clue_reveal.ogg` | 茶馆/老范官印线索出现 | 中 |
| SFX | 蓝草药发现 | `herb_clue_reveal.ogg` | 凌瑶验尸发现蓝色草药碎屑 | 中 |
| SFX | 人群低声议论增强版 | `court_murmur_low.ogg` | 公堂攻防、伪证动摇时烘托气氛 | 中 |

#### 8.10.6 可复用现有音频资源

| 需求 | 可复用资源 | 说明 |
|---|---|---|
| 普通对峙开始 | `accuse` / `confrontation` | 已能覆盖基础公堂紧张感 |
| 追击/击破 | `pursuit` | 可先替代伪证拆穿 BGM |
| 最终轮压迫 | `cornered` | 可先替代沈清月压迫主题 |
| 出示证据 | `evidence_slam` | 草药香囊、官印线索均可复用 |
| 惊堂木 | `judge_gavel` | 公堂节奏控制继续复用 |
| 真相揭示 | `truth_reveal` | 官印、蓝草药发现可先复用 |
| 戏剧停顿 | `dramatic_pause` | 香囊赝品翻盘前可复用 |
| 异议提示 | `objection` | 沈清月插话/反向假说可复用 |

#### 8.10.7 资源落地顺序建议

1. 先补证据图标：`evidence_blue_herb_residue`、`evidence_neck_marks`、`evidence_herb_sachet`、`evidence_fake_herb_sachet`。
2. 再补王大爷 `confession/guilty`，确保伪证半玩法有情绪反馈。
3. 再补 `prologue_defeat.ogg`，保证终局败局不显得突兀。
4. 若时间充足，再补凌瑶 `forensic/angry`、陆昭 `defeated`、沈清月 `victory`。
5. 场景背景和沈清月专属 BGM 可作为增强项，不阻塞第一轮剧情落地。
