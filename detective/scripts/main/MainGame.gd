extends Control
## 主游戏 UI：左场景插图 + 右菜单 + 底部对话框 + 顶部时间条
## 协调所有面板的展开/收起 + 日期过场 + 日程事件提示

@onready var scene_bg: TextureRect = $Background
@onready var top_bar_label: Label = $TopBar/TimeLabel
@onready var location_label: Label = $TopBar/LocationLabel
@onready var menu_panel: Control = $RightMenu
@onready var subpanel_container: Control = $SubPanelContainer
@onready var dialogue_box: Control = $DialogueBox
@onready var notification_layer: Control = $NotificationLayer
@onready var ending_screen: Control = $EndingScreen
@onready var day_transition: Control = $DayTransition
@onready var event_hint_btn: Button = $EventHintBtn
@onready var bgm_a: AudioStreamPlayer = $BgmA
@onready var bgm_b: AudioStreamPlayer = $BgmB

const SubPanels = {
	"map": "res://scenes/ui/MapPanel.tscn",
	"talk": "res://scenes/ui/TalkPanel.tscn",
	"move": "res://scenes/ui/MovePanel.tscn",
	"search": "res://scenes/ui/SearchPanel.tscn",
	"notebook": "res://scenes/ui/NotebookPanel.tscn",
	"confrontation": "res://scenes/ui/ConfrontationPanel.tscn",
	"settings": "res://scenes/ui/SettingsPanel.tscn",
}

const SettingsSealIcon = preload("res://scripts/ui/SettingsSealIcon.gd")
const SETTINGS_BUTTON_ICON_PATH := "res://assets/cn/ui/icon_settings_seal.png"

var _active_subpanel: Control = null
var _pending_events: Array[String] = []
var _event_hint_auto_pending := false
var _pending_adhoc_lines: Array = []
var _pending_day_info: Dictionary = {}   # 延迟的日期过场 { "day": int, "sub": String }
var _last_location_period: int = -1      # 上次进入场景时的 period
var _last_location_day: int = -1         # 上次进入场景时的 day
var _time_card_playing: bool = false     # 时间过场是否正在播放
var _title_layer: Control = null
var _title_props_layer: Control = null
var _scene_fx: Node = null
var _playing_case_epilogue := false
var _bg_fade_rect: ColorRect = null
var _bg_transition_id: int = 0
var _current_bg_path: String = ""
var _npc_layer: Control = null
var _settings_btn: Button = null
var _settings_icon: Control = null
var _settings_btn_tween: Tween = null
var _settings_btn_hovered := false
var _settings_btn_pressed_visual := false


func _ready() -> void:
	GameManager.location_changed.connect(_on_location_changed)
	GameManager.time_advanced.connect(_on_time_advanced)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.evidence_added.connect(_on_evidence_added)
	GameManager.clue_added.connect(_on_clue_added)
	GameManager.day_event_available.connect(_on_day_event_available)
	GameManager.phase_unlocked.connect(_on_phase_unlocked)
	GameManager.progression_hint.connect(_on_progression_hint)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.confrontation_triggered.connect(_on_confrontation_from_dialogue)
	DialogueManager.narration_started.connect(_on_narration_started)
	DialogueManager.narration_ended.connect(_on_narration_ended)
	DialogueManager.narration_choices_ready.connect(_on_narration_choices_ready)
	DialogueManager.narration_time_card.connect(_on_narration_time_card)
	DialogueManager.lie_exposed.connect(_on_lie_exposed)
	
	menu_panel.menu_clicked.connect(_on_menu_clicked)
	event_hint_btn.pressed.connect(_on_event_hint_clicked)
	if ending_screen.has_signal("return_to_case_select_requested"):
		ending_screen.return_to_case_select_requested.connect(_on_return_to_case_select_after_ending)
	_style_event_hint_button()

	dialogue_box.visible = false
	subpanel_container.visible = false
	ending_screen.visible = false
	menu_panel.visible = false
	event_hint_btn.visible = false
	
	# 在背景图之上、UI 之下挂一层场景动态效果
	var FX = load("res://scripts/ui/SceneFXLayer.gd")
	if FX:
		_scene_fx = FX.new()
		_scene_fx.name = "SceneFXLayer"
		# 紧贴 Background 之上：把它插入到 Background 之后的位置
		add_child(_scene_fx)
		move_child(_scene_fx, scene_bg.get_index() + 1)

	_build_bg_fade_layer()

	# NPC 场景立绘层：在非对话状态时常驻显示 NPC（放在 BackgroundFade 之后）
	var NpcLayer = load("res://scripts/ui/NpcSceneLayer.gd")
	if NpcLayer:
		_npc_layer = NpcLayer.new()
		_npc_layer.name = "NpcSceneLayer"
		add_child(_npc_layer)
		if _bg_fade_rect:
			move_child(_npc_layer, _bg_fade_rect.get_index() + 1)
		elif _scene_fx:
			move_child(_npc_layer, _scene_fx.get_index() + 1)

	# 右上角设置按钮
	_build_settings_button()

	BgmPlayer.register_players(bgm_a, bgm_b)
	
	# 助手系统：被动旁白信号
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_signal("banter_ready"):
		cs.banter_ready.connect(_on_companion_banter)
	
	_show_title()


func _build_bg_fade_layer() -> void:
	_bg_fade_rect = ColorRect.new()
	_bg_fade_rect.name = "BackgroundFade"
	_bg_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_fade_rect.color = Color(0, 0, 0, 0)
	_bg_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_fade_rect)
	if _scene_fx:
		move_child(_bg_fade_rect, _scene_fx.get_index() + 1)
	else:
		move_child(_bg_fade_rect, scene_bg.get_index() + 1)


func _build_settings_button() -> void:
	_settings_btn = Button.new()
	_settings_btn.name = "SettingsBtn"
	_settings_btn.flat = true
	_settings_btn.custom_minimum_size = Vector2(58, 58)
	_settings_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_settings_btn.tooltip_text = "设置"
	_settings_btn.anchor_left = 1.0
	_settings_btn.anchor_right = 1.0
	_settings_btn.anchor_top = 0.0
	_settings_btn.anchor_bottom = 0.0
	_settings_btn.offset_left = -76.0
	_settings_btn.offset_top = 14.0
	_settings_btn.offset_right = -18.0
	_settings_btn.offset_bottom = 72.0
	_settings_btn.pivot_offset = _settings_btn.custom_minimum_size * 0.5
	_settings_btn.add_theme_stylebox_override("normal", _make_settings_button_style(
		Color(0.055, 0.037, 0.023, 0.94),
		Color(0.62, 0.44, 0.17, 0.95),
		Color(0, 0, 0, 0.34),
		16
	))
	_settings_btn.add_theme_stylebox_override("hover", _make_settings_button_style(
		Color(0.09, 0.055, 0.03, 0.97),
		Color(0.88, 0.67, 0.28, 1.0),
		Color(0.92, 0.66, 0.24, 0.22),
		22
	))
	_settings_btn.add_theme_stylebox_override("pressed", _make_settings_button_style(
		Color(0.045, 0.028, 0.016, 0.98),
		Color(0.97, 0.80, 0.38, 1.0),
		Color(0, 0, 0, 0.18),
		10
	))
	_settings_btn.add_theme_stylebox_override("focus", _make_settings_button_style(
		Color(0.075, 0.045, 0.028, 0.96),
		Color(0.92, 0.72, 0.3, 1.0),
		Color(0.85, 0.60, 0.2, 0.18),
		20
	))
	_settings_btn.add_theme_stylebox_override("disabled", _make_settings_button_style(
		Color(0.04, 0.03, 0.02, 0.55),
		Color(0.36, 0.28, 0.16, 0.45),
		Color(0, 0, 0, 0.12),
		8
	))

	var inner_plate := Panel.new()
	inner_plate.name = "InsetPlate"
	inner_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_plate.anchor_left = 0.0
	inner_plate.anchor_top = 0.0
	inner_plate.anchor_right = 1.0
	inner_plate.anchor_bottom = 1.0
	inner_plate.offset_left = 5.0
	inner_plate.offset_top = 5.0
	inner_plate.offset_right = -5.0
	inner_plate.offset_bottom = -5.0
	inner_plate.add_theme_stylebox_override("panel", _make_settings_inset_style())
	_settings_btn.add_child(inner_plate)

	_settings_icon = _create_settings_button_icon()
	_settings_icon.name = "SettingsSealIcon"
	_settings_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_icon.anchor_left = 0.5
	_settings_icon.anchor_top = 0.5
	_settings_icon.anchor_right = 0.5
	_settings_icon.anchor_bottom = 0.5
	_settings_icon.offset_left = -17.0
	_settings_icon.offset_top = -17.0
	_settings_icon.offset_right = 17.0
	_settings_icon.offset_bottom = 17.0
	_settings_btn.add_child(_settings_icon)

	_settings_btn.resized.connect(func():
		if _settings_btn and is_instance_valid(_settings_btn):
			_settings_btn.pivot_offset = _settings_btn.size * 0.5
	)
	_settings_btn.mouse_entered.connect(func():
		_settings_btn_hovered = true
		_sync_settings_button_visual_state()
	)
	_settings_btn.mouse_exited.connect(func():
		_settings_btn_hovered = false
		_settings_btn_pressed_visual = false
		_sync_settings_button_visual_state()
	)
	_settings_btn.button_down.connect(func():
		_settings_btn_pressed_visual = true
		_sync_settings_button_visual_state()
	)
	_settings_btn.button_up.connect(func():
		_settings_btn_pressed_visual = false
		_sync_settings_button_visual_state()
	)
	_settings_btn.pressed.connect(_on_settings_btn_pressed)
	_settings_btn.visible = false
	add_child(_settings_btn)
	_sync_settings_button_visual_state()
	# 设置按钮跟随菜单栏同步显隐
	menu_panel.visibility_changed.connect(func():
		if _settings_btn and is_instance_valid(_settings_btn):
			_settings_btn.visible = menu_panel.visible
			if not menu_panel.visible:
				_settings_btn.scale = Vector2.ONE
	)


func _on_settings_btn_pressed() -> void:
	_settings_btn_pressed_visual = false
	_sync_settings_button_visual_state()
	_open_subpanel("settings")


func _create_settings_button_icon() -> Control:
	if ResourceLoader.exists(SETTINGS_BUTTON_ICON_PATH):
		var icon := TextureRect.new()
		icon.texture = load(SETTINGS_BUTTON_ICON_PATH)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return icon
	return SettingsSealIcon.new()


func _make_settings_button_style(bg: Color, border: Color, shadow: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style


func _make_settings_inset_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.075, 0.04, 0.72)
	style.border_color = Color(0.42, 0.29, 0.13, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style


func _sync_settings_button_visual_state() -> void:
	if _settings_btn == null or not is_instance_valid(_settings_btn):
		return
	if _settings_icon and is_instance_valid(_settings_icon) and _settings_icon.has_method("set_visual_state"):
		_settings_icon.call("set_visual_state", _settings_btn_hovered, _settings_btn_pressed_visual)
	var target_scale := Vector2.ONE
	var duration := 0.18
	if _settings_btn_pressed_visual:
		target_scale = Vector2(0.96, 0.96)
		duration = 0.08
	elif _settings_btn_hovered:
		target_scale = Vector2(1.04, 1.04)
		duration = 0.14
	_animate_settings_button(target_scale, duration)


func _animate_settings_button(target_scale: Vector2, duration: float) -> void:
	if _settings_btn == null or not is_instance_valid(_settings_btn):
		return
	if _settings_btn_tween:
		_settings_btn_tween.kill()
	_settings_btn_tween = create_tween()
	_settings_btn_tween.set_trans(Tween.TRANS_SINE)
	_settings_btn_tween.set_ease(Tween.EASE_OUT)
	_settings_btn_tween.tween_property(_settings_btn, "scale", target_scale, duration)


func _set_background(path: String, use_fade := true) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	# 背景没有变化时不做 fade，避免同场景连续叙述闪黑。
	if path == _current_bg_path:
		return
	var tex := load(path)
	if tex == null:
		return
	if not use_fade or _bg_fade_rect == null or scene_bg.texture == null:
		scene_bg.texture = tex
		_current_bg_path = path
		return
	_bg_transition_id += 1
	var tid := _bg_transition_id
	var tw_out := create_tween()
	tw_out.tween_property(_bg_fade_rect, "color:a", 0.72, 0.16)
	await tw_out.finished
	if tid != _bg_transition_id:
		return
	scene_bg.texture = tex
	_current_bg_path = path
	var tw_in := create_tween()
	tw_in.tween_property(_bg_fade_rect, "color:a", 0.0, 0.22)


# ─── 标题界面 ───
func _show_title() -> void:
	menu_panel.visible = false
	top_bar_label.get_parent().visible = false
	dialogue_box.visible = false
	dialogue_box.visible = false
	subpanel_container.visible = false
	ending_screen.visible = false
	event_hint_btn.visible = false
	
	var bg := AssetResolver.get_scene_background_by_id("scene_title")
	if bg == "":
		bg = "res://assets/cn/scenes/title_screen.png"
	_set_background(bg, scene_bg.texture != null)
	BgmPlayer.play("main_theme")
	
	# 标题前景漂浮物件层
	_spawn_title_props()
	
	if _title_layer and is_instance_valid(_title_layer):
		_title_layer.queue_free()
	_title_layer = Control.new()
	_title_layer.name = "TitleLayer"
	_title_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_title_layer)
	
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.02, 0.03, 0.45)
	_title_layer.add_child(shade)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_layer.add_child(center)
	
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(420, 360)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)
	
	var title := Label.new()
	title.text = "推 理 者 计 划"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	vbox.add_child(title)
	
	var sub := Label.new()
	sub.text = "Detective Program"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62, 1))
	vbox.add_child(sub)

	# 调查员状态条
	var iv := get_node_or_null("/root/InvestigatorService")
	if iv:
		vbox.add_child(_make_investigator_strip(iv))

	vbox.add_child(_make_title_button("开 始 调 查", _on_start_investigation_pressed, false))
	# 只要当前案件存在存档，就必须保留继续入口；即使案件已通关，也可能是在重玩途中。
	if GameManager.has_save():
		vbox.add_child(_make_title_button("继 续 游 戏", _continue_game, false))
	vbox.add_child(_make_title_button("设 置", _on_title_settings_pressed, false))
	vbox.add_child(_make_title_button("退 出 游 戏", func(): get_tree().quit(), false))


func _is_active_case_cleared() -> bool:
	var iv := get_node_or_null("/root/InvestigatorService")
	return iv != null and iv.has_method("is_case_cleared") and iv.is_case_cleared(GameManager.ACTIVE_CASE)


func _make_title_button(text: String, cb: Callable, disabled := false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.flat = true
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.78, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.42, 0.36, 0.8))
	btn.pressed.connect(cb)
	return btn


func _hide_title() -> void:
	if _title_layer and is_instance_valid(_title_layer):
		_title_layer.queue_free()
	_title_layer = null
	if _title_props_layer and is_instance_valid(_title_props_layer):
		_title_props_layer.queue_free()
	_title_props_layer = null


func _spawn_title_props() -> void:
	if _title_props_layer and is_instance_valid(_title_props_layer):
		_title_props_layer.queue_free()

	_title_props_layer = Control.new()
	_title_props_layer.name = "TitlePropsLayer"
	_title_props_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_props_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_props_layer)
	# 放在背景与 UI 之间
	if scene_bg:
		move_child(_title_props_layer, scene_bg.get_index() + 1)

	var PropScript = load("res://scripts/ui/TitleFloatingProp.gd")
	if PropScript == null:
		return

	var vp := get_viewport_rect().size
	var cx := vp.x * 0.5
	var cy := vp.y * 0.5

	# 中央水晶球（脉动呼吸）
	_add_title_prop("res://assets/cn/title_props/orb.png",
		Vector2(cx - 150, cy - 150), Vector2(300, 300),
		{"breathe_scale": true, "breathe_speed": 1.0, "breathe_amount": 0.03, "float_speed": 0.0})

	# 左侧物件（扇形分布，避免重叠）
	_add_title_prop("res://assets/cn/title_props/magnifier.png",
		Vector2(cx - 400, cy - 100), Vector2(130, 130),
		{"float_speed": 1.0, "float_amplitude": 4.0, "rot_amplitude": 4.0, "phase_offset": 0.5})
	_add_title_prop("res://assets/cn/title_props/scroll.png",
		Vector2(cx - 460, cy + 40), Vector2(140, 140),
		{"float_speed": 0.8, "float_amplitude": 5.0, "rot_amplitude": 3.0, "phase_offset": 1.2})
	_add_title_prop("res://assets/cn/title_props/lantern.png",
		Vector2(cx - 280, cy + 180), Vector2(110, 110),
		{"float_speed": 1.3, "float_amplitude": 6.0, "rot_amplitude": 2.0, "phase_offset": 2.0})

	# 右侧物件（扇形分布，避免重叠）
	_add_title_prop("res://assets/cn/title_props/compass.png",
		Vector2(cx + 300, cy - 100), Vector2(120, 120),
		{"float_speed": 1.1, "float_amplitude": 5.0, "rot_amplitude": 3.0, "phase_offset": 3.5})
	_add_title_prop("res://assets/cn/title_props/ink_brush.png",
		Vector2(cx + 420, cy + 30), Vector2(120, 120),
		{"float_speed": 0.9, "float_amplitude": 4.0, "rot_amplitude": 4.0, "phase_offset": 4.0})
	_add_title_prop("res://assets/cn/title_props/pocket_watch.png",
		Vector2(cx + 240, cy + 200), Vector2(110, 110),
		{"float_speed": 1.2, "float_amplitude": 5.0, "rot_amplitude": 2.0, "phase_offset": 5.5})


func _add_title_prop(path: String, pos: Vector2, prop_size: Vector2, params: Dictionary) -> void:
	if not ResourceLoader.exists(path):
		return
	var prop := TextureRect.new()
	prop.set_script(load("res://scripts/ui/TitleFloatingProp.gd"))
	prop.texture = load(path)
	prop.position = pos
	prop.custom_minimum_size = prop_size
	for k in params.keys():
		prop.set(k, params[k])
	_title_props_layer.add_child(prop)


func _on_start_investigation_pressed() -> void:
	var case_count: int = GameManager.get_case_index_entries().size()
	if case_count <= 1:
		# 单案件：走原有逻辑
		if _is_active_case_cleared():
			_start_new_game()
			return
		if GameManager.has_save():
			_show_restart_confirm()
			return
		_start_new_game()
		return
	# 多案件：打开选案面板
	_open_case_select_panel(false)


func _on_title_settings_pressed() -> void:
	var scene_path: String = SubPanels.get("settings", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("Panel scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	var panel: Control = packed.instantiate()
	add_child(panel)
	move_child(panel, get_child_count() - 1)
	if panel.has_signal("close_requested"):
		panel.close_requested.connect(panel.queue_free)
	if panel.has_signal("return_to_title_requested"):
		panel.return_to_title_requested.connect(panel.queue_free)


func _show_restart_confirm() -> void:
	var overlay := ColorRect.new()
	overlay.name = "RestartConfirmOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.02, 0.03, 0.70)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.09, 0.07, 0.95)
	panel_style.border_color = Color(0.55, 0.42, 0.22, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "重新开始？"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	vbox.add_child(title)

	var body := Label.new()
	body.text = "当前已有存档。开始新游戏会覆盖现有进度，\n确定要重新开始吗？"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.82, 0.78, 0.70, 1))
	vbox.add_child(body)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 24)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	var cancel_btn := Button.new()
	cancel_btn.text = "取  消"
	cancel_btn.custom_minimum_size = Vector2(110, 42)
	cancel_btn.flat = true
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.add_theme_color_override("font_color", Color(0.65, 0.62, 0.55, 1))
	cancel_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.80, 0.72, 1))
	cancel_btn.add_theme_color_override("font_pressed_color", Color(0.55, 0.50, 0.42, 1))
	btn_hbox.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "重新开始"
	confirm_btn.custom_minimum_size = Vector2(130, 42)
	confirm_btn.flat = true
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1))
	confirm_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.78, 1))
	confirm_btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
	btn_hbox.add_child(confirm_btn)

	var close_dialog := func():
		overlay.queue_free()

	cancel_btn.pressed.connect(close_dialog)
	confirm_btn.pressed.connect(func():
		close_dialog.call()
		_start_new_game()
	)


func _start_new_game() -> void:
	_hide_title()
	#top_bar_label.get_parent().visible = true  # 时间显示暂时关闭
	_pending_events.clear()
	GameManager.reset_progress()
	GameManager.set_state(GameManager.STATE_PROLOGUE)
	BgmPlayer.play("prologue")
	DialogueManager.start_narration("res://data/cases/%s/prologue.json" % GameManager.ACTIVE_CASE)


func _continue_game() -> void:
	if not GameManager.load_game():
		return
	_hide_title()
	#top_bar_label.get_parent().visible = true  # 时间显示暂时关闭
	_sync_pending_events_from_save()
	if GameManager.current_state == GameManager.STATE_PROLOGUE:
		BgmPlayer.play("prologue")
		DialogueManager.start_narration("res://data/cases/%s/prologue.json" % GameManager.ACTIVE_CASE)
		return
	GameManager.set_state(GameManager.STATE_PLAYING)
	_on_location_changed(GameManager.current_location)
	_on_time_advanced(GameManager.current_day, GameManager.current_period)
	menu_panel.visible = true
	if menu_panel.has_method("refresh_visibility"):
		menu_panel.refresh_visibility()
	_refresh_event_hint()


func _sync_pending_events_from_save() -> void:
	_pending_events.clear()
	for evt_id in GameManager.pending_event_ids():
		_pending_events.append(evt_id)


# ─── 时间/地点/通知 ───
func _on_location_changed(loc_id: String) -> void:
	var data := GameManager.get_location_data(loc_id)
	location_label.text = data.get("name", loc_id)
	var bg_path: String = AssetResolver.get_scene_background(data)
	# 时间过场：仅在时间变化较大时显示（≥2个时段差异，避免单步移动触发）
	var cur_period := GameManager.current_period
	var cur_day := GameManager.current_day
	var period_diff: int = abs(cur_period - _last_location_period) if _last_location_period >= 0 else 0
	var day_diff: int = abs(cur_day - _last_location_day) if _last_location_day >= 0 else 0
	var significant_change: bool = day_diff > 0 or period_diff >= 2
	# 无论是否显示时间卡，都更新记录
	_last_location_period = cur_period
	_last_location_day = cur_day
	var should_show_time: bool = significant_change and GameManager.current_state == GameManager.STATE_PLAYING and not day_transition.visible and not _time_card_playing
	if should_show_time:
		_time_card_playing = true
		_set_background(bg_path, false)
		var period_name: String = GameManager.PERIOD_NAMES[cur_period] if cur_period < GameManager.PERIOD_NAMES.size() else ""
		var loc_name: String = data.get("name", "")
		if period_name != "":
			day_transition.show_period("%s · %s" % [period_name, loc_name])
			day_transition.finished.connect(func():
				_time_card_playing = false
				_try_companion_banter("arrive_location:" + loc_id)
			, CONNECT_ONE_SHOT)
	else:
		_set_background(bg_path, true)
	# 同步场景动态特效层
	if _scene_fx and _scene_fx.has_method("apply_for_scene_id"):
		_scene_fx.apply_for_scene_id(data.get("scene_type", ""))
	# 刷新 NPC 场景立绘层（始终显示，不隐藏）
	if _npc_layer and _npc_layer.has_method("refresh_npcs"):
		_npc_layer.refresh_npcs(loc_id)
	BgmPlayer.play(loc_id)
	if menu_panel.has_method("refresh_visibility"):
		menu_panel.refresh_visibility()
	_close_subpanel()
	if not should_show_time:
		_try_companion_banter("arrive_location:" + loc_id)


func _on_time_advanced(_day: int, _period: int) -> void:
	top_bar_label.text = "%s    距下一日 %d 时段    总剩余 %d 时段" % [GameManager.current_time_text(), GameManager.periods_until_next_day(), GameManager.remaining_periods()]
	if GameManager.is_time_up():
		_show_ending("timeout")
	elif GameManager.remaining_periods() <= 2:
		_try_companion_banter("period_late")


func _on_day_changed(new_day: int) -> void:
	_try_companion_banter("new_day")
	# 如果对话或叙述正在进行，延迟日期过场，等说话完毕再显示
	if dialogue_box.visible:
		var sub := "临川镇 · %s" % GameManager.PERIOD_NAMES[GameManager.current_period]
		_pending_day_info = { "day": new_day, "sub": sub }
		return
	_show_day_transition(new_day)


func _show_day_transition(day: int) -> void:
	var sub := "临川镇 · %s" % GameManager.PERIOD_NAMES[GameManager.current_period]
	day_transition.show_day(day, sub)


func _on_evidence_added(eid: String) -> void:
	var ev = GameManager.evidence_data.get(eid, {})
	_flash_notification("【获得证据】" + ev.get("name", eid))


func _on_clue_added(cid: String) -> void:
	var cl = GameManager.evidence_data.get(cid, {})
	_flash_notification("【获得线索】" + cl.get("name", cid))


func _on_phase_unlocked(phase_id: String) -> void:
	var phase: Dictionary = {}
	for p in GameManager.progression_data.get("phases", []):
		if p.get("id", "") == phase_id:
			phase = p
			break
	if phase.is_empty():
		return
	_flash_notification("【调查进展】" + phase.get("title", "新阶段解锁"))
	# 刷新菜单和地图
	if menu_panel.has_method("refresh_visibility"):
		menu_panel.refresh_visibility()
	_try_companion_banter("phase_unlocked:" + phase_id)


func _on_progression_hint(speaker: String, text: String) -> void:
	if text == "":
		return
	var lines: Array = [{ "speaker": speaker, "text": text }]
	_play_or_queue_adhoc(lines)


func _on_lie_exposed(npc_id: String, _lie_node: String) -> void:
	var npc = GameManager.get_npc_data(npc_id)
	_flash_notification("【揭穿谎言】发现 %s 在说谎" % npc.get("name", npc_id))


func _flash_notification(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = Vector2(40, 80 + notification_layer.get_child_count() * 36)
	notification_layer.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 2.5)
	tw.tween_callback(lbl.queue_free)


# ─── 日程事件 ───
func _on_day_event_available(evt_id: String) -> void:
	# auto_play 事件（如撞见凶手）直接播放，不进按钮队列
	var evt: Dictionary = GameManager.get_day_event(evt_id)
	if bool(evt.get("auto_play", false)):
		_play_event_now(evt_id)
		return
	if not _pending_events.has(evt_id):
		_pending_events.append(evt_id)
	_refresh_event_hint()


func _play_event_now(evt_id: String) -> void:
	var evt: Dictionary = GameManager.get_day_event(evt_id)
	GameManager.apply_event_effects(evt)
	var lines: Array = []
	var idx := 0
	for line in evt.get("narration", []):
		if line is Dictionary:
			lines.append(line)
		else:
			var voice_path: String = AssetResolver.resolve_event_voice_path(evt_id, idx)
			lines.append({ "speaker": "", "text": str(line), "voice_path": voice_path })
		idx += 1
	DialogueManager.play_adhoc_narration(lines, func():
		_refresh_event_hint()
		_try_companion_banter("after_event:" + evt_id)
	)


func _refresh_event_hint() -> void:
	if _pending_events.is_empty():
		event_hint_btn.visible = false
		return
	var evt_id = _pending_events[0]
	var evt = GameManager.get_day_event(evt_id)
	var title: String = evt.get("title", "新事件")
	event_hint_btn.text = "  ✦  关键发现 · %s  ✦" % title
	event_hint_btn.tooltip_text = evt.get("hint", "")
	event_hint_btn.visible = true
	_pulse_event_hint_button()
	_schedule_event_hint_autoplay()


func _schedule_event_hint_autoplay() -> void:
	if _event_hint_auto_pending:
		return
	_event_hint_auto_pending = true
	_auto_play_event_after_hint()


func _auto_play_event_after_hint() -> void:
	await get_tree().create_timer(1.05).timeout
	_event_hint_auto_pending = false
	if _pending_events.is_empty():
		event_hint_btn.visible = false
		return
	var evt_id: String = _pending_events.pop_front()
	# 先关闭关键发现弹窗，再进入助手/旁白对话，避免 UI 重叠。
	event_hint_btn.visible = false
	await get_tree().process_frame
	# 若触发点发生在普通对话/叙述中，等当前说话完全结束后再插入关键发现对话。
	while dialogue_box.visible or GameManager.current_state == GameManager.STATE_DIALOGUE:
		await get_tree().process_frame
	_play_event_now(evt_id)


func _style_event_hint_button() -> void:
	event_hint_btn.custom_minimum_size = Vector2(390, 48)
	event_hint_btn.add_theme_font_size_override("font_size", 20)
	event_hint_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.46, 1))
	event_hint_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.70, 1))
	event_hint_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.74, 0.28, 1))
	event_hint_btn.add_theme_constant_override("outline_size", 3)
	event_hint_btn.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 1))
	var normal := _make_event_hint_style(Color(0.12, 0.08, 0.04, 0.88), Color(0.86, 0.64, 0.25, 0.95), 14)
	var hover := _make_event_hint_style(Color(0.16, 0.10, 0.045, 0.94), Color(1.0, 0.78, 0.32, 1.0), 20)
	var pressed := _make_event_hint_style(Color(0.08, 0.055, 0.03, 0.96), Color(1.0, 0.88, 0.48, 1.0), 10)
	event_hint_btn.add_theme_stylebox_override("normal", normal)
	event_hint_btn.add_theme_stylebox_override("hover", hover)
	event_hint_btn.add_theme_stylebox_override("pressed", pressed)


func _make_event_hint_style(bg: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.95, 0.62, 0.18, 0.28)
	style.shadow_size = shadow_size
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _pulse_event_hint_button() -> void:
	event_hint_btn.scale = Vector2(1.0, 1.0)
	var tw := create_tween()
	tw.tween_property(event_hint_btn, "scale", Vector2(1.025, 1.025), 0.18)
	tw.tween_property(event_hint_btn, "scale", Vector2(1.0, 1.0), 0.22)


func _on_event_hint_clicked() -> void:
	# 保留手动入口兼容调试；正常流程已自动关闭提示并播放事件对话。
	if _pending_events.is_empty():
		return
	var evt_id: String = _pending_events.pop_front()
	event_hint_btn.visible = false
	_play_event_now(evt_id)


# ─── 菜单 ───
func _on_menu_clicked(menu_id: String) -> void:
	if menu_id == "talk":
		var npcs: Array = GameManager.get_active_npcs_at(GameManager.current_location)
		if npcs.is_empty():
			_flash_notification("此处无人。")
			return
		# 只有一人时跳过 TalkPanel 直接进入对话
		if npcs.size() == 1:
			DialogueManager.start_dialogue(npcs[0])
			return
	if menu_id == "discuss":
		DialogueManager.start_companion_discuss()
		return
	# 地图按钮打开地图面板
	if menu_id == "map":
		_open_subpanel("map")
		return
	_open_subpanel(menu_id)


func _open_subpanel(menu_id: String) -> void:
	_close_subpanel()
	if not SubPanels.has(menu_id):
		return
	# ── 探索面板：优先使用场景热点叠加模式 ──
	if menu_id == "search" and _has_hint_rects():
		_open_search_overlay()
		return
	var scene_path: String = SubPanels[menu_id]
	if not ResourceLoader.exists(scene_path):
		push_warning("Panel scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	var panel: Control = packed.instantiate()
	subpanel_container.add_child(panel)
	subpanel_container.visible = true
	_active_subpanel = panel
	if panel.has_signal("close_requested"):
		panel.close_requested.connect(_close_subpanel)
	if panel.has_signal("npc_selected"):
		panel.npc_selected.connect(_on_npc_selected)
	if panel.has_signal("location_selected"):
		panel.location_selected.connect(_on_location_selected)
	if panel.has_signal("confrontation_requested"):
		panel.confrontation_requested.connect(_on_confrontation_requested)
	if panel.has_signal("return_to_title_requested"):
		panel.return_to_title_requested.connect(_on_return_to_title)
	if panel.has_signal("game_reset_requested"):
		panel.game_reset_requested.connect(_on_game_reset)
	if panel.has_signal("search_result_acknowledged"):
		panel.search_result_acknowledged.connect(_on_search_result_acknowledged)


func _on_return_to_title() -> void:
	_close_subpanel()
	_show_title()


func _on_game_reset() -> void:
	_close_subpanel()
	# 不调用 GameManager.reset_progress()（它会 save_game 重新创建存档）
	# 只重置内存中的游戏状态，存档已在 SettingsPanel._do_reset 中删除
	GameManager.current_state = GameManager.STATE_PROLOGUE
	GameManager.current_day = 1
	GameManager.current_period = 0
	GameManager.collected_evidence.clear()
	GameManager.collected_clues.clear()
	GameManager.dialogue_flags.clear()
	GameManager.triggered_events.clear()
	GameManager.unlocked_phases = ["phase_1"]
	GameManager.ACTIVE_CASE = ""
	_show_title()


func _close_subpanel() -> void:
	var was_search_overlay := _active_subpanel != null and _active_subpanel.name == "SearchOverlay"
	var was_active = _active_subpanel
	if _active_subpanel and is_instance_valid(_active_subpanel):
		_active_subpanel.queue_free()
		_active_subpanel = null
	subpanel_container.visible = false
	if was_search_overlay:
		menu_panel.visible = true
		if _npc_layer and _npc_layer.has_method("show_npcs"):
			_npc_layer.show_npcs()


func _has_hint_rects() -> bool:
	var loc := GameManager.current_location_data()
	for sp in loc.get("search_points", []):
		if sp.get("hint_rect", null) != null:
			return true
	return false


func _open_search_overlay() -> void:
	var OverlayScript = load("res://scripts/ui/SearchOverlay.gd")
	if OverlayScript == null:
		push_warning("SearchOverlay.gd not found, falling back to SearchPanel")
		var scene_path: String = SubPanels["search"]
		if ResourceLoader.exists(scene_path):
			var packed: PackedScene = load(scene_path)
			var panel: Control = packed.instantiate()
			subpanel_container.add_child(panel)
			subpanel_container.visible = true
			_active_subpanel = panel
			if panel.has_signal("close_requested"):
				panel.close_requested.connect(_close_subpanel)
			if panel.has_signal("search_result_acknowledged"):
				panel.search_result_acknowledged.connect(_on_search_result_acknowledged)
		return
	var overlay := Control.new()
	overlay.set_script(OverlayScript)
	overlay.name = "SearchOverlay"
	overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.custom_minimum_size = subpanel_container.size
	subpanel_container.add_child(overlay)
	subpanel_container.visible = true
	_active_subpanel = overlay
	# 隐藏右侧菜单，让场景图完全可见
	menu_panel.visible = false
	if overlay.has_signal("close_requested"):
		overlay.close_requested.connect(_close_subpanel)
	if overlay.has_signal("search_result_acknowledged"):
		overlay.search_result_acknowledged.connect(_on_search_result_acknowledged)


func _on_npc_selected(npc_id: String) -> void:
	_close_subpanel()
	DialogueManager.start_dialogue(npc_id)


func _on_location_selected(loc_id: String) -> void:
	_close_subpanel()
	GameManager.change_location(loc_id, true)


func _on_confrontation_requested(_suspect: String) -> void:
	_close_subpanel()
	_open_confrontation_panel()


func _on_confrontation_from_dialogue() -> void:
	# 从对话触发对峙（新流程）
	_open_confrontation_panel()


func _open_confrontation_panel() -> void:
	_close_subpanel()
	BgmPlayer.play("accuse")
	menu_panel.visible = false
	var scene_path: String = SubPanels["confrontation"]
	if not ResourceLoader.exists(scene_path):
		push_warning("Panel scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	var panel: Control = packed.instantiate()
	subpanel_container.add_child(panel)
	subpanel_container.visible = true
	_active_subpanel = panel
	if panel.has_signal("confrontation_finished"):
		panel.confrontation_finished.connect(_on_confrontation_finished)


func _on_confrontation_finished(result: String, mistakes: int) -> void:
	_close_subpanel()
	# 对峙胜利后设置对应 flag
	if result == "victory":
		var confront_key: String = GameManager.active_confrontation_key
		var suspect: String = GameManager.case_data.get(confront_key, {}).get("suspect", "")
		if suspect == "agui":
			GameManager.set_flag("agui_confessed_mastermind")
	# 重置对峙路由键
	GameManager.active_confrontation_key = "confrontation"
	var ending_id := GameManager.judge_confrontation(result, mistakes)
	if ending_id == "bad" or ending_id == "partial":
		_try_companion_banter("accuse_fail")
	if _try_play_case_epilogue(ending_id):
		return
	_show_ending(ending_id)


func _try_play_case_epilogue(ending_id: String) -> bool:
	var path := "res://data/cases/%s/epilogue_meta.json" % GameManager.ACTIVE_CASE
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var root = JSON.parse_string(f.get_as_text())
	if typeof(root) != TYPE_DICTIONARY:
		return false
	var triggers: Array = root.get("trigger_endings", [])
	if not triggers.has(ending_id):
		return false
	var lines: Array = []
	for scene in root.get("scenes", []):
		if typeof(scene) != TYPE_DICTIONARY:
			continue
		var bg: String = scene.get("background", "")
		var bgm: String = scene.get("bgm", "")
		if bgm != "":
			BgmPlayer.play(bgm)
		for line in scene.get("lines", []):
			if typeof(line) != TYPE_DICTIONARY:
				continue
			var item: Dictionary = line.duplicate(true)
			if bg != "" and item.get("background", "") == "":
				item["background"] = bg
			lines.append(item)
	if lines.is_empty():
		return false
	_playing_case_epilogue = true
	DialogueManager.play_adhoc_narration(lines, func():
		_playing_case_epilogue = false
		_show_ending(ending_id)
	)
	return true


# ─── 对话 ───
func _on_dialogue_started(speaker: String, portrait: String, text: String, options: Array, pages: Array) -> void:
	dialogue_box.show_dialogue(speaker, portrait, text, options, pages)
	dialogue_box.visible = true
	menu_panel.visible = false
	if DialogueManager.is_discuss_mode():
		# 讨论模式：隐藏原 NPC 立绘（助手由 DialogueBox.portrait_rect 居中显示）
		if _npc_layer and _npc_layer.has_method("hide_npcs"):
			_npc_layer.hide_npcs()
	else:
		if _npc_layer and _npc_layer.has_method("hide_npcs"):
			_npc_layer.hide_npcs()


func _on_dialogue_ended() -> void:
	dialogue_box.visible = false
	menu_panel.visible = true
	_refresh_event_hint()
	_try_show_pending_day_transition()
	if _npc_layer and _npc_layer.has_method("show_npcs"):
		_npc_layer.show_npcs()


# ─── 序章 / 叙述 ───
func _on_narration_started(background: String, _speaker: String, text: String, has_next: bool, _centered: bool, portrait: String = "") -> void:
	if background != "":
		_set_background(background, true)
	# 进入游戏前的过场不叠加场景特效；无背景的助手短评不打断当前地点特效。
	if background != "" and _scene_fx:
		_scene_fx.clear_layers()
	dialogue_box.show_narration(_speaker, text, has_next, portrait)
	dialogue_box.visible = true
	menu_panel.visible = false
	if _npc_layer and _npc_layer.has_method("hide_npcs"):
		_npc_layer.hide_npcs()


func _on_narration_choices_ready(choices: Array) -> void:
	dialogue_box.show_narration_choices(choices)




func _on_narration_ended() -> void:
	dialogue_box.end_narration_mode()
	dialogue_box.visible = false
	if _playing_case_epilogue:
		menu_panel.visible = false
		return
	if GameManager.current_state == GameManager.STATE_PROLOGUE:
		GameManager.set_state(GameManager.STATE_PLAYING)
		GameManager.change_location(GameManager.case_main_scene, false)
		_on_time_advanced(GameManager.current_day, GameManager.current_period)
	menu_panel.visible = true
	_refresh_event_hint()
	_try_show_pending_day_transition()
	if _npc_layer and _npc_layer.has_method("show_npcs"):
		_npc_layer.show_npcs()


## 叙述中遇到 time_card 节点：显示时间过场，结束后自动推进叙述
func _on_narration_time_card(text: String, sub_text: String) -> void:
	# 先立即黑屏遮住一切（避免闪帧）
	day_transition.bg.modulate.a = 1.0
	day_transition.visible = true
	day_transition.label.visible_characters = 0

	# 然后再预加载下一个节点的背景（此时已被黑屏遮住）
	var next_node_id: String = DialogueManager._current_tree.get("nodes", {}).get(DialogueManager._narration_node, {}).get("next", "")
	var next_bg: String = ""
	if next_node_id != "":
		next_bg = DialogueManager._current_tree.get("nodes", {}).get(next_node_id, {}).get("background", "")
	if next_bg != "" and ResourceLoader.exists(next_bg):
		_set_background(next_bg, false)

	# 设置时间卡样式：较小字号 + 左对齐（打字机效果不跳动）
	var orig_font_size: int = day_transition.label.get_theme_font_size("font_size")
	var orig_sub_size: int = day_transition.sub_label.get_theme_font_size("font_size")
	day_transition.label.add_theme_font_size_override("font_size", 42)
	day_transition.sub_label.add_theme_font_size_override("font_size", 24)
	day_transition.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	day_transition.sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	day_transition.visible = true
	day_transition.label.text = text
	day_transition.sub_label.text = sub_text if sub_text != "" else ""
	day_transition.label.visible_characters = 0
	day_transition.label.modulate.a = 1.0
	day_transition.sub_label.visible_characters = 0
	day_transition.sub_label.modulate.a = 1.0 if sub_text != "" else 0.0
	# 保持黑幕完全遮住，避免预载下一张背景时漏出 1-2 帧画面。
	day_transition.bg.modulate.a = 1.0

	var total_main: int = text.length()
	var total_sub: int = sub_text.length() if sub_text != "" else 0
	GameManager.set_state(GameManager.STATE_TRANSITION)

	var tw := create_tween()
	# 黑屏淡入
	tw.tween_property(day_transition.bg, "modulate:a", 1.0, 0.3)
	# 主文本打字机（从左往右，每字~0.09秒）
	tw.tween_property(day_transition.label, "visible_characters", total_main, total_main * 0.09).set_delay(0.3)
	# 副文本打字机（主文本打完后开始）
	if total_sub > 0:
		tw.tween_interval(0.2)
		tw.tween_property(day_transition.sub_label, "visible_characters", total_sub, total_sub * 0.08)
	# 全部打完停留1.5秒
	tw.tween_interval(1.5)
	# 整体淡出
	tw.tween_property(day_transition.label, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(day_transition.sub_label, "modulate:a", 0.0, 0.4)
	tw.tween_property(day_transition.bg, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		day_transition.visible = false
		# 恢复原始样式
		day_transition.label.visible_characters = -1
		day_transition.sub_label.visible_characters = -1
		day_transition.label.add_theme_font_size_override("font_size", orig_font_size)
		day_transition.sub_label.add_theme_font_size_override("font_size", orig_sub_size)
		day_transition.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_transition.sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		GameManager.set_state(GameManager.STATE_PROLOGUE)
		DialogueManager.narration_next()
	)


## 检查是否有延迟的日期过场等待显示（对话/叙述结束后调用）
func _try_show_pending_day_transition() -> void:
	if _pending_day_info.is_empty():
		return
	var info := _pending_day_info
	_pending_day_info = {}
	_show_day_transition(info.get("day", 1))


# ─── 选择案件 ───
func _open_case_select_panel(return_to_title_on_cancel: bool) -> void:
	var packed: PackedScene = load("res://scenes/ui/CaseSelectPanel.tscn")
	if packed == null:
		push_error("CaseSelectPanel.tscn missing")
		return
	var panel: Control = packed.instantiate()
	add_child(panel)
	move_child(panel, get_child_count() - 1)
	panel.case_chosen_with_action.connect(_on_case_chosen_with_action)
	if return_to_title_on_cancel:
		panel.cancelled.connect(_show_title)


func _on_case_chosen_with_action(case_id: String, action: String) -> void:
	if case_id != GameManager.ACTIVE_CASE:
		GameManager.switch_case(case_id)
	match action:
		"continue":
			_continue_game()
		"new", _:
			_start_new_game()


func _on_return_to_case_select_after_ending() -> void:
	BgmPlayer.stop()
	ending_screen.visible = false
	menu_panel.visible = false
	dialogue_box.visible = false
	dialogue_box.visible = false
	subpanel_container.visible = false
	event_hint_btn.visible = false
	top_bar_label.get_parent().visible = false
	_hide_title()
	if _scene_fx and _scene_fx.has_method("clear_layers"):
		_scene_fx.clear_layers()
	_open_case_select_panel(true)


# ─── 结局 ───
func _show_ending(ending_id: String) -> void:
	GameManager.set_state(GameManager.STATE_ENDING)
	if ending_id == "perfect" or ending_id == "good":
		BgmPlayer.play("ending_perfect")
	else:
		BgmPlayer.play("ending_bad")
	# 通知调查员档案：结算 XP / 升级 / 解锁
	var summary: Dictionary = {}
	var iv := get_node_or_null("/root/InvestigatorService")
	if iv:
		summary = iv.record_case_cleared(GameManager.ACTIVE_CASE, ending_id)
	var data := GameManager.get_ending(ending_id)
	ending_screen.show_ending(data.get("title", ""), data.get("narration", ""))
	if ending_screen.has_method("show_progression_summary") and not summary.is_empty():
		ending_screen.show_progression_summary(summary, iv)
	ending_screen.visible = true
	menu_panel.visible = false
	dialogue_box.visible = false
	dialogue_box.visible = false
	subpanel_container.visible = false
	event_hint_btn.visible = false


# ─── 调查员状态条 / 代号设置 ──────────────────────────────────────────────

func _make_investigator_strip(iv: Node) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 70)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.07, 0.85)
	sb.border_color = Color(0.55, 0.42, 0.22, 0.85)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)

	var vbx := VBoxContainer.new()
	vbx.add_theme_constant_override("separation", 4)
	panel.add_child(vbx)

	# 行 1：代号 · Lv.x · 称号 · [改代号]
	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	vbx.add_child(top_hb)

	var codename_lbl := Label.new()
	codename_lbl.text = "代号：%s" % iv.get_codename()
	codename_lbl.add_theme_font_size_override("font_size", 16)
	codename_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	codename_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_child(codename_lbl)

	var rank_lbl := Label.new()
	rank_lbl.text = "Lv.%d  %s" % [iv.get_rank(), iv.get_rank_title()]
	rank_lbl.add_theme_font_size_override("font_size", 16)
	rank_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42, 1))
	top_hb.add_child(rank_lbl)

	var edit_btn := Button.new()
	edit_btn.text = "改代号"
	edit_btn.flat = true
	edit_btn.add_theme_font_size_override("font_size", 12)
	edit_btn.add_theme_color_override("font_color", Color(0.78, 0.70, 0.55, 1))
	edit_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.68, 1))
	edit_btn.pressed.connect(func(): _prompt_codename(iv, codename_lbl))
	top_hb.add_child(edit_btn)

	# 行 2：XP 进度条
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 100
	bar.value = iv.rank_progress() * 100.0
	bar.custom_minimum_size = Vector2(0, 14)
	vbx.add_child(bar)

	var xp_lbl := Label.new()
	xp_lbl.text = "经验：%d / %d" % [iv.get_xp(), iv.xp_for_next_rank()]
	xp_lbl.add_theme_font_size_override("font_size", 12)
	xp_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.55, 1))
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbx.add_child(xp_lbl)

	# 首次进入：未设代号 → 弹设置代号
	if not iv.has_codename():
		call_deferred("_prompt_codename", iv, codename_lbl)
	return panel


func _prompt_codename(iv: Node, codename_lbl: Label) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "设定调查员代号"
	dlg.dialog_text = "「推理者计划」需要一个代号。你将以此身份接受所有模拟卷宗。"
	dlg.ok_button_text = "确定"
	var input := LineEdit.new()
	input.placeholder_text = "输入代号（最多 16 字）"
	input.text = iv.get_codename("")
	input.max_length = 16
	input.custom_minimum_size = Vector2(320, 36)
	dlg.add_child(input)
	add_child(dlg)
	dlg.popup_centered(Vector2i(420, 220))
	dlg.confirmed.connect(func():
		var nm: String = input.text.strip_edges()
		if nm == "":
			nm = "无名调查员"
		iv.set_codename(nm)
		if is_instance_valid(codename_lbl):
			codename_lbl.text = "代号：%s" % iv.get_codename()
		dlg.queue_free()
	)


# ─── 助手系统集成 ─────────────────────────────────────────────────────────

func _try_companion_banter(trigger: String, npc_id: String = "", node_id: String = "") -> void:
	var cs = get_node_or_null("/root/CompanionService")
	if cs == null:
		return
	if not cs.has_method("try_emit_banter"):
		return
	cs.try_emit_banter({
		"trigger": trigger,
		"npc_id": npc_id,
		"node_id": node_id,
	})


func _open_discuss_panel() -> void:
	var DiscussPanelScript = load("res://scripts/ui/DiscussPanel.gd")
	if DiscussPanelScript == null:
		push_warning("DiscussPanel.gd not found")
		return
	var panel := PanelContainer.new()
	panel.set_script(DiscussPanelScript)
	panel.name = "DiscussPanel"
	# 居中弹出
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	move_child(panel, get_child_count() - 1)
	menu_panel.visible = false
	if panel.has_signal("discuss_closed"):
		panel.discuss_closed.connect(func():
			menu_panel.visible = true
		)
	if panel.has_signal("discuss_result"):
		panel.discuss_result.connect(_on_discuss_result)


func _on_discuss_result(lines: Array) -> void:
	# 用 adhoc narration 播放助手的讨论回答
	if lines.is_empty():
		menu_panel.visible = true
		return
	DialogueManager.play_adhoc_narration(lines, func(): menu_panel.visible = true)


func _on_companion_banter(lines: Array) -> void:
	# 播放助手被动旁白（adhoc narration 方式）
	if lines.is_empty():
		return
	_play_or_queue_adhoc(lines)


func _is_search_panel_busy() -> bool:
	if _active_subpanel == null or not is_instance_valid(_active_subpanel):
		return false
	if not _active_subpanel.has_method("is_searching"):
		return false
	return bool(_active_subpanel.call("is_searching"))


func _play_or_queue_adhoc(lines: Array) -> void:
	if lines.is_empty():
		return
	# 搜索流程中，必须先让玩家阅读“探索结果”并点“知道了”，再播放助手对话。
	if _is_search_panel_busy():
		_pending_adhoc_lines.append(lines)
		return
	DialogueManager.play_adhoc_narration(lines)


func _on_search_result_acknowledged() -> void:
	_flush_pending_adhoc_lines()


func _flush_pending_adhoc_lines() -> void:
	if _pending_adhoc_lines.is_empty():
		return
	if _is_search_panel_busy():
		return
	var lines: Array = _pending_adhoc_lines.pop_front()
	DialogueManager.play_adhoc_narration(lines, func(): _flush_pending_adhoc_lines())
