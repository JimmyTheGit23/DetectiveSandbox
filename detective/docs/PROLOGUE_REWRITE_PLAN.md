# 序章「渡口沉舟」重写计划

## 核心改动：真凶由阿贵 → 沈清月

### 新案件结构

```
第一幕：开场逃生（不动）
第二幕：调查阶段A — 证据指向阿贵（现有基础+扩充+加入沈清月）
第三幕：中BOSS对峙 — 阿贵（90%复用，胜利后转折指向沈清月）
第四幕：调查阶段B — 追查幕后主谋（全新）
第五幕：FINAL BOSS对峙 — 沈清月（全新，高难度智商对决）
```

---

## Phase 1：角色与数据更新

### 1.1 新增沈清月角色卡 → `docs/character_profiles.md`
- 完整性格、口癖、情绪表、动作习惯
- 作为真凶的伪装层/真实层设计
- 对白风格示例

### 1.2 更新 `data/cases/prologue_ferry/casting.json`
- 新增 shen_qingyue 条目
- actor_id 留空（新角色需生成立绘）

### 1.3 更新 `data/cases/prologue_ferry/npcs.json`
- 新增 shen_qingyue 条目
- 配置对话文件路径

### 1.4 更新 `data/cases/prologue_ferry/evidence.json`
- 新增4件指向沈清月的证据：
  - evidence_salvage_mark（打捞痕迹）
  - evidence_shen_connection（赌坊中间人）
  - evidence_dock_timing（码头时间矛盾）
  - evidence_father_ledger（沈父账本/真实债务）

### 1.5 更新 `data/cases/prologue_ferry/case.json`
- culprit: "agui" → "shen_qingyue"
- suspects 列表新增沈清月
- motives 新增沈清月的动机
- key_evidence 更新
- confrontation 改为双阶段结构

---

## Phase 2：对白扩充（逆转裁判规格）

### 逆转裁判对白规格参考：
- 每个NPC每轮对话：6-12句（含助手评论）
- 每个NPC至少3-4轮对话（随证据解锁）
- 环境调查：每个场景5-10条描述
- 凌瑶讨论系统：独立50-80行
- 对峙证词：每句配4-6句press + 6-8句break

### 2.1 `dialogues/shen_qingyue.json`（全新）
- 调查A阶段：表演"飒爽债主"，3-4轮对话
- 调查B阶段：被追问后态度变化，3-4轮对话
- 总计约150-200行对白

### 2.2 扩充 `dialogues/agui.json`
- 当前：~30行 → 目标：~100行
- 增加：2-3轮新对话（被遣散的细节、与"某人"的接触暗示）
- 增加每轮对话的助手评论密度

### 2.3 扩充 `dialogues/lao_fan.json`
- 当前：~25行 → 目标：~100行
- 增加：赌坊关系追问、"谁介绍你的"线索
- 增加调查B阶段的二次审讯

### 2.4 扩充 `dialogues/zhou_wife.json`
- 当前：~25行 → 目标：~80行
- 增加：关于沈清月的看法、丈夫生意往来细节

### 2.5 扩充 `dialogues/li_zheng.json`
- 当前：~20行 → 目标：~80行
- 增加：关于沈清月的八卦、赌坊消息、码头夜间目击

### 2.6 扩充 `dialogues/fisherman_wang.json`
- 当前：极少 → 目标：~80行
- 全面重写：打捞目击、江面观察、铁证

---

## Phase 3：对峙系统改造

### 3.1 阿贵对峙（中BOSS）— 修改现有
- 保留三段证词结构（95%不动）
- 修改 victory_dialogue：
  - 删除阿贵自认主谋的台词
  - 改为：他供出"有人教我"→ 透露沈清月的线索
  - 添加凌瑶震惊 + 转折引导

### 3.2 沈清月对峙（FINAL BOSS）— 全新编写
- 三段证词设计：
  1. "我杀他对我没好处"（反向逻辑防线）
  2. "巧合不等于罪行"（关联性否认）
  3. "你没有直接证据"（最后硬扛）
- 每段3-4句证词
- 每句配完整 press / break_dialogue
- transition_dialogue 推进情绪
- victory_dialogue（最终认罪/爆发）
- 总计约400-500行

---

## Phase 4：立绘生成

### 4.1 沈清月基础立绘
- 使用 Gemini API 生成
- 风格参考：项目内现有半写实中国水墨风格
- 描述：22岁英气美人，穿男装劲服，长发束起，冷艳精致
- 纯色背景 #7B2D8B
- 输出：`prologue_shen_qingyue.png`

### 4.2 沈清月情绪差分
- `prologue_shen_qingyue_cold_smile.png` — 冷笑
- `prologue_shen_qingyue_cracking.png` — 裂缝
- `prologue_shen_qingyue_broken.png` — 崩溃
- `prologue_shen_qingyue_confrontation.png` — 对峙状态

### 4.3 已有角色无需修改
- 阿贵、老范、钱里正、王大爷、周氏 — 立绘不变
- 凌瑶 — 已有多个情绪差分，够用

---

## Phase 5：关联文件更新

### 5.1 `prologue.json`
- 凌瑶码头目击描述修改（加入沈清月的身影描述）
- 客栈暖场增加沈清月伏笔

### 5.2 `progression.json`
- 增加调查阶段B的进度触发条件
- 增加沈清月对峙的解锁条件

### 5.3 `locations.json`
- 可能新增：沈清月住处（客栈另一间房）
- 可能新增：下游打捞点

### 5.4 `search_results.json`
- 增加与沈清月相关的搜查点

### 5.5 `npc_states.json`
- 增加沈清月在各阶段的状态变化

---

## 执行顺序

```
Step 1: 写入沈清月角色卡到 character_profiles.md
Step 2: 更新 casting.json + npcs.json（数据文件）
Step 3: 更新 evidence.json（新证据）
Step 4: 编写 dialogues/shen_qingyue.json（全新对话树）
Step 5: 修改 case.json — 阿贵胜利后转折
Step 6: 编写 case.json — 沈清月对峙段（FINAL BOSS）
Step 7: 扩充各NPC对话（逆转规格）
Step 8: 生成沈清月立绘（Gemini API）
Step 9: 更新 prologue.json / progression.json 等关联文件
Step 10: 测试联调
```

---

## Gemini API 配置

- API Key: AIzaSyC0_sovY-q4Z6WjihkZM6xFWuScWfGgQo0
- 用途：角色立绘生成
- 新角色：text-to-image 生成
- 已有角色修改：image-to-image 方式保持一致性
- 参考风格：半写实中国水墨插画（与项目现有立绘风格统一）

---

*计划创建日期: 2026-05-24*
*预计总对白量: 1200-1500行（当前约200行，扩充6-7倍）*
