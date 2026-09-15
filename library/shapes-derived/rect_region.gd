@tool
extends BaseNode3D
class_name RectRegion

## A flat rectangular slab with an optional tube border.
## The border supports solid, dashed, and treadmill (animated scrolling dash) modes.
## Compose-based: one MeshInstance3D child (front-face) + one (back-face) share
## a single ImmediateMesh, matching the DashedLine/BracketLine pattern.

#region Configuration — Shape

@export_group("Shape")

@export var color: Color = Color(1.0, 1.0, 0.0, 0.4) :
	set(value):
		color = value
		if _ready_done: draw()

## Center of the rectangle in local space (XZ plane).
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

## Thin slab height along Y. Keep small (e.g. 0.01) for a flat appearance.
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

@export_range(3, 32, 1) var border_tube_segments: int = 8 :
	set(value):
		border_tube_segments = max(3, value)
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

## Scrolls the dash pattern around the border perimeter continuously.
## Has no effect when dashed_border = false.
@export var treadmill: bool = false :
	set(value):
		treadmill = value
		if _ready_done: _update_treadmill_state()

## Units per second the pattern scrolls around the perimeter.
@export_range(0.0, 20.0, 0.01) var treadmill_speed: float = 1.0

## When true the pattern scrolls clockwise; when false, counter-clockwise.
@export var treadmill_reverse: bool = false

## Current scroll offset in world units. Can be driven externally.
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

var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(w: float = 1.0, d: float = 1.0) -> RectRegion:
	return RectRegion.new(w, d)

static func get_square(size: float = 1.0) -> RectRegion:
	return RectRegion.new(size, size)

static func get_highlighted(w: float = 1.0, d: float = 1.0) -> RectRegion:
	var r          := RectRegion.new(w, d)
	r.color         = Color(0.2, 0.6, 1.0, 0.3)
	r.border_color  = Color(0.2, 0.6, 1.0)
	return r

static func get_treadmill_border(w: float = 1.0, d: float = 1.0,
								 speed: float = 1.0) -> RectRegion:
	var r              := RectRegion.new(w, d)
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
	if not treadmill or not dashed_border:
		return
	var pattern  := dash_length + gap_length
	var sign     := -1.0 if treadmill_reverse else 1.0
	treadmill_offset = fmod(treadmill_offset + sign * treadmill_speed * delta, pattern)
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

# ratio: 0 = all gap, 1 = all dash
func set_dash_ratio(ratio: float) -> void:
	ratio       = clamp(ratio, 0.01, 0.99)
	var pattern := dash_length + gap_length
	dash_length = pattern * ratio
	gap_length  = pattern * (1.0 - ratio)
	draw()

func set_treadmill(value: bool) -> void:
	treadmill = value
	_update_treadmill_state()

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

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_filled_rect()
	if show_border:
		_draw_border()
	_mesh.surface_end()

#endregion

#region Treadmill helpers

func _update_treadmill_state() -> void:
	# Nothing to allocate/destroy — _process handles everything.
	# Just redraw so a toggle-off clears the offset visual immediately.
	draw()

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

	# Top face
	_mesh.surface_set_color(color)
	_quad(tl1, tr1, br1, bl1)

	# Bottom face
	_mesh.surface_set_color(bot_c)
	_quad(bl, br, tr, tl)

	# Four side walls
	_mesh.surface_set_color(rim_c)
	_quad(bl,  br,  br1, bl1)   # front  (+Z)
	_quad(br,  tr,  tr1, br1)   # right  (+X)
	_quad(tr,  tl,  tl1, tr1)   # back   (-Z)
	_quad(tl,  bl,  bl1, tl1)   # left   (-X)

func _draw_border() -> void:
	var hw := width * 0.5
	var hd := depth * 0.5
	var y  := pos.y + thickness   # border sits on the top face

	var bl := pos + Vector3(-hw, y,  hd)
	var br := pos + Vector3( hw, y,  hd)
	var tr := pos + Vector3( hw, y, -hd)
	var tl := pos + Vector3(-hw, y, -hd)

	# Perimeter as four directed edges (clockwise when viewed from above).
	var edges: Array = [[bl, br], [br, tr], [tr, tl], [tl, bl]]

	if dashed_border:
		_draw_border_dashed(edges)
	else:
		for edge in edges:
			_draw_border_tube(edge[0], edge[1])

## Draws the dashed border with treadmill_offset applied continuously around
## the full perimeter. The offset is treated as an arc-length phase shift, so
## dashes appear to slide around the rectangle when treadmill is enabled.
func _draw_border_dashed(edges: Array) -> void:
	# Build a flat list of perimeter samples: [[point, cumulative_dist], …]
	var samples: Array = []
	var accumulated := 0.0
	samples.append([edges[0][0], 0.0])
	for edge in edges:
		var from: Vector3 = edge[0]
		var to:   Vector3 = edge[1]
		accumulated += from.distance_to(to)
		samples.append([to, accumulated])
	var perimeter: float = accumulated

	if perimeter < 0.001:
		return

	var pattern := dash_length + gap_length

	# Normalise offset into [0, pattern) — fmod can be negative (reverse mode).
	var phase := fmod(treadmill_offset, pattern)
	if phase < 0.0:
		phase += pattern

	# Draw dashes starting from -phase so entering dashes are visible.
	var dist := -phase
	while dist < perimeter:
		var draw_start: float = max(dist, 0.0)
		var draw_end:   float = min(dist + dash_length, perimeter)
		if draw_end > draw_start:
			_draw_perimeter_segment(samples, draw_start, draw_end)
		dist += pattern

## Samples the perimeter between two arc-length distances and draws a tube.
func _draw_perimeter_segment(samples: Array, from_dist: float, to_dist: float) -> void:
	# Find the world-space points at the two arc-length positions.
	var p0 := _perimeter_sample_at(samples, from_dist)
	var p1 := _perimeter_sample_at(samples, to_dist)
	_draw_border_tube(p0, p1)

func _perimeter_sample_at(samples: Array, dist: float) -> Vector3:
	for i in range(1, samples.size()):
		var d0: float = samples[i - 1][1]
		var d1: float = samples[i][1]
		if dist <= d1:
			var t: float = (dist - d0) / max(d1 - d0, 0.0001)
			return (samples[i - 1][0] as Vector3).lerp(samples[i][0], t)
	return samples[-1][0]

#endregion

#region Geometry helpers

func _draw_border_tube(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	if dir.length() < 0.001:
		return
	_connect_rings([
		_build_ring(from, dir.normalized()),
		_build_ring(to,   dir.normalized()),
	])

func _build_ring(center: Vector3, forward: Vector3) -> Array[Vector3]:
	var up    := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up        = right.cross(forward).normalized()
	var ring: Array[Vector3] = []
	for j in range(border_tube_segments):
		var angle  := TAU * j / border_tube_segments
		var offset := (cos(angle) * right + sin(angle) * up) * border_thickness
		ring.append(center + offset)
	return ring

func _connect_rings(rings: Array) -> void:
	for s in range(rings.size() - 1):
		var r0: Array = rings[s]
		var r1: Array = rings[s + 1]
		for j in range(r0.size()):
			var nj := (j + 1) % r0.size()
			_mesh.surface_set_color(border_color)
			_quad(r0[j], r0[nj], r1[nj], r1[j])

	var first: Array = rings[0]
	var c0 := _ring_center(first)
	for j in range(first.size()):
		_mesh.surface_set_color(border_color)
		_tri(c0, first[(j + 1) % first.size()], first[j])

	var last: Array = rings[-1]
	var c1 := _ring_center(last)
	for j in range(last.size()):
		_mesh.surface_set_color(border_color)
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

func _make_material(cull: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode                  = cull
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

#endregion
