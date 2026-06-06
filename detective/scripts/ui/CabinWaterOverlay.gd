extends Control
class_name CabinWaterOverlay

var level: float = 0.26:
	set(value):
		level = clamp(value, 0.0, 0.92)
		queue_redraw()

var _phase := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_phase += delta * 1.7
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var top_y := size.y * (1.0 - level)
	var points := PackedVector2Array()
	points.append(Vector2(0.0, size.y))
	var steps := 28
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := t * size.x
		var wave := sin(t * TAU * 3.0 + _phase) * 5.0 + sin(t * TAU * 7.0 - _phase * 0.7) * 2.0
		points.append(Vector2(x, top_y + wave))
	points.append(Vector2(size.x, size.y))
	draw_colored_polygon(points, Color(0.025, 0.145, 0.19, 0.68))

	var crest := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := t * size.x
		var wave := sin(t * TAU * 3.0 + _phase) * 5.0 + sin(t * TAU * 7.0 - _phase * 0.7) * 2.0
		crest.append(Vector2(x, top_y + wave))
	draw_polyline(crest, Color(0.62, 0.88, 0.95, 0.42), 2.0, true)
