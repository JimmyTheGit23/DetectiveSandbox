# Agent对话重写系统 · 完整迁移指南

> 日期：2026-06-12
> 要让别的开发者在另一台机器上启用这套Agent流程，按以下步骤操作。

---

## 一、必需复制的文件

### 1. Agent定义（.codebuddy/agents/）—— 18个文件

**主角Agent：**
- `陆昭.md` — 陆昭（隐秘御史，主角）
- `凌瑶.md` — 凌瑶（金鳞镖局，助手）

**序章NPC Agent（7人）：**
- `周德茂.md` — 死者（布商/漕运中间人）
- `阿贵.md` — 死者仆从（被操纵的棋子）
- `老范.md` — 船家（共犯）
- `沈清月.md` — 真凶（金陵沈家之女）
- `周氏.md` — 死者妻子
- `王大爷.md` — 渔翁（关键证人）
- `钱里正.md` — 地方小吏

**质量审查Agent（9人）：**
- `剧本作家.md` — 写/改文本
- `逻辑审查官.md` — 证物矛盾/flag死循环
- `角色语感审查官.md` — 语癖贯穿/遮名辨识
- `节奏审查官.md` — 三拍子/情绪曲线/冗余密度
- `台词质量审查官.md` — 书面语/翻译腔检测
- `历史考据审查官.md` — 明代万历年用语
- `真人对话审查官.md` — "真人不这么说"检测
- `叙事总监.md` — 剧情一致性
- `总导演.md` — 终审加权打分

### 2. 项目规则
- `CLAUDE.md` — 项目级规则（含14条铁则）

### 3. 设计文档
```
docs/narrative/
├── PROLOGUE_CHARACTER_ARCHIVE.md    — 序章角色设定归档
├── PROLOGUE_DIALOGUE_RESTRUCTURE_BLUEPRINT.md — 重构蓝图
├── PROLOGUE_DIALOGUE_REWRITE_LOG.md — 执行进度追踪
└── ACE_ATTORNEY_DESIGN_PATTERNS.md  — 逆转裁判设计模式
```

### 4. 游戏数据文件（14个CSV）
```
data/case_tables/prologue_ferry/
├── prologue_lines.csv              — 序章开场
├── dialogue_lines.csv              — NPC对话线
├── dialogue_nodes.csv              — 对话节点定义
├── dialogue_options.csv            — 对话选项
├── day_events.csv                  — 事件定义
├── day_event_lines.csv             — 事件对话
├── companion_banter.csv            — 同伴闲聊
├── companion_discussions.csv       — 同伴讨论
├── testimony_statements.csv        — 证词定义
├── testimony_press_lines.csv       — 证词追问线
├── testimony_break_lines.csv       — 证词击破线
├── testimony_wrong_reactions.csv   — 错证反馈
├── testimony_sets.csv              — 证词组定义
└── characters.csv                  — 角色表
```

### 5. 工具脚本
- `tools/data_compiler/validate_case_tables.py` — CSV校验

---

## 二、在新机器上启动

### 步骤1：复制文件
将上述全部文件复制到新项目的对应目录。

### 步骤2：让AI读取规则
在新会话中执行：
```
1. 读 CLAUDE.md → 确认14条铁则
2. 读 docs/narrative/PROLOGUE_DIALOGUE_RESTRUCTURE_BLUEPRINT.md → 确认重构目标
3. 读 docs/narrative/PROLOGUE_CHARACTER_ARCHIVE.md → 确认角色设定
4. 读 docs/narrative/PROLOGUE_DIALOGUE_REWRITE_LOG.md → 了解当前进度
```

### 步骤3：创建Team
```
1. 使用 team_create 创建团队（如"序章演出"）
2. 用 task 工具 spawn 所有需要的Agent（mode=bypassPermissions）
3. 每个Agent的prompt中明确角色身份和场景任务
```

### 步骤4：驱动Agent对话
用 `send_message` 让Agent互相对话产出台词：
- 主角Agent先发起场景
- NPC Agent用send_message回复
- 收集全部产出后写入CSV
- 运行校验确认无错误

### 步骤5：校验并提交
```
python tools/data_compiler/validate_case_tables.py --case prologue_ferry
git add -A && git commit && git push
```

---

## 三、14条铁则速查

| # | 铁则 | 说明 |
|---|------|------|
| 1 | 朗读测试 | 出声念，不磕巴 |
| 2 | 现场感 | 对眼前情境说话，非对观众解释 |
| 3 | 反应先于判断 | 先有情绪再有理性 |
| 4 | 一句一事 | 一句话只做一件事 |
| 5 | 不写判词 | 台词是对话，非审判词/标语 |
| 6 | 不写括号动作 | 严禁任何形式括号内容 |
| 7 | 不写分析腔 | 用身体感受+具体瞬间 |
| 8 | 凌瑶不做策略分析 | 只说身体感受/具体瞬间/困惑关心 |
| 9 | 每段有案外生活 | 至少30%非功利交流 |
| 10 | 对峙中非功利≥30% | 关心/情绪/生活细节/沉默陪伴 |
| 11 | 历史考据 | 万历年间，禁用"饼干""OK""搞定" |
| 12 | 闲聊模式 | 陆昭先说自己的感受再问人 |
| 13 | 4话题上限 | 每个NPC恰好4条话题 |
| 14 | 双向禁止复读 | 任何人说完，对方不得原样重复关键词 |

---

## 四、当前进度

| 场景 | CSV | 状态 |
|------|-----|------|
| S1 冷开场+时代背景 | prologue_lines.csv | ✅ 17行精简版 |
| S2 船舱闲谈（陆昭×3NPC） | dialogue_lines.csv | ✅ 49行完整对话 |
| S3 凌瑶救人 | day_event_lines.csv | ✅ |
| S4 渡口指控 | day_event_lines.csv | ✅ |
| 区1-6 闲聊补齐 | companion_banter.csv | ✅ |
| 王大爷对峙轮 | testimony_press/break | 🔴 待Agent对话 |
| 老范对峙轮 | testimony_press/break | 🔴 待Agent对话 |
| 阿贵对峙轮 | testimony_press/break | 🔴 待Agent对话 |
| 沈清月终局 | testimony_press/break | 🔴 待Agent对话 |
| 五官质量审查 | — | 🔴 待做 |
| 总导演终审 | — | 🔴 待做 |
