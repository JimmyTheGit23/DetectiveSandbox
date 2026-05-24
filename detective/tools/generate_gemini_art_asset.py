#!/usr/bin/env python3
"""
Gemini 美术资产生成器。

用途：
1. 生成 UI 图标、角色立绘、CG 草图等资产。
2. 当画面出现角色时，强制走项目内参考图 img2img，保证角色一致性。
3. 需要抠图时，强制输出纯色底（洋红或纯绿），并可直接走本地去底流程。

示例：
  生成设置按钮图标（无角色，不需要色键底）：
  python3 tools/generate_gemini_art_asset.py \
    --output assets/cn/ui/icon_settings_seal.png \
    --aspect-ratio 1:1 \
    --prompt "Antique Ming-dynasty brass settings emblem on dark lacquer background, centered, readable at 32px"

  生成带角色的纯紫底草图（必须参考项目内角色图）：
  python3 tools/generate_gemini_art_asset.py \
    --output assets/ai_raw/test/lingyao_pose_magenta.png \
    --aspect-ratio 1:1 \
    --reference assets/cn/portraits/companion_lingyao_v10.png \
    --character-consistency \
    --chroma magenta \
    --remove-chroma \
    --prompt "Same character, bust portrait, surprised expression, no extra props"
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MODEL = "gemini-2.5-flash-image"
API_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"

CHROMA_RULES = {
	"magenta": (
		"BACKGROUND RULE: use a completely flat solid pure magenta background #FF00FF only. "
		"No gradient, no texture, no shadows cast onto the background, no props touching the frame edge. "
		"Do not use magenta or purple on the subject itself unless explicitly required by the source reference."
	),
	"green": (
		"BACKGROUND RULE: use a completely flat solid pure green background #00FF00 only. "
		"No gradient, no texture, no shadows cast onto the background, no props touching the frame edge. "
		"Do not use bright chroma green on the subject itself unless explicitly required by the source reference."
	),
}

GENERAL_RULES = (
	"Return a finished image, not a text description. "
	"No watermark, no logo, no UI chrome, no readable text, no letters, no numbers. "
	"Preserve a clean silhouette and readable composition."
)

CHARACTER_RULES = (
	"CHARACTER CONSISTENCY RULE: use only the supplied project reference images as the identity source. "
	"Keep the same face shape, age, hairstyle, clothing silhouette, costume colors, accessories and overall identity. "
	"Do not invent a different character, do not merge with a generic face, do not change ethnicity or era. "
	"If multiple reference images are provided, treat them as the exact cast to preserve."
)


def parse_args() -> argparse.Namespace:
	ap = argparse.ArgumentParser(description="Generate image assets with Gemini while enforcing chroma and character-consistency rules.")
	ap.add_argument("--prompt", required=True, help="Primary prompt text.")
	ap.add_argument("--output", required=True, help="Output image path, relative to repo root or absolute path.")
	ap.add_argument("--aspect-ratio", default="1:1", help="Gemini aspect ratio, for example 1:1 or 16:9.")
	ap.add_argument("--model", default=DEFAULT_MODEL, help=f"Model name (default: {DEFAULT_MODEL}).")
	ap.add_argument("--api-key", default=os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY"), help="Gemini API key.")
	ap.add_argument("--reference", action="append", default=[], help="Reference image path. Repeatable. Required for character-consistent generations.")
	ap.add_argument("--character-consistency", action="store_true", help="Force img2img character identity preservation rules.")
	ap.add_argument("--chroma", choices=["none", "magenta", "green"], default="none", help="Use a flat chroma-key background.")
	ap.add_argument("--remove-chroma", action="store_true", help="Post-process the generated image into transparency using the local chroma removal helper.")
	ap.add_argument("--transparent-output", default="", help="Optional output path for the transparent result. Defaults to <output_stem>_transparent.png.")
	ap.add_argument("--dry-run", action="store_true", help="Print the resolved prompt and inputs without calling the API.")
	return ap.parse_args()


def repo_path(path_str: str) -> Path:
	path = Path(path_str)
	return path if path.is_absolute() else ROOT / path


def detect_mime(path: Path) -> str:
	suffix = path.suffix.lower()
	if suffix == ".png":
		return "image/png"
	if suffix in {".jpg", ".jpeg"}:
		return "image/jpeg"
	raise ValueError(f"Unsupported reference format: {path}")


def build_prompt(prompt: str, chroma: str, character_consistency: bool) -> str:
	parts = [prompt.strip(), GENERAL_RULES]
	if chroma != "none":
		parts.append(CHROMA_RULES[chroma])
	if character_consistency:
		parts.append(CHARACTER_RULES)
	return "\n\n".join(parts)


def build_payload(full_prompt: str, references: list[Path], aspect_ratio: str) -> dict[str, Any]:
	parts: list[dict[str, Any]] = []
	for ref in references:
		parts.append({
			"inline_data": {
				"mime_type": detect_mime(ref),
				"data": base64.b64encode(ref.read_bytes()).decode("ascii"),
			}
		})
	parts.append({"text": full_prompt})
	return {
		"contents": [{"parts": parts}],
		"generationConfig": {
			"responseModalities": ["TEXT", "IMAGE"],
			"imageConfig": {"aspectRatio": aspect_ratio},
		},
	}


def post_json_urllib(url: str, payload: dict[str, Any]) -> dict[str, Any]:
	req = urllib.request.Request(
		url,
		data=json.dumps(payload).encode("utf-8"),
		headers={"Content-Type": "application/json"},
		method="POST",
	)
	with urllib.request.urlopen(req, timeout=180) as resp:
		return json.loads(resp.read().decode("utf-8"))


def post_json_curl(url: str, payload: dict[str, Any]) -> dict[str, Any]:
	result = subprocess.run(
		[
			"curl", "-sS", "-X", "POST", url,
			"-H", "Content-Type: application/json",
			"--data-binary", "@-",
		],
		input=json.dumps(payload),
		text=True,
		capture_output=True,
		check=False,
	)
	if result.returncode != 0:
		raise RuntimeError(result.stderr.strip() or "curl request failed")
		
	return json.loads(result.stdout)


def call_gemini(model: str, api_key: str, payload: dict[str, Any]) -> dict[str, Any]:
	url = API_URL.format(model=model, key=api_key)
	try:
		return post_json_urllib(url, payload)
	except Exception as exc:
		print(f"[warn] urllib failed, falling back to curl: {exc}", file=sys.stderr)
		return post_json_curl(url, payload)


def extract_image_bytes(response: dict[str, Any]) -> bytes:
	if response.get("error"):
		raise RuntimeError(response["error"].get("message", json.dumps(response["error"])))
	for candidate in response.get("candidates", []):
		for part in candidate.get("content", {}).get("parts", []):
			inline = part.get("inlineData") or part.get("inline_data")
			if inline and inline.get("data"):
				return base64.b64decode(inline["data"])
	texts = []
	for candidate in response.get("candidates", []):
		for part in candidate.get("content", {}).get("parts", []):
			if part.get("text"):
				texts.append(part["text"])
	message = texts[0] if texts else json.dumps(response)[:400]
	raise RuntimeError(f"Gemini did not return image data. Response: {message}")


def remove_chroma(raw_path: Path, transparent_path: Path) -> None:
	sys.path.insert(0, str(Path(__file__).resolve().parent))
	from defringe_portrait import remove_chroma_background

	remove_chroma_background(str(raw_path), str(transparent_path))


def main() -> int:
	args = parse_args()
	if not args.api_key:
		print("缺少 GEMINI_API_KEY / GOOGLE_API_KEY，或使用 --api-key。", file=sys.stderr)
		return 2
	if args.character_consistency and not args.reference:
		print("开启 --character-consistency 时必须提供至少一张 --reference。", file=sys.stderr)
		return 2
	if args.remove_chroma and args.chroma == "none":
		print("开启 --remove-chroma 时必须指定 --chroma magenta 或 --chroma green。", file=sys.stderr)
		return 2

	output_path = repo_path(args.output)
	references = [repo_path(path_str) for path_str in args.reference]
	missing = [str(path) for path in references if not path.exists()]
	if missing:
		print("缺少参考图：", file=sys.stderr)
		for item in missing:
			print(f"  - {item}", file=sys.stderr)
		return 2

	full_prompt = build_prompt(args.prompt, args.chroma, args.character_consistency)
	payload = build_payload(full_prompt, references, args.aspect_ratio)

	print(f"model: {args.model}")
	print(f"output: {output_path}")
	print(f"references: {len(references)}")
	print(f"chroma: {args.chroma}")
	print(f"character_consistency: {args.character_consistency}")
	print("prompt:")
	print(full_prompt)

	if args.dry_run:
		return 0

	output_path.parent.mkdir(parents=True, exist_ok=True)
	response = call_gemini(args.model, args.api_key, payload)
	image_bytes = extract_image_bytes(response)
	output_path.write_bytes(image_bytes)
	print(f"saved raw image: {output_path}")

	if args.remove_chroma:
		transparent_path = repo_path(args.transparent_output) if args.transparent_output else output_path.with_stem(output_path.stem + "_transparent")
		remove_chroma(output_path, transparent_path)
		print(f"saved transparent image: {transparent_path}")

	return 0


if __name__ == "__main__":
	sys.exit(main())
