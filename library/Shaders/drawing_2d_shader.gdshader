shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float smoothness = 0.01;

void fragment() {
    vec2 uv = UV;

    // Center the UV
    vec2 centered = uv - vec2(0.5);

    // Get angle (-PI to PI)
    float angle = atan(centered.y, centered.x);

    // Normalize angle to 0 → 1
    angle = (angle + PI) / (2.0 * PI);

    // Create reveal mask
    float mask = smoothstep(progress+smoothness, progress , angle);

    vec4 tex = texture(TEXTURE, uv);
    tex.a *= mask;

    COLOR = tex;
}