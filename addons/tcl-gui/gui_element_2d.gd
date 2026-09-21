@tool
class_name GuiElement2D
extends Control
## Base class for hand-drawn, bindable GUI controls.
## Provides: the bind_to array, a shared StyleBoxFlat-based look (rounded
## corners + soft shadow, cheaply "fancy" instead of flat rects), smoothed
## hover/press animation state subclasses can read in _draw(), and small
## color/format helpers subclasses share.

@export_group("Binding")
## Each entry maps this control's value to one (node, property) pair.
## Add more than one entry to drive several targets from a single control.
@export var bind_to: Array[BindTarget] = []

@export_group("Style")
@export var base_color: Color = Color(0.20, 0.20, 0.24)
@export var accent_color: Color = Color(0.35, 0.65, 1.0)
@export var outline_color: Color = Color(0.05, 0.05, 0.07, 0.8)
@export var outline_width: float = 1.5
@export_range(0, 40, 1) var corner_radius: int = 10:
	set(v): corner_radius = v; queue_redraw()
@export_range(0, 20, 1) var shadow_size: int = 5:
	set(v): shadow_size = v; queue_redraw()
@export var shadow_color: Color = Color(0, 0, 0, 0.35)
## How much brighter the control gets on hover / darker while pressed, 0..1.
@export_range(0.0, 1.0, 0.01) var hover_lighten: float = 0.12
@export_range(0.0, 1.0, 0.01) var press_darken: float = 0.15
## Higher = snappier hover/press transitions; this is not a duration.
@export_range(1.0, 30.0, 0.5) var animation_speed: float = 14.0

@export_group("Value Label")
@export var show_value: bool = true
@export var value_suffix: String = ""
@export_range(0, 6, 1) var value_decimals: int = 2
@export var value_font_size: int = 13
@export var value_label_color: Color = Color(1, 1, 1, 0.92)

## Emitted whenever the control's value changes, in addition to binding.
signal value_changed(value: Variant)

var _hovering: bool = false
var _pressing: bool = false
var _hover_t: float = 0.0  ## smoothed 0..1
var _press_t: float = 0.0  ## smoothed 0..1


func _ready() -> void:
	mouse_entered.connect(func() -> void: _hovering = true)
	mouse_exited.connect(func() -> void: _hovering = false; _pressing = false)
	set_process(true)


func _process(delta: float) -> void:
	var new_hover := move_toward(_hover_t, 1.0 if _hovering else 0.0, delta * animation_speed)
	var new_press := move_toward(_press_t, 1.0 if _pressing else 0.0, delta * animation_speed)
	if not is_equal_approx(new_hover, _hover_t) or not is_equal_approx(new_press, _press_t):
		_hover_t = new_hover
		_press_t = new_press
		queue_redraw()


func _emit(value: Variant) -> void:
	for target in bind_to:
		if target != null:
			target.apply(self, value)
	value_changed.emit(value)


## Builds a rounded, drop-shadowed StyleBoxFlat from the shared style knobs.
func make_style(color: Color, radius_override: int = -1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	var r := corner_radius if radius_override < 0 else radius_override
	sb.set_corner_radius_all(r)
	sb.corner_detail = 8
	sb.shadow_size = shadow_size
	sb.shadow_color = shadow_color
	sb.anti_aliasing = true
	if outline_width > 0.0:
		sb.border_width_left = outline_width
		sb.border_width_right = outline_width
		sb.border_width_top = outline_width
		sb.border_width_bottom = outline_width
		sb.border_color = outline_color
	return sb


## Applies the current hover/press animation to a base color.
func shade(color: Color) -> Color:
	var c := color.lightened(hover_lighten * _hover_t)
	return c.darkened(press_darken * _press_t)


func format_value(v: float) -> String:
	return ("%." + str(value_decimals) + "f") % v + value_suffix


## Draws left-aligned text centered on `center`, using the theme fallback font.
func draw_centered_string(center: Vector2, text: String, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := center - text_size / 2.0
	pos.y += font.get_ascent(font_size)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
