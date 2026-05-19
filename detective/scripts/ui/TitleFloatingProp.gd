extends TextureRect
## 标题界面漂浮物件
## 支持：上下漂浮、微微旋转、呼吸缩放

@export var float_speed: float = 1.2
@export var float_amplitude: float = 6.0
@export var rot_speed: float = 0.6
@export var rot_amplitude: float = 3.0
@export var phase_offset: float = 0.0
@export var breathe_scale: bool = false
@export var breathe_speed: float = 0.8
@export var breathe_amount: float = 0.02

var _time: float = 0.0
var _base_pos: Vector2
var _base_rot: float
var _base_scale: Vector2


func _ready() -> void:
	_base_pos = position
	_base_rot = rotation
	_base_scale = scale
	# 若未指定相位，随机分配，让多个物件不同步
	if phase_offset == 0.0:
		phase_offset = randf() * TAU
	mouse_filter = MOUSE_FILTER_IGNORE
	expand_mode = EXPAND_IGNORE_SIZE
	stretch_mode = STRETCH_KEEP_ASPECT_CENTERED


func _process(delta: float) -> void:
	_time += delta
	var t: float = _time + phase_offset

	# 上下漂浮
	position.y = _base_pos.y + sin(t * float_speed) * float_amplitude
	# 微微旋转
	rotation = _base_rot + deg_to_rad(sin(t * rot_speed) * rot_amplitude)
	# 呼吸缩放（可选，球体可用）
	if breathe_scale:
		var s: float = 1.0 + sin(t * breathe_speed) * breathe_amount
		scale = _base_scale * s
