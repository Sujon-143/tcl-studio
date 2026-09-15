@tool
extends DashedLine
class_name ParametricCurve

## Plots a mathematical curve on a GridPlane using a callable f(x) → y.
## Points are computed in the grid's local coordinate system and converted to
## world positions via GridPlane.local_to_global, so the curve always lies on
## the grid surface regardless of its transform or scale_to_world_space.
##
## All DashedLine features (solid/dashed, thickness, draw_progress, treadmill,
## treadmill_reverse) are inherited and work without any extra wiring.

#region Configuration — Curve

@export_group("Curve")

## How many sample points to compute along the curve (controls smoothness).
@export_range(2, 2000, 1) var resolution: int = 100 :
	set(value):
		resolution = max(2, value)
		if _ready_done: update_curve()

## Range of x values to evaluate (min, max) in grid-space units.
## Clamped to the grid's x_range automatically when use_grid_x_range is true.
@export var x_range: Vector2 = Vector2(-5.0, 5.0) :
	set(value):
		x_range = value
		if _ready_done: update_curve()

## When true the curve's x_range is driven by the grid's x_range automatically.
@export var use_grid_x_range: bool = false :
	set(value):
		use_grid_x_range = value
		if _ready_done: update_curve()

## Height above the grid plane (grid-space Z offset). Usually 0.
## Raise this slightly (e.g. 0.01) to prevent z-fighting with the grid surface.
@export_range(0.0, 1.0, 0.001) var lift: float = 0.0 :
	set(value):
		lift = value
		if _ready_done: update_curve()

#endregion

#region Private

## The GridPlane this curve is plotted on. Set via set_grid().
## Not exported — assign via code or the set_grid() factory helper.
var grid: GridPlane = null

## Callable f(x: float) → float. Set via set_function().
var func_x_to_y: Callable = func(x: float) -> float: return sin(x)

#endregion

#region Static factories

static func get_default_parametric_curve(p_grid: GridPlane) -> ParametricCurve:
	var c      := ParametricCurve.new()
	c.grid      = p_grid
	c.color     = Color(1.0, 0.5, 0.0)
	c.thickness = 0.05
	c.solid     = true
	return c

static func get_dashed(p_grid: GridPlane) -> ParametricCurve:
	var c           := ParametricCurve.new()
	c.grid           = p_grid
	c.color          = Color(1.0, 0.5, 0.0)
	c.thickness      = 0.04
	c.solid          = false
	c.dash_length    = 0.2
	c.gap_length     = 0.1
	return c

static func get_treadmill_curve(p_grid: GridPlane, speed: float = 1.0) -> ParametricCurve:
	var c              := ParametricCurve.new()
	c.grid              = p_grid
	c.color             = Color(1.0, 0.5, 0.0)
	c.thickness         = 0.04
	c.solid             = false
	c.treadmill         = true
	c.treadmill_speed   = speed
	return c

#endregion

#region Lifecycle

func _init() -> void:
	super([])

func _ready() -> void:
	# DashedLine._ready() sets up mesh instances and sets _ready_done = true.
	super._ready()
	update_curve()

# _process is fully handled by DashedLine (treadmill scrolling).
# No override needed — treadmill works on the already-computed points array.

#endregion

#region Public API

## Assigns a GridPlane and re-parents this node to it so that local coordinates
## align. Safe to call after _ready().
func set_grid(new_grid: GridPlane) -> void:
	grid = new_grid
	if is_instance_valid(grid) and get_parent() != grid:
		if get_parent():
			get_parent().remove_child(self)
		grid.add_child(self)
	update_curve()

## Sets the plotting function f(x: float) → float and redraws.
func set_function(new_func: Callable) -> void:
	func_x_to_y = new_func
	update_curve()

## Sets the x evaluation range and redraws.
func set_x_range(min_x: float, max_x: float) -> void:
	x_range = Vector2(min_x, max_x)
	update_curve()

## Sets the number of sample points and redraws.
func set_resolution(new_res: int) -> void:
	resolution = max(2, new_res)
	update_curve()

## Recomputes all curve points from func_x_to_y and the current x_range,
## then triggers a DashedLine draw(). Call this after changing the function
## or any property that affects curve shape.
func update_curve() -> void:
	if not is_instance_valid(grid):
		return

	var range_to_use := grid.x_range if use_grid_x_range else x_range
	var step: float   = (range_to_use.y - range_to_use.x) / resolution

	var new_points: Array[Vector3] = []
	for i in range(resolution + 1):
		var gx: float = range_to_use.x + i * step
		var gy: float = func_x_to_y.call(gx)
		# gz = 0.0: curve lies at the grid's Z origin (flat on the XZ plane).
		# gy + lift: function value maps to world Y (up), lift adds a small
		# offset to prevent z-fighting with the grid surface.
		new_points.append(grid.local_to_global(gx,0.0,gy + lift))

	points = new_points
#endregion
