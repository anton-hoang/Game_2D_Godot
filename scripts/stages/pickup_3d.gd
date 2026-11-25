class_name Pickup3D
extends Area3D
## Vật phẩm rơi ra khi tiêu diệt quái vật:
## - "hp": Bình máu đỏ (+28 HP)
## - "energy": Tinh thể năng lượng xanh (+35 MP/Energy)
## - "gold": Đồng vàng (+Vàng dùng để nâng cấp)

var pickup_type: String = "gold" # "gold" | "hp" | "energy" | "weapon" | "bag_item"
var amount: int = 10
var item_id: String = "" # Dùng cho rơi Vũ Khí ngẫu nhiên hoặc Đan Dược vào Rương Đồ
var _time: float = 0.0
var _sprite: Sprite3D


func _ready() -> void:
	add_to_group("pickups")
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.85
	col.shape = sphere
	add_child(col)

	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = 0.052 if pickup_type == "weapon" else 0.045
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	match pickup_type:
		"hp":
			_sprite.texture = PixelArtGenerator.get_prop_texture("pickup_hp")
		"energy":
			_sprite.texture = PixelArtGenerator.get_prop_texture("pickup_mp")
		"weapon":
			_sprite.texture = PixelArtGenerator.get_prop_texture("pickup_weapon")
		"bag_item":
			_sprite.texture = PixelArtGenerator.get_prop_texture("pickup_potion")
		_:
			_sprite.texture = PixelArtGenerator.get_prop_texture("pickup_gold")
	add_child(_sprite)

	var light := OmniLight3D.new()
	light.light_color = Color(0.95, 0.55, 1.0) if pickup_type == "weapon" else (Color(0.35, 0.95, 0.65) if pickup_type == "bag_item" else (Color(1.0, 0.35, 0.4) if pickup_type == "hp" else (Color(0.3, 0.75, 1.0) if pickup_type == "energy" else Color(1.0, 0.82, 0.25))))
	light.light_energy = 2.0 if pickup_type == "weapon" else 1.1
	light.omni_range = 3.5 if pickup_type == "weapon" else 2.4
	add_child(light)

	if pickup_type == "weapon" and SaveManager.WEAPON_CATALOG.has(item_id):
		var lbl := Label3D.new()
		WuxiaFontTheme.style_label_3d(lbl)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.pixel_size = 0.0085
		lbl.font_size = 26
		lbl.outline_size = 8
		lbl.position = Vector3(0.0, 1.25, 0.0)
		lbl.modulate = SaveManager.WEAPON_CATALOG[item_id]["color"]
		lbl.text = "★ RƠI VŨ KHÍ: " + str(SaveManager.WEAPON_CATALOG[item_id]["name"])
		add_child(lbl)

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
	collect_by(body)


## Cho phép cả Player lẫn Bạn Đồng Hành Linh Thú tự động nhặt vật phẩm này
func collect_by(player_body: Node) -> void:
	if is_queued_for_deletion():
		return
	AudioManager.play_sfx("pickup")
	match pickup_type:
		"hp":
			if player_body and player_body.has_method("heal"):
				player_body.heal(float(amount))
		"energy":
			if player_body and player_body.has_method("add_energy"):
				player_body.add_energy(float(amount))
			DamageNumber3D.spawn(get_parent(), global_position, amount, false, false, "+" + str(amount) + " MP")
		"gold":
			SaveManager.add_gold(amount)
			GameManager.add_score(amount * 5)
			DamageNumber3D.spawn(get_parent(), global_position, amount, true, false, "+" + str(amount) + " VÀNG")
		"weapon":
			AudioManager.play_sfx("victory", 1.15)
			var w_name: String = str(SaveManager.WEAPON_CATALOG.get(item_id, {}).get("name", "Binh Khí"))
			if SaveManager.add_weapon_to_inventory(item_id):
				DamageNumber3D.spawn(get_parent(), global_position + Vector3(0, 0.5, 0), 0, true, false, "NHẶT VŨ KHÍ: " + w_name + "!")
			else:
				SaveManager.add_gold(35)
				DamageNumber3D.spawn(get_parent(), global_position + Vector3(0, 0.5, 0), 35, true, false, w_name + " (Trùng +35 Lượng)")
		"bag_item":
			SaveManager.add_bag_item(item_id, 1)
			var i_name: String = str(SaveManager.ITEM_CATALOG.get(item_id, {}).get("name", "Đan Dược"))
			DamageNumber3D.spawn(get_parent(), global_position + Vector3(0, 0.4, 0), 1, false, true, "VÀO RƯƠNG: +1 " + i_name)
	queue_free()
