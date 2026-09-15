@tool
extends Label3D
class_name BaseLabel3D

@export_category('Appearance Animations')

@export_range(0.01, 4.0, 0.01) var base_scale: float = 1.0:
	set(v):
		base_scale = v
		_update_scale()

@export_range(0.0, 1.0, 0.01) var popup_progress: float = 1.0:
	set(v):
		popup_progress = v
		visible = popup_progress > 0.01
		_update_scale()

@export_category('Indication Animations')

@export_range(0.0, 1.0, 0.01) var indicate_progress: float = 0.0:
	set(v):
		indicate_progress = v
		_update_scale()

@export_range(0.0, 1.0, 0.01) var indicate_scale_boost: float = 0.2:
	set(v):
		indicate_scale_boost = v
		_update_scale()

@export_category("Important Properties")

@export_multiline var txt: String = "":
	set(v):
		txt = v
		text = v

@export var font_color: Color = Color.WHITE:
	set(v):
		font_color = v
		modulate = v

@export var outline_color: Color = Color.BLACK:
	set(v):
		outline_color = v
		outline_modulate = v

@export var fnt_size: int = 30:
	set(v):
		fnt_size = v
		font_size = v

@export var outln_size: int = 0:
	set(v):
		outln_size = v
		outline_size = v

func _update_scale() -> void:
	var s := base_scale

	if popup_progress > 0.01:
		s *= TransitionFunctions.ease_out(TransitionFunctions.trans_back, popup_progress)

	var indicate_t := TransitionFunctions.ease_in_out(
		TransitionFunctions.trans_sine, indicate_progress
	)
	s *= 1.0 + indicate_scale_boost * sin(indicate_t * PI)

	scale = Vector3(s, s, s)
