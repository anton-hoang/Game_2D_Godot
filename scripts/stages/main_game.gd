extends Node3D
## MainGameController: Kết nối StageManager (thế giới 3D HD-2D) và GameUIController (HUD Cổ Trang & Menu).
## Ánh sáng & Thiên tượng (Hoàng hôn, Đêm xanh, Màn đêm, Đêm mưa, Huyết nguyệt) tự động biến chuyển ngẫu nhiên mượt mà.

var stage_manager: StageManager
var ui_controller: GameUIController


func _ready() -> void:
	stage_manager = get_node_or_null("StageManager") as StageManager
	if stage_manager == null:
		stage_manager = StageManager.new()
		stage_manager.name = "StageManager"
		add_child(stage_manager)

	ui_controller = get_node_or_null("GameUI") as GameUIController
	if ui_controller == null:
		ui_controller = GameUIController.new()
		ui_controller.name = "GameUI"
		add_child(ui_controller)

	ui_controller.bind_player(stage_manager.player)
	ui_controller.start_stage_requested.connect(_on_start_stage_requested)
	ui_controller.enter_town_hub_requested.connect(_on_enter_town_hub_requested)
	ui_controller.npc_service_requested.connect(_on_npc_service_requested)
	ui_controller.toggle_dof_requested.connect(_on_toggle_dof_requested)
	ui_controller.relic_chosen.connect(_on_relic_chosen)

	stage_manager.wave_banner_requested.connect(ui_controller.show_wave_banner)
	stage_manager.npc_interacted.connect(ui_controller.show_npc_dialogue)
	stage_manager.bounty_board_opened.connect(ui_controller.show_quest_board)
	stage_manager.relic_selection_requested.connect(ui_controller.show_relic_selection)
	stage_manager.hub_portal_entered.connect(ui_controller.open_stage_select_from_hub)
	stage_manager.boss_appeared.connect(_on_boss_appeared_cinematic)

	# Lắng nghe sự kiện Thiên Tượng đổi ánh sáng ngẫu nhiên tự động
	if stage_manager.environment_builder:
		stage_manager.environment_builder.weather_lighting_changed.connect(_on_weather_lighting_changed)
		var cur_mode := stage_manager.environment_builder.current_time_of_day
		var cur_name := str(HD2DEnvironmentBuilder.WEATHER_NAMES.get(cur_mode, "Màn Đêm Tĩnh Mịch"))
		ui_controller.update_weather_display(cur_name)


func _on_weather_lighting_changed(_mode: String, display_name: String) -> void:
	ui_controller.update_weather_display(display_name)
	if not get_tree().paused:
		ui_controller.show_wave_banner("THIÊN TƯỢNG BIẾN CHUYỂN", "Trời đất chuyển sang: " + display_name)


func _on_enter_town_hub_requested() -> void:
	stage_manager.enter_town_hub()
	ui_controller.bind_player(stage_manager.player)


func _on_npc_service_requested(role: String) -> void:
	var p := stage_manager.player
	if p == null:
		return
	if role == "innkeeper":
		p.heal(p.max_hp)
		p.add_energy(p.max_energy)
		AudioManager.play_sfx("victory", 1.1)
		ui_controller.show_wave_banner("NGHỈ NGƠI TẠI QUÁN TRỌ MIRA", "Sinh lực và Chân khí đã hồi phục viên mãn!")
	elif role == "merchant":
		if SaveManager.gold >= 20:
			SaveManager.add_gold(-20)
			p.heal(p.max_hp)
			p.add_energy(p.max_energy)
			GameManager.add_score(150)
			AudioManager.play_sfx("pickup", 1.15)
			ui_controller.show_wave_banner("ĐÃ MUA ĐAN DƯỢC TĂNG LỰC", "Hồi đầy Sinh Lực / Chân Khí & nhận +150 Chiến Công")
		else:
			AudioManager.play_sfx("hurt", 0.9)
			ui_controller.show_wave_banner("NGÂN LƯỢNG KHÔNG ĐỦ (CẦN 20 LƯỢNG)", "Hãy mở Rương báu trong 3 nhà gỗ hoặc chém vỡ thùng gỗ để tìm thêm!")


func _on_boss_appeared_cinematic(boss_node: EnemyBase) -> void:
	if boss_node == null or not is_instance_valid(boss_node):
		return
	# Làm chậm nhẹ chiến trường trong lúc camera lia điện ảnh vào Boss
	Engine.time_scale = 0.25
	ui_controller.play_boss_cinematic_overlay(
		boss_node.stats.enemy_name.to_upper(),
		"Ma Vương Hắc Ám • Tam Cảnh Chiến Thần — Huyết Nguyệt Giáng Lâm!",
		2.2
	)
	if stage_manager.camera_rig:
		await stage_manager.camera_rig.play_boss_intro(boss_node, 2.2)
	Engine.time_scale = 1.0


func _on_relic_chosen(relic_id: String) -> void:
	stage_manager.apply_relic_and_continue_wave(relic_id)
	if stage_manager.player:
		ui_controller.update_relics_hud(stage_manager.player.active_relics)


func _on_start_stage_requested(stage_id: int) -> void:
	stage_manager.load_and_start_stage(stage_id)
	ui_controller.bind_player(stage_manager.player)
	ui_controller.update_relics_hud({})


func _on_toggle_dof_requested() -> void:
	if stage_manager and stage_manager.camera_rig:
		var enabled := stage_manager.camera_rig.toggle_dof()
		ui_controller.show_wave_banner("HIỆU ỨNG CHIỀU SÂU DOF: " + ("MỞ" if enabled else "TẮT"), "Hiệu ứng làm mờ cảnh xa gần HD-2D")
