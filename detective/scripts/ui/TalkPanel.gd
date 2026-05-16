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
	for npc_id in loc.get("npcs", []):
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
	
	# 头像：用立绘头部区域裁剪
	var portrait_path: String = data.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var tex: Texture2D = load(portrait_path)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(72, 72)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# 通过 AtlasTexture 仅裁取头部区域（上方 1/3）
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		var tex_size := tex.get_size()
		# 取头部：从 y=tex_size.y * 0.02 开始，高 tex_size.y * 0.35；宽方向居中正方形
		var crop_h: float = tex_size.y * 0.36
		var crop_w: float = crop_h  # 正方形
		var crop_x: float = (tex_size.x - crop_w) / 2.0
		var crop_y: float = tex_size.y * 0.02
		atlas.region = Rect2(crop_x, crop_y, crop_w, crop_h)
		icon.texture = atlas
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(icon)
	
	# 文字
	var lbl := Label.new()
	lbl.text = "%s   （%s）" % [data.get("name", npc_id), data.get("title", "")]
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(lbl)
	
	return btn
