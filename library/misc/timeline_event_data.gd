@tool
class_name TimelineEventData
extends Resource

## Sentinel value for override_reveal_style — means "use the TimelineMaker global default".
## All other values actively override it.
enum RevealStyle {
	USE_DEFAULT,        ## Follow TimelineMaker.event_reveal_style
	FADE_IN,
	SCALE_UP,
	SLIDE_FROM_BOTTOM,
	SLIDE_FROM_TOP,
	SLIDE_FROM_LEFT,
	SLIDE_FROM_RIGHT,
	POP,
	TYPEWRITER,
}

## Short name shown near the marker.
@export var label: String = "Event":
	set(v): label = v; emit_changed()

## Date or sub-label drawn below / beside the marker.
@export var date: String = "2025":
	set(v): date = v; emit_changed()

## Normalised position along the timeline (0 = start, 1 = end).
@export_range(0.0, 1.0, 0.001) var position: float = 0.5:
	set(v): position = v; emit_changed()

## Optional icon rendered next to the marker.
@export var icon: Texture2D:
	set(v): icon = v; emit_changed()

## Icon display size in pixels (square). Only used when icon is set.
@export_range(8.0, 128.0, 1.0, "suffix:px") var icon_size: float = 32.0:
	set(v): icon_size = v; emit_changed()

## Leave as USE_DEFAULT to follow the global reveal style on TimelineMaker.
@export var override_reveal_style: RevealStyle = RevealStyle.USE_DEFAULT:
	set(v): override_reveal_style = v; emit_changed()

## Per-event label colour override. Leave alpha = 0 to use the global colour.
@export var label_color_override: Color = Color(1, 1, 1, 0):
	set(v): label_color_override = v; emit_changed()

## Per-event marker colour override. Leave alpha = 0 to use the global colour.
@export var marker_color_override: Color = Color(1, 1, 1, 0):
	set(v): marker_color_override = v; emit_changed()

## Which side of the timeline to draw label/date on (+1 = default, -1 = opposite).
@export_enum("Default:1", "Flip:-1") var label_side: int = 1:
	set(v): label_side = v; emit_changed()
