class_name HD2DEnvironmentBuilder
extends Node3D
## Dựng cảnh làng cổ 2.5D HD-2D nâng cấp (phong cách Windferry Hamlet / Octopath Traveler):
## - Bầu trời đêm có Mặt Trăng phát sáng & các vì sao lấp lánh + Dãy núi mờ phía xa.
## - Tường kè đá nhiều tầng chi tiết có mũ tường, cầu đá vòm bậc thang, suối nước phản chiếu ánh đèn.
## - Nhà gỗ khung nửa gỗ (half-timbered) có bồn hoa cửa sổ, ống khói tỏa khói, dây cờ phơi giữa 2 nhà.
## - Đạo cụ làng ven đường: thùng gỗ, ghế băng gỗ, hòm hàng, hàng rào gỗ, khóm cỏ hoa tiền cảnh tạo Tilt-Shift.
## - 5 chế độ ánh sáng: "golden_hour" (Hoàng hôn), "blue_night" (Đêm xanh), "midnight" (Màn Đêm Sâu),
##   "rainy_night" (Đêm mưa), "crimson_eclipse" (Nguyệt thực Boss).

var world_env: WorldEnvironment
var sun_light: DirectionalLight3D
var rain_particles: GPUParticles3D
var firefly_particles: GPUParticles3D
var moon_node: MeshInstance3D
var stars_root: Node3D
var _lantern_lights: Array[OmniLight3D] = []
var _lantern_base_energies: Array[float] = []
var _window_materials: Array[StandardMaterial3D] = []
var current_time_of_day: String = "midnight"
var _flicker_time: float = 0.0


func _ready() -> void:
	_build_lighting_and_postfx()
	_build_night_sky_and_mountains()
	_build_terrain_and_walls()
	_build_cottages()
	_build_village_props()
	_build_lanterns()
	_build_trees_and_foliage()
	_build_atmosphere_particles()
	apply_time_of_day(current_time_of_day)


func _process(delta: float) -> void:
	# Hiệu ứng lửa đèn lồng lập lòe nhẹ rất sống động trong màn đêm HD-2D
	_flicker_time += delta * 5.2
	for i in range(_lantern_lights.size()):
		var l := _lantern_lights[i]
		if is_instance_valid(l) and i < _lantern_base_energies.size():
			var wave := sin(_flicker_time + float(i) * 1.7) * 0.14 + cos(_flicker_time * 1.9 + float(i)) * 0.08
			l.light_energy = maxf(0.4, _lantern_base_energies[i] + wave)


## Thay đổi thời điểm ánh sáng của màn chơi:
## "golden_hour", "blue_night", "midnight" (Màn Đêm Sâu), "rainy_night", "crimson_eclipse"
func apply_time_of_day(mode: String) -> void:
	current_time_of_day = mode
	if world_env == null or world_env.environment == null or sun_light == null:
		return
	var env := world_env.environment

	match mode:
		"golden_hour":
			sun_light.light_color = Color(1.0, 0.72, 0.40)
			sun_light.light_energy = 1.45
			sun_light.rotation_degrees = Vector3(-26.0, -35.0, 0.0)
			env.background_color = Color(0.28, 0.18, 0.24)
			env.ambient_light_color = Color(0.50, 0.34, 0.28)
			env.ambient_light_energy = 0.72
			env.fog_light_color = Color(0.62, 0.38, 0.30)
			env.fog_density = 0.013
			env.glow_bloom = 0.25
			_set_lantern_power(1.6)
			_set_night_sky_visible(false, Color(1.0, 0.92, 0.75))
			if rain_particles:
				rain_particles.emitting = false
			if firefly_particles:
				firefly_particles.amount = 45

		"midnight":
			# MÀN ĐÊM SÂU (Deep Midnight): Trời đen xanh thẳm, trăng sáng bạc, sao lấp lánh,
			# đèn lồng và cửa sổ nhà gỗ tỏa sáng rực rỡ ấm áp tương phản mạnh!
			sun_light.light_color = Color(0.38, 0.50, 0.88)
			sun_light.light_energy = 0.42
			sun_light.rotation_degrees = Vector3(-46.0, 22.0, 0.0)
			env.background_color = Color(0.02, 0.03, 0.08)
			env.ambient_light_color = Color(0.09, 0.13, 0.25)
			env.ambient_light_energy = 0.34
			env.fog_light_color = Color(0.07, 0.10, 0.20)
			env.fog_density = 0.021
			env.glow_bloom = 0.42
			_set_lantern_power(3.5)
			_set_night_sky_visible(true, Color(0.86, 0.92, 1.0))
			if rain_particles:
				rain_particles.emitting = false
			if firefly_particles:
				firefly_particles.amount = 110

		"rainy_night":
			sun_light.light_color = Color(0.42, 0.56, 0.82)
			sun_light.light_energy = 0.48
			sun_light.rotation_degrees = Vector3(-42.0, 25.0, 0.0)
			env.background_color = Color(0.04, 0.07, 0.13)
			env.ambient_light_color = Color(0.14, 0.20, 0.32)
			env.ambient_light_energy = 0.40
			env.fog_light_color = Color(0.14, 0.20, 0.32)
			env.fog_density = 0.025
			env.glow_bloom = 0.36
			_set_lantern_power(3.0)
			_set_night_sky_visible(true, Color(0.65, 0.78, 0.95))
			if rain_particles:
				rain_particles.emitting = true

		"crimson_eclipse":
			# Đêm Nguyệt Thực Đỏ cho màn Boss
			sun_light.light_color = Color(0.95, 0.28, 0.38)
			sun_light.light_energy = 0.65
			sun_light.rotation_degrees = Vector3(-40.0, 15.0, 0.0)
			env.background_color = Color(0.08, 0.02, 0.06)
			env.ambient_light_color = Color(0.24, 0.08, 0.14)
			env.ambient_light_energy = 0.42
			env.fog_light_color = Color(0.28, 0.08, 0.15)
			env.fog_density = 0.022
			env.glow_bloom = 0.44
			_set_lantern_power(3.2)
			_set_night_sky_visible(true, Color(1.0, 0.22, 0.28))
			if rain_particles:
				rain_particles.emitting = true

		_: # "blue_night" (Đêm xanh chạng vạng giống ảnh mẫu Windferry Hamlet)
			sun_light.light_color = Color(0.52, 0.65, 0.94)
			sun_light.light_energy = 0.65
			sun_light.rotation_degrees = Vector3(-40.0, 28.0, 0.0)
			env.background_color = Color(0.07, 0.10, 0.18)
			env.ambient_light_color = Color(0.18, 0.24, 0.38)
			env.ambient_light_energy = 0.50
			env.fog_light_color = Color(0.18, 0.22, 0.35)
			env.fog_density = 0.017
			env.glow_bloom = 0.32
			_set_lantern_power(2.7)
			_set_night_sky_visible(true, Color(0.88, 0.93, 1.0))
			if rain_particles:
				rain_particles.emitting = false


func _set_night_sky_visible(is_night: bool, moon_tint: Color) -> void:
	if stars_root:
		stars_root.visible = is_night
	if moon_node:
		moon_node.visible = is_night
		var mat := moon_node.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = moon_tint
			mat.emission = moon_tint


func _set_lantern_power(energy: float) -> void:
	_lantern_base_energies.clear()
	for l in _lantern_lights:
		if is_instance_valid(l):
			l.light_energy = energy
			_lantern_base_energies.append(energy)
	for m in _window_materials:
		if m:
			m.emission_energy_multiplier = energy * 1.25


func _build_lighting_and_postfx() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.16, 0.28)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.08

	# Hậu kỳ HD-2D: Glow / Bloom ấm áp cho ánh đèn lồng & cửa sổ
	env.glow_enabled = true
	env.glow_intensity = 1.25
	env.glow_strength = 1.12
	env.glow_bloom = 0.38
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 0.80

	# Hậu kỳ Fog chiều sâu
	env.fog_enabled = true
	env.fog_light_color = Color(0.10, 0.14, 0.24)
	env.fog_density = 0.020
	env.fog_aerial_perspective = 0.40

	# Hậu kỳ SSAO tạo chiều sâu các khe đá & mái nhà
	env.ssao_enabled = true
	env.ssao_radius = 1.35
	env.ssao_intensity = 1.55

	# Chỉnh màu sắc điện ảnh
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.18

	world_env.environment = env
	add_child(world_env)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "DirectionalLight3D"
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_max_distance = 75.0
	sun_light.shadow_blur = 1.3
	add_child(sun_light)


## Bầu trời đêm: Mặt trăng tròn tỏa hào quang, dải sao lấp lánh & dãy núi mờ phía chân trời
func _build_night_sky_and_mountains() -> void:
	# Mặt trăng lớn trên bầu trời đêm phía xa
	moon_node = MeshInstance3D.new()
	moon_node.name = "NightMoon"
	var moon_sphere := SphereMesh.new()
	moon_sphere.radius = 2.8
	moon_sphere.height = 5.6
	moon_node.mesh = moon_sphere
	moon_node.position = Vector3(-16.0, 17.5, -42.0)
	var moon_mat := StandardMaterial3D.new()
	moon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_mat.albedo_color = Color(0.90, 0.95, 1.0)
	moon_mat.emission_enabled = true
	moon_mat.emission = Color(0.85, 0.92, 1.0)
	moon_mat.emission_energy_multiplier = 2.6
	moon_node.material_override = moon_mat
	add_child(moon_node)

	# Các vì sao lấp lánh trên nền trời đêm
	stars_root = Node3D.new()
	stars_root.name = "NightStars"
	add_child(stars_root)
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.albedo_color = Color(0.92, 0.96, 1.0)
	star_mat.emission_enabled = true
	star_mat.emission = Color(0.88, 0.94, 1.0)
	star_mat.emission_energy_multiplier = 2.2

	var star_quad := QuadMesh.new()
	star_quad.size = Vector2(0.18, 0.18)
	var rng := RandomNumberGenerator.new()
	rng.seed = 202611
	for i in range(65):
		var st := MeshInstance3D.new()
		st.mesh = star_quad
		st.material_override = star_mat
		st.position = Vector3(rng.randf_range(-42.0, 42.0), rng.randf_range(10.0, 26.0), rng.randf_range(-48.0, -34.0))
		var s := rng.randf_range(0.6, 1.7)
		st.scale = Vector3(s, s, 1.0)
		stars_root.add_child(st)

	# Dãy núi & đồi thông mờ phía hậu cảnh tạo chiều sâu nhiều lớp
	var mountain_mat := StandardMaterial3D.new()
	mountain_mat.albedo_color = Color(0.08, 0.11, 0.18)
	mountain_mat.roughness = 0.95
	var peaks := [
		[Vector3(-28.0, 4.0, -32.0), Vector3(24.0, 14.0, 10.0)],
		[Vector3(-8.0, 5.0, -35.0), Vector3(28.0, 17.0, 12.0)],
		[Vector3(16.0, 4.5, -33.0), Vector3(26.0, 15.0, 11.0)],
		[Vector3(34.0, 3.8, -31.0), Vector3(22.0, 13.0, 10.0)],
	]
	for pk in peaks:
		var m := MeshInstance3D.new()
		var pr := PrismMesh.new()
		pr.size = pk[1]
		m.mesh = pr
		m.position = pk[0]
		m.material_override = mountain_mat
		add_child(m)


func _build_terrain_and_walls() -> void:
	var stone_cobble_mat := _make_textured_material(Color(0.30, 0.28, 0.33), Color(0.18, 0.17, 0.22), 0.78, "cobble")
	var dirt_path_mat := _make_textured_material(Color(0.34, 0.25, 0.18), Color(0.24, 0.17, 0.12), 0.90, "dirt")
	var grass_mat := _make_textured_material(Color(0.13, 0.22, 0.14), Color(0.08, 0.15, 0.10), 0.92, "grass")
	var stone_wall_mat := _make_textured_material(Color(0.27, 0.28, 0.34), Color(0.16, 0.17, 0.22), 0.82, "brick")
	var stone_trim_mat := _make_textured_material(Color(0.36, 0.37, 0.42), Color(0.24, 0.25, 0.30), 0.76, "cobble")

	# Mặt đất tầng dưới (Đấu trường chính)
	var ground_body := StaticBody3D.new()
	ground_body.name = "ArenaGround"
	add_child(ground_body)
	var ground_col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(60.0, 2.0, 30.0)
	ground_col.shape = box_shape
	ground_col.position = Vector3(0.0, -1.0, 0.0)
	ground_body.add_child(ground_col)

	_add_box_mesh(ground_body, Vector3(60.0, 2.0, 30.0), Vector3(0.0, -1.0, 0.0), grass_mat)
	# Con đường lát đá cuội chạy qua làng (bên phải & giữa) và đường đất ấm (bên trái)
	_add_box_mesh(ground_body, Vector3(32.0, 0.09, 7.6), Vector3(8.0, 0.02, 1.5), stone_cobble_mat)
	_add_box_mesh(ground_body, Vector3(20.0, 0.08, 7.2), Vector3(-15.0, 0.015, 0.5), dirt_path_mat)

	# Suối & Hồ nước phản chiếu lấp lánh bên trái
	var water_mesh := MeshInstance3D.new()
	water_mesh.name = "HamletPond"
	var plane := PlaneMesh.new()
	plane.size = Vector2(14.0, 10.5)
	plane.subdivide_width = 40
	plane.subdivide_depth = 40
	water_mesh.mesh = plane
	water_mesh.position = Vector3(-8.2, 0.06, 3.6)
	var water_shader := load("res://assets/shaders/water_hd2d.gdshader") as Shader
	if water_shader:
		var smat := ShaderMaterial.new()
		smat.shader = water_shader
		water_mesh.material_override = smat
	add_child(water_mesh)

	# Cây cầu đá vòm có bậc cong & lan can trụ đá giống ảnh mẫu Windferry
	var bridge_root := Node3D.new()
	bridge_root.name = "StoneBridge"
	bridge_root.position = Vector3(-7.6, 0.0, 0.7)
	add_child(bridge_root)
	_add_box_mesh(bridge_root, Vector3(5.6, 0.35, 3.4), Vector3(0.0, 0.16, 0.0), stone_wall_mat)
	_add_box_mesh(bridge_root, Vector3(3.4, 0.58, 3.4), Vector3(0.0, 0.32, 0.0), stone_cobble_mat)
	# Lan can 2 bên cầu có trụ đá đầu cầu
	for bz: float in [-1.55, 1.55]:
		_add_box_mesh(bridge_root, Vector3(5.6, 0.85, 0.32), Vector3(0.0, 0.58, bz), stone_wall_mat)
		_add_box_mesh(bridge_root, Vector3(5.7, 0.16, 0.42), Vector3(0.0, 1.02, bz), stone_trim_mat)
		for bx: float in [-2.6, 0.0, 2.6]:
			_add_box_mesh(bridge_root, Vector3(0.45, 1.15, 0.48), Vector3(bx, 0.62, bz), stone_trim_mat)

	# Tường kè đá tầng 2 chạy dài phía sau với mũ đá nhô ra
	_add_box_mesh(self, Vector3(58.0, 2.7, 1.6), Vector3(0.0, 1.35, -9.2), stone_wall_mat)
	_add_box_mesh(self, Vector3(58.0, 0.24, 1.95), Vector3(0.0, 2.72, -9.15), stone_trim_mat)
	# Trụ đá tăng cường dọc tường kè
	for px: float in [-20.0, -12.0, -4.0, 4.0, 16.0, 24.0]:
		_add_box_mesh(self, Vector3(0.85, 2.8, 0.55), Vector3(px, 1.4, -8.35), stone_trim_mat)

	# Nền tầng 2 phía sau tường đá (có CollisionShape3D để Player đi bộ lên tham quan và vào 3 ngôi nhà!)
	var upper_body := StaticBody3D.new()
	upper_body.name = "UpperTerraceGround"
	add_child(upper_body)
	var upper_col := CollisionShape3D.new()
	var upper_box := BoxShape3D.new()
	upper_box.size = Vector3(58.0, 2.6, 16.0)
	upper_col.shape = upper_box
	upper_col.position = Vector3(0.0, 1.30, -17.5)
	upper_body.add_child(upper_col)
	_add_box_mesh(upper_body, Vector3(58.0, 2.6, 16.0), Vector3(0.0, 1.30, -17.5), grass_mat)
	# Con đường lát đá tầng 2 nối trước cửa 3 ngôi nhà gỗ
	_add_box_mesh(upper_body, Vector3(38.0, 0.08, 2.6), Vector3(2.0, 2.62, -9.8), stone_cobble_mat)

	# Bậc thang đá cổ + dốc va chạm mượt (ramp collider) đi lên tầng 2 ở bên phải
	for step_i in range(7):
		_add_box_mesh(
			self,
			Vector3(3.8, 0.40, 1.25),
			Vector3(10.6, 0.20 + float(step_i) * 0.39, -7.2 - float(step_i) * 0.45),
			stone_cobble_mat
		)
	var ramp_body := StaticBody3D.new()
	ramp_body.name = "StairsRamp"
	add_child(ramp_body)
	var ramp_col := CollisionShape3D.new()
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = Vector3(3.8, 0.35, 4.6)
	ramp_col.shape = ramp_shape
	ramp_col.position = Vector3(10.6, 1.28, -8.35)
	ramp_col.rotation_degrees = Vector3(34.0, 0.0, 0.0)
	ramp_body.add_child(ramp_col)

	_add_box_mesh(self, Vector3(0.38, 1.9, 3.6), Vector3(8.55, 1.15, -8.5), stone_wall_mat)
	_add_box_mesh(self, Vector3(0.38, 1.9, 3.6), Vector3(12.65, 1.15, -8.5), stone_wall_mat)

	# BẪY ĐỊA HÌNH 3D: Suối nước sâu bên trái (đánh bay quái rơi xuống suối chịu sát thương) & 2 Hố gai sắt
	var water_haz := HazardZone3D.new()
	water_haz.name = "PondHazard"
	water_haz.hazard_type = "water_hazard"
	water_haz.zone_size = Vector3(11.5, 1.2, 6.2)
	water_haz.damage_per_tick = 22
	water_haz.position = Vector3(-8.4, 0.0, 4.8)
	add_child(water_haz)

	for sp_pos: Vector3 in [Vector3(12.8, 0.0, 4.8), Vector3(0.5, 0.0, -5.2)]:
		var spike_haz := HazardZone3D.new()
		spike_haz.hazard_type = "spike_pit"
		spike_haz.zone_size = Vector3(2.8, 1.0, 2.4)
		spike_haz.damage_per_tick = 28
		spike_haz.position = sp_pos
		add_child(spike_haz)


func _build_cottages() -> void:
	# 3 ngôi nhà gỗ có NỘI THẤT BÊN TRONG & HIỆU ỨNG CUTAWAY TỰ MỜ MẶT TIỀN khi bước vào cửa!
	_create_cottage(Vector3(-12.0, 2.6, -13.4), Color(0.68, 0.58, 0.46), Color(0.24, 0.17, 0.14), true, "Xưởng Rèn Cổ", 40)
	_create_cottage(Vector3(2.2, 2.6, -13.0), Color(0.80, 0.68, 0.56), Color(0.28, 0.16, 0.14), true, "Quán Trọ Windferry", 50)
	_create_cottage(Vector3(16.2, 2.6, -13.4), Color(0.70, 0.64, 0.56), Color(0.18, 0.22, 0.34), false, "Kho Hàng Thương Nhân", 65)

	# Dây cờ vải nhiều màu treo giữa nhà giữa và nhà bên phải (chi tiết đắt giá giống ảnh Windferry!)
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.32, 0.24, 0.18)
	_add_box_mesh(self, Vector3(7.2, 0.06, 0.06), Vector3(9.4, 5.1, -10.8), rope_mat)
	var flag_colors := [Color(0.22, 0.42, 0.78), Color(0.92, 0.88, 0.78), Color(0.82, 0.24, 0.24), Color(0.92, 0.88, 0.78), Color(0.24, 0.56, 0.34)]
	for fi in range(flag_colors.size()):
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = flag_colors[fi]
		fmat.roughness = 0.85
		var sag: float = sin(float(fi + 1) / 6.0 * PI) * 0.45
		_add_box_mesh(self, Vector3(0.85, 1.05, 0.08), Vector3(6.8 + float(fi) * 1.25, 4.55 - sag, -10.8), fmat)


## Dựng ngôi nhà gỗ 2 phần tách biệt:
## 1) Khung nhà sau & Nội thất ấm cúng (sàn gỗ, thảm đỏ, lò sưởi lửa cháy, bàn gỗ + nến, rương báu mở được bằng [E]).
## 2) Mặt tiền & Mái nhà (facade_root) có Area3D cảm biến: khi Player bước vào nhà, mặt tiền tự mờ đi (Seamless Cutaway)!
func _create_cottage(pos: Vector3, plaster_col: Color, roof_col: Color, has_chimney: bool, room_title: String, chest_gold: int) -> void:
	var house := Node3D.new()
	house.position = pos
	add_child(house)

	var wall_mat := _make_textured_material(plaster_col, plaster_col.darkened(0.16), 0.85, "brick")
	var stone_base_mat := _make_textured_material(Color(0.30, 0.30, 0.34), Color(0.20, 0.20, 0.24), 0.84, "cobble")
	var wood_mat := _make_textured_material(Color(0.26, 0.15, 0.10), Color(0.18, 0.10, 0.07), 0.86, "wood")
	var floor_wood_mat := _make_textured_material(Color(0.38, 0.23, 0.13), Color(0.28, 0.16, 0.09), 0.80, "wood")
	var shutter_mat := StandardMaterial3D.new()
	shutter_mat.albedo_color = Color(0.18, 0.28, 0.32)
	shutter_mat.roughness = 0.85
	var roof_mat := _make_textured_material(roof_col, roof_col.darkened(0.26), 0.78, "brick")

	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(1.0, 0.82, 0.38)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.64, 0.18)
	win_mat.emission_energy_multiplier = 3.2
	_window_materials.append(win_mat)

	# --- PHẦN 1: NỘI THẤT BÊN TRONG & TƯỜNG SAU / 2 TƯỜNG HÔNG ---
	# Sàn gỗ nội thất + Thảm đỏ ấm cúng
	_add_box_mesh(house, Vector3(7.6, 0.14, 5.2), Vector3(0.0, 0.08, 0.0), floor_wood_mat)
	var rug_mat := StandardMaterial3D.new()
	rug_mat.albedo_color = Color(0.62, 0.14, 0.18)
	_add_box_mesh(house, Vector3(3.6, 0.05, 2.4), Vector3(0.0, 0.16, 0.3), rug_mat)

	# Tường sau & 2 tường bên (luôn giữ nguyên để tạo không gian phòng ấm cúng khi mặt tiền ẩn đi)
	_add_box_mesh(house, Vector3(7.8, 4.7, 0.32), Vector3(0.0, 2.35, -2.55), wall_mat)
	_add_box_mesh(house, Vector3(0.32, 4.7, 5.4), Vector3(-3.75, 2.35, 0.0), wall_mat)
	_add_box_mesh(house, Vector3(0.32, 4.7, 5.4), Vector3(3.75, 2.35, 0.0), wall_mat)

	# Lò sưởi đá có lửa cháy rực cam đỏ ở tường sau bên trái
	_add_box_mesh(house, Vector3(1.8, 2.2, 0.85), Vector3(-2.1, 1.1, -2.0), stone_base_mat)
	var fire_mat := StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.62, 0.15)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.45, 0.10)
	fire_mat.emission_energy_multiplier = 4.2
	_add_box_mesh(house, Vector3(0.95, 0.85, 0.35), Vector3(-2.1, 0.58, -1.58), fire_mat)
	var hearth_light := OmniLight3D.new()
	hearth_light.position = Vector3(-2.1, 1.0, -1.1)
	hearth_light.light_color = Color(1.0, 0.56, 0.18)
	hearth_light.light_energy = 2.6
	hearth_light.omni_range = 6.5
	house.add_child(hearth_light)
	_lantern_lights.append(hearth_light)
	_lantern_base_energies.append(2.6)

	# Bàn gỗ + Ghế đẩu + Cây nến sáng giữa phòng
	_add_box_mesh(house, Vector3(1.8, 0.14, 1.1), Vector3(0.2, 0.82, -0.8), wood_mat)
	_add_box_mesh(house, Vector3(0.16, 0.80, 0.16), Vector3(-0.55, 0.40, -1.2), wood_mat)
	_add_box_mesh(house, Vector3(0.16, 0.80, 0.16), Vector3(0.95, 0.40, -1.2), wood_mat)
	_add_box_mesh(house, Vector3(0.14, 0.32, 0.14), Vector3(0.2, 1.04, -0.8), win_mat)

	# Rương báu mở được bằng phím [E] đặt ở góc phải trong nhà
	var chest := TreasureChest3D.new()
	chest.gold_reward = chest_gold
	chest.position = Vector3(2.3, 0.15, -1.3)
	house.add_child(chest)

	# Biển tên phòng phía trên cửa
	var sign_lbl := Label3D.new()
	sign_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_lbl.pixel_size = 0.0085
	sign_lbl.font_size = 26
	sign_lbl.outline_size = 8
	sign_lbl.position = Vector3(0.0, 2.75, 2.95)
	sign_lbl.modulate = Color(1.0, 0.90, 0.55)
	sign_lbl.text = room_title + "\n(Đi vào cửa để mở nội thất)"
	house.add_child(sign_lbl)

	# --- PHẦN 2: MẶT TIỀN & MÁI NHÀ (Tự ẩn/hiện mượt mà khi bước vào trong) ---
	var facade := Node3D.new()
	facade.name = "CutawayFacade"
	house.add_child(facade)

	# Tường mặt tiền 2 bên cửa chính (chừa khoảng trống ở giữa cho người chơi bước thẳng vào)
	_add_box_mesh(facade, Vector3(3.1, 4.7, 0.28), Vector3(-2.35, 2.35, 2.60), wall_mat)
	_add_box_mesh(facade, Vector3(3.1, 4.7, 0.28), Vector3(2.35, 2.35, 2.60), wall_mat)
	_add_box_mesh(facade, Vector3(1.8, 2.45, 0.28), Vector3(0.0, 3.48, 2.60), wall_mat)

	# Khung xà gỗ nửa gỗ mặt tiền
	_add_box_mesh(facade, Vector3(8.0, 0.24, 0.34), Vector3(0.0, 2.55, 2.64), wood_mat)
	_add_box_mesh(facade, Vector3(8.0, 0.24, 0.34), Vector3(0.0, 4.70, 2.64), wood_mat)
	for tx: float in [-3.85, -1.10, 1.10, 3.85]:
		_add_box_mesh(facade, Vector3(0.24, 4.6, 0.34), Vector3(tx, 2.35, 2.64), wood_mat)

	# Bậc thềm đá & đèn tường trước cửa
	_add_box_mesh(house, Vector3(2.0, 0.16, 0.85), Vector3(0.0, 0.08, 3.05), stone_base_mat)
	_add_box_mesh(facade, Vector3(0.30, 0.36, 0.30), Vector3(1.05, 1.95, 2.86), win_mat)

	# Cửa sổ phát sáng vàng ấm có chấn song & bồn hoa
	var flower_box_mat := StandardMaterial3D.new()
	flower_box_mat.albedo_color = Color(0.22, 0.44, 0.20)
	for wx: float in [-2.55, 2.55]:
		for wy: float in [1.65, 3.55]:
			_add_box_mesh(facade, Vector3(1.32, 1.10, 0.16), Vector3(wx, wy, 2.72), win_mat)
			_add_box_mesh(facade, Vector3(0.10, 1.14, 0.22), Vector3(wx, wy, 2.75), wood_mat)
			_add_box_mesh(facade, Vector3(1.36, 0.10, 0.22), Vector3(wx, wy, 2.75), wood_mat)
			_add_box_mesh(facade, Vector3(0.32, 1.12, 0.14), Vector3(wx - 0.82, wy, 2.74), shutter_mat)
			_add_box_mesh(facade, Vector3(0.32, 1.12, 0.14), Vector3(wx + 0.82, wy, 2.74), shutter_mat)
			_add_box_mesh(facade, Vector3(1.45, 0.26, 0.35), Vector3(wx, wy - 0.66, 2.86), wood_mat)
			_add_box_mesh(facade, Vector3(1.30, 0.24, 0.28), Vector3(wx, wy - 0.48, 2.86), flower_box_mat)

	# Mái nhà dốc & ống khói thuộc nhóm Cutaway để khi vào nhà nhìn xuống nội thất cực thoáng
	var roof_mesh := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(8.8, 3.1, 6.4)
	roof_mesh.mesh = prism
	roof_mesh.position = Vector3(0.0, 6.25, 0.0)
	roof_mesh.material_override = roof_mat
	facade.add_child(roof_mesh)

	if has_chimney:
		_add_box_mesh(facade, Vector3(0.85, 2.4, 0.85), Vector3(-2.6, 6.9, -0.8), stone_base_mat)
		_add_box_mesh(facade, Vector3(1.05, 0.22, 1.05), Vector3(-2.6, 8.15, -0.8), stone_base_mat)

	# Cảm biến Cutaway: Khi Player đi qua cửa vào bên trong, mặt tiền & mái tự động co/ẩn mượt mà!
	var interior_sensor := Area3D.new()
	interior_sensor.name = "InteriorCutawaySensor"
	var s_col := CollisionShape3D.new()
	var s_box := BoxShape3D.new()
	s_box.size = Vector3(7.4, 3.8, 5.4)
	s_col.shape = s_box
	s_col.position = Vector3(0.0, 1.9, 0.1)
	interior_sensor.add_child(s_col)
	house.add_child(interior_sensor)

	interior_sensor.body_entered.connect(func(body: Node) -> void:
		if body and body.is_in_group("player"):
			var tw := facade.create_tween()
			tw.tween_property(facade, "scale", Vector3(1.0, 0.01, 1.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func() -> void: facade.visible = false)
			sign_lbl.visible = false
	)
	interior_sensor.body_exited.connect(func(body: Node) -> void:
		if body and body.is_in_group("player"):
			facade.visible = true
			var tw := facade.create_tween()
			tw.tween_property(facade, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			sign_lbl.visible = true
	)

	# Ánh sáng cam ấm tỏa ra trước ngôi nhà
	var house_glow := OmniLight3D.new()
	house_glow.position = Vector3(0.0, 2.2, 4.0)
	house_glow.light_color = Color(1.0, 0.62, 0.22)
	house_glow.light_energy = 2.8
	house_glow.omni_range = 10.5
	house_glow.shadow_enabled = true
	house.add_child(house_glow)
	_lantern_lights.append(house_glow)
	_lantern_base_energies.append(2.8)


## Các đạo cụ làng ven đường: Ghế băng gỗ, hàng rào gỗ và các Thùng rượu / Hòm hàng PHÁ HỦY ĐƯỢC rơi Vàng/Máu!
func _build_village_props() -> void:
	var wood_mat := _make_textured_material(Color(0.32, 0.20, 0.12), Color(0.22, 0.13, 0.08), 0.88, "wood")
	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.18, 0.19, 0.22)
	iron_mat.metallic = 0.65

	# Ghế băng gỗ ven bờ suối bên trái
	var bench := Node3D.new()
	bench.position = Vector3(-13.8, 0.0, -2.5)
	add_child(bench)
	_add_box_mesh(bench, Vector3(2.2, 0.14, 0.65), Vector3(0.0, 0.55, 0.0), wood_mat)
	_add_box_mesh(bench, Vector3(2.2, 0.55, 0.12), Vector3(0.0, 0.90, -0.28), wood_mat)
	_add_box_mesh(bench, Vector3(0.16, 0.55, 0.55), Vector3(-0.85, 0.27, 0.0), iron_mat)
	_add_box_mesh(bench, Vector3(0.16, 0.55, 0.55), Vector3(0.85, 0.27, 0.0), iron_mat)

	# Hàng rào gỗ cổ dọc 2 bên rìa làng
	for fx: float in [-20.5, -18.5, -16.5, 17.5, 19.5, 21.5]:
		_add_box_mesh(self, Vector3(0.18, 1.25, 0.18), Vector3(fx, 0.62, -6.8), wood_mat)
	_add_box_mesh(self, Vector3(4.5, 0.14, 0.10), Vector3(-18.5, 0.95, -6.8), wood_mat)
	_add_box_mesh(self, Vector3(4.5, 0.14, 0.10), Vector3(-18.5, 0.50, -6.8), wood_mat)
	_add_box_mesh(self, Vector3(4.5, 0.14, 0.10), Vector3(19.5, 0.95, -6.8), wood_mat)
	_add_box_mesh(self, Vector3(4.5, 0.14, 0.10), Vector3(19.5, 0.50, -6.8), wood_mat)

	spawn_breakable_props()


## Sinh lại các thùng rượu & hòm hàng phá hủy được mỗi khi vào làng hoặc bắt đầu màn chơi mới
func spawn_breakable_props() -> void:
	for old_b in get_tree().get_nodes_in_group("breakables"):
		if is_instance_valid(old_b):
			old_b.queue_free()

	var specs := [
		["barrel", Vector3(14.2, 0.0, -5.2)],
		["barrel", Vector3(15.3, 0.0, -5.5)],
		["crate", Vector3(16.4, 0.0, -4.7)],
		["barrel", Vector3(-15.5, 0.0, -5.8)],
		["crate", Vector3(-14.3, 0.0, -5.6)],
		["barrel", Vector3(-2.5, 0.0, -5.8)],
		["crate", Vector3(5.6, 0.0, 5.2)],
		["barrel", Vector3(6.8, 0.0, 5.4)],
	]
	for sp in specs:
		var br := BreakableProp3D.new()
		br.prop_kind = str(sp[0])
		br.position = sp[1]
		add_child(br)


func _build_lanterns() -> void:
	# 8 cột đèn đường phát sáng vàng ấm dọc cầu đá, bờ suối, đường cuội và tầng 2
	var lantern_positions: Array[Vector3] = [
		Vector3(-13.8, 0.0, 1.2),
		Vector3(-5.0, 0.0, -0.8),
		Vector3(6.8, 0.0, 2.2),
		Vector3(14.5, 0.0, -0.4),
		Vector3(-16.5, 0.0, -4.5),
		Vector3(-4.5, 2.65, -9.2),
		Vector3(8.5, 2.65, -9.2),
		Vector3(18.5, 2.65, -9.2),
	]
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.14, 0.13, 0.16)
	post_mat.roughness = 0.78
	post_mat.metallic = 0.35

	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1.0, 0.90, 0.52)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.68, 0.22)
	bulb_mat.emission_energy_multiplier = 3.8
	_window_materials.append(bulb_mat)

	for p in lantern_positions:
		var post := Node3D.new()
		post.position = p
		add_child(post)
		_add_box_mesh(post, Vector3(0.28, 0.22, 0.28), Vector3(0.0, 0.11, 0.0), post_mat) # Đế cột
		_add_box_mesh(post, Vector3(0.16, 2.25, 0.16), Vector3(0.0, 1.15, 0.0), post_mat) # Thân cột
		_add_box_mesh(post, Vector3(0.62, 0.12, 0.16), Vector3(0.22, 2.22, 0.0), post_mat) # Tay treo đèn
		_add_box_mesh(post, Vector3(0.42, 0.10, 0.42), Vector3(0.42, 2.12, 0.0), post_mat) # Chóp lồng đèn
		_add_box_mesh(post, Vector3(0.32, 0.42, 0.32), Vector3(0.42, 1.86, 0.0), bulb_mat) # Lồng kính sáng

		var light := OmniLight3D.new()
		light.position = Vector3(0.42, 1.82, 0.0)
		light.light_color = Color(1.0, 0.66, 0.24)
		light.light_energy = 2.8
		light.omni_range = 8.8
		light.shadow_enabled = true
		post.add_child(light)
		_lantern_lights.append(light)
		_lantern_base_energies.append(2.8)


func _build_trees_and_foliage() -> void:
	var tree_tex := PixelArtGenerator.get_prop_texture("tree")
	var autumn_tex := PixelArtGenerator.get_prop_texture("tree_autumn")
	var pine_tex := PixelArtGenerator.get_prop_texture("pine")
	var bush_tex := PixelArtGenerator.get_prop_texture("bush")
	var grass_tex := PixelArtGenerator.get_prop_texture("grass_tuft")
	var flower_tex := PixelArtGenerator.get_prop_texture("flower_cluster")

	# Cây cổ thụ khổng lồ giữa làng & 2 bên hậu cảnh (giống ảnh Windferry)
	var giant_tree := _spawn_foliage_sprite(tree_tex, Vector3(-4.8, 2.6, -15.8), 0.135, 5.2)
	giant_tree.name = "GiantVillageTree"

	var tree_specs := [
		[tree_tex, Vector3(-18.5, 2.6, -12.0), 0.095, 3.6],
		[autumn_tex, Vector3(9.8, 2.6, -15.2), 0.10, 3.8],
		[tree_tex, Vector3(21.5, 2.6, -11.8), 0.095, 3.6],
		[pine_tex, Vector3(-23.0, 2.6, -18.0), 0.11, 4.0],
		[pine_tex, Vector3(-14.0, 2.6, -20.5), 0.12, 4.4],
		[pine_tex, Vector3(2.5, 2.6, -21.0), 0.125, 4.6],
		[pine_tex, Vector3(15.0, 2.6, -20.0), 0.115, 4.2],
		[pine_tex, Vector3(24.5, 2.6, -18.5), 0.11, 4.0],
		[tree_tex, Vector3(-20.5, 0.0, -4.8), 0.088, 3.3],
		[autumn_tex, Vector3(21.0, 0.0, -4.5), 0.088, 3.3],
	]
	for ts in tree_specs:
		_spawn_foliage_sprite(ts[0], ts[1], ts[2], ts[3])

	# Các bụi cây rậm rạp dọc chân tường kè đá & tầng trên
	var bush_positions: Array[Vector3] = [
		Vector3(-15.0, 0.0, -7.8),
		Vector3(-10.5, 0.0, -7.9),
		Vector3(-6.2, 0.0, -7.8),
		Vector3(-1.8, 0.0, -7.9),
		Vector3(2.8, 0.0, -7.8),
		Vector3(6.8, 0.0, -7.9),
		Vector3(15.2, 0.0, -7.8),
		Vector3(-7.0, 2.6, -10.5),
		Vector3(-1.5, 2.6, -10.5),
		Vector3(12.2, 2.6, -10.5),
	]
	for bp in bush_positions:
		_spawn_foliage_sprite(bush_tex, bp, 0.068, 0.72)

	# Cỏ cao & khóm hoa ven suối và ở tiền cảnh (Foreground) để tạo chiều sâu Tilt-Shift DOF cực đẹp
	var grass_positions: Array[Vector3] = [
		Vector3(-15.5, 0.0, 6.2), Vector3(-12.2, 0.0, 7.6), Vector3(-8.5, 0.0, 8.3),
		Vector3(-3.8, 0.0, 7.8), Vector3(0.5, 0.0, 8.2), Vector3(4.5, 0.0, 7.6),
		Vector3(9.2, 0.0, 8.0), Vector3(13.8, 0.0, 7.5), Vector3(17.5, 0.0, 6.8),
		Vector3(-3.2, 0.0, 3.8), Vector3(-1.8, 0.0, 5.2), Vector3(-14.2, 0.0, 4.2),
		Vector3(-11.5, 0.0, -4.8), Vector3(4.2, 0.0, -5.5), Vector3(13.0, 0.0, -4.6),
	]
	for i in range(grass_positions.size()):
		var tex := flower_tex if (i % 3 == 0) else grass_tex
		_spawn_foliage_sprite(tex, grass_positions[i], 0.062, 0.56)


func _spawn_foliage_sprite(tex: Texture2D, pos: Vector3, px_size: float, y_lift: float) -> Sprite3D:
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = px_size
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sp.shaded = true
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	sp.position = pos + Vector3(0.0, y_lift, 0.0)
	add_child(sp)
	return sp


func _build_atmosphere_particles() -> void:
	# Hạt đom đóm vàng ấm bay lượn dày đặc trong màn đêm HD-2D
	firefly_particles = GPUParticles3D.new()
	firefly_particles.name = "Fireflies"
	firefly_particles.amount = 110
	firefly_particles.lifetime = 5.2
	firefly_particles.position = Vector3(0.0, 2.8, -2.0)

	var ff_mat := ParticleProcessMaterial.new()
	ff_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ff_mat.emission_box_extents = Vector3(24.0, 3.8, 12.0)
	ff_mat.gravity = Vector3(0.0, 0.06, 0.0)
	ff_mat.initial_velocity_min = 0.18
	ff_mat.initial_velocity_max = 0.65
	ff_mat.scale_min = 0.06
	ff_mat.scale_max = 0.16
	firefly_particles.process_material = ff_mat

	var ff_quad := QuadMesh.new()
	ff_quad.size = Vector2(0.16, 0.16)
	var ff_draw_mat := StandardMaterial3D.new()
	ff_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ff_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	ff_draw_mat.albedo_color = Color(1.0, 0.88, 0.44, 0.90)
	ff_draw_mat.emission_enabled = true
	ff_draw_mat.emission = Color(1.0, 0.80, 0.32)
	ff_draw_mat.emission_energy_multiplier = 2.4
	ff_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ff_quad.material = ff_draw_mat
	firefly_particles.draw_pass_1 = ff_quad
	add_child(firefly_particles)

	# Hạt mưa rơi chéo có độ bóng cho màn đêm mưa & nguyệt thực
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 420
	rain_particles.lifetime = 1.05
	rain_particles.emitting = false
	rain_particles.position = Vector3(0.0, 12.0, 0.0)

	var rain_mat := ParticleProcessMaterial.new()
	rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_mat.emission_box_extents = Vector3(26.0, 1.0, 14.0)
	rain_mat.direction = Vector3(-0.18, -1.0, 0.0)
	rain_mat.spread = 2.5
	rain_mat.initial_velocity_min = 15.0
	rain_mat.initial_velocity_max = 18.0
	rain_mat.gravity = Vector3(0.0, -9.8, 0.0)
	rain_particles.process_material = rain_mat

	var rain_quad := QuadMesh.new()
	rain_quad.size = Vector2(0.032, 0.52)
	var rain_draw_mat := StandardMaterial3D.new()
	rain_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	rain_draw_mat.albedo_color = Color(0.72, 0.84, 1.0, 0.46)
	rain_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_quad.material = rain_draw_mat
	rain_particles.draw_pass_1 = rain_quad
	add_child(rain_particles)


func _add_box_mesh(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _make_textured_material(c1: Color, c2: Color, rough: float, pattern: String) -> StandardMaterial3D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var c3 := c1.lightened(0.10)
	for y in range(24):
		for x in range(24):
			var col := c1
			if pattern == "brick":
				var row := y / 6
				var offset := (row % 2) * 6
				if (y % 6 == 0) or ((x + offset) % 12 == 0):
					col = c2
				elif (y % 6 == 1) and ((x + offset) % 12 > 1):
					col = c3
			elif pattern == "cobble":
				var hash_v := (x * 11 + y * 17) % 9
				if (x % 6 == 0) or (y % 6 == 0):
					col = c2
				elif hash_v == 0 or hash_v == 3:
					col = c3
			elif pattern == "wood":
				col = c2 if (y % 4 == 0) else (c3 if ((x + y * 3) % 11 == 0) else c1)
			else:
				var n := (x * 7 + y * 13 + x * y) % 7
				col = c2 if n <= 1 else (c3 if n == 6 else c1)
			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.42, 0.42, 0.42)
	mat.roughness = rough
	return mat
