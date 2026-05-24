extends Control
## 案件选择面板：全屏时代标签页 + 右侧角色背景图 + 左侧案件卡片
##
## 信号：
##   case_chosen_with_action(case_id, action)  — 玩家选了案件并决定操作（"new"/"continue"）
##   cancelled()                                 — 玩家取消（关闭按钮 / Esc）

signal case_chosen_with_action(case_id: String, action: String)
signal cancelled()

# ─── 时代配置 ───
const ERAS := [
	{ "id": "ancient",   "label": "古  代", "bg": "res://assets/cn/era_backgrounds/era_ancient.png" },
	{ "id": "republic",  "label": "民  国", "bg": "res://assets/cn/era_backgrounds/era_republic.png" },
	{ "id": "modern",    "label": "现  代", "bg": "" },
	{ "id": "special",   "label": "？ ？", "bg": "" },
]

const CARD_BG_NORMAL := Color(0.08, 0.07, 0.06, 0.88)
const CARD_BG_HOVER  := Color(0.14, 0.12, 0.09, 0.92)
const CARD_BG_CURRENT := Color(0.10, 0.14, 0.08, 0.90)
const CARD_BORDER_NORMAL  := Color(0.42, 0.32, 0.18, 0.80)
const CARD_BORDER_HOVER   := Color(0.85, 0.66, 0.32, 1.0)
const CARD_BORDER_CURRENT := Color(0.55, 0.85, 0.40, 0.90)
const TAB_ACTIVE_COLOR   := Color(1.0, 0.92, 0.68, 1)
const TAB_INACTIVE_COLOR := Color(0.55, 0.50, 0.42, 0.8)

var _era_buttons: Array[Button] = []
var _current_era: String = ""
var _bg_texture: TextureRect
var _bg_clip: Control
var _cards_container: VBoxContainer
var _tab_underlines: Dictionary = {}
var _action_bubble: Control = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_switch_era("ancient")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancelled.emit()
		queue_free()


func _build_ui() -> void:
	# ── 1. 纯黑实色底（完全遮住主菜单）──
	var solid_bg := ColorRect.new()
	solid_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	solid_bg.color = Color(0.04, 0.04, 0.05, 1.0)
	solid_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(solid_bg)

	# ── 2. 角色背景图（高度铺满，右对齐，只裁左边）──
	_bg_clip = Control.new()
	_bg_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_bg_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_clip)

	_bg_texture = TextureRect.new()
	_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture.modulate = Color(1, 1, 1, 0.85)
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_clip.add_child(_bg_texture)
	# 延迟一帧让锚点生效后再对齐
	_bg_clip.resized.connect(_do_align_bg)

	# ── 3. 渐变遮罩（从左到右逐渐透明，无硬边）──
	var gradient_overlay := TextureRect.new()
	gradient_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	gradient_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gradient_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	gradient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad_img := Image.create(256, 1, false, Image.FORMAT_RGBA8)
	for x in range(256):
		var alpha: float
		if x < 140:
			alpha = 0.82
		elif x < 200:
			alpha = lerpf(0.82, 0.0, float(x - 140) / 60.0)
		else:
			alpha = 0.0
		grad_img.set_pixel(x, 0, Color(0.04, 0.04, 0.05, alpha))
	var grad_tex := ImageTexture.create_from_image(grad_img)
	gradient_overlay.texture = grad_tex
	add_child(gradient_overlay)

	# ── 4. 左侧主内容区 ──
	var left_margin := MarginContainer.new()
	left_margin.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_margin.anchor_right = 0.60
	left_margin.add_theme_constant_override("margin_left", 50)
	left_margin.add_theme_constant_override("margin_right", 30)
	left_margin.add_theme_constant_override("margin_top", 40)
	left_margin.add_theme_constant_override("margin_bottom", 40)
	add_child(left_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 0)
	left_margin.add_child(content_vbox)

	# ── 5. 标题 ──
	var title := Label.new()
	title.text = "── 选 择 案 件 ──"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	content_vbox.add_child(title)

	var sp1 := Control.new()
	sp1.custom_minimum_size = Vector2(0, 18)
	content_vbox.add_child(sp1)

	# ── 6. 时代标签栏 ──
	var tab_hb := HBoxContainer.new()
	tab_hb.add_theme_constant_override("separation", 0)
	content_vbox.add_child(tab_hb)

	for era in ERAS:
		var tab_wrapper := VBoxContainer.new()
		tab_wrapper.add_theme_constant_override("separation", 3)
		tab_hb.add_child(tab_wrapper)

		var btn := Button.new()
		btn.text = era.label
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_color_override("font_color", TAB_INACTIVE_COLOR)
		btn.add_theme_color_override("font_hover_color", TAB_ACTIVE_COLOR)
		btn.custom_minimum_size = Vector2(80, 34)
		var eid: String = era.id
		btn.pressed.connect(func(): _switch_era(eid))
		tab_wrapper.add_child(btn)
		_era_buttons.append(btn)

		var underline := ColorRect.new()
		underline.custom_minimum_size = Vector2(80, 2)
		underline.color = Color(0.85, 0.66, 0.32, 0.0)
		tab_wrapper.add_child(underline)
		_tab_underlines[eid] = underline

	# 分隔
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	sep.modulate = Color(0.5, 0.4, 0.25, 0.5)
	content_vbox.add_child(sep)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 14)
	content_vbox.add_child(sp2)

	# ── 7. 卡片滚动区 ──
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_vbox.add_child(scroll)

	_cards_container = VBoxContainer.new()
	_cards_container.add_theme_constant_override("separation", 14)
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_cards_container)

	# ── 8. 右上角关闭按钮 ──
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55, 1))
	close_btn.add_theme_color_override("font_hover_color", Color(1, 0.92, 0.68, 1))
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -60
	close_btn.offset_top = 16
	close_btn.offset_right = -16
	close_btn.offset_bottom = 60
	close_btn.pressed.connect(func():
		cancelled.emit()
		queue_free()
	)
	add_child(close_btn)


func _switch_era(era_id: String) -> void:
	_current_era = era_id
	var idx := 0
	for era in ERAS:
		var btn: Button = _era_buttons[idx]
		var underline: ColorRect = _tab_underlines[era.id]
		if era.id == era_id:
			btn.add_theme_color_override("font_color", TAB_ACTIVE_COLOR)
			underline.color = Color(0.85, 0.66, 0.32, 1.0)
		else:
			btn.add_theme_color_override("font_color", TAB_INACTIVE_COLOR)
			underline.color = Color(0.85, 0.66, 0.32, 0.0)
		idx += 1

	var era_cfg := _get_era_config(era_id)
	var bg_path: String = era_cfg.get("bg", "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		_bg_texture.texture = load(bg_path)
	else:
		_bg_texture.texture = null
	_do_align_bg()

	_refresh_cards()


func _get_era_config(era_id: String) -> Dictionary:
	for era in ERAS:
		if era.id == era_id:
			return era
	return {}


func _refresh_cards() -> void:
	for child in _cards_container.get_children():
		child.queue_free()

	var entries: Array = GameManager.get_case_index_entries()
	var era_entries: Array = []
	for entry in entries:
		if entry.get("era", "ancient") == _current_era:
			era_entries.append(entry)

	if era_entries.is_empty():
		var empty := Label.new()
		empty.text = "\n\n该时代暂无案件，敬请期待\n"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.6, 0.55, 0.48, 0.7))
		_cards_container.add_child(empty)
		return

	for entry in era_entries:
		_cards_container.add_child(_make_case_card(entry))


func _make_case_card(entry: Dictionary) -> Control:
	var case_id: String = entry.get("id", "")
	var manifest_path: String = entry.get("manifest", "")
	var locked_field: bool = entry.get("locked", false)
	var unlock_after: String = entry.get("unlock_after", "")
	var tag: String = entry.get("tag", "")
	var voice_status: String = entry.get("voice_status", "full")

	var iv := get_node_or_null("/root/InvestigatorService")
	var locked := locked_field
	var cleared := false
	var best_ending := ""
	var play_count := 0
	if iv:
		if not iv.is_case_unlocked(case_id):
			locked = true
		var rec: Dictionary = iv.get_case_record(case_id)
		if not rec.is_empty():
			cleared = true
			best_ending = rec.get("best_ending", "")
			play_count = int(rec.get("play_count", 0))

	var manifest: Dictionary = {}
	if manifest_path != "" and FileAccess.file_exists(manifest_path):
		var f := FileAccess.open(manifest_path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				manifest = parsed

	var is_current: bool = (case_id == GameManager.ACTIVE_CASE)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set_meta("case_id", case_id)
	card.set_meta("locked", locked)
	card.set_meta("is_current", is_current)

	var card_sb := StyleBoxFlat.new()
	if locked:
		card_sb.bg_color = Color(0.05, 0.04, 0.03, 0.75)
		card_sb.border_color = Color(0.3, 0.28, 0.22, 0.6)
	elif is_current:
		card_sb.bg_color = CARD_BG_CURRENT
		card_sb.border_color = CARD_BORDER_CURRENT
	else:
		card_sb.bg_color = CARD_BG_NORMAL
		card_sb.border_color = CARD_BORDER_NORMAL
	card_sb.set_border_width_all(2)
	card_sb.corner_radius_top_left = 6
	card_sb.corner_radius_top_right = 6
	card_sb.corner_radius_bottom_left = 6
	card_sb.corner_radius_bottom_right = 6
	card_sb.content_margin_left = 12
	card_sb.content_margin_right = 14
	card_sb.content_margin_top = 10
	card_sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", card_sb)
	card.set_meta("stylebox", card_sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hb)

	# 左：预览图
	var preview_path: String = manifest.get("preview_image", "")
	if preview_path != "" and ResourceLoader.exists(preview_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(preview_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.custom_minimum_size = Vector2(160, 100)
		tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(tex_rect)

	# 右：信息
	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vb.add_theme_constant_override("separation", 4)
	hb.add_child(info_vb)

	# 标题行
	var title_hb := HBoxContainer.new()
	title_hb.add_theme_constant_override("separation", 8)
	title_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vb.add_child(title_hb)

	var title_lbl := Label.new()
	title_lbl.text = manifest.get("title", case_id)
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_hb.add_child(title_lbl)

	if is_current:
		var cur_lbl := Label.new()
		cur_lbl.text = "● 当前"
		cur_lbl.add_theme_font_size_override("font_size", 12)
		cur_lbl.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6, 1))
		cur_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_hb.add_child(cur_lbl)

	if tag != "":
		var tag_lbl := Label.new()
		tag_lbl.text = "[%s]" % tag
		tag_lbl.add_theme_font_size_override("font_size", 12)
		tag_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62, 1))
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_hb.add_child(tag_lbl)

	if cleared:
		var clear_lbl := Label.new()
		clear_lbl.text = "✓ 已完成 · %s" % _ending_label(best_ending)
		clear_lbl.add_theme_font_size_override("font_size", 13)
		clear_lbl.add_theme_color_override("font_color", _ending_color(best_ending))
		clear_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.01, 1))
		clear_lbl.add_theme_constant_override("outline_size", 2)
		clear_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_hb.add_child(clear_lbl)

	# 副标题
	var sub_text: String = manifest.get("subtitle", "")
	if sub_text != "":
		var sub_lbl := Label.new()
		sub_lbl.text = sub_text
		sub_lbl.add_theme_font_size_override("font_size", 13)
		sub_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.58, 1))
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vb.add_child(sub_lbl)

	# meta
	var meta_lbl := Label.new()
	var diff: String = manifest.get("difficulty", "?")
	var days: int = int(manifest.get("estimated_days", 0))
	var voice_label := ""
	if voice_status == "missing":
		voice_label = "  ·  ⚠ 无语音"
	elif voice_status == "partial":
		voice_label = "  ·  部分语音"
	var replay_label := "  ·  已通关%d次，再次选择将从头开始" % play_count if cleared else ""
	meta_lbl.text = "难度 %s  ·  预计 %d 时段%s%s" % [diff, days, voice_label, replay_label]
	meta_lbl.add_theme_font_size_override("font_size", 12)
	meta_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5, 1))
	meta_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vb.add_child(meta_lbl)

	# 简介
	var intro_text: String = manifest.get("intro", "")
	if intro_text != "":
		var oneline := intro_text.replace("\n", "  ").strip_edges()
		var intro_lbl := Label.new()
		intro_lbl.text = oneline
		intro_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intro_lbl.add_theme_font_size_override("font_size", 12)
		intro_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 0.68, 0.9))
		intro_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		intro_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		intro_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		intro_lbl.max_lines_visible = 2
		info_vb.add_child(intro_lbl)

	if locked:
		var lock_lbl := Label.new()
		if locked_field:
			lock_lbl.text = "🔒 暂未开放"
		elif unlock_after != "":
			# 找前置案件标题
			var prereq_title := unlock_after
			var entries: Array = GameManager.get_case_index_entries() if GameManager else []
			for e in entries:
				if e.get("id", "") == unlock_after:
					var mp: String = e.get("manifest", "")
					if mp != "" and FileAccess.file_exists(mp):
						var mf := FileAccess.open(mp, FileAccess.READ)
						if mf:
							var pm = JSON.parse_string(mf.get_as_text())
							if typeof(pm) == TYPE_DICTIONARY:
								prereq_title = pm.get("title", unlock_after)
					break
			lock_lbl.text = "🔒 通关「%s」后解锁" % prereq_title
		else:
			lock_lbl.text = "🔒 暂未解锁"
		lock_lbl.add_theme_font_size_override("font_size", 12)
		lock_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1))
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vb.add_child(lock_lbl)

	# 鼠标交互
	if not locked:
		card.mouse_entered.connect(func():
			var sb: StyleBoxFlat = card.get_meta("stylebox")
			sb.bg_color = CARD_BG_HOVER
			if not card.get_meta("is_current"):
				sb.border_color = CARD_BORDER_HOVER
		)
		card.mouse_exited.connect(func():
			var sb: StyleBoxFlat = card.get_meta("stylebox")
			if card.get_meta("is_current"):
				sb.bg_color = CARD_BG_CURRENT
				sb.border_color = CARD_BORDER_CURRENT
			else:
				sb.bg_color = CARD_BG_NORMAL
				sb.border_color = CARD_BORDER_NORMAL
		)
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				var case_title: String = manifest.get("title", case_id)
				_show_action_bubble(case_id, case_title, _case_has_save(case_id), cleared)
		)

	return card


static func _ending_label(eid: String) -> String:
	match eid:
		"perfect": return "明镜高悬"
		"good": return "真凶伏法"
		"partial": return "擒贼一半"
		"bad": return "冤狱再起"
		"timeout": return "日暮途穷"
	return eid


static func _ending_color(eid: String) -> Color:
	match eid:
		"perfect": return Color(0.60, 0.95, 0.55, 1)
		"good": return Color(0.78, 0.85, 0.48, 1)
		"partial": return Color(0.90, 0.78, 0.35, 1)
		"bad": return Color(0.92, 0.55, 0.45, 1)
		"timeout": return Color(0.70, 0.62, 0.55, 1)
	return Color(0.85, 0.78, 0.62, 1)


func _do_align_bg() -> void:
	if _bg_texture == null or _bg_texture.texture == null or _bg_clip == null:
		return
	var tex_size: Vector2 = _bg_texture.texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	var cont_size: Vector2 = _bg_clip.size
	if cont_size.x <= 0 or cont_size.y <= 0:
		return
	# 高度铺满，按比例计算宽度
	var scale_f: float = cont_size.y / tex_size.y
	var rendered_w: float = tex_size.x * scale_f
	# 右对齐：图片右边贴容器右边，左边溢出裁切
	var offset_x: float = cont_size.x - rendered_w
	_bg_texture.position = Vector2(offset_x, 0)
	_bg_texture.size = Vector2(rendered_w, cont_size.y)


func _case_has_save(case_id: String) -> bool:
	if FileAccess.file_exists("user://saves/%s.json" % case_id):
		return true
	# 兼容旧存档路径，避免旧版本中途进度在选案界面消失。
	return FileAccess.file_exists("user://%s_save.json" % case_id)


func _show_action_bubble(case_id: String, case_title: String, has_save: bool, _is_cleared: bool) -> void:
	_remove_action_bubble()

	# 无存档：直接开始新游戏。已通关但正在重玩且有存档时，仍必须允许继续。
	if not has_save:
		case_chosen_with_action.emit(case_id, "new")
		queue_free()
		return

	# 有存档：弹出气泡选择
	var overlay := ColorRect.new()
	overlay.name = "ActionBubbleOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.50)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	center.add_child(panel)

	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.10, 0.09, 0.07, 0.96)
	panel_sb.border_color = Color(0.55, 0.42, 0.22, 0.85)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(10)
	panel_sb.content_margin_left = 28
	panel_sb.content_margin_right = 28
	panel_sb.content_margin_top = 22
	panel_sb.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", panel_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = case_title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	vbox.add_child(title_lbl)

	var hint := Label.new()
	hint.text = "检测到存档，选择操作："
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.75, 0.70, 0.55, 1))
	vbox.add_child(hint)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 24)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	var continue_btn := Button.new()
	continue_btn.text = "继 续 上 次"
	continue_btn.custom_minimum_size = Vector2(140, 44)
	continue_btn.flat = true
	continue_btn.add_theme_font_size_override("font_size", 18)
	continue_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1))
	continue_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.78, 1))
	continue_btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
	continue_btn.pressed.connect(func():
		_remove_action_bubble()
		case_chosen_with_action.emit(case_id, "continue")
		queue_free()
	)
	btn_hbox.add_child(continue_btn)

	var new_btn := Button.new()
	new_btn.text = "从 头 开 始"
	new_btn.custom_minimum_size = Vector2(140, 44)
	new_btn.flat = true
	new_btn.add_theme_font_size_override("font_size", 18)
	new_btn.add_theme_color_override("font_color", Color(0.65, 0.62, 0.55, 1))
	new_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.80, 0.72, 1))
	new_btn.add_theme_color_override("font_pressed_color", Color(0.55, 0.50, 0.42, 1))
	new_btn.pressed.connect(func():
		_remove_action_bubble()
		case_chosen_with_action.emit(case_id, "new")
		queue_free()
	)
	btn_hbox.add_child(new_btn)

	# 点击遮罩取消
	overlay.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_remove_action_bubble()
	)

	_action_bubble = overlay


func _remove_action_bubble() -> void:
	if _action_bubble and is_instance_valid(_action_bubble):
		_action_bubble.queue_free()
		_action_bubble = null

