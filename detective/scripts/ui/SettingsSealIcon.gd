extends Control

var _hovered := false
var _pressed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_visual_state(is_hovered: bool, is_pressed: bool) -> void:
	if _hovered == is_hovered and _pressed == is_pressed:
		return
	_hovered = is_hovered
	_pressed = is_pressed
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	if _pressed:
		center += Vector2(0.0, 0.8)
	var bronze_dark := Color(0.40, 0.25, 0.09, 1.0)
	var bronze_mid := Color(0.70, 0.51, 0.19, 1.0)
	var bronze_hi := Color(0.95, 0.79, 0.40, 1.0)
	var lacquer := Color(0.16, 0.10, 0.05, 0.88)
	if _hovered:
		bronze_mid = bronze_mid.lightened(0.10)
		bronze_hi = bronze_hi.lightened(0.08)
		lacquer = lacquer.lightened(0.08)
	var outer_radius: float = minf(size.x, size.y) * 0.42
	var ring_radius: float = outer_radius - 3.4
	var inner_radius: float = outer_radius * 0.54
	var shadow_offset := Vector2(0.0, 1.6)

	draw_circle(center + shadow_offset, outer_radius + 1.6, Color(0, 0, 0, 0.26))
	draw_circle(center, outer_radius + 0.2, lacquer)
	draw_arc(center, outer_radius - 0.2, 0, TAU, 48, bronze_dark, 2.6, true)
	draw_arc(center, ring_radius, 0, TAU, 48, bronze_mid, 2.2, true)

	for i in range(8):
		var angle := (TAU / 8.0) * i + PI / 8.0
		var dir := Vector2.RIGHT.rotated(angle)
		var tooth_start := center + dir * (ring_radius + 0.5)
		var tooth_end := center + dir * (outer_radius + 1.8)
		draw_line(tooth_start, tooth_end, bronze_dark, 2.8)
		draw_line(tooth_start, tooth_end, bronze_hi if i % 2 == 0 else bronze_mid, 1.2)

	draw_arc(center, inner_radius + 3.2, -0.42, TAU - 0.42, 40, bronze_dark, 1.7, true)
	draw_arc(center, inner_radius + 1.6, 0.18, TAU + 0.18, 40, bronze_hi, 1.1, true)

	for angle in [0.0, PI * 0.5, PI * 0.25, -PI * 0.25]:
		var dir := Vector2.RIGHT.rotated(angle)
		var spoke_from := center - dir * (inner_radius * 0.78)
		var spoke_to := center + dir * (inner_radius * 0.78)
		draw_line(spoke_from, spoke_to, bronze_dark, 2.1)
		draw_line(spoke_from, spoke_to, bronze_mid, 0.9)

	var diamond_radius: float = inner_radius * 0.64
	var diamond := PackedVector2Array([
		center + Vector2(0, -diamond_radius),
		center + Vector2(diamond_radius, 0),
		center + Vector2(0, diamond_radius),
		center + Vector2(-diamond_radius, 0),
	])
	draw_colored_polygon(diamond, Color(0.11, 0.07, 0.04, 0.34))
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), bronze_dark, 1.0, true)

	draw_circle(center, 4.2, Color(0.12, 0.07, 0.04, 0.96))
	draw_arc(center, 4.6, 0, TAU, 24, bronze_hi, 1.4, true)
	draw_circle(center, 1.5, bronze_hi)

	draw_arc(center, ring_radius - 4.6, -0.55, 0.38, 16, bronze_hi, 1.1, true)
	draw_arc(center, ring_radius - 4.6, PI - 0.36, PI + 0.62, 16, bronze_mid, 1.1, true)
