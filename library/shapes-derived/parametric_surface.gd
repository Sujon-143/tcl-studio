@tool
extends BaseNode3D
class_name ParametricSurface

## Generates a 3D parametric surface using a callable f(x, z) → y.
## Supports draw_progress to animate the surface appearing from one side.
## Uses ArrayMesh (not ImmediateMesh) because the surface can have thousands
## of vertices — ArrayMesh hands them to the GPU in one batch rather than
## one-at-a-time, which is far more efficient for dense meshes.
##
## The GridPlane integration uses local_to_global() / x_range / y_range from
## the updated GridPlane API, so there is no dependency on the old `size` property.

#region Configuration — Surface

@export_group("Surface")

@export var color: Color = Color(1.0, 1.0, 1.0, 1.0) :
	set(value):
		color = value
		if _ready_done: rebuild_mesh()

## If true, color is mapped to vertex height (dark at low, bright at high).
@export var color_map_enabled: bool = false :
	set(value):
		color_map_enabled = value
		if _ready_done: rebuild_mesh()

## Y range used for color mapping. When both components are 0 the range is
## computed automatically from the actual vertex heights each rebuild.
@export var color_range: Vector2 = Vector2.ZERO :
	set(value):
		color_range = value
		if _ready_done: rebuild_mesh()

#endregion

#region Configuration — Grid / Bounds

@export_group("Grid / Bounds")

## When true, size and divisions are taken from the assigned GridPlane's
## x_range, y_range, and divisions. The surface transform also tracks the grid.
@export var use_grid_dimensions: bool = false :
	set(value):
		use_grid_dimensions = value
		if _ready_done: rebuild_mesh()

## Full width of the surface along X and Z (ignored when use_grid_dimensions = true).
@export var size: Vector2 = Vector2(10.0, 10.0) :
	set(value):
		size = value
		if _ready_done: rebuild_mesh()

## Number of quads along X and Z (ignored when use_grid_dimensions = true).
@export var divisions: Vector2i = Vector2i(50, 50) :
	set(value):
		divisions = Vector2i(max(1, value.x), max(1, value.y))
		if _ready_done: rebuild_mesh()

#endregion

#region Configuration — Reveal

@export_group("Reveal")

## Axis along which the reveal wavefront travels. "x" = left→right, "z" = front→back.
@export_enum("x", "z") var reveal_axis: String = "x" :
	set(value):
		reveal_axis = value
		if _ready_done: rebuild_mesh()

@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0 :
	set(value):
		draw_progress = clamp(value, 0.0, 1.0)
		if _ready_done: rebuild_mesh()

#endregion

#region Private

## Optional GridPlane reference. Set via set_grid().
var grid: GridPlane = null

## Callable f(x: float, z: float) → float. Set via set_height_function().
var height_func: Callable = func(_x: float, _z: float) -> float: return 0.0

var _mesh: ArrayMesh
var _mat: StandardMaterial3D
var _mesh_instance: MeshInstance3D

var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(p_grid: GridPlane = null) -> ParametricSurface:
	var s      := ParametricSurface.new()
	s.grid      = p_grid
	s.color     = Color(0.3, 0.7, 1.0, 0.85)
	return s

static func get_flat_colored(p_grid: GridPlane, col: Color) -> ParametricSurface:
	var s              := ParametricSurface.new()
	s.grid              = p_grid
	s.color             = col
	s.color_map_enabled = false
	return s

static func get_height_mapped(p_grid: GridPlane,
							  min_col: Color = Color.BLUE,
							  max_col: Color = Color.RED) -> ParametricSurface:
	var s                  := ParametricSurface.new()
	s.grid                  = p_grid
	s.color                 = max_col
	s.color_map_enabled     = true
	return s

#endregion

#region Lifecycle

func _init(p_grid: GridPlane = null,
		   p_func: Callable = func(_x: float, _z: float) -> float: return 0.0,
		   p_size: Vector2 = Vector2(10.0, 10.0),
		   p_div:  Vector2i = Vector2i(50, 50)) -> void:
	grid        = p_grid
	height_func = p_func
	size        = p_size
	divisions   = p_div
	_mesh       = ArrayMesh.new()

func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED

	_mesh_instance                   = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat
	add_child(_mesh_instance)

	_ready_done = true

	# Sync transform with grid if assigned.
	if is_instance_valid(grid):
		global_transform = grid.global_transform

	rebuild_mesh()

func _exit_tree() -> void:
	_ready_done = false

	if is_instance_valid(_mesh_instance):
		_mesh_instance.mesh = null
		_mesh_instance.queue_free()
		_mesh_instance = null

	if _mesh is ArrayMesh:
		_mesh.clear_surfaces()
		_mesh = null

	_mat = null

#endregion

#region Public API

## Required for compatibility with ProcAnim.create_object.
func draw() -> void:
	rebuild_mesh()

func set_color(new_color: Color) -> void:
	color = new_color
	rebuild_mesh()

func set_flat_color(new_color: Color) -> void:
	color             = new_color
	color_map_enabled = false
	rebuild_mesh()

func set_color_map_enabled(enabled: bool) -> void:
	color_map_enabled = enabled
	rebuild_mesh()

func set_color_range(min_y: float, max_y: float) -> void:
	color_range = Vector2(min_y, max_y)
	rebuild_mesh()

func set_divisions(div_x: int, div_z: int) -> void:
	if not use_grid_dimensions:
		divisions = Vector2i(max(1, div_x), max(1, div_z))
		rebuild_mesh()

func set_resolution(div_x: int, div_z: int) -> void:
	set_divisions(div_x, div_z)

func set_size(new_size: Vector2) -> void:
	if not use_grid_dimensions:
		size = new_size
		rebuild_mesh()

func set_reveal_axis(axis: String) -> void:
	assert(axis in ["x", "z"], "reveal_axis must be 'x' or 'z'")
	reveal_axis = axis
	rebuild_mesh()

func set_height_function(new_func: Callable) -> void:
	height_func = new_func
	rebuild_mesh()

## Assigns a GridPlane. When sync_dimensions = true the surface bounds and
## divisions are overwritten with the grid's current values, and the surface
## transform is locked to the grid transform.
func set_grid(new_grid: GridPlane, sync_dimensions: bool = false) -> void:
	grid = new_grid
	if is_instance_valid(grid):
		if sync_dimensions:
			_sync_dimensions_from_grid()
		global_transform = grid.global_transform
	rebuild_mesh()

func set_use_grid_dimensions(enabled: bool) -> void:
	use_grid_dimensions = enabled
	if enabled and is_instance_valid(grid):
		_sync_dimensions_from_grid()
	rebuild_mesh()

#endregion

#region Dimension sync

## Reads x_range, y_range, and divisions from the GridPlane and overwrites
## the local size / divisions to match. Called when use_grid_dimensions = true.
func _sync_dimensions_from_grid() -> void:
	if not is_instance_valid(grid):
		return
	var xr := grid.x_range
	var yr = grid.y_range
	var s  := grid.scale_to_world_space
	# Convert logical grid units to world metres (same as GridPlane.draw() does).
	size      = Vector2((xr.y - xr.x) * s, (yr.y - yr.x) * s)
	divisions = Vector2i(grid.divisions, grid.divisions)

#endregion

#region Mesh building

func rebuild_mesh() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	if draw_progress <= 0.0:
		return

	# ── Resolve working size and division counts ─────────────────────────────
	var work_size := size
	var div_x     := divisions.x
	var div_z     := divisions.y

	if use_grid_dimensions and is_instance_valid(grid):
		_sync_dimensions_from_grid()
		work_size = size
		div_x     = divisions.x
		div_z     = divisions.y
		global_transform = grid.global_transform

	div_x = max(1, div_x)
	div_z = max(1, div_z)

	var step_x: float = work_size.x / div_x
	var step_z: float = work_size.y / div_z
	var half_x: float = work_size.x * 0.5
	var half_z: float = work_size.y * 0.5

	# ── Sample vertex heights ────────────────────────────────────────────────
	var vertices: Array[Vector3] = []
	var heights:  Array[float]   = []
	var y_min: float =  INF
	var y_max: float = -INF

	for ix in range(div_x + 1):
		var x: float = -half_x + ix * step_x
		for iz in range(div_z + 1):
			var z: float = -half_z + iz * step_z
			var y: float = height_func.call(x, z)
			vertices.append(Vector3(x, y, z))
			heights.append(y)
			y_min = min(y_min, y)
			y_max = max(y_max, y)

	# ── Build triangle index list ────────────────────────────────────────────
	var quads: Array[PackedInt32Array] = []
	for ix in range(div_x):
		for iz in range(div_z):
			var i00: int = ix       * (div_z + 1) + iz
			var i01: int = ix       * (div_z + 1) + iz + 1
			var i10: int = (ix + 1) * (div_z + 1) + iz
			var i11: int = (ix + 1) * (div_z + 1) + iz + 1
			quads.append(PackedInt32Array([i00, i10, i11]))
			quads.append(PackedInt32Array([i00, i11, i01]))

	# ── Sort triangles for the reveal wavefront ──────────────────────────────
	var order := range(quads.size())
	if reveal_axis == "x":
		order.sort_custom(func(a: int, b: int) -> bool:
			var xa := (vertices[quads[a][0]].x + vertices[quads[a][1]].x + vertices[quads[a][2]].x) / 3.0
			var xb := (vertices[quads[b][0]].x + vertices[quads[b][1]].x + vertices[quads[b][2]].x) / 3.0
			return xa < xb)
	else:
		order.sort_custom(func(a: int, b: int) -> bool:
			var za := (vertices[quads[a][0]].z + vertices[quads[a][1]].z + vertices[quads[a][2]].z) / 3.0
			var zb := (vertices[quads[b][0]].z + vertices[quads[b][1]].z + vertices[quads[b][2]].z) / 3.0
			return za < zb)

	# ── Collect visible triangle indices ─────────────────────────────────────
	var triangles_to_draw: int = int(quads.size() * draw_progress)
	var visible_indices := PackedInt32Array()
	for i in range(triangles_to_draw):
		visible_indices.append_array(quads[order[i]])

	if visible_indices.is_empty():
		return

	# ── Build vertex color array ─────────────────────────────────────────────
	var min_y := color_range.x if color_range.x != color_range.y else y_min
	var max_y := color_range.y if color_range.x != color_range.y else y_max

	var vertex_colors := PackedColorArray()
	for i in range(vertices.size()):
		var c: Color
		if color_map_enabled and max_y > min_y:
			var t: float = (heights[i] - min_y) / (max_y - min_y)
			c = Color(color.r * t, color.g * t, color.b * t, color.a)
		else:
			c = color
		vertex_colors.append(c)

	# ── Upload to GPU ─────────────────────────────────────────────────────────
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_COLOR]  = vertex_colors
	arrays[Mesh.ARRAY_INDEX]  = visible_indices
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

#endregion
