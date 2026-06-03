"""
NPC Portrait Generator for 序章渡口沉舟 (Prologue Ferry Case)
Uses Gemini 2.5 Flash Image API with image-to-image for style consistency.
"""

import argparse
import os
import time
import base64
import struct
from pathlib import Path
from io import BytesIO

from google import genai
from google.genai import types
from PIL import Image
import numpy as np
from rembg import remove
from scipy.ndimage import binary_erosion

# ─── Config ───
PROJECT_ROOT = Path(__file__).resolve().parent.parent
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"
OUTPUT_DIR = PROJECT_ROOT / "assets" / "cn" / "portraits"
RAW_DIR = PROJECT_ROOT / "assets" / "ai_raw" / "portraits"
REFERENCE_DIR = OUTPUT_DIR

# Style reference images (existing portraits for consistency)
STYLE_REFS = [
    REFERENCE_DIR / "prologue_lu_zhao.png",
    REFERENCE_DIR / "lu_zhao.png",
]

client = genai.Client(api_key=API_KEY) if API_KEY else None

# ─── Character Definitions ───
CHARACTERS = {
    "li_zheng": {
        "name": "钱里正",
        "description": "A 55-year-old Chinese local official (里正) from the Ming Dynasty era. Round face, slightly overweight, shrewd calculating eyes, thin mustache and goatee. Wears a dark blue cotton official's robe with a black cloth cap. Smooth and worldly expression. Semi-realistic anime illustration style (半写实古风插画).",
        "emotions": {
            "base": "neutral scheming expression, hands clasped in front, slight smirk",
            "nervous": "rubbing hands together nervously, forced smile, sweating slightly",
            "stern": "furrowed brows, arms crossed, scrutinizing gaze, suspicious look",
            "sighing": "eyes closed, exhaling, one hand touching forehead, weary expression",
            "shocked": "suddenly shocked expression, eyes wide, forced smile gone, mouth slightly open, hands frozen mid-gesture",
            "gossip": "leaning forward conspiratorially, one hand half-cupped near the side of his mouth as if whispering, eyes glancing sideways with a sly knowing look, shoulders slightly hunched, eager rumor-mongering smirk on his lips",
            "evasive": "head turned slightly away, eyes looking sideways at the floor avoiding direct contact, one hand rubbing his temple or the back of his neck, mouth corners pressed down in a non-committal grimace, body language of someone deflecting blame",
        }
    },
    "agui": {
        "name": "阿贵",
        "description": "A 25-year-old Chinese male servant from the Ming Dynasty era. Thin build, plain gray cotton robe, round honest face, slightly sunken eyes from crying. Looks timid and exhausted. Semi-realistic anime illustration style (半写实古风插画).",
        "emotions": {
            "base": "timid expression, eyes slightly red from crying, hunched posture",
            "crying": "tears streaming down face, mouth trembling, hands clutching at robe, sobbing",
            "nervous": "eyes darting to the side, hands clenched into fists, tense shoulders, sweating",
            "shocked": "wide eyes, mouth slightly open, frozen mid-gesture, stunned expression",
            "broken": "utterly defeated expression, shoulders collapsed forward, tear-streaked face, hollow eyes, hands clutching robe, guilt and despair",
            "collapsed": "on knees, head bowed, hands on ground, completely broken look, defeated",
        }
    },
    "lu_zhao": {
        "name": "陆昭",
        "file_prefix": "prologue_lu_zhao",
        "description": "A young Ming Dynasty Chinese male detective protagonist in simple pale travel robes, upright scholar-official bearing, black hair tied in a neat topknot. Semi-realistic ancient Chinese detective game portrait style.",
        "emotions": {
            "nervous": "subtle nervous expression, brows slightly tense, lips pressed, one hand half-raised as if thinking under pressure; still composed and dignified",
        }
    },
    "xia_lingyao": {
        "name": "凌瑶",
        "file_prefix": "companion_lingyao",
        "description": "A spirited young Ming Dynasty Chinese female companion, agile courier and detective assistant, wearing blue-gray practical martial traveler clothing with long dark hair. Semi-realistic ancient Chinese detective game portrait style.",
        "emotions": {
            "embarrassed": "embarrassed comedic expression, cheeks slightly flushed, awkward smile, eyes averted, one hand scratching cheek; still clearly the same energetic companion",
        }
    },
    "lao_fan": {
        "name": "老范",
        "description": "A 50-year-old Chinese boatman/ferryman from the Ming Dynasty era. Very dark sun-weathered skin, wiry thin build, calloused hands. Wears worn brown hemp clothing, short messy hair. A long bamboo smoking pipe in hand. Tough and seasoned appearance. Semi-realistic anime illustration style (半写实古风插画).",
        "emotions": {
            "base": "squinting eyes, smoking pipe held to lips, weather-beaten calm expression",
            "sneering": "one corner of mouth raised in contempt, eyes narrowed dismissively, pipe lowered",
            "frozen": "pipe fallen from lips, eyes wide, entire body rigid with shock, pale face",
            "collapsed": "sitting on ground, head in hands, pipe dropped beside him, shaking, defeated",
        }
    },
    "zhou_wife": {
        "name": "周氏",
        "description": "A 35-year-old Chinese woman (merchant's wife) from the Ming Dynasty era. Oval face with slightly prominent cheekbones suggesting strong will. Almond-shaped eyes with downturned outer corners giving a perpetual look of sorrow, but sharp and shrewd pupils revealing her merchant's acumen. Willow-leaf eyebrows with a deep furrow between them from constant worry. Straight nose with slightly wide nostrils suggesting good fortune. Thin lips with corners turned down, hinting at both bitterness and grief. Fair skin with a small mole below her left eye (tear mole) and faint freckles across the bridge of her nose. Hair parted in the middle, pulled back in a simple bun with a few loose strands framing her face, held by a plain wooden hairpin. White mourning robe with round collar. Semi-realistic anime illustration style (半写实古风插画).",
        "emotions": {
            "base": "grief-stricken expression, tears on face, clutching at own robe, eyes red from crying but sharp with suspicion",
            "screaming": "mouth wide open screaming, hair wild, hands reaching out aggressively, rage and grief, tear mole visible on left cheek",
            "trembling": "arms wrapped around self, lips trembling, eyes unfocused, shaking, tear mole accentuating her sorrow",
            "silent": "head bowed, long hair covering face, still and quiet, hollow exhausted look, tear mole visible through hair strands",
            "accusing": "finger pointing accusingly, eyes blazing with anger and grief, mouth set in a firm line of accusation, tear mole prominent on left cheek, posture rigid with righteous fury",
            "suspicious": "eyes narrowed with suspicion, head tilted slightly, one eyebrow raised, lips pressed together in a thin line of doubt, tear mole visible as she studies someone intently",
            "interrogating": "leaning forward aggressively, eyes sharp and piercing, mouth open mid-question, hands gesturing emphatically, tear mole accentuating her intense focused expression",
            "relieved": "softened expression, eyes still red but with a glimmer of peace, lips slightly parted in a sigh of relief, tear mole visible as tension leaves her face, shoulders relaxing"
        }
    },
    "fisherman_wang": {
        "name": "王大爷",
        "description": "A 65-year-old Chinese fisherman from the Ming Dynasty era. Deeply wrinkled dark skin, white sparse beard, bald on top with side hair. Wears ragged brown vest over bare chest, very thin and sinewy. Sits mending a fishing net. Semi-realistic anime illustration style (半写实古风插画).",
        "emotions": {
            "base": "cautious sideways glance, weathered calm face, hands working on net",
            "evasive": "looking away, mouth shut tight, slightly hunched as if wanting to hide something",
        }
    },
    "shen_qingyue": {
        "name": "沈清月",
        "description": "A 22-year-old Chinese young woman from the Ming Dynasty era, daughter of a herbal-medicine merchant in Xunyang. She wears MALE attire — a dark indigo or blue-green scholar's straight robe (青色直裰) with a cloth belt at the waist; her long jet-black hair is tied back high in a tight topknot or single high tail (NOT a court hairpin, NOT female updo). Tall and lean build, sharp intelligent almond eyes, well-defined eyebrows, striking handsome bearing (英气逼人). Despite the male clothes she is clearly a young woman — slender neck, softer jawline. She is the secret culprit who hides ruthless calculation behind a brisk merchant facade. Same semi-realistic Chinese historical anime illustration style as the reference (半写实古风插画), clean linework, soft shading.",
        "emotions": {
            "base": "composed half-smile, arms loosely crossed, calm sharp gaze with a hint of mockery",
            "bold": "confident swaggering merchant pose, arms crossed firmly in front of chest, chin slightly lifted, one eyebrow arched, a brisk fearless half-smile, weight on one leg — the very picture of a sharp-tongued young debt collector who is unafraid of officials",
            "cooperative": "relaxed cooperative posture, one hand extending a folded paper IOU forward as if handing evidence over, the other hand open at her side, gentle disarming smile, eyes meeting the viewer openly — performing the role of a reasonable witness",
            "sharp": "narrowed piercing eyes, one eyebrow raised aggressively, mouth pressed into a thin sharp line about to snap back a retort, head tilted slightly with a needle-sharp accusatory expression, body subtly tense",
            "deflecting": "head turned three-quarters away, eyes glancing aside avoiding the viewer, one hand unconsciously gripping the opposite elbow tightly (white-knuckled), mouth slightly pursed, a forced casual smile that does not reach the eyes — the body language of someone hiding something",
            "cold_fury": "an unsettling, icy smile of grudging admiration — the mask has just cracked. Eyes are dead cold and steady, no warmth, lips curved up in a small precise smile but with absolutely no kindness, head slightly lowered while still staring forward from beneath the brows, arms now lowered to her sides with hands relaxed and open in a quietly dangerous way — this is the real Shen Qingyue revealed, the killer beneath the merchant disguise",
            "confrontation": "courtroom confrontation pose under harsh dramatic lighting, standing tall and defiant facing forward, one hand placed firmly on the courtroom rail or table in front of her, the other balled into a fist at her side, eyes locked forward in cold focused glare, jaw set, dramatic high-contrast shadow under her chin — Ace-Attorney-style cornered-suspect base pose, ready to be pressed",
        }
    },
}


def load_reference_images():
    """Load style reference images for consistency."""
    refs = []
    for path in STYLE_REFS:
        if path.exists():
            img = Image.open(path)
            refs.append(img)
            print(f"  Loaded reference: {path.name}")
    return refs


def _image_to_part(img):
    """Convert PIL Image to Gemini API Part."""
    buf = BytesIO()
    img.save(buf, format='PNG')
    return types.Part.from_bytes(data=buf.getvalue(), mime_type='image/png')


def generate_portrait(char_id, char_data, emotion_key, emotion_desc, ref_images, base_image=None):
    """Generate a single portrait using Gemini API."""
    if client is None:
        raise RuntimeError("请先设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")

    prompt_parts = []

    # Existing-character variants must prioritize the character reference image.
    if base_image and emotion_key != "base":
        prompt_parts.append(_image_to_part(base_image))
    elif ref_images:
        prompt_parts.append(_image_to_part(ref_images[0]))

    # Build text prompt
    if emotion_key == "base":
        text_prompt = f"""Generate a character portrait illustration with these exact specifications:

CHARACTER: {char_data['description']}

POSE AND EXPRESSION: {emotion_desc}

COMPOSITION: 3/4 body portrait from head to knees. Character fills 85% of canvas height. Head near top, knees near bottom.

BACKGROUND: Solid pure green (#00FF00) background. NO other elements in background.

STYLE: Match the semi-realistic Chinese historical anime illustration style of the reference image. Clean linework, soft shading, consistent lighting (soft front-lit, slight rim light).

IMPORTANT: NO TEXT. NO CHARACTERS/WRITING anywhere in the image. Pure green background only."""
    else:
        text_prompt = f"""Generate an emotion variant of this character portrait.

The character is the SAME person as the reference portrait provided. Keep the EXACT same face shape, hairstyle, clothing (every garment, color, collar style, belt, hat/headwear), body proportions, social class, gender presentation, and overall identity. Do NOT change them into a different character, do NOT alter the clothing color, do NOT swap male attire for female attire or vice versa.

ONLY change the expression and gesture to: {emotion_desc}

CHARACTER: {char_data['description']}

COMPOSITION: Same 3/4 body portrait composition as the reference. Head to knees visible.

BACKGROUND: Solid pure green (#00FF00) background.

STYLE: Match the exact same art style as the reference images.

IMPORTANT: NO TEXT. NO CHARACTERS/WRITING anywhere. Same character, different emotion only."""

    prompt_parts.append(types.Part.from_text(text=text_prompt))

    # Call Gemini API with retries
    for attempt in range(4):
        try:
            response = client.models.generate_content(
                model=MODEL,
                contents=prompt_parts,
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE", "TEXT"],
                )
            )

            # Extract image from response
            for part in response.candidates[0].content.parts:
                if part.inline_data and part.inline_data.mime_type.startswith("image/"):
                    img_data = part.inline_data.data
                    img = Image.open(BytesIO(img_data))
                    return img

            print(f"    WARNING: No image in response for {char_id}/{emotion_key}")
            return None

        except Exception as e:
            wait_time = 15 * (attempt + 1)
            print(f"    Attempt {attempt+1} failed: {e}")
            if attempt < 3:
                print(f"    Retrying in {wait_time}s...")
                time.sleep(wait_time)
            else:
                print(f"    FAILED after 4 attempts")
                return None

    return None


def remove_background(img):
    """Remove green background using rembg."""
    img_rgba = img.convert("RGBA")
    result = remove(img_rgba)
    return result


def despill_green(img):
    """5-pass green despill algorithm (from CLAUDE.md)."""
    arr = np.array(img).astype(np.float32)
    if arr.shape[2] < 4:
        return img

    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    h, w = arr.shape[:2]

    # Pass 1: Remove very-green semi-transparent edge pixels
    semi_transparent = (a > 10) & (a < 240)
    very_green = (g > r + 40) & (g > b + 40)
    mask1 = semi_transparent & very_green
    a[mask1] = 0

    # Pass 2: In dark areas (hair), clamp G to max(R, B)
    dark_mask = (r < 100) & (b < 100) & (a > 0)
    green_tint = g > np.maximum(r, b)
    fix2 = dark_mask & green_tint
    g[fix2] = np.maximum(r[fix2], b[fix2])

    # Pass 3: Medium areas with green shift
    medium = (a > 0) & ~dark_mask
    green_shift = (g > r + 15) & (g > b + 15)
    fix3 = medium & green_shift
    g[fix3] = (r[fix3] + b[fix3]) / 2.0

    # Pass 4: Upper 1/3 (hairpin area) - aggressive green clamp
    upper_third = int(h / 3)
    upper_dark = (r[:upper_third] < 120) & (b[:upper_third] < 120) & (a[:upper_third] > 0)
    upper_green = g[:upper_third] > np.maximum(r[:upper_third], b[:upper_third])
    fix4 = upper_dark & upper_green
    g[:upper_third][fix4] = np.maximum(r[:upper_third][fix4], b[:upper_third][fix4])

    # Pass 5: Edge band detection - clamp G on edge pixels
    opaque = a > 128
    eroded = binary_erosion(opaque, iterations=2)
    edge_band = opaque & ~eroded
    edge_green = g > np.maximum(r, b)
    fix5 = edge_band & edge_green
    g[fix5] = np.maximum(r[fix5], b[fix5])

    arr[:,:,0] = np.clip(r, 0, 255)
    arr[:,:,1] = np.clip(g, 0, 255)
    arr[:,:,2] = np.clip(b, 0, 255)
    arr[:,:,3] = np.clip(a, 0, 255)

    return Image.fromarray(arr.astype(np.uint8), 'RGBA')


def fit_to_canvas(img, target_size):
    """Autocrop transparent pixels, scale into target canvas, bottom-center aligned."""
    if target_size is None:
        return img
    img = img.convert("RGBA")
    arr = np.array(img)
    alpha = arr[:, :, 3]
    nz = np.argwhere(alpha > 10)
    if nz.size:
        y0, x0 = nz.min(axis=0)
        y1, x1 = nz.max(axis=0)
        pad = 4
        x0 = max(0, x0 - pad)
        y0 = max(0, y0 - pad)
        x1 = min(arr.shape[1] - 1, x1 + pad)
        y1 = min(arr.shape[0] - 1, y1 + pad)
        img = img.crop((x0, y0, x1 + 1, y1 + 1))
    target_w, target_h = target_size
    scale = min(target_w / img.size[0], target_h / img.size[1])
    new_size = (max(1, int(img.size[0] * scale)), max(1, int(img.size[1] * scale)))
    resized = img.resize(new_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    canvas.paste(resized, ((target_w - new_size[0]) // 2, target_h - new_size[1]), resized)
    return canvas


def verify_despill(img):
    """Check green contamination levels."""
    arr = np.array(img).astype(np.float32)
    if arr.shape[2] < 4:
        return True, 0, 0
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    visible = a > 10
    strong_green = visible & (g > r + 25) & (g > b + 25)
    dark_area = visible & (r < 100) & (b < 100)
    green_in_dark = dark_area & (g > r + 10)
    sg_count = int(np.sum(strong_green))
    gd_count = int(np.sum(green_in_dark))
    passed = sg_count == 0 and gd_count < 100
    return passed, sg_count, gd_count


def process_character(char_id, char_data, ref_images, only_emotions=None, force=False):
    """Generate portraits for a character."""
    print(f"\n{'='*60}")
    print(f"  CHARACTER: {char_data['name']} ({char_id})")
    print(f"{'='*60}")

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    file_prefix = char_data.get("file_prefix", f"prologue_{char_id}")
    base_path = OUTPUT_DIR / f"{file_prefix}.png"
    base_image = Image.open(base_path) if base_path.exists() else None
    target_size = base_image.size if base_image is not None else None

    for emotion_key, emotion_desc in char_data["emotions"].items():
        if only_emotions and emotion_key not in only_emotions:
            continue
        suffix = "" if emotion_key == "base" else f"_{emotion_key}"
        filename = f"{file_prefix}{suffix}.png"
        greenscreen_filename = f"{file_prefix}{suffix}_greenscreen.png"
        output_path = OUTPUT_DIR / filename
        greenscreen_path = RAW_DIR / greenscreen_filename

        if output_path.exists() and not force:
            print(f"\n  [{emotion_key}] Already exists: {filename}, skipping")
            if emotion_key == "base":
                base_image = Image.open(output_path)
                target_size = base_image.size
            continue

        print(f"\n  [{emotion_key}] Generating: {filename}")
        print(f"    Prompt: {emotion_desc[:60]}...")

        raw_img = generate_portrait(char_id, char_data, emotion_key, emotion_desc, ref_images, base_image)
        if raw_img is None:
            print(f"    FAILED generation, skipping")
            continue

        raw_img.save(greenscreen_path)
        print(f"    Saved greenscreen draft: {greenscreen_path.relative_to(PROJECT_ROOT)}")

        print(f"    Removing background...")
        nobg = remove_background(raw_img)

        print(f"    Running green despill...")
        final = despill_green(nobg)
        final = fit_to_canvas(final, target_size)

        passed, sg, gd = verify_despill(final)
        status_str = "PASS" if passed else "WARN"
        print(f"    Verification: strong_green={sg}, green_in_dark={gd} [{status_str}]")

        final.save(output_path)
        print(f"    DONE: {filename}")

        if emotion_key == "base":
            base_image = raw_img
            target_size = output_path.size if hasattr(output_path, "size") else target_size

        time.sleep(3)

    return True


def main():
    parser = argparse.ArgumentParser(description="Generate prologue NPC portraits with Gemini img2img")
    parser.add_argument("--character", action="append", choices=sorted(CHARACTERS.keys()), help="Only generate this character; repeatable")
    parser.add_argument("--emotion", action="append", help="Only generate this emotion; repeatable")
    parser.add_argument("--force", action="store_true", help="Overwrite existing final portrait files")
    args = parser.parse_args()

    print("NPC Portrait Generator - 序章渡口沉舟")
    print("="*60)

    print("\nLoading style references...")
    ref_images = load_reference_images()
    if not ref_images:
        print("WARNING: No reference images found!")

    selected = args.character or list(CHARACTERS.keys())
    only_emotions = set(args.emotion or [])

    results = {}
    for char_id in selected:
        char_data = CHARACTERS[char_id]
        unknown = only_emotions - set(char_data["emotions"].keys())
        if unknown:
            print(f"  ERROR {char_id}: unknown emotion(s): {', '.join(sorted(unknown))}")
            results[char_id] = False
            continue
        try:
            success = process_character(char_id, char_data, ref_images, only_emotions, args.force)
            results[char_id] = success
        except Exception as e:
            print(f"  ERROR processing {char_id}: {e}")
            results[char_id] = False

    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    for char_id, success in results.items():
        name = CHARACTERS[char_id]["name"]
        status = "OK" if success else "FAIL"
        print(f"  [{status}] {name} ({char_id})")
    print(f"\nDone!")


if __name__ == "__main__":
    main()
