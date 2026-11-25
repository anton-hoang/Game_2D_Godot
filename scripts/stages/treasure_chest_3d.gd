class_name TreasureChest3D
extends Area3D
## Rương báu đặt bên trong các ngôi nhà gỗ (Seamless Interior):
## Khi người chơi bước vào nhà, tiến lại gần rương và nhấn [E] để mở rương nhận Vàng + Hồi máu.

var gold_reward: int = 35
var is_opened: bool = false
var _player_near: bool = false
var _lid_mesh: MeshInstance3D
var _prompt_label: Label3D


func _ready() -> void:
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.9
	col.shape = sphere
	col.position = Vector3(0.0, 0.5, 0.0)
	add_child(col)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.45, 0.24, 0.12)
	wood_mat.roughness = 0.82

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.98, 0.80, 0.22)
	gold_mat.metallic = 0.75
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(0.95, 0.75, 0.18)
	gold_mat.emission_energy_multiplier = 0.5

	# Thân rương
	var base := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(1.1, 0.55, 0.72)
	base.mesh = bmesh
	base.position = Vector3(0.0, 0.28, 0.0)
	base.material_override = wood_mat
	add_child(base)

	# Khóa vàng mặt trước
	var lock := MeshInstance3D.new()
	var lmesh := BoxMesh.new()
	lmesh.size = Vector3(0.22, 0.26, 0.08)
	lock.mesh = lmesh
	lock.position = Vector3(0.0, 0.48, 0.38)
	lock.material_override = gold_mat
	add_child(lock)

	# Nắp rương (sẽ bật mở khi người chơi nhấn E)
	_lid_mesh = MeshInstance3D.new()
	var lid_bm := BoxMesh.new()
	lid_bm.size = Vector3(1.14, 0.24, 0.76)
	_lid_mesh.mesh = lid_bm
	_lid_mesh.position = Vector3(0.0, 0.66, 0.0)
	_lid_mesh.material_override = gold_mat
	add_child(_lid_mesh)

	_prompt_label = Label3D.new()
	WuxiaFontTheme.style_label_3d(_prompt_label)
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.pixel_size = 0.0085
	_prompt_label.font_size = 28
	_prompt_label.outline_size = 8
	_prompt_label.position = Vector3(0.0, 1.45, 0.0)
	_prompt_label.modulate = Color(1.0, 0.90, 0.35)
	_prompt_label.text = "[E] Mở Rương Báu"
	_prompt_label.visible = false
	add_child(_prompt_label)

	body_entered.connect(func(b: Node) -> void:
		if b and b.is_in_group("player") and not is_opened:
			_player_near = true
			_prompt_label.visible = true
	)
	body_exited.connect(func(b: Node) -> void:
		if b and b.is_in_group("player"):
			_player_near = false
			_prompt_label.visible = false
	)


func _physics_process(_delta: float) -> void:
	if _player_near and not is_opened and Input.is_action_just_pressed("interact") and not get_tree().paused:
		_open_chest()


func _open_chest() -> void:
	is_opened = true
	_prompt_label.visible = false
	AudioManager.play_sfx("victory", 1.15)
	SaveManager.add_gold(gold_reward)
	SaveManager.advance_quest("treasure_hunter", 1)
	GameManager.add_score(gold_reward * 4)

	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("heal"):
		player.heal(35.0)

	DamageNumber3D.spawn(get_parent(), global_position + Vector3(0.0, 0.5, 0.0), gold_reward, true, false, "+" + str(gold_reward) + " VÀNG!")
	var tw := create_tween()
	tw.tween_property(_lid_mesh, "rotation_degrees:x", -68.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_lid_mesh, "position:z", -0.25, 0.35)
