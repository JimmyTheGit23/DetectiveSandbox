extends Control
## 设置面板：BGM 音量 / 语音音量 / 返回标题 / 关闭。

signal close_requested()
signal return_to_title_requested()

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


func _on_gm_unlock_toggled(pressed: bool) -> void:
	if _settings and _settings.has_method("set_gm_unlock_all"):
		_settings.set_gm_unlock_all(pressed)
