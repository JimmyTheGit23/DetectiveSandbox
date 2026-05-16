extends Control
## 移动面板：当前简化为"全镇地图入口"快捷键。
## 子地点系统暂未启用，此面板直接说明并提供进入地图选项。

signal close_requested()

@onready var label: RichTextLabel = $Panel/VBox/Info
@onready var close_btn: Button = $Panel/VBox/CloseBtn


func _ready() -> void:
	close_btn.pressed.connect(func(): close_requested.emit())
	label.text = "[center][color=#ddd]\n你正处于：[color=#fbb]%s[/color]\n\n本区域内尚无可移动的子位置（待开放）。\n如需前往其他地点，请使用[color=#ffd]【地图】[/color]菜单。\n[/color][/center]" % GameManager.current_location_data().get("name", "")
