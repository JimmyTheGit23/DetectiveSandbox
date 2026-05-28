extends Control
## 笔记本面板：证物 / 线索 / 关键信息 / 人物 四个 Tab

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
	_build_record_tab()
	_build_key_info_tab()
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


func _make_scroll_container(title: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(scroll)
	return scroll


func _make_margin(parent: Control) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	parent.add_child(margin)
	return margin


# ─── 通用列表项（无图标） ───

func _add_list_item(parent: Container, name_text: String, desc: String, color: Color, tag: String, source: String = "", item_id: String = "") -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 72)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.clip_text = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.10, 0.07, 0.92)
	style.border_color = Color(0.48, 0.36, 0.18, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 10
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.22, 0.17, 0.10, 0.95)
	hover_style.border_color = Color(0.72, 0.55, 0.27, 0.95)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.08, 0.06, 0.04, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# 内部布局: HBox = [Icon] + [VBox: name + desc_preview]
	var hbox := HBoxContainer.new()
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.offset_left = 10
	hbox.offset_right = -14
	hbox.offset_top = 8
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	# 图标
	var icon_path := "res://assets/ai_processed/objects/evidence_icons/%s.png" % item_id
	if item_id != "" and ResourceLoader.exists(icon_path):
		var icon_rect := TextureRect.new()
		icon_rect.texture = load(icon_path)
		icon_rect.custom_minimum_size = Vector2(56, 56)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 圆角裁切效果通过 clip_children
		var icon_wrapper := PanelContainer.new()
		icon_wrapper.custom_minimum_size = Vector2(56, 56)
		icon_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color(0.08, 0.06, 0.04, 1)
		icon_style.corner_radius_top_left = 6
		icon_style.corner_radius_top_right = 6
		icon_style.corner_radius_bottom_left = 6
		icon_style.corner_radius_bottom_right = 6
		icon_style.set_content_margin_all(0)
		icon_wrapper.add_theme_stylebox_override("panel", icon_style)
		icon_wrapper.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		icon_wrapper.add_child(icon_rect)
		hbox.add_child(icon_wrapper)

	# 文字区域
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 4)
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)

	# 名称行: [tag] + name
	var name_label := Label.new()
	var display := ""
	if tag != "":
		display += "[%s] " % tag
	display += name_text
	if source != "":
		display += "  —— %s" % source
	name_label.text = display
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", color)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(name_label)

	# 描述预览行
	var desc_preview := Label.new()
	var preview_text := desc.substr(0, 40)
	if desc.length() > 40:
		preview_text += "……"
	desc_preview.text = preview_text
	desc_preview.add_theme_font_size_override("font_size", 13)
	desc_preview.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50, 0.85))
	desc_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(desc_preview)

	parent.add_child(btn)

	btn.pressed.connect(func() -> void:
		_show_detail_popup(name_text, desc, color, tag, source, item_id)
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


# ─── 通用详情弹窗 ───

func _show_detail_popup(title: String, body: String, color: Color, tag: String, source: String = "", item_id: String = "") -> void:
	if has_node("DetailPopup"):
		return

	var overlay := Control.new()
	overlay.name = "DetailPopup"
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
	card.custom_minimum_size = Vector2(440, 0)
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

	# 关闭按钮行
	var top_hbox := HBoxContainer.new()
	card_vbox.add_child(top_hbox)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)
	var close_btn2 := Button.new()
	close_btn2.flat = true
	close_btn2.text = "✕"
	close_btn2.add_theme_font_size_override("font_size", 22)
	close_btn2.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55, 1))
	close_btn2.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72, 1))
	close_btn2.pressed.connect(func() -> void: overlay.queue_free())
	top_hbox.add_child(close_btn2)

	# 标题 + 标签 + 来源
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	card_vbox.add_child(header)

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

	if source != "":
		var src_lbl := Label.new()
		src_lbl.text = "——%s" % source
		src_lbl.add_theme_font_size_override("font_size", 14)
		src_lbl.add_theme_color_override("font_color", Color(0.65, 0.58, 0.45, 0.9))
		src_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		src_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		header.add_child(src_lbl)

	# 图标（如果有）
	var detail_icon_path := "res://assets/ai_processed/objects/evidence_icons/%s.png" % item_id
	if item_id != "" and ResourceLoader.exists(detail_icon_path):
		var icon_center := CenterContainer.new()
		card_vbox.add_child(icon_center)
		var icon_panel := PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(128, 128)
		var icon_bg := StyleBoxFlat.new()
		icon_bg.bg_color = Color(0.06, 0.05, 0.03, 1)
		icon_bg.corner_radius_top_left = 8
		icon_bg.corner_radius_top_right = 8
		icon_bg.corner_radius_bottom_left = 8
		icon_bg.corner_radius_bottom_right = 8
		icon_bg.border_color = Color(0.48, 0.36, 0.18, 0.7)
		icon_bg.set_border_width_all(1)
		icon_bg.set_content_margin_all(0)
		icon_panel.add_theme_stylebox_override("panel", icon_bg)
		icon_panel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		icon_center.add_child(icon_panel)
		var icon_tex := TextureRect.new()
		icon_tex.texture = load(detail_icon_path)
		icon_tex.custom_minimum_size = Vector2(128, 128)
		icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon_panel.add_child(icon_tex)

	# 分隔线
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.72, 0.55, 0.27, 0.4)
	card_vbox.add_child(sep)

	# 描述
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


# ─── 证物 Tab（横向翻页大图标） ───

var _evidence_page_index: int = 0
var _evidence_items_cache: Array = []
var _evidence_card_container: Control = null
var _evidence_page_label: Label = null

func _build_evidence_tab() -> void:
	var scroll := _make_scroll_container("证 物")
	var margin := _make_margin(scroll)

	_evidence_items_cache = []
	for item_id in GameManager.collected_evidence:
		var item_data: Dictionary = GameManager.evidence_data.get(item_id, {})
		if item_data.get("hidden", false):
			continue
		_evidence_items_cache.append(item_id)

	if _evidence_items_cache.is_empty():
		var empty_vbox := VBoxContainer.new()
		margin.add_child(empty_vbox)
		_add_empty_state(empty_vbox, "尚无证物")
		return

	_evidence_page_index = 0

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(root_vbox)

	# 卡片显示区域
	_evidence_card_container = Control.new()
	_evidence_card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_evidence_card_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_evidence_card_container.custom_minimum_size = Vector2(0, 320)
	root_vbox.add_child(_evidence_card_container)

	# 底部导航栏: [<] page_label [>]
	var nav_hbox := HBoxContainer.new()
	nav_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_hbox.add_theme_constant_override("separation", 16)
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(nav_hbox)

	var prev_btn := Button.new()
	prev_btn.text = "◀ 上一件"
	prev_btn.custom_minimum_size = Vector2(100, 38)
	prev_btn.add_theme_font_size_override("font_size", 16)
	prev_btn.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55, 1))
	prev_btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.72, 1))
	prev_btn.focus_mode = Control.FOCUS_NONE
	var prev_style := StyleBoxFlat.new()
	prev_style.bg_color = Color(0.15, 0.12, 0.08, 0.9)
	prev_style.border_color = Color(0.48, 0.36, 0.18, 0.8)
	prev_style.set_border_width_all(1)
	prev_style.set_corner_radius_all(6)
	prev_style.content_margin_left = 12
	prev_style.content_margin_right = 12
	prev_btn.add_theme_stylebox_override("normal", prev_style)
	var prev_hover := prev_style.duplicate() as StyleBoxFlat
	prev_hover.bg_color = Color(0.22, 0.17, 0.10, 0.95)
	prev_btn.add_theme_stylebox_override("hover", prev_hover)
	prev_btn.pressed.connect(func() -> void:
		if _evidence_page_index > 0:
			_evidence_page_index -= 1
			_render_evidence_card()
	)
	nav_hbox.add_child(prev_btn)

	_evidence_page_label = Label.new()
	_evidence_page_label.add_theme_font_size_override("font_size", 15)
	_evidence_page_label.add_theme_color_override("font_color", Color(0.75, 0.68, 0.55, 0.9))
	_evidence_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_evidence_page_label.custom_minimum_size = Vector2(80, 0)
	nav_hbox.add_child(_evidence_page_label)

	var next_btn := Button.new()
	next_btn.text = "下一件 ▶"
	next_btn.custom_minimum_size = Vector2(100, 38)
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55, 1))
	next_btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.72, 1))
	next_btn.focus_mode = Control.FOCUS_NONE
	next_btn.add_theme_stylebox_override("normal", prev_style.duplicate())
	next_btn.add_theme_stylebox_override("hover", prev_hover.duplicate())
	next_btn.pressed.connect(func() -> void:
		if _evidence_page_index < _evidence_items_cache.size() - 1:
			_evidence_page_index += 1
			_render_evidence_card()
	)
	nav_hbox.add_child(next_btn)

	_render_evidence_card()


func _render_evidence_card() -> void:
	if _evidence_card_container == null:
		return
	# 清空旧卡片
	for child in _evidence_card_container.get_children():
		child.queue_free()

	if _evidence_items_cache.is_empty():
		return

	var item_id: String = _evidence_items_cache[_evidence_page_index]
	var data: Dictionary = GameManager.evidence_data.get(item_id, {})
	var evidence_name: String = data.get("name", item_id)
	var evidence_desc: String = data.get("description", "")

	# 更新页码
	if _evidence_page_label != null:
		_evidence_page_label.text = "%d / %d" % [_evidence_page_index + 1, _evidence_items_cache.size()]

	# 构建卡片
	var card := VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 14)
	_evidence_card_container.add_child(card)
	card.anchor_right = 1.0
	card.anchor_bottom = 1.0

	# 居中大图标
	var icon_path := "res://assets/ai_processed/objects/evidence_icons/%s.png" % item_id
	if ResourceLoader.exists(icon_path):
		var icon_center := CenterContainer.new()
		icon_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(icon_center)

		var icon_panel := PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(180, 180)
		var icon_bg := StyleBoxFlat.new()
		icon_bg.bg_color = Color(0.06, 0.05, 0.03, 1)
		icon_bg.corner_radius_top_left = 10
		icon_bg.corner_radius_top_right = 10
		icon_bg.corner_radius_bottom_left = 10
		icon_bg.corner_radius_bottom_right = 10
		icon_bg.border_color = Color(0.55, 0.42, 0.22, 0.8)
		icon_bg.set_border_width_all(2)
		icon_bg.set_content_margin_all(0)
		icon_panel.add_theme_stylebox_override("panel", icon_bg)
		icon_panel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		icon_center.add_child(icon_panel)

		var icon_tex := TextureRect.new()
		icon_tex.texture = load(icon_path)
		icon_tex.custom_minimum_size = Vector2(180, 180)
		icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon_panel.add_child(icon_tex)

	# 名称（居中）
	var name_lbl := Label.new()
	name_lbl.text = evidence_name
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.72, 0.48, 1))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(name_lbl)

	# 描述
	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.fit_content = true
	desc_lbl.scroll_active = false
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.text = evidence_desc
	desc_lbl.add_theme_font_size_override("normal_font_size", 16)
	desc_lbl.add_theme_color_override("default_color", Color(0.85, 0.80, 0.70, 0.95))
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(desc_lbl)


# ─── 线索 Tab ───

func _build_clue_tab() -> void:
	_build_item_list_tab("线 索", GameManager.collected_clues, Color(1, 0.84, 0.50, 1), "线索", "尚无线索")


func _build_item_list_tab(title: String, items: Array, color: Color, tag: String, empty_text: String) -> void:
	var scroll := _make_scroll_container(title)
	var margin := _make_margin(scroll)

	if items.is_empty():
		var empty_vbox := VBoxContainer.new()
		margin.add_child(empty_vbox)
		_add_empty_state(empty_vbox, empty_text)
		return

	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(list_vbox)

	for item_id in items:
		var data: Dictionary = GameManager.evidence_data.get(item_id, {})
		_add_list_item(list_vbox, data.get("name", item_id), data.get("description", ""), color, tag, "", item_id)


# ─── 卷宗 Tab ───

func _build_record_tab() -> void:
	var scroll := _make_scroll_container("卷 宗")
	var margin := _make_margin(scroll)
	var records: Array = GameManager.get("case_records") if GameManager != null else []
	var dialogues: Array = GameManager.get("dialogue_records") if GameManager != null else []
	if records.is_empty() and dialogues.is_empty():
		var empty_vbox := VBoxContainer.new()
		margin.add_child(empty_vbox)
		_add_empty_state(empty_vbox, "尚无卷宗记录")
		return
	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(list_vbox)
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var rtype: String = record.get("type", "key")
		var tag := "情报"
		if rtype == "testimony":
			tag = "证词"
		elif rtype == "suspicion":
			tag = "疑点"
		_add_list_item(list_vbox, record.get("title", "卷宗记录"), record.get("text", ""), Color(1.0, 0.74, 0.48, 1), tag, record.get("source", ""))
	var summaries := _build_dialogue_summaries(dialogues)
	if not summaries.is_empty():
		var sep := HSeparator.new()
		sep.add_theme_constant_override("separation", 10)
		list_vbox.add_child(sep)
		var title := Label.new()
		title.text = "── 角色对话卷宗 ──"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1))
		list_vbox.add_child(title)
		for summary in summaries:
			var speaker: String = summary.get("speaker", "旁白")
			var lines: Array = summary.get("lines", [])
			var body := ""
			for line in lines:
				body += "· %s\n" % str(line)
			_add_list_item(
				list_vbox,
				"%s（%d条关键对话）" % [speaker, lines.size()],
				body.strip_edges(),
				Color(0.86, 0.82, 0.68, 1),
				"对话",
				"角色卷宗"
			)


func _build_dialogue_summaries(dialogues: Array) -> Array:
	var speaker_order: Array[String] = []
	var key_lines_by_speaker: Dictionary = {}
	var fallback_by_speaker: Dictionary = {}
	var start: int = max(0, dialogues.size() - 180)
	for i in range(start, dialogues.size()):
		var d = dialogues[i]
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var speaker: String = str(d.get("speaker", "旁白")).strip_edges()
		var text: String = str(d.get("text", "")).strip_edges()
		if speaker == "" or text == "":
			continue
		if not speaker_order.has(speaker):
			speaker_order.append(speaker)
			key_lines_by_speaker[speaker] = []
			fallback_by_speaker[speaker] = []
		_add_unique_limited(fallback_by_speaker[speaker], text, 4)
		if _is_key_dialogue_line(text):
			_add_unique_limited(key_lines_by_speaker[speaker], text, 8)
	var result: Array = []
	for speaker in speaker_order:
		var lines: Array = key_lines_by_speaker.get(speaker, [])
		if lines.is_empty():
			lines = fallback_by_speaker.get(speaker, [])
		if not lines.is_empty():
			result.append({"speaker": speaker, "lines": lines})
	return result


func _add_unique_limited(lines: Array, text: String, limit: int) -> void:
	if lines.has(text):
		return
	lines.append(text)
	while lines.size() > limit:
		lines.pop_front()


func _is_key_dialogue_line(text: String) -> bool:
	var terms := [
		"船板", "撞礁", "暗礁", "水涨", "破洞", "凿痕", "钉眼", "浮囊", "包袱",
		"二两", "十二年", "遣散", "赌债", "四十二两", "不到一刻钟", "半个时辰",
		"不会游泳", "不识水性", "夜船", "老范", "阿贵", "动机", "证据"
	]
	for term in terms:
		if text.find(term) >= 0:
			return true
	return false


# ─── 关键信息 Tab ───

func _build_key_info_tab() -> void:
	var scroll := _make_scroll_container("关键信息")
	var margin := _make_margin(scroll)

	var unlocked: Array = []
	for key in GameManager.key_info_data:
		if key.begins_with("_"):
			continue
		var entry: Dictionary = GameManager.key_info_data[key]
		var requires: Dictionary = entry.get("requires", {})
		if GameManager.check_key_info_requires(requires):
			unlocked.append(key)

	var dynamic_records: Array = []
	var saved_records: Array = GameManager.get("case_records") if GameManager != null else []
	for record in saved_records:
		if typeof(record) == TYPE_DICTIONARY:
			dynamic_records.append(record)

	if unlocked.is_empty() and dynamic_records.is_empty():
		var empty_vbox := VBoxContainer.new()
		margin.add_child(empty_vbox)
		_add_empty_state(empty_vbox, "尚未获得关键信息")
		return

	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 8)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(info_vbox)

	for key in unlocked:
		var entry: Dictionary = GameManager.key_info_data[key]
		_add_list_item(
			info_vbox,
			entry.get("name", key),
			entry.get("description", ""),
			Color(0.72, 0.92, 1.0, 1),  # 淡蓝色
			"情报",
			entry.get("source", "")
		)
	for record in dynamic_records:
		var rtype: String = record.get("type", "key")
		var tag := "情报"
		if rtype == "testimony":
			tag = "证词"
		elif rtype == "suspicion":
			tag = "疑点"
		_add_list_item(info_vbox, record.get("title", "卷宗记录"), record.get("text", ""), Color(1.0, 0.78, 0.48, 1), tag, record.get("source", ""))


# ─── 人物 Tab ───

func _make_portrait_avatar(texture: Texture2D, output_size: int = 96) -> Texture2D:
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
		# 头像裁切：取头部区域的正方形，保证脸完整可见。
		var side: float = min(bbox_h * 0.58, bbox_w * 0.95)
		crop_w = int(side)
		var center_x: float = float(min_x + max_x) * 0.5
		crop_x = int(center_x - side * 0.5)
		crop_y = int(float(min_y) + bbox_h * 0.02)
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
	cropped.resize(output_size, output_size, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(cropped)


func _build_people_tab() -> void:
	var scroll := _make_scroll_container("人 物")
	var margin := _make_margin(scroll)

	var seen: Array = []
	for nid in GameManager.npcs_data.keys():
		var npc_def = GameManager.npcs_data[nid]
		if typeof(npc_def) == TYPE_DICTIONARY and bool(npc_def.get("always_in_notebook", false)):
			seen.append(nid)
	for loc_id in GameManager.visited_locations:
		var npcs: Array = GameManager.get_location_data(loc_id).get("npcs", [])
		for n in npcs:
			if not seen.has(n):
				seen.append(n)
	if seen.is_empty():
		var empty_vbox := VBoxContainer.new()
		margin.add_child(empty_vbox)
		_add_empty_state(empty_vbox, "尚未结识人物")
		return

	var people_grid := GridContainer.new()
	people_grid.columns = 2
	people_grid.add_theme_constant_override("h_separation", 14)
	people_grid.add_theme_constant_override("v_separation", 14)
	people_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(people_grid)

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
		_add_person_entry(people_grid, "%s ｜ %s" % [role_name, role_title], body, Color(0.72, 0.95, 0.72, 1), "人物", portrait_path)


func _add_person_entry(parent: Container, name_text: String, body: String, color: Color, tag: String, portrait_path: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 118)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.text = ""

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.10, 0.07, 0.92)
	style.border_color = Color(0.48, 0.36, 0.18, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.18, 0.13, 0.08, 0.96)
	hover_style.border_color = Color(0.78, 0.58, 0.25, 1)
	btn.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.10, 0.075, 0.05, 0.98)
	pressed_style.border_color = Color(1.0, 0.78, 0.35, 1)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# 内部布局：横向排列，头像完整显示在左侧，身份文字在右侧。
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE)
	hbox.offset_left = 12
	hbox.offset_right = -12
	hbox.offset_top = 12
	hbox.offset_bottom = -12
	hbox.add_theme_constant_override("separation", 14)
	btn.add_child(hbox)

	# 左侧头像
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait_frame := PanelContainer.new()
		portrait_frame.custom_minimum_size = Vector2(86, 86)
		portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pstyle := StyleBoxFlat.new()
		pstyle.bg_color = Color(0.04, 0.035, 0.025, 1)
		pstyle.border_color = Color(0.62, 0.46, 0.22, 0.95)
		pstyle.set_border_width_all(1)
		pstyle.corner_radius_top_left = 6
		pstyle.corner_radius_top_right = 6
		pstyle.corner_radius_bottom_left = 6
		pstyle.corner_radius_bottom_right = 6
		pstyle.content_margin_left = 4
		pstyle.content_margin_right = 4
		pstyle.content_margin_top = 4
		pstyle.content_margin_bottom = 4
		portrait_frame.add_theme_stylebox_override("panel", pstyle)
		portrait_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(portrait_frame)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(78, 78)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = _make_portrait_avatar(load(portrait_path), 78)
		portrait_frame.add_child(portrait)
	else:
		var portrait_frame := PanelContainer.new()
		portrait_frame.custom_minimum_size = Vector2(86, 86)
		portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pstyle := StyleBoxFlat.new()
		pstyle.bg_color = Color(0.04, 0.035, 0.025, 1)
		pstyle.border_color = Color(0.62, 0.46, 0.22, 0.95)
		pstyle.set_border_width_all(1)
		pstyle.corner_radius_top_left = 6
		pstyle.corner_radius_top_right = 6
		pstyle.corner_radius_bottom_left = 6
		pstyle.corner_radius_bottom_right = 6
		portrait_frame.add_theme_stylebox_override("panel", pstyle)
		hbox.add_child(portrait_frame)
		var placeholder := Label.new()
		placeholder.text = "殁"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.custom_minimum_size = Vector2(78, 78)
		placeholder.add_theme_font_size_override("font_size", 32)
		placeholder.add_theme_color_override("font_color", Color(0.72, 0.66, 0.55, 1))
		portrait_frame.add_child(placeholder)

	# 右侧名字与简介
	var text_vbox := VBoxContainer.new()
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = name_text
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(name_lbl)

	var intro_lbl := Label.new()
	intro_lbl.text = body.strip_edges().split("\n")[0]
	intro_lbl.add_theme_font_size_override("font_size", 13)
	intro_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.58, 0.95))
	intro_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	intro_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_lbl.max_lines_visible = 2
	intro_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_child(intro_lbl)

	parent.add_child(btn)

	btn.pressed.connect(func() -> void:
		_show_person_detail(name_text, body, color, tag, portrait_path)
	)


func _show_person_detail(title: String, body: String, color: Color, tag: String, portrait_path: String) -> void:
	if has_node("PersonDetailOverlay"):
		return

	var overlay := Control.new()
	overlay.name = "PersonDetailOverlay"
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
	card.custom_minimum_size = Vector2(440, 0)
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

	# 关闭按钮
	var top_hbox := HBoxContainer.new()
	card_vbox.add_child(top_hbox)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)
	var close_btn2 := Button.new()
	close_btn2.flat = true
	close_btn2.text = "✕"
	close_btn2.add_theme_font_size_override("font_size", 22)
	close_btn2.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55, 1))
	close_btn2.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72, 1))
	close_btn2.pressed.connect(func() -> void: overlay.queue_free())
	top_hbox.add_child(close_btn2)

	# 头像 + 名字
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
