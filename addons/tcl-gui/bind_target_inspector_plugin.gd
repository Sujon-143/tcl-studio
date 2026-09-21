@tool
extends EditorInspectorPlugin
## Two cases:
## 1. A BindTarget resource is being edited (expanded inside a
##    GuiElement2D's bind_to array) -> replace target_property with a
##    dropdown built from target_node's properties/methods.
## 2. A LevelMeter2D node is being edited -> replace source_property with
##    a dropdown built from source_node's properties, resolved directly
##    against the node itself (no scene-selection lookup needed here,
##    since the node being edited IS the owner).


func _can_handle(object: Object) -> bool:
	return object is BindTarget or object is LevelMeter2D


func _parse_property(
	object: Object,
	type: Variant.Type,
	name: String,
	hint_type: PropertyHint,
	hint_string: String,
	usage_flags: int,
	wide: bool
) -> bool:
	if name == "target_property" and object is BindTarget:
		var picker := preload('res://addons/tcl-gui/bind_target_property_picker.gd').new()
		picker.setup(object as BindTarget)
		add_property_editor(name, picker)
		return true

	if name == "source_property" and object is LevelMeter2D:
		var picker := preload('res://addons/tcl-gui/source_property_picker.gd').new()
		picker.setup(object as LevelMeter2D)
		add_property_editor(name, picker)
		return true

	return false
