@tool
extends BaseNode3D
class_name DashedLineQuad

## A 3D polyline rendered as camera-facing quads, with solid or dashed modes,
## animated draw progress, and an optional treadmill effect that scrolls the
## dash pattern along the fixed points.
##
## Billboarding is done manually per-segment: for each quad the lateral offset
## axis is computed as cross(segment_dir, to_cam), so every quad lies in the
## plane that contains its segment and the camera. This works correctly for
## lines of any orientation, including vertical and diagonal ones.
## No material billboard_mode is used.

#region Configuration — Points and color

@export_group("Line")

@export var points: Array[Vector3] = [] :
	set(value):
		points = value
		if _ready_done: draw()

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: draw()

## Half-width of the quad strip in world units.
@export_range(0.001, 1.0, 0.001) var thickness: float = 0.05 :
	set(value):
		thickness = value
		if _ready_done: draw()

#endregion

#region Configuration — Solid / Dash

@export_group("Dash")

## If true, draws a continuous solid line (ignores dash_length / gap_length).
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

#region Configuration — Treadmill

@export_group("Treadmill")

## Scrolls the dash pattern along the line without moving the points.
## Has no effect when solid = true.
@export var treadmill: bool = false :
	set(value):
		treadmill = value
		if _ready_done: draw()

## Units per second the pattern scrolls along the line.
@export_range(0.0, 20.0, 0.01) var treadmill_speed: float = 1.0

## When true the pattern scrolls from point_b toward point_a (backwards).
## When false it scrolls from point_a toward point_b (forward, the default).
@export var treadmill_reverse: bool = false

## Current scroll offset in world units. Can be driven externally or via
## _process when treadmill = true and treadmill_speed > 0.
@export var treadmill_offset: float = 0.0 :
	set(value):
		treadmill_offset = value
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

## Camera position in this node's local space, refreshed at the start of
## every draw() call so _draw_quad_segment() can access it cheaply.
var _cam_pos_local: Vector3 = Vector3.ZERO

# Guards setters from calling draw() before _ready() has run.
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(is_solid: bool = false) -> DashedLineQuad:
	var dl := DashedLineQuad.new([Vector3.ZERO, Vector3.FORWARD])
	dl.thickness = 0.01
	dl.color     = Color.RED
	dl.solid     = is_solid
	dl.set_dash_ratio(0.7)
	return dl

static func get_treadmill(p_points: Array[Vector3], speed: float = 1.0) -> DashedLineQuad:
	var dl := DashedLineQuad.new(p_points)
	dl.treadmill       = true
	dl.treadmill_speed = speed
	return dl

static func get_treadmill_reverse(p_points: Array[Vector3], speed: float = 1.0) -> DashedLineQuad:
	var dl := DashedLineQuad.new(p_points)
	dl.treadmill         = true
	dl.treadmill_speed   = speed
	dl.treadmill_reverse = true
	return dl

#endregion

#region Lifecycle

func _init(p_points: Array[Vector3] = []) -> void:
	points = p_points
	_mesh  = ImmediateMesh.new()

func _ready() -> void:
	_mesh = ImmediateMesh.new()

	_mat = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	# No billboard_mode — facing is computed manually per segment in draw().

	_mesh_instance = MeshInstance3D.new()
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

func _process(delta: float) -> void:
	# Rebuild every frame: camera may have moved even when the line hasn't.
	if treadmill and not solid:
		var pattern      := dash_length + gap_length
		var sign         := -1.0 if treadmill_reverse else 1.0
		treadmill_offset  = fmod(treadmill_offset + sign * treadmill_speed * delta, pattern)
	draw()

#endregion

#region Public API

func set_points(p_points: Array[Vector3]) -> void:
	points = p_points
	draw()

func add_point(p_point: Vector3) -> void:
	points.append(p_point)
	draw()

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_thickness(new_thickness: float) -> void:
	thickness = new_thickness
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

func set_treadmill_reverse(value: bool) -> void:
	treadmill_reverse = value

## Resets the line to invisible without changing points.
func reset() -> void:
	draw_progress    = 0.0
	treadmill_offset = 0.0
	draw()

## Removes all points and clears the mesh.
func clear() -> void:
	points.clear()
	if is_instance_valid(_mesh):
		_mesh.clear_surfaces()

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	if points.size() < 2:
		return

	# Bring camera into this node's local space once per frame.
	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_position()

	var samples             := _build_samples()
	var total_length: float  = samples[-1][1]
	if total_length <= 0.0 or draw_progress <= 0.0:
		return

	var limit := total_length * draw_progress

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(color)

	if solid:
		_draw_solid(samples, limit)
	elif treadmill:
		_draw_treadmill(samples, limit)
	else:
		_draw_dashed(samples, limit)

	_mesh.surface_end()

func _draw_solid(samples: Array, limit: float) -> void:
	for i in range(samples.size() - 1):
		var seg_start: float = samples[i][1]
		var seg_end:   float = samples[i + 1][1]
		if seg_start >= limit:
			break
		var from_pos := _sample_at(samples, seg_start)
		var to_pos   := _sample_at(samples, min(seg_end, limit))
		_draw_quad_segment(from_pos, to_pos)

func _draw_dashed(samples: Array, limit: float) -> void:
	var pattern := dash_length + gap_length
	var dist    := 0.0
	while dist < limit:
		var dash_end: float = min(dist + dash_length, limit)
		_draw_span(samples, dist, dash_end)
		dist += pattern

func _draw_treadmill(samples: Array, limit: float) -> void:
	var pattern := dash_length + gap_length

	var phase := fmod(treadmill_offset, pattern)
	if phase < 0.0:
		phase += pattern

	var dist := -phase
	while dist < limit:
		var draw_start: float = max(dist, 0.0)
		var draw_end:   float = min(dist + dash_length, limit)
		if draw_end > draw_start:
			_draw_span(samples, draw_start, draw_end)
		dist += pattern

## Walks each polyline edge overlapping [from_dist, to_dist] and emits one
## quad per edge. Clipping per edge keeps dashes clean across bends.
func _draw_span(samples: Array, from_dist: float, to_dist: float) -> void:
	if to_dist - from_dist < 0.0001:
		return
	for i in range(samples.size() - 1):
		var seg_s: float = samples[i][1]
		var seg_e: float = samples[i + 1][1]
		if seg_e <= from_dist:
			continue
		if seg_s >= to_dist:
			break
		var clip_s: float = max(seg_s, from_dist)
		var clip_e: float = min(seg_e, to_dist)
		_draw_quad_segment(_sample_at(samples, clip_s), _sample_at(samples, clip_e))

#endregion

#region Geometry helpers

## Returns [[point, cumulative_distance], …] for each control point.
func _build_samples() -> Array:
	var samples: Array = []
	var accumulated    := 0.0
	samples.append([points[0], 0.0])
	for i in range(1, points.size()):
		accumulated += points[i].distance_to(points[i - 1])
		samples.append([points[i], accumulated])
	return samples

## Returns the local-space point on the polyline at arc-length distance.
func _sample_at(samples: Array, dist: float) -> Vector3:
	for i in range(1, samples.size()):
		var d0: float = samples[i - 1][1]
		var d1: float = samples[i][1]
		if dist <= d1:
			var t: float = (dist - d0) / max(d1 - d0, 0.0001)
			return samples[i - 1][0].lerp(samples[i][0], t)
	return samples[-1][0]

## Emits one camera-facing quad for the segment from → to (local space).
##
## Lateral axis = cross(segment_dir, to_cam).
##   • segment_dir   — direction the line travels along this edge.
##   • to_cam        — direction from the segment midpoint toward the camera.
## Their cross product is perpendicular to both, i.e. it lies in the plane
## that contains the segment and the camera — which is exactly the plane the
## quad should be visible from. This works for horizontal, vertical, and any
## diagonal segments without any special-casing.
func _draw_quad_segment(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()

	var mid    := (from + to) * 0.5
	var to_cam := _cam_pos_local - mid
	if to_cam.length() < 0.0001:
		to_cam = Vector3.UP        # camera exactly on the segment — rare fallback
	to_cam = to_cam.normalized()

	var lateral := dir.cross(to_cam)
	if lateral.length() < 0.0001:
		# Segment aims directly at camera; any perpendicular will do.
		var arb := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		lateral = dir.cross(arb)
	lateral = lateral.normalized() * thickness

	_quad(from - lateral, from + lateral,
		  to   + lateral, to   - lateral)

## Emits two triangles forming a quad (a b c d, counter-clockwise).
func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(b)
	_mesh.surface_add_vertex(c)
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(c)
	_mesh.surface_add_vertex(d)

## Returns the active camera's world-space position.
## Works in both editor (@tool) and runtime.
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
			# Fallback: first available editor camera.
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
