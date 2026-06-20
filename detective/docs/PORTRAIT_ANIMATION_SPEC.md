# 立绘动态化技术方案与验证报告

> 创建：2026-06-20  
> 状态：**机制验证通过（headless 运行无错误）**，待接入正式美术帧。  
> 关联计划：`docs/PROLOGUE_REMAKE_PLAN.md` 第五节。

---

## 一、目标与原则

让静态立绘"活起来"（眨眼、说话口型、冲击动作），但**绝不用整图序列帧**（会导致美术量 = 情绪数 × 帧数，爆炸）。

**核心原则（逆转裁判同款）：**
> 身体 1 张静止大图（贵、不动）+ 眼睛 2~3 帧小贴图（便宜）+ 嘴巴 2~3 帧小贴图（便宜）+ 程序动画（抖动/位移，无需美术）。

---

## 二、引擎现状（验证前已存在）

`scripts/ui/DialogueBox.gd` **早已实现整图帧版动画链路**：
- `_idle_frames`：自动探测 `<base>_idle_0.png`/`_idle_1.png`（睁/闭眼），每 2~4 秒眨一次（闭眼 0.12s）。
- `_talk_frames`：自动探测 `<base>_talk_0.png`/`_talk_1.png`，说话时帧循环；无帧则 `_start_talk_bounce()` 微抖动兜底。
- 已接打字机：`_start_talk_animation()` / `_stop_talk_animation()`。

**问题**：这是**整图帧**方案（idle_0/1 是两张完整立绘），每个情绪都要额外整图 → 美术翻倍。且现有 `xiao_cui_idle_*` 在 `anim_test/` 子目录、尺寸 832×1248 与正式 603×900 不符，实际未在游戏中生效（当前无任何角色真的在眨眼）。

---

## 三、新方案：分层组件 `AnimatedPortrait`

新增 `scripts/ui/AnimatedPortrait.gd`，三层叠加：

| 层 | 内容 | 美术成本 |
|---|---|---|
| `_body` | 身体/姿势/情绪大图（= 现有 portrait_expressions 情绪图） | 复用现有，无新增 |
| `_eyes` | 眼部小贴图序列（半闭→全闭），睁眼=隐藏该层 | 巴掌大，多情绪可复用 |
| `_mouth` | 嘴部小贴图序列（半开→全开），闭嘴=隐藏该层 | 巴掌大，多情绪可复用 |

**接口：**
```gdscript
set_body(texture)                  # 身体大图
set_eye_frames([半闭, 全闭])        # 眨眼贴图（不含睁眼）
set_mouth_frames([半开, 全开])      # 口型贴图（不含闭嘴）
set_layer_rects(eye_rect, mouth_rect)  # 眼/嘴贴图在立绘上的像素位置
set_talking(bool)                  # 接打字机状态：说话=口型循环，停=闭嘴
```

**行为：**
- 眨眼：定时器随机 2.2~5.0s 触发，播 睁→半→闭→半→睁（每帧 0.06s），平时隐藏眼层。
- 口型：`set_talking(true)` 时嘴层按 0.09s 间隔循环开合；`false` 隐藏嘴层。
- **向后兼容**：眼/嘴帧为空 → 退化为纯静态身体大图。可逐角色渐进升级。

---

## 四、验证结果

- 验证场景：`scenes/ui/DynamicPortraitTest.tscn` + `scripts/ui/DynamicPortraitTest.gd`
- 用真实身体立绘（沈清月 `prologue_shen_qingyue.png`）+ **程序生成的占位眼/嘴贴图**（半透明椭圆块）验证机制，不依赖美术。
- 运行命令：
  ```
  Godot --headless --path . res://scenes/ui/DynamicPortraitTest.tscn --quit-after 120
  ```
- **结果：✅ 通过**。组件实例化、三层构建、身体图加载、定时器与眨眼/口型逻辑、占位贴图生成均无运行时错误，干净退出（仅有项目原有的无关字体 UID warning）。
- 交互验证（编辑器内 F6 运行）：空格 / 「说话」按钮切换说话状态观察口型；眨眼自动循环。

> 注：占位贴图是纯色椭圆块，仅验证"机制能跑通"。真实效果需替换为画好的眼/嘴小图。

---

## 五、接入正式美术的规范

### 5.1 美术交付物（每个主要角色）
```
prologue_<role>_<emotion>.png          # 身体+脸（睁眼、闭嘴）= 现有大图，不变
prologue_<role>_eyes.png （或按情绪分组）# 眼部小图：半闭、全闭 2 帧，透明背景，画在立绘对应像素位置
prologue_<role>_mouth.png               # 嘴部小图：半开、全开 2 帧，透明背景
```
- 眼/嘴贴图**在同角色多情绪间尽量复用**（普通系情绪共用一套，仅"崩溃/大哭"等极端情绪单独画）。实际增量远小于"情绪数 × 2"。
- 贴图建议为**与立绘等幅、透明定位**（即贴图就是 603×900 整幅，只在眼/嘴处有像素，其余透明）。这样无需 `set_layer_rects`，直接铺满即可，最省心。
- 次要路人（actor_*）可只做眨眼、甚至不做。

### 5.2 数据接入
建议 `portrait_expressions.csv` 扩两列（留空则静态，向后兼容）：
```
npc_id, base_portrait, emotion, portrait, eyes_sheet, mouth_sheet, writer_note
```

### 5.3 引擎接入
将 `DialogueBox` / `ConfrontationPanel` 中显示立绘的 `TextureRect` 替换/包裹为 `AnimatedPortrait`，
说话状态接现有 `_typewriter_playing` / `_start_talk_animation` 信号即可。冲击动作（拍桌/后仰）继续用现有 `_shake_tween` 程序动画。

---

## 六、进阶（后续可选，序章不做）
- **Live2D / Spine**：呼吸、头部微转、布料飘动，效果最好但需骨骼绑定，与现 AI 生成立绘工作流冲突，留给高规格角色（如沈清月终章）。
- **Skeleton2D 顶点形变**：轻微喘气晃动，介于贴图与 Live2D 之间，优先级低。

---

## 七、正式帧 AI 生成流程（已用沈清月验证）

脚本：`tools/gen_portrait_anim_frames.py`
```
GEMINI_API_KEY=xxx python3 tools/gen_portrait_anim_frames.py --char shen_qingyue
```
产出：`<base>_idle_0/_idle_1/_talk_0/_talk_1.png`（睁眼/闭眼/闭嘴/张嘴），与原图等尺寸对齐。

### ⚠️ 关键发现：整图 image-to-image 有「全局漂移」，必须局部合成
直接让 Gemini「基于原图只改眼睛」生成整图，结果**整张图被重绘**，与原图差异高达 **58%**（全局轻微位移/色调变化）。逐帧之间会抖动闪烁，**不可直接当动画帧**。

**解决流程（脚本已实现）：**
1. `_gen_raw`：image-to-image 生成「闭眼整图」「张嘴整图」。
2. `_locate_features`：用 `gemini-2.5-flash` 视觉定位眼/嘴像素框（返回 JSON `{eyes:[x,y,w,h], mouth:[x,y,w,h]}`）。
3. `_composite_region`：只把生成图的眼/嘴区域（圆角 + 高斯羽化边缘）合成回原图，其余像素 100% 用原图。

**验证结果（沈清月 848×1264）：** 合成后差异 idle_1=**0.48%**（y 270~372 眼部）、talk_1=**0.09%**（y 365~427 嘴部），全局漂移消除，背景透明保留。✅

> 经验：AI 适合「生成像素内容」，不适合「保证逐帧一致」。一致性靠程序合成保证。

### GM 测试集成
- GM 测试面板（`GmTestPanel`）右侧新增「动态立绘测试」入口 → 打开 `DynamicPortraitTest`。
- 测试场景加载上述真实帧，演示眨眼（每 2.5~5s）+ 说话口型（空格/按钮切换）。
- headless 运行验证：帧加载、眨眼/口型逻辑均无运行时错误。

---

## 八、相关文件清单
- `scripts/ui/AnimatedPortrait.gd` —— 分层动态立绘组件（新增，眼/嘴小贴图方案）
- `scripts/ui/DynamicPortraitTest.gd` —— 动态立绘测试场景脚本（接入真实生成帧）
- `scenes/ui/DynamicPortraitTest.tscn` —— 测试场景
- `scripts/ui/GmTestPanel.gd` —— GM 面板（已加「动态立绘测试」入口）
- `tools/gen_portrait_anim_frames.py` —— 正式帧生成脚本（生成+定位+局部合成，已验证）
- `scripts/ui/DialogueBox.gd` —— 现有整图帧动画链路（自动探测 _idle_*/_talk_*）
- `tools/gemini_anim_test.py` —— 早期探索脚本（整图方案，已被上面新脚本取代）
