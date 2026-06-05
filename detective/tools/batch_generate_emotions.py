#!/usr/bin/env python3
"""
批量生成角色表情变体（二次元风格）。
使用凌瑶立绘作为风格参考，通过 generate_gemini_art_asset.py 生成。
"""
from __future__ import annotations
import os
import subprocess
import sys
from pathlib import Path

from portrait_generation_spec import (
    NPC_KNEE_UP_SPEC,
    chroma_background_phrase,
    chroma_for_character,
)

ROOT = Path(__file__).resolve().parent.parent
STYLE_REF = "assets/cn/portraits/companion_lingyao.png"
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")

# ─── 角色基础描述 ───
CHARACTERS = {
    "agui": {
        "name": "阿贵",
        "desc": "Chinese servant (阿贵), around 40 years old. Thin face with hollow cheeks, but NOT scary or creepy — tired beaten-down man, soft worried eyes, small neat goatee. Hair in simple topknot. Worn grey-blue patched servant robes with visible mends, cloth sash at waist.",
    },
    "zhou_wife": {
        "name": "周氏",
        "desc": "Chinese woman (周氏) in Ming Dynasty mourning attire, around 35 years old. Oval face with slightly prominent cheekbones suggesting strong will. Almond-shaped eyes with downturned outer corners giving a perpetual look of sorrow, but sharp and shrewd pupils revealing her merchant's acumen. Willow-leaf eyebrows with a deep furrow between them from constant worry. Straight nose with slightly wide nostrils suggesting good fortune. Thin lips with corners turned down, hinting at both bitterness and grief. Fair skin with a small mole below her left eye (tear mole) and faint freckles across the bridge of her nose. Hair parted in the middle, pulled back in a simple bun with a few loose strands framing her face, held by a plain wooden hairpin. White mourning robe with round collar.",
    },
    "li_zheng": {
        "name": "钱里正",
        "desc": "Chinese local official (钱里正), around 50 years old. Round chubby face, small shrewd eyes, double chin, slightly balding under small black official cap. Portly build. Dark blue-grey minor official robe, round collar, white inner collar, black belt.",
    },
    "shen_qingyue": {
        "name": "沈清月",
        "desc": "Beautiful young Chinese woman (沈清月), 22 years old, wealthy merchant family. Sharp intelligent eyes, refined jawline, composed expression. Long black hair in half-updo with hairpin. Elegant maroon/dark red cross-collar robe with black trim, brown leather belt with embroidered floral pouch at waist.",
    },
}

# ─── 表情变体定义 ───
EMOTIONS = {
    "agui": [
        ("broken", "Expression: completely broken and defeated, face contorted with anguish, tears streaming, mouth open in a cry of despair. The look of a man whose mask has shattered. One hand gripping his chest."),
        ("collapsed", "Expression: collapsed and broken, slumped posture, eyes vacant and unfocused, face pale. The look of a man who has given up entirely."),
        ("confrontation_collapsed", "Expression: during confrontation — collapsing under pressure, face crumbling, tears welling, hands trembling. The moment before total breakdown."),
        ("confrontation_shaken", "Expression: during confrontation — deeply shaken, eyes wide with fear, sweating, mouth trembling. Being pressed hard and losing composure."),
        ("confrontation", "Expression: during confrontation — nervous and defensive, eyes darting, brow furrowed, hands clasped tightly. Trying to maintain his story under pressure."),
        ("crying", "Expression: openly crying, tears streaming down his thin face, eyes red and swollen, mouth twisted with grief. The look of a man releasing years of pent-up sorrow."),
        ("nervous", "Expression: very nervous and anxious, eyes darting sideways, brow furrowed with worry, jaw tight, a muscle visible in his cheek. Sweat bead on temple."),
        ("shaken", "Expression: shaken and unsteady, eyes unfocused, face pale, mouth slightly open as if about to stammer. The look of a man whose composure is cracking."),
        ("shocked", "Expression: shocked and stunned, eyes wide open, mouth agape, face frozen. The look of someone who has just heard something devastating."),
    ],
    "zhou_wife": [
        ("screaming", "Expression: screaming in grief and rage, mouth wide open, eyes squeezed shut with tears, face red with emotion. One hand raised in an accusatory gesture, the other clutching her chest. Raw, uncontrolled grief. Tear mole visible on left cheek."),
        ("silent", "Expression: silent grief — eyes downcast, face pale and drawn, lips pressed into a thin line. No tears visible but the pain is evident. Quiet, dignified suffering. Tear mole visible through hair strands."),
        ("trembling", "Expression: trembling with suppressed emotion, lips quivering, eyes glistening with unshed tears, hands shaking. The look of someone barely holding it together. Tear mole accentuating her sorrow."),
        ("accusing", "Expression: finger pointing accusingly, eyes blazing with anger and grief, mouth set in a firm line of accusation. Tear mole prominent on left cheek. Posture rigid with righteous fury."),
        ("suspicious", "Expression: eyes narrowed with suspicion, head tilted slightly, one eyebrow raised, lips pressed together in a thin line of doubt. Tear mole visible as she studies someone intently."),
        ("interrogating", "Expression: leaning forward aggressively, eyes sharp and piercing, mouth open mid-question, hands gesturing emphatically. Tear mole accentuating her intense focused expression."),
        ("relieved", "Expression: softened expression, eyes still red but with a glimmer of peace, lips slightly parted in a sigh of relief. Tear mole visible as tension leaves her face, shoulders relaxing."),
    ],
    "li_zheng": [
        ("evasive", "Expression: evasive and uncomfortable, eyes avoiding direct contact, forced smile, sweating slightly. The look of a man who knows more than he's saying but doesn't want to get involved."),
        ("gossip", "Expression: gossiping — leaning in with excitement, eyes gleaming with information, mouth forming words eagerly, one hand cupped near mouth. The look of someone sharing juicy secrets."),
        ("nervous", "Expression: nervous and sweating, eyes darting around, forced smile, hands clasped together. The look of a man caught between wanting to help and fearing trouble."),
        ("shocked", "Expression: shocked with mouth open, eyes wide, round face even rounder with surprise. Hands raised in a defensive gesture."),
        ("sighing", "Expression: sighing heavily, shoulders slumped, eyes half-closed, mouth forming a weary 'oh well' expression. The look of a man resigned to trouble."),
        ("stern", "Expression: attempting to look stern and authoritative, brow furrowed, mouth set in a firm line — but it doesn't quite work on his round cheerful face. Trying to be serious."),
    ],
    "shen_qingyue": [
        ("bold", "Expression: bold and fearless, arms crossed, chin raised, confident smirk. The look of someone who believes she has nothing to hide. Bold posture, direct eye contact."),
        ("broken", "Expression: the mask finally cracking — eyes glistening with tears, lips trembling, face showing genuine pain for the first time. The mention of her father has broken through her defenses."),
        ("cold_fury", "Expression: ice-cold fury — eyes like frozen daggers, jaw set, no trace of warmth. The real person beneath the mask. Extremely dangerous and composed."),
        ("cold_smile", "Expression: cold calculated smile — lips curved but eyes completely cold. The smile of someone who knows she's winning. Chilling rather than warm."),
        ("confrontation", "Expression: during confrontation — maintaining composure under pressure, one eyebrow slightly raised, lips pressed together thoughtfully. Calculating her next move."),
        ("cooperative", "Expression: cooperative and forthcoming — open posture, hands visible, slight smile. The performance of someone who has nothing to hide. Very convincing."),
        ("cracking", "Expression: composure beginning to crack — micro-expressions flickering, eyes briefly losing their practiced calm, a slight tightening around the mouth."),
        ("deflecting", "Expression: deflecting a question — head tilted slightly, eyes shifting, one hand raised in a dismissive gesture. Skillfully redirecting the conversation."),
        ("sharp", "Expression: sharp and cutting — eyes narrowed, lips parted in a cutting retort, one finger pointed. The look of someone fighting back hard."),
        ("victory", "Expression: victory and triumph — composed smile, eyes gleaming with satisfaction, posture relaxed and confident. The look of someone who has just won."),
    ],
}


def gen_one(char_key: str, emotion_key: str, emotion_desc: str, dry_run: bool = False) -> None:
    char = CHARACTERS[char_key]
    chroma = chroma_for_character(char_key, char["desc"])
    filename = f"prologue_{char_key}_{emotion_key}.png"
    raw_path = f"assets/ai_raw/portraits/{char_key}_{emotion_key}_newstyle.png"
    transparent_path = f"assets/ai_raw/portraits/{char_key}_{emotion_key}_newstyle_transparent.png"
    output_path = f"assets/cn/portraits/{filename}"

    prompt = (
        f"Draw a character in the EXACT SAME art style as the reference image. "
        f"Keep the same clean anime line art, large expressive eyes, smooth cel-shading, vibrant colors. "
        f"But this is a DIFFERENT character: {char['desc']} "
        f"{emotion_desc} "
        f"{NPC_KNEE_UP_SPEC.framing_prompt} "
        f"{chroma_background_phrase(chroma)} No text, no watermark."
    )

    cmd = [
        sys.executable, "tools/generate_gemini_art_asset.py",
        "--output", raw_path,
        "--aspect-ratio", "2:3",
        "--reference", STYLE_REF,
        "--chroma", chroma,
        "--remove-chroma",
        "--api-key", API_KEY,
        "--prompt", prompt,
    ]

    if dry_run:
        print(f"[DRY] {filename}: {emotion_key}")
        return

    print(f"\n=== Generating {filename} ===")
    result = subprocess.run(cmd, cwd=str(ROOT), capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  [FAIL] {result.stderr[:200]}")
        return

    # Post-process
    pp_cmd = [
        sys.executable, "tools/postprocess_portrait.py",
        transparent_path, output_path,
        "--target-width", str(NPC_KNEE_UP_SPEC.canvas_width),
        "--target-height", str(NPC_KNEE_UP_SPEC.canvas_height),
        "--padding", str(NPC_KNEE_UP_SPEC.crop_padding),
    ]
    result2 = subprocess.run(pp_cmd, cwd=str(ROOT), capture_output=True, text=True)
    if result2.returncode == 0:
        print(f"  [OK] → {output_path}")
    else:
        print(f"  [POSTPROCESS FAIL] {result2.stderr[:200]}")


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--char", choices=list(CHARACTERS.keys()), help="只生成指定角色")
    ap.add_argument("--emotion", help="只生成指定表情")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()

    if args.list:
        for ck, emotions in EMOTIONS.items():
            print(f"\n{CHARACTERS[ck]['name']} ({ck}):")
            for ek, _ in emotions:
                print(f"  - prologue_{ck}_{ek}.png")
        return

    for ck, emotions in EMOTIONS.items():
        if args.char and ck != args.char:
            continue
        for ek, ed in emotions:
            if args.emotion and ek != args.emotion:
                continue
            gen_one(ck, ek, ed, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
