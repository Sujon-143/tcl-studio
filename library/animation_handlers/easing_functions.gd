extends RefCounted
class_name TransitionFunctions

# ----------------------------
# TRANSITIONS (base curves)
# ----------------------------

static func trans_linear(t: float) -> float:
	return t


static func trans_sine(t: float) -> float:
	return 1.0 - cos((t * PI) / 2.0)


static func trans_quad(t: float) -> float:
	return t * t


static func trans_cubic(t: float) -> float:
	return t * t * t


static func trans_quart(t: float) -> float:
	return pow(t, 4)


static func trans_quint(t: float) -> float:
	return pow(t, 5)


static func trans_expo(t: float) -> float:
	return  0.0 if t == 0.0 else pow(2.0, 10.0 * (t - 1.0))


static func trans_circ(t: float) -> float:
	return 1.0 - sqrt(1.0 - t * t)


static func trans_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return c3 * t * t * t - c1 * t * t


static func trans_elastic(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	var c4 := (2.0 * PI) / 3.0
	return -pow(2.0, 10.0 * t - 10.0) * sin((t * 10.0 - 10.75) * c4)


static func trans_bounce(t: float) -> float:
	var n1 := 7.5625
	var d1 := 2.75

	if t < 1.0 / d1:
		return n1 * t * t
	elif t < 2.0 / d1:
		t -= 1.5 / d1
		return n1 * t * t + 0.75
	elif t < 2.5 / d1:
		t -= 2.25 / d1
		return n1 * t * t + 0.9375
	else:
		t -= 2.625 / d1
		return n1 * t * t + 0.984375


# ----------------------------
# EASING WRAPPERS
# ----------------------------

static func ease_in(func_ref: Callable, t: float) -> float:
	return func_ref.call(t)


static func ease_out(func_ref: Callable, t: float) -> float:
	return 1.0 - func_ref.call(1.0 - t)


static func ease_in_out(func_ref: Callable, t: float) -> float:
	if t < 0.5:
		return func_ref.call(2.0 * t) / 2.0
	else:
		return 1.0 - func_ref.call(2.0 * (1.0 - t)) / 2.0
