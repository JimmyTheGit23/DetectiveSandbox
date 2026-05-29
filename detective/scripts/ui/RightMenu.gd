extends PanelContainer
## 底部菜单栏：案卷牌匾式分段按钮

signal menu_clicked(menu_id: String)

const LABELS = {
	"move": "移动",
	"talk": "对话",
	"search": "调查",
	"notebook": "笔记",
	"discuss": "讨论",
	"map": "地图",
}

const SUBLABELS = {
	"move": "行踪",
	"talk": "问讯",
	"search": "勘验",
	"notebook": "案牍",
	"discuss": "合议",
	"map": "舆图",
}

const ORDER = ["move", "talk", "search", "notebook", "discuss", "map"]
var UI_FONT: Font = null
const BUTTON_SIZE := Vector2(102, 56)

var _btn_map: Dictionary = {}
var _btn_tweens: Dictionary = {}


func _ready() -> void:
	# 动态加载字体
	if ResourceLoader.exists("res://assets/fonts/SourceHanMonoSC-Regular.otf"):
		UI_FONT = load("res://assets/fonts/SourceHanMonoSC-Regular.otf")
	elif ResourceLoader.exists("res://assets/fonts/NotoSerifSC.ttf"):
		UI_FONT = load("res://assets/fonts/NotoSerifSC.ttf")
	elif ResourceLoader.exists("res://assets/fonts/NotoSansSC.otf"):
		UI_FONT = load("res://assets/fonts/NotoSansSC.otf")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_style()
	_build()
	GameManager.location_changed.connect(_on_location_changed)
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("refresh_visibility")


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.012, 0.84)
	style.border_color = Color(0.62, 0.45, 0.18, 0.72)
	style.border_width_top = 2
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 0
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 24
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_btn_map.clear()
	_btn_tweens.clear()

	var rail := Panel.new()
	rail.name = "Rail"
	rail.custom_minimum_size = Vector2(0, 66)
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.add_theme_stylebox_override("panel", _make_rail_style())
	add_child(rail)

	var trim := ColorRect.new()
	trim.name = "TopTrim"
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trim.anchor_right = 1.0
	trim.offset_left = 24.0
	trim.offset_top = 9.0
	trim.offset_right = -24.0
	trim.offset_bottom = 11.0
	trim.color = Color(0.82, 0.62, 0.24, 0.52)
	rail.add_child(trim)

	var inner_glow := ColorRect.new()
	inner_glow.name = "InnerGlow"
	inner_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_glow.anchor_right = 1.0
	inner_glow.anchor_bottom = 1.0
	inner_glow.offset_left = 10.0
	inner_glow.offset_top = 10.0
	inner_glow.offset_right = -10.0
	inner_glow.offset_bottom = -10.0
	inner_glow.color = Color(0.33, 0.18, 0.06, 0.10)
	rail.add_child(inner_glow)

	var content := MarginContainer.new()
	content.name = "Content"
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.offset_left = 10.0
	content.offset_top = 8.0
	content.offset_right = -10.0
	content.offset_bottom = -8.0
	rail.add_child(content)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	content.add_child(hbox)

	for menu_id in ORDER:
		var btn := _build_menu_button(menu_id)
		hbox.add_child(btn)
		_btn_map[menu_id] = btn


func _build_menu_button(menu_id: String) -> Button:
	var btn := Button.new()
	btn.name = "%sButton" % menu_id.capitalize()
	btn.flat = false
	btn.text = ""
	btn.custom_minimum_size = BUTTON_SIZE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_stylebox_override("normal", _make_button_style(
		Color(0.135, 0.082, 0.04, 0.94),
		Color(0.56, 0.39, 0.15, 0.88),
		Color(0, 0, 0, 0.28),
		12,
		2
	))
	btn.add_theme_stylebox_override("hover", _make_button_style(
		Color(0.20, 0.11, 0.045, 0.98),
		Color(0.89, 0.68, 0.28, 1.0),
		Color(0.88, 0.65, 0.24, 0.22),
		18,
		2
	))
	btn.add_theme_stylebox_override("pressed", _make_button_style(
		Color(0.11, 0.064, 0.03, 0.98),
		Color(0.95, 0.77, 0.35, 1.0),
		Color(0, 0, 0, 0.14),
		8,
		1
	))
	btn.add_theme_stylebox_override("focus", _make_button_style(
		Color(0.18, 0.10, 0.042, 0.97),
		Color(0.84, 0.62, 0.24, 1.0),
		Color(0.84, 0.62, 0.24, 0.18),
		16,
		2
	))
	btn.add_theme_stylebox_override("disabled", _make_button_style(
		Color(0.095, 0.06, 0.032, 0.74),
		Color(0.34, 0.25, 0.14, 0.62),
		Color(0, 0, 0, 0.10),
		6,
		1
	))

	var content := Control.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(content)

	var ornament := ColorRect.new()
	ornament.name = "Ornament"
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ornament.anchor_left = 0.5
	ornament.anchor_right = 0.5
	ornament.offset_left = -14.0
	ornament.offset_top = 10.0
	ornament.offset_right = 14.0
	ornament.offset_bottom = 12.0
	content.add_child(ornament)

	var title := Label.new()
	title.name = "Title"
	title.text = LABELS.get(menu_id, menu_id)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.anchor_right = 1.0
	title.offset_top = 12.0
	title.offset_bottom = 38.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.86))
	title.add_theme_constant_override("outline_size", 2)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = SUBLABELS.get(menu_id, "")
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.anchor_right = 1.0
	subtitle.offset_top = 37.0
	subtitle.offset_bottom = 52.0
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.72))
	subtitle.add_theme_constant_override("outline_size", 1)
	content.add_child(subtitle)

	btn.set_meta("menu_id", menu_id)
	btn.set_meta("hovered", false)
	btn.set_meta("pressed_visual", false)
	btn.set_meta("title_label", title)
	btn.set_meta("subtitle_label", subtitle)
	btn.set_meta("ornament", ornament)

	btn.resized.connect(func() -> void:
		btn.pivot_offset = btn.size * 0.5
	)
	btn.mouse_entered.connect(func() -> void:
		btn.set_meta("hovered", true)
		_apply_button_visual(btn)
	)
	btn.mouse_exited.connect(func() -> void:
		btn.set_meta("hovered", false)
		btn.set_meta("pressed_visual", false)
		_apply_button_visual(btn)
	)
	btn.button_down.connect(func() -> void:
		btn.set_meta("pressed_visual", true)
		_apply_button_visual(btn)
	)
	btn.button_up.connect(func() -> void:
		btn.set_meta("pressed_visual", false)
		_apply_button_visual(btn)
	)
	btn.pressed.connect(_on_pressed.bind(menu_id))

	_apply_button_visual(btn, false)
	return btn


func _make_rail_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.028, 0.90)
	style.border_color = Color(0.43, 0.30, 0.12, 0.86)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 10
	return style


func _make_button_style(bg: Color, border: Color, shadow: Color, shadow_size: int, top_border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = top_border_width
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style


func _apply_button_visual(btn: Button, animate: bool = true) -> void:
	var menu_id := String(btn.get_meta("menu_id", ""))
	var hovered: bool = btn.get_meta("hovered", false)
	var pressed_visual: bool = btn.get_meta("pressed_visual", false)
	var unlocked := GameManager.is_panel_unlocked(menu_id)
	var title := btn.get_meta("title_label", null) as Label
	var subtitle := btn.get_meta("subtitle_label", null) as Label
	var ornament := btn.get_meta("ornament", null) as ColorRect
	var title_color := Color(0.94, 0.83, 0.58, 1.0)
	var subtitle_color := Color(0.72, 0.59, 0.36, 0.92)
	var ornament_color := Color(0.76, 0.57, 0.22, 0.90)
	var scale_target: Vector2 = Vector2.ONE

	if not unlocked:
		title_color = Color(0.70, 0.64, 0.55, 0.94)
		subtitle_color = Color(0.50, 0.45, 0.38, 0.92)
		ornament_color = Color(0.42, 0.31, 0.16, 0.76)
		btn.self_modulate = Color(0.90, 0.87, 0.82, 0.98)
		btn.tooltip_text = GameManager.get_panel_locked_hint(menu_id)
	else:
		btn.self_modulate = Color(1, 1, 1, 1)
		btn.tooltip_text = LABELS.get(menu_id, menu_id)

	if pressed_visual:
		title_color = Color(1.0, 0.88, 0.55, 1.0)
		subtitle_color = Color(0.83, 0.68, 0.38, 0.95)
		ornament_color = Color(0.97, 0.77, 0.31, 0.96)
		scale_target = Vector2(0.97, 0.97)
	elif hovered:
		title_color = Color(1.0, 0.94, 0.74, 1.0)
		subtitle_color = Color(0.90, 0.77, 0.50, 0.95)
		ornament_color = Color(1.0, 0.80, 0.36, 0.98)
		scale_target = Vector2(1.035, 1.035)

	if title:
		title.add_theme_color_override("font_color", title_color)
	if subtitle:
		subtitle.add_theme_color_override("font_color", subtitle_color)
	if ornament:
		ornament.color = ornament_color

	if animate:
		_animate_button(btn, scale_target, 0.16)
	else:
		btn.scale = scale_target


func _animate_button(btn: Control, target_scale: Vector2, duration: float) -> void:
	var key: int = btn.get_instance_id()
	var existing = _btn_tweens.get(key)
	if existing is Tween:
		existing.kill()
	btn.pivot_offset = btn.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, duration)
	_btn_tweens[key] = tween


func _on_pressed(menu_id: String) -> void:
	if not GameManager.is_panel_unlocked(menu_id):
		var hint := GameManager.get_panel_locked_hint(menu_id)
		if hint != "":
			_flash_locked_hint(hint)
		return
	menu_clicked.emit(menu_id)


func refresh_visibility() -> void:
	if not is_inside_tree():
		return
	if _btn_map.has("move"):
		_btn_map["move"].visible = true
	if _btn_map.has("discuss"):
		var cs = get_node_or_null("/root/CompanionService")
		_btn_map["discuss"].visible = cs != null and cs.has_method("has_companion") and cs.has_companion()
	for menu_id in ORDER:
		var btn = _btn_map.get(menu_id)
		if btn is Button:
			_apply_button_visual(btn, false)


func _on_location_changed(_loc_id: String) -> void:
	refresh_visibility()


func _on_visibility_changed() -> void:
	if visible:
		refresh_visibility()


func _flash_locked_hint(hint: String) -> void:
	var lbl := Label.new()
	lbl.text = hint
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	lbl.position.y -= 46
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)
