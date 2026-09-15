@tool
extends MeshBase3D
class_name PrismMesh3D

## A MeshInstance3D with an inline PrismMesh (triangular prism).

@export_group("Prism")

@export_range(0.0, 1.0) var left_to_right: float = 0.5:
	set(v):
		left_to_right = v
		_build_mesh()

@export var size: Vector3 = Vector3(1.0, 1.0, 1.0):
	set(v):
		size = v
		_build_mesh()

@export_range(0, 64) var subdivide_width: int = 0:
	set(v):
		subdivide_width = v
		_build_mesh()

@export_range(0, 64) var subdivide_height: int = 0:
	set(v):
		subdivide_height = v
		_build_mesh()

@export_range(0, 64) var subdivide_depth: int = 0:
	set(v):
		subdivide_depth = v
		_build_mesh()

func _build_mesh() -> void:
	var m := PrismMesh.new()
	m.left_to_right    = left_to_right
	m.size             = size
	m.subdivide_width  = subdivide_width
	m.subdivide_height = subdivide_height
	m.subdivide_depth  = subdivide_depth
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

## Cross-sectional triangle area (base * height / 2).
func get_cross_section_area() -> float:
	return size.x * size.y * 0.5

func get_volume() -> float:
	return get_cross_section_area() * size.z

## Approximate surface area (two triangular ends + three rectangular faces).
func get_surface_area() -> float:
	var tri_area := get_cross_section_area()
	# Three rectangular faces: bottom, left slope, right slope
	var base  := size.x
	var h     := size.y
	var depth := size.z
	var ridge_x := left_to_right * base
	var left_slope  := sqrt(ridge_x * ridge_x + h * h)
	var right_slope := sqrt((base - ridge_x) * (base - ridge_x) + h * h)
	return 2.0 * tri_area + (base + left_slope + right_slope) * depth

## Ridge (apex) position in world space.
func get_ridge_center() -> Vector3:
	var local_pt := Vector3(
		lerpf(-size.x * 0.5, size.x * 0.5, left_to_right),
		size.y * 0.5,
		0.0
	)
	return global_transform * local_pt

func get_info() -> Dictionary:
	var d := super.get_info()
	d["size"]          = size
	d["left_to_right"] = left_to_right
	d["cross_section"] = get_cross_section_area()
	d["ridge"]         = get_ridge_center()
	return d
