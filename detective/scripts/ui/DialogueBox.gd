extends Control
## 底部对话框：NPC 立绘 + 名字 + 文本（逐字显示）+ 选项滚动列表 + 常驻"结束对话"按钮

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")

@onready var portrait_rect: TextureRect = $Portrait
@onready var speaker_label: Label = $Box/SpeakerName
@onready var text_label: RichTextLabel = $Box/TextLabel
@onready var options_vbox: VBoxContainer = $Box/Options/OptionsVBox
@onready var exit_btn: Button = $Box/ExitBtn

var _typewriter: Node = null


func _ready() -> void:
	exit_btn.pressed.connect(_on_exit_pressed)
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# 文字出字中点击 → 立即显示全文
	if _typewriter.is_playing():
		var clicked := false
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked = true
		elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			clicked = true
		if clicked:
			_typewriter.skip()
			get_viewport().set_input_as_handled()


func _on_exit_pressed() -> void:
	DialogueManager.end_dialogue()


func show_dialogue(speaker: String, portrait_path: String, text: String, options: Array) -> void:
	speaker_label.text = speaker
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false
	
	# 先隐藏选项，等文字出完再显示
	options_vbox.visible = false
	for child in options_vbox.get_children():
		child.queue_free()
	
	# 逐字显示对话文本
	_typewriter.play(text_label, text)
	await _typewriter.finished
	
	# 文字完成后显示选项
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var goto_val: String = opt.get("goto", "")
		if goto_val == "__exit__":
			continue
		var btn := Button.new()
		btn.text = opt.get("text", "")
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 36)
		var idx := i
		btn.pressed.connect(func(): DialogueManager.choose_option(idx))
		options_vbox.add_child(btn)
	options_vbox.visible = true
