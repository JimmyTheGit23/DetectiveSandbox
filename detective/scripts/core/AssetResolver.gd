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
var _portrait_expressions: Dictionary = {}  # base_portrait -> emotion -> portrait_path
var _portrait_meta: Dictionary = {}         # portrait_file_name -> {screen_scale, pivot_y}（对话立绘缩放校正）
var _center_npc_layouts_by_npc: Dictionary = {}
var _center_npc_layouts_by_portrait: Dictionary = {}
var _voice_status: String = "full"    # 当前案件的语音状态：full / partial / missing

# 调试
@export var debug_log: bool = false

# 对话立绘缩放校正数据已迁移到 portrait_expressions.csv 的 screen_scale / pivot_y 列
# （旧规格立绘按实际脸部大小校正，基准：1280x720 对话画面中脸高约 145px）。

# 中央立绘的标准框体，供 GM 预览 / 正式对话 / 场景常驻共用。
const CENTER_PORTRAIT_STANDARD_FRAME := {
	"offset_left": -320.0,
	"offset_top": 60.0,
	"offset_right": 320.0,
	"offset_bottom": 0.0,
	"pivot_x": 320.0,
}

const CENTER_PORTRAIT_TEXTURE_NORMALIZE_BY_SURFACE := {
	# 统一中央立绘的透明边裁切规则，避免 GM 预览 / 场景常驻 / 对峙各自一套。
	"scene": {"crop_padding_ratio": 0.02, "crop_min_padding": 8, "crop_min_height_ratio": 0.78},
	"preview": {"crop_padding_ratio": 0.02, "crop_min_padding": 8, "crop_min_height_ratio": 0.78},
	"dialogue": {"crop_padding_ratio": 0.02, "crop_min_padding": 8, "crop_min_height_ratio": 0.78},
	"confrontation": {"crop_padding_ratio": 0.02, "crop_min_padding": 8, "crop_min_height_ratio": 0.78},
}

# 若后续确实需要某个界面单独微调，统一只在这里改，不再散落在各 UI 脚本里。
const CENTER_PORTRAIT_SURFACE_TUNING := {
	"scene": {"scale_multiplier": 1.0, "offset_y": 0.0, "pivot_y_offset": 0.0},
	"preview": {"scale_multiplier": 1.0, "offset_y": 0.0, "pivot_y_offset": 0.0},
	"dialogue": {"scale_multiplier": 1.0, "offset_y": 0.0, "pivot_y_offset": 0.0},
	"confrontation": {"scale_multiplier": 1.0, "offset_y": 0.0, "pivot_y_offset": 0.0},
}


func _ready() -> void:
	_load_registries()
	_load_current_case_from_game_manager()
	call_deferred("_load_current_case_from_game_manager")


func _load_current_case_from_game_manager() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var case_id := str(gm.get("ACTIVE_CASE"))
	if case_id != "" and case_id != _current_case_id:
		load_case(case_id)


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
	var table_data := CaseTableLoader.load_case(case_id)
	_casting = table_data.get("casting", {}).get("casting", {})
	_bgm_config = table_data.get("bgm_config", {})
	_portrait_expressions = table_data.get("portrait_expressions", {}).get("portraits", {})
	_portrait_meta = table_data.get("portrait_expressions", {}).get("portrait_meta", {})
	_center_npc_layouts_by_npc = table_data.get("center_npc_layouts", {}).get("by_npc", {})
	_center_npc_layouts_by_portrait = table_data.get("center_npc_layouts", {}).get("by_portrait", {})
	# 读 voice_status：优先 manifest.voice_status；找不到时从 case_index.csv 读；都没有默认 full
	var manifest: Dictionary = table_data.get("manifest", {})
	_voice_status = manifest.get("voice_status", "")
	if _voice_status == "":
		var idx := CaseTableLoader.load_case_index()
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
			" center_npc_layouts=", _center_npc_layouts_by_portrait.size(),
			" voice_status=", _voice_status)


## 当前案件的语音状态。供 VoicePlayer 决定是否启用兜底回退。
func get_voice_status() -> String:
	return _voice_status


# ─── 角色 → 演员 → 立绘/语音 ───

## 返回当前案件的完整 casting 字典（npc_id -> entry）
func get_casting() -> Dictionary:
	return _casting

## 返回当前案件中该 npc_id 对应的 actor_id；若无 casting 或未配置，返回 ""。
func get_actor_id_for_npc(npc_id: String) -> String:
	var entry = _casting.get(npc_id, null)
	if typeof(entry) == TYPE_DICTIONARY:
		var aid = entry.get("actor_id", "")
		if aid != "":
			return aid
	return ""


## 取角色立绘路径。
##   0) casting 中有 portrait 覆盖（case 级别）→ 最高优先
##   1) 通过 casting → actor → portrait
##   2) 回退：npcs_data 中的 portrait 字段（兼容旧数据）
##   3) 都没有：返回 ""
func get_portrait(npc_id: String, npcs_data: Dictionary = {}) -> String:
	# 0) casting 级别覆盖（如序章陆昭穿素袍而非官服）
	var entry = _casting.get(npc_id, null)
	if typeof(entry) == TYPE_DICTIONARY:
		var cp: String = entry.get("portrait", "")
		if cp != "" and ResourceLoader.exists(cp):
			return cp
	# 1) actor registry
	var aid := get_actor_id_for_npc(npc_id)
	if aid != "":
		var actor = _actors.get(aid, null)
		if typeof(actor) == TYPE_DICTIONARY:
			var p: String = actor.get("portrait", "")
			if p != "" and ResourceLoader.exists(p):
				return p
	# 2) 回退到旧的 npcs.json.portrait
	var npc_def = npcs_data.get(npc_id, {})
	if typeof(npc_def) == TYPE_DICTIONARY:
		var p2: String = npc_def.get("portrait", "")
		if p2 != "":
			return p2
	return ""


## 从案件级表情资源表解析立绘。base_path 是基础立绘路径，emotion 是对话/对峙状态。
func resolve_portrait_expression(base_path: String, emotion: String) -> String:
	if base_path == "" or emotion == "":
		return ""
	var table = _portrait_expressions.get(base_path, null)
	if typeof(table) != TYPE_DICTIONARY:
		return ""
	var path: String = table.get(emotion, "")
	if path != "" and ResourceLoader.exists(path):
		return path
	return ""


func resolve_portrait_from_base(base_path: String, emotion: String = "", context: String = "") -> String:
	if base_path == "":
		return ""
	for key in _portrait_expression_candidates(emotion, context):
		var mapped := resolve_portrait_expression(base_path, key)
		if mapped != "":
			return mapped
		var variant := _portrait_variant_path(base_path, key)
		if variant != "" and ResourceLoader.exists(variant):
			return variant
	return base_path


## 统一解析案件角色立绘：角色 ID + 情绪/上下文 + 可选强制覆盖 → 最终资源路径。
## 优先级：portrait_override > characters/casting 基础立绘 > portrait_expressions.csv > 文件名变体 > 基础立绘。
func resolve_case_portrait(npc_id: String, emotion: String = "", npcs_data: Dictionary = {}, context: String = "", portrait_override: String = "") -> String:
	var override_path := portrait_override.strip_edges()
	if override_path != "" and ResourceLoader.exists(override_path):
		return override_path
	var base_path := get_portrait(npc_id, npcs_data)
	if base_path == "":
		base_path = _companion_base_portrait(npc_id)
	if base_path == "":
		return ""
	return resolve_portrait_from_base(base_path, emotion, context)


func get_portrait_expression_emotions(base_path: String) -> Array:
	var out: Array = []
	_append_unique(out, "base")
	var table = _portrait_expressions.get(base_path, null)
	if typeof(table) == TYPE_DICTIONARY:
		for emotion in table.keys():
			_append_unique(out, str(emotion))
	_append_portrait_file_variant_emotions(out, base_path)
	out.sort()
	if out.has("base"):
		out.erase("base")
		out.push_front("base")
	return out


func get_case_portrait_emotions(npc_id: String, npcs_data: Dictionary = {}) -> Array:
	var base_path := get_portrait(npc_id, npcs_data)
	if base_path == "":
		base_path = _companion_base_portrait(npc_id)
	var out := get_portrait_expression_emotions(base_path)
	for emotion in get_center_npc_emotions(npc_id):
		_append_unique(out, str(emotion))
	out.sort()
	if out.has("base"):
		out.erase("base")
		out.push_front("base")
	return out


## 取立绘在屏幕上的显示缩放。默认 1.0；用于旧规格立绘的脸部比例校正（数据驱动）。
func get_portrait_screen_scale(portrait_path: String) -> float:
	var file_name := portrait_path.get_file()
	return float(_portrait_meta.get(file_name, {}).get("screen_scale", 1.0))


## 取立绘缩放支点的 Y 坐标。默认使用 640x660 立绘框中心；旧规格立绘靠近头脸缩放（数据驱动）。
func get_portrait_screen_pivot_y(portrait_path: String) -> float:
	var file_name := portrait_path.get_file()
	return float(_portrait_meta.get(file_name, {}).get("pivot_y", 330.0))


func get_center_portrait_standard_frame() -> Dictionary:
	return CENTER_PORTRAIT_STANDARD_FRAME.duplicate(true)


func get_center_portrait_texture_normalize_config(surface_id: String = "scene") -> Dictionary:
	var fallback = CENTER_PORTRAIT_TEXTURE_NORMALIZE_BY_SURFACE.get("scene", {})
	var cfg = CENTER_PORTRAIT_TEXTURE_NORMALIZE_BY_SURFACE.get(surface_id, fallback)
	if typeof(cfg) != TYPE_DICTIONARY:
		return {}
	return cfg.duplicate(true)


## 中央立绘展示配置。优先命中 npc+emotion，其次 portrait 精确配置，最后回退到旧的按文件名缩放规则。
func get_center_portrait_presentation(npc_id: String = "", emotion: String = "", portrait_path: String = "") -> Dictionary:
	var cfg := {
		"enabled": true,
		"screen_scale": get_portrait_screen_scale(portrait_path),
		"offset_y": 0.0,
		"pivot_y": get_portrait_screen_pivot_y(portrait_path),
		"confrontation_screen_scale": get_portrait_screen_scale(portrait_path),
		"confrontation_offset_y": 0.0,
	}
	var resolved := _lookup_center_portrait_layout(npc_id, emotion, portrait_path)
	if typeof(resolved) == TYPE_DICTIONARY:
		if resolved.has("screen_scale"):
			cfg["screen_scale"] = float(resolved.get("screen_scale", cfg["screen_scale"]))
		if resolved.has("offset_y"):
			cfg["offset_y"] = float(resolved.get("offset_y", cfg["offset_y"]))
		if resolved.has("pivot_y"):
			cfg["pivot_y"] = float(resolved.get("pivot_y", cfg["pivot_y"]))
		if resolved.has("confrontation_screen_scale"):
			cfg["confrontation_screen_scale"] = float(resolved.get("confrontation_screen_scale", cfg["confrontation_screen_scale"]))
		else:
			cfg["confrontation_screen_scale"] = float(cfg["screen_scale"])
		if resolved.has("confrontation_offset_y"):
			cfg["confrontation_offset_y"] = float(resolved.get("confrontation_offset_y", cfg["confrontation_offset_y"]))
		else:
			cfg["confrontation_offset_y"] = float(cfg["offset_y"])
		if resolved.has("enabled"):
			cfg["enabled"] = bool(resolved.get("enabled", true))
	return cfg


func get_center_portrait_surface_presentation(surface_id: String = "scene", npc_id: String = "", emotion: String = "", portrait_path: String = "") -> Dictionary:
	var cfg := get_center_portrait_presentation(npc_id, emotion, portrait_path).duplicate(true)
	if surface_id == "confrontation":
		cfg["screen_scale"] = float(cfg.get("confrontation_screen_scale", cfg.get("screen_scale", 1.0)))
		cfg["offset_y"] = float(cfg.get("confrontation_offset_y", cfg.get("offset_y", 0.0)))
	var tuning = CENTER_PORTRAIT_SURFACE_TUNING.get(surface_id, CENTER_PORTRAIT_SURFACE_TUNING["scene"])
	if typeof(tuning) != TYPE_DICTIONARY:
		return cfg
	cfg["screen_scale"] = float(cfg.get("screen_scale", 1.0)) * float(tuning.get("scale_multiplier", 1.0))
	cfg["offset_y"] = float(cfg.get("offset_y", 0.0)) + float(tuning.get("offset_y", 0.0))
	cfg["pivot_y"] = float(cfg.get("pivot_y", 330.0)) + float(tuning.get("pivot_y_offset", 0.0))
	return cfg


func set_center_portrait_layout(npc_id: String, emotion: String, portrait_path: String, layout: Dictionary) -> void:
	if npc_id == "" or portrait_path == "":
		return
	var clean_emotion := emotion if emotion != "" else "base"
	var cfg := {
		"npc_id": npc_id,
		"emotion": clean_emotion,
		"portrait": portrait_path,
		"screen_scale": float(layout.get("screen_scale", get_portrait_screen_scale(portrait_path))),
		"offset_y": float(layout.get("offset_y", 0.0)),
		"pivot_y": float(layout.get("pivot_y", get_portrait_screen_pivot_y(portrait_path))),
		"confrontation_screen_scale": float(layout.get(
			"confrontation_screen_scale",
			layout.get("screen_scale", get_portrait_screen_scale(portrait_path))
		)),
		"confrontation_offset_y": float(layout.get(
			"confrontation_offset_y",
			layout.get("offset_y", 0.0)
		)),
	}
	if layout.has("enabled"):
		cfg["enabled"] = bool(layout.get("enabled", true))
	var npc_entry = _center_npc_layouts_by_npc.get(npc_id, null)
	if typeof(npc_entry) != TYPE_DICTIONARY:
		npc_entry = {}
		_center_npc_layouts_by_npc[npc_id] = npc_entry
	if layout.has("enabled"):
		npc_entry["enabled"] = bool(layout.get("enabled", true))
	var emotions = npc_entry.get("emotions", null)
	if typeof(emotions) != TYPE_DICTIONARY:
		emotions = {}
		npc_entry["emotions"] = emotions
	emotions[clean_emotion] = cfg
	_center_npc_layouts_by_portrait[portrait_path] = cfg


func is_center_npc_enabled(npc_id: String) -> bool:
	var npc_entry = _center_npc_layouts_by_npc.get(npc_id, null)
	if typeof(npc_entry) != TYPE_DICTIONARY:
		return true
	return bool(npc_entry.get("enabled", true))


func get_center_npc_ids() -> Array:
	var ids: Array = []
	for npc_id in _center_npc_layouts_by_npc.keys():
		ids.append(str(npc_id))
	ids.sort()
	return ids


func get_center_npc_emotions(npc_id: String) -> Array:
	var npc_entry = _center_npc_layouts_by_npc.get(npc_id, null)
	if typeof(npc_entry) != TYPE_DICTIONARY:
		return ["base"]
	var emotions: Dictionary = npc_entry.get("emotions", {})
	var out: Array = []
	for emotion in emotions.keys():
		out.append(str(emotion))
	out.sort()
	if out.has("base"):
		out.erase("base")
		out.push_front("base")
	return out


func _lookup_center_portrait_layout(npc_id: String, emotion: String, portrait_path: String) -> Dictionary:
	var npc_entry = _center_npc_layouts_by_npc.get(npc_id, null)
	var emotions: Dictionary = {}
	if typeof(npc_entry) == TYPE_DICTIONARY:
		emotions = npc_entry.get("emotions", {})
		if emotion != "" and emotions.has(emotion):
			var emotion_cfg = emotions.get(emotion, null)
			if typeof(emotion_cfg) == TYPE_DICTIONARY:
				return emotion_cfg
	if portrait_path != "" and _center_npc_layouts_by_portrait.has(portrait_path):
		var portrait_cfg = _center_npc_layouts_by_portrait.get(portrait_path, null)
		if typeof(portrait_cfg) == TYPE_DICTIONARY:
			return portrait_cfg
	if typeof(npc_entry) == TYPE_DICTIONARY:
		if emotions.has("base"):
			var base_cfg = emotions.get("base", null)
			if typeof(base_cfg) == TYPE_DICTIONARY:
				return base_cfg
	return {}


func _companion_base_portrait(speaker_id: String) -> String:
	if speaker_id != "xia_lingyao" and speaker_id != "lingyao":
		return ""
	var cs := get_node_or_null("/root/CompanionService")
	if cs != null and cs.has_method("get_companion_portrait"):
		var portrait := str(cs.get_companion_portrait())
		if portrait != "":
			return portrait
	return "res://assets/cn/portraits/companion_lingyao.png"


func _portrait_expression_candidates(emotion: String, context: String) -> Array:
	var raw := emotion.strip_edges()
	var normalized := _normalize_portrait_emotion(raw)
	var candidates := []
	if context == "confrontation":
		if raw == "" or raw == "normal" or raw == "base":
			_append_unique(candidates, "confrontation")
		else:
			_append_unique(candidates, raw)
			if normalized != raw:
				_append_unique(candidates, normalized)
			if raw.begins_with("confrontation_"):
				_append_unique(candidates, raw.substr("confrontation_".length()))
			elif raw != "confrontation":
				_append_unique(candidates, "confrontation_%s" % raw)
			if normalized != "" and normalized != raw and not normalized.begins_with("confrontation"):
				_append_unique(candidates, "confrontation_%s" % normalized)
			_append_unique(candidates, "confrontation")
	else:
		if raw != "" and raw != "normal" and raw != "base":
			_append_unique(candidates, raw)
		if normalized != "" and normalized != raw and normalized != "normal" and normalized != "base":
			_append_unique(candidates, normalized)
	_append_unique(candidates, "normal")
	_append_unique(candidates, "base")
	return candidates


func _normalize_portrait_emotion(emotion: String) -> String:
	match emotion:
		"accusatory", "piercing", "serious", "firm":
			return "serious"
		"cold", "stern", "angry":
			return "cold"
		"thinking", "alert", "ponder":
			return "worried"
		"determined", "resolute":
			return "determined"
		"nervous", "panic", "anxious", "uneasy":
			return "anxious"
		"surprised", "shock", "startled":
			return "shocked"
		"worried", "concerned", "sad":
			return "worried"
		"cheerful", "happy", "relief":
			return "cheerful"
	return emotion


func _portrait_variant_path(base_path: String, emotion: String) -> String:
	if base_path == "" or emotion == "" or emotion == "normal" or emotion == "base":
		return ""
	return base_path.replace(".png", "_%s.png" % emotion)


func _append_portrait_file_variant_emotions(arr: Array, base_path: String) -> void:
	if base_path == "" or not base_path.ends_with(".png"):
		return
	var dir := DirAccess.open(base_path.get_base_dir())
	if dir == null:
		return
	var base_name := base_path.get_file().get_basename()
	var prefix := "%s_" % base_name
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with(prefix) and file_name.ends_with(".png"):
			var suffix_len := file_name.length() - prefix.length() - ".png".length()
			var suffix := file_name.substr(prefix.length(), suffix_len)
			if suffix.find("raw") < 0 and suffix.find("magenta") < 0:
				_append_unique(arr, suffix)
		file_name = dir.get_next()
	dir.list_dir_end()


func _append_unique(arr: Array, value: String) -> void:
	if value != "" and not arr.has(value):
		arr.append(value)


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
##   1) location.background 作为地点级覆盖（同一 scene_type 下可有不同房间/角度）
##   2) 回退：location.scene_type → scenes/registry.json → background
func get_scene_background(location_def: Dictionary) -> String:
	var location_bg: String = location_def.get("background", "")
	if location_bg != "" and ResourceLoader.exists(location_bg):
		return location_bg
	var scene_type: String = location_def.get("scene_type", "")
	if scene_type != "":
		var scene = _scenes.get(scene_type, null)
		if typeof(scene) == TYPE_DICTIONARY:
			var bg: String = scene.get("background", "")
			if bg != "" and ResourceLoader.exists(bg):
				return bg
	return location_bg


## 直接根据 scene_id 取背景（用于序章、标题画面等非 location 场景）。
func get_scene_background_by_id(scene_id: String) -> String:
	var scene = _scenes.get(scene_id, null)
	if typeof(scene) == TYPE_DICTIONARY:
		return scene.get("background", "")
	return ""


# ─── 氛围 → BGM ───
## 解析 BGM 标识符到具体 track_id。支持三种输入：
##   1) location_id（先查 bgm_config.locations）
##   2) track_id（直接命中 tracks 字典）
##   3) state_id（查 bgm_config.states）
##   4) mood_tag（查 bgm/registry.json 的 mood_index）
##
## 返回真实的 track_id；找不到时返回 ""。
func resolve_bgm_track(key: String) -> String:
	if key == "":
		return ""
	# 1) bgm_config 中的地点/状态映射
	var locations: Dictionary = _bgm_config.get("locations", {})
	if locations.has(key):
		return _resolve_track_id(locations[key])
	if _bgm_tracks.has(key):
		return key
	var states: Dictionary = _bgm_config.get("states", {})
	if states.has(key):
		return _resolve_track_id(states[key])
	# 4) mood_index
	if _bgm_mood_index.has(key):
		var arr = _bgm_mood_index[key]
		if typeof(arr) == TYPE_ARRAY and arr.size() > 0:
			return str(arr[0])
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
