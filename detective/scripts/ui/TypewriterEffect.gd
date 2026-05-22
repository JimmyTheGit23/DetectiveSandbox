extends Node
## 逐字显示文本效果。支持语气节奏控制和音效标记。
##
## 用法：
##   var TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")
##   var tw = TypewriterEffectScript.new()
##   add_child(tw)
##   tw.play(rich_text_label, "你好……世界！")
##   await tw.finished
##
## 文本中可嵌入控制标记：
##   <pause=0.5>    — 在此处暂停 0.5 秒
##   <speed=0.5>    — 切换为慢速（数值越小越慢，1.0=默认）
##   <speed=2.0>    — 切换为快速
##   <speed=1.0>    — 恢复默认速度
##   <sfx=tap>      — 在此处触发音效（预留，当前仅记录）
##
## 标点自动节奏：
##   句号/叹号/问号后短暂停顿
##   省略号处稍作拉长
##   逗号/顿号轻微停顿

signal finished
signal sfx_requested(sfx_name: String)

## 基础每字延迟（秒）
@export var base_char_delay: float = 0.04
## 标点停顿倍率
@export var punctuation_pause_comma: float = 3.0    # 逗号/顿号
@export var punctuation_pause_period: float = 5.0   # 句号/叹号/问号
@export var punctuation_pause_ellipsis: float = 2.5 # 省略号中的每个点
## 括号内（旁白/动作描写）加速倍率
@export var parenthesis_speed: float = 1.5

var _target: RichTextLabel = null
var _raw_text: String = ""
var _display_text: String = ""       # 去除控制标记后的纯文本
var _commands: Array = []            # [{pos: int, type: str, value: variant}]
var _playing: bool = false
var _skip_requested: bool = false
var _current_speed: float = 1.0
var _in_parenthesis: bool = false
var _run_id: int = 0                 # 用于使旧协程失效，防止闪烁


func play(target: RichTextLabel, text: String) -> void:
	_run_id += 1
	var current_run := _run_id
	_target = target
	_raw_text = text
	_playing = true
	_skip_requested = false
	_current_speed = 1.0
	_in_parenthesis = false
	_parse_commands()
	_target.text = _display_text
	_target.visible_characters = 0
	_run_typewriter(current_run)


func skip() -> void:
	_skip_requested = true


func is_playing() -> bool:
	return _playing


## 解析文本中的控制标记，生成纯显示文本和命令列表
func _parse_commands() -> void:
	_commands.clear()
	_display_text = ""
	var i := 0
	var src := _raw_text
	while i < src.length():
		if src[i] == "<" and i + 1 < src.length():
			var end := src.find(">", i)
			if end > i:
				var tag := src.substr(i + 1, end - i - 1)
				var pos := _display_text.length()
				if tag.begins_with("pause="):
					var val := tag.substr(6).to_float()
					_commands.append({"pos": pos, "type": "pause", "value": val})
				elif tag.begins_with("speed="):
					var val := tag.substr(6).to_float()
					_commands.append({"pos": pos, "type": "speed", "value": val})
				elif tag.begins_with("sfx="):
					var val := tag.substr(4)
					_commands.append({"pos": pos, "type": "sfx", "value": val})
				else:
					# 保留 BBCode 标签原样（RichTextLabel 需要）
					_display_text += src.substr(i, end - i + 1)
				i = end + 1
				continue
		_display_text += src[i]
		i += 1


func _run_typewriter(run_id: int) -> void:
	var char_index := 0
	var total := _target.get_total_character_count()

	while char_index < total:
		# 如果有新的 play() 调用，旧协程立即退出（防止闪烁）
		if run_id != _run_id:
			return
		if _skip_requested:
			_target.visible_characters = -1
			break

		# 执行该位置的所有命令
		for cmd in _commands:
			if cmd["pos"] == char_index:
				match cmd["type"]:
					"pause":
						await get_tree().create_timer(cmd["value"]).timeout
						if run_id != _run_id:
							return
						if _skip_requested:
							_target.visible_characters = -1
							_finish()
							return
					"speed":
						_current_speed = cmd["value"]
					"sfx":
						sfx_requested.emit(cmd["value"])

		# 再次检查，避免 await 后状态已变
		if run_id != _run_id:
			return

		# 显示下一个字符
		char_index += 1
		_target.visible_characters = char_index

		# 计算延迟
		var delay := _get_char_delay(char_index - 1)
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
			if run_id != _run_id:
				return
			if _skip_requested:
				_target.visible_characters = -1
				break

	# 只有当前活跃的协程才能 finish
	if run_id == _run_id:
		_finish()


func _finish() -> void:
	_target.visible_characters = -1
	_playing = false
	finished.emit()


## 根据字符类型计算延迟
func _get_char_delay(char_pos: int) -> float:
	if char_pos < 0 or char_pos >= _display_text.length():
		return base_char_delay
	
	var ch := _display_text[char_pos]
	
	# 跳过 BBCode 标签内的字符（不额外延迟）
	# RichTextLabel 的 visible_characters 本身就跳过标签
	
	# 检查括号（动作描写加速）
	if ch == "（" or ch == "(":
		_in_parenthesis = true
	elif ch == "）" or ch == ")":
		_in_parenthesis = false
	
	var speed_mult := _current_speed
	if _in_parenthesis:
		speed_mult *= parenthesis_speed
	
	# 标点节奏
	if ch in ["，", "、", ",", "；"]:
		return base_char_delay * punctuation_pause_comma / speed_mult
	elif ch in ["。", "！", "？", ".", "!", "?"]:
		return base_char_delay * punctuation_pause_period / speed_mult
	elif ch == "…" or ch == "—":
		return base_char_delay * punctuation_pause_ellipsis / speed_mult
	elif ch == "\n":
		return base_char_delay * punctuation_pause_period / speed_mult
	else:
		return base_char_delay / speed_mult
