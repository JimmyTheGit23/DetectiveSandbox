extends Control
## 场景热点探索叠加层：在场景图上直接显示可交互的探索热点
## 与旧 SearchPanel 并行，当 locations.json 的 search_points 含 hint_rect 时自动启用

signal close_requested()
signal search_result_acknowledged()

var _is_searching := false
var _hotspot_buttons: Array[Button] = []
var _pulsing_buttons: Array[Button] = []
var _side_list_vbox: VBoxContainer
var _close_btn: Button
var _result_box: RichTextLabel
var _pulse_time := 0.0


func is_searching() -> bool:
	return _is_searching


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse_val := 0.60 + 0.40 * (0.5 + 0.5 * sin(_pulse_time * 2.5))
	for btn in _pulsing_buttons:
		if is_instance_valid(btn):
			# 只让边框发光脉冲，文字保持稳定
			var style = btn.get_theme_stylebox("normal") as StyleBoxFlat
			if style:
				style.border_color.a = pulse_val * 0.55
				style.shadow_size = 8.0 + 6.0 * pulse_val


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not _is_searching:
		close_requested.emit()
		get_viewport().set_input_as_handled()


# ─── 构建 UI ────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# 1) 轻暗遮罩：标识"探索模式"，但场景图仍可见
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.18)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	# 2) 探索模式标签
	var mode_label := Label.new()
	mode_label.text = "  🔍 探索模式  —  点击场景中发光区域调查  |  ESC 退出"
	mode_label.anchor_left = 0.0
	mode_label.anchor_top = 0.0
	mode_label.offset_left = 16.0
	mode_label.offset_top = 60.0
	mode_label.add_theme_font_size_override("font_size", 16)
	mode_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 0.75))
	mode_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	mode_label.add_theme_constant_override("outline_size", 3)
	mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mode_label)

	# 3) 热点层
	var hotspot_layer := Control.new()
	hotspot_layer.name = "HotspotLayer"
	hotspot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hotspot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hotspot_layer)
	_build_hotspots(hotspot_layer)

	# 4) 右侧辅助面板
	_build_side_panel()


func _build_hotspots(parent: Control) -> void:
	_hotspot_buttons.clear()
	_pulsing_buttons.clear()

	var loc := GameManager.current_location_data()
	var loc_id: String = GameManager.current_location

	for sp in loc.get("search_points", []):
		var hint_rect = sp.get("hint_rect", null)
		if hint_rect == null:
			continue

		var pid: String = sp.get("id", "")
		var pname: String = sp.get("name", pid)
		var key := "%s.%s" % [loc_id, pid]
		var done: int = GameManager.search_history.get(key, 0)
		var unlocked := GameManager.is_search_point_unlocked(loc_id, pid)

		var btn := Button.new()
		btn.name = "Hotspot_%s" % pid
		btn.flat = true
		# 用 anchor 实现归一化定位，窗口缩放时自动跟随
		btn.anchor_left = hint_rect[0]
		btn.anchor_top = hint_rect[1]
		btn.anchor_right = hint_rect[0] + hint_rect[2]
		btn.anchor_bottom = hint_rect[1] + hint_rect[3]
		btn.offset_left = 0.0
		btn.offset_top = 0.0
		btn.offset_right = 0.0
		btn.offset_bottom = 0.0
		btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
		btn.grow_vertical = Control.GROW_DIRECTION_BOTH

		if unlocked:
			if done > 0:
				btn.text = pname + "  ✓"
				_apply_done_style(btn)
			else:
				btn.text = pname
				_apply_hotspot_style(btn)
				_pulsing_buttons.append(btn)
			btn.pressed.connect(_on_hotspot_clicked.bind(pid))
		else:
			var hint := GameManager.get_search_point_locked_hint(loc_id, pid)
			btn.text = "🔒 " + pname
			btn.tooltip_text = hint
			btn.modulate = Color(1, 1, 1, 0.35)
			_apply_locked_style(btn)

		parent.add_child(btn)
		_hotspot_buttons.append(btn)


func _apply_hotspot_style(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.04, 0.02, 0.55)
	normal.border_color = Color(0.9, 0.75, 0.3, 0.55)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.shadow_color = Color(0.9, 0.75, 0.3, 0.25)
	normal.shadow_size = 10
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.05, 0.04, 0.02, 0.70)
	hover.border_color = Color(1.0, 0.85, 0.4, 0.9)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(4)
	hover.shadow_color = Color(1.0, 0.85, 0.4, 0.5)
	hover.shadow_size = 14
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.05, 0.04, 0.02, 0.80)
	pressed.border_color = Color(1.0, 0.95, 0.6, 1.0)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.85, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.6, 1))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))


func _apply_done_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.035, 0.62)
	style.border_color = Color(0.95, 0.76, 0.32, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0.95, 0.62, 0.18, 0.24)
	style.shadow_size = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.14, 0.09, 0.04, 0.78)
	hover.border_color = Color(1.0, 0.86, 0.42, 0.95)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(5)
	hover.shadow_color = Color(1.0, 0.72, 0.28, 0.40)
	hover.shadow_size = 14
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.72, 1))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01, 1))



func _apply_locked_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.40)
	style.border_color = Color(0.4, 0.4, 0.4, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))
	btn.add_theme_constant_override("outline_size", 2)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))


# ─── 右侧辅助面板 ──────────────────────────────────────────────────────────

func _build_side_panel() -> void:
	var side_panel := PanelContainer.new()
	side_panel.name = "SidePanel"
	# 固定贴右但保留右侧安全边距，避免窄窗口/缩放时伸到屏幕外。
	side_panel.anchor_left = 1.0
	side_panel.anchor_right = 1.0
	var panel_w: float = min(260.0, get_viewport_rect().size.x * 0.34)
	side_panel.offset_left = -panel_w - 16.0
	side_panel.offset_right = -16.0
	side_panel.offset_top = 56.0
	side_panel.offset_bottom = -16.0


	var side_style := StyleBoxFlat.new()
	side_style.bg_color = Color(0.06, 0.05, 0.04, 0.85)
	side_style.border_color = Color(0.55, 0.42, 0.22, 0.7)
	side_style.set_border_width_all(1)
	side_style.set_corner_radius_all(6)
	side_style.content_margin_left = 10
	side_style.content_margin_right = 10
	side_style.content_margin_top = 12
	side_style.content_margin_bottom = 12
	side_panel.add_theme_stylebox_override("panel", side_style)
	add_child(side_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	side_panel.add_child(vbox)

	var title := Label.new()
	title.text = "── 可疑之处 ──"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1))
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(panel_w - 28.0, 200)

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_side_list_vbox = VBoxContainer.new()
	_side_list_vbox.add_theme_constant_override("separation", 4)
	_side_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_side_list_vbox)

	_result_box = RichTextLabel.new()
	_result_box.custom_minimum_size = Vector2(panel_w - 28.0, 96)

	_result_box.bbcode_enabled = true
	_result_box.add_theme_font_size_override("normal_font_size", 16)
	_result_box.add_theme_color_override("default_color", Color(0.9, 0.86, 0.76, 1))
	_result_box.text = "[i]点击场景发光区域或列表项探索。[/i]"
	vbox.add_child(_result_box)

	_close_btn = Button.new()
	_close_btn.text = "关  闭"
	_close_btn.custom_minimum_size = Vector2(panel_w - 28.0, 40)

	_close_btn.add_theme_font_size_override("font_size", 18)
	_close_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58, 1))
	_close_btn.pressed.connect(func(): close_requested.emit())
	vbox.add_child(_close_btn)

	_build_side_list()


func _build_side_list() -> void:
	for child in _side_list_vbox.get_children():
		child.queue_free()

	var loc := GameManager.current_location_data()
	var loc_id: String = GameManager.current_location
	for sp in loc.get("search_points", []):
		var pid: String = sp.get("id", "")
		var pname: String = sp.get("name", pid)
		var cost: int = int(sp.get("time_cost", 1))
		var key := "%s.%s" % [loc_id, pid]
		var done: int = GameManager.search_history.get(key, 0)
		var unlocked := GameManager.is_search_point_unlocked(loc_id, pid)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 15)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		if unlocked:
			var done_mark := "  ✓" if done > 0 else ""
			btn.text = "  %s  [耗时%d]%s" % [pname, cost, done_mark]
			btn.disabled = _is_searching
			btn.pressed.connect(_on_hotspot_clicked.bind(pid))
			if done > 0:
				btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42, 0.95))
				btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.68, 1))
			else:
				btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1))
				btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8, 1))

		else:
			var hint := GameManager.get_search_point_locked_hint(loc_id, pid)
			btn.text = "  🔒 %s" % pname
			btn.disabled = true
			btn.tooltip_text = hint
			btn.modulate.a = 0.5

		_side_list_vbox.add_child(btn)


# ─── 探索流程 ───────────────────────────────────────────────────────────────

func _on_hotspot_clicked(point_id: String) -> void:
	if _is_searching:
		return
	_is_searching = true
	_set_all_disabled(true)
	_close_btn.disabled = true

	var point_name := _point_name(point_id)
	var planned_cost := _point_cost(point_id)

	_result_box.text = "[center][color=#ead48a]你开始调查「%s」……[/color][/center]" % point_name
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return

	_result_box.text = "[center][color=#ead48a]探索中……[/color]\n[i]你放慢脚步，重新检查每一个细节。[/i][/center]"
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return

	var result := GameManager.resolve_search(GameManager.current_location, point_id)
	var cost: int = int(result.get("time_cost", planned_cost))
	GameManager.advance_period(cost)
	_result_box.text = "[center][color=#d8c08a]本次探索消耗了 %d 段时辰。[/color][/center]" % cost
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return

	await _show_result_dialog(point_name, result, cost)
	if not is_inside_tree():
		return

	search_result_acknowledged.emit()
	_refresh_all()
	_result_box.text = "[i]请选择下一处可疑点继续探索。[/i]"
	_is_searching = false
	_set_all_disabled(false)
	_close_btn.disabled = false

	# 触发对话（用于"在某处遇见 NPC"剧情事件）
	var trigger_npc: String = result.get("trigger_dialogue", "")
	if trigger_npc != "":
		var start_node: String = result.get("trigger_dialogue_start", "")
		close_requested.emit()
		await get_tree().process_frame
		if start_node != "":
			DialogueManager.start_dialogue_at(trigger_npc, start_node)
		else:
			DialogueManager.start_dialogue(trigger_npc)


func _point_name(point_id: String) -> String:
	for sp in GameManager.current_location_data().get("search_points", []):
		if sp.get("id", "") == point_id:
			return sp.get("name", point_id)
	return point_id


func _point_cost(point_id: String) -> int:
	for sp in GameManager.current_location_data().get("search_points", []):
		if sp.get("id", "") == point_id:
			return int(sp.get("time_cost", 1))
	return 1


func _set_all_disabled(disabled: bool) -> void:
	for btn in _hotspot_buttons:
		if is_instance_valid(btn) and not btn.text.begins_with("🔒"):
			btn.disabled = disabled
	for child in _side_list_vbox.get_children():
		if child is Button and not child.text.begins_with("  🔒"):
			child.disabled = disabled


func _refresh_all() -> void:
	# 清除旧热点
	for btn in _hotspot_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_hotspot_buttons.clear()
	_pulsing_buttons.clear()

	var hotspot_layer = get_node_or_null("HotspotLayer")
	if hotspot_layer:
		_build_hotspots(hotspot_layer)
	_build_side_list()


# ─── 探索结果弹窗 ───────────────────────────────────────────────────────────

func _show_result_dialog(point_name: String, result: Dictionary, cost: int) -> void:
	var overlay := Control.new()
	overlay.name = "SearchResultOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 360)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.065, 0.045, 0.96)
	style.border_color = Color(0.72, 0.56, 0.28, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 18
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "── 探索结果 · %s ──" % point_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1))
	vbox.add_child(title)

	var body := RichTextLabel.new()
	body.custom_minimum_size = Vector2(700, 220)
	body.bbcode_enabled = true
	body.fit_content = false
	body.scroll_active = true
	body.add_theme_font_size_override("normal_font_size", 20)
	body.add_theme_color_override("default_color", Color(0.9, 0.86, 0.76, 1))
	body.text = _result_dialog_text(result, cost)
	vbox.add_child(body)

	var btn := Button.new()
	btn.text = "知 道 了"
	btn.custom_minimum_size = Vector2(180, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58, 1))
	vbox.add_child(btn)

	await btn.pressed
	if is_instance_valid(overlay):
		overlay.queue_free()


func _result_dialog_text(result: Dictionary, cost: int) -> String:
	var txt: String = "你完成了这次调查。\n\n"
	txt += result.get("narration", "")
	txt += "\n\n—— 本次探索消耗了 %d 段时辰。" % cost
	if result.get("gained_evidence", "") != "":
		var ev = GameManager.evidence_data.get(result.gained_evidence, {})
		txt += "\n\n【获得证据：%s】" % ev.get("name", "")
	if result.get("gained_clue", "") != "":
		var cl = GameManager.evidence_data.get(result.gained_clue, {})
		txt += "\n\n【获得线索：%s】" % cl.get("name", "")
	return txt
