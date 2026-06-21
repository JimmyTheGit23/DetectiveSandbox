extends Control

signal cancelled()

const NPC_LAYOUT_PREVIEW_PANEL_SCENE_PATH := "res://scenes/ui/NpcLayoutPreviewPanel.tscn"
const DYNAMIC_PORTRAIT_TEST_SCENE_PATH := "res://scenes/ui/DynamicPortraitTest.tscn"
const DYNAMIC_PORTRAIT_V2_TEST_SCENE_PATH := "res://scenes/ui/DynamicPortraitTestV2.tscn"
const MODULAR_PORTRAIT_TEST_SCENE_PATH := "res://scenes/ui/ModularPortraitTest.tscn"

var _preset_select: OptionButton
var _confront_select: OptionButton
var _status_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_refresh_all()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.025, 0.04, 0.94)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", 36)
	shell.add_theme_constant_override("margin_right", 36)
	shell.add_theme_constant_override("margin_top", 28)
	shell.add_theme_constant_override("margin_bottom", 28)
	add_child(shell)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	shell.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = "GM 测试场景"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1.0))
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "预设跳转、对峙启动、中央 NPC 配置预览"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68, 0.92))
	title_box.add_child(subtitle)

	var close_btn := Button.new()
	close_btn.text = "返 回"
	close_btn.flat = true
	close_btn.custom_minimum_size = Vector2(88, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(0.92, 0.82, 0.60, 1.0))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.75, 1.0))
	close_btn.pressed.connect(_close_panel)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	root.add_child(body)

	body.add_child(_build_gm_column())
	body.add_child(_build_preview_column())

	_status_label = Label.new()
	_status_label.text = "当前案件：%s" % GameManager.ACTIVE_CASE
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color(0.83, 0.77, 0.68, 0.95))
	root.add_child(_status_label)


func _build_gm_column() -> Control:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(0, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	vbox.add_child(_make_section_title("流程跳转"))

	_preset_select = OptionButton.new()
	_preset_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_make_labeled_row("GM 预设", _preset_select))

	var preset_buttons := HBoxContainer.new()
	preset_buttons.add_theme_constant_override("separation", 10)
	vbox.add_child(preset_buttons)

	var apply_btn := _make_action_button("应用预设（停在该阶段）")
	apply_btn.pressed.connect(_on_apply_preset_pressed)
	preset_buttons.add_child(apply_btn)

	var preset_confront_btn := _make_action_button("预设并进入对峙")
	preset_confront_btn.pressed.connect(_on_preset_confront_pressed)
	preset_buttons.add_child(preset_confront_btn)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.50, 0.38, 0.22, 0.35))
	vbox.add_child(sep)

	vbox.add_child(_make_section_title("直接功能"))

	_confront_select = OptionButton.new()
	_confront_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_make_labeled_row("对峙 ID", _confront_select))

	var confront_btn := _make_action_button("直接进入对峙（自动补预设）")
	confront_btn.pressed.connect(_on_start_confront_pressed)
	vbox.add_child(confront_btn)

	var title_btn := _make_action_button("回到标题界面")
	title_btn.pressed.connect(_on_return_title_pressed)
	vbox.add_child(title_btn)

	return panel


func _build_preview_column() -> Control:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(0, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	vbox.add_child(_make_section_title("立绘预览场景"))

	var desc := RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.scroll_active = false
	desc.add_theme_font_size_override("normal_font_size", 15)
	desc.add_theme_color_override("default_color", Color(0.88, 0.84, 0.78, 1.0))
	desc.text = "点击下面按钮会打开一个独立预览场景。\n在里面可以直接切换 [b]NPC / 表情 / 背景[/b]，并且支持 [b]重载配置[/b]，看改表后的即时效果。"
	vbox.add_child(desc)

	var open_btn := _make_action_button("打开立绘预览场景")
	open_btn.pressed.connect(_on_open_preview_scene_pressed)
	vbox.add_child(open_btn)

	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("separator", Color(0.50, 0.38, 0.22, 0.35))
	vbox.add_child(sep2)

	vbox.add_child(_make_section_title("动态立绘测试"))

	var anim_desc := RichTextLabel.new()
	anim_desc.bbcode_enabled = true
	anim_desc.fit_content = true
	anim_desc.scroll_active = false
	anim_desc.add_theme_font_size_override("normal_font_size", 15)
	anim_desc.add_theme_color_override("default_color", Color(0.88, 0.84, 0.78, 1.0))
	anim_desc.text = "[b]V2 分层叠加[/b]：Body + Eyes 小图块 + Mouth 小图块\n(小图 Gemini 生成，精准无漂移)"
	vbox.add_child(anim_desc)

	var anim_btn2 := _make_action_button("打开动态立绘测试 V2")
	anim_btn2.pressed.connect(_on_open_dynamic_portrait_v2_pressed)
	vbox.add_child(anim_btn2)

	var anim_desc_mod := RichTextLabel.new()
	anim_desc_mod.bbcode_enabled = true
	anim_desc_mod.fit_content = true
	anim_desc_mod.scroll_active = false
	anim_desc_mod.add_theme_font_size_override("normal_font_size", 15)
	anim_desc_mod.add_theme_color_override("default_color", Color(0.88, 0.84, 0.78, 1.0))
	anim_desc_mod.text = "[b]模块化方案[/b]：基底 + Eyes 精确裁剪 + 坐标对齐\n(彻底解决眉毛动 / 叠影问题)"
	vbox.add_child(anim_desc_mod)

	var anim_btn3 := _make_action_button("打开模块化立绘测试 (新)")
	anim_btn3.pressed.connect(_on_open_modular_portrait_pressed)
	vbox.add_child(anim_btn3)

	var anim_desc_v1 := RichTextLabel.new()
	anim_desc_v1.bbcode_enabled = true
	anim_desc_v1.fit_content = true
	anim_desc_v1.scroll_active = false
	anim_desc_v1.add_theme_font_size_override("normal_font_size", 14)
	anim_desc_v1.add_theme_color_override("default_color", Color(0.72, 0.70, 0.65, 1.0))
	anim_desc_v1.text = "V1 整图帧方案 (旧)"
	vbox.add_child(anim_desc_v1)

	var anim_btn := _make_action_button("打开动态立绘测试 V1")
	anim_btn.pressed.connect(_on_open_dynamic_portrait_pressed)
	vbox.add_child(anim_btn)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	return panel


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.065, 0.05, 0.96)
	style.border_color = Color(0.56, 0.41, 0.20, 0.86)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.63, 1.0))
	return label


func _make_labeled_row(label_text: String, field: Control) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.76, 0.71, 0.64, 0.95))
	row.add_child(label)
	row.add_child(field)
	return row


func _make_action_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = true
	btn.custom_minimum_size = Vector2(0, 42)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.94, 0.70, 0.32, 1.0))
	return btn


func _refresh_all() -> void:
	_refresh_presets()
	_refresh_confrontations()
	_update_status("当前案件：%s" % GameManager.ACTIVE_CASE)


func _refresh_presets() -> void:
	_preset_select.clear()
	var main := _main_scene()
	if main == null or not main.has_method("gm_preset_options"):
		return
	var options: Array = main.call("gm_preset_options")
	for entry in options:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var label := str(entry.get("label", entry.get("id", "")))
		var preset_id := str(entry.get("id", ""))
		_preset_select.add_item(label)
		_preset_select.set_item_metadata(_preset_select.get_item_count() - 1, preset_id)


func _refresh_confrontations() -> void:
	_confront_select.clear()
	var keys: Array = []
	for key in GameManager.case_data.keys():
		var id := str(key)
		if id.begins_with("confrontation"):
			keys.append(id)
	keys.sort()
	for id in keys:
		_confront_select.add_item(id)
		_confront_select.set_item_metadata(_confront_select.get_item_count() - 1, id)


func _on_apply_preset_pressed() -> void:
	_transition_main("gm_apply_preset", [_selected_metadata(_preset_select)])


func _on_preset_confront_pressed() -> void:
	_transition_main("gm_apply_preset_and_confront", [_selected_metadata(_preset_select)])


func _on_start_confront_pressed() -> void:
	_transition_main("gm_start_confrontation", [_selected_metadata(_confront_select)])


func _on_open_preview_scene_pressed() -> void:
	if NPC_LAYOUT_PREVIEW_PANEL_SCENE_PATH == "" or not ResourceLoader.exists(NPC_LAYOUT_PREVIEW_PANEL_SCENE_PATH):
		_update_status("缺少立绘预览场景")
		return
	var packed: PackedScene = load(NPC_LAYOUT_PREVIEW_PANEL_SCENE_PATH)
	var panel: Control = packed.instantiate()
	get_tree().current_scene.add_child(panel)
	_update_status("已打开立绘预览场景")


func _on_open_dynamic_portrait_v2_pressed() -> void:
	if not ResourceLoader.exists(DYNAMIC_PORTRAIT_V2_TEST_SCENE_PATH):
		_update_status("缺少动态立绘测试 V2 场景")
		return
	var packed: PackedScene = load(DYNAMIC_PORTRAIT_V2_TEST_SCENE_PATH)
	var panel: Control = packed.instantiate()
	get_tree().current_scene.add_child(panel)
	_update_status("已打开动态立绘测试 V2 (分层叠加)")


func _on_open_modular_portrait_pressed() -> void:
	if not ResourceLoader.exists(MODULAR_PORTRAIT_TEST_SCENE_PATH):
		_update_status("缺少模块化立绘测试场景")
		return
	var packed: PackedScene = load(MODULAR_PORTRAIT_TEST_SCENE_PATH)
	var panel: Control = packed.instantiate()
	get_tree().current_scene.add_child(panel)
	_update_status("已打开模块化立绘测试 (精确裁剪，无叠影)")


func _on_open_dynamic_portrait_pressed() -> void:
	if not ResourceLoader.exists(DYNAMIC_PORTRAIT_TEST_SCENE_PATH):
		_update_status("缺少动态立绘测试场景")
		return
	var packed: PackedScene = load(DYNAMIC_PORTRAIT_TEST_SCENE_PATH)
	var panel: Control = packed.instantiate()
	get_tree().current_scene.add_child(panel)
	_update_status("已打开动态立绘测试")


func _on_return_title_pressed() -> void:
	_transition_main("gm_return_to_title")


func _selected_metadata(opt: OptionButton) -> String:
	if opt == null or opt.get_item_count() <= 0:
		return ""
	var idx := opt.selected
	if idx < 0:
		idx = 0
	return str(opt.get_item_metadata(idx))


func _call_main(method_name: String, args: Array = []) -> void:
	var main := _main_scene()
	if main == null or not main.has_method(method_name):
		_update_status("MainGame 缺少方法：%s" % method_name)
		return
	match args.size():
		0:
			main.call_deferred(method_name)
		1:
			main.call_deferred(method_name, args[0])
		2:
			main.call_deferred(method_name, args[0], args[1])
		_:
			_update_status("参数过多：%s" % method_name)
			return


func _transition_main(method_name: String, args: Array = []) -> void:
	_call_main(method_name, args)
	_close_panel()


func _main_scene() -> Node:
	return get_tree().current_scene


func _update_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _close_panel() -> void:
	cancelled.emit()
	queue_free()
