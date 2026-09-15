@tool
extends MeshBase3D
class_name CapsuleMesh3D

## A MeshInstance3D with an inline CapsuleMesh.

@export_group("Capsule")

@export_range(0.01, 100.0) var radius: float = 0.5:
	set(v):
		radius = v
		_build_mesh()

@export_range(0.01, 200.0) var height: float = 2.0:
	set(v):
		height = v
		_build_mesh()

@export_range(3, 128) var radial_segments: int = 16:
	set(v):
		radial_segments = v
		_build_mesh()

@export_range(1, 64) var rings: int = 8:
	set(v):
		rings = v
		_build_mesh()

func _build_mesh() -> void:
	var m := CapsuleMesh.new()
	m.radius          = radius
	m.height          = height
	m.radial_segments = radial_segments
	m.rings           = rings
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

## Cylindrical body height (total height minus the two hemispherical caps).
func get_cylinder_height() -> float:
	return maxf(0.0, height - 2.0 * radius)

## Surface area = cylinder band + two hemisphere caps.
func get_surface_area() -> float:
	var cyl_h := get_cylinder_height()
	return 2.0 * PI * radius * cyl_h + 4.0 * PI * radius * radius

## Volume = cylinder section + full sphere.
func get_volume() -> float:
	var cyl_h := get_cylinder_height()
	return PI * radius * radius * cyl_h + (4.0 / 3.0) * PI * pow(radius, 3.0)

## World-space top dome centre.
func get_top_center() -> Vector3:
	return global_transform * Vector3(0, height * 0.5, 0)

## World-space bottom dome centre.
func get_bottom_center() -> Vector3:
	return global_transform * Vector3(0, -height * 0.5, 0)

## True if world_point is inside the capsule (exact test).
func contains_point_exact(world_point: Vector3) -> bool:
	var local := global_transform.inverse() * world_point
	var cyl_h := get_cylinder_height()
	var clamped_y :float= clamp(local.y, -cyl_h * 0.5, cyl_h * 0.5)
	return Vector3(local.x, clamped_y, local.z).distance_to(local) <= radius

func get_info() -> Dictionary:
	var d := super.get_info()
	d["radius"]          = radius
	d["height"]          = height
	d["cylinder_height"] = get_cylinder_height()
	return d
