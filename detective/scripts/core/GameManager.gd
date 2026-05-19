extends Node
## 全局游戏管理器：状态、时间、地点、证据、线索、剧情标记、NPC 状态机、日程事件

signal state_changed(new_state: String)
signal time_advanced(day: int, period: int)
signal day_changed(new_day: int)
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

# 时间系统：6 时段/天，共 7 天
const PERIODS_PER_DAY := 14
const TOTAL_DAYS := 3
const PERIOD_NAMES := [
	"清晨", "辰时", "近午", "正午", "未初", "未时", "申初",
	"申时", "酉初", "酉时", "戌初", "戌时", "亥初", "亥时"
]

# 当前案件（动态可切换）
const CASE_INDEX_PATH := "res://data/cases/_index.json"
const CURRENT_CASE_PATH := "user://current_case.json"
const DEFAULT_CASE := "linchuan_inn"

var ACTIVE_CASE: String = DEFAULT_CASE

# 当前案件的初始定位地点（从 manifest.main_scene 读，回退到 DEFAULT_MAIN_SCENE）
const DEFAULT_MAIN_SCENE := "post_station"
var case_main_scene: String = DEFAULT_MAIN_SCENE

# 当前案件元信息（来自 manifest.json）
var case_manifest: Dictionary = {}

# 案件索引（来自 _index.json）
var case_index: Dictionary = {}

# 存档路径（按案件分槽，user://saves/<case_id>.json）
var SAVE_PATH: String = "user://saves/%s.json" % DEFAULT_CASE

var current_state: String = STATE_PROLOGUE
var current_day: int = 1
var current_period: int = 0
var current_location: String = "post_station"

# 数据
var locations_data: Dictionary = {}
var npcs_data: Dictionary = {}
var evidence_data: Dictionary = {}
var search_results_data: Dictionary = {}
var case_data: Dictionary = {}
var day_events_data: Dictionary = {}
var npc_states_data: Dictionary = {}
# 渐进式开放系统
var progression_data: Dictionary = {}
var unlocked_phases: Array[String] = ["phase_1"]

# 新：NPC 时段日程 + 凶手行动表（动态案件可选）
var schedules_data: Dictionary = {}
var culprit_actions_data: Dictionary = {}
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
var triggered_events: Dictionary = {}   # event_id -> true
var npc_states: Dictionary = {}         # npc_id -> { stat_name: value }


func _ready() -> void:
	_load_case_index()
	_resolve_active_case()
	_load_data()
	_init_npc_states()


# ─── 案件管理 ───
func _load_case_index() -> void:
	if not FileAccess.file_exists(CASE_INDEX_PATH):
		return
	var f := FileAccess.open(CASE_INDEX_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		case_index = parsed


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
	return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://data/cases/%s" % case_id)) \
		or FileAccess.file_exists("res://data/cases/%s/case.json" % case_id)


func _set_active_case(case_id: String, persist: bool = true) -> void:
	ACTIVE_CASE = case_id
	SAVE_PATH = "user://saves/%s.json" % case_id
	# 确保 user://saves/ 目录存在
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://saves")):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	# 加载 manifest
	case_manifest = _read_json(_case_path("manifest.json"))
	case_main_scene = case_manifest.get("main_scene", DEFAULT_MAIN_SCENE)
	if persist:
		var f := FileAccess.open(CURRENT_CASE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify({"case_id": case_id}))


## 切换到另一个案件。会：
##   1) 写 current_case.json，下次启动会记得
##   2) 重新加载该案件的全套 JSON 数据
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
	current_period = 0
	current_location = case_main_scene
	collected_evidence.clear()
	collected_clues.clear()
	visited_locations = [case_main_scene]
	search_history.clear()
	dialogue_flags.clear()
	visited_nodes.clear()
	triggered_events.clear()
	culprit_actions_witnessed.clear()
	unlocked_phases = ["phase_1"]
	reroll_case_seed()
	# 切换案件时刷新助手系统数据
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("reload_for_case"):
		cs.reload_for_case()
	return true


func get_case_index_entries() -> Array:
	return case_index.get("cases", [])


# ─── 数据加载 ───
func _case_path(filename: String) -> String:
	return "res://data/cases/%s/%s" % [ACTIVE_CASE, filename]


func _load_data() -> void:
	locations_data = _read_json(_case_path("locations.json"))
	npcs_data = _read_json(_case_path("npcs.json"))
	evidence_data = _read_json(_case_path("evidence.json"))
	search_results_data = _read_json(_case_path("search_results.json"))
	case_data = _read_json(_case_path("case.json"))
	day_events_data = _read_json(_case_path("day_events.json"))
	npc_states_data = _read_json(_case_path("npc_states.json"))
	progression_data = _read_json(_case_path("progression.json"))
	# 新：NPC schedule 与凶手行动表（可选，没有就退回静态行为）
	schedules_data = _read_json(_case_path("schedules.json"))
	culprit_actions_data = _read_json(_case_path("culprit_actions.json"))
	_resolve_culprit_action_schedule()
	# 通知资产解析器加载本案的 casting / bgm_config
	if Engine.has_singleton("AssetResolver") or get_node_or_null("/root/AssetResolver") != null:
		var resolver := get_node_or_null("/root/AssetResolver")
		if resolver and resolver.has_method("load_case"):
			resolver.load_case(ACTIVE_CASE)


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
	current_period = 0
	current_location = case_main_scene
	collected_evidence.clear()
	collected_clues.clear()
	visited_locations = [case_main_scene]
	search_history.clear()
	dialogue_flags.clear()
	visited_nodes.clear()
	triggered_events.clear()
	culprit_actions_witnessed.clear()
	unlocked_phases = ["phase_1"]
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
	var data := {
		"current_state": current_state,
		"current_day": current_day,
		"current_period": current_period,
		"current_location": current_location,
		"collected_evidence": collected_evidence,
		"collected_clues": collected_clues,
		"visited_locations": visited_locations,
		"search_history": search_history,
		"dialogue_flags": dialogue_flags,
		"visited_nodes": visited_nodes,
		"triggered_events": triggered_events,
		"npc_states": npc_states,
		"case_seed": case_seed,
		"culprit_actions_witnessed": culprit_actions_witnessed,
		"unlocked_phases": unlocked_phases,
	}
	# 助手系统状态
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("get_save_data"):
		data["companion_state"] = cs.get_save_data()
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	current_state = data.get("current_state", STATE_PLAYING)
	current_day = int(data.get("current_day", 1))
	current_period = int(data.get("current_period", 0))
	current_location = data.get("current_location", case_main_scene)
	collected_evidence.assign(data.get("collected_evidence", []))
	collected_clues.assign(data.get("collected_clues", []))
	visited_locations.assign(data.get("visited_locations", [case_main_scene]))
	search_history = data.get("search_history", {})
	dialogue_flags = data.get("dialogue_flags", {})
	visited_nodes = data.get("visited_nodes", {})
	triggered_events = data.get("triggered_events", {})
	npc_states = data.get("npc_states", {})
	case_seed = int(data.get("case_seed", 0))
	culprit_actions_witnessed = data.get("culprit_actions_witnessed", {})
	var saved_phases = data.get("unlocked_phases", ["phase_1"])
	unlocked_phases.clear()
	for p in saved_phases:
		unlocked_phases.append(str(p))
	# 用恢复出来的 case_seed 重算凶手动作的实际时刻，确保读档与原游玩一致
	_resolve_culprit_action_schedule()
	# 恢复助手系统状态
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("load_save_data"):
		var comp_data: Dictionary = data.get("companion_state", {})
		if not comp_data.is_empty():
			cs.load_save_data(comp_data)
	return true


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


# ─── 时间 ───
func advance_period(periods: int = 1) -> void:
	var old_day := current_day
	for i in range(periods):
		current_period += 1
		if current_period >= PERIODS_PER_DAY:
			current_period = 0
			current_day += 1
	time_advanced.emit(current_day, current_period)
	if current_day != old_day:
		day_changed.emit(current_day)
	_run_culprit_tick()
	_check_day_events()
	_check_progression()
	save_game()


func is_time_up() -> bool:
	return current_day > TOTAL_DAYS


func current_time_text() -> String:
	return "第 %d 日 · %s" % [current_day, PERIOD_NAMES[current_period]]


func remaining_periods() -> int:
	var used = (current_day - 1) * PERIODS_PER_DAY + current_period
	return TOTAL_DAYS * PERIODS_PER_DAY - used


func periods_until_next_day() -> int:
	return PERIODS_PER_DAY - current_period


func total_periods_used() -> int:
	return (current_day - 1) * PERIODS_PER_DAY + current_period


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
	if advance:
		advance_period(1)
	location_changed.emit(loc_id)
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
func add_evidence(eid: String) -> bool:
	if collected_evidence.has(eid):
		return false
	collected_evidence.append(eid)
	_apply_transitions("evidence_obtained:" + eid)
	evidence_added.emit(eid)
	_check_day_events()
	_check_progression()
	save_game()
	return true


func add_clue(cid: String) -> bool:
	if collected_clues.has(cid):
		return false
	collected_clues.append(cid)
	_apply_transitions("clue_obtained:" + cid)
	clue_added.emit(cid)
	_check_day_events()
	_check_progression()
	save_game()
	return true


func has_clue(cid: String) -> bool:
	return collected_clues.has(cid)


func has_evidence(eid: String) -> bool:
	return collected_evidence.has(eid)


# ─── Flags / 访问记录 ───
func set_flag(flag_id: String) -> void:
	if dialogue_flags.get(flag_id, false):
		return
	dialogue_flags[flag_id] = true
	_apply_transitions("flag_set:" + flag_id)
	flag_set.emit(flag_id)
	_check_day_events()
	_check_progression()
	save_game()


func has_flag(flag_id: String) -> bool:
	return dialogue_flags.get(flag_id, false)


func mark_node_visited(npc_id: String, node_id: String) -> void:
	var key := "%s.%s" % [npc_id, node_id]
	visited_nodes[key] = visited_nodes.get(key, 0) + 1
	_apply_transitions_for_npc(npc_id, "node_visited:" + node_id)
	node_visited.emit(npc_id, node_id)
	_check_day_events()
	save_game()


func node_visit_count(npc_id: String, node_id: String) -> int:
	return visited_nodes.get("%s.%s" % [npc_id, node_id], 0)


func has_visited(npc_id: String, node_id: String) -> bool:
	return node_visit_count(npc_id, node_id) > 0


# ─── NPC 状态机 ───
func get_npc_state(npc_id: String, stat: String, default = 0):
	var state: Dictionary = npc_states.get(npc_id, {})
	return state.get(stat, default)


func set_npc_state(npc_id: String, stat: String, value) -> void:
	if not npc_states.has(npc_id):
		npc_states[npc_id] = {}
	npc_states[npc_id][stat] = value


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
##   { "day_gte": N }  / { "day_lte": N } / { "day_eq": N }
##   { "period_gte": N }
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
			return get_npc_schedule_at(loc_npc, current_day, current_period).get("location", "") == loc_id
		return false
	# NPC 当前活动条件：{ "npc_activity": { "npc": "bu_zhang", "activity": "collect_debt" } }
	if d.has("npc_activity"):
		var act_spec = d["npc_activity"]
		if typeof(act_spec) == TYPE_DICTIONARY:
			var act_npc: String = str(act_spec.get("npc", ""))
			var act_id: String = str(act_spec.get("activity", ""))
			if act_npc == "" or act_id == "":
				return false
			return get_npc_schedule_at(act_npc, current_day, current_period).get("activity", "") == act_id
		return false
	if d.has("visited"):
		var v: String = d["visited"]
		var parts := v.split(".")
		if parts.size() == 2:
			return has_visited(parts[0], parts[1])
		return false
	if d.has("day_gte"):
		return current_day >= int(d["day_gte"])
	if d.has("day_lte"):
		return current_day <= int(d["day_lte"])
	if d.has("day_eq"):
		return current_day == int(d["day_eq"])
	if d.has("period_gte"):
		return current_period >= int(d["period_gte"])
	if d.has("total_periods_used_gte"):
		return total_periods_used() >= int(d["total_periods_used_gte"])
	if d.has("total_periods_used_lte"):
		return total_periods_used() <= int(d["total_periods_used_lte"])
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
		result.narration = "你又看了一遍此处，但已没有新发现。"
		# 触发对话不论是否第一次都执行（适用于"再次约见"场景）
	save_game()
	return result


# ─── NPC ───
func get_npc_data(nid: String) -> Dictionary:
	return npcs_data.get(nid, {})


## 获取 NPC 对玩家显示的名字（考虑名字是否已解锁）
func get_npc_display_name(nid: String) -> String:
	var data: Dictionary = npcs_data.get(nid, {})
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
	for phase in progression_data.get("phases", []):
		var pid: String = phase.get("id", "")
		if pid == "" or unlocked_phases.has(pid):
			continue
		var cond = phase.get("unlock_condition", null)
		if cond == null:
			continue
		if evaluate_condition(cond):
			unlocked_phases.append(pid)
			phase_unlocked.emit(pid)
			# 发送助手引导提示
			var notifs: Dictionary = progression_data.get("phase_notifications", {})
			if notifs.has(pid):
				var n: Dictionary = notifs[pid]
				progression_hint.emit(n.get("speaker", ""), n.get("text", ""))
			save_game()


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


# ─── 日程事件 ───
func _check_day_events() -> void:
	for evt in day_events_data.get("events", []):
		var evt_id: String = evt.get("id", "")
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


func apply_event_effects(evt: Dictionary) -> void:
	var effects: Dictionary = evt.get("effects", {})
	if effects.has("set_flag"):
		var f = effects["set_flag"]
		if f is String:
			set_flag(f)
		elif f is Array:
			for x in f:
				set_flag(x)
	if effects.has("gain_clue"):
		add_clue(effects["gain_clue"])
	# 自动设置一个 evt_id_done 的 flag（与事件 trigger 中的 not flag 配对）
	var evt_id: String = evt.get("id", "")
	if evt_id != "":
		set_flag(evt_id + "_done")
	if effects.has("gain_evidence"):
		add_evidence(effects["gain_evidence"])
	if effects.has("unlock_phase"):
		var phase_id: String = effects["unlock_phase"]
		if not unlocked_phases.has(phase_id):
			unlocked_phases.append(phase_id)
			phase_unlocked.emit(phase_id)
			save_game()


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


func get_ending(ending_id: String) -> Dictionary:
	return case_data.get("endings", {}).get(ending_id, {})


# ─── NPC 调度（schedule + culprit actions）─────────────────────────────────

## "D{day}_P{period}" → 绝对时段（0-23），方便比大小与抖动
static func _to_abs_period(day: int, period: int) -> int:
	return (day - 1) * PERIODS_PER_DAY + period


static func _from_abs_period(abs_p: int) -> Vector2i:
	abs_p = max(0, abs_p)
	@warning_ignore("integer_division")
	var d: int = abs_p / PERIODS_PER_DAY + 1
	var p: int = abs_p % PERIODS_PER_DAY
	return Vector2i(d, p)


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
func _resolve_culprit_action_schedule() -> void:
	culprit_action_resolved.clear()
	if case_seed == 0:
		case_seed = int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
	var actions: Array = culprit_actions_data.get("actions", [])
	if actions.is_empty():
		return
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
		var base_abs := _to_abs_period(dp.x, dp.y)
		var delta := 0
		if jitter > 0:
			delta = rng.randi_range(-jitter, jitter)
		var final_abs: int = clamp(base_abs + delta, 0, TOTAL_DAYS * PERIODS_PER_DAY - 1)
		var v := _from_abs_period(final_abs)
		culprit_action_resolved[aid] = "D%d_P%d" % [v.x, v.y]


## 取某 NPC 在 day/period 时段的所在地与活动
## 返回 {"location": "...", "activity": "...", "public": bool} 或 {} 表示无调度
## 优先级：时段 override > conditional_override（flag 触发） > default
func get_npc_schedule_at(npc_id: String, day: int, period: int) -> Dictionary:
	var entry = schedules_data.get(npc_id, null)
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	# 1) 时段精确 override（最高优先级）
	var key := "D%d_P%d" % [day, period]
	var overrides: Dictionary = entry.get("overrides", {})
	if overrides.has(key):
		var ov = overrides[key]
		if typeof(ov) == TYPE_DICTIONARY:
			return ov
	# 2) 条件 override（flag 被设置后替换 default）
	var cond_overrides: Array = entry.get("conditional_overrides", [])
	for co in cond_overrides:
		if typeof(co) != TYPE_DICTIONARY:
			continue
		var flag: String = co.get("if_flag", "")
		if flag != "" and has_flag(flag):
			var sched = co.get("schedule", null)
			if typeof(sched) == TYPE_DICTIONARY:
				return sched
	# 3) default
	var def = entry.get("default", null)
	if typeof(def) == TYPE_DICTIONARY:
		return def
	return {}


## 取当前时段所在 location_id 的有效 NPC 列表（public=true 的才会自然出现）
## 优先用 schedule，schedule 缺失则回退到 locations.json 的静态 npcs 字段
## 会过滤渐进系统中未解锁的 NPC
func get_active_npcs_at(location_id: String, day: int = -1, period: int = -1) -> Array:
	if day < 0: day = current_day
	if period < 0: period = current_period
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
		var sched := get_npc_schedule_at(nid, day, period)
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


## 凶手动作 tick：进入某个时段时调用
##  - 若动作时段已到，投放痕迹证据（标记为"案件隐藏证据"，玩家搜索到才显形）
##  - 若玩家正在动作地点，且 public=false → 直接撞见，设置 witness flag
func _run_culprit_tick() -> void:
	var actions: Array = culprit_actions_data.get("actions", [])
	if actions.is_empty() or culprit_action_resolved.is_empty():
		return
	var now_abs := _to_abs_period(current_day, current_period)
	for a in actions:
		if typeof(a) != TYPE_DICTIONARY:
			continue
		var aid: String = a.get("id", "")
		if aid == "":
			continue
		if has_flag("culprit_action_done:" + aid):
			continue
		var resolved_key: String = culprit_action_resolved.get(aid, a.get("day_period", ""))
		var dp := _parse_dp(resolved_key)
		if dp.x < 0:
			continue
		var action_abs := _to_abs_period(dp.x, dp.y)
		if now_abs < action_abs:
			continue
		# 已到执行时段：判定玩家是否目击
		var loc: Dictionary = a.get("leaves_trace", {})
		var loc_id: String = loc.get("location", "")
		# 玩家只要在场就算"撞见"（public 动作=公开看到；private=撞破偷偷做）
		# 撞见会设置 if_witnessed flag → 触发 day_events.json 中 auto_play 遭遇剧情
		if current_location == loc_id:
			var wflag: String = a.get("if_witnessed", "")
			if wflag != "":
				set_flag(wflag)
		# 标记动作已发生（即使玩家没看见，也会留下痕迹）
		set_flag("culprit_action_done:" + aid)
		culprit_actions_witnessed[aid] = current_location == loc_id


## "重置随机种子" —— 新游戏开局时调用
func reroll_case_seed() -> void:
	case_seed = int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
	_resolve_culprit_action_schedule()


