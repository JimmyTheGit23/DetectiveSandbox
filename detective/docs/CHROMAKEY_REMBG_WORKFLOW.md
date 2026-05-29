# 抠图与色键流水线 (ChromaKey & Rembg Workflow)

## 概述

本文档归档项目所有抠图（去背景）技术方案，涵盖三种背景类型的完整流水线、算法细节、踩坑经验与命令速查。

配套文档：`docs/CHARACTER_DESIGN_WORKFLOW.md`（角色生成流程）

---

## 一、流水线总览

| 背景类型 | 工具 | 适用场景 | 是否需要 despill |
|----------|------|----------|------------------|
| **纯绿底** `#00FF00` | `rembg` + `defringe_portrait.py --despill-green` | 立绘（Gemini img2img 生成，半身/全身） | **必须** |
| **纯紫底** `#FF00FF` | `remove_purple_bg.py`（纯色键，无 rembg） | 像素素材、UI 元素、图标 | 否 |
| **米色/复杂底** | `rembg_oldportraits.py`（U2Net + 归一化画布） | 老立绘批量翻新 | 视情况 |

---

## 二、绿底流水线（立绘主用）

### Pass 0：rembg 智能去背

```python
from rembg import remove, new_session
session = new_session("u2net")     # 人物专用模型
out = remove(src_img, session=session)
```

得到 RGBA，但**头发丝、抗锯齿边缘会残留绿色调**（G 通道偏高 5~30）。

### Pass 1~5：`despill_green_from_hair()` 五遍清扫

源码位置：`tools/defringe_portrait.py:140`。针对不同区域用不同阈值压低 G 通道：

#### Pass 1：半透明边像素

```python
semi = (a > 0) & (a < 200)
# 极绿(g>r+40且g>b+40) → 直接 alpha=0
# 轻绿(g>r+15) → G 改成 (R+B)/2
```

#### Pass 2：暗色头发区

```python
dark = visible & (a > 100) & (r < 100) & (b < 100)
# G 钳制到 max(R,B)
hair_green = dark & (g > np.maximum(r, b) + 3)
data[hair_green, 1] = np.maximum(r, b)[hair_green]
```

#### Pass 3：中间色调

```python
medium = visible & (a > 100) & ~dark
# G 偏移 → 降到 (R+B)/2
shifted = medium & (g > r + 15) & (g > b + 15)
data[shifted, 1] = (r + b)[shifted] / 2
```

#### Pass 4：上 1/3 区域（发簪/头饰）

```python
h = data.shape[0]
upper = np.zeros_like(visible); upper[:h//3] = True
pin = upper & visible & (a > 100) & (g > r + 8) & (g > b + 8)
# 更激进地压 G
data[pin, 1] = np.maximum(r, b)[pin]
```

#### Pass 5：alpha 二值化后侵蚀 2px，外圈 ring 强行 G=max(R,B)

```python
from scipy import ndimage
alpha_binary = (data[:,:,3] > 50).astype(np.uint8)
interior = ndimage.binary_erosion(alpha_binary, iterations=2)
edge_band = (alpha_binary > 0) & ~interior
edge_g = edge_band & (data[:,:,1] > data[:,:,0] + 5) & (data[:,:,1] > data[:,:,2] + 5)
data[edge_g, 1] = np.maximum(data[edge_g, 0], data[edge_g, 2])
```

### 验收（必过）

```python
strong_green = (visible & (g > r + 25) & (g > b + 25)).sum()    # 必须 == 0
green_in_dark = (visible & (r < 80) & (b < 80) & (g > r + 5) & (g > b + 5)).sum()  # 必须 < 100
assert strong_green == 0 and green_in_dark < 100
```

| 指标 | 阈值 | 说明 |
|------|------|------|
| `strong_green` | == 0 | G > R+25 且 G > B+25 的像素必须为零 |
| `green_in_dark` | < 100 | 暗色区域（头发）的绿色残留像素数 |

---

## 三、紫底流水线（像素素材主用）

源码：`tools/remove_purple_bg.py`。**不用 rembg，纯算法色键**，因为像素图边缘锐利、不需要 ML 模型。

### 策略 1：纯亮紫直接干掉

```python
dist = |R-255| + G + |B-255|
is_bright_purple = dist < 200  →  alpha=0
```

### 策略 2：紫偏分数

```python
# 紫偏分数 = (R+B)/2 - G > 8 → alpha=0
# 即使紫色被生成模型染浅了也能识别
```

### 策略 3：alpha 1 像素侵蚀 ★ 关键 ★

```python
# 只有自身+上下左右四邻域 alpha 都 > 100 才保留
# 这步直接切掉最外层一圈紫边
eroded = (alpha > 100) & (4邻域 > 100) ? alpha : 0
```

### 策略 4：半透明像素去紫

```python
# 有紫偏的像素 → R/B 通道往 RGB 均值靠拢
```

### 策略 5：alpha 高斯模糊

```python
# radius=0.5，消除阶梯锯齿
```

---

## 四、复杂底流水线（老立绘翻新）

源码：`tools/rembg_oldportraits.py`

```python
# Step 1: rembg u2net 去背
out = remove(src_img, session=new_session("u2net"))

# Step 2: autocrop 到非透明像素最小外接矩形 (padding=4)
nz = np.argwhere(alpha > 10)
y0, x0 = nz.min(0)
y1, x1 = nz.max(0)

# Step 3: 等比缩放后塞进 603×900 画布，居底对齐
canvas = Image.new("RGBA", (603, 900), (0, 0, 0, 0))
paste_y = 900 - nh   # 居底
```

好处：**规格统一**（与新批次同尺寸），可直接替换无需调对话框坐标。

---

## 五、生图一致性保证

### 5.1 双参考图 img2img

调用 `gemini-2.5-flash-image` 时，**强制把参考图作为 inline_data 喂给模型**，而不是只用文字 prompt：

- **IMAGE 1（face reference）**：人物面部参考图，prompt 明示「replicate these exact facial features」
- **IMAGE 2（style/clothing reference）**：项目已有的角色立绘，prompt 明示「match this art style」

```python
payload = {
    "contents": [{"parts": [
        {"text": prompt},
        {"inline_data": {"mime_type": "image/png", "data": face_ref_b64}},
        {"inline_data": {"mime_type": "image/png", "data": ref_b64}},
    ]}],
    "generationConfig": {"responseModalities": ["IMAGE", "TEXT"]}
}
```

### 5.2 情绪差分的一致性四条铁律

1. **用基础立绘作为唯一参考图**（不要换参考），保证脸型/服装/发型锁死
2. Prompt 写 **"SAME character"**，只描述**表情/姿势变化**
3. 每张走完整 rembg → despill → 验证流程，不跳步
4. 每张之间留 5 秒间隔避免 API 限流

### 5.3 背景策略（影响一致性视觉感）

| 项目位置 | 背景 | 用途 |
|----------|------|------|
| 立绘类（半身/全身） | 纯绿 `#00FF00` 或灰 `#808080` | rembg + despill |
| 像素素材 / UI | 纯紫 `#FF00FF` | 色键去除，零溢色 |

### 5.4 动画帧的帧间一致性

对于 `_idle_0` / `_idle_1` / `_talk_N` 需要逐帧切换的资产，采用 **Inpainting** 而非重新生成：

- idle_0 与 idle_1 只在**眼睛区域** mask 重绘（Denoising 0.25-0.35）
- talk 帧只在**嘴巴区域** mask 重绘
- 反例：`anim_test/xiao_cui_idle_0` 与 `idle_1` 因独立生成而有 50% 像素差异，导致眨眼时角色"整张脸跳动"

---

## 六、关键经验（踩过的坑）

1. **AI 生成的"纯色"不是真的纯**——背景会被烘焙进角色阴影/发丝（color spill），所以纯色键往往不够，必须配合 despill。
2. **alpha 1px 侵蚀比任何色键都有效**——最外圈像素 95% 是边缘色污染，直接切掉性价比最高（紫底脚本的策略 3、绿底脚本的 Pass 5 都是这个思路）。
3. **不要把灰化用在外描边**——`defringe_portrait.py:78` 注释明确说：「最外层色键污染不做灰化，直接透明，避免在深色背景上出现灰边」。
4. **`_backup_before_rembg/` 必须存**——抠图不可逆，原图丢了就没救。
5. **彩色背景的根本问题**：AI 图像生成会将背景色"烘焙"进角色的阴影/边缘区域。即使用 rembg 切除背景后，衣物褶皱和发丝中仍会残留背景色调。实测灰色背景 `#808080` 无可见溢色，是首选。

---

## 七、命令速查

```bash
# 立绘绿底（生成后必跑）
python tools/defringe_portrait.py input.png output.png --despill-green

# 像素图紫底
python tools/remove_purple_bg.py input.png

# 整个目录紫底批处理
python tools/remove_purple_bg.py assets/cn/sprites/

# 老立绘翻新
python tools/rembg_oldportraits.py            # 全量 8 张
python tools/rembg_oldportraits.py lu_zhao    # 单张
```

---

## 八、工具文件索引

| 文件 | 功能 |
|------|------|
| `tools/defringe_portrait.py` | 绿底 despill 五遍清扫 + 量化验收 |
| `tools/remove_purple_bg.py` | 紫底纯色键五策略去背 |
| `tools/rembg_oldportraits.py` | 复杂底 rembg + 归一化画布 |
| `tools/generate_confrontation_poses.py` | 对峙姿态批量生成脚本 |

---

*文档版本: v1.0*
*创建日期: 2026-05-28*
*适用项目: 临川驿案（DetectiveSandbox）*
