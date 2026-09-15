@tool
extends BaseNode3D
class_name AngleArcQuad

## AngleArc rendered as camera-facing quads instead of tubes.
## Arms extend to the tips of vec_a / vec_b. Arc sits at the given radius.

#region Configuration — Arc shape

@export_group("Arc Shape")

@export var origin: Vector3 = Vector3.ZERO :
	set(value):
		origin = value
		if _ready: draw()

@export var vec_a: Vector3 = Vector3.RIGHT :
	set(value):
		vec_a = value
		if _ready: draw()

@export var vec_b: Vector3 = Vector3.FORWARD :
	set(value):
		vec_b = value
		if _ready: draw()

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready: draw()

@export_range(0.01, 10.0, 0.01) var radius: float = 0.4 :
	set(value):
		radius = value
		if _ready: draw()

@export_range(0.001, 1.0, 0.001) var thickness: float = 0.02 :
	set(value):
		thickness = value
		if _ready: draw()

@export_range(4, 128, 1) var arc_segments: int = 32 :
	set(value):
		arc_segments = value
		if _ready: draw()

#endregion

#region Configuration — Radii lines (arms)

@export_group("Radii")

@export var show_radii: bool = true :
	set(value):
		show_radii = value
		if _ready: draw()

#endregion

#region Configuration — Label

@export_group("Label")

@export var show_label: bool = true :
	set(value):
		show_label = value
		if _ready: _rebuild_label()

@export_range(0.01, 5.0, 0.01) var label_scale: float = 0.4 :
	set(value):
		label_scale = value
		if _ready and _label:
			_label.scale = Vector3.ONE * label_scale

@export var label_color: Color = Color.WHITE :
	set(value):
		label_color = value
		if _ready: draw()

#endregion

#region Configuration — Dash

@export_group("Dash")

@export var dashed: bool = false :
	set(value):
		dashed = value
		if _ready: draw()

@export_range(0.001, 1.0, 0.001) var dash_length: float = 0.08 :
	set(value):
		dash_length = value
		if _ready: draw()

@export_range(0.001, 1.0, 0.001) var gap_length: float = 0.04 :
	set(value):
		gap_length = value
		if _ready: draw()

#endregion

#region Configuration — Draw progress

@export_group("Draw Progress")

@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0 :
	set(value):
		draw_progress = clamp(value, 0.0, 1.0)
		if _ready: draw()

#endregion

#region Private

var _mesh: ImmediateMesh
var _mat: StandardMaterial3D
var _label: Label3D
var _mesh_instance: MeshInstance3D

var _cam_pos_local: Vector3 = Vector3.ZERO
var is_ready: bool = false

#endregion

#region Static factories

static func get_default(orig: Vector3, a: Vector3, b: Vector3) -> AngleArcQuad:
	return AngleArcQuad.new(orig, a, b)

static func get_right_angle(orig: Vector3) -> AngleArcQuad:
	var arc := AngleArcQuad.new(orig, Vector3.RIGHT, Vector3.FORWARD)
	arc.color       = Color(0.2, 0.9, 0.5)
	arc.label_color = Color(0.2, 0.9, 0.5)
	return arc

static func get_dashed(orig: Vector3, a: Vector3, b: Vector3) -> AngleArcQuad:
	var arc := AngleArcQuad.new(orig, a, b)
	arc.dashed = true
	return arc

#endregion

#region Lifecycle

func _init(
	p_origin: Vector3 = Vector3.ZERO,
	p_a: Vector3 = Vector3.RIGHT,
	p_b: Vector3 = Vector3.FORWARD
) -> void:
	origin = p_origin
	vec_a  = p_a
	vec_b  = p_b

func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED

	_mesh = ImmediateMesh.new()
	_mesh_instance                   = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat
	add_child(_mesh_instance)

	if show_label:
		_create_label()

	is_ready = true
	draw()

func _exit_tree() -> void:
	is_ready = false

	if is_instance_valid(_mesh_instance):
		_mesh_instance.mesh = null
		_mesh_instance.queue_free()
		_mesh_instance = null

	if is_instance_valid(_label):
		_label.queue_free()
		_label = null

	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
		_mesh = null

	_mat = null

func _process(_delta: float) -> void:
	if _ready:
		draw()

#endregion

#region Public API

func set_vectors(new_origin: Vector3, new_a: Vector3, new_b: Vector3) -> void:
	origin = new_origin
	vec_a  = new_a
	vec_b  = new_b
	if _ready: draw()

func set_color(new_color: Color) -> void:
	color = new_color
	if _ready: draw()

func set_radius(new_radius: float) -> void:
	radius = new_radius
	if _ready: draw()

func set_thickness(new_thickness: float) -> void:
	thickness = new_thickness
	if _ready: draw()

func set_show_label(value: bool) -> void:
	show_label = value
	if _ready: draw()

func set_dashed(value: bool) -> void:
	dashed = value
	if _ready: draw()

func set_dash_ratio(ratio: float) -> void:
	ratio = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	if _ready: draw()

#endregion

#region Drawing

func draw() -> void:
	if not _ready or not is_instance_valid(_mesh):
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

	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_position()

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(color)

	# Radii (arms) – now use the full vec_a / vec_b lengths
	if show_radii and draw_progress >= 0.999:
		_draw_quad_segment(origin, origin + vec_a)
		_draw_quad_segment(origin, origin + vec_b)

	if dashed:
		_draw_dashed_arc(dir_a, dir_b, total_angle, drawn_angle)
	else:
		_draw_arc_range(dir_a, dir_b, total_angle, 0.0, draw_progress)

	_mesh.surface_end()
	_update_label_visibility()

func _draw_arc_range(dir_a: Vector3, dir_b: Vector3, total_angle: float, t_start: float, t_end: float) -> void:
	if t_end <= t_start:
		return
	var steps: int = max(2, int(arc_segments * (t_end - t_start)))
	for s in range(steps):
		var t0: float = lerp(t_start, t_end, float(s)     / steps)
		var t1: float = lerp(t_start, t_end, float(s + 1) / steps)
		var p0 := origin + dir_a.slerp(dir_b, t0).normalized() * radius
		var p1 := origin + dir_a.slerp(dir_b, t1).normalized() * radius
		_draw_quad_segment(p0, p1)

func _draw_dashed_arc(dir_a: Vector3, dir_b: Vector3, total_angle: float, drawn_angle: float) -> void:
	var total_arc_length := total_angle * radius
	var drawn_length     := drawn_angle * radius
	if drawn_length <= 0.0:
		return

	var pattern := dash_length + gap_length
	var dist := 0.0
	while dist < drawn_length:
		var dash_end: float = min(dist + dash_length, drawn_length)
		_draw_arc_range(dir_a, dir_b, total_angle, dist / total_arc_length, dash_end / total_arc_length)
		dist += pattern

#endregion

#region Geometry helpers

func _draw_quad_segment(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()

	var mid := (from + to) * 0.5
	var to_cam := _cam_pos_local - mid
	if to_cam.length() < 0.0001:
		to_cam = Vector3.UP
	to_cam = to_cam.normalized()

	var lateral := dir.cross(to_cam)
	if lateral.length() < 0.0001:
		var arb := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		lateral = dir.cross(arb)
	lateral = lateral.normalized() * thickness

	_quad(from - lateral, from + lateral, to + lateral, to - lateral)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(b)
	_mesh.surface_add_vertex(c)
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(c)
	_mesh.surface_add_vertex(d)

func _get_camera_world_position() -> Vector3:
	if Engine.is_editor_hint():
		var ei := Engine.get_singleton("EditorInterface") as Object
		if ei:
			for i in range(4):
				var vp = ei.call("get_editor_viewport_3d", i)
				if vp:
					var cam = vp.get_camera_3d()
					if cam and cam.current:
						return cam.global_position
			for i in range(4):
				var vp = ei.call("get_editor_viewport_3d", i)
				if vp:
					var cam = vp.get_camera_3d()
					if cam:
						return cam.global_position
		return Vector3.ZERO

	var vp := get_viewport()
	if vp:
		var cam := vp.get_camera_3d()
		if cam:
			return cam.global_position
	return Vector3.ZERO

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
	if show_label:
		if not is_instance_valid(_label):
			_create_label()
	else:
		if is_instance_valid(_label):
			_label.queue_free()
			_label = null
	if _ready:
		draw()

func _update_label_visibility() -> void:
	if show_label and is_instance_valid(_label):
		if draw_progress >= 0.999:
			_label.visible  = true
			var dir_a       := vec_a.normalized()
			var dir_b       := vec_b.normalized()
			var total_angle := dir_a.angle_to(dir_b)
			var mid_dir     := dir_a.slerp(dir_b, 0.5).normalized()
			# Label placed slightly outside the arc, independent of arm lengths
			_label.position = origin + mid_dir * (radius * 1.4)
			_label.text     = "%.1f°" % rad_to_deg(total_angle)
			_label.modulate = label_color
		else:
			_label.visible = false

#endregion
