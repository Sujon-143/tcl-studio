@tool
class_name Character
extends BaseShape2D

# ─────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────
signal animation_finished(anim_name: String)

# ─────────────────────────────────────────
#  Node refs
# ─────────────────────────────────────────
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var eyeball_1: Node2D = %eyeball1
@onready var eyeball_2: Node2D = %eyeball2
@onready var eye_1: Node2D = %eye1
@onready var eye_2: Node2D = %eye2

# ─────────────────────────────────────────
#  Eye tracking
# ─────────────────────────────────────────
@export var eye_radius: float = 10.0

@export var look_at_target: Marker2D = null:
	set(value):
		look_at_target = value
		setup()

# ─────────────────────────────────────────
#  Animation triggers (editor inspect‑boxes)
# ─────────────────────────────────────────
@export_group("Animation Triggers")

@export var play_blink: bool = false:
	set(value):
		if _setting_animated_prop: return
		_setting_animated_prop = true
		play_blink = value
		if value:
			play_animation("blinker", true)   # force one‑shot
		else:
			stop_animation()
		_setting_animated_prop = false

@export var play_hi: bool = false:
	set(value):
		if _setting_animated_prop: return
		_setting_animated_prop = true
		play_hi = value
		if value:
			play_animation("Hi", true)
		else:
			stop_animation()
		_setting_animated_prop = false

# ─────────────────────────────────────────
#  Internal
# ─────────────────────────────────────────
var _setting_animated_prop := false
var _current_animation := ""


func _ready() -> void:
	setup()


func setup() -> void:
	if Engine.is_editor_hint():
		_reset_eyeballs()
		return
	set_process(true)


func _process(_delta: float) -> void:
	if look_at_target:
		_update_eyeball(eyeball_1, eye_1)
		_update_eyeball(eyeball_2, eye_2)


func _update_eyeball(eyeball: Node2D, eye_socket: Node2D) -> void:
	var sock_pos := eye_socket.global_position
	var targ_pos := look_at_target.global_position
	var dir := (targ_pos - sock_pos).normalized()
	var dist := sock_pos.distance_to(targ_pos)
	eyeball.global_position = sock_pos + dir * minf(dist, eye_radius)


func _reset_eyeballs() -> void:
	if eyeball_1 and eye_1:
		eyeball_1.global_position = eye_1.global_position
	if eyeball_2 and eye_2:
		eyeball_2.global_position = eye_2.global_position


# ─────────────────────────────────────────
#  PUBLIC API – for external AnimationPlayers
# ─────────────────────────────────────────

##
## Play a named animation from this character’s AnimationPlayer.
## @param anim_name:     name of the animation (e.g. "blinker")
## @param force_no_loop: if true, temporarily set loop mode to NONE
##
func play_animation(anim_name: String, force_no_loop: bool = true) -> void:
	if not is_node_ready() or not animation_player:
		return

	if not animation_player.has_animation(anim_name):
		push_warning("Character: animation '" + anim_name + "' not found")
		return

	# Disconnect any previous finished signal
	if animation_player.animation_finished.is_connected(_on_anim_finished):
		animation_player.animation_finished.disconnect(_on_anim_finished)

	# Lock the animation to single‑shot if needed
	var anim := animation_player.get_animation(anim_name)
	if force_no_loop:
		anim.loop_mode = Animation.LOOP_NONE

	animation_player.play(anim_name)
	animation_player.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
	_current_animation = anim_name


##
## Stop the current animation and reset to the start.
##
func stop_animation(reset: bool = true) -> void:
	if not is_node_ready() or not animation_player:
		return

	if animation_player.animation_finished.is_connected(_on_anim_finished):
		animation_player.animation_finished.disconnect(_on_anim_finished)

	animation_player.stop()
	if reset:
		animation_player.seek(0.0, true)
	_current_animation = ""


func _on_anim_finished(anim_name: String) -> void:
	_current_animation = ""

	# Update the inspector booleans without recursion
	if not _setting_animated_prop:
		_setting_animated_prop = true
		match anim_name:
			"blinker": play_blink = false
			"Hi":      play_hi = false
		_setting_animated_prop = false

	animation_finished.emit(anim_name)
