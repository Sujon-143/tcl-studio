@tool
extends BaseNode3D
class_name Triangle3D

# ──────────────────────────────────────────────────────────────────────────────
# Internal state
# ──────────────────────────────────────────────────────────────────────────────
var _stroke_mesh_inst : MeshInstance3D       = null
var _fill_mesh_inst   : MeshInstance3D       = null
var _corner_spheres   : Array[MeshInstance3D] = []
var _corner_labels    : Array[Label3D]        = []
var _angle_labels     : Array[Label3D]        = []
# Pre-allocated arc mesh instances – exactly 3, never added/removed at runtime.
var _arc_mesh_insts   : Array[MeshInstance3D] = []

var _treadmill_offset : float = 0.0
var _ready_done       : bool  = false
# Dirty flag: setters flip this, _process draws once per frame at most.
# This is what prevents AnimationPlayer from triggering dozens of full redraws
# per frame when it interpolates a keyed property.
var _dirty            : bool  = false

# ──────────────────────────────────────────────────────────────────────────────
# Exports – Vertices
# ──────────────────────────────────────────────────────────────────────────────
@export_group("Vertices")

@export var is_right_angle : bool = false:
	set(v): is_right_angle = v; _mark_dirty()

@export var point_a : Vector3 = Vector3(-0.8, -1.0, 0.0):
	set(v): point_a = v; _mark_dirty()

@export var point_b : Vector3 = Vector3(-0.8,  0.8, 0.0):
	set(v): point_b = v; _mark_dirty()

@export var point_c : Vector3 = Vector3( 1.2,  0.8, 0.0):
	set(v): point_c = v; _mark_dirty()

# ──────────────────────────────────────────────────────────────────────────────
# Exports – Stroke
# ──────────────────────────────────────────────────────────────────────────────
@export_group("Stroke")

@export_range(0.001, 1.0, 0.001) var thickness : float = 0.05:
	set(v): thickness = v; _mark_dirty()

@export var color : Color = Color.WHITE:
	set(v): color = v; _mark_dirty()

@export var solid : bool = false:
	set(v): solid = v; _mark_dirty()

@export_range(0.001, 2.0, 0.001) var dash_length : float = 0.2:
	set(v): dash_length = max(0.001, v); _mark_dirty()

@export_range(0.001, 2.0, 0.001) var gap_length : float = 0.1:
	set(v): gap_length = max(0.001, v); _mark_dirty()

@export var treadmill : bool = false:
	set(v): treadmill = v; _mark_dirty()

@export_range(0.0, 20.0, 0.01) var treadmill_speed   : float = 1.0
@export var treadmill_reverse : bool = false

@export_range(0.0, 1.0, 0.001) var draw_progress : float = 1.0:
	set(v): draw_progress = clamp(v, 0.0, 1.0); _mark_dirty()

# ──────────────────────────────────────────────────────────────────────────────
# Exports – Fill
# ──────────────────────────────────────────────────────────────────────────────
@export_group("Fill")

@export var filled : bool = false:
	set(v): filled = v; _mark_dirty()

@export var fill_color : Color = Color(1.0, 1.0, 1.0, 0.15):
	set(v): fill_color = v; _mark_dirty()

# ──────────────────────────────────────────────────────────────────────────────
# Exports – Corner Points
# ──────────────────────────────────────────────────────────────────────────────
@export_group("Corner Points")

@export var visible_corner_points : bool = false:
	set(v): visible_corner_points = v; _mark_dirty()

@export_range(0.01, 1.0, 0.005) var corner_radius : float = 0.06:
	set(v): corner_radius = v; _mark_dirty()

@export var corner_color : Color = Color.CYAN:
	set(v): corner_color = v; _mark_dirty()

# ──────────────────────────────────────────────────────────────────────────────
# Exports – Angles
# ──────────────────────────────────────────────────────────────────────────────
@export_group("Angles")

@export var show_angles : bool = false:
	set(v): show_angles = v; _mark_dirty()

@export_range(0.1, 2.0, 0.01) var angle_arc_radius : float = 0.24:
	set(v): angle_arc_radius = v; _mark_dirty()

@export var angle_arc_color : Color = Color.YELLOW:
	set(v): angle_arc_color = v; _mark_dirty()

@export var angle_label_color : Color = Color.WHITE:
	set(v): angle_label_color = v; _mark_dirty()

@export_range(6, 60, 1) var angle_font_size : int = 13:
	set(v): angle_font_size = v; _mark_dirty()

@export_range(1.2, 3.0, 0.05) var angle_label_offset : float = 1.7:
	set(v): angle_label_offset = v; _mark_dirty()

# ──────────────────────────────────────────────────────────────────────────────
# Exports – Corner Labels
# ──────────────────────────────────────────────────────────────────────────────
@export_group("Corner Labels")

@export var corner_labels : String = "":
	set(v): corner_labels = v; _mark_dirty()

@export_range(6, 64, 1) var corner_label_font_size : int = 16:
	set(v): corner_label_font_size = v; _mark_dirty()

@export var corner_label_color : Color = Color.WHITE:
	set(v): corner_label_color = v; _mark_dirty()

@export_range(0.05, 1.0, 0.01) var corner_label_offset : float = 0.18:
	set(v): corner_label_offset = v; _mark_dirty()

# ──────────────────────────────────────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_setup_nodes()
	_ready_done = true
	_dirty = true

func _exit_tree() -> void:
	_ready_done = false

func _process(delta: float) -> void:
	if not _ready_done:
		return

	if treadmill and not solid:
		var pattern := dash_length + gap_length
		var sign    := -1.0 if treadmill_reverse else 1.0
		_treadmill_offset = fmod(
			_treadmill_offset + sign * treadmill_speed * delta, pattern)
		_dirty = true

	# Billboard elements always need a refresh (camera may have moved).
	if visible_corner_points or show_angles or corner_labels != "":
		_dirty = true

	if _dirty:
		_dirty = false
		_do_draw()

# ──────────────────────────────────────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────────────────────────────────────
func set_points(a: Vector3, b: Vector3, c: Vector3) -> void:
	point_a = a; point_b = b; point_c = c

func set_dash_ratio(ratio: float) -> void:
	ratio = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)

# ──────────────────────────────────────────────────────────────────────────────
# Dirty flag
# All property setters call only this. AnimationPlayer may set the same
# property many times per frame during interpolation – the flag ensures we
# still only draw once per frame.
# ──────────────────────────────────────────────────────────────────────────────
func _mark_dirty() -> void:
	if _ready_done:
		_dirty = true

# ──────────────────────────────────────────────────────────────────────────────
# Node setup  (runs exactly once in _ready)
# All child nodes are created here and reused for the lifetime of the object.
# Nothing is ever added to or removed from the scene tree after this point.
# ──────────────────────────────────────────────────────────────────────────────
func _setup_nodes() -> void:
	_stroke_mesh_inst = _make_mesh_inst("StrokeMesh", false)
	_fill_mesh_inst   = _make_mesh_inst("FillMesh",   true)

	for i in 3:
		var s  := MeshInstance3D.new()
		s.name = "CornerSphere%d" % i
		s.mesh = SphereMesh.new()
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		s.material_override = sm
		add_child(s)
		_corner_spheres.append(s)

		var cl := _make_label3d("CornerLabel%d" % i)
		add_child(cl)
		_corner_labels.append(cl)

		var al := _make_label3d("AngleLabel%d" % i)
		add_child(al)
		_angle_labels.append(al)

		# Arc mesh instances: pre-allocated here, never touched again structure-wise.
		var arc := _make_mesh_inst("ArcMesh%d" % i, false)
		arc.visible = false
		_arc_mesh_insts.append(arc)

func _make_mesh_inst(node_name: String, transparent: bool) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	var mat  := StandardMaterial3D.new()
	mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode                 = BaseMaterial3D.CULL_DISABLED
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inst.material_override = mat
	add_child(inst)
	return inst

func _make_label3d(node_name: String) -> Label3D:
	var l       := Label3D.new()
	l.name      = node_name
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.visible   = false
	return l

# ──────────────────────────────────────────────────────────────────────────────
# Master draw  (at most once per frame, driven by _dirty flag)
# ──────────────────────────────────────────────────────────────────────────────
func _do_draw() -> void:
	var a   := _vert_a()
	var b   := _vert_b()
	var c   := _vert_c()
	var cam := _camera_local_pos()

	_do_draw_fill(a, b, c)
	_do_draw_stroke(a, b, c, cam)
	_do_draw_corners(a, b, c)
	_do_draw_corner_labels(a, b, c)
	_do_draw_angles(a, b, c, cam)

# ──────────────────────────────────────────────────────────────────────────────
# Vertex helpers
# ──────────────────────────────────────────────────────────────────────────────
func _vert_a() -> Vector3:
	return Vector3(point_b.x, point_a.y, point_b.z) if is_right_angle else point_a

func _vert_b() -> Vector3:
	return point_b

func _vert_c() -> Vector3:
	return Vector3(point_c.x, point_b.y, point_b.z) if is_right_angle else point_c

# ──────────────────────────────────────────────────────────────────────────────
# Fill
# ──────────────────────────────────────────────────────────────────────────────
func _do_draw_fill(a: Vector3, b: Vector3, c: Vector3) -> void:
	if not filled:
		_fill_mesh_inst.mesh = null
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(fill_color)
	mesh.surface_add_vertex(a); mesh.surface_add_vertex(b); mesh.surface_add_vertex(c)
	mesh.surface_add_vertex(a); mesh.surface_add_vertex(c); mesh.surface_add_vertex(b)
	mesh.surface_end()
	_fill_mesh_inst.mesh = mesh

# ──────────────────────────────────────────────────────────────────────────────
# Stroke
# ──────────────────────────────────────────────────────────────────────────────
func _do_draw_stroke(a: Vector3, b: Vector3, c: Vector3, cam: Vector3) -> void:
	var edges   : Array        = [[a, b], [b, c], [c, a]]
	var lengths : Array[float] = []
	var total   : float        = 0.0

	for e in edges:
		var l : float = (e[0] as Vector3).distance_to(e[1] as Vector3)
		lengths.append(l)
		total += l

	var mesh := ImmediateMesh.new()
	_stroke_mesh_inst.mesh = mesh       # assign BEFORE emitting any vertices
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(color)

	var limit    := total * draw_progress
	var consumed : float = 0.0

	for i in 3:
		if consumed >= limit:
			break
		var edge_limit :float= min(lengths[i], limit - consumed)
		_stroke_edge(mesh,
			edges[i][0] as Vector3,
			edges[i][1] as Vector3,
			lengths[i], edge_limit, cam)
		consumed += lengths[i]

	mesh.surface_end()

func _stroke_edge(mesh: ImmediateMesh,
		from: Vector3, to: Vector3,
		edge_len: float, limit: float,
		cam: Vector3) -> void:

	if edge_len < 0.0001 or limit <= 0.0:
		return
	var dir := (to - from).normalized()

	if solid:
		_emit_quad(mesh, from, from + dir * limit, cam, thickness)
		return

	var pattern := dash_length + gap_length
	var dist    := 0.0

	if treadmill:
		var phase := fmod(_treadmill_offset, pattern)
		if phase < 0.0: phase += pattern
		dist = -phase

	while dist < limit:
		var ds :float= max(dist, 0.0)
		var de :float= min(dist + dash_length, limit)
		if de > ds:
			_emit_quad(mesh, from + dir * ds, from + dir * de, cam, thickness)
		dist += pattern

# ──────────────────────────────────────────────────────────────────────────────
# Camera-facing quad  (writes two triangles into an already-open ImmediateMesh)
# ──────────────────────────────────────────────────────────────────────────────
func _emit_quad(mesh: ImmediateMesh,
		from: Vector3, to: Vector3,
		cam: Vector3, half_w: float) -> void:

	var seg := to - from
	if seg.length_squared() < 1e-8:
		return

	var dir    := seg.normalized()
	var to_cam := cam - (from + to) * 0.5
	if to_cam.length_squared() < 1e-8:
		to_cam = Vector3.UP
	to_cam = to_cam.normalized()

	var lat := dir.cross(to_cam)
	if lat.length_squared() < 1e-8:
		var arb := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		lat = dir.cross(arb)
	lat = lat.normalized() * half_w

	mesh.surface_add_vertex(from - lat)
	mesh.surface_add_vertex(from + lat)
	mesh.surface_add_vertex(to   + lat)
	mesh.surface_add_vertex(from - lat)
	mesh.surface_add_vertex(to   + lat)
	mesh.surface_add_vertex(to   - lat)

# ──────────────────────────────────────────────────────────────────────────────
# Corner spheres
# ──────────────────────────────────────────────────────────────────────────────
func _do_draw_corners(a: Vector3, b: Vector3, c: Vector3) -> void:
	var pts := [a, b, c]
	for i in 3:
		var s := _corner_spheres[i]
		s.visible = visible_corner_points
		if not visible_corner_points:
			continue
		s.position = pts[i]
		var sm := s.mesh as SphereMesh
		sm.radius = corner_radius
		sm.height = corner_radius * 2.0
		(s.material_override as StandardMaterial3D).albedo_color = corner_color

# ──────────────────────────────────────────────────────────────────────────────
# Corner labels
# ──────────────────────────────────────────────────────────────────────────────
func _do_draw_corner_labels(a: Vector3, b: Vector3, c: Vector3) -> void:
	var pts    := [a, b, c]
	var center := (a + b + c) / 3.0
	var parts  := corner_labels.split(",", false)
	for i in 3:
		var lbl := _corner_labels[i]
		if i < parts.size() and parts[i].strip_edges() != "":
			lbl.text      = parts[i].strip_edges()
			lbl.font_size = corner_label_font_size
			lbl.modulate  = corner_label_color
			lbl.position  = pts[i] + (pts[i] - center).normalized() * corner_label_offset
			lbl.visible   = true
		else:
			lbl.visible = false

# ──────────────────────────────────────────────────────────────────────────────
# Angle arcs + labels
#
# Key safety rule: we NEVER add or remove nodes here.
# _arc_mesh_insts[0..2] were created in _setup_nodes and live forever.
# Each frame we just rebuild their ImmediateMesh in-place.
# ──────────────────────────────────────────────────────────────────────────────
func _do_draw_angles(a: Vector3, b: Vector3, c: Vector3, cam: Vector3) -> void:
	if not show_angles:
		for i in 3:
			_arc_mesh_insts[i].visible = false
			_angle_labels[i].visible   = false
		return

	_draw_angle_at(a, b, c, 0, cam)
	_draw_angle_at(b, a, c, 1, cam)
	_draw_angle_at(c, b, a, 2, cam)

func _draw_angle_at(v: Vector3, p: Vector3, q: Vector3,
		idx: int, cam: Vector3) -> void:

	var dp  := (p - v).normalized()
	var dq  := (q - v).normalized()
	var deg := rad_to_deg(acos(clamp(dp.dot(dq), -1.0, 1.0)))

	var arc_inst := _arc_mesh_insts[idx]
	arc_inst.visible = true

	var mesh := ImmediateMesh.new()
	arc_inst.mesh = mesh              # assign BEFORE emitting vertices
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(angle_arc_color)

	var arc_w := thickness * 0.6

	if is_right_angle and abs(deg - 90.0) < 0.5:
		# Square corner marker
		var sq  := angle_arc_radius * 0.65
		var pts := [v + dp * sq, v + dp * sq + dq * sq, v + dq * sq]
		for i in 2:
			_emit_quad(mesh, pts[i], pts[i + 1], cam, arc_w)
	else:
		var angle_p := atan2(dp.y, dp.x)
		var angle_q := atan2(dq.y, dq.x)
		var delta   := angle_q - angle_p
		while delta >  PI: delta -= TAU
		while delta < -PI: delta += TAU
		var steps := 16
		var prev  := v + Vector3(cos(angle_p), sin(angle_p), 0.0) * angle_arc_radius
		for i in range(1, steps + 1):
			var t    := float(i) / float(steps)
			var ang  := angle_p + delta * t
			var curr := v + Vector3(cos(ang), sin(ang), 0.0) * angle_arc_radius
			_emit_quad(mesh, prev, curr, cam, arc_w)
			prev = curr

	mesh.surface_end()

	# Label
	var bisector := dp + dq
	if bisector.length_squared() < 0.001:
		bisector = dp.cross(Vector3.FORWARD)
	bisector = bisector.normalized()

	var lbl       := _angle_labels[idx]
	lbl.text      = "%d°" % int(round(deg))
	lbl.position  = v + bisector * angle_arc_radius * angle_label_offset
	lbl.modulate  = angle_label_color
	lbl.font_size = angle_font_size
	lbl.visible   = true

# ──────────────────────────────────────────────────────────────────────────────
# Camera helper
# ──────────────────────────────────────────────────────────────────────────────
func _camera_local_pos() -> Vector3:
	var world_pos := Vector3.ZERO

	if Engine.is_editor_hint():
		var ei := Engine.get_singleton("EditorInterface") as Object
		if ei:
			for i in 4:
				var vp = ei.call("get_editor_viewport_3d", i)
				if vp:
					var cam = vp.get_camera_3d()
					if cam and cam.current:
						world_pos = cam.global_position
						break
			if world_pos == Vector3.ZERO:
				for i in 4:
					var vp = ei.call("get_editor_viewport_3d", i)
					if vp:
						var cam = vp.get_camera_3d()
						if cam:
							world_pos = cam.global_position
							break
	else:
		var vp := get_viewport()
		if vp:
			var cam := vp.get_camera_3d()
			if cam:
				world_pos = cam.global_position

	return global_transform.affine_inverse() * world_pos
