@tool
extends BaseNode3D
class_name DimensionLine

## A dimension line between two points: a double-headed arrow floating above
## the measured segment, with optional extension lines and a label.
## Renders directly via ImmediateMesh — no Arrow3D dependency.
## Animation grows from 0 → 1: left arrow → right arrow → extension lines.

#region Configuration — Points and color

@export_group("Dimension")

@export var point_a: Vector3 = Vector3.ZERO :
	set(value):
		point_a = value
		if _ready_done:
			_update_geometry()
			draw()

@export var point_b: Vector3 = Vector3(1, 0, 0) :
	set(value):
		point_b = value
		if _ready_done:
			_update_geometry()
			draw()

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: draw()

## How far the arrow line floats perpendicular to the measured segment.
@export_range(0.0, 10.0, 0.001) var offset: float = 0.3 :
	set(value):
		offset = value
		if _ready_done:
			_update_geometry()
			draw()

#endregion

#region Configuration — Label

@export_group("Label")

## When true the label shows the measured distance automatically.
## When false, label_text is shown as-is (use for annotation / custom units).
@export var auto_label: bool = true :
	set(value):
		auto_label = value
		if _ready_done: draw()

## Custom label text. Only used when auto_label = false.
@export var label_text: String = "" :
	set(value):
		label_text = value
		if _ready_done: draw()

## Format string used when auto_label = true. Must contain one %s or %.Nf token.
@export var auto_label_format: String = "%.2f" :
	set(value):
		auto_label_format = value
		if _ready_done: draw()

@export_range(0.01, 5.0, 0.01) var label_scale: float = 0.5 :
	set(value):
		label_scale = value
		if _ready_done and is_instance_valid(_label):
			_label.scale = Vector3.ONE * label_scale

#endregion

#region Configuration — Arrow

@export_group("Arrow")

@export_range(0.001, 1.0, 0.001) var shaft_radius: float = 0.015 :
	set(value):
		shaft_radius = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var head_radius: float = 0.055 :
	set(value):
		head_radius = value
		if _ready_done: draw()

## Fraction of each arrow's length consumed by the arrowhead cone.
@export_range(0.01, 0.99, 0.01) var head_ratio: float = 0.12 :
	set(value):
		head_ratio = clamp(value, 0.01, 0.99)
		if _ready_done: draw()

#endregion

#region Configuration — Extension lines

@export_group("Extension Lines")

@export var show_extension_lines: bool = true :
	set(value):
		show_extension_lines = value
		if _ready_done:
			_update_geometry()
			draw()

@export_range(0.001, 1.0, 0.001) var extension_line_radius: float = 0.008 :
	set(value):
		extension_line_radius = value
		if _ready_done: draw()

#endregion

#region Configuration — Dash

@export_group("Dash")

@export var dashed: bool = false :
	set(value):
		dashed = value
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var dash_length: float = 0.15 :
	set(value):
		dash_length = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var gap_length: float = 0.07 :
	set(value):
		gap_length = max(0.001, value)
		if _ready_done: draw()

#endregion

#region Configuration — Draw progress

@export_group("Draw Progress")

@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0 :
	set(value):
		draw_progress = clamp(value, 0.0, 1.0)
		if _ready_done: draw()

#endregion

#region Private

var _mesh: ImmediateMesh
var _mat_front: StandardMaterial3D
var _mat_back: StandardMaterial3D
var _mesh_instance: MeshInstance3D
var _mesh_instance_back: MeshInstance3D
var _label: Label3D

# Guards setters from calling draw() before _ready() has run.
var _ready_done: bool = false

# Cached geometry — computed once in _update_geometry(), consumed in draw().
#
# Layout (all in world space):
#
#   point_a ──ext_left──► a_off ◄── left arrow tip
#                                    left arrow shaft ──► left_base
#                                                  [label gap]
#                                    right_base ◄── right arrow shaft
#                                    right arrow tip ──► b_off ──ext_right──► point_b
#
# "left" always refers to the point_a side, "right" to point_b.

var _a_off: Vector3       # point_a offset onto the dimension line
var _b_off: Vector3       # point_b offset onto the dimension line
var _mid: Vector3         # midpoint of the offset line (label anchor)
var _forward: Vector3     # unit vector from point_a → point_b
var _offset_dir: Vector3  # unit vector perpendicular to forward, in-plane

# Arrow shafts (tip = arrowhead tip, base = the gap-edge end)
var _left_tip: Vector3
var _left_base: Vector3
var _right_tip: Vector3
var _right_base: Vector3

# Extension lines (from original points up to the offset line)
var _ext_left_from: Vector3
var _ext_left_to: Vector3
var _ext_right_from: Vector3
var _ext_right_to: Vector3

# Arc-length budget for draw_progress animation:
#   [0, left_arrow_len]                   → left arrow
#   [left_arrow_len, left_arrow_len + right_arrow_len] → right arrow
#   [... , _total_len]                    → extension lines
var _left_arrow_len: float
var _right_arrow_len: float
var _ext_len: float       # length of one extension line (both are identical)
var _total_len: float

# Tube subdivision hint — ring count scales with segment length.
var _tube_segments: int = 6

#endregion

#region Static factories

static func get_default(a: Vector3, b: Vector3) -> DimensionLine:
	return DimensionLine.new(a, b)

static func get_with_label(a: Vector3, b: Vector3, label: String) -> DimensionLine:
	var d      := DimensionLine.new(a, b)
	d.auto_label = false
	d.label_text = label
	return d

static func get_auto_label(a: Vector3, b: Vector3, fmt: String = "%.2f") -> DimensionLine:
	var d               := DimensionLine.new(a, b)
	d.auto_label         = true
	d.auto_label_format  = fmt
	return d

#endregion

#region Lifecycle

func _init(p_a: Vector3 = Vector3.ZERO, p_b: Vector3 = Vector3(1, 0, 0)) -> void:
	point_a = p_a
	point_b = p_b
	_mesh   = ImmediateMesh.new()

func _setup() -> void:
	_mesh = ImmediateMesh.new()

	_mat_front = StandardMaterial3D.new()
	_mat_front.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_front.vertex_color_use_as_albedo = true
	_mat_front.cull_mode                  = BaseMaterial3D.CULL_BACK

	_mat_back = StandardMaterial3D.new()
	_mat_back.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_back.vertex_color_use_as_albedo = true
	_mat_back.cull_mode                  = BaseMaterial3D.CULL_FRONT

	# Front-face instance
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat_front
	add_child(_mesh_instance)

	# Back-face instance — same mesh, reversed cull, gives full double-sided
	# rendering without coplanar z-fighting from duplicated geometry.
	_mesh_instance_back = MeshInstance3D.new()
	_mesh_instance_back.mesh              = _mesh
	_mesh_instance_back.material_override = _mat_back
	add_child(_mesh_instance_back)

	_create_label()

	_ready_done = true
	_update_geometry()
	draw()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_setup()
		NOTIFICATION_EXIT_TREE:
			_teardown()

func _teardown() -> void:
	_ready_done = false
	
	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
		_mesh = null
	_mat_front = null

func _set(property: StringName, _value: Variant) -> bool:
	if property == &"mesh":
		return true  # block Godot restoring mesh = null on reload
	return false

func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray()

#endregion

#region Public API

func set_points(a: Vector3, b: Vector3) -> void:
	point_a = a
	point_b = b
	_update_geometry()
	draw()

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_offset(value: float) -> void:
	offset = value
	_update_geometry()
	draw()

## Show a fixed custom label (disables auto_label).
func set_label(text: String) -> void:
	auto_label = false
	label_text = text
	draw()

## Switch back to showing the measured distance.
func set_auto_label(value: bool) -> void:
	auto_label = value
	draw()

func set_dashed(value: bool) -> void:
	dashed = value
	draw()

# ratio: 0 = all gap, 1 = all dash
func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

## Required for compatibility with ProcAnim.create_object.
func draw() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	if draw_progress <= 0.0 or _total_len <= 0.0:
		_update_label_visibility()
		return

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(color)

	var d: float = _total_len * draw_progress
	if dashed:
		_draw_dashed_components(d)
	else:
		_draw_solid_components(d)

	_mesh.surface_end()
	_update_label_visibility()

#endregion

#region Geometry update

func _update_geometry() -> void:
	var dir: Vector3  = point_b - point_a
	var length: float = dir.length()
	if length < 0.001:
		_total_len = 0.0
		return

	_forward    = dir.normalized()
	var up      := Vector3.UP if abs(_forward.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	_offset_dir = _forward.cross(up).cross(_forward).normalized()

	_a_off = point_a + _offset_dir * offset
	_b_off = point_b + _offset_dir * offset
	_mid   = (_a_off + _b_off) * 0.5

	# Label gap: a silent zone around the midpoint so the label has breathing room.
	var label_gap: float = length * 0.18

	_left_tip  = _a_off
	_left_base = _mid - _forward * label_gap
	_right_tip = _b_off
	_right_base = _mid + _forward * label_gap

	_left_arrow_len  = _left_tip.distance_to(_left_base)
	_right_arrow_len = _right_tip.distance_to(_right_base)

	# Extension lines
	_ext_left_from  = point_a
	_ext_left_to    = _a_off
	_ext_right_from = point_b
	_ext_right_to   = _b_off
	_ext_len = point_a.distance_to(_a_off)  # same for both sides by construction

	# Animation budget: left arrow → right arrow → ext lines (both counted once each)
	_total_len = _left_arrow_len + _right_arrow_len
	if show_extension_lines:
		_total_len += _ext_len * 2.0

#endregion

#region Draw — solid and dashed dispatch

func _draw_solid_components(d: float) -> void:
	# ── Left arrow ──────────────────────────────────────────────────────────
	if d <= _left_arrow_len:
		_draw_arrow_partial(_left_base, _left_tip, d / _left_arrow_len,
							shaft_radius, head_radius, head_ratio)
		return
	_draw_arrow(_left_base, _left_tip, shaft_radius, head_radius, head_ratio)

	# ── Right arrow ─────────────────────────────────────────────────────────
	var d2: float = d - _left_arrow_len
	if d2 <= _right_arrow_len:
		_draw_arrow_partial(_right_base, _right_tip, d2 / _right_arrow_len,
							shaft_radius, head_radius, head_ratio)
		return
	_draw_arrow(_right_base, _right_tip, shaft_radius, head_radius, head_ratio)

	if not show_extension_lines:
		return

	# ── Extension lines ──────────────────────────────────────────────────────
	var d3: float = d - _left_arrow_len - _right_arrow_len
	# Both extension lines animate in parallel (each gets half the remaining budget)
	var ext_budget: float = _ext_len * 2.0
	var t_ext: float      = clamp(d3 / ext_budget, 0.0, 1.0)

	var ext_color := Color(color.r, color.g, color.b, color.a * 0.5)
	_mesh.surface_set_color(ext_color)

	if d3 <= _ext_len:
		_draw_tube(_ext_left_from, _ext_left_from.lerp(_ext_left_to, t_ext * 2.0),
				   extension_line_radius)
	elif d3 <= _ext_len * 2.0:
		_draw_tube(_ext_left_from,  _ext_left_to,  extension_line_radius)
		_draw_tube(_ext_right_from, _ext_right_from.lerp(_ext_right_to, (d3 - _ext_len) / _ext_len),
				   extension_line_radius)
	else:
		_draw_tube(_ext_left_from,  _ext_left_to,  extension_line_radius)
		_draw_tube(_ext_right_from, _ext_right_to, extension_line_radius)

	_mesh.surface_set_color(color)

func _draw_dashed_components(d: float) -> void:
	# ── Left arrow ──────────────────────────────────────────────────────────
	if d <= _left_arrow_len:
		_draw_arrow_dashed_partial(_left_base, _left_tip, d / _left_arrow_len,
								   shaft_radius, head_radius, head_ratio)
		return
	_draw_arrow_dashed(_left_base, _left_tip, shaft_radius, head_radius, head_ratio)

	# ── Right arrow ─────────────────────────────────────────────────────────
	var d2: float = d - _left_arrow_len
	if d2 <= _right_arrow_len:
		_draw_arrow_dashed_partial(_right_base, _right_tip, d2 / _right_arrow_len,
								   shaft_radius, head_radius, head_ratio)
		return
	_draw_arrow_dashed(_right_base, _right_tip, shaft_radius, head_radius, head_ratio)

	if not show_extension_lines:
		return

	# ── Extension lines ──────────────────────────────────────────────────────
	var d3: float  = d - _left_arrow_len - _right_arrow_len
	var ext_color := Color(color.r, color.g, color.b, color.a * 0.5)
	_mesh.surface_set_color(ext_color)

	if d3 <= _ext_len:
		_draw_dashed_tube(_ext_left_from, _ext_left_to, d3 / _ext_len,
						  extension_line_radius)
	elif d3 <= _ext_len * 2.0:
		_draw_dashed_tube(_ext_left_from, _ext_left_to, 1.0, extension_line_radius)
		_draw_dashed_tube(_ext_right_from, _ext_right_to, (d3 - _ext_len) / _ext_len,
						  extension_line_radius)
	else:
		_draw_dashed_tube(_ext_left_from, _ext_left_to,  1.0, extension_line_radius)
		_draw_dashed_tube(_ext_right_from, _ext_right_to, 1.0, extension_line_radius)

	_mesh.surface_set_color(color)

#endregion

#region Arrow helpers

## Draws a complete arrow from base → tip (shaft + cone).
func _draw_arrow(base: Vector3, tip: Vector3,
				 s_radius: float, h_radius: float, h_ratio: float) -> void:
	var total: float     = base.distance_to(tip)
	if total < 0.001:
		return
	var head_len: float  = total * h_ratio
	var shaft_end: Vector3 = tip.lerp(base, h_ratio)
	_draw_tube(base, shaft_end, s_radius)
	_draw_cone(shaft_end, tip, h_radius)

## Draws a partial arrow animated by t ∈ [0, 1].
## Growth direction: base → shaft → cone tip.
func _draw_arrow_partial(base: Vector3, tip: Vector3, t: float,
						 s_radius: float, h_radius: float, h_ratio: float) -> void:
	if t <= 0.0:
		return
	var total: float       = base.distance_to(tip)
	if total < 0.001:
		return
	var head_len: float    = total * h_ratio
	var shaft_len: float   = total - head_len
	var shaft_end: Vector3 = tip.lerp(base, h_ratio)
	var d: float           = total * t

	if d <= shaft_len:
		_draw_tube(base, base.lerp(shaft_end, d / shaft_len), s_radius)
	else:
		_draw_tube(base, shaft_end, s_radius)
		var cone_t: float = (d - shaft_len) / head_len
		_draw_cone_partial(shaft_end, tip, h_radius, cone_t)

## Draws a complete dashed arrow (dashed shaft, solid cone).
func _draw_arrow_dashed(base: Vector3, tip: Vector3,
						s_radius: float, h_radius: float, h_ratio: float) -> void:
	var total: float       = base.distance_to(tip)
	if total < 0.001:
		return
	var shaft_end: Vector3 = tip.lerp(base, h_ratio)
	_draw_dashed_tube(base, shaft_end, 1.0, s_radius)
	_draw_cone(shaft_end, tip, h_radius)

## Draws a partial dashed arrow animated by t ∈ [0, 1].
func _draw_arrow_dashed_partial(base: Vector3, tip: Vector3, t: float,
								s_radius: float, h_radius: float, h_ratio: float) -> void:
	if t <= 0.0:
		return
	var total: float       = base.distance_to(tip)
	if total < 0.001:
		return
	var head_len: float    = total * h_ratio
	var shaft_len: float   = total - head_len
	var shaft_end: Vector3 = tip.lerp(base, h_ratio)
	var d: float           = total * t

	if d <= shaft_len:
		_draw_dashed_tube(base, shaft_end, d / shaft_len, s_radius)
	else:
		_draw_dashed_tube(base, shaft_end, 1.0, s_radius)
		_draw_cone_partial(shaft_end, tip, h_radius, (d - shaft_len) / head_len)

#endregion

#region Geometry helpers

func _draw_tube(from: Vector3, to: Vector3, radius: float) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	_connect_rings([
		_build_ring(from, dir.normalized(), radius),
		_build_ring(to,   dir.normalized(), radius),
	])

func _draw_dashed_tube(from: Vector3, to: Vector3, t: float, radius: float) -> void:
	if t <= 0.0:
		return
	var total_len: float = from.distance_to(to)
	if total_len < 0.0001:
		return
	var forward  := (to - from).normalized()
	var limit    :float= total_len * clamp(t, 0.0, 1.0)
	var pattern  := dash_length + gap_length
	var dist     := 0.0
	while dist < limit:
		var dash_end: float = min(dist + dash_length, limit)
		_draw_tube(from + forward * dist, from + forward * dash_end, radius)
		dist += pattern

## Draws a closed cone from base_center → tip.
func _draw_cone(base_center: Vector3, tip: Vector3, radius: float) -> void:
	var dir := tip - base_center
	if dir.length() < 0.0001:
		return
	var ring := _build_ring(base_center, dir.normalized(), radius)
	# Side faces
	for j in range(ring.size()):
		var nj := (j + 1) % ring.size()
		_tri(tip, ring[j], ring[nj])
	# Base cap
	var c := _ring_center(ring)
	for j in range(ring.size()):
		_tri(c, ring[(j + 1) % ring.size()], ring[j])

## Draws a partial cone grown from base → tip by t ∈ [0, 1].
func _draw_cone_partial(base_center: Vector3, tip: Vector3,
						radius: float, t: float) -> void:
	if t <= 0.0:
		return
	# Lerp the tip toward the base by (1 - t); scale radius accordingly.
	var partial_tip := base_center.lerp(tip, t)
	var partial_radius := radius * t
	_draw_cone(base_center, partial_tip, partial_radius)

func _build_ring(center: Vector3, forward: Vector3, radius: float) -> Array[Vector3]:
	var up    := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up        = right.cross(forward).normalized()
	var ring: Array[Vector3] = []
	for j in range(_tube_segments):
		var a      := TAU * j / _tube_segments
		var off    := (cos(a) * right + sin(a) * up) * radius
		ring.append(center + off)
	return ring

func _connect_rings(rings: Array, caps: bool = true) -> void:
	for s in range(rings.size() - 1):
		var r0: Array = rings[s]
		var r1: Array = rings[s + 1]
		for j in range(r0.size()):
			var nj := (j + 1) % r0.size()
			_quad(r0[j], r0[nj], r1[nj], r1[j])

	if not caps:
		return

	var first: Array = rings[0]
	var c0 := _ring_center(first)
	for j in range(first.size()):
		_tri(c0, first[(j + 1) % first.size()], first[j])

	var last: Array = rings[-1]
	var c1 := _ring_center(last)
	for j in range(last.size()):
		_tri(c1, last[j], last[(j + 1) % last.size()])

func _ring_center(ring: Array) -> Vector3:
	var c := Vector3.ZERO
	for v in ring:
		c += v
	return c / ring.size()

func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(b)
	_mesh.surface_add_vertex(c)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(a, b, c)
	_tri(a, c, d)

#endregion

#region Label helpers

func _create_label() -> void:
	_label               = Label3D.new()
	_label.font_size     = 64
	_label.billboard     = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.scale         = Vector3.ONE * label_scale
	add_child(_label)

func _update_label_visibility() -> void:
	if not is_instance_valid(_label):
		return
	if draw_progress >= 0.999:
		_label.visible  = true
		_label.position = _mid
		_label.modulate = color
		_label.text     = _resolve_label(point_a.distance_to(point_b))
	else:
		_label.visible = false

## Returns the string that should appear on the label.
func _resolve_label(length: float) -> String:
	if auto_label:
		return auto_label_format % length
	return label_text

#endregion
