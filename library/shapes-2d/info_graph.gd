@tool
class_name InfographicLink
extends BaseShape2D

# ─── Internal ─────────────────────────────────────────────────────────────────
var _source_node: Node2D = null
var _target_node: Node2D = null
var _last_source_pos := Vector2.ZERO
var _last_target_pos := Vector2.ZERO

# ─── Nodes to connect ────────────────────────────────────────────────────────
@export_group("Nodes")
## Leave empty to use this node's own position as the start point.
@export var source: NodePath = NodePath():
	set(v):
		source = v
		_resolve_nodes()
		_update_resolved_points()

## The target node the line should end at.
@export var target: NodePath = NodePath():
	set(v):
		target = v
		_resolve_nodes()
		_update_resolved_points()

# ─── Curve ───────────────────────────────────────────────────────────────────
@export_group("Curve")
## How much the line bends away from the straight connection.
## Positive = right side, negative = left side (relative to direction from source to target).
@export_range(-500.0, 500.0, 1.0) var curve_offset: float = 0.0:
	set(v):
		curve_offset = v
		_update_resolved_points()

## Number of segments used to draw the curve.
@export_range(8, 128, 1) var curve_resolution: int = 32:
	set(v):
		curve_resolution = v
		_update_resolved_points()

# ─── Visuals ─────────────────────────────────────────────────────────────────
@export_group("Visuals")
@export var line_color: Color = Color.WHITE:
	set(v):
		line_color = v
		queue_redraw()

@export_range(0.5, 50.0, 0.1) var line_width: float = 3.0:
	set(v):
		line_width = v
		queue_redraw()

@export var dashed: bool = false:
	set(v):
		dashed = v
		queue_redraw()

@export_range(1.0, 200.0, 0.5) var dash_length: float = 12.0:
	set(v):
		dash_length = v
		queue_redraw()

@export_range(1.0, 200.0, 0.5) var gap_length: float = 8.0:
	set(v):
		gap_length = v
		queue_redraw()

# ─── Arrows ──────────────────────────────────────────────────────────────────
@export_group("Arrows")
enum ArrowStyle { NONE, FILLED, OPEN }

@export var arrow_start: ArrowStyle = ArrowStyle.NONE:
	set(v):
		arrow_start = v
		queue_redraw()

@export var arrow_end: ArrowStyle = ArrowStyle.FILLED:
	set(v):
		arrow_end = v
		queue_redraw()

@export_range(4.0, 60.0, 0.5) var arrow_size: float = 12.0:
	set(v):
		arrow_size = v
		queue_redraw()

@export_range(10.0, 70.0, 1.0) var arrow_angle: float = 30.0:
	set(v):
		arrow_angle = v
		queue_redraw()

# ─── Label ───────────────────────────────────────────────────────────────────
@export_group("Label")
@export_multiline var label_text: String = "":
	set(v):
		label_text = v
		queue_redraw()

@export var label_color: Color = Color.WHITE:
	set(v):
		label_color = v
		queue_redraw()

@export var font: Font:
	set(v):
		font = v
		queue_redraw()

@export var font_size: int = 16:
	set(v):
		font_size = v
		queue_redraw()

# ─── Behaviour ────────────────────────────────────────────────────────────────
@export_group("Behaviour")
## Continuously redraw when source or target moves (less performance friendly).
@export var auto_refresh: bool = false

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	_resolve_nodes()
	_update_resolved_points()

func _enter_tree() -> void:
	_resolve_nodes()
	_update_resolved_points()

func _process(_delta: float) -> void:
	if not auto_refresh:
		return
	if not is_instance_valid(_source_node) and not source.is_empty():
		_resolve_nodes()
	if not is_instance_valid(_target_node) and not target.is_empty():
		_resolve_nodes()

	var s_pos := _get_source_pos()
	var t_pos := _get_target_pos()
	if s_pos != _last_source_pos or t_pos != _last_target_pos:
		_last_source_pos = s_pos
		_last_target_pos = t_pos
		_update_resolved_points()

func _draw() -> void:
	super._draw()
	if resolved_points.size() < 2:
		return

	var pts := resolved_points
	if not dashed:
		draw_polyline(pts, line_color, line_width, true)
	else:
		_draw_dashed(pts)

	# Arrows
	if arrow_end != ArrowStyle.NONE and pts.size() >= 2:
		var tip := pts[-1]
		var dir := (pts[-1] - pts[-2]).normalized()
		_draw_arrow(tip, dir, arrow_end)

	if arrow_start != ArrowStyle.NONE and pts.size() >= 2:
		var tip := pts[0]
		var dir := (pts[0] - pts[1]).normalized()
		_draw_arrow(tip, dir, arrow_start)

	# Label at midpoint
	if not label_text.is_empty() and pts.size() >= 2:
		var mid_idx := pts.size() / 2
		var pos := pts[mid_idx]
		var col := label_color
		if font:
			draw_string(font, pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, col)
		else:
			# fallback: draw a small marker
			draw_circle(pos, 3, col)

# ─── Helpers ─────────────────────────────────────────────────────────────────

func _resolve_nodes() -> void:
	var s := get_node_or_null(source) as Node2D if not source.is_empty() else self
	if s != _source_node:
		_source_node = s
		_last_source_pos = _get_source_pos()

	var t := get_node_or_null(target) as Node2D if not target.is_empty() else null
	if t != _target_node:
		_target_node = t
		_last_target_pos = _get_target_pos()

func _get_source_pos() -> Vector2:
	return _source_node.global_position if is_instance_valid(_source_node) else global_position

func _get_target_pos() -> Vector2:
	return _target_node.global_position if is_instance_valid(_target_node) else Vector2.ZERO

func _update_resolved_points() -> void:
	var s := _get_source_pos()
	var t := _get_target_pos()
	if s.distance_squared_to(t) < 0.01:
		resolved_points = PackedVector2Array()
		return

	var pts := PackedVector2Array()
	if curve_offset == 0.0:
		# straight line
		for i in range(curve_resolution + 1):
			var f := float(i) / float(curve_resolution)
			pts.append(s.lerp(t, f))
	else:
		var mid := (s + t) * 0.5
		var dir := (t - s).normalized()
		var perp := Vector2(-dir.y, dir.x)   # rotate 90° left
		var ctrl := mid + perp * curve_offset
		for i in range(curve_resolution + 1):
			var f := float(i) / float(curve_resolution)
			pts.append(_quadratic_bezier(s, ctrl, t, f))
	resolved_points = pts
	queue_redraw()

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

# ─── Dashed line drawing (similar to Arrow2D) ────────────────────────────────
func _draw_dashed(pts: PackedVector2Array) -> void:
	var period := dash_length + gap_length
	var dist_in_cycle := 0.0
	var in_dash := true
	var seg_start := pts[0]
	var dash_start := seg_start

	for i in range(1, pts.size()):
		var seg_end := pts[i]
		var seg_len := seg_start.distance_to(seg_end)
		if seg_len == 0.0:
			seg_start = seg_end
			continue
		var seg_dir := (seg_end - seg_start) / seg_len
		var walked := 0.0

		while walked < seg_len:
			var remaining: float = (dash_length - dist_in_cycle) if in_dash else (period - dist_in_cycle)
			var step := minf(remaining, seg_len - walked)
			var pos := seg_start + seg_dir * (walked + step)

			if in_dash:
				draw_line(dash_start, pos, line_color, line_width, true)

			walked += step
			dist_in_cycle += step

			if dist_in_cycle >= (dash_length if in_dash else period):
				dist_in_cycle = fmod(dist_in_cycle, period)
				in_dash = !in_dash
				if in_dash:
					dist_in_cycle = 0.0
					dash_start = pos
			elif in_dash:
				dash_start = pos

		seg_start = seg_end

	if in_dash:
		draw_line(dash_start, pts[-1], line_color, line_width, true)

# ─── Arrow drawing ───────────────────────────────────────────────────────────
func _draw_arrow(tip: Vector2, dir: Vector2, style: ArrowStyle) -> void:
	var ang := deg_to_rad(arrow_angle)
	var left  := tip - dir.rotated(-ang) * arrow_size
	var right := tip - dir.rotated( ang) * arrow_size

	match style:
		ArrowStyle.FILLED:
			draw_colored_polygon(PackedVector2Array([tip, left, right]), line_color)
		ArrowStyle.OPEN:
			draw_line(tip, left,  line_color, line_width, true)
			draw_line(tip, right, line_color, line_width, true)
