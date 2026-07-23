extends Node
## 全局背景音乐播放器
##
## 使用标准 load() 加载已导入的 AudioStreamWAV 资源，兼容编辑器和导出版本。

@export var enabled: bool = true
@export var default_volume_db: float = -12.0
@export var fade_seconds: float = 1.5
@export var debug_log: bool = true

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _current_id: String = ""
var _current_bgm_name: String = ""
var _audio_ready: bool = false
var _pending_play: String = ""

# 流缓存
var _stream_cache: Dictionary = {}

## BGM 映射全部走 AssetResolver.resolve_bgm_track（各案 bgm_config 数据驱动）。
## 数据未覆盖的 id 按"id 即曲目名"回退（原硬编码 BGM_MAP 已删除）。


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
	# 优先走 AssetResolver：location_id / mood_tag / track_id 都能解析
	var bgm_name: String = ""
	var resolver := get_node_or_null("/root/AssetResolver")
	if resolver and resolver.has_method("resolve_bgm_track"):
		bgm_name = resolver.resolve_bgm_track(id)
	# 数据未覆盖的 id：按"id 即曲目名"回退
	if bgm_name == "":
		bgm_name = id
	# 同一首曲目不重播，即使 id 不同（如不同地点映射到同一 BGM）
	if bgm_name == _current_bgm_name and _active_player and _active_player.playing:
		_current_id = id
		return
	var stream := _load_stream_raw(bgm_name)
	if debug_log:
		print("[BGM] play('", id, "') → bgm_name='", bgm_name, "', stream=", stream)
	if stream == null:
		fade_out()
		_current_id = id
		_current_bgm_name = ""
		return
	_current_id = id
	_current_bgm_name = bgm_name
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
	_current_bgm_name = ""


func current_bgm_id() -> String:
	return _current_id


func set_enabled(v: bool) -> void:
	enabled = v
	if not v:
		stop()


## 加载 BGM 音频资源，支持 .wav 和 .mp3 格式
func _load_stream_raw(bgm_name: String) -> AudioStream:
	if _stream_cache.has(bgm_name):
		return _stream_cache[bgm_name]
	# 优先从 AssetResolver 的 registry 获取完整路径
	var path := ""
	var resolver := get_node_or_null("/root/AssetResolver")
	if resolver and resolver.has_method("get_bgm_file"):
		path = resolver.get_bgm_file(bgm_name)
	# 回退：按 track_id 尝试 wav / mp3
	if path == "" or not ResourceLoader.exists(path):
		path = "res://assets/cn/bgm/%s.wav" % bgm_name
	if not ResourceLoader.exists(path):
		path = "res://assets/cn/bgm/%s.mp3" % bgm_name
	if not ResourceLoader.exists(path):
		if debug_log:
			print("[BGM] resource not found: ", bgm_name)
		return null
	var stream: AudioStream = load(path)
	if stream == null:
		if debug_log:
			print("[BGM] load failed: ", path)
		return null
	# WAV 格式：禁用内置循环（手动循环）
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		stream.loop_begin = 0
		stream.loop_end = 0
	_stream_cache[bgm_name] = stream
	if debug_log:
		if stream is AudioStreamWAV:
			print("[BGM] loaded ", path, " stereo=", stream.stereo, " rate=", stream.mix_rate, " data_len=", stream.data.size())
		else:
			print("[BGM] loaded ", path, " (", stream.get_class(), ")")
	return stream


func _play_stream(stream: AudioStream) -> void:
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
