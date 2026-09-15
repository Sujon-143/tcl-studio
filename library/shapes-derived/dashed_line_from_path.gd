@tool
extends DashedLine
class_name DashedLineFromPath

## A DashedLine whose points are driven by an embedded Path3D child.
## Edit the spline handles in the editor viewport and the line updates live.
## All dash, treadmill, and draw-progress features from DashedLine are inherited.
##
## NOTE: The inherited `points` property is overwritten every time the curve
## changes — do not set it manually when using this class.

#region Configuration — Path

@export_group("Path")

## How densely the baked curve is sampled. Smaller = smoother, more vertices.
@export_range(0.01, 1.0, 0.001) var bake_interval: float = 0.1 :
	set(value):
		bake_interval = max(0.01, value)
		if _ready_done:
			_apply_bake_interval()
			_sync_points_from_curve()

## If true the Path3D node is visible in the viewport (helpful while editing).
@export var show_path_node: bool = true :
	set(value):
		show_path_node = value
		if _ready_done and is_instance_valid(_path):
			_path.visible = show_path_node

#endregion

#region Private

var _path: Path3D = null

# Tracks the last curve fingerprint we synced so we only rebuild when needed.
# Computed by _curve_fingerprint() since PackedVector3Array has no .hash() in 4.6.
var _last_curve_version: int = -1

#endregion

#region Static factories

static func get_default_path() -> DashedLineFromPath:
	return DashedLineFromPath.new()

static func get_treadmill_path(speed: float = 1.0) -> DashedLineFromPath:
	var dl             := DashedLineFromPath.new()
	dl.treadmill        = true
	dl.treadmill_speed  = speed
	return dl

#endregion

#region Lifecycle

func _setup() -> void:
	# Let DashedLine build its mesh instances and set _ready_done.
	super._setup()

	_ensure_path_child()
	_apply_bake_interval()
	_sync_points_from_curve()




func _process(delta: float) -> void:
	# Let DashedLine handle treadmill scrolling.
	super._process(delta)

	# In @tool mode curve_changed doesn't fire reliably during handle drags,
	# so we poll the curve each frame as a lightweight fallback.
	if Engine.is_editor_hint() and is_instance_valid(_path) and _path.curve is Curve3D:
		var h := _curve_fingerprint()
		if h != _last_curve_version:
			_last_curve_version = h
			_sync_points_from_curve()

#endregion

#region Public API

## Replaces the embedded curve with new control points (world-space).
## Existing curve data is cleared.
func set_curve_points(ctrl_points: Array[Vector3]) -> void:
	if not is_instance_valid(_path) or not _path.curve is Curve3D:
		return
	_path.curve.clear_points()
	for p in ctrl_points:
		_path.curve.add_point(p)
	_sync_points_from_curve()

## Returns the Path3D child so callers can manipulate the curve directly.
func get_path_node() -> Path3D:
	return _path

#endregion

#region Path management

func _ensure_path_child() -> void:
	# Re-use an existing Path3D child if the scene was saved with one.
	for child in get_children():
		if child is Path3D:
			_path = child
			break

	if not is_instance_valid(_path):
		_path       = Path3D.new()
		_path.name  = "Curve"
		_path.curve = Curve3D.new()
		add_child(_path)
		# Setting owner makes the node appear in the editor scene tree and
		# persists it when the scene is saved.
		if Engine.is_editor_hint():
			_path.owner = get_tree().get_edited_scene_root() if get_tree() else self

	_path.visible = show_path_node

	# Connect the curve-changed signal (guard against double-connect).
	if _path.curve is Curve3D:
		if not _path.curve.changed.is_connected(_on_curve_changed):
			_path.curve.changed.connect(_on_curve_changed)

func _apply_bake_interval() -> void:
	if is_instance_valid(_path) and _path.curve is Curve3D:
		_path.curve.bake_interval = bake_interval

func _sync_points_from_curve() -> void:
	if not is_instance_valid(_path) or not _path.curve is Curve3D:
		return

	var baked := _path.curve.get_baked_points()  # PackedVector3Array
	if baked.size() < 2:
		return

	# Convert to Array[Vector3] expected by DashedLine.points.
	var new_points: Array[Vector3] = []
	new_points.assign(baked)
	points = new_points

## Cheap change detector for the baked curve.
## Samples point count + first, middle, and last baked positions into one int.
## PackedVector3Array has no .hash() in Godot 4.6, so we build one manually.
func _curve_fingerprint() -> int:
	var baked := _path.curve.get_baked_points()
	var n     := baked.size()
	if n == 0:
		return 0
	var first := baked[0]
	var mid   := baked[n / 2]
	var last  := baked[n - 1]
	# Polynomial rolling hash over the sampled coordinates (scaled to ints).
	var h: int = n
	h = h * 31 + int(first.x * 1000.0)
	h = h * 31 + int(first.y * 1000.0)
	h = h * 31 + int(first.z * 1000.0)
	h = h * 31 + int(mid.x   * 1000.0)
	h = h * 31 + int(mid.y   * 1000.0)
	h = h * 31 + int(mid.z   * 1000.0)
	h = h * 31 + int(last.x  * 1000.0)
	h = h * 31 + int(last.y  * 1000.0)
	h = h * 31 + int(last.z  * 1000.0)
	return h

func _on_curve_changed() -> void:
	_sync_points_from_curve()

#endregion
