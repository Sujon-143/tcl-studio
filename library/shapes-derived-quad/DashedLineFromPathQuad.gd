@tool
extends DashedLineQuad
class_name DashedLineFromPathQuad

## DashedLineFromPath re-implemented on top of DashedLineQuad.
## Identical logic — only the base class changes. All Path3D curve editing,
## bake_interval, show_path_node, and treadmill features are preserved.

#region Configuration — Path

@export_group("Path")

@export_range(0.01, 1.0, 0.001) var bake_interval: float = 0.1 :
	set(value):
		bake_interval = max(0.01, value)
		if _ready_done:
			_apply_bake_interval()
			_sync_points_from_curve()

@export var show_path_node: bool = true :
	set(value):
		show_path_node = value
		if _ready_done and is_instance_valid(_path):
			_path.visible = show_path_node

#endregion

#region Private

var _path: Path3D = null
var _last_curve_version: int = -1

#endregion

#region Static factories

static func get_default_path() -> DashedLineFromPathQuad:
	return DashedLineFromPathQuad.new()

static func get_treadmill_path(speed: float = 1.0) -> DashedLineFromPathQuad:
	var dl            := DashedLineFromPathQuad.new()
	dl.treadmill       = true
	dl.treadmill_speed = speed
	return dl

#endregion

#region Lifecycle

func _ready() -> void:
	super._ready()
	_ensure_path_child()
	_apply_bake_interval()
	_sync_points_from_curve()

func _exit_tree() -> void:
	if is_instance_valid(_path) and _path.curve is Curve3D:
		if _path.curve.changed.is_connected(_on_curve_changed):
			_path.curve.changed.disconnect(_on_curve_changed)
	super._exit_tree()

func _process(delta: float) -> void:
	super._process(delta)
	if Engine.is_editor_hint() and is_instance_valid(_path) and _path.curve is Curve3D:
		var h := _curve_fingerprint()
		if h != _last_curve_version:
			_last_curve_version = h
			_sync_points_from_curve()

#endregion

#region Public API

func set_curve_points(ctrl_points: Array[Vector3]) -> void:
	if not is_instance_valid(_path) or not _path.curve is Curve3D:
		return
	_path.curve.clear_points()
	for p in ctrl_points:
		_path.curve.add_point(p)
	_sync_points_from_curve()

func get_path_node() -> Path3D:
	return _path

#endregion

#region Path management

func _ensure_path_child() -> void:
	for child in get_children():
		if child is Path3D:
			_path = child
			break

	if not is_instance_valid(_path):
		_path       = Path3D.new()
		_path.name  = "Curve"
		_path.curve = Curve3D.new()
		add_child(_path)
		if Engine.is_editor_hint():
			_path.owner = get_tree().get_edited_scene_root() if get_tree() else self

	_path.visible = show_path_node

	if _path.curve is Curve3D:
		if not _path.curve.changed.is_connected(_on_curve_changed):
			_path.curve.changed.connect(_on_curve_changed)

func _apply_bake_interval() -> void:
	if is_instance_valid(_path) and _path.curve is Curve3D:
		_path.curve.bake_interval = bake_interval

func _sync_points_from_curve() -> void:
	if not is_instance_valid(_path) or not _path.curve is Curve3D:
		return
	var baked := _path.curve.get_baked_points()
	if baked.size() < 2:
		return
	var new_points: Array[Vector3] = []
	new_points.assign(baked)
	points = new_points

func _curve_fingerprint() -> int:
	var baked := _path.curve.get_baked_points()
	var n     := baked.size()
	if n == 0:
		return 0
	var first := baked[0]
	var mid   := baked[n / 2]
	var last  := baked[n - 1]
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
