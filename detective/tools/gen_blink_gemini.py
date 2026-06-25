#!/usr/bin/env python3
"""调用 Gemini 2.5 Flash Image, 让其在保持原图基础上"只改眼睛"生成闭眼/半闭眼变体.

工作流:
  1. 读 base 立绘 (assets/cn/portraits/companion_<role>.png)
  2. 上传 + prompt → Gemini 输出整张闭眼变体
  3. 保存到 anim_layers/<role>/gemini_<variant>_raw.png
  4. 调用 gen_overlay.py 提取差分 overlay (本目录已有, 含眉毛硬切)
  5. 调用 crop_blink_to_small.py 裁出 ROI 小贴图

依赖: 仅 Python 标准库 + Pillow + numpy (已用于 gen_overlay)

环境变量: GEMINI_API_KEY
用法:
  python tools/gen_blink_gemini.py --char lingyao --variant closed
  python tools/gen_blink_gemini.py --char lingyao --variant half
  python tools/gen_blink_gemini.py --char lingyao --all
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # detective/
ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
MODEL = "gemini-2.5-flash-image"

# 角色相关配置: ROI 与 Gemini prompt
CHAR_CONFIG = {
    "lingyao": {
        "base": "assets/cn/portraits/companion_lingyao.png",
        "out_dir": "assets/cn/portraits/anim_layers/lingyao",
        # gen_overlay.py 参数
        "roi": "300,312,215,60",
        "cut_top": 312,
        "threshold": 18,
        "feather": 3.0,
    },
}

# 用极强的"保留原图"硬约束, 把变化局限在眼睛区
COMMON_NEGATIVE = (
    "Output ONLY one PNG image, NO text or markdown. "
    "Exact same character, same pose, same costume, same hairstyle, same hair color, "
    "same earrings, same makeup, same lipstick, same skin tone, same lighting, "
    "same background color, same image dimensions. "
    "DO NOT change eyebrows, forehead, nose, mouth, ears, neck, shoulders, hands, clothing. "
    "DO NOT add or remove accessories. DO NOT redraw the face proportions. "
    "Only modify the eyes region. Keep all other pixels identical to the input."
)

PROMPTS = {
    "closed": (
        "Take the input portrait of the character (Chinese ancient style young woman) "
        "and produce the EXACT SAME image except the eyes are gently FULLY CLOSED, "
        "as if she is mid-blink. Eyelids are softly lowered, you can see only the eyelash line. "
        "The closed-eye area should match the skin tone of the surrounding eyelid skin, "
        "with a faint natural eyelash shadow — NOT a dark grey/brown shape. "
        "Eyelashes are delicate, the closed-eye line is thin and curves naturally. "
        + COMMON_NEGATIVE
    ),
    "half": (
        "Take the input portrait of the character and produce the EXACT SAME image except "
        "the eyes are HALF CLOSED — eyelids lowered to about half, "
        "you can still see a thin slit of the iris. This is the mid-frame of a blink. "
        "Eyelid color must blend smoothly with the surrounding skin tone, "
        "NOT appear as a dark patch. "
        + COMMON_NEGATIVE
    ),
}


def call_gemini(base_image: Path, prompt: str, out_path: Path) -> None:
    """调 Gemini 2.5 Flash Image, image-to-image 编辑."""
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        sys.exit("缺少环境变量 GEMINI_API_KEY")

    img_bytes = base_image.read_bytes()
    b64 = base64.b64encode(img_bytes).decode()

    body = {
        "contents": [{
            "role": "user",
            "parts": [
                {"text": prompt},
                {"inline_data": {"mime_type": "image/png", "data": b64}},
            ],
        }],
        "generationConfig": {
            "responseModalities": ["IMAGE"],
            "temperature": 0.2,
        },
    }
    data = json.dumps(body).encode()
    url = ENDPOINT.format(model=MODEL, key=api_key)
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json"},
    )
    print(f"  → 调 Gemini ({MODEL}), 输入 {len(img_bytes)/1024:.0f}KB ...")
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            res = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        err = e.read().decode(errors="replace")
        sys.exit(f"  ✗ Gemini HTTP {e.code}: {err[:500]}")

    # 找返回里的 inline_data image
    image_data = None
    for cand in res.get("candidates", []):
        for part in cand.get("content", {}).get("parts", []):
            inline = part.get("inline_data") or part.get("inlineData")
            if inline and inline.get("data"):
                image_data = base64.b64decode(inline["data"])
                break
        if image_data:
            break

    if image_data is None:
        # debug: 把响应保存下来
        debug = out_path.with_suffix(".debug.json")
        debug.write_text(json.dumps(res, indent=2, ensure_ascii=False), encoding="utf-8")
        sys.exit(f"  ✗ 响应中没有图像 (调试输出: {debug})")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(image_data)
    print(f"  ✓ 保存 {out_path} ({len(image_data)/1024:.0f}KB)")


def run_overlay_pipeline(char: str, variant: str) -> None:
    """生成变体 raw → 跑 gen_overlay.py → 跑 crop_blink_to_small.py"""
    cfg = CHAR_CONFIG[char]
    base = ROOT / cfg["base"]
    out_dir = ROOT / cfg["out_dir"]
    raw = out_dir / f"gemini_{variant}_raw.png"

    print(f"\n=== {char} / {variant} ===")
    call_gemini(base, PROMPTS[variant], raw)

    # 跑差分 overlay (用现有脚本)
    overlay_script = ROOT / ".codebuddy/skills/portrait-blink-animation/scripts/gen_overlay.py"
    full_overlay = out_dir / f"eyes_{variant}_v2.png"   # 全帧版, 临时
    print(f"  → 差分提取 → {full_overlay.name}")
    rc = subprocess.run([
        sys.executable, str(overlay_script),
        "--base", str(base),
        "--variant", str(raw),
        "--output", str(full_overlay),
        "--roi", cfg["roi"],
        "--cut-top", str(cfg["cut_top"]),
        "--threshold", str(cfg["threshold"]),
        "--feather", str(cfg["feather"]),
    ], cwd=ROOT).returncode
    if rc != 0:
        sys.exit(f"  ✗ gen_overlay.py 失败 rc={rc}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--char", required=True, choices=list(CHAR_CONFIG.keys()))
    ap.add_argument("--variant", choices=["closed", "half"])
    ap.add_argument("--all", action="store_true", help="生成 closed + half 两套")
    args = ap.parse_args()

    if not args.variant and not args.all:
        sys.exit("需指定 --variant closed|half 或 --all")

    variants = ["closed", "half"] if args.all else [args.variant]
    for v in variants:
        run_overlay_pipeline(args.char, v)

    # 最后一次性裁小图
    print("\n=== 裁切为 ROI 小贴图 ===")
    crop_script = ROOT / "tools/crop_blink_to_small.py"
    # 先把 v2 改名覆盖 eyes_closed.png / eyes_half.png (作为新版本)
    out_dir = ROOT / CHAR_CONFIG[args.char]["out_dir"]
    for v in variants:
        new_full = out_dir / f"eyes_{v}_v2.png"
        target = out_dir / f"eyes_{v}.png"
        if new_full.exists():
            # 保留旧版做备份
            backup = out_dir / f"eyes_{v}_pre_gemini.png"
            if target.exists() and not backup.exists():
                target.rename(backup)
                print(f"  备份旧版 → {backup.name}")
            new_full.rename(target)
            print(f"  替换 → {target.name}")
    rc = subprocess.run([sys.executable, str(crop_script), args.char], cwd=ROOT).returncode
    if rc != 0:
        sys.exit(f"  ✗ crop_blink_to_small.py 失败 rc={rc}")

    print("\n完成. 在 Godot 中重启 LingyaoBlinkSmallTest 场景查看效果.")


if __name__ == "__main__":
    main()
