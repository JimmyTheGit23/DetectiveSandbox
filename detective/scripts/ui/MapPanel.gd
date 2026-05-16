extends Control
## 全镇地图面板：展示地图插图 + 可点击地点按钮 → 选择目的地

signal close_requested()
signal location_selected(location_id: String)

# 地图上各地点的相对坐标（基于 1280x720 viewport）
const MAP_POSITIONS = {
	"post_station": Vector2(580, 540),
	"shen_residence": Vector2(540, 380),
	"yamen": Vector2(650, 290),
	"spring_wind_tower": Vector2(820, 290),
	"guanyin_temple": Vector2(560, 130),
	"market": Vector2(310, 310),
}

@onready var map_image: TextureRect = $Panel/MapImage
@onready var points_layer: Control = $Panel/Points
@onready var info_panel: PanelContainer = $Panel/InfoPanel
@onready var info_label: RichTextLabel = $Panel/InfoPanel/InfoLabel
@onready var close_btn: Button = $Panel/CloseBtn


func _ready() -> void:
	close_btn.pressed.connect(func(): close_requested.emit())
	map_image.texture = load("res://assets/cn/scenes/town_map.png")
	info_label.text = "[center][color=#fae9b3]点击地图上的标记前往。跨地点移动消耗一个时段。[/color][/center]"
	_build_points()


func _build_points() -> void:
	for child in points_layer.get_children():
		child.queue_free()
	for loc_id in MAP_POSITIONS.keys():
		var pos: Vector2 = MAP_POSITIONS[loc_id]
		var data = GameManager.get_location_data(loc_id)
		var visited: bool = GameManager.visited_locations.has(loc_id)
		var is_current: bool = (loc_id == GameManager.current_location)
		
		# 标记点：用一个 Control 自绘圆 + 文字 + 点击区域
		var marker := _MapMarker.new()
		marker.position = pos
		marker.location_name = data.get("name", loc_id)
		marker.is_current = is_current
		marker.is_visited = visited
		marker.location_id = loc_id
		marker.clicked.connect(_on_point_clicked)
		points_layer.add_child(marker)


func _on_point_clicked(loc_id: String) -> void:
	if loc_id == GameManager.current_location:
		info_label.text = "[center][color=#ffaa88]你已经在 %s。[/color][/center]" % GameManager.get_location_data(loc_id).get("name", "")
		return
	location_selected.emit(loc_id)


# 自定义标记点：圆形按钮 + 标牌名字
class _MapMarker extends Control:
	signal clicked(loc_id: String)
	var location_name: String = ""
	var location_id: String = ""
	var is_current: bool = false
	var is_visited: bool = false
	var _hover: bool = false
	const RADIUS := 18.0
	
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		# 把整个 Control 当成点击热区
		size = Vector2(160, 60)
		position -= Vector2(RADIUS, RADIUS)  # 让 pos 表示圆心
	
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 仅在圆心附近点击才触发
			var local: Vector2 = event.position
			if local.distance_to(Vector2(RADIUS, RADIUS)) <= RADIUS + 6:
				clicked.emit(location_id)
				accept_event()
	
	func _process(_delta: float) -> void:
		var mp := get_local_mouse_position()
		var new_hover := mp.distance_to(Vector2(RADIUS, RADIUS)) <= RADIUS + 6
		if new_hover != _hover:
			_hover = new_hover
			queue_redraw()
	
	func _draw() -> void:
		var center := Vector2(RADIUS, RADIUS)
		# 颜色配置
		var bg_color: Color
		var border_color: Color
		var glyph_color: Color
		if is_current:
			bg_color = Color(0.85, 0.18, 0.18, 0.95)
			border_color = Color(1, 0.9, 0.6, 1)
			glyph_color = Color(1, 1, 0.9, 1)
		elif is_visited:
			bg_color = Color(0.95, 0.78, 0.35, 0.95)
			border_color = Color(0.45, 0.25, 0.1, 1)
			glyph_color = Color(0.2, 0.12, 0.05, 1)
		else:
			bg_color = Color(0.95, 0.94, 0.85, 0.92)
			border_color = Color(0.45, 0.32, 0.18, 1)
			glyph_color = Color(0.35, 0.22, 0.1, 1)
		# 悬停高亮
		if _hover and not is_current:
			bg_color = bg_color.lightened(0.18)
		# 阴影
		draw_circle(center + Vector2(2, 3), RADIUS, Color(0, 0, 0, 0.4))
		# 主圆
		draw_circle(center, RADIUS, bg_color)
		# 边框
		draw_arc(center, RADIUS, 0, TAU, 32, border_color, 2.5, true)
		# 中心点字符（当前位置画一个旗帜符号；其他画一个圆点）
		var fnt := ThemeDB.fallback_font
		if is_current:
			draw_string(fnt, center + Vector2(-7, 7), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, glyph_color)
		else:
			draw_circle(center, 5, glyph_color)
		
		# 名字标牌：在标记右侧
		var label_pos := Vector2(RADIUS * 2 + 8, RADIUS - 8)
		var label_size := Vector2(120, 22)
		# 标牌背景
		draw_rect(Rect2(label_pos, label_size), Color(0.96, 0.93, 0.82, 0.92), true)
		draw_rect(Rect2(label_pos, label_size), Color(0.45, 0.3, 0.15, 1), false, 1.5)
		# 文字
		var text_color := Color(0.15, 0.1, 0.05, 1) if is_visited or is_current else Color(0.4, 0.3, 0.2, 1)
		draw_string(fnt, label_pos + Vector2(8, 17), location_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, text_color)
