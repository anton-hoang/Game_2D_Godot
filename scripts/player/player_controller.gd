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

## 3 Bùa Cổ Ngữ Roguelite thu thập trong màn chơi (có thể cộng dồn nhiều tầng!):
## - "lightning": Lôi Công Kiếm Quyết (Đòn 3 giật tia sét lan sang 3 quái gần nhất)
## - "fire_dash": Hỏa Viêm Khinh Công (Dash để lại vệt lửa đốt cháy quái)
## - "siphon": Hấp Tinh Đại Pháp (Hạ gục quái hồi 8% HP & 15 Chân Khí)
var active_relics: Dictionary = {
	"lightning": 0,
	"fire_dash": 0,
	"siphon": 0,
}
var _fire_trail_spawn_cd: float = 0.0

var anim_sprite: AnimatedSprite3D
var slash_vfx: Sprite3D
var player_light: OmniLight3D
var camera_rig: CameraRig3D
var _rim_halo_sprite: Sprite3D
var _contact_shadow: MeshInstance3D
var _shield_dome: MeshInstance3D
var _spirit_shield_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_apply_save_upgrades()
	_build_visual_nodes()
	if not SaveManager.cosmetic_changed.is_connected(refresh_cosmetic_appearance):
		SaveManager.cosmetic_changed.connect(refresh_cosmetic_appearance)
	hp_changed.emit(current_hp, max_hp)
	energy_changed.emit(current_energy, max_energy)


## Cập nhật màu khăn choàng ngay lập tức khi người chơi mở khóa hoặc thay đổi trang bị
func refresh_cosmetic_appearance() -> void:
	if anim_sprite and custom_sprite_frames == null:
		var cur_anim := anim_sprite.animation
		anim_sprite.sprite_frames = PixelArtGenerator.get_player_sprite_frames(SaveManager.equipped_scarf)
		anim_sprite.play(cur_anim if anim_sprite.sprite_frames.has_animation(cur_anim) else "idle")


## Xóa sạch các Bùa Cổ Ngữ khi bắt đầu màn mới
func reset_stage_relics() -> void:
	active_relics = {"lightning": 0, "fire_dash": 0, "siphon": 0}


## Cộng thêm tầng Bùa Cổ Ngữ vừa chọn sau mỗi Wave
func add_relic(relic_id: String) -> void:
	active_relics[relic_id] = int(active_relics.get(relic_id, 0)) + 1
	AudioManager.play_sfx("victory", 1.2)


## Kích hoạt Lá Chắn Hộ Thân từ Linh Thú đồng hành (chặn hoàn toàn sát thương trong thời gian hiệu lực)
func activate_spirit_shield(duration_sec: float = 5.0) -> void:
	_spirit_shield_timer = maxf(_spirit_shield_timer, duration_sec)
	if _shield_dome:
		_shield_dome.visible = true
	AudioManager.play_sfx("gate", 1.25)


## Kích hoạt hiệu ứng Hấp Tinh Đại Pháp khi tiêu diệt quái vật
func on_enemy_killed() -> void:
	var lv: int = int(active_relics.get("siphon", 0))
	if lv > 0:
		heal(max_hp * 0.08 * float(lv))
		add_energy(15.0 * float(lv))


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
	anim_sprite.sprite_frames = custom_sprite_frames if custom_sprite_frames else PixelArtGenerator.get_player_sprite_frames(SaveManager.equipped_scarf)
	anim_sprite.play("idle")

	# Tạo viền sáng Rim-Light an toàn 100% bằng Sprite3D hào quang nhẹ phía sau (tránh xung đột pipeline material_override trên D3D12)
	var rim_halo := Sprite3D.new()
	rim_halo.name = "RimLightHalo"
	rim_halo.position = Vector3(0.0, 0.96, -0.02)
	rim_halo.pixel_size = 0.0475
	rim_halo.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	rim_halo.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	rim_halo.shaded = false
	rim_halo.modulate = Color(1.0, 0.82, 0.46, 0.42)
	rim_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rim_halo)
	_rim_halo_sprite = rim_halo

	# Bóng tròn mềm tiếp đất (Contact Shadow) giúp nhân vật đứng vững và rõ vị trí trong màn đêm
	_contact_shadow = MeshInstance3D.new()
	var sh_cyl := CylinderMesh.new()
	sh_cyl.top_radius = 0.46
	sh_cyl.bottom_radius = 0.46
	sh_cyl.height = 0.02
	_contact_shadow.mesh = sh_cyl
	_contact_shadow.position = Vector3(0.0, 0.03, 0.0)
	var sh_mat := StandardMaterial3D.new()
	sh_mat.albedo_color = Color(0.02, 0.02, 0.04, 0.58)
	sh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_contact_shadow.material_override = sh_mat
	add_child(_contact_shadow)

	# Quả cầu Lá Chắn Linh Khí 3D (hiện lên khi Tiểu Hồ Ly / Tiên Hạc cứu nguy lúc sắp hết máu)
	_shield_dome = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.15
	sm.height = 2.3
	_shield_dome.mesh = sm
	_shield_dome.position = Vector3(0.0, 0.95, 0.0)
	var s_mat := StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.42, 0.95, 0.88, 0.26)
	s_mat.emission_enabled = true
	s_mat.emission = Color(0.35, 0.92, 0.86)
	s_mat.emission_energy_multiplier = 1.8
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shield_dome.material_override = s_mat
	_shield_dome.visible = false
	add_child(_shield_dome)

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

	# Đồng bộ frame & hướng cho lớp Rim-Light Halo phía sau nhân vật
	if _rim_halo_sprite and anim_sprite and anim_sprite.sprite_frames:
		var cur_tex := anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, anim_sprite.frame)
		if cur_tex and _rim_halo_sprite.texture != cur_tex:
			_rim_halo_sprite.texture = cur_tex
		_rim_halo_sprite.flip_h = anim_sprite.flip_h

	# Hồi năng lượng tự nhiên theo thời gian
	if current_energy < max_energy:
		current_energy = minf(max_energy, current_energy + 4.5 * delta)
		energy_changed.emit(current_energy, max_energy)

	if _invuln_timer > 0.0:
		_invuln_timer -= delta
	if _spirit_shield_timer > 0.0:
		_spirit_shield_timer -= delta
		if _shield_dome:
			_shield_dome.rotation.y += delta * 2.2
			if _spirit_shield_timer <= 0.0:
				_shield_dome.visible = false
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
		# Bùa Cổ Ngữ Hỏa Viêm Khinh Công: Để lại vệt lửa đốt cháy quái đuổi theo
		var fire_lv: int = int(active_relics.get("fire_dash", 0))
		if fire_lv > 0:
			_fire_trail_spawn_cd -= delta
			if _fire_trail_spawn_cd <= 0.0:
				_spawn_fire_trail(fire_lv)
				_fire_trail_spawn_cd = 0.065
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

	# Giới hạn trong khu vực làng (cho phép đi lên cầu thang, sân tầng 2 và bước vào 3 ngôi nhà gỗ)
	global_position.x = clampf(global_position.x, -21.5, 21.5)
	global_position.z = clampf(global_position.z, -16.5, 9.5)


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
	var hit_any := _deal_melee_damage(attack_damage * dmg_mult, hit_range, 0.85, knockback, is_crit)
	# Bùa Cổ Ngữ Lôi Công Kiếm Quyết: Đòn thứ 3 giật tia sét lan sang 3 quái gần nhất!
	var lightning_lv: int = int(active_relics.get("lightning", 0))
	if combo_step == 3 and hit_any and lightning_lv > 0:
		_trigger_chain_lightning(lightning_lv)


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


func _deal_melee_damage(dmg: float, radius: float, dot_threshold: float, knockback_force: float, is_crit: bool) -> bool:
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

	# Hỗ trợ chém vỡ các vật thể 3D phá hủy được (Thùng rượu gỗ, Hòm hàng)
	for br in get_tree().get_nodes_in_group("breakables"):
		if not is_instance_valid(br) or not br.has_method("take_damage"):
			continue
		var to_br: Vector3 = br.global_position - global_position
		to_br.y = 0.0
		if to_br.length() <= radius + 0.45:
			var dir_br := to_br.normalized() if to_br.length() > 0.01 else facing_dir
			if dot_threshold < -0.5 or dir_br.dot(facing_dir) >= -0.35:
				br.take_damage(int(round(dmg)))
				hit_any = true

	if hit_any:
		# Hồi nhẹ năng lượng mỗi khi đánh trúng quái
		add_energy(5.0)
		GameManager.trigger_hit_stop(0.045 if not is_crit else 0.068, 0.08)
		if camera_rig:
			camera_rig.shake(0.14 if not is_crit else 0.22, 0.11)
	return hit_any


## Lôi Công Kiếm Quyết: Giật tia sét màu lam vàng lan sang tối đa 3 quái vật gần nhất
func _trigger_chain_lightning(level: int) -> void:
	var candidates: Array = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node.has_method("take_damage"):
			var d := global_position.distance_to(node.global_position)
			if d <= 9.5:
				candidates.append({"node": node, "dist": d})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["dist"]) < float(b["dist"]))

	var max_targets := mini(3, candidates.size())
	var prev_pos := global_position + Vector3(0.0, 1.0, 0.0)
	var bolt_dmg := int(round(attack_damage * (0.75 + 0.35 * float(level - 1))))

	if max_targets > 0:
		AudioManager.play_sfx("special", 1.35)
	for i in range(max_targets):
		var target_node: Node3D = candidates[i]["node"]
		if not is_instance_valid(target_node):
			continue
		var target_pos := target_node.global_position + Vector3(0.0, 1.0, 0.0)
		_spawn_lightning_beam(prev_pos, target_pos)
		target_node.take_damage(bolt_dmg, Vector3.ZERO, true)
		DamageNumber3D.spawn(get_parent(), target_pos, bolt_dmg, true, false, "LÔI SÉT -" + str(bolt_dmg))
		prev_pos = target_pos


func _spawn_lightning_beam(from_pos: Vector3, to_pos: Vector3) -> void:
	if get_parent() == null:
		return
	var diff := to_pos - from_pos
	var dist := diff.length()
	if dist < 0.05:
		return
	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.14, 0.14, dist)
	beam.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.55, 0.92, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.42, 0.88, 1.0)
	mat.emission_energy_multiplier = 4.5
	beam.material_override = mat
	get_parent().add_child(beam)
	beam.global_position = (from_pos + to_pos) * 0.5
	beam.look_at(to_pos, Vector3.UP)

	var tw := beam.create_tween()
	tw.tween_property(beam, "scale", Vector3(0.05, 0.05, 1.0), 0.22)
	tw.tween_callback(beam.queue_free)


func _spawn_fire_trail(level: int) -> void:
	if get_parent() == null:
		return
	var fz := FireTrailZone3D.new()
	fz.burn_damage = 10 + level * 6
	fz.duration = 2.8 + float(level - 1) * 0.6
	get_parent().add_child(fz)
	fz.global_position = global_position + Vector3(0.0, 0.05, 0.0)


## Nhận sát thương từ quái hoặc đạn
func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if _is_dead or _invuln_timer > 0.0:
		return
	if _spirit_shield_timer > 0.0:
		AudioManager.play_sfx("pickup", 1.4)
		DamageNumber3D.spawn(get_parent(), global_position + Vector3(0, 0.5, 0), 0, true, false, "KHIÊN CHẶN!")
		_invuln_timer = 0.25
		return
	current_hp = maxf(0.0, current_hp - amount)
	GameManager.damage_taken_in_stage += amount
	SaveManager.reset_no_damage_goblin_streak()
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
