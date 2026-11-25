extends Node3D
## MainGameController: Kết nối StageManager (thế giới 3D HD-2D) và GameUIController (HUD & Menu).
## Mở đầu ở trạng thái cảnh làng Đêm Xanh (Blue Hour) phía sau Menu chính để người chơi thưởng thức đồ họa HD-2D ngay khi mở game.

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
	ui_controller.quick_lighting_requested.connect(_on_quick_lighting_requested)
	ui_controller.toggle_dof_requested.connect(_on_toggle_dof_requested)
	stage_manager.wave_banner_requested.connect(ui_controller.show_wave_banner)


func _on_start_stage_requested(stage_id: int) -> void:
	stage_manager.load_and_start_stage(stage_id)
	ui_controller.bind_player(stage_manager.player)


func _on_quick_lighting_requested(mode: String) -> void:
	if stage_manager and stage_manager.environment_builder:
		stage_manager.environment_builder.apply_time_of_day(mode)
		var mode_names := {
			"golden_hour": "HOÀNG HÔN (GOLDEN HOUR)",
			"blue_night": "ĐÊM XANH CHẠNG VẠNG (BLUE NIGHT)",
			"midnight": "MÀN ĐÊM SÂU (DEEP MIDNIGHT)",
			"rainy_night": "ĐÊM MƯA BÃO (RAINY NIGHT)",
			"crimson_eclipse": "ĐÊM NGUYỆT THỰC (CRIMSON ECLIPSE)",
		}
		ui_controller.show_wave_banner(
			"THỜI ĐIỂM: " + str(mode_names.get(mode, mode.to_upper())),
			"[1] Hoàng hôn | [2] Đêm xanh | [3] Màn Đêm Sâu | [R] Đêm mưa | [4] Nguyệt thực"
		)


func _on_toggle_dof_requested() -> void:
	if stage_manager and stage_manager.camera_rig:
		var enabled := stage_manager.camera_rig.toggle_dof()
		ui_controller.show_wave_banner("TILT-SHIFT DOF: " + ("BẬT" if enabled else "TẮT"), "Hiệu ứng làm mờ tiền cảnh & hậu cảnh kiểu Octopath Traveler")
