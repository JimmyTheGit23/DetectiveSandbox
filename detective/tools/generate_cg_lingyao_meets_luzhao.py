"""
生成 CG：凌瑶初遇陆昭
==========================================
使用男主（陆昭）和助手（凌瑶）的立绘作为参考图，
通过 Gemini img2img 生成风格一致的场景 CG。

用法：
  python tools/generate_cg_lingyao_meets_luzhao.py
"""

from google import genai
from google.genai import types
from pathlib import Path
import os
import time

API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"

# 项目路径
PROJECT_ROOT = Path(__file__).parent.parent
PORTRAITS_DIR = PROJECT_ROOT / "assets" / "cn" / "portraits"
SCENES_DIR = PROJECT_ROOT / "assets" / "cn" / "scenes"

# 角色参考立绘
LU_ZHAO_PORTRAIT = PORTRAITS_DIR / "lu_zhao.png"
LINGYAO_PORTRAIT = PORTRAITS_DIR / "companion_lingyao_v10.png"

# 风格参考场景
STYLE_REFERENCE_IMAGES = [
    (SCENES_DIR / "guanyin_temple.png", "image/png"),
    (SCENES_DIR / "post_station.png", "image/png"),
]

STYLE_LOCK = """

STYLE LOCK:
- Match the supplied style reference scenes exactly: muted gray-green/brown palette, thin hand-drawn ink outlines, soft watercolor wash, calm visual density, no glossy modern anime lighting, no high-saturation cinematic rendering.
- Ming Dynasty setting only: wood, mud walls, gray tiles, bamboo, straw rain capes, bamboo conical hats. No modern umbrellas, no western umbrellas, no plastic, no glass storefronts, no modern docks, no metal railings, no electric lamps, no modern flags.
- Do not include readable text anywhere. No Chinese characters, no calligraphy, no labels, no signs with words, no seals, no stamps, no envelopes with markings. If a signboard or paper appears, it must be blank or only abstract stains.
"""

OUTPUT_PATH = SCENES_DIR / "prologue_cg_lingyao_meets_luzhao.png"

PROMPT = """Based on these character reference images, generate a WIDE LANDSCAPE scene illustration in Chinese ink wash painting style.

Scene: A rescue scene in heavy rain at a riverside shore. Ming Dynasty China, winter dawn. The rain is pouring down heavily. A young man has just been shipwrecked and washed ashore — a young woman warrior finds him and pulls him up.

Characters:
- The FIRST reference character (young man in dark navy blue official robes) is COLLAPSED/LYING on the muddy riverbank, half-submerged in shallow water. He is barely conscious, soaking wet, face turned upward weakly. His robes are torn and waterlogged. He is the VICTIM who nearly drowned.
- The SECOND reference character (young woman in dark slate blue/navy gray martial arts outfit with white trim, high ponytail, leather arm guards) is CROUCHING beside him, actively pulling him up by his arm/shoulder. She is the RESCUER. Her expression is urgent and determined — she is saving his life. One hand grips his arm firmly, the other supports his back. She is strong and capable.

Composition:
- The man is LOW in the frame, lying/slumped on the wet ground at center, clearly helpless and weak
- The woman is ABOVE him, crouching/kneeling beside him, actively lifting him — she is clearly the one in control, the rescuer
- Her posture shows physical strength and urgency — leaning forward, arms engaged in pulling him up
- Rain pours heavily around them
- Background: misty river, distant mountains barely visible, reeds/grass at the water's edge, scattered rocks, debris from the shipwreck floating nearby
- Cold dawn light on the horizon

Atmosphere: Dramatic rescue. The woman is saving the man's life. She is strong, capable, and in charge of the situation. He is weak, barely conscious, dependent on her help. Cold blue-gray dominant palette with subtle warm amber on the horizon.

CRITICAL: The WOMAN is the RESCUER (standing/crouching ABOVE, pulling UP). The MAN is the VICTIM (lying DOWN, being rescued). Do NOT reverse this — the woman saves the man.
CRITICAL: Keep BOTH characters' clothing and appearance EXACTLY matching their reference images. The man wears dark navy official robes. The woman wears dark slate blue martial outfit with white trim and arm guards.
CRITICAL: Both characters must be clearly visible with recognizable features — NOT silhouettes. Show their faces, clothing details, and colors clearly despite the rain.
CRITICAL: LANDSCAPE 16:9 format. Cinematic dramatic composition.

Art style: Chinese ink wash with dramatic cinematic lighting. Muted but NOT monochrome — preserve character clothing colors (dark navy blue for him, dark slate blue with white trim for her).

IMPORTANT: Generate an image, do not just describe it."""


def main():
    if not API_KEY:
        raise RuntimeError("请先设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")

    print("=" * 60)
    print("生成 CG：凌瑶初遇陆昭")
    print("=" * 60)

    # 检查参考图
    missing = []
    if not LU_ZHAO_PORTRAIT.exists():
        missing.append(str(LU_ZHAO_PORTRAIT))
    if not LINGYAO_PORTRAIT.exists():
        missing.append(str(LINGYAO_PORTRAIT))
    for path, _ in STYLE_REFERENCE_IMAGES:
        if not path.exists():
            missing.append(str(path))

    if missing:
        print(f"[ERROR] 缺少参考图:")
        for m in missing:
            print(f"  - {m}")
        return

    print(f"男主立绘: {LU_ZHAO_PORTRAIT}")
    print(f"助手立绘: {LINGYAO_PORTRAIT}")
    print(f"输出路径: {OUTPUT_PATH}")
    print()

    # 构建参考图列表：风格参考 + 角色参考
    reference_images = list(STYLE_REFERENCE_IMAGES) + [
        (LU_ZHAO_PORTRAIT, "image/png"),
        (LINGYAO_PORTRAIT, "image/png"),
    ]

    client = genai.Client(api_key=API_KEY)

    # 构建输入内容
    contents = []
    for img_path, mime_type in reference_images:
        print(f"  加载参考图: {img_path.name}")
        with open(img_path, "rb") as f:
            image_data = f.read()
        contents.append(types.Part.from_bytes(data=image_data, mime_type=mime_type))

    full_prompt = PROMPT + STYLE_LOCK
    contents.append(full_prompt)

    print(f"\n  提示词长度: {len(full_prompt)} 字符")
    print(f"  参考图数量: {len(reference_images)} 张")
    print(f"  模型: {MODEL}")
    print()
    print("  正在生成...")

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                response_modalities=["IMAGE"],
                image_config=types.ImageConfig(
                    aspect_ratio="16:9"
                )
            )
        )

        for part in response.candidates[0].content.parts:
            if part.inline_data:
                with open(OUTPUT_PATH, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"\n  [OK] 已保存: {OUTPUT_PATH}")
                print(f"  文件大小: {OUTPUT_PATH.stat().st_size / 1024:.1f} KB")
                return

        # 无图片输出
        for part in response.candidates[0].content.parts:
            if part.text:
                print(f"\n  [INFO] AI回复: {part.text[:300]}")
        print(f"\n  [FAIL] 未生成图片，可能触发了安全过滤。")

    except Exception as e:
        print(f"\n  [ERROR] {e}")


if __name__ == "__main__":
    main()
