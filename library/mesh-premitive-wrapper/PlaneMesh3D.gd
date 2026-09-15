@tool
extends MeshBase3D
class_name PlaneMesh3D

## A MeshInstance3D with an inline PlaneMesh.

@export_group("Plane")

@export var size: Vector2 = Vector2(2.0, 2.0):
	set(v):
		size = v
		_build_mesh()

@export_range(1, 128) var subdivide_width: int = 0:
	set(v):
		subdivide_width = v
		_build_mesh()

@export_range(1, 128) var subdivide_depth: int = 0:
	set(v):
		subdivide_depth = v
		_build_mesh()

@export var center_offset: Vector3 = Vector3.ZERO:
	set(v):
		center_offset = v
		_build_mesh()

## Plane orientation axis
@export_enum("Y (horizontal)", "X (vertical YZ)", "Z (vertical XY)") var orientation: int = 0:
	set(v):
		orientation = v
		_build_mesh()

func _build_mesh() -> void:
	var m := PlaneMesh.new()
	m.size             = size
	m.subdivide_width  = subdivide_width
	m.subdivide_depth  = subdivide_depth
	m.center_offset    = center_offset
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
	return 0.0  # Infinitely thin

## Perimeter of the plane rectangle.
func get_perimeter() -> float:
	return 2.0 * (size.x + size.y)

## World-space normal based on orientation.
func get_normal() -> Vector3:
	var local_n: Vector3
	match orientation:
		0: local_n = Vector3.UP
		1: local_n = Vector3.RIGHT
		2: local_n = Vector3.BACK
		_: local_n = Vector3.UP
	return global_transform.basis * local_n

## World-space corners (clockwise from top-left when viewed from above).
func get_corners() -> Array[Vector3]:
	var hw := size.x * 0.5
	var hd := size.y * 0.5
	var corners: Array[Vector3] = []
	match orientation:
		0:
			for p in [Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd),
					  Vector3(hw, 0, hd),  Vector3(-hw, 0, hd)]:
				corners.append(global_transform * (p + center_offset))
		1:
			for p in [Vector3(0, -hw, -hd), Vector3(0, hw, -hd),
					  Vector3(0, hw, hd),  Vector3(0, -hw, hd)]:
				corners.append(global_transform * (p + center_offset))
		2:
			for p in [Vector3(-hw, -hd, 0), Vector3(hw, -hd, 0),
					  Vector3(hw, hd, 0),  Vector3(-hw, hd, 0)]:
				corners.append(global_transform * (p + center_offset))
	return corners

## Project a world-space point onto the plane, returns the closest in-plane point.
func project_point(world_point: Vector3) -> Vector3:
	var n := get_normal()
	var d := n.dot(global_position)
	return world_point - n * (n.dot(world_point) - d)

func get_info() -> Dictionary:
	var d := super.get_info()
	d["size"]      = size
	d["perimeter"] = get_perimeter()
	d["normal"]    = get_normal()
	return d
