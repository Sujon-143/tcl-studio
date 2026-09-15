@tool
extends BaseNode3D
class_name DashedCircle

## A circle (ring) rendered as a tube, with solid or dashed modes
## and support for animated draw progress.

#region Configuration — Shape

@export_group("Circle")

@export var pos: Vector3 = Vector3.ZERO :
	set(value):
		pos = value
		if _ready_done: draw()

@export_range(0.01, 100.0, 0.001) var radius: float = 1.0 :
	set(value):
		radius = value
		if _ready_done: draw()

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var thickness: float = 0.05 :
	set(value):
		thickness = value
		if _ready_done: draw()

@export_range(3, 32, 1) var tube_segments: int = 6 :
	set(value):
		tube_segments = max(3, value)
		if _ready_done: draw()

#endregion

#region Configuration — Solid / Dash

@export_group("Dash")

## If true, draws a solid ring (ignores dash_length / gap_length).
@export var solid: bool = false :
	set(value):
		solid = value
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var dash_length: float = 0.2 :
	set(value):
		dash_length = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var gap_length: float = 0.1 :
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

# Guards setters from calling draw() before _ready() has run.
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default() -> DashedCircle:
	return DashedCircle.new()

static func get_dashed(p_radius: float = 1.0) -> DashedCircle:
	var c := DashedCircle.new()
	c.radius     = p_radius
	c.solid      = false
	c.thickness  = 0.01
	c.dash_length = 0.21
	c.gap_length  = 0.09
	c.color      = Color.RED
	return c

static func get_solid(p_radius: float = 1.0) -> DashedCircle:
	var c := DashedCircle.new()
	c.radius = p_radius
	c.solid  = true
	return c

#endregion

#region Lifecycle

func _init() -> void:
	_mesh = ImmediateMesh.new()


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

	

	_ready_done = true
	draw()

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

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_radius(new_radius: float) -> void:
	radius = new_radius
	draw()

func set_thickness(new_thickness: float) -> void:
	thickness = new_thickness
	draw()

func set_position_center(new_pos: Vector3) -> void:
	pos = new_pos
	draw()

func set_solid(value: bool) -> void:
	solid = value
	draw()

func set_dash_length(value: float) -> void:
	dash_length = max(0.001, value)
	draw()

func set_gap_length(value: float) -> void:
	gap_length = max(0.001, value)
	draw()

# ratio: 0 = all gap, 1 = all dash
func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

func set_tube_segments(segs: int) -> void:
	tube_segments = max(3, segs)
	draw()

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	var circumference := 2.0 * PI * radius
	if circumference <= 0.0 or draw_progress <= 0.0:
		return

	var limit := circumference * draw_progress

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(color)

	if solid:
		_draw_solid(limit, circumference)
	else:
		_draw_dashed(limit, circumference)

	_mesh.surface_end()

func _draw_solid(limit: float, circumference: float) -> void:
	_draw_tube_arc(0.0, limit / circumference, circumference, true)

func _draw_dashed(limit: float, circumference: float) -> void:
	var pattern := dash_length + gap_length
	var dist    := 0.0
	while dist < limit:
		var dash_end :float= min(dist + dash_length, limit)
		# caps=false: flat end-cap discs make short dash segments look like
		# bottles/arrows. The open tube reads cleanly as a dashed line.
		_draw_tube_arc(dist / circumference, dash_end / circumference, circumference, false)
		dist += pattern

#endregion

#region Geometry helpers

## Draws a curved tube segment from t_start to t_end (t in [0, 1] of full circle).
func _draw_tube_arc(t_start: float, t_end: float, circumference: float, caps: bool) -> void:
	var steps :int= max(2, int((t_end - t_start) * circumference / thickness) + 2)
	var rings: Array = []

	for s in range(steps + 1):
		var t      :float= lerp(t_start, t_end, float(s) / steps)
		var t_next :float= lerp(t_start, t_end, min(float(s + 1) / steps, 1.0))

		var angle      :float= t      * TAU
		var angle_next :float= t_next * TAU

		var center  := pos + Vector3(cos(angle)      * radius, 0.0, sin(angle)      * radius)
		var next_pt := pos + Vector3(cos(angle_next) * radius, 0.0, sin(angle_next) * radius)

		var forward := next_pt - center
		if forward.length() < 0.0001:
			forward = Vector3.FORWARD
		forward = forward.normalized()

		rings.append(_build_ring(center, forward))

	_connect_rings(rings, caps)

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
