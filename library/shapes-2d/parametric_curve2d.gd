@tool
extends BaseShape2D
class_name ParametricCurve2D

# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCES
# ═══════════════════════════════════════════════════════════════════════════════

## The AxisGrid2D node that defines the coordinate system.
@export var grid: AxisGrid2D:
	set(v):
		grid = v
		queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════

## The parametric function: given t, returns a world position Vector2.
## Example: func(t): return Vector2(t, sin(t))
var function: Callable:
	set(v):
		function = v
		queue_redraw()

## Range of the parameter t.
@export var t_range: Vector2 = Vector2(0.0, 1.0):
	set(v):
		t_range = v
		queue_redraw()

## Number of line segments (higher = smoother curve).
@export_range(8, 2048, 1) var steps: int = 256:
	set(v):
		steps = v
		queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# COORDINATE MAPPING
# ═══════════════════════════════════════════════════════════════════════════════

## The rectangle in world coordinates that maps exactly to the grid's pixel area.
## The grid's top‑left pixel corner corresponds to world_rect.position,
## and its bottom‑right pixel corner to world_rect.end.
@export var world_rect: Rect2 = Rect2(-5.0, -5.0, 10.0, 10.0):
	set(v):
		world_rect = v
		queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# STYLE
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Style")

@export var curve_color: Color = Color.CYAN:
	set(v):
		curve_color = v
		queue_redraw()

@export_range(0.5, 20.0, 0.1) var curve_width: float = 2.0:
	set(v):
		curve_width = v
		queue_redraw()

@export var antialiased: bool = true:
	set(v):
		antialiased = v
		queue_redraw()

## If true, the curve is drawn as a dashed line.
@export var dashed: bool = false:
	set(v):
		dashed = v
		queue_redraw()

@export_range(2.0, 200.0, 1.0) var dash_length: float = 8.0:
	set(v):
		dash_length = v
		queue_redraw()

@export_range(1.0, 200.0, 1.0) var gap_length: float = 4.0:
	set(v):
		gap_length = v
		queue_redraw()

## Dash offset along the curve (in pixels). Can be animated externally.
var dash_offset: float = 0.0:
	set(v):
		dash_offset = v
		queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# DRAWING
# ═══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	super._draw()
	if not grid or not function.is_valid():
		return
	
	# Build pixel points from the parametric function.
	var pts := _evaluate_curve()
	if pts.size() < 2:
		return
	
	if dashed:
		_draw_dashed_polyline(pts)
	else:
		draw_polyline(pts, curve_color, curve_width, antialiased)


## Evaluates the function at `steps + 1` equally spaced t values and returns
## an array of pixel coordinates ready for drawing.
func _evaluate_curve() -> PackedVector2Array:
	var result := PackedVector2Array()
	result.resize(steps + 1)
	
	var t_min := t_range.x
	var t_max := t_range.y
	var delta := (t_max - t_min) / steps
	
	for i in range(steps + 1):
		var t := t_min + i * delta
		var world_pos: Vector2 = function.call(t)
		var pixel_pos := _world_to_pixel(world_pos)
		result[i] = pixel_pos
	
	return result


## Maps a world coordinate to the grid's pixel coordinate system.
func _world_to_pixel(world: Vector2) -> Vector2:
	if not grid:
		return Vector2.ZERO
	
	# Grid's pixel rectangle
	var grid_top_left := -grid.grid_size * 0.5
	var grid_bottom_right := grid.grid_size * 0.5
	
	# Fractional position inside world_rect
	var fx := (world.x - world_rect.position.x) / world_rect.size.x
	var fy := (world.y - world_rect.position.y) / world_rect.size.y
	
	# Interpolate to pixel coordinates
	var pixel_x :float= lerp(grid_top_left.x, grid_bottom_right.x, fx)
	var pixel_y :float= lerp(grid_top_left.y, grid_bottom_right.y, fy)
	
	return Vector2(pixel_x, pixel_y)


## Draws a dashed polyline using the same algorithm as AxisGrid2D.
func _draw_dashed_polyline(pts: PackedVector2Array) -> void:
	var period := dash_length + gap_length
	if period <= 0.0:
		return
	
	var dist := fmod(dash_offset, period)
	if dist < 0.0:
		dist += period
	
	var in_dash := dist < dash_length
	var seg_start := pts[0]
	var dash_start := seg_start
	
	for i in range(1, pts.size()):
		var seg_end := pts[i]
		var seg_len := seg_start.distance_to(seg_end)
		if seg_len < 0.001:
			seg_start = seg_end
			continue
		var dir := (seg_end - seg_start) / seg_len
		var walked := 0.0
		
		while walked < seg_len:
			var remaining := (dash_length - dist) if in_dash else (period - dist)
			var step := minf(remaining, seg_len - walked)
			if step < 0.001:
				dist += period
				in_dash = !in_dash
				continue
			var pos := seg_start + dir * (walked + step)
			
			if in_dash:
				draw_line(dash_start, pos, curve_color, curve_width, antialiased)
			
			walked += step
			dist   += step
			
			if dist >= (dash_length if in_dash else period):
				dist = fmod(dist, period)
				in_dash = !in_dash
				if in_dash:
					dist = 0.0
					dash_start = pos
			elif in_dash:
				dash_start = pos
		
		seg_start = seg_end


var _runtime_func:Callable
var _expression:Expression
var _expression_valid:bool=false
@export var expression_string:String
@export var show_expression_errors:bool=false

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
	# Do a quick test to catch runtime-compile errors
	var test = _expression.execute([0.0])
	if _expression.has_execute_failed():
		_expression_valid = false
		
	_expression_valid = true
