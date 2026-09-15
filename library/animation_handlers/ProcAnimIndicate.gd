extends Node
class_name ProcAnimIndicate

func indicate_3d(item: Node3D, scale_factor: float = 1.25,
		color: Color = Color(1.0, 0.9, 0.0, 1.0), duration: float = 0.5) -> void:
	if not is_instance_valid(item): return

	var half := duration * 0.5
	var base_scale := item.scale

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(item, meshes)

	var saved: Dictionary = {}
	for mi in meshes:
		saved[mi] = {}
		for s in mi.get_surface_override_material_count():
			var mat = mi.get_active_material(s)
			if not mat is StandardMaterial3D: continue
			var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			mi.set_surface_override_material(s, dup)
			saved[mi][s] = {
				"mat":              dup,
				"albedo":           dup.albedo_color,
				"emission":         dup.emission,
				"emission_energy":  dup.emission_energy_multiplier,
				"emission_enabled": dup.emission_enabled,
			}

	var twn_in := create_tween().set_parallel(true)
	twn_in.tween_property(item, "scale", base_scale * scale_factor, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for mi in meshes:
		for s in saved[mi]:
			var dup: StandardMaterial3D = saved[mi][s]["mat"]
			dup.emission_enabled = true
			twn_in.tween_property(dup, "albedo_color", color, half) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			twn_in.tween_property(dup, "emission", color, half) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			twn_in.tween_property(dup, "emission_energy_multiplier", 1.5, half) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await twn_in.finished

	var twn_out := create_tween().set_parallel(true)
	twn_out.tween_property(item, "scale", base_scale, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	for mi in meshes:
		for s in saved[mi]:
			var entry: Dictionary = saved[mi][s]
			var dup: StandardMaterial3D = entry["mat"]
			twn_out.tween_property(dup, "albedo_color", entry["albedo"], half) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			twn_out.tween_property(dup, "emission", entry["emission"], half) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			twn_out.tween_property(dup, "emission_energy_multiplier", entry["emission_energy"], half) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await twn_out.finished

	for mi in meshes:
		for s in saved[mi]:
			(saved[mi][s]["mat"] as StandardMaterial3D).emission_enabled = saved[mi][s]["emission_enabled"]

func broadcast_3d(item: Node3D, n_rings: int = 3, max_radius: float = 2.5,
		color: Color = Color.WHITE, duration: float = 0.8,
		_tube_radius: float = 0.04, axis: Vector3 = Vector3.UP) -> void:
	if not is_instance_valid(item): return
	if n_rings <= 0: return

	var stagger := duration * 0.25
	var all_done: Array[Signal] = []

	for i in n_rings:
		var torus := TorusMesh.new()
		torus.inner_radius  = 0.45
		torus.outer_radius  = 0.5
		torus.rings         = 32
		torus.ring_segments = 12

		var mat := StandardMaterial3D.new()
		mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color               = Color(color.r, color.g, color.b, 0.85)
		mat.emission_enabled           = true
		mat.emission                   = color
		mat.emission_energy_multiplier = 1.2
		mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
		mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED

		var mi := MeshInstance3D.new()
		mi.mesh              = torus
		mi.material_override = mat
		mi.global_position   = item.global_position

		if axis.is_equal_approx(Vector3.RIGHT):
			mi.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		elif axis.is_equal_approx(Vector3.FORWARD) or axis.is_equal_approx(Vector3.BACK):
			mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)

		item.get_parent().add_child(mi)

		var delay := stagger * i
		var twn := create_tween().set_parallel(true)
		twn.tween_property(mi, "scale", Vector3.ONE * max_radius, duration) \
			.set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		twn.tween_property(mat, "albedo_color:a", 0.0, duration) \
			.set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		twn.tween_property(mat, "emission_energy_multiplier", 0.0, duration) \
			.set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

		var cleanup := create_tween()
		cleanup.tween_interval(delay + duration)
		cleanup.tween_callback(func():
			if is_instance_valid(mi): mi.queue_free()
		)
		all_done.append(cleanup.finished)

	if not all_done.is_empty():
		await all_done.back()

func _collect_meshes(root: Node, result: Array[MeshInstance3D]) -> void:
	if root is MeshInstance3D:
		result.append(root as MeshInstance3D)
	for child in root.get_children():
		_collect_meshes(child, result)
