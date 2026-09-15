@tool
extends BaseNode3D
class_name CircleSectorQuad

## CircleSector with camera-facing quad borders instead of tubes.
## The filled sector face stays as flat triangles (it IS flat — no billboarding needed).
## Only the border arc and radial edge lines use the quad approach.
## Billboarding is computed per-segment: lateral = cross(seg_dir, to_cam).

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

## Number of segments for the arc border approximation.
@export_range(4, 256, 1) var border_arc_segments: int = 64 :
	set(value):
		border_arc_segments = max(4, value)
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

var _cam_pos_local: Vector3 = Vector3.ZERO
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(from_angle: float, to_angle: float) -> CircleSectorQuad:
	return CircleSectorQuad.new(from_angle, to_angle)

static func get_right_angle() -> CircleSectorQuad:
	var s := CircleSectorQuad.new(0.0, PI / 2.0)
	s.color        = Color(0.2, 0.8, 0.4, 0.35)
	s.border_color = Color(0.2, 0.8, 0.4)
	return s

static func get_half() -> CircleSectorQuad:
	var s := CircleSectorQuad.new(0.0, PI)
	s.color        = Color(0.8, 0.3, 0.2, 0.35)
	s.border_color = Color(0.8, 0.3, 0.2)
	return s

static func get_dashed(from_angle: float, to_angle: float) -> CircleSectorQuad:
	var s := CircleSectorQuad.new(from_angle, to_angle)
	s.dashed_border = true
	return s

#endregion

#region Lifecycle

func _init(p_from: float = 0.0, p_to: float = PI / 2.0) -> void:
	angle_from = p_from
	angle_to   = p_to
	_mesh      = ImmediateMesh.new()

func _ready() -> void:
	_mesh = ImmediateMesh.new()

	_mat_front = StandardMaterial3D.new()
	_mat_front.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_front.vertex_color_use_as_albedo = true
	_mat_front.cull_mode                  = BaseMaterial3D.CULL_BACK
	_mat_front.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA

	_mat_back = StandardMaterial3D.new()
	_mat_back.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_back.vertex_color_use_as_albedo = true
	_mat_back.cull_mode                  = BaseMaterial3D.CULL_FRONT
	_mat_back.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA

	_mesh_instance                   = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat_front
	add_child(_mesh_instance)

	_mesh_instance_back                   = MeshInstance3D.new()
	_mesh_instance_back.mesh              = _mesh
	_mesh_instance_back.material_override = _mat_back
	add_child(_mesh_instance_back)

	_ready_done = true
	draw()

func _exit_tree() -> void:
	_ready_done = false

	if is_instance_valid(_mesh_instance):
		_mesh_instance.mesh = null
		_mesh_instance.queue_free()
		_mesh_instance = null

	if is_instance_valid(_mesh_instance_back):
		_mesh_instance_back.mesh = null
		_mesh_instance_back.queue_free()
		_mesh_instance_back = null

	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
		_mesh = null

	_mat_front = null
	_mat_back  = null

func _process(_delta: float) -> void:
	draw()

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

	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_position()

	var start_angle := angle_from
	var end_angle   := angle_from + (angle_to - angle_from) * draw_progress
	if end_angle <= start_angle + 0.0001:
		return

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	_draw_filled_sector(start_angle, end_angle)

	if show_border:
		_draw_border(start_angle, end_angle)

	_mesh.surface_end()

func _draw_filled_sector(start_angle: float, end_angle: float) -> void:
	var span  := end_angle - start_angle
	var step  := span / segments
	var y_top := thickness

	for i in range(segments):
		var a0 := start_angle + i * step
		var a1 := a0 + step

		var p0 := pos + Vector3(cos(a0) * radius, y_top, sin(a0) * radius)
		var p1 := pos + Vector3(cos(a1) * radius, y_top, sin(a1) * radius)

		_mesh.surface_set_color(color)
		_tri(pos + Vector3(0, y_top, 0), p0, p1)

		_mesh.surface_set_color(Color(color.r, color.g, color.b, color.a * 0.5))
		_tri(pos, p1, p0)

		_mesh.surface_set_color(Color(color.r, color.g, color.b, color.a * 0.6))
		_quad(p0, p1, p1 - Vector3(0, y_top, 0), p0 - Vector3(0, y_top, 0))

	_draw_sector_wall(start_angle)
	if end_angle - start_angle > 0.0001:
		_draw_sector_wall(end_angle)

func _draw_sector_wall(angle: float) -> void:
	var y_top         := thickness
	var center_bottom := pos
	var center_top    := pos + Vector3(0, y_top, 0)
	var outer_bottom  := pos + Vector3(cos(angle) * radius, 0.0,   sin(angle) * radius)
	var outer_top     := pos + Vector3(cos(angle) * radius, y_top, sin(angle) * radius)

	_mesh.surface_set_color(Color(color.r, color.g, color.b, color.a * 0.6))
	_quad(center_bottom, outer_bottom, outer_top, center_top)

func _draw_border(start_angle: float, end_angle: float) -> void:
	_mesh.surface_set_color(border_color)
	var arc_length := (end_angle - start_angle) * radius

	if dashed_border:
		var pattern := dash_length + gap_length
		var dist    := 0.0
		while dist < arc_length:
			var dash_end: float = min(dist + dash_length, arc_length)
			var t0 := dist / arc_length
			var t1 := dash_end / arc_length
			_draw_border_arc(
				start_angle + (end_angle - start_angle) * t0,
				start_angle + (end_angle - start_angle) * t1
			)
			dist += pattern
	else:
		_draw_border_arc(start_angle, end_angle)

	_draw_border_radial(start_angle)
	if end_angle - start_angle > 0.0001:
		_draw_border_radial(end_angle)

func _draw_border_arc(arc_start: float, arc_end: float) -> void:
	if arc_end - arc_start < 0.001:
		return
	var y     := thickness
	var span  := arc_end - arc_start
	var steps :int= max(1, int(border_arc_segments * (span / TAU)))
	for s in range(steps):
		var t0 :float= lerp(arc_start, arc_end, float(s)     / steps)
		var t1 :float= lerp(arc_start, arc_end, float(s + 1) / steps)
		var p0 := pos + Vector3(cos(t0) * radius, y, sin(t0) * radius)
		var p1 := pos + Vector3(cos(t1) * radius, y, sin(t1) * radius)
		_draw_quad_segment(p0, p1)

func _draw_border_radial(angle: float) -> void:
	var y    := thickness
	var from := pos + Vector3(0, y, 0)
	var to   := pos + Vector3(cos(angle) * radius, y, sin(angle) * radius)
	_draw_quad_segment(from, to)

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
	lateral = lateral.normalized() * border_thickness

	_mesh.surface_set_color(border_color)
	_quad(from - lateral, from + lateral, to + lateral, to - lateral)

func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(b)
	_mesh.surface_add_vertex(c)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(a, b, c)
	_tri(a, c, d)

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
