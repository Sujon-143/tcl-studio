@tool
extends BaseShape2D
class_name Triangle2D

# ─── Internal ─────────────────────────────────────────────────────────────────
var _dash_offset: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# VERTICES
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Vertices")

## When true, vertex B is the right-angle corner: A is directly above it,
## C is directly to its right — all distances driven by unit_size.
@export var is_right_angle: bool = false:
	set(v): is_right_angle = v; queue_redraw()

## Position of vertex A in unit_size multiples.
@export var point_a: Vector2 = Vector2(-0.8, -1.0):
	set(v): point_a = v; queue_redraw()

## Position of vertex B in unit_size multiples (right-angle corner when enabled).
@export var point_b: Vector2 = Vector2(-0.8, 0.8):
	set(v): point_b = v; queue_redraw()

## Position of vertex C in unit_size multiples.
@export var point_c: Vector2 = Vector2(1.2, 0.8):
	set(v): point_c = v; queue_redraw()

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

@export var filled: bool = false:
	set(v): filled = v; queue_redraw()

@export var fill_color: Color = Color(1, 1, 1, 0.15):
	set(v): fill_color = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# CORNER POINTS
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Corner Points")

@export var visible_corner_points: bool = false:
	set(v): visible_corner_points = v; queue_redraw()

@export_range(0.02, 0.4, 0.005) var corner_radius: float = 0.06:
	set(v): corner_radius = v; queue_redraw()

@export var corner_color: Color = Color.CYAN:
	set(v): corner_color = v; queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# ANGLES  — global defaults
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Angles")

## Master switch: show angle arcs and labels for all three vertices.
@export var show_angles: bool = false:
	set(v): show_angles = v; queue_redraw()

@export_range(0.05, 1.2, 0.01) var angle_arc_radius: float = 0.24:
	set(v): angle_arc_radius = v; queue_redraw()

@export var angle_arc_color: Color = Color.YELLOW:
	set(v): angle_arc_color = v; queue_redraw()

@export var angle_label_color: Color = Color.WHITE:
	set(v): angle_label_color = v; queue_redraw()

@export_range(6, 100, 1) var angle_font_size: int = 13:
	set(v): angle_font_size = v; queue_redraw()

## Distance multiplier from the arc midpoint to the label centre.
## 1.0 = label sits on the arc; >1.0 = pushed outward.
@export_range(1.0, 4.0, 0.05) var angle_label_offset: float = 1.7:
	set(v): angle_label_offset = v; queue_redraw()

# ── Per-vertex angle overrides ─────────────────────────────────────────────────
# Each sub-group lets you fine-tune one vertex without touching the others.
# "Use global" means the per-vertex value is ignored (the global setting applies).

@export_subgroup("Angle at A")

@export var angle_a_visible: bool = true:
	set(v): angle_a_visible = v; queue_redraw()

@export var angle_a_override_color: bool = false:
	set(v): angle_a_override_color = v; queue_redraw()

@export var angle_a_arc_color: Color = Color.YELLOW:
	set(v): angle_a_arc_color = v; queue_redraw()

@export var angle_a_override_label_color: bool = false:
	set(v): angle_a_override_label_color = v; queue_redraw()

@export var angle_a_label_color: Color = Color.WHITE:
	set(v): angle_a_label_color = v; queue_redraw()

## Extra offset applied ON TOP of the global angle_label_offset (in unit_size multiples).
## Positive = farther from the vertex; negative = closer.
@export_range(-1.0, 1.0, 0.01) var angle_a_label_nudge: float = 0.0:
	set(v): angle_a_label_nudge = v; queue_redraw()

## Manual label position override in unit_size multiples relative to the vertex.
## When non-zero, this overrides the computed bisector placement entirely.
@export var angle_a_label_offset_override: Vector2 = Vector2.ZERO:
	set(v): angle_a_label_offset_override = v; queue_redraw()

@export_subgroup("Angle at B")

@export var angle_b_visible: bool = true:
	set(v): angle_b_visible = v; queue_redraw()

@export var angle_b_override_color: bool = false:
	set(v): angle_b_override_color = v; queue_redraw()

@export var angle_b_arc_color: Color = Color.YELLOW:
	set(v): angle_b_arc_color = v; queue_redraw()

@export var angle_b_override_label_color: bool = false:
	set(v): angle_b_override_label_color = v; queue_redraw()

@export var angle_b_label_color: Color = Color.WHITE:
	set(v): angle_b_label_color = v; queue_redraw()

@export_range(-1.0, 1.0, 0.01) var angle_b_label_nudge: float = 0.0:
	set(v): angle_b_label_nudge = v; queue_redraw()

@export var angle_b_label_offset_override: Vector2 = Vector2.ZERO:
	set(v): angle_b_label_offset_override = v; queue_redraw()

@export_subgroup("Angle at C")

@export var angle_c_visible: bool = true:
	set(v): angle_c_visible = v; queue_redraw()

@export var angle_c_override_color: bool = false:
	set(v): angle_c_override_color = v; queue_redraw()

@export var angle_c_arc_color: Color = Color.YELLOW:
	set(v): angle_c_arc_color = v; queue_redraw()

@export var angle_c_override_label_color: bool = false:
	set(v): angle_c_override_label_color = v; queue_redraw()

@export var angle_c_label_color: Color = Color.WHITE:
	set(v): angle_c_label_color = v; queue_redraw()

@export_range(-1.0, 1.0, 0.01) var angle_c_label_nudge: float = 0.0:
	set(v): angle_c_label_nudge = v; queue_redraw()

@export var angle_c_label_offset_override: Vector2 = Vector2.ZERO:
	set(v): angle_c_label_offset_override = v; queue_redraw()

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

## Speed in unit_sizes per second.
@export_range(0.0, 6.0, 0.01) var treadmill_speed: float = 0.6:
	set(v): treadmill_speed = v

@export var treadmill_reverse: bool = false:
	set(v): treadmill_reverse = v

# ═══════════════════════════════════════════════════════════════════════════════
# CORNER LABELS  — global defaults
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Corner Labels")

## Comma-separated labels for A, B, C — e.g. "P,Q,R" or "α,β,γ".
## Leave a slot empty to skip it: ",B,C" labels only B and C.
@export var corner_labels: String = "":
	set(v): corner_labels = v; queue_redraw()

@export_range(6, 64, 1) var corner_label_font_size: int = 16:
	set(v): corner_label_font_size = v; queue_redraw()

@export var corner_label_color: Color = Color.WHITE:
	set(v): corner_label_color = v; queue_redraw()

## How far outside the vertex to push the label (in unit_size multiples).
@export_range(0.05, 1.0, 0.01) var corner_label_offset: float = 0.18:
	set(v): corner_label_offset = v; queue_redraw()

# ── Per-vertex label overrides ─────────────────────────────────────────────────

@export_subgroup("Label at A")

@export var label_a_visible: bool = true:
	set(v): label_a_visible = v; queue_redraw()

@export var label_a_override_font_size: bool = false:
	set(v): label_a_override_font_size = v; queue_redraw()

@export_range(6, 64, 1) var label_a_font_size: int = 16:
	set(v): label_a_font_size = v; queue_redraw()

@export var label_a_override_color: bool = false:
	set(v): label_a_override_color = v; queue_redraw()

@export var label_a_color: Color = Color.WHITE:
	set(v): label_a_color = v; queue_redraw()

## Manual position override relative to vertex A, in unit_size multiples.
## When non-zero, this replaces the auto-computed outward direction entirely.
@export var label_a_position_override: Vector2 = Vector2.ZERO:
	set(v): label_a_position_override = v; queue_redraw()

@export_subgroup("Label at B")

@export var label_b_visible: bool = true:
	set(v): label_b_visible = v; queue_redraw()

@export var label_b_override_font_size: bool = false:
	set(v): label_b_override_font_size = v; queue_redraw()

@export_range(6, 64, 1) var label_b_font_size: int = 16:
	set(v): label_b_font_size = v; queue_redraw()

@export var label_b_override_color: bool = false:
	set(v): label_b_override_color = v; queue_redraw()

@export var label_b_color: Color = Color.WHITE:
	set(v): label_b_color = v; queue_redraw()

@export var label_b_position_override: Vector2 = Vector2.ZERO:
	set(v): label_b_position_override = v; queue_redraw()

@export_subgroup("Label at C")

@export var label_c_visible: bool = true:
	set(v): label_c_visible = v; queue_redraw()

@export var label_c_override_font_size: bool = false:
	set(v): label_c_override_font_size = v; queue_redraw()

@export_range(6, 64, 1) var label_c_font_size: int = 16:
	set(v): label_c_font_size = v; queue_redraw()

@export var label_c_override_color: bool = false:
	set(v): label_c_override_color = v; queue_redraw()

@export var label_c_color: Color = Color.WHITE:
	set(v): label_c_color = v; queue_redraw()

@export var label_c_position_override: Vector2 = Vector2.ZERO:
	set(v): label_c_position_override = v; queue_redraw()


# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if treadmill_enabled and dashed:
		var dir: float    = -1.0 if treadmill_reverse else 1.0
		_dash_offset     += treadmill_speed * delta * dir
		var period: float  = (dash_length + gap_length) * unit_size
		_dash_offset       = fmod(_dash_offset, period)
		if _dash_offset < 0.0:
			_dash_offset += period
		queue_redraw()


# ═══════════════════════════════════════════════════════════════════════════════
# DRAW
# ═══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	super._draw()
	var a: Vector2 = _vertex_a()
	var b: Vector2 = _vertex_b()
	var c: Vector2 = _vertex_c()

	if filled:
		draw_colored_polygon(PackedVector2Array([a, b, c]), fill_color)

	var sw: float = stroke_width * unit_size
	if dashed:
		_draw_dashed(PackedVector2Array([a, b, c, a]))
	else:
		draw_line(a, b, color, sw, antialiased)
		draw_line(b, c, color, sw, antialiased)
		draw_line(c, a, color, sw, antialiased)

	if visible_corner_points:
		var cr: float = corner_radius * unit_size
		draw_circle(a, cr, corner_color)
		draw_circle(b, cr, corner_color)
		draw_circle(c, cr, corner_color)

	if show_angles:
		_draw_angles(a, b, c)

	if corner_labels.strip_edges() != "":
		_draw_corner_labels(a, b, c)


# ═══════════════════════════════════════════════════════════════════════════════
# VERTEX HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _vertex_a() -> Vector2:
	if is_right_angle:
		return Vector2(point_b.x, point_b.y + (point_a.y - point_b.y)) * unit_size
	return point_a * unit_size

func _vertex_b() -> Vector2:
	return point_b * unit_size

func _vertex_c() -> Vector2:
	if is_right_angle:
		return Vector2(point_b.x + (point_c.x - point_b.x), point_b.y) * unit_size
	return point_c * unit_size


# ═══════════════════════════════════════════════════════════════════════════════
# GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

## Returns the unit normal 90° CCW from the edge from_pt → to_pt.
func _edge_normal(from_pt: Vector2, to_pt: Vector2) -> Vector2:
	var edge: Vector2 = to_pt - from_pt
	if edge.length_squared() < 0.0001:
		return Vector2(0.0, -1.0)
	return Vector2(-edge.y, edge.x).normalized()

## Interior angle (degrees) at vertex v, with neighbours p and q.
func _angle_at(v: Vector2, p: Vector2, q: Vector2) -> float:
	var dp: Vector2 = p - v
	var dq: Vector2 = q - v
	if dp.length_squared() < 0.0001 or dq.length_squared() < 0.0001:
		return 0.0
	return rad_to_deg(acos(clampf(dp.normalized().dot(dq.normalized()), -1.0, 1.0)))

## Returns true when the triangle is non-degenerate (all edges ≥ 2 px,
## non-zero area, and no near-collinear configuration).
func _triangle_is_valid(a: Vector2, b: Vector2, c: Vector2) -> bool:
	const MIN_EDGE_SQ: float = 4.0
	if (b - a).length_squared() < MIN_EDGE_SQ: return false
	if (c - b).length_squared() < MIN_EDGE_SQ: return false
	if (a - c).length_squared() < MIN_EDGE_SQ: return false
	# Require at least 1 px² of area.
	return absf((b - a).cross(c - a)) > 2.0


# ═══════════════════════════════════════════════════════════════════════════════
# ANGLE DRAWING
# ═══════════════════════════════════════════════════════════════════════════════

## Bundles all per-vertex angle settings into one struct for clean passing.
## Index 0 = A, 1 = B, 2 = C.
func _angle_settings(idx: int) -> Dictionary:
	match idx:
		0:
			return {
				"visible":               angle_a_visible,
				"arc_color":             angle_a_arc_color if angle_a_override_color else angle_arc_color,
				"label_color":           angle_a_label_color if angle_a_override_label_color else angle_label_color,
				"nudge":                 angle_a_label_nudge,
				"label_offset_override": angle_a_label_offset_override,
			}
		1:
			return {
				"visible":               angle_b_visible,
				"arc_color":             angle_b_arc_color if angle_b_override_color else angle_arc_color,
				"label_color":           angle_b_label_color if angle_b_override_label_color else angle_label_color,
				"nudge":                 angle_b_label_nudge,
				"label_offset_override": angle_b_label_offset_override,
			}
		_:
			return {
				"visible":               angle_c_visible,
				"arc_color":             angle_c_arc_color if angle_c_override_color else angle_arc_color,
				"label_color":           angle_c_label_color if angle_c_override_label_color else angle_label_color,
				"nudge":                 angle_c_label_nudge,
				"label_offset_override": angle_c_label_offset_override,
			}


func _draw_angles(a: Vector2, b: Vector2, c: Vector2) -> void:
	var verts: Array[Vector2] = [a, b, c]
	var neighbours: Array     = [[1, 2], [0, 2], [0, 1]]

	for i: int in range(3):
		var s: Dictionary = _angle_settings(i)
		if not s["visible"]:
			continue

		var v: Vector2 = verts[i]
		var p: Vector2 = verts[neighbours[i][0]]
		var q: Vector2 = verts[neighbours[i][1]]

		var dp: Vector2 = p - v
		var dq: Vector2 = q - v

		# is_right_angle: B is always exactly 90° — bypass geometry entirely.
		if is_right_angle and i == 1:
			_draw_angle_full(v, p, q, 90.0, s)
			continue

		# Both neighbours coincide with v → genuine 0° at this vertex.
		if dp.length_squared() < 4.0 and dq.length_squared() < 4.0:
			var font: Font         = ThemeDB.fallback_font
			var label: String      = "0°"
			var text_size: Vector2 = font.get_string_size(
				label, HORIZONTAL_ALIGNMENT_LEFT, -1, angle_font_size)
			var ov: Vector2 = s["label_offset_override"]
			var label_pos: Vector2
			if ov.length_squared() > 0.00001:
				label_pos = v + ov * unit_size
			else:
				var dist: float = angle_arc_radius * unit_size * angle_label_offset \
								  + s["nudge"] * unit_size
				label_pos = v + Vector2.UP * dist
			draw_string(font, label_pos - text_size * 0.5, label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, angle_font_size, s["label_color"])
			continue

		# One neighbour coincides with another (but not with v) → angle at v
		# is indeterminate; skip silently.
		if dp.length_squared() < 4.0 or dq.length_squared() < 4.0:
			continue

		# Normal angle.
		var deg: float = rad_to_deg(
			acos(clampf(dp.normalized().dot(dq.normalized()), -1.0, 1.0)))
		_draw_angle_full(v, p, q, deg, s)
## Draw a single degenerate 0° angle label at the coincident point.
## vertex_idx is used to read that vertex's per-vertex settings.
## lone_pt is the surviving lone vertex — used to orient the label away from it.
func _draw_degenerate_angle(
		coincident_pt: Vector2,
		lone_pt: Vector2,
		vertex_idx: int,
		_unused: Vector2) -> void:

	var s: Dictionary = _angle_settings(vertex_idx)
	if not s["visible"]:
		return

	var font: Font         = ThemeDB.fallback_font
	var label: String      = "0°"
	var text_size: Vector2 = font.get_string_size(
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, angle_font_size)

	# Push the label perpendicular to the edge, on the side away from lone_pt.
	var n: Vector2 = _edge_normal(coincident_pt, lone_pt)
	# Pick the normal direction that points away from lone_pt.
	var to_lone: Vector2 = (lone_pt - coincident_pt).normalized()
	if n.dot(to_lone) > 0.0:
		n = -n

	var label_pos: Vector2 = coincident_pt + n * angle_arc_radius * unit_size * angle_label_offset
	draw_string(font, label_pos - text_size * 0.5, label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, angle_font_size, s["label_color"])

## Draw arc + label for one fully non-degenerate angle.
func _draw_angle_full(
		v: Vector2, p: Vector2, q: Vector2,
		deg: float, s: Dictionary) -> void:

	var raw_p: Vector2 = p - v
	var raw_q: Vector2 = q - v

	# Guard: if either direction is zero (degenerate vertex), fall back to
	# a safe perpendicular so the label still draws at the right position.
	var dir_p: Vector2 = raw_p.normalized() if raw_p.length_squared() >= 0.001 else Vector2.RIGHT
	var dir_q: Vector2 = raw_q.normalized() if raw_q.length_squared() >= 0.001 else dir_p.rotated(-PI * 0.5)

	var angle_p: float = atan2(dir_p.y, dir_p.x)
	var angle_q: float = atan2(dir_q.y, dir_q.x)

	var delta: float = angle_q - angle_p
	while delta >  PI: delta -= TAU
	while delta < -PI: delta += TAU

	var arc_r: float  = angle_arc_radius * unit_size
	var thin_w: float = stroke_width * unit_size * 0.6
	var font: Font    = ThemeDB.fallback_font

	var bisector: Vector2 = (dir_p + dir_q).normalized()
	if bisector.length_squared() < 0.001:
		bisector = dir_p.rotated(PI * 0.5)

	var is_right: bool = absf(deg - 90.0) < 0.5

	# ── Arc or right-angle square ──────────────────────────────────────────────
	if is_right:
		var sq: float      = arc_r * 0.6
		var arm_p: Vector2 = dir_p * sq
		var arm_q: Vector2 = dir_q * sq
		var sq_pts: PackedVector2Array = PackedVector2Array([
			v + arm_p,
			v + arm_p + arm_q,
			v + arm_q,
		])
		draw_polyline(sq_pts, s["arc_color"], thin_w, antialiased)
	else:
		var arc_pts: PackedVector2Array = PackedVector2Array()
		for i: int in range(33):
			var angle: float = angle_p + delta * (float(i) / 32.0)
			arc_pts.append(v + Vector2(cos(angle), sin(angle)) * arc_r)
		draw_polyline(arc_pts, s["arc_color"], thin_w, antialiased)

	# ── Label ──────────────────────────────────────────────────────────────────
	var label: String      = "%d°" % int(round(deg))
	var text_size: Vector2 = font.get_string_size(
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, angle_font_size)

	var label_pos: Vector2
	var ov: Vector2 = s["label_offset_override"]
	if ov.length_squared() > 0.00001:
		label_pos = v + ov * unit_size
	else:
		var total_dist: float = arc_r * angle_label_offset + s["nudge"] * unit_size
		label_pos = v + bisector * total_dist

	draw_string(font, label_pos - text_size * 0.5, label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, angle_font_size, s["label_color"])

# ═══════════════════════════════════════════════════════════════════════════════
# DASHED DRAWING
# ═══════════════════════════════════════════════════════════════════════════════

func _draw_dashed(pts: PackedVector2Array) -> void:
	var u: float             = unit_size
	var dl: float            = dash_length * u
	var gl: float            = gap_length * u
	var period: float        = dl + gl
	var dist_in_cycle: float = fmod(_dash_offset, period)
	if dist_in_cycle < 0.0:
		dist_in_cycle += period

	var in_dash: bool       = dist_in_cycle < dl
	var seg_start: Vector2  = pts[0]
	var dash_start: Vector2 = pts[0]

	for i: int in range(1, pts.size()):
		var seg_end: Vector2 = pts[i]
		var seg_len: float   = seg_start.distance_to(seg_end)
		if seg_len == 0.0:
			seg_start = seg_end
			continue
		var dir: Vector2  = (seg_end - seg_start) / seg_len
		var walked: float = 0.0

		while walked < seg_len:
			var remaining: float = (dl - dist_in_cycle) if in_dash else (period - dist_in_cycle)
			var step: float      = minf(remaining, seg_len - walked)
			var pos: Vector2     = seg_start + dir * (walked + step)

			if in_dash:
				draw_line(dash_start, pos, color, stroke_width * u, antialiased)

			walked        += step
			dist_in_cycle += step

			if dist_in_cycle >= (dl if in_dash else period):
				dist_in_cycle = fmod(dist_in_cycle, period)
				in_dash       = !in_dash
				if in_dash:
					dist_in_cycle = 0.0
					dash_start    = pos
			elif in_dash:
				dash_start = pos

		seg_start = seg_end

	if in_dash:
		draw_line(dash_start, pts[-1], color, stroke_width * unit_size, antialiased)


# ═══════════════════════════════════════════════════════════════════════════════
# CORNER LABEL DRAWING
# ═══════════════════════════════════════════════════════════════════════════════

## Bundles per-vertex label settings. Index 0 = A, 1 = B, 2 = C.
func _label_settings(idx: int) -> Dictionary:
	match idx:
		0:
			return {
				"visible":           label_a_visible,
				"font_size":         label_a_font_size if label_a_override_font_size else corner_label_font_size,
				"color":             label_a_color if label_a_override_color else corner_label_color,
				"pos_override":      label_a_position_override,
			}
		1:
			return {
				"visible":           label_b_visible,
				"font_size":         label_b_font_size if label_b_override_font_size else corner_label_font_size,
				"color":             label_b_color if label_b_override_color else corner_label_color,
				"pos_override":      label_b_position_override,
			}
		_:
			return {
				"visible":           label_c_visible,
				"font_size":         label_c_font_size if label_c_override_font_size else corner_label_font_size,
				"color":             label_c_color if label_c_override_color else corner_label_color,
				"pos_override":      label_c_position_override,
			}

func _draw_corner_labels(a: Vector2, b: Vector2, c: Vector2) -> void:
	var parts: PackedStringArray = corner_labels.split(",", false)
	# split() with false skips empties, but we need positional slots.
	# Re-split preserving empty slots:
	var slots: PackedStringArray = corner_labels.split(",")
	# Pad to exactly 3 elements.
	while slots.size() < 3:
		slots.append("")

	var font: Font    = ThemeDB.fallback_font
	var offset: float = corner_label_offset * unit_size
	var verts: Array[Vector2] = [a, b, c]

	# ── Compute outward nudge directions ───────────────────────────────────────
	#
	# BUG FIX (two bugs from previous version):
	#
	# Bug 1 — Coincident-pair loop didn't break.
	#   All three pairs were tested, so a later iteration could overwrite the
	#   corrections made by an earlier one. Fixed: break after the first match.
	#
	# Bug 2 — Lone vertex kept its degenerate COM-based direction.
	#   When two vertices coincide, the centroid (COM) is pulled almost to the
	#   shared point, making the COM → lone_vertex direction nearly identical to
	#   one of the two normals already assigned to the coincident pair — causing
	#   two labels to land in the same spot.
	#   Fixed: the lone vertex's direction is now computed directly as
	#   normalize(lone_vertex − shared_point), which is always well-defined and
	#   guaranteed to differ from both ±normal directions.

	const COINCIDE_SQ: float = 4.0
	var com: Vector2 = (a + b + c) / 3.0

	# Start with COM-based outward directions (good for normal triangles).
	var outwards: Array[Vector2] = []
	for i: int in range(3):
		var to_v: Vector2 = verts[i] - com
		outwards.append(to_v.normalized() if to_v.length_squared() > 0.01 else Vector2.ZERO)

	# Pairs: (i, j, k) — i and j may coincide; k is the lone vertex.
	var pairs: Array = [[0, 1, 2], [1, 2, 0], [0, 2, 1]]
	for triplet: Array in pairs:
		var i: int = triplet[0]
		var j: int = triplet[1]
		var k: int = triplet[2]
		if (verts[i] - verts[j]).length_squared() >= COINCIDE_SQ:
			continue

		# i and j are coincident. Normal to the edge shared_point → lone_vertex.
		var n: Vector2 = _edge_normal(verts[i], verts[k])
		outwards[i] = n
		outwards[j] = -n

		# Lone vertex k: push directly away from the shared position (FIX).
		var to_k: Vector2 = verts[k] - verts[i]
		outwards[k] = to_k.normalized() if to_k.length_squared() > 0.01 else -n
		break  # Only one coincident pair can exist; stop here (FIX).

	# Last-resort fallbacks when all three coincide.
	const FALLBACKS: Array[Vector2] = [
		Vector2(-0.707, -0.707),
		Vector2( 0.707, -0.707),
		Vector2( 0.0,    1.0),
	]
	for i: int in range(3):
		if outwards[i].length_squared() < 0.001:
			outwards[i] = FALLBACKS[i]

	# ── Draw each label ────────────────────────────────────────────────────────
	for i: int in range(mini(slots.size(), 3)):
		var raw_label: String = slots[i].strip_edges()
		if raw_label.is_empty():
			continue

		var s: Dictionary = _label_settings(i)
		if not s["visible"]:
			continue

		var fs: int    = s["font_size"]
		var col: Color = s["color"]

		var anchor: Vector2
		var ov: Vector2 = s["pos_override"]
		if ov.length_squared() > 0.00001:
			# Manual override: relative to vertex, in unit_size multiples.
			anchor = verts[i] + ov * unit_size
		else:
			anchor = verts[i] + outwards[i] * offset

		var text_size: Vector2 = font.get_string_size(
			raw_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, anchor - text_size * 0.5, raw_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
