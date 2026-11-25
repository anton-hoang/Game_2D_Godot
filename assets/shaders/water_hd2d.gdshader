shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
// Shader mặt hồ & suối cổ trang HD-2D:
// Mặt nước phẳng mượt (không Z-fighting với đường/cầu), gợn sóng mảnh tinh tế, phản chiếu ánh trăng & đèn lồng dịu mắt!

uniform vec4 shallow_color : source_color = vec4(0.11, 0.28, 0.38, 0.94);
uniform vec4 deep_color : source_color = vec4(0.03, 0.10, 0.20, 0.98);
uniform vec4 foam_color : source_color = vec4(0.76, 0.90, 0.96, 1.0);
uniform vec4 lantern_reflect_color : source_color = vec4(0.98, 0.64, 0.28, 1.0);
uniform float wave_speed : hint_range(0.1, 4.0) = 0.95;
uniform float wave_scale : hint_range(1.0, 60.0) = 24.0;

void fragment() {
	float t = TIME * wave_speed;
	vec2 uv_s = UV * vec2(wave_scale * 0.75, wave_scale * 1.65);

	// Gợn sóng mảnh chạy ngang mềm mại như mặt hồ tĩnh lặng
	float w1 = sin(uv_s.y + sin(uv_s.x * 0.55 + t * 0.65) * 1.4 - t * 1.15);
	float w2 = cos(uv_s.y * 1.65 - uv_s.x * 0.45 + t * 0.85);
	float w3 = sin((uv_s.x + uv_s.y * 1.2) * 0.8 + t * 0.55);
	float ripple = w1 * 0.48 + w2 * 0.34 + w3 * 0.18;

	// Vệt sáng gợn nước siêu mảnh (không bị phình thành chấm tròn trắng gắt dưới Bloom!)
	float fine_glint = smoothstep(0.84, 0.97, ripple) * 0.42;

	// Viền bọt mảnh dịu dọc sát mép bờ đá
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge_dist = min(edge_x, edge_y);
	float shore_foam = (1.0 - smoothstep(0.0, 0.055, edge_dist + ripple * 0.006)) * 0.34;

	// Quầng phản chiếu đèn lồng vàng ấm dịu nhẹ trên mặt nước
	float g1 = length((UV - vec2(0.26, 0.55)) * vec2(1.1, 1.3));
	float warm_glow = exp(-g1 * g1 * 9.0) * (0.78 + 0.22 * sin(t * 2.8 + w1 * 1.8));

	vec3 base_water = mix(deep_color.rgb, shallow_color.rgb, smoothstep(-0.6, 0.7, ripple));
	base_water = mix(base_water, foam_color.rgb, shore_foam);
	ALBEDO = mix(base_water, lantern_reflect_color.rgb, clamp(warm_glow * 0.42, 0.0, 0.50));
	// Giữ Emission dịu dưới ngưỡng HDR Bloom để mặt nước luôn trong xanh sâu thẳm không bị chói trắng!
	EMISSION = foam_color.rgb * (fine_glint * 0.32 + shore_foam * 0.12) + lantern_reflect_color.rgb * warm_glow * 0.45;
	ALPHA = 0.94;
	METALLIC = 0.18;
	SPECULAR = 0.42;
	ROUGHNESS = clamp(0.18 + abs(ripple) * 0.08, 0.12, 0.34);
	NORMAL_MAP = normalize(vec3(w2 * 0.10, w1 * 0.14, 1.0)) * 0.5 + 0.5;
}
