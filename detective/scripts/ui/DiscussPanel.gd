extends PanelContainer
## 助手讨论面板：显示可用话题列表，玩家选择后触发助手对话。

signal discuss_closed()
signal discuss_result(lines: Array)

const TOPIC_LABELS := {
	"next_direction": "大致下一步该往哪走？",
	"suspect_now": "现在最可疑的人是谁？",
	"evidence_ready": "我手上证据是不是够了？",
	"chitchat": "闲聊一下",
}

const TOPIC_COST_TEXT := {
	"next_direction": "消耗 1 时段",
	"suspect_now": "消耗 1 时段",
	"evidence_ready": "每日 1 次，无消耗",
	"chitchat": "不限次数",
}

var _vbox: VBoxContainer
var _title_label: Label
var _hint_label: Label
var _cancel_btn: Button


func _ready() -> void:
	custom_minimum_size = Vector2(420, 320)
	_build_ui()
	_populate_topics()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(margin)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(_vbox)

	_title_label = Label.new()
	_title_label.text = "与凌瑶讨论"
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(_title_label)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_vbox.add_child(_hint_label)

	# 分割线
	var sep := HSeparator.new()
	_vbox.add_child(sep)


func _populate_topics() -> void:
	var cs = get_node_or_null("/root/CompanionService")
	if cs == null:
		return

	# 更新标题中的角色名
	_title_label.text = "与%s讨论" % cs.get_companion_role_name()

	# 提示剩余次数
	var day_text := "第 %d 日" % GameManager.current_day
	_hint_label.text = day_text

	var topics: Array = cs.get_available_topics()
	for topic_info in topics:
		var topic_id: String = topic_info.get("id", "")
		var state: Dictionary = topic_info.get("state", {})
		var available: bool = state.get("available", false)
		var remaining: int = state.get("remaining", 0)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label_text: String = TOPIC_LABELS.get(topic_id, topic_id)
		var cost_text: String = TOPIC_COST_TEXT.get(topic_id, "")

		if topic_id == "chitchat":
			btn.text = "%s    （%s）" % [label_text, cost_text]
		elif available:
			btn.text = "%s    （%s · 剩余%d次）" % [label_text, cost_text, remaining]
		else:
			var reason: String = state.get("reason", "")
			var reason_text := ""
			match reason:
				"daily_limit":
					reason_text = "今日已用完"
				"final_day_locked":
					reason_text = "终局日不可使用"
				"no_time":
					reason_text = "时间不足"
				_:
					reason_text = "不可用"
			btn.text = "%s    （%s）" % [label_text, reason_text]
			btn.disabled = true

		btn.pressed.connect(_on_topic_selected.bind(topic_id))
		_vbox.add_child(btn)

	# 取消按钮
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_vbox.add_child(spacer)

	_cancel_btn = Button.new()
	_cancel_btn.text = "取  消"
	_cancel_btn.custom_minimum_size = Vector2(0, 40)
	_cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel_btn.pressed.connect(_on_cancel)
	_vbox.add_child(_cancel_btn)


func _on_topic_selected(topic_id: String) -> void:
	var cs = get_node_or_null("/root/CompanionService")
	if cs == null:
		_close()
		return
	var lines: Array = cs.discuss(topic_id)
	discuss_result.emit(lines)
	_close()


func _on_cancel() -> void:
	_close()


func _close() -> void:
	discuss_closed.emit()
	queue_free()
