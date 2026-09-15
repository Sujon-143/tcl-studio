@tool
extends BaseNode3D
class_name CircleSector

## A 3D filled pie-slice (sector) with an optional tube border.
## The filled face is a fan of triangles from the centre; the border is
## a tube that runs along the outer arc and down each radial edge.

#region Configuration — Sector shape

@export_group("Sector")

@export var pos: Vector3 = Vector3.ZERO :
	set(value):
		pos = value
		if _ready_done: draw()

@export var angle_from: float = 0.0 :
	set(value):
		angle_from = value
		if _ready_done: draw()

@export var angle_to: float = PI / 2.0 :
	set(value):
		angle_to = value
		if _ready_done: draw()

@export_range(0.01, 100.0, 0.001) var radius: float = 1.0 :
	set(value):
		radius = value
		if _ready_done: draw()

@export var color: Color = Color(1, 1, 0, 0.4) :
	set(value):
		color = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var thickness: float = 0.01 :
	set(value):
		thickness = value
		if _ready_done: draw()

@export_range(3, 128, 1) var segments: int = 32 :
	set(value):
		segments = value
		if _ready_done: draw()

#endregion

#region Configuration — Border

@export_group("Border")

@export var show_border: bool = true :
	set(value):
		show_border = value
		if _ready_done: draw()

@export var border_color: Color = Color.WHITE :
	set(value):
		border_color = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var border_thickness: float = 0.03 :
	set(value):
		border_thickness = value
		if _ready_done: draw()

@export_range(3, 32, 1) var border_tube_segments: int = 8 :
	set(value):
		border_tube_segments = value
		if _ready_done: draw()

#endregion

#region Configuration — Dash

@export_group("Dash")

@export var dashed_border: bool = false :
	set(value):
		dashed_border = value
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

# Guards setters from calling draw() before _ready() has run.
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(from_angle: float, to_angle: float) -> CircleSector:
	return CircleSector.new(from_angle, to_angle)

static func get_right_angle() -> CircleSector:
	var s := CircleSector.new(0.0, PI / 2.0)
	s.color        = Color(0.2, 0.8, 0.4, 0.35)
	s.border_color = Color(0.2, 0.8, 0.4)
	return s

static func get_half() -> CircleSector:
	var s := CircleSector.new(0.0, PI)
	s.color        = Color(0.8, 0.3, 0.2, 0.35)
	s.border_color = Color(0.8, 0.3, 0.2)
	return s

static func get_dashed(from_angle: float, to_angle: float) -> CircleSector:
	var s := CircleSector.new(from_angle, to_angle)
	s.dashed_border = true
	return s

#endregion

#region Lifecycle

func _init(p_from: float = 0.0, p_to: float = PI / 2.0) -> void:
	angle_from = p_from
	angle_to   = p_to
	_mesh      = ImmediateMesh.new()


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

func set_angles(from_angle: float, to_angle: float) -> void:
	angle_from = from_angle
	angle_to   = to_angle
	draw()

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_radius(new_radius: float) -> void:
	radius = new_radius
	draw()

func set_show_border(value: bool) -> void:
	show_border = value
	draw()

func set_dashed_border(value: bool) -> void:
	dashed_border = value
	draw()

func set_border_color(new_color: Color) -> void:
	border_color = new_color
	draw()

func set_border_thickness(t: float) -> void:
	border_thickness = t
	draw()

# ratio: 0 = all gap, 1 = all dash
func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	if draw_progress <= 0.0:
		return

	var start_angle := angle_from
	var end_angle   := angle_from + (angle_to - angle_from) * draw_progress
	if end_angle <= start_angle + 0.0001:
		return

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	_draw_filled_sector(start_angle, end_angle)

	if show_border:
		_draw_border(start_angle, end_angle)

	_mesh.surface_end()

# Filled pie slice — fan of triangles from the centre, with outer rim quads
# and side walls on both radial edges.
func _draw_filled_sector(start_angle: float, end_angle: float) -> void:
	var span   := end_angle - start_angle
	var step   := span / segments
	var y_top  := thickness

	for i in range(segments):
		var a0 := start_angle + i * step
		var a1 := a0 + step

		var p0 := pos + Vector3(cos(a0) * radius, y_top, sin(a0) * radius)
		var p1 := pos + Vector3(cos(a1) * radius, y_top, sin(a1) * radius)

		# Top face (centre → arc)
		_mesh.surface_set_color(color)
		_tri(pos + Vector3(0, y_top, 0), p0, p1)

		# Bottom face (slightly dimmed for depth)
		_mesh.surface_set_color(Color(color.r, color.g, color.b, color.a * 0.5))
		_tri(pos, p1, p0)

		# Outer rim quad (vertical band at the arc edge)
		_mesh.surface_set_color(Color(color.r, color.g, color.b, color.a * 0.6))
		_quad(p0, p1, p1 - Vector3(0, y_top, 0), p0 - Vector3(0, y_top, 0))

	# Vertical walls along both radial edges
	_draw_sector_wall(start_angle)
	if end_angle - start_angle > 0.0001:
		_draw_sector_wall(end_angle)

# Vertical quad for a single radial edge at the given angle.
func _draw_sector_wall(angle: float) -> void:
	var y_top          := thickness
	var center_bottom  := pos
	var center_top     := pos + Vector3(0, y_top, 0)
	var outer_bottom   := pos + Vector3(cos(angle) * radius, 0.0,   sin(angle) * radius)
	var outer_top      := pos + Vector3(cos(angle) * radius, y_top, sin(angle) * radius)

	_mesh.surface_set_color(Color(color.r, color.g, color.b, color.a * 0.6))
	_quad(center_bottom, outer_bottom, outer_top, center_top)

# Outer arc border (dashed or solid) plus the two radial edge lines.
func _draw_border(start_angle: float, end_angle: float) -> void:
	var arc_length := (end_angle - start_angle) * radius

	if dashed_border:
		var pattern := dash_length + gap_length
		var dist    := 0.0
		while dist < arc_length:
			var dash_end :float= min(dist + dash_length, arc_length)
			var t0       := dist / arc_length
			var t1       := dash_end / arc_length
			# caps=false: prevents bottle/arrow artifact on short dash segments
			_draw_border_arc(
				start_angle + (end_angle - start_angle) * t0,
				start_angle + (end_angle - start_angle) * t1,
				false
			)
			dist += pattern
	else:
		_draw_border_arc(start_angle, end_angle)

	# Radial edge lines — only two distinct edges when span > epsilon
	_draw_border_line(start_angle)
	if end_angle - start_angle > 0.0001:
		_draw_border_line(end_angle)

# Tube that follows the outer arc between two angles.
# caps=false: flat end-cap discs make short dash segments look like
# bottles/arrows. The open tube reads cleanly as a dashed line.
func _draw_border_arc(arc_start: float, arc_end: float, caps: bool = true) -> void:
	if arc_end - arc_start < 0.001:
		return

	var y     := thickness
	var steps :int= max(2, int((arc_end - arc_start) * radius / border_thickness) + 2)
	var rings: Array = []

	for s in range(steps + 1):
		var t      :float= lerp(arc_start, arc_end, float(s) / steps)
		var t_next :float= lerp(arc_start, arc_end, min(float(s + 1) / steps, 1.0))

		var center  := pos + Vector3(cos(t)      * radius, y, sin(t)      * radius)
		var next_pt := pos + Vector3(cos(t_next) * radius, y, sin(t_next) * radius)

		var forward := next_pt - center
		if forward.length() < 0.0001:
			forward = Vector3.FORWARD
		forward = forward.normalized()

		rings.append(_build_ring(center, forward))

	_connect_rings(rings, caps)

# Tube along a radial edge (centre → arc rim) at the given angle.
func _draw_border_line(angle: float) -> void:
	var y    := thickness
	var from := pos + Vector3(0, y, 0)
	var to   := pos + Vector3(cos(angle) * radius, y, sin(angle) * radius)

	var dir := to - from
	if dir.length() < 0.001:
		return
	# Radial edges are always solid and always have caps.
	_connect_rings([_build_ring(from, dir.normalized()), _build_ring(to, dir.normalized())])

#endregion

#region Geometry helpers

func _build_ring(center: Vector3, forward: Vector3) -> Array[Vector3]:
	var up    := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up        = right.cross(forward).normalized()

	var ring: Array[Vector3] = []
	for j in range(border_tube_segments):
		var a      := TAU * j / border_tube_segments
		var offset := (cos(a) * right + sin(a) * up) * border_thickness
		ring.append(center + offset)
	return ring

func _connect_rings(rings: Array, caps: bool = true) -> void:
	for s in range(rings.size() - 1):
		var r0: Array = rings[s]
		var r1: Array = rings[s + 1]
		for j in range(r0.size()):
			var nj := (j + 1) % r0.size()
			_mesh.surface_set_color(border_color)
			_quad(r0[j], r0[nj], r1[nj], r1[j])

	if not caps:
		return

	var first: Array = rings[0]
	var c0 := _ring_center(first)
	for j in range(first.size()):
		_mesh.surface_set_color(border_color)
		_tri(c0, first[(j + 1) % first.size()], first[j])

	var last: Array = rings[-1]
	var c1 := _ring_center(last)
	for j in range(last.size()):
		_mesh.surface_set_color(border_color)
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
