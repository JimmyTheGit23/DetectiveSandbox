extends Control
## SceneFXLayer
##
## 在场景背景之上、UI 之下叠加的"动态特效层"。
## 由 MainGame 创建，监听场景切换信号；按 scenes/registry.json 中每个 scene 的
## "effects": ["rain_light", "mist_slow", ...] 数组渲染对应效果。
##
## 支持的 fx_id：
##   rain_light       —— 软雨（少量、长条、慢落）
##   rain_drip        —— 急雨/屋檐雨滴
##   mist_slow        —— 缓慢雾气
##   incense_smoke    —— 香炉烟丝
##   lantern_flicker  —— 灯笼闪烁亮度调制
##   candle_flicker   —— 烛光闪烁
##   curtain_sway     —— 帘幕轻摆（简化为半透明色块呼吸）
##   red_silk_sway    —— 红绸轻摆
##   water_ripple     —— 水面涟漪（备用，暂未挂场景）
##   dust_motes       —— 尘埃微粒（室内逆光场景）
##   light_shaft      —— 柔和窗格光柱呼吸
##
## 实现策略：纯 GDScript 程序化，不依赖额外纹理；雨/烟用 CPUParticles2D，灯光用 Tween 调制
## ColorRect/Overlay 节点的 modulate.a。性能开销很小。

const PERIODS_PER_DAY := 8

var _active_layers: Array[Node] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## 由 MainGame 在 _on_location_changed 时调用。
func apply_for_scene_id(scene_id: String) -> void:
	clear_layers()
	if scene_id == "":
		return
	var resolver := get_node_or_null("/root/AssetResolver")
	if resolver == null:
		return
	var effects: Array = _get_effects_for_scene(scene_id)
	for fx_id in effects:
		_spawn_layer(str(fx_id))


func _get_effects_for_scene(scene_id: String) -> Array:
	var f := FileAccess.open("res://data/scenes/registry.json", FileAccess.READ)
	if f == null:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var scenes: Dictionary = parsed.get("scenes", {})
	var entry: Dictionary = scenes.get(scene_id, {})
	return entry.get("effects", [])


func clear_layers() -> void:
	for n in _active_layers:
		if is_instance_valid(n):
			n.queue_free()
	_active_layers.clear()


# ─── 各种 fx 工厂 ─────────────────────────────────────────────────────────

func _spawn_layer(fx_id: String) -> void:
	var node: Node = null
	match fx_id:
		"rain_light":
			node = _make_rain(120, 420, 0.45, 14)
		"rain_drip":
			node = _make_rain(30, 620, 0.55, 20)
		"mist_slow":
			node = _make_mist(0.18)
		"incense_smoke":
			node = _make_smoke()
		"lantern_flicker":
			node = _make_light_flicker(Color(1.0, 0.55, 0.25, 0.10), 1.6)
		"candle_flicker":
			node = _make_light_flicker(Color(1.0, 0.78, 0.40, 0.08), 0.9)
		"curtain_sway":
			node = _make_modulated_overlay(Color(0.55, 0.45, 0.35, 0.07), 4.0)
		"red_silk_sway":
			node = _make_modulated_overlay(Color(0.65, 0.18, 0.20, 0.06), 3.0)
		"water_ripple":
			node = _make_water_ripple()
		"dust_motes":
			node = _make_dust_motes()
		"light_shaft":
			node = _make_light_shaft()
		_:
			push_warning("[SceneFXLayer] unknown fx_id: " + fx_id)
			return
	if node:
		add_child(node)
		_active_layers.append(node)


# ─── 雨 ───────────────────────────────────────────────────────────────────
func _make_rain(amount: int, speed: float, alpha: float, length: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var vp_size := get_viewport_rect().size
	p.position = Vector2(vp_size.x * 0.5, -10)
	p.emitting = true
	p.amount = amount
	p.lifetime = 1.6
	p.preprocess = 0.6
	p.randomness = 0.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp_size.x * 0.6, 2)
	p.direction = Vector2(0.05, 1)
	p.spread = 4.0
	p.gravity = Vector2(0, 0)
	p.initial_velocity_min = speed * 0.85
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.2
	p.color = Color(0.85, 0.92, 1.0, alpha)
	# 雨线纹理：竖直亮线
	var img := Image.create(2, length, false, Image.FORMAT_RGBA8)
	for y in range(length):
		var t: float = 1.0 - abs(float(y) - float(length) * 0.5) / (float(length) * 0.5)
		img.set_pixel(0, y, Color(1, 1, 1, clamp(t, 0.0, 1.0)))
		img.set_pixel(1, y, Color(1, 1, 1, clamp(t * 0.7, 0.0, 1.0)))
	p.texture = ImageTexture.create_from_image(img)
	return p


# ─── 雾 ───────────────────────────────────────────────────────────────────
func _make_mist(alpha: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var vp_size := get_viewport_rect().size
	p.position = Vector2(vp_size.x * 0.5, vp_size.y * 0.6)
	p.emitting = true
	p.amount = 14
	p.lifetime = 9.0
	p.preprocess = 4.0
	p.randomness = 0.95
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp_size.x * 0.55, vp_size.y * 0.25)
	p.direction = Vector2(1, 0)
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = 1.6
	p.scale_amount_max = 3.4
	p.color = Color(0.92, 0.94, 0.98, alpha)
	# 软白圆斑
	var sz := 32
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var c: float = (sz - 1) * 0.5
	for y in range(sz):
		for x in range(sz):
			var dx := float(x) - c
			var dy := float(y) - c
			var r: float = sqrt(dx * dx + dy * dy) / (sz * 0.5)
			var a: float = clamp(1.0 - r, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * 0.6))
	p.texture = ImageTexture.create_from_image(img)
	return p


# ─── 烟（线性上升） ────────────────────────────────────────────────────────
func _make_smoke() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var vp_size := get_viewport_rect().size
	p.position = Vector2(vp_size.x * 0.32, vp_size.y * 0.78)
	p.emitting = true
	p.amount = 10
	p.lifetime = 4.5
	p.preprocess = 2.0
	p.randomness = 0.8
	p.direction = Vector2(0, -1)
	p.spread = 12.0
	p.gravity = Vector2(0, -8.0)
	p.initial_velocity_min = 18.0
	p.initial_velocity_max = 32.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	p.color = Color(0.85, 0.78, 0.65, 0.18)
	# 软圆斑
	var sz := 16
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var c: float = (sz - 1) * 0.5
	for y in range(sz):
		for x in range(sz):
			var dx := float(x) - c
			var dy := float(y) - c
			var r: float = sqrt(dx * dx + dy * dy) / (sz * 0.5)
			var a: float = exp(-pow(r * 1.6, 2.0))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	p.texture = ImageTexture.create_from_image(img)
	return p


# ─── 灯光闪烁 / 烛光闪烁 ───────────────────────────────────────────────────
func _make_light_flicker(c: Color, period: float) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = c
	var tw := create_tween()
	tw.set_loops()
	var base_a: float = c.a
	tw.tween_property(rect, "color:a", base_a * 1.6, period * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(rect, "color:a", base_a * 0.5, period * 0.5).set_trans(Tween.TRANS_SINE)
	return rect


# ─── 半透明色块呼吸：帘幕 / 红绸 ───────────────────────────────────────────
func _make_modulated_overlay(c: Color, period: float) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = c
	var tw := create_tween()
	tw.set_loops()
	var base_a: float = c.a
	tw.tween_property(rect, "color:a", base_a * 1.4, period * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(rect, "color:a", base_a * 0.5, period * 0.5).set_trans(Tween.TRANS_SINE)
	return rect


# ─── 水面涟漪（备用，暂未挂场景） ──────────────────────────────────────────
func _make_water_ripple() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var vp_size := get_viewport_rect().size
	p.position = Vector2(vp_size.x * 0.5, vp_size.y * 0.48)
	p.emitting = true
	p.amount = 6
	p.lifetime = 3.0
	p.preprocess = 1.0
	p.randomness = 0.95
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp_size.x * 0.45, vp_size.y * 0.08)
	p.direction = Vector2(0, 0)
	p.spread = 0.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.9
	p.color = Color(0.85, 0.92, 1.0, 0.08)
	var size_px := 32
	var img := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	for y in range(size_px):
		for x in range(size_px):
			var dx := float(x) - (size_px - 1) * 0.5
			var dy := float(y) - (size_px - 1) * 0.5
			var r: float = sqrt(dx * dx + dy * dy) / (size_px * 0.5)
			var ring: float = exp(-pow((r - 0.78) * 6.0, 2.0))
			img.set_pixel(x, y, Color(1, 1, 1, ring * 0.6))
	p.texture = ImageTexture.create_from_image(img)
	return p


# ─── 尘埃微粒：室内逆光 ────────────────────────────────────────────────────
func _make_dust_motes() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var vp_size := get_viewport_rect().size
	# 中上部（窗口区域）发射，向下方缓缓飘
	p.position = Vector2(vp_size.x * 0.5, vp_size.y * 0.30)
	p.emitting = true
	p.amount = 28
	p.lifetime = 7.0
	p.preprocess = 4.0
	p.randomness = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp_size.x * 0.48, vp_size.y * 0.22)
	p.direction = Vector2(0.05, 1.0)
	p.spread = 18.0
	p.gravity = Vector2(0, 6.0)            # 极轻微下沉
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 9.0
	p.angular_velocity_min = -8.0
	p.angular_velocity_max = 8.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.1
	p.color = Color(1.0, 0.92, 0.72, 0.55)  # 暖金光点
	# 用 color_ramp（Gradient）做粒子生命周期内的 alpha 淡入淡出
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.92, 0.72, 0.0))
	ramp.set_color(1, Color(1.0, 0.92, 0.72, 0.0))
	ramp.add_point(0.15, Color(1.0, 0.92, 0.72, 1.0))
	ramp.add_point(0.75, Color(1.0, 0.92, 0.72, 1.0))
	p.color_ramp = ramp
	# 软圆点纹理（高斯径向衰减），避免硬边
	var sz := 16
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var c: float = (sz - 1) * 0.5
	for y in range(sz):
		for x in range(sz):
			var dx := float(x) - c
			var dy := float(y) - c
			var r: float = sqrt(dx * dx + dy * dy) / (sz * 0.5)
			var a: float = exp(-pow(r * 2.0, 2.0))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	p.texture = ImageTexture.create_from_image(img)
	return p


# ─── 柔和光柱 ─────────────────────────────────────────────────────────────
func _make_light_shaft() -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var base := Color(1.0, 0.92, 0.65, 0.05)
	rect.color = base
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(rect, "color:a", base.a * 1.6, 4.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(rect, "color:a", base.a * 0.7, 4.0).set_trans(Tween.TRANS_SINE)
	return rect
