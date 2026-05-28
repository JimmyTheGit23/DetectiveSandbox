extends RefCounted
class_name CaseTableLoader
## 运行时 CSV 案件数据加载器。
## 目标：Godot 运行时只读取 data/case_tables/ 下的 CSV，再组装为既有运行时代码需要的 Dictionary 结构。

const TABLE_ROOT := "res://data/case_tables"
const CASE_INDEX_CSV := "res://data/case_tables/case_index.csv"

static var _case_cache: Dictionary = {}
static var _index_cache: Dictionary = {}


static func clear_cache() -> void:
	_case_cache.clear()
	_index_cache.clear()


static func case_exists(case_id: String) -> bool:
	return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("%s/%s" % [TABLE_ROOT, case_id]))


static func load_case_index() -> Dictionary:
	if not _index_cache.is_empty():
		return _index_cache.duplicate(true)
	var rows := _rows(CASE_INDEX_CSV)
	var cases: Array = []
	var default_case := ""
	for row in rows:
		var case_id := _cell(row, "id")
		if case_id == "":
			continue
		var entry := {
			"id": case_id,
			"manifest": "case_tables:%s:manifest" % case_id,
			"order": _parse_int(_cell(row, "order"), 0),
			"locked": _parse_bool(row.get("locked", false)),
			"lock_reason": _cell(row, "lock_reason"),
			"tag": _cell(row, "tag"),
			"voice_status": _cell(row, "voice_status", "full"),
			"unlock_after": _cell(row, "unlock_after"),
			"style": _cell(row, "style"),
			"category": _cell(row, "category"),
			"era": _cell(row, "era", "ancient"),
			"is_tutorial": _parse_bool(row.get("is_tutorial", false)),
			"preview_blurb": _cell(row, "preview_blurb"),
		}
		cases.append(entry)
		if _parse_bool(row.get("default", false)):
			default_case = case_id
	cases.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
	if default_case == "" and not cases.is_empty():
		default_case = cases[0].get("id", "")
	_index_cache = {
		"_comment": "Generated at runtime from data/case_tables/case_index.csv",
		"default_case": default_case,
		"cases": cases,
	}
	return _index_cache.duplicate(true)


static func load_manifest(case_id: String) -> Dictionary:
	return load_case(case_id).get("manifest", {})


static func load_dialogue(case_id: String, npc_id: String) -> Dictionary:
	return load_case(case_id).get("dialogues", {}).get(npc_id, {})


static func load_narration(case_id: String, doc_id: String = "prologue") -> Dictionary:
	return load_case(case_id).get(doc_id, {})


static func load_companion_data(case_id: String) -> Dictionary:
	var data := load_case(case_id)
	return {
		"config": data.get("companion_config", {}),
		"discussions": data.get("companion_discussions", {}),
		"banter": data.get("companion_banter", {}),
	}


static func load_case(case_id: String) -> Dictionary:
	if _case_cache.has(case_id):
		return _case_cache[case_id].duplicate(true)
	var src := "%s/%s" % [TABLE_ROOT, case_id]
	if not case_exists(case_id):
		push_error("[CaseTableLoader] case table directory not found: " + src)
		return {}

	var docs := _load_json_docs(src)
	var npcs_and_casting := _compile_characters(src, case_id)
	var data := {
		"manifest": docs.get("manifest", {}),
		"locations": _compile_locations(src),
		"npcs": npcs_and_casting.get("npcs", {}),
		"casting": npcs_and_casting.get("casting", {}),
		"evidence": _compile_evidence(src),
		"key_info": docs.get("key_info", {}),
		"search_results": _compile_search_results(src),
		"case": _compile_case_data(src, docs.get("case_base", {})),
		"day_events": _compile_day_events(src, docs.get("day_events_base", {})),
		"npc_states": _compile_npc_states(src, docs.get("npc_states_base", {})),
		"progression": _compile_progression(src, docs.get("progression_base", {})),
		"schedules": _compile_schedules(src, docs.get("schedules_base", {})),
		"culprit_actions": _compile_culprit_actions(src, docs.get("culprit_actions_base", {})),
		"portrait_expressions": _compile_portrait_expressions(src),
		"dialogues": _compile_dialogues(src, docs.get("dialogues_base", {})),
		"bgm_config": docs.get("bgm_config", {}),
		"prologue": docs.get("prologue", {}),
		"epilogue_meta": docs.get("epilogue_meta", {}),
		"companion_config": docs.get("companion_config", {}),
		"companion_discussions": docs.get("companion_discussions", {}),
		"companion_banter": docs.get("companion_banter", {}),
	}
	_case_cache[case_id] = data.duplicate(true)
	return data


# ─── CSV / DSL helpers ─────────────────────────────────────────────────────

static func _rows(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var header := Array(f.get_csv_line())
	if header.is_empty():
		return []
	if str(header[0]).begins_with("﻿"):
		header[0] = str(header[0]).substr(1)
	var out: Array = []
	while not f.eof_reached():
		var values := Array(f.get_csv_line())
		if values.is_empty():
			continue
		var has_value := false
		for v in values:
			if str(v).strip_edges() != "":
				has_value = true
				break
		if not has_value:
			continue
		if str(values[0]).strip_edges().begins_with("#"):
			continue
		var row := {}
		for i in range(header.size()):
			var key := str(header[i]).strip_edges()
			if key == "":
				continue
			row[key] = values[i] if i < values.size() else ""
		out.append(row)
	return out


static func _load_json_docs(src: String) -> Dictionary:
	var docs := {}
	for row in _rows("%s/json_docs.csv" % src):
		var doc_id := _cell(row, "doc_id")
		if doc_id == "":
			continue
		var parsed = JSON.parse_string(str(row.get("json", "")))
		if typeof(parsed) == TYPE_DICTIONARY:
			docs[doc_id] = parsed
		else:
			push_warning("[CaseTableLoader] invalid json_docs row: %s/%s" % [src, doc_id])
	return docs


static func _cell(row: Dictionary, key: String, default_value: String = "") -> String:
	var value = row.get(key, default_value)
	if value == null:
		return default_value
	return str(value).strip_edges()


static func _is_blank(value) -> bool:
	return value == null or str(value).strip_edges() == ""


static func _set_if(d: Dictionary, key: String, value) -> void:
	if value == null:
		return
	if value is String and value == "":
		return
	if value is Array and value.is_empty():
		return
	d[key] = value


static func _set_condition(d: Dictionary, key: String, value) -> void:
	if _is_blank(value):
		return
	d[key] = _parse_condition(value)


static func _set_flags_from_cell(d: Dictionary, value) -> void:
	var flags := _parse_list(value)
	if not flags.is_empty():
		d["set_flags"] = flags


static func _ensure_dict(d: Dictionary, key, default_value: Dictionary = {}) -> Dictionary:
	if not d.has(key) or typeof(d[key]) != TYPE_DICTIONARY:
		d[key] = default_value.duplicate(true)
	return d[key]


static func _ensure_array(d: Dictionary, key) -> Array:
	if not d.has(key) or typeof(d[key]) != TYPE_ARRAY:
		d[key] = []
	return d[key]


static func _append_group(d: Dictionary, key, value) -> void:
	_ensure_array(d, key).append(value)


static func _parse_bool(value, default_value: bool = false) -> bool:
	if _is_blank(value):
		return default_value
	if value is bool:
		return value
	var t := str(value).strip_edges().to_lower()
	return ["1", "true", "yes", "y", "是", "对"].has(t)


static func _parse_int(value, default_value = null):
	if _is_blank(value):
		return default_value
	return int(float(str(value).strip_edges()))


static func _parse_scalar(value):
	if _is_blank(value):
		return ""
	var text := str(value).strip_edges()
	if text.to_lower() == "true":
		return true
	if text.to_lower() == "false":
		return false
	if text.is_valid_int():
		return int(text)
	if text.is_valid_float():
		return float(text)
	return text


static func _parse_json_any(value, default_value):
	if _is_blank(value):
		return default_value
	var parsed = JSON.parse_string(str(value))
	return parsed if parsed != null else default_value


static func _parse_json_dict(value) -> Dictionary:
	var parsed = _parse_json_any(value, {})
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func _parse_list(value) -> Array:
	if _is_blank(value):
		return []
	if value is Array:
		var arr: Array = []
		for x in value:
			if str(x).strip_edges() != "":
				arr.append(str(x).strip_edges())
		return arr
	var text := str(value).strip_edges()
	if text.begins_with("["):
		var parsed = JSON.parse_string(text)
		if parsed is Array:
			var arr2: Array = []
			for x in parsed:
				if str(x).strip_edges() != "":
					arr2.append(str(x).strip_edges())
			return arr2
	var sep := ";" if text.find(";") >= 0 else ","
	var out: Array = []
	for part in _split_top_level(text, sep):
		var item := str(part).strip_edges()
		if item != "":
			out.append(item)
	return out


static func _parse_float_list(value) -> Array:
	var out: Array = []
	for x in _parse_list(value):
		out.append(float(str(x)))
	return out


static func _split_top_level(text: String, sep: String = ",") -> Array:
	var parts: Array = []
	var buf := ""
	var depth := 0
	var in_quote := false
	var quote_char := ""
	var escape := false
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		if escape:
			buf += ch
			escape = false
			continue
		if ch == "\\" and in_quote:
			buf += ch
			escape = true
			continue
		if ch == "\"" or ch == "'":
			if in_quote and ch == quote_char:
				in_quote = false
				quote_char = ""
			elif not in_quote:
				in_quote = true
				quote_char = ch
			buf += ch
			continue
		if not in_quote:
			if "([{".find(ch) >= 0:
				depth += 1
			elif ")]}".find(ch) >= 0:
				depth -= 1
			elif ch == sep and depth == 0:
				if buf.strip_edges() != "":
					parts.append(buf.strip_edges())
				buf = ""
				continue
		buf += ch
	if buf.strip_edges() != "":
		parts.append(buf.strip_edges())
	return parts


static func _parse_condition(value):
	if _is_blank(value):
		return null
	if value is Dictionary or value is Array:
		return value
	var text := str(value).strip_edges()
	if text.begins_with("{") or text.begins_with("["):
		return JSON.parse_string(text)
	if text.find(";") >= 0:
		var all_arr: Array = []
		for p in _split_top_level(text, ";"):
			all_arr.append(_parse_condition(p))
		return {"all": all_arr}
	var all_inner = _parse_call("all", text)
	if all_inner != null:
		var arr: Array = []
		for p in _split_top_level(all_inner):
			arr.append(_parse_condition(p))
		return {"all": arr}
	var any_inner = _parse_call("any", text)
	if any_inner != null:
		var arr2: Array = []
		for p in _split_top_level(any_inner):
			arr2.append(_parse_condition(p))
		return {"any": arr2}
	var not_inner = _parse_call("not", text)
	if not_inner != null:
		return {"not": _parse_condition(not_inner)}
	for item in [
		["evidence:", "evidence"], ["clue:", "clue"], ["flag:", "flag"], ["not_flag:", "not_flag"],
		["visited:", "visited"], ["location:", "location"], ["location_unlocked:", "location_unlocked"]
	]:
		if text.begins_with(item[0]):
			return {item[1]: text.substr(str(item[0]).length()).strip_edges()}
	if text == "default" or text == "default:true":
		return {"default": true}
	push_warning("[CaseTableLoader] unknown condition DSL: " + text)
	return null


static func _parse_call(name: String, text: String):
	var prefix := name + "("
	if text.begins_with(prefix) and text.ends_with(")"):
		return text.substr(prefix.length(), text.length() - prefix.length() - 1).strip_edges()
	return null


static func _sort_by_order(a: Dictionary, b: Dictionary) -> bool:
	return float(_cell(a, "order", "0")) < float(_cell(b, "order", "0"))


static func _sort_rows(rows: Array) -> void:
	rows.sort_custom(func(a, b): return _sort_by_order(a, b))


static func _line(row: Dictionary) -> Dictionary:
	var d := {"speaker": _cell(row, "speaker"), "text": _cell(row, "text")}
	for key in ["speaker_id", "emotion", "portrait_emotion", "portrait_override"]:
		_set_if(d, key, _cell(row, key))
	return d


# ─── 表格编译：基础数据 ───────────────────────────────────────────────────

static func _compile_evidence(src: String) -> Dictionary:
	var out := {"_comment": "Generated at runtime from evidence_items.csv"}
	for row in _rows("%s/evidence_items.csv" % src):
		var item_id := _cell(row, "item_id")
		if item_id == "":
			continue
		var item := {}
		_set_if(item, "type", _cell(row, "type", "evidence"))
		_set_if(item, "category", _cell(row, "category"))
		_set_if(item, "name", _cell(row, "name"))
		_set_if(item, "description", _cell(row, "description"))
		if _parse_bool(row.get("hidden", false)):
			item["hidden"] = true
		if _parse_bool(row.get("meta_clue", false)):
			item["meta_clue"] = true
		_set_if(item, "icon", _cell(row, "icon"))
		_set_if(item, "tags", _parse_list(row.get("tags", "")))
		_set_if(item, "phase", _cell(row, "phase"))
		out[item_id] = item
	return out


static func _compile_characters(src: String, case_id: String) -> Dictionary:
	var npcs := {"_comment": "Generated at runtime from characters.csv"}
	var casting := {"_comment": "Generated at runtime from characters.csv", "case_id": case_id, "casting": {}}
	for row in _rows("%s/characters.csv" % src):
		var npc_id := _cell(row, "npc_id")
		if npc_id == "":
			continue
		var n := {}
		var name := _cell(row, "name")
		var title := _cell(row, "title")
		var intro := _cell(row, "intro")
		_set_if(n, "name", name)
		_set_if(n, "title", title)
		_set_if(n, "intro", intro)
		_set_if(n, "dialogue", _cell(row, "dialogue_id", _cell(row, "dialogue")))
		_set_if(n, "portrait", _cell(row, "portrait"))
		for flag in ["always_in_notebook", "is_victim"]:
			if _parse_bool(row.get(flag, false)):
				n[flag] = true
		npcs[npc_id] = n
		var c := {}
		_set_if(c, "actor_id", _cell(row, "actor_id"))
		_set_if(c, "role_name", name)
		_set_if(c, "role_title", title)
		_set_if(c, "role_intro", intro)
		_set_if(c, "portrait", _cell(row, "portrait"))
		for flag2 in ["is_player", "is_culprit", "is_victim"]:
			if _parse_bool(row.get(flag2, false)):
				c[flag2] = true
		casting["casting"][npc_id] = c
	return {"npcs": npcs, "casting": casting}


static func _compile_locations(src: String) -> Dictionary:
	var out := {"_comment": "Generated at runtime from locations/search_points/location_links CSV"}
	for row in _rows("%s/locations.csv" % src):
		var loc_id := _cell(row, "location_id")
		if loc_id == "":
			continue
		var loc := {}
		for key in ["name", "parent", "description", "unlock_phase", "background", "scene_type"]:
			_set_if(loc, key, _cell(row, key))
		_set_if(loc, "npcs", _parse_list(row.get("npcs", "")))
		loc["search_points"] = []
		out[loc_id] = loc
	for row in _rows("%s/location_links.csv" % src):
		var from_loc := _cell(row, "from_location")
		if from_loc == "":
			continue
		if not out.has(from_loc):
			out[from_loc] = {"search_points": []}
		var link := {}
		_set_if(link, "target", _cell(row, "target_location"))
		_set_if(link, "name", _cell(row, "name"))
		_set_if(link, "description", _cell(row, "description"))
		_set_condition(link, "requires", row.get("requires", ""))
		var time_cost = _parse_int(row.get("time_cost", ""), null)
		if time_cost != null:
			link["time_cost"] = time_cost
		_ensure_array(out[from_loc], "sub_locations").append(link)
	for row in _rows("%s/search_points.csv" % src):
		var loc_id := _cell(row, "location_id")
		var point_id := _cell(row, "point_id")
		if loc_id == "" or point_id == "":
			continue
		if not out.has(loc_id):
			out[loc_id] = {"search_points": []}
		var point := {"id": point_id}
		_set_if(point, "name", _cell(row, "name"))
		var tc = _parse_int(row.get("time_cost", ""), null)
		if tc != null:
			point["time_cost"] = tc
		_set_if(point, "hint_rect", _parse_float_list(row.get("hint_rect", "")))
		_set_condition(point, "unlock_condition", row.get("unlock_condition", ""))
		_set_if(point, "locked_hint", _cell(row, "locked_hint"))
		_ensure_array(out[loc_id], "search_points").append(point)
	return out


static func _result_payload(row: Dictionary) -> Dictionary:
	var d := {}
	_set_if(d, "intro_text", _cell(row, "intro_text"))
	_set_if(d, "narration", _cell(row, "narration"))
	_set_if(d, "evidence", _cell(row, "gain_evidence", _cell(row, "evidence")))
	_set_if(d, "clue", _cell(row, "gain_clue", _cell(row, "clue")))
	_set_flags_from_cell(d, row.get("set_flags", ""))
	_set_if(d, "trigger_dialogue", _cell(row, "trigger_dialogue"))
	_set_if(d, "trigger_dialogue_start", _cell(row, "trigger_dialogue_start"))
	var time_cost = _parse_int(row.get("time_cost", ""), null)
	if time_cost != null:
		d["time_cost"] = time_cost
	return d


static func _compile_search_results(src: String) -> Dictionary:
	var out := {"_comment": "Generated at runtime from search_results/search_sub_choices CSV"}
	var sub_choices := {}
	var sub_rows := _rows("%s/search_sub_choices.csv" % src)
	_sort_rows(sub_rows)
	for row in sub_rows:
		var loc := _cell(row, "location_id")
		var point := _cell(row, "point_id")
		var variant := _cell(row, "variant_id", "default")
		if loc == "" or point == "":
			continue
		var choice := {}
		_set_if(choice, "text", _cell(row, "text"))
		_set_if(choice, "narration", _cell(row, "narration"))
		_set_if(choice, "evidence", _cell(row, "gain_evidence", _cell(row, "evidence")))
		_set_if(choice, "clue", _cell(row, "gain_clue", _cell(row, "clue")))
		_set_flags_from_cell(choice, row.get("set_flags", ""))
		_set_condition(choice, "requires", row.get("requires", ""))
		var key := "%s|%s|%s" % [loc, point, variant]
		_append_group(sub_choices, key, choice)
	for row in _rows("%s/search_results.csv" % src):
		var loc := _cell(row, "location_id")
		var point := _cell(row, "point_id")
		if loc == "" or point == "":
			continue
		var key2 := "%s.%s" % [loc, point]
		var variant := _cell(row, "variant_id", "default")
		var entry := _result_payload(row)
		var choices: Array = sub_choices.get("%s|%s|%s" % [loc, point, variant], [])
		if not choices.is_empty():
			entry["sub_choices"] = choices
		var when = row.get("when", "")
		if not _is_blank(when):
			entry["when"] = _parse_condition(when)
			_append_group(_ensure_dict(out, key2), "conditional", entry)
		else:
			_ensure_dict(out, key2)[variant] = entry
	return out


# ─── 表格编译：对话 / 对峙 ─────────────────────────────────────────────────

static func _compile_dialogues(src: String, base: Dictionary = {}) -> Dictionary:
	var node_rows := _rows("%s/dialogue_nodes.csv" % src)
	if node_rows.is_empty():
		return base.duplicate(true)
	var line_rows := _rows("%s/dialogue_lines.csv" % src)
	_sort_rows(line_rows)
	var option_rows := _rows("%s/dialogue_options.csv" % src)
	_sort_rows(option_rows)
	var lines_by_node := {}
	for row in line_rows:
		var npc_id := _cell(row, "npc_id")
		var node_id := _cell(row, "node_id")
		var text := _cell(row, "text")
		if npc_id == "" or node_id == "" or text == "":
			continue
		var line := {"text": text}
		for key in ["speaker_id", "speaker", "type", "emotion", "mood", "record_type", "record_title", "record_text", "record_id"]:
			_set_if(line, key, _cell(row, key))
		_set_if(line, "highlight", _parse_list(row.get("highlight", "")))
		_set_condition(line, "requires", row.get("requires", ""))
		_append_group(lines_by_node, "%s|%s" % [npc_id, node_id], line)
	var options_by_node := {}
	for row in option_rows:
		var npc_id := _cell(row, "npc_id")
		var node_id := _cell(row, "node_id")
		var text := _cell(row, "text")
		var goto := _cell(row, "goto")
		if npc_id == "" or node_id == "" or text == "" or goto == "":
			continue
		var opt := {"text": text, "goto": goto}
		_set_if(opt, "type", _cell(row, "type"))
		_set_condition(opt, "requires", row.get("requires", ""))
		_set_flags_from_cell(opt, row.get("set_flags", ""))
		if _parse_bool(row.get("hide_after_visit", false)):
			opt["hide_after_visit"] = true
		var min_visits = _parse_int(row.get("min_hub_visits", ""), null)
		if min_visits != null:
			opt["min_hub_visits"] = min_visits
		var cost_time = _parse_int(row.get("cost_time", ""), null)
		if cost_time != null:
			opt["cost_time"] = cost_time
		_append_group(options_by_node, "%s|%s" % [npc_id, node_id], opt)
	var dialogues := base.duplicate(true)
	var start_by_npc := {}
	for row in node_rows:
		var npc_id := _cell(row, "npc_id")
		var node_id := _cell(row, "node_id")
		if npc_id == "" or node_id == "":
			continue
		if not dialogues.has(npc_id) or typeof(dialogues[npc_id]) != TYPE_DICTIONARY:
			dialogues[npc_id] = {"_comment": "Generated at runtime from dialogue CSV", "start": node_id, "nodes": {}}
		_ensure_dict(dialogues[npc_id], "nodes")
		if _parse_bool(row.get("is_start", false)) or not start_by_npc.has(npc_id):
			start_by_npc[npc_id] = node_id
			dialogues[npc_id]["start"] = node_id
		var node := _ensure_dict(dialogues[npc_id]["nodes"], node_id).duplicate(true)
		for key in ["text", "emotion"]:
			_set_if(node, key, _cell(row, key))
		_set_flags_from_cell(node, row.get("set_flags", ""))
		_set_if(node, "gain_evidence", _cell(row, "gain_evidence"))
		_set_if(node, "gain_clue", _cell(row, "gain_clue"))
		if _parse_bool(row.get("trigger_confrontation", false)):
			node["trigger_confrontation"] = true
		_set_if(node, "confrontation_key", _cell(row, "confrontation_key"))
		if _parse_bool(row.get("end", false)):
			node["end"] = true
		var node_key := "%s|%s" % [npc_id, node_id]
		_set_if(node, "lines", lines_by_node.get(node_key, []))
		_set_if(node, "options", options_by_node.get(node_key, []))
		dialogues[npc_id]["nodes"][node_id] = node
	return dialogues


static func _compile_case_data(src: String, base: Dictionary = {}) -> Dictionary:
	var out := base.duplicate(true)
	var confrontation_rows := _rows("%s/confrontations.csv" % src)
	if confrontation_rows.is_empty():
		return out
	var confrontation_lines := _rows("%s/confrontation_lines.csv" % src)
	_sort_rows(confrontation_lines)
	var testimony_rows := _rows("%s/testimony_sets.csv" % src)
	_sort_rows(testimony_rows)
	var testimony_lines := _rows("%s/testimony_lines.csv" % src)
	_sort_rows(testimony_lines)
	var statement_rows := _rows("%s/testimony_statements.csv" % src)
	_sort_rows(statement_rows)
	var press_rows := _rows("%s/testimony_press_lines.csv" % src)
	_sort_rows(press_rows)
	var break_rows := _rows("%s/testimony_break_lines.csv" % src)
	_sort_rows(break_rows)
	var wrong_rows := _rows("%s/testimony_wrong_reactions.csv" % src)
	_sort_rows(wrong_rows)

	var confrontation_lines_by_key := {}
	for row in confrontation_lines:
		_append_group(confrontation_lines_by_key, "%s|%s" % [_cell(row, "confrontation_id"), _cell(row, "section")], row)
	var testimony_lines_by_key := {}
	for row in testimony_lines:
		_append_group(testimony_lines_by_key, "%s|%s" % [_cell(row, "testimony_id"), _cell(row, "section")], row)
	var press_by_statement := {}
	for row in press_rows:
		_append_group(press_by_statement, _cell(row, "statement_id"), _line(row))
	var break_by_statement := {}
	for row in break_rows:
		_append_group(break_by_statement, _cell(row, "statement_id"), _line(row))
	var wrong_by_statement := {}
	for row in wrong_rows:
		var sid := _cell(row, "statement_id")
		var evid := _cell(row, "evidence_id")
		_append_group(_ensure_dict(wrong_by_statement, sid), evid, _line(row))
	var statements_by_testimony := {}
	var add_rows: Array = []
	for row in statement_rows:
		if _cell(row, "press_add_trigger") != "":
			add_rows.append(row)
		else:
			_append_group(statements_by_testimony, _cell(row, "testimony_id"), row)
	var statement_objects := {}
	for row in statement_rows:
		var stmt := _compile_statement(row, press_by_statement, break_by_statement, wrong_by_statement)
		if stmt.get("id", "") != "":
			statement_objects[stmt["id"]] = stmt
	for row in add_rows:
		var parent = statement_objects.get(_cell(row, "press_add_trigger"), null)
		var add_stmt = statement_objects.get(_cell(row, "statement_id"), null)
		if parent is Dictionary and add_stmt is Dictionary:
			parent["press_adds"] = {"after": _cell(row, "press_add_after", _cell(row, "press_add_trigger")), "statement": add_stmt}
	var testimonies_by_confrontation := {}
	for row in testimony_rows:
		var testimony_id := _cell(row, "testimony_id")
		var testimony := {}
		_set_if(testimony, "id", testimony_id)
		_set_if(testimony, "witness", _cell(row, "witness"))
		_set_if(testimony, "title", _cell(row, "title"))
		for section in ["preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
			var lines: Array = []
			for x in testimony_lines_by_key.get("%s|%s" % [testimony_id, section], []):
				lines.append(_line(x))
			_set_if(testimony, section, lines)
		var statements: Array = []
		for stmt_row in statements_by_testimony.get(testimony_id, []):
			var stmt = statement_objects.get(_cell(stmt_row, "statement_id"), null)
			if stmt is Dictionary:
				statements.append(stmt)
		testimony["statements"] = statements
		_append_group(testimonies_by_confrontation, _cell(row, "confrontation_id"), testimony)
	for row in confrontation_rows:
		var confrontation_id := _cell(row, "confrontation_id")
		if confrontation_id == "":
			continue
		var data := {}
		_set_if(data, "_comment", _cell(row, "writer_note"))
		_set_if(data, "suspect", _cell(row, "suspect"))
		if not _is_blank(row.get("is_final", "")):
			data["is_final"] = _parse_bool(row.get("is_final", false))
		for key in ["background", "bgm", "bgm_break", "bgm_final_round"]:
			_set_if(data, key, _cell(row, key))
		var confidence = _parse_int(row.get("confidence", ""), null)
		if confidence != null:
			data["confidence"] = confidence
		for section in ["intro_dialogue", "victory_dialogue", "defeat_dialogue"]:
			var lines: Array = []
			for x in confrontation_lines_by_key.get("%s|%s" % [confrontation_id, section], []):
				lines.append(_line(x))
			_set_if(data, section, lines)
		var epilogue: Array = []
		for x in confrontation_lines_by_key.get("%s|epilogue_text" % confrontation_id, []):
			var t := _cell(x, "text")
			if t != "":
				epilogue.append(t)
		_set_if(data, "epilogue_text", epilogue)
		data["testimonies"] = testimonies_by_confrontation.get(confrontation_id, [])
		out[confrontation_id] = data
	return out


static func _compile_statement(row: Dictionary, press_by_statement: Dictionary, break_by_statement: Dictionary, wrong_by_statement: Dictionary) -> Dictionary:
	var statement_id := _cell(row, "statement_id")
	var stmt := {}
	_set_if(stmt, "id", statement_id)
	_set_if(stmt, "speaker", _cell(row, "speaker"))
	for key in ["speaker_id", "emotion", "portrait_emotion", "portrait_override"]:
		_set_if(stmt, key, _cell(row, key))
	_set_if(stmt, "text", _cell(row, "text"))
	if not _is_blank(row.get("is_contradiction", "")):
		stmt["is_contradiction"] = _parse_bool(row.get("is_contradiction", false))
	_set_if(stmt, "counter_evidence", _cell(row, "counter_evidence"))
	if not _is_blank(row.get("alt_evidence", "")):
		stmt["alt_evidence"] = _parse_list(row.get("alt_evidence", ""))
	_set_if(stmt, "break_evidence", _cell(row, "break_evidence"))
	_set_if(stmt, "press", press_by_statement.get(statement_id, []))
	_set_if(stmt, "break_dialogue", break_by_statement.get(statement_id, []))
	var wrong = wrong_by_statement.get(statement_id, {})
	if wrong is Dictionary and not wrong.is_empty():
		stmt["wrong_reactions"] = wrong
	return stmt


# ─── 表格编译：进度 / 时间 / 资产 ───────────────────────────────────────────

static func _compile_progression(src: String, base: Dictionary = {}) -> Dictionary:
	var out := base.duplicate(true)
	var phase_rows := _rows("%s/progression_phases.csv" % src)
	_sort_rows(phase_rows)
	if not phase_rows.is_empty():
		var phases: Array = []
		for row in phase_rows:
			var phase := {}
			_set_if(phase, "id", _cell(row, "phase_id"))
			_set_if(phase, "title", _cell(row, "title"))
			_set_if(phase, "description", _cell(row, "description"))
			_set_if(phase, "hint", _cell(row, "hint"))
			phase["locations"] = _parse_list(row.get("locations", ""))
			phase["unlock_condition"] = null if _is_blank(row.get("unlock_condition", "")) else _parse_condition(row.get("unlock_condition", ""))
			_set_if(phase, "_comment", _cell(row, "writer_note"))
			phases.append(phase)
		out["phases"] = phases
	var unlock_rows := _rows("%s/progression_unlocks.csv" % src)
	if not unlock_rows.is_empty() or FileAccess.file_exists("%s/progression_unlocks.csv" % src):
		var grouped := {"panel_unlock": {}, "search_point_unlock": {}, "npc_unlock": {}, "confrontation_unlock": {}}
		for row in unlock_rows:
			var group := _cell(row, "unlock_type")
			var target := _cell(row, "target_id")
			if not grouped.has(group) or target == "":
				continue
			var entry := {}
			entry["condition"] = null if _is_blank(row.get("condition", "")) else _parse_condition(row.get("condition", ""))
			_set_if(entry, "locked_hint", _cell(row, "locked_hint"))
			_set_if(entry, "_comment", _cell(row, "writer_note"))
			grouped[group][target] = entry
		for group in grouped.keys():
			out[group] = grouped[group]
	var notification_rows := _rows("%s/phase_notifications.csv" % src)
	if not notification_rows.is_empty() or FileAccess.file_exists("%s/phase_notifications.csv" % src):
		var notifications := {}
		for row in notification_rows:
			var phase_id := _cell(row, "phase_id")
			if phase_id != "":
				notifications[phase_id] = {"speaker": _cell(row, "speaker"), "text": _cell(row, "text")}
		out["phase_notifications"] = notifications
	return out


static func _compile_npc_states(src: String, base: Dictionary = {}) -> Dictionary:
	var out := {}
	_set_if(out, "_comment", base.get("_comment", ""))
	var npc_order: Array = []
	for row in _rows("%s/npc_state_initial.csv" % src) + _rows("%s/npc_state_transitions.csv" % src):
		var npc_id := _cell(row, "npc_id")
		if npc_id != "" and not npc_order.has(npc_id):
			npc_order.append(npc_id)
	for npc_id in npc_order:
		out[npc_id] = {"initial": {}, "transitions": []}
	for row in _rows("%s/npc_state_initial.csv" % src):
		var npc_id := _cell(row, "npc_id")
		var stat := _cell(row, "stat")
		if npc_id == "" or stat == "":
			continue
		_ensure_dict(out, npc_id, {"initial": {}, "transitions": []})
		out[npc_id]["initial"][stat] = _parse_scalar(row.get("value", ""))
	var transitions := _rows("%s/npc_state_transitions.csv" % src)
	_sort_rows(transitions)
	for row in transitions:
		var npc_id := _cell(row, "npc_id")
		var event := _cell(row, "event")
		if npc_id == "" or event == "":
			continue
		var transition := {"on": event, "delta": _parse_json_dict(row.get("delta", "{}"))}
		_set_if(transition, "_comment", _cell(row, "writer_note"))
		_ensure_dict(out, npc_id, {"initial": {}, "transitions": []})
		out[npc_id]["transitions"].append(transition)
	return out


static func _compile_day_events(src: String, base: Dictionary = {}) -> Dictionary:
	var lines_by_event := {}
	var line_rows := _rows("%s/day_event_lines.csv" % src)
	_sort_rows(line_rows)
	for row in line_rows:
		_append_group(lines_by_event, _cell(row, "event_id"), row)
	var event_rows := _rows("%s/day_events.csv" % src)
	_sort_rows(event_rows)
	var events: Array = []
	for row in event_rows:
		var event_id := _cell(row, "event_id")
		if event_id == "":
			continue
		var evt := {"id": event_id}
		_set_if(evt, "title", _cell(row, "title"))
		_set_if(evt, "hint", _cell(row, "hint"))
		evt["trigger"] = _parse_json_any(row.get("trigger", ""), {})
		var narration: Array = []
		for line in lines_by_event.get(event_id, []):
			if _cell(line, "line_kind") == "text":
				narration.append(_cell(line, "text"))
			else:
				var item := {"speaker": _cell(line, "speaker"), "text": _cell(line, "text")}
				_set_if(item, "emotion", _cell(line, "emotion"))
				_set_if(item, "voice_path", _cell(line, "voice_path"))
				narration.append(item)
		evt["narration"] = narration
		evt["effects"] = _parse_json_any(row.get("effects", ""), {})
		if not _is_blank(row.get("auto_play", "")):
			evt["auto_play"] = _parse_bool(row.get("auto_play", false))
		_set_if(evt, "_comment", _cell(row, "writer_note"))
		events.append(evt)
	var out := {}
	_set_if(out, "_comment", base.get("_comment", ""))
	out["events"] = events
	return out


static func _schedule_from_row(row: Dictionary) -> Dictionary:
	var sched := {}
	_set_if(sched, "location", _cell(row, "location"))
	_set_if(sched, "activity", _cell(row, "activity"))
	if not _is_blank(row.get("public", "")):
		sched["public"] = _parse_bool(row.get("public", false))
	return sched


static func _compile_schedules(src: String, base: Dictionary = {}) -> Dictionary:
	var out := {}
	_set_if(out, "_comment", base.get("_comment", ""))
	for row in _rows("%s/schedule_defaults.csv" % src):
		var npc_id := _cell(row, "npc_id")
		if npc_id == "":
			continue
		var entry := {}
		_set_if(entry, "_role", _cell(row, "role_note"))
		var default_sched := _schedule_from_row(row)
		if not default_sched.is_empty():
			entry["default"] = default_sched
		out[npc_id] = entry
	for row in _rows("%s/schedule_overrides.csv" % src):
		var npc_id := _cell(row, "npc_id")
		var time_key := _cell(row, "time_key")
		if npc_id == "" or time_key == "":
			continue
		_ensure_dict(_ensure_dict(out, npc_id), "overrides")[time_key] = _schedule_from_row(row)
	var conditional_rows := _rows("%s/schedule_conditional_overrides.csv" % src)
	_sort_rows(conditional_rows)
	for row in conditional_rows:
		var npc_id := _cell(row, "npc_id")
		var if_flag := _cell(row, "if_flag")
		if npc_id == "" or if_flag == "":
			continue
		_ensure_array(_ensure_dict(out, npc_id), "conditional_overrides").append({"if_flag": if_flag, "schedule": _schedule_from_row(row)})
	return out


static func _compile_culprit_actions(src: String, base: Dictionary = {}) -> Dictionary:
	var action_rows := _rows("%s/culprit_actions.csv" % src)
	_sort_rows(action_rows)
	var actions: Array = []
	for row in action_rows:
		var action_id := _cell(row, "action_id")
		if action_id == "":
			continue
		var action := {"id": action_id}
		_set_if(action, "culprit", _cell(row, "culprit"))
		_set_if(action, "day_period", _cell(row, "day_period"))
		var jitter = _parse_int(row.get("jitter", ""), null)
		if jitter != null:
			action["jitter"] = jitter
		_set_if(action, "intent", _cell(row, "intent"))
		var trace := {}
		_set_if(trace, "evidence_id", _cell(row, "trace_evidence_id"))
		_set_if(trace, "location", _cell(row, "trace_location"))
		_set_if(trace, "discoverable_after", _cell(row, "trace_discoverable_after"))
		if not trace.is_empty():
			action["leaves_trace"] = trace
		_set_if(action, "if_witnessed", _cell(row, "if_witnessed"))
		_set_if(action, "_comment", _cell(row, "writer_note"))
		actions.append(action)
	var out := {}
	_set_if(out, "_comment", base.get("_comment", ""))
	out["actions"] = actions
	return out


static func _compile_portrait_expressions(src: String) -> Dictionary:
	var portraits := {}
	for row in _rows("%s/portrait_expressions.csv" % src):
		var base := _cell(row, "base_portrait")
		var emotion := _cell(row, "emotion")
		var portrait := _cell(row, "portrait")
		if base == "" or emotion == "" or portrait == "":
			continue
		_ensure_dict(portraits, base)[emotion] = portrait
	return {"_comment": "Generated at runtime from portrait_expressions.csv", "portraits": portraits}


