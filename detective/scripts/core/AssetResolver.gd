extends Node
## 全局资产解析器（Asset Resolver）
##
## 角色 / 地点 / 氛围 → 实际资产路径的统一翻译层。
## 通过引入"演员 / 场景 / BGM 三大注册表 + 案件级 casting 选角表"实现资产与案件的解耦：
##
##   npc_id ──(casting.json)──> actor_id ──(actors/registry.json)──> portrait + voice_config
##   location_id ──(locations.json.scene_type)──> scene_id ──(scenes/registry.json)──> background
##   bgm_tag ──(bgm/registry.json.mood_index)──> track_id ──> wav 文件
##
## 兼容策略：所有 get_* 都先走新链路，找不到时回退到旧的直接字段（npcs.json.portrait /
## locations.json.background / BgmPlayer.BGM_MAP），保证临川驿案在迁移过程中始终可玩。
##
## 设计目标：让 VoicePlayer / BgmPlayer / DialogueManager 等运行时模块只持有"逻辑 ID"，
## 不再持有任何具体文件路径。

const ACTORS_REGISTRY_PATH := "res://data/actors/registry.json"
const SCENES_REGISTRY_PATH := "res://data/scenes/registry.json"
const BGM_REGISTRY_PATH := "res://data/bgm/registry.json"

# 加载后的内存缓存
var _actors: Dictionary = {}      # actor_id -> actor_def
var _scenes: Dictionary = {}      # scene_id -> scene_def
var _bgm_tracks: Dictionary = {}  # track_id -> track_def
var _bgm_mood_index: Dictionary = {}  # mood_tag -> [track_id, ...]

# 案件级数据（按当前案件加载，可被切换）
var _current_case_id: String = ""
var _casting: Dictionary = {}         # role_npc_id -> casting_entry
var _bgm_config: Dictionary = {}      # bgm_config.json 内容
var _voice_status: String = "full"    # 当前案件的语音状态：full / partial / missing

# 调试
@export var debug_log: bool = false


func _ready() -> void:
	_load_registries()
	# 注意：案件级数据（casting / bgm_config）由 GameManager 在 _load_data() 时主动调用 load_case() 灌入
	# 这里不主动读，避免和 GameManager 的案件切换逻辑耦合


# ─── 注册表加载 ───
func _load_registries() -> void:
	_actors = _read_section(ACTORS_REGISTRY_PATH, "actors")
	_scenes = _read_section(SCENES_REGISTRY_PATH, "scenes")
	var bgm_root := _read_dict(BGM_REGISTRY_PATH)
	_bgm_tracks = bgm_root.get("tracks", {})
	_bgm_mood_index = bgm_root.get("mood_index", {})
	if debug_log:
		print("[AssetResolver] actors=", _actors.size(),
			" scenes=", _scenes.size(),
			" bgm_tracks=", _bgm_tracks.size(),
			" bgm_moods=", _bgm_mood_index.size())


func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[AssetResolver] missing registry: " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[AssetResolver] invalid JSON: " + path)
		return {}
	return parsed


func _read_section(path: String, key: String) -> Dictionary:
	var root := _read_dict(path)
	var sec = root.get(key, {})
	if typeof(sec) != TYPE_DICTIONARY:
		return {}
	# 过滤掉以 "_" 开头的注释/schema 字段
	var clean: Dictionary = {}
	for k in sec.keys():
		if typeof(k) == TYPE_STRING and (k as String).begins_with("_"):
			continue
		clean[k] = sec[k]
	return clean


# ─── 案件加载（由 GameManager 调用） ───
func load_case(case_id: String) -> void:
	_current_case_id = case_id
	_casting = _read_dict("res://data/cases/%s/casting.json" % case_id).get("casting", {})
	_bgm_config = _read_dict("res://data/cases/%s/bgm_config.json" % case_id)
	# 读 voice_status：优先 manifest.voice_status；找不到时从 _index.json 读；都没有默认 full
	var manifest := _read_dict("res://data/cases/%s/manifest.json" % case_id)
	_voice_status = manifest.get("voice_status", "")
	if _voice_status == "":
		var idx := _read_dict("res://data/cases/_index.json")
		for entry in idx.get("cases", []):
			if typeof(entry) == TYPE_DICTIONARY and entry.get("id", "") == case_id:
				_voice_status = entry.get("voice_status", "full")
				break
	if _voice_status == "":
		_voice_status = "full"
	if debug_log:
		print("[AssetResolver] case=", case_id,
			" casting=", _casting.size(),
			" bgm_config=", _bgm_config.size(),
			" voice_status=", _voice_status)


## 当前案件的语音状态。供 VoicePlayer 决定是否启用兜底回退。
func get_voice_status() -> String:
	return _voice_status


# ─── 角色 → 演员 → 立绘/语音 ───
## 返回当前案件中该 npc_id 对应的 actor_id；若无 casting 或未配置，返回 ""。
func get_actor_id_for_npc(npc_id: String) -> String:
	var entry = _casting.get(npc_id, null)
	if typeof(entry) == TYPE_DICTIONARY:
		var aid = entry.get("actor_id", "")
		if aid != "":
			return aid
	return ""


## 取角色立绘路径。
##   1) 通过 casting → actor → portrait
##   2) 回退：npcs_data 中的 portrait 字段（兼容旧数据）
##   3) 都没有：返回 ""
func get_portrait(npc_id: String, npcs_data: Dictionary = {}) -> String:
	var aid := get_actor_id_for_npc(npc_id)
	if aid != "":
		var actor = _actors.get(aid, null)
		if typeof(actor) == TYPE_DICTIONARY:
			var p: String = actor.get("portrait", "")
			if p != "" and ResourceLoader.exists(p):
				return p
	# 回退到旧的 npcs.json.portrait
	var npc_def = npcs_data.get(npc_id, {})
	if typeof(npc_def) == TYPE_DICTIONARY:
		var p2: String = npc_def.get("portrait", "")
		if p2 != "":
			return p2
	return ""


## 取角色语音配置。返回 {style, pitch} 或空字典。
func get_voice_config(npc_id: String) -> Dictionary:
	var aid := get_actor_id_for_npc(npc_id)
	if aid == "":
		return {}
	var actor = _actors.get(aid, null)
	if typeof(actor) != TYPE_DICTIONARY:
		return {}
	return actor.get("voice_config", {})


## 解析对话语音文件路径。
##
## 严格隔离：每个案件的语音都必须放在 voices/{actor_id}/{case_id}/{node_id}.wav。
##
## 回退策略由当前案件的 voice_status 控制（来自 manifest.json 或 _index.json.cases[].voice_status）：
##   - "missing"  → 完全静默，不查找任何文件（性能 + 安全双优化）
##   - "partial"  → 只查 {actor_id}/{case_id}/，找不到就静默（防止跨案件错乱）
##   - "full"     → 先查 {actor_id}/{case_id}/，再查 {actor_id}/（演员通用台词），仍找不到就静默
##
## 注意：**绝不**回退到 voices/{npc_id}/{node_id}.wav 这种旧布局——npc_id 在不同案件里
## 可能撞名（例如 ma_san 在临川驿案和浔阳楼案都存在但角色身份不同），跨案件回退会错乱。
func resolve_voice_path(npc_id: String, node_id: String) -> String:
	if _voice_status == "missing":
		return ""
	var aid := get_actor_id_for_npc(npc_id)
	if aid == "" or _current_case_id == "":
		return ""
	# 1) 案件专属
	var p1 := "res://assets/cn/voices/%s/%s/%s.wav" % [aid, _current_case_id, node_id]
	if ResourceLoader.exists(p1):
		return p1
	# 2) 演员通用（仅 full 状态允许）
	if _voice_status == "full":
		var p2 := "res://assets/cn/voices/%s/%s.wav" % [aid, node_id]
		if ResourceLoader.exists(p2):
			return p2
	return ""


## 解析序章/旁白语音文件路径（按案件隔离）。
##   优先 voices/_prologue/{case_id}/{node_id}.wav
##   voice_status=full 时回退到 voices/_prologue/{node_id}.wav（仅作为旧路径的兼容兜底，
##   新案件不应依赖此路径）。
##   voice_status=missing 时直接返回 ""。
func resolve_prologue_voice_path(node_id: String) -> String:
	if _voice_status == "missing":
		return ""
	if _current_case_id != "":
		var p1 := "res://assets/cn/voices/_prologue/%s/%s.wav" % [_current_case_id, node_id]
		if ResourceLoader.exists(p1):
			return p1
	if _voice_status == "full":
		var p2 := "res://assets/cn/voices/_prologue/%s.wav" % node_id
		if ResourceLoader.exists(p2):
			return p2
	return ""


## 解析事件叙述语音路径（按案件隔离）。
##   优先 voices/_events/{case_id}/{evt_id}_{idx}.wav
##   voice_status=full 时回退到 voices/_events/{evt_id}_{idx}.wav（旧路径兼容）。
func resolve_event_voice_path(evt_id: String, idx: int) -> String:
	if _voice_status == "missing":
		return ""
	if _current_case_id != "":
		var p1 := "res://assets/cn/voices/_events/%s/%s_%d.wav" % [_current_case_id, evt_id, idx]
		if ResourceLoader.exists(p1):
			return p1
	if _voice_status == "full":
		var p2 := "res://assets/cn/voices/_events/%s_%d.wav" % [evt_id, idx]
		if ResourceLoader.exists(p2):
			return p2
	return ""


# ─── 角色剧本信息（来自 casting） ───
## casting 中的角色专属字段（name / title / intro / is_culprit 等）
## 当 casting 不存在时回退到 npcs.json 的相应字段。
func get_role_info(npc_id: String, npcs_data: Dictionary = {}) -> Dictionary:
	var entry = _casting.get(npc_id, null)
	if typeof(entry) == TYPE_DICTIONARY:
		# 对外统一字段名：name / title / intro
		return {
			"name": entry.get("role_name", entry.get("name", "")),
			"title": entry.get("role_title", entry.get("title", "")),
			"intro": entry.get("role_intro", entry.get("intro", "")),
			"is_culprit": entry.get("is_culprit", false),
		}
	var npc_def = npcs_data.get(npc_id, {})
	if typeof(npc_def) == TYPE_DICTIONARY:
		return {
			"name": npc_def.get("name", ""),
			"title": npc_def.get("title", ""),
			"intro": npc_def.get("intro", ""),
			"is_culprit": npc_def.get("is_culprit", false),
		}
	return {}


# ─── 地点 → 场景 → 背景 ───
## 取地点背景图。
##   1) location.scene_type → scenes/registry.json → background
##   2) 回退：location.background 字段（兼容旧数据）
func get_scene_background(location_def: Dictionary) -> String:
	var scene_type: String = location_def.get("scene_type", "")
	if scene_type != "":
		var scene = _scenes.get(scene_type, null)
		if typeof(scene) == TYPE_DICTIONARY:
			var bg: String = scene.get("background", "")
			if bg != "" and ResourceLoader.exists(bg):
				return bg
	# 回退
	return location_def.get("background", "")


## 直接根据 scene_id 取背景（用于序章、标题画面等非 location 场景）。
func get_scene_background_by_id(scene_id: String) -> String:
	var scene = _scenes.get(scene_id, null)
	if typeof(scene) == TYPE_DICTIONARY:
		return scene.get("background", "")
	return ""


# ─── 氛围 → BGM ───
## 解析 BGM 标识符到具体 track_id。支持三种输入：
##   1) location_id（先查 bgm_config.locations）
##   2) mood_tag（查 bgm/registry.json 的 mood_index）
##   3) track_id（直接命中 tracks 字典）
##
## 返回真实的 track_id；找不到时返回 ""。
func resolve_bgm_track(key: String) -> String:
	if key == "":
		return ""
	# 1) bgm_config 中的地点/状态映射
	var locations: Dictionary = _bgm_config.get("locations", {})
	if locations.has(key):
		return _resolve_track_id(locations[key])
	var states: Dictionary = _bgm_config.get("states", {})
	if states.has(key):
		return _resolve_track_id(states[key])
	# 2) mood_index
	if _bgm_mood_index.has(key):
		var arr = _bgm_mood_index[key]
		if typeof(arr) == TYPE_ARRAY and arr.size() > 0:
			return str(arr[0])
	# 3) 直接是 track_id
	if _bgm_tracks.has(key):
		return key
	return ""


## 把 bgm_config 的值（可能是 "track:investigation_dark" / "mood:suspense" / 直接 track_id）
## 解析为最终 track_id。
func _resolve_track_id(value) -> String:
	if typeof(value) != TYPE_STRING:
		return ""
	var s: String = value
	if s.begins_with("track:"):
		return s.substr("track:".length())
	if s.begins_with("mood:"):
		var mood := s.substr("mood:".length())
		if _bgm_mood_index.has(mood):
			var arr = _bgm_mood_index[mood]
			if typeof(arr) == TYPE_ARRAY and arr.size() > 0:
				return str(arr[0])
		return ""
	# 直接是 track_id
	return s


## 取 track_id 对应的 wav 文件路径。
func get_bgm_file(track_id: String) -> String:
	var t = _bgm_tracks.get(track_id, null)
	if typeof(t) == TYPE_DICTIONARY:
		return t.get("file", "")
	return ""


## 便捷接口：直接拿到 bgm 文件路径（输入可以是 location_id / mood_tag / track_id）
func resolve_bgm_file(key: String) -> String:
	var tid := resolve_bgm_track(key)
	if tid == "":
		return ""
	return get_bgm_file(tid)


# ─── 调试辅助 ───
func dump_summary() -> void:
	print("[AssetResolver] case=", _current_case_id,
		" actors=", _actors.size(),
		" scenes=", _scenes.size(),
		" bgm_tracks=", _bgm_tracks.size(),
		" casting=", _casting.size(),
		" bgm_config=", _bgm_config.size())
