extends Node
class_name ProcAnimParallel

var _dummy: float = 0.0

func wait(time: float) -> void:
	if time <= 0.0: return
	var twn := create_tween()
	twn.tween_property(self, "_dummy", randf(), time)
	await twn.finished
	if is_instance_valid(twn): twn.kill()

func play_parallel(tasks: Array) -> void:
	if tasks.is_empty(): return
	var max_duration: float = 0.0
	for entry in tasks:
		if not (entry is Array) or entry.size() < 2:
			push_warning("ProcAnim.play_parallel: each entry must be [Callable, float]")
			continue
		var fn: Callable = entry[0]
		var dur: float    = float(entry[1])
		if not fn.is_valid():
			push_warning("ProcAnim.play_parallel: invalid Callable in task list")
			continue
		var launcher := create_tween()
		launcher.tween_callback(fn)
		max_duration = maxf(max_duration, dur)
	await wait(max_duration)
