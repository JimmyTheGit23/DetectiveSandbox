extends Control
## 日期推进过场：黑屏 + 「第 X 日 · 时段」毛笔字渐入渐出

signal finished

@onready var bg: ColorRect = $Bg
@onready var label: Label = $CenterBox/VBox/DayLabel
@onready var sub_label: Label = $CenterBox/VBox/SubLabel


func _ready() -> void:
	visible = false


func show_day(day: int, sub_text: String = "") -> void:
	visible = true
	label.text = "第 %d 日" % day
	sub_label.text = sub_text
	label.modulate.a = 0.0
	sub_label.modulate.a = 0.0
	bg.modulate.a = 0.0
	
	GameManager.set_state(GameManager.STATE_TRANSITION)
	var tw := create_tween()
	tw.tween_property(bg, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(label, "modulate:a", 1.0, 0.6).set_delay(0.2)
	tw.parallel().tween_property(sub_label, "modulate:a", 1.0, 0.6).set_delay(0.6)
	tw.tween_interval(1.6)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(sub_label, "modulate:a", 0.0, 0.5)
	tw.tween_property(bg, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		visible = false
		GameManager.set_state(GameManager.STATE_PLAYING)
		finished.emit()
	)
