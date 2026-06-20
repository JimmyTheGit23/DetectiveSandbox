#!/usr/bin/env python3
"""
分层立绘生成器 —— 紫色背景 + 抠图流程。

策略：
  1. 给 Gemini 原始立绘，要求生成纯紫色(#FF00FF)背景的分层部件：
     - body: 去眼去嘴的身体
     - eyes_closed: 只有闭眼
     - mouth_open: 只有张嘴
  2. 用 remove_purple_bg.py 抠图得到透明背景
  3. 引擎内叠加组装，天然对齐

所有输出都是 848×1264 全尺寸 PNG，像素坐标 1:1 对应。

用法：
  GEMINI_API_KEY=xxx python3 tools/gen_portrait_layers.py --char shen_qingyue
"""

from __future__ import annotations
import argparse, os, sys
from io import BytesIO
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
PORTRAITS = ROOT / "assets" / "cn" / "portraits"
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"

DEFAULT_BASE = {
    "shen_qingyue": PORTRAITS / "prologue_shen_qingyue.png",
}

# ── Prompt 设计：要求紫色纯色背景 ──────────────────────────────────
PROMPT_BODY = """Edit this character portrait illustration.

Create a new image with these EXACT requirements:
- The character's eyes and mouth must be COMPLETELY REMOVED — fill those areas with the surrounding skin color so it looks like a smooth face with no eyes and no mouth
- The background must be SOLID MAGENTA (#FF00FF) — pure bright purple, no gradients, no details
- Keep EVERYTHING else 100% identical: hair, eyebrows, nose, ears, clothing, accessories, hands, body, lighting, colors, pose, and framing
- The result should look like the character with their eyes and mouth seamlessly erased, placed on a solid magenta background
- Output the FULL image at the same size (848x1264)

This is for a layered animation system where eyes and mouth will be overlaid separately."""

PROMPT_EYES_CLOSED = """Edit this character portrait illustration.

Create a new image with these EXACT requirements:
- The character's eyes should be CLOSED (natural relaxed blink, gentle eyelids)
- The background must be SOLID MAGENTA (#FF00FF) — pure bright purple
- ONLY the closed eyes and their immediate surrounding area (eyelids, lashes, small skin area around eyes) should be visible
- The REST of the image (hair, face, body, clothing, etc.) must be COVERED by the solid magenta background
- The closed eyes must remain at EXACTLY the same pixel position as in the original
- Include natural upper eyelash lines matching the original art style
- The closed eyelids should be the character's skin tone

This is an overlay layer for a layered animation system. Only the eye region should show through.
Output the FULL image at the same size (848x1264)."""

PROMPT_MOUTH_OPEN = """Edit this character portrait illustration.

Create a new image with these EXACT requirements:
- The character's mouth should be OPEN as if speaking a syllable (natural, slightly open, relaxed)
- The background must be SOLID MAGENTA (#FF00FF) — pure bright purple
- ONLY the open mouth and its immediate surrounding area (lips, teeth hint, small skin area around mouth) should be visible
- The REST of the image (hair, face, body, clothing, etc.) must be COVERED by the solid magenta background
- The open mouth must remain at EXACTLY the same pixel position as in the original
- The mouth width should match the original closed mouth width
- Include lips with natural coloring and a hint of teeth/dark interior

This is an overlay layer for a layered animation system. Only the mouth region should show through.
Output the FULL image at the same size (848x1264)."""


def setup_client():
    if not API_KEY:
        raise RuntimeError("请设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
    from google import genai
    return genai.Client(api_key=API_KEY)


def _gen_image(client, src_path: Path, prompt: str, target_size: tuple) -> Image.Image | None:
    """调用 image-to-image 生成单张图。"""
    from google.genai import types
    with open(src_path, "rb") as f:
        img_part = types.Part.from_bytes(data=f.read(), mime_type="image/png")
    resp = client.models.generate_content(
        model=MODEL,
        contents=[img_part, prompt],
        config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
    )
    for part in resp.candidates[0].content.parts:
        if getattr(part, "inline_data", None) is not None:
            img = Image.open(BytesIO(part.inline_data.data)).convert("RGBA")
            if img.size != target_size:
                img = img.resize(target_size, Image.LANCZOS)
            return img
        if getattr(part, "text", None):
            print(f"  [text] {part.text[:200]}")
    return None


def remove_purple_for_layers(img: Image.Image, min_cluster_size: int = 100) -> Image.Image:
    """紫色背景抠图 —— 针对分层部件优化版。

    与 remove_purple_bg.py 的区别：
    - min_cluster_size 更小（部件图层内容可能很小，如嘴巴只有几百像素）
    - 保留所有 > min_cluster_size 的连通簇（不需要只保留最大簇）
    - 其余流程一致：flood fill → 全局色键 → 小簇清除 → despill → 画布保持原尺寸
    """
    from collections import deque
    from scipy import ndimage

    PURPLE_R, PURPLE_G, PURPLE_B = 255, 0, 255
    data = np.array(img, dtype=np.float32)
    rgb = data[:, :, :3].astype(np.uint8)

    # ── Step 1: 角采样背景色 ──
    h, w, _ = data.shape
    border_px = 5
    top = data[:border_px, :, :3].reshape(-1, 3)
    bottom = data[h - border_px:, :, :3].reshape(-1, 3)
    left = data[:, :border_px, :3].reshape(-1, 3)
    right = data[:, w - border_px:, :3].reshape(-1, 3)
    strips = np.concatenate([top, bottom, left, right], axis=0)
    bg = np.median(strips, axis=0).astype(np.float32)

    # ── Step 2: BFS flood fill 背景连通区 ──
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    dist = np.linalg.norm(rgb.astype(np.float32) - bg.astype(np.float32), axis=2)
    chroma_candidate = (r > g + 20) & (b > g + 20)
    candidate = (dist < 78.0) & chroma_candidate

    visited = np.zeros((h, w), dtype=bool)
    q = deque()
    def push(y, x):
        if 0 <= y < h and 0 <= x < w and candidate[y, x] and not visited[y, x]:
            visited[y, x] = True
            q.append((y, x))
    for x in range(w):
        push(0, x); push(h - 1, x)
    for y in range(h):
        push(y, 0); push(y, w - 1)
    while q:
        y, x = q.popleft()
        push(y - 1, x); push(y + 1, x); push(y, x - 1); push(y, x + 1)

    data[visited, 3] = 0

    # ── 全局色键 ──
    r2, g2, b2, a2 = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    global_purple = (a2 > 0) & (r2 > g2 + 18) & (b2 > g2 + 18) & (((r2 + b2) * 0.5) > g2 + 32)
    data[:, :, 3][global_purple] = 0

    # ── Step 3: 小簇清除（使用更小的阈值） ──
    alpha = data[:, :, 3].copy()
    binary = (alpha > 0).astype(np.int32)
    labeled, num_features = ndimage.label(binary)
    if num_features > 0:
        sizes = ndimage.sum(binary, labeled, range(1, num_features + 1))
        for i in range(1, num_features + 1):
            if sizes[i - 1] < min_cluster_size:
                alpha[labeled == i] = 0
    data[:, :, 3] = alpha

    # ── alpha 1px 侵蚀 ──
    alpha = data[:, :, 3]
    shifted_up = np.zeros_like(alpha)
    shifted_down = np.zeros_like(alpha)
    shifted_left = np.zeros_like(alpha)
    shifted_right = np.zeros_like(alpha)
    shifted_up[1:, :] = alpha[:-1, :]
    shifted_down[:-1, :] = alpha[1:, :]
    shifted_left[:, 1:] = alpha[:, :-1]
    shifted_right[:, :-1] = alpha[:, 1:]
    eroded = np.where(
        (alpha > 100) & (shifted_up > 100) & (shifted_down > 100) &
        (shifted_left > 100) & (shifted_right > 100), alpha, 0
    )
    data[:, :, 3] = eroded

    # ── Step 4: Magenta-only despill ──
    r3, g3, b3, a3 = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    fg = a3 > 0
    rb_min = np.minimum(r3, b3)
    rb_diff = np.abs(r3.astype(np.int16) - b3.astype(np.int16))
    is_magenta = fg & (rb_min > g3 + 8) & (rb_diff < 50)
    if np.any(is_magenta):
        spill_amt = np.clip((rb_min[is_magenta] - g3[is_magenta] - 8) / 40.0, 0, 1)
        data[is_magenta, 0] = r3[is_magenta] - (r3[is_magenta] - g3[is_magenta]) * spill_amt
        data[is_magenta, 2] = b3[is_magenta] - (b3[is_magenta] - g3[is_magenta]) * spill_amt

    # ── 半透明边像素去紫 ──
    semi = (data[:, :, 3] > 5) & (data[:, :, 3] < 245)
    if np.any(semi):
        r_s, g_s, b_s = data[semi, 0], data[semi, 1], data[semi, 2]
        bias_s = ((r_s + b_s) / 2.0) - g_s
        has_purple = bias_s > 5
        if np.any(has_purple):
            avg = (r_s[has_purple] + g_s[has_purple] + b_s[has_purple]) / 3.0
            strength = np.clip(bias_s[has_purple] / 40.0, 0.0, 0.8)
            idx = np.where(semi)
            py, px = idx[0][has_purple], idx[1][has_purple]
            data[py, px, 0] = avg + (data[py, px, 0] - avg) * (1.0 - strength)
            data[py, px, 2] = avg + (data[py, px, 2] - avg) * (1.0 - strength)

    # ── Step 5: 全透明像素 RGB 清零 ──
    data[data[:, :, 3] == 0, :3] = 0

    # ── Step 6: Alpha 高斯模糊 ──
    alpha_channel = np.clip(data[:, :, 3], 0, 255).astype(np.uint8)
    alpha_img = Image.fromarray(alpha_channel, mode='L')
    smoothed = alpha_img.filter(ImageFilter.GaussianBlur(radius=0.8))
    data[:, :, 3] = np.array(smoothed, dtype=np.float32)

    return Image.fromarray(np.clip(data, 0, 255).astype(np.uint8))


def _verify_layer(img: Image.Image, name: str) -> None:
    """验证图层质量。"""
    arr = np.array(img)
    total = arr.shape[0] * arr.shape[1]
    non_transparent = np.sum(arr[:, :, 3] > 10)
    pct = non_transparent / total * 100
    if non_transparent > 0:
        ys, xs = np.where(arr[:, :, 3] > 10)
        print(f"  {name}: {pct:.2f}% 非透明 ({non_transparent}px), "
              f"区域 x={xs.min()}~{xs.max()}, y={ys.min()}~{ys.max()}")
    else:
        print(f"  {name}: 完全透明 ⚠️")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--char", default="shen_qingyue")
    ap.add_argument("--base", default="")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--no-remove-bg", action="store_true", help="跳过抠图步骤（调试用）")
    args = ap.parse_args()

    base_path = Path(args.base) if args.base else DEFAULT_BASE.get(args.char)
    if base_path is None or not base_path.exists():
        print(f"找不到基准立绘：{base_path}")
        sys.exit(1)

    base = Image.open(base_path).convert("RGBA")
    size = base.size
    print(f"基准：{base_path.name}  尺寸 {size}")

    out_dir = PORTRAITS / "anim_layers" / args.char
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.dry_run:
        print("  [dry-run] 将生成 body/eyes_closed/mouth_open (紫底→抠图)")
        return

    client = setup_client()

    # ── 1. 生成 body 层（去眼去嘴，紫底） ──
    print("\n[1/3] 生成 body 层（去眼去嘴）...")
    body_raw = _gen_image(client, base_path, PROMPT_BODY, size)
    if body_raw:
        body_raw.save(out_dir / "body_raw.png")
        print(f"  ✓ 紫底原图保存 {out_dir / 'body_raw.png'}")

        if not args.no_remove_bg:
            print("  抠图中...")
            body_clean = remove_purple_for_layers(body_raw, min_cluster_size=500)
            _verify_layer(body_clean, "body")
            body_clean.save(out_dir / "body.png")
            print(f"  ✓ 保存 {out_dir / 'body.png'}")
    else:
        print("  ✗ 生成失败")
        sys.exit(1)

    # ── 2. 生成闭眼层（紫底，只有闭眼） ──
    print("\n[2/3] 生成闭眼层...")
    eyes_raw = _gen_image(client, base_path, PROMPT_EYES_CLOSED, size)
    if eyes_raw:
        eyes_raw.save(out_dir / "eyes_closed_raw.png")
        print(f"  ✓ 紫底原图保存 {out_dir / 'eyes_closed_raw.png'}")

        if not args.no_remove_bg:
            print("  抠图中...")
            eyes_clean = remove_purple_for_layers(eyes_raw, min_cluster_size=50)
            _verify_layer(eyes_clean, "eyes_closed")
            eyes_clean.save(out_dir / "eyes_closed.png")
            print(f"  ✓ 保存 {out_dir / 'eyes_closed.png'}")
    else:
        print("  ✗ 生成失败")

    # ── 3. 生成张嘴层（紫底，只有张嘴） ──
    print("\n[3/3] 生成张嘴层...")
    mouth_raw = _gen_image(client, base_path, PROMPT_MOUTH_OPEN, size)
    if mouth_raw:
        mouth_raw.save(out_dir / "mouth_open_raw.png")
        print(f"  ✓ 紫底原图保存 {out_dir / 'mouth_open_raw.png'}")

        if not args.no_remove_bg:
            print("  抠图中...")
            mouth_clean = remove_purple_for_layers(mouth_raw, min_cluster_size=50)
            _verify_layer(mouth_clean, "mouth_open")
            mouth_clean.save(out_dir / "mouth_open.png")
            print(f"  ✓ 保存 {out_dir / 'mouth_open.png'}")
    else:
        print("  ✗ 生成失败")

    # ── 叠加验证 ──
    print("\n=== 叠加验证 ===")
    body_path = out_dir / "body.png"
    eyes_path = out_dir / "eyes_closed.png"
    mouth_path = out_dir / "mouth_open.png"

    if body_path.exists() and eyes_path.exists():
        body_img = Image.open(body_path).convert("RGBA")
        eyes_img = Image.open(eyes_path).convert("RGBA")
        composite = np.array(body_img).copy()
        eyes_arr = np.array(eyes_img)
        mask = eyes_arr[:, :, 3] > 10
        composite[mask] = eyes_arr[mask]
        Image.fromarray(composite).save("/tmp/layer_test_eyes.png")
        print("  body+闭眼 叠加预览: /tmp/layer_test_eyes.png")

    if body_path.exists() and mouth_path.exists():
        body_img = Image.open(body_path).convert("RGBA")
        mouth_img = Image.open(mouth_path).convert("RGBA")
        composite2 = np.array(body_img).copy()
        mouth_arr = np.array(mouth_img)
        mask2 = mouth_arr[:, :, 3] > 10
        composite2[mask2] = mouth_arr[mask2]
        Image.fromarray(composite2).save("/tmp/layer_test_mouth.png")
        print("  body+张嘴 叠加预览: /tmp/layer_test_mouth.png")

    print("\n完成！重新打开项目让 Godot 导入新 png 即可。")


if __name__ == "__main__":
    main()
