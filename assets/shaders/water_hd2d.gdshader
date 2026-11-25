shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
// Shader mặt hồ & suối cổ trang HD-2D mềm mại:
// Sóng nước uyển chuyển mượt mà, phản chiếu ánh trăng ngọc bích, ánh đèn lồng bokeh ấm áp & viền bọt mềm ven bờ!

uniform vec4 shallow_color : source_color = vec4(0.16, 0.30, 0.44, 0.90);
uniform vec4 deep_color : source_color = vec4(0.05, 0.11, 0.22, 0.96);
uniform vec4 foam_color : source_color = vec4(0.84, 0.94, 1.0, 1.0);
uniform vec4 lantern_reflect_color : source_color = vec4(1.0, 0.72, 0.34, 1.0);
uniform float wave_speed : hint_range(0.1, 4.0) = 1.15;
uniform float wave_scale : hint_range(1.0, 60.0) = 16.0;

void vertex() {
	float t = TIME * wave_speed;
	VERTEX.y += sin(VERTEX.x * 1.4 + t) * 0.018 + cos(VERTEX.z * 1.7 - t * 0.85) * 0.014;
}

void fragment() {
	float t = TIME * wave_speed;
	vec2 p1 = UV * wave_scale + vec2(t * 0.28, t * 0.18);
	vec2 p2 = UV * (wave_scale * 1.55) - vec2(t * 0.22, -t * 0.31);
	vec2 p3 = UV * (wave_scale * 2.4) + vec2(-t * 0.14, t * 0.36);

	float w1 = sin(p1.x + sin(p1.y * 0.7)) * cos(p1.y);
	float w2 = sin(p2.x * 0.9 + p2.y);
	float w3 = cos(p3.x - p3.y * 1.1);
	float ripple = (w1 * 0.5 + w2 * 0.35 + w3 * 0.15);

	// Đường viền bọt mềm dịu ven mép bờ hồ
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge_dist = min(edge_x, edge_y);
	float shore_foam = (1.0 - smoothstep(0.0, 0.095, edge_dist + ripple * 0.018)) * 0.42;

	// Chấm sáng lấp lánh dịu mắt trên gợn sóng
	float glint = smoothstep(0.58, 0.86, abs(w1 * w2 + w3 * 0.42));

	// Vệt bokeh ánh đèn lồng vàng cam & ánh trăng lan mềm trên mặt nước
	float g1 = length((UV - vec2(0.32, 0.54)) * vec2(1.0, 1.4));
	float g2 = length((UV - vec2(0.70, 0.42)) * vec2(1.1, 1.3));
	float warm_glow = exp(-g1 * g1 * 7.5) * (0.82 + 0.18 * sin(t * 3.2 + w1 * 2.2));
	float moon_glow = exp(-g2 * g2 * 6.0) * 0.45;

	vec3 base_water = mix(deep_color.rgb, shallow_color.rgb, smoothstep(-0.55, 0.65, ripple));
	base_water = mix(base_water, foam_color.rgb, shore_foam);
	ALBEDO = mix(base_water, lantern_reflect_color.rgb, clamp(warm_glow * 0.68, 0.0, 0.78));
	EMISSION = foam_color.rgb * (glint * 0.62 + moon_glow * 0.55 + shore_foam * 0.25) + lantern_reflect_color.rgb * warm_glow * 1.15;
	ALPHA = clamp(0.86 + shore_foam * 0.14, 0.82, 0.97);
	METALLIC = 0.36;
	SPECULAR = 0.92;
	ROUGHNESS = clamp(0.08 + abs(ripple) * 0.06, 0.04, 0.22);
	NORMAL_MAP = normalize(vec3((w1 + w3 * 0.4) * 0.18, (w2 - w3 * 0.35) * 0.18, 1.0)) * 0.5 + 0.5;
}
