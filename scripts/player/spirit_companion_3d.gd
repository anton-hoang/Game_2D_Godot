class_name SpiritCompanion3D
extends Node3D
## Bạn Đồng Hành Linh Thú Cổ Trang (4 Linh Thú x 3 Cấp Tiến Hóa + Kỹ Năng Chủ Động [F / V]!):
## 1. Tiểu Hồ Ly (fox): Khiên Hộ Thân + 3 cầu hồ hỏa truy đuổi.
## 2. Tiên Hạc (crane): Hồi HP/MP lớn + Sóng gió đẩy lùi quái.
## 3. Tiểu Thanh Long (dragon — Gacha Sử Thi ★★): Long Tức Băng Phong 5 tia phá giáp!
## 4. Phượng Hoàng Lửa (phoenix — Gacha Huyền Thoại ★★★): Niết Bàn Hỏa Vũ 360° + Nội tại HỒI SINH 1 LẦN/MÀN!

signal pet_skill_cd_changed(remaining: float, total: float)

var owner_player: PlayerController
var pet_type: String = "fox"
var pet_level: int = 1

var anim_sprite: AnimatedSprite3D
var aura_light: OmniLight3D
var _evo_ring: MeshInstance3D
var _hover_time: float = 0.0
var _bolt_cd: float = 1.8
var _shield_cd: float = 0.0
var _active_skill_cd: float = 0.0
var _active_skill_max_cd: float = 12.0
var _phoenix_revive_used: bool = false
var _target_pickup: Node3D = null


func _ready() -> void:
	add_to_group("spirit_pet")
	_build_visuals()
	if not SaveManager.cosmetic_changed.is_connected(refresh_pet_appearance):
		SaveManager.cosmetic_changed.connect(refresh_pet_appearance)
	refresh_pet_appearance()


func _build_visuals() -> void:
	anim_sprite = AnimatedSprite3D.new()
	anim_sprite.name = "PetSprite3D"
	anim_sprite.pixel_size = 0.036
	anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	anim_sprite.shaded = false
	anim_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	anim_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anim_sprite)

	# Vòng hào quang 3D xoay quanh Linh Thú khi tiến hóa lên Cấp 2 & Cấp 3!
	_evo_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.48
	tm.outer_radius = 0.56
	_evo_ring.mesh = tm
	_evo_ring.position = Vector3(0.0, -0.25, 0.0)
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.albedo_color = Color(1.0, 0.85, 0.35, 0.80)
	rmat.emission_enabled = true
	rmat.emission = Color(1.0, 0.85, 0.35)
	rmat.emission_energy_multiplier = 3.2
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_evo_ring.material_override = rmat
	_evo_ring.visible = false
	add_child(_evo_ring)

	aura_light = OmniLight3D.new()
	aura_light.light_energy = 1.15
	aura_light.omni_range = 3.6
	aura_light.shadow_enabled = false
	add_child(aura_light)


func reset_stage_passives() -> void:
	_phoenix_revive_used = false
	_active_skill_cd = 0.0
	_shield_cd = 0.0
	pet_skill_cd_changed.emit(0.0, _active_skill_max_cd)


func refresh_pet_appearance() -> void:
	pet_type = SaveManager.equipped_pet
	pet_level = SaveManager.get_pet_level(pet_type)
	_active_skill_max_cd = 13.0 if pet_level == 1 else (10.5 if pet_level == 2 else 8.0)

	var pd: Dictionary = SaveManager.PET_CATALOG.get(pet_type, SaveManager.PET_CATALOG["fox"])
	var pcol: Color = pd.get("color", Color(1.0, 0.72, 0.80))

	if anim_sprite:
		anim_sprite.sprite_frames = PixelArtGenerator.get_pet_sprite_frames(pet_type, pet_level)
		anim_sprite.pixel_size = 0.036 if pet_level == 1 else (0.043 if pet_level == 2 else 0.050)
		anim_sprite.play("float")
	if aura_light:
		aura_light.light_color = pcol
		aura_light.light_energy = 1.05 + float(pet_level - 1) * 0.45
	if _evo_ring:
		_evo_ring.visible = (pet_level >= 2)
		_evo_ring.scale = Vector3.ONE * (0.95 if pet_level == 2 else 1.25)
		var rmat := _evo_ring.material_override as StandardMaterial3D
		if rmat:
			rmat.albedo_color = Color(pcol.r, pcol.g, pcol.b, 0.82)
			rmat.emission = pcol
			rmat.emission_energy_multiplier = 2.6 if pet_level == 2 else 4.2
	pet_skill_cd_changed.emit(_active_skill_cd, _active_skill_max_cd)


func _physics_process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return

	_hover_time += delta * 3.4
	if _evo_ring and _evo_ring.visible:
		_evo_ring.rotation.y += delta * (2.5 if pet_level == 2 else 4.0)
	if _bolt_cd > 0.0:
		_bolt_cd -= delta
	if _shield_cd > 0.0:
		_shield_cd -= delta
	if _active_skill_cd > 0.0:
		_active_skill_cd = maxf(0.0, _active_skill_cd - delta)
		pet_skill_cd_changed.emit(_active_skill_cd, _active_skill_max_cd)

	# KÍCH HOẠT KỸ NĂNG CHỦ ĐỘNG LINH THÚ BẰNG PHÍM [F] HOẶC [V]!
	if Input.is_action_just_pressed("pet_skill") and _active_skill_cd <= 0.0 and not owner_player._is_dead:
		_cast_active_pet_skill()

	# 1. Tự động bay nhặt Vàng / vật phẩm rơi quanh người chơi (tầm nhặt rộng hơn theo cấp tiến hóa!)
	var pickup_range: float = 8.5 + float(pet_level - 1) * 2.2
	if _target_pickup == null or not is_instance_valid(_target_pickup):
		_target_pickup = _find_nearest_pickup(pickup_range)

	var desired_pos: Vector3
	if _target_pickup and is_instance_valid(_target_pickup):
		desired_pos = _target_pickup.global_position + Vector3(0.0, 0.75, 0.0)
		global_position = global_position.lerp(desired_pos, clampf(10.0 * delta, 0.0, 1.0))
		if global_position.distance_to(_target_pickup.global_position) <= 1.25:
			_collect_pickup_for_player(_target_pickup)
			_target_pickup = null
	else:
		var side_x: float = -1.20 if owner_player.facing_dir.x >= 0.0 else 1.20
		desired_pos = owner_player.global_position + Vector3(
			side_x + cos(_hover_time * 0.7) * 0.25,
			1.62 + sin(_hover_time) * 0.22,
			-0.45 + sin(_hover_time * 0.6) * 0.25
		)
		global_position = global_position.lerp(desired_pos, clampf(5.5 * delta, 0.0, 1.0))

	if anim_sprite:
		var dx := desired_pos.x - global_position.x
		if absf(dx) > 0.08:
			anim_sprite.flip_h = dx < 0.0
		else:
			anim_sprite.flip_h = owner_player.anim_sprite.flip_h if owner_player.anim_sprite else false

	# 2. Hỗ trợ bắn Đạn Linh Khí mạnh dần theo cấp Tiến Hóa (1 -> 2 -> 3)
	if GameManager.is_stage_active and _bolt_cd <= 0.0:
		var enemy := _find_nearest_enemy(12.5)
		if enemy:
			_fire_spirit_bolt(enemy, 1.0)
			var pd: Dictionary = SaveManager.PET_CATALOG.get(pet_type, SaveManager.PET_CATALOG["fox"])
			var cds: Array = pd.get("bolt_cd", [2.2, 1.8, 1.4])
			_bolt_cd = float(cds[clampi(pet_level - 1, 0, cds.size() - 1)])

	# 3. Tự động tạo Lá Chắn bảo vệ khi Sinh Lực người chơi tụt xuống dưới 38%
	if GameManager.is_stage_active and _shield_cd <= 0.0 and not owner_player._is_dead:
		var hp_ratio := owner_player.current_hp / maxf(1.0, owner_player.max_hp)
		if hp_ratio > 0.0 and hp_ratio <= 0.38:
			_shield_cd = 20.0
			owner_player.activate_spirit_shield(5.0)
			var pname: String = SaveManager.get_pet_display_name(pet_type).to_upper()
			DamageNumber3D.spawn(get_parent(), owner_player.global_position + Vector3(0.0, 0.90, 0.0), 0, true, false, pname + ": HỘ THÂN THUẪN!")


## KỸ NĂNG CHỦ ĐỘNG RIÊNG CỦA 4 LINH THÚ (PHÍM [F] / [V])!
func _cast_active_pet_skill() -> void:
	_active_skill_cd = _active_skill_max_cd
	pet_skill_cd_changed.emit(_active_skill_cd, _active_skill_max_cd)

	var pd: Dictionary = SaveManager.PET_CATALOG.get(pet_type, SaveManager.PET_CATALOG["fox"])
	var pcol: Color = pd.get("color", Color.WHITE)
	var sname: String = str(pd.get("skill_name", "LINH THÚ KỸ"))
	AudioManager.play_sfx("special", 1.25)
	DamageNumber3D.spawn(get_parent(), global_position + Vector3(0.0, 0.85, 0.0), 0, true, false, "✦ " + sname.to_upper() + "! ✦")

	match pet_type:
		"dragon":
			# TIỂU THANH LONG: Long Tức Băng Phong — 5 tia Long Hỏa Băng Lam + Sóng Rồng Lam + Phá 1 Khiên!
			CombatVFX3D.spawn_skin_skill_vfx(get_parent(), owner_player.global_position, owner_player.facing_dir, "azure_dragon", pcol)
			var targets := _find_enemies_in_range(12.0)
			for i in range(5):
				var tgt: Node3D = targets[i % targets.size()] if targets.size() > 0 else null
				if tgt:
					_fire_spirit_bolt(tgt, 1.35)
				else:
					var deg: float = -30.0 + float(i) * 15.0
					var d := owner_player.facing_dir.rotated(Vector3.UP, deg_to_rad(deg)).normalized()
					_fire_spirit_bolt_dir(d, 1.35)
			for e in _find_enemies_in_range(5.2):
				if e.has_method("take_damage"):
					e.take_damage(int(round(owner_player.attack_damage * (1.2 + 0.45 * float(pet_level)))), Vector3.ZERO, true)
				if e.has_method("_damage_shield"):
					e._damage_shield(1)

		"phoenix":
			# PHƯỢNG HOÀNG LỬA: Niết Bàn Hỏa Vũ — Bùng nổ vòng lửa 360° thiêu đốt diện rộng + Hồi 25% HP!
			owner_player.heal(owner_player.max_hp * (0.22 + 0.05 * float(pet_level)))
			CombatVFX3D.spawn_shockwave_ring(get_parent(), owner_player.global_position, pcol, 0.7, 6.4, 0.48)
			CombatVFX3D.spawn_shockwave_ring(get_parent(), owner_player.global_position + Vector3(0, 0.4, 0), Color(1.0, 0.88, 0.30), 0.5, 4.8, 0.36)
			CombatVFX3D.spawn_hit_sparks(get_parent(), owner_player.global_position, Vector3.UP, pcol, 16)
			if owner_player.camera_rig:
				owner_player.camera_rig.shake(0.28, 0.20)
			var nova_dmg: int = int(round(owner_player.attack_damage * (2.0 + 0.65 * float(pet_level))))
			for e in _find_enemies_in_range(6.2):
				var push: Vector3 = (e.global_position - owner_player.global_position)
				push.y = 0.0
				push = push.normalized() if push.length() > 0.01 else Vector3.RIGHT
				if e.has_method("take_damage"):
					e.take_damage(nova_dmg, push * 13.0, true)
				if e.has_method("_damage_shield"):
					e._damage_shield(1)

		"crane":
			# TIÊN HẠC: Tiên Vũ Hồi Xuân — Hồi lớn HP + Chân Khí + Sóng gió ngọc bích đẩy văng quái!
			owner_player.heal(owner_player.max_hp * (0.28 + 0.07 * float(pet_level)))
			owner_player.add_energy(35.0 + 10.0 * float(pet_level - 1))
			CombatVFX3D.spawn_shockwave_ring(get_parent(), owner_player.global_position, pcol, 0.6, 5.5, 0.40)
			for e in _find_enemies_in_range(5.6):
				var push: Vector3 = (e.global_position - owner_player.global_position)
				push.y = 0.0
				push = push.normalized() if push.length() > 0.01 else Vector3.RIGHT
				if e.has_method("take_damage"):
					e.take_damage(int(round(owner_player.attack_damage * (1.0 + 0.35 * float(pet_level)))), push * 16.0, false)

		_: # "fox" — TIỂU HỒ LY: Hồ Ly Hộ Thuẫn — Khiên 5.5s + Hồi HP + 3 cầu hồ hỏa truy đuổi!
			owner_player.activate_spirit_shield(5.5 + float(pet_level - 1) * 0.8)
			owner_player.heal(owner_player.max_hp * (0.16 + 0.05 * float(pet_level)))
			CombatVFX3D.spawn_shockwave_ring(get_parent(), owner_player.global_position, pcol, 0.5, 4.4, 0.36)
			var targets := _find_enemies_in_range(12.0)
			for i in range(3):
				var tgt: Node3D = targets[i % targets.size()] if targets.size() > 0 else null
				if tgt:
					_fire_spirit_bolt(tgt, 1.30)


## NỘI TẠI BẤT TỬ CỦA PHƯỢNG HOÀNG LỬA: Hồi sinh người chơi 1 lần mỗi màn khi cạn máu!
func try_phoenix_revive() -> bool:
	if pet_type != "phoenix" or _phoenix_revive_used or owner_player == null:
		return false
	_phoenix_revive_used = true
	var revive_ratio: float = 0.55 if pet_level < 3 else 0.78
	owner_player.current_hp = owner_player.max_hp * revive_ratio
	owner_player.hp_changed.emit(owner_player.current_hp, owner_player.max_hp)
	owner_player._invuln_timer = 3.0
	owner_player.activate_spirit_shield(4.5)
	AudioManager.play_sfx("victory", 1.25)
	GameManager.trigger_hit_stop(0.10, 0.08)
	if owner_player.camera_rig:
		owner_player.camera_rig.shake(0.38, 0.28)
	CombatVFX3D.spawn_skin_skill_vfx(get_parent(), owner_player.global_position, Vector3.RIGHT, "golden_pillars", Color(1.0, 0.56, 0.16))
	DamageNumber3D.spawn(get_parent(), owner_player.global_position + Vector3(0.0, 1.1, 0.0), 0, true, false, "✦ PHƯỢNG HOÀNG NIẾT BÀN — HỒI SINH! ✦")
	for e in _find_enemies_in_range(6.8):
		var push: Vector3 = (e.global_position - owner_player.global_position)
		push.y = 0.0
		push = push.normalized() if push.length() > 0.01 else Vector3.RIGHT
		if e.has_method("take_damage"):
			e.take_damage(int(round(owner_player.attack_damage * 2.6)), push * 18.0, true)
	return true


func _find_nearest_pickup(max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for p in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(p):
			continue
		var d := owner_player.global_position.distance_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p as Node3D
	return best


func _collect_pickup_for_player(pickup: Node3D) -> void:
	if pickup and is_instance_valid(pickup) and pickup.has_method("collect_by"):
		pickup.collect_by(owner_player)


func _find_nearest_enemy(max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e as Node3D
	return best


func _find_enemies_in_range(max_dist: float) -> Array[Node3D]:
	var list: Array[Node3D] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e is Node3D:
			var n3 := e as Node3D
			if owner_player.global_position.distance_to(n3.global_position) <= max_dist:
				list.append(n3)
	return list


func _fire_spirit_bolt(enemy: Node3D, power_mult: float = 1.0) -> void:
	if get_parent() == null:
		return
	var to_e := (enemy.global_position + Vector3(0.0, 0.85, 0.0)) - global_position
	var dir := to_e.normalized() if to_e.length() > 0.01 else Vector3.RIGHT
	_spawn_bolt(enemy, dir, power_mult)


func _fire_spirit_bolt_dir(dir: Vector3, power_mult: float = 1.0) -> void:
	_spawn_bolt(null, dir, power_mult)


func _spawn_bolt(enemy: Node3D, dir: Vector3, power_mult: float) -> void:
	if get_parent() == null:
		return
	var pd: Dictionary = SaveManager.PET_CATALOG.get(pet_type, SaveManager.PET_CATALOG["fox"])
	var dmg_arr: Array = pd.get("dmg_mult", [0.68, 1.0, 1.4])
	var lv_mult: float = float(dmg_arr[clampi(pet_level - 1, 0, dmg_arr.size() - 1)])
	var bolt := SpiritBolt3D.new()
	bolt.target_enemy = enemy
	bolt.direction = dir
	bolt.damage = int(round(owner_player.attack_damage * lv_mult * power_mult))
	bolt.bolt_color = pd.get("color", Color(1.0, 0.48, 0.72))
	get_parent().add_child(bolt)
	bolt.global_position = global_position
	AudioManager.play_sfx("pickup", 1.35)
