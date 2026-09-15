@tool
extends MeshBase3D
class_name TubeTrailMesh3D

## A MeshInstance3D with an inline TubeTrailMesh.
## Typically used with GPUParticles3D trail sections.

@export_group("Tube Trail")

@export_range(0.01, 100.0) var radius: float = 0.1:
	set(v):
		radius = v
		_build_mesh()

@export_range(1, 128) var radial_steps: int = 8:
	set(v):
		radial_steps = v
		_build_mesh()

@export_range(1, 128) var sections: int = 5:
	set(v):
		sections = v
		_build_mesh()

@export_range(0.01, 100.0) var section_length: float = 0.2:
	set(v):
		section_length = v
		_build_mesh()

@export_range(1, 32) var section_rings: int = 3:
	set(v):
		section_rings = v
		_build_mesh()

@export var curve: Curve:
	set(v):
		curve = v
		_build_mesh()

func _build_mesh() -> void:
	var m := TubeTrailMesh.new()
	m.radius         = radius
	m.radial_steps   = radial_steps
	m.sections       = sections
	m.section_length = section_length
	m.section_rings  = section_rings
	if curve: m.curve = curve
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

## Total length of the trail.
func get_total_length() -> float:
	return sections * section_length

## Lateral surface area (open cylinder approximation).
func get_surface_area() -> float:
	return 2.0 * PI * radius * get_total_length()

func get_volume() -> float:
	return PI * radius * radius * get_total_length()

## World-space point along the trail centre axis at normalised t ∈ [0,1].
func point_along_trail(t: float) -> Vector3:
	var local_pt := Vector3(0.0, lerpf(-get_total_length() * 0.5, get_total_length() * 0.5, t), 0.0)
	return global_transform * local_pt

func get_info() -> Dictionary:
	var d := super.get_info()
	d["radius"]       = radius
	d["total_length"] = get_total_length()
	d["sections"]     = sections
	return d
