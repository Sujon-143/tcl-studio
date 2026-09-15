@tool
extends Node3D
class_name BaseNode3D

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

## Fades opacity in/out. Composes with flash — never conflicts.
@export_range(0.0, 1.0, 0.01) var fade_progress: float = 1.0:
	set(v):
		fade_progress = v
		_update_modulate()

## Grows from a point. Multiplies on top of base_scale.
@export_range(0.0, 1.0, 0.01) var grow_progress: float = 1.0:
	set(v):
		grow_progress = v
		_update_scale()

## Stroke/geometry draw completion (0 = nothing, 1 = fully drawn).
## Subclasses read this in update_visuals().


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

## Brightness flash — composes with fade, never overwrites it.
## Animate 0→1 once per flash beat; peaks at t=0.5.
@export_range(0.0, 1.0, 0.01) var flash_progress: float = 0.0:
	set(v):
		flash_progress = v
		_update_modulate()

## How many times brighter the flash peak gets above normal.
@export_range(0.0, 3.0, 0.05) var flash_brightness: float = 1.5

## Decaying scale-wobble like a struck rigid body.
## Animate 0→1; shake amplitude decays automatically toward 1.
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
		update_visuals()

## Radius of the circumscribe circle in local units.
@export_range(1.0, 500.0, 1.0) var circumscribe_radius: float = 60.0:
	set(v):
		circumscribe_radius = v
		update_visuals()

## Stroke color of the circumscribe ring.
@export var circumscribe_color: Color = Color(1.0, 0.85, 0.1, 1.0):
	set(v):
		circumscribe_color = v
		update_visuals()

## Stroke width of the circumscribe ring.
@export_range(0.5, 16.0, 0.5) var circumscribe_width: float = 3.0:
	set(v):
		circumscribe_width = v
		update_visuals()

## Draw the ring as a dashed arc instead of solid.
@export var circumscribe_dashed: bool = false:
	set(v):
		circumscribe_dashed = v
		update_visuals()

## Length of each dash in local units (dashed mode only).
@export_range(2.0, 40.0, 1.0) var circumscribe_dash_length: float = 10.0:
	set(v):
		circumscribe_dash_length = v
		update_visuals()

## Gap between dashes in local units (dashed mode only).
@export_range(1.0, 40.0, 1.0) var circumscribe_gap_length: float = 6.0:
	set(v):
		circumscribe_gap_length = v
		update_visuals()

# ─────────────────────────────────────────────────────────────────────────────
#  TRANSFORM ANIMATIONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category('Transform Animations')

## Spins the node. 0 = 0°, 1 = one full clockwise revolution.
## Chain multiple 0→1 keys in AnimationPlayer for multi-turn spins.
@export_range(0.0, 1.0, 0.01) var spin_progress: float = 0.0:
	set(v):
		spin_progress = v
		rotation.y = TransitionFunctions.ease_in_out(
			TransitionFunctions.trans_quint, spin_progress
		) * TAU

## Squash (< 0.5) or stretch (> 0.5) in the XY plane. 0.5 = no deformation.
## Z axis stays neutral — squash is treated as a screen-plane operation.
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
		update_visuals()

var resolved_points: PackedVector3Array = PackedVector3Array()

# ─────────────────────────────────────────────────────────────────────────────
#  SCALE COMPOSITION
#  Single source of truth. Every scale-affecting setter calls this.
#  AnimationPlayer may fire multiple setters per frame — the last call
#  wins, but by then all stored values are current, so the result is correct.
# ─────────────────────────────────────────────────────────────────────────────
func _update_scale() -> void:
	# 1. Base
	var s := base_scale

	# 2. Grow — cubic ease, 0 = point, 1 = full size
	s *= TransitionFunctions.ease_in_out(TransitionFunctions.trans_cubic, grow_progress)

	# 3. Popup — back-ease overshoot on top of grow
	if popup_progress > 0.01:
		s *= TransitionFunctions.ease_out(TransitionFunctions.trans_back, popup_progress)

	# 4. Indicate — sine-arch pulse, ×1 at t=0 and t=1, peak at t=0.5
	var indicate_t := TransitionFunctions.ease_in_out(
		TransitionFunctions.trans_sine, indicate_progress
	)
	s *= 1.0 + indicate_scale_boost * sin(indicate_t * PI)

	# 5. Shake — decaying asymmetric wobble
	var shake_envelope := 1.0 - TransitionFunctions.ease_in(
		TransitionFunctions.trans_quart, shake_progress
	)
	var wobble := sin(shake_progress * PI * shake_frequency) \
		* shake_envelope * shake_amplitude_scale

	# 6. Squash/stretch — anisotropic XY split; Z stays neutral
	var sq := (squash_progress - 0.5) * 2.0  # remap 0…1 → -1…+1
	var sx  := s * (1.0 - sq * 0.4) * (1.0 + wobble)
	var sy  := s * (1.0 + sq * 0.4) * (1.0 - wobble * 0.5)
	var sz  := s  # depth unaffected — squash is a planar XY operation

	scale = Vector3(sx, sy, sz)

# ─────────────────────────────────────────────────────────────────────────────
#  MODULATE COMPOSITION
#  fade and flash are both keyed independently in AnimationPlayer.
#  Neither overwrites the other — they compose into one apply_fade() call.
# ─────────────────────────────────────────────────────────────────────────────
func _update_modulate() -> void:
	# Fade: 0→1 sine-eased alpha
	var alpha := TransitionFunctions.ease_in_out(
		TransitionFunctions.trans_sine, fade_progress
	)
	# Flash: expo-eased brightness arch, ×1 at t=0 and t=1, peak at t=0.5
	var flash_t    := TransitionFunctions.ease_in_out(
		TransitionFunctions.trans_expo, flash_progress
	)
	var brightness := 1.0 + flash_brightness * sin(flash_t * PI)

	# Subclass applies both to its material — one call, no conflicts
	apply_fade(brightness, alpha)

# ─────────────────────────────────────────────────────────────────────────────
#  VIRTUAL METHODS — override in subclasses
# ─────────────────────────────────────────────────────────────────────────────

## Called whenever any visual parameter changes.
## Override to rebuild mesh, update material, redraw geometry, etc.
func update_visuals() -> void:
	pass

## Called with the composed brightness multiplier and alpha.
## brightness > 1.0 when flash is active; alpha from fade_progress.
## Override to apply these to your material(s).
func apply_fade(brightness: float, alpha: float) -> void:
	pass
