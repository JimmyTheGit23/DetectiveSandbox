extends PanelContainer
## 底部菜单栏（逆转裁判风格）
##
## 纯文字按钮横条：金色文字 + 深色半透明底条
## hover时文字变亮

signal menu_clicked(menu_id: String)

const LABELS = {
	"move": "移动",
	"talk": "对话",
	"search": "调查",
	"notebook": "笔记",
	"discuss": "讨论",
	"map": "地图",
}

const ORDER = ["move", "talk", "search", "notebook", "discuss", "map"]

var _btn_map: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_style()
	_build()
	GameManager.location_changed.connect(_on_location_changed)
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("refresh_visibility")


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.015, 0.82)
	style.border_color = Color(0.6, 0.45, 0.2, 0.65)
	style.border_width_top = 1
	style.border_width_bottom = 0
	style.border_width_left = 0
	style.border_width_right = 0
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	add_theme_stylebox_override("panel", style)


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_btn_map.clear()

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 0)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(hbox)

	for i in range(ORDER.size()):
		var menu_id: String = ORDER[i]

		var btn := Button.new()
		btn.text = LABELS.get(menu_id, menu_id)
		btn.flat = true
		btn.custom_minimum_size = Vector2(90, 40)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# 文字样式
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", Color(0.92, 0.78, 0.45, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.85, 0.35, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(0.92, 0.78, 0.45, 1.0))

		# hover背景
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.2, 0.15, 0.06, 0.4)
		hover_style.set_corner_radius_all(0)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.25, 0.18, 0.05, 0.6)
		pressed_style.set_corner_radius_all(0)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		# 正常状态无背景
		var normal_style := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		btn.pressed.connect(_on_pressed.bind(menu_id))
		hbox.add_child(btn)
		_btn_map[menu_id] = btn

		# 添加分隔线（最后一个不加）
		if i < ORDER.size() - 1:
			var sep := VSeparator.new()
			sep.custom_minimum_size = Vector2(1, 30)
			sep.add_theme_stylebox_override("separator", _make_sep_style())
			hbox.add_child(sep)


func _make_sep_style() -> StyleBoxLine:
	var s := StyleBoxLine.new()
	s.color = Color(0.55, 0.40, 0.18, 0.5)
	s.thickness = 1
	s.vertical = true
	return s


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


func _on_location_changed(_loc_id: String) -> void:
	refresh_visibility()


func _on_visibility_changed() -> void:
	if visible:
		refresh_visibility()


func _flash_locked_hint(hint: String) -> void:
	var lbl := Label.new()
	lbl.text = hint
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	lbl.position.y -= 40
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)
