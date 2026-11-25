class_name BreakableProp3D
extends StaticBody3D
## Vật thể 3D phá hủy được (Thùng rượu gỗ / Hòm hàng ven đường):
## - Khi người chơi chém trúng sẽ rung lắc và vỡ tung, rơi ra Vàng, Bình máu hoặc Tinh thể năng lượng.

var prop_kind: String = "barrel" # "barrel" | "crate"
var max_hp: int = 25
var current_hp: int = 25
var _visual_root: Node3D
var _broken: bool = false


func _ready() -> void:
	add_to_group("breakables")
	current_hp = max_hp
	_build_mesh()


func _build_mesh() -> void:
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.95, 1.05, 0.95)
	col.shape = box
	col.position = Vector3(0.0, 0.52, 0.0)
	add_child(col)

	_visual_root = Node3D.new()
	add_child(_visual_root)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.36, 0.22, 0.13) if prop_kind == "barrel" else Color(0.46, 0.30, 0.16)
	wood_mat.roughness = 0.88

	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.18, 0.20, 0.24)
	iron_mat.metallic = 0.6

	if prop_kind == "barrel":
		var cyl := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.42
		cm.bottom_radius = 0.44
		cm.height = 1.05
		cyl.mesh = cm
		cyl.position = Vector3(0.0, 0.52, 0.0)
		cyl.material_override = wood_mat
		_visual_root.add_child(cyl)

		for ry: float in [0.28, 0.78]:
			var band := MeshInstance3D.new()
			var bcm := CylinderMesh.new()
			bcm.top_radius = 0.45
			bcm.bottom_radius = 0.45
			bcm.height = 0.09
			band.mesh = bcm
			band.position = Vector3(0.0, ry, 0.0)
			band.material_override = iron_mat
			_visual_root.add_child(band)
	else:
		var crate := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.02, 1.0, 1.02)
		crate.mesh = bm
		crate.position = Vector3(0.0, 0.50, 0.0)
		crate.material_override = wood_mat
		_visual_root.add_child(crate)

		var trim := MeshInstance3D.new()
		var tbm := BoxMesh.new()
		tbm.size = Vector3(1.06, 0.14, 1.06)
		trim.mesh = tbm
		trim.position = Vector3(0.0, 0.50, 0.0)
		trim.material_override = iron_mat
		_visual_root.add_child(trim)


func take_damage(dmg: int) -> void:
	if _broken:
		return
	current_hp -= dmg
	AudioManager.play_sfx("hit", 1.25)
	DamageNumber3D.spawn(get_parent(), global_position, dmg, false, false)

	if current_hp <= 0:
		_break_and_drop()
	else:
		# Rung lắc khi bị chém nhưng chưa vỡ
		var tw := create_tween()
		tw.tween_property(_visual_root, "scale", Vector3(1.18, 0.85, 1.18), 0.06)
		tw.tween_property(_visual_root, "scale", Vector3.ONE, 0.10)


func _break_and_drop() -> void:
	_broken = true
	AudioManager.play_sfx("hurt", 1.35)

	# Rơi ngẫu nhiên Vàng, Bình máu hoặc Năng lượng
	var drop := Pickup3D.new()
	var r := randf()
	if r < 0.45:
		drop.pickup_type = "gold"
		drop.amount = randi_range(12, 22)
	elif r < 0.78:
		drop.pickup_type = "hp"
		drop.amount = 30
	else:
		drop.pickup_type = "energy"
		drop.amount = 40

	if get_parent():
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector3(0.0, 0.25, 0.0)

	# Hiệu ứng vỡ nhỏ dần rồi biến mất
	var tw := create_tween()
	tw.tween_property(_visual_root, "scale", Vector3(1.3, 0.1, 1.3), 0.16)
	tw.tween_callback(queue_free)
