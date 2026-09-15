@tool
class_name CrossMark
extends BaseShape2D

@export var target: NodePath:
	set(value):
		target = value
		queue_redraw()
	get:
		return target
@export var color:Color= Color.RED:
	set(value):
		color= value
		queue_redraw()
	get:
		return color

@export var line_width:float=5.00:
	set(value):
		line_width= value
		queue_redraw()
	get:
		return line_width

@export var size:Vector2= Vector2(100,100):
	set(value):
		size= value
		queue_redraw()
	get:
		return size


func _draw():
	super._draw()
	var target_node = get_node(target)
	if target_node == null:
		return
	
	var top_left = -size/2
	
	var p1 = top_left
	var p2 = top_left + size
	var p3 = top_left + Vector2(size.x, 0)
	var p4 = top_left + Vector2(0, size.y)

	draw_line(p1, p2, color, line_width,true)
	draw_line(p3, p4, color, line_width,true)
