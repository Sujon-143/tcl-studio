@tool
extends RefCounted
class_name MoleculePresets

## Hard-coded molecular geometry presets for the chemistry library.
##
## Each preset is a Dictionary with:
##   "name"   String          display name
##   "formula" String         chemical formula
##   "atoms"  Array[Dict]     { symbol, position: Vector3 }
##   "bonds"  Array[Dict]     { a: int, b: int, order: BondOrder }
##
## Coordinates are in Ångströms (1 Å = 0.1 nm). The origin is the
## geometric centre of the molecule.
##
## Usage:
##   var preset := MoleculePresets.get("water")
##   # → { name, formula, atoms, bonds }

const _PRESETS: Dictionary = {

	# ── Water  H₂O ─────────────────────────────────────────────────────────
	# Bent geometry, bond angle 104.5°, O-H bond length 0.96 Å
	"water": {
		"name": "Water", "formula": "H₂O",
		"atoms": [
			{ "symbol": "O", "position": Vector3( 0.000,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3( 0.757,  0.586,  0.000) },
			{ "symbol": "H", "position": Vector3(-0.757,  0.586,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 2, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Methane  CH₄ ───────────────────────────────────────────────────────
	# Tetrahedral, bond angle 109.5°, C-H bond length 1.09 Å
	"methane": {
		"name": "Methane", "formula": "CH₄",
		"atoms": [
			{ "symbol": "C", "position": Vector3( 0.000,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3( 0.629,  0.629,  0.629) },
			{ "symbol": "H", "position": Vector3(-0.629, -0.629,  0.629) },
			{ "symbol": "H", "position": Vector3(-0.629,  0.629, -0.629) },
			{ "symbol": "H", "position": Vector3( 0.629, -0.629, -0.629) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 2, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 3, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 4, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Carbon dioxide  CO₂ ────────────────────────────────────────────────
	# Linear, C=O bond length 1.16 Å
	"co2": {
		"name": "Carbon dioxide", "formula": "CO₂",
		"atoms": [
			{ "symbol": "O", "position": Vector3(-1.160,  0.000,  0.000) },
			{ "symbol": "C", "position": Vector3( 0.000,  0.000,  0.000) },
			{ "symbol": "O", "position": Vector3( 1.160,  0.000,  0.000) },
		],
		"bonds": [
			{ "a": 1, "b": 0, "order": ChemistryData.BondOrder.DOUBLE },
			{ "a": 1, "b": 2, "order": ChemistryData.BondOrder.DOUBLE },
		],
	},

	# ── Ammonia  NH₃ ───────────────────────────────────────────────────────
	# Trigonal pyramidal, bond angle 107°, N-H bond 1.01 Å
	"ammonia": {
		"name": "Ammonia", "formula": "NH₃",
		"atoms": [
			{ "symbol": "N", "position": Vector3( 0.000,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3( 0.939,  0.000, -0.333) },
			{ "symbol": "H", "position": Vector3(-0.470,  0.813, -0.333) },
			{ "symbol": "H", "position": Vector3(-0.470, -0.813, -0.333) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 2, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 3, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Ethane  C₂H₆ ───────────────────────────────────────────────────────
	# Staggered conformation, C-C 1.54 Å, C-H 1.09 Å
	"ethane": {
		"name": "Ethane", "formula": "C₂H₆",
		"atoms": [
			{ "symbol": "C", "position": Vector3(-0.770,  0.000,  0.000) },
			{ "symbol": "C", "position": Vector3( 0.770,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.160,  1.027,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.160, -0.514,  0.890) },
			{ "symbol": "H", "position": Vector3(-1.160, -0.514, -0.890) },
			{ "symbol": "H", "position": Vector3( 1.160,  0.514,  0.890) },
			{ "symbol": "H", "position": Vector3( 1.160,  0.514, -0.890) },
			{ "symbol": "H", "position": Vector3( 1.160, -1.027,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 2, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 3, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 4, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 5, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 6, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 7, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Ethylene  C₂H₄ ─────────────────────────────────────────────────────
	# Planar, C=C double bond 1.34 Å, C-H 1.09 Å
	"ethylene": {
		"name": "Ethylene", "formula": "C₂H₄",
		"atoms": [
			{ "symbol": "C", "position": Vector3(-0.670,  0.000,  0.000) },
			{ "symbol": "C", "position": Vector3( 0.670,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.230,  0.930,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.230, -0.930,  0.000) },
			{ "symbol": "H", "position": Vector3( 1.230,  0.930,  0.000) },
			{ "symbol": "H", "position": Vector3( 1.230, -0.930,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.DOUBLE },
			{ "a": 0, "b": 2, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 3, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 4, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 5, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Acetylene  C₂H₂ ────────────────────────────────────────────────────
	# Linear, C≡C triple bond 1.20 Å, C-H 1.06 Å
	"acetylene": {
		"name": "Acetylene", "formula": "C₂H₂",
		"atoms": [
			{ "symbol": "H", "position": Vector3(-2.060,  0.000,  0.000) },
			{ "symbol": "C", "position": Vector3(-1.060,  0.000,  0.000) },
			{ "symbol": "C", "position": Vector3( 1.060,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3( 2.060,  0.000,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 2, "order": ChemistryData.BondOrder.TRIPLE },
			{ "a": 2, "b": 3, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Benzene  C₆H₆ ──────────────────────────────────────────────────────
	# Regular hexagon, C-C aromatic 1.40 Å, C-H 1.09 Å
	"benzene": {
		"name": "Benzene", "formula": "C₆H₆",
		"atoms": [
			{ "symbol": "C", "position": Vector3( 1.400,  0.000,  0.000) },
			{ "symbol": "C", "position": Vector3( 0.700,  1.212,  0.000) },
			{ "symbol": "C", "position": Vector3(-0.700,  1.212,  0.000) },
			{ "symbol": "C", "position": Vector3(-1.400,  0.000,  0.000) },
			{ "symbol": "C", "position": Vector3(-0.700, -1.212,  0.000) },
			{ "symbol": "C", "position": Vector3( 0.700, -1.212,  0.000) },
			{ "symbol": "H", "position": Vector3( 2.490,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3( 1.245,  2.156,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.245,  2.156,  0.000) },
			{ "symbol": "H", "position": Vector3(-2.490,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.245, -2.156,  0.000) },
			{ "symbol": "H", "position": Vector3( 1.245, -2.156,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.AROMATIC },
			{ "a": 1, "b": 2, "order": ChemistryData.BondOrder.AROMATIC },
			{ "a": 2, "b": 3, "order": ChemistryData.BondOrder.AROMATIC },
			{ "a": 3, "b": 4, "order": ChemistryData.BondOrder.AROMATIC },
			{ "a": 4, "b": 5, "order": ChemistryData.BondOrder.AROMATIC },
			{ "a": 5, "b": 0, "order": ChemistryData.BondOrder.AROMATIC },
			{ "a": 0, "b": 6,  "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 7,  "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 2, "b": 8,  "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 3, "b": 9,  "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 4, "b": 10, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 5, "b": 11, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Hydrogen chloride  HCl ─────────────────────────────────────────────
	"hcl": {
		"name": "Hydrogen chloride", "formula": "HCl",
		"atoms": [
			{ "symbol": "H",  "position": Vector3(-0.640,  0.000,  0.000) },
			{ "symbol": "Cl", "position": Vector3( 0.640,  0.000,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Hydrogen fluoride  HF ──────────────────────────────────────────────
	"hf": {
		"name": "Hydrogen fluoride", "formula": "HF",
		"atoms": [
			{ "symbol": "H", "position": Vector3(-0.460,  0.000,  0.000) },
			{ "symbol": "F", "position": Vector3( 0.460,  0.000,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Formaldehyde  CH₂O ─────────────────────────────────────────────────
	# Planar, C=O 1.21 Å, C-H 1.10 Å, H-C-H 116°
	"formaldehyde": {
		"name": "Formaldehyde", "formula": "CH₂O",
		"atoms": [
			{ "symbol": "C", "position": Vector3( 0.000,  0.000,  0.000) },
			{ "symbol": "O", "position": Vector3( 1.210,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3(-0.540,  0.937,  0.000) },
			{ "symbol": "H", "position": Vector3(-0.540, -0.937,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.DOUBLE },
			{ "a": 0, "b": 2, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 3, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Hydrogen peroxide  H₂O₂ ────────────────────────────────────────────
	# Dihedral 112°, O-O 1.45 Å, O-H 0.97 Å
	"h2o2": {
		"name": "Hydrogen peroxide", "formula": "H₂O₂",
		"atoms": [
			{ "symbol": "O", "position": Vector3(-0.725,  0.000,  0.000) },
			{ "symbol": "O", "position": Vector3( 0.725,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.060,  0.800,  0.440) },
			{ "symbol": "H", "position": Vector3( 1.060, -0.800,  0.440) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 2, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 3, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Nitrogen gas  N₂ ───────────────────────────────────────────────────
	"n2": {
		"name": "Nitrogen gas", "formula": "N₂",
		"atoms": [
			{ "symbol": "N", "position": Vector3(-0.548,  0.000,  0.000) },
			{ "symbol": "N", "position": Vector3( 0.548,  0.000,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.TRIPLE },
		],
	},

	# ── Oxygen gas  O₂ ─────────────────────────────────────────────────────
	"o2": {
		"name": "Oxygen gas", "formula": "O₂",
		"atoms": [
			{ "symbol": "O", "position": Vector3(-0.605,  0.000,  0.000) },
			{ "symbol": "O", "position": Vector3( 0.605,  0.000,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.DOUBLE },
		],
	},

	# ── Ozone  O₃ ──────────────────────────────────────────────────────────
	# Bent, bond angle 117°, O-O 1.28 Å
	"ozone": {
		"name": "Ozone", "formula": "O₃",
		"atoms": [
			{ "symbol": "O", "position": Vector3( 0.000,  0.000,  0.000) },
			{ "symbol": "O", "position": Vector3( 1.278,  0.000,  0.000) },
			{ "symbol": "O", "position": Vector3(-0.581,  1.144,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.AROMATIC },
			{ "a": 0, "b": 2, "order": ChemistryData.BondOrder.AROMATIC },
		],
	},

	# ── Methanol  CH₃OH ────────────────────────────────────────────────────
	"methanol": {
		"name": "Methanol", "formula": "CH₄O",
		"atoms": [
			{ "symbol": "C", "position": Vector3(-0.748,  0.000,  0.000) },
			{ "symbol": "O", "position": Vector3( 0.678,  0.000,  0.000) },
			{ "symbol": "H", "position": Vector3( 1.060,  0.900,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.134,  1.027,  0.000) },
			{ "symbol": "H", "position": Vector3(-1.134, -0.514,  0.890) },
			{ "symbol": "H", "position": Vector3(-1.134, -0.514, -0.890) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 1, "b": 2, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 3, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 4, "order": ChemistryData.BondOrder.SINGLE },
			{ "a": 0, "b": 5, "order": ChemistryData.BondOrder.SINGLE },
		],
	},

	# ── Sodium chloride  NaCl (ion pair) ───────────────────────────────────
	"nacl": {
		"name": "Sodium chloride", "formula": "NaCl",
		"atoms": [
			{ "symbol": "Na", "position": Vector3(-1.190,  0.000,  0.000) },
			{ "symbol": "Cl", "position": Vector3( 1.190,  0.000,  0.000) },
		],
		"bonds": [
			{ "a": 0, "b": 1, "order": ChemistryData.BondOrder.SINGLE },
		],
	},
}

# ── API ───────────────────────────────────────────────────────────────────────

## Returns the preset dict for the given key, or {} if not found.
static func get_preset(key: String) -> Dictionary:
	var k := key.to_lower()
	if _PRESETS.has(k):
		return _PRESETS[k]
	push_error("MoleculePresets: unknown preset '%s'. Available: %s" % [key, keys()])
	return {}

## All preset keys.
static func keys() -> Array:
	return _PRESETS.keys()

## True if the preset key exists.
static func has_preset(key: String) -> bool:
	return _PRESETS.has(key.to_lower())
