class_name StageManager
extends Node3D
## Quản lý luồng màn chơi:
## - Đọc StageData của màn hiện tại, áp dụng thời điểm ánh sáng (Hoàng hôn / Đêm xanh / Mưa / Nguyệt thực).
## - Sinh quái theo từng đợt (Wave Spawner).
## - Khi diệt hết quái trong đợt -> Mở cổng ánh sáng (WavePortal3D) sang đợt tiếp theo.
## - Khi diệt hết đợt cuối (hoặc Boss) -> Mở bảng tổng kết Điểm / Thời gian / Xếp hạng S-A-B-C.

signal wave_banner_requested(title_text: String, subtitle_text: String)
signal boss_appeared(boss_node: EnemyBase)

var environment_builder: HD2DEnvironmentBuilder
var player: PlayerController
var camera_rig: CameraRig3D
var wave_portal: WavePortal3D
var entities_root: Node3D

var current_stage_data: StageData
var current_wave_index: int = 0
var alive_enemies_count: int = 0

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
	player.position = Vector3(0.0, 0.2, 1.8)

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


## Tải và bắt đầu màn chơi theo stage_id (1 đến 5)
func load_and_start_stage(stage_id: int) -> void:
	_clear_entities()
	current_stage_data = StageDatabase.get_stage_data(stage_id)
	current_wave_index = 0
	alive_enemies_count = 0

	# Đặt lại vị trí và nâng cấp của Player
	player._is_dead = false
	player._apply_save_upgrades()
	player.global_position = Vector3(-1.5, 0.2, 1.8)
	player.hp_changed.emit(player.current_hp, player.max_hp)
	player.energy_changed.emit(player.current_energy, player.max_energy)

	# Áp dụng ánh sáng thời điểm của màn (Hoàng hôn / Đêm xanh / Mưa / Nguyệt thực)
	environment_builder.apply_time_of_day(current_stage_data.time_of_day)
	AudioManager.play_stage_ambience(current_stage_data.time_of_day)

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

	if alive_enemies_count == 0 and GameManager.is_stage_active:
		_on_wave_cleared()


func _spawn_loot_drops(pos: Vector3, enemy_stats: EnemyStats) -> void:
	# Luôn rơi vàng
	var gold_pickup := Pickup3D.new()
	gold_pickup.pickup_type = "gold"
	gold_pickup.amount = enemy_stats.gold_drop
	entities_root.add_child(gold_pickup)
	gold_pickup.global_position = pos + Vector3(randf_range(-0.4, 0.4), 0.2, randf_range(-0.4, 0.4))

	# Tỉ lệ rơi bình máu (35%) hoặc tinh thể năng lượng (40%)
	var roll := randf()
	if roll < 0.35:
		var hp_p := Pickup3D.new()
		hp_p.pickup_type = "hp"
		hp_p.amount = 28
		entities_root.add_child(hp_p)
		hp_p.global_position = pos + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6))
	elif roll < 0.75:
		var mp_p := Pickup3D.new()
		mp_p.pickup_type = "energy"
		mp_p.amount = 35
		entities_root.add_child(mp_p)
		mp_p.global_position = pos + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6))


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
	_spawn_current_wave()


func _clear_entities() -> void:
	if entities_root == null:
		return
	for child in entities_root.get_children():
		child.queue_free()
