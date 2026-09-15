@tool
extends BaseShape2D
class_name Arrow2D

# ─── Internal ────────────────────────────────────────────────────────────────
var _dash_offset: float = 0.0

@export_category("visual settings")
# ─── Stroke ──────────────────────────────────────────────────────────────────
@export_range(1.0, 100.0, 0.1) var stroke_width: float = 4.0:
	set(v): stroke_width = v; queue_redraw()
	get: return stroke_width

@export var color: Color = Color.WHITE:
	set(v): color = v; queue_redraw()
	get: return color

@export var antialiased: bool = true:
	set(v): antialiased = v; queue_redraw()
	get: return antialiased

# ─── Points ───────────────────────────────────────────────────────────────────
@export var start: Vector2 = Vector2(-100, 0):
	set(v): start = v; _update_resolved_points(); queue_redraw()
	get: return start

@export var end: Vector2 = Vector2(100, 0):
	set(v): end = v; _update_resolved_points(); queue_redraw()
	get: return end

# ─── Arrowhead ───────────────────────────────────────────────────────────────
enum ArrowheadStyle { NONE, FILLED, OUTLINE, OPEN, CIRCLE, DIAMOND }

@export var head_start: ArrowheadStyle = ArrowheadStyle.NONE:
	set(v): head_start = v; queue_redraw()
	get: return head_start

@export var head_end: ArrowheadStyle = ArrowheadStyle.FILLED:
	set(v): head_end = v; queue_redraw()
	get: return head_end

@export_range(4.0, 80.0, 0.5) var head_size: float = 16.0:
	set(v): head_size = v; queue_redraw()
	get: return head_size

## Angle of each arrowhead wing in degrees
@export_range(10.0, 80.0, 1.0) var head_angle: float = 25.0:
	set(v): head_angle = v; queue_redraw()
	get: return head_angle

# ─── Dash ─────────────────────────────────────────────────────────────────────
@export var dashed: bool = false:
	set(v): dashed = v; queue_redraw()
	get: return dashed

@export_range(2.0, 200.0, 1.0) var dash_length: float = 16.0:
	set(v): dash_length = v; queue_redraw()
	get: return dash_length

@export_range(1.0, 200.0, 1.0) var gap_length: float = 8.0:
	set(v): gap_length = v; queue_redraw()
	get: return gap_length

# ─── Treadmill ────────────────────────────────────────────────────────────────
@export var treadmill_enabled: bool = false:
	set(v): treadmill_enabled = v
	get: return treadmill_enabled

@export_range(0.0, 600.0, 1.0) var treadmill_speed: float = 60.0:
	set(v): treadmill_speed = v
	get: return treadmill_speed

@export var treadmill_reverse: bool = false:
	set(v): treadmill_reverse = v
	get: return treadmill_reverse

# ─── Progress ─────────────────────────────────────────────────────────────────
## 0 = nothing drawn, 1 = full line. Tween this for animated reveal.
@export_range(0.0, 1.0, 0.01) var progress: float = 1.0:
	set(v): progress = v; _update_resolved_points(); queue_redraw()
	get: return progress

# ─── Curvature ────────────────────────────────────────────────────────────────
## Pull the midpoint perpendicular to the line. 0 = straight.
@export_range(-400.0, 400.0, 1.0) var curvature: float = 0.0:
	set(v): curvature = v; _update_resolved_points(); queue_redraw()
	get: return curvature

## How many segments to tesselate the bezier into
@export_range(4, 128, 1) var curve_resolution: int = 32:
	set(v): curve_resolution = v; _update_resolved_points(); queue_redraw()
	get: return curve_resolution


# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	_update_resolved_points()

func _process(delta: float) -> void:
	if treadmill_enabled and dashed:
		var dir := -1.0 if treadmill_reverse else 1.0
		_dash_offset += treadmill_speed * delta * dir
		var period := dash_length + gap_length
		_dash_offset = fmod(_dash_offset, period)
		if _dash_offset < 0.0:
			_dash_offset += period
		queue_redraw()


func _draw() -> void:
	super._draw()
	var pts := _build_points()
	if pts.size() < 2:
		return
	
	if progress<=0.1:
		return
	
	# Shorten line endpoints so they don't poke through arrowheads
	var draw_pts := pts.duplicate()
	if head_end != ArrowheadStyle.NONE:
		draw_pts = _trim_end(draw_pts, head_size * 0.6)
	if head_start != ArrowheadStyle.NONE:
		draw_pts = _trim_start(draw_pts, head_size * 0.6)

	# Line
	if not dashed:
		draw_polyline(draw_pts, color, stroke_width, antialiased)
	else:
		_draw_dashed(draw_pts)

	# Arrowheads drawn on original (non-trimmed) endpoints
	if head_end != ArrowheadStyle.NONE:
		var tip := pts[-1]
		var incoming := (pts[-1] - pts[-2]).normalized()
		_draw_head(tip, incoming, head_end)

	if head_start != ArrowheadStyle.NONE:
		var tip := pts[0]
		var incoming := (pts[0] - pts[1]).normalized()
		_draw_head(tip, incoming, head_start)


# ─── Point generation ─────────────────────────────────────────────────────────
func _build_points() -> PackedVector2Array:
	var pts: PackedVector2Array

	if curvature == 0.0:
		# Generate same number of points as curved mode so progress works smoothly
		for i in range(curve_resolution + 1):
			var t := float(i) / float(curve_resolution)
			pts.append(start.lerp(end, t))
	else:
		var mid := (start + end) * 0.5
		var perp := (end - start).normalized().rotated(PI * 0.5)
		var ctrl := mid + perp * curvature
		for i in range(curve_resolution + 1):
			var t := float(i) / float(curve_resolution)
			pts.append(_bezier(start, ctrl, end, t))

	# Apply progress
	var keep := maxi(2, int(ceil(pts.size() * progress)))
	pts = pts.slice(0, keep)

	return pts
	
	
func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2


# ─── Dashed drawing ───────────────────────────────────────────────────────────
func _draw_dashed(pts: PackedVector2Array) -> void:
	var period := dash_length + gap_length
	var dist_in_cycle := fmod(_dash_offset, period)
	var in_dash := dist_in_cycle < dash_length
	var seg_start := pts[0]
	var dash_seg_start := seg_start

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
				draw_line(dash_seg_start, pos, color, stroke_width, antialiased)

			walked += step
			dist_in_cycle += step

			if dist_in_cycle >= (dash_length if in_dash else period):
				dist_in_cycle = fmod(dist_in_cycle, period)
				in_dash = !in_dash
				if in_dash:
					dist_in_cycle = 0.0
					dash_seg_start = pos
			elif in_dash:
				dash_seg_start = pos

		seg_start = seg_end

	if in_dash:
		draw_line(dash_seg_start, pts[-1], color, stroke_width, antialiased)


# ─── Arrowhead drawing ────────────────────────────────────────────────────────
func _draw_head(tip: Vector2, dir: Vector2, style: ArrowheadStyle) -> void:
	var angle := deg_to_rad(head_angle)
	var left  := tip - dir.rotated(-angle) * head_size
	var right := tip - dir.rotated( angle) * head_size
	var _base_mid := tip - dir * head_size  # midpoint between wings

	match style:
		ArrowheadStyle.FILLED:
			draw_polyline(PackedVector2Array([left,right,tip,left]),color,1,true)
			draw_colored_polygon(PackedVector2Array([tip, left, right]), color)

		ArrowheadStyle.OUTLINE:
			draw_colored_polygon(PackedVector2Array([tip, left, right]), color)
			draw_polyline(PackedVector2Array([tip, left, right, tip]),
				Color(0, 0, 0, 0.35), stroke_width * 0.5, antialiased)

		ArrowheadStyle.OPEN:
			draw_line(tip, left,  color, stroke_width, antialiased)
			draw_line(tip, right, color, stroke_width, antialiased)

		ArrowheadStyle.CIRCLE:
			var radius := head_size * 0.5
			var center := tip - dir * radius
			draw_circle(center, radius, color)

		ArrowheadStyle.DIAMOND:
			var back := tip - dir * head_size * 2.0
			draw_colored_polygon(
				PackedVector2Array([tip, left, back, right]), color)


# ─── Trim helpers (keep head from overlapping line) ───────────────────────────
func _trim_end(pts: PackedVector2Array, amount: float) -> PackedVector2Array:
	var result := pts.duplicate()
	var remaining := amount
	while result.size() > 1 and remaining > 0.0:
		var last := result[-1]
		var prev := result[-2]
		var seg_len := prev.distance_to(last)
		if seg_len <= remaining:
			result.remove_at(result.size() - 1)
			remaining -= seg_len
		else:
			result[-1] = last + (prev - last).normalized() * remaining
			remaining = 0.0
	return result


func _trim_start(pts: PackedVector2Array, amount: float) -> PackedVector2Array:
	var result := pts.duplicate()
	var remaining := amount
	while result.size() > 1 and remaining > 0.0:
		var first := result[0]
		var next  := result[1]
		var seg_len := first.distance_to(next)
		if seg_len <= remaining:
			result.remove_at(0)
			remaining -= seg_len
		else:
			result[0] = first + (next - first).normalized() * remaining
			remaining = 0.0
	return result


# ─── Resolved points update ───────────────────────────────────────────────────
## Call whenever a property that changes the spine geometry itself is set.
## Stores the current path (before trimming) in BaseShape2D.resolved_points.
func _update_resolved_points() -> void:
	resolved_points = _build_points()
