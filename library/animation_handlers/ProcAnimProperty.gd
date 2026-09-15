extends Node
class_name ProcAnimProperty

func _auto_kill(twn: Tween) -> void:
	if is_instance_valid(twn): twn.kill()

# ── single item ───────────────────────────────────────────────────────────────

func tween_property(
		item,
		property: String,
		from: Variant,
		to: Variant,
		run_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		callback: Callable = Callable()   # optional: called each tick with (value)
) -> void:
	if not is_instance_valid(item): return
	
	# validate property exists on this node
	var has_prop = item.get_property_list().any(func(p): return p["name"] == property)
	if not has_prop:
		push_warning("ProcAnimProperty: node '%s' has no property '%s'." % [item.name, property])
		return

	item.set(property, from)
	var twn := create_tween()
	twn.tween_method(
		func(value: Variant) -> void:
			item.set(property, value)
			if callback.is_valid(): callback.call(value),
		from, to, run_time
	).set_trans(trans).set_ease(ease_type)
	await twn.finished
	_auto_kill(twn)

# ── sequential ────────────────────────────────────────────────────────────────

func tween_sequential(
		items: Array,
		property: String,
		from: Variant,
		to: Variant,
		total_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		callback: Callable = Callable()
) -> void:
	if items.is_empty(): return
	var per_item := clampf(total_time / items.size(), 0.05, total_time)
	for item in items:
		await tween_property(item, property, from, to, per_item, trans, ease_type, callback)

# ── parallel ──────────────────────────────────────────────────────────────────

func tween_parallel(
		items: Array,
		property: String,
		from: Variant,
		to: Variant,
		run_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		callback: Callable = Callable()
) -> void:
	if items.is_empty(): return
	var tweens: Array[Tween] = []
	for item in items:
		if not is_instance_valid(item): continue
		var has_prop = item.get_property_list().any(func(p): return p["name"] == property)
		if not has_prop:
			push_warning("ProcAnimProperty: node '%s' has no property '%s'." % [item.name, property])
			continue
		item.set(property, from)
		var twn := create_tween()
		twn.tween_method(
			func(value: Variant) -> void:
				item.set(property, value)
				if callback.is_valid(): callback.call(value),
			from, to, run_time
		).set_trans(trans).set_ease(ease_type)
		tweens.append(twn)
	for twn in tweens: await twn.finished

# ── staggered ─────────────────────────────────────────────────────────────────

func tween_staggered(
		items: Array,
		property: String,
		from: Variant,
		to: Variant,
		run_time: float = 1.0,
		stagger_delay: float = 0.15,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		callback: Callable = Callable()
) -> void:
	if items.is_empty(): return

	# pre-set all items to `from` before any tween starts
	for item in items:
		if is_instance_valid(item): item.set(property, from)

	for i in items.size():
		var item = items[i]
		if not is_instance_valid(item): continue
		var has_prop = item.get_property_list().any(func(p): return p["name"] == property)
		if not has_prop:
			push_warning("ProcAnimProperty: node '%s' has no property '%s'." % [item.name, property])
			continue
		var twn := create_tween()
		if i > 0:
			twn.tween_interval(stagger_delay * i)
		twn.tween_method(
			func(value: Variant) -> void:
				item.set(property, value)
				if callback.is_valid(): callback.call(value),
			from, to, run_time
		).set_trans(trans).set_ease(ease_type)

	# wait for the last item to finish
	var total_wait := stagger_delay * (items.size() - 1) + run_time
	var wait_twn := create_tween()
	wait_twn.tween_interval(total_wait)
	await wait_twn.finished
	_auto_kill(wait_twn)
