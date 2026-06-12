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

const GM_PRESET_ORDER := [
	"cabin_start",
	"wang_confront",
	"phase2_investigate",
	"main_confront_ready",
	"phase3_after_agui",
	"final_ready",
	"fixed_epilogue",
]

const GM_PRESETS := {
	"cabin_start": {
		"label": "船舱调查开始",
		"location": "cabin_lu_room",
	},
	"wang_confront": {
		"label": "王大爷自证对峙前",
		"location": "ferry_inn",
		"flags": ["cabin_review_done", "evt_cabin_sleep_done", "accused_of_murder", "cabin_phase_done"],
		"evidence": ["evidence_hull_hole", "evidence_lingyao_identity", "evidence_iron_crowbar_location", "evidence_seal_lost"],
		"clues": ["evidence_cabin_escape_time", "evidence_weather_fog", "evidence_storm_noise", "evidence_no_motive"],
		"confrontation": "confrontation_wang",
	},
	"phase2_investigate": {
		"label": "自证清白后调查",
		"location": "ferry_dock",
		"flags": ["cabin_phase_done", "cabin_review_done", "evt_cabin_sleep_done", "accused_of_murder", "confrontation_wang_completed", "self_cleared", "wang_testimony_debunked", "zhou_wife_bribe_exposed"],
		"evidence": ["evidence_hull_hole", "evidence_lingyao_identity", "evidence_iron_crowbar_location", "evidence_seal_lost"],
		"clues": ["evidence_cabin_escape_time", "evidence_weather_fog", "evidence_storm_noise", "evidence_no_motive"],
	},
	"main_confront_ready": {
		"label": "老范/阿贵对峙前",
		"location": "ferry_inn",
		"flags": ["cabin_phase_done", "cabin_review_done", "evt_cabin_sleep_done", "accused_of_murder", "confrontation_wang_completed", "self_cleared", "wang_testimony_debunked", "zhou_wife_bribe_exposed", "evt_hull_discovered_done", "hull_sabotage_known", "evt_bladder_found_done", "agui_premeditation_known", "evt_dismissal_revealed_done", "agui_motive_known"],
		"evidence": ["evidence_hull_hole", "evidence_nail_marks", "evidence_float_bladder", "evidence_no_blunt_trauma", "evidence_dismissal_note", "evidence_lingyao_identity", "evidence_iron_crowbar_location", "evidence_seal_lost"],
		"clues": ["evidence_cabin_escape_time", "evidence_weather_fog", "evidence_storm_noise", "evidence_no_motive", "evidence_wrong_channel", "clue_fan_alibi_hole"],
		"confrontation": "confrontation",
	},
	"phase3_after_agui": {
		"label": "阿贵招供后",
		"location": "ferry_inn",
		"flags": ["cabin_phase_done", "cabin_review_done", "evt_cabin_sleep_done", "accused_of_murder", "confrontation_wang_completed", "self_cleared", "wang_testimony_debunked", "zhou_wife_bribe_exposed", "evt_hull_discovered_done", "hull_sabotage_known", "evt_bladder_found_done", "agui_premeditation_known", "evt_dismissal_revealed_done", "agui_motive_known", "confrontation_completed", "agui_confessed_mastermind", "evt_phase3_transition_done", "phase3_scene_rearranged"],
		"evidence": ["evidence_hull_hole", "evidence_nail_marks", "evidence_float_bladder", "evidence_no_blunt_trauma", "evidence_dismissal_note", "evidence_lingyao_identity", "evidence_iron_crowbar_location", "evidence_seal_lost"],
		"clues": ["evidence_cabin_escape_time", "evidence_weather_fog", "evidence_storm_noise", "evidence_no_motive", "evidence_wrong_channel", "clue_fan_alibi_hole", "clue_agui_confession", "evidence_dock_timing"],
	},
	"final_ready": {
		"label": "沈清月终局前",
		"location": "shen_room",
		"flags": ["cabin_phase_done", "cabin_review_done", "evt_cabin_sleep_done", "accused_of_murder", "confrontation_wang_completed", "self_cleared", "wang_testimony_debunked", "zhou_wife_bribe_exposed", "evt_hull_discovered_done", "hull_sabotage_known", "evt_bladder_found_done", "agui_premeditation_known", "evt_dismissal_revealed_done", "agui_motive_known", "confrontation_completed", "agui_confessed_mastermind", "evt_phase3_transition_done", "phase3_scene_rearranged", "bladder_meaning_revised", "evt_shen_evidence_ready_done"],
		"evidence": ["evidence_hull_hole", "evidence_nail_marks", "evidence_float_bladder", "evidence_no_blunt_trauma", "evidence_dismissal_note", "evidence_lingyao_identity", "evidence_iron_crowbar_location", "evidence_seal_lost", "evidence_cargo_silver", "evidence_drug_capsule_shell", "evidence_tongue_herb_residue", "evidence_oil_lock_residue", "evidence_father_ledger"],
		"clues": ["evidence_cabin_escape_time", "evidence_weather_fog", "evidence_storm_noise", "evidence_no_motive", "evidence_wrong_channel", "clue_fan_alibi_hole", "clue_agui_confession", "evidence_dock_timing", "evidence_salvage_mark", "evidence_shen_connection"],
		"confrontation": "confrontation_final",
	},
	"fixed_epilogue": {
		"label": "固定结尾过渡",
		"location": "ferry_inn",
		"flags": ["cabin_phase_done", "prologue_truth_reached", "prologue_defeated", "case_partially_resolved"],
	},
}

const GM_CONFRONTATION_PRESET_MAP := {
	"confrontation_wang": "wang_confront",
	"confrontation": "main_confront_ready",
	"confrontation_final": "final_ready",
}

const SettingsSealIcon = preload("res://scripts/ui/SettingsSealIcon.gd")
const SETTINGS_BUTTON_ICON_PATH := "res://assets/cn/ui/icon_settings_seal.png"
const GM_TEST_PANEL_SCENE_PATH := "res://scenes/ui/GmTestPanel.tscn"
const EVIDENCE_OBTAIN_HOLD_SECONDS := 2.0
const EVIDENCE_POPUP_VISIBLE_SECONDS := 2.0
const EVIDENCE_POPUP_WIDTH := 660.0
const EVIDENCE_CLICK_BLOCKER_Z_INDEX := 2048
const EVIDENCE_POPUP_STACK_Z_INDEX := 2047

var _active_subpanel: Control = null
var _pending_events: Array[String] = []
var _event_hint_auto_pending := false
var _silent_auto_event_pending := false
var _silent_auto_event_suppress_evidence_hold := false
var _pending_adhoc_lines: Array = []
var _defer_adhoc_until_confrontation_result_done := false
var _last_location_day: int = -1         # 上次进入场景时的 day
var _time_card_playing: bool = false     # 场景过场是否正在播放
var _visited_locations: Dictionary = {}  # 已访问过的场景 ID → true（首次访问时显示地名卡）
var _suppress_next_arrival_banter := false
var _suppress_next_location_intro := false
var _title_layer: Control = null
var _title_props_layer: Control = null
var _scene_fx: Node = null
var _playing_case_epilogue := false
var _next_narration_typewriter_skip_disabled := false
var _next_narration_typewriter_char_delay := -1.0
var _bg_fade_rect: ColorRect = null
var _bg_transition_id: int = 0
var _current_bg_path: String = ""
var _npc_layer: Control = null
var _settings_btn: Button = null
var _settings_icon: Control = null
var _settings_btn_tween: Tween = null
var _settings_btn_hovered := false
var _settings_btn_pressed_visual := false
var _evidence_click_blocker: Control = null
var _evidence_click_lock_until_msec := 0
var _evidence_popup_stack: VBoxContainer = null
var _screen_shake_tween_ref: Tween = null
var _screen_shake_base_positions: Dictionary = {}


func _ready() -> void:
	set_process(false)
	CaseTableLoader.clear_cache()
	GameManager.location_changed.connect(_on_location_changed)
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
	DialogueManager.narration_video.connect(_on_narration_video)
	DialogueManager.narration_time_card.connect(_on_narration_time_card)
	DialogueManager.narration_effects.connect(_on_narration_effects)
	DialogueManager.lie_exposed.connect(_on_lie_exposed)
	
	menu_panel.menu_clicked.connect(_on_menu_clicked)
	if menu_panel.has_signal("locked_hint_requested"):
		menu_panel.locked_hint_requested.connect(_on_menu_locked_hint_requested)
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


func _process(_delta: float) -> void:
	if _evidence_click_blocker == null or not _evidence_click_blocker.visible:
		set_process(false)
		return
	if _is_evidence_click_locked():
		return
	_evidence_click_blocker.visible = false
	_evidence_click_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _input(event: InputEvent) -> void:
	if not _is_evidence_click_locked():
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()


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
	# 切换背景时重置位置偏移（CG 场景可能偏移过）
	scene_bg.position = Vector2.ZERO
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
	# 返回主界面时隐藏 NPC 立绘
	if _npc_layer and _npc_layer.has_method("hide_npcs"):
		_npc_layer.hide_npcs()
	
	var bg := AssetResolver.get_scene_background_by_id("scene_title")
	if bg == "":
		bg = "res://assets/cn/scenes/title_screen.png"
	_set_background(bg, scene_bg.texture != null)
	BgmPlayer.play("ferry_prologue_shore")
	
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
	shade.color = Color(0.02, 0.02, 0.03, 0.38)
	_title_layer.add_child(shade)
	
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 92)
	margin.add_theme_constant_override("margin_top", 86)
	margin.add_theme_constant_override("margin_right", 92)
	margin.add_theme_constant_override("margin_bottom", 78)
	_title_layer.add_child(margin)

	var layout := HBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 54)
	margin.add_child(layout)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 14)
	layout.add_child(title_box)
	
	var title := Label.new()
	title.text = "推 理 者 计 划"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	title_box.add_child(title)
	
	var title_rule := ColorRect.new()
	title_rule.custom_minimum_size = Vector2(380, 2)
	title_rule.color = Color(0.85, 0.66, 0.32, 0.82)
	title_box.add_child(title_rule)

	var sub := Label.new()
	sub.text = "Detective Program"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62, 1))
	title_box.add_child(sub)

	var menu_center := CenterContainer.new()
	menu_center.custom_minimum_size = Vector2(340, 0)
	menu_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(menu_center)

	var menu_box := VBoxContainer.new()
	menu_box.custom_minimum_size = Vector2(320, 0)
	menu_box.add_theme_constant_override("separation", 14)
	menu_center.add_child(menu_box)

	menu_box.add_child(_make_title_button("开 始 调 查", _on_start_investigation_pressed, false))
	# 只要当前案件存在存档，就必须保留继续入口；即使案件已通关，也可能是在重玩途中。
	if GameManager.has_resume_save():
		menu_box.add_child(_make_title_button("读 取 存 档", _on_title_load_save_pressed, false))
	menu_box.add_child(_make_title_button("GM 测 试", _on_title_gm_test_pressed, false))
	menu_box.add_child(_make_title_button("设 置", _on_title_settings_pressed, false))
	menu_box.add_child(_make_title_button("退 出 游 戏", func(): get_tree().quit(), false))


func _is_active_case_cleared() -> bool:
	var iv := get_node_or_null("/root/InvestigatorService")
	return iv != null and iv.has_method("is_case_cleared") and iv.is_case_cleared(GameManager.ACTIVE_CASE)


func _make_title_button(text: String, cb: Callable, disabled := false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.flat = true
	btn.custom_minimum_size = Vector2(300, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	_open_title_settings_panel(0)


func _on_title_load_save_pressed() -> void:
	_open_title_settings_panel(1, true)


func _open_title_settings_panel(initial_tab: int, title_load_only := false) -> void:
	var scene_path: String = SubPanels.get("settings", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("Panel scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	var panel: Control = packed.instantiate()
	if panel != null:
		panel.set("initial_tab", initial_tab)
		panel.set("title_load_only", title_load_only)
	add_child(panel)
	move_child(panel, get_child_count() - 1)
	if panel.has_signal("close_requested"):
		panel.close_requested.connect(panel.queue_free)
	if panel.has_signal("return_to_title_requested"):
		panel.return_to_title_requested.connect(panel.queue_free)


func _on_title_gm_test_pressed() -> void:
	if GM_TEST_PANEL_SCENE_PATH == "" or not ResourceLoader.exists(GM_TEST_PANEL_SCENE_PATH):
		push_warning("GM test panel missing: " + GM_TEST_PANEL_SCENE_PATH)
		return
	var packed: PackedScene = load(GM_TEST_PANEL_SCENE_PATH)
	var panel: Control = packed.instantiate()
	add_child(panel)
	move_child(panel, get_child_count() - 1)


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
	# 立即切黑，避免第一帧露出标题背景
	_set_background("res://assets/cn/scenes/pure_black.png", false)
	top_bar_label.get_parent().visible = false
	_visited_locations.clear()
	_pending_events.clear()
	GameManager.reset_progress()
	GameManager.set_state(GameManager.STATE_PROLOGUE)
	BgmPlayer.play("ferry_cabin_night")
	DialogueManager.start_narration("prologue")


func _continue_game() -> void:
	if not GameManager.load_resume_save():
		return
	resume_loaded_game()


func resume_loaded_game() -> void:
	_hide_title()
	top_bar_label.get_parent().visible = true
	_restore_session_visited_locations_from_save()
	_sync_pending_events_from_save()
	if GameManager.current_state == GameManager.STATE_PROLOGUE:
		if not _should_resume_cabin_from_prologue_save():
			_set_background("res://assets/cn/scenes/pure_black.png", false)
			BgmPlayer.play("ferry_cabin_night")
			DialogueManager.start_narration("prologue", true)
			return
		GameManager.set_state(GameManager.STATE_PLAYING)
	elif GameManager.current_state == GameManager.STATE_TRANSITION and GameManager.ACTIVE_CASE == "prologue_ferry" and not _should_resume_cabin_from_prologue_save():
		_set_background("res://assets/cn/scenes/pure_black.png", false)
		BgmPlayer.play("ferry_cabin_night")
		DialogueManager.start_narration("prologue", true)
		return
	GameManager.set_state(GameManager.STATE_PLAYING)
	_on_location_changed(GameManager.current_location, true)
	_update_top_bar()
	menu_panel.visible = true
	if menu_panel.has_method("refresh_visibility"):
		menu_panel.refresh_visibility()
	if _has_pending_auto_event():
		_schedule_silent_auto_event(true)
	else:
		_refresh_event_hint()
	if _should_resume_wang_confrontation_after_continue():
		_deferred_start_confrontation.call_deferred("confrontation_wang")


func _should_resume_cabin_from_prologue_save() -> bool:
	if GameManager.ACTIVE_CASE != "prologue_ferry":
		return false
	return (
		GameManager.has_clue("clue_travel_notes")
		or GameManager.has_flag("cabin_seal_box_checked")
		or GameManager.has_flag("cabin_route_note_checked")
		or GameManager.has_flag("cabin_storm_window_checked")
		or GameManager.has_flag("cabin_wet_cloak_checked")
		or GameManager.has_flag("cabin_agui_talked")
		or GameManager.has_flag("cabin_lao_fan_talked")
		or GameManager.has_flag("cabin_zhou_talked")
		or GameManager.has_flag("cabin_explore_done")
		or GameManager.has_flag("cabin_phase_done")
	)


func _restore_session_visited_locations_from_save() -> void:
	_visited_locations.clear()
	for loc_id in GameManager.visited_locations:
		_visited_locations[str(loc_id)] = true
	if GameManager.current_location != "":
		_visited_locations[GameManager.current_location] = true


func _sync_pending_events_from_save() -> void:
	_pending_events.clear()
	for evt_id in GameManager.pending_event_ids():
		_pending_events.append(evt_id)


func _has_pending_auto_event() -> bool:
	for evt_id in _pending_events:
		var evt: Dictionary = GameManager.get_day_event(str(evt_id))
		if bool(evt.get("auto_play", false)):
			return true
	return false


func _should_resume_wang_confrontation_after_continue() -> bool:
	return (
		GameManager.ACTIVE_CASE == "prologue_ferry"
		and GameManager.current_location == "ferry_inn"
		and GameManager.has_flag("accused_of_murder")
		and not GameManager.has_flag("confrontation_wang_completed")
	)


# ─── 时间/地点/通知 ───
func _on_location_changed(loc_id: String, suppress_arrival_banter := false) -> void:
	var block_arrival_banter := suppress_arrival_banter or _suppress_next_arrival_banter
	var skip_location_intro := _suppress_next_location_intro
	_suppress_next_arrival_banter = false
	_suppress_next_location_intro = false
	var data := GameManager.get_location_data(loc_id)
	_update_top_bar()
	var bg_path: String = AssetResolver.get_scene_background(data)
	# 场景过场：首次访问该场景时显示地名过场
	var cur_day := GameManager.current_day
	var time_card_key := "D%d_%s" % [cur_day, loc_id]
	var already_shown: bool = GameManager.shown_time_cards.has(time_card_key)
	var is_first_visit: bool = not skip_location_intro and not _visited_locations.has(loc_id)
	var significant_change: bool = not already_shown and is_first_visit
	# 无论是否显示时间卡，都更新记录
	_visited_locations[loc_id] = true
	_last_location_day = cur_day
	var should_show_time: bool = significant_change and GameManager.current_state == GameManager.STATE_PLAYING and not day_transition.visible and not _time_card_playing
	if should_show_time:
		GameManager.shown_time_cards[time_card_key] = true
		GameManager.save_game()
		_time_card_playing = true
		_set_background(bg_path, false)
		var loc_name: String = data.get("name", "")
		if loc_name != "":
			var card_text := "%s · %s" % [GameManager.get_current_time_label(), loc_name]
			day_transition.show_period(card_text)
			day_transition.finished.connect(func():
				_time_card_playing = false
				if _npc_layer and _npc_layer.has_method("refresh_npcs"):
					_npc_layer.refresh_npcs(loc_id)
				if not block_arrival_banter:
					_try_companion_banter("arrive_location:" + loc_id)
			, CONNECT_ONE_SHOT)
	else:
		_set_background(bg_path, true)
	# 同步场景动态特效层
	if _scene_fx and _scene_fx.has_method("apply_for_scene_id"):
		_scene_fx.apply_for_scene_id(data.get("scene_type", ""))
	# 刷新 NPC 场景立绘层（时间过场期间先不显示，过场结束后再刷新）
	if should_show_time:
		if _npc_layer and _npc_layer.has_method("hide_npcs"):
			_npc_layer.hide_npcs()
	else:
		if _npc_layer and _npc_layer.has_method("refresh_npcs"):
			_npc_layer.refresh_npcs(loc_id)
	BgmPlayer.play(loc_id)
	if menu_panel.has_method("refresh_visibility"):
		menu_panel.refresh_visibility()
	_close_subpanel()
	if not should_show_time and not block_arrival_banter:
		_try_companion_banter("arrive_location:" + loc_id)


func _update_top_bar() -> void:
	var loc_data := GameManager.current_location_data()
	var loc_name: String = loc_data.get("name", GameManager.current_location)
	
	# 获取父地点名称（主要场景）
	var parent_id: String = loc_data.get("parent", "")
	var parent_name: String = ""
	if parent_id != "":
		var parent_data: Dictionary = GameManager.get_location_data(parent_id)
		parent_name = parent_data.get("name", parent_id)
	
	# 如果没有父地点，左上角显示时间+当前地点
	# 如果有父地点，左上角显示时间+主要场景（父地点）
	var time_str: String = GameManager.get_current_time_label()
	if parent_name == "":
		top_bar_label.text = "    %s · %s" % [time_str, loc_name]
		location_label.text = "    "
	else:
		top_bar_label.text = "    %s · %s" % [time_str, parent_name]
		location_label.text = loc_name + "    "


func _on_evidence_added(eid: String) -> void:
	var ev = GameManager.evidence_data.get(eid, {})
	var should_hold := GameManager.should_hold_last_evidence_obtain_display()
	_flash_notification("【获得证物】" + ev.get("name", eid))
	_show_evidence_popup(eid, ev, should_hold)


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


func _show_evidence_popup(eid: String, ev: Dictionary, hold_advance := true) -> void:
	var tex: Texture2D = _load_evidence_popup_texture(eid, ev)
	if hold_advance:
		_lock_evidence_clicks_for(EVIDENCE_OBTAIN_HOLD_SECONDS)
		if dialogue_box and dialogue_box.has_method("lock_advance_for"):
			dialogue_box.lock_advance_for(EVIDENCE_OBTAIN_HOLD_SECONDS)
	if tex == null:
		return

	var toast := PanelContainer.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.custom_minimum_size = Vector2(EVIDENCE_POPUP_WIDTH, 138)
	toast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast.modulate.a = 0.0
	toast.scale = Vector2(0.97, 0.97)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.035, 0.02, 0.96)
	style.border_color = Color(0.92, 0.70, 0.28, 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 18
	style.content_margin_left = 16
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	toast.add_theme_stylebox_override("panel", style)
	_ensure_evidence_popup_stack().add_child(toast)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	toast.add_child(row)

	var img := TextureRect.new()
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(112, 112)
	img.size = Vector2(112, 112)
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(img)

	var label_box := VBoxContainer.new()
	label_box.custom_minimum_size = Vector2(480, 112)
	label_box.alignment = BoxContainer.ALIGNMENT_CENTER
	label_box.add_theme_constant_override("separation", 4)
	label_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label_box)

	var title_lbl := Label.new()
	title_lbl.text = "获得证物"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.78, 0.34, 1))
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_box.add_child(title_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(ev.get("name", eid))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_box.add_child(name_lbl)

	var desc := str(ev.get("short_description", ev.get("description", ""))).strip_edges()
	if desc != "":
		var desc_lbl := Label.new()
		desc_lbl.text = desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.clip_text = true
		desc_lbl.max_lines_visible = 2
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		desc_lbl.add_theme_font_size_override("font_size", 17)
		desc_lbl.add_theme_color_override("font_color", Color(0.86, 0.80, 0.66, 1))
		desc_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		desc_lbl.add_theme_constant_override("outline_size", 1)
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label_box.add_child(desc_lbl)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(toast, "modulate:a", 1.0, 0.18)
	tw.tween_property(toast, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(EVIDENCE_POPUP_VISIBLE_SECONDS)
	tw.set_parallel(true)
	tw.tween_property(toast, "modulate:a", 0.0, 0.45)
	tw.tween_property(toast, "scale", Vector2(0.98, 0.98), 0.45)
	tw.chain().tween_callback(toast.queue_free)


func _ensure_evidence_popup_stack() -> VBoxContainer:
	if _evidence_popup_stack != null and is_instance_valid(_evidence_popup_stack):
		return _evidence_popup_stack
	_evidence_popup_stack = VBoxContainer.new()
	_evidence_popup_stack.name = "EvidencePopupStack"
	_evidence_popup_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_evidence_popup_stack.z_index = EVIDENCE_POPUP_STACK_Z_INDEX
	_evidence_popup_stack.anchor_left = 0.5
	_evidence_popup_stack.anchor_top = 0.0
	_evidence_popup_stack.anchor_right = 0.5
	_evidence_popup_stack.anchor_bottom = 0.0
	_evidence_popup_stack.offset_left = -EVIDENCE_POPUP_WIDTH * 0.5
	_evidence_popup_stack.offset_top = 70.0
	_evidence_popup_stack.offset_right = EVIDENCE_POPUP_WIDTH * 0.5
	_evidence_popup_stack.offset_bottom = 420.0
	_evidence_popup_stack.add_theme_constant_override("separation", 10)
	notification_layer.add_child(_evidence_popup_stack)
	return _evidence_popup_stack


func _lock_evidence_clicks_for(seconds: float) -> void:
	var duration_msec := int(maxf(seconds, 0.0) * 1000.0)
	if duration_msec <= 0:
		return
	_evidence_click_lock_until_msec = maxi(
		_evidence_click_lock_until_msec,
		Time.get_ticks_msec() + duration_msec
	)
	_ensure_evidence_click_blocker()
	_evidence_click_blocker.visible = true
	_evidence_click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func _ensure_evidence_click_blocker() -> void:
	if _evidence_click_blocker != null and is_instance_valid(_evidence_click_blocker):
		return
	_evidence_click_blocker = Control.new()
	_evidence_click_blocker.name = "EvidenceClickBlocker"
	_evidence_click_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_evidence_click_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_evidence_click_blocker.visible = false
	_evidence_click_blocker.z_index = EVIDENCE_CLICK_BLOCKER_Z_INDEX
	_evidence_click_blocker.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			get_viewport().set_input_as_handled()
	)
	add_child(_evidence_click_blocker)


func _is_evidence_click_locked() -> bool:
	return Time.get_ticks_msec() < _evidence_click_lock_until_msec


func _load_evidence_popup_texture(eid: String, ev: Dictionary) -> Texture2D:
	var candidates := [
		"res://assets/ai_processed/objects/evidence_icons/%s.png" % eid,
		str(ev.get("icon", "")),
		"res://assets/cn/title_props/scroll.png",
	]
	for path in candidates:
		if path == "" or not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	return null


# ─── 日程事件 ───
func _on_day_event_available(evt_id: String) -> void:
	var evt: Dictionary = GameManager.get_day_event(evt_id)
	if bool(evt.get("auto_play", false)):
		if not _pending_events.has(evt_id):
			_pending_events.append(evt_id)
		_schedule_silent_auto_event()
		return
	if not _pending_events.has(evt_id):
		_pending_events.append(evt_id)
	_refresh_event_hint()


func _schedule_silent_auto_event(suppress_evidence_hold := false) -> void:
	_silent_auto_event_suppress_evidence_hold = _silent_auto_event_suppress_evidence_hold or suppress_evidence_hold
	if _silent_auto_event_pending:
		return
	_silent_auto_event_pending = true
	_play_silent_auto_event_when_idle()


func _play_silent_auto_event_when_idle() -> void:
	await get_tree().process_frame
	while true:
		var auto_idx := -1
		for i in range(_pending_events.size()):
			var evt_id := _pending_events[i]
			var evt: Dictionary = GameManager.get_day_event(evt_id)
			if bool(evt.get("auto_play", false)):
				auto_idx = i
				break
		if auto_idx < 0:
			break
		while dialogue_box.visible or GameManager.current_state == GameManager.STATE_DIALOGUE or subpanel_container.visible:
			await get_tree().process_frame
		if auto_idx < 0 or auto_idx >= _pending_events.size():
			continue
		var popped_evt = _pending_events.pop_at(auto_idx)
		if popped_evt == null:
			continue
		var next_evt_id := str(popped_evt)
		_play_event_now(next_evt_id, _silent_auto_event_suppress_evidence_hold)
		await get_tree().process_frame
	_silent_auto_event_pending = false
	_silent_auto_event_suppress_evidence_hold = false


func _play_event_now(evt_id: String, suppress_evidence_hold := false) -> void:
	var previous_suppress_evidence_hold := GameManager.suppress_evidence_obtain_hold
	if suppress_evidence_hold:
		GameManager.suppress_evidence_obtain_hold = true
	var evt: Dictionary = GameManager.get_day_event(evt_id)
	var evt_for_effects: Dictionary = evt.duplicate(true)
	var effects_for_apply: Dictionary = evt_for_effects.get("effects", {})
	var deferred_location := ""
	if bool(effects_for_apply.get("defer_change_location", false)) and effects_for_apply.has("change_location"):
		deferred_location = str(effects_for_apply.get("change_location", ""))
		effects_for_apply.erase("change_location")
		effects_for_apply.erase("defer_change_location")
		evt_for_effects["effects"] = effects_for_apply
	var lines: Array = []
	var default_narration_fx: Dictionary = evt.get("effects", {}).get("narration_fx", {})
	var cabin_escape_insert_index := -1
	var idx := 0
	for line in evt.get("narration", []):
		if line is Dictionary:
			var line_dict: Dictionary = line.duplicate(true)
			var line_effect: Dictionary = line_dict.get("effect", {})
			if bool(line_effect.get("cabin_escape_panel", false)):
				cabin_escape_insert_index = lines.size()
				idx += 1
				continue
			if not default_narration_fx.is_empty():
				var merged_effect := default_narration_fx.duplicate(true)
				for key in line_effect.keys():
					merged_effect[key] = line_effect[key]
				line_dict["effect"] = merged_effect
			lines.append(line_dict)
		else:
			var voice_path: String = AssetResolver.resolve_event_voice_path(evt_id, idx)
			var item := { "speaker": "", "text": str(line), "voice_path": voice_path }
			if not default_narration_fx.is_empty():
				item["effect"] = default_narration_fx.duplicate(true)
			lines.append(item)
		idx += 1
	# 检查是否需要在 narration 结束后自动进入对峙
	var suppress_arrival_banter_after_event := bool(evt.get("effects", {}).get("suppress_arrival_banter", false))
	var suppress_location_intro_after_event := bool(evt.get("effects", {}).get("suppress_location_intro", false))
	var auto_confront: String = str(evt.get("effects", {}).get("auto_start_confrontation", ""))

	var finish_event := func():
		# 事件级效果必须在整段叙事播放完后再落库。
		# 否则玩家在沉船/指控等长事件中途退出，继续游戏会把未播完的剧情当作已完成。
		GameManager.apply_event_effects(evt_for_effects, not suppress_evidence_hold)
		GameManager.suppress_evidence_obtain_hold = previous_suppress_evidence_hold
		if deferred_location != "":
			if suppress_arrival_banter_after_event:
				_suppress_next_arrival_banter = true
			if suppress_location_intro_after_event:
				_suppress_next_location_intro = true
			GameManager.change_location(deferred_location, false)
		_refresh_event_hint()
		_try_companion_banter("after_event:" + evt_id)
		if auto_confront != "":
			_deferred_start_confrontation.call_deferred(auto_confront)

	if cabin_escape_insert_index >= 0:
		var before_escape: Array = lines.slice(0, cabin_escape_insert_index)
		var after_escape: Array = lines.slice(cabin_escape_insert_index)
		var play_after_escape := func():
			if after_escape.is_empty():
				finish_event.call()
			else:
				DialogueManager.play_adhoc_narration(after_escape, finish_event, suppress_evidence_hold)
		var show_escape := func():
			_show_cabin_escape_panel(play_after_escape)
		if before_escape.is_empty():
			show_escape.call()
		else:
			DialogueManager.play_adhoc_narration(before_escape, show_escape, suppress_evidence_hold)
	else:
		DialogueManager.play_adhoc_narration(lines, finish_event, suppress_evidence_hold)


func _show_cabin_escape_panel(done: Callable) -> void:
	dialogue_box.visible = false
	menu_panel.visible = false
	event_hint_btn.visible = false
	if _npc_layer and _npc_layer.has_method("hide_npcs"):
		_npc_layer.hide_npcs()
	if _scene_fx:
		_scene_fx.clear_layers()

	var top_bar: CanvasItem = top_bar_label.get_parent() as CanvasItem
	var top_bar_was_visible: bool = top_bar.visible
	top_bar.visible = false

	var PanelScript: Script = load("res://scripts/ui/CabinEscapePanel.gd") as Script
	if PanelScript == null:
		top_bar.visible = top_bar_was_visible
		if done.is_valid():
			done.call()
		return
	var panel: Control = PanelScript.new()
	panel.name = "CabinEscapePanel"
	add_child(panel)
	panel.move_to_front()
	var on_completed := func():
		if is_instance_valid(panel):
			panel.queue_free()
		top_bar.visible = top_bar_was_visible
		if done.is_valid():
			done.call()
	panel.completed.connect(on_completed, CONNECT_ONE_SHOT)


func _deferred_start_confrontation(confront_key: String) -> void:
	await get_tree().create_timer(0.5).timeout
	GameManager.active_confrontation_key = confront_key
	_open_confrontation_panel()


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
	var popped_evt = _pending_events.pop_front()
	if popped_evt == null:
		event_hint_btn.visible = false
		return
	var evt_id := str(popped_evt)
	# 先关闭关键发现弹窗，再进入助手/旁白对话，避免 UI 重叠。
	event_hint_btn.visible = false
	await get_tree().process_frame
	# 若触发点发生在普通对话/叙述中，等当前说话完全结束后再插入关键发现对话。
	while dialogue_box.visible or GameManager.current_state == GameManager.STATE_DIALOGUE or subpanel_container.visible:
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
	var popped_evt = _pending_events.pop_front()
	if popped_evt == null:
		event_hint_btn.visible = false
		return
	var evt_id := str(popped_evt)
	event_hint_btn.visible = false
	_play_event_now(evt_id)


# ─── 菜单 ───
func _on_menu_locked_hint_requested(hint: String) -> void:
	_flash_notification(hint)


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
	GameManager.collected_evidence.clear()
	GameManager.collected_clues.clear()
	GameManager.dialogue_flags.clear()
	GameManager.visited_nodes.clear()
	GameManager.visited_node_versions.clear()
	GameManager.triggered_events.clear()
	GameManager.unlocked_phases = ["phase_0", "phase_1"]
	GameManager.ACTIVE_CASE = ""
	_show_title()


func gm_preset_options() -> Array:
	var out: Array = []
	for preset_id in GM_PRESET_ORDER:
		var preset: Dictionary = GM_PRESETS.get(preset_id, {})
		out.append({"id": preset_id, "label": preset.get("label", preset_id)})
	return out


func gm_apply_preset(preset_id: String, reset_first := true) -> void:
	if not GM_PRESETS.has(preset_id):
		_flash_notification("未知 GM 预设：" + preset_id)
		return
	GameManager.reload_current_case_tables()
	var preset: Dictionary = GM_PRESETS[preset_id]
	if reset_first:
		GameManager.reset_progress()
	_gm_grant_state(preset)
	_gm_prepare_surface(true)
	_gm_force_location(str(preset.get("location", GameManager.case_main_scene)))
	_flash_notification("GM 预设：" + str(preset.get("label", preset_id)))


func gm_apply_preset_and_confront(preset_id: String) -> void:
	gm_apply_preset(preset_id, true)
	var preset: Dictionary = GM_PRESETS.get(preset_id, {})
	var confront_key := str(preset.get("confrontation", ""))
	if confront_key == "":
		_flash_notification("此预设没有绑定对峙")
		return
	gm_start_confrontation(confront_key, false)


func gm_jump_to_dialogue(npc_id: String, node_id: String) -> void:
	if npc_id == "" or node_id == "":
		_flash_notification("格式：npc_id.node_id")
		return
	GameManager.reload_current_case_tables()
	_gm_prepare_surface(false)
	DialogueManager.start_dialogue_at(npc_id, node_id, true)


func gm_jump_to_narration(doc_id: String, node_id: String) -> void:
	if doc_id == "" or node_id == "":
		_flash_notification("格式：doc_id.node_id")
		return
	GameManager.reload_current_case_tables()
	_gm_prepare_surface(false)
	DialogueManager.start_narration_at(doc_id, node_id, true)


func gm_play_event(evt_id: String) -> void:
	if evt_id == "":
		_flash_notification("请输入事件 ID")
		return
	GameManager.reload_current_case_tables()
	if GameManager.get_day_event(evt_id).is_empty():
		_flash_notification("未知事件：" + evt_id)
		return
	_gm_prepare_surface(false)
	_play_event_now(evt_id, true)


func gm_start_confrontation(confront_key: String, reload_tables := true) -> void:
	if reload_tables:
		var preset_id := str(GM_CONFRONTATION_PRESET_MAP.get(confront_key, ""))
		if preset_id != "":
			gm_apply_preset(preset_id, true)
		else:
			GameManager.reload_current_case_tables()
	if confront_key == "":
		_flash_notification("请输入对峙 ID")
		return
	if not GameManager.case_data.has(confront_key):
		_flash_notification("未知对峙：" + confront_key)
		return
	_gm_prepare_surface(false)
	GameManager.suppress_evidence_obtain_hold = true
	GameManager.active_confrontation_key = confront_key
	_open_confrontation_panel()


func gm_play_fixed_epilogue() -> void:
	GameManager.reload_current_case_tables()
	_gm_prepare_surface(false)
	var preset: Dictionary = GM_PRESETS.get("fixed_epilogue", {})
	_gm_grant_state(preset)
	GameManager.save_game()
	if not _try_play_case_epilogue("prologue_fixed"):
		_show_ending("prologue_fixed")


func gm_preview_center_npc(npc_id: String, emotion: String = "base") -> void:
	if _npc_layer == null or not is_instance_valid(_npc_layer) or not _npc_layer.has_method("preview_center_npc"):
		_flash_notification("中央 NPC 预览层不可用")
		return
	_gm_prepare_surface(false)
	if GameManager.current_location != "" and GameManager.locations_data.has(GameManager.current_location):
		_gm_force_location(GameManager.current_location)
	if not _npc_layer.preview_center_npc(npc_id, emotion):
		_flash_notification("预览失败：%s / %s" % [npc_id, emotion])


func gm_clear_center_preview() -> void:
	if _npc_layer != null and is_instance_valid(_npc_layer) and _npc_layer.has_method("clear_preview"):
		_npc_layer.clear_preview()


func gm_reload_center_npc_layouts() -> void:
	GameManager.reload_current_case_tables()
	if _npc_layer != null and is_instance_valid(_npc_layer):
		if _npc_layer.has_method("clear_preview"):
			_npc_layer.clear_preview()
		elif _npc_layer.has_method("refresh_npcs") and GameManager.current_location != "":
			_npc_layer.refresh_npcs(GameManager.current_location)
	_flash_notification("已重载中央 NPC 配置")


func gm_return_to_title() -> void:
	_show_title()


func _gm_prepare_surface(show_menu := true) -> void:
	_close_subpanel()
	_pending_events.clear()
	_pending_adhoc_lines.clear()
	_event_hint_auto_pending = false
	event_hint_btn.visible = false
	ending_screen.visible = false
	dialogue_box.visible = false
	subpanel_container.visible = false
	GameManager.suppress_evidence_obtain_hold = false
	_hide_title()
	menu_panel.visible = show_menu
	GameManager.set_state(GameManager.STATE_PLAYING)
	# 状态切到 PLAYING 后重新触发阶段解锁判定
	# （_gm_grant_state 里 set_flag 调的 _check_progression 会因 STATE_PROLOGUE 跳过条件阶段）
	GameManager._check_progression()
	if _scene_fx and _scene_fx.has_method("clear_layers"):
		_scene_fx.clear_layers()
	if _npc_layer and _npc_layer.has_method("show_npcs"):
		_npc_layer.show_npcs()


func _gm_grant_state(preset: Dictionary) -> void:
	for flag_id in preset.get("flags", []):
		GameManager.set_flag(str(flag_id))
	for evidence_id in preset.get("evidence", []):
		if GameManager.evidence_data.has(str(evidence_id)):
			GameManager.add_evidence(str(evidence_id), false)
	for clue_id in preset.get("clues", []):
		if GameManager.evidence_data.has(str(clue_id)):
			GameManager.add_clue(str(clue_id))
	_gm_clear_event_noise()


func _gm_clear_event_noise() -> void:
	_pending_events.clear()
	_event_hint_auto_pending = false
	event_hint_btn.visible = false


func _gm_force_location(loc_id: String, suppress_entry := true) -> void:
	if loc_id == "" or not GameManager.locations_data.has(loc_id):
		return
	if suppress_entry:
		_suppress_next_arrival_banter = true
		_suppress_next_location_intro = true
	GameManager.current_location = loc_id
	if not GameManager.visited_locations.has(loc_id):
		GameManager.visited_locations.append(loc_id)
	GameManager.location_changed.emit(loc_id)
	GameManager.save_game()


func is_subpanel_active() -> bool:
	return _active_subpanel != null and is_instance_valid(_active_subpanel)


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
	# 进入探索模式时隐藏 NPC 立绘和对话框残留
	if _npc_layer and _npc_layer.has_method("hide_npcs"):
		_npc_layer.hide_npcs()
	dialogue_box.visible = false
	dialogue_box.portrait_rect.visible = false
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
	BgmPlayer.play("ferry_inn_investigation")
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
	GameManager.suppress_evidence_obtain_hold = false
	var confront_key: String = GameManager.active_confrontation_key
	var confront_data: Dictionary = GameManager.case_data.get(confront_key, {})
	_defer_adhoc_until_confrontation_result_done = not bool(confront_data.get("is_final", false))
	# 对峙胜利后设置对应 flag
	if result == "victory":
		var suspect: String = GameManager.case_data.get(confront_key, {}).get("suspect", "")
		if confront_key == "confrontation_wang":
			GameManager.set_flag("self_cleared")
			GameManager.set_flag("wang_testimony_debunked")
			GameManager.set_flag("zhou_wife_bribe_exposed")
		elif suspect == "agui":
			GameManager.set_flag("agui_confessed_mastermind")
		elif confront_key == "confrontation_final" and GameManager.ACTIVE_CASE == "prologue_ferry":
			GameManager.set_flag("prologue_truth_reached")
			GameManager.set_flag("prologue_defeated")
			GameManager.set_flag("case_partially_resolved")
		GameManager.set_flag(confront_key + "_completed")
	# 重置对峙路由键（DialogueManager 在下次触发时会重新设置正确的 key）
	GameManager.active_confrontation_key = "confrontation"
	# 判断是否为中间对峙（非最终BOSS）：播放过渡剧情后返回调查
	if not confront_data.get("is_final", false):
		_play_mid_confrontation_result(confront_key, confront_data, result, mistakes)
		return
	# 最终对峙 → 结局流程。序章终局无论机制胜败，都是"逼近真相但沈清月翻盘"的败局。
	var ending_id := GameManager.judge_confrontation(result, mistakes)
	if confront_key == "confrontation_final" and GameManager.ACTIVE_CASE == "prologue_ferry":
		GameManager.set_flag("prologue_defeated")
		GameManager.set_flag("case_partially_resolved")
		if result == "victory":
			GameManager.set_flag("prologue_truth_reached")
		ending_id = "prologue_fixed"
	if ending_id == "bad" or ending_id == "partial":
		_try_companion_banter("accuse_fail")
	if _try_play_case_epilogue(ending_id):
		return
	_defer_adhoc_until_confrontation_result_done = false
	_show_ending(ending_id)


func _play_mid_confrontation_result(confront_key: String, confront_data: Dictionary, result: String, _mistakes: int) -> void:
	# 中间对峙（如阿贵）：播放胜利/失败对话后返回调查模式
	var dialogue_key := "victory_dialogue" if result == "victory" else "defeat_dialogue"
	var lines: Array = confront_data.get(dialogue_key, [])
	if lines.size() > 0:
		DialogueManager.play_adhoc_narration(lines, func():
			_after_mid_confrontation(confront_key, result)
		)
	else:
		_after_mid_confrontation(confront_key, result)


func _after_mid_confrontation(confront_key: String, result: String) -> void:
	if result == "victory":
		# 胜利后增加一段情感缓冲，避免从高潮直接跳到菜单
		var buffer_lines: Array = []
		if confront_key == "confrontation_wang":
			buffer_lines = [
				{"speaker": "凌瑶", "text": "看吧！雾里认人、风浪里听喊声、还有你上岸那会儿的样子，这几句都站不住了。你不是凶手。", "emotion": "determined"},
				{"speaker": "钱里正", "text": "既然这份证词压不住人，我不会再把陆公子当凶犯看。但案子没结，客栈里的人都先别走。", "emotion": "stern"},
				{"speaker": "陆昭", "text": "王大爷的证词站不住了。有人想先把我钉死，再让真正的凶手从证据缝里逃走。", "emotion": "cold"},
				{"speaker": "凌瑶", "text": "还有沈清月。她开场那几句听着像讲理，其实是在先把你摁成最顺手的嫌犯。", "emotion": "worried"},
				{"speaker": "陆昭", "text": "先不碰她。回到证据：船怎么沉，周德茂怎么死，阿贵和老范为什么活下来。一样一样查。", "emotion": "serious"},
				{"speaker": "凌瑶", "text": "明白。客栈里能问的先问清楚，码头那条破船也得重新看。", "emotion": "determined"}
			]
		else:
			buffer_lines = [
				{"speaker": "凌瑶", "text": "……这案子比我想的要深多了。阿贵只是棋子——真正的对手还在后面。", "emotion": "worried"},
				{"speaker": "凌瑶", "text": "走吧。趁她还没反应过来——我们去查。", "emotion": "determined"}
			]
		DialogueManager.play_adhoc_narration(buffer_lines, func():
			_return_to_investigation(confront_key, result)
		)
	else:
		# 对峙失败：播放失败旁白后退回标题界面
		var defeat_lines: Array = [
			{"speaker": "", "text": "证据不足。你没能拆穿对方的证词。"},
			{"speaker": "", "text": "真相还在迷雾里。你只能暂且退下，重新审视手头的线索。"},
		]
		DialogueManager.play_adhoc_narration(defeat_lines, func():
			_return_to_title_after_defeat()
		)


func _return_to_investigation(confront_key: String, result: String) -> void:
	# 返回主界面继续调查
	menu_panel.visible = true
	_defer_adhoc_until_confrontation_result_done = false
	BgmPlayer.play(GameManager.current_location)
	if menu_panel.has_method("refresh_visibility"):
		menu_panel.refresh_visibility()
	if _npc_layer and _npc_layer.has_method("refresh_npcs"):
		_npc_layer.refresh_npcs(GameManager.current_location)
	_refresh_event_hint()
	_flush_pending_adhoc_lines()
	# 注意：set_flag("agui_confessed_mastermind") 已在上层调用。
	# GameManager.set_flag 内部自动调用 _check_progression()，
	# 所以 phase_3 的解锁条件（flag: agui_confessed_mastermind）已满足，
	# phase_unlocked 信号已经发射，_on_phase_unlocked 会处理通知和菜单刷新。
	if result != "victory":
		_try_companion_banter("accuse_fail")


func _return_to_title_after_defeat() -> void:
	# 对峙失败后退回标题界面
	dialogue_box.visible = false
	menu_panel.visible = false
	subpanel_container.visible = false
	event_hint_btn.visible = false
	top_bar_label.get_parent().visible = false
	BgmPlayer.stop()
	_show_title()


func _try_play_case_epilogue(ending_id: String) -> bool:
	var root := CaseTableLoader.load_narration(GameManager.ACTIVE_CASE, "epilogue_meta")
	if root.is_empty():
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
	# NPC 已在 NpcSceneLayer 可见时，跳过 DialogueBox 的立绘入场动画（避免拖动/跳动感）
	if _npc_layer and _npc_layer._portrait and _npc_layer._portrait.visible and _npc_layer._portrait.modulate.a > 0.5:
		dialogue_box.skip_portrait_intro()
	dialogue_box.show_dialogue(speaker, portrait, text, options, pages)
	dialogue_box.visible = true
	menu_panel.visible = false
	if _npc_layer and _npc_layer.has_method("hide_npcs"):
		_npc_layer.hide_npcs()


func _on_dialogue_ended() -> void:
	dialogue_box.visible = false
	menu_panel.visible = true
	_refresh_event_hint()
	if _npc_layer and _npc_layer.has_method("show_npcs"):
		_npc_layer.show_npcs()


# ─── 序章 / 叙述 ───
func _on_narration_started(background: String, _speaker: String, text: String, has_next: bool, _centered: bool, portrait: String = "") -> void:
	if background != "":
		_set_background(background, true)
	# 进入游戏前的过场不叠加场景特效；无背景的助手短评不打断当前地点特效。
	if background != "" and _scene_fx:
		_scene_fx.clear_layers()
	if dialogue_box and dialogue_box.has_method("set_next_narration_typewriter_settings"):
		dialogue_box.set_next_narration_typewriter_settings(
			_next_narration_typewriter_skip_disabled,
			_next_narration_typewriter_char_delay
		)
	elif dialogue_box and dialogue_box.has_method("set_next_narration_typewriter_skip_disabled"):
		dialogue_box.set_next_narration_typewriter_skip_disabled(_next_narration_typewriter_skip_disabled)
	_next_narration_typewriter_skip_disabled = false
	_next_narration_typewriter_char_delay = -1.0
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
		top_bar_label.get_parent().visible = true
		var initial_time_card_key := "D%d_%s" % [GameManager.current_day, GameManager.case_main_scene]
		GameManager.shown_time_cards[initial_time_card_key] = true
		GameManager.change_location(GameManager.case_main_scene, false)
		_update_top_bar()
	menu_panel.visible = true
	_refresh_event_hint()
	if _npc_layer and _npc_layer.has_method("show_npcs"):
		_npc_layer.show_npcs()


## 叙述中遇到 video 节点：播放视频，结束后自动推进叙述
func _on_narration_video(video_path: String) -> void:
	if video_path == "":
		DialogueManager.narration_next()
		return
	
	# 用 FileAccess 检查原始文件（不依赖 Godot 导入缓存）
	if not FileAccess.file_exists(video_path):
		push_warning("[MainGame] Video file not found: %s, skipping." % video_path)
		DialogueManager.narration_next()
		return
	
	if dialogue_box and dialogue_box.has_method("clear_for_transition"):
		dialogue_box.clear_for_transition()
	dialogue_box.visible = false
	menu_panel.visible = false
	
	# 直接 load（Godot 4 会自动触发即时导入 .ogv）
	var stream: Resource = load(video_path)
	if stream and stream is VideoStream:
		var vp := VideoStreamPlayer.new()
		vp.expand = true
		vp.loop = false
		vp.bus = &"Master"
		vp.volume_db = 0.0
		add_child(vp)
		vp.stream = stream
		vp.play()
		print("[MainGame] Playing video: %s" % video_path)
		vp.finished.connect(func():
			vp.queue_free()
			dialogue_box.visible = true
			menu_panel.visible = true
			DialogueManager.narration_next()
		, CONNECT_ONE_SHOT)
	else:
		push_error("[MainGame] Failed to load video stream: %s" % video_path)
		dialogue_box.visible = true
		menu_panel.visible = true
		DialogueManager.narration_next()

## 叙述中遇到 time_card 节点：显示时间过场，结束后自动推进叙述
func _on_narration_time_card(text: String, sub_text: String) -> void:
	if dialogue_box and dialogue_box.has_method("clear_for_transition"):
		dialogue_box.clear_for_transition()
	dialogue_box.visible = false
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


## 叙述演出效果处理（震动/闪屏/色调/心理活动渐暗）
func _on_narration_effects(fx: Dictionary) -> void:
	_next_narration_typewriter_skip_disabled = bool(fx.get("disable_typewriter_skip", false))
	_next_narration_typewriter_char_delay = float(fx.get("typewriter_char_delay", -1.0))
	if fx.has("bgm"):
		var bgm_id := str(fx.get("bgm", ""))
		if bgm_id != "":
			BgmPlayer.play(bgm_id)
	if fx.get("shake", false):
		var intensity: float = float(fx.get("shake_intensity", 6.0))
		var duration: float = float(fx.get("shake_duration", 0.4))
		_do_screen_shake(intensity, duration)
	if fx.has("flash"):
		var color_str: String = str(fx.get("flash", "white"))
		var color := Color.WHITE
		if color_str == "white":
			color = Color(1, 1, 1, 0.7)
		elif color_str == "black":
			color = Color(0, 0, 0, 0.9)
		elif color_str == "blue":
			color = Color(0.1, 0.2, 0.5, 0.6)
		dialogue_box.flash_screen(color, float(fx.get("flash_duration", 0.2)))
	if fx.has("tint"):
		var tint_str: String = str(fx.get("tint", ""))
		if tint_str == "dark_blue":
			_bg_fade_rect.color = Color(0.02, 0.05, 0.15, 0.4)
		elif tint_str == "clear":
			_bg_fade_rect.color = Color(0, 0, 0, 0)
	# 心理活动渐暗/恢复效果
	if fx.has("mind_fade"):
		var fade_str: String = str(fx.get("mind_fade", ""))
		var fade_duration: float = float(fx.get("mind_fade_duration", 1.5))
		if fade_str == "in":
			_mind_fade_tween(fade_duration, 0.0, 0.65)
		elif fade_str == "out":
			_mind_fade_tween(fade_duration, _bg_fade_rect.color.a, 0.0)
	# 心理活动音效提示（可选）
	if fx.has("mind_sfx"):
		var sfx_player = get_node_or_null("/root/SfxPlayer")
		if sfx_player and sfx_player.has_method("play"):
			sfx_player.play(str(fx.get("mind_sfx")))
	if fx.has("sfx"):
		var sfx_player = get_node_or_null("/root/SfxPlayer")
		if sfx_player and sfx_player.has_method("play"):
			sfx_player.play(str(fx.get("sfx")))
	# CG 背景偏移：bg_offset_y 负值向上推画面，露出被对话框遮住的下半部分
	if fx.has("bg_offset_y"):
		scene_bg.position.y = float(fx.get("bg_offset_y"))


## 心理活动渐暗：使用 _bg_fade_rect 做全屏黑幕渐变
func _mind_fade_tween(duration: float, from_alpha: float, to_alpha: float) -> void:
	if _bg_fade_rect == null:
		return
	# 如果正在执行 mind_fade tween，先停止
	if _mind_fade_tween_ref != null and _mind_fade_tween_ref.is_valid():
		_mind_fade_tween_ref.kill()
	_bg_fade_rect.color = Color(0.01, 0.01, 0.03, from_alpha)
	_mind_fade_tween_ref = create_tween()
	_mind_fade_tween_ref.tween_property(_bg_fade_rect, "color:a", to_alpha, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

var _mind_fade_tween_ref: Tween = null


func _do_screen_shake(intensity: float = 6.0, duration: float = 0.4) -> void:
	var targets: Array[CanvasItem] = []
	if is_instance_valid(scene_bg):
		targets.append(scene_bg)
	if _scene_fx and is_instance_valid(_scene_fx):
		targets.append(_scene_fx)
	if _bg_fade_rect and is_instance_valid(_bg_fade_rect):
		targets.append(_bg_fade_rect)
	if _npc_layer and is_instance_valid(_npc_layer):
		targets.append(_npc_layer)
	if targets.is_empty():
		return
	for target in _screen_shake_base_positions.keys():
		if is_instance_valid(target):
			target.position = _screen_shake_base_positions[target]
	if _screen_shake_tween_ref != null and _screen_shake_tween_ref.is_valid():
		_screen_shake_tween_ref.kill()
	var original_positions: Dictionary = {}
	for target in targets:
		original_positions[target] = target.position
	_screen_shake_base_positions = original_positions.duplicate()
	_screen_shake_tween_ref = create_tween()
	var steps := int(duration / 0.05)
	for i in range(steps):
		var offset_x: float = intensity * (1.0 if i % 2 == 0 else -1.0) * (1.0 - float(i) / steps)
		var offset_y: float = intensity * 0.5 * (1.0 if i % 3 == 0 else -1.0) * (1.0 - float(i) / steps)
		var first_target := true
		for target in targets:
			var base_pos: Vector2 = original_positions.get(target, target.position)
			if first_target:
				_screen_shake_tween_ref.tween_property(target, "position", base_pos + Vector2(offset_x, offset_y), 0.05)
				first_target = false
			else:
				_screen_shake_tween_ref.parallel().tween_property(target, "position", base_pos + Vector2(offset_x, offset_y), 0.05)
	var restore_first := true
	for target in targets:
		var base_pos: Vector2 = original_positions.get(target, target.position)
		if restore_first:
			_screen_shake_tween_ref.tween_property(target, "position", base_pos, 0.05)
			restore_first = false
		else:
			_screen_shake_tween_ref.parallel().tween_property(target, "position", base_pos, 0.05)
	_screen_shake_tween_ref.tween_callback(func():
		_screen_shake_base_positions.clear()
	)


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
	if ending_id == "perfect" or ending_id == "good" or ending_id == "prologue_fixed":
		BgmPlayer.play("ending_perfect")
	else:
		BgmPlayer.play("ending_bad")
	# 检查结局是否有前置叙事（pre_narration）
	var data := GameManager.get_ending(ending_id)
	var pre_narration: Array = data.get("pre_narration", [])
	if not pre_narration.is_empty():
		menu_panel.visible = false
		DialogueManager.play_adhoc_narration(pre_narration, func():
			_display_ending_screen(ending_id, data)
		)
		return
	_display_ending_screen(ending_id, data)


func _display_ending_screen(ending_id: String, data: Dictionary) -> void:
	# 通知调查员档案：结算 XP / 升级 / 解锁
	var summary: Dictionary = {}
	var iv := get_node_or_null("/root/InvestigatorService")
	if iv:
		summary = iv.record_case_cleared(GameManager.ACTIVE_CASE, ending_id)
	ending_screen.show_ending(data.get("title", ""), data.get("narration", ""))
	if ending_screen.has_method("show_progression_summary") and not summary.is_empty():
		ending_screen.show_progression_summary(summary, iv)
	ending_screen.visible = true
	menu_panel.visible = false
	dialogue_box.visible = false
	dialogue_box.visible = false
	subpanel_container.visible = false
	event_hint_btn.visible = false


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
	if _defer_adhoc_until_confrontation_result_done or _is_search_panel_busy():
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
