@tool
class_name Stepper2D
extends GuiElement2D
## Hand-drawn number stepper: [-] value [+]. Holding a button repeats the
## step after an initial delay. Emits/binds a float (round it yourself via
## `integer_only` if you need whole numbers).

@export_group("Stepper")
@export var min_value: float = 0.0
@export var max_value: float = 10.0
@export var step: float = 1.0
@export var integer_only: bool = true
@export var value: float = 0.0:
	set(v):
		value = clamp(v, min_value, max_value)
		if integer_only:
			value = round(value)
		queue_redraw()
@export var button_width: float = 36.0
@export var repeat_delay: float = 0.45
@export var repeat_interval: float = 0.09

var _repeat_timer: Timer
var _held_dir: int = 0  ## -1, 0, +1
var _minus_hover: bool = false
var _plus_hover: bool = false


func _ready() -> void:
	super._ready()
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(140, 40)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_repeat_timer = Timer.new()
	_repeat_timer.one_shot = false
	_repeat_timer.wait_time = repeat_interval
	_repeat_timer.timeout.connect(_on_repeat)
	add_child(_repeat_timer)


func _minus_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(button_width, size.y))


func _plus_rect() -> Rect2:
	return Rect2(Vector2(size.x - button_width, 0), Vector2(button_width, size.y))


func _draw() -> void:
	draw_style_box(make_style(base_color), Rect2(Vector2.ZERO, size))

	var minus_color := shade(accent_color) if _minus_hover else base_color.lightened(0.06)
	var plus_color := shade(accent_color) if _plus_hover else base_color.lightened(0.06)
	draw_style_box(make_style(minus_color, corner_radius), _minus_rect())
	draw_style_box(make_style(plus_color, corner_radius), _plus_rect())

	draw_centered_string(_minus_rect().get_center(), "-", value_font_size + 6, Color.WHITE)
	draw_centered_string(_plus_rect().get_center(), "+", value_font_size + 6, Color.WHITE)

	var label := (str(int(value)) if integer_only else format_value(value))
	draw_centered_string(Rect2(Vector2.ZERO, size).get_center(), label, value_font_size + 2, value_label_color)


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseMotion:
		var new_minus := _minus_rect().has_point(event.position)
		var new_plus := _plus_rect().has_point(event.position)
		if new_minus != _minus_hover or new_plus != _plus_hover:
			_minus_hover = new_minus
			_plus_hover = new_plus
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _minus_rect().has_point(event.position):
				_start_hold(-1)
			elif _plus_rect().has_point(event.position):
				_start_hold(1)
		else:
			_stop_hold()


func _start_hold(dir: int) -> void:
	_held_dir = dir
	_pressing = true
	_step(dir)
	_repeat_timer.wait_time = repeat_delay
	_repeat_timer.start()


func _stop_hold() -> void:
	_held_dir = 0
	_pressing = false
	_repeat_timer.stop()


func _on_repeat() -> void:
	if _held_dir == 0:
		return
	_repeat_timer.wait_time = repeat_interval  # first tick used repeat_delay, then speed up
	_step(_held_dir)


func _step(dir: int) -> void:
	var new_value := clamp(value + dir * step, min_value, max_value)
	if not is_equal_approx(new_value, value):
		value = new_value
		_emit(value)
