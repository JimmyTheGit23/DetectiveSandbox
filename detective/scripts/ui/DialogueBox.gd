extends Control
## NPC 对话框：底部只显示立绘、名字和文本；文字播完后才在画面上方显示选项。

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")

@onready var portrait_rect: TextureRect = $Portrait
@onready var speaker_label: Label = $Box/SpeakerName
@onready var text_label: RichTextLabel = $Box/TextLabel
@onready var legacy_options: ScrollContainer = $Box/Options
@onready var options_vbox: VBoxContainer = $Box/Options/OptionsVBox
@onready var exit_btn: Button = $Box/ExitBtn

var _typewriter: Node = null
var _top_options_panel: PanelContainer = null
var _top_options_vbox: VBoxContainer = null
var _choice_hint_label: Label = null

const DEFAULT_PORTRAIT_POSITION := Vector2(34, -200)
const DEFAULT_PORTRAIT_SIZE := Vector2(200, 500)
const OPERA_PERFORMER_PORTRAIT_POSITION := Vector2(-66, -200)
const OPERA_PERFORMER_PORTRAIT_SIZE := Vector2(300, 500)
const SENIOR_PREFECT_PORTRAIT_POSITION := Vector2(12, -150)
const SENIOR_PREFECT_PORTRAIT_SIZE := Vector2(180, 450)


func _ready() -> void:
	legacy_options.visible = false
	exit_btn.visible = false
	text_label.anchor_bottom = 1.0
	text_label.offset_bottom = -46.0
	text_label.add_theme_font_size_override("normal_font_size", 22)
	_build_choice_hint()
	_build_top_options_panel()
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# 文字出字中点击 → 立即显示全文；不显示选项。
	if _typewriter.is_playing():
		var clicked := false
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked = true
		elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			clicked = true
		if clicked:
			_typewriter.skip()
			get_viewport().set_input_as_handled()


func show_dialogue(speaker: String, portrait_path: String, text: String, options: Array) -> void:
	speaker_label.text = speaker
	portrait_rect.position = DEFAULT_PORTRAIT_POSITION
	portrait_rect.size = DEFAULT_PORTRAIT_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if portrait_path.ends_with("actor_opera_performer.png"):
		portrait_rect.position = OPERA_PERFORMER_PORTRAIT_POSITION
		portrait_rect.size = OPERA_PERFORMER_PORTRAIT_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	elif portrait_path.ends_with("actor_senior_prefect.png"):
		portrait_rect.position = SENIOR_PREFECT_PORTRAIT_POSITION
		portrait_rect.size = SENIOR_PREFECT_PORTRAIT_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false
	
	_hide_options()
	_choice_hint_label.visible = false
	
	# 逐字显示对话文本。说话过程中不显示任何选项。
	_typewriter.play(text_label, text)
	await _typewriter.finished
	
	_choice_hint_label.visible = true
	_show_options(options)


func _build_choice_hint() -> void:
	_choice_hint_label = Label.new()
	_choice_hint_label.text = "▼ 请选择回应"
	_choice_hint_label.anchor_left = 0.0
	_choice_hint_label.anchor_top = 1.0
	_choice_hint_label.anchor_right = 1.0
	_choice_hint_label.anchor_bottom = 1.0
	_choice_hint_label.offset_top = -34.0
	_choice_hint_label.offset_bottom = -6.0
	_choice_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_choice_hint_label.add_theme_font_size_override("font_size", 16)
	_choice_hint_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.6, 0.8))
	_choice_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_hint_label.visible = false
	$Box.add_child(_choice_hint_label)


func _build_top_options_panel() -> void:
	_top_options_panel = PanelContainer.new()
	_top_options_panel.name = "TopOptionsPanel"
	_top_options_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# 顶部选项不使用外层底框，只保留按钮自身的边框。
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)
	panel_style.border_color = Color(0, 0, 0, 0)
	panel_style.set_border_width_all(0)
	panel_style.content_margin_left = 0
	panel_style.content_margin_right = 0
	panel_style.content_margin_top = 0
	panel_style.content_margin_bottom = 0
	_top_options_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_top_options_panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	_top_options_panel.add_child(margin)
	
	_top_options_vbox = VBoxContainer.new()
	_top_options_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(_top_options_vbox)
	_top_options_panel.visible = false


func _position_top_options(option_count: int) -> void:
	var vp := get_viewport_rect().size
	var panel_w: float = min(880.0, vp.x * 0.80)
	var panel_h: float = min(300.0, max(1, option_count) * 54.0)
	_top_options_panel.size = Vector2(panel_w, panel_h)
	_top_options_panel.position = Vector2((vp.x - panel_w) * 0.5, 432.0 - vp.y)


func _hide_options() -> void:
	legacy_options.visible = false
	exit_btn.visible = false
	if _top_options_panel:
		_top_options_panel.visible = false
	if _top_options_vbox:
		for child in _top_options_vbox.get_children():
			child.queue_free()
	for child in options_vbox.get_children():
		child.queue_free()


func _show_options(options: Array) -> void:
	_hide_options()
	var visible_count := 0
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var goto_val: String = opt.get("goto", "")
		if goto_val == "__exit__":
			continue
		var option_text: String = opt.get("text", "")
		if opt.get("_visited", false):
			option_text = "✓ " + option_text
		var btn := _make_option_button(option_text)
		var idx := i
		btn.pressed.connect(func():
			_hide_options()
			_choice_hint_label.visible = false
			DialogueManager.choose_option(idx)
		)
		_top_options_vbox.add_child(btn)
		visible_count += 1
	var close_btn := _make_option_button("（先告辞，待会再来）  ✕")
	close_btn.pressed.connect(func():
		_hide_options()
		_choice_hint_label.visible = false
		DialogueManager.end_dialogue(true)
	)
	_top_options_vbox.add_child(close_btn)
	visible_count += 1
	_position_top_options(visible_count)
	_top_options_panel.visible = true


func _make_option_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
	return btn
