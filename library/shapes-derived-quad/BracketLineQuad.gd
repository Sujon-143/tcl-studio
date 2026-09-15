@tool
extends BaseNode3D
class_name BracketLineQuad

## BracketLine rendered as camera-facing quads instead of tubes.
## All features (draw_progress, dashed, label, offset) are preserved.
## Billboarding is computed per-segment: lateral = cross(seg_dir, to_cam).

#region Configuration — Points and color

@export_group("Bracket")

@export var point_a: Vector3 = Vector3.ZERO :
	set(value):
		point_a = value
		if _ready_done:
			_update_geometry()
			draw()

@export var point_b: Vector3 = Vector3(1, 0, 0) :
	set(value):
		point_b = value
		if _ready_done:
			_update_geometry()
			draw()

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: draw()

#endregion

#region Configuration — Shape

@export_group("Shape")

@export_range(0.01, 2.0, 0.001) var bracket_size: float = 0.15 :
	set(value):
		bracket_size = value
		if _ready_done:
			_update_geometry()
			draw()

@export_range(0.001, 1.0, 0.001) var thickness: float = 0.02 :
	set(value):
		thickness = value
		if _ready_done: draw()

@export var offset: float = 0.0 :
	set(value):
		offset = value
		if _ready_done:
			_update_geometry()
			draw()

#endregion

#region Configuration — Label

@export_group("Label")

@export var show_label: bool = false :
	set(value):
		show_label = value
		if _ready_done: _rebuild_label()

@export var label_text: String = "" :
	set(value):
		label_text = value
		if _ready_done: draw()

@export var auto_label: bool = false :
	set(value):
		auto_label = value
		if _ready_done: draw()

@export_range(0.01, 5.0, 0.01) var label_scale: float = 0.4 :
	set(value):
		label_scale = value
		if _ready_done and _label:
			_label.scale = Vector3.ONE * label_scale

#endregion

#region Configuration — Dash

@export_group("Dash")

@export var dashed: bool = false :
	set(value):
		dashed = value
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var dash_length: float = 0.12 :
	set(value):
		dash_length = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var gap_length: float = 0.06 :
	set(value):
		gap_length = max(0.001, value)
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
var _mat: StandardMaterial3D
var _label: Label3D
var _mesh_instance: MeshInstance3D

var _cam_pos_local: Vector3 = Vector3.ZERO
var _ready_done: bool = false

var _left_cap_from: Vector3
var _left_cap_to: Vector3
var _shaft_from: Vector3
var _shaft_to: Vector3
var _right_cap_from: Vector3
var _right_cap_to: Vector3
var _cap_len: float
var _shaft_len: float
var _total_len: float

#endregion

#region Static factories

static func get_default(a: Vector3, b: Vector3) -> BracketLineQuad:
	return BracketLineQuad.new(a, b)

static func get_with_label(a: Vector3, b: Vector3, text: String) -> BracketLineQuad:
	var br := BracketLineQuad.new(a, b)
	br.show_label = true
	br.label_text = text
	return br

static func get_auto_label(a: Vector3, b: Vector3) -> BracketLineQuad:
	var br := BracketLineQuad.new(a, b)
	br.show_label = true
	br.auto_label = true
	return br

static func get_dashed(a: Vector3, b: Vector3) -> BracketLineQuad:
	var br := BracketLineQuad.new(a, b)
	br.dashed = true
	return br

#endregion

#region Lifecycle

func _init(p_a: Vector3 = Vector3.ZERO, p_b: Vector3 = Vector3(1, 0, 0)) -> void:
	point_a = p_a
	point_b = p_b
	_mesh   = ImmediateMesh.new()

func _ready() -> void:
	_mesh = ImmediateMesh.new()

	_mat = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED

	_mesh_instance                   = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat
	add_child(_mesh_instance)

	if show_label:
		_create_label()

	_ready_done = true
	_update_geometry()
	draw()

func _exit_tree() -> void:
	_ready_done = false

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
	draw()

#endregion

#region Public API

func set_points(a: Vector3, b: Vector3) -> void:
	point_a = a
	point_b = b
	_update_geometry()
	draw()

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_bracket_size(value: float) -> void:
	bracket_size = value
	_update_geometry()
	draw()

func set_thickness(value: float) -> void:
	thickness = value
	draw()

func set_offset(value: float) -> void:
	offset = value
	_update_geometry()
	draw()

func set_dashed(value: bool) -> void:
	dashed = value
	draw()

func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

func set_label(text: String) -> void:
	label_text = text
	show_label = true
	auto_label = false
	if not is_instance_valid(_label):
		_create_label()
	draw()

func set_show_label(value: bool) -> void:
	show_label = value
	_rebuild_label()

#endregion

#region Geometry update

func _update_geometry() -> void:
	var dir: Vector3  = point_b - point_a
	var length: float = dir.length()
	if length < 0.001:
		_total_len = 0.0
		return

	var forward: Vector3 = dir.normalized()
	var up: Vector3      = Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	var perp: Vector3    = forward.cross(up).normalized()

	var pa: Vector3 = point_a + perp * offset
	var pb: Vector3 = point_b + perp * offset

	var half: float    = bracket_size * 0.5
	_left_cap_from     = pa - perp * half
	_left_cap_to       = pa + perp * half
	_right_cap_from    = pb - perp * half
	_right_cap_to      = pb + perp * half
	_shaft_from        = pa
	_shaft_to          = pb

	_cap_len   = bracket_size
	_shaft_len = pa.distance_to(pb)
	_total_len = _cap_len + _shaft_len + _cap_len

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	if draw_progress <= 0.0 or _total_len <= 0.0:
		_update_label_visibility()
		return

	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_position()

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(color)

	var d: float = _total_len * draw_progress
	if dashed:
		_draw_dashed_components(d)
	else:
		_draw_solid_components(d)

	_mesh.surface_end()
	_update_label_visibility()

func _draw_solid_components(d: float) -> void:
	if d <= _cap_len:
		_draw_quad_segment(_left_cap_from, _left_cap_from.lerp(_left_cap_to, d / _cap_len))
	elif d <= _cap_len + _shaft_len:
		_draw_quad_segment(_left_cap_from, _left_cap_to)
		_draw_quad_segment(_shaft_from, _shaft_from.lerp(_shaft_to, (d - _cap_len) / _shaft_len))
	else:
		_draw_quad_segment(_left_cap_from, _left_cap_to)
		_draw_quad_segment(_shaft_from, _shaft_to)
		var t: float = (d - _cap_len - _shaft_len) / _cap_len
		_draw_quad_segment(_right_cap_from, _right_cap_from.lerp(_right_cap_to, t))

func _draw_dashed_components(d: float) -> void:
	if d <= _cap_len:
		_draw_dashed_span(_left_cap_from, _left_cap_to, d / _cap_len)
	elif d <= _cap_len + _shaft_len:
		_draw_dashed_span(_left_cap_from, _left_cap_to, 1.0)
		_draw_dashed_span(_shaft_from, _shaft_to, (d - _cap_len) / _shaft_len)
	else:
		_draw_dashed_span(_left_cap_from, _left_cap_to, 1.0)
		_draw_dashed_span(_shaft_from, _shaft_to, 1.0)
		_draw_dashed_span(_right_cap_from, _right_cap_to, (d - _cap_len - _shaft_len) / _cap_len)

func _draw_dashed_span(from: Vector3, to: Vector3, t: float) -> void:
	if t <= 0.0:
		return
	var total_len: float = from.distance_to(to)
	if total_len < 0.0001:
		return
	var forward  := (to - from).normalized()
	var limit    :float= total_len * clamp(t, 0.0, 1.0)
	var pattern  := dash_length + gap_length
	var dist     := 0.0
	while dist < limit:
		var dash_end: float = min(dist + dash_length, limit)
		_draw_quad_segment(from + forward * dist, from + forward * dash_end)
		dist += pattern

#endregion

#region Geometry helpers

func _draw_quad_segment(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()

	var mid    := (from + to) * 0.5
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
	_label.modulate      = color
	add_child(_label)

func _rebuild_label() -> void:
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
			var mid         := (_shaft_from + _shaft_to) * 0.5
			var dir         := (_shaft_to - _shaft_from).normalized()
			var up          := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
			var perp        := dir.cross(up).normalized()
			_label.position = mid + perp * (bracket_size * 0.7)
			_label.text     = label_text if not auto_label else ("%.2f" % _shaft_len)
			_label.modulate = color
		else:
			_label.visible = false

#endregion
