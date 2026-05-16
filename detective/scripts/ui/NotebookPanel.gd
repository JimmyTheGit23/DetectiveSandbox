extends Control
## 笔记本面板：证据 / 线索 / 人物 三个 Tab

signal close_requested()

@onready var tab_container: TabContainer = $Panel/Tabs
@onready var close_btn: Button = $Panel/CloseBtn


func _ready() -> void:
	close_btn.pressed.connect(func(): close_requested.emit())
	_build_evidence_tab()
	_build_clue_tab()
	_build_people_tab()


func _make_scroll_panel(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_container.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	return vbox


func _add_entry(parent: VBoxContainer, title: String, body: String, color: Color = Color(1, 0.9, 0.6, 1)) -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(0, 90)
	parent.add_child(pc)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	pc.add_child(vbox)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", color)
	vbox.add_child(t)
	var b := RichTextLabel.new()
	b.bbcode_enabled = true
	b.fit_content = true
	b.text = body
	b.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(b)


func _build_evidence_tab() -> void:
	var vbox := _make_scroll_panel("证 物")
	if GameManager.collected_evidence.is_empty():
		var lbl := Label.new()
		lbl.text = "  尚无证物。"
		lbl.add_theme_font_size_override("font_size", 18)
		vbox.add_child(lbl)
		return
	for eid in GameManager.collected_evidence:
		var data = GameManager.evidence_data.get(eid, {})
		_add_entry(vbox, data.get("name", eid), data.get("description", ""), Color(1, 0.7, 0.5, 1))


func _build_clue_tab() -> void:
	var vbox := _make_scroll_panel("线 索")
	if GameManager.collected_clues.is_empty():
		var lbl := Label.new()
		lbl.text = "  尚无线索。"
		lbl.add_theme_font_size_override("font_size", 18)
		vbox.add_child(lbl)
		return
	for cid in GameManager.collected_clues:
		var data = GameManager.evidence_data.get(cid, {})
		_add_entry(vbox, data.get("name", cid), data.get("description", ""), Color(1, 0.85, 0.6, 1))


func _build_people_tab() -> void:
	var vbox := _make_scroll_panel("人 物")
	# 只显示已遇过的 NPC（出现在已访问地点的 NPC 列表中）
	var seen: Array = []
	for loc_id in GameManager.visited_locations:
		var npcs: Array = GameManager.get_location_data(loc_id).get("npcs", [])
		for n in npcs:
			if not seen.has(n):
				seen.append(n)
	for nid in seen:
		var data = GameManager.get_npc_data(nid)
		# 累计已揭穿的谎言
		var lies_exposed: Array = []
		for flag in GameManager.dialogue_flags.keys():
			if flag.begins_with("lie_exposed:%s." % nid):
				var ln: String = flag.substr(("lie_exposed:%s." % nid).length())
				lies_exposed.append(ln)
		var body: String = data.get("intro", "")
		if lies_exposed.size() > 0:
			body += "\n\n[color=#ffaa55]【已识破谎言】[/color]"
			for ln in lies_exposed:
				body += "\n  · %s" % ln
		_add_entry(vbox, "%s ｜ %s" % [data.get("name", nid), data.get("title", "")], body, Color(0.85, 1, 0.85, 1))
