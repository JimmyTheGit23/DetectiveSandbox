extends Control
## NpcSceneLayer
##
## 场景底部的"在场 NPC 头像指示条"。
## 以头像 + 名字的方式显示当前地点的 NPC，
## 不破坏场景构图，同时让玩家一眼知道场景里有谁。
##
## 设计：
##   - 头像为 64x64 的圆形裁剪，显示图片顶部（脸部）
##   - 底部居中排列，带半透明暗色背景条
##   - 对话/叙述进行时隐藏，结束后恢复

const AVATAR_SIZE := 64.0         # 头像尺寸（正方形）
const AVATAR_GAP := 20.0          # 头像间距
const BAR_HEIGHT := 80.0          # 指示条高度
const BAR_BOTTOM_MARGIN := 4.0    # 距离底边距离
const NAME_FONT_SIZE := 14
const BAR_RIGHT_OFFSET := 220.0   # 右侧菜单宽度，场景可视区 = viewport.x - 此值

var _bar: PanelContainer
var _hbox: HBoxContainer
var _visible_items: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_bar()


func _build_bar() -> void:
	# 底部指示条容器
	_bar = PanelContainer.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 半透明深色背景
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.02, 0.55)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 4
	_bar.add_theme_stylebox_override("panel", style)
	add_child(_bar)

	# 水平布局
	_hbox = HBoxContainer.new()
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.add_theme_constant_override("separation", int(AVATAR_GAP))
	_bar.add_child(_hbox)

	_bar.visible = false


## 由 MainGame 在地点切换时调用。刷新场景中的 NPC 列表。
func refresh_npcs(location_id: String) -> void:
	_clear()
	var gm := get_node_or_null("/root/GameManager") as Node
	if gm == null:
		return
	if gm.current_state != gm.STATE_PLAYING:
		return

	var npcs: Array = gm.get_active_npcs_at(location_id)
	if npcs.is_empty():
		_bar.visible = false
		return

	var resolver := get_node_or_null("/root/AssetResolver") as Node

	for npc_id in npcs:
		var nid_s := str(npc_id)
		if nid_s == "lu_zhao":
			continue
		var portrait_path: String = ""
		if resolver:
			portrait_path = resolver.get_portrait(nid_s, gm.npcs_data)
		if portrait_path == "":
			continue
		var role: Dictionary = resolver.get_role_info(nid_s, gm.npcs_data) if resolver else {}
		var display_name: String = role.get("name", nid_s)

		var item := _create_avatar_item(portrait_path, display_name)
		if item:
			_hbox.add_child(item)
			_visible_items.append(item)

	if _visible_items.is_empty():
		_bar.visible = false
		return

	_bar.visible = true
	_position_bar()

	# 淡入动画
	_bar.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_bar, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)


## 创建单个头像+名字的 VBoxContainer
func _create_avatar_item(portrait_path: String, display_name: String) -> VBoxContainer:
	# 优先加载预裁剪的头像（avatars 目录）
	var avatar_path := portrait_path.replace("/portraits/", "/portraits/avatars/")
	var tex: Texture2D = null
	if ResourceLoader.exists(avatar_path):
		tex = load(avatar_path) as Texture2D
	if tex == null:
		# 回退到原始立绘
		tex = load(portrait_path) as Texture2D
	if tex == null:
		return null

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)

	# 头像图片——直接显示预裁剪的正方形头像
	var avatar := TextureRect.new()
	avatar.texture = tex
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.custom_minimum_size = Vector2(AVATAR_SIZE, AVATAR_SIZE)
	avatar.size = Vector2(AVATAR_SIZE, AVATAR_SIZE)
	vbox.add_child(avatar)

	# 名字标签
	var lbl := Label.new()
	lbl.text = display_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75, 0.9))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.custom_minimum_size = Vector2(AVATAR_SIZE + 8, 0)
	vbox.add_child(lbl)

	return vbox


## 定位底部指示条（居中在场景可视区底部）
func _position_bar() -> void:
	await get_tree().process_frame  # 等子节点计算完尺寸
	var vp := get_viewport_rect().size
	var scene_w := vp.x - BAR_RIGHT_OFFSET
	var bar_w := _bar.size.x
	_bar.position = Vector2(
		(scene_w - bar_w) * 0.5,
		vp.y - _bar.size.y - BAR_BOTTOM_MARGIN
	)


func _clear() -> void:
	for child in _hbox.get_children():
		child.queue_free()
	_visible_items.clear()


## 对话/叙述开始时隐藏
func hide_npcs() -> void:
	_bar.visible = false


## 对话/叙述结束后恢复
func show_npcs() -> void:
	if not _visible_items.is_empty():
		_bar.visible = true

