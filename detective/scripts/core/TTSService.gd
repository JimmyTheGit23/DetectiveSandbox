extends Node
## MiniMax TTS 服务：通过 Token Plan Key 调用语音合成 API
## 当 VoicePlayer 没有预录音频时，自动调用 TTS 生成语音并缓存

signal tts_ready(npc_id: String, node_id: String, path: String)
signal tts_error(npc_id: String, node_id: String, err: String)

const TTS_API_URL := "https://api.minimaxi.com/v1/t2a_v2"
const CACHE_DIR := "user://tts_cache/"

var _api_key: String = ""
var _model: String = "speech-2.6-hd"
var _voice_map: Dictionary = {}   # npc_id -> voice_id
var _speed: float = 1.0
var _enabled: bool = true
var _requesting: Dictionary = {}  # key ->HTTPRequest
var _initialized: bool = false


func _ready() -> void:
	_load_config()
	_ensure_cache_dir()
	# 监听自己的信号，生成完毕后自动播放
	tts_ready.connect(_on_tts_auto_play)


func _load_config() -> void:
	var config_path := "res://tts_config.json"
	if not FileAccess.file_exists(config_path):
		push_warning("TTSService: tts_config.json not found, TTS disabled")
		_enabled = false
		return
	var f := FileAccess.open(config_path, FileAccess.READ)
	if f == null:
		push_warning("TTSService: cannot read tts_config.json")
		_enabled = false
		return
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err != OK:
		push_warning("TTSService: tts_config.json parse error: " + json.get_error_message())
		_enabled = false
		return
	var data: Dictionary = json.data
	_api_key = data.get("api_key", "")
	if _api_key == "":
		push_warning("TTSService: api_key is empty, TTS disabled")
		_enabled = false
		return
	_model = data.get("model", "speech-2.6-hd")
	_speed = data.get("speed", 1.0)
	_voice_map = data.get("voice_map", {})
	_enabled = data.get("enabled", true)
	_initialized = true


func _ensure_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)


## 判断 TTS 是否可用
func is_available() -> bool:
	return _enabled and _initialized and _api_key != ""


## 获取 NPC 对应的 voice_id
func get_voice_id(npc_id: String) -> String:
	return _voice_map.get(npc_id, "")


## 尝试播放缓存的 TTS 音频，返回是否命中缓存
func try_play_cached(npc_id: String, node_id: String) -> bool:
	if not is_available():
		return false
	var cache_path := _cache_path(npc_id, node_id)
	if FileAccess.file_exists(cache_path):
		# 通过 VoicePlayer 播放
		VoicePlayer.play_voice_path(cache_path)
		return true
	return false


## 请求 TTS 生成语音（异步），完成后通过信号通知
func request_tts(npc_id: String, node_id: String, text: String) -> void:
	if not is_available():
		return
	var key := "%s.%s" % [npc_id, node_id]
	if _requesting.has(key):
		return  # 已在请求中

	var voice_id := get_voice_id(npc_id)
	if voice_id == "":
		return  # 没有配置该 NPC 的音色

	# 检查缓存
	var cache_path := _cache_path(npc_id, node_id)
	if FileAccess.file_exists(cache_path):
		tts_ready.emit(npc_id, node_id, cache_path)
		return

	# 发起 HTTP 请求
	var http := HTTPRequest.new()
	add_child(http)
	_requesting[key] = http

	var body := JSON.stringify({
		"model": _model,
		"text": text,
		"stream": false,
		"output_format": "hex",
		"voice_setting": {
			"voice_id": voice_id,
			"speed": _speed,
			"vol": 1.0,
			"pitch": 0
		},
		"audio_setting": {
			"sample_rate": 32000,
			"bitrate": 128000,
			"format": "mp3",
			"channel": 1
		},
		"language_boost": "Chinese"
	})

	var headers := [
		"Authorization: Bearer " + _api_key,
		"Content-Type: application/json"
	]

	http.request_completed.connect(_on_tts_response.bind(npc_id, node_id, key, http))
	http.request_raw(TTS_API_URL, headers, HTTPClient.METHOD_POST, body.to_utf8_buffer())


## 请求 TTS 并立即播放旁白/叙述文本
func request_tts_speaker(speaker_name: String, text: String, voice_id: String = "") -> void:
	if not is_available():
		return
	if voice_id == "":
		# 尝试从 voice_map 反查
		for nid in _voice_map:
			var npc_data := GameManager.get_npc_data(nid)
			if npc_data.get("name", "") == speaker_name:
				voice_id = _voice_map[nid]
				break
	if voice_id == "":
		return  # 无法匹配音色

	# 用 speaker_name + text hash 做缓存 key
	var cache_key := "narration_%s_%d" % [speaker_name, hash(text)]
	var cache_path := CACHE_DIR + cache_key + ".mp3"
	if FileAccess.file_exists(cache_path):
		VoicePlayer.play_voice_path(cache_path)
		return

	var http := HTTPRequest.new()
	add_child(http)
	_requesting[cache_key] = http

	var body := JSON.stringify({
		"model": _model,
		"text": text,
		"stream": false,
		"output_format": "hex",
		"voice_setting": {
			"voice_id": voice_id,
			"speed": _speed,
			"vol": 1.0,
			"pitch": 0
		},
		"audio_setting": {
			"sample_rate": 32000,
			"bitrate": 128000,
			"format": "mp3",
			"channel": 1
		},
		"language_boost": "Chinese"
	})

	var headers := [
		"Authorization: Bearer " + _api_key,
		"Content-Type: application/json"
	]

	http.request_completed.connect(_on_narration_response.bind(cache_path, cache_key, http))
	http.request_raw(TTS_API_URL, headers, HTTPClient.METHOD_POST, body.to_utf8_buffer())


func _on_tts_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray,
		npc_id: String, node_id: String, key: String, http: HTTPRequest) -> void:
	_requesting.erase(key)
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		var err_text := "HTTP error result=%d code=%d" % [result, code]
		if body.size() > 0:
			err_text += " body=" + body.get_string_from_utf8().left(200)
		push_warning("TTSService: " + err_text)
		tts_error.emit(npc_id, node_id, err_text)
		return

	var json := JSON.new()
	var parse_err := json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		tts_error.emit(npc_id, node_id, "JSON parse error")
		return

	var data: Dictionary = json.data
	var base_resp: Dictionary = data.get("base_resp", {})
	if base_resp.get("status_code", -1) != 0:
		tts_error.emit(npc_id, node_id, "API error: " + str(base_resp.get("status_msg", "unknown")))
		return

	var audio_hex: String = data.get("data", {}).get("audio", "")
	if audio_hex == "":
		tts_error.emit(npc_id, node_id, "empty audio data")
		return

	# 解码 hex 并保存为 mp3
	var cache_path := _cache_path(npc_id, node_id)
	_save_hex_audio(audio_hex, cache_path)

	tts_ready.emit(npc_id, node_id, cache_path)


func _on_narration_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray,
		cache_path: String, key: String, http: HTTPRequest) -> void:
	_requesting.erase(key)
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_warning("TTSService narration: HTTP error result=%d code=%d" % [result, code])
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return

	var data: Dictionary = json.data
	var base_resp: Dictionary = data.get("base_resp", {})
	if base_resp.get("status_code", -1) != 0:
		return

	var audio_hex: String = data.get("data", {}).get("audio", "")
	if audio_hex == "":
		return

	_save_hex_audio(audio_hex, cache_path)
	VoicePlayer.play_voice_path(cache_path)


func _save_hex_audio(hex_str: String, path: String) -> void:
	var bytes := PackedByteArray()
	for i in range(0, hex_str.length(), 2):
		var byte_val := hex_str.substr(i, 2).hex_to_int()
		bytes.append(byte_val)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_buffer(bytes)
		f.close()


func _cache_path(npc_id: String, node_id: String) -> String:
	return CACHE_DIR + "%s_%s.mp3" % [npc_id, node_id]


## 清空 TTS 缓存
func clear_cache() -> void:
	var dir := DirAccess.open(CACHE_DIR)
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not dir.current_is_dir():
				dir.remove(fname)
			fname = dir.get_next()
		dir.list_dir_end()


## TTS 生成完毕后自动播放
func _on_tts_auto_play(_npc_id: String, _node_id: String, path: String) -> void:
	VoicePlayer.play_voice_path(path)
