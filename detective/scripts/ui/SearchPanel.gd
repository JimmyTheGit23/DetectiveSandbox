extends Control
## 探索面板：列出当前地点所有可探索点，点击后先播放探索仪式感，再消耗时间并弹出结果对话框

signal close_requested()
signal search_result_acknowledged()

@onready var title_label: Label = $Panel/VBox/Title
@onready var list_vbox: VBoxContainer = $Panel/VBox/List
@onready var result_box: RichTextLabel = $Panel/VBox/ResultBox
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var _is_searching := false


func is_searching() -> bool:
	return _is_searching


func _ready() -> void:
	close_btn.pressed.connect(func(): close_requested.emit())
	title_label.text = "── 可疑之处 ──"
	result_box.text = "[i]点击下方按钮以探索该处。[/i]"
	_build_list()


func _build_list() -> void:
	for child in list_vbox.get_children():
		child.queue_free()
	var loc := GameManager.current_location_data()
	var loc_id: String = GameManager.current_location
	for sp in loc.get("search_points", []):
		var pid: String = sp.get("id", "")
		var pname: String = sp.get("name", pid)
		var key := "%s.%s" % [loc_id, pid]
		var done: int = GameManager.search_history.get(key, 0)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# 渐进系统：检查搜索点是否解锁
		var unlocked := GameManager.is_search_point_unlocked(loc_id, pid)
		if unlocked:
			var done_mark := "  ✓" if done > 0 else ""
			btn.text = "  %s%s" % [pname, done_mark]
			btn.disabled = _is_searching
			btn.pressed.connect(_on_search.bind(pid))
		else:
			var hint := GameManager.get_search_point_locked_hint(loc_id, pid)
			btn.text = "  🔒 %s" % pname
			btn.disabled = true
			btn.tooltip_text = hint
			btn.modulate.a = 0.5
		list_vbox.add_child(btn)


func _on_search(point_id: String) -> void:
	if _is_searching:
		return
	_is_searching = true
	_set_buttons_disabled(true)
	close_btn.disabled = true
	
	var point_name := _point_name(point_id)

	var result := GameManager.resolve_search(GameManager.current_location, point_id)
	result_box.text = "[center][color=#ead48a]探索中……[/color]\n[i]你放慢脚步，重新检查每一个细节。[/i][/center]"
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return

	await _show_result_dialog(point_name, result)
	if not is_inside_tree():
		return
	search_result_acknowledged.emit()
	
	_build_list()
	result_box.text = "[i]请选择下一处可疑点继续探索。[/i]"
	_is_searching = false
	_set_buttons_disabled(false)
	close_btn.disabled = false
	
	# 触发对话（用于"在某处遇见 NPC"剧情事件）
	var trigger_npc: String = result.get("trigger_dialogue", "")
	if trigger_npc != "":
		var start_node: String = result.get("trigger_dialogue_start", "")
		close_requested.emit()
		await get_tree().process_frame
		if start_node != "":
			DialogueManager.start_dialogue_at(trigger_npc, start_node)
		else:
			DialogueManager.start_dialogue(trigger_npc)


func _point_name(point_id: String) -> String:
	for sp in GameManager.current_location_data().get("search_points", []):
		if sp.get("id", "") == point_id:
			return sp.get("name", point_id)
	return point_id


func _set_buttons_disabled(disabled: bool) -> void:
	for child in list_vbox.get_children():
		if child is Button:
			(child as Button).disabled = disabled


func _show_result_dialog(point_name: String, result: Dictionary) -> void:
	var overlay := Control.new()
	overlay.name = "SearchResultOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.add_child(dim)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 360)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.065, 0.045, 0.96)
	style.border_color = Color(0.72, 0.56, 0.28, 0.95)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 18
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "── 探索结果 · %s ──" % point_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1))
	vbox.add_child(title)
	
	var body := RichTextLabel.new()
	body.custom_minimum_size = Vector2(700, 220)
	body.bbcode_enabled = true
	body.fit_content = false
	body.scroll_active = true
	body.add_theme_font_size_override("normal_font_size", 20)
	body.add_theme_color_override("default_color", Color(0.9, 0.86, 0.76, 1))
	body.text = _result_dialog_text(result)
	vbox.add_child(body)

	# 证据/线索图片展示
	var ev_id: String = result.get("gained_evidence", "")
	if ev_id == "":
		ev_id = result.get("gained_clue", "")
	if ev_id != "":
		var icon_path := "res://assets/ai_processed/objects/evidence_icons/%s.png" % ev_id
		if ResourceLoader.exists(icon_path):
			var tex: Texture2D = load(icon_path)
			if tex:
				var img := TextureRect.new()
				img.texture = tex
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				img.custom_minimum_size = Vector2(240, 240)
				img.size = Vector2(240, 240)
				img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				vbox.add_child(img)
				# 有图片时扩大面板最小尺寸
				panel.custom_minimum_size.y = 620

	var btn := Button.new()
	btn.text = "知 道 了"
	btn.custom_minimum_size = Vector2(180, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58, 1))
	vbox.add_child(btn)
	
	await btn.pressed
	if is_instance_valid(overlay):
		overlay.queue_free()


func _result_dialog_text(result: Dictionary) -> String:
	var txt: String = "你完成了这次调查。\n\n"
	var narration: String = result.get("narration", "")
	if narration == "":
		narration = result.get("intro_text", "")
	txt += narration
	if result.get("gained_evidence", "") != "":
		var ev = GameManager.evidence_data.get(result.gained_evidence, {})
		txt += "\n\n【获得证据：%s】" % ev.get("name", "")
	if result.get("gained_clue", "") != "":
		var cl = GameManager.evidence_data.get(result.gained_clue, {})
		txt += "\n\n【获得线索：%s】" % cl.get("name", "")
	return txt
