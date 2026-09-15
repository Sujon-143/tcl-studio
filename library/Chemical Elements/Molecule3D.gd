@tool
extends Node3D
class_name Molecule3D

## Container node that instantiates atoms and bonds from a preset definition.
##
## Usage (code):
##   var mol := Molecule3D.new()
##   add_child(mol)
##   mol.preset_key = "benzene"
##
## Usage (Inspector):
##   Add a Molecule3D node → set Preset Key → molecule builds itself.
##
## The node owns all child Atom3D and Bond3D nodes. Calling `rebuild()`
## tears down and reconstructs everything from the current preset.

# ── Exports ───────────────────────────────────────────────────────────────────

@export_group("Molecule")

## Key into MoleculePresets (e.g. "water", "benzene", "co2").
@export var preset_key: String = "water":
	set(v):
		preset_key = v
		rebuild()

## Uniform scale applied to all atom positions (Å → Godot units).
## 1.0 = 1 Å per Godot unit. Increase for better visibility.
@export_range(0.1, 10.0) var angstrom_scale: float = 1.0:
	set(v):
		angstrom_scale = v
		rebuild()

## Atom display mode forwarded to every Atom3D.
## 0 = Ball-and-stick,  1 = Spacefill.
@export_enum("Ball and stick", "Spacefill") var atom_display_mode: int = 0:
	set(v):
		atom_display_mode = v
		_apply_display_mode()

## Per-atom display scale forwarded to every Atom3D.
@export_range(0.05, 5.0) var atom_display_scale: float = 0.4:
	set(v):
		atom_display_scale = v
		_apply_display_mode()

## When true, bonds are visible.
@export var show_bonds: bool = true:
	set(v):
		show_bonds = v
		_apply_bond_visibility()

# ── Runtime state ─────────────────────────────────────────────────────────────

## Ordered list of Atom3D nodes (matches preset "atoms" array index).
var atoms: Array[Atom3D] = []

## Ordered list of Bond3D nodes (matches preset "bonds" array index).
var bonds: Array[Bond3D] = []

## The currently loaded preset dict (read-only; use preset_key to change).
var current_preset: Dictionary = {}

## Emitted after a successful rebuild.
signal molecule_built(preset: Dictionary)

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	rebuild()

# ── Public API ────────────────────────────────────────────────────────────────

## Tear down and rebuild from the current preset_key.
func rebuild() -> void:
	_clear_children()
	atoms.clear()
	bonds.clear()

	if preset_key.is_empty():
		return
	if not MoleculePresets.has_preset(preset_key):
		push_error("Molecule3D: unknown preset '%s'" % preset_key)
		return

	current_preset = MoleculePresets.get_preset(preset_key)
	_build_atoms()
	_build_bonds()
	molecule_built.emit(current_preset)

## All available preset keys.
func available_presets() -> Array:
	return MoleculePresets.keys()

## Returns the Atom3D at index i, or null.
func get_atom(i: int) -> Atom3D:
	if i < 0 or i >= atoms.size():
		return null
	return atoms[i]

## Returns every Atom3D with the given element symbol.
func get_atoms_by_element(symbol: String) -> Array[Atom3D]:
	var result: Array[Atom3D] = []
	for a in atoms:
		if a.get_symbol() == symbol:
			result.append(a)
	return result

## Returns the Bond3D at index i, or null.
func get_bond(i: int) -> Bond3D:
	if i < 0 or i >= bonds.size():
		return null
	return bonds[i]

## Molecular formula string from the current preset.
func get_formula() -> String:
	return current_preset.get("formula", "")

## Display name from the current preset.
func get_display_name() -> String:
	return current_preset.get("name", preset_key)

## Approximate molecular mass (sum of atomic masses, no electron correction).
func get_molecular_mass() -> float:
	var total := 0.0
	for a in atoms:
		total += a.get_mass()
	return total

## Geometric centre of all atoms in world space.
func get_geometric_center() -> Vector3:
	if atoms.is_empty():
		return global_position
	var sum := Vector3.ZERO
	for a in atoms:
		sum += a.global_position
	return sum / float(atoms.size())

## Largest distance from the geometric centre to any atom surface.
func get_bounding_radius() -> float:
	var centre := get_geometric_center()
	var r_max := 0.0
	for a in atoms:
		var d := centre.distance_to(a.global_position) + a.get_display_radius()
		if d > r_max:
			r_max = d
	return r_max

## Summary dictionary.
func get_info() -> Dictionary:
	return {
		"name":             get_display_name(),
		"formula":          get_formula(),
		"atom_count":       atoms.size(),
		"bond_count":       bonds.size(),
		"molecular_mass_u": get_molecular_mass(),
		"bounding_radius":  get_bounding_radius(),
		"geometric_center": get_geometric_center(),
	}

# ── Internal builders ─────────────────────────────────────────────────────────

func _build_atoms() -> void:
	var atom_data: Array = current_preset.get("atoms", [])
	for entry in atom_data:
		var atom := Atom3D.new()
		atom.element_symbol  = entry["symbol"]
		atom.display_mode    = atom_display_mode
		atom.display_scale   = atom_display_scale
		atom.position        = entry["position"] * angstrom_scale
		add_child(atom)
		atoms.append(atom)

func _build_bonds() -> void:
	var bond_data: Array = current_preset.get("bonds", [])
	for entry in bond_data:
		var idx_a: int = entry["a"]
		var idx_b: int = entry["b"]
		if idx_a >= atoms.size() or idx_b >= atoms.size():
			push_error("Molecule3D: bond references out-of-range atom index")
			continue

		var bond := Bond3D.new()
		add_child(bond)

		# Paths are relative to the Bond3D node (which is a sibling of atoms
		# under this Molecule3D). Use the atom node names.
		bond.atom_a_path = bond.get_path_to(atoms[idx_a])
		bond.atom_b_path = bond.get_path_to(atoms[idx_b])

		# Map BondOrder enum value to export index (0-based).
		match entry["order"]:
			ChemistryData.BondOrder.SINGLE:   bond.bond_order = 0
			ChemistryData.BondOrder.DOUBLE:   bond.bond_order = 1
			ChemistryData.BondOrder.TRIPLE:   bond.bond_order = 2
			ChemistryData.BondOrder.AROMATIC: bond.bond_order = 3

		bond.visible = show_bonds
		bonds.append(bond)

func _apply_display_mode() -> void:
	for a in atoms:
		a.display_mode  = atom_display_mode
		a.display_scale = atom_display_scale

func _apply_bond_visibility() -> void:
	for b in bonds:
		b.visible = show_bonds

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
