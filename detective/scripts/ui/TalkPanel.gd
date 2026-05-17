extends Control
## 对话面板：列出当前地点所有 NPC，点击发起对话

signal close_requested()
signal npc_selected(npc_id: String)

@onready var list_vbox: VBoxContainer = $Panel/VBox/List
@onready var title_label: Label = $Panel/VBox/Title
@onready var close_btn: Button = $Panel/VBox/CloseBtn


func _ready() -> void:
	close_btn.pressed.connect(func(): close_requested.emit())
	var loc := GameManager.current_location_data()
	title_label.text = "── 此处之人 ──"
	# 用 schedule 取当前时段实际在此地点的 NPC（动态），缺 schedule 则回退到静态
	var active_npcs: Array = GameManager.get_active_npcs_at(GameManager.current_location)
	if active_npcs.is_empty():
		active_npcs = loc.get("npcs", [])
	for npc_id in active_npcs:
		var data := GameManager.get_npc_data(npc_id)
		list_vbox.add_child(_make_npc_button(npc_id, data))


func _make_npc_button(npc_id: String, data: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 88)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): npc_selected.emit(npc_id))
	
	# 用 HBox 内嵌头像+文字（mouse_filter=ignore 让点击穿透到 Button）
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 16)
	hb.anchor_right = 1.0
	hb.anchor_bottom = 1.0
	hb.offset_left = 12
	hb.offset_top = 6
	hb.offset_right = -12
	hb.offset_bottom = -6
	btn.add_child(hb)
	
	# 头像：用立绘头部区域裁剪（通过 AssetResolver 解析，兼容 casting 演员制）
	var portrait_path: String = AssetResolver.get_portrait(npc_id, GameManager.npcs_data)
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var tex: Texture2D = load(portrait_path)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(72, 72)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# 找人物的实际包围盒（避免居底对齐的透明 PNG 裁到画布顶部空白）
		var rect: Rect2 = _compute_head_region(tex)
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = rect
		icon.texture = atlas
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(icon)
	
	# 文字（角色姓名/头衔走 AssetResolver，casting 优先于 npcs 字段）
	var role_info: Dictionary = AssetResolver.get_role_info(npc_id, GameManager.npcs_data)
	var role_name: String = role_info.get("name", "")
	if role_name == "":
		role_name = data.get("name", npc_id)
	var role_title: String = role_info.get("title", "")
	if role_title == "":
		role_title = data.get("title", "")
	var lbl := Label.new()
	lbl.text = "%s   （%s）" % [role_name, role_title]
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(lbl)
	
	return btn


## 找立绘的人物头部正方形区域。
## 先求 alpha>10 的包围盒，从盒顶取 ~40% 高度作为头部正方形；
## 若立绘无透明像素（旧版整张实心 PNG 兼容），回退到画布上方裁切。
static func _compute_head_region(tex: Texture2D) -> Rect2:
	if tex == null:
		return Rect2(0, 0, 1, 1)
	var img: Image = tex.get_image()
	if img == null:
		return Rect2(0, 0, tex.get_size().x, tex.get_size().y)
	var w: int = img.get_width()
	var h: int = img.get_height()
	# 扫描非透明像素的包围盒
	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1
	# 性能：只采样网格点（每 4 像素）足够找包围盒
	var step: int = 4
	var y: int = 0
	while y < h:
		var x: int = 0
		while x < w:
			if img.get_pixel(x, y).a > 0.04:
				if x < min_x: min_x = x
				if y < min_y: min_y = y
				if x > max_x: max_x = x
				if y > max_y: max_y = y
			x += step
		y += step
	# 整张实心（无透明）或无可见像素 → 回退
	var has_alpha_region: bool = (max_x >= 0) and (min_x > 0 or min_y > 0 or max_x < w - 1 or max_y < h - 1)
	if not has_alpha_region:
		# 旧实心立绘：仍按画布顶部 36% 裁
		var fh: float = float(h) * 0.36
		return Rect2((w - fh) * 0.5, h * 0.02, fh, fh)
	# 包围盒高度，取顶部约 42% 作为头部
	var bbox_h: float = float(max_y - min_y + 1)
	var bbox_w: float = float(max_x - min_x + 1)
	var crop_h: float = bbox_h * 0.42
	# 头像取正方形，但限制不超过包围盒宽度
	var crop_size: float = min(crop_h, bbox_w)
	# 留少量顶部安全边
	var crop_y: float = float(min_y) - bbox_h * 0.02
	if crop_y < 0:
		crop_y = 0
	# 水平居中于包围盒中线
	var center_x: float = float(min_x + max_x) * 0.5
	var crop_x: float = center_x - crop_size * 0.5
	if crop_x < 0:
		crop_x = 0
	if crop_x + crop_size > w:
		crop_x = w - crop_size
	return Rect2(crop_x, crop_y, crop_size, crop_size)

