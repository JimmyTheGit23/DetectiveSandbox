"""
NPC Portrait Generator for 序章渡口沉舟 (Prologue Ferry Case)
Uses Gemini 2.5 Flash Image API with image-to-image for style consistency.
"""

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
API_KEY = "AIzaSyDcYbFROXhHKHVS42ucJXQ6cHt8XpcA4pg"
MODEL = "gemini-2.5-flash-image"
OUTPUT_DIR = Path(r"E:/godot/DetectiveSandbox/detective/assets/cn/portraits")
REFERENCE_DIR = OUTPUT_DIR

# Style reference images (existing portraits for consistency)
STYLE_REFS = [
    REFERENCE_DIR / "prologue_lu_zhao.png",
    REFERENCE_DIR / "lu_zhao.png",
]

client = genai.Client(api_key=API_KEY)

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
            "collapsed": "on knees, head bowed, hands on ground, completely broken look, defeated",
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
        "description": "A 35-year-old Chinese woman (merchant's wife) from the Ming Dynasty era. Disheveled long black hair falling over face, white mourning robe. Pretty face contorted with grief. Tear stains on cheeks. Semi-realistic anime illustration style (半写实古风插画).",
        "emotions": {
            "base": "grief-stricken expression, tears on face, clutching at own robe",
            "screaming": "mouth wide open screaming, hair wild, hands reaching out aggressively, rage and grief",
            "trembling": "arms wrapped around self, lips trembling, eyes unfocused, shaking",
            "silent": "head bowed, long hair covering face, still and quiet, hollow exhausted look",
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

    prompt_parts = []

    # Add style reference
    if ref_images:
        prompt_parts.append(_image_to_part(ref_images[0]))

    # Add base portrait as reference for emotion variants
    if base_image and emotion_key != "base":
        prompt_parts.append(_image_to_part(base_image))

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

The character is the SAME person as the reference portrait provided. Keep the EXACT same face shape, hairstyle, clothing, and body proportions.

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


def process_character(char_id, char_data, ref_images):
    """Generate all portraits for a character."""
    print(f"\n{'='*60}")
    print(f"  CHARACTER: {char_data['name']} ({char_id})")
    print(f"{'='*60}")

    base_image = None

    for emotion_key, emotion_desc in char_data["emotions"].items():
        suffix = "" if emotion_key == "base" else f"_{emotion_key}"
        filename = f"prologue_{char_id}{suffix}.png"
        greenscreen_filename = f"prologue_{char_id}{suffix}_greenscreen.png"
        output_path = OUTPUT_DIR / filename
        greenscreen_path = OUTPUT_DIR / greenscreen_filename

        # Skip if already exists
        if output_path.exists():
            print(f"\n  [{emotion_key}] Already exists: {filename}, skipping")
            if emotion_key == "base":
                base_image = Image.open(output_path)
            continue

        print(f"\n  [{emotion_key}] Generating: {filename}")
        print(f"    Prompt: {emotion_desc[:60]}...")

        # Generate
        raw_img = generate_portrait(char_id, char_data, emotion_key, emotion_desc, ref_images, base_image)
        if raw_img is None:
            print(f"    FAILED generation, skipping")
            continue

        # Save greenscreen version
        raw_img.save(greenscreen_path)
        print(f"    Saved greenscreen: {greenscreen_filename}")

        # Remove background
        print(f"    Removing background...")
        nobg = remove_background(raw_img)

        # Despill
        print(f"    Running green despill...")
        final = despill_green(nobg)

        # Verify
        passed, sg, gd = verify_despill(final)
        status_str = "PASS" if passed else "WARN"
        print(f"    Verification: strong_green={sg}, green_in_dark={gd} [{status_str}]")

        # Save final
        final.save(output_path)
        print(f"    DONE: {filename}")

        # Store base for emotion variants
        if emotion_key == "base":
            base_image = raw_img  # Use greenscreen version as reference

        # Rate limiting
        time.sleep(3)

    return True


def main():
    print("NPC Portrait Generator - 序章渡口沉舟")
    print("="*60)

    # Load references
    print("\nLoading style references...")
    ref_images = load_reference_images()
    if not ref_images:
        print("WARNING: No reference images found!")

    # Process each character
    results = {}
    for char_id, char_data in CHARACTERS.items():
        try:
            success = process_character(char_id, char_data, ref_images)
            results[char_id] = success
        except Exception as e:
            print(f"  ERROR processing {char_id}: {e}")
            results[char_id] = False

    # Summary
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
