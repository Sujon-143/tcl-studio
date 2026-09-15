@tool
extends BaseShape2D
class_name VintageMonitor2D

# ─────────────────────────────────────────────────────────────────────────────
#  MONITOR DIMENSIONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Monitor Dimensions")

## Overall width of the entire monitor unit in local units.
@export_range(100.0, 800.0, 1.0) var monitor_width: float = 320.0:
	set(v): monitor_width = v; queue_redraw()

## Overall height of the entire monitor unit (bezel + stand) in local units.
@export_range(80.0, 700.0, 1.0) var monitor_height: float = 300.0:
	set(v): monitor_height = v; queue_redraw()

## Corner radius of the outer bezel shell.
@export_range(0.0, 40.0, 1.0) var bezel_corner_radius: float = 14.0:
	set(v): bezel_corner_radius = v; queue_redraw()

## Thickness of the bezel frame around the screen on each side.
@export_range(4.0, 60.0, 1.0) var bezel_thickness: float = 22.0:
	set(v): bezel_thickness = v; queue_redraw()

## Corner radius of the inner screen rect.
@export_range(0.0, 20.0, 1.0) var screen_corner_radius: float = 6.0:
	set(v): screen_corner_radius = v; queue_redraw()

## Height of the stand/neck below the monitor body, as fraction of monitor_height.
@export_range(0.05, 0.5, 0.01) var stand_height_ratio: float = 0.18:
	set(v): stand_height_ratio = v; queue_redraw()

## Width of the neck connecting body to base.
@export_range(10.0, 120.0, 1.0) var neck_width: float = 36.0:
	set(v): neck_width = v; queue_redraw()

## Width of the flat base foot.
@export_range(40.0, 300.0, 1.0) var base_width: float = 130.0:
	set(v): base_width = v; queue_redraw()

## Height/thickness of the flat base foot.
@export_range(4.0, 30.0, 1.0) var base_height: float = 12.0:
	set(v): base_height = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  BEZEL COLORS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Bezel Colors")

## Primary body color of the plastic bezel.
@export var bezel_color: Color = Color(0.76, 0.74, 0.68, 1.0):
	set(v): bezel_color = v; queue_redraw()

## Shadow/dark face of the bezel (bottom-right depth).
@export var bezel_shadow_color: Color = Color(0.52, 0.50, 0.46, 1.0):
	set(v): bezel_shadow_color = v; queue_redraw()

## Highlight edge of the bezel (top-left light catch).
@export var bezel_highlight_color: Color = Color(0.90, 0.89, 0.85, 1.0):
	set(v): bezel_highlight_color = v; queue_redraw()

## Color of the inner screen border inset (the recessed lip).
@export var bezel_inner_color: Color = Color(0.20, 0.20, 0.18, 1.0):
	set(v): bezel_inner_color = v; queue_redraw()

## Stand and base color (slightly darker than bezel).
@export var stand_color: Color = Color(0.62, 0.60, 0.56, 1.0):
	set(v): stand_color = v; queue_redraw()

## Vent slot color.
@export var vent_color: Color = Color(0.40, 0.39, 0.36, 0.8):
	set(v): vent_color = v; queue_redraw()

## Number of vent slots on the right side of the bezel.
@export_range(0, 10, 1) var vent_count: int = 4:
	set(v): vent_count = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  SCREEN COLORS & PHOSPHOR
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Screen — Phosphor")

## Background color of the CRT screen when powered off.
@export var screen_off_color: Color = Color(0.04, 0.06, 0.04, 1.0):
	set(v): screen_off_color = v; queue_redraw()

## Primary phosphor/text glow color (classic green, amber, or white).
@export var phosphor_color: Color = Color(0.18, 1.0, 0.32, 1.0):
	set(v): phosphor_color = v; queue_redraw()

## Dim ambient glow tint across the whole screen when powered on.
@export var screen_glow_color: Color = Color(0.04, 0.14, 0.06, 1.0):
	set(v): screen_glow_color = v; queue_redraw()

## Specular glare patch color on the screen glass.
@export var screen_glare_color: Color = Color(0.85, 0.90, 0.95, 0.12):
	set(v): screen_glare_color = v; queue_redraw()

## Opacity of scanline dark bands overlaid on the screen.
@export_range(0.0, 0.8, 0.01) var scanline_opacity: float = 0.18:
	set(v): scanline_opacity = v; queue_redraw()

## Pixel height of each scanline band (line + gap).
@export_range(2.0, 8.0, 0.5) var scanline_pitch: float = 3.0:
	set(v): scanline_pitch = v; queue_redraw()

## CRT barrel warp strength. 0 = flat, 1 = strong bulge illusion via vignette.
@export_range(0.0, 1.0, 0.01) var barrel_strength: float = 0.35:
	set(v): barrel_strength = v; queue_redraw()

## Power LED color.
@export var led_color: Color = Color(0.2, 1.0, 0.25, 1.0):
	set(v): led_color = v; queue_redraw()

## Power LED radius.
@export_range(1.0, 8.0, 0.5) var led_radius: float = 3.5:
	set(v): led_radius = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  SCREEN CONTENT — TERMINAL TEXT
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Screen Content")

## Lines of text to display on the terminal screen.
@export var terminal_lines: Array[String] = [
	"SYSTEM BOOT v2.3.1",
	"RAM CHECK........OK",
	"DISK CHECK.......OK",
	"LOADING KERNEL...",
	"",
	"C:\\> _"
]:
	set(v): terminal_lines = v; queue_redraw()

## Font size for terminal text (in local units).
@export_range(4, 100, 1) var terminal_font_size: int = 10:
	set(v): terminal_font_size = v; queue_redraw()

## Line height multiplier.
@export_range(1.0, 2.5, 0.05) var line_height_mult: float = 1.5:
	set(v): line_height_mult = v; queue_redraw()

## Left padding of text inside screen.
@export_range(2.0, 30.0, 1.0) var text_padding: float = 8.0:
	set(v): text_padding = v; queue_redraw()

## Top padding of text inside screen.
@export_range(2.0, 30.0, 1.0) var text_padding_top: float = 8.0:
	set(v): text_padding_top = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — POWER ON
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Power On")

## 0 = monitor completely off / dark, 1 = fully powered on with glow.
## Controls screen brightness, LED, and CRT "turn on" white flash.
@export_range(0.0, 1.0, 0.01) var power_on_progress: float = 1.0:
	set(v): power_on_progress = v; queue_redraw()

## At t≈0.1 the CRT fires a bright white horizontal line before spreading.
## This is embedded in power_on_progress but can be overridden here for manual control.
@export_range(0.0, 1.0, 0.01) var crt_flash_progress: float = 0.0:
	set(v): crt_flash_progress = v; queue_redraw()

## 0 = no vertical expand (single bright line), 1 = screen fully expanded.
## Animate AFTER crt_flash_progress hits 1 to simulate CRT vertical sweep.
@export_range(0.0, 1.0, 0.01) var screen_expand_progress: float = 1.0:
	set(v): screen_expand_progress = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — TEXT TYPING
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Text Typing")

## 0 = no text visible, 1 = all lines fully typed out.
## Characters appear progressively across all lines as this sweeps 0→1.
@export_range(0.0, 1.0, 0.01) var type_progress: float = 1.0:
	set(v): type_progress = v; queue_redraw()

## Blink speed of the cursor (cycles per second at full speed). Driven by blink_phase.
@export_range(0.5, 10.0, 0.1) var cursor_blink_speed: float = 2.0:
	set(v): cursor_blink_speed = v; queue_redraw()

## Animate this with a looping 0→1 tween at cursor_blink_speed Hz for blinking.
## 0.0→0.5 = cursor ON, 0.5→1.0 = cursor OFF.
@export_range(0.0, 1.0, 0.01) var blink_phase: float = 0.0:
	set(v): blink_phase = v; queue_redraw()

## Opacity of the text (can fade in/out independently of type_progress).
@export_range(0.0, 1.0, 0.01) var text_opacity: float = 1.0:
	set(v): text_opacity = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — SCANLINE SCROLL
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Scanline Scroll")

## Drives vertical scroll of the scanline pattern. Loop 0→1 continuously.
@export_range(0.0, 1.0, 0.01) var scanline_scroll: float = 0.0:
	set(v): scanline_scroll = v; queue_redraw()

## A single bright scanline "refresh sweep" passes top→bottom.
## 0 = at top, 1 = passed bottom. Loop for a CRT refresh look.
@export_range(0.0, 1.0, 0.01) var refresh_sweep_progress: float = 0.0:
	set(v): refresh_sweep_progress = v; queue_redraw()

## Brightness of the refresh sweep line.
@export_range(0.0, 1.0, 0.01) var refresh_sweep_brightness: float = 0.35:
	set(v): refresh_sweep_brightness = v; queue_redraw()

## Width (as fraction of screen height) of the refresh sweep band.
@export_range(0.01, 0.3, 0.005) var refresh_sweep_width: float = 0.06:
	set(v): refresh_sweep_width = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — GLITCH
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Glitch")

## 0 = pristine, 1 = full glitch. Controls horizontal shift bands.
## Animate with short spikes for an authentic CRT glitch feel.
@export_range(0.0, 1.0, 0.01) var glitch_progress: float = 0.0:
	set(v): glitch_progress = v; queue_redraw()

## Seed for the glitch band pattern (change to get different glitch shapes).
@export var glitch_seed: int = 7:
	set(v): glitch_seed = v; queue_redraw()

## Number of horizontal glitch bands drawn.
@export_range(1, 12, 1) var glitch_band_count: int = 4:
	set(v): glitch_band_count = v; queue_redraw()

## Max horizontal pixel shift of each glitch band (in local units).
@export_range(1.0, 60.0, 1.0) var glitch_max_shift: float = 18.0:
	set(v): glitch_max_shift = v; queue_redraw()

## Color tint of glitch bands (RGB channel separation effect).
@export var glitch_tint_color: Color = Color(0.3, 1.0, 0.5, 0.25):
	set(v): glitch_tint_color = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — STATIC / NOISE
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Static")

## 0 = no static, 1 = heavy noise overlay on screen.
@export_range(0.0, 1.0, 0.01) var static_progress: float = 0.0:
	set(v): static_progress = v; queue_redraw()

## Seed for the static dot pattern.
@export var static_seed: int = 99:
	set(v): static_seed = v; queue_redraw()

## Number of static noise dots rendered.
@export_range(0, 800, 10) var static_dot_count: int = 200:
	set(v): static_dot_count = v; queue_redraw()

## Size of each static dot in local units.
@export_range(0.5, 5.0, 0.25) var static_dot_size: float = 1.5:
	set(v): static_dot_size = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — SCREEN FADE / FLICKER
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Fade & Flicker")

## Master brightness of the screen content (0 = black, 1 = full brightness).
@export_range(0.0, 1.0, 0.01) var screen_brightness: float = 1.0:
	set(v): screen_brightness = v; queue_redraw()

## Animate 0→1→0 rapidly for a flicker effect. Multiplies into screen_brightness.
@export_range(0.0, 1.0, 0.01) var flicker_progress: float = 1.0:
	set(v): flicker_progress = v; queue_redraw()

## 0 = screen fully on, 1 = screen turned off with collapsing scanline.
## Animate 0→1 for a power-off sequence (reverse of power_on).
@export_range(0.0, 1.0, 0.01) var power_off_progress: float = 0.0:
	set(v): power_off_progress = v; queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS — ROUNDED RECT
# ─────────────────────────────────────────────────────────────────────────────

func _rounded_rect_points(rect: Rect2, r: float, segs_per_corner: int = 8) -> PackedVector2Array:
	r = minf(r, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var cx := [rect.position.x + r, rect.end.x - r, rect.end.x - r, rect.position.x + r]
	var cy := [rect.position.y + r, rect.position.y + r, rect.end.y - r, rect.end.y - r]
	var start_angles := [-PI, -PI * 0.5, 0.0, PI * 0.5]
	for i in 4:
		for s in segs_per_corner + 1:
			var a = start_angles[i] + (PI * 0.5) * (float(s) / float(segs_per_corner))
			pts.append(Vector2(cx[i] + cos(a) * r, cy[i] + sin(a) * r))
	return pts

func _draw_rounded_rect(rect: Rect2, r: float, color: Color, segs: int = 8) -> void:
	var pts := _rounded_rect_points(rect, r, segs)
	draw_colored_polygon(pts, color)

func _stroke_rounded_rect(rect: Rect2, r: float, color: Color, width: float, segs: int = 8) -> void:
	var pts := _rounded_rect_points(rect, r, segs)
	# Close the loop
	if pts.size() > 0:
		pts.append(pts[0])
	draw_polyline(pts, color, width, true)

# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS — GEOMETRY GETTERS
# ─────────────────────────────────────────────────────────────────────────────

func _get_body_rect() -> Rect2:
	var body_h := monitor_height * (1.0 - stand_height_ratio)
	return Rect2(-monitor_width * 0.5, -monitor_height * 0.5, monitor_width, body_h)

func _get_screen_rect() -> Rect2:
	var body := _get_body_rect()
	return Rect2(
		body.position.x + bezel_thickness,
		body.position.y + bezel_thickness,
		body.size.x - bezel_thickness * 2.0,
		body.size.y - bezel_thickness * 2.0
	)

func _get_stand_top_y() -> float:
	return _get_body_rect().end.y

func _get_stand_bottom_y() -> float:
	return _get_stand_top_y() + monitor_height * stand_height_ratio - base_height

# ─────────────────────────────────────────────────────────────────────────────
#  DRAW
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var body_rect   := _get_body_rect()
	var screen_rect := _get_screen_rect()

	# ── Composite brightness ──────────────────────────────────────────────────
	var pwr     := clampf(power_on_progress, 0.0, 1.0)
	var pwr_off := clampf(power_off_progress, 0.0, 1.0)
	# Power-off collapses brightness
	var eff_brightness := screen_brightness * flicker_progress * pwr * (1.0 - pwr_off * 0.95)
	# CRT expand: clip the screen vertically around its center
	var expand  := clampf(screen_expand_progress, 0.0, 1.0)
	var flash   := clampf(crt_flash_progress, 0.0, 1.0)

	# Power-off collapse mirrors expand but in reverse
	if pwr_off > 0.0:
		expand = lerpf(expand, 0.0, pwr_off)

	# Visible screen content band (vertical clip in local space)
	var s_cx   := screen_rect.get_center().x
	var s_cy   := screen_rect.get_center().y
	var s_half := screen_rect.size.y * 0.5

	# Height of the revealed band
	var band_half := s_half * expand

	# ── 1. STAND / BASE ───────────────────────────────────────────────────────
	# Neck
	var stand_top_y    := _get_stand_top_y()
	var stand_bottom_y := _get_stand_bottom_y()
	var neck_pts := PackedVector2Array([
		Vector2(-neck_width * 0.5, stand_top_y),
		Vector2( neck_width * 0.5, stand_top_y),
		Vector2( neck_width * 0.6, stand_bottom_y),
		Vector2(-neck_width * 0.6, stand_bottom_y),
	])
	draw_colored_polygon(neck_pts, stand_color)

	# Base foot (rounded)
	var base_rect := Rect2(-base_width * 0.5, stand_bottom_y, base_width, base_height)
	_draw_rounded_rect(base_rect, base_height * 0.4, stand_color, 6)
	# Base highlight
	var base_hl := stand_color.lightened(0.15)
	draw_line(
		Vector2(base_rect.position.x + 6, base_rect.position.y + 2),
		Vector2(base_rect.end.x - 6,      base_rect.position.y + 2),
		base_hl, 1.5, true
	)

	# ── 2. MONITOR BODY SHADOW (drop shadow) ─────────────────────────────────
	var shadow_rect := Rect2(body_rect.position + Vector2(5, 6), body_rect.size)
	_draw_rounded_rect(shadow_rect, bezel_corner_radius, Color(0, 0, 0, 0.28), 10)

	# ── 3. BEZEL BODY ────────────────────────────────────────────────────────
	_draw_rounded_rect(body_rect, bezel_corner_radius, bezel_color, 10)

	# Bezel bottom-right shadow face (depth illusion)
	var shadow_face_pts := PackedVector2Array([
		Vector2(body_rect.end.x - bezel_corner_radius, body_rect.position.y + bezel_corner_radius),
		Vector2(body_rect.end.x, body_rect.position.y + bezel_corner_radius),
		Vector2(body_rect.end.x, body_rect.end.y - bezel_corner_radius),
		Vector2(body_rect.end.x - bezel_corner_radius, body_rect.end.y),
		Vector2(body_rect.position.x + bezel_corner_radius, body_rect.end.y),
		Vector2(body_rect.position.x + bezel_corner_radius, body_rect.end.y - bezel_corner_radius),
	])
	draw_colored_polygon(shadow_face_pts, bezel_shadow_color)

	# Bezel top-left highlight edge
	_stroke_rounded_rect(
		Rect2(body_rect.position + Vector2(1, 1), body_rect.size - Vector2(2, 2)),
		bezel_corner_radius - 1, bezel_highlight_color, 1.5, 10
	)

	# ── 4. SCREEN RECESSED LIP ────────────────────────────────────────────────
	var lip_rect := Rect2(
		screen_rect.position - Vector2(4, 4),
		screen_rect.size + Vector2(8, 8)
	)
	_draw_rounded_rect(lip_rect, screen_corner_radius + 3, bezel_inner_color, 8)

	# ── 5. SCREEN BACKGROUND ─────────────────────────────────────────────────
	_draw_rounded_rect(screen_rect, screen_corner_radius, screen_off_color, 8)

	# Powered-on ambient glow fills the screen
	if pwr > 0.01 and expand > 0.01:
		var glow_col := screen_glow_color
		glow_col.a = pwr * expand
		_draw_rounded_rect(screen_rect, screen_corner_radius, glow_col, 8)

	# ── 6. CRT VERTICAL EXPAND / COLLAPSE BAND ────────────────────────────────
	# Only draw the visible band (everything outside stays black)
	if expand < 0.999 and pwr > 0.01:
		# Black mask above the band
		var top_mask := Rect2(
			screen_rect.position.x,
			screen_rect.position.y,
			screen_rect.size.x,
			maxf(0.0, (s_cy - band_half) - screen_rect.position.y)
		)
		if top_mask.size.y > 0:
			draw_rect(top_mask, screen_off_color)

		# Black mask below the band
		var bot_y    := s_cy + band_half
		var bot_mask := Rect2(
			screen_rect.position.x,
			bot_y,
			screen_rect.size.x,
			maxf(0.0, screen_rect.end.y - bot_y)
		)
		if bot_mask.size.y > 0:
			draw_rect(bot_mask, screen_off_color)

		# Bright white slit at center of band edge (CRT bloom line)
		var slit_thickness := maxf(1.5, 4.0 * (1.0 - expand))
		var slit_col := phosphor_color.lightened(0.6)
		slit_col.a = (1.0 - expand) * pwr * 0.9
		draw_line(
			Vector2(screen_rect.position.x + 4, s_cy - band_half),
			Vector2(screen_rect.end.x - 4,      s_cy - band_half),
			slit_col, slit_thickness, true
		)
		draw_line(
			Vector2(screen_rect.position.x + 4, s_cy + band_half),
			Vector2(screen_rect.end.x - 4,      s_cy + band_half),
			slit_col, slit_thickness, true
		)

	# ── 7. CRT FLASH (horizontal white line burst) ────────────────────────────
	if flash > 0.01 and pwr > 0.01:
		var fl_alpha := flash * (1.0 - flash) * 4.0   # peaks at flash=0.5
		var fl_col   := Color(1.0, 1.0, 1.0, fl_alpha * pwr)
		var fl_h     := maxf(1.0, screen_rect.size.y * 0.04 * fl_alpha)
		draw_rect(
			Rect2(screen_rect.position.x, s_cy - fl_h * 0.5, screen_rect.size.x, fl_h),
			fl_col
		)

	# ── 8. SCANLINES ─────────────────────────────────────────────────────────
	if scanline_opacity > 0.01 and expand > 0.1 and pwr > 0.01:
		var scan_col := Color(0, 0, 0, scanline_opacity * eff_brightness)
		var offset   := fmod(scanline_scroll * scanline_pitch * 10.0, scanline_pitch)
		var y_start  := screen_rect.position.y
		var y_end    := screen_rect.end.y
		var x_start  := screen_rect.position.x
		var x_end    := screen_rect.end.x
		var y := y_start + offset
		while y < y_end:
			var row_top    := maxf(y, maxf(y_start, s_cy - band_half))
			var row_bottom := minf(y + scanline_pitch * 0.4, minf(y_end, s_cy + band_half))
			if row_bottom > row_top:
				draw_rect(Rect2(x_start, row_top, x_end - x_start, row_bottom - row_top), scan_col)
			y += scanline_pitch

	# ── 9. REFRESH SWEEP ─────────────────────────────────────────────────────
	if refresh_sweep_brightness > 0.01 and pwr > 0.01 and expand > 0.5:
		var sweep_y      := screen_rect.position.y + screen_rect.size.y * refresh_sweep_progress
		var sweep_height := screen_rect.size.y * refresh_sweep_width
		var sw_col       := phosphor_color.lightened(0.3)
		sw_col.a = refresh_sweep_brightness * eff_brightness * 0.6
		var sw_top  := clampf(sweep_y - sweep_height * 0.5, screen_rect.position.y, screen_rect.end.y)
		var sw_bot  := clampf(sweep_y + sweep_height * 0.5, screen_rect.position.y, screen_rect.end.y)
		if sw_bot > sw_top:
			draw_rect(Rect2(screen_rect.position.x, sw_top, screen_rect.size.x, sw_bot - sw_top), sw_col)

	# ── 10. TERMINAL TEXT ─────────────────────────────────────────────────────
	if type_progress > 0.0 and text_opacity > 0.01 and pwr > 0.01 and expand > 0.3:
		var font    := ThemeDB.fallback_font
		var line_h  := terminal_font_size * line_height_mult
		var total_chars := 0
		for line in terminal_lines:
			total_chars += line.length()
		var chars_to_show := int(type_progress * float(total_chars))
		var chars_drawn   := 0
		var tx := screen_rect.position.x + text_padding
		var ty := screen_rect.position.y + text_padding_top + terminal_font_size

		# Clip to band
		var band_top    := s_cy - band_half
		var band_bottom := s_cy + band_half

		for li in terminal_lines.size():
			var line: String = terminal_lines[li]
			if chars_drawn >= chars_to_show:
				break

			var remaining := chars_to_show - chars_drawn
			var show_chars := mini(remaining, line.length())
			var display_str := line.substr(0, show_chars)

			# Add blinking cursor at the end of the currently-typing line
			var is_active_line := (chars_drawn + line.length() >= chars_to_show) and show_chars < line.length()
			var is_last_line   := (li == terminal_lines.size() - 1) and show_chars >= line.length() - 1

			if (is_active_line or is_last_line) and blink_phase < 0.5:
				display_str += "|"

			# Only draw if within vertical band
			if ty >= band_top and ty - terminal_font_size <= band_bottom:
				# Per-character glow: the most recently typed char is brighter
				var txt_col := phosphor_color
				txt_col.a = text_opacity * eff_brightness
				draw_string(font, Vector2(tx, ty), display_str,
					HORIZONTAL_ALIGNMENT_LEFT, -1, terminal_font_size, txt_col)

				# Extra glow on last character typed
				if show_chars > 0 and show_chars <= line.length():
					var last_char := display_str.substr(display_str.length() - 1, 1)
					var prev_str  := display_str.substr(0, display_str.length() - 1)
					var prev_w    := font.get_string_size(prev_str, HORIZONTAL_ALIGNMENT_LEFT, -1, terminal_font_size).x
					var glow_col2 := phosphor_color.lightened(0.5)
					glow_col2.a = text_opacity * eff_brightness * 0.7
					draw_string(font, Vector2(tx + prev_w, ty), last_char,
						HORIZONTAL_ALIGNMENT_LEFT, -1, terminal_font_size, glow_col2)

			chars_drawn += line.length()
			ty += line_h

	# ── 11. GLITCH BANDS ──────────────────────────────────────────────────────
	if glitch_progress > 0.01 and pwr > 0.01:
		var rng := RandomNumberGenerator.new()
		rng.seed = glitch_seed
		var s_w := screen_rect.size.x
		var s_h := screen_rect.size.y
		for _i in glitch_band_count:
			var band_y    := screen_rect.position.y + rng.randf() * s_h
			var band_h    := rng.randf_range(2.0, s_h * 0.12)
			var shift     := rng.randf_range(-glitch_max_shift, glitch_max_shift) * glitch_progress
			var tint      := glitch_tint_color
			tint.a        *= glitch_progress * rng.randf_range(0.4, 1.0)
			var shifted_rect := Rect2(
				screen_rect.position.x + shift,
				clampf(band_y, screen_rect.position.y, screen_rect.end.y - 1),
				s_w,
				minf(band_h, screen_rect.end.y - band_y)
			)
			if shifted_rect.size.y > 0:
				draw_rect(shifted_rect, tint)
			# Chromatic aberration tint strip
			var ca_col := Color(tint.r * 0.4, tint.g * 0.1, tint.b * 0.8, tint.a * 0.4)
			var ca_rect := Rect2(shifted_rect.position.x - 3, shifted_rect.position.y,
				shifted_rect.size.x, shifted_rect.size.y)
			if ca_rect.size.y > 0:
				draw_rect(ca_rect, ca_col)

	# ── 12. STATIC NOISE ──────────────────────────────────────────────────────
	if static_progress > 0.01 and pwr > 0.01:
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = static_seed
		var dots_to_draw := int(static_dot_count * static_progress)
		for _i in dots_to_draw:
			var dx := screen_rect.position.x + rng2.randf() * screen_rect.size.x
			var dy := screen_rect.position.y + rng2.randf() * screen_rect.size.y
			var brightness := rng2.randf_range(0.3, 1.0)
			var dot_col := phosphor_color.lightened(brightness - 0.5)
			dot_col.a = rng2.randf_range(0.4, 0.9) * static_progress
			draw_rect(Rect2(dx, dy, static_dot_size, static_dot_size), dot_col)

	# ── 13. BARREL VIGNETTE (CRT curvature illusion) ─────────────────────────
	if barrel_strength > 0.01 and pwr > 0.01:
		# Draw dark corners via four triangles pointing inward
		var v := barrel_strength * 0.6 * expand
		var corner_size := minf(screen_rect.size.x, screen_rect.size.y) * 0.32 * v
		var corner_col  := Color(0, 0, 0, v * 0.85)
		# Top-left
		draw_colored_polygon(PackedVector2Array([
			screen_rect.position,
			screen_rect.position + Vector2(corner_size, 0),
			screen_rect.position + Vector2(0, corner_size)
		]), corner_col)
		# Top-right
		draw_colored_polygon(PackedVector2Array([
			Vector2(screen_rect.end.x, screen_rect.position.y),
			Vector2(screen_rect.end.x - corner_size, screen_rect.position.y),
			Vector2(screen_rect.end.x, screen_rect.position.y + corner_size)
		]), corner_col)
		# Bottom-left
		draw_colored_polygon(PackedVector2Array([
			Vector2(screen_rect.position.x, screen_rect.end.y),
			Vector2(screen_rect.position.x + corner_size, screen_rect.end.y),
			Vector2(screen_rect.position.x, screen_rect.end.y - corner_size)
		]), corner_col)
		# Bottom-right
		draw_colored_polygon(PackedVector2Array([
			screen_rect.end,
			screen_rect.end - Vector2(corner_size, 0),
			screen_rect.end - Vector2(0, corner_size)
		]), corner_col)

	# ── 14. SCREEN GLARE PATCH ───────────────────────────────────────────────
	if screen_glare_color.a > 0.01:
		var gl_pts := PackedVector2Array([
			screen_rect.position + Vector2(8, 5),
			screen_rect.position + Vector2(screen_rect.size.x * 0.45, 5),
			screen_rect.position + Vector2(screen_rect.size.x * 0.25, screen_rect.size.y * 0.28),
			screen_rect.position + Vector2(4, screen_rect.size.y * 0.18),
		])
		draw_colored_polygon(gl_pts, screen_glare_color)
		# Smaller secondary glare
		var gl2_pts := PackedVector2Array([
			screen_rect.position + Vector2(screen_rect.size.x * 0.55, 6),
			screen_rect.position + Vector2(screen_rect.size.x * 0.78, 6),
			screen_rect.position + Vector2(screen_rect.size.x * 0.70, screen_rect.size.y * 0.12),
			screen_rect.position + Vector2(screen_rect.size.x * 0.50, screen_rect.size.y * 0.12),
		])
		draw_colored_polygon(gl2_pts, screen_glare_color)

	# ── 15. BEZEL DETAILS — VENT SLOTS ───────────────────────────────────────
	if vent_count > 0:
		var vent_x     := body_rect.end.x - bezel_thickness * 0.65
		var vent_w     := bezel_thickness * 0.25
		var vent_area_h := body_rect.size.y * 0.35
		var vent_start_y := body_rect.get_center().y - vent_area_h * 0.5
		var vent_step  := vent_area_h / float(vent_count)
		for i in vent_count:
			var vy := vent_start_y + i * vent_step + vent_step * 0.15
			var vh := vent_step * 0.5
			draw_rect(Rect2(vent_x, vy, vent_w, vh), vent_color)
			# Vent highlight (top edge)
			var vh_col := vent_color.lightened(0.2)
			draw_line(Vector2(vent_x, vy), Vector2(vent_x + vent_w, vy), vh_col, 1.0)

	# ── 16. BEZEL BRAND BADGE ─────────────────────────────────────────────────
	var badge_rect := Rect2(
		body_rect.position.x + bezel_thickness * 0.3,
		body_rect.end.y - bezel_thickness * 0.72,
		bezel_thickness * 1.6,
		bezel_thickness * 0.35
	)
	_draw_rounded_rect(badge_rect, 2.0, bezel_shadow_color.darkened(0.15), 4)
	# Tiny dots on badge (design detail)
	for di in 3:
		var dot_x := badge_rect.position.x + badge_rect.size.x * (0.25 + di * 0.25)
		draw_circle(Vector2(dot_x, badge_rect.get_center().y), 1.2, bezel_color.lightened(0.1))

	# ── 17. POWER LED ─────────────────────────────────────────────────────────
	var led_x := body_rect.end.x - bezel_thickness * 0.55
	var led_y := body_rect.end.y - bezel_thickness * 0.55
	# LED housing (dark circle)
	draw_circle(Vector2(led_x, led_y), led_radius + 2.0, bezel_shadow_color.darkened(0.2))
	# LED glow
	var eff_led_col := led_color
	eff_led_col.a = pwr * (0.5 + 0.5 * flicker_progress) * (1.0 - pwr_off)
	if eff_led_col.a > 0.01:
		# Outer soft glow
		var led_glow := led_color
		led_glow.a = eff_led_col.a * 0.35
		draw_circle(Vector2(led_x, led_y), led_radius * 2.2, led_glow)
	draw_circle(Vector2(led_x, led_y), led_radius, eff_led_col if pwr > 0.05 else bezel_shadow_color.darkened(0.3))
	# LED specular
	if pwr > 0.05:
		draw_circle(Vector2(led_x - led_radius * 0.3, led_y - led_radius * 0.3),
			led_radius * 0.35, Color(1, 1, 1, 0.55))

	# ── 18. OUTER BEZEL STROKE ────────────────────────────────────────────────
	_stroke_rounded_rect(body_rect, bezel_corner_radius, Color(0, 0, 0, 0.45), 1.5, 10)
