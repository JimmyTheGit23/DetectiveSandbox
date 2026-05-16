extends Control
## 底部对话框：NPC 立绘 + 名字 + 文本 + 选项滚动列表 + 常驻"结束对话"按钮

@onready var portrait_rect: TextureRect = $Portrait
@onready var speaker_label: Label = $Box/SpeakerName
@onready var text_label: RichTextLabel = $Box/TextLabel
@onready var options_vbox: VBoxContainer = $Box/Options/OptionsVBox
@onready var exit_btn: Button = $Box/ExitBtn


func _ready() -> void:
	exit_btn.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	DialogueManager.end_dialogue()


func show_dialogue(speaker: String, portrait_path: String, text: String, options: Array) -> void:
	speaker_label.text = speaker
	text_label.text = text
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false
	
	for child in options_vbox.get_children():
		child.queue_free()
	# 把对话节点显式定义的选项添加进来
	# 跳过显式的 __exit__ 选项（避免与底部常驻"结束对话"按钮重复）
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
