extends Control
## 序章/叙述框：支持底部对话框与居中提示框两种显示

@onready var box: PanelContainer = $Box
@onready var speaker_label: Label = $Box/VBox/SpeakerName
@onready var text_label: RichTextLabel = $Box/VBox/TextLabel
@onready var continue_label: Label = $Box/VBox/ContinueLabel

var _has_next: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		DialogueManager.narration_advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		DialogueManager.narration_advance()
		get_viewport().set_input_as_handled()


func show_narration(speaker: String, text: String, has_next: bool, centered := false) -> void:
	speaker_label.text = speaker
	speaker_label.visible = (speaker != "")
	text_label.text = text
	_has_next = has_next
	continue_label.text = "▼ 点击继续" if has_next else "▼ 点击进入游戏"
	_apply_layout(centered)


func _apply_layout(centered: bool) -> void:
	if centered:
		box.anchor_left = 0.5
		box.anchor_top = 0.5
		box.anchor_right = 0.5
		box.anchor_bottom = 0.5
		box.offset_left = -470
		box.offset_top = -170
		box.offset_right = 470
		box.offset_bottom = 170
		text_label.custom_minimum_size = Vector2(880, 220)
		text_label.add_theme_font_size_override("normal_font_size", 22)
		text_label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.76, 1))
	else:
		box.anchor_left = 0.0
		box.anchor_top = 1.0
		box.anchor_right = 1.0
		box.anchor_bottom = 1.0
		box.offset_left = 80
		box.offset_top = -260
		box.offset_right = -80
		box.offset_bottom = -40
		text_label.custom_minimum_size = Vector2(0, 150)
		text_label.add_theme_font_size_override("normal_font_size", 22)
		text_label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.76, 1))
