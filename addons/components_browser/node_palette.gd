@tool
extends ItemList

signal node_drag_started(node_class: String)

var entries: Array[Dictionary] = []


func _get_drag_data(_at_position: Vector2) -> Variant:
	var selected := get_selected_items()
	if selected.is_empty() or selected[0] >= entries.size():
		return null

	var node_class: String = entries[selected[0]]["class_name"]
	var preview := Label.new()
	preview.text = "  Add %s  " % node_class
	preview.add_theme_stylebox_override("normal", get_theme_stylebox("Panel", "EditorStyles"))
	set_drag_preview(preview)
	node_drag_started.emit(node_class)
	return {"type": "tcl_studio_node", "node_class": node_class}
