@tool
extends Node2D
class_name IndicationManager

const CIRCLE_SEGMENTS: int = 64

@export var indication_items: Array[IndicationData] = []:
	set(v):
		indication_items = v
		queue_redraw()

var _redraw_timer: Timer

func _ready() -> void:
	if Engine.is_editor_hint():
		_redraw_timer = Timer.new()
		_redraw_timer.wait_time = 0.1
		_redraw_timer.autostart = true
		_redraw_timer.timeout.connect(queue_redraw)
		add_child(_redraw_timer)

func _draw() -> void:
	for item in indication_items:
		if item == null:
			continue
		match item.indication_shape:
			IndicationData.Shape.RECTANGLE: _draw_rect_item(item)
			IndicationData.Shape.CIRCLE:    _draw_circle_item(item)

# ─── Shape Drawers ────────────────────────────────────────────────────────────

func _draw_rect_item(item: IndicationData) -> void:
	var rect := Rect2(item.indication_position, Vector2(item.rect_width, item.rect_height))
	draw_rect(rect, item.rect_color, true)
	if item.dashed:
		_draw_dashed_rect_outline(rect, item.rect_color, item.dash_length, item.gap_length, item.line_width)

func _draw_circle_item(item: IndicationData) -> void:
	draw_ellipse(item.indication_position, item.circ_width, item.circ_height, item.circ_color, true)
	if item.dashed:
		_draw_dashed_ellipse_outline(item.indication_position, item.circ_width, item.circ_height,
				item.circ_color, item.dash_length, item.gap_length, item.line_width)

# ─── Dashed Outline Helpers ───────────────────────────────────────────────────

func _draw_dashed_rect_outline(
		rect: Rect2, color: Color,
		dash: float, gap: float, width: float) -> void:
	var corners: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x,    rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	for i in corners.size():
		_draw_dashed_line(corners[i], corners[(i + 1) % corners.size()], color, dash, gap, width)

func _draw_dashed_ellipse_outline(
		center: Vector2, rx: float, ry: float, color: Color,
		dash: float, gap: float, width: float) -> void:
	var points: Array[Vector2] = []
	for i in CIRCLE_SEGMENTS:
		var angle := (TAU / CIRCLE_SEGMENTS) * i
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))

	var drawing := true
	var budget  := dash
	for i in points.size():
		var a         := points[i]
		var b         := points[(i + 1) % points.size()]
		var remaining := a.distance_to(b)
		var dir       := (b - a) / remaining
		var pos       := 0.0
		while pos < remaining:
			var chunk := minf(budget, remaining - pos)
			if drawing:
				draw_line(a + dir * pos, a + dir * (pos + chunk), color, width, true)
			pos    += chunk
			budget -= chunk
			if budget <= 0.0:
				drawing = not drawing
				budget  = dash if drawing else gap

func _draw_dashed_line(
		a: Vector2, b: Vector2, color: Color,
		dash: float, gap: float, width: float) -> void:
	var total   := a.distance_to(b)
	var dir     := (b - a) / total
	var pos     := 0.0
	var drawing := true
	while pos < total:
		var chunk := minf(dash if drawing else gap, total - pos)
		if drawing:
			draw_line(a + dir * pos, a + dir * (pos + chunk), color, width, true)
		pos    += chunk
		drawing = not drawing
