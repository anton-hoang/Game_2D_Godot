class_name StageMapLayouts
extends RefCounted
## Bộ thiết kế kiến trúc bản đồ chuyên biệt cho 5 màn chơi chiến đấu HD-2D:
## - Màn 1 ("autumn_forest"): Rừng Thu Ngoại Ô Windferry (đường mòn đất, lán trại, đống lửa, rừng lá thu dày đặc, suối nhỏ).
## - Màn 2 ("moonlit_bridge"): Thung Lũng Cầu Đá Ánh Trăng (2 hồ nước lớn 2 bên, cây cầu đá rộng ở giữa, 2 tháp canh ven sông).
## - Màn 3 ("rainy_market"): Khu Chợ Đêm Trong Cơn Mưa (quảng trường đá ướt, 4 sạp hàng mái vải nhiều màu, đài phun nước giữa sân).
## - Màn 4 ("ancient_fortress"): Cổ Thành Đêm Sâu (tường thành pháo đài răng cưa, cổng vòm khổng lồ, 6 chậu lửa cháy rực, 4 hố gai chiến thuật).
## - Màn 5 ("eclipse_citadel"): Tế Đàn Nguyệt Thực Malakor (đấu trường bát giác đỏ đen, 6 trụ đá cổ khắc ấn đỏ phát sáng, bệ thờ Boss).


static func build_stage_map(builder: HD2DEnvironmentBuilder, root: Node3D, theme: String) -> void:
	match theme:
		"autumn_forest":
			_build_autumn_forest(builder, root)
		"moonlit_bridge":
			_build_moonlit_bridge(builder, root)
		"rainy_market":
			_build_rainy_market(builder, root)
		"ancient_fortress":
			_build_ancient_fortress(builder, root)
		"eclipse_citadel":
			_build_eclipse_citadel(builder, root)
		_:
			_build_autumn_forest(builder, root)


## ============================================================================
## MÀN 1: RỪNG THU NGOẠI Ô WINDFERRY (Golden Hour — Lá vàng, Lán trại, Đống lửa)
## ============================================================================
static func _build_autumn_forest(b: HD2DEnvironmentBuilder, root: Node3D) -> void:
	var grass_mat := b._make_textured_material(Color(0.24, 0.28, 0.14), Color(0.16, 0.20, 0.09), 0.92, "grass")
	var dirt_mat := b._make_textured_material(Color(0.42, 0.29, 0.17), Color(0.30, 0.20, 0.11), 0.88, "dirt")
	var wood_mat := b._make_textured_material(Color(0.32, 0.19, 0.11), Color(0.22, 0.13, 0.07), 0.88, "wood")
	var tent_mat := b._make_textured_material(Color(0.76, 0.64, 0.44), Color(0.60, 0.48, 0.32), 0.86, "brick")
	var stone_mat := b._make_textured_material(Color(0.34, 0.33, 0.36), Color(0.22, 0.21, 0.25), 0.84, "cobble")

	b._create_arena_ground(root, grass_mat)
	# Con đường đất uốn nhẹ chạy xuyên rừng thu
	b._add_box_mesh(root, Vector3(52.0, 0.08, 6.2), Vector3(0.0, 0.02, 1.2), dirt_mat)
	b._add_box_mesh(root, Vector3(14.0, 0.08, 9.0), Vector3(0.0, 0.02, -3.5), dirt_mat)

	# Con suối nhỏ phía góc phải dưới
	b._create_water_plane(root, Vector2(10.0, 7.5), Vector3(13.5, 0.05, 5.2))
	b._add_hazard(root, "water_hazard", Vector3(13.5, 0.0, 5.8), Vector3(9.0, 1.2, 5.0), 18)

	# Dãy đồi thấp & 2 Lều trại lính trinh sát ở hậu cảnh
	b._add_box_mesh(root, Vector3(58.0, 1.8, 12.0), Vector3(0.0, 0.9, -14.5), grass_mat)
	for tx: float in [-9.5, 8.5]:
		var tent := MeshInstance3D.new()
		var pr := PrismMesh.new()
		pr.size = Vector3(5.2, 3.0, 4.4)
		tent.mesh = pr
		tent.position = Vector3(tx, 1.5, -7.2)
		tent.material_override = tent_mat
		root.add_child(tent)
		# Hàng cọc gỗ bảo vệ trại
		b._add_box_mesh(root, Vector3(5.6, 0.9, 0.25), Vector3(tx, 0.45, -4.7), wood_mat)

	# Đống lửa trại rực sáng giữa rừng + khúc gỗ ngồi
	b._create_campfire(root, Vector3(-0.5, 0.0, -5.2), stone_mat, wood_mat)
	b._add_box_mesh(root, Vector3(2.4, 0.42, 0.48), Vector3(-3.2, 0.21, -5.0), wood_mat)
	b._add_box_mesh(root, Vector3(2.4, 0.42, 0.48), Vector3(2.2, 0.21, -5.0), wood_mat)

	# 4 cột đèn gỗ treo ven đường mòn + Cổng gỗ mái cong dẫn vào Rừng Thu
	for lp: Vector3 in [Vector3(-12.0, 0.0, -2.5), Vector3(-4.0, 0.0, 4.5), Vector3(5.5, 0.0, -2.5), Vector3(11.0, 0.0, 1.5)]:
		b._create_lantern_post(root, lp, Color(1.0, 0.72, 0.28), 2.4)
	b.create_curved_wooden_gate(root, Vector3(-14.5, 0.0, 1.2), 82.0, "RỪNG THU QUAN")
	b.create_red_lantern_string(root, Vector3(-9.5, 3.8, -5.2), Vector3(8.5, 3.8, -5.2), 6)

	# Rừng cây lá thu vàng cam dày đặc tạo không khí chiều thu rực rỡ
	var autumn_tex := PixelArtGenerator.get_prop_texture("tree_autumn")
	var tree_tex := PixelArtGenerator.get_prop_texture("tree")
	var bush_tex := PixelArtGenerator.get_prop_texture("bush")
	var flower_tex := PixelArtGenerator.get_prop_texture("flower_cluster")

	for x_pos: float in [-20.0, -15.5, -11.0, -5.0, 0.0, 4.8, 12.5, 17.5, 21.5]:
		var tex := autumn_tex if (int(abs(x_pos)) % 2 == 0) else tree_tex
		b._spawn_foliage_sprite_to(root, tex, Vector3(x_pos, 0.8, -11.2 + randf_range(-1.5, 1.0)), 0.11, 4.1)
	for x_fg: float in [-16.0, -9.0, -2.0, 4.0, 9.0, 16.0]:
		b._spawn_foliage_sprite_to(root, flower_tex, Vector3(x_fg, 0.0, 7.8), 0.068, 0.58)
	for bx: float in [-14.0, -6.5, 3.5, 12.0]:
		b._spawn_foliage_sprite_to(root, bush_tex, Vector3(bx, 0.0, -6.5), 0.072, 0.75)

	b._spawn_breakables_at(root, [
		["barrel", Vector3(-7.0, 0.0, -3.5)],
		["crate", Vector3(-6.0, 0.0, -3.8)],
		["barrel", Vector3(6.5, 0.0, -3.6)],
		["crate", Vector3(7.6, 0.0, -3.2)],
		["barrel", Vector3(1.5, 0.0, 5.0)],
	])


## ============================================================================
## MÀN 2: THUNG LŨNG CẦU ĐÁ ÁNH TRĂNG (Blue Night — 2 Hồ nước lớn, Cầu đá đôi)
## ============================================================================
static func _build_moonlit_bridge(b: HD2DEnvironmentBuilder, root: Node3D) -> void:
	var grass_mat := b._make_textured_material(Color(0.11, 0.20, 0.16), Color(0.07, 0.14, 0.12), 0.92, "grass")
	var stone_mat := b._make_textured_material(Color(0.28, 0.30, 0.38), Color(0.18, 0.20, 0.26), 0.80, "brick")
	var cobble_mat := b._make_textured_material(Color(0.32, 0.33, 0.40), Color(0.20, 0.22, 0.28), 0.78, "cobble")

	b._create_arena_ground(root, grass_mat)
	# Mặt nước rộng trải dài phía trước và phía sau cầu đá
	b._create_water_plane(root, Vector2(52.0, 6.2), Vector3(0.0, 0.05, 6.2))
	b._create_water_plane(root, Vector2(52.0, 5.5), Vector3(0.0, 0.05, -6.8))

	# Đấu trường chính là con đê & cây cầu đá cổ khổng lồ chạy ngang qua hồ
	b._add_box_mesh(root, Vector3(50.0, 0.35, 8.6), Vector3(0.0, 0.15, 0.0), cobble_mat)
	# Bờ thành đá thấp hai bên cầu (chừa 2 lối hở để người chơi đánh bay quái xuống hồ nước!)
	for sx: float in [-14.0, 0.0, 14.0]:
		b._add_box_mesh(root, Vector3(8.5, 0.75, 0.42), Vector3(sx, 0.45, -4.1), stone_mat)
		b._add_box_mesh(root, Vector3(8.5, 0.75, 0.42), Vector3(sx, 0.45, 4.1), stone_mat)

	# 2 Tháp canh bằng đá 2 đầu cầu
	for tx: float in [-16.5, 16.5]:
		b._add_box_mesh(root, Vector3(4.2, 6.5, 4.2), Vector3(tx, 3.25, -8.8), stone_mat)
		b._add_box_mesh(root, Vector3(4.8, 0.6, 4.8), Vector3(tx, 6.6, -8.8), cobble_mat)
		b._create_brazier(root, Vector3(tx, 6.9, -8.8), Color(0.45, 0.85, 1.0))

	# Bẫy nước 2 bên rìa cầu (đánh quái văng ra mép cầu sẽ rơi xuống hồ nước nhận sát thương!)
	b._add_hazard(root, "water_hazard", Vector3(0.0, 0.0, 6.4), Vector3(42.0, 1.2, 3.6), 24)
	b._add_hazard(root, "water_hazard", Vector3(0.0, 0.0, -6.6), Vector3(42.0, 1.2, 3.4), 24)

	# 6 cột đèn xanh vàng dọc lan can cầu + Cổng gỗ mái cong cổ trang giữa cầu & dây đèn lồng đỏ
	for lx: float in [-12.0, -4.0, 4.0, 12.0]:
		b._create_lantern_post(root, Vector3(lx, 0.2, -3.8), Color(1.0, 0.74, 0.34), 2.9)
		b._create_lantern_post(root, Vector3(lx, 0.2, 3.8), Color(0.58, 0.82, 1.0), 2.2)
	b.create_curved_wooden_gate(root, Vector3(0.0, 0.25, -4.4), 0.0, "NGUYỆT KIỀU")
	b.create_red_lantern_string(root, Vector3(-12.0, 4.4, -3.8), Vector3(12.0, 4.4, -3.8), 7)

	var pine_tex := PixelArtGenerator.get_prop_texture("pine")
	for px: float in [-22.0, -12.0, -6.0, 0.0, 6.0, 12.0, 22.0]:
		b._spawn_foliage_sprite_to(root, pine_tex, Vector3(px, 0.0, -12.5), 0.12, 4.4)

	b._spawn_breakables_at(root, [
		["barrel", Vector3(-9.0, 0.2, -2.5)],
		["crate", Vector3(-8.0, 0.2, -2.5)],
		["barrel", Vector3(8.5, 0.2, 2.4)],
		["crate", Vector3(9.5, 0.2, 2.4)],
	])


## ============================================================================
## MÀN 3: KHU CHỢ ĐÊM TRONG CƠN MƯA (Rainy Night — Sạp vải, Đài phun nước)
## ============================================================================
static func _build_rainy_market(b: HD2DEnvironmentBuilder, root: Node3D) -> void:
	var wet_stone := b._make_textured_material(Color(0.22, 0.24, 0.30), Color(0.14, 0.16, 0.22), 0.35, "cobble")
	var brick_mat := b._make_textured_material(Color(0.28, 0.25, 0.28), Color(0.18, 0.16, 0.20), 0.75, "brick")
	var wood_mat := b._make_textured_material(Color(0.30, 0.18, 0.11), Color(0.20, 0.12, 0.07), 0.82, "wood")

	b._create_arena_ground(root, wet_stone)

	# Tường phố thị trấn phía sau với các vòm cửa sáng đèn
	b._add_box_mesh(root, Vector3(54.0, 5.2, 2.0), Vector3(0.0, 2.6, -10.5), brick_mat)
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(1.0, 0.78, 0.32)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.58, 0.16)
	win_mat.emission_energy_multiplier = 3.2
	b._window_materials.append(win_mat)
	for wx: float in [-16.0, -8.0, 0.0, 8.0, 16.0]:
		b._add_box_mesh(root, Vector3(1.8, 2.2, 0.2), Vector3(wx, 2.5, -9.45), win_mat)

	# 4 Sạp hàng Chợ Đêm mái vải sọc đỏ/xanh/vàng dọc phía sau quảng trường
	var awning_colors := [Color(0.76, 0.18, 0.20), Color(0.18, 0.42, 0.68), Color(0.82, 0.58, 0.16), Color(0.22, 0.52, 0.34)]
	var stall_xs: Array[float] = [-13.5, -4.5, 4.5, 13.5]
	for i in range(stall_xs.size()):
		var sx: float = stall_xs[i]
		var amat := StandardMaterial3D.new()
		amat.albedo_color = awning_colors[i]
		amat.roughness = 0.78
		b._add_box_mesh(root, Vector3(4.6, 1.1, 1.8), Vector3(sx, 0.55, -7.2), wood_mat) # Quầy gỗ
		b._add_box_mesh(root, Vector3(0.2, 2.8, 0.2), Vector3(sx - 2.1, 1.4, -6.5), wood_mat)
		b._add_box_mesh(root, Vector3(0.2, 2.8, 0.2), Vector3(sx + 2.1, 1.4, -6.5), wood_mat)
		var roof := b._add_box_mesh(root, Vector3(5.0, 0.22, 2.6), Vector3(sx, 2.85, -7.1), amat)
		roof.rotation_degrees.x = 14.0
		b._create_lantern_post(root, Vector3(sx + 2.4, 0.0, -5.8), Color(1.0, 0.52, 0.22), 2.8)

	# Cổng Chợ Đêm mái cong & 2 dây đèn lồng đỏ giăng chéo rực rỡ giữa quảng trường mưa!
	b.create_curved_wooden_gate(root, Vector3(0.0, 0.0, -6.2), 0.0, "CHỢ ĐÊM PHONG VŨ")
	b.create_red_lantern_string(root, Vector3(-14.5, 4.6, -5.5), Vector3(0.0, 5.0, -5.5), 5)
	b.create_red_lantern_string(root, Vector3(0.0, 5.0, -5.5), Vector3(14.5, 4.6, -5.5), 5)

	# Đài phun nước đá cổ ngay trung tâm quảng trường
	b._add_box_mesh(root, Vector3(4.2, 0.7, 4.2), Vector3(0.0, 0.35, -1.2), brick_mat)
	b._create_water_plane(root, Vector2(3.6, 3.6), Vector3(0.0, 0.72, -1.2))
	b._add_box_mesh(root, Vector3(0.9, 2.4, 0.9), Vector3(0.0, 1.35, -1.2), brick_mat)

	# 2 Hố gai cống ngầm 2 bên quảng trường
	b._add_hazard(root, "spike_pit", Vector3(-9.5, 0.0, 3.2), Vector3(3.0, 1.0, 2.4), 26)
	b._add_hazard(root, "spike_pit", Vector3(9.5, 0.0, 3.2), Vector3(3.0, 1.0, 2.4), 26)

	b._spawn_breakables_at(root, [
		["crate", Vector3(-12.5, 0.0, -4.6)],
		["barrel", Vector3(-11.4, 0.0, -4.5)],
		["crate", Vector3(11.5, 0.0, -4.6)],
		["barrel", Vector3(12.6, 0.0, -4.5)],
		["barrel", Vector3(-3.0, 0.0, 4.8)],
		["crate", Vector3(3.2, 0.0, 4.8)],
	])


## ============================================================================
## MÀN 4: CỔ THÀNH ĐÊM SÂU (Deep Midnight — Tường thành, Chậu lửa, 4 Hố gai)
## ============================================================================
static func _build_ancient_fortress(b: HD2DEnvironmentBuilder, root: Node3D) -> void:
	var fort_floor := b._make_textured_material(Color(0.20, 0.21, 0.26), Color(0.12, 0.13, 0.18), 0.72, "cobble")
	var fort_wall := b._make_textured_material(Color(0.24, 0.25, 0.32), Color(0.14, 0.15, 0.20), 0.80, "brick")
	var banner_mat := StandardMaterial3D.new()
	banner_mat.albedo_color = Color(0.16, 0.28, 0.56)

	b._create_arena_ground(root, fort_floor)
	# Thảm đá đường diễu hành chính giữa sân thành
	b._add_box_mesh(root, Vector3(44.0, 0.06, 4.8), Vector3(0.0, 0.03, 1.0), fort_wall)

	# Tường thành đá lớn răng cưa (Battlements) phía sau & Cổng vòm khổng lồ
	b._add_box_mesh(root, Vector3(56.0, 6.2, 2.4), Vector3(0.0, 3.1, -9.8), fort_wall)
	for mx: float in [-22.0, -18.0, -14.0, -10.0, -6.0, -2.0, 2.0, 6.0, 10.0, 14.0, 18.0, 22.0]:
		b._add_box_mesh(root, Vector3(2.2, 1.4, 2.6), Vector3(mx, 6.8, -9.8), fort_wall)

	# Cổng sắt pháo đài ở chính giữa tường thành + Cờ hiệu hoàng gia 2 bên
	var gate_mat := StandardMaterial3D.new()
	gate_mat.albedo_color = Color(0.06, 0.06, 0.10)
	b._add_box_mesh(root, Vector3(5.4, 4.8, 0.4), Vector3(0.0, 2.4, -8.5), gate_mat)
	for gx: float in [-7.5, -3.8, 3.8, 7.5]:
		b._add_box_mesh(root, Vector3(1.1, 3.6, 0.12), Vector3(gx, 3.6, -8.5), banner_mat)

	# 6 Chậu lửa pháo đài (Braziers) cháy cam rực trong Màn Đêm Sâu
	for bp: Vector3 in [
		Vector3(-12.5, 0.0, -7.2), Vector3(-4.2, 0.0, -7.2), Vector3(4.2, 0.0, -7.2),
		Vector3(12.5, 0.0, -7.2), Vector3(-12.5, 0.0, 5.2), Vector3(12.5, 0.0, 5.2),
	]:
		b._create_brazier(root, bp, Color(1.0, 0.56, 0.18))

	# 4 Hố gai phòng thủ chiến thuật bố trí 4 góc sân thành
	for sp: Vector3 in [Vector3(-9.0, 0.0, -2.5), Vector3(9.0, 0.0, -2.5), Vector3(-9.0, 0.0, 4.5), Vector3(9.0, 0.0, 4.5)]:
		b._add_hazard(root, "spike_pit", sp, Vector3(2.8, 1.0, 2.4), 30)

	b._spawn_breakables_at(root, [
		["crate", Vector3(-15.5, 0.0, 0.5)],
		["barrel", Vector3(-15.2, 0.0, 1.8)],
		["crate", Vector3(15.5, 0.0, 0.5)],
		["barrel", Vector3(15.2, 0.0, 1.8)],
	])


## ============================================================================
## MÀN 5: TẾ ĐÀN NGUYỆT THỰC MALAKOR (Crimson Eclipse — Đấu trường Boss)
## ============================================================================
static func _build_eclipse_citadel(b: HD2DEnvironmentBuilder, root: Node3D) -> void:
	var obsidian_mat := b._make_textured_material(Color(0.13, 0.09, 0.16), Color(0.07, 0.05, 0.10), 0.58, "cobble")
	var dark_stone := b._make_textured_material(Color(0.20, 0.14, 0.24), Color(0.11, 0.07, 0.15), 0.76, "brick")
	var rune_mat := StandardMaterial3D.new()
	rune_mat.albedo_color = Color(1.0, 0.22, 0.34)
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(1.0, 0.18, 0.32)
	rune_mat.emission_energy_multiplier = 4.0
	b._window_materials.append(rune_mat)

	b._create_arena_ground(root, obsidian_mat)

	# Vòng tròn cổ ngữ đỏ phát sáng khổng lồ giữa đấu trường Boss
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 6.2
	tm.outer_radius = 6.55
	ring.mesh = tm
	ring.position = Vector3(0.0, 0.06, 0.8)
	ring.material_override = rune_mat
	root.add_child(ring)

	# Bệ thờ Hắc Ám & Ngai Vàng đổ nát phía sau đấu trường
	b._add_box_mesh(root, Vector3(14.0, 1.2, 5.5), Vector3(0.0, 0.6, -9.2), dark_stone)
	b._add_box_mesh(root, Vector3(9.5, 2.2, 3.8), Vector3(0.0, 1.7, -10.4), dark_stone)
	b._add_box_mesh(root, Vector3(3.2, 6.2, 1.2), Vector3(0.0, 4.5, -11.5), dark_stone)
	b._add_box_mesh(root, Vector3(1.2, 4.4, 0.2), Vector3(0.0, 4.5, -10.8), rune_mat)

	# 6 Trụ đá Obelisk cổ đại có khắc ấn đỏ phát sáng bao quanh sân đấu
	var pillars: Array[Vector3] = [
		Vector3(-15.5, 0.0, -7.0), Vector3(-8.5, 0.0, -8.0),
		Vector3(8.5, 0.0, -8.0), Vector3(15.5, 0.0, -7.0),
		Vector3(-16.0, 0.0, 4.8), Vector3(16.0, 0.0, 4.8),
	]
	for pp in pillars:
		b._add_box_mesh(root, Vector3(1.6, 7.2, 1.6), pp + Vector3(0.0, 3.6, 0.0), dark_stone)
		b._add_box_mesh(root, Vector3(0.35, 5.6, 1.72), pp + Vector3(0.0, 3.4, 0.0), rune_mat)
		b._create_brazier(root, pp + Vector3(0.0, 7.3, 0.0), Color(1.0, 0.24, 0.36))

	# 2 Hố gai hắc ám rìa sân đấu
	b._add_hazard(root, "spike_pit", Vector3(-11.5, 0.0, 1.5), Vector3(2.8, 1.0, 2.8), 32)
	b._add_hazard(root, "spike_pit", Vector3(11.5, 0.0, 1.5), Vector3(2.8, 1.0, 2.8), 32)

	b._spawn_breakables_at(root, [
		["barrel", Vector3(-12.5, 0.0, -4.5)],
		["crate", Vector3(-11.5, 0.0, -4.5)],
		["barrel", Vector3(11.5, 0.0, -4.5)],
		["crate", Vector3(12.5, 0.0, -4.5)],
	])
