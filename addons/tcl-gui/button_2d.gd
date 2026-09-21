@tool
class_name Button2D
extends GuiElement2D
## Hand-drawn press button. On press it applies `true` to every bind target
## (set call_as_method = true on the BindTarget to trigger a method/event
## instead of setting a boolean property).

@export_group("Button")
@export var label_text: String = "Button":
	set(v): label_text = v; queue_redraw()
@export var font_size: int = 16:
	set(v): font_size = v; queue_redraw()
@export var font_color: Color = Color.WHITE
## How many pixels the button visually "sinks" while pressed.
@export_range(0.0, 8.0, 0.5) var press_inset: float = 3.0

var _pressed: bool = false


func _ready() -> void:
	super._ready()
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(110, 40)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var inset := press_inset * _press_t
	var rect := Rect2(Vector2(0, inset), size - Vector2(0, inset))
	var color := shade(base_color)
	if _pressed:
		color = shade(accent_color)
	draw_style_box(make_style(color), rect)

	if label_text != "":
		draw_centered_string(rect.get_center(), label_text, font_size, font_color)


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pressed = event.pressed
		_pressing = event.pressed
		if event.pressed:
			_emit(true)
