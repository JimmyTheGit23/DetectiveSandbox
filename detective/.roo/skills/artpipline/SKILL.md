name: artpipline
description: 生成项目中的美术资产时
---

# Artpipline

## Instructions

### Gemini API 配置

生成美术资产时使用 Gemini API 进行图像生成。

**API Key**: 通过环境变量 `GEMINI_API_KEY` 或脚本 `--api-key` 参数传入。

**调用方式**:
- 脚本: `tools/generate_companion_assets.py`（直接调用 Gemini API，无需额外依赖）
- 模型: `gemini-2.5-flash-image`（主）/ `imagen-4.0-generate-001`（备选）
- 端点: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`

**立绘标准规格**:
- 尺寸: 603×900 RGBA
- 背景: 纯绿色 #00FF00 或纯紫色 #FF00FF（色键去背）
- 后处理: `tools/process_ai_assets.py`（remove_magenta / autocrop）

**工作流**:
1. 使用 Gemini API 生成紫底/绿底草图
2. 落地到 `assets/ai_raw/portraits/`
3. 色键去背 + autocrop + resize 到 603×900
4. 输出到 `assets/cn/portraits/`

### 风格基底

所有角色立绘共享以下风格描述（与凌瑶一致的半写实二次元古风）:

```
Ancient Chinese Ming Dynasty Jiangnan character portrait, semi-realistic anime illustration
fused with traditional ink-wash brushwork. Clean line art with soft cel-shading,
vibrant but muted color palette. Half-body waist-up shot, three-quarter angle,
subject facing slightly toward camera-left, eye-level framing.
IMPORTANT: solid pure magenta background #FF00FF, completely flat, no gradient.
Sharp clean silhouette edges. No text, no watermark, no UI.
Lighting: soft warm key light from upper-right, gentle ambient fill.
Style: anime-influenced Chinese guqin-era detective game character portraits.