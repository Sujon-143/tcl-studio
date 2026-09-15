@tool
extends DashedLineRS
class_name DashedLineFromPathRS

## A DashedLineRS whose points are driven by an embedded Path3D child.
## Edit the spline handles in the viewport – the line updates live.
## All dash, treadmill, and draw‑progress features are inherited.
##
## The `points` property is overwritten automatically – do not set it manually.

#region Configuration — Path

@export_group("Path")

## How densely the baked curve is sampled. Smaller = smoother but heavier.
@export_range(0.01, 1.0, 0.001) var bake_interval: float = 0.1 :
	set(value):
		bake_interval = max(0.01, value)
		if is_instance_valid(_path):
			_path.curve.bake_interval = bake_interval
			_sync_points_from_curve()

## If true, the Path3D child is visible in the viewport (helpful while editing).
@export var show_path_node: bool = true :
	set(value):
		show_path_node = value
		if is_instance_valid(_path):
			_path.visible = show_path_node

#endregion

#region Private

var _path: Path3D

# Cache of the last known curve fingerprint (for editor polling)
var _last_curve_fingerprint: int = -1

#endregion

#region Static factories

static func get_default_path() -> DashedLineFromPathRS:
	var dl := DashedLineFromPathRS.new()
	return dl

static func get_treadmill_path(speed: float = 1.0) -> DashedLineFromPathRS:
	var dl             := DashedLineFromPathRS.new()
	dl.treadmill        = true
	dl.treadmill_speed  = speed
	return dl

#endregion

#region Lifecycle

func _ready() -> void:
	_ensure_path_child()
	super._ready()   # calls _schedule_draw internally, which we then override with curve data
	_sync_points_from_curve()

func _exit_tree() -> void:
	if is_instance_valid(_path) and _path.curve is Curve3D:
		if _path.curve.changed.is_connected(_on_curve_changed):
			_path.curve.changed.disconnect(_on_curve_changed)
	super._exit_tree()

func _process(delta: float) -> void:
	super._process(delta)

	# In the editor, curve_changed doesn't always fire while dragging handles,
	# so we poll a lightweight fingerprint every frame.
	if Engine.is_editor_hint() and is_instance_valid(_path) and _path.curve is Curve3D:
		var fp := _curve_fingerprint()
		if fp != _last_curve_fingerprint:
			_last_curve_fingerprint = fp
			_sync_points_from_curve()

#endregion

#region Public API

## Returns the Path3D child for direct manipulation.
func get_path_node() -> Path3D:
	return _path

## Returns the embedded Curve3D (shorthand).
func get_curve() -> Curve3D:
	return _path.curve if is_instance_valid(_path) else null

## Replace the curve with new world‑space control points.
func set_curve_points(ctrl_points: Array[Vector3]) -> void:
	if not is_instance_valid(_path) or not _path.curve is Curve3D:
		return
	_path.curve.clear_points()
	for p in ctrl_points:
		_path.curve.add_point(p)
	_sync_points_from_curve()

#endregion

#region Internal

func _ensure_path_child() -> void:
	# Look for an existing Path3D child
	for child in get_children():
		if child is Path3D:
			_path = child as Path3D
			break

	# If not found, create one and add two default points so the line is immediately visible
	if not is_instance_valid(_path):
		_path = Path3D.new()
		_path.name = "Curve"
		_path.curve = Curve3D.new()
		_path.curve.add_point(Vector3.ZERO)
		_path.curve.add_point(Vector3(0, 0, 2))   # default straight line
		add_child(_path)
		if Engine.is_editor_hint():
			_path.owner = get_tree().get_edited_scene_root() if get_tree() else self

	_path.curve.bake_interval = bake_interval
	_path.visible = show_path_node

	if _path.curve is Curve3D:
		if not _path.curve.changed.is_connected(_on_curve_changed):
			_path.curve.changed.connect(_on_curve_changed)

func _sync_points_from_curve() -> void:
	if not is_instance_valid(_path) or not _path.curve is Curve3D:
		return

	var baked := _path.curve.get_baked_points()
	if baked.size() < 2:
		return

	var new_points: Array[Vector3] = []
	new_points.assign(baked)
	points = new_points   # triggers _schedule_draw via inherited setter

func _curve_fingerprint() -> int:
	var baked := _path.curve.get_baked_points()
	var n := baked.size()
	if n == 0:
		return 0

	var first := baked[0]
	var mid   := baked[n / 2]
	var last  := baked[n - 1]

	var h := n
	h = hash_position(h, first)
	h = hash_position(h, mid)
	h = hash_position(h, last)
	return h

# Small inline hash helper to avoid messing with floats
static func hash_position(h: int, pos: Vector3) -> int:
	h = h * 31 + int(pos.x * 1000.0)
	h = h * 31 + int(pos.y * 1000.0)
	h = h * 31 + int(pos.z * 1000.0)
	return h

func _on_curve_changed() -> void:
	_sync_points_from_curve()

#endregion
