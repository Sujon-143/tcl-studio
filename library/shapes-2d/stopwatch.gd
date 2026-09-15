@tool
extends BaseShape2D
class_name StopwatchShape2D

## Stylized analog stopwatch drawn entirely via _draw().
##
## Design intent: AnimationPlayer is the clock.
## Keyframe [stopwatched_time] from 0 → N ms and the watch plays back
## identically in the editor and at runtime — no separate internal timer needed.
##
## If you want a free-running mode instead, call start() / stop() / reset()
## from your own script; they simply drive stopwatched_time forward each frame.

# ── Editor-exposed properties ─────────────────────────────────────────────────

@export_group("Time")

## Elapsed time in milliseconds. Keyframe THIS in AnimationPlayer.
## Works in editor preview and at runtime identically.
@export_range(0, 3600000, 1, "suffix:ms")
var stopwatched_time: int = 0:
	set(v):
		stopwatched_time = v
		queue_redraw()

## Label drawn on the watch face (brand name, event tag, etc.).
@export var label: String = "STOPWATCH":
	set(v):
		label = v
		queue_redraw()

@export_group("Display")

## Outer radius of the watch face in pixels.
@export_range(30, 300, 1, "suffix:px")
var face_radius: float = 100.0:
	set(v):
		face_radius = v
		queue_redraw()

@export var face_color: Color = Color(0.13, 0.12, 0.11, 1.0):
	set(v): face_color = v; queue_redraw()

@export var bezel_color: Color = Color(0.55, 0.54, 0.52, 1.0):
	set(v): bezel_color = v; queue_redraw()

@export var seconds_hand_color: Color = Color(0.86, 0.35, 0.19, 1.0):
	set(v): seconds_hand_color = v; queue_redraw()

@export var minutes_hand_color: Color = Color(0.90, 0.88, 0.84, 1.0):
	set(v): minutes_hand_color = v; queue_redraw()

@export var tick_color: Color = Color(0.85, 0.83, 0.78, 0.85):
	set(v): tick_color = v; queue_redraw()

@export var readout_color: Color = Color(0.85, 0.83, 0.78, 1.0):
	set(v): readout_color = v; queue_redraw()

# ── Optional free-running mode ────────────────────────────────────────────────
# These are NOT needed when AnimationPlayer drives stopwatched_time.
# Use them only if you want a self-ticking stopwatch from code.

var _free_running: bool = false
var _free_start_tick: int = 0
var _free_base_ms: int = 0

## Start free-running mode (increments stopwatched_time each frame).
func start() -> void:
	if _free_running:
		return
	_free_base_ms = stopwatched_time
	_free_start_tick = Time.get_ticks_msec()
	_free_running = true
	set_process(true)

## Pause free-running mode (stopwatched_time keeps its current value).
func stop() -> void:
	if not _free_running:
		return
	stopwatched_time = _free_base_ms + (Time.get_ticks_msec() - _free_start_tick)
	_free_running = false
	set_process(false)

## Reset stopwatched_time to zero and stop.
func reset() -> void:
	_free_running = false
	set_process(false)
	stopwatched_time = 0  # setter triggers queue_redraw()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	super._ready()
	

func _process(_delta: float) -> void:
	# Only reached in free-running mode.
	#stopwatched_time = _free_base_ms + (Time.get_ticks_msec() - _free_start_tick)
	# setter calls queue_redraw() automatically.
	pass
# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	super._draw()
	# stopwatched_time is the single source of truth — same in editor and runtime.
	var ms: float      = float(stopwatched_time)
	var total_s: float = ms / 1000.0
	var seconds: float = fmod(total_s, 60.0)
	var minutes: int   = int(total_s / 60.0) % 60
	var ms_frac: float = fmod(ms, 1000.0) / 1000.0

	_draw_bezel()
	_draw_face()
	_draw_crown()
	_draw_pushers()
	_draw_tick_marks()
	_draw_sub_dial(minutes)
	_draw_label_text()
	_draw_seconds_hand(seconds, ms_frac)
	_draw_center_cap()
	_draw_digital_readout(ms)

# ── Sub-draw helpers ──────────────────────────────────────────────────────────

func _draw_bezel() -> void:
	draw_circle(Vector2.ZERO, face_radius + 8.0, bezel_color)
	draw_arc(Vector2.ZERO, face_radius + 4.0, 0.0, TAU, 80,
		Color(0, 0, 0, 0.25), 2.0, true)

func _draw_face() -> void:
	draw_circle(Vector2.ZERO, face_radius, face_color)
	for i in 12:
		var a: float = (float(i) / 12.0) * TAU
		var inner := Vector2(cos(a), sin(a)) * (face_radius * 0.45)
		var outer := Vector2(cos(a), sin(a)) * (face_radius * 0.95)
		draw_line(inner, outer, Color(1, 1, 1, 0.015), 0.5)

func _draw_crown() -> void:
	var cx: float = face_radius + 8.0
	draw_rect(Rect2(cx, -5, 10, 10), bezel_color, true)
	draw_rect(Rect2(cx, -5, 10, 10),
		Color(bezel_color.r * 0.7, bezel_color.g * 0.7, bezel_color.b * 0.7, 1.0),
		false, 0.5)

func _draw_pushers() -> void:
	var positions: Array[Vector2] = [
		Vector2(-face_radius * 0.64, -face_radius * 0.72),
		Vector2(-face_radius * 0.64, -face_radius * 0.42),
	]
	for p in positions:
		draw_circle(p, 4.5, bezel_color)
		draw_circle(p, 4.5,
			Color(bezel_color.r * 0.7, bezel_color.g * 0.7, bezel_color.b * 0.7),
			false, 0.5)

func _draw_tick_marks() -> void:
	for i in 60:
		var a: float = (float(i) / 60.0) * TAU - PI * 0.5
		var is_major: bool = (i % 5 == 0)
		var tick_len: float = face_radius * (0.10 if is_major else 0.05)
		var outer_r: float = face_radius * 0.94
		var p1 := Vector2(cos(a), sin(a)) * outer_r
		var p2 := Vector2(cos(a), sin(a)) * (outer_r - tick_len)
		var t_color := tick_color if is_major \
			else Color(tick_color.r, tick_color.g, tick_color.b, tick_color.a * 0.45)
		draw_line(p1, p2, t_color, 1.5 if is_major else 0.8, true)

		if i % 15 == 0:
			var numeral: String = "60" if i == 0 else str(i)
			var font: Font = ThemeDB.fallback_font
			var font_size: int = maxi(8, int(face_radius * 0.13))
			var text_r: float = face_radius * 0.76
			var tp := Vector2(cos(a), sin(a)) * text_r - Vector2(font_size * 0.6, -font_size * 0.35)
			draw_string(font, tp, numeral, HORIZONTAL_ALIGNMENT_LEFT, -1,
				font_size, tick_color)

func _draw_sub_dial(minutes: int) -> void:
	var sub_r: float = face_radius * 0.22
	var sub_center := Vector2(0.0, -face_radius * 0.50)

	draw_circle(sub_center, sub_r,
		Color(face_color.r + 0.07, face_color.g + 0.07, face_color.b + 0.07, 1.0))
	draw_arc(sub_center, sub_r, 0.0, TAU, 40,
		Color(tick_color.r, tick_color.g, tick_color.b, 0.35), 0.5, true)

	for i in 30:
		var a: float = (float(i) / 30.0) * TAU - PI * 0.5
		var is_maj: bool = (i % 5 == 0)
		var t_len: float = sub_r * (0.22 if is_maj else 0.12)
		var p1 := sub_center + Vector2(cos(a), sin(a)) * sub_r * 0.92
		var p2 := sub_center + Vector2(cos(a), sin(a)) * (sub_r * 0.92 - t_len)
		draw_line(p1, p2,
			Color(tick_color.r, tick_color.g, tick_color.b, 0.5 if is_maj else 0.25),
			0.8, true)

	var min_angle: float = (float(minutes) / 30.0) * TAU - PI * 0.5
	var hand_tip := sub_center + Vector2(cos(min_angle), sin(min_angle)) * sub_r * 0.70
	draw_line(sub_center, hand_tip, minutes_hand_color, 1.2, true)
	draw_circle(sub_center, 2.0, minutes_hand_color)

func _draw_label_text() -> void:
	if label.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = maxi(7, int(face_radius * 0.10))
	draw_string(font,
		Vector2(-face_radius * 0.5, -face_radius * 0.18),
		label, HORIZONTAL_ALIGNMENT_CENTER, face_radius, font_size,
		Color(tick_color.r, tick_color.g, tick_color.b, 0.55))

func _draw_seconds_hand(seconds: float, ms_frac: float) -> void:
	var smooth_s: float = seconds + ms_frac
	var angle: float = (smooth_s / 60.0) * TAU - PI * 0.5
	var dir := Vector2(cos(angle), sin(angle))
	draw_line(Vector2.ZERO, -dir * face_radius * 0.25,
		Color(seconds_hand_color.r, seconds_hand_color.g, seconds_hand_color.b, 0.7),
		2.5, true)
	draw_line(Vector2.ZERO, dir * face_radius * 0.88, seconds_hand_color, 1.5, true)

func _draw_center_cap() -> void:
	draw_circle(Vector2.ZERO, 5.0, bezel_color)
	draw_circle(Vector2.ZERO, 2.5, seconds_hand_color)

func _draw_digital_readout(ms: float) -> void:
	var total_s: int = int(ms / 1000.0)
	var mm: int      = total_s / 60
	var ss: int      = total_s % 60
	var cs: int      = int(fmod(ms, 1000.0)) / 10
	var font: Font   = ThemeDB.fallback_font
	var font_size: int = maxi(9, int(face_radius * 0.14))
	draw_string(font,
		Vector2(-face_radius * 0.5, face_radius * 0.32),
		"%02d:%02d.%02d" % [mm, ss, cs],
		HORIZONTAL_ALIGNMENT_CENTER, face_radius, font_size,
		readout_color)
