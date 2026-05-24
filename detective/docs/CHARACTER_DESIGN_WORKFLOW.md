# 角色设计流程准则 (Character Design Workflow)

## 概述

本文档定义了项目中角色立绘的标准生成流程，确保角色视觉一致性、动画帧兼容性和后期抠图可行性。

---

## 一、核心原则

1. **每场景单角色**：每个生成画面中只能出现一名角色，避免多人构图干扰后期裁切。
2. **纯色背景**：使用纯色背景（推荐纯紫 `#7B2D8B` 或纯绿 `#00B140`），要求：
   - 背景色**不得出现在角色身上**（衣物、配饰、肤色都不含该色）
   - 便于后续自动抠图（chroma key / rembg）
3. **角色一致性**：所有角色生成必须使用 **image-to-image (img2img)** 方式，以项目内已有角色参考图为基准。
4. **标准姿态**：角色必须**站立、正面面对镜头**（或四分之三侧面），全身或半身均可。

---

## 二、文件命名规范

角色资产存放在 `res://assets/cn/portraits/` 目录下。

### 2.1 基础立绘

```
{case_prefix}_{character_id}.png          # 基础立绘（默认表情）
{case_prefix}_{character_id}_{emotion}.png # 情绪差分
```

**案件前缀示例**：
- `prologue_` — 序章沉船案
- `xunyang_` — 浔阳楼案

**情绪后缀**：
- `_shaken` — 动摇
- `_collapsed` — 崩溃
- `_confrontation` — 对峙状态
- `_nervous` — 紧张
- `_angry` — 愤怒
- `_sad` — 悲伤

### 2.2 动画帧（眨眼/说话）

```
{case_prefix}_{character_id}_idle_0.png   # 待机帧 0（睁眼，必须）
{case_prefix}_{character_id}_idle_1.png   # 待机帧 1（闭眼，必须）

{case_prefix}_{character_id}_talk_0.png   # 说话帧 0（嘴巴闭合）
{case_prefix}_{character_id}_talk_1.png   # 说话帧 1（嘴巴半开）
{case_prefix}_{character_id}_talk_2.png   # 说话帧 2（嘴巴张开）
```

> **关键约束**：idle_0 和 idle_1 之间**只有眼睛区域**有差异（闭眼/睁眼）。
> talk 帧之间**只有嘴巴区域**有差异。身体姿态、衣物、背景完全一致。

### 2.3 全身立绘（可选，用于特写/CG）

```
{case_prefix}_{character_id}_fullbody.png
```

---

## 三、生成流程（标准 SOP）

### Step 1: 确认角色参考图

从项目中找到该角色已有的基础立绘作为参考：

```
参考图位置: res://assets/cn/portraits/{case_prefix}_{character_id}.png
```

对于阿贵：`res://assets/cn/portraits/prologue_agui.png`

### Step 2: 生成基础全身立绘（纯色背景）

**Prompt 模板**：

```
[Character description matching reference image],
standing upright, facing the camera, full body portrait,
Chinese ancient Ming Dynasty period clothing,
solid [purple/green] background (#7B2D8B / #00B140),
single character only, no other people,
high quality illustration, consistent art style,
clean edges for easy background removal
```

**img2img 参数**：
- 参考图：使用项目内已有角色立绘
- Denoising strength: 0.35-0.55（保持角色特征一致性）
- 分辨率：1024x1536（竖版 2:3 比例）或 768x1024
- CFG Scale: 7-9

**阿贵示例 Prompt**：

```
A young Chinese male servant in Ming Dynasty clothing,
dark hair tied back, worried/humble expression,
wearing a grey-blue servant's robe with white cloth belt,
standing upright facing the camera, full body,
solid purple background (#7B2D8B),
single character only, high quality illustration,
semi-realistic Chinese ink painting style
```

### Step 3: 生成眨眼帧（idle_0 / idle_1）

**方法 A — Inpainting（推荐）**：
1. 使用 Step 2 生成的全身图作为基础
2. 用 inpaint mask 只覆盖眼睛区域
3. Prompt: `closed eyes, blinking, same character same pose same clothing`
4. Denoising: 0.25-0.35（仅改眼睛）

**方法 B — 手动编辑**：
1. 复制 idle_0
2. 在 Photoshop/Krita 中手绘闭眼状态
3. 确保除眼睛外所有像素完全一致

**输出**：
- `idle_0.png` = 基础立绘（睁眼）
- `idle_1.png` = 闭眼帧

### Step 4: 生成说话帧（talk_0 / talk_1 / talk_2）

**方法 — Inpainting**：
1. 使用基础立绘
2. Inpaint mask 只覆盖嘴巴区域
3. 分别生成：
   - talk_0: `mouth closed, neutral expression` (同 idle_0)
   - talk_1: `mouth slightly open, speaking`
   - talk_2: `mouth open, talking`
4. Denoising: 0.20-0.35

### Step 5: 抠图处理

1. 使用 `rembg` 或类似工具自动去除纯色背景
2. 验证边缘干净无残留
3. 输出为透明 PNG

```bash
# 使用 rembg 批量处理
rembg i input.png output.png
```

### Step 6: 裁切与对齐

确保所有帧（idle_0, idle_1, talk_0, talk_1, talk_2）：
- **画布尺寸完全一致**
- **角色位置完全对齐**（像素级）
- 推荐使用图层对齐工具验证

### Step 7: 导入 Godot 并验证

1. 将文件放入 `res://assets/cn/portraits/`
2. 命名符合规范（系统会自动识别 `_idle_0`, `_idle_1`, `_talk_N` 后缀）
3. 运行游戏测试眨眼和说话动画

---

## 四、系统集成说明

### 4.1 动画帧自动加载逻辑

`DialogueBox.gd` 中的 `_load_animation_frames()` 方法会自动：
- 查找 `{base_path}_talk_0.png` ~ `_talk_9.png` 作为说话帧
- 查找 `{base_path}_idle_0.png` ~ `_idle_9.png` 作为待机帧

### 4.2 眨眼系统

- 使用 `_idle_frames[0]`（睁眼）和 `_idle_frames[1]`（闭眼）
- 每 2.5-5.0 秒随机触发一次
- 闭眼持续 0.12 秒
- 说话时暂停眨眼

### 4.3 说话动画

- 有多帧时：每 0.12 秒切换一帧，循环播放
- 无多帧时：角色微幅上下抖动（bounce 2px）模拟说话

---

## 五、质量检查清单

- [ ] 角色面对镜头，站姿端正
- [ ] 背景为纯色（紫/绿），角色身上无该颜色
- [ ] img2img 参考了项目内已有角色（一致性）
- [ ] idle_0 与 idle_1 仅眼睛区域不同
- [ ] talk 帧仅嘴巴区域不同
- [ ] 所有帧画布尺寸一致、角色位置对齐
- [ ] 抠图后边缘干净，无色环残留
- [ ] 文件命名符合规范
- [ ] 在 Godot 中实际测试通过（眨眼流畅、说话切帧正常）

---

## 六、背景色选择参考

| 背景色 | Hex | 适用场景 |
|--------|-----|----------|
| **中性灰** | `#808080` | **推荐首选** — 不会产生色彩溢色，适合所有衣物颜色 |
| 紫色 | `#7B2D8B` | 仅限穿绿色/黄色衣物的角色（避免紫色溢入暖色衣物） |
| 绿色 | `#00B140` | 仅限穿红色/品红衣物的角色（避免绿色溢入发丝） |
| 蓝色 | `#0055AA` | 穿绿色衣物时备选 |

### ⚠️ 关键教训（2026-05 实测结论）

**彩色背景的根本问题**：AI 图像生成会将背景色"烘焙"进角色的阴影/边缘区域（color spill）。即使用 rembg 切除背景后，衣物褶皱和发丝中仍会残留背景色调。

**实测对比**：
- 紫色背景 + 暗红衣服 → 衣服阴影带紫色 ❌
- 绿色背景 + 暗红衣服 → 发丝边缘带绿色 ❌  
- **灰色背景 + 暗红衣服 → 无可见溢色** ✅

**最终结论**：除非角色主色调是灰色，否则**一律使用中性灰(#808080)背景**。

---

## 六B、Gemini API 生图 + rembg + despill 完整流程（2026-05-24 实测验证）

### 前置条件
- Gemini API Key（支持 `gemini-2.5-flash-image` 模型）
- Python 环境：`rembg`, `Pillow`, `numpy`, `scipy`
- 项目工具：`tools/defringe_portrait.py`（含 `despill_green_from_hair()` 函数）

### Step A: Image-to-Image 生成（角色一致性）

```python
import json, base64, urllib.request, time, sys

API_KEY = "YOUR_KEY"
MODEL = "gemini-2.5-flash-image"
URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={API_KEY}"

# 加载参考图（必须用项目内已有角色立绘确保一致性）
with open("assets/cn/portraits/prologue_shen_qingyue.png", "rb") as f:
    ref_b64 = base64.standard_b64encode(f.read()).decode()

# 如有面部参考照片也一并传入
with open("path/to/face_reference.png", "rb") as f:
    face_ref_b64 = base64.standard_b64encode(f.read()).decode()

prompt = """Generate a character portrait illustration based on these reference images.

IMAGE 1 is the FACE reference - replicate these exact facial features:
- [描述面部特征: 脸型、眼睛、发型等]

IMAGE 2 is the STYLE and CLOTHING reference - match this art style:
- Semi-realistic anime illustration, soft cel-shading
- [描述服装细节]

GENERATE:
- Half-body portrait, 3/4 angle
- [表情描述]
- Background: SOLID PURE GREEN (#00FF00) - completely flat uniform green, NO gradients, NO shadows
"""

payload = {
    "contents": [{"parts": [
        {"text": prompt},
        {"inline_data": {"mime_type": "image/png", "data": face_ref_b64}},
        {"inline_data": {"mime_type": "image/png", "data": ref_b64}},
    ]}],
    "generationConfig": {"responseModalities": ["IMAGE", "TEXT"]}
}

# 带重试（gemini-2.5-flash-image 高峰期会返回 503）
for attempt in range(4):
    try:
        data = json.dumps(payload).encode()
        req = urllib.request.Request(URL, data=data, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=180) as resp:
            result = json.loads(resp.read().decode())
        
        for part in result["candidates"][0]["content"]["parts"]:
            if "inlineData" in part:
                img_bytes = base64.standard_b64decode(part["inlineData"]["data"])
                with open("output_greenscreen.png", "wb") as f:
                    f.write(img_bytes)
                break
        break
    except urllib.error.HTTPError as e:
        if e.code == 503 and attempt < 3:
            time.sleep((attempt + 1) * 20)  # 20s, 40s, 60s
        else:
            raise
```

**API 注意事项**：
- 模型名：`gemini-2.5-flash-image`（不是 `-exp` 后缀，那个已废弃/404）
- `responseModalities` 必须为 `["IMAGE", "TEXT"]`（大写）
- 超时设 180s（图像生成较慢）
- 503 错误常见，必须实现重试

### Step B: rembg 去背景

```python
from rembg import remove
from PIL import Image

input_img = Image.open("output_greenscreen.png")
cutout = remove(input_img)
cutout.save("output_rembg.png", "PNG")
```

### Step C: 绿色去溢（despill） — 必须执行！

**这是最关键的步骤。** rembg 会在以下区域残留绿色：
- 黑色头发丝（G通道比R/B高出5-30）
- 发簪/配饰边缘
- 半透明抗锯齿边缘像素

```python
# 方法1: 使用项目工具
sys.path.insert(0, 'tools')
from defringe_portrait import despill_green_from_hair
despill_green_from_hair("output_rembg.png", "output_final.png")

# 方法2: 内联5-Pass算法
import numpy as np
from PIL import Image
from scipy import ndimage

img = Image.open("output_rembg.png").convert("RGBA")
data = np.array(img, dtype=np.float64)
r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
visible = a > 0

# Pass 1: 极绿半透明边缘 → 全透明
semi = (a > 0) & (a < 200)
data[(semi & (g > r + 40) & (g > b + 40)), 3] = 0
# 轻度绿边 → 降低绿通道
mild = semi & (g > r + 15) & (g > b + 15)
data[mild, 1] = (data[mild, 0] + data[mild, 2]) / 2

# Pass 2: 暗色区域（头发） → 钳制 G 到 max(R,B)
dark = visible & (a > 100) & (r < 100) & (b < 100)
hair_green = dark & (g > np.maximum(r, b) + 3)
data[hair_green, 1] = np.maximum(r, b)[hair_green]

# Pass 3: 中间色调绿偏移 → 降低到 avg(R,B)
medium = visible & (a > 100) & ~dark
shifted = medium & (g > r + 15) & (g > b + 15)
data[shifted, 1] = (r + b)[shifted] / 2

# Pass 4: 发簪区域（上1/3）更积极处理
h = data.shape[0]
upper = np.zeros_like(visible); upper[:h//3] = True
pin = upper & visible & (a > 100) & (g > r + 8) & (g > b + 8)
data[pin, 1] = np.maximum(r, b)[pin]

# Pass 5: 边缘带检测（2px侵蚀）
alpha_bin = (data[:,:,3] > 50).astype(np.uint8)
interior = ndimage.binary_erosion(alpha_bin, iterations=2)
edge = (alpha_bin > 0) & ~interior
edge_g = edge & (data[:,:,1] > data[:,:,0] + 5) & (data[:,:,1] > data[:,:,2] + 5)
data[edge_g, 1] = np.maximum(data[edge_g, 0], data[edge_g, 2])

Image.fromarray(np.clip(data, 0, 255).astype(np.uint8)).save("output_final.png")
```

### Step D: 质量验证（必须通过才能使用）

```python
data = np.array(Image.open("output_final.png").convert("RGBA"))
r, g, b, a = data[:,:,0].astype(int), data[:,:,1].astype(int), data[:,:,2].astype(int), data[:,:,3]
visible = a > 10

strong_green = visible & (g > r + 25) & (g > b + 25)
dark_area = visible & (r < 80) & (b < 80)
green_in_dark = dark_area & (g > r + 5) & (g > b + 5)

assert strong_green.sum() == 0, f"FAIL: {strong_green.sum()} strong green pixels"
assert green_in_dark.sum() < 100, f"FAIL: {green_in_dark.sum()} green-in-dark pixels"
print("PASS ✅")
```

**验收标准**：
| 指标 | 阈值 | 说明 |
|------|------|------|
| `strong_green` | == 0 | G > R+25 且 G > B+25 的像素必须为零 |
| `green_in_dark` | < 100 | 暗色区域（头发）的绿色残留像素数 |

### 情绪差分生成注意事项

1. **用基础立绘作为唯一参考图**，确保所有差分的脸型/服装/发型完全一致
2. **Prompt 中明确写 "SAME character" + 只描述表情/姿势变化**
3. **每张都走完整 Step B→C→D 流程**（不能跳过 despill！）
4. **差分之间留 5 秒间隔**避免 API 限流
5. **保留 greenscreen 中间文件**（`_greenscreen.png`），方便重新处理

### 灰色背景替代方案

如果绿色溢出问题难以处理（如角色有大量细散发丝），可改用灰色背景：
- Prompt 中写 `SOLID NEUTRAL GRAY (#808080) background`
- 灰色背景不会产生色相污染，只有明度影响
- rembg 对灰色背景的去除效果同样好
- **无需 Step C 的 despill 步骤**（这是灰色背景的最大优势）

---

## 七、测试案例：阿贵（序章沉船案）

### 现有资产
- `prologue_agui.png` — 半身立绘（864×1184px, RGBA 透明背景, 59% 透明区域）
- `prologue_agui_shaken.png` — 动摇
- `prologue_agui_collapsed.png` — 崩溃
- `prologue_agui_confrontation.png` — 对峙
- `prologue_agui_confrontation_shaken.png` — 对峙·动摇
- `prologue_agui_confrontation_collapsed.png` — 对峙·崩溃

### 待生成资产
- `prologue_agui_idle_0.png` — 站立正面·睁眼（与基础立绘一致）
- `prologue_agui_idle_1.png` — 站立正面·闭眼（仅眼睛区域不同）
- `prologue_agui_talk_0.png` — 嘴巴闭合（同 idle_0）
- `prologue_agui_talk_1.png` — 嘴巴半开（仅嘴巴区域不同）
- `prologue_agui_talk_2.png` — 嘴巴张开（仅嘴巴区域不同）
- `prologue_agui_fullbody.png` — 全身立绘（可选）

### 技术规格
- **目标尺寸**：864×1184px（与现有立绘一致）或 1024×1536px（高清版）
- **格式**：PNG, RGBA（透明背景）
- **画风**：半写实中国水墨插画风格

### 生成参考

基于 `prologue_agui.png` 的角色特征：
- 中年男性仆人，面容忧虑
- 灰蓝色仆人袍，有补丁/缝补痕迹（显示低微身份）
- 白色/米色布腰带，打结样式
- 黑发束起（小发髻）
- 美术风格：半写实中国水墨插画

使用 img2img 方式，以 `prologue_agui.png` 作为参考，生成全身站立正面版本，背景用纯紫色 `#7B2D8B`（角色身上无紫色）。

### ⚠️ 已知问题（anim_test 前车之鉴）

`assets/cn/portraits/anim_test/xiao_cui_idle_0.png` 与 `xiao_cui_idle_1.png` 存在约 **50% 像素差异**（整张图都不同），这是因为两帧是独立生成的而非 inpainting。正确做法是 inpaint 仅修改眼睛区域，确保帧间差异 < 1%。

---

## 八、工具链推荐

| 步骤 | 推荐工具 |
|------|----------|
| img2img 生成 | Stable Diffusion (ComfyUI / A1111) / Midjourney |
| Inpainting | ComfyUI Inpaint / A1111 Inpaint |
| 背景移除 | rembg (Python) / remove.bg |
| 帧对齐验证 | Krita / Photoshop 图层叠加 |
| 批量处理 | Python + Pillow 脚本 |

---

---

## 九、代码集成验证

### 9.1 快速验证脚本

在 Godot 中运行以下编辑器脚本验证资产是否被正确识别：

```gdscript
# 在编辑器脚本中执行
var base := "res://assets/cn/portraits/prologue_agui.png"
var idle_base := base.replace(".png", "_idle_%d.png")
var talk_base := base.replace(".png", "_talk_%d.png")

print("=== 阿贵动画帧检测 ===")
for i in range(10):
    var p := idle_base % i
    if ResourceLoader.exists(p):
        print("✅ idle_%d: %s" % [i, p])
    else:
        if i == 0:
            print("❌ idle_0 缺失（眨眼功能不可用）")
        break

for i in range(10):
    var p := talk_base % i
    if ResourceLoader.exists(p):
        print("✅ talk_%d: %s" % [i, p])
    else:
        if i == 0:
            print("ℹ️ 无 talk 帧（将使用微抖动代替）")
        break
```

### 9.2 关键代码文件

| 文件 | 作用 |
|------|------|
| `scripts/ui/DialogueBox.gd` | 动画帧加载、眨眼循环、说话帧切换 |
| `scripts/core/AssetResolver.gd` | 角色立绘路径解析（casting → actor → portrait） |
| `scripts/dialogue/DialogueManager.gd` | 对话触发时传递 portrait 路径 |
| `assets/cn/portrait_fade.gdshader` | 立绘边缘渐隐 shader |

### 9.3 无需修改代码

现有 `DialogueBox.gd` 已经支持动画帧自动发现，只需要按命名规范放置图片文件即可自动生效。无需修改任何代码。

---

*文档版本: v1.0*
*创建日期: 2026-05-23*
*适用项目: 临川驿案（DetectiveSandbox）*
