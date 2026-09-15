shader_type sky;

// ─────────────────────────────────────────────────────────────────────────────
//  STYLIZED SPACE SKY  –  Godot 4.x  (no seams, no UV projection)
//
//  Every noise / star sample uses the raw 3D EYEDIR direction vector.
//  This is the standard technique used by real Godot sky shaders (GDQuest,
//  godotshaders.com starry-sky, etc.) to completely avoid the visible seam
//  that appears when you project to 2D with atan/asin.
//
//  Setup:
//    WorldEnvironment → Environment → Background: Sky
//    Sky → Sky Material: ShaderMaterial → Shader: this file
//    Sky → Process Mode: Real-Time          ← needed for twinkling
// ─────────────────────────────────────────────────────────────────────────────

// ── COLORS ────────────────────────────────────────────────────────────────────
group_uniforms colors;
uniform vec3 deep_space_color : source_color = vec3(0.00, 0.00, 0.02);
uniform vec3 nebula_color_a   : source_color = vec3(0.30, 0.05, 0.55); // violet
uniform vec3 nebula_color_b   : source_color = vec3(0.05, 0.15, 0.50); // deep blue
uniform vec3 nebula_color_c   : source_color = vec3(0.50, 0.04, 0.20); // crimson
uniform vec3 star_color_warm  : source_color = vec3(1.00, 0.88, 0.65);
uniform vec3 star_color_cool  : source_color = vec3(0.65, 0.82, 1.00);

// ── NEBULA ────────────────────────────────────────────────────────────────────
group_uniforms nebula;
uniform float nebula_strength  : hint_range(0.0, 2.0) = 1.0;
uniform float nebula_scale     : hint_range(0.5, 4.0) = 1.4;
uniform float nebula_sharpness : hint_range(1.0, 6.0) = 2.5;

// ── STARS ─────────────────────────────────────────────────────────────────────
group_uniforms stars;
uniform float star_density     : hint_range(0.0, 1.0)  = 0.55;
uniform float star_size        : hint_range(0.001, 0.1) = 0.028;
uniform float star_brightness  : hint_range(0.5, 4.0)  = 1.8;
uniform float twinkle_speed    : hint_range(0.0, 4.0)  = 1.2;
uniform float twinkle_amount   : hint_range(0.0, 1.0)  = 0.35;
uniform int   star_layers      : hint_range(1, 5)      = 3;
uniform float layer_scale_base : hint_range(5.0, 40.0) = 18.0;
uniform float layer_scale_step : hint_range(2.0, 20.0) = 9.0;

// ── MILKY WAY BAND ────────────────────────────────────────────────────────────
group_uniforms milky_way;
uniform float band_strength : hint_range(0.0, 2.0) = 0.7;
uniform float band_width    : hint_range(0.0, 1.0) = 0.18;
uniform float band_tilt     : hint_range(-1.0, 1.0) = 0.3;

// ── MISC ──────────────────────────────────────────────────────────────────────
group_uniforms misc;
uniform float exposure : hint_range(0.2, 3.0) = 1.1;

// ─────────────────────────────────────────────────────────────────────────────
//  HASH & NOISE  —  pure 3D, no 2D projection, zero seams
// ─────────────────────────────────────────────────────────────────────────────

// Inigo Quilez – MIT
vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7,  74.7)),
	         dot(p, vec3(269.5, 183.3, 246.1)),
	         dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453123);
}

// 3D gradient (Perlin-style) noise — eliminates the square lattice artifact
// that value noise produces at low octave counts.
// Each lattice vertex gets a random gradient vector; the noise value is the
// dot product of that gradient with the offset to the sample point.
// Result is naturally centred around 0, remapped to [0,1] at the end.
float gnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	// Quintic interpolant – C2 continuous, kills second-derivative discontinuity
	// that causes the faint grid lines even smoothstep leaves behind
	vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	// Random gradient at each of the 8 cube corners
	// hash3 gives a vec3 in [0,1]^3; map to [-1,1]^3 for a proper gradient
	vec3 g000 = hash3(i+vec3(0,0,0))*2.0-1.0;
	vec3 g100 = hash3(i+vec3(1,0,0))*2.0-1.0;
	vec3 g010 = hash3(i+vec3(0,1,0))*2.0-1.0;
	vec3 g110 = hash3(i+vec3(1,1,0))*2.0-1.0;
	vec3 g001 = hash3(i+vec3(0,0,1))*2.0-1.0;
	vec3 g101 = hash3(i+vec3(1,0,1))*2.0-1.0;
	vec3 g011 = hash3(i+vec3(0,1,1))*2.0-1.0;
	vec3 g111 = hash3(i+vec3(1,1,1))*2.0-1.0;

	float n000 = dot(g000, f-vec3(0,0,0));
	float n100 = dot(g100, f-vec3(1,0,0));
	float n010 = dot(g010, f-vec3(0,1,0));
	float n110 = dot(g110, f-vec3(1,1,0));
	float n001 = dot(g001, f-vec3(0,0,1));
	float n101 = dot(g101, f-vec3(1,0,1));
	float n011 = dot(g011, f-vec3(0,1,1));
	float n111 = dot(g111, f-vec3(1,1,1));

	float x00 = mix(n000, n100, u.x);
	float x10 = mix(n010, n110, u.x);
	float x01 = mix(n001, n101, u.x);
	float x11 = mix(n011, n111, u.x);
	float y0  = mix(x00,  x10,  u.y);
	float y1  = mix(x01,  x11,  u.y);
	float raw = mix(y0,   y1,   u.z);

	// Raw Perlin output is in roughly [-0.9, 0.9]; remap to [0, 1]
	return raw * 0.5 + 0.5;
}

// Fractal Brownian Motion in 3D — uses gradient noise
float fbm3(vec3 p, int oct) {
	float v = 0.0, a = 0.5, f = 1.0;
	for (int i = 0; i < oct; i++) {
		v += a * gnoise3(p * f);
		f *= 2.07;
		a *= 0.48;
	}
	return v;
}

// 3D Voronoi – Inigo Quilez MIT
// Returns vec2(closest_dist, cell_id_scalar)
vec2 voronoi3(vec3 x) {
	vec3 p = floor(x);
	vec3 f = fract(x);
	float best = 100.0;
	float id   = 0.0;
	for (int k = -1; k <= 1; k++)
	for (int j = -1; j <= 1; j++)
	for (int i = -1; i <= 1; i++) {
		vec3 b = vec3(float(i), float(j), float(k));
		vec3 r = b - f + hash3(p + b);
		float d = dot(r, r);
		if (d < best) {
			best = d;
			id   = dot(p + b, vec3(1.0, 57.0, 113.0));
		}
	}
	return vec2(sqrt(best), id);
}

// ─────────────────────────────────────────────────────────────────────────────
//  STAR LAYER  – all in 3D EYEDIR space, not projected UV
// ─────────────────────────────────────────────────────────────────────────────
vec3 star_layer(vec3 dir, float scale, float seed) {
	vec2 v = voronoi3(dir * scale + seed * 7.3);
	vec3 ch = hash3(vec3(v.y * 0.001, v.y * 0.003, seed));

	// Cull most cells to control density
	if (ch.z > star_density) return vec3(0.0);

	// Twinkle
	float tw = 1.0 - twinkle_amount * 0.5
	         + twinkle_amount * 0.5
	         * sin(TIME * twinkle_speed * (0.6 + ch.x * 0.8) + ch.y * 6.28318);

	// Star disc
	float s = smoothstep(star_size, 0.0, v.x) * star_brightness * tw;

	// Color: warm / cool / white
	vec3 col;
	if      (ch.x < 0.33) col = star_color_warm;
	else if (ch.x < 0.66) col = star_color_cool;
	else                   col = vec3(1.0);
	return col * s;
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN
// ─────────────────────────────────────────────────────────────────────────────
void sky() {
	vec3 dir = normalize(EYEDIR);

	// 1. Deep space base
	vec3 col = deep_space_color;

	// 2. Nebula – three FBM passes in different orientations, all 3D
	vec3 np = dir * nebula_scale;
	float n1 = fbm3(np,                              5);
	float n2 = fbm3(np + vec3(3.2, 1.7, 4.9),       5);
	float n3 = fbm3(np * 1.6 + vec3(7.1, 2.3, 0.5), 4);

	float neb = pow(max(n1 * n2, 0.0), nebula_sharpness) * nebula_strength;
	neb = clamp(neb * 2.2, 0.0, 0.9);

	vec3 neb_col = mix(nebula_color_a, nebula_color_b, n1);
	neb_col      = mix(neb_col, nebula_color_c, n2 * 0.6);

	// Bright emission filaments (pillars of creation feel)
	float filament = pow(n3, 4.0) * 2.5;
	neb_col += filament * (nebula_color_a * 0.5 + nebula_color_c * 0.3);

	col = mix(col, neb_col, neb);

	// 3. Milky Way dust band
	// "dot with plane normal" gives smooth band distance in 3D – no seam possible
	vec3 band_normal = normalize(vec3(band_tilt, 1.0, 0.0));
	float band_dist  = abs(dot(dir, band_normal));
	float band_mask  = smoothstep(band_width, 0.0, band_dist);
	float band_noise = fbm3(dir * 3.0, 3);
	vec3  band_col   = mix(nebula_color_b * 0.4, star_color_cool * 0.3, band_noise);
	col = mix(col, col + band_col, band_mask * band_strength);

	// 4. Star layers (loop uses constant expression, Godot GLSL limit)
	for (int i = 0; i < 5; i++) {
		if (i >= star_layers) break;
		col += star_layer(dir, layer_scale_base + float(i) * layer_scale_step, float(i));
	}

	// 5. Rare giant stars (low density, extra bright, no twinkling flicker)
	{
		vec2 gv   = voronoi3(dir * (layer_scale_base * 0.35));
		vec3 gch  = hash3(vec3(gv.y * 0.001, gv.y * 0.003, 9.9));
		if (gch.z < 0.08) {
			float gs = smoothstep(star_size * 2.5, 0.0, gv.x) * 3.5;
			col += vec3(1.0) * gs;
		}
	}

	// 6. Exposure + soft Reinhard tonemap
	col *= exposure;
	col  = col / (col + vec3(0.6));

	// Space color grade: slightly blue-violet
	col.r *= 0.93;
	col.b  = col.b * 1.06 + 0.003;

	COLOR = col;
}
