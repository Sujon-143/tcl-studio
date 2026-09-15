extends Node
class_name ProcAnimFade

func _auto_kill(twn: Tween) -> void:
	if is_instance_valid(twn): twn.kill()

func fade_in(item: CanvasItem, duration: float = 0.5) -> void:
	item.modulate.a = 0.0
	item.show()
	var twn := create_tween()
	twn.tween_property(item, "modulate:a", 1.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await twn.finished
	_auto_kill(twn)

func fade_out(item: CanvasItem, duration: float = 0.5) -> void:
	var twn := create_tween()
	twn.tween_property(item, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await twn.finished
	_auto_kill(twn)
	if is_instance_valid(item):
		item.hide()
		item.modulate.a = 1.0

func fade_in_sequential(array_of_items: Array, total_time: float) -> void:
	if array_of_items.is_empty(): return
	var dur := clampf(total_time / array_of_items.size(), 0.05, total_time)
	for item in array_of_items: await fade_in(item, dur)

func fade_out_sequential(array_of_items: Array, total_time: float) -> void:
	if array_of_items.is_empty(): return
	var dur := clampf(total_time / array_of_items.size(), 0.05, total_time)
	for item in array_of_items: await fade_out(item, dur)
