#!/usr/bin/env python3
"""
Gemini API - Character Animation Frame Generator
Uses image-to-image to:
1. Generate front-facing full-body character image from existing portrait
2. Generate blinking animation frames (eyes open / eyes half-closed / eyes closed)

Usage:
  python3 tools/gemini_anim_test.py
"""

import os
import sys
import base64
from pathlib import Path
from PIL import Image
from io import BytesIO
from google import genai
from google.genai import types

# ─── Configuration ───
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"

# Paths
PROJECT_ROOT = Path(__file__).parent.parent
PORTRAITS_DIR = PROJECT_ROOT / "assets" / "cn" / "portraits"
OUTPUT_DIR = PROJECT_ROOT / "assets" / "cn" / "portraits" / "anim_test"

# Test character
CHARACTER = "xiao_cui"
SOURCE_IMAGE = PORTRAITS_DIR / f"{CHARACTER}.png"


def setup_client():
    """Initialize Gemini client."""
    if not API_KEY:
        raise RuntimeError("请先设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
    client = genai.Client(api_key=API_KEY)
    return client


def load_image_as_part(image_path: Path) -> types.Part:
    """Load a local image file as a Gemini Part."""
    with open(image_path, "rb") as f:
        image_bytes = f.read()
    return types.Part.from_bytes(data=image_bytes, mime_type="image/png")


def save_generated_image(response, output_path: Path) -> bool:
    """Extract and save generated image from Gemini response."""
    for part in response.candidates[0].content.parts:
        if part.inline_data is not None:
            img_data = part.inline_data.data
            img = Image.open(BytesIO(img_data))
            # Convert to RGBA if needed
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            img.save(output_path)
            print(f"  Saved: {output_path} ({img.size[0]}x{img.size[1]})")
            return True
        elif hasattr(part, 'text') and part.text:
            print(f"  Text response: {part.text[:200]}")
    return False


def step1_generate_fullbody(client):
    """
    Step 1: Generate a front-facing full-body character image.
    Takes the existing portrait and asks Gemini to create a full-body version
    suitable for a visual novel / Ace Attorney style game.
    """
    print("\n" + "=" * 60)
    print("STEP 1: Generate Front-Facing Full-Body Character")
    print("=" * 60)
    print(f"  Source: {SOURCE_IMAGE}")

    image_part = load_image_as_part(SOURCE_IMAGE)

    prompt = """Based on this character portrait, generate a FULL-BODY front-facing version of the same character.

Requirements:
- Same character, same outfit, same art style (Chinese ancient costume, anime/illustration style)
- Full body visible from head to knees/feet
- Facing directly forward (front view, looking at the viewer)
- Standing pose with natural hand position (e.g., holding a fan, hands at sides)
- Transparent or simple dark background
- High quality illustration suitable for a visual novel game
- Keep the same face, hair style, accessories, and clothing details
- Resolution approximately 768x1024 or similar portrait orientation
- The character should be centered in the frame
- Style reference: Ace Attorney / Phoenix Wright character sprites

This is for a detective visual novel game set in ancient China. The character is a courtesan (花魁) named 小翠."""

    response = client.models.generate_content(
        model=MODEL,
        contents=[image_part, prompt],
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
        ),
    )

    output_path = OUTPUT_DIR / f"{CHARACTER}_fullbody.png"
    if save_generated_image(response, output_path):
        print("  [OK] Full-body image generated!")
        return output_path
    else:
        print("  [FAIL] No image in response")
        return None


def step2_generate_blink_frames(client, fullbody_path: Path):
    """
    Step 2: Generate blinking animation frames.
    Takes the full-body image and generates:
    - Frame 0: Eyes open (normal) - this is the base
    - Frame 1: Eyes half-closed
    - Frame 2: Eyes fully closed
    """
    print("\n" + "=" * 60)
    print("STEP 2: Generate Blinking Animation Frames")
    print("=" * 60)

    if fullbody_path is None or not fullbody_path.exists():
        # Fallback to source image
        fullbody_path = SOURCE_IMAGE
        print(f"  Using source image as fallback: {fullbody_path}")

    image_part = load_image_as_part(fullbody_path)

    # Frame 0: Eyes open (copy of the base)
    frame0_path = OUTPUT_DIR / f"{CHARACTER}_idle_0.png"
    if fullbody_path != frame0_path:
        img = Image.open(fullbody_path)
        img.save(frame0_path)
        print(f"  Frame 0 (eyes open): {frame0_path}")

    # Frame 1: Eyes closed
    prompt_closed = """Edit this character image to show the EXACT same character with their EYES FULLY CLOSED (blinking).

CRITICAL REQUIREMENTS:
- Keep EVERYTHING else EXACTLY the same: pose, clothing, hair, background, lighting, colors
- ONLY change the eyes to be fully closed (natural blink, not squinting)
- The eyelids should be gently closed as if mid-blink
- Same art style, same quality
- Do NOT change anything else about the image
- Output the full image, not just the face

This is one frame of a blinking animation for a visual novel game."""

    print("  Generating eyes-closed frame...")
    response_closed = client.models.generate_content(
        model=MODEL,
        contents=[image_part, prompt_closed],
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
        ),
    )

    frame1_path = OUTPUT_DIR / f"{CHARACTER}_idle_1.png"
    if save_generated_image(response_closed, frame1_path):
        print("  [OK] Eyes-closed frame generated!")
    else:
        print("  [FAIL] Could not generate eyes-closed frame")

    print("\n  Animation frames ready for Godot:")
    print(f"    idle_0: eyes open  -> {frame0_path.name}")
    print(f"    idle_1: eyes closed -> {frame1_path.name}")
    print("\n  Place these in the portraits folder and the game will auto-detect them!")


def main():
    print("=" * 60)
    print("  Gemini Animation Frame Generator")
    print("  Character: %s" % CHARACTER)
    print("=" * 60)

    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Check source exists
    if not SOURCE_IMAGE.exists():
        print(f"ERROR: Source image not found: {SOURCE_IMAGE}")
        sys.exit(1)

    print(f"  Source image: {SOURCE_IMAGE}")
    img = Image.open(SOURCE_IMAGE)
    print(f"  Dimensions: {img.size[0]}x{img.size[1]}")

    # Initialize client
    client = setup_client()
    print("  Gemini client initialized")

    # Step 1: Generate full-body image
    fullbody_path = step1_generate_fullbody(client)

    # Step 2: Generate blink frames
    step2_generate_blink_frames(client, fullbody_path)

    print("\n" + "=" * 60)
    print("  DONE!")
    print("=" * 60)
    print(f"\n  Output files in: {OUTPUT_DIR}")
    print("\n  To use in game, copy to:")
    print(f"    {PORTRAITS_DIR}/{CHARACTER}_idle_0.png")
    print(f"    {PORTRAITS_DIR}/{CHARACTER}_idle_1.png")
    print("\n  The DialogueBox will auto-detect and play blink animation!")


if __name__ == "__main__":
    main()
