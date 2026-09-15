extends Node
class_name ProcAnimMove

func _auto_kill(twn: Tween) -> void:
	if is_instance_valid(twn): twn.kill()

# ── helpers ───────────────────────────────────────────────────────────────────

func _popup_node(node: Node, duration: float) -> void:
	node.scale = Vector3.ZERO
	var twn := create_tween()
	twn.tween_property(node, "scale", Vector3.ONE, duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await twn.finished
	_auto_kill(twn)

func _popout_node(node: Node, duration: float) -> void:
	var twn := create_tween()
	twn.tween_property(node, "scale", Vector3.ZERO, duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await twn.finished
	_auto_kill(twn)
	node.queue_free()

# ── 2D move ───────────────────────────────────────────────────────────────────

func move_to_2d(item: Node2D, target_pos: Vector2, duration: float = 0.5,
		show_arrow: bool = false,
		trans := Tween.TRANS_CUBIC, _ease := Tween.EASE_IN_OUT) -> void:

	var arrow: Arrow3D = null
	if show_arrow:
		# Arrow3D works in 3D space; lift 2D coords into XY plane
		var start := Vector3(item.global_position.x, item.global_position.y, 0)
		var end   := Vector3(target_pos.x, target_pos.y, 0)
		arrow = Arrow3D.new()
		arrow.start= start
		arrow.end= end
		arrow.set_dashed(true)
		get_tree().current_scene.add_child(arrow)
		await _popup_node(arrow, 0.25)

	var twn := create_tween()
	twn.tween_property(item, "position", target_pos, duration).set_trans(trans).set_ease(_ease)
	await twn.finished
	_auto_kill(twn)

	if is_instance_valid(arrow):
		await _popout_node(arrow, 0.25)

# ── 3D move ───────────────────────────────────────────────────────────────────

func move_to_3d(item: Node3D, target_pos: Vector3, duration: float = 0.5,
		show_arrow: bool = false,
		trans := Tween.TRANS_CUBIC, _ease := Tween.EASE_IN_OUT) -> void:

	var arrow: Arrow3D = null
	if show_arrow:
		arrow = Arrow3D.new()
		arrow.start= item.global_position
		arrow.end= target_pos
		arrow.set_dashed(true)
		get_tree().current_scene.add_child(arrow)
		await _popup_node(arrow, 0.25)

	var twn := create_tween()
	twn.tween_property(item, "global_position", target_pos, duration).set_trans(trans).set_ease(_ease)
	await twn.finished
	_auto_kill(twn)

	if is_instance_valid(arrow):
		await _popout_node(arrow, 0.25)


func shift3D(item:Node3D,amount:Vector3,duration:float=0.5):
	var twn := create_tween()
	twn.tween_property(item, "global_position",item.global_position+amount, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await twn.finished
	_auto_kill(twn)


# ── 3D rotation ───────────────────────────────────────────────────────────────
func rotation_3d(
	item: Node3D,
	rotation_amount: Vector3,
	duration: float = 0.5,
	show_circle: bool = false,
	trans := Tween.TRANS_CUBIC,
	_ease := Tween.EASE_IN_OUT
) -> void:
	# ------------------ Determine active axis & angle ------------------
	var axis := Vector3.ZERO
	var angle := 0.0

	if rotation_amount.x != 0.0:
		axis = Vector3.RIGHT
		angle = rotation_amount.x
	elif rotation_amount.y != 0.0:
		axis = Vector3.UP
		angle = rotation_amount.y
	elif rotation_amount.z != 0.0:
		axis = Vector3(0.0, 0.0, 1.0)
		angle = rotation_amount.z

	axis = axis.normalized()

	# ------------------ Circle ------------------
	var circle: DashedCircle = null

	if show_circle:
		circle = DashedCircle.new()
		get_tree().current_scene.add_child(circle)

		# Build a basis where the Y column = axis
		# so the circle (assumed built in XZ plane, normal = Y) lies on the rotation plane
		var up := axis

		# Pick a reference vector not parallel to `up` to build the other axes
		var ref := Vector3.FORWARD if abs(up.dot(Vector3.UP)) > 0.99 else Vector3.UP
		var right := up.cross(ref).normalized()
		var forward := right.cross(up).normalized()

		# Basis(x, y, z) → x=right, y=up(=axis), z=forward
		var basis := Basis(right, up, forward)

		circle.global_transform = Transform3D(basis, item.global_position)
		circle.set_color(Color.DARK_RED)
		await _popup_node(circle, 0.25)

	# ------------------ Rotation ------------------
	var start_basis: Basis = item.global_transform.basis
	var target_basis: Basis = Basis(axis, angle) * start_basis

	# ------------------ Tween ------------------
	var twn := create_tween()
	twn.tween_method(
		func(weight: float):
			var gt := item.global_transform
			gt.basis = start_basis.slerp(target_basis, weight)
			item.global_transform = gt,
		0.0,
		1.0,
		duration
	).set_trans(trans).set_ease(_ease)

	await twn.finished
	_auto_kill(twn)

	# ------------------ Cleanup ------------------
	if is_instance_valid(circle):
		await _popout_node(circle, 0.25)



# ── 3D rotate around point ────────────────────────────────────────────────────
func rotate_around_3d(
	item: Node3D,
	center: Vector3,
	axis: Vector3,
	angle: float,
	duration: float = 0.5,
	show_circle: bool = false,
	trans := Tween.TRANS_CUBIC,
	_ease := Tween.EASE_IN_OUT
) -> void:
	# ------------------ Circle ------------------
	var circle: DashedCircle = null

	if show_circle:
		circle = DashedCircle.new()
		get_tree().current_scene.add_child(circle)

		var up := axis.normalized()
		var ref := Vector3.FORWARD if abs(up.dot(Vector3.UP)) > 0.99 else Vector3.UP
		var right := up.cross(ref).normalized()
		var forward := right.cross(up).normalized()
		var basis := Basis(right, up, forward)

		var radius := item.global_position.distance_to(center)
		circle.global_transform = Transform3D(basis * radius, center)
		circle.set_color(Color.DARK_RED)
		circle.set_radius(radius)
		await _popup_node(circle, 0.25)

	# ------------------ Rotation ------------------
	var norm_axis := axis.normalized()
	var start_pos: Vector3 = item.global_position
	var start_basis: Basis = item.global_transform.basis

	var twn := create_tween()
	twn.tween_method(
		func(weight: float):
			var partial_basis := Basis(norm_axis, angle * weight)
			item.global_position = center + partial_basis * (start_pos - center)
			item.global_transform.basis = partial_basis * start_basis,
		0.0,
		1.0,
		duration
	).set_trans(trans).set_ease(_ease)

	await twn.finished
	_auto_kill(twn)

	# ------------------ Cleanup ------------------
	if is_instance_valid(circle):
		await _popout_node(circle, 0.25)
