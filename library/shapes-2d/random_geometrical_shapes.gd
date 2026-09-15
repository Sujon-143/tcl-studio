@tool
extends BaseShape2D
class_name RandomGeoShapes

## Draws a field of stylized, morphing geometric shapes for background decoration.
## Shape vertex calculations run on a WorkerThreadPool thread when shape_count
## exceeds [thread_threshold], keeping the main thread free.
##
## All properties trigger queue_redraw() so live preview works in the editor.

# ── Types ─────────────────────────────────────────────────────────────────────

enum FillMode {
	SOLID,          ## Flat filled polygons.
	OUTLINE,        ## Stroked outlines only.
	SOLID_OUTLINE,  ## Fill + contrasting outline.
	GRADIENT,       ## Radial gradient per shape (approximated with rings).
}

enum ShapeSet {
	ALL,        ## Triangles, quads, pentagons, hexagons, stars.
	ANGULAR,    ## Triangles and quads only.
	ROUNDED,    ## Pentagons and hexagons.
	STARS,      ## Star polygons only.
}

# Internal per-shape state — all data needed to draw one shape.
class GeoShape:
	var center:       Vector2
	var base_radius:  float
	var sides:        int          ## Vertex count (3–8; stars encode as negative).
	var star_skip:    int          ## For stars: how many vertices to skip (2 or 3).
	var rotation:     float        ## Current rotation in radians.
	var rot_speed:    float        ## Radians per second.
	var phase:        float        ## Morph phase offset (0–TAU).
	var morph_speed:  float        ## Radians per second for morph oscillation.
	var morph_amp:    float        ## Morph amplitude as fraction of base_radius.
	var color:        Color
	var line_width:   float        ## For outline modes.
	# Pre-computed polygon points (updated off-thread).
	var points:       PackedVector2Array

# ── Editor properties ─────────────────────────────────────────────────────────

@export_group("Shapes")

## Number of shapes to draw.
@export_range(1, 200, 1)
var shape_count: int = 20:
	set(v):
		shape_count = v
		_rebuild_shapes()

## Which shape families to include.
@export var shape_set: ShapeSet = ShapeSet.ALL:
	set(v):
		shape_set = v
		_rebuild_shapes()

## Minimum shape radius in pixels.
@export_range(5.0, 300.0, 1.0, "suffix:px")
var radius_min: float = 20.0:
	set(v): radius_min = v; _rebuild_shapes()

## Maximum shape radius in pixels.
@export_range(5.0, 300.0, 1.0, "suffix:px")
var radius_max: float = 80.0:
	set(v): radius_max = v; _rebuild_shapes()

## Region in which shapes are scattered (relative to node origin).
@export var scatter_rect: Rect2 = Rect2(-200, -200, 400, 400):
	set(v): scatter_rect = v; _rebuild_shapes()

## Random seed — change to get a different layout.
@export var seed_value: int = 0:
	set(v): seed_value = v; _rebuild_shapes()

@export_group("Motion")

## Global morph speed multiplier.
@export_range(0.0, 5.0, 0.01)
var morph_speed: float = 1.0:
	set(v): morph_speed = v

## Maximum morph amplitude as a fraction of each shape's radius.
@export_range(0.0, 0.8, 0.01)
var morph_amplitude: float = 0.25:
	set(v): morph_amplitude = v

## Global rotation speed multiplier.
@export_range(0.0, 5.0, 0.01)
var rotation_speed: float = 1.0:
	set(v): rotation_speed = v

@export_group("Style")

## How shapes are filled.
@export var fill_mode: FillMode = FillMode.SOLID_OUTLINE:
	set(v): fill_mode = v; queue_redraw()

## Primary palette — shapes pick colors from this list.
@export var palette: Array[Color] = [
	Color(0.18, 0.42, 0.82, 0.55),
	Color(0.82, 0.25, 0.45, 0.50),
	Color(0.25, 0.75, 0.60, 0.50),
	Color(0.85, 0.65, 0.15, 0.50),
	Color(0.55, 0.25, 0.85, 0.50),
]:
	set(v): palette = v; _rebuild_shapes()

## Outline color used in OUTLINE and SOLID_OUTLINE modes.
@export var outline_color: Color = Color(1, 1, 1, 0.35):
	set(v): outline_color = v; queue_redraw()

## Outline thickness in pixels.
@export_range(0.5, 8.0, 0.1, "suffix:px")
var outline_width: float = 1.5:
	set(v): outline_width = v; queue_redraw()

@export_group("Performance")

## Above this shape count, vertex math is offloaded to a worker thread.
@export_range(10, 200, 1)
var thread_threshold: int = 40

## Animate in editor (can be taxing; disable for heavy scenes).
@export var animate_in_editor: bool = true:
	set(v):
		animate_in_editor = v
		set_process(animate_in_editor or not Engine.is_editor_hint())

# ── Internal state ────────────────────────────────────────────────────────────

var _shapes:       Array[GeoShape] = []
var _rng:          RandomNumberGenerator = RandomNumberGenerator.new()
var _time:         float = 0.0
var _thread_busy:  bool = false
# Double-buffer: _shapes holds current draw data; _pending holds next-frame data.
var _pending:      Array[GeoShape] = []
var _mutex:        Mutex = Mutex.new()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	super._ready()
	_rebuild_shapes()
	set_process(animate_in_editor or not Engine.is_editor_hint())

func _process(delta: float) -> void:
	_time += delta
	if shape_count >= thread_threshold and not Engine.is_editor_hint():
		_update_threaded(delta)
	else:
		_update_inline(delta)
	queue_redraw()

# ── Shape management ──────────────────────────────────────────────────────────

func _rebuild_shapes() -> void:
	_rng.seed = seed_value
	_shapes.clear()
	for i in shape_count:
		_shapes.append(_make_shape(i))
	queue_redraw()

func _make_shape(index: int) -> GeoShape:
	var s := GeoShape.new()
	s.center = Vector2(
		scatter_rect.position.x + _rng.randf() * scatter_rect.size.x,
		scatter_rect.position.y + _rng.randf() * scatter_rect.size.y
	)
	s.base_radius = _rng.randf_range(radius_min, radius_max)
	s.rotation    = _rng.randf_range(0.0, TAU)
	s.rot_speed   = _rng.randf_range(-1.2, 1.2)
	s.phase       = _rng.randf_range(0.0, TAU)
	s.morph_speed = _rng.randf_range(0.5, 2.0)
	s.morph_amp   = _rng.randf_range(0.05, morph_amplitude)
	s.line_width  = _rng.randf_range(0.8, outline_width)

	# Pick sides based on shape_set.
	match shape_set:
		ShapeSet.ANGULAR:
			s.sides = _rng.randi_range(3, 4)
			s.star_skip = 0
		ShapeSet.ROUNDED:
			s.sides = _rng.randi_range(5, 8)
			s.star_skip = 0
		ShapeSet.STARS:
			s.sides = _rng.randi_range(4, 7)
			s.star_skip = _rng.randi_range(2, 3)
		_: # ALL
			var roll := _rng.randi_range(0, 4)
			if roll <= 1:
				s.sides = _rng.randi_range(3, 4); s.star_skip = 0
			elif roll <= 3:
				s.sides = _rng.randi_range(5, 8); s.star_skip = 0
			else:
				s.sides = _rng.randi_range(4, 6); s.star_skip = 2

	if palette.size() > 0:
		s.color = palette[index % palette.size()]
	else:
		s.color = Color(_rng.randf(), _rng.randf(), _rng.randf(), 0.5)

	s.points = _compute_points(s, _time)
	return s

# ── Vertex computation ────────────────────────────────────────────────────────

func _compute_points(s: GeoShape, t: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var is_star: bool = s.star_skip > 0

	if is_star:
		# Alternating outer/inner vertices to form a star.
		var total_verts: int = s.sides * 2
		var inner_r: float = s.base_radius * 0.42
		for vi in total_verts:
			var angle: float = s.rotation + (float(vi) / float(total_verts)) * TAU
			var is_outer: bool = (vi % 2 == 0)
			var r: float = s.base_radius if is_outer else inner_r
			# Apply morph only to outer vertices.
			if is_outer:
				var morph: float = sin(t * s.morph_speed * morph_speed + s.phase + vi * 0.7) \
								   * s.morph_amp * s.base_radius
				r += morph
			pts.append(s.center + Vector2(cos(angle), sin(angle)) * r)
	else:
		for vi in s.sides:
			var angle: float = s.rotation + (float(vi) / float(s.sides)) * TAU
			var morph: float = sin(t * s.morph_speed * morph_speed + s.phase + vi * 1.3) \
							   * s.morph_amp * s.base_radius
			var r: float = s.base_radius + morph
			pts.append(s.center + Vector2(cos(angle), sin(angle)) * r)
	return pts

# ── Update strategies ─────────────────────────────────────────────────────────

func _update_inline(delta: float) -> void:
	for s in _shapes:
		s.rotation += s.rot_speed * rotation_speed * delta
		s.points = _compute_points(s, _time)

func _update_threaded(delta: float) -> void:
	if _thread_busy:
		return
	_thread_busy = true
	# Snapshot the shapes array for the thread.
	var snapshot: Array[GeoShape] = _shapes.duplicate()
	var t: float = _time
	var d: float = delta
	WorkerThreadPool.add_task(func():
		var results: Array[GeoShape] = []
		for s in snapshot:
			s.rotation += s.rot_speed * rotation_speed * d
			s.points = _compute_points(s, t)
			results.append(s)
		_mutex.lock()
		_pending = results
		_mutex.unlock()
		call_deferred("_apply_thread_results")
	)

func _apply_thread_results() -> void:
	_mutex.lock()
	_shapes = _pending.duplicate()
	_mutex.unlock()
	_thread_busy = false

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	super._draw()
	for s in _shapes:
		if s.points.size() < 3:
			continue
		match fill_mode:
			FillMode.SOLID:
				draw_colored_polygon(s.points, s.color)
			FillMode.OUTLINE:
				_draw_poly_outline(s.points, outline_color, s.line_width)
			FillMode.SOLID_OUTLINE:
				draw_colored_polygon(s.points, s.color)
				_draw_poly_outline(s.points, outline_color, s.line_width)
			FillMode.GRADIENT:
				_draw_gradient_shape(s)

func _draw_poly_outline(pts: PackedVector2Array, color: Color, width: float) -> void:
	var n: int = pts.size()
	for i in n:
		draw_line(pts[i], pts[(i + 1) % n], color, width, true)

func _draw_gradient_shape(s: GeoShape) -> void:
	# Approximate a radial gradient with 3 concentric rings.
	var steps: int = 3
	for step in steps:
		var t: float = float(step) / float(steps)
		var scaled := PackedVector2Array()
		for p in s.points:
			scaled.append(s.center + (p - s.center) * (1.0 - t * 0.7))
		var alpha_mod: float = s.color.a * (1.0 - t * 0.6)
		var c := Color(s.color.r + t * 0.2, s.color.g + t * 0.2, s.color.b + t * 0.2, alpha_mod)
		draw_colored_polygon(scaled, c)
