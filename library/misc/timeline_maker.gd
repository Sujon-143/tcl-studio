@tool
class_name TimelineMaker
extends Node2D

## ─────────────────────────────────────────────────────────────────────────────
##  TimelineMaker  —  AnimationPlayer-friendly historical timeline renderer.
##
##  Quick-start:
##    1. Add a TimelineMaker node to your scene.
##    2. Create TimelineEventData resources and push them into [events].
##    3. Slide [progress] from 0 → 1 in the Inspector to preview the animation,
##       or keyframe it in AnimationPlayer.
##
##  Place both .gd files in the same folder.
## ─────────────────────────────────────────────────────────────────────────────

# ── Orientation ───────────────────────────────────────────────────────────────

enum Orientation { HORIZONTAL, VERTICAL }

## Direction the timeline grows.
## Default 0 = HORIZONTAL. Integer literal avoids @tool parse-order issues.
@export var orientation: Orientation = 0:
	set(v): orientation = v; queue_redraw()

## Total pixel length of the drawn line.
@export_range(100.0, 4000.0, 1.0, "suffix:px") var line_length: float = 600.0:
	set(v): line_length = v; queue_redraw()

# ── Animation ─────────────────────────────────────────────────────────────────

@export_group("Animation")

## THE variable to keyframe. 0 = nothing shown, 1 = fully revealed.
@export_range(0.0, 1.0, 0.001) var progress: float = 0.0:
	set(v):
		progress = clampf(v, 0.0, 1.0)
		queue_redraw()

## Fraction of total progress each event's entrance animation spans.
@export_range(0.01, 0.5, 0.005) var event_animation_duration: float = 0.12:
	set(v): event_animation_duration = v; queue_redraw()

## Default entrance style for all events (can be overridden per-event).
@export var event_reveal_style: TimelineEventData.RevealStyle = TimelineEventData.RevealStyle.FADE_IN:
	set(v): event_reveal_style = v; queue_redraw()

## Pixel travel distance for SLIDE_FROM_* styles.
@export_range(5.0, 300.0, 1.0, "suffix:px") var event_slide_distance: float = 40.0:
	set(v): event_slide_distance = v; queue_redraw()

## Optional custom easing curve. Leave empty for built-in smoothstep.
@export var event_easing_curve: Curve:
	set(v): event_easing_curve = v; queue_redraw()

# ── Line ──────────────────────────────────────────────────────────────────────

@export_group("Line")

@export var line_color: Color = Color(0.85, 0.85, 0.85, 1.0):
	set(v): line_color = v; queue_redraw()

@export_range(0.5, 16.0, 0.1, "suffix:px") var line_thickness: float = 3.0:
	set(v): line_thickness = v; queue_redraw()

## Show an arrowhead at the end when progress >= 0.98.
@export var arrow_head: bool = true:
	set(v): arrow_head = v; queue_redraw()

@export_range(4.0, 40.0, 1.0, "suffix:px") var arrow_head_size: float = 14.0:
	set(v): arrow_head_size = v; queue_redraw()

## Animated dot that travels at the line tip while drawing.
@export var show_cursor: bool = true:
	set(v): show_cursor = v; queue_redraw()

# ── Markers ───────────────────────────────────────────────────────────────────

@export_group("Markers")

@export var marker_color: Color = Color.WHITE:
	set(v): marker_color = v; queue_redraw()

@export_range(2.0, 32.0, 0.5, "suffix:px") var marker_radius: float = 7.0:
	set(v): marker_radius = v; queue_redraw()

## Dark halo ring behind each marker for readability.
@export var marker_outline: bool = true:
	set(v): marker_outline = v; queue_redraw()

@export var marker_outline_color: Color = Color(0.1, 0.1, 0.1, 0.85):
	set(v): marker_outline_color = v; queue_redraw()

@export_range(0.0, 10.0, 0.5, "suffix:px") var marker_outline_width: float = 3.0:
	set(v): marker_outline_width = v; queue_redraw()

# ── Typography ────────────────────────────────────────────────────────────────

@export_group("Typography")

## Leave empty to use the project fallback font.
@export var font: Font:
	set(v): font = v; queue_redraw()

@export_range(8, 96, 1, "suffix:px") var label_font_size: int = 18:
	set(v): label_font_size = v; queue_redraw()

@export_range(6, 64, 1, "suffix:px") var date_font_size: int = 13:
	set(v): date_font_size = v; queue_redraw()

@export var label_color: Color = Color.WHITE:
	set(v): label_color = v; queue_redraw()

@export var date_color: Color = Color(0.65, 0.65, 0.65, 1.0):
	set(v): date_color = v; queue_redraw()

## Pixel gap from the line edge to the nearest text.
@export_range(4.0, 200.0, 1.0, "suffix:px") var text_offset: float = 20.0:
	set(v): text_offset = v; queue_redraw()

## Extra gap between label and date when stacked.
@export_range(0.0, 40.0, 1.0, "suffix:px") var label_date_gap: float = 6.0:
	set(v): label_date_gap = v; queue_redraw()

# ── Events data ───────────────────────────────────────────────────────────────

@export_group("Events Data")

@export var events: Array[TimelineEventData] = []:
	set(v):
		for ev in events:
			if ev and ev.changed.is_connected(_on_event_changed):
				ev.changed.disconnect(_on_event_changed)
		events = v
		for ev in events:
			if ev and not ev.changed.is_connected(_on_event_changed):
				ev.changed.connect(_on_event_changed)
		queue_redraw()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	for ev in events:
		if ev and not ev.changed.is_connected(_on_event_changed):
			ev.changed.connect(_on_event_changed)

func _on_event_changed() -> void:
	queue_redraw()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _font() -> Font:
	return font if font else ThemeDB.fallback_font

func _smoothstep(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	if event_easing_curve:
		return event_easing_curve.sample(t)
	return _smoothstep(t)

## Draw a horizontally-centred string where [pos] is the visual vertical centre.
func _draw_text(pos: Vector2, text: String, size: int, color: Color, alpha: float) -> void:
	if text.is_empty() or alpha <= 0.001:
		return
	var f  := _font()
	var c  := Color(color.r, color.g, color.b, color.a * alpha)
	var sw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	# draw_string pos.y is the baseline. Shift down by half ascent to vertically centre.
	var baseline_shift := f.get_ascent(size) * 0.5
	draw_string(f, Vector2(pos.x - sw * 0.5, pos.y + baseline_shift),
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)

# ── Main draw ─────────────────────────────────────────────────────────────────

func _draw() -> void:
	var p := clampf(progress, 0.0, 1.0)

	var start    := Vector2.ZERO
	var full_end := Vector2.ZERO
	match orientation:
		Orientation.HORIZONTAL:
			start    = Vector2(-line_length * 0.5, 0.0)
			full_end = Vector2( line_length * 0.5, 0.0)
		Orientation.VERTICAL:
			start    = Vector2(0.0, -line_length * 0.5)
			full_end = Vector2(0.0,  line_length * 0.5)

	var tip := start.lerp(full_end, p)

	# Main line
	if p > 0.0:
		draw_line(start, tip, line_color, line_thickness, true)

	# Arrowhead
	if arrow_head and p >= 0.98:
		_draw_arrowhead(tip, full_end)

	# Travelling cursor
	if show_cursor and p > 0.001 and p < 0.999:
		draw_circle(tip, line_thickness * 2.0, line_color)

	# Events
	for ev in events:
		if ev:
			_draw_event(ev, start, full_end, p)

# ── Arrowhead ─────────────────────────────────────────────────────────────────

func _draw_arrowhead(tip: Vector2, towards: Vector2) -> void:
	var dir := towards - tip
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT if orientation == Orientation.HORIZONTAL else Vector2.DOWN
	dir = dir.normalized()
	var sz    := arrow_head_size
	var back  := tip - dir * sz
	var left  := back + dir.rotated( 0.42 * PI) * sz * 0.55
	var right := back + dir.rotated(-0.42 * PI) * sz * 0.55
	draw_colored_polygon(PackedVector2Array([tip, left, right]), line_color)

# ── Single event ──────────────────────────────────────────────────────────────

func _draw_event(ev: TimelineEventData, start: Vector2, end: Vector2, gp: float) -> void:
	var pos_frac := clampf(ev.position, 0.0, 1.0)

	# Wait until the line tip has reached this event.
	if gp < pos_frac:
		return

	# Local entrance progress 0→1
	var dur     := maxf(event_animation_duration, 0.001)
	var local_t := clampf((gp - pos_frac) / dur, 0.0, 1.0)
	var ep      := _ease(local_t)

	# Resolve reveal style
	var style: TimelineEventData.RevealStyle = event_reveal_style
	if ev.override_reveal_style != TimelineEventData.RevealStyle.USE_DEFAULT:
		style = ev.override_reveal_style

	# World anchor on the line
	var anchor := start.lerp(end, pos_frac)

	# Colour overrides (alpha == 0 means use global)
	var mk_color  := ev.marker_color_override if ev.marker_color_override.a > 0.0 else marker_color
	var lbl_color := ev.label_color_override   if ev.label_color_override.a   > 0.0 else label_color

	# Which side of the line (+1 default, -1 flipped)
	var side := float(ev.label_side)

	# Unit vector pointing away from the line toward the label area
	var ortho := Vector2.ZERO
	match orientation:
		Orientation.HORIZONTAL: ortho = Vector2(0.0, -1.0) * side  # up by default
		Orientation.VERTICAL:   ortho = Vector2( 1.0,  0.0) * side  # right by default

	# ── Text positions ────────────────────────────────────────────────────────
	# HORIZONTAL: date closest to line, label stacked further out.
	# VERTICAL:   label/date stacked vertically at a lateral offset.
	var label_pos := Vector2.ZERO
	var date_pos  := Vector2.ZERO

	match orientation:
		Orientation.HORIZONTAL:
			# ortho.y is -1 (up) or +1 (down), so multiplying by it moves text away from line
			var date_y  := anchor.y + ortho.y * (text_offset + date_font_size * 0.5)
			var label_y := anchor.y + ortho.y * (text_offset + date_font_size + label_date_gap + label_font_size * 0.5)
			date_pos  = Vector2(anchor.x, date_y)
			label_pos = Vector2(anchor.x, label_y)
		Orientation.VERTICAL:
			var x := anchor.x + ortho.x * text_offset
			label_pos = Vector2(x, anchor.y - (label_date_gap * 0.5 + date_font_size * 0.5))
			date_pos  = Vector2(x, anchor.y + (label_date_gap * 0.5 + label_font_size * 0.5))

	# ── Slide offset ──────────────────────────────────────────────────────────
	var slide := Vector2.ZERO
	match style:
		TimelineEventData.RevealStyle.SLIDE_FROM_BOTTOM:
			slide = Vector2(0.0,  event_slide_distance * (1.0 - ep))
		TimelineEventData.RevealStyle.SLIDE_FROM_TOP:
			slide = Vector2(0.0, -event_slide_distance * (1.0 - ep))
		TimelineEventData.RevealStyle.SLIDE_FROM_LEFT:
			slide = Vector2(-event_slide_distance * (1.0 - ep), 0.0)
		TimelineEventData.RevealStyle.SLIDE_FROM_RIGHT:
			slide = Vector2( event_slide_distance * (1.0 - ep), 0.0)

	label_pos += slide
	date_pos  += slide

	# ── Alpha & scale ─────────────────────────────────────────────────────────
	var alpha      := 1.0
	var draw_scale := 1.0

	match style:
		TimelineEventData.RevealStyle.FADE_IN,           \
		TimelineEventData.RevealStyle.SLIDE_FROM_BOTTOM, \
		TimelineEventData.RevealStyle.SLIDE_FROM_TOP,    \
		TimelineEventData.RevealStyle.SLIDE_FROM_LEFT,   \
		TimelineEventData.RevealStyle.SLIDE_FROM_RIGHT:
			alpha = ep

		TimelineEventData.RevealStyle.SCALE_UP:
			draw_scale = ep
			alpha      = ep

		TimelineEventData.RevealStyle.POP:
			if local_t < 0.55:
				draw_scale = _ease(local_t / 0.55) * 1.25
			else:
				draw_scale = 1.25 - (_ease((local_t - 0.55) / 0.45) * 0.25)
			alpha = minf(ep * 3.0, 1.0)

		TimelineEventData.RevealStyle.TYPEWRITER:
			alpha      = 1.0
			draw_scale = 1.0

	# ── Marker outline ────────────────────────────────────────────────────────
	if marker_outline:
		var r := (marker_radius + marker_outline_width) * draw_scale
		draw_circle(anchor, r, Color(marker_outline_color.r, marker_outline_color.g,
				marker_outline_color.b, marker_outline_color.a * alpha))

	# ── Marker fill ───────────────────────────────────────────────────────────
	if style == TimelineEventData.RevealStyle.SCALE_UP or style == TimelineEventData.RevealStyle.POP:
		draw_set_transform(anchor, 0.0, Vector2(draw_scale, draw_scale))
		draw_circle(Vector2.ZERO, marker_radius,
				Color(mk_color.r, mk_color.g, mk_color.b, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  # reset immediately
	else:
		draw_circle(anchor, marker_radius,
				Color(mk_color.r, mk_color.g, mk_color.b, alpha))

	# ── Icon ──────────────────────────────────────────────────────────────────
	if ev.icon:
		var isz   := ev.icon_size * draw_scale
		var irect := Rect2(anchor - Vector2(isz, isz) * 0.5, Vector2(isz, isz))
		draw_texture_rect(ev.icon, irect, false, Color(1, 1, 1, alpha))

	# ── Label & date ──────────────────────────────────────────────────────────
	if style == TimelineEventData.RevealStyle.TYPEWRITER:
		if not ev.label.is_empty():
			var n := int(local_t * float(ev.label.length()))
			_draw_text(label_pos, ev.label.substr(0, n), label_font_size, lbl_color, 1.0)
		if not ev.date.is_empty():
			var n := int(local_t * float(ev.date.length()))
			_draw_text(date_pos, ev.date.substr(0, n), date_font_size, date_color, 1.0)
	else:
		_draw_text(label_pos, ev.label, label_font_size, lbl_color, alpha)
		_draw_text(date_pos,  ev.date,  date_font_size,  date_color,  alpha)

# ── Editor warnings ───────────────────────────────────────────────────────────

func _get_configuration_warnings() -> PackedStringArray:
	var w := PackedStringArray()
	if events.is_empty():
		w.append("No events assigned. Add TimelineEventData resources in 'Events Data'.")
	for i in events.size():
		if events[i] == null:
			w.append("events[%d] is null." % i)
	return w
