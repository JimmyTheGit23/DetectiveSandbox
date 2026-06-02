# GDD 02 — NPC 知识管理模型

> 三级分层知识系统，控制 NPC 在对话中可透露的信息

---

## 1. 三级知识分层

```
┌──────────────────────────────────────┐
│ Level 2: 交互知识 (Dynamic)          │  ← append-only，对话中动态累积
├──────────────────────────────────────┤
│ Level 1: 观察知识 (Computed)         │  ← 基于时间线可推算
├──────────────────────────────────────┤
│ Level 0: 固有知识 (Static)           │  ← 角色背景，始终持有
└──────────────────────────────────────┘
```

---

## 2. Level 0 — 固有知识（Static）

NPC 始终知道的信息，在剧本生成时确定：

| 类型 | 示例 |
|------|------|
| 个人背景 | 姓名、职业、年龄、性格特征 |
| 社会关系 | 与其他 NPC 的关系（亲属/朋友/仇人/雇佣） |
| 日常习惯 | 通常几点在哪里、常去的地点 |
| 秘密 | 每个 NPC 至少有 1 个不愿透露的秘密 |
| 动机相关 | 是否有作案动机（凶手的真实动机在此层） |

### 数据结构

```gdscript
class_name NPCKnowledge_L0

var npc_id: String
var name: String
var occupation: String
var personality: Array[String]    # ["谨慎", "多疑", "善良"]
var relationships: Dictionary     # {npc_id: "关系描述"}
var daily_routine: Dictionary     # {time_period: location}
var secrets: Array[String]        # 不主动透露
var has_motive: bool
var motive_detail: String         # 仅凶手有实际值
```

---

## 3. Level 1 — 观察知识（Computed）

NPC 基于自身位置和时间线**可以观察到**的信息：

| 规则 | 说明 |
|------|------|
| 同一地点 | NPC 在某时段位于某地点，可观察到该地点同时段的其他人和事件 |
| 相邻地点 | 可听到声响但看不到详情 |
| 时间窗口 | 只知道自己在场期间发生的事 |

### 计算逻辑

```python
def compute_l1_knowledge(npc: NPC, timeline: List[TimelineEvent]) -> List[Observation]:
    observations = []
    for event in timeline:
        npc_location = get_npc_location(npc, event.time)
        if npc_location == event.location:
            # 同一地点：完整观察
            observations.append(Observation(
                event=event,
                clarity="clear",
                detail=event.full_description
            ))
        elif is_adjacent(npc_location, event.location):
            # 相邻地点：模糊感知
            observations.append(Observation(
                event=event,
                clarity="vague",
                detail=event.sound_description  # 只有声音描述
            ))
    return observations
```

---

## 4. Level 2 — 交互知识（Dynamic）

在游戏运行时动态累积的知识（append-only，不可删除）：

| 来源 | 说明 |
|------|------|
| 玩家告知 | 玩家在对话中向 NPC 透露的信息 |
| NPC 间传播 | 某些事件触发 NPC 之间的信息传递 |
| 事件触发 | 特定游戏事件使 NPC 获得新知识 |

### 数据结构

```gdscript
class_name NPCKnowledge_L2

var entries: Array[KnowledgeEntry] = []

class KnowledgeEntry:
    var source: String          # "player" / "npc_xxx" / "event_xxx"
    var content: String         # 知识内容
    var day_acquired: int       # 获取日期
    var time_acquired: String   # 获取时段
    var trust_required: float   # 透露此信息所需的最低信任度
```

---

## 5. 知识查询：构建 NPC 对话上下文

对话系统在生成可用选项时，查询 NPC 的完整知识：

```python
def build_npc_context(npc_id: str, current_day: int, current_time: str) -> NPCContext:
    l0 = load_static_knowledge(npc_id)
    l1 = compute_observations(npc_id, current_day, current_time)
    l2 = load_dynamic_knowledge(npc_id)
    
    return NPCContext(
        # NPC 可以回答的问题范围
        answerable_topics=merge_topics(l0, l1, l2),
        # NPC 会主动隐瞒的信息
        hidden_info=l0.secrets + get_lies(npc_id),
        # NPC 的情绪状态影响回答方式
        emotional_state=compute_emotion(npc_id, current_day),
        # 信任度决定是否透露敏感信息
        trust_level=get_trust(npc_id)
    )
```

---

## 6. 知识隔离原则

| 原则 | 说明 |
|------|------|
| NPC 不全知 | 每个 NPC 只知道自己知识层级内的信息 |
| 凶手有谎言 | 凶手的 L1 观察知识中包含蓄意伪造的版本 |
| 信息不可逆 | L2 知识只增不减，玩家告知 NPC 的信息无法撤回 |
| 信任度门槛 | 敏感信息需要达到信任度阈值才能获取 |
| 矛盾标记 | 当同一事件存在多个矛盾版本时，系统自动标记 |
