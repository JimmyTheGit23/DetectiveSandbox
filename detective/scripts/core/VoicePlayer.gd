extends Node
## 全局语音播放器：根据 NPC + 节点 ID 播放对应配音
##
## 严格按案件隔离 —— 路径解析全部委托给 AssetResolver，本地不再做任何路径拼接兜底。
## 这样可以彻底防止跨案件错乱（例如浔阳楼案的 ma_san 错误回退到临川驿案的 ma_san 语音）。
##
## 路径约定（仅由 AssetResolver 内部使用）：
##   - 对话：voices/{actor_id}/{case_id}/{node_id}.wav  （首选）
##           voices/{actor_id}/{node_id}.wav             （仅 voice_status=full 允许，演员通用台词）
##   - 序章：voices/_prologue/{case_id}/{node_id}.wav   （首选）
##           voices/_prologue/{node_id}.wav              （仅 voice_status=full 允许，旧路径兼容）
##   - 事件：voices/_events/{case_id}/{evt_id}_{idx}.wav（首选）
##           voices/_events/{evt_id}_{idx}.wav           （仅 voice_status=full 允许，旧路径兼容）
##
## voice_status=missing/partial 时，找不到当前案件文件就**完全静默**——绝不播错的语音。

var _player: AudioStreamPlayer
var _played_in_session: Dictionary = {}  # 本次对话已播放节点 key -> true

@export var enabled: bool = true
@export var volume_db: float = 0.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = volume_db
	add_child(_player)


func begin_session() -> void:
	## 开始一次新的对话/序章，清空"已播放"记录
	_played_in_session.clear()


func end_session() -> void:
	_played_in_session.clear()
	stop()


func play_dialogue(npc_id: String, node_id: String) -> void:
	if not enabled:
		return
	var key := "dlg:%s:%s" % [npc_id, node_id]
	if _played_in_session.has(key):
		# 本次对话已播放过这个节点 → 跳过，但仍停掉当前可能正在播放的旧音
		stop()
		return
	# 完全委托给 AssetResolver。返回 "" 即视为本节点无语音，静默。
	var resolver := get_node_or_null("/root/AssetResolver")
	if resolver == null or not resolver.has_method("resolve_voice_path"):
		return
	var path: String = resolver.resolve_voice_path(npc_id, node_id)
	if path == "":
		# 没有语音就静默 —— 绝不播跨案件的错位语音
		stop()
		return
	if _play_path(path):
		_played_in_session[key] = true


func play_narration(node_id: String) -> void:
	if not enabled:
		return
	var key := "nar:%s" % node_id
	if _played_in_session.has(key):
		stop()
		return
	var resolver := get_node_or_null("/root/AssetResolver")
	if resolver == null or not resolver.has_method("resolve_prologue_voice_path"):
		return
	var path: String = resolver.resolve_prologue_voice_path(node_id)
	if path == "":
		stop()
		return
	if _play_path(path):
		_played_in_session[key] = true


## 由 MainGame 在派发事件叙述时调用：解析事件语音路径并播放。
func play_event_narration(evt_id: String, idx: int) -> void:
	if not enabled:
		return
	var resolver := get_node_or_null("/root/AssetResolver")
	if resolver == null or not resolver.has_method("resolve_event_voice_path"):
		return
	var path: String = resolver.resolve_event_voice_path(evt_id, idx)
	play_voice_path(path)


func play_voice_path(path: String) -> void:
	if not enabled:
		return
	if path == "":
		stop()
		return
	_play_path(path)


func stop() -> void:
	if _player and _player.playing:
		_player.stop()


func _play_path(path: String) -> bool:
	stop()
	if not ResourceLoader.exists(path):
		# 静默跳过：还没生成的台词不会报错
		return false
	var stream: AudioStream = load(path)
	if stream == null:
		return false
	_player.stream = stream
	_player.play()
	return true

