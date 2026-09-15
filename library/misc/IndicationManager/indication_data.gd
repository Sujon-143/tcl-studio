extends Resource
class_name IndicationData

enum Shape { CIRCLE, RECTANGLE }

@export var indication_shape: Shape = Shape.CIRCLE:
	set(v):
		indication_shape = v
		emit_changed()

@export var indication_position: Vector2 = Vector2.ZERO:
	set(v):
		indication_position = v
		emit_changed()

@export var dashed: bool = false:
	set(v):
		dashed = v
		emit_changed()

@export var dash_length: float = 10.0:
	set(v):
		dash_length = clampf(v, 1.0, 999.0)
		emit_changed()

@export var gap_length: float = 5.0:
	set(v):
		gap_length = clampf(v, 1.0, 999.0)
		emit_changed()

@export var line_width: float = 2.0:
	set(v):
		line_width = clampf(v, 0.5, 50.0)
		emit_changed()

@export_category("Rectangle Settings")
@export var rect_width: float = 100.0:
	set(v):
		rect_width = clampf(v, 0.0, 99999.0)
		emit_changed()

@export var rect_height: float = 100.0:
	set(v):
		rect_height = clampf(v, 0.0, 99999.0)
		emit_changed()

@export var rect_color: Color = Color(1.0, 0.1, 0.5, 0.3):
	set(v):
		rect_color = v
		emit_changed()

@export_category("Circle Settings")
@export var circ_width: float = 100.0:
	set(v):
		circ_width = clampf(v, 0.0, 99999.0)
		emit_changed()

@export var circ_height: float = 100.0:
	set(v):
		circ_height = clampf(v, 0.0, 99999.0)
		emit_changed()

@export var circ_color: Color = Color(1.0, 0.1, 0.5, 0.3):
	set(v):
		circ_color = v
		emit_changed()
