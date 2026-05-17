#!/usr/bin/env python3
"""
浔阳楼·夜雨红绸案 —— 场景背景批量生成器（Nano Banana Pro / Gemini 3 Pro Image）

依赖：
  - `~/.codebuddy/skills/AI绘图/scripts/generate_image.py`（nano-banana-pro skill）
  - 环境变量 GEMINI_API_KEY 或 --api-key 参数
  - uv（用于运行 skill 脚本）

用法：
  # 生成所有 1K 草图（约 6 张，用于审稿）
  python3 tools/generate_scenes_gemini.py --batch p0 --resolution 1K
  python3 tools/generate_scenes_gemini.py --batch all --resolution 1K

  # 指定单张
  python3 tools/generate_scenes_gemini.py --only xunyang_prologue --resolution 2K

  # 生成 2K 终稿
  python3 tools/generate_scenes_gemini.py --batch p0 --resolution 2K --final

输出：
  - 草图阶段：assets/ai_raw/scenes/<name>_draft_<ts>.png
  - 终稿阶段（--final）：assets/cn/scenes/<name>.png（统一 resize 到 1280×720）

  生成完成后还需要：
  1) 人工挑选满意稿
  2) 调用 process_ai_assets.py 或手动 import 到 Godot
  3) 在 scenes/registry.json 登记新 scene_id
"""

from __future__ import annotations
import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL_SCRIPT = Path.home() / ".codebuddy" / "skills" / "AI绘图" / "scripts" / "generate_image.py"

DRAFT_DIR = ROOT / "assets" / "ai_raw" / "scenes"
FINAL_DIR = ROOT / "assets" / "cn" / "scenes"

# ---------------------------------------------------------------------------
# 风格基底（所有场景共享，保持视觉一致性）
# ---------------------------------------------------------------------------
STYLE_BASE = (
    "Ancient Chinese Ming Dynasty Jiangnan setting, traditional ink-wash painting fused with "
    "soft cinematic lighting, painterly digital illustration. 16:9 widescreen landscape composition, "
    "no characters in frame, no text, no UI, no watermark. "
    "Color palette: ink black, deep teal, warm lantern amber, muted vermilion accents. "
    "Suitable as a 1280x720 detective-game scene background, atmospheric and storytelling."
)

# ---------------------------------------------------------------------------
# 场景清单
#   key:        生成器内部 ID（与 scene_id 对应）
#   filename:   输出文件名（不含扩展名）
#   priority:   p0=必做（满足 R1/R2）；p1=差异化提升
#   prompt:     场景独有描述（最终会拼接 STYLE_BASE）
#   register:   {scene_id, name, tags, mood, description}  用于 scenes/registry.json
# ---------------------------------------------------------------------------
SCENES = [
    {
        "key": "xunyang_prologue",
        "filename": "xunyang_prologue",
        "priority": "p0",
        "prompt": (
            "A distant cinematic establishing shot of Xunyang Pavilion at night during a soft "
            "spring rain. Multi-storey wooden pleasure tower with curved tiled roofs and red "
            "lanterns reflected on the rippling river surface. Misty rain veils the scene, "
            "willow branches sway, a lone wine flag flutters. No people. Tone: mysterious, "
            "melancholic, the calm before a crime is discovered. Wide angle, low camera near "
            "the water, layered depth from foreground reeds to pavilion silhouette to dark sky."
        ),
        "register": {
            "scene_id": "scene_xunyang_prologue",
            "name": "浔阳楼序章·夜雨远景",
            "tags": ["cinematic", "intro", "rain", "night", "exterior", "water"],
            "mood": "mysterious",
            "description": "案件序章用：江畔夜雨中的浔阳楼远景，红灯倒映水波，无人物。",
        },
    },
    {
        "key": "xunyang_courtyard",
        "filename": "xunyang_courtyard",
        "priority": "p0",
        "prompt": (
            "Close-mid shot of the rear courtyard of an ancient Chinese pleasure-house, the morning "
            "after a heavy spring rain. Wet bluestone pavement with a faint dark stain where a body "
            "fell. A torn long red silk ribbon snagged on the corner of a stone wall, fluttering in "
            "the breeze. Eaves above hold a dim wind-lantern still burning. An old stone well in the "
            "background, moss-covered. Soft overcast morning light, no people, no body in frame, "
            "only the aftermath. Tone: tragic, hushed, cold dawn."
        ),
        "register": {
            "scene_id": "scene_xunyang_courtyard",
            "name": "浔阳楼·后院（案发地）",
            "tags": ["outdoor", "courtyard", "crime_scene", "rain_aftermath", "morning"],
            "mood": "tense",
            "description": "案发后院：雨后青石板留有坠落痕迹，墙角红绸残片，屋檐风灯，老井。",
        },
    },
    {
        "key": "xunyang_qiu_chamber",
        "filename": "xunyang_qiu_chamber",
        "priority": "p0",
        "prompt": (
            "Interior of a Ming Dynasty Jiangnan courtesan's private chamber, in elegant feminine "
            "decor. Carved wooden dressing table with bronze mirror, scattered rouge and hairpins. "
            "An overturned wine cup spilling red wine on a silk handkerchief. An incense burner by "
            "the bedside still issuing a thin curl of smoke. Embroidered drapes half-open showing a "
            "lattice window with soft afternoon light. A small unsent letter on the writing desk. "
            "No people. Tone: intimate, melancholic, hints of struggle."
        ),
        "register": {
            "scene_id": "scene_xunyang_qiu_chamber",
            "name": "秋菱闺阁",
            "tags": ["indoor", "private", "feminine", "small", "evidence"],
            "mood": "intimate",
            "description": "花魁私室：妆台、倾倒酒盏、香炉、未送出的小笺。",
        },
    },
    # ---- P1 差异化提升 ----
    {
        "key": "xunyang_pavilion_main",
        "filename": "xunyang_pavilion_main",
        "priority": "p1",
        "prompt": (
            "Interior of the main hall of a Ming Dynasty riverside pleasure-tower at night. Glowing "
            "red silk lanterns hanging from carved wooden beams, a small stage with closed embroidered "
            "curtains, round dining tables with porcelain wine pots, a private booth half-curtained "
            "in the background. Warm amber and vermilion tones, hints of rain on the lattice windows. "
            "No people. Tone: warm but with an undercurrent of secrecy."
        ),
        "register": {
            "scene_id": "scene_xunyang_main_hall",
            "name": "浔阳楼·正厅",
            "tags": ["indoor", "social", "entertainment", "warm", "night"],
            "mood": "warm",
            "description": "浔阳楼内堂：红灯戏台、雅间、酒桌，夜雨打窗。",
        },
    },
    {
        "key": "xunyang_convent",
        "filename": "xunyang_convent",
        "priority": "p1",
        "prompt": (
            "A small humble Buddhist nunnery across a narrow alley from a pleasure-tower, at night. "
            "Plain wooden gate slightly ajar, a single oil lamp at a tiny window facing the street, "
            "showing the silhouette of an old altar with incense smoke. Outside: wet cobblestones, a "
            "stone Buddha statue under the eaves, faint glow of red lanterns from the tower across "
            "the street suggested at frame edge. No people. Tone: quiet, watchful, austere."
        ),
        "register": {
            "scene_id": "scene_xunyang_convent",
            "name": "慈航庵·对街小窗",
            "tags": ["indoor_outdoor", "religious", "quiet", "watchful"],
            "mood": "solemn",
            "description": "对街小庵：面街小窗、佛龛灯、外有远处红灯光晕。",
        },
    },
    {
        "key": "xunyang_yamen",
        "filename": "xunyang_yamen",
        "priority": "p1",
        "prompt": (
            "Interior of a Ming Dynasty Jiangnan prefectural courtroom (Fu Ya) at dusk. Tall vermilion "
            "pillars, the central plaque reading symbolic ancient characters (illegible / decorative). "
            "Blue stone floor, a long wooden bench with case scrolls, a tall rack holding bamboo-rod "
            "punishment tools, two flickering oil lamps casting long shadows. Through an open side "
            "screen, distant misty river. No people. Tone: official, oppressive, twilight."
        ),
        "register": {
            "scene_id": "scene_xunyang_yamen",
            "name": "江南府衙·黄昏",
            "tags": ["indoor", "official", "formal", "dusk"],
            "mood": "tense",
            "description": "江南风格府衙：朱柱、卷宗架、油灯、远江雾景。",
        },
    },
    # ─── P0+ 第二案动态扩展：新增 2 地点 ───
    {
        "key": "xunyang_riverside_dock",
        "filename": "xunyang_riverside_dock",
        "priority": "p0",
        "prompt": (
            "A small wooden riverside dock and water pavilion behind a Ming Dynasty Jiangnan pleasure-house, at dusk. "
            "Weathered wooden planks slick with rain, a tied-up flat-bottom ferry boat rocking gently, lantern hanging "
            "from a tall bamboo pole, mooring rope coiled on a stone bollard. Reflection of red lanterns from the "
            "pleasure-house above shimmers on the dark river. Distant fog hides the far shore, willow branches dip into the water. "
            "No people. Tone: liminal, secretive, between worlds — a perfect spot for disposing of evidence."
        ),
        "register": {
            "scene_id": "scene_xunyang_dock",
            "name": "浔阳楼·江畔水阁",
            "tags": ["outdoor", "water", "secret", "dusk", "transit"],
            "mood": "tense",
            "description": "浔阳楼后江畔的小码头与水阁，泊船、灯笼、雾江。可作为销证地、夜间目击点。",
        },
    },
    {
        "key": "xunyang_silk_shop",
        "filename": "xunyang_silk_shop",
        "priority": "p0",
        "prompt": (
            "Interior of a Ming Dynasty Jiangnan silk shop (布庄), mid-morning. Rolled bolts of silk in deep crimson, "
            "indigo, jade-green and ivory stacked on dark wooden shelves to the ceiling. A long lacquered counter "
            "with a brass weighing scale and an abacus. Embroidered sample pieces hang from rafters, sunlight "
            "filtering through paper lattice windows casts soft beams catching dust motes. A small back-room curtain "
            "half drawn. Tone: respectable trade with hidden ledgers, comfortable but watchful."
        ),
        "register": {
            "scene_id": "scene_xunyang_silk_shop",
            "name": "城南布庄",
            "tags": ["indoor", "trade", "evidence", "daytime"],
            "mood": "neutral",
            "description": "城南布庄内堂：成卷绸缎、铜秤算盘、绣样、内帐帘。红绸来源追溯地。",
        },
    },
]


def find_scene(key: str) -> dict | None:
    for s in SCENES:
        if s["key"] == key:
            return s
    return None


def run_one(scene: dict, resolution: str, final: bool, dry_run: bool, api_key: str | None) -> bool:
    out_dir = FINAL_DIR if final else DRAFT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)

    suffix = "" if final else f"_draft_{int(time.time())}"
    out_name = f"{scene['filename']}{suffix}.png"
    out_path = out_dir / out_name

    prompt = scene["prompt"] + "\n\n" + STYLE_BASE

    cmd = [
        "uv", "run", str(SKILL_SCRIPT),
        "--prompt", prompt,
        "--filename", out_name,
        "--resolution", resolution,
    ]
    if api_key:
        cmd += ["--api-key", api_key]

    print(f"\n── [{scene['priority']}] {scene['key']}  ({resolution}) → {out_path.relative_to(ROOT)}")
    if dry_run:
        print("    [dry-run] prompt 字符数:", len(prompt))
        print("    cmd:", " ".join(cmd[:6]) + " ...")
        return True

    # 切到输出目录运行（skill 默认保存到 cwd）
    try:
        result = subprocess.run(cmd, cwd=out_dir, capture_output=True, text=True, timeout=600)
    except subprocess.TimeoutExpired:
        print("    [TIMEOUT] 超过 600s，跳过")
        return False
    except FileNotFoundError as e:
        print(f"    [ERR] 找不到命令：{e}")
        return False

    if result.returncode != 0:
        print(f"    [FAIL] exit={result.returncode}")
        if result.stderr:
            print(result.stderr[-500:])
        return False

    if not out_path.exists():
        # skill 可能把文件保存到 cwd 下别的名字
        print(f"    [WARN] 预期文件不存在：{out_path}")
        print("    skill stdout:", result.stdout[-300:])
        return False

    # 终稿：resize 到 1280×720
    if final:
        try:
            from PIL import Image
            im = Image.open(out_path).convert("RGB")
            target = (1280, 720)
            if im.size != target:
                im = im.resize(target, Image.LANCZOS)
                im.save(out_path)
                print(f"    [OK] resized to {target}")
            else:
                print("    [OK] already 1280×720")
        except Exception as e:
            print(f"    [WARN] resize 失败: {e}")
    else:
        print("    [OK] 草图已落地")
    return True


def main():
    ap = argparse.ArgumentParser(description="批量生成浔阳楼案场景背景图")
    ap.add_argument("--batch", choices=["p0", "p1", "all"], help="批次")
    ap.add_argument("--only", action="append", help="只生成指定 key，可重复")
    ap.add_argument("--resolution", choices=["1K", "2K", "4K"], default="1K")
    ap.add_argument("--final", action="store_true", help="终稿模式：直接落到 assets/cn/scenes/ 并 resize")
    ap.add_argument("--dry-run", action="store_true", help="只打印不调用 API")
    ap.add_argument("--api-key", default=os.environ.get("GEMINI_API_KEY"),
                    help="Gemini API key（默认读 GEMINI_API_KEY 环境变量）")
    ap.add_argument("--list", action="store_true", help="列出所有场景并退出")
    args = ap.parse_args()

    if args.list:
        for s in SCENES:
            print(f"  [{s['priority']}] {s['key']:<26} → {s['filename']}.png   ({s['register']['scene_id']})")
        return

    if not args.batch and not args.only:
        print("请用 --batch p0|p1|all 或 --only <key> 指定。", file=sys.stderr)
        sys.exit(2)

    if not args.dry_run and not args.api_key:
        print("缺少 GEMINI_API_KEY（用 --api-key 或环境变量），可加 --dry-run 仅预演。", file=sys.stderr)
        sys.exit(3)

    if not args.dry_run and not SKILL_SCRIPT.exists():
        print(f"找不到 nano-banana-pro skill 脚本：{SKILL_SCRIPT}", file=sys.stderr)
        sys.exit(4)

    targets: list[dict] = []
    if args.only:
        for k in args.only:
            s = find_scene(k)
            if not s:
                print(f"未知 key：{k}", file=sys.stderr); sys.exit(2)
            targets.append(s)
    else:
        for s in SCENES:
            if args.batch == "all" or s["priority"] == args.batch:
                targets.append(s)

    print(f"准备生成 {len(targets)} 张  resolution={args.resolution}  final={args.final}  dry_run={args.dry_run}")

    ok, fail = 0, 0
    for s in targets:
        success = run_one(s, args.resolution, args.final, args.dry_run, args.api_key)
        if success:
            ok += 1
        else:
            fail += 1

    print(f"\n=== 完成：{ok} 成功 / {fail} 失败 ===")
    if args.final and ok > 0:
        print("\n下一步：")
        print("  1) 用 Godot 打开工程让 .import 文件自动生成")
        print("  2) 将以下 scene 注册到 data/scenes/registry.json（脚本已在 SCENES.register 中写好元数据）")
        for s in targets:
            print(f"     - {s['register']['scene_id']}: res://assets/cn/scenes/{s['filename']}.png")
        print("  3) 改 data/cases/xunyang_pavilion/locations.json 把 scene_type 指向新 scene_id")
        print("  4) 改 manifest.json 的 preview_image / 升级 art_status，并跑 python3 tools/regression/run_static.py")


if __name__ == "__main__":
    main()
