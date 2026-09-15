@tool
extends Button

signal component_drag_started(node_class: String)

var node_class := ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if node_class.is_empty():
		return null
	var preview := Label.new()
	preview.text = "  Add %s  " % node_class
	preview.add_theme_stylebox_override("normal", get_theme_stylebox("Panel", "EditorStyles"))
	set_drag_preview(preview)
	component_drag_started.emit(node_class)
	return {"type": "tcl_studio_node", "node_class": node_class}
