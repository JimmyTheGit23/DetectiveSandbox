extends Control

const DEFAULT_CENTER_PORTRAIT_FRAME := {
	"offset_left": -320.0,
	"offset_top": 60.0,
	"offset_right": 320.0,
	"offset_bottom": 0.0,
	"pivot_x": 320.0,
}
const DEFAULT_PORTRAIT_CROP_PADDING_RATIO := 0.02
const DEFAULT_PORTRAIT_CROP_MIN_PADDING := 8
const DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO := 0.78
const CENTER_NPC_LAYOUT_CSV_TEMPLATE := "res://data/case_tables/%s/center_npc_layouts.csv"
const LU_ZHAO_OFFICIAL_PREVIEW_ID := "lu_zhao_official"
const LU_ZHAO_OFFICIAL_PORTRAIT := "res://assets/cn/portraits/lu_zhao.png"
const COMPARE_SLOT_SHIFT_X := 330.0
const PREVIEW_SHELL_MARGIN_LEFT := 28.0
const PREVIEW_SHELL_MARGIN_RIGHT := 28.0
const PREVIEW_SHELL_MARGIN_TOP := 24.0
const PREVIEW_SHELL_MARGIN_BOTTOM := 24.0
const PREVIEW_BODY_SEPARATION := 18.0
const PREVIEW_SAFE_PADDING_X := 12.0
const CENTER_NPC_LAYOUT_HEADERS := [
	"npc_id",
	"enabled",
	"emotion",
	"portrait",
	"screen_scale",
	"offset_y",
	"pivot_y",
	"confrontation_screen_scale",
	"confrontation_offset_y",
	"writer_note",
]

var _background_rect: TextureRect
var _npc_select: OptionButton
var _emotion_select: OptionButton
var _compare_enabled_check: CheckBox
var _compare_npc_select: OptionButton
var _compare_emotion_select: OptionButton
var _background_select: OptionButton
var _scale_spin: SpinBox
var _offset_spin: SpinBox
var _pivot_spin: SpinBox
var _confrontation_scale_spin: SpinBox
var _confrontation_offset_spin: SpinBox
var _config_label: RichTextLabel
var _status_label: Label
var _portrait_rect: TextureRect
var _compare_portrait_rect: TextureRect
var _primary_guide: ColorRect
var _secondary_guide: ColorRect
var _primary_guide_line: ColorRect
var _secondary_guide_line: ColorRect
var _portrait_texture_cache: Dictionary = {}
var _preview_entries_by_id: Dictionary = {}
var _current_portrait_path := ""
var _current_compare_portrait_path := ""
var _suppress_layout_editor := false
var _center_portrait_frame: Dictionary = DEFAULT_CENTER_PORTRAIT_FRAME.duplicate(true)
var _control_panel: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_on_preview_resized)
	_refresh_center_portrait_frame()
	_build_ui()
	_refresh_all()
	call_deferred("_refresh_preview_stage_layout")


func _refresh_center_portrait_frame() -> void:
	_center_portrait_frame = DEFAULT_CENTER_PORTRAIT_FRAME.duplicate(true)
	if AssetResolver != null and AssetResolver.has_method("get_center_portrait_standard_frame"):
		var resolved = AssetResolver.get_center_portrait_standard_frame()
		if typeof(resolved) == TYPE_DICTIONARY and not resolved.is_empty():
			_center_portrait_frame = resolved.duplicate(true)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()


func _build_ui() -> void:
	var bg_dim := ColorRect.new()
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dim.color = Color(0.02, 0.02, 0.03, 1.0)
	bg_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_dim)

	_background_rect = TextureRect.new()
	_background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background_rect)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.03, 0.04, 0.28)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_primary_guide = _create_guide_rect()
	add_child(_primary_guide)
	_primary_guide_line = _create_guide_line()
	add_child(_primary_guide_line)
	_secondary_guide = _create_guide_rect()
	add_child(_secondary_guide)
	_secondary_guide_line = _create_guide_line()
	add_child(_secondary_guide_line)

	_portrait_rect = _create_portrait_rect()
	add_child(_portrait_rect)
	_compare_portrait_rect = _create_portrait_rect()
	add_child(_compare_portrait_rect)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", int(PREVIEW_SHELL_MARGIN_LEFT))
	shell.add_theme_constant_override("margin_right", int(PREVIEW_SHELL_MARGIN_RIGHT))
	shell.add_theme_constant_override("margin_top", int(PREVIEW_SHELL_MARGIN_TOP))
	shell.add_theme_constant_override("margin_bottom", int(PREVIEW_SHELL_MARGIN_BOTTOM))
	add_child(shell)

	var root := HBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", int(PREVIEW_BODY_SEPARATION))
	shell.add_child(root)

	_control_panel = PanelContainer.new()
	_control_panel.custom_minimum_size = Vector2(360, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.065, 0.05, 0.94)
	panel_style.border_color = Color(0.58, 0.42, 0.20, 0.86)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 18
	panel_style.content_margin_bottom = 18
	_control_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(_control_panel)

	var panel_scroll := ScrollContainer.new()
	panel_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_control_panel.add_child(panel_scroll)

	var panel_vbox := VBoxContainer.new()
	panel_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_vbox.add_theme_constant_override("separation", 14)
	panel_scroll.add_child(panel_vbox)

	var title := Label.new()
	title.text = "中央 NPC 立绘预览"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1.0))
	panel_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "选择一变即刷新，不依赖当前调查场景"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 0.92))
	panel_vbox.add_child(subtitle)

	_background_select = OptionButton.new()
	_background_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_background_select.item_selected.connect(_on_background_selected)
	panel_vbox.add_child(_make_labeled_row("背景", _background_select))

	_npc_select = OptionButton.new()
	_npc_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_npc_select.item_selected.connect(_on_npc_selected)
	panel_vbox.add_child(_make_labeled_row("NPC", _npc_select))

	_emotion_select = OptionButton.new()
	_emotion_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_emotion_select.item_selected.connect(_on_emotion_selected)
	panel_vbox.add_child(_make_labeled_row("表情", _emotion_select))

	_compare_enabled_check = CheckBox.new()
	_compare_enabled_check.text = "开启对比模式"
	_compare_enabled_check.toggled.connect(_on_compare_toggled)
	panel_vbox.add_child(_compare_enabled_check)

	_compare_npc_select = OptionButton.new()
	_compare_npc_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compare_npc_select.item_selected.connect(_on_compare_npc_selected)
	panel_vbox.add_child(_make_labeled_row("对比 NPC", _compare_npc_select))

	_compare_emotion_select = OptionButton.new()
	_compare_emotion_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compare_emotion_select.item_selected.connect(_on_compare_emotion_selected)
	panel_vbox.add_child(_make_labeled_row("对比表情", _compare_emotion_select))

	var layout_title := Label.new()
	layout_title.text = "布局参数"
	layout_title.add_theme_font_size_override("font_size", 18)
	layout_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.56, 1.0))
	panel_vbox.add_child(layout_title)

	_scale_spin = _make_spin_box(0.2, 2.0, 0.01)
	_scale_spin.value_changed.connect(_on_layout_value_changed)
	panel_vbox.add_child(_make_compact_labeled_row("screen_scale", _scale_spin))

	_offset_spin = _make_spin_box(-400.0, 400.0, 1.0)
	_offset_spin.value_changed.connect(_on_layout_value_changed)
	panel_vbox.add_child(_make_compact_labeled_row("offset_y", _offset_spin))

	_pivot_spin = _make_spin_box(0.0, 660.0, 1.0)
	_pivot_spin.value_changed.connect(_on_layout_value_changed)
	panel_vbox.add_child(_make_compact_labeled_row("pivot_y", _pivot_spin))

	_confrontation_scale_spin = _make_spin_box(0.2, 2.0, 0.01)
	_confrontation_scale_spin.value_changed.connect(_on_layout_value_changed)
	panel_vbox.add_child(_make_compact_labeled_row("confront_scale", _confrontation_scale_spin))

	_confrontation_offset_spin = _make_spin_box(-400.0, 400.0, 1.0)
	_confrontation_offset_spin.value_changed.connect(_on_layout_value_changed)
	panel_vbox.add_child(_make_compact_labeled_row("confront_offset_y", _confrontation_offset_spin))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	panel_vbox.add_child(button_row)

	var write_btn := _make_action_button("写入 CSV")
	write_btn.pressed.connect(_on_write_csv_pressed)
	button_row.add_child(write_btn)

	var reload_btn := _make_action_button("重载配置")
	reload_btn.pressed.connect(_on_reload_pressed)
	button_row.add_child(reload_btn)

	var close_btn := _make_action_button("返 回")
	close_btn.pressed.connect(queue_free)
	button_row.add_child(close_btn)

	_config_label = RichTextLabel.new()
	_config_label.bbcode_enabled = true
	_config_label.fit_content = false
	_config_label.scroll_active = true
	_config_label.custom_minimum_size = Vector2(0, 190)
	_config_label.add_theme_font_size_override("normal_font_size", 15)
	_config_label.add_theme_color_override("default_color", Color(0.88, 0.84, 0.78, 1.0))
	panel_vbox.add_child(_config_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	_status_label = Label.new()
	_status_label.anchor_left = 0.0
	_status_label.anchor_right = 1.0
	_status_label.anchor_top = 1.0
	_status_label.anchor_bottom = 1.0
	_status_label.offset_left = 40.0
	_status_label.offset_right = -40.0
	_status_label.offset_top = -30.0
	_status_label.offset_bottom = -8.0
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.90, 0.84, 0.72, 0.92))
	add_child(_status_label)


func _make_labeled_row(label_text: String, field: Control) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68, 0.96))
	row.add_child(label)
	row.add_child(field)
	return row


func _create_guide_rect() -> ColorRect:
	var guide := ColorRect.new()
	guide.anchor_left = 0.5
	guide.anchor_right = 0.5
	guide.anchor_top = 0.0
	guide.anchor_bottom = 1.0
	guide.color = Color(1.0, 0.85, 0.35, 0.08)
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return guide


func _create_guide_line() -> ColorRect:
	var guide_line := ColorRect.new()
	guide_line.anchor_left = 0.5
	guide_line.anchor_right = 0.5
	guide_line.anchor_top = 0.0
	guide_line.anchor_bottom = 1.0
	guide_line.offset_left = -1.0
	guide_line.offset_right = 1.0
	guide_line.color = Color(1.0, 0.88, 0.45, 0.28)
	guide_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return guide_line


func _create_portrait_rect() -> TextureRect:
	var rect := TextureRect.new()
	rect.anchor_left = 0.5
	rect.anchor_right = 0.5
	rect.anchor_bottom = 1.0
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := load("res://assets/cn/portrait_fade.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("fade_bottom", 0.0)
		mat.set_shader_parameter("fade_top", 0.0)
		mat.set_shader_parameter("fade_left", 0.10)
		mat.set_shader_parameter("fade_right", 0.10)
		rect.material = mat
	return rect


func _make_compact_labeled_row(label_text: String, field: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(110, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68, 0.96))
	row.add_child(label)
	row.add_child(field)
	return row


func _make_spin_box(min_value: float, max_value: float, step_value: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step_value
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin


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
	_refresh_backgrounds()
	_refresh_npcs()
	_refresh_compare_controls()
	_update_status("当前案件：%s" % GameManager.ACTIVE_CASE)


func _refresh_backgrounds() -> void:
	var previous := _selected_metadata(_background_select)
	_background_select.clear()
	var seen: Dictionary = {}
	for loc_id in GameManager.locations_data.keys():
		var loc := GameManager.get_location_data(str(loc_id))
		if loc.is_empty():
			continue
		var bg_path := AssetResolver.get_scene_background(loc)
		if bg_path == "" or seen.has(bg_path):
			continue
		seen[bg_path] = true
		var loc_name := str(loc.get("name", loc_id))
		_background_select.add_item("%s (%s)" % [loc_name, str(loc_id)])
		_background_select.set_item_metadata(_background_select.get_item_count() - 1, bg_path)
	if _background_select.get_item_count() <= 0:
		var fallback_bg := AssetResolver.get_scene_background_by_id("scene_title")
		if fallback_bg != "":
			_background_select.add_item("标题背景")
			_background_select.set_item_metadata(0, fallback_bg)
	_select_option_by_metadata(_background_select, previous)
	_update_background()


func _refresh_npcs() -> void:
	var previous_npc := _selected_metadata(_npc_select)
	var previous_compare_npc := _selected_metadata(_compare_npc_select)
	_npc_select.clear()
	_compare_npc_select.clear()
	_preview_entries_by_id.clear()
	var entries := _build_preview_npc_entries()
	for entry in entries:
		var npc_id := str(entry.get("id", ""))
		if npc_id == "":
			continue
		_preview_entries_by_id[npc_id] = entry
		var role_name := str(entry.get("name", npc_id))
		_npc_select.add_item("%s (%s)" % [role_name, npc_id])
		_npc_select.set_item_metadata(_npc_select.get_item_count() - 1, npc_id)
		_compare_npc_select.add_item("%s (%s)" % [role_name, npc_id])
		_compare_npc_select.set_item_metadata(_compare_npc_select.get_item_count() - 1, npc_id)
	_select_option_by_metadata(_npc_select, previous_npc)
	_select_option_by_metadata(_compare_npc_select, previous_compare_npc)
	_refresh_emotions()
	_refresh_compare_emotions()


func _build_preview_npc_entries() -> Array:
	var entries: Array = []
	var seen: Dictionary = {}
	for npc_id in GameManager.npcs_data.keys():
		var id := str(npc_id)
		if id.begins_with("_"):
			continue
		var portrait_path := AssetResolver.resolve_case_portrait(id, "base", GameManager.npcs_data)
		if portrait_path == "" or not ResourceLoader.exists(portrait_path):
			continue
		_append_preview_entry(entries, seen, id, _preview_name_for_npc(id), portrait_path)
	_append_preview_entry(entries, seen, LU_ZHAO_OFFICIAL_PREVIEW_ID, "陆昭·官服", LU_ZHAO_OFFICIAL_PORTRAIT)
	_append_companion_preview_entry(entries, seen)
	if AssetResolver != null and AssetResolver.has_method("get_center_npc_ids"):
		for npc_id in AssetResolver.get_center_npc_ids():
			var id := str(npc_id)
			if seen.has(id):
				continue
			var portrait_path := AssetResolver.resolve_case_portrait(id, "base", GameManager.npcs_data)
			if portrait_path == "" or not ResourceLoader.exists(portrait_path):
				continue
			_append_preview_entry(entries, seen, id, _preview_name_for_npc(id), portrait_path)
	return entries


func _append_companion_preview_entry(entries: Array, seen: Dictionary) -> void:
	var companion_id := "xia_lingyao"
	var companion_name := "凌瑶"
	var companion_service := get_node_or_null("/root/CompanionService")
	if companion_service != null:
		if companion_service.has_method("get_companion_id"):
			var service_id := str(companion_service.get_companion_id())
			if service_id != "":
				companion_id = service_id
		if companion_service.has_method("get_companion_role_name"):
			var service_name := str(companion_service.get_companion_role_name())
			if service_name != "":
				companion_name = service_name
	var portrait_path := AssetResolver.resolve_case_portrait(companion_id, "base", GameManager.npcs_data)
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		_append_preview_entry(entries, seen, companion_id, companion_name, portrait_path)


func _append_preview_entry(entries: Array, seen: Dictionary, npc_id: String, role_name: String, base_portrait: String = "") -> void:
	if npc_id == "" or seen.has(npc_id):
		return
	if base_portrait != "" and not ResourceLoader.exists(base_portrait):
		return
	seen[npc_id] = true
	entries.append({
		"id": npc_id,
		"name": role_name if role_name != "" else npc_id,
		"base_portrait": base_portrait,
	})


func _preview_name_for_npc(npc_id: String) -> String:
	var role_info := AssetResolver.get_role_info(npc_id, GameManager.npcs_data)
	return str(role_info.get("name", npc_id))


func _refresh_emotions() -> void:
	var previous := _selected_metadata(_emotion_select)
	_emotion_select.clear()
	var npc_id := _selected_metadata(_npc_select)
	var emotions: Array = []
	if npc_id != "":
		emotions = _preview_emotions_for(npc_id)
	if emotions.is_empty():
		emotions = ["base"]
	for emotion in emotions:
		var value := str(emotion)
		_emotion_select.add_item(value)
		_emotion_select.set_item_metadata(_emotion_select.get_item_count() - 1, value)
	_select_option_by_metadata(_emotion_select, previous)
	_update_preview()


func _refresh_compare_emotions() -> void:
	var previous := _selected_metadata(_compare_emotion_select)
	_compare_emotion_select.clear()
	var npc_id := _selected_metadata(_compare_npc_select)
	var emotions: Array = []
	if npc_id != "":
		emotions = _preview_emotions_for(npc_id)
	if emotions.is_empty():
		emotions = ["base"]
	for emotion in emotions:
		var value := str(emotion)
		_compare_emotion_select.add_item(value)
		_compare_emotion_select.set_item_metadata(_compare_emotion_select.get_item_count() - 1, value)
	_select_option_by_metadata(_compare_emotion_select, previous)
	if _compare_enabled_check != null and _compare_enabled_check.button_pressed and _selected_metadata(_compare_emotion_select) == "":
		_seed_compare_selection()
	_update_preview()


func _preview_emotions_for(npc_id: String) -> Array:
	var entry: Dictionary = _preview_entries_by_id.get(npc_id, {})
	var base_portrait := str(entry.get("base_portrait", ""))
	var emotions: Array = []
	if base_portrait != "" and AssetResolver.has_method("get_portrait_expression_emotions"):
		emotions = AssetResolver.get_portrait_expression_emotions(base_portrait)
	elif AssetResolver.has_method("get_case_portrait_emotions"):
		emotions = AssetResolver.get_case_portrait_emotions(npc_id, GameManager.npcs_data)
	if AssetResolver.has_method("get_center_npc_emotions"):
		for emotion in AssetResolver.get_center_npc_emotions(npc_id):
			if not emotions.has(str(emotion)):
				emotions.append(str(emotion))
	emotions.sort()
	if emotions.has("base"):
		emotions.erase("base")
		emotions.push_front("base")
	return emotions


func _update_background() -> void:
	var bg_path := _selected_metadata(_background_select)
	if bg_path != "" and ResourceLoader.exists(bg_path):
		_background_rect.texture = load(bg_path)
	else:
		_background_rect.texture = null


func _update_preview() -> void:
	var npc_id := _selected_metadata(_npc_select)
	var emotion := _selected_metadata(_emotion_select)
	if npc_id == "":
		_current_portrait_path = ""
		_portrait_rect.visible = false
		_compare_portrait_rect.visible = false
		_apply_preview_slot_visibility()
		_config_label.text = "当前案件没有可预览的中央 NPC。"
		return
	var portrait_path := _resolve_preview_portrait(npc_id, emotion)
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		_current_portrait_path = ""
		_portrait_rect.visible = false
		_compare_portrait_rect.visible = false
		_apply_preview_slot_visibility()
		_config_label.text = "没有找到对应立绘：%s / %s" % [npc_id, emotion]
		return
	var presentation := AssetResolver.get_center_portrait_surface_presentation("preview", npc_id, emotion, portrait_path)
	_current_portrait_path = portrait_path
	_set_layout_editor_values(presentation)
	_portrait_rect.texture = _load_portrait_texture(portrait_path)
	_apply_portrait_presentation(_portrait_rect, presentation, _slot_shift_x(false))
	_portrait_rect.visible = true
	_update_compare_preview()
	_apply_preview_slot_visibility()
	_refresh_config_label(presentation)


func _resolve_preview_portrait(npc_id: String, emotion: String) -> String:
	var entry: Dictionary = _preview_entries_by_id.get(npc_id, {})
	var base_portrait := str(entry.get("base_portrait", ""))
	if base_portrait != "" and AssetResolver.has_method("resolve_portrait_from_base"):
		return AssetResolver.resolve_portrait_from_base(base_portrait, emotion)
	return AssetResolver.resolve_case_portrait(npc_id, emotion, GameManager.npcs_data)


func _set_layout_editor_values(presentation: Dictionary) -> void:
	_suppress_layout_editor = true
	if _scale_spin != null:
		_scale_spin.value = float(presentation.get("screen_scale", 1.0))
	if _offset_spin != null:
		_offset_spin.value = float(presentation.get("offset_y", 0.0))
	if _pivot_spin != null:
		_pivot_spin.value = float(presentation.get("pivot_y", 330.0))
	if _confrontation_scale_spin != null:
		_confrontation_scale_spin.value = float(presentation.get("confrontation_screen_scale", presentation.get("screen_scale", 1.0)))
	if _confrontation_offset_spin != null:
		_confrontation_offset_spin.value = float(presentation.get("confrontation_offset_y", presentation.get("offset_y", 0.0)))
	_suppress_layout_editor = false


func _layout_from_editor() -> Dictionary:
	return {
		"screen_scale": float(_scale_spin.value) if _scale_spin != null else 1.0,
		"offset_y": float(_offset_spin.value) if _offset_spin != null else 0.0,
		"pivot_y": float(_pivot_spin.value) if _pivot_spin != null else 330.0,
		"confrontation_screen_scale": float(_confrontation_scale_spin.value) if _confrontation_scale_spin != null else (float(_scale_spin.value) if _scale_spin != null else 1.0),
		"confrontation_offset_y": float(_confrontation_offset_spin.value) if _confrontation_offset_spin != null else (float(_offset_spin.value) if _offset_spin != null else 0.0),
	}


func _apply_portrait_presentation(rect: TextureRect, presentation: Dictionary, slot_shift_x: float) -> void:
	if rect == null:
		return
	rect.offset_left = float(_center_portrait_frame.get("offset_left", -320.0)) + slot_shift_x
	var offset_y := float(presentation.get("offset_y", 0.0))
	rect.offset_top = float(_center_portrait_frame.get("offset_top", 60.0)) + offset_y
	rect.offset_right = float(_center_portrait_frame.get("offset_right", 320.0)) + slot_shift_x
	rect.offset_bottom = float(_center_portrait_frame.get("offset_bottom", 0.0)) + offset_y
	rect.pivot_offset = Vector2(float(_center_portrait_frame.get("pivot_x", 320.0)), float(presentation.get("pivot_y", 330.0)))
	var scale_value := float(presentation.get("screen_scale", 1.0))
	rect.scale = Vector2(scale_value, scale_value)


func _refresh_config_label(presentation: Dictionary) -> void:
	var npc_id := _selected_metadata(_npc_select)
	var emotion := _selected_metadata(_emotion_select)
	var entry: Dictionary = _preview_entries_by_id.get(npc_id, {})
	var role_name := str(entry.get("name", _preview_name_for_npc(npc_id)))
	var lines := [
		"[b]案件[/b]  %s" % GameManager.ACTIVE_CASE,
		"[b]主槽 NPC[/b]  %s (%s)" % [role_name, npc_id],
		"[b]主槽表情[/b]  %s" % emotion,
		"[b]主槽缩放[/b]  %.2f" % float(presentation.get("screen_scale", 1.0)),
		"[b]主槽上下 Offset[/b]  %.1f" % float(presentation.get("offset_y", 0.0)),
		"[b]主槽 Pivot Y[/b]  %.1f" % float(presentation.get("pivot_y", 330.0)),
		"[b]对峙缩放[/b]  %.2f" % float(presentation.get("confrontation_screen_scale", presentation.get("screen_scale", 1.0))),
		"[b]对峙上下 Offset[/b]  %.1f" % float(presentation.get("confrontation_offset_y", presentation.get("offset_y", 0.0))),
		"[b]主槽立绘[/b]",
		_current_portrait_path,
	]
	if _compare_enabled_check != null and _compare_enabled_check.button_pressed:
		var compare_npc_id := _selected_metadata(_compare_npc_select)
		var compare_emotion := _selected_metadata(_compare_emotion_select)
		if compare_npc_id != "":
			var compare_entry: Dictionary = _preview_entries_by_id.get(compare_npc_id, {})
			var compare_name := str(compare_entry.get("name", _preview_name_for_npc(compare_npc_id)))
			lines.append("")
			lines.append("[b]对比槽 NPC[/b]  %s (%s)" % [compare_name, compare_npc_id])
			lines.append("[b]对比槽表情[/b]  %s" % compare_emotion)
			if _current_compare_portrait_path != "":
				lines.append("[b]对比槽立绘[/b]")
				lines.append(_current_compare_portrait_path)
	_config_label.text = "\n".join(lines)


func _on_reload_pressed() -> void:
	GameManager.reload_current_case_tables()
	_refresh_all()
	_update_status("已重载立绘配置")


func _on_write_csv_pressed() -> void:
	_write_current_layout_to_csv()


func _on_background_selected(_index: int) -> void:
	_update_background()


func _on_npc_selected(_index: int) -> void:
	_refresh_emotions()


func _on_emotion_selected(_index: int) -> void:
	_update_preview()


func _on_compare_toggled(enabled: bool) -> void:
	_refresh_compare_controls()
	if enabled:
		_seed_compare_selection()
	_refresh_compare_emotions()
	_update_preview()


func _on_compare_npc_selected(_index: int) -> void:
	_refresh_compare_emotions()


func _on_compare_emotion_selected(_index: int) -> void:
	_update_preview()


func _on_layout_value_changed(_value: float) -> void:
	if _suppress_layout_editor:
		return
	if _current_portrait_path == "":
		return
	var presentation := _layout_from_editor()
	_apply_portrait_presentation(_portrait_rect, presentation, _slot_shift_x(false))
	_refresh_config_label(presentation)
	_write_current_layout_to_csv()


func _refresh_compare_controls() -> void:
	var enabled := _compare_enabled_check != null and _compare_enabled_check.button_pressed
	if _compare_npc_select != null:
		_compare_npc_select.disabled = not enabled
	if _compare_emotion_select != null:
		_compare_emotion_select.disabled = not enabled


func _seed_compare_selection() -> void:
	if _compare_npc_select == null or _compare_emotion_select == null:
		return
	var primary_npc := _selected_metadata(_npc_select)
	var primary_emotion := _selected_metadata(_emotion_select)
	if primary_npc == "":
		return
	_select_option_by_metadata(_compare_npc_select, primary_npc)
	_compare_emotion_select.clear()
	var emotions := _preview_emotions_for(primary_npc)
	if emotions.is_empty():
		emotions = ["base"]
	for emotion in emotions:
		var value := str(emotion)
		_compare_emotion_select.add_item(value)
		_compare_emotion_select.set_item_metadata(_compare_emotion_select.get_item_count() - 1, value)
	var compare_emotion := primary_emotion
	if emotions.size() > 1:
		var primary_idx := emotions.find(primary_emotion)
		if primary_idx >= 0:
			compare_emotion = str(emotions[(primary_idx + 1) % emotions.size()])
		else:
			compare_emotion = str(emotions[0])
	_select_option_by_metadata(_compare_emotion_select, compare_emotion)


func _update_compare_preview() -> void:
	_current_compare_portrait_path = ""
	if _compare_enabled_check == null or not _compare_enabled_check.button_pressed:
		_compare_portrait_rect.visible = false
		return
	var npc_id := _selected_metadata(_compare_npc_select)
	var emotion := _selected_metadata(_compare_emotion_select)
	if npc_id == "":
		_compare_portrait_rect.visible = false
		return
	var portrait_path := _resolve_preview_portrait(npc_id, emotion)
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		_compare_portrait_rect.visible = false
		return
	var presentation := AssetResolver.get_center_portrait_surface_presentation("preview", npc_id, emotion, portrait_path)
	_current_compare_portrait_path = portrait_path
	_compare_portrait_rect.texture = _load_portrait_texture(portrait_path)
	_apply_portrait_presentation(_compare_portrait_rect, presentation, _slot_shift_x(true))
	_compare_portrait_rect.visible = true


func _apply_preview_slot_visibility() -> void:
	var compare_enabled := _compare_enabled_check != null and _compare_enabled_check.button_pressed
	_apply_guide_layout(_primary_guide, _primary_guide_line, _slot_shift_x(false))
	if compare_enabled:
		_apply_guide_layout(_secondary_guide, _secondary_guide_line, _slot_shift_x(true))
		_secondary_guide.visible = true
		_secondary_guide_line.visible = true
	else:
		_secondary_guide.visible = false
		_secondary_guide_line.visible = false
	if _compare_portrait_rect != null and not compare_enabled:
		_compare_portrait_rect.visible = false


func _apply_guide_layout(guide: ColorRect, guide_line: ColorRect, slot_shift_x: float) -> void:
	if guide != null:
		guide.offset_left = float(_center_portrait_frame.get("offset_left", -320.0)) + slot_shift_x
		guide.offset_right = float(_center_portrait_frame.get("offset_right", 320.0)) + slot_shift_x
		guide.offset_top = float(_center_portrait_frame.get("offset_top", 60.0))
		guide.offset_bottom = float(_center_portrait_frame.get("offset_bottom", 0.0))
	if guide_line != null:
		guide_line.offset_left = slot_shift_x - 1.0
		guide_line.offset_right = slot_shift_x + 1.0


func _slot_shift_x(is_compare_slot: bool) -> float:
	var slot_center_x := _slot_center_x(is_compare_slot)
	return slot_center_x - (size.x * 0.5)


func _slot_center_x(is_compare_slot: bool) -> float:
	var preview_bounds := _preview_bounds()
	var preview_center_x := (preview_bounds.x + preview_bounds.y) * 0.5
	var frame_left := float(_center_portrait_frame.get("offset_left", -320.0))
	var frame_right := float(_center_portrait_frame.get("offset_right", 320.0))
	var min_center_x := preview_bounds.x - frame_left
	var max_center_x := preview_bounds.y - frame_right
	if min_center_x > max_center_x:
		var collapsed_center := (min_center_x + max_center_x) * 0.5
		return collapsed_center
	var compare_enabled := _compare_enabled_check != null and _compare_enabled_check.button_pressed
	if not compare_enabled:
		return clampf(preview_center_x, min_center_x, max_center_x)
	var desired_center_x := preview_center_x + (COMPARE_SLOT_SHIFT_X if is_compare_slot else -COMPARE_SLOT_SHIFT_X)
	return clampf(desired_center_x, min_center_x, max_center_x)


func _preview_bounds() -> Vector2:
	var panel_width := 360.0
	if _control_panel != null:
		panel_width = maxf(_control_panel.size.x, _control_panel.custom_minimum_size.x)
	var left_bound := PREVIEW_SHELL_MARGIN_LEFT + panel_width + PREVIEW_BODY_SEPARATION + PREVIEW_SAFE_PADDING_X
	var right_bound := size.x - PREVIEW_SHELL_MARGIN_RIGHT - PREVIEW_SAFE_PADDING_X
	if right_bound < left_bound:
		var midpoint := size.x * 0.5
		return Vector2(midpoint, midpoint)
	return Vector2(left_bound, right_bound)


func _refresh_preview_stage_layout() -> void:
	_apply_preview_slot_visibility()
	if _current_portrait_path != "":
		_apply_portrait_presentation(_portrait_rect, _layout_from_editor(), _slot_shift_x(false))
	if _current_compare_portrait_path != "" and _compare_portrait_rect != null and _compare_portrait_rect.visible:
		var compare_npc_id := _selected_metadata(_compare_npc_select)
		var compare_emotion := _selected_metadata(_compare_emotion_select)
		var compare_presentation := AssetResolver.get_center_portrait_surface_presentation(
			"preview",
			compare_npc_id,
			compare_emotion,
			_current_compare_portrait_path
		)
		_apply_portrait_presentation(_compare_portrait_rect, compare_presentation, _slot_shift_x(true))


func _on_preview_resized() -> void:
	_refresh_preview_stage_layout()


func _selected_metadata(opt: OptionButton) -> String:
	if opt == null or opt.get_item_count() <= 0:
		return ""
	var idx := opt.selected
	if idx < 0:
		idx = 0
	return str(opt.get_item_metadata(idx))


func _select_option_by_metadata(opt: OptionButton, value: String) -> void:
	if opt == null or value == "":
		return
	for idx in range(opt.get_item_count()):
		if str(opt.get_item_metadata(idx)) == value:
			opt.select(idx)
			return
	if opt.get_item_count() > 0 and opt.selected < 0:
		opt.select(0)


func _update_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _write_current_layout_to_csv() -> bool:
	var npc_id := _selected_metadata(_npc_select)
	var emotion := _selected_metadata(_emotion_select)
	if npc_id == "" or emotion == "" or _current_portrait_path == "":
		_update_status("没有可写入的立绘配置")
		return false
	var csv_path := _center_layout_csv_path()
	var table := _read_center_layout_csv(csv_path)
	if not bool(table.get("ok", true)):
		return false
	var headers: Array = table.get("headers", CENTER_NPC_LAYOUT_HEADERS.duplicate())
	_ensure_center_layout_headers(headers)
	var rows: Array = table.get("rows", [])
	var row_index := _find_center_layout_row(rows, npc_id, emotion, _current_portrait_path)
	var row: Dictionary = rows[row_index].duplicate() if row_index >= 0 else {}
	var enabled_text := str(row.get("enabled", "True")).strip_edges()
	if enabled_text == "":
		enabled_text = "True"
	row["npc_id"] = npc_id
	row["enabled"] = enabled_text
	row["emotion"] = emotion
	row["portrait"] = _current_portrait_path
	row["screen_scale"] = _format_layout_float(float(_scale_spin.value), 2)
	row["offset_y"] = _format_layout_float(float(_offset_spin.value), 1)
	row["pivot_y"] = _format_layout_float(float(_pivot_spin.value), 1)
	row["confrontation_screen_scale"] = _format_layout_float(
		float(_confrontation_scale_spin.value) if _confrontation_scale_spin != null else float(_scale_spin.value),
		2
	)
	row["confrontation_offset_y"] = _format_layout_float(
		float(_confrontation_offset_spin.value) if _confrontation_offset_spin != null else float(_offset_spin.value),
		1
	)
	if not row.has("writer_note"):
		row["writer_note"] = ""
	if row_index >= 0:
		rows[row_index] = row
	else:
		rows.append(row)
	if not _write_center_layout_csv(csv_path, headers, rows):
		return false
	var presentation := _layout_from_editor()
	if AssetResolver != null and AssetResolver.has_method("set_center_portrait_layout"):
		AssetResolver.set_center_portrait_layout(npc_id, emotion, _current_portrait_path, presentation)
	CaseTableLoader.clear_cache()
	_update_status("已写入 CSV：%s / %s" % [npc_id, emotion])
	return true


func _center_layout_csv_path() -> String:
	return CENTER_NPC_LAYOUT_CSV_TEMPLATE % GameManager.ACTIVE_CASE


func _read_center_layout_csv(path: String) -> Dictionary:
	var headers: Array = CENTER_NPC_LAYOUT_HEADERS.duplicate()
	var rows: Array = []
	if not FileAccess.file_exists(path):
		return {"ok": true, "headers": headers, "rows": rows}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_update_status("无法读取 CSV：%s" % path)
		return {"ok": false, "headers": headers, "rows": rows}
	var raw_headers := Array(f.get_csv_line())
	if not raw_headers.is_empty():
		headers = []
		for idx in range(raw_headers.size()):
			var key := str(raw_headers[idx]).strip_edges()
			if idx == 0 and key.length() > 0 and key.unicode_at(0) == 0xfeff:
				key = key.substr(1)
			if key != "":
				headers.append(key)
	while not f.eof_reached():
		var values := Array(f.get_csv_line())
		var has_value := false
		for value in values:
			if str(value).strip_edges() != "":
				has_value = true
				break
		if not has_value:
			continue
		if not values.is_empty() and str(values[0]).strip_edges().begins_with("#"):
			continue
		var row := {}
		for idx in range(headers.size()):
			row[str(headers[idx])] = values[idx] if idx < values.size() else ""
		rows.append(row)
	return {"ok": true, "headers": headers, "rows": rows}


func _ensure_center_layout_headers(headers: Array) -> void:
	for header in CENTER_NPC_LAYOUT_HEADERS:
		if not headers.has(header):
			headers.append(header)


func _find_center_layout_row(rows: Array, npc_id: String, emotion: String, portrait_path: String) -> int:
	var fallback_idx := -1
	for idx in range(rows.size()):
		var row = rows[idx]
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str(row.get("npc_id", "")) != npc_id or str(row.get("emotion", "")) != emotion:
			continue
		if str(row.get("portrait", "")) == portrait_path:
			return idx
		if fallback_idx < 0:
			fallback_idx = idx
	return fallback_idx


func _write_center_layout_csv(path: String, headers: Array, rows: Array) -> bool:
	var dir_path := ProjectSettings.globalize_path(path.get_base_dir())
	if dir_path != "":
		DirAccess.make_dir_recursive_absolute(dir_path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_update_status("无法写入 CSV：%s" % path)
		return false
	var header_cells := PackedStringArray()
	for header in headers:
		header_cells.append(str(header))
	f.store_csv_line(header_cells)
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var cells := PackedStringArray()
		for header in headers:
			cells.append(str(row.get(str(header), "")))
		f.store_csv_line(cells)
	return true


func _format_layout_float(value: float, digits: int) -> String:
	if digits <= 1:
		return "%.1f" % value
	return "%.2f" % value


func _load_portrait_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var cache_key := _portrait_cache_key(path)
	var cached = _portrait_texture_cache.get(cache_key, null)
	if cached is Texture2D:
		return cached
	var texture := _load_source_portrait_texture(path)
	if texture == null:
		texture = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if texture == null:
		return null
	var normalized := _crop_texture_to_visible_alpha(texture)
	_portrait_texture_cache[cache_key] = normalized
	return normalized


func _load_source_portrait_texture(path: String) -> Texture2D:
	var source_path := ProjectSettings.globalize_path(path)
	if source_path == "" or not FileAccess.file_exists(source_path):
		return null
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _portrait_cache_key(path: String) -> String:
	var modified_time := FileAccess.get_modified_time(path)
	if modified_time == 0:
		modified_time = FileAccess.get_modified_time(ProjectSettings.globalize_path(path))
	return "%s:%d" % [path, modified_time]


func _crop_texture_to_visible_alpha(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image == null:
		return texture
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return texture
	var image_size := image.get_size()
	var normalize_cfg := _get_portrait_normalize_config()
	if float(used.size.y) / float(image_size.y) < float(normalize_cfg.get("crop_min_height_ratio", DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO)):
		return texture
	var pad_ratio := float(normalize_cfg.get("crop_padding_ratio", DEFAULT_PORTRAIT_CROP_PADDING_RATIO))
	var min_padding := int(normalize_cfg.get("crop_min_padding", DEFAULT_PORTRAIT_CROP_MIN_PADDING))
	var pad_x: int = max(min_padding, int(ceil(float(used.size.x) * pad_ratio)))
	var pad_y: int = max(min_padding, int(ceil(float(used.size.y) * pad_ratio)))
	var x1: int = max(0, used.position.x - pad_x)
	var y1: int = max(0, used.position.y - pad_y)
	var x2: int = min(image_size.x, used.position.x + used.size.x + pad_x)
	var y2: int = min(image_size.y, used.position.y + used.size.y + pad_y)
	if x1 == 0 and y1 == 0 and x2 == image_size.x and y2 == image_size.y:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(x1), float(y1), float(x2 - x1), float(y2 - y1))
	return atlas


func _get_portrait_normalize_config() -> Dictionary:
	if AssetResolver != null and AssetResolver.has_method("get_center_portrait_texture_normalize_config"):
		var resolved = AssetResolver.get_center_portrait_texture_normalize_config("preview")
		if typeof(resolved) == TYPE_DICTIONARY and not resolved.is_empty():
			return resolved
	return {
		"crop_padding_ratio": DEFAULT_PORTRAIT_CROP_PADDING_RATIO,
		"crop_min_padding": DEFAULT_PORTRAIT_CROP_MIN_PADDING,
		"crop_min_height_ratio": DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO,
	}
