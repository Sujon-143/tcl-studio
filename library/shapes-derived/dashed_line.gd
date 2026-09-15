@tool
extends BaseNode3D
class_name DashedLine

## A 3D polyline rendered as a tube, with solid or dashed modes,
## animated draw progress, and an optional treadmill effect that
## scrolls the dash pattern along the fixed points.

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

@export var glow:bool=false:
	set(value):
		glow=value
		_mat_front.emission_enabled=true
		if _ready_done:draw()
@export var glow_color:Color= Color.YELLOW:
	set(value):
		glow_color= value
		_mat_front.emission= glow_color
		if _ready_done:draw()
@export var glow_energy:float=1.0:
	set(value):
		glow_energy= value
		_mat_front.emission_intensity= glow_energy
		if _ready_done:draw()

@export_range(0.001, 5.0, 0.001) var thickness: float = 0.05 :
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

## If true, draws a continuous solid line (ignores dash_length / gap_length).
@export var solid: bool = false :
	set(value):
		solid = value
		if _ready_done: draw()

@export_range(0.001, 5.0, 0.001) var dash_length: float = 0.2 :
	set(value):
		dash_length = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001,5.0, 0.001) var gap_length: float = 0.1 :
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
var _mat_front: StandardMaterial3D
var _mat_back: StandardMaterial3D
var _mesh_instance: MeshInstance3D
var _mesh_instance_back: MeshInstance3D

# Guards setters from calling draw() before _ready() has run.
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(is_solid: bool = false) -> DashedLine:
	var dl := DashedLine.new([Vector3.ZERO, Vector3.FORWARD])
	dl.thickness = 0.01
	dl.color     = Color.RED
	dl.solid     = is_solid
	dl.set_dash_ratio(0.7)
	return dl

static func get_treadmill(p_points: Array[Vector3], speed: float = 1.0) -> DashedLine:
	var dl := DashedLine.new(p_points)
	dl.treadmill       = true
	dl.treadmill_speed = speed
	return dl

static func get_treadmill_reverse(p_points: Array[Vector3], speed: float = 1.0) -> DashedLine:
	var dl := DashedLine.new(p_points)
	dl.treadmill         = true
	dl.treadmill_speed   = speed
	dl.treadmill_reverse = true
	return dl

#endregion

#region Lifecycle

func _init(p_points: Array[Vector3] = []) -> void:
	points = p_points
	_mesh  = ImmediateMesh.new()

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


func _process(delta: float) -> void:
	if not treadmill or solid:
		return
	# Advance and wrap the offset so it stays within one pattern period,
	# keeping the floating-point value small regardless of run duration.
	# treadmill_reverse flips the sign so the pattern scrolls the other way.
	var pattern  := dash_length + gap_length
	var sign     := -1.0 if treadmill_reverse else 1.0
	treadmill_offset = fmod(treadmill_offset + sign * treadmill_speed * delta, pattern)
	draw()

#endregion

#region Public API

func set_points(p_points: Array[Vector3]) -> void:
	points = p_points
	draw()

func add_point(p_point:Vector3)->void:
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

func set_tube_segments(segs: int) -> void:
	tube_segments = max(3, segs)
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

	var samples          := _build_samples()
	var total_length: float = samples[-1][1]
	if total_length <= 0.0 or draw_progress <= 0.0:
		return

	var limit := total_length * draw_progress

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(color)

	if solid:
		_draw_solid(samples, limit)
	elif treadmill:
		_draw_treadmill(samples, limit, total_length)
	else:
		_draw_dashed(samples, limit)

	_mesh.surface_end()

func _draw_solid(samples: Array, limit: float) -> void:
	for i in range(points.size() - 1):
		var seg_start: float = samples[i][1]
		var seg_end: float   = samples[i + 1][1]
		if seg_start >= limit:
			break
		var from_pos := _sample_at(samples, seg_start)
		var to_pos   := _sample_at(samples, min(seg_end, limit))
		_draw_tube_segment(from_pos, to_pos)

func _draw_dashed(samples: Array, limit: float) -> void:
	var pattern := dash_length + gap_length
	var dist    := 0.0
	while dist < limit:
		var dash_end: float = min(dist + dash_length, limit)
		# caps=false: flat end-cap discs make short dash segments look like
		# bottles/arrows. The open tube reads cleanly as a dashed line.
		_draw_segment_between(samples, dist, dash_end, false)
		dist += pattern

func _draw_treadmill(samples: Array, limit: float, _total_length: float) -> void:
	# The offset shifts where dashes start along the line. We begin drawing
	# from a negative start so dashes that are partially scrolled onto the
	# line from the beginning are visible.
	var pattern := dash_length + gap_length

	# Phase within one pattern period (always positive after fmod + abs guard).
	# fmod can return negative values when treadmill_offset goes negative
	# (reverse mode), so we normalise into [0, pattern).
	var phase := fmod(treadmill_offset, pattern)
	if phase < 0.0:
		phase += pattern

	# First dash may start before 0 so it enters the line from the start end.
	var dist := -phase
	while dist < limit:
		var dash_start := dist
		var dash_end   := dist + dash_length
		var draw_start: float = max(dash_start, 0.0)
		var draw_end:   float = min(dash_end,   limit)
		if draw_end > draw_start:
			_draw_segment_between(samples, draw_start, draw_end, false)
		dist += pattern

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

## Returns the point on the polyline at the given distance from the start.
func _sample_at(samples: Array, dist: float) -> Vector3:
	for i in range(1, samples.size()):
		var d0: float = samples[i - 1][1]
		var d1: float = samples[i][1]
		if dist <= d1:
			var t: float = (dist - d0) / max(d1 - d0, 0.0001)
			return samples[i - 1][0].lerp(samples[i][0], t)
	return samples[-1][0]

## Straight tube between two world-space points.
func _draw_tube_segment(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	var forward := dir.normalized()
	var steps: float = max(2, int(dir.length() / thickness) + 2)
	var rings: Array = []
	for s in range(steps + 1):
		rings.append(_build_ring(from.lerp(to, float(s) / steps), forward))
	_connect_rings(rings, true)

## Curved tube by sampling the polyline between two arc-length distances.
func _draw_segment_between(samples: Array, from_dist: float, to_dist: float, caps: bool) -> void:
	var steps: float = max(2, int((to_dist - from_dist) / thickness) + 2)
	var rings: Array = []
	var last_forward := Vector3.FORWARD

	for s in range(steps + 1):
		var t := float(s) / steps
		var d: float = lerp(from_dist, to_dist, t)
		var p := _sample_at(samples, d)

		var forward: Vector3
		if s < steps:
			var d_next: float = lerp(from_dist, to_dist, float(s + 1) / steps)
			var delta  := _sample_at(samples, d_next) - p
			if delta.length() > 0.0001:
				forward      = delta.normalized()
				last_forward = forward
			else:
				forward = last_forward
		else:
			forward = last_forward

		rings.append(_build_ring(p, forward))
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
