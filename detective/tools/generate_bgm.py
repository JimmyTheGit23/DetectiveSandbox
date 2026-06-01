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

# ═══════════════════════════════════════════════════════════════════
# LEITMOTIF 系统
# ═══════════════════════════════════════════════════════════════════
# 核心动机（陆昭/游戏主题）：5音下行 A-G-E-D-C (Am)
# 沈清月动机：4音上行不协和 E-F-A-Bb (tritone span)
# 中心调性：A小调 | BPM基准：60
# 所有曲目必须包含至少一个动机的变体以实现听觉统一。
# ═══════════════════════════════════════════════════════════════════

LEITMOTIF_MAIN = (
	"CRITICAL: This piece MUST include a recurring 5-note descending motif "
	"(the notes A-G-E-D-C in A minor key) as the melodic backbone. "
	"This motif should appear at least 2-3 times throughout the piece, "
	"representing the protagonist's pursuit of truth. "
	"The motif rhythm is: dotted quarter, eighth, quarter, quarter, half note."
)

LEITMOTIF_SHEN = (
	"CRITICAL: Include a dissonant 4-note ascending motif (E-F-A-Bb) "
	"representing a dangerous feminine antagonist. "
	"The interval span creates unease (tritone from E to Bb). "
	"Rhythm: two sixteenths, one eighth, one sustained half note."
)

LEITMOTIF_BOTH = (
	"CRITICAL: Weave TWO motifs together in counterpoint: "
	"(1) A 5-note descending phrase A-G-E-D-C representing the protagonist (played by erhu), "
	"and (2) A dissonant 4-note ascending phrase E-F-A-Bb representing the antagonist (played by pipa). "
	"The two motifs should alternate, overlap, and build dramatic tension."
)

KEY_CENTER = "All melodies and harmonies must stay in A minor (Am) key center, using notes from the A natural minor scale."


# 每条 BGM 的配置
BGM_CONFIGS = {
	# ═══════════════════════════════════════════════════════════════
	# 通用 / 全局曲目
	# ═══════════════════════════════════════════════════════════════
	"main_theme": {
		"prompts": [
			(LEITMOTIF_MAIN, 1.0),
			(KEY_CENTER, 1.0),
			("Chinese guqin solo playing the descending motif slowly and deliberately, meditative", 1.0),
			("traditional dizi flute enters softly in second half echoing the motif", 0.8),
			("rainy night ambience, distant thunder, winter river", 0.6),
			("dark, melancholic, somber, dignified, like a scholar's oath in the rain", 0.8),
			("no vocals, no modern instruments, loopable, wide reverb", 0.9),
		],
		"bpm": 60,
		"duration_sec": 60,
		"description": "主题曲：古琴呈示核心动机(A-G-E-D-C)，洞箫接应，水墨夜雨",
	},
	"investigation_dark": {
		"prompts": [
			(LEITMOTIF_MAIN, 1.0),
			(KEY_CENTER, 1.0),
			("Chinese erhu playing fragments of the 5-note descending motif in low register", 0.9),
			("sparse guqin plucks as harmonic support", 0.7),
			("low Chinese drums very distant, subtle heartbeat pulse", 0.5),
			("tense, suspenseful, slow, dark investigation atmosphere", 0.8),
			("no bright tones, no sharp percussion, loopable, Am key", 1.0),
		],
		"bpm": 60,
		"duration_sec": 50,
		"description": "通用查案：二胡奏动机碎片、古琴支撑、低鼓心跳，Am调",
	},
	"spring_wind": {
		"prompts": [
			(LEITMOTIF_MAIN, 0.8),
			(KEY_CENTER, 1.0),
			("Chinese pipa lute playing a warm variation of descending motif A-G-E-D-C", 1.0),
			("Chinese guzheng zither gentle arpeggios in A minor", 0.8),
			("slightly decadent, melancholic but warm, late-night cabaret in ancient China", 0.7),
			("the motif appears decorated with ornamental notes, still recognizable", 0.8),
			("no harsh sounds, warm low-mid frequencies, intimate reverb", 0.9),
		],
		"bpm": 72,
		"duration_sec": 50,
		"description": "春风楼：琵琶奏动机暖色变奏、古筝伴奏，Am调靡靡",
	},
	"temple_quiet": {
		"prompts": [
			(LEITMOTIF_MAIN, 0.7),
			(KEY_CENTER, 1.0),
			("soft Chinese xiao flute playing the descending motif very slowly, breathy, meditative", 1.0),
			("warm guqin single note drone on A, low and mellow", 0.8),
			("quiet temple ambience, no sharp bells, wooden fish (muyu) very faint", 0.6),
			("dark calm Buddhist atmosphere, soft low frequencies", 0.7),
			("the motif is stretched to double length, contemplative and sparse", 0.8),
			("avoid piercing high tones, avoid harsh percussion, Am key", 1.0),
		],
		"bpm": 48,
		"duration_sec": 50,
		"description": "观音庙：洞箫极慢奏动机、古琴持续A音、木鱼轻点，Am调",
	},
	"market_calm": {
		"prompts": [
			(LEITMOTIF_MAIN, 0.6),
			(KEY_CENTER, 1.0),
			("light dizi flute melody based on the descending motif but playful and bouncy", 0.9),
			("Chinese guzheng light plucking, cheerful but in minor key", 0.7),
			("bustling distant ambience, daily life atmosphere in ancient town", 0.6),
			("the motif is hidden in the flute melody, subtle and woven in", 0.7),
			("subdued, calm, not too bright, Am key with moments of relative major C", 0.8),
		],
		"bpm": 72,
		"duration_sec": 40,
		"description": "集市：笛子将动机化为轻快旋律、古筝伴奏，Am调日常",
	},
	"accuse_tension": {
		"prompts": [
			(LEITMOTIF_MAIN, 1.0),
			(KEY_CENTER, 1.0),
			("intense Chinese taiko/tanggu drums driving rhythm at 90 BPM", 1.0),
			("dramatic erhu playing the descending motif A-G-E-D-C rapidly and repeatedly", 1.0),
			("the motif is played at double speed as an ostinato, building to climax", 0.9),
			("tense, climactic, urgent, the moment of accusation", 1.0),
			("Am key, no modern instruments, no vocals", 0.9),
		],
		"bpm": 90,
		"duration_sec": 40,
		"description": "通用指证：二胡急速反复奏动机+太鼓驱动，Am调高潮",
	},
	"ending_warm": {
		"prompts": [
			(LEITMOTIF_MAIN, 1.0),
			(KEY_CENTER, 0.8),
			("Chinese guqin playing the 5-note motif transposed to A MAJOR (A-B-C#-E-F#), warm resolution", 1.0),
			("warm string ensemble joins softly, gentle crescendo", 0.7),
			("the motif transforms from minor to major, representing truth found", 0.9),
			("calm, redemptive, dignified hope, like dawn after long rain", 0.8),
			("A major key resolution, loopable ending, no harsh tones", 0.9),
		],
		"bpm": 66,
		"duration_sec": 40,
		"description": "好结局：动机转A大调(A-B-C#-E-F#)，古琴+暖弦乐，解决感",
	},
	"ending_cold": {
		"prompts": [
			(LEITMOTIF_MAIN, 1.0),
			(KEY_CENTER, 1.0),
			("desolate Chinese erhu playing only the first 2 notes of the motif (A-G) repeatedly, fading", 1.0),
			("cold hollow guqin single pluck on low A, very sparse", 0.8),
			("distant rain, winter emptiness, unresolved ending", 0.7),
			("the motif is incomplete - only A and G repeat, never reaching resolution", 0.9),
			("Am key, extremely slow, regretful, hollow, fading to silence", 1.0),
		],
		"bpm": 48,
		"duration_sec": 40,
		"description": "坏结局：动机仅前2音(A-G)反复不解决、二胡哀鸣渐弱，Am调",
	},

	# ═══════════════════════════════════════════════════════════════
	# 序章：渡口沉舟
	# ═══════════════════════════════════════════════════════════════
	"ferry_cabin_night": {
		"prompts": [
			(LEITMOTIF_MAIN, 0.9),
			(KEY_CENTER, 1.0),
			("Chinese guqin playing the descending motif A-G-E-D-C in low octave, very slow and sparse", 1.0),
			("soft xiao flute sustained drone on E, breathy and dark", 0.8),
			("rain tapping on wooden boat hull, distant thunder, river water lapping", 0.8),
			("late Ming dynasty winter night ferry cabin, enclosed uneasy atmosphere", 0.9),
			("the motif plays once at start, then fragments appear in guqin between rain sounds", 0.8),
			("no modern instruments, no vocals, loopable, Am key, foreshadowing disaster", 1.0),
		],
		"bpm": 52,
		"duration_sec": 60,
		"description": "船舱夜航：古琴低八度奏动机+洞箫持续E音+雨声木船，Am调",
	},
	"ferry_prologue_escape": {
		"prompts": [
			(LEITMOTIF_MAIN, 0.8),
			(KEY_CENTER, 1.0),
			("urgent low cello-like erhu tremolo, frantic bowing in Am", 1.0),
			("the descending motif A-G-E-D-C played at triple speed as panicked scramble", 0.9),
			("metallic creaking, wood splintering, water rushing in, claustrophobic", 0.9),
			("heavy taiko drums irregular heartbeat pattern, building panic", 0.8),
			("sinking ship escape sequence, life or death urgency", 1.0),
			("Am key, no vocals, intense and relentless, short loops acceptable", 1.0),
		],
		"bpm": 120,
		"duration_sec": 45,
		"description": "沉船逃生：动机3倍速急奏+水涌金属嘎吱+太鼓心跳，Am调BPM120",
	},
	"ferry_prologue_shore": {
		"prompts": [
			(LEITMOTIF_MAIN, 1.0),
			(KEY_CENTER, 1.0),
			("Chinese erhu solo playing the full descending motif A-G-E-D-C very slowly, sorrowful but relieved", 1.0),
			("cold winter rain ambience fading, river at dawn", 0.7),
			("after near-death, a moment of stillness, the motif is played complete for first emotional statement", 0.9),
			("sparse guqin pluck on final C note, like a period ending a sentence", 0.7),
			("Am key, extremely slow, no percussion, no bright tones, cold but alive", 1.0),
		],
		"bpm": 48,
		"duration_sec": 50,
		"description": "获救上岸：二胡完整慢奏动机+冷雨渐消、劫后余生，Am调",
	},
	"ferry_inn_investigation": {
		"prompts": [
			(LEITMOTIF_MAIN, 0.9),
			(KEY_CENTER, 1.0),
			("Chinese guzheng playing the descending motif A-G-E-D-C as broken arpeggiated chords", 1.0),
			("soft rain on tile roof ambience, quiet inn atmosphere", 0.8),
			("the motif is spread across guzheng arpeggios, each note decorated with grace notes", 0.8),
			("subtle suspicion building, quiet investigation, something is not right", 0.8),
			("Am key, no harsh sounds, loopable, gentle dynamics, warm but uneasy", 1.0),
		],
		"bpm": 66,
		"duration_sec": 50,
		"description": "客栈调查：古筝将动机拆为分解和弦+雨打瓦片，Am调稍快",
	},
	"ferry_dock_investigation": {
		"prompts": [
			(LEITMOTIF_MAIN, 0.8),
			(KEY_CENTER, 1.0),
			("Chinese dizi flute playing only first 3 notes of motif (A-G-E) then trailing off unresolved", 1.0),
			("cold river wind ambience, wooden dock creaking, ominous emptiness", 0.8),
			("the motif is deliberately incomplete - flute plays A-G-E then silence, suggesting hidden truth", 0.9),
			("sparse guqin low plucks punctuating the silence", 0.6),
			("Am key, slow, ominous, unresolved feeling, loopable", 1.0),
		],
		"bpm": 60,
		"duration_sec": 50,
		"description": "码头调查：笛子仅奏动机前3音(A-G-E)悬而不决+江风，Am调",
	},
	"shen_corridor_theme": {
		"prompts": [
			(LEITMOTIF_SHEN, 1.0),
			(KEY_CENTER, 0.8),
			("Chinese pipa playing the dissonant ascending motif E-F-A-Bb cold and precise", 1.0),
			("guqin harmonics (artificial flageolet) on high strings, icy and crystalline", 0.8),
			("the 4-note motif E-F-A-Bb repeats with slight variations each time", 0.9),
			("dangerous feminine elegance, calculating intelligence, hidden blade", 0.9),
			("sparse metallic overtones, no warmth, Am key with Bb creating constant unease", 1.0),
			("no percussion, slow and deliberate, loopable", 0.9),
		],
		"bpm": 52,
		"duration_sec": 50,
		"description": "沈清月主题：琵琶奏角色动机(E-F-A-Bb)+古琴泛音，冷冽不协和",
	},
	"ferry_court_opening": {
		"prompts": [
			(LEITMOTIF_MAIN, 0.9),
			(KEY_CENTER, 1.0),
			("solemn Chinese tanggu drum slow cadence, court ceremony opening", 0.9),
			("guqin playing the descending motif A-G-E-D-C in middle register, dignified and stern", 1.0),
			("the motif is played once slowly as ceremonial declaration, then sustains on final C", 0.8),
			("ancient Chinese courtroom atmosphere, authority and gravity", 0.9),
			("Am key, no frivolous tones, measured and weighty, transitions to tension", 1.0),
		],
		"bpm": 60,
		"duration_sec": 45,
		"description": "对峙开庭：堂鼓缓拍+古琴庄严奏动机，Am调肃穆公堂",
	},
	"ferry_confrontation": {
		"prompts": [
			(LEITMOTIF_BOTH, 1.0),
			(KEY_CENTER, 1.0),
			("erhu playing descending motif A-G-E-D-C intensely, aggressive bowing", 1.0),
			("pipa answering with ascending motif E-F-A-Bb, sharp attack", 0.9),
			("taiko drums driving 90 BPM pulse, building layers", 0.9),
			("two motifs trading back and forth, protagonist vs antagonist musical duel", 1.0),
			("Am key, intense confrontation, no rest, no silence between phrases", 0.9),
		],
		"bpm": 90,
		"duration_sec": 50,
		"description": "渡口对峙：二胡(主动机)vs琵琶(沈动机)交锋+太鼓，Am调",
	},
	"confrontation_final": {
		"prompts": [
			(LEITMOTIF_BOTH, 1.0),
			("CLIMAX: The protagonist's descending motif A-G-E-D-C now DOMINATES, played by full ensemble in UNISON", 1.0),
			("the antagonist's motif E-F-A-Bb fragments and retreats to background", 0.8),
			("all instruments: erhu, guqin, pipa, dizi, taiko playing the main motif TOGETHER triumphantly", 1.0),
			("the motif is played in HIGHER OCTAVE and FASTER, Bb major moment of triumph then back to Am", 0.9),
			("ultimate breakthrough moment, truth revealed, justice prevails", 1.0),
			("Am key resolving, extremely intense, the musical climax of the entire case", 1.0),
		],
		"bpm": 120,
		"duration_sec": 45,
		"description": "对峙终章：全奏齐奏主动机+沈动机溃散，Am调最高潮BPM120",
	},
	"prologue_defeat": {
		"prompts": [
			(LEITMOTIF_MAIN, 1.0),
			(KEY_CENTER, 1.0),
			("Chinese erhu playing the descending motif A-G-E-D-C BACKWARDS (C-D-E-G-A ascending) very slowly", 1.0),
			("the retrograde motif represents defeat - the truth slipping away, unraveling", 0.9),
			("cold guqin sparse plucks on low A, hollow resonance", 0.8),
			("distant rain fading, winter river at dawn, emptiness after loss", 0.7),
			("melancholic but with a seed of resolve - the ascending retrograde hints at future comeback", 0.9),
			("Am key (Dm color - iv chord emphasis), no percussion, extremely slow, loopable", 1.0),
		],
		"bpm": 48,
		"duration_sec": 50,
		"description": "序章败局：二胡倒行奏动机(C-D-E-G-A)+冷雨，Am/Dm调不甘",
	},

	# ═══════════════════════════════════════════════════════════════
	# 第一案：浔阳楼·夜雨红绸案
	# 调性：Dm（Am的下属调，更悲情）
	# 动机处理：主动机移至Dm = D-C-A-G-F
	# ═══════════════════════════════════════════════════════════════
	"xunyang_main_theme": {
		"prompts": [
			("CRITICAL: Include the game's core 5-note descending motif transposed to D minor: D-C-A-G-F. "
			 "This is the same motif as A-G-E-D-C but in Dm key. Play it on xiao flute, slow and mournful.", 1.0),
			("All melodies in D minor key, Jiangnan night rain atmosphere", 1.0),
			("soft Chinese xiao bamboo flute playing the D-C-A-G-F motif, breathy and warm", 1.0),
			("low guqin drone on D, very gentle plucked sustain", 0.8),
			("light rain on river surface, distant water lapping, misty Jiangnan night", 0.8),
			("mournful but tender, avoid piercing high tones, avoid sharp percussion", 1.0),
			("soft low-mid frequencies, wide warm reverb, no sudden swells, Dm key", 1.0),
		],
		"bpm": 60,
		"duration_sec": 60,
		"description": "浔阳楼主题：洞箫奏动机Dm移调(D-C-A-G-F)+古琴+江雨，Dm调",
	},
	"xunyang_rain_courtyard": {
		"prompts": [
			("CRITICAL: Include fragments of the 5-note descending motif in D minor (D-C-A-G-F) on erhu, "
			 "played in broken fragments suggesting a crime's aftermath", 1.0),
			("All melodies in D minor key", 1.0),
			("slow Chinese erhu, mid-low register, long bow strokes, playing motif fragments D-C-A then silence", 1.0),
			("quiet guqin pluck on low D, sparse single notes", 0.7),
			("light continuous rain ambience, soft puddle drips, cold dawn after crime", 0.8),
			("avoid harsh attack, avoid bright cymbals, gentle dynamic range, Dm key", 1.0),
		],
		"bpm": 52,
		"duration_sec": 50,
		"description": "案发后院：二胡碎片化奏动机Dm+雨后冷晨、稀疏古琴，Dm调",
	},
	"xunyang_chamber_lament": {
		"prompts": [
			("CRITICAL: Include the 5-note descending motif in D minor (D-C-A-G-F) on pipa, "
			 "played as a soft lament, decorated with tremolo and grace notes", 1.0),
			("All melodies in D minor key", 1.0),
			("Chinese pipa lute solo playing the motif tenderly, soft fingerpicked", 1.0),
			("warm guzheng zither slow tremolo supporting, no harsh strikes", 0.7),
			("incense smoke ambience, intimate small room reverb, feminine sorrow", 0.8),
			("very gentle dynamics, breathy soft, Dm key, avoid loud plucks", 1.0),
		],
		"bpm": 60,
		"duration_sec": 45,
		"description": "秋菱闺阁：琵琶柔情奏动机Dm+古筝颤音，Dm调私密哀曲",
	},
	"xunyang_pavilion_warm": {
		"prompts": [
			("CRITICAL: Include the 5-note descending motif in D minor (D-C-A-G-F) "
			 "played as a duet between pipa and guzheng, warm and slightly playful", 1.0),
			("All melodies in D minor key with moments of relative F major warmth", 1.0),
			("Chinese pipa and guzheng duet, mid tempo softly plucked, motif traded between instruments", 1.0),
			("muted Chinese dizi flute in background echoing motif tail notes", 0.6),
			("rain on lattice window, warm but with undercurrent of secrecy", 0.8),
			("warm low-mid range, intimate reverb, Dm key, avoid bright cymbals", 1.0),
		],
		"bpm": 66,
		"duration_sec": 50,
		"description": "浔阳楼正厅：琵琶古筝对奏动机Dm+笛子回应，Dm调温暖",
	},
	"xunyang_convent_vigil": {
		"prompts": [
			("CRITICAL: Include the 5-note descending motif in D minor (D-C-A-G-F) on xiao flute, "
			 "extremely slow, stretched to double duration, like a prayer dissolving", 1.0),
			("All melodies in D minor key", 1.0),
			("very soft Chinese xiao flute playing stretched motif, sustained and breathy", 1.0),
			("low warm guqin drone on D, single sustained notes", 0.8),
			("faint distant wooden fish (muyu) tap on beat 1 only, very gentle", 0.5),
			("nighttime nunnery vigil, hushed devotion, absolutely no metal bells", 1.0),
			("dark calm Buddhist atmosphere, soft low frequencies, wide reverb, Dm key", 1.0),
		],
		"bpm": 48,
		"duration_sec": 50,
		"description": "慈航庵守夜：洞箫极慢拉伸动机Dm+古琴持续D+木鱼，Dm调",
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


async def generate_one(bgm_id: str, cfg: dict, client, force: bool = False) -> bool:
	out_path = OUT_DIR / f"{bgm_id}.wav"
	if out_path.exists() and not force:
		print(f"  [skip] {out_path.name} already exists (use --force to overwrite)")
		return True
	if out_path.exists() and force:
		print(f"  [overwrite] {out_path.name}")
	
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
	# 解析命令行参数（在 API key 检查之前，支持 --list 不需要 key）
	args = sys.argv[1:]
	force = "--force" in args
	if force:
		args.remove("--force")
	
	# 支持 --list 显示所有可用 bgm_id（不需要 API key）
	if "--list" in args:
		print("\n可用 BGM ID（Leitmotif 系统 | 核心动机: A-G-E-D-C | 沈清月: E-F-A-Bb）：")
		print(f"{'─'*90}")
		for bid, cfg in BGM_CONFIGS.items():
			print(f"  {bid:30s} | {cfg['bpm']:3d} BPM | {cfg['duration_sec']:2d}s | {cfg['description']}")
		print(f"\n共 {len(BGM_CONFIGS)} 首。使用: python generate_bgm.py [id...] [--force]")
		return
	
	api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
	if not api_key:
		print("请设置环境变量 GEMINI_API_KEY 或 GOOGLE_API_KEY")
		sys.exit(1)
	
	# v1alpha 是 Lyria 实时所需的 API 版本
	client = genai.Client(api_key=api_key, http_options={"api_version": "v1alpha"})
	
	target_ids = args if args else list(BGM_CONFIGS.keys())
	
	print(f"\n{'='*60}")
	print(f"  Leitmotif BGM Generator")
	print(f"  核心动机: A-G-E-D-C (Am) | 沈清月: E-F-A-Bb")
	print(f"  待生成: {len(target_ids)} 首 | Force: {force}")
	print(f"{'='*60}\n")
	
	for bgm_id in target_ids:
		if bgm_id not in BGM_CONFIGS:
			print(f"  [skip] unknown bgm: {bgm_id}")
			continue
		cfg = BGM_CONFIGS[bgm_id]
		ok = False
		for attempt in range(2):
			ok = await generate_one(bgm_id, cfg, client, force=force)
			if ok:
				break
			print(f"      retry attempt {attempt+2}/2 ...")
			await asyncio.sleep(3)
		if not ok:
			print(f"  ✗ failed: {bgm_id}")


if __name__ == "__main__":
	asyncio.run(main())
