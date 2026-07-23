# 临川驿案 - Project Rules

## 三层架构开发规范（所有代码改动必须遵守）

> 完整技术细节见 `docs/ARCHITECTURE.md`。本节为强制性开发纪律，违反即返工。

### 分层职责（禁止越层）

```
Layer 1  流程骨架层（冻结）     scripts/core/flow/FlowRunner.gd   —— 只驱动大阶段流转
Layer 2  钩子骨架层（只追加）   scripts/core/hooks/HookBus.gd     —— 统一事件订阅中心
Layer 3  内容执行层（数据）     scripts/core/effects/EffectRegistry.gd + data/case_tables/
```

1. **FlowRunner** 禁止写入任何案件具体内容（flag/证据/台词/地点 ID），阶段定义只能来自 `flow` 数据。
2. **HookBus** 本体禁止修改；新机制 = 在常量清单追加钩子名 + `emit_hook`/`subscribe`。
3. **EffectRegistry** 是所有内容效果的唯一执行点；新效果类型用 `register_effect` 注册，禁止绕开它直接改 GameManager 状态。

### 硬性禁止

1. **禁止在 `.gd` 脚本里硬编码案件内容**：flag/证据/线索 ID、台词文本、地图坐标、BGM 映射、判决文案、立绘缩放参数、GM 预设 → 全部进 `data/case_tables/`（CSV 或 json_docs）。
2. **禁止新增第二套条件求值器**：唯一口径 `GameManager.evaluate_condition`；缺条件键就在其中加键。
3. **禁止在 mutator 里手动调用检查函数**（`_check_day_events`/`_check_progression`）：状态变更只发钩子，检查链由订阅触发（优先级 day_events=20 > progression=10 > FlowRunner=5）。
4. **禁止用 `ACTIVE_CASE == "xxx"` 做流程分支**：流程差异走数据配置；线性流程判断用 `FlowRunner.has_flow()`。
5. **禁止恢复时段消耗制**：时间 = 剧情日（`GameManager.get_story_day()`，由 time_progression.csv 的 flag 推导）；3 日 × 14 时段方案已废弃。
6. **禁止剧本/文案内容写进代码**：对峙后路由、缓冲台词、事件链、结局覆盖全部进 `flow` 数据的 `confrontation_routes`。

### 新机制接入流程（按类型对号入座）

| 要加什么 | 加在哪里 |
|---|---|
| 新效果（如"扣理智值"） | `EffectRegistry.register_effect("fx_name", handler)` |
| 新事件钩子（如"证据出示"） | `HookBus` 常量清单追加 + 产生处 `emit_hook` + 关心处 `subscribe` |
| 新案件大阶段流程 | 该案 json_docs 的 `flow` 文档（start/phases/confrontation_routes/resume_markers/forced_confrontation） |
| 新条件类型（如"理智低于"） | `GameManager.evaluate_condition` 加键 |
| 新内容数据（坐标/文案/配置） | 优先进 json_docs/CSV，代码只读数据（经 GameManager 持有的 *_data） |
| 新 autoload | project.godot 注册 + 提醒需重启编辑器（编辑器编译缓存不识别新标识符，headless 无此问题） |

### 验证要求

- 框架层改动后**必须跑 headless 行为测试**（临时场景 + `get_tree().quit(code)`，验证行为等价），不能只靠编辑器 validate_script。
- 临时测试脚本/场景/迁移脚本**用完即删**。
- 编辑器内 `execute_editor_script` 访问不到游戏 autoload 实例，验证一律用 headless 进程。

## Art Generation Rules (Image Assets)

### API & Tools
- Use **Gemini API** for image generation: `gemini-2.5-flash-image` (supports image-to-image with `responseModalities: ["IMAGE", "TEXT"]`)
- Fallback model: `gemini-2.0-flash` (text-only, no image gen), do NOT use `-exp` suffix models (deprecated)
- API Key: configured in environment or passed directly
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
- Note: `gemini-2.5-flash-image` may return 503 during high demand - implement retry with exponential backoff (15s, 30s, 45s)

### Character Consistency (CRITICAL)
- **All character illustrations MUST use image-to-image generation** to maintain consistency
- When generating a character portrait, ALWAYS provide the existing character portrait(s) as reference input
- Reference images location: `res://assets/cn/portraits/`
- The generated image must match the character's established appearance (face shape, hair style, clothing style)

### Background & Cutout Workflow
1. **Generate with solid color background** - use pure green (`#00FF00`) as default
2. **Choose background color that does NOT appear in the character** - e.g., if character wears green, use magenta (`#FF00FF`) instead
3. **Step 1 - Background removal**: Use `rembg` (AI-based) to remove background → transparent PNG
4. **Step 2 - Green despill (CRITICAL)**: Run aggressive green spill removal algorithm (see below)
5. **Step 3 - Verification**: Check `green_in_dark` pixel count < 100 before accepting

### Green Spill Removal - Known Issue & Solution

**Problem**: When using green screen backgrounds, `rembg` removes the bulk of the background but leaves green contamination in:
- Hair edges and thin strands (most visible on dark/black hair)
- Hairpin and small accessories near the edge
- Semi-transparent edge pixels where green bleeds through
- Dark areas where even a few green channel values are noticeable

**Why simple chroma-key fails**: The green isn't uniform - it mixes with anti-aliased edges, creating pixels that are part-green part-subject. `rembg` preserves these as semi-transparent but doesn't desaturate the green channel.

**Solution - 5-Pass Despill Algorithm** (must run AFTER rembg):
```python
# Pass 1: Remove very-green semi-transparent edge pixels (set alpha=0)
# Pass 2: In dark areas (hair, R<100, B<100), clamp G to max(R, B)
# Pass 3: In medium areas with green shift (G > R+15 and G > B+15), reduce G to avg(R,B)
# Pass 4: Hairpin area (upper 1/3 of image) - same clamp as Pass 2 with lower threshold
# Pass 5: Edge band detection (2px erosion) - clamp G on all edge pixels
```

**Acceptance criteria after despill**:
- `strong_green` (G > R+25 and G > B+25) pixels: **must be 0**
- `green_in_dark` (dark area green tint) pixels: **must be < 100** (ideally < 50)

**Alternative approach if green spill persists**: 
- Use magenta (`#FF00FF`) background instead - less spill on black hair
- But requires same despill logic targeting magenta channel instead

### Art Style Guidelines
- Style: Semi-realistic anime/illustration (半写实古风插画)
- Reference the "assistant" companion character style already in the project
- Characters wear period-appropriate Chinese traditional clothing (Ming Dynasty era)
- Half-body or upper-body composition for portraits
- Clean linework with soft shading
- Consistent lighting (soft front-lit, slight rim light)
- **CRITICAL: Scene backgrounds must NOT contain any Chinese text/characters** — AI-generated Chinese is always garbled. Prompt must explicitly say "NO TEXT, NO CHARACTERS, NO WRITING". Signs/lanterns should be blank or have only abstract weathering.

### File Naming Convention
- Main characters: `prologue_{character_name}.png`
- Character emotions: `prologue_{character_name}_{emotion}.png`
- Actors (generic NPCs): `actor_{role_name}.png`
- Companions: `companion_{name}_{emotion}.png`

### Image Specifications
- Portrait size: approximately 832x1248 (2:3 ratio)
- **Composition: 3/4 body portrait — from head to KNEES** (not just waist/half-body)
- Character should fill ~85% of canvas height (head near top, knees near bottom)
- Character is displayed bottom-aligned in game (lower body flush with screen bottom)
- Format: PNG with transparent background (after cutout)
- Keep arms/hands visible when possible for expressiveness

### Character Reference - 沈清月 (Shen Qingyue)
- **Face**: Based on reference photo - petite oval face, large round doe-like eyes, straight blunt bangs, delicate features, youthful (18-20)
- **Hair**: Black, long flowing with straight bangs; ponytail/half-updo with hairpin accessory
- **Clothing**: Purple-maroon/burgundy (紫红色/酒红色) traditional hanfu/Chinese robe with black collar/trim, brown leather belt, ornamental pouch (荷包)
- **Personality**: Cold, calculating, with hidden depth
- **Expressions needed**: neutral, cold_smile, cracking (showing vulnerability), broken (emotional collapse)
- **Reference files**: `prologue_shen_qingyue.png` (use as image-to-image reference for ALL emotion variants)

## Complete Image Generation Workflow (Step by Step)

```
1. Prepare references:
   - Face reference photo (if establishing new character)
   - Existing character portrait (for emotion variants / consistency)

2. Call Gemini API:
   - Model: gemini-2.5-flash-image
   - Input: reference image(s) + detailed prompt
   - responseModalities: ["IMAGE", "TEXT"]
   - Prompt must specify: SOLID PURE GREEN (#00FF00) background
   
3. Background removal:
   - Tool: rembg (Python: `from rembg import remove`)
   - Input: greenscreen PNG → Output: RGBA PNG
   
4. Green despill (MANDATORY):
   - Run 5-pass despill algorithm
   - Dependencies: PIL/Pillow, numpy, scipy.ndimage
   
5. Verification:
   - Analyze strong_green and green_in_dark pixel counts
   - Accept only if strong_green == 0 and green_in_dark < 100
   
6. Replace target file and keep greenscreen version for re-processing if needed
   - Greenscreen files: `{name}_greenscreen.png` (intermediate, can be deleted after verification)
   - Backup old versions: `_backup_{name}.png`
```

---

## 序章台词铁则（Agent对话必须遵守）

1. 朗读测试：出声念，不磕巴
2. 现场感测试：角色对眼前情境说话，非对观众解释
3. 反应先于判断：先有情绪再有理性
4. 一句一事：一句话只做一件事
5. 不写判词：台词是对话，非审判词/标语/谜语
6. 不写括号动作：严禁任何形式括号内容
7. 不写分析腔：用身体感受+具体瞬间，非总结判断
8. 凌瑶不做策略分析：只说身体感受/具体瞬间/困惑关心。**大侠风范+温柔可爱，不是碎嘴**：认真时语速变慢眼神定住，闲聊时有温度但不抢话，鼓励时"行。我信你。"不说"快快快""等什么呢"这类催促。追问时"那你觉得呢？"——真心好奇，不是逼问。
9. 每段有案外生活：至少30%非功利交流
10. 对峙中非功利≥30%：关心/情绪/生活细节/沉默陪伴
11. 历史考据（万历年间）：禁用"饼干""OK""搞定"等
12. **闲聊模式**：陆昭先说自己感受，再让NPC自然回应。不是审问，是同船乘客闲谈。
13. **4话题上限**：每个NPC恰好4条话题（hub入口不计入）。新增话题覆盖旧话题（保留node_id替换text）。Agent产出必须标注node_id。
14. **双向禁止复读**：任何人说完后，对方不得原样重复其关键词或句式。陆昭不复读NPC，NPC不复读陆昭，凌瑶不复读任何人。用自己的话接新内容。
15. **禁止文学化体感描写**：角色台词和内心独白中，不得出现小说式的身体感受/环境感知描写（如"背上一阵凉""油灯火苗被风扯得忽闪""空气里飘来××味"）。人不会在心里这样描述自己的感官体验。改用：直接的想法、判断、疑问。
16. **凌瑶语言规范**：大侠风范+温柔可爱，不使用夸张口头禅（"嘶——""哈？！"），改用更自然的方式表达警觉和关注。认真时语速放慢——"等一下。他刚才那句话不对。"鼓励时——"行。我信你。"保护时——"别慌，我在。"不抢话、不碎碎念。关键时刻当机立断，日常时自然有温度。
17. **陆昭人物核心**：为国家有抱负的热血青年，不是冷面书生。为了揭开黑暗主动投身险境的理想主义者，血液里烧着对公正的信念。表面沉稳但内心有火，尊敬自己的老师。审问时用完整句子，不冷冰冰地说单字命令；发现矛盾时像在"解开"谜题而非"攻击"对手；独处时有自我怀疑的脆弱面；偶尔会热血地说出"我不会让任何人白死。"
18. **证据获得禁止即时解说**：角色得到证据/线索时，只能有反应（"这边缘……""等等"），不得在同一段话里同时给出原因+推断+影响三层解释。逻辑推进留给玩家和下一次对话。
19. **到达地点禁止即时分析**：进入新地点的banter，前两句必须是非侦查性内容（身体状态/环境细节/案外话题），不得开门见山给出案情判断。
20. **NPC不配合原则**：嫌疑人被追问时，不得在第一轮就给出完整描述。应先答一个截断的版本，被追问后才补全关键细节，或用另一套说辞把话题绕开，让玩家判断哪句是漏嘴。
21. **凌瑶不做收尾人**：每段banter/discussion的最后一句，不得由凌瑶来总结、归纳或布置任务。她可以说一个不相关的事结尾（"走，我饿了。"），或沉默，或让陆昭说。
22. **大幅减少破折号**：对白中禁止用"——"连接两个分句（如"他说——然后""去了——回来"）。内心独白中最多每段1处。用句号断句，让停顿自然存在于句子之间。
