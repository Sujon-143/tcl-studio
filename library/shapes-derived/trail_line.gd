# TrailLine.gd — camera-facing flat quads, O(n) verts, no tube math
class_name TrailLine
extends BaseMeshInstance3D

var _im := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()
var _points: Array[Vector3] = []
var _max_points: int = 1000

@export var min_distance: float = 0.05  # minimum movement threshold

var _last_parent_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	top_level = true   # ← detaches this node from parent transform inheritance
	mesh = _im
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = _mat


# In TrailLine.gd — add this variable
var track_target: Node3D = null

func _process(_delta: float) -> void:
	var target := track_target if track_target else (get_parent() as Node3D)
	if not target:
		return
	var current_pos := target.global_position
	if current_pos.distance_to(_last_parent_pos) >= min_distance:
		_last_parent_pos = current_pos
		add_point(current_pos)


func add_point(p: Vector3) -> void:
	_points.append(p)
	if _points.size() > _max_points:
		_points.pop_front()
	_redraw()

func _redraw() -> void:
	_im.clear_surfaces()
	if _points.size() < 2:
		return
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(_points.size() - 1):
		var a := _points[i]
		var b := _points[i + 1]
		var t := float(i) / _points.size()
		var alpha := t
		var width: float = lerp(0.01, 0.5, t)
		var dir := (b - a).normalized()
		var to_cam: Vector3 = (cam.global_position - a).normalized()
		var perp := dir.cross(to_cam).normalized() * width
		var c := Color(0.965, 0.0, 0.522, alpha)
		_im.surface_set_color(c)
		_im.surface_add_vertex(a - perp)
		_im.surface_add_vertex(a + perp)
		_im.surface_add_vertex(b + perp)
		_im.surface_add_vertex(b + perp)
		_im.surface_add_vertex(b - perp)
		_im.surface_add_vertex(a - perp)
	_im.surface_end()

func clear():
	_points.clear()
