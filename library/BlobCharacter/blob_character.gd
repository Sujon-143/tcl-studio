@tool
extends BaseNode3D
class_name BlobCharacter

# ══════════════════════════════════════════════════════════════════════════════
#  NODE REFERENCES
# ══════════════════════════════════════════════════════════════════════════════

@onready var body            : MeshInstance3D = %body
@onready var character_camera                 = %character_camera
@onready var eye_left        : MeshInstance3D = %eye_left
@onready var eye_right       : MeshInstance3D = %eye_right
@onready var hand_right      : MeshInstance3D = %hand_right
@onready var hand_left       : MeshInstance3D = %hand_left


# ══════════════════════════════════════════════════════════════════════════════
#  COLORS
# ══════════════════════════════════════════════════════════════════════════════

@export_group("Colors")

## When ON each part gets its own colour slot.
## When OFF the left-side colours drive both sides.
@export var separate_materials : bool = true:
	set(v): separate_materials = v; _build_materials()

@export var body_color : Color = Color(0.42, 0.47, 0.52):
	set(v): body_color = v; _apply_colors()

@export var eye_left_color  : Color = Color(0.12, 0.12, 0.15):
	set(v): eye_left_color = v; _apply_colors()
@export var eye_right_color : Color = Color(0.12, 0.12, 0.15):
	set(v): eye_right_color = v; _apply_colors()

@export var hand_left_color  : Color = Color(0.38, 0.43, 0.48):
	set(v): hand_left_color = v; _apply_colors()
@export var hand_right_color : Color = Color(0.38, 0.43, 0.48):
	set(v): hand_right_color = v; _apply_colors()


# ══════════════════════════════════════════════════════════════════════════════
#  MATERIAL OVERRIDES
# ══════════════════════════════════════════════════════════════════════════════

@export_group("Material Overrides")
@export var body_material       : StandardMaterial3D
@export var eye_left_material   : StandardMaterial3D
@export var eye_right_material  : StandardMaterial3D
@export var hand_left_material  : StandardMaterial3D
@export var hand_right_material : StandardMaterial3D


# ══════════════════════════════════════════════════════════════════════════════
#  BLINK
# ══════════════════════════════════════════════════════════════════════════════

@export_group("Blink")
@export var blink_enabled    : bool  = true:
	set(v): blink_enabled = v; _on_blink_enabled_changed()
## Average seconds between automatic blinks (±20 % random jitter)
@export var blink_interval   : float = 3.5
## Duration of the closing sweep
@export var blink_close_time : float = 0.055
## How long the eyes stay shut
@export var blink_hold_time  : float = 0.04
## Duration of the opening sweep
@export var blink_open_time  : float = 0.085


# ══════════════════════════════════════════════════════════════════════════════
#  HAND RAISE
# ══════════════════════════════════════════════════════════════════════════════

@export_group("Hand Raise")
## Seconds the hand stays raised before auto-lowering. 0 = stays up forever.
@export var hand_raise_hold_time : float = 1.5
## Rise / fall tween duration in seconds
@export var hand_raise_duration  : float = 0.40


# ══════════════════════════════════════════════════════════════════════════════
#  WALK
# ══════════════════════════════════════════════════════════════════════════════

@export_group("Walk")
@export var walk_speed      : float = 2.2   ## Steps per second
@export var walk_sway_angle : float = 6.0   ## Peak lateral body lean (degrees)
@export var walk_bob_height : float = 0.035 ## Peak vertical bob (metres)
@export var walk_hand_swing : float = 28.0  ## Hand swing arc (degrees, forward/back)
@export var walk_hand_shift : float = 0.06  ## Subtle forward/back hand position shift


# ══════════════════════════════════════════════════════════════════════════════
#  LOOK-AT
# ══════════════════════════════════════════════════════════════════════════════

@export_group("Look At")
## Assign in Inspector to make the blob track a node every frame.
@export var look_at_target : Node3D
## Smoothing factor. 0 = snap, 0.99 = very slow.
@export_range(0.0, 0.99) var look_smooth : float = 0.85
## When true the whole body tracks the target; when false only the Y axis turns.
@export var full_body_turn : bool = false


# ══════════════════════════════════════════════════════════════════════════════
#  PICK / REACH
# ══════════════════════════════════════════════════════════════════════════════

@export_group("Pick / Reach")
@export var reach_distance : float = 1.5
@export_enum("right", "left") var reach_hand : String = "right"


# ══════════════════════════════════════════════════════════════════════════════
#  PRIVATE — MATERIALS
# ══════════════════════════════════════════════════════════════════════════════

var _mat_body   : StandardMaterial3D
var _mat_eye_l  : StandardMaterial3D
var _mat_eye_r  : StandardMaterial3D
var _mat_hand_l : StandardMaterial3D
var _mat_hand_r : StandardMaterial3D


# ══════════════════════════════════════════════════════════════════════════════
#  PRIVATE — ANIMATION STATE
# ══════════════════════════════════════════════════════════════════════════════

var _blink_timer : float = 0.0
var _blinking    : bool  = false

var _walking  : bool  = false
var _walk_t   : float = 0.0

var _breathing : bool  = false
var _breath_t  : float = 0.0

var _looking      : bool    = false
var _look_target  : Vector3

# Per-track tween handles so animation tracks don't cancel each other
var _tween_hand_r : Tween
var _tween_hand_l : Tween
var _tween_body   : Tween
var _tween_lookat : Tween

# Cached rest poses — set once in _ready, never written by animations
var _rest_body_pos   : Vector3
var _rest_body_rot   : Vector3
var _rest_body_scale : Vector3
var _rest_hand_r_pos : Vector3
var _rest_hand_l_pos : Vector3
var _rest_hand_r_rot : Vector3
var _rest_hand_l_rot : Vector3


# ══════════════════════════════════════════════════════════════════════════════
#  LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_materials()
	_cache_rest()
	_reset_blink_timer()


func _process(delta: float) -> void:
	# Blink ticker — runs in both editor and game
	if blink_enabled and not _blinking:
		_blink_timer -= delta
		if _blink_timer <= 0.0:
			_do_blink()
			_reset_blink_timer()

	if _walking:
		_tick_walk(delta)

	if _breathing and not _walking:
		_tick_breathe(delta)

	# Physics-based look-at is skipped in the editor (no physics server running)
	if not Engine.is_editor_hint():
		if _looking or look_at_target != null:
			_tick_look_at(delta)


# ══════════════════════════════════════════════════════════════════════════════
#  TWEEN FACTORY  — works identically in editor and game
# ══════════════════════════════════════════════════════════════════════════════

func _tween() -> Tween:
	return create_tween()


## Awaitable timer that works in both editor and game.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# ══════════════════════════════════════════════════════════════════════════════
#  MATERIAL SYSTEM
# ══════════════════════════════════════════════════════════════════════════════

func _make_mat(color: Color) -> StandardMaterial3D:
	var m          := StandardMaterial3D.new()
	m.albedo_color  = color
	m.roughness     = 0.62
	m.metallic      = 0.04
	return m


func _build_materials() -> void:
	if not is_node_ready():
		return

	_mat_body = body_material if body_material else _make_mat(body_color)
	body.set_surface_override_material(0, _mat_body)

	if separate_materials:
		_mat_eye_l  = eye_left_material   if eye_left_material   else _make_mat(eye_left_color)
		_mat_eye_r  = eye_right_material  if eye_right_material  else _make_mat(eye_right_color)
		_mat_hand_l = hand_left_material  if hand_left_material  else _make_mat(hand_left_color)
		_mat_hand_r = hand_right_material if hand_right_material else _make_mat(hand_right_color)
	else:
		_mat_eye_l  = eye_left_material  if eye_left_material  else _make_mat(eye_left_color)
		_mat_eye_r  = _mat_eye_l
		_mat_hand_l = hand_left_material if hand_left_material else _make_mat(hand_left_color)
		_mat_hand_r = _mat_hand_l

	eye_left.set_surface_override_material(0,  _mat_eye_l)
	eye_right.set_surface_override_material(0, _mat_eye_r)
	hand_left.set_surface_override_material(0, _mat_hand_l)
	hand_right.set_surface_override_material(0, _mat_hand_r)


func _apply_colors() -> void:
	if not is_node_ready() or _mat_body == null:
		return
	if not body_material:       _mat_body.albedo_color  = body_color
	if not eye_left_material:   _mat_eye_l.albedo_color = eye_left_color
	if not hand_left_material:  _mat_hand_l.albedo_color = hand_left_color

	if separate_materials:
		if not eye_right_material:  _mat_eye_r.albedo_color  = eye_right_color
		if not hand_right_material: _mat_hand_r.albedo_color = hand_right_color


# ══════════════════════════════════════════════════════════════════════════════
#  REST-POSE CACHE
# ══════════════════════════════════════════════════════════════════════════════

func _cache_rest() -> void:
	if not is_node_ready():
		return
	_rest_body_pos   = body.position
	_rest_body_rot   = body.rotation_degrees
	_rest_body_scale = body.scale
	_rest_hand_r_pos = hand_right.position
	_rest_hand_l_pos = hand_left.position
	_rest_hand_r_rot = hand_right.rotation_degrees
	_rest_hand_l_rot = hand_left.rotation_degrees


# ══════════════════════════════════════════════════════════════════════════════
#  TWEEN HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _kill(t: Tween) -> void:
	if t != null and t.is_valid() and t.is_running():
		t.kill()


## Spring all parts back to rest pose and stop walk / breathe.
func restore_pose() -> void:
	_kill(_tween_hand_r)
	_kill(_tween_hand_l)
	_kill(_tween_body)
	_walking   = false
	_breathing = false

	var t := _tween().set_parallel(true)
	t.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	t.tween_property(body,       "position",          _rest_body_pos,   0.45)
	t.tween_property(body,       "rotation_degrees",  _rest_body_rot,   0.45)
	t.tween_property(body,       "scale",             _rest_body_scale, 0.45)
	t.tween_property(hand_right, "position",          _rest_hand_r_pos, 0.45)
	t.tween_property(hand_left,  "position",          _rest_hand_l_pos, 0.45)
	t.tween_property(hand_right, "rotation_degrees",  _rest_hand_r_rot, 0.45)
	t.tween_property(hand_left,  "rotation_degrees",  _rest_hand_l_rot, 0.45)
	_tween_body = t


# ══════════════════════════════════════════════════════════════════════════════
#  BLINK
#
#  Each eye mesh scales its Y axis: 1.0 → 0.05 → 1.0.
#  Close: EASE_IN (accelerates shut like a real lid).
#  Open:  EASE_OUT CUBIC (snaps open, eases at full).
# ══════════════════════════════════════════════════════════════════════════════

func _reset_blink_timer() -> void:
	_blink_timer = blink_interval * randf_range(0.80, 1.20)


func _on_blink_enabled_changed() -> void:
	if not blink_enabled and is_node_ready():
		eye_left.scale  = Vector3.ONE
		eye_right.scale = Vector3.ONE
		_blinking       = false


## Trigger a single natural blink immediately.
func blink_now() -> void:
	if _blinking or not is_node_ready():
		return
	_do_blink()


func _do_blink() -> void:
	if _blinking:
		return
	_blinking = true

	var close := _tween().set_parallel(true)
	close.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	close.tween_property(eye_left,  "scale", Vector3(1.0, 0.05, 1.0), blink_close_time)
	close.tween_property(eye_right, "scale", Vector3(1.0, 0.05, 1.0), blink_close_time)
	await close.finished

	if blink_hold_time > 0.0:
		await _wait(blink_hold_time)

	var open := _tween().set_parallel(true)
	open.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	open.tween_property(eye_left,  "scale", Vector3.ONE, blink_open_time)
	open.tween_property(eye_right, "scale", Vector3.ONE, blink_open_time)
	await open.finished

	_blinking = false


# ══════════════════════════════════════════════════════════════════════════════
#  HAND RAISE
# ══════════════════════════════════════════════════════════════════════════════

## Raise right hand. Auto-lowers after hand_raise_hold_time seconds (0 = stays up).
func raise_right_hand() -> void:
	_kill(_tween_hand_r)
	var t := _tween().set_parallel(true)
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(hand_right, "position",
		_rest_hand_r_pos + Vector3(0.0, 0.38, 0.05), hand_raise_duration)
	t.tween_property(hand_right, "rotation_degrees",
		_rest_hand_r_rot + Vector3(-15.0, 0.0, -60.0), hand_raise_duration)
	_tween_hand_r = t

	if hand_raise_hold_time > 0.0:
		await t.finished
		await _wait(hand_raise_hold_time)
		_lower_right_hand()


## Raise left hand. Auto-lowers after hand_raise_hold_time seconds (0 = stays up).
func raise_left_hand() -> void:
	_kill(_tween_hand_l)
	var t := _tween().set_parallel(true)
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(hand_left, "position",
		_rest_hand_l_pos + Vector3(0.0, 0.38, 0.05), hand_raise_duration)
	t.tween_property(hand_left, "rotation_degrees",
		_rest_hand_l_rot + Vector3(-15.0, 0.0, 60.0), hand_raise_duration)
	_tween_hand_l = t

	if hand_raise_hold_time > 0.0:
		await t.finished
		await _wait(hand_raise_hold_time)
		_lower_left_hand()


func _lower_right_hand() -> void:
	_kill(_tween_hand_r)
	var t := _tween().set_parallel(true)
	t.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	t.tween_property(hand_right, "position",         _rest_hand_r_pos, hand_raise_duration)
	t.tween_property(hand_right, "rotation_degrees", _rest_hand_r_rot, hand_raise_duration)
	_tween_hand_r = t


func _lower_left_hand() -> void:
	_kill(_tween_hand_l)
	var t := _tween().set_parallel(true)
	t.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	t.tween_property(hand_left, "position",         _rest_hand_l_pos, hand_raise_duration)
	t.tween_property(hand_left, "rotation_degrees", _rest_hand_l_rot, hand_raise_duration)
	_tween_hand_l = t


# ══════════════════════════════════════════════════════════════════════════════
#  WAVE  — lift → oscillate from raised position → lower
# ══════════════════════════════════════════════════════════════════════════════

func wave_right_hand(cycles: int = 3) -> void:
	_kill(_tween_hand_r)

	var lifted_pos := _rest_hand_r_pos + Vector3(0.0, 0.36, 0.08)
	var lifted_rot := _rest_hand_r_rot + Vector3(-10.0, 0.0, -50.0)

	var lift := _tween().set_parallel(true)
	lift.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lift.tween_property(hand_right, "position",         lifted_pos, 0.28)
	lift.tween_property(hand_right, "rotation_degrees", lifted_rot, 0.28)
	await lift.finished

	for _i in cycles:
		var w1 := _tween()
		w1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		w1.tween_property(hand_right, "rotation_degrees",
			lifted_rot + Vector3(0.0, 0.0, 28.0), 0.16)
		await w1.finished
		var w2 := _tween()
		w2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		w2.tween_property(hand_right, "rotation_degrees",
			lifted_rot + Vector3(0.0, 0.0, -28.0), 0.16)
		await w2.finished

	_lower_right_hand()


func wave_left_hand(cycles: int = 3) -> void:
	_kill(_tween_hand_l)

	var lifted_pos := _rest_hand_l_pos + Vector3(0.0, 0.36, 0.08)
	var lifted_rot := _rest_hand_l_rot + Vector3(-10.0, 0.0, 50.0)

	var lift := _tween().set_parallel(true)
	lift.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lift.tween_property(hand_left, "position",         lifted_pos, 0.28)
	lift.tween_property(hand_left, "rotation_degrees", lifted_rot, 0.28)
	await lift.finished

	for _i in cycles:
		var w1 := _tween()
		w1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		w1.tween_property(hand_left, "rotation_degrees",
			lifted_rot + Vector3(0.0, 0.0, -28.0), 0.16)
		await w1.finished
		var w2 := _tween()
		w2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		w2.tween_property(hand_left, "rotation_degrees",
			lifted_rot + Vector3(0.0, 0.0, 28.0), 0.16)
		await w2.finished

	_lower_left_hand()


# ══════════════════════════════════════════════════════════════════════════════
#  WALK  — fully procedural, per-frame
#
#  Body bobs UP on each foot-fall (abs-sine, double frequency).
#  Body leans L/R in sync (single sine, opposite phase to bob peak).
#  Tiny constant forward lean gives momentum feel.
#  Hands swing fwd/back in opposite phase with subtle positional shift.
# ══════════════════════════════════════════════════════════════════════════════

func start_walk() -> void:
	_kill(_tween_hand_r)
	_kill(_tween_hand_l)
	_kill(_tween_body)
	_breathing = false
	_walking   = true
	_walk_t    = 0.0

func stop_walk() -> void:
	_walking = false
	restore_pose()

func toggle_walk() -> void:
	if _walking: stop_walk()
	else:        start_walk()


func _tick_walk(delta: float) -> void:
	_walk_t += delta * walk_speed * TAU

	var step_phase := _walk_t * 2.0
	var bob        :float= abs(sin(step_phase)) * walk_bob_height
	var sway       := sin(_walk_t) * deg_to_rad(walk_sway_angle)
	var lean_x     := 3.5 + sin(_walk_t * 0.5) * 1.2

	body.position        = _rest_body_pos + Vector3(0.0, bob, 0.0)
	body.rotation_degrees = _rest_body_rot + Vector3(lean_x, 0.0, rad_to_deg(sway))

	var rh_angle := sin(_walk_t)       * walk_hand_swing
	var lh_angle := sin(_walk_t + PI)  * walk_hand_swing
	var rh_bob   :float= abs(sin(step_phase))       * (walk_bob_height * 0.35)
	var lh_bob   :float= abs(sin(step_phase + PI))  * (walk_bob_height * 0.35)

	hand_right.rotation_degrees = _rest_hand_r_rot + Vector3(rh_angle, 0.0, 0.0)
	hand_left.rotation_degrees  = _rest_hand_l_rot + Vector3(lh_angle, 0.0, 0.0)
	hand_right.position = _rest_hand_r_pos + Vector3(-sin(_walk_t)      * walk_hand_shift, rh_bob, 0.0)
	hand_left.position  = _rest_hand_l_pos + Vector3(-sin(_walk_t + PI) * walk_hand_shift, lh_bob, 0.0)


# ══════════════════════════════════════════════════════════════════════════════
#  IDLE BREATHE  — asymmetric inhale/exhale with smoothstep corners
#
#  Inhale = first 40 % of cycle (fast)
#  Exhale = remaining 60 %       (slow)
#  Chest expands on Y and Z; barely on X. Body rises very slightly on inhale.
# ══════════════════════════════════════════════════════════════════════════════

func start_breathe() -> void:
	_breathing = true
	_breath_t  = 0.0

func stop_breathe() -> void:
	_breathing = false
	var t := _tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(body, "scale",    _rest_body_scale, 0.6)
	t.parallel().tween_property(body, "position", _rest_body_pos,  0.6)

func toggle_breathe() -> void:
	if _breathing: stop_breathe()
	else:          start_breathe()


func _tick_breathe(delta: float) -> void:
	_breath_t = fmod(_breath_t + delta * 0.26, 1.0)   # ~3.8 s full cycle

	var t   : float = _breath_t
	var raw : float = (t / 0.4) if t < 0.4 else (1.0 - (t - 0.4) / 0.6)
	var phase : float = raw * raw * (3.0 - 2.0 * raw)  # smoothstep

	body.scale    = Vector3(1.0 + phase * 0.016, 1.0 + phase * 0.048, 1.0 + phase * 0.030)
	body.position = _rest_body_pos + Vector3(0.0, phase * 0.013, 0.0)


# ══════════════════════════════════════════════════════════════════════════════
#  BOUNCE / NOD / SHAKE
# ══════════════════════════════════════════════════════════════════════════════

func bounce(count: int = 2) -> void:
	restore_pose()
	await get_tree().process_frame
	for _i in count:
		var sq := _tween().set_parallel(true)
		sq.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		sq.tween_property(body, "scale",    Vector3(1.12, 0.88, 1.12), 0.10)
		sq.tween_property(body, "position", _rest_body_pos + Vector3(0.0, -0.04, 0.0), 0.10)
		await sq.finished
		var st := _tween().set_parallel(true)
		st.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		st.tween_property(body, "scale",    Vector3(0.92, 1.14, 0.92), 0.16)
		st.tween_property(body, "position", _rest_body_pos + Vector3(0.0, 0.12, 0.0), 0.16)
		await st.finished
		var settle := _tween().set_parallel(true)
		settle.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		settle.tween_property(body, "scale",    _rest_body_scale, 0.30)
		settle.tween_property(body, "position", _rest_body_pos,   0.30)
		await settle.finished


func nod(count: int = 2) -> void:
	restore_pose()
	await get_tree().process_frame
	for _i in count:
		var fwd := _tween()
		fwd.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fwd.tween_property(body, "rotation_degrees",
			_rest_body_rot + Vector3(14.0, 0.0, 0.0), 0.13)
		await fwd.finished
		var back := _tween()
		back.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		back.tween_property(body, "rotation_degrees", _rest_body_rot, 0.13)
		await back.finished
	restore_pose()


func shake_head(count: int = 3) -> void:
	restore_pose()
	await get_tree().process_frame
	for _i in count:
		var r := _tween()
		r.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		r.tween_property(body, "rotation_degrees",
			_rest_body_rot + Vector3(0.0, 20.0, 0.0), 0.09)
		await r.finished
		var l := _tween()
		l.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		l.tween_property(body, "rotation_degrees",
			_rest_body_rot + Vector3(0.0, -20.0, 0.0), 0.09)
		await l.finished
	restore_pose()


# ══════════════════════════════════════════════════════════════════════════════
#  LOOK-AT SYSTEM  (game-only — no physics in editor)
# ══════════════════════════════════════════════════════════════════════════════

## Start smoothly tracking a fixed world-space position every frame.
func look_at_position(world_pos: Vector3) -> void:
	_look_target = world_pos
	_looking     = true


## Stop runtime tracking and spring back to rest Y rotation.
func stop_looking() -> void:
	_looking = false
	_kill(_tween_lookat)
	var t := _tween()
	t.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "rotation_degrees",
		Vector3(rotation_degrees.x, 0.0, rotation_degrees.z), 0.5)
	_tween_lookat = t


func _tick_look_at(delta: float) -> void:
	var target : Vector3 = look_at_target.global_position if look_at_target != null else _look_target
	var dir    : Vector3 = (target - global_position)
	if dir.length_squared() < 0.001:
		return
	dir = dir.normalized()

	var desired_basis := Basis.looking_at(-dir, Vector3.UP)
	var desired_euler := desired_basis.get_euler()
	var t : float     = 1.0 - pow(look_smooth, delta * 60.0)

	if full_body_turn:
		rotation = rotation.lerp(desired_euler, t)
	else:
		rotation.y = lerp_angle(rotation.y, desired_euler.y, t)


## Instantly snap to face a world-space position.
func face_toward(world_pos: Vector3) -> void:
	var dir := (world_pos - global_position).normalized()
	if dir.length_squared() < 0.001:
		return
	var b := Basis.looking_at(-dir, Vector3.UP)
	if full_body_turn: rotation = b.get_euler()
	else:              rotation.y = b.get_euler().y


## Tween-based smooth turn toward a world-space position.
func turn_toward(world_pos: Vector3, duration: float = 0.45) -> void:
	var dir := (world_pos - global_position).normalized()
	if dir.length_squared() < 0.001:
		return
	var target_y_rad := Basis.looking_at(-dir, Vector3.UP).get_euler().y
	var target_deg   := Vector3(rotation_degrees.x, rad_to_deg(target_y_rad), rotation_degrees.z)
	_kill(_tween_lookat)
	var t := _tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "rotation_degrees", target_deg, duration)
	_tween_lookat = t


# ══════════════════════════════════════════════════════════════════════════════
#  PICK / REACH FROM FRONT  (game-only — physics not available in editor)
#
#  Casts a ray along the blob's forward (-X) axis up to reach_distance.
#  Animates the chosen hand to extend toward the hit, pauses, then retracts.
#  Returns the collider Object if anything was hit, otherwise null.
# ══════════════════════════════════════════════════════════════════════════════

func pick_object_from_front() -> Object:
	if Engine.is_editor_hint():
		push_warning("BlobCharacter: pick_object_from_front() is not available in the editor.")
		return null
	if not is_inside_tree():
		return null

	var space   := get_world_3d().direct_space_state
	var origin  := global_position + Vector3(0.0, 0.1, 0.0)
	var forward := -global_transform.basis.x
	var dest    := origin + forward * reach_distance

	var query    := PhysicsRayQueryParameters3D.create(origin, dest)
	query.exclude = [self]
	var result   := space.intersect_ray(query)

	var is_right  : bool            = (reach_hand == "right")
	var hand_node : MeshInstance3D  = hand_right if is_right else hand_left
	var rest_pos  : Vector3         = _rest_hand_r_pos if is_right else _rest_hand_l_pos
	var rest_rot  : Vector3         = _rest_hand_r_rot if is_right else _rest_hand_l_rot

	if result.is_empty():
		_reach_and_retract(hand_node, rest_pos, rest_rot, rest_pos + forward * 0.30)
		return null

	_reach_and_retract(hand_node, rest_pos, rest_rot, to_local(result.position))
	return result.get("collider")


func _reach_and_retract(
		hand_node    : MeshInstance3D,
		rest_pos     : Vector3,
		rest_rot     : Vector3,
		local_target : Vector3
) -> void:
	var extend := _tween().set_parallel(true)
	extend.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	extend.tween_property(hand_node, "position",         local_target,                   0.22)
	extend.tween_property(hand_node, "rotation_degrees", rest_rot + Vector3(-22.0, 0, 0), 0.22)
	await extend.finished

	await _wait(0.15)

	var retract := _tween().set_parallel(true)
	retract.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	retract.tween_property(hand_node, "position",         rest_pos, 0.35)
	retract.tween_property(hand_node, "rotation_degrees", rest_rot, 0.35)
	await retract.finished


# ══════════════════════════════════════════════════════════════════════════════
#  EDITOR TOOL BUTTONS  (Godot 4.3+)
# ══════════════════════════════════════════════════════════════════════════════

func _get_tool_buttons() -> Array:
	return [
		{ "name": "👁  Blink Now",           "pressed": blink_now              },
		{ "name": "🤚 Raise Right Hand",     "pressed": raise_right_hand       },
		{ "name": "🤚 Raise Left Hand",      "pressed": raise_left_hand        },
		{ "name": "👋 Wave Right",           "pressed": wave_right_hand        },
		{ "name": "👋 Wave Left",            "pressed": wave_left_hand         },
		{ "name": "🚶 Toggle Walk",          "pressed": toggle_walk            },
		{ "name": "💨 Toggle Breathe",       "pressed": toggle_breathe         },
		{ "name": "🎉 Bounce",               "pressed": bounce                 },
		{ "name": "✅ Nod",                  "pressed": nod                    },
		{ "name": "❌ Shake Head",           "pressed": shake_head             },
		{ "name": "🖐  Pick From Front",     "pressed": pick_object_from_front },
		{ "name": "↺  Restore Pose",         "pressed": restore_pose           },
	]
