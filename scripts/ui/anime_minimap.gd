class_name AnimeMinimap
extends Control
## Minimap tròn phong cách Tiên Hiệp / Anime Fantasy RPG:
## - Nền địa hình vẽ phong cách hoa anh đào + hồ nước xanh + quảng trường đá.
## - Viền kim loại vàng đồng kép có 4 khấc Đông-Tây-Nam-Bắc.
## - Hiển thị thời gian thực vị trí Người chơi (sao vàng), NPC (xanh lá), Cổng (xanh lam/tím), Quái (đỏ) và Boss (vàng đỏ).

var location_name: String = "Thành Trấn"
var _loc_label: Label
var _coord_label: Label
var _pulse_t: float = 0.0
var _player_world_pos: Vector3 = Vector3.ZERO
var _npc_points: Array[Vector2] = []
var _portal_points: Array[Vector2] = []
var _enemy_points: Array[Vector2] = []
var _boss_points: Array[Vector2] = []
var _scan_timer: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(108, 138)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_loc_label = Label.new()
	_loc_label.position = Vector2(-8, 98)
	_loc_label.custom_minimum_size = Vector2(124, 20)
	_loc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loc_label.add_theme_font_size_override("font_size", 13)
	_loc_label.add_theme_constant_override("outline_size", 4)
	_loc_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08, 0.96))
	_loc_label.modulate = Color(1.0, 0.94, 0.72)
	_loc_label.text = location_name
	_loc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loc_label)

	_coord_label = Label.new()
	_coord_label.position = Vector2(-8, 116)
	_coord_label.custom_minimum_size = Vector2(124, 18)
	_coord_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coord_label.add_theme_font_size_override("font_size", 11)
	_coord_label.add_theme_constant_override("outline_size", 3)
	_coord_label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.07, 0.95))
	_coord_label.modulate = Color(0.94, 0.92, 0.98)
	_coord_label.text = "(128, 64)"
	_coord_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_coord_label)


func set_location_name(loc: String) -> void:
	location_name = loc
	if _loc_label:
		_loc_label.text = loc


func _process(delta: float) -> void:
	_pulse_t += delta * 3.0
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 0.14
		_refresh_radar_points()
	queue_redraw()


func _world_to_radar(wpos: Vector3, center: Vector2, rad: float) -> Vector2:
	# Quy đổi tọa độ đấu trường/làng (-22..22, -16..10) về vòng tròn radar gọn đẹp
	var nx: float = clampf(wpos.x / 22.0, -0.82, 0.82)
	var nz: float = clampf((wpos.z + 2.0) / 14.0, -0.82, 0.82)
	var v := Vector2(nx, nz)
	if v.length() > 0.84:
		v = v.normalized() * 0.84
	return center + v * rad


func _refresh_radar_points() -> void:
	_npc_points.clear()
	_portal_points.clear()
	_enemy_points.clear()
	_boss_points.clear()

	var tree := get_tree()
	if tree == null:
		return

	var p := tree.get_first_node_in_group("player") as Node3D
	if p and is_instance_valid(p):
		_player_world_pos = p.global_position
		if _coord_label:
			var gx: int = 128 + int(round(_player_world_pos.x * 2.0))
			var gz: int = 64 + int(round(_player_world_pos.z * 2.0))
			_coord_label.text = "(%d, %d)" % [gx, gz]

	var center := Vector2(54.0, 48.0)
	var rad: float = 41.0

	for e in tree.get_nodes_in_group("enemies"):
		var en := e as EnemyBase
		if en and is_instance_valid(en) and en.current_state != EnemyBase.State.DIE:
			var pt: Vector2 = _world_to_radar(en.global_position, center, rad)
			if en.stats and en.stats.archetype == "boss":
				_boss_points.append(pt)
			else:
				_enemy_points.append(pt)

	# Quét NPC & Cổng dịch chuyển khi đang ở Làng Windferry
	var stage_mgr := tree.root.find_child("StageManager", true, false) as StageManager
	if stage_mgr:
		if stage_mgr.is_in_town_hub:
			if stage_mgr.town_npcs_root and stage_mgr.town_npcs_root.visible:
				for child in stage_mgr.town_npcs_root.get_children():
					if child is Node3D and (child as Node3D).visible:
						_npc_points.append(_world_to_radar((child as Node3D).global_position, center, rad))
		if stage_mgr.wave_portal and stage_mgr.wave_portal.visible:
			_portal_points.append(_world_to_radar(stage_mgr.wave_portal.global_position, center, rad))
		if stage_mgr.tower_portal and stage_mgr.tower_portal.visible:
			_portal_points.append(_world_to_radar(stage_mgr.tower_portal.global_position, center, rad))


func _draw() -> void:
	var c := Vector2(54.0, 48.0)
	var r: float = 44.0

	# 1. Đổ bóng mềm & Nền bản đồ tròn tông tím hoàng hôn + mảng xanh hồ & tán hoa anh đào hồng
	draw_circle(c + Vector2(0, 3), r + 3.5, Color(0.0, 0.0, 0.0, 0.55))
	draw_circle(c, r, Color(0.14, 0.16, 0.28, 0.94))

	# Quảng trường đá ở giữa radar
	draw_circle(c + Vector2(4, 3), r * 0.56, Color(0.36, 0.34, 0.46, 0.72))
	# Mặt hồ sen xanh lam phía trái dưới
	draw_circle(c + Vector2(-18, 12), r * 0.36, Color(0.14, 0.38, 0.58, 0.85))
	# Cụm tán hoa anh đào hồng mềm mại dọc rìa trên & hai bên giống hệt minimap ảnh mẫu
	var sakura_spots: Array[Vector2] = [
		Vector2(-24, -18), Vector2(-14, -26), Vector2(-28, -4),
		Vector2(20, -22), Vector2(28, -8), Vector2(18, 22),
	]
	for sp: Vector2 in sakura_spots:
		draw_circle(c + sp, 9.5, Color(0.92, 0.48, 0.72, 0.42))
		draw_circle(c + sp + Vector2(-2, -2), 5.5, Color(1.0, 0.72, 0.86, 0.48))

	# Lưới kinh vĩ mờ tinh tế
	draw_line(c + Vector2(-r + 4, 0), c + Vector2(r - 4, 0), Color(0.92, 0.84, 0.62, 0.16), 1.0, true)
	draw_line(c + Vector2(0, -r + 4), c + Vector2(0, r - 4), Color(0.92, 0.84, 0.62, 0.16), 1.0, true)
	draw_arc(c, r * 0.54, 0.0, TAU, 36, Color(0.92, 0.84, 0.62, 0.18), 1.0, true)

	# 2. Chấm NPC (xanh ngọc), Cổng dịch chuyển (xanh lam phát sáng), Quái (đỏ), Boss (vàng đỏ)
	for np: Vector2 in _npc_points:
		draw_circle(np, 3.2, Color(0.34, 0.96, 0.62, 0.95))
	for pp: Vector2 in _portal_points:
		var p_rad: float = 4.2 + sin(_pulse_t * 1.4) * 1.1
		draw_circle(pp, p_rad + 2.0, Color(0.28, 0.80, 1.0, 0.35))
		draw_circle(pp, p_rad, Color(0.45, 0.92, 1.0, 0.98))
	for ep: Vector2 in _enemy_points:
		draw_circle(ep, 3.2, Color(1.0, 0.26, 0.32, 0.96))
	for bp: Vector2 in _boss_points:
		draw_circle(bp, 6.2, Color(1.0, 0.22, 0.28, 0.40))
		draw_circle(bp, 4.2, Color(1.0, 0.86, 0.26, 1.0))

	# 3. Mũi tên vàng đánh dấu Nhân vật
	var p_pt: Vector2 = _world_to_radar(_player_world_pos, c, 41.0)
	var arrow := PackedVector2Array([
		p_pt + Vector2(0, -6.5),
		p_pt + Vector2(4.8, 4.5),
		p_pt + Vector2(0, 2.0),
		p_pt + Vector2(-4.8, 4.5),
	])
	draw_colored_polygon(arrow, Color(1.0, 0.92, 0.32))
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[0]]), Color(0.18, 0.10, 0.04, 0.95), 1.2, true)

	# 4. Vành tròn vàng đồng chạm khắc kép + 4 viên chấm vàng 4 hướng
	draw_arc(c, r + 1.5, 0.0, TAU, 56, Color(0.18, 0.11, 0.06, 0.96), 4.5, true)
	draw_arc(c, r + 0.5, 0.0, TAU, 56, Color(0.95, 0.78, 0.38, 0.98), 2.4, true)
	draw_arc(c, r - 2.2, 0.0, TAU, 56, Color(0.56, 0.40, 0.18, 0.80), 1.0, true)

	var ticks: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	for d: Vector2 in ticks:
		draw_circle(c + d * (r + 0.5), 3.0, Color(1.0, 0.88, 0.46, 0.98))
