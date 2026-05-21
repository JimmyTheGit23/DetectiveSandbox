extends PanelContainer
## 右侧主菜单：图标按钮，移动按钮仅在当前地点有 sub_locations 时显示。

signal menu_clicked(menu_id: String)

const ICON_PATHS = {
	"map": "res://assets/cn/ui/icon_map.png",
	"talk": "res://assets/cn/ui/icon_talk.png",
	"move": "res://assets/cn/ui/icon_move.png",
	"search": "res://assets/cn/ui/icon_search.png",
	"notebook": "res://assets/cn/ui/icon_notebook.png",
	"discuss": "res://assets/cn/ui/icon_discuss.png",
	"accuse": "res://assets/cn/ui/icon_accuse.png",
	"settings": "res://assets/cn/ui/icon_settings.png",
}

const LABELS = {
	"map": "地  图",
	"talk": "对  话",
	"move": "移  动",
	"search": "探  索",
	"notebook": "笔记本",
	"discuss": "讨  论",
	"accuse": "指  证",
	"settings": "设  置",
}

const ORDER = ["map", "talk", "move", "search", "notebook", "discuss", "settings"]

var _btn_map: Dictionary = {}  # menu_id -> Button


func _ready() -> void:
	_build()
	# 监听地点变化以刷新按钮显隐
	if GameManager.location_changed.is_connected(_on_location_changed):
		pass
	else:
		GameManager.location_changed.connect(_on_location_changed)
	# 读档/返回游戏时 MainGame 可能直接调用 _on_location_changed 而不 emit signal；
	# 菜单重新显示时也刷新一次，避免移动按钮停留在旧地点状态。
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("refresh_visibility")


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
		# 用 HBox 自己装图标+文字
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
		_btn_map[menu_id] = btn
	_refresh_visibility()


func _on_pressed(menu_id: String) -> void:
	# 检查面板是否锁定
	if not GameManager.is_panel_unlocked(menu_id):
		var hint := GameManager.get_panel_locked_hint(menu_id)
		if hint != "":
			_flash_locked_hint(hint)
		return
	menu_clicked.emit(menu_id)


func _flash_locked_hint(text: String) -> void:
	# 在菜单上方短暂显示提示
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1, 0.7, 0.4, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.position = Vector2(-200, -30)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.custom_minimum_size = Vector2(220, 0)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)


func _on_location_changed(_loc_id: String) -> void:
	refresh_visibility()


func _on_visibility_changed() -> void:
	if visible:
		refresh_visibility()


## 公开刷新入口：读档、切地点、菜单重新显示时都可调用
func refresh_visibility() -> void:
	_refresh_visibility()


## 刷新按钮显隐：move 按钮只在当前地点有 sub_locations 时显示
## discuss 按钮只在有助手时显示
## 渐进系统：锁定面板灰显示
func _refresh_visibility() -> void:
	if not _btn_map.has("move"):
		return
	var loc: Dictionary = GameManager.current_location_data()
	var subs: Array = loc.get("sub_locations", [])
	_btn_map["move"].visible = subs.size() > 0
	# 讨论按钮：助手系统在场时才显示
	if _btn_map.has("discuss"):
		var cs = get_node_or_null("/root/CompanionService")
		_btn_map["discuss"].visible = cs != null and cs.has_method("has_companion") and cs.has_companion()
	# 渐进系统：对锁定面板设灰色透明度
	for menu_id in ["accuse"]:
		if _btn_map.has(menu_id):
			var unlocked := GameManager.is_panel_unlocked(menu_id)
			_btn_map[menu_id].modulate.a = 1.0 if unlocked else 0.45
