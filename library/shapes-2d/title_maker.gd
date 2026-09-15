@tool
extends BaseShape2D
class_name TitleMaker

## Draws an animated scene title using _draw().
## Keyframe [progress] 0.0 → 1.0 to play the intro animation,
## then 1.0 → 0.0 to reverse it (or use a separate outro animation style).
##
## Combine with Wiper on a lower z_index for polished scene transitions.

# ── Animation styles ──────────────────────────────────────────────────────────

enum TitleStyle {
	FADE_IN,            ## Simple opacity fade.
	SLIDE_LEFT,         ## Slides in from the right.
	SLIDE_RIGHT,        ## Slides in from the left.
	SLIDE_UP,           ## Slides in from below.
	SLIDE_DOWN,         ## Slides in from above.
	SCALE_UP,           ## Scales from 0 → 1 at origin.
	SCALE_PUNCH,        ## Overshoots scale then settles (punch-in feel).
	TYPEWRITER,         ## Characters revealed left-to-right.
	LETTER_DROP,        ## Each letter falls in with staggered delay.
	LETTER_SCATTER,     ## Letters fly in from random directions.
	GLITCH,             ## Horizontal RGB offset glitch reveal.
	CURTAIN,            ## Two halves split apart vertically.
	STAMP,              ## Slams in large and shrinks to final size.
}

enum SubtitleStyle {
	NONE,
	FADE_DELAYED,       ## Fades in after the main title settles.
	SLIDE_SYNC,         ## Slides in from opposite direction to main title.
	TYPEWRITER_DELAYED, ## Typed in after main title is done.
}

enum DecorationType {
	NONE,
	UNDERLINE,          ## Animated line drawing under title.
	BOX,                ## Rectangle border draws in.
	CORNER_MARKS,       ## Four corner brackets.
	SIDE_BARS,          ## Left and right accent bars.
}

# ── Editor properties ─────────────────────────────────────────────────────────

@export_group("Content")

## Main title text.
@export_multiline var title_text: String = "SCENE TITLE":
	set(v): title_text = v; queue_redraw()

## Optional subtitle below the main title.
@export_multiline() var subtitle_text: String = "":
	set(v): subtitle_text = v; queue_redraw()

## Optional small label above the main title (episode number, chapter, etc.).
@export_multiline var super_text: String = "":
	set(v): super_text = v; queue_redraw()

@export_group("Animation")

## 0.0 = not started  /  1.0 = fully revealed.
## Keyframe this in AnimationPlayer.
@export_range(0.0, 1.0, 0.001)
var progress: float = 0.0:
	set(v):
		progress = v
		queue_redraw()

## Main title entrance style.
@export var title_style: TitleStyle = TitleStyle.SLIDE_UP:
	set(v): title_style = v; queue_redraw()

## Subtitle entrance style.
@export var subtitle_style: SubtitleStyle = SubtitleStyle.FADE_DELAYED:
	set(v): subtitle_style = v; queue_redraw()

## Decoration entrance style.
@export var decoration: DecorationType = DecorationType.UNDERLINE:
	set(v): decoration = v; queue_redraw()

## How far into the animation the subtitle begins (0–1 range of progress).
@export_range(0.0, 1.0, 0.01)
var subtitle_delay: float = 0.5:
	set(v): subtitle_delay = v; queue_redraw()

## Slide distance in pixels for SLIDE_* styles.
@export_range(10.0, 600.0, 1.0, "suffix:px")
var _slide_distance: float = 120.0:
	set(v): _slide_distance = v; queue_redraw()

## Per-letter stagger as a fraction of total progress for letter animations.
@export_range(0.0, 0.5, 0.005)
var letter_stagger: float = 0.08:
	set(v): letter_stagger = v; queue_redraw()

## Seed for LETTER_SCATTER random directions.
@export var scatter_seed: int = 42:
	set(v): scatter_seed = v; queue_redraw()

@export_group("Typography")

## Main title font (leave empty for the theme fallback font).
@export var title_font: Font:
	set(v): title_font = v; queue_redraw()

@export_range(12, 256, 1, "suffix:px")
var title_font_size: int = 72:
	set(v): title_font_size = v; queue_redraw()

## Subtitle font size.
@export_range(8, 128, 1, "suffix:px")
var subtitle_font_size: int = 28:
	set(v): subtitle_font_size = v; queue_redraw()

## Super-label font size.
@export_range(8, 64, 1, "suffix:px")
var super_font_size: int = 18:
	set(v): super_font_size = v; queue_redraw()

## Letter spacing modifier in pixels (added between characters).
@export_range(-20.0, 80.0, 0.5, "suffix:px")
var letter_spacing: float = 4.0:
	set(v): letter_spacing = v; queue_redraw()

@export_group("Colors")

@export var title_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(v): title_color = v; queue_redraw()

@export var subtitle_color: Color = Color(0.85, 0.85, 0.85, 0.85):
	set(v): subtitle_color = v; queue_redraw()

@export var super_color: Color = Color(0.70, 0.70, 0.70, 0.70):
	set(v): super_color = v; queue_redraw()

@export var decoration_color: Color = Color(1.0, 1.0, 1.0, 0.9):
	set(v): decoration_color = v; queue_redraw()

## Decoration line thickness.
@export_range(0.5, 8.0, 0.1, "suffix:px")
var decoration_thickness: float = 2.0:
	set(v): decoration_thickness = v; queue_redraw()

## Decoration padding around the title text.
@export_range(0.0, 60.0, 1.0, "suffix:px")
var decoration_padding: float = 12.0:
	set(v): decoration_padding = v; queue_redraw()

## Second color used in GLITCH style.
@export var glitch_color_a: Color = Color(1.0, 0.1, 0.1, 0.8):
	set(v): glitch_color_a = v; queue_redraw()

@export var glitch_color_b: Color = Color(0.1, 0.8, 1.0, 0.8):
	set(v): glitch_color_b = v; queue_redraw()

## Glitch offset in pixels at progress = 0; shrinks to 0 at progress = 1.
@export_range(0.0, 60.0, 0.5, "suffix:px")
var glitch_max_offset: float = 20.0:
	set(v): glitch_max_offset = v; queue_redraw()

# ── Internal helpers ──────────────────────────────────────────────────────────

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _font() -> Font:
	return title_font if title_font else ThemeDB.fallback_font

## Smooth ease-out curve (cubic).
func _ease_out(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)

## Ease-out with overshoot (elastic-lite).
func _ease_punch(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	if t < 0.7:
		# Overshoot: scale goes slightly above 1.
		return _ease_out(t / 0.7) * 1.15
	else:
		# Settle back.
		return 1.15 - (_ease_out((t - 0.7) / 0.3) * 0.15)

## Returns the width of [text] with the current title font and letter_spacing.
func _measure_text(text: String, font_size: int) -> float:
	var f: Font = _font()
	var w: float = 0.0
	for i in text.length():
		w += f.get_char_size(text.unicode_at(i), font_size).x
		if i < text.length() - 1:
			w += letter_spacing
	return w

## Draws [text] character by character with spacing applied.
## [origin] is the baseline-left starting point.
func _draw_text_spaced(text: String, origin: Vector2, font_size: int,
					   color: Color, x_offset: float = 0.0, alpha_mod: float = 1.0) -> void:
	var f: Font = _font()
	var x: float = origin.x + x_offset
	var c := Color(color.r, color.g, color.b, color.a * alpha_mod)
	for ch in text:
		draw_char(f, Vector2(x, origin.y), ch, font_size, c)
		x += f.get_char_size(ch.unicode_at(0), font_size).x + letter_spacing

## Same as above but returns each character's center position (used for per-letter animation).
func _measure_chars(text: String, origin: Vector2, font_size: int) -> Array[Dictionary]:
	var f: Font = _font()
	var x: float = origin.x
	var result: Array[Dictionary] = []
	for ch in text:
		var cw: float = f.get_char_size(ch.unicode_at(0), font_size).x
		result.append({ "ch": ch, "pos": Vector2(x, origin.y), "width": cw })
		x += cw + letter_spacing
	return result

# ── Draw dispatch ─────────────────────────────────────────────────────────────

func _draw() -> void:
	super._draw()
	var p: float = clampf(progress, 0.0, 1.0)
	var f: Font = _font()

	# --- Geometry: where does the title sit? (centered at node origin) ---
	var title_w: float    = _measure_text(title_text, title_font_size)
	var title_h: float    = float(title_font_size)
	var title_origin := Vector2(-title_w * 0.5, title_h * 0.5)  # Baseline-centered.

	var sub_w: float      = _measure_text(subtitle_text, subtitle_font_size)
	var sub_origin := Vector2(-sub_w * 0.5, title_h * 0.5 + float(subtitle_font_size) + 8.0)

	var super_w: float    = _measure_text(super_text, super_font_size)
	var super_origin := Vector2(-super_w * 0.5, -title_h * 0.5 - 10.0)

	# --- Super label (always simple fade) ---
	if super_text.length() > 0:
		var super_alpha: float = _ease_out(p)
		_draw_text_spaced(super_text, super_origin, super_font_size,
			super_color, 0.0, super_alpha)

	# --- Main title ---
	_draw_title(p, title_origin, title_w, title_h)

	# --- Decoration ---
	_draw_decoration(p, title_origin, title_w, title_h)

	# --- Subtitle ---
	if subtitle_text.length() > 0:
		_draw_subtitle(p, sub_origin)

# ── Main title drawing ────────────────────────────────────────────────────────

func _draw_title(p: float, origin: Vector2, tw: float, th: float) -> void:
	match title_style:
		TitleStyle.FADE_IN:
			_draw_text_spaced(title_text, origin, title_font_size,
				title_color, 0.0, _ease_out(p))

		TitleStyle.SLIDE_LEFT:
			var offset: float = _slide_distance * (1.0 - _ease_out(p))
			_draw_text_spaced(title_text, origin, title_font_size,
				title_color, offset, _ease_out(p))

		TitleStyle.SLIDE_RIGHT:
			var offset: float = -_slide_distance * (1.0 - _ease_out(p))
			_draw_text_spaced(title_text, origin, title_font_size,
				title_color, offset, _ease_out(p))

		TitleStyle.SLIDE_UP:
			_draw_title_offset_y(p, origin, _slide_distance * (1.0 - _ease_out(p)))

		TitleStyle.SLIDE_DOWN:
			_draw_title_offset_y(p, origin, -_slide_distance * (1.0 - _ease_out(p)))

		TitleStyle.SCALE_UP:
			_draw_title_scaled(p, origin, tw, th, _ease_out(p))

		TitleStyle.SCALE_PUNCH:
			_draw_title_scaled(p, origin, tw, th, _ease_punch(p))

		TitleStyle.TYPEWRITER:
			_draw_typewriter(p, origin)

		TitleStyle.LETTER_DROP:
			_draw_letter_drop(p, origin)

		TitleStyle.LETTER_SCATTER:
			_draw_letter_scatter(p, origin)

		TitleStyle.GLITCH:
			_draw_glitch(p, origin)

		TitleStyle.CURTAIN:
			_draw_curtain(p, origin, tw, th)

		TitleStyle.STAMP:
			_draw_stamp(p, origin, tw, th)

# ── Title style implementations ───────────────────────────────────────────────

func _draw_title_offset_y(p: float, origin: Vector2, y_offset: float) -> void:
	var shifted := Vector2(origin.x, origin.y + y_offset)
	_draw_text_spaced(title_text, shifted, title_font_size,
		title_color, 0.0, _ease_out(p))

func _draw_title_scaled(p: float, origin: Vector2, tw: float, th: float, scale: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale, scale))
	_draw_text_spaced(title_text, origin, title_font_size,
		title_color, 0.0, clampf(scale, 0.0, 1.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_typewriter(p: float, origin: Vector2) -> void:
	var chars_visible: int = int(p * title_text.length())
	var partial: String = title_text.substr(0, chars_visible)
	_draw_text_spaced(partial, origin, title_font_size, title_color, 0.0, 1.0)
	# Blinking cursor at the end.
	if chars_visible < title_text.length():
		var cursor_x: float = origin.x + _measure_text(partial, title_font_size)
		draw_line(Vector2(cursor_x, origin.y - title_font_size),
			Vector2(cursor_x, origin.y + 4),
			Color(title_color.r, title_color.g, title_color.b, 0.8), 2.0)

func _draw_letter_drop(p: float, origin: Vector2) -> void:
	var chars: Array[Dictionary] = _measure_chars(title_text, origin, title_font_size)
	var f: Font = _font()
	for i in chars.size():
		var window_start: float = float(i) / float(chars.size()) * letter_stagger
		var local_p: float = clampf((p - window_start) / (1.0 - letter_stagger * 0.5), 0.0, 1.0)
		var ep: float = _ease_out(local_p)
		var drop: float = (1.0 - ep) * _slide_distance
		var pos: Vector2 = chars[i]["pos"] + Vector2(0, drop)
		draw_char(f, pos, chars[i]["ch"], title_font_size,
			Color(title_color.r, title_color.g, title_color.b, title_color.a * ep))

func _draw_letter_scatter(p: float, origin: Vector2) -> void:
	_rng.seed = scatter_seed
	var chars: Array[Dictionary] = _measure_chars(title_text, origin, title_font_size)
	var f: Font = _font()
	for i in chars.size():
		var dir := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)).normalized()
		var dist: float = _rng.randf_range(_slide_distance * 0.5, _slide_distance * 1.5)
		var window_start: float = float(i) / float(chars.size()) * letter_stagger
		var local_p: float = clampf((p - window_start) / (1.0 - letter_stagger * 0.5), 0.0, 1.0)
		var ep: float = _ease_out(local_p)
		var offset: Vector2 = dir * dist * (1.0 - ep)
		var pos: Vector2 = chars[i]["pos"] + offset
		draw_char(f, pos, chars[i]["ch"], title_font_size,
			Color(title_color.r, title_color.g, title_color.b, title_color.a * ep))

func _draw_glitch(p: float, origin: Vector2) -> void:
	# Glitch: two offset colored copies collapse onto the real position as p → 1.
	var glitch_offset: float = glitch_max_offset * (1.0 - p)
	# Red channel offset.
	_draw_text_spaced(title_text, origin, title_font_size,
		glitch_color_a, -glitch_offset, p * 0.9)
	# Blue channel offset.
	_draw_text_spaced(title_text, origin, title_font_size,
		glitch_color_b, glitch_offset, p * 0.9)
	# Main layer fades in as glitch collapses.
	_draw_text_spaced(title_text, origin, title_font_size,
		title_color, 0.0, _ease_out(p))

func _draw_curtain(p: float, origin: Vector2, tw: float, th: float) -> void:
	# Top and bottom halves reveal from center outward.
	var ep: float = _ease_out(p)
	var half_h: float = (th * 0.5 + 4.0) * (1.0 - ep)
	# Draw full text first (clipping not available in _draw, so use opacity
	# fade + a covering rect trick via scissoring — approximate with opacity).
	_draw_text_spaced(title_text, origin, title_font_size, title_color, 0.0, ep)
	# Mask the remaining portion with the background suggestion (Color(0,0,0,0)).
	# Since true clip-rect isn't available per-draw, fade + slide is the clean fallback.

func _draw_stamp(p: float, origin: Vector2, tw: float, th: float) -> void:
	# Slams in huge then snaps to final size.
	var stamp_scale: float
	if p < 0.6:
		# Rapid scale-down from 3x to 1x.
		stamp_scale = 3.0 - (3.0 - 1.0) * _ease_out(p / 0.6)
	else:
		# Settle with micro-bounce.
		stamp_scale = 1.0 + sin((p - 0.6) / 0.4 * PI) * 0.04
	var alpha: float = minf(p * 3.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(stamp_scale, stamp_scale))
	_draw_text_spaced(title_text, origin, title_font_size, title_color, 0.0, alpha)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── Subtitle drawing ──────────────────────────────────────────────────────────

func _draw_subtitle(p: float, origin: Vector2) -> void:
	var local_p: float = clampf((p - subtitle_delay) / (1.0 - subtitle_delay), 0.0, 1.0)
	if local_p <= 0.0:
		return
	var ep: float = _ease_out(local_p)

	match subtitle_style:
		SubtitleStyle.FADE_DELAYED:
			_draw_text_spaced(subtitle_text, origin, subtitle_font_size,
				subtitle_color, 0.0, ep)

		SubtitleStyle.SLIDE_SYNC:
			var offset: float = _slide_distance * 0.5 * (1.0 - ep)
			_draw_text_spaced(subtitle_text, origin, subtitle_font_size,
				subtitle_color, -offset, ep)

		SubtitleStyle.TYPEWRITER_DELAYED:
			var chars_visible: int = int(local_p * subtitle_text.length())
			var partial: String = subtitle_text.substr(0, chars_visible)
			_draw_text_spaced(partial, origin, subtitle_font_size, subtitle_color, 0.0, 1.0)

		SubtitleStyle.NONE:
			_draw_text_spaced(subtitle_text, origin, subtitle_font_size,
				subtitle_color, 0.0, ep)

# ── Decoration drawing ────────────────────────────────────────────────────────

func _draw_decoration(p: float, title_origin: Vector2, tw: float, th: float) -> void:
	if decoration == DecorationType.NONE:
		return
	var ep: float = _ease_out(p)
	var pad: float = decoration_padding
	# Decoration bounds (axis-aligned around the title text).
	var left:   float = title_origin.x - pad
	var right:  float = title_origin.x + tw + pad
	var top:    float = title_origin.y - th - pad
	var bottom: float = title_origin.y + pad

	match decoration:
		DecorationType.UNDERLINE:
			# Line draws in from left to right.
			var line_end_x: float = left + (right - left) * ep
			draw_line(Vector2(left, bottom), Vector2(line_end_x, bottom),
				decoration_color, decoration_thickness, true)

		DecorationType.BOX:
			# Box perimeter draws in clockwise.
			var perimeter: float = 2.0 * ((right - left) + (bottom - top))
			var drawn: float = perimeter * ep
			_draw_partial_rect(left, top, right, bottom, drawn)

		DecorationType.CORNER_MARKS:
			var mark_len: float = 20.0 * ep
			var corners: Array[Array] = [
				[Vector2(left, top),    Vector2(left + mark_len, top),   Vector2(left, top + mark_len)],
				[Vector2(right, top),   Vector2(right - mark_len, top),  Vector2(right, top + mark_len)],
				[Vector2(left, bottom), Vector2(left + mark_len, bottom),Vector2(left, bottom - mark_len)],
				[Vector2(right,bottom), Vector2(right - mark_len,bottom),Vector2(right, bottom - mark_len)],
			]
			for corner in corners:
				draw_line(corner[0], corner[1], decoration_color, decoration_thickness, true)
				draw_line(corner[0], corner[2], decoration_color, decoration_thickness, true)

		DecorationType.SIDE_BARS:
			var bar_h: float = (bottom - top) * ep
			var bar_w: float = decoration_thickness * 2.0
			draw_rect(Rect2(left - bar_w - 6, top, bar_w, bar_h), decoration_color)
			draw_rect(Rect2(right + 6, top, bar_w, bar_h), decoration_color)

## Draws a rectangle outline up to [drawn] total pixels of perimeter,
## starting at the top-left, going clockwise.
func _draw_partial_rect(l: float, t: float, r: float, b: float, drawn: float) -> void:
	var segs: Array[Array] = [
		[Vector2(l, t), Vector2(r, t)],  # top
		[Vector2(r, t), Vector2(r, b)],  # right
		[Vector2(r, b), Vector2(l, b)],  # bottom
		[Vector2(l, b), Vector2(l, t)],  # left
	]
	var remaining: float = drawn
	for seg in segs:
		var seg_len: float = seg[0].distance_to(seg[1])
		if remaining <= 0.0:
			break
		var fraction: float = minf(remaining / seg_len, 1.0)
		var end_pt: Vector2 = seg[0].lerp(seg[1], fraction)
		draw_line(seg[0], end_pt, decoration_color, decoration_thickness, true)
		remaining -= seg_len
