@tool
class_name LEDMatrix
extends BaseShape2D

# --------------------------------------------------------------------------- #
# Editor‑exposed properties
# --------------------------------------------------------------------------- #
@export var rows: int = 8:
	set(value):
		rows = max(1, value)
		queue_redraw()

@export var columns: int = 8:
	set(value):
		columns = max(1, value)
		queue_redraw()

@export var led_radius: float = 5.0:
	set(value):
		led_radius = max(0.0, value)
		queue_redraw()

# Horizontal and vertical distance between the centres of adjacent LEDs
@export var separation: Vector2 = Vector2(15.0, 15.0):
	set(value):
		separation = value
		queue_redraw()

# Text rendered on top of the background rectangle
@export var background_rectangle_title: String = "LED Matrix":
	set(value):
		background_rectangle_title = value
		queue_redraw()
@export var background_rectangle_title_font_size:int=20:
	set(v):
		background_rectangle_title_font_size=v
		queue_redraw()

@export var turn_on_color: Color = Color.RED:
	set(value):
		turn_on_color = value
		queue_redraw()

@export var turn_off_color: Color = Color.DARK_GRAY:
	set(value):
		turn_off_color = value
		queue_redraw()

# List of LED indices (column, row) that should be lit
@export var on_indices: PackedVector2Array = []:
	set(value):
		on_indices = value
		queue_redraw()

# --------------------------------------------------------------------------- #
# Lifecycle
# --------------------------------------------------------------------------- #
func _ready() -> void:
	super._ready()
	# Initial draw (redundant with setter but safe)
	queue_redraw()

# --------------------------------------------------------------------------- #
# Drawing
# --------------------------------------------------------------------------- #
func _draw() -> void:
	# No LEDs → nothing to draw
	if rows <= 0 or columns <= 0:
		return

	# --- Compute total size of the LED array (centre‑to‑centre) ---
	var total_width: float = (columns - 1) * separation.x + led_radius * 2.0
	var total_height: float = (rows - 1) * separation.y + led_radius * 2.0

	# Add some padding so LEDs don't touch the rectangle edge
	const PADDING: float = 8.0
	const TEXT_HEIGHT: float = 20.0   # room for the title

	# Background rectangle size
	var bg_size := Vector2(
		max(total_width + PADDING * 2.0, 10.0),
		max(total_height + PADDING * 2.0 + TEXT_HEIGHT, 10.0)
	)

	# Position the background rect so that the LED grid is centred inside it,
	# with the title area above.
	var bg_rect := Rect2(
		-bg_size.x / 2.0,
		-bg_size.y / 2.0,
		bg_size.x,
		bg_size.y
	)

	# Draw background
	draw_rect(bg_rect, Color(0.1, 0.1, 0.1, 0.8), true)
	draw_rect(bg_rect, Color.WHITE, false, 1.0)

	# Draw title text if it isn't empty
	if not background_rectangle_title.is_empty():
		# Use the default project font (fallback)
		var font := ThemeDB.fallback_font
		var text_size := font.get_string_size(background_rectangle_title,
				HORIZONTAL_ALIGNMENT_CENTER, -1, background_rectangle_title_font_size)
		# Centre the title horizontally; place it near the top of the background
		draw_string(
			font,
			Vector2(-text_size.x / 2.0, bg_rect.position.y + 18.0),
			background_rectangle_title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			background_rectangle_title_font_size,
			Color.WHITE
		)

	# Offset to place the first LED (top‑left) after padding + title
	var grid_offset := Vector2(
		-bg_rect.size.x / 2.0 + PADDING + led_radius,
		-bg_rect.size.y / 2.0 + PADDING + TEXT_HEIGHT + led_radius
	)

	# Convert on_indices to a faster lookup set: "col,row" -> true
	var lit_set: Dictionary = {}
	for idx in on_indices:
		lit_set["%d,%d" % [idx.x, idx.y]] = true

	# Draw all LEDs
	for row in range(rows):
		for col in range(columns):
			var center := grid_offset + Vector2(col * separation.x, row * separation.y)
			var color := turn_off_color
			if lit_set.has("%d,%d" % [col, row]):
				color = turn_on_color
			draw_circle(center, led_radius, color)
