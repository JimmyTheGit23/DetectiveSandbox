class_name TextUtils
## 文本显示工具：在显示层过滤舞台指示，保留原始数据不动。
## 过滤的括号内容（如"（低声）"）可用于未来动画/表情系统。
## 主角心理活动用中文括号保留，并在富文本层染成蓝色。

static var _re_export_note: RegEx = null

const INNER_THOUGHT_COLOR := "#4da3ff"

## 过滤中文括号内的舞台指示文本（（低声）、（叹气）等）
## 仅用于显示层，不影响 CSV 数据源。
static func strip_stage_directions(text: String) -> String:
	var result := strip_export_notes(text)
	result = _strip_stage_parentheticals(result)
	# 清理可能残留的多余空格
	result = _collapse_spaces(result).strip_edges()
	return result


## 去掉导出文档残留的章节标记，如 *(fail_dialogue)*。
static func strip_export_notes(text: String) -> String:
	if _re_export_note == null:
		_re_export_note = RegEx.new()
		_re_export_note.compile("\\s*\\*\\([^)]*\\)\\*")
	return _re_export_note.sub(text, "", true).strip_edges()


## 对话/旁白显示前的纯文本准备。force_inner_thought=true 时整句视为心理活动。
static func prepare_dialogue_plain_text(text: String, force_inner_thought := false) -> String:
	var result := strip_export_notes(text).replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	if force_inner_thought:
		result = ensure_inner_thought_parentheses(result)
	else:
		result = strip_stage_directions(result)
	while result.find("\n\n") >= 0:
		result = result.replace("\n\n", "\n")
	return result


## 心理活动必须用中文括号呈现；若原文没加括号，显示层自动补上。
static func ensure_inner_thought_parentheses(text: String) -> String:
	var result := strip_export_notes(text).strip_edges()
	if result == "":
		return result
	if _is_fully_wrapped_by_chinese_parentheses(result):
		return result
	return "（%s）" % result


## 剥离所有中文括号内容（用于非心理活动的普通对话，确保漏网的舞台指示不残留）。
static func strip_all_parentheticals(text: String) -> String:
	var out := ""
	var i := 0
	while i < text.length():
		var ch := text[i]
		if ch == "（":
			var end := text.find("）", i + 1)
			if end > i:
				i = end + 1
				continue
		out += ch
		i += 1
	return _collapse_spaces(out).strip_edges()


## 将保留下来的括号段染蓝。调用前应先移除舞台指示。
static func color_inner_thoughts(text: String, color := INNER_THOUGHT_COLOR) -> String:
	var out := ""
	var i := 0
	while i < text.length():
		var ch := text[i]
		if ch == "（":
			var end := text.find("）", i + 1)
			if end > i:
				var segment := text.substr(i, end - i + 1)
				out += "[color=%s]%s[/color]" % [color, segment]
				i = end + 1
				continue
		out += ch
		i += 1
	return out


static func format_dialogue_text(text: String, force_inner_thought := false, color := INNER_THOUGHT_COLOR) -> String:
	var plain := prepare_dialogue_plain_text(text, force_inner_thought)
	return color_inner_thoughts(plain, color) if force_inner_thought else strip_all_parentheticals(plain)


static func _strip_stage_parentheticals(text: String) -> String:
	var out := ""
	var i := 0
	while i < text.length():
		var ch := text[i]
		if ch == "（":
			var end := text.find("）", i + 1)
			if end > i:
				var inner := text.substr(i + 1, end - i - 1)
				if _is_stage_direction(inner):
					i = end + 1
					continue
				out += text.substr(i, end - i + 1)
				i = end + 1
				continue
		out += ch
		i += 1
	return out


static func _is_stage_direction(inner: String) -> bool:
	var s := inner.strip_edges()
	if s == "":
		return true
	var hard_stage_markers := [
		"低声", "小声", "叹气", "沉默", "停住", "蹲下", "凑近", "抬头", "低头",
		"翻开", "看了", "吞了", "突然", "浑身", "神色", "语无伦次", "捂住脸",
		"对峙", "先不回答", "愣了", "嘴角", "看着", "指了指", "低着头",
		"将浮囊", "放在桌", "发颤", "抠", "涌出来", "闷在", "滑下来", "抱头",
		"话停", "摸了", "手停", "看手", "望向"
	]
	for marker in hard_stage_markers:
		if s.find(marker) >= 0:
			return true
	if _looks_like_inner_thought(s):
		return false
	for marker in ["声音", "手指", "双手", "眼泪", "眼睛"]:
		if s.find(marker) >= 0:
			return true
	return false


static func _looks_like_inner_thought(text: String) -> bool:
	for mark in ["。", "！", "？", "?", "!", "……"]:
		if text.find(mark) >= 0:
			return true
	return false


static func _is_fully_wrapped_by_chinese_parentheses(text: String) -> bool:
	if not text.begins_with("（") or not text.ends_with("）"):
		return false
	var depth := 0
	for i in range(text.length()):
		var ch := text[i]
		if ch == "（":
			depth += 1
		elif ch == "）":
			depth -= 1
			if depth == 0 and i < text.length() - 1:
				return false
	return depth == 0


static func _collapse_spaces(text: String) -> String:
	var result := text
	while result.find("  ") >= 0:
		result = result.replace("  ", " ")
	result = result.replace(" \n", "\n").replace("\n ", "\n")
	return result
