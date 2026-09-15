extends Node
class_name ProcAnimTransform

var popup: ProcAnimPopup

func _auto_kill(twn: Tween) -> void:
	if is_instance_valid(twn): twn.kill()

func transform_from_object(from: Node, target: Node, remove: bool = false, time: float = 1.0) -> void:
	if not is_instance_valid(from) or not is_instance_valid(target): return
	if from is Node3D and target is Node3D:
		var twn := create_tween()
		twn.tween_property(from, "global_position", (target as Node3D).global_position, time * 0.2) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await twn.finished
		_auto_kill(twn)
	await popup.hide_item_popup(from, 0.4 * time)
	await popup.show_item_popup(target, 0.4 * time)
	if remove and is_instance_valid(from):
		if from.get_parent(): from.get_parent().remove_child(from)
		from.queue_free()

func transform_camera(camera_1: Camera3D, camera_2: Camera3D, time: float):
	var old_transform := camera_1.global_transform
	var twn := create_tween()
	twn.tween_property(camera_1, "global_transform", camera_2.global_transform, time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await twn.finished
	_auto_kill(twn)
	
func restore_camera(camera_1: Camera3D, saved_transform: Transform3D, time: float = 1.0) -> void:
	var twn := create_tween()
	twn.tween_property(camera_1, "global_transform", saved_transform, time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await twn.finished
	_auto_kill(twn)
