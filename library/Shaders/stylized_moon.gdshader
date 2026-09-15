shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

// ── SURFACE PROPERTIES ────────────────────────────────────────────────────────
group_uniforms surface;
uniform vec4  base_color           : source_color = vec4(0.78, 0.75, 0.70, 1.0);
uniform vec4  dark_color           : source_color = vec4(0.18, 0.17, 0.15, 1.0);
uniform vec4  rim_bright_color     : source_color = vec4(0.95, 0.93, 0.88, 1.0);
uniform float crater_scale         : hint_range(1.0, 20.0)  = 4.0;
uniform float crater_depth         : hint_range(0.0, 2.0)   = 1.2;
uniform float crater_sharpness     : hint_range(1.0, 6.0)   = 2.0;
uniform float small_craters        : hint_range(0.0, 1.0)   = 0.4;
uniform float crater_min_radius    : hint_range(0.1, 0.5)   = 0.25;
uniform float crater_max_radius    : hint_range(0.2, 0.9)   = 0.7;
uniform float rim_width            : hint_range(0.0, 0.5)   = 0.15;
uniform float rim_height           : hint_range(0.0, 1.0)   = 0.6;
uniform float displacement_strength: hint_range(0.0, 0.5)   = 0.08;

// ── TOON SHADING ──────────────────────────────────────────────────────────────
group_uniforms toon;
uniform int   diffuse_bands   : hint_range(1, 6)     = 3;
uniform float band_smoothness : hint_range(0.0, 0.5) = 0.1;
uniform vec4  shadow_color    : source_color = vec4(0.10, 0.09, 0.08, 1.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.75;

// ── RIM LIGHT ─────────────────────────────────────────────────────────────────
group_uniforms rim;
uniform vec4  rim_color    : source_color = vec4(0.95, 0.97, 1.00, 1.0);
uniform float rim_power    : hint_range(1.0, 8.0) = 4.5;
uniform float rim_strength : hint_range(0.0, 1.5) = 1.0;

// ── NORMAL STRENGTH ───────────────────────────────────────────────────────────
group_uniforms normals;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.9;

// ─────────────────────────────────────────────────────────────────────────────
//  object_pos: original LOCAL-space position, frozen before displacement.
//  This is the stable domain for all crater/noise sampling in fragment().
//  Because it's set from VERTEX *before* we mutate VERTEX, and the GPU
//  interpolates it across the original (pre-displacement) triangle, the
//  fragment always receives a position anchored to the rest-pose surface —
//  no morphing, no sliding textures.
// ─────────────────────────────────────────────────────────────────────────────
varying vec3 object_pos;

// ─────────────────────────────────────────────────────────────────────────────
float hash3(vec3 p) {
    p  = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n = 0.0;
    for (int x = 0; x <= 1; x++) {
        for (int y = 0; y <= 1; y++) {
            for (int z = 0; z <= 1; z++) {
                vec3  offset = vec3(float(x), float(y), float(z));
                float h      = hash3(i + offset);
                vec3  w      = abs(offset - f);
                float weight = (1.0 - w.x) * (1.0 - w.y) * (1.0 - w.z);
                n += h * weight;
            }
        }
    }
    return n;
}

float fbm(vec3 p, int octaves, float persistence, float lacunarity) {
    float value = 0.0;
    float amp   = 0.5;
    float freq  = 1.0;
    for (int i = 0; i < 5; i++) {
        if (i >= octaves) break;
        value += amp * noise3(p * freq);
        amp   *= persistence;
        freq  *= lacunarity;
    }
    return clamp(value, 0.0, 1.0);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Crater profile
//  t = normalised distance from crater centre (0=centre, 1=rim edge)
//  returns: x = signed height  (-1 deepest pit … +1 highest rim)
//           y = albedo factor  (0 = darkest floor, 1 = base, >1 = bright rim)
// ─────────────────────────────────────────────────────────────────────────────
vec2 crater_profile(float t) {
    if (t >= 1.0) {
        float outer = 1.0 - smoothstep(0.0, rim_width, t - 1.0);
        return vec2(outer * rim_height * 0.3,       // slight ejecta bump
                    1.0 + outer * 0.2);              // subtle brightening
    }
    float rim_t   = smoothstep(0.6, 1.0, t);
    float bowl_t  = 1.0 - smoothstep(0.0, 0.85, t);
    float disp    = rim_t * rim_height - bowl_t;    // + = raised rim, - = sunken floor
    float alb     = 1.0 - bowl_t * 0.85 + rim_t * 0.7;
    return vec2(disp, alb);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Crater field
//  Returns vec2(signed_displacement, albedo_factor) for the dominant crater
// ─────────────────────────────────────────────────────────────────────────────
vec2 crater_field(vec3 pos, float scale, float sharpness) {
    vec3  p      = pos * scale;
    vec3  cell   = floor(p);
    vec3  offset = fract(p);
    float best   = 0.0;
    vec2  result = vec2(0.0, 1.0);

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            for (int k = -1; k <= 1; k++) {
                vec3  neighbor = cell + vec3(float(i), float(j), float(k));
                float h1  = hash3(neighbor);
                float h2  = hash3(neighbor + vec3(1.23, 4.56, 7.89));
                float h3v = hash3(neighbor + vec3(9.87, 6.54, 3.21));

                float radius   = crater_min_radius + h3v * (crater_max_radius - crater_min_radius);
                float strength = 0.5 + hash3(neighbor + 0.5) * 0.5;

                vec3  diff      = offset - vec3(float(i), float(j), float(k)) - vec3(h1, h2, h3v);
                float dist      = length(diff);
                float t         = dist / radius;
                float influence = strength * (1.0 - smoothstep(0.0, 1.0 + rim_width, t));

                if (influence > best) {
                    best   = influence;
                    vec2 p2 = crater_profile(t);
                    result  = vec2(p2.x * strength, p2.y);
                }
            }
        }
    }
    return result;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Layered crater sample — shared by vertex and fragment
// ─────────────────────────────────────────────────────────────────────────────
vec2 layered_craters(vec3 pos) {
    vec2 large  = crater_field(pos, crater_scale,       crater_sharpness);
    vec2 medium = crater_field(pos, crater_scale * 2.5, crater_sharpness * 1.1);
    vec2 small  = crater_field(pos, crater_scale * 5.5, crater_sharpness * 1.3);

    float disp = large.x
               + medium.x * small_craters * 0.5
               + small.x  * small_craters * 0.2;

    float alb = large.y;
    if (abs(medium.y - 1.0) > abs(alb - 1.0)) alb = mix(alb, medium.y, small_craters);
    if (abs(small.y  - 1.0) > abs(alb - 1.0)) alb = mix(alb, small.y,  small_craters * 0.5);

    return vec2(disp, alb);
}

// ─────────────────────────────────────────────────────────────────────────────
//  VERTEX
// ─────────────────────────────────────────────────────────────────────────────
void vertex() {
    // ── Freeze the sampling domain BEFORE any displacement ──────────────────
    // object_pos is the rest-pose local position. The GPU interpolates it
    // across the original triangle, so fragment() always gets a stable
    // coordinate regardless of how much VERTEX has moved.
    object_pos = VERTEX;

    // ── Displace ─────────────────────────────────────────────────────────────
    vec2 cr = layered_craters(object_pos);

    // profile.x > 0  → rim (pushes outward  → +NORMAL)
    // profile.x < 0  → bowl (pushes inward  → -NORMAL)
    // So: VERTEX += NORMAL * disp * strength  (sign already correct from profile)
    VERTEX += NORMAL * cr.x * displacement_strength;
}

// ─────────────────────────────────────────────────────────────────────────────
//  FRAGMENT
// ─────────────────────────────────────────────────────────────────────────────
void fragment() {
    // Sample always from the frozen rest-pose position — no morphing
    vec3 pos = object_pos;
    vec2 cr  = layered_craters(pos);

    float fine_noise = fbm(pos * 2.0, 4, 0.5, 2.0) * 0.15 + 0.9;

    vec3 color;
    if (cr.y < 1.0) {
        color = mix(dark_color.rgb, base_color.rgb, cr.y);
    } else {
        color = mix(base_color.rgb, rim_bright_color.rgb, clamp(cr.y - 1.0, 0.0, 1.0));
    }
    color *= fine_noise;
    ALBEDO = color;

    // Normal map from finite differences on the displacement field
    float eps = 0.015;
    vec2  cx  = layered_craters(pos + vec3(eps, 0.0, 0.0));
    vec2  cy  = layered_craters(pos + vec3(0.0, eps, 0.0));
    vec3  nmap = normalize(vec3(
        (cr.x - cx.x) * crater_depth,
        (cr.x - cy.x) * crater_depth,
        0.06
    ));
    NORMAL_MAP       = nmap * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = normal_strength;

    ROUGHNESS = 0.75;
    METALLIC  = 0.0;
    SPECULAR  = 0.1;
}
float toon_bands(float value, int bands, float smoothness) {
    float b       = float(bands);
    float raw     = value * b;
    float stepped = floor(raw) + smoothstep(0.5 - smoothness, 0.5 + smoothness, fract(raw));
    return clamp(stepped / b, 0.0, 1.0);
}
// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT
// ─────────────────────────────────────────────────────────────────────────────
void light() {
    float NdotL = max(dot(NORMAL, LIGHT), 0.0);
    float lit   = clamp(NdotL * ATTENUATION, 0.0, 1.0);
    float toon  = toon_bands(lit, diffuse_bands, band_smoothness);

    vec3 diffuse_intensity = mix(vec3(1.0), shadow_color.rgb, (1.0 - toon) * shadow_strength);
    DIFFUSE_LIGHT += diffuse_intensity * LIGHT_COLOR * toon;

    float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power);
    DIFFUSE_LIGHT += rim_color.rgb * LIGHT_COLOR * clamp(fresnel * rim_strength, 0.0, 0.8);
}