class_name SpiritBolt3D
extends Area3D
## Đạn Linh Khí do Tiểu Hồ Ly / Tiên Hạc bắn ra hỗ trợ người chơi:
## Tự động bay truy đuổi nhẹ về phía quái vật mục tiêu, phát ánh sáng ngọc bích/hồng ngọc và gây sát thương.

var target_enemy: Node3D
var direction: Vector3 = Vector3.RIGHT
var speed: float = 12.5
var damage: int = 16
var bolt_color: Color = Color(0.45, 0.96, 0.85)
var lifetime: float = 2.6


func _ready() -> void:
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.34
	col.shape = sph
	add_child(col)

	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = bolt_color
	mat.emission_enabled = true
	mat.emission = bolt_color
	mat.emission_energy_multiplier = 3.8
	mi.material_override = mat
	add_child(mi)

	var light := OmniLight3D.new()
	light.light_color = bolt_color
	light.light_energy = 1.4
	light.omni_range = 2.8
	add_child(light)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if target_enemy and is_instance_valid(target_enemy):
		var to_t := (target_enemy.global_position + Vector3(0.0, 0.85, 0.0)) - global_position
		if to_t.length() > 0.1:
			direction = direction.lerp(to_t.normalized(), clampf(8.5 * delta, 0.0, 1.0)).normalized()

	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, direction * 3.0, false)
		DamageNumber3D.spawn(get_parent(), body.global_position + Vector3(0.0, 0.55, 0.0), damage, false, false, "LINH KHÍ -" + str(damage))
		queue_free()
