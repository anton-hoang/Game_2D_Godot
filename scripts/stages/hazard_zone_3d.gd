class_name HazardZone3D
extends Area3D
## Bẫy địa hình tương tác 3D:
## - "water_hazard" (Suối nước sâu): Đánh bay quái rơi xuống suối sẽ làm quái bị đuối nước / nhận sát thương liên tục & giảm tốc.
## - "spike_pit" (Hố gai sắt): Quái bị đẩy lùi hoặc bước vào hố gai sẽ bị đâm sát thương mạnh và hất văng.

var hazard_type: String = "spike_pit" # "water_hazard" | "spike_pit"
var zone_size: Vector3 = Vector3(3.2, 1.2, 2.8)
var damage_per_tick: int = 24
var _cooldowns: Dictionary = {}


func _ready() -> void:
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = zone_size
	col.shape = box
	col.position = Vector3(0.0, zone_size.y * 0.5, 0.0)
	add_child(col)

	if hazard_type == "spike_pit":
		_build_spike_visuals()


func _build_spike_visuals() -> void:
	var pit_mat := StandardMaterial3D.new()
	pit_mat.albedo_color = Color(0.07, 0.06, 0.09)
	pit_mat.roughness = 0.95

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.28, 0.27, 0.32)

	var spike_mat := StandardMaterial3D.new()
	spike_mat.albedo_color = Color(0.76, 0.80, 0.86)
	spike_mat.metallic = 0.8
	spike_mat.roughness = 0.3

	# Nền hố tối & khung đá cảnh báo
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(zone_size.x, 0.12, zone_size.z)
	base.mesh = bm
	base.position = Vector3(0.0, 0.04, 0.0)
	base.material_override = pit_mat
	add_child(base)

	var rim := MeshInstance3D.new()
	var rbm := BoxMesh.new()
	rbm.size = Vector3(zone_size.x + 0.3, 0.10, zone_size.z + 0.3)
	rim.mesh = rbm
	rim.position = Vector3(0.0, 0.02, 0.0)
	rim.material_override = frame_mat
	add_child(rim)

	# 12 mũi gai sắt nhọn bên trong hố
	for ix in range(-1, 2):
		for iz in range(-1, 2):
			var sp := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.02
			cone.bottom_radius = 0.16
			cone.height = 0.68
			sp.mesh = cone
			sp.position = Vector3(float(ix) * (zone_size.x * 0.28), 0.36, float(iz) * (zone_size.z * 0.28))
			sp.material_override = spike_mat
			add_child(sp)


func _physics_process(delta: float) -> void:
	# Giảm hồi chiêu từng đối tượng
	for id_key in _cooldowns.keys():
		_cooldowns[id_key] = float(_cooldowns[id_key]) - delta
		if float(_cooldowns[id_key]) <= 0.0:
			_cooldowns.erase(id_key)

	for body in get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		var uid := body.get_instance_id()
		if _cooldowns.has(uid):
			continue

		if body.is_in_group("enemies") and body.has_method("take_damage"):
			if hazard_type == "water_hazard":
				# Quái rơi xuống suối nước chịu sát thương đuối nước mạnh
				body.take_damage(damage_per_tick, Vector3(0.0, 0.0, 0.0), true)
				DamageNumber3D.spawn(get_parent(), body.global_position + Vector3(0, 0.7, 0), damage_per_tick, false, false, "RƠI SUỐI! -" + str(damage_per_tick))
				_cooldowns[uid] = 0.85
			else:
				# Quái trúng hố gai sắt bị sát thương chí mạng và hất nhẹ
				body.take_damage(damage_per_tick, Vector3(randf_range(-4, 4), 0.0, randf_range(-4, 4)), true)
				DamageNumber3D.spawn(get_parent(), body.global_position + Vector3(0, 0.7, 0), damage_per_tick, true, false, "HỐ GAI! -" + str(damage_per_tick))
				_cooldowns[uid] = 0.75
		elif body.is_in_group("player") and hazard_type == "spike_pit" and body.has_method("take_damage"):
			# Người chơi bước vào hố gai cũng nhận nhẹ sát thương (chỉ khi đang chiến đấu)
			if GameManager.is_stage_active:
				body.take_damage(10.0, Vector3(0.0, 0.0, 4.0))
				_cooldowns[uid] = 1.1
