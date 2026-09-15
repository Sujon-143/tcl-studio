@tool
extends BaseNode3D
class_name AngleArc

#region Configuration — Arc shape

@export_group("Arc Shape")

@export var origin: Vector3 = Vector3.ZERO :
	set(value):
		origin = value
		if _ready_done: draw()

@export var vec_a: Vector3 = Vector3.RIGHT :
	set(value):
		vec_a = value
		if _ready_done: draw()

@export var vec_b: Vector3 = Vector3.FORWARD :
	set(value):
		vec_b = value
		if _ready_done: draw()

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: draw()

@export_range(0.01, 10.0, 0.01) var radius: float = 0.4 :
	set(value):
		radius = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var thickness: float = 0.02 :
	set(value):
		thickness = value
		if _ready_done: draw()

@export_range(3, 32, 1) var tube_segments: int = 8 :
	set(value):
		tube_segments = value
		if _ready_done: draw()

@export_range(4, 128, 1) var arc_segments: int = 32 :
	set(value):
		arc_segments = value
		if _ready_done: draw()

#endregion

#region Configuration — Radii lines

@export_group("Radii")

@export var show_radii: bool = true :
	set(value):
		show_radii = value
		if _ready_done: draw()

#endregion

#region Configuration — Label

@export_group("Label")

@export var show_label: bool = true :
	set(value):
		show_label = value
		if _ready_done: _rebuild_label()

@export_range(0.01, 5.0, 0.01) var label_scale: float = 0.4 :
	set(value):
		label_scale = value
		if _ready_done and _label:
			_label.scale = Vector3.ONE * label_scale

@export var label_color: Color = Color.WHITE :
	set(value):
		label_color = value
		if _ready_done: draw()

#endregion

#region Configuration — Dash

@export_group("Dash")

@export var dashed: bool = false :
	set(value):
		dashed = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var dash_length: float = 0.08 :
	set(value):
		dash_length = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var gap_length: float = 0.04 :
	set(value):
		gap_length = value
		if _ready_done: draw()

#endregion

#region Configuration — Draw progress

@export_group("Draw Progress")

@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0 :
	set(value):
		draw_progress = clamp(value, 0.0, 1.0)
		if _ready_done: draw()

#endregion

#region Private

var _mesh: ImmediateMesh
var _mat_front: StandardMaterial3D
var _mat_back: StandardMaterial3D
var _label: Label3D
var _mesh_instance: MeshInstance3D
var _mesh_instance_back: MeshInstance3D

# Guards setters from calling draw() before _ready() has run.
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(orig: Vector3, a: Vector3, b: Vector3) -> AngleArc:
	var ang_arc= AngleArc.new()
	ang_arc.origin= orig
	ang_arc.vec_a= a
	ang_arc.vec_b= b
	return ang_arc

static func get_right_angle(orig: Vector3) -> AngleArc:
	var arc := AngleArc.new()
	arc.origin= orig
	arc.vec_a= Vector3.RIGHT
	arc.vec_b= Vector3.FORWARD
	arc.color       = Color(0.2, 0.9, 0.5)
	arc.label_color = Color(0.2, 0.9, 0.5)
	return arc

static func get_dashed(orig: Vector3, a: Vector3, b: Vector3) -> AngleArc:
	var arc := AngleArc.new()
	arc.vec_a= a
	arc.vec_b= b
	arc.origin= orig
	arc.dashed = true
	return arc

#endregion

#region Lifecycle

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_setup()
		NOTIFICATION_EXIT_TREE:
			_teardown()

func _setup() -> void:
	if _ready_done:
		return

	_mesh = ImmediateMesh.new()

	_mat_front = StandardMaterial3D.new()
	_mat_front.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_front.vertex_color_use_as_albedo = true
	_mat_front.cull_mode                  = BaseMaterial3D.CULL_DISABLED  # drop _mat_back entirely

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat_front
	add_child(_mesh_instance, false, Node.INTERNAL_MODE_BACK)

	if show_label:
		_create_label()

	_ready_done = true
	
	draw()

func _teardown() -> void:
	_ready_done = false
	if is_instance_valid(_label):
		_label.queue_free()
		_label = null
	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
		_mesh = null
	_mat_front = null


func _set(property: StringName, _value: Variant) -> bool:
	if property == &"mesh":
		return true  # block Godot restoring mesh = null on reload
	return false

func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray()

#endregion

#region Public API

func set_vectors(new_origin: Vector3, new_a: Vector3, new_b: Vector3) -> void:
	origin = new_origin
	vec_a  = new_a
	vec_b  = new_b
	draw()

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_radius(new_radius: float) -> void:
	radius = new_radius
	draw()

func set_thickness(new_thickness: float) -> void:
	thickness = new_thickness
	draw()

func set_show_label(value: bool) -> void:
	show_label = value
	draw()

func set_dashed(value: bool) -> void:
	dashed = value
	draw()

# ratio: 0 = all gap, 1 = all dash
func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	if draw_progress <= 0.0:
		_update_label_visibility()
		return

	var dir_a := vec_a.normalized()
	var dir_b := vec_b.normalized()
	var total_angle := dir_a.angle_to(dir_b)

	if total_angle < 0.001:
		_update_label_visibility()
		return

	var drawn_angle := total_angle * draw_progress
	if drawn_angle <= 0.0:
		_update_label_visibility()
		return

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(color)

	if show_radii and draw_progress >= 0.999:
		_draw_tube(origin, origin + dir_a * radius)
		_draw_tube(origin, origin + dir_b * radius)

	if dashed:
		_draw_dashed_arc(dir_a, dir_b, total_angle, drawn_angle)
	else:
		_draw_arc_range(dir_a, dir_b, total_angle, 0.0, draw_progress)

	_mesh.surface_end()

	_update_label_visibility()

func _draw_arc_range(
	dir_a: Vector3, dir_b: Vector3,
	total_angle: float,
	t_start: float, t_end: float,
	caps: bool = true
) -> void:
	if t_end <= t_start:
		return
	var steps: int = max(2, int(arc_segments * (t_end - t_start)))
	var rings: Array = []

	for s in range(steps + 1):
		var t: float      = lerp(t_start, t_end, float(s) / steps)
		var t_next: float = lerp(t_start, t_end, min(float(s + 1) / steps, 1.0))

		var dir      := dir_a.slerp(dir_b, t).normalized()
		var dir_next := dir_a.slerp(dir_b, t_next).normalized()

		var center   := origin + dir * radius
		var next_pt  := origin + dir_next * radius

		var forward := next_pt - center
		if forward.length() < 0.0001:
			forward = dir.cross(Vector3.UP).normalized()
		forward = forward.normalized()

		rings.append(_build_ring(center, forward))

	_connect_rings(rings, caps)

func _draw_dashed_arc(dir_a: Vector3, dir_b: Vector3, total_angle: float, drawn_angle: float) -> void:
	var total_arc_length := total_angle * radius
	var drawn_length     := drawn_angle * radius
	if drawn_length <= 0.0:
		return

	var pattern := dash_length + gap_length
	var dist    := 0.0
	while dist < drawn_length:
		var dash_end: float = min(dist + dash_length, drawn_length)
		var t_start := dist / total_arc_length
		var t_end   := dash_end / total_arc_length
		# caps=false: flat end-cap discs make short dash segments look like
		# bottles/arrows. The open tube reads cleanly as a dashed line.
		_draw_arc_range(dir_a, dir_b, total_angle, t_start, t_end, false)
		dist += pattern

func _draw_tube(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	var forward := dir.normalized()
	_connect_rings([
		_build_ring(from, forward),
		_build_ring(to,   forward),
	], true)

#endregion

#region Geometry helpers

func _build_ring(center: Vector3, forward: Vector3) -> Array[Vector3]:
	var up    := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up        = right.cross(forward).normalized()

	var ring: Array[Vector3] = []
	for j in range(tube_segments):
		var a      := TAU * j / tube_segments
		var offset := (cos(a) * right + sin(a) * up) * thickness
		ring.append(center + offset)
	return ring

func _connect_rings(rings: Array, caps: bool = true) -> void:
	for s in range(rings.size() - 1):
		var r0: Array = rings[s]
		var r1: Array = rings[s + 1]
		for j in range(r0.size()):
			var nj := (j + 1) % r0.size()
			_quad(r0[j], r0[nj], r1[nj], r1[j])

	if not caps:
		return

	var first: Array = rings[0]
	var c0 := _ring_center(first)
	for j in range(first.size()):
		_tri(c0, first[(j + 1) % first.size()], first[j])

	var last: Array = rings[-1]
	var c1 := _ring_center(last)
	for j in range(last.size()):
		_tri(c1, last[j], last[(j + 1) % last.size()])

func _ring_center(ring: Array) -> Vector3:
	var c := Vector3.ZERO
	for v in ring:
		c += v
	return c / ring.size()

func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(b)
	_mesh.surface_add_vertex(c)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(a, b, c)
	_tri(a, c, d)

#endregion

#region Label helpers

func _create_label() -> void:
	_label               = Label3D.new()
	_label.font_size     = 64
	_label.billboard     = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.scale         = Vector3.ONE * label_scale
	add_child(_label)

func _rebuild_label() -> void:
	# Called when show_label is toggled in the editor.
	if show_label:
		if not is_instance_valid(_label):
			_create_label()
	else:
		if is_instance_valid(_label):
			_label.queue_free()
			_label = null
	draw()

func _update_label_visibility() -> void:
	if show_label and is_instance_valid(_label):
		if draw_progress >= 0.999:
			_label.visible  = true
			var dir_a       := vec_a.normalized()
			var dir_b       := vec_b.normalized()
			var total_angle := dir_a.angle_to(dir_b)
			var mid_dir     := dir_a.slerp(dir_b, 0.5).normalized()
			_label.position = origin + mid_dir * (radius * 1.4)
			_label.text     = "%.1f°" % rad_to_deg(total_angle)
			_label.modulate = label_color
		else:
			_label.visible = false

#endregion
