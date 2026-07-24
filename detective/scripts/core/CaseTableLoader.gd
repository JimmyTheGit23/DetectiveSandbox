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


## 案件流程骨架定义（json_docs.csv 中 doc_id="flow"，无则返回空）
static func load_flow(case_id: String) -> Dictionary:
	return load_case(case_id).get("flow", {})


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
		"manifest": _compile_manifest(src, docs.get("manifest", {})),
		"locations": _compile_locations(src),
		"npcs": npcs_and_casting.get("npcs", {}),
		"casting": npcs_and_casting.get("casting", {}),
		"center_npc_layouts": _compile_center_npc_layouts(src),
		"evidence": _compile_evidence(src),
		"key_info": docs.get("key_info", {}),
		"search_results": _compile_search_results(src),
		"case": _compile_case_data(src),
		"day_events": _compile_day_events(src),
		"npc_states": _compile_npc_states(src),
		"progression": _compile_progression(src),
		"time_progression": _compile_time_progression(src),
		"schedules": _compile_schedules(src),
		"culprit_actions": _compile_culprit_actions(src),
		"portrait_expressions": _compile_portrait_expressions(src),
		"dialogues": _compile_dialogues(src),
		"bgm_config": docs.get("bgm_config", {}),
		"prologue": _compile_prologue(src),
		"epilogue_meta": _compile_epilogue_meta(src, docs.get("epilogue_meta", {})),
		"companion_config": _compile_companion_config(src),
		"companion_discussions": _compile_companion_discussions(src),
		"companion_banter": _compile_companion_banter(src),
		"flow": docs.get("flow", {}),
		"gm_presets": docs.get("gm_presets", {}),
		"map_config": docs.get("map_config", {}),
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


static func _parse_float(value, default_value: float = 0.0) -> float:
	if _is_blank(value):
		return default_value
	return float(str(value).strip_edges())


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
	# 允许字符串"null"作为空值处理
	if text.to_lower() == "null":
		return null
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


static func _order_sort_value(row: Dictionary) -> float:
	var text := _cell(row, "order", "0").strip_edges()
	if text == "":
		return 0.0
	if text.is_valid_float():
		return float(text)
	var number_text := ""
	var suffix := ""
	var suffix_started := false
	var sign_allowed := true
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		if not suffix_started:
			if (ch == "-" or ch == "+") and sign_allowed:
				number_text += ch
				sign_allowed = false
			elif ch >= "0" and ch <= "9":
				number_text += ch
				sign_allowed = false
			elif ch == ".":
				number_text += ch
				sign_allowed = false
			else:
				suffix_started = true
				suffix += ch
		else:
			suffix += ch
	if number_text == "" or number_text == "-" or number_text == "+" or number_text == ".":
		return 0.0
	var value := float(number_text)
	var offset := 0.0
	var divisor := 100.0
	var lower_suffix := suffix.to_lower()
	for i in range(lower_suffix.length()):
		var code := lower_suffix.unicode_at(i)
		if code >= 97 and code <= 122:
			offset += float(code - 96) / divisor
			divisor *= 100.0
	return value + offset


static func _sort_by_order(a: Dictionary, b: Dictionary) -> bool:
	return _order_sort_value(a) < _order_sort_value(b)


static func _sort_rows(rows: Array) -> void:
	rows.sort_custom(func(a, b): return _sort_by_order(a, b))


static func _line(row: Dictionary) -> Dictionary:
	var d := {"speaker": _cell(row, "speaker"), "text": _cell(row, "text")}
	for key in ["speaker_id", "emotion", "portrait_emotion", "portrait_override"]:
		_set_if(d, key, _cell(row, key))
	# 方案B：对峙台词可携带 effect（如 gain_evidence / gain_clue / set_flag），
	# 由角色在对峙过程中"当庭抛出"证据/线索。
	var effect_str := _cell(row, "effect")
	if effect_str != "":
		var eff = _parse_json_any(effect_str, {})
		if typeof(eff) == TYPE_DICTIONARY and not eff.is_empty():
			# speaker_id 可能临时写在 effect JSON 里（如 day_event_lines 无独立列）
			if eff.has("speaker_id") and not d.has("speaker_id"):
				d["speaker_id"] = str(eff["speaker_id"])
			var clean_eff: Dictionary = eff.duplicate()
			clean_eff.erase("speaker_id")
			if not clean_eff.is_empty():
				d["effect"] = clean_eff
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
		for key in ["speaker_id", "speaker", "type", "emotion", "mood", "portrait_emotion", "portrait_override", "record_type", "record_title", "record_text", "record_id"]:
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
	for meta_row in _rows("%s/case_meta.csv" % src):
		var meta_key := _cell(meta_row, "key")
		var meta_value := _cell(meta_row, "value")
		if meta_key == "":
			continue
		if meta_value.begins_with("{") or meta_value.begins_with("["):
			out[meta_key] = _parse_json_any(meta_value, meta_value)
		else:
			out[meta_key] = _parse_scalar(meta_value)
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
		_set_if(testimony, "grant_evidence", _cell(row, "grant_evidence"))
		for key in ["mode", "proof_statement_id", "proof_evidence", "proof_prompt"]:
			_set_if(testimony, key, _cell(row, key))
		if not _is_blank(row.get("proof_alt_evidence", "")):
			testimony["proof_alt_evidence"] = _parse_list(row.get("proof_alt_evidence", ""))
		if not _is_blank(row.get("skip_title_card", "")):
			testimony["skip_title_card"] = _parse_bool(row.get("skip_title_card", false))
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
		for key in ["background", "bgm", "bgm_break", "bgm_break_actual", "bgm_final_round", "verdict_text"]:
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


static func _compile_time_progression(src: String) -> Array:
	var out: Array = []
	for row in _rows("%s/time_progression.csv" % src):
		var entry := {}
		entry["order"] = _parse_int(row.get("order", ""), 99)
		entry["trigger_condition"] = _parse_condition(row.get("trigger_condition", ""))
		entry["day"] = _parse_int(row.get("day", ""), 1)
		entry["period_label"] = _cell(row, "period_label", "辰时")
		out.append(entry)
	out.sort_custom(func(a, b): return int(a.get("order", 99)) < int(b.get("order", 99)))
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
				var text_item := {"speaker": "", "text": _cell(line, "text")}
				_set_if(text_item, "background", _cell(line, "background"))
				_set_if(text_item, "voice_path", _cell(line, "voice_path"))
				var text_effect = _parse_json_any(line.get("effect", ""), {})
				if typeof(text_effect) == TYPE_DICTIONARY and not text_effect.is_empty():
					text_item["effect"] = text_effect
				if text_item.has("background") or text_item.has("voice_path") or text_item.has("effect"):
					narration.append(text_item)
				else:
					narration.append(_cell(line, "text"))
			else:
				var item := {"speaker": _cell(line, "speaker"), "text": _cell(line, "text")}
				_set_if(item, "speaker_id", _cell(line, "speaker_id"))
				_set_if(item, "emotion", _cell(line, "emotion"))
				_set_if(item, "voice_path", _cell(line, "voice_path"))
				_set_if(item, "background", _cell(line, "background"))
				var line_effect = _parse_json_any(line.get("effect", ""), {})
				if typeof(line_effect) == TYPE_DICTIONARY and not line_effect.is_empty():
					# speaker_id 可能临时写在 effect JSON 里（day_event_lines 无独立列）
					# 提升到顶层，供 _emit_adhoc 的立绘解析使用
					if line_effect.has("speaker_id") and not item.has("speaker_id"):
						item["speaker_id"] = str(line_effect["speaker_id"])
					var effect_without_sid: Dictionary = line_effect.duplicate()
					effect_without_sid.erase("speaker_id")
					if not effect_without_sid.is_empty():
						item["effect"] = effect_without_sid
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
	var portrait_meta := {}
	for row in _rows("%s/portrait_expressions.csv" % src):
		var base := _cell(row, "base_portrait")
		var emotion := _cell(row, "emotion")
		var portrait := _cell(row, "portrait")
		if base == "" or emotion == "" or portrait == "":
			continue
		_ensure_dict(portraits, base)[emotion] = portrait
		# 对话立绘缩放校正元数据（旧规格立绘按脸部比例校正；screen_scale 默认 1.0、pivot_y 默认 330）
		var scale = _parse_float(row.get("screen_scale", ""), 1.0)
		var pivot = _parse_float(row.get("pivot_y", ""), 330.0)
		if scale != 1.0 or pivot != 330.0:
			portrait_meta[portrait.get_file()] = {"screen_scale": scale, "pivot_y": pivot}
	return {"_comment": "Generated at runtime from portrait_expressions.csv", "portraits": portraits, "portrait_meta": portrait_meta}


static func _compile_center_npc_layouts(src: String) -> Dictionary:
	var by_npc := {}
	var by_portrait := {}
	for row in _rows("%s/center_npc_layouts.csv" % src):
		var npc_id := _cell(row, "npc_id")
		var emotion := _cell(row, "emotion", "base")
		var portrait := _cell(row, "portrait")
		if npc_id == "" or portrait == "":
			continue
		var npc_entry := _ensure_dict(by_npc, npc_id)
		if row.has("enabled") and not _is_blank(row.get("enabled")):
			npc_entry["enabled"] = _parse_bool(row.get("enabled", true), true)
		var cfg := {
			"npc_id": npc_id,
			"emotion": emotion,
			"portrait": portrait,
			"screen_scale": _parse_float(row.get("screen_scale", 1.0), 1.0),
			"offset_y": _parse_float(row.get("offset_y", 0.0), 0.0),
			"pivot_y": _parse_float(row.get("pivot_y", 330.0), 330.0),
			"confrontation_screen_scale": _parse_float(
				row.get("confrontation_screen_scale", row.get("screen_scale", 1.0)),
				_parse_float(row.get("screen_scale", 1.0), 1.0)
			),
			"confrontation_offset_y": _parse_float(
				row.get("confrontation_offset_y", row.get("offset_y", 0.0)),
				_parse_float(row.get("offset_y", 0.0), 0.0)
			),
		}
		_ensure_dict(npc_entry, "emotions")[emotion] = cfg
		by_portrait[portrait] = cfg
	return {
		"_comment": "Generated at runtime from center_npc_layouts.csv",
		"by_npc": by_npc,
		"by_portrait": by_portrait,
	}


# ─── 表格编译：序章 / 尾声 / 伙伴系统 ───────────────────────────────────────

static func _compile_prologue(src: String, fallback: Dictionary = {}) -> Dictionary:
	var node_rows := _rows("%s/prologue_nodes.csv" % src)
	if node_rows.is_empty():
		return fallback.duplicate(true)
	var line_rows := _rows("%s/prologue_lines.csv" % src)
	var choice_rows := _rows("%s/prologue_choices.csv" % src)
	var lines_by_node := {}
	for row in line_rows:
		var nid := _cell(row, "node_id")
		if nid == "":
			continue
		_append_group(lines_by_node, nid, row)
	var choices_by_node := {}
	for row in choice_rows:
		var nid := _cell(row, "node_id")
		if nid == "":
			continue
		_append_group(choices_by_node, nid, row)
	var nodes := {}
	var start_node := ""
	for row in node_rows:
		var nid := _cell(row, "node_id")
		if nid == "":
			continue
		if start_node == "":
			start_node = nid
		var node := {}
		_set_if(node, "background", _cell(row, "background"))
		_set_if(node, "next", _cell(row, "next"))
		if _parse_bool(row.get("centered", false)):
			node["centered"] = true
		if _parse_bool(row.get("end", false)):
			node["end"] = true
		_set_if(node, "portrait", _cell(row, "portrait"))
		_set_if(node, "emotion", _cell(row, "emotion"))
		var fx_str := _cell(row, "fx")
		if fx_str != "":
			node["fx"] = _parse_json_any(fx_str, {})
		var effect_str := _cell(row, "effect")
		if effect_str != "":
			node["effect"] = _parse_json_any(effect_str, {})
		var node_type := _cell(row, "type")
		if node_type != "":
			node["type"] = node_type
		_set_if(node, "video", _cell(row, "video"))
		# Lines (text)
		var nlines: Array = lines_by_node.get(nid, [])
		if not nlines.is_empty():
			var first_line: Dictionary = nlines[0]
			_set_if(node, "speaker", _cell(first_line, "speaker"))
			_set_if(node, "text", _cell(first_line, "text"))
			# 若 prologue_lines 的行有 type（如 inner_thought），且 node 尚无 type，则继承
			var line_type := _cell(first_line, "type")
			if line_type != "" and not node.has("type"):
				node["type"] = line_type
			# 若 prologue_lines 的行有 emotion，且 node 尚无 emotion，则继承
			var line_emotion := _cell(first_line, "emotion")
			if line_emotion != "" and not node.has("emotion"):
				node["emotion"] = line_emotion
		# Choices
		var nchoices: Array = choices_by_node.get(nid, [])
		if not nchoices.is_empty():
			var c_arr: Array = []
			for crow in nchoices:
				var c := {"text": _cell(crow, "text"), "goto": _cell(crow, "goto")}
				var req_str := _cell(crow, "requires")
				if req_str != "":
					c["requires"] = _parse_json_any(req_str, {})
				c_arr.append(c)
			node["choices"] = c_arr
		nodes[nid] = node
	# Preserve start metadata from fallback
	var out := {}
	_set_if(out, "_comment", fallback.get("_comment", ""))
	_set_if(out, "_design_note", fallback.get("_design_note", ""))
	out["start"] = fallback.get("start", start_node)
	out["nodes"] = nodes
	return out


static func _compile_epilogue_meta(src: String, fallback: Dictionary = {}) -> Dictionary:
	var scene_rows := _rows("%s/epilogue_scenes.csv" % src)
	if scene_rows.is_empty():
		return fallback.duplicate(true)
	var line_rows := _rows("%s/epilogue_lines.csv" % src)
	var lines_by_scene := {}
	for row in line_rows:
		var sid := _cell(row, "scene_id")
		if sid == "":
			continue
		_append_group(lines_by_scene, sid, row)
	var scenes: Array = []
	for srow in scene_rows:
		var sid := _cell(srow, "scene_id")
		if sid == "":
			continue
		var scene := {}
		_set_if(scene, "id", sid)
		_set_if(scene, "type", _cell(srow, "type"))
		_set_if(scene, "background", _cell(srow, "background"))
		_set_if(scene, "bgm", _cell(srow, "bgm"))
		var slines: Array = []
		for lr in lines_by_scene.get(sid, []):
			slines.append({"speaker": _cell(lr, "speaker"), "text": _cell(lr, "text")})
		if not slines.is_empty():
			scene["lines"] = slines
		scenes.append(scene)
	var out := {}
	_set_if(out, "_comment", fallback.get("_comment", ""))
	var trigger_endings: Array = fallback.get("trigger_endings", [])
	if trigger_endings.is_empty():
		trigger_endings = ["perfect", "good", "partial"]
	out["trigger_endings"] = trigger_endings
	out["scenes"] = scenes
	return out


static func _compile_companion_discussions(src: String, fallback: Dictionary = {}) -> Dictionary:
	var rows := _rows("%s/companion_discussions.csv" % src)
	if rows.is_empty():
		return fallback.duplicate(true)
	var out := {}
	for row in rows:
		var topic_id := _cell(row, "topic_id")
		if topic_id == "":
			continue
		if not out.has(topic_id):
			out[topic_id] = {"rules": []}
		var rule := {}
		var when_str := _cell(row, "when")
		if when_str != "":
			rule["when"] = _parse_json_any(when_str, {})
		var lines_str := _cell(row, "lines")
		if lines_str != "":
			rule["lines"] = _parse_json_any(lines_str, [])
		if _parse_bool(row.get("once", false)):
			rule["once"] = true
		var priority = _parse_int(row.get("priority", ""), null)
		if priority != null:
			rule["priority"] = priority
		# Check for pool-style (chitchat) with default:true when
		var when_dict = rule.get("when", {})
		if when_dict is Dictionary and when_dict.get("default", false):
			var lines_arr = rule.get("lines", [])
			if lines_arr is Array and not lines_arr.is_empty() and out[topic_id]["rules"].is_empty():
				out[topic_id]["pool"] = lines_arr
				continue
		out[topic_id]["rules"].append(rule)
	# Preserve _comment keys from fallback
	for topic_id in fallback.keys():
		if topic_id.begins_with("_"):
			if not out.has(topic_id):
				out[topic_id] = fallback[topic_id]
	return out


static func _compile_companion_banter(src: String, fallback: Dictionary = {}) -> Dictionary:
	var rows := _rows("%s/companion_banter.csv" % src)
	if rows.is_empty():
		return fallback.duplicate(true)
	var rules: Array = []
	for row in rows:
		var rule := {}
		_set_if(rule, "id", _cell(row, "banter_id"))
		var when_str := _cell(row, "when")
		if when_str != "":
			rule["when"] = _parse_json_any(when_str, {})
		var req_str := _cell(row, "requires")
		if req_str != "":
			rule["requires"] = _parse_json_any(req_str, {})
		var lines_str := _cell(row, "lines")
		if lines_str != "":
			rule["lines"] = _parse_json_any(lines_str, [])
		var effect_str := _cell(row, "effect")
		if effect_str != "":
			rule["effect"] = _parse_json_any(effect_str, {})
		if _parse_bool(row.get("once", false)):
			rule["once"] = true
		var priority = _parse_int(row.get("priority", ""), null)
		if priority != null:
			rule["priority"] = priority
		rules.append(rule)
	return {"_comment": fallback.get("_comment", "Generated at runtime from companion_banter.csv"), "rules": rules}


# ─── 表格编译：manifest / companion_config ─────────────────────────────────

static func _compile_manifest(src: String, fallback: Dictionary = {}) -> Dictionary:
	var rows := _rows("%s/case_info.csv" % src)
	if rows.is_empty():
		return fallback.duplicate(true)
	var row: Dictionary = rows[0]
	var out := {}
	for key in ["id", "title", "subtitle", "order", "difficulty", "estimated_days", "max_days",
			"main_scene", "preview_image", "synopsis", "intro", "era", "locale",
			"companion", "voice_status"]:
		_set_if(out, key, _cell(row, key))
	if _parse_bool(row.get("is_tutorial", false)):
		out["is_tutorial"] = true
	for key in ["scenes", "files", "directories", "rewards"]:
		var val := _cell(row, key)
		if val != "":
			out[key] = _parse_json_any(val, {})
	# Preserve legacy file references for compatibility
	if not out.has("scenes"):
		out["scenes"] = fallback.get("scenes", {})
	if not out.has("files"):
		out["files"] = fallback.get("files", {})
	return out


static func _compile_companion_config(src: String) -> Dictionary:
	var rows := _rows("%s/companion_config.csv" % src)
	if rows.is_empty():
		return {}
	var row: Dictionary = rows[0]
	var out := {}
	_set_if(out, "companion_id", _cell(row, "companion_id"))
	_set_if(out, "role_name", _cell(row, "role_name"))
	_set_if(out, "actor_id", _cell(row, "actor_id"))
	_set_if(out, "intro_hint", _cell(row, "intro_hint"))
	_set_if(out, "banter_suppress_until_flag", _cell(row, "banter_suppress_until_flag"))
	if _parse_bool(row.get("tutorial_mode", false)):
		out["tutorial_mode"] = true
	if _parse_bool(row.get("lock_on_final_day", false)):
		out["lock_on_final_day"] = true
	var bmp = _parse_int(row.get("banter_max_per_day", ""), null)
	if bmp != null:
		out["banter_max_per_day"] = bmp
	var topics_str := _cell(row, "available_topics")
	if topics_str != "":
		out["available_topics"] = _parse_json_any(topics_str, [])
	var limits_str := _cell(row, "limits")
	if limits_str != "":
		out["limits"] = _parse_json_any(limits_str, {})
	# Tutorial hints from separate CSV
	var hint_rows := _rows("%s/companion_tutorial_hints.csv" % src)
	if not hint_rows.is_empty():
		var hints := {}
		for hrow in hint_rows:
			var hkey := _cell(hrow, "hint_key")
			if hkey != "":
				hints[hkey] = _cell(hrow, "text")
		out["tutorial_hints"] = hints
	return out
