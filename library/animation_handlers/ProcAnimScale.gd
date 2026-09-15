extends Node
class_name ProcAnimScale

var _resting_scales: Dictionary = {}

func _register_resting_scale(item: Node, force: bool = false) -> void:
	var id := item.get_instance_id()
	if force or not _resting_scales.has(id):
		if item is Node3D: _resting_scales[id] = (item as Node3D).scale
		elif item is Node2D: _resting_scales[id] = (item as Node2D).scale

func _neutral_scale(item: Node) -> Variant:
	var id := item.get_instance_id()
	if _resting_scales.has(id):
		return _resting_scales[id]
	_register_resting_scale(item)
	if item is Node3D: return (item as Node3D).scale
	if item is Node2D: return (item as Node2D).scale
	return null

func _zero_scale(item: Node) -> Variant:
	var rest = _neutral_scale(item)
	if rest == null: return null
	return rest * 0.05

func set_scale(item: Node, s: Variant) -> void:
	if item is Node2D:   (item as Node2D).scale = s
	elif item is Node3D: (item as Node3D).scale = s
