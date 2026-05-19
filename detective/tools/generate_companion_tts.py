#!/usr/bin/env python3
"""
提取助手（凌瑶）的所有台词，调用 Gemini TTS API 生成语音文件。

用法:
    cd detective
    python3 tools/generate_companion_tts.py

需要环境变量 GEMINI_API_KEY 或在 tts_config.json 中设置 gemini_api_key。
语音文件输出到: assets/cn/voices/actor_tomboy_courier/tts_preview/
输出格式: WAV (PCM 16-bit, 24000Hz, mono)
"""

import json
import os
import sys
import time
import hashlib
import base64
import wave
import struct
import urllib.request
import urllib.error

# ─── 配置 ───
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TTS_CONFIG_PATH = os.path.join(PROJECT_ROOT, "tts_config.json")
CASE_DATA_DIR = os.path.join(PROJECT_ROOT, "data", "cases", "linchuan_inn")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "cn", "voices", "actor_tomboy_courier", "tts_preview")

GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent"
# 少女风格语音：Leda(年轻) / Aoede(轻松) / Laomedeia(欢快) / Sulafat(温暖)
VOICE_NAME = "Leda"


def load_gemini_api_key():
    """从环境变量或配置文件加载 Gemini API Key"""
    key = os.environ.get("GEMINI_API_KEY", "")
    if key:
        return key
    if os.path.exists(TTS_CONFIG_PATH):
        with open(TTS_CONFIG_PATH, "r", encoding="utf-8") as f:
            cfg = json.load(f)
        key = cfg.get("gemini_api_key", "")
    return key


def call_gemini_tts(api_key, text, voice_name=VOICE_NAME):
    """调用 Gemini TTS API，返回 PCM bytes (24000Hz, 16-bit, mono) 或 None"""
    request_body = {
        "contents": [{
            "parts": [{"text": f"请用中文朗读以下内容：{text}"}]
        }],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {
                    "prebuiltVoiceConfig": {
                        "voiceName": voice_name
                    }
                }
            }
        }
    }

    body = json.dumps(request_body, ensure_ascii=False).encode("utf-8")
    url = f"{GEMINI_API_URL}?key={api_key}"
    headers = {"Content-Type": "application/json"}

    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")[:500]
        print(f"  HTTP Error {e.code}: {err_body}")
        return None
    except Exception as e:
        print(f"  Request Error: {e}")
        return None

    # 提取音频数据
    try:
        candidates = result.get("candidates", [])
        if not candidates:
            print(f"  No candidates in response")
            return None
        parts = candidates[0].get("content", {}).get("parts", [])
        if not parts:
            print(f"  No parts in response")
            return None
        inline_data = parts[0].get("inlineData", {})
        audio_b64 = inline_data.get("data", "")
        if not audio_b64:
            # 可能返回了文本而非音频
            text_resp = parts[0].get("text", "")
            if text_resp:
                print(f"  API 返回了文本而非音频: {text_resp[:100]}")
            else:
                print(f"  Empty audio data")
            return None
        return base64.b64decode(audio_b64)
    except (KeyError, IndexError) as e:
        print(f"  Response parse error: {e}")
        return None


def pcm_to_wav(pcm_bytes, sample_rate=24000, channels=1, sample_width=2):
    """将 PCM 原始数据封装为 WAV 格式 bytes"""
    buf = bytearray()
    # RIFF header
    data_size = len(pcm_bytes)
    buf.extend(b"RIFF")
    buf.extend(struct.pack("<I", 36 + data_size))
    buf.extend(b"WAVE")
    # fmt chunk
    buf.extend(b"fmt ")
    buf.extend(struct.pack("<I", 16))  # chunk size
    buf.extend(struct.pack("<H", 1))   # PCM format
    buf.extend(struct.pack("<H", channels))
    buf.extend(struct.pack("<I", sample_rate))
    buf.extend(struct.pack("<I", sample_rate * channels * sample_width))  # byte rate
    buf.extend(struct.pack("<H", channels * sample_width))  # block align
    buf.extend(struct.pack("<H", sample_width * 8))  # bits per sample
    # data chunk
    buf.extend(b"data")
    buf.extend(struct.pack("<I", data_size))
    buf.extend(pcm_bytes)
    return bytes(buf)


def safe_filename(text, max_len=60):
    """从文本生成安全文件名"""
    h = hashlib.md5(text.encode("utf-8")).hexdigest()[:8]
    prefix = "".join(c for c in text[:max_len] if c.isalnum() or c in "_ -—")
    prefix = prefix.strip(" -")[:40]
    return f"{prefix}_{h}"


def extract_companion_lines():
    """从所有数据文件中提取助手的台词"""
    lines = []  # [(source, text), ...]
    seen_texts = set()

    def add_line(source, text):
        text = text.strip()
        if not text or len(text) < 2:
            return
        if text in seen_texts:
            return
        seen_texts.add(text)
        lines.append((source, text))

    # 1) banter.json
    banter_path = os.path.join(CASE_DATA_DIR, "companion", "banter.json")
    if os.path.exists(banter_path):
        with open(banter_path, "r", encoding="utf-8") as f:
            banter = json.load(f)
        for rule in banter.get("rules", []):
            for line_item in rule.get("lines", []):
                if isinstance(line_item, str):
                    add_line("banter", line_item)
                elif isinstance(line_item, list):
                    for sub in line_item:
                        if isinstance(sub, dict):
                            speaker = sub.get("speaker", "")
                            text = sub.get("text", "")
                            if speaker == "凌瑶" and text:
                                add_line("banter", text)
                        elif isinstance(sub, str):
                            add_line("banter", sub)

    # 2) discussions.json
    discuss_path = os.path.join(CASE_DATA_DIR, "companion", "discussions.json")
    if os.path.exists(discuss_path):
        with open(discuss_path, "r", encoding="utf-8") as f:
            discussions = json.load(f)
        for topic_key, topic_val in discussions.items():
            if topic_key.startswith("_"):
                continue
            rules = topic_val.get("rules", []) if isinstance(topic_val, dict) else []
            for rule in rules:
                for line_item in rule.get("lines", []):
                    if isinstance(line_item, str):
                        add_line(f"discuss_{topic_key}", line_item)
            pool = topic_val.get("pool", []) if isinstance(topic_val, dict) else []
            for item in pool:
                for line_item in item.get("lines", []):
                    if isinstance(line_item, str):
                        add_line(f"discuss_{topic_key}", line_item)

    # 3) day_events.json
    events_path = os.path.join(CASE_DATA_DIR, "day_events.json")
    if os.path.exists(events_path):
        with open(events_path, "r", encoding="utf-8") as f:
            events = json.load(f)
        for evt in events.get("events", []):
            for narr in evt.get("narration", []):
                if isinstance(narr, dict):
                    speaker = narr.get("speaker", "")
                    text = narr.get("text", "")
                    if speaker == "凌瑶" and text:
                        add_line(f"event_{evt.get('id', '')}", text)

    # 4) progression.json - phase_notifications
    prog_path = os.path.join(CASE_DATA_DIR, "progression.json")
    if os.path.exists(prog_path):
        with open(prog_path, "r", encoding="utf-8") as f:
            prog = json.load(f)
        for phase_id, notif in prog.get("phase_notifications", {}).items():
            speaker = notif.get("speaker", "")
            text = notif.get("text", "")
            if speaker == "凌瑶" and text:
                add_line(f"phase_{phase_id}", text)

    return lines


def main():
    # 加载 API Key
    api_key = load_gemini_api_key()
    if not api_key:
        print("错误：未找到 Gemini API Key")
        print("请设置环境变量 GEMINI_API_KEY 或在 tts_config.json 中添加 gemini_api_key")
        sys.exit(1)

    # 提取台词
    lines = extract_companion_lines()
    print(f"共提取到 {len(lines)} 条助手台词")
    print(f"使用 Gemini TTS (voice: {VOICE_NAME})\n")

    # 创建输出目录
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 生成索引文件
    index = []

    success = 0
    fail = 0
    skip = 0

    for i, (source, text) in enumerate(lines, 1):
        fname = safe_filename(text)
        wav_path = os.path.join(OUTPUT_DIR, f"{fname}.wav")

        # 跳过已存在的
        if os.path.exists(wav_path):
            print(f"[{i}/{len(lines)}] 跳过（已存在）: {text[:40]}...")
            skip += 1
            index.append({"source": source, "text": text, "file": f"{fname}.wav"})
            continue

        print(f"[{i}/{len(lines)}] 生成: {text[:50]}...")

        pcm_bytes = call_gemini_tts(api_key, text, VOICE_NAME)
        if pcm_bytes is None:
            fail += 1
            print(f"  等待 5 秒后重试...")
            time.sleep(5)
            pcm_bytes = call_gemini_tts(api_key, text, VOICE_NAME)
            if pcm_bytes is None:
                print(f"  重试失败，跳过")
                continue

        # 封装为 WAV
        wav_bytes = pcm_to_wav(pcm_bytes)
        with open(wav_path, "wb") as f:
            f.write(wav_bytes)

        file_size = len(wav_bytes)
        print(f"  OK ({file_size:,} bytes)")
        success += 1

        index.append({"source": source, "text": text, "file": f"{fname}.wav"})

        # 限速：免费配额 15 RPM
        time.sleep(5)

    # 保存索引
    index_path = os.path.join(OUTPUT_DIR, "_index.json")
    with open(index_path, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)

    print(f"\n── 完成 ──")
    print(f"  成功: {success}")
    print(f"  跳过: {skip}")
    print(f"  失败: {fail}")
    print(f"  输出目录: {OUTPUT_DIR}")
    print(f"  索引文件: {index_path}")
    if fail > 0:
        print(f"\n  ⚠ 有 {fail} 条失败。可稍后重新运行脚本（已成功的会自动跳过）。")


if __name__ == "__main__":
    main()
