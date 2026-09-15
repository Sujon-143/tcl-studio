@tool
extends BaseShape2D
class_name Wiper

## Full-screen wipe transition node.
## Place anywhere in your scene — it forces itself to the canvas origin and
## draws on a very high z-index so it covers everything beneath it.
##
## Keyframe [progress] from 0.0 → 1.0 in AnimationPlayer to wipe IN
## (screen becomes covered), or 1.0 → 0.0 to wipe OUT (screen becomes clear).
## [invert] flips which side is filled without changing the progress direction.

# ── Wipe styles ───────────────────────────────────────────────────────────────

enum WipeStyle {
	HORIZONTAL,        ## Left-to-right curtain.
	VERTICAL,          ## Top-to-bottom curtain.
	DIAGONAL,          ## Corner-to-corner diagonal edge.
	RADIAL,            ## Iris / circle expanding from center.
	DIAMOND,           ## Diamond iris from center.
	BLINDS,            ## Multiple horizontal slats sliding in.
	VENETIAN,          ## Multiple vertical slats sliding in.
	CLOCK,             ## Clockwise sweep from 12 o'clock.
	CROSS,             ## Two simultaneous horizontal + vertical wipes meeting center.
	FADE,              ## Modulate alpha only (no geometry wipe).
}

# ── Editor properties ─────────────────────────────────────────────────────────

@export_group("Transition")

## 0.0 = fully clear  /  1.0 = fully covered.
## Keyframe this in AnimationPlayer.
@export_range(0.0, 1.0, 0.001)
var progress: float = 0.0:
	set(v):
		progress = v
		queue_redraw()

## Which wipe style to use.
@export var wipe_style: WipeStyle = WipeStyle.HORIZONTAL:
	set(v):
		wipe_style = v
		queue_redraw()

## Flip the filled and clear regions.
@export var invert: bool = false:
	set(v):
		invert = v
		queue_redraw()

## Number of slats for BLINDS / VENETIAN styles.
@export_range(2, 32, 1)
var slat_count: int = 8:
	set(v):
		slat_count = v
		queue_redraw()

## Softness of the wipe edge (feather width in pixels, 0 = hard).
## Note: Godot's polygon draw is opaque — feather is approximated with
## a thin semi-transparent strip rendered on top of the hard edge.
@export_range(0.0, 80.0, 0.5, "suffix:px")
var edge_softness: float = 0.0:
	set(v):
		edge_softness = v
		queue_redraw()

@export_group("Appearance")

## Wipe panel color.
@export var wipe_color: Color = Color(0.05, 0.05, 0.05, 1.0):
	set(v):
		wipe_color = v
		queue_redraw()

## Optional contrasting edge stripe color (set alpha to 0 to hide).
@export var edge_color: Color = Color(1.0, 1.0, 1.0, 0.0):
	set(v):
		edge_color = v
		queue_redraw()

## Width of the edge stripe in pixels.
@export_range(0.0, 40.0, 0.5, "suffix:px")
var edge_stripe_width: float = 4.0:
	set(v):
		edge_stripe_width = v
		queue_redraw()

@export_group("Screen")

## Match this to your project's viewport size.
@export var screen_size: Vector2 = Vector2(1920, 1080):
	set(v):
		screen_size = v
		queue_redraw()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Force highest z-index so this always draws on top.
	#z_index = 4096
	#z_as_relative = false
	# Snap to canvas origin so screen_size calculations are correct.
	global_position = Vector2.ZERO

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	super._draw()
	var p: float = progress if not invert else 1.0 - progress
	# Clamp to avoid floating-point overshoot.
	p = clampf(p, 0.0, 1.0)

	if p <= 0.0:
		return  # Fully clear — draw nothing.

	match wipe_style:
		WipeStyle.HORIZONTAL:   _wipe_horizontal(p)
		WipeStyle.VERTICAL:     _wipe_vertical(p)
		WipeStyle.DIAGONAL:     _wipe_diagonal(p)
		WipeStyle.RADIAL:       _wipe_radial(p)
		WipeStyle.DIAMOND:      _wipe_diamond(p)
		WipeStyle.BLINDS:       _wipe_blinds(p)
		WipeStyle.VENETIAN:     _wipe_venetian(p)
		WipeStyle.CLOCK:        _wipe_clock(p)
		WipeStyle.CROSS:        _wipe_cross(p)
		WipeStyle.FADE:         _wipe_fade(p)

# ── Wipe implementations ──────────────────────────────────────────────────────

func _wipe_horizontal(p: float) -> void:
	var w: float = screen_size.x * p
	var h: float = screen_size.y
	draw_rect(Rect2(0, 0, w, h), wipe_color)
	_draw_edge_stripe(Vector2(w, 0), Vector2(w, h))

func _wipe_vertical(p: float) -> void:
	var w: float = screen_size.x
	var h: float = screen_size.y * p
	draw_rect(Rect2(0, 0, w, h), wipe_color)
	_draw_edge_stripe(Vector2(0, h), Vector2(w, h))

func _wipe_diagonal(p: float) -> void:
	# Diagonal wipe: edge travels from top-left to bottom-right.
	# The edge line passes through a point at fraction p along the diagonal.
	var W := screen_size.x
	var H := screen_size.y
	var diag: float = W + H
	var t: float = p * diag  # Position of the edge along the diagonal axis.
	# Four possible clipped polygons depending on t; build generically.
	var pts := PackedVector2Array()
	pts.append(Vector2(0, 0))
	if t <= W:
		pts.append(Vector2(t, 0))
	else:
		pts.append(Vector2(W, 0))
		pts.append(Vector2(W, t - W))
	pts.append(Vector2(maxf(0.0, t - H), H))
	pts.append(Vector2(0, minf(t, H)))
	if pts.size() >= 3:
		draw_colored_polygon(pts, wipe_color)
		# Edge stripe: the diagonal cut.
		if edge_color.a > 0.01 and edge_stripe_width > 0.0:
			var ex: float = minf(t, W)
			var ey: float = maxf(0.0, t - W)
			var fx: float = maxf(0.0, t - H)
			var fy: float = minf(t, H)
			draw_line(Vector2(ex, ey), Vector2(fx, fy), edge_color, edge_stripe_width, true)

func _wipe_radial(p: float) -> void:
	# Expanding circle iris from screen center.
	var center := screen_size * 0.5
	# Max radius needed to cover all corners.
	var max_r: float = center.length() * 1.42
	var r: float = p * max_r
	# Draw filled polygon approximating circle.
	var seg: int = 64
	var pts := PackedVector2Array()
	for i in seg:
		var angle: float = (float(i) / float(seg)) * TAU
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	if pts.size() >= 3:
		draw_colored_polygon(pts, wipe_color)
		if edge_color.a > 0.01 and edge_stripe_width > 0.0:
			for i in seg:
				draw_line(pts[i], pts[(i + 1) % seg], edge_color, edge_stripe_width, true)

func _wipe_diamond(p: float) -> void:
	var center := screen_size * 0.5
	var max_r: float = (center.x + center.y) * 1.05
	var r: float = p * max_r
	var pts := PackedVector2Array([
		center + Vector2(0, -r),
		center + Vector2(r, 0),
		center + Vector2(0, r),
		center + Vector2(-r, 0),
	])
	# Clip to screen rect using min/max clamping per vertex (sufficient for diamond).
	var clipped := PackedVector2Array()
	for pt in pts:
		clipped.append(Vector2(clampf(pt.x, 0, screen_size.x), clampf(pt.y, 0, screen_size.y)))
	if clipped.size() >= 3:
		draw_colored_polygon(clipped, wipe_color)
		if edge_color.a > 0.01 and edge_stripe_width > 0.0:
			var n: int = clipped.size()
			for i in n:
				draw_line(clipped[i], clipped[(i+1)%n], edge_color, edge_stripe_width, true)

func _wipe_blinds(p: float) -> void:
	# Horizontal slats, each sliding in from the left.
	var W: float = screen_size.x
	var H: float = screen_size.y
	var slat_h: float = H / float(slat_count)
	var slat_w: float = W * p
	for i in slat_count:
		var y: float = i * slat_h
		draw_rect(Rect2(0, y, slat_w, slat_h), wipe_color)
		if edge_color.a > 0.01 and edge_stripe_width > 0.0:
			draw_line(Vector2(slat_w, y), Vector2(slat_w, y + slat_h),
				edge_color, edge_stripe_width, true)

func _wipe_venetian(p: float) -> void:
	# Vertical slats, each sliding down from the top.
	var W: float = screen_size.x
	var H: float = screen_size.y
	var slat_w: float = W / float(slat_count)
	var slat_h: float = H * p
	for i in slat_count:
		var x: float = i * slat_w
		draw_rect(Rect2(x, 0, slat_w, slat_h), wipe_color)
		if edge_color.a > 0.01 and edge_stripe_width > 0.0:
			draw_line(Vector2(x, slat_h), Vector2(x + slat_w, slat_h),
				edge_color, edge_stripe_width, true)

func _wipe_clock(p: float) -> void:
	# Clockwise sweep starting at 12 o'clock.
	var center := screen_size * 0.5
	var max_r: float = center.length() * 1.5
	var sweep: float = p * TAU
	var seg: int = maxi(4, int(sweep / (PI / 32.0)))
	var pts := PackedVector2Array()
	pts.append(center)
	for i in seg + 1:
		var angle: float = -PI * 0.5 + (float(i) / float(seg)) * sweep
		pts.append(center + Vector2(cos(angle), sin(angle)) * max_r)
	if pts.size() >= 3:
		draw_colored_polygon(pts, wipe_color)
		if edge_color.a > 0.01 and edge_stripe_width > 0.0:
			# Draw the leading edge ray.
			var lead_angle: float = -PI * 0.5 + sweep
			draw_line(center,
				center + Vector2(cos(lead_angle), sin(lead_angle)) * max_r,
				edge_color, edge_stripe_width, true)

func _wipe_cross(p: float) -> void:
	# Two wipes (horizontal + vertical) meeting at center simultaneously.
	var W: float = screen_size.x
	var H: float = screen_size.y
	var half_w: float = (W * 0.5) * p
	var half_h: float = (H * 0.5) * p
	# Left and right panels.
	draw_rect(Rect2(0, 0, half_w, H), wipe_color)
	draw_rect(Rect2(W - half_w, 0, half_w, H), wipe_color)
	# Top and bottom panels.
	draw_rect(Rect2(0, 0, W, half_h), wipe_color)
	draw_rect(Rect2(0, H - half_h, W, half_h), wipe_color)
	if edge_color.a > 0.01 and edge_stripe_width > 0.0:
		draw_line(Vector2(half_w, 0), Vector2(half_w, H), edge_color, edge_stripe_width)
		draw_line(Vector2(W - half_w, 0), Vector2(W - half_w, H), edge_color, edge_stripe_width)
		draw_line(Vector2(0, half_h), Vector2(W, half_h), edge_color, edge_stripe_width)
		draw_line(Vector2(0, H - half_h), Vector2(W, H - half_h), edge_color, edge_stripe_width)

func _wipe_fade(p: float) -> void:
	var c := Color(wipe_color.r, wipe_color.g, wipe_color.b, wipe_color.a * p)
	draw_rect(Rect2(Vector2.ZERO, screen_size), c)

# ── Edge stripe helper ────────────────────────────────────────────────────────

func _draw_edge_stripe(from: Vector2, to: Vector2) -> void:
	if edge_color.a < 0.01 or edge_stripe_width <= 0.0:
		return
	draw_line(from, to, edge_color, edge_stripe_width, true)
