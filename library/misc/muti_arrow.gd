@tool
extends Arrow2D
class_name MultiArrow

@export var arrow_count: int = 5:
	set(v): arrow_count = v; queue_redraw()

## Total spread angle in degrees across all arrows
@export_range(10.0, 360.0, 1.0) var spread_angle: float = 60.0:
	set(v): spread_angle = v; queue_redraw()

## Length of each arrow
@export_range(10.0, 1000.0, 1.0) var arrow_length: float = 100.0:
	set(v): arrow_length = v; queue_redraw()

## Center direction angle in degrees (0 = right)
@export_range(-180.0, 180.0, 1.0) var base_angle: float = 0.0:
	set(v): base_angle = v; queue_redraw()


func _draw() -> void:
	if arrow_count <= 0:
		return

	# Save original start/end so we can restore after each arrow
	var orig_start := start
	var orig_end   := end

	for i in range(arrow_count):
		# Spread arrows evenly; with 1 arrow it sits at base_angle
		var t := 0.5 if arrow_count == 1 else float(i) / float(arrow_count - 1)
		var half := spread_angle * 0.5
		var angle_deg :float= base_angle + lerp(-half, half, t)
		var angle_rad := deg_to_rad(angle_deg)
		var dir := Vector2(cos(angle_rad), sin(angle_rad))

		start = Vector2.ZERO          # all arrows fan out from the node origin
		end   = dir * arrow_length

		super._draw()

	# Restore so inspector / other code still sees the originals
	start = orig_start
	end   = orig_end
