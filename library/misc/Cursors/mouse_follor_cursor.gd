# MouseFollowCursor.gd
# ============================================================
# A presentation/annotation cursor for animated simulation videos.
#
# KEY BINDINGS (all configurable via @export):
#   C          – Toggle cursor visibility (animated)
#   R + drag   – Draw a rectangle annotation (release to confirm)
#   O + drag   – Draw a circle/ellipse annotation (release to confirm)
#   Shift+Z    – Undo last annotation
#   Shift+X    – Clear all annotations
#   Shift+H    – Toggle annotation layer visibility
#   F          – Cycle fill mode: outline → filled → dashed
#   Shift+C    – Cycle annotation color through palette
# ============================================================

@warning_ignore("missing_tool")
extends BaseSprite
class_name MouseFollowCursor

# ─────────────────────────────────────────────────────────────
#  Inner class: the 2D overlay that owns all drawn annotations
# ─────────────────────────────────────────────────────────────
class DrawingOverlay extends Node2D:

	# ── Annotation data ──────────────────────────────────────
	enum ShapeType { RECT, CIRCLE }
	enum FillMode  { OUTLINE, FILLED, DASHED }

	class Annotation:
		var shape_type : int          # ShapeType
		var rect       : Rect2        # used for both rect and circle bounding-box
		var color      : Color
		var line_width : float
		var fill_mode  : int          # FillMode
		var fill_alpha : float        # interior fill alpha (0–1)
		var corner_radius : float     # rect only
		var dash_len   : float
		var gap_len    : float

	# ── Runtime state ────────────────────────────────────────
	var annotations    : Array[Annotation] = []
	var preview        : Annotation        = null   # shape being dragged right now
	var drag_start     : Vector2           = Vector2.ZERO
	var is_dragging    : bool              = false

	# ── References to parent config (set by parent) ──────────
	var cfg : MouseFollowCursor = null

	func _ready() -> void:
		z_index = 99   # just below cursor sprite

	func _draw() -> void:
		for ann in annotations:
			_draw_annotation(ann)
		if preview != null:
			_draw_annotation(preview)

	# ── Draw a single Annotation ─────────────────────────────
	func _draw_annotation(ann: Annotation) -> void:
		match ann.shape_type:
			ShapeType.RECT:
				_draw_rect_annotation(ann)
			ShapeType.CIRCLE:
				_draw_circle_annotation(ann)

	func _draw_rect_annotation(ann: Annotation) -> void:
		var r := ann.rect.abs()
		if r.size.x < 2.0 or r.size.y < 2.0:
			return
		match ann.fill_mode:
			FillMode.FILLED:
				var fill_col := Color(ann.color.r, ann.color.g, ann.color.b, ann.fill_alpha)
				draw_rect(r, fill_col, true)
				draw_rect(r, ann.color, false, ann.line_width)
			FillMode.DASHED:
				var fill_col := Color(ann.color.r, ann.color.g, ann.color.b, ann.fill_alpha)
				draw_rect(r, fill_col, true)
				_draw_dashed_rect(r, ann)
			_: # OUTLINE
				draw_rect(r, ann.color, false, ann.line_width)

	func _draw_circle_annotation(ann: Annotation) -> void:
		var r := ann.rect.abs()
		if r.size.x < 2.0 or r.size.y < 2.0:
			return
		var center := r.get_center()
		var rx     := r.size.x * 0.5
		var ry     := r.size.y * 0.5
		match ann.fill_mode:
			FillMode.FILLED:
				var fill_col := Color(ann.color.r, ann.color.g, ann.color.b, ann.fill_alpha)
				_draw_ellipse(center, rx, ry, fill_col, true, ann.line_width)
				_draw_ellipse(center, rx, ry, ann.color, false, ann.line_width)
			FillMode.DASHED:
				var fill_col := Color(ann.color.r, ann.color.g, ann.color.b, ann.fill_alpha)
				_draw_ellipse(center, rx, ry, fill_col, true, ann.line_width)
				_draw_dashed_ellipse(center, rx, ry, ann)
			_: # OUTLINE
				_draw_ellipse(center, rx, ry, ann.color, false, ann.line_width)

	# ── Helpers ──────────────────────────────────────────────

	func _draw_ellipse(center: Vector2, rx: float, ry: float,
					   color: Color, filled: bool, width: float) -> void:
		var segments :int= max(32, int((rx + ry) * 0.5))
		var points   := PackedVector2Array()
		for i in range(segments + 1):
			var angle := TAU * i / float(segments)
			points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
		if filled:
			draw_polygon(points, PackedColorArray([color]))
		else:
			draw_polyline(points, color, width, true)

	func _draw_dashed_rect(r: Rect2, ann: Annotation) -> void:
		var corners := [
			r.position,
			Vector2(r.end.x, r.position.y),
			r.end,
			Vector2(r.position.x, r.end.y),
			r.position                          # close
		]
		for i in range(4):
			_draw_dashed_line(corners[i], corners[i+1], ann)

	func _draw_dashed_ellipse(center: Vector2, rx: float, ry: float,
							   ann: Annotation) -> void:
		var segments  :int= max(64, int((rx + ry) * 0.5))
		var perim_est := TAU * sqrt((rx * rx + ry * ry) * 0.5)
		var dash_frac := ann.dash_len / perim_est
		var gap_frac  := ann.gap_len  / perim_est

		var t    := 0.0
		var draw := true

		while t < 1.0:
			var step_frac := dash_frac if draw else gap_frac
			var next_t    :float= min(t + step_frac, 1.0)

			if draw:
				var pts := PackedVector2Array()
				var steps :int= max(2, int(step_frac * segments))
				for s in range(steps + 1):
					var tt    := t + step_frac * s / float(steps)
					var angle := TAU * tt
					pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
				draw_polyline(pts, ann.color, ann.line_width, true)

			t    = next_t
			draw = not draw

	func _draw_dashed_line(a: Vector2, b: Vector2, ann: Annotation) -> void:
		var total  := a.distance_to(b)
		if total < 0.001:
			return
		var dir    :Vector2= (b - a) / total
		var pos    :float= 0.0
		var draw   :bool= true
		while pos < total:
			var seg_len := ann.dash_len if draw else ann.gap_len
			if draw:
				var p0 :Vector2= a + dir * pos
				var p1 :Vector2= a + dir * min(pos + seg_len, total)
				draw_line(p0, p1, ann.color, ann.line_width, true)
			pos  += seg_len
			draw  = not draw

	# ── Input ────────────────────────────────────────────────
	func _input(event: InputEvent) -> void:
		if cfg == null:
			return

		var drawing_rect    := cfg.key_draw_rect    != KEY_NONE and Input.is_key_pressed(cfg.key_draw_rect)
		var drawing_circle  := cfg.key_draw_circle  != KEY_NONE and Input.is_key_pressed(cfg.key_draw_circle)
		var wants_draw      := drawing_rect or drawing_circle

		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed and wants_draw:
					drag_start  = mb.global_position
					is_dragging = true
					preview     = _make_annotation(
						ShapeType.RECT if drawing_rect else ShapeType.CIRCLE,
						Rect2(drag_start, Vector2.ZERO)
					)
					get_viewport().set_input_as_handled()
				elif not mb.pressed and is_dragging:
					is_dragging = false
					if preview != null and preview.rect.abs().get_area() > 4.0:
						annotations.append(preview)
					preview = null
					queue_redraw()
					get_viewport().set_input_as_handled()

		elif event is InputEventMouseMotion:
			if is_dragging and preview != null:
				var mm := event as InputEventMouseMotion
				preview.rect = Rect2(drag_start, mm.global_position - drag_start)
				queue_redraw()

	func _make_annotation(shape: int, r: Rect2) -> Annotation:
		var ann          := Annotation.new()
		ann.shape_type   = shape
		ann.rect         = r
		ann.color        = cfg.current_color()
		ann.line_width   = cfg.annotation_line_width
		ann.fill_mode    = cfg.current_fill_mode
		ann.fill_alpha   = cfg.fill_alpha
		ann.corner_radius = cfg.rect_corner_radius
		ann.dash_len     = cfg.dash_length
		ann.gap_len      = cfg.dash_gap
		return ann

	func undo_last() -> void:
		if annotations.size() > 0:
			annotations.pop_back()
			queue_redraw()

	func clear_all() -> void:
		annotations.clear()
		preview     = null
		is_dragging = false
		queue_redraw()


# ═════════════════════════════════════════════════════════════
#  MouseFollowCursor  –  main class
# ═════════════════════════════════════════════════════════════

# ── Appearance ───────────────────────────────────────────────
@export_group("Appearance")
@export_range(0.1, 5.0, 0.01) var appear_time   : float = 0.5
@export_range(0.0, 1.0, 0.01) var cursor_alpha   : float = 1.0
@export                        var cursor_scale   : Vector2 = Vector2.ONE

# ── Annotation – Colors ──────────────────────────────────────
@export_group("Annotation / Colors")
## Color palette cycled with Shift+C
@export var color_palette : Array[Color] = [
	Color.WHITE,
	Color(1.0, 0.27, 0.27),    # red
	Color(0.27, 0.9,  0.45),   # green
	Color(0.27, 0.7,  1.0),    # blue
	Color(1.0, 0.85, 0.15),    # yellow
	Color(1.0, 0.55, 0.0),     # orange
]
var _color_index : int = 0
func current_color() -> Color:
	if color_palette.is_empty():
		return Color.WHITE
	return color_palette[_color_index % color_palette.size()]

# ── Annotation – Shapes ──────────────────────────────────────
@export_group("Annotation / Shapes")
@export_range(1.0, 20.0, 0.5) var annotation_line_width : float = 2.5
@export_range(0.0, 40.0, 1.0) var rect_corner_radius    : float = 4.0
## Draw a translucent fill inside the shape so underlying content stays visible
@export var shape_filled : bool = false
## Use a dashed stroke instead of a solid one
@export var shape_dashed : bool = false
## Alpha of the interior fill (keep low so content underneath shows through)
@export_range(0.0, 1.0, 0.01) var fill_alpha : float = 0.15

# ── Annotation – Dash ────────────────────────────────────────
@export_group("Annotation / Dash")
@export_range(2.0, 60.0, 1.0) var dash_length : float = 12.0
@export_range(2.0, 40.0, 1.0) var dash_gap    : float = 6.0

# ── Key Bindings ─────────────────────────────────────────────
@export_group("Key Bindings")
## Toggle cursor visibility
@export var key_toggle_cursor    : Key = KEY_C
## Hold while dragging to draw a rectangle
@export var key_draw_rect        : Key = KEY_R
## Hold while dragging to draw a circle/ellipse
@export var key_draw_circle      : Key = KEY_O
## Undo last annotation  (requires Shift)
@export var key_undo             : Key = KEY_Z
## Clear all annotations (requires Shift)
@export var key_clear            : Key = KEY_X
## Toggle annotation layer visibility (requires Shift)
@export var key_toggle_overlay   : Key = KEY_H
## Cycle annotation color through palette (requires Shift)
@export var key_cycle_color      : Key = KEY_C

# ── Runtime state ────────────────────────────────────────────
var shown            : bool = false
var overlay_visible  : bool = true

## Derives fill mode from the two exported bools:
##   dashed=true  → DASHED  (dashed stroke + faint fill if shape_filled)
##   filled=true  → FILLED  (solid stroke + faint fill)
##   both false   → OUTLINE (solid stroke, no fill)
var current_fill_mode: int:
	get:
		if shape_dashed:
			return DrawingOverlay.FillMode.DASHED
		elif shape_filled:
			return DrawingOverlay.FillMode.FILLED
		return DrawingOverlay.FillMode.OUTLINE

var _overlay : DrawingOverlay


# ── Lifecycle ────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	z_index = 100
	scale   = cursor_scale

	_overlay      = DrawingOverlay.new()
	_overlay.cfg  = self
	# Add to the same parent so world coordinates align
	get_parent().add_child.call_deferred(_overlay)
	_overlay.z_index = 99

func _input(event: InputEvent) -> void:
	super._input(event)

	# ── Mouse follow ─────────────────────────────────────────
	if event is InputEventMouseMotion:
		global_position = (event as InputEventMouseMotion).global_position
		return  # don't fall through to key logic

	# ── Key handling ─────────────────────────────────────────
	if not (event is InputEventKey) or not (event as InputEventKey).is_pressed():
		return

	var ke      := event as InputEventKey
	var shifted := ke.shift_pressed

	match ke.keycode:
		key_toggle_cursor when not shifted:
			shown = not shown
			_toggle_vis()

		key_cycle_color when shifted:
			_color_index = (_color_index + 1) % max(1, color_palette.size())

		key_undo when shifted:
			_overlay.undo_last()

		key_clear when shifted:
			_overlay.clear_all()

		key_toggle_overlay when shifted:
			overlay_visible = not overlay_visible
			var twn := create_tween()
			twn.tween_property(_overlay, "modulate:a",
				1.0 if overlay_visible else 0.0, appear_time)
			twn.finished.connect(twn.kill)


# ── Cursor pop animation ─────────────────────────────────────
func _toggle_vis() -> void:
	var twn := create_tween()
	if shown:
		twn.tween_property(self, "popup_progress", 1.0, appear_time)
	else:
		twn.tween_property(self, "popup_progress", 0.0, appear_time)
	twn.finished.connect(twn.kill)


# ── Editor process: keep scale in sync ──────────────────────
func _process(_delta: float) -> void:
	if scale != cursor_scale:
		scale = cursor_scale
