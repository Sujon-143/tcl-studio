@tool
extends MeshBase3D
class_name CylinderMesh3D

## A MeshInstance3D with an inline CylinderMesh.

@export_group("Cylinder")

@export_range(0.01, 100.0) var top_radius: float = 0.5:
	set(v):
		top_radius = v
		_build_mesh()

@export_range(0.01, 100.0) var bottom_radius: float = 0.5:
	set(v):
		bottom_radius = v
		_build_mesh()

@export_range(0.01, 200.0) var height: float = 2.0:
	set(v):
		height = v
		_build_mesh()

@export_range(3, 128) var radial_segments: int = 16:
	set(v):
		radial_segments = v
		_build_mesh()

@export_range(1, 64) var rings: int = 1:
	set(v):
		rings = v
		_build_mesh()

@export var cap_top: bool = true:
	set(v):
		cap_top = v
		_build_mesh()

@export var cap_bottom: bool = true:
	set(v):
		cap_bottom = v
		_build_mesh()

func _build_mesh() -> void:
	var m := CylinderMesh.new()
	m.top_radius      = top_radius
	m.bottom_radius   = bottom_radius
	m.height          = height
	m.radial_segments = radial_segments
	m.rings           = rings
	m.cap_top         = cap_top
	m.cap_bottom      = cap_bottom
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

## Lateral (side) surface area of a truncated cone.
func get_lateral_area() -> float:
	var slant := sqrt(pow(height, 2.0) + pow(top_radius - bottom_radius, 2.0))
	return PI * (top_radius + bottom_radius) * slant

func get_surface_area() -> float:
	var area := get_lateral_area()
	if cap_top:    area += PI * top_radius * top_radius
	if cap_bottom: area += PI * bottom_radius * bottom_radius
	return area

## Volume of a truncated cone (r1, r2, h).
func get_volume() -> float:
	return (PI * height / 3.0) * (
		top_radius * top_radius +
		top_radius * bottom_radius +
		bottom_radius * bottom_radius
	)

## Average radius at a normalised height t ∈ [0,1] (0=bottom, 1=top).
func radius_at(t: float) -> float:
	return lerpf(bottom_radius, top_radius, clampf(t, 0.0, 1.0))

## World-space point on the lateral surface at height fraction t and angle a (radians).
func point_on_surface(t: float, angle: float) -> Vector3:
	var r := radius_at(t)
	var local_pt := Vector3(r * cos(angle), lerpf(-height * 0.5, height * 0.5, t), r * sin(angle))
	return global_transform * local_pt

## World-space centre of the top cap.
func get_top_center() -> Vector3:
	return global_transform * Vector3(0, height * 0.5, 0)

## World-space centre of the bottom cap.
func get_bottom_center() -> Vector3:
	return global_transform * Vector3(0, -height * 0.5, 0)

func get_info() -> Dictionary:
	var d := super.get_info()
	d["top_radius"]    = top_radius
	d["bottom_radius"] = bottom_radius
	d["height"]        = height
	d["lateral_area"]  = get_lateral_area()
	return d
