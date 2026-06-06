extends Control
class_name CabinEscapePanel

signal completed

const BG_RISING := "res://assets/cn/scenes/prologue_ship_cabin_rising.png"
const BG_ESCAPE := "res://assets/cn/scenes/prologue_ship_cabin_escape_injured.png"
const BG_DARK_WATER := "res://assets/cn/scenes/prologue_dark_water.png"

const CabinWaterOverlayScript = preload("res://scripts/ui/CabinWaterOverlay.gd")

var _scene_root: Control
var _background: TextureRect
var _water
var _flash: ColorRect
var _caption: Label
var _hint: Label
var _hotspots: Dictionary = {}

var _door_checked := false
var _has_crowbar := false
var _crate_ready := false
var _hole_seen := false
var _finishing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(_sync_scene_pivot)
	_build_scene()
	_play_bgm("ferry_prologue_escape")
	_set_caption("黑暗里，船身猛地一沉。冰水撞上脚踝。先确认舱门。")
	_set_hint("点击画面中的可疑位置。")
	_set_stage_opening()
	call_deferred("_intro_flash")


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

	_make_hotspot("door", "舱门", Rect2(0.42, 0.36, 0.19, 0.23))
	_make_hotspot("hole", "涌水处", Rect2(0.08, 0.69, 0.26, 0.22))
	_make_hotspot("crowbar", "铁撬棍", Rect2(0.75, 0.18, 0.18, 0.46))
	_make_hotspot("crate", "漂浮木箱", Rect2(0.48, 0.61, 0.29, 0.25))
	_make_hotspot("skylight", "天窗", Rect2(0.38, 0.04, 0.30, 0.25))

	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_build_caption()
	_sync_scene_pivot()


func _build_caption() -> void:
	var shade := ColorRect.new()
	shade.name = "CaptionShade"
	shade.anchor_left = 0.0
	shade.anchor_right = 1.0
	shade.anchor_top = 0.74
	shade.anchor_bottom = 1.0
	shade.color = Color(0.015, 0.018, 0.02, 0.74)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_caption = Label.new()
	_caption.name = "Caption"
	_caption.anchor_left = 0.10
	_caption.anchor_right = 0.90
	_caption.anchor_top = 0.78
	_caption.anchor_bottom = 0.91
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 26)
	_caption.add_theme_color_override("font_color", Color(0.88, 0.93, 0.95, 1.0))
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_caption.add_theme_constant_override("shadow_offset_x", 2)
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_caption)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.anchor_left = 0.10
	_hint.anchor_right = 0.90
	_hint.anchor_top = 0.92
	_hint.anchor_bottom = 0.98
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.64, 0.78, 0.82, 0.82))
	add_child(_hint)


func _make_hotspot(id: String, tooltip: String, rect: Rect2) -> void:
	var btn := Button.new()
	btn.name = "Hotspot_" + id
	btn.text = ""
	btn.tooltip_text = tooltip
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.anchor_left = rect.position.x
	btn.anchor_top = rect.position.y
	btn.anchor_right = rect.position.x + rect.size.x
	btn.anchor_bottom = rect.position.y + rect.size.y
	btn.offset_left = 0.0
	btn.offset_top = 0.0
	btn.offset_right = 0.0
	btn.offset_bottom = 0.0
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", _make_hotspot_style(Color(0.74, 0.94, 1.0, 0.34)))
	btn.add_theme_stylebox_override("pressed", _make_hotspot_style(Color(1.0, 1.0, 1.0, 0.52)))
	btn.pressed.connect(func(): _on_hotspot_pressed(id))
	_scene_root.add_child(btn)
	_hotspots[id] = btn


func _make_hotspot_style(border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.74, 0.94, 1.0, 0.035)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb


func _set_stage_opening() -> void:
	for id in _hotspots.keys():
		var btn := _hotspots[id] as Button
		if btn:
			btn.disabled = id != "door"


func _open_all_hotspots() -> void:
	for id in _hotspots.keys():
		var btn := _hotspots[id] as Button
		if btn:
			btn.disabled = false


func _sync_scene_pivot() -> void:
	if _scene_root:
		_scene_root.pivot_offset = size * 0.5


func _intro_flash() -> void:
	_flash_screen(0.45, 0.14)
	_shake(8.0, 0.45)


func _on_hotspot_pressed(id: String) -> void:
	if _finishing:
		return
	match id:
		"door":
			_check_door()
		"hole":
			_check_hole()
		"crowbar":
			_take_crowbar()
		"crate":
			_move_crate()
		"skylight":
			_try_skylight()


func _check_door() -> void:
	_play_sfx("ship_creak")
	_shake(5.0, 0.24)
	if not _door_checked:
		_door_checked = true
		_open_all_hotspots()
		_raise_water(0.08)
		_set_caption("舱门推不开。门外有沉重的货物顶着，木板被撞得发闷。只能另找出口。")
		_set_hint("水在涨。找能垫脚和撬锁的东西。")
	else:
		_set_caption("舱门纹丝不动。外面的货物随着船身滑动，又重重压了回来。")


func _check_hole() -> void:
	_play_sfx("water_rush")
	_shake(3.0, 0.18)
	if not _hole_seen:
		_hole_seen = true
		_raise_water(0.05)
		if not GameManager.has_evidence("evidence_hull_hole"):
			GameManager.add_evidence("evidence_hull_hole")
		_set_caption("你咬牙摸进冰水里。脚下有个方形洞口，边缘齐得发冷。不是撞裂，是凿开的。")
		_set_hint("有人想让这条船沉下去。")
	else:
		_set_caption("水正从那个方洞里喷上来，像有人在船底开了一只眼。")


func _take_crowbar() -> void:
	if not _door_checked:
		_set_caption("黑暗里什么都在晃。先确认舱门还能不能出去。")
		return
	_play_sfx("metal_clink")
	if not _has_crowbar:
		_has_crowbar = true
		_raise_water(0.04)
		if not GameManager.has_evidence("evidence_iron_crowbar_location"):
			GameManager.add_evidence("evidence_iron_crowbar_location")
		_set_caption("你扯下舱壁上的铁撬棍。冰冷的铁柄滑得握不住，只能攥得更紧。")
	else:
		_set_caption("铁撬棍已经在手里。现在得想办法够到天窗。")


func _move_crate() -> void:
	if not _door_checked:
		_set_caption("水还在脚边乱撞。先确认舱门。")
		return
	_play_sfx("splash")
	_shake(2.0, 0.18)
	if not _crate_ready:
		_crate_ready = true
		_raise_water(0.04)
		_set_caption("你把漂起的木箱推到天窗正下方。木箱在水里打转，勉强能踩。")
	else:
		_set_caption("木箱已经顶到天窗下方，再拖下去只会被水冲偏。")


func _try_skylight() -> void:
	if not _door_checked:
		_set_caption("天窗透进一点冷光，可你还没确认舱门。")
		return
	if not _crate_ready:
		_set_caption("天窗太高。得先把漂起来的木箱推到下面。")
		_pulse_hotspot("crate")
		return
	if not _has_crowbar:
		_set_caption("锁扣锈死了，徒手掰不开。舱壁上有铁器在晃。")
		_pulse_hotspot("crowbar")
		return
	_finish_escape()


func _finish_escape() -> void:
	if _finishing:
		return
	_finishing = true
	for id in _hotspots.keys():
		var btn := _hotspots[id] as Button
		if btn:
			btn.disabled = true
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


func _pulse_hotspot(id: String) -> void:
	var btn := _hotspots.get(id) as Button
	if btn == null:
		return
	var tw := create_tween()
	tw.tween_property(btn, "modulate:a", 0.45, 0.16)
	tw.tween_property(btn, "modulate:a", 1.0, 0.16)


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
