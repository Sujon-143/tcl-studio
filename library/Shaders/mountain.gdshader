shader_type spatial;
render_mode world_vertex_coords, unshaded;

uniform float mountain_radius : hint_range(0.1, 20.0) = 3.0;
uniform float mountain_height : hint_range(0.0, 20.0) = 2.5;
uniform float peak_flatten : hint_range(0.0, 1.0) = 0.3;
uniform vec2 mountain_center = vec2(0.0, 0.0);
uniform float noise_strength : hint_range(0.0, 1.0) = 0.35;
uniform float noise_scale : hint_range(0.1, 10.0) = 2.5;

// --- Noise (hash + value noise, runs in vertex) ---

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f); // smoothstep

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        v += amp * vnoise(p);
        p *= 2.1;
        amp *= 0.5;
    }
    return v;
}

// --- Color palette ---

varying float v_height_ratio; // 0 = base, 1 = peak
varying float v_slope;        // 0 = flat top, 1 = steep edge

void vertex() {
    vec2 offset = VERTEX.xz - mountain_center;
    float dist = length(offset);
    float t = clamp(dist / mountain_radius, 0.0, 1.0);

    float slope = 1.0 - smoothstep(0.0, 1.0, t);
    float top_clamp = 1.0 - peak_flatten;
    float is_top = step(top_clamp, slope); // 1.0 on flat top region
    slope = min(slope, top_clamp) / top_clamp;
    slope = pow(slope, 1.5);

    // Layered noise: coarse shape + fine detail
    vec2 np = VERTEX.xz * noise_scale;
    float n = fbm(np) * 0.6 + fbm(np * 2.3 + vec2(5.1, 3.7)) * 0.4;
    n = (n - 0.5) * noise_strength;

    // Suppress noise on the flat top so it stays clean
    n *= (1.0 - is_top * 0.85);

    float final_height = (slope + n * slope) * mountain_height;
    VERTEX.y += final_height;

    // Pass to fragment
    v_height_ratio = slope; // 0..1 clean shape value
    v_slope = t;            // 0 = center, 1 = edge
}

void fragment() {
    // Color zones by height
    vec3 snow    = vec3(0.93, 0.96, 1.00); // white-blue peak
    vec3 ice     = vec3(0.65, 0.82, 0.92); // pale blue glacier
    vec3 rock    = vec3(0.38, 0.32, 0.28); // dark rock mid
    vec3 tundra  = vec3(0.22, 0.30, 0.20); // dark green-grey base
    vec3 ground  = vec3(0.15, 0.18, 0.22); // deep cold shadow base

    // Blend from base to peak using height
    float h = v_height_ratio;

    vec3 col = ground;
    col = mix(col, tundra, smoothstep(0.0, 0.2, h));
    col = mix(col, rock,   smoothstep(0.15, 0.55, h));
    col = mix(col, ice,    smoothstep(0.50, 0.78, h));
    col = mix(col, snow,   smoothstep(0.72, 0.92, h));

    // Subtle rim darkening on steep slopes
    col *= mix(0.75, 1.0, smoothstep(0.5, 1.0, 1.0 - v_slope));

    // Cold blue tint at very top (flat plateau = polar ice cap feel)
    float plateau = smoothstep(0.88, 1.0, h);
    col = mix(col, vec3(0.78, 0.90, 1.00), plateau * 0.4);

    ALBEDO = col;
}