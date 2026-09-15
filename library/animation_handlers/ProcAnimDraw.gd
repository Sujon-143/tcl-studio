extends Node
class_name ProcAnimDraw

func _auto_kill(twn: Tween) -> void:
	if is_instance_valid(twn): twn.kill()

func create_object(item: Node, run_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		_ease: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if not is_instance_valid(item): return
	if not "draw_progress" in item:
		push_warning("ProcAnim.create_object: node '%s' has no draw_progress property." % item.name)
		return
	item.show()
	item.draw_progress = 0.0
	item.draw()
	var twn := create_tween()
	twn.tween_method(
		func(value: float) -> void:
			item.draw_progress = value
			item.draw(),
		0.0, 1.0, run_time
	).set_trans(trans).set_ease(_ease)
	await twn.finished
	_auto_kill(twn)

func create_objects_sequential(items: Array, total_time: float,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		_ease: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if items.is_empty(): return
	var per_item := clampf(total_time / items.size(), 0.05, total_time)
	for item in items:
		item.show()
		await create_object(item, per_item, trans, _ease)

func create_objects_parallel(items: Array, run_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		_ease: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if items.is_empty(): return
	var signals: Array[Signal] = []
	for item in items:
		if not is_instance_valid(item) or not "draw_progress" in item: continue
		item.show()
		item.draw_progress = 0.0
		item.draw()
		var twn := create_tween()
		twn.tween_method(
			func(value: float) -> void:
				item.draw_progress = value
				item.draw(),
			0.0, 1.0, run_time
		).set_trans(trans).set_ease(_ease)
		signals.append(twn.finished)
	for sig in signals: await sig

func create_objects_staggered(items: Array, run_time: float = 1.0,
		stagger_delay: float = 0.15,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		_ease: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if items.is_empty(): return
	for item in items:
		if not is_instance_valid(item) or not "draw_progress" in item: continue
		item.show()
		item.draw_progress = 0.0
		item.draw()
	for i in items.size():
		var item = items[i]
		if not is_instance_valid(item): continue
		var twn := create_tween()
		if i > 0: twn.tween_interval(stagger_delay * i)
		twn.tween_method(
			func(value: float) -> void:
				item.draw_progress = value
				item.draw(),
			0.0, 1.0, run_time
		).set_trans(trans).set_ease(_ease)
	# wait is not available here directly; use a local tween
	var wait_twn := create_tween()
	wait_twn.tween_interval(stagger_delay * (items.size() - 1) + run_time)
	await wait_twn.finished
	_auto_kill(wait_twn)
