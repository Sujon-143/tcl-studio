@tool 
class_name SlicedCircle
extends Circle2D


@export_range(0,360,1) var num_slice:int=1:
	set(v):
		num_slice= v
		queue_redraw()
	get:return num_slice	
	

@export_range(0,TAU,0.01) var angular_spreading:float=TAU:
	set(v):
		angular_spreading=v
		queue_redraw()
	get:
		return angular_spreading

@export var slice_thickness:float=1.0:
	set(v):
		slice_thickness= v	
		queue_redraw()
	get:
		return slice_thickness

@export var slice_color:Color= Color.WHITE:
	set(v):
		slice_color= v
		queue_redraw()
	get:return slice_color



func _draw() -> void:
	super._draw()
	for th in linspace(0,angular_spreading,num_slice):
		draw_line(
			Vector2.ZERO,
			radius*Vector2(cos(th),sin(th)),
			slice_color,slice_thickness,antialiased
		)

static func linspace(start: float, end: float, num: int) -> Array:
	if num <= 0:
		return []
	if num == 1:
		return [start]

	var result := []
	var step := (end - start) / (num - 1)

	for i in range(num):
		result.append(start + step * i)

	return result
	
	
	
	
	
