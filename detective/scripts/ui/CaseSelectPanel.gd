extends Control
## 案件选择面板：以卡片形式列出所有可玩案件
##
## 数据源：GameManager.get_case_index_entries() + 每条 entry.manifest 指向的 manifest.json
##
## 信号：
##   case_chosen(case_id)  — 玩家点了某张卡片
##   cancelled()            — 玩家取消（关闭按钮 / Esc）

signal case_chosen(case_id: String)
signal cancelled()

const CARD_BG_NORMAL := Color(0.11, 0.10, 0.08, 0.92)
const CARD_BG_HOVER  := Color(0.16, 0.14, 0.10, 0.96)
const CARD_BG_CURRENT := Color(0.13, 0.16, 0.10, 0.94)
const CARD_BORDER_NORMAL  := Color(0.42, 0.32, 0.18, 0.85)
const CARD_BORDER_HOVER   := Color(0.85, 0.66, 0.32, 1.0)
const CARD_BORDER_CURRENT := Color(0.55, 0.85, 0.40, 0.95)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancelled.emit()
		queue_free()


func _build_ui() -> void:
	# 半透明遮罩
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# 主容器
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 560)
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	stylebox.border_color = Color(0.62, 0.46, 0.22, 0.95)
	stylebox.set_border_width_all(2)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.content_margin_left = 28
	stylebox.content_margin_right = 28
	stylebox.content_margin_top = 22
	stylebox.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", stylebox)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# 标题栏
	var hb_title := HBoxContainer.new()
	hb_title.add_theme_constant_override("separation", 12)
	vbox.add_child(hb_title)

	var title := Label.new()
	title.text = "── 选 择 案 件 ──"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb_title.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(func():
		cancelled.emit()
		queue_free()
	)
	hb_title.add_child(close_btn)

	# 卡片滚动区
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(840, 460)
	vbox.add_child(scroll)

	var cards_vbox := VBoxContainer.new()
	cards_vbox.add_theme_constant_override("separation", 12)
	cards_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cards_vbox)

	var entries: Array = GameManager.get_case_index_entries()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "暂无可玩案件"
		empty.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55, 1))
		cards_vbox.add_child(empty)
		return

	for entry in entries:
		cards_vbox.add_child(_make_case_card(entry))


func _make_case_card(entry: Dictionary) -> Control:
	var case_id: String = entry.get("id", "")
	var manifest_path: String = entry.get("manifest", "")
	var locked_field: bool = entry.get("locked", false)
	var rank_required: int = int(entry.get("rank_required", 1))
	var _style_tag: String = entry.get("style", "")
	var _category: String = entry.get("category", "solo")
	var tag: String = entry.get("tag", "")
	var voice_status: String = entry.get("voice_status", "full")

	# 调查员视角：是否解锁 / 是否已通关 / 最佳结局
	var iv := get_node_or_null("/root/InvestigatorService")
	var locked := locked_field
	var rank_ok := true
	var cleared := false
	var best_ending := ""
	var play_count := 0
	if iv:
		rank_ok = iv.get_rank() >= rank_required
		if not rank_ok:
			locked = true
		var rec: Dictionary = iv.get_case_record(case_id)
		if not rec.is_empty():
			cleared = true
			best_ending = rec.get("best_ending", "")
			play_count = int(rec.get("play_count", 0))

	# 加载 manifest
	var manifest: Dictionary = {}
	if manifest_path != "" and FileAccess.file_exists(manifest_path):
		var f := FileAccess.open(manifest_path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				manifest = parsed

	var is_current: bool = (case_id == GameManager.ACTIVE_CASE)

	# 卡片根：PanelContainer——会自适应内容高度
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set_meta("case_id", case_id)
	card.set_meta("locked", locked)
	card.set_meta("is_current", is_current)

	var card_sb := StyleBoxFlat.new()
	if locked:
		card_sb.bg_color = Color(0.07, 0.06, 0.05, 0.85)
		card_sb.border_color = Color(0.3, 0.28, 0.22, 0.7)
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

	# 内部布局：左图 + 右文字
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hb)

	# 左：预览图（固定尺寸，不让它撑垮卡片）
	var preview_path: String = manifest.get("preview_image", "")
	if preview_path != "" and ResourceLoader.exists(preview_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(preview_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.custom_minimum_size = Vector2(180, 120)
		tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 圆角通过 clip 实现（轻量做法：直接给个边）
		hb.add_child(tex_rect)

	# 右：文字 vbox
	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vb.add_theme_constant_override("separation", 4)
	hb.add_child(info_vb)

	# 标题行：title + tag/current 标
	var title_hb := HBoxContainer.new()
	title_hb.add_theme_constant_override("separation", 10)
	title_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vb.add_child(title_hb)

	var title_lbl := Label.new()
	var title_text: String = manifest.get("title", case_id)
	title_lbl.text = title_text
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_hb.add_child(title_lbl)

	if is_current:
		var cur_lbl := Label.new()
		cur_lbl.text = "● 当前"
		cur_lbl.add_theme_font_size_override("font_size", 13)
		cur_lbl.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6, 1))
		cur_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_hb.add_child(cur_lbl)

	if tag != "":
		var tag_lbl := Label.new()
		tag_lbl.text = "[%s]" % tag
		tag_lbl.add_theme_font_size_override("font_size", 13)
		tag_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62, 1))
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_hb.add_child(tag_lbl)

	# 通关徽章
	if cleared:
		var clear_lbl := Label.new()
		var ending_name := _ending_label(best_ending)
		clear_lbl.text = "✦ 已通关 · %s" % ending_name
		clear_lbl.add_theme_font_size_override("font_size", 13)
		clear_lbl.add_theme_color_override("font_color", _ending_color(best_ending))
		clear_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_hb.add_child(clear_lbl)

	# 副标题
	var sub_text: String = manifest.get("subtitle", "")
	if sub_text != "":
		var sub_lbl := Label.new()
		sub_lbl.text = sub_text
		sub_lbl.add_theme_font_size_override("font_size", 14)
		sub_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.58, 1))
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vb.add_child(sub_lbl)

	# meta：难度 / 估计天数 / 语音
	var meta_lbl := Label.new()
	var diff: String = manifest.get("difficulty", "?")
	var days: int = int(manifest.get("estimated_days", 0))
	var voice_label := ""
	if voice_status == "missing":
		voice_label = "   ·   ⚠ 无语音"
	elif voice_status == "partial":
		voice_label = "   ·   部分语音"
	meta_lbl.text = "难度 %s   ·   预计 %d 时段%s" % [diff, days, voice_label]
	meta_lbl.add_theme_font_size_override("font_size", 13)
	meta_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5, 1))
	meta_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vb.add_child(meta_lbl)

	# 简介——限制为 2 行 + 省略号，防止超框
	var intro_text: String = manifest.get("intro", "")
	if intro_text != "":
		# 把原文里硬换行换成空格，让 autowrap 接管
		var oneline := intro_text.replace("\n", "  ").strip_edges()
		var intro_lbl := Label.new()
		intro_lbl.text = oneline
		intro_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intro_lbl.add_theme_font_size_override("font_size", 13)
		intro_lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.7, 1))
		intro_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		intro_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		intro_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		intro_lbl.clip_text = false
		intro_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		intro_lbl.max_lines_visible = 2
		intro_lbl.add_theme_constant_override("line_spacing", 2)
		info_vb.add_child(intro_lbl)

	if locked:
		var lock_lbl := Label.new()
		if iv and not rank_ok:
			lock_lbl.text = "🔒 需 Lv.%d 解锁（%s）" % [rank_required, iv.get_rank_title(rank_required)]
		else:
			lock_lbl.text = "🔒 暂未开放"
		lock_lbl.add_theme_font_size_override("font_size", 13)
		lock_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1))
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vb.add_child(lock_lbl)
	elif cleared:
		var replay_lbl := Label.new()
		replay_lbl.text = "已玩 %d 次（重玩仅得 30%% 经验）" % play_count
		replay_lbl.add_theme_font_size_override("font_size", 12)
		replay_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.50, 1))
		replay_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vb.add_child(replay_lbl)

	# 鼠标交互：hover 高亮 + 点击触发
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
				case_chosen.emit(case_id)
				queue_free()
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
