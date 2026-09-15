@tool
extends BaseShape2D
class_name Dot2D


@export var radius:float=100:
	set(value):
		radius=value
		queue_redraw()
	get:
		return radius

@export var color:Color= Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		color= value
		queue_redraw()
	get:
		return color

@export var labeled:bool=false:
	set(v):labeled=v;queue_redraw()

@export var label:String= 'A':
	set(v):label=v;queue_redraw()

@export var label_color:Color= Color.BLACK:
	set(v):label_color= v;queue_redraw()

@export var label_font_size:int=30:
	set(v):label_font_size=v;queue_redraw()
	




func _draw():
	super._draw()
	draw_circle(
		Vector2.ZERO,radius,color,true,-1,true
	)
	if labeled:
		Util.draw_centered_string(
			self,ThemeDB.fallback_font,Vector2.ZERO,label,-1,label_font_size,label_color
)
