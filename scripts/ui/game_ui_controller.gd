class_name GameUIController
extends CanvasLayer
## Quản lý toàn bộ giao diện người dùng (UI) phong cách CỔ TRANG / KIẾM HIỆP HD-2D:
## - Khung thanh Sinh Lực (HP) & Chân Khí (MP) có chân dung nhân vật viền vàng đồng, vệt máu trễ (damage trail) và ấn triện son đỏ.
## - Banner thông báo kiểu Cuộn Thư Cổ Trang (Trục cuộn gỗ + Viền vàng son + Hiệu ứng mở cuộn mượt mà).
## - Hiển thị Thời Tiết / Khí Tượng tự động ngẫu nhiên (không cần bấm phím đổi sáng).
## - Menu chính, Chọn màn (1-5), Lò rèn nâng cấp, Tạm dừng, Hộp thoại Chân dung NPC và Bảng Phong Thần S/A/B/C.

signal start_stage_requested(stage_id: int)
signal enter_town_hub_requested
signal toggle_dof_requested
signal npc_service_requested(role: String)

var hud_root: Control
var hp_bar: ProgressBar
var hp_trail_bar: ProgressBar
var hp_label: Label
var energy_bar: ProgressBar
var energy_label: Label
var wave_label: Label
var gold_label: Label
var score_label: Label
var time_label: Label
var weather_label: Label
var banner_box: Control
var banner_title: Label
var banner_sub: Label
var _banner_tween: Tween

var boss_box: PanelContainer
var boss_name_label: Label
var boss_hp_bar: ProgressBar
var boss_hp_trail: ProgressBar

var main_menu_panel: Control
var stage_select_panel: Control
var upgrade_panel: Control
var pause_panel: Control
var result_panel: Control
var gameover_panel: Control
var dialogue_panel: Control

var _stage_buttons_box: VBoxContainer
var _upgrade_info_label: Label
var _result_title_label: Label
var _result_details_label: Label
var _result_rank_label: Label
var _next_stage_btn: Button
var _dlg_portrait: TextureRect
var _dlg_name_lbl: Label
var _dlg_text_lbl: Label
var _dlg_action_btn: Button
var _current_npc_role: String = ""


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
	_build_dialogue_panel()

	GameManager.stats_updated.connect(_on_stats_updated)
	GameManager.stage_cleared.connect(_on_stage_cleared)
	GameManager.player_died.connect(_on_player_died)
	GameManager.boss_spawned.connect(_on_boss_spawned)
	SaveManager.data_changed.connect(_refresh_all_menus)

	show_main_menu()


func _process(delta: float) -> void:
	if GameManager.is_stage_active and time_label:
		var t := GameManager.stage_elapsed_time
		var mins := int(t) / 60
		var secs := int(t) % 60
		time_label.text = "❖ Thời Khắc: %02d:%02d" % [mins, secs]

	# Hiệu ứng thanh vệt vàng đuổi theo khi mất máu (Damage Trail cực mượt kiểu game cổ trang)
	if hp_trail_bar and hp_bar:
		hp_trail_bar.max_value = hp_bar.max_value
		if hp_trail_bar.value > hp_bar.value:
			hp_trail_bar.value = move_toward(hp_trail_bar.value, hp_bar.value, hp_bar.max_value * 0.45 * delta)
		else:
			hp_trail_bar.value = hp_bar.value

	if boss_hp_trail and boss_hp_bar and boss_box and boss_box.visible:
		boss_hp_trail.max_value = boss_hp_bar.max_value
		if boss_hp_trail.value > boss_hp_bar.value:
			boss_hp_trail.value = move_toward(boss_hp_trail.value, boss_hp_bar.value, boss_hp_bar.max_value * 0.35 * delta)
		else:
			boss_hp_trail.value = boss_hp_bar.value


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if dialogue_panel and dialogue_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		elif GameManager.is_stage_active:
			_toggle_pause()
		elif not main_menu_panel.visible and not stage_select_panel.visible and not upgrade_panel.visible:
			_toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.keycode == KEY_G:
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


## Cập nhật nhãn thời tiết cổ trang mỗi khi ánh sáng tự động đổi ngẫu nhiên
func update_weather_display(display_name: String) -> void:
	if weather_label:
		weather_label.text = "❖ Thiên Tượng: " + display_name


## Hiện thông báo kiểu Cuộn Thư Cổ Trang (mở cuộn ngang từ giữa ra 2 bên rất mượt)
func show_wave_banner(title: String, subtitle: String) -> void:
	if banner_box == null:
		return
	banner_title.text = "「 " + title + " 」"
	banner_sub.text = subtitle
	banner_box.visible = true
	banner_box.modulate.a = 0.0
	banner_box.scale = Vector2(0.45, 1.0)
	banner_box.pivot_offset = Vector2(banner_box.custom_minimum_size.x * 0.5, banner_box.custom_minimum_size.y * 0.5)

	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(banner_box, "modulate:a", 1.0, 0.28)
	_banner_tween.tween_property(banner_box, "scale:x", 1.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(2.4)
	_banner_tween.tween_property(banner_box, "modulate:a", 0.0, 0.45)
	_banner_tween.tween_callback(func() -> void: banner_box.visible = false)


func show_main_menu() -> void:
	get_tree().paused = true
	GameManager.is_stage_active = false
	_hide_all_panels()
	main_menu_panel.visible = true
	_refresh_all_menus()


func _hide_all_panels() -> void:
	for p in [main_menu_panel, stage_select_panel, upgrade_panel, pause_panel, result_panel, gameover_panel, dialogue_panel]:
		if p:
			p.visible = false


func show_npc_dialogue(npc_data: Dictionary) -> void:
	get_tree().paused = true
	_hide_all_panels()
	_current_npc_role = str(npc_data.get("role", "blacksmith"))
	if _dlg_portrait:
		_dlg_portrait.texture = PixelArtGenerator.get_npc_portrait_texture(_current_npc_role)
	if _dlg_name_lbl:
		_dlg_name_lbl.text = "【 %s • %s 】" % [str(npc_data.get("name", "NPC")), str(npc_data.get("title", ""))]
	if _dlg_text_lbl:
		_dlg_text_lbl.text = str(npc_data.get("text", ""))
	if _dlg_action_btn:
		_dlg_action_btn.text = str(npc_data.get("action_label", "Xác nhận"))
	if dialogue_panel:
		dialogue_panel.visible = true


func open_stage_select_from_hub() -> void:
	get_tree().paused = true
	_hide_all_panels()
	_refresh_all_menus()
	stage_select_panel.visible = true


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

	# =========================================================================
	# GÓC TRÊN TRÁI: BẢNG TRẠNG THÁI CỔ TRANG (Chân dung + Sinh Lực + Chân Khí)
	# =========================================================================
	var status_frame := _create_classical_panel(Color(0.11, 0.08, 0.07, 0.90), Color(0.84, 0.66, 0.30, 0.96))
	status_frame.position = Vector2(18, 14)
	status_frame.custom_minimum_size = Vector2(396, 106)
	hud_root.add_child(status_frame)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	status_frame.add_child(hbox)

	# Khung chân dung Lữ Khách có viền sơn son thếp vàng
	var portrait_frame := _create_classical_panel(Color(0.18, 0.07, 0.07, 0.96), Color(0.92, 0.74, 0.34, 1.0))
	portrait_frame.custom_minimum_size = Vector2(76, 76)
	hbox.add_child(portrait_frame)

	var hero_tex := TextureRect.new()
	hero_tex.texture = PixelArtGenerator.get_hero_portrait_texture()
	hero_tex.custom_minimum_size = Vector2(64, 64)
	hero_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.add_child(hero_tex)

	var bars_col := VBoxContainer.new()
	bars_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars_col.add_theme_constant_override("separation", 6)
	hbox.add_child(bars_col)

	var name_row := HBoxContainer.new()
	bars_col.add_child(name_row)

	# Ấn triện son đỏ cổ trang góc tên nhân vật
	var seal := _create_red_seal("KIẾM")
	name_row.add_child(seal)

	var hero_title := Label.new()
	hero_title.text = "  LỮ KHÁCH WINDFERRY"
	hero_title.add_theme_font_size_override("font_size", 14)
	hero_title.modulate = Color(0.98, 0.86, 0.50)
	name_row.add_child(hero_title)

	# Thanh Sinh Lực (HP) 2 lớp: vệt vàng trễ phía sau + thanh son đỏ phía trước
	var hp_holder := Control.new()
	hp_holder.custom_minimum_size = Vector2(276, 22)
	bars_col.add_child(hp_holder)

	hp_trail_bar = _create_classical_bar(Color(0.95, 0.76, 0.24), Color(0.08, 0.05, 0.05, 0.92), 22, true)
	hp_trail_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_holder.add_child(hp_trail_bar)

	hp_bar = _create_classical_bar(Color(0.76, 0.14, 0.16), Color(0, 0, 0, 0), 22, false)
	hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_holder.add_child(hp_bar)
	hp_label = _create_overlay_label(hp_bar, "SINH LỰC: 120 / 120")

	# Thanh Chân Khí (MP / Kỹ năng K) màu ngọc bích cổ trang
	energy_bar = _create_classical_bar(Color(0.14, 0.62, 0.66), Color(0.05, 0.09, 0.10, 0.92), 18, true)
	energy_bar.custom_minimum_size = Vector2(276, 18)
	bars_col.add_child(energy_bar)
	energy_label = _create_overlay_label(energy_bar, "CHÂN KHÍ (K): 100 / 100")

	# Dòng gợi ý thao tác ngắn gọn bên dưới bảng máu
	var controls_hint := Label.new()
	controls_hint.position = Vector2(22, 126)
	controls_hint.text = "WASD: Hành tẩu  •  [E] Giao tiếp/Mở rương  •  [J] Tam Liên Trảm  •  [K] Kiếm Khí  •  [L] Thân Pháp  •  [ESC] Tạm nghỉ"
	controls_hint.add_theme_font_size_override("font_size", 12)
	controls_hint.modulate = Color(0.92, 0.86, 0.72, 0.88)
	hud_root.add_child(controls_hint)

	# =========================================================================
	# GÓC TRÊN PHẢI: THẺ NGỌC CHIẾN TÍCH & THIÊN TƯỢNG (Cổ trang)
	# =========================================================================
	var top_right_panel := _create_classical_panel(Color(0.11, 0.08, 0.07, 0.90), Color(0.84, 0.66, 0.30, 0.96))
	top_right_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right_panel.position = Vector2(-290, 14)
	top_right_panel.custom_minimum_size = Vector2(272, 134)
	hud_root.add_child(top_right_panel)

	var tr_vbox := VBoxContainer.new()
	tr_vbox.add_theme_constant_override("separation", 4)
	top_right_panel.add_child(tr_vbox)

	wave_label = Label.new()
	wave_label.text = "❖ Chiến Đợt: 1 / 3"
	wave_label.add_theme_font_size_override("font_size", 15)
	wave_label.modulate = Color(1.0, 0.85, 0.40)
	tr_vbox.add_child(wave_label)

	gold_label = Label.new()
	gold_label.text = "❖ Ngân Lượng: 0 Lượng"
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.modulate = Color(1.0, 0.92, 0.50)
	tr_vbox.add_child(gold_label)

	score_label = Label.new()
	score_label.text = "❖ Chiến Công: 0"
	score_label.add_theme_font_size_override("font_size", 14)
	score_label.modulate = Color(0.95, 0.90, 0.82)
	tr_vbox.add_child(score_label)

	time_label = Label.new()
	time_label.text = "❖ Thời Khắc: 00:00"
	time_label.add_theme_font_size_override("font_size", 13)
	time_label.modulate = Color(0.76, 0.88, 0.94)
	tr_vbox.add_child(time_label)

	weather_label = Label.new()
	weather_label.text = "❖ Thiên Tượng: Màn Đêm Tĩnh Mịch"
	weather_label.add_theme_font_size_override("font_size", 13)
	weather_label.modulate = Color(0.95, 0.78, 0.52)
	tr_vbox.add_child(weather_label)

	# =========================================================================
	# BANNER THÔNG BÁO GIỮA MÀN HÌNH KIỂU CUỘN THƯ CỔ TRANG (Classical Scroll)
	# =========================================================================
	var scroll_hbox := HBoxContainer.new()
	scroll_hbox.set_anchors_preset(Control.PRESET_CENTER_TOP)
	scroll_hbox.position = Vector2(-290, 82)
	scroll_hbox.custom_minimum_size = Vector2(580, 86)
	scroll_hbox.add_theme_constant_override("separation", 0)
	scroll_hbox.visible = false
	scroll_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(scroll_hbox)
	banner_box = scroll_hbox

	# Trục gỗ cuộn thư bên trái
	var left_rod := _create_scroll_rod()
	scroll_hbox.add_child(left_rod)

	# Thân giấy gió cổ trang viền son vàng
	var scroll_body := _create_classical_panel(Color(0.14, 0.09, 0.07, 0.94), Color(0.88, 0.68, 0.30, 1.0))
	scroll_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_hbox.add_child(scroll_body)

	var b_vbox := VBoxContainer.new()
	b_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	b_vbox.add_theme_constant_override("separation", 4)
	scroll_body.add_child(b_vbox)

	var top_ornament := Label.new()
	top_ornament.text = "─────── ❖ ───────"
	top_ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_ornament.add_theme_font_size_override("font_size", 11)
	top_ornament.modulate = Color(0.86, 0.66, 0.30, 0.85)
	b_vbox.add_child(top_ornament)

	banner_title = Label.new()
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_title.add_theme_font_size_override("font_size", 21)
	banner_title.modulate = Color(1.0, 0.88, 0.44)
	b_vbox.add_child(banner_title)

	banner_sub = Label.new()
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub.add_theme_font_size_override("font_size", 13)
	banner_sub.modulate = Color(0.95, 0.88, 0.74)
	b_vbox.add_child(banner_sub)

	# Trục gỗ cuộn thư bên phải
	var right_rod := _create_scroll_rod()
	scroll_hbox.add_child(right_rod)

	# =========================================================================
	# THANH MÁU LỚN CỦA BOSS PHONG CÁCH CỔ TRANG UY NGHI
	# =========================================================================
	boss_box = _create_classical_panel(Color(0.13, 0.05, 0.06, 0.93), Color(0.90, 0.68, 0.28, 1.0))
	boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	boss_box.position = Vector2(-310, -90)
	boss_box.custom_minimum_size = Vector2(620, 72)
	boss_box.visible = false
	hud_root.add_child(boss_box)

	var boss_vbox := VBoxContainer.new()
	boss_vbox.add_theme_constant_override("separation", 6)
	boss_box.add_child(boss_vbox)

	boss_name_label = Label.new()
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 17)
	boss_name_label.modulate = Color(1.0, 0.78, 0.38)
	boss_name_label.text = "【 MA VƯƠNG HẮC ÁM MALAKOR • ĐỆ NHẤT CẢNH 】"
	boss_vbox.add_child(boss_name_label)

	var boss_bar_holder := Control.new()
	boss_bar_holder.custom_minimum_size = Vector2(580, 22)
	boss_vbox.add_child(boss_bar_holder)

	boss_hp_trail = _create_classical_bar(Color(0.96, 0.76, 0.25), Color(0.08, 0.03, 0.04, 0.95), 22, true)
	boss_hp_trail.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_bar_holder.add_child(boss_hp_trail)

	boss_hp_bar = _create_classical_bar(Color(0.78, 0.10, 0.20), Color(0, 0, 0, 0), 22, false)
	boss_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_bar_holder.add_child(boss_hp_bar)


func _build_main_menu() -> void:
	main_menu_panel = _create_center_modal(540, 440)
	var vbox := _get_modal_vbox(main_menu_panel)

	var ornament := Label.new()
	ornament.text = "━━━━━━━━━  ❖  ━━━━━━━━━"
	ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ornament.modulate = Color(0.88, 0.68, 0.30)
	vbox.add_child(ornament)

	var title := Label.new()
	title.text = "PHONG HÀNH KÝ • WINDFERRY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.modulate = Color(1.0, 0.86, 0.40)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Hành Động Cổ Trang 2.5D HD-2D\n5 Bản Đồ Chiến Trận • Thiên Tượng Biến Chuyển Tự Nhiên • Làng Cổ Tương Tác"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.modulate = Color(0.92, 0.86, 0.74)
	vbox.add_child(sub)

	var hub_btn := _create_button("❖ HÀNH TẨU LÀNG CỔ WINDFERRY (NPC & RƯƠNG BÁU)", func() -> void:
		_hide_all_panels()
		boss_box.visible = false
		get_tree().paused = false
		enter_town_hub_requested.emit()
	)
	vbox.add_child(hub_btn)

	var play_btn := _create_button("❖ XUẤT TRẬN NGAY (MÀN 1)", func() -> void:
		_start_stage(SaveManager.unlocked_stage)
	)
	play_btn.name = "QuickPlayBtn"
	vbox.add_child(play_btn)

	vbox.add_child(_create_button("❖ CHỌN CHIẾN TRƯỜNG (5 MÀN BẢN ĐỒ RIÊNG)", func() -> void:
		_hide_all_panels()
		_refresh_all_menus()
		stage_select_panel.visible = true
	))

	vbox.add_child(_create_button("❖ LÒ RÈN CƯỜNG HÓA (DÙNG NGÂN LƯỢNG)", func() -> void:
		_hide_all_panels()
		_refresh_all_menus()
		upgrade_panel.visible = true
	))

	vbox.add_child(_create_button("❖ TẨY TỦY CHƠI LẠI TỪ ĐẦU", func() -> void:
		SaveManager.reset_save()
		_refresh_all_menus()
	))


func _build_stage_select_menu() -> void:
	stage_select_panel = _create_center_modal(600, 460)
	var vbox := _get_modal_vbox(stage_select_panel)

	var title := Label.new()
	title.text = "【 BẢN ĐỒ CHIẾN TRẬN — NGŨ ĐẠI ẢI 】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.86, 0.40)
	vbox.add_child(title)

	_stage_buttons_box = VBoxContainer.new()
	_stage_buttons_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_stage_buttons_box)

	vbox.add_child(_create_button("QUAY LẠI CHÍNH ĐIỆN", func() -> void:
		show_main_menu()
	))


func _build_upgrade_menu() -> void:
	upgrade_panel = _create_center_modal(560, 430)
	var vbox := _get_modal_vbox(upgrade_panel)

	var title := Label.new()
	title.text = "【 LÒ RÈN BINH KHÍ • CƯỜNG HÓA TU VI 】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.86, 0.40)
	vbox.add_child(title)

	_upgrade_info_label = Label.new()
	_upgrade_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_info_label.add_theme_font_size_override("font_size", 14)
	_upgrade_info_label.modulate = Color(0.95, 0.88, 0.74)
	vbox.add_child(_upgrade_info_label)

	var btn_atk := _create_button("Tôi Luyện Kiếm Khí (+4 Công Lực)", func() -> void:
		if SaveManager.buy_upgrade("attack"):
			AudioManager.play_sfx("pickup")
			_refresh_all_menus()
	)
	btn_atk.name = "BtnAtk"
	vbox.add_child(btn_atk)

	var btn_hp := _create_button("Rèn Hộ Tâm Giáp (+25 Sinh Lực)", func() -> void:
		if SaveManager.buy_upgrade("max_hp"):
			AudioManager.play_sfx("pickup")
			_refresh_all_menus()
	)
	btn_hp.name = "BtnHp"
	vbox.add_child(btn_hp)

	var btn_spd := _create_button("Tu Luyện Khinh Công (+0.45 Thân Pháp)", func() -> void:
		if SaveManager.buy_upgrade("speed"):
			AudioManager.play_sfx("pickup")
			_refresh_all_menus()
	)
	btn_spd.name = "BtnSpd"
	vbox.add_child(btn_spd)

	vbox.add_child(_create_button("RỜI LÒ RÈN", func() -> void:
		if get_tree().paused and not GameManager.is_stage_active and not main_menu_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		else:
			show_main_menu()
	))


func _build_pause_menu() -> void:
	pause_panel = _create_center_modal(430, 330)
	var vbox := _get_modal_vbox(pause_panel)

	var title := Label.new()
	title.text = "【 TẠM DỪNG CUỘC CHIẾN 】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.86, 0.40)
	vbox.add_child(title)

	vbox.add_child(_create_button("TIẾP TỤC HÀNH TẨU", func() -> void:
		_toggle_pause()
	))
	vbox.add_child(_create_button("TÁI CHIẾN MÀN NÀY", func() -> void:
		_start_stage(GameManager.current_stage_id)
	))
	vbox.add_child(_create_button("VỀ CHÍNH ĐIỆN", func() -> void:
		show_main_menu()
	))


func _build_result_menu() -> void:
	result_panel = _create_center_modal(520, 420)
	var vbox := _get_modal_vbox(result_panel)

	_result_title_label = Label.new()
	_result_title_label.text = "【 KHẢI HOÀN PHÁ ẢI 】"
	_result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title_label.add_theme_font_size_override("font_size", 24)
	_result_title_label.modulate = Color(1.0, 0.86, 0.36)
	vbox.add_child(_result_title_label)

	_result_rank_label = Label.new()
	_result_rank_label.text = "ĐẠT HẠNG: S"
	_result_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_rank_label.add_theme_font_size_override("font_size", 40)
	_result_rank_label.modulate = Color(1.0, 0.88, 0.25)
	vbox.add_child(_result_rank_label)

	_result_details_label = Label.new()
	_result_details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_details_label.add_theme_font_size_override("font_size", 15)
	_result_details_label.modulate = Color(0.95, 0.89, 0.76)
	vbox.add_child(_result_details_label)

	_next_stage_btn = _create_button("TIẾN VÀO ẢI TIẾP THEO", func() -> void:
		var next_id := mini(GameManager.TOTAL_STAGES, GameManager.current_stage_id + 1)
		_start_stage(next_id)
	)
	vbox.add_child(_next_stage_btn)

	vbox.add_child(_create_button("VỀ LÀNG WINDFERRY (GẶP NPC & CHUẨN BỊ)", func() -> void:
		_hide_all_panels()
		boss_box.visible = false
		get_tree().paused = false
		enter_town_hub_requested.emit()
	))

	vbox.add_child(_create_button("VỀ CHÍNH ĐIỆN", func() -> void:
		show_main_menu()
	))


func _build_gameover_menu() -> void:
	gameover_panel = _create_center_modal(450, 310)
	var vbox := _get_modal_vbox(gameover_panel)

	var title := Label.new()
	title.text = "【 TRỌNG THƯƠNG BẠI TRẬN 】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(0.95, 0.30, 0.30)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Anh hùng khó tránh lúc sa cơ. Hãy về Lò Rèn cường hóa binh khí hoặc tái chiến!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.modulate = Color(0.94, 0.86, 0.74)
	vbox.add_child(sub)

	vbox.add_child(_create_button("TÁI CHIẾN MÀN NÀY", func() -> void:
		_start_stage(GameManager.current_stage_id)
	))
	vbox.add_child(_create_button("VÀO LÒ RÈN CƯỜNG HÓA", func() -> void:
		_hide_all_panels()
		_refresh_all_menus()
		upgrade_panel.visible = true
	))
	vbox.add_child(_create_button("VỀ CHÍNH ĐIỆN", func() -> void:
		show_main_menu()
	))


## Hộp thoại Chân dung NPC phong cách Cuộn Thư Cổ Trang
func _build_dialogue_panel() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.02, 0.02, 0.50)
	backdrop.visible = false
	add_child(backdrop)
	dialogue_panel = backdrop

	var panel := _create_classical_panel(Color(0.12, 0.08, 0.07, 0.95), Color(0.88, 0.68, 0.30, 1.0))
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-390, -212)
	panel.custom_minimum_size = Vector2(780, 190)
	backdrop.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)

	var p_frame := _create_classical_panel(Color(0.18, 0.08, 0.08, 0.95), Color(0.92, 0.74, 0.34, 1.0))
	p_frame.custom_minimum_size = Vector2(142, 142)
	hbox.add_child(p_frame)

	_dlg_portrait = TextureRect.new()
	_dlg_portrait.custom_minimum_size = Vector2(126, 126)
	_dlg_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dlg_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p_frame.add_child(_dlg_portrait)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 8)
	hbox.add_child(text_col)

	_dlg_name_lbl = Label.new()
	_dlg_name_lbl.add_theme_font_size_override("font_size", 18)
	_dlg_name_lbl.modulate = Color(1.0, 0.86, 0.40)
	text_col.add_child(_dlg_name_lbl)

	_dlg_text_lbl = Label.new()
	_dlg_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text_lbl.add_theme_font_size_override("font_size", 15)
	_dlg_text_lbl.modulate = Color(0.95, 0.90, 0.80)
	_dlg_text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_col.add_child(_dlg_text_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	text_col.add_child(btn_row)

	_dlg_action_btn = _create_button("Thực hiện", func() -> void:
		if _current_npc_role == "blacksmith":
			_hide_all_panels()
			_refresh_all_menus()
			upgrade_panel.visible = true
		else:
			_hide_all_panels()
			get_tree().paused = false
			npc_service_requested.emit(_current_npc_role)
	)
	_dlg_action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(_dlg_action_btn)

	var close_btn := _create_button("Cáo từ", func() -> void:
		_hide_all_panels()
		get_tree().paused = false
	)
	close_btn.custom_minimum_size = Vector2(140, 38)
	btn_row.add_child(close_btn)


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
		gold_label.text = "❖ Ngân Lượng: " + str(SaveManager.gold) + " Lượng"

	var quick_btn := main_menu_panel.find_child("QuickPlayBtn", true, false) as Button
	if quick_btn:
		quick_btn.text = "❖ XUẤT TRẬN NGAY (ẢI MỚI NHẤT: MÀN " + str(SaveManager.unlocked_stage) + ")"

	if _stage_buttons_box:
		for c in _stage_buttons_box.get_children():
			c.queue_free()
		for s_id in range(1, GameManager.TOTAL_STAGES + 1):
			var st := StageDatabase.get_stage_data(s_id)
			var unlocked := s_id <= SaveManager.unlocked_stage
			var rec: Dictionary = SaveManager.stage_records.get(str(s_id), {})
			var rank_str := " [Hạng %s • %d điểm]" % [str(rec["rank"]), int(rec["score"])] if rec.has("rank") else ""
			var btn_text := st.stage_name + rank_str if unlocked else (st.stage_name + " (Chưa khai mở)")
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
			"NGÂN LƯỢNG HIỆN CÓ: %d LƯỢNG\n" % SaveManager.gold
			+ "Công lực: Tầng %d (+%.0f)  •  Sinh lực: Tầng %d (+%.0f)  •  Khinh công: Tầng %d (+%.2f)"
			% [lv_atk, SaveManager.get_bonus_attack(), lv_hp, SaveManager.get_bonus_max_hp(), lv_spd, SaveManager.get_bonus_speed()]
		)
		var b_atk := upgrade_panel.find_child("BtnAtk", true, false) as Button
		var b_hp := upgrade_panel.find_child("BtnHp", true, false) as Button
		var b_spd := upgrade_panel.find_child("BtnSpd", true, false) as Button
		if b_atk:
			b_atk.text = "Tôi Luyện Kiếm Khí (+4 Công lực) — %d Lượng" % SaveManager.get_upgrade_cost("attack")
		if b_hp:
			b_hp.text = "Rèn Hộ Tâm Giáp (+25 Sinh lực) — %d Lượng" % SaveManager.get_upgrade_cost("max_hp")
		if b_spd:
			b_spd.text = "Tu Luyện Khinh Công (+0.45 Thân pháp) — %d Lượng" % SaveManager.get_upgrade_cost("speed")


func _on_player_hp_changed(cur: float, mx: float) -> void:
	if hp_bar:
		hp_bar.max_value = mx
		hp_bar.value = cur
	if hp_label:
		hp_label.text = "SINH LỰC: %d / %d" % [int(ceil(cur)), int(mx)]


func _on_player_energy_changed(cur: float, mx: float) -> void:
	if energy_bar:
		energy_bar.max_value = mx
		energy_bar.value = cur
	if energy_label:
		energy_label.text = "CHÂN KHÍ (K): %d / %d" % [int(cur), int(mx)]


func _on_stats_updated(score: int, gold: int, wave_idx: int, total_waves: int) -> void:
	if score_label:
		score_label.text = "❖ Chiến Công: " + str(score)
	if gold_label:
		gold_label.text = "❖ Ngân Lượng: " + str(gold) + " Lượng"
	if wave_label:
		wave_label.text = "❖ Chiến Đợt: %d / %d" % [wave_idx, total_waves]


func _on_boss_spawned(boss_node: Node) -> void:
	var boss := boss_node as EnemyBase
	if boss == null:
		return
	boss_box.visible = true
	if boss_hp_trail:
		boss_hp_trail.max_value = boss.max_hp
		boss_hp_trail.value = boss.current_hp
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
		var phase_txt := "ĐỆ NHẤT CẢNH" if phase == 1 else ("ĐỆ NHỊ CẢNH" if phase == 2 else "CUỒNG NỘ CẢNH")
		boss_name_label.text = "【 %s • %s (%d / %d) 】" % [b_name.to_upper(), phase_txt, int(ceil(cur)), int(mx)]


func _on_boss_died(_enemy: EnemyBase) -> void:
	boss_box.visible = false


func _on_stage_cleared(result: Dictionary) -> void:
	get_tree().paused = true
	_hide_all_panels()
	result_panel.visible = true
	_result_title_label.text = "【 KHẢI HOÀN PHÁ ẢI %d 】" % int(result.get("stage_id", 1))
	var rank_str := str(result.get("rank", "A"))
	_result_rank_label.text = "PHONG HẠNG: " + rank_str
	_result_rank_label.modulate = Color(1.0, 0.88, 0.25) if rank_str == "S" else (Color(0.45, 0.95, 0.55) if rank_str == "A" else Color(0.85, 0.85, 0.95))
	_result_details_label.text = (
		"Chiến công đạt được: %d\nThời khắc hoàn thành: %.1f giây\nBan thưởng phá ải: +%d Lượng"
		% [int(result.get("score", 0)), float(result.get("time", 0.0)), int(result.get("gold_reward", 0))]
	)
	_next_stage_btn.visible = bool(result.get("has_next_stage", false))


func _on_player_died() -> void:
	get_tree().paused = true
	_hide_all_panels()
	gameover_panel.visible = true


## ============================================================================
## BỘ TẠO THÀNH PHẦN GIAO DIỆN CỔ TRANG (Sơn son thếp vàng, Ấn triện, Trục cuộn)
## ============================================================================

func _create_red_seal(txt: String) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.68, 0.11, 0.12, 0.96)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.95, 0.78, 0.38)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(1.0, 0.94, 0.76)
	p.add_child(lbl)
	return p


func _create_scroll_rod() -> PanelContainer:
	var rod := PanelContainer.new()
	rod.custom_minimum_size = Vector2(18, 86)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.32, 0.17, 0.10, 0.98)
	sb.border_width_left = 2
	sb.border_width_top = 4
	sb.border_width_right = 2
	sb.border_width_bottom = 4
	sb.border_color = Color(0.90, 0.72, 0.32)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	rod.add_theme_stylebox_override("panel", sb)
	return rod


func _create_classical_bar(fill_col: Color, bg_col: Color, height: int, has_border: bool) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(260, height)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_col
	if has_border:
		bg.border_width_left = 2
		bg.border_width_top = 2
		bg.border_width_right = 2
		bg.border_width_bottom = 2
		bg.border_color = Color(0.84, 0.66, 0.30, 0.95)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3

	var fg := StyleBoxFlat.new()
	fg.bg_color = fill_col
	fg.border_width_top = 1
	fg.border_color = fill_col.lightened(0.35)
	fg.corner_radius_top_left = 2
	fg.corner_radius_top_right = 2
	fg.corner_radius_bottom_left = 2
	fg.corner_radius_bottom_right = 2

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar


func _create_overlay_label(parent_bar: ProgressBar, txt: String) -> Label:
	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(1.0, 0.96, 0.86)
	lbl.text = txt
	parent_bar.add_child(lbl)
	return lbl


func _create_classical_panel(bg_col: Color, border_col: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border_col
	sb.corner_radius_top_left = 5
	sb.corner_radius_top_right = 5
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_bottom_right = 5
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.50)
	sb.shadow_size = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", sb)
	return panel


func _create_center_modal(w: int, h: int) -> Control:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.02, 0.02, 0.68)
	backdrop.visible = false
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var panel := _create_classical_panel(Color(0.11, 0.08, 0.07, 0.95), Color(0.88, 0.68, 0.30, 1.0))
	panel.custom_minimum_size = Vector2(w, h)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "ModalVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 11)
	panel.add_child(vbox)
	return backdrop


func _get_modal_vbox(modal_backdrop: Control) -> VBoxContainer:
	return modal_backdrop.find_child("ModalVBox", true, false) as VBoxContainer


func _create_button(txt: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 38)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.20, 0.13, 0.10, 0.94)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.80, 0.62, 0.28, 0.92)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.42, 0.14, 0.13, 0.98)
	hover.border_color = Color(1.0, 0.84, 0.40, 1.0)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.56, 0.18, 0.15, 1.0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82))
	btn.pressed.connect(callback)
	return btn
