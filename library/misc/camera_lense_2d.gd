@tool
extends BaseShape2D
class_name CameraLens2D

# ─────────────────────────────────────────────────────────────────────────────
#  CAMERA BODY DIMENSIONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Body Dimensions")

@export_range(30.0, 200.0) var body_width: float = 80.0:
	set(v): body_width = v; queue_redraw()

@export_range(30.0, 200.0) var body_height: float = 60.0:
	set(v): body_height = v; queue_redraw()

@export_range(0.0, 30.0) var body_corner_radius: float = 8.0:
	set(v): body_corner_radius = v; queue_redraw()

@export_range(8.0, 60.0) var lens_radius: float = 20.0:
	set(v): lens_radius = v; queue_redraw()

@export_range(1.0, 15.0) var ring_thickness: float = 4.0:
	set(v): ring_thickness = v; queue_redraw()

@export_range(-10.0, 20.0) var lens_offset: float = 4.0:
	set(v): lens_offset = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  LIGHT CONE (SIMPLE FILLED TRIANGLE)
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Light Cone")

@export var cone_enabled: bool = true:
	set(v): cone_enabled = v; queue_redraw()

## Rotation in degrees (0 = right, 90 = down, etc.)
@export_range(0.0, 360.0, 0.1) var cone_rotation_degrees: float = 0.0:
	set(v): cone_rotation_degrees = v; queue_redraw()

## Full opening angle (in degrees)
@export_range(5.0, 150.0, 0.5) var cone_angle: float = 40.0:
	set(v): cone_angle = v; queue_redraw()

## How far the cone extends from the lens
@export_range(20.0, 1500.0) var cone_length: float = 150.0:
	set(v): cone_length = v; queue_redraw()

## Color and base opacity of the cone
@export var cone_color: Color = Color(0.9, 0.95, 1.0, 0.4):
	set(v): cone_color = v; queue_redraw()

## Master opacity multiplier (0 = invisible, 1 = full cone_color.a)
@export_range(0.0, 1.0) var cone_opacity: float = 1.0:
	set(v): cone_opacity = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  COLORS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Colors")

@export var body_color: Color = Color(0.2, 0.2, 0.22):
	set(v): body_color = v; queue_redraw()

@export var body_accent: Color = Color(0.1, 0.1, 0.12):
	set(v): body_accent = v; queue_redraw()

@export var ring_color: Color = Color(0.7, 0.7, 0.75):
	set(v): ring_color = v; queue_redraw()

@export var ring_highlight: Color = Color(1.0, 1.0, 1.0, 0.8):
	set(v): ring_highlight = v; queue_redraw()

@export var glass_color: Color = Color(0.05, 0.08, 0.12, 0.9):
	set(v): glass_color = v; queue_redraw()

@export var glass_highlight: Color = Color(0.6, 0.7, 1.0, 0.5):
	set(v): glass_highlight = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  LED
# ─────────────────────────────────────────────────────────────────────────────
@export_category("LED")

@export var show_led: bool = true:
	set(v): show_led = v; queue_redraw()

@export var led_color_on: Color = Color(1.0, 0.2, 0.2):
	set(v): led_color_on = v; queue_redraw()

@export_range(1.0, 8.0) var led_radius: float = 3.0:
	set(v): led_radius = v; queue_redraw()

@export_range(0.0, 1.0) var power_on: float = 1.0:
	set(v): power_on = v; queue_redraw()

@export_range(0.0, 1.0) var recording_blink: float = 0.0:
	set(v): recording_blink = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS – ROUNDED RECT
# ─────────────────────────────────────────────────────────────────────────────

func _rounded_rect_points(rect: Rect2, r: float, segs: int = 8) -> PackedVector2Array:
	r = minf(r, minf(rect.size.x, rect.size.y) * 0.5)
	var pts: PackedVector2Array = PackedVector2Array()
	var cx: Array[float] = [rect.position.x + r, rect.end.x - r, rect.end.x - r, rect.position.x + r]
	var cy: Array[float] = [rect.position.y + r, rect.position.y + r, rect.end.y - r, rect.end.y - r]
	var start_angles: Array[float] = [-PI, -PI * 0.5, 0.0, PI * 0.5]
	for i: int in 4:
		for s: int in segs + 1:
			var a: float = start_angles[i] + (PI * 0.5) * (float(s) / float(segs))
			pts.append(Vector2(cx[i] + cos(a) * r, cy[i] + sin(a) * r))
	return pts

func _draw_rounded_rect(rect: Rect2, r: float, color: Color, segs: int = 8) -> void:
	draw_colored_polygon(_rounded_rect_points(rect, r, segs), color)

func _stroke_rounded_rect(rect: Rect2, r: float, color: Color, width: float, segs: int = 8) -> void:
	var pts: PackedVector2Array = _rounded_rect_points(rect, r, segs)
	if pts.size() > 0:
		pts.append(pts[0])
	draw_polyline(pts, color, width, true)

# ─────────────────────────────────────────────────────────────────────────────
#  DRAW
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var body_rect: Rect2 = Rect2(-body_width * 0.5, -body_height * 0.5, body_width, body_height)
	var lens_center: Vector2 = Vector2(body_width * 0.5 + lens_offset, 0.0)

	# ── 1. LIGHT CONE (SIMPLE FILLED TRIANGLE) ─────────────────────────────
	if cone_enabled and cone_length > 0.0 and cone_angle > 0.0 and cone_color.a * cone_opacity > 0.0:
		var rotation_rad: float = deg_to_rad(cone_rotation_degrees)
		var dir: Vector2 = Vector2.RIGHT.rotated(rotation_rad)
		var half_angle: float = deg_to_rad(cone_angle * 0.5)
		var perp: Vector2 = dir.rotated(PI * 0.5)  # perpendicular (90° CCW)

		var tip: Vector2 = lens_center
		var base_center: Vector2 = tip + dir * cone_length
		var half_base_width: float = tan(half_angle) * cone_length

		# Three vertices of the filled triangle
		var cone_pts: PackedVector2Array = PackedVector2Array()
		cone_pts.append(tip)
		cone_pts.append(base_center + perp * half_base_width)
		cone_pts.append(base_center - perp * half_base_width)

		var col: Color = cone_color
		col.a = cone_color.a * cone_opacity
		draw_colored_polygon(cone_pts, col)

		# Optional thin outline
		var edge_col: Color = col
		edge_col.a *= 0.6
		draw_line(tip, base_center + perp * half_base_width, edge_col, 1.0)
		draw_line(tip, base_center - perp * half_base_width, edge_col, 1.0)
		draw_line(base_center + perp * half_base_width, base_center - perp * half_base_width, edge_col, 1.0)

	# ── 2. BODY ─────────────────────────────────────────────────────────────
	_draw_rounded_rect(body_rect, body_corner_radius, body_color)
	_stroke_rounded_rect(body_rect, body_corner_radius, body_accent, 2.0)

	# ── 3. LENS BARREL (behind the ring) ────────────────────────────────────
	var barrel_rect: Rect2 = Rect2(
		lens_center.x - lens_radius * 0.5,
		lens_center.y - lens_radius - ring_thickness,
		lens_radius * 0.8,
		(lens_radius + ring_thickness) * 2.0
	)
	draw_rect(barrel_rect, body_accent.darkened(0.2))

	# ── 4. FOCUS RING ──────────────────────────────────────────────────────
	var ring_center: Vector2 = lens_center
	var ring_inner: float = lens_radius + ring_thickness * 0.2
	var ring_outer: float = lens_radius + ring_thickness

	draw_circle(ring_center, ring_outer, ring_color)
	draw_circle(ring_center, ring_inner, glass_color)  # cut out inner

	# Ring knurling
	var knurls: int = 16
	for k: int in knurls:
		var angle: float = TAU * float(k) / float(knurls)
		var base: Vector2 = ring_center + Vector2.RIGHT.rotated(angle) * (ring_outer - 1.0)
		var tip: Vector2 = ring_center + Vector2.RIGHT.rotated(angle) * (ring_outer + 1.0)
		draw_line(base, tip, ring_highlight if k % 2 == 0 else ring_color.darkened(0.2), 1.5)

	# Ring highlight arc
	var hl_pts: PackedVector2Array = PackedVector2Array()
	hl_pts.append(ring_center)
	for s: int in 8:
		var a: float = lerp(-PI * 0.6, -PI * 0.4, float(s) / 7.0)
		hl_pts.append(ring_center + Vector2.RIGHT.rotated(a) * ring_outer)
	draw_colored_polygon(hl_pts, ring_highlight.lightened(0.1))

	# ── 5. LENS GLASS ──────────────────────────────────────────────────────
	draw_circle(lens_center, lens_radius, glass_color)
	draw_circle(lens_center - Vector2(lens_radius * 0.3, lens_radius * 0.35), lens_radius * 0.4, glass_highlight)
	draw_circle(lens_center - Vector2(lens_radius * 0.55, lens_radius * 0.55), lens_radius * 0.2, glass_highlight.lightened(0.2))
	draw_arc(lens_center, lens_radius - 0.5, 0.0, TAU, 40, Color(0.0, 0.0, 0.0, 0.5), 1.0)

	# ── 6. LED ─────────────────────────────────────────────────────────────
	if show_led:
		var led_pos: Vector2 = Vector2(body_rect.position.x + 10.0, body_rect.position.y + 10.0)
		var led_on: bool = power_on > 0.5 and recording_blink < 0.5
		var led_col: Color = led_color_on if led_on else body_accent
		draw_circle(led_pos, led_radius + 1.0, Color(0.0, 0.0, 0.0, 0.6))
		draw_circle(led_pos, led_radius, led_col)
		if led_col.a > 0.1:
			var glow: Color = led_col
			glow.a *= 0.25
			draw_circle(led_pos, led_radius * 2.2, glow)

	# ── 7. OUTLINE ─────────────────────────────────────────────────────────
	_stroke_rounded_rect(body_rect, body_corner_radius, Color(0.0, 0.0, 0.0, 0.4), 1.0)
