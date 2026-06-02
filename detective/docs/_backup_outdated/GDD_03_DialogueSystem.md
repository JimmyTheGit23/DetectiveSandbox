# GDD 03 — 选项制对话系统

> 零运行时成本的动态对话选项系统

---

## 1. 设计目标

- **零 API 成本**: 运行时不调用任何 LLM
- **动态选项**: 根据玩家状态、持有线索、NPC 信任度自动增减可选项
- **精确叙事控制**: 每个选项的效果预先定义，不存在 AI 幻觉
- **高重玩性**: 不同路线看到不同选项组合

---

## 2. 对话选项数据结构

```gdscript
class_name DialogueOption

var id: String                    # "baker_tom_q1_opt1"
var category: String              # "闲聊" / "试探" / "质问" / "出示证据" / "施压"
var display_text: String          # 玩家看到的选项文本
var npc_response: String          # NPC 的回答文本
var conditions: Array[Condition]  # 显示此选项需要满足的条件
var effects: Array[Effect]        # 选择此选项后的效果
```

---

## 3. 条件类型（Conditions）

| 条件类型 | 参数 | 说明 |
|----------|------|------|
| `HasEvidence` | evidence_id | 玩家持有某个物证 |
| `HasTestimony` | testimony_id | 玩家持有某条证词 |
| `ContradictionDetected` | contradiction_id | 玩家已发现某个矛盾 |
| `PressureAbove` | threshold (float) | 当前施压值超过阈值 |
| `TimeOfDay` | period (string) | 当前时段匹配 |
| `DayRange` | min_day, max_day | 当前游戏日在范围内 |
| `NotYetAsked` | option_id | 玩家尚未选过某选项 |
| `RelationshipAbove` | npc_id, threshold | 与 NPC 的信任度超过阈值 |
| `RelationshipBelow` | npc_id, threshold | 与 NPC 的信任度低于阈值 |
| `FlagSet` | flag_name | 某个全局标记已设置 |
| `FlagNotSet` | flag_name | 某个全局标记未设置 |
| `CognitiveBelow` | threshold | 认知负荷低于阈值（头脑清醒才能问高难度问题） |

### 条件组合规则

- 同一选项的多个条件默认为 **AND** 关系
- 支持 `OR` 组合，使用嵌套数组表示

---

## 4. 效果类型（Effects）

| 效果类型 | 参数 | 说明 |
|----------|------|------|
| `GainClue` | clue_id | 获得线索 |
| `GainTestimony` | testimony_id, npc_id | 获得某 NPC 的证词 |
| `ModifyPressure` | npc_id, delta | 修改 NPC 被施压值 |
| `ModifyCognitive` | delta | 修改玩家认知负荷 |
| `ModifyTrust` | npc_id, delta | 修改 NPC 信任度 |
| `RevealContradiction` | contradiction_id | 揭露一个矛盾 |
| `TriggerEvent` | event_id | 触发特定事件 |
| `UnlockLocation` | location_id | 解锁新地点 |
| `SetFlag` | flag_name | 设置全局标记 |
| `ModifyAlertness` | delta | 修改凶手警觉度 |
| `ConsumeTime` | minutes | 消耗时间 |
| `AddKnowledge_L2` | npc_id, content | 向 NPC 添加交互知识 |

---

## 5. 对话树 JSON 格式

```json
{
  "npc_id": "baker_tom",
  "nodes": {
    "root": {
      "npc_greeting": "你好，侦探。今天的面包刚出炉。",
      "options": [
        {
          "id": "baker_tom_root_opt1",
          "category": "闲聊",
          "display_text": "最近生意怎么样？",
          "npc_response": "还行吧，不过自从出了那件事，来的人少了不少。",
          "conditions": [],
          "effects": [
            {"type": "ModifyTrust", "npc_id": "baker_tom", "delta": 5},
            {"type": "ConsumeTime", "minutes": 5}
          ],
          "next_node": "after_smalltalk"
        },
        {
          "id": "baker_tom_root_opt2",
          "category": "试探",
          "display_text": "案发那晚你在哪里？",
          "npc_response": "我在店里加班，一直忙到很晚。问隔壁的老王，他可以作证。",
          "conditions": [],
          "effects": [
            {"type": "GainTestimony", "testimony_id": "tom_alibi_001", "npc_id": "baker_tom"},
            {"type": "ConsumeTime", "minutes": 10}
          ],
          "next_node": "after_alibi"
        },
        {
          "id": "baker_tom_root_opt3",
          "category": "出示证据",
          "display_text": "我在你店后面发现了这把刀...",
          "npc_response": "（神色一变）那...那是我切面包用的，怎么会在外面？",
          "conditions": [
            {"type": "HasEvidence", "evidence_id": "bloody_knife_001"}
          ],
          "effects": [
            {"type": "GainClue", "clue_id": "tom_nervous_about_knife"},
            {"type": "ModifyPressure", "npc_id": "baker_tom", "delta": 20},
            {"type": "ModifyAlertness", "delta": 10},
            {"type": "ConsumeTime", "minutes": 10}
          ],
          "next_node": "knife_confrontation"
        }
      ]
    },
    "after_smalltalk": {
      "npc_greeting": "你还想知道什么？",
      "options": [
        "..."
      ]
    }
  }
}
```

---

## 6. 对话类别与消耗

| 类别 | 时间消耗 | 认知负荷 | 信任度影响 | 警觉度影响 |
|------|----------|----------|------------|------------|
| 闲聊 | 5 min | 0 | +3~+5 | 0 |
| 试探 | 10 min | +2 | -1~+2 | +2 |
| 质问 | 10 min | +5 | -5~-10 | +5 |
| 出示证据 | 10 min | +3 | 视反应 | +5~+15 |
| 施压 | 15 min | +8 | -10~-15 | +10 |
| 安抚 | 10 min | -2 | +5~+10 | 0 |

---

## 7. 选项动态增减规则

### 增加选项
- 获得新线索 → 解锁相关 NPC 的「出示证据」选项
- 发现矛盾 → 解锁「质问」选项
- 信任度达标 → 解锁私密话题
- 推进天数 → 解锁后期选项

### 减少选项
- 已选过的「一次性」选项不再出现
- 信任度过低 → NPC 拒绝交谈，选项全部变为「道歉」「离开」
- 认知负荷过高 → 复杂选项（质问/施压）变灰不可选
- NPC 施压值过高 → NPC 沉默，仅剩基础选项

---

## 8. 每日对话次数限制

| 参数 | 值 |
|------|-----|
| 每日总对话次数 | 10-15 次 |
| 同一 NPC 每日对话上限 | 3 次 |
| 施压/质问每日上限 | 共 3 次 |
