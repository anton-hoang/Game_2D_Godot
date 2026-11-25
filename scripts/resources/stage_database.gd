class_name StageDatabase
extends RefCounted
## Cơ sở dữ liệu 5 màn chơi tăng dần độ khó và 5 loại quái vật (Cận chiến, Tầm xa, Lao tới, Tank, Boss).
## Tự động đọc từ file .tres trong res://resources/stage_data/ và res://resources/enemy_stats/ nếu tồn tại,
## hoặc khởi tạo trực tiếp để đảm bảo luôn chạy mượt ngay lập tức.


static func get_enemy_stats(archetype: String, stage_level: int = 1) -> EnemyStats:
	var path := "res://resources/enemy_stats/" + archetype + ".tres"
	var base_stats: EnemyStats
	if ResourceLoader.exists(path):
		base_stats = (load(path) as EnemyStats).duplicate()
	else:
		base_stats = _create_default_enemy_stats(archetype)

	# Tăng nhẹ chỉ số theo cấp độ màn chơi (Scaling)
	var scale_mult := 1.0 + float(stage_level - 1) * 0.14
	base_stats.max_hp = round(base_stats.max_hp * scale_mult)
	base_stats.attack_damage = round(base_stats.attack_damage * (1.0 + float(stage_level - 1) * 0.10))
	return base_stats


static func get_stage_data(stage_id: int) -> StageData:
	var clamped_id := clampi(stage_id, 1, 5)
	var path := "res://resources/stage_data/stage_" + str(clamped_id) + ".tres"
	if ResourceLoader.exists(path):
		return load(path) as StageData
	return _create_default_stage_data(clamped_id)


static func _create_default_enemy_stats(archetype: String) -> EnemyStats:
	var s := EnemyStats.new()
	s.archetype = archetype
	match archetype:
		"melee":
			s.enemy_name = "Goblin Trinh Sát"
			s.max_hp = 55.0
			s.move_speed = 3.5
			s.attack_damage = 12.0
			s.attack_range = 1.65
			s.attack_cooldown = 1.25
			s.knockback_resistance = 0.0
			s.score_value = 100
			s.gold_drop = 8
			s.sprite_scale = 1.0
		"ranged":
			s.enemy_name = "Phù Thủy Bóng Đêm"
			s.max_hp = 45.0
			s.move_speed = 2.8
			s.attack_damage = 15.0
			s.attack_range = 8.5
			s.attack_cooldown = 1.85
			s.knockback_resistance = 0.0
			s.score_value = 135
			s.gold_drop = 11
			s.sprite_scale = 1.0
		"charger":
			s.enemy_name = "Chiến Thú Cuồng Nộ"
			s.max_hp = 68.0
			s.move_speed = 3.8
			s.attack_damage = 18.0
			s.attack_range = 4.6
			s.attack_cooldown = 1.95
			s.knockback_resistance = 0.25
			s.score_value = 160
			s.gold_drop = 13
			s.sprite_scale = 1.08
		"tank":
			s.enemy_name = "Hộ Vệ Giáp Sắt"
			s.max_hp = 135.0
			s.move_speed = 2.15
			s.attack_damage = 22.0
			s.attack_range = 2.1
			s.attack_cooldown = 1.9
			s.knockback_resistance = 0.72
			s.score_value = 220
			s.gold_drop = 18
			s.sprite_scale = 1.25
		"boss":
			s.enemy_name = "Chúa Tể Hắc Ám Malakor"
			s.max_hp = 520.0
			s.move_speed = 3.1
			s.attack_damage = 24.0
			s.attack_range = 3.4
			s.attack_cooldown = 1.55
			s.knockback_resistance = 0.88
			s.score_value = 1000
			s.gold_drop = 65
			s.sprite_scale = 1.45
	return s


static func _create_default_stage_data(stage_id: int) -> StageData:
	var st := StageData.new()
	st.stage_id = stage_id
	match stage_id:
		1:
			st.stage_name = "Màn 1: Hoàng Hôn Làng Windferry"
			st.stage_subtitle = "3 Đợt quái — Làm quen di chuyển, combo và né đòn"
			st.time_of_day = "golden_hour"
			st.target_clear_time = 75.0
			st.waves = [
				{"melee": 3},
				{"melee": 3, "ranged": 1},
				{"melee": 4, "ranged": 2},
			]
		2:
			st.stage_name = "Màn 2: Đêm Xanh Bên Cầu Đá"
			st.stage_subtitle = "3 Đợt quái — Chiến thú lao nhanh xuất hiện"
			st.time_of_day = "blue_night"
			st.target_clear_time = 85.0
			st.waves = [
				{"melee": 3, "ranged": 2},
				{"melee": 2, "charger": 2},
				{"melee": 3, "ranged": 2, "charger": 2},
			]
		3:
			st.stage_name = "Màn 3: Cơn Mưa Đêm Thị Trấn"
			st.stage_subtitle = "4 Đợt quái — Hộ vệ giáp sắt (Tank) cản đường"
			st.time_of_day = "rainy_night"
			st.target_clear_time = 105.0
			st.waves = [
				{"melee": 4, "ranged": 2},
				{"charger": 3, "ranged": 2},
				{"tank": 1, "melee": 3},
				{"tank": 1, "ranged": 2, "charger": 2},
			]
		4:
			st.stage_name = "Màn 4: Màn Đêm Sâu Thành Cổ"
			st.stage_subtitle = "4 Đợt quái — Đêm tối tĩnh mịch dưới ánh trăng & đèn lồng"
			st.time_of_day = "midnight"
			st.target_clear_time = 120.0
			st.waves = [
				{"melee": 4, "charger": 2},
				{"tank": 1, "ranged": 3},
				{"tank": 2, "melee": 3},
				{"tank": 2, "ranged": 2, "charger": 2},
			]
		5:
			st.stage_name = "Màn 5: Nguyệt Thực & Chúa Tể Malakor"
			st.stage_subtitle = "4 Đợt quái + BOSS CUỐI CHƯƠNG (3 Pha chiến đấu)"
			st.time_of_day = "crimson_eclipse"
			st.target_clear_time = 150.0
			st.waves = [
				{"melee": 4, "ranged": 2},
				{"charger": 3, "tank": 1},
				{"tank": 2, "ranged": 3},
				{"boss": 1, "melee": 2},
			]
	return st
