extends Control
## 动态立绘验证场景（接入真实生成帧）
##
## 使用 tools/gen_portrait_anim_frames.py 生成的整图帧：
##   <base>.png        身体/睁眼/闭嘴（原图）
##   <base>_idle_1.png 闭眼（仅眼部合成，其余=原图，无漂移）
##   <base>_talk_1.png 张嘴（仅嘴部合成）
##
## 行为：眨眼每 2.5~5s 播一次；说话时在张嘴/闭嘴间循环；眨眼优先级最高。
## 运行：空格 / 「说话」按钮 切换说话状态。

const BASE_PORTRAIT := "res://assets/cn/portraits/prologue_shen_qingyue.png"

var _portrait_rect: TextureRect = null
var _status_label: Label = null

var _tex_open: Texture2D = null     # 睁眼+闭嘴（base）
var _tex_blink: Texture2D = null    # 闭眼
var _tex_talk: Texture2D = null     # 张嘴

var _talking := false
var _blinking := false
var _mouth_open := false

var _blink_timer: Timer = null
var _mouth_timer: Timer = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 半透明遮罩背景（盖住下层 GM 面板）
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# 立绘：用 KEEP_ASPECT_CENTERED 完整显示，铺满整屏由 stretch 居中缩放
	_portrait_rect = TextureRect.new()
	_portrait_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 留出顶部 UI 空间：从 y=20 到底部 20，整体略微下压让头部不顶边
	_portrait_rect.offset_left = 0
	_portrait_rect.offset_top = 20
	_portrait_rect.offset_right = 0
	_portrait_rect.offset_bottom = -20
	add_child(_portrait_rect)

	_load_frames()
	_build_overlay_ui()

	# 计时器
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_do_blink)
	add_child(_blink_timer)
	_mouth_timer = Timer.new()
	_mouth_timer.one_shot = false
	_mouth_timer.wait_time = 0.1
	_mouth_timer.timeout.connect(_on_mouth_tick)
	add_child(_mouth_timer)

	_apply_frame()
	_schedule_blink()
	_update_status()


func _build_overlay_ui() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top = 0
	bar.offset_bottom = 96
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.85)
	bar.add_theme_stylebox_override("panel", style)
	add_child(bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)

	var title := Label.new()
	title.text = "动态立绘测试 · 沈清月"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1.0))
	info.add_child(title)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 1.0))
	info.add_child(_status_label)

	var talk_btn := Button.new()
	talk_btn.text = "说话 / 停止 [空格]"
	talk_btn.custom_minimum_size = Vector2(170, 44)
	talk_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	talk_btn.pressed.connect(_toggle_talk)
	row.add_child(talk_btn)

	var back := Button.new()
	back.text = "返回"
	back.custom_minimum_size = Vector2(90, 44)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): queue_free())
	row.add_child(back)


func _load_frames() -> void:
	if ResourceLoader.exists(BASE_PORTRAIT):
		_tex_open = load(BASE_PORTRAIT)
	var blink_path := BASE_PORTRAIT.replace(".png", "_idle_1.png")
	var talk_path := BASE_PORTRAIT.replace(".png", "_talk_1.png")
	if ResourceLoader.exists(blink_path):
		_tex_blink = load(blink_path)
	if ResourceLoader.exists(talk_path):
		_tex_talk = load(talk_path)


## 当前应显示哪一帧：眨眼 > 说话张嘴 > 睁眼闭嘴
func _apply_frame() -> void:
	if _portrait_rect == null:
		return
	if _blinking and _tex_blink != null:
		_portrait_rect.texture = _tex_blink
	elif _talking and _mouth_open and _tex_talk != null:
		_portrait_rect.texture = _tex_talk
	else:
		_portrait_rect.texture = _tex_open


# ─── 眨眼 ───
func _schedule_blink() -> void:
	_blink_timer.start(randf_range(2.5, 5.0))


func _do_blink() -> void:
	if not visible or _tex_blink == null:
		_schedule_blink()
		return
	_blinking = true
	_apply_frame()
	await get_tree().create_timer(0.12).timeout
	if not is_inside_tree():
		return
	_blinking = false
	_apply_frame()
	_schedule_blink()


# ─── 口型 ───
func _toggle_talk() -> void:
	_talking = not _talking
	if _talking:
		_mouth_timer.start()
	else:
		_mouth_timer.stop()
		_mouth_open = false
	_apply_frame()
	_update_status()


func _on_mouth_tick() -> void:
	if not _talking:
		_mouth_timer.stop()
		return
	_mouth_open = not _mouth_open
	_apply_frame()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_toggle_talk()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			queue_free()


func _update_status() -> void:
	if _status_label == null:
		return
	var loaded := _tex_blink != null and _tex_talk != null
	var src := "已加载生成帧" if loaded else "缺生成帧·仅静态"
	_status_label.text = "%s    当前：%s" % [src, "说话中（口型循环）" if _talking else "静止 · 自动眨眼"]
