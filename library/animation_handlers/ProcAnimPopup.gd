extends Node
class_name ProcAnimPopup

var scale_helper: ProcAnimScale
var parallel: ProcAnimParallel

func _auto_kill(twn: Tween) -> void:
	if is_instance_valid(twn): twn.kill()

func show_item_popup(item: Node, duration: float = 0.5) -> void:
	if not is_instance_valid(item): return
	var target = scale_helper._neutral_scale(item)
	if target == null:
		push_warning("ProcAnim.show_item_popup: unsupported node type %s" % item.get_class())
		return
	scale_helper.set_scale(item, scale_helper._zero_scale(item))
	item.show()
	var twn := create_tween()
	twn.tween_property(item, "scale", target, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await twn.finished
	_auto_kill(twn)

func hide_item_popup(item: Node, duration: float = 0.5) -> void:
	if not is_instance_valid(item): return
	scale_helper._register_resting_scale(item)
	var original = scale_helper._neutral_scale(item)
	if original == null:
		push_warning("ProcAnim.hide_item_popup: unsupported node type %s" % item.get_class())
		return
	var twn := create_tween()
	twn.tween_property(item, "scale", scale_helper._zero_scale(item), duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await twn.finished
	_auto_kill(twn)
	if is_instance_valid(item):
		item.hide()
		scale_helper.set_scale(item, original)

func show_items_popup_sequential(array_of_items: Array, total_time: float) -> void:
	if array_of_items.is_empty(): return
	var per := clampf(total_time / array_of_items.size(), 0.05, total_time)
	for item in array_of_items:
		await show_item_popup(item, per)

func hide_items_popup_sequential(array_of_items: Array, total_time: float) -> void:
	if array_of_items.is_empty(): return
	var per := clampf(total_time / array_of_items.size(), 0.05, total_time)
	for item in array_of_items:
		await hide_item_popup(item, per)

func show_items_popup_parallel(array_of_items: Array, duration: float = 0.5) -> void:
	var signals: Array[Signal] = []
	for item in array_of_items:
		if not is_instance_valid(item): continue
		var target = scale_helper._neutral_scale(item)
		if target == null: continue
		scale_helper.set_scale(item, scale_helper._zero_scale(item))
		item.show()
		var twn := create_tween()
		twn.tween_property(item, "scale", target, duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		signals.append(twn.finished)
	for sig in signals: await sig

func show_items_popup_staggered(array_of_items: Array, duration: float = 0.5, stagger_delay: float = 0.1) -> void:
	for i in array_of_items.size():
		var item = array_of_items[i]
		if not is_instance_valid(item): continue
		var target = scale_helper._neutral_scale(item)
		if target == null: continue
		scale_helper.set_scale(item, scale_helper._zero_scale(item))
		item.show()
		var twn := create_tween()
		if i > 0: twn.tween_interval(stagger_delay * i)
		twn.tween_property(item, "scale", target, duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await parallel.wait(stagger_delay * (array_of_items.size() - 1) + duration)

func hide_items_popup_parallel(array_of_items: Array, duration: float = 0.5) -> void:
	var originals: Array = []
	var zeros: Array = []
	for item in array_of_items:
		if is_instance_valid(item):
			scale_helper._register_resting_scale(item)
			originals.append(scale_helper._neutral_scale(item))
			zeros.append(scale_helper._zero_scale(item))
		else:
			originals.append(null)
			zeros.append(null)
	var signals: Array[Signal] = []
	for i in array_of_items.size():
		var item = array_of_items[i]
		if not is_instance_valid(item) or zeros[i] == null: continue
		var twn := create_tween()
		twn.tween_property(item, "scale", zeros[i], duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		signals.append(twn.finished)
	for sig in signals: await sig
	for i in array_of_items.size():
		var item = array_of_items[i]
		if is_instance_valid(item) and originals[i] != null:
			item.hide()
			scale_helper.set_scale(item, originals[i])
