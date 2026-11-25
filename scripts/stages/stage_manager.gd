class_name StageManager
extends Node3D
## Quản lý luồng màn chơi:
## - Đọc StageData của màn hiện tại, áp dụng thời điểm ánh sáng (Hoàng hôn / Đêm xanh / Mưa / Nguyệt thực).
## - Sinh quái theo từng đợt (Wave Spawner).
## - Khi diệt hết quái trong đợt -> Mở cổng ánh sáng (WavePortal3D) sang đợt tiếp theo.
## - Khi diệt hết đợt cuối (hoặc Boss) -> Mở bảng tổng kết Điểm / Thời gian / Xếp hạng S-A-B-C.

signal wave_banner_requested(title_text: String, subtitle_text: String)
signal boss_appeared(boss_node: EnemyBase)
signal npc_interacted(npc_data: Dictionary)
signal bounty_board_opened
signal relic_selection_requested
signal hub_portal_entered

var environment_builder: HD2DEnvironmentBuilder
var player: PlayerController
var companion_pet: SpiritCompanion3D
var camera_rig: CameraRig3D
var wave_portal: WavePortal3D
var entities_root: Node3D
var town_npcs_root: Node3D

var current_stage_data: StageData
var current_wave_index: int = 0
var alive_enemies_count: int = 0
var is_in_town_hub: bool = false

const SPAWN_POINTS: Array[Vector3] = [
	Vector3(-14.5, 0.2, 1.5),
	Vector3(14.5, 0.2, 1.5),
	Vector3(-11.0, 0.2, -4.5),
	Vector3(11.5, 0.2, -4.5),
	Vector3(-9.5, 0.2, 5.5),
	Vector3(10.0, 0.2, 5.5),
	Vector3(0.0, 0.2, -5.2),
]


func _ready() -> void:
	_setup_scene_hierarchy()


func _setup_scene_hierarchy() -> void:
	environment_builder = get_node_or_null("HD2DEnvironment") as HD2DEnvironmentBuilder
	if environment_builder == null:
		environment_builder = HD2DEnvironmentBuilder.new()
		environment_builder.name = "HD2DEnvironment"
		add_child(environment_builder)

	entities_root = get_node_or_null("Entities") as Node3D
	if entities_root == null:
		entities_root = Node3D.new()
		entities_root.name = "Entities"
		add_child(entities_root)

	player = get_node_or_null("Player") as PlayerController
	if player == null:
		var player_scene := load("res://scenes/player/player.tscn") as PackedScene
		if player_scene:
			player = player_scene.instantiate() as PlayerController
		else:
			player = PlayerController.new()
		player.name = "Player"
		add_child(player)
	player.position = Vector3(1.5, 0.2, 2.2)

	# Bạn Đồng Hành Linh Thú (Tiểu Hồ Ly / Tiên Hạc) bay lượn bên vai cô bé Lữ Khách!
	companion_pet = get_node_or_null("SpiritCompanion3D") as SpiritCompanion3D
	if companion_pet == null:
		companion_pet = SpiritCompanion3D.new()
		companion_pet.name = "SpiritCompanion3D"
		add_child(companion_pet)
	companion_pet.owner_player = player
	companion_pet.position = player.position + Vector3(-1.2, 1.6, -0.4)

	camera_rig = get_node_or_null("CameraRig3D") as CameraRig3D
	if camera_rig == null:
		camera_rig = CameraRig3D.new()
		camera_rig.name = "CameraRig3D"
		add_child(camera_rig)
	camera_rig.target = player
	player.camera_rig = camera_rig

	wave_portal = get_node_or_null("WavePortal3D") as WavePortal3D
	if wave_portal == null:
		wave_portal = WavePortal3D.new()
		wave_portal.name = "WavePortal3D"
		add_child(wave_portal)
	wave_portal.position = Vector3(7.5, 0.05, 1.5)
	wave_portal.portal_entered.connect(_on_portal_entered)

	_build_town_npcs()


## Tạo 3 NPC đứng quanh Làng Windferry trong chế độ Làng trung tâm (Town Hub)
func _build_town_npcs() -> void:
	town_npcs_root = Node3D.new()
	town_npcs_root.name = "TownNPCs"
	add_child(town_npcs_root)

	var npc_configs := [
		{
			"role": "blacksmith",
			"name": "Thợ Rèn Gorn",
			"title": "Lò Rèn Cổ Windferry",
			"text": "Hôm nay quái vật kéo về đông lắm! Mang vàng lại đây, ta sẽ cường hóa vũ khí, giáp trụ và giày gió cho ngươi trước khi xuất trận.",
			"action_label": "Mở Lò Rèn Nâng Cấp",
			"pos": Vector3(-3.0, 0.1, -3.6),
		},
		{
			"role": "innkeeper",
			"name": "Chủ Quán Trọ Mira",
			"title": "Quán Trọ Ấm Áp Windferry",
			"text": "Đêm xuống rồi, hãy nghỉ ngơi bên lò sưởi một lát nhé lữ khách! Ta có thể hồi phục toàn bộ Sinh lực & Năng lượng cho ngươi miễn phí.",
			"action_label": "Nghỉ Ngơi (Hồi 100% HP & MP)",
			"pos": Vector3(2.2, 2.7, -9.8),
		},
		{
			"role": "merchant",
			"name": "Thương Nhân Aurelius",
			"title": "Binh Khí Phổ & Dược Điếm",
			"text": "Ta mang về đủ loại Thần Binh Cổ Trang (Kiếm, Đại Đao, Cung Tên, Gậy Phép) cùng Đan Dược thượng hạng! Mời lữ khách ghé xem hàng.",
			"action_label": "Mở Cửa Hàng Vũ Khí & Đan Dược",
			"pos": Vector3(-11.5, 0.1, -0.5),
		},
	]
	for cfg in npc_configs:
		var npc := VillageNPC3D.new()
		npc.npc_role = str(cfg["role"])
		npc.npc_name = str(cfg["name"])
		npc.npc_title = str(cfg["title"])
		npc.dialogue_text = str(cfg["text"])
		npc.action_label = str(cfg["action_label"])
		npc.position = cfg["pos"]
		npc.interacted.connect(func(d: Dictionary) -> void: npc_interacted.emit(d))
		town_npcs_root.add_child(npc)

	# Bảng Truy Nã (Bounty Board) đặt ngay quảng trường giữa Làng Windferry
	var board := BountyBoard3D.new()
	board.name = "VillageBountyBoard"
	board.position = Vector3(2.8, 0.0, -5.2)
	board.board_interacted.connect(func() -> void: bounty_board_opened.emit())
	town_npcs_root.add_child(board)


## Vào chế độ Làng Trung Tâm yên bình (Town Hub):
## Người chơi tự do đi dạo, nói chuyện 3 NPC, leo bậc thang vào 3 ngôi nhà mở rương báu, chém thùng gỗ,
## rồi bước vào Cổng Chiến Đấu bên phải để chọn màn đánh quái!
func enter_town_hub() -> void:
	_clear_entities()
	is_in_town_hub = true
	GameManager.is_stage_active = false
	if town_npcs_root:
		town_npcs_root.visible = true
		town_npcs_root.process_mode = Node.PROCESS_MODE_INHERIT

	player._is_dead = false
	player._apply_save_upgrades()
	player.global_position = Vector3(1.5, 0.2, 2.2)
	if companion_pet and is_instance_valid(companion_pet):
		companion_pet.global_position = player.global_position + Vector3(-1.2, 1.6, -0.4)
	player.hp_changed.emit(player.current_hp, player.max_hp)
	player.energy_changed.emit(player.current_energy, player.max_energy)

	environment_builder.build_map_for_theme("hamlet_hub")
	var chosen_hub_weather := environment_builder.apply_random_time_of_day(true)
	AudioManager.play_stage_ambience(chosen_hub_weather)

	wave_portal.set_portal_active(true, SaveManager.unlocked_stage, false)
	wave_portal._label_3d.text = "CỔNG CHIẾN ĐẤU (MÀN " + str(SaveManager.unlocked_stage) + ")\n(Bước vào để chọn màn đánh quái)"
	wave_portal._label_3d.modulate = Color(1.0, 0.86, 0.35)
	wave_banner_requested.emit(
		"LÀNG CỔ WINDFERRY (KHU VỰC YÊN BÌNH)",
		"Nói chuyện NPC bằng [E] • Leo cầu thang bên phải vào 3 nhà mở Rương • Vào Cổng Ánh Sáng để đánh quái"
	)


## Tải và bắt đầu màn chơi theo stage_id (1 đến 5)
func load_and_start_stage(stage_id: int) -> void:
	_clear_entities()
	is_in_town_hub = false
	if town_npcs_root:
		town_npcs_root.visible = false
		town_npcs_root.process_mode = Node.PROCESS_MODE_DISABLED

	current_stage_data = StageDatabase.get_stage_data(stage_id)
	current_wave_index = 0
	alive_enemies_count = 0

	# Đặt lại vị trí, nâng cấp và xóa Bùa Cổ Ngữ của trận trước
	player._is_dead = false
	player._apply_save_upgrades()
	player.reset_stage_relics()
	player.global_position = Vector3(1.5, 0.2, 2.2)
	if companion_pet and is_instance_valid(companion_pet):
		companion_pet.global_position = player.global_position + Vector3(-1.2, 1.6, -0.4)
	player.hp_changed.emit(player.current_hp, player.max_hp)
	player.energy_changed.emit(player.current_energy, player.max_energy)

	# Dựng kiến trúc Map riêng của từng màn chơi + Chọn ngẫu nhiên thời điểm ánh sáng tự động!
	environment_builder.build_map_for_theme(current_stage_data.map_theme)
	var chosen_weather := environment_builder.apply_random_time_of_day(true)
	AudioManager.play_stage_ambience(chosen_weather)

	wave_portal.set_portal_active(false)
	GameManager.start_stage(stage_id, current_stage_data.waves.size())

	wave_banner_requested.emit(current_stage_data.stage_name, current_stage_data.stage_subtitle)
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(self) and GameManager.is_stage_active:
		_spawn_current_wave()


func _spawn_current_wave() -> void:
	if current_stage_data == null or current_wave_index >= current_stage_data.waves.size():
		return

	var wave_dict: Dictionary = current_stage_data.waves[current_wave_index]
	var wave_num := current_wave_index + 1
	var total_w := current_stage_data.waves.size()
	GameManager.set_wave(wave_num, total_w)

	var is_boss_wave := wave_dict.has("boss")
	if is_boss_wave:
		wave_banner_requested.emit("ĐỢT CUỐI: BOSS XUẤT HIỆN!", "Chúa Tể Hắc Ám Malakor đã giáng lâm")
		AudioManager.play_sfx("boss_roar")
	else:
		wave_banner_requested.emit("ĐỢT QUÁI " + str(wave_num) + " / " + str(total_w), "Tiêu diệt toàn bộ kẻ địch để mở cổng!")

	var spawn_idx := 0
	alive_enemies_count = 0

	for archetype in wave_dict.keys():
		var count := int(wave_dict[archetype])
		for i in range(count):
			var enemy := _instantiate_enemy(str(archetype), current_stage_data.stage_id)
			var base_pos := SPAWN_POINTS[spawn_idx % SPAWN_POINTS.size()]
			if str(archetype) == "boss":
				base_pos = Vector3(8.0, 0.3, 1.2)
			else:
				base_pos += Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-0.9, 0.9))
			enemy.position = base_pos
			entities_root.add_child(enemy)
			enemy.died.connect(_on_enemy_died)
			alive_enemies_count += 1
			spawn_idx += 1

			if str(archetype) == "boss":
				boss_appeared.emit(enemy)
				GameManager.boss_spawned.emit(enemy)


func _instantiate_enemy(archetype: String, stage_level: int) -> EnemyBase:
	var enemy: EnemyBase
	var scene_path := "res://scenes/enemies/enemy_base.tscn"
	if ResourceLoader.exists(scene_path):
		var sc := load(scene_path) as PackedScene
		enemy = sc.instantiate() as EnemyBase
	else:
		enemy = EnemyBase.new()
	enemy.stats = StageDatabase.get_enemy_stats(archetype, stage_level)
	return enemy


func _on_enemy_died(enemy: EnemyBase) -> void:
	alive_enemies_count = maxi(0, alive_enemies_count - 1)
	_spawn_loot_drops(enemy.global_position, enemy.stats)

	# Kích hoạt Hấp Tinh Đại Pháp (nếu đã chọn) & tính tiến độ nhiệm vụ Diệt Goblin vô thương
	if player and is_instance_valid(player):
		player.on_enemy_killed()
	if enemy.stats and enemy.stats.archetype == "melee":
		SaveManager.advance_quest("goblin_slayer", 1)

	if alive_enemies_count == 0 and GameManager.is_stage_active:
		_on_wave_cleared()


func _spawn_loot_drops(pos: Vector3, enemy_stats: EnemyStats) -> void:
	# Luôn rơi vàng
	var gold_pickup := Pickup3D.new()
	gold_pickup.pickup_type = "gold"
	gold_pickup.amount = enemy_stats.gold_drop
	entities_root.add_child(gold_pickup)
	gold_pickup.global_position = pos + Vector3(randf_range(-0.4, 0.4), 0.2, randf_range(-0.4, 0.4))

	# Tỉ lệ rơi bình máu (30%), năng lượng (30%), Đan Dược bỏ vào Rương Đồ (20%) & RƠI VŨ KHÍ NGẪU NHIÊN (22% quái thường, 100% Boss!)
	var roll := randf()
	if roll < 0.30:
		var hp_p := Pickup3D.new()
		hp_p.pickup_type = "hp"
		hp_p.amount = 28
		entities_root.add_child(hp_p)
		hp_p.global_position = pos + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6))
	elif roll < 0.60:
		var mp_p := Pickup3D.new()
		mp_p.pickup_type = "energy"
		mp_p.amount = 35
		entities_root.add_child(mp_p)
		mp_p.global_position = pos + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6))
	elif roll < 0.82:
		var bag_p := Pickup3D.new()
		bag_p.pickup_type = "bag_item"
		var pot_pool: Array[String] = ["hp_potion", "mp_potion", "elixir_power"]
		bag_p.item_id = pot_pool[randi() % 2] if randf() < 0.82 else pot_pool[2]
		entities_root.add_child(bag_p)
		bag_p.global_position = pos + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6))

	var is_boss_enemy: bool = (enemy_stats.archetype == "boss")
	var weapon_drop_chance: float = 1.0 if is_boss_enemy else (0.35 if enemy_stats.archetype == "tank" else 0.22)
	if randf() < weapon_drop_chance:
		var wp := Pickup3D.new()
		wp.pickup_type = "weapon"
		var stage_lv: int = current_stage_data.stage_id if current_stage_data else 1
		wp.item_id = SaveManager.pick_random_weapon_drop(stage_lv, is_boss_enemy)
		entities_root.add_child(wp)
		wp.global_position = pos + Vector3(randf_range(-0.7, 0.7), 0.35, randf_range(-0.7, 0.7))


func _on_wave_cleared() -> void:
	current_wave_index += 1
	if current_wave_index >= current_stage_data.waves.size():
		# Đã hoàn thành toàn bộ các đợt của màn chơi
		wave_banner_requested.emit("CHIẾN THẮNG MÀN CHƠI!", "Đang tổng kết chiến tích...")
		await get_tree().create_timer(1.1).timeout
		if is_instance_valid(self):
			GameManager.complete_current_stage(current_stage_data.target_clear_time)
	else:
		# Mở cổng sang đợt tiếp theo
		var next_wave_dict: Dictionary = current_stage_data.waves[current_wave_index]
		var next_is_boss := next_wave_dict.has("boss")
		wave_portal.set_portal_active(true, current_wave_index + 1, next_is_boss)
		wave_banner_requested.emit("ĐÃ DỌN SẠCH ĐỢT " + str(current_wave_index) + "!", "Bước vào Cổng Ánh Sáng bên phải để sang đợt kế tiếp")


func _on_portal_entered() -> void:
	if is_in_town_hub:
		hub_portal_entered.emit()
	else:
		# Sau mỗi Wave bước qua Cổng Ánh Sáng -> Hiện 3 Thẻ Bùa Cổ Ngữ Roguelite để người chơi chọn!
		relic_selection_requested.emit()


## Tiếp tục sinh đợt quái kế tiếp ngay sau khi người chơi chọn xong 1 trong 3 Bùa Cổ Ngữ
func apply_relic_and_continue_wave(relic_id: String) -> void:
	if player and is_instance_valid(player):
		player.add_relic(relic_id)
	_spawn_current_wave()


func _clear_entities() -> void:
	if entities_root == null:
		return
	for child in entities_root.get_children():
		child.queue_free()
