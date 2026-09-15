@tool
extends BaseMeshInstance3D
class_name SolidCircle

## A circle (ring) rendered as a tube with solid or dashed modes
## and animated draw progress.
##
## Extends BaseMeshInstance3D (MeshInstance3D), so assign a
## StandardMaterial3D to this node's material_override in the Inspector
## and tween it freely. No material management here.

#region Configuration — Shape

@export_group("Circle")

@export var pos: Vector3 = Vector3.ZERO:
	set(value):
		pos = value
		if _ready_done: draw()

@export_range(0.01, 100.0, 0.001) var radius: float = 1.0:
	set(value):
		radius = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var thickness: float = 0.05:
	set(value):
		thickness = value
		if _ready_done: draw()

@export_range(3, 32, 1) var tube_segments: int = 6:
	set(value):
		tube_segments = max(3, value)
		if _ready_done: draw()

#endregion

#region Configuration — Solid / Dash

@export_group("Dash")

@export var solid: bool = true:
	set(value):
		solid = value
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var dash_length: float = 0.2:
	set(value):
		dash_length = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var gap_length: float = 0.1:
	set(value):
		gap_length = max(0.001, value)
		if _ready_done: draw()

#endregion

#region Configuration — Draw Progress

@export_group("Draw Progress")

@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0:
	set(value):
		draw_progress = clamp(value, 0.0, 1.0)
		if _ready_done: draw()

#endregion

#region Private

var _mesh: ImmediateMesh
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default() -> SolidCircle:
	return SolidCircle.new()

static func get_dashed(p_radius: float = 1.0) -> SolidCircle:
	var c := SolidCircle.new()
	c.radius      = p_radius
	c.solid       = false
	c.thickness   = 0.01
	c.dash_length = 0.21
	c.gap_length  = 0.09
	return c

static func get_solid(p_radius: float = 1.0) -> SolidCircle:
	var c := SolidCircle.new()
	c.radius = p_radius
	c.solid  = true
	return c

#endregion

#region Lifecycle

func _ready() -> void:
	_mesh = ImmediateMesh.new()
	mesh  = _mesh
	_ready_done = true
	draw()

func _exit_tree() -> void:
	_ready_done = false
	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
	mesh  = null
	_mesh = null

#endregion

#region Public API

func set_radius(new_radius: float) -> void:
	radius = new_radius

func set_thickness(new_thickness: float) -> void:
	thickness = new_thickness

func set_position_center(new_pos: Vector3) -> void:
	pos = new_pos

func set_solid(value: bool) -> void:
	solid = value

func set_dash_length(value: float) -> void:
	dash_length = max(0.001, value)

func set_gap_length(value: float) -> void:
	gap_length = max(0.001, value)

func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)

func set_tube_segments(segs: int) -> void:
	tube_segments = max(3, segs)

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
		var dash_end: float = min(dist + dash_length, limit)
		_draw_tube_arc(dist / circumference, dash_end / circumference, circumference, false)
		dist += pattern

#endregion

#region Geometry helpers

func _draw_tube_arc(t_start: float, t_end: float, circumference: float, caps: bool) -> void:
	var steps: int = max(2, int((t_end - t_start) * circumference / thickness) + 2)

	# A ring carries: position, outward normal, forward tangent, and uv.
	# We store them together so _connect_rings can emit all attributes.
	# Each entry: { v: Vector3, n: Vector3, t: Vector4, uv: Vector2 }
	var rings: Array = []

	for s in range(steps + 1):
		var t_frac : float = lerp(t_start, t_end, float(s) / steps)
		var t_next : float = lerp(t_start, t_end, min(float(s + 1) / steps, 1.0))
		var angle      : float = t_frac * TAU
		var angle_next : float = t_next * TAU

		var center  := pos + Vector3(cos(angle)      * radius, 0.0, sin(angle)      * radius)
		var next_pt := pos + Vector3(cos(angle_next) * radius, 0.0, sin(angle_next) * radius)

		var forward := (next_pt - center)
		if forward.length() < 0.0001:
			forward = Vector3.FORWARD
		forward = forward.normalized()

		rings.append(_build_ring(center, forward, float(s) / steps))

	_connect_rings(rings, caps)

## Returns an Array of Dicts, one per tube cross-section vertex.
## Keys: v (Vector3 pos), n (Vector3 normal), tg (Plane tangent), uv (Vector2).
func _build_ring(center: Vector3, forward: Vector3, u: float) -> Array:
	var up    := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up        = right.cross(forward).normalized()

	# Tangent = forward direction along the tube, w = 1.0 (handedness).
	# ImmediateMesh.surface_set_tangent() expects a Plane: xyz = direction, d = handedness.
	var tangent := Plane(forward.x, forward.y, forward.z, 1.0)

	var ring: Array = []
	for j in range(tube_segments):
		var a      := TAU * j / tube_segments
		var normal := (cos(a) * right + sin(a) * up)   # outward from tube centre
		var vert   := center + normal * thickness
		var uv     := Vector2(u, float(j) / tube_segments)
		ring.append({ "v": vert, "n": normal, "tg": tangent, "uv": uv })
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

	# End-cap discs — normal points along the tube axis (forward / backward).
	# For the first cap the normal faces backward (−forward of ring 1).
	# For the last cap it faces forward (forward of the last ring).
	var first: Array = rings[0]
	var last:  Array = rings[-1]

	# Reconstruct cap normals from tangent w component (always stored in tg).
	var first_fwd := Vector3(first[0]["tg"].normal.x, first[0]["tg"].normal.y, first[0]["tg"].normal.z)
	var last_fwd  := Vector3(last[0]["tg"].normal.x,  last[0]["tg"].normal.y,  last[0]["tg"].normal.z)

	var c0 := _ring_center_pos(first)
	for j in range(first.size()):
		_tri_cap(
			c0, first[(j + 1) % first.size()], first[j],
			-first_fwd,
			Plane(-first_fwd.x, -first_fwd.y, -first_fwd.z, 1.0)
		)

	var c1 := _ring_center_pos(last)
	for j in range(last.size()):
		_tri_cap(
			c1, last[j], last[(j + 1) % last.size()],
			last_fwd,
			Plane(last_fwd.x, last_fwd.y, last_fwd.z, 1.0)
		)

func _ring_center_pos(ring: Array) -> Vector3:
	var c := Vector3.ZERO
	for d in ring:
		c += d["v"]
	return c / ring.size()

# ── Emit helpers ──────────────────────────────────────────────────────────────

func _emit(d: Dictionary) -> void:
	_mesh.surface_set_normal(d["n"])
	_mesh.surface_set_tangent(d["tg"])
	_mesh.surface_set_uv(d["uv"])
	_mesh.surface_add_vertex(d["v"])

func _tri(a: Dictionary, b: Dictionary, c: Dictionary) -> void:
	_emit(a); _emit(b); _emit(c)

func _quad(a: Dictionary, b: Dictionary, c: Dictionary, d: Dictionary) -> void:
	_tri(a, b, c)
	_tri(a, c, d)

## Cap triangles share a flat normal / tangent across all three verts.
func _tri_cap(
		center: Vector3, a: Dictionary, b: Dictionary,
		cap_normal: Vector3, cap_tangent: Plane) -> void:
	# Center point
	_mesh.surface_set_normal(cap_normal)
	_mesh.surface_set_tangent(cap_tangent)
	_mesh.surface_set_uv(Vector2(0.5, 0.5))
	_mesh.surface_add_vertex(center)
	# Ring point A
	_mesh.surface_set_normal(cap_normal)
	_mesh.surface_set_tangent(cap_tangent)
	_mesh.surface_set_uv(a["uv"])
	_mesh.surface_add_vertex(a["v"])
	# Ring point B
	_mesh.surface_set_normal(cap_normal)
	_mesh.surface_set_tangent(cap_tangent)
	_mesh.surface_set_uv(b["uv"])
	_mesh.surface_add_vertex(b["v"])

#endregion
