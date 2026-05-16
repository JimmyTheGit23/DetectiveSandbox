extends Node
## 全局语音播放器：根据 NPC + 节点 ID 播放对应配音
## 文件路径约定：res://assets/cn/voices/{npc_id}/{node_id}.wav
## 序章特殊：res://assets/cn/voices/_prologue/{node_id}.wav
##
## 同一次对话内若已经播放过的节点，不再重复播放（避免反复回到 intro 时重听）

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
	var path := "res://assets/cn/voices/%s/%s.wav" % [npc_id, node_id]
	if _play_path(path):
		_played_in_session[key] = true


func play_narration(node_id: String) -> void:
	if not enabled:
		return
	var key := "nar:%s" % node_id
	if _played_in_session.has(key):
		stop()
		return
	var path := "res://assets/cn/voices/_prologue/%s.wav" % node_id
	if _play_path(path):
		_played_in_session[key] = true


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
