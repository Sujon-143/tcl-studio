@tool
extends BaseNode3D
class_name Grid3D

# ============================================================
# Configuration – Grid
# ============================================================
@export_group("Grid")

@export var color: Color = Color.WHITE :
	set(v):
		color = v
		if _initialized: draw()

## Min and max values for each axis (local space, before scaling)
@export var x_range: Vector2 = Vector2(-5.0, 5.0) :
	set(v):
		x_range = v
		if _initialized:
			draw()
			_update_labels()

@export var y_range: Vector2 = Vector2(-5.0, 5.0) :
	set(v):
		y_range = v
		if _initialized:
			draw()
			_update_labels()

@export var z_range: Vector2 = Vector2(-5.0, 5.0) :
	set(v):
		z_range = v
		if _initialized:
			draw()
			_update_labels()

## Divisions for grid lines in the X direction (lines parallel to Z)
@export_range(1, 100, 1) var x_divisions: int = 10 :
	set(v):
		x_divisions = max(1, v)
		if _initialized:
			draw()
			_update_labels()

## Divisions for grid lines in the Z direction (lines parallel to X)
@export_range(1, 100, 1) var z_divisions: int = 10 :
	set(v):
		z_divisions = max(1, v)
		if _initialized:
			draw()
			_update_labels()

## Divisions along the Y axis (used for labels and optional vertical grid)
@export_range(1, 100, 1) var y_divisions: int = 10 :
	set(v):
		y_divisions = max(1, v)
		if _initialized:
			draw()
			_update_labels()

@export_range(0.001, 10.0, 0.001) var scale_to_world: float = 1.0 :
	set(v):
		scale_to_world = max(0.001, v)
		if _initialized:
			draw()
			_update_labels()

@export_range(0.001, 1.0, 0.001) var line_thickness: float = 0.02 :
	set(v):
		line_thickness = v
		if _initialized: draw()

# ============================================================
# Configuration – Axes
# ============================================================
@export_group("Axes")

@export var show_axes: bool = true :
	set(v):
		show_axes = v
		if _initialized: draw()

@export var show_y_axis: bool = true :
	set(v):
		show_y_axis = v
		if _initialized:
			draw()
			_update_labels()

@export_range(0.001, 1.0, 0.001) var axis_thickness: float = 0.04 :
	set(v):
		axis_thickness = v
		if _initialized: draw()

@export var axis_separate_color: bool = false :
	set(v):
		axis_separate_color = v
		if _initialized:
			_rebuild_axis_mesh()
			draw()
			_update_labels()

@export var axis_color: Color = Color(1.0, 1.0, 0.3, 1.0) :
	set(v):
		axis_color = v
		if _initialized: draw()

# ============================================================
# Configuration – Labels
# ============================================================
@export_group("Labels")

@export var show_labels: bool = true :
	set(v):
		show_labels = v
		if _initialized: _update_labels()

@export var label_size: float = 0.2 :
	set(v):
		label_size = v
		if _initialized: _update_labels()

@export var label_color: Color = Color.WHITE :
	set(v):
		label_color = v
		if _initialized: _update_labels()

# ============================================================
# Configuration – Draw Progress
# ============================================================
@export_group("Draw Progress")

@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0 :
	set(v):
		draw_progress = clamp(v, 0.0, 1.0)
		if _initialized: draw()

# ============================================================
# Private
# ============================================================
var _mesh: ImmediateMesh
var _mat: StandardMaterial3D
var _mesh_instance: MeshInstance3D

var _axis_mesh: ImmediateMesh
var _axis_mat: StandardMaterial3D
var _axis_mesh_instance: MeshInstance3D

var _label_container: Node3D
var _labels: Array[Label3D] = []

var _cam_pos_local: Vector3 = Vector3.ZERO
var _initialized: bool = false

# ============================================================
# Lifecycle – robust reparenting support
# ============================================================
func _init() -> void:
	_mesh = ImmediateMesh.new()
	_axis_mesh = ImmediateMesh.new()

func _enter_tree() -> void:
	if not _initialized:
		_initialize()
	# In case the node was reparented and mesh instances were freed, recreate them
	if not is_instance_valid(_mesh_instance):
		_create_mesh_instances()
	if not is_instance_valid(_label_container):
		_label_container = Node3D.new()
		_label_container.name = "Labels"
		add_child(_label_container)
	# Redraw to ensure everything is correct after reparenting
	call_deferred("draw")
	call_deferred("_update_labels")

func _exit_tree() -> void:
	_initialized = false
	_cleanup_mesh_instances()

func _ready() -> void:
	# Called only once when entering the tree for the first time
	_initialize()

func _initialize() -> void:
	_create_mesh_instances()
	_label_container = Node3D.new()
	_label_container.name = "Labels"
	add_child(_label_container)
	_initialized = true
	draw()
	_update_labels()

func _create_mesh_instances() -> void:
	if not _mat:
		_mat = _make_material()
	
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.material_override = _mat
	add_child(_mesh_instance)
	
	if axis_separate_color:
		_rebuild_axis_mesh()

func _cleanup_mesh_instances() -> void:
	if is_instance_valid(_mesh_instance):
		_mesh_instance.mesh = null
		_mesh_instance.queue_free()
		_mesh_instance = null
	_destroy_axis_mesh()
	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()

# ============================================================
# Public API
# ============================================================
## Convert local grid coordinates to global position.
## Input can be normalized (0..1) or absolute (world units).
func local_grid_to_global(grid_x: float, grid_y: float, grid_z: float, normalized: bool = true) -> Vector3:
	var local := Vector3()
	if normalized:
		local.x = lerp(x_range.x, x_range.y, grid_x)
		local.y = lerp(y_range.x, y_range.y, grid_y)
		local.z = lerp(z_range.x, z_range.y, grid_z)
	else:
		local = Vector3(grid_x, grid_y, grid_z)
	local *= scale_to_world
	return to_global(local)

## Force redraw (useful after manual modifications)
func redraw() -> void:
	draw()
	_update_labels()

# ============================================================
# Drawing
# ============================================================
func draw() -> void:
	if not _initialized or not is_instance_valid(_mesh):
		return
	
	_mesh.clear_surfaces()
	if is_instance_valid(_axis_mesh):
		_axis_mesh.clear_surfaces()
	
	if draw_progress <= 0.0:
		return
	
	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_position()
	
	var s := scale_to_world
	var x_min := x_range.x * s
	var x_max := x_range.y * s
	var y_min := y_range.x * s
	var y_max := y_range.y * s
	var z_min := z_range.x * s
	var z_max := z_range.y * s
	
	var center := Vector3(
		(x_min + x_max) * 0.5,
		(y_min + y_max) * 0.5,
		(z_min + z_max) * 0.5
	)
	var half_diag := Vector3(x_max - x_min, y_max - y_min, z_max - z_min).length() * 0.5
	var max_dist := half_diag * draw_progress
	
	var x_step := (x_max - x_min) / x_divisions
	var z_step := (z_max - z_min) / z_divisions
	
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var axis_surface_open := false
	if axis_separate_color and is_instance_valid(_axis_mesh):
		_axis_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		axis_surface_open = true
	
	# XZ plane grid: lines parallel to X (constant Z)
	for i in range(z_divisions + 1):
		var z := z_min + i * z_step
		if (Vector3(center.x, center.y, z) - center).length() <= max_dist:
			var is_x_axis :bool= abs(z) < z_step * 0.01
			if is_x_axis and show_axes:
				_emit_axis_line(Vector3(x_min, 0, z), Vector3(x_max, 0, z), axis_surface_open)
			else:
				_draw_line_on(_mesh, Vector3(x_min, 0, z), Vector3(x_max, 0, z),
					line_thickness * 0.5, color)
	
	# Lines parallel to Z (constant X)
	for i in range(x_divisions + 1):
		var x := x_min + i * x_step
		if (Vector3(x, center.y, center.z) - center).length() <= max_dist:
			var is_z_axis :bool= abs(x) < x_step * 0.01
			if is_z_axis and show_axes:
				_emit_axis_line(Vector3(x, 0, z_min), Vector3(x, 0, z_max), axis_surface_open)
			else:
				_draw_line_on(_mesh, Vector3(x, 0, z_min), Vector3(x, 0, z_max),
					line_thickness * 0.5, color)
	
	# Y axis line (if enabled)
	if show_y_axis and show_axes:
		var y_from := Vector3(0, y_min, 0)
		var y_to   := Vector3(0, y_max, 0)
		if (y_from - center).length() <= max_dist or (y_to - center).length() <= max_dist:
			_emit_axis_line(y_from, y_to, axis_surface_open)
	
	_mesh.surface_end()
	if axis_surface_open:
		_axis_mesh.surface_end()

func _emit_axis_line(from: Vector3, to: Vector3, into_axis_mesh: bool) -> void:
	var r := axis_thickness * 0.5
	var col := axis_color
	if into_axis_mesh:
		_mesh.surface_end()
		_draw_line_on(_axis_mesh, from, to, r, col)
		_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	else:
		# When not using separate axis mesh, still use axis_color if show_axes is true
		if show_axes:
			col = axis_color
		else:
			col = color.lightened(0.3)
		_draw_line_on(_mesh, from, to, r, col)

func _draw_line_on(target: ImmediateMesh, from: Vector3, to: Vector3, r: float, line_color: Color) -> void:
	var dir := to - from
	if dir.length() < 0.001 or r <= 0.0:
		return
	dir = dir.normalized()
	
	var mid := (from + to) * 0.5
	var to_cam := _cam_pos_local - mid
	if to_cam.length() < 0.0001:
		to_cam = Vector3.UP
	to_cam = to_cam.normalized()
	
	var lateral := dir.cross(to_cam)
	if lateral.length() < 0.0001:
		var arb := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		lateral = dir.cross(arb)
	lateral = lateral.normalized() * r
	
	target.surface_set_color(line_color)
	_quad_on(target,
		from - lateral, from + lateral,
		to   + lateral, to   - lateral)

func _quad_on(target: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	target.surface_add_vertex(a)
	target.surface_add_vertex(b)
	target.surface_add_vertex(c)
	target.surface_add_vertex(a)
	target.surface_add_vertex(c)
	target.surface_add_vertex(d)

# ============================================================
# Labels – updated on any relevant change
# ============================================================
func _update_labels() -> void:
	# Clear old labels
	for lbl in _labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_labels.clear()
	
	if not show_labels or not _initialized:
		return
	
	var s := scale_to_world
	var x_min := x_range.x * s
	var x_max := x_range.y * s
	var y_min := y_range.x * s
	var y_max := y_range.y * s
	var z_min := z_range.x * s
	var z_max := z_range.y * s
	
	var offset := 0.15 * s  # base offset from axis lines
	
	var create_label := func(pos: Vector3, text: String, col: Color = label_color) -> void:
		var lbl := Label3D.new()
		lbl.text = text
		lbl.position = pos
		lbl.modulate = col
		lbl.font_size = int(label_size * 50)  # adjust multiplier as needed
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.pixel_size = 0.001  # helps readability in 3D
		_label_container.add_child(lbl)
		_labels.append(lbl)
	
	# Axis endpoint labels
	if show_axes:
		create_label.call(Vector3(x_max + offset, 0, 0), "X")
		create_label.call(Vector3(0, 0, z_max + offset), "Z")
	if show_y_axis and show_axes:
		create_label.call(Vector3(0, y_max + offset, 0), "Y")
	
	var step_x := (x_max - x_min) / x_divisions
	var step_z := (z_max - z_min) / z_divisions
	var step_y := (y_max - y_min) / y_divisions
	
	# X axis ticks (placed below the X axis)
	if show_axes:
		for i in range(x_divisions + 1):
			var x_val := x_min + i * step_x
			var col := axis_color if axis_separate_color else label_color
			create_label.call(Vector3(x_val, -offset, 0), "%.1f" % (x_val / s), col)
	
	# Z axis ticks (placed below the Z axis)
	if show_axes:
		for i in range(z_divisions + 1):
			var z_val := z_min + i * step_z
			var col := axis_color if axis_separate_color else label_color
			create_label.call(Vector3(0, -offset, z_val), "%.1f" % (z_val / s), col)
	
	# Y axis ticks (placed to the side of the Y axis)
	if show_y_axis and show_axes:
		for i in range(y_divisions + 1):
			var y_val := y_min + i * step_y
			var col := axis_color if axis_separate_color else label_color
			create_label.call(Vector3(offset, y_val, 0), "%.1f" % (y_val / s), col)

# ============================================================
# Axis Mesh Helpers
# ============================================================
func _rebuild_axis_mesh() -> void:
	if axis_separate_color:
		if not is_instance_valid(_axis_mesh_instance):
			if not (_axis_mesh is ImmediateMesh):
				_axis_mesh = ImmediateMesh.new()
			_axis_mat = _make_material()
			_axis_mesh_instance = MeshInstance3D.new()
			_axis_mesh_instance.mesh = _axis_mesh
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

# ============================================================
# Utilities
# ============================================================
func _make_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

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
