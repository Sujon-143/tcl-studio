@tool
extends MeshInstance3D
class_name BaseMeshInstance3D

@export_category('Apperence Animations')

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
		target.scale = Vector3(0.1,0.1,0.1)
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
	target.scale = Vector3.ONE * (popup_scale + ind_offset)
