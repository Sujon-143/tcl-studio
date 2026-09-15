@tool
extends BaseNode3D
class_name InfinityPlane

## A fading ground plane drawn as a flat quad that fades from opaque at the
## centre to fully transparent at the edges, with an optional grid overlay
## that fades the same way.
##
## Compose-based: owns a single MeshInstance3D child. The material is always
## present (transparency is always needed), so there is no toggle pattern here.

#region Configuration — Plane

@export_group("Plane")

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: draw()

## Radius within which the plane is fully opaque.
@export_range(0.1, 100.0, 0.01) var inner_size: float = 5.0 :
	set(value):
		inner_size = max(0.1, value)
		if _ready_done: draw()

## Radius at which the plane becomes fully transparent.
@export_range(0.1, 500.0, 0.01) var outer_size: float = 30.0 :
	set(value):
		outer_size = max(0.1, value)
		if _ready_done: draw()

#endregion

#region Configuration — Grid

@export_group("Grid")

@export var show_grid: bool = true :
	set(value):
		show_grid = value
		if _ready_done: draw()

@export_range(1, 64, 1) var divisions: int = 8 :
	set(value):
		divisions = max(1, value)
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var line_thickness: float = 0.03 :
	set(value):
		line_thickness = value
		if _ready_done: draw()

#endregion

#region Private

var _mesh: ImmediateMesh
var _mat: StandardMaterial3D
var _mesh_instance: MeshInstance3D

var _ready_done: bool = false

#endregion

#region Static factories

static func get_default() -> InfinityPlane:
	var p := InfinityPlane.new()
	p.color = Color(0.3, 0.3, 0.8, 0.5)
	return p

static func get_dark() -> InfinityPlane:
	var p := InfinityPlane.new()
	p.color      = Color(0.05, 0.05, 0.05, 0.8)
	p.inner_size = 8.0
	p.outer_size = 40.0
	return p

static func get_subtle() -> InfinityPlane:
	var p := InfinityPlane.new()
	p.color      = Color(0.5, 0.5, 0.5, 0.25)
	p.inner_size = 6.0
	p.outer_size = 25.0
	p.show_grid  = false
	return p

#endregion

#region Lifecycle

func _init() -> void:
	_mesh = ImmediateMesh.new()

func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	_mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA

	_mesh_instance                   = MeshInstance3D.new()
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

#endregion

#region Public API

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_inner_size(value: float) -> void:
	inner_size = max(0.1, value)
	draw()

func set_outer_size(value: float) -> void:
	outer_size = max(0.1, value)
	draw()

func set_show_grid(value: bool) -> void:
	show_grid = value
	draw()

func set_divisions(value: int) -> void:
	divisions = max(1, value)
	draw()

func set_line_thickness(value: float) -> void:
	line_thickness = value
	draw()

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_mesh):
		return

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	_draw_fading_plane()

	if show_grid:
		_draw_fading_grid()

	_mesh.surface_end()

## Four triangles fanning from the origin so vertex colors interpolate from
## opaque at the centre to fully transparent at the outer corners.
func _draw_fading_plane() -> void:
	var s: float = outer_size
	var corners: Array[Vector3] = [
		Vector3(-s, 0.0, -s),
		Vector3( s, 0.0, -s),
		Vector3( s, 0.0,  s),
		Vector3(-s, 0.0,  s),
	]
	var opaque      := color
	var transparent := Color(color.r, color.g, color.b, 0.0)

	for i in range(4):
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		_mesh.surface_set_color(opaque)
		_mesh.surface_add_vertex(Vector3.ZERO)
		_mesh.surface_set_color(transparent)
		_mesh.surface_add_vertex(a)
		_mesh.surface_set_color(transparent)
		_mesh.surface_add_vertex(b)

## Grid lines spanning outer_size, each fading to transparent at their ends.
## Only lines whose centre offset falls within inner_size are drawn; lines
## beyond inner_size have zero alpha at the centre and are invisible anyway.
func _draw_fading_grid() -> void:
	var half: float = outer_size
	var step: float = (inner_size * 2.0) / divisions

	for i in range(divisions + 1):
		var t: float    = -inner_size + i * step
		var fade: float = 1.0 - clamp(abs(t) / inner_size, 0.0, 1.0)
		var centre_col  := Color(color.r, color.g, color.b, color.a * fade)
		var edge_col    := Color(color.r, color.g, color.b, 0.0)

		# Line parallel to X (constant Z = t)
		_draw_fading_line(
			Vector3(-half, 0.01, t), Vector3(half, 0.01, t),
			centre_col, edge_col)

		# Line parallel to Z (constant X = t)
		_draw_fading_line(
			Vector3(t, 0.01, -half), Vector3(t, 0.01, half),
			centre_col, edge_col)

## A flat ribbon quad whose two long edges are transparent and whose interior
## fades to centre_col, giving the line a soft feathered look.
## The line lies flat on the plane (no tube — this plane is intentionally flat).
func _draw_fading_line(from: Vector3, to: Vector3,
					   centre_col: Color, edge_col: Color) -> void:
	var dir  := (to - from).normalized()
	var perp := dir.cross(Vector3.UP).normalized()
	if perp.length_squared() < 0.0001:
		perp = Vector3.RIGHT

	var h := line_thickness * 0.5
	var a := from + perp * h
	var b := from - perp * h
	var c := to   - perp * h
	var d := to   + perp * h

	# Triangle 1
	_mesh.surface_set_color(edge_col);   _mesh.surface_add_vertex(a)
	_mesh.surface_set_color(edge_col);   _mesh.surface_add_vertex(b)
	_mesh.surface_set_color(centre_col); _mesh.surface_add_vertex(c)

	# Triangle 2
	_mesh.surface_set_color(edge_col);   _mesh.surface_add_vertex(a)
	_mesh.surface_set_color(centre_col); _mesh.surface_add_vertex(c)
	_mesh.surface_set_color(centre_col); _mesh.surface_add_vertex(d)

#endregion
