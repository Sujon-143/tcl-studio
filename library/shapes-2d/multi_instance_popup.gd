@tool
extends Node2D
class_name MultiInstancePopup

@export var items_to_popup: Array[NodePath] = []

@export var working: bool = false:
	set(value):
		working = value
		queue_redraw()

@export_range(0.0, 1.0, 0.01, 'prefer_slider') var popup_progress: float = 1.0:
	set(value):
		popup_progress = value
		_apply_to_children(value)
	get:
		return popup_progress

func _apply_to_children(value: float) -> void:
	if not working:
		return
	if not is_inside_tree():
		return
	for item_path in items_to_popup:
		var node: Node = get_node_or_null(item_path)
		if node == null or not node.is_inside_tree():
			continue
		# Avoid setting if value is already the same (breaks AnimationPlayer loops)
		if node.get("popup_progress") == value:
			continue
		node.set("popup_progress", value)
		
		if node.get('PopupProgress')==value:
			continue
		node.set('PopupProgress',value)
		
		
		
		
