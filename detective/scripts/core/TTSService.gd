extends Node
## MiniMax TTS 服务（文本转语音）
## 当 VoicePlayer 没有预录音频时，自动调用 TTS 生成语音并缓存
##
## MiniMax TTS API 格式：
##   POST https://api.minimaxi.com/v1/t2a_v2
##   Body: {"model":"speech-01-turbo","text":"文本","voice_setting":{"voice_id":"voice_id"}}
##   Response: {"base_resp":{"status_code":0},"data":{"audio":"hex_encoded_audio"}}

signal tts_ready(npc_id: String, node_id: String, path: String)
signal tts_error(npc_id: String, node_id: String, err: String)

const CACHE_DIR := "user://tts_cache/"

var _api_key: String = ""
var _api_url: String = "https://api.minimaxi.com/v1/t2a_v2"
var _model: String = "speech-01-turbo"
var _voice_map: Dictionary = {}   # npc_id -> voice_id
var _enabled: bool = true
var _requesting: Dictionary = {}  # key -> HTTPRequest
var _initialized: bool = false


func _ready() -> void:
	_load_config()
	_ensure_cache_dir()
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
	_api_url = data.get("api_url", _api_url)
	_model = data.get("model", _model)
	_voice_map = data.get("voice_map", {})
	_enabled = data.get("enabled", true)
	_initialized = true
	print("[TTSService] MiniMax TTS initialized, url=%s model=%s" % [_api_url, _model])


func _ensure_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)


func is_available() -> bool:
	return _enabled and _initialized and _api_key != ""


func get_voice_id(npc_id: String) -> String:
	return _voice_map.get(npc_id, "")


func try_play_cached(npc_id: String, node_id: String) -> bool:
	if not is_available():
		return false
	var cache_path := _cache_path(npc_id, node_id)
	if FileAccess.file_exists(cache_path):
		VoicePlayer.play_voice_path(cache_path)
		return true
	return false


## 为主角/说话人请求 TTS 并立即播放（ConfrontationPanel 调用此方法）
## style_hint: 可选的风格指令（MiniMax 通过 speed/volume 等参数控制，此处暂不使用）
func request_tts_speaker(speaker_name: String, text: String, voice_id: String = "", style_hint: String = "") -> void:
	if not is_available():
		print("[TTSService] request_tts_speaker: not available")
		return

	# 从 voice_id（npc_id）获取 voice_name
	var voice_name := voice_id
	if voice_name != "" and _voice_map.has(voice_name):
		voice_name = _voice_map[voice_name]

	# 尝试反查
	if voice_name == "" or voice_name == voice_id:
		for nid in _voice_map:
			var npc_display := ""
			if has_node("/root/GameManager"):
				var npc_data := GameManager.get_npc_data(nid)
				npc_display = str(npc_data.get("name", ""))
			if npc_display == speaker_name or nid == speaker_name:
				voice_name = _voice_map[nid]
				break

	if voice_name == "":
		# 回退：使用默认语音
		voice_name = "male-qn-jingying-jingpin"
		print("[TTSService] No voice found for '%s', using default" % speaker_name)

	# 缓存 key（包含 style_hint 的 hash 以区分不同风格）
	var style_hash := hash(style_hint) if style_hint != "" else 0
	var cache_key := "speaker_%s_%d_%d" % [speaker_name, hash(text), style_hash]
	var cache_path := CACHE_DIR + cache_key + ".mp3"
	if FileAccess.file_exists(cache_path):
		print("[TTSService] Cache hit: %s" % cache_path)
		VoicePlayer.play_voice_path(cache_path)
		return

	var http := HTTPRequest.new()
	add_child(http)
	_requesting[cache_key] = http

	var body := _build_request(text, voice_name, style_hint)
	var headers := [
		"Authorization: Bearer " + _api_key,
		"Content-Type: application/json"
	]

	print("[TTSService] Speaker TTS: name='%s' voice='%s' text='%s'" % [speaker_name, voice_name, text.left(30)])
	http.request_completed.connect(_on_speaker_response.bind(cache_path, cache_key, http))
	http.request_raw(_api_url, headers, HTTPClient.METHOD_POST, body.to_utf8_buffer())


## 为指定 NPC 请求 TTS（异步）
func request_tts(npc_id: String, node_id: String, text: String) -> void:
	if not is_available():
		return
	var key := "%s.%s" % [npc_id, node_id]
	if _requesting.has(key):
		return

	var voice_name := get_voice_id(npc_id)
	if voice_name == "":
		return

	# 检查缓存
	var cache_path := _cache_path(npc_id, node_id)
	if FileAccess.file_exists(cache_path):
		tts_ready.emit(npc_id, node_id, cache_path)
		return

	var http := HTTPRequest.new()
	add_child(http)
	_requesting[key] = http

	var body := _build_request(text, voice_name)
	var headers := [
		"Authorization: Bearer " + _api_key,
		"Content-Type: application/json"
	]

	print("[TTSService] Requesting TTS: npc=%s text='%s' voice=%s" % [npc_id, text.left(30), voice_name])
	http.request_completed.connect(_on_tts_response.bind(npc_id, node_id, key, http))
	http.request_raw(_api_url, headers, HTTPClient.METHOD_POST, body.to_utf8_buffer())


## 构建 MiniMax TTS 请求体
func _build_request(text: String, voice_name: String, _style_hint: String = "") -> String:
	return JSON.stringify({
		"model": _model,
		"text": text,
		"voice_setting": {
			"voice_id": voice_name
		}
	})


func _on_tts_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray,
		npc_id: String, node_id: String, key: String, http: HTTPRequest) -> void:
	_requesting.erase(key)
	http.queue_free()

	print("[TTSService] Response: result=%d code=%d body_size=%d" % [result, code, body.size()])

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		var err_text := "HTTP error result=%d code=%d" % [result, code]
		if body.size() > 0:
			err_text += " body=" + body.get_string_from_utf8().left(500)
		push_warning("TTSService: " + err_text)
		print("[TTSService] ERROR: " + err_text)
		tts_error.emit(npc_id, node_id, err_text)
		return

	# 解析 JSON 响应
	var body_text := body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(body_text) != OK:
		print("[TTSService] JSON parse error")
		tts_error.emit(npc_id, node_id, "JSON parse error")
		return

	var data: Dictionary = json.data

	# 检查 MiniMax base_resp 错误
	var base_resp: Dictionary = data.get("base_resp", {})
	var status_code: int = base_resp.get("status_code", 0)
	if status_code != 0:
		var err_msg: String = base_resp.get("status_msg", "unknown error")
		print("[TTSService] API error: code=%d msg=%s" % [status_code, err_msg])
		tts_error.emit(npc_id, node_id, err_msg)
		return

	# 提取音频数据（hex 编码）
	var audio_data: Dictionary = data.get("data", {})
	var audio_hex: String = audio_data.get("audio", "")

	if audio_hex == "":
		print("[TTSService] No audio data in response")
		tts_error.emit(npc_id, node_id, "no audio data")
		return

	# 解码 hex 音频并保存
	var cache_path := _cache_path(npc_id, node_id)
	_save_hex_audio(audio_hex, cache_path)

	print("[TTSService] Saved audio to %s" % cache_path)
	tts_ready.emit(npc_id, node_id, cache_path)


func _on_speaker_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray,
		cache_path: String, key: String, http: HTTPRequest) -> void:
	_requesting.erase(key)
	http.queue_free()

	print("[TTSService] Speaker response: result=%d code=%d body_size=%d" % [result, code, body.size()])

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		var err_text := "HTTP error result=%d code=%d" % [result, code]
		if body.size() > 0:
			err_text += " body=" + body.get_string_from_utf8().left(500)
		push_warning("TTSService speaker: " + err_text)
		print("[TTSService] ERROR: " + err_text)
		return

	var body_text := body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(body_text) != OK:
		print("[TTSService] Speaker JSON parse error")
		return

	var data: Dictionary = json.data

	# 检查 MiniMax base_resp 错误
	var base_resp: Dictionary = data.get("base_resp", {})
	var status_code: int = base_resp.get("status_code", 0)
	if status_code != 0:
		var err_msg: String = base_resp.get("status_msg", "unknown error")
		print("[TTSService] Speaker API error: code=%d msg=%s" % [status_code, err_msg])
		return

	var audio_data: Dictionary = data.get("data", {})
	var audio_hex: String = audio_data.get("audio", "")

	if audio_hex == "":
		print("[TTSService] Speaker: no audio data")
		return

	_save_hex_audio(audio_hex, cache_path)

	print("[TTSService] Speaker saved audio to %s" % cache_path)
	VoicePlayer.play_voice_path(cache_path)


## 将 hex 编码的音频数据保存为 mp3 文件
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


func _on_tts_auto_play(_npc_id: String, _node_id: String, path: String) -> void:
	VoicePlayer.play_voice_path(path)