@tool
extends BaseShape2D
class_name AxisGrid2D

@export_range(-100, 0, 1) var x_limit_l: float = -5:
	set(v): x_limit_l = v; queue_redraw()
@export_range(0, 100, 1) var x_limit_h: float = 5:
	set(v): x_limit_h = v; queue_redraw()
@export_range(-100, 0, 1) var y_limit_l: float = -5:
	set(v): y_limit_l = v; queue_redraw()
@export_range(0, 100, 1) var y_limit_h: float = 5:
	set(v): y_limit_h = v; queue_redraw()
	
@export_range(1, 100, 1.0) var step_size_x: int = 1:
	set(v): step_size_x = v; queue_redraw()
@export_range(1, 100, 1.0) var step_size_y: int = 1:
	set(v): step_size_y = v; queue_redraw()





@export var thickness: float = 2.0:
	set(v): thickness = v; queue_redraw()
@export var axis_thickness: float = 4.0:
	set(v): axis_thickness = v; queue_redraw()

@export var grid_color: Color = Color(1, 1, 1, 0.2):
	set(v): grid_color = v; queue_redraw()
@export var axis_color: Color = Color.WHITE:
	set(v): axis_color = v; queue_redraw()
@export var tick_color: Color = Color.WHITE:
	set(v): tick_color = v; queue_redraw()

@export var show_labels: bool = false:
	set(v): show_labels = v; queue_redraw()
@export var label_offset: Vector2 = Vector2.ZERO:
	set(v): label_offset = v; queue_redraw()
@export_range(10, 100, 1.0) var label_font_size: float = 20:
	set(v): label_font_size = v; queue_redraw()

@export var background: StyleBoxFlat:
	set(v):
		if background and background.changed.is_connected(queue_redraw):
			background.changed.disconnect(queue_redraw)
		background = v
		if background:
			background.changed.connect(queue_redraw)
		queue_redraw()

@export var grid_visible: bool = true:
	set(v): grid_visible = v; queue_redraw()

## Tick half-length in pixels (used when grid is hidden)
@export var tick_size: float = 8.0:
	set(v): tick_size = v; queue_redraw()

## Draw arrowheads at axis ends
@export var show_arrows: bool = false:
	set(v): show_arrows = v; queue_redraw()
@export var arrow_size: float = 12.0:
	set(v): arrow_size = v; queue_redraw()


func _draw() -> void:
	super._draw()

	# Background
	if background:
		draw_style_box(background, Rect2(
			Vector2(x_limit_l, y_limit_l) * unit_size,
			(Vector2(x_limit_h, y_limit_h) - Vector2(x_limit_l, y_limit_l)) * unit_size
		))

	# Grid lines or ticks + axes
	if grid_visible:
		_draw_grid()
	else:
		_draw_ticks()

	_draw_axes()

	if show_labels:
		_draw_labels()


func _draw_grid() -> void:
	# Vertical lines
	for i in range(x_limit_l, x_limit_h + 1, step_size_x):
		if i == 0:
			continue  # drawn as axis
		var pt_1 := Vector2(i * unit_size, y_limit_l * unit_size)
		var pt_2 := Vector2(i * unit_size, y_limit_h * unit_size)
		draw_line(pt_1, pt_2, grid_color, thickness, true)

	# Horizontal lines
	for j in range(y_limit_l, y_limit_h + 1, step_size_y):
		if j == 0:
			continue  # drawn as axis
		var pt_1 := Vector2(x_limit_l * unit_size, j * unit_size)
		var pt_2 := Vector2(x_limit_h * unit_size, j * unit_size)
		draw_line(pt_1, pt_2, grid_color, thickness, true)


func _draw_ticks() -> void:
	# X-axis ticks: vertical marks along y=0
	for i in range(x_limit_l, x_limit_h + 1, step_size_x):
		if i == 0:
			continue  # origin, skip
		var x := i * unit_size
		draw_line(
			Vector2(x, -tick_size),
			Vector2(x, tick_size),
			tick_color, thickness, true
		)

	# Y-axis ticks: horizontal marks along x=0
	for j in range(y_limit_l, y_limit_h + 1, step_size_y):
		if j == 0:
			continue  # origin, skip
		var y := j * unit_size  # FIX: was -j due to Vector2.UP multiplying
		draw_line(
			Vector2(-tick_size, y),
			Vector2(tick_size, y),
			tick_color, thickness, true
		)


func _draw_axes() -> void:
	# X axis
	draw_line(
		Vector2(x_limit_l * unit_size, 0),
		Vector2(x_limit_h * unit_size, 0),
		axis_color, axis_thickness, true
	)
	# Y axis
	draw_line(
		Vector2(0, y_limit_l * unit_size),
		Vector2(0, y_limit_h * unit_size),
		axis_color, axis_thickness, true
	)

	if show_arrows:
		_draw_arrow(Vector2(x_limit_h * unit_size, 0), Vector2.RIGHT)
		_draw_arrow(Vector2(0, y_limit_l * unit_size), Vector2.UP)


func _draw_arrow(tip: Vector2, direction: Vector2) -> void:
	var perp := Vector2(-direction.y, direction.x)
	var base := tip - direction * arrow_size
	draw_colored_polygon(PackedVector2Array([
		tip,
		base + perp * (arrow_size * 0.5),
		base - perp * (arrow_size * 0.5)
	]), axis_color)


func _draw_labels() -> void:
	var font := ThemeDB.fallback_font

	# X labels along the x-axis
	for i in range(x_limit_l, x_limit_h + 1, step_size_x):
		if i == 0:
			continue
		draw_string(
			font,
			Vector2(i * unit_size, 0) + label_offset,
			"%.1f" % i,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1, label_font_size, axis_color
		)

	# Y labels along the y-axis
	# Negate j for display because Godot's Y axis is flipped
	for j in range(y_limit_l, y_limit_h + 1, step_size_y):
		if j == 0:
			continue
		draw_string(
			font,
			Vector2(0, j * unit_size) + label_offset,
			"%.1f" % (-j),
			HORIZONTAL_ALIGNMENT_CENTER,
			-1, label_font_size, axis_color
		)
