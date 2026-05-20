"""
序章「渡口沉舟」完整美术生成器
==========================================
生成顺序：
  Phase 1: NPC 角色立绘（5人）
  Phase 2: 场景背景（5张）
  Phase 3: 过场 CG（4张，img2img 从角色立绘出发）

使用 Gemini 2.5 Flash image generation
"""

from google import genai
from google.genai import types
from pathlib import Path
import sys
import time
import argparse

API_KEY = "AIzaSyBr9RWOwk643l6eG0Fv91sshiU67IurMxo"
MODEL = "gemini-2.5-flash-image"

# 项目路径
PROJECT_ROOT = Path(__file__).parent.parent
PORTRAITS_DIR = PROJECT_ROOT / "assets" / "cn" / "portraits"
SCENES_DIR = PROJECT_ROOT / "assets" / "cn" / "scenes"
STYLE_REFERENCE_IMAGES = [
    (SCENES_DIR / "guanyin_temple.png", "image/png"),
    (SCENES_DIR / "post_station.png", "image/png"),
]

STYLE_LOCK = """

STYLE LOCK:
- Match the supplied style reference scenes exactly: muted gray-green/brown palette, thin hand-drawn ink outlines, soft watercolor wash, calm visual density, no glossy modern anime lighting, no high-saturation cinematic rendering.
- Ming Dynasty setting only: wood, mud walls, gray tiles, bamboo, straw rain capes, bamboo conical hats. No modern umbrellas, no western umbrellas, no plastic, no glass storefronts, no modern docks, no metal railings, no electric lamps, no modern flags.
- Do not include readable text anywhere. No Chinese characters, no calligraphy, no labels, no signs with words, no seals, no stamps, no envelopes with markings. If a signboard or paper appears, it must be blank or only abstract stains.
- Keep people small or silhouetted in backgrounds unless explicitly requested. Avoid close-up props with written information.
"""

# 确保输出目录存在
PORTRAITS_DIR.mkdir(parents=True, exist_ok=True)
SCENES_DIR.mkdir(parents=True, exist_ok=True)

# API 调用间隔（秒）
COOLDOWN = 8


def generate_image(prompt: str, output_path: Path, reference_images: list[tuple[Path, str]] = None, aspect_ratio: str = "1:1"):
    """
    生成图片。支持纯文本生成和 img2img。
    
    reference_images: [(图片路径, mime_type), ...] 用于 img2img
    aspect_ratio: "1:1" 立绘, "16:9" 场景/CG
    """
    client = genai.Client(api_key=API_KEY)
    
    # 构建输入
    contents = []
    
    if reference_images:
        for img_path, mime_type in reference_images:
            if not img_path.exists():
                print(f"  [WARN] 参考图不存在: {img_path}")
                continue
            with open(img_path, "rb") as f:
                image_data = f.read()
            contents.append(types.Part.from_bytes(data=image_data, mime_type=mime_type))
    
    contents.append(prompt)
    
    print(f"  提示词: {prompt[:80]}...")
    if reference_images:
        print(f"  参考图: {len(reference_images)} 张")
    
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                response_modalities=["IMAGE"],
                image_config=types.ImageConfig(
                    aspect_ratio=aspect_ratio
                )
            )
        )
        
        for part in response.candidates[0].content.parts:
            if part.inline_data:
                with open(output_path, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"  [OK] 已保存: {output_path}")
                return True
        
        # 无图片，输出文本
        for part in response.candidates[0].content.parts:
            if part.text:
                print(f"  [INFO] AI回复: {part.text[:200]}")
        print(f"  [FAIL] 未生成图片")
        return False
        
    except Exception as e:
        print(f"  [ERROR] {e}")
        return False


# ============================================================
# Phase 1: NPC 立绘
# ============================================================

PORTRAIT_PROMPTS = {
    "prologue_agui": {
        "prompt": """Generate a character portrait illustration in Chinese ink wash painting style (semi-realistic, anime-influenced Chinese historical art style).

Character: A Chinese man in his early 30s. He is a household servant (仆从) in the Ming Dynasty (around 1594). 

Appearance: Round face with an honest/simpleminded look, but with slightly shifty/nervous eyes that hint at hidden thoughts. Skin slightly tanned from labor. Short stubble. Hair tied in a simple low bun.

Clothing: Gray-blue rough cotton padded robe (粗布棉袍), tied at the waist with a plain cloth belt. The fabric looks worn and patched. Simple cloth shoes.

Expression: Trying to look sad/tearful, but there's something forced about it. His eyes dart to the side.

Background: SOLID BRIGHT PURPLE background (#9B30FF or similar vivid purple). The background must be a FLAT UNIFORM SOLID COLOR with NO gradients, NO patterns, NO objects. The character must NOT contain any purple elements in their design.

Pose: BUST PORTRAIT (from chest/shoulders up to top of head ONLY, NO waist, NO hands, NO lower body visible). Slightly turned, face angled as if looking away guiltily.

Art style: Chinese historical ink wash with subtle anime influence. Muted cool tones (gray-blue palette) for the CHARACTER ONLY. Consistent with Ming Dynasty period aesthetics. Ensure correct body proportions and natural pose.

CRITICAL: The background MUST be a solid flat purple color for chroma-key removal. No purple/violet in the character's clothing or skin.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_agui.png"
    },
    "prologue_lao_fan": {
        "prompt": """Generate a character portrait illustration in Chinese ink wash painting style (semi-realistic, anime-influenced Chinese historical art style).

Character: A Chinese man in his mid-40s. He is a boatman/ferryman (船家) in the Ming Dynasty (around 1594). Has worked on the Yangtze River for 20 years.

Appearance: Dark-skinned (sun and wind weathered), lean and wiry build. Prominent cheekbones, deep-set eyes with a shrewd/cunning look. Thick calluses on his hands. Face has deep wrinkles from squinting against river glare.

Clothing: Short brown hemp jacket (短褐), sleeves rolled up showing sinewy forearms. Head wrapped in a coarse cloth headband. Simple rope sandals.

Expression: A casual, slightly cocky smirk. The look of someone who thinks they're smarter than everyone else.

Background: SOLID BRIGHT PURPLE background (#9B30FF or similar vivid purple). The background must be a FLAT UNIFORM SOLID COLOR with NO gradients, NO patterns, NO objects. The character must NOT contain any purple elements in their design.

Pose: BUST PORTRAIT (from chest/shoulders up to top of head ONLY, NO waist, NO hands, NO lower body visible). Head tilted back slightly with a cocky smirk, smoking pipe visible near mouth.

Art style: Chinese historical ink wash with subtle anime influence. Warm earth tones (browns, tans) for the CHARACTER. Ming Dynasty period. Ensure correct body proportions and natural pose.

CRITICAL: The background MUST be a solid flat purple color for chroma-key removal. No purple/violet in the character's clothing or skin.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_lao_fan.png"
    },
    "prologue_zhou_wife": {
        "prompt": """Generate a character portrait illustration in Chinese ink wash painting style (semi-realistic, anime-influenced Chinese historical art style).

Character: A Chinese woman around 35 years old. She is a merchant's wife (商人之妻) in mourning in the Ming Dynasty (around 1594). Her husband just died.

Appearance: Plain but dignified face. Red-rimmed swollen eyes from crying, but her jaw is set with determination. Hair in a simple low bun (no ornaments - in mourning). Pale complexion.

Clothing: White/undyed rough hemp mourning garment (素服/孝服). Simple and unadorned. A plain white cloth headband.

Expression: Grief-stricken but resolute. She has been crying but now her eyes are fierce with determination to seek justice.

Background: SOLID BRIGHT PURPLE background (#9B30FF or similar vivid purple). The background must be a FLAT UNIFORM SOLID COLOR with NO gradients, NO patterns, NO objects. The character must NOT contain any purple elements in their design.

Pose: BUST PORTRAIT (from chest/shoulders up to top of head ONLY, NO waist, NO hands, NO lower body visible). Chin slightly raised defiantly, looking directly at viewer.

Art style: Chinese historical ink wash with subtle anime influence. Very muted/desaturated palette (whites, pale grays) for the CHARACTER. Ming Dynasty period. Ensure correct body proportions and natural pose.

CRITICAL: The background MUST be a solid flat purple color for chroma-key removal. No purple/violet in the character's clothing or skin.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_zhou_wife.png"
    },
    "prologue_li_zheng": {
        "prompt": """Generate a character portrait illustration in Chinese ink wash painting style (semi-realistic, anime-influenced Chinese historical art style).

Character: A Chinese man in his mid-50s. He is a village headman/local official (里正) in the Ming Dynasty (around 1594). A petty bureaucrat in a small river ferry town.

Appearance: Slightly chubby round face with a perpetual ingratiating smile. Small eyes that are calculating behind the friendly facade. Thinning hair under a small black cap (小帽). Clean-shaven. Soft hands (not a laborer).

Clothing: Dark indigo/navy long robe (长衫) of decent quality but not luxurious. A cloth waist sash. The clothes say "I'm respectable but not wealthy."

Expression: An obsequious smile, slightly bowing - the look of a man who knows how to please authority while protecting his own interests.

Background: SOLID BRIGHT PURPLE background (#9B30FF or similar vivid purple). The background must be a FLAT UNIFORM SOLID COLOR with NO gradients, NO patterns, NO objects. The character must NOT contain any purple elements in their design.

Pose: BUST PORTRAIT (from chest/shoulders up to top of head ONLY, NO waist, NO hands, NO lower body visible). Head slightly bowed with ingratiating expression, looking up at viewer.

Art style: Chinese historical ink wash with subtle anime influence. Dark navy/indigo tones for the CHARACTER. Ming Dynasty period. Ensure correct body proportions and natural pose.

CRITICAL: The background MUST be a solid flat purple color for chroma-key removal. No purple/violet in the character's clothing or skin.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_li_zheng.png"
    },
    "prologue_fisherman_wang": {
        "prompt": """Generate a character portrait illustration in Chinese ink wash painting style (semi-realistic, anime-influenced Chinese historical art style).

Character: A Chinese man in his mid-60s. He is an old fisherman (打渔老翁) in the Ming Dynasty (around 1594). Has lived on the Yangtze River his entire life.

Appearance: Very thin and slightly hunched. A face deeply creased and weathered like old leather - every wrinkle tells a story of decades on the river. Wispy white beard and eyebrows. Keen, bright eyes that miss nothing despite his age. Bony hands with prominent veins.

Clothing: A worn straw rain cape (蓑衣) draped over shoulders, or a faded short brown hemp jacket. Simple cloth wrapped around his head.

Expression: Calm and knowing. The look of an old man who has seen everything and fears nothing. A slight frown of someone who witnessed something wrong and intends to speak up.

Background: SOLID BRIGHT PURPLE background (#9B30FF or similar vivid purple). The background must be a FLAT UNIFORM SOLID COLOR with NO gradients, NO patterns, NO objects. The character must NOT contain any purple elements in their design.

Pose: BUST PORTRAIT (from chest/shoulders up to top of head ONLY, NO waist, NO hands, NO lower body visible). Head slightly tilted as if assessing you, keen eyes staring directly.

Art style: Chinese historical ink wash with subtle anime influence. Faded earth tones and grays for the CHARACTER. Ming Dynasty period. Ensure correct body proportions and natural pose.

CRITICAL: The background MUST be a solid flat purple color for chroma-key removal. No purple/violet in the character's clothing or skin.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_fisherman_wang.png"
    }
}


# ============================================================
# Phase 2: 场景背景
# ============================================================

SCENE_PROMPTS = {
    "prologue_ferry_inn": {
        "prompt": """Generate a wide landscape scene illustration in Chinese ink wash painting style (atmospheric, semi-realistic).

Scene: The INTERIOR of a shabby riverside inn in a small ferry town along the Yangtze River, Ming Dynasty China (around 1594). Winter evening.

Details:
- A single large main room serving as both lobby and common room. Rough wooden pillars, mud/plaster walls with visible cracks
- Several rough wooden tables and benches scattered around. One table in the center-left has papers/scrolls spread on it
- A clay stove in the back-left corner with dim orange glow. A few travelers huddle nearby (small silhouettes, not detailed)
- A clothesline/rope strung across the LEFT wall with a few garments hanging to dry — one rough cotton outer robe, one lighter under-garment
- An open doorway in the back-right showing a small private room beyond, with a bed and a bundled bag/pack visible on it
- A wooden counter near the right side where an innkeeper stands (small figure, back turned)
- The front entrance door is visible in the center background, rain visible through the gap, warm amber light spilling in
- Muddy floor with scattered straw mats
- Rain pouring outside, visible through windows and doorway

CRITICAL: The hanging clothes on the LEFT wall must be clearly visible. The table with papers must be in the CENTER-LEFT area. The doorway to the back room with the bed and bag must be in the BACK-RIGHT. These are interactive search points for the player.

Atmosphere: Heavy winter rain outside, warm amber light inside from oil lamps and stove fire. Cozy but shabby. Cold blue-gray outside visible through openings, warm brown/amber inside. Muted tones.

Art style: Chinese ink wash painting with slight modern rendering. Cinematic wide shot composition. 16:9 landscape format.

No close-up faces. Any people are small background silhouettes.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_ferry_inn.png"
    },
    "prologue_ferry_dock": {
        "prompt": """Generate a wide landscape scene illustration in Chinese ink wash painting style (atmospheric, semi-realistic).

Scene: A small river ferry dock on the Yangtze River during heavy rain. Ming Dynasty China, winter, daytime but very overcast.

Details:
- A wooden dock/wharf extending into murky yellow-brown river water
- Several small wooden boats (乌篷船) moored crookedly at the dock
- One wrecked/overturned boat dragged onto the muddy bank, hull facing up
- Coiled ropes, bamboo poles, and scattered cargo debris on the dock
- Rain coming down in sheets, creating a curtain effect
- The river is wide and turbulent, waves choppy
- A few simple wooden structures (sheds/shelters) along the bank

Atmosphere: Ominous, heavy rain, murky water. The overturned boat is the visual focal point suggesting something terrible happened. Cold gray-blue palette with brown river tones.

Art style: Chinese ink wash painting with atmospheric depth. Cinematic 16:9 landscape.

No characters in the scene.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_ferry_dock.png"
    },
    "prologue_wreck_site": {
        "prompt": """Generate a wide landscape scene illustration in Chinese ink wash painting style (atmospheric, semi-realistic).

Scene: A shipwreck site among river rocks downstream on the Yangtze River. Ming Dynasty China, winter, overcast day.

Details:
- Large dark rocks jutting out of the water, forming a reef/rapid area
- Half a wooden boat hull wedged between two large boulders, hull cracked open
- Scattered wooden debris, broken planks, and waterlogged fabric floating nearby
- The river swirls around the rocks, white foam where water hits stone
- Mist/spray rising from the turbulent water
- Distant riverbank barely visible through the haze
- A somber, crime-scene atmosphere

Atmosphere: Cold, desolate, slightly eerie. The wrecked boat tells a story of violence. Muted grays, dark browns, white water foam. The kind of place where bad things happen and no one sees.

Art style: Chinese ink wash painting, dramatic composition focusing on the wreck. Cinematic 16:9 landscape.

No characters in the scene.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_wreck_site.png"
    },
    "prologue_river_bend": {
        "prompt": """Generate a wide landscape scene illustration in Chinese ink wash painting style (atmospheric, semi-realistic).

Scene: A small fishing village in a river bend along the Yangtze River. Ming Dynasty China, early winter morning, thin mist.

Details:
- 4-5 small thatched-roof cottages (茅屋) scattered along the riverbank
- Fishing nets hung on bamboo poles to dry
- A small wooden pier/jetty with a tiny sampan tied to it
- Thin morning mist rising from the calm river surface
- Distant green-gray mountains faintly visible through the mist
- A bare willow tree near the water's edge
- Overall feeling: quiet, isolated, peaceful but slightly melancholic

Atmosphere: Dawn/early morning with soft diffused light. Thin white mist over water. Muted blue-green-gray palette. Peaceful contrast to the violent scenes of the main investigation areas.

Art style: Classic Chinese ink wash painting (水墨画) style. Ethereal, atmospheric. Cinematic 16:9 landscape.

No characters in the scene.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_river_bend.png"
    },
    "prologue_cold_open": {
        "prompt": """Generate a wide landscape scene illustration in Chinese ink wash painting style (atmospheric, dramatic, semi-realistic).

Scene: A river ferry dock at dawn during a violent rainstorm. Ming Dynasty China, winter. This is a CRIME SCENE / dramatic opening shot.

Details:
- Pre-dawn darkness giving way to the faintest gray light on the horizon
- TORRENTIAL rain, almost like a wall of water
- A muddy riverbank with a body lying FACE DOWN at the water's edge, half submerged in murky yellow-brown water. The body wears a soaked cotton robe.
- A circle of dark silhouettes (villagers) standing at a distance, no one approaching
- The wide river behind, turbulent and angry
- A few dock structures barely visible through the rain
- Lightning illuminating the scene intermittently

Atmosphere: DRAMATIC, OMINOUS, SHOCKING. This is the first thing the player sees - it needs to hit hard. Near-black tones with cold blue-gray, the body as the focal point of horror. Rain dominates everything.

Art style: Chinese ink wash painting but with dramatic cinematic lighting. Very dark and moody. 16:9 landscape.

No close-up faces visible (silhouettes only for standing figures, body face-down).

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "prologue_cold_open.png"
    },
    "xunyang_approach": {
        "prompt": """Generate a wide landscape scene illustration in Chinese ink wash painting style (atmospheric, semi-realistic).

Scene: A boat traveling on the Yangtze River in early spring, approaching a famous riverside pavilion tower. Ming Dynasty China.

Details:
- A small wooden boat (乌篷船) in the foreground, viewed from a slight distance, drifting downstream on calm water
- The boat has a small canopy, a single boatman silhouette at the rear with a pole
- In the distance (center-right of frame), the silhouette of a grand three-story wooden pavilion tower with upturned eaves rises above the mist — this is Xunyang Pavilion (浔阳楼)
- The river is wide and calm, reflecting the soft light
- Thin mist lingering on the water surface, beginning to clear
- Early spring: willow trees along the far bank just starting to show pale green buds
- A few fishing boats scattered in the middle distance
- Sky: overcast but brightening, with breaks in the clouds showing pale golden light — winter is over, spring is beginning

Atmosphere: Transitional, hopeful. The dark winter rain of the previous case is behind us. Soft spring light breaking through mist. Quiet journey, anticipation of arrival. Muted blue-green palette with warm golden highlights where the sun breaks through.

Art style: Chinese ink wash painting, ethereal and atmospheric. Cinematic 16:9 landscape format.

No close-up faces. Figures are small silhouettes.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "xunyang_approach.png"
    },
    "linchuan_approach": {
        "prompt": """Generate a wide landscape scene illustration in Chinese ink wash painting style (atmospheric, semi-realistic).

Scene: A boat approaching a small riverside town in autumn rain at dusk. Ming Dynasty China.

Details:
- A small wooden boat (乌篷船) in the center-foreground, seen from above/behind, heading toward the town
- Rain falling steadily — visible rain streaks, ripples on the dark water
- The town ahead: modest wooden buildings with gray tile roofs huddled along the riverbank, a stone arch bridge connecting two sides
- A post station (驿站) building visible — low, sturdy, with a red lantern glowing faintly at the entrance
- Autumn trees with orange-red-yellow leaves along the bank, some leaves falling into the water
- Dusk sky: dark gray-blue clouds heavy with rain, last traces of amber sunset on the far horizon
- The river is narrower here than the Yangtze — this is a tributary or canal approaching Linchuan town
- A few scattered lights in the town windows — warm amber dots in the gray-blue gloom

Atmosphere: Ominous transition. The brightness of the Xunyang case is gone — autumn rain has returned. A sense of entering darker territory. The warm lights of the town are small comfort against the encroaching dark. Muted gray-blue-amber palette. Rain and gathering darkness.

Art style: Chinese ink wash painting with cinematic mood lighting. 16:9 landscape format.

No close-up faces. Figures are small silhouettes.

IMPORTANT: Generate an image, do not just describe it.""",
        "output": "linchuan_approach.png"
    }
}


# ============================================================
# Phase 3: 过场 CG (img2img)
# ============================================================

def get_cg_prompts():
    """过场CG需要在立绘生成后才能确定参考图路径"""
    lu_zhao = PORTRAITS_DIR / "lu_zhao.png"
    lingyao = PORTRAITS_DIR / "companion_lingyao_v10.png"
    zhou_wife = PORTRAITS_DIR / "prologue_zhou_wife.png"
    
    return {
        "prologue_cg_zhou_kneel": {
            "references": [(zhou_wife, "image/png"), (lu_zhao, "image/png")],
            "prompt": """Based on these character reference images, generate a WIDE LANDSCAPE scene illustration in Chinese ink wash painting style.

Scene: A dramatic moment in heavy rain at a riverside dock. Ming Dynasty China, winter dawn.

The first reference character (woman in white mourning clothes) is KNEELING in the mud, desperately grabbing the hem/ankle of the second reference character (young man in dark navy blue official robes). Her face is tear-streaked, desperate, looking up at him pleadingly. 

He stands upright in the rain, looking down at her with a serious/compassionate expression. Behind them, a body is visible at the water's edge (blurred/background).

Rain pours down on both of them. Mud splashes. Other villagers watch from a distance as dark silhouettes.

CRITICAL: Keep both characters' clothing and appearance EXACTLY matching their reference images. The woman wears white mourning garments. The man wears dark navy official robes.

CRITICAL: LANDSCAPE 16:9 format. Cinematic dramatic composition.

Art style: Chinese ink wash, dramatic lighting, cold blue-gray rain tones.

IMPORTANT: Generate an image, do not just describe it.""",
            "output": "prologue_cg_zhou_kneel.png"
        },
        "prologue_cg_lingyao_rush": {
            "references": [(lingyao, "image/png")],
            "prompt": """Based on this character reference image, generate a WIDE LANDSCAPE scene illustration in Chinese ink wash painting style.

Scene: The character from the reference (young woman in dark slate blue/navy gray martial arts outfit with white trim, high ponytail, arm guards) is PUSHING through a crowd of people in heavy rain. She is running/rushing forward, one arm extended pushing people aside, the other arm pumping as she runs.

She is soaking wet - hair plastered to her face, clothes drenched. Her expression is urgent and excited - she has important information and is racing to deliver it. Mouth slightly open as if shouting.

Background: Blurred crowd of villagers in rain wearing straw rain capes (蓑衣) and bamboo conical hats (斗笠) — NO modern umbrellas, NO western-style umbrellas. A dock/waterfront setting barely visible through the downpour. Dawn light.

Dynamic action pose - motion blur on the crowd, sharp focus on her. Rain streaks across the frame.

CRITICAL: Do NOT include any modern umbrellas. Villagers use traditional straw capes and bamboo hats for rain protection only.

CRITICAL: Keep her clothing EXACTLY matching the reference - dark slate blue/navy gray top with white/silver trim, dark belt, leather arm guards, brown utility pouch.

CRITICAL: LANDSCAPE 16:9 format. Dynamic cinematic composition.

Art style: Chinese ink wash with action energy. Cold rain tones with her as warm focal point.

IMPORTANT: Generate an image, do not just describe it.""",
            "output": "prologue_cg_lingyao_rush.png"
        },
        "prologue_cg_letter": {
            "references": [(lingyao, "image/png"), (lu_zhao, "image/png")],
            "prompt": """Based on these character reference images, generate a WIDE LANDSCAPE scene illustration in Chinese ink wash painting style.

Scene: After the rain has stopped. A quiet, misty moment at the river's edge near a shipwreck. Ming Dynasty China, winter.

The first reference character (young woman in dark slate blue martial outfit) is crouching beside wooden debris from a wrecked boat, pointing toward a small unmarked soaked oil-paper packet partly hidden under a broken plank. The clue is tiny, mostly obscured, and not readable. She does NOT hold any document.

The second reference character (young man in dark navy official robes) stands behind her, leaning forward slightly to examine the hidden clue. His expression is sharp and focused.

Background: Scattered shipwreck debris, calm misty river, clouds parting slightly to show gray sky. The atmosphere has shifted from tense/rainy to quiet/mysterious.

The clue must be an unmarked blank wet packet or folded scrap, face down, mostly covered by mud and wood. It has NO visible writing surface.

CRITICAL: Do NOT show a front-facing paper sheet. Do NOT put any paper or envelope in a character's hands. Do NOT render any text, writing, Chinese characters, calligraphy, seals, stamps, or markings anywhere in the image.

CRITICAL: Keep both characters' appearances EXACTLY matching their references.

CRITICAL: LANDSCAPE 16:9 format. Quiet, atmospheric composition.

Art style: Chinese ink wash, misty/ethereal mood. The tone shifts from investigation to mystery/foreshadowing.

IMPORTANT: Generate an image, do not just describe it.""",
            "output": "prologue_cg_letter.png"
        }
    }


def run_phase_portraits():
    """Phase 1: 生成 NPC 立绘"""
    print("\n" + "=" * 60)
    print("Phase 1: NPC 角色立绘（5人）")
    print("=" * 60)
    
    results = []
    for i, (key, data) in enumerate(PORTRAIT_PROMPTS.items()):
        print(f"\n[{i+1}/5] 生成: {key}")
        print("-" * 40)
        output_path = PORTRAITS_DIR / data["output"]
        
        if output_path.exists():
            print(f"  [SKIP] 已存在: {output_path}")
            results.append(True)
            continue
        
        success = generate_image(
            prompt=data["prompt"],
            output_path=output_path,
            aspect_ratio="3:4"  # 立绘用竖版
        )
        results.append(success)
        
        if i < len(PORTRAIT_PROMPTS) - 1:
            print(f"  等待 {COOLDOWN}s...")
            time.sleep(COOLDOWN)
    
    print(f"\n立绘完成: {sum(results)}/{len(results)} 成功")
    return all(results)


def run_phase_scenes():
    """Phase 2: 生成场景背景"""
    print("\n" + "=" * 60)
    print("Phase 2: 场景背景（7张）")
    print("=" * 60)
    
    results = []
    for i, (key, data) in enumerate(SCENE_PROMPTS.items()):
        print(f"\n[{i+1}/5] 生成: {key}")
        print("-" * 40)
        output_path = SCENES_DIR / data["output"]
        
        if output_path.exists():
            print(f"  [SKIP] 已存在: {output_path}")
            results.append(True)
            continue
        
        success = generate_image(
            prompt=data["prompt"] + STYLE_LOCK,
            output_path=output_path,
            reference_images=STYLE_REFERENCE_IMAGES,
            aspect_ratio="16:9"
        )
        results.append(success)
        
        if i < len(SCENE_PROMPTS) - 1:
            print(f"  等待 {COOLDOWN}s...")
            time.sleep(COOLDOWN)
    
    print(f"\n场景完成: {sum(results)}/{len(results)} 成功")
    return all(results)


def run_phase_cg():
    """Phase 3: 生成过场 CG (img2img)"""
    print("\n" + "=" * 60)
    print("Phase 3: 过场 CG（3张，img2img）")
    print("=" * 60)
    
    cg_prompts = get_cg_prompts()
    results = []
    
    for i, (key, data) in enumerate(cg_prompts.items()):
        print(f"\n[{i+1}/3] 生成: {key}")
        print("-" * 40)
        output_path = SCENES_DIR / data["output"]
        
        if output_path.exists():
            print(f"  [SKIP] 已存在: {output_path}")
            results.append(True)
            continue
        
        # 检查参考图是否都存在
        missing = [str(p) for p, _ in data["references"] if not p.exists()]
        if missing:
            print(f"  [WARN] 缺少参考图: {missing}")
            print(f"  [SKIP] 需要先完成 Phase 1 的立绘生成")
            results.append(False)
            continue
        
        success = generate_image(
            prompt=data["prompt"] + STYLE_LOCK,
            output_path=output_path,
            reference_images=STYLE_REFERENCE_IMAGES + data["references"],
            aspect_ratio="16:9"
        )
        results.append(success)
        
        if i < len(cg_prompts) - 1:
            print(f"  等待 {COOLDOWN}s...")
            time.sleep(COOLDOWN)
    
    print(f"\nCG完成: {sum(results)}/{len(results)} 成功")
    return all(results)


def main():
    parser = argparse.ArgumentParser(description="序章「渡口沉舟」美术生成器")
    parser.add_argument("--phase", choices=["portraits", "scenes", "cg", "all"], default="all",
                        help="指定生成阶段: portraits/scenes/cg/all")
    parser.add_argument("--force", action="store_true",
                        help="强制重新生成已存在的文件")
    args = parser.parse_args()
    
    print("=" * 60)
    print("序章「渡口沉舟」美术资产生成器")
    print("=" * 60)
    print(f"模式: {args.phase}")
    print(f"强制重新生成: {args.force}")
    print(f"立绘输出: {PORTRAITS_DIR}")
    print(f"场景输出: {SCENES_DIR}")
    print()
    
    if args.force:
        # 如果强制模式，删除已有文件让其重新生成
        print("[FORCE] 将覆盖已有文件")
    
    if args.phase in ("portraits", "all"):
        run_phase_portraits()
    
    if args.phase in ("scenes", "all"):
        run_phase_scenes()
    
    if args.phase in ("cg", "all"):
        run_phase_cg()
    
    print("\n" + "=" * 60)
    print("全部完成！")
    print("=" * 60)


if __name__ == "__main__":
    main()
