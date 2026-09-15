extends Node
class_name ProcAnimFX

var scale_helper: ProcAnimScale

func shake(item: Node, duration: float = 0.4, intensity: float = 8.0, frequency: int = 20) -> void:
	if not is_instance_valid(item): return
	var origin: Variant
	if item is Node2D:        origin = (item as Node2D).position
	elif item is Node3D:      origin = (item as Node3D).position
	else: push_warning("ProcAnim.shake: unsupported node type"); return
	var step_time := duration / float(frequency)
	for _i in frequency:
		if item is Node2D:
			(item as Node2D).position = origin + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		else:
			(item as Node3D).position = origin + Vector3(randf_range(-intensity, intensity), randf_range(-intensity, intensity), 0.0)
		await get_tree().create_timer(step_time).timeout
	if item is Node2D: (item as Node2D).position = origin
	else:              (item as Node3D).position = origin

func pulse(item: Node, cycles: int = 3, scale_amount: float = 1.15, cycle_duration: float = 0.3) -> void:
	if not is_instance_valid(item): return
	var base = scale_helper._neutral_scale(item)
	var big: Variant
	if item is Node3D:        big = (item as Node3D).scale * scale_amount
	elif item is Node2D:      big = (item as Node2D).scale * scale_amount
	else: push_warning("ProcAnim.pulse: unsupported node type"); return
	for _i in cycles:
		var twn := create_tween()
		twn.tween_property(item, "scale", big, cycle_duration * 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		twn.tween_property(item, "scale", base, cycle_duration * 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await twn.finished
		if is_instance_valid(twn): twn.kill()
