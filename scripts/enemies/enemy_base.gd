class_name EnemyBase
extends CharacterBody3D
## AI Quái vật & Boss theo State Machine (IDLE, CHASE, ATTACK, HURT, DIE):
## - Hỗ trợ 4 loại quái thường: melee (cận chiến), ranged (bắn đạn phép), charger (tích lực lao nhanh), tank (máu trâu + kháng đẩy lùi + đập đất).
## - Hỗ trợ Boss cuối chương với 3 Pha chiến đấu (Phase 1 -> Phase 2 dưới 65% HP -> Phase 3 Cuồng Nộ dưới 30% HP).

signal died(enemy: EnemyBase)
signal boss_hp_changed(current_hp: float, max_hp: float, boss_name: String, phase: int, shield_pts: int, is_broken: bool)

enum State { IDLE, CHASE, ATTACK, HURT, BROKEN, DIE }

@export var stats: EnemyStats

var current_state: State = State.IDLE
var current_hp: float = 60.0
var max_hp: float = 60.0
var boss_phase: int = 1
var max_shield: int = 0
var current_shield: int = 0
var _break_timer: float = 0.0

var _attack_cd_timer: float = 0.0
var _state_timer: float = 0.0
var _knockback_vel: Vector3 = Vector3.ZERO
var _charge_dir: Vector3 = Vector3.ZERO
var _is_charging_dash: bool = false

var anim_sprite: AnimatedSprite3D
var hp_bar_3d: Sprite3D
var shield_label_3d: Label3D
var _hp_bar_img: Image
var _hp_bar_tex: ImageTexture
var _rim_halo_sprite: Sprite3D


func _ready() -> void:
	add_to_group("enemies")
	if stats == null:
		stats = EnemyStats.new()
	max_hp = stats.max_hp
	current_hp = max_hp
	# Gán Khiên Giáp (Shield) cho Quái Tank (3 Khiên) & Boss Malakor (5 Khiên)
	if stats.archetype == "tank":
		max_shield = 3
	elif stats.archetype == "boss":
		max_shield = 5
	current_shield = max_shield

	_build_visuals()
	if stats.archetype == "boss":
		boss_hp_changed.emit(current_hp, max_hp, stats.enemy_name, boss_phase, current_shield, false)


func _build_visuals() -> void:
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap := CapsuleShape3D.new()
		cap.radius = 0.42 * stats.sprite_scale
		cap.height = 1.4 * stats.sprite_scale
		col.shape = cap
		col.position = Vector3(0.0, 0.7 * stats.sprite_scale, 0.0)
		add_child(col)

	anim_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if anim_sprite == null:
		anim_sprite = AnimatedSprite3D.new()
		anim_sprite.name = "AnimatedSprite3D"
		add_child(anim_sprite)

	var y_offset := 1.42 if stats.archetype == "boss" else (1.05 if stats.archetype == "tank" else 0.84)
	anim_sprite.position = Vector3(0.0, y_offset * stats.sprite_scale, 0.0)
	anim_sprite.pixel_size = 0.045 * stats.sprite_scale
	anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	anim_sprite.shaded = true
	anim_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	anim_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	anim_sprite.sprite_frames = stats.custom_sprite_frames if stats.custom_sprite_frames else PixelArtGenerator.get_enemy_sprite_frames(stats.archetype, stats.sprite_tint)
	anim_sprite.play("idle")

	# Lớp viền sáng Rim-Light an toàn 100% trên D3D12 (Boss tỏa viền đỏ rực uy nghi, quái thường tỏa viền ánh trăng)
	_rim_halo_sprite = Sprite3D.new()
	_rim_halo_sprite.name = "RimLightHalo"
	_rim_halo_sprite.position = Vector3(0.0, y_offset * stats.sprite_scale, -0.025)
	_rim_halo_sprite.pixel_size = 0.0485 * stats.sprite_scale
	_rim_halo_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_rim_halo_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_rim_halo_sprite.shaded = false
	_rim_halo_sprite.modulate = Color(1.0, 0.24, 0.34, 0.58) if stats.archetype == "boss" else Color(0.56, 0.80, 1.0, 0.34)
	_rim_halo_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rim_halo_sprite)

	# Bóng tròn mềm tiếp đất dưới chân quái/Boss
	var csh := MeshInstance3D.new()
	var sh_cyl := CylinderMesh.new()
	sh_cyl.top_radius = 0.50 * stats.sprite_scale
	sh_cyl.bottom_radius = 0.50 * stats.sprite_scale
	sh_cyl.height = 0.02
	csh.mesh = sh_cyl
	csh.position = Vector3(0.0, 0.03, 0.0)
	var sh_mat := StandardMaterial3D.new()
	sh_mat.albedo_color = Color(0.02, 0.01, 0.04, 0.55)
	sh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	csh.material_override = sh_mat
	add_child(csh)

	# Thanh máu nhỏ kiểu cổ trang viền vàng đồng trên đầu quái thường
	if stats.archetype != "boss":
		hp_bar_3d = Sprite3D.new()
		hp_bar_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		hp_bar_3d.pixel_size = 0.024
		hp_bar_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		hp_bar_3d.position = Vector3(0.0, 1.80 * stats.sprite_scale, 0.0)
		_hp_bar_img = Image.create(36, 7, false, Image.FORMAT_RGBA8)
		_hp_bar_tex = ImageTexture.create_from_image(_hp_bar_img)
		hp_bar_3d.texture = _hp_bar_tex
		add_child(hp_bar_3d)
		_update_overhead_hp_bar()

	# Biểu tượng Khiên Giáp trên đầu cho quái Tank (Boss hiển thị ngay trên thanh máu lớn HUD)
	if max_shield > 0 and stats.archetype != "boss":
		shield_label_3d = Label3D.new()
		WuxiaFontTheme.style_label_3d(shield_label_3d)
		shield_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		shield_label_3d.pixel_size = 0.0085
		shield_label_3d.font_size = 28
		shield_label_3d.outline_size = 8
		shield_label_3d.position = Vector3(0.0, 2.22 * stats.sprite_scale, 0.0)
		add_child(shield_label_3d)
		_update_shield_display()


func _update_shield_display() -> void:
	if shield_label_3d:
		if current_state == State.BROKEN:
			shield_label_3d.text = "★ PHÁ GIÁP (x2 SÁT THƯƠNG) ★"
			shield_label_3d.modulate = Color(1.0, 0.35, 0.25)
		else:
			shield_label_3d.text = "🛡 KHIÊN: %d / %d" % [current_shield, max_shield]
			shield_label_3d.modulate = Color(0.55, 0.90, 1.0)
	if stats.archetype == "boss":
		boss_hp_changed.emit(current_hp, max_hp, stats.enemy_name, boss_phase, current_shield, current_state == State.BROKEN)


func _update_overhead_hp_bar() -> void:
	if _hp_bar_img == null or _hp_bar_tex == null:
		return
	# Viền vàng đồng cổ trang bên ngoài + nền tối bên trong
	_hp_bar_img.fill(Color(0.84, 0.66, 0.28, 0.95))
	for y in range(1, 6):
		for x in range(1, 35):
			_hp_bar_img.set_pixel(x, y, Color(0.08, 0.04, 0.05, 0.92))
	var ratio := clampf(current_hp / maxf(1.0, max_hp), 0.0, 1.0)
	var fill_w := int(round(32.0 * ratio))
	var bar_col := Color(0.82, 0.16, 0.18) if stats.archetype != "tank" else Color(0.92, 0.56, 0.16)
	var bar_hi := bar_col.lightened(0.28)
	for y in range(2, 5):
		for x in range(2, 2 + fill_w):
			_hp_bar_img.set_pixel(x, y, bar_hi if y == 2 else bar_col)
	_hp_bar_tex.update(_hp_bar_img)


func _physics_process(delta: float) -> void:
	if _rim_halo_sprite and anim_sprite and anim_sprite.sprite_frames:
		var cur_tex := anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, anim_sprite.frame)
		if cur_tex and _rim_halo_sprite.texture != cur_tex:
			_rim_halo_sprite.texture = cur_tex
		_rim_halo_sprite.flip_h = anim_sprite.flip_h
		_rim_halo_sprite.visible = current_state != State.DIE

	if current_state == State.DIE:
		return

	if _attack_cd_timer > 0.0:
		_attack_cd_timer -= delta

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var to_player := Vector3.ZERO
	var dist_to_player := 999.0
	if player and is_instance_valid(player):
		to_player = player.global_position - global_position
		to_player.y = 0.0
		dist_to_player = to_player.length()

	match current_state:
		State.IDLE:
			velocity.x = _knockback_vel.x
			velocity.z = _knockback_vel.z
			if anim_sprite.animation != "idle":
				anim_sprite.play("idle")
			if dist_to_player <= stats.detection_range:
				_change_state(State.CHASE)

		State.CHASE:
			if player == null:
				_change_state(State.IDLE)
			else:
				var dir := to_player.normalized() if dist_to_player > 0.01 else Vector3.RIGHT
				if absf(dir.x) > 0.05:
					anim_sprite.flip_h = dir.x < 0.0
				if anim_sprite.animation != "move":
					anim_sprite.play("move")

				# Quái tầm xa giữ khoảng cách hợp lý, quái khác tiến sát vào
				var speed_mult := 1.0 + (boss_phase - 1) * 0.22
				if stats.archetype == "ranged" and dist_to_player < stats.attack_range * 0.55:
					velocity.x = -dir.x * stats.move_speed * 0.75 + _knockback_vel.x
					velocity.z = -dir.z * stats.move_speed * 0.75 + _knockback_vel.z
				else:
					velocity.x = dir.x * stats.move_speed * speed_mult + _knockback_vel.x
					velocity.z = dir.z * stats.move_speed * speed_mult + _knockback_vel.z

				if dist_to_player <= stats.attack_range and _attack_cd_timer <= 0.0:
					_start_attack(player, dir)

		State.ATTACK:
			_state_timer -= delta
			if _is_charging_dash:
				var dash_spd := stats.move_speed * (3.1 if stats.archetype == "charger" else 2.6)
				velocity.x = _charge_dir.x * dash_spd + _knockback_vel.x
				velocity.z = _charge_dir.z * dash_spd + _knockback_vel.z
			else:
				velocity.x = _knockback_vel.x * 0.5
				velocity.z = _knockback_vel.z * 0.5

			if _state_timer <= 0.0:
				_is_charging_dash = false
				_change_state(State.CHASE)

		State.HURT:
			_state_timer -= delta
			velocity.x = _knockback_vel.x
			velocity.z = _knockback_vel.z
			if _state_timer <= 0.0:
				_change_state(State.CHASE)

		State.BROKEN:
			# TRẠNG THÁI PHÁ GIÁP (BREAK): Quái/Boss bị choáng bất động hoàn toàn trong 3 giây & nhận x2 sát thương!
			_break_timer -= delta
			velocity.x = _knockback_vel.x * 0.4
			velocity.z = _knockback_vel.z * 0.4
			if anim_sprite:
				anim_sprite.position.x = sin(_break_timer * 32.0) * 0.08
			if _break_timer <= 0.0:
				if anim_sprite:
					anim_sprite.position.x = 0.0
					anim_sprite.modulate = Color.WHITE
				current_shield = max_shield
				_change_state(State.CHASE)
				_update_shield_display()

	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.1

	_knockback_vel = _knockback_vel.move_toward(Vector3.ZERO, 16.0 * delta)
	move_and_slide()

	global_position.x = clampf(global_position.x, -21.0, 21.0)
	global_position.z = clampf(global_position.z, -8.5, 9.5)


func _change_state(new_state: State) -> void:
	if current_state == State.DIE:
		return
	current_state = new_state


func _start_attack(player: Node3D, dir_to_player: Vector3) -> void:
	_change_state(State.ATTACK)
	anim_sprite.play("attack")
	var cd_factor := 1.0 if stats.archetype != "boss" else (1.0 - (boss_phase - 1) * 0.22)
	_attack_cd_timer = stats.attack_cooldown * cd_factor

	match stats.archetype:
		"melee":
			_state_timer = 0.45
			_schedule_melee_hit(player, 0.22, stats.attack_range + 0.45, stats.attack_damage)
		"tank":
			_state_timer = 0.65
			# Đập đất tầm rộng gây knockback lớn
			_schedule_melee_hit(player, 0.35, stats.attack_range + 0.75, stats.attack_damage)
		"ranged":
			_state_timer = 0.50
			_schedule_ranged_shot(dir_to_player, 0.22, 1)
		"charger":
			_state_timer = 0.58
			_charge_dir = dir_to_player
			# Nhấp nháy báo hiệu trước khi húc
			anim_sprite.modulate = Color(1.0, 0.75, 0.3)
			await get_tree().create_timer(0.18).timeout
			if not is_instance_valid(self) or current_state == State.DIE:
				return
			anim_sprite.modulate = Color.WHITE
			_is_charging_dash = true
			_schedule_melee_hit(player, 0.16, 1.9, stats.attack_damage)
		"boss":
			_execute_boss_attack(player, dir_to_player)


## Boss có 3 Pha chiến đấu với kỹ năng đa dạng:
## - Pha 1 (100% - 65% HP): Chém đại đao + Bắn 3 cầu năng lượng hình quạt.
## - Pha 2 (65% - 30% HP): Lao chém tốc độ cao + Bắn 5 cầu năng lượng.
## - Pha 3 (< 30% HP): Cuồng nộ phát sáng đỏ, triệu hồi vòng đạn 8 hướng + đập đất liên hoàn.
func _execute_boss_attack(player: Node3D, dir_to_player: Vector3) -> void:
	_state_timer = 0.72
	var roll := randi() % 3
	if roll == 0:
		# Đòn 1: Chém đại đao cận chiến hoặc lao tới
		_charge_dir = dir_to_player
		_is_charging_dash = boss_phase >= 2
		_schedule_melee_hit(player, 0.26, stats.attack_range + 0.9, stats.attack_damage * (1.0 + (boss_phase - 1) * 0.2))
	elif roll == 1:
		# Đòn 2: Bắn chùm đạn năng lượng hình quạt
		var fan_count := 3 if boss_phase == 1 else (5 if boss_phase == 2 else 7)
		_schedule_ranged_shot(dir_to_player, 0.25, fan_count)
	else:
		# Đòn 3: Vòng xung kích 8 hướng (Pha 2 & 3) hoặc chém nặng (Pha 1)
		if boss_phase >= 2:
			_schedule_nova_ring(0.30, 8 if boss_phase == 2 else 12)
		else:
			_schedule_melee_hit(player, 0.30, stats.attack_range + 0.8, stats.attack_damage * 1.15)


func _schedule_melee_hit(player: Node3D, delay: float, hit_radius: float, dmg: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self) or current_state == State.DIE:
		return
	if player and is_instance_valid(player) and player.has_method("take_damage"):
		var diff := player.global_position - global_position
		diff.y = 0.0
		if diff.length() <= hit_radius:
			var kb_dir := diff.normalized() if diff.length() > 0.01 else Vector3.RIGHT
			player.take_damage(dmg, kb_dir * 7.5, self)


func _schedule_ranged_shot(base_dir: Vector3, delay: float, count: int) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self) or current_state == State.DIE:
		return
	var spread_deg := 18.0
	var start_deg := -spread_deg * float(count - 1) * 0.5
	for i in range(count):
		var angle := deg_to_rad(start_deg + i * spread_deg)
		var rotated_dir := base_dir.rotated(Vector3.UP, angle).normalized()
		_spawn_projectile(rotated_dir)


func _schedule_nova_ring(delay: float, count: int) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self) or current_state == State.DIE:
		return
	for i in range(count):
		var angle := (TAU / float(count)) * float(i)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		_spawn_projectile(dir)


func _spawn_projectile(dir: Vector3) -> void:
	if get_parent() == null:
		return
	var proj := EnemyProjectile3D.new()
	proj.direction = dir
	proj.damage = stats.attack_damage * 0.85
	proj.speed = 8.5 if stats.archetype != "boss" else (9.5 + boss_phase * 1.2)
	proj.orb_color = Color(0.6, 0.25, 1.0) if stats.archetype != "boss" else Color(1.0, 0.25, 0.45)
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector3(0.0, 0.85, 0.0)


## Xử lý khi bị Player Đỡ Đòn Hoàn Hảo (Perfect Parry): Phá 2 điểm Khiên Giáp ngay lập tức & phản sát thương chí mạng!
func on_parried_by_player(counter_dmg: int, player_pos: Vector3) -> void:
	if current_state == State.DIE:
		return
	var push_dir := (global_position - player_pos)
	push_dir.y = 0.0
	push_dir = push_dir.normalized() if push_dir.length() > 0.01 else Vector3.RIGHT
	_damage_shield(2)
	take_damage(counter_dmg, push_dir * 12.0, true)


func _damage_shield(points: int) -> void:
	if max_shield <= 0 or current_state == State.BROKEN or current_state == State.DIE:
		return
	current_shield = maxi(0, current_shield - points)
	if current_shield == 0:
		# VỠ KHIÊN -> KÍCH HOẠT PHÁ GIÁP (BREAK): Choáng 3.0 giây + nhận x2 sát thương!
		current_state = State.BROKEN
		_is_charging_dash = false
		_break_timer = 3.0
		anim_sprite.play("hurt")
		anim_sprite.modulate = Color(1.0, 0.55, 0.25)
		AudioManager.play_sfx("boss_roar", 1.3)
		GameManager.trigger_hit_stop(0.10, 0.05)
		CombatVFX3D.spawn_shockwave_ring(get_parent(), global_position, Color(1.0, 0.42, 0.16), 0.6, 5.0, 0.42)
		CombatVFX3D.spawn_hit_sparks(get_parent(), global_position, Vector3.UP, Color(1.0, 0.80, 0.25), 14)
		DamageNumber3D.spawn(get_parent(), global_position + Vector3(0, 1.0, 0), 0, true, false, "💥 PHÁ GIÁP (BREAK)! x2 DMG!")
	_update_shield_display()


## Nhận sát thương từ người chơi (Đòn chí mạng / đòn 3 / tuyệt kỹ trừ 1 Khiên; khi đang PHÁ GIÁP nhận x2 sát thương!)
func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO, is_crit: bool = false) -> void:
	if current_state == State.DIE:
		return

	var actual_dmg := amount
	if current_state == State.BROKEN:
		actual_dmg = amount * 2
		is_crit = true
	elif max_shield > 0 and is_crit:
		_damage_shield(1)

	current_hp = maxf(0.0, current_hp - float(actual_dmg))
	AudioManager.play_sfx("hit")
	DamageNumber3D.spawn(get_parent(), global_position, actual_dmg, is_crit, false)
	_update_overhead_hp_bar()

	var kb_mult := clampf(1.0 - stats.knockback_resistance, 0.1, 1.0)
	_knockback_vel = Vector3(knockback.x, 0.0, knockback.z) * kb_mult

	# Kiểm tra chuyển pha của Boss
	if stats.archetype == "boss":
		var hp_ratio := current_hp / maxf(1.0, max_hp)
		var new_phase := 3 if hp_ratio <= 0.30 else (2 if hp_ratio <= 0.65 else 1)
		if new_phase != boss_phase:
			boss_phase = new_phase
			AudioManager.play_sfx("boss_roar")
			DamageNumber3D.spawn(get_parent(), global_position + Vector3(0, 0.8, 0), 0, true, false, "PHA " + str(boss_phase) + "!")
		boss_hp_changed.emit(current_hp, max_hp, stats.enemy_name, boss_phase, current_shield, current_state == State.BROKEN)

	# Hiệu ứng nháy trắng/đỏ khi trúng đòn
	var flash_col := Color(1.0, 0.45, 0.45) if boss_phase < 3 else Color(1.0, 0.25, 0.35)
	anim_sprite.modulate = flash_col
	var tw := create_tween()
	var normal_col := Color(1.0, 0.65, 0.35) if current_state == State.BROKEN else (Color.WHITE if boss_phase < 3 else Color(1.0, 0.72, 0.72))
	tw.tween_property(anim_sprite, "modulate", normal_col, 0.22)

	if current_hp <= 0.0:
		_die()
	elif current_state != State.BROKEN and stats.knockback_resistance < 0.65 and current_state != State.ATTACK:
		_change_state(State.HURT)
		_state_timer = 0.18
		anim_sprite.play("hurt")


func _die() -> void:
	current_state = State.DIE
	_is_charging_dash = false
	anim_sprite.play("die")
	GameManager.add_score(stats.score_value)
	died.emit(self)

	var tw := create_tween()
	tw.tween_property(anim_sprite, "modulate:a", 0.0, 0.42)
	tw.tween_callback(queue_free)
