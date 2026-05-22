shader_type canvas_item;

uniform float fade_start : hint_range(0.0, 1.0) = 0.55;
uniform float fade_end : hint_range(0.0, 1.0) = 0.95;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float fade = smoothstep(fade_start, fade_end, UV.y);
    tex.a *= 1.0 - fade;
    COLOR = tex;
}
