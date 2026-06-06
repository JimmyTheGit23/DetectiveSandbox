#!/usr/bin/env python3
"""
Generate case-table evidence icons using MiniMax CLI.

Usage:
  python3 tools/generate_case_table_evidence_icons_mmx.py \
    --case prologue_ferry \
    --api-key "$MINIMAX_API_KEY" \
    --ids evidence_weather_fog evidence_storm_noise evidence_cabin_escape_time
"""

from __future__ import annotations

import argparse
import csv
import os
import subprocess
import sys
import time
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
EVIDENCE_TABLE = PROJECT_ROOT / "data" / "case_tables"
OUTPUT_DIR = PROJECT_ROOT / "assets" / "ai_processed" / "objects" / "evidence_icons"
MMX = Path.home() / ".workbuddy" / "binaries" / "node" / "versions" / "20.18.0" / "bin" / "mmx"


STYLE = (
    "Traditional Chinese Ming dynasty inventory icon. "
    "Single centered object on a transparent or visually isolated background. "
    "Aged paper, brushed ink, wood, wax, cloth, and metal are allowed materials. "
    "Readable silhouette, game item icon framing, no UI, no watermark, no labels, no visible text or legible characters, no extra hands."
)

PROMPT_OVERRIDES = {
    "evidence_weather_fog": (
        "A Ming dynasty court evidence icon: an official river inspection sheet on aged parchment, "
        "showing a brush-ink sketch of a riverbank, a distant boat silhouette swallowed by dense fog, "
        "and a small measuring cord with marker pegs beside it. "
        "No readable text, just abstract inspection marks and seals."
    ),
    "evidence_storm_noise": (
        "A Ming dynasty court evidence icon: a witness note scroll about storm noise, "
        "with a small dark boat silhouette, heavy rain slashes, violent wave strokes, and wind swirl motifs "
        "painted in brush ink around the scene. Include a small wax seal or tally token, but no readable text."
    ),
    "evidence_cabin_escape_time": (
        "A Ming dynasty court evidence icon: a rescue deposition sheet on aged parchment, "
        "with two witness seal marks, a simple sketch of a collapsed man being dragged ashore, "
        "and a traditional timekeeping marker such as incense ash tally or bamboo time slips. "
        "No readable text, just official-looking record marks."
    ),
}


def load_items(case_id: str) -> dict[str, dict[str, str]]:
    table_path = EVIDENCE_TABLE / case_id / "evidence_items.csv"
    if not table_path.exists():
        raise FileNotFoundError(f"Missing evidence table: {table_path}")
    items: dict[str, dict[str, str]] = {}
    with table_path.open(encoding="utf-8-sig", newline="") as fh:
        for row in csv.DictReader(fh):
            item_id = row.get("item_id", "").strip()
            if not item_id or item_id.startswith("#"):
                continue
            items[item_id] = row
    return items


def build_prompt(item_id: str, row: dict[str, str]) -> str:
    if item_id in PROMPT_OVERRIDES:
        return f"{PROMPT_OVERRIDES[item_id]} {STYLE}"
    item_type = row.get("type", "evidence").strip() or "evidence"
    category = row.get("category", "").strip()
    name = row.get("name", item_id).strip()
    description = row.get("description", "").strip()
    descriptor = "physical evidence" if item_type == "evidence" else "written clue or investigation note"
    category_text = f"Category: {category}. " if category else ""
    return (
        f"Create a {descriptor} icon for a Ming dynasty detective game. "
        f"Item name: {name}. "
        f"{category_text}"
        f"Depict the evidence itself, not a scene. "
        f"Description: {description[:280]} "
        f"{STYLE}"
    )


def generate_icon(api_key: str, item_id: str, prompt: str, delay: float) -> tuple[bool, str]:
    output_path = OUTPUT_DIR / f"{item_id}.png"
    env = os.environ.copy()
    cmd = [
        str(MMX),
        "--api-key",
        api_key,
        "--quiet",
        "--non-interactive",
        "image",
        "generate",
        "--prompt",
        prompt,
        "--aspect-ratio",
        "1:1",
        "--response-format",
        "base64",
        "--out",
        str(output_path),
    ]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=240,
            env=env,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return False, "timeout"
    if result.returncode != 0:
        stderr = (result.stderr or result.stdout).strip()
        return False, stderr[:300]
    if not output_path.exists() or output_path.stat().st_size < 128:
        return False, "output missing or too small"
    if delay > 0:
        time.sleep(delay)
    return True, str(output_path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate evidence icons from case-table CSV using mmx")
    parser.add_argument("--case", required=True, help="Case id, for example prologue_ferry")
    parser.add_argument("--api-key", required=True, help="MiniMax API key")
    parser.add_argument("--ids", nargs="+", required=True, help="Evidence/clue ids to generate")
    parser.add_argument("--force", action="store_true", help="Regenerate even if icon exists")
    parser.add_argument("--delay", type=float, default=1.5, help="Delay between generations")
    args = parser.parse_args()

    if not MMX.exists():
        print(f"mmx CLI not found: {MMX}", file=sys.stderr)
        return 2

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    items = load_items(args.case)

    missing: list[str] = []
    for item_id in args.ids:
        if item_id not in items:
            missing.append(item_id)
    if missing:
        print("Unknown ids:", ", ".join(missing), file=sys.stderr)
        return 2

    failures = 0
    for item_id in args.ids:
        output_path = OUTPUT_DIR / f"{item_id}.png"
        if output_path.exists() and not args.force:
            print(f"SKIP {item_id} -> {output_path.name}")
            continue
        prompt = build_prompt(item_id, items[item_id])
        ok, detail = generate_icon(args.api_key, item_id, prompt, args.delay)
        if ok:
            print(f"OK   {item_id} -> {output_path.name}")
        else:
            failures += 1
            print(f"FAIL {item_id}: {detail}", file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
