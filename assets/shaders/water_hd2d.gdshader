shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
// Shader mặt hồ & thác nước Windferry Hamlet:
// Phản chiếu lấp lánh từng chấm trắng bạc & ánh đèn lồng cam vàng rực rỡ ngay trên mặt hồ như ảnh mẫu!

uniform vec4 shallow_color : source_color = vec4(0.11, 0.17, 0.27, 0.94);
uniform vec4 deep_color : source_color = vec4(0.03, 0.06, 0.13, 0.98);
uniform vec4 sparkle_color : source_color = vec4(0.98, 0.95, 0.88, 1.0);
uniform vec4 lantern_reflect_color : source_color = vec4(1.0, 0.66, 0.28, 1.0);
uniform float wave_speed : hint_range(0.1, 4.0) = 1.65;
uniform float wave_scale : hint_range(1.0, 60.0) = 26.0;

void fragment() {
	vec2 p1 = UV * wave_scale + vec2(TIME * wave_speed * 0.32, TIME * wave_speed * 0.20);
	vec2 p2 = UV * (wave_scale * 1.6) - vec2(TIME * wave_speed * 0.24, -TIME * wave_speed * 0.36);
	vec2 p3 = UV * (wave_scale * 2.8) + vec2(-TIME * wave_speed * 0.15, TIME * wave_speed * 0.45);

	float w1 = sin(p1.x) * cos(p1.y);
	float w2 = sin(p2.x + p2.y);
	float w3 = cos(p3.x - p3.y * 1.15);
	float ripple = (w1 + w2 + w3 * 0.6) / 2.6;

	// Chấm trắng lấp lánh gợn sóng sắc nét giống mặt hồ trong ảnh Windferry
	float glint = smoothstep(0.56, 0.80, abs(w1 * w2 + w3 * 0.50));
	// Vệt sáng cam vàng phản chiếu từ đèn đường bên trái mặt hồ
	float glow_dist = length((UV - vec2(0.32, 0.56)) * vec2(1.0, 1.6));
	float warm_glow = exp(-glow_dist * glow_dist * 10.5) * (0.78 + 0.22 * sin(TIME * 4.5 + w1 * 3.0));

	vec3 base_water = mix(deep_color.rgb, shallow_color.rgb, smoothstep(-0.5, 0.7, ripple));
	ALBEDO = mix(base_water, lantern_reflect_color.rgb, clamp(warm_glow * 0.75, 0.0, 0.85));
	EMISSION = sparkle_color.rgb * glint * 0.88 + lantern_reflect_color.rgb * warm_glow * 1.35;
	METALLIC = 0.52;
	SPECULAR = 1.0;
	ROUGHNESS = clamp(0.05 + ripple * 0.03, 0.02, 0.18);
	NORMAL_MAP = normalize(vec3((w1 + w3 * 0.5) * 0.24, (w2 - w3 * 0.4) * 0.24, 1.0)) * 0.5 + 0.5;
}
