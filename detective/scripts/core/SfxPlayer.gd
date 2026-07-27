extends Node
## 音效播放器（SFX Player）
##
## 轻量级音效播放器，用于环境/事件/UI 一次性音效。
## 使用 3 个 AudioStreamPlayer 池实现多音效同时播放（不会互相打断）。
## 路径解析：res://assets/cn/sfx/{sfx_id}.wav（或 .mp3）

@export var enabled: bool = true
@export var default_volume_db: float = -3.0
@export var debug_log: bool = false

var _players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0
var _stream_cache: Dictionary = {}
var _loop_stream_cache: Dictionary = {}
var _loop_player: AudioStreamPlayer = null

const POOL_SIZE := 3
const SFX_BASE_PATH := "res://assets/cn/sfx/"


func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer_%d" % i
		p.bus = "Master"
		p.volume_db = default_volume_db
		add_child(p)
		_players.append(p)
	if debug_log:
		print("[SFX] Ready, pool size: ", POOL_SIZE)


## 播放音效。sfx_id 对应 res://assets/cn/sfx/{sfx_id}.wav 或 .mp3
func play(sfx_id: String, volume_db: float = -100.0) -> void:
	if not enabled or sfx_id == "":
		return
	var stream := _load_stream(sfx_id)
	if stream == null:
		if debug_log:
			print("[SFX] not found: ", sfx_id)
		return
	var player := _get_next_player()
	player.stream = stream
	player.volume_db = volume_db if volume_db > -100.0 else default_volume_db
	player.play()
	if debug_log:
		print("[SFX] play: ", sfx_id, " on player ", _next_player_idx)


## 停止所有正在播放的音效
func stop_all() -> void:
	for p in _players:
		p.stop()
	stop_loop()


## 循环播放环境音（雨声/人群声等铺底）。独立于一次性音效的流缓存，
## 避免给共享 stream 设置 loop 后污染一次性播放。
func play_loop(sfx_id: String, volume_db: float = -100.0) -> void:
	if not enabled or sfx_id == "":
		return
	var stream := _load_loop_stream(sfx_id)
	if stream == null:
		if debug_log:
			print("[SFX] loop not found: ", sfx_id)
		return
	if _loop_player == null:
		_loop_player = AudioStreamPlayer.new()
		_loop_player.name = "SfxLoopPlayer"
		_loop_player.bus = "Master"
		add_child(_loop_player)
	_loop_player.stream = stream
	_loop_player.volume_db = volume_db if volume_db > -100.0 else default_volume_db
	_loop_player.play()
	if debug_log:
		print("[SFX] play_loop: ", sfx_id)


## 停止循环环境音
func stop_loop() -> void:
	if _loop_player and _loop_player.playing:
		_loop_player.stop()


func _load_loop_stream(sfx_id: String) -> AudioStream:
	if _loop_stream_cache.has(sfx_id):
		return _loop_stream_cache[sfx_id]
	var base := _load_stream(sfx_id)
	if base == null:
		return null
	var stream := base.duplicate()
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = 0
	_loop_stream_cache[sfx_id] = stream
	return stream


## 设置是否启用
func set_enabled(v: bool) -> void:
	enabled = v
	if not v:
		stop_all()


func _get_next_player() -> AudioStreamPlayer:
	# 优先选空闲的 player
	for p in _players:
		if not p.playing:
			return p
	# 都在播放时轮转覆盖最旧的
	var p := _players[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % POOL_SIZE
	return p


func _load_stream(sfx_id: String) -> AudioStream:
	if _stream_cache.has(sfx_id):
		return _stream_cache[sfx_id]
	# 尝试 wav
	var path := SFX_BASE_PATH + sfx_id + ".wav"
	if not ResourceLoader.exists(path):
		# 尝试 mp3
		path = SFX_BASE_PATH + sfx_id + ".mp3"
	if not ResourceLoader.exists(path):
		# 尝试 ogg
		path = SFX_BASE_PATH + sfx_id + ".ogg"
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	if stream != null:
		_stream_cache[sfx_id] = stream
	return stream
