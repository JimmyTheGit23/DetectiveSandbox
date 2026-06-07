extends Control
## 设置面板：三栏切换 —— 存档 / 读档 / 设置（音量+GM工具）

signal close_requested()
signal return_to_title_requested()
signal game_reset_requested()

@onready var panel: PanelContainer = $Panel

var _bgm_slider: HSlider
var _voice_slider: HSlider
var _bgm_value_lbl: Label
var _voice_value_lbl: Label
var _gm_check: CheckBox
var _gm_preset_select: OptionButton
var _gm_confront_select: OptionButton
var _gm_dialogue_input: LineEdit
var _gm_narration_input: LineEdit
var _gm_event_input: LineEdit
var _reset_button: Button
var _settings: Node
var initial_tab: int = 0
var title_load_only: bool = false

# 标签页系统
var _tab_bar: HBoxContainer
var _tab_buttons: Array[Button] = []
var _tab_pages: Array[Control] = []
var _current_tab: int = 0
# 存档/读档槽位 UI
var _save_slot_panels: Array[PanelContainer] = []
var _load_slot_panels: Array[PanelContainer] = []


func _ready() -> void:
	_settings = get_node_or_null("/root/SettingsService")
	_build_ui()
	if title_load_only:
		_refresh_load_slots()
		return
	open_tab(initial_tab)


func _bgm_init_value() -> float:
	return float(_settings.bgm_volume) if _settings else 0.8


func _voice_init_value() -> float:
	return float(_settings.voice_volume) if _settings else 1.0


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(root)

	if title_load_only:
		_build_title_load_page(root)
		return

	# ── 标签栏 ──
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 0)
	_tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_tab_bar)

	var tab_names := ["存  档", "读  档", "设  置"]
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_tab_clicked.bind(i))
		_tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	# 分割线
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.6, 0.45, 0.25, 0.6))
	root.add_child(sep)

	# ── 标签页容器 ──
	var page_container := Control.new()
	page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(page_container)

	# 页0: 存档
	var save_page := _build_save_page()
	save_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	save_page.visible = true
	page_container.add_child(save_page)
	_tab_pages.append(save_page)

	# 页1: 读档
	var load_page := _build_load_page()
	load_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_page.visible = false
	page_container.add_child(load_page)
	_tab_pages.append(load_page)

	# 页2: 设置
	var settings_page := _build_settings_page()
	settings_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_page.visible = false
	page_container.add_child(settings_page)
	_tab_pages.append(settings_page)

	_update_tab_visuals()


func _build_title_load_page(root: VBoxContainer) -> void:
	var page_container := Control.new()
	page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(page_container)

	var load_page := _build_load_page()
	load_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_page.visible = true
	page_container.add_child(load_page)
	_tab_pages.append(load_page)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.6, 0.45, 0.25, 0.6))
	root.add_child(sep)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.custom_minimum_size = Vector2(0, 58)
	root.add_child(footer)

	var back_btn := Button.new()
	back_btn.text = "返  回"
	back_btn.flat = true
	back_btn.custom_minimum_size = Vector2(150, 42)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1))
	back_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.78, 1))
	back_btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
	back_btn.pressed.connect(_on_close)
	footer.add_child(back_btn)


# ─── 标签切换 ───
func open_tab(index: int) -> void:
	var clamped := clampi(index, 0, max(_tab_pages.size() - 1, 0))
	_on_tab_clicked(clamped)


func _unhandled_input(event: InputEvent) -> void:
	if not title_load_only:
		return
	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _on_tab_clicked(index: int) -> void:
	_current_tab = index
	for i in range(_tab_pages.size()):
		_tab_pages[i].visible = (i == index)
	_update_tab_visuals()
	# 切到存档/读档页时刷新槽位信息
	if index == 0:
		_refresh_save_slots()
	elif index == 1:
		_refresh_load_slots()


func _update_tab_visuals() -> void:
	for i in range(_tab_buttons.size()):
		if i == _current_tab:
			_tab_buttons[i].add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
			_tab_buttons[i].add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.65))
		else:
			_tab_buttons[i].add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
			_tab_buttons[i].add_theme_color_override("font_hover_color", Color(0.85, 0.78, 0.62))


# ═══════════════════════════════════════════
# 存档页
# ═══════════════════════════════════════════
func _build_save_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.name = "SaveVBox"
	scroll.add_child(vbox)

	for slot in range(1, GameManager.MANUAL_SLOT_COUNT + 1):
		var panel_node := _make_slot_panel(slot, true)
		vbox.add_child(panel_node)
		_save_slot_panels.append(panel_node)

	return scroll


# ═══════════════════════════════════════════
# 读档页
# ═══════════════════════════════════════════
func _build_load_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.name = "LoadVBox"
	scroll.add_child(vbox)

	for slot in range(1, GameManager.MANUAL_SLOT_COUNT + 1):
		var panel_node := _make_slot_panel(slot, false)
		vbox.add_child(panel_node)
		_load_slot_panels.append(panel_node)

	return scroll


func _make_slot_panel(slot: int, is_save: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 100)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.04, 0.85)
	sb.border_color = Color(0.5, 0.38, 0.2, 0.7)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_child(hbox)

	# 左侧：槽位信息
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	var slot_label := Label.new()
	slot_label.name = "SlotLabel"
	slot_label.text = "槽位 %d" % slot
	slot_label.add_theme_font_size_override("font_size", 20)
	slot_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.65))
	info_vbox.add_child(slot_label)

	var detail_label := Label.new()
	detail_label.name = "DetailLabel"
	detail_label.text = "空"
	detail_label.add_theme_font_size_override("font_size", 14)
	detail_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	info_vbox.add_child(detail_label)

	var time_label := Label.new()
	time_label.name = "TimeLabel"
	time_label.text = ""
	time_label.add_theme_font_size_override("font_size", 12)
	time_label.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42, 0.8))
	info_vbox.add_child(time_label)

	# 右侧：操作按钮
	var btn := Button.new()
	btn.name = "ActionButton"
	btn.custom_minimum_size = Vector2(100, 40)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	if is_save:
		btn.text = "保  存"
		btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.78))
		btn.pressed.connect(_on_save_slot.bind(slot))
	else:
		btn.text = "读  取"
		btn.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.78, 1.0, 1.0))
		btn.pressed.connect(_on_load_slot.bind(slot))
	hbox.add_child(btn)

	# 存储元数据引用
	p.set_meta("slot", slot)
	p.set_meta("slot_label", slot_label)
	p.set_meta("detail_label", detail_label)
	p.set_meta("time_label", time_label)
	p.set_meta("action_btn", btn)

	return p


func _refresh_save_slots() -> void:
	for p in _save_slot_panels:
		_update_slot_panel(p, true)


func _refresh_load_slots() -> void:
	for p in _load_slot_panels:
		_update_slot_panel(p, false)


func _update_slot_panel(p: PanelContainer, is_save: bool) -> void:
	var slot: int = p.get_meta("slot", 1)
	var info := GameManager.get_slot_info(slot)
	var detail_label: Label = p.get_meta("detail_label")
	var time_label: Label = p.get_meta("time_label")
	var action_btn: Button = p.get_meta("action_btn")

	if info.get("empty", true):
		detail_label.text = "空存档位" if is_save else "无存档"
		time_label.text = ""
		if is_save:
			action_btn.disabled = false
			action_btn.text = "保  存"
		else:
			action_btn.disabled = true
			action_btn.text = "无存档"
	else:
		var loc: String = info.get("location", "")
		var day: int = info.get("day", 1)
		var ev_count: int = info.get("evidence_count", 0)
		detail_label.text = "%s · 第%d天 · 证据×%d" % [loc, day, ev_count]
		time_label.text = str(info.get("timestamp", ""))
		action_btn.disabled = false
		if is_save:
			action_btn.text = "覆  盖"
		else:
			action_btn.text = "读  取"


func _on_save_slot(slot: int) -> void:
	# 二次确认（覆盖已有存档时）
	var info := GameManager.get_slot_info(slot)
	if not info.get("empty", true):
		_show_save_confirm(slot)
		return
	_do_save_slot(slot)


func _show_save_confirm(slot: int) -> void:
	var overlay := ColorRect.new()
	overlay.name = "SaveConfirm"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.02, 0.03, 0.70)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var confirm_panel := PanelContainer.new()
	confirm_panel.custom_minimum_size = Vector2(400, 0)
	center.add_child(confirm_panel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.07, 0.95)
	sb.border_color = Color(0.55, 0.42, 0.22, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	confirm_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	confirm_panel.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "槽位 %d 已有存档，确定覆盖？" % slot
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.65))
	vbox.add_child(lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "取  消"
	cancel_btn.custom_minimum_size = Vector2(100, 36)
	cancel_btn.flat = true
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.add_theme_color_override("font_color", Color(0.65, 0.62, 0.55))
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "确定覆盖"
	confirm_btn.custom_minimum_size = Vector2(100, 36)
	confirm_btn.flat = true
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	confirm_btn.pressed.connect(func():
		overlay.queue_free()
		_do_save_slot(slot)
	)
	btn_row.add_child(confirm_btn)


func _do_save_slot(slot: int) -> void:
	if GameManager.save_to_slot(slot):
		_flash_msg("已保存到槽位 %d" % slot)
		_refresh_save_slots()
	else:
		_flash_msg("保存失败")


func _on_load_slot(slot: int) -> void:
	if GameManager.load_from_slot(slot):
		_flash_msg("已读取槽位 %d" % slot)
		close_requested.emit()
		var main = get_tree().current_scene
		if main and main.has_method("resume_loaded_game"):
			main.resume_loaded_game()
		elif main and main.has_method("_on_location_changed"):
			# 回退兼容：若主场景尚未接入统一恢复入口，至少保持旧行为。
			main._on_location_changed(GameManager.current_location, true)
			if main.has_method("_update_top_bar"):
				main._update_top_bar()
			if main.has_method("_hide_title"):
				main._hide_title()
			menu_panel_visible(main, true)
	else:
		_flash_msg("读取失败")


func menu_panel_visible(main: Node, visible: bool) -> void:
	var menu = main.get_node_or_null("RightMenu")
	if menu:
		menu.visible = visible


func _flash_msg(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(lbl.queue_free)


# ═══════════════════════════════════════════
# 设置页（原内容）
# ═══════════════════════════════════════════
func _build_settings_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# 音乐音量
	vbox.add_child(_make_volume_row("音  乐", _bgm_init_value(), true))
	# 语音音量
	vbox.add_child(_make_volume_row("语  音", _voice_init_value(), false))

	# 间距
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	# GM 指令区
	var gm_sep := HSeparator.new()
	gm_sep.add_theme_color_override("separator", Color(0.6, 0.45, 0.25, 0.4))
	vbox.add_child(gm_sep)

	var gm_box := HBoxContainer.new()
	gm_box.add_theme_constant_override("separation", 10)
	gm_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(gm_box)

	var gm_label := Label.new()
	gm_label.text = "GM 指令"
	gm_label.add_theme_font_size_override("font_size", 16)
	gm_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3, 1))
	gm_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gm_box.add_child(gm_label)

	_gm_check = CheckBox.new()
	_gm_check.text = "解锁全部"
	_gm_check.button_pressed = bool(_settings.get("gm_unlock_all")) if _settings else false
	_gm_check.add_theme_font_size_override("font_size", 14)
	_gm_check.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55, 1))
	_gm_check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gm_check.toggled.connect(_on_gm_unlock_toggled)
	gm_box.add_child(_gm_check)

	var gm_hint := Label.new()
	gm_hint.text = "无视等级限制"
	gm_hint.add_theme_font_size_override("font_size", 12)
	gm_hint.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42, 0.8))
	gm_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gm_box.add_child(gm_hint)

	_build_gm_jump_tools(vbox)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer2)

	# 按钮区
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_box)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	btn_box.add_child(btn_row)

	var btn_title := Button.new()
	btn_title.text = "返回标题画面"
	btn_title.custom_minimum_size = Vector2(0, 40)
	btn_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_title.add_theme_font_size_override("font_size", 17)
	btn_title.pressed.connect(_on_return_title)
	btn_row.add_child(btn_title)

	var btn_reset := Button.new()
	btn_reset.text = "重置游戏进度"
	btn_reset.custom_minimum_size = Vector2(0, 40)
	btn_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_reset.add_theme_font_size_override("font_size", 17)
	btn_reset.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))
	btn_reset.pressed.connect(_on_reset_game)
	btn_row.add_child(btn_reset)
	_reset_button = btn_reset

	var btn_close := Button.new()
	btn_close.text = "关闭设置"
	btn_close.custom_minimum_size = Vector2(0, 40)
	btn_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_close.add_theme_font_size_override("font_size", 17)
	btn_close.pressed.connect(_on_close)
	btn_row.add_child(btn_close)

	var reset_hint := Label.new()
	reset_hint.text = "（清除所有案件进度、经验和存档，不可恢复）"
	reset_hint.add_theme_font_size_override("font_size", 12)
	reset_hint.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42, 0.8))
	btn_box.add_child(reset_hint)

	return scroll


# ─── GM 工具（从原代码保留） ───
func _build_gm_jump_tools(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	parent.add_child(box)

	var title := Label.new()
	title.text = "GM 跳转"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.96, 0.72, 0.36, 1))
	box.add_child(title)

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	box.add_child(preset_row)

	_gm_preset_select = OptionButton.new()
	_gm_preset_select.custom_minimum_size = Vector2(250, 32)
	_gm_preset_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_gm_presets()
	preset_row.add_child(_gm_preset_select)

	var btn_apply := _make_gm_button("套预设", 82)
	btn_apply.pressed.connect(_on_gm_apply_preset)
	preset_row.add_child(btn_apply)

	var btn_preset_confront := _make_gm_button("预设对峙", 96)
	btn_preset_confront.pressed.connect(_on_gm_preset_confront)
	preset_row.add_child(btn_preset_confront)

	_gm_confront_select = OptionButton.new()
	_gm_confront_select.custom_minimum_size = Vector2(210, 32)
	for key in ["confrontation_wang", "confrontation", "confrontation_final"]:
		_gm_confront_select.add_item(key)
		_gm_confront_select.set_item_metadata(_gm_confront_select.get_item_count() - 1, key)
	preset_row.add_child(_gm_confront_select)
	var btn_confront := _make_gm_button("进对峙", 76)
	btn_confront.pressed.connect(_on_gm_start_confrontation)
	preset_row.add_child(btn_confront)

	var dialogue_row := HBoxContainer.new()
	dialogue_row.add_theme_constant_override("separation", 6)
	box.add_child(dialogue_row)
	_gm_dialogue_input = _make_gm_input("li_zheng.ask_next_step", 260)
	dialogue_row.add_child(_gm_dialogue_input)
	var btn_dialogue := _make_gm_button("跳对话", 76)
	btn_dialogue.pressed.connect(_on_gm_jump_dialogue)
	dialogue_row.add_child(btn_dialogue)

	_gm_narration_input = _make_gm_input("prologue.cabin_prologue_1", 260)
	dialogue_row.add_child(_gm_narration_input)
	var btn_narration := _make_gm_button("跳叙事", 76)
	btn_narration.pressed.connect(_on_gm_jump_narration)
	dialogue_row.add_child(btn_narration)

	var event_row := HBoxContainer.new()
	event_row.add_theme_constant_override("separation", 6)
	box.add_child(event_row)
	_gm_event_input = _make_gm_input("evt_shen_evidence_ready", 260)
	event_row.add_child(_gm_event_input)
	var btn_event := _make_gm_button("播事件", 76)
	btn_event.pressed.connect(_on_gm_play_event)
	event_row.add_child(btn_event)

	var btn_epilogue := _make_gm_button("固定结尾", 96)
	btn_epilogue.pressed.connect(_on_gm_fixed_epilogue)
	event_row.add_child(btn_epilogue)

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_row.add_child(fill)


func _make_gm_button(text: String, width := 92.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, 32)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(1.0, 0.74, 0.32, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.55, 1))
	return btn


func _make_gm_input(placeholder: String, width := 240.0) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size = Vector2(width, 32)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return input


func _populate_gm_presets() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("gm_preset_options"):
		for item in main.gm_preset_options():
			var label := str(item.get("label", item.get("id", "")))
			var preset_id := str(item.get("id", ""))
			_gm_preset_select.add_item(label)
			_gm_preset_select.set_item_metadata(_gm_preset_select.get_item_count() - 1, preset_id)
	else:
		for preset_id in ["cabin_start", "wang_confront", "phase2_investigate", "main_confront_ready", "phase3_after_agui", "final_ready", "fixed_epilogue"]:
			_gm_preset_select.add_item(preset_id)
			_gm_preset_select.set_item_metadata(_gm_preset_select.get_item_count() - 1, preset_id)


func _make_volume_row(label_text: String, init_value: float, is_bgm: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = init_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(280, 32)
	row.add_child(slider)

	var value_lbl := Label.new()
	value_lbl.text = "%d%%" % int(round(init_value * 100))
	value_lbl.custom_minimum_size = Vector2(56, 0)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_lbl.add_theme_font_size_override("font_size", 18)
	value_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value_lbl)

	if is_bgm:
		_bgm_slider = slider
		_bgm_value_lbl = value_lbl
		slider.value_changed.connect(_on_bgm_changed)
	else:
		_voice_slider = slider
		_voice_value_lbl = value_lbl
		slider.value_changed.connect(_on_voice_changed)

	return row


func _on_bgm_changed(v: float) -> void:
	_bgm_value_lbl.text = "%d%%" % int(round(v * 100))
	if _settings and _settings.has_method("set_bgm_volume"):
		_settings.set_bgm_volume(v)


func _on_voice_changed(v: float) -> void:
	_voice_value_lbl.text = "%d%%" % int(round(v * 100))
	if _settings and _settings.has_method("set_voice_volume"):
		_settings.set_voice_volume(v)


func _on_close() -> void:
	close_requested.emit()


func _on_return_title() -> void:
	return_to_title_requested.emit()


func _selected_metadata(opt: OptionButton) -> String:
	if opt == null or opt.get_item_count() <= 0:
		return ""
	var idx := opt.selected
	if idx < 0:
		idx = 0
	var meta = opt.get_item_metadata(idx)
	return str(meta)


func _input_text_or_placeholder(input: LineEdit) -> String:
	if input == null:
		return ""
	var value := input.text.strip_edges()
	if value == "":
		value = input.placeholder_text.strip_edges()
	return value


func _split_target(text: String) -> PackedStringArray:
	var value := text.strip_edges()
	var dot := value.find(".")
	if dot <= 0 or dot >= value.length() - 1:
		return PackedStringArray()
	return PackedStringArray([value.substr(0, dot), value.substr(dot + 1)])


func _on_gm_apply_preset() -> void:
	_gm_call_main("gm_apply_preset", [_selected_metadata(_gm_preset_select)])


func _on_gm_preset_confront() -> void:
	_gm_call_main("gm_apply_preset_and_confront", [_selected_metadata(_gm_preset_select)])


func _on_gm_jump_dialogue() -> void:
	var parts := _split_target(_input_text_or_placeholder(_gm_dialogue_input))
	if parts.size() != 2:
		return
	_gm_call_main("gm_jump_to_dialogue", [parts[0], parts[1]])


func _on_gm_jump_narration() -> void:
	var parts := _split_target(_input_text_or_placeholder(_gm_narration_input))
	if parts.size() != 2:
		return
	_gm_call_main("gm_jump_to_narration", [parts[0], parts[1]])


func _on_gm_play_event() -> void:
	_gm_call_main("gm_play_event", [_input_text_or_placeholder(_gm_event_input)])


func _on_gm_start_confrontation() -> void:
	_gm_call_main("gm_start_confrontation", [_selected_metadata(_gm_confront_select)])


func _on_gm_fixed_epilogue() -> void:
	_gm_call_main("gm_play_fixed_epilogue")


func _gm_call_main(method_name: String, args: Array = []) -> void:
	var main = get_tree().current_scene
	if main == null or not main.has_method(method_name):
		return
	close_requested.emit()
	match args.size():
		0:
			main.call_deferred(method_name)
		1:
			main.call_deferred(method_name, args[0])
		2:
			main.call_deferred(method_name, args[0], args[1])
		3:
			main.call_deferred(method_name, args[0], args[1], args[2])
		_:
			push_warning("Too many GM call args: " + method_name)


func _unlock_all_evidence() -> void:
	for eid in GameManager.evidence_data.keys():
		if eid.begins_with("_"):
			continue
		var entry: Dictionary = GameManager.evidence_data[eid]
		var etype: String = entry.get("type", "")
		if etype == "evidence":
			GameManager.add_evidence(eid, false)
		elif etype == "clue":
			GameManager.add_clue(eid)
	if GameManager.current_state == GameManager.STATE_PROLOGUE:
		GameManager.set_state(GameManager.STATE_PLAYING)


func _on_gm_unlock_toggled(pressed: bool) -> void:
	if _settings and _settings.has_method("set_gm_unlock_all"):
		_settings.set_gm_unlock_all(pressed)


var _reset_confirm_step: int = 0

func _on_reset_game() -> void:
	if _reset_confirm_step == 0:
		_reset_confirm_step = 1
		if _reset_button:
			_reset_button.text = "确认重置？（再次点击执行）"
			_reset_button.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15))
		get_tree().create_timer(3.0).timeout.connect(_reset_confirm_timeout)
	elif _reset_confirm_step == 1:
		_reset_confirm_step = 0
		_do_reset()


func _reset_confirm_timeout() -> void:
	_reset_confirm_step = 0
	if _reset_button and _reset_button.text.begins_with("确认重置"):
		_reset_button.text = "重置游戏进度"
		_reset_button.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))


func _do_reset() -> void:
	var inv := get_node_or_null("/root/InvestigatorService")
	if inv and inv.has_method("reset_profile"):
		inv.reset_profile()
	var saves_dir := ProjectSettings.globalize_path("user://saves")
	if DirAccess.dir_exists_absolute(saves_dir):
		var da := DirAccess.open(saves_dir)
		if da:
			da.list_dir_begin()
			var fname := da.get_next()
			while fname != "":
				if fname.ends_with(".json"):
					da.remove(fname)
				fname = da.get_next()
	var cc_path := ProjectSettings.globalize_path("user://current_case.json")
	if FileAccess.file_exists("user://current_case.json"):
		DirAccess.remove_absolute(cc_path)
	game_reset_requested.emit()
