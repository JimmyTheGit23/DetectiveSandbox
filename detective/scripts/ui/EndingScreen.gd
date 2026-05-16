extends Control
## 结局画面

@onready var title_label: Label = $Center/VBox/Title
@onready var text_label: RichTextLabel = $Center/VBox/Text
@onready var restart_btn: Button = $Center/VBox/RestartBtn


func _ready() -> void:
	restart_btn.pressed.connect(_on_restart)


func show_ending(title: String, text: String) -> void:
	title_label.text = title
	text_label.text = "[center]" + text + "[/center]"


func _on_restart() -> void:
	get_tree().reload_current_scene()
