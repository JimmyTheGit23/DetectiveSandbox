extends Control
## 探索面板：列出当前地点所有可探索点，点击消耗时间获得线索/证据

signal close_requested()

@onready var title_label: Label = $Panel/VBox/Title
@onready var list_vbox: VBoxContainer = $Panel/VBox/List
@onready var result_box: RichTextLabel = $Panel/VBox/ResultBox
@onready var close_btn: Button = $Panel/VBox/CloseBtn


func _ready() -> void:
	close_btn.pressed.connect(func(): close_requested.emit())
	title_label.text = "── 可疑之处 ──"
	result_box.text = "[i]点击下方按钮以探索该处。每次探索消耗时段。[/i]"
	_build_list()


func _build_list() -> void:
	for child in list_vbox.get_children():
		child.queue_free()
	var loc := GameManager.current_location_data()
	var loc_id: String = GameManager.current_location
	for sp in loc.get("search_points", []):
		var pid: String = sp.get("id", "")
		var pname: String = sp.get("name", pid)
		var cost: int = int(sp.get("time_cost", 1))
		var key := "%s.%s" % [loc_id, pid]
		var done: int = GameManager.search_history.get(key, 0)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var done_mark := "  ✓" if done > 0 else ""
		btn.text = "  %s    [耗时 %d 段]%s" % [pname, cost, done_mark]
		btn.pressed.connect(_on_search.bind(pid))
		list_vbox.add_child(btn)


func _on_search(point_id: String) -> void:
	var result := GameManager.resolve_search(GameManager.current_location, point_id)
	# 推进时间
	var cost: int = int(result.get("time_cost", 1))
	GameManager.advance_period(cost)
	# 显示结果
	var txt: String = "[i]" + result.get("narration", "") + "[/i]"
	if result.get("gained_evidence", "") != "":
		var ev = GameManager.evidence_data.get(result.gained_evidence, {})
		txt += "\n\n[color=#fcc]【获得证据：%s】[/color]" % ev.get("name", "")
	if result.get("gained_clue", "") != "":
		var cl = GameManager.evidence_data.get(result.gained_clue, {})
		txt += "\n\n[color=#fce]【获得线索：%s】[/color]" % cl.get("name", "")
	result_box.text = txt
	_build_list()
	# 触发对话（用于"在某处遇见 NPC"剧情事件）
	var trigger_npc: String = result.get("trigger_dialogue", "")
	if trigger_npc != "":
		var start_node: String = result.get("trigger_dialogue_start", "")
		# 关闭探索面板，进入对话
		close_requested.emit()
		await get_tree().process_frame
		if start_node != "":
			DialogueManager.start_dialogue_at(trigger_npc, start_node)
		else:
			DialogueManager.start_dialogue(trigger_npc)
