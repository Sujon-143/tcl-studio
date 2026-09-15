@tool
class_name Table
extends BaseShape2D

@export var row_first: bool = true:
	set(value):
		row_first = value
		queue_redraw()

@export var rows: int = 3:
	set(value):
		rows = value
		queue_redraw()
	get:
		return rows

@export var cols: int = 3:
	set(value):
		cols = value
		 
		queue_redraw()
	get:
		return cols

@export var cell_size: Vector2 = Vector2(100, 50):
	set(value):
		cell_size = value
		 
		queue_redraw()

@export var line_color: Color = Color.WHITE:
	set(value):
		line_color = value
		queue_redraw()

@export var line_width: float = 1.0:
	set(value):
		line_width = value
		queue_redraw()


func _draw() -> void:
	super._draw()
	var table_width  := cols * cell_size.x
	var table_height := rows * cell_size.y

	# Horizontal lines
	for r in range(rows + 1):
		var y := r * cell_size.y
		draw_line(Vector2(0, y), Vector2(table_width, y), line_color, line_width)

	# Vertical lines
	for c in range(cols + 1):
		var x := c * cell_size.x
		draw_line(Vector2(x, 0), Vector2(x, table_height), line_color, line_width)
