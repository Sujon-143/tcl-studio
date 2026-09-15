@tool
extends MeshBase3D
class_name QuadMesh3D

## A MeshInstance3D with an inline QuadMesh (single unsubdivided quad, UV-ready).

@export_group("Quad")

@export var size: Vector2 = Vector2(1.0, 1.0):
	set(v):
		size = v
		_build_mesh()

@export var center_offset: Vector3 = Vector3.ZERO:
	set(v):
		center_offset = v
		_build_mesh()

@export_enum("Y (horizontal)", "X (vertical YZ)", "Z (vertical XY)") var orientation: int = 0:
	set(v):
		orientation = v
		_build_mesh()

func _build_mesh() -> void:
	var m := QuadMesh.new()
	m.size          = size
	m.center_offset = center_offset
	match orientation:
		0: m.orientation = PlaneMesh.FACE_Y
		1: m.orientation = PlaneMesh.FACE_X
		2: m.orientation = PlaneMesh.FACE_Z
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

func get_surface_area() -> float:
	return size.x * size.y

func get_volume() -> float:
	return 0.0

func get_perimeter() -> float:
	return 2.0 * (size.x + size.y)

func get_normal() -> Vector3:
	match orientation:
		0: return global_transform.basis * Vector3.UP
		1: return global_transform.basis * Vector3.RIGHT
		2: return global_transform.basis * Vector3.BACK
	return global_transform.basis * Vector3.UP

func get_corners() -> Array[Vector3]:
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	var corners: Array[Vector3] = []
	for p in [Vector3(-hw, -hh, 0), Vector3(hw, -hh, 0),
			  Vector3(hw, hh, 0),  Vector3(-hw, hh, 0)]:
		corners.append(global_transform * (p + center_offset))
	return corners

func get_info() -> Dictionary:
	var d := super.get_info()
	d["size"]      = size
	d["perimeter"] = get_perimeter()
	d["normal"]    = get_normal()
	return d
