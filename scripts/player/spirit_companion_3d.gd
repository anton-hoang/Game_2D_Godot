class_name SpiritCompanion3D
extends Node3D
## Bạn Đồng Hành Linh Thú Cổ Trang (Tiểu Hồ Ly Bạch Tuyết / Tiên Hạc Trắng):
## 1. Bay lượn uyển chuyển bên vai cô bé Lữ Khách với ánh hào quang ấm áp.
## 2. Tự động bay đi nhặt Vàng rơi (và hút vật phẩm về) trong phạm vi rộng quanh người chơi.
## 3. Cứ mỗi ~2.6 giây tự động bắn Đạn Linh Khí (SpiritBolt3D) truy đuổi hỗ trợ đánh quái.
## 4. Khi Sinh Lực người chơi tụt xuống dưới 38% -> Tự động triệu hồi Lá Chắn Linh Khí bảo vệ (hồi chiêu 20s)!

var owner_player: PlayerController
var pet_type: String = "fox" # "fox" (Tiểu Hồ Ly) | "crane" (Tiên Hạc)

var anim_sprite: AnimatedSprite3D
var aura_light: OmniLight3D
var _hover_time: float = 0.0
var _bolt_cd: float = 2.0
var _shield_cd: float = 0.0
var _target_pickup: Node3D = null


func _ready() -> void:
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

	aura_light = OmniLight3D.new()
	aura_light.light_energy = 1.15
	aura_light.omni_range = 3.2
	add_child(aura_light)


func refresh_pet_appearance() -> void:
	pet_type = SaveManager.equipped_pet
	if anim_sprite:
		anim_sprite.sprite_frames = PixelArtGenerator.get_pet_sprite_frames(pet_type)
		anim_sprite.play("float")
	if aura_light:
		aura_light.light_color = Color(1.0, 0.72, 0.80) if pet_type == "fox" else Color(0.45, 0.96, 0.88)


func _physics_process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return

	_hover_time += delta * 3.4
	if _bolt_cd > 0.0:
		_bolt_cd -= delta
	if _shield_cd > 0.0:
		_shield_cd -= delta

	# 1. Tìm đồng Vàng / vật phẩm rơi quanh người chơi để bay tới tự động nhặt hộ!
	if _target_pickup == null or not is_instance_valid(_target_pickup):
		_target_pickup = _find_nearest_pickup(8.5)

	var desired_pos: Vector3
	if _target_pickup and is_instance_valid(_target_pickup):
		desired_pos = _target_pickup.global_position + Vector3(0.0, 0.75, 0.0)
		global_position = global_position.lerp(desired_pos, clampf(9.5 * delta, 0.0, 1.0))
		if global_position.distance_to(_target_pickup.global_position) <= 1.25:
			_collect_pickup_for_player(_target_pickup)
			_target_pickup = null
	else:
		# Bay lượn nhẹ bên vai sau lưng cô bé Lữ Khách
		var side_x: float = -1.15 if owner_player.facing_dir.x >= 0.0 else 1.15
		desired_pos = owner_player.global_position + Vector3(
			side_x + cos(_hover_time * 0.7) * 0.25,
			1.55 + sin(_hover_time) * 0.22,
			-0.45 + sin(_hover_time * 0.6) * 0.25
		)
		global_position = global_position.lerp(desired_pos, clampf(5.5 * delta, 0.0, 1.0))

	if anim_sprite:
		var dx := desired_pos.x - global_position.x
		if absf(dx) > 0.08:
			anim_sprite.flip_h = dx < 0.0
		else:
			anim_sprite.flip_h = owner_player.anim_sprite.flip_h if owner_player.anim_sprite else false

	# 2. Hỗ trợ bắn Đạn Linh Khí khi đang trong chiến đấu
	if GameManager.is_stage_active and _bolt_cd <= 0.0:
		var enemy := _find_nearest_enemy(11.5)
		if enemy:
			_fire_spirit_bolt(enemy)
			_bolt_cd = 2.4 if pet_type == "fox" else 2.1

	# 3. Tạo Lá Chắn Linh Khí bảo vệ khi người chơi sắp hết máu (< 38% HP)
	if GameManager.is_stage_active and _shield_cd <= 0.0 and not owner_player._is_dead:
		var hp_ratio := owner_player.current_hp / maxf(1.0, owner_player.max_hp)
		if hp_ratio > 0.0 and hp_ratio <= 0.38:
			_shield_cd = 20.0
			owner_player.activate_spirit_shield(5.0)
			var pet_lbl := "TIỂU HỒ LY" if pet_type == "fox" else "TIÊN HẠC"
			DamageNumber3D.spawn(get_parent(), owner_player.global_position + Vector3(0.0, 0.85, 0.0), 0, true, false, pet_lbl + ": HỘ THÂN THUẪN!")


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


func _fire_spirit_bolt(enemy: Node3D) -> void:
	if get_parent() == null:
		return
	var bolt := SpiritBolt3D.new()
	bolt.target_enemy = enemy
	var to_e := (enemy.global_position + Vector3(0.0, 0.85, 0.0)) - global_position
	bolt.direction = to_e.normalized() if to_e.length() > 0.01 else Vector3.RIGHT
	bolt.damage = int(round(owner_player.attack_damage * 0.65))
	bolt.bolt_color = Color(1.0, 0.48, 0.72) if pet_type == "fox" else Color(0.38, 0.96, 0.88)
	get_parent().add_child(bolt)
	bolt.global_position = global_position
	AudioManager.play_sfx("pickup", 1.35)
