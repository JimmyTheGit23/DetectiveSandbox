# 序章台词重构执行归档

> 日期：2026-06-12  
> 案例：序章《渡口沉舟》  
> 原则：不做逐句微调，按场景任务整组重写；保留证据链、节点 ID、条件和结局。

---

## 第一批：开场、救援、船舱闲谈

### 本批戏剧任务

| 场景 | 改写目标 | 落地方式 |
| --- | --- | --- |
| 冷开场沉船 | 先给危险和失控感，不让陆昭一开始就像旁观者 | 增加惊醒、官印乱响、门外阻挡、呛水和手脚发麻 |
| 半个时辰前 | 建立陆昭的青年抱负和不安 | 写成第一次独领密旨，查漕运亏空账；承认心里没底，但不退 |
| 船舱调查 | 用闲谈预埋线索，少设定说明 | 周德茂水性和油味、阿贵包袱、老范东汊选择都从现场细节露出 |
| 凌瑶救人 | 让凌瑶先是救命恩人，再是搭档 | 她先扶人、递姜汤、记身份；可爱来自照料和轻松一句话，不靠连续吐槽 |
| 清晨指控 | 建立“被安排好的嫌疑” | 周氏情绪、阿贵指认、沈清月定题，陆昭被压住后仍先稳住事实 |

### 已改文件

- `data/case_tables/prologue_ferry/prologue_lines.csv`
- `data/case_tables/prologue_ferry/day_event_lines.csv`
- `data/case_tables/prologue_ferry/dialogue_lines.csv` 的船舱阶段节点
- `data/case_tables/prologue_ferry/dialogue_nodes.csv` 的船舱入口问候
- `data/case_tables/prologue_ferry/dialogue_options.csv` 的船舱选项文案
- `docs/narrative/PROLOGUE_DIALOGUE_RESTRUCTURE_BLUEPRINT.md`
- `docs/narrative/DIALOGUE_REWRITE_PLAN.md`

### 新增规则

- 对白要像人在现场说话：短、明白，先反应，再判断。
- 少用漂亮比喻、抽象大词和谜语式台词。
- 保留轻微古代语境，但不堆文言，也不使用网络口语。
- 凌瑶可以闲聊，但闲聊要带出关系、照料或观察。
- 陆昭可以说理，但说理前要有人味：迟疑、感谢、歉意、克制的怒意或落水余悸。

### 保留骨架

- 未改 `node_id`、`npc_id`、`record_id`、`evidence_id`、`requires`。
- 未改变船舱阶段只有陆昭与三名乘客对话的结构。
- 未改变凌瑶救起陆昭、陆昭被指认为嫌疑人、进入王大爷对峙的流程。
- 未改变序章最终“真相被证明但沈清月未被法律压住”的方向。

### 校验结果

已通过：

```bash
python3 tools/data_compiler/validate_case_tables.py --case prologue_ferry
```

结果：`[OK] case=prologue_ferry 表格校验通过（0 warning）`

同时做了 CSV/嵌套 JSON 解析抽查，结果通过。

---

## 第一批后的建议

1. 重写 `companion_banter.csv` 和 `companion_discussions.csv`，让凌瑶的闲聊、降压和陪伴感稳定下来。
2. 重写 `testimony_wrong_reactions.csv`，把错证反馈从攻略提示改成角色化反馈。
3. 再按王大爷、老范、阿贵的顺序改中段对峙，最后处理沈清月终局。

---

## 第二批：凌瑶同伴闲聊与讨论

### 本批戏剧任务

| 场景 | 改写目标 | 落地方式 |
| --- | --- | --- |
| 触发闲聊 | 降低凌瑶的攻略腔和嘴碎感 | 先给情绪、照料或生活观察，再轻推方向 |
| 方向提示 | 保留玩家可用性，但不直接报答案 | 用押镖经验、时限压力、能落纸的证据来缩小争点 |
| 证据获得反应 | 不把每个证据都喊成最终答案 | 让凌瑶判断“能压哪句话”“还缺哪条链” |
| 沈清月相关讨论 | 提前建立终局压迫感 | 凌瑶从直觉不舒服，逐步意识到沈清月会拆证据 |
| 闲聊话题 | 更可爱，但不过度现代 | 姜汤、人情、押镖、话多但会收、确认“我还在” |

### 已改文件

- `data/case_tables/prologue_ferry/companion_banter.csv`
- `data/case_tables/prologue_ferry/companion_discussions.csv`

### 保留骨架

- 未改 `banter_id`、`topic_id`、触发器、条件结构和优先级。
- 保留所有原有讨论类别：`next_direction`、`suspect_now`、`evidence_ready`、`chitchat`、`why_here`、`about_shen`。
- 保留同伴提示的可用性，但把“直接报答案”改为“缩小争点”。

### 校验结果

已单独通过：

```bash
companion_banter-ok
companion_discussions-ok
```

下一步应进入 `testimony_wrong_reactions.csv`，再处理三轮中段对峙。

---

## 第三批：错证反馈语气

### 本批戏剧任务

| 场景 | 改写目标 | 落地方式 |
| --- | --- | --- |
| 王大爷错证 | 减少直接报答案 | 从“拿某证据”改为“这句要过眼睛/耳朵/时间这一关” |
| 老范错证 | 区分手段、时间、动机 | 让凌瑶说明证物压不到哪句话，而不是直接切答案 |
| 阿贵错证 | 保留玩家方向，但不系统化 | “这件压不到他的话”“看他自己带了什么”等现场说法 |
| 沈清月错证反击 | 少比喻，增强法理压迫 | 把“花色不对、湿纸、茶桌听书”等改为“不相干、份量不够、缺物证” |

### 已改文件

- `data/case_tables/prologue_ferry/testimony_wrong_reactions.csv`

### 保留骨架

- 未改 `statement_id`、`evidence_id`、行顺序、speaker 和 emotion。
- 保留正确/错误证据的反馈关系，只改台词表达。

### 校验结果

已单独通过：

```bash
testimony_wrong_reactions-ok rows=173
no-leading-space
```

并清理了本文件中的旧式攻略腔关键表达：`方向不对`、`对，就这个`、`拿救起`、`花色不对`、`茶桌听书` 等。

下一步应进入 `testimony_press_lines.csv` / `testimony_break_lines.csv` 的中段对峙重写。
