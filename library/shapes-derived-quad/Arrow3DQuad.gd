@tool
extends BaseMeshInstance3D
class_name Arrow3DQuad

## Arrow3D rendered as camera-facing quads instead of tubes.
## The arrowhead is a flat camera-facing triangle fan (a 2D cone silhouette).
## All features (doubled, dashed, treadmill, draw_progress) are preserved.
## Billboarding is computed per-segment: lateral = cross(seg_dir, to_cam).

#region Configuration — Points and color

@export_group("Arrow")

@export var start: Vector3 = Vector3.ZERO :
	set(value):
		start = value
		if _ready_done: draw()

@export var end: Vector3 = Vector3(0, 0, 1) :
	set(value):
		end = value
		if _ready_done: draw()

@export var color: Color = Color.WHITE :
	set(value):
		color = value
		if _ready_done: draw()

@export var doubled: bool = false :
	set(value):
		doubled = value
		if _ready_done: draw()

#endregion

#region Configuration — Shaft

@export_group("Shaft")

@export_range(0.001, 1.0, 0.001) var shaft_radius: float = 0.02 :
	set(value):
		shaft_radius = value
		if _ready_done: draw()

#endregion

#region Configuration — Head

@export_group("Head")

@export_range(0.001, 1.0, 0.001) var head_radius: float = 0.08 :
	set(value):
		head_radius = value
		if _ready_done: draw()

@export_range(0.01, 0.99, 0.01) var head_length_ratio: float = 0.2 :
	set(value):
		head_length_ratio = clamp(value, 0.01, 0.99)
		if _ready_done: draw()

#endregion

#region Configuration — Dash

@export_group("Dash")

@export var dashed: bool = false :
	set(value):
		dashed = value
		if _ready_done: draw()

@export_range(0.01, 2.0, 0.001) var dash_length: float = 0.15 :
	set(value):
		dash_length = max(0.01, value)
		if _ready_done: draw()

@export_range(0.001, 2.0, 0.001) var gap_length: float = 0.07 :
	set(value):
		gap_length = max(0.001, value)
		if _ready_done: draw()

#endregion

#region Configuration — Treadmill

@export_group("Treadmill")

@export var treadmill: bool = false :
	set(value):
		treadmill = value
		if _ready_done: draw()

@export_range(0.0, 20.0, 0.01) var treadmill_speed: float = 1.0

@export var treadmill_reverse: bool = false

@export var treadmill_offset: float = 0.0 :
	set(value):
		treadmill_offset = value
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

var _immediate_mesh: ImmediateMesh
var _mat: StandardMaterial3D
var _mesh_instance_back: MeshInstance3D

var _cam_pos_local: Vector3 = Vector3.ZERO
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3.FORWARD) -> Arrow3DQuad:
	return Arrow3DQuad.new(p_start, p_end)

static func get_default_dashed(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3.FORWARD) -> Arrow3DQuad:
	var a := Arrow3DQuad.new(p_start, p_end)
	a.dashed = true
	return a

static func get_double(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3.FORWARD) -> Arrow3DQuad:
	var a := Arrow3DQuad.new(p_start, p_end)
	a.doubled = true
	return a

static func get_double_dashed(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3.FORWARD) -> Arrow3DQuad:
	var a := Arrow3DQuad.new(p_start, p_end)
	a.doubled = true
	a.dashed  = true
	return a

#endregion

#region Lifecycle

func _init(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3(0, 0, 1)) -> void:
	start = p_start
	end   = p_end

func _ready() -> void:
	_immediate_mesh = ImmediateMesh.new()
	mesh            = _immediate_mesh

	_mat = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	material_override = _mat

	_ready_done = true
	draw()

func _exit_tree() -> void:
	_ready_done = false

	if _immediate_mesh is ImmediateMesh:
		_immediate_mesh.clear_surfaces()
		_immediate_mesh = null
		mesh = null

	_mat = null

func _process(delta: float) -> void:
	if treadmill and dashed:
		var pattern := dash_length + gap_length
		var sign    := -1.0 if treadmill_reverse else 1.0
		treadmill_offset = fmod(treadmill_offset + sign * treadmill_speed * delta, pattern)
	draw()

#endregion

#region Public API

func set_points(new_start: Vector3, new_end: Vector3) -> void:
	start = new_start
	end   = new_end
	draw()

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_doubled(value: bool) -> void:
	doubled = value
	draw()

func set_dashed(value: bool) -> void:
	dashed = value
	draw()

func set_shaft_radius(r: float) -> void:
	shaft_radius = r
	draw()

func set_head_radius(r: float) -> void:
	head_radius = r
	draw()

func set_head_length_ratio(ratio: float) -> void:
	head_length_ratio = clamp(ratio, 0.01, 0.99)
	draw()

func set_dash_length(value: float) -> void:
	dash_length = max(0.01, value)
	draw()

func set_gap_length(value: float) -> void:
	gap_length = max(0.001, value)
	draw()

func set_dash_ratio(ratio: float) -> void:
	ratio = clamp(ratio, 0.01, 0.99)
	var pattern: float = dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

#endregion

#region Drawing

func draw() -> void:
	if not is_instance_valid(_immediate_mesh):
		return
	_immediate_mesh.clear_surfaces()

	if draw_progress <= 0.0:
		return

	var dir: Vector3 = end - start
	var total_length: float = dir.length()
	if total_length < 0.001:
		return

	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_position()

	var forward: Vector3 = dir.normalized()
	var head_len: float  = total_length * head_length_ratio

	var segments: Array[Dictionary] = []
	var cumulative: float = 0.0

	if doubled:
		var back_base := start + forward * head_len
		segments.append({
			"type": "head", "from": back_base, "tip": start,
			"draw_dir": -forward, "length": head_len,
			"start_dist": cumulative, "end_dist": cumulative + head_len
		})
		cumulative += head_len

		var shaft_from := back_base
		var shaft_to   := end - forward * head_len
		var shaft_len  := shaft_from.distance_to(shaft_to)
		segments.append({
			"type": "shaft", "from": shaft_from, "to": shaft_to,
			"draw_dir": forward, "length": shaft_len,
			"start_dist": cumulative, "end_dist": cumulative + shaft_len
		})
		cumulative += shaft_len

		segments.append({
			"type": "head", "from": shaft_to, "tip": end,
			"draw_dir": forward, "length": head_len,
			"start_dist": cumulative, "end_dist": cumulative + head_len
		})
	else:
		var shaft_to  := end - forward * head_len
		var shaft_len := start.distance_to(shaft_to)
		segments.append({
			"type": "shaft", "from": start, "to": shaft_to,
			"draw_dir": forward, "length": shaft_len,
			"start_dist": 0.0, "end_dist": shaft_len
		})
		cumulative = shaft_len
		segments.append({
			"type": "head", "from": shaft_to, "tip": end,
			"draw_dir": forward, "length": head_len,
			"start_dist": cumulative, "end_dist": cumulative + head_len
		})

	var draw_length: float = total_length * draw_progress
	var has_vertices: bool = false

	for seg in segments:
		if draw_length <= seg.start_dist:
			break

		var will_draw :bool= draw_length >= seg.end_dist or \
			(seg.type == "head" and \
			 (draw_length - seg.start_dist) / (seg.end_dist - seg.start_dist) >= 0.999)

		if not will_draw and seg.type == "shaft":
			will_draw = true  # partial shafts always attempt draw

		if not will_draw:
			continue

		if not has_vertices:
			_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			_immediate_mesh.surface_set_color(color)
			has_vertices = true

		if draw_length >= seg.end_dist:
			if seg.type == "shaft":
				_draw_shaft(seg.from, seg.to, seg.draw_dir, seg.length, 1.0)
			else:
				_draw_head(seg.from, seg.tip, seg.draw_dir)
		else:
			var t: float = (draw_length - seg.start_dist) / (seg.end_dist - seg.start_dist)
			if seg.type == "shaft":
				_draw_shaft(seg.from, seg.to, seg.draw_dir, seg.length, t)
			else:
				if t >= 0.999:
					_draw_head(seg.from, seg.tip, seg.draw_dir)
			break

	if has_vertices:
		_immediate_mesh.surface_end()

#endregion

#region Shaft

func _draw_shaft(from: Vector3, to: Vector3, forward: Vector3, total_len: float, t: float) -> void:
	var limit :float= total_len * clamp(t, 0.0, 1.0)
	if limit < 0.0001:
		return

	if dashed and treadmill:
		var pattern := dash_length + gap_length
		var phase   := fmod(treadmill_offset, pattern)
		if phase < 0.0:
			phase += pattern
		var dist := -phase
		while dist < limit:
			var draw_start: float = max(dist, 0.0)
			var draw_end:   float = min(dist + dash_length, limit)
			if draw_end > draw_start:
				_draw_quad_segment(from + forward * draw_start, from + forward * draw_end)
			dist += pattern
	elif dashed:
		var dist := 0.0
		while dist < limit:
			var dash_end: float = min(dist + dash_length, limit)
			_draw_quad_segment(from + forward * dist, from + forward * dash_end)
			dist += dash_length + gap_length
	else:
		_draw_quad_segment(from, from + forward * limit)

#endregion

#region Head

## Arrowhead: a flat camera-facing filled triangle.
## The base is a quad (two triangles) scaled to head_radius,
## tapering to a point at tip.
func _draw_head(base: Vector3, tip: Vector3, draw_dir: Vector3) -> void:
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

	# Two triangles forming a filled triangle pointing to tip.
	_tri(b_left, tip, b_right)
	_tri(b_right, tip, b_left)  # back face (CULL_DISABLED so both needed)

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
	lateral = lateral.normalized() * shaft_radius

	_quad(from - lateral, from + lateral, to + lateral, to - lateral)

func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	_immediate_mesh.surface_add_vertex(a)
	_immediate_mesh.surface_add_vertex(b)
	_immediate_mesh.surface_add_vertex(c)

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
