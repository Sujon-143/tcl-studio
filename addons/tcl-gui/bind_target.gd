@tool
class_name BindTarget
extends Resource
## A single (node, property) binding target for a GUI control.
## A control's `bind_to` is an Array[BindTarget], so one slider/button
## can drive several values at once.

## The node in the scene tree whose property/method will be updated.
## Relative to the control's own position in the tree (uses get_node_or_null).
@export var target_node: NodePath = NodePath("")

## The property name to set, or the method name to call (see call_as_method).
## If the GUI Elements editor plugin is enabled, this renders as a dropdown
## populated from target_node's actual properties/methods instead of free text.
@export var target_property: StringName = &""

## If true, target_property is treated as a method name and called with the
## control's value as its single argument, instead of being assigned directly.
## Use this for buttons ("pressed") or anything that needs custom logic.
@export var call_as_method: bool = false

## Optional linear remap of the control's raw value before applying it.
## Leave enable_remap off to pass the value through unchanged.
@export var enable_remap: bool = false
@export var remap_in_min: float = 0.0
@export var remap_in_max: float = 1.0
@export var remap_out_min: float = 0.0
@export var remap_out_max: float = 1.0


func apply(root: Node, value: Variant) -> void:
	if target_node.is_empty() or target_property == &"":
		return
	var node: Node = root.get_node_or_null(target_node)
	if node == null:
		push_warning("BindTarget: node not found at path '%s'" % target_node)
		return

	var v: Variant = value
	if enable_remap and typeof(value) in [TYPE_FLOAT, TYPE_INT]:
		v = remap(float(value), remap_in_min, remap_in_max, remap_out_min, remap_out_max)

	if call_as_method:
		if node.has_method(target_property):
			node.call(target_property, v)
		else:
			push_warning("BindTarget: '%s' has no method '%s'" % [node.name, target_property])
	else:
		node.set(target_property, v)
