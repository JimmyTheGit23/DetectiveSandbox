extends Node
## 对话管理：加载 JSON 对话树（支持条件分支、动态文本、flag）

signal dialogue_started(speaker: String, portrait: String, text: String, options: Array, pages: Array)
signal dialogue_ended()
signal confrontation_triggered()
signal narration_started(background: String, speaker: String, text: String, has_next: bool, centered: bool, portrait: String)
signal narration_choices_ready(choices: Array)
signal narration_ended()
signal lie_exposed(npc_id: String, lie_node: String)

var _current_tree: Dictionary = {}
var _current_node_id: String = ""
var _current_npc_id: String = ""
var _dialogue_had_content_node: bool = false
var _will_trigger_confrontation: bool = false
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
	_dialogue_had_content_node = false
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


func end_dialogue(suppress_companion_banter := false) -> void:
	var ended_npc := _current_npc_id
	var had_content := _dialogue_had_content_node
	var should_confront := _will_trigger_confrontation
	_current_tree = {}
	_current_npc_id = ""
	_dialogue_had_content_node = false
	_will_trigger_confrontation = false
	VoicePlayer.end_session()
	GameManager.set_state(GameManager.STATE_PLAYING)
	dialogue_ended.emit()
	# 对峙触发：对话结束后立即进入对峙
	if should_confront:
		confrontation_triggered.emit()
		return
	# 助手被动旁白：至少听过一个实质询问节点后，结束对话才触发总结。
	if not suppress_companion_banter and had_content:
		_try_companion_banter({"trigger": "dialogue_end", "npc_id": ended_npc, "node_id": ""})


func _emit_current() -> void:
	var node: Dictionary = _current_tree.get("nodes", {}).get(_current_node_id, {})
	if node.is_empty():
		end_dialogue()
		return
	if _current_node_id != "hub":
		_dialogue_had_content_node = true
	# 第一次进入此节点（choose_option 进来时已 mark；start 进来时这里 mark）
	if not GameManager.has_visited(_current_npc_id, _current_node_id):
		GameManager.mark_node_visited(_current_npc_id, _current_node_id)
		for f in node.get("set_flags", []):
			GameManager.set_flag(f)
		# 兼容旧对话格式 effects: { set_flag/add_clue/add_evidence }
		var effects: Dictionary = node.get("effects", {})
		if not effects.is_empty():
			var flags = effects.get("set_flag", effects.get("set_flags", []))
			if flags is String:
				GameManager.set_flag(flags)
			elif flags is Array:
				for fx_flag in flags:
					GameManager.set_flag(str(fx_flag))
			var old_gc: String = effects.get("add_clue", "")
			if old_gc != "":
				GameManager.add_clue(old_gc)
			var old_ge: String = effects.get("add_evidence", "")
			if old_ge != "":
				GameManager.add_evidence(old_ge)
		# 通过对话直接获得线索/证据
		var gc: String = node.get("gain_clue", "")
		if gc != "":
			GameManager.add_clue(gc)
			_try_companion_banter({
				"trigger": "gain_clue",
				"npc_id": _current_npc_id,
				"node_id": _current_node_id,
				"gained_clue": gc,
				"companion_banter": node.get("companion_banter", []),
			})
		var ge: String = node.get("gain_evidence", "")
		if ge != "":
			GameManager.add_evidence(ge)
			_try_companion_banter({
				"trigger": "gain_evidence",
				"npc_id": _current_npc_id,
				"node_id": _current_node_id,
				"gained_evidence": ge,
				"companion_banter": node.get("companion_banter", []),
			})
		var reveal: Dictionary = node.get("reveal_lie", {})
		if reveal.size() > 0:
			var lie_node: String = reveal.get("lie_node", "")
			var lie_flag: String = "lie_exposed:%s.%s" % [_current_npc_id, lie_node]
			GameManager.set_flag(lie_flag)
			lie_exposed.emit(_current_npc_id, lie_node)
			_try_companion_banter({
				"trigger": "lie_exposed",
				"npc_id": _current_npc_id,
				"node_id": _current_node_id,
				"companion_banter": node.get("companion_banter", []),
			})
	
	var npc := GameManager.get_npc_data(_current_npc_id)
	# 通过 AssetResolver 解析立绘和角色名（先走 casting → actor → portrait，回退到 npcs.json）
	var portrait: String = AssetResolver.get_portrait(_current_npc_id, GameManager.npcs_data)
	var role_info: Dictionary = AssetResolver.get_role_info(_current_npc_id, GameManager.npcs_data)
	var npc_name: String = GameManager.get_npc_display_name(_current_npc_id)
	if npc_name == "":
		npc_name = role_info.get("name", npc.get("name", _current_npc_id))
	var pages: Array = _resolve_dialogue_pages(node, npc_name, portrait)
	var text: String = _pages_to_text(pages)
	var options := _filter_options(node.get("options", []))
	# 优化：如果当前节点的选项只是"回 hub"+"退出"这种中转，直接跳到 hub
	# 这样 choose_option 读的选项和玩家看到的一致（解决索引不匹配导致的卡死）
	if _should_skip_to_hub(options):
		_current_node_id = "hub"
		var hub_node: Dictionary = _current_tree.get("nodes", {}).get("hub", {})
		options = _filter_options(hub_node.get("options", []))
	VoicePlayer.play_dialogue(_current_npc_id, _current_node_id)
	# TTS 异步请求：如果 VoicePlayer 没有命中预录或缓存，发起 TTS 生成
	_try_tts_for_dialogue(_current_npc_id, _current_node_id, text)
	# 检查是否触发对峙：对话播完后自动进入对峙流程
	if node.get("trigger_confrontation", false):
		_will_trigger_confrontation = true
	dialogue_started.emit(npc_name, portrait, text, options, pages)


func _resolve_text(node: Dictionary) -> String:
	return _pages_to_text(_resolve_dialogue_pages(node, "", ""))


func _resolve_dialogue_pages(node: Dictionary, default_speaker: String, default_portrait: String) -> Array:
	var lines: Array = node.get("lines", [])
	if not lines.is_empty():
		var out: Array = []
		for line in lines:
			if typeof(line) != TYPE_DICTIONARY:
				continue
			# 支持单行条件：requires 不满足则跳过该行
			if line.has("requires"):
				if not GameManager.evaluate_condition(line["requires"]):
					continue
			var line_text: String = str(line.get("text", "")).strip_edges()
			if line_text == "":
				continue
			var line_type: String = str(line.get("type", "")).strip_edges()
			var speaker: String = str(line.get("speaker", "")).strip_edges()
			var speaker_id: String = str(line.get("speaker_id", line.get("npc_id", ""))).strip_edges()
			if speaker == "" and speaker_id != "":
				speaker = _display_name_for_speaker_id(speaker_id)
			if speaker == "" and line_type != "narration":
				speaker = default_speaker
			var portrait: String = str(line.get("portrait", "")).strip_edges()
			if portrait == "" and line_type != "narration":
				portrait = _portrait_for_speaker(speaker, speaker_id, default_speaker, default_portrait)
			var page := {"speaker": speaker, "portrait": portrait, "text": line_text, "type": line_type}
			for meta_key in ["emotion", "mood", "highlight", "record", "record_type", "record_title", "record_text", "record_id"]:
				if line.has(meta_key):
					page[meta_key] = line[meta_key]
			out.append(page)
		if not out.is_empty():
			return out
	# 优先 text_variants（按条件取）
	if node.has("text_variants"):
		for v in node["text_variants"]:
			if v.get("default", false):
				continue
			if GameManager.evaluate_condition(v.get("when", {})):
				return _single_page(default_speaker, default_portrait, v.get("text", ""))
		# 没有匹配的，找 default
		for v in node["text_variants"]:
			if v.get("default", false):
				return _single_page(default_speaker, default_portrait, v.get("text", ""))
	var text: String = node.get("text", "")
	if text != "":
		return _single_page(default_speaker, default_portrait, text)
	return _single_page(default_speaker, default_portrait, "（此处暂无可显示的对话内容。）")


func _single_page(speaker: String, portrait: String, text: String) -> Array:
	return [{"speaker": speaker, "portrait": portrait, "text": text}]


func _pages_to_text(pages: Array) -> String:
	var parts: Array[String] = []
	for page in pages:
		if typeof(page) != TYPE_DICTIONARY:
			continue
		var line_text: String = str(page.get("text", "")).strip_edges()
		if line_text != "":
			parts.append(line_text)
	return "\n\n".join(parts)


func _display_name_for_speaker_id(speaker_id: String) -> String:
	if speaker_id == "xia_lingyao" or speaker_id == "lingyao":
		return "凌瑶"
	var display_name := GameManager.get_npc_display_name(speaker_id)
	if display_name != "":
		return display_name
	var role_info: Dictionary = AssetResolver.get_role_info(speaker_id, GameManager.npcs_data)
	return role_info.get("name", speaker_id)


func _portrait_for_speaker(speaker: String, speaker_id: String, default_speaker: String, default_portrait: String) -> String:
	if speaker_id == "xia_lingyao" or speaker_id == "lingyao" or speaker == "凌瑶":
		var cs = get_node_or_null("/root/CompanionService")
		if cs != null and cs.has_method("get_companion_portrait"):
			return cs.get_companion_portrait()
		return "res://assets/cn/portraits/companion_lingyao.png"
	if speaker_id != "":
		return AssetResolver.get_portrait(speaker_id, GameManager.npcs_data)
	if speaker == "陆昭":
		return AssetResolver.get_portrait("lu_zhao", GameManager.npcs_data)
	if speaker == default_speaker:
		return default_portrait
	for npc_id in GameManager.npcs_data.keys():
		if GameManager.get_npc_display_name(str(npc_id)) == speaker:
			return AssetResolver.get_portrait(str(npc_id), GameManager.npcs_data)
	return ""


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
		var option_copy: Dictionary = o.duplicate(true)
		var goto: String = option_copy.get("goto", "")
		option_copy["_visited"] = goto != "" and goto != "__exit__" and GameManager.has_visited(_current_npc_id, goto)
		out.append(option_copy)
	return out


## 检测：当前节点选项是否只有"回 hub + 退出"的无意义中转
func _should_skip_to_hub(options: Array) -> bool:
	if _current_node_id == "hub":
		return false
	if not _current_tree.get("nodes", {}).has("hub"):
		return false
	var has_hub_goto := false
	for o in options:
		var goto: String = o.get("goto", "")
		if goto == "hub":
			has_hub_goto = true
		elif goto == "__exit__" or goto == "":
			pass
		else:
			return false
	return has_hub_goto


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
	# 有选项的节点不走 narration_next，等 narration_choose
	if node.has("choices") and not node.get("choices", []).is_empty():
		return
	var nxt: String = node.get("next", "")
	if nxt == "":
		_end_narration()
		return
	_narration_node = nxt
	_emit_narration()


## 叙述中选择选项（密室逃脱等交互场景用）
func narration_choose(index: int) -> void:
	if not _narration_mode:
		return
	var node: Dictionary = _current_tree.get("nodes", {}).get(_narration_node, {})
	var choices: Array = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	# 应用选项效果
	_apply_narration_effects(choice.get("effect", {}))
	var goto: String = choice.get("goto", "")
	if goto == "" or goto == "__end__":
		_end_narration()
		return
	_narration_node = goto
	_emit_narration()


func _emit_narration() -> void:
	var node: Dictionary = _current_tree.get("nodes", {}).get(_narration_node, {})
	if node.is_empty():
		_end_narration()
		return
	# 应用节点自身效果（进入即触发）
	_apply_narration_effects(node.get("effect", {}))
	if not node.get("silent", false):
		VoicePlayer.play_narration(_narration_node)
	else:
		VoicePlayer.stop()
	var centered: bool = node.get("centered", false)
	var has_choices: bool = node.has("choices") and not node.get("choices", []).is_empty()
	var node_portrait: String = node.get("portrait", "")
	if node.get("end", false):
		narration_started.emit(node.get("background", ""), node.get("speaker", ""), node.get("text", ""), false, centered, node_portrait)
		return
	# 有选项时 has_next 设为 false（不显示"点击继续"），改为等选项
	var has_next: bool = not has_choices
	narration_started.emit(node.get("background", ""), node.get("speaker", ""), node.get("text", ""), has_next, centered, node_portrait)
	if has_choices:
		narration_choices_ready.emit(node.get("choices", []))


## 应用叙述节点/选项的效果
func _apply_narration_effects(effects) -> void:
	if effects == null or typeof(effects) != TYPE_DICTIONARY:
		return
	var d: Dictionary = effects
	if d.has("set_flag"):
		var f = d["set_flag"]
		if f is String:
			GameManager.set_flag(f)
		elif f is Array:
			for x in f:
				GameManager.set_flag(str(x))
	if d.has("gain_clue"):
		GameManager.add_clue(str(d["gain_clue"]))
	if d.has("gain_evidence"):
		GameManager.add_evidence(str(d["gain_evidence"]))


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
	# 为叙述中有 speaker 的行触发 TTS
	if speaker != "" and speaker != "旁白" and text != "":
		_try_tts_for_narration(speaker, text)
	var centered := false
	if item is Dictionary:
		centered = item.get("centered", false)
		VoicePlayer.play_voice_path(item.get("voice_path", ""))
	else:
		VoicePlayer.stop()
	narration_started.emit(background, speaker, text, has_next, centered, "")


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


# ─── 助手旁白触发辅助 ───
func _try_companion_banter(context: Dictionary) -> void:
	var cs = get_node_or_null("/root/CompanionService")
	if cs == null:
		return
	if not cs.has_method("try_emit_banter"):
		return
	cs.try_emit_banter(context)


# ─── TTS 集成 ───
func _try_tts_for_dialogue(npc_id: String, node_id: String, text: String) -> void:
	var tts := get_node_or_null("/root/TTSService")
	if tts == null or not tts.is_available():
		return
	# 如果已有缓存，VoicePlayer._try_tts_fallback 已经播放了
	# 这里负责发起异步 TTS 请求（无缓存时）
	if tts.try_play_cached(npc_id, node_id):
		return
	# 异步请求 TTS，生成后自动播放
	tts.request_tts(npc_id, node_id, text)


func _try_tts_for_narration(speaker: String, text: String) -> void:
	var tts := get_node_or_null("/root/TTSService")
	if tts == null or not tts.is_available():
		return
	tts.request_tts_speaker(speaker, text)
