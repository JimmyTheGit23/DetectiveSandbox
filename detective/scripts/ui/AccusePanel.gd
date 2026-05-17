extends Control
## 公堂指证面板：分步仪式感 UI。
##
## 步骤：① 选嫌疑人 → ② 选动机 → ③ 选手法 → ④ 选证据 → ⑤ 最终确认
## 未解锁的选项显示为「?? 调查后解锁」，不可点击。

signal close_requested()
signal accuse_submitted(suspect: String, motive: String, method: String, evidence: Array)

@onready var panel: Control = $Panel

# ─── 状态 ───
enum Step { SUSPECT, MOTIVE, METHOD, EVIDENCE, CONFIRM }
var _step: int = Step.SUSPECT
var _selected_suspect: String = ""
var _selected_motive: String = ""
var _selected_method: String = ""
var _selected_evidence: Array = []

# ─── 风格常量 ───
const CLR_GOLD := Color(0.96, 0.88, 0.65)
const CLR_DIM := Color(0.55, 0.50, 0.42, 0.6)
const CLR_LOCKED := Color(0.45, 0.42, 0.38, 0.4)
const CLR_BG_CARD := Color(0.12, 0.10, 0.08, 0.92)
const CLR_BORDER := Color(0.6, 0.45, 0.25, 0.5)
const CLR_SELECTED := Color(0.85, 0.55, 0.15, 0.25)
const CLR_HOVER := Color(0.7, 0.55, 0.3, 0.12)
const FONT_TITLE := 30
const FONT_STEP := 18
const FONT_ITEM := 18
const FONT_HINT := 14
const FONT_CONFIRM := 22
const STEP_TITLES := ["── 第一步 · 指认嫌疑人 ──", "── 第二步 · 指明动机 ──", "── 第三步 · 指出手法 ──", "── 第四步 · 呈堂证据 ──", "── 最终确认 · 提交指证 ──"]
const STEP_DESCS := [
	"「大人，您认为此案真凶是谁？」",
	"「大人认为凶手所为何故？」",
	"「死者是如何遇害的？」",
	"「请呈上能证明您判断的证物。」",
	"请确认您的指证。一旦提交，公堂即刻开审。"
]


func _ready() -> void:
	_build_step()


# ─── 核心构建 ───
func _build_step() -> void:
	# 清空旧内容
	for c in panel.get_children():
		c.queue_free()

	# 背景暗幕 + 竹简边框
	var bg := _make_bg()
	panel.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 60; vbox.offset_top = 40; vbox.offset_right = -60; vbox.offset_bottom = -30
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# 大标题
	var title := Label.new()
	title.text = "── 公  堂  指  证 ──"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_TITLE)
	title.add_theme_color_override("font_color", CLR_GOLD)
	vbox.add_child(title)

	# 步骤进度条
	vbox.add_child(_make_progress_bar())

	# 分割
	vbox.add_child(_make_sep())

	# 步骤标题 + 描述
	var step_title := Label.new()
	step_title.text = STEP_TITLES[_step]
	step_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_title.add_theme_font_size_override("font_size", FONT_STEP + 2)
	step_title.add_theme_color_override("font_color", CLR_GOLD)
	vbox.add_child(step_title)

	var step_desc := Label.new()
	step_desc.text = STEP_DESCS[_step]
	step_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_desc.add_theme_font_size_override("font_size", FONT_HINT + 1)
	step_desc.add_theme_color_override("font_color", CLR_DIM)
	vbox.add_child(step_desc)

	vbox.add_child(_make_sep())

	# 内容区（可滚动）
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)

	match _step:
		Step.SUSPECT:
			_build_radio_list(content, GameManager.case_data.get("suspects", []), _selected_suspect, _on_suspect_picked)
		Step.MOTIVE:
			_build_radio_list(content, GameManager.case_data.get("motives", []), _selected_motive, _on_motive_picked)
		Step.METHOD:
			_build_radio_list(content, GameManager.case_data.get("methods", []), _selected_method, _on_method_picked)
		Step.EVIDENCE:
			_build_evidence_list(content)
		Step.CONFIRM:
			_build_confirm(content)

	# 底部按钮区
	vbox.add_child(_make_sep())
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_row)

	if _step > Step.SUSPECT:
		var back_btn := _make_btn("◁  上一步", func(): _step -= 1; _build_step())
		btn_row.add_child(back_btn)

	if _step < Step.CONFIRM:
		var next_btn := _make_btn("下一步  ▷", func(): _try_next_step())
		btn_row.add_child(next_btn)
	elif _step == Step.CONFIRM:
		var submit_btn := _make_btn("┃ 提  交  指  证 ┃", func(): _on_submit())
		submit_btn.add_theme_font_size_override("font_size", FONT_CONFIRM)
		submit_btn.custom_minimum_size = Vector2(320, 54)
		btn_row.add_child(submit_btn)

	var close_btn := _make_btn("关  闭", func(): close_requested.emit())
	btn_row.add_child(close_btn)


# ─── 单选列表（嫌疑人/动机/手法通用） ───
func _build_radio_list(parent: VBoxContainer, items: Array, current_sel: String, on_pick: Callable) -> void:
	for item in items:
		if not item is Dictionary:
			continue
		var id: String = item.get("id", "")
		var display_name: String = item.get("name", "")
		var unlocked: bool = _check_unlock(item)

		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = CLR_SELECTED if (id == current_sel and unlocked) else Color(0, 0, 0, 0)
		style.border_color = CLR_BORDER if unlocked else CLR_LOCKED
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(10)
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(0, 44)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		row.add_child(hbox)

		if unlocked:
			# 选中标记
			var mark := Label.new()
			mark.text = "◉" if id == current_sel else "○"
			mark.add_theme_font_size_override("font_size", FONT_ITEM + 2)
			mark.add_theme_color_override("font_color", CLR_GOLD if id == current_sel else CLR_DIM)
			mark.custom_minimum_size = Vector2(28, 0)
			hbox.add_child(mark)

			var lbl := Label.new()
			lbl.text = display_name
			lbl.add_theme_font_size_override("font_size", FONT_ITEM)
			lbl.add_theme_color_override("font_color", CLR_GOLD)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(lbl)

			# 点击
			row.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					on_pick.call(id)
			)
			row.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			# 锁定：只显示锁+问号，不给任何方向提示
			var lock := Label.new()
			lock.text = "🔒"
			lock.add_theme_font_size_override("font_size", FONT_ITEM)
			lock.custom_minimum_size = Vector2(28, 0)
			hbox.add_child(lock)

			var lbl := Label.new()
			lbl.text = "尚未查明"
			lbl.add_theme_font_size_override("font_size", FONT_ITEM)
			lbl.add_theme_color_override("font_color", CLR_LOCKED)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(lbl)

			row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		parent.add_child(row)


# ─── 证据列表（多选） ───
func _build_evidence_list(parent: VBoxContainer) -> void:
	if GameManager.collected_evidence.is_empty():
		var empty := Label.new()
		empty.text = "尚未收集到任何证据。请先调查现场。"
		empty.add_theme_font_size_override("font_size", FONT_ITEM)
		empty.add_theme_color_override("font_color", CLR_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		parent.add_child(empty)
		return

	var count_label := Label.new()
	count_label.text = "已选 %d 件（至少需要 %d 件）" % [_selected_evidence.size(), GameManager.case_data.get("min_evidence_required", 1)]
	count_label.add_theme_font_size_override("font_size", FONT_HINT)
	count_label.add_theme_color_override("font_color", CLR_DIM)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(count_label)

	for eid in GameManager.collected_evidence:
		var data: Dictionary = GameManager.evidence_data.get(eid, {})
		var is_sel: bool = _selected_evidence.has(eid)

		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = CLR_SELECTED if is_sel else Color(0, 0, 0, 0)
		style.border_color = CLR_BORDER
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(0, 40)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row.add_child(hbox)

		var mark := Label.new()
		mark.text = "☑" if is_sel else "☐"
		mark.add_theme_font_size_override("font_size", FONT_ITEM + 2)
		mark.add_theme_color_override("font_color", CLR_GOLD if is_sel else CLR_DIM)
		mark.custom_minimum_size = Vector2(28, 0)
		hbox.add_child(mark)

		var lbl := Label.new()
		lbl.text = data.get("name", eid)
		lbl.add_theme_font_size_override("font_size", FONT_ITEM)
		lbl.add_theme_color_override("font_color", CLR_GOLD if is_sel else Color(0.85, 0.82, 0.75))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		# 显示证据简述
		var desc_text: String = data.get("description", "")
		if desc_text != "":
			var desc := Label.new()
			desc.text = desc_text.substr(0, 30) + ("…" if desc_text.length() > 30 else "")
			desc.add_theme_font_size_override("font_size", FONT_HINT)
			desc.add_theme_color_override("font_color", CLR_DIM)
			hbox.add_child(desc)

		var ev_id := eid
		row.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_toggle_evidence(ev_id)
		)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		parent.add_child(row)


# ─── 最终确认 ───
func _build_confirm(parent: VBoxContainer) -> void:
	var items: Array[Dictionary] = [
		_make_confirm_row("嫌疑人", _get_name("suspects", _selected_suspect)),
		_make_confirm_row("动  机", _get_name("motives", _selected_motive)),
		_make_confirm_row("手  法", _get_name("methods", _selected_method)),
	]
	for d in items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var key := Label.new()
		key.text = d["key"]
		key.add_theme_font_size_override("font_size", FONT_ITEM + 2)
		key.add_theme_color_override("font_color", CLR_DIM)
		key.custom_minimum_size = Vector2(100, 0)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(key)

		var val := Label.new()
		val.text = d["value"]
		val.add_theme_font_size_override("font_size", FONT_ITEM + 2)
		val.add_theme_color_override("font_color", CLR_GOLD)
		row.add_child(val)

		parent.add_child(row)

	# 证据列表
	var ev_row := HBoxContainer.new()
	ev_row.add_theme_constant_override("separation", 20)
	ev_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ev_key := Label.new()
	ev_key.text = "证  据"
	ev_key.add_theme_font_size_override("font_size", FONT_ITEM + 2)
	ev_key.add_theme_color_override("font_color", CLR_DIM)
	ev_key.custom_minimum_size = Vector2(100, 0)
	ev_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ev_row.add_child(ev_key)

	var ev_names: PackedStringArray = []
	for eid in _selected_evidence:
		var d: Dictionary = GameManager.evidence_data.get(eid, {})
		ev_names.append(d.get("name", eid))
	var ev_val := Label.new()
	ev_val.text = "、".join(ev_names) if ev_names.size() > 0 else "（无）"
	ev_val.add_theme_font_size_override("font_size", FONT_ITEM)
	ev_val.add_theme_color_override("font_color", CLR_GOLD)
	ev_val.autowrap_mode = TextServer.AUTOWRAP_WORD
	ev_val.custom_minimum_size = Vector2(500, 0)
	ev_row.add_child(ev_val)
	parent.add_child(ev_row)

	parent.add_child(_make_sep())

	var warn := Label.new()
	warn.text = "一旦提交，公堂即刻开审，无法撤回。"
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.add_theme_font_size_override("font_size", FONT_HINT + 1)
	warn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3, 0.8))
	parent.add_child(warn)


# ─── 解锁检查 ───
func _check_unlock(item: Dictionary) -> bool:
	var conds: Array = item.get("unlock", [])
	if conds.is_empty():
		return true
	for c in conds:
		if c is Dictionary:
			if not GameManager.evaluate_condition(c):
				return false
	return true


# ─── 回调 ───
func _on_suspect_picked(id: String) -> void:
	_selected_suspect = id
	_build_step()

func _on_motive_picked(id: String) -> void:
	_selected_motive = id
	_build_step()

func _on_method_picked(id: String) -> void:
	_selected_method = id
	_build_step()

func _toggle_evidence(eid: String) -> void:
	if _selected_evidence.has(eid):
		_selected_evidence.erase(eid)
	else:
		_selected_evidence.append(eid)
	_build_step()


func _try_next_step() -> void:
	match _step:
		Step.SUSPECT:
			if _selected_suspect == "":
				_flash_msg("请先选择一名嫌疑人。")
				return
		Step.MOTIVE:
			if _selected_motive == "":
				_flash_msg("请先选择一项动机。")
				return
		Step.METHOD:
			if _selected_method == "":
				_flash_msg("请先选择一种手法。")
				return
		Step.EVIDENCE:
			var min_req: int = int(GameManager.case_data.get("min_evidence_required", 1))
			if _selected_evidence.size() < min_req:
				_flash_msg("至少需要选择 %d 件证据。" % min_req)
				return
	_step += 1
	_build_step()


func _on_submit() -> void:
	accuse_submitted.emit(_selected_suspect, _selected_motive, _selected_method, _selected_evidence)


func _flash_msg(msg: String) -> void:
	# 在面板顶部短暂显示提示
	var lbl := Label.new()
	lbl.text = msg
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", FONT_ITEM)
	lbl.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl.offset_top = 8; lbl.offset_bottom = 36
	panel.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tw.tween_callback(lbl.queue_free)


# ─── UI 辅助 ───
func _make_bg() -> Control:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = CLR_BG_CARD
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg

func _make_sep() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", CLR_BORDER)
	return sep

func _make_btn(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(160, 42)
	btn.add_theme_font_size_override("font_size", FONT_ITEM)
	btn.pressed.connect(callback)
	return btn

func _make_progress_bar() -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	var labels := ["嫌疑人", "动机", "手法", "证据", "确认"]
	for i in range(labels.size()):
		if i > 0:
			var arrow := Label.new()
			arrow.text = "→"
			arrow.add_theme_font_size_override("font_size", FONT_HINT)
			arrow.add_theme_color_override("font_color", CLR_DIM)
			hbox.add_child(arrow)
		var lbl := Label.new()
		lbl.text = labels[i]
		lbl.add_theme_font_size_override("font_size", FONT_HINT + 1)
		if i < _step:
			lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))  # 已完成：绿
		elif i == _step:
			lbl.add_theme_color_override("font_color", CLR_GOLD)  # 当前：金
		else:
			lbl.add_theme_color_override("font_color", CLR_DIM)  # 未来：暗
		hbox.add_child(lbl)
	return hbox

func _make_confirm_row(key_text: String, value_text: String) -> Dictionary:
	return { "key": key_text, "value": value_text }

func _get_name(category: String, id: String) -> String:
	for item in GameManager.case_data.get(category, []):
		if item is Dictionary and item.get("id", "") == id:
			return item.get("name", id)
	return id
