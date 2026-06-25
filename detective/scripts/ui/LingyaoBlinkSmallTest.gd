extends Control
## 方案 C 验证: 用 ROI 大小的小贴图眼层 + 多帧 alpha 曲线眨眼。
##
## 对比 DynamicPortraitTestV2:
##   - 眼层贴图: 848x1264 全帧 → 215x60 ROI 小图(美术量 1/130)
##   - 底部硬切: closed 帧 y>367 残留已在生成阶段砍掉, 消除"下方暗影"
##   - 眼层定位: 通过 layer_rect 显式指定 ROI 在画布中的位置
##
## 按 B 键手动眨眼; 自动每 2.5~5s 眨一次。

const BODY_PATH := "res://assets/cn/portraits/companion_lingyao.png"
const EYES_HALF_PATH := "res://assets/cn/portraits/anim_layers/lingyao/small/eyes_half.png"
const EYES_CLOSED_PATH := "res://assets/cn/portraits/anim_layers/lingyao/small/eyes_closed.png"

## ROI 在源图(848x1264)中的位置 —— 与 crop_blink_to_small.py 配置一致
## 上沿 325 避开眉毛(右眉延伸到 y=324), 下沿 367 避开脸颊溢出
const EYE_ROI_IN_SOURCE := Rect2(300, 325, 215, 43)
const SOURCE_SIZE := Vector2(848, 1264)

var _tex_body: Texture2D
var _tex_eyes_half: Texture2D
var _tex_eyes_closed: Texture2D

var _body_rect: TextureRect
var _eyes_rect: TextureRect
var _status_label: Label

var _blink_frames: Array[Dictionary] = []
var _blink_timer: Timer
var _is_blinking := false


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.10, 0.95)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# 加载贴图
	_tex_body = load(BODY_PATH) if ResourceLoader.exists(BODY_PATH) else null
	_tex_eyes_half = load(EYES_HALF_PATH) if ResourceLoader.exists(EYES_HALF_PATH) else null
	_tex_eyes_closed = load(EYES_CLOSED_PATH) if ResourceLoader.exists(EYES_CLOSED_PATH) else null

	if _tex_body == null:
		_show_error("缺少身体图: " + BODY_PATH)
		return

	# 立绘容器: 把 848x1264 的源图按比例摆在屏幕中央
	# 用 AspectRatioContainer 不方便算 ROI, 改用手动 Rect 摆放
	var viewport_size := Vector2(get_viewport_rect().size)
	var scale := minf(viewport_size.x / SOURCE_SIZE.x, (viewport_size.y - 100) / SOURCE_SIZE.y)
	var portrait_size := SOURCE_SIZE * scale
	var portrait_pos := Vector2((viewport_size.x - portrait_size.x) * 0.5,
								 (viewport_size.y - portrait_size.y) * 0.5 + 40)

	# Body 层
	_body_rect = TextureRect.new()
	_body_rect.texture = _tex_body
	_body_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_body_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_body_rect.position = portrait_pos
	_body_rect.size = portrait_size
	_body_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body_rect)

	# 眼睛层: 按 ROI 在源图中的位置 → 缩放到屏幕坐标
	if _tex_eyes_half != null and _tex_eyes_closed != null:
		_eyes_rect = TextureRect.new()
		_eyes_rect.texture = _tex_eyes_half
		_eyes_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_eyes_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_eyes_rect.position = portrait_pos + EYE_ROI_IN_SOURCE.position * scale
		_eyes_rect.size = EYE_ROI_IN_SOURCE.size * scale
		_eyes_rect.visible = false
		_eyes_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_eyes_rect)

	_build_ui()
	_build_blink_sequence()
	_start_blink_loop()


func _build_ui() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(PRESET_TOP_WIDE)
	bar.offset_bottom = 80
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.82)
	bar.add_theme_stylebox_override("panel", style)
	add_child(bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var title := Label.new()
	title.text = "凌瑶眨眼 · 方案C(ROI 小贴图 + 多帧 alpha 曲线)"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.68, 1))
	info.add_child(title)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 1))
	_status_label.text = "[B] 手动眨眼   状态: 待机"
	info.add_child(_status_label)

	var blink_btn := Button.new()
	blink_btn.text = "眨眼 [B]"
	blink_btn.custom_minimum_size = Vector2(120, 44)
	blink_btn.pressed.connect(_do_blink)
	row.add_child(blink_btn)

	var back := Button.new()
	back.text = "返回"
	back.custom_minimum_size = Vector2(80, 44)
	back.pressed.connect(_on_back_pressed)
	row.add_child(back)


func _show_error(msg: String) -> void:
	var l := Label.new()
	l.text = msg
	l.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	l.add_theme_font_size_override("font_size", 24)
	l.set_anchors_preset(PRESET_CENTER)
	add_child(l)


# ═══ 眨眼序列(7 帧, 解决 V2 帧数不足问题) ═══
func _build_blink_sequence() -> void:
	if _tex_eyes_half == null or _tex_eyes_closed == null:
		return
	# 7 帧: 渐入 半→闭(3 帧) + 中保持闭 + 渐出 闭→半 → 露出睁眼(3 帧)
	# half α 调高到 0.80(原 V2 是 0.55, 几乎看不见); closed 实芯 3 帧, 总闭眼时长 ~210ms
	_blink_frames = [
		{"tex": _tex_eyes_half,   "dur": 0.040, "alpha": 0.80},
		{"tex": _tex_eyes_closed, "dur": 0.060, "alpha": 1.00},
		{"tex": _tex_eyes_closed, "dur": 0.090, "alpha": 1.00},  # 全闭保持
		{"tex": _tex_eyes_closed, "dur": 0.060, "alpha": 1.00},
		{"tex": _tex_eyes_half,   "dur": 0.040, "alpha": 0.80},
	]


func _start_blink_loop() -> void:
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_do_blink)
	add_child(_blink_timer)
	_schedule_next_blink()


func _schedule_next_blink() -> void:
	if not _is_blinking and is_instance_valid(_blink_timer):
		_blink_timer.start(randf_range(2.5, 5.0))


func _do_blink() -> void:
	if _is_blinking or not is_instance_valid(_eyes_rect) or _blink_frames.is_empty():
		return
	_is_blinking = true
	_eyes_rect.visible = true
	if _status_label != null:
		_status_label.text = "[B] 手动眨眼   状态: 眨眼中"

	for frame in _blink_frames:
		if not is_instance_valid(_eyes_rect):
			_is_blinking = false
			return
		_eyes_rect.texture = frame.tex
		var a := float(frame.get("alpha", 1.0))
		_eyes_rect.modulate = Color(1, 1, 1, a)
		await get_tree().create_timer(frame.dur).timeout

	if is_instance_valid(_eyes_rect):
		_eyes_rect.visible = false
		_eyes_rect.modulate = Color(1, 1, 1, 1.0)
	_is_blinking = false
	if _status_label != null:
		_status_label.text = "[B] 手动眨眼   状态: 待机"
	_schedule_next_blink()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		_do_blink()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/DynamicPortraitTestV2.tscn")
