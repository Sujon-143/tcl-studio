@tool
extends Node2D
class_name Neuron2D

# ─────────────────────────────────────────────────────────────────────────────
#  SHAPE
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Shape")

## Base radius of the neuron circle (at spawn_progress = 1).
@export_range(2.0, 200.0, 1.0, "or_greater") var radius: float = 24.0:
	set(v):
		radius = v
		queue_redraw()

## Number of segments used to draw circles/arcs (quality).
@export_range(6, 128, 1, "or_greater") var segments: int = 32:
	set(v):
		segments = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  COLORS — BASE
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Colors — Base")

@export var fill_color: Color = Color(0.12, 0.14, 0.22, 1.0):
	set(v):
		fill_color = v
		queue_redraw()

@export var stroke_color: Color = Color(0.45, 0.55, 0.9, 1.0):
	set(v):
		stroke_color = v
		queue_redraw()

@export_range(0.0, 20.0, 0.1, "or_greater") var stroke_width: float = 2.0:
	set(v):
		stroke_width = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — SPAWN
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Spawn")

## 0 = invisible/zero-size, 1 = fully spawned. Drives both scale and fade.
@export_range(0.0, 1.0, 0.01) var spawn_progress: float = 1.0:
	set(v):
		spawn_progress = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — ACTIVATION
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Activation")

## 0 = idle color, 1 = fully activated color.
@export_range(0.0, 1.0, 0.01) var activation_progress: float = 0.0:
	set(v):
		activation_progress = v
		queue_redraw()

@export var active_color: Color = Color(0.3, 0.85, 0.6, 1.0):
	set(v):
		active_color = v
		queue_redraw()

## Soft glow drawn behind the neuron while activated.
@export var glow_enabled: bool = true:
	set(v):
		glow_enabled = v
		queue_redraw()

@export var glow_color: Color = Color(0.3, 0.85, 0.6, 1.0):
	set(v):
		glow_color = v
		queue_redraw()

## Glow radius as a multiplier of `radius` at full activation.
@export_range(1.0, 6.0, 0.05, "or_greater") var glow_scale: float = 1.8:
	set(v):
		glow_scale = v
		queue_redraw()

## Max opacity of the glow at activation_progress = 1.
@export_range(0.0, 1.0, 0.01) var glow_opacity: float = 0.5:
	set(v):
		glow_opacity = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — FIRE PULSE (expanding ring burst, e.g. a spike event)
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Fire Pulse")

## 0 = ring not started, 1 = ring fully expanded and faded out.
## Designed to be keyframed 0→1 once per "firing" event.
@export_range(0.0, 1.0, 0.01) var pulse_progress: float = 0.0:
	set(v):
		pulse_progress = v
		queue_redraw()

@export var pulse_color: Color = Color(1.0, 0.9, 0.4, 1.0):
	set(v):
		pulse_color = v
		queue_redraw()

@export_range(0.0, 20.0, 0.1, "or_greater") var pulse_width: float = 2.5:
	set(v):
		pulse_width = v
		queue_redraw()

## Ring radius (as multiplier of `radius`) at pulse_progress = 0.
@export_range(0.1, 4.0, 0.05, "or_greater") var pulse_start_scale: float = 1.0:
	set(v):
		pulse_start_scale = v
		queue_redraw()

## Ring radius (as multiplier of `radius`) at pulse_progress = 1.
@export_range(0.1, 8.0, 0.05, "or_greater") var pulse_end_scale: float = 2.2:
	set(v):
		pulse_end_scale = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — ERROR
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Error")

## 0 = no error shown, 1 = fully in error state.
@export_range(0.0, 1.0, 0.01) var error_progress: float = 0.0:
	set(v):
		error_progress = v
		queue_redraw()

@export var error_color: Color = Color(0.9, 0.3, 0.35, 1.0):
	set(v):
		error_color = v
		queue_redraw()

## Static burst ring drawn around the neuron, scaled by error_progress.
@export_range(0.5, 6.0, 0.05, "or_greater") var error_burst_scale: float = 1.4:
	set(v):
		error_burst_scale = v
		queue_redraw()

@export_range(0.0, 20.0, 0.1, "or_greater") var error_burst_width: float = 2.5:
	set(v):
		error_burst_width = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — GRADIENT / BACKPROP HIGHLIGHT
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Gradient")

## 0 = idle color, 1 = fully in gradient/backprop color.
## Takes priority over activation_progress, but not error_progress.
@export_range(0.0, 1.0, 0.01) var grad_progress: float = 0.0:
	set(v):
		grad_progress = v
		queue_redraw()

@export var grad_color: Color = Color(0.95, 0.75, 0.2, 1.0):
	set(v):
		grad_color = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — SELECTION HIGHLIGHT RING
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Highlight")

## 0 = no ring, 1 = ring fully swept around (TAU). Good for a pulsing "look here" cue.
@export_range(0.0, 1.0, 0.01) var highlight_progress: float = 0.0:
	set(v):
		highlight_progress = v
		queue_redraw()

@export var highlight_color: Color = Color(1.0, 1.0, 1.0, 0.9):
	set(v):
		highlight_color = v
		queue_redraw()

@export_range(0.0, 20.0, 0.1, "or_greater") var highlight_ring_width: float = 2.0:
	set(v):
		highlight_ring_width = v
		queue_redraw()

@export_range(0.0, 60.0, 0.5, "or_greater") var highlight_ring_gap: float = 5.0:
	set(v):
		highlight_ring_gap = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  LABEL
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Label")

@export var show_label: bool = false:
	set(v):
		show_label = v
		queue_redraw()

## Text shown before the number, e.g. "b=" or "a=". Leave empty for just the number.
@export var label_prefix: String = "":
	set(v):
		label_prefix = v
		queue_redraw()

## The value displayed. Animate this directly to "count up/down" a bias or activation.
@export var label_value: float = 0.0:
	set(v):
		label_value = v
		queue_redraw()

## Decimal places shown.
@export_range(0, 6, 1) var label_decimals: int = 2:
	set(v):
		label_decimals = v
		queue_redraw()

## Font size. Kept as float (not int) so it tweens smoothly in AnimationPlayer;
## it's rounded to an int only at the draw_string() call.
@export_range(1.0, 96.0, 0.5, "or_greater") var label_font_size: float = 12.0:
	set(v):
		label_font_size = v
		queue_redraw()

@export var label_color: Color = Color(1.0, 1.0, 1.0, 0.9):
	set(v):
		label_color = v
		queue_redraw()

@export_range(0.0, 1.0, 0.01) var label_opacity: float = 1.0:
	set(v):
		label_opacity = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────

func _fmt(v: float) -> String:
	return ("%." + str(label_decimals) + "f") % v

func _font_px() -> int:
	return int(round(label_font_size))

# ─────────────────────────────────────────────────────────────────────────────
#  DRAW
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var spawn := clampf(spawn_progress, 0.0, 1.0)
	if spawn <= 0.0:
		return

	var r := radius * spawn
	if r <= 0.0:
		return

	# --- Resolve state color (priority: error > gradient > activation) ---
	var fill := fill_color
	var stroke := stroke_color

	if error_progress > 0.001:
		fill = fill_color.lerp(error_color, error_progress)
		stroke = stroke_color.lerp(error_color, error_progress)
	elif grad_progress > 0.001:
		fill = fill_color.lerp(grad_color, grad_progress)
		stroke = stroke_color.lerp(grad_color, grad_progress)
	elif activation_progress > 0.001:
		fill = fill_color.lerp(active_color, activation_progress)
		stroke = stroke_color.lerp(active_color, activation_progress)

	fill.a *= spawn
	stroke.a *= spawn

	# --- Glow (drawn first, behind everything) ---
	if glow_enabled and activation_progress > 0.001 and glow_opacity > 0.001:
		var glow_r := r * lerpf(1.0, glow_scale, activation_progress)
		var glow_col := glow_color
		glow_col.a *= activation_progress * glow_opacity * spawn
		draw_circle(Vector2.ZERO, glow_r, glow_col)

	# --- Body ---
	draw_circle(Vector2.ZERO, r, fill)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, segments, stroke, stroke_width, true)

	# --- Fire pulse ring (expands outward, fades as it grows) ---
	if pulse_progress > 0.001:
		var pulse_r := r * lerpf(pulse_start_scale, pulse_end_scale, pulse_progress)
		var pcol := pulse_color
		pcol.a *= (1.0 - pulse_progress) * spawn
		draw_arc(Vector2.ZERO, pulse_r, 0.0, TAU, segments, pcol, pulse_width, true)

	# --- Error burst ring ---
	if error_progress > 0.001:
		var burst_r := r * lerpf(1.0, error_burst_scale, error_progress)
		var ecol := error_color
		ecol.a *= error_progress * spawn
		draw_arc(Vector2.ZERO, burst_r, 0.0, TAU, segments, ecol, error_burst_width, true)

	# --- Selection highlight sweep ring ---
	if highlight_progress > 0.001:
		var ring_r := r + highlight_ring_gap
		var end_a := -PI * 0.5 + highlight_progress * TAU
		var hcol := highlight_color
		hcol.a *= spawn
		draw_arc(Vector2.ZERO, ring_r, -PI * 0.5, end_a, segments, hcol, highlight_ring_width, true)

	# --- Label ---
	if show_label and label_opacity > 0.001:
		var font_px := _font_px()
		var text := label_prefix + _fmt(label_value)
		var lcol := label_color
		lcol.a *= label_opacity * spawn
		draw_string(
			ThemeDB.fallback_font,
			Vector2(0.0, font_px * 0.35),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_px,
			lcol
		)
