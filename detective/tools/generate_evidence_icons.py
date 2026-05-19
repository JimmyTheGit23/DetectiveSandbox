#!/usr/bin/env python3
"""
Generate evidence/clue icons using MiniMax CLI (mmx).
Usage: python3 tools/generate_evidence_icons.py [--case linchuan_inn|xunyang_pavilion|all]
Requires: mmx CLI installed and configured with API key.
"""

import json
import os
import subprocess
import sys
import time
import argparse

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "ai_processed", "objects", "evidence_icons")

# Ensure mmx is on PATH
NODE_BIN = os.path.expanduser("~/.workbuddy/binaries/node/versions/20.18.0/bin")
MMX = os.path.join(NODE_BIN, "mmx")

CASES = {
    "linchuan_inn": {
        "evidence": os.path.join(PROJECT_ROOT, "data", "cases", "linchuan_inn", "evidence.json"),
    },
    "xunyang_pavilion": {
        "evidence": os.path.join(PROJECT_ROOT, "data", "cases", "xunyang_pavilion", "evidence.json"),
    },
}

STYLE = (
    "Traditional Chinese Ming dynasty ink wash painting style, "
    "game inventory icon on solid magenta #FF00FF background, "
    "dark sepia and aged paper tones, centered single object composition, "
    "Do NOT include any text, letters, or characters in the image. "
    "highly detailed miniature illustration."
)


def build_prompt(item_id: str, name: str, description: str, item_type: str) -> str:
    if item_type == "evidence":
        context = (
            f"Physical evidence item from a Chinese detective game set in Ming dynasty: '{name}'. "
            f"Context: {description[:150]}"
        )
    else:
        context = (
            f"Investigation clue/note from a Chinese detective game set in Ming dynasty: '{name}'. "
            f"Context: {description[:150]}"
        )
    return f"{context}. Visual style: {STYLE}"


def generate_icon(item_id: str, prompt: str, output_dir: str) -> tuple:
    """Generate a single icon using mmx CLI. Returns (path, error)."""
    output_path = os.path.join(output_dir, f"{item_id}.png")

    cmd = [
        MMX, "image", "generate",
        "--prompt", prompt,
        "--aspect-ratio", "1:1",
        "--out", output_path,
    ]

    env = os.environ.copy()
    env["PATH"] = NODE_BIN + ":" + env.get("PATH", "")

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=180,
            env=env,
        )
        if result.returncode != 0:
            return None, f"mmx exit {result.returncode}: {result.stderr[:200]}"

        if not os.path.exists(output_path) or os.path.getsize(output_path) < 100:
            return None, f"Output file missing or too small: {result.stdout[:200]}"

        return output_path, None
    except subprocess.TimeoutExpired:
        return None, "Timeout after 180s"
    except Exception as e:
        return None, str(e)


def main():
    parser = argparse.ArgumentParser(description="Generate evidence icons using MiniMax CLI")
    parser.add_argument(
        "--case",
        default="all",
        choices=["linchuan_inn", "xunyang_pavilion", "all"],
        help="Which case to generate icons for (default: all)",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=3.0,
        help="Delay in seconds between API calls (default: 3.0)",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        default=True,
        help="Skip items that already have an icon file (default: True)",
    )
    args = parser.parse_args()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Verify mmx is available
    env = os.environ.copy()
    env["PATH"] = NODE_BIN + ":" + env.get("PATH", "")
    try:
        subprocess.run([MMX, "--version"], capture_output=True, check=True, env=env, timeout=10)
    except Exception as e:
        print(f"ERROR: mmx CLI not found or not working. Error: {e}")
        print(f"Make sure mmx is installed and PATH includes: {NODE_BIN}")
        sys.exit(1)

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

            icon_path = os.path.join(OUTPUT_DIR, f"{key}.png")
            if args.skip_existing and os.path.exists(icon_path) and os.path.getsize(icon_path) > 100:
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
        print("No icons to generate. All items already have icons.")
        return

    print(f"Generating {len(all_items)} icons using MiniMax image-01...")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Delay between calls: {args.delay}s")
    print()

    success = 0
    failed = 0
    for i, item in enumerate(all_items):
        prompt = build_prompt(item["id"], item["name"], item["description"], item["type"])
        print(f"  [{i+1}/{len(all_items)}] Generating [{item['id']}] ({item['name']})...")

        path, err = generate_icon(item["id"], prompt, OUTPUT_DIR)
        if path:
            success += 1
            print(f"    OK -> {path}")
        else:
            failed += 1
            print(f"    FAIL: {err}")

        if i < len(all_items) - 1:
            time.sleep(args.delay)

    print(f"\nDone: {success} generated, {failed} failed, {len(all_items) - success - failed} skipped")


if __name__ == "__main__":
    main()
