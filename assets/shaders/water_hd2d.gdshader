shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
// Shader mặt hồ sen & suối Tiên Hiệp Anime HD-2D:
// Trong sâu xanh lam ngọc, phản chiếu ánh trăng & đèn hoa đăng mềm mại, hoàn toàn không bị vệt cam gắt hay chấm Bloom trắng!

uniform vec4 shallow_color : source_color = vec4(0.13, 0.30, 0.46, 0.94);
uniform vec4 deep_color : source_color = vec4(0.05, 0.12, 0.26, 0.98);
uniform vec4 foam_color : source_color = vec4(0.76, 0.92, 1.0, 1.0);
uniform vec4 lantern_reflect_color : source_color = vec4(1.0, 0.78, 0.42, 1.0);
uniform float wave_speed : hint_range(0.1, 4.0) = 0.72;
uniform float wave_scale : hint_range(1.0, 60.0) = 20.0;

void fragment() {
	float t = TIME * wave_speed;
	vec2 uv_s = UV * vec2(wave_scale * 0.7, wave_scale * 1.35);

	// Gợn sóng tĩnh lặng mềm mại trên mặt hồ sen
	float w1 = sin(uv_s.y + sin(uv_s.x * 0.45 + t * 0.5) * 0.9 - t * 0.9);
	float w2 = cos(uv_s.y * 1.4 - uv_s.x * 0.35 + t * 0.65);
	float ripple = w1 * 0.55 + w2 * 0.45;

	// Vệt sáng ánh trăng lấp lánh dịu mắt
	float moon_glint = smoothstep(0.86, 0.98, ripple) * 0.24;

	// Viền bọt mảnh dịu dọc sát mép bờ đá
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge_dist = min(edge_x, edge_y);
	float shore_foam = (1.0 - smoothstep(0.0, 0.048, edge_dist + ripple * 0.004)) * 0.28;

	// Quầng phản chiếu đèn hoa đăng vàng ấm tán xạ nhẹ đều (không còn vệt chữ Z gắt!)
	float d1 = length((UV - vec2(0.32, 0.62)) * vec2(1.4, 1.4));
	float d2 = length((UV - vec2(0.68, 0.44)) * vec2(1.4, 1.4));
	float lantern_soft = (exp(-d1 * d1 * 12.0) + exp(-d2 * d2 * 14.0)) * (0.85 + 0.15 * sin(t * 2.0));

	vec3 base_water = mix(deep_color.rgb, shallow_color.rgb, smoothstep(-0.65, 0.70, ripple));
	base_water = mix(base_water, foam_color.rgb, shore_foam);
	ALBEDO = mix(base_water, lantern_reflect_color.rgb, clamp(lantern_soft * 0.30, 0.0, 0.36));
	EMISSION = foam_color.rgb * (moon_glint * 0.22 + shore_foam * 0.10) + lantern_reflect_color.rgb * lantern_soft * 0.22;
	ALPHA = 0.94;
	METALLIC = 0.14;
	SPECULAR = 0.36;
	ROUGHNESS = clamp(0.20 + abs(ripple) * 0.06, 0.16, 0.34);
	NORMAL_MAP = normalize(vec3(w2 * 0.07, w1 * 0.09, 1.0)) * 0.5 + 0.5;
}
