shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

// ─────────────────────────────────────────────────────────────────────────────
//  STYLIZED EARTH SHADER  –  Godot 4.x (FIXED)
// ─────────────────────────────────────────────────────────────────────────────

// ── TEXTURES ──────────────────────────────────────────────────────────────────
group_uniforms textures;
uniform sampler2D albedo_texture   : source_color, hint_default_white;
uniform sampler2D normal_texture   : hint_normal;
uniform sampler2D specular_texture : hint_default_white;
uniform sampler2D night_texture    : source_color, hint_default_black;
uniform sampler2D cloud_texture    : hint_default_black;

// ── SURFACE COLOURS ───────────────────────────────────────────────────────────
group_uniforms surface;
uniform vec4  tint_color        : source_color = vec4(1.0);
uniform float saturation        : hint_range(0.0, 2.0) = 1.2;
uniform float contrast          : hint_range(0.5, 2.0) = 1.1;

// ── TOON SHADING ──────────────────────────────────────────────────────────────
group_uniforms toon;
uniform int   diffuse_bands     : hint_range(1, 6)    = 3;
uniform float band_smoothness   : hint_range(0.0, 0.5) = 0.08;
uniform vec4  shadow_color      : source_color = vec4(0.05, 0.05, 0.15, 1.0);
uniform float shadow_strength   : hint_range(0.0, 1.0) = 0.75;

// ── ATMOSPHERE ─────────────────────────────────────────────────────────────────
group_uniforms atmosphere;
uniform vec4  atmo_color        : source_color = vec4(0.30, 0.55, 1.00, 1.0);
uniform float atmo_power        : hint_range(1.0, 8.0)  = 3.5;
uniform float atmo_strength     : hint_range(0.0, 2.0)  = 1.0;
uniform float atmo_day_only     : hint_range(0.0, 1.0)  = 0.8;

// ── SPECULAR ──────────────────────────────────────────────────────────────────
group_uniforms specular;
uniform float ocean_spec_power   : hint_range(1.0, 128.0) = 48.0;
uniform float ocean_spec_strength: hint_range(0.0, 2.0)   = 0.6;
uniform vec4  ocean_spec_color   : source_color = vec4(0.8, 0.9, 1.0, 1.0);

// ── CLOUDS ────────────────────────────────────────────────────────────────────
group_uniforms clouds;
uniform float cloud_density     : hint_range(0.0, 1.0) = 0.55;
uniform float cloud_sharpness   : hint_range(1.0, 8.0) = 3.0;
uniform vec4  cloud_color       : source_color = vec4(0.95, 0.97, 1.00, 1.0);
uniform vec4  cloud_shadow_color: source_color = vec4(0.60, 0.65, 0.75, 1.0);
uniform float cloud_scroll_speed: hint_range(0.0, 0.1) = 0.004;

// ── NIGHT SIDE ────────────────────────────────────────────────────────────────
group_uniforms night_side;
uniform float night_brightness  : hint_range(0.0, 3.0) = 1.4;
uniform float night_blend_width : hint_range(0.0, 0.5) = 0.15;
uniform vec4  night_tint        : source_color = vec4(1.0, 0.85, 0.55, 1.0);

// ── MISC ──────────────────────────────────────────────────────────────────────
group_uniforms misc;
uniform float normal_strength   : hint_range(0.0, 2.0) = 0.6;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.0;

// ── VARYINGS (to pass data from fragment to light) ────────────────────────────
varying float v_specular_mask;
varying vec3  v_night_emission;

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────
vec3 adjust_saturation(vec3 c, float sat) {
	float grey = dot(c, vec3(0.2126, 0.7152, 0.0722));
	return mix(vec3(grey), c, sat);
}

float toon_bands(float value, int bands, float smoothness) {
	float b   = float(bands);
	float raw = value * b;
	float stepped = floor(raw) + smoothstep(0.5 - smoothness, 0.5 + smoothness, fract(raw));
	return clamp(stepped / b, 0.0, 1.0);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FRAGMENT
// ─────────────────────────────────────────────────────────────────────────────
void fragment() {
	vec2 uv = UV;
	vec2 cloud_uv = uv + vec2(TIME * cloud_scroll_speed, 0.0);

	vec4 albedo_samp  = texture(albedo_texture,   uv);
	vec4 night_samp   = texture(night_texture,    uv);
	vec4 cloud_samp   = texture(cloud_texture,    cloud_uv);
	vec4 spec_mask    = texture(specular_texture, uv);

	// Surface colour
	vec3 surface_col = albedo_samp.rgb * tint_color.rgb;
	surface_col = adjust_saturation(surface_col, saturation);
	surface_col = ((surface_col - 0.5) * contrast) + 0.5;
	surface_col = clamp(surface_col, 0.0, 1.0);

	// Clouds
	float cloud_mask = pow(clamp(cloud_samp.r, 0.0, 1.0), 1.0 / cloud_sharpness);
	cloud_mask = smoothstep(1.0 - cloud_density, 1.0, cloud_mask);
	vec3 land_with_cloud_shadow = mix(surface_col, surface_col * cloud_shadow_color.rgb, cloud_mask * 0.4);
	vec3 surface_with_clouds = mix(land_with_cloud_shadow, cloud_color.rgb, cloud_mask);

	ALBEDO = surface_with_clouds;

	// Normal map
	NORMAL_MAP = texture(normal_texture, uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;

	// Specular mask (ocean glint) – store in varying for light()
	float spec_mask_value = spec_mask.r * (1.0 - cloud_mask * 0.8);
	v_specular_mask = spec_mask_value;
	SPECULAR = spec_mask_value;          // also set built-in (optional)
	ROUGHNESS = mix(0.05, 0.95, 1.0 - spec_mask_value);
	METALLIC = 0.0;

	// Night emission – will be multiplied by night_mask in light()
	v_night_emission = night_samp.rgb * night_tint.rgb * night_brightness * emission_strength;
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT
// ─────────────────────────────────────────────────────────────────────────────
void light() {
	float NdotL = dot(NORMAL, LIGHT);

	// Toon diffuse
	float lit   = clamp(NdotL * ATTENUATION, 0.0, 1.0);
	float toon  = toon_bands(lit, diffuse_bands, band_smoothness);
	vec3 diffuse_intensity = mix(vec3(1.0), shadow_color.rgb, (1.0 - toon) * shadow_strength);
	DIFFUSE_LIGHT += diffuse_intensity * LIGHT_COLOR * toon;

	// Night-side emission (added to diffuse light)
	float day_mask   = smoothstep(-night_blend_width, night_blend_width, NdotL);
	float night_mask = 1.0 - day_mask;
	DIFFUSE_LIGHT += v_night_emission * night_mask;

	// Ocean specular (using varying mask)
	vec3 H = normalize(LIGHT + VIEW);
	float NdotH = max(dot(NORMAL, H), 0.0);
	float spec_raw = pow(NdotH, ocean_spec_power) * v_specular_mask * ATTENUATION * day_mask;
	float spec_toon = smoothstep(0.3, 0.7, spec_raw * 4.0);
	SPECULAR_LIGHT += ocean_spec_color.rgb * LIGHT_COLOR * spec_toon * ocean_spec_strength;

	// Atmosphere Fresnel rim
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), atmo_power);
	float rim_day = mix(1.0, day_mask, atmo_day_only);
	float rim_strength = fresnel * atmo_strength * rim_day;
	DIFFUSE_LIGHT += atmo_color.rgb * LIGHT_COLOR * rim_strength;
}

