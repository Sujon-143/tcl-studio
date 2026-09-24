@tool
class_name Slider2D
extends GuiElement2D
## Hand-drawn horizontal slider. Emits/binds a float in [min_value, max_value].
## Draws a rounded, shadowed track + fill, a beveled handle that grows on
## hover/press, and (optionally) the current value as floating text.

@export_group("Slider")
@export var track_height: float = 8.0:
	set(v): track_height = v; queue_redraw()
@export var handle_radius: float = 11.0:
	set(v): handle_radius = v; _sync_min_size()
@export var min_value: float = 0.0:
	set(v): min_value = v; queue_redraw()
@export var max_value: float = 1.0:
	set(v): max_value = v; queue_redraw()
## 0 = continuous, otherwise value snaps to multiples of step.
@export var step: float = 0.0

@export_range(0.0, 1.0, 0.001) var ratio: float = 0.5:
	set(v):
		ratio = clamp(v, 0.0, 1.0)
		queue_redraw()

var _dragging: bool = false


func _ready() -> void:
	super._ready()
	_sync_min_size()
	mouse_filter = Control.MOUSE_FILTER_STOP


## Keeps the control's actual height (not just its minimum-size hint) tall
## enough for the handle + value label. Without this, growing handle_radius
## after _ready() leaves the handle drawn (and draggable) partly outside the
## control's own rect, and input outside a Control's rect never reaches it.
func _sync_min_size() -> void:
	var h := handle_radius * 2.0 + 24.0
	custom_minimum_size = Vector2(custom_minimum_size.x if custom_minimum_size.x > 0.0 else 180.0, h)
	if size.y < h:
		size = Vector2(size.x, h)
	queue_redraw()


func get_value() -> float:
	return lerp(min_value, max_value, ratio)


func set_value(v: float) -> void:
	ratio = inverse_lerp(min_value, max_value, v)


func _draw() -> void:
	var w := size.x
	var y := size.y - handle_radius - 4.0
	var track_rect := Rect2(0, y - track_height / 2.0, w, track_height)

	draw_style_box(make_style(base_color), track_rect)

	var fill_w := maxf(ratio * w, track_height)  # keep a fully round cap when near zero
	var fill_rect := Rect2(0, y - track_height / 2.0, fill_w, track_height)
	var fill_style := make_style(shade(accent_color), int(track_height / 2.0))
	# Square off the right edge of the fill so it reads as a "progress" bar
	# rather than a floating rounded pill once it's not covering the track.
	if ratio < 0.999:
		fill_style.corner_radius_top_right = 0
		fill_style.corner_radius_bottom_right = 0
	draw_style_box(fill_style, fill_rect)

	var handle_x := ratio * w
	var r := handle_radius * (1.0 + 0.12 * _hover_t + 0.08 * _press_t)
	draw_circle(Vector2(handle_x, y), r + 2.0, shadow_color)
	draw_circle(Vector2(handle_x, y), r, Color.WHITE)
	draw_circle(Vector2(handle_x, y), r, shade(accent_color).darkened(0.05), false, 0.0)
	draw_arc(Vector2(handle_x, y), r, 0, TAU, 24, shade(accent_color), 3.0, true)

	if show_value:
		draw_centered_string(Vector2(handle_x, y - r - value_font_size), format_value(get_value()), value_font_size, value_label_color)


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_pressing = event.pressed
		if event.pressed:
			_update_from_x(event.position.x)
	elif event is InputEventMouseMotion and _dragging:
		_update_from_x(event.position.x)


func _update_from_x(x: float) -> void:
	var r := clamp(x / size.x, 0.0, 1.0)
	var v := lerp(min_value, max_value, r)
	if step > 0.0:
		v = round(v / step) * step
		r = inverse_lerp(min_value, max_value, v)
	if not is_equal_approx(r, ratio):
		ratio = r
		_emit(get_value())
