extends Control
## 指证面板：选嫌疑人 / 动机 / 手法 / 证据 → 提交

signal close_requested()
signal accuse_submitted(suspect: String, motive: String, method: String, evidence: Array)

@onready var suspects_vbox: VBoxContainer = $Panel/HBox/Suspects/List
@onready var motives_vbox: VBoxContainer = $Panel/HBox/Motives/List
@onready var methods_vbox: VBoxContainer = $Panel/HBox/Methods/List
@onready var evidence_vbox: VBoxContainer = $Panel/HBox/Evidence/List
@onready var submit_btn: Button = $Panel/SubmitBtn
@onready var close_btn: Button = $Panel/CloseBtn

var _selected_suspect: String = ""
var _selected_motive: String = ""
var _selected_method: String = ""
var _selected_evidence: Array = []
var _suspect_btns: Dictionary = {}
var _motive_btns: Dictionary = {}
var _method_btns: Dictionary = {}


func _ready() -> void:
	close_btn.pressed.connect(func(): close_requested.emit())
	submit_btn.pressed.connect(_on_submit)
	_build()


func _build() -> void:
	var case_data: Dictionary = GameManager.case_data
	for s in case_data.get("suspects", []):
		_add_radio(suspects_vbox, s, _suspect_btns, func(id): _selected_suspect = id; _refresh_btn_states(_suspect_btns, id))
	for m in case_data.get("motives", []):
		_add_radio(motives_vbox, m, _motive_btns, func(id): _selected_motive = id; _refresh_btn_states(_motive_btns, id))
	for m in case_data.get("methods", []):
		_add_radio(methods_vbox, m, _method_btns, func(id): _selected_method = id; _refresh_btn_states(_method_btns, id))
	# 证据：只显示已收集的"实物证据"（type=evidence）
	for eid in GameManager.collected_evidence:
		var data = GameManager.evidence_data.get(eid, {})
		var cb := CheckBox.new()
		cb.text = data.get("name", eid)
		cb.add_theme_font_size_override("font_size", 16)
		cb.toggled.connect(func(p): _on_ev_toggled(eid, p))
		evidence_vbox.add_child(cb)


func _add_radio(parent: VBoxContainer, item: Dictionary, store: Dictionary, on_click: Callable) -> void:
	var btn := Button.new()
	btn.text = item.get("name", "")
	btn.toggle_mode = true
	btn.add_theme_font_size_override("font_size", 16)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 36)
	var id: String = item.get("id", "")
	store[id] = btn
	btn.pressed.connect(func(): on_click.call(id))
	parent.add_child(btn)


func _refresh_btn_states(store: Dictionary, selected_id: String) -> void:
	for id in store.keys():
		(store[id] as Button).button_pressed = (id == selected_id)


func _on_ev_toggled(eid: String, pressed: bool) -> void:
	if pressed and not _selected_evidence.has(eid):
		_selected_evidence.append(eid)
	elif not pressed and _selected_evidence.has(eid):
		_selected_evidence.erase(eid)


func _on_submit() -> void:
	if _selected_suspect == "" or _selected_motive == "" or _selected_method == "":
		_flash("请选择嫌疑人、动机、手法。")
		return
	if _selected_evidence.size() < 1:
		_flash("至少勾选一项证据。")
		return
	accuse_submitted.emit(_selected_suspect, _selected_motive, _selected_method, _selected_evidence)


func _flash(msg: String) -> void:
	submit_btn.text = msg
	await get_tree().create_timer(1.5).timeout
	submit_btn.text = "提  交  指  证"
