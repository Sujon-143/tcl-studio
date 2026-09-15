@tool
class_name TriangleVerticesAnnotator
extends Node2D

@export var annote_va:bool=false:
	set(value):
		annote_va= value
		queue_redraw()
	get:
		return annote_va

@export var annote_vb:bool=false:
	set(value):
		annote_vb= value
		queue_redraw()
	get:
		return annote_vb

@export var annote_vc:bool=false:
	set(value):
		annote_vc= value
		queue_redraw()
	get:
		return annote_vc


@export var triangle:Triangle2D=null:
	set(value):
		triangle= value
		if triangle!=null:
			build_circles()
	get:
		return triangle

@export_range(0.0,1.0,0.01) var progress:float= 0.0:
	set(value):
		progress= value
		apply_popups()
	get:
		return progress

@export var annotation_color:Color= Color.RED:
	set(value):
		annotation_color= value
		if circ_a!=null:
			circ_a.color= value
		if circ_b!=null:
			circ_b.color= value
		if circ_c!=null:
			circ_c.color= value
	get:
		return annotation_color


var circ_a:Circle2D=null
var circ_b:Circle2D= null
var circ_c:Circle2D=null




func _enter_tree():
	if triangle!=null:
		build_circles()

func build_circles():
	circ_a= Circle2D.new()
	circ_a.dashed=true
	circ_a.dash_length= 20.0
	add_child(circ_a)

	circ_b= Circle2D.new()
	circ_b.dashed=true
	circ_b.dash_length= 20.0
	add_child(circ_b)

	circ_c= Circle2D.new()
	circ_c.dashed=true
	circ_c.dash_length= 20.0
	add_child(circ_c)
	circ_a.popup_progress= 0.0
	circ_b.popup_progress= 0.0
	circ_c.popup_progress= 0.0
	
	circ_a.global_position= triangle.to_global(triangle.point_a*triangle.unit_size)
	circ_b.global_position= triangle.to_global(triangle.point_b*triangle.unit_size)
	circ_c.global_position= triangle.to_global(triangle.point_c*triangle.unit_size)

func apply_popups():
	if annote_va:
		circ_a.popup_progress= progress
	if annote_vb:
		circ_b.popup_progress= progress
	if annote_vc:
		circ_c.popup_progress= progress



func _exit_tree():
	circ_a.queue_free()
	circ_b.queue_free()
	circ_c.queue_free()
	circ_a= null
	circ_b= null
	circ_c= null
