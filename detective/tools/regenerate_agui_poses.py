#!/usr/bin/env python3
"""
Regenerate agui confrontation poses with correct dimensions (832x1248).
Uses Gemini API image-to-image generation with the base portrait as reference.
Generates pure green background for easy chroma key removal.
"""

import json
import base64
import os
import sys
import urllib.request
import urllib.error

# --- Config ---
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PORTRAITS_DIR = os.path.join(PROJECT_ROOT, "assets", "cn", "portraits")
OUTPUT_DIR = PORTRAITS_DIR

if not API_KEY:
    print("错误：请先设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY", file=sys.stderr)
    sys.exit(1)

# Gemini API endpoint
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={API_KEY}"

# Source image: use the base portrait for character consistency
SOURCE_IMAGE = os.path.join(PORTRAITS_DIR, "prologue_agui.png")

# --- Target size ---
TARGET_WIDTH = 832
TARGET_HEIGHT = 1248

# --- Poses to generate ---
POSES = [
    {
        "name": "confrontation",
        "output": "prologue_agui_confrontation.png",
        "prompt": (
            "Based on this character reference image, generate a new portrait of the SAME character "
            "in a confrontation pose.\n\n"
            "CRITICAL BACKGROUND REQUIREMENT:\n"
            "- The background MUST be a completely flat, uniform, solid pure green color (RGB 0, 255, 0)\n"
            "- ZERO texture, ZERO noise, ZERO variation in the background\n"
            "- Every single pixel in the background area must be EXACTLY (0, 255, 0)\n"
            "- Do NOT add any patterns, gradients, shadows, or brush strokes to the background\n"
            "- The character must NOT contain this pure green color (0, 255, 0) anywhere\n\n"
            "CRITICAL SIZE REQUIREMENT:\n"
            "- Output image MUST be exactly 832 pixels wide and 1248 pixels tall\n"
            "- Aspect ratio must be exactly 2:3 (width:height)\n\n"
            "CHARACTER POSE AND EXPRESSION:\n"
            "- Upper body portrait, from waist up\n"
            "- Standing in a three-quarter profile view, facing to the RIGHT\n"
            "- Expression: stern, confident, slightly intimidating\n"
            "- Hands at the character's sides naturally, NO pointing, NO gestures\n"
            "- Standing upright with good posture\n\n"
            "CHARACTER CONSISTENCY (MOST IMPORTANT):\n"
            "- Preserve the EXACT same character from the reference image\n"
            "- Same clothing, same colors, same patterns, same hairstyle\n"
            "- Same face shape, same eye style, same hair color\n"
            "- Same art style (Chinese ink wash painting / ancient Chinese setting)\n"
            "- This is image-to-image, NOT creating a new character\n\n"
            "Output: upper body portrait, 832x1248 pixels, solid green background (#00FF00)."
        ),
    },
    {
        "name": "confrontation_collapsed",
        "output": "prologue_agui_confrontation_collapsed.png",
        "prompt": (
            "Based on this character reference image, generate a new portrait of the SAME character.\n\n"
            "CRITICAL BACKGROUND REQUIREMENT:\n"
            "- The background MUST be a completely flat, uniform, solid pure green color (RGB 0, 255, 0)\n"
            "- ZERO texture, ZERO noise, ZERO variation\n"
            "- Every pixel in the background must be EXACTLY (0, 255, 0)\n"
            "- The character must NOT contain this pure green color anywhere\n\n"
            "CRITICAL SIZE: Output MUST be exactly 832 pixels wide and 1248 pixels tall.\n\n"
            "CHARACTER POSE:\n"
            "- Upper body portrait, from waist up\n"
            "- Sitting or slumping forward, body collapsed/crouching\n"
            "- Expression: defeated, broken, head slightly bowed, shoulders slumped\n"
            "- Hands may be on knees or hanging limply\n\n"
            "CHARACTER CONSISTENCY: Preserve EXACT same character. Same clothing, colors, "
            "patterns, hairstyle, face shape, art style. Image-to-image, not new character.\n\n"
            "Output: 832x1248 pixels, solid green background (#00FF00)."
        ),
    },
    {
        "name": "confrontation_shaken",
        "output": "prologue_agui_confrontation_shaken.png",
        "prompt": (
            "Based on this character reference image, generate a new portrait of the SAME character.\n\n"
            "CRITICAL BACKGROUND: Flat, solid pure green (RGB 0, 255, 0). No texture/noise.\n"
            "Character must NOT contain this green color.\n\n"
            "CRITICAL SIZE: Output MUST be exactly 832x1248 pixels.\n\n"
            "CHARACTER POSE:\n"
            "- Upper body portrait, from waist up\n"
            "- Standing, slightly recoiling or leaning back\n"
            "- Expression: shaken, nervous, slightly fearful, eyes wide\n"
            "- Hands may be slightly raised in defensive posture\n\n"
            "CHARACTER CONSISTENCY: Preserve EXACT same character. Same everything.\n\n"
            "Output: 832x1248 pixels, solid green background (#00FF00)."
        ),
    },
    {
        "name": "collapsed",
        "output": "prologue_agui_collapsed.png",
        "prompt": (
            "Based on this character reference image, generate a new portrait of the SAME character.\n\n"
            "CRITICAL BACKGROUND: Flat, solid pure green (RGB 0, 255, 0). No texture/noise.\n"
            "Character must NOT contain this green color.\n\n"
            "CRITICAL SIZE: Output MUST be exactly 832x1248 pixels.\n\n"
            "CHARACTER POSE:\n"
            "- Upper body portrait, from waist up\n"
            "- Collapsed/slumping, complete defeat body language\n"
            "- Expression: broken, eyes downcast, mouth slightly open\n"
            "- Shoulders slumped forward\n\n"
            "CHARACTER CONSISTENCY: Preserve EXACT same character.\n\n"
            "Output: 832x1248 pixels, solid green background (#00FF00)."
        ),
    },
    {
        "name": "shaken",
        "output": "prologue_agui_shaken.png",
        "prompt": (
            "Based on this character reference image, generate a new portrait of the SAME character.\n\n"
            "CRITICAL BACKGROUND: Flat, solid pure green (RGB 0, 255, 0). No texture/noise.\n"
            "Character must NOT contain this green color.\n\n"
            "CRITICAL SIZE: Output MUST be exactly 832x1248 pixels.\n\n"
            "CHARACTER POSE:\n"
            "- Upper body portrait, from waist up\n"
            "- Standing, body tense and uneasy\n"
            "- Expression: shaken, worried, eyebrows raised in anxiety\n"
            "- Hands may be clasped together nervously\n\n"
            "CHARACTER CONSISTENCY: Preserve EXACT same character.\n\n"
            "Output: 832x1248 pixels, solid green background (#00FF00)."
        ),
    },
]


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
        "contents": [
            {
                "parts": [
                    {"inline_data": {"mime_type": mime_type, "data": image_data}},
                    {"text": prompt},
                ]
            }
        ],
        "generation_config": {
            "response_modalities": ["IMAGE", "TEXT"],
            "temperature": 0.8,
        },
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        API_URL, data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            print(f"  API status: {resp.status}")
            return extract_image_from_response(result, output_path)
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8") if e.fp else ""
        print(f"  HTTP error {e.code}: {e.reason}")
        print(f"  Response: {error_body[:1500]}")
        return False
    except Exception as e:
        print(f"  Request failed: {type(e).__name__}: {e}")
        return False


def extract_image_from_response(result: dict, output_path: str) -> bool:
    try:
        candidates = result.get("candidates", [])
        if not candidates:
            print("  Error: no candidates in response")
            print(f"  Response: {json.dumps(result, indent=2)[:2000]}")
            return False

        parts = candidates[0].get("content", {}).get("parts", [])
        for part in parts:
            if "inlineData" in part:
                img_bytes = base64.b64decode(part["inlineData"]["data"])
                with open(output_path, "wb") as f:
                    f.write(img_bytes)
                print(f"  Saved: {output_path}")
                return True
            elif "inline_data" in part:
                img_bytes = base64.b64decode(part["inline_data"]["data"])
                with open(output_path, "wb") as f:
                    f.write(img_bytes)
                print(f"  Saved: {output_path}")
                return True

        print("  Warning: no image data in response")
        print(f"  Structure: {json.dumps(result, indent=2)[:3000]}")
        return False
    except Exception as e:
        print(f"  Parse failed: {type(e).__name__}: {e}")
        return False


def remove_green_background(input_path: str, output_path: str) -> bool:
    try:
        from PIL import Image
        import numpy as np

        img = Image.open(input_path).convert("RGBA")
        data = np.array(img, dtype=np.float64)
        r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]

        mask1 = (g > 150) & (g > r * 1.5) & (g > b * 1.5)
        mask2 = (g > 80) & (g - r > 30) & (g - b > 30) & (g > b * 1.2)
        mask3 = (g > 80) & (g >= r) & (g >= b) & ((g - r) > 15) & ((g - b) > 15)
        green_mask = mask1 | mask2 | mask3

        result = np.array(img).copy()
        result[:, :, 3] = np.where(green_mask, 0, result[:, :, 3])

        g_ratio = np.where((r + b) > 0, g / (r + b + 0.001), 0)
        near_green = (g_ratio > 0.7) & (g > 60) & (~green_mask)
        result[:, :, 3] = np.where(
            near_green,
            np.clip(result[:, :, 3].astype(float) * 0.5, 0, 255).astype(np.uint8),
            result[:, :, 3],
        )

        Image.fromarray(result).save(output_path, "PNG")
        total = green_mask.size
        removed = np.sum(green_mask)
        print(f"  Background removed: {removed}/{total} pixels ({removed * 100 // total}%)")
        return True
    except ImportError:
        print("  Missing Pillow/numpy. Run: pip install Pillow numpy")
        return False
    except Exception as e:
        print(f"  Background removal failed: {type(e).__name__}: {e}")
        return False


def resize_to_target(input_path: str, output_path: str, target_w: int, target_h: int) -> bool:
    try:
        from PIL import Image

        img = Image.open(input_path)
        w, h = img.size

        if w == target_w and h == target_h:
            img.save(output_path, "PNG")
            print(f"  Already correct size: {target_w}x{target_h}")
            return True

        target_ratio = target_w / target_h
        current_ratio = w / h

        if current_ratio > target_ratio:
            new_w = int(h * target_ratio)
            left = (w - new_w) // 2
            img = img.crop((left, 0, left + new_w, h))
        elif current_ratio < target_ratio:
            new_h = int(w / target_ratio)
            top = (h - new_h) // 2
            img = img.crop((0, top, w, top + new_h))

        img = img.resize((target_w, target_h), Image.LANCZOS)
        img.save(output_path, "PNG")
        print(f"  Resized to {target_w}x{target_h}")
        return True
    except Exception as e:
        print(f"  Resize failed: {type(e).__name__}: {e}")
        return False


def main():
    print("=" * 60)
    print("  agui confrontation pose regenerator")
    print(f"  Target size: {TARGET_WIDTH}x{TARGET_HEIGHT}")
    print("=" * 60)
    print()

    if not os.path.exists(SOURCE_IMAGE):
        print(f"Error: source image not found: {SOURCE_IMAGE}")
        sys.exit(1)

    print(f"Source: {SOURCE_IMAGE}")
    print()

    success_count = 0
    total = len(POSES)

    for i, pose in enumerate(POSES):
        print(f"[{i + 1}/{total}] Generating: {pose['name']}...")
        output_path = os.path.join(OUTPUT_DIR, pose["output"])

        green_path = output_path.replace(".png", "_green.png")
        if generate_with_gemini(SOURCE_IMAGE, pose["prompt"], green_path):
            transparent_path = output_path.replace(".png", "_transparent.png")
            if remove_green_background(green_path, transparent_path):
                if resize_to_target(transparent_path, output_path, TARGET_WIDTH, TARGET_HEIGHT):
                    success_count += 1
                    for tmp in [green_path, transparent_path]:
                        if os.path.exists(tmp) and tmp != output_path:
                            os.remove(tmp)
                else:
                    print(f"  Failed to resize")
            else:
                print(f"  Failed to remove background")
        else:
            print(f"  Failed to generate image")

        print()

    print("=" * 60)
    print(f"  Done! {success_count}/{total} poses generated successfully")
    print(f"  Target size: {TARGET_WIDTH}x{TARGET_HEIGHT}")
    print("=" * 60)

    if success_count == 0:
        print()
        print("Note: If you see 403 errors, the API key may need to be verified.")
        print("If you see 400 errors, the model may not support image generation.")


if __name__ == "__main__":
    main()