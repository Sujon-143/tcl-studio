@tool
extends BaseShape2D
class_name Circle2D

# ─── Internal ─────────────────────────────────────────────────────────────────
# Accumulated dash offset – never clamped to avoid fmod phase jumps.
var _dash_offset: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# SHAPE
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Shape")

@export_range(1.0, 2000.0, 0.1) var radius: float = 100.0:
	set(v): radius = v; _update_resolved_points(); queue_redraw()

@export_range(-360.0, 360.0, 0.1) var angle_start: float = 0.0:
	set(v): angle_start = v; _update_resolved_points(); queue_redraw()

@export_range(0.0, 1.0, 0.01) var progress: float = 1.0:
	set(v): progress = v; _update_resolved_points(); queue_redraw()

@export_range(16, 512, 1) var resolution: int = 128:
	set(v): resolution = v; _update_resolved_points(); queue_redraw()

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

@export_range(1.0, 200.0, 0.5) var dash_length: float = 16.0:
	set(v): dash_length = v; queue_redraw()

@export_range(1.0, 200.0, 0.5) var gap_length: float = 8.0:
	set(v): gap_length = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# TREADMILL
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Treadmill")

@export var treadmill_enabled: bool = false:
	set(v): treadmill_enabled = v

@export_range(0.0, 800.0, 1.0) var treadmill_speed: float = 60.0:
	set(v): treadmill_speed = v

@export var treadmill_reverse: bool = false:
	set(v): treadmill_reverse = v

# ═══════════════════════════════════════════════════════════════════════════════
# ARROWHEADS
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Arrowheads")

enum ArrowheadStyle { NONE, FILLED, OPEN, CIRCLE, DIAMOND }

@export var arrow_tip: ArrowheadStyle = ArrowheadStyle.NONE:
	set(v): arrow_tip = v; queue_redraw()

@export var arrow_tail: ArrowheadStyle = ArrowheadStyle.NONE:
	set(v): arrow_tail = v; queue_redraw()

@export var arrow_follow_treadmill: bool = false:
	set(v): arrow_follow_treadmill = v; queue_redraw()

@export_range(4.0, 120.0, 0.5) var arrow_size: float = 18.0:
	set(v): arrow_size = v; queue_redraw()

@export_range(10.0, 70.0, 1.0) var arrow_angle: float = 28.0:
	set(v): arrow_angle = v; queue_redraw()

@export_range(0, 32, 1) var arrow_count: int = 0:
	set(v): arrow_count = v; queue_redraw()

@export var distributed_follow_treadmill: bool = true:
	set(v): distributed_follow_treadmill = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super._ready()
	_update_resolved_points()

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
		_draw_filled()
		return

	var a_start := deg_to_rad(angle_start)
	var full_span := TAU * progress

	# Trim the stroke so it ends exactly at the arrowhead base (arc length = arrow_size).
	var trim_rad := arrow_size / maxf(radius, 0.001)

	var draw_a_start := a_start
	var draw_a_end   := a_start + full_span

	var has_tip  := arrow_tip  != ArrowheadStyle.NONE
	var has_tail := arrow_tail != ArrowheadStyle.NONE

	if has_tail: draw_a_start += trim_rad
	if has_tip:  draw_a_end   -= trim_rad

	if draw_a_end > draw_a_start:
		var pts := _build_arc_points(draw_a_start, draw_a_end)
		if pts.size() >= 2:
			if dashed:
				_draw_dashed(pts)
			else:
				draw_polyline(pts, color, stroke_width, antialiased)

	# Draw arrowheads at the original (untrimmed) angles.
	if has_tip:
		var fwd := (not treadmill_reverse) if arrow_follow_treadmill else true
		_draw_arrowhead(a_start + full_span, fwd, arrow_tip)

	if has_tail:
		var fwd := treadmill_reverse if arrow_follow_treadmill else false
		_draw_arrowhead(a_start, fwd, arrow_tail)

	_draw_distributed_arrows(a_start, full_span)

# ═══════════════════════════════════════════════════════════════════════════════
# ARC POINT GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

func _build_arc_points(a_from: float, a_to: float) -> PackedVector2Array:
	var pts: PackedVector2Array
	var fraction := (a_to - a_from) / TAU
	var steps    := maxi(2, int(ceil(resolution * fraction)))
	for i in range(steps + 1):
		var t     := float(i) / float(steps)
		var angle :float= lerp(a_from, a_to, t)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _circle_tangent(angle: float, forward: bool) -> Vector2:
	var t := Vector2(-sin(angle), cos(angle))
	return t if forward else -t

func _draw_filled() -> void:
	var pts: PackedVector2Array
	pts.append(Vector2.ZERO)
	var a_start := deg_to_rad(angle_start)
	var steps   := maxi(2, int(resolution * progress))
	for i in range(steps + 1):
		var t     := float(i) / float(steps)
		var angle :float= lerp(a_start, a_start + TAU * progress, t)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(pts, color)

# ═══════════════════════════════════════════════════════════════════════════════
# DASHED DRAWING
# ═══════════════════════════════════════════════════════════════════════════════

func _draw_dashed(pts: PackedVector2Array) -> void:
	var period  := dash_length + gap_length
	# Get non‑negative remainder without fmod to avoid floating point glitches.
	var dist    :float= _dash_offset - floor(_dash_offset / period) * period
	if dist < 0.0: dist += period
	var in_dash    := dist < dash_length
	var seg_start  := pts[0]
	var dash_start := seg_start

	for i in range(1, pts.size()):
		var seg_end := pts[i]
		var seg_len := seg_start.distance_to(seg_end)
		if seg_len == 0.0:
			seg_start = seg_end
			continue
		var dir    := (seg_end - seg_start) / seg_len
		var walked := 0.0

		while walked < seg_len:
			var remaining := (dash_length - dist) if in_dash else (period - dist)
			var step      := minf(remaining, seg_len - walked)
			var pos       := seg_start + dir * (walked + step)

			if in_dash:
				draw_line(dash_start, pos, color, stroke_width, antialiased)

			walked += step
			dist   += step

			if dist >= (dash_length if in_dash else period):
				dist    = fmod(dist, period)
				in_dash = !in_dash
				if in_dash:
					dist       = 0.0
					dash_start = pos
			elif in_dash:
				dash_start = pos

		seg_start = seg_end

	# Finish the last dash if needed.
	if in_dash:
		draw_line(dash_start, pts[-1], color, stroke_width, antialiased)

# ═══════════════════════════════════════════════════════════════════════════════
# ARROWHEAD RENDERING – all heads now lie exactly on the circle.
# ═══════════════════════════════════════════════════════════════════════════════

func _draw_arrowhead(angle: float, forward: bool, style: ArrowheadStyle) -> void:
	var tip := Vector2(cos(angle), sin(angle)) * radius
	var dir := _circle_tangent(angle, forward)

	match style:
		ArrowheadStyle.FILLED, ArrowheadStyle.OPEN:
			var delta_angle := arrow_size / radius
			var _sign := 1.0 if forward else -1.0

			var la := angle + _sign * delta_angle
			var ra := angle - _sign * delta_angle
			var lp := Vector2(cos(la), sin(la)) * radius
			var rp := Vector2(cos(ra), sin(ra)) * radius

			if style == ArrowheadStyle.FILLED:
				draw_colored_polygon(PackedVector2Array([tip, lp, rp]), color)
			else: # OPEN
				draw_line(tip, lp, color, stroke_width, antialiased)
				draw_line(tip, rp, color, stroke_width, antialiased)

		ArrowheadStyle.CIRCLE:
			var center := tip - dir * (arrow_size * 0.5)
			draw_circle(center, arrow_size * 0.5, color)

		ArrowheadStyle.DIAMOND:
			var delta_angle := arrow_size / radius
			var _sign := 1.0 if forward else -1.0

			var la := angle + _sign * delta_angle
			var ra := angle - _sign * delta_angle
			var lp := Vector2(cos(la), sin(la)) * radius
			var rp := Vector2(cos(ra), sin(ra)) * radius
			var back := tip - dir * arrow_size

			draw_colored_polygon(PackedVector2Array([tip, lp, back, rp]), color)

func _draw_distributed_arrows(a_start: float, full_span: float) -> void:
	if arrow_count <= 0:
		return
	var arc_length := radius * full_span
	for k in range(arrow_count):
		var arc_dist := arc_length * (float(k) + 0.5) / float(arrow_count)
		var angle    := a_start + arc_dist / radius
		var fwd      := (not treadmill_reverse) if distributed_follow_treadmill else true
		_draw_arrowhead(angle, fwd, ArrowheadStyle.FILLED)

# ═══════════════════════════════════════════════════════════════════════════════
# RESOLVED POINTS UPDATE
# ═══════════════════════════════════════════════════════════════════════════════

## Called whenever a property that changes the arc geometry itself is changed.
## Stores the current arc points (before trimming) in BaseShape2D.resolved_points.
func _update_resolved_points() -> void:
	var a_start := deg_to_rad(angle_start)
	var a_end := a_start + TAU * progress
	resolved_points = _build_arc_points(a_start, a_end)
