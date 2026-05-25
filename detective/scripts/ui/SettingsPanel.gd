extends Control
## 设置面板：BGM 音量 / 语音音量 / 返回标题 / 关闭。

signal close_requested()
signal return_to_title_requested()
signal game_reset_requested()

@onready var panel: PanelContainer = $Panel

var _bgm_slider: HSlider
var _voice_slider: HSlider
var _bgm_value_lbl: Label
var _voice_value_lbl: Label
var _gm_check: CheckBox
# 用 get_node 取 autoload，避免 LSP 在某些环境下不识别 autoload symbol
var _settings: Node


func _ready() -> void:
	_settings = get_node_or_null("/root/SettingsService")
	_build_ui()


func _bgm_init_value() -> float:
	return float(_settings.bgm_volume) if _settings else 0.8


func _voice_init_value() -> float:
	return float(_settings.voice_volume) if _settings else 1.0


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	# 标题
	var title := Label.new()
	title.text = "设  置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.65))
	vbox.add_child(title)
	
	# 分割线
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.6, 0.45, 0.25, 0.6))
	vbox.add_child(sep)
	
	# 音乐音量
	vbox.add_child(_make_volume_row("音  乐", _bgm_init_value(), true))
	# 语音音量
	vbox.add_child(_make_volume_row("语  音", _voice_init_value(), false))
	
	# 间距
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	# GM 指令区
	var gm_sep := HSeparator.new()
	gm_sep.add_theme_color_override("separator", Color(0.6, 0.45, 0.25, 0.4))
	vbox.add_child(gm_sep)

	var gm_box := HBoxContainer.new()
	gm_box.add_theme_constant_override("separation", 10)
	gm_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(gm_box)

	var gm_label := Label.new()
	gm_label.text = "GM 指令"
	gm_label.add_theme_font_size_override("font_size", 18)
	gm_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3, 1))
	gm_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gm_box.add_child(gm_label)

	_gm_check = CheckBox.new()
	_gm_check.text = "解锁全部案件"
	_gm_check.button_pressed = bool(_settings.get("gm_unlock_all")) if _settings else false
	_gm_check.add_theme_font_size_override("font_size", 16)
	_gm_check.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55, 1))
	_gm_check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gm_check.toggled.connect(_on_gm_unlock_toggled)
	gm_box.add_child(_gm_check)

	var gm_hint := Label.new()
	gm_hint.text = "（测试用，无视等级限制）"
	gm_hint.add_theme_font_size_override("font_size", 12)
	gm_hint.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42, 0.8))
	gm_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gm_box.add_child(gm_hint)

	# 快速跳转按钮（调试用）
	var debug_box := HBoxContainer.new()
	debug_box.add_theme_constant_override("separation", 10)
	vbox.add_child(debug_box)

	var btn_confront := Button.new()
	btn_confront.text = "⚡ 快速进入对峙"
	btn_confront.custom_minimum_size = Vector2(0, 40)
	btn_confront.add_theme_font_size_override("font_size", 16)
	btn_confront.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1))
	btn_confront.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.5, 1))
	btn_confront.pressed.connect(_on_debug_confrontation)
	debug_box.add_child(btn_confront)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer2)
	
	# 按钮区
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_box)
	
	var btn_title := Button.new()
	btn_title.text = "返回标题画面"
	btn_title.custom_minimum_size = Vector2(0, 48)
	btn_title.add_theme_font_size_override("font_size", 20)
	btn_title.pressed.connect(_on_return_title)
	btn_box.add_child(btn_title)
	
	var btn_reset := Button.new()
	btn_reset.text = "重置游戏进度"
	btn_reset.custom_minimum_size = Vector2(0, 48)
	btn_reset.add_theme_font_size_override("font_size", 20)
	btn_reset.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))
	btn_reset.pressed.connect(_on_reset_game)
	btn_box.add_child(btn_reset)
	
	var reset_hint := Label.new()
	reset_hint.text = "（清除所有案件进度、经验和存档，不可恢复）"
	reset_hint.add_theme_font_size_override("font_size", 12)
	reset_hint.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42, 0.8))
	btn_box.add_child(reset_hint)
	
	var btn_close := Button.new()
	btn_close.text = "关闭设置"
	btn_close.custom_minimum_size = Vector2(0, 44)
	btn_close.add_theme_font_size_override("font_size", 18)
	btn_close.pressed.connect(_on_close)
	btn_box.add_child(btn_close)


func _make_volume_row(label_text: String, init_value: float, is_bgm: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)
	
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = init_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(280, 32)
	row.add_child(slider)
	
	var value_lbl := Label.new()
	value_lbl.text = "%d%%" % int(round(init_value * 100))
	value_lbl.custom_minimum_size = Vector2(56, 0)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_lbl.add_theme_font_size_override("font_size", 18)
	value_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value_lbl)
	
	if is_bgm:
		_bgm_slider = slider
		_bgm_value_lbl = value_lbl
		slider.value_changed.connect(_on_bgm_changed)
	else:
		_voice_slider = slider
		_voice_value_lbl = value_lbl
		slider.value_changed.connect(_on_voice_changed)
	
	return row


func _on_bgm_changed(v: float) -> void:
	_bgm_value_lbl.text = "%d%%" % int(round(v * 100))
	if _settings and _settings.has_method("set_bgm_volume"):
		_settings.set_bgm_volume(v)


func _on_voice_changed(v: float) -> void:
	_voice_value_lbl.text = "%d%%" % int(round(v * 100))
	if _settings and _settings.has_method("set_voice_volume"):
		_settings.set_voice_volume(v)


func _on_close() -> void:
	close_requested.emit()


func _on_return_title() -> void:
	return_to_title_requested.emit()


func _on_debug_confrontation() -> void:
	_unlock_all_evidence()
	GameManager.set_state(GameManager.STATE_PLAYING)
	GameManager.current_location = GameManager.case_main_scene
	var main = get_tree().current_scene
	# 隐藏标题
	if main and main.has_method("_hide_title"):
		main._hide_title()
	# 隐藏菜单
	var menu = main.get_node_or_null("RightMenu")
	if menu:
		menu.visible = false
	# 直接实例化对峙面板到主场景
	var scene_path := "res://scenes/ui/ConfrontationPanel.tscn"
	if ResourceLoader.exists(scene_path):
		var packed: PackedScene = load(scene_path)
		var confrontation_panel: Control = packed.instantiate()
		main.add_child(confrontation_panel)
		main.move_child(confrontation_panel, main.get_child_count() - 1)
		if confrontation_panel.has_signal("confrontation_finished"):
			confrontation_panel.confrontation_finished.connect(func(result, mistakes):
				confrontation_panel.queue_free()
				if main.has_method("_show_ending"):
					var ending_id = GameManager.judge_confrontation(result, mistakes)
					main._show_ending(ending_id)
			)
	# 关闭设置面板
	queue_free()



func _unlock_all_evidence() -> void:
	# 给玩家解锁本案所有证据和线索
	for eid in GameManager.evidence_data.keys():
		if eid.begins_with("_"):
			continue
		var entry: Dictionary = GameManager.evidence_data[eid]
		var etype: String = entry.get("type", "")
		if etype == "evidence":
			GameManager.add_evidence(eid)
		elif etype == "clue":
			GameManager.add_clue(eid)
	# 确保游戏状态为 playing
	if GameManager.current_state == GameManager.STATE_PROLOGUE:
		GameManager.set_state(GameManager.STATE_PLAYING)


func _on_gm_unlock_toggled(pressed: bool) -> void:
	if _settings and _settings.has_method("set_gm_unlock_all"):
		_settings.set_gm_unlock_all(pressed)


var _reset_confirm_step: int = 0

func _on_reset_game() -> void:
	if _reset_confirm_step == 0:
		_reset_confirm_step = 1
		# 找到重置按钮并修改文本作为确认提示
		var btn_box: VBoxContainer = null
		for child in panel.get_children():
			if child is VBoxContainer:
				for sub in child.get_children():
					if sub is VBoxContainer:
						btn_box = sub
						break
		if btn_box:
			for child in btn_box.get_children():
				if child is Button and child.text == "重置游戏进度":
					child.text = "确认重置？（再次点击执行）"
					child.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15))
					break
		# 3秒后自动恢复
		get_tree().create_timer(3.0).timeout.connect(_reset_confirm_timeout)
	elif _reset_confirm_step == 1:
		_reset_confirm_step = 0
		_do_reset()


func _reset_confirm_timeout() -> void:
	_reset_confirm_step = 0
	# 恢复按钮文本
	for child in panel.get_children():
		if child is VBoxContainer:
			for sub in child.get_children():
				if sub is VBoxContainer:
					for btn in sub.get_children():
						if btn is Button and btn.text.begins_with("确认重置"):
							btn.text = "重置游戏进度"
							btn.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))
							return


func _do_reset() -> void:
	# 1. 重置调查员档案（等级、XP、通关记录等）
	var inv := get_node_or_null("/root/InvestigatorService")
	if inv and inv.has_method("reset_profile"):
		inv.reset_profile()
	# 2. 删除所有单案存档 + current_case.json
	var saves_dir := ProjectSettings.globalize_path("user://saves")
	if DirAccess.dir_exists_absolute(saves_dir):
		var da := DirAccess.open(saves_dir)
		if da:
			da.list_dir_begin()
			var fname := da.get_next()
			while fname != "":
				if fname.ends_with(".json"):
					da.remove(fname)
				fname = da.get_next()
	var cc_path := ProjectSettings.globalize_path("user://current_case.json")
	if FileAccess.file_exists("user://current_case.json"):
		DirAccess.remove_absolute(cc_path)
	# 3. 发出信号，由 MainGame 处理返回标题
	game_reset_requested.emit()
