class_name DynamicPortraitTestV2
extends Control
## V3 多帧眨眼动态立绘 —— diff overlay + 多帧动画
## body(原图) + eyes_overlay(半闭/全闭,全帧透明) + mouth_layer(张嘴,全帧透明)
## 眨眼序列: 睁眼 → 半闭(0.06s) → 全闭(0.08s) → 半闭(0.06s) → 睁眼
## 所有层 848x1264, 相同锚点/缩放, 天然对齐。

# ═══ 预加载纹理 ═══
var _tex_body: Texture2D
var _tex_eyes_half: Texture2D      # 半闭眼 overlay
var _tex_eyes_closed: Texture2D    # 全闭眼 overlay
var _tex_mouth_open: Texture2D

var _talking := false
var _status_label: Label
var _eyes_rect: TextureRect        # 眨眼层（切换纹理实现帧动画）
var _mouth_rect: TextureRect

## 眨眼帧定义: (纹理, 持续秒数)
var _blink_frames: Array[Dictionary] = []

func _init() -> void:
	var base := "res://assets/cn/portraits/anim_layers/shen_qingyue/"
	_tex_body = load("res://assets/cn/portraits/prologue_shen_qingyue.png")
	_tex_eyes_half = load(base + "eyes_half.png")
	_tex_eyes_closed = load(base + "eyes_closed.png")
	_tex_mouth_open = load(base + "mouth_layer.png")
	
	# 眨眼序列: 纹理 → 持续时间
	_blink_frames = [
		{"tex": _tex_eyes_half,  "dur": 0.06},   # 半闭（下落）
		{"tex": _tex_eyes_closed, "dur": 0.10},   # 全闭（停留稍长）
		{"tex": _tex_eyes_half,  "dur": 0.06},   # 半闭（抬起）
	]

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	if _tex_eyes_half == null:
		push_error("DynamicPortraitTestV2: eyes_half.png 加载失败")
	if _tex_eyes_closed == null:
		push_error("DynamicPortraitTestV2: eyes_closed.png 加载失败")
	if _tex_mouth_open == null:
		push_error("DynamicPortraitTestV2: mouth_layer.png 加载失败")
	
	# ── 身体层 (底层: 原图) ──
	var body := _make_full_layer("Body", _tex_body)
	add_child(body)
	
	# ── 眼睛层 (默认隐藏=睁眼, 通过切换纹理播放眨眼) ──
	var eyes := _make_full_layer("Eyes", _tex_eyes_half)
	eyes.visible = false
	add_child(eyes)
	_eyes_rect = eyes
	
	# ── 张嘴层 (默认隐藏=闭嘴) ──
	var mouth := _make_full_layer("Mouth", _tex_mouth_open)
	mouth.visible = false
	add_child(mouth)
	_mouth_rect = mouth
	
	# ── UI 工具条 ──
	_build_ui()
	
	# ── 启动眨眼 ──
	_start_blink_cycle()

## 创建与身体图完全对齐的全帧层
func _make_full_layer(layer_name: String, tex: Texture2D) -> TextureRect:
	var t := TextureRect.new()
	t.name = layer_name
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.focus_mode = Control.FOCUS_NONE          # 防止出现焦点虚线框
	return t

# ═══ UI ═══
func _build_ui() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(PRESET_TOP_WIDE)
	bar.offset_bottom = 100
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
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(row)
	
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	
	var title := Label.new()
	title.text = "动态立绘 V2 · 差分叠加"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.68, 1))
	info.add_child(title)
	
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 1))
	_status_label.text = "状态: 静默"
	info.add_child(_status_label)
	
	var talk_btn := Button.new()
	talk_btn.text = "说话 / 停止 [空格]"
	talk_btn.custom_minimum_size = Vector2(160, 44)
	talk_btn.pressed.connect(_toggle_talk)
	row.add_child(talk_btn)
	
	var back := Button.new()
	back.text = "返回"
	back.custom_minimum_size = Vector2(80, 44)
	back.pressed.connect(func(): queue_free())
	row.add_child(back)

# ═══ 说话 ═══
func _toggle_talk() -> void:
	_talking = !_talking
	if _talking:
		_mouth_rect.visible = true
		_status_label.text = "状态: 说话中"
	else:
		_mouth_rect.visible = false
		_status_label.text = "状态: 静默"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_toggle_talk()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		_do_blink()

# ═══ 眨眼（多帧动画） ═══
var _blink_timer: Timer
var _is_blinking := false

func _start_blink_cycle() -> void:
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_do_blink)
	add_child(_blink_timer)
	_schedule_blink()

func _schedule_blink() -> void:
	if not _is_blinking:
		_blink_timer.start(randf_range(2.5, 5.0))

## 播放完整眨眼序列: 半闭 → 全闭 → 半闭 → 睁
func _do_blink() -> void:
	if _is_blinking or not is_instance_valid(_eyes_rect):
		return
	_is_blinking = true
	_eyes_rect.visible = true
	
	for frame in _blink_frames:
		if not is_instance_valid(_eyes_rect):
			_is_blinking = false
			return
		_eyes_rect.texture = frame.tex
		await get_tree().create_timer(frame.dur).timeout
	
	if is_instance_valid(_eyes_rect):
		_eyes_rect.visible = false
	_is_blinking = false
	_schedule_blink()
