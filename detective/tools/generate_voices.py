"""批量为所有 NPC 对话台词生成 TTS 音频。
- 扫描 data/dialogues/*.json + data/prologue.json
- 按角色音色配置调用 Gemini TTS
- 输出到 assets/cn/voices/{npc_id}/{node_id}.wav
- 已存在的文件跳过（增量）
"""
from __future__ import annotations
import json
import os
import re
import time
import wave
from pathlib import Path

from google import genai
from google.genai import types

API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
MODEL = "gemini-2.5-flash-preview-tts"

ROOT = Path(__file__).resolve().parent.parent
ACTIVE_CASE = "linchuan_inn"
DIALOG_DIR = ROOT / f"data/cases/{ACTIVE_CASE}/dialogues"
PROLOGUE = ROOT / f"data/cases/{ACTIVE_CASE}/prologue.json"
OUT_DIR = ROOT / "assets/cn/voices"

# 每个 NPC 的音色配置 + 默认情绪
# 注意：声音来自 30 个内置音色，男女分类参考 https://gemini-tts.com/voices
VOICE_CONFIG = {
    # 男声
    "lu_zhao":      {"voice": "Iapetus",     "gender": "M", "tone": "用沉稳清亮的年轻男性官员语气，平静坚定地"},
    "liu_wenqing":  {"voice": "Algieba",     "gender": "M", "tone": "用温和但带一丝戒备的中年男性官员语气，略沙哑地"},
    "zhao_dayou":   {"voice": "Algenib",     "gender": "M", "tone": "用紧张害怕、苍老沙哑的男性老人语气"},
    "gu_qingxuan":  {"voice": "Enceladus",   "gender": "M", "tone": "用从容神秘、低沉气声的青年男子语气"},
    "daoming":      {"voice": "Sadaltager",  "gender": "M", "tone": "用平和清明、缓慢沉稳的年迈男性僧人语气"},
    "ma_san":       {"voice": "Orus",        "gender": "M", "tone": "用直率粗犷、压低声音的中年男性捕快语气"},
    # 女声
    "su_wan":       {"voice": "Achernar",    "gender": "F", "tone": "用悲伤压抑、声音轻柔颤抖的年轻女子语气"},
    "xiao_cui":     {"voice": "Aoede",       "gender": "F", "tone": "用哀婉柔弱、轻声细语的年轻女子语气"},
    # 旁白
    "_narrator":    {"voice": "Charon",      "gender": "M", "tone": "用沉静客观的男性旁白语气，平静地"},
}


def safe_name(s: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_]+", "_", s)


def clean_text_for_tts(text: str) -> str:
    """从对话文本中去除括号内的舞台指示（如「（皱眉）」），
    避免 TTS 把它念出来。但保留主体内容。"""
    # 去掉中括号、括号内的描述性提示
    text = re.sub(r"（[^）]*）", "", text)
    text = re.sub(r"\([^\)]*\)", "", text)
    text = re.sub(r"【[^】]*】", "", text)
    return text.strip()


# 角色身份背景（统一加在 prompt 前面，让 TTS 演绎更稳定一致）
CHARACTER_BG = {
    "lu_zhao":     "你是明朝的青年御史陆昭，正在查案。",
    "liu_wenqing": "你是明朝的中年知县柳文卿，外表谦和但心中有鬼，正在应对御史的询问。",
    "su_wan":      "你是死者沈砚秋的未婚妻苏婉，悲痛欲绝。",
    "zhao_dayou":  "你是临川驿的老驿丞赵大有，因为发现命案而惊魂未定。",
    "gu_qingxuan": "你是一位神秘的白衣青年公子顾清玄，气定神闲，似乎别有目的。",
    "xiao_cui":    "你是春风楼的花魁小翠，性情温婉，对死者沈砚秋有情。",
    "daoming":     "你是观音庙的年迈住持道明法师，言谈平和清明。",
    "ma_san":      "你是临川县衙的捕头马三，性情直率粗犷，但心中有正义。",
    "_narrator":   "你是一位明清古典话本的男性旁白者，平静沉稳。",
}


def build_prompt(role_bg: str, tone: str, text: str) -> str:
    """组合提示词。明确告知 TTS 角色身份 + 语气 + 朗读内容。"""
    if not text:
        return ""
    return f"{role_bg}\n\n请{tone}朗读下面这段话（只朗读引号之间的文字，不要朗读引号本身和括号里的舞台提示）：\n\n「{text}」"


def synth(client, voice_name: str, prompt: str) -> bytes:
    """调用 TTS API，返回 PCM 字节。带重试。"""
    last_err = None
    for attempt in range(3):
        try:
            resp = client.models.generate_content(
                model=MODEL,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(
                        voice_config=types.VoiceConfig(
                            prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=voice_name)
                        )
                    ),
                ),
            )
            return resp.candidates[0].content.parts[0].inline_data.data
        except Exception as e:
            last_err = e
            print(f"    ! attempt {attempt+1} failed: {e}")
            time.sleep(2 + attempt * 2)
    raise RuntimeError(f"TTS failed after 3 attempts: {last_err}")


def write_wav(path: Path, pcm: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(24000)
        wf.writeframes(pcm)


def node_text_for_tts(node: dict) -> str:
    """节点可能使用 text 或 text_variants。运行时只按 node_id 播一个 wav，
    因此优先取 default variant；没有 default 则取第一条 variant。"""
    text = node.get("text", "")
    if text:
        return text
    variants = node.get("text_variants", [])
    if isinstance(variants, list):
        for v in variants:
            if v.get("default") and v.get("text"):
                return v.get("text", "")
        for v in variants:
            if v.get("text"):
                return v.get("text", "")
    return ""


def process_npc_dialog(client, npc_id: str, json_path: Path) -> None:
    cfg = VOICE_CONFIG.get(npc_id)
    if not cfg:
        print(f"  ! 跳过 {npc_id}（未配置音色）")
        return
    with json_path.open(encoding="utf-8") as f:
        tree = json.load(f)
    nodes = tree.get("nodes", {})
    out_dir = OUT_DIR / npc_id
    print(f"\n=== {npc_id}（{cfg['voice']}） ===")
    for node_id, node in nodes.items():
        text = node_text_for_tts(node)
        cleaned = clean_text_for_tts(text)
        if not cleaned:
            continue
        out_path = out_dir / f"{safe_name(node_id)}.wav"
        if out_path.exists():
            print(f"  • skip {node_id} (exists)")
            continue
        prompt = build_prompt(CHARACTER_BG.get(npc_id, ""), cfg["tone"], cleaned)
        print(f"  ▶ {node_id}: {cleaned[:30]}...")
        pcm = synth(client, cfg["voice"], prompt)
        write_wav(out_path, pcm)
        time.sleep(0.5)  # 轻微限速避免 429


def process_prologue(client) -> None:
    if not PROLOGUE.exists():
        return
    with PROLOGUE.open(encoding="utf-8") as f:
        tree = json.load(f)
    nodes = tree.get("nodes", {})
    out_dir = OUT_DIR / "_prologue"
    print("\n=== 序章（按 speaker 分配音色） ===")
    for node_id, node in nodes.items():
        text = node.get("text", "")
        cleaned = clean_text_for_tts(text)
        if not cleaned:
            continue
        speaker = node.get("speaker", "").strip()
        # speaker 为空 = 旁白
        if speaker == "":
            cfg = VOICE_CONFIG["_narrator"]
        elif speaker == "陆昭":
            cfg = VOICE_CONFIG["lu_zhao"]
        else:
            cfg = VOICE_CONFIG["_narrator"]
        out_path = out_dir / f"{safe_name(node_id)}.wav"
        if out_path.exists():
            print(f"  • skip {node_id} (exists)")
            continue
        # 序章里如果 speaker 是陆昭，用陆昭背景；否则用旁白背景
        bg_key = "lu_zhao" if speaker == "陆昭" else "_narrator"
        prompt = build_prompt(CHARACTER_BG.get(bg_key, ""), cfg["tone"], cleaned)
        print(f"  ▶ {node_id} [{speaker or '旁白'}]: {cleaned[:30]}...")
        pcm = synth(client, cfg["voice"], prompt)
        write_wav(out_path, pcm)
        time.sleep(0.5)


def main():
    if not API_KEY:
        raise RuntimeError("请先设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
    client = genai.Client(api_key=API_KEY)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # 序章
    process_prologue(client)

    # 各 NPC
    for json_path in sorted(DIALOG_DIR.glob("*.json")):
        npc_id = json_path.stem
        process_npc_dialog(client, npc_id, json_path)

    print("\n✓ Done.")


if __name__ == "__main__":
    main()
