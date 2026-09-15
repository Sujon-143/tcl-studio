@tool
extends Node3D
class_name ProceduralHouseGenerator

## House architectural styles.
enum Style {
	MODERN,    # Flat roof, large windows, simple boxy shape
	CLASSIC,   # Pitched roof, symmetric windows, chimney
	COTTAGE,   # Cozy, uneven shapes, small windows, slanted roof
	URBAN      # Narrow, tall, multiple floors, flat roof with railing
}

## Random seed for deterministic variation.
@export var seed: int = 0:
	set(value):
		seed = value
		_regenerate()

## Main architectural style.
@export var style: Style = Style.MODERN:
	set(value):
		style = value
		_regenerate()

## Base width (X axis) of the house.
@export var width: float = 2.0:
	set(value):
		width = maxf(0.5, value)
		_regenerate()

## Base depth (Z axis) of the house.
@export var depth: float = 2.0:
	set(value):
		depth = maxf(0.5, value)
		_regenerate()

## Base height of walls (without roof).
@export var wall_height: float = 1.5:
	set(value):
		wall_height = maxf(0.3, value)
		_regenerate()

## Overall scale factor (multiplies all dimensions).
@export var global_scale: float = 1.0:
	set(value):
		global_scale = maxf(0.2, value)
		_regenerate()

## Whether to add color variation (random hues / saturation shifts).
@export var color_variation: bool = true:
	set(value):
		color_variation = value
		_regenerate()

## If true, uses flat/unshaded materials for a true low-poly look.
@export var low_poly_material: bool = true:
	set(value):
		low_poly_material = value
		_regenerate()

# ------------------------------------------------------------------------------
# PRIVATE VARIABLES
# ------------------------------------------------------------------------------
var _generated_nodes: Array[Node] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ------------------------------------------------------------------------------
# LIFECYCLE & CLEANUP
# ------------------------------------------------------------------------------
func _ready() -> void:
	if Engine.is_editor_hint():
		_regenerate.call_deferred()
	else:
		_regenerate()

func _exit_tree() -> void:
	_cleanup_generated_nodes()

# ------------------------------------------------------------------------------
# MAIN GENERATION LOGIC
# ------------------------------------------------------------------------------
func _regenerate() -> void:
	if not is_inside_tree():
		return
	_cleanup_generated_nodes()

	_rng = RandomNumberGenerator.new()
	_rng.seed = seed if seed != 0 else randi()

	match style:
		Style.MODERN:
			_generate_modern_house()
		Style.CLASSIC:
			_generate_classic_house()
		Style.COTTAGE:
			_generate_cottage_house()
		Style.URBAN:
			_generate_urban_house()

func _cleanup_generated_nodes() -> void:
	for node: Node in _generated_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_generated_nodes.clear()

# ------------------------------------------------------------------------------
# HELPERS — COLOR
# ------------------------------------------------------------------------------

## Shifts a color slightly in hue and saturation when color_variation is on.
## Pass a max_shift between 0.0..1.0; smaller = subtler variation.
func _vary(base: Color, max_shift: float) -> Color:
	if not color_variation:
		return base
	var h: float = fmod(base.h + _rng.randf_range(-max_shift, max_shift), 1.0)
	var s: float = clampf(base.s + _rng.randf_range(-max_shift * 0.5, max_shift * 0.5), 0.0, 1.0)
	var v: float = clampf(base.v + _rng.randf_range(-max_shift * 0.3, max_shift * 0.3), 0.0, 1.0)
	return Color.from_hsv(h, s, v)

# ------------------------------------------------------------------------------
# HELPERS — MATERIALS
# ------------------------------------------------------------------------------
func _make_material(albedo: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = albedo
	if low_poly_material:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

# ------------------------------------------------------------------------------
# HELPERS — MESH PRIMITIVES
# All `origin` parameters are the BOTTOM-CENTER of the shape (floor level).
# This is consistent across every helper so callers never double-offset.
# ------------------------------------------------------------------------------

## Adds a box with bottom-center at `origin`.
func _add_box(origin: Vector3, size: Vector3, color: Color) -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = box
	instance.material_override = _make_material(color)
	# BoxMesh is centered; shift up by half its height so base sits at origin.
	instance.position = origin + Vector3(0.0, size.y * 0.5, 0.0)
	add_child(instance)
	_generated_nodes.append(instance)

## Adds a gable (PrismMesh) or flat (BoxMesh) roof.
## `origin` = bottom-center of the roof (= top of the walls).
func _add_roof(
		origin: Vector3,
		rwidth: float,
		rdepth: float,
		rheight: float,
		color: Color,
		gable: bool = true) -> void:

	if gable:
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(rwidth, rheight, rdepth)
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.mesh = prism
		instance.material_override = _make_material(color)
		# PrismMesh is centered on its origin; shift up so base sits at origin.
		instance.position = origin + Vector3(0.0, rheight * 0.5, 0.0)
		add_child(instance)
		_generated_nodes.append(instance)
	else:
		# Flat roof: reuse _add_box (already handles bottom-center convention).
		_add_box(origin, Vector3(rwidth, rheight, rdepth), color)

## Adds a cylindrical chimney.
## `origin` = bottom of the chimney.
func _add_chimney(origin: Vector3, radius: float, height: float, color: Color) -> void:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	if low_poly_material:
		cylinder.radial_segments = 6
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = cylinder
	instance.material_override = _make_material(color)
	# CylinderMesh is centered; shift up so base sits at origin.
	instance.position = origin + Vector3(0.0, height * 0.5, 0.0)
	add_child(instance)
	_generated_nodes.append(instance)

## Adds a thin flat slab as a window pane, flush against a face.
## `origin` = center of the window (X, Y already in wall-space; Z is face position).
func _add_window(center: Vector3, win_w: float, win_h: float, face_z: float, color: Color) -> void:
	var frame_thickness: float = win_w * 0.06
	var frame_color: Color = color.darkened(0.35)

	# Outer frame
	_add_box(
		Vector3(center.x, center.y - win_h * 0.5, face_z),
		Vector3(win_w + frame_thickness * 2.0, win_h + frame_thickness * 2.0, 0.04),
		frame_color
	)
	# Glass pane (slightly proud of the frame)
	_add_box(
		Vector3(center.x, center.y - win_h * 0.5, face_z + 0.02),
		Vector3(win_w, win_h, 0.03),
		color
	)

# ------------------------------------------------------------------------------
# STYLE: MODERN
# ------------------------------------------------------------------------------
func _generate_modern_house() -> void:
	var w: float = width * global_scale
	var d: float = depth * global_scale
	var h: float = wall_height * global_scale
	var roof_h: float = 0.18 * global_scale

	var wall_color: Color = _vary(Color(0.85, 0.85, 0.90), 0.05)
	_add_box(Vector3(0.0, 0.0, 0.0), Vector3(w, h, d), wall_color)

	# Flat roof with slight overhang
	_add_roof(Vector3(0.0, h, 0.0), w + 0.08, d + 0.08, roof_h, _vary(Color(0.38, 0.38, 0.44), 0.04), false)

	var face_z: float = d * 0.5 + 0.02

	# Large panoramic window
	var win_w: float = w * 0.68
	var win_h: float = h * 0.48
	var win_cy: float = h * 0.62
	var glass_color: Color = _vary(Color(0.55, 0.72, 0.92), 0.06)
	_add_window(Vector3(0.0, win_cy, 0.0), win_w, win_h, face_z, glass_color)

	# Door — offset from center so it doesn't overlap the big window
	var door_x: float = _rng.randf_range(w * 0.15, w * 0.3) * (1.0 if _rng.randf() > 0.5 else -1.0)
	var door_w: float = w * 0.22
	var door_h: float = h * 0.72
	_add_box(Vector3(door_x, 0.0, face_z), Vector3(door_w, door_h, 0.05), _vary(Color(0.28, 0.20, 0.14), 0.04))

	# Roof parapet
	var parapet_h: float = 0.10
	var parapet_y: float = h + roof_h
	var parapet_color: Color = _vary(Color(0.50, 0.50, 0.56), 0.03)
	_add_box(Vector3(0.0, parapet_y, d * 0.5 - 0.05),  Vector3(w + 0.12, parapet_h, 0.10), parapet_color)
	_add_box(Vector3(0.0, parapet_y, -d * 0.5 + 0.05), Vector3(w + 0.12, parapet_h, 0.10), parapet_color)
	_add_box(Vector3( w * 0.5 - 0.05, parapet_y, 0.0), Vector3(0.10, parapet_h, d + 0.12), parapet_color)
	_add_box(Vector3(-w * 0.5 + 0.05, parapet_y, 0.0), Vector3(0.10, parapet_h, d + 0.12), parapet_color)

# ------------------------------------------------------------------------------
# STYLE: CLASSIC
# ------------------------------------------------------------------------------
func _generate_classic_house() -> void:
	var w: float = width * global_scale
	var d: float = depth * global_scale
	var h: float = wall_height * global_scale
	var roof_h: float = h * 0.65

	var wall_color: Color = _vary(Color(0.95, 0.90, 0.82), 0.05)
	_add_box(Vector3(0.0, 0.0, 0.0), Vector3(w, h, d), wall_color)

	var roof_color: Color = _vary(Color(0.55, 0.30, 0.25), 0.06)
	_add_roof(Vector3(0.0, h, 0.0), w + 0.12, d + 0.12, roof_h, roof_color, true)

	# Chimney — origin is on the roof surface, slightly inside the ridge.
	# Rise from h + a fraction of roof_h so it pierces through the slope.
	var chimney_base_y: float = h + roof_h * 0.35
	var chimney_height: float = roof_h * 0.75
	var chimney_color: Color = _vary(Color(0.68, 0.50, 0.40), 0.05)
	_add_chimney(
		Vector3(w * 0.38, chimney_base_y, d * 0.25),
		0.14 * global_scale,
		chimney_height,
		chimney_color
	)
	# Chimney cap (slightly wider flat box)
	_add_box(
		Vector3(w * 0.38, chimney_base_y + chimney_height, d * 0.25),
		Vector3(0.30 * global_scale, 0.06 * global_scale, 0.30 * global_scale),
		chimney_color.darkened(0.15)
	)

	var face_z: float = d * 0.5 + 0.02
	var win_color: Color = _vary(Color(0.70, 0.82, 0.96), 0.05)
	var win_w: float = w * 0.22
	var win_h: float = h * 0.34
	var win_y: float = h * 0.60

	# Two symmetric front windows
	_add_window(Vector3(-w * 0.30, win_y, 0.0), win_w, win_h, face_z, win_color)
	_add_window(Vector3( w * 0.30, win_y, 0.0), win_w, win_h, face_z, win_color)

	# Centered front door
	var door_w: float = w * 0.22
	var door_h: float = h * 0.66
	_add_box(Vector3(0.0, 0.0, face_z), Vector3(door_w, door_h, 0.05), _vary(Color(0.38, 0.24, 0.14), 0.05))

	# Optional back window
	if _rng.randf() > 0.35:
		_add_window(Vector3(0.0, win_y, 0.0), win_w, win_h, -d * 0.5 - 0.02, win_color)

# ------------------------------------------------------------------------------
# STYLE: COTTAGE
# ------------------------------------------------------------------------------
func _generate_cottage_house() -> void:
	var w: float = width * global_scale
	var d: float = depth * global_scale
	var h: float = wall_height * global_scale * _rng.randf_range(0.88, 1.10)
	var roof_h: float = h * _rng.randf_range(0.55, 0.72)

	var wall_color: Color = _vary(Color(0.88, 0.82, 0.74), 0.06)
	_add_box(Vector3(0.0, 0.0, 0.0), Vector3(w, h, d), wall_color)

	var roof_color: Color = _vary(Color(0.50, 0.35, 0.30), 0.06)
	_add_roof(Vector3(0.0, h, 0.0), w + 0.16, d + 0.16, roof_h, roof_color, true)

	var face_z: float = d * 0.5 + 0.02
	var win_color: Color = _vary(Color(0.60, 0.76, 0.90), 0.06)
	var win_w: float = w * 0.19
	var win_h: float = h * 0.28

	# Two small windows at slightly randomised heights (cottage feels hand-built)
	_add_window(
		Vector3(-w * 0.28, h * 0.55 + _rng.randf_range(-0.06, 0.06), 0.0),
		win_w, win_h, face_z, win_color
	)
	_add_window(
		Vector3( w * 0.28, h * 0.55 + _rng.randf_range(-0.06, 0.06), 0.0),
		win_w, win_h, face_z, win_color
	)

	# Door — slightly off-center
	var door_x: float = _rng.randf_range(-w * 0.18, w * 0.18)
	var door_w: float = w * 0.20
	var door_h: float = h * 0.60
	_add_box(Vector3(door_x, 0.0, face_z), Vector3(door_w, door_h, 0.05), _vary(Color(0.44, 0.30, 0.20), 0.06))

	# Front step
	_add_box(
		Vector3(door_x, 0.0, face_z + 0.08),
		Vector3(door_w * 1.30, 0.08, 0.22),
		_vary(Color(0.70, 0.62, 0.52), 0.04)
	)

	# Optional small side extension (shed / storage bump)
	if _rng.randf() > 0.50:
		var ext_w: float = w * _rng.randf_range(0.28, 0.40)
		var ext_d: float = d * _rng.randf_range(0.30, 0.50)
		var ext_h: float = h * _rng.randf_range(0.50, 0.70)
		var ext_side: float = (w * 0.5 + ext_w * 0.5) * (1.0 if _rng.randf() > 0.5 else -1.0)
		_add_box(Vector3(ext_side, 0.0, 0.0), Vector3(ext_w, ext_h, ext_d), _vary(wall_color, 0.04))
		_add_roof(Vector3(ext_side, ext_h, 0.0), ext_w + 0.10, ext_d + 0.10, ext_h * 0.45, roof_color, true)

# ------------------------------------------------------------------------------
# STYLE: URBAN
# ------------------------------------------------------------------------------
func _generate_urban_house() -> void:
	var w: float = width  * global_scale * _rng.randf_range(0.70, 0.90)
	var d: float = depth  * global_scale * _rng.randf_range(0.80, 1.20)
	var h: float = wall_height * global_scale * _rng.randf_range(1.40, 1.80)
	var roof_h: float = 0.14 * global_scale

	var wall_color: Color = _vary(Color(0.74, 0.78, 0.82), 0.04)
	_add_box(Vector3(0.0, 0.0, 0.0), Vector3(w, h, d), wall_color)

	# Flat roof
	_add_roof(Vector3(0.0, h, 0.0), w + 0.06, d + 0.06, roof_h, _vary(Color(0.34, 0.34, 0.40), 0.03), false)

	# Roof railing
	var rail_h: float = 0.14
	var rail_y: float = h + roof_h
	var rail_color: Color = _vary(Color(0.50, 0.50, 0.56), 0.03)
	_add_box(Vector3(0.0, rail_y, d * 0.5 - 0.05),  Vector3(w + 0.10, rail_h, 0.09), rail_color)
	_add_box(Vector3(0.0, rail_y, -d * 0.5 + 0.05), Vector3(w + 0.10, rail_h, 0.09), rail_color)
	_add_box(Vector3( w * 0.5 - 0.05, rail_y, 0.0), Vector3(0.09, rail_h, d + 0.10), rail_color)
	_add_box(Vector3(-w * 0.5 + 0.05, rail_y, 0.0), Vector3(0.09, rail_h, d + 0.10), rail_color)

	var face_z: float = d * 0.5 + 0.02
	var win_color: Color = _vary(Color(0.62, 0.80, 0.96), 0.06)
	var win_w: float = w * 0.20
	# Window height kept small enough to never reach roof_h zone.
	var win_h: float = h * 0.18

	# Three floors of windows — evenly spaced within safe wall zone.
	# Floor band: 0.10*h (above door) to 0.88*h (below roof).
	var usable_h: float = h * 0.78
	var floor_count: int = 3
	for floor_i: int in range(floor_count):
		var t: float = float(floor_i) / float(floor_count - 1)
		# win_cy = vertical center of this floor's window row
		var win_cy: float = h * 0.18 + usable_h * t
		# Two windows per floor, symmetric
		_add_window(Vector3(-w * 0.28, win_cy, 0.0), win_w, win_h, face_z, win_color)
		_add_window(Vector3( w * 0.28, win_cy, 0.0), win_w, win_h, face_z, win_color)

	# Ground-floor door
	var door_w: float = w * 0.28
	var door_h: float = h * 0.28
	_add_box(Vector3(0.0, 0.0, face_z), Vector3(door_w, door_h, 0.05), _vary(Color(0.38, 0.44, 0.50), 0.04))

	# Optional AC / utility box on side wall
	if _rng.randf() > 0.45:
		_add_box(
			Vector3(w * 0.5 + 0.04, h * 0.28, 0.0),
			Vector3(0.14, 0.28, 0.38),
			_vary(Color(0.60, 0.60, 0.65), 0.03)
		)
