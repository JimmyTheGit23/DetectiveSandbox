# 抠图与色键流水线 (ChromaKey & Rembg Workflow)

## 概述

本文档归档项目所有抠图（去背景）技术方案，涵盖四种背景类型的完整流水线、算法细节、踩坑经验与命令速查。

配套文档：`docs/CHARACTER_DESIGN_WORKFLOW.md`（角色生成流程）、`.claude/skills/generate-portrait.md`（skill 定义）

---

## 一、流水线总览

| 背景类型 | 工具 | 适用场景 | 是否需要 despill |
|----------|------|----------|------------------|
| **纯紫底（立绘）** `#FF00FF` | `remove_purple_bg.py`（色键 + magenta-only despill） | **立绘主用**（companion/prologue/confrontation） | **必须**（magenta-only） |
| **纯紫底（像素素材）** `#FF00FF` | `remove_purple_bg.py`（纯色键，无 despill） | 像素素材、UI 元素、图标 | 否 |
| **纯绿底** `#00FF00` | `rembg` + `defringe_portrait.py --despill-green` | **已弃用**。绿底溢色对深色头发影响大，despill 容易误伤肤色/蓝色衣服 | **必须** |
| **米色/复杂底** | `rembg_oldportraits.py`（U2Net + 归一化画布） | 老立绘批量翻新 | 视情况 |

### 为什么紫底优于绿底

1. **绿底溢色在深色头发上极为明显**：头发 R<100 且 B<100 时，G 通道稍高（5~30）肉眼可见绿色调
2. **绿 despill 容易误伤正常颜色**：肤色 R>G>B 与绿溢色 G>R 都满足 G>R，难以区分
3. **紫底溢色可用 R≈B 且均>G 精确识别**：正常肤色 R>G>B（R>>B）、蓝色衣服 B>G>R（B>>R），都不满足 R≈B
4. **紫 despill 对正常颜色零影响**：`min(R,B) > G + 8 AND |R-B| < 50` 这个条件完美排除了暖色皮肤、蓝色衣服、棕色配饰

---

## 二、紫底立绘流水线（推荐主用）

源码：`tools/remove_purple_bg.py`。从 v2.0 开始，该工具整合了色键去除 + magenta-only despill + 小簇清除，一条龙完成。

### Step 1：角采样背景色

```python
# 从四边各取 5px 宽的边缘条带，取中位数 RGB 作为背景参考色
border = np.concatenate([data[:5,:,:3], data[-5:,:,:3], data[:,:5,:3], data[:,-5:,:3]], axis=0)
bg_color = np.median(border, axis=0)
```

### Step 2：从边缘 BFS 填充背景连通区

```python
# 计算每个像素到 bg_color 的欧氏距离
dist = np.linalg.norm(rgb - bg_color, axis=2)
# 候选：距离 < threshold 且颜色偏紫（R>G+20, B>G+20）
candidate = (dist < threshold) & (r > g + 20) & (b > g + 20)
# BFS 从画布四边开始，只扩展到候选像素
# 结果：连通到边缘的紫色区域 → alpha = 0
```

**关键**：flood fill 只标记与画布边缘连通的紫色区域，不会误删角色内部的紫色衣物（因为衣物不与边缘连通）。

### Step 3：小连通簇清除（<3000 px）

```python
# 对剩余 alpha>0 的像素做连通分量分析
# 删除面积 < 3000 的小簇（Gemini 水印、噪点）
# 保留 > 3000 的大簇（角色身体）
```

### Step 4：Magenta-Only Despill ★ 核心算法 ★

```python
fg = alpha > 0  # 前景像素
rb_min = np.minimum(r, b)
rb_diff = np.abs(r - b)

# 紫色溢色判定：R≈B 且均明显高于 G
is_magenta = fg & (rb_min > g + 8) & (rb_diff < 50)

# 溢色程度 0~1
spill_amt = np.clip((rb_min - g - 8) / 40.0, 0, 1)

# 修正：将 R/B 通道往 G 通道靠拢（只修被判定为紫溢的像素）
r_fix = np.where(is_magenta, r - (r - g) * spill_amt, r)
b_fix = np.where(is_magenta, b - (b - g) * spill_amt, b)
```

**为什么这个算法不会误伤正常颜色**：

| 颜色 | R,G,B 关系 | `min(R,B) > G+8` | `|R-B| < 50` | 判定 |
|------|-----------|-------------------|--------------|------|
| 暖色皮肤 | R>G>B, R≈200,G≈160,B≈130 | min=130, 130>168? ❌ | - | 不是紫溢 ✅ |
| 蓝色衣服 | B>G>R, B≈180,G≈100,R≈60 | min=60, 60>108? ❌ | - | 不是紫溢 ✅ |
| 棕色 | R>G>>B, R≈160,G≈110,B≈50 | min=50, 50>118? ❌ | - | 不是紫溢 ✅ |
| 紫色溢色 | R≈B>G, R≈180,G≈100,B≈170 | min=170, 170>108? ✅ | 10<50 ✅ | 是紫溢 → 修正 ✅ |
| 浅粉溢色 | R≈B>G, R≈200,G≈140,B≈190 | min=190, 190>148? ✅ | 10<50 ✅ | 是紫溢 → 修正 ✅ |

### Step 5：全透明像素 RGB 清零

```python
# 防止半透明混合时边缘渗色
data[alpha == 0, :3] = 0
```

### Step 6：Alpha 高斯模糊

```python
# radius=0.8，消除色键硬边产生的阶梯锯齿
alpha_blurred = GaussianBlur(alpha_channel, radius=0.8)
```

### Step 7：标准化画布

```python
# 伙伴角色：848×1264（LANCZOS，居底对齐）
# NPC/序章角色：603×900（LANCZOS，居底对齐）
scale = min(target_w / src_w, target_h / src_h)
resized = img.resize((new_w, new_h), LANCZOS)
canvas.paste(resized, (center_x, bottom_y), resized)
```

### 验收（必过）

```python
is_magenta_spill = visible & (np.minimum(r, b) > g + 8) & (np.abs(r - b) < 50)
magenta_spill = is_magenta_spill.sum()
pure_magenta = visible & (r > 230) & (g < 30) & (b > 230)
bg_residue = pure_magenta.sum()

assert magenta_spill == 0, f"紫溢残留: {magenta_spill}"
assert bg_residue == 0, f"背景残留: {bg_residue}"
```

---

## 三、绿底流水线（已弃用，保留参考）

> ⚠️ 绿底流水线已弃用。新立绘统一使用紫底流水线。
> 绿底的问题：rembg 切除背景后，发丝/衣褶残留 G 通道偏高（5~30），
> despill 难以区分"绿色溢色"和"正常暖色皮肤（G>R 不成立但 G 偏高）"，
> 导致过度 despill 把肤色变灰，或不足 despill 留绿色头发。

### Pass 0：rembg 智能去背

```python
from rembg import remove, new_session
session = new_session("u2net")     # 人物专用模型
out = remove(src_img, session=session)
```

### Pass 1~5：`despill_green_from_hair()` 五遍清扫

源码位置：`tools/defringe_portrait.py:140`。

1. 半透明边极绿像素 → alpha=0
2. 暗色头发区 G 钳制到 max(R,B)
3. 中间色调 G 降到 (R+B)/2
4. 上1/3 头饰区更激进压 G
5. alpha 侵蚀 2px 外圈 G=max(R,B)

### 验收

```python
strong_green = (visible & (g > r + 25) & (g > b + 25)).sum()    # 必须 == 0
green_in_dark = (visible & (r < 80) & (b < 80) & (g > r + 5) & (g > b + 5)).sum()  # 必须 < 100
```

---

## 四、紫底像素素材流水线（无 despill）

源码：`tools/remove_purple_bg.py`（`--no-despill` 模式）。

适用于：图标、UI 元素、像素素材（边缘锐利，不需要 ML 模型）。

### 策略 1：纯亮紫直接干掉

```python
dist = |R-255| + G + |B-255|
is_bright_purple = dist < 200  →  alpha=0
```

### 策略 2：紫偏分数

```python
# 紫偏分数 = (R+B)/2 - G > 8 → alpha=0
```

### 策略 3：alpha 1 像素侵蚀 ★ 关键 ★

```python
# 只有自身+上下左右四邻域 alpha 都 > 100 才保留
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

## 五、复杂底流水线（老立绘翻新）

源码：`tools/rembg_oldportraits.py`

```python
# Step 1: rembg u2net 去背
out = remove(src_img, session=new_session("u2net"))

# Step 2: autocrop 到非透明像素最小外接矩形 (padding=4)

# Step 3: 等比缩放后塞进 603×900 画布，居底对齐
```

---

## 六、生图一致性保证

### 6.1 双参考图 img2img

调用 `gemini-2.5-flash-image` 时，**强制把参考图作为 inline_data 喂给模型**：

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

### 6.2 情绪差分的一致性四条铁律

1. **用基础立绘作为唯一参考图**（不要换参考），保证脸型/服装/发型锁死
2. Prompt 写 **"SAME character"**，只描述**表情/姿势变化**
3. 每张走完整紫底色键 → magenta despill → 验证流程，不跳步
4. 每张之间留 5 秒间隔避免 API 限流

### 6.3 背景策略（v2.0 更新）

| 项目位置 | 背景 | 抠图方式 |
|----------|------|----------|
| 立绘类（半身/全身） | **纯紫 `#FF00FF`** | 色键 + magenta-only despill |
| 像素素材 / UI | 纯紫 `#FF00FF` | 纯色键，无 despill |
| ~~绿底~~ | ~~`#00FF00`~~ | ~~已弃用~~ |

### 6.4 动画帧的帧间一致性

对于 `_idle_0` / `_idle_1` / `_talk_N` 需要逐帧切换的资产，采用 **Inpainting** 而非重新生成：

- idle_0 与 idle_1 只在**眼睛区域** mask 重绘（Denoising 0.25-0.35）
- talk 帧只在**嘴巴区域** mask 重绘

---

## 七、关键经验（踩过的坑）

1. **AI 生成的"纯色"不是真的纯**——背景会被烘焙进角色阴影/发丝（color spill），所以纯色键往往不够，必须配合 despill。
2. **紫底优于绿底的核心原因**：紫色溢色可以用 `min(R,B) > G + 8 AND |R-B| < 50` 精确识别，不影响暖色皮肤/蓝色衣服/棕色配饰。绿色溢色无法用简单规则区分于正常暖色。
3. **alpha 1px 侵蚀比任何色键都有效**——最外圈像素 95% 是边缘色污染，直接切掉性价比最高。
4. **不要把灰化用在外描边**——最外层色键污染不做灰化，直接透明，避免在深色背景上出现灰边。
5. **`_backup_` 目录必须存**——抠图不可逆，原图丢了就没救。
6. **flood fill 防内洞误删**：只从画布边缘开始 BFS，角色内部的紫色区域（如紫衣）不会被误删。
7. **小簇清除阈值 3000px**：Gemini 水印通常 < 3000px，角色碎片 > 3000px，这个阈值在实践中效果良好。
8. **despill 强度系数 40**：`(min(R,B) - G - 8) / 40`，8 是起扣阈值（避免过度修正），40 是满修正距离。微调时改 40 可控制 despill 激进程度。

---

## 八、命令速查

```bash
# 立绘紫底（推荐，一条龙色键+despill+标准化）
python tools/remove_purple_bg.py input.png output.png --portrait

# 立绘紫底（仅色键+despill，不标准化画布）
python tools/remove_purple_bg.py input.png output.png

# 像素图紫底（仅色键，无 despill）
python tools/remove_purple_bg.py input.png output.png --no-despill

# 整个目录紫底批处理
python tools/remove_purple_bg.py assets/cn/sprites/

# 绿底 despill（已弃用，仅供历史参考）
python tools/defringe_portrait.py input.png output.png --despill-green

# 老立绘翻新（复杂底）
python tools/rembg_oldportraits.py            # 全量
python tools/rembg_oldportraits.py lu_zhao    # 单张
```

---

## 九、工具文件索引

| 文件 | 功能 |
|------|------|
| `tools/remove_purple_bg.py` | **紫底色键 + magenta-only despill + 小簇清除 + 画布标准化**（v2.0 推荐） |
| `tools/defringe_portrait.py` | 绿底 despill 五遍清扫 + 量化验收（已弃用） |
| `tools/rembg_oldportraits.py` | 复杂底 rembg + 归一化画布 |
| `tools/generate_confrontation_poses.py` | 对峙姿态批量生成脚本 |
| `tools/generate_portraits_gemini.py` | 演员立绘批量生成器（紫底色键） |
| `tools/process_ai_assets.py` | 紫底色键（简单版，用于像素素材） |

---

*文档版本: v2.0*
*更新日期: 2026-06-02*
*适用项目: 临川驿案（DetectiveSandbox）*
*变更：新增紫底立绘流水线（magenta-only despill），绿底降级为已弃用*
