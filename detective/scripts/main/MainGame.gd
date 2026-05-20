extends Control
## 主游戏 UI：左场景插图 + 右菜单 + 底部对话框 + 顶部时间条
## 协调所有面板的展开/收起 + 日期过场 + 日程事件提示

@onready var scene_bg: TextureRect = $Background
@onready var top_bar_label: Label = $TopBar/TimeLabel
@onready var location_label: Label = $TopBar/LocationLabel
@onready var menu_panel: Control = $RightMenu
@onready var subpanel_container: Control = $SubPanelContainer
@onready var dialogue_box: Control = $DialogueBox
@onready var narration_box: Control = $NarrationBox
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
	"accuse": "res://scenes/ui/AccusePanel.tscn",
	"settings": "res://scenes/ui/SettingsPanel.tscn",
}

var _active_subpanel: Control = null
var _pending_events: Array[String] = []
var _pending_adhoc_lines: Array = []
var _pending_day_info: Dictionary = {}   # 延迟的日期过场 { "day": int, "sub": String }
var _title_layer: Control = null
var _title_props_layer: Control = null
var _scene_fx: Node = null
var _playing_case_epilogue := false
#var _npc_layer: Control = null


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
	DialogueManager.narration_started.connect(_on_narration_started)
	DialogueManager.narration_ended.connect(_on_narration_ended)
	DialogueManager.lie_exposed.connect(_on_lie_exposed)
	
	menu_panel.menu_clicked.connect(_on_menu_clicked)
	event_hint_btn.pressed.connect(_on_event_hint_clicked)
	
	dialogue_box.visible = false
	narration_box.visible = false
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
	
	# NPC 场景立绘层（已禁用）
	#var NpcLayer = load("res://scripts/ui/NpcSceneLayer.gd")
	#if NpcLayer:
	#	_npc_layer = NpcLayer.new()
	#	_npc_layer.name = "NpcSceneLayer"
	#	add_child(_npc_layer)
	#	if _scene_fx:
	#		move_child(_npc_layer, _scene_fx.get_index() + 1)
	
	BgmPlayer.register_players(bgm_a, bgm_b)
	
	# 助手系统：被动旁白信号
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_signal("banter_ready"):
		cs.banter_ready.connect(_on_companion_banter)
	
	_show_title()


# ─── 标题界面 ───
func _show_title() -> void:
	menu_panel.visible = false
	top_bar_label.get_parent().visible = false
	dialogue_box.visible = false
	narration_box.visible = false
	subpanel_container.visible = false
	ending_screen.visible = false
	event_hint_btn.visible = false
	
	var bg := AssetResolver.get_scene_background_by_id("scene_title")
	if bg == "":
		bg = "res://assets/cn/scenes/title_screen.png"
	if ResourceLoader.exists(bg):
		scene_bg.texture = load(bg)
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

	vbox.add_child(_make_title_button("开 始 游 戏", _on_start_game_pressed, false))
	if GameManager.has_save():
		vbox.add_child(_make_title_button("继 续 游 戏", _continue_game, false))
	# 仅当案件索引中有 ≥ 2 个案件时显示"选择案件"
	var case_count: int = GameManager.get_case_index_entries().size()
	if case_count >= 2:
		var current_title: String = GameManager.case_manifest.get("title", GameManager.ACTIVE_CASE)
		vbox.add_child(_make_title_button("选 择 案 件 （当前：%s）" % current_title, _on_select_case_pressed, false))
	vbox.add_child(_make_title_button("设 置", _on_title_settings_pressed, false))
	vbox.add_child(_make_title_button("退 出 游 戏", func(): get_tree().quit(), false))


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


func _on_start_game_pressed() -> void:
	if GameManager.has_save():
		_show_restart_confirm()
		return
	_start_new_game()


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
	top_bar_label.get_parent().visible = true
	_pending_events.clear()
	GameManager.reset_progress()
	GameManager.set_state(GameManager.STATE_PROLOGUE)
	BgmPlayer.play("prologue")
	DialogueManager.start_narration("res://data/cases/%s/prologue.json" % GameManager.ACTIVE_CASE)


func _continue_game() -> void:
	if not GameManager.load_game():
		return
	_hide_title()
	top_bar_label.get_parent().visible = true
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
	# 通过 AssetResolver 解析背景（scene_type → registry → background，回退到 data.background）
	var bg_path: String = AssetResolver.get_scene_background(data)
	if bg_path != "" and ResourceLoader.exists(bg_path):
		scene_bg.texture = load(bg_path)
	# 同步场景动态特效层
	if _scene_fx and _scene_fx.has_method("apply_for_scene_id"):
		_scene_fx.apply_for_scene_id(data.get("scene_type", ""))
	# 刷新 NPC 场景立绘层
	#if _npc_layer and _npc_layer.has_method("refresh_npcs"):
	#	_npc_layer.refresh_npcs(loc_id)
	BgmPlayer.play(loc_id)
	if menu_panel.has_method("refresh_visibility"):
		menu_panel.refresh_visibility()
	_close_subpanel()
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
	if narration_box.visible or dialogue_box.visible:
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
	event_hint_btn.text = "  ★  " + evt.get("title", "新事件")
	event_hint_btn.tooltip_text = evt.get("hint", "")
	event_hint_btn.visible = true


func _on_event_hint_clicked() -> void:
	if _pending_events.is_empty():
		return
	var evt_id: String = _pending_events.pop_front()
	event_hint_btn.visible = false
	var evt = GameManager.get_day_event(evt_id)
	# 应用效果
	GameManager.apply_event_effects(evt)
	# 播放叙述：支持字符串，也支持 {speaker,text,voice_path}
	# 注意：事件叙述的 voice_path 必须按案件隔离。data 中显式写的 voice_path 视为'已确认正确'，
	# 否则通过 AssetResolver.resolve_event_voice_path 严格按当前案件查找；找不到就传空（静默）。
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


# ─── 菜单 ───
func _on_menu_clicked(menu_id: String) -> void:
	if menu_id == "talk":
		var npcs: Array = GameManager.get_active_npcs_at(GameManager.current_location)
		if npcs.is_empty():
			_flash_notification("此处无人。")
			return
	if menu_id == "discuss":
		_open_discuss_panel()
		return
	_open_subpanel(menu_id)


func _open_subpanel(menu_id: String) -> void:
	_close_subpanel()
	if not SubPanels.has(menu_id):
		return
	if menu_id == "accuse":
		BgmPlayer.play("accuse")
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
	if panel.has_signal("accuse_submitted"):
		panel.accuse_submitted.connect(_on_accuse_submitted)
	if panel.has_signal("return_to_title_requested"):
		panel.return_to_title_requested.connect(_on_return_to_title)
	if panel.has_signal("search_result_acknowledged"):
		panel.search_result_acknowledged.connect(_on_search_result_acknowledged)


func _on_return_to_title() -> void:
	_close_subpanel()
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
	# 关闭指证面板后恢复地点 BGM
	if was_active and BgmPlayer.current_bgm_id() == "accuse":
		BgmPlayer.play(GameManager.current_location)


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


func _on_accuse_submitted(suspect: String, motive: String, method: String, ev_list: Array) -> void:
	_close_subpanel()
	var ending_id := GameManager.judge_accusation(suspect, motive, method, ev_list)
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
func _on_dialogue_started(speaker: String, portrait: String, text: String, options: Array) -> void:
	dialogue_box.show_dialogue(speaker, portrait, text, options)
	dialogue_box.visible = true
	menu_panel.visible = false
	#if _npc_layer and _npc_layer.has_method("hide_npcs"):
	#	_npc_layer.hide_npcs()


func _on_dialogue_ended() -> void:
	dialogue_box.visible = false
	menu_panel.visible = true
	_refresh_event_hint()
	_try_show_pending_day_transition()
	#if _npc_layer and _npc_layer.has_method("show_npcs"):
	#	_npc_layer.show_npcs()


# ─── 序章 / 叙述 ───
func _on_narration_started(background: String, _speaker: String, text: String, has_next: bool, centered: bool) -> void:
	if background != "" and ResourceLoader.exists(background):
		scene_bg.texture = load(background)
	narration_box.show_narration(_speaker, text, has_next, centered)
	narration_box.visible = true
	menu_panel.visible = false
	#if _npc_layer and _npc_layer.has_method("hide_npcs"):
	#	_npc_layer.hide_npcs()


func _on_narration_ended() -> void:
	narration_box.visible = false
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
	#if _npc_layer and _npc_layer.has_method("show_npcs"):
	#	_npc_layer.show_npcs()


## 检查是否有延迟的日期过场等待显示（对话/叙述结束后调用）
func _try_show_pending_day_transition() -> void:
	if _pending_day_info.is_empty():
		return
	var info := _pending_day_info
	_pending_day_info = {}
	_show_day_transition(info.get("day", 1))


# ─── 选择案件 ───
func _on_select_case_pressed() -> void:
	# 弹出案件选择面板（在标题层之上）
	var packed: PackedScene = load("res://scenes/ui/CaseSelectPanel.tscn")
	if packed == null:
		push_error("CaseSelectPanel.tscn missing")
		return
	var panel: Control = packed.instantiate()
	add_child(panel)
	panel.case_chosen.connect(_on_case_chosen)
	panel.cancelled.connect(func(): panel.queue_free())


func _on_case_chosen(case_id: String) -> void:
	# 玩家选了一个案件
	if case_id != GameManager.ACTIVE_CASE:
		# 切到新案件，回标题
		GameManager.switch_case(case_id)
		_show_title()
	# 同案件不需要切，UI 已经会自动 close


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
	narration_box.visible = false
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
