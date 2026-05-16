"""
批量生成游戏背景音乐（Gemini Lyria RealTime）

每个 BGM 配置：风格提示词 + 录制时长。
- 通过 Lyria 实时流接口连接
- 接收 PCM 音频流，按设定时长录制
- 封装为 WAV 文件保存到 assets/cn/bgm/

注意：Lyria 是实验性接口，可能不稳定，遇到 5xx 重试或换风格描述。

用法：
  GEMINI_API_KEY=xxx python3 tools/generate_bgm.py
  # 或者只生成单个：
  GEMINI_API_KEY=xxx python3 tools/generate_bgm.py main_theme

第一次跑前请确认 google-genai SDK >= 1.0
"""
from __future__ import annotations
import os
import sys
import asyncio
import struct
import time
from pathlib import Path

try:
	from google import genai
	from google.genai import types
except ImportError:
	print("请先运行: pip3 install google-genai")
	sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets/cn/bgm"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# 每条 BGM 的配置
BGM_CONFIGS = {
	"main_theme": {
		"prompts": [
			("Chinese guqin meditative", 1.0),
			("traditional dizi flute", 0.8),
			("rainy ambience", 0.6),
			("dark, melancholic, somber", 0.7),
		],
		"bpm": 60,
		"duration_sec": 60,
		"description": "主题曲：水墨夜雨、古琴洞箫、沉郁肃穆",
	},
	"investigation_dark": {
		"prompts": [
			("dark Chinese erhu", 0.9),
			("low Chinese drums", 0.6),
			("tense, suspenseful, slow", 0.8),
			("ambient strings", 0.5),
		],
		"bpm": 65,
		"duration_sec": 50,
		"description": "查案场景：沉郁悬疑、二胡低鼓",
	},
	"spring_wind": {
		"prompts": [
			("Chinese pipa lute", 1.0),
			("Chinese guzheng zither", 0.8),
			("decadent, melancholic", 0.7),
			("smoky cabaret feel", 0.5),
		],
		"bpm": 70,
		"duration_sec": 50,
		"description": "春风楼：琵琶古筝，靡靡又带哀愁",
	},
	"temple_quiet": {
		"prompts": [
			("soft Chinese xiao flute, very gentle", 1.0),
			("warm guqin drone, low and mellow", 0.8),
			("quiet temple ambience, no sharp bells", 0.9),
			("dark calm Buddhist atmosphere, soft low frequencies", 0.7),
			("avoid piercing high tones, avoid harsh percussion", 1.0),
		],
		"bpm": 48,
		"duration_sec": 50,
		"description": "观音庙：柔和洞箫、低沉古琴、无刺耳钟声",
	},
	"market_calm": {
		"prompts": [
			("traditional Chinese ambient", 0.8),
			("light flute melody", 0.7),
			("subdued, calm, distant", 0.6),
		],
		"bpm": 75,
		"duration_sec": 40,
		"description": "集市：清淡平和，箫声远",
	},
	"accuse_tension": {
		"prompts": [
			("intense Chinese percussion", 1.0),
			("dramatic erhu", 0.9),
			("tense, climactic, urgent", 1.0),
			("low brass swell", 0.5),
		],
		"bpm": 95,
		"duration_sec": 40,
		"description": "指证：紧张到顶，鼓点紧促",
	},
	"ending_warm": {
		"prompts": [
			("hopeful Chinese guqin", 0.9),
			("warm strings", 0.7),
			("calm, redemptive, melancholic but warm", 0.8),
		],
		"bpm": 70,
		"duration_sec": 40,
		"description": "好结局：温暖肃穆",
	},
	"ending_cold": {
		"prompts": [
			("desolate Chinese erhu", 0.9),
			("cold, regretful, hollow", 1.0),
			("distant rain", 0.5),
		],
		"bpm": 55,
		"duration_sec": 40,
		"description": "坏结局：冷峻悲凉",
	},
}

MODEL = "models/lyria-realtime-exp"
SAMPLE_RATE = 48000
CHANNELS = 2
BITS_PER_SAMPLE = 16


def write_wav(path: Path, pcm_bytes: bytes) -> None:
	"""把 16-bit PCM 字节流封装成 WAV 文件。"""
	num_samples = len(pcm_bytes) // (CHANNELS * BITS_PER_SAMPLE // 8)
	byte_rate = SAMPLE_RATE * CHANNELS * BITS_PER_SAMPLE // 8
	block_align = CHANNELS * BITS_PER_SAMPLE // 8
	data_size = len(pcm_bytes)
	riff_size = 36 + data_size
	with open(path, "wb") as f:
		f.write(b"RIFF")
		f.write(struct.pack("<I", riff_size))
		f.write(b"WAVE")
		f.write(b"fmt ")
		f.write(struct.pack("<IHHIIHH", 16, 1, CHANNELS, SAMPLE_RATE, byte_rate, block_align, BITS_PER_SAMPLE))
		f.write(b"data")
		f.write(struct.pack("<I", data_size))
		f.write(pcm_bytes)


async def generate_one(bgm_id: str, cfg: dict, client) -> bool:
	out_path = OUT_DIR / f"{bgm_id}.wav"
	if out_path.exists():
		print(f"  [skip] {out_path.name} already exists")
		return True
	
	print(f"  ▶ {bgm_id}: {cfg['description']}")
	print(f"      duration={cfg['duration_sec']}s, bpm={cfg['bpm']}")
	
	prompts = [
		types.WeightedPrompt(text=p, weight=w)
		for p, w in cfg["prompts"]
	]
	gen_config = types.LiveMusicGenerationConfig(
		bpm=cfg["bpm"],
		temperature=1.0,
	)
	
	pcm_buffer = bytearray()
	target_bytes = cfg["duration_sec"] * SAMPLE_RATE * CHANNELS * (BITS_PER_SAMPLE // 8)
	# 适当多采集一些以保证完整时长
	max_bytes = int(target_bytes * 1.05)
	
	try:
		async with client.aio.live.music.connect(model=MODEL) as session:
			await session.set_weighted_prompts(prompts=prompts)
			await session.set_music_generation_config(config=gen_config)
			await session.play()
			
			start = time.time()
			async for message in session.receive():
				if hasattr(message, "server_content") and message.server_content:
					audio_chunk = message.server_content.audio_chunks[0] if message.server_content.audio_chunks else None
					if audio_chunk and audio_chunk.data:
						pcm_buffer.extend(audio_chunk.data)
						# print(f"      collected {len(pcm_buffer)/1024:.0f}KB ({len(pcm_buffer)/target_bytes*100:.0f}%)")
				if len(pcm_buffer) >= max_bytes:
					break
				if time.time() - start > cfg["duration_sec"] + 30:
					print("      [warn] timeout, breaking")
					break
			try:
				await session.stop()
			except Exception:
				pass
	except Exception as e:
		print(f"      [error] {e}")
		return False
	
	if len(pcm_buffer) < target_bytes // 2:
		print(f"      [warn] only got {len(pcm_buffer)} bytes, less than half. saving anyway.")
	
	# 截断到 target_bytes
	pcm_final = bytes(pcm_buffer[:target_bytes])
	write_wav(out_path, pcm_final)
	print(f"      ✓ saved {out_path.name} ({len(pcm_final)/1024/1024:.1f}MB)")
	return True


async def main() -> None:
	api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
	if not api_key:
		print("请设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
		sys.exit(1)
	
	# v1alpha 是 Lyria 实时所需的 API 版本
	client = genai.Client(api_key=api_key, http_options={"api_version": "v1alpha"})
	
	# 命令行可指定单个 bgm_id 只生成那一条
	target_ids = sys.argv[1:] if len(sys.argv) > 1 else list(BGM_CONFIGS.keys())
	
	for bgm_id in target_ids:
		if bgm_id not in BGM_CONFIGS:
			print(f"  [skip] unknown bgm: {bgm_id}")
			continue
		cfg = BGM_CONFIGS[bgm_id]
		ok = False
		for attempt in range(2):
			ok = await generate_one(bgm_id, cfg, client)
			if ok:
				break
			print(f"      retry attempt {attempt+2}/2 ...")
			await asyncio.sleep(3)
		if not ok:
			print(f"  ✗ failed: {bgm_id}")


if __name__ == "__main__":
	asyncio.run(main())
