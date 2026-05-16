extends Control
## 笔记本面板：证物 / 线索 / 人物 三个 Tab

signal close_requested()

@onready var bg: ColorRect = $Bg
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/Title
@onready var tab_container: TabContainer = $Panel/Tabs
@onready var close_btn: Button = $Panel/CloseBtn


func _ready() -> void:
	_style_root()
	close_btn.pressed.connect(func(): close_requested.emit())
	_build_evidence_tab()
	_build_clue_tab()
	_build_people_tab()


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


func _make_scroll_panel(title: String) -> VBoxContainer:
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
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	return vbox


func _add_entry(parent: VBoxContainer, title: String, body: String, color: Color = Color(1, 0.9, 0.6, 1), tag := "", portrait_path := "") -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(0, 116)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.10, 0.07, 0.92)
	style.border_color = Color(0.48, 0.36, 0.18, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	pc.add_theme_stylebox_override("panel", style)
	parent.add_child(pc)
	
	var root_hbox := HBoxContainer.new()
	root_hbox.add_theme_constant_override("separation", 14)
	pc.add_child(root_hbox)
	
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait_frame := PanelContainer.new()
		portrait_frame.custom_minimum_size = Vector2(82, 82)
		var portrait_style := StyleBoxFlat.new()
		portrait_style.bg_color = Color(0.04, 0.035, 0.025, 1)
		portrait_style.border_color = Color(0.62, 0.46, 0.22, 0.95)
		portrait_style.set_border_width_all(1)
		portrait_style.corner_radius_top_left = 6
		portrait_style.corner_radius_top_right = 6
		portrait_style.corner_radius_bottom_left = 6
		portrait_style.corner_radius_bottom_right = 6
		portrait_style.content_margin_left = 4
		portrait_style.content_margin_right = 4
		portrait_style.content_margin_top = 4
		portrait_style.content_margin_bottom = 4
		portrait_frame.add_theme_stylebox_override("panel", portrait_style)
		root_hbox.add_child(portrait_frame)
		
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(74, 74)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = _make_portrait_avatar(load(portrait_path))
		portrait_frame.add_child(portrait)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_hbox.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 21)
	t.add_theme_color_override("font_color", color)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = Color(0.72, 0.55, 0.27, 0.35)
	vbox.add_child(line)
	
	var b := RichTextLabel.new()
	b.bbcode_enabled = true
	b.fit_content = true
	b.scroll_active = false
	b.text = body
	b.add_theme_font_size_override("normal_font_size", 17)
	b.add_theme_color_override("default_color", Color(0.88, 0.84, 0.74, 1))
	vbox.add_child(b)


func _make_portrait_avatar(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var img: Image = texture.get_image()
	var side: int = mini(img.get_width(), img.get_height())
	var crop_x: int = int(float(img.get_width() - side) / 2.0)
	# 头像取立绘上方区域，避免裁到身体下半部分
	var crop_y: int = int(img.get_height() * 0.02)
	var crop_h: int = mini(side, int(img.get_height() * 0.42))
	var crop_w: int = crop_h
	crop_x = int(float(img.get_width() - crop_w) / 2.0)
	var cropped := img.get_region(Rect2i(crop_x, crop_y, crop_w, crop_h))
	cropped.resize(96, 96, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(cropped)


func _add_empty_state(parent: VBoxContainer, text: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 80)
	parent.add_child(spacer)
	var lbl := Label.new()
	lbl.text = "◇  %s  ◇" % text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.72, 0.55, 0.85))
	parent.add_child(lbl)


func _build_evidence_tab() -> void:
	var vbox := _make_scroll_panel("证 物")
	if GameManager.collected_evidence.is_empty():
		_add_empty_state(vbox, "尚无证物")
		return
	for eid in GameManager.collected_evidence:
		var data = GameManager.evidence_data.get(eid, {})
		_add_entry(vbox, data.get("name", eid), data.get("description", ""), Color(1, 0.67, 0.46, 1), "证物")


func _build_clue_tab() -> void:
	var vbox := _make_scroll_panel("线 索")
	if GameManager.collected_clues.is_empty():
		_add_empty_state(vbox, "尚无线索")
		return
	for cid in GameManager.collected_clues:
		var data = GameManager.evidence_data.get(cid, {})
		_add_entry(vbox, data.get("name", cid), data.get("description", ""), Color(1, 0.84, 0.50, 1), "线索")


func _build_people_tab() -> void:
	var vbox := _make_scroll_panel("人 物")
	var seen: Array = []
	for loc_id in GameManager.visited_locations:
		var npcs: Array = GameManager.get_location_data(loc_id).get("npcs", [])
		for n in npcs:
			if not seen.has(n):
				seen.append(n)
	if seen.is_empty():
		_add_empty_state(vbox, "尚未结识人物")
		return
	for nid in seen:
		var data = GameManager.get_npc_data(nid)
		var lies_exposed: Array = []
		for flag in GameManager.dialogue_flags.keys():
			if flag.begins_with("lie_exposed:%s." % nid):
				var ln: String = flag.substr(("lie_exposed:%s." % nid).length())
				lies_exposed.append(ln)
		var body: String = data.get("intro", "")
		if lies_exposed.size() > 0:
			body += "\n\n[color=#ffaa55]【已识破谎言】[/color]"
			for ln in lies_exposed:
				body += "\n  · %s" % ln
		_add_entry(vbox, "%s ｜ %s" % [data.get("name", nid), data.get("title", "")], body, Color(0.72, 0.95, 0.72, 1), "人物", data.get("portrait", ""))
