extends Control
## 笔记本面板：证物 / 线索 / 人物 三个 Tab

signal close_requested()

@onready var bg: ColorRect = $Bg
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/Title
@onready var tab_container: TabContainer = $Panel/Tabs
@onready var close_btn: Button = $Panel/CloseBtn

var _detail_overlay: PanelContainer


func _ready() -> void:
	_style_root()
	close_btn.pressed.connect(func(): close_requested.emit())
	_create_detail_overlay()
	_build_evidence_tab()
	_build_clue_tab()
	_build_people_tab()


func _input(event: InputEvent) -> void:
	if _detail_overlay.visible and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var rect := _detail_overlay.get_global_rect()
			if not rect.has_point(event.global_position):
				_detail_overlay.visible = false


func _style_root() -> void:
	bg.color = Color(0, 0, 0, 0.62)
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.058, 0.04, 0.96)
	panel_style.border_color = Color(0.68, 0.52, 0.25, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.65)
	panel_style.shadow_size = 22
	panel.add_theme_stylebox_override("panel", panel_style)
	
	title_label.text = "案 牍 笔 记"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1))
	
	close_btn.flat = true
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55, 1))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72, 1))
	
	tab_container.add_theme_font_size_override("font_size", 21)
	tab_container.add_theme_color_override("font_selected_color", Color(1.0, 0.86, 0.5, 1))
	tab_container.add_theme_color_override("font_unselected_color", Color(0.75, 0.68, 0.56, 0.95))


func _make_scroll_panel(title: String) -> GridContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(grid)
	return grid


func _make_portrait_avatar(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var img: Image = texture.get_image()
	if img == null:
		return texture
	var w: int = img.get_width()
	var h: int = img.get_height()
	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1
	var step: int = 4
	var yy: int = 0
	while yy < h:
		var xx: int = 0
		while xx < w:
			if img.get_pixel(xx, yy).a > 0.04:
				if xx < min_x: min_x = xx
				if yy < min_y: min_y = yy
				if xx > max_x: max_x = xx
				if yy > max_y: max_y = yy
			xx += step
		yy += step
	var has_alpha_region: bool = (max_x >= 0) and (min_x > 0 or min_y > 0 or max_x < w - 1 or max_y < h - 1)
	var crop_x: int
	var crop_y: int
	var crop_w: int
	if has_alpha_region:
		var bbox_h: float = float(max_y - min_y + 1)
		var bbox_w: float = float(max_x - min_x + 1)
		var side: float = min(bbox_h * 0.42, bbox_w)
		crop_w = int(side)
		var center_x: float = float(min_x + max_x) * 0.5
		crop_x = int(center_x - side * 0.5)
		crop_y = int(float(min_y) - bbox_h * 0.02)
		if crop_x < 0: crop_x = 0
		if crop_y < 0: crop_y = 0
		if crop_x + crop_w > w: crop_x = w - crop_w
		if crop_y + crop_w > h: crop_y = h - crop_w
	else:
		var side2: int = mini(w, h)
		crop_w = mini(side2, int(h * 0.42))
		crop_x = int((w - crop_w) * 0.5)
		crop_y = int(h * 0.02)
	var cropped := img.get_region(Rect2i(crop_x, crop_y, crop_w, crop_w))
	cropped.resize(96, 96, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(cropped)


func _show_detail(title: String, body: String, color: Color, tag: String, portrait_path: String) -> void:
	if has_node("DetailOverlay"):
		return

	var overlay := Control.new()
	overlay.name = "DetailOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var blocker := ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.55)
	blocker.anchor_right = 1.0
	blocker.anchor_bottom = 1.0
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(blocker)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(card)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.10, 0.075, 0.05, 0.98)
	card_style.border_color = Color(0.68, 0.52, 0.25, 0.95)
	card_style.set_border_width_all(2)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.shadow_color = Color(0, 0, 0, 0.7)
	card_style.shadow_size = 28
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 20
	card_style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", card_style)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 14)
	card.add_child(card_vbox)

	var top_hbox := HBoxContainer.new()
	card_vbox.add_child(top_hbox)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)
	var close_btn := Button.new()
	close_btn.flat = true
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55, 1))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72, 1))
	close_btn.pressed.connect(func() -> void: overlay.queue_free())
	top_hbox.add_child(close_btn)

	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 16)
	card_vbox.add_child(info_hbox)

	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait_frame := PanelContainer.new()
		portrait_frame.custom_minimum_size = Vector2(96, 96)
		var pstyle := StyleBoxFlat.new()
		pstyle.bg_color = Color(0.04, 0.035, 0.025, 1)
		pstyle.border_color = Color(0.62, 0.46, 0.22, 0.95)
		pstyle.set_border_width_all(1)
		pstyle.corner_radius_top_left = 8
		pstyle.corner_radius_top_right = 8
		pstyle.corner_radius_bottom_left = 8
		pstyle.corner_radius_bottom_right = 8
		pstyle.content_margin_left = 4
		pstyle.content_margin_right = 4
		pstyle.content_margin_top = 4
		pstyle.content_margin_bottom = 4
		portrait_frame.add_theme_stylebox_override("panel", pstyle)
		info_hbox.add_child(portrait_frame)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(88, 88)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = _make_portrait_avatar(load(portrait_path))
		portrait_frame.add_child(portrait)

	var title_vbox := VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 8)
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_hbox.add_child(title_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	title_vbox.add_child(header)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", color)
	header.add_child(t)

	if tag != "":
		var badge := Label.new()
		badge.text = "  %s  " % tag
		badge.add_theme_font_size_override("font_size", 14)
		badge.add_theme_color_override("font_color", Color(0.18, 0.12, 0.05, 1))
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = color
		badge_style.corner_radius_top_left = 10
		badge_style.corner_radius_top_right = 10
		badge_style.corner_radius_bottom_left = 10
		badge_style.corner_radius_bottom_right = 10
		badge.add_theme_stylebox_override("normal", badge_style)
		header.add_child(badge)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.72, 0.55, 0.27, 0.4)
	card_vbox.add_child(sep)

	var desc := RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.scroll_active = false
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = body
	desc.add_theme_font_size_override("normal_font_size", 18)
	desc.add_theme_color_override("default_color", Color(0.88, 0.84, 0.74, 1))
	card_vbox.add_child(desc)

	blocker.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			overlay.queue_free()
	)


func _add_entry(parent: Container, title: String, body: String, color: Color = Color(1, 0.9, 0.6, 1), tag := "", portrait_path := "") -> void:
	var pc := Button.new()
	pc.text = ""
	pc.focus_mode = Control.FOCUS_NONE
	pc.custom_minimum_size = Vector2(300, 80)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.10, 0.07, 0.92)
	style.border_color = Color(0.48, 0.36, 0.18, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	pc.add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.18, 0.13, 0.08, 0.96)
	hover_style.border_color = Color(0.78, 0.58, 0.25, 1)
	pc.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.10, 0.075, 0.05, 0.98)
	pressed_style.border_color = Color(1.0, 0.78, 0.35, 1)
	pc.add_theme_stylebox_override("pressed", pressed_style)
	parent.add_child(pc)

	var content := Control.new()
	content.size = Vector2(300, 80)
	content.custom_minimum_size = Vector2(300, 80)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(content)

	var name_x := 14.0
	var name_w := 230.0
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait_frame := PanelContainer.new()
		portrait_frame.position = Vector2(10, 14)
		portrait_frame.size = Vector2(52, 52)
		portrait_frame.custom_minimum_size = Vector2(52, 52)
		portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait_style := StyleBoxFlat.new()
		portrait_style.bg_color = Color(0.04, 0.035, 0.025, 1)
		portrait_style.border_color = Color(0.62, 0.46, 0.22, 0.95)
		portrait_style.set_border_width_all(1)
		portrait_style.corner_radius_top_left = 4
		portrait_style.corner_radius_top_right = 4
		portrait_style.corner_radius_bottom_left = 4
		portrait_style.corner_radius_bottom_right = 4
		portrait_style.content_margin_left = 2
		portrait_style.content_margin_right = 2
		portrait_style.content_margin_top = 2
		portrait_style.content_margin_bottom = 2
		portrait_frame.add_theme_stylebox_override("panel", portrait_style)
		content.add_child(portrait_frame)

		var portrait := TextureRect.new()
		portrait.size = Vector2(48, 48)
		portrait.custom_minimum_size = Vector2(48, 48)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = _make_portrait_avatar(load(portrait_path))
		portrait_frame.add_child(portrait)
		name_x = 72.0
		name_w = 174.0

	var t := Label.new()
	t.position = Vector2(name_x, 27)
	t.size = Vector2(name_w, 26)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.text = title
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.add_theme_font_size_override("font_size", 17)
	t.add_theme_color_override("font_color", color)
	content.add_child(t)

	if tag != "":
		var badge := Label.new()
		badge.position = Vector2(252, 30)
		badge.size = Vector2(38, 20)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.text = tag
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color(0.18, 0.12, 0.05, 1))
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = color
		badge_style.corner_radius_top_left = 8
		badge_style.corner_radius_top_right = 8
		badge_style.corner_radius_bottom_left = 8
		badge_style.corner_radius_bottom_right = 8
		badge.add_theme_stylebox_override("normal", badge_style)
		content.add_child(badge)

	pc.pressed.connect(func() -> void:
		_show_detail(title, body, color, tag, portrait_path)
	)


func _add_empty_state(parent: Container, text: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 80)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	var lbl := Label.new()
	lbl.text = "◇  %s  ◇" % text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.72, 0.55, 0.85))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(lbl)


func _build_evidence_tab() -> void:
	_build_grid_tab("证 物", GameManager.collected_evidence, Color(1, 0.67, 0.46, 1), "证物", "尚无证物")


func _build_clue_tab() -> void:
	_build_grid_tab("线 索", GameManager.collected_clues, Color(1, 0.84, 0.50, 1), "线索", "尚无线索")


func _build_people_tab() -> void:
	var flow := _make_scroll_panel("人 物")
	var seen: Array = []
	for loc_id in GameManager.visited_locations:
		var npcs: Array = GameManager.get_location_data(loc_id).get("npcs", [])
		for n in npcs:
			if not seen.has(n):
				seen.append(n)
	if seen.is_empty():
		_add_empty_state(flow, "尚未结识人物")
		return
	for nid in seen:
		var data = GameManager.get_npc_data(nid)
		var lies_exposed: Array = []
		for flag in GameManager.dialogue_flags.keys():
			if flag.begins_with("lie_exposed:%s." % nid):
				var ln: String = flag.substr(("lie_exposed:%s." % nid).length())
				lies_exposed.append(ln)
		var body: String = data.get("intro", "")
		# 通过 AssetResolver 解析角色信息（casting 优先），保证笔记本展示的是剧本身份
		var role_info: Dictionary = AssetResolver.get_role_info(nid, GameManager.npcs_data)
		var role_name: String = role_info.get("name", data.get("name", nid))
		var role_title: String = role_info.get("title", data.get("title", ""))
		var role_intro: String = role_info.get("intro", "")
		if role_intro != "":
			body = role_intro
		var portrait_path: String = AssetResolver.get_portrait(nid, GameManager.npcs_data)
		if lies_exposed.size() > 0:
			body += "\n\n[color=#ffaa55]【已识破谎言】[/color]"
			for ln in lies_exposed:
				body += "\n  · %s" % ln
		_add_entry(vbox, "%s ｜ %s" % [role_name, role_title], body, Color(0.72, 0.95, 0.72, 1), "人物", portrait_path)


func _build_grid_tab(title: String, items: Array, color: Color, tag: String, empty_text: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)

	if items.is_empty():
		var vbox := VBoxContainer.new()
		margin.add_child(vbox)
		_add_empty_state(vbox, empty_text)
		return

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 14)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(flow)

	for item_id in items:
		var data = GameManager.evidence_data.get(item_id, {})
		_add_grid_item(flow, item_id, data.get("name", item_id), data.get("description", ""), color, tag, data.get("icon", ""))


func _add_grid_item(parent: HFlowContainer, id: String, name_text: String, desc: String, color: Color, tag: String, icon_path: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(100, 130)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	btn.add_theme_constant_override("icon_max_width", 64)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.72, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.65, 0.55, 1))
	btn.clip_text = true

	# 默认图标
	var default_icon := "res://assets/ai_processed/objects/evidence_marker.png"
	if icon_path == "" or not ResourceLoader.exists(icon_path):
		icon_path = default_icon
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)

	btn.text = name_text
	btn.pressed.connect(func(): _show_detail(id, name_text, desc, color, tag))

	# 样式
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.10, 0.07, 0.92)
	style.border_color = Color(0.48, 0.36, 0.18, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = Color(0.22, 0.17, 0.10, 0.95)
	hover_style.border_color = Color(0.72, 0.55, 0.27, 0.95)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = Color(0.08, 0.06, 0.04, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	parent.add_child(btn)


func _create_detail_overlay() -> void:
	_detail_overlay = PanelContainer.new()
	_detail_overlay.visible = false
	_detail_overlay.anchors_preset = Control.PRESET_CENTER
	_detail_overlay.custom_minimum_size = Vector2(440, 0)
	add_child(_detail_overlay)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.98)
	style.border_color = Color(0.72, 0.55, 0.27, 0.95)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 20
	_detail_overlay.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.name = "DetailMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_detail_overlay.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "DetailVBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# 关闭按钮行
	var close_hbox := HBoxContainer.new()
	vbox.add_child(close_hbox)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_hbox.add_child(spacer)

	var close_btn2 := Button.new()
	close_btn2.flat = true
	close_btn2.text = "✕"
	close_btn2.add_theme_font_size_override("font_size", 22)
	close_btn2.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55, 1))
	close_btn2.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72, 1))
	close_btn2.pressed.connect(func(): _detail_overlay.visible = false)
	close_hbox.add_child(close_btn2)

	# 标题
	var title_label2 := Label.new()
	title_label2.name = "DetailTitle"
	title_label2.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label2)

	# 标签
	var tag_label := Label.new()
	tag_label.name = "DetailTag"
	tag_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(tag_label)

	# 分隔线
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = Color(0.72, 0.55, 0.27, 0.35)
	vbox.add_child(line)

	# 描述
	var desc_rtl := RichTextLabel.new()
	desc_rtl.name = "DetailDesc"
	desc_rtl.bbcode_enabled = true
	desc_rtl.fit_content = true
	desc_rtl.scroll_active = false
	desc_rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_rtl.add_theme_font_size_override("normal_font_size", 17)
	desc_rtl.add_theme_color_override("default_color", Color(0.88, 0.84, 0.74, 1))
	vbox.add_child(desc_rtl)


func _show_detail(_id: String, title: String, desc: String, color: Color, tag: String) -> void:
	var title_lbl: Label = _detail_overlay.find_child("DetailTitle", true, false)
	var tag_lbl: Label = _detail_overlay.find_child("DetailTag", true, false)
	var desc_rtl: RichTextLabel = _detail_overlay.find_child("DetailDesc", true, false)

	title_lbl.text = title
	title_lbl.add_theme_color_override("font_color", color)

	tag_lbl.text = "  %s  " % tag
	tag_lbl.add_theme_color_override("font_color", Color(0.18, 0.12, 0.05, 1))
	var tag_style := StyleBoxFlat.new()
	tag_style.bg_color = color
	tag_style.corner_radius_top_left = 10
	tag_style.corner_radius_top_right = 10
	tag_style.corner_radius_bottom_left = 10
	tag_style.corner_radius_bottom_right = 10
	tag_lbl.add_theme_stylebox_override("normal", tag_style)

	desc_rtl.text = desc

	_update_overlay_layout.call_deferred()


func _update_overlay_layout() -> void:
	var min_size := _detail_overlay.get_combined_minimum_size()
	var w := max(min_size.x, 440)
	var h := min_size.y
	_detail_overlay.size = Vector2(w, h)
	_detail_overlay.offset_left = -w / 2
	_detail_overlay.offset_right = w / 2
	_detail_overlay.offset_top = -h / 2
	_detail_overlay.offset_bottom = h / 2
	_detail_overlay.visible = true
