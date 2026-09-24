@tool
class_name CircularSlider2D
extends GuiElement2D
## Hand-drawn radial/dial slider. Sweeps from start_angle_deg to
## end_angle_deg (0deg = +X, clockwise). Draws a soft-glowing filled arc,
## optional tick marks, a beveled knob, and a centered value readout.

@export_group("Circular Slider")
@export var radius: float = 52.0:
	set(v): radius = v; _sync_min_size()
@export var track_width: float = 9.0:
	set(v): track_width = v; _sync_min_size()
@export_range(-360.0, 360.0, 0.5) var start_angle_deg: float = -135.0:
	set(v): start_angle_deg = v; queue_redraw()
@export_range(-360.0, 360.0, 0.5) var end_angle_deg: float = 135.0:
	set(v): end_angle_deg = v; queue_redraw()
@export var min_value: float = 0.0
@export var max_value: float = 1.0
## 0 = continuous, otherwise value snaps to multiples of step.
@export var step: float = 0.0
@export var show_ticks: bool = true
@export_range(2, 24, 1) var tick_count: int = 9
@export var label_text: String = ""  ## small caption drawn under the value, e.g. "FREQ"

@export_range(0.0, 1.0, 0.001) var ratio: float = 0.0:
	set(v):
		ratio = clamp(v, 0.0, 1.0)
		queue_redraw()

var _dragging: bool = false


func _ready() -> void:
	super._ready()
	_sync_min_size()
	mouse_filter = Control.MOUSE_FILTER_STOP


## Keeps the control's actual rect (not just its minimum-size hint) big
## enough for radius + track_width, in both directions. Without this, the
## drawn arc/knob and mouse input past the old size go out of sync as soon
## as radius grows beyond whatever size the control had at _ready() time —
## input outside a Control's own rect is never delivered to it, so dragging
## silently stops working past that point even though it still draws.
func _sync_min_size() -> void:
	var d := (radius + track_width) * 2.0
	custom_minimum_size = Vector2(d, d)
	if size.x < d or size.y < d:
		size = Vector2(maxf(size.x, d), maxf(size.y, d))
	queue_redraw()


func get_value() -> float:
	return lerp(min_value, max_value, ratio)


func set_value(v: float) -> void:
	ratio = inverse_lerp(min_value, max_value, v)


func _center() -> Vector2:
	return size / 2.0


func _draw() -> void:
	var c := _center()
	var a0 := deg_to_rad(start_angle_deg)
	var a1 := deg_to_rad(end_angle_deg)

	if show_ticks:
		for i in tick_count:
			var t := float(i) / float(tick_count - 1)
			var ang := lerp(a0, a1, t)
			var p0 := c + Vector2(cos(ang), sin(ang)) * (radius + track_width * 0.7)
			var p1 := c + Vector2(cos(ang), sin(ang)) * (radius + track_width * 1.3)
			draw_line(p0, p1, outline_color, 1.5)

	# Base track.
	draw_arc(c, radius, a0, a1, 48, base_color, track_width, true)
	# Soft glow behind the filled arc, then the crisp fill on top.
	var current_angle := lerp(a0, a1, ratio)
	var glow := shade(accent_color)
	glow.a = 0.35
	draw_arc(c, radius, a0, current_angle, 48, glow, track_width * 1.8, true)
	draw_arc(c, radius, a0, current_angle, 48, shade(accent_color), track_width, true)

	var knob_r := track_width * 0.95 * (1.0 + 0.1 * _hover_t + 0.06 * _press_t)
	var handle_pos := c + Vector2(cos(current_angle), sin(current_angle)) * radius
	draw_circle(handle_pos, knob_r + 2.0, shadow_color)
	draw_circle(handle_pos, knob_r, Color.WHITE)
	draw_arc(handle_pos, knob_r, 0, TAU, 20, shade(accent_color), 2.5, true)

	if show_value:
		var value_pos := c
		if label_text != "":
			value_pos.y -= value_font_size * 0.5
		draw_centered_string(value_pos, format_value(get_value()), value_font_size + 2, value_label_color)
		if label_text != "":
			draw_centered_string(c + Vector2(0, value_font_size), label_text, value_font_size - 3, value_label_color * Color(1, 1, 1, 0.7))


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_pressing = event.pressed
		if event.pressed:
			_update_from_point(event.position)
	elif event is InputEventMouseMotion and _dragging:
		_update_from_point(event.position)


func _update_from_point(p: Vector2) -> void:
	var c := _center()
	var angle := (p - c).angle()
	var a0 := deg_to_rad(start_angle_deg)
	var a1 := deg_to_rad(end_angle_deg)
	var span := a1 - a0
	if is_zero_approx(span):
		return
	var rel := wrapf(angle - a0, 0.0, TAU)
	if span < 0.0:
		rel -= TAU
	var r := clamp(rel / span, 0.0, 1.0)
	var v := lerp(min_value, max_value, r)
	if step > 0.0:
		v = round(v / step) * step
		r = inverse_lerp(min_value, max_value, v)
	if not is_equal_approx(r, ratio):
		ratio = r
		_emit(get_value())
