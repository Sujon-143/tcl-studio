@tool
extends BaseShape2D
class_name Rect2D

# ─── Internal ────────────────────────────────────────────────────────────────
var _dash_offset: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# SHAPE
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Shape")

@export var size: Vector2 = Vector2(200, 120):
	set(v): size = v; queue_redraw()

@export_range(0.0, 1.0, 0.01) var progress: float = 1.0:
	set(v): progress = clampf(v, 0.0, 1.0); queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# STROKE
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Stroke")

@export_range(0.5, 100.0, 0.1) var stroke_width: float = 4.0:
	set(v): stroke_width = v; queue_redraw()

@export var color: Color = Color.WHITE:
	set(v): color = v; queue_redraw()

@export var filled: bool = false:
	set(v): filled = v; queue_redraw()

@export var antialiased: bool = true:
	set(v): antialiased = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# DASH
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Dash")

@export var dashed: bool = false:
	set(v): dashed = v; queue_redraw()

@export var dash_length: float = 16.0:
	set(v): dash_length = v; queue_redraw()

@export var gap_length: float = 8.0:
	set(v): gap_length = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# TREADMILL
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Treadmill")

@export var treadmill_enabled: bool = false:
	set(v): treadmill_enabled = v

@export var treadmill_speed: float = 60.0:
	set(v): treadmill_speed = v

@export var treadmill_reverse: bool = false:
	set(v): treadmill_reverse = v

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _enter_tree() -> void:
	pass
	
func _process(delta: float) -> void:
	if treadmill_enabled and dashed:
		var dir := -1.0 if treadmill_reverse else 1.0
		_dash_offset += treadmill_speed * delta * dir
		queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# DRAW
# ═══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	super._draw()
	if filled:
		draw_rect(Rect2(-size/2, size), color)
		return

	var pts := _build_rect_points()
	if pts.size() < 2:
		return

	if dashed:
		_draw_dashed_lines(pts)
	else:
		draw_polyline(pts, color, stroke_width, antialiased)

# ═══════════════════════════════════════════════════════════════════════════════
# RECT PATH GENERATION (fixed progress behaviour)
# ═══════════════════════════════════════════════════════════════════════════════

func _build_rect_points() -> PackedVector2Array:
	if progress <= 0.0:
		return PackedVector2Array()

	var half := size / 2.0
	var corners := [
		Vector2(-half.x, -half.y),  # top-left
		Vector2( half.x, -half.y),  # top-right
		Vector2( half.x,  half.y),  # bottom-right
		Vector2(-half.x,  half.y)   # bottom-left
	]

	# Edges as [start, end, length]
	var edges := [
		[corners[0], corners[1], size.x],
		[corners[1], corners[2], size.y],
		[corners[2], corners[3], size.x],
		[corners[3], corners[0], size.y]
	]

	var perimeter := 2.0 * (size.x + size.y)
	if progress >= 1.0:
		# Full closed rectangle (first point repeated to close the polyline)
		return PackedVector2Array([corners[0], corners[1], corners[2], corners[3], corners[0]])

	var remaining := perimeter * progress
	var points := PackedVector2Array()
	points.append(corners[0])  # always start at first corner

	for edge in edges:
		var start: Vector2 = edge[0]
		var end: Vector2 = edge[1]
		var length: float = edge[2]

		if remaining >= length:
			# Whole edge fits
			points.append(end)
			remaining -= length
		else:
			# Partial edge
			var dir := (end - start).normalized()
			var partial := start + dir * remaining
			points.append(partial)
			break

	return points

# ═══════════════════════════════════════════════════════════════════════════════
# DASHED DRAWING (continuous across segments, supports different dash/gap lengths)
# ═══════════════════════════════════════════════════════════════════════════════

func _draw_dashed_lines(pts: PackedVector2Array) -> void:
	var period := dash_length + gap_length
	var dist := fmod(_dash_offset, period)
	if dist < 0.0: dist += period

	var in_dash := dist < dash_length
	var seg_start := pts[0]
	var dash_start := seg_start

	for i in range(1, pts.size()):
		var seg_end := pts[i]
		var seg_len := seg_start.distance_to(seg_end)
		if seg_len == 0.0:
			seg_start = seg_end
			continue

		var dir := (seg_end - seg_start) / seg_len
		var walked := 0.0

		while walked < seg_len:
			var remaining_in_pattern := (dash_length - dist) if in_dash else (period - dist)
			var step := minf(remaining_in_pattern, seg_len - walked)
			var pos := seg_start + dir * (walked + step)

			if in_dash:
				draw_line(dash_start, pos, color, stroke_width, antialiased)

			walked += step
			dist += step

			if dist >= (dash_length if in_dash else period):
				dist = fmod(dist, period)
				in_dash = !in_dash
				if in_dash:
					dist = 0.0
					dash_start = pos
			elif in_dash:
				dash_start = pos

		seg_start = seg_end

	# Final partial dash if needed
	if in_dash:
		draw_line(dash_start, pts[-1], color, stroke_width, antialiased)
