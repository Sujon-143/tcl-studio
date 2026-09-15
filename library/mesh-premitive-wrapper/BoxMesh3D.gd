@tool
extends MeshBase3D
class_name BoxMesh3D

## A MeshInstance3D with an inline BoxMesh.

@export_group("Box")

@export var size: Vector3 = Vector3(1, 1, 1):
	set(v):
		size = v
		_build_mesh()

@export_range(1, 64) var subdivide_width: int = 0:
	set(v):
		subdivide_width = v
		_build_mesh()

@export_range(1, 64) var subdivide_height: int = 0:
	set(v):
		subdivide_height = v
		_build_mesh()

@export_range(1, 64) var subdivide_depth: int = 0:
	set(v):
		subdivide_depth = v
		_build_mesh()

func _build_mesh() -> void:
	var m := BoxMesh.new()
	m.size             = size
	m.subdivide_width  = subdivide_width
	m.subdivide_height = subdivide_height
	m.subdivide_depth  = subdivide_depth
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

func get_surface_area() -> float:
	return 2.0 * (size.x * size.y + size.y * size.z + size.z * size.x)

func get_volume() -> float:
	return size.x * size.y * size.z

## Diagonal of the box.
func get_diagonal() -> float:
	return size.length()

## Face centre in world space. face: "top","bottom","front","back","left","right"
func get_face_center(face: String) -> Vector3:
	var h := size * 0.5
	var local_pt: Vector3
	match face:
		"top":    local_pt = Vector3(0,  h.y, 0)
		"bottom": local_pt = Vector3(0, -h.y, 0)
		"front":  local_pt = Vector3(0, 0,  h.z)
		"back":   local_pt = Vector3(0, 0, -h.z)
		"right":  local_pt = Vector3( h.x, 0, 0)
		"left":   local_pt = Vector3(-h.x, 0, 0)
		_: local_pt = Vector3.ZERO
	return global_transform * local_pt

## All 8 corners in world space.
func get_corners() -> Array[Vector3]:
	var h := size * 0.5
	var corners: Array[Vector3] = []
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				corners.append(global_transform * Vector3(h.x * sx, h.y * sy, h.z * sz))
	return corners

## True if world_point is strictly inside the box (local-space test).
func contains_point_exact(world_point: Vector3) -> bool:
	var local := global_transform.inverse() * world_point
	var h := size * 0.5
	return abs(local.x) < h.x and abs(local.y) < h.y and abs(local.z) < h.z

func get_info() -> Dictionary:
	var d := super.get_info()
	d["size"]     = size
	d["diagonal"] = get_diagonal()
	return d
