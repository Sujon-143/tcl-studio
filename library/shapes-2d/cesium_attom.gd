@tool
extends BaseShape2D
class_name CesiumAtom

## Cesium-133 atom visualizer.
## Renders a physically-grounded Bohr model of Cs-133 (55 protons, 78 neutrons,
## electron configuration [Xe] 6s¹ across 6 shells: 2-8-18-18-8-1).
## The outer 6s¹ electron oscillates at the specified hyperfine frequency,
## mirroring the 9,192,631,770 Hz definition of the SI second.

# ── Editor-exposed properties ─────────────────────────────────────────────────

@export_group("Physics")

## Hyperfine transition frequency in GHz.
## The physical Cs-133 value is 9.192631770 GHz (SI definition of the second).
## Adjust to animate at a visible rate in-editor.
@export_range(0.1, 30.0, 0.001, "suffix:GHz")
var vibration_frequency: float = 9.192631770:
	set(v):
		vibration_frequency = v
		queue_redraw()

@export_group("Display")

## Label rendered beneath the nucleus (e.g. "¹³³Cs", "Cs-133", or a custom tag).
@export var label: String = "¹³³Cs":
	set(v):
		label = v
		queue_redraw()

## Overall scale of the atom diagram in pixels.
@export_range(40, 400, 1, "suffix:px")
var diagram_radius: float = 120.0:
	set(v):
		diagram_radius = v
		queue_redraw()

## Show electron shell orbit rings.
@export var show_shells: bool = true:
	set(v):
		show_shells = v
		queue_redraw()

## Highlight the outer 6s¹ "clock" electron with a glow.
@export var highlight_clock_electron: bool = true:
	set(v):
		highlight_clock_electron = v
		queue_redraw()

## Color for inner-shell electrons (shells 1–5).
@export var inner_electron_color: Color = Color(0.22, 0.55, 0.85, 0.85):
	set(v):
		inner_electron_color = v
		queue_redraw()

## Color for the outer 6s¹ "clock" electron.
@export var clock_electron_color: Color = Color(0.94, 0.62, 0.15, 1.0):
	set(v):
		clock_electron_color = v
		queue_redraw()

## Color of the nucleus.
@export var nucleus_color: Color = Color(0.85, 0.18, 0.13, 1.0):
	set(v):
		nucleus_color = v
		queue_redraw()

# ── Internal state ────────────────────────────────────────────────────────────

# Cs-133 Bohr shell electron counts: 2, 8, 18, 18, 8, 1
const SHELL_COUNTS: Array[int] = [2, 8, 18, 18, 8, 1]

# Shell radii as fractions of diagram_radius (innermost → outermost).
const SHELL_FRACTIONS: Array[float] = [0.17, 0.29, 0.43, 0.57, 0.71, 0.86]

# Angular speeds (radians/second). Inner shells orbit faster (Kepler-like scaling).
const SHELL_OMEGA: Array[float] = [3.50, 2.40, 1.65, 1.15, 0.75, 0.45]

# Per-electron angular positions, indexed [shell][electron].
var _angles: Array = []

# Accumulated time for the hyperfine pulse animation.
var _time: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_init_angles()
	set_process(true)

func _init_angles() -> void:
	_angles.clear()
	for i in SHELL_COUNTS.size():
		var n: int = SHELL_COUNTS[i]
		var shell_angles: Array[float] = []
		for k in n:
			shell_angles.append((float(k) / float(n)) * TAU)
		_angles.append(shell_angles)

func _process(delta: float) -> void:
	_time += delta
	# Advance each electron's angular position.
	for si in SHELL_COUNTS.size():
		var omega: float = SHELL_OMEGA[si]
		for ei in _angles[si].size():
			_angles[si][ei] += omega * delta
	queue_redraw()

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	super._draw()
	# Hyperfine pulse: the 6s¹ electron oscillates at vibration_frequency.
	# We map that to a visible 0–1 pulse using a sine at a scaled rate.
	var pulse: float = (sin(_time * vibration_frequency * 0.8) * 0.5 + 0.5)

	_draw_shell_rings()
	_draw_electrons(pulse)
	_draw_nucleus()
	_draw_hyperfine_glow(pulse)
	_draw_label()

func _draw_shell_rings() -> void:
	if not show_shells:
		return
	for si in SHELL_COUNTS.size():
		var r: float = SHELL_FRACTIONS[si] * diagram_radius
		var alpha: float = 0.10 + si * 0.04
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64,
			Color(0.6, 0.6, 0.6, alpha), 0.8, true)

func _draw_electrons(pulse: float) -> void:
	for si in SHELL_COUNTS.size():
		var r: float = SHELL_FRACTIONS[si] * diagram_radius
		var is_outer: bool = (si == SHELL_COUNTS.size() - 1)
		for ei in _angles[si].size():
			var angle: float = _angles[si][ei]
			var pos := Vector2(cos(angle), sin(angle)) * r
			if is_outer and highlight_clock_electron:
				# Glow ring around the clock electron — pulses with hyperfine freq.
				var glow_r: float = 5.0 + pulse * 4.0
				var glow_c := Color(clock_electron_color.r,
								clock_electron_color.g,
								clock_electron_color.b,
								0.25 + pulse * 0.35)
				draw_circle(pos, glow_r, glow_c)
				draw_circle(pos, 4.0,
					Color(clock_electron_color.r,
						  clock_electron_color.g,
						  clock_electron_color.b,
						  0.7 + pulse * 0.3))
			else:
				draw_circle(pos, 2.5, inner_electron_color)

func _draw_nucleus() -> void:
	# Nucleus radius scales weakly with diagram size (it's not to physical scale —
	# a true-to-scale nucleus would be invisible).
	var nuc_r: float = clampf(diagram_radius * 0.09, 7.0, 18.0)
	draw_circle(Vector2.ZERO, nuc_r, nucleus_color)
	# Lighter inner highlight for depth.
	draw_circle(Vector2.ZERO, nuc_r * 0.45,
		Color(nucleus_color.r + 0.25, nucleus_color.g + 0.15, nucleus_color.b + 0.15, 0.6))
	# Proton / neutron count annotation.
	var font: Font = ThemeDB.fallback_font
	var font_size: int = maxi(8, int(nuc_r * 0.55))
	draw_string(font, Vector2(-nuc_r * 0.55, -nuc_r * 0.15),
		"55p", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size,
		Color(1, 1, 1, 0.85))
	draw_string(font, Vector2(-nuc_r * 0.55, nuc_r * 0.55),
		"78n", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size,
		Color(1, 1, 1, 0.65))

func _draw_hyperfine_glow(pulse: float) -> void:
	# Soft amber radial glow around the whole atom that breathes with the
	# hyperfine oscillation of the 6s¹ electron.
	if not highlight_clock_electron:
		return
	var outer_r: float = SHELL_FRACTIONS[5] * diagram_radius + 14.0
	var glow_c := Color(clock_electron_color.r,
						clock_electron_color.g,
						clock_electron_color.b,
						0.04 + pulse * 0.10)
	draw_circle(Vector2.ZERO, outer_r, glow_c)

func _draw_label() -> void:
	if label.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = maxi(10, int(diagram_radius * 0.12))
	var y_offset: float = diagram_radius + font_size + 6.0
	draw_string(font,
		Vector2(-50, y_offset),
		label,
		HORIZONTAL_ALIGNMENT_CENTER, 100, font_size,
		Color(0.85, 0.85, 0.80, 0.9))
	# Frequency sub-label.
	var freq_str: String = "%.3f GHz" % vibration_frequency
	draw_string(font,
		Vector2(-50, y_offset + font_size + 2),
		freq_str,
		HORIZONTAL_ALIGNMENT_CENTER, 100, maxi(8, font_size - 3),
		Color(0.65, 0.65, 0.60, 0.6))
