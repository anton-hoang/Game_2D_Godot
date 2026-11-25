shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
// Shader viền sáng ngược (Rim Lighting) cho Sprite 2D Pixel Art trong thế giới 3D HD-2D:
// Tự động phát hiện rìa trong suốt của nhân vật/quái để tạo hào quang viền sáng ấm áp (như ánh đèn lồng/ánh trăng hắt sau lưng).

uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform vec4 modulate_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.78, 0.42, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 1.15;
uniform float rim_thickness : hint_range(0.5, 3.0) = 1.35;
uniform bool flip_h = false;

void vertex() {
	// Billboard cố định trục Y (BILLBOARD_FIXED_Y) luôn xoay mặt về phía Camera 3D
	vec3 cam_forward = -normalize(vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z));
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = normalize(cross(up, cam_forward));
	mat4 bb = mat4(
		vec4(right, 0.0),
		vec4(up, 0.0),
		vec4(cam_forward, 0.0),
		MODEL_MATRIX[3]
	);
	vec3 scaled_v = VERTEX * vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
	VERTEX = scaled_v;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV;
	if (flip_h) {
		uv.x = 1.0 - uv.x;
	}
	vec4 tex_col = texture(albedo_tex, uv);
	if (tex_col.a < 0.5) {
		discard;
	}

	// Kiểm tra pixel lân cận phía trên/trái/phải để tìm cạnh rìa silhouette nhân vật
	vec2 px = (1.0 / vec2(textureSize(albedo_tex, 0))) * rim_thickness;
	float a_top = texture(albedo_tex, uv + vec2(0.0, -px.y)).a;
	float a_left = texture(albedo_tex, uv + vec2(-px.x, 0.0)).a;
	float a_right = texture(albedo_tex, uv + vec2(px.x, 0.0)).a;
	float edge = clamp(1.0 - min(a_top, min(a_left, a_right)), 0.0, 1.0);

	// Ưu tiên viền sáng mạnh hơn ở phần đầu & vai (UV.y < 0.65)
	float top_bias = smoothstep(0.95, 0.15, uv.y);
	float rim_factor = edge * (0.45 + 0.55 * top_bias);

	vec3 base_rgb = tex_col.rgb * modulate_color.rgb;
	ALBEDO = base_rgb;
	EMISSION = rim_color.rgb * rim_factor * rim_strength;
	ROUGHNESS = 0.85;
	ALPHA = tex_col.a * modulate_color.a;
}
