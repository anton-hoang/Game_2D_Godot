class_name GameUIController
extends CanvasLayer
## Quản lý toàn bộ giao diện người dùng (UI) của game:
## - Lớp Vignette hậu kỳ HD-2D.
## - HUD: Thanh máu (HP), Thanh năng lượng (MP/Energy), Số Wave, Vàng, Điểm, Thời gian, Thanh máu lớn của Boss.
## - Phím tắt thử nhanh ánh sáng HD-2D giống ảnh mẫu (1: Hoàng hôn, 2: Đêm xanh, R: Đêm mưa, G: Tilt-Shift DOF).
## - Menu chính, Chọn màn (1-5), Cửa hàng Nâng cấp (Sát thương, Máu, Tốc độ), Tạm dừng, Màn hình Thắng (Hạng S/A/B/C) & Thua.

signal start_stage_requested(stage_id: int)
signal quick_lighting_requested(mode: String)
signal toggle_dof_requested

var hud_root: Control
var hp_bar: ProgressBar
var hp_label: Label
var energy_bar: ProgressBar
var energy_label: Label
var wave_label: Label
var gold_label: Label
var score_label: Label
var time_label: Label
var banner_box: PanelContainer
var banner_title: Label
var banner_sub: Label

var boss_box: VBoxContainer
var boss_name_label: Label
var boss_hp_bar: ProgressBar

var main_menu_panel: Control
var stage_select_panel: Control
var upgrade_panel: Control
var pause_panel: Control
var result_panel: Control
var gameover_panel: Control

var _stage_buttons_box: VBoxContainer
var _upgrade_info_label: Label
var _result_title_label: Label
var _result_details_label: Label
var _result_rank_label: Label
var _next_stage_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_vignette_overlay()
	_build_hud()
	_build_main_menu()
	_build_stage_select_menu()
	_build_upgrade_menu()
	_build_pause_menu()
	_build_result_menu()
	_build_gameover_menu()

	GameManager.stats_updated.connect(_on_stats_updated)
	GameManager.stage_cleared.connect(_on_stage_cleared)
	GameManager.player_died.connect(_on_player_died)
	GameManager.boss_spawned.connect(_on_boss_spawned)
	SaveManager.data_changed.connect(_refresh_all_menus)

	show_main_menu()


func _process(_delta: float) -> void:
	if GameManager.is_stage_active and time_label:
		var t := GameManager.stage_elapsed_time
		var mins := int(t) / 60
		var secs := int(t) % 60
		time_label.text = "THỜI GIAN: %02d:%02d" % [mins, secs]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.is_stage_active:
			_toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.keycode == KEY_1:
			quick_lighting_requested.emit("golden_hour")
		elif kev.keycode == KEY_2:
			quick_lighting_requested.emit("blue_night")
		elif kev.keycode == KEY_3:
			quick_lighting_requested.emit("midnight")
		elif kev.keycode == KEY_R:
			quick_lighting_requested.emit("rainy_night")
		elif kev.keycode == KEY_4:
			quick_lighting_requested.emit("crimson_eclipse")
		elif kev.keycode == KEY_G:
			toggle_dof_requested.emit()
		elif kev.keycode == KEY_H and hud_root:
			hud_root.visible = not hud_root.visible


## Liên kết tín hiệu từ Player vào HUD
func bind_player(player: PlayerController) -> void:
	if player == null:
		return
	if not player.hp_changed.is_connected(_on_player_hp_changed):
		player.hp_changed.connect(_on_player_hp_changed)
	if not player.energy_changed.is_connected(_on_player_energy_changed):
		player.energy_changed.connect(_on_player_energy_changed)
	_on_player_hp_changed(player.current_hp, player.max_hp)
	_on_player_energy_changed(player.current_energy, player.max_energy)


func show_wave_banner(title: String, subtitle: String) -> void:
	if banner_box == null:
		return
	banner_title.text = title
	banner_sub.text = subtitle
	banner_box.visible = true
	banner_box.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(banner_box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: banner_box.visible = false)


func show_main_menu() -> void:
	get_tree().paused = true
	GameManager.is_stage_active = false
	_hide_all_panels()
	main_menu_panel.visible = true
	_refresh_all_menus()


func _hide_all_panels() -> void:
	for p in [main_menu_panel, stage_select_panel, upgrade_panel, pause_panel, result_panel, gameover_panel]:
		if p:
			p.visible = false


func _build_vignette_overlay() -> void:
	var vig := ColorRect.new()
	vig.name = "VignetteOverlay"
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := load("res://assets/shaders/vignette.gdshader") as Shader
	if shader:
		var smat := ShaderMaterial.new()
		smat.shader = shader
		vig.material = smat
	add_child(vig)


func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.name = "HUD"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)

	# Góc trên trái: Thanh máu, Năng lượng & Hướng dẫn phím tắt HD-2D
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(20, 16)
	top_left.custom_minimum_size = Vector2(310, 120)
	top_left.add_theme_constant_override("separation", 6)
	hud_root.add_child(top_left)

	var header_lbl := Label.new()
	header_lbl.text = "WINDFERRY HAMLET • HD-2D ACTION RPG"
	header_lbl.add_theme_font_size_override("font_size", 13)
	header_lbl.modulate = Color(0.95, 0.84, 0.55)
	top_left.add_child(header_lbl)

	hp_bar = _create_bar(Color(0.88, 0.22, 0.26), 22)
	top_left.add_child(hp_bar)
	hp_label = _create_overlay_label(hp_bar, "HP: 120 / 120")

	energy_bar = _create_bar(Color(0.20, 0.65, 0.95), 18)
	top_left.add_child(energy_bar)
	energy_label = _create_overlay_label(energy_bar, "MP (Kỹ năng K): 100 / 100")

	var controls_hint := Label.new()
	controls_hint.text = "WASD: Di chuyển | J: Combo 3 đòn | K: Tuyệt kỹ | L: Né (Dash) | ESC: Tạm dừng\nÁnh sáng HD-2D: [1] Hoàng hôn  [2] Đêm xanh  [3] Màn Đêm Sâu  [R] Đêm mưa  [4] Nguyệt thực  [G] DOF"
	controls_hint.add_theme_font_size_override("font_size", 12)
	controls_hint.modulate = Color(0.82, 0.88, 0.96, 0.85)
	top_left.add_child(controls_hint)

	# Góc trên phải: Số Wave, Vàng, Điểm, Thời gian
	var top_right_panel := _create_styled_panel()
	top_right_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right_panel.position = Vector2(-265, 16)
	top_right_panel.custom_minimum_size = Vector2(245, 112)
	hud_root.add_child(top_right_panel)

	var tr_vbox := VBoxContainer.new()
	tr_vbox.add_theme_constant_override("separation", 4)
	top_right_panel.add_child(tr_vbox)

	wave_label = Label.new()
	wave_label.text = "ĐỢT QUÁI: 1 / 3"
	wave_label.add_theme_font_size_override("font_size", 16)
	wave_label.modulate = Color(1.0, 0.85, 0.38)
	tr_vbox.add_child(wave_label)

	gold_label = Label.new()
	gold_label.text = "VÀNG: 0"
	gold_label.add_theme_font_size_override("font_size", 15)
	gold_label.modulate = Color(1.0, 0.92, 0.45)
	tr_vbox.add_child(gold_label)

	score_label = Label.new()
	score_label.text = "ĐIỂM: 0"
	score_label.add_theme_font_size_override("font_size", 15)
	tr_vbox.add_child(score_label)

	time_label = Label.new()
	time_label.text = "THỜI GIAN: 00:00"
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.modulate = Color(0.75, 0.88, 1.0)
	tr_vbox.add_child(time_label)

	# Banner thông báo giữa màn hình khi qua đợt
	banner_box = _create_styled_panel()
	banner_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_box.position = Vector2(-240, 88)
	banner_box.custom_minimum_size = Vector2(480, 74)
	banner_box.visible = false
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(banner_box)

	var b_vbox := VBoxContainer.new()
	b_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_box.add_child(b_vbox)

	banner_title = Label.new()
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_title.add_theme_font_size_override("font_size", 22)
	banner_title.modulate = Color(1.0, 0.86, 0.38)
	b_vbox.add_child(banner_title)

	banner_sub = Label.new()
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub.add_theme_font_size_override("font_size", 14)
	b_vbox.add_child(banner_sub)

	# Thanh máu lớn của Boss ở cạnh dưới màn hình
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	boss_box.position = Vector2(-280, -78)
	boss_box.custom_minimum_size = Vector2(560, 56)
	boss_box.visible = false
	hud_root.add_child(boss_box)

	boss_name_label = Label.new()
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 18)
	boss_name_label.modulate = Color(1.0, 0.42, 0.48)
	boss_name_label.text = "CHÚA TỂ HẮC ÁM MALAKOR (PHA 1)"
	boss_box.add_child(boss_name_label)

	boss_hp_bar = _create_bar(Color(0.88, 0.14, 0.28), 24)
	boss_box.add_child(boss_hp_bar)


func _build_main_menu() -> void:
	main_menu_panel = _create_center_modal(520, 410)
	var vbox := _get_modal_vbox(main_menu_panel)

	var title := Label.new()
	title.text = "CHRONICLES OF WINDFERRY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.modulate = Color(1.0, 0.84, 0.38)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "2.5D HD-2D Action RPG (Octopath Traveler Style)\nChiến đấu qua 5 màn chơi • Mở cổng Wave • Đánh Boss 3 Pha"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.modulate = Color(0.82, 0.88, 0.96)
	vbox.add_child(sub)

	var play_btn := _create_button("BẮT ĐẦU NGAY (MÀN ĐÃ MỞ: 1)", func() -> void:
		_start_stage(SaveManager.unlocked_stage)
	)
	play_btn.name = "QuickPlayBtn"
	vbox.add_child(play_btn)

	vbox.add_child(_create_button("CHỌN MÀN CHƠI (5 MÀN)", func() -> void:
		_hide_all_panels()
		_refresh_all_menus()
		stage_select_panel.visible = true
	))

	vbox.add_child(_create_button("NÂNG CẤP NHÂN VẬT (DÙNG VÀNG)", func() -> void:
		_hide_all_panels()
		_refresh_all_menus()
		upgrade_panel.visible = true
	))

	vbox.add_child(_create_button("XÓA LƯU GAME (CHƠI LẠI TỪ ĐẦU)", func() -> void:
		SaveManager.reset_save()
		_refresh_all_menus()
	))


func _build_stage_select_menu() -> void:
	stage_select_panel = _create_center_modal(580, 450)
	var vbox := _get_modal_vbox(stage_select_panel)

	var title := Label.new()
	title.text = "CHỌN MÀN CHƠI (STAGE SELECT)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(1.0, 0.85, 0.38)
	vbox.add_child(title)

	_stage_buttons_box = VBoxContainer.new()
	_stage_buttons_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_stage_buttons_box)

	vbox.add_child(_create_button("QUAY LẠI MENU CHÍNH", func() -> void:
		show_main_menu()
	))


func _build_upgrade_menu() -> void:
	upgrade_panel = _create_center_modal(540, 420)
	var vbox := _get_modal_vbox(upgrade_panel)

	var title := Label.new()
	title.text = "LÒ RÈN & NÂNG CẤP LỮ KHÁCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(1.0, 0.85, 0.38)
	vbox.add_child(title)

	_upgrade_info_label = Label.new()
	_upgrade_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_info_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_upgrade_info_label)

	var btn_atk := _create_button("Nâng cấp Sát Thương (+4 DMG)", func() -> void:
		if SaveManager.buy_upgrade("attack"):
			AudioManager.play_sfx("pickup")
			_refresh_all_menus()
	)
	btn_atk.name = "BtnAtk"
	vbox.add_child(btn_atk)

	var btn_hp := _create_button("Nâng cấp Máu Tối Đa (+25 HP)", func() -> void:
		if SaveManager.buy_upgrade("max_hp"):
			AudioManager.play_sfx("pickup")
			_refresh_all_menus()
	)
	btn_hp.name = "BtnHp"
	vbox.add_child(btn_hp)

	var btn_spd := _create_button("Nâng cấp Tốc Độ Chạy (+0.45 SPD)", func() -> void:
		if SaveManager.buy_upgrade("speed"):
			AudioManager.play_sfx("pickup")
			_refresh_all_menus()
	)
	btn_spd.name = "BtnSpd"
	vbox.add_child(btn_spd)

	vbox.add_child(_create_button("QUAY LẠI", func() -> void:
		show_main_menu()
	))


func _build_pause_menu() -> void:
	pause_panel = _create_center_modal(420, 320)
	var vbox := _get_modal_vbox(pause_panel)

	var title := Label.new()
	title.text = "TẠM DỪNG (PAUSED)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(1.0, 0.85, 0.38)
	vbox.add_child(title)

	vbox.add_child(_create_button("TIẾP TỤC CHIẾN ĐẤU", func() -> void:
		_toggle_pause()
	))
	vbox.add_child(_create_button("CHƠI LẠI MÀN NÀY", func() -> void:
		_start_stage(GameManager.current_stage_id)
	))
	vbox.add_child(_create_button("VỀ MENU CHÍNH", func() -> void:
		show_main_menu()
	))


func _build_result_menu() -> void:
	result_panel = _create_center_modal(500, 400)
	var vbox := _get_modal_vbox(result_panel)

	_result_title_label = Label.new()
	_result_title_label.text = "HOÀN THÀNH MÀN CHƠI!"
	_result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title_label.add_theme_font_size_override("font_size", 25)
	_result_title_label.modulate = Color(1.0, 0.86, 0.35)
	vbox.add_child(_result_title_label)

	_result_rank_label = Label.new()
	_result_rank_label.text = "XẾP HẠNG: S"
	_result_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_rank_label.add_theme_font_size_override("font_size", 42)
	_result_rank_label.modulate = Color(1.0, 0.88, 0.25)
	vbox.add_child(_result_rank_label)

	_result_details_label = Label.new()
	_result_details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_details_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_result_details_label)

	_next_stage_btn = _create_button("SANG MÀN TIẾP THEO", func() -> void:
		var next_id := mini(GameManager.TOTAL_STAGES, GameManager.current_stage_id + 1)
		_start_stage(next_id)
	)
	vbox.add_child(_next_stage_btn)

	vbox.add_child(_create_button("NÂNG CẤP NHÂN VẬT", func() -> void:
		_hide_all_panels()
		_refresh_all_menus()
		upgrade_panel.visible = true
	))

	vbox.add_child(_create_button("VỀ MENU CHÍNH", func() -> void:
		show_main_menu()
	))


func _build_gameover_menu() -> void:
	gameover_panel = _create_center_modal(440, 300)
	var vbox := _get_modal_vbox(gameover_panel)

	var title := Label.new()
	title.text = "THẤT BẠI (DEFEATED)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.modulate = Color(1.0, 0.35, 0.38)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Bạn đã ngã xuống. Hãy nâng cấp trang bị bằng vàng hoặc thử lại!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	vbox.add_child(_create_button("THỬ LẠI MÀN NÀY", func() -> void:
		_start_stage(GameManager.current_stage_id)
	))
	vbox.add_child(_create_button("NÂNG CẤP NHÂN VẬT", func() -> void:
		_hide_all_panels()
		_refresh_all_menus()
		upgrade_panel.visible = true
	))
	vbox.add_child(_create_button("VỀ MENU CHÍNH", func() -> void:
		show_main_menu()
	))


func _start_stage(stage_id: int) -> void:
	_hide_all_panels()
	boss_box.visible = false
	get_tree().paused = false
	start_stage_requested.emit(stage_id)


func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_panel.visible = paused


func _refresh_all_menus() -> void:
	if gold_label:
		gold_label.text = "VÀNG: " + str(SaveManager.gold)

	var quick_btn := main_menu_panel.find_child("QuickPlayBtn", true, false) as Button
	if quick_btn:
		quick_btn.text = "CHƠI NGAY (MÀN MỚI NHẤT: MÀN " + str(SaveManager.unlocked_stage) + ")"

	if _stage_buttons_box:
		for c in _stage_buttons_box.get_children():
			c.queue_free()
		for s_id in range(1, GameManager.TOTAL_STAGES + 1):
			var st := StageDatabase.get_stage_data(s_id)
			var unlocked := s_id <= SaveManager.unlocked_stage
			var rec: Dictionary = SaveManager.stage_records.get(str(s_id), {})
			var rank_str := " [Hạng: " + str(rec["rank"]) + " | Điểm: " + str(rec["score"]) + "]" if rec.has("rank") else ""
			var btn_text := st.stage_name + rank_str if unlocked else (st.stage_name + " (Chưa mở khóa)")
			var btn := _create_button(btn_text, func() -> void:
				if unlocked:
					_start_stage(s_id)
			)
			btn.disabled = not unlocked
			_stage_buttons_box.add_child(btn)

	if _upgrade_info_label:
		var lv_atk: int = int(SaveManager.upgrades.get("attack", 0))
		var lv_hp: int = int(SaveManager.upgrades.get("max_hp", 0))
		var lv_spd: int = int(SaveManager.upgrades.get("speed", 0))
		_upgrade_info_label.text = (
			"VÀNG HIỆN CÓ: %d\n" % SaveManager.gold
			+ "Sát thương: Cấp %d (+%.0f) | Máu: Cấp %d (+%.0f) | Tốc độ: Cấp %d (+%.2f)"
			% [lv_atk, SaveManager.get_bonus_attack(), lv_hp, SaveManager.get_bonus_max_hp(), lv_spd, SaveManager.get_bonus_speed()]
		)
		var b_atk := upgrade_panel.find_child("BtnAtk", true, false) as Button
		var b_hp := upgrade_panel.find_child("BtnHp", true, false) as Button
		var b_spd := upgrade_panel.find_child("BtnSpd", true, false) as Button
		if b_atk:
			b_atk.text = "Cường Hóa Vũ Khí (+4 Sát thương) — Giá: %d Vàng" % SaveManager.get_upgrade_cost("attack")
		if b_hp:
			b_hp.text = "Giáp Hộ Thân (+25 Máu tối đa) — Giá: %d Vàng" % SaveManager.get_upgrade_cost("max_hp")
		if b_spd:
			b_spd.text = "Giày Gió (+0.45 Tốc độ chạy) — Giá: %d Vàng" % SaveManager.get_upgrade_cost("speed")


func _on_player_hp_changed(cur: float, mx: float) -> void:
	if hp_bar:
		hp_bar.max_value = mx
		hp_bar.value = cur
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(ceil(cur)), int(mx)]


func _on_player_energy_changed(cur: float, mx: float) -> void:
	if energy_bar:
		energy_bar.max_value = mx
		energy_bar.value = cur
	if energy_label:
		energy_label.text = "NĂNG LƯỢNG (K): %d / %d" % [int(cur), int(mx)]


func _on_stats_updated(score: int, gold: int, wave_idx: int, total_waves: int) -> void:
	if score_label:
		score_label.text = "ĐIỂM: " + str(score)
	if gold_label:
		gold_label.text = "VÀNG: " + str(gold)
	if wave_label:
		wave_label.text = "ĐỢT QUÁI: %d / %d" % [wave_idx, total_waves]


func _on_boss_spawned(boss_node: Node) -> void:
	var boss := boss_node as EnemyBase
	if boss == null:
		return
	boss_box.visible = true
	if not boss.boss_hp_changed.is_connected(_on_boss_hp_changed):
		boss.boss_hp_changed.connect(_on_boss_hp_changed)
	if not boss.died.is_connected(_on_boss_died):
		boss.died.connect(_on_boss_died)
	_on_boss_hp_changed(boss.current_hp, boss.max_hp, boss.stats.enemy_name, boss.boss_phase)


func _on_boss_hp_changed(cur: float, mx: float, b_name: String, phase: int) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = mx
		boss_hp_bar.value = cur
	if boss_name_label:
		boss_name_label.text = "%s — PHA %d (%d / %d)" % [b_name.to_upper(), phase, int(ceil(cur)), int(mx)]


func _on_boss_died(_enemy: EnemyBase) -> void:
	boss_box.visible = false


func _on_stage_cleared(result: Dictionary) -> void:
	get_tree().paused = true
	_hide_all_panels()
	result_panel.visible = true
	_result_title_label.text = "CHIẾN THẮNG MÀN " + str(result.get("stage_id", 1)) + "!"
	var rank_str := str(result.get("rank", "A"))
	_result_rank_label.text = "HẠNG: " + rank_str
	_result_rank_label.modulate = Color(1.0, 0.88, 0.25) if rank_str == "S" else (Color(0.45, 0.95, 0.55) if rank_str == "A" else Color(0.75, 0.85, 1.0))
	_result_details_label.text = (
		"Tổng điểm: %d\nThời gian hoàn thành: %.1f giây\nThưởng qua màn: +%d Vàng"
		% [int(result.get("score", 0)), float(result.get("time", 0.0)), int(result.get("gold_reward", 0))]
	)
	_next_stage_btn.visible = bool(result.get("has_next_stage", false))


func _on_player_died() -> void:
	get_tree().paused = true
	_hide_all_panels()
	gameover_panel.visible = true


func _create_bar(fill_col: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(280, height)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.07, 0.12, 0.88)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.65, 0.54, 0.32, 0.85)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4

	var fg := StyleBoxFlat.new()
	fg.bg_color = fill_col
	fg.corner_radius_top_left = 3
	fg.corner_radius_top_right = 3
	fg.corner_radius_bottom_left = 3
	fg.corner_radius_bottom_right = 3

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar


func _create_overlay_label(parent_bar: ProgressBar, txt: String) -> Label:
	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.text = txt
	parent_bar.add_child(lbl)
	return lbl


func _create_styled_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.14, 0.90)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.76, 0.62, 0.34, 0.9)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	return panel


func _create_center_modal(w: int, h: int) -> Control:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.03, 0.06, 0.65)
	backdrop.visible = false
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var panel := _create_styled_panel()
	panel.custom_minimum_size = Vector2(w, h)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "ModalVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	return backdrop


func _get_modal_vbox(modal_backdrop: Control) -> VBoxContainer:
	return modal_backdrop.find_child("ModalVBox", true, false) as VBoxContainer


func _create_button(txt: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 38)
	btn.pressed.connect(callback)
	return btn
