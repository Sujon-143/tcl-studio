@tool
extends SphereMesh3D
class_name Atom3D

## A single atom in a ball-and-stick or spacefill model.
## Set `element_symbol` in the Inspector (or via code) and the node
## self-configures its size and CPK colour automatically.
##
## Scale factor: 1 Godot unit ≈ 1 Å for this library, then multiplied
## by `display_scale` for readability.

# ── Exports ───────────────────────────────────────────────────────────────────

@export_group("Atom")

## IUPAC element symbol, e.g. "C", "H", "O". Case-sensitive.
@export var element_symbol: String = "C":
	set(v):
		element_symbol = v
		_apply_element()
	get:
		return element_symbol

## Rendering mode. BALL_AND_STICK uses covalent radius (smaller);
## SPACEFILL uses van der Waals radius (larger, fills bonding space).
@export_enum("Ball and stick", "Spacefill") var display_mode: int = 0:
	set(v):
		display_mode = v
		_apply_element()
	get:
		return display_mode

## Global scale multiplier applied on top of the physical radius.
## Default 0.4 keeps atoms readable while leaving room for bonds.
@export_range(0.05, 5.0) var display_scale: float = 0.4:
	set(v):
		display_scale = v
		_apply_element()
	get:
		return display_scale	

## When true, the CPK colour is locked and won't be overridden on element change.
@export var lock_color: bool = false:
	set(v):
		lock_color = v
	get:
		return lock_color

# ── Runtime state ─────────────────────────────────────────────────────────────

## The element data dict cached after the last successful lookup.
var element_data: Dictionary = {}

## Emitted when the element_symbol is changed to a valid element.
signal element_changed(symbol: String, data: Dictionary)

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_apply_element()

# ── Core setup ────────────────────────────────────────────────────────────────

func _apply_element() -> void:
	if element_symbol.is_empty():
		return
	if not ChemistryData.has_element(element_symbol):
		push_error("Atom3D: unknown element '%s'" % element_symbol)
		return

	element_data = ChemistryData.element(element_symbol)

	var r: float
	match display_mode:
		0: r = element_data["covalent_radius"]   # ball-and-stick
		1: r = element_data["vdw_radius"]         # spacefill
		_: r = element_data["covalent_radius"]

	# SphereMesh3D radius is exposed as `radius`.
	radius = r * display_scale
	height = radius * 2.0   # keep SphereMesh height in sync

	if not lock_color:
		color = element_data["color"]

	element_changed.emit(element_symbol, element_data)

# ── Geometry helpers ──────────────────────────────────────────────────────────

## World-space centre of the atom (same as global_position).
func get_atom_center() -> Vector3:
	return global_position

## Physical covalent radius in Å × display_scale.
func get_display_radius() -> float:
	return radius

## Returns this atom's element symbol.
func get_symbol() -> String:
	return element_symbol

## Returns the atom's electronegativity (Pauling scale).
func get_electronegativity() -> float:
	return element_data.get("electronegativity", 0.0)

## Returns the atom's atomic mass in atomic mass units.
func get_mass() -> float:
	return element_data.get("mass", 0.0)

## Estimated bond vector toward another atom (unit, world space).
func direction_to(other: Atom3D) -> Vector3:
	return (other.global_position - global_position).normalized()

## Distance to another atom (centre-to-centre, world units).
func distance_to_atom(other: Atom3D) -> float:
	return global_position.distance_to(other.global_position)

# ── Physics hook ─────────────────────────────────────────────────────────────
## Override in a subclass or attach a script to add RigidBody3D /
## StaticBody3D behaviour. The placeholder below makes it easy to find.

func _physics_hook() -> void:
	pass   # TODO: add rigid-body or spring physics in a subclass

# ── Info ─────────────────────────────────────────────────────────────────────

func get_info() -> Dictionary:
	var d := super.get_info()
	d["element"]           = element_symbol
	d["element_name"]      = element_data.get("name", "?")
	d["atomic_number"]     = element_data.get("atomic_number", 0)
	d["mass_u"]            = get_mass()
	d["electronegativity"] = get_electronegativity()
	d["display_radius"]    = get_display_radius()
	d["display_mode"]      = ["ball_and_stick", "spacefill"][display_mode]
	return d
