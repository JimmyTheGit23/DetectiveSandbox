extends Control
## 对峙面板：逆转检视式证据击破
##
## 流程：犯人抛出谎言 → 玩家选择证据呈堂 → 判断是否击破
## 击破：播放"异议！"特效 + 击破对话 → 下一轮
## 失败：信心 -1 → 信心归零则败北

signal confrontation_finished(result: String, mistakes: int)  # result: "victory"/"defeat", mistakes: int

# ─── 状态机 ───
enum State { INTRO, LIE_PRESENTED, PLAYER_CHOOSE, BREAK_ANIM, FAIL_ANIM, VICTORY, DEFEAT }
var _state: int = State.INTRO

# ─── 数据 ───
var _confrontation_data: Dictionary = {}
var _current_round_idx: int = 0
var _confidence: int = 3
var _max_confidence: int = 3
var _mistakes: int = 0
var _selected_evidence_id: String = ""
var _dialogue_queue: Array = []
var _dialogue_idx: int = 0
var _is_playing_dialogue: bool = false

# ─── 节点引用 ───
var _panel: Control
var _portrait_rect: TextureRect
var _lie_label: RichTextLabel
var _evidence_container: VBoxContainer
var _confidence_label: Label
var _dialogue_box: PanelContainer
var _dialogue_speaker: Label
var _dialogue_text: RichTextLabel
var _objection_layer: Control
var _shake_tween: Tween = null

# ─── 立绘状态 ───
enum PortraitState { NORMAL, SHAKEN, COLLAPSED }
var _portrait_state: int = PortraitState.NORMAL

# ─── 风格常量 ───
const CLR_GOLD := Color(0.96, 0.88, 0.65)
const CLR_DIM := Color(0.55, 0.50, 0.42, 0.6)
const CLR_BG := Color(0.06, 0.04, 0.03, 0.97)
const CLR_BORDER := Color(0.6, 0.45, 0.25, 0.5)
const CLR_SELECTED := Color(0.85, 0.55, 0.15, 0.25)
const CLR_RED := Color(0.85, 0.25, 0.18, 0.9)
const CLR_GREEN := Color(0.3, 0.8, 0.35)
const FONT_TITLE := 28
const FONT_LIE := 22
const FONT_EVIDENCE := 17
const FONT_DIALOGUE := 20
const FONT_CONFIDENCE := 20
const FONT_OBJECTION := 72


func _ready() -> void:
	_confrontation_data = GameManager.case_data.get("confrontation", {})
	_max_confidence = int(_confrontation_data.get("confidence", 3))
	_confidence = _max_confidence
	_current_round_idx = 0
	_mistakes = 0
	_portrait_state = PortraitState.NORMAL
	_build_ui()
	_enter_state(State.INTRO)


# ─── UI 构建 ───
func _build_ui() -> void:
	# 全屏背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = CLR_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	# ── 上部：犯人立绘 ──
	_portrait_rect = TextureRect.new()
	_portrait_rect.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_portrait_rect.offset_top = 20
	_portrait_rect.offset_left = -200
	_portrait_rect.offset_right = 200
	_portrait_rect.offset_bottom = 420
	_portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_portrait_rect)
	_update_portrait()

	# ── 信心条（右上角） ──
	_confidence_label = Label.new()
	_confidence_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_confidence_label.offset_left = -220
	_confidence_label.offset_top = 20
	_confidence_label.offset_right = -20
	_confidence_label.offset_bottom = 50
	_confidence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_confidence_label.add_theme_font_size_override("font_size", FONT_CONFIDENCE)
	_confidence_label.add_theme_color_override("font_color", CLR_GOLD)
	_update_confidence_display()
	_panel.add_child(_confidence_label)

	# ── 谎言气泡（立绘下方） ──
	var lie_panel := PanelContainer.new()
	lie_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lie_panel.offset_left = 60
	lie_panel.offset_top = 430
	lie_panel.offset_right = -60
	lie_panel.offset_bottom = 530
	var lie_style := StyleBoxFlat.new()
	lie_style.bg_color = Color(0.08, 0.06, 0.04, 0.92)
	lie_style.border_color = Color(0.7, 0.35, 0.2, 0.8)
	lie_style.set_border_width_all(2)
	lie_style.set_corner_radius_all(8)
	lie_style.content_margin_left = 16
	lie_style.content_margin_right = 16
	lie_style.content_margin_top = 10
	lie_style.content_margin_bottom = 10
	lie_panel.add_theme_stylebox_override("panel", lie_style)
	_panel.add_child(lie_panel)

	_lie_label = RichTextLabel.new()
	_lie_label.bbcode_enabled = true
	_lie_label.fit_content = true
	_lie_label.scroll_active = false
	_lie_label.add_theme_font_size_override("normal_font_size", FONT_LIE)
	_lie_label.add_theme_color_override("default_color", Color(0.95, 0.82, 0.65))
	lie_panel.add_child(_lie_label)

	# ── 证据栏（下半屏） ──
	var evidence_panel := PanelContainer.new()
	evidence_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	evidence_panel.offset_top = -220
	var ev_style := StyleBoxFlat.new()
	ev_style.bg_color = Color(0.05, 0.035, 0.025, 0.95)
	ev_style.border_color = Color(0.5, 0.38, 0.18, 0.6)
	ev_style.set_border_width_all(1)
	ev_style.set_corner_radius_all(4)
	ev_style.content_margin_left = 16
	ev_style.content_margin_right = 16
	ev_style.content_margin_top = 10
	ev_style.content_margin_bottom = 10
	evidence_panel.add_theme_stylebox_override("panel", ev_style)
	_panel.add_child(evidence_panel)

	var ev_vbox := VBoxContainer.new()
	ev_vbox.add_theme_constant_override("separation", 4)
	evidence_panel.add_child(ev_vbox)

	var ev_title := Label.new()
	ev_title.text = "── 呈堂证据 ──"
	ev_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev_title.add_theme_font_size_override("font_size", 16)
	ev_title.add_theme_color_override("font_color", CLR_DIM)
	ev_vbox.add_child(ev_title)

	var ev_scroll := ScrollContainer.new()
	ev_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ev_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ev_vbox.add_child(ev_scroll)

	_evidence_container = VBoxContainer.new()
	_evidence_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_evidence_container.add_theme_constant_override("separation", 3)
	ev_scroll.add_child(_evidence_container)

	# ── 对话框（底部覆盖，默认隐藏） ──
	_dialogue_box = PanelContainer.new()
	_dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_box.offset_top = -200
	_dialogue_box.visible = false
	var dlg_style := StyleBoxFlat.new()
	dlg_style.bg_color = Color(0.07, 0.05, 0.035, 0.96)
	dlg_style.border_color = Color(0.6, 0.45, 0.25, 0.7)
	dlg_style.set_border_width_all(2)
	dlg_style.set_corner_radius_all(6)
	dlg_style.content_margin_left = 20
	dlg_style.content_margin_right = 20
	dlg_style.content_margin_top = 14
	dlg_style.content_margin_bottom = 14
	_dialogue_box.add_theme_stylebox_override("panel", dlg_style)
	_panel.add_child(_dialogue_box)

	var dlg_vbox := VBoxContainer.new()
	dlg_vbox.add_theme_constant_override("separation", 8)
	_dialogue_box.add_child(dlg_vbox)

	_dialogue_speaker = Label.new()
	_dialogue_speaker.add_theme_font_size_override("font_size", 18)
	_dialogue_speaker.add_theme_color_override("font_color", CLR_GOLD)
	dlg_vbox.add_child(_dialogue_speaker)

	_dialogue_text = RichTextLabel.new()
	_dialogue_text.bbcode_enabled = true
	_dialogue_text.fit_content = true
	_dialogue_text.scroll_active = false
	_dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_text.add_theme_font_size_override("normal_font_size", FONT_DIALOGUE)
	_dialogue_text.add_theme_color_override("default_color", Color(0.92, 0.88, 0.78))
	dlg_vbox.add_child(_dialogue_text)

	# ── 异议特效层（全屏覆盖，默认隐藏） ──
	_objection_layer = Control.new()
	_objection_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_objection_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objection_layer.visible = false
	add_child(_objection_layer)


# ─── 信心值显示 ───
func _update_confidence_display() -> void:
	var hearts := ""
	for i in range(_max_confidence):
		if i < _confidence:
			hearts += "❤ "
		else:
			hearts += "♡ "
	_confidence_label.text = "信心 " + hearts


# ─── 立绘 ───
func _update_portrait() -> void:
	var suspect_id: String = _confrontation_data.get("suspect", "")
	if suspect_id == "":
		return
	var npc_data: Dictionary = GameManager.get_npc_data(suspect_id)
	var base_portrait: String = npc_data.get("portrait", "")
	if base_portrait == "":
		return
	# 根据状态选立绘：正常用原版，动摇/崩溃用后缀
	var path := base_portrait
	match _portrait_state:
		PortraitState.SHAKEN:
			var alt := base_portrait.replace(".png", "_shaken.png")
			if ResourceLoader.exists(alt):
				path = alt
		PortraitState.COLLAPSED:
			var alt := base_portrait.replace(".png", "_collapsed.png")
			if ResourceLoader.exists(alt):
				path = alt
	if ResourceLoader.exists(path):
		_portrait_rect.texture = load(path)
	# 代码特效补充（即使没有专属立绘也能区分状态）
	_portrait_rect.rotation = 0.0
	_portrait_rect.modulate = Color(1, 1, 1, 1)
	match _portrait_state:
		PortraitState.SHAKEN:
			# 动摇：微黄绿色偏移，暗示不安
			_portrait_rect.modulate = Color(1.0, 0.95, 0.8, 1.0)
		PortraitState.COLLAPSED:
			# 崩溃：大幅倾斜 + 降透明度
			_portrait_rect.rotation = -0.08
			_portrait_rect.modulate = Color(0.7, 0.7, 0.7, 0.75)


# ─── 证据列表 ───
func _refresh_evidence_list() -> void:
	for c in _evidence_container.get_children():
		c.queue_free()
	if _state != State.PLAYER_CHOOSE:
		return
	for eid in GameManager.collected_evidence:
		var data: Dictionary = GameManager.evidence_data.get(eid, {})
		if data.is_empty():
			continue
		var is_sel: bool = (eid == _selected_evidence_id)

		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = CLR_SELECTED if is_sel else Color(0, 0, 0, 0)
		style.border_color = Color(0.85, 0.55, 0.15) if is_sel else CLR_BORDER
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(0, 38)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		row.add_child(hbox)

		var mark := Label.new()
		mark.text = "▶" if is_sel else "◇"
		mark.add_theme_font_size_override("font_size", FONT_EVIDENCE)
		mark.add_theme_color_override("font_color", CLR_GOLD if is_sel else CLR_DIM)
		mark.custom_minimum_size = Vector2(24, 0)
		hbox.add_child(mark)

		var name_lbl := Label.new()
		name_lbl.text = data.get("name", eid)
		name_lbl.add_theme_font_size_override("font_size", FONT_EVIDENCE)
		name_lbl.add_theme_color_override("font_color", CLR_GOLD if is_sel else Color(0.85, 0.82, 0.75))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		var desc_lbl := Label.new()
		var desc: String = data.get("description", "")
		desc_lbl.text = desc.substr(0, 28) + ("…" if desc.length() > 28 else "")
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", CLR_DIM)
		hbox.add_child(desc_lbl)

		var ev_id := eid
		row.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_evidence_clicked(ev_id)
		)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		_evidence_container.add_child(row)

	# 提交按钮
	if _selected_evidence_id != "":
		var submit_row := HBoxContainer.new()
		submit_row.alignment = BoxContainer.ALIGNMENT_CENTER
		submit_row.add_theme_constant_override("separation", 20)
		var submit_btn := Button.new()
		submit_btn.text = "⚡ 呈  堂  证  据"
		submit_btn.custom_minimum_size = Vector2(280, 48)
		submit_btn.add_theme_font_size_override("font_size", 22)
		submit_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
		submit_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.7))
		submit_btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.65, 0.2))
		submit_btn.pressed.connect(_on_submit_evidence)
		submit_row.add_child(submit_btn)
		_evidence_container.add_child(submit_row)


func _on_evidence_clicked(eid: String) -> void:
	if _state != State.PLAYER_CHOOSE:
		return
	_selected_evidence_id = eid
	_refresh_evidence_list()


func _on_submit_evidence() -> void:
	if _state != State.PLAYER_CHOOSE or _selected_evidence_id == "":
		return
	_judge_evidence(_selected_evidence_id)


# ─── 状态机 ───
func _enter_state(new_state: int) -> void:
	_state = new_state
	match _state:
		State.INTRO:
			_show_intro()
		State.LIE_PRESENTED:
			_show_lie()
		State.PLAYER_CHOOSE:
			_selected_evidence_id = ""
			_refresh_evidence_list()
		State.BREAK_ANIM:
			_play_break_anim()
		State.FAIL_ANIM:
			_play_fail_anim()
		State.VICTORY:
			_play_victory()
		State.DEFEAT:
			_play_defeat()


# ─── 开场 ───
func _show_intro() -> void:
	var intro: Array = _confrontation_data.get("intro_dialogue", [])
	if intro.is_empty():
		_enter_state(State.LIE_PRESENTED)
		return
	_dialogue_queue = intro
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _enter_state(State.LIE_PRESENTED))


# ─── 展示谎言 ───
func _show_lie() -> void:
	var rounds: Array = _confrontation_data.get("rounds", [])
	if _current_round_idx >= rounds.size():
		_enter_state(State.VICTORY)
		return
	var round_data: Dictionary = rounds[_current_round_idx]
	_lie_label.text = "[b]「" + round_data.get("lie", "") + "」[/b]"
	_lie_label.get_parent().visible = true
	_dialogue_box.visible = false
	# 短暂展示谎言后进入选择
	await get_tree().create_timer(1.2).timeout
	_enter_state(State.PLAYER_CHOOSE)


# ─── 判断证据 ───
func _judge_evidence(eid: String) -> void:
	var rounds: Array = _confrontation_data.get("rounds", [])
	var round_data: Dictionary = rounds[_current_round_idx]
	var counter: String = round_data.get("counter_evidence", "")
	var alt: Array = round_data.get("alt_evidence", [])
	if eid == counter or alt.has(eid):
		_enter_state(State.BREAK_ANIM)
	else:
		_enter_state(State.FAIL_ANIM)


# ─── 击破动画 ───
func _play_break_anim() -> void:
	_evidence_container.get_parent().get_parent().visible = false
	_lie_label.get_parent().visible = false

	# 播放异议特效
	await _play_objection_fx()

	# 立绘切换为动摇
	_portrait_state = PortraitState.SHAKEN
	_update_portrait()
	_shake_portrait()

	# 播放击破对话
	var rounds: Array = _confrontation_data.get("rounds", [])
	var round_data: Dictionary = rounds[_current_round_idx]
	var break_dlg: Array = round_data.get("break_dialogue", [])
	_dialogue_queue = break_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func():
		_current_round_idx += 1
		# 检查是否还有下一轮
		var remaining_rounds: Array = _confrontation_data.get("rounds", [])
		if _current_round_idx >= remaining_rounds.size():
			_enter_state(State.VICTORY)
		else:
			_enter_state(State.LIE_PRESENTED)
	)


# ─── 失败动画 ───
func _play_fail_anim() -> void:
	_mistakes += 1
	_confidence = max(0, _confidence - 1)
	_update_confidence_display()
	_evidence_container.get_parent().get_parent().visible = false

	# 闪红
	await _play_red_flash()

	# 播放失败对话
	var rounds: Array = _confrontation_data.get("rounds", [])
	var round_data: Dictionary = rounds[_current_round_idx]
	var fail_dlg: Array = round_data.get("fail_dialogue", [])
	_dialogue_queue = fail_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func():
		if _confidence <= 0:
			_enter_state(State.DEFEAT)
		else:
			_enter_state(State.LIE_PRESENTED)
	)


# ─── 胜利 ───
func _play_victory() -> void:
	_portrait_state = PortraitState.COLLAPSED
	_update_portrait()

	var victory_dlg: Array = _confrontation_data.get("victory_dialogue", [])
	_dialogue_queue = victory_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func():
		confrontation_finished.emit("victory", _mistakes)
	)


# ─── 失败 ───
func _play_defeat() -> void:
	var defeat_dlg: Array = _confrontation_data.get("defeat_dialogue", [])
	_dialogue_queue = defeat_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func():
		confrontation_finished.emit("defeat", _mistakes)
	)


# ─── 对话播放队列 ───
func _show_dialogue_queue(on_done: Callable) -> void:
	_is_playing_dialogue = true
	_show_next_dialogue_line(on_done)


func _show_next_dialogue_line(on_done: Callable) -> void:
	if _dialogue_idx >= _dialogue_queue.size():
		_dialogue_box.visible = false
		_is_playing_dialogue = false
		on_done.call()
		return
	var line = _dialogue_queue[_dialogue_idx]
	var speaker: String = ""
	var text: String = ""
	if line is Dictionary:
		speaker = str(line.get("speaker", ""))
		text = str(line.get("text", ""))
	else:
		text = str(line)

	_dialogue_speaker.text = speaker
	_dialogue_text.text = text
	_dialogue_box.visible = true

	# 点击继续
	_set_waiting_for_click(func():
		_dialogue_idx += 1
		_show_next_dialogue_line(on_done)
	)


var _click_callback: Callable = Callable()

func _set_waiting_for_click(cb: Callable) -> void:
	_click_callback = cb


func _input(event: InputEvent) -> void:
	if _click_callback.is_valid() and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cb := _click_callback
		_click_callback = Callable()
		cb.call()
	elif _click_callback.is_valid() and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		var cb := _click_callback
		_click_callback = Callable()
		cb.call()


# ─── 特效：异议！ ───
func _play_objection_fx() -> void:
	_objection_layer.visible = true
	_objection_layer.mouse_filter = Control.MOUSE_FILTER_STOP

	# 全屏闪白
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objection_layer.add_child(flash)

	# 异议文字
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objection_layer.add_child(center)

	var label := Label.new()
	label.text = "异  议！"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_OBJECTION)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 6)
	label.scale = Vector2(0.3, 0.3)
	label.modulate.a = 0.0
	center.add_child(label)

	# 动画
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "color:a", 0.9, 0.06)
	tw.tween_property(label, "modulate:a", 1.0, 0.06)
	tw.tween_property(label, "scale", Vector2(1.15, 1.15), 0.12)
	tw.chain()
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08)
	tw.tween_interval(0.6)
	tw.set_parallel(true)
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_property(label, "modulate:a", 0.0, 0.3)
	tw.chain()
	tw.tween_callback(func():
		_objection_layer.visible = false
		_objection_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for c in _objection_layer.get_children():
			c.queue_free()
	)
	await tw.finished


# ─── 特效：闪红（失败） ───
func _play_red_flash() -> void:
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.8, 0.1, 0.05, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	move_child(flash, get_child_count() - 1)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.4, 0.08)
	tw.tween_property(flash, "color:a", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)
	await tw.finished


# ─── 特效：立绘抖动 ───
func _shake_portrait() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	var orig_pos := _portrait_rect.position
	for i in range(6):
		var offset_x := 8.0 if i % 2 == 0 else -8.0
		_shake_tween.tween_property(_portrait_rect, "position:x", orig_pos.x + offset_x, 0.04)
	_shake_tween.tween_property(_portrait_rect, "position:x", orig_pos.x, 0.06)
