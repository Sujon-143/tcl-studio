@tool
class_name RangeSlider2D
extends GuiElement2D
## Hand-drawn horizontal slider with two handles selecting a [low, high]
## range. Emits/binds a Vector2(low_value, high_value) — a BindTarget with
## call_as_method = true and a matching two/one-arg method works well here,
## or point it at any property typed Vector2.

@export_group("Range Slider")
@export var track_height: float = 8.0:
	set(v): track_height = v; queue_redraw()
@export var handle_radius: float = 10.0:
	set(v): handle_radius = v; _sync_min_size()
@export var min_value: float = 0.0:
	set(v): min_value = v; queue_redraw()
@export var max_value: float = 1.0:
	set(v): max_value = v; queue_redraw()
## 0 = continuous, otherwise values snap to multiples of step.
@export var step: float = 0.0
## Smallest allowed gap between the two handles, in ratio (0..1) space.
@export_range(0.0, 0.5, 0.01) var min_gap_ratio: float = 0.02

@export_range(0.0, 1.0, 0.001) var low_ratio: float = 0.25:
	set(v):
		low_ratio = clamp(v, 0.0, high_ratio - min_gap_ratio)
		queue_redraw()
@export_range(0.0, 1.0, 0.001) var high_ratio: float = 0.75:
	set(v):
		high_ratio = clamp(v, low_ratio + min_gap_ratio, 1.0)
		queue_redraw()

var _dragging_handle: int = -1  ## -1 none, 0 = low, 1 = high


func _ready() -> void:
	super._ready()
	_sync_min_size()
	mouse_filter = Control.MOUSE_FILTER_STOP


## See Slider2D._sync_min_size() — same fix, same reason.
func _sync_min_size() -> void:
	var h := handle_radius * 2.0 + 24.0
	custom_minimum_size = Vector2(custom_minimum_size.x if custom_minimum_size.x > 0.0 else 200.0, h)
	if size.y < h:
		size = Vector2(size.x, h)
	queue_redraw()


func get_low_value() -> float:
	return lerp(min_value, max_value, low_ratio)


func get_high_value() -> float:
	return lerp(min_value, max_value, high_ratio)


func _draw() -> void:
	var w := size.x
	var y := size.y - handle_radius - 4.0
	draw_style_box(make_style(base_color), Rect2(0, y - track_height / 2.0, w, track_height))

	var lx := low_ratio * w
	var hx := high_ratio * w
	var fill_style := make_style(shade(accent_color), int(track_height / 2.0))
	draw_style_box(fill_style, Rect2(lx, y - track_height / 2.0, hx - lx, track_height))

	for hx_pos in [lx, hx]:
		var r := handle_radius * (1.0 + 0.12 * _hover_t + 0.08 * _press_t)
		draw_circle(Vector2(hx_pos, y), r + 2.0, shadow_color)
		draw_circle(Vector2(hx_pos, y), r, Color.WHITE)
		draw_arc(Vector2(hx_pos, y), r, 0, TAU, 24, shade(accent_color), 3.0, true)

	if show_value:
		var label := format_value(get_low_value()) + " – " + format_value(get_high_value())
		draw_centered_string(Vector2((lx + hx) / 2.0, y - handle_radius - value_font_size), label, value_font_size, value_label_color)


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pressing = event.pressed
		if event.pressed:
			var w := size.x
			var lx := low_ratio * w
			var hx := high_ratio * w
			_dragging_handle = 0 if absf(event.position.x - lx) <= absf(event.position.x - hx) else 1
			_update_from_x(event.position.x)
		else:
			_dragging_handle = -1
	elif event is InputEventMouseMotion and _dragging_handle != -1:
		_update_from_x(event.position.x)


func _update_from_x(x: float) -> void:
	var r := clamp(x / size.x, 0.0, 1.0)
	var v := lerp(min_value, max_value, r)
	if step > 0.0:
		v = round(v / step) * step
		r = inverse_lerp(min_value, max_value, v)
	var changed := false
	if _dragging_handle == 0 and not is_equal_approx(r, low_ratio):
		low_ratio = r
		changed = true
	elif _dragging_handle == 1 and not is_equal_approx(r, high_ratio):
		high_ratio = r
		changed = true
	if changed:
		_emit(Vector2(get_low_value(), get_high_value()))
