@tool
extends BaseLabel2D
class_name ValueTracker

@export_category("Config Variables")
@export_range(0, 5, 1.0, "prefer_slider") var num_digit: int = 2:
	set(value):
		num_digit = value
		_refresh_display()

@export_range(0,5,1.0,'prefer_slider') var digit_before:int=0:
	set(value):
		digit_before= value
		_refresh_display()



@export var value: float = 0.0:
	set(val):
		value = val
		_refresh_display()

@export var show_sign:bool=false

@export_category("Drive by Others")
@export var driver_node: NodePath:
	set(val):
		driver_node = val
		_reconnect()

@export var value_to_track: StringName:
	set(val):
		value_to_track = val
		_reconnect()

var _tracked_node: Node = null


func _enter_tree() -> void:
	set_process(true)  # ← critical: enables _process in editor for @tool scripts


func _ready() -> void:
	pivot_offset_ratio= Vector2.ONE*0.5
	_refresh_display()
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override('font_color',Color.BLACK)
	_reconnect()
	

func _process(_delta: float) -> void:
	_poll_value()


@export var show_preciding_value: bool=false:
	set(v): show_preciding_value= v;_refresh_display()
	get:return show_preciding_value

@export var preciding_string:String=">>":
	set(v):preciding_string= v;_refresh_display()
	get:return preciding_string
	

func _refresh_display() -> void:
	var total_width = digit_before + num_digit + (1 if num_digit > 0 else 0)
	text= ""
	text+= preciding_string if show_preciding_value else ""
	text+= "+%0*.*f" % [total_width, num_digit, value] if (show_sign and value>0) else "%0*.*f" % [total_width, num_digit, value]


func _reconnect() -> void:
	_tracked_node = null

	if driver_node.is_empty() or value_to_track == &"":
		return

	# get_node_or_null with NodePath relative to THIS node works in both editor and runtime
	var node := get_node_or_null(driver_node)
	if node == null:
		push_warning("ValueTracker: '%s' not found." % driver_node)
		return

	_tracked_node = node
	_poll_value()
	
	
func _poll_value() -> void:
	if _tracked_node == null or value_to_track == &"":
		return
	
	var new_val: float
	var prop := str(value_to_track)
	
	if "." in prop:
		var parts := prop.split(".", false, 1)
		var obj = _tracked_node.get(parts[0])
		if obj == null:
			return
		# Built-in types (Color, Vector2, etc.) can't use .get()
		# Use direct property access via the variant itself
		new_val = float(obj[parts[1]])
	else:
		var fetched = _tracked_node.get(prop)
		if fetched == null:
			return
		new_val = float(fetched)
	
	if new_val != value:
		value = new_val
