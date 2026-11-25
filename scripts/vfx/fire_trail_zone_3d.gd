class_name FireTrailZone3D
extends Area3D
## Vệt lửa của Bùa Cổ Ngữ "Hỏa Viêm Khinh Công":
## Khi người chơi thực hiện Dash (L), để lại các đốm lửa cháy sáng trên đường đá gây sát thương thiêu đốt quái đuổi theo.

var burn_damage: int = 12
var duration: float = 3.2
var _tick_cd: Dictionary = {}
var _flame_mesh: MeshInstance3D


func _ready() -> void:
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.05
	col.shape = sph
	col.position = Vector3(0.0, 0.4, 0.0)
	add_child(col)

	_flame_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.48
	sm.height = 0.65
	_flame_mesh.mesh = sm
	_flame_mesh.position = Vector3(0.0, 0.25, 0.0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.42, 0.10, 0.92)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.46, 0.08)
	mat.emission_energy_multiplier = 4.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flame_mesh.material_override = mat
	add_child(_flame_mesh)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.65, 0.0)
	light.light_color = Color(1.0, 0.45, 0.12)
	light.light_energy = 1.8
	light.omni_range = 3.6
	add_child(light)


func _physics_process(delta: float) -> void:
	duration -= delta
	if _flame_mesh:
		_flame_mesh.scale = Vector3.ONE * clampf(duration * 0.65, 0.15, 1.1)
	if duration <= 0.0:
		queue_free()
		return

	for uid in _tick_cd.keys():
		_tick_cd[uid] = float(_tick_cd[uid]) - delta
		if float(_tick_cd[uid]) <= 0.0:
			_tick_cd.erase(uid)

	for body in get_overlapping_bodies():
		if is_instance_valid(body) and body.is_in_group("enemies") and body.has_method("take_damage"):
			var uid := body.get_instance_id()
			if not _tick_cd.has(uid):
				body.take_damage(burn_damage, Vector3.ZERO, false)
				DamageNumber3D.spawn(get_parent(), body.global_position + Vector3(0, 0.5, 0), burn_damage, false, false, "THIÊU ĐỐT -" + str(burn_damage))
				_tick_cd[uid] = 0.55
