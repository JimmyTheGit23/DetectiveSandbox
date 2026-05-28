#!/usr/bin/env python3
"""
Generate prologue_inn_corridor.png using Gemini API.
Scene backgrounds don't need cutout/despill — generate directly with natural background.
"""

import base64
import json
import os
import time
import urllib.request
import urllib.error

API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"
OUTPUT_PATH = "E:/godot/DetectiveSandbox/detective/assets/cn/scenes/prologue_inn_corridor.png"

PROMPT = """
Semi-realistic Chinese historical illustration in ink-wash style (半写实古风插画).
Wide-angle view of a narrow inn corridor at night during heavy rain.

Scene details:
- Long wooden hallway of a Ming Dynasty inn (明代客栈走廊), viewed from one end looking down the length
- Dark aged wooden walls with visible grain and knots, wooden plank flooring
- Low ceiling with wooden beams overhead
- 2-3 red paper lanterns hanging from the ceiling at intervals, casting warm amber-orange pools of light on the walls and floor
- Doors on one or both sides (simple wooden sliding doors), some slightly ajar showing darkness within
- At the far end of the corridor, a window or open doorway showing rain outside — rain streaming down in silver threads, blue-grey rainy night
- Atmosphere: dim, moody, slightly oppressive — a corridor where secrets are kept
- Floor slightly reflective from moisture/rain tracked in
- No people, no figures
- Muted earth tones: dark brown wood, warm amber lantern glow, cool grey-blue from rain at end
- Detailed architectural elements: wooden lattice windows, heavy timber construction
- Same style as existing game assets: clean linework with soft shading, warm lantern lighting contrasting cold rainy exterior
- Horizontal composition, cinematic widescreen (approximately 16:9 aspect ratio)
- IMPORTANT: NO TEXT, NO CHARACTERS, NO WRITING, NO CHINESE CHARACTERS on any surfaces — all signs blank, all walls plain wood
""".strip()

def call_gemini_image(prompt: str, retries: int = 4) -> bytes:
    if not API_KEY:
        raise RuntimeError("请先设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={API_KEY}"

    payload = {
        "contents": [{
            "parts": [{"text": prompt}]
        }],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"]
        }
    }

    body = json.dumps(payload).encode("utf-8")

    delays = [15, 30, 45, 60]

    for attempt in range(retries):
        print(f"[Attempt {attempt + 1}/{retries}] Calling Gemini API...")
        try:
            req = urllib.request.Request(
                url,
                data=body,
                headers={"Content-Type": "application/json"}
            )
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode("utf-8"))

            # Extract image data from response
            candidates = data.get("candidates", [])
            if not candidates:
                print("  ERROR: No candidates in response")
                print("  Response:", json.dumps(data, indent=2)[:500])
                raise ValueError("No candidates returned")

            parts = candidates[0].get("content", {}).get("parts", [])
            for part in parts:
                if "inlineData" in part:
                    mime = part["inlineData"].get("mimeType", "")
                    if "image" in mime:
                        print(f"  SUCCESS: Got image ({mime})")
                        return base64.b64decode(part["inlineData"]["data"])

            # Check for text-only response (no image generated)
            for part in parts:
                if "text" in part:
                    print(f"  Text response (no image): {part['text'][:200]}")

            raise ValueError("No image data in response parts")

        except urllib.error.HTTPError as e:
            status = e.code
            body_text = e.read().decode("utf-8", errors="replace")[:300]
            print(f"  HTTP {status}: {body_text}")

            if status == 503 and attempt < retries - 1:
                wait = delays[attempt]
                print(f"  503 Service Unavailable — retrying in {wait}s...")
                time.sleep(wait)
            elif status == 429 and attempt < retries - 1:
                wait = delays[attempt]
                print(f"  429 Rate limit — retrying in {wait}s...")
                time.sleep(wait)
            else:
                raise

        except Exception as e:
            print(f"  Error: {e}")
            if attempt < retries - 1:
                wait = delays[attempt]
                print(f"  Retrying in {wait}s...")
                time.sleep(wait)
            else:
                raise

    raise RuntimeError("All retries exhausted")


def main():
    print("=" * 60)
    print("Generating: prologue_inn_corridor.png")
    print("Model:", MODEL)
    print("Output:", OUTPUT_PATH)
    print("=" * 60)
    print()

    image_bytes = call_gemini_image(PROMPT)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "wb") as f:
        f.write(image_bytes)

    size_kb = len(image_bytes) / 1024
    print(f"\nSaved: {OUTPUT_PATH} ({size_kb:.1f} KB)")
    print("Done!")


if __name__ == "__main__":
    main()
