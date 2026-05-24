# GDD 01 — 脚本生成引擎

> 负责在每局开始前生成唯一的案件剧本

---

## 1. 三层架构

```
┌─────────────────────────────────────┐
│  Layer 3: 约束求解器 (Validator)     │  ← 纯规则，校验一致性
├─────────────────────────────────────┤
│  Layer 2: LLM 填槽 + 润色 (Filler)  │  ← AI 生成，仅在开局前调用
├─────────────────────────────────────┤
│  Layer 1: 犯罪骨架模板 (Template)    │  ← 50-100 个预制模板
└─────────────────────────────────────┘
```

---

## 2. Layer 1 — 犯罪骨架模板

每个模板定义：

| 字段 | 说明 | 示例 |
|------|------|------|
| crime_type | 犯罪类型 | 毒杀、密室、坠楼伪装 |
| timeline_slots | 时间线槽位（关键节点） | 作案前、作案中、作案后 |
| evidence_slots | 物证槽位 | 凶器位置、关键物品、痕迹 |
| motive_pattern | 动机模式 | 财产纠纷、情感纠葛、秘密掩盖 |
| alibi_weakness | 不在场证明漏洞模式 | 时间缝隙、证人矛盾、伪造痕迹 |
| min_suspects | 最少嫌疑人数 | 3 |
| red_herrings | 误导线索数 | 1-3 |

### 模板数据结构

```python
@dataclass
class CrimeTemplate:
    id: str                          # "template_poison_001"
    crime_type: str                  # "毒杀"
    timeline_slots: List[TimeSlot]   # 关键时间节点
    evidence_slots: List[EvidenceSlot]
    motive_pattern: str
    alibi_weakness: str
    min_suspects: int
    red_herring_count: range         # range(1, 4)
    difficulty: int                  # 1-5
```

---

## 3. Layer 2 — LLM 填槽 + 润色

AI（开局前调用一次）负责：

1. **选择模板** — 根据难度和随机种子
2. **分配角色** — 为每个槽位分配 NPC（凶手、受害者、嫌疑人、证人）
3. **填充具体内容** — 生成具体的时间、地点、物品名称
4. **生成 NPC 记忆片段** — 每个 NPC 对事件的主观记忆
5. **生成对话树** — 基于角色知识和性格生成完整对话选项

### 生成产物

```python
@dataclass
class CrimeScript:
    template_id: str
    victim: str
    murderer: str
    suspects: List[str]
    timeline: List[TimelineEvent]    # 完整事件时间线
    evidence_map: Dict[str, Evidence] # 物证分布
    npc_memories: Dict[str, List[Memory]]  # NPC 记忆
    dialogue_trees: Dict[str, DialogueTree] # 对话树
    contradiction_graph: Graph       # 矛盾关系图
    solution: SolutionData           # 正确答案
```

---

## 4. Layer 3 — 约束求解器

纯规则校验，不依赖 AI，确保生成内容逻辑自洽：

### 校验规则

| 规则 | 说明 |
|------|------|
| 时间线一致性 | 同一 NPC 不能同时出现在两个地点 |
| 物证可达性 | 所有关键物证必须可被玩家通过合理路径获取 |
| 可解性保证 | 必须存在至少一条推理链从初始线索到达真相 |
| 矛盾可发现性 | 每个矛盾必须有至少两条对立证词/证据可触发 |
| 红鲱鱼平衡 | 误导线索必须有可证伪路径 |

### 校验函数示例

```python
def validate(script: CrimeScript) -> ValidationResult:
    errors = []
    
    # 1. 时间线一致性
    for npc in script.suspects:
        events = [e for e in script.timeline if e.actor == npc]
        for i, e1 in enumerate(events):
            for e2 in events[i+1:]:
                if e1.overlaps(e2) and e1.location != e2.location:
                    errors.append(f"时间冲突: {npc} 在 {e1.time} 同时出现在 {e1.location} 和 {e2.location}")
    
    # 2. 物证可达性
    for eid, evidence in script.evidence_map.items():
        if not evidence.is_reachable_by_player():
            errors.append(f"物证不可达: {eid} 在 {evidence.location}")
    
    # 3. 可解性（推理链验证）
    if not find_deduction_path(script.evidence_map, script.solution):
        errors.append("致命: 无法从初始线索推导出正确答案")
    
    # 4. 矛盾可发现性
    for contradiction in script.contradiction_graph.nodes:
        sources = script.contradiction_graph.edges(contradiction)
        if len(sources) < 2:
            errors.append(f"矛盾 {contradiction.id} 缺少可发现路径")
    
    return ValidationResult(
        is_valid=len(errors) == 0,
        errors=errors
    )
```

---

## 5. 三种免费生成方案

| 方案 | 说明 | 适用场景 |
|------|------|----------|
| A: 纯本地 LLM | 使用 llama.cpp 等本地推理 | 玩家硬件较好 |
| B: 纯预制模板 | 50-100 套完整预制剧本，无需 AI | 最低配置需求 |
| C: 混合方案 | 预制骨架 + 本地 LLM 填细节 | **推荐** |

推荐采用 **方案 C**：预制大量骨架模板，细节由本地小模型或规则随机化填充。
