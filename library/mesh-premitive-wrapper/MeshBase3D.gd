@tool
extends BaseMeshInstance3D
class_name MeshBase3D

## Shared base for all primitive mesh tools.
## Exposes material and geometry utilities. Subclasses call _build_mesh() to
## set `mesh`, then _apply_material() is called automatically.



# ── Exported visual properties ────────────────────────────────────────────────

@export_group("Material")

@export var color: Color = Color.WHITE:
	set(v): color = v; _apply_material()

@export_range(0.0, 1.0) var opacity: float = 1.0:
	set(v): opacity = v; _apply_material()

@export_range(0.0, 1.0) var metallic: float = 0.0:
	set(v): metallic = v; _apply_material()

@export_range(0.0, 1.0) var roughness: float = 0.8:
	set(v): roughness = v; _apply_material()

@export var emission_enabled: bool = false:
	set(v): emission_enabled = v; _apply_material()

@export var emission_color: Color = Color.WHITE:
	set(v): emission_color = v; _apply_material()

@export_range(0.0, 16.0) var emission_energy: float = 1.0:
	set(v): emission_energy = v; _apply_material()

@export_group("Shading")


@export var unshaded: bool = false:
	set(v): unshaded = v; _apply_material()

@export var double_sided: bool = false:
	set(v): double_sided = v; _apply_material()

# ── Internal ──────────────────────────────────────────────────────────────────

var _mat: StandardMaterial3D

func _ready() -> void:
	_build_mesh()

func _build_mesh() -> void:
	pass  # Subclass sets self.mesh then calls _apply_material()

func _apply_material() -> void:
	var mat=material_override
	if _mat == null or not _mat is StandardMaterial3D:
		_mat = StandardMaterial3D.new()
	
	_mat.albedo_color = Color(color.r, color.g, color.b, opacity)
	_mat.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
		if opacity < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	)
	_mat.metallic                   = metallic
	_mat.roughness                  = roughness
	_mat.emission_enabled           = emission_enabled
	_mat.emission                   = emission_color
	_mat.emission_energy_multiplier = emission_energy
	_mat.shading_mode               = (
		BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded
		else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	)
	_mat.cull_mode = (
		BaseMaterial3D.CULL_DISABLED if double_sided
		else BaseMaterial3D.CULL_BACK
	)

	# material_override applies to all surfaces without needing surface indices
	material_override = _mat
# ── Shared geometry utilities ─────────────────────────────────────────────────

## World-space AABB.
func get_aabb_world() -> AABB:
	if mesh == null: return AABB()
	return get_transform() * mesh.get_aabb()

## World-space centre (same as global_position for centred primitives).
func get_center() -> Vector3:
	return global_position

## Override in subclasses for exact analytic formula.
func get_surface_area() -> float: return 0.0
func get_volume() -> float:       return 0.0

## Half-extents in local space.
func get_extents() -> Vector3:
	if mesh == null: return Vector3.ZERO
	return mesh.get_aabb().size * 0.5

## True if world-space point is inside the AABB.
func contains_point(world_point: Vector3) -> bool:
	return get_aabb_world().has_point(world_point)

## Closest point on the AABB surface to a world-space point.
func closest_surface_point(world_point: Vector3) -> Vector3:
	var aabb := get_aabb_world()
	return Vector3(
		clamp(world_point.x, aabb.position.x, aabb.end.x),
		clamp(world_point.y, aabb.position.y, aabb.end.y),
		clamp(world_point.z, aabb.position.z, aabb.end.z)
	)

## Distance from world_point to the nearest AABB surface point.
func distance_to_point(world_point: Vector3) -> float:
	return world_point.distance_to(closest_surface_point(world_point))

## Convenience: set material_override to a custom material externally.
func set_custom_material(mat: Material) -> void:
	material_override = mat

## Restore the auto-managed material after set_custom_material.
func restore_material() -> void:
	material_override = _mat

## Summary dictionary.
func get_info() -> Dictionary:
	return {
		"node":         name,
		"class":        get_class(),
		"position":     global_position,
		"rotation_deg": global_rotation_degrees,
		"scale":        global_scale,
		"surface_area": get_surface_area(),
		"volume":       get_volume(),
		"extents":      get_extents(),
		"aabb":         get_aabb_world(),
	}
