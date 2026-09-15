@tool
class_name FunctionPlot2D
extends BaseShape2D


@export var function_expressionression:String:
	set(v):
		function_expressionression=v
		queue_redraw()

@export var color:Color= Color.BROWN:
	set(v):
		color=v;queue_redraw()
@export var thickness:float=5.0:
	set(v):thickness=v;queue_redraw()

@export var lower_limit:float=-5:
	set(v):
		lower_limit=v;queue_redraw()

@export var upper_limit:float=5:
	set(v):
		upper_limit= v;queue_redraw()

@export var dashed:bool=false:
	set(v):dashed= v;queue_redraw()
@export var variable_name:String= "x":
	set(v):variable_name= v;queue_redraw()

var is_expressionression_valid:bool=false
var expression:Expression
var pt:PackedVector2Array


func _ready():
	super._ready()
	expression= Expression.new()
	pt= PackedVector2Array()
	

@export var ax:AxisGrid2D:
	set(v):
		ax= v;
		global_position= ax.global_position

func _draw() -> void:
	super._draw()
	if ax==null:
		return
	
	var err= expression.parse(function_expressionression,PackedStringArray([variable_name]))
	if err!= OK:
		print("invalid function")
		return
	
	print("valid expressionression")
	pt.clear()
	for t in SlicedCircle.linspace(lower_limit,
				lerp(lower_limit,upper_limit,draw_progress),100*draw_progress):
		var y= expression.execute([t],self,true,false)
		pt.push_back(global_position+ ax.to_local(Vector2(t*ax.unit_size,-y*ax.unit_size)))
	
	if pt.size()<2:
		return
	if dashed:
		draw_multiline(pt,color,thickness,true)
	else:
		draw_polyline(pt,color,thickness,true)
