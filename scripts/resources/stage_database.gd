class_name StageDatabase
extends RefCounted
## Cơ sở dữ liệu 5 màn chơi HD-2D — 7 loại quái anime đa dạng & 5 BOSS HUYỀN THOẠI (Mỗi màn 1 con Boss riêng!):
## - 7 Quái: slime (Tinh Linh Slime), wolf (Sói Ma), bandit (Đạo Tặc), ghost (Bóng Ma), warrior (Chiến Binh), kitsune (Hồ Ly), golem (Thủ Vệ Đá).
## - 5 Boss:
##   Màn 1 -> boss_kitsune  (Hồ Ly Yêu Vương)
##   Màn 2 -> boss_dragon   (Long Vương Thần)
##   Màn 3 -> boss_darklord (Ma Vương Hắc Ám)
##   Màn 4 -> boss_archmage (Pháp Sư Vĩnh Hằng)
##   Màn 5 -> boss_emperor  (Thiên Ma Cuồng Đế)


static func is_boss_id(enemy_id: String) -> bool:
	return enemy_id == "boss" or enemy_id.begins_with("boss_")


static func get_enemy_stats(enemy_id: String, stage_level: int = 1, endless_floor: int = 0) -> EnemyStats:
	var base_stats: EnemyStats = _create_default_enemy_stats(enemy_id)
	if endless_floor > 0:
		# Cân bằng chỉ số Tháp Vô Tận tăng mượt theo từng tầng (Tầng 1 -> Vô tận!)
		var hp_mult: float = 0.85 + float(endless_floor - 1) * 0.14
		var dmg_mult: float = 0.88 + float(endless_floor - 1) * 0.08
		if is_boss_id(enemy_id):
			hp_mult = 0.72 + float(endless_floor) * 0.11
			dmg_mult = 0.82 + float(endless_floor) * 0.06
		base_stats.max_hp = round(base_stats.max_hp * hp_mult)
		base_stats.attack_damage = round(base_stats.attack_damage * dmg_mult)
		base_stats.gold_drop = int(round(float(base_stats.gold_drop) * (1.0 + float(endless_floor - 1) * 0.12)))
		return base_stats

	# Tăng nhẹ chỉ số quái thường theo màn chơi (Boss đã có chỉ số thiết kế chuẩn riêng cho từng màn)
	if not is_boss_id(enemy_id):
		var scale_mult: float = 1.0 + float(stage_level - 1) * 0.12
		base_stats.max_hp = round(base_stats.max_hp * scale_mult)
		base_stats.attack_damage = round(base_stats.attack_damage * (1.0 + float(stage_level - 1) * 0.09))
	return base_stats


## Sinh đội hình quái cho từng Tầng của CỬU THIÊN THÍ LUYỆN THÁP (mỗi 3 tầng gặp 1 Boss Huyền Thoại ngẫu nhiên!)
static func get_endless_floor_wave(floor_num: int) -> Dictionary:
	var boss_pool: Array[String] = ["boss_kitsune", "boss_dragon", "boss_darklord", "boss_archmage", "boss_emperor"]
	if floor_num % 3 == 0:
		var chosen_boss: String = boss_pool[randi() % boss_pool.size()]
		var wave: Dictionary = {chosen_boss: 1}
		var adds: int = mini(4, 1 + (floor_num / 4))
		var add_pool: Array[String] = ["slime", "bandit", "wolf", "ghost", "kitsune"]
		var add_id: String = add_pool[randi() % add_pool.size()]
		wave[add_id] = adds
		return wave

	var wave_n: Dictionary = {}
	var total_budget: int = mini(10, 3 + floor_num / 2)
	var pool: Array[String] = ["slime", "bandit", "wolf"]
	if floor_num >= 2:
		pool.append("ghost")
		pool.append("kitsune")
	if floor_num >= 4:
		pool.append("warrior")
	if floor_num >= 5:
		pool.append("golem")

	for i in range(total_budget):
		var pick: String = pool[randi() % pool.size()]
		wave_n[pick] = int(wave_n.get(pick, 0)) + 1
	return wave_n


static func get_stage_data(stage_id: int) -> StageData:
	var clamped_id: int = clampi(stage_id, 1, 5)
	return _create_default_stage_data(clamped_id)


static func _create_default_enemy_stats(enemy_id: String) -> EnemyStats:
	var s := EnemyStats.new()
	s.visual_id = enemy_id
	match enemy_id:
		# =====================================================================
		# 7 LOẠI QUÁI ANIME CHIBI (HÀNG TRÊN ẢNH MẪU)
		# =====================================================================
		"slime":
			s.enemy_name = "Tinh Linh Slime"
			s.archetype = "melee"
			s.max_hp = 44.0
			s.move_speed = 3.2
			s.attack_damage = 10.0
			s.attack_range = 1.6
			s.attack_cooldown = 1.3
			s.score_value = 90
			s.gold_drop = 8
			s.aura_color = Color(0.35, 0.76, 1.0)
			s.sprite_scale = 0.95
		"wolf", "charger":
			s.enemy_name = "Sói Ma"
			s.visual_id = "wolf"
			s.archetype = "charger"
			s.max_hp = 68.0
			s.move_speed = 4.1
			s.attack_damage = 17.0
			s.attack_range = 4.8
			s.attack_cooldown = 1.85
			s.knockback_resistance = 0.22
			s.score_value = 155
			s.gold_drop = 12
			s.aura_color = Color(0.32, 0.72, 1.0)
			s.sprite_scale = 1.06
		"bandit", "melee":
			s.enemy_name = "Đạo Tặc"
			s.visual_id = "bandit"
			s.archetype = "melee"
			s.max_hp = 58.0
			s.move_speed = 3.7
			s.attack_damage = 13.0
			s.attack_range = 1.75
			s.attack_cooldown = 1.15
			s.score_value = 115
			s.gold_drop = 10
			s.aura_color = Color(0.95, 0.45, 0.25)
			s.sprite_scale = 1.0
		"ghost", "ranged":
			s.enemy_name = "Bóng Ma"
			s.visual_id = "ghost"
			s.archetype = "ranged"
			s.max_hp = 48.0
			s.move_speed = 3.0
			s.attack_damage = 15.0
			s.attack_range = 8.6
			s.attack_cooldown = 1.80
			s.score_value = 140
			s.gold_drop = 12
			s.aura_color = Color(0.76, 0.34, 1.0)
			s.projectile_color = Color(0.80, 0.32, 1.0)
			s.sprite_scale = 1.02
		"kitsune":
			s.enemy_name = "Hồ Ly"
			s.archetype = "ranged"
			s.max_hp = 64.0
			s.move_speed = 3.5
			s.attack_damage = 17.0
			s.attack_range = 8.2
			s.attack_cooldown = 1.65
			s.score_value = 165
			s.gold_drop = 14
			s.aura_color = Color(1.0, 0.44, 0.32)
			s.projectile_color = Color(1.0, 0.48, 0.20)
			s.sprite_scale = 1.05
		"warrior", "tank":
			s.enemy_name = "Chiến Binh"
			s.visual_id = "warrior"
			s.archetype = "tank"
			s.max_hp = 130.0
			s.move_speed = 2.35
			s.attack_damage = 21.0
			s.attack_range = 2.15
			s.attack_cooldown = 1.80
			s.knockback_resistance = 0.72
			s.shield_points = 3
			s.score_value = 220
			s.gold_drop = 18
			s.aura_color = Color(0.98, 0.28, 0.24)
			s.sprite_scale = 1.22
		"golem":
			s.enemy_name = "Thủ Vệ Đá"
			s.archetype = "tank"
			s.max_hp = 165.0
			s.move_speed = 1.95
			s.attack_damage = 25.0
			s.attack_range = 2.4
			s.attack_cooldown = 2.05
			s.knockback_resistance = 0.82
			s.shield_points = 4
			s.score_value = 260
			s.gold_drop = 22
			s.aura_color = Color(0.28, 0.94, 0.92)
			s.sprite_scale = 1.32

		# =====================================================================
		# 5 BOSS HUYỀN THOẠI (MỖI MÀN 1 CON BOSS ĐẶC TRƯNG!)
		# =====================================================================
		"boss_kitsune":
			s.enemy_name = "Hồ Ly Yêu Vương"
			s.boss_subtitle = "Boss Màn 1 • Cửu Vĩ Yêu Hồ Hoàng Kim — Hỏa Cầu Liên Hoàn!"
			s.archetype = "boss"
			s.max_hp = 290.0
			s.move_speed = 3.4
			s.attack_damage = 18.0
			s.attack_range = 4.2
			s.attack_cooldown = 1.65
			s.knockback_resistance = 0.80
			s.shield_points = 3
			s.score_value = 650
			s.gold_drop = 45
			s.aura_color = Color(1.0, 0.62, 0.22)
			s.projectile_color = Color(1.0, 0.45, 0.18)
			s.sprite_scale = 1.38
		"boss_dragon":
			s.enemy_name = "Long Vương Thần"
			s.boss_subtitle = "Boss Màn 2 • Bạch Long Thủy Thần — Cuồng Ba Hải Triều!"
			s.archetype = "boss"
			s.max_hp = 370.0
			s.move_speed = 3.2
			s.attack_damage = 21.0
			s.attack_range = 4.5
			s.attack_cooldown = 1.55
			s.knockback_resistance = 0.84
			s.shield_points = 4
			s.score_value = 800
			s.gold_drop = 55
			s.aura_color = Color(0.28, 0.76, 1.0)
			s.projectile_color = Color(0.32, 0.86, 1.0)
			s.sprite_scale = 1.46
		"boss_darklord", "boss":
			s.enemy_name = "Ma Vương Hắc Ám"
			s.visual_id = "boss_darklord"
			s.boss_subtitle = "Boss Màn 3 • Chúa Tể Bóng Đêm — Hắc Viêm Tử Thần!"
			s.archetype = "boss"
			s.max_hp = 450.0
			s.move_speed = 3.35
			s.attack_damage = 24.0
			s.attack_range = 4.0
			s.attack_cooldown = 1.50
			s.knockback_resistance = 0.86
			s.shield_points = 4
			s.score_value = 950
			s.gold_drop = 65
			s.aura_color = Color(0.78, 0.30, 1.0)
			s.projectile_color = Color(0.84, 0.30, 1.0)
			s.sprite_scale = 1.48
		"boss_archmage":
			s.enemy_name = "Pháp Sư Vĩnh Hằng"
			s.boss_subtitle = "Boss Màn 4 • Thánh Nữ Hoàng Kim — Vạn Kiếm Thánh Quang!"
			s.archetype = "boss"
			s.max_hp = 520.0
			s.move_speed = 3.1
			s.attack_damage = 26.0
			s.attack_range = 5.6
			s.attack_cooldown = 1.45
			s.knockback_resistance = 0.88
			s.shield_points = 5
			s.score_value = 1150
			s.gold_drop = 80
			s.aura_color = Color(1.0, 0.88, 0.32)
			s.projectile_color = Color(1.0, 0.86, 0.30)
			s.sprite_scale = 1.48
		"boss_emperor":
			s.enemy_name = "Thiên Ma Cuồng Đế"
			s.boss_subtitle = "Boss Cuối Màn 5 • Huyết Nguyệt Ma Đế — Hủy Diệt Cửu Thiên!"
			s.archetype = "boss"
			s.max_hp = 660.0
			s.move_speed = 3.5
			s.attack_damage = 29.0
			s.attack_range = 4.2
			s.attack_cooldown = 1.38
			s.knockback_resistance = 0.90
			s.shield_points = 6
			s.score_value = 1500
			s.gold_drop = 110
			s.aura_color = Color(1.0, 0.18, 0.24)
			s.projectile_color = Color(1.0, 0.24, 0.26)
			s.sprite_scale = 1.56
	return s


static func _create_default_stage_data(stage_id: int) -> StageData:
	var st := StageData.new()
	st.stage_id = stage_id
	match stage_id:
		1:
			st.stage_name = "Màn 1: Rừng Thu Ngoại Ô Windferry"
			st.stage_subtitle = "3 Đợt + BOSS MÀN 1: HỒ LY YÊU VƯƠNG"
			st.map_theme = "autumn_forest"
			st.time_of_day = "golden_hour"
			st.target_clear_time = 95.0
			st.waves = [
				{"slime": 3, "bandit": 1},
				{"slime": 2, "bandit": 2, "wolf": 1},
				{"boss_kitsune": 1, "slime": 2},
			]
		2:
			st.stage_name = "Màn 2: Thung Lũng Cầu Đá Ánh Trăng"
			st.stage_subtitle = "3 Đợt + BOSS MÀN 2: LONG VƯƠNG THẦN"
			st.map_theme = "moonlit_bridge"
			st.time_of_day = "blue_night"
			st.target_clear_time = 110.0
			st.waves = [
				{"slime": 2, "wolf": 2, "kitsune": 1},
				{"bandit": 2, "ghost": 2, "wolf": 1},
				{"boss_dragon": 1, "slime": 2},
			]
		3:
			st.stage_name = "Màn 3: Khu Chợ Đêm Trong Cơn Mưa"
			st.stage_subtitle = "4 Đợt + BOSS MÀN 3: MA VƯƠNG HẮC ÁM"
			st.map_theme = "rainy_market"
			st.time_of_day = "rainy_night"
			st.target_clear_time = 125.0
			st.waves = [
				{"bandit": 3, "ghost": 2},
				{"wolf": 2, "kitsune": 2, "bandit": 1},
				{"warrior": 1, "ghost": 2, "bandit": 2},
				{"boss_darklord": 1, "ghost": 2},
			]
		4:
			st.stage_name = "Màn 4: Cổ Thành Đêm Sâu"
			st.stage_subtitle = "4 Đợt + BOSS MÀN 4: PHÁP SƯ VĨNH HẰNG"
			st.map_theme = "ancient_fortress"
			st.time_of_day = "midnight"
			st.target_clear_time = 140.0
			st.waves = [
				{"warrior": 1, "bandit": 3, "kitsune": 1},
				{"golem": 1, "ghost": 2, "wolf": 2},
				{"warrior": 2, "golem": 1, "kitsune": 2},
				{"boss_archmage": 1, "warrior": 1},
			]
		5:
			st.stage_name = "Màn 5: Tế Đàn Nguyệt Thực Cửu Thiên"
			st.stage_subtitle = "4 Đợt + BOSS CUỐI: THIÊN MA CUỒNG ĐẾ"
			st.map_theme = "eclipse_citadel"
			st.time_of_day = "crimson_eclipse"
			st.target_clear_time = 165.0
			st.waves = [
				{"wolf": 3, "ghost": 2, "kitsune": 2},
				{"warrior": 2, "golem": 1, "bandit": 2},
				{"golem": 2, "warrior": 1, "ghost": 2, "kitsune": 1},
				{"boss_emperor": 1, "warrior": 1, "ghost": 1},
			]
	return st
