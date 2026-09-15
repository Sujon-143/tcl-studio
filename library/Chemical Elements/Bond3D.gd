@tool
extends CylinderMesh3D
class_name Bond3D

## A chemical bond rendered as one or more cylinders between two Atom3D nodes.
## Positioning and rotation are computed automatically from the atom positions.
##
## For double/triple bonds the cylinders are offset perpendicular to the bond
## axis. Call `refresh()` any time atom positions change, or connect to
## Atom3D.element_changed if you need automatic reactivity.
##
## Physics hook: override `_physics_hook()` or replace `atom_a` / `atom_b`
## with NodePaths to RigidBody3D nodes and add a spring joint in a subclass.

# ── Exports ───────────────────────────────────────────────────────────────────

@export_group("Bond")

## Bond order: 0=single, 1=double, 2=triple, 3=aromatic.
@export_enum("Single", "Double", "Triple", "Aromatic") var bond_order: int = 0:
	set(v):
		bond_order = v
		_update_bond()

## NodePath to the first atom. Must point to an Atom3D.
@export var atom_a_path: NodePath = NodePath():
	set(v):
		atom_a_path = v
		_update_bond()

## NodePath to the second atom. Must point to an Atom3D.
@export var atom_b_path: NodePath = NodePath():
	set(v):
		atom_b_path = v
		_update_bond()

## When true, uses the exported `color` instead of the ChemistryData default.
@export var custom_color: bool = false:
	set(v):
		custom_color = v
		_update_bond()

## Radial segments per cylinder. Lower = faster, higher = smoother.
@export_range(4, 32) var bond_segments: int = 12:
	set(v):
		bond_segments = v
		_update_bond()

# ── Internal ──────────────────────────────────────────────────────────────────

var _order_enum: ChemistryData.BondOrder:
	get:
		match bond_order:
			0: return ChemistryData.BondOrder.SINGLE
			1: return ChemistryData.BondOrder.DOUBLE
			2: return ChemistryData.BondOrder.TRIPLE
			3: return ChemistryData.BondOrder.AROMATIC
			_: return ChemistryData.BondOrder.SINGLE

var _extra_cylinders: Array[CylinderMesh3D] = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_update_bond()

# ── Public API ────────────────────────────────────────────────────────────────

## Rebuild geometry after moving atoms at runtime.
func refresh() -> void:
	_update_bond()

## Set both atom paths at once and rebuild.
func connect_atoms(a: NodePath, b: NodePath) -> void:
	atom_a_path = a
	atom_b_path = b
	_update_bond()

## Returns the Atom3D at atom_a_path, or null.
func get_atom_a() -> Atom3D:
	if atom_a_path.is_empty() or not has_node(atom_a_path):
		return null
	var n := get_node(atom_a_path)
	return n if n is Atom3D else null

## Returns the Atom3D at atom_b_path, or null.
func get_atom_b() -> Atom3D:
	if atom_b_path.is_empty() or not has_node(atom_b_path):
		return null
	var n := get_node(atom_b_path)
	return n if n is Atom3D else null

## World-space midpoint of the bond.
func get_midpoint() -> Vector3:
	var a := get_atom_a()
	var b := get_atom_b()
	if a == null or b == null:
		return global_position
	return (a.global_position + b.global_position) * 0.5

## Bond length in world units (centre-to-centre).
func get_bond_length() -> float:
	var a := get_atom_a()
	var b := get_atom_b()
	if a == null or b == null:
		return 0.0
	return a.global_position.distance_to(b.global_position)

# ── Internal geometry ─────────────────────────────────────────────────────────

func _update_bond() -> void:
	_clear_extra_cylinders()

	var a := get_atom_a()
	var b := get_atom_b()
	if a == null or b == null:
		return

	var ord := _order_enum
	var visual := ChemistryData.bond_visual(ord)
	var bond_r: float = visual["radius"]
	var offset: float = visual["offset"]

	if not custom_color:
		color = ChemistryData.bond_color(ord)
	radial_segments = bond_segments

	var pos_a := a.global_position
	var pos_b := b.global_position
	var diff  := pos_b - pos_a

	if diff.length_squared() < 1e-6:
		return

	var bond_len := diff.length()

	match ord:
		ChemistryData.BondOrder.SINGLE, ChemistryData.BondOrder.AROMATIC:
			_place_cylinder(self, pos_a, pos_b, bond_r, bond_len)

		ChemistryData.BondOrder.DOUBLE:
			var perp := _perpendicular(diff.normalized()) * offset
			_place_cylinder(self,           pos_a + perp, pos_b + perp, bond_r, bond_len)
			var e1 := _make_extra_cylinder()
			_place_cylinder(e1, pos_a - perp, pos_b - perp, bond_r, bond_len)

		ChemistryData.BondOrder.TRIPLE:
			_place_cylinder(self, pos_a, pos_b, bond_r, bond_len)
			var perp := _perpendicular(diff.normalized()) * offset
			var e1 := _make_extra_cylinder()
			_place_cylinder(e1, pos_a + perp, pos_b + perp, bond_r, bond_len)
			var e2 := _make_extra_cylinder()
			_place_cylinder(e2, pos_a - perp, pos_b - perp, bond_r, bond_len)

	_physics_hook(a, b)

func _place_cylinder(cyl: CylinderMesh3D, from: Vector3, to: Vector3,
		r: float, bond_len: float) -> void:
	var mid := (from + to) * 0.5
	var dir  := (to - from).normalized()

	cyl.top_radius    = r
	cyl.bottom_radius = r
	cyl.height        = bond_len
	cyl.cap_top       = false
	cyl.cap_bottom    = false
	cyl.global_position = mid

	# Align the Y-up cylinder with `dir`.
	var up := Vector3.UP
	if abs(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var right := up.cross(dir).normalized()
	var fwd   := dir.cross(right)
	cyl.global_transform.basis = Basis(right, dir, fwd)

func _make_extra_cylinder() -> CylinderMesh3D:
	var cyl := CylinderMesh3D.new()
	cyl.color     = ChemistryData.bond_color(_order_enum) if not custom_color else color
	cyl.roughness = roughness
	cyl.metallic  = metallic
	get_parent().add_child(cyl)
	_extra_cylinders.append(cyl)
	return cyl

func _clear_extra_cylinders() -> void:
	for cyl in _extra_cylinders:
		if is_instance_valid(cyl):
			cyl.queue_free()
	_extra_cylinders.clear()

static func _perpendicular(v: Vector3) -> Vector3:
	if abs(v.x) < 0.9:
		return v.cross(Vector3.RIGHT).normalized()
	return v.cross(Vector3.UP).normalized()

# ── Physics hook ─────────────────────────────────────────────────────────────

## Override in a subclass to add spring/constraint physics.
## Called after geometry is placed with the two resolved Atom3D nodes.
func _physics_hook(_a: Atom3D, _b: Atom3D) -> void:
	pass   # TODO: implement spring joint in a physics subclass

# ── Info ─────────────────────────────────────────────────────────────────────

func get_info() -> Dictionary:
	var d := super.get_info()
	var a := get_atom_a()
	var b := get_atom_b()
	d["bond_order"]  = _order_enum
	d["bond_length"] = get_bond_length()
	d["atom_a"]      = a.get_symbol() if a else "?"
	d["atom_b"]      = b.get_symbol() if b else "?"
	d["midpoint"]    = get_midpoint()
	return d
