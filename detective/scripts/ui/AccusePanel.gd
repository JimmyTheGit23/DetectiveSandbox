extends Control
## 公堂指证面板：选嫌疑人 → 进入对峙。
##
## 简化版：只需选择嫌疑人，确认后进入 ConfrontationPanel。
## 如果案件没有 confrontation 数据，回退到旧的五步流程。

signal close_requested()
signal accuse_submitted(suspect: String, motive: String, method: String, evidence: Array)
signal confrontation_requested(suspect: String)

@onready var panel: Control = $Panel

# ─── 状态 ───
enum Step { SUSPECT, CONFIRM }
var _step: int = Step.SUSPECT
var _selected_suspect: String = ""
# 旧流程备用
var _selected_motive: String = ""
var _selected_method: String = ""
var _selected_evidence: Array = []
var _use_confrontation: bool = false

# ─── 风格常量 ───
const CLR_GOLD := Color(0.96, 0.88, 0.65)
const CLR_DIM := Color(0.55, 0.50, 0.42, 0.6)
const CLR_LOCKED := Color(0.45, 0.42, 0.38, 0.4)
const CLR_BG_CARD := Color(0.12, 0.10, 0.08, 0.92)
const CLR_BORDER := Color(0.6, 0.45, 0.25, 0.5)
const CLR_SELECTED := Color(0.85, 0.55, 0.15, 0.25)
const FONT_TITLE := 30
const FONT_STEP := 18
const FONT_ITEM := 18
const FONT_HINT := 14
const FONT_CONFIRM := 22
const STEP_TITLES_NEW := ["── 指认嫌疑人 ──", "── 确认指证 ──"]
const STEP_DESCS_NEW := [
	"「大人，您认为此案真凶是谁？」",
	"确认后将对嫌疑人展开对峙，无法撤回。"
]
const STEP_TITLES_OLD := ["── 第一步 · 指认嫌疑人 ──", "── 第二步 · 指明动机 ──", "── 第三步 · 指出手法 ──", "── 第四步 · 呈堂证据 ──", "── 最终确认 · 提交指证 ──"]
const STEP_DESCS_OLD := [
	"「大人，您认为此案真凶是谁？」",
	"「大人认为凶手所为何故？」",
	"「死者是如何遇害的？」",
	"「请呈上能证明您判断的证物。」",
	"请确认您的指证。一旦提交，公堂即刻开审。"
]


func _ready() -> void:
	_use_confrontation = not GameManager.case_data.get("confrontation", {}).is_empty()
	_build_step()


# ─── 核心构建 ───
func _build_step() -> void:
	for c in panel.get_children():
		c.queue_free()

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
	vbox.add_child(_make_sep())

	if _use_confrontation:
		_build_confrontation_flow(vbox)
	else:
		_build_legacy_flow(vbox)


# ─── 对峙模式流程 ───
func _build_confrontation_flow(vbox: VBoxContainer) -> void:
	# 步骤标题 + 描述
	var step_title := Label.new()
	step_title.text = STEP_TITLES_NEW[_step]
	step_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_title.add_theme_font_size_override("font_size", FONT_STEP + 2)
	step_title.add_theme_color_override("font_color", CLR_GOLD)
	vbox.add_child(step_title)

	var step_desc := Label.new()
	step_desc.text = STEP_DESCS_NEW[_step]
	step_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_desc.add_theme_font_size_override("font_size", FONT_HINT + 1)
	step_desc.add_theme_color_override("font_color", CLR_DIM)
	vbox.add_child(step_desc)

	vbox.add_child(_make_sep())

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
		Step.CONFIRM:
			_build_confirm_new(content)

	# 底部按钮
	vbox.add_child(_make_sep())
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_row)

	if _step > Step.SUSPECT:
		btn_row.add_child(_make_btn("◁  上一步", func(): _step -= 1; _build_step()))

	if _step < Step.CONFIRM:
		btn_row.add_child(_make_btn("下一步  ▷", func(): _try_next_step_new()))
	else:
		var submit_btn := _make_btn("┃ 开  始  对  峙 ┃", func(): _on_submit_confrontation())
		submit_btn.add_theme_font_size_override("font_size", FONT_CONFIRM)
		submit_btn.custom_minimum_size = Vector2(320, 54)
		btn_row.add_child(submit_btn)

	btn_row.add_child(_make_btn("关  闭", func(): close_requested.emit()))


func _build_confirm_new(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var key := Label.new()
	key.text = "嫌疑人"
	key.add_theme_font_size_override("font_size", FONT_ITEM + 2)
	key.add_theme_color_override("font_color", CLR_DIM)
	key.custom_minimum_size = Vector2(100, 0)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(key)
	var val := Label.new()
	val.text = _get_name("suspects", _selected_suspect)
	val.add_theme_font_size_override("font_size", FONT_ITEM + 2)
	val.add_theme_color_override("font_color", CLR_GOLD)
	row.add_child(val)
	parent.add_child(row)

	parent.add_child(_make_sep())

	var warn := Label.new()
	warn.text = "对峙一旦开始，无法中途退出。证据将在对峙中呈堂。"
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.add_theme_font_size_override("font_size", FONT_HINT + 1)
	warn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3, 0.8))
	parent.add_child(warn)


func _try_next_step_new() -> void:
	if _step == Step.SUSPECT:
		if _selected_suspect == "":
			_flash_msg("请先选择一名嫌疑人。")
			return
	_step += 1
	_build_step()


func _on_submit_confrontation() -> void:
	confrontation_requested.emit(_selected_suspect)


# ─── 旧流程（无 confrontation 数据时回退） ───
func _build_legacy_flow(vbox: VBoxContainer) -> void:
	var step_titles := STEP_TITLES_OLD
	var step_descs := STEP_DESCS_OLD

	var step_title := Label.new()
	step_title.text = step_titles[_step]
	step_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_title.add_theme_font_size_override("font_size", FONT_STEP + 2)
	step_title.add_theme_color_override("font_color", CLR_GOLD)
	vbox.add_child(step_title)

	var step_desc := Label.new()
	step_desc.text = step_descs[_step]
	step_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_desc.add_theme_font_size_override("font_size", FONT_HINT + 1)
	step_desc.add_theme_color_override("font_color", CLR_DIM)
	vbox.add_child(step_desc)

	vbox.add_child(_make_sep())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)

	# 旧流程用扩展 enum 值
	var old_step := _step
	# 为了兼容旧的 Step.SUSPECT=0 到 Step.CONFIRM=4，映射一下
	var legacy_step := old_step  # 0=SUSPECT, 1=MOTIVE, 2=METHOD, 3=EVIDENCE, 4=CONFIRM
	match legacy_step:
		0:
			_build_radio_list(content, GameManager.case_data.get("suspects", []), _selected_suspect, _on_suspect_picked)
		1:
			_build_radio_list(content, GameManager.case_data.get("motives", []), _selected_motive, _on_motive_picked)
		2:
			_build_radio_list(content, GameManager.case_data.get("methods", []), _selected_method, _on_method_picked)
		3:
			_build_evidence_list(content)
		4:
			_build_confirm_old(content)

	vbox.add_child(_make_sep())
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_row)

	if _step > 0:
		btn_row.add_child(_make_btn("◁  上一步", func(): _step -= 1; _build_step()))

	if _step < 4:
		btn_row.add_child(_make_btn("下一步  ▷", func(): _try_next_step_old()))
	elif _step == 4:
		var submit_btn := _make_btn("┃ 提  交  指  证 ┃", func(): _on_submit_old())
		submit_btn.add_theme_font_size_override("font_size", FONT_CONFIRM)
		submit_btn.custom_minimum_size = Vector2(320, 54)
		btn_row.add_child(submit_btn)

	btn_row.add_child(_make_btn("关  闭", func(): close_requested.emit()))


func _try_next_step_old() -> void:
	match _step:
		0:
			if _selected_suspect == "":
				_flash_msg("请先选择一名嫌疑人。")
				return
		1:
			if _selected_motive == "":
				_flash_msg("请先选择一项动机。")
				return
		2:
			if _selected_method == "":
				_flash_msg("请先选择一种手法。")
				return
		3:
			var min_req: int = int(GameManager.case_data.get("min_evidence_required", 1))
			if _selected_evidence.size() < min_req:
				_flash_msg("至少需要选择 %d 件证据。" % min_req)
				return
	_step += 1
	_build_step()


func _on_submit_old() -> void:
	accuse_submitted.emit(_selected_suspect, _selected_motive, _selected_method, _selected_evidence)


func _build_confirm_old(parent: VBoxContainer) -> void:
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


# ─── 证据列表（多选，旧流程用） ───
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


# ─── 单选列表（通用） ───
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

			row.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					on_pick.call(id)
			)
			row.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
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


func _flash_msg(msg: String) -> void:
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
	var labels: Array
	if _use_confrontation:
		labels = ["嫌疑人", "对峙"]
	else:
		labels = ["嫌疑人", "动机", "手法", "证据", "确认"]
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
			lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		elif i == _step:
			lbl.add_theme_color_override("font_color", CLR_GOLD)
		else:
			lbl.add_theme_color_override("font_color", CLR_DIM)
		hbox.add_child(lbl)
	return hbox

func _make_confirm_row(key_text: String, value_text: String) -> Dictionary:
	return { "key": key_text, "value": value_text }

func _get_name(category: String, id: String) -> String:
	for item in GameManager.case_data.get(category, []):
		if item is Dictionary and item.get("id", "") == id:
			return item.get("name", id)
	return id
