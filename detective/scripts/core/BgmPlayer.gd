extends Node
## 全局背景音乐播放器
##
## 强力版：绕过 .import 系统，从 wav 原始字节流手动构造 AudioStreamWAV
## 避免 Godot 在 import 阶段做任何意外处理。

@export var enabled: bool = true
@export var default_volume_db: float = -12.0
@export var fade_seconds: float = 1.5
@export var debug_log: bool = true

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _current_id: String = ""
var _audio_ready: bool = false
var _pending_play: String = ""

# 流缓存（手动加载的 wav）
var _stream_cache: Dictionary = {}

## 旧的硬编码映射，作为 AssetResolver 不可用时的兜底（迁移期保留，迁移完成后可删除）。
const BGM_MAP := {
	"prologue": "main_theme",
	"main_theme": "main_theme",
	"post_station": "investigation_dark",
	"shen_residence": "investigation_dark",
	"yamen": "investigation_dark",
	"spring_wind_tower": "spring_wind",
	"guanyin_temple": "temple_quiet",
	"market": "market_calm",
	"accuse": "accuse_tension",
	"ending_perfect": "ending_warm",
	"ending_bad": "ending_cold",
}


func _ready() -> void:
	if debug_log:
		print("[BGM] Ready (waiting for register_players from MainGame).")


func register_players(_a: AudioStreamPlayer, _b: AudioStreamPlayer) -> void:
	# 诊断模式：忽略传入的场景节点，直接代码 new 两个 player（同 VoicePlayer 的写法）
	_player_a = AudioStreamPlayer.new()
	_player_a.name = "BgmAlt_A"
	_player_a.bus = "Master"
	add_child(_player_a)
	_player_b = AudioStreamPlayer.new()
	_player_b.name = "BgmAlt_B"
	_player_b.bus = "Master"
	add_child(_player_b)
	_active_player = _player_a
	_audio_ready = true
	if debug_log:
		print("[BGM] players created (autoload add_child).")
	if _pending_play != "":
		var p := _pending_play
		_pending_play = ""
		play(p)


func play(id: String) -> void:
	if not enabled:
		return
	if not _audio_ready:
		_pending_play = id
		return
	if id == _current_id and _active_player and _active_player.playing:
		return
	# 优先走 AssetResolver：location_id / mood_tag / track_id 都能解析
	var bgm_name: String = ""
	var resolver := get_node_or_null("/root/AssetResolver")
	if resolver and resolver.has_method("resolve_bgm_track"):
		bgm_name = resolver.resolve_bgm_track(id)
	# 回退到旧的硬编码映射（迁移期兜底）
	if bgm_name == "":
		bgm_name = BGM_MAP.get(id, id)
	var stream := _load_stream_raw(bgm_name)
	if debug_log:
		print("[BGM] play('", id, "') → bgm_name='", bgm_name, "', stream=", stream)
	if stream == null:
		fade_out()
		_current_id = id
		return
	_current_id = id
	_play_stream(stream)


func fade_out() -> void:
	if _active_player and _active_player.playing:
		var tw := create_tween()
		tw.tween_property(_active_player, "volume_db", -80.0, fade_seconds)
		tw.tween_callback(_active_player.stop)


func stop() -> void:
	if _player_a: _player_a.stop()
	if _player_b: _player_b.stop()
	_current_id = ""


func current_bgm_id() -> String:
	return _current_id


func set_enabled(v: bool) -> void:
	enabled = v
	if not v:
		stop()


## 直接从源 WAV 文件字节流构造 AudioStreamWAV，绕过 import 系统
func _load_stream_raw(bgm_name: String) -> AudioStreamWAV:
	if _stream_cache.has(bgm_name):
		return _stream_cache[bgm_name]
	var path := "res://assets/cn/bgm/%s.wav" % bgm_name
	if not FileAccess.file_exists(path):
		if debug_log:
			print("[BGM] file not found: ", path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var bytes := f.get_buffer(f.get_length())
	f.close()
	
	var stream := _parse_wav_to_stream(bytes)
	if stream == null:
		if debug_log:
			print("[BGM] WAV parse failed: ", path)
		return null
	_stream_cache[bgm_name] = stream
	if debug_log:
		print("[BGM] loaded raw WAV ", path, " stereo=", stream.stereo, " rate=", stream.mix_rate, " data_len=", stream.data.size())
	return stream


func _parse_wav_to_stream(bytes: PackedByteArray) -> AudioStreamWAV:
	# 极简 RIFF/WAVE 解析，只支持 PCM16 / mono+stereo
	if bytes.size() < 44:
		return null
	if bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	if bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
		return null
	# 找 fmt 和 data chunk
	var pos := 12
	var channels := 0
	var rate := 0
	var bits := 0
	var data_offset := -1
	var data_len := 0
	while pos + 8 <= bytes.size():
		var chunk_id := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var chunk_size := bytes.decode_u32(pos + 4)
		if chunk_id == "fmt ":
			# format = bytes[pos+8..]:  fmt_tag(2), channels(2), rate(4), byterate(4), block(2), bits(2)
			channels = bytes.decode_u16(pos + 8 + 2)
			rate = bytes.decode_u32(pos + 8 + 4)
			bits = bytes.decode_u16(pos + 8 + 14)
		elif chunk_id == "data":
			data_offset = pos + 8
			data_len = int(chunk_size)
			break
		pos += 8 + int(chunk_size)
		# chunk_size 奇数时需要 pad 1 字节
		if chunk_size % 2 == 1:
			pos += 1
	if data_offset < 0 or bits != 16:
		return null
	var pcm := bytes.slice(data_offset, data_offset + data_len)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = (channels == 2)
	stream.mix_rate = rate
	# 重要：不要在这里设置 LOOP_FORWARD + loop_end=0。
	# Godot 会把 loop_begin==loop_end 当成 0 长度循环，导致 play() 后立刻停止。
	# 先正常播放；循环由 _on_bgm_finished 手动重播。
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.loop_begin = 0
	stream.loop_end = 0
	stream.data = pcm
	return stream


func _play_stream(stream: AudioStreamWAV) -> void:
	var old_player := _active_player
	var next_player: AudioStreamPlayer = _player_b if _active_player == _player_a else _player_a
	next_player.stream = stream
	# 先不用 Tween，直接 0dB 播放，排除淡入 Tween 未执行导致一直 -80dB 的问题
	next_player.volume_db = default_volume_db
	next_player.play()
	# 手动循环：避免 AudioStreamWAV 的 loop_end 配置导致 0 长度循环。
	# 切歌时同一个 player 可能还残留上一条 finished 连接，先安全断开再连接。
	var finished_cb := _on_bgm_finished.bind(next_player)
	if next_player.finished.is_connected(finished_cb):
		next_player.finished.disconnect(finished_cb)
	next_player.finished.connect(finished_cb, CONNECT_ONE_SHOT)
	
	if old_player and old_player.playing and old_player != next_player:
		old_player.stop()
	
	if debug_log:
		print("[BGM] start raw stream on ", next_player.name, " playing=", next_player.playing, " volume_db=", next_player.volume_db, " pos=", next_player.get_playback_position())
		await get_tree().create_timer(1.0).timeout
		print("[BGM] after 1s playing=", next_player.playing, " volume_db=", next_player.volume_db, " pos=", next_player.get_playback_position())
	
	_active_player = next_player


func _on_bgm_finished(player: AudioStreamPlayer) -> void:
	# 当前 active player 播完时重播，实现 BGM 循环
	if player == _active_player and _current_id != "" and player.stream != null:
		player.play()
		var finished_cb := _on_bgm_finished.bind(player)
		if player.finished.is_connected(finished_cb):
			player.finished.disconnect(finished_cb)
		player.finished.connect(finished_cb, CONNECT_ONE_SHOT)
