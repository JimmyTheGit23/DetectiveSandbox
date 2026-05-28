extends Control
## 场景热点探索叠加层：在场景图上直接显示可交互的探索热点
## 与旧 SearchPanel 并行，当 locations.json 的 search_points 含 hint_rect 时自动启用
## 简洁模式：热点仅以发光边框显示，无文字标注。按 F3 可切换调试标签。

signal close_requested()
signal search_result_acknowledged()

var _is_searching := false
var _hotspot_buttons: Array[Button] = []
var _pulsing_buttons: Array[Button] = []
var _pulse_time := 0.0
var _show_labels := true  # 默认显示热点名字标签
var _generic_label: Label
var _generic_tween: Tween
var _exit_btn: Button


func is_searching() -> bool:
	return _is_searching


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_background_clicked)
	_build_ui()


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse_val := 0.60 + 0.40 * (0.5 + 0.5 * sin(_pulse_time * 2.5))
	for btn in _pulsing_buttons:
		if is_instance_valid(btn):
			var style = btn.get_theme_stylebox("normal") as StyleBoxFlat
			if style:
				style.border_color.a = pulse_val * 0.55
				style.shadow_size = 8.0 + 6.0 * pulse_val


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if event.keycode == KEY_ESCAPE and not _is_searching:
		close_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F3:
		_show_labels = not _show_labels
		_refresh_hotspot_labels()
		get_viewport().set_input_as_handled()


# ─── 构建 UI ────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# 1) 轻暗遮罩：标识"探索模式"，但场景图仍可见
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.18)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	# 2) 探索模式标签（左上角）
	var mode_label := Label.new()
	mode_label.text = "  🔍 探索模式  —  点击场景中发光区域调查"
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

	# 3) 退出按钮（右上角）
	_build_exit_button()

	# 4) 热点层
	var hotspot_layer := Control.new()
	hotspot_layer.name = "HotspotLayer"
	hotspot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hotspot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hotspot_layer)
	_build_hotspots(hotspot_layer)

	# 5) 底部通用描述浮现标签
	_build_generic_label()


func _build_exit_button() -> void:
	_exit_btn = Button.new()
	_exit_btn.text = "✕ 退出探索"
	_exit_btn.anchor_left = 1.0
	_exit_btn.anchor_right = 1.0
	_exit_btn.anchor_top = 0.0
	_exit_btn.offset_left = -130.0
	_exit_btn.offset_right = -16.0
	_exit_btn.offset_top = 58.0
	_exit_btn.offset_bottom = 94.0

	_exit_btn.add_theme_font_size_override("font_size", 15)
	_exit_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 0.9))
	_exit_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.85, 1))
	_exit_btn.add_theme_constant_override("outline_size", 2)
	_exit_btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.75)
	style.border_color = Color(0.55, 0.42, 0.22, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	_exit_btn.add_theme_stylebox_override("normal", style)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.10, 0.08, 0.05, 0.90)
	hover.border_color = Color(0.88, 0.68, 0.30, 0.9)
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(4)
	_exit_btn.add_theme_stylebox_override("hover", hover)

	_exit_btn.pressed.connect(func(): close_requested.emit())
	add_child(_exit_btn)


func _build_generic_label() -> void:
	_generic_label = Label.new()
	_generic_label.name = "GenericLabel"
	_generic_label.anchor_left = 0.15
	_generic_label.anchor_right = 0.85
	_generic_label.anchor_top = 1.0
	_generic_label.anchor_bottom = 1.0
	_generic_label.offset_top = -72.0
	_generic_label.offset_bottom = -24.0
	_generic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_generic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_generic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_generic_label.add_theme_font_size_override("font_size", 17)
	_generic_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78, 1))
	_generic_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_generic_label.add_theme_constant_override("outline_size", 3)
	_generic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_generic_label.modulate.a = 0.0
	add_child(_generic_label)


func _build_hotspots(parent: Control) -> void:
	_hotspot_buttons.clear()
	_pulsing_buttons.clear()

	var loc: Dictionary = GameManager.current_location_data()
	var loc_id: String = GameManager.current_location

	for sp in loc.get("search_points", []):
		var hint_rect = sp.get("hint_rect", null)
		if hint_rect == null:
			continue

		var pid: String = sp.get("id", "")
		var pname: String = sp.get("name", pid)
		var key: String = "%s.%s" % [loc_id, pid]
		var done: int = GameManager.search_history.get(key, 0)
		var unlocked: bool = GameManager.is_search_point_unlocked(loc_id, pid)

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

		# 文字标签样式（默认显示搜索点名称）
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58, 0.95))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8, 1.0))
		btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		btn.add_theme_constant_override("outline_size", 3)
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_BOTTOM
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

		# 默认显示搜索点名称
		btn.text = ""
		# 存储名字供标签切换
		btn.set_meta("point_name", pname)
		btn.set_meta("point_done", done > 0)
		btn.set_meta("point_locked", not unlocked)

		if unlocked:
			if done > 0:
				_apply_done_style(btn)
			else:
				_apply_hotspot_style(btn)
				_pulsing_buttons.append(btn)
			btn.pressed.connect(_on_hotspot_clicked.bind(pid))
		else:
			var hint := GameManager.get_search_point_locked_hint(loc_id, pid)
			btn.tooltip_text = hint
			btn.modulate = Color(1, 1, 1, 0.35)
			_apply_locked_style(btn)

		parent.add_child(btn)
		_hotspot_buttons.append(btn)

	# 如果调试模式开着，刷新标签
	if _show_labels:
		_refresh_hotspot_labels()


func _refresh_hotspot_labels() -> void:
	for btn in _hotspot_buttons:
		if not is_instance_valid(btn):
			continue
		if _show_labels:
			var pname: String = btn.get_meta("point_name", "")
			var done: bool = btn.get_meta("point_done", false)
			var locked: bool = btn.get_meta("point_locked", false)
			if locked:
				btn.text = "🔒 " + pname
			elif done:
				btn.text = pname + "  ✓"
			else:
				btn.text = pname
		else:
			btn.text = ""


func _apply_hotspot_style(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.04, 0.02, 0.45)
	normal.border_color = Color(0.9, 0.75, 0.3, 0.55)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.shadow_color = Color(0.9, 0.75, 0.3, 0.25)
	normal.shadow_size = 10
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.05, 0.04, 0.02, 0.60)
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
	style.bg_color = Color(0.06, 0.05, 0.03, 0.40)
	style.border_color = Color(0.65, 0.55, 0.30, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0.6, 0.45, 0.18, 0.15)
	style.shadow_size = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.10, 0.07, 0.04, 0.65)
	hover.border_color = Color(0.85, 0.70, 0.35, 0.80)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(5)
	hover.shadow_color = Color(0.85, 0.60, 0.22, 0.30)
	hover.shadow_size = 10
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.72, 1))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01, 1))


func _apply_locked_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.30)
	style.border_color = Color(0.4, 0.4, 0.4, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))
	btn.add_theme_constant_override("outline_size", 2)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))


# ─── 非热点区域点击 → 通用描述 ─────────────────────────────────────────────

func _on_background_clicked(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _is_searching:
		return
	# 显示场景通用描述
	_show_generic_description()


func _show_generic_description() -> void:
	var loc: Dictionary = GameManager.current_location_data()
	var desc: String = loc.get("description", "这里没有什么特别的。")
	_generic_label.text = desc

	# 取消之前的 tween
	if _generic_tween and _generic_tween.is_valid():
		_generic_tween.kill()

	_generic_tween = create_tween()
	_generic_label.modulate.a = 0.0
	_generic_tween.tween_property(_generic_label, "modulate:a", 1.0, 0.3)
	_generic_tween.tween_interval(2.5)
	_generic_tween.tween_property(_generic_label, "modulate:a", 0.0, 0.5)


# ─── 探索流程 ───────────────────────────────────────────────────────────────

func _on_hotspot_clicked(point_id: String) -> void:
	if _is_searching:
		return
	_is_searching = true
	_set_all_disabled(true)
	_exit_btn.disabled = true

	var point_name: String = _point_name(point_id)
	var result: Dictionary = GameManager.resolve_search(GameManager.current_location, point_id)
	await _show_result_dialog(point_name, result)

	if not is_inside_tree():
		return

	search_result_acknowledged.emit()
	_refresh_all()
	_is_searching = false
	_set_all_disabled(false)
	_exit_btn.disabled = false

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


func _set_all_disabled(disabled: bool) -> void:
	# 搜索时隐藏热点层（避免边框透出弹窗）
	var hotspot_layer = get_node_or_null("HotspotLayer")
	if hotspot_layer:
		hotspot_layer.visible = not disabled
	for btn in _hotspot_buttons:
		if is_instance_valid(btn) and not btn.get_meta("point_locked", false):
			btn.disabled = disabled


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


# ─── 探索结果（底部浮现） ───────────────────────────────────────────────────

func _show_result_dialog(point_name: String, result: Dictionary) -> void:
	# 多步骤调查：有 sub_choices 时走专用弹窗
	var sub_choices: Array = result.get("sub_choices", [])
	if sub_choices.size() > 0:
		var intro: String = result.get("intro_text", "")
		await _show_sub_choices_dialog(point_name, intro, sub_choices)
		return

	# 用底部浮现文字显示结果（不弹窗）
	var text: String = str(result.get("narration", ""))
	if text == "":
		text = str(result.get("intro_text", ""))
	if text == "":
		text = "你仔细查看了这里。"
	if result.get("gained_evidence", "") != "":
		var ev: Dictionary = GameManager.evidence_data.get(result.gained_evidence, {})
		text += "\n【获得证据：%s】" % ev.get("name", "")
	if result.get("gained_clue", "") != "":
		var cl: Dictionary = GameManager.evidence_data.get(result.gained_clue, {})
		text += "\n【获得线索：%s】" % cl.get("name", "")

	# 显示底部浮现文字并等待玩家点击关闭
	await _show_bottom_result(text)


## 底部浮现结果文字，点击任意处关闭
func _show_bottom_result(text: String) -> void:
	# 创建底部结果面板
	var result_panel := PanelContainer.new()
	result_panel.name = "BottomResultPanel"
	result_panel.anchor_left = 0.08
	result_panel.anchor_right = 0.92
	result_panel.anchor_top = 1.0
	result_panel.anchor_bottom = 1.0
	result_panel.offset_top = -180.0
	result_panel.offset_bottom = -20.0
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.035, 0.025, 0.92)
	panel_style.border_color = Color(0.65, 0.50, 0.25, 0.7)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	result_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(result_panel)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.76, 1))
	label.text = text + "\n\n[center][color=#aa8844][i]— 点击任意处继续 —[/i][/color][/center]"
	result_panel.add_child(label)

	# 淡入
	result_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(result_panel, "modulate:a", 1.0, 0.3)
	await tween.finished

	# 等待任意点击
	var clicked: Array[bool] = [false]
	var click_handler := func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked[0] = true
	gui_input.connect(click_handler)

	while not clicked[0]:
		await get_tree().process_frame
		if not is_inside_tree():
			return

	gui_input.disconnect(click_handler)

	# 淡出
	var fade := create_tween()
	fade.tween_property(result_panel, "modulate:a", 0.0, 0.3)
	await fade.finished
	if is_instance_valid(result_panel):
		result_panel.queue_free()


# ─── 多步骤调查选项弹窗 ─────────────────────────────────────────────────────

func _show_sub_choices_dialog(point_name: String, intro_text: String, sub_choices: Array) -> void:
	var overlay := Control.new()
	overlay.name = "SubChoicesOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.50)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 0)
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

	# 标题
	var title := Label.new()
	title.text = "── %s ──" % point_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1))
	vbox.add_child(title)

	# 引入文本
	var intro_label := RichTextLabel.new()
	intro_label.custom_minimum_size = Vector2(720, 80)
	intro_label.bbcode_enabled = true
	intro_label.fit_content = true
	intro_label.scroll_active = false
	intro_label.add_theme_font_size_override("normal_font_size", 19)
	intro_label.add_theme_color_override("default_color", Color(0.9, 0.86, 0.76, 1))
	intro_label.text = intro_text
	vbox.add_child(intro_label)

	# 分隔
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.55, 0.42, 0.22, 0.6))
	vbox.add_child(sep)

	# 提示
	var hint := Label.new()
	hint.text = "你打算怎么做？"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.68, 0.52, 1))
	vbox.add_child(hint)

	# 选项按钮
	var chosen: Array[int] = [-1]
	var choice_btns: Array[Button] = []
	for i in range(sub_choices.size()):
		var choice: Dictionary = sub_choices[i]
		var btn := Button.new()
		btn.text = "  ▸  " + choice.get("text", "")
		btn.custom_minimum_size = Vector2(0, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 19)
		btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.85, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
		btn.add_theme_constant_override("outline_size", 3)
		btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.10, 0.07, 0.04, 0.75)
		btn_style.border_color = Color(0.62, 0.48, 0.22, 0.6)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(5)
		btn_style.content_margin_left = 12
		btn_style.content_margin_right = 12
		btn.add_theme_stylebox_override("normal", btn_style)
		var hover_style := btn_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color(0.14, 0.10, 0.05, 0.90)
		hover_style.border_color = Color(0.88, 0.68, 0.30, 0.9)
		btn.add_theme_stylebox_override("hover", hover_style)
		var idx := i
		btn.pressed.connect(func():
			chosen[0] = idx
			for b in choice_btns:
				b.disabled = true
		)
		vbox.add_child(btn)
		choice_btns.append(btn)

	# 等待玩家选择
	while chosen[0] < 0:
		await get_tree().process_frame
		if not is_inside_tree():
			return

	# 玩家选择了一个选项 → 应用效果并显示结果
	var chosen_choice: Dictionary = sub_choices[chosen[0]]
	_apply_sub_choice_effects(chosen_choice)

	# 替换面板内容为结果
	for child in vbox.get_children():
		child.queue_free()
	await get_tree().process_frame

	var result_title := Label.new()
	result_title.text = "── 调查结果 ──"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 24)
	result_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1))
	vbox.add_child(result_title)

	var result_body := RichTextLabel.new()
	result_body.custom_minimum_size = Vector2(720, 160)
	result_body.bbcode_enabled = true
	result_body.fit_content = true
	result_body.scroll_active = false
	result_body.add_theme_font_size_override("normal_font_size", 20)
	result_body.add_theme_color_override("default_color", Color(0.9, 0.86, 0.76, 1))
	var result_text: String = chosen_choice.get("narration", "")
	var ev_id: String = chosen_choice.get("evidence", "")
	if ev_id != "":
		var ev = GameManager.evidence_data.get(ev_id, {})
		result_text += "\n\n【获得证据：%s】" % ev.get("name", ev_id)
	var cl_id: String = chosen_choice.get("clue", "")
	if cl_id != "":
		var cl = GameManager.evidence_data.get(cl_id, {})
		result_text += "\n\n【获得线索：%s】" % cl.get("name", cl_id)
	result_body.text = result_text
	vbox.add_child(result_body)

	var ok_btn := Button.new()
	ok_btn.text = "知 道 了"
	ok_btn.custom_minimum_size = Vector2(180, 44)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_btn.add_theme_font_size_override("font_size", 20)
	ok_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58, 1))
	vbox.add_child(ok_btn)

	await ok_btn.pressed
	if is_instance_valid(overlay):
		overlay.queue_free()


## 应用多步骤调查选项的效果
func _apply_sub_choice_effects(choice: Dictionary) -> void:
	var ev: String = choice.get("evidence", "")
	if ev != "":
		GameManager.add_evidence(ev)
	var cl: String = choice.get("clue", "")
	if cl != "":
		GameManager.add_clue(cl)
	for f in choice.get("set_flags", []):
		GameManager.set_flag(str(f))
