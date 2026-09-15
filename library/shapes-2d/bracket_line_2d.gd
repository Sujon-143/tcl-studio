@tool
extends Node2D
class_name BracketLine2D

## A 2D bracket: a shaft with perpendicular caps at both ends.
## The caps are drawn as full segments (both sides of the shaft endpoints),
## and the shaft connects the centres of the caps.
## Animation grows from 0 → 1: left cap → shaft → right cap.

# ---------------------------------------------------------------------------
# Configuration — Points and colour
# ---------------------------------------------------------------------------

@export_group("Bracket")

@export var point_a: Vector2 = Vector2.ZERO:
	set(value):
		point_a = value
		if _ready_done:
			_update_geometry()
			queue_redraw()

@export var point_b: Vector2 = Vector2(100.0, 0.0):
	set(value):
		point_b = value
		if _ready_done:
			_update_geometry()
			queue_redraw()

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		if _ready_done:
			queue_redraw()

# ---------------------------------------------------------------------------
# Configuration — Shape
# ---------------------------------------------------------------------------

@export_group("Shape")

## Length of each perpendicular cap segment.
@export_range(1.0, 200.0, 0.5, "suffix:px") var bracket_size: float = 15.0:
	set(value):
		bracket_size = value
		if _ready_done:
			_update_geometry()
			queue_redraw()

## Stroke width of all lines.
@export_range(0.5, 32.0, 0.5, "suffix:px") var thickness: float = 2.0:
	set(value):
		thickness = value
		if _ready_done:
			queue_redraw()

## Perpendicular offset of the whole bracket from the point_a→point_b axis.
@export var offset: float = 0.0:
	set(value):
		offset = value
		if _ready_done:
			_update_geometry()
			queue_redraw()

## Draw lines with rounded end-caps (LINE_CAP_ROUND).
@export var rounded_caps: bool = true:
	set(value):
		rounded_caps = value
		if _ready_done:
			queue_redraw()

# ---------------------------------------------------------------------------
# Configuration — Label
# ---------------------------------------------------------------------------

@export_group("Label")

@export var show_label: bool = false:
	set(value):
		show_label = value
		if _ready_done:
			_rebuild_label()

@export var label_text: String = "":
	set(value):
		label_text = value
		if _ready_done:
			queue_redraw()

## When true the label automatically shows the shaft length (rounded to 1 dp).
@export var auto_label: bool = false:
	set(value):
		auto_label = value
		if _ready_done:
			queue_redraw()

@export_range(6, 128, 1, "suffix:pt") var label_font_size: int = 14:
	set(value):
		label_font_size = value
		if _ready_done and is_instance_valid(_label):
			_label.label_settings.font_size = label_font_size

## Extra perpendicular distance the label sits away from the shaft midpoint.
@export_range(0.0, 200.0, 1.0, "suffix:px") var label_offset: float = 12.0:
	set(value):
		label_offset = value
		if _ready_done:
			queue_redraw()

# ---------------------------------------------------------------------------
# Configuration — Dash
# ---------------------------------------------------------------------------

@export_group("Dash")

@export var dashed: bool = false:
	set(value):
		dashed = value
		if _ready_done:
			queue_redraw()

@export_range(0.001, 200.0, 0.5, "suffix:px") var dash_length: float = 12.0:
	set(value):
		dash_length = maxf(value, 0.001)
		if _ready_done:
			queue_redraw()

@export_range(0.001, 200.0, 0.5, "suffix:px") var gap_length: float = 6.0:
	set(value):
		gap_length = maxf(value, 0.001)
		if _ready_done:
			queue_redraw()

# ---------------------------------------------------------------------------
# Configuration — Draw progress
# ---------------------------------------------------------------------------

@export_group("Draw Progress")

## Animatable: 0 = nothing drawn, 1 = fully drawn.
## Order: left cap → shaft → right cap (mirrors the 3D version).
@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0:
	set(value):
		draw_progress = clampf(value, 0.0, 1.0)
		if _ready_done:
			queue_redraw()

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

var _ready_done: bool = false
var _label: Label = null

# Cached geometry (world-space 2D points)
var _left_cap_from:  Vector2
var _left_cap_to:    Vector2
var _shaft_from:     Vector2
var _shaft_to:       Vector2
var _right_cap_from: Vector2
var _right_cap_to:   Vector2

var _cap_len:   float = 0.0
var _shaft_len: float = 0.0
var _total_len: float = 0.0

# ---------------------------------------------------------------------------
# Static factories
# ---------------------------------------------------------------------------

static func get_default(a: Vector2, b: Vector2) -> BracketLine2D:
	var br := BracketLine2D.new()
	br.point_a = a
	br.point_b = b
	return br

static func get_with_label(a: Vector2, b: Vector2, text: String) -> BracketLine2D:
	var br := BracketLine2D.new()
	br.point_a     = a
	br.point_b     = b
	br.show_label  = true
	br.label_text  = text
	return br

static func get_auto_label(a: Vector2, b: Vector2) -> BracketLine2D:
	var br := BracketLine2D.new()
	br.point_a    = a
	br.point_b    = b
	br.show_label = true
	br.auto_label = true
	return br

static func get_dashed(a: Vector2, b: Vector2) -> BracketLine2D:
	var br := BracketLine2D.new()
	br.point_a = a
	br.point_b = b
	br.dashed  = true
	return br

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_setup()
		NOTIFICATION_EXIT_TREE:
			_teardown()

func _setup() -> void:
	if _ready_done:
		return
	if show_label:
		_create_label()
	_ready_done = true
	_update_geometry()
	queue_redraw()

func _teardown() -> void:
	_ready_done = false
	if is_instance_valid(_label):
		_label.queue_free()
		_label = null

func _get_configuration_warnings() -> PackedStringArray:
	var w := PackedStringArray()
	if point_a.distance_to(point_b) < 0.001:
		w.append("point_a and point_b are too close together — bracket will not be visible.")
	return w

# ---------------------------------------------------------------------------
# Public API  (mirrors the 3D version)
# ---------------------------------------------------------------------------

func set_points(a: Vector2, b: Vector2) -> void:
	point_a = a
	point_b = b
	_update_geometry()
	queue_redraw()

func set_color(new_color: Color) -> void:
	color = new_color
	queue_redraw()

func set_bracket_size(value: float) -> void:
	bracket_size = value
	_update_geometry()
	queue_redraw()

func set_thickness(value: float) -> void:
	thickness = value
	queue_redraw()

func set_offset(value: float) -> void:
	offset = value
	_update_geometry()
	queue_redraw()

func set_dashed(value: bool) -> void:
	dashed = value
	queue_redraw()

## ratio: 0 = all gap, 1 = all dash
func set_dash_ratio(ratio: float) -> void:
	ratio       = clampf(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	queue_redraw()

func set_label(text: String) -> void:
	label_text = text
	show_label = true
	auto_label = false
	if not is_instance_valid(_label):
		_create_label()
	queue_redraw()

func set_show_label(value: bool) -> void:
	show_label = value
	_rebuild_label()

# ---------------------------------------------------------------------------
# Geometry update
# ---------------------------------------------------------------------------

func _update_geometry() -> void:
	var dir: Vector2 = point_b - point_a
	var length: float = dir.length()
	if length < 0.001:
		_total_len = 0.0
		return

	var forward: Vector2 = dir.normalized()
	# In 2D, the perpendicular is simply the forward rotated 90° CCW.
	var perp: Vector2 = Vector2(-forward.y, forward.x)

	# Shift anchor points by offset along the perpendicular.
	var pa: Vector2 = point_a + perp * offset
	var pb: Vector2 = point_b + perp * offset

	var half: float  = bracket_size * 0.5
	_left_cap_from   = pa - perp * half
	_left_cap_to     = pa + perp * half
	_right_cap_from  = pb - perp * half
	_right_cap_to    = pb + perp * half
	_shaft_from      = pa
	_shaft_to        = pb

	_cap_len   = bracket_size
	_shaft_len = pa.distance_to(pb)
	_total_len = _cap_len + _shaft_len + _cap_len

# ---------------------------------------------------------------------------
# _draw
# ---------------------------------------------------------------------------

func _draw() -> void:
	if draw_progress <= 0.0 or _total_len <= 0.0:
		_update_label_visibility()
		return

	var d: float = _total_len * draw_progress

	if dashed:
		_draw_dashed_components(d)
	else:
		_draw_solid_components(d)

	_update_label_visibility()

# ---------------------------------------------------------------------------
# Solid drawing
# ---------------------------------------------------------------------------

func _draw_solid_components(d: float) -> void:
	if d <= _cap_len:
		# Partial left cap only
		var t: float   = d / _cap_len
		var partial_to := _left_cap_from.lerp(_left_cap_to, t)
		_draw_segment(_left_cap_from, partial_to)

	elif d <= _cap_len + _shaft_len:
		# Full left cap + partial shaft
		_draw_segment(_left_cap_from, _left_cap_to)
		var t: float = (d - _cap_len) / _shaft_len
		_draw_segment(_shaft_from, _shaft_from.lerp(_shaft_to, t))

	else:
		# Full left cap + full shaft + partial right cap
		_draw_segment(_left_cap_from, _left_cap_to)
		_draw_segment(_shaft_from, _shaft_to)
		var t: float = (d - _cap_len - _shaft_len) / _cap_len
		_draw_segment(_right_cap_from, _right_cap_from.lerp(_right_cap_to, t))

# ---------------------------------------------------------------------------
# Dashed drawing
# ---------------------------------------------------------------------------

func _draw_dashed_components(d: float) -> void:
	if d <= _cap_len:
		_draw_dashed_segment(_left_cap_from, _left_cap_to, d / _cap_len)

	elif d <= _cap_len + _shaft_len:
		_draw_dashed_segment(_left_cap_from, _left_cap_to, 1.0)
		_draw_dashed_segment(_shaft_from, _shaft_to, (d - _cap_len) / _shaft_len)

	else:
		_draw_dashed_segment(_left_cap_from, _left_cap_to, 1.0)
		_draw_dashed_segment(_shaft_from, _shaft_to, 1.0)
		_draw_dashed_segment(_right_cap_from, _right_cap_to, (d - _cap_len - _shaft_len) / _cap_len)

# ---------------------------------------------------------------------------
# Geometry helpers
# ---------------------------------------------------------------------------

func _draw_segment(from: Vector2, to: Vector2) -> void:
	if from.distance_to(to) < 0.0001:
		return
	draw_line(from, to, color, thickness, rounded_caps)

func _draw_dashed_segment(from: Vector2, to: Vector2, t: float) -> void:
	if t <= 0.0:
		return
	var total: float = from.distance_to(to)
	if total < 0.0001:
		return
	var forward  := (to - from).normalized()
	var limit    := total * clampf(t, 0.0, 1.0)
	var pattern  := dash_length + gap_length
	var dist     := 0.0
	while dist < limit:
		var dash_end: float = minf(dist + dash_length, limit)
		draw_line(
			from + forward * dist,
			from + forward * dash_end,
			color, thickness, rounded_caps
		)
		dist += pattern

# ---------------------------------------------------------------------------
# Label helpers
# ---------------------------------------------------------------------------

func _create_label() -> void:
	_label = Label.new()
	var ls              := LabelSettings.new()
	ls.font_size        = label_font_size
	ls.font_color       = color
	_label.label_settings = ls
	_label.z_index      = 1
	add_child(_label, false, Node.INTERNAL_MODE_BACK)

func _rebuild_label() -> void:
	if show_label:
		if not is_instance_valid(_label):
			_create_label()
	else:
		if is_instance_valid(_label):
			_label.queue_free()
			_label = null
	queue_redraw()

func _update_label_visibility() -> void:
	if not show_label or not is_instance_valid(_label):
		return

	if draw_progress >= 0.999:
		_label.visible = true

		# Recolour in case color changed.
		if _label.label_settings:
			_label.label_settings.font_color = color

		# Position: midpoint of the shaft, offset perpendicularly.
		var mid     := (_shaft_from + _shaft_to) * 0.5
		var forward := (_shaft_to - _shaft_from).normalized() if _shaft_len > 0.001 else Vector2.RIGHT
		var perp    := Vector2(-forward.y, forward.x)

		# Place the label node in local space (it is a child of this Node2D).
		_label.position = mid + perp * (bracket_size * 0.5 + label_offset)

		# Centre-align the Label widget itself.
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		_label.size                 = Vector2.ZERO   # auto-size

		_label.text = label_text if not auto_label else ("%.1f" % _shaft_len)
	else:
		_label.visible = false
