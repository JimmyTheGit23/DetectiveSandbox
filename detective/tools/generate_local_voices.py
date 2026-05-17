#!/usr/bin/env python3
"""本地 TTS 生成工具（ChatTTS backend）。

目标：
- 按 actor_id 固定 speaker_seed，保证同一演员跨节点/案件声线一致。
- 扫描案件 dialogue / prologue / day_events，生成运行时直接使用的 wav。
- 输出路径遵循 AssetResolver 约定：
  - 对话：assets/cn/voices/{actor_id}/{case_id}/{node_id}.wav
  - 序章：assets/cn/voices/_prologue/{case_id}/{node_id}.wav
  - 事件：assets/cn/voices/_events/{case_id}/{evt_id}_{idx}.wav

用法：
  python tools/generate_local_voices.py --case xunyang_pavilion --dry-run --limit 10
  python tools/generate_local_voices.py --case xunyang_pavilion --only-missing --limit 3
  python tools/generate_local_voices.py --case xunyang_pavilion --actor actor_wealthy_merchant

依赖：见 tools/tts/requirements-chattts.txt。
"""
from __future__ import annotations

import argparse
import json
import math
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parent.parent
VOICE_ROOT = ROOT / "assets/cn/voices"
PROFILE_PATH = ROOT / "data/voices/actor_voice_profiles.json"


@dataclass
class VoiceJob:
    kind: str                 # dialogue / prologue / event
    case_id: str
    node_id: str
    text: str
    out_path: Path
    actor_id: str = "_narrator"
    npc_id: str = ""


# ─── JSON / text helpers ──────────────────────────────────────────────────

def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def clean_text_for_tts(text: str) -> str:
    """清理 TTS 文本。

    - 对话里的行内舞台提示（如「（皱眉）你说」）删除；
    - 但如果整行就是旁白提示（如「（你已撞见他销证。）」），保留括号内内容，避免事件关键信息漏读；
    - 去掉中文引号，合并空白。
    """
    text = (text or "").strip()
    # 整句括号旁白：保留内容
    m = re.fullmatch(r"（([^）]+)）", text) or re.fullmatch(r"\(([^\)]+)\)", text)
    if m:
        text = m.group(1)
    else:
        text = re.sub(r"（[^）]*）", "", text)
        text = re.sub(r"\([^\)]*\)", "", text)
    text = re.sub(r"【[^】]*】", "", text)
    text = text.replace("「", "").replace("」", "")
    # ChatTTS 对部分中文全角标点会提示 invalid characters；转成更稳的 ASCII/普通停顿。
    text = (
        text.replace("？", "?")
        .replace("！", "!")
        .replace("；", ";")
        .replace("——", "，")
        .replace("—", "，")
        .replace("……", "。")
        .replace("…", "。")
    )
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


def split_long_text(text: str, max_chars: int = 90) -> list[str]:
    """ChatTTS 长文本更容易飘；按中文标点切段。"""
    if len(text) <= max_chars:
        return [text]
    parts: list[str] = []
    buf = ""
    for ch in text:
        buf += ch
        if ch in "。！？；…" and len(buf) >= 30:
            parts.append(buf.strip())
            buf = ""
        elif len(buf) >= max_chars:
            parts.append(buf.strip())
            buf = ""
    if buf.strip():
        parts.append(buf.strip())
    return [p for p in parts if p]


# ─── job collection ────────────────────────────────────────────────────────

def collect_jobs(case_id: str) -> list[VoiceJob]:
    case_dir = ROOT / "data/cases" / case_id
    manifest = load_json(case_dir / "manifest.json")
    voice_status = manifest.get("voice_status", "missing")
    casting_doc = load_json(case_dir / "casting.json")
    casting: dict[str, Any] = casting_doc.get("casting", {})

    jobs: list[VoiceJob] = []

    # dialogue jobs
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
                if not text:
                    continue
                out = VOICE_ROOT / actor_id / case_id / f"{node_id}.wav"
                jobs.append(VoiceJob("dialogue", case_id, node_id, text, out, actor_id=actor_id, npc_id=npc_id))

    # prologue jobs
    prologue = load_json(case_dir / "prologue.json")
    for node_id, node in prologue.get("nodes", {}).items():
        if not isinstance(node, dict):
            continue
        if node.get("silent", False):
            continue
        text = clean_text_for_tts(node.get("text", ""))
        if not text:
            continue
        out = VOICE_ROOT / "_prologue" / case_id / f"{node_id}.wav"
        jobs.append(VoiceJob("prologue", case_id, node_id, text, out, actor_id="_narrator"))

    # event narration jobs
    day_events = load_json(case_dir / "day_events.json")
    for evt in day_events.get("events", []):
        if not isinstance(evt, dict):
            continue
        evt_id = evt.get("id", "")
        for idx, line in enumerate(evt.get("narration", [])):
            if isinstance(line, dict):
                text = line.get("text", "")
                speaker = line.get("speaker", "")
            else:
                text = str(line)
                speaker = ""
            text = clean_text_for_tts(text)
            if not text:
                continue
            actor_id = "_narrator"
            # 若事件行显式 speaker 且能映射到 casting，可用对应角色声线；默认旁白
            if speaker:
                for npc_id, cast in casting.items():
                    if cast.get("role_name") == speaker:
                        actor_id = cast.get("actor_id", "_narrator")
                        break
            out = VOICE_ROOT / "_events" / case_id / f"{evt_id}_{idx}.wav"
            jobs.append(VoiceJob("event", case_id, f"{evt_id}_{idx}", text, out, actor_id=actor_id))

    return jobs


# ─── ChatTTS backend ───────────────────────────────────────────────────────

class BaseBackend:
    def synth_one(self, job: VoiceJob) -> tuple[np.ndarray, int]:
        raise NotImplementedError


class ChatTTSBackend(BaseBackend):
    def __init__(self, profiles: dict[str, Any], device: str = "auto") -> None:
        try:
            import torch  # type: ignore
            import ChatTTS  # type: ignore
        except Exception as e:
            raise RuntimeError(
                "ChatTTS/torch 未安装。请先执行：\n"
                "  python -m venv .venv-tts\n"
                "  source .venv-tts/bin/activate  # Windows 用 .venv-tts\\Scripts\\Activate.ps1\n"
                "  pip install -r tools/tts/requirements-chattts.txt\n"
            ) from e
        self.torch = torch
        self.ChatTTS = ChatTTS
        self.profiles = profiles
        self.chat = ChatTTS.Chat()
        print("[ChatTTS] loading model ...")
        # 优先使用工程根目录下手动下载好的 asset/（已加入 .gitignore）；没有或校验失败再走 HF cache。
        loaded = False
        if (ROOT / "asset").exists():
            loaded = self.chat.load(source="local", custom_path=str(ROOT), compile=False)
        if not loaded:
            loaded = self.chat.load(source="huggingface", compile=False)
        if not loaded:
            raise RuntimeError(
                "ChatTTS 模型下载/加载失败。可尝试：\n"
                "  export HF_ENDPOINT=https://hf-mirror.com\n"
                "  python tools/generate_local_voices.py --case xunyang_pavilion --actor actor_wealthy_merchant --limit 2\n"
                "或手动下载 2Noise/ChatTTS 的 asset/ 目录到工程根目录（asset/ 已被 .gitignore 忽略）。"
            )
        self._spk_cache: dict[str, Any] = {}

    def _profile(self, actor_id: str) -> dict[str, Any]:
        return self.profiles.get(actor_id) or self.profiles.get("_narrator", {})

    def _speaker(self, actor_id: str):
        if actor_id in self._spk_cache:
            return self._spk_cache[actor_id]
        prof = self._profile(actor_id)
        seed = int(prof.get("speaker_seed", 90001))
        # ChatTTS 的 sample_random_speaker 使用当前随机状态；固定 seed 以保持 actor 声线一致。
        self.torch.manual_seed(seed)
        spk = self.chat.sample_random_speaker()
        self._spk_cache[actor_id] = spk
        return spk

    def synth_one(self, job: VoiceJob) -> tuple[np.ndarray, int]:
        prof = self._profile(job.actor_id)
        spk = self._speaker(job.actor_id)
        speed = int(prof.get("speed", 4))
        oral = int(prof.get("oral", 2))
        laugh = int(prof.get("laugh", 0))
        brk = int(prof.get("break", 4))
        temperature = float(prof.get("temperature", 0.35))
        # ChatTTS 控制 token；不要把角色说明塞太长，避免读出来或影响稳定性。
        refine_prompt = f"[oral_{oral}][laugh_{laugh}][break_{brk}]"
        infer_prompt = f"[speed_{speed}]"
        pieces = split_long_text(job.text)
        wavs: list[np.ndarray] = []
        for part in pieces:
            params_refine = self.ChatTTS.Chat.RefineTextParams(prompt=refine_prompt)
            params_infer = self.ChatTTS.Chat.InferCodeParams(
                spk_emb=spk,
                temperature=temperature,
                prompt=infer_prompt,
            )
            out = self.chat.infer(
                [part],
                params_refine_text=params_refine,
                params_infer_code=params_infer,
            )
            arr = np.asarray(out[0], dtype=np.float32)
            wavs.append(arr)
            # 轻微停顿，避免拼接太急促
            wavs.append(np.zeros(int(24000 * 0.12), dtype=np.float32))
        wav = np.concatenate(wavs) if wavs else np.zeros(1, dtype=np.float32)
        return postprocess_wav(wav), 24000


class MacOSSayBackend(BaseBackend):
    """macOS 系统 say 的 debug backend。

    只用于验证游戏语音路径/播放链路，不建议作为正式配音。
    """

    VOICE_BY_ACTOR = {
        "_narrator": "Tingting",
        "actor_wealthy_merchant": "Rocko (中文（中国大陆）)",
        "actor_elder_grandmother": "Grandma (中文（中国大陆）)",
        "actor_buddhist_nun": "Shelley (中文（中国大陆）)",
        "actor_madam_proprietress": "Flo (中文（中国大陆）)",
        "actor_innkeeper_wife": "Sandy (中文（中国大陆）)",
        "actor_jianghu_swordsman": "Reed (中文（中国大陆）)",
        "actor_senior_prefect": "Grandpa (中文（中国大陆）)",
        "actor_opera_performer": "Eddy (中文（中国大陆）)",
        "actor_foreign_traveler": "Rocko (中文（中国大陆）)",
    }

    def __init__(self, profiles: dict[str, Any], device: str = "auto") -> None:
        if sys.platform != "darwin":
            raise RuntimeError("macos_say backend 只支持 macOS，仅用于调试。")
        self.profiles = profiles

    def synth_one(self, job: VoiceJob) -> tuple[np.ndarray, int]:
        voice = self.VOICE_BY_ACTOR.get(job.actor_id, self.VOICE_BY_ACTOR["_narrator"])
        prof = self.profiles.get(job.actor_id, {})
        speed_tag = int(prof.get("speed", 4))
        # say -r 是每分钟词数，这里粗略映射到 135~180。
        rate = 130 + speed_tag * 10
        with tempfile.TemporaryDirectory() as td:
            aiff = Path(td) / "out.aiff"
            wav_path = Path(td) / "out.wav"
            subprocess.run(["say", "-v", voice, "-r", str(rate), "-o", str(aiff), job.text], check=True)
            subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEF32@24000", str(aiff), str(wav_path)], check=True)
            wav, sr = sf.read(wav_path, dtype="float32", always_2d=False)
        return postprocess_wav(np.asarray(wav, dtype=np.float32)), int(sr)


class CosyVoiceBackend(BaseBackend):
    def __init__(self, profiles: dict[str, Any], device: str = "auto") -> None:
        raise NotImplementedError(
            "cosyvoice backend 预留给正式中文配音。当前先跑通 ChatTTS；如需启用，"
            "建议单独安装 CosyVoice2 并给每个 actor 配参考音频。"
        )


def make_backend(engine: str, profiles: dict[str, Any], device: str) -> BaseBackend:
    if engine == "chattts":
        return ChatTTSBackend(profiles, device=device)
    if engine == "macos_say":
        return MacOSSayBackend(profiles, device=device)
    if engine == "cosyvoice":
        return CosyVoiceBackend(profiles, device=device)
    raise ValueError(f"unknown engine: {engine}")


# ─── audio post-process ────────────────────────────────────────────────────

def postprocess_wav(wav: np.ndarray, peak: float = 0.70) -> np.ndarray:
    wav = np.asarray(wav, dtype=np.float32)
    if wav.ndim > 1:
        wav = wav.mean(axis=0)
    wav = np.nan_to_num(wav)
    max_abs = float(np.max(np.abs(wav))) if wav.size else 0.0
    if max_abs > 1e-6:
        wav = wav / max_abs * peak
    return np.clip(wav, -1.0, 1.0)


def write_wav(path: Path, wav: np.ndarray, sr: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    sf.write(path, wav, sr, subtype="PCM_16")


def write_import_stub(path: Path) -> None:
    """Godot 会自动生成 .import；这里不手写，避免版本差异。保留函数用于未来扩展。"""
    return


# ─── main ──────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--case", default="xunyang_pavilion")
    ap.add_argument("--actor", default="", help="只生成某个 actor_id")
    ap.add_argument("--npc", default="", help="只生成某个 npc_id 的 dialogue")
    ap.add_argument("--kind", choices=["all", "dialogue", "prologue", "event"], default="all")
    ap.add_argument("--only-missing", action="store_true", help="跳过已存在 wav")
    ap.add_argument("--overwrite", action="store_true")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--engine", choices=["chattts", "macos_say", "cosyvoice"], default="chattts")
    ap.add_argument("--device", default="auto")
    args = ap.parse_args()

    profiles_doc = load_json(PROFILE_PATH)
    profiles = profiles_doc.get("profiles", {})
    jobs = collect_jobs(args.case)

    def keep(j: VoiceJob) -> bool:
        if args.kind != "all" and j.kind != args.kind:
            return False
        if args.actor and j.actor_id != args.actor:
            return False
        if args.npc and j.npc_id != args.npc:
            return False
        if args.only_missing and j.out_path.exists() and not args.overwrite:
            return False
        if j.out_path.exists() and not args.overwrite and not args.only_missing:
            return False
        return True

    jobs = [j for j in jobs if keep(j)]
    if args.limit > 0:
        jobs = jobs[: args.limit]

    print(f"case={args.case} jobs={len(jobs)} engine={args.engine} dry_run={args.dry_run}")
    missing_profiles = sorted({j.actor_id for j in jobs if j.actor_id not in profiles})
    if missing_profiles:
        print("[WARN] 缺少 voice profile，将回退 narrator:", ", ".join(missing_profiles))
    for i, j in enumerate(jobs, 1):
        prof = profiles.get(j.actor_id, profiles.get("_narrator", {}))
        rel = j.out_path.relative_to(ROOT)
        print(f"[{i:03d}] {j.kind:<8} actor={j.actor_id:<28} seed={prof.get('speaker_seed','?')} -> {rel}")
        print(f"      {j.text[:80]}")
    if args.dry_run or not jobs:
        return 0

    if args.engine == "macos_say":
        print("[WARN] macos_say 仅用于路径/播放链路调试，效果不适合作为正式语音。")
    backend = make_backend(args.engine, profiles, device=args.device)
    for i, j in enumerate(jobs, 1):
        print(f"▶ [{i}/{len(jobs)}] {j.actor_id} {j.node_id}")
        wav, sr = backend.synth_one(j)
        write_wav(j.out_path, wav, sr)
        write_import_stub(j.out_path)
        print(f"  wrote {j.out_path.relative_to(ROOT)} ({len(wav)/sr:.1f}s)")
    print("done. 建议继续运行：python tools/audit_voices.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
