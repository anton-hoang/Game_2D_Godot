shader_type canvas_item;
// Shader Vignette hậu kỳ phong cách HD-2D (làm tối 4 góc màn hình)

uniform float intensity : hint_range(0.0, 1.5) = 0.55;
uniform float softness : hint_range(0.05, 1.0) = 0.45;
uniform vec4 vignette_color : source_color = vec4(0.03, 0.02, 0.06, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 1.4142;
	float vig = smoothstep(1.0 - softness, 1.0, dist * intensity);
	COLOR = vec4(vignette_color.rgb, vig * vignette_color.a);
}
