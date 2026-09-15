@tool
extends BaseShape2D
class_name OrbitShape2D

## Draws an elliptical orbit ring with correct depth cueing.
## Front (bottom) is fully opaque; back (top) fades to alpha_back.
## Extends BaseShape2D and keeps resolved_points in sync.

# ── Orbit geometry ────────────────────────────────────────────────────────────

@export var radius_x: float = 120.0:
	set(v): radius_x = v; _rebuild()

@export var radius_y: float = 40.0:
	set(v): radius_y = v; _rebuild()

@export_range(16, 256, 1) var segments: int = 90:
	set(v): segments = v; _rebuild()

# ── Stroke style ──────────────────────────────────────────────────────────────

@export var color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(v): color = v; queue_redraw()

@export var line_width: float = 2.0:
	set(v): line_width = v; queue_redraw()

@export var antialiased: bool = true:
	set(v): antialiased = v; queue_redraw()

# ── Depth cueing ──────────────────────────────────────────────────────────────

@export_range(0.0, 1.0) var alpha_front: float = 1.0:
	set(v): alpha_front = v; queue_redraw()

@export_range(0.0, 1.0) var alpha_back: float = 0.12:
	set(v): alpha_back = v; queue_redraw()

## 1.0 = linear fade.  >1 = front stays bright longer then fades sharply.
@export_range(0.25, 4.0, 0.05) var depth_curve: float = 1.8:
	set(v): depth_curve = v; queue_redraw()

## How many extra segments each arc extends past the left/right seam points.
## This overlap lets the two polylines blend instead of leaving a hard edge.
## 3–6 is usually plenty.
@export_range(1, 16, 1) var seam_overlap: int = 5:
	set(v): seam_overlap = v; queue_redraw()

# ── BaseShape2D contract ──────────────────────────────────────────────────────

## Full closed ellipse point list kept in sync with geometry changes.
## Other systems (collision, PathFollow2D, etc.) read this.

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_rebuild()

# ── Geometry helpers ──────────────────────────────────────────────────────────

func _rebuild() -> void:
	resolved_points.clear()
	if segments < 2:
		return
	var step: float = TAU / float(segments)
	# No closing duplicate — BaseShape2D callers treat it as an implicit closed loop.
	for i in range(segments):
		resolved_points.append(_ellipse_point(i * step))
	queue_redraw()

func _ellipse_point(angle: float) -> Vector2:
	return Vector2(cos(angle) * radius_x, sin(angle) * radius_y)

func _depth_at(angle: float) -> float:
	# sin(angle): −1 at top (back), +1 at bottom (front) — remap to [0, 1]
	var t: float = sin(angle) * 0.5 + 0.5
	return pow(t, depth_curve)

func _color_at(angle: float) -> Color:
	var a: float = lerpf(alpha_back, alpha_front, _depth_at(angle))
	return Color(color.r, color.g, color.b, color.a * a)

# ── Draw ──────────────────────────────────────────────────────────────────────

func _draw() -> void:
	if segments < 2:
		return

	var step: float    = TAU / float(segments)
	var overlap: float = seam_overlap * step  # extra angular reach past each seam

	# ── Back arc (top of ellipse, far side) ───────────────────────────────────
	# Core span PI → TAU (sin negative = y negative = upper half in canvas space).
	# Extend by `overlap` on both ends so it bleeds past the seam intersection.
	var back_pts:  PackedVector2Array
	var back_cols: PackedColorArray

	var b_start: float = PI  - overlap
	var b_end:   float = TAU + overlap
	var b_count: int   = int(ceil((b_end - b_start) / step)) + 1

	for i in range(b_count):
		var a: float = b_start + i * step
		back_pts.append(_ellipse_point(a))
		back_cols.append(_color_at(a))

	# ── Front arc (bottom of ellipse, near side) ──────────────────────────────
	# Core span 0 → PI (sin positive = y positive = lower half in canvas space).
	var front_pts:  PackedVector2Array
	var front_cols: PackedColorArray

	var f_start: float = 0.0 - overlap
	var f_end:   float = PI  + overlap
	var f_count: int   = int(ceil((f_end - f_start) / step)) + 1

	for i in range(f_count):
		var a: float = f_start + i * step
		front_pts.append(_ellipse_point(a))
		front_cols.append(_color_at(a))

	# Back drawn first so the front arc paints over it at the seam crossings.
	draw_polyline_colors(back_pts,  back_cols,  line_width, antialiased)
	draw_polyline_colors(front_pts, front_cols, line_width, antialiased)
