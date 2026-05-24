extends Control
## 时间过场系统：黑屏 + 打字机效果从左往右逐字显示
## show_day() — 换天过场
## show_period() — 通用时间过场（所有时间显示统一风格）

signal finished

@onready var bg: ColorRect = $Bg
@onready var label: Label = $CenterBox/VBox/DayLabel
@onready var sub_label: Label = $CenterBox/VBox/SubLabel


func _ready() -> void:
	visible = false


## 换天过场（也用打字机+左对齐，与 show_period 统一风格）
func show_day(day: int, sub_text: String = "") -> void:
	var main_text := "第 %d 日" % day
	if sub_text != "":
		main_text += "  %s" % sub_text
	show_period(main_text)


## 通用时间过场：立即黑屏 + 42px左对齐 + 打字机从左往右 + 停留1.5秒
func show_period(period_text: String) -> void:
	# 立即全黑（不淡入，避免闪1-2帧场景）
	bg.modulate.a = 1.0
	visible = true

	label.text = period_text
	sub_label.text = ""
	sub_label.modulate.a = 0.0

	# 统一样式：42px、左对齐、打字机
	label.add_theme_font_size_override("font_size", 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.visible_characters = 0
	label.modulate.a = 1.0

	GameManager.set_state(GameManager.STATE_TRANSITION)
	var total_chars: int = label.text.length()
	var type_duration: float = total_chars * 0.09  # 每字0.09秒

	var tw := create_tween()
	# 打字机：从左往右逐字显示（黑屏已就绪）
	tw.tween_property(label, "visible_characters", total_chars, type_duration).set_delay(0.3)
	# 全部打完停留1.5秒
	tw.tween_interval(1.5)
	# 淡出
	tw.tween_property(label, "modulate:a", 0.0, 0.35)
	tw.tween_property(bg, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		visible = false
		label.visible_characters = -1
		label.modulate.a = 1.0
		GameManager.set_state(GameManager.STATE_PLAYING)
		finished.emit()
	)
