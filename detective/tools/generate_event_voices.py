"""为 day_events.json 中的事件叙述生成语音。
输出：assets/cn/voices/_events/{event_id}_{index}.wav

支持 narration item:
- 字符串：旁白音色
- dict: {speaker, text, voice_path}
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
DAY_EVENTS = ROOT / "data/cases/linchuan_inn/day_events.json"
OUT_DIR = ROOT / "assets/cn/voices/_events"

VOICE_BY_SPEAKER = {
    "赵大有": ("Algenib", "你是临川驿的老驿丞赵大有，因为发现命案而惊魂未定。请用紧张、苍老、沙哑的男性老人语气朗读。"),
    "赵大有 · 临川驿驿丞": ("Algenib", "你是临川驿的老驿丞赵大有，因为发现命案而惊魂未定。请用紧张、苍老、沙哑的男性老人语气朗读。"),
    "马三": ("Orus", "你是临川县衙捕头马三，直率粗犷但心中有正义。请用压低声音的中年男性捕快语气朗读。"),
    "苏婉": ("Achernar", "你是死者沈砚秋的未婚妻苏婉，悲痛而压抑。请用轻柔颤抖的年轻女子语气朗读。"),
    "顾清玄": ("Enceladus", "你是神秘白衣公子顾清玄，气定神闲。请用从容神秘的青年男子语气朗读。"),
    "旁白": ("Charon", "你是明清古典话本的男性旁白者。请用沉静客观的旁白语气朗读。"),
    "": ("Charon", "你是明清古典话本的男性旁白者。请用沉静客观的旁白语气朗读。"),
}


def clean_text(text: str) -> str:
    text = re.sub(r"（[^）]*）", "", text)
    text = re.sub(r"【[^】]*】", "", text)
    return text.strip().strip("「」")


def write_wav(path: Path, pcm: bytes):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(24000)
        wf.writeframes(pcm)


def synth(client, voice: str, prompt: str) -> bytes:
    resp = client.models.generate_content(
        model=MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_modalities=["AUDIO"],
            speech_config=types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=voice)
                )
            ),
        ),
    )
    return resp.candidates[0].content.parts[0].inline_data.data


def main():
    if not API_KEY:
        raise RuntimeError("请设置 GEMINI_API_KEY 或 GOOGLE_API_KEY")
    data = json.load(open(DAY_EVENTS, encoding="utf-8"))
    client = genai.Client(api_key=API_KEY)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for evt in data.get("events", []):
        evt_id = evt.get("id", "")
        for idx, item in enumerate(evt.get("narration", [])):
            if isinstance(item, str):
                speaker, text = "旁白", item
                out_path = OUT_DIR / f"{evt_id}_{idx}.wav"
            else:
                speaker = item.get("speaker", "旁白")
                text = item.get("text", "")
                vp = item.get("voice_path", "")
                out_path = ROOT / vp.replace("res://", "") if vp else OUT_DIR / f"{evt_id}_{idx}.wav"
            cleaned = clean_text(text)
            if not cleaned:
                continue
            if out_path.exists():
                print("skip", out_path.name)
                continue
            voice, role = VOICE_BY_SPEAKER.get(speaker, VOICE_BY_SPEAKER[""])
            prompt = f"{role}\n\n只朗读引号内文字，不要朗读括号提示：\n「{cleaned}」"
            print("▶", evt_id, idx, speaker, cleaned[:30])
            pcm = synth(client, voice, prompt)
            write_wav(out_path, pcm)
            time.sleep(0.5)
    print("done")


if __name__ == "__main__":
    main()
