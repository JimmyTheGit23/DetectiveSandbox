#!/usr/bin/env python3
"""Gemini TTS 案件级语音生成工具。

设计目标：
- 每个案件单独配置 `data/cases/<case>/voice_profiles.json`。
- 每个身份角色在配音前必须定义：性别、年龄、性格、基础语气、Gemini voice_name。
- 每个 dialogue node / prologue node / event line 可额外定义单句语气。
- 输出路径严格遵循 AssetResolver：
  - 对话：assets/cn/voices/{actor_id}/{case_id}/{node_id}.wav
  - 序章：assets/cn/voices/_prologue/{case_id}/{node_id}.wav
  - 事件：assets/cn/voices/_events/{case_id}/{evt_id}_{idx}.wav

用法：
  GEMINI_API_KEY=xxx .venv-tts/bin/python tools/generate_gemini_case_voices.py --case xunyang_pavilion --dry-run --limit 5
  GEMINI_API_KEY=xxx .venv-tts/bin/python tools/generate_gemini_case_voices.py --case xunyang_pavilion --only-missing
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import time
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    from google import genai
    from google.genai import types
except Exception as e:  # pragma: no cover
    print("请先安装 google-genai：.venv-tts/bin/pip install google-genai", file=sys.stderr)
    raise

ROOT = Path(__file__).resolve().parent.parent
VOICE_ROOT = ROOT / "assets/cn/voices"
DEFAULT_MODEL = "gemini-2.5-flash-preview-tts"


@dataclass
class VoiceJob:
    kind: str  # dialogue / prologue / event
    case_id: str
    node_id: str
    text: str
    out_path: Path
    npc_id: str = ""
    actor_id: str = "_narrator"
    role_key: str = "_narrator"
    tone_key: str = ""


# ─── helpers ───────────────────────────────────────────────────────────────

def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def safe_name(s: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_]+", "_", s)


def clean_text_for_tts(text: str) -> str:
    """去舞台提示，但整句括号旁白保留内容。"""
    text = (text or "").strip()
    m = re.fullmatch(r"（([^）]+)）", text) or re.fullmatch(r"\(([^\)]+)\)", text)
    if m:
        text = m.group(1)
    else:
        text = re.sub(r"（[^）]*）", "", text)
        text = re.sub(r"\([^\)]*\)", "", text)
    text = re.sub(r"【[^】]*】", "", text)
    text = text.replace("「", "").replace("」", "")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def node_text_for_tts(node: dict[str, Any]) -> str:
    text = node.get("text", "")
    if text:
        return clean_text_for_tts(text)
    variants = node.get("text_variants", [])
    if isinstance(variants, list) and variants:
        for v in variants:
            if isinstance(v, dict) and v.get("id") == "default" and v.get("text"):
                return clean_text_for_tts(v["text"])
        first = variants[0]
        if isinstance(first, dict):
            return clean_text_for_tts(first.get("text", ""))
    return ""


def write_wav(path: Path, pcm: bytes, sample_rate: int = 24000) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(pcm)


# ─── profile / prompt ──────────────────────────────────────────────────────

def role_profile(profiles: dict[str, Any], role_key: str) -> dict[str, Any]:
    if role_key == "_narrator":
        return profiles.get("narrator", {})
    return profiles.get("roles", {}).get(role_key, profiles.get("narrator", {}))


def line_tone(profiles: dict[str, Any], job: VoiceJob, prof: dict[str, Any]) -> str:
    if job.kind == "dialogue":
        return prof.get("line_tones", {}).get(job.node_id, "")
    if job.kind == "prologue":
        return profiles.get("prologue_tones", {}).get(job.node_id, "")
    if job.kind == "event":
        return profiles.get("event_tones", {}).get(job.tone_key or job.node_id, "")
    return ""


def build_prompt(profiles: dict[str, Any], job: VoiceJob) -> str:
    prof = role_profile(profiles, job.role_key)
    role_name = prof.get("role_name", "旁白")
    role_title = prof.get("role_title", "")
    gender = prof.get("gender", "")
    age = prof.get("age", "")
    personality = prof.get("personality", "")
    base_tone = prof.get("base_tone", "沉稳自然地")
    tone = line_tone(profiles, job, prof)
    tone_part = f"本句语气：{tone}。" if tone else ""

    return (
        "你正在为一款明代探案视觉小说配音。请只朗读最后引号里的台词，不要朗读任何说明、标签、括号或引号。\n"
        f"角色：{role_name}（{role_title}）。\n"
        f"性别：{gender}；年龄：{age}。\n"
        f"性格/身份：{personality}。\n"
        f"基础演绎：{base_tone}。\n"
        f"{tone_part}\n"
        "要求：古人说话的气口，吐字清楚，情绪克制，避免现代播音腔；不要额外添加台词。\n\n"
        f"「{job.text}」"
    )


# ─── job collection ────────────────────────────────────────────────────────

def collect_jobs(case_id: str, profiles: dict[str, Any]) -> list[VoiceJob]:
    case_dir = ROOT / "data/cases" / case_id
    casting = load_json(case_dir / "casting.json").get("casting", {})
    jobs: list[VoiceJob] = []

    # dialogues
    dlg_dir = case_dir / "dialogues"
    if dlg_dir.exists():
        for p in sorted(dlg_dir.glob("*.json")):
            npc_id = p.stem
            cast = casting.get(npc_id, {})
            actor_id = cast.get("actor_id", npc_id)
            tree = load_json(p)
            for node_id, node in tree.get("nodes", {}).items():
                if not isinstance(node, dict):
                    continue
                text = node_text_for_tts(node)
                # 某些极短古文句式会让 Gemini TTS 返回空音频；允许案件级配置为 TTS 单独改写，
                # 不影响游戏里显示的原文。
                prof = role_profile(profiles, npc_id)
                text = prof.get("tts_text_overrides", {}).get(node_id, text)
                if not text:
                    continue
                out = VOICE_ROOT / actor_id / case_id / f"{safe_name(node_id)}.wav"
                jobs.append(VoiceJob("dialogue", case_id, node_id, text, out, npc_id=npc_id, actor_id=actor_id, role_key=npc_id))

    # prologue
    prologue = load_json(case_dir / "prologue.json")
    for node_id, node in prologue.get("nodes", {}).items():
        if not isinstance(node, dict):
            continue
        if node.get("silent", False):
            continue
        text = clean_text_for_tts(node.get("text", ""))
        if not text:
            continue
        speaker = node.get("speaker", "").strip()
        role_key = "_narrator"
        actor_id = "_narrator"
        if speaker:
            for npc_id, cast in casting.items():
                if cast.get("role_name") == speaker:
                    role_key = npc_id
                    actor_id = cast.get("actor_id", "_narrator")
                    break
        out = VOICE_ROOT / "_prologue" / case_id / f"{safe_name(node_id)}.wav"
        jobs.append(VoiceJob("prologue", case_id, node_id, text, out, actor_id=actor_id, role_key=role_key))

    # events
    day_events = load_json(case_dir / "day_events.json")
    for evt in day_events.get("events", []):
        if not isinstance(evt, dict):
            continue
        evt_id = evt.get("id", "")
        for idx, line in enumerate(evt.get("narration", [])):
            if isinstance(line, dict):
                text = line.get("text", "")
                speaker = line.get("speaker", "").strip()
            else:
                text = str(line)
                speaker = ""
            text = clean_text_for_tts(text)
            override_key = f"{evt_id}_{idx}"
            text = profiles.get("tts_text_overrides", {}).get("event", {}).get(override_key, text)
            if not text:
                continue
            role_key = "_narrator"
            actor_id = "_narrator"
            if speaker:
                for npc_id, cast in casting.items():
                    if cast.get("role_name") == speaker:
                        role_key = npc_id
                        actor_id = cast.get("actor_id", "_narrator")
                        break
            out = VOICE_ROOT / "_events" / case_id / f"{safe_name(evt_id)}_{idx}.wav"
            jobs.append(VoiceJob("event", case_id, f"{evt_id}_{idx}", text, out, actor_id=actor_id, role_key=role_key, tone_key=f"{evt_id}_{idx}"))

    return jobs


# ─── Gemini TTS ────────────────────────────────────────────────────────────

def synth(client: genai.Client, model: str, voice_name: str, prompt: str) -> bytes:
    last_err: Exception | None = None
    for attempt in range(3):
        try:
            resp = client.models.generate_content(
                model=model,
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
            data = resp.candidates[0].content.parts[0].inline_data.data
            if isinstance(data, str):
                data = base64.b64decode(data)
            return data
        except Exception as e:
            last_err = e
            print(f"    ! attempt {attempt + 1} failed: {e}")
            time.sleep(2 + attempt * 2)
    raise RuntimeError(f"Gemini TTS failed after 3 attempts: {last_err}")


# ─── CLI ───────────────────────────────────────────────────────────────────

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--case", default="xunyang_pavilion")
    ap.add_argument("--only-missing", action="store_true")
    ap.add_argument("--overwrite", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--npc", default="")
    ap.add_argument("--actor", default="")
    ap.add_argument("--node", default="", help="只生成指定 node_id（对话/序章）或事件 voice id，如 evt_xxx_0")
    ap.add_argument("--kind", choices=["dialogue", "prologue", "event"], default="")
    ap.add_argument("--api-key", default=os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY"))
    args = ap.parse_args()

    case_dir = ROOT / "data/cases" / args.case
    profile_path = case_dir / "voice_profiles.json"
    profiles = load_json(profile_path)
    if not profiles:
        raise RuntimeError(f"缺少案件级配音配置: {profile_path}")
    model = profiles.get("model", DEFAULT_MODEL)

    jobs = collect_jobs(args.case, profiles)
    if args.npc:
        jobs = [j for j in jobs if j.npc_id == args.npc]
    if args.actor:
        jobs = [j for j in jobs if j.actor_id == args.actor]
    if args.node:
        jobs = [j for j in jobs if j.node_id == args.node]
    if args.kind:
        jobs = [j for j in jobs if j.kind == args.kind]
    if args.only_missing:
        jobs = [j for j in jobs if not j.out_path.exists()]
    if not args.overwrite and not args.only_missing:
        # 默认不覆盖已有文件
        jobs = [j for j in jobs if not j.out_path.exists()]
    if args.limit > 0:
        jobs = jobs[: args.limit]

    print(f"case={args.case} jobs={len(jobs)} model={model} dry_run={args.dry_run}")
    for i, j in enumerate(jobs, 1):
        prof = role_profile(profiles, j.role_key)
        voice_name = prof.get("voice_name", "Charon")
        tone = line_tone(profiles, j, prof) or prof.get("base_tone", "")
        print(f"[{i:03d}] {j.kind:8s} role={j.role_key:14s} actor={j.actor_id:28s} voice={voice_name:10s} -> {j.out_path.relative_to(ROOT)}")
        print(f"      text={j.text[:70]}")
        print(f"      tone={tone[:90]}")
        if args.dry_run:
            if i == 1:
                print("      prompt_preview:")
                print("      " + build_prompt(profiles, j).replace("\n", "\n      ")[:900])
            continue

    if args.dry_run:
        return
    if not args.api_key:
        raise RuntimeError("请设置 GEMINI_API_KEY / GOOGLE_API_KEY，或使用 --api-key")

    client = genai.Client(api_key=args.api_key)
    for i, j in enumerate(jobs, 1):
        prof = role_profile(profiles, j.role_key)
        voice_name = prof.get("voice_name", "Charon")
        prompt = build_prompt(profiles, j)
        print(f"▶ [{i}/{len(jobs)}] {j.role_key}.{j.node_id} ({voice_name})")
        pcm = synth(client, model, voice_name, prompt)
        write_wav(j.out_path, pcm)
        print(f"  wrote {j.out_path.relative_to(ROOT)}")
        time.sleep(0.5)


if __name__ == "__main__":
    main()
