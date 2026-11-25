class_name PlayerController
extends CharacterBody3D
## Nhân vật người chơi 2.5D HD-2D (CharacterBody3D + AnimatedSprite3D Billboard + Đổ bóng thật):
## - Di chuyển 8 hướng trên mặt phẳng XZ.
## - Né (Dash) có thời gian hồi & khung bất tử ngắn (i-frame).
## - Combo tấn công thường 3 đòn liên tiếp (J) và Kỹ năng đặc biệt xoáy kiếm AOE tốn năng lượng (K).
## - Hit-stop, knockback, rung camera và số sát thương bay lên.

signal hp_changed(current_hp: float, max_hp: float)
signal energy_changed(current_energy: float, max_energy: float)
signal dash_cooldown_changed(remaining: float, total: float)

## PLACEHOLDER ASSET: Khi có SpriteFrames thật (.tres), kéo thả vào thuộc tính custom_sprite_frames trong Inspector.
@export var custom_sprite_frames: SpriteFrames
@export var base_max_hp: float = 120.0
@export var base_max_energy: float = 100.0
@export var base_speed: float = 6.2
@export var base_attack_damage: float = 22.0
@export var dash_speed: float = 16.5
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.85
@export var special_energy_cost: float = 35.0

var max_hp: float = 120.0
var current_hp: float = 120.0
var max_energy: float = 100.0
var current_energy: float = 100.0
var move_speed: float = 6.2
var attack_damage: float = 22.0

var facing_dir: Vector3 = Vector3.RIGHT
var combo_step: int = 0
var _combo_reset_timer: float = 0.0
var _attack_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cd_timer: float = 0.0
var _invuln_timer: float = 0.0
var _knockback_vel: Vector3 = Vector3.ZERO
var _is_dead: bool = false

var anim_sprite: AnimatedSprite3D
var slash_vfx: Sprite3D
var player_light: OmniLight3D
var camera_rig: CameraRig3D


func _ready() -> void:
	add_to_group("player")
	_apply_save_upgrades()
	_build_visual_nodes()
	hp_changed.emit(current_hp, max_hp)
	energy_changed.emit(current_energy, max_energy)


## Áp dụng các nâng cấp đã mua bằng vàng từ SaveManager
func _apply_save_upgrades() -> void:
	max_hp = base_max_hp + SaveManager.get_bonus_max_hp()
	current_hp = max_hp
	max_energy = base_max_energy
	current_energy = max_energy * 0.6
	move_speed = base_speed + SaveManager.get_bonus_speed()
	attack_damage = base_attack_damage + SaveManager.get_bonus_attack()


## Tạo các node hiển thị Sprite3D billboard, bóng đổ và hiệu ứng chém nếu chưa có trong scene
func _build_visual_nodes() -> void:
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap := CapsuleShape3D.new()
		cap.radius = 0.38
		cap.height = 1.35
		col.shape = cap
		col.position = Vector3(0.0, 0.68, 0.0)
		add_child(col)

	anim_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if anim_sprite == null:
		anim_sprite = AnimatedSprite3D.new()
		anim_sprite.name = "AnimatedSprite3D"
		add_child(anim_sprite)

	anim_sprite.position = Vector3(0.0, 0.96, 0.0)
	anim_sprite.pixel_size = 0.044
	anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	anim_sprite.shaded = true
	anim_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	anim_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	anim_sprite.sprite_frames = custom_sprite_frames if custom_sprite_frames else PixelArtGenerator.get_player_sprite_frames()
	anim_sprite.play("idle")

	slash_vfx = get_node_or_null("SlashVFX") as Sprite3D
	if slash_vfx == null:
		slash_vfx = Sprite3D.new()
		slash_vfx.name = "SlashVFX"
		add_child(slash_vfx)
	slash_vfx.texture = PixelArtGenerator.get_prop_texture("slash_arc")
	slash_vfx.pixel_size = 0.058
	slash_vfx.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	slash_vfx.position = Vector3(0.75, 0.85, 0.0)
	slash_vfx.visible = false

	# Đèn lồng cá nhân ấm nhẹ giúp nhân vật luôn nổi bật trong màn đêm sâu HD-2D
	player_light = get_node_or_null("PlayerLantern") as OmniLight3D
	if player_light == null:
		player_light = OmniLight3D.new()
		player_light.name = "PlayerLantern"
		add_child(player_light)
	player_light.position = Vector3(0.0, 1.25, 0.55)
	player_light.light_color = Color(1.0, 0.80, 0.48)
	player_light.light_energy = 1.25
	player_light.omni_range = 5.5


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# Hồi năng lượng tự nhiên theo thời gian
	if current_energy < max_energy:
		current_energy = minf(max_energy, current_energy + 4.5 * delta)
		energy_changed.emit(current_energy, max_energy)

	if _invuln_timer > 0.0:
		_invuln_timer -= delta
	if _combo_reset_timer > 0.0:
		_combo_reset_timer -= delta
		if _combo_reset_timer <= 0.0:
			combo_step = 0
	if _dash_cd_timer > 0.0:
		_dash_cd_timer = maxf(0.0, _dash_cd_timer - delta)
		dash_cooldown_changed.emit(_dash_cd_timer, dash_cooldown)
	if _attack_timer > 0.0:
		_attack_timer -= delta

	# Lấy vector di chuyển 8 hướng trên mặt phẳng XZ
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_vec.x, 0.0, input_vec.y)
	if move_dir.length_squared() > 0.001:
		move_dir = move_dir.normalized()
		facing_dir = move_dir
		if absf(move_dir.x) > 0.05:
			anim_sprite.flip_h = move_dir.x < 0.0

	# Xử lý phím Né (Dash - phím L)
	if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0 and _dash_timer <= 0.0:
		_start_dash(move_dir if move_dir.length_squared() > 0.01 else facing_dir)

	# Xử lý phím Tấn công combo 3 đòn (phím J) & Kỹ năng đặc biệt (phím K)
	if _dash_timer <= 0.0 and _attack_timer <= 0.0:
		if Input.is_action_just_pressed("attack"):
			_perform_combo_attack()
		elif Input.is_action_just_pressed("special") and current_energy >= special_energy_cost:
			_perform_special_skill()

	# Tính vận tốc
	if _dash_timer > 0.0:
		_dash_timer -= delta
		velocity.x = facing_dir.x * dash_speed
		velocity.z = facing_dir.z * dash_speed
	elif _attack_timer > 0.0:
		velocity.x = facing_dir.x * 1.4 + _knockback_vel.x
		velocity.z = facing_dir.z * 1.4 + _knockback_vel.z
	else:
		velocity.x = move_dir.x * move_speed + _knockback_vel.x
		velocity.z = move_dir.z * move_speed + _knockback_vel.z
		if _invuln_timer <= 0.05:
			if move_dir.length_squared() > 0.01:
				if anim_sprite.animation != "run":
					anim_sprite.play("run")
			else:
				if anim_sprite.animation != "idle":
					anim_sprite.play("idle")

	# Trọng lực
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.1

	_knockback_vel = _knockback_vel.move_toward(Vector3.ZERO, 18.0 * delta)
	move_and_slide()

	# Giới hạn trong đấu trường để không rơi khỏi map
	global_position.x = clampf(global_position.x, -21.0, 21.0)
	global_position.z = clampf(global_position.z, -8.5, 9.5)


func _start_dash(dir: Vector3) -> void:
	facing_dir = dir.normalized()
	_dash_timer = dash_duration
	_dash_cd_timer = dash_cooldown
	_invuln_timer = dash_duration + 0.08
	anim_sprite.play("dash")
	AudioManager.play_sfx("dash")
	dash_cooldown_changed.emit(_dash_cd_timer, dash_cooldown)


## Tấn công thường theo combo 3 đòn: Đòn 1 chém nhanh -> Đòn 2 quét ngang -> Đòn 3 kết liễu mạnh
func _perform_combo_attack() -> void:
	combo_step = (combo_step % 3) + 1
	_combo_reset_timer = 0.95
	_attack_timer = 0.20 if combo_step < 3 else 0.28

	var anim_name := "attack_" + str(combo_step)
	anim_sprite.play(anim_name)
	AudioManager.play_sfx("slash", 0.95 + combo_step * 0.08)

	var dmg_mult := 1.0 if combo_step == 1 else (1.22 if combo_step == 2 else 1.65)
	var hit_range := 2.25 if combo_step < 3 else 2.75
	var knockback := 6.5 if combo_step < 3 else 11.5
	var is_crit := combo_step == 3

	_show_slash_effect(
		Color(0.85, 0.95, 1.0) if combo_step < 3 else Color(1.0, 0.85, 0.35),
		1.0 if combo_step < 3 else 1.35
	)
	_deal_melee_damage(attack_damage * dmg_mult, hit_range, 0.85, knockback, is_crit)


## Kỹ năng đặc biệt (Phím K): Kiếm Khí Xung Kích 360 độ tiêu hao năng lượng
func _perform_special_skill() -> void:
	current_energy = maxf(0.0, current_energy - special_energy_cost)
	energy_changed.emit(current_energy, max_energy)
	_attack_timer = 0.34
	_invuln_timer = 0.25
	anim_sprite.play("special")
	AudioManager.play_sfx("special")

	_show_slash_effect(Color(0.35, 0.92, 1.0), 1.9)
	# Gây sát thương diện rộng toàn bộ quái xung quanh
	_deal_melee_damage(attack_damage * 2.25, 3.8, -1.0, 13.5, true)
	if camera_rig:
		camera_rig.shake(0.24, 0.18)


func _show_slash_effect(col: Color, scale_mult: float) -> void:
	if slash_vfx == null:
		return
	slash_vfx.visible = true
	slash_vfx.modulate = col
	slash_vfx.position = Vector3(facing_dir.x * 0.95, 0.85, facing_dir.z * 0.95)
	slash_vfx.flip_h = facing_dir.x < 0.0
	slash_vfx.scale = Vector3.ONE * scale_mult
	var tw := create_tween()
	tw.tween_property(slash_vfx, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func() -> void: slash_vfx.visible = false)


func _deal_melee_damage(dmg: float, radius: float, dot_threshold: float, knockback_force: float, is_crit: bool) -> void:
	var hit_any := false
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node.has_method("take_damage"):
			continue
		var to_enemy: Vector3 = node.global_position - global_position
		to_enemy.y = 0.0
		var dist := to_enemy.length()
		if dist <= radius:
			var dir_to := to_enemy.normalized() if dist > 0.01 else facing_dir
			if dot_threshold < -0.5 or dir_to.dot(facing_dir) >= -0.25:
				var final_dmg := int(round(dmg * randf_range(0.95, 1.08)))
				node.take_damage(final_dmg, dir_to * knockback_force, is_crit)
				hit_any = true

	if hit_any:
		# Hồi nhẹ năng lượng mỗi khi đánh trúng quái
		add_energy(5.0)
		GameManager.trigger_hit_stop(0.045 if not is_crit else 0.068, 0.08)
		if camera_rig:
			camera_rig.shake(0.14 if not is_crit else 0.22, 0.11)


## Nhận sát thương từ quái hoặc đạn
func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if _is_dead or _invuln_timer > 0.0:
		return
	current_hp = maxf(0.0, current_hp - amount)
	GameManager.damage_taken_in_stage += amount
	_invuln_timer = 0.55
	_knockback_vel = Vector3(knockback.x, 0.0, knockback.z)
	anim_sprite.play("hurt")
	AudioManager.play_sfx("hurt")
	hp_changed.emit(current_hp, max_hp)
	DamageNumber3D.spawn(get_parent(), global_position, int(round(amount)), false, false)

	if camera_rig:
		camera_rig.shake(0.22, 0.15)
	GameManager.trigger_hit_stop(0.05, 0.1)

	# Nhấp nháy đỏ khi trúng đòn
	var tw := create_tween()
	anim_sprite.modulate = Color(1.0, 0.35, 0.35)
	tw.tween_property(anim_sprite, "modulate", Color.WHITE, 0.35)

	if current_hp <= 0.0:
		_is_dead = true
		GameManager.notify_player_died()


func heal(amount: float) -> void:
	if _is_dead:
		return
	var actual := minf(max_hp - current_hp, amount)
	current_hp = minf(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)
	DamageNumber3D.spawn(get_parent(), global_position, int(round(maxf(1.0, actual))), false, true)


func add_energy(amount: float) -> void:
	if _is_dead:
		return
	current_energy = minf(max_energy, current_energy + amount)
	energy_changed.emit(current_energy, max_energy)
