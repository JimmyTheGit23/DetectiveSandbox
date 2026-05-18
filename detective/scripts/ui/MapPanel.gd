extends Control
## 全镇地图面板：展示地图插图 + 可点击地点按钮 → 选择目的地

signal close_requested()
signal location_selected(location_id: String)

# 地图上各案件地点的相对坐标（基于 1280x720 viewport）
const CASE_MAP_POSITIONS := {
	"linchuan_inn": {
		"post_station": Vector2(580, 540),
		"shen_residence": Vector2(540, 380),
		"yamen": Vector2(650, 290),
		"spring_wind_tower": Vector2(820, 290),
		"guanyin_temple": Vector2(560, 130),
		"market": Vector2(310, 310),
	},
	"xunyang_pavilion": {
		"yamen": Vector2(610, 270),
		"pavilion_main": Vector2(850, 300),
		"convent": Vector2(650, 160),
		"marketplace": Vector2(330, 330),
		"silk_shop": Vector2(280, 460),
	},
}

# 未配置坐标的新案件：按网格临时排布，避免英文 id 漏到界面上。
const FALLBACK_POSITIONS := [
	Vector2(330, 330), Vector2(610, 270), Vector2(850, 300),
	Vector2(540, 500), Vector2(780, 500), Vector2(650, 160),
	Vector2(440, 170), Vector2(900, 460),
]

@onready var map_image: TextureRect = $Panel/MapImage
@onready var points_layer: Control = $Panel/Points
@onready var info_panel: PanelContainer = $Panel/InfoPanel
@onready var info_label: RichTextLabel = $Panel/InfoPanel/InfoLabel
@onready var close_btn: Button = $Panel/CloseBtn


func _ready() -> void:
	close_btn.pressed.connect(func(): close_requested.emit())
	map_image.texture = load("res://assets/cn/scenes/town_map.png")
	info_label.text = "[center][color=#fae9b3]点击标记前往 · 数字=在场人数[/color][/center]"
	_build_points()


func _build_points() -> void:
	for child in points_layer.get_children():
		child.queue_free()
	var loc_ids := _case_location_ids()
	if loc_ids.is_empty():
		info_label.text = "[center][color=#ffaa88]当前案件还没有地点数据。[/color][/center]"
		return
	var configured: Dictionary = CASE_MAP_POSITIONS.get(GameManager.ACTIVE_CASE, {})
	var markers: Array = []
	for i in range(loc_ids.size()):
		var loc_id: String = loc_ids[i]
		var data := GameManager.get_location_data(loc_id)
		# 跳过有 parent 的子地点——它们不在大地图上显示
		if data.get("parent", "") != "":
			continue
		var pos := _position_for(loc_id, i, configured)
		# 判断"当前是否在此地或此地的子地点内"
		var is_current: bool = _is_current_or_child(loc_id, data)
		var visited: bool = GameManager.visited_locations.has(loc_id)
		# 如果是 hub，检查子地点是否有被访问过的
		if not visited and data.get("is_hub", false):
			for child_id in data.get("children", []):
				if GameManager.visited_locations.has(child_id):
					visited = true
					break
		# 汇总 NPC：自己 + 所有 children 的 NPC
		var all_npc_names: Array = []
		var child_location_names: Array = []  # 用于 hover 展示子地点
		_collect_npcs_for(loc_id, all_npc_names)
		if data.get("is_hub", false):
			for child_id in data.get("children", []):
				_collect_npcs_for(child_id, all_npc_names)
				var child_data := GameManager.get_location_data(child_id)
				var child_name: String = child_data.get("name", child_id)
				child_location_names.append(child_name)
		
		var marker := _MapMarker.new()
		marker.position = pos
		# hub 用 map_name（如"浔阳楼"），普通地点用 name
		marker.location_name = data.get("map_name", data.get("name", loc_id))
		marker.is_current = is_current
		marker.is_visited = visited
		# hub 的点击目标是自身（正厅），会被 _on_point_clicked 处理
		marker.location_id = loc_id
		marker.npc_names = all_npc_names
		marker.child_location_names = child_location_names
		marker.clicked.connect(_on_point_clicked)
		points_layer.add_child(marker)
		markers.append(marker)
	_resolve_label_directions(markers)


## 收集某地点当前时段的 NPC 名字（排除玩家自己）
func _collect_npcs_for(loc_id: String, out: Array) -> void:
	var npcs_here: Array = GameManager.get_active_npcs_at(loc_id)
	for nid in npcs_here:
		var nid_s := str(nid)
		if nid_s == "lu_zhao":
			continue
		var nm: String = GameManager.get_npc_display_name(nid_s)
		if not out.has(nm):
			out.append(nm)


## 判断玩家当前是否"在此地点或其子地点内"
func _is_current_or_child(loc_id: String, data: Dictionary) -> bool:
	if GameManager.current_location == loc_id:
		return true
	if data.get("is_hub", false):
		for child_id in data.get("children", []):
			if GameManager.current_location == child_id:
				return true
	return false


## 把所有 marker 的标牌方向（right/left）按碰撞情况调整，避免互相遮挡。
func _resolve_label_directions(markers: Array) -> void:
	# 第一遍：根据屏幕宽度做"贴右边就左展开"的硬约束
	var map_w: float = points_layer.size.x
	if map_w <= 0:
		map_w = 1280.0  # fallback
	for m in markers:
		var marker_node: Control = m as Control
		if marker_node == null:
			continue
		var right_edge: float = marker_node.position.x + _MapMarker.RADIUS * 2.0 + 8.0 + _MapMarker.LABEL_MAX_W
		if right_edge > map_w - 16.0:
			marker_node.set("label_side", -1)
	# 第二遍：检测彼此重叠，重叠就翻到对侧
	for i in range(markers.size()):
		var a: Control = markers[i] as Control
		if a == null:
			continue
		var a_rect: Rect2 = a.call("compute_label_rect_world")
		for j in range(markers.size()):
			if i == j:
				continue
			var b: Control = markers[j] as Control
			if b == null:
				continue
			var b_point: Vector2 = b.position
			if a_rect.has_point(b_point):
				var cur: int = int(a.get("label_side"))
				a.set("label_side", -cur)
				a_rect = a.call("compute_label_rect_world")
				if a_rect.has_point(b_point):
					a.set("label_side", cur)
					a_rect = a.call("compute_label_rect_world")
				break
	# 通知所有 marker 重新绘制
	for m in markers:
		var mc: Control = m as Control
		if mc != null:
			mc.queue_redraw()


func _case_location_ids() -> Array:
	var ids: Array = []
	for loc_id in GameManager.locations_data.keys():
		var data := GameManager.get_location_data(loc_id)
		if data.is_empty():
			continue
		if not GameManager.is_location_unlocked(loc_id):
			continue
		ids.append(loc_id)
	ids.sort()
	if ids.has(GameManager.current_location):
		ids.erase(GameManager.current_location)
		ids.insert(0, GameManager.current_location)
	return ids


func _position_for(loc_id: String, index: int, configured: Dictionary) -> Vector2:
	if configured.has(loc_id):
		return configured[loc_id]
	return FALLBACK_POSITIONS[index % FALLBACK_POSITIONS.size()]


func _display_name(loc_id: String, data: Dictionary) -> String:
	var display_name: String = data.get("name", "")
	if display_name != "":
		return display_name
	return loc_id.replace("_", " ").capitalize()


func _on_point_clicked(loc_id: String) -> void:
	var data := GameManager.get_location_data(loc_id)
	# 如果点的是 hub 且玩家已在其内部（含子地点），提示
	if _is_current_or_child(loc_id, data):
		var name_str: String = data.get("map_name", data.get("name", loc_id))
		info_label.text = "[center][color=#ffaa88]你已经在 %s 范围内。使用【移动】在内部走动。[/color][/center]" % name_str
		return
	location_selected.emit(loc_id)


# ─── 自定义标记点：圆点 + 名片标牌 + 人数徽章 + 悬浮人名展开 ───
class _MapMarker extends Control:
	signal clicked(loc_id: String)
	var location_name: String = ""
	var location_id: String = ""
	var is_current: bool = false
	var is_visited: bool = false
	var npc_names: Array = []
	var child_location_names: Array = []  # hub 的子地点名列表
	var _hover: bool = false
	# +1 = 标牌在圆点右侧（默认），-1 = 在左侧
	var label_side: int = 1
	const RADIUS := 18.0
	const LABEL_H := 22.0
	const LABEL_MAX_W := 150.0
	const LABEL_GAP := 8.0
	const BADGE_RADIUS := 10.0
	const NAME_BOX_LINE_H := 18.0
	# 锚点偏移：节点局部坐标系下，圆点中心位置；node 的 (0,0) 在圆点左上
	const PIN_CENTER := Vector2(RADIUS, RADIUS)
	
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		# 节点 size 留余量给左右展开标牌 + 下方人名条；hover 时还会 move_to_front
		size = Vector2(360, 220)
		# 居中：节点左上 = 实际坐标 - 圆点偏移；为了左展开也能容纳，水平再左移 LABEL_MAX_W
		position -= Vector2(RADIUS + LABEL_MAX_W, RADIUS)
	
	## 计算标牌文字实际宽度（用 ThemeDB fallback font），避免固定 150px 占位
	func _label_text_width() -> float:
		var fnt := ThemeDB.fallback_font
		var sz: Vector2 = fnt.get_string_size(location_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		return clamp(sz.x + 18.0, 56.0, LABEL_MAX_W)
	
	## 本节点局部坐标系下的标牌矩形
	func _label_rect_local() -> Rect2:
		var w := _label_text_width()
		var y := PIN_CENTER.y - LABEL_H * 0.5
		var x: float
		if label_side > 0:
			x = PIN_CENTER.x + RADIUS + LABEL_GAP
		else:
			x = PIN_CENTER.x - RADIUS - LABEL_GAP - w
		return Rect2(Vector2(x, y), Vector2(w, LABEL_H))
	
	## 屏幕（points_layer）坐标系下的标牌矩形，给外部碰撞检测用
	func compute_label_rect_world() -> Rect2:
		var r := _label_rect_local()
		return Rect2(r.position + position, r.size)
	
	## 人数徽章中心点（与标牌方向无关，永远贴在圆点的"远离标牌一侧"上方，避免互相干扰）
	func _badge_center_local() -> Vector2:
		# 把徽章放在圆点的对侧上方：标牌在右 → 徽章在左上；标牌在左 → 徽章在右上
		if label_side > 0:
			return PIN_CENTER + Vector2(-RADIUS * 0.85, -RADIUS * 0.85)
		else:
			return PIN_CENTER + Vector2(RADIUS * 0.85, -RADIUS * 0.85)
	
	## 展开人名条的矩形（局部）
	func _name_box_rect_local() -> Rect2:
		var lr := _label_rect_local()
		var count := npc_names.size()
		var box_h: float = NAME_BOX_LINE_H * float(count) + 10.0
		return Rect2(lr.position + Vector2(0, lr.size.y + 4), Vector2(lr.size.x, box_h))
	
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var local: Vector2 = event.position
			if local.distance_to(PIN_CENTER) <= RADIUS + 6:
				clicked.emit(location_id); accept_event(); return
			if _label_rect_local().has_point(local):
				clicked.emit(location_id); accept_event(); return
			if local.distance_to(_badge_center_local()) <= BADGE_RADIUS + 4:
				clicked.emit(location_id); accept_event(); return
	
	func _process(_delta: float) -> void:
		var mp := get_local_mouse_position()
		var label_rect := _label_rect_local()
		var badge_c := _badge_center_local()
		var count := npc_names.size()
		var name_box_rect := Rect2(Vector2.ZERO, Vector2.ZERO)
		if count > 0:
			name_box_rect = _name_box_rect_local()
		var new_hover: bool = (
			mp.distance_to(PIN_CENTER) <= RADIUS + 6
			or label_rect.has_point(mp)
			or mp.distance_to(badge_c) <= BADGE_RADIUS + 4
			or (count > 0 and name_box_rect.has_point(mp))
		)
		if new_hover != _hover:
			_hover = new_hover
			queue_redraw()
			if _hover:
				var p := get_parent()
				if p:
					p.move_child(self, p.get_child_count() - 1)
	
	func _draw() -> void:
		var fnt := ThemeDB.fallback_font
		# ─── 主圆点 ───
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
		if _hover and not is_current:
			bg_color = bg_color.lightened(0.18)
		draw_circle(PIN_CENTER + Vector2(2, 3), RADIUS, Color(0, 0, 0, 0.4))
		draw_circle(PIN_CENTER, RADIUS, bg_color)
		draw_arc(PIN_CENTER, RADIUS, 0, TAU, 32, border_color, 2.5, true)
		if is_current:
			draw_string(fnt, PIN_CENTER + Vector2(-7, 7), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, glyph_color)
		else:
			draw_circle(PIN_CENTER, 5, glyph_color)
		
		# ─── 标牌（自适应方向 + 自适应宽度）───
		var lr := _label_rect_local()
		draw_rect(lr, Color(0.96, 0.93, 0.82, 0.92), true)
		draw_rect(lr, Color(0.45, 0.3, 0.15, 1), false, 1.5)
		# 标牌连接线：从圆点边缘画一段细线到标牌，视觉上"挂着"
		var line_color := Color(0.45, 0.3, 0.15, 0.85)
		var conn_y := PIN_CENTER.y
		if label_side > 0:
			draw_line(Vector2(PIN_CENTER.x + RADIUS, conn_y),
				Vector2(lr.position.x, conn_y), line_color, 1.5)
		else:
			draw_line(Vector2(PIN_CENTER.x - RADIUS, conn_y),
				Vector2(lr.position.x + lr.size.x, conn_y), line_color, 1.5)
		var text_color := Color(0.15, 0.1, 0.05, 1) if (is_visited or is_current) else Color(0.4, 0.3, 0.2, 1)
		draw_string(fnt, lr.position + Vector2(8, 17), location_name,
			HORIZONTAL_ALIGNMENT_LEFT, lr.size.x - 12, 16, text_color)
		
		# ─── 人数徽章（贴在圆点对侧上方）───
		var count := npc_names.size()
		if count > 0:
			var bc := _badge_center_local()
			var badge_bg := Color(0.55, 0.12, 0.12, 0.96)
			var badge_border := Color(1.0, 0.85, 0.4, 1.0)
			if _hover:
				badge_bg = badge_bg.lightened(0.18)
			draw_circle(bc + Vector2(1, 2), BADGE_RADIUS, Color(0, 0, 0, 0.4))
			draw_circle(bc, BADGE_RADIUS, badge_bg)
			draw_arc(bc, BADGE_RADIUS, 0, TAU, 24, badge_border, 1.4, true)
			var num_text: String = "9+" if count > 9 else str(count)
			draw_string(fnt, bc + Vector2(-5 if count > 9 else -3, 5), num_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.95, 0.85, 1))
		
		# ─── hover 时展开人名条（含子地点列表）───
		if _hover and (count > 0 or child_location_names.size() > 0):
			# 计算总行数 = 子地点行 + NPC 行
			var child_count := child_location_names.size()
			var total_lines: int = child_count + count
			if child_count > 0 and count > 0:
				total_lines += 1  # 分割行
			var nbr_pos := _label_rect_local().position + Vector2(0, _label_rect_local().size.y + 4)
			var box_h: float = NAME_BOX_LINE_H * float(total_lines) + 10.0
			var nbr := Rect2(nbr_pos, Vector2(_label_rect_local().size.x + 40, box_h))
			draw_rect(nbr, Color(0.18, 0.12, 0.08, 0.92), true)
			draw_rect(nbr, Color(0.95, 0.78, 0.35, 0.85), false, 1.2)
			draw_rect(Rect2(nbr.position + Vector2(4, 4), Vector2(2, nbr.size.y - 8)),
				Color(0.95, 0.78, 0.35, 0.7), true)
			var line_i: int = 0
			# 子地点
			for ci in range(child_count):
				var cn: String = str(child_location_names[ci])
				draw_string(fnt, nbr.position + Vector2(12, 6 + NAME_BOX_LINE_H * (line_i + 1) - 4),
					"▸ " + cn, HORIZONTAL_ALIGNMENT_LEFT, nbr.size.x - 16, 14,
					Color(0.75, 0.88, 0.65, 1.0))
				line_i += 1
			# 分割
			if child_count > 0 and count > 0:
				var sep_y: float = nbr.position.y + 6 + NAME_BOX_LINE_H * float(line_i) - 2
				draw_line(Vector2(nbr.position.x + 8, sep_y),
					Vector2(nbr.position.x + nbr.size.x - 8, sep_y),
					Color(0.95, 0.78, 0.35, 0.4), 1.0)
				line_i += 1
			# NPC
			for i in range(count):
				var nm: String = str(npc_names[i])
				draw_string(fnt, nbr.position + Vector2(12, 6 + NAME_BOX_LINE_H * (line_i + 1) - 4),
					"· " + nm, HORIZONTAL_ALIGNMENT_LEFT, nbr.size.x - 16, 14,
					Color(1.0, 0.94, 0.78, 1.0))
				line_i += 1
