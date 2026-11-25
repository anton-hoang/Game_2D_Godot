class_name PlayerProjectile3D
extends Area3D
## Đạn tấn công của người chơi cho 2 hệ vũ khí tầm xa:
## - "arrow" (Cung Tên): Mũi tên mảnh dài bay siêu nhanh kèm đuôi sáng, xuyên phá mạnh.
## - "magic_orb" (Gậy Phép): Quả cầu pháp thuật truy đuổi mục tiêu, phát nổ diện rộng (AOE) khi trúng đích!

var proj_kind: String = "arrow" # "arrow" | "magic_orb"
var direction: Vector3 = Vector3.RIGHT
var speed: float = 19.0
var damage: int = 20
var knockback_force: float = 5.0
var is_crit: bool = false
var proj_color: Color = Color(0.65, 1.0, 0.48)
var aoe_radius: float = 0.0
var homing: bool = false
var lifetime: float = 2.6


func _ready() -> void:
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.35 if proj_kind == "arrow" else 0.44
	col.shape = sph
	add_child(col)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = proj_color
	mat.emission_enabled = true
	mat.emission = proj_color
	mat.emission_energy_multiplier = 4.0

	if proj_kind == "arrow":
		var shaft := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.10, 0.10, 1.15)
		shaft.mesh = bm
		shaft.material_override = mat
		add_child(shaft)
	else:
		var orb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.28
		sm.height = 0.56
		orb.mesh = sm
		orb.material_override = mat
		add_child(orb)
		var light := OmniLight3D.new()
		light.light_color = proj_color
		light.light_energy = 1.6
		light.omni_range = 3.4
		add_child(light)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if homing:
		var nearest := _find_nearest_enemy(9.0)
		if nearest:
			var to_e := (nearest.global_position + Vector3(0.0, 0.85, 0.0)) - global_position
			if to_e.length() > 0.1:
				direction = direction.lerp(to_e.normalized(), clampf(7.5 * delta, 0.0, 1.0)).normalized()

	global_position += direction * speed * delta
	if proj_kind == "arrow" and direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)


func _find_nearest_enemy(max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			var d := global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e as Node3D
	return best


func _on_body_entered(body: Node) -> void:
	if body == null or body.is_in_group("player"):
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		if aoe_radius > 0.1:
			CombatVFX3D.spawn_shockwave_ring(get_parent(), global_position, proj_color, 0.3, aoe_radius * 1.15, 0.28)
			CombatVFX3D.spawn_hit_sparks(get_parent(), global_position, direction, proj_color, 10)
			# Cầu pháp thuật nổ lan AOE trúng các quái xung quanh
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.has_method("take_damage"):
					if e.global_position.distance_to(global_position) <= aoe_radius:
						var push_dir: Vector3 = (e.global_position - global_position).normalized()
						e.take_damage(damage, push_dir * knockback_force, is_crit)
		else:
			CombatVFX3D.spawn_hit_sparks(get_parent(), body.global_position, direction, proj_color, 7)
			body.take_damage(damage, direction * knockback_force, is_crit)
		queue_free()
	elif body.is_in_group("breakables") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
