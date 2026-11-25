class_name EnemyProjectile3D
extends Area3D
## Đạn phép / cầu năng lượng của quái tầm xa (Ranged) và Boss bắn về phía người chơi.

var direction: Vector3 = Vector3.RIGHT
var speed: float = 9.0
var damage: float = 14.0
var lifetime: float = 3.8
var orb_color: Color = Color(0.55, 0.25, 1.0)


func _ready() -> void:
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.32
	col.shape = sphere
	add_child(col)

	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.48
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = orb_color
	mat.emission_enabled = true
	mat.emission = orb_color
	mat.emission_energy_multiplier = 3.0
	mi.material_override = mat
	add_child(mi)

	var light := OmniLight3D.new()
	light.light_color = orb_color
	light.light_energy = 1.4
	light.omni_range = 2.8
	add_child(light)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, direction * 5.5)
		queue_free()
	elif body is StaticBody3D:
		queue_free()
