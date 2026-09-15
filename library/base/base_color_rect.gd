@tool
extends ColorRect
class_name WipeRect

@export_category("Appearance Animations")

var start_pos: Vector2
var end_pos: Vector2 = Vector2.ZERO

@export_range(0, 1.0, 0.01) var wipe_progress: float = 0.0:
	set(value):
		wipe_progress = value
		
		var t = TransitionFunctions.ease_out(
			TransitionFunctions.trans_back, value
		)

		global_position = start_pos.lerp(end_pos, t)


func _ready():
	custom_minimum_size = Vector2(1920, 1080)
	start_pos = Vector2(-1920, 0)
	global_position = start_pos
