@tool
extends BaseNode3D
class_name DimensionLineQuad

## DimensionLine rendered as camera-facing quads instead of tubes.
## All features (draw_progress, dashed, label, extension lines) are preserved.
## Arrowheads are flat camera-facing filled triangles.
## Billboarding is computed per-segment: lateral = cross(seg_dir, to_cam).

#region Configuration — Points and color

@export_group("Dimension")

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

@export_range(0.0, 10.0, 0.001) var offset: float = 0.3 :
	set(value):
		offset = value
		if _ready_done:
			_update_geometry()
			draw()

#endregion

#region Configuration — Label

@export_group("Label")

@export var auto_label: bool = true :
	set(value):
		auto_label = value
		if _ready_done: draw()

@export var label_text: String = "" :
	set(value):
		label_text = value
		if _ready_done: draw()

@export var auto_label_format: String = "%.2f" :
	set(value):
		auto_label_format = value
		if _ready_done: draw()

@export_range(0.01, 5.0, 0.01) var label_scale: float = 0.5 :
	set(value):
		label_scale = value
		if _ready_done and is_instance_valid(_label):
			_label.scale = Vector3.ONE * label_scale

#endregion

#region Configuration — Arrow

@export_group("Arrow")

@export_range(0.001, 1.0, 0.001) var shaft_radius: float = 0.015 :
	set(value):
		shaft_radius = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var head_radius: float = 0.055 :
	set(value):
		head_radius = value
		if _ready_done: draw()

@export_range(0.01, 0.99, 0.01) var head_ratio: float = 0.12 :
	set(value):
		head_ratio = clamp(value, 0.01, 0.99)
		if _ready_done: draw()

#endregion

#region Configuration — Extension lines

@export_group("Extension Lines")

@export var show_extension_lines: bool = true :
	set(value):
		show_extension_lines = value
		if _ready_done:
			_update_geometry()
			draw()

@export_range(0.001, 1.0, 0.001) var extension_line_radius: float = 0.008 :
	set(value):
		extension_line_radius = value
		if _ready_done: draw()

#endregion

#region Configuration — Dash

@export_group("Dash")

@export var dashed: bool = false :
	set(value):
		dashed = value
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var dash_length: float = 0.15 :
	set(value):
		dash_length = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var gap_length: float = 0.07 :
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
var _mesh_instance: MeshInstance3D
var _label: Label3D

var _cam_pos_local: Vector3 = Vector3.ZERO
var _ready_done: bool = false

var _a_off: Vector3
var _b_off: Vector3
var _mid: Vector3
var _forward: Vector3
var _offset_dir: Vector3

var _left_tip: Vector3
var _left_base: Vector3
var _right_tip: Vector3
var _right_base: Vector3

var _ext_left_from: Vector3
var _ext_left_to: Vector3
var _ext_right_from: Vector3
var _ext_right_to: Vector3

var _left_arrow_len: float
var _right_arrow_len: float
var _ext_len: float
var _total_len: float

#endregion

#region Static factories

static func get_default(a: Vector3, b: Vector3) -> DimensionLineQuad:
	return DimensionLineQuad.new(a, b)

static func get_with_label(a: Vector3, b: Vector3, label: String) -> DimensionLineQuad:
	var d      := DimensionLineQuad.new(a, b)
	d.auto_label = false
	d.label_text = label
	return d

static func get_auto_label(a: Vector3, b: Vector3, fmt: String = "%.2f") -> DimensionLineQuad:
	var d              := DimensionLineQuad.new(a, b)
	d.auto_label        = true
	d.auto_label_format = fmt
	return d

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

func set_offset(value: float) -> void:
	offset = value
	_update_geometry()
	draw()

func set_label(text: String) -> void:
	auto_label = false
	label_text = text
	draw()

func set_auto_label(value: bool) -> void:
	auto_label = value
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

#endregion

#region Geometry update

func _update_geometry() -> void:
	var dir: Vector3  = point_b - point_a
	var length: float = dir.length()
	if length < 0.001:
		_total_len = 0.0
		return

	_forward    = dir.normalized()
	var up      := Vector3.UP if abs(_forward.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	_offset_dir = _forward.cross(up).cross(_forward).normalized()

	_a_off = point_a + _offset_dir * offset
	_b_off = point_b + _offset_dir * offset
	_mid   = (_a_off + _b_off) * 0.5

	var label_gap: float = length * 0.18

	_left_tip   = _a_off
	_left_base  = _mid - _forward * label_gap
	_right_tip  = _b_off
	_right_base = _mid + _forward * label_gap

	_left_arrow_len  = _left_tip.distance_to(_left_base)
	_right_arrow_len = _right_tip.distance_to(_right_base)

	_ext_left_from  = point_a
	_ext_left_to    = _a_off
	_ext_right_from = point_b
	_ext_right_to   = _b_off
	_ext_len = point_a.distance_to(_a_off)

	_total_len = _left_arrow_len + _right_arrow_len
	if show_extension_lines:
		_total_len += _ext_len * 2.0

#endregion

#region Draw dispatch

func _draw_solid_components(d: float) -> void:
	if d <= _left_arrow_len:
		_draw_arrow_partial(_left_base, _left_tip, d / _left_arrow_len)
		return
	_draw_arrow(_left_base, _left_tip)

	var d2: float = d - _left_arrow_len
	if d2 <= _right_arrow_len:
		_draw_arrow_partial(_right_base, _right_tip, d2 / _right_arrow_len)
		return
	_draw_arrow(_right_base, _right_tip)

	if not show_extension_lines:
		return

	var d3: float  = d - _left_arrow_len - _right_arrow_len
	var ext_color := Color(color.r, color.g, color.b, color.a * 0.5)
	_mesh.surface_set_color(ext_color)

	if d3 <= _ext_len:
		_draw_quad_segment_r(_ext_left_from, _ext_left_from.lerp(_ext_left_to, d3 / _ext_len), extension_line_radius)
	elif d3 <= _ext_len * 2.0:
		_draw_quad_segment_r(_ext_left_from,  _ext_left_to,  extension_line_radius)
		_draw_quad_segment_r(_ext_right_from, _ext_right_from.lerp(_ext_right_to, (d3 - _ext_len) / _ext_len), extension_line_radius)
	else:
		_draw_quad_segment_r(_ext_left_from,  _ext_left_to,  extension_line_radius)
		_draw_quad_segment_r(_ext_right_from, _ext_right_to, extension_line_radius)

	_mesh.surface_set_color(color)

func _draw_dashed_components(d: float) -> void:
	if d <= _left_arrow_len:
		_draw_arrow_dashed_partial(_left_base, _left_tip, d / _left_arrow_len)
		return
	_draw_arrow_dashed(_left_base, _left_tip)

	var d2: float = d - _left_arrow_len
	if d2 <= _right_arrow_len:
		_draw_arrow_dashed_partial(_right_base, _right_tip, d2 / _right_arrow_len)
		return
	_draw_arrow_dashed(_right_base, _right_tip)

	if not show_extension_lines:
		return

	var d3: float  = d - _left_arrow_len - _right_arrow_len
	var ext_color := Color(color.r, color.g, color.b, color.a * 0.5)
	_mesh.surface_set_color(ext_color)

	if d3 <= _ext_len:
		_draw_dashed_span_r(_ext_left_from, _ext_left_to, d3 / _ext_len, extension_line_radius)
	elif d3 <= _ext_len * 2.0:
		_draw_dashed_span_r(_ext_left_from,  _ext_left_to,  1.0, extension_line_radius)
		_draw_dashed_span_r(_ext_right_from, _ext_right_to, (d3 - _ext_len) / _ext_len, extension_line_radius)
	else:
		_draw_dashed_span_r(_ext_left_from,  _ext_left_to,  1.0, extension_line_radius)
		_draw_dashed_span_r(_ext_right_from, _ext_right_to, 1.0, extension_line_radius)

	_mesh.surface_set_color(color)

#endregion

#region Arrow helpers

func _draw_arrow(base: Vector3, tip: Vector3) -> void:
	var shaft_end := tip.lerp(base, head_ratio)
	_draw_quad_segment_r(base, shaft_end, shaft_radius)
	_draw_head(shaft_end, tip)

func _draw_arrow_partial(base: Vector3, tip: Vector3, t: float) -> void:
	if t <= 0.0:
		return
	var total      := base.distance_to(tip)
	var head_len   := total * head_ratio
	var shaft_len  := total - head_len
	var shaft_end  := tip.lerp(base, head_ratio)
	var d          := total * t

	if d <= shaft_len:
		_draw_quad_segment_r(base, base.lerp(shaft_end, d / shaft_len), shaft_radius)
	else:
		_draw_quad_segment_r(base, shaft_end, shaft_radius)
		var cone_t := (d - shaft_len) / head_len
		_draw_head_partial(shaft_end, tip, cone_t)

func _draw_arrow_dashed(base: Vector3, tip: Vector3) -> void:
	var shaft_end := tip.lerp(base, head_ratio)
	_draw_dashed_span_r(base, shaft_end, 1.0, shaft_radius)
	_draw_head(shaft_end, tip)

func _draw_arrow_dashed_partial(base: Vector3, tip: Vector3, t: float) -> void:
	if t <= 0.0:
		return
	var total     := base.distance_to(tip)
	var head_len  := total * head_ratio
	var shaft_len := total - head_len
	var shaft_end := tip.lerp(base, head_ratio)
	var d         := total * t

	if d <= shaft_len:
		_draw_dashed_span_r(base, shaft_end, d / shaft_len, shaft_radius)
	else:
		_draw_dashed_span_r(base, shaft_end, 1.0, shaft_radius)
		_draw_head_partial(shaft_end, tip, (d - shaft_len) / head_len)

## Flat camera-facing filled triangle arrowhead.
func _draw_head(base: Vector3, tip: Vector3) -> void:
	var dir := tip - base
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()

	var mid    := (base + tip) * 0.5
	var to_cam := _cam_pos_local - mid
	if to_cam.length() < 0.0001:
		to_cam = Vector3.UP
	to_cam = to_cam.normalized()

	var lateral := dir.cross(to_cam)
	if lateral.length() < 0.0001:
		var arb := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		lateral = dir.cross(arb)
	lateral = lateral.normalized() * head_radius

	var b_left  := base - lateral
	var b_right := base + lateral
	_tri(b_left, tip, b_right)
	_tri(b_right, tip, b_left)

func _draw_head_partial(base: Vector3, tip: Vector3, t: float) -> void:
	if t <= 0.0:
		return
	_draw_head(base, base.lerp(tip, t))

func _draw_dashed_span_r(from: Vector3, to: Vector3, t: float, r: float) -> void:
	if t <= 0.0:
		return
	var total_len := from.distance_to(to)
	if total_len < 0.0001:
		return
	var fwd   := (to - from).normalized()
	var limit :float= total_len * clamp(t, 0.0, 1.0)
	var dist  := 0.0
	while dist < limit:
		var dash_end: float = min(dist + dash_length, limit)
		_draw_quad_segment_r(from + fwd * dist, from + fwd * dash_end, r)
		dist += dash_length + gap_length

#endregion

#region Geometry helpers

## Draw a quad segment with an explicit radius (used for extension lines vs shaft).
func _draw_quad_segment_r(from: Vector3, to: Vector3, r: float) -> void:
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
	lateral = lateral.normalized() * r

	_quad(from - lateral, from + lateral, to + lateral, to - lateral)

func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(b)
	_mesh.surface_add_vertex(c)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(a, b, c)
	_tri(a, c, d)

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

func _update_label_visibility() -> void:
	if not is_instance_valid(_label):
		return
	if draw_progress >= 0.999:
		_label.visible  = true
		_label.position = _mid
		_label.modulate = color
		_label.text     = auto_label_format % point_a.distance_to(point_b) if auto_label else label_text
	else:
		_label.visible = false

#endregion
