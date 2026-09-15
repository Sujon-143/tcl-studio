@tool
extends BaseNode3D
class_name AnimatableSpring3D

@export var end_a_node : NodePath
@export var end_b_node : NodePath

@export var point_a := Vector3(0.0, 0.0, 0.0) :
	set(v): point_a = v; _rebuild = true
@export var point_b := Vector3(0.0, -2.0, 0.0) :
	set(v): point_b = v; _rebuild = true

@export_group("Spring")
@export var natural_length := 2.0 :
	set(v): natural_length = v; _rebuild = true
@export var initial_displacement := 1.0 :
	set(v): initial_displacement = v; _rebuild = true
@export var initial_velocity := 0.0 :
	set(v): initial_velocity = v; _rebuild = true
@export var spring_constant := 20.0 :
	set(v): spring_constant = max(0.01, v); _update_osc(); _rebuild = true
@export var damping := 2.0 :
	set(v): damping = max(0.0, v); _update_osc(); _rebuild = true
@export var mass := 1.0 :
	set(v): mass = max(0.001, v); _update_osc(); _rebuild = true

## Animate this
@export var animation_time := 0.0 :
	set(v): animation_time = max(0.0, v); _rebuild = true

@export_group("Mesh")
@export_range(1, 64) var coil_turns := 8 :
	set(v): coil_turns = v; _rebuild = true
@export_range(3, 64) var segments_per_turn := 12 :
	set(v): segments_per_turn = v; _rebuild = true
@export_range(0.001, 2.0, 0.001) var coil_radius := 0.15 :
	set(v): coil_radius = v; _rebuild = true
@export_range(0.001, 0.5, 0.001) var wire_thickness := 0.02 :
	set(v): wire_thickness = v; _rebuild = true
@export_range(3, 16) var radial_segments := 8 :
	set(v): radial_segments = v; _rebuild = true
@export var color := Color(0.82, 0.82, 0.86) :
	set(v): color = v; if _mat: _mat.albedo_color = v

# --- private ---
var _mesh : ArrayMesh
var _mat  : StandardMaterial3D
var _mi   : MeshInstance3D
var _rebuild := true
var is_ready   := false

# oscillator cache
var _omega0 := 0.0
var _zeta   := 0.0
var _omegad := 0.0
var _r1     := 0.0
var _r2     := 0.0
var _under  := true
var _settle := 5.0

func _ready() -> void:
	_mesh = ArrayMesh.new()
	_mat  = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	_mat.albedo_color               = color
	_mi       = MeshInstance3D.new()
	_mi.mesh  = _mesh
	_mi.material_override = _mat
	add_child(_mi)
	is_ready = true
	_update_osc()
	_rebuild = true

func _process(_dt: float) -> void:
	if not _ready: return
	if _rebuild:
		_do_rebuild()
		_rebuild = false

func _update_osc() -> void:
	_omega0 = sqrt(spring_constant / mass)
	_zeta   = damping / (2.0 * mass * _omega0)
	_under  = _zeta < 1.0
	if _under:
		_omegad = _omega0 * sqrt(1.0 - _zeta * _zeta)
		_settle = 4.6 / max(_zeta * _omega0, 0.0001)
	else:
		var sq  := sqrt(max(_zeta * _zeta - 1.0, 0.0))
		_r1 = -_zeta * _omega0 + _omega0 * sq
		_r2 = -_zeta * _omega0 - _omega0 * sq
		_settle = 5.0 / max(_omega0, 0.0001)
	_settle = clamp(_settle, 0.1, 60.0)

## Displacement from equilibrium at time t. Positive = stretched beyond natural.
func displacement_at(t: float) -> float:
	if t <= 0.0: return initial_displacement
	if _under:
		var A := initial_displacement
		var B = (initial_velocity + _zeta * _omega0 * initial_displacement) / max(_omegad, 0.0001)
		return exp(-_zeta * _omega0 * t) * (A * cos(_omegad * t) + B * sin(_omegad * t))
	elif abs(_zeta - 1.0) < 0.001:
		var A := initial_displacement
		var B := initial_velocity + _omega0 * initial_displacement
		return (A + B * t) * exp(-_omega0 * t)
	else:
		var d  := _r1 - _r2
		var A  := (initial_velocity - _r2 * initial_displacement) / d
		var B  := initial_displacement - A
		return A * exp(_r1 * t) + B * exp(_r2 * t)

func _get_a() -> Vector3:
	if not end_a_node.is_empty():
		var n := get_node_or_null(end_a_node) as Node3D
		if n: return n.global_position
	return global_transform * point_a

func _get_b_simulated() -> Vector3:
	## The actual spring-simulated position of end B in world space.
	var a    := _get_a()
	# Axis direction: from point_a toward point_b in local space, into world.
	var ldir := point_b - point_a
	if ldir.length_squared() < 0.0001: ldir = Vector3(0, -1, 0)
	var axis := (global_transform.basis * ldir).normalized()
	var current_length := natural_length + displacement_at(animation_time)
	return a + axis * current_length

func _do_rebuild() -> void:
	# 1. Compute where B should be right now
	var b_world := _get_b_simulated()

	# 2. Move node B there (no matter what kind of Node3D it is)
	if not end_b_node.is_empty():
		var nb := get_node_or_null(end_b_node) as Node3D
		if nb:
			nb.global_position = b_world

	# 3. Build mesh from A to simulated B
	var a_world := _get_a()
	var la := global_transform.affine_inverse() * a_world
	var lb := global_transform.affine_inverse() * b_world

	if la.distance_to(lb) < 0.0001: return

	_bake_mesh(la, lb)

func _bake_mesh(la: Vector3, lb: Vector3) -> void:
	var axis   := lb - la
	var length := axis.length()
	var adir   := axis / length

	var uref := Vector3.UP if abs(adir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var u    := adir.cross(uref).normalized()
	var v    := adir.cross(u).normalized()

	var total_segs := coil_turns * segments_per_turn
	var n          := total_segs + 1

	# Build spine
	var spine : Array[Vector3] = []
	spine.resize(n)
	for i in n:
		var t     := float(i) / float(total_segs)
		var angle := t * coil_turns * TAU
		spine[i]  = la + adir * (t * length) + (u * cos(angle) + v * sin(angle)) * coil_radius

	# Transport frames
	var frames : Array[Vector3] = []
	frames.resize(n)
	var t0   := (spine[1] - spine[0]).normalized()
	var seed := Vector3.RIGHT if abs(t0.dot(Vector3.RIGHT)) < 0.99 else Vector3.UP
	frames[0] = t0.cross(seed).normalized()
	for i in range(1, n):
		var tp := (spine[i] - spine[i-1]).normalized()
		var tc := tp if i >= n-1 else (spine[i+1] - spine[i]).normalized()
		var ax := tp.cross(tc)
		if ax.length_squared() < 1e-8: frames[i] = frames[i-1]
		else: frames[i] = frames[i-1].rotated(ax.normalized(), tp.angle_to(tc))

	# Vertices
	var vc   := n * radial_segments
	var verts := PackedVector3Array(); verts.resize(vc)
	var norms := PackedVector3Array(); norms.resize(vc)
	var uvs   := PackedVector2Array(); uvs.resize(vc)
	var idx   := 0
	for i in n:
		var tang := Vector3.ZERO
		if i == 0:       tang = (spine[1]-spine[0]).normalized()
		elif i == n-1:   tang = (spine[n-1]-spine[n-2]).normalized()
		else:            tang = (spine[i+1]-spine[i-1]).normalized()
		var right := frames[i]
		var up    := tang.cross(right).normalized()
		for j in radial_segments:
			var a2  := float(j) / radial_segments * TAU
			var off := (right * cos(a2) + up * sin(a2)) * wire_thickness
			verts[idx] = spine[i] + off
			norms[idx] = off.normalized()
			uvs[idx]   = Vector2(float(i)/(n-1), float(j)/radial_segments)
			idx += 1

	# Indices
	var icount := (n-1) * radial_segments * 6
	var inds   := PackedInt32Array(); inds.resize(icount)
	var ii     := 0
	for i in n-1:
		for j in radial_segments:
			var c0 := i*radial_segments + j
			var c1 := i*radial_segments + (j+1)%radial_segments
			var n0 := (i+1)*radial_segments + j
			var n1 := (i+1)*radial_segments + (j+1)%radial_segments
			inds[ii]=c0;ii+=1; inds[ii]=n0;ii+=1; inds[ii]=n1;ii+=1
			inds[ii]=c0;ii+=1; inds[ii]=n1;ii+=1; inds[ii]=c1;ii+=1

	var arrays := []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX]  = inds
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
