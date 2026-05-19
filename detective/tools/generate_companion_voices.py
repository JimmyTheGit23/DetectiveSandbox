#!/usr/bin/env python3
"""
Generate companion (凌瑶) voice lines using MiniMax TTS API.

Usage:
    python tools/generate_companion_voices.py --api-key YOUR_KEY [--voice-id VOICE_ID] [--model MODEL]

Supported models:
    speech-2.8-hd   — 最新模型，支持语气词和情绪控制 (推荐)
    speech-2.6-hd   — 稳定版本
    speech-02-hd    — 旧版模型

Extracts all companion dialogue from JSON data files and generates WAV audio
for each line, saved to assets/cn/voices/actor_tomboy_courier/linchuan_inn/.

Requires: pip install requests
"""

import argparse
import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path

import requests

# ─── Configuration ──────────────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data" / "cases" / "linchuan_inn" / "companion"
OUTPUT_DIR = PROJECT_ROOT / "assets" / "cn" / "voices" / "actor_tomboy_courier" / "linchuan_inn"

COMPANION_SPEAKER = "凌瑶"
DEFAULT_VOICE_ID = "female-shaonv"               # 少女音色 — 适合凌瑶的活泼少女形象
DEFAULT_MODEL = "speech-2.8-hd"                   # 最新模型
API_BASE = "https://api.minimax.chat"

# Rate limiting
REQUEST_INTERVAL = 0.5  # seconds between API calls
MAX_RETRIES = 3
RETRY_DELAY = 2  # seconds


# ─── Extract companion lines from JSON ──────────────────────────────────────

def _extract_from_banter(data: dict) -> list[dict]:
    """Extract companion lines from banter.json."""
    results = []
    rules = data.get("rules", [])
    for rule in rules:
        rule_id = rule.get("id", "unknown")
        lines = rule.get("lines", [])
        for i, entry in enumerate(lines):
            if isinstance(entry, str):
                results.append({
                    "source": f"banter/{rule_id}",
                    "index": i,
                    "text": entry,
                })
            elif isinstance(entry, list):
                for j, item in enumerate(entry):
                    if isinstance(item, dict) and item.get("speaker") == COMPANION_SPEAKER:
                        results.append({
                            "source": f"banter/{rule_id}",
                            "index": i,
                            "sub_index": j,
                            "text": item.get("text", ""),
                        })
    return results


def _extract_from_discussions(data: dict) -> list[dict]:
    """Extract companion lines from discussions.json."""
    results = []
    for topic_name, topic_data in data.items():
        if not isinstance(topic_data, dict):
            continue

        if topic_name == "chitchat":
            pool = topic_data.get("pool", [])
            for i, item in enumerate(pool):
                lines = item.get("lines", [])
                for j, line in enumerate(lines):
                    results.append({
                        "source": f"discuss/chitchat",
                        "index": i,
                        "sub_index": j,
                        "text": line,
                    })
            continue

        rules = topic_data.get("rules", [])
        for i, rule in enumerate(rules):
            lines = rule.get("lines", [])
            for j, line in enumerate(lines):
                results.append({
                    "source": f"discuss/{topic_name}",
                    "index": i,
                    "sub_index": j,
                    "text": line,
                })
    return results


def extract_all_lines() -> list[dict]:
    """Extract all companion lines from all data files."""
    all_lines = []

    banter_path = DATA_DIR / "banter.json"
    if banter_path.exists():
        with open(banter_path, "r", encoding="utf-8") as f:
            banter_data = json.load(f)
        all_lines.extend(_extract_from_banter(banter_data))

    discuss_path = DATA_DIR / "discussions.json"
    if discuss_path.exists():
        with open(discuss_path, "r", encoding="utf-8") as f:
            discuss_data = json.load(f)
        all_lines.extend(_extract_from_discussions(discuss_data))

    return all_lines


# ─── Generate filename for a line ───────────────────────────────────────────

def generate_filename(line: dict, seq: int) -> str:
    """Generate a descriptive filename for a voice line."""
    source = line["source"]
    short_source = source.replace("banter/", "b_").replace("discuss/", "d_")
    text_hash = hashlib.md5(line["text"].encode("utf-8")).hexdigest()[:6]
    text_hint = line["text"][:10].replace(" ", "")
    return f"{short_source}_{seq:03d}_{text_hint}_{text_hash}"


# ─── MiniMax TTS API call ──────────────────────────────────────────────────

def call_tts_v2(api_key: str, text: str, voice_id: str, model: str) -> bytes:
    """Call MiniMax t2a_v2 API and return raw audio bytes (WAV).

    Supports speech-2.8-hd, speech-2.6-hd, speech-02-hd models.
    Uses the new voice_setting/audio_setting parameter structure.
    """
    url = f"{API_BASE}/v1/t2a_v2"

    payload = {
        "model": model,
        "text": text,
        "stream": False,
        "voice_setting": {
            "voice_id": voice_id,
            "speed": 1.0,
            "vol": 1.0,
            "pitch": 0,
        },
        "audio_setting": {
            "sample_rate": 24000,
            "bitrate": 128000,
            "format": "wav",
            "channel": 1,
        },
        "output_format": "hex",
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    for attempt in range(MAX_RETRIES):
        try:
            resp = requests.post(url, json=payload, headers=headers, timeout=60)
            result = resp.json()
            base_resp = result.get("base_resp", {})
            status_code = base_resp.get("status_code", -1)
            status_msg = base_resp.get("status_msg", "unknown")

            # Success
            if status_code == 0:
                audio_hex = result.get("data", {}).get("audio", "")
                if audio_hex:
                    return bytes.fromhex(audio_hex)
                else:
                    raise RuntimeError(f"No audio data in response")

            # Insufficient balance — no point retrying
            if status_code in (1008, 2056):
                err_detail = base_resp.get("status_msg", "")
                if "balance" in err_detail.lower() or "limit" in err_detail.lower():
                    raise RuntimeError(f"USAGE LIMIT: {err_detail}")
                raise RuntimeError(f"API error: {err_detail}")

            print(f"  API error (status={status_code}): {status_msg}")
            if attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_DELAY * (attempt + 1))
                continue
            raise RuntimeError(f"MiniMax API error: {status_msg}")

        except requests.exceptions.RequestException as e:
            print(f"  Request error: {e}")
            if attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_DELAY * (attempt + 1))
            else:
                raise

    raise RuntimeError("Max retries exceeded")


# ─── Main ───────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Generate companion voice lines via MiniMax TTS")
    parser.add_argument("--api-key", required=True, help="MiniMax API key")
    parser.add_argument("--voice-id", default=DEFAULT_VOICE_ID, help=f"Voice ID (default: {DEFAULT_VOICE_ID})")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"TTS model (default: {DEFAULT_MODEL})")
    parser.add_argument("--dry-run", action="store_true", help="Only list lines, don't generate audio")
    parser.add_argument("--skip-existing", action="store_true", help="Skip lines that already have audio files")
    parser.add_argument("--only", type=str, help="Only generate lines matching source filter (e.g. 'banter' or 'discuss')")
    parser.add_argument("--limit", type=int, default=0, help="Max number of lines to generate (0=all)")
    args = parser.parse_args()

    # Extract all lines
    lines = extract_all_lines()
    print(f"Extracted {len(lines)} companion lines from data files")
    print(f"Model: {args.model} | Voice: {args.voice_id}\n")

    if args.only:
        lines = [l for l in lines if args.only in l["source"]]
        print(f"Filtered to {len(lines)} lines matching '{args.only}'\n")

    if args.limit > 0:
        lines = lines[:args.limit]
        print(f"Limited to {len(lines)} lines\n")

    # Dry run
    if args.dry_run:
        for i, line in enumerate(lines):
            fname = generate_filename(line, i)
            print(f"  [{i:03d}] {fname}.wav")
            print(f"         \"{line['text'][:50]}{'...' if len(line['text'])>50 else ''}\"")
            print(f"         source: {line['source']}")
        print(f"\nTotal: {len(lines)} lines")
        return

    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Generate audio
    success_count = 0
    fail_count = 0
    skip_count = 0

    for i, line in enumerate(lines):
        fname = generate_filename(line, i)
        out_path = OUTPUT_DIR / f"{fname}.wav"

        # Skip existing
        if args.skip_existing and out_path.exists():
            skip_count += 1
            continue

        print(f"[{i+1}/{len(lines)}] {fname}.wav")
        print(f"  \"{line['text'][:60]}{'...' if len(line['text'])>60 else ''}\"")

        try:
            audio_bytes = call_tts_v2(args.api_key, line["text"], args.voice_id, args.model)
            with open(out_path, "wb") as f:
                f.write(audio_bytes)
            size_kb = len(audio_bytes) / 1024
            print(f"  OK Saved ({size_kb:.1f} KB)")
            success_count += 1
        except RuntimeError as e:
            err_str = str(e)
            print(f"  FAILED: {e}")
            # If balance/limit issue, stop immediately
            if "USAGE LIMIT" in err_str or "balance" in err_str.lower():
                print(f"\n!!! Usage limit reached — stopping.")
                print(f"    If Token Plan Plus, wait for rate limit reset.")
                print(f"    Otherwise, top up at https://platform.minimaxi.com/")
                break
            fail_count += 1
        except Exception as e:
            print(f"  FAILED: {e}")
            fail_count += 1

        # Rate limit
        if i < len(lines) - 1:
            time.sleep(REQUEST_INTERVAL)

    print(f"\n{'='*50}")
    print(f"Done! Success: {success_count}, Failed: {fail_count}, Skipped: {skip_count}")
    print(f"Output: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
