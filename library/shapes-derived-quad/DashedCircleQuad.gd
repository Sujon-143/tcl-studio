@tool
extends BaseNode3D
class_name DashedCircleQuad

## DashedCircle rendered as camera-facing quads instead of tubes.
## All features (solid/dashed, draw_progress) are preserved.
## Billboarding is computed per-segment: lateral = cross(seg_dir, to_cam).

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

## Number of straight quad segments used to approximate the full circle.
@export_range(4, 256, 1) var circle_segments: int = 64 :
	set(value):
		circle_segments = max(4, value)
		if _ready_done: draw()

#endregion

#region Configuration — Solid / Dash

@export_group("Dash")

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
var _mat: StandardMaterial3D
var _mesh_instance: MeshInstance3D

var _cam_pos_local: Vector3 = Vector3.ZERO
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default() -> DashedCircleQuad:
	return DashedCircleQuad.new()

static func get_dashed(p_radius: float = 1.0) -> DashedCircleQuad:
	var c := DashedCircleQuad.new()
	c.radius      = p_radius
	c.solid       = false
	c.thickness   = 0.01
	c.dash_length = 0.21
	c.gap_length  = 0.09
	c.color       = Color.RED
	return c

static func get_solid(p_radius: float = 1.0) -> DashedCircleQuad:
	var c := DashedCircleQuad.new()
	c.radius = p_radius
	c.solid  = true
	return c

#endregion

#region Lifecycle

func _init() -> void:
	_mesh = ImmediateMesh.new()

func _ready() -> void:
	_mesh = ImmediateMesh.new()

	_mat = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED

	_mesh_instance                   = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat
	add_child(_mesh_instance)

	_ready_done = true
	draw()

func _exit_tree() -> void:
	_ready_done = false

	if is_instance_valid(_mesh_instance):
		_mesh_instance.mesh = null
		_mesh_instance.queue_free()
		_mesh_instance = null

	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
		_mesh = null

	_mat = null

func _process(_delta: float) -> void:
	draw()

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

func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

func set_circle_segments(segs: int) -> void:
	circle_segments = max(4, segs)
	draw()

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	var circumference := TAU * radius
	if circumference <= 0.0 or draw_progress <= 0.0:
		return

	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_position()

	var limit := circumference * draw_progress

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(color)

	if solid:
		_draw_arc(0.0, limit, circumference)
	else:
		var pattern := dash_length + gap_length
		var dist    := 0.0
		while dist < limit:
			var dash_end: float = min(dist + dash_length, limit)
			_draw_arc(dist, dash_end, circumference)
			dist += pattern

	_mesh.surface_end()

## Draws a portion of the circle between two arc-length distances.
func _draw_arc(from_dist: float, to_dist: float, circumference: float) -> void:
	if to_dist - from_dist < 0.0001:
		return
	# Convert arc lengths to angles.
	var a_start := (from_dist / circumference) * TAU
	var a_end   := (to_dist   / circumference) * TAU

	# Number of segments proportional to arc span vs full circle.
	var span_frac := (to_dist - from_dist) / circumference
	var steps     :int= max(1, int(circle_segments * span_frac))

	for s in range(steps):
		var t0 :float= lerp(a_start, a_end, float(s)     / steps)
		var t1 :float= lerp(a_start, a_end, float(s + 1) / steps)
		var p0 := pos + Vector3(cos(t0) * radius, 0.0, sin(t0) * radius)
		var p1 := pos + Vector3(cos(t1) * radius, 0.0, sin(t1) * radius)
		_draw_quad_segment(p0, p1)

#endregion

#region Geometry helpers

func _draw_quad_segment(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()

	var mid    := (from + to) * 0.5
	var to_cam := _cam_pos_local - mid
	if to_cam.length() < 0.0001:
		to_cam = Vector3.UP
	to_cam = to_cam.normalized()

	var lateral := dir.cross(to_cam)
	if lateral.length() < 0.0001:
		var arb := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		lateral = dir.cross(arb)
	lateral = lateral.normalized() * thickness

	_quad(from - lateral, from + lateral, to + lateral, to - lateral)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(b)
	_mesh.surface_add_vertex(c)
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(c)
	_mesh.surface_add_vertex(d)

func _get_camera_world_position() -> Vector3:
	if Engine.is_editor_hint():
		var ei := Engine.get_singleton("EditorInterface") as Object
		if ei:
			for i in range(4):
				var vp = ei.call("get_editor_viewport_3d", i)
				if vp:
					var cam = vp.get_camera_3d()
					if cam and cam.current:
						return cam.global_position
			for i in range(4):
				var vp = ei.call("get_editor_viewport_3d", i)
				if vp:
					var cam = vp.get_camera_3d()
					if cam:
						return cam.global_position
		return Vector3.ZERO
	var vp := get_viewport()
	if vp:
		var cam := vp.get_camera_3d()
		if cam:
			return cam.global_position
	return Vector3.ZERO

#endregion
