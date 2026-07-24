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
const PORTRAIT_CROP_PADDING_RATIO := 0.02
const PORTRAIT_CROP_MIN_PADDING := 8
const PORTRAIT_CROP_MIN_HEIGHT_RATIO := 0.78
const DEFAULT_SINGLE_PORTRAIT_FRAME := {
	"offset_left": -320.0,
	"offset_top": 60.0,
	"offset_right": 320.0,
	"offset_bottom": 0.0,
	"pivot_x": 320.0,
}
const DEFAULT_PORTRAIT_CROP_PADDING_RATIO := 0.02
const DEFAULT_PORTRAIT_CROP_MIN_PADDING := 8
const DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO := 0.78

var _portrait: TextureRect            # 单 NPC 模式的立绘（保持原行为）
var _portraits: Array = []            # 多 NPC 模式的立绘列表
var _current_npc_id: String = ""      # 单 NPC 模式当前 NPC
var _current_npc_ids: Array = []      # 多 NPC 模式所有 NPC
var _portrait_tween: Tween = null
var _multi_mode: bool = false
var _portrait_texture_cache: Dictionary = {}
var _current_portrait_display_scale: float = 1.0
var _current_portrait_pivot_y: float = 330.0
var _current_portrait_offset_y: float = 0.0
var _preview_active := false
var _single_portrait_frame: Dictionary = DEFAULT_SINGLE_PORTRAIT_FRAME.duplicate(true)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_refresh_single_portrait_frame()
	_build_portrait()


func _refresh_single_portrait_frame() -> void:
	_single_portrait_frame = DEFAULT_SINGLE_PORTRAIT_FRAME.duplicate(true)
	if AssetResolver != null and AssetResolver.has_method("get_center_portrait_standard_frame"):
		var resolved = AssetResolver.get_center_portrait_standard_frame()
		if typeof(resolved) == TYPE_DICTIONARY and not resolved.is_empty():
			_single_portrait_frame = resolved.duplicate(true)


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
	_portrait.offset_left = float(_single_portrait_frame.get("offset_left", -320.0))
	_portrait.offset_top = float(_single_portrait_frame.get("offset_top", 60.0))
	_portrait.offset_right = float(_single_portrait_frame.get("offset_right", 320.0))
	_portrait.offset_bottom = float(_single_portrait_frame.get("offset_bottom", 0.0))
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
		if AssetResolver != null and AssetResolver.has_method("is_center_npc_enabled") and not AssetResolver.is_center_npc_enabled(nid):
			continue
		filtered.append(nid)

	_preview_active = false
	if filtered.is_empty():
		_hide_portrait()
		return

	# 逆转裁判式：一场景一立绘。多 NPC 场景只显示焦点角色（默认列表首位，
	# 或保持当前焦点），对话选择对象时经 focus_npc 切换；不再多立绘并排。
	var focus_id := ""
	if filtered.size() == 1:
		focus_id = filtered[0]
	elif _current_npc_id != "" and filtered.has(_current_npc_id):
		focus_id = _current_npc_id
	else:
		focus_id = filtered[0]
	_switch_to_single_mode()
	var portrait_path: String = AssetResolver.get_portrait(focus_id, GameManager.npcs_data)
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		_hide_portrait()
		return
	_current_npc_id = focus_id
	_apply_single_portrait_presentation(focus_id, "base", portrait_path)
	_portrait.texture = _load_portrait_texture(portrait_path)
	_show_portrait()


## 对话选择对象时切换焦点立绘（逆转式：立绘跟随对话对象）。
## 对话开始本身会 hide_npcs，故此处只换纹理与焦点 id，不主动显示。
func focus_npc(npc_id: String) -> void:
	if npc_id == "" or npc_id == _current_npc_id:
		return
	_switch_to_single_mode()
	_current_npc_id = npc_id
	var portrait_path: String = AssetResolver.get_portrait(npc_id, GameManager.npcs_data)
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		return
	_apply_single_portrait_presentation(npc_id, "base", portrait_path)
	_portrait.texture = _load_portrait_texture(portrait_path)


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
	_portrait.pivot_offset = Vector2(float(_single_portrait_frame.get("pivot_x", _portrait.size.x / 2.0)), _current_portrait_pivot_y)
	_portrait.offset_top = float(_single_portrait_frame.get("offset_top", 60.0)) + _current_portrait_offset_y
	_portrait.offset_bottom = float(_single_portrait_frame.get("offset_bottom", 0.0)) + _current_portrait_offset_y
	if _portrait.visible and _portrait.modulate.a > 0.9:
		return
	# 如果有子面板活跃（探索/搜索/对峙等），不显示 NPC 立绘
	var main_scene := get_tree().current_scene
	if main_scene and main_scene.has_method("is_subpanel_active") and main_scene.is_subpanel_active():
		return
	_portrait.visible = true
	if _portrait_tween != null and _portrait_tween.is_valid():
		_portrait_tween.kill()
	_portrait.modulate = Color(1, 1, 1, 0)
	var target_scale := Vector2(_current_portrait_display_scale, _current_portrait_display_scale)
	_portrait.scale = target_scale * 0.95
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
var _saved_portrait_display_scale: float = 1.0
var _saved_portrait_pivot_y: float = 330.0
var _saved_portrait_offset_y: float = 0.0

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
	_saved_portrait_display_scale = _current_portrait_display_scale
	_saved_portrait_pivot_y = _current_portrait_pivot_y
	_saved_portrait_offset_y = _current_portrait_offset_y
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
	_apply_single_portrait_presentation("__companion__", "base", portrait_path)
	_portrait.texture = _load_portrait_texture(portrait_path)
	_current_npc_id = "__companion__"
	_show_portrait()


func _load_portrait_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var cache_key := _portrait_cache_key(path)
	var cached = _portrait_texture_cache.get(cache_key, null)
	if cached is Texture2D:
		return cached
	var texture := _load_source_portrait_texture(path)
	if texture == null:
		texture = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if texture == null:
		return null
	var normalized := _crop_texture_to_visible_alpha(texture)
	_portrait_texture_cache[cache_key] = normalized
	return normalized


func _load_source_portrait_texture(path: String) -> Texture2D:
	var source_path := ProjectSettings.globalize_path(path)
	if source_path == "" or not FileAccess.file_exists(source_path):
		return null
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _portrait_cache_key(path: String) -> String:
	var modified_time := FileAccess.get_modified_time(path)
	if modified_time == 0:
		modified_time = FileAccess.get_modified_time(ProjectSettings.globalize_path(path))
	return "%s:%d" % [path, modified_time]


func _crop_texture_to_visible_alpha(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image == null:
		return texture
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return texture
	var image_size := image.get_size()
	var normalize_cfg := _get_portrait_normalize_config()
	if float(used.size.y) / float(image_size.y) < float(normalize_cfg.get("crop_min_height_ratio", DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO)):
		return texture
	var pad_ratio := float(normalize_cfg.get("crop_padding_ratio", DEFAULT_PORTRAIT_CROP_PADDING_RATIO))
	var min_padding := int(normalize_cfg.get("crop_min_padding", DEFAULT_PORTRAIT_CROP_MIN_PADDING))
	var pad_x: int = max(min_padding, int(ceil(float(used.size.x) * pad_ratio)))
	var pad_y: int = max(min_padding, int(ceil(float(used.size.y) * pad_ratio)))
	var x1: int = max(0, used.position.x - pad_x)
	var y1: int = max(0, used.position.y - pad_y)
	var x2: int = min(image_size.x, used.position.x + used.size.x + pad_x)
	var y2: int = min(image_size.y, used.position.y + used.size.y + pad_y)
	if x1 == 0 and y1 == 0 and x2 == image_size.x and y2 == image_size.y:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(x1), float(y1), float(x2 - x1), float(y2 - y1))
	return atlas


func _get_portrait_normalize_config() -> Dictionary:
	if AssetResolver != null and AssetResolver.has_method("get_center_portrait_texture_normalize_config"):
		var resolved = AssetResolver.get_center_portrait_texture_normalize_config("scene")
		if typeof(resolved) == TYPE_DICTIONARY and not resolved.is_empty():
			return resolved
	return {
		"crop_padding_ratio": DEFAULT_PORTRAIT_CROP_PADDING_RATIO,
		"crop_min_padding": DEFAULT_PORTRAIT_CROP_MIN_PADDING,
		"crop_min_height_ratio": DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO,
	}


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
		_current_portrait_display_scale = _saved_portrait_display_scale
		_current_portrait_pivot_y = _saved_portrait_pivot_y
		_current_portrait_offset_y = _saved_portrait_offset_y
		_portrait.texture = _saved_texture
		_saved_texture = null
		_saved_npc_id = ""
		_saved_portrait_display_scale = 1.0
		_saved_portrait_pivot_y = 330.0
		_saved_portrait_offset_y = 0.0
		_show_portrait()
	else:
		_saved_npc_id = ""
		_saved_portrait_display_scale = 1.0
		_saved_portrait_pivot_y = 330.0
		_saved_portrait_offset_y = 0.0


func preview_center_npc(npc_id: String, emotion: String = "base") -> bool:
	if npc_id == "":
		return false
	var portrait_path := AssetResolver.resolve_case_portrait(npc_id, emotion, GameManager.npcs_data)
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		return false
	_preview_active = true
	_switch_to_single_mode()
	_current_npc_id = npc_id
	_apply_single_portrait_presentation(npc_id, emotion, portrait_path)
	_portrait.texture = _load_portrait_texture(portrait_path)
	_show_portrait()
	return true


func clear_preview() -> void:
	_preview_active = false
	if GameManager != null and GameManager.current_location != "":
		refresh_npcs(GameManager.current_location)
	else:
		_hide_portrait()


func _apply_single_portrait_presentation(npc_id: String, emotion: String, portrait_path: String) -> void:
	var presentation := AssetResolver.get_center_portrait_surface_presentation("scene", npc_id, emotion, portrait_path)
	_current_portrait_display_scale = float(presentation.get("screen_scale", 1.0))
	_current_portrait_pivot_y = float(presentation.get("pivot_y", 330.0))
	_current_portrait_offset_y = float(presentation.get("offset_y", 0.0))
	_portrait.offset_top = float(_single_portrait_frame.get("offset_top", 60.0)) + _current_portrait_offset_y
	_portrait.offset_bottom = float(_single_portrait_frame.get("offset_bottom", 0.0)) + _current_portrait_offset_y
