@tool
extends MeshBase3D
class_name PointMesh3D

## A MeshInstance3D with an inline PointMesh.
## Renders as a single screen-space point.

@export_group("Point")

@export_range(1.0, 128.0) var point_size: float = 8.0:
	set(v): point_size = v; _apply_material()

func _build_mesh() -> void:
	mesh = PointMesh.new()
	_apply_material()

func _apply_material() -> void:
	if _mat == null:
		_mat = StandardMaterial3D.new()
	_mat.use_point_size             = true
	_mat.point_size                 = point_size
	_mat.albedo_color               = Color(color.r, color.g, color.b, opacity)
	_mat.emission_enabled           = emission_enabled
	_mat.emission                   = emission_color
	_mat.emission_energy_multiplier = emission_energy
	_mat.shading_mode               = (
		BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded
		else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	)
	material_override = _mat

func get_surface_area() -> float: return 0.0
func get_volume() -> float:       return 0.0

func get_point_position() -> Vector3:
	return global_position

func get_info() -> Dictionary:
	var d := super.get_info()
	d["point_size"] = point_size
	return d
