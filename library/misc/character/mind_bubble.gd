@tool
class_name MindBubble
extends BaseShape2D

# ─────────────────────────────────────────
#  Enums
# ─────────────────────────────────────────
enum BubbleShape {
	OVAL,
	ROUNDED_RECT,
	CLOUD,
}

enum AnchorDirection {
	BOTTOM_LEFT,   # bubble extends up and right from anchor
	BOTTOM_RIGHT,  # bubble extends up and left from anchor
	TOP_LEFT,      # bubble extends down and right from anchor
	TOP_RIGHT,     # bubble extends down and left from anchor
}


# ─────────────────────────────────────────
#  Size
# ─────────────────────────────────────────
@export_group("Size")

@export var bubble_size: Vector2 = Vector2(200.0, 120.0):
	set(value):
		bubble_size = value
		queue_redraw()


# ─────────────────────────────────────────
#  Shape
# ─────────────────────────────────────────
@export_group("Shape")

@export var bubble_shape: BubbleShape = BubbleShape.OVAL:
	set(value):
		bubble_shape = value
		queue_redraw()

## Corner radius – only used by ROUNDED_RECT shape.
@export_range(0.0, 80.0) var corner_radius: float = 24.0:
	set(value):
		corner_radius = value
		queue_redraw()

## Cloud bump count – only used by CLOUD shape.
@export_range(4, 20) var cloud_bumps: int = 10:
	set(value):
		cloud_bumps = value
		queue_redraw()

## Cloud bump radius relative to bubble size (0.0 – 0.5).
@export_range(0.1, 0.5) var cloud_bump_radius: float = 0.22:
	set(value):
		cloud_bump_radius = value
		queue_redraw()


# ─────────────────────────────────────────
#  Tail (thought bubble dots)
# ─────────────────────────────────────────
@export_group("Tail")

@export var show_tail: bool = true:
	set(value):
		show_tail = value
		queue_redraw()

## Which corner of the bubble is attached to the local origin (0,0).
@export var anchor_direction: AnchorDirection = AnchorDirection.BOTTOM_LEFT:
	set(value):
		anchor_direction = value
		queue_redraw()

## Number of thought‑bubble dots in the tail.
@export_range(1, 5) var tail_dot_count: int = 3:
	set(value):
		tail_dot_count = value
		queue_redraw()

## Radius of the largest tail dot (px).
@export_range(4.0, 32.0) var tail_dot_radius_max: float = 14.0:
	set(value):
		tail_dot_radius_max = value
		queue_redraw()

## How far the tail extends from the bubble edge toward the anchor (px).
@export_range(10.0, 120.0) var tail_length: float = 60.0:
	set(value):
		tail_length = value
		queue_redraw()


# ─────────────────────────────────────────
#  Style
# ─────────────────────────────────────────
@export_group("Style")

@export var bubble_color: Color = Color.WHITE:
	set(value):
		bubble_color = value
		queue_redraw()

@export var border_color: Color = Color(0.0, 0.0, 0.0, 1.0):
	set(value):
		border_color = value
		queue_redraw()

@export_range(0.0, 12.0) var border_width: float = 0.0:
	set(value):
		border_width = value
		queue_redraw()


# ─────────────────────────────────────────
#  Drawing
# ─────────────────────────────────────────
func _draw() -> void:
	var half: Vector2 = bubble_size * 0.5
	var center: Vector2 = _get_bubble_center_offset(half)

	# Offset the whole drawing so the bubble is drawn at 'center'.
	draw_set_transform(center, 0.0, Vector2.ONE)

	match bubble_shape:
		BubbleShape.OVAL:
			_draw_oval(half)
		BubbleShape.ROUNDED_RECT:
			_draw_rounded_rect(half)
		BubbleShape.CLOUD:
			_draw_cloud(half)

	# Reset transform so the tail is drawn relative to (0,0).
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if show_tail:
		_draw_tail(center, half)


# ── Shape helpers ────────────────────────
func _draw_oval(half: Vector2) -> void:
	draw_ellipse(Vector2.ZERO, half.x, half.y, bubble_color, true, -1.0, true)
	if border_width > 0.0:
		draw_ellipse(Vector2.ZERO, half.x, half.y, border_color, false, border_width, true)

func _draw_rounded_rect(half: Vector2) -> void:
	var rect := Rect2(-half, bubble_size)
	draw_rect(rect, bubble_color, true, -1.0, true)
	if border_width > 0.0:
		draw_rect(rect, border_color, false, border_width, true)

func _draw_cloud(half: Vector2) -> void:
	var bump_r: float = minf(half.x, half.y) * cloud_bump_radius
	var orbit_x: float = half.x - bump_r
	var orbit_y: float = half.y - bump_r

	var outline := PackedVector2Array()

	for i in cloud_bumps:
		var spoke: float = TAU * i / cloud_bumps
		var bump_center: Vector2 = Vector2(cos(spoke) * orbit_x, sin(spoke) * orbit_y)

		var half_step: float = PI / cloud_bumps
		var arc_start: float = spoke - PI * 0.5 - half_step
		var arc_end:   float = spoke + PI * 0.5 + half_step
		var arc_steps: int = 12

		for j in arc_steps + 1:
			var t: float = float(j) / float(arc_steps)
			var a: float = lerp(arc_start, arc_end, t)
			outline.append(bump_center + Vector2(cos(a), sin(a)) * bump_r)

	# Fill
	for i in outline.size() - 1:
		draw_colored_polygon(
			PackedVector2Array([Vector2.ZERO, outline[i], outline[i + 1]]),
			bubble_color
		)

	# Border
	if border_width > 0.0:
		var closed := outline.duplicate()
		closed.append(outline[0])
		draw_polyline(closed, border_color, border_width, true)


# ── Tail dots ────────────────────────────
func _draw_tail(bubble_center: Vector2, half: Vector2) -> void:
	# 1. Find the bubble edge point closest to the anchor (0,0).
	var anchor: Vector2 = Vector2.ZERO
	var corner: Vector2 = _get_anchor_corner_offset(half)   # relative to bubble centre

	# 2. Vector from edge point toward anchor.
	var direction: Vector2 = (anchor - corner).normalized()
	var edge_point: Vector2 = bubble_center + corner

	# 3. Draw dots from edge inward toward anchor.
	for i in tail_dot_count:
		var t: float = float(i + 1) / float(tail_dot_count + 1)
		var r: float = tail_dot_radius_max * (1.0 - t * 0.75)
		var pos: Vector2 = edge_point + direction * tail_length * t
		draw_circle(pos, r, bubble_color)
		if border_width > 0.0:
			draw_arc(pos, r, 0.0, TAU, 32, border_color, border_width)


# ─────────────────────────────────────────
#  Anchor helpers
# ─────────────────────────────────────────
## Returns the offset of the bubble’s centre from (0,0) for the chosen anchor corner.
func _get_bubble_center_offset(half: Vector2) -> Vector2:
	match anchor_direction:
		AnchorDirection.BOTTOM_LEFT:   return Vector2( half.x, -half.y)
		AnchorDirection.BOTTOM_RIGHT:  return Vector2(-half.x, -half.y)
		AnchorDirection.TOP_LEFT:      return Vector2( half.x,  half.y)
		AnchorDirection.TOP_RIGHT:     return Vector2(-half.x,  half.y)
	return Vector2.ZERO

## Returns the offset of the anchor corner relative to the bubble’s centre.
func _get_anchor_corner_offset(half: Vector2) -> Vector2:
	# Corner is opposite the anchor direction.
	match anchor_direction:
		AnchorDirection.BOTTOM_LEFT:   return Vector2(-half.x,  half.y)
		AnchorDirection.BOTTOM_RIGHT:  return Vector2( half.x,  half.y)
		AnchorDirection.TOP_LEFT:      return Vector2(-half.x, -half.y)
		AnchorDirection.TOP_RIGHT:     return Vector2( half.x, -half.y)
	return Vector2.ZERO
