#!/usr/bin/env python3
"""
Generate evidence/clue icons using Gemini API.
Usage: python3 tools/generate_evidence_icons.py --api-key YOUR_KEY
"""

import argparse
import json
import os
import sys
import base64
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    import requests
except ImportError:
    print("Installing requests...")
    os.system(f"{sys.executable} -m pip install requests -q")
    import requests

API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"
DEFAULT_MODEL = "gemini-2.5-flash-image"


def generate_icon(item_id, name, description, item_type, api_key, model, output_dir):
    """Generate a single icon using Gemini API."""

    style = (
        "Traditional Chinese Ming dynasty ink wash painting style, "
        "small square game inventory icon, dark sepia and aged paper tones, "
        "centered composition, no text labels, highly detailed miniature illustration."
    )

    if item_type == "evidence":
        context = (
            f"Physical evidence item from a Chinese detective game set in Ming dynasty: '{name}'. "
            f"Context: {description[:180]}"
        )
    else:
        context = (
            f"Investigation clue/note from a Chinese detective game set in Ming dynasty: '{name}'. "
            f"Context: {description[:180]}"
        )

    prompt = f"{context}. Visual style: {style}"

    url = f"{API_BASE}/{model}:generateContent"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
            "responseFormat": {"image": {"aspectRatio": "1:1"}},
        },
    }

    try:
        resp = requests.post(
            url,
            headers={
                "Content-Type": "application/json",
                "x-goog-api-key": api_key,
            },
            json=payload,
            timeout=60,
        )
        resp.raise_for_status()
        data = resp.json()

        candidates = data.get("candidates", [])
        if not candidates:
            return None, "No candidates in response"

        parts = candidates[0].get("content", {}).get("parts", [])
        image_data = None

        for part in parts:
            inline_data = part.get("inline_data")
            if inline_data and inline_data.get("mime_type", "").startswith("image/"):
                image_data = base64.b64decode(inline_data["data"])
                break

        if not image_data:
            return None, "No image data in response"

        output_path = os.path.join(output_dir, f"{item_id}.png")
        with open(output_path, "wb") as f:
            f.write(image_data)

        return output_path, None

    except Exception as e:
        return None, str(e)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-key", required=True, help="Gemini API key")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="Gemini model name")
    parser.add_argument(
        "--evidence",
        default="data/cases/linchuan_inn/evidence.json",
        help="Path to evidence JSON file",
    )
    parser.add_argument(
        "--output-dir",
        default="assets/ai_processed/objects/evidence_icons",
        help="Output directory for generated icons",
    )
    parser.add_argument(
        "--max-workers",
        type=int,
        default=2,
        help="Max concurrent API requests",
    )
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    with open(args.evidence, "r", encoding="utf-8") as f:
        data = json.load(f)

    items = []
    for key, value in data.items():
        if key.startswith("_"):
            continue
        items.append(
            (
                key,
                value.get("name", key),
                value.get("description", ""),
                value.get("type", "evidence"),
            )
        )

    print(f"Generating {len(items)} icons using model '{args.model}'...")

    results = {}
    with ThreadPoolExecutor(max_workers=args.max_workers) as executor:
        futures = {
            executor.submit(
                generate_icon,
                item_id,
                name,
                desc,
                item_type,
                args.api_key,
                args.model,
                args.output_dir,
            ): item_id
            for item_id, name, desc, item_type in items
        }

        for future in as_completed(futures):
            item_id = futures[future]
            try:
                path, err = future.result()
                if path:
                    results[item_id] = path
                    print(f"  OK [{item_id}]")
                else:
                    print(f"  FAIL [{item_id}]: {err}")
            except Exception as e:
                print(f"  FAIL [{item_id}]: {e}")

    # Update evidence.json with icon paths for successful generations
    updated_count = 0
    for key, value in data.items():
        if key.startswith("_"):
            continue
        if key in results:
            value["icon"] = f"res://{args.output_dir}/{key}.png"
            updated_count += 1

    with open(args.evidence, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(
        f"\nDone: {len(results)}/{len(items)} icons generated, {updated_count} entries updated in {args.evidence}"
    )


if __name__ == "__main__":
    main()
