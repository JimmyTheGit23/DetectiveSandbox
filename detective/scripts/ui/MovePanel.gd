extends Control
## 移动面板：显示当前地点的内部可通行路径（sub_locations）。
## 选择后直接移动到目标地点（不消耗时段，楼内/院内走动）。

signal close_requested()
signal location_selected(location_id: String)

@onready var panel: PanelContainer = $Panel

const CLR_GOLD := Color(0.96, 0.88, 0.65)
const CLR_DIM := Color(0.6, 0.55, 0.45, 0.7)
const CLR_BORDER := Color(0.6, 0.45, 0.25, 0.5)


func _ready() -> void:
	_build()


func _build() -> void:
	# 清理场景模板里的占位 VBox/按钮，避免旧 CloseBtn 盖在移动项上吞掉点击。
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	# 标题
	var title := Label.new()
	var loc_name: String = GameManager.current_location_data().get("name", "")
	title.text = "── 移  动 ──"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", CLR_GOLD)
	vbox.add_child(title)

	# 当前位置
	var current := Label.new()
	current.text = "当前位置：%s" % loc_name
	current.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current.add_theme_font_size_override("font_size", 16)
	current.add_theme_color_override("font_color", CLR_DIM)
	vbox.add_child(current)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", CLR_BORDER)
	vbox.add_child(sep)

	# 子地点列表
	var loc_data: Dictionary = GameManager.current_location_data()
	var subs: Array = loc_data.get("sub_locations", [])

	if subs.is_empty():
		var empty := Label.new()
		empty.text = "此处没有可移动的方向。\n如需前往其他地点，请使用【地图】。"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", CLR_DIM)
		vbox.add_child(empty)
	else:
		for sub in subs:
			if not sub is Dictionary:
				continue
			var target: String = sub.get("target", "")
			var btn_name: String = sub.get("name", target)
			var desc: String = sub.get("description", "")

			var row := PanelContainer.new()
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.12, 0.08, 0.7)
			style.border_color = CLR_BORDER
			style.set_border_width_all(1)
			style.set_corner_radius_all(5)
			style.set_content_margin_all(12)
			row.add_theme_stylebox_override("panel", style)
			row.custom_minimum_size = Vector2(0, 52)

			var hbox := HBoxContainer.new()
			hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_theme_constant_override("separation", 14)
			row.add_child(hbox)

			var arrow := Label.new()
			arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			arrow.text = "▸"
			arrow.add_theme_font_size_override("font_size", 20)
			arrow.add_theme_color_override("font_color", CLR_GOLD)
			arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hbox.add_child(arrow)

			var text_vbox := VBoxContainer.new()
			text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(text_vbox)

			var name_lbl := Label.new()
			name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_lbl.text = btn_name
			name_lbl.add_theme_font_size_override("font_size", 19)
			name_lbl.add_theme_color_override("font_color", CLR_GOLD)
			text_vbox.add_child(name_lbl)

			if desc != "":
				var desc_lbl := Label.new()
				desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				desc_lbl.text = desc
				desc_lbl.add_theme_font_size_override("font_size", 14)
				desc_lbl.add_theme_color_override("font_color", CLR_DIM)
				text_vbox.add_child(desc_lbl)

			var tid := target
			row.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					location_selected.emit(tid)
			)
			row.mouse_filter = Control.MOUSE_FILTER_STOP
			vbox.add_child(row)

	# 关闭按钮
	var close_btn := Button.new()
	close_btn.text = "关  闭"
	close_btn.custom_minimum_size = Vector2(140, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): close_requested.emit())
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(close_btn)
