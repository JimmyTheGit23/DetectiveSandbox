"""
证据图标生成工具
==========================================
使用纯紫背景 + 抠图流程生成证据图标。

用法：
  python tools/generate_evidence_icons_batch.py
"""

from google import genai
from google.genai import types
from pathlib import Path
import os
import subprocess

API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-image"

# 项目路径
PROJECT_ROOT = Path(__file__).parent.parent
EVIDENCE_DIR = PROJECT_ROOT / "assets" / "ai_processed" / "objects" / "evidence_icons"
REMOVE_BG_SCRIPT = Path.home() / ".codebuddy" / "skills" / "purple-chromakey-image" / "scripts" / "remove_magenta_background.py"

# 证据图标配置
EVIDENCE_CONFIGS = {
    "clue_fan_alibi_hole": {
        "prompt": """A worn parchment document with a torn hole in the center, symbolizing a broken alibi. The document has Chinese calligraphy writing that is partially visible but illegible. The hole is ragged and deliberate, suggesting someone tried to destroy evidence.

Background: SOLID PURE MAGENTA #FF00FF, flat chroma key background, no transparency, no checkerboard, no gradient.
The subject must be clearly separated from the magenta background with clean edges.
No text, no watermark, no labels, no UI, no grid lines.
Game item icon style, centered, clear silhouette, high contrast, detailed texture.""",
    },
    "clue_broken_rope": {
        "prompt": """A thick hemp rope that has been cut or broken, coiled loosely. The rope ends are frayed and show clean cut marks. The rope is weathered and old, suitable for a boat dock. One end has a metal ring attached.

Background: SOLID PURE MAGENTA #FF00FF, flat chroma key background, no transparency, no checkerboard, no gradient.
The subject must be clearly separated from the magenta background with clean edges.
No text, no watermark, no labels, no UI, no grid lines.
Game item icon style, centered, clear silhouette, high contrast, detailed texture.""",
    },
    "dock_shop_receipt": {
        "prompt": """An old Chinese merchant receipt written on yellowed paper with ink brush strokes. The receipt shows item quantities and prices in traditional Chinese accounting format. A red stamp/seal is partially visible at the bottom. The paper is slightly crumpled.

Background: SOLID PURE MAGENTA #FF00FF, flat chroma key background, no transparency, no checkerboard, no gradient.
The subject must be clearly separated from the magenta background with clean edges.
No text, no watermark, no labels, no UI, no grid lines.
Game item icon style, centered, clear silhouette, high contrast, detailed texture.""",
    },
    "inn_kitchen_knife": {
        "prompt": """A Chinese kitchen cleaver with a wooden handle, commonly used in Ming Dynasty inns and kitchens. The blade is slightly rusty but sharp. The handle is worn from use. The knife has a practical, utilitarian design.

Background: SOLID PURE MAGENTA #FF00FF, flat chroma key background, no transparency, no checkerboard, no gradient.
The subject must be clearly separated from the magenta background with clean edges.
No text, no watermark, no labels, no UI, no grid lines.
Game item icon style, centered, clear silhouette, high contrast, detailed texture.""",
    },
    "dock_mysterious_footprints": {
        "prompt": """A pair of muddy footprints on a wet wooden dock surface. The footprints are partially filled with water, showing clear boot/shoe patterns. The prints lead in an unexpected direction near the edge of the dock. Mud residue visible.

Background: SOLID PURE MAGENTA #FF00FF, flat chroma key background, no transparency, no checkerboard, no gradient.
The subject must be clearly separated from the magenta background with clean edges.
No text, no watermark, no labels, no UI, no grid lines.
Game item icon style, centered, clear silhouette, high contrast, detailed texture.""",
    },
    "evidence_bladder_receipt": {
        "prompt": """A formal purchase receipt for animal bladders (used for making waterproof bags/floats) from a dock supply shop. Written on traditional Chinese paper with ink. Shows the item name, quantity (2 pieces), date, and shop stamp. The document is official-looking.

Background: SOLID PURE MAGENTA #FF00FF, flat chroma key background, no transparency, no checkerboard, no gradient.
The subject must be clearly separated from the magenta background with clean edges.
No text, no watermark, no labels, no UI, no grid lines.
Game item icon style, centered, clear silhouette, high contrast, detailed texture.""",
    },
}


def remove_background(input_path: Path, output_path: Path, tolerance: int = 55):
    """运行抠图脚本去除紫色背景"""
    cmd = [
        "python3", str(REMOVE_BG_SCRIPT),
        "--input", str(input_path),
        "--output", str(output_path),
        "--tolerance", str(tolerance),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  [ERROR] 抠图失败: {result.stderr}")
        return False
    return True


def main():
    if not API_KEY:
        raise RuntimeError("请设置 GEMINI_API_KEY 环境变量或通过 --api-key 参数传入")

    print("=" * 60)
    print("批量生成证据图标")
    print("=" * 60)

    # 确保输出目录存在
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)

    client = genai.Client(api_key=API_KEY)

    for evidence_id, config in EVIDENCE_CONFIGS.items():
        print(f"\n{'─' * 50}")
        print(f"生成: {evidence_id}")

        raw_path = EVIDENCE_DIR / f"{evidence_id}_raw_magenta.png"
        final_path = EVIDENCE_DIR / f"{evidence_id}.png"

        # 生成带紫色背景的图片
        prompt = config["prompt"]
        print(f"  提示词长度: {len(prompt)} 字符")
        print(f"  模型: {MODEL}")
        print("  正在生成...")

        try:
            response = client.models.generate_content(
                model=MODEL,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE"],
                    image_config=types.ImageConfig(
                        aspect_ratio="1:1"
                    )
                )
            )

            image_saved = False
            for part in response.candidates[0].content.parts:
                if part.inline_data:
                    with open(raw_path, "wb") as f:
                        f.write(part.inline_data.data)
                    print(f"  [OK] 原始图片已保存: {raw_path.name}")
                    image_saved = True
                    break

            if not image_saved:
                for part in response.candidates[0].content.parts:
                    if part.text:
                        print(f"  [INFO] AI回复: {part.text[:200]}")
                print(f"  [FAIL] 未生成图片")
                continue

            # 抠图
            print("  正在去除紫色背景...")
            if remove_background(raw_path, final_path):
                print(f"  [OK] 最终图片已保存: {final_path.name}")
                print(f"  文件大小: {final_path.stat().st_size / 1024:.1f} KB")
                # 删除原始紫色背景图片
                raw_path.unlink()
                print(f"  [CLEAN] 已删除原始文件")
            else:
                print(f"  [WARN] 抠图失败，保留原始文件")

        except Exception as e:
            print(f"  [ERROR] {e}")

    print(f"\n{'=' * 60}")
    print("完成！")
    print(f"输出目录: {EVIDENCE_DIR}")


if __name__ == "__main__":
    main()
