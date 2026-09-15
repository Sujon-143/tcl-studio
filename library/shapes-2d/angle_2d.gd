@tool
extends BaseShape2D
class_name Angle2D

# ─── Internal ─────────────────────────────────────────────────────────────────
var _dash_offset: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# GEOMETRY
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Geometry")

## The corner/vertex of the angle in unit_size multiples
@export var vertex: Vector2 = Vector2.ZERO:
	set(v): vertex = v; queue_redraw()

## Starting angle of the first ray in degrees (0 = right)
@export_range(-360.0, 360.0, 0.1) var base_angle: float = 0.0:
	set(v): base_angle = v; queue_redraw()

## Angular span from the first ray to the second, in degrees
@export_range(-360.0, 360.0, 0.1) var span_angle: float = 60.0:
	set(v): span_angle = v; queue_redraw()

## Length of ray A (the base ray) in unit_size multiples
@export_range(0.1, 8.0, 0.01) var ray_a_length: float = 1.5:
	set(v): ray_a_length = v; queue_redraw()

## Length of ray B (the span ray) in unit_size multiples
@export_range(0.1, 8.0, 0.01) var ray_b_length: float = 1.5:
	set(v): ray_b_length = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# STROKE
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Stroke")

@export_range(0.01, 1.0, 0.005) var stroke_width: float = 0.04:
	set(v): stroke_width = v; queue_redraw()

@export var color: Color = Color.WHITE:
	set(v): color = v; queue_redraw()

@export var antialiased: bool = true:
	set(v): antialiased = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# ARC
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Arc")

@export_range(0.05, 2.0, 0.01) var arc_radius: float = 0.3:
	set(v): arc_radius = v; queue_redraw()

@export var arc_color: Color = Color.YELLOW:
	set(v): arc_color = v; queue_redraw()

@export_range(0.005, 0.5, 0.005) var arc_stroke_width: float = 0.03:
	set(v): arc_stroke_width = v; queue_redraw()

@export_range(8, 128, 1) var arc_resolution: int = 48:
	set(v): arc_resolution = v; queue_redraw()

## Draw a right-angle square marker when span is exactly 90°
@export var right_angle_marker: bool = true:
	set(v): right_angle_marker = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# LABEL
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Label")

@export var show_label: bool = true:
	set(v): show_label = v; queue_redraw()

## Leave empty to auto-display the measured angle in degrees
@export var label_text: String = "":
	set(v): label_text = v; queue_redraw()

@export_range(6, 64, 1) var label_font_size: int = 14:
	set(v): label_font_size = v; queue_redraw()

@export var label_color: Color = Color.WHITE:
	set(v): label_color = v; queue_redraw()

## Pushes the label further out from the vertex along the bisector
@export_range(1.1, 4.0, 0.05) var label_offset: float = 1.8:
	set(v): label_offset = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# ARROWHEADS
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Arrowheads")

enum ArrowheadStyle { NONE, FILLED, OPEN, CIRCLE, DIAMOND }

@export var head_a: ArrowheadStyle = ArrowheadStyle.NONE:
	set(v): head_a = v; queue_redraw()

@export var head_b: ArrowheadStyle = ArrowheadStyle.NONE:
	set(v): head_b = v; queue_redraw()

@export_range(0.05, 1.0, 0.01) var head_size: float = 0.16:
	set(v): head_size = v; queue_redraw()

@export_range(10.0, 80.0, 1.0) var head_angle: float = 25.0:
	set(v): head_angle = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# DASH
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Dash")

@export var dashed: bool = false:
	set(v): dashed = v; queue_redraw()

@export_range(0.02, 2.0, 0.01) var dash_length: float = 0.16:
	set(v): dash_length = v; queue_redraw()

@export_range(0.01, 2.0, 0.01) var gap_length: float = 0.08:
	set(v): gap_length = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# TREADMILL
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Treadmill")

@export var treadmill_enabled: bool = false:
	set(v): treadmill_enabled = v

@export_range(0.0, 6.0, 0.01) var treadmill_speed: float = 0.6:
	set(v): treadmill_speed = v

@export var treadmill_reverse: bool = false:
	set(v): treadmill_reverse = v

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if treadmill_enabled and dashed:
		var dir := -1.0 if treadmill_reverse else 1.0
		_dash_offset += treadmill_speed * delta * dir
		var period := (dash_length + gap_length) * unit_size
		_dash_offset = fmod(_dash_offset, period)
		if _dash_offset < 0.0:
			_dash_offset += period
		queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# DRAW
# ═══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	super._draw()
	var u   := unit_size
	var v   := vertex * u
	var a_rad := deg_to_rad(base_angle)
	var b_rad := deg_to_rad(base_angle + span_angle)
	var dir_a := Vector2(cos(a_rad), sin(a_rad))
	var dir_b := Vector2(cos(b_rad), sin(b_rad))
	var tip_a := v + dir_a * ray_a_length * u
	var tip_b := v + dir_b * ray_b_length * u

	# ── Rays ──
	var sw := stroke_width * u
	var trim := head_size * u * 0.6

	var draw_tip_a := tip_a if head_a == ArrowheadStyle.NONE else tip_a - dir_a * trim
	var draw_tip_b := tip_b if head_b == ArrowheadStyle.NONE else tip_b - dir_b * trim

	if dashed:
		_draw_dashed(PackedVector2Array([v, draw_tip_a]))
		_draw_dashed(PackedVector2Array([v, draw_tip_b]))
	else:
		draw_line(v, draw_tip_a, color, sw, antialiased)
		draw_line(v, draw_tip_b, color, sw, antialiased)

	# ── Arrowheads ──
	if head_a != ArrowheadStyle.NONE:
		_draw_head(tip_a, dir_a, head_a)
	if head_b != ArrowheadStyle.NONE:
		_draw_head(tip_b, dir_b, head_b)

	# ── Arc ──
	var abs_span :float= abs(span_angle)
	var is_right :bool= right_angle_marker and abs(abs_span - 90.0) < 0.5

	if is_right:
		_draw_right_angle_marker(v, dir_a, dir_b)
	else:
		_draw_arc(v, a_rad, b_rad)

	# ── Label ──
	if show_label:
		_draw_label(v, a_rad, b_rad, abs_span)

# ═══════════════════════════════════════════════════════════════════════════════
# ARC
# ═══════════════════════════════════════════════════════════════════════════════

func _draw_arc(v: Vector2, a_rad: float, b_rad: float) -> void:
	var delta := b_rad - a_rad
	while delta >  PI: delta -= TAU
	while delta < -PI: delta += TAU

	var r   := arc_radius * unit_size
	var pts := PackedVector2Array()
	for i in range(arc_resolution + 1):
		var t     := float(i) / float(arc_resolution)
		var angle: float = a_rad + delta * t
		pts.append(v + Vector2(cos(angle), sin(angle)) * r)
	draw_polyline(pts, arc_color, arc_stroke_width * unit_size, antialiased)

func _draw_right_angle_marker(v: Vector2, dir_a: Vector2, dir_b: Vector2) -> void:
	var sq := arc_radius * unit_size * 0.8
	var pa := v + dir_a * sq
	var pb := v + dir_b * sq
	var corner := pa + dir_b * sq
	draw_polyline(PackedVector2Array([pa, corner, pb]),
		arc_color, arc_stroke_width * unit_size, antialiased)

# ═══════════════════════════════════════════════════════════════════════════════
# LABEL
# ═══════════════════════════════════════════════════════════════════════════════

func _draw_label(v: Vector2, a_rad: float, b_rad: float, abs_span: float) -> void:
	var delta := b_rad - a_rad
	while delta >  PI: delta -= TAU
	while delta < -PI: delta += TAU

	var bisector_angle := a_rad + delta * 0.5
	var bisector       := Vector2(cos(bisector_angle), sin(bisector_angle))
	var label          := label_text if label_text.strip_edges() != "" \
						  else "%d°" % int(round(abs_span))
	var font           := ThemeDB.fallback_font
	var text_size      := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size)
	var pos            := v + bisector * arc_radius * unit_size * label_offset - text_size * 0.5
	draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_color)

# ═══════════════════════════════════════════════════════════════════════════════
# ARROWHEAD
# ═══════════════════════════════════════════════════════════════════════════════

func _draw_head(tip: Vector2, dir: Vector2, style: ArrowheadStyle) -> void:
	var u     := unit_size
	var angle := deg_to_rad(head_angle)
	var left  := tip - dir.rotated(-angle) * head_size * u
	var right := tip - dir.rotated( angle) * head_size * u
	var sw    := stroke_width * u

	match style:
		ArrowheadStyle.FILLED:
			draw_colored_polygon(PackedVector2Array([tip, left, right]), color)
		ArrowheadStyle.OPEN:
			draw_line(tip, left,  color, sw, antialiased)
			draw_line(tip, right, color, sw, antialiased)
		ArrowheadStyle.CIRCLE:
			var r      := head_size * u * 0.5
			var center := tip - dir * r
			draw_circle(center, r, color)
		ArrowheadStyle.DIAMOND:
			var back := tip - dir * head_size * u * 2.0
			draw_colored_polygon(PackedVector2Array([tip, left, back, right]), color)

# ═══════════════════════════════════════════════════════════════════════════════
# DASHED DRAWING
# ═══════════════════════════════════════════════════════════════════════════════

func _draw_dashed(pts: PackedVector2Array) -> void:
	var u             := unit_size
	var period        := (dash_length + gap_length) * u
	var dist_in_cycle := fmod(_dash_offset, period)
	if dist_in_cycle < 0.0:
		dist_in_cycle += period
	var in_dash    := dist_in_cycle < dash_length * u
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
			var remaining := (dash_length * u - dist_in_cycle) if in_dash else (period - dist_in_cycle)
			var step      := minf(remaining, seg_len - walked)
			var pos       := seg_start + dir * (walked + step)
			if in_dash:
				draw_line(dash_start, pos, color, stroke_width * u, antialiased)
			walked        += step
			dist_in_cycle += step
			if dist_in_cycle >= (dash_length * u if in_dash else period):
				dist_in_cycle = fmod(dist_in_cycle, period)
				in_dash       = !in_dash
				if in_dash:
					dist_in_cycle = 0.0
					dash_start    = pos
			elif in_dash:
				dash_start = pos
		seg_start = seg_end

	if in_dash:
		draw_line(dash_start, pts[-1], color, stroke_width * u, antialiased)
