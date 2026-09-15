@tool
class_name BackgroundRect
extends Node2D

## A procedural background drawing node that renders various elegant patterns
## using the _draw() virtual method. Fully configurable from the editor.
## Supports static and animated (dynamic) patterns.

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum BackgroundPattern {
	SOLID,              ## Flat filled rectangle
	GRID,               ## Regular square grid
	DOT_GRID,           ## Grid of dots / circles
	CROSS_HATCH,        ## Diagonal cross-hatch lines
	HEXAGONAL,          ## Honeycomb hex grid
	TRIANGULAR,         ## Triangulated grid
	CONCENTRIC_RINGS,   ## Expanding concentric ellipses
	RADIAL_LINES,       ## Lines radiating from a point
	WAVE,               ## Sine-wave horizontal lines
	CHECKER,            ## Checkerboard fill
	DIAMOND_GRID,       ## Rotated 45° square grid
	VORONOI_DOTS,       ## Scattered dot pattern (pseudo-Voronoi feel)
	CIRCUIT,            ## PCB-style circuit trace pattern
	BLUEPRINT,          ## Blueprint-style grid with major/minor lines
}

enum AnimationMode {
	NONE,       ## Static — no animation
	SCROLL,     ## Pattern scrolls in a direction
	PULSE,      ## Pattern pulses in scale/alpha
	ROTATE,     ## Pattern rotates around centre
	WAVE_FLOW,  ## Wave pattern animates phase
}

# ---------------------------------------------------------------------------
# Exported — Size & Clipping
# ---------------------------------------------------------------------------

@export_group("Size")

## Width of the background rectangle in pixels.
@export var rect_width: float = 400.0:
	set(v):
		rect_width = maxf(v, 1.0)
		queue_redraw()

## Height of the background rectangle in pixels.
@export var rect_height: float = 300.0:
	set(v):
		rect_height = maxf(v, 1.0)
		queue_redraw()

## Pivot / origin of the rect relative to this node's position.
## (0,0) = top-left corner; (0.5,0.5) = centred.
@export var pivot: Vector2 = Vector2.ZERO:
	set(v):
		pivot = v
		queue_redraw()

## Clip drawing to the rect boundaries.
@export var clip_to_rect: bool = true:
	set(v):
		clip_to_rect = v
		queue_redraw()

# ---------------------------------------------------------------------------
# Exported — Pattern
# ---------------------------------------------------------------------------

@export_group("Pattern")

## The background pattern to render.
@export var pattern: BackgroundPattern = BackgroundPattern.GRID:
	set(v):
		pattern = v
		queue_redraw()

## Background fill colour (drawn behind everything else).
@export var background_color: Color = Color(0.10, 0.10, 0.14, 1.0):
	set(v):
		background_color = v
		queue_redraw()

## Primary colour used for the pattern lines / shapes.
@export var pattern_color: Color = Color(0.30, 0.55, 0.90, 0.55):
	set(v):
		pattern_color = v
		queue_redraw()

## Secondary / accent colour (used in two-colour patterns like checkerboard,
## diamond grid, etc.).
@export var accent_color: Color = Color(0.60, 0.85, 1.00, 0.25):
	set(v):
		accent_color = v
		queue_redraw()

## Uniform cell / spacing size for grid-based patterns (pixels).
@export_range(4.0, 256.0, 1.0, "suffix:px") var cell_size: float = 32.0:
	set(v):
		cell_size = maxf(v, 4.0)
		queue_redraw()

## Line thickness for stroke-based patterns.
@export_range(0.5, 16.0, 0.5, "suffix:px") var line_width: float = 1.0:
	set(v):
		line_width = maxf(v, 0.5)
		queue_redraw()

## Dot / circle radius for dot-grid and voronoi patterns.
@export_range(1.0, 32.0, 0.5, "suffix:px") var dot_radius: float = 2.5:
	set(v):
		dot_radius = maxf(v, 0.5)
		queue_redraw()

## Corner radius for the background rect (rounded corners).
@export_range(0.0, 128.0, 1.0, "suffix:px") var corner_radius: float = 0.0:
	set(v):
		corner_radius = clampf(v, 0.0, 128.0)
		queue_redraw()

## Number of radial lines or wave layers depending on pattern.
@export_range(3, 128, 1) var count: int = 24:
	set(v):
		count = clampi(v, 3, 128)
		queue_redraw()

## Show a thin border around the rect.
@export var show_border: bool = false:
	set(v):
		show_border = v
		queue_redraw()

## Border colour (requires show_border = true).
@export var border_color: Color = Color(0.50, 0.75, 1.00, 0.80):
	set(v):
		border_color = v
		queue_redraw()

## Border thickness.
@export_range(0.5, 16.0, 0.5, "suffix:px") var border_width: float = 1.5:
	set(v):
		border_width = maxf(v, 0.5)
		queue_redraw()

# ---------------------------------------------------------------------------
# Exported — Blueprint-specific
# ---------------------------------------------------------------------------

@export_group("Blueprint Options")

## Major grid line interval (every N minor cells a thicker line is drawn).
@export_range(2, 20, 1) var major_grid_every: int = 5:
	set(v):
		major_grid_every = clampi(v, 2, 20)
		queue_redraw()

## Major line thickness multiplier relative to line_width.
@export_range(1.0, 8.0, 0.5) var major_line_scale: float = 2.5:
	set(v):
		major_line_scale = maxf(v, 1.0)
		queue_redraw()

## Draw axis cross at the origin of the rect.
@export var draw_origin_cross: bool = true:
	set(v):
		draw_origin_cross = v
		queue_redraw()

# ---------------------------------------------------------------------------
# Exported — Wave Options
# ---------------------------------------------------------------------------

@export_group("Wave Options")

## Amplitude of the sine wave in pixels.
@export_range(1.0, 200.0, 1.0, "suffix:px") var wave_amplitude: float = 20.0:
	set(v):
		wave_amplitude = maxf(v, 1.0)
		queue_redraw()

## Horizontal frequency of the sine wave (cycles across the rect width).
@export_range(0.1, 20.0, 0.1) var wave_frequency: float = 2.0:
	set(v):
		wave_frequency = maxf(v, 0.1)
		queue_redraw()

## Number of samples used to approximate each wave polyline.
@export_range(8, 512, 1) var wave_samples: int = 128:
	set(v):
		wave_samples = clampi(v, 8, 512)
		queue_redraw()

# ---------------------------------------------------------------------------
# Exported — Radial Options
# ---------------------------------------------------------------------------

@export_group("Radial Options")

## Centre of radial patterns (normalised: 0-1 within rect).
@export var radial_center: Vector2 = Vector2(0.5, 0.5):
	set(v):
		radial_center = v
		queue_redraw()

## Outer radius for concentric rings (0 = auto-fill rect diagonal).
@export_range(0.0, 2000.0, 1.0, "suffix:px") var radial_outer_radius: float = 0.0:
	set(v):
		radial_outer_radius = maxf(v, 0.0)
		queue_redraw()

## Inner spacing between concentric rings in pixels.
@export_range(4.0, 100.0, 1.0, "suffix:px") var ring_spacing: float = 20.0:
	set(v):
		ring_spacing = maxf(v, 1.0)
		queue_redraw()

## Aspect ratio for elliptical rings (1.0 = circles).
@export_range(0.1, 5.0, 0.05) var ring_aspect: float = 1.0:
	set(v):
		ring_aspect = maxf(v, 0.1)
		queue_redraw()

# ---------------------------------------------------------------------------
# Exported — Animation
# ---------------------------------------------------------------------------

@export_group("Animation")

## Animation mode. Set to NONE for a fully static background.
@export var animation_mode: AnimationMode = AnimationMode.NONE:
	set(v):
		animation_mode = v
		_update_process()
		queue_redraw()

## Animation speed multiplier.
@export_range(0.0, 10.0, 0.05) var animation_speed: float = 1.0

## Scroll direction (normalised; length ignored — only angle matters).
@export var scroll_direction: Vector2 = Vector2(1.0, 0.0)

## Pulse range — pattern alpha oscillates between these two values.
@export var pulse_alpha_range: Vector2 = Vector2(0.2, 1.0)

# ---------------------------------------------------------------------------
# Exported — Overlay / Post-FX
# ---------------------------------------------------------------------------

@export_group("Overlay")

## Draw a subtle vignette gradient over the rect.
@export var vignette: bool = false:
	set(v):
		vignette = v
		queue_redraw()

## Vignette strength (0 = invisible, 1 = heavy).
@export_range(0.0, 1.0, 0.01) var vignette_strength: float = 0.5:
	set(v):
		vignette_strength = clampf(v, 0.0, 1.0)
		queue_redraw()

## Vignette colour.
@export var vignette_color: Color = Color(0, 0, 0, 1):
	set(v):
		vignette_color = v
		queue_redraw()

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _time: float = 0.0
var _scroll_offset: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_rng.seed = 42
	_update_process()

func _update_process() -> void:
	set_process(animation_mode != AnimationMode.NONE)

func _process(delta: float) -> void:
	_time += delta * animation_speed
	if animation_mode == AnimationMode.SCROLL:
		var dir := scroll_direction.normalized() if scroll_direction.length() > 0.001 else Vector2.RIGHT
		_scroll_offset += dir * delta * animation_speed * cell_size
		# wrap offset
		_scroll_offset.x = fmod(_scroll_offset.x, cell_size)
		_scroll_offset.y = fmod(_scroll_offset.y, cell_size)
	queue_redraw()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Returns the top-left origin of the rect in local space.
func _rect_origin() -> Vector2:
	return Vector2(-rect_width * pivot.x, -rect_height * pivot.y)

## Returns the Rect2 in local space.
func _local_rect() -> Rect2:
	return Rect2(_rect_origin(), Vector2(rect_width, rect_height))

## Resolves the animated pattern colour (handles pulse).
func _pattern_color() -> Color:
	if animation_mode == AnimationMode.PULSE:
		var t := (sin(_time * TAU * 0.5) + 1.0) * 0.5
		var a :float= lerp(pulse_alpha_range.x, pulse_alpha_range.y, t)
		return Color(pattern_color.r, pattern_color.g, pattern_color.b, a)
	return pattern_color

## Returns the current rotation offset for ROTATE animation.
func _anim_rotation() -> float:
	if animation_mode == AnimationMode.ROTATE:
		return _time * TAU * 0.1
	return 0.0

## Returns the current wave phase offset.
func _wave_phase() -> float:
	if animation_mode == AnimationMode.WAVE_FLOW:
		return _time * TAU
	return 0.0

# ---------------------------------------------------------------------------
# _draw entry point
# ---------------------------------------------------------------------------

func _draw() -> void:
	var r := _local_rect()
	var cr := corner_radius

	# --- Background fill ---
	if cr > 0.0:
		draw_rect(r, background_color)   # fallback flat (Godot draw_rect is axis-aligned)
	else:
		draw_rect(r, background_color)

	# --- Clip region (scissors) ---
	# We use draw_set_transform to offset the canvas; clipping via RenderingServer
	# requires CanvasItem API not available in _draw(), so we guard each draw
	# call manually instead (cheaper and fully compatible).

	match pattern:
		BackgroundPattern.SOLID:
			pass  # background_color is already drawn
		BackgroundPattern.GRID:
			_draw_grid(r)
		BackgroundPattern.DOT_GRID:
			_draw_dot_grid(r)
		BackgroundPattern.CROSS_HATCH:
			_draw_cross_hatch(r)
		BackgroundPattern.HEXAGONAL:
			_draw_hex_grid(r)
		BackgroundPattern.TRIANGULAR:
			_draw_triangular_grid(r)
		BackgroundPattern.CONCENTRIC_RINGS:
			_draw_concentric_rings(r)
		BackgroundPattern.RADIAL_LINES:
			_draw_radial_lines(r)
		BackgroundPattern.WAVE:
			_draw_wave(r)
		BackgroundPattern.CHECKER:
			_draw_checker(r)
		BackgroundPattern.DIAMOND_GRID:
			_draw_diamond_grid(r)
		BackgroundPattern.VORONOI_DOTS:
			_draw_voronoi_dots(r)
		BackgroundPattern.CIRCUIT:
			_draw_circuit(r)
		BackgroundPattern.BLUEPRINT:
			_draw_blueprint(r)

	# --- Vignette overlay ---
	if vignette:
		_draw_vignette(r)

	# --- Border ---
	if show_border:
		draw_rect(r, border_color, false, border_width)

# ---------------------------------------------------------------------------
# Pattern: Grid
# ---------------------------------------------------------------------------

func _draw_grid(r: Rect2) -> void:
	var col := _pattern_color()
	var ox := r.position.x + fmod(_scroll_offset.x, cell_size)
	var oy := r.position.y + fmod(_scroll_offset.y, cell_size)

	# Vertical lines
	var x := ox - cell_size
	while x <= r.end.x + cell_size:
		var cx := clampf(x, r.position.x, r.end.x)
		if not clip_to_rect or (x >= r.position.x and x <= r.end.x):
			draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), col, line_width)
		x += cell_size

	# Horizontal lines
	var y := oy - cell_size
	while y <= r.end.y + cell_size:
		if not clip_to_rect or (y >= r.position.y and y <= r.end.y):
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), col, line_width)
		y += cell_size

# ---------------------------------------------------------------------------
# Pattern: Dot Grid
# ---------------------------------------------------------------------------

func _draw_dot_grid(r: Rect2) -> void:
	var col := _pattern_color()
	var ox := fmod(_scroll_offset.x, cell_size)
	var oy := fmod(_scroll_offset.y, cell_size)
	var x := r.position.x + ox - cell_size
	while x <= r.end.x + cell_size:
		var y := r.position.y + oy - cell_size
		while y <= r.end.y + cell_size:
			var p := Vector2(x, y)
			if not clip_to_rect or r.has_point(p):
				draw_circle(p, dot_radius, col)
			y += cell_size
		x += cell_size

# ---------------------------------------------------------------------------
# Pattern: Cross-Hatch
# ---------------------------------------------------------------------------

func _draw_cross_hatch(r: Rect2) -> void:
	var col := _pattern_color()
	var diag := r.size.length()
	var cx := r.position.x + r.size.x * 0.5
	var cy := r.position.y + r.size.y * 0.5
	var phase := _scroll_offset.x + _scroll_offset.y

	# +45° lines
	var t := -diag + fmod(phase, cell_size)
	while t <= diag:
		var p1 := Vector2(cx + t, cy - diag)
		var p2 := Vector2(cx + t + diag, cy)
		var q1 := Vector2(cx + t - diag, cy)
		var q2 := Vector2(cx + t, cy + diag)
		_draw_clipped_line(r, p1, q2, col, line_width)
		t += cell_size

	# -45° lines
	t = -diag + fmod(phase, cell_size)
	while t <= diag:
		var p1 := Vector2(cx - t - diag, cy)
		var q2 := Vector2(cx - t, cy + diag)
		var p3 := Vector2(cx - t, cy - diag)
		var q3 := Vector2(cx - t + diag, cy)
		_draw_clipped_line(r, p3, q2, col, line_width)
		t += cell_size

# ---------------------------------------------------------------------------
# Pattern: Hexagonal
# ---------------------------------------------------------------------------

func _draw_hex_grid(r: Rect2) -> void:
	var col := _pattern_color()
	var s := cell_size * 0.5            # side length
	var w := s * sqrt(3.0)              # flat-top hex width
	var h := s * 2.0                    # flat-top hex height
	var col_step := w
	var row_step := h * 0.75

	var ox := fmod(_scroll_offset.x, col_step * 2.0)
	var oy := fmod(_scroll_offset.y, row_step * 2.0)

	var row := -2
	while row * row_step + oy < r.end.y + h:
		var col_idx := -2
		while col_idx * col_step + ox < r.end.x + w:
			var offset_x := w * 0.5 if row % 2 != 0 else 0.0
			var cx := r.position.x + col_idx * col_step + offset_x + ox
			var cy := r.position.y + row * row_step + oy
			_draw_hex(cx, cy, s, col)
			col_idx += 1
		row += 1

func _draw_hex(cx: float, cy: float, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		var angle_deg := 60.0 * i - 30.0
		var angle_rad := deg_to_rad(angle_deg)
		pts.append(Vector2(cx + s * cos(angle_rad), cy + s * sin(angle_rad)))
	draw_polyline(pts + PackedVector2Array([pts[0]]), col, line_width, true)

# ---------------------------------------------------------------------------
# Pattern: Triangular
# ---------------------------------------------------------------------------

func _draw_triangular_grid(r: Rect2) -> void:
	var col := _pattern_color()
	var h_step := cell_size
	var v_step := cell_size * sqrt(3.0) * 0.5
	var ox := fmod(_scroll_offset.x, h_step)
	var oy := fmod(_scroll_offset.y, v_step * 2.0)

	var row := -2
	while r.position.y + row * v_step + oy < r.end.y + cell_size:
		var y0 := r.position.y + row * v_step + oy
		var y1 := y0 + v_step
		var offset := h_step * 0.5 if row % 2 != 0 else 0.0
		var col_idx := -2
		while r.position.x + col_idx * h_step + offset + ox < r.end.x + cell_size:
			var x0 := r.position.x + col_idx * h_step + offset + ox
			var mid_x := x0 + h_step * 0.5
			# Upward triangle
			_draw_clipped_line(r, Vector2(x0, y1), Vector2(mid_x, y0), col, line_width)
			_draw_clipped_line(r, Vector2(mid_x, y0), Vector2(x0 + h_step, y1), col, line_width)
			_draw_clipped_line(r, Vector2(x0, y1), Vector2(x0 + h_step, y1), col, line_width)
			col_idx += 1
		row += 1

# ---------------------------------------------------------------------------
# Pattern: Concentric Rings
# ---------------------------------------------------------------------------

func _draw_concentric_rings(r: Rect2) -> void:
	var col := _pattern_color()
	var center := r.position + r.size * radial_center
	var max_r := radial_outer_radius if radial_outer_radius > 0.0 else r.size.length()
	var phase_offset := _scroll_offset.length() if animation_mode == AnimationMode.SCROLL else 0.0
	var rot := _anim_rotation()

	var ri := ring_spacing + fmod(phase_offset, ring_spacing)
	while ri <= max_r + ring_spacing:
		# Draw ellipse as polyline
		var pts := PackedVector2Array()
		var segs :int= max(32, count)
		for i in segs + 1:
			var a := TAU * i / segs + rot
			pts.append(center + Vector2(cos(a) * ri, sin(a) * ri / ring_aspect))
		# Fade outer rings
		var alpha_t := 1.0 - (ri / (max_r + ring_spacing))
		var c := Color(col.r, col.g, col.b, col.a * alpha_t)
		draw_polyline(pts, c, line_width, false)
		ri += ring_spacing

# ---------------------------------------------------------------------------
# Pattern: Radial Lines
# ---------------------------------------------------------------------------

func _draw_radial_lines(r: Rect2) -> void:
	var col := _pattern_color()
	var center := r.position + r.size * radial_center
	var max_r := r.size.length()
	var rot := _anim_rotation()

	for i in count:
		var angle := TAU * i / count + rot
		var end_pt := center + Vector2(cos(angle), sin(angle)) * max_r
		var alpha_t :float= 0.3 + 0.7 * abs(sin(TAU * i / count))
		var c := Color(col.r, col.g, col.b, col.a * alpha_t)
		_draw_clipped_line(r, center, end_pt, c, line_width)

# ---------------------------------------------------------------------------
# Pattern: Wave
# ---------------------------------------------------------------------------

func _draw_wave(r: Rect2) -> void:
	var col := _pattern_color()
	var phase := _wave_phase()
	var spacing := r.size.y / (count + 1)

	for i in count:
		var base_y := r.position.y + spacing * (i + 1)
		var pts := PackedVector2Array()
		for s in wave_samples + 1:
			var t := float(s) / wave_samples
			var x := r.position.x + t * r.size.x
			var y := base_y + sin(t * wave_frequency * TAU + phase + i * 0.4) * wave_amplitude
			pts.append(Vector2(x, y))
		var alpha_t := 0.4 + 0.6 * (1.0 - float(i) / count)
		var c := Color(col.r, col.g, col.b, col.a * alpha_t)
		draw_polyline(pts, c, line_width, false)

# ---------------------------------------------------------------------------
# Pattern: Checker
# ---------------------------------------------------------------------------

func _draw_checker(r: Rect2) -> void:
	var col1 := _pattern_color()
	var col2 := accent_color
	var cols := int(ceil(r.size.x / cell_size)) + 2
	var rows := int(ceil(r.size.y / cell_size)) + 2
	var ox := fmod(_scroll_offset.x, cell_size * 2.0)
	var oy := fmod(_scroll_offset.y, cell_size * 2.0)

	for row in rows:
		for col_i in cols:
			var rx := r.position.x + col_i * cell_size - cell_size + ox - cell_size
			var ry := r.position.y + row * cell_size - cell_size + oy - cell_size
			var cell_rect := Rect2(rx, ry, cell_size, cell_size)
			if clip_to_rect:
				cell_rect = cell_rect.intersection(r)
				if cell_rect.size == Vector2.ZERO:
					continue
			var is_dark := (row + col_i) % 2 == 0
			draw_rect(cell_rect, col2 if is_dark else col1)

# ---------------------------------------------------------------------------
# Pattern: Diamond Grid
# ---------------------------------------------------------------------------

func _draw_diamond_grid(r: Rect2) -> void:
	var col := _pattern_color()
	var half := cell_size * 0.5
	var ox := fmod(_scroll_offset.x, cell_size)
	var oy := fmod(_scroll_offset.y, cell_size)
	var x := r.position.x - cell_size + ox
	while x <= r.end.x + cell_size:
		var y := r.position.y - cell_size + oy
		while y <= r.end.y + cell_size:
			var pts := PackedVector2Array([
				Vector2(x, y - half),
				Vector2(x + half, y),
				Vector2(x, y + half),
				Vector2(x - half, y),
				Vector2(x, y - half),
			])
			var in_rect := r.has_point(Vector2(x, y))
			if not clip_to_rect or in_rect:
				draw_polyline(pts, col, line_width, false)
			y += cell_size
		x += cell_size

# ---------------------------------------------------------------------------
# Pattern: Voronoi Dots (pseudo-random scattered dots)
# ---------------------------------------------------------------------------

func _draw_voronoi_dots(r: Rect2) -> void:
	var col := _pattern_color()
	_rng.seed = 42
	var cols_count := int(ceil(r.size.x / cell_size)) + 1
	var rows_count := int(ceil(r.size.y / cell_size)) + 1
	var phase := _time * 20.0 if animation_mode == AnimationMode.WAVE_FLOW else 0.0

	for row in rows_count:
		for col_i in cols_count:
			_rng.seed = (row * 1000 + col_i) * 7919
			var jx := _rng.randf() * cell_size
			var jy := _rng.randf() * cell_size
			var px := r.position.x + col_i * cell_size + jx
			var py := r.position.y + row * cell_size + jy + sin(_rng.randf() * TAU + phase) * dot_radius
			var p := Vector2(px, py)
			if not clip_to_rect or r.has_point(p):
				var alpha_mod := 0.5 + 0.5 * _rng.randf()
				var c := Color(col.r, col.g, col.b, col.a * alpha_mod)
				draw_circle(p, dot_radius * (0.5 + _rng.randf() * 0.8), c)

# ---------------------------------------------------------------------------
# Pattern: Circuit (PCB traces)
# ---------------------------------------------------------------------------

func _draw_circuit(r: Rect2) -> void:
	var col := _pattern_color()
	_rng.seed = 1337
	var snap := cell_size
	var phase_scroll := _scroll_offset

	var num_traces := count
	for i in num_traces:
		_rng.seed = i * 3571 + 7
		var sx := r.position.x + _rng.randi_range(0, int(r.size.x / snap)) * snap + fmod(phase_scroll.x, snap)
		var sy := r.position.y + _rng.randi_range(0, int(r.size.y / snap)) * snap + fmod(phase_scroll.y, snap)
		var pts := PackedVector2Array([Vector2(sx, sy)])
		var cx2 := sx
		var cy2 := sy
		for _step in _rng.randi_range(2, 6):
			var horizontal := _rng.randi_range(0, 1) == 0
			var steps := _rng.randi_range(1, 4)
			var sign_v := 1 if _rng.randi_range(0, 1) == 0 else -1
			if horizontal:
				cx2 += steps * snap * sign_v
			else:
				cy2 += steps * snap * sign_v
			pts.append(Vector2(cx2, cy2))
			# via dot
			if not clip_to_rect or r.has_point(Vector2(cx2, cy2)):
				draw_circle(Vector2(cx2, cy2), dot_radius * 1.5, col)

		var alpha_t := 0.3 + 0.7 * (float(i) / num_traces)
		var c := Color(col.r, col.g, col.b, col.a * alpha_t)
		draw_polyline(pts, c, line_width, false)

# ---------------------------------------------------------------------------
# Pattern: Blueprint
# ---------------------------------------------------------------------------

func _draw_blueprint(r: Rect2) -> void:
	var minor_col := Color(pattern_color.r, pattern_color.g, pattern_color.b, pattern_color.a * 0.35)
	var major_col := Color(pattern_color.r, pattern_color.g, pattern_color.b, pattern_color.a * 0.75)
	var ox := fmod(_scroll_offset.x, cell_size)
	var oy := fmod(_scroll_offset.y, cell_size)

	var col_idx := -major_grid_every
	var x := r.position.x + ox
	while x <= r.end.x + cell_size:
		var is_major := col_idx % major_grid_every == 0
		var lw := line_width * major_line_scale if is_major else line_width
		var lc := major_col if is_major else minor_col
		if not clip_to_rect or (x >= r.position.x and x <= r.end.x):
			draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), lc, lw)
		x += cell_size
		col_idx += 1

	var row_idx := -major_grid_every
	var y := r.position.y + oy
	while y <= r.end.y + cell_size:
		var is_major := row_idx % major_grid_every == 0
		var lw := line_width * major_line_scale if is_major else line_width
		var lc := major_col if is_major else minor_col
		if not clip_to_rect or (y >= r.position.y and y <= r.end.y):
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), lc, lw)
		y += cell_size
		row_idx += 1

	if draw_origin_cross:
		var cross_col := Color(accent_color.r, accent_color.g, accent_color.b, 0.9)
		var cx := r.position.x + r.size.x * radial_center.x
		var cy := r.position.y + r.size.y * radial_center.y
		var arm := cell_size * major_grid_every * 0.3
		draw_line(Vector2(cx - arm, cy), Vector2(cx + arm, cy), cross_col, line_width * major_line_scale)
		draw_line(Vector2(cx, cy - arm), Vector2(cx, cy + arm), cross_col, line_width * major_line_scale)
		draw_circle(Vector2(cx, cy), dot_radius * 2.0, cross_col)

# ---------------------------------------------------------------------------
# Vignette overlay
# ---------------------------------------------------------------------------

func _draw_vignette(r: Rect2) -> void:
	# Approximate vignette with four gradient triangles from each edge inward.
	var edge := minf(r.size.x, r.size.y) * 0.5 * vignette_strength
	var vc := vignette_color
	var tc := Color(vc.r, vc.g, vc.b, 0.0)

	# Top
	var pts_top = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y),
		Vector2(r.end.x, r.position.y + edge), Vector2(r.position.x, r.position.y + edge)])
	draw_colored_polygon(pts_top,vc)
	# Bottom
	var pts_bot := PackedVector2Array([Vector2(r.position.x, r.end.y - edge),
		Vector2(r.end.x, r.end.y - edge), r.end, Vector2(r.position.x, r.end.y)])
	draw_colored_polygon(pts_bot,vc)
	# Left
	var pts_lft := PackedVector2Array([r.position, Vector2(r.position.x + edge, r.position.y),
		Vector2(r.position.x + edge, r.end.y), Vector2(r.position.x, r.end.y)])
	draw_colored_polygon(pts_lft,tc)
	# Right
	var pts_rgt := PackedVector2Array([Vector2(r.end.x - edge, r.position.y),
		Vector2(r.end.x, r.position.y), r.end, Vector2(r.end.x - edge, r.end.y)])
	draw_colored_polygon(pts_rgt, tc)

# ---------------------------------------------------------------------------
# Utility: clipped line draw (naive endpoint clamping — works for axis-aligned
# and short lines fully within the rect). For rigorous clip use Liang-Barsky.
# ---------------------------------------------------------------------------

func _draw_clipped_line(r: Rect2, from: Vector2, to: Vector2, col: Color, width: float) -> void:
	if not clip_to_rect:
		draw_line(from, to, col, width)
		return
	# Liang–Barsky line clipping
	var dx := to.x - from.x
	var dy := to.y - from.y
	var p := [-dx, dx, -dy, dy]
	var q := [from.x - r.position.x, r.end.x - from.x, from.y - r.position.y, r.end.y - from.y]
	var t0 := 0.0
	var t1 := 1.0
	for k in 4:
		if p[k] == 0.0:
			if q[k] < 0.0:
				return  # parallel and outside
		elif p[k] < 0.0:
			t0 = maxf(t0, q[k] / p[k])
		else:
			t1 = minf(t1, q[k] / p[k])
	if t0 > t1:
		return
	var cf := from + Vector2(dx, dy) * t0
	var ct := from + Vector2(dx, dy) * t1
	draw_line(cf, ct, col, width)

# ---------------------------------------------------------------------------
# Editor gizmo: draw a selection outline in-editor
# ---------------------------------------------------------------------------

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if rect_width < 1.0 or rect_height < 1.0:
		warnings.append("rect_width and rect_height must be >= 1.")
	return warnings
