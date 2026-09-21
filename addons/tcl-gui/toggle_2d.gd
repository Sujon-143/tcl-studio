@tool
class_name Toggle2D
extends GuiElement2D
## Hand-drawn on/off pill switch with a smoothly sliding knob. Emits/binds
## a bool.

@export_group("Toggle")
@export var toggled_on: bool = false:
	set(v):
		toggled_on = v
		queue_redraw()
@export var show_labels: bool = false
@export var on_label: String = "ON"
@export var off_label: String = "OFF"
## Higher = snappier knob slide; not a duration.
@export_range(1.0, 30.0, 0.5) var slide_speed: float = 16.0

var _knob_t: float = 0.0  ## smoothed 0 (off) .. 1 (on)


func _ready() -> void:
	super._ready()
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(54, 26)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_knob_t = 1.0 if toggled_on else 0.0


func _process(delta: float) -> void:
	super._process(delta)
	var target := 1.0 if toggled_on else 0.0
	var new_t := move_toward(_knob_t, target, delta * slide_speed)
	if not is_equal_approx(new_t, _knob_t):
		_knob_t = new_t
		queue_redraw()


func _draw() -> void:
	var track_color := shade(base_color.lerp(accent_color, _knob_t))
	draw_style_box(make_style(track_color, int(size.y / 2.0)), Rect2(Vector2.ZERO, size))

	if show_labels:
		var margin := size.y * 0.55
		draw_centered_string(Vector2(size.x - margin, size.y / 2.0), on_label, int(size.y * 0.4), Color(1, 1, 1, 0.35 + 0.5 * _knob_t))
		draw_centered_string(Vector2(margin, size.y / 2.0), off_label, int(size.y * 0.4), Color(1, 1, 1, 0.35 + 0.5 * (1.0 - _knob_t)))

	var knob_r := size.y / 2.0 - 2.0
	var knob_r_anim := knob_r * (1.0 + 0.08 * _hover_t + 0.06 * _press_t)
	var knob_x := lerp(size.y / 2.0, size.x - size.y / 2.0, _knob_t)
	var knob_pos := Vector2(knob_x, size.y / 2.0)
	draw_circle(knob_pos, knob_r_anim + 2.0, shadow_color)
	draw_circle(knob_pos, knob_r_anim, Color.WHITE)


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pressing = event.pressed
		if event.pressed:
			toggled_on = not toggled_on
			_emit(toggled_on)
