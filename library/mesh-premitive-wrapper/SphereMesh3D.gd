@tool
extends MeshBase3D
class_name SphereMesh3D

## A MeshInstance3D with an inline SphereMesh.
## All mesh and material properties are exposed directly in the editor.

@export_group("Sphere")

@export_range(0.01, 100.0) var radius: float = 0.5:
	set(v):
		radius = v
		_build_mesh()

@export_range(0.01, 100.0) var height: float = 1.0:
	set(v):
		height = v
		_build_mesh()

@export_range(3, 128) var radial_segments: int = 32:
	set(v):
		radial_segments = v
		_build_mesh()

@export_range(2, 128) var rings: int = 16:
	set(v):
		rings = v
		_build_mesh()

@export var is_hemisphere: bool = false:
	set(v):
		is_hemisphere = v
		_build_mesh()

func _build_mesh() -> void:
	var m := SphereMesh.new()
	m.radius          = radius
	m.height          = height
	m.radial_segments = radial_segments
	m.rings           = rings
	m.is_hemisphere   = is_hemisphere
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

## Surface area of a full sphere: 4πr²
func get_surface_area() -> float:
	if is_hemisphere:
		return 3.0 * PI * radius * radius   # curved + flat base
	return 4.0 * PI * radius * radius

## Volume: (4/3)πr³
func get_volume() -> float:
	if is_hemisphere:
		return (2.0 / 3.0) * PI * pow(radius, 3.0)
	return (4.0 / 3.0) * PI * pow(radius, 3.0)

## Great-circle circumference.
func get_circumference() -> float:
	return 2.0 * PI * radius

## Returns a world-space point on the surface at spherical coords (theta, phi).
## theta: polar angle from Y-up (0 = top, PI = bottom)
## phi:   azimuthal angle around Y (0 = +Z)
func point_on_surface(theta: float, phi: float) -> Vector3:
	var local_pt := Vector3(
		radius * sin(theta) * sin(phi),
		radius * cos(theta),
		radius * sin(theta) * cos(phi)
	)
	return global_transform * local_pt

## Outward unit normal at a surface point (world space).
func normal_at(theta: float, phi: float) -> Vector3:
	return (point_on_surface(theta, phi) - global_position).normalized()

## True if world_point is strictly inside the sphere.
func contains_point_exact(world_point: Vector3) -> bool:
	return global_position.distance_to(world_point) < radius

## Distance from world_point to the sphere surface (negative = inside).
func signed_distance(world_point: Vector3) -> float:
	return global_position.distance_to(world_point) - radius

func get_info() -> Dictionary:
	var d := super.get_info()
	d["radius"]       = radius
	d["height"]       = height
	d["is_hemisphere"] = is_hemisphere
	d["circumference"] = get_circumference()
	return d
