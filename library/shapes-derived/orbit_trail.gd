@tool
extends MeshInstance3D
class_name OrbitTrail

## Camera-facing flat quad strip orbit trail.
## O(n) vertices — no tube math, no cross-sections.
##
## Material is managed internally (vertex colour + alpha, unshaded, no cull).
## Just drop the node in the scene and configure via the Inspector.

# ──────────────────────────────────────────────────────────────────────────────
#region  Orbit Shape
# ──────────────────────────────────────────────────────────────────────────────

@export_group("Orbit Shape")

@export var center: Vector3 = Vector3.ZERO:
	set(v): center = v; _redraw()

## Radius along the X axis.
@export_range(0.01, 200.0, 0.001) var radius_x: float = 3.0:
	set(v): radius_x = max(0.01, v); _redraw()

## Radius along the Z axis.  Equal to radius_x for a circle.
@export_range(0.01, 200.0, 0.001) var radius_z: float = 3.0:
	set(v): radius_z = max(0.01, v); _redraw()

## Tilt of the orbit plane around the X axis (degrees).
@export_range(-180.0, 180.0, 0.1) var inclination_deg: float = 0.0:
	set(v): inclination_deg = v; _redraw()

## Where the visible trail begins on the ellipse (degrees, 0 = +X).
@export_range(0.0, 360.0, 0.1) var start_angle_deg: float = 0.0:
	set(v): start_angle_deg = v; _redraw()

## Where the visible trail ends on the ellipse (degrees).
## The trail always travels CCW from start to end.
## Set equal to start_angle_deg for a full 360 loop.
@export_range(0.0, 360.0, 0.1) var end_angle_deg: float = 270.0:
	set(v): end_angle_deg = v; _redraw()

## Number of line segments used to approximate the arc.
@export_range(8, 512, 1) var segments: int = 128:
	set(v): segments = max(8, v); _redraw()

#endregion

# ──────────────────────────────────────────────────────────────────────────────
#region  Trail Profile
# ──────────────────────────────────────────────────────────────────────────────

@export_group("Trail Profile")

## Half-width at the start (head) of the trail.
@export_range(0.0, 4.0, 0.001) var width_start: float = 0.35:
	set(v): width_start = max(0.0, v); _redraw()

## Half-width at the end (tail) of the trail.
@export_range(0.0, 4.0, 0.001) var width_end: float = 0.01:
	set(v): width_end = max(0.0, v); _redraw()

## Power curve on the width lerp.
## 1 = linear, >1 = stays wide longer then tapers sharply, <1 = tapers immediately.
@export_range(0.1, 6.0, 0.01) var width_exponent: float = 1.5:
	set(v): width_exponent = max(0.1, v); _redraw()

## Alpha at the start (head).
@export_range(0.0, 1.0, 0.001) var alpha_start: float = 1.0:
	set(v): alpha_start = clamp(v, 0.0, 1.0); _redraw()

## Alpha at the end (tail).
@export_range(0.0, 1.0, 0.001) var alpha_end: float = 0.0:
	set(v): alpha_end = clamp(v, 0.0, 1.0); _redraw()

## Power curve on the alpha lerp (same semantic as width_exponent).
@export_range(0.1, 6.0, 0.01) var alpha_exponent: float = 1.0:
	set(v): alpha_exponent = max(0.1, v); _redraw()

## Base colour of the trail.  Per-vertex alpha is applied on top.
@export var trail_color: Color = Color(0.965, 0.55, 0.1, 1.0):
	set(v): trail_color = v; _redraw()

#endregion

# ──────────────────────────────────────────────────────────────────────────────
#region  Dash
# ──────────────────────────────────────────────────────────────────────────────

@export_group("Dash")

@export var solid: bool = true:
	set(v): solid = v; _redraw()

## Fraction of each dash+gap pattern that is solid (0.01 … 0.99).
@export_range(0.01, 0.99, 0.01) var dash_ratio: float = 0.6:
	set(v): dash_ratio = clamp(v, 0.01, 0.99); _redraw()

## Total arc-length (world units) of one dash + one gap cycle.
@export_range(0.05, 20.0, 0.01) var dash_period: float = 0.8:
	set(v): dash_period = max(0.05, v); _redraw()

#endregion

# ──────────────────────────────────────────────────────────────────────────────
#region  Private
# ──────────────────────────────────────────────────────────────────────────────

var _mesh: ImmediateMesh
var _mat:  StandardMaterial3D
var _ready_done: bool = false

#endregion

# ──────────────────────────────────────────────────────────────────────────────
#region  Static factories
# ──────────────────────────────────────────────────────────────────────────────

static func get_default() -> OrbitTrail:
	return OrbitTrail.new()

## Hot comet-style trail.
static func get_comet(rx: float = 3.0, rz: float = 3.0) -> OrbitTrail:
	var t            := OrbitTrail.new()
	t.radius_x       = rx;    t.radius_z      = rz
	t.width_start    = 0.25;  t.width_end     = 0.005
	t.alpha_start    = 1.0;   t.alpha_end     = 0.0
	t.width_exponent = 2.0;   t.alpha_exponent = 1.2
	t.trail_color    = Color(0.4, 0.85, 1.0)
	t.end_angle_deg  = 200.0
	return t

## Uniform-width closed orbit ring.
static func get_ring(rx: float = 3.0, rz: float = 3.0) -> OrbitTrail:
	var t         := OrbitTrail.new()
	t.radius_x    = rx;   t.radius_z  = rz
	t.width_start = 0.06; t.width_end = 0.06
	t.alpha_start = 0.9;  t.alpha_end = 0.9
	t.end_angle_deg = 359.9
	return t

## Dashed elliptical inclined orbit.
static func get_dashed_inclined(rx: float = 4.0, rz: float = 2.5, deg: float = 25.0) -> OrbitTrail:
	var t             := OrbitTrail.new()
	t.radius_x        = rx;   t.radius_z  = rz
	t.inclination_deg = deg
	t.solid           = false
	t.dash_ratio      = 0.55; t.dash_period = 1.0
	t.width_start     = 0.12; t.width_end   = 0.03
	t.alpha_start     = 1.0;  t.alpha_end   = 0.3
	t.trail_color     = Color(1.0, 0.85, 0.3)
	t.end_angle_deg   = 359.9
	return t

#endregion

# ──────────────────────────────────────────────────────────────────────────────
#region  Lifecycle
# ──────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_mat  = StandardMaterial3D.new()
	_mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	_mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh              = _mesh
	material_override = _mat
	_ready_done       = true
	draw()

func _exit_tree() -> void:
	_ready_done = false
	if _mesh is ImmediateMesh:
		_mesh.clear_surfaces()
	mesh              = null
	material_override = null
	_mesh             = null
	_mat              = null

#endregion

# ──────────────────────────────────────────────────────────────────────────────
#region  Public API
# ──────────────────────────────────────────────────────────────────────────────

func set_arc(p_start_deg: float, p_end_deg: float) -> void:
	start_angle_deg = p_start_deg
	end_angle_deg   = p_end_deg

func set_radii(rx: float, rz: float) -> void:
	radius_x = rx; radius_z = rz

func set_width_range(w_start: float, w_end: float) -> void:
	width_start = w_start; width_end = w_end

func set_alpha_range(a_start: float, a_end: float) -> void:
	alpha_start = a_start; alpha_end = a_end

func set_color(c: Color) -> void:
	trail_color = c

func set_solid(value: bool) -> void:
	solid = value

#endregion

# ──────────────────────────────────────────────────────────────────────────────
#region  Draw
# ──────────────────────────────────────────────────────────────────────────────

func draw() -> void:
	if not is_instance_valid(_mesh):
		return
	_mesh.clear_surfaces()

	# Span: always travel CCW from start → end.
	# If equal, treat as a full 360.
	var span_deg := end_angle_deg - start_angle_deg
	if span_deg <= 0.0:
		span_deg += 360.0
	span_deg = clamp(span_deg, 0.001, 360.0)

	# Camera position — use editor-friendly fallback when no runtime camera.
	var cam_pos  := Vector3.ZERO
	var have_cam := false
	if Engine.is_editor_hint():
		# Pick a point straight above the orbit center so the shape is visible
		# in the default top-down editor perspective.
		cam_pos  = center + Vector3(0.0, 50.0, 0.0)
		have_cam = true
	else:
		var vp  := get_viewport()
		var cam := vp.get_camera_3d() if vp else null
		if cam:
			cam_pos  = cam.global_position
			have_cam = true

	if not have_cam:
		return

	# Pre-build orbit points.
	var pts: Array[Vector3] = []
	pts.resize(segments + 1)
	for i in range(segments + 1):
		var frac  := float(i) / float(segments)
		var angle := start_angle_deg + frac * span_deg
		pts[i] = _orbit_point(angle)

	# ── Pass 1: bake one perp, width, and color per point ───────────────────
	# Using the averaged tangent across both neighbouring segments at each
	# interior point guarantees that adjacent quads share identical edge
	# positions → no gaps or overlaps at joints.
	var perps:  Array[Vector3] = []
	var widths: Array[float]   = []
	var colors: Array[Color]   = []
	perps.resize(segments + 1)
	widths.resize(segments + 1)
	colors.resize(segments + 1)

	for i in range(segments + 1):
		var t := float(i) / float(segments)

		# Averaged tangent: average the forward vectors of the prev and next
		# segments (clamped at the endpoints to just one segment).
		var prev := pts[max(i - 1, 0)]
		var next := pts[min(i + 1, segments)]
		var tangent := (next - prev)
		if tangent.length_squared() < 1e-10:
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()

		var to_cam := (cam_pos - pts[i]).normalized()
		var perp   := tangent.cross(to_cam)
		if perp.length_squared() < 1e-10:
			# Fallback: tangent is pointing straight at camera — use world up.
			perp = tangent.cross(Vector3.UP)
		perps[i]  = perp.normalized()
		widths[i] = _profile_width(t)
		colors[i] = Color(trail_color.r, trail_color.g, trail_color.b, _profile_alpha(t))

	# ── Pass 2: emit quads using the shared per-point data ───────────────────
	# Per-segment arc length for dash phase tracking.
	var seg_len  := (pts[1] - pts[0]).length() if segments > 0 else 0.001
	var dash_len := dash_period * dash_ratio
	var arc_dist := 0.0

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(segments):
		# ── Dash gate ────────────────────────────────────────────────────
		if not solid:
			var phase := fmod(arc_dist, dash_period)
			arc_dist  += seg_len
			if phase > dash_len:
				continue

		# Both endpoints share the same pre-baked perp so edges line up exactly.
		var p0 := pts[i];     var pa := perps[i];  var w0 := widths[i]; var c0 := colors[i]
		var p1 := pts[i + 1]; var pb := perps[i+1]; var w1 := widths[i+1]; var c1 := colors[i+1]

		_emit(p0 - pa * w0, c0)
		_emit(p0 + pa * w0, c0)
		_emit(p1 + pb * w1, c1)

		_emit(p1 + pb * w1, c1)
		_emit(p1 - pb * w1, c1)
		_emit(p0 - pa * w0, c0)

	_mesh.surface_end()

#endregion

# ──────────────────────────────────────────────────────────────────────────────
#region  Helpers
# ──────────────────────────────────────────────────────────────────────────────

## t = 0 → head (start_angle_deg), t = 1 → tail (end_angle_deg).
func _profile_width(t: float) -> float:
	return lerp(width_start, width_end, pow(t, width_exponent))

func _profile_alpha(t: float) -> float:
	return lerp(alpha_start, alpha_end, pow(t, alpha_exponent))

func _orbit_point(angle_deg: float) -> Vector3:
	var a     := deg_to_rad(angle_deg)
	var local := Vector3(cos(a) * radius_x, 0.0, sin(a) * radius_z)
	var inc   := deg_to_rad(inclination_deg)
	return center + Vector3(
		local.x,
		local.y * cos(inc) - local.z * sin(inc),
		local.y * sin(inc) + local.z * cos(inc)
	)

func _emit(v: Vector3, col: Color) -> void:
	_mesh.surface_set_color(col)
	_mesh.surface_add_vertex(v)

func _redraw() -> void:
	if _ready_done:
		draw()

#endregion
