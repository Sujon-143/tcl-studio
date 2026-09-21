@tool
class_name LevelMeter2D
extends GuiElement2D
## The opposite direction of the other controls: instead of a user driving
## a value that gets written OUT to other nodes, this reads a value IN from
## a source node's property every frame and displays it as a vertical bar
## — e.g. point it at an AudioStreamPlayer's volume, a sensor's last
## reading, a health value, anything with a numeric property.
##
## It still has bind_to (inherited), so it can also forward the value it
## reads onward to drive something else — a live passthrough/relay.
## If the "GUI Elements Property Picker" editor plugin is enabled,
## source_property renders as a dropdown of source_node's real properties,
## same as BindTarget.target_property does.

@export_group("Source")
## The node to read from. Resolved relative to this meter, same as
## BindTarget.target_node is resolved relative to the control that owns it.
@export var source_node: NodePath = NodePath("")
## The property on source_node to poll. See the note above about the
## editor picker.
@export var source_property: StringName = &""
@export var min_value: float = 0.0
@export var max_value: float = 1.0
## Smooths the displayed value so fast-changing sources (like live audio)
## don't flicker. 1 = instant, lower = smoother/slower to respond.
@export_range(0.05, 1.0, 0.01) var smoothing: float = 0.35
@export var show_peak_hold: bool = true
@export var peak_hold_seconds: float = 1.2

var _display_ratio: float = 0.0
var _peak_ratio: float = 0.0
var _peak_timer: float = 0.0
var _resolved: Node = null


func _ready() -> void:
	super._ready()
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(28, 140)


func _process(delta: float) -> void:
	super._process(delta)
	if source_node.is_empty() or source_property == &"":
		return
	if _resolved == null:
		_resolved = get_node_or_null(source_node)
		if _resolved == null:
			return

	var raw: Variant = _resolved.get(source_property)
	if typeof(raw) != TYPE_FLOAT and typeof(raw) != TYPE_INT:
		return
	var target_ratio := clamp(inverse_lerp(min_value, max_value, float(raw)), 0.0, 1.0)
	_display_ratio = lerp(_display_ratio, target_ratio, smoothing)

	if _display_ratio >= _peak_ratio:
		_peak_ratio = _display_ratio
		_peak_timer = peak_hold_seconds
	elif _peak_timer > 0.0:
		_peak_timer -= delta
	else:
		_peak_ratio = maxf(_peak_ratio - delta * 0.6, _display_ratio)

	_emit(lerp(min_value, max_value, _display_ratio))
	queue_redraw()


func _draw() -> void:
	draw_style_box(make_style(base_color), Rect2(Vector2.ZERO, size))

	var fill_h := _display_ratio * size.y
	var fill_rect := Rect2(0, size.y - fill_h, size.x, fill_h)
	draw_style_box(make_style(accent_color, corner_radius), fill_rect)

	if show_peak_hold:
		var peak_y := size.y - _peak_ratio * size.y
		draw_line(Vector2(0, peak_y), Vector2(size.x, peak_y), Color.WHITE, 2.0)

	if show_value:
		draw_centered_string(Vector2(size.x / 2.0, 12), format_value(lerp(min_value, max_value, _display_ratio)), value_font_size, value_label_color)
