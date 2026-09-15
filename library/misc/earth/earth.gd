@tool
extends BaseMeshInstance3D
class_name Earth

# ---------------------------------------------------------------------------
#  Requires in project:
#    DashedCircleQuad, DashedLineQuad, Arrow3DQuad
#
#  Architecture:
#    MeshInstance3D (this) – sphere mesh, never rotates
#      └── SpinPivot (Node3D) – rotates for auto‑rotate, carries axial tilt
#            └── LinesRoot – all grid circles/lines (spin with globe)
#
#  Selection rings & radial arrows are attached to get_parent() so they
#  live in world space and are repositioned every frame.
#
#  Coordinate convention (local space of this MeshInstance3D):
#    +Y = north pole
#    lat ∈ [-PI/2, PI/2]  (equator = 0)
#    lon ∈ [0, TAU]       (0 = +Z, grows CCW from above)
# ---------------------------------------------------------------------------

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Local transform
# ════════════════════════════════════════════════════════════════════════════

@export_category("local transform parameters")

@export var local_rotation_x: float = 0.0:
	set(value):
		local_rotation_x = value
		_apply_local_rotations()

@export var local_rotation_y: float = 0.0:
	set(value):
		local_rotation_y = value
		_apply_local_rotations()

@export var local_rotation_z: float = 0.0:
	set(value):
		local_rotation_z = value
		_apply_local_rotations()

func _apply_local_rotations() -> void:
	var b := Basis.IDENTITY
	b = b.rotated(Vector3(1, 0, 0), deg_to_rad(local_rotation_x))
	b = b.rotated(Vector3(0, 1, 0), deg_to_rad(local_rotation_y))
	b = b.rotated(Vector3(0, 0, 1), deg_to_rad(local_rotation_z))
	transform.basis = b

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Physical
# ════════════════════════════════════════════════════════════════════════════

@export_category("Physical constants")

@export_range(0.1, 100.0, 0.1) var radius: float = 1.0:
	set(v): radius = v; if _ready_done: _rebuild()

@export_range(0.1, 200.0, 0.1) var height: float = 2.0:
	set(v): height = v; if _ready_done: _rebuild()

@export_range(0.0, 1.0, 0.01) var surface_opacity: float = 1.0:
	set(v): surface_opacity = clamp(v, 0.0, 1.0); if _ready_done: _apply_surface_opacity()

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Geographical
# ════════════════════════════════════════════════════════════════════════════

@export_category("Geographical constants")

@export_range(0.0, TAU, 0.001) var tilt: float = 0.0:
	set(v): tilt = v; if _ready_done: _apply_tilt()

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Rotation
# ════════════════════════════════════════════════════════════════════════════

@export_category("Rotational constants")

@export var auto_rotate: bool = false
@export_range(0.0, TAU, 0.001) var auto_rotate_speed: float = 0.3

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Equator & Meridian
# ════════════════════════════════════════════════════════════════════════════

@export_category("Equator line")

@export var visible_equator_line: bool = false:
	set(v): visible_equator_line = v; if _ready_done: _rebuild_lines()
@export var equator_line_color: Color = Color.CYAN:
	set(v): equator_line_color = v; if _ready_done: _rebuild_lines()
@export_range(0.001, 0.5, 0.001) var equator_line_thickness: float = 0.025:
	set(v): equator_line_thickness = v; if _ready_done: _rebuild_lines()
@export var equator_line_solid: bool = true:
	set(v): equator_line_solid = v; if _ready_done: _rebuild_lines()
@export_range(0.01, 4.0, 0.01) var equator_dash_length: float = 0.3:
	set(v): equator_dash_length = max(0.01, v); if _ready_done: _rebuild_lines()
@export_range(0.01, 4.0, 0.01) var equator_gap_length: float = 0.15:
	set(v): equator_gap_length = max(0.01, v); if _ready_done: _rebuild_lines()

@export_category("Meridian line")

@export var visible_meridian_line: bool = false:
	set(v): visible_meridian_line = v; if _ready_done: _rebuild_lines()
@export var meridian_line_color: Color = Color.YELLOW:
	set(v): meridian_line_color = v; if _ready_done: _rebuild_lines()
@export_range(0.001, 0.5, 0.001) var meridian_line_thickness: float = 0.025:
	set(v): meridian_line_thickness = v; if _ready_done: _rebuild_lines()
@export var meridian_line_solid: bool = true:
	set(v): meridian_line_solid = v; if _ready_done: _rebuild_lines()
@export_range(0.01, 4.0, 0.01) var meridian_dash_length: float = 0.3:
	set(v): meridian_dash_length = max(0.01, v); if _ready_done: _rebuild_lines()
@export_range(0.01, 4.0, 0.01) var meridian_gap_length: float = 0.15:
	set(v): meridian_gap_length = max(0.01, v); if _ready_done: _rebuild_lines()

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Latitude grid rings
# ════════════════════════════════════════════════════════════════════════════

@export_category("Latitude grid rings")

@export var visible_latitude_rings: bool = false:
	set(v): visible_latitude_rings = v; if _ready_done: _rebuild_lines()
@export var latitude_ring_color: Color = Color(0.6, 0.9, 1.0, 0.7):
	set(v): latitude_ring_color = v; if _ready_done: _rebuild_lines()
@export_range(0.001, 0.5, 0.001) var latitude_ring_thickness: float = 0.015:
	set(v): latitude_ring_thickness = v; if _ready_done: _rebuild_lines()
@export var latitude_ring_solid: bool = false:
	set(v): latitude_ring_solid = v; if _ready_done: _rebuild_lines()
@export_range(0.01, 4.0, 0.01) var latitude_dash_length: float = 0.25:
	set(v): latitude_dash_length = max(0.01, v); if _ready_done: _rebuild_lines()
@export_range(0.01, 4.0, 0.01) var latitude_gap_length: float = 0.12:
	set(v): latitude_gap_length = max(0.01, v); if _ready_done: _rebuild_lines()
@export_range(1, 12, 1) var latitude_ring_count: int = 5:
	set(v): latitude_ring_count = max(1, v); if _ready_done: _rebuild_lines()

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Longitude grid meridians
# ════════════════════════════════════════════════════════════════════════════

@export_category("Longitude grid meridians")

@export var visible_longitude_lines: bool = false:
	set(v): visible_longitude_lines = v; if _ready_done: _rebuild_lines()
@export var longitude_line_color: Color = Color(0.6, 0.9, 1.0, 0.7):
	set(v): longitude_line_color = v; if _ready_done: _rebuild_lines()
@export_range(0.001, 0.5, 0.001) var longitude_line_thickness: float = 0.015:
	set(v): longitude_line_thickness = v; if _ready_done: _rebuild_lines()
@export var longitude_line_solid: bool = false:
	set(v): longitude_line_solid = v; if _ready_done: _rebuild_lines()
@export_range(0.01, 4.0, 0.01) var longitude_dash_length: float = 0.25:
	set(v): longitude_dash_length = max(0.01, v); if _ready_done: _rebuild_lines()
@export_range(0.01, 4.0, 0.01) var longitude_gap_length: float = 0.12:
	set(v): longitude_gap_length = max(0.01, v); if _ready_done: _rebuild_lines()
@export_range(2, 36, 1) var longitude_line_count: int = 12:
	set(v): longitude_line_count = max(2, v); if _ready_done: _rebuild_lines()

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Targets
# ════════════════════════════════════════════════════════════════════════════

@export_category("Targets")

@export var clamp_targets: bool = false:
	set(v): clamp_targets = v; if _ready_done: _clamp_all_targets()

@export var targets: Array[NodePath] = []:
	set(v): targets = v; if _ready_done: _clamp_all_targets()

@export var surface_offset: float = 0.2:
	set(v): surface_offset = v; if _ready_done: _clamp_all_targets()

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Selected target movement
# ════════════════════════════════════════════════════════════════════════════

@export_category("Selected target movement")

enum ForwardAxis { X_POS, X_NEG, Y_POS, Y_NEG, Z_POS, Z_NEG }

@export var movement_forward_axis: ForwardAxis = ForwardAxis.Z_POS

@export var selected_targets: Array[NodePath] = []:
	set(v): selected_targets = v; if _ready_done: _rebuild_selection_visuals()

@export_range(0.0, TAU, 0.001) var longitude: float = 0.0:
	set(v):
		longitude = fmod(v, TAU)
		if _ready_done: _move_selected_targets()

@export_range(-PI * 0.5, PI * 0.5, 0.001) var latitude: float = 0.0:
	set(v):
		latitude = clamp(v, -PI * 0.5, PI * 0.5)
		if _ready_done: _move_selected_targets()

# ════════════════════════════════════════════════════════════════════════════
#  EXPORTS — Selection visuals
# ════════════════════════════════════════════════════════════════════════════

@export_category("Selection ring")

@export var show_selection_ring: bool = true:
	set(v): show_selection_ring = v; if _ready_done: _rebuild_selection_visuals()
@export var selection_ring_color: Color = Color(0.2, 0.85, 1.0):
	set(v): selection_ring_color = v; if _ready_done: _rebuild_selection_visuals()
@export_range(0.01, 4.0, 0.01) var selection_ring_radius: float = 0.18:
	set(v): selection_ring_radius = v; if _ready_done: _rebuild_selection_visuals()
@export_range(0.001, 0.2, 0.001) var selection_ring_thickness: float = 0.018:
	set(v): selection_ring_thickness = v; if _ready_done: _rebuild_selection_visuals()

@export_category("Radial arrow")

@export var show_radial_arrow: bool = false:
	set(v): show_radial_arrow = v; if _ready_done: _rebuild_selection_visuals()
@export var radial_arrow_color: Color = Color(1.0, 0.5, 0.1):
	set(v): radial_arrow_color = v; if _ready_done: _rebuild_selection_visuals()
@export_range(0.0, 1.0, 0.001) var radial_arrow_draw_progress: float = 1.0:
	set(v):
		radial_arrow_draw_progress = clamp(v, 0.0, 1.0)
		if _ready_done: _push_arrow_props()
@export_range(0.001, 0.2, 0.001) var radial_arrow_shaft_radius: float = 0.012:
	set(v): radial_arrow_shaft_radius = v; if _ready_done: _rebuild_selection_visuals()
@export_range(0.001, 0.4, 0.001) var radial_arrow_head_radius: float = 0.05:
	set(v): radial_arrow_head_radius = v; if _ready_done: _rebuild_selection_visuals()

# ════════════════════════════════════════════════════════════════════════════
#  PRIVATE
# ════════════════════════════════════════════════════════════════════════════

var _spin_pivot: Node3D
var _lines_root: Node3D
var _sphere_mesh: SphereMesh
var _overlay_mat: StandardMaterial3D

var _sel_visuals: Dictionary = {}   # { path_key: {"ring":., "arrow":.} }

const _SURFACE_BIAS := 0.003

var _ready_done := false
var _prev_lat := 0.0
var _prev_lon := 0.0

# ════════════════════════════════════════════════════════════════════════════
#  LIFECYCLE
# ════════════════════════════════════════════════════════════════════════════

func _setup() -> void:
	_spin_pivot = Node3D.new()
	_spin_pivot.name = "SpinPivot"
	add_child(_spin_pivot)

	_sphere_mesh = SphereMesh.new()
	_sphere_mesh.radial_segments = 64
	_sphere_mesh.rings = 32
	mesh = _sphere_mesh

	_overlay_mat = material_overlay as StandardMaterial3D

	_lines_root = Node3D.new()
	_lines_root.name = "LinesRoot"
	_spin_pivot.add_child(_lines_root)

	_prev_lat = latitude
	_prev_lon = longitude

	_ready_done = true
	_rebuild()


func _teardown() -> void:
	_ready_done = false
	_cleanup_sel_visuals()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_setup()
		NOTIFICATION_EXIT_TREE:
			_teardown()


func _set(property: StringName, _value: Variant) -> bool:
	if property == &"mesh":
		return true  # block Godot restoring mesh = null on reload
	return false


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray()


func _process(delta: float) -> void:
	if auto_rotate:
		_spin_pivot.rotate_y(auto_rotate_speed * delta)
	_update_sel_transforms()

# ════════════════════════════════════════════════════════════════════════════
#  REBUILD
# ════════════════════════════════════════════════════════════════════════════

func _rebuild() -> void:
	_apply_sphere_shape()
	_apply_surface_opacity()
	_apply_tilt()
	_rebuild_lines()
	_clamp_all_targets()
	_rebuild_selection_visuals()


func _apply_sphere_shape() -> void:
	if not is_instance_valid(_sphere_mesh): return
	_sphere_mesh.radius = radius
	_sphere_mesh.height = height


func _apply_surface_opacity() -> void:
	if material_overlay != _overlay_mat:
		_overlay_mat = material_overlay as StandardMaterial3D
	if not is_instance_valid(_overlay_mat): return
	_overlay_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var c := _overlay_mat.albedo_color
	c.a = surface_opacity
	_overlay_mat.albedo_color = c


func _apply_tilt() -> void:
	if not is_instance_valid(_spin_pivot): return
	_spin_pivot.rotation = Vector3(0.0, _spin_pivot.rotation.y, tilt)

# ════════════════════════════════════════════════════════════════════════════
#  GRID LINES  (SpinPivot‑local → spin with the globe)
# ════════════════════════════════════════════════════════════════════════════

func _cleanup_lines() -> void:
	if not is_instance_valid(_lines_root): return
	for ch in _lines_root.get_children():
		ch.queue_free()


func _rebuild_lines() -> void:
	if not _ready_done or not is_instance_valid(_lines_root): return
	_cleanup_lines()

	var r := radius + _SURFACE_BIAS
	var b := height * 0.5 + _SURFACE_BIAS

	if visible_equator_line:
		_lines_root.add_child(_make_circle(r, 0.0, equator_line_color,
				equator_line_thickness, equator_line_solid,
				equator_dash_length, equator_gap_length))

	if visible_meridian_line:
		_lines_root.add_child(_make_great_circle(r, b, 0.0, meridian_line_color,
				meridian_line_thickness, meridian_line_solid,
				meridian_dash_length, meridian_gap_length))

	if visible_latitude_rings:
		for i in range(1, latitude_ring_count + 1):
			var lat := (float(i) / float(latitude_ring_count + 1)) * (PI * 0.5)
			for sign_v in [1.0, -1.0]:
				var lat_s: float = lat * sign_v
				var ring_r := cos(lat_s) * r
				var ring_y := sin(lat_s) * b
				_lines_root.add_child(_make_circle(ring_r, ring_y, latitude_ring_color,
						latitude_ring_thickness, latitude_ring_solid,
						latitude_dash_length, latitude_gap_length))

	if visible_longitude_lines:
		for i in range(longitude_line_count):
			var lon := (float(i) / float(longitude_line_count)) * TAU
			_lines_root.add_child(_make_great_circle(r, b, lon, longitude_line_color,
					longitude_line_thickness, longitude_line_solid,
					longitude_dash_length, longitude_gap_length))


func _make_circle(ring_r: float, y: float, col: Color,
		thick: float, solid: bool, dash: float, gap: float) -> DashedCircleQuad:
	var c := DashedCircleQuad.new()
	c.radius    = ring_r
	c.pos       = Vector3(0.0, y, 0.0)
	c.color     = col
	c.thickness = thick
	c.solid     = solid
	if not solid:
		c.dash_length = dash
		c.gap_length  = gap
	return c


func _make_great_circle(r: float, b: float, lon: float, col: Color,
		thick: float, solid: bool, dash: float, gap: float) -> DashedLineQuad:
	var pts: Array[Vector3] = []
	var steps := 128
	for i in range(steps + 1):
		var ang := (float(i) / float(steps)) * TAU
		var xz  := sin(ang) * r
		var y   := cos(ang) * b
		pts.append(Vector3(xz * cos(lon), y, xz * sin(lon)))
	var line := DashedLineQuad.new(pts)
	line.color     = col
	line.thickness = thick
	line.solid     = solid
	if not solid:
		line.dash_length = dash
		line.gap_length  = gap
	return line

# ════════════════════════════════════════════════════════════════════════════
#  ELLIPSOID MATHS  (always in THIS node's local space)
# ════════════════════════════════════════════════════════════════════════════

func _ry() -> float:
	return height * 0.5


func _to_local(world_pos: Vector3) -> Vector3:
	return global_transform.affine_inverse() * world_pos


func _to_world(local_pos: Vector3) -> Vector3:
	return global_transform * local_pos


func _ellipsoid_dir(world_pos: Vector3) -> Vector3:
	var lp := _to_local(world_pos)
	var a  := radius
	var b  := _ry()
	if lp.length_squared() < 1e-8: return Vector3.UP
	var d := Vector3(lp.x / a, lp.y / b, lp.z / a)
	if d.length_squared() < 1e-8: return Vector3.UP
	return d.normalized()


func _surface_point(world_pos: Vector3) -> Vector3:
	var d := _ellipsoid_dir(world_pos)
	var a := radius
	var b := _ry()
	return _to_world(Vector3(d.x * a, d.y * b, d.z * a))


func _surface_normal(world_surf: Vector3) -> Vector3:
	var ls := _to_local(world_surf)
	var a  := radius
	var b  := _ry()
	var n_local := Vector3(ls.x / (a * a), ls.y / (b * b), ls.z / (a * a))
	if n_local.length_squared() < 1e-8: n_local = Vector3.UP
	var basis_it := global_transform.basis.inverse().transposed()
	return (basis_it * n_local).normalized()


func _lat_lon_to_world(lat: float, lon: float) -> Vector3:
	var a  := radius
	var b  := _ry()
	var cl := cos(lat)
	return _to_world(Vector3(cl * sin(lon) * a, sin(lat) * b, cl * cos(lon) * a))


func _world_to_lat_lon(world_pos: Vector3) -> Vector2:
	var d := _ellipsoid_dir(world_pos)
	return Vector2(asin(clamp(d.y, -1.0, 1.0)), atan2(d.x, d.z))

# ════════════════════════════════════════════════════════════════════════════
#  TANGENT DIRECTIONS (world space) for movement alignment
# ════════════════════════════════════════════════════════════════════════════

func _north_direction(lat: float, lon: float) -> Vector3:
	var a  := radius
	var b  := _ry()
	var sl := sin(lat); var cl := cos(lat)
	var sn := sin(lon); var cn := cos(lon)
	return _to_world(Vector3(-sl * sn * a, cl * b, -sl * cn * a)).normalized()


func _east_direction(lat: float, lon: float) -> Vector3:
	var a  := radius
	var cl := cos(lat)
	var sn := sin(lon); var cn := cos(lon)
	return _to_world(Vector3(cl * cn * a, 0.0, -cl * sn * a)).normalized()

# ════════════════════════════════════════════════════════════════════════════
#  TARGET CLAMPING
# ════════════════════════════════════════════════════════════════════════════

func _clamp_node(node: Node3D) -> void:
	if not is_instance_valid(node) or not is_inside_tree(): return
	var sp := _surface_point(node.global_position)
	var n  := _surface_normal(sp)
	node.global_position = sp + n * surface_offset


func _clamp_all_targets() -> void:
	if not clamp_targets: return
	for path in targets:
		if path == NodePath(""): continue
		var node := get_node_or_null(path) as Node3D
		if is_instance_valid(node): _clamp_node(node)

# ════════════════════════════════════════════════════════════════════════════
#  SELECTED TARGET MOVEMENT
# ════════════════════════════════════════════════════════════════════════════

func _move_selected_targets() -> void:
	if selected_targets.is_empty(): return

	var lat := latitude
	var lon := longitude

	var tangent := Vector3.ZERO
	if not is_equal_approx(lat, _prev_lat):
		tangent = _north_direction(lat, lon)
	elif not is_equal_approx(lon, _prev_lon):
		tangent = _east_direction(lat, lon)

	_prev_lat = lat
	_prev_lon = lon

	for path in selected_targets:
		if path == NodePath(""): continue
		var node := get_node_or_null(path) as Node3D
		if not is_instance_valid(node): continue

		var sp := _lat_lon_to_world(lat, lon)
		var n  := _surface_normal(sp)
		node.global_position = sp + n * surface_offset

		if tangent.length_squared() > 0.001:
			_align_forward_axis(node, tangent, n)

	_update_sel_transforms()


func _align_forward_axis(node: Node3D, tangent: Vector3, normal: Vector3) -> void:
	var up := normal.normalized()
	var fw := tangent.normalized()

	var original_scale := node.global_transform.basis.get_scale()

	var x_axis: Vector3
	var y_axis: Vector3
	var z_axis: Vector3

	match movement_forward_axis:
		ForwardAxis.Z_POS, ForwardAxis.Z_NEG:
			z_axis = fw if movement_forward_axis == ForwardAxis.Z_POS else -fw
			y_axis = up
			if abs(y_axis.dot(z_axis)) > 0.9999:
				z_axis = y_axis.cross(Vector3.RIGHT).normalized()
			x_axis = y_axis.cross(z_axis).normalized()
			z_axis = x_axis.cross(y_axis).normalized()

		ForwardAxis.X_POS, ForwardAxis.X_NEG:
			x_axis = fw if movement_forward_axis == ForwardAxis.X_POS else -fw
			y_axis = up
			if abs(y_axis.dot(x_axis)) > 0.9999:
				x_axis = y_axis.cross(Vector3.FORWARD).normalized()
			z_axis = x_axis.cross(y_axis).normalized()
			x_axis = y_axis.cross(z_axis).normalized()

		ForwardAxis.Y_POS, ForwardAxis.Y_NEG:
			y_axis = fw if movement_forward_axis == ForwardAxis.Y_POS else -fw
			z_axis = -up
			if abs(y_axis.dot(z_axis)) > 0.9999:
				z_axis = y_axis.cross(Vector3.RIGHT).normalized()
			x_axis = y_axis.cross(z_axis).normalized()
			z_axis = x_axis.cross(y_axis).normalized()

	node.global_transform.basis = Basis(x_axis, y_axis, z_axis).scaled(original_scale)

# ════════════════════════════════════════════════════════════════════════════
#  SELECTION VISUALS
# ════════════════════════════════════════════════════════════════════════════

func _cleanup_sel_visuals() -> void:
	for key in _sel_visuals:
		var e: Dictionary = _sel_visuals[key]
		if e.has("ring")  and is_instance_valid(e["ring"]):  e["ring"].queue_free()
		if e.has("arrow") and is_instance_valid(e["arrow"]): e["arrow"].queue_free()
	_sel_visuals.clear()


func _rebuild_selection_visuals() -> void:
	if not _ready_done: return
	_cleanup_sel_visuals()

	var attach: Node = get_parent()
	if not is_instance_valid(attach): return

	for path in selected_targets:
		if path == NodePath(""): continue
		var node := get_node_or_null(path) as Node3D
		if not is_instance_valid(node): continue

		var key := path.get_concatenated_names()
		var e   := {}

		if show_selection_ring:
			var ring := DashedCircleQuad.new()
			ring.radius    = selection_ring_radius
			ring.color     = selection_ring_color
			ring.thickness = selection_ring_thickness
			ring.solid     = true
			# ✅ Synchronous add — node is in the tree immediately
			attach.add_child(ring)
			e["ring"] = ring

		if show_radial_arrow:
			# ✅ Dummy positions — _update_sel_transforms corrects them after tree is ready
			var arrow := Arrow3DQuad.new(Vector3.ZERO, Vector3.ONE)
			arrow.color        = radial_arrow_color
			arrow.shaft_radius = radial_arrow_shaft_radius
			arrow.head_radius  = radial_arrow_head_radius
			arrow.draw_progress = radial_arrow_draw_progress
			arrow.dashed       = false
			attach.add_child(arrow)
			e["arrow"] = arrow

		_sel_visuals[key] = e

	# ✅ Defer the transform pass so every child is guaranteed inside the tree
	_update_sel_transforms.call_deferred()


func _push_arrow_props() -> void:
	for key in _sel_visuals:
		var e: Dictionary = _sel_visuals[key]
		if e.has("arrow") and is_instance_valid(e["arrow"]):
			var arrow: Arrow3DQuad = e["arrow"]
			arrow.draw_progress = radial_arrow_draw_progress
			arrow.color         = radial_arrow_color
			arrow.shaft_radius  = radial_arrow_shaft_radius
			arrow.head_radius   = radial_arrow_head_radius


func _update_sel_transforms() -> void:
	if not _ready_done or not is_inside_tree(): return

	for path in selected_targets:
		if path == NodePath(""): continue
		var node := get_node_or_null(path) as Node3D
		if not is_instance_valid(node): continue

		var key := path.get_concatenated_names()
		if not _sel_visuals.has(key): continue
		var e: Dictionary = _sel_visuals[key]

		var sp := _surface_point(node.global_position)
		var n  := _surface_normal(sp)

		if e.has("ring") and is_instance_valid(e["ring"]):
			var ring: DashedCircleQuad = e["ring"]
			if ring.is_inside_tree():
				ring.global_position = sp + n * (surface_offset + _SURFACE_BIAS * 2.0)
				var right := n.cross(Vector3.FORWARD)
				if right.length_squared() < 0.01:
					right = n.cross(Vector3.RIGHT)
				right = right.normalized()
				var fwd := right.cross(n).normalized()
				ring.global_transform.basis = Basis(right, n, -fwd)

		if e.has("arrow") and is_instance_valid(e["arrow"]):
			var arrow: Arrow3DQuad = e["arrow"]
			arrow.global_position  = Vector3.ZERO
			arrow.global_rotation  = Vector3.ZERO
			arrow.start            = global_position
			arrow.end              = sp
			arrow.draw_progress    = radial_arrow_draw_progress

# ════════════════════════════════════════════════════════════════════════════
#  CLEANUP
# ════════════════════════════════════════════════════════════════════════════

func _cleanup_all() -> void:
	_cleanup_lines()
	_cleanup_sel_visuals()
