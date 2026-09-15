@tool
extends BaseNode3D
class_name RectRegionQuad

## RectRegion with camera-facing quad borders instead of tubes.
## The filled slab face stays as flat quads (it IS flat — no billboarding needed).
## Only the border lines use the quad approach.
## All features (treadmill, dashed border, draw_progress) are preserved.

#region Configuration — Shape

@export_group("Shape")

@export var color: Color = Color(1.0, 1.0, 0.0, 0.4) :
	set(value):
		color = value
		if _ready_done: draw()

@export var pos: Vector3 = Vector3.ZERO :
	set(value):
		pos = value
		if _ready_done: draw()

@export_range(0.001, 100.0, 0.001) var width: float = 1.0 :
	set(value):
		width = max(0.001, value)
		if _ready_done: draw()

@export_range(0.001, 100.0, 0.001) var depth: float = 1.0 :
	set(value):
		depth = max(0.001, value)
		if _ready_done: draw()

@export_range(0.0, 1.0, 0.001) var thickness: float = 0.01 :
	set(value):
		thickness = value
		if _ready_done: draw()

#endregion

#region Configuration — Border

@export_group("Border")

@export var show_border: bool = true :
	set(value):
		show_border = value
		if _ready_done: draw()

@export var border_color: Color = Color.WHITE :
	set(value):
		border_color = value
		if _ready_done: draw()

@export_range(0.001, 1.0, 0.001) var border_thickness: float = 0.03 :
	set(value):
		border_thickness = value
		if _ready_done: draw()

#endregion

#region Configuration — Border Dash

@export_group("Border Dash")

@export var dashed_border: bool = false :
	set(value):
		dashed_border = value
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

#region Configuration — Border Treadmill

@export_group("Border Treadmill")

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

#region Configuration — Draw Progress

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
var _mesh_instance: MeshInstance3D
var _mesh_instance_back: MeshInstance3D

var _cam_pos_local: Vector3 = Vector3.ZERO
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(w: float = 1.0, d: float = 1.0) -> RectRegionQuad:
	return RectRegionQuad.new(w, d)

static func get_square(size: float = 1.0) -> RectRegionQuad:
	return RectRegionQuad.new(size, size)

static func get_highlighted(w: float = 1.0, d: float = 1.0) -> RectRegionQuad:
	var r          := RectRegionQuad.new(w, d)
	r.color         = Color(0.2, 0.6, 1.0, 0.3)
	r.border_color  = Color(0.2, 0.6, 1.0)
	return r

static func get_treadmill_border(w: float = 1.0, d: float = 1.0,
								 speed: float = 1.0) -> RectRegionQuad:
	var r              := RectRegionQuad.new(w, d)
	r.dashed_border     = true
	r.treadmill         = true
	r.treadmill_speed   = speed
	return r

#endregion

#region Lifecycle

func _init(p_width: float = 1.0, p_depth: float = 1.0) -> void:
	width = p_width
	depth = p_depth
	_mesh = ImmediateMesh.new()

func _ready() -> void:
	_mat_front = _make_material(BaseMaterial3D.CULL_BACK)
	_mat_back  = _make_material(BaseMaterial3D.CULL_FRONT)

	_mesh_instance                   = MeshInstance3D.new()
	_mesh_instance.mesh              = _mesh
	_mesh_instance.material_override = _mat_front
	add_child(_mesh_instance)

	_mesh_instance_back                   = MeshInstance3D.new()
	_mesh_instance_back.mesh              = _mesh
	_mesh_instance_back.material_override = _mat_back
	add_child(_mesh_instance_back)

	_ready_done = true
	draw()

func _exit_tree() -> void:
	_ready_done = false

	if is_instance_valid(_mesh_instance):
		_mesh_instance.mesh = null
		_mesh_instance.queue_free()
		_mesh_instance = null

	if is_instance_valid(_mesh_instance_back):
		_mesh_instance_back.mesh = null
		_mesh_instance_back.queue_free()
		_mesh_instance_back = null

	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
		_mesh = null

	_mat_front = null
	_mat_back  = null

func _process(delta: float) -> void:
	if treadmill and dashed_border:
		var pattern      := dash_length + gap_length
		var sign         := -1.0 if treadmill_reverse else 1.0
		treadmill_offset  = fmod(treadmill_offset + sign * treadmill_speed * delta, pattern)
	draw()

#endregion

#region Public API

func set_color(new_color: Color) -> void:
	color = new_color
	draw()

func set_size(new_width: float, new_depth: float) -> void:
	width = max(0.001, new_width)
	depth = max(0.001, new_depth)
	draw()

func set_pos(new_pos: Vector3) -> void:
	pos = new_pos
	draw()

func set_thickness(new_thickness: float) -> void:
	thickness = new_thickness
	draw()

func set_show_border(value: bool) -> void:
	show_border = value
	draw()

func set_dashed_border(value: bool) -> void:
	dashed_border = value
	draw()

func set_border_color(new_color: Color) -> void:
	border_color = new_color
	draw()

func set_border_thickness(t: float) -> void:
	border_thickness = t
	draw()

func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

func set_treadmill(value: bool) -> void:
	treadmill = value
	draw()

func set_treadmill_reverse(value: bool) -> void:
	treadmill_reverse = value

func set_treadmill_speed(value: float) -> void:
	treadmill_speed = value

func draw() -> void:
	if not is_instance_valid(_mesh):
		return

	_mesh.clear_surfaces()

	if draw_progress <= 0.0:
		return

	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_position()

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_filled_rect()
	if show_border:
		_draw_border()
	_mesh.surface_end()

#endregion

#region Drawing

func _draw_filled_rect() -> void:
	var hw  := width * 0.5
	var hd  := depth * 0.5

	var bl  := pos + Vector3(-hw, 0.0,  hd)
	var br  := pos + Vector3( hw, 0.0,  hd)
	var tr  := pos + Vector3( hw, 0.0, -hd)
	var tl  := pos + Vector3(-hw, 0.0, -hd)

	var bl1 := bl + Vector3(0.0, thickness, 0.0)
	var br1 := br + Vector3(0.0, thickness, 0.0)
	var tr1 := tr + Vector3(0.0, thickness, 0.0)
	var tl1 := tl + Vector3(0.0, thickness, 0.0)

	var bot_c := Color(color.r, color.g, color.b, color.a * 0.5)
	var rim_c := Color(color.r, color.g, color.b, color.a * 0.6)

	_mesh.surface_set_color(color)
	_quad(tl1, tr1, br1, bl1)

	_mesh.surface_set_color(bot_c)
	_quad(bl, br, tr, tl)

	_mesh.surface_set_color(rim_c)
	_quad(bl,  br,  br1, bl1)
	_quad(br,  tr,  tr1, br1)
	_quad(tr,  tl,  tl1, tr1)
	_quad(tl,  bl,  bl1, tl1)

func _draw_border() -> void:
	var hw := width * 0.5
	var hd := depth * 0.5
	var y  := pos.y + thickness

	var bl := pos + Vector3(-hw, y,  hd)
	var br := pos + Vector3( hw, y,  hd)
	var tr := pos + Vector3( hw, y, -hd)
	var tl := pos + Vector3(-hw, y, -hd)

	var edges: Array = [
		{"from": bl, "to": br},
		{"from": br, "to": tr},
		{"from": tr, "to": tl},
		{"from": tl, "to": bl},
	]

	if dashed_border:
		_draw_border_dashed(edges)
	else:
		_draw_border_continuous(edges)

func _draw_border_continuous(edges: Array) -> void:
	_mesh.surface_set_color(border_color)

	# Draw each edge quad
	for i in range(edges.size()):
		var cur = edges[i]
		var next = edges[(i + 1) % edges.size()]
		var from: Vector3 = cur["from"]
		var to:   Vector3 = cur["to"]

		var dir := to - from
		if dir.length() < 0.001:
			continue
		dir = dir.normalized()

		var lateral := _compute_lateral(dir)
		var half_thick := border_thickness * 0.5

		# Quad for the edge (centered on the line)
		_quad(from - lateral * half_thick,
			  from + lateral * half_thick,
			  to   + lateral * half_thick,
			  to   - lateral * half_thick)

		# Corner fill: triangle from the corner point to the outer ends of the two edges
		var corner_pt := to  # same as next["from"]
		var dir_in     := dir
		var dir_out    :Vector3= (next["to"] - corner_pt).normalized()
		var lat_in     := _compute_lateral(dir_in)
		var lat_out    := _compute_lateral(dir_out)

		var outer_in   := corner_pt + lat_in  * border_thickness * 0.5
		var outer_out  := corner_pt + lat_out * border_thickness * 0.5

		_tri(corner_pt, outer_in, outer_out)

func _draw_border_dashed(edges: Array) -> void:
	_mesh.surface_set_color(border_color)

	var pattern := dash_length + gap_length
	var phase   := fmod(treadmill_offset, pattern)
	if phase < 0.0:
		phase += pattern

	# Process each edge, keeping track of remaining distance along the perimeter
	var perimeter := 0.0
	for edge in edges:
		perimeter += (edge["to"] - edge["from"]).length()

	if perimeter < 0.001:
		return

	var dist := -phase
	var edge_idx := 0
	var edge_t := 0.0  # progress along current edge (0..1)

	# Helper to advance along the perimeter
	while dist < perimeter:
		var dash_start :float= max(dist, 0.0)
		var dash_end   :float= min(dist + dash_length, perimeter)

		if dash_end > dash_start:
			# Draw this dash piece by piece
			_draw_dash_interval(edges, dash_start, dash_end)

		dist += pattern

func _draw_dash_interval(edges: Array, start_dist: float, end_dist: float) -> void:
	# Find which edge and offset for start_dist
	var start_edge_idx := 0
	var start_t := 0.0
	var accumulated := 0.0
	for i in range(edges.size()):
		var len :float= (edges[i]["to"] - edges[i]["from"]).length()
		if start_dist <= accumulated + len:
			start_edge_idx = i
			start_t = (start_dist - accumulated) / max(len, 0.001)
			break
		accumulated += len

	# Same for end_dist
	var end_edge_idx := 0
	var end_t := 0.0
	accumulated = 0.0
	for i in range(edges.size()):
		var len :float= (edges[i]["to"] - edges[i]["from"]).length()
		if end_dist <= accumulated + len:
			end_edge_idx = i
			end_t = (end_dist - accumulated) / max(len, 0.001)
			break
		accumulated += len

	# If the dash is contained within one edge, simple case
	if start_edge_idx == end_edge_idx:
		var edge = edges[start_edge_idx]
		var p0 :Vector3= edge["from"].lerp(edge["to"], start_t)
		var p1 :Vector3= edge["from"].lerp(edge["to"], end_t)
		_draw_border_quad_segment(p0, p1)
		return

	# Dash spans across one or more corners – draw each segment and corner fills
	var current_idx := start_edge_idx
	var t := start_t

	while true:
		var edge = edges[current_idx]
		var segment_end_t := 1.0 if current_idx != end_edge_idx else end_t
		var p0 :Vector3= edge["from"].lerp(edge["to"], t)
		var p1 :Vector3= edge["from"].lerp(edge["to"], segment_end_t)

		_draw_border_quad_segment(p0, p1)

		if current_idx == end_edge_idx:
			break

		# Draw corner fill at the end of this edge (corner point = edge["to"])
		var corner_pt :Vector3= edge["to"]
		var next_edge = edges[(current_idx + 1) % edges.size()]
		var dir_in  :Vector3= (corner_pt - edge["from"]).normalized()
		var dir_out :Vector3= (next_edge["to"] - corner_pt).normalized()
		var lat_in  := _compute_lateral(dir_in)
		var lat_out := _compute_lateral(dir_out)

		var half_thick := border_thickness * 0.5
		var outer_in   := corner_pt + lat_in  * half_thick
		var outer_out  := corner_pt + lat_out * half_thick

		# Only draw corner if the dash actually includes the corner point
		# (it does, because we're spanning across the corner)
		_tri(corner_pt, outer_in, outer_out)

		current_idx = (current_idx + 1) % edges.size()
		t = 0.0

func _compute_lateral(forward: Vector3) -> Vector3:
	var to_cam := _cam_pos_local - forward  # rough direction
	if to_cam.length() < 0.0001:
		to_cam = Vector3.UP
	to_cam = to_cam.normalized()
	var lateral := forward.cross(to_cam)
	if lateral.length() < 0.0001:
		var arb := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		lateral = forward.cross(arb)
	return lateral.normalized()

func _draw_border_quad_segment(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()

	var lateral := _compute_lateral(dir)
	var half_thick := border_thickness * 0.5

	_quad(from - lateral * half_thick,
		  from + lateral * half_thick,
		  to   + lateral * half_thick,
		  to   - lateral * half_thick)

#endregion

#region Geometry helpers

func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	_mesh.surface_add_vertex(a)
	_mesh.surface_add_vertex(b)
	_mesh.surface_add_vertex(c)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(a, b, c)
	_tri(a, c, d)

func _make_material(cull: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode                  = cull
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

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
