# Markdown 写作指南

## 概述

除了直接编辑 CSV 文件，作者也可以使用 Markdown 格式编写案例内容，然后通过转换工具生成 CSV 文件。

## 适用场景

- **对话剧本**：编写 NPC 对话和剧情
- **证据描述**：撰写证据和线索的详细描述
- **地点描述**：编写地点的环境描写
- **事件叙述**：编写日间事件和过场动画

---

## 对话剧本格式

### 基本结构

```markdown
# NPC: 阿贵

## hub
> 你……你是昨晚同船的那位？听说里正给了你两天。你要问什么……问吧。
*（哭泣）*

### 选项
- [ask] 问问当晚发生了什么 → intro
- [press] 你和周德茂关系怎样？ → ask_relationship
  - 条件：agui_talked_once
- [press] 你是怎么从水里活下来的？ → press_alibi
  - 条件：agui_talked_once
- 先告辞 → __exit__

---

## intro

**阿贵**：那天晚上……老爷急着过江，老范说夜里也能走。小的只是跟着上了船，哪敢多嘴。
*（悲伤）*

**阿贵**：到了江心，突然船就晃得厉害——然后水就涌进来了！什么都看不见！小的拼命去拉老爷的手，没拉住……
*（悲伤）*
高亮：水涌进来；没拉住

**凌瑶**：他没有急着咬谁，只把自己说成了一个慌乱救主的人。
*（担忧）*

**陆昭**：先听着。看他后面怎么说。
*（严肃）*

### 选项
- 继续询问 → hub
- 先告辞 → __exit__
```

### 格式说明

#### NPC 定义

```markdown
# NPC: {npc_id}
```

- `npc_id`：角色 ID，小写字母+下划线

#### 节点定义

```markdown
## {node_id}
```

- `node_id`：节点 ID
- 第一个节点默认为起始节点（`is_start=true`）

#### 台词格式

```markdown
**{speaker}**：{text}
*（{emotion}）*
高亮：{keyword1}；{keyword2}
```

- `speaker`：说话者名称或 ID
- `text`：台词内容
- `emotion`：情绪（可选）
- `高亮`：高亮关键词，分号分隔（可选）

**多行台词：**

```markdown
**阿贵**：
小的不会水……当时什么都看不见，只觉得冷。
手里好像抓到了一块板子——死死抱住不敢放。
*（悲伤）*
高亮：抱着一块船板
```

#### 证词记录

```markdown
**阿贵**：小的不会水……当时什么都看不见，只觉得冷。
*（悲伤）*
记录：testimony|证词记录：阿贵的生还说法|阿贵声称自己抱着一块船板漂上岸。
```

格式：`记录：{type}|{title}|{text}`

#### 选项格式

```markdown
### 选项
- [{type}] {text} → {goto}
  - 条件：{condition}
  - 设置：{flags}
  - 隐藏：true
  - 消耗：{time}
```

- `type`：选项类型（ask/press/observe/confrontation，可选）
- `text`：选项文本
- `goto`：跳转目标
- `条件`：显示条件（可选）
- `设置`：选择后设置的标志位（可选）
- `隐藏`：访问后隐藏（可选）
- `消耗`：时间消耗（可选）

**特殊跳转：**
- `__exit__`：退出对话
- `__confront__`：进入对峙
- `hub`：返回对话中心

---

## 证据描述格式

```markdown
# 证据

## evidence_hull_hole
- 类型：evidence
- 名称：船底人工破洞
- 描述：
  沉船底部有一处明显的人工凿痕。
  木板边缘整齐，不像撞击所致——更像是被人从内侧用凿子打开的活板。

## clue_wife_suspicion
- 类型：clue
- 名称：周氏的怀疑
- 描述：
  周氏说：阿贵这两天表现很反常。
  案发后他哭得比谁都凶，但平时他跟老爷关系并不好——上船前还被老爷骂了一顿。
```

---

## 地点描述格式

```markdown
# 地点

## ferry_inn
- 名称：石矶渡·客栈
- 描述：
  江畔一间简陋的客栈，土墙木梁，屋顶漏雨。
  冬雨绵绵，门口泥泞不堪。滞留旅客挤满了大堂。
- 阶段：phase_1
- NPC：li_zheng

### 搜索点
- inn_lobby：客栈大堂
- inn_kitchen：客栈厨房
  - 消耗：1
  - 提示：0.0;0.22;0.75;0.68

---

## zhou_room
- 名称：周氏房间
- 父地点：ferry_inn
- 描述：
  一间狭小的偏房。桌上散着纸笔，墙角堆着包袱行李。
  空气中有淡淡的香烛气味。
- 阶段：phase_1
- NPC：zhou_wife

### 搜索点
- zhou_desk：桌上纸笔砚台
- zhou_luggage：墙角包袱行李
```

---

## 事件描述格式

```markdown
# 事件

## evt_hull_discovered
- 标题：人为破坏
- 提示：（你发现了船底的人工破洞）
- 触发：
  - 拥有：evidence_hull_hole
  - 未完成：evt_hull_discovered_done
- 效果：
  - 设置标志：evt_hull_discovered_done, hull_sabotage_known

## evt_confrontation_ready
- 标题：证据齐了——可以对峙了
- 提示：✦ 关键证据已齐，点击发起对峙
- 触发：
  - 拥有：evidence_hull_hole
  - 拥有：evidence_float_bladder
  - 拥有：evidence_no_blunt_trauma
  - 标志：agui_premeditation_known
  - 未完成：confrontation_auto_triggered
- 效果：
  - 设置标志：confrontation_auto_triggered
  - 自动对峙：confrontation
```

---

## 转换工具

### markdown_to_csv.py

将 Markdown 文件转换为 CSV 格式。

**位置：** `tools/data_compiler/markdown_to_csv.py`（待创建）

**用法：**
```bash
# 转换对话剧本
python tools/data_compiler/markdown_to_csv.py dialogue your_case_id dialogue.md

# 转换证据描述
python tools/data_compiler/markdown_to_csv.py evidence your_case_id evidence.md

# 转换地点描述
python tools/data_compiler/markdown_to_csv.py locations your_case_id locations.md

# 转换事件描述
python tools/data_compiler/markdown_to_csv.py events your_case_id events.md
```

---

## 写作建议

### 对话写作

1. **角色一致性**：保持每个角色的语言风格一致
2. **情绪标记**：合理使用情绪标记，增强表现力
3. **高亮使用**：标记关键信息，引导玩家注意
4. **选项设计**：选项应有明确的目的和反馈

### 描述写作

1. **简洁明了**：描述应简洁，避免冗长
2. **细节具体**：使用具体的细节增加真实感
3. **氛围营造**：通过描写营造合适的氛围

### 证据写作

1. **客观描述**：证据描述应客观，避免主观判断
2. **细节丰富**：包含足够的细节供玩家推理
3. **关联性**：明确证据与其他元素的关联

---

## 示例：完整对话剧本

```markdown
# NPC: lao_fan

## hub
> 哟……你就是那个同船的？听说周氏告了你杀人啊。胆子不小——被告了还到处问话。

### 选项
- [ask] 说说当晚的事 → intro
- [press] 为什么走那条航道？ → ask_route
  - 条件：fan_talked_once
- [press] 本地人都知道那条路危险，你跑了二十年不知道？ → press_route
  - 条件：clue_reef_common_knowledge
- [press] 你是怎么获救的？ → ask_rescue
  - 条件：fan_talked_once
- [press] 你那条船，船底以前修过没有？ → show_hull
  - 条件：evidence_hull_hole
- [press] 听说你最近手头有点紧？ → show_iou
  - 条件：evidence_gambling_iou
- [observe] 你跑船跑了二十年……怎么欠的赌债？ → ask_gambling_story
  - 条件：clue_fan_boat_skill
- [press] 那个'药材行的姑娘'——是她先找你的吧？ → press_shen_connection
  - 条件：agui_confessed_mastermind
- 先告辞 → __exit__

---

## intro
*老范的开场陈述*

**老范**：唉，天灾呗。那夜雨大浪急，我跑了二十年船没见过那阵仗。
*（得意）*

**老范**：那客人催得急啊！说要赶武昌的早市。走大路绕远，走那条——
*（得意）*

**老范**：嗐，老汉也知道有礁石。但水涨了以后，以前那礁石应该没过去了嘛。谁知道还露着。
*（得意）*

### 选项
- 继续询问 → hub
- 先告辞 → __exit__

---

## ask_route
*询问航线选择*

**陆昭**：为什么走那条航道？
*（严肃）*

**老范**：那客人催得急啊！说要赶武昌的早市。走大路绕远，走那条——
*（得意）*

**老范**：嗐，老汉也知道有礁石。但水涨了以后，以前那礁石应该没过去了嘛。谁知道还露着。
*（得意）*

### 选项
- 继续询问 → hub
- 先告辞 → __exit__
```

---

## 注意事项

### 格式要求

1. **编码**：使用 UTF-8 编码
2. **换行**：使用 LF 换行符（Unix 风格）
3. **缩进**：使用空格缩进，不要使用 Tab

### 特殊字符

1. **引号**：使用中文引号「」""''
2. **省略号**：使用……
3. **破折号**：使用——

### 代码块

使用代码块标记特殊内容：

```markdown
**陆昭**：
```
（内心独白）
这里应该仔细查看。
```
```

---

## 相关文档

- [案例数据规范](CASE_DATA_SPEC.md)
- [验证指南](VALIDATION_GUIDE.md)
- [CSV 模板](case_template/)

---

*文档版本：1.0*
*最后更新：2026-05-30*