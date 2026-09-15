extends Node
class_name ProcAnim

var _scale:     ProcAnimScale
var _parallel:  ProcAnimParallel
var _popup:     ProcAnimPopup
var _fade:      ProcAnimFade
var _fx:        ProcAnimFX
var _move:      ProcAnimMove
var _transform: ProcAnimTransform
var _indicate:  ProcAnimIndicate
var _draw:      ProcAnimDraw
var _property:  ProcAnimProperty  # ← new

func _ready() -> void:
	_scale     = ProcAnimScale.new()
	_parallel  = ProcAnimParallel.new()
	_popup     = ProcAnimPopup.new()
	_fade      = ProcAnimFade.new()
	_fx        = ProcAnimFX.new()
	_move      = ProcAnimMove.new()
	_transform = ProcAnimTransform.new()
	_indicate  = ProcAnimIndicate.new()
	_draw      = ProcAnimDraw.new()
	_property  = ProcAnimProperty.new()  # ← new

	_popup.scale_helper = _scale
	_popup.parallel     = _parallel
	_fx.scale_helper    = _scale
	_transform.popup    = _popup

	for m in [_scale, _parallel, _popup, _fade, _fx, _move, _transform, _indicate, _draw, _property]:
		add_child(m)
		#m._ready()  # force immediate init in editor context


# ── Parallel / wait ───────────────────────────────────────────────────────────

func play_parallel(tasks: Array) -> void: await _parallel.play_parallel(tasks)
func wait(time: float) -> void:           await _parallel.wait(time)


# ── Popup — single ────────────────────────────────────────────────────────────


func show_item_popup(item: Node, duration: float = 0.5) -> void:
	await _popup.show_item_popup(item, duration)

func hide_item_popup(item: Node, duration: float = 0.5) -> void:
	await _popup.hide_item_popup(item, duration)


# ── Popup — arrays ────────────────────────────────────────────────────────────

func show_items_popup_sequential(a: Array, t: float) -> void:
	for item in a:
		item.hide()
	await _popup.show_items_popup_sequential(a, t)

func hide_items_popup_sequential(a: Array, t: float) -> void:
	await _popup.hide_items_popup_sequential(a, t)

func show_items_popup_parallel(a: Array, d: float = 0.5) -> void:
	await _popup.show_items_popup_parallel(a, d)

func show_items_popup_staggered(a: Array, d: float = 0.5, s: float = 0.1) -> void:
	await _popup.show_items_popup_staggered(a, d, s)

func hide_items_popup_parallel(a: Array, d: float = 0.5) -> void:
	await _popup.hide_items_popup_parallel(a, d)


# ── Fade ──────────────────────────────────────────────────────────────────────

func fade_in(item: CanvasItem, duration: float = 0.5) -> void:
	await _fade.fade_in(item, duration)

func fade_out(item: CanvasItem, duration: float = 0.5) -> void:
	await _fade.fade_out(item, duration)

func fade_in_sequential(a: Array, t: float) -> void:
	await _fade.fade_in_sequential(a, t)

func fade_out_sequential(a: Array, t: float) -> void:
	await _fade.fade_out_sequential(a, t)


# ── FX ────────────────────────────────────────────────────────────────────────

func shake(item: Node, duration: float = 0.4, intensity: float = 8.0, frequency: int = 20) -> void:
	await _fx.shake(item, duration, intensity, frequency)

func pulse(item: Node, cycles: int = 3, scale_amount: float = 1.15, cycle_duration: float = 0.3) -> void:
	await _fx.pulse(item, cycles, scale_amount, cycle_duration)


# ── Move ──────────────────────────────────────────────────────────────────────

func move_to_2d(item: Node2D, target_pos: Vector2, duration: float = 0.5,show_arrow:bool=false,
		trans := Tween.TRANS_CUBIC, _ease := Tween.EASE_IN_OUT) -> void:
	await _move.move_to_2d(item, target_pos, duration,show_arrow, trans, _ease)

func move_to_3d(item: Node3D, target_pos: Vector3, duration: float = 0.5,show_arrow:bool=false,
		trans := Tween.TRANS_CUBIC, _ease := Tween.EASE_IN_OUT) -> void:
	await _move.move_to_3d(item, target_pos, duration,show_arrow, trans, _ease)

func shift3D(item:Node3D,amount:Vector3,duration:float=0.5):
	await _move.shift3D(item,amount,duration)

func rotation_3d(item: Node3D, rotation_amount: Vector3, duration: float = 0.5,show_circle:bool=false,
		trans := Tween.TRANS_CUBIC, _ease := Tween.EASE_IN_OUT) -> void:
	await _move.rotation_3d(item, rotation_amount, duration,show_circle, trans, _ease)

func rotate_around_3d(item: Node3D, center: Vector3, axis: Vector3, angle: float,
		duration: float = 0.5, show_circle: bool = false,
		trans := Tween.TRANS_CUBIC, _ease := Tween.EASE_IN_OUT) -> void:
	await _move.rotate_around_3d(item, center, axis, angle, duration, show_circle, trans, _ease)

# ── Transform ─────────────────────────────────────────────────────────────────

func transform_from_object(from: Node, target: Node, remove: bool = false, time: float = 1.0) -> void:
	await _transform.transform_from_object(from, target, remove, time)

func transform_camera(camera_1: Camera3D, camera_2: Camera3D, time: float):
	await _transform.transform_camera(camera_1, camera_2, time)

func restore_camera(camera_1: Camera3D, saved_transform: Transform3D, time: float = 1.0) -> void:
	await _transform.restore_camera(camera_1, saved_transform, time)


# ── Indicate / Broadcast ──────────────────────────────────────────────────────

func indicate_3d(item: Node3D, scale_factor: float = 1.25,
		color: Color = Color(1.0, 0.9, 0.0, 1.0), duration: float = 0.5) -> void:
	await _indicate.indicate_3d(item, scale_factor, color, duration)

func broadcast_3d(item: Node3D, n_rings: int = 3, max_radius: float = 2.5,
		color: Color = Color.WHITE, duration: float = 0.8,
		tube_radius: float = 0.04, axis: Vector3 = Vector3.UP) -> void:
	await _indicate.broadcast_3d(item, n_rings, max_radius, color, duration, tube_radius, axis)


# ── Draw / Create ─────────────────────────────────────────────────────────────

func create_object(item: Node, run_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_BACK,
		_ease: Tween.EaseType = Tween.EASE_IN) -> void:
	item.hide()
	await _draw.create_object(item, run_time, trans, _ease)

func create_objects_sequential(items: Array, total_time: float,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		_ease: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	await _draw.create_objects_sequential(items, total_time, trans, _ease)

func create_objects_parallel(items: Array, run_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		_ease: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	await _draw.create_objects_parallel(items, run_time, trans, _ease)

func create_objects_staggered(items: Array, run_time: float = 1.0,
		stagger_delay: float = 0.15,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		_ease: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	await _draw.create_objects_staggered(items, run_time, stagger_delay, trans, _ease)


# ── Property Tween ────────────────────────────────────────────────────────────

func tween_property(
		item, property: String, from: Variant, to: Variant,
		run_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		callback: Callable = Callable()) -> void:
	await _property.tween_property(item, property, from, to, run_time, trans, ease_type, callback)

func tween_property_sequential(
		items: Array, property: String, from: Variant, to: Variant,
		total_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		callback: Callable = Callable()) -> void:
	await _property.tween_sequential(items, property, from, to, total_time, trans, ease_type, callback)

func tween_property_parallel(
		items: Array, property: String, from: Variant, to: Variant,
		run_time: float = 1.0,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		callback: Callable = Callable()) -> void:
	await _property.tween_parallel(items, property, from, to, run_time, trans, ease_type, callback)

func tween_property_staggered(
		items: Array, property: String, from: Variant, to: Variant,
		run_time: float = 1.0, stagger_delay: float = 0.15,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		callback: Callable = Callable()) -> void:
	await _property.tween_staggered(items, property, from, to, run_time, stagger_delay, trans, ease_type, callback)
