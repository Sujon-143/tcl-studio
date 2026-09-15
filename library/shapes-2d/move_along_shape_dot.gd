@tool
class_name MoveAlongShape
extends BaseShape2D

# ─── Internal ─────────────────────────────────────────────────────────────────
var _target_node: BaseShape2D = null

# ═══════════════════════════════════════════════════════════════════════════════
# TARGET
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Target")

## NodePath to any BaseShape2D that exposes a resolved_points array (Arrow2D, etc.)
@export var target: NodePath = NodePath():
	set(v):
		target = v
		_target_node = get_node_or_null(v) as BaseShape2D
		_update_position()

## Normalized position along the path (0 = start, 1 = end)
@export_range(0.0, 1.0, 0.001) var progress: float = 0.0:
	set(v):
		progress = v
		_update_position()

# ═══════════════════════════════════════════════════════════════════════════════
# VISUAL
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Visual")

enum DotStyle { CIRCLE, DIAMOND, SQUARE, RING, CROSS }

@export var dot_style: DotStyle = DotStyle.CIRCLE:
	set(v): dot_style = v; queue_redraw()

@export_range(2.0, 120.0, 0.5) var dot_radius: float = 10.0:
	set(v): dot_radius = v; queue_redraw()

@export var dot_color: Color = Color.WHITE:
	set(v): dot_color = v; queue_redraw()

@export var dot_filled: bool = true:
	set(v): dot_filled = v; queue_redraw()

@export_range(0.5, 20.0, 0.1) var outline_width: float = 2.0:
	set(v): outline_width = v; queue_redraw()

@export var outline_color: Color = Color.TRANSPARENT:
	set(v): outline_color = v; queue_redraw()

@export var antialiased: bool = true:
	set(v): antialiased = v; queue_redraw()

# ─── Orientation Indicator ────────────────────────────────────────────────────

@export_subgroup("Orientation Indicator")

@export var show_orientation: bool = false:
	set(v): show_orientation = v; queue_redraw()

enum OrientationStyle { TICK, ARROW }

@export var orientation_style: OrientationStyle = OrientationStyle.TICK:
	set(v): orientation_style = v; queue_redraw()

@export_range(2.0, 80.0, 0.5) var orientation_length: float = 18.0:
	set(v): orientation_length = v; queue_redraw()

@export_range(0.5, 20.0, 0.1) var orientation_width: float = 2.0:
	set(v): orientation_width = v; queue_redraw()

@export var orientation_color: Color = Color.YELLOW:
	set(v): orientation_color = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# ANIMATION
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Animation")

@export var animate: bool = false

## Fraction of the path traversed per second (0.01–10.0)
@export_range(0.01, 10.0, 0.01) var speed: float = 1.0

@export var reverse: bool = false

@export var loop: bool = true

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _enter_tree() -> void:
	if target != NodePath():
		_target_node = get_node_or_null(target) as BaseShape2D
	_update_position()

func _process(delta: float) -> void:
	if animate:
		var dir := -1.0 if reverse else 1.0
		progress += dir * speed * delta
		if loop:
			progress = fmod(progress, 1.0)
			if progress < 0.0:
				progress += 1.0
		else:
			progress = clampf(progress, 0.0, 1.0)
		# The progress setter calls _update_position() and queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# PATH HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

## Returns the total length of the target shape's resolved_points.
func _get_path_length() -> float:
	if not _target_node or _target_node.resolved_points.size() < 2:
		return 1.0
	var pts := _target_node.resolved_points
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i-1].distance_to(pts[i])
	return maxf(total, 1.0)

## Given a normalized t (0..1), returns the point on the polyline in the target's local space.
func _sample_path(t: float) -> Vector2:
	var pts := _target_node.resolved_points if _target_node else PackedVector2Array()
	if pts.size() < 2:
		return Vector2.ZERO
	var t_clamped := clampf(t, 0.0, 1.0)
	var total_dist := _get_path_length()
	if total_dist == 1.0:  # fallback for single point or empty
		return pts[0]
	var target_dist := t_clamped * total_dist
	var walked := 0.0
	for i in range(1, pts.size()):
		var seg_len := pts[i-1].distance_to(pts[i])
		if seg_len == 0.0:
			continue
		if walked + seg_len >= target_dist:
			var frac := (target_dist - walked) / seg_len
			return pts[i-1].lerp(pts[i], frac)
		walked += seg_len
	return pts[-1]

## Returns the tangent direction (unit vector) in target local space at progress t.
func _sample_tangent(t: float) -> Vector2:
	var pts := _target_node.resolved_points if _target_node else PackedVector2Array()
	if pts.size() < 2:
		return Vector2.RIGHT
	# sample a tiny step forward to get direction
	var p0 := _sample_path(t)
	var p1 := _sample_path(minf(t + 0.001, 1.0))
	var dir := p1 - p0
	if dir.length_squared() < 0.000001:
		# probably at end, try backward
		p1 = _sample_path(maxf(t - 0.001, 0.0))
		dir = p0 - p1
	return dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT

# ═══════════════════════════════════════════════════════════════════════════════
# POSITION
# ═══════════════════════════════════════════════════════════════════════════════

func _update_position() -> void:
	if not _target_node or _target_node.resolved_points.size() < 2:
		queue_redraw()
		return
	var local_pos := _sample_path(progress)
	var world_pos := _target_node.to_global(local_pos)
	global_position = world_pos
	queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# DRAW  –  always at Vector2.ZERO in local space
# ═══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	super._draw()
	_draw_dot()
	if show_orientation:
		_draw_orientation()

func _draw_dot() -> void:
	match dot_style:
		DotStyle.CIRCLE:
			if dot_filled:
				draw_circle(Vector2.ZERO, dot_radius, dot_color, antialiased)
			if outline_color.a > 0.0:
				_draw_circle_outline(dot_radius, dot_color if not dot_filled else outline_color)

		DotStyle.RING:
			_draw_circle_outline(dot_radius, dot_color)
			if outline_color.a > 0.0:
				_draw_circle_outline(dot_radius + outline_width, outline_color)

		DotStyle.DIAMOND:
			var pts := PackedVector2Array([
				Vector2(0, -dot_radius), Vector2(dot_radius, 0),
				Vector2(0,  dot_radius), Vector2(-dot_radius, 0),
			])
			if dot_filled:
				draw_colored_polygon(pts, dot_color)
			if outline_color.a > 0.0:
				pts.append(pts[0])
				draw_polyline(pts, outline_color, outline_width, antialiased)

		DotStyle.SQUARE:
			var r := dot_radius * 0.8
			var pts := PackedVector2Array([
				Vector2(-r, -r), Vector2(r, -r),
				Vector2(r,  r),  Vector2(-r, r),
			])
			if dot_filled:
				draw_colored_polygon(pts, dot_color)
			if outline_color.a > 0.0:
				pts.append(pts[0])
				draw_polyline(pts, outline_color, outline_width, antialiased)

		DotStyle.CROSS:
			var r := dot_radius
			draw_line(Vector2(-r, 0), Vector2(r, 0), dot_color, outline_width, antialiased)
			draw_line(Vector2(0, -r), Vector2(0, r), dot_color, outline_width, antialiased)

func _draw_circle_outline(r: float, col: Color) -> void:
	const STEPS := 48
	var pts: PackedVector2Array
	for i in range(STEPS + 1):
		var a := TAU * float(i) / float(STEPS)
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, col, outline_width, antialiased)

func _draw_orientation() -> void:
	if not _target_node:
		return
	# Compute world‑space tangent from the path
	var local_tangent := _sample_tangent(progress)
	var world_tangent := _target_node.global_transform.basis_xform(local_tangent).normalized()
	# Bring it into our own local space for drawing
	var local_draw_tangent := global_transform.affine_inverse().basis_xform(world_tangent).normalized()
	var tip := local_draw_tangent * orientation_length
	draw_line(Vector2.ZERO, tip, orientation_color, orientation_width, antialiased)

	if orientation_style == OrientationStyle.ARROW:
		var perp := Vector2(-local_draw_tangent.y, local_draw_tangent.x)
		var aw   := orientation_length * 0.35
		var base := tip - local_draw_tangent * aw
		draw_colored_polygon(
			PackedVector2Array([tip, base + perp * aw * 0.5, base - perp * aw * 0.5]),
			orientation_color
		)
