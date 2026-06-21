class_name ModularPortrait
extends Control

"""模块化立绘动画系统

架构:
- body_layer: 完整立绘基底 (companion_lingyao.png)
- eyes_layer: 眼睛sprite (切换帧实现眨眼)
- mouth_layer: 嘴巴sprite (切换帧实现说话)

眼睛帧: eyes_open → eyes_half → eyes_closed → eyes_half → eyes_open
嘴巴帧: mouth_closed ↔ mouth_open
"""

# 资源路径
const BASE = preload("res://assets/cn/portraits/companion_lingyao.png")
const EYES_DIR = "res://assets/cn/portraits/anim_layers/lingyao/"
const MOUTH_DIR = "res://assets/cn/portraits/anim_layers/lingyao/"

# 眼睛动画帧序列 (sprite, duration_sec)
var _eye_frames = [
    {"tex": null, "dur": 0.08},  # half
    {"tex": null, "dur": 0.12},  # closed
    {"tex": null, "dur": 0.08},  # half
]

# 位置坐标 (来自Python分析)
const EYES_POS = Vector2(310, 315)
const EYES_SIZE = Vector2(195, 53)
const MOUTH_POS = Vector2(375, 390)
const MOUTH_SIZE = Vector2(100, 55)

# 运行时状态
var _body_layer: TextureRect
var _eyes_layer: TextureRect
var _mouth_layer: TextureRect
var _blink_timer: Timer
var _is_blinking = false
var _is_talking = false

func _ready() -> void:
    # 1. 基底层 (完整立绘)
    _body_layer = TextureRect.new()
    _body_layer.texture = BASE
    _body_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _body_layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _body_layer.set_anchors_preset(PRESET_FULL_RECT)
    _body_layer.mouse_filter = MOUSE_FILTER_IGNORE
    add_child(_body_layer)
    
    # 2. 眼睛层 (覆盖在眼睛位置上方)
    _eyes_layer = TextureRect.new()
    _eyes_layer.texture = load(EYES_DIR + "eyes_open.png")
    _eyes_layer.position = EYES_POS
    _eyes_layer.stretch_mode = TextureRect.STRETCH_SCALE  # 按纹理自然大小显示
    _eyes_layer.mouse_filter = MOUSE_FILTER_IGNORE
    _eyes_layer.z_index = 10
    add_child(_eyes_layer)
    
    # 3. 嘴巴层
    _mouth_layer = TextureRect.new()
    _mouth_layer.texture = load(MOUTH_DIR + "mouth_closed.png")
    _mouth_layer.position = MOUTH_POS
    _mouth_layer.stretch_mode = TextureRect.STRETCH_SCALE  # 按纹理自然大小显示
    _mouth_layer.mouse_filter = MOUSE_FILTER_IGNORE
    _mouth_layer.z_index = 11
    add_child(_mouth_layer)
    
    # 预加载眼睛帧
    _eye_frames[0].tex = load(EYES_DIR + "eyes_half.png")
    _eye_frames[1].tex = load(EYES_DIR + "eyes_closed.png")
    _eye_frames[2].tex = load(EYES_DIR + "eyes_half.png")
    
    # 启动自动眨眼
    _blink_timer = Timer.new()
    _blink_timer.one_shot = true
    _blink_timer.timeout.connect(_do_blink)
    add_child(_blink_timer)
    _schedule_blink()
    
    print("✅ ModularPortrait 初始化完成")
    print("   眼睛位置: ", EYES_POS, ", 大小: ", EYES_SIZE)
    print("   嘴巴位置: ", MOUTH_POS, ", 大小: ", MOUTH_SIZE)

func _schedule_blink() -> void:
    """调度下一次眨眼"""
    if not _is_blinking and is_instance_valid(_blink_timer):
        _blink_timer.start(randf_range(2.5, 5.0))

func _do_blink() -> void:
    """执行完整眨眼动画"""
    if _is_blinking:
        return
    _is_blinking = true
    
    for frame in _eye_frames:
        if not is_instance_valid(_eyes_layer):
            _is_blinking = false
            return
        _eyes_layer.texture = frame.tex
        await get_tree().create_timer(frame.dur).timeout
    
    # 恢复睁眼
    if is_instance_valid(_eyes_layer):
        _eyes_layer.texture = load(EYES_DIR + "eyes_open.png")
    
    _is_blinking = false
    _schedule_blink()

func trigger_blink() -> void:
    """手动触发眨眼 (测试用)"""
    _do_blink()

func set_talking(talking: bool) -> void:
    """设置说话状态"""
    _is_talking = talking
    if talking:
        _mouth_layer.texture = load(MOUTH_DIR + "mouth_open.png")
    else:
        _mouth_layer.texture = load(MOUTH_DIR + "mouth_closed.png")

func _input(event: InputEvent) -> void:
    """测试用: 按B键眨眼，按空格键说话"""
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_B:
            trigger_blink()
        elif event.keycode == KEY_SPACE:
            set_talking(not _is_talking)
