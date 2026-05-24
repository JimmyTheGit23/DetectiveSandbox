#!/usr/bin/env python3
"""
Generate evidence/clue icons using Google Gemini Imagen API.
Usage: python3 tools/generate_evidence_icons_gemini.py [--case prologue_ferry|all]
"""

import json
import os
import sys
import time
import argparse
import base64
import urllib.request
import urllib.error

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "ai_processed", "objects", "evidence_icons")

API_KEY = "AIzaSyC0_sovY-q4Z6WjihkZM6xFWuScWfGgQo0"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-001:predict?key={API_KEY}"

CASES = {
    "prologue_ferry": {
        "evidence": os.path.join(PROJECT_ROOT, "data", "cases", "prologue_ferry", "evidence.json"),
    },
    "linchuan_inn": {
        "evidence": os.path.join(PROJECT_ROOT, "data", "cases", "linchuan_inn", "evidence.json"),
    },
    "xunyang_pavilion": {
        "evidence": os.path.join(PROJECT_ROOT, "data", "cases", "xunyang_pavilion", "evidence.json"),
    },
}

STYLE = (
    "Traditional Chinese Ming dynasty (1368-1644) ink wash painting style, "
    "game inventory icon on solid dark aged-parchment background, "
    "dark sepia and muted earth tones, centered single object composition, "
    "Absolutely NO text, NO Chinese characters, NO English letters, NO seal stamps, NO writing of any kind anywhere in the image. "
    "Highly detailed miniature illustration of a physical object, square format."
)

# Hand-crafted English prompts matching each evidence description
# ONLY evidence items (not clues) - focused on physical objects with Ming dynasty period accuracy
CUSTOM_PROMPTS = {
    "evidence_hull_hole": (
        "A section of traditional Chinese wooden boat hull plank (Ming dynasty river vessel), "
        "showing a clean square hole cut from the inside with chisel marks on the edges. "
        "Around the hole are two rows of small nail holes - one set dark and rusty, one set fresh. "
        "The wood grain is rough pine, water-stained and aged."
    ),
    "evidence_float_bladder": (
        "An inflated animal-hide flotation bladder used by ancient Chinese river workers, "
        "made of stitched brown ox leather with hemp cord ties at the neck. "
        "It sits on a piece of rough cotton cloth wrapping. "
        "Simple utilitarian object, no decorations."
    ),
    "evidence_gambling_iou": (
        "A crumpled and heavily creased piece of thin rice paper, folded many times. "
        "The paper is yellowed and stained with finger grease and tea spots. "
        "It is just a worn piece of paper - show NO writing, NO characters, just the physical paper itself "
        "with visible fold creases and torn edges."
    ),
    "evidence_dismissal_note": (
        "A single sheet of formal Ming dynasty paper document, neatly folded in half. "
        "The paper is high quality but yellowed with age, with a visible fold crease down the middle. "
        "Show ONLY the blank paper with its texture and fold - absolutely NO writing, NO stamps, NO seals, "
        "NO characters of any kind. Just aged paper."
    ),
    "evidence_cargo_silver": (
        "An empty Ming dynasty wooden cargo crate (flat rectangular box with bamboo reinforcement strips), "
        "its lid thrown open, lying on the wet floor of a wrecked wooden boat. "
        "Inside is completely empty except for a few scraps of wet cloth padding. "
        "The style is a simple Chinese merchant's cargo box, NOT a Western treasure chest."
    ),
    "evidence_nail_marks": (
        "Extreme close-up of a weathered wooden boat plank surface. "
        "Two distinct groups of nail holes are visible side by side: "
        "the left group has dark rusty oxidized holes (old), "
        "the right group has bright fresh wood-colored holes (new, recently driven). "
        "The wood shows water damage and salt staining typical of a river vessel."
    ),
}


def build_prompt(item_id: str, name: str, description: str, item_type: str) -> str:
    """Build the image generation prompt."""
    if item_id in CUSTOM_PROMPTS:
        context = CUSTOM_PROMPTS[item_id]
    else:
        # Fallback: use the description (translated to English context)
        if item_type == "evidence":
            context = f"Physical evidence item: '{name}'. {description[:120]}"
        else:
            context = f"Investigation clue: '{name}'. {description[:120]}"
    return f"{context}. Visual style: {STYLE}"


def generate_icon(item_id: str, prompt: str, output_dir: str) -> tuple:
    """Generate a single icon using Gemini Imagen API. Returns (path, error)."""
    output_path = os.path.join(output_dir, f"{item_id}.png")

    payload = json.dumps({
        "instances": [{"prompt": prompt}],
        "parameters": {
            "sampleCount": 1,
            "aspectRatio": "1:1",
            "personGeneration": "allow_all"
        }
    }).encode("utf-8")

    req = urllib.request.Request(
        API_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))

        predictions = result.get("predictions", [])
        if not predictions:
            return None, f"No predictions in response: {json.dumps(result)[:200]}"

        # Decode base64 image
        b64_data = predictions[0].get("bytesBase64Encoded", "")
        if not b64_data:
            return None, "No image data in prediction"

        img_bytes = base64.b64decode(b64_data)
        with open(output_path, "wb") as f:
            f.write(img_bytes)

        if os.path.getsize(output_path) < 100:
            return None, "Output file too small"

        return output_path, None

    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8", errors="replace")[:300]
        return None, f"HTTP {e.code}: {error_body}"
    except urllib.error.URLError as e:
        return None, f"URL Error: {e.reason}"
    except Exception as e:
        return None, str(e)


def main():
    parser = argparse.ArgumentParser(description="Generate evidence icons using Gemini Imagen API")
    parser.add_argument(
        "--case",
        default="prologue_ferry",
        choices=list(CASES.keys()) + ["all"],
        help="Which case to generate icons for (default: prologue_ferry)",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=4.0,
        help="Delay in seconds between API calls (default: 4.0)",
    )
    parser.add_argument(
        "--no-skip-existing",
        action="store_true",
        default=False,
        help="Regenerate even if icon already exists",
    )
    args = parser.parse_args()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    cases_to_process = list(CASES.keys()) if args.case == "all" else [args.case]

    all_items = []
    for case_id in cases_to_process:
        case_info = CASES[case_id]
        evidence_path = case_info["evidence"]
        if not os.path.exists(evidence_path):
            print(f"WARNING: {evidence_path} not found, skipping {case_id}")
            continue

        with open(evidence_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        for key, value in data.items():
            if key.startswith("_"):
                continue
            if not isinstance(value, dict):
                continue
            # Skip hidden, meta clues, and non-evidence items (clues don't need icons)
            if value.get("hidden", False) or value.get("meta_clue", False):
                continue
            if value.get("type", "") != "evidence":
                continue

            icon_path = os.path.join(OUTPUT_DIR, f"{key}.png")
            if not args.no_skip_existing and os.path.exists(icon_path) and os.path.getsize(icon_path) > 100:
                print(f"  SKIP [{key}] (already exists)")
                continue

            all_items.append({
                "id": key,
                "name": value.get("name", key),
                "description": value.get("description", ""),
                "type": value.get("type", "evidence"),
                "case": case_id,
            })

    if not all_items:
        print("No icons to generate. All items already have icons or are hidden.")
        return

    print(f"Generating {len(all_items)} icons using Gemini Imagen API...")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Delay between calls: {args.delay}s")
    print()

    success = 0
    failed = 0
    for i, item in enumerate(all_items):
        prompt = build_prompt(item["id"], item["name"], item["description"], item["type"])
        print(f"  [{i+1}/{len(all_items)}] Generating [{item['id']}] ({item['name']})...")
        print(f"    Prompt: {prompt[:100]}...")

        path, err = generate_icon(item["id"], prompt, OUTPUT_DIR)
        if path:
            size_kb = os.path.getsize(path) / 1024
            success += 1
            print(f"    OK -> {path} ({size_kb:.0f}KB)")
        else:
            failed += 1
            print(f"    FAIL: {err}")

        if i < len(all_items) - 1:
            time.sleep(args.delay)

    print(f"\nDone: {success} generated, {failed} failed")


if __name__ == "__main__":
    main()
