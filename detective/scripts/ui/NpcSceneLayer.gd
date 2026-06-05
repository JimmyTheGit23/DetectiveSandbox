extends Control
## NpcSceneLayer
##
## 场景中NPC的常驻立绘显示。
## 进入有NPC的场景时，在画面中显示该地点的NPC立绘。
## - 1 个 NPC：居中、贴底（与对话时位置一致）
## - 2 个 NPC：左右分置
## - 3+ 个 NPC：左/中/右分置，立绘略缩小
## 对话/叙述/探索时隐藏，结束后恢复。

const SLOT_OFFSETS := {
	1: [Vector2(0, 0)],
	2: [Vector2(-260, 0), Vector2(260, 0)],
	3: [Vector2(-360, 0), Vector2(0, 0), Vector2(360, 0)],
}
const MULTI_HALF_WIDTH := 220.0  # 多 NPC 时单个立绘的半宽

var _portrait: TextureRect            # 单 NPC 模式的立绘（保持原行为）
var _portraits: Array = []            # 多 NPC 模式的立绘列表
var _current_npc_id: String = ""      # 单 NPC 模式当前 NPC
var _current_npc_ids: Array = []      # 多 NPC 模式所有 NPC
var _portrait_tween: Tween = null
var _multi_mode: bool = false


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
		mat.set_shader_parameter("fade_top", 0.0)
		mat.set_shader_parameter("fade_left", 0.10)
		mat.set_shader_parameter("fade_right", 0.10)
		_portrait.material = mat
	_portrait.visible = false
	add_child(_portrait)


func _build_multi_portrait(npc_id: String, slot_offset: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.name = "SceneNpcPortrait_" + npc_id
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.anchor_left = 0.5
	tr.anchor_right = 0.5
	tr.anchor_bottom = 1.0
	tr.offset_left = slot_offset.x - MULTI_HALF_WIDTH
	tr.offset_top = 140.0  # 多 NPC 模式下立绘略小，所以从更下方开始
	tr.offset_right = slot_offset.x + MULTI_HALF_WIDTH
	tr.offset_bottom = slot_offset.y
	var shader = load("res://assets/cn/portrait_fade.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("fade_bottom", 0.0)
		mat.set_shader_parameter("fade_top", 0.0)
		mat.set_shader_parameter("fade_left", 0.12)
		mat.set_shader_parameter("fade_right", 0.12)
		tr.material = mat
	tr.modulate = Color(1, 1, 1, 0)
	tr.visible = false
	add_child(tr)
	return tr


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
	var filtered: Array = []
	for npc_id in npcs:
		var nid := str(npc_id)
		if nid == "lu_zhao":
			continue
		filtered.append(nid)

	if filtered.is_empty():
		_hide_portrait()
		return

	# 单 NPC：保持原行为
	if filtered.size() == 1:
		_switch_to_single_mode()
		var portrait_path: String = AssetResolver.get_portrait(filtered[0], GameManager.npcs_data)
		if portrait_path == "" or not ResourceLoader.exists(portrait_path):
			_hide_portrait()
			return
		_current_npc_id = filtered[0]
		_portrait.texture = _load_portrait_texture(portrait_path)
		_show_portrait()
		return

	# 多 NPC：分槽位显示
	_switch_to_multi_mode(filtered)


func _switch_to_single_mode() -> void:
	_multi_mode = false
	_clear_multi_portraits()
	_current_npc_ids.clear()


func _switch_to_multi_mode(npc_ids: Array) -> void:
	_multi_mode = true
	# 隐藏单 NPC 立绘
	_portrait.visible = false
	_current_npc_id = ""
	_clear_multi_portraits()
	_current_npc_ids = npc_ids.duplicate()
	# 选择槽位（最多支持 3 个；超过 3 时取前 3 个）
	var n: int = min(npc_ids.size(), 3)
	var slots: Array = SLOT_OFFSETS.get(n, SLOT_OFFSETS[3])
	for i in range(n):
		var nid: String = npc_ids[i]
		var portrait_path: String = AssetResolver.get_portrait(nid, GameManager.npcs_data)
		if portrait_path == "" or not ResourceLoader.exists(portrait_path):
			continue
		var slot_offset: Vector2 = slots[i] if i < slots.size() else Vector2.ZERO
		var tr: TextureRect = _build_multi_portrait(nid, slot_offset)
		tr.texture = _load_portrait_texture(portrait_path)
		_portraits.append(tr)
	_show_multi_portraits()


func _clear_multi_portraits() -> void:
	for tr in _portraits:
		if is_instance_valid(tr):
			tr.queue_free()
	_portraits.clear()


func _show_portrait() -> void:
	if _portrait.visible and _portrait.modulate.a > 0.9:
		return
	# 如果有子面板活跃（探索/搜索/对峙等），不显示 NPC 立绘
	var main_scene := get_tree().current_scene
	if main_scene and main_scene.has_method("is_subpanel_active") and main_scene.is_subpanel_active():
		return
	_portrait.visible = true
	if _portrait_tween != null and _portrait_tween.is_valid():
		_portrait_tween.kill()
	_portrait.pivot_offset = _portrait.size / 2.0
	_portrait.modulate = Color(1, 1, 1, 0)
	var target_scale := Vector2(1.0, 1.0)
	_portrait.scale = Vector2(0.95, 0.95)
	_portrait_tween = create_tween()
	_portrait_tween.set_parallel(true)
	_portrait_tween.tween_property(_portrait, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_portrait_tween.tween_property(_portrait, "scale", target_scale, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _show_multi_portraits() -> void:
	var main_scene := get_tree().current_scene
	if main_scene and main_scene.has_method("is_subpanel_active") and main_scene.is_subpanel_active():
		return
	if _portrait_tween != null and _portrait_tween.is_valid():
		_portrait_tween.kill()
	_portrait_tween = create_tween()
	_portrait_tween.set_parallel(true)
	for tr in _portraits:
		tr.visible = true
		tr.modulate = Color(1, 1, 1, 0)
		_portrait_tween.tween_property(tr, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _hide_portrait() -> void:
	_current_npc_id = ""
	_current_npc_ids.clear()
	if _multi_mode:
		if _portrait_tween != null and _portrait_tween.is_valid():
			_portrait_tween.kill()
		_portrait_tween = create_tween()
		_portrait_tween.set_parallel(true)
		for tr in _portraits:
			_portrait_tween.tween_property(tr, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_portrait_tween.tween_callback(_clear_multi_portraits)
		_multi_mode = false
		return
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
	for tr in _portraits:
		if is_instance_valid(tr):
			tr.modulate.a = 0.0
			tr.visible = false


## 对话/叙述/探索结束后恢复
func show_npcs() -> void:
	if _multi_mode and not _portraits.is_empty():
		_show_multi_portraits()
		return
	if _current_npc_id != "":
		_show_portrait()


## 讨论模式：切换立绘为助手
var _saved_npc_id: String = ""
var _saved_texture: Texture2D = null
var _saved_multi_ids: Array = []

func show_companion() -> void:
	""" 先隐藏原 NPC 立绘，再显示助手立绘（居中） """
	# 多 NPC 模式：先全部隐藏并保存
	if _multi_mode:
		_saved_multi_ids = _current_npc_ids.duplicate()
		hide_npcs()
		_clear_multi_portraits()
		_multi_mode = false
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
	_portrait.texture = _load_portrait_texture(portrait_path)
	_current_npc_id = "__companion__"
	_show_portrait()


func _load_portrait_texture(path: String) -> Texture2D:
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D


func restore_npc() -> void:
	""" 隐藏助手立绘，恢复原 NPC 立绘 """
	# 先隐藏当前（助手）
	if _portrait.visible:
		if _portrait_tween != null and _portrait_tween.is_valid():
			_portrait_tween.kill()
		_portrait.modulate.a = 0.0
		_portrait.visible = false
	# 恢复多 NPC 模式
	if not _saved_multi_ids.is_empty():
		_switch_to_multi_mode(_saved_multi_ids)
		_saved_multi_ids.clear()
		_saved_npc_id = ""
		_saved_texture = null
		return
	# 恢复单 NPC
	_current_npc_id = _saved_npc_id
	if _saved_texture != null:
		_portrait.texture = _saved_texture
		_saved_texture = null
		_saved_npc_id = ""
		_show_portrait()
	else:
		_saved_npc_id = ""
