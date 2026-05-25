extends Control
## NpcSceneLayer
##
## 场景中NPC的常驻立绘显示。
## 进入有NPC的场景时，在画面中央显示该NPC的大立绘（与对话时相同的位置和风格）。
## 一个场景只显示一个NPC。
## 对话/叙述/探索时隐藏，结束后恢复。

var _portrait: TextureRect
var _current_npc_id: String = ""
var _portrait_tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_portrait()


func _build_portrait() -> void:
	_portrait = TextureRect.new()
	_portrait.name = "SceneNpcPortrait"
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 角色立绘位置：居中、贴底（下半身被对话框自然遮挡，参考逆转裁判布局）
	_portrait.anchor_left = 0.5
	_portrait.anchor_right = 0.5
	_portrait.anchor_bottom = 1.0
	_portrait.offset_left = -320.0
	_portrait.offset_top = 60.0
	_portrait.offset_right = 320.0
	_portrait.offset_bottom = 0.0
	# 应用边缘渐隐 shader（底部不渐隐，由对话框自然遮挡）
	var shader = load("res://assets/cn/portrait_fade.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("fade_bottom", 0.0)
		mat.set_shader_parameter("fade_top", 0.05)
		mat.set_shader_parameter("fade_left", 0.10)
		mat.set_shader_parameter("fade_right", 0.10)
		_portrait.material = mat
	_portrait.visible = false
	add_child(_portrait)


## 由 MainGame 在地点切换时调用。显示当前场景的 NPC 立绘。
func refresh_npcs(location_id: String) -> void:
	if GameManager == null:
		_hide_portrait()
		return
	# 允许在 PLAYING 和 TRANSITION 状态下显示NPC（时间过场期间也保持显示）
	if GameManager.current_state != GameManager.STATE_PLAYING and GameManager.current_state != GameManager.STATE_TRANSITION:
		_hide_portrait()
		return

	var npcs: Array = GameManager.get_active_npcs_at(location_id)
	# 过滤掉主角自身
	var target_npc_id: String = ""
	for npc_id in npcs:
		var nid := str(npc_id)
		if nid == "lu_zhao":
			continue
		target_npc_id = nid
		break  # 只取第一个 NPC

	if target_npc_id == "":
		_hide_portrait()
		return

	var portrait_path: String = AssetResolver.get_portrait(target_npc_id, GameManager.npcs_data)
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		_hide_portrait()
		return

	_current_npc_id = target_npc_id
	_portrait.texture = load(portrait_path)
	_show_portrait()


func _show_portrait() -> void:
	if _portrait.visible and _portrait.modulate.a > 0.9:
		return
	_portrait.visible = true
	if _portrait_tween != null and _portrait_tween.is_valid():
		_portrait_tween.kill()
	_portrait.pivot_offset = _portrait.size / 2.0
	_portrait.modulate = Color(1, 1, 1, 0)
	_portrait.scale = Vector2(0.95, 0.95)
	_portrait_tween = create_tween()
	_portrait_tween.set_parallel(true)
	_portrait_tween.tween_property(_portrait, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_portrait_tween.tween_property(_portrait, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _hide_portrait() -> void:
	_current_npc_id = ""
	if not _portrait.visible:
		return
	if _portrait_tween != null and _portrait_tween.is_valid():
		_portrait_tween.kill()
	_portrait_tween = create_tween()
	_portrait_tween.tween_property(_portrait, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_portrait_tween.tween_callback(func(): _portrait.visible = false)


## 对话/叙述/探索开始时隐藏
func hide_npcs() -> void:
	if _portrait_tween != null and _portrait_tween.is_valid():
		_portrait_tween.kill()
	_portrait.modulate.a = 0.0
	_portrait.visible = false


## 对话/叙述/探索结束后恢复
func show_npcs() -> void:
	if _current_npc_id != "":
		_show_portrait()


## 讨论模式：切换立绘为助手
var _saved_npc_id: String = ""
var _saved_texture: Texture2D = null

func show_companion() -> void:
	""" 先隐藏原 NPC 立绘，再显示助手立绘（居中） """
	_saved_npc_id = _current_npc_id
	_saved_texture = _portrait.texture
	# 先隐藏当前 NPC
	if _portrait.visible:
		if _portrait_tween != null and _portrait_tween.is_valid():
			_portrait_tween.kill()
		_portrait.modulate.a = 0.0
		_portrait.visible = false
	# 加载助手立绘并显示
	var portrait_path: String = CompanionService.get_companion_portrait()
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		return
	_portrait.texture = load(portrait_path)
	_current_npc_id = "__companion__"
	_show_portrait()


func restore_npc() -> void:
	""" 隐藏助手立绘，恢复原 NPC 立绘 """
	# 先隐藏当前（助手）
	if _portrait.visible:
		if _portrait_tween != null and _portrait_tween.is_valid():
			_portrait_tween.kill()
		_portrait.modulate.a = 0.0
		_portrait.visible = false
	# 恢复 NPC
	_current_npc_id = _saved_npc_id
	if _saved_texture != null:
		_portrait.texture = _saved_texture
		_saved_texture = null
		_saved_npc_id = ""
		_show_portrait()
	else:
		_saved_npc_id = ""
