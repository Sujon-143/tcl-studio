@tool
extends BaseNode3D
class_name GridPlane

## A 3D grid plane lying in Godot's XZ plane (Y = 0 by default).
## Drawn as cylindrical tubes.
##
## Coordinate model
## ────────────────
## The grid has its own logical 2D coordinate system ("grid space") that maps
## directly onto Godot world axes with no remapping:
##
##   gx  →  world X  (right,         controlled by x_range)
##   gz  →  world Z  (toward viewer, controlled by z_range)
##   gy  →  world Y  (up,            the optional lift-off-plane argument)
##
## The grid therefore lies in the XZ plane (world Y = 0), which is Godot's
## natural ground/floor plane.
##
## scale_to_world_space maps one logical grid unit onto world metres.
## At 1.0 each grid step equals one world metre; at 0.5 it equals half a metre.
##
## local_to_global(gx, gz, gy) converts a point expressed in logical grid units
## into world space, applying scale_to_world_space and the node's own transform.
##
## draw_progress animates the grid growing from its centre outward by radius.

#region Configuration — Grid

@export_group("Grid")

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: draw()

## Logical range along the X axis (grid-space X → world X).
@export var x_range: Vector2 = Vector2(-5.0, 5.0) :
	set(value):
		x_range = value
		if _ready_done: draw()

## Logical range along the Z axis (grid-space Z → world Z).
@export var z_range: Vector2 = Vector2(-5.0, 5.0) :
	set(value):
		z_range = value
		if _ready_done: draw()

## How many division lines to draw along each axis.
@export_range(1, 200, 1) var divisions: int = 10 :
	set(value):
		divisions = max(1, value)
		if _ready_done: draw()

## How much one logical grid unit maps to in world metres.
## 1.0 = full match (1 unit = 1 m), 0.5 = half scale (2 units = 1 m).
@export_range(0.001, 10.0, 0.001) var scale_to_world_space: float = 1.0 :
	set(value):
		scale_to_world_space = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var line_thickness: float = 0.02 :
	set(value):
		line_thickness = value
		if _ready_done: draw()

@export_range(3, 32, 1) var tube_segments: int = 6 :
	set(value):
		tube_segments = max(3, value)
		if _ready_done: draw()

#endregion

#region Configuration — Axes

@export_group("Axes")

@export var show_axes: bool = true :
	set(value):
		show_axes = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var axis_thickness: float = 0.04 :
	set(value):
		axis_thickness = value
		if _ready_done: draw()

## When false, axis lines use a lightened version of color (single mesh, single material).
## When true, axis lines are drawn into a separate MeshInstance3D with their own
## material so they can have a fully independent color. Toggling this on creates
## the extra mesh and material; toggling off destroys them.
@export var axis_separate_color: bool = false :
	set(value):
		axis_separate_color = value
		if _ready_done:
			_rebuild_axis_mesh()
			draw()

@export var axis_color: Color = Color(1.0, 1.0, 0.3, 1.0) :
	set(value):
		axis_color = value
		if _ready_done: draw()

#endregion

#region Configuration — Draw Progress

@export_group("Draw Progress")

## How much of the grid is visible (0 = none, 1 = full).
## Lines are revealed by their distance from the grid's logical centre:
## a line is visible when its offset from centre is ≤ half_diagonal * draw_progress,
## where half_diagonal is half the diagonal of the world-space bounding rectangle.
@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0 :
	set(value):
		draw_progress = clamp(value, 0.0, 1.0)
		if _ready_done: draw()

#endregion

#region Private

# Grid lines mesh (all non-axis lines, plus axis lines when axis_separate_color = false)
var _mesh: ImmediateMesh
var _mat: StandardMaterial3D
var _mesh_instance: MeshInstance3D

# Axis-only mesh — allocated only when axis_separate_color = true
var _axis_mesh: ImmediateMesh
var _axis_mat: StandardMaterial3D
var _axis_mesh_instance: MeshInstance3D

var _ready_done: bool = false

#endregion

#region Static factories

static func get_default() -> GridPlane:
	var g := GridPlane.new()
	g.color = Color(1.0, 1.0, 1.0, 0.3)
	return g

static func get_xz() -> GridPlane:
	var g := GridPlane.new()
	g.color = Color(0.5, 0.5, 0.5, 0.4)
	return g

## Returns a GridPlane rotated to lie in the XY plane.
## Achieved by rotating the node -90° on X so local Z points up (world Y).
static func get_xy() -> GridPlane:
	var g := GridPlane.new()
	g.rotation.x = -PI / 2.0
	g.color      = Color(0.5, 0.5, 0.5, 0.4)
	return g

static func get_colored_axes(grid_col: Color, ax_col: Color) -> GridPlane:
	var g                := GridPlane.new()
	g.color               = grid_col
	g.axis_separate_color = true
	g.axis_color          = ax_col
	return g

## Creates a grid spanning a specific logical range at the given scale.
static func get_ranged(x_lo: float, x_hi: float,
					   z_lo: float, z_hi: float,
					   scale: float = 1.0) -> GridPlane:
	var g                := GridPlane.new()
	g.x_range             = Vector2(x_lo, x_hi)
	g.z_range             = Vector2(z_lo, z_hi)
	g.scale_to_world_space = scale
	return g

#endregion

#region Lifecycle

func _init() -> void:
	_mesh      = ImmediateMesh.new()
	_axis_mesh = ImmediateMesh.new()

func _ready() -> void:
	_mat = _make_material()

	_mesh_instance                   = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat
	add_child(_mesh_instance)

	if axis_separate_color:
		_rebuild_axis_mesh()

	_ready_done = true
	draw()

func _exit_tree() -> void:
	_ready_done = false

	if is_instance_valid(_mesh_instance):
		_mesh_instance.mesh = null
		_mesh_instance.queue_free()
		_mesh_instance = null

	_destroy_axis_mesh()

	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
		_mesh = null

	_mat = null

#endregion

#region Public API

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_x_range(r: Vector2) -> void:
	x_range = r
	draw()

func set_z_range(r: Vector2) -> void:
	z_range = r
	draw()

func set_divisions(new_divisions: int) -> void:
	divisions = max(1, new_divisions)
	draw()

func set_scale_to_world_space(s: float) -> void:
	scale_to_world_space = max(0.001, s)
	draw()

func set_line_thickness(t: float) -> void:
	line_thickness = t
	draw()

func set_axis_thickness(t: float) -> void:
	axis_thickness = t
	draw()

func set_show_axes(value: bool) -> void:
	show_axes = value
	draw()

func set_tube_segments(segs: int) -> void:
	tube_segments = max(3, segs)
	draw()

func set_axis_separate_color(value: bool) -> void:
	axis_separate_color = value
	_rebuild_axis_mesh()
	draw()

func set_axis_color(new_color: Color) -> void:
	axis_color = new_color
	draw()

func set_draw_progress(value: float) -> void:
	draw_progress = value
	draw()

## Converts a point in logical grid-space coordinates into world space.
##
## Parameters
##   gx — position along the X axis (grid-space X → world X, right)
##   gz — position along the Z axis (grid-space Z → world Z, toward viewer)
##   gy — height above the grid plane (→ world Y, up). Defaults to 0.0.
##
## scale_to_world_space is applied first, then the node's global transform.
##
## Examples (scale_to_world_space = 1.0, node at world origin, no rotation):
##   local_to_global(1.0, 0.0)        → Vector3(1, 0, 0)   — one step right
##   local_to_global(0.0, 2.0)        → Vector3(0, 0, 2)   — two steps into screen
##   local_to_global(1.0, 2.0, 0.5)  → Vector3(1, 0.5, 2) — lifted 0.5 m above grid
##
## Examples (scale_to_world_space = 0.5):
##   local_to_global(2.0, 0.0)        → Vector3(1, 0, 0)   — 2 units = 1 m
func local_to_global(gx: float=0.0, gy: float=0.0, gz: float = 0.0) -> Vector3:
	# Grid space maps directly to Godot local space:
	#   gx → local X, gz → local Z, gy → local Y (up)
	var local := Vector3(gx, gy, -gz) * scale_to_world_space
	return to_global(local)

#endregion

#region Axis mesh lifecycle

## Creates or destroys the secondary axis MeshInstance3D based on
## the axis_separate_color flag. Safe to call multiple times.
func _rebuild_axis_mesh() -> void:
	if axis_separate_color:
		if not is_instance_valid(_axis_mesh_instance):
			if not (_axis_mesh is ImmediateMesh):
				_axis_mesh = ImmediateMesh.new()
			_axis_mat = _make_material()

			_axis_mesh_instance                   = MeshInstance3D.new()
			_axis_mesh_instance.mesh              = _axis_mesh
			_axis_mesh_instance.material_override = _axis_mat
			add_child(_axis_mesh_instance)
	else:
		_destroy_axis_mesh()

func _destroy_axis_mesh() -> void:
	if is_instance_valid(_axis_mesh_instance):
		_axis_mesh_instance.mesh = null
		_axis_mesh_instance.queue_free()
		_axis_mesh_instance = null

	if _axis_mesh is ImmediateMesh:
		_axis_mesh.clear_surfaces()

	_axis_mat = null

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_mesh):
		return

	_mesh.clear_surfaces()
	if is_instance_valid(_axis_mesh):
		_axis_mesh.clear_surfaces()

	if draw_progress <= 0.0:
		return

	var s := scale_to_world_space

	# World-local extents (logical units × scale)
	var x_lo: float = x_range.x * s
	var x_hi: float = x_range.y * s
	var z_lo: float = z_range.x * s
	var z_hi: float = z_range.y * s

	# Logical centre of the bounding rectangle
	var cx: float = (x_lo + x_hi) * 0.5
	var cz: float = (z_lo + z_hi) * 0.5

	# Half-diagonal of the bounding rectangle — full-progress reveal radius
	var half_diag: float = Vector2(x_hi - x_lo, z_hi - z_lo).length() * 0.5
	var max_dist: float  = half_diag * draw_progress

	var x_step: float = (x_hi - x_lo) / divisions
	var z_step: float = (z_hi - z_lo) / divisions

	# ── Open surfaces ────────────────────────────────────────────────────────
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var axis_surface_open := false
	if axis_separate_color and is_instance_valid(_axis_mesh):
		_axis_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		axis_surface_open = true

	# ── Lines parallel to X axis (constant Z = z_lo + i * z_step) ───────────
	# These run left-right across the grid.
	for i in range(divisions + 1):
		var z: float    = z_lo + i * z_step
		var dist: float = abs(z - cz)
		if dist > max_dist:
			continue

		var is_x_axis: bool = abs(z) < z_step * 0.01
		if is_x_axis and show_axes:
			_emit_axis_line(
				Vector3(x_lo, 0.0, z), Vector3(x_hi, 0.0, z),
				axis_surface_open)
		else:
			_draw_tube_on(_mesh,
				Vector3(x_lo, 0.0, z), Vector3(x_hi, 0.0, z),
				line_thickness * 0.5, color)

	# ── Lines parallel to Z axis (constant X = x_lo + i * x_step) ───────────
	# These run front-back across the grid.
	for i in range(divisions + 1):
		var x: float    = x_lo + i * x_step
		var dist: float = abs(x - cx)
		if dist > max_dist:
			continue

		var is_z_axis: bool = abs(x) < x_step * 0.01
		if is_z_axis and show_axes:
			_emit_axis_line(
				Vector3(x, 0.0, z_lo), Vector3(x, 0.0, z_hi),
				axis_surface_open)
		else:
			_draw_tube_on(_mesh,
				Vector3(x, 0.0, z_lo), Vector3(x, 0.0, z_hi),
				line_thickness * 0.5, color)

	# ── Close surfaces ───────────────────────────────────────────────────────
	_mesh.surface_end()
	if axis_surface_open:
		_axis_mesh.surface_end()

## Emits a single axis line, routing to the axis mesh when axis_separate_color is on.
## Because ImmediateMesh only supports one open surface at a time, routing to
## _axis_mesh requires temporarily closing and re-opening the grid surface.
func _emit_axis_line(from: Vector3, to: Vector3, into_axis_mesh: bool) -> void:
	var radius: float = axis_thickness * 0.5
	if into_axis_mesh:
		_mesh.surface_end()
		_draw_tube_on(_axis_mesh, from, to, radius, axis_color)
		_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	else:
		_draw_tube_on(_mesh, from, to, radius, color.lightened(0.3))

#endregion

#region Geometry helpers

func _draw_tube_on(target: ImmediateMesh, from: Vector3, to: Vector3,
				   radius: float, tube_color: Color) -> void:
	var dir: Vector3 = to - from
	if dir.length() < 0.001 or radius <= 0.0:
		return
	var forward := dir.normalized()
	var r0      := _build_ring(from, forward, radius)
	var r1      := _build_ring(to,   forward, radius)

	target.surface_set_color(tube_color)

	# Side quads
	for j in range(tube_segments):
		var nj := (j + 1) % tube_segments
		_quad_on(target, r0[j], r0[nj], r1[nj], r1[j])

	# Front cap
	for j in range(tube_segments):
		var nj := (j + 1) % tube_segments
		_tri_on(target, from, r0[nj], r0[j])

	# Back cap
	for j in range(tube_segments):
		var nj := (j + 1) % tube_segments
		_tri_on(target, to, r1[j], r1[nj])

func _build_ring(center: Vector3, forward: Vector3, radius: float) -> Array[Vector3]:
	var up    := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.999 else Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up        = right.cross(forward).normalized()
	var ring: Array[Vector3] = []
	for j in range(tube_segments):
		var a   := TAU * j / tube_segments
		var off := (cos(a) * right + sin(a) * up) * radius
		ring.append(center + off)
	return ring

func _tri_on(target: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	target.surface_add_vertex(a)
	target.surface_add_vertex(b)
	target.surface_add_vertex(c)

func _quad_on(target: ImmediateMesh, a: Vector3, b: Vector3,
			  c: Vector3, d: Vector3) -> void:
	_tri_on(target, a, b, c)
	_tri_on(target, a, c, d)

func _make_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

#endregion
