# PCG 工具链（Procedural Case Generation）

> **状态**: M1.1 犯罪骨架模板层完成（2026-05-17）  
> **总览**: [docs/ROADMAP_PCG.md](../../docs/ROADMAP_PCG.md)  
> **设计基础**: [docs/GDD_01_ScriptEngine.md](../../docs/GDD_01_ScriptEngine.md)

PCG 把"案件"分成**三层**：

```
Layer 3: 约束求解器（Validator）   ← 纯规则，校验生成结果
Layer 2: 填槽器（Filler）           ← 把骨架的 slot 具体化为 case.json + casting.json + dialogues/*
Layer 1: 犯罪骨架（Template）       ← 本目录，描述"案件结构"而非"案件内容"
```

本 README 主要描述 **Layer 1**（M1.1）。

---

## 目录结构

```
tools/pcg/
├── README.md                       # 本文档
├── schemas/
│   └── template_schema.json        # JSON Schema：骨架模板的字段定义
├── templates/
│   ├── tpl_001_old_grudge_poisoning.json     # ★4 旧仇毒杀（临川驿案脱壳参照）
│   ├── tpl_002_jealousy_fall_disguised.json  # ★3 情敌伪装坠楼
│   └── tpl_003_impersonation_inheritance.json # ★5 冒名顶替继承
└── inspect_template.py             # 模板可视化检查工具
```

---

## 设计原则

### 1. 骨架不写"具体内容"，只写"结构与约束"

骨架只声明：
- **角色画像**（`archetype_tags`：性别 / 年龄段 / 职业类 / 性格类）—— 不指定具体 actor_id
- **场景类型**（`scene_archetype`）—— 不指定具体 scene_id
- **物证语义**（`category`：weapon_or_method / motive_proof / alibi_breaker / identity_proof / background_context / false_lead）—— 不指定具体物品名
- **时间相对位置**（`pre_crime` / `crime_moment` / `D1.morning` / …）—— 不绑死绝对时段

具体化由 M1.2 填槽器做，演员/场景由 M3 选角器结合资产抽象层（M2）解决。

### 2. 难度由 6 个量化指标合成

`difficulty.factors` 包含：
- `suspect_count` —— 嫌疑人数
- `min_evidence_required` —— 完美结局所需关键证据数
- `contradiction_count` —— 关键矛盾对数
- `red_herring_count` —— 误导线索数
- `key_evidence_depth` —— surface / moderate / buried
- `motive_obfuscation` —— overt / misdirected / hidden

聚合后映射到 1-5 ★ 显示给玩家。

### 3. 每个矛盾必须可破

骨架要求 `contradictions[*].rebuttal_sources.length >= 2`——任意单个证据丢失/没拿到，玩家仍有备用路径揭穿矛盾，避免"卡死的死路"。

### 4. 每个红鲱鱼必须有反驳路径

`red_herrings[*].rebuttal` 必须非空，且引用的 evidence/contradiction 必须存在。否则玩家可能被永远误导。

### 5. solution_skeleton.deduction_chain 必须可达真凶

推理链是"从初始线索经若干步推到真凶"的有向证明链。每步引用的 evidence/contradiction 都须在前一步可达——这是 M1.3 校验器最重要的"可解性证明"。

---

## Schema 字段速查

详见 [`schemas/template_schema.json`](schemas/template_schema.json)，关键字段：

| 字段 | 说明 |
|------|------|
| `id` | 全局唯一，蛇形，前缀 `tpl_` |
| `crime_type` | 类型枚举：poisoning / drowning / stabbing / strangulation / fall_disguised / locked_room / missing_person / impersonation / framed_innocent |
| `roles[]` | 角色画像列表，每条含 slot_id / function（player/victim/culprit/suspect/witness/informant/authority）/ archetype_tags / knowledge_topics / lie_topics / trust_pattern / alibi |
| `location_slots[]` | 地点槽位 + scene_archetype 标签 |
| `timeline_slots[]` | 时间线，phase 用相对时间，produces_evidence 关联到 evidence_slots |
| `evidence_slots[]` | 证据槽位，分 key / supporting / red_herring；discovery_path 指定 search@地点 / dialogue<-角色 / derived |
| `contradictions[]` | 矛盾点，rebuttal_sources ≥ 2 |
| `red_herrings[]` | 误导线索包，必须有 rebuttal 路径 |
| `solution_skeleton` | 真凶 / 动机 / 手法 / 关键证据集合 / 推理链 |
| `endings_pattern` | 五档结局判定阈值 |
| `constraints.hard / soft` | 生成器须满足的硬/软约束声明 |

---

## 编写一个新模板（SOP）

1. **选定 crime_type**（schema 的枚举里挑一个）和星级。
2. **画时间线** —— 先列 `timeline_slots`，至少要有 `crime_moment`、若干 `alibi_claim`、一个 `discovery`。
3. **设计角色** —— 一个真凶、若干嫌疑人、必要证人 / 线人 / 权威。每个角色补 `archetype_tags`（性别+年龄+职业），决定 M3 选角空间。
4. **铺物证** —— 至少 3 件 key 证据，覆盖 weapon_or_method / motive_proof / alibi_breaker 三类。补 supporting 证据用于推进，补 red_herring 制造误导。
5. **补矛盾** —— 真凶至少要有一条可被破的谎言（lie_topics 里一项进入 contradictions）。每条矛盾至少 2 个 rebuttal source。
6. **写推理链** —— 从 `timeline_body_discovery` 出发，逐步引用 evidence/contradiction，最后一步 `concludes` 必须直接命中真凶 slot_id。
7. **跑校验** —— `python tools/pcg/inspect_template.py 你的模板.json`：先看健康检查全绿，再看时间线/角色/证据/矛盾视图是否符合预期。
8. **跑 schema 校验**：
   ```bash
   python3 -c "import json,jsonschema; \
     s=json.load(open('tools/pcg/schemas/template_schema.json')); \
     t=json.load(open('你的模板.json')); \
     jsonschema.validate(t,s); print('OK')"
   ```

---

## 工具：`inspect_template.py`

```bash
# 渲染单份模板的完整报告
python3 tools/pcg/inspect_template.py tools/pcg/templates/tpl_001_old_grudge_poisoning.json

# 一行摘要 + 健康检查
python3 tools/pcg/inspect_template.py --all --brief

# 全部模板的完整报告
python3 tools/pcg/inspect_template.py --all
```

报告含 7 个视图：META / ROLES / TIMELINE / EVIDENCE / CONTRADICTIONS / RED_HERRINGS / SOLUTION + HEALTH 自检。

`--brief` 模式输出形如：
```
OK  tpl_001_old_grudge_poisoning             | poisoning          | ★4 | 9 roles | 8 evidence
OK  tpl_002_jealousy_fall_disguised          | fall_disguised     | ★3 | 7 roles | 6 evidence
OK  tpl_003_impersonation_inheritance        | impersonation      | ★5 | 8 roles | 6 evidence
```

退出码非零 = 至少一个模板的健康检查不通过，可作为 CI 门禁。

---

## 健康检查规则（inspect_template.py 内置）

不读 schema 也能跑的常识规则：

1. `solution.culprit_slot` 必须在 roles 中，且对应角色 `is_culprit=true`
2. 整个模板必须**有且仅有 1 个**真凶
3. `solution.key_evidence_slots` 中每条都要在 evidence_slots 内定义
4. 所有 `discovery_path.hint_location` / `from_actor` 引用合法
5. `discovery_path.preconditions` 中的 ID 必须是已定义的 evidence 或 contradiction
6. 每条矛盾的 `rebuttal_sources` ≥ 2 且全部存在
7. 每个 red_herring 必须有 rebuttal 路径，且 rebuttal 引用合法
8. timeline_slots 的 actor 必须在 roles 中（除非显式 'unknown'）
9. 真凶必须配置至少一条 `lie_topics`（否则没有谎言可识破）
10. `deduction_chain` 最后一步的结论应直接指向真凶

---

## 当前模板库

| ID | crime_type | 难度 | 角色数 | 证据数 | 灵感来源 |
|----|------------|------|-------|-------|---------|
| tpl_001_old_grudge_poisoning | poisoning | ★4 | 9 | 8 | 临川驿案（首部参照） |
| tpl_002_jealousy_fall_disguised | fall_disguised | ★3 | 7 | 6 | 通用情爱纠葛骨架 |
| tpl_003_impersonation_inheritance | impersonation | ★5 | 8 | 6 | 经典身份顶替骨架 |

> 目标：M1 阶段达到 **10 套骨架**，覆盖 schema 中所有 `crime_type` 至少一次。

---

## 接下来（M1.2 / M1.3）

- **M1.2 填槽器** —— 输入：模板 + 随机种子 + 演员库 + 场景库。输出：`data/cases/<case_id>/case.json + casting.json + locations.json + bgm_config.json + npcs.json + dialogues/*.json`。
- **M1.3 约束校验器** —— 跑过填槽器之后，独立校验"时间线一致 / 物证可达 / 可解性 / 矛盾合法"，失败即重生成或回滚。
- **M1.4 对话树派生** —— 每个角色基于 `knowledge_topics` + `lie_topics` 自动派生选项树。
- **M1.5 ScriptLoader.gd** —— Godot 端从生成的 case.json 反向加载游戏状态。
