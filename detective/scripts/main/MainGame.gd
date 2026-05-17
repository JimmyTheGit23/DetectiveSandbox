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
var _title_layer: Control = null
var _scene_fx: Node = null


func _ready() -> void:
	GameManager.location_changed.connect(_on_location_changed)
	GameManager.time_advanced.connect(_on_time_advanced)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.evidence_added.connect(_on_evidence_added)
	GameManager.clue_added.connect(_on_clue_added)
	GameManager.day_event_available.connect(_on_day_event_available)
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
	
	BgmPlayer.register_players(bgm_a, bgm_b)
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
	title.text = "推 理 模 拟 器"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	vbox.add_child(title)
	
	var sub := Label.new()
	sub.text = "水墨古风侦探 AVG"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62, 1))
	vbox.add_child(sub)
	
	vbox.add_child(_make_title_button("开 始 游 戏", _on_start_game_pressed, false))
	if GameManager.has_save():
		vbox.add_child(_make_title_button("继 续 游 戏", _continue_game, false))
	# 仅当案件索引中有 ≥ 2 个案件时显示"选择案件"
	var case_count: int = GameManager.get_case_index_entries().size()
	if case_count >= 2:
		var current_title: String = GameManager.case_manifest.get("title", GameManager.ACTIVE_CASE)
		vbox.add_child(_make_title_button("选 择 案 件 （当前：%s）" % current_title, _on_select_case_pressed, false))
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


func _on_start_game_pressed() -> void:
	if GameManager.has_save():
		_show_restart_confirm()
		return
	_start_new_game()


func _show_restart_confirm() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "重新开始？"
	dialog.dialog_text = "当前已有存档。开始新游戏会覆盖现有进度，确定要重新开始吗？"
	dialog.ok_button_text = "重新开始"
	dialog.cancel_button_text = "取消"
	add_child(dialog)
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_start_new_game()
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(460, 180))


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
	BgmPlayer.play(loc_id)
	_close_subpanel()


func _on_time_advanced(_day: int, _period: int) -> void:
	top_bar_label.text = "%s    距下一日 %d 时段    总剩余 %d 时段" % [GameManager.current_time_text(), GameManager.periods_until_next_day(), GameManager.remaining_periods()]
	if GameManager.is_time_up():
		_show_ending("timeout")


func _on_day_changed(new_day: int) -> void:
	# 跨日 → 播日期过场
	var sub := "临川镇 · %s" % GameManager.PERIOD_NAMES[GameManager.current_period]
	day_transition.show_day(new_day, sub)


func _on_evidence_added(eid: String) -> void:
	var ev = GameManager.evidence_data.get(eid, {})
	_flash_notification("【获得证据】" + ev.get("name", eid))


func _on_clue_added(cid: String) -> void:
	var cl = GameManager.evidence_data.get(cid, {})
	_flash_notification("【获得线索】" + cl.get("name", cid))


func _on_lie_exposed(npc_id: String, lie_node: String) -> void:
	var npc = GameManager.get_npc_data(npc_id)
	_flash_notification("【揭穿谎言】%s 的「%s」" % [npc.get("name", npc_id), lie_node])


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
	DialogueManager.play_adhoc_narration(lines, func(): _refresh_event_hint())


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
	DialogueManager.play_adhoc_narration(lines, func(): _refresh_event_hint())


# ─── 菜单 ───
func _on_menu_clicked(menu_id: String) -> void:
	if menu_id == "talk":
		var loc := GameManager.current_location_data()
		var npcs: Array = loc.get("npcs", [])
		if npcs.is_empty():
			_flash_notification("此处无人。")
			return
	_open_subpanel(menu_id)


func _open_subpanel(menu_id: String) -> void:
	_close_subpanel()
	if not SubPanels.has(menu_id):
		return
	if menu_id == "accuse":
		BgmPlayer.play("accuse")
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


func _on_return_to_title() -> void:
	_close_subpanel()
	_show_title()


func _close_subpanel() -> void:
	var was_active = _active_subpanel
	if _active_subpanel and is_instance_valid(_active_subpanel):
		_active_subpanel.queue_free()
		_active_subpanel = null
	subpanel_container.visible = false
	# 关闭指证面板后恢复地点 BGM
	if was_active and BgmPlayer.current_bgm_id() == "accuse":
		BgmPlayer.play(GameManager.current_location)


func _on_npc_selected(npc_id: String) -> void:
	_close_subpanel()
	DialogueManager.start_dialogue(npc_id)


func _on_location_selected(loc_id: String) -> void:
	_close_subpanel()
	GameManager.change_location(loc_id, true)


func _on_accuse_submitted(suspect: String, motive: String, method: String, ev_list: Array) -> void:
	_close_subpanel()
	var ending_id := GameManager.judge_accusation(suspect, motive, method, ev_list)
	_show_ending(ending_id)


# ─── 对话 ───
func _on_dialogue_started(speaker: String, portrait: String, text: String, options: Array) -> void:
	dialogue_box.show_dialogue(speaker, portrait, text, options)
	dialogue_box.visible = true
	menu_panel.visible = false


func _on_dialogue_ended() -> void:
	dialogue_box.visible = false
	menu_panel.visible = true
	_refresh_event_hint()


# ─── 序章 / 叙述 ───
func _on_narration_started(background: String, _speaker: String, text: String, has_next: bool, centered: bool) -> void:
	if background != "" and ResourceLoader.exists(background):
		scene_bg.texture = load(background)
	narration_box.show_narration(_speaker, text, has_next, centered)
	narration_box.visible = true
	menu_panel.visible = false


func _on_narration_ended() -> void:
	narration_box.visible = false
	if GameManager.current_state == GameManager.STATE_PROLOGUE:
		GameManager.set_state(GameManager.STATE_PLAYING)
		GameManager.change_location(GameManager.case_main_scene, false)
		_on_time_advanced(GameManager.current_day, GameManager.current_period)
	menu_panel.visible = true
	_refresh_event_hint()


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
	var data := GameManager.get_ending(ending_id)
	ending_screen.show_ending(data.get("title", ""), data.get("narration", ""))
	ending_screen.visible = true
	menu_panel.visible = false
	dialogue_box.visible = false
	narration_box.visible = false
	subpanel_container.visible = false
	event_hint_btn.visible = false
