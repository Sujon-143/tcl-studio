@tool
extends Sprite2D
class_name BaseSprite

@export_category('Apperence Animations')
@export var base_scale:float=1.0:
	set(value):
		base_scale= value
		_update_scale()
	get:
		return base_scale



@export_range(0, 1.0, 0.01) var popup_progress: float = 0.0:
	set(value):
		popup_progress = value
		_update_scale()

@export_range(0, 1.0, 0.01) var indication_progress: float = 0.0:
	set(value):
		indication_progress = value
		_update_scale()

func _update_scale() -> void:
	var target = self

	# --- Visibility gate (driven by popup only) ---
	if popup_progress <= 0.05:
		target.hide()
		target.scale = Vector2(0.1,0.1)
		return
	else:
		target.show()

	# --- Popup scale contribution ---
	var popup_scale: float = TransitionFunctions.ease_out(
		TransitionFunctions.trans_back, popup_progress
	)

	# --- Indication scale contribution ---
	var delta_scale := 0.2
	var ind_offset: float

	if indication_progress <= 0.5:
		var t = indication_progress / 0.5
		ind_offset = delta_scale * TransitionFunctions.ease_out(
			TransitionFunctions.trans_back, t
		)
	else:
		var t = (indication_progress - 0.5) / 0.5
		ind_offset = delta_scale - delta_scale * TransitionFunctions.ease_out(
			TransitionFunctions.trans_back, t
		)

	# --- Apply combined scale (no conflict) ---
	target.scale = base_scale*Vector2.ONE * (popup_scale + ind_offset)


func _ready():
	pass
func _input(event):
	pass
