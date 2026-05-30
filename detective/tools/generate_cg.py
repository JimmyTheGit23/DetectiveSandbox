"""
通用CG生成工具
==========================================
使用角色立绘作为参考图，通过 Gemini img2img 生成风格一致的场景 CG。

用法：
  python tools/generate_cg.py --event agui_breakdown
  python tools/generate_cg.py --event lao_fan_silence
  python tools/generate_cg.py --event shen_approach
"""

from google import genai
from google.genai import types
from pathlib import Path
import os
import argparse

API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"

# 项目路径
PROJECT_ROOT = Path(__file__).parent.parent
PORTRAITS_DIR = PROJECT_ROOT / "assets" / "cn" / "portraits"
SCENES_DIR = PROJECT_ROOT / "assets" / "cn" / "scenes"

# 风格参考场景（从已有CG提取风格）
STYLE_REFERENCE_IMAGES = [
    (SCENES_DIR / "prologue_cg_lingyao_meets_luzhao.png", "image/png"),
    (SCENES_DIR / "prologue_cg_lingyao_rush.png", "image/png"),
]

STYLE_LOCK = """

STYLE LOCK:
- Match the supplied style reference scenes exactly: muted gray-green/brown palette, thin hand-drawn ink outlines, soft watercolor wash, calm visual density, no glossy modern anime lighting, no high-saturation cinematic rendering.
- Ming Dynasty setting only: wood, mud walls, gray tiles, bamboo, straw rain capes. No modern elements.
- Do not include readable text anywhere. No Chinese characters, no calligraphy, no labels, no signs with words.
"""

# CG事件配置
CG_CONFIGS = {
    "agui_breakdown": {
        "ref_images": [
            (PORTRAITS_DIR / "prologue_agui_crying.png", "image/png"),
        ],
        "output": SCENES_DIR / "prologue_cg_agui_breakdown.png",
        "prompt": """Based on the character reference image, generate a scene illustration in Chinese ink wash painting style.

Scene: A young man breaking down crying at a ferry dock at night, kneeling on muddy ground in heavy rain.

Character:
- The reference character (阿贵, thin build, simple peasant clothes) is KNEELING on the ground, crying bitterly with hands covering his face
- He is overwhelmed with guilt and grief, his body shaking with sobs
- His clothes are wet from the rain, hair disheveled

Composition:
- Character is LOW in the frame, kneeling at center-left
- Background: traditional Chinese ferry dock at night, wooden posts, thatched roof shelter, rain pouring down
- Dim lantern light casting warm glow on wet surfaces
- A wooden boat dock visible in the background through the rain
- Muddy ground with puddles reflecting the lantern light

Atmosphere: Deeply emotional, tragic breakdown. 12 years of hidden guilt finally overflowing. Dark rainy night, isolation, despair.

CRITICAL: Keep the character's clothing and appearance EXACTLY matching the reference image.
CRITICAL: The character must be clearly visible with recognizable features — NOT a silhouette.
CRITICAL: LANDSCAPE 16:9 format. Cinematic dramatic composition.

Art style: Chinese ink wash with dramatic cinematic lighting. Muted dark palette with warm lantern highlights.""",
    },
    "lao_fan_silence": {
        "ref_images": [
            (PORTRAITS_DIR / "prologue_lao_fan.png", "image/png"),
        ],
        "output": SCENES_DIR / "prologue_cg_lao_fan_silence.png",
        "prompt": """Based on the character reference image, generate a scene illustration in Chinese ink wash painting style.

Scene: A middle-aged man standing alone at a rainy dock at night, his back partially facing the viewer, staring at the dark river in guilty silence.

Character:
- The reference character (老范, stocky build, rough merchant clothes) is standing at the edge of a wooden dock
- His posture is hunched, shoulders heavy with guilt
- He is looking out at the dark river, refusing to turn around
- Rain falling on his back, soaking his clothes

Composition:
- Character is positioned at the right third of the frame, facing left toward the dark river
- Background: wooden dock extending into darkness, rain falling heavily, distant river bank barely visible
- A single dim oil lamp on a wooden post casting warm glow
- Wet wooden planks reflecting the light
- River surface disturbed by rain, dark and ominous

Atmosphere: Heavy silence, guilt, unspoken secrets. The weight of 12 years of lies. A man alone with his conscience in the rain.

CRITICAL: Keep the character's clothing and appearance EXACTLY matching the reference image.
CRITICAL: Show the character from a 3/4 back view — face partially visible, expression somber.
CRITICAL: LANDSCAPE 16:9 format. Cinematic dramatic composition.

Art style: Chinese ink wash with dramatic cinematic lighting. Dark moody palette with single warm light source.""",
    },
    "shen_approach": {
        "ref_images": [
            (PORTRAITS_DIR / "prologue_shen_qingyue_cold_smile.png", "image/png"),
        ],
        "output": SCENES_DIR / "prologue_cg_shen_approach.png",
        "prompt": """Based on the character reference image, generate a scene illustration in Chinese ink wash painting style.

Scene: A beautiful elegant woman leaning against a wooden doorframe of a traditional Chinese inn corridor, approaching the viewer with mysterious confidence.

Character:
- The reference character (沈清月, refined features, luxurious silk robes) is leaning against a doorframe
- She has a cold, knowing smile on her lips
- Her eyes are sharp and calculating, looking directly at the viewer
- One hand rests on the doorframe, body language relaxed but predatory

Composition:
- Character is at center, framed by the wooden doorframe
- Background: traditional Chinese inn corridor, paper lanterns casting warm amber light
- Wooden walls with shadow patterns from the lattice windows
- A long corridor receding into darkness behind her
- Atmospheric fog/mist in the corridor

Atmosphere: Seductive danger, hidden motives, suspense. She knows something and is about to reveal it. A spider inviting prey into her web.

CRITICAL: Keep the character's clothing and appearance EXACTLY matching the reference image.
CRITICAL: The character must be clearly visible with recognizable features — show her face, clothing details, and colors clearly.
CRITICAL: LANDSCAPE 16:9 format. Cinematic dramatic composition.

Art style: Chinese ink wash with dramatic cinematic lighting. Warm amber lantern light contrasting with cool shadow depths.""",
    },
    "agui_confrontation_win": {
        "ref_images": [
            (PORTRAITS_DIR / "prologue_agui_confrontation_collapsed.png", "image/png"),
        ],
        "output": SCENES_DIR / "prologue_cg_agui_confrontation_win.png",
        "prompt": """Based on the character reference image, generate a scene illustration in Chinese ink wash painting style.

Scene: A young man who has just confessed to his crime, collapsed on the floor of a traditional Chinese inn main hall, finally free from the weight of his guilt.

Character:
- The reference character (阿贵, thin build, peasant clothes) is collapsed on his knees/hands on the wooden floor
- His expression shows a mix of devastation and strange relief — the truth is finally out
- Tears streaming down his face, body shaking
- His posture shows complete surrender and breakdown

Composition:
- Character is LOW in the frame, collapsed at center
- Background: traditional Chinese inn main hall, wooden pillars, heavy wooden furniture
- Other figures (investigators) standing around him in a semicircle, seen from behind/at angles
- Warm lantern light from above casting dramatic shadows
- Wooden floorboards worn and aged

Atmosphere: Climactic confession. The moment truth breaks through 12 years of lies. Dramatic, emotional, cathartic.

CRITICAL: Keep the character's clothing and appearance EXACTLY matching the reference image.
CRITICAL: The character must be clearly visible with recognizable features.
CRITICAL: LANDSCAPE 16:9 format. Cinematic dramatic composition.

Art style: Chinese ink wash with dramatic cinematic lighting. High contrast between light and shadow.""",
    },
    "shen_confrontation_win": {
        "ref_images": [
            (PORTRAITS_DIR / "prologue_shen_qingyue_broken.png", "image/png"),
        ],
        "output": SCENES_DIR / "prologue_cg_shen_confrontation_win.png",
        "prompt": """Based on the character reference image, generate a scene illustration in Chinese ink wash painting style.

Scene: A refined woman whose composure has finally cracked, her mask of elegance shattered as her crimes are exposed.

Character:
- The reference character (沈清月, refined features, luxurious silk robes) is standing but her composure has broken
- Her expression shows her facade crumbling — cold fury mixed with shock that she's been caught
- Her posture is no longer confident, slightly defensive
- One hand may be gripping a chair or table for support

Composition:
- Character is at center, standing but destabilized
- Background: traditional Chinese inn main hall, formal setting
- Investigators confronting her from across the room
- Harsh lighting exposing her, no more shadows to hide in
- Her elegant surroundings contrasting with her crumbling facade

Atmosphere: The unmasking. A predator caught in the light. Dramatic confrontation between truth and deception.

CRITICAL: Keep the character's clothing and appearance EXACTLY matching the reference image.
CRITICAL: The character must be clearly visible with recognizable features.
CRITICAL: LANDSCAPE 16:9 format. Cinematic dramatic composition.

Art style: Chinese ink wash with dramatic cinematic lighting. High contrast, exposing light vs hiding shadow.""",
    },
    "fan_night_sighting": {
        "ref_images": [
            (PORTRAITS_DIR / "prologue_lao_fan.png", "image/png"),
            (PORTRAITS_DIR / "actor_young_servant_boy.png", "image/png"),
        ],
        "output": SCENES_DIR / "prologue_cg_fan_night_sighting.png",
        "prompt": """Based on the character reference images, generate a scene illustration in Chinese ink wash painting style.

Scene: A young servant boy secretly watching a man sneaking around at the dock at night.

Characters:
- The FIRST reference character (老范, stocky build, rough merchant clothes) is walking cautiously near the dock at night, looking around nervously, carrying something
- The SECOND reference character (young servant boy) is hiding behind a wooden post, peeking out and watching the man with wide eyes

Composition:
- The man (老范) is in the mid-ground, walking near the dock edge
- The boy is in the foreground, partially hidden behind a post, only half his face visible
- Background: night scene at the ferry dock, dim moonlight, wooden boats moored
- Shadows and darkness creating a secretive atmosphere
- Wet wooden surfaces reflecting faint light

Atmosphere: Secret observation, suspicion, mystery. A witness to something that shouldn't be happening. Dark and secretive.

CRITICAL: Keep both characters' clothing and appearance EXACTLY matching their reference images.
CRITICAL: Both characters must be clearly visible with recognizable features.
CRITICAL: LANDSCAPE 16:9 format. Cinematic dramatic composition.

Art style: Chinese ink wash with dramatic cinematic lighting. Dark nighttime palette with selective moonlight illumination.""",
    },
}


def main():
    parser = argparse.ArgumentParser(description="生成序章CG图")
    parser.add_argument("--event", required=True, choices=list(CG_CONFIGS.keys()),
                        help="CG事件名称")
    parser.add_argument("--api-key", default=API_KEY, help="Gemini API Key")
    args = parser.parse_args()

    config = CG_CONFIGS[args.event]
    api_key = args.api_key or API_KEY

    if not api_key:
        raise RuntimeError("请设置 GEMINI_API_KEY 环境变量或通过 --api-key 参数传入")

    print("=" * 60)
    print(f"生成 CG: {args.event}")
    print("=" * 60)

    # 检查参考图
    missing = []
    for img_path, _ in config["ref_images"]:
        if not img_path.exists():
            missing.append(str(img_path))

    # 检查风格参考
    style_refs = []
    for img_path, mime_type in STYLE_REFERENCE_IMAGES:
        if img_path.exists():
            style_refs.append((img_path, mime_type))
        else:
            print(f"  [WARN] 风格参考图不存在，跳过: {img_path.name}")

    if missing:
        print(f"[ERROR] 缺少参考图:")
        for m in missing:
            print(f"  - {m}")
        return

    output_path = config["output"]
    print(f"参考图: {[p.name for p, _ in config['ref_images']]}")
    print(f"输出路径: {output_path}")
    print()

    # 构建参考图列表：风格参考 + 角色参考
    reference_images = style_refs + config["ref_images"]

    client = genai.Client(api_key=api_key)

    # 构建输入内容
    contents = []
    for img_path, mime_type in reference_images:
        print(f"  加载参考图: {img_path.name}")
        with open(img_path, "rb") as f:
            image_data = f.read()
        contents.append(types.Part.from_bytes(data=image_data, mime_type=mime_type))

    full_prompt = config["prompt"] + STYLE_LOCK
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
                with open(output_path, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"\n  [OK] 已保存: {output_path}")
                print(f"  文件大小: {output_path.stat().st_size / 1024:.1f} KB")
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
