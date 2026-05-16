extends Control
## 序章/叙述框：底部文字盒，居中显示，点击/按键继续

@onready var speaker_label: Label = $Box/VBox/SpeakerName
@onready var text_label: RichTextLabel = $Box/VBox/TextLabel
@onready var continue_label: Label = $Box/VBox/ContinueLabel

var _has_next: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 用 _gui_input 比 gui_input 信号更直接
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


func show_narration(speaker: String, text: String, has_next: bool) -> void:
	speaker_label.text = speaker
	speaker_label.visible = (speaker != "")
	text_label.text = text
	_has_next = has_next
	continue_label.text = "▼ 点击继续" if has_next else "▼ 点击进入主菜单"
