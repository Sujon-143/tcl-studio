@tool
extends Node2D
class_name NeuralNetwork2D

# ─────────────────────────────────────────────────────────────────────────────
#  NETWORK TOPOLOGY
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Network Topology")

## Number of neurons per layer. e.g. [2, 3, 2, 1] = input(2), hidden(3), hidden(2), output(1).
@export var layer_sizes: Array[int] = [2, 3, 2, 1]:
	set(v):
		layer_sizes = v
		_rebuild_network_data()
		queue_redraw()

## Horizontal spacing between layers in local units.
@export_range(20.0, 600.0, 1.0, "or_greater") var layer_spacing: float = 120.0:
	set(v):
		layer_spacing = v
		_rebuild_network_data()
		queue_redraw()

## Vertical spacing between neurons within a layer in local units.
@export_range(10.0, 400.0, 1.0, "or_greater") var neuron_spacing: float = 70.0:
	set(v):
		neuron_spacing = v
		_rebuild_network_data()
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  VISUAL PROPERTIES — NEURONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Visual — Neurons")

## Radius of each neuron circle.
@export_range(2.0, 200.0, 1.0, "or_greater") var neuron_radius: float = 18.0:
	set(v):
		neuron_radius = v
		queue_redraw()

## Fill color of idle neurons.
@export var neuron_fill_color: Color = Color(0.12, 0.14, 0.22, 1.0):
	set(v):
		neuron_fill_color = v
		queue_redraw()

## Stroke color of idle neurons.
@export var neuron_stroke_color: Color = Color(0.45, 0.55, 0.9, 1.0):
	set(v):
		neuron_stroke_color = v
		queue_redraw()

## Stroke width of idle neurons.
@export_range(0.0, 20.0, 0.1, "or_greater") var neuron_stroke_width: float = 2.0:
	set(v):
		neuron_stroke_width = v
		queue_redraw()

## Fill color when a neuron is "activated" during forward pass.
@export var neuron_active_color: Color = Color(0.3, 0.85, 0.6, 1.0):
	set(v):
		neuron_active_color = v
		queue_redraw()

## Fill color of the output neuron(s) when showing error state.
@export var neuron_error_color: Color = Color(0.9, 0.3, 0.35, 1.0):
	set(v):
		neuron_error_color = v
		queue_redraw()

## Fill color during backprop gradient highlight.
@export var neuron_grad_color: Color = Color(0.95, 0.75, 0.2, 1.0):
	set(v):
		neuron_grad_color = v
		queue_redraw()

## Number of segments used to draw each neuron circle (quality).
@export_range(6, 128, 1, "or_greater") var neuron_segments: int = 32:
	set(v):
		neuron_segments = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  VISUAL PROPERTIES — CONNECTIONS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Visual — Connections")

## Color of idle connection lines.
@export var connection_color: Color = Color(0.35, 0.4, 0.65, 0.5):
	set(v):
		connection_color = v
		queue_redraw()

## Width of idle connection lines.
## NOTE: previously hard-capped at 6.0 which made big AnimationPlayer sweeps
## invisible/clamped. Now open-ended via "or_greater".
@export_range(0.0, 20.0, 0.1, "or_greater") var connection_width: float = 1.0:
	set(v):
		connection_width = v
		queue_redraw()

## Color of a connection during forward‑pass signal travel.
@export var connection_forward_color: Color = Color(0.3, 0.85, 0.6, 0.9):
	set(v):
		connection_forward_color = v
		queue_redraw()

## Color of a connection during backprop gradient travel.
@export var connection_backprop_color: Color = Color(0.95, 0.75, 0.2, 0.9):
	set(v):
		connection_backprop_color = v
		queue_redraw()

## Width of an active (forward/backprop) connection.
@export_range(0.0, 24.0, 0.1, "or_greater") var connection_active_width: float = 2.5:
	set(v):
		connection_active_width = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  VISUAL PROPERTIES — LABELS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Visual — Labels")

## Show weight values on connection lines.
@export var show_weights: bool = true:
	set(v):
		show_weights = v
		queue_redraw()

## Sideways offset of weight labels from the connection line.
@export_range(0.0, 60.0, 0.5, "or_greater") var weight_label_offset: float = 8.0:
	set(v):
		weight_label_offset = v
		queue_redraw()

## How far weight labels stagger ALONG the line based on which src/dst neuron
## pair they belong to (0 = all labels stuck at the exact midpoint and will
## overlap on dense layers; higher = labels fan out along the connection).
@export_range(0.0, 0.45, 0.01, "or_greater") var weight_label_spread: float = 0.18:
	set(v):
		weight_label_spread = v
		queue_redraw()

## Show bias values inside neurons.
@export var show_biases: bool = true:
	set(v):
		show_biases = v
		queue_redraw()

## Show activation values inside neurons (replaces bias label when visible).
@export var show_activations: bool = false:
	set(v):
		show_activations = v
		queue_redraw()

## Font size for all labels.
## NOTE: previously typed `int`. AnimationPlayer tracks on int properties default
## to DISCRETE interpolation (snap-at-keyframe) instead of Continuous, so this
## looked like it "wasn't redrawing" between keys. Now a float — smoothly
## tweens — and gets rounded to an int only at the draw_string() call sites.
@export_range(1.0, 96.0, 0.5, "or_greater") var label_font_size: float = 9.0:
	set(v):
		label_font_size = v
		queue_redraw()

## Color of weight labels.
@export var weight_label_color: Color = Color(0.75, 0.8, 1.0, 0.8):
	set(v):
		weight_label_color = v
		queue_redraw()

## Color of bias/activation labels.
@export var neuron_label_color: Color = Color(1.0, 1.0, 1.0, 0.9):
	set(v):
		neuron_label_color = v
		queue_redraw()

## Color of error/delta labels drawn near output neurons.
@export var error_label_color: Color = Color(0.9, 0.3, 0.35, 1.0):
	set(v):
		error_label_color = v
		queue_redraw()

## Opacity multiplier applied to ALL labels (0 = hidden, 1 = full).
@export_range(0.0, 1.0, 0.01) var label_opacity: float = 1.0:
	set(v):
		label_opacity = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  DUMMY DATA — weights / biases / activations / errors / deltas
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Dummy Data")

## Seed for deterministic random generation of weights/biases.
@export var data_seed: int = 42:
	set(v):
		data_seed = v
		_rebuild_network_data()
		queue_redraw()

## Range for randomly generated weight values (symmetric around 0).
@export_range(0.1, 3.0, 0.05, "or_greater") var weight_range: float = 1.0:
	set(v):
		weight_range = v
		_rebuild_network_data()
		queue_redraw()

## Range for randomly generated bias values (symmetric around 0).
@export_range(0.1, 3.0, 0.05, "or_greater") var bias_range: float = 0.5:
	set(v):
		bias_range = v
		_rebuild_network_data()
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — BUILD
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Build")

## 0 = nothing visible, 1 = entire network drawn.
## Neurons appear layer by layer as progress sweeps 0→1.
@export_range(0.0, 1.0, 0.01) var build_progress: float = 1.0:
	set(v):
		build_progress = v
		queue_redraw()

## 0 = no connections, 1 = all connections drawn.
## Connections are revealed after their source layer neuron appears.
@export_range(0.0, 1.0, 0.01) var connection_draw_progress: float = 1.0:
	set(v):
		connection_draw_progress = v
		queue_redraw()

## Fade-in opacity of the whole network (independent of modulate.a).
@export_range(0.0, 1.0, 0.01) var network_fade: float = 1.0:
	set(v):
		network_fade = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — FORWARD PASS
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Forward Pass")

## Drives the forward‑pass signal sweep left→right across the whole network.
## 0 = at input, 1 = output neurons fully activated.
@export_range(0.0, 1.0, 0.01) var forward_pass_progress: float = 0.0:
	set(v):
		forward_pass_progress = v
		queue_redraw()

## How wide (in progress space) the traveling "pulse" front is.
## Smaller = sharper wavefront, larger = more gradual fade.
@export_range(0.01, 0.5, 0.01, "or_greater") var forward_pulse_width: float = 0.15:
	set(v):
		forward_pulse_width = v
		queue_redraw()

## Brightness multiplier at the peak of the forward‑pass pulse.
@export_range(1.0, 4.0, 0.05, "or_greater") var forward_pulse_brightness: float = 2.0:
	set(v):
		forward_pulse_brightness = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — ERROR DISPLAY
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Error Display")

## 0 = no error shown, 1 = error labels and highlights fully visible at output.
@export_range(0.0, 1.0, 0.01) var error_display_progress: float = 0.0:
	set(v):
		error_display_progress = v
		queue_redraw()

## Scale of the error "burst" ring drawn around output neurons at peak.
@export_range(0.5, 6.0, 0.05, "or_greater") var error_burst_scale: float = 1.4:
	set(v):
		error_burst_scale = v
		queue_redraw()

## Stroke color of the error burst ring.
@export var error_burst_color: Color = Color(0.9, 0.3, 0.35, 0.85):
	set(v):
		error_burst_color = v
		queue_redraw()

## Stroke width of the error burst ring.
@export_range(0.0, 20.0, 0.1, "or_greater") var error_burst_width: float = 2.5:
	set(v):
		error_burst_width = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — BACKPROPAGATION
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Backpropagation")

## Drives the gradient sweep right→left across the network.
## 0 = at output, 1 = gradients fully reach input layer.
@export_range(0.0, 1.0, 0.01) var backprop_progress: float = 0.0:
	set(v):
		backprop_progress = v
		queue_redraw()

## Width of the backprop gradient pulse front (in progress space).
@export_range(0.01, 0.5, 0.01, "or_greater") var backprop_pulse_width: float = 0.18:
	set(v):
		backprop_pulse_width = v
		queue_redraw()

## Brightness multiplier at the peak of the backprop pulse.
@export_range(1.0, 4.0, 0.05, "or_greater") var backprop_pulse_brightness: float = 1.8:
	set(v):
		backprop_pulse_brightness = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — WEIGHT CORRECTION
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Weight Correction")

## 0 = weights/biases at original values, 1 = updated values.
## Interpolates the displayed dummy numbers between old and new.
@export_range(0.0, 1.0, 0.01) var weight_correction_progress: float = 0.0:
	set(v):
		weight_correction_progress = v
		queue_redraw()

## Flash color pulsed onto connections as their weight updates.
@export var weight_update_flash_color: Color = Color(1.0, 0.9, 0.4, 1.0):
	set(v):
		weight_update_flash_color = v
		queue_redraw()

## Width (in progress space) of each connection's update flash.
@export_range(0.01, 0.3, 0.01, "or_greater") var weight_flash_width: float = 0.08:
	set(v):
		weight_flash_width = v
		queue_redraw()

## Scale factor applied to the updated bias value labels during correction.
## Values > 1 exaggerate the change for visual clarity.
@export_range(1.0, 5.0, 0.1, "or_greater") var learning_rate_display: float = 1.0:
	set(v):
		learning_rate_display = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION — HIGHLIGHT / INDICATE
# ─────────────────────────────────────────────────────────────────────────────
@export_category("Animation — Highlight")

## Index of the layer to highlight (-1 = none).
@export_range(-1, 32, 1, "or_greater") var highlight_layer: int = -1:
	set(v):
		highlight_layer = v
		queue_redraw()

## Index of the neuron within highlight_layer to highlight (-1 = whole layer).
@export_range(-1, 128, 1, "or_greater") var highlight_neuron: int = -1:
	set(v):
		highlight_neuron = v
		queue_redraw()

## 0 = no highlight ring, 1 = full ring. Animatable for a pulse effect.
@export_range(0.0, 1.0, 0.01) var highlight_progress: float = 0.0:
	set(v):
		highlight_progress = v
		queue_redraw()

## Color of the highlight ring.
@export var highlight_color: Color = Color(1.0, 1.0, 1.0, 0.9):
	set(v):
		highlight_color = v
		queue_redraw()

## Width of the highlight ring stroke.
@export_range(0.0, 20.0, 0.1, "or_greater") var highlight_ring_width: float = 2.0:
	set(v):
		highlight_ring_width = v
		queue_redraw()

## Gap between the neuron edge and the highlight ring.
@export_range(0.0, 60.0, 0.5, "or_greater") var highlight_ring_gap: float = 5.0:
	set(v):
		highlight_ring_gap = v
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
#  INTERNAL STATE
# ─────────────────────────────────────────────────────────────────────────────

# _neuron_positions[layer][neuron] → Vector2 in local space
var _neuron_positions: Array = []

# _weights[layer][dst_neuron][src_neuron]  (layer 0 = connections from layer0→layer1)
var _weights: Array = []
var _weights_updated: Array = []   # post-correction target values

# _biases[layer][neuron]  (layer 0 = input layer biases)
var _biases: Array = []
var _biases_updated: Array = []

# _activations[layer][neuron]  — dummy sigmoid-like outputs
var _activations: Array = []

# _deltas[layer][neuron]  — dummy gradient deltas
var _deltas: Array = []

# _errors[neuron]  — per-output-neuron errors (target - activation)
var _errors: Array = []

# Total connection count (for mapping forward/backprop progress to individual edges)
var _total_connections: int = 0

# ─────────────────────────────────────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_rebuild_network_data()

# ─────────────────────────────────────────────────────────────────────────────
#  DATA GENERATION
# ─────────────────────────────────────────────────────────────────────────────
func _rebuild_network_data() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data_seed

	_neuron_positions.clear()
	_weights.clear()
	_weights_updated.clear()
	_biases.clear()
	_biases_updated.clear()
	_activations.clear()
	_deltas.clear()
	_errors.clear()
	_total_connections = 0

	var num_layers := layer_sizes.size()
	if num_layers == 0:
		return

	# Compute centered neuron positions
	for li in num_layers:
		var n := layer_sizes[li]
		var layer_positions: Array[Vector2] = []
		var total_height := (n - 1) * neuron_spacing
		for ni in n:
			var x := li * layer_spacing
			var y := ni * neuron_spacing - total_height * 0.5
			layer_positions.append(Vector2(x, y))
		_neuron_positions.append(layer_positions)

	# Generate dummy weights, biases, activations, deltas
	for li in num_layers:
		var n := layer_sizes[li]
		var b_layer: Array[float] = []
		var b_updated_layer: Array[float] = []
		var a_layer: Array[float] = []
		var d_layer: Array[float] = []
		for ni in n:
			b_layer.append(rng.randf_range(-bias_range, bias_range))
			b_updated_layer.append(rng.randf_range(-bias_range, bias_range))
			a_layer.append(rng.randf_range(0.05, 0.95))   # dummy activation
			d_layer.append(rng.randf_range(-0.5, 0.5))    # dummy delta
		_biases.append(b_layer)
		_biases_updated.append(b_updated_layer)
		_activations.append(a_layer)
		_deltas.append(d_layer)

	# Weights between consecutive layers
	for li in num_layers - 1:
		var src_n := layer_sizes[li]
		var dst_n := layer_sizes[li + 1]
		var w_dst: Array = []
		var wu_dst: Array = []
		for di in dst_n:
			var w_src: Array[float] = []
			var wu_src: Array[float] = []
			for si in src_n:
				w_src.append(rng.randf_range(-weight_range, weight_range))
				wu_src.append(rng.randf_range(-weight_range, weight_range))
				_total_connections += 1
			w_dst.append(w_src)
			wu_dst.append(wu_src)
		_weights.append(w_dst)
		_weights_updated.append(wu_dst)

	# Dummy errors at output layer
	var out_n := layer_sizes[-1]
	for ni in out_n:
		_errors.append(rng.randf_range(-0.6, 0.6))

# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────

## Returns fraction [0,1] of how visible layer `li` is given `build_progress`.
## Layers appear sequentially as progress sweeps 0→1.
func _layer_visibility(li: int) -> float:
	var num_layers := layer_sizes.size()
	if num_layers <= 1:
		return 1.0
	# Each layer has a threshold; when progress passes it, visibility goes 0→1.
	var threshold := float(li) / float(num_layers - 1)
	var ramp := 1.0 / float(num_layers - 1)
	return clampf((build_progress - threshold) / ramp, 0.0, 1.0)

## Returns fraction [0,1] of how visible the connection from layer li→li+1,
## src neuron si → dst neuron di is, given `connection_draw_progress`.
## Also accounts for build_progress of the source layer.
func _connection_visibility(li: int, _si: int, _di: int, conn_global_index: int) -> float:
	var layer_vis := _layer_visibility(li) * _layer_visibility(li + 1)
	if layer_vis <= 0.0:
		return 0.0
	if _total_connections == 0:
		return 0.0
	# Connections also stagger based on connection_draw_progress
	var threshold := float(conn_global_index) / float(_total_connections)
	var ramp := 1.0 / float(_total_connections)
	var conn_vis := clampf((connection_draw_progress - threshold) / ramp, 0.0, 1.0)
	return layer_vis * conn_vis

## Gaussian-like bell centered at `center`, width `w`, in [0,1] range.
func _pulse(progress: float, center: float, w: float) -> float:
	var d := (progress - center) / maxf(w, 0.001)
	return clampf(exp(-d * d * 4.0), 0.0, 1.0)

## Sigmoid for display formatting.
func _sig(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))

## Format a float to 2 decimal places as string.
func _fmt(v: float) -> String:
	return "%.2f" % v

## Integer font size for draw_string() calls (label_font_size is a float
## so it can be smoothly keyframed in AnimationPlayer).
func _font_px() -> int:
	return int(round(label_font_size))

# ─────────────────────────────────────────────────────────────────────────────
#  DRAW
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if layer_sizes.is_empty() or _neuron_positions.is_empty():
		return

	var num_layers := layer_sizes.size()
	var base_alpha := network_fade
	var font_px := _font_px()

	# ── 1. CONNECTIONS ────────────────────────────────────────────────────────
	var conn_idx := 0
	for li in num_layers - 1:
		if li >= _weights.size():
			break
		var src_positions: Array = _neuron_positions[li]
		var dst_positions: Array = _neuron_positions[li + 1]
		var src_n := layer_sizes[li]
		var dst_n := layer_sizes[li + 1]

		# Normalized position of this layer-pair for pulse math
		var layer_forward_t := float(li + 1) / float(num_layers - 1) if num_layers > 1 else 1.0
		var layer_back_t := float(num_layers - 2 - li) / float(num_layers - 1) if num_layers > 1 else 0.0

		for di in dst_n:
			for si in src_n:
				var vis := _connection_visibility(li, si, di, conn_idx)
				if vis <= 0.0:
					conn_idx += 1
					continue

				var p_from: Vector2 = src_positions[si]
				var p_to: Vector2 = dst_positions[di]

				# Trim lines to neuron edges
				var dir := (p_to - p_from).normalized()
				var p_start := p_from + dir * neuron_radius
				var p_end   := p_to   - dir * neuron_radius

				# --- Base connection color (without visibility factor yet) ---
				var base_col := connection_color

				# --- Pulse intensities ---
				var fwd_pulse := _pulse(forward_pass_progress, layer_forward_t, forward_pulse_width)
				var bp_pulse  := _pulse(backprop_progress, layer_back_t, backprop_pulse_width)

				# --- Weight correction flash ---
				var conn_t := float(conn_idx) / float(maxf(_total_connections, 1))
				var wf_pulse := _pulse(weight_correction_progress, conn_t, weight_flash_width)

				var line_w := connection_width
				var col: Color

				if wf_pulse > 0.01:
					# Blend with flash color, then apply visibility
					col = weight_update_flash_color.lerp(base_col, 1.0 - wf_pulse)
					col.a = lerpf(weight_update_flash_color.a, base_col.a, 1.0 - wf_pulse) * vis * base_alpha
					line_w = lerpf(connection_width, connection_active_width * 1.5, wf_pulse)
				elif fwd_pulse > 0.01:
					col = base_col.lerp(connection_forward_color, fwd_pulse)
					col.a = lerpf(base_col.a, connection_forward_color.a, fwd_pulse) * vis * base_alpha
					line_w = lerpf(connection_width, connection_active_width, fwd_pulse)
				elif bp_pulse > 0.01:
					col = base_col.lerp(connection_backprop_color, bp_pulse)
					col.a = lerpf(base_col.a, connection_backprop_color.a, bp_pulse) * vis * base_alpha
					line_w = lerpf(connection_width, connection_active_width, bp_pulse)
				else:
					col = base_col
					col.a *= vis * base_alpha

				draw_line(p_start, p_end, col, line_w, true)

				# --- Weight label (staggered along the line to avoid overlap) ---
				if show_weights and label_opacity > 0.01 and vis > 0.5:
					var w_cur: float = _weights[li][di][si]
					var w_new: float = _weights_updated[li][di][si]
					var w_disp := lerpf(w_cur, w_new, weight_correction_progress)
					# All connections between two layers share the same midpoint x,
					# and symmetric (si,di)/(di,si) pairs share the exact same
					# midpoint — so labels can't all sit at t=0.5. Stagger each
					# label's position along the line based on its src/dst pair.
					var si_t := float(si) / float(maxi(src_n - 1, 1))
					var di_t := float(di) / float(maxi(dst_n - 1, 1))
					var stagger := (si_t - di_t) * weight_label_spread
					var t := clampf(0.5 + stagger, 0.12, 0.88)
					var mid := p_start.lerp(p_end, t)
					# Perpendicular offset to avoid overlapping the line itself
					var perp := Vector2(-dir.y, dir.x) * weight_label_offset
					var lbl_pos := mid + perp
					var lbl_col := weight_label_color
					lbl_col.a *= label_opacity * vis * base_alpha
					if wf_pulse > 0.3:
						lbl_col = weight_update_flash_color
						lbl_col.a *= label_opacity * vis * base_alpha
					draw_string(
						ThemeDB.fallback_font,
						lbl_pos,
						_fmt(w_disp),
						HORIZONTAL_ALIGNMENT_CENTER,
						-1,
						font_px,
						lbl_col
					)

				conn_idx += 1

	# ── 2. NEURONS ────────────────────────────────────────────────────────────
	for li in num_layers:
		var n := layer_sizes[li]
		var vis_layer := _layer_visibility(li) * base_alpha
		if vis_layer <= 0.0:
			continue

		var layer_forward_t := float(li) / float(num_layers - 1) if num_layers > 1 else 1.0
		var layer_back_t    := float(num_layers - 1 - li) / float(num_layers - 1) if num_layers > 1 else 0.0
		var is_output_layer := li == (num_layers - 1)

		for ni in n:
			var pos: Vector2 = _neuron_positions[li][ni]

			# --- Determine fill color by animation state ---
			var fill := neuron_fill_color
			var stroke := neuron_stroke_color

			var fwd_pulse := _pulse(forward_pass_progress, layer_forward_t, forward_pulse_width)
			var bp_pulse  := _pulse(backprop_progress, layer_back_t, backprop_pulse_width)

			if is_output_layer and error_display_progress > 0.01:
				fill = neuron_fill_color.lerp(neuron_error_color, error_display_progress)
				stroke = neuron_stroke_color.lerp(neuron_error_color, error_display_progress)
			elif bp_pulse > 0.01:
				fill = neuron_fill_color.lerp(neuron_grad_color, bp_pulse)
				stroke = neuron_stroke_color.lerp(neuron_grad_color, bp_pulse)
			elif fwd_pulse > 0.01:
				fill = neuron_fill_color.lerp(neuron_active_color, fwd_pulse)
				stroke = neuron_stroke_color.lerp(neuron_active_color, fwd_pulse)

			fill.a   *= vis_layer
			stroke.a *= vis_layer

			# --- Draw filled circle ---
			draw_circle(pos, neuron_radius, fill)

			# --- Draw stroke ring ---
			draw_arc(pos, neuron_radius, 0.0, TAU, neuron_segments,
				stroke, neuron_stroke_width, true)

			# --- Error burst ring (output layer only) ---
			if is_output_layer and error_display_progress > 0.01:
				var burst_r := neuron_radius * lerpf(1.0, error_burst_scale, error_display_progress)
				var burst_col := error_burst_color
				burst_col.a *= error_display_progress * vis_layer
				draw_arc(pos, burst_r, 0.0, TAU, neuron_segments,
					burst_col, error_burst_width, true)

			# --- Highlight ring ---
			if highlight_progress > 0.01:
				var do_highlight := false
				if highlight_layer == li:
					do_highlight = (highlight_neuron == -1 or highlight_neuron == ni)
				if do_highlight:
					var ring_r := neuron_radius + highlight_ring_gap
					var end_a := -PI * 0.5 + highlight_progress * TAU
					var hl_col := highlight_color
					hl_col.a *= vis_layer
					draw_arc(pos, ring_r, -PI * 0.5, end_a, neuron_segments,
						hl_col, highlight_ring_width, true)

			# --- Neuron label (bias / activation / delta) ---
			if label_opacity > 0.01 and vis_layer > 0.3:
				var lbl := ""
				var lbl_col := neuron_label_color

				if show_activations and forward_pass_progress > layer_forward_t - 0.1:
					lbl = _fmt(_activations[li][ni])
					lbl_col = neuron_active_color if fwd_pulse > 0.3 else neuron_label_color
				elif show_biases:
					var b_cur: float = _biases[li][ni]
					var b_new: float = _biases_updated[li][ni]
					var b_disp := lerpf(b_cur, b_new, weight_correction_progress)
					lbl = _fmt(b_disp)

				lbl_col.a *= label_opacity * vis_layer
				if not lbl.is_empty():
					# Center the string on the neuron with a slight vertical nudge
					var lbl_y := pos.y + font_px * 0.35   # baseline offset
					draw_string(
						ThemeDB.fallback_font,
						Vector2(pos.x, lbl_y),
						lbl,
						HORIZONTAL_ALIGNMENT_CENTER,
						-1,
						font_px,
						lbl_col
					)

	# ── 3. ERROR LABELS at output neurons ────────────────────────────────────
	if error_display_progress > 0.01 and label_opacity > 0.01:
		var out_li := num_layers - 1
		var vis_layer := _layer_visibility(out_li) * base_alpha
		if vis_layer > 0.0:
			var out_n := layer_sizes[out_li]
			for ni in out_n:
				var pos: Vector2 = _neuron_positions[out_li][ni]
				var err: float = _errors[ni] if ni < _errors.size() else 0.0
				var ecol := error_label_color
				ecol.a *= error_display_progress * label_opacity * vis_layer
				var err_str := "Δ" + _fmt(err)
				draw_string(
					ThemeDB.fallback_font,
					pos + Vector2(neuron_radius + 6.0, font_px * 0.4),
					err_str,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					font_px + 1,
					ecol
				)

	# ── 4. DELTA LABELS during backprop ───────────────────────────────────────
	if backprop_progress > 0.01 and label_opacity > 0.01:
		for li in num_layers:
			var layer_back_t := float(num_layers - 1 - li) / float(num_layers - 1) if num_layers > 1 else 0.0
			var bp_pulse := _pulse(backprop_progress, layer_back_t, backprop_pulse_width)
			if bp_pulse < 0.05:
				continue
			var vis_layer := _layer_visibility(li) * base_alpha
			var n := layer_sizes[li]
			for ni in n:
				var pos: Vector2 = _neuron_positions[li][ni]
				var d: float = _deltas[li][ni]
				var dcol := neuron_grad_color
				dcol.a *= bp_pulse * label_opacity * vis_layer
				draw_string(
					ThemeDB.fallback_font,
					pos + Vector2(neuron_radius + 5.0, -font_px * 0.5),
					"∇" + _fmt(d),
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					font_px,
					dcol
				)
