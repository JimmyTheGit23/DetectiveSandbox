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

# 当前案件
const ACTIVE_CASE := "linchuan_inn"
const SAVE_PATH := "user://linchuan_inn_save.json"

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
	_load_data()
	_init_npc_states()


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
	current_location = "post_station"
	collected_evidence.clear()
	collected_clues.clear()
	visited_locations = ["post_station"]
	search_history.clear()
	dialogue_flags.clear()
	visited_nodes.clear()
	triggered_events.clear()
	_init_npc_states()
	save_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


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
	}
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
	current_location = data.get("current_location", "post_station")
	collected_evidence.assign(data.get("collected_evidence", []))
	collected_clues.assign(data.get("collected_clues", []))
	visited_locations.assign(data.get("visited_locations", ["post_station"]))
	search_history = data.get("search_history", {})
	dialogue_flags = data.get("dialogue_flags", {})
	visited_nodes = data.get("visited_nodes", {})
	triggered_events = data.get("triggered_events", {})
	npc_states = data.get("npc_states", {})
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
	_check_day_events()
	save_game()


func is_time_up() -> bool:
	return current_day > TOTAL_DAYS


func current_time_text() -> String:
	return "第 %d 日 · %s" % [current_day, PERIOD_NAMES[current_period]]


func remaining_periods() -> int:
	var used = (current_day - 1) * PERIODS_PER_DAY + current_period
	return TOTAL_DAYS * PERIODS_PER_DAY - used


func total_periods_used() -> int:
	return (current_day - 1) * PERIODS_PER_DAY + current_period


# ─── 地点 ───
func change_location(loc_id: String, advance: bool = true) -> void:
	if not locations_data.has(loc_id):
		push_error("Unknown location: " + loc_id)
		return
	current_location = loc_id
	if not visited_locations.has(loc_id):
		visited_locations.append(loc_id)
	if advance:
		advance_period(1)
	location_changed.emit(loc_id)
	save_game()


func get_location_data(loc_id: String) -> Dictionary:
	return locations_data.get(loc_id, {})


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
	save_game()
	return true


func add_clue(cid: String) -> bool:
	if collected_clues.has(cid):
		return false
	collected_clues.append(cid)
	_apply_transitions("clue_obtained:" + cid)
	clue_added.emit(cid)
	_check_day_events()
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
	if d.has("flag"):
		return has_flag(d["flag"])
	if d.has("not_flag"):
		return not has_flag(d["not_flag"])
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
