extends PanelContainer
## 右侧主菜单：6 个图标按钮

signal menu_clicked(menu_id: String)

const ICON_PATHS = {
	"map": "res://assets/cn/ui/icon_map.png",
	"talk": "res://assets/cn/ui/icon_talk.png",
	"move": "res://assets/cn/ui/icon_move.png",
	"search": "res://assets/cn/ui/icon_search.png",
	"notebook": "res://assets/cn/ui/icon_notebook.png",
	"accuse": "res://assets/cn/ui/icon_accuse.png",
}

const LABELS = {
	"map": "地  图",
	"talk": "对  话",
	"move": "移  动",
	"search": "探  索",
	"notebook": "笔记本",
	"accuse": "指  证",
}

const ORDER = ["map", "talk", "move", "search", "notebook", "accuse"]


func _ready() -> void:
	_build()


func _build() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	for menu_id in ORDER:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 18)
		# 用 HBox 自己装图标+文字，避免 Button 内置 icon 把按钮撑高
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_BEGIN
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_theme_constant_override("separation", 10)
		hb.anchor_right = 1.0
		hb.anchor_bottom = 1.0
		hb.offset_left = 12
		hb.offset_right = -8
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE)
		hb.offset_left = 10
		btn.add_child(hb)
		
		var icon_path: String = ICON_PATHS.get(menu_id, "")
		if ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.texture = load(icon_path)
			icon.custom_minimum_size = Vector2(36, 36)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_child(icon)
		
		var lbl := Label.new()
		lbl.text = LABELS.get(menu_id, menu_id)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(lbl)
		
		btn.pressed.connect(_on_pressed.bind(menu_id))
		vbox.add_child(btn)


func _on_pressed(menu_id: String) -> void:
	menu_clicked.emit(menu_id)
