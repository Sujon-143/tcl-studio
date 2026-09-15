@tool
extends BaseNode3D
class_name Spring3D

#region ── Exports ─────────────────────────────────────────────────────────────

@export_group("Endpoints")

@export var point_a: Vector3 = Vector3(0.0, 1.0, 0.0):
	set(v):
		point_a = v
		_dirty = true

@export var point_b: Vector3 = Vector3(0.0, -1.0, 0.0):
	set(v):
		point_b = v
		_dirty = true

@export var end_a_fixed: bool = true:
	set(v):
		end_a_fixed = v
		_dirty = true

@export var end_b_fixed: bool = false:
	set(v):
		end_b_fixed = v
		_dirty = true

@export var end_a_node: NodePath = NodePath()
@export var end_b_node: NodePath = NodePath()

# -----------------------------------------------------------------------------
@export_group("Physics")

@export_range(0.1, 500.0, 0.1) var spring_constant: float = 20.0

@export_range(0.01, 20.0, 0.01) var rest_length: float = 2.0:
	set(v):
		var new_len :float= max(0.01, v)
		if not is_equal_approx(rest_length, new_len):
			rest_length = new_len
			_rest_length_changed = true
			_dirty = true
			_needs_full_rebuild = true
			if _ready_done and Engine.is_editor_hint() and physics_paused and snap_to_rest_length:
				_snap_to_rest_length()

## Maximum extension beyond rest length before the spring force stops increasing.
## Set to 0 for no limit.
@export_range(0.0, 20.0, 0.01) var elastic_limit: float = 0.0

@export_range(0.01, 100.0, 0.01) var mass: float = 1.0
@export_range(0.0, 200.0, 0.01) var damping: float = 2.0
@export_range(0.0, 50.0, 0.01) var angular_damping: float = 1.0
@export_range(0.0, 200.0, 0.1) var max_velocity: float = 20.0
@export_range(0.0, 30.0, 0.01) var gravity: float = 9.8

@export var gravity_direction: Vector3 = Vector3.DOWN:
	set(v):
		gravity_direction = v.normalized() if v.length() > 0.0001 else Vector3.DOWN

# -----------------------------------------------------------------------------
@export_group("Editor Helpers")

## When true, changing rest_length moves the free endpoint(s) to match it.
@export var snap_to_rest_length: bool = true

## One-shot: sets rest_length to the current distance between endpoints.
@export var set_rest_to_current: bool = false:
	set(v):
		if v and _ready_done:
			rest_length = point_a.distance_to(point_b)
		set_rest_to_current = false

# -----------------------------------------------------------------------------
@export_group("Mesh - Tube")

@export_range(1, 64, 1) var coil_turns: int = 8:
	set(v):
		coil_turns = max(1, v)
		_needs_full_rebuild = true

@export_range(3, 64, 1) var segments_per_turn: int = 12:
	set(v):
		segments_per_turn = max(3, v)
		_needs_full_rebuild = true

@export_range(0.001, 4.0, 0.001) var coil_radius: float = 0.15:
	set(v):
		coil_radius = max(0.001, v)
		_needs_full_rebuild = true

@export_range(0.001, 0.5, 0.001) var wire_thickness: float = 0.02:
	set(v):
		wire_thickness = max(0.001, v)
		_needs_full_rebuild = true

@export_range(0, 4, 1) var end_cap_turns: int = 0:
	set(v):
		end_cap_turns = max(0, v)
		_needs_full_rebuild = true

@export_range(3, 16, 1) var radial_segments: int = 8:
	set(v):
		radial_segments = max(3, v)
		_needs_full_rebuild = true

@export var color: Color = Color(0.82, 0.82, 0.86, 1.0):
	set(v):
		color = v
		if _mesh_material:
			_mesh_material.albedo_color = v

# -----------------------------------------------------------------------------
@export_group("Simulation Control")

@export var physics_paused: bool = true

@export var reset_simulation: bool = false:
	set(v):
		if v and _ready_done:
			_pos_a = global_transform * point_a
			_pos_b = global_transform * point_b
			_vel_a = Vector3.ZERO
			_vel_b = Vector3.ZERO

			if _needs_full_rebuild or _mesh.get_surface_count() == 0:
				_rebuild_mesh_full()
				_needs_full_rebuild = false
				_dirty = false
			else:
				_update_mesh_positions()

			_push_to_child_nodes()

			if Engine.is_editor_hint():
				update_gizmos()

			_needs_reset = false
		reset_simulation = false

#endregion

#region ── Private state ───────────────────────────────────────────────────────

var _pos_a: Vector3 = Vector3.ZERO
var _pos_b: Vector3 = Vector3.ZERO
var _vel_a: Vector3 = Vector3.ZERO
var _vel_b: Vector3 = Vector3.ZERO

var _mesh: ArrayMesh
var _mesh_material: StandardMaterial3D
var _mesh_instance: MeshInstance3D

var _ready_done: bool = false
var _dirty: bool = true
var _needs_full_rebuild: bool = true
var _needs_reset: bool = true
var _rest_length_changed: bool = false

var _vertex_count: int = 0
var _indices: PackedInt32Array = PackedInt32Array()
var _normals: PackedVector3Array = PackedVector3Array()
var _uvs: PackedVector2Array = PackedVector2Array()
var _base_positions: PackedVector3Array = PackedVector3Array()

var _points: Array[Vector3] = []
var _frames: Array[Vector3] = []
var _vertex_buffer: PackedVector3Array = PackedVector3Array()

var _last_length: float = 0.0

#endregion

#region ── Lifecycle ───────────────────────────────────────────────────────────

func _ready() -> void:
	_mesh = ArrayMesh.new()

	_mesh_material = StandardMaterial3D.new()
	_mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh_material.vertex_color_use_as_albedo = true
	_mesh_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_material.albedo_color = color

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.material_override = _mesh_material
	add_child(_mesh_instance)

	_ready_done = true
	_needs_reset = true
	_needs_full_rebuild = true


func _exit_tree() -> void:
	_ready_done = false
	if is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()
	_mesh = null
	_mesh_material = null


func _process(delta: float) -> void:
	if not _ready_done:
		return

	var is_editor := Engine.is_editor_hint()

	# ----- Editor behaviour ----------------------------------------------------
	if is_editor:
		if physics_paused:
			if _dirty or _needs_full_rebuild or _rest_length_changed:
				_pos_a = global_transform * point_a
				_pos_b = global_transform * point_b
				_rebuild_mesh_full()
				_dirty = false
				_needs_full_rebuild = false
				_rest_length_changed = false
			return
		# Not paused: simulation runs – fall through to common code below.

	# ----- Common simulation / update code (runtime + editor when not paused) ---
	if _needs_reset:
		_reset_state()
		_needs_reset = false

	if _needs_full_rebuild:
		_rebuild_mesh_full()
		_needs_full_rebuild = false

	if _rest_length_changed:
		if end_a_fixed and end_b_fixed:
			_rebuild_mesh_full()
		_rest_length_changed = false

	_update_fixed_endpoints()
	if not physics_paused:
		_step_physics(delta)
	_push_to_child_nodes()
	_update_mesh_positions()

#endregion

#region ── Public API ──────────────────────────────────────────────────────────

func teleport_a(world_pos: Vector3) -> void:
	_pos_a = world_pos
	_vel_a = Vector3.ZERO

func teleport_b(world_pos: Vector3) -> void:
	_pos_b = world_pos
	_vel_b = Vector3.ZERO

func impulse_a(impulse: Vector3) -> void:
	if not end_a_fixed:
		_vel_a += impulse / max(mass, 0.0001)

func impulse_b(impulse: Vector3) -> void:
	if not end_b_fixed:
		_vel_b += impulse / max(mass, 0.0001)

func reset() -> void:
	_reset_state()

func get_position_a() -> Vector3: return _pos_a
func get_position_b() -> Vector3: return _pos_b
func get_velocity_a() -> Vector3: return _vel_a
func get_velocity_b() -> Vector3: return _vel_b
func get_extension() -> float: return (_pos_b - _pos_a).length() - rest_length

#endregion

#region ── Editor Helper: Snap to Rest Length ─────────────────────────────────

func _snap_to_rest_length() -> void:
	if not Engine.is_editor_hint() or not physics_paused:
		return

	var dir := (point_b - point_a).normalized()
	if dir.length() < 0.001:
		dir = Vector3.UP

	if end_a_fixed and end_b_fixed:
		print("Spring3D: Both ends fixed. Cannot snap to rest length.")
		return

	if not end_a_fixed and not end_b_fixed:
		var center := (point_a + point_b) * 0.5
		point_a = center - dir * rest_length * 0.5
		point_b = center + dir * rest_length * 0.5
	elif end_a_fixed:
		point_b = point_a + dir * rest_length
	else: # end_b_fixed
		point_a = point_b - dir * rest_length

	_pos_a = global_transform * point_a
	_pos_b = global_transform * point_b
	_dirty = true
	update_gizmos()

#endregion

#region ── Physics ─────────────────────────────────────────────────────────────

func _reset_state() -> void:
	_pos_a = global_transform * point_a
	_pos_b = global_transform * point_b
	_vel_a = Vector3.ZERO
	_vel_b = Vector3.ZERO
	_dirty = true

func _update_fixed_endpoints() -> void:
	if end_a_fixed:
		_pos_a = global_transform * point_a
		_vel_a = Vector3.ZERO
	if end_b_fixed:
		_pos_b = global_transform * point_b
		_vel_b = Vector3.ZERO

func _step_physics(dt: float) -> void:
	var steps := maxi(1, ceili(spring_constant * dt / 20.0))
	var sub_dt := dt / float(steps)
	for _i in steps:
		_integrate(sub_dt)

func _integrate(dt: float) -> void:
	var sep := _pos_b - _pos_a
	var dist := sep.length()
	if dist < 0.0001:
		return
	var dir := sep / dist
	var ext := dist - rest_length

	# Apply elastic limit: clamp the extension used for force calculation
	if elastic_limit > 0.0:
		ext = clampf(ext, -elastic_limit, elastic_limit)

	var spring_force := spring_constant * ext * dir
	var rel_vel_along := (_vel_b - _vel_a).dot(dir)
	var damp_force := damping * rel_vel_along * dir
	var f_axis := spring_force + damp_force

	var grav := gravity_direction * gravity

	if not end_a_fixed:
		var acc_a := (f_axis + grav) / mass
		_vel_a += acc_a * dt
		var transverse_a := _vel_a - _vel_a.dot(dir) * dir
		_vel_a -= transverse_a * clampf(angular_damping * dt, 0.0, 1.0)
		if max_velocity > 0.0:
			_vel_a = _vel_a.limit_length(max_velocity)
		_pos_a += _vel_a * dt

	if not end_b_fixed:
		var acc_b := (-f_axis + grav) / mass
		_vel_b += acc_b * dt
		var transverse_b := _vel_b - _vel_b.dot(dir) * dir
		_vel_b -= transverse_b * clampf(angular_damping * dt, 0.0, 1.0)
		if max_velocity > 0.0:
			_vel_b = _vel_b.limit_length(max_velocity)
		_pos_b += _vel_b * dt

func _push_to_child_nodes() -> void:
	if not end_a_fixed and not end_a_node.is_empty():
		var node := get_node_or_null(end_a_node) as Node3D
		if node:
			node.global_position = _pos_a
	if not end_b_fixed and not end_b_node.is_empty():
		var node := get_node_or_null(end_b_node) as Node3D
		if node:
			node.global_position = _pos_b

#endregion

#region ── Mesh Generation (Full Build Once) ───────────────────────────────────

func _rebuild_mesh_full() -> void:
	var local_a := global_transform.affine_inverse() * _pos_a
	var local_b := global_transform.affine_inverse() * _pos_b
	var length := local_a.distance_to(local_b)
	if length < 0.0001:
		return

	var pts: Array[Vector3] = _build_helix_points(local_a, local_b)
	var n := pts.size()
	if n < 2:
		return

	var frames: Array[Vector3] = _build_transport_frames(pts)

	_vertex_count = n * radial_segments
	_base_positions.resize(_vertex_count)
	_normals.resize(_vertex_count)
	_uvs.resize(_vertex_count)

	var idx := 0
	for i: int in n:
		var center: Vector3 = pts[i]
		var tangent: Vector3
		if i == 0:
			tangent = (pts[1] - pts[0]).normalized()
		elif i == n - 1:
			tangent = (pts[-1] - pts[-2]).normalized()
		else:
			tangent = (pts[i + 1] - pts[i - 1]).normalized()

		var right: Vector3 = frames[i]
		var up: Vector3 = tangent.cross(right).normalized()

		for j: int in radial_segments:
			var angle: float = float(j) / radial_segments * TAU
			var offset: Vector3 = (right * cos(angle) + up * sin(angle)) * wire_thickness
			_base_positions[idx] = center + offset
			_normals[idx] = offset.normalized()
			_uvs[idx] = Vector2(float(i) / (n - 1), float(j) / radial_segments)
			idx += 1

	var verts_per_ring := radial_segments
	_indices.resize((n - 1) * radial_segments * 6)
	var i_idx := 0
	for i: int in n - 1:
		for j: int in radial_segments:
			var curr0: int = i * verts_per_ring + j
			var curr1: int = i * verts_per_ring + (j + 1) % verts_per_ring
			var next0: int = (i + 1) * verts_per_ring + j
			var next1: int = (i + 1) * verts_per_ring + (j + 1) % verts_per_ring

			_indices[i_idx] = curr0; i_idx += 1
			_indices[i_idx] = next0; i_idx += 1
			_indices[i_idx] = next1; i_idx += 1
			_indices[i_idx] = curr0; i_idx += 1
			_indices[i_idx] = next1; i_idx += 1
			_indices[i_idx] = curr1; i_idx += 1

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _base_positions
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_INDEX] = _indices

	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	_vertex_buffer = _base_positions.duplicate()

	_last_length = length
	_dirty = false

#endregion

#region ── Fast Vertex Update (Stretching) ─────────────────────────────────────

func _update_mesh_positions() -> void:
	var local_a := global_transform.affine_inverse() * _pos_a
	var local_b := global_transform.affine_inverse() * _pos_b
	var current_length := local_a.distance_to(local_b)
	if current_length < 0.0001:
		return

	if is_equal_approx(current_length, _last_length) and not _dirty:
		return

	@warning_ignore("integer_division")
	var n :int=int( _base_positions.size() / radial_segments)
	if n < 2:
		return

	var pts: Array[Vector3] = _build_helix_points(local_a, local_b)
	var frames: Array[Vector3] = _build_transport_frames(pts)

	var idx := 0
	for i: int in n:
		var center: Vector3 = pts[i]
		var tangent: Vector3
		if i == 0:
			tangent = (pts[1] - pts[0]).normalized()
		elif i == n - 1:
			tangent = (pts[-1] - pts[-2]).normalized()
		else:
			tangent = (pts[i + 1] - pts[i - 1]).normalized()

		var right: Vector3 = frames[i]
		var up: Vector3 = tangent.cross(right).normalized()

		for j: int in radial_segments:
			var angle: float = float(j) / radial_segments * TAU
			var offset: Vector3 = (right * cos(angle) + up * sin(angle)) * wire_thickness
			_vertex_buffer[idx] = center + offset
			idx += 1

	if _mesh.get_surface_count() > 0:
		_mesh.surface_update_vertex_region(0, 0, _vertex_buffer.to_byte_array())

	_last_length = current_length
	_dirty = false

#endregion

#region ── Helix Point Generation ──────────────────────────────────────────────

func _build_helix_points(local_a: Vector3, local_b: Vector3) -> Array[Vector3]:
	var axis := local_b - local_a
	var length := axis.length()
	var axis_dir := axis / length

	var up_ref := Vector3.UP if abs(axis_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var u := axis_dir.cross(up_ref).normalized()
	var v := axis_dir.cross(u).normalized()

	var coil_segs := coil_turns * segments_per_turn
	var cap_segs := end_cap_turns * segments_per_turn
	var all_segs := cap_segs + coil_segs + cap_segs

	_points.resize(all_segs + 1)
	for i: int in all_segs + 1:
		var t: float = float(i) / max(all_segs, 1)

		var r: float = coil_radius
		if cap_segs > 0:
			var cap_frac: float = float(cap_segs) / float(all_segs)
			if t < cap_frac:
				r = coil_radius * (t / cap_frac)
			elif t > 1.0 - cap_frac:
				r = coil_radius * ((1.0 - t) / cap_frac)

		var coil_t: float = t
		if cap_segs > 0:
			var cap_frac: float = float(cap_segs) / float(all_segs)
			coil_t = clampf((t - cap_frac) / (1.0 - 2.0 * cap_frac), 0.0, 1.0)

		var angle: float = coil_t * float(coil_turns) * TAU
		var radial: Vector3 = (u * cos(angle) + v * sin(angle)) * r
		_points[i] = local_a + axis_dir * (t * length) + radial

	return _points

func _build_transport_frames(pts: Array[Vector3]) -> Array[Vector3]:
	var n := pts.size()
	_frames.resize(n)

	var t0: Vector3 = (pts[1] - pts[0]).normalized()
	var _seed: Vector3 = Vector3.RIGHT if abs(t0.dot(Vector3.RIGHT)) < 0.99 else Vector3.UP
	_frames[0] = t0.cross(_seed).normalized()

	for i: int in range(1, n):
		var t_prev: Vector3 = (pts[i] - pts[i - 1]).normalized()
		var t_curr: Vector3
		if i < n - 1:
			t_curr = (pts[i + 1] - pts[i]).normalized()
		else:
			t_curr = t_prev

		var rot_axis: Vector3 = t_prev.cross(t_curr)
		if rot_axis.length() < 0.0001:
			_frames[i] = _frames[i - 1]
		else:
			var angle: float = t_prev.angle_to(t_curr)
			_frames[i] = _frames[i - 1].rotated(rot_axis.normalized(), angle)

	return _frames

#endregion

#region ── Static Factories ────────────────────────────────────────────────────

static func make_rigid(a: Vector3, b: Vector3) -> Spring3D:
	var s := Spring3D.new()
	s.point_a = a
	s.point_b = b
	s.spring_constant = 80.0
	s.damping = 5.0
	s.rest_length = a.distance_to(b)
	return s

static func make_soft(a: Vector3, b: Vector3) -> Spring3D:
	var s := Spring3D.new()
	s.point_a = a
	s.point_b = b
	s.spring_constant = 8.0
	s.damping = 0.5
	s.rest_length = a.distance_to(b)
	return s

static func make_critical(a: Vector3, b: Vector3, k: float = 20.0) -> Spring3D:
	var s := Spring3D.new()
	s.point_a = a
	s.point_b = b
	s.spring_constant = k
	s.mass = 1.0
	s.damping = 2.0 * sqrt(k * s.mass)
	s.rest_length = a.distance_to(b)
	return s

#endregion
