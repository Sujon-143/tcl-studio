@tool
extends Node3D
class_name ParametricCurve3D
## Plots a y = f(x) curve on a Grid3D node.
##
## Attach this as a child of (or sibling to) a Grid3D, assign the grid
## reference, then either:
##   • set [member expression_string] in the Inspector for editor preview, or
##   • call [method set_function] at runtime with any GDScript Callable.
##
## All visual settings (color, thickness, dash pattern, draw_progress) live
## here; the Grid3D is used only for coordinate mapping.

# ──────────────────────────────────────────────────────────────────
# Configuration — Target grid
# ──────────────────────────────────────────────────────────────────
@export_group("Grid")

## The Grid3D this curve is plotted on.
## If left empty the node walks up the scene tree to find the first Grid3D.
@export var grid: Grid3D :
	set(v):
		grid = v
		if _ready_done: _rebuild()

# ──────────────────────────────────────────────────────────────────
# Configuration — Curve
# ──────────────────────────────────────────────────────────────────
@export_group("Curve")

## Number of sampled points. Higher = smoother, costs more geometry.
@export_range(2, 4000, 1) var resolution: int = 200 :
	set(v):
		resolution = max(2, v)
		if _ready_done: _rebuild()

## X range to sample.  Leave [member use_grid_x_range] on to mirror the grid.
@export var x_range: Vector2 = Vector2(-5.0, 5.0) :
	set(v):
		x_range = v
		if _ready_done: _rebuild()

## When true, x_range is taken from the grid's x_range automatically.
@export var use_grid_x_range: bool = true :
	set(v):
		use_grid_x_range = v
		if _ready_done: _rebuild()

## Vertical lift above the grid plane (world-space offset on Y).
@export_range(-10.0, 10.0, 0.001) var lift: float = 0.002 :
	set(v):
		lift = v
		if _ready_done: _rebuild()

# ──────────────────────────────────────────────────────────────────
# Configuration — Editor expression
# ──────────────────────────────────────────────────────────────────
@export_group("Editor Expression")

## A GDScript math expression in terms of x, evaluated in the editor AND
## at runtime when no Callable has been set via set_function().
## Supports all built-in math functions: sin, cos, tan, sqrt, abs, pow,
## log, exp, PI, TAU, etc.
## Examples:  sin(x)   |   x * x - 2   |   cos(x * 2) / (abs(x) + 0.5)
@export var expression_string: String = "sin(x)" :
	set(v):
		expression_string = v
		_compile_expression()
		if _ready_done: _rebuild()

## When true a small error label is shown in the editor if the expression
## fails to compile, so you get immediate feedback.
@export var show_expression_errors: bool = true

# ──────────────────────────────────────────────────────────────────
# Configuration — Appearance
# ──────────────────────────────────────────────────────────────────
@export_group("Appearance")

@export var color: Color = Color(1.0, 0.5, 0.0, 1.0) :
	set(v):
		color = v
		if _ready_done: _redraw_mesh()

@export_range(0.001, 1.0, 0.001) var thickness: float = 0.03 :
	set(v):
		thickness = v
		if _ready_done: _redraw_mesh()

## Solid line vs dashed line.
@export var solid: bool = true :
	set(v):
		solid = v
		if _ready_done: _redraw_mesh()

@export_range(0.01, 5.0, 0.001) var dash_length: float = 0.18 :
	set(v):
		dash_length = v
		if _ready_done: _redraw_mesh()

@export_range(0.01, 5.0, 0.001) var gap_length: float = 0.09 :
	set(v):
		gap_length = v
		if _ready_done: _redraw_mesh()

# ──────────────────────────────────────────────────────────────────
# Configuration — Animation
# ──────────────────────────────────────────────────────────────────
@export_group("Animation")

## Fraction of the curve that is drawn, from the start.  Animate to reveal.
@export_range(0.0, 1.0, 0.001) var draw_progress: float = 1.0 :
	set(v):
		draw_progress = clamp(v, 0.0, 1.0)
		if _ready_done: _redraw_mesh()

## Animate the dash offset so the pattern appears to scroll along the curve.
@export var treadmill: bool = false

@export_range(0.001, 20.0, 0.001) var treadmill_speed: float = 1.0

## Reverses the treadmill scroll direction.
@export var treadmill_reverse: bool = false

# ──────────────────────────────────────────────────────────────────
# Private
# ──────────────────────────────────────────────────────────────────
var _mesh: ImmediateMesh
var _mat: StandardMaterial3D
var _mesh_instance: MeshInstance3D

## Compiled expression (editor + runtime fallback).
var _expression: Expression = null
var _expression_valid: bool  = false

## Runtime override — if set this takes priority over the expression string.
var _runtime_func: Callable

## Cached world-space sample points (rebuilt when curve params change).
var _points: Array[Vector3] = []

## Scrolling dash offset for treadmill mode.
var _treadmill_offset: float = 0.0

## Cached camera position in local space (updated per frame for billboarding).
var _cam_pos_local: Vector3 = Vector3.ZERO

var _ready_done: bool = false

# Error label shown inside the editor only
var _error_label: Label3D = null

# ──────────────────────────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────────────────────────
func _init() -> void:
	_mesh = ImmediateMesh.new()

func _ready() -> void:
	_ensure_mesh_instance()
	_compile_expression()
	_auto_find_grid()
	_rebuild()
	_ready_done = true

func _process(delta: float) -> void:
	if not _ready_done or not is_instance_valid(_mesh_instance):
		return

	# Update camera for billboard quads every frame
	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_pos()

	if treadmill:
		var dir: float = -1.0 if treadmill_reverse else 1.0
		_treadmill_offset += delta * treadmill_speed * dir
		_redraw_mesh()
	elif Engine.is_editor_hint():
		# Redraw in editor each frame so billboard quads track the editor camera
		_redraw_mesh()

# ──────────────────────────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────────────────────────

## Set a runtime Callable f(x: float) -> float.
## This overrides the expression_string until clear_function() is called.
func set_function(f: Callable) -> void:
	_runtime_func = f
	_rebuild()

## Remove the runtime Callable and fall back to expression_string.
func clear_function() -> void:
	_runtime_func = Callable()
	_rebuild()

## Point to a different grid and reparent if needed.
func set_grid(new_grid: Grid3D) -> void:
	grid = new_grid
	_rebuild()

## Force a full resample + redraw.
func refresh() -> void:
	_rebuild()

# ──────────────────────────────────────────────────────────────────
# Internal — build pipeline
# ──────────────────────────────────────────────────────────────────

func _auto_find_grid() -> void:
	if is_instance_valid(grid):
		return
	# Walk up the tree
	var p: Node = get_parent()
	while p:
		if p is Grid3D:
			grid = p as Grid3D
			return
		p = p.get_parent()

func _rebuild() -> void:
	_sample_points()
	_redraw_mesh()
	_update_error_label("")

func _sample_points() -> void:
	_points.clear()
	if not is_instance_valid(grid):
		return

	var range_x: Vector2 = grid.x_range if use_grid_x_range else x_range
	var step: float = (range_x.y - range_x.x) / float(resolution)
	var s: float = grid.scale_to_world

	for i in range(resolution + 1):
		var gx: float = range_x.x + i * step
		var gy: float = _evaluate(gx)
		if is_nan(gy) or is_inf(gy):
			_points.append(Vector3(INF, INF, INF))
			continue
		# Build the point in Grid3D local space (same space ImmediateMesh uses
		# when this node is a child of grid, or we convert below if not).
		# Grid3D maps: x → local X, y-function → local Z, XZ plane is the grid.
		var local_on_grid := Vector3(gx * s, lift, gy * s)
		# If this node is NOT the grid itself, convert grid-local → our local.
		var world_pt: Vector3 = grid.to_global(local_on_grid)
		var our_local: Vector3 = to_local(world_pt)
		_points.append(our_local)

func _evaluate(x: float) -> float:
	# Runtime Callable takes priority
	if _runtime_func.is_valid():
		var result = _runtime_func.call(x)
		if result is float or result is int:
			return float(result)
		return 0.0

	# Fall back to the compiled expression
	if _expression_valid and _expression:
		var result = _expression.execute([x])
		if _expression.has_execute_failed():
			return 0.0
		if result is float or result is int:
			return float(result)
	return 0.0

func _compile_expression() -> void:
	_expression_valid = false
	if expression_string.strip_edges().is_empty():
		return
	_expression = Expression.new()
	var err: int = _expression.parse(expression_string, ["x"])
	if err != OK:
		_expression_valid = false
		if show_expression_errors:
			_update_error_label("Expr error: " + _expression.get_error_text())
		return
	# Do a quick test to catch runtime-compile errors
	var test = _expression.execute([0.0])
	if _expression.has_execute_failed():
		_expression_valid = false
		if show_expression_errors:
			_update_error_label("Expr runtime error: " + _expression.get_error_text())
		return
	_expression_valid = true

# ──────────────────────────────────────────────────────────────────
# Internal — mesh drawing
# ──────────────────────────────────────────────────────────────────

func _ensure_mesh_instance() -> void:
	if is_instance_valid(_mesh_instance):
		return
	if not _mat:
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.vertex_color_use_as_albedo = true
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.material_override = _mat
	add_child(_mesh_instance)

func _redraw_mesh() -> void:
	if not is_instance_valid(_mesh) or not is_instance_valid(_mesh_instance):
		return
	_mesh.clear_surfaces()
	if _points.size() < 2 or draw_progress <= 0.0:
		return

	_cam_pos_local = global_transform.affine_inverse() * _get_camera_world_pos()

	# How many points to actually draw
	var total: int = _points.size()
	var visible_end: int = max(2, int(ceil(draw_progress * float(total))))
	visible_end = min(visible_end, total)

	if solid:
		_draw_solid(visible_end)
	else:
		_draw_dashed(visible_end)

func _draw_solid(end_idx: int) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var r: float = thickness * 0.5
	var segment_start: int = 0

	for i in range(end_idx):
		var pt: Vector3 = _points[i]
		# Sentinel = discontinuity
		if pt.x == INF:
			segment_start = i + 1
			continue
		if i < segment_start + 1:
			continue
		var prev: Vector3 = _points[i - 1]
		if prev.x == INF:
			segment_start = i
			continue
		_emit_quad(prev, pt, r, color)

	_mesh.surface_end()

func _draw_dashed(end_idx: int) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var r: float = thickness * 0.5
	var cycle: float = dash_length + gap_length
	var t: float = fmod(_treadmill_offset, cycle)
	if t < 0.0:
		t += cycle
	# Phase within the current cycle: 0..dash_length = dash, rest = gap
	var phase: float = t

	var segment_start: int = 0
	for i in range(1, end_idx):
		var a: Vector3 = _points[i - 1]
		var b: Vector3 = _points[i]
		if a.x == INF or b.x == INF:
			segment_start = i + 1
			continue
		if i < segment_start + 1:
			continue

		var seg_len: float = a.distance_to(b)
		if seg_len < 0.0001:
			continue
		var walked: float = 0.0

		while walked < seg_len:
			var remaining_in_phase: float = (dash_length if phase < dash_length else gap_length) - fmod(phase, dash_length if phase < dash_length else gap_length)
			# Clamp remaining_in_phase to avoid negative/zero
			remaining_in_phase = max(0.0001, remaining_in_phase)

			var step_len: float = min(remaining_in_phase, seg_len - walked)
			var t0: float = walked / seg_len
			var t1: float = (walked + step_len) / seg_len
			var pa: Vector3 = a.lerp(b, t0)
			var pb: Vector3 = a.lerp(b, t1)

			if phase < dash_length:
				_emit_quad(pa, pb, r, color)

			walked += step_len
			phase += step_len
			if phase >= cycle:
				phase -= cycle

	_mesh.surface_end()

func _emit_quad(from: Vector3, to: Vector3, r: float, col: Color) -> void:
	# from/to are already in this node's local space.
	# _cam_pos_local is also in local space (set in _redraw_mesh).
	var dir: Vector3 = to - from
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()

	var mid: Vector3 = (from + to) * 0.5
	var to_cam: Vector3 = _cam_pos_local - mid
	if to_cam.length() < 0.0001:
		to_cam = Vector3.UP
	to_cam = to_cam.normalized()

	var lateral: Vector3 = dir.cross(to_cam)
	if lateral.length() < 0.0001:
		var arb: Vector3 = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		lateral = dir.cross(arb)
	lateral = lateral.normalized() * r

	_mesh.surface_set_color(col)
	_mesh.surface_add_vertex(from - lateral)
	_mesh.surface_add_vertex(from + lateral)
	_mesh.surface_add_vertex(to   + lateral)
	_mesh.surface_add_vertex(from - lateral)
	_mesh.surface_add_vertex(to   + lateral)
	_mesh.surface_add_vertex(to   - lateral)

# ──────────────────────────────────────────────────────────────────
# Error label (editor feedback only)
# ──────────────────────────────────────────────────────────────────

func _update_error_label(msg: String) -> void:
	if not Engine.is_editor_hint() or not show_expression_errors:
		if is_instance_valid(_error_label):
			_error_label.queue_free()
			_error_label = null
		return

	if msg.is_empty():
		if is_instance_valid(_error_label):
			_error_label.queue_free()
			_error_label = null
		return

	if not is_instance_valid(_error_label):
		_error_label = Label3D.new()
		_error_label.modulate = Color.RED
		_error_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_error_label.no_depth_test = true
		_error_label.pixel_size = 0.005
		_error_label.font_size = 24
		add_child(_error_label)

	_error_label.text = msg
	# Position above the grid origin
	if is_instance_valid(grid):
		_error_label.global_position = grid.global_position + Vector3(0, 1.0, 0)
	else:
		_error_label.position = Vector3(0, 1.0, 0)

# ──────────────────────────────────────────────────────────────────
# Utilities
# ──────────────────────────────────────────────────────────────────

func _get_camera_world_pos() -> Vector3:
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

# ──────────────────────────────────────────────────────────────────
# Static convenience factories
# ──────────────────────────────────────────────────────────────────

## Create a solid orange curve and add it to grid.
static func make_solid(p_grid: Grid3D, expr: String = "sin(x)", col: Color = Color(1.0, 0.5, 0.0)) -> ParametricCurve3D:
	var c := ParametricCurve3D.new()
	c.grid              = p_grid
	c.color             = col
	c.thickness         = 0.04
	c.solid             = true
	c.expression_string = expr
	p_grid.add_child(c)
	return c

## Create a dashed curve and add it to grid.
static func make_dashed(p_grid: Grid3D, expr: String = "cos(x)", col: Color = Color(0.3, 0.8, 1.0)) -> ParametricCurve3D:
	var c := ParametricCurve3D.new()
	c.grid              = p_grid
	c.color             = col
	c.thickness         = 0.035
	c.solid             = false
	c.dash_length       = 0.18
	c.gap_length        = 0.09
	c.expression_string = expr
	p_grid.add_child(c)
	return c

## Create a treadmill (animated dash) curve and add it to grid.
static func make_treadmill(p_grid: Grid3D, expr: String = "sin(x)", speed: float = 1.5) -> ParametricCurve3D:
	var c := ParametricCurve3D.new()
	c.grid              = p_grid
	c.color             = Color(1.0, 0.85, 0.2)
	c.thickness         = 0.035
	c.solid             = false
	c.treadmill         = true
	c.treadmill_speed   = speed
	c.expression_string = expr
	p_grid.add_child(c)
	return c
