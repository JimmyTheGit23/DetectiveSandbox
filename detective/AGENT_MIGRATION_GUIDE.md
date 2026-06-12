# Agent流程迁移指南

> 日期：2026-06-12
> 要把这套Agent对话重写流程搬到另一台机器，需复制以下文件。

---

## 一、必需目录/文件

### 1. Agent定义（.codebuddy/agents/）—— 18个文件

**主角Agent：**
- `.codebuddy/agents/陆昭.md` — 陆昭（隐秘御史，主角）
- `.codebuddy/agents/凌瑶.md` — 凌瑶（金鳞镖局，助手）

**序章NPC Agent：**
- `.codebuddy/agents/周德茂.md` — 死者（布商/漕运中间人）
- `.codebuddy/agents/阿贵.md` — 死者仆从（被操纵的棋子）
- `.codebuddy/agents/老范.md` — 船家（共犯）
- `.codebuddy/agents/沈清月.md` — 真凶（金陵沈家之女）
- `.codebuddy/agents/周氏.md` — 死者妻子
- `.codebuddy/agents/王大爷.md` — 渔翁（关键证人）
- `.codebuddy/agents/钱里正.md` — 地方小吏

**质量审查Agent（7个）：**
- `.codebuddy/agents/剧本作家.md`
- `.codebuddy/agents/逻辑审查官.md`
- `.codebuddy/agents/角色语感审查官.md`
- `.codebuddy/agents/节奏审查官.md`
- `.codebuddy/agents/台词质量审查官.md`
- `.codebuddy/agents/历史考据审查官.md`
- `.codebuddy/agents/总导演.md`
- `.codebuddy/agents/真人对话审查官.md`
- `.codebuddy/agents/叙事总监.md`

### 2. 项目规则
- `CLAUDE.md` — 项目级规则（Art generation + 文案质量管道）

### 3. 设计文档
- `docs/narrative/PROLOGUE_CHARACTER_ARCHIVE.md` — 序章角色设定归档
- `docs/narrative/PROLOGUE_DIALOGUE_RESTRUCTURE_BLUEPRINT.md` — 重构蓝图（含11条铁则）
- `docs/narrative/PROLOGUE_DIALOGUE_REWRITE_LOG.md` — 执行归档（进度追踪）
- `docs/narrative/DIALOGUE_REWRITE_PLAN.md` — 原改写计划

### 4. 游戏数据文件
```
data/case_tables/prologue_ferry/
├── prologue_lines.csv        — 序章开场叙述
├── dialogue_lines.csv        — NPC对话线
├── dialogue_nodes.csv        — 对话节点定义
├── dialogue_options.csv      — 对话选项
├── day_events.csv            — 事件定义
├── day_event_lines.csv       — 事件对话
├── companion_banter.csv      — 同伴闲聊（六区已补齐）
├── companion_discussions.csv — 同伴系统讨论
├── testimony_statements.csv  — 证词定义
├── testimony_press_lines.csv — 证词追问线
├── testimony_break_lines.csv — 证词击破线
├── testimony_wrong_reactions.csv — 错证反馈
├── testimony_sets.csv        — 证词组定义
└── characters.csv            — 角色表
```

### 5. 工具脚本
- `tools/data_compiler/validate_case_tables.py` — CSV完整性校验

---

## 二、使用流程

### 在新机器上启动Agent对话重写：

1. **复制所有上述文件到对应位置**

2. **在新会话中，让AI读取规则文件**：
   ```
   读 CLAUDE.md → 确认管道规则
   读 docs/narrative/PROLOGUE_DIALOGUE_RESTRUCTURE_BLUEPRINT.md → 确认11条铁则
   读 docs/narrative/PROLOGUE_CHARACTER_ARCHIVE.md → 确认角色设定
   读 docs/narrative/PROLOGUE_DIALOGUE_REWRITE_LOG.md → 了解当前进度
   ```

3. **创建Team并spawn Agent**：
   - 提示词中明确：
     - 角色身份 + 语癖
     - 11条铁则（无括号、纯台词、历史考据、凌瑶不越界…）
     - 场景任务
   - 使用 `send_message` 让Agent互相对话产出

4. **产出写入CSV后运行校验**：
   ```bash
   python tools/data_compiler/validate_case_tables.py --case prologue_ferry
   ```

---

## 三、当前进度总览

| 项目 | 状态 | 产出 |
|------|------|------|
| S1 冷开场沉船+半个时辰前 | ✅ 已写入 | prologue_lines.csv |
| S2 船舱调查（陆昭×3NPC） | ✅ 已写入 | dialogue_lines.csv/nodes.csv |
| 区1-6 闲聊补齐 | ✅ 已完成 | companion_banter.csv, day_event_lines.csv |
| S3 凌瑶救人 | ✅ Agent产出 | 待写入 day_event_lines.csv |
| S4 渡口指控 | ✅ Agent产出 | 待写入 day_event_lines.csv |
| 王大爷对峙轮 | ✅ Agent产出 | 待写入 testimony_press/break_lines.csv |
| 老范对峙轮 | ✅ Agent产出 | 待写入 testimony_press/break_lines.csv |
| 阿贵对峙轮 | ⬜ Agent产出中 | 已有证词20条，待对话 |
| 沈清月终局 | ⬜ Agent产出中 | 已有证词20条，待对话 |
| 五官质量审查 | ⬜ 未开始 | — |
| 总导演终审 | ⬜ 未开始 | — |

---

## 四、11条铁则速查

1. 朗读测试：出声念，不磕巴
2. 现场感测试：角色对眼前情境说话，非对观众解释
3. 反应先于判断：先有情绪再有理性
4. 一句一事：一句话只做一件事
5. 不写判词：台词是对话，非审判词/标语/谜语
6. 不写括号动作：严禁任何形式括号内容
7. 不写分析腔：用身体感受+具体瞬间，非总结判断
8. 凌瑶不做策略分析：只说身体感受/具体瞬间/困惑关心
9. 每段有案外生活：至少30%非功利交流
10. 对峙中非功利≥30%：关心/情绪/生活细节/沉默陪伴
11. 历史考据（万历年间）：禁用"饼干""OK""搞定"等
