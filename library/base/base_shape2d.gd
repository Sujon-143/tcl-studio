@tool
extends Node2D
class_name BaseShape2D

# ─────────────────────────────────────────────────────────────────────────────
#  APPEARANCE ANIMATIONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category('Appearance Animations')

## Base uniform scale — all animation multipliers build on top of this.
@export_range(0.01, 4.0, 0.01) var base_scale: float = 1.0:
	set(v):
		base_scale = v
		_update_scale()

## Pops the shape in with an overshoot bounce. Also controls visibility.
@export_range(0.0, 1.0, 0.01) var popup_progress: float = 1.0:
	set(v):
		popup_progress = v
		visible = popup_progress > 0.01
		_update_scale()

## Fades opacity in/out. Never touches scale or position.
@export_range(0.0, 1.0, 0.01) var fade_progress: float = 1.0:
	set(v):
		fade_progress = v
		modulate.a = TransitionFunctions.ease_in_out(
			TransitionFunctions.trans_sine, fade_progress
		)

## Grows from a point. Multiplies on top of base_scale.
@export_range(0.0, 1.0, 0.01) var grow_progress: float = 1.0:
	set(v):
		grow_progress = v
		_update_scale()

## Stroke draw completion (0 = nothing drawn, 1 = fully drawn).
## Subclasses read this in _draw(); changing it triggers a redraw.
@export_range(0.0, 1.0, 0.01) var draw_progress: float = 1.0:
	set(v):
		draw_progress = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  INDICATION ANIMATIONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category('Indication Animations')

## One-shot attention pulse. Scale peaks at t=0.5 then returns to normal.
## Animate 0→1 for a single beat.
@export_range(0.0, 1.0, 0.01) var indicate_progress: float = 0.0:
	set(v):
		indicate_progress = v
		_update_scale()

## Peak scale overshoot of the indicate pulse (0.2 = +20% at peak).
@export_range(0.0, 1.0, 0.01) var indicate_scale_boost: float = 0.2:
	set(v):
		indicate_scale_boost = v
		_update_scale()

## Color brightness flash. Peaks at t=0.5, returns to normal at t=1.
## Animate 0→1 once per flash beat.
@export_range(0.0, 1.0, 0.01) var flash_progress: float = 0.0:
	set(v):
		flash_progress = v
		var t := TransitionFunctions.ease_in_out(
			TransitionFunctions.trans_expo, flash_progress
		)
		var b := 1.0 + flash_brightness * sin(t * PI)
		modulate = Color(b, b, b, modulate.a)

## How many times brighter the flash peak gets above normal.
@export_range(0.0, 3.0, 0.05) var flash_brightness: float = 1.5

## Decaying scale-wobble like a struck rigid body.
## Animate 0→1; shake decays automatically as progress approaches 1.
@export_range(0.0, 1.0, 0.01) var shake_progress: float = 0.0:
	set(v):
		shake_progress = v
		_update_scale()

## Number of wobble oscillations across the full shake (higher = faster rattle).
@export_range(1.0, 20.0, 0.5) var shake_frequency: float = 8.0:
	set(v):
		shake_frequency = v
		_update_scale()

## Peak scale distortion of the shake (0.06 = ±6% squish at peak).
@export_range(0.0, 0.5, 0.01) var shake_amplitude_scale: float = 0.06:
	set(v):
		shake_amplitude_scale = v
		_update_scale()

# ─────────────────────────────────────────────────────────────────────────────
#  CIRCUMSCRIBE ANIMATIONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category('Circumscribe Animations')

## 0 = no ring, 1 = full ring traced around the shape.
@export_range(0.0, 1.0, 0.01) var circumscribe_progress: float = 0.0:
	set(v):
		circumscribe_progress = v
		queue_redraw()

## Radius of the circumscribe circle in local units.
@export_range(1.0, 500.0, 1.0) var circumscribe_radius: float = 60.0:
	set(v):
		circumscribe_radius = v
		queue_redraw()

## Stroke color of the circumscribe ring.
@export var circumscribe_color: Color = Color(1.0, 0.85, 0.1, 1.0):
	set(v):
		circumscribe_color = v
		queue_redraw()

## Stroke width of the circumscribe ring.
@export_range(0.5, 16.0, 0.5) var circumscribe_width: float = 3.0:
	set(v):
		circumscribe_width = v
		queue_redraw()

## Draw the ring as a dashed arc instead of solid.
@export var circumscribe_dashed: bool = false:
	set(v):
		circumscribe_dashed = v
		queue_redraw()

## Length of each dash in local units (dashed mode only).
@export_range(2.0, 40.0, 1.0) var circumscribe_dash_length: float = 10.0:
	set(v):
		circumscribe_dash_length = v
		queue_redraw()

## Gap between dashes in local units (dashed mode only).
@export_range(1.0, 40.0, 1.0) var circumscribe_gap_length: float = 6.0:
	set(v):
		circumscribe_gap_length = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  TRANSFORM ANIMATIONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category('Transform Animations')

## Spins the node. 0 = 0°, 1 = one full clockwise revolution.
## Chain multiple 0→1 keys for multi-turn spins.
@export_range(0.0, 1.0, 0.01) var spin_progress: float = 0.0:
	set(v):
		spin_progress = v
		rotation = TransitionFunctions.ease_in_out(
			TransitionFunctions.trans_quint, spin_progress
		) * TAU

## Squash (< 0.5) or stretch (> 0.5). 0.5 = no deformation.
## Applied as the final anisotropic split on the accumulated scale.
@export_range(0.0, 1.0, 0.01) var squash_progress: float = 0.5:
	set(v):
		squash_progress = v
		_update_scale()

# ─────────────────────────────────────────────────────────────────────────────
#  COMMON PARAMETERS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Common Parameters")
@export var unit_size: float = 100:
	set(v):
		unit_size = v
		queue_redraw()

var resolved_points: PackedVector2Array = PackedVector2Array()


func _ready():
	pass
# ─────────────────────────────────────────────────────────────────────────────
#  SCALE COMPOSITION  — single source of truth, called by every scale setter
# ─────────────────────────────────────────────────────────────────────────────
func _update_scale() -> void:
	# 1. Start from base
	var s := base_scale

	# 2. Grow — linear multiplier (0 = invisible, 1 = full)
	s *= TransitionFunctions.ease_in_out(	TransitionFunctions.trans_cubic, grow_progress)

	# 3. Popup — multiplicative overshoot on top of whatever grow gave us
	if popup_progress > 0.01:
		s *= TransitionFunctions.ease_out(TransitionFunctions.trans_back, popup_progress)

	# 4. Indicate — sine-arch pulse, peaks at t=0.5, returns to ×1 at t=1
	var indicate_t := TransitionFunctions.ease_in_out(
		TransitionFunctions.trans_sine, indicate_progress
	)
	s *= 1.0 + indicate_scale_boost * sin(indicate_t * PI)

	# 5. Shake — asymmetric wobble, decays to zero by t=1
	var shake_envelope := 1.0 - TransitionFunctions.ease_in(
		TransitionFunctions.trans_quart, shake_progress
	)
	var wobble := sin(shake_progress * PI * shake_frequency) \
		* shake_envelope * shake_amplitude_scale

	# 6. Squash/stretch — anisotropic final split on the accumulated scalar s
	#    squash_progress == 0.5  →  t=0  →  no deformation
	var sq := (squash_progress - 0.5) * 2.0   # remap 0…1 → -1…+1
	var sx := s * (1.0 - sq * 0.4) * (1.0 + wobble)
	var sy := s * (1.0 + sq * 0.4) * (1.0 - wobble * 0.5)

	scale = Vector2(sx, sy)

# ─────────────────────────────────────────────────────────────────────────────
#  DRAW  — circumscribe ring; child classes call super._draw() first
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if circumscribe_progress <= 0.0:
		return

	var r         := circumscribe_radius
	var end_angle := -PI * 0.5 + circumscribe_progress * TAU   # clockwise from 12 o'clock
	var segs      :int= max(8, int(r * 0.5))

	if not circumscribe_dashed:
		draw_arc(Vector2.ZERO, r, -PI * 0.5, end_angle, segs,
			circumscribe_color, circumscribe_width, true)
	else:
		var dash_angle := circumscribe_dash_length / r
		var gap_angle  := circumscribe_gap_length  / r
		var step_angle := dash_angle + gap_angle
		var seg_ratio  := segs * (dash_angle / (circumscribe_progress * TAU + 0.0001))

		var angle     := -PI * 0.5
		var remaining := circumscribe_progress * TAU

		while remaining > 0.0:
			var this_dash := minf(dash_angle, remaining)
			draw_arc(Vector2.ZERO, r, angle, angle + this_dash,
				maxi(3, int(seg_ratio)),
				circumscribe_color, circumscribe_width, true)
			angle     += step_angle
			remaining -= step_angle
