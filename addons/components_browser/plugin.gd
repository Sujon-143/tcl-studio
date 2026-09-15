@tool
extends EditorPlugin

const TCL_NODE_DOCK := preload("res://addons/components_browser/tcl_node_dock.gd")
const TCL_NODE_CATALOG := preload("res://addons/components_browser/node_catalog.gd")

var node_dock: Control
var panel_button: Button
var dragging_node_class := ""


func _enter_tree() -> void:

	node_dock = TCL_NODE_DOCK.new()
	node_dock.editor_interface = get_editor_interface()
	node_dock.undo_redo = get_undo_redo()
	node_dock.catalog_entries = TCL_NODE_CATALOG.NODES
	node_dock.node_drag_started.connect(_on_node_drag_started)
	panel_button = add_control_to_bottom_panel(node_dock, "Components")
	panel_button.tooltip_text = "Browse and drag TCL Studio components into the active scene."


func _exit_tree() -> void:

	if is_instance_valid(node_dock):
		remove_control_from_bottom_panel(node_dock)
		node_dock.queue_free()


func _on_node_drag_started(node_class: String) -> void:
	dragging_node_class = node_class


func _handles(object: Object) -> bool:
	# Enables the 2D editor's forwarding callbacks for the active scene.
	return object is Node


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if _is_drag_drop(event):
		node_dock.add_node_by_class(dragging_node_class)
		dragging_node_class = ""
	return false


func _forward_3d_gui_input(_camera: Camera3D, event: InputEvent) -> int:
	if _is_drag_drop(event):
		node_dock.add_node_by_class(dragging_node_class)
		dragging_node_class = ""
	return AFTER_GUI_INPUT_PASS


func _is_drag_drop(event: InputEvent) -> bool:
	if dragging_node_class.is_empty() or not event is InputEventMouseButton or event.pressed:
		return false
	var drag_data := get_viewport().gui_get_drag_data()
	return drag_data is Dictionary and drag_data.get("type", "") == "tcl_studio_node"
