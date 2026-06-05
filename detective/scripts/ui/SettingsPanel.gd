extends Control
## 设置面板：BGM 音量 / 语音音量 / 返回标题 / 关闭。

signal close_requested()
signal return_to_title_requested()
signal game_reset_requested()

@onready var panel: PanelContainer = $Panel

var _bgm_slider: HSlider
var _voice_slider: HSlider
var _bgm_value_lbl: Label
var _voice_value_lbl: Label
var _gm_check: CheckBox
var _gm_preset_select: OptionButton
var _gm_confront_select: OptionButton
var _gm_dialogue_input: LineEdit
var _gm_narration_input: LineEdit
var _gm_event_input: LineEdit
var _reset_button: Button
# 用 get_node 取 autoload，避免 LSP 在某些环境下不识别 autoload symbol
var _settings: Node


func _ready() -> void:
	_settings = get_node_or_null("/root/SettingsService")
	_build_ui()


func _bgm_init_value() -> float:
	return float(_settings.bgm_volume) if _settings else 0.8


func _voice_init_value() -> float:
	return float(_settings.voice_volume) if _settings else 1.0


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(root)
	
	# 标题
	var title := Label.new()
	title.text = "设  置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.65))
	root.add_child(title)
	
	# 分割线
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.6, 0.45, 0.25, 0.6))
	root.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	root.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	# 音乐音量
	vbox.add_child(_make_volume_row("音  乐", _bgm_init_value(), true))
	# 语音音量
	vbox.add_child(_make_volume_row("语  音", _voice_init_value(), false))
	
	# 间距
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	# GM 指令区
	var gm_sep := HSeparator.new()
	gm_sep.add_theme_color_override("separator", Color(0.6, 0.45, 0.25, 0.4))
	vbox.add_child(gm_sep)

	var gm_box := HBoxContainer.new()
	gm_box.add_theme_constant_override("separation", 10)
	gm_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(gm_box)

	var gm_label := Label.new()
	gm_label.text = "GM 指令"
	gm_label.add_theme_font_size_override("font_size", 18)
	gm_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3, 1))
	gm_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gm_box.add_child(gm_label)

	_gm_check = CheckBox.new()
	_gm_check.text = "解锁全部案件"
	_gm_check.button_pressed = bool(_settings.get("gm_unlock_all")) if _settings else false
	_gm_check.add_theme_font_size_override("font_size", 16)
	_gm_check.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55, 1))
	_gm_check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gm_check.toggled.connect(_on_gm_unlock_toggled)
	gm_box.add_child(_gm_check)

	var gm_hint := Label.new()
	gm_hint.text = "（测试用，无视等级限制）"
	gm_hint.add_theme_font_size_override("font_size", 12)
	gm_hint.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42, 0.8))
	gm_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gm_box.add_child(gm_hint)

	_build_gm_jump_tools(vbox)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer2)
	
	# 按钮区
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	root.add_child(btn_box)
	
	var btn_title := Button.new()
	btn_title.text = "返回标题画面"
	btn_title.custom_minimum_size = Vector2(0, 48)
	btn_title.add_theme_font_size_override("font_size", 20)
	btn_title.pressed.connect(_on_return_title)
	btn_box.add_child(btn_title)
	
	var btn_reset := Button.new()
	btn_reset.text = "重置游戏进度"
	btn_reset.custom_minimum_size = Vector2(0, 48)
	btn_reset.add_theme_font_size_override("font_size", 20)
	btn_reset.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))
	btn_reset.pressed.connect(_on_reset_game)
	btn_box.add_child(btn_reset)
	_reset_button = btn_reset
	
	var reset_hint := Label.new()
	reset_hint.text = "（清除所有案件进度、经验和存档，不可恢复）"
	reset_hint.add_theme_font_size_override("font_size", 12)
	reset_hint.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42, 0.8))
	btn_box.add_child(reset_hint)
	
	var btn_close := Button.new()
	btn_close.text = "关闭设置"
	btn_close.custom_minimum_size = Vector2(0, 44)
	btn_close.add_theme_font_size_override("font_size", 18)
	btn_close.pressed.connect(_on_close)
	btn_box.add_child(btn_close)


func _build_gm_jump_tools(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)

	var title := Label.new()
	title.text = "GM 跳转"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.96, 0.72, 0.36, 1))
	box.add_child(title)

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 8)
	box.add_child(preset_row)

	_gm_preset_select = OptionButton.new()
	_gm_preset_select.custom_minimum_size = Vector2(240, 36)
	_populate_gm_presets()
	preset_row.add_child(_gm_preset_select)

	var btn_apply := _make_gm_button("套用预设")
	btn_apply.pressed.connect(_on_gm_apply_preset)
	preset_row.add_child(btn_apply)

	var btn_preset_confront := _make_gm_button("进预设对峙")
	btn_preset_confront.pressed.connect(_on_gm_preset_confront)
	preset_row.add_child(btn_preset_confront)

	var dialogue_row := HBoxContainer.new()
	dialogue_row.add_theme_constant_override("separation", 8)
	box.add_child(dialogue_row)
	_gm_dialogue_input = _make_gm_input("li_zheng.ask_next_step")
	dialogue_row.add_child(_gm_dialogue_input)
	var btn_dialogue := _make_gm_button("跳对话")
	btn_dialogue.pressed.connect(_on_gm_jump_dialogue)
	dialogue_row.add_child(btn_dialogue)

	var narration_row := HBoxContainer.new()
	narration_row.add_theme_constant_override("separation", 8)
	box.add_child(narration_row)
	_gm_narration_input = _make_gm_input("prologue.day2_lizheng_1")
	narration_row.add_child(_gm_narration_input)
	var btn_narration := _make_gm_button("跳叙事")
	btn_narration.pressed.connect(_on_gm_jump_narration)
	narration_row.add_child(btn_narration)

	var event_row := HBoxContainer.new()
	event_row.add_theme_constant_override("separation", 8)
	box.add_child(event_row)
	_gm_event_input = _make_gm_input("evt_shen_evidence_ready")
	event_row.add_child(_gm_event_input)
	var btn_event := _make_gm_button("播事件")
	btn_event.pressed.connect(_on_gm_play_event)
	event_row.add_child(btn_event)

	var confront_row := HBoxContainer.new()
	confront_row.add_theme_constant_override("separation", 8)
	box.add_child(confront_row)
	_gm_confront_select = OptionButton.new()
	_gm_confront_select.custom_minimum_size = Vector2(240, 36)
	for key in ["confrontation_wang", "confrontation", "confrontation_final"]:
		_gm_confront_select.add_item(key)
		_gm_confront_select.set_item_metadata(_gm_confront_select.get_item_count() - 1, key)
	confront_row.add_child(_gm_confront_select)
	var btn_confront := _make_gm_button("进对峙")
	btn_confront.pressed.connect(_on_gm_start_confrontation)
	confront_row.add_child(btn_confront)

	var btn_epilogue := _make_gm_button("播固定结尾")
	btn_epilogue.pressed.connect(_on_gm_fixed_epilogue)
	box.add_child(btn_epilogue)


func _make_gm_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 36)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(1.0, 0.74, 0.32, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.55, 1))
	return btn


func _make_gm_input(placeholder: String) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size = Vector2(240, 36)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return input


func _populate_gm_presets() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("gm_preset_options"):
		for item in main.gm_preset_options():
			var label := str(item.get("label", item.get("id", "")))
			var preset_id := str(item.get("id", ""))
			_gm_preset_select.add_item(label)
			_gm_preset_select.set_item_metadata(_gm_preset_select.get_item_count() - 1, preset_id)
	else:
		for preset_id in ["cabin_start", "wang_confront", "phase2_investigate", "main_confront_ready", "phase3_after_agui", "final_ready", "fixed_epilogue"]:
			_gm_preset_select.add_item(preset_id)
			_gm_preset_select.set_item_metadata(_gm_preset_select.get_item_count() - 1, preset_id)


func _make_volume_row(label_text: String, init_value: float, is_bgm: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)
	
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = init_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(280, 32)
	row.add_child(slider)
	
	var value_lbl := Label.new()
	value_lbl.text = "%d%%" % int(round(init_value * 100))
	value_lbl.custom_minimum_size = Vector2(56, 0)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_lbl.add_theme_font_size_override("font_size", 18)
	value_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value_lbl)
	
	if is_bgm:
		_bgm_slider = slider
		_bgm_value_lbl = value_lbl
		slider.value_changed.connect(_on_bgm_changed)
	else:
		_voice_slider = slider
		_voice_value_lbl = value_lbl
		slider.value_changed.connect(_on_voice_changed)
	
	return row


func _on_bgm_changed(v: float) -> void:
	_bgm_value_lbl.text = "%d%%" % int(round(v * 100))
	if _settings and _settings.has_method("set_bgm_volume"):
		_settings.set_bgm_volume(v)


func _on_voice_changed(v: float) -> void:
	_voice_value_lbl.text = "%d%%" % int(round(v * 100))
	if _settings and _settings.has_method("set_voice_volume"):
		_settings.set_voice_volume(v)


func _on_close() -> void:
	close_requested.emit()


func _on_return_title() -> void:
	return_to_title_requested.emit()


func _on_debug_confrontation() -> void:
	_gm_call_main("gm_apply_preset_and_confront", ["main_confront_ready"])


func _selected_metadata(opt: OptionButton) -> String:
	if opt == null or opt.get_item_count() <= 0:
		return ""
	var idx := opt.selected
	if idx < 0:
		idx = 0
	var meta = opt.get_item_metadata(idx)
	return str(meta)


func _input_text_or_placeholder(input: LineEdit) -> String:
	if input == null:
		return ""
	var value := input.text.strip_edges()
	if value == "":
		value = input.placeholder_text.strip_edges()
	return value


func _split_target(text: String) -> PackedStringArray:
	var value := text.strip_edges()
	var dot := value.find(".")
	if dot <= 0 or dot >= value.length() - 1:
		return PackedStringArray()
	return PackedStringArray([value.substr(0, dot), value.substr(dot + 1)])


func _on_gm_apply_preset() -> void:
	_gm_call_main("gm_apply_preset", [_selected_metadata(_gm_preset_select)])


func _on_gm_preset_confront() -> void:
	_gm_call_main("gm_apply_preset_and_confront", [_selected_metadata(_gm_preset_select)])


func _on_gm_jump_dialogue() -> void:
	var parts := _split_target(_input_text_or_placeholder(_gm_dialogue_input))
	if parts.size() != 2:
		return
	_gm_call_main("gm_jump_to_dialogue", [parts[0], parts[1]])


func _on_gm_jump_narration() -> void:
	var parts := _split_target(_input_text_or_placeholder(_gm_narration_input))
	if parts.size() != 2:
		return
	_gm_call_main("gm_jump_to_narration", [parts[0], parts[1]])


func _on_gm_play_event() -> void:
	_gm_call_main("gm_play_event", [_input_text_or_placeholder(_gm_event_input)])


func _on_gm_start_confrontation() -> void:
	_gm_call_main("gm_start_confrontation", [_selected_metadata(_gm_confront_select)])


func _on_gm_fixed_epilogue() -> void:
	_gm_call_main("gm_play_fixed_epilogue")


func _gm_call_main(method_name: String, args: Array = []) -> void:
	var main = get_tree().current_scene
	if main == null or not main.has_method(method_name):
		return
	close_requested.emit()
	match args.size():
		0:
			main.call_deferred(method_name)
		1:
			main.call_deferred(method_name, args[0])
		2:
			main.call_deferred(method_name, args[0], args[1])
		3:
			main.call_deferred(method_name, args[0], args[1], args[2])
		_:
			push_warning("Too many GM call args: " + method_name)



func _unlock_all_evidence() -> void:
	# 给玩家解锁本案所有证据和线索
	for eid in GameManager.evidence_data.keys():
		if eid.begins_with("_"):
			continue
		var entry: Dictionary = GameManager.evidence_data[eid]
		var etype: String = entry.get("type", "")
		if etype == "evidence":
			GameManager.add_evidence(eid)
		elif etype == "clue":
			GameManager.add_clue(eid)
	# 确保游戏状态为 playing
	if GameManager.current_state == GameManager.STATE_PROLOGUE:
		GameManager.set_state(GameManager.STATE_PLAYING)


func _on_gm_unlock_toggled(pressed: bool) -> void:
	if _settings and _settings.has_method("set_gm_unlock_all"):
		_settings.set_gm_unlock_all(pressed)


var _reset_confirm_step: int = 0

func _on_reset_game() -> void:
	if _reset_confirm_step == 0:
		_reset_confirm_step = 1
		if _reset_button:
			_reset_button.text = "确认重置？（再次点击执行）"
			_reset_button.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15))
		# 3秒后自动恢复
		get_tree().create_timer(3.0).timeout.connect(_reset_confirm_timeout)
	elif _reset_confirm_step == 1:
		_reset_confirm_step = 0
		_do_reset()


func _reset_confirm_timeout() -> void:
	_reset_confirm_step = 0
	if _reset_button and _reset_button.text.begins_with("确认重置"):
		_reset_button.text = "重置游戏进度"
		_reset_button.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))


func _do_reset() -> void:
	# 1. 重置调查员档案（等级、XP、通关记录等）
	var inv := get_node_or_null("/root/InvestigatorService")
	if inv and inv.has_method("reset_profile"):
		inv.reset_profile()
	# 2. 删除所有单案存档 + current_case.json
	var saves_dir := ProjectSettings.globalize_path("user://saves")
	if DirAccess.dir_exists_absolute(saves_dir):
		var da := DirAccess.open(saves_dir)
		if da:
			da.list_dir_begin()
			var fname := da.get_next()
			while fname != "":
				if fname.ends_with(".json"):
					da.remove(fname)
				fname = da.get_next()
	var cc_path := ProjectSettings.globalize_path("user://current_case.json")
	if FileAccess.file_exists("user://current_case.json"):
		DirAccess.remove_absolute(cc_path)
	# 3. 发出信号，由 MainGame 处理返回标题
	game_reset_requested.emit()
