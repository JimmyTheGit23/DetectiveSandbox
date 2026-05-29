#!/usr/bin/env python3
"""
使用 Gemini API 的 image generation 功能生成对峙姿势的立绘图片。
基于现有角色立绘生成新的对峙（法庭辩论）姿势。
"""

import json
import base64
import os
import sys
import urllib.request
import urllib.error
import struct

# ─── 配置 ───
API_KEY = "AIzaSyCD5oeTpuaamXwCw6RHPny8mA8c2eqSl78"
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PORTRAITS_DIR = os.path.join(PROJECT_ROOT, "assets", "cn", "portraits")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "cn", "portraits")

# Gemini API endpoint for image generation
# 使用 Gemini 2.5 Flash Image 模型（支持图像生成）
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={API_KEY}"

# 备选：使用 Imagen 4
IMAGEN_URL = f"https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-001:predict?key={API_KEY}"


def load_image_as_base64(image_path: str) -> str:
    """读取图片文件并返回 base64 编码"""
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def get_mime_type(image_path: str) -> str:
    """根据文件扩展名返回 MIME 类型"""
    ext = os.path.splitext(image_path)[1].lower()
    mime_map = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
    }
    return mime_map.get(ext, "image/png")


def generate_with_gemini_flash(source_image_path: str, prompt: str, output_path: str) -> bool:
    """
    使用 Gemini 2.0 Flash 的 image generation 功能。
    将原图作为输入，生成新的对峙姿势。
    """
    image_data = load_image_as_base64(source_image_path)
    mime_type = get_mime_type(source_image_path)
    
    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": image_data
                        }
                    },
                    {
                        "text": prompt
                    }
                ]
            }
        ],
        "generation_config": {
            "response_modalities": ["TEXT", "IMAGE"],
            "temperature": 0.8
        }
    }
    
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            print(f"  API 响应状态: {resp.status}")
            return extract_image_from_response(result, output_path)
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8") if e.fp else ""
        print(f"  HTTP 错误 {e.code}: {e.reason}")
        print(f"  响应内容: {error_body[:1000]}")
        return False
    except Exception as e:
        print(f"  请求失败: {type(e).__name__}: {e}")
        return False


def generate_with_imagen(source_image_path: str, prompt: str, output_path: str) -> bool:
    """
    使用 Imagen 3 API 进行 image-to-image 生成。
    注意：Imagen 3 的 predict 格式与 Gemini 不同。
    """
    image_data = load_image_as_base64(source_image_path)
    mime_type = get_mime_type(source_image_path)
    
    # Imagen 3 预测格式
    payload = {
        "instances": [
            {
                "prompt": prompt,
                "image": {
                    "bytesBase64": image_data
                }
            }
        ],
        "parameters": {
            "sampleCount": 1,
            "aspectRatio": "1:1",
            "outputMimeType": "image/png",
            "safetyFilterLevel": "block_some"
        }
    }
    
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        IMAGEN_URL,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            print(f"  Imagen API 响应状态: {resp.status}")
            return extract_image_from_imagen_response(result, output_path)
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8") if e.fp else ""
        print(f"  Imagen HTTP 错误 {e.code}: {e.reason}")
        print(f"  响应内容: {error_body[:1000]}")
        return False
    except Exception as e:
        print(f"  Imagen 请求失败: {type(e).__name__}: {e}")
        return False


def extract_image_from_response(result: dict, output_path: str) -> bool:
    """从 Gemini API 响应中提取图片"""
    try:
        candidates = result.get("candidates", [])
        if not candidates:
            print("  错误: 响应中没有 candidates")
            print(f"  完整响应: {json.dumps(result, indent=2)[:2000]}")
            return False
        
        parts = candidates[0].get("content", {}).get("parts", [])
        for part in parts:
            if "inlineData" in part:
                img_data = part["inlineData"]["data"]
                img_bytes = base64.b64decode(img_data)
                with open(output_path, "wb") as f:
                    f.write(img_bytes)
                print(f"  图片已保存: {output_path}")
                return True
            elif "inline_data" in part:
                img_data = part["inline_data"]["data"]
                img_bytes = base64.b64decode(img_data)
                with open(output_path, "wb") as f:
                    f.write(img_bytes)
                print(f"  图片已保存: {output_path}")
                return True
        
        # 没有找到图片数据，打印响应结构
        print("  警告: 响应中没有找到图片数据")
        print(f"  响应结构: {json.dumps(result, indent=2)[:3000]}")
        return False
    except Exception as e:
        print(f"  解析响应失败: {type(e).__name__}: {e}")
        print(f"  响应: {json.dumps(result, indent=2)[:2000]}")
        return False


def extract_image_from_imagen_response(result: dict, output_path: str) -> bool:
    """从 Imagen API 响应中提取图片"""
    try:
        predictions = result.get("predictions", [])
        if not predictions:
            print("  错误: Imagen 响应中没有 predictions")
            print(f"  完整响应: {json.dumps(result, indent=2)[:2000]}")
            return False
        
        pred = predictions[0]
        if "bytesBase64" in pred:
            img_bytes = base64.b64decode(pred["bytesBase64"])
            with open(output_path, "wb") as f:
                f.write(img_bytes)
            print(f"  图片已保存: {output_path}")
            return True
        
        print(f"  Imagen 响应格式异常: {json.dumps(pred, indent=2)[:1000]}")
        return False
    except Exception as e:
        print(f"  解析 Imagen 响应失败: {type(e).__name__}: {e}")
        return False


def remove_green_background(input_path: str, output_path: str) -> bool:
    """去除纯绿色背景，生成带透明通道的PNG。
    使用更宽松的绿色检测阈值，确保各种绿色变体都能被去除。"""
    try:
        from PIL import Image
        import numpy as np
        
        img = Image.open(input_path).convert("RGBA")
        data = np.array(img, dtype=np.float64)
        r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
        
        # 多重绿色检测策略：
        # 策略1: 纯绿 #00FF00 - 绿色通道最高，红蓝通道低
        mask1 = (g > 150) & (g > r * 1.5) & (g > b * 1.5)
        
        # 策略2: 偏绿的橄榄色/暗绿色 - g > 100 且 g 明显高于 r 和 b
        mask2 = (g > 80) & (g - r > 30) & (g - b > 30) & (g > b * 1.2)
        
        # 策略3: 宽松的绿色检测 - g 通道最高且 g > 80
        mask3 = (g > 80) & (g >= r) & (g >= b) & ((g - r) > 15) & ((g - b) > 15)
        
        green_mask = mask1 | mask2 | mask3
        
        # 距离衰减：让绿色边缘的像素半透明（避免锯齿）
        result = np.array(img).copy()
        
        # 对于绿色 mask 为真的像素，设为完全透明
        result[:,:,3] = np.where(green_mask, 0, result[:,:,3])
        
        # 对于接近绿色的边缘像素，设为半透明
        # 找到边缘区域（接近但不完全在绿色 mask 内）
        edge_threshold = 0.7
        g_ratio = np.where((r + b) > 0, g / (r + b + 0.001), 0)
        near_green = (g_ratio > edge_threshold) & (g > 60) & (~green_mask)
        # 只在角色轮廓附近应用半透明（避免大面积误判）
        # 通过检查像素周围是否也有绿色来判断是否在边缘
        result[:,:,3] = np.where(near_green, 
                                  np.clip(result[:,:,3].astype(float) * 0.5, 0, 255).astype(np.uint8),
                                  result[:,:,3])
        
        result_img = Image.fromarray(result)
        result_img.save(output_path, "PNG")
        
        # 统计
        total_pixels = green_mask.size
        removed_pixels = np.sum(green_mask)
        print(f"  去除背景完成: {removed_pixels}/{total_pixels} 像素被移除 ({removed_pixels*100//total_pixels}%)")
        print(f"  透明背景图片已保存: {output_path}")
        return True
        
    except ImportError:
        print("  未安装 Pillow/numpy，无法去除背景")
        print("  请运行: pip install Pillow numpy")
        return False
    except Exception as e:
        print(f"  去除背景失败: {type(e).__name__}: {e}")
        return False


def main():
    print("=" * 60)
    print("  对峙姿势立绘生成器 (Gemini API)")
    print("=" * 60)
    print()
    
    # ─── 陆昭（主角）───
    # 使用 prologue 布衣版本作为源图
    lu_zhao_source = os.path.join(PORTRAITS_DIR, "prologue_lu_zhao.png")
    lu_zhao_output = os.path.join(OUTPUT_DIR, "lu_zhao_confrontation_pose.png")
    
    if not os.path.exists(lu_zhao_source):
        # 回退
        lu_zhao_source = os.path.join(PORTRAITS_DIR, "lu_zhao_serious.png")
    if not os.path.exists(lu_zhao_source):
        lu_zhao_source = os.path.join(PORTRAITS_DIR, "lu_zhao.png")
    
    if not os.path.exists(lu_zhao_source):
        print("错误: 找不到陆昭的源立绘")
        sys.exit(1)
    
    lu_zhao_prompt = """Based on this character reference image, generate a new portrait of the SAME character in a new pose.

CRITICAL BACKGROUND REQUIREMENT:
- The background MUST be a completely flat, uniform, solid pure green color (RGB 0, 255, 0)
- ZERO texture, ZERO noise, ZERO variation in the background
- Every single pixel in the background area must be EXACTLY (0, 255, 0)
- Do NOT add any patterns, gradients, shadows, or brush strokes to the background
- The background must be perfectly flat and clean like a computer-generated solid fill
- The character must NOT contain this pure green color anywhere

CHARACTER POSE AND EXPRESSION:
- The character MUST be facing to the RIGHT with their face/body clearly turned right
- The character's head is turned to the RIGHT side of the image, looking right
- The body is in a three-quarter profile, body angled to face the right
- Expression: serious, calm, determined - NOT smiling, NOT evil, NOT smirking
- Hands are at the character's sides naturally, NO pointing, NO gestures, NO raised hands
- Standing upright with good posture, looking forward to the right
- This is a standard standing portrait pose for a dialogue game

CHARACTER CONSISTENCY (MOST IMPORTANT):
- You MUST preserve the EXACT same character from the reference image
- Same clothing, same colors, same patterns, same hairstyle
- Same face shape, same eye style, same hair color
- Same art style (Chinese ink wash painting / ancient Chinese setting)
- This is image-to-image, NOT creating a new character
- The character should look like the SAME person, just in a different pose
- The character MUST be facing and looking to the RIGHT

Upper body portrait, from waist up, character facing RIGHT. Completely flat solid green background (#00FF00, RGB 0,255,0). No texture or noise in the background at all."""

    # ─── 凌瑶（助手）───
    lingyao_source = os.path.join(PORTRAITS_DIR, "companion_lingyao_determined.png")
    lingyao_output = os.path.join(OUTPUT_DIR, "companion_lingyao_confrontation_pose.png")
    
    if not os.path.exists(lingyao_source):
        # 回退到默认立绘
        lingyao_source = os.path.join(PORTRAITS_DIR, "companion_lingyao.png")
    
    if not os.path.exists(lingyao_source):
        print("错误: 找不到凌瑶的源立绘")
        sys.exit(1)
    
    lingyao_prompt = """Based on this character reference image, generate a new portrait of the SAME character in a new pose.

CRITICAL BACKGROUND REQUIREMENT:
- The background MUST be a completely flat, uniform, solid pure green color (RGB 0, 255, 0)
- ZERO texture, ZERO noise, ZERO variation in the background
- Every single pixel in the background area must be EXACTLY (0, 255, 0)
- Do NOT add any patterns, gradients, shadows, or brush strokes to the background
- The background must be perfectly flat and clean like a computer-generated solid fill
- The character must NOT contain this pure green color anywhere

CHARACTER POSE AND EXPRESSION:
- The character is standing in a three-quarter profile view, facing to the RIGHT side of the image
- The character's body is angled/sideways, not facing the viewer directly
- Expression: serious, focused, intelligent - NOT smiling, NOT evil. A calm determined look
- Hands are at the character's sides naturally, NO pointing, NO gestures, NO raised hands
- Standing upright with good posture, looking forward (to the right)
- This is a standard standing portrait pose for a dialogue game

CHARACTER CONSISTENCY (MOST IMPORTANT):
- You MUST preserve the EXACT same character from the reference image
- Same clothing, same colors, same patterns, same hairstyle
- Same face shape, same eye style, same hair color
- Same art style (Chinese ink wash painting / ancient Chinese setting)
- This is image-to-image, NOT creating a new character
- The character should look like the SAME person, just in a different pose

Upper body portrait, from waist up, facing right. Completely flat solid green background (#00FF00, RGB 0,255,0). No texture or noise in the background at all."""

    # ─── 凌瑶（助手）- 标准表情 ──
    lingyao_normal_source = os.path.join(PORTRAITS_DIR, "companion_lingyao.png")
    lingyao_normal_output = os.path.join(OUTPUT_DIR, "companion_lingyao_confrontation_normal.png")
    
    if not os.path.exists(lingyao_normal_source):
        lingyao_normal_source = os.path.join(PORTRAITS_DIR, "companion_lingyao_determined.png")
    
    lingyao_normal_prompt = """Based on this character reference image, generate a new portrait of the SAME character in a new pose.

CRITICAL BACKGROUND REQUIREMENT:
- The background MUST be a completely flat, uniform, solid pure green color (RGB 0, 255, 0)
- ZERO texture, ZERO noise, ZERO variation in the background
- Every single pixel in the background area must be EXACTLY (0, 255, 0)
- Do NOT add any patterns, gradients, shadows, or brush strokes to the background
- The background must be perfectly flat and clean like a computer-generated solid fill
- The character must NOT contain this pure green color anywhere

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
- The character should look like the SAME person, just in a different pose

Upper body portrait, from waist up, facing right. Completely flat solid green background (#00FF00, RGB 0,255,0). No texture or noise in the background at all."""

    # ─── 生成 ───
    success_count = 0
    total = 3
    
    print(f"[1/3] 生成陆昭对峙立绘...")
    print(f"  源图: {lu_zhao_source}")
    print(f"  输出: {lu_zhao_output}")
    print(f"  使用 Gemini 2.0 Flash image generation...")
    if generate_with_gemini_flash(lu_zhao_source, lu_zhao_prompt, lu_zhao_output):
        success_count += 1
    else:
        print("  Gemini Flash 失败，尝试 Imagen 3...")
        if generate_with_imagen(lu_zhao_source, lu_zhao_prompt, lu_zhao_output):
            success_count += 1
    print()
    
    print(f"[2/3] 生成凌瑶对峙立绘（愤怒/坚定表情）...")
    print(f"  源图: {lingyao_source}")
    print(f"  输出: {lingyao_output}")
    print(f"  使用 Gemini 2.0 Flash image generation...")
    if generate_with_gemini_flash(lingyao_source, lingyao_prompt, lingyao_output):
        success_count += 1
    else:
        print("  Gemini Flash 失败，尝试 Imagen 3...")
        if generate_with_imagen(lingyao_source, lingyao_prompt, lingyao_output):
            success_count += 1
    print()
    
    print(f"[3/3] 生成凌瑶标准表情立绘...")
    print(f"  源图: {lingyao_normal_source}")
    print(f"  输出: {lingyao_normal_output}")
    print(f"  使用 Gemini image generation...")
    if os.path.exists(lingyao_normal_source):
        if generate_with_gemini_flash(lingyao_normal_source, lingyao_normal_prompt, lingyao_normal_output):
            success_count += 1
        else:
            if generate_with_imagen(lingyao_normal_source, lingyao_normal_prompt, lingyao_normal_output):
                success_count += 1
    else:
        print(f"  源图不存在，跳过")
    print()
    
    # ─── 去除绿色背景 ───
    print("=" * 60)
    print("  去除绿色背景...")
    print("=" * 60)
    print()
    
    bg_removed_count = 0
    
    # 陆昭：将生成的绿色背景图重命名为 _green，去除背景后保存为最终文件
    if os.path.exists(lu_zhao_output):
        lu_zhao_green = os.path.join(OUTPUT_DIR, "lu_zhao_confrontation_pose_green.png")
        lu_zhao_final = lu_zhao_output  # 最终透明背景文件
        os.rename(lu_zhao_output, lu_zhao_green)
        if remove_green_background(lu_zhao_green, lu_zhao_final):
            bg_removed_count += 1
            if os.path.exists(lu_zhao_green):
                os.remove(lu_zhao_green)
        else:
            # 去除失败，恢复原文件
            if os.path.exists(lu_zhao_green):
                os.rename(lu_zhao_green, lu_zhao_output)
    
    # 凌瑶愤怒/坚定表情
    if os.path.exists(lingyao_output):
        lingyao_green = os.path.join(OUTPUT_DIR, "companion_lingyao_confrontation_pose_green.png")
        lingyao_final = lingyao_output
        os.rename(lingyao_output, lingyao_green)
        if remove_green_background(lingyao_green, lingyao_final):
            bg_removed_count += 1
            if os.path.exists(lingyao_green):
                os.remove(lingyao_green)
        else:
            if os.path.exists(lingyao_green):
                os.rename(lingyao_green, lingyao_output)
    
    # 凌瑶标准表情
    if os.path.exists(lingyao_normal_output):
        lingyao_normal_green = os.path.join(OUTPUT_DIR, "companion_lingyao_confrontation_normal_green.png")
        lingyao_normal_final = lingyao_normal_output
        os.rename(lingyao_normal_output, lingyao_normal_green)
        if remove_green_background(lingyao_normal_green, lingyao_normal_final):
            bg_removed_count += 1
            if os.path.exists(lingyao_normal_green):
                os.remove(lingyao_normal_green)
        else:
            if os.path.exists(lingyao_normal_green):
                os.rename(lingyao_normal_green, lingyao_normal_output)
    
    print()
    print("=" * 60)
    print(f"  完成! 成功生成 {success_count}/{total} 张图片")
    print(f"  背景去除: {bg_removed_count}/{success_count} 张")
    print("=" * 60)
    
    if success_count == 0:
        print()
        print("提示: 如果看到 403 错误，可能需要在 Google Cloud Console 中")
        print("启用 Generative Language API 和 Imagen API。")
        print("如果看到 400 错误，可能模型不支持 image generation，")
        print("需要确认 API key 有对应的权限。")


if __name__ == "__main__":
    main()