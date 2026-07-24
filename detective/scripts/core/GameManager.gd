extends Node
## 全局游戏管理器：状态、地点、证据、线索、剧情标记、NPC 状态机、日程事件

signal state_changed(new_state: String)
signal evidence_added(evidence_id: String)
signal clue_added(clue_id: String)
signal location_changed(location_id: String)
signal flag_set(flag_id: String)
signal node_visited(npc_id: String, node_id: String)
signal day_event_available(event_id: String)
signal phase_unlocked(phase_id: String)
signal progression_hint(speaker: String, text: String)

# 游戏状态
const STATE_PROLOGUE := "prologue"
const STATE_PLAYING := "playing"
const STATE_DIALOGUE := "dialogue"
const STATE_MENU := "menu"
const STATE_ENDING := "ending"
const STATE_TRANSITION := "transition"  # 日期切换过场

# 当前案件（动态可切换）
const CURRENT_CASE_PATH := "user://current_case.json"
const DEFAULT_CASE := "linchuan_inn"

var ACTIVE_CASE: String = DEFAULT_CASE

# 当前案件的初始定位地点（从 manifest.main_scene 读，回退到 DEFAULT_MAIN_SCENE）
const DEFAULT_MAIN_SCENE := "post_station"
var case_main_scene: String = DEFAULT_MAIN_SCENE

# 当前案件元信息（来自 CSV 表格 manifest 文档）
var case_manifest: Dictionary = {}

# 案件索引（来自 _index.json）
var case_index: Dictionary = {}

# 存档路径（按案件分槽，user://saves/<case_id>.json）
var SAVE_PATH: String = "user://saves/%s.json" % DEFAULT_CASE

var current_state: String = STATE_PROLOGUE
var current_day: int = 1
var current_location: String = "post_station"

# 数据
var locations_data: Dictionary = {}
var npcs_data: Dictionary = {}
var evidence_data: Dictionary = {}
var key_info_data: Dictionary = {}
var search_results_data: Dictionary = {}
var case_data: Dictionary = {}
var day_events_data: Dictionary = {}
var npc_states_data: Dictionary = {}
# 渐进式开放系统
var progression_data: Dictionary = {}
var unlocked_phases: Array[String] = ["phase_1"]

# 新：NPC 时段日程 + 凶手行动表（动态案件可选）
var schedules_data: Dictionary = {}
var time_progression_data: Array = []
var culprit_actions_data: Dictionary = {}
# GM 调试预设（数据驱动，原 MainGame 硬编码）
var gm_presets_data: Dictionary = {}
# 地图配置（数据驱动，原 MapPanel 硬编码）
var map_config_data: Dictionary = {}

# 对峙数据路由：由对话系统设置，ConfrontationPanel 读取
var active_confrontation_key: String = "confrontation"
# 每次 reset 时基于 case_seed 解算的真实执行时刻：action_id -> "D{d}_P{p}"
var culprit_action_resolved: Dictionary = {}
# 玩家撞见过的凶手行动（用于触发遭遇剧情，避免重复）
var culprit_actions_witnessed: Dictionary = {}
# 案件随机种子（每次新游戏生成；存档/读档保持一致）
var case_seed: int = 0

# 玩家进度
var collected_evidence: Array[String] = []
var collected_clues: Array[String] = []
var visited_locations: Array[String] = ["post_station"]
var search_history: Dictionary = {}
var dialogue_flags: Dictionary = {}     # flag_id -> true
var visited_nodes: Dictionary = {}      # "npc_id.node_id" -> count
var visited_node_versions: Dictionary = {}  # "npc_id.node_id" -> current visible content version
var triggered_events: Dictionary = {}   # event_id -> true
var npc_states: Dictionary = {}         # npc_id -> { stat_name: value }
var case_records: Array[Dictionary] = []       # 证词 / 疑点 / 关键信息记录
var dialogue_records: Array[Dictionary] = []   # 对话卷宗回看
var shown_time_cards: Dictionary = {}          # 已显示的时间字幕 key → true（持久化，避免重复）
var suppress_evidence_obtain_hold := false
var _last_evidence_obtain_hold_enabled := true


func _ready() -> void:
	_load_case_index()
	_resolve_active_case()
	_load_data()
	_init_npc_states()
	# 延迟到所有 autoload 就绪后订阅钩子（顺序不敏感）
	call_deferred("_subscribe_hooks")


# ─── 钩子订阅（Layer 2：替代旧的 mutator 内联轮询） ───
## 检查链优先级：day_events(20) 先于 progression(10)，与旧内联调用顺序一致
func _subscribe_hooks() -> void:
	for h in [HookBus.FLAG_SET, HookBus.EVIDENCE_ADDED, HookBus.CLUE_ADDED]:
		HookBus.subscribe(h, _hook_check_day_events, 20)
		HookBus.subscribe(h, _hook_check_progression, 10)
	HookBus.subscribe(HookBus.LOCATION_CHANGED, _hook_check_day_events, 20)
	HookBus.subscribe(HookBus.NODE_VISITED, _hook_check_day_events, 20)


func _hook_check_day_events(_payload: Dictionary) -> void:
	_check_day_events()


func _hook_check_progression(_payload: Dictionary) -> void:
	_check_progression()


# ─── 案件管理 ───
func _load_case_index() -> void:
	case_index = CaseTableLoader.load_case_index()


func _resolve_active_case() -> void:
	# 优先级：user://current_case.json -> case_index.default_case -> DEFAULT_CASE
	var chosen := ""
	if FileAccess.file_exists(CURRENT_CASE_PATH):
		var f := FileAccess.open(CURRENT_CASE_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				chosen = parsed.get("case_id", "")
	if chosen == "":
		chosen = case_index.get("default_case", DEFAULT_CASE)
	# 校验存在
	if not _case_exists(chosen):
		chosen = DEFAULT_CASE
	_set_active_case(chosen, false)


func _case_exists(case_id: String) -> bool:
	return CaseTableLoader.case_exists(case_id)


func _set_active_case(case_id: String, persist: bool = true) -> void:
	ACTIVE_CASE = case_id
	SAVE_PATH = "user://saves/%s.json" % case_id
	# 确保 user://saves/ 目录存在
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://saves")):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	# 加载 manifest（运行时来自 data/case_tables/<case_id>/json_docs.csv）
	case_manifest = CaseTableLoader.load_manifest(case_id)
	case_main_scene = case_manifest.get("main_scene", DEFAULT_MAIN_SCENE)
	if persist:
		var f := FileAccess.open(CURRENT_CASE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify({"case_id": case_id}))


## 切换到另一个案件。会：
##   1) 写 current_case.json，下次启动会记得
##   2) 重新加载该案件的全套 CSV 表格数据
##   3) 通知 AssetResolver 切换 casting/bgm_config
##   4) 重置玩家进度（不是清存档，仅当前会话的状态变量）
## 注意：调用方负责把 UI 切回标题画面/序章
func switch_case(case_id: String) -> bool:
	if not _case_exists(case_id):
		push_error("Case not found: " + case_id)
		return false
	_set_active_case(case_id, true)
	_load_data()
	_init_npc_states()
	# 重置当前会话状态（但不清存档；玩家选了案件后再决定开新游戏还是继续）
	current_state = STATE_PROLOGUE
	current_day = 1
	current_location = case_main_scene
	collected_evidence.clear()
	collected_clues.clear()
	visited_locations = [case_main_scene]
	search_history.clear()
	dialogue_flags.clear()
	visited_nodes.clear()
	visited_node_versions.clear()
	triggered_events.clear()
	case_records.clear()
	dialogue_records.clear()
	shown_time_cards.clear()
	culprit_actions_witnessed.clear()
	suppress_evidence_obtain_hold = false
	_last_evidence_obtain_hold_enabled = true
	unlocked_phases = ["phase_0", "phase_1"]
	reroll_case_seed()
	# 切换案件时刷新助手系统数据
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("reload_for_case"):
		cs.reload_for_case()
	HookBus.emit_hook(HookBus.CASE_SWITCHED, {"case_id": case_id})
	return true


func get_case_index_entries() -> Array:
	return case_index.get("cases", [])


# ─── 数据加载 ───
func _load_data() -> void:
	var table_data := CaseTableLoader.load_case(ACTIVE_CASE)
	case_manifest = table_data.get("manifest", {})
	case_main_scene = case_manifest.get("main_scene", DEFAULT_MAIN_SCENE)
	locations_data = table_data.get("locations", {})
	npcs_data = table_data.get("npcs", {})
	evidence_data = table_data.get("evidence", {})
	key_info_data = table_data.get("key_info", {})
	search_results_data = table_data.get("search_results", {})
	case_data = table_data.get("case", {})
	day_events_data = table_data.get("day_events", {})
	npc_states_data = table_data.get("npc_states", {})
	progression_data = table_data.get("progression", {})
	# 新：NPC schedule 与凶手行动表（可选，没有就退回静态行为）
	schedules_data = table_data.get("schedules", {})
	time_progression_data = table_data.get("time_progression", [])
	culprit_actions_data = table_data.get("culprit_actions", {})
	gm_presets_data = table_data.get("gm_presets", {})
	map_config_data = table_data.get("map_config", {})
	_resolve_culprit_action_schedule()
	# 通知资产解析器加载本案的 casting / bgm_config
	if Engine.has_singleton("AssetResolver") or get_node_or_null("/root/AssetResolver") != null:
		var resolver := get_node_or_null("/root/AssetResolver")
		if resolver and resolver.has_method("load_case"):
			resolver.load_case(ACTIVE_CASE)


func reload_current_case_tables(reset_npc_state := false) -> void:
	CaseTableLoader.clear_cache()
	_load_case_index()
	_load_data()
	if reset_npc_state:
		_init_npc_states()
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("reload_for_case"):
		cs.reload_for_case()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing JSON: " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var txt := f.get_as_text()
	var result = JSON.parse_string(txt)
	if typeof(result) != TYPE_DICTIONARY:
		push_error("Invalid JSON: " + path)
		return {}
	return result


func _init_npc_states() -> void:
	npc_states.clear()
	for npc_id in npc_states_data.keys():
		# 跳过注释字段（如 "_comment"）和非字典项
		if npc_id.begins_with("_"):
			continue
		var raw = npc_states_data[npc_id]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var conf: Dictionary = raw
		var initial: Dictionary = conf.get("initial", {})
		npc_states[npc_id] = initial.duplicate()


# ─── 存档 / 新游戏 ───
func reset_progress() -> void:
	current_state = STATE_PROLOGUE
	current_day = 1
	current_location = case_main_scene
	collected_evidence.clear()
	collected_clues.clear()
	visited_locations = [case_main_scene]
	search_history.clear()
	dialogue_flags.clear()
	visited_nodes.clear()
	visited_node_versions.clear()
	triggered_events.clear()
	case_records.clear()
	dialogue_records.clear()
	shown_time_cards.clear()
	culprit_actions_witnessed.clear()
	suppress_evidence_obtain_hold = false
	_last_evidence_obtain_hold_enabled = true
	unlocked_phases = ["phase_0", "phase_1"]
	reroll_case_seed()
	_init_npc_states()
	save_game()


func has_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		return true
	# 兼容旧存档路径（一次性迁移）
	var legacy := "user://%s_save.json" % ACTIVE_CASE
	if FileAccess.file_exists(legacy):
		_migrate_legacy_save(legacy)
		return FileAccess.file_exists(SAVE_PATH)
	return false


func _migrate_legacy_save(legacy_path: String) -> void:
	var f := FileAccess.open(legacy_path, FileAccess.READ)
	if f == null:
		return
	var content := f.get_as_text()
	f.close()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://saves")):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var w := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if w:
		w.store_string(content)
		w.close()
		print("[GameManager] migrated legacy save: %s -> %s" % [legacy_path, SAVE_PATH])


func save_game() -> void:
	var data := _build_save_data()
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		# 兼容旧存档路径：选案界面可能先检测到旧存档，再进入读取。
		var legacy := "user://%s_save.json" % ACTIVE_CASE
		if FileAccess.file_exists(legacy):
			_migrate_legacy_save(legacy)
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	_apply_save_data(parsed)
	return true


# ─── 手动存档槽位（3个） ───
const MANUAL_SLOT_COUNT := 3

func has_resume_save() -> bool:
	return case_has_resume_save(ACTIVE_CASE)


func case_has_resume_save(case_id: String) -> bool:
	if _case_has_primary_save(case_id):
		return true
	for slot in range(1, MANUAL_SLOT_COUNT + 1):
		if FileAccess.file_exists(_manual_slot_path_for_case(case_id, slot)):
			return true
	return false


func load_resume_save() -> bool:
	var latest := _latest_resume_save()
	if latest.is_empty():
		return false
	if str(latest.get("kind", "")) == "slot":
		return load_from_slot(int(latest.get("slot", 0)))
	return load_game()

## 保存当前状态到指定手动存档槽位（1-3）
func save_to_slot(slot: int) -> bool:
	if slot < 1 or slot > MANUAL_SLOT_COUNT:
		return false
	var path := _manual_slot_path(slot)
	var data := _build_save_data()
	data["save_timestamp"] = Time.get_datetime_string_from_system(false, true)
	data["save_slot"] = slot
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		return true
	return false


## 从指定手动存档槽位加载（1-3）
func load_from_slot(slot: int) -> bool:
	if slot < 1 or slot > MANUAL_SLOT_COUNT:
		return false
	var path := _manual_slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	_apply_save_data(parsed)
	return true


## 获取指定槽位的存档信息（用于 UI 显示）
func get_slot_info(slot: int) -> Dictionary:
	if slot < 1 or slot > MANUAL_SLOT_COUNT:
		return {}
	var path := _manual_slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"empty": true, "slot": slot}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"empty": true, "slot": slot}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"empty": true, "slot": slot}
	var data: Dictionary = parsed
	var loc_id: String = data.get("current_location", "")
	var loc_name: String = locations_data.get(loc_id, {}).get("name", loc_id) if locations_data.has(loc_id) else loc_id
	return {
		"empty": false,
		"slot": slot,
		"timestamp": data.get("save_timestamp", ""),
		"location": loc_name,
		"day": int(data.get("current_day", 1)),
		"state": data.get("current_state", ""),
		"evidence_count": data.get("collected_evidence", []).size(),
	}


func _manual_slot_path(slot: int) -> String:
	return _manual_slot_path_for_case(ACTIVE_CASE, slot)


func _manual_slot_path_for_case(case_id: String, slot: int) -> String:
	return "user://saves/%s_slot%d.json" % [case_id, slot]


func _case_has_primary_save(case_id: String) -> bool:
	var save_path := "user://saves/%s.json" % case_id
	if FileAccess.file_exists(save_path):
		return true
	var legacy := "user://%s_save.json" % case_id
	if not FileAccess.file_exists(legacy):
		return false
	if case_id != ACTIVE_CASE:
		return true
	_migrate_legacy_save(legacy)
	return FileAccess.file_exists(save_path)


func _latest_resume_save() -> Dictionary:
	# 先迁移当前案件旧版继续档，避免比较修改时间时漏掉它。
	has_save()
	var best: Dictionary = {}
	var auto_time := _existing_save_modified_time(SAVE_PATH)
	if auto_time > 0:
		best = {
			"kind": "auto",
			"modified_time": auto_time,
		}
	for slot in range(1, MANUAL_SLOT_COUNT + 1):
		var slot_path := _manual_slot_path(slot)
		var slot_time := _existing_save_modified_time(slot_path)
		if slot_time <= 0:
			continue
		if best.is_empty() or slot_time >= int(best.get("modified_time", 0)):
			best = {
				"kind": "slot",
				"slot": slot,
				"modified_time": slot_time,
			}
	return best


func _existing_save_modified_time(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var modified_time := int(FileAccess.get_modified_time(path))
	if modified_time == 0:
		modified_time = int(FileAccess.get_modified_time(ProjectSettings.globalize_path(path)))
	return max(modified_time, 1)


## 构建存档数据（供 auto-save 和 manual-save 共用）
func _build_save_data() -> Dictionary:
	var data := {
		"current_state": current_state,
		"current_day": current_day,
		"current_location": current_location,
		"collected_evidence": collected_evidence,
		"collected_clues": collected_clues,
		"visited_locations": visited_locations,
		"search_history": search_history,
		"dialogue_flags": dialogue_flags,
		"visited_nodes": visited_nodes,
		"visited_node_versions": visited_node_versions,
		"triggered_events": triggered_events,
		"npc_states": npc_states,
		"case_records": case_records,
		"dialogue_records": dialogue_records,
		"shown_time_cards": shown_time_cards,
		"case_seed": case_seed,
		"culprit_actions_witnessed": culprit_actions_witnessed,
		"unlocked_phases": unlocked_phases,
	}
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("get_save_data"):
		data["companion_state"] = cs.get_save_data()
	return data


## 从存档数据恢复游戏状态（供 auto-load 和 manual-load 共用）
func _apply_save_data(data: Dictionary) -> void:
	current_state = data.get("current_state", STATE_PLAYING)
	current_day = int(data.get("current_day", 1))
	current_location = data.get("current_location", case_main_scene)
	collected_evidence.assign(data.get("collected_evidence", []))
	collected_clues.assign(data.get("collected_clues", []))
	visited_locations.assign(data.get("visited_locations", [case_main_scene]))
	search_history = data.get("search_history", {})
	dialogue_flags = data.get("dialogue_flags", {})
	visited_nodes = data.get("visited_nodes", {})
	visited_node_versions = data.get("visited_node_versions", {})
	triggered_events = data.get("triggered_events", {})
	npc_states = data.get("npc_states", {})
	case_records.assign(data.get("case_records", []))
	dialogue_records.assign(data.get("dialogue_records", []))
	shown_time_cards = data.get("shown_time_cards", {})
	case_seed = int(data.get("case_seed", 0))
	culprit_actions_witnessed = data.get("culprit_actions_witnessed", {})
	suppress_evidence_obtain_hold = false
	_last_evidence_obtain_hold_enabled = true
	var saved_phases = data.get("unlocked_phases", ["phase_0", "phase_1"])
	unlocked_phases.clear()
	for p in saved_phases:
		unlocked_phases.append(str(p))
	_resolve_culprit_action_schedule()
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("load_save_data"):
		var comp_data: Dictionary = data.get("companion_state", {})
		if not comp_data.is_empty():
			cs.load_save_data(comp_data)
	_check_day_events()
	_check_progression()
	HookBus.emit_hook(HookBus.SAVE_LOADED, {})


func pending_event_ids() -> Array[String]:
	var result: Array[String] = []
	for evt_id in triggered_events.keys():
		if triggered_events.get(evt_id, false) and not has_flag(str(evt_id) + "_done"):
			result.append(str(evt_id))
	return result


# ─── 状态 ───
func set_state(new_state: String) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	if new_state != STATE_PROLOGUE:
		save_game()


# ─── 地点 ───
func change_location(loc_id: String, advance: bool = true) -> void:
	if not locations_data.has(loc_id):
		push_error("Unknown location: " + loc_id)
		return
	if not is_location_unlocked(loc_id):
		push_warning("Location locked: " + loc_id)
		return
	# 主地点内部移动不消耗时段
	if advance and _is_same_hub(current_location, loc_id):
		advance = false
	current_location = loc_id
	if not visited_locations.has(loc_id):
		visited_locations.append(loc_id)
	location_changed.emit(loc_id)
	HookBus.emit_hook(HookBus.LOCATION_CHANGED, {"location_id": loc_id})
	save_game()


## 判断两个地点是否属于同一个 hub（parent 相同，或互为 parent/child）
func _is_same_hub(a: String, b: String) -> bool:
	if a == b:
		return true
	var da: Dictionary = locations_data.get(a, {})
	var db: Dictionary = locations_data.get(b, {})
	var pa: String = da.get("parent", "")
	var pb: String = db.get("parent", "")
	# 都有同一个 parent
	if pa != "" and pa == pb:
		return true
	# a 是 b 的 parent
	if pb == a:
		return true
	# b 是 a 的 parent
	if pa == b:
		return true
	# a 和 b 分别是子地点和 hub，通过 parent 关联
	if pa != "" and pa == pb:
		return true
	return false


func get_location_data(loc_id: String) -> Dictionary:
	var data = locations_data.get(loc_id, {})
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}


func current_location_data() -> Dictionary:
	return get_location_data(current_location)


# ─── 证据/线索 ───
func add_evidence(eid: String, hold_obtain_display := true) -> bool:
	if collected_evidence.has(eid):
		return false
	collected_evidence.append(eid)
	_apply_transitions("evidence_obtained:" + eid)
	_last_evidence_obtain_hold_enabled = hold_obtain_display and not suppress_evidence_obtain_hold
	evidence_added.emit(eid)
	HookBus.emit_hook(HookBus.EVIDENCE_ADDED, {"evidence_id": eid})
	# 自动存档已移除，改为关键节点前存档
	return true


func should_hold_last_evidence_obtain_display() -> bool:
	return _last_evidence_obtain_hold_enabled


func add_clue(cid: String) -> bool:
	if collected_clues.has(cid):
		return false
	collected_clues.append(cid)
	_apply_transitions("clue_obtained:" + cid)
	clue_added.emit(cid)
	HookBus.emit_hook(HookBus.CLUE_ADDED, {"clue_id": cid})
	# 自动存档已移除，改为关键节点前存档
	return true


func has_clue(cid: String) -> bool:
	return collected_clues.has(cid)


func has_evidence(eid: String) -> bool:
	return collected_evidence.has(eid)


# ─── 卷宗 / 对话记录 ───
func add_case_record(record: Dictionary) -> bool:
	var title: String = str(record.get("title", record.get("record_title", ""))).strip_edges()
	var text: String = str(record.get("text", record.get("record_text", ""))).strip_edges()
	if title == "" and text == "":
		return false
	var record_id: String = str(record.get("id", record.get("record_id", ""))).strip_edges()
	if record_id == "":
		record_id = "%s|%s" % [title, text]
	for existing in case_records:
		if str(existing.get("id", "")) == record_id:
			return false
	var entry := {
		"id": record_id,
		"type": str(record.get("type", record.get("record_type", "key"))),
		"title": title if title != "" else "卷宗记录",
		"text": text,
		"source": str(record.get("source", "")),
		"day": current_day,
		"period": 0,
	}
	case_records.append(entry)
	# 自动存档已移除，改为关键节点前存档
	return true


func add_dialogue_record(speaker: String, text: String) -> void:
	var clean_text := text.strip_edges()
	if clean_text == "":
		return
	if not dialogue_records.is_empty():
		var last: Dictionary = dialogue_records[dialogue_records.size() - 1]
		if last.get("speaker", "") == speaker and last.get("text", "") == clean_text:
			return
	dialogue_records.append({
		"speaker": speaker if speaker != "" else "旁白",
		"text": clean_text,
		"day": current_day,
		"period": 0,
	})
	while dialogue_records.size() > 240:
		dialogue_records.pop_front()
	# 自动存档已移除，改为关键节点前存档


# ─── Flags / 访问记录 ───
func set_flag(flag_id: String) -> void:
	if dialogue_flags.get(flag_id, false):
		return
	dialogue_flags[flag_id] = true
	_apply_transitions("flag_set:" + flag_id)
	flag_set.emit(flag_id)
	HookBus.emit_hook(HookBus.FLAG_SET, {"flag_id": flag_id})
	# 自动存档已移除，改为关键节点前存档


func has_flag(flag_id: String) -> bool:
	return dialogue_flags.get(flag_id, false)


## 检查 key_info 的 requires 条件是否满足
func check_key_info_requires(requires: Dictionary) -> bool:
	if requires.is_empty():
		return true
	if requires.has("flag"):
		return has_flag(requires["flag"])
	if requires.has("all"):
		for cond in requires["all"]:
			if cond.has("flag") and not has_flag(cond["flag"]):
				return false
		return true
	return false


func mark_node_visited(npc_id: String, node_id: String) -> void:
	var key := "%s.%s" % [npc_id, node_id]
	visited_nodes[key] = visited_nodes.get(key, 0) + 1
	_apply_transitions_for_npc(npc_id, "node_visited:" + node_id)
	node_visited.emit(npc_id, node_id)
	HookBus.emit_hook(HookBus.NODE_VISITED, {"npc_id": npc_id, "node_id": node_id})
	# 自动存档已移除，改为关键节点前存档


func node_visit_count(npc_id: String, node_id: String) -> int:
	return visited_nodes.get("%s.%s" % [npc_id, node_id], 0)


func has_visited(npc_id: String, node_id: String) -> bool:
	return node_visit_count(npc_id, node_id) > 0


func mark_node_version_seen(npc_id: String, node_id: String, version: String) -> void:
	if version == "":
		return
	visited_node_versions["%s.%s" % [npc_id, node_id]] = version


func has_seen_node_version(npc_id: String, node_id: String, version: String) -> bool:
	if version == "":
		return has_visited(npc_id, node_id)
	return str(visited_node_versions.get("%s.%s" % [npc_id, node_id], "")) == version


## 统计玩家在某个 NPC 的 hub 中访问过多少个不同的分支节点。
## 用于 "min_hub_visits" 条件：对话选项循序渐进解锁。
func hub_visited_count(npc_id: String) -> int:
	var count := 0
	var prefix := npc_id + "."
	for key in visited_nodes.keys():
		if key.begins_with(prefix):
			var node_id: String = key.substr(prefix.length())
			# 排除 hub 节点本身和 __exit__ 等系统节点
			if node_id != "hub" and not node_id.begins_with("__"):
				count += 1
	return count


# ─── NPC 状态机 ───
func get_npc_state(npc_id: String, stat: String, default = 0):
	var state: Dictionary = npc_states.get(npc_id, {})
	return state.get(stat, default)


func set_npc_state(npc_id: String, stat: String, value) -> void:
	if not npc_states.has(npc_id):
		npc_states[npc_id] = {}
	npc_states[npc_id][stat] = value
	HookBus.emit_hook(HookBus.NPC_STATE_CHANGED, {"npc_id": npc_id, "stat": stat, "value": value})


func _apply_transitions(event_key: String) -> void:
	# 全局事件（不限定 npc）：遍历所有 npc 看是否匹配
	for npc_id in npc_states_data.keys():
		_apply_transitions_for_npc(npc_id, event_key)


func _apply_transitions_for_npc(npc_id: String, event_key: String) -> void:
	var raw = npc_states_data.get(npc_id, {})
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var conf: Dictionary = raw
	for t in conf.get("transitions", []):
		if t.get("on", "") != event_key:
			continue
		var delta: Dictionary = t.get("delta", {})
		for stat in delta.keys():
			var cur = get_npc_state(npc_id, stat, 0)
			set_npc_state(npc_id, stat, cur + int(delta[stat]))


# ─── 通用条件评估 ───
## requires 支持：
##   { "evidence": "evidence_id" } 收集了该证据
##   { "clue": "clue_id" }
##   { "flag": "flag_id" }
##   { "visited": "npc_id.node_id" }
##   { "location_unlocked": "loc_id" }  地点已解锁
##   { "evidence_count_gte": N }  证据总数 >= N
##   { "state": "npc.stat", "lt": N } / "lte" / "gt" / "gte" / "eq"
##   { "not": <cond> }
##   { "all": [cond1, cond2, ...] }
##   { "any": [cond1, cond2, ...] }
func evaluate_condition(cond) -> bool:
	if cond == null:
		return true
	if cond is Array:
		# 默认 all
		for c in cond:
			if not evaluate_condition(c):
				return false
		return true
	if not (cond is Dictionary):
		return true
	var d: Dictionary = cond
	if d.is_empty():
		return true
	# 复合
	if d.has("not"):
		return not evaluate_condition(d["not"])
	if d.has("all"):
		for c in d["all"]:
			if not evaluate_condition(c):
				return false
		return true
	if d.has("any"):
		for c in d["any"]:
			if evaluate_condition(c):
				return true
		return false
	# 单项
	if d.has("evidence"):
		return has_evidence(d["evidence"])
	if d.has("clue"):
		return has_clue(d["clue"])
	if d.has("evidence_count_gte"):
		return collected_evidence.size() >= int(d["evidence_count_gte"])
	if d.has("clue_count_gte"):
		return collected_clues.size() >= int(d["clue_count_gte"])
	if d.has("flag"):
		return has_flag(d["flag"])
	if d.has("not_flag"):
		return not has_flag(d["not_flag"])
	# 别名（与旧 CompanionService 讨论条件键统一口径）
	if d.has("has_evidence"):
		return has_evidence(d["has_evidence"])
	if d.has("has_clue"):
		return has_clue(d["has_clue"])
	if d.has("has_flag"):
		return has_flag(d["has_flag"])
	# 精确剧情日
	if d.has("day"):
		return get_story_day() == int(d["day"])
	# 关键证据收集比例（用于"证据是否齐了的"话题/提示）
	if d.has("evidence_ratio_gte"):
		var key_ev: Array = case_data.get("key_evidence", [])
		if key_ev.is_empty():
			return false
		var ev_count := 0
		for ev in key_ev:
			if has_evidence(str(ev)):
				ev_count += 1
		return float(ev_count) / float(key_ev.size()) >= float(d["evidence_ratio_gte"])
	# 当前地点条件，用于 NPC 移动后的场景化开场白/选项
	if d.has("location"):
		return current_location == str(d["location"])
	# NPC 当前所在地条件：{ "npc_location": { "npc": "bu_zhang", "location": "pavilion_main" } }
	if d.has("npc_location"):
		var loc_spec = d["npc_location"]
		if typeof(loc_spec) == TYPE_DICTIONARY:
			var loc_npc: String = str(loc_spec.get("npc", ""))
			var loc_id: String = str(loc_spec.get("location", ""))
			if loc_npc == "" or loc_id == "":
				return false
			return get_npc_schedule(loc_npc).get("location", "") == loc_id
		return false
	# NPC 当前活动条件：{ "npc_activity": { "npc": "bu_zhang", "activity": "collect_debt" } }
	if d.has("npc_activity"):
		var act_spec = d["npc_activity"]
		if typeof(act_spec) == TYPE_DICTIONARY:
			var act_npc: String = str(act_spec.get("npc", ""))
			var act_id: String = str(act_spec.get("activity", ""))
			if act_npc == "" or act_id == "":
				return false
			return get_npc_schedule(act_npc).get("activity", "") == act_id
		return false
	if d.has("visited"):
		var v: String = d["visited"]
		var parts := v.split(".")
		if parts.size() == 2:
			return has_visited(parts[0], parts[1])
		# 单段：按地点访问理解（与旧 CompanionService 语义统一）
		return visited_locations.has(v)
	if d.has("not_visited"):
		return not visited_locations.has(str(d["not_visited"]))
	if d.has("location_unlocked"):
		return is_location_unlocked(str(d["location_unlocked"]))
	if d.has("day_gte"):
		return get_story_day() >= int(d["day_gte"])
	if d.has("day_lte"):
		return get_story_day() <= int(d["day_lte"])
	if d.has("total_periods_used_gte"):
		var total := 0
		for v in search_history.values():
			total += int(v)
		return total >= int(d["total_periods_used_gte"])
	if d.has("state"):
		var sk: String = d["state"]
		var p := sk.split(".")
		if p.size() != 2:
			return false
		var val: int = int(get_npc_state(p[0], p[1], 0))
		if d.has("lt"): return val < int(d["lt"])
		if d.has("lte"): return val <= int(d["lte"])
		if d.has("gt"): return val > int(d["gt"])
		if d.has("gte"): return val >= int(d["gte"])
		if d.has("eq"): return val == int(d["eq"])
	return true


# ─── 搜索 ───
func resolve_search(location_id: String, point_id: String) -> Dictionary:
	var key := "%s.%s" % [location_id, point_id]
	var entries: Dictionary = search_results_data.get(key, {})
	if entries.is_empty():
		return { "narration": "你在此处仔细查看，但未发现什么异常。", "time_cost": 1 }
	# 选条件最匹配的条目
	var chosen: Dictionary = entries.get("default", {})
	# 支持新的 conditional 数组语法
	if entries.has("conditional"):
		for entry in entries["conditional"]:
			if evaluate_condition(entry.get("when", {})):
				chosen = entry
				break
	# 兼容旧的 after_clue:xxx
	for ek in entries.keys():
		if ek.begins_with("after_clue:"):
			var required: String = ek.substr("after_clue:".length())
			if has_clue(required):
				chosen = entries[ek]
				break
	
	var loc_data := get_location_data(location_id)
	var time_cost := 1
	for sp in loc_data.get("search_points", []):
		if sp.get("id", "") == point_id:
			time_cost = int(sp.get("time_cost", 1))
			break
	
	var done_count: int = search_history.get(key, 0)
	search_history[key] = done_count + 1
	
	var result := {
		"narration": chosen.get("narration", ""),
		"time_cost": time_cost,
		"gained_evidence": "",
		"gained_clue": "",
		"trigger_dialogue": chosen.get("trigger_dialogue", ""),
		"trigger_dialogue_start": chosen.get("trigger_dialogue_start", ""),
		"already_done": done_count > 0,
		"intro_text": chosen.get("intro_text", ""),
		"sub_choices": chosen.get("sub_choices", []),
	}
	if done_count == 0:
		var ev: String = chosen.get("evidence", "")
		var cl: String = chosen.get("clue", "")
		if ev != "" and add_evidence(ev):
			result.gained_evidence = ev
		if cl != "" and add_clue(cl):
			result.gained_clue = cl
		# 设置 flag
		for f in chosen.get("set_flags", []):
			set_flag(f)
	else:
		# 重复探索：保留原叙述和证据引用（用于显示证物图片），不换通用文案
		var ev_ref: String = chosen.get("evidence", "")
		var cl_ref: String = chosen.get("clue", "")
		if ev_ref != "":
			result.gained_evidence = ev_ref
		if cl_ref != "":
			result.gained_clue = cl_ref
	# 触发对话不论是否第一次都执行（适用于"再次约见"场景）
	# 自动存档已移除，改为关键节点前存档
	HookBus.emit_hook(HookBus.SEARCH_RESOLVED, {"location_id": location_id, "point_id": point_id, "result": result})
	return result


# ─── NPC ───
func get_npc_data(nid: String) -> Dictionary:
	return npcs_data.get(nid, {})


## 获取 NPC 对玩家显示的名字（考虑名字是否已解锁）
func get_npc_display_name(nid: String) -> String:
	if not npcs_data.has(nid):
		return nid
	var raw = npcs_data[nid]
	if typeof(raw) != TYPE_DICTIONARY:
		return nid
	var data: Dictionary = raw
	if data.is_empty():
		return nid
	# 没有 hidden_name 字段 → 始终显示真名
	if not data.get("hidden_name", false):
		return data.get("name", nid)
	# 检查是否满足解锁条件
	var cond = data.get("reveal_name_condition", null)
	if cond != null and evaluate_condition(cond):
		return data.get("name", nid)
	# 未解锁 → 显示 unknown_label
	return data.get("unknown_label", data.get("title", nid))


## 判断 NPC 名字是否已对玩家揭示
func is_npc_name_revealed(nid: String) -> bool:
	var data: Dictionary = npcs_data.get(nid, {})
	if not data.get("hidden_name", false):
		return true
	var cond = data.get("reveal_name_condition", null)
	if cond == null:
		return true
	return evaluate_condition(cond)


# ─── 渐进式开放系统 ───
func _check_progression() -> void:
	if progression_data.is_empty():
		return
	# 序章叙事期间不触发阶段解锁（但允许无条件的阶段如phase_0解锁）
	if current_state == STATE_PROLOGUE:
		# 序章期间只解锁无条件的阶段（如phase_0）
		for phase in progression_data.get("phases", []):
			var pid: String = phase.get("id", "")
			if pid == "" or unlocked_phases.has(pid):
				continue
			var cond = phase.get("unlock_condition", null)
			if cond == null:
				unlocked_phases.append(pid)
				phase_unlocked.emit(pid)
				# 发送助手引导提示
				var notifs: Dictionary = progression_data.get("phase_notifications", {})
				if notifs.has(pid):
					var n: Dictionary = notifs[pid]
					progression_hint.emit(n.get("speaker", ""), n.get("text", ""))
			return
	for phase in progression_data.get("phases", []):
		var pid: String = phase.get("id", "")
		if pid == "" or unlocked_phases.has(pid):
			continue
		var cond = phase.get("unlock_condition", null)
		# 如果条件为null，自动解锁（如phase_0）
		if cond == null:
			unlocked_phases.append(pid)
			phase_unlocked.emit(pid)
			# 发送助手引导提示
			var notifs: Dictionary = progression_data.get("phase_notifications", {})
			if notifs.has(pid):
				var n: Dictionary = notifs[pid]
				progression_hint.emit(n.get("speaker", ""), n.get("text", ""))
			continue
		if evaluate_condition(cond):
			unlocked_phases.append(pid)
			phase_unlocked.emit(pid)
			# 发送助手引导提示
			var notifs: Dictionary = progression_data.get("phase_notifications", {})
			if notifs.has(pid):
				var n: Dictionary = notifs[pid]
				progression_hint.emit(n.get("speaker", ""), n.get("text", ""))


## 判断地点是否已解锁
func is_location_unlocked(loc_id: String) -> bool:
	if progression_data.is_empty():
		return true
	var loc_data: Dictionary = locations_data.get(loc_id, {})
	var phase_id: String = loc_data.get("unlock_phase", "")
	if phase_id == "":
		return true
	return unlocked_phases.has(phase_id)


## 获取所有已解锁的地点 ID
func get_unlocked_locations() -> Array:
	var result: Array = []
	for loc_id in locations_data.keys():
		if is_location_unlocked(loc_id):
			result.append(loc_id)
	return result


## 判断搜索点是否已解锁
func is_search_point_unlocked(location_id: String, point_id: String) -> bool:
	if progression_data.is_empty():
		return true
	var sp_unlock: Dictionary = progression_data.get("search_point_unlock", {})
	var key := "%s.%s" % [location_id, point_id]
	if not sp_unlock.has(key):
		return true
	var entry: Dictionary = sp_unlock[key]
	return evaluate_condition(entry.get("condition", null))


## 获取搜索点锁定提示
func get_search_point_locked_hint(location_id: String, point_id: String) -> String:
	var sp_unlock: Dictionary = progression_data.get("search_point_unlock", {})
	var key := "%s.%s" % [location_id, point_id]
	if sp_unlock.has(key):
		return sp_unlock[key].get("locked_hint", "此处暂时无法调查。")
	return ""


## 判断NPC是否已解锁（可见）
func is_npc_unlocked(npc_id: String) -> bool:
	if progression_data.is_empty():
		return true
	var npc_unlock: Dictionary = progression_data.get("npc_unlock", {})
	if not npc_unlock.has(npc_id):
		return true
	var entry: Dictionary = npc_unlock[npc_id]
	return evaluate_condition(entry.get("condition", null))


## 判断面板是否已解锁
func is_panel_unlocked(panel_id: String) -> bool:
	if progression_data.is_empty():
		return true
	var panel_unlock: Dictionary = progression_data.get("panel_unlock", {})
	if not panel_unlock.has(panel_id):
		return true
	var entry: Dictionary = panel_unlock[panel_id]
	return evaluate_condition(entry.get("condition", null))


## 获取面板锁定提示
func get_panel_locked_hint(panel_id: String) -> String:
	var panel_unlock: Dictionary = progression_data.get("panel_unlock", {})
	if panel_unlock.has(panel_id):
		return panel_unlock[panel_id].get("locked_hint", "尚未解锁。")
	return ""


## 获取当前阶段信息
func get_current_phase() -> Dictionary:
	if progression_data.is_empty():
		return {}
	var phases: Array = progression_data.get("phases", [])
	var current: Dictionary = {}
	for phase in phases:
		var pid: String = phase.get("id", "")
		if unlocked_phases.has(pid):
			current = phase
	return current


## 获取当前阶段的引导提示
func get_current_phase_hint() -> String:
	var phase := get_current_phase()
	return phase.get("hint", "")


## 剧情日：从 time_progression.csv 推导（与 get_current_time_label 同一遍历逻辑）。
## 序章的时间不是消耗制，而是剧情标签制——第一个 trigger 满足的行决定"今天是第几天"。
## 无数据时回退 current_day 字段。
var _story_day_resolving := false

func get_story_day() -> int:
	# 防递归：trigger_condition 若含 day_gte/day_lte 会回到 evaluate_condition → get_story_day
	if _story_day_resolving:
		return current_day
	_story_day_resolving = true
	var result := current_day
	for entry in time_progression_data:
		if evaluate_condition(entry.get("trigger_condition", null)):
			result = int(entry.get("day", current_day))
			break
	_story_day_resolving = false
	return result


## 案件总天数：time_progression 中的最大剧情日（无数据时回退 1）
func get_total_days() -> int:
	var max_day := 1
	for entry in time_progression_data:
		max_day = maxi(max_day, int(entry.get("day", 1)))
	return max_day


## 年代前缀：从 manifest.subtitle 推导（"万历廿二年 · 腊月 · 荆江" → "万历廿二年 · 腊月"）
func _era_prefix() -> String:
	var subtitle: String = str(case_manifest.get("subtitle", ""))
	if subtitle == "":
		return ""
	var parts: Array = []
	for p in subtitle.split("·"):
		parts.append(str(p).strip_edges())
	if parts.size() >= 2:
		parts = parts.slice(0, parts.size() - 1)
	return " · ".join(parts)


## 根据 time_progression 数据返回当前时间标签（数据驱动）
func get_current_time_label() -> String:
	# 万历格式的日期标签
	var day_names := ["", "第一天", "第二天", "第三天", "第四天", "第五天"]
	# 年代前缀（从 manifest.subtitle 推导，数据驱动）
	var era_prefix := _era_prefix()

	for entry in time_progression_data:
		if evaluate_condition(entry.get("trigger_condition", null)):
			var d: int = int(entry.get("day", 1))
			var day_str: String = day_names[clampi(d, 1, day_names.size() - 1)]
			var period: String = str(entry.get("period_label", "辰时"))
			# 使用万历格式：万历廿二年 · 腊月 · 亥时
			return "%s · %s" % [era_prefix, period]
	# 默认
	var day_str: String = day_names[clampi(current_day, 1, day_names.size() - 1)]
	return "%s · 辰时" % era_prefix


# ─── 日程事件 ───
func _check_day_events() -> void:
	# 序章叙事期间不触发日程事件
	if current_state == STATE_PROLOGUE:
		return
	for evt in day_events_data.get("events", []):
		var evt_id: String = str(evt.get("id", ""))
		if triggered_events.get(evt_id, false):
			continue
		if evaluate_condition(evt.get("trigger", {})):
			# 标记为可触发（但不自动播放，需要 UI 提示玩家）
			triggered_events[evt_id] = true
			day_event_available.emit(evt_id)


func get_day_event(evt_id: String) -> Dictionary:
	for evt in day_events_data.get("events", []):
		if evt.get("id", "") == evt_id:
			return evt
	return {}


func apply_event_effects(evt: Dictionary, hold_obtain_display := true) -> void:
	var effects: Dictionary = evt.get("effects", {}).duplicate()
	# 自动设置一个 evt_id_done 的 flag（与事件 trigger 中的 not flag 配对）
	var evt_id: String = str(evt.get("id", ""))
	if evt_id != "":
		effects["auto_done_flag"] = evt_id
	EffectRegistry.apply_effects(effects, {"hold_obtain_display": hold_obtain_display})


# ─── 指证 ───
func judge_accusation(suspect: String, motive: String, method: String, selected_evidence: Array) -> String:
	var truth = case_data
	var suspect_ok: bool = (suspect == truth.get("culprit", ""))
	var motive_ok: bool = (motive == truth.get("motive", ""))
	var method_ok: bool = (method == truth.get("method", ""))
	var key_ev: Array = truth.get("key_evidence", [])
	var min_req: int = int(truth.get("min_evidence_required", 3))
	var ev_match := 0
	for ev in selected_evidence:
		if key_ev.has(ev):
			ev_match += 1
	if not suspect_ok:
		return "bad"
	if suspect_ok and motive_ok and method_ok and ev_match >= min_req:
		return "perfect"
	if suspect_ok and motive_ok and ev_match >= 2:
		return "good"
	if suspect_ok:
		return "partial"
	return "bad"


## 根据对峙结果判定结局等级
## result: "victory" / "defeat"
## mistakes: 选错证据的次数
func judge_confrontation(result: String, mistakes: int) -> String:
	if result != "victory":
		return "bad"
	# 全部击破，根据失误次数定等级
	if mistakes == 0:
		return "perfect"
	if mistakes <= 1:
		return "good"
	return "partial"


func get_ending(ending_id: String) -> Dictionary:
	return case_data.get("endings", {}).get(ending_id, {})


# ─── NPC 调度（schedule）─────────────────────────────────

## "D2_P3" → Vector2i(day, period)；解析失败返回 (-1,-1)
static func _parse_dp(s: String) -> Vector2i:
	if not s.begins_with("D"):
		return Vector2i(-1, -1)
	var p_idx := s.find("_P")
	if p_idx < 0:
		return Vector2i(-1, -1)
	var d := int(s.substr(1, p_idx - 1))
	var p := int(s.substr(p_idx + 2))
	return Vector2i(d, p)


## 用 case_seed 解算凶手每个动作的实际执行时段（基础时刻 + ±jitter 抖动）
## 注：此功能为未来动态案件保留，当前不依赖时段推进
func _resolve_culprit_action_schedule() -> void:
	culprit_action_resolved.clear()
	if case_seed == 0:
		case_seed = int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
	var actions: Array = culprit_actions_data.get("actions", [])
	if actions.is_empty():
		return
	const _PERIODS_PER_DAY := 14
	const _TOTAL_DAYS := 3
	var rng := RandomNumberGenerator.new()
	rng.seed = case_seed
	for a in actions:
		if typeof(a) != TYPE_DICTIONARY:
			continue
		var aid: String = a.get("id", "")
		var dp_str: String = a.get("day_period", "")
		var jitter: int = int(a.get("jitter", 0))
		var dp := _parse_dp(dp_str)
		if dp.x < 0:
			continue
		var base_abs := (dp.x - 1) * _PERIODS_PER_DAY + dp.y
		var delta := 0
		if jitter > 0:
			delta = rng.randi_range(-jitter, jitter)
		var final_abs: int = clamp(base_abs + delta, 0, _TOTAL_DAYS * _PERIODS_PER_DAY - 1)
		@warning_ignore("integer_division")
		var vd: int = final_abs / _PERIODS_PER_DAY + 1
		var vp: int = final_abs % _PERIODS_PER_DAY
		culprit_action_resolved[aid] = "D%d_P%d" % [vd, vp]


## 取某 NPC 的当前调度（基于 flag 条件）
## 返回 {"location": "...", "activity": "...", "public": bool} 或 {} 表示无调度
## 优先级：conditional_override（flag 触发） > default
func get_npc_schedule(npc_id: String) -> Dictionary:
	var entry = schedules_data.get(npc_id, null)
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	# 条件 override（flag 被设置后替换 default）
	var cond_overrides: Array = entry.get("conditional_overrides", [])
	for co in cond_overrides:
		if typeof(co) != TYPE_DICTIONARY:
			continue
		var flag: String = co.get("if_flag", "")
		if flag != "" and has_flag(flag):
			var sched = co.get("schedule", null)
			if typeof(sched) == TYPE_DICTIONARY:
				return sched
	# default
	var def = entry.get("default", null)
	if typeof(def) == TYPE_DICTIONARY:
		return def
	return {}


## 兼容旧接口：带 day/period 参数（忽略时段，仅用 flag 逻辑）
func get_npc_schedule_at(npc_id: String, _day: int, _period: int) -> Dictionary:
	return get_npc_schedule(npc_id)


## 取当前位置的有效 NPC 列表（public=true 的才会自然出现）
## 优先用 schedule，schedule 缺失则回退到 locations.json 的静态 npcs 字段
## 会过滤渐进系统中未解锁的 NPC
func get_active_npcs_at(location_id: String, _day: int = -1, _period: int = -1) -> Array:
	# 如果当前案件没配 schedules，直接回退到静态
	if schedules_data.is_empty():
		var fallback_loc := get_location_data(location_id)
		var static_npcs: Array = fallback_loc.get("npcs", [])
		var filtered: Array = []
		for nid in static_npcs:
			if is_npc_unlocked(str(nid)):
				filtered.append(nid)
		return filtered
	var result: Array = []
	for npc_id in schedules_data.keys():
		if typeof(npc_id) != TYPE_STRING:
			continue
		var nid: String = npc_id
		if nid.begins_with("_"):
			continue
		if not is_npc_unlocked(nid):
			continue
		var sched := get_npc_schedule(nid)
		if sched.is_empty():
			continue
		if sched.get("location", "") != location_id:
			continue
		if not bool(sched.get("public", true)):
			continue
		result.append(nid)
	# 同时合并 locations.json 中的静态 npcs（兼容老数据）
	var static_loc := get_location_data(location_id)
	for nid2 in static_loc.get("npcs", []):
		var nid_s := str(nid2)
		if not schedules_data.has(nid_s) and not result.has(nid_s):
			if is_npc_unlocked(nid_s):
				result.append(nid_s)
	return result


## "重置随机种子" —— 新游戏开局时调用
func reroll_case_seed() -> void:
	case_seed = int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
	_resolve_culprit_action_schedule()
