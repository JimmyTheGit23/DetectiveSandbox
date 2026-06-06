extends Control
class_name CabinEscapePanel

signal completed

const BG_RISING := "res://assets/cn/scenes/prologue_ship_cabin_rising.png"
const BG_ESCAPE := "res://assets/cn/scenes/prologue_ship_cabin_escape_injured.png"
const BG_DARK_WATER := "res://assets/cn/scenes/prologue_dark_water.png"
const FALLBACK_VIEW_SIZE := Vector2(1280, 720)

const CabinWaterOverlayScript = preload("res://scripts/ui/CabinWaterOverlay.gd")

var _scene_root: Control
var _background: TextureRect
var _water
var _flash: ColorRect
var _caption_shade: ColorRect
var _caption: Label
var _hint: Label

var _hole_seen := false
var _finishing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_force_fullscreen_layout()
	resized.connect(_force_fullscreen_layout)
	if not get_tree().root.size_changed.is_connected(_force_fullscreen_layout):
		get_tree().root.size_changed.connect(_force_fullscreen_layout)
	_build_scene()
	_force_fullscreen_layout()
	_play_bgm("ferry_prologue_escape")
	_set_caption("黑暗里，船身猛地一沉。冰水撞上脚踝。")
	_set_hint("")
	call_deferred("_run_auto_escape")
	call_deferred("_force_fullscreen_layout")


func _exit_tree() -> void:
	if get_tree().root.size_changed.is_connected(_force_fullscreen_layout):
		get_tree().root.size_changed.disconnect(_force_fullscreen_layout)


func _build_scene() -> void:
	_scene_root = Control.new()
	_scene_root.name = "TiltingCabin"
	_scene_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene_root.rotation_degrees = -1.8
	add_child(_scene_root)

	_background = TextureRect.new()
	_background.name = "Background"
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.texture = load(BG_RISING)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_root.add_child(_background)

	var cold_tint := ColorRect.new()
	cold_tint.name = "ColdTint"
	cold_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	cold_tint.color = Color(0.015, 0.04, 0.07, 0.22)
	cold_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_root.add_child(cold_tint)

	_water = CabinWaterOverlayScript.new()
	_water.name = "WaterOverlay"
	_water.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene_root.add_child(_water)

	var vignette := ColorRect.new()
	vignette.name = "Vignette"
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0.26)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_root.add_child(vignette)

	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_build_caption()


func _build_caption() -> void:
	_caption_shade = ColorRect.new()
	_caption_shade.name = "CaptionShade"
	_caption_shade.color = Color(0.015, 0.018, 0.02, 0.74)
	_caption_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption_shade)

	_caption = Label.new()
	_caption.name = "Caption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.custom_minimum_size = Vector2(560, 72)
	_caption.add_theme_font_size_override("font_size", 26)
	_caption.add_theme_color_override("font_color", Color(0.88, 0.93, 0.95, 1.0))
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_caption.add_theme_constant_override("shadow_offset_x", 2)
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_caption)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(560, 28)
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.64, 0.78, 0.82, 0.82))
	add_child(_hint)
	_layout_caption()


func _force_fullscreen_layout() -> void:
	var view_size := _current_view_size()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	position = Vector2.ZERO
	size = view_size
	if _scene_root:
		_scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_scene_root.offset_left = 0.0
		_scene_root.offset_top = 0.0
		_scene_root.offset_right = 0.0
		_scene_root.offset_bottom = 0.0
		_scene_root.size = view_size
		_scene_root.pivot_offset = view_size * 0.5
	if _background:
		_background.set_anchors_preset(Control.PRESET_FULL_RECT)
		_background.offset_left = 0.0
		_background.offset_top = 0.0
		_background.offset_right = 0.0
		_background.offset_bottom = 0.0
	if _water:
		_water.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layout_caption()


func _current_view_size() -> Vector2:
	var parent_control := get_parent() as Control
	if parent_control and parent_control.size.x > 1.0 and parent_control.size.y > 1.0:
		return parent_control.size
	var viewport_size := get_viewport_rect().size
	if viewport_size.x > 1.0 and viewport_size.y > 1.0:
		return viewport_size
	return FALLBACK_VIEW_SIZE


func _layout_caption() -> void:
	if _caption == null or _hint == null:
		return
	var view_size := _current_view_size()
	var side_margin: float = clampf(view_size.x * 0.08, 24.0, 140.0)
	var bottom_margin: float = clampf(view_size.y * 0.035, 18.0, 34.0)
	var shade_height: float = clampf(view_size.y * 0.24, 150.0, 230.0)
	var caption_height: float = clampf(view_size.y * 0.105, 72.0, 104.0)
	var hint_height: float = 30.0
	var text_width: float = maxf(view_size.x - side_margin * 2.0, 160.0)

	if _caption_shade:
		_caption_shade.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_caption_shade.position = Vector2(0.0, view_size.y - shade_height)
		_caption_shade.size = Vector2(view_size.x, shade_height)

	_caption.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_caption.position = Vector2(side_margin, view_size.y - bottom_margin - caption_height - hint_height - 8.0)
	_caption.size = Vector2(text_width, caption_height)
	_caption.custom_minimum_size = Vector2(minf(text_width, 560.0), caption_height)

	_hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hint.position = Vector2(side_margin, view_size.y - bottom_margin - hint_height)
	_hint.size = Vector2(text_width, hint_height)
	_hint.custom_minimum_size = Vector2(minf(text_width, 560.0), hint_height)


func _run_auto_escape() -> void:
	if _finishing or not is_inside_tree():
		return
	_intro_flash()
	await get_tree().create_timer(0.65).timeout
	if not is_inside_tree():
		return

	_play_sfx("ship_creak")
	_shake(5.0, 0.24)
	_raise_water(0.08)
	_set_caption("舱门推不开。门外有沉重的货物顶着，木板被撞得发闷。只能另找出口。")
	await get_tree().create_timer(1.45).timeout
	if not is_inside_tree():
		return

	_play_sfx("water_rush")
	_shake(3.0, 0.18)
	_hole_seen = true
	_raise_water(0.05)
	if not GameManager.has_evidence("evidence_hull_hole"):
		GameManager.add_evidence("evidence_hull_hole")
	_set_caption("你咬牙摸进冰水里。脚下有个方形洞口，边缘齐得发冷。不是撞裂，是凿开的。")
	await get_tree().create_timer(1.65).timeout
	if not is_inside_tree():
		return

	_play_sfx("metal_clink")
	_raise_water(0.04)
	if not GameManager.has_evidence("evidence_iron_crowbar_location"):
		GameManager.add_evidence("evidence_iron_crowbar_location")
	_set_caption("你扯下舱壁上的铁撬棍。冰冷的铁柄滑得握不住，只能攥得更紧。")
	await get_tree().create_timer(1.35).timeout
	if not is_inside_tree():
		return

	_play_sfx("splash")
	_shake(2.0, 0.18)
	_raise_water(0.04)
	_set_caption("你把漂起的木箱推到天窗正下方。木箱在水里打转，勉强能踩。")
	await get_tree().create_timer(1.35).timeout
	if not is_inside_tree():
		return

	_finish_escape()


func _intro_flash() -> void:
	_flash_screen(0.45, 0.14)
	_shake(8.0, 0.45)


func _finish_escape() -> void:
	if _finishing:
		return
	_finishing = true
	if not _hole_seen:
		_hole_seen = true
		if not GameManager.has_evidence("evidence_hull_hole"):
			GameManager.add_evidence("evidence_hull_hole")
		_set_caption("你踩上木箱时，水流卷开杂物。船底那个洞一闪而过：方正、整齐，绝不是暗礁撞开的。")
		await get_tree().create_timer(1.3).timeout
	_set_caption("铁撬卡进锁扣。你用尽全身力气往下一压。")
	_play_sfx("ship_creak")
	_shake(9.0, 0.55)
	_raise_water(0.12)
	await get_tree().create_timer(0.75).timeout
	_flash_screen(0.75, 0.18)
	_background.texture = load(BG_ESCAPE)
	_water.level = 0.48
	_scene_root.rotation_degrees = 0.7
	_play_sfx("glass_break")
	_set_caption("咔嚓！天窗向外弹开。冷雨砸在脸上，你双手撑住破木边缘，硬生生钻了出去。")
	await get_tree().create_timer(1.8).timeout
	if not GameManager.has_evidence("evidence_seal_lost"):
		GameManager.add_evidence("evidence_seal_lost")
	_background.texture = load(BG_DARK_WATER)
	_water.level = 0.0
	_flash_screen(0.35, 0.25)
	_set_caption("船体在身后断裂。官印、行李和文书，全被黑水吞了下去。")
	await get_tree().create_timer(1.25).timeout
	_set_caption("你抓住一块断板，江水冷得像针。岸线在雨里忽远忽近。")
	await get_tree().create_timer(1.15).timeout
	completed.emit()


func _raise_water(delta: float) -> void:
	var tw := create_tween()
	tw.tween_property(_water, "level", clamp(_water.level + delta, 0.0, 0.72), 0.55).set_trans(Tween.TRANS_SINE)


func _shake(intensity: float, duration: float) -> void:
	if _scene_root == null:
		return
	var origin := Vector2.ZERO
	var steps := 7
	var tw := create_tween()
	for _i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(_scene_root, "position", origin + offset, duration / float(steps))
	tw.tween_property(_scene_root, "position", origin, 0.04)


func _flash_screen(alpha: float, duration: float) -> void:
	_flash.color = Color(1, 1, 1, alpha)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)


func _set_caption(text: String) -> void:
	_caption.text = text


func _set_hint(text: String) -> void:
	_hint.text = text


func _play_bgm(id: String) -> void:
	var bgm_player = get_node_or_null("/root/BgmPlayer")
	if bgm_player and bgm_player.has_method("play"):
		bgm_player.play(id)
	else:
		BgmPlayer.play(id)


func _play_sfx(id: String) -> void:
	var sfx_player = get_node_or_null("/root/SfxPlayer")
	if sfx_player and sfx_player.has_method("play"):
		sfx_player.play(id)
