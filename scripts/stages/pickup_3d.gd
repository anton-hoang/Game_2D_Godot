class_name Pickup3D
extends Area3D
## Vật phẩm rơi ra khi tiêu diệt quái vật:
## - "hp": Bình máu đỏ (+28 HP)
## - "energy": Tinh thể năng lượng xanh (+35 MP/Energy)
## - "gold": Đồng vàng (+Vàng dùng để nâng cấp)

var pickup_type: String = "gold"
var amount: int = 10
var _time: float = 0.0
var _sprite: Sprite3D


func _ready() -> void:
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.75
	col.shape = sphere
	add_child(col)

	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = 0.045
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	match pickup_type:
		"hp":
			_sprite.texture = PixelArtGenerator.get_prop_texture("pickup_hp")
		"energy":
			_sprite.texture = PixelArtGenerator.get_prop_texture("pickup_mp")
		_:
			_sprite.texture = PixelArtGenerator.get_prop_texture("pickup_gold")
	add_child(_sprite)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.35, 0.4) if pickup_type == "hp" else (Color(0.3, 0.75, 1.0) if pickup_type == "energy" else Color(1.0, 0.82, 0.25))
	light.light_energy = 1.1
	light.omni_range = 2.4
	add_child(light)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_time += delta * 4.0
	if _sprite:
		_sprite.position.y = 0.45 + sin(_time) * 0.14

	# Tự động hút nhẹ về phía người chơi khi lại gần
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player and is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if dist < 3.2:
			global_position = global_position.move_toward(player.global_position, 9.5 * delta)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	AudioManager.play_sfx("pickup")
	match pickup_type:
		"hp":
			if body.has_method("heal"):
				body.heal(float(amount))
		"energy":
			if body.has_method("add_energy"):
				body.add_energy(float(amount))
			DamageNumber3D.spawn(get_parent(), global_position, amount, false, false, "+" + str(amount) + " MP")
		"gold":
			SaveManager.add_gold(amount)
			GameManager.add_score(amount * 5)
			DamageNumber3D.spawn(get_parent(), global_position, amount, true, false, "+" + str(amount) + " VÀNG")
	queue_free()
