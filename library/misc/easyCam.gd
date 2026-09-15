@tool
extends Camera3D
class_name EasyCam


@export var look_at_pos:Vector3= Vector3.ZERO:
	set(value):
		look_at_pos= value
		if not is_inside_tree():return	
		else:
			look_at(look_at_pos)
	get:return look_at_pos
