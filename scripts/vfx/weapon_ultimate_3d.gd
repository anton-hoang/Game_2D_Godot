class_name WeaponUltimate3D
extends Node3D
## Hệ thống 4 CHIÊU CUỐI (ULTIMATE SKILL — Phím U / R) 3D điện ảnh riêng biệt cho từng loại vũ khí:
## 1. KIẾM (sword)    -> VẠN KIẾM QUY TÔNG: 16 thanh Linh Kiếm khổng lồ treo lơ lửng rồi lao cắm liên hoàn xuống đầu quái!
## 2. ĐẠI ĐAO (saber) -> BÁ VƯƠNG PHÁ THIÊN TRẢM: 3 luồng Đao Khí Hỏa Viêm khổng lồ chẻ thẳng 13m + chuỗi nổ dung nham phá tan 3 giáp!
## 3. CUNG TÊN (bow)  -> CỬU THIÊN HỎA VŨ TIỄN: Bắn tiễn lên trời gọi cơn mưa 24 mũi Thần Tiễn Phượng Hoàng oanh tạc!
## 4. GẬY PHÉP (staff)-> THÁI CỰC THIÊN LÔI TRẬN: Đại Pháp Trận 3D xoay tròn hút quái vào tâm + 9 cột Thiên Lôi giáng xuống + Siêu Tân Tinh!


static func launch(parent: Node, player: PlayerController, weapon_type: String, facing_dir: Vector3, base_dmg: float, accent_col: Color) -> void:
	if parent == null or not is_instance_valid(parent) or player == null:
		return
	var runner := WeaponUltimate3D.new()
	parent.add_child(runner)
	runner.global_position = player.global_position
	var dir := facing_dir.normalized() if facing_dir.length_squared() > 0.01 else Vector3.RIGHT
	match weapon_type:
		"saber":
			runner._run_saber_ultimate(parent, player, dir, base_dmg, accent_col)
		"bow":
			runner._run_bow_ultimate(parent, player, dir, base_dmg, accent_col)
		"staff":
			runner._run_staff_ultimate(parent, player, base_dmg, accent_col)
		_:
			runner._run_sword_ultimate(parent, player, base_dmg, accent_col)


## ============================================================================
## 1. CHIÊU CUỐI KIẾM: VẠN KIẾM QUY TÔNG (16 Linh Kiếm Khổng Lồ Từ Trời Giáng!)
## ============================================================================
func _run_sword_ultimate(world: Node, player: PlayerController, base_dmg: float, col: Color) -> void:
	var origin: Vector3 = player.global_position
	CombatVFX3D.spawn_shockwave_ring(world, origin, col, 0.8, 6.2, 0.55)
	if player.camera_rig:
		player.camera_rig.shake(0.32, 0.25)

	# Tìm các mục tiêu đang sống quanh nhân vật để khóa kiếm rơi trúng đầu
	var targets: Array[Vector3] = _collect_enemy_positions(origin, 11.0)
	var sword_positions: Array[Vector3] = []
	for i in range(16):
		if targets.size() > 0 and i < 10:
			var tpos: Vector3 = targets[i % targets.size()]
			sword_positions.append(tpos + Vector3(randf_range(-0.9, 0.9), 0.0, randf_range(-0.9, 0.9)))
		else:
			var ang: float = (TAU / 16.0) * float(i) + randf_range(-0.15, 0.15)
			var dist: float = randf_range(2.2, 6.2)
			sword_positions.append(origin + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist))

	var blade_mat := _make_glow_mat(col, 4.6)
	var hilt_mat := _make_glow_mat(Color(1.0, 0.84, 0.28), 3.0)

	for i in range(sword_positions.size()):
		var dst: Vector3 = sword_positions[i]
		var sw := Node3D.new()
		world.add_child(sw)
		sw.global_position = dst + Vector3(0.0, 6.8 + randf_range(0.0, 1.4), 0.0)

		# Lưỡi linh kiếm sắc nhọn chúc thẳng xuống đất
		var blade := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.18, 2.35, 0.08)
		blade.mesh = bm
		blade.material_override = blade_mat
		sw.add_child(blade)

		var guard := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.72, 0.14, 0.16)
		guard.mesh = gm
		guard.position = Vector3(0.0, 1.05, 0.0)
		guard.material_override = hilt_mat
		sw.add_child(guard)

		var delay_sec: float = 0.12 + float(i) * 0.055
		var tw := sw.create_tween()
		tw.tween_interval(delay_sec)
		tw.tween_property(sw, "global_position:y", dst.y + 0.95, 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			if not is_instance_valid(world):
				return
			AudioManager.play_sfx("slash", 1.15 + randf_range(-0.12, 0.18))
			CombatVFX3D.spawn_shockwave_ring(world, dst, col, 0.3, 2.4, 0.25)
			CombatVFX3D.spawn_hit_sparks(world, dst, Vector3.UP, col, 6)
			_aoe_damage(world, dst, 2.55, base_dmg * 1.18, 6.5, true, 1)
		)
		tw.tween_interval(0.32)
		tw.tween_property(sw, "scale", Vector3(0.05, 1.4, 0.05), 0.22)
		tw.tween_callback(sw.queue_free)

	await get_tree().create_timer(1.85).timeout
	queue_free()


## ============================================================================
## 2. CHIÊU CUỐI ĐẠI ĐAO: BÁ VƯƠNG PHÁ THIÊN TRẢM (3 Luồng Đao Khí Chẻ Đất 13m!)
## ============================================================================
func _run_saber_ultimate(world: Node, player: PlayerController, dir: Vector3, base_dmg: float, col: Color) -> void:
	var origin: Vector3 = player.global_position
	var fire_col: Color = Color(1.0, 0.36, 0.12)
	var gold_col: Color = Color(1.0, 0.84, 0.26)
	CombatVFX3D.spawn_shockwave_ring(world, origin, fire_col, 0.7, 5.2, 0.42)

	for wave_i in range(3):
		if not is_instance_valid(world):
			break
		AudioManager.play_sfx("special", 0.72 + float(wave_i) * 0.10)
		if is_instance_valid(player) and player.camera_rig:
			player.camera_rig.shake(0.36, 0.22)

		var yaw_deg: float = 0.0 if wave_i == 0 else (-16.0 if wave_i == 1 else 16.0)
		var wave_dir: Vector3 = dir.rotated(Vector3.UP, deg_to_rad(yaw_deg)).normalized()
		var slash_mesh := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 2.6 + float(wave_i) * 0.35
		sm.bottom_radius = 2.6 + float(wave_i) * 0.35
		sm.height = 0.26
		slash_mesh.mesh = sm
		slash_mesh.material_override = _make_glow_mat(fire_col if wave_i != 2 else gold_col, 5.0)
		world.add_child(slash_mesh)
		slash_mesh.global_position = origin + wave_dir * 1.2 + Vector3(0.0, 1.05, 0.0)
		slash_mesh.scale = Vector3(1.15, 1.0, 0.38)
		slash_mesh.look_at(slash_mesh.global_position + wave_dir, Vector3.UP)

		var end_pos: Vector3 = origin + wave_dir * 13.0 + Vector3(0.0, 1.05, 0.0)
		var tw := slash_mesh.create_tween()
		tw.set_parallel(true)
		tw.tween_property(slash_mesh, "global_position", end_pos, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(slash_mesh, "scale", Vector3(2.0, 0.35, 0.75), 0.48)
		tw.chain().tween_callback(slash_mesh.queue_free)

		# Chuỗi vụ nổ nứt đất dọc đường chém 13m + phá tan 3 tầng Khiên Giáp!
		for step_k in range(1, 7):
			var pt: Vector3 = origin + wave_dir * (float(step_k) * 2.05)
			var dmg_mult: float = 1.65 if wave_i == 0 else 1.25
			var shield_hit: int = 2 if wave_i == 0 else 1
			var delay_k: float = float(step_k) * 0.055
			var timer_k := get_tree().create_timer(delay_k)
			timer_k.timeout.connect(func() -> void:
				if not is_instance_valid(world):
					return
				CombatVFX3D.spawn_shockwave_ring(world, pt, fire_col, 0.4, 2.8, 0.28)
				CombatVFX3D.spawn_hit_sparks(world, pt, wave_dir, gold_col, 8)
				_aoe_damage(world, pt, 2.75, base_dmg * dmg_mult, 19.0, true, shield_hit, wave_dir)
			)

		await get_tree().create_timer(0.24).timeout

	await get_tree().create_timer(0.8).timeout
	queue_free()


## ============================================================================
## 3. CHIÊU CUỐI CUNG TÊN: CỬU THIÊN HỎA VŨ TIỄN (Mưa 24 Thần Tiễn Phượng Hoàng!)
## ============================================================================
func _run_bow_ultimate(world: Node, player: PlayerController, dir: Vector3, base_dmg: float, col: Color) -> void:
	var origin: Vector3 = player.global_position
	var fire_gold: Color = Color(1.0, 0.68, 0.20)
	var arrow_mat := _make_glow_mat(fire_gold, 5.2)

	# Bước 1: Bắn 5 mũi tên rực sáng vút thẳng lên bầu trời!
	AudioManager.play_sfx("dash", 1.45)
	CombatVFX3D.spawn_shockwave_ring(world, origin, fire_gold, 0.5, 3.8, 0.35)
	for s in range(5):
		var up_ar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.10, 1.35, 0.10)
		up_ar.mesh = bm
		up_ar.material_override = arrow_mat
		world.add_child(up_ar)
		up_ar.global_position = origin + Vector3(randf_range(-0.5, 0.5), 1.3, randf_range(-0.5, 0.5))
		var tw_u := up_ar.create_tween()
		tw_u.tween_property(up_ar, "global_position:y", origin.y + 13.5, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_u.tween_callback(up_ar.queue_free)

	# Xác định tâm vùng oanh tạc (ưu tiên cụm quái phía trước, không thì cách trước mặt 5.5m)
	var zone_center: Vector3 = origin + dir * 5.5
	var targets: Array[Vector3] = _collect_enemy_positions(origin, 12.5)
	if targets.size() > 0:
		zone_center = targets[0]

	# Vòng mục tiêu rực lửa cảnh báo dưới mặt đất
	CombatVFX3D.spawn_shockwave_ring(world, zone_center, fire_gold, 1.2, 5.4, 1.45)

	await get_tree().create_timer(0.24).timeout
	if not is_instance_valid(world):
		queue_free()
		return

	# Bước 2: Giáng 24 mũi Thần Tiễn rực lửa xéo từ bầu trời xuống khắp vùng oanh tạc!
	for i in range(24):
		if not is_instance_valid(world):
			break
		var ang: float = randf_range(0.0, TAU)
		var rad: float = sqrt(randf()) * 4.8
		var dst: Vector3 = zone_center + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		if targets.size() > 0 and i % 3 == 0:
			var tp: Vector3 = targets[(i / 3) % targets.size()]
			dst = tp + Vector3(randf_range(-0.7, 0.7), 0.0, randf_range(-0.7, 0.7))

		var start_p: Vector3 = dst + Vector3(-dir.x * 3.2, 11.0, -dir.z * 3.2)
		var ar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.11, 0.11, 1.75)
		ar.mesh = bm
		ar.material_override = arrow_mat
		world.add_child(ar)
		ar.global_position = start_p
		ar.look_at(dst, Vector3.UP)

		var tw := ar.create_tween()
		tw.tween_property(ar, "global_position", dst + Vector3(0.0, 0.25, 0.0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			if not is_instance_valid(world):
				return
			if i % 3 == 0:
				AudioManager.play_sfx("hit", 1.15 + randf_range(-0.1, 0.2))
			CombatVFX3D.spawn_shockwave_ring(world, dst, col if (i % 2 == 0) else fire_gold, 0.25, 1.9, 0.22)
			CombatVFX3D.spawn_hit_sparks(world, dst, Vector3.UP, fire_gold, 5)
			_aoe_damage(world, dst, 2.35, base_dmg * 0.92, 5.5, true, 1 if (i % 4 == 0) else 0)
		)
		tw.tween_interval(0.15)
		tw.tween_callback(ar.queue_free)
		await get_tree().create_timer(0.055).timeout

	await get_tree().create_timer(0.55).timeout
	queue_free()


## ============================================================================
## 4. CHIÊU CUỐI GẬY PHÉP: THÁI CỰC THIÊN LÔI TRẬN (Đại Pháp Trận + 9 Thiên Lôi!)
## ============================================================================
func _run_staff_ultimate(world: Node, player: PlayerController, base_dmg: float, col: Color) -> void:
	var origin: Vector3 = player.global_position
	var violet_col: Color = Color(0.76, 0.42, 1.0)
	var cyan_col: Color = Color(0.45, 0.92, 1.0)

	# Dựng Đại Pháp Trận 2 vòng đồng tâm khổng lồ xoay rực sáng dưới đất!
	var circle_root := Node3D.new()
	world.add_child(circle_root)
	circle_root.global_position = origin + Vector3(0.0, 0.14, 0.0)

	var outer_ring := MeshInstance3D.new()
	var otm := TorusMesh.new()
	otm.inner_radius = 5.6
	otm.outer_radius = 6.1
	outer_ring.mesh = otm
	outer_ring.material_override = _make_glow_mat(violet_col, 4.2)
	circle_root.add_child(outer_ring)

	var inner_ring := MeshInstance3D.new()
	var itm := TorusMesh.new()
	itm.inner_radius = 3.1
	itm.outer_radius = 3.45
	inner_ring.mesh = itm
	inner_ring.material_override = _make_glow_mat(cyan_col, 4.5)
	circle_root.add_child(inner_ring)

	var rot_tw := circle_root.create_tween()
	rot_tw.tween_property(circle_root, "rotation:y", TAU * 1.5, 1.65)

	AudioManager.play_sfx("special", 1.25)
	if player.camera_rig:
		player.camera_rig.shake(0.28, 0.25)

	# Liên tiếp giáng 9 Cột Thiên Lôi từ bầu trời đánh thẳng vào quái trong trận pháp!
	for bolt_i in range(9):
		if not is_instance_valid(world):
			break
		# Hút nhẹ quái vật trong vòng 7.2m vào tâm Pháp Trận!
		_pull_enemies_toward(origin, 7.2, 1.25)

		var targets: Array[Vector3] = _collect_enemy_positions(origin, 7.5)
		var dst: Vector3 = origin + Vector3(cos(float(bolt_i) * 0.72) * 3.4, 0.0, sin(float(bolt_i) * 0.72) * 3.4)
		if targets.size() > 0:
			dst = targets[bolt_i % targets.size()]

		var bolt := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.24
		cm.bottom_radius = 0.52
		cm.height = 12.5
		bolt.mesh = cm
		bolt.material_override = _make_glow_mat(cyan_col if (bolt_i % 2 == 0) else violet_col, 5.5)
		world.add_child(bolt)
		bolt.global_position = dst + Vector3(0.0, 6.25, 0.0)

		AudioManager.play_sfx("special", 1.4 + randf_range(-0.1, 0.2))
		CombatVFX3D.spawn_shockwave_ring(world, dst, cyan_col, 0.4, 2.8, 0.28)
		CombatVFX3D.spawn_hit_sparks(world, dst, Vector3.UP, violet_col, 7)
		_aoe_damage(world, dst, 2.8, base_dmg * 1.25, 4.0, true, 1 if (bolt_i % 3 == 0) else 0)

		var btw := bolt.create_tween()
		btw.tween_property(bolt, "scale", Vector3(0.06, 1.0, 0.06), 0.24)
		btw.tween_callback(bolt.queue_free)
		await get_tree().create_timer(0.14).timeout

	# Kết thúc bằng VỤ NỔ SIÊU TÂN TINH toàn bộ Đại Pháp Trận!
	if is_instance_valid(world):
		AudioManager.play_sfx("victory", 0.85)
		if is_instance_valid(player) and player.camera_rig:
			player.camera_rig.shake(0.42, 0.30)
		CombatVFX3D.spawn_shockwave_ring(world, origin, violet_col, 0.9, 7.6, 0.52)
		CombatVFX3D.spawn_shockwave_ring(world, origin + Vector3(0, 0.4, 0), col, 0.6, 6.2, 0.42)
		_aoe_damage(world, origin, 6.8, base_dmg * 2.45, 16.0, true, 2)

	if is_instance_valid(circle_root):
		var ctw := circle_root.create_tween()
		ctw.tween_property(circle_root, "scale", Vector3(1.3, 0.05, 1.3), 0.28)
		ctw.tween_callback(circle_root.queue_free)

	await get_tree().create_timer(0.5).timeout
	queue_free()


func _collect_enemy_positions(origin: Vector3, max_radius: float) -> Array[Vector3]:
	var list: Array[Vector3] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is Node3D and node.has_method("take_damage"):
			var pos: Vector3 = (node as Node3D).global_position
			if pos.distance_to(origin) <= max_radius:
				list.append(pos)
	return list


func _pull_enemies_toward(center: Vector3, radius: float, pull_dist: float) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is Node3D:
			var n3 := node as Node3D
			var diff: Vector3 = center - n3.global_position
			diff.y = 0.0
			var d: float = diff.length()
			if d > 1.2 and d <= radius:
				n3.global_position += diff.normalized() * minf(pull_dist, d - 1.0)


func _aoe_damage(world: Node, center: Vector3, radius: float, dmg: float, knock_force: float, is_crit: bool, extra_shield: int = 0, forced_dir: Vector3 = Vector3.ZERO) -> void:
	if not is_instance_valid(world):
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node.has_method("take_damage"):
			continue
		var diff: Vector3 = (node as Node3D).global_position - center
		diff.y = 0.0
		if diff.length() <= radius:
			var kdir: Vector3 = forced_dir if forced_dir.length_squared() > 0.01 else (diff.normalized() if diff.length() > 0.01 else Vector3.RIGHT)
			var final_dmg: int = int(round(dmg * randf_range(0.95, 1.12)))
			node.take_damage(final_dmg, kdir * knock_force, is_crit)
			if extra_shield > 0 and node.has_method("_damage_shield"):
				node._damage_shield(extra_shield)
	for br in get_tree().get_nodes_in_group("breakables"):
		if is_instance_valid(br) and br.has_method("take_damage"):
			var dbr: Vector3 = (br as Node3D).global_position - center
			dbr.y = 0.0
			if dbr.length() <= radius + 0.5:
				br.take_damage(int(round(dmg)))


func _make_glow_mat(col: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(col.r, col.g, col.b, 0.88)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
