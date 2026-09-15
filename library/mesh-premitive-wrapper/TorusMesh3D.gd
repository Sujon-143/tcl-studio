@tool
extends MeshBase3D
class_name TorusMesh3D

## A MeshInstance3D with an inline TorusMesh.

@export_group("Torus")

@export_range(0.01, 100.0) var inner_radius: float = 0.4:
	set(v):
		inner_radius = v
		_build_mesh()

@export_range(0.01, 100.0) var outer_radius: float = 0.6:
	set(v):
		outer_radius = v
		_build_mesh()

@export_range(3, 128) var rings: int = 32:
	set(v):
		rings = v
		_build_mesh()

@export_range(3, 128) var ring_segments: int = 16:
	set(v):
		ring_segments = v
		_build_mesh()

func _build_mesh() -> void:
	var m := TorusMesh.new()
	m.inner_radius  = inner_radius
	m.outer_radius  = outer_radius
	m.rings         = rings
	m.ring_segments = ring_segments
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

## Tube radius (half the cross-section diameter).
func get_tube_radius() -> float:
	return (outer_radius - inner_radius) * 0.5

## Major radius (centre of ring to centre of tube).
func get_major_radius() -> float:
	return (outer_radius + inner_radius) * 0.5

## Surface area: 4π² R r
func get_surface_area() -> float:
	return 4.0 * PI * PI * get_major_radius() * get_tube_radius()

## Volume: 2π² R r²
func get_volume() -> float:
	var R := get_major_radius()
	var r := get_tube_radius()
	return 2.0 * PI * PI * R * r * r

## World-space point on the torus surface.
## theta: angle around the main ring (0..TAU)
## phi:   angle around the tube cross-section (0..TAU)
func point_on_surface(theta: float, phi: float) -> Vector3:
	var R := get_major_radius()
	var r := get_tube_radius()
	var local_pt := Vector3(
		(R + r * cos(phi)) * cos(theta),
		r * sin(phi),
		(R + r * cos(phi)) * sin(theta)
	)
	return global_transform * local_pt

## Outward unit normal at (theta, phi).
func normal_at(theta: float, phi: float) -> Vector3:
	var center_of_tube := global_transform * Vector3(
		get_major_radius() * cos(theta),
		0.0,
		get_major_radius() * sin(theta)
	)
	return (point_on_surface(theta, phi) - center_of_tube).normalized()

func get_info() -> Dictionary:
	var d := super.get_info()
	d["inner_radius"] = inner_radius
	d["outer_radius"] = outer_radius
	d["major_radius"] = get_major_radius()
	d["tube_radius"]  = get_tube_radius()
	return d
