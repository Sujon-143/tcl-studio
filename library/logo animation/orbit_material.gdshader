shader_type canvas_item;

// 0.0 = fully faded (back of orbit), 1.0 = fully opaque (front)
uniform float alpha_front : hint_range(0.1, 1.0) = 1.0;
uniform float alpha_back  : hint_range(0.0, 0.9) = 0.15;

// Controls how sharp the front/back transition is (1.0 = linear, >1 = eased)
uniform float contrast : hint_range(0.5, 4.0) = 1.5;

// Shift where "front" sits (0.5 = bottom of UV, tweak if your orbit is offset)
uniform float front_uv_y : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    // UV.y goes 0.0 (top) → 1.0 (bottom) in canvas_item
    // Remap so front_uv_y = 1.0, opposite = 0.0
    float t = abs(UV.y - (1.0 - front_uv_y)) / max(front_uv_y, 1.0 - front_uv_y);
    t = clamp(t, 0.0, 1.0);

    // Apply contrast curve so the front pops and back fades quickly
    t = pow(t, contrast);

    float alpha = mix(alpha_back, alpha_front, t);
    COLOR.a *= alpha;
}
