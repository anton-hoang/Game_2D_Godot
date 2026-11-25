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
signal relic_chosen(relic_id: String)
signal use_bag_item_requested(item_id: String)

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
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect
var _boss_intro_card: Control
var _boss_intro_name: Label
var _boss_intro_sub: Label

var main_menu_panel: Control
var stage_select_panel: Control
var upgrade_panel: Control
var pause_panel: Control
var result_panel: Control
var gameover_panel: Control
var dialogue_panel: Control
var relic_panel: Control
var quest_board_panel: Control
var inventory_panel: Control
var shop_panel: Control
var gacha_panel: Control

var _hero_portrait_rect: TextureRect
var _hero_title_label: Label
var _weapon_hud_label: Label
var _relic_hud_label: Label
var _quest_list_box: VBoxContainer
var _scarf_buttons_box: HBoxContainer
var _pet_buttons_box: HBoxContainer
var _inv_grid: GridContainer
var _inv_detail_icon: TextureRect
var _inv_detail_title: Label
var _inv_detail_desc: Label
var _inv_detail_btn: Button
var _inv_selected: Dictionary = {}

var _shop_gold_lbl: Label
var _shop_grid: GridContainer
var _shop_detail_icon: TextureRect
var _shop_detail_title: Label
var _shop_detail_desc: Label
var _shop_detail_btn: Button
var _shop_selected: Dictionary = {}

var _gacha_gold_lbl: Label
var _gacha_wheel: GachaWheelControl
var _gacha_result_lbl: Label
var _gacha_wardrobe_grid: GridContainer
var _gacha_btn_x1: Button
var _gacha_btn_x5: Button
var _pending_gacha_results: Array[Dictionary] = []
var _hp_badge_lbl: Label

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
	_build_cinematic_letterbox()
	_build_main_menu()
	_build_stage_select_menu()
	_build_upgrade_menu()
	_build_pause_menu()
	_build_result_menu()
	_build_gameover_menu()
	_build_dialogue_panel()
	_build_relic_selection_panel()
	_build_quest_board_panel()
	_build_inventory_panel()
	_build_shop_panel()
	_build_gacha_panel()

	GameManager.stats_updated.connect(_on_stats_updated)
	GameManager.stage_cleared.connect(_on_stage_cleared)
	GameManager.player_died.connect(_on_player_died)
	GameManager.boss_spawned.connect(_on_boss_spawned)
	SaveManager.data_changed.connect(_refresh_all_menus)
	SaveManager.cosmetic_changed.connect(_refresh_hero_cosmetic_hud)
	SaveManager.inventory_changed.connect(_refresh_hero_cosmetic_hud)
	SaveManager.quest_completed_notify.connect(func(qtitle: String, qsub: String) -> void:
		show_wave_banner("HOÀN THÀNH NHIỆM VỤ: " + qtitle, qsub)
	)

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
		elif quest_board_panel and quest_board_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		elif inventory_panel and inventory_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		elif shop_panel and shop_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		elif gacha_panel and gacha_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		elif relic_panel and relic_panel.visible:
			return # Bắt buộc chọn 1 Bùa Cổ Ngữ trước khi tiếp tục
		elif GameManager.is_stage_active:
			_toggle_pause()
		elif not main_menu_panel.visible and not stage_select_panel.visible and not upgrade_panel.visible:
			_toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.keycode == KEY_I or kev.keycode == KEY_B:
			if inventory_panel and inventory_panel.visible:
				_hide_all_panels()
				get_tree().paused = false
			elif not main_menu_panel.visible and not relic_panel.visible:
				show_inventory()
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
	for p in [main_menu_panel, stage_select_panel, upgrade_panel, pause_panel, result_panel, gameover_panel, dialogue_panel, relic_panel, quest_board_panel, inventory_panel, shop_panel, gacha_panel]:
		if p:
			p.visible = false


## Mở Shop Gacha Trang Phục & Tủ 10 Skin Cổ Trang
func show_gacha_shop() -> void:
	get_tree().paused = true
	_hide_all_panels()
	_refresh_gacha_ui()
	if gacha_panel:
		gacha_panel.visible = true


## Mở Rương Đồ / Túi Đồ Cổ Trang (Phím I / B hoặc từ Menu)
func show_inventory() -> void:
	get_tree().paused = true
	_hide_all_panels()
	_refresh_inventory_ui()
	if inventory_panel:
		inventory_panel.visible = true


## Mở Cửa Hàng Vũ Khí & Đan Dược (từ Thương Nhân Aurelius hoặc Menu)
func show_weapon_shop() -> void:
	get_tree().paused = true
	_hide_all_panels()
	_refresh_shop_ui()
	if shop_panel:
		shop_panel.visible = true


## Hiện bảng chọn 1 trong 3 Bùa Cổ Ngữ Roguelite sau mỗi đợt quái
func show_relic_selection() -> void:
	get_tree().paused = true
	_hide_all_panels()
	if relic_panel:
		relic_panel.visible = true


## Hiện Bảng Truy Nã Nhiệm Vụ Dân Làng & Tủ Đổi Danh Hiệu / Màu Khăn Choàng
func show_quest_board() -> void:
	get_tree().paused = true
	_hide_all_panels()
	_refresh_quest_board()
	if quest_board_panel:
		quest_board_panel.visible = true


func update_relics_hud(relics: Dictionary) -> void:
	if _relic_hud_label == null:
		return
	var parts: Array[String] = []
	if int(relics.get("lightning", 0)) > 0:
		parts.append("⚡Lôi Công Lv.%d" % int(relics["lightning"]))
	if int(relics.get("fire_dash", 0)) > 0:
		parts.append("🔥Hỏa Viêm Lv.%d" % int(relics["fire_dash"]))
	if int(relics.get("siphon", 0)) > 0:
		parts.append("✦Hấp Tinh Lv.%d" % int(relics["siphon"]))
	_relic_hud_label.text = ("Bùa Cổ Ngữ: " + "  |  ".join(parts)) if parts.size() > 0 else ""


func _refresh_hero_cosmetic_hud() -> void:
	if _hero_portrait_rect:
		_hero_portrait_rect.texture = PixelArtGenerator.get_hero_portrait_texture(SaveManager.equipped_scarf, SaveManager.equipped_skin)
	if _hero_title_label:
		_hero_title_label.text = "  " + SaveManager.equipped_title.to_upper()
	if _weapon_hud_label:
		var wd: Dictionary = SaveManager.get_equipped_weapon_data()
		var type_vn: String = {"sword": "KIẾM", "saber": "ĐAO", "bow": "CUNG", "staff": "GẬY PHÉP"}.get(str(wd.get("type", "sword")), "KIẾM")
		_weapon_hud_label.text = "❖ Binh Khí [%s]: %s (+%.0f Công)  •  Nhấn [I] Mở Rương Đồ" % [type_vn, str(wd.get("name", "")), float(wd.get("dmg", 0.0))]
		_weapon_hud_label.modulate = wd.get("color", Color(1.0, 0.88, 0.50))


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
	# GÓC TRÊN TRÁI: KHUNG THANH MÁU CỔ TRANG CAO CẤP (Giống hệt ảnh mẫu!)
	# Chân dung bo tròn viền vàng đồng hoa văn + Huy hiệu Sinh Lực tròn + Thanh Máu / Chân Khí sắc nét
	# =========================================================================
	var status_wrap := Control.new()
	status_wrap.position = Vector2(18, 12)
	status_wrap.custom_minimum_size = Vector2(420, 114)
	status_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(status_wrap)

	# Khung chữ nhật nền gỗ đen viền vàng cổ trang phía sau 2 thanh máu/nội lực
	var bars_panel := _create_classical_panel(Color(0.14, 0.08, 0.06, 0.94), Color(0.88, 0.68, 0.28, 1.0))
	bars_panel.position = Vector2(56, 12)
	bars_panel.custom_minimum_size = Vector2(346, 86)
	status_wrap.add_child(bars_panel)

	var bars_col := VBoxContainer.new()
	bars_col.add_theme_constant_override("separation", 5)
	bars_panel.add_child(bars_col)

	var name_row := HBoxContainer.new()
	bars_col.add_child(name_row)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(34, 1)
	name_row.add_child(spacer)

	var hero_title := Label.new()
	hero_title.text = SaveManager.equipped_title.to_upper()
	hero_title.add_theme_font_size_override("font_size", 15)
	hero_title.modulate = Color(1.0, 0.88, 0.50)
	name_row.add_child(hero_title)
	_hero_title_label = hero_title

	# Thanh Sinh Lực (HP) có viền vàng & vệt máu trễ mượt
	var hp_row := HBoxContainer.new()
	bars_col.add_child(hp_row)
	var hp_sp := Control.new()
	hp_sp.custom_minimum_size = Vector2(32, 1)
	hp_row.add_child(hp_sp)

	var hp_holder := Control.new()
	hp_holder.custom_minimum_size = Vector2(284, 21)
	hp_row.add_child(hp_holder)

	hp_trail_bar = _create_classical_bar(Color(0.96, 0.76, 0.24), Color(0.10, 0.04, 0.05, 0.95), 21, true)
	hp_trail_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_holder.add_child(hp_trail_bar)

	hp_bar = _create_classical_bar(Color(0.80, 0.16, 0.18), Color(0, 0, 0, 0), 21, false)
	hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_holder.add_child(hp_bar)
	hp_label = _create_overlay_label(hp_bar, "SINH LỰC: 120 / 120")

	# Thanh Chân Khí (MP) màu ngọc bích sáng
	var mp_row := HBoxContainer.new()
	bars_col.add_child(mp_row)
	var mp_sp := Control.new()
	mp_sp.custom_minimum_size = Vector2(32, 1)
	mp_row.add_child(mp_sp)

	energy_bar = _create_classical_bar(Color(0.12, 0.64, 0.68), Color(0.05, 0.09, 0.10, 0.95), 18, true)
	energy_bar.custom_minimum_size = Vector2(284, 18)
	mp_row.add_child(energy_bar)
	energy_label = _create_overlay_label(energy_bar, "CHÂN KHÍ: 100 / 100")

	# Khung chân dung TRÒN viền vàng đồng chạm khắc đặt nổi chồng lên cạnh trái thanh máu (giống hệt ảnh!)
	var portrait_circle := PanelContainer.new()
	portrait_circle.position = Vector2(0, 4)
	portrait_circle.custom_minimum_size = Vector2(92, 92)
	var p_sb := StyleBoxFlat.new()
	p_sb.bg_color = Color(0.18, 0.07, 0.06, 0.98)
	p_sb.border_width_left = 4
	p_sb.border_width_top = 4
	p_sb.border_width_right = 4
	p_sb.border_width_bottom = 4
	p_sb.border_color = Color(0.95, 0.76, 0.30)
	p_sb.corner_radius_top_left = 46
	p_sb.corner_radius_top_right = 46
	p_sb.corner_radius_bottom_left = 46
	p_sb.corner_radius_bottom_right = 46
	p_sb.shadow_color = Color(0, 0, 0, 0.6)
	p_sb.shadow_size = 6
	p_sb.content_margin_left = 10
	p_sb.content_margin_right = 10
	p_sb.content_margin_top = 10
	p_sb.content_margin_bottom = 10
	portrait_circle.add_theme_stylebox_override("panel", p_sb)
	status_wrap.add_child(portrait_circle)

	var hero_tex := TextureRect.new()
	hero_tex.texture = PixelArtGenerator.get_hero_portrait_texture(SaveManager.equipped_scarf, SaveManager.equipped_skin)
	hero_tex.custom_minimum_size = Vector2(64, 64)
	hero_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_circle.add_child(hero_tex)
	_hero_portrait_rect = hero_tex

	# Phù hiệu chỉ số nhỏ tròn viền vàng ở đáy vòng chân dung (như số "120" trong ảnh mẫu)
	var badge := PanelContainer.new()
	badge.position = Vector2(24, 82)
	badge.custom_minimum_size = Vector2(44, 22)
	var b_sb := StyleBoxFlat.new()
	b_sb.bg_color = Color(0.24, 0.12, 0.07, 0.98)
	b_sb.border_width_left = 2
	b_sb.border_width_top = 2
	b_sb.border_width_right = 2
	b_sb.border_width_bottom = 2
	b_sb.border_color = Color(0.94, 0.76, 0.30)
	b_sb.corner_radius_top_left = 10
	b_sb.corner_radius_top_right = 10
	b_sb.corner_radius_bottom_left = 10
	b_sb.corner_radius_bottom_right = 10
	badge.add_theme_stylebox_override("panel", b_sb)
	status_wrap.add_child(badge)

	_hp_badge_lbl = Label.new()
	_hp_badge_lbl.text = "120"
	_hp_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_badge_lbl.add_theme_font_size_override("font_size", 11)
	_hp_badge_lbl.modulate = Color(1.0, 0.90, 0.52)
	badge.add_child(_hp_badge_lbl)

	# Dòng gợi ý thao tác ngắn gọn, Vũ Khí đang cầm & Bùa Cổ Ngữ bên dưới bảng máu
	var controls_hint := Label.new()
	controls_hint.position = Vector2(22, 118)
	controls_hint.text = "WASD: Di chuyển • [I] Rương Đồ 7x7 • [E] Tương tác • [J] Công • [K] Tuyệt kỹ • [L] Khinh Công • [Shift/Chuột phải] Đỡ"
	controls_hint.add_theme_font_size_override("font_size", 12)
	controls_hint.modulate = Color(0.96, 0.90, 0.74, 0.90)
	hud_root.add_child(controls_hint)

	_weapon_hud_label = Label.new()
	_weapon_hud_label.position = Vector2(22, 137)
	_weapon_hud_label.add_theme_font_size_override("font_size", 13)
	hud_root.add_child(_weapon_hud_label)
	_refresh_hero_cosmetic_hud()

	_relic_hud_label = Label.new()
	_relic_hud_label.position = Vector2(22, 156)
	_relic_hud_label.text = ""
	_relic_hud_label.add_theme_font_size_override("font_size", 13)
	_relic_hud_label.modulate = Color(0.55, 0.96, 1.0)
	hud_root.add_child(_relic_hud_label)

	# =========================================================================
	# GÓC TRÊN PHẢI: CUỘN GIẤY GIÓ CỔ MÀU KEM VÀNG NÂU (Giống hệt góc phải ảnh mẫu!)
	# =========================================================================
	var top_right_panel := _create_classical_panel(Color(0.91, 0.82, 0.64, 0.94), Color(0.62, 0.42, 0.18, 1.0))
	top_right_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right_panel.position = Vector2(-286, 14)
	top_right_panel.custom_minimum_size = Vector2(268, 136)
	hud_root.add_child(top_right_panel)

	var tr_vbox := VBoxContainer.new()
	tr_vbox.add_theme_constant_override("separation", 4)
	top_right_panel.add_child(tr_vbox)

	var ink_brown := Color(0.24, 0.13, 0.06)
	wave_label = Label.new()
	wave_label.text = "❖ Chiến Đợt: 1 / 3"
	wave_label.add_theme_font_size_override("font_size", 14)
	wave_label.modulate = Color(0.52, 0.12, 0.10)
	tr_vbox.add_child(wave_label)

	gold_label = Label.new()
	gold_label.text = "❖ Ngân Lượng: 0 Lượng"
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.modulate = ink_brown
	tr_vbox.add_child(gold_label)

	score_label = Label.new()
	score_label.text = "❖ Chiến Công: 0"
	score_label.add_theme_font_size_override("font_size", 14)
	score_label.modulate = ink_brown
	tr_vbox.add_child(score_label)

	time_label = Label.new()
	time_label.text = "❖ Thời Khắc: 00:00"
	time_label.add_theme_font_size_override("font_size", 13)
	time_label.modulate = ink_brown
	tr_vbox.add_child(time_label)

	weather_label = Label.new()
	weather_label.text = "❖ Thiên Tượng: Màn Đêm Tĩnh Mịch"
	weather_label.add_theme_font_size_override("font_size", 13)
	weather_label.modulate = Color(0.38, 0.18, 0.08)
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


## Dựng 2 dải đen điện ảnh (Letterbox) & Bảng Danh Hiệu Boss Cổ Trang khi Boss xuất hiện
func _build_cinematic_letterbox() -> void:
	_letterbox_top = ColorRect.new()
	_letterbox_top.color = Color(0.02, 0.01, 0.02, 0.96)
	_letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_letterbox_top.custom_minimum_size = Vector2(0, 88)
	_letterbox_top.position.y = -92
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_letterbox_top)

	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.color = Color(0.02, 0.01, 0.02, 0.96)
	_letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_letterbox_bottom.custom_minimum_size = Vector2(0, 88)
	_letterbox_bottom.offset_top = 0
	_letterbox_bottom.offset_bottom = 88
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_letterbox_bottom)

	var card := _create_classical_panel(Color(0.14, 0.04, 0.05, 0.94), Color(0.95, 0.74, 0.30, 1.0))
	card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	card.position = Vector2(-320, -185)
	card.custom_minimum_size = Vector2(640, 86)
	card.visible = false
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	_boss_intro_card = card

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	_boss_intro_name = Label.new()
	_boss_intro_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_intro_name.add_theme_font_size_override("font_size", 26)
	_boss_intro_name.modulate = Color(1.0, 0.84, 0.36)
	vb.add_child(_boss_intro_name)

	_boss_intro_sub = Label.new()
	_boss_intro_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_intro_sub.add_theme_font_size_override("font_size", 14)
	_boss_intro_sub.modulate = Color(1.0, 0.56, 0.56)
	vb.add_child(_boss_intro_sub)


## Kích hoạt Intro điện ảnh 3.4 giây: Ẩn HUD -> 2 dải đen Letterbox trượt vào -> Bảng danh hiệu Ma Vương -> Mở lại chiến đấu
func play_boss_cinematic_overlay(boss_title: String, boss_subtitle: String, duration: float = 2.6) -> void:
	if _letterbox_top == null or _letterbox_bottom == null:
		return
	if hud_root:
		hud_root.visible = false
	_boss_intro_name.text = "「 " + boss_title + " 」"
	_boss_intro_sub.text = boss_subtitle
	_boss_intro_card.visible = true
	_boss_intro_card.modulate.a = 0.0

	var tw_in := create_tween()
	tw_in.set_parallel(true)
	tw_in.tween_property(_letterbox_top, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(_letterbox_bottom, "offset_top", -88.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(_letterbox_bottom, "offset_bottom", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(_boss_intro_card, "modulate:a", 1.0, 0.55).set_delay(0.25)

	await get_tree().create_timer(duration + 0.65, true, false, true).timeout
	if not is_instance_valid(self):
		return

	var tw_out := create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(_letterbox_top, "position:y", -92.0, 0.45)
	tw_out.tween_property(_letterbox_bottom, "offset_top", 0.0, 0.45)
	tw_out.tween_property(_letterbox_bottom, "offset_bottom", 88.0, 0.45)
	tw_out.tween_property(_boss_intro_card, "modulate:a", 0.0, 0.35)
	await tw_out.finished
	_boss_intro_card.visible = false
	if hud_root:
		hud_root.visible = true


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

	vbox.add_child(_create_button("❖ RƯƠNG ĐỒ & VŨ KHÍ (PHÍM I)", func() -> void:
		show_inventory()
	))

	vbox.add_child(_create_button("❖ CỬA HÀNG THƯƠNG NHÂN (MUA VŨ KHÍ & ĐAN DƯỢC)", func() -> void:
		show_weapon_shop()
	))

	vbox.add_child(_create_button("❖ TỤ BẢO CÁC — SHOP GACHA TRANG PHỤC (10 SKIN)", func() -> void:
		show_gacha_shop()
	))

	vbox.add_child(_create_button("❖ BẢNG TRUY NÃ & TỦ KHĂN CHOÀNG (NHIỆM VỤ)", func() -> void:
		show_quest_board()
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
		elif _current_npc_role == "merchant":
			show_weapon_shop()
		elif _current_npc_role == "tailor":
			show_gacha_shop()
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


## ============================================================================
## BẢNG CHỌN 1 TRONG 3 THẺ BÙA CỔ NGỮ ROGUELITE SAU MỖI ĐỢT QUÁI (WAVE)
## ============================================================================
func _build_relic_selection_panel() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.01, 0.03, 0.72)
	backdrop.visible = false
	add_child(backdrop)
	relic_panel = backdrop

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var main_box := _create_classical_panel(Color(0.11, 0.07, 0.06, 0.96), Color(0.92, 0.72, 0.30, 1.0))
	main_box.custom_minimum_size = Vector2(860, 410)
	center.add_child(main_box)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	main_box.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "【 CHỌN 1 BÙA CỔ NGỮ — BÍ TỊCH TĂNG CƯỜNG 】"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 23)
	hdr.modulate = Color(1.0, 0.86, 0.38)
	vbox.add_child(hdr)

	var sub := Label.new()
	sub.text = "Lĩnh hội 1 trong 3 bí kíp cổ trang dưới đây (có thể cộng dồn nhiều tầng trong trận đánh này!)"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.modulate = Color(0.94, 0.88, 0.74)
	vbox.add_child(sub)

	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 18)
	vbox.add_child(cards_row)

	var relic_cards := [
		{
			"id": "lightning",
			"seal": "LÔI",
			"title": "Lôi Công Kiếm Quyết",
			"accent": Color(0.45, 0.88, 1.0),
			"desc": "Đòn thứ 3 trong chuỗi Tam Liên Trảm giật tia sét lan sang tối đa 3 quái vật gần nhất, gây sát thương chí mạng!",
		},
		{
			"id": "fire_dash",
			"seal": "HỎA",
			"title": "Hỏa Viêm Khinh Công",
			"accent": Color(1.0, 0.56, 0.22),
			"desc": "Mỗi lần thi triển Thân Pháp (Dash - phím L) để lại vệt lửa cháy rực trên mặt đất thiêu đốt toàn bộ kẻ địch đuổi theo!",
		},
		{
			"id": "siphon",
			"seal": "TINH",
			"title": "Hấp Tinh Đại Pháp",
			"accent": Color(0.46, 0.96, 0.62),
			"desc": "Mỗi khi hạ gục một kẻ địch, hấp thụ linh khí hồi ngay 8% Sinh Lực tối đa và +15 Chân Khí (cộng dồn theo tầng)!",
		},
	]

	for rc in relic_cards:
		var card := _create_classical_panel(Color(0.16, 0.10, 0.08, 0.98), rc["accent"])
		card.custom_minimum_size = Vector2(252, 265)
		cards_row.add_child(card)

		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 10)
		card.add_child(cv)

		var seal_center := CenterContainer.new()
		cv.add_child(seal_center)
		seal_center.add_child(_create_red_seal(str(rc["seal"])))

		var ctitle := Label.new()
		ctitle.text = str(rc["title"])
		ctitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ctitle.add_theme_font_size_override("font_size", 18)
		ctitle.modulate = rc["accent"]
		cv.add_child(ctitle)

		var cdesc := Label.new()
		cdesc.text = str(rc["desc"])
		cdesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cdesc.add_theme_font_size_override("font_size", 13)
		cdesc.modulate = Color(0.95, 0.90, 0.80)
		cdesc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(cdesc)

		var rid := str(rc["id"])
		var pick_btn := _create_button("LĨNH HỘI BÍ TỊCH NÀY", func() -> void:
			_hide_all_panels()
			get_tree().paused = false
			relic_chosen.emit(rid)
		)
		cv.add_child(pick_btn)


## ============================================================================
## BẢNG TRUY NÃ NHIỆM VỤ DÂN LÀNG & TỦ ĐỔI DANH HIỆU / MÀU KHĂN CHOÀNG
## ============================================================================
func _build_quest_board_panel() -> void:
	quest_board_panel = _create_center_modal(780, 610)
	var vbox := _get_modal_vbox(quest_board_panel)

	var title := Label.new()
	title.text = "【 BẢNG TRUY NÃ • TỦ KHĂN CHOÀNG & LINH THÚ ĐỒNG HÀNH 】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 21)
	title.modulate = Color(1.0, 0.86, 0.38)
	vbox.add_child(title)

	_quest_list_box = VBoxContainer.new()
	_quest_list_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_quest_list_box)

	var pet_hdr := Label.new()
	pet_hdr.text = "─── CHỌN BẠN ĐỒNG HÀNH LINH THÚ (Tự nhặt vàng • Bắn linh khí • Khiên cứu nguy) ───"
	pet_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pet_hdr.add_theme_font_size_override("font_size", 13)
	pet_hdr.modulate = Color(0.55, 0.96, 0.90)
	vbox.add_child(pet_hdr)

	_pet_buttons_box = HBoxContainer.new()
	_pet_buttons_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_pet_buttons_box.add_theme_constant_override("separation", 12)
	vbox.add_child(_pet_buttons_box)

	var scarf_hdr := Label.new()
	scarf_hdr.text = "─── MÀU KHĂN CHOÀNG ĐÃ MỞ KHÓA (Đổi trực tiếp trên Nhân Vật) ───"
	scarf_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scarf_hdr.add_theme_font_size_override("font_size", 13)
	scarf_hdr.modulate = Color(0.95, 0.84, 0.50)
	vbox.add_child(scarf_hdr)

	_scarf_buttons_box = HBoxContainer.new()
	_scarf_buttons_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_scarf_buttons_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_scarf_buttons_box)

	vbox.add_child(_create_button("ĐÓNG BẢNG TRUY NÃ", func() -> void:
		if not GameManager.is_stage_active and not main_menu_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		else:
			show_main_menu()
	))


func _refresh_quest_board() -> void:
	if _quest_list_box == null or _scarf_buttons_box == null:
		return
	for c in _quest_list_box.get_children():
		c.queue_free()

	for qid in SaveManager.QUEST_DEFINITIONS.keys():
		var qd: Dictionary = SaveManager.QUEST_DEFINITIONS[qid]
		var cur: int = int(SaveManager.quest_progress.get(qid, 0))
		var tgt: int = int(qd["target"])
		var claimed := bool(SaveManager.quest_claimed.get(qid, false))
		var done := cur >= tgt

		var row_panel := _create_classical_panel(Color(0.15, 0.10, 0.08, 0.92), Color(0.76, 0.58, 0.26, 0.85))
		_quest_list_box.add_child(row_panel)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row_panel.add_child(row)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_col)

		var q_lbl := Label.new()
		q_lbl.text = "❖ %s  [%d / %d]" % [str(qd["title"]), cur, tgt]
		q_lbl.add_theme_font_size_override("font_size", 15)
		q_lbl.modulate = Color(0.45, 0.96, 0.55) if done else Color(1.0, 0.86, 0.42)
		info_col.add_child(q_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = "%s\nThưởng: +%d Lượng • Danh hiệu「%s」• %s" % [str(qd["desc"]), int(qd["gold"]), str(qd["unlock_title"]), str(qd["scarf_label"])]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.modulate = Color(0.92, 0.87, 0.76)
		info_col.add_child(desc_lbl)

		var q_key := str(qid)
		var btn_txt := "ĐÃ LĨNH THƯỞNG" if claimed else ("LĨNH THƯỞNG!" if done else "ĐANG LÀM...")
		var claim_btn := _create_button(btn_txt, func() -> void:
			if SaveManager.claim_quest_reward(q_key):
				AudioManager.play_sfx("victory", 1.2)
				_refresh_quest_board()
				show_wave_banner("ĐÃ LĨNH THƯỞNG NHIỆM VỤ!", "Mở khóa Danh hiệu & Màu Khăn Choàng mới!")
		)
		claim_btn.custom_minimum_size = Vector2(150, 42)
		claim_btn.disabled = claimed or not done
		row.add_child(claim_btn)

	# Hàng nút chọn Bạn Đồng Hành Linh Thú (Tiểu Hồ Ly Bạch Tuyết / Tiên Hạc Cổ Trang)
	if _pet_buttons_box:
		for pc in _pet_buttons_box.get_children():
			pc.queue_free()
		var pet_choices := [
			{"id": "fox", "label": "🦊 Tiểu Hồ Ly Bạch Tuyết (Linh Cầu Hồng Ngọc)"},
			{"id": "crane", "label": "🕊 Tiên Hạc Trắng (Linh Khí Ngọc Bích)"},
		]
		for pc_data in pet_choices:
			var p_key: String = str(pc_data["id"])
			var is_eq: bool = (SaveManager.equipped_pet == p_key)
			var pbtn := _create_button(("★ " if is_eq else "") + str(pc_data["label"]), func() -> void:
				SaveManager.equip_pet(p_key)
				AudioManager.play_sfx("pickup", 1.2)
				_refresh_quest_board()
			)
			pbtn.custom_minimum_size = Vector2(320, 36)
			_pet_buttons_box.add_child(pbtn)

	# Hàng nút chọn Màu Khăn Choàng đã mở khóa
	for sc in _scarf_buttons_box.get_children():
		sc.queue_free()
	for scarf_id in SaveManager.SCARF_PALETTES.keys():
		var s_key: String = str(scarf_id)
		var sp: Dictionary = SaveManager.SCARF_PALETTES[s_key]
		var unlocked: bool = SaveManager.unlocked_scarves.has(s_key)
		var equipped: bool = (SaveManager.equipped_scarf == s_key)
		var label_txt: String = ("★ " if equipped else "") + str(sp["name"]) if unlocked else "🔒 " + str(sp["name"])
		var sbtn := _create_button(label_txt, func() -> void:
			if unlocked:
				SaveManager.equip_scarf(s_key)
				AudioManager.play_sfx("pickup", 1.1)
				_refresh_quest_board()
		)
		sbtn.disabled = not unlocked
		_scarf_buttons_box.add_child(sbtn)


## ============================================================================
## RƯƠNG ĐỒ CỔ TRANG DẠNG LƯỚI Ô VUÔNG 7x7 (49 Ô): HIỂN THỊ HÌNH ẢNH VẬT PHẨM TRONG TỪNG Ô
## ============================================================================
func _build_inventory_panel() -> void:
	inventory_panel = _create_center_modal(900, 610)
	var vbox := _get_modal_vbox(inventory_panel)

	var title := Label.new()
	title.text = "【 RƯƠNG ĐỒ CỔ TRANG — TÚI Ô VUÔNG 7×7 (BINH KHÍ & ĐAN DƯỢC) 】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(1.0, 0.86, 0.36)
	vbox.add_child(title)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	# Bên trái: Lưới ô vuông 7x7 cổ trang (49 ô vuông hiển thị hình ảnh Vũ Khí & Đan Dược)
	var grid_panel := _create_classical_panel(Color(0.09, 0.05, 0.05, 0.96), Color(0.86, 0.66, 0.28, 0.95))
	split.add_child(grid_panel)

	_inv_grid = GridContainer.new()
	_inv_grid.columns = 7
	_inv_grid.add_theme_constant_override("h_separation", 6)
	_inv_grid.add_theme_constant_override("v_separation", 6)
	grid_panel.add_child(_inv_grid)

	# Bên phải: Bảng xem chi tiết vật phẩm đang chọn trong ô vuông + Nút Trang Bị / Sử Dụng
	var detail_panel := _create_classical_panel(Color(0.14, 0.08, 0.06, 0.96), Color(0.90, 0.72, 0.30, 1.0))
	detail_panel.custom_minimum_size = Vector2(340, 440)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)

	var dv := VBoxContainer.new()
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_theme_constant_override("separation", 12)
	detail_panel.add_child(dv)

	var icon_box := CenterContainer.new()
	dv.add_child(icon_box)
	var icon_bg := _create_classical_panel(Color(0.08, 0.05, 0.05, 0.95), Color(0.95, 0.78, 0.32, 1.0))
	icon_bg.custom_minimum_size = Vector2(104, 104)
	icon_box.add_child(icon_bg)

	_inv_detail_icon = TextureRect.new()
	_inv_detail_icon.custom_minimum_size = Vector2(78, 78)
	_inv_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_inv_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_bg.add_child(_inv_detail_icon)

	_inv_detail_title = Label.new()
	_inv_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inv_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inv_detail_title.add_theme_font_size_override("font_size", 17)
	_inv_detail_title.modulate = Color(1.0, 0.88, 0.42)
	dv.add_child(_inv_detail_title)

	_inv_detail_desc = Label.new()
	_inv_detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inv_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inv_detail_desc.add_theme_font_size_override("font_size", 13)
	_inv_detail_desc.modulate = Color(0.95, 0.90, 0.80)
	_inv_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(_inv_detail_desc)

	_inv_detail_btn = _create_button("TRANG BỊ / SỬ DỤNG", func() -> void:
		if _inv_selected.is_empty():
			return
		var kind: String = str(_inv_selected.get("kind", ""))
		var id_key: String = str(_inv_selected.get("id", ""))
		if kind == "weapon":
			SaveManager.equip_weapon(id_key)
			AudioManager.play_sfx("slash", 1.15)
		elif kind == "item":
			use_bag_item_requested.emit(id_key)
		_refresh_inventory_ui()
	)
	dv.add_child(_inv_detail_btn)

	vbox.add_child(_create_button("ĐÓNG RƯƠNG ĐỒ (PHÍM I / ESC)", func() -> void:
		if not main_menu_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		else:
			show_main_menu()
	))


func _refresh_inventory_ui() -> void:
	if _inv_grid == null:
		return
	for c in _inv_grid.get_children():
		c.queue_free()

	# Gom tất cả Vũ khí sở hữu + Đan Dược đang có vào 49 ô (lưới 7x7)
	var entries: Array[Dictionary] = []
	for wid in SaveManager.owned_weapons:
		var w_key: String = str(wid)
		if SaveManager.WEAPON_CATALOG.has(w_key):
			var wd: Dictionary = SaveManager.WEAPON_CATALOG[w_key]
			entries.append({
				"kind": "weapon", "id": w_key, "name": str(wd["name"]),
				"rarity": str(wd["rarity"]), "color": wd["color"],
				"tex": PixelArtGenerator.get_weapon_icon_texture(w_key),
				"badge": "★" if (SaveManager.equipped_weapon == w_key) else "",
				"desc": "Loại: %s • +%d Công lực\n%s" % [str(wd["type"]).to_upper(), int(wd["dmg"]), str(wd["desc"])],
				"equipped": (SaveManager.equipped_weapon == w_key),
			})
	for iid in SaveManager.ITEM_CATALOG.keys():
		var i_key: String = str(iid)
		var qty: int = int(SaveManager.bag_items.get(i_key, 0))
		if qty > 0:
			var idata: Dictionary = SaveManager.ITEM_CATALOG[i_key]
			entries.append({
				"kind": "item", "id": i_key, "name": str(idata["name"]),
				"rarity": "Đan Dược", "color": Color(0.42, 0.94, 0.62),
				"tex": PixelArtGenerator.get_bag_item_icon_texture(i_key),
				"badge": "x%d" % qty,
				"desc": "Số lượng: %d\n%s" % [qty, str(idata["desc"])],
				"equipped": false,
			})

	if _inv_selected.is_empty() and entries.size() > 0:
		_inv_selected = entries[0]

	# Vẽ đủ 49 ô vuông 7x7 (ô có đồ hiển thị hình ảnh 44x44 + viền màu hiếm + số lượng, ô trống có nền tối cổ trang)
	for idx in range(49):
		if idx < entries.size():
			var ent: Dictionary = entries[idx]
			var is_sel: bool = (str(_inv_selected.get("id", "")) == str(ent["id"]))
			var slot := _create_grid_slot_button(ent["tex"], str(ent["badge"]), ent["color"], is_sel, func() -> void:
				_inv_selected = ent
				AudioManager.play_sfx("pickup", 1.2)
				_refresh_inventory_ui()
			)
			_inv_grid.add_child(slot)
		else:
			_inv_grid.add_child(_create_empty_grid_slot())

	_update_inventory_detail_panel(entries)


func _update_inventory_detail_panel(entries: Array[Dictionary]) -> void:
	# Đồng bộ lại entry đang chọn (phòng trường hợp vừa dùng hết đan dược)
	var found: Dictionary = {}
	for e in entries:
		if str(e["id"]) == str(_inv_selected.get("id", "")):
			found = e
			break
	if found.is_empty() and entries.size() > 0:
		found = entries[0]
	_inv_selected = found

	if found.is_empty():
		_inv_detail_icon.texture = null
		_inv_detail_title.text = "Rương đồ trống"
		_inv_detail_desc.text = "Hãy đánh quái hoặc ghé Cửa Hàng Thương Nhân để thu thập Binh Khí & Đan Dược!"
		_inv_detail_btn.disabled = true
		return

	_inv_detail_icon.texture = found["tex"]
	_inv_detail_title.text = "[%s]\n%s" % [str(found["rarity"]), str(found["name"])]
	_inv_detail_title.modulate = found["color"]
	_inv_detail_desc.text = str(found["desc"])
	if str(found["kind"]) == "weapon":
		var is_eq: bool = bool(found["equipped"])
		_inv_detail_btn.text = "★ ĐANG TRANG BỊ" if is_eq else "❖ TRANG BỊ BINH KHÍ NÀY"
		_inv_detail_btn.disabled = is_eq
	else:
		_inv_detail_btn.text = "❖ SỬ DỤNG ĐAN DƯỢC NGAY"
		_inv_detail_btn.disabled = false


## ============================================================================
## CỬA HÀNG THƯƠNG NHÂN AURELIUS DẠNG LƯỚI Ô VUÔNG (ĐỒNG BỘ VỚI RƯƠNG ĐỒ 7x7!)
## ============================================================================
func _build_shop_panel() -> void:
	shop_panel = _create_center_modal(900, 610)
	var vbox := _get_modal_vbox(shop_panel)

	var title := Label.new()
	title.text = "【 BINH KHÍ PHỔ & DƯỢC ĐIẾM AURELIUS — CHỌN Ô ĐỂ MUA 】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(1.0, 0.86, 0.36)
	vbox.add_child(title)

	_shop_gold_lbl = Label.new()
	_shop_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_gold_lbl.add_theme_font_size_override("font_size", 15)
	_shop_gold_lbl.modulate = Color(1.0, 0.92, 0.45)
	vbox.add_child(_shop_gold_lbl)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	var grid_panel := _create_classical_panel(Color(0.09, 0.05, 0.05, 0.96), Color(0.86, 0.66, 0.28, 0.95))
	split.add_child(grid_panel)

	_shop_grid = GridContainer.new()
	_shop_grid.columns = 5
	_shop_grid.add_theme_constant_override("h_separation", 8)
	_shop_grid.add_theme_constant_override("v_separation", 8)
	grid_panel.add_child(_shop_grid)

	# Cột chi tiết món hàng đang chọn bên phải + Nút Mua
	var detail_panel := _create_classical_panel(Color(0.14, 0.08, 0.06, 0.96), Color(0.90, 0.72, 0.30, 1.0))
	detail_panel.custom_minimum_size = Vector2(360, 410)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)

	var dv := VBoxContainer.new()
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_theme_constant_override("separation", 12)
	detail_panel.add_child(dv)

	var icon_box := CenterContainer.new()
	dv.add_child(icon_box)
	var icon_bg := _create_classical_panel(Color(0.08, 0.05, 0.05, 0.95), Color(0.95, 0.78, 0.32, 1.0))
	icon_bg.custom_minimum_size = Vector2(104, 104)
	icon_box.add_child(icon_bg)

	_shop_detail_icon = TextureRect.new()
	_shop_detail_icon.custom_minimum_size = Vector2(78, 78)
	_shop_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_shop_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_bg.add_child(_shop_detail_icon)

	_shop_detail_title = Label.new()
	_shop_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_detail_title.add_theme_font_size_override("font_size", 17)
	dv.add_child(_shop_detail_title)

	_shop_detail_desc = Label.new()
	_shop_detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_detail_desc.add_theme_font_size_override("font_size", 13)
	_shop_detail_desc.modulate = Color(0.95, 0.90, 0.80)
	_shop_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(_shop_detail_desc)

	_shop_detail_btn = _create_button("MUA VẬT PHẨM", func() -> void:
		if _shop_selected.is_empty():
			return
		var kind: String = str(_shop_selected.get("kind", ""))
		var id_key: String = str(_shop_selected.get("id", ""))
		if kind == "weapon":
			if SaveManager.buy_weapon(id_key):
				AudioManager.play_sfx("victory", 1.15)
				show_wave_banner("ĐÃ MUA THẦN BINH!", "Đã đưa vào Rương Đồ 7x7 & trang bị ngay!")
		elif kind == "item":
			if SaveManager.buy_bag_item(id_key):
				AudioManager.play_sfx("pickup", 1.15)
		_refresh_shop_ui()
	)
	dv.add_child(_shop_detail_btn)

	vbox.add_child(_create_button("RỜI CỬA HÀNG", func() -> void:
		if not main_menu_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		else:
			show_main_menu()
	))


func _refresh_shop_ui() -> void:
	if _shop_grid == null:
		return
	if _shop_gold_lbl:
		_shop_gold_lbl.text = "❖ NGÂN LƯỢNG HIỆN CÓ: %d LƯỢNG" % SaveManager.gold

	for c in _shop_grid.get_children():
		c.queue_free()

	var catalog_items: Array[Dictionary] = []
	for wid in SaveManager.WEAPON_CATALOG.keys():
		var w_key: String = str(wid)
		var wd: Dictionary = SaveManager.WEAPON_CATALOG[w_key]
		if int(wd["price"]) <= 0:
			continue
		var owned: bool = SaveManager.owned_weapons.has(w_key)
		catalog_items.append({
			"kind": "weapon", "id": w_key, "name": str(wd["name"]),
			"rarity": str(wd["rarity"]), "color": wd["color"],
			"price": int(wd["price"]), "owned": owned,
			"tex": PixelArtGenerator.get_weapon_icon_texture(w_key),
			"badge": "✓" if owned else ("%d" % int(wd["price"])),
			"desc": "Loại: %s • +%d Công lực\nGiá: %d Lượng\n%s" % [str(wd["type"]).to_upper(), int(wd["dmg"]), int(wd["price"]), str(wd["desc"])],
		})
	for iid in SaveManager.ITEM_CATALOG.keys():
		var i_key: String = str(iid)
		var idata: Dictionary = SaveManager.ITEM_CATALOG[i_key]
		var qty: int = int(SaveManager.bag_items.get(i_key, 0))
		catalog_items.append({
			"kind": "item", "id": i_key, "name": str(idata["name"]),
			"rarity": "Đan Dược (Có x%d)" % qty, "color": Color(0.45, 0.95, 0.65),
			"price": int(idata["price"]), "owned": false,
			"tex": PixelArtGenerator.get_bag_item_icon_texture(i_key),
			"badge": "%d" % int(idata["price"]),
			"desc": "Giá: %d Lượng (Đang có x%d trong rương)\n%s" % [int(idata["price"]), qty, str(idata["desc"])],
		})

	if _shop_selected.is_empty() and catalog_items.size() > 0:
		_shop_selected = catalog_items[0]

	# Lưới 5x5 (25 ô vuông bày hàng cổ trang)
	for idx in range(25):
		if idx < catalog_items.size():
			var ent: Dictionary = catalog_items[idx]
			var is_sel: bool = (str(_shop_selected.get("id", "")) == str(ent["id"]))
			var slot := _create_grid_slot_button(ent["tex"], str(ent["badge"]), ent["color"], is_sel, func() -> void:
				_shop_selected = ent
				AudioManager.play_sfx("pickup", 1.2)
				_refresh_shop_ui()
			, 66)
			_shop_grid.add_child(slot)
		else:
			_shop_grid.add_child(_create_empty_grid_slot(66))

	# Cập nhật bảng chi tiết món đang chọn
	var cur_sel: Dictionary = {}
	for ci in catalog_items:
		if str(ci["id"]) == str(_shop_selected.get("id", "")):
			cur_sel = ci
			break
	if cur_sel.is_empty() and catalog_items.size() > 0:
		cur_sel = catalog_items[0]
	_shop_selected = cur_sel

	if not cur_sel.is_empty():
		_shop_detail_icon.texture = cur_sel["tex"]
		_shop_detail_title.text = "[%s]\n%s" % [str(cur_sel["rarity"]), str(cur_sel["name"])]
		_shop_detail_title.modulate = cur_sel["color"]
		_shop_detail_desc.text = str(cur_sel["desc"])
		var price: int = int(cur_sel["price"])
		var owned: bool = bool(cur_sel["owned"])
		_shop_detail_btn.text = "✓ ĐÃ SỞ HỮU TRONG RƯƠNG" if owned else ("❖ MUA NGAY (%d LƯỢNG)" % price)
		_shop_detail_btn.disabled = owned or SaveManager.gold < price


## ============================================================================
## TỤ BẢO CÁC — VÒNG QUAY GACHA 10 TRANG PHỤC CÓ HIỆU ỨNG QUAY THẬT!
## ============================================================================
func _build_gacha_panel() -> void:
	gacha_panel = _create_center_modal(960, 630)
	var vbox := _get_modal_vbox(gacha_panel)

	var title := Label.new()
	title.text = "【 TỤ BẢO CÁC — VÒNG QUAY GACHA 10 TRANG PHỤC CỔ TRANG 】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(1.0, 0.86, 0.36)
	vbox.add_child(title)

	_gacha_gold_lbl = Label.new()
	_gacha_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gacha_gold_lbl.add_theme_font_size_override("font_size", 14)
	_gacha_gold_lbl.modulate = Color(1.0, 0.92, 0.50)
	vbox.add_child(_gacha_gold_lbl)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 20)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	# CỘT TRÁI: Vòng Quay 10 Ô Trang Phục (có hiệu ứng xoay giảm tốc + kim chỉ vàng) + 2 Nút Quay x1 / x5
	var wheel_col := VBoxContainer.new()
	wheel_col.alignment = BoxContainer.ALIGNMENT_CENTER
	wheel_col.add_theme_constant_override("separation", 10)
	split.add_child(wheel_col)

	var wheel_center := CenterContainer.new()
	wheel_col.add_child(wheel_center)

	_gacha_wheel = GachaWheelControl.new()
	_gacha_wheel.custom_minimum_size = Vector2(360, 360)
	_gacha_wheel.spin_finished.connect(_on_gacha_wheel_finished)
	wheel_center.add_child(_gacha_wheel)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	wheel_col.add_child(btn_row)

	_gacha_btn_x1 = _create_button("❖ QUAY 1 LẦN (%d Lượng)" % SaveManager.GACHA_COST_SINGLE, func() -> void:
		_perform_gacha_roll(1)
	)
	_gacha_btn_x1.custom_minimum_size = Vector2(185, 42)
	btn_row.add_child(_gacha_btn_x1)

	_gacha_btn_x5 = _create_button("★ QUAY x5 (%d — BAO HIẾM!)" % SaveManager.GACHA_COST_MULTI, func() -> void:
		_perform_gacha_roll(5)
	)
	_gacha_btn_x5.custom_minimum_size = Vector2(215, 42)
	btn_row.add_child(_gacha_btn_x5)

	# CỘT PHẢI: Thông báo kết quả quay + Tủ 10 Trang Phục dạng lưới ô vuông 5x2 (bấm vào ô để MẶC NGAY!)
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 10)
	split.add_child(right_col)

	var res_panel := _create_classical_panel(Color(0.10, 0.06, 0.06, 0.95), Color(0.88, 0.68, 0.30, 0.95))
	res_panel.custom_minimum_size = Vector2(460, 118)
	right_col.add_child(res_panel)

	_gacha_result_lbl = Label.new()
	_gacha_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gacha_result_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gacha_result_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gacha_result_lbl.add_theme_font_size_override("font_size", 14)
	_gacha_result_lbl.modulate = Color(0.96, 0.90, 0.74)
	_gacha_result_lbl.text = "Bấm QUAY để xoay Vòng Quay 10 Trang Phục!\n• 5 Skin Thường: Mặc tự nhiên\n• 5 Skin Hiếm / Sử Thi / Huyền Thoại: Có Hào Quang & Hạt 3D!"
	res_panel.add_child(_gacha_result_lbl)

	var w_hdr := Label.new()
	w_hdr.text = "❖ TỦ 10 TRANG PHỤC (Bấm ô đã mở khóa để MẶC NGAY)"
	w_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_hdr.add_theme_font_size_override("font_size", 14)
	w_hdr.modulate = Color(1.0, 0.86, 0.42)
	right_col.add_child(w_hdr)

	var ward_panel := _create_classical_panel(Color(0.09, 0.05, 0.05, 0.95), Color(0.82, 0.64, 0.28, 0.9))
	right_col.add_child(ward_panel)

	var ward_center := CenterContainer.new()
	ward_panel.add_child(ward_center)

	_gacha_wardrobe_grid = GridContainer.new()
	_gacha_wardrobe_grid.columns = 5
	_gacha_wardrobe_grid.add_theme_constant_override("h_separation", 8)
	_gacha_wardrobe_grid.add_theme_constant_override("v_separation", 8)
	ward_center.add_child(_gacha_wardrobe_grid)

	vbox.add_child(_create_button("ĐÓNG TỤ BẢO CÁC", func() -> void:
		if _gacha_wheel and _gacha_wheel.is_spinning:
			return
		if not main_menu_panel.visible:
			_hide_all_panels()
			get_tree().paused = false
		else:
			show_main_menu()
	))


func _perform_gacha_roll(count: int) -> void:
	if _gacha_wheel and _gacha_wheel.is_spinning:
		return
	var results := SaveManager.roll_skin_gacha(count)
	if results.is_empty():
		AudioManager.play_sfx("hurt", 0.9)
		return

	_pending_gacha_results = results
	# Nếu quay x5, cho vòng quay dừng đúng vào bộ Skin hiếm nhất vừa trúng!
	var highlight_res: Dictionary = results[0]
	for r in results:
		if bool(r["has_vfx"]):
			highlight_res = r

	if _gacha_btn_x1:
		_gacha_btn_x1.disabled = true
	if _gacha_btn_x5:
		_gacha_btn_x5.disabled = true
	if _gacha_result_lbl:
		_gacha_result_lbl.text = "✨ VÒNG QUAY ĐANG XOAY... ĐANG RÚT TRANG PHỤC CỔ TRANG! ✨"
		_gacha_result_lbl.modulate = Color(1.0, 0.88, 0.36)

	_gacha_wheel.start_spin_to(highlight_res)


func _on_gacha_wheel_finished(top_result: Dictionary) -> void:
	var lines: Array[String] = []
	for r in _pending_gacha_results:
		var st := "MỚI!" if bool(r["is_new"]) else ("Trùng +%d Lượng" % int(r["refund"]))
		var vfx_mark := " ✨VFX" if bool(r["has_vfx"]) else ""
		lines.append("• [%s] %s%s (%s)" % [str(r["rarity"]), str(r["name"]), vfx_mark, st])
	if _gacha_result_lbl:
		_gacha_result_lbl.text = "CHÚC MỪNG TRÚNG THƯỞNG!\n" + "\n".join(lines)
		_gacha_result_lbl.modulate = top_result.get("tag_color", Color(1.0, 0.90, 0.45))
	_refresh_gacha_ui()


func _refresh_gacha_ui() -> void:
	if _gacha_gold_lbl:
		var remain_pity: int = maxi(1, 5 - SaveManager.gacha_pity)
		_gacha_gold_lbl.text = "❖ NGÂN LƯỢNG: %d LƯỢNG   •   SƯU TẬP: %d / %d SKIN   •   Còn %d lượt chắc chắn nổ Skin Hiếm có VFX!" % [
			SaveManager.gold, SaveManager.owned_skins.size(), SaveManager.SKIN_CATALOG.size(), remain_pity
		]
	var spinning := _gacha_wheel != null and _gacha_wheel.is_spinning
	if _gacha_btn_x1:
		_gacha_btn_x1.disabled = spinning or SaveManager.gold < SaveManager.GACHA_COST_SINGLE
	if _gacha_btn_x5:
		_gacha_btn_x5.disabled = spinning or SaveManager.gold < SaveManager.GACHA_COST_MULTI

	if _gacha_wardrobe_grid == null:
		return
	for c in _gacha_wardrobe_grid.get_children():
		c.queue_free()

	for sid in SaveManager.SKIN_CATALOG.keys():
		var s_key: String = str(sid)
		var sk: Dictionary = SaveManager.SKIN_CATALOG[s_key]
		var owned: bool = SaveManager.owned_skins.has(s_key)
		var equipped: bool = (SaveManager.equipped_skin == s_key)
		var tex := PixelArtGenerator.get_hero_portrait_texture(SaveManager.equipped_scarf, s_key)
		var badge_txt := "★" if equipped else ("✨" if (owned and bool(sk["has_vfx"])) else ("🔒" if not owned else ""))
		var border_col: Color = sk["tag_color"] if owned else Color(0.35, 0.30, 0.28)
		var slot := _create_grid_slot_button(tex, badge_txt, border_col, equipped, func() -> void:
			if owned:
				SaveManager.equip_skin(s_key)
				AudioManager.play_sfx("pickup", 1.2)
				if _gacha_result_lbl:
					_gacha_result_lbl.text = "ĐÃ MẶC: [%s] %s\n%s" % [str(sk["rarity"]), str(sk["name"]), str(sk["desc"])]
					_gacha_result_lbl.modulate = sk["tag_color"]
				_refresh_gacha_ui()
			else:
				if _gacha_result_lbl:
					_gacha_result_lbl.text = "CHƯA MỞ KHÓA: [%s] %s\n%s" % [str(sk["rarity"]), str(sk["name"]), str(sk["desc"])]
					_gacha_result_lbl.modulate = Color(0.80, 0.76, 0.70)
		, 76)
		if not owned:
			slot.modulate = Color(0.52, 0.50, 0.54)
		_gacha_wardrobe_grid.add_child(slot)


## Helper: Tạo 1 ô vuông hiển thị hình ảnh vật phẩm/vũ khí/skin (dùng cho Rương 7x7, Shop & Tủ 10 Skin)
func _create_grid_slot_button(icon_tex: Texture2D, badge_text: String, border_col: Color, is_selected: bool, on_click: Callable, slot_px: int = 58) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(slot_px, slot_px)
	btn.pressed.connect(on_click)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.24, 0.14, 0.10, 0.96) if is_selected else Color(0.14, 0.09, 0.08, 0.94)
	var bw := 3 if is_selected else 2
	sb.border_width_left = bw
	sb.border_width_top = bw
	sb.border_width_right = bw
	sb.border_width_bottom = bw
	sb.border_color = Color(1.0, 0.92, 0.40) if is_selected else border_col
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4

	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.32, 0.18, 0.12, 0.98)
	hov.border_color = Color(1.0, 0.94, 0.55)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)

	var tex_rect := TextureRect.new()
	tex_rect.texture = icon_tex
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.offset_left = 6
	tex_rect.offset_top = 6
	tex_rect.offset_right = -6
	tex_rect.offset_bottom = -6
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tex_rect)

	if badge_text != "":
		var blbl := Label.new()
		blbl.text = badge_text
		blbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		blbl.offset_left = -36
		blbl.offset_top = -18
		blbl.offset_right = -3
		blbl.offset_bottom = -2
		blbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		blbl.add_theme_font_size_override("font_size", 11)
		blbl.modulate = Color(1.0, 0.92, 0.45)
		blbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(blbl)
	return btn


func _create_empty_grid_slot(slot_px: int = 58) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(slot_px, slot_px)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.05, 0.72)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.45, 0.34, 0.18, 0.55)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	p.add_theme_stylebox_override("panel", sb)
	return p


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
	if _hp_badge_lbl:
		_hp_badge_lbl.text = str(int(ceil(cur)))


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
	_on_boss_hp_changed(boss.current_hp, boss.max_hp, boss.stats.enemy_name, boss.boss_phase, boss.current_shield, boss.current_state == EnemyBase.State.BROKEN)


func _on_boss_hp_changed(cur: float, mx: float, b_name: String, phase: int, shield_pts: int = 0, is_broken: bool = false) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = mx
		boss_hp_bar.value = cur
	if boss_name_label:
		var phase_txt := "ĐỆ NHẤT CẢNH" if phase == 1 else ("ĐỆ NHỊ CẢNH" if phase == 2 else "CUỒNG NỘ CẢNH")
		var sh_txt := "💥 PHÁ GIÁP (x2 SÁT THƯƠNG)!" if is_broken else ("🛡 KHIÊN: %d" % shield_pts)
		boss_name_label.text = "【 %s • %s • %s (%d / %d) 】" % [b_name.to_upper(), phase_txt, sh_txt, int(ceil(cur)), int(mx)]
		boss_name_label.modulate = Color(1.0, 0.36, 0.24) if is_broken else Color(1.0, 0.78, 0.38)


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
