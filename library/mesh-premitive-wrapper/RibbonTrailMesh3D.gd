@tool
extends MeshBase3D
class_name RibbonTrailMesh3D

## A MeshInstance3D with an inline RibbonTrailMesh.

@export_group("Ribbon Trail")

@export_range(0.01, 100.0) var size: float = 1.0:
	set(v):
		size = v
		_build_mesh()

@export_range(1, 128) var sections: int = 5:
	set(v):
		sections = v
		_build_mesh()

@export_range(0.01, 100.0) var section_length: float = 0.2:
	set(v):
		section_length = v
		_build_mesh()

@export_range(1, 32) var section_segments: int = 3:
	set(v):
		section_segments = v
		_build_mesh()

@export var curve: Curve:
	set(v):
		curve = v
		_build_mesh()

@export_enum("Faces (double-sided)", "Trail (single-sided)") var shape: int = 0:
	set(v):
		shape = v
		_build_mesh()

func _build_mesh() -> void:
	var m := RibbonTrailMesh.new()
	m.size             = size
	m.sections         = sections
	m.section_length   = section_length
	m.section_segments = section_segments
	if curve: m.curve  = curve
	m.shape = RibbonTrailMesh.SHAPE_FLAT if shape == 0 else RibbonTrailMesh.SHAPE_CROSS
	mesh = m
	_apply_material()

# ── Geometry ──────────────────────────────────────────────────────────────────

func get_total_length() -> float:
	return sections * section_length

func get_surface_area() -> float:
	return size * get_total_length()

func get_volume() -> float:
	return 0.0  # Flat ribbon

## World-space centre point at normalised t ∈ [0,1] along ribbon length.
func point_along_ribbon(t: float) -> Vector3:
	var local_pt := Vector3(0.0, lerpf(-get_total_length() * 0.5, get_total_length() * 0.5, t), 0.0)
	return global_transform * local_pt

func get_info() -> Dictionary:
	var d := super.get_info()
	d["size"]         = size
	d["total_length"] = get_total_length()
	d["sections"]     = sections
	return d
