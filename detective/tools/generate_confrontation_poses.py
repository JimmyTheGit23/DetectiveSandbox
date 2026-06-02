#!/usr/bin/env python3
"""
对峙姿势立绘生成器 v2.0（紫底色键 + magenta-only despill）

变更（v2.0）：
  - 背景从绿色 #00FF00 改为紫色 #FF00FF
  - 抠图从自定义绿底去除改为 tools/remove_purple_bg.py（flood fill + magenta-only despill）
  - 增加画布标准化（848×1264 companion / 603×900 NPC）
  - 增加验收检查（verify_portrait）

用法：
  python3 tools/generate_confrontation_poses.py
  python3 tools/generate_confrontation_poses.py --only lingyao
  python3 tools/generate_confrontation_poses.py --skip-generate  # 跳过API调用，只做后处理
"""

import json
import base64
import os
import sys
import time
import shutil
import urllib.request
import urllib.error

# ─── 配置 ───
API_KEY = os.environ.get("GEMINI_API_KEY", "")
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PORTRAITS_DIR = os.path.join(PROJECT_ROOT, "assets", "cn", "portraits")
BACKUP_DIR = os.path.join(PORTRAITS_DIR, "backup_confrontation_v1")

# Gemini API
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={API_KEY}"

# 紫底背景 prompt 模板
MAGENTA_BG_PROMPT = """
CRITICAL BACKGROUND REQUIREMENT:
- The background MUST be a completely flat, uniform, solid pure magenta color (#FF00FF, RGB 255,0,255)
- ZERO texture, ZERO noise, ZERO variation in the background
- Every single pixel in the background area must be EXACTLY (255, 0, 255)
- Do NOT add any patterns, gradients, shadows, or brush strokes to the background
- The background must be perfectly flat and clean like a computer-generated solid fill
- The character must NOT contain this pure magenta color anywhere in clothing or skin
"""


def load_image_as_base64(image_path: str) -> str:
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def get_mime_type(image_path: str) -> str:
    ext = os.path.splitext(image_path)[1].lower()
    return {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg"}.get(ext, "image/png")


def generate_with_gemini(source_image_path: str, prompt: str, output_path: str) -> bool:
    image_data = load_image_as_base64(source_image_path)
    mime_type = get_mime_type(source_image_path)

    payload = {
        "contents": [{"parts": [
            {"inline_data": {"mime_type": mime_type, "data": image_data}},
            {"text": prompt},
        ]}],
        "generationConfig": {"responseModalities": ["IMAGE", "TEXT"], "temperature": 0.8}
    }

    for attempt in range(3):
        try:
            req = urllib.request.Request(
                API_URL,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=120) as resp:
                result = json.loads(resp.read().decode("utf-8"))
                return _extract_image(result, output_path)
        except urllib.error.HTTPError as e:
            error_body = e.read().decode("utf-8") if e.fp else ""
            print(f"  HTTP {e.code}: {e.reason}")
            if e.code == 503 and attempt < 2:
                wait = 20 * (2 ** attempt)
                print(f"  重试 {attempt+1}/3，等待 {wait}s...")
                time.sleep(wait)
                continue
            print(f"  响应: {error_body[:500]}")
            return False
        except Exception as e:
            print(f"  请求失败: {type(e).__name__}: {e}")
            return False
    return False


def _extract_image(result: dict, output_path: str) -> bool:
    try:
        parts = result.get("candidates", [{}])[0].get("content", {}).get("parts", [])
        for part in parts:
            img_data = part.get("inlineData", part.get("inline_data", {})).get("data")
            if img_data:
                with open(output_path, "wb") as f:
                    f.write(base64.b64decode(img_data))
                print(f"  紫底图已保存: {output_path}")
                return True
        print("  警告: 响应中没有图片数据")
        return False
    except Exception as e:
        print(f"  解析失败: {e}")
        return False


def chromakey_portrait(input_path: str, output_path: str, canvas_size: tuple = (848, 1264)) -> bool:
    """使用 tools/remove_purple_bg.py 做紫底色键 + magenta despill + 画布标准化。"""
    sys.path.insert(0, os.path.join(PROJECT_ROOT, "tools"))
    from remove_purple_bg import remove_purple_bg, verify_portrait

    remove_purple_bg(input_path, output_path, portrait=True, canvas_size=canvas_size)

    if not verify_portrait(output_path):
        print(f"  ⚠ 验收未通过: {output_path}")
        return False
    print(f"  ✅ 验收通过: {output_path}")
    return True


# ─── 角色定义 ───
CHARACTERS = [
    {
        "key": "lu_zhao_confrontation_pose",
        "source": ["prologue_lu_zhao.png", "lu_zhao_serious.png", "lu_zhao.png"],
        "canvas": (603, 900),
        "prompt": (
            "Based on this character reference image, generate a new portrait of the SAME character in a new pose.\n\n"
            + MAGENTA_BG_PROMPT +
            """
CHARACTER POSE AND EXPRESSION:
- The character MUST be facing to the RIGHT with their face/body clearly turned right
- Three-quarter profile, body angled to face the right
- Expression: serious, calm, determined - NOT smiling, NOT evil, NOT smirking
- Hands are at the character's sides naturally, NO pointing, NO gestures, NO raised hands
- Standing upright with good posture, looking forward to the right

CHARACTER CONSISTENCY (MOST IMPORTANT):
- You MUST preserve the EXACT same character from the reference image
- Same clothing, same colors, same patterns, same hairstyle
- Same face shape, same eye style, same hair color
- Same art style (Chinese ink wash painting / ancient Chinese setting)
- This is image-to-image, NOT creating a new character

Upper body portrait, from waist up, character facing RIGHT. Completely flat solid magenta background (#FF00FF, RGB 255,0,255).
"""
        ),
    },
    {
        "key": "companion_lingyao_confrontation_pose",
        "source": ["companion_lingyao_determined.png", "companion_lingyao.png"],
        "canvas": (848, 1264),
        "prompt": (
            "Based on this character reference image, generate a new portrait of the SAME character in a new pose.\n\n"
            + MAGENTA_BG_PROMPT +
            """
CHARACTER POSE AND EXPRESSION:
- The character is standing in a three-quarter profile view, facing to the RIGHT side of the image
- The character's body is angled/sideways, not facing the viewer directly
- Expression: serious, focused, intelligent - NOT smiling, NOT evil. A calm determined look
- Hands are at the character's sides naturally, NO pointing, NO gestures, NO raised hands
- Standing upright with good posture, looking forward (to the right)

CHARACTER CONSISTENCY (MOST IMPORTANT):
- You MUST preserve the EXACT same character from the reference image
- Same clothing, same colors, same patterns, same hairstyle
- Same face shape, same eye style, same hair color
- Same art style (Chinese ink wash painting / ancient Chinese setting)
- This is image-to-image, NOT creating a new character

Upper body portrait, from waist up, facing right. Completely flat solid magenta background (#FF00FF, RGB 255,0,255).
"""
        ),
    },
    {
        "key": "companion_lingyao_confrontation_normal",
        "source": ["companion_lingyao.png", "companion_lingyao_determined.png"],
        "canvas": (848, 1264),
        "prompt": (
            "Based on this character reference image, generate a new portrait of the SAME character in a new pose.\n\n"
            + MAGENTA_BG_PROMPT +
            """
CHARACTER POSE AND EXPRESSION:
- The character is standing in a three-quarter profile view, facing to the RIGHT side of the image
- The character's body is angled/sideways, not facing the viewer directly
- Expression: calm, neutral, relaxed - a standard standing portrait expression. Not angry, not smiling, just a normal composed look
- Hands are at the character's sides naturally, NO pointing, NO gestures, NO raised hands
- Standing upright with good posture, looking forward (to the right)
- This is a standard standing portrait pose for a dialogue game - the DEFAULT expression

CHARACTER CONSISTENCY (MOST IMPORTANT):
- You MUST preserve the EXACT same character from the reference image
- Same clothing, same colors, same patterns, same hairstyle
- Same face shape, same eye style, same hair color
- Same art style (Chinese ink wash painting / ancient Chinese setting)
- This is image-to-image, NOT creating a new character

Upper body portrait, from waist up, facing right. Completely flat solid magenta background (#FF00FF, RGB 255,0,255).
"""
        ),
    },
]


def find_source(source_list: list) -> str:
    for name in source_list:
        path = os.path.join(PORTRAITS_DIR, name)
        if os.path.exists(path):
            return path
    return None


def backup_old(key: str) -> None:
    """归档旧文件到 backup 目录。"""
    src = os.path.join(PORTRAITS_DIR, f"{key}.png")
    if os.path.exists(src):
        os.makedirs(BACKUP_DIR, exist_ok=True)
        dst = os.path.join(BACKUP_DIR, f"{key}.png")
        shutil.copy2(src, dst)
        print(f"  已归档: {src} → {dst}")


def main():
    import argparse
    ap = argparse.ArgumentParser(description="对峙姿势立绘生成器 v2.0（紫底色键）")
    ap.add_argument("--only", action="append", help="只生成指定角色 key")
    ap.add_argument("--skip-generate", action="store_true", help="跳过API调用，只做后处理")
    ap.add_argument("--skip-backup", action="store_true", help="跳过备份")
    args = ap.parse_args()

    print("=" * 60)
    print("  对峙姿势立绘生成器 v2.0（紫底色键 + magenta despill）")
    print("=" * 60)

    targets = CHARACTERS
    if args.only:
        keys = set(args.only)
        targets = [c for c in CHARACTERS if c["key"] in keys]
        if not targets:
            print(f"未找到指定角色: {args.only}")
            available = [c["key"] for c in CHARACTERS]
            print(f"可用: {available}")
            sys.exit(1)

    success = 0
    failed = 0

    for i, char in enumerate(targets, 1):
        key = char["key"]
        final_path = os.path.join(PORTRAITS_DIR, f"{key}.png")
        raw_path = os.path.join(PORTRAITS_DIR, f"{key}_magenta_raw.png")

        print(f"\n[{i}/{len(targets)}] {key}")
        print(f"  画布: {char['canvas'][0]}×{char['canvas'][1]}")

        # 1. 归档旧文件
        if not args.skip_backup:
            backup_old(key)

        # 2. 找源图
        source_path = find_source(char["source"])
        if not source_path:
            print(f"  ❌ 找不到源图: {char['source']}")
            failed += 1
            continue
        print(f"  源图: {source_path}")

        # 3. 调 API 生成紫底图
        if not args.skip_generate:
            print(f"  调用 Gemini API 生成紫底图...")
            if not generate_with_gemini(source_path, char["prompt"], raw_path):
                print(f"  ❌ 生成失败")
                failed += 1
                continue
            time.sleep(5)  # 避免 API 限流
        else:
            if not os.path.exists(raw_path):
                print(f"  ❌ 跳过生成但找不到紫底草图: {raw_path}")
                failed += 1
                continue

        # 4. 紫底色键 + despill + 画布标准化
        print(f"  执行紫底色键 + magenta despill...")
        if chromakey_portrait(raw_path, final_path, canvas_size=char["canvas"]):
            success += 1
            # 清理中间文件
            if os.path.exists(raw_path) and raw_path != final_path:
                os.remove(raw_path)
        else:
            failed += 1

    print(f"\n{'=' * 60}")
    print(f"  完成: {success} 成功 / {failed} 失败")
    if success > 0:
        print(f"  备份目录: {BACKUP_DIR}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
