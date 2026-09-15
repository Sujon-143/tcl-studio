@tool
extends BaseShape2D
class_name LineFromPath

var path: Path2D = null
var _dash_offset: float = 0.0

@export_range(1, 100, 0.1) var stroke_width: float = 10:
	set(value): stroke_width = value; queue_redraw()
	get: return stroke_width

@export var color: Color = Color.WHITE:
	set(value): color = value; queue_redraw()
	get: return color

@export var filled: bool = false:
	set(value): filled = value; queue_redraw()
	get: return filled

@export var antialiased: bool = false:
	set(value): antialiased = value; queue_redraw()
	get: return antialiased

@export_range(0.0, 1.0, 0.01) var progress: float = 1.0:
	set(value): progress = value; queue_redraw()
	get: return progress

# --- Dash options ---
@export var dashed: bool = false:
	set(value): dashed = value; queue_redraw()
	get: return dashed

@export_range(1.0, 200.0, 1.0) var dash_length: float = 20.0:
	set(value): dash_length = value; queue_redraw()
	get: return dash_length

@export_range(1.0, 200.0, 1.0) var gap_length: float = 10.0:
	set(value): gap_length = value; queue_redraw()
	get: return gap_length

# --- Treadmill / panning ---
@export var treadmill_enabled: bool = false:
	set(value): treadmill_enabled = value
	get: return treadmill_enabled

@export_range(0.0, 500.0, 1.0) var treadmill_speed: float = 40.0:
	set(value): treadmill_speed = value
	get: return treadmill_speed

@export var treadmill_reverse: bool = false:
	set(value): treadmill_reverse = value
	get: return treadmill_reverse

func _ready() -> void:
	super._ready()
	create_path()

func _process(delta: float) -> void:
	if treadmill_enabled and dashed:
		var dir := -1.0 if treadmill_reverse else 1.0
		_dash_offset += treadmill_speed * delta * dir
		var period := dash_length + gap_length
		_dash_offset = fmod(_dash_offset, period)
		if _dash_offset < 0.0:
			_dash_offset += period  # keep positive after reversal
		queue_redraw()


func _draw() -> void:
	super._draw()
	if path == null or path.curve == null:
		return

	var points := path.curve.get_baked_points()
	if points.size() < 2:
		return

	# --- Apply progress: slice the baked points array ---
	var target_count := maxi(2, int(ceil(points.size() * progress)))
	points = points.slice(0, target_count)

	if not dashed:
		# Solid line / polygon
		if filled:
			draw_polygon(points, [color])
		else:
			draw_polyline(points, color, stroke_width, antialiased)
		return

	# --- Dashed drawing ---
	# Walk along the polyline segment by segment, emitting dash segments.
	var dash_cycle := dash_length + gap_length
	# Current distance into the current dash/gap cycle, shifted by the treadmill offset
	var dist_in_cycle := fmod(_dash_offset, dash_cycle)
	var in_dash := dist_in_cycle < dash_length

	var seg_start := points[0]
	var dash_seg_start := seg_start  # where the current dash began (if in_dash)

	for i in range(1, points.size()):
		var seg_end := points[i]
		var seg_len := seg_start.distance_to(seg_end)
		if seg_len == 0.0:
			seg_start = seg_end
			continue

		var seg_dir := (seg_end - seg_start) / seg_len
		var walked := 0.0

		while walked < seg_len:
			var remaining_in_cycle: float
			if in_dash:
				remaining_in_cycle = dash_length - dist_in_cycle
			else:
				remaining_in_cycle = dash_cycle - dist_in_cycle

			var step := minf(remaining_in_cycle, seg_len - walked)
			var pos := seg_start + seg_dir * (walked + step)

			if in_dash:
				# End of a dash segment → draw it
				draw_line(dash_seg_start, pos, color, stroke_width, antialiased)

			walked += step
			dist_in_cycle += step

			if dist_in_cycle >= (dash_length if in_dash else dash_cycle):
				dist_in_cycle = fmod(dist_in_cycle, dash_cycle)
				if in_dash:
					in_dash = false
				else:
					in_dash = true
					dist_in_cycle = 0.0
					dash_seg_start = pos

			if in_dash and step == remaining_in_cycle:
				dash_seg_start = pos

		seg_start = seg_end

	# Draw final open dash if we ended mid-dash
	if in_dash:
		draw_line(dash_seg_start, points[-1], color, stroke_width, antialiased)


func create_path() -> void:
	position = Vector2(1920, 1080) / 2.0
	path = Path2D.new()
	path.curve = Curve2D.new()
	path.name = "Curve"
	add_child(path)
	if Engine.is_editor_hint():
		path.set_owner(get_tree().edited_scene_root)
	# Connect so any curve edit triggers a redraw
	path.curve.changed.connect(queue_redraw)


func _exit_tree() -> void:
	if path:
		remove_child(path)
		path.queue_free()
		path = null
