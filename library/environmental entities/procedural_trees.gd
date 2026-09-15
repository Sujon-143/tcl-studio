@tool
extends Node3D
class_name ProceduralTreeGenerator

## Different visual styles for the tree.
enum Style {
	PINE,    # Conical, pine-like shape with tiered branches
	ROUND,   # Dense, spherical canopy with visible branch structure
	STYLIZED # Abstract, low-poly fantasy look with floating clusters
}

## Random seed for deterministic variation.
@export var seed: int = 0 :
	set(value):
		seed = value
		_regenerate()

## Base style of the tree.
@export var style: Style = Style.PINE :
	set(value):
		style = value
		_regenerate()

## Height of the trunk (world units).
@export var trunk_height: float = 2.0 :
	set(value):
		trunk_height = maxf(0.2, value)
		_regenerate()

## Radius of the trunk at the base.
@export var trunk_radius: float = 0.4 :
	set(value):
		trunk_radius = maxf(0.05, value)
		_regenerate()

## Overall size multiplier for leaves / canopy.
@export var leaf_size: float = 1.0 :
	set(value):
		leaf_size = maxf(0.2, value)
		_regenerate()

## Density (number) of leaf clusters / tiers.
@export var leaf_density: float = 0.5 :
	set(value):
		leaf_density = clampf(value, 0.1, 1.0)
		_regenerate()

## Randomly shift leaf colors for a more organic look.
@export var color_variation: bool = true :
	set(value):
		color_variation = value
		_regenerate()

## Low-poly look (flat shading, reduced segments).
@export var low_poly: bool = true :
	set(value):
		low_poly = value
		_regenerate()

## How much the trunk curves / leans. 0 = perfectly straight.
@export_range(0.0, 1.0) var trunk_curve: float = 0.2 :
	set(value):
		trunk_curve = clampf(value, 0.0, 1.0)
		_regenerate()

## Direction the trunk leans (radians around Y-axis).
@export_range(0.0, 6.28) var lean_direction: float = 0.0 :
	set(value):
		lean_direction = value
		_regenerate()

## How pronounced the root flare is at the base.
@export_range(0.0, 1.0) var root_flare: float = 0.4 :
	set(value):
		root_flare = clampf(value, 0.0, 1.0)
		_regenerate()

## How much side branches spread out from the trunk.
@export_range(0.0, 1.0) var branch_spread: float = 0.5 :
	set(value):
		branch_spread = clampf(value, 0.0, 1.0)
		_regenerate()

# ------------------------------------------------------------------------------

# Stores generated nodes so we can clean them up.
var _generated_nodes: Array[Node] = []

# Trunk segment world positions, computed during trunk generation.
# Each entry is the top-center position of that segment.
var _trunk_segments: Array[Vector3] = []

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
	_trunk_segments.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed if seed != 0 else rng.seed

	match style:
		Style.PINE:
			_generate_pine_tree(rng)
		Style.ROUND:
			_generate_round_tree(rng)
		Style.STYLIZED:
			_generate_stylized_tree(rng)


func _cleanup_generated_nodes() -> void:
	for node in _generated_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_generated_nodes.clear()


# ------------------------------------------------------------------------------
# TRUNK BUILDER — segmented, curved trunk with root flare
# Returns an array of world-space positions (bottom of each segment → top).
# ------------------------------------------------------------------------------

## Builds a segmented trunk that curves toward lean_direction.
## Returns an array of Vector3 world-space positions for each segment joint
## (index 0 = ground level, last index = top of trunk).
func _build_curved_trunk(
		rng: RandomNumberGenerator,
		seg_count: int,
		trunk_col: Color,
		bark_col: Color,
		curve_override: float = -1.0) -> Array[Vector3]:

	var positions: Array[Vector3] = []
	var seg_height := trunk_height / float(seg_count)

	# Allow callers to pass a curve value without touching the exported property.
	var effective_curve := curve_override if curve_override >= 0.0 else trunk_curve

	# Total lean displacement at trunk top.
	var total_lean_x := sin(lean_direction) * effective_curve * trunk_height * 0.15
	var total_lean_z := cos(lean_direction) * effective_curve * trunk_height * 0.15

	# Ground position.
	positions.append(Vector3.ZERO)

	for i in range(seg_count):
		var t_bot := float(i) / float(seg_count)       # 0..1 along trunk
		var t_top := float(i + 1) / float(seg_count)

		# Radius tapers from base → top.
		# Root flare adds extra width at the very bottom segments.
		var flare_mult := 1.0 + root_flare * maxf(0.0, 1.0 - t_bot * 4.0)
		var r_bot :float= trunk_radius * flare_mult * lerp(1.0, 0.15, t_bot)
		var r_top :float= trunk_radius * lerp(1.0, 0.15, t_top)

		# Slight random wobble per segment — scale by effective_curve so
		# a straight trunk (curve=0) has zero wobble.
		var wobble_x := rng.randf_range(-0.03, 0.03) * trunk_radius * effective_curve
		var wobble_z := rng.randf_range(-0.03, 0.03) * trunk_radius * effective_curve

		# bot_pos is always the previously appended position (chain is continuous).
		var bot_pos := positions[i]

		# top_pos: move straight up one segment, add proportional lean + wobble.
		var top_pos := Vector3(
			total_lean_x * t_top + wobble_x,
			seg_height * (i + 1),
			total_lean_z * t_top + wobble_z
		)
		positions.append(top_pos)

		# Build mesh segment.
		var mid_pos   := (bot_pos + top_pos) / 2.0
		var dir       := (top_pos - bot_pos).normalized()
		var seg_len   := (top_pos - bot_pos).length()
		var col       := trunk_col if i < seg_count - 1 else bark_col
		var mesh_inst := _create_tapered_cylinder(r_bot, r_top, seg_len, col)
		# CylinderMesh grows along local +Y — align Y to dir.
		mesh_inst.position = mid_pos
		mesh_inst.transform.basis = _basis_from_y(dir)
		add_child(mesh_inst)
		_generated_nodes.append(mesh_inst)

	return positions


# ------------------------------------------------------------------------------
# BRANCH HELPER — grows a single branch stub from a trunk position
# Returns the tip position of the branch.
# ------------------------------------------------------------------------------

func _add_branch(
		base_pos: Vector3,
		angle_y: float,       # horizontal direction
		angle_up: float,      # elevation from horizontal (radians)
		length: float,
		base_rad: float,
		tip_rad: float,
		color: Color) -> Vector3:

	var dir := Vector3(
		cos(angle_y) * cos(angle_up),
		sin(angle_up),
		sin(angle_y) * cos(angle_up)
	).normalized()

	var tip := base_pos + dir * length
	var mid := (base_pos + tip) / 2.0

	var mesh_inst := _create_tapered_cylinder(base_rad, tip_rad, length, color)
	mesh_inst.position = mid

	# CylinderMesh grows along local +Y — align Y to dir.
	mesh_inst.transform.basis = _basis_from_y(dir)

	add_child(mesh_inst)
	_generated_nodes.append(mesh_inst)
	return tip


# ------------------------------------------------------------------------------
# MESH HELPERS
# ------------------------------------------------------------------------------

# Builds an orthonormal Basis whose +Y axis points along `dir`.
# Works for any direction including near-vertical (which look_at can't handle).
func _basis_from_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	# Choose a reference vector that is never parallel to y.
	var ref := Vector3.FORWARD if abs(y.dot(Vector3.RIGHT)) > 0.9 else Vector3.RIGHT
	var x   := ref.cross(y).normalized()
	var z   := y.cross(x).normalized()
	return Basis(x, y, z)


func _create_tapered_cylinder(bottom_rad: float, top_rad: float, height: float, color: Color) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.bottom_radius = bottom_rad
	cylinder.top_radius   = top_rad
	cylinder.height       = height
	if low_poly:
		cylinder.radial_segments = 5
		cylinder.rings = 2
	else:
		cylinder.radial_segments = 12
		cylinder.rings = 6

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if low_poly:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = cylinder
	mesh_inst.material_override = mat
	return mesh_inst


func _create_cone(bottom_rad: float, height: float, color: Color) -> MeshInstance3D:
	var cone := CylinderMesh.new()
	cone.bottom_radius = bottom_rad
	cone.top_radius   = 0.0
	cone.height       = height
	if low_poly:
		cone.radial_segments = 5
		cone.rings = 1
	else:
		cone.radial_segments = 10
		cone.rings = 3

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if low_poly:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var inst := MeshInstance3D.new()
	inst.mesh = cone
	inst.material_override = mat
	return inst


func _create_leaf_cluster(
		pos: Vector3,
		scale_vec: Vector3,
		color: Color,
		rng: RandomNumberGenerator) -> void:

	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	if low_poly:
		sphere.radial_segments = 6
		sphere.rings = 4
	else:
		sphere.radial_segments = 14
		sphere.rings = 10

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if low_poly:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.rim_enabled = true
		mat.rim = 0.4
		mat.rim_tint = 0.7

	var inst := MeshInstance3D.new()
	inst.mesh = sphere
	inst.material_override = mat
	inst.position = pos
	inst.scale = scale_vec
	if style == Style.STYLIZED:
		inst.rotate_y(rng.randf_range(0.0, TAU))
	add_child(inst)
	_generated_nodes.append(inst)


func _leaf_color(base: Color, rng: RandomNumberGenerator) -> Color:
	if not color_variation:
		return base
	return base.lerp(
		Color(base.r + rng.randf_range(-0.1, 0.1),
			  base.g + rng.randf_range(-0.1, 0.1),
			  base.b + rng.randf_range(-0.05, 0.05)),
		rng.randf_range(0.0, 0.6)
	)


# ------------------------------------------------------------------------------
# STYLE: PINE
# Segmented curved trunk + tiered rings of branch stubs + cone leaf clusters.
# ------------------------------------------------------------------------------

func _generate_pine_tree(rng: RandomNumberGenerator) -> void:
	var trunk_col   := Color(0.45, 0.30, 0.18)
	var bark_col    := Color(0.55, 0.38, 0.22)
	var seg_count   := 6 if low_poly else 10

	var trunk_positions := _build_curved_trunk(rng, seg_count, trunk_col, bark_col, -1.0)

	# Number of tiers = driven by leaf_density.
	var tiers := int(lerp(3.0, 8.0, leaf_density))

	for tier in range(tiers):
		# t=0 → near top, t=1 → near bottom of foliage zone
		var t := float(tier) / float(max(tiers - 1, 1))

		# Sample a position along the upper 70% of the trunk.
		var trunk_t    := 0.3 + t * 0.65  # 0.3..0.95 along trunk
		var seg_idx    := int(trunk_t * (trunk_positions.size() - 1))
		seg_idx        = clampi(seg_idx, 0, trunk_positions.size() - 2)
		var seg_frac   := (trunk_t * (trunk_positions.size() - 1)) - seg_idx
		var attach_pos := trunk_positions[seg_idx].lerp(trunk_positions[seg_idx + 1], seg_frac)

		# Cone tier: gets smaller toward the top.
		var tier_scale    := leaf_size * (1.0 - t * 0.55) * 0.9
		var cone_radius   := tier_scale * 0.7
		var cone_height   := tier_scale * 1.1

		# Ring of branches around trunk at this height.
		var branch_count  := rng.randi_range(3, 5)
		var branch_len    := tier_scale * branch_spread * 0.6
		var branch_rad    :float= trunk_radius * lerp(0.18, 0.08, trunk_t)

		for b in range(branch_count):
			var ba_y   := TAU * b / float(branch_count) + rng.randf_range(-0.2, 0.2)
			var ba_up  :float= lerp(0.1, -0.25, t) + rng.randf_range(-0.1, 0.1)  # droop more at bottom
			var tip    := _add_branch(attach_pos, ba_y, ba_up,
					branch_len, branch_rad, branch_rad * 0.4, bark_col)

			# Cone at branch tip.
			var cone_inst := _create_cone(cone_radius * 0.65, cone_height * 0.9,
					_leaf_color(Color(0.28, 0.62, 0.22), rng))
			cone_inst.position = tip + Vector3(0, cone_height * 0.3, 0)
			add_child(cone_inst)
			_generated_nodes.append(cone_inst)

		# Central cone for this tier (on trunk).
		var main_cone := _create_cone(cone_radius, cone_height,
				_leaf_color(Color(0.30, 0.65, 0.20), rng))
		main_cone.position = attach_pos + Vector3(0, cone_height * 0.35, 0)
		add_child(main_cone)
		_generated_nodes.append(main_cone)

	# Top spike.
	var top_pos    := trunk_positions[-1]
	var spike      := _create_cone(leaf_size * 0.22, leaf_size * 0.75,
			_leaf_color(Color(0.35, 0.70, 0.22), rng))
	spike.position = top_pos + Vector3(0, leaf_size * 0.2, 0)
	add_child(spike)
	_generated_nodes.append(spike)


# ------------------------------------------------------------------------------
# STYLE: ROUND
# Segmented trunk + radiating branches + sphere clusters at tips.
# ------------------------------------------------------------------------------

func _generate_round_tree(rng: RandomNumberGenerator) -> void:
	var trunk_col   := Color(0.50, 0.36, 0.22)
	var bark_col    := Color(0.60, 0.44, 0.28)
	var seg_count   := 5 if low_poly else 8

	var trunk_positions := _build_curved_trunk(rng, seg_count, trunk_col, bark_col, -1.0)

	# Main branches: grow from upper 50% of trunk.
	var branch_count := int(lerp(4.0, 10.0, leaf_density))
	var main_col     := Color(0.33, 0.63, 0.28)

	for i in range(branch_count):
		var trunk_t  := rng.randf_range(0.45, 0.92)
		var seg_idx  := int(trunk_t * (trunk_positions.size() - 1))
		seg_idx      = clampi(seg_idx, 0, trunk_positions.size() - 2)
		var seg_frac := (trunk_t * (trunk_positions.size() - 1)) - seg_idx
		var att_pos  := trunk_positions[seg_idx].lerp(trunk_positions[seg_idx + 1], seg_frac)

		var ba_y     := rng.randf_range(0.0, TAU)
		# Upper branches reach upward, lower ones spread outward.
		var ba_up    :float= lerp(deg_to_rad(40.0), deg_to_rad(-10.0), trunk_t) + rng.randf_range(-0.2, 0.2)
		var b_len    := rng.randf_range(0.5, 1.1) * leaf_size * branch_spread
		var b_rad    :float= trunk_radius * lerp(0.20, 0.09, trunk_t)

		var tip := _add_branch(att_pos, ba_y, ba_up, b_len, b_rad, b_rad * 0.35, bark_col)

		# Optional sub-branch.
		if rng.randf() < 0.5 and branch_spread > 0.3:
			var sub_ba_y  := ba_y + rng.randf_range(-0.6, 0.6)
			var sub_ba_up := ba_up + rng.randf_range(-0.2, 0.3)
			var sub_len   := b_len * rng.randf_range(0.4, 0.7)
			var sub_tip   := _add_branch(tip, sub_ba_y, sub_ba_up, sub_len,
					b_rad * 0.4, b_rad * 0.1, bark_col)
			# Cluster at sub-tip.
			var s_scale := rng.randf_range(0.45, 0.75) * leaf_size
			_create_leaf_cluster(sub_tip,
					Vector3(s_scale, s_scale * rng.randf_range(0.8, 1.2), s_scale),
					_leaf_color(main_col, rng), rng)

		# Main cluster at branch tip.
		var c_scale := rng.randf_range(0.6, 1.1) * leaf_size
		_create_leaf_cluster(tip,
				Vector3(c_scale, c_scale * rng.randf_range(0.85, 1.3), c_scale),
				_leaf_color(main_col, rng), rng)

	# Fill-in cluster at the very top.
	var top_scale := leaf_size * 0.7
	_create_leaf_cluster(trunk_positions[-1] + Vector3(0, top_scale * 0.3, 0),
			Vector3(top_scale, top_scale * 1.1, top_scale),
			_leaf_color(main_col, rng), rng)


# ------------------------------------------------------------------------------
# STYLE: STYLIZED
# Twisted trunk + irregular angled branches + non-uniform floating clusters.
# ------------------------------------------------------------------------------

func _generate_stylized_tree(rng: RandomNumberGenerator) -> void:
	var trunk_col   := Color(0.55, 0.40, 0.28)
	var bark_col    := Color(0.65, 0.48, 0.32)
	var seg_count   := 4 if low_poly else 7

	# Exaggerate curve for stylized look — pass as override so the exported
	# property is never mutated (mutating it would re-trigger _regenerate()).
	var stylized_curve := minf(trunk_curve + 0.3, 1.0)
	var trunk_positions := _build_curved_trunk(rng, seg_count, trunk_col, bark_col, stylized_curve)

	var base_hue := rng.randf_range(0.26, 0.44)
	var sat      := rng.randf_range(0.55, 0.85)
	var val      := rng.randf_range(0.50, 0.78)

	var cluster_count := int(lerp(3.0, 9.0, leaf_density))

	for i in range(cluster_count):
		# Attach along the full trunk height for a sprawling look.
		var trunk_t  := rng.randf_range(0.2, 0.95)
		var seg_idx  := int(trunk_t * (trunk_positions.size() - 1))
		seg_idx      = clampi(seg_idx, 0, trunk_positions.size() - 2)
		var seg_frac := (trunk_t * (trunk_positions.size() - 1)) - seg_idx
		var att_pos  := trunk_positions[seg_idx].lerp(trunk_positions[seg_idx + 1], seg_frac)

		var ba_y  := rng.randf_range(0.0, TAU)
		var ba_up := rng.randf_range(deg_to_rad(-20.0), deg_to_rad(60.0))
		var b_len := rng.randf_range(0.4, 1.1) * leaf_size * branch_spread
		var b_rad := trunk_radius * rng.randf_range(0.08, 0.22)

		var tip := _add_branch(att_pos, ba_y, ba_up, b_len, b_rad, b_rad * 0.2, bark_col)

		# Non-uniform cluster scale for stylized appeal.
		var sx := rng.randf_range(0.5, 1.3) * leaf_size * 0.7
		var sy := rng.randf_range(0.8, 1.7) * leaf_size * 0.7
		var sz := rng.randf_range(0.5, 1.3) * leaf_size * 0.7

		var leaf_col := Color.from_hsv(
				base_hue + rng.randf_range(-0.06, 0.10), sat, val)
		if not color_variation:
			leaf_col = Color(0.38, 0.68, 0.35)

		_create_leaf_cluster(tip, Vector3(sx, sy, sz), leaf_col, rng)

		# Occasionally add a second floating cluster near the first.
		if rng.randf() < 0.4:
			var offset := Vector3(
				rng.randf_range(-0.3, 0.3) * leaf_size,
				rng.randf_range(0.1, 0.5) * leaf_size,
				rng.randf_range(-0.3, 0.3) * leaf_size
			)
			var leaf_col2 := Color.from_hsv(
					base_hue + rng.randf_range(-0.04, 0.08), sat * 0.9, val * 1.05)
			_create_leaf_cluster(tip + offset,
					Vector3(sx, sy, sz) * rng.randf_range(0.5, 0.8),
					leaf_col2, rng)
