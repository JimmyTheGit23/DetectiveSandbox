extends Node
## 对话管理：加载 JSON 对话树（支持条件分支、动态文本、flag）

signal dialogue_started(speaker: String, portrait: String, text: String, options: Array)
signal dialogue_ended()
signal narration_started(background: String, speaker: String, text: String, has_next: bool)
signal narration_ended()
signal lie_exposed(npc_id: String, lie_node: String)

var _current_tree: Dictionary = {}
var _current_node_id: String = ""
var _current_npc_id: String = ""
var _narration_mode: bool = false
var _narration_node: String = ""


# ─── NPC 对话 ───
func start_dialogue(npc_id: String) -> void:
	var path := "res://data/cases/%s/dialogues/%s.json" % [GameManager.ACTIVE_CASE, npc_id]
	if not FileAccess.file_exists(path):
		push_warning("No dialogue tree: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_current_tree = parsed
	_current_npc_id = npc_id
	_current_node_id = _pick_start_node()
	VoicePlayer.begin_session()
	GameManager.set_state(GameManager.STATE_DIALOGUE)
	_emit_current()


## 从指定节点开始对话（用于剧情事件触发某个特定场景对话）
func start_dialogue_at(npc_id: String, node_id: String) -> void:
	var path := "res://data/cases/%s/dialogues/%s.json" % [GameManager.ACTIVE_CASE, npc_id]
	if not FileAccess.file_exists(path):
		push_warning("No dialogue tree: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_current_tree = parsed
	_current_npc_id = npc_id
	_current_node_id = node_id
	VoicePlayer.begin_session()
	GameManager.set_state(GameManager.STATE_DIALOGUE)
	_emit_current()


func _pick_start_node() -> String:
	# 支持 start_variants 数组（按条件挑起点）
	if _current_tree.has("start_variants"):
		for v in _current_tree["start_variants"]:
			if GameManager.evaluate_condition(v.get("when", {})):
				return v.get("goto", _current_tree.get("start", "intro"))
	return _current_tree.get("start", "intro")


func choose_option(index: int) -> void:
	var node: Dictionary = _current_tree.get("nodes", {}).get(_current_node_id, {})
	var options: Array = _filter_options(node.get("options", []))
	if index < 0 or index >= options.size():
		return
	var opt: Dictionary = options[index]
	# 时间消耗
	var cost := int(opt.get("cost_time", 0))
	if cost > 0:
		GameManager.advance_period(cost)
	# 设置 flag
	for f in opt.get("set_flags", []):
		GameManager.set_flag(f)
	var goto: String = opt.get("goto", "")
	if goto == "" or goto == "__exit__":
		end_dialogue()
		return
	_current_node_id = goto
	_apply_node_entry(_current_node_id)
	var next_node: Dictionary = _current_tree.get("nodes", {}).get(_current_node_id, {})
	if next_node.get("end", false):
		_emit_current()
		# 等用户按继续
		return
	_emit_current()


func _apply_node_entry(node_id: String) -> void:
	var node: Dictionary = _current_tree.get("nodes", {}).get(node_id, {})
	# 标记节点访问
	GameManager.mark_node_visited(_current_npc_id, node_id)
	# 设置 flag
	for f in node.get("set_flags", []):
		GameManager.set_flag(f)
	# 谎言被揭穿
	var lie: Dictionary = node.get("lie", {})
	if lie.get("is_lie", false):
		# 这里只是 lie 元数据声明，揭穿走 reveal_lie 字段。无需处理。
		pass
	# 节点 reveal_lie: { "lie_node": "...", "set_flag": "..." }
	var reveal: Dictionary = node.get("reveal_lie", {})
	if reveal.size() > 0:
		var lie_node: String = reveal.get("lie_node", "")
		var lie_flag: String = "lie_exposed:%s.%s" % [_current_npc_id, lie_node]
		GameManager.set_flag(lie_flag)
		lie_exposed.emit(_current_npc_id, lie_node)


func end_dialogue() -> void:
	_current_tree = {}
	_current_npc_id = ""
	VoicePlayer.end_session()
	GameManager.set_state(GameManager.STATE_PLAYING)
	dialogue_ended.emit()


func _emit_current() -> void:
	var node: Dictionary = _current_tree.get("nodes", {}).get(_current_node_id, {})
	if node.is_empty():
		end_dialogue()
		return
	# 第一次进入此节点（choose_option 进来时已 mark；start 进来时这里 mark）
	if not GameManager.has_visited(_current_npc_id, _current_node_id):
		GameManager.mark_node_visited(_current_npc_id, _current_node_id)
		for f in node.get("set_flags", []):
			GameManager.set_flag(f)
		# 通过对话直接获得线索/证据
		var gc: String = node.get("gain_clue", "")
		if gc != "":
			GameManager.add_clue(gc)
		var ge: String = node.get("gain_evidence", "")
		if ge != "":
			GameManager.add_evidence(ge)
		var reveal: Dictionary = node.get("reveal_lie", {})
		if reveal.size() > 0:
			var lie_node: String = reveal.get("lie_node", "")
			var lie_flag: String = "lie_exposed:%s.%s" % [_current_npc_id, lie_node]
			GameManager.set_flag(lie_flag)
			lie_exposed.emit(_current_npc_id, lie_node)
	
	var npc := GameManager.get_npc_data(_current_npc_id)
	var portrait: String = npc.get("portrait", "")
	var npc_name: String = npc.get("name", _current_npc_id)
	var text: String = _resolve_text(node)
	var options := _filter_options(node.get("options", []))
	VoicePlayer.play_dialogue(_current_npc_id, _current_node_id)
	dialogue_started.emit(npc_name, portrait, text, options)


func _resolve_text(node: Dictionary) -> String:
	# 优先 text_variants（按条件取）
	if node.has("text_variants"):
		for v in node["text_variants"]:
			if v.get("default", false):
				continue
			if GameManager.evaluate_condition(v.get("when", {})):
				return v.get("text", "")
		# 没有匹配的，找 default
		for v in node["text_variants"]:
			if v.get("default", false):
				return v.get("text", "")
	return node.get("text", "")


func _filter_options(options: Array) -> Array:
	var out: Array = []
	for o in options:
		# 兼容旧字段
		var req_ev: String = o.get("requires_evidence", "")
		var req_cl: String = o.get("requires_clue", "")
		if req_ev != "" and not GameManager.has_evidence(req_ev):
			continue
		if req_cl != "" and not GameManager.has_clue(req_cl):
			continue
		# 新统一 requires
		if o.has("requires"):
			if not GameManager.evaluate_condition(o["requires"]):
				continue
		# hide_after_visit: 一次性选项
		if o.get("hide_after_visit", false):
			var goto: String = o.get("goto", "")
			if goto != "" and GameManager.has_visited(_current_npc_id, goto):
				continue
		out.append(o)
	return out


# ─── 序章 / 叙述模式 ───
func start_narration(json_path: String) -> void:
	if not FileAccess.file_exists(json_path):
		return
	var f := FileAccess.open(json_path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_current_tree = parsed
	_narration_mode = true
	_narration_node = _current_tree.get("start", "scene1")
	VoicePlayer.begin_session()
	_emit_narration()


func narration_next() -> void:
	if not _narration_mode:
		return
	var node: Dictionary = _current_tree.get("nodes", {}).get(_narration_node, {})
	if node.get("end", false):
		_end_narration()
		return
	var nxt: String = node.get("next", "")
	if nxt == "":
		_end_narration()
		return
	_narration_node = nxt
	_emit_narration()


func _emit_narration() -> void:
	var node: Dictionary = _current_tree.get("nodes", {}).get(_narration_node, {})
	if node.is_empty():
		_end_narration()
		return
	VoicePlayer.play_narration(_narration_node)
	if node.get("end", false):
		narration_started.emit(node.get("background", ""), node.get("speaker", ""), node.get("text", ""), false)
		return
	narration_started.emit(node.get("background", ""), node.get("speaker", ""), node.get("text", ""), true)


func _end_narration() -> void:
	_narration_mode = false
	_current_tree = {}
	VoicePlayer.end_session()
	narration_ended.emit()


# ─── 公开：临时播放一段简单 narration（用于日程事件）───
var _adhoc_lines: Array = []
var _adhoc_idx: int = 0
var _adhoc_callback: Callable

func play_adhoc_narration(lines: Array, callback: Callable = Callable()) -> void:
	## lines: Array of String 或 Array of { "speaker": "", "text": "", "background": "" }
	_adhoc_lines = lines
	_adhoc_idx = 0
	_adhoc_callback = callback
	_narration_mode = true
	_emit_adhoc()


func _emit_adhoc() -> void:
	if _adhoc_idx >= _adhoc_lines.size():
		_end_adhoc()
		return
	var item = _adhoc_lines[_adhoc_idx]
	var background := ""
	var speaker := ""
	var text := ""
	if item is String:
		text = item
	else:
		background = item.get("background", "")
		speaker = item.get("speaker", "")
		text = item.get("text", "")
	var has_next := _adhoc_idx < _adhoc_lines.size() - 1
	narration_started.emit(background, speaker, text, has_next)


func adhoc_next() -> void:
	_adhoc_idx += 1
	if _adhoc_idx >= _adhoc_lines.size():
		_end_adhoc()
		return
	_emit_adhoc()


func _end_adhoc() -> void:
	_narration_mode = false
	_adhoc_lines = []
	narration_ended.emit()
	if _adhoc_callback.is_valid():
		_adhoc_callback.call()


func is_adhoc() -> bool:
	return _narration_mode and _adhoc_lines.size() > 0


func narration_advance() -> void:
	# 统一入口：序章用 next，adhoc 用 adhoc_next
	if is_adhoc():
		adhoc_next()
	else:
		narration_next()
