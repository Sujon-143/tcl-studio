@tool
extends BaseNode3D
class_name DashedLineRS

## A 3D polyline rendered as a tube, with solid or dashed modes,
## animated draw progress, and an optional treadmill effect.
##
## Uses RenderingServer directly instead of MeshInstance3D + ImmediateMesh,
## avoiding per-frame node overhead. Two RID instances share one mesh RID
## (front-cull and back-cull) for double-sided rendering without geometry
## duplication or z-fighting.

#region Configuration — Points and color

@export_group("Line")

@export var points: Array[Vector3] = [] :
	set(value):
		points = value
		if _ready_done: _schedule_draw()

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: _schedule_draw()

@export var glow: bool = false :
	set(value):
		glow = value
		if _ready_done: _update_material_params()

@export var glow_color: Color = Color.YELLOW :
	set(value):
		glow_color = value
		if _ready_done: _update_material_params()

@export var glow_energy: float = 1.0 :
	set(value):
		glow_energy = value
		if _ready_done: _update_material_params()

@export_range(0.001, 5.0, 0.001) var thickness: float = 0.05 :
	set(value):
		thickness = value
		if _ready_done: _schedule_draw()

@export_range(3, 32, 1) var tube_segments: int = 6 :
	set(value):
		tube_segments = max(3, value)
		if _ready_done: _schedule_draw()

#endregion

#region Configuration — Solid / Dash

@export_group("Dash")

@export var solid: bool = false :
	set(value):
		solid = value
		if _ready_done: _schedule_draw()

@export_range(0.001, 2.0, 0.001) var dash_length: float = 0.2 :
	set(value):
		dash_length = max(0.001, value)
		if _ready_done: _schedule_draw()

@export_range(0.001, 2.0, 0.001) var gap_length: float = 0.1 :
	set(value):
		gap_length = max(0.001, value)
		if _ready_done: _schedule_draw()

#endregion

#region Configuration — Treadmill

@export_group("Treadmill")

@export var treadmill: bool = false :
	set(value):
		treadmill = value
		if _ready_done: _schedule_draw()

@export_range(0.0, 20.0, 0.01) var treadmill_speed: float = 1.0

@export var treadmill_reverse: bool = false

@export var treadmill_offset: float = 0.0 :
	set(value):
		treadmill_offset = value
		if _ready_done: _schedule_draw()

#endregion

#region Configuration — Draw progress

@export_group("Draw Progress")

@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0 :
	set(value):
		draw_progress = clamp(value, 0.0, 1.0)
		if _ready_done: _schedule_draw()

#endregion

#region Private

var _mesh_rid:   RID
var _inst_front: RID   # CULL_BACK  — shows outward-facing triangles
var _inst_back:  RID   # CULL_FRONT — shows inward-facing triangles (double-sided)
var _mat_front:  RID
var _mat_back:   RID
var _scenario:   RID

var _ready_done:   bool = false
var _draw_pending: bool = false

# Persistent geometry buffers — cleared and refilled each draw(), never reallocated.
var _verts:   PackedVector3Array = PackedVector3Array()
var _normals: PackedVector3Array = PackedVector3Array()
var _colors:  PackedColorArray   = PackedColorArray()
var _indices: PackedInt32Array   = PackedInt32Array()

#endregion

#region Static factories

static func get_default(is_solid: bool = false) -> DashedLineRS:
	var dl := DashedLineRS.new([Vector3.ZERO, Vector3.FORWARD])
	dl.thickness = 0.01
	dl.color     = Color.RED
	dl.solid     = is_solid
	dl.set_dash_ratio(0.7)
	return dl

static func get_treadmill(p_points: Array[Vector3], speed: float = 1.0) -> DashedLineRS:
	var dl            := DashedLineRS.new(p_points)
	dl.treadmill       = true
	dl.treadmill_speed = speed
	return dl

static func get_treadmill_reverse(p_points: Array[Vector3], speed: float = 1.0) -> DashedLineRS:
	var dl              := DashedLineRS.new(p_points)
	dl.treadmill         = true
	dl.treadmill_speed   = speed
	dl.treadmill_reverse = true
	return dl

#endregion

#region Lifecycle

func _init(p_points: Array[Vector3] = []) -> void:
	points = p_points

func _ready() -> void:
	_scenario = get_world_3d().scenario

	_mesh_rid = RenderingServer.mesh_create()

	# Create one StandardMaterial3D per cull mode and steal their RIDs.
	# We keep the Object wrappers alive in _mat_std_* so the shader stays valid.
	var std_front := StandardMaterial3D.new()
	std_front.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	std_front.vertex_color_use_as_albedo = true
	std_front.cull_mode                  = BaseMaterial3D.CULL_BACK

	var std_back := StandardMaterial3D.new()
	std_back.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	std_back.vertex_color_use_as_albedo = true
	std_back.cull_mode                  = BaseMaterial3D.CULL_FRONT

	# get_rid() returns the internal material RID managed by Godot.
	# We hold a reference to the wrapper objects so the RIDs stay valid.
	_mat_front = std_front.get_rid()
	_mat_back  = std_back.get_rid()

	# Keep the wrappers alive on this node so the RIDs are never freed early.
	set_meta("_std_front", std_front)
	set_meta("_std_back",  std_back)

	_update_material_params()

	_inst_front = RenderingServer.instance_create2(_mesh_rid, _scenario)
	_inst_back  = RenderingServer.instance_create2(_mesh_rid, _scenario)

	RenderingServer.instance_set_surface_override_material(_inst_back, 0, _mat_back)

	_update_transform()

	_ready_done = true
	draw()

func _enter_tree() -> void:
	if _ready_done:
		_update_transform()
		_set_instances_visible(true)

func _exit_tree() -> void:
	_ready_done = false

	if _inst_front.is_valid(): RenderingServer.free_rid(_inst_front)
	if _inst_back.is_valid():  RenderingServer.free_rid(_inst_back)
	if _mesh_rid.is_valid():   RenderingServer.free_rid(_mesh_rid)

	# Releasing the wrapper Objects lets Godot free their internal material RIDs.
	if has_meta("_std_front"): remove_meta("_std_front")
	if has_meta("_std_back"):  remove_meta("_std_back")

	_inst_front = RID(); _inst_back = RID()
	_mat_front  = RID(); _mat_back  = RID()
	_mesh_rid   = RID()

func _process(delta: float) -> void:
	if _ready_done:
		_update_transform()

	if treadmill and not solid and _ready_done:
		var pattern: float = dash_length + gap_length
		var sign:    float = -1.0 if treadmill_reverse else 1.0
		treadmill_offset = fmod(treadmill_offset + sign * treadmill_speed * delta, pattern)
		_schedule_draw()

	if _draw_pending:
		_draw_pending = false
		draw()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			if _ready_done: _update_transform()
		NOTIFICATION_VISIBILITY_CHANGED:
			if _ready_done: _set_instances_visible(is_visible_in_tree())

#endregion

#region Public API

func set_points(p_points: Array[Vector3]) -> void:
	points = p_points

func add_point(p_point: Vector3) -> void:
	points.append(p_point)
	_schedule_draw()

func set_color(new_color: Color) -> void:
	color = new_color

func set_thickness(new_thickness: float) -> void:
	thickness = new_thickness

func set_solid(value: bool) -> void:
	solid = value

func set_dash_length(value: float) -> void:
	dash_length = max(0.001, value)

func set_gap_length(value: float) -> void:
	gap_length = max(0.001, value)

func set_tube_segments(segs: int) -> void:
	tube_segments = max(3, segs)

## ratio: 0 = all gap, 1 = all dash
func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern: float = dash_length + gap_length
	dash_length  = pattern * ratio
	gap_length   = pattern * (1.0 - ratio)

func set_treadmill_reverse(value: bool) -> void:
	treadmill_reverse = value

func reset() -> void:
	draw_progress    = 0.0
	treadmill_offset = 0.0

func clear() -> void:
	points.clear()
	_clear_mesh()

#endregion

#region Draw entry point

func draw() -> void:
	if not _mesh_rid.is_valid():
		return

	_clear_mesh()

	if points.size() < 2:
		return

	var samples: Array         = _build_samples()
	var total_length: float    = samples[-1][1]
	if total_length <= 0.0 or draw_progress <= 0.0:
		return

	var limit: float = total_length * draw_progress

	_verts.clear()
	_normals.clear()
	_colors.clear()
	_indices.clear()

	if solid:
		_draw_solid(samples, limit)
	elif treadmill:
		_draw_treadmill(samples, limit)
	else:
		_draw_dashed(samples, limit)

	_upload_mesh()

#endregion

#region Draw implementations

func _draw_solid(samples: Array, limit: float) -> void:
	for i in range(points.size() - 1):
		var seg_start: float = samples[i][1]
		var seg_end:   float = samples[i + 1][1]
		if seg_start >= limit:
			break
		var from_pos: Vector3 = _sample_at(samples, seg_start)
		var to_pos:   Vector3 = _sample_at(samples, min(seg_end, limit))
		_append_tube_segment(from_pos, to_pos)

func _draw_dashed(samples: Array, limit: float) -> void:
	var pattern: float = dash_length + gap_length
	var dist:    float = 0.0
	while dist < limit:
		var dash_end: float = min(dist + dash_length, limit)
		_append_segment_between(samples, dist, dash_end)
		dist += pattern

func _draw_treadmill(samples: Array, limit: float) -> void:
	var pattern: float = dash_length + gap_length
	var phase:   float = fmod(treadmill_offset, pattern)
	if phase < 0.0:
		phase += pattern
	var dist: float = -phase
	while dist < limit:
		var draw_start: float = max(dist, 0.0)
		var draw_end:   float = min(dist + dash_length, limit)
		if draw_end > draw_start:
			_append_segment_between(samples, draw_start, draw_end)
		dist += pattern

#endregion

#region Geometry helpers

func _build_samples() -> Array:
	var samples:      Array = []
	var accumulated:  float = 0.0
	samples.append([points[0], 0.0])
	for i in range(1, points.size()):
		accumulated += points[i].distance_to(points[i - 1])
		samples.append([points[i], accumulated])
	return samples

func _sample_at(samples: Array, dist: float) -> Vector3:
	for i in range(1, samples.size()):
		var d0: float = samples[i - 1][1]
		var d1: float = samples[i][1]
		if dist <= d1:
			var t: float = (dist - d0) / max(d1 - d0, 0.0001)
			return (samples[i - 1][0] as Vector3).lerp(samples[i][0], t)
	return samples[-1][0]

func _append_tube_segment(from: Vector3, to: Vector3) -> void:
	var dir: Vector3 = to - from
	if dir.length() < 0.0001:
		return
	var forward: Vector3 = dir.normalized()
	var steps:   int     = max(2, int(dir.length() / thickness) + 2)
	var rings:   Array   = []
	for s in range(steps + 1):
		rings.append(_build_ring(from.lerp(to, float(s) / float(steps)), forward))
	_connect_rings(rings, true)

func _append_segment_between(samples: Array, from_dist: float, to_dist: float) -> void:
	var steps:    int    = max(2, int((to_dist - from_dist) / thickness) + 2)
	var rings:    Array  = []
	var last_fwd: Vector3 = Vector3.FORWARD
	for s in range(steps + 1):
		var t:   float   = float(s) / float(steps)
		var d:   float   = lerpf(from_dist, to_dist, t)
		var p:   Vector3 = _sample_at(samples, d)
		var fwd: Vector3
		if s < steps:
			var d_next: float   = lerpf(from_dist, to_dist, float(s + 1) / float(steps))
			var delta:  Vector3 = _sample_at(samples, d_next) - p
			if delta.length() > 0.0001:
				fwd      = delta.normalized()
				last_fwd = fwd
			else:
				fwd = last_fwd
		else:
			fwd = last_fwd
		rings.append(_build_ring(p, fwd))
	_connect_rings(rings, false)

func _build_ring(center: Vector3, forward: Vector3) -> Array[Vector3]:
	var up:    Vector3 = Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right: Vector3 = forward.cross(up).normalized()
	up                 = right.cross(forward).normalized()
	var ring: Array[Vector3] = []
	for j in range(tube_segments):
		var a:      float   = TAU * float(j) / float(tube_segments)
		var offset: Vector3 = (cos(a) * right + sin(a) * up) * thickness
		ring.append(center + offset)
	return ring

func _connect_rings(rings: Array, caps: bool) -> void:
	for s in range(rings.size() - 1):
		var r0: Array[Vector3] = rings[s]
		var r1: Array[Vector3] = rings[s + 1]
		for j in range(r0.size()):
			var nj: int = (j + 1) % r0.size()
			_quad(r0[j], r0[nj], r1[nj], r1[j])

	if not caps:
		return

	var first: Array[Vector3] = rings[0]
	var c0:    Vector3        = _ring_center(first)
	for j in range(first.size()):
		_tri(c0, first[(j + 1) % first.size()], first[j])

	var last: Array[Vector3] = rings[-1]
	var c1:   Vector3        = _ring_center(last)
	for j in range(last.size()):
		_tri(c1, last[j], last[(j + 1) % last.size()])

func _ring_center(ring: Array[Vector3]) -> Vector3:
	var c: Vector3 = Vector3.ZERO
	for v: Vector3 in ring:
		c += v
	return c / ring.size()

func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	var base: int    = _verts.size()
	var n:    Vector3 = (b - a).cross(c - a).normalized()
	_verts.append(a);  _verts.append(b);  _verts.append(c)
	_normals.append(n); _normals.append(n); _normals.append(n)
	_colors.append(color); _colors.append(color); _colors.append(color)
	_indices.append(base); _indices.append(base + 1); _indices.append(base + 2)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(a, b, c)
	_tri(a, c, d)

#endregion

#region RenderingServer helpers

func _upload_mesh() -> void:
	if _verts.is_empty():
		return

	var arr: Array = []
	arr.resize(RenderingServer.ARRAY_MAX)
	arr[RenderingServer.ARRAY_VERTEX] = _verts
	arr[RenderingServer.ARRAY_NORMAL] = _normals
	arr[RenderingServer.ARRAY_COLOR]  = _colors
	arr[RenderingServer.ARRAY_INDEX]  = _indices

	RenderingServer.mesh_add_surface_from_arrays(
		_mesh_rid,
		RenderingServer.PRIMITIVE_TRIANGLES,
		arr
	)

	# Front faces — assigned on the mesh surface itself.
	RenderingServer.mesh_surface_set_material(_mesh_rid, 0, _mat_front)

	# Back faces — per-instance override so the same mesh serves both.
	RenderingServer.instance_set_surface_override_material(_inst_back, 0, _mat_back)

## mesh_clear() removes all surfaces in one call (replaces the absent mesh_remove_surface).
func _clear_mesh() -> void:
	if _mesh_rid.is_valid():
		RenderingServer.mesh_clear(_mesh_rid)

func _update_material_params() -> void:
	# Update the Object wrappers directly — changes propagate automatically
	# to the internal RIDs because Godot tracks them.
	var std_front := get_meta("_std_front", null) as StandardMaterial3D
	var std_back  := get_meta("_std_back",  null) as StandardMaterial3D
	if std_front == null:
		return
	for std: StandardMaterial3D in [std_front, std_back]:
		std.emission_enabled   = glow
		std.emission           = glow_color
		std.emission_energy_multiplier = glow_energy

func _update_transform() -> void:
	if not _inst_front.is_valid():
		return
	var xfm: Transform3D = global_transform
	RenderingServer.instance_set_transform(_inst_front, xfm)
	RenderingServer.instance_set_transform(_inst_back,  xfm)

func _set_instances_visible(v: bool) -> void:
	if not _inst_front.is_valid():
		return
	RenderingServer.instance_set_visible(_inst_front, v)
	RenderingServer.instance_set_visible(_inst_back,  v)

func _schedule_draw() -> void:
	_draw_pending = true

#endregion
