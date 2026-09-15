@tool
extends Node
class_name ChemistryData

## Static element and bond reference data for the chemistry library.
## All data is stored as plain dictionaries — no instantiation needed.
## Usage:  ChemistryData.element("C")   → { symbol, name, color, radius, … }
##         ChemistryData.bond_radius(BondOrder.SINGLE) → float

# ── Bond orders ───────────────────────────────────────────────────────────────

enum BondOrder { SINGLE = 1, DOUBLE = 2, TRIPLE = 3, AROMATIC = 4 }

# ── Element table ─────────────────────────────────────────────────────────────
# Keys per entry:
#   symbol          String   IUPAC symbol
#   name            String   full element name
#   atomic_number   int
#   color           Color    CPK-2 convention (Corey–Pauling–Koltun)
#   covalent_radius float    in Ångströms  (used for ball-and-stick sphere size)
#   vdw_radius      float    van der Waals radius in Å  (spacefill model)
#   electronegativity float  Pauling scale (0.0 = unknown/noble)
#   mass            float    atomic mass in u

const ELEMENTS: Dictionary = {
	"H":  { "symbol": "H",  "name": "Hydrogen",    "atomic_number": 1,
			"color": Color(1.00, 1.00, 1.00),   "covalent_radius": 0.31,
			"vdw_radius": 1.20, "electronegativity": 2.20, "mass":  1.008 },

	"He": { "symbol": "He", "name": "Helium",      "atomic_number": 2,
			"color": Color(0.85, 1.00, 1.00),   "covalent_radius": 0.28,
			"vdw_radius": 1.40, "electronegativity": 0.00, "mass":  4.003 },

	"Li": { "symbol": "Li", "name": "Lithium",     "atomic_number": 3,
			"color": Color(0.80, 0.50, 1.00),   "covalent_radius": 1.28,
			"vdw_radius": 1.82, "electronegativity": 0.98, "mass":  6.941 },

	"B":  { "symbol": "B",  "name": "Boron",       "atomic_number": 5,
			"color": Color(1.00, 0.71, 0.71),   "covalent_radius": 0.84,
			"vdw_radius": 1.92, "electronegativity": 2.04, "mass": 10.811 },

	"C":  { "symbol": "C",  "name": "Carbon",      "atomic_number": 6,
			"color": Color(0.25, 0.25, 0.25),   "covalent_radius": 0.77,
			"vdw_radius": 1.70, "electronegativity": 2.55, "mass": 12.011 },

	"N":  { "symbol": "N",  "name": "Nitrogen",    "atomic_number": 7,
			"color": Color(0.19, 0.31, 0.97),   "covalent_radius": 0.75,
			"vdw_radius": 1.55, "electronegativity": 3.04, "mass": 14.007 },

	"O":  { "symbol": "O",  "name": "Oxygen",      "atomic_number": 8,
			"color": Color(1.00, 0.05, 0.05),   "covalent_radius": 0.73,
			"vdw_radius": 1.52, "electronegativity": 3.44, "mass": 15.999 },

	"F":  { "symbol": "F",  "name": "Fluorine",    "atomic_number": 9,
			"color": Color(0.56, 0.88, 0.31),   "covalent_radius": 0.71,
			"vdw_radius": 1.47, "electronegativity": 3.98, "mass": 18.998 },

	"Ne": { "symbol": "Ne", "name": "Neon",        "atomic_number": 10,
			"color": Color(0.70, 0.89, 0.96),   "covalent_radius": 0.69,
			"vdw_radius": 1.54, "electronegativity": 0.00, "mass": 20.180 },

	"Na": { "symbol": "Na", "name": "Sodium",      "atomic_number": 11,
			"color": Color(0.67, 0.36, 0.95),   "covalent_radius": 1.66,
			"vdw_radius": 2.27, "electronegativity": 0.93, "mass": 22.990 },

	"Mg": { "symbol": "Mg", "name": "Magnesium",   "atomic_number": 12,
			"color": Color(0.54, 1.00, 0.00),   "covalent_radius": 1.41,
			"vdw_radius": 1.73, "electronegativity": 1.31, "mass": 24.305 },

	"Al": { "symbol": "Al", "name": "Aluminium",   "atomic_number": 13,
			"color": Color(0.75, 0.65, 0.65),   "covalent_radius": 1.21,
			"vdw_radius": 1.84, "electronegativity": 1.61, "mass": 26.982 },

	"Si": { "symbol": "Si", "name": "Silicon",     "atomic_number": 14,
			"color": Color(0.94, 0.78, 0.63),   "covalent_radius": 1.11,
			"vdw_radius": 2.10, "electronegativity": 1.90, "mass": 28.086 },

	"P":  { "symbol": "P",  "name": "Phosphorus",  "atomic_number": 15,
			"color": Color(1.00, 0.50, 0.00),   "covalent_radius": 1.07,
			"vdw_radius": 1.80, "electronegativity": 2.19, "mass": 30.974 },

	"S":  { "symbol": "S",  "name": "Sulphur",     "atomic_number": 16,
			"color": Color(1.00, 1.00, 0.19),   "covalent_radius": 1.05,
			"vdw_radius": 1.80, "electronegativity": 2.58, "mass": 32.065 },

	"Cl": { "symbol": "Cl", "name": "Chlorine",    "atomic_number": 17,
			"color": Color(0.12, 0.94, 0.12),   "covalent_radius": 1.02,
			"vdw_radius": 1.75, "electronegativity": 3.16, "mass": 35.453 },

	"Ar": { "symbol": "Ar", "name": "Argon",       "atomic_number": 18,
			"color": Color(0.50, 0.82, 0.89),   "covalent_radius": 0.97,
			"vdw_radius": 1.88, "electronegativity": 0.00, "mass": 39.948 },

	"K":  { "symbol": "K",  "name": "Potassium",   "atomic_number": 19,
			"color": Color(0.56, 0.25, 0.83),   "covalent_radius": 2.03,
			"vdw_radius": 2.75, "electronegativity": 0.82, "mass": 39.098 },

	"Ca": { "symbol": "Ca", "name": "Calcium",     "atomic_number": 20,
			"color": Color(0.24, 1.00, 0.00),   "covalent_radius": 1.76,
			"vdw_radius": 2.31, "electronegativity": 1.00, "mass": 40.078 },

	"Fe": { "symbol": "Fe", "name": "Iron",        "atomic_number": 26,
			"color": Color(0.88, 0.40, 0.20),   "covalent_radius": 1.32,
			"vdw_radius": 2.00, "electronegativity": 1.83, "mass": 55.845 },

	"Cu": { "symbol": "Cu", "name": "Copper",      "atomic_number": 29,
			"color": Color(0.78, 0.50, 0.20),   "covalent_radius": 1.32,
			"vdw_radius": 1.40, "electronegativity": 1.90, "mass": 63.546 },

	"Zn": { "symbol": "Zn", "name": "Zinc",        "atomic_number": 30,
			"color": Color(0.49, 0.50, 0.69),   "covalent_radius": 1.22,
			"vdw_radius": 1.39, "electronegativity": 1.65, "mass": 65.38  },

	"Br": { "symbol": "Br", "name": "Bromine",     "atomic_number": 35,
			"color": Color(0.65, 0.16, 0.16),   "covalent_radius": 1.20,
			"vdw_radius": 1.85, "electronegativity": 2.96, "mass": 79.904 },

	"I":  { "symbol": "I",  "name": "Iodine",      "atomic_number": 53,
			"color": Color(0.58, 0.00, 0.58),   "covalent_radius": 1.39,
			"vdw_radius": 1.98, "electronegativity": 2.66, "mass": 126.90 },

	"Au": { "symbol": "Au", "name": "Gold",        "atomic_number": 79,
			"color": Color(1.00, 0.82, 0.14),   "covalent_radius": 1.36,
			"vdw_radius": 1.66, "electronegativity": 2.54, "mass": 196.97 },
}

# ── Bond cylinder radii (Å, scaled to match atom display scale) ───────────────
# These are visual radii for the stick in ball-and-stick. The offset spacing
# for double/triple bonds is also defined here.

const BOND_VISUAL: Dictionary = {
	ChemistryData.BondOrder.SINGLE:   { "radius": 0.10, "offset": 0.00 },
	ChemistryData.BondOrder.DOUBLE:   { "radius": 0.07, "offset": 0.14 },
	ChemistryData.BondOrder.TRIPLE:   { "radius": 0.06, "offset": 0.14 },
	ChemistryData.BondOrder.AROMATIC: { "radius": 0.08, "offset": 0.12 },
}

# ── Bond colour overrides ─────────────────────────────────────────────────────
# By default Bond3D uses a neutral grey. Override per bond type here.

const BOND_COLORS: Dictionary = {
	ChemistryData.BondOrder.SINGLE:   Color(0.55, 0.55, 0.55),
	ChemistryData.BondOrder.DOUBLE:   Color(0.40, 0.60, 0.90),
	ChemistryData.BondOrder.TRIPLE:   Color(0.90, 0.55, 0.20),
	ChemistryData.BondOrder.AROMATIC: Color(0.60, 0.80, 0.40),
}

# ── API ───────────────────────────────────────────────────────────────────────

## Returns the data dictionary for an element symbol, or an empty dict
## with a push_error if the symbol is unknown.
static func element(symbol: String) -> Dictionary:
	if ELEMENTS.has(symbol):
		return ELEMENTS[symbol]
	push_error("ChemistryData: unknown element symbol '%s'" % symbol)
	return {}

## Convenience: CPK colour for a symbol.
static func cpk_color(symbol: String) -> Color:
	var el := element(symbol)
	return el.get("color", Color.MAGENTA)   # magenta = obvious unknown

## Covalent radius in Å.
static func covalent_radius(symbol: String) -> float:
	var el := element(symbol)
	return el.get("covalent_radius", 0.70)

## Van der Waals radius in Å.
static func vdw_radius(symbol: String) -> float:
	var el := element(symbol)
	return el.get("vdw_radius", 1.50)

## Returns the visual bond data dict for a BondOrder value.
static func bond_visual(order: BondOrder) -> Dictionary:
	return BOND_VISUAL.get(order, BOND_VISUAL[BondOrder.SINGLE])

## Returns the display colour for a bond order.
static func bond_color(order: BondOrder) -> Color:
	return BOND_COLORS.get(order, Color(0.55, 0.55, 0.55))

## All known element symbols.
static func all_symbols() -> Array:
	return ELEMENTS.keys()

## True if the symbol exists in the table.
static func has_element(symbol: String) -> bool:
	return ELEMENTS.has(symbol)
