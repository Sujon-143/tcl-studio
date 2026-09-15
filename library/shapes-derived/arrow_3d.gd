@tool
extends BaseMeshInstance3D
class_name Arrow3D

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

@export_range(3, 64, 1) var shaft_segments: int = 10 :
	set(value):
		shaft_segments = max(3, value)
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

## Scrolls the dash pattern along the shaft without moving the points.
## Has no effect when dashed = false.
@export var treadmill: bool = false :
	set(value):
		treadmill = value
		if _ready_done: draw()

## Units per second the pattern scrolls along the shaft.
@export_range(0.0, 20.0, 0.01) var treadmill_speed: float = 1.0

## When true the pattern scrolls from tip toward tail (backwards).
@export var treadmill_reverse: bool = false

## Current scroll offset in world units.
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
var _ready_done: bool = false

#endregion

#region Static factories

static func get_default(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3.FORWARD) -> Arrow3D:
	var a := Arrow3D.new()
	a.start = p_start
	a.end   = p_end
	return a

static func get_default_dashed(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3.FORWARD) -> Arrow3D:
	var a := Arrow3D.new()
	a.start  = p_start
	a.end    = p_end
	a.dashed = true
	return a

static func get_double(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3.FORWARD) -> Arrow3D:
	var a := Arrow3D.new()
	a.start   = p_start
	a.end     = p_end
	a.doubled = true
	return a

static func get_double_dashed(p_start: Vector3 = Vector3.ZERO, p_end: Vector3 = Vector3.FORWARD) -> Arrow3D:
	var a := Arrow3D.new()
	a.start   = p_start
	a.end     = p_end
	a.doubled = true
	a.dashed  = true
	return a

#endregion

#region Lifecycle

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_setup()
		NOTIFICATION_EXIT_TREE:
			_teardown()

func _setup() -> void:
	# Idempotent — safe to call more than once
	if _ready_done:
		return

	_immediate_mesh = ImmediateMesh.new()

	_mat = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED  # both sides, no child node needed

	material_override = _mat
	mesh              = _immediate_mesh

	_ready_done = true
	draw()

func _teardown() -> void:
	_ready_done = false
	if _immediate_mesh is ImmediateMesh:
		_immediate_mesh.clear_surfaces()
	_immediate_mesh   = null
	mesh              = null
	material_override = null
	_mat              = null

# Intercept Godot trying to restore mesh = null from the .tscn on reload.
# ImmediateMesh is runtime-only and is never written to disk, so Godot saves
# mesh = null. Without this override that null would stomp our runtime mesh
# every time the project reloads.
func _set(property: StringName, _value: Variant) -> bool:
	if property == &"mesh":
		return true  # silently swallow — we own the mesh slot entirely
	return false

func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray()  # we manage the mesh ourselves; suppress engine nag

func _process(delta: float) -> void:
	if not treadmill or not dashed:
		return
	var pattern := dash_length + gap_length
	var _sign    := -1.0 if treadmill_reverse else 1.0
	treadmill_offset = fmod(treadmill_offset + _sign * treadmill_speed * delta, pattern)

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

func set_shaft_segments(segs: int) -> void:
	shaft_segments = max(3, segs)
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

	var dir: Vector3          = end - start
	var total_length: float   = dir.length()
	if total_length < 0.001:
		return

	var forward: Vector3 = dir.normalized()
	var head_len: float  = total_length * head_length_ratio

	var up: Vector3    = Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right: Vector3 = forward.cross(up).normalized()
	up                 = right.cross(forward).normalized()

	var segments: Array[Dictionary] = []
	var cumulative: float = 0.0

	if doubled:
		var back_base: Vector3 = start + forward * head_len
		segments.append({
			"type": "head", "from": back_base, "tip": start,
			"draw_dir": -forward, "length": head_len,
			"start_dist": cumulative, "end_dist": cumulative + head_len
		})
		cumulative += head_len

		var shaft_from: Vector3 = back_base
		var shaft_to: Vector3   = end - forward * head_len
		var shaft_len: float    = shaft_from.distance_to(shaft_to)
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
		var shaft_to: Vector3 = end - forward * head_len
		var shaft_len: float  = start.distance_to(shaft_to)
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

		var fully_drawn: bool = draw_length >= seg.end_dist
		var t: float = 1.0 if fully_drawn else \
			(draw_length - seg.start_dist) / (seg.end_dist - seg.start_dist)

		# Skip partial heads — only draw a head once it's fully revealed
		if seg.type == "head" and not fully_drawn and t < 0.999:
			break

		if not has_vertices:
			_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			_immediate_mesh.surface_set_color(color)
			has_vertices = true

		if seg.type == "shaft":
			if fully_drawn:
				_draw_shaft_full(seg.from, seg.to, seg.draw_dir, right, up)
			else:
				_draw_shaft_partial(seg.from, seg.to, t, seg.draw_dir, right, up)
		else:
			_draw_head_full(seg.from, seg.tip, seg.draw_dir, right, up)

		if not fully_drawn:
			break

	if has_vertices:
		_immediate_mesh.surface_end()

#endregion

#region Shaft

func _draw_shaft_full(from: Vector3, to: Vector3, forward: Vector3, right: Vector3, up: Vector3) -> void:
	if dashed:
		if treadmill:
			_draw_treadmill_shaft(from, to, forward, right, up, from.distance_to(to))
		else:
			_draw_dashed_shaft(from, to, forward, right, up)
	else:
		_draw_cylinder(from, to, shaft_radius, forward, right, up)

func _draw_shaft_partial(from: Vector3, to: Vector3, t: float, forward: Vector3, right: Vector3, up: Vector3) -> void:
	var total_len: float  = from.distance_to(to)
	var limit: float      = total_len * t
	if dashed:
		if treadmill:
			_draw_treadmill_shaft(from, to, forward, right, up, limit)
		else:
			var dist: float = 0.0
			while dist < limit:
				var dash_end: float = min(dist + dash_length, limit)
				_draw_cylinder(from + forward * dist, from + forward * dash_end, shaft_radius, forward, right, up)
				dist += dash_length + gap_length
	else:
		_draw_cylinder(from, from + forward * limit, shaft_radius, forward, right, up)

#endregion

#region Head

func _draw_head_full(base: Vector3, tip: Vector3, draw_dir: Vector3, right: Vector3, up: Vector3) -> void:
	var taper_end: Vector3 = base + draw_dir * (base.distance_to(tip) * 0.3)
	_draw_cone_tapered(base, taper_end, tip, shaft_radius, head_radius, draw_dir, right, up)

#endregion

#region Geometry

func _draw_dashed_shaft(shaft_start: Vector3, shaft_end: Vector3, forward: Vector3, right: Vector3, up: Vector3) -> void:
	var total: float = shaft_start.distance_to(shaft_end)
	if total < 0.001:
		return
	var dist: float = 0.0
	while dist < total:
		var d_end: float = min(dist + dash_length, total)
		_draw_cylinder(shaft_start + forward * dist, shaft_start + forward * d_end, shaft_radius, forward, right, up)
		dist += dash_length + gap_length

func _draw_treadmill_shaft(from: Vector3, _to: Vector3, forward: Vector3, right: Vector3, up: Vector3, limit: float) -> void:
	if limit <= 0.0:
		return
	var pattern := dash_length + gap_length
	var phase   := fmod(treadmill_offset, pattern)
	if phase < 0.0:
		phase += pattern
	var dist := -phase
	while dist < limit:
		var draw_start: float = max(dist, 0.0)
		var draw_end: float   = min(dist + dash_length, limit)
		if draw_end > draw_start:
			_draw_cylinder(from + forward * draw_start, from + forward * draw_end, shaft_radius, forward, right, up)
		dist += pattern

func _draw_cylinder(from: Vector3, to: Vector3, radius: float, _forward: Vector3, right: Vector3, up: Vector3) -> void:
	var n: int = shaft_segments
	var bot: Array[Vector3] = []
	var top: Array[Vector3] = []
	for i in range(n):
		var angle: float    = (2.0 * PI * i) / n
		var offset: Vector3 = (cos(angle) * right + sin(angle) * up) * radius
		bot.append(from + offset)
		top.append(to   + offset)
	for i in range(n):
		var next: int = (i + 1) % n
		_quad(bot[i], bot[next], top[next], top[i])
	for i in range(n):
		var next: int = (i + 1) % n
		_triangle(from, bot[next], bot[i])
	for i in range(n):
		var next: int = (i + 1) % n
		_triangle(to, top[i], top[next])

func _draw_cone_tapered(taper_start: Vector3, taper_end: Vector3, tip: Vector3, r_small: float, r_large: float, _forward: Vector3, right: Vector3, up: Vector3) -> void:
	var n: int = shaft_segments
	var ring_a: Array[Vector3] = []
	var ring_b: Array[Vector3] = []
	for i in range(n):
		var angle: float     = (2.0 * PI * i) / n
		var dir_off: Vector3 = cos(angle) * right + sin(angle) * up
		ring_a.append(taper_start + dir_off * r_small)
		ring_b.append(taper_end   + dir_off * r_large)
	for i in range(n):
		var next: int = (i + 1) % n
		_quad(ring_a[i], ring_a[next], ring_b[next], ring_b[i])
	for i in range(n):
		var next: int = (i + 1) % n
		_triangle(tip, ring_b[i], ring_b[next])
	for i in range(n):
		var next: int = (i + 1) % n
		_triangle(taper_end, ring_b[next], ring_b[i])

func _triangle(a: Vector3, b: Vector3, c: Vector3) -> void:
	_immediate_mesh.surface_add_vertex(a)
	_immediate_mesh.surface_add_vertex(b)
	_immediate_mesh.surface_add_vertex(c)

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(a, b, c)
	_triangle(a, c, d)

#endregion
