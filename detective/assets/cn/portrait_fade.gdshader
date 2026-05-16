shader_type canvas_item;

// 立绘边缘渐隐：让 sprite 底部、左侧（贴墙的一边）、右侧渐变到透明，
// 使其自然融入对话框背景。
uniform float fade_bottom : hint_range(0.0, 0.5) = 0.18;
uniform float fade_top    : hint_range(0.0, 0.5) = 0.05;
uniform float fade_left   : hint_range(0.0, 0.5) = 0.10;
uniform float fade_right  : hint_range(0.0, 0.5) = 0.10;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float a = base.a;
	// 底部渐隐
	if (UV.y > 1.0 - fade_bottom) {
		float t = (UV.y - (1.0 - fade_bottom)) / fade_bottom;
		a *= 1.0 - smoothstep(0.0, 1.0, t);
	}
	// 顶部
	if (UV.y < fade_top) {
		float t = UV.y / fade_top;
		a *= smoothstep(0.0, 1.0, t);
	}
	// 左侧
	if (UV.x < fade_left) {
		float t = UV.x / fade_left;
		a *= smoothstep(0.0, 1.0, t);
	}
	// 右侧
	if (UV.x > 1.0 - fade_right) {
		float t = (UV.x - (1.0 - fade_right)) / fade_right;
		a *= 1.0 - smoothstep(0.0, 1.0, t);
	}
	COLOR = vec4(base.rgb, a);
}
