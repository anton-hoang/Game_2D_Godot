class_name VillageNPC3D
extends Area3D
## NPC đứng trong Làng Windferry (Thợ Rèn, Chủ Quán Trọ, Thương Nhân):
## - Hiển thị Sprite3D billboard có đổ bóng thật và biển báo "[E] Nói chuyện" khi người chơi lại gần.
## - Khi nhấn E sẽ phát tín hiệu mở Hộp thoại Chân dung (Dialogue Portrait) kèm hành động dịch vụ tương ứng.

signal interacted(npc_data: Dictionary)

var npc_role: String = "blacksmith" # "blacksmith" | "innkeeper" | "merchant"
var npc_name: String = "Thợ Rèn Gorn"
var npc_title: String = "Lò Rèn Windferry"
var dialogue_text: String = "Chào lữ khách! Đưa vàng đây, ta sẽ tôi luyện lại thanh kiếm của ngươi."
var action_label: String = "Mở Lò Rèn Nâng Cấp"

var _player_in_range: bool = false
var _prompt_label: Label3D
var _sprite: Sprite3D
var _time: float = 0.0


func _ready() -> void:
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.4
	col.shape = sphere
	col.position = Vector3(0.0, 0.8, 0.0)
	add_child(col)

	_sprite = Sprite3D.new()
	_sprite.texture = PixelArtGenerator.get_npc_sprite_texture(npc_role)
	_sprite.pixel_size = 0.044
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.shaded = true
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	_sprite.position = Vector3(0.0, 0.92, 0.0)
	add_child(_sprite)

	# Nhãn tên NPC luôn hiện mờ phía trên
	var name_lbl := Label3D.new()
	WuxiaFontTheme.style_label_3d(name_lbl)
	name_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_lbl.pixel_size = 0.0085
	name_lbl.font_size = 28
	name_lbl.outline_size = 8
	name_lbl.position = Vector3(0.0, 2.05, 0.0)
	name_lbl.modulate = Color(1.0, 0.88, 0.45)
	name_lbl.text = npc_name
	add_child(name_lbl)

	# Biển báo tương tác chỉ hiện khi người chơi bước tới gần
	_prompt_label = Label3D.new()
	WuxiaFontTheme.style_label_3d(_prompt_label)
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.pixel_size = 0.009
	_prompt_label.font_size = 30
	_prompt_label.outline_size = 9
	_prompt_label.position = Vector3(0.0, 2.45, 0.0)
	_prompt_label.modulate = Color(0.50, 0.96, 1.0)
	_prompt_label.text = "[E] Nói chuyện"
	_prompt_label.visible = false
	add_child(_prompt_label)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_time += delta * 2.8
	if _sprite:
		_sprite.position.y = 0.92 + sin(_time) * 0.03
	if _player_in_range and _prompt_label:
		_prompt_label.position.y = 2.45 + sin(_time * 1.6) * 0.08
		if Input.is_action_just_pressed("interact") and not get_tree().paused:
			AudioManager.play_sfx("pickup", 0.85)
			interacted.emit({
				"role": npc_role,
				"name": npc_name,
				"title": npc_title,
				"text": dialogue_text,
				"action_label": action_label,
			})


func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = true
		if _prompt_label:
			_prompt_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = false
		if _prompt_label:
			_prompt_label.visible = false
