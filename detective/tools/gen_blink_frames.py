#!/usr/bin/env python3
"""
眨眼动画帧生成器 —— 紫色背景 + 抠图 + diff overlay 多帧流程。

解决：
  - Gemini 闭眼时眉毛变形 → 用严格 prompt 约束只修改眼睛区域
  - 只有1帧闭眼 → 生成半闭眼(过渡) + 全闭眼两帧
  - 边缘穿帮 → diff overlay + alpha 渐变

输出：
  eyes_half.png    — 半闭眼 overlay（眨眼中途）
  eyes_closed.png  — 全闭眼 overlay（完全闭合）

用法：
  GEMINI_API_KEY=xxx python3 tools/gen_blink_frames.py --char shen_qingyue
"""

from __future__ import annotations
import argparse, os, sys, json
from io import BytesIO
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
PORTRAITS = ROOT / "assets" / "cn" / "portraits"
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"

DEFAULT_BASE = {
    "shen_qingyue": PORTRAITS / "prologue_shen_qingyue.png",
}

# ── Prompt: 强调只改眼睛、绝对不动眉毛 ────────────────────────────
PROMPT_HALF_CLOSED = """This is a character portrait with a SOLID MAGENTA (#FF00FF) background.

Edit ONLY the eye area — make the eyes HALF-CLOSED (about 60% closed, relaxed mid-blink state).

CRITICAL RULES:
1. DO NOT change, move, or redraw the EYEBROWS in any way — they must stay EXACTLY identical to the original pixel position and shape
2. DO NOT change the forehead area above the eyebrows
3. DO NOT change the nose, mouth, cheeks, or any other facial feature
4. ONLY modify the eyelids: upper lid comes down partially, lower lid stays still
5. The upper eyelid should naturally cover about half of the iris/pupil area
6. Keep the exact same skin tone on the closed portion of the eyelid as surrounding face skin
7. Keep the SOLID MAGENTA (#FF00FF) background EXACTLY unchanged
8. Keep EVERYTHING else 100% identical: hair, ears, clothing, accessories, pose, lighting

Output at the same size (848x1264). This is frame 1 of a 2-frame blink animation."""

PROMPT_FULL_CLOSED = """This is a character portrait with a SOLID MAGENTA (#FF00FF) background.

Edit ONLY the eye area — make the eyes FULLY CLOSED (natural relaxed blink, gentle closed eyelids).

CRITICAL RULES:
1. DO NOT change, move, or redraw the EYEBROWS in any way — they must stay EXACTLY identical to the original pixel position and shape
2. DO NOT change the forehead area above the eyebrows
3. DO NOT change the nose, mouth, cheeks, or any other facial feature
4. ONLY modify the eyelids: both upper and lower lids meet gently
5. The closed eyelids show natural gentle curve with subtle lash line hint
6. Use the character's natural skin tone for the eyelids (not lighter or darker)
7. Keep the SOLID MAGENTA (#FF00FF) background EXACTLY unchanged
8. Keep EVERYTHING else 100% identical: hair, ears, clothing, accessories, pose, lighting

Output at the same size (848x1264). This is frame 2 of a 2-frame blink animation (fully closed)."""

# 眼部 ROI（只在这个区域内提取差异，避免其他区域干扰）
# ⚠️ 重要：y起点必须避开眉毛！眉毛在 y≈250~272，眼睛在 y≈283~300。
# ROI 的 y 起点设在 280 以避开眉毛+眉眼间隔，否则眨眼时眉毛会跟着变形/上下动。
EYE_ROI = (320, 280, 300, 45)  # x, y, w, h — 仅覆盖眼睛带，不含眉毛
# 硬切线：生成 overlay 后，y < HARD_CUT_TOP 的像素全部强制 alpha=0，
# 物理保证眉毛区零像素（即使羽化扩散也不会碰到眉毛）。
HARD_CUT_TOP = 280


def setup_client():
    if not API_KEY:
        raise RuntimeError("请设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
    from google import genai
    return genai.Client(api_key=API_KEY)


def _gen_image(client, src_path: Path, prompt: str, target_size: tuple) -> Image.Image | None:
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
                img = img.resize(target_size, Image.Resampling.LANCZOS)
            return img
        if getattr(part, "text", None):
            print(f"  [text] {part.text[:200]}")
    return None


def make_purple_bg(src_path: Path, out_path: Path) -> Path:
    """将透明背景立绘转为紫底版本。"""
    img = Image.open(src_path).convert("RGBA")
    arr = np.array(img)
    mask_transparent = arr[:, :, 3] == 0
    arr[mask_transparent, 0] = 255
    arr[mask_transparent, 1] = 0
    arr[mask_transparent, 2] = 255
    arr[mask_transparent, 3] = 255
    result = Image.fromarray(arr)
    result.save(out_path)
    return out_path


def remove_purple_bg(img: Image.Image, min_cluster_size: int = 100) -> Image.Image:
    """调用项目现有的 remove_purple_bg.py 逻辑的内联版。"""
    from collections import deque
    try:
        from scipy import ndimage
    except ImportError:
        print("  ⚠️ scipy 未安装，使用简化版抠图")
        return _simple_remove_purple(img)

    PURPLE_R, PURPLE_G, PURPLE_B = 255, 0, 255
    data = np.array(img, dtype=np.float32)
    rgb = data[:, :, :3].astype(np.uint8)
    h, w, _ = data.shape
    border_px = 5
    top = data[:border_px, :, :3].reshape(-1, 3)
    bottom = data[h - border_px:, :, :3].reshape(-1, 3)
    left = data[:, :border_px, :3].reshape(-1, 3)
    right = data[:, w - border_px:, :3].reshape(-1, 3)
    strips = np.concatenate([top, bottom, left, right], axis=0)
    bg = np.median(strips, axis=0).astype(np.float32)

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

    r2, g2, b2, a2 = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    global_purple = (a2 > 0) & (r2 > g2 + 18) & (b2 > g2 + 18) & (((r2 + b2) * 0.5) > g2 + 32)
    data[:, :, 3][global_purple] = 0

    alpha = data[:, :, 3].copy()
    binary = (alpha > 0).astype(np.int32)
    labeled, num_features = ndimage.label(binary)
    if num_features > 0:
        sizes = ndimage.sum(binary, labeled, range(1, num_features + 1))
        for i in range(1, num_features + 1):
            if sizes[i - 1] < min_cluster_size:
                alpha[labeled == i] = 0
    data[:, :, 3] = alpha

    # despill
    r3, g3, b3, a3 = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    fg = a3 > 0
    rb_min = np.minimum(r3, b3)
    rb_diff = np.abs(r3.astype(np.int16) - b3.astype(np.int16))
    is_magenta = fg & (rb_min > g3 + 8) & (rb_diff < 50)
    if np.any(is_magenta):
        spill_amt = np.clip((rb_min[is_magenta] - g3[is_magenta] - 8) / 40.0, 0, 1)
        data[is_magenta, 0] = r3[is_magenta] - (r3[is_magenta] - g3[is_magenta]) * spill_amt
        data[is_magenta, 2] = b3[is_magenta] - (b3[is_magenta] - g3[is_magenta]) * spill_amt

    data[data[:, :, 3] == 0, :3] = 0
    return Image.fromarray(np.clip(data, 0, 255).astype(np.uint8))


def _simple_remove_purple(img: Image.Image) -> Image.Image:
    """简化版抠图（无 scipy 时的 fallback）。"""
    arr = np.array(img.convert("RGBA"), dtype=np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    purple_mask = (r > 200) & (g < 60) & (b > 200)
    arr[purple_mask, 3] = 0
    arr[arr[:, :, 3] == 0, :3] = 0
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))


def generate_diff_overlay(
    base: Image.Image,
    variant: Image.Image,
    output_path: Path,
    threshold: float = 18.0,
    feather_radius: float = 3.5,
    min_alpha: int = 15,
    roi: tuple[int, int, int, int] | None = None,
) -> dict[str, Any]:
    """基于两张图的像素差异生成 overlay PNG。"""
    W, H = base.size
    arr_b = np.array(base, dtype=np.float32)
    arr_v = np.array(variant, dtype=np.float32)

    rgb_diff = np.linalg.norm(arr_b[:, :, :3] - arr_v[:, :, :3], axis=2)
    var_alpha = arr_v[:, :, 3]
    changed_mask = (rgb_diff > threshold) & (var_alpha > 30)

    if roi is not None:
        rx, ry, rw, rh = roi
        roi_mask = np.zeros((H, W), dtype=bool)
        roi_mask[ry:ry + rh, rx:rx + rw] = True
        changed_mask = changed_mask & roi_mask

    mask_uint8 = (changed_mask.astype(np.uint8)) * 255
    mask_img = Image.fromarray(mask_uint8, mode="L")
    blurred = mask_img.filter(ImageFilter.GaussianBlur(radius=feather_radius))
    alpha_arr = np.array(blurred, dtype=np.float32)
    alpha_arr[alpha_arr < min_alpha] = 0

    # ★ 硬切：y < HARD_CUT_TOP 的像素全部强制透明，物理保证眉毛区零像素
    alpha_arr[:HARD_CUT_TOP, :] = 0

    output = arr_v.copy()
    output[:, :, 3] = alpha_arr

    total_px = W * H
    nonzero = np.sum(alpha_arr > min_alpha)
    pct = nonzero / total_px * 100
    if nonzero > 0:
        ys, xs = np.where(alpha_arr > min_alpha)
        bbox_w = xs.max() - xs.min()
        bbox_h = ys.max() - ys.min()
    else:
        bbox_w = bbox_h = 0

    result = Image.fromarray(np.clip(output, 0, 255).astype(np.uint8))
    result.save(output_path, optimize=True)
    file_kb = output_path.stat().st_size / 1024

    return {"nonzero_pixels": int(nonzero), "pct_nonzero": round(pct, 2),
            "bbox_size": (int(bbox_w), int(bbox_h)), "file_kb": round(file_kb, 1)}


def main() -> None:
    ap = argparse.ArgumentParser(description="眨眼动画帧生成器")
    ap.add_argument("--char", default="shen_qingyue")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    base_path = DEFAULT_BASE.get(args.char)
    if base_path is None or not base_path.exists():
        print(f"找不到基准立绘: {base_path}")
        sys.exit(1)

    base = Image.open(base_path).convert("RGBA")
    size = base.size
    print(f"基准: {base_path.name}  尺寸 {size}")

    out_dir = PORTRAITS / "anim_layers" / args.char
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.dry_run:
        print("[dry-run] 将生成:")
        print(f"  eyes_half.png   (半闭眼 overlay)")
        print(f"  eyes_closed.png (全闭眼 overlay)")
        return

    # ── 准备紫底原图 ──
    purple_path = out_dir / "purple_bg_base.png"
    if not purple_path.exists():
        print("\n准备紫底原图...")
        make_purple_bg(base_path, purple_path)
        print(f"  ✓ {purple_path.name}")

    client = setup_client()

    frames = [
        ("half", PROMPT_HALF_CLOSED, "eyes_half.png"),
        ("closed", PROMPT_FULL_CLOSED, "eyes_closed.png"),
    ]

    for label, prompt, out_name in frames:
        print(f"\n{'='*50}")
        print(f"[{label}] 生成{'半' if label=='half' else '全'}闭眼帧...")

        # 1. Gemini 生成紫底闭眼整图
        raw_img = _gen_image(client, purple_path, prompt, size)
        if raw_img is None:
            print(f"  ✗ {label} 生成失败，跳过")
            continue

        raw_path = out_dir / f"blink_{label}_raw.png"
        raw_img.save(raw_path)

        # 检查紫底保留率
        arr = np.array(raw_img)
        purple = (arr[:,:,0] > 200) & (arr[:,:,1] < 60) & (arr[:,:,2] > 200)
        purple_pct = purple.sum() / (arr.shape[0] * arr.shape[1]) * 100
        print(f"  紫色背景保留: {purple_pct:.1f}%")

        if purple_pct < 10:
            print(f"  ⚠️ 紫色背景丢失过多，跳过")
            continue

        # 2. 抠图
        clean_img = remove_purple_bg(raw_img, min_cluster_size=200)
        clean_path = out_dir / f"blink_{label}_clean.png"
        clean_img.save(clean_path)
        print(f"  ✓ 抠图完成: {clean_path.name}")

        # 3. Diff overlay（限制在眼部 ROI）
        overlay_path = out_dir / out_name
        stats = generate_diff_overlay(
            base, clean_img, overlay_path,
            threshold=18.0, feather_radius=3.5, min_alpha=15,
            roi=EYE_ROI,
        )
        print(f"  ✓ overlay: {out_name}")
        print(f"    有效像素: {stats['nonzero_pixels']}px ({stats['pct_nonzero']}%)")
        print(f"    文件大小: {stats['file_kb']}KB")

    # ── 写入帧配置 ──
    config = {
        "frames": [
            {"name": "half", "file": "eyes_half.png", "description": "半闭眼"},
            {"name": "closed", "file": "eyes_closed.png", "description": "全闭眼"},
        ],
        "roi": list(EYE_ROI),
    }
    config_path = out_dir / "blink_frames.json"
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print(f"\n✓ 帧配置已写入: {config_path.name}")
    print("\n完成！重启 Godot 导入新纹理即可测试。")


if __name__ == "__main__":
    main()
