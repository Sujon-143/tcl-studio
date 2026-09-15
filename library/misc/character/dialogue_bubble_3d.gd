@tool
class_name DialogBubble3D
extends BaseNode3D

## A 3D dialog bubble that floats above a character.
## Place as a child of the character, position at the head, and animate
## the exported properties using an AnimationPlayer.

# -----------------------------------------------
# Exported properties (animated via AnimationPlayer)
# -----------------------------------------------

@export var text: String = "Hello!":
	set(value):
		text = value
		_update_bubble()

## Overall size of the bubble interior (without border / tail)
@export var bubble_size: Vector2 = Vector2(200, 80):
	set(value):
		bubble_size = value
		_update_bubble()

## Radius of the bubble corners
@export var corner_radius: float = 15.0:
	set(value):
		corner_radius = value
		_update_bubble()

## Height of the tail pointing downwards
@export var tail_height: float = 20.0:
	set(value):
		tail_height = value
		_update_bubble()

## Width of the tail base
@export var tail_width: float = 20.0:
	set(value):
		tail_width = value
		_update_bubble()

## Horizontal offset of the tail tip from the bubble center (in pixels)
@export var tail_offset: float = 0.0:
	set(value):
		tail_offset = value
		_update_bubble()

## Background color of the bubble
@export var background_color: Color = Color.WHITE:
	set(value):
		background_color = value
		_update_bubble()

## Border color (set border_width > 0 to see it)
@export var border_color: Color = Color.BLACK:
	set(value):
		border_color = value
		_update_bubble()

## Width of the border in pixels (0 = no border)
@export var border_width: float = 2.0:
	set(value):
		border_width = value
		_update_bubble()

## Color of the displayed text
@export var text_color: Color = Color.BLACK:
	set(value):
		text_color = value
		_update_bubble()

## Font size (pixels)
@export var font_size: int = 16:
	set(value):
		font_size = value
		_update_bubble()

## Custom font (leave empty for default)
@export var font: Font:
	set(value):
		font = value
		_update_bubble()

## Padding between the text and the bubble edge (horizontal, vertical)
@export var text_padding: Vector2 = Vector2(10, 5):
	set(value):
		text_padding = value
		_update_bubble()

## Scale: number of pixels per 3D unit (default 100 px = 1 unit)
@export var pixels_per_unit: float = 100.0:
	set(value):
		pixels_per_unit = value
		_update_bubble()

# -----------------------------------------------
# Internal state
# -----------------------------------------------

var _sprite: Sprite3D
var _label: Label3D
var _texture: ImageTexture
var _setup_done := false

# -----------------------------------------------
# Lifecycle
# -----------------------------------------------

func _ready() -> void:
	if not _setup_done:
		_setup_children()
		_update_bubble()
		_setup_done = true

func _enter_tree() -> void:
	if not _setup_done and is_inside_tree():
		_setup_children()
		_update_bubble()
		_setup_done = true

func _setup_children() -> void:
	# Create Sprite3D for the bubble graphic
	if not has_node("BubbleSprite"):
		_sprite = Sprite3D.new()
		_sprite.name = "BubbleSprite"
		add_child(_sprite, false, INTERNAL_MODE_BACK)
		_sprite.owner = self if is_inside_tree() and owner else null
	else:
		_sprite = get_node("BubbleSprite") as Sprite3D

	# Create Label3D for the text
	if not has_node("BubbleLabel"):
		_label = Label3D.new()
		_label.name = "BubbleLabel"
		add_child(_label, false, INTERNAL_MODE_FRONT)
		_label.owner = self if is_inside_tree() and owner else null
	else:
		_label = get_node("BubbleLabel") as Label3D

# -----------------------------------------------
# Bubble image generation
# -----------------------------------------------

func _update_bubble() -> void:
	if not _sprite or not _label:
		return

	_texture = null

	var px_unit := 1.0 / pixels_per_unit

	# --- Image dimensions ---
	var full_width  := int(bubble_size.x + border_width * 2)
	var body_height := int(bubble_size.y + border_width * 2)
	var img_height  := int(body_height + tail_height)

	# tail_center_x: horizontal pixel position of the tail tip inside the image
	var tail_center_x := full_width / 2.0 + tail_offset

	# --- Build image ---
	var img := Image.create(full_width, img_height, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Draw bubble body (border + fill)
	if border_width > 0:
		_fill_rounded_rect(img, Rect2(0, 0, full_width, body_height),
				border_color, corner_radius)
		_fill_rounded_rect(img,
				Rect2(border_width, border_width, bubble_size.x, bubble_size.y),
				background_color, max(0.0, corner_radius - border_width))
	else:
		_fill_rounded_rect(img, Rect2(0, 0, full_width, body_height),
				background_color, corner_radius)

	# Draw tail triangle
	var tail_points := PackedVector2Array([
		Vector2(tail_center_x - tail_width / 2.0, body_height),
		Vector2(tail_center_x + tail_width / 2.0, body_height),
		Vector2(tail_center_x, body_height + tail_height),
	])
	_draw_triangle(img, tail_points, background_color)

	if border_width > 0:
		_draw_polygon_outline(img, tail_points, border_color)

	# --- Apply texture to Sprite3D ---
	_texture = ImageTexture.create_from_image(img)
	_sprite.texture  = _texture
	_sprite.pixel_size = px_unit
	_sprite.centered = false          # anchor = top-left of image
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	# In Godot 4, Sprite3D with centered=false maps:
	#   image pixel (px, py)  →  world offset Vector3(px, -py, 0) * pixel_size
	# (image Y-down  =  world -Y)
	#
	# We want the TAIL TIP (image pixel: tail_center_x, img_height) to sit at
	# local origin (0, 0, 0), so:
	#   sprite.position + Vector3(tail_center_x, -img_height, 0) * px_unit = (0,0,0)
	#   sprite.position = Vector3(-tail_center_x, img_height, 0) * px_unit   ← +Y !
	var tip_x := tail_center_x * px_unit
	var tip_y := float(img_height) * px_unit
	_sprite.position = Vector3(-tip_x, tip_y, 0.0)   # FIX: was -tip_y

	# --- Position Label3D at the bubble body centre ---
	# Body centre in image pixels: (full_width/2, body_height/2)
	# In world coords (relative to our local origin = tail tip):
	#   x = (full_width/2 - tail_center_x) * px_unit  =  -tail_offset * px_unit
	#   y = (img_height - body_height/2)   * px_unit  =  (tail_height + body_height/2) * px_unit
	var body_center_x := -tail_offset * px_unit
	var body_center_y := (tail_height + body_height / 2.0) * px_unit  # FIX: was negated
	_label.position = Vector3(body_center_x, body_center_y, 0.01)  # tiny Z to avoid z-fighting

	# Label settings
	_label.text       = text
	_label.modulate   = text_color
	_label.font_size  = font_size
	_label.font       = font if font else null
	_label.pixel_size = px_unit
	_label.width      = (bubble_size.x - text_padding.x * 2.0) * px_unit
	_label.height     = (bubble_size.y - text_padding.y * 2.0) * px_unit
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_label.billboard  = BaseMaterial3D.BILLBOARD_ENABLED


# -----------------------------------------------
# Helper drawing functions
# -----------------------------------------------

static func _fill_rounded_rect(image: Image, rect: Rect2, color: Color, radius: float) -> void:
	if radius <= 0.0:
		image.fill_rect(rect, color)
		return

	var rx := int(rect.position.x)
	var ry := int(rect.position.y)
	var rw := int(rect.size.x)
	var rh := int(rect.size.y)
	var ri := int(radius)

	# Horizontal bar (full width, radius inset top/bottom)
	image.fill_rect(Rect2(rx, ry + ri, rw, rh - 2 * ri), color)
	# Top bar
	image.fill_rect(Rect2(rx + ri, ry, rw - 2 * ri, ri), color)
	# Bottom bar
	image.fill_rect(Rect2(rx + ri, ry + rh - ri, rw - 2 * ri, ri), color)

	# FIX: fill_circle signature in Godot 4 is (x: int, y: int, radius: int, color: Color)
	image.fill_circle(rx + ri,          ry + ri,          ri, color)  # top-left
	image.fill_circle(rx + rw - ri - 1, ry + ri,          ri, color)  # top-right
	image.fill_circle(rx + ri,          ry + rh - ri - 1, ri, color)  # bottom-left
	image.fill_circle(rx + rw - ri - 1, ry + rh - ri - 1, ri, color)  # bottom-right


static func _draw_triangle(image: Image, points: PackedVector2Array, color: Color) -> void:
	var pts := Array(points)
	pts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)

	var y_min := int(max(0, pts[0].y))
	var y_max := int(min(image.get_height() - 1, pts[2].y))

	for y in range(y_min, y_max + 1):
		var x_intersections: Array[float] = []
		for i in range(3):
			var j  := (i + 1) % 3
			var p0 : Vector2 = pts[i]
			var p1 : Vector2 = pts[j]
			if (p0.y <= y and p1.y > y) or (p1.y <= y and p0.y > y):
				var t := (y - p0.y) / (p1.y - p0.y)
				x_intersections.append(p0.x + t * (p1.x - p0.x))
		if x_intersections.size() >= 2:
			x_intersections.sort()
			var x_start := int(max(0, x_intersections[0]))
			var x_end   := int(min(image.get_width() - 1, x_intersections[-1]))
			for x in range(x_start, x_end + 1):
				image.set_pixel(x, y, color)


static func _draw_polygon_outline(image: Image, points: PackedVector2Array, color: Color) -> void:
	var n := points.size()
	for i in range(n):
		_bresenham_line(image, points[i], points[(i + 1) % n], color)


static func _bresenham_line(image: Image, p1: Vector2, p2: Vector2, color: Color) -> void:
	var x1 := int(p1.x);  var y1 := int(p1.y)
	var x2 := int(p2.x);  var y2 := int(p2.y)
	var dx :=  absi(x2 - x1)
	var dy := -absi(y2 - y1)
	var sx := 1 if x1 < x2 else -1
	var sy := 1 if y1 < y2 else -1
	var err := dx + dy

	while true:
		if x1 >= 0 and x1 < image.get_width() and y1 >= 0 and y1 < image.get_height():
			image.set_pixel(x1, y1, color)
		if x1 == x2 and y1 == y2:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy;  x1 += sx
		if e2 <= dx:
			err += dx;  y1 += sy
