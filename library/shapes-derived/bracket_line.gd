@tool
extends BaseNode3D
class_name BracketLine

## A 3D bracket: a shaft with perpendicular caps at both ends.
## The caps are drawn as full segments (both sides of the shaft endpoints),
## and the shaft connects the centers of the caps.
## Animation grows from 0 → 1: left cap → shaft → right cap.

#region Configuration — Points and color

@export_group("Bracket")

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

#endregion

#region Configuration — Shape

@export_group("Shape")

@export_range(0.01, 2.0, 0.001) var bracket_size: float = 0.15 :
	set(value):
		bracket_size = value
		if _ready_done:
			_update_geometry()
			draw()

@export_range(0.001, 1.0, 0.001) var thickness: float = 0.02 :
	set(value):
		thickness = value
		if _ready_done: draw()

@export var offset: float = 0.0 :
	set(value):
		offset = value
		if _ready_done:
			_update_geometry()
			draw()

@export_range(3, 32, 1) var tube_segments: int = 6 :
	set(value):
		tube_segments = value
		if _ready_done: draw()

#endregion

#region Configuration — Label

@export_group("Label")

@export var show_label: bool = false :
	set(value):
		show_label = value
		if _ready_done: _rebuild_label()

@export var label_text: String = "" :
	set(value):
		label_text = value
		if _ready_done: draw()

@export var auto_label: bool = false :
	set(value):
		auto_label = value
		if _ready_done: draw()

@export_range(0.01, 5.0, 0.01) var label_scale: float = 0.4 :
	set(value):
		label_scale = value
		if _ready_done and _label:
			_label.scale = Vector3.ONE * label_scale

#endregion

#region Configuration — Dash

@export_group("Dash")

@export var dashed: bool = false :
	set(value):
		dashed = value
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var dash_length: float = 0.12 :
	set(value):
		dash_length = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var gap_length: float = 0.06 :
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
var _label: Label3D
var _mesh_instance: MeshInstance3D
var _mesh_instance_back: MeshInstance3D

# Guards setters from calling draw() before _ready() has run.
var _ready_done: bool = false

# Cached geometry
var _left_cap_from: Vector3
var _left_cap_to: Vector3
var _shaft_from: Vector3
var _shaft_to: Vector3
var _right_cap_from: Vector3
var _right_cap_to: Vector3
var _cap_len: float
var _shaft_len: float
var _total_len: float

#endregion

#region Static factories

static func get_default(a: Vector3, b: Vector3) -> BracketLine:
	var bracket_line= BracketLine.new()
	bracket_line.point_a= a
	bracket_line.point_b= b
	return bracket_line
	
	
static func get_with_label(a: Vector3, b: Vector3, text: String) -> BracketLine:
	var br := BracketLine.new()
	br.point_a= a
	br.point_b= b
	br.show_label = true
	br.label_text = text
	return br

static func get_auto_label(a: Vector3, b: Vector3) -> BracketLine:
	var br := BracketLine.new()
	br.point_a= a
	br.point_b= b
	br.show_label = true
	br.auto_label = true
	return br

static func get_dashed(a: Vector3, b: Vector3) -> BracketLine:
	var br := BracketLine.new()
	br.point_a= a
	br.point_b= b
	br.dashed = true
	return br

#endregion

#region Lifecycle

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_setup()
		NOTIFICATION_EXIT_TREE:
			_teardown()

func _setup() -> void:
	if _ready_done:
		return

	_mesh = ImmediateMesh.new()

	_mat_front = StandardMaterial3D.new()
	_mat_front.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_front.vertex_color_use_as_albedo = true
	_mat_front.cull_mode                  = BaseMaterial3D.CULL_DISABLED  # drop _mat_back entirely

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat_front
	add_child(_mesh_instance, false, Node.INTERNAL_MODE_BACK)

	if show_label:
		_create_label()

	_ready_done = true
	_update_geometry()
	draw()

func _teardown() -> void:
	_ready_done = false
	if is_instance_valid(_label):
		_label.queue_free()
		_label = null
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

func set_bracket_size(value: float) -> void:
	bracket_size = value
	_update_geometry()
	draw()

func set_thickness(value: float) -> void:
	thickness = value
	draw()

func set_offset(value: float) -> void:
	offset = value
	_update_geometry()
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

func set_label(text: String) -> void:
	label_text = text
	show_label = true
	auto_label = false
	if not is_instance_valid(_label):
		_create_label()
	draw()

func set_show_label(value: bool) -> void:
	show_label = value
	_rebuild_label()

#endregion

#region Geometry update

func _update_geometry() -> void:
	var dir: Vector3 = point_b - point_a
	var length: float = dir.length()
	if length < 0.001:
		_total_len = 0.0
		return

	var forward: Vector3 = dir.normalized()
	var up: Vector3      = Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	var perp: Vector3    = forward.cross(up).normalized()

	# Shift anchor points by offset along the perpendicular
	var pa: Vector3 = point_a + perp * offset
	var pb: Vector3 = point_b + perp * offset

	var half: float    = bracket_size * 0.5
	_left_cap_from     = pa - perp * half
	_left_cap_to       = pa + perp * half
	_right_cap_from    = pb - perp * half
	_right_cap_to      = pb + perp * half
	_shaft_from        = pa
	_shaft_to          = pb

	_cap_len   = bracket_size
	_shaft_len = pa.distance_to(pb)
	_total_len = _cap_len + _shaft_len + _cap_len

#endregion

#region Drawing

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

func _draw_solid_components(d: float) -> void:
	if d <= _cap_len:
		# Partial left cap only
		var t: float        = d / _cap_len
		var partial_to      := _left_cap_from.lerp(_left_cap_to, t)
		_draw_tube(_left_cap_from, partial_to)
	elif d <= _cap_len + _shaft_len:
		# Full left cap + partial shaft
		_draw_tube(_left_cap_from, _left_cap_to)
		var t: float = (d - _cap_len) / _shaft_len
		_draw_tube(_shaft_from, _shaft_from.lerp(_shaft_to, t))
	else:
		# Full left cap + full shaft + partial right cap
		_draw_tube(_left_cap_from, _left_cap_to)
		_draw_tube(_shaft_from, _shaft_to)
		var t: float = (d - _cap_len - _shaft_len) / _cap_len
		_draw_tube(_right_cap_from, _right_cap_from.lerp(_right_cap_to, t))

func _draw_dashed_components(d: float) -> void:
	if d <= _cap_len:
		_draw_dashed_tube(_left_cap_from, _left_cap_to, d / _cap_len)
	elif d <= _cap_len + _shaft_len:
		_draw_dashed_tube(_left_cap_from, _left_cap_to, 1.0)
		_draw_dashed_tube(_shaft_from, _shaft_to, (d - _cap_len) / _shaft_len)
	else:
		_draw_dashed_tube(_left_cap_from, _left_cap_to, 1.0)
		_draw_dashed_tube(_shaft_from, _shaft_to, 1.0)
		_draw_dashed_tube(_right_cap_from, _right_cap_to, (d - _cap_len - _shaft_len) / _cap_len)

#endregion

#region Geometry helpers

func _draw_tube(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	_connect_rings([
		_build_ring(from, dir.normalized()),
		_build_ring(to,   dir.normalized()),
	])

func _draw_dashed_tube(from: Vector3, to: Vector3, t: float) -> void:
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
		var dash_end :float= min(dist + dash_length, limit)
		_draw_tube(from + forward * dist, from + forward * dash_end)
		dist += pattern

func _build_ring(center: Vector3, forward: Vector3) -> Array[Vector3]:
	var up    := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up        = right.cross(forward).normalized()

	var ring: Array[Vector3] = []
	for j in range(tube_segments):
		var a      := TAU * j / tube_segments
		var offset := (cos(a) * right + sin(a) * up) * thickness
		ring.append(center + offset)
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
	_label.modulate      = color
	add_child(_label)

func _rebuild_label() -> void:
	# Called when show_label is toggled in the editor.
	if show_label:
		if not is_instance_valid(_label):
			_create_label()
	else:
		if is_instance_valid(_label):
			_label.queue_free()
			_label = null
	draw()

func _update_label_visibility() -> void:
	if show_label and is_instance_valid(_label):
		if draw_progress >= 0.999:
			_label.visible  = true
			var mid         := (_shaft_from + _shaft_to) * 0.5
			var dir         := (_shaft_to - _shaft_from).normalized()
			var up          := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
			var perp        := dir.cross(up).normalized()
			_label.position = mid + perp * (bracket_size * 0.7)
			_label.text     = label_text if not auto_label else ("%.2f" % _shaft_len)
			_label.modulate = color
		else:
			_label.visible = false

#endregion
