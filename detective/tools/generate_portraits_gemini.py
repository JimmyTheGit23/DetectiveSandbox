#!/usr/bin/env python3
"""
演员立绘批量生成器（Nano Banana Pro / Gemini 3 Pro Image）+ 紫底色键去背 + 标准化到 603×900 RGBA。

依赖：
  - `~/.codebuddy/skills/AI绘图/scripts/generate_image.py`（nano-banana-pro skill）
  - 环境变量 GEMINI_API_KEY 或 --api-key
  - uv

工作流（严格遵守紫底色键约定）：
  1. Gemini 生成纯 #FF00FF 紫底图（不要透明背景，否则色键质量差）
  2. 落到 assets/ai_raw/portraits/<key>_draft_<ts>.png
  3. --final 模式：tools/process_ai_assets.remove_magenta + autocrop + fit 到 603×900 + 居底对齐
     输出到 assets/cn/portraits/<key>.png

用法：
  python3 tools/generate_portraits_gemini.py --list
  python3 tools/generate_portraits_gemini.py --batch p0 --resolution 1K
  python3 tools/generate_portraits_gemini.py --only actor_madam_proprietress --resolution 2K --final
  python3 tools/generate_portraits_gemini.py --batch all --resolution 2K --final

  # 已有草图想直接走色键去背 + 标准化（不再调 API）：
  python3 tools/generate_portraits_gemini.py --postprocess <draft_path> --output <actor_id>
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

DRAFT_DIR = ROOT / "assets" / "ai_raw" / "portraits"
FINAL_DIR = ROOT / "assets" / "cn" / "portraits"

# 立绘标准规格（与现有 8 张一致）
PORTRAIT_W = 603
PORTRAIT_H = 900

# ---------------------------------------------------------------------------
# 风格基底：明代江南古风、半身立绘、3/4 视角、纯 #FF00FF 紫底（用于色键去背）
# ---------------------------------------------------------------------------
STYLE_BASE = (
    "Ancient Chinese Ming Dynasty Jiangnan character portrait, painterly digital illustration "
    "fused with traditional ink-wash brushwork. Half-body waist-up shot, three-quarter angle, "
    "subject facing slightly toward camera-left, eye-level framing. "
    "IMPORTANT: solid pure magenta background #FF00FF, completely flat, no gradient, no shadow on the background, "
    "background fills entire frame except the character silhouette — this background will be removed via chroma key. "
    "Sharp clean silhouette edges (no purple tint bleeding into hair / clothing). "
    "No text, no watermark, no UI, no extra characters in frame, no decorative borders, no environment elements behind subject. "
    "Lighting: soft warm key light from upper-right, gentle ambient fill. "
    "Style consistent with traditional Chinese guqin-era detective game character portraits, ink-tinted color palette."
)

# ---------------------------------------------------------------------------
# 16 个新演员清单（priority p0=最缺的标签格子；p1=锦上添花）
# ---------------------------------------------------------------------------
ACTORS = [
    # ─── P0：覆盖最严重的标签盲区 ───
    {
        "key": "actor_madam_proprietress",
        "priority": "p0",
        "display_name": "中年掌柜娘子",
        "tags": ["female", "middle", "merchant", "sharp", "worldly"],
        "description": "三十五至四十岁的酒楼/商号当家娘子。略施粉黛，目光精明，举止干练。可扮演当家娘子、老鸨、布庄掌柜娘子。",
        "voice_config": {"style": "shrewd_middle_female", "pitch": 0},
        "prompt": (
            "Half-body portrait of a 35-40 year old Ming Dynasty Jiangnan inn matron / pleasure-house proprietress. "
            "Wearing layered silk hanfu in muted plum and ivory, gold hairpin, jade earrings, hair coiled in a married-woman's bun. "
            "Expression: composed, shrewd eyes, faint knowing smile, hint of weariness. "
            "Posture: hands crossed in front, holding a small ledger book, slight forward lean as if appraising a customer. "
            "She is dignified, not seductive — the boss, not the entertainer."
        ),
    },
    {
        "key": "actor_elder_grandmother",
        "priority": "p0",
        "display_name": "老年贵妇",
        "tags": ["female", "elder", "noble", "weary", "stern"],
        "description": "六十岁上下的望族遗孀/老夫人。银发银簪，眉目威严。可扮演老夫人、退休女官、宗族长辈。",
        "voice_config": {"style": "stern_elder_female", "pitch": -2},
        "prompt": (
            "Half-body portrait of a 60-65 year old Ming Dynasty noble widow / matriarch. "
            "Silver-grey hair coiled tight under a dark widow's coif, simple silver hairpin, deeply lined face but proud bearing. "
            "Wearing dark indigo or charcoal silk hanfu with subtle plum-blossom embroidery, jade prayer beads in hand. "
            "Expression: stern, watchful, mouth set in a thin line, eyes that have seen too much. "
            "Posture: upright, one hand resting on a cane of dark wood with silver tip."
        ),
    },
    {
        "key": "actor_buddhist_nun",
        "priority": "p0",
        "display_name": "中年比丘尼",
        "tags": ["female", "middle", "religious", "austere", "secretive"],
        "description": "四十岁上下的庵主/师太。灰布僧衣，目光清冷。可扮演庵主、师太、隐姓出家女子。",
        "voice_config": {"style": "calm_middle_female", "pitch": -1},
        "prompt": (
            "Half-body portrait of a 40-45 year old Ming Dynasty Buddhist nun (bhikkhuni). "
            "Shaved head with faint stubble, plain greyish-brown monastic robe with simple wooden prayer beads around the neck. "
            "Smooth pale face, no makeup, austere beauty, slight melancholy in the eyes. "
            "Expression: quiet, serene, with a hint of secrecy — like she is hiding a past life. "
            "Posture: hands folded in dharma gesture at chest level, slight downward gaze."
        ),
    },
    {
        "key": "actor_young_servant_boy",
        "priority": "p0",
        "display_name": "少年小厮",
        "tags": ["male", "young_teen", "lowborn", "agile", "curious"],
        "description": "十三四岁的书童/小二。瘦削机灵。可扮演书童、跑堂小二、衙门小吏、客栈小厮。",
        "voice_config": {"style": "bright_youth_male", "pitch": 3},
        "prompt": (
            "Half-body portrait of a 13-14 year old Ming Dynasty Jiangnan errand boy / inn-pageboy. "
            "Skinny build, oversized brown short hanfu and a red sash at the waist, hair tied in twin top-knots like a young apprentice. "
            "Slightly tanned skin, smudge of dirt on one cheek. "
            "Expression: bright, curious, mouth half-open as if about to speak, eyes darting sideways. "
            "Posture: leaning forward, one hand holding a small wooden tea tray, the other scratching his head."
        ),
    },
    {
        "key": "actor_wealthy_merchant",
        "priority": "p0",
        "display_name": "中年富商",
        "tags": ["male", "middle", "merchant", "jovial", "greedy"],
        "description": "四十多岁的商号东家/当铺老板。富态圆润，笑里藏算盘。可扮演商号东家、当铺老板、米行东家、走私贩。",
        "voice_config": {"style": "jovial_middle_male", "pitch": -1},
        "prompt": (
            "Half-body portrait of a 40-45 year old Ming Dynasty wealthy merchant / pawnshop owner. "
            "Round-faced, slight double chin, well-groomed thin moustache and small goatee. "
            "Wearing rich brown silk hanfu trimmed with gold thread, a jade thumb-ring and a fat gold-and-jade necklace, fingers stubby. "
            "Expression: broad fake smile, narrow calculating eyes. "
            "Posture: holding an abacus in one hand, the other tucking a sleeve, slight forward bow as if greeting a customer."
        ),
    },
    {
        "key": "actor_jianghu_swordsman",
        "priority": "p0",
        "display_name": "青年游侠",
        "tags": ["male", "young", "martial", "proud", "wandering"],
        "description": "二十五六岁的镖师/游侠。身姿挺拔，一道浅疤。可扮演镖师、护院、游侠、外乡客。",
        "voice_config": {"style": "stoic_young_male", "pitch": -1},
        "prompt": (
            "Half-body portrait of a 25-27 year old Ming Dynasty Jianghu wandering swordsman / caravan guard. "
            "Broad shoulders, short topknot tied with a black ribbon, faint old scar across the right brow. "
            "Wearing a dark indigo short fighting hanfu with leather bracers, a bamboo hat slung on the back, "
            "a sheathed jian sword held vertically at the side. "
            "Expression: stoic, proud, slight frown, eyes alert. "
            "Posture: standing straight, free hand resting on sword hilt."
        ),
    },
    {
        "key": "actor_eccentric_diviner",
        "priority": "p0",
        "display_name": "老年术士",
        "tags": ["male", "elder", "religious", "eccentric", "cunning"],
        "description": "六十多岁的算命先生/阴阳师。一脸狡黠，长须飘飘。可扮演算命先生、阴阳师、神棍、巫祝。",
        "voice_config": {"style": "raspy_elder_male", "pitch": -3},
        "prompt": (
            "Half-body portrait of a 60-65 year old Ming Dynasty street fortune teller / yin-yang diviner. "
            "Long thin white beard down to chest, wispy white hair under a faded black scholar-cap, deep crow's-feet, hooked nose. "
            "Wearing a patched-up grey-blue daoist-style robe with bagua trigrams faintly embroidered, holding a tortoise-shell divination case in one hand "
            "and a folding fan with calligraphy in the other. "
            "Expression: cunning, knowing smirk, eyes sparkling with mischief. "
            "Posture: slight forward lean, as if about to whisper a prophecy."
        ),
    },
    {
        "key": "actor_courtly_lady",
        "priority": "p0",
        "display_name": "中年贵妇",
        "tags": ["female", "middle", "noble", "graceful", "proud"],
        "description": "三十五岁上下的高门夫人/官眷。气度雍容，眼神警惕。可扮演高门夫人、致仕官眷、退休女官夫人。",
        "voice_config": {"style": "refined_middle_female", "pitch": 0},
        "prompt": (
            "Half-body portrait of a 33-37 year old Ming Dynasty high-born lady / official's wife. "
            "Elaborate married-woman hairstyle with golden phoenix hairpin and pearl tassels, refined oval face, light makeup, jade pendant. "
            "Wearing layered silk ruqun in pale jade-green and ivory, intricate cloud-pattern embroidery at sleeves and collar. "
            "Expression: graceful but guarded, polite half-smile that doesn't reach the eyes. "
            "Posture: hands folded over an embroidered silk handkerchief, head turned slightly aside."
        ),
    },
    # ─── P1：进一步增加风格多样性 ───
    {
        "key": "actor_senior_prefect",
        "priority": "p1",
        "display_name": "老年知府",
        "tags": ["male", "elder", "official", "stern", "weary"],
        "description": "五十多岁的本府主官/老知府。官袍威严，世故沉重。可扮演知府、老京官、退休大员，与中年地方官区分。",
        "voice_config": {"style": "weighty_elder_male", "pitch": -2},
        "prompt": (
            "Half-body portrait of a 55-60 year old Ming Dynasty Prefect (Zhi Fu) in full court attire. "
            "Heavy silk official robe in dark crimson with embroidered rank-square (mandarin square) on the chest, black gauze official cap with stiff side wings. "
            "Long grey beard, deep-set tired eyes, heavy bags under the eyes, prominent forehead lines. "
            "Expression: weighty, stern, weary of bureaucracy. "
            "Posture: hands clasped behind a jade belt-plaque, slight forward stoop showing accumulated weight of office."
        ),
    },
    {
        "key": "actor_apothecary_doctor",
        "priority": "p1",
        "display_name": "中年药师",
        "tags": ["male", "middle", "scholar", "scholarly", "meticulous"],
        "description": "四十岁出头的药铺/医馆主人。长衫青色，手握药戥。可扮演大夫、药铺东家、仵作师傅。",
        "voice_config": {"style": "soft_scholar_male", "pitch": 0},
        "prompt": (
            "Half-body portrait of a 40-45 year old Ming Dynasty apothecary / Chinese medicine doctor. "
            "Slim build, neat dark beard, half-rim reading spectacles low on the nose, hair tied in a scholar's topknot. "
            "Wearing a deep indigo long scholar's robe with a small leather apron over it, holding a small balance scale (dengzi) in one hand and a folded prescription paper in the other. "
            "Expression: meticulous, thoughtful, lips slightly pursed. "
            "Posture: seated-style upright lean, examining the scale closely."
        ),
    },
    {
        "key": "actor_innkeeper_wife",
        "priority": "p1",
        "display_name": "中年客栈娘子",
        "tags": ["female", "middle", "lowborn", "warm", "gossipy"],
        "description": "三十多岁的客栈娘子/茶坊老板娘。圆脸热情，话多消息灵。可扮演客栈老板娘、茶坊娘子、邻里大嫂。",
        "voice_config": {"style": "warm_middle_female", "pitch": 1},
        "prompt": (
            "Half-body portrait of a 35-40 year old Ming Dynasty roadside inn proprietress / teahouse owner's wife. "
            "Round friendly face, simple bun with a single wooden hairpin, ruddy cheeks, calloused hands. "
            "Wearing a coarse cotton hanfu in russet brown with a long apron in faded indigo, sleeves rolled up. "
            "Expression: warm and chatty, big open smile, eyes crinkled, ready to gossip. "
            "Posture: holding a teapot in one hand and a wet cleaning cloth in the other, slight tilt to the left."
        ),
    },
    {
        "key": "actor_shy_handmaid",
        "priority": "p1",
        "display_name": "年轻女侍",
        "tags": ["female", "young", "lowborn", "shy", "innocent"],
        "description": "十八九岁的丫鬟/侍女。低头怯怯。可扮演大户人家丫鬟、酒楼侍女、绣楼侍女。",
        "voice_config": {"style": "soft_young_female", "pitch": 3},
        "prompt": (
            "Half-body portrait of an 18-19 year old Ming Dynasty Jiangnan maidservant working in a noble household. "
            "Slender adult build, hair in a simple low side-braid tied with a pale red ribbon, fair pale face, gentle features, no makeup. "
            "Wearing a modest pale-blue ruqun with high collar and long sleeves covering hands, a white sash and a plain cotton apron. "
            "Expression: respectful, demure, eyes lowered politely. "
            "Posture: standing upright, hands clasped in front holding a folded silk handkerchief, very poised servant pose."
        ),
    },
    {
        "key": "actor_tomboy_courier",
        "priority": "p1",
        "display_name": "青年女镖客",
        "tags": ["female", "young", "martial", "spirited", "loyal"],
        "description": "二十四五岁的女镖师/女江湖客。英气勃发。可扮演女镖师、女护卫、客栈女打手、走江湖的姑娘。",
        "voice_config": {"style": "spirited_young_female", "pitch": 0},
        "prompt": (
            "Half-body portrait of a 24-25 year old Ming Dynasty Jianghu female courier / female caravan guard. "
            "Healthy tanned skin, hair pulled back in a high ponytail with a red ribbon, sharp eyebrows, no makeup. "
            "Wearing a snug fitted indigo short fighting hanfu trimmed with leather, cross-body belt with throwing-darts pouch, "
            "a short broadsword (dao) sheathed at the hip. "
            "Expression: spirited, smirking confidently, eyes bright. "
            "Posture: hand on hip, the other resting casually on sword hilt."
        ),
    },
    {
        "key": "actor_drunken_poet",
        "priority": "p1",
        "display_name": "中年落魄文人",
        "tags": ["male", "middle", "scholar", "dissolute", "perceptive"],
        "description": "四十岁上下的失意文人/醉书生。胡子拉碴，半醉半醒。可扮演落魄秀才、酒楼常客、街头说书人、隐姓京官。",
        "voice_config": {"style": "slurred_middle_male", "pitch": -1},
        "prompt": (
            "Half-body portrait of a 40-44 year old Ming Dynasty failed scholar / dissolute poet. "
            "Unkempt beard stubble, messy half-undone topknot, faint flush of wine on cheeks and nose, slightly bloodshot eyes. "
            "Wearing a wrinkled faded grey scholar's robe with a wine stain on the chest, sash loose, holding a small wine gourd in one hand "
            "and an open scroll of poetry in the other. "
            "Expression: half-drunk smirk, but eyes underneath are unexpectedly perceptive and sad. "
            "Posture: leaning slightly to one side as if barely standing, sleeves askew."
        ),
    },
    {
        "key": "actor_foreign_traveler",
        "priority": "p1",
        "display_name": "西域旅人",
        "tags": ["male", "middle", "merchant", "exotic", "wary"],
        "description": "三十多岁的外族商人/西域客。深目高鼻，络腮胡。可扮演西域胡商、北疆来客、丝路使者，提供异邦视角。",
        "voice_config": {"style": "accented_middle_male", "pitch": -1},
        "prompt": (
            "Half-body portrait of a 33-38 year old Central Asian / Silk Road merchant traveling in late Ming Dynasty Jiangnan. "
            "Tan skin, deep-set eyes, prominent nose, full curly beard, hair under a colorful round embroidered cap. "
            "Wearing a cross-collar Central Asian robe in deep red and gold trim, a wide leather belt with a curved knife and pouch of foreign coins. "
            "Expression: wary, observant, slightly guarded, polite half-smile. "
            "Posture: one hand at the belt buckle, the other holding the strap of a rolled silk bolt over the shoulder."
        ),
    },
    {
        "key": "actor_opera_performer",
        "priority": "p1",
        "display_name": "青年戏子",
        "tags": ["male", "young", "performer", "androgynous", "beautiful"],
        "description": "二十出头的旦角戏子。眉眼细腻，男装女相。可扮演戏班名角、变装侦察、男旦、走唱艺人。",
        "voice_config": {"style": "soft_androgynous_male", "pitch": 2},
        "prompt": (
            "Half-body portrait of a 21-22 year old Ming Dynasty male opera performer specializing in Dan (female-role) parts, in offstage attire. "
            "Slim androgynous build, long black hair half-pinned with a single jade hairpin, pale fine features, faint stage-makeup remnants around the eyes. "
            "Wearing a soft pale-pink and silver scholar-style hanfu, holding a folding fan painted with peonies. "
            "Expression: beautifully ambiguous, faint enigmatic smile, eyes lowered demurely. "
            "Posture: graceful, weight on one leg, sleeve held mid-air mid-gesture as if pausing a performance pose."
        ),
    },
]


def find_actor(key: str) -> dict | None:
    for a in ACTORS:
        if a["key"] == key:
            return a
    return None


# ---------------------------------------------------------------------------
# 后处理：色键 + 标准化
# ---------------------------------------------------------------------------
def postprocess_to_portrait(src: Path, out: Path) -> None:
    """紫底色键去背 + autocrop + 缩放到 603x900 RGBA（保持比例 + 居底对齐）。"""
    sys.path.insert(0, str(ROOT / "tools"))
    from process_ai_assets import remove_magenta, autocrop  # type: ignore
    from PIL import Image
    img = Image.open(src)
    img = remove_magenta(img)
    img = autocrop(img, padding=4)
    src_w, src_h = img.size
    scale = min(PORTRAIT_W / src_w, PORTRAIT_H / src_h)
    new_w = max(1, int(src_w * scale))
    new_h = max(1, int(src_h * scale))
    # 立绘是写实风（非像素），用 LANCZOS 而不是 NEAREST
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (PORTRAIT_W, PORTRAIT_H), (0, 0, 0, 0))
    # 居底对齐：人物贴底，便于 UI 中显示
    paste_x = (PORTRAIT_W - new_w) // 2
    paste_y = PORTRAIT_H - new_h
    canvas.paste(resized, (paste_x, paste_y), resized)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, "PNG")
    print(f"    [postprocess] → {out.relative_to(ROOT)}  ({PORTRAIT_W}x{PORTRAIT_H} RGBA)")


# ---------------------------------------------------------------------------
def run_one(actor: dict, resolution: str, final: bool, dry_run: bool, api_key: str | None) -> bool:
    DRAFT_DIR.mkdir(parents=True, exist_ok=True)
    FINAL_DIR.mkdir(parents=True, exist_ok=True)

    prompt = actor["prompt"] + "\n\n" + STYLE_BASE
    suffix = f"_draft_{int(time.time())}"
    raw_name = f"{actor['key']}{suffix}.png"
    raw_path = DRAFT_DIR / raw_name

    cmd = [
        "uv", "run", str(SKILL_SCRIPT),
        "--prompt", prompt,
        "--filename", raw_name,
        "--resolution", resolution,
    ]
    if api_key:
        cmd += ["--api-key", api_key]

    print(f"\n── [{actor['priority']}] {actor['key']}  ({resolution}) → {raw_path.relative_to(ROOT)}")
    if dry_run:
        print(f"    [dry-run] prompt 字符数: {len(prompt)}")
        return True

    try:
        result = subprocess.run(cmd, cwd=DRAFT_DIR, capture_output=True, text=True, timeout=600)
    except subprocess.TimeoutExpired:
        print("    [TIMEOUT]")
        return False
    except FileNotFoundError as e:
        print(f"    [ERR] {e}")
        return False

    if result.returncode != 0 or not raw_path.exists():
        print(f"    [FAIL] exit={result.returncode}")
        if result.stderr:
            print(result.stderr[-500:])
        return False
    print("    [OK] 紫底草图已落地")

    if final:
        final_path = FINAL_DIR / f"{actor['key']}.png"
        try:
            postprocess_to_portrait(raw_path, final_path)
        except Exception as e:
            print(f"    [WARN] 后处理失败: {e}")
            return False
    return True


def main():
    ap = argparse.ArgumentParser(description="批量生成新演员立绘并去除紫底")
    ap.add_argument("--batch", choices=["p0", "p1", "all"], help="批次")
    ap.add_argument("--only", action="append", help="只生成指定 actor key，可重复")
    ap.add_argument("--resolution", choices=["1K", "2K", "4K"], default="1K")
    ap.add_argument("--final", action="store_true", help="终稿模式：色键+缩放并落 assets/cn/portraits/")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--api-key", default=os.environ.get("GEMINI_API_KEY"))
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--postprocess", help="只对已有草图做色键去背")
    ap.add_argument("--output", help="配合 --postprocess 用，actor key（输出到 assets/cn/portraits/<key>.png）")
    args = ap.parse_args()

    if args.list:
        for a in ACTORS:
            tag_str = "/".join(a["tags"][:3])
            print(f"  [{a['priority']}] {a['key']:<32} {tag_str:<28} {a['display_name']}")
        return

    if args.postprocess:
        if not args.output:
            print("--postprocess 需要 --output <actor_key>", file=sys.stderr); sys.exit(2)
        out_path = FINAL_DIR / f"{args.output}.png"
        postprocess_to_portrait(Path(args.postprocess), out_path)
        return

    if not args.batch and not args.only:
        print("用 --batch p0|p1|all 或 --only <key>", file=sys.stderr); sys.exit(2)

    if not args.dry_run and not args.api_key:
        print("缺少 GEMINI_API_KEY", file=sys.stderr); sys.exit(3)

    if not args.dry_run and not SKILL_SCRIPT.exists():
        print(f"找不到 skill 脚本：{SKILL_SCRIPT}", file=sys.stderr); sys.exit(4)

    targets: list[dict] = []
    if args.only:
        for k in args.only:
            a = find_actor(k)
            if not a:
                print(f"未知 key：{k}", file=sys.stderr); sys.exit(2)
            targets.append(a)
    else:
        for a in ACTORS:
            if args.batch == "all" or a["priority"] == args.batch:
                targets.append(a)

    print(f"准备生成 {len(targets)} 个立绘  resolution={args.resolution}  final={args.final}")
    ok, fail = 0, 0
    for a in targets:
        if run_one(a, args.resolution, args.final, args.dry_run, args.api_key):
            ok += 1
        else:
            fail += 1
    print(f"\n=== 完成：{ok} 成功 / {fail} 失败 ===")
    if args.final and ok > 0:
        print("\n下一步：")
        print("  1) 查看 assets/cn/portraits/，必要时 nano-banana-pro 改 prompt 重生")
        print("  2) 运行 tools/register_new_actors.py 注册到 data/actors/registry.json（或手动）")
        print("  3) python3 tools/regression/run_static.py")


if __name__ == "__main__":
    main()
