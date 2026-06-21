class_name DynamicPortraitTestV2
extends Control
## V3 多帧眨眼动态立绘 —— diff overlay + 多帧动画
## body(原图) + eyes_overlay(半闭/全闭,全帧透明) + mouth_layer(张嘴,全帧透明)
## 眨眼序列: 睁眼 → 半闭(0.06s) → 全闭(0.08s) → 半闭(0.06s) → 睁眼
## 所有层 848x1264, 相同锚点/缩放, 天然对齐。

# ═══ 角色配置 ═══
const CHAR_CONFIG: Dictionary = {
	"shen_qingyue": {
		"body": "res://assets/cn/portraits/prologue_shen_qingyue.png",
		"anim_dir": "res://assets/cn/portraits/anim_layers/shen_qingyue/",
		"name": "沈清月",
	},
	"lingyao": {
		"body": "res://assets/cn/portraits/companion_lingyao.png",
		"anim_dir": "res://assets/cn/portraits/anim_layers/lingyao/",
		"name": "凌瑶",
	},
}
var _current_char: String = "shen_qingyue"

# ═══ 预加载纹理 ═══
var _tex_body: Texture2D
var _tex_eyes_half: Texture2D      # 半闭眼 overlay
var _tex_eyes_closed: Texture2D    # 全闭眼 overlay
var _tex_mouth_open: Texture2D

var _talking := false
var _status_label: Label
var _eyes_rect: TextureRect        # 眨眼层（切换纹理实现帧动画）
var _mouth_rect: TextureRect
var _char_select: OptionButton     # 角色选择下拉

## 眨眼帧定义: (纹理, 持续秒数)
var _blink_frames: Array[Dictionary] = []

func _load_char(char_id: String) -> void:
	var cfg = CHAR_CONFIG[char_id]
	_tex_body = load(cfg.body)
	_tex_eyes_half = load(cfg.anim_dir + "eyes_half.png")
	_tex_eyes_closed = load(cfg.anim_dir + "eyes_closed.png")
	_tex_mouth_open = load(cfg.anim_dir + "mouth_layer.png")  # 可能为 null
	
	# 眨眼序列: 只使用有效的眼纹理
	_blink_frames.clear()
	if _tex_eyes_half != null:
		_blink_frames.append({"tex": _tex_eyes_half, "dur": 0.06})
	if _tex_eyes_closed != null:
		_blink_frames.append({"tex": _tex_eyes_closed, "dur": 0.10})
	if _tex_eyes_half != null:
		_blink_frames.append({"tex": _tex_eyes_half, "dur": 0.06})
	
	# 眨眼序列
	_blink_frames = [
		{"tex": _tex_eyes_half,  "dur": 0.06},
		{"tex": _tex_eyes_closed, "dur": 0.10},
		{"tex": _tex_eyes_half,  "dur": 0.06},
	]

func _ready() -> void:
	# ⚡ Z序约定: [0]=背景, [1]=立绘层, [2]=UIbar(最上面)
	# UI必须在最上层才能接收点击！
	set_size(Vector2(1280, 720))
	set_position(Vector2(0, 0))
	set_anchors_preset(PRESET_FULL_RECT)
	
	# Z0. 背景
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.10, 0.95)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# Z1. 立绘层（在UI下面）
	_load_char(_current_char)
	_rebuild_portrait_layers()
	
	# Z2. UI工具条（最后add = 最上面，能接收点击）
	_build_ui()
	
	# UI创建后首次设置状态文字
	if _tex_body == null:
		_status_label.text = CHAR_CONFIG[_current_char].name + " 纹理缺失"
		_status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	else:
		_status_label.text = CHAR_CONFIG[_current_char].name + " - 状态: 静默"
		_status_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 1))
	
	# 启动眨眼
	_start_blink_cycle()

## 重建立绘层(Z1位置，在背景与UI之间)
func _rebuild_portrait_layers() -> void:
	# 首次调用时UI还没创建，_status_label可能为Nil（稍后在_build_ui中设）
	if _status_label != null:
		if _tex_body == null:
			_status_label.text = CHAR_CONFIG[_current_char].name + " 纹理缺失"
			_status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
		else:
			_status_label.text = CHAR_CONFIG[_current_char].name + " - 状态: 静默"
			_status_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 1))
	
	# 身体层 - 插入到Z1（背景0，UI在最后）
	if _tex_body != null:
		var body := TextureRect.new()
		body.texture = _tex_body
		body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		body.set_anchors_preset(PRESET_FULL_RECT)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(body, true)  # 内部有序 = 插到索引1位置
		move_child(body, 1)
	
	# 眼睛层 - Z2
	_eyes_rect = null
	if _tex_eyes_half != null:
		_eyes_rect = TextureRect.new()
		_eyes_rect.texture = _tex_eyes_half
		_eyes_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_eyes_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_eyes_rect.set_anchors_preset(PRESET_FULL_RECT)
		_eyes_rect.visible = false
		_eyes_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_eyes_rect)
	
	# 嘴层 - Z3
	_mouth_rect = null
	if _tex_mouth_open != null:
		_mouth_rect = TextureRect.new()
		_mouth_rect.texture = _tex_mouth_open
		_mouth_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_mouth_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_mouth_rect.set_anchors_preset(PRESET_FULL_RECT)
		_mouth_rect.visible = false
		_mouth_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_mouth_rect)



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
	
	# 角色选择
	_char_select = OptionButton.new()
	_char_select.custom_minimum_size = Vector2(120, 44)
	for char_id in CHAR_CONFIG:
		var idx := _char_select.get_item_count()
		_char_select.add_item(CHAR_CONFIG[char_id].name, idx)
		_char_select.set_item_metadata(idx, char_id)
		if char_id == _current_char:
			_char_select.selected = idx
	_char_select.item_selected.connect(_on_char_selected)
	row.add_child(_char_select)
	
	# 说话按钮
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

# ═══ 角色切换 ═══
func _on_char_selected(idx: int) -> void:
	_current_char = _char_select.get_item_metadata(idx) as String
	_stop_blink()
	
	# ═══ Z序约定: [0]=背景, [1]=立绘, [2]=UI ═══
	# 只移除Z1的立绘层，UI不动（避免_status_label变Nil）
	var children := get_children()
	if children.size() > 2:  # 有立绘层时才删
		var portrait_count := children.size() - 2  # =总 - 背景 - UI
		for _i in range(portrait_count):
			var child := get_child(1)  # 始终移除索引1=立绘顶层
			if is_instance_valid(child):
				child.queue_free()
	
	_load_char(_current_char)
	_rebuild_portrait_layers()  # 重新加在Z1位置，UI始终在Z2最上层
	_start_blink_cycle()

# ═══ 说话 ═══
func _toggle_talk() -> void:
	if _mouth_rect == null:
		_status_label.text = "该角色暂无说话动画"
		return
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
	if not _is_blinking and is_instance_valid(_blink_timer):
		_blink_timer.start(randf_range(2.5, 5.0))

func _stop_blink() -> void:
	if is_instance_valid(_blink_timer):
		_blink_timer.stop()
	_blink_timer = null
	_is_blinking = false

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
