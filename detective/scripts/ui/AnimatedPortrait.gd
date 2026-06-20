extends Control
## AnimatedPortrait —— 立绘动态化组件（分层方案验证）
##
## 设计目标：以「身体大图 + 眼部小贴图 + 嘴部小贴图」三层叠加，
## 用极少的小贴图实现「眨眼 + 说话口型」，避免整图序列帧导致的美术爆炸。
##
## 层级结构（均为本节点的子 TextureRect，共享同一坐标系/尺寸）：
##   _body   身体/姿势（静止大图，最贵，永不逐帧）—— 对应现有 portrait_expressions 的情绪大图
##   _eyes   眼部贴图（睁/半/闭，盖在眼睛位置；睁眼帧可为空=露出 body）
##   _mouth  嘴部贴图（合/半开/开，盖在嘴巴位置；说话时循环，停字=合）
##
## 用法：
##   set_body(texture)                设置身体大图
##   set_eye_frames([闭眼,半闭...])    设置眨眼贴图序列（不含睁眼；睁眼=隐藏眼层）
##   set_mouth_frames([开,半开...])    设置口型贴图序列（说话时循环；停=合，即隐藏嘴层）
##   set_layer_rects(eye_rect, mouth_rect)  设置眼/嘴贴图相对本节点的位置矩形
##   set_talking(bool)                外部告知是否正在说话（接打字机状态）
##
## 兼容：眼/嘴帧为空时，本组件退化为「只显示身体大图」的静态立绘。

# ─── 层节点 ───
var _body: TextureRect = null
var _eyes: TextureRect = null
var _mouth: TextureRect = null

# ─── 帧资源 ───
var _eye_frames: Array[Texture2D] = []     # [半闭, 全闭, ...]，睁眼=隐藏
var _mouth_frames: Array[Texture2D] = []   # [半开, 全开, ...]，闭嘴=隐藏

# ─── 状态 ───
var _is_talking: bool = false
var _mouth_idx: int = 0

# ─── 计时器 ───
var _blink_timer: Timer = null
var _mouth_timer: Timer = null

# ─── 可调参数 ───
const BLINK_MIN_INTERVAL := 2.2
const BLINK_MAX_INTERVAL := 5.0
const BLINK_FRAME_TIME := 0.06       # 每帧眨眼贴图停留（睁→半→闭→半→睁）
const MOUTH_FRAME_INTERVAL := 0.09   # 说话口型帧切换间隔


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()
	_build_timers()
	_schedule_next_blink()


func _build_layers() -> void:
	_body = _make_layer("Body")
	_eyes = _make_layer("Eyes")
	_mouth = _make_layer("Mouth")
	_eyes.visible = false
	_mouth.visible = false


func _make_layer(node_name: String) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = node_name
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.offset_left = 0
	layer.offset_top = 0
	layer.offset_right = 0
	layer.offset_bottom = 0
	add_child(layer)
	return layer


func _build_timers() -> void:
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_do_blink)
	add_child(_blink_timer)

	_mouth_timer = Timer.new()
	_mouth_timer.one_shot = false
	_mouth_timer.wait_time = MOUTH_FRAME_INTERVAL
	_mouth_timer.timeout.connect(_on_mouth_tick)
	add_child(_mouth_timer)


# ═══════════════════════════════════════════════════════════════
# 公共接口
# ═══════════════════════════════════════════════════════════════

func set_body(texture: Texture2D) -> void:
	if _body != null:
		_body.texture = texture


func set_eye_frames(frames: Array) -> void:
	_eye_frames.clear()
	for f in frames:
		if f is Texture2D:
			_eye_frames.append(f)
	if _eyes != null:
		_eyes.visible = false  # 默认睁眼=隐藏眼层


func set_mouth_frames(frames: Array) -> void:
	_mouth_frames.clear()
	for f in frames:
		if f is Texture2D:
			_mouth_frames.append(f)
	if _mouth != null:
		_mouth.visible = false


## 设置眼/嘴贴图相对本节点的位置（像素矩形）。
## 不调用时，眼/嘴层铺满整个节点（要求贴图本身已是「整幅尺寸、透明定位」）。
func set_layer_rects(eye_rect: Rect2, mouth_rect: Rect2) -> void:
	_apply_rect(_eyes, eye_rect)
	_apply_rect(_mouth, mouth_rect)


func _apply_rect(layer: TextureRect, rect: Rect2) -> void:
	if layer == null or rect.size == Vector2.ZERO:
		return
	layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	layer.position = rect.position
	layer.size = rect.size
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


## 快捷初始化（分层方案）:
##   setup(身体图, 睁眼贴图, 闭眼贴图, 闭嘴贴图, 张嘴贴图, 眼坐标, 嘴坐标)
## 一次性设置身体大图 + 眼/嘴小图块及其位置。
func setup(body_tex: Texture2D,
			_eyes_open_tex: Texture2D,    # 睁眼时隐藏眼层,贴图仅做存档
			eyes_closed_tex: Texture2D,
			_mouth_closed_tex: Texture2D,  # 闭嘴时隐藏嘴层,贴图仅做存档
			mouth_open_tex: Texture2D,
			eye_pos: Vector2, mouth_pos: Vector2,
			eye_size: Vector2, mouth_size: Vector2) -> void:
	
	set_body(body_tex)
	
	# 眨眼帧: 只用闭眼一帧(睁眼=隐藏眼层露出body)
	# 如果以后有半闭帧，加在数组中间
	if eyes_closed_tex:
		set_eye_frames([eyes_closed_tex])
	
	# 口型帧: 只用张嘴一帧
	if mouth_open_tex:
		set_mouth_frames([mouth_open_tex])
	
	# 定位置
	set_layer_rects(
		Rect2(eye_pos, eye_size),
		Rect2(mouth_pos, mouth_size)
	)


func set_talking(talking: bool) -> void:
	if _is_talking == talking:
		return
	_is_talking = talking
	if _is_talking:
		_start_mouth_loop()
	else:
		_stop_mouth_loop()


# ═══════════════════════════════════════════════════════════════
# 眨眼
# ═══════════════════════════════════════════════════════════════

func _schedule_next_blink() -> void:
	if _blink_timer == null:
		return
	_blink_timer.start(randf_range(BLINK_MIN_INTERVAL, BLINK_MAX_INTERVAL))


func _do_blink() -> void:
	if _eye_frames.is_empty() or _eyes == null or not visible:
		_schedule_next_blink()
		return
	# 睁 → 依次播放眨眼帧（半闭→全闭）→ 倒放回睁
	await _play_eye_sequence_down()
	await _play_eye_sequence_up()
	if _eyes != null:
		_eyes.visible = false
	_schedule_next_blink()


func _play_eye_sequence_down() -> void:
	for i in range(_eye_frames.size()):
		if _eyes == null:
			return
		_eyes.texture = _eye_frames[i]
		_eyes.visible = true
		await get_tree().create_timer(BLINK_FRAME_TIME).timeout


func _play_eye_sequence_up() -> void:
	for i in range(_eye_frames.size() - 2, -1, -1):
		if _eyes == null:
			return
		_eyes.texture = _eye_frames[i]
		_eyes.visible = true
		await get_tree().create_timer(BLINK_FRAME_TIME).timeout


# ═══════════════════════════════════════════════════════════════
# 口型
# ═══════════════════════════════════════════════════════════════

func _start_mouth_loop() -> void:
	if _mouth_frames.is_empty() or _mouth == null:
		return
	_mouth_idx = 0
	_mouth.visible = true
	_mouth.texture = _mouth_frames[0]
	_mouth_timer.start()


func _stop_mouth_loop() -> void:
	if _mouth_timer != null:
		_mouth_timer.stop()
	if _mouth != null:
		_mouth.visible = false  # 闭嘴=隐藏嘴层（露出 body 的闭嘴）


func _on_mouth_tick() -> void:
	if not _is_talking or _mouth_frames.is_empty() or _mouth == null:
		_mouth_timer.stop()
		return
	_mouth_idx = (_mouth_idx + 1) % _mouth_frames.size()
	_mouth.texture = _mouth_frames[_mouth_idx]
