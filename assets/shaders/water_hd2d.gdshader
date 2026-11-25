shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
// Shader mặt nước HD-2D nâng cấp: gợn sóng nhiều tầng + tia sáng phản chiếu lấp lánh như ánh đèn lồng trên mặt hồ đêm

uniform vec4 shallow_color : source_color = vec4(0.08, 0.16, 0.28, 0.92);
uniform vec4 deep_color : source_color = vec4(0.02, 0.05, 0.12, 0.97);
uniform vec4 sparkle_color : source_color = vec4(0.95, 0.88, 0.72, 1.0);
uniform float wave_speed : hint_range(0.1, 4.0) = 1.5;
uniform float wave_scale : hint_range(1.0, 50.0) = 18.0;
uniform float roughness_val : hint_range(0.02, 0.4) = 0.06;

void fragment() {
	vec2 p1 = UV * wave_scale + vec2(TIME * wave_speed * 0.35, TIME * wave_speed * 0.22);
	vec2 p2 = UV * (wave_scale * 1.45) - vec2(TIME * wave_speed * 0.28, -TIME * wave_speed * 0.32);
	vec2 p3 = UV * (wave_scale * 2.2) + vec2(-TIME * wave_speed * 0.18, TIME * wave_speed * 0.40);

	float w1 = sin(p1.x) * cos(p1.y);
	float w2 = sin(p2.x + p2.y);
	float w3 = cos(p3.x - p3.y * 1.2);
	float ripple = (w1 + w2 + w3 * 0.6) / 2.6;

	// Điểm sáng lấp lánh li ti trên mặt nước đêm (giống ảnh Windferry Hamlet)
	float sparkle = smoothstep(0.62, 0.86, abs(w1 * w2 + w3 * 0.45));

	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, smoothstep(-0.5, 0.7, ripple));
	EMISSION = sparkle_color.rgb * sparkle * 0.55;
	METALLIC = 0.55;
	SPECULAR = 1.0;
	ROUGHNESS = clamp(roughness_val + ripple * 0.03, 0.02, 0.25);
	NORMAL_MAP = normalize(vec3((w1 + w3 * 0.5) * 0.22, (w2 - w3 * 0.4) * 0.22, 1.0)) * 0.5 + 0.5;
}
