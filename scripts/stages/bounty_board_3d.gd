class_name BountyBoard3D
extends Area3D
## Bảng Truy Nã (Bounty Board) bằng gỗ mái ngói đặt ngay quảng trường giữa Làng Windferry:
## - Gắn các tờ cáo thị giấy gió & dấu triện đỏ.
## - Khi người chơi lại gần và nhấn [E] sẽ mở Bảng Nhiệm Vụ Dân Làng & Kho Danh Hiệu / Khăn Choàng!

signal board_interacted

var _player_near: bool = false
var _prompt_label: Label3D
var _time: float = 0.0


func _ready() -> void:
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.6
	col.shape = sph
	col.position = Vector3(0.0, 1.0, 0.0)
	add_child(col)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.28, 0.16, 0.09)
	wood_mat.roughness = 0.85

	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.14, 0.18, 0.26)

	var paper_mat := StandardMaterial3D.new()
	paper_mat.albedo_color = Color(0.95, 0.89, 0.72)

	var seal_mat := StandardMaterial3D.new()
	seal_mat.albedo_color = Color(0.86, 0.16, 0.16)
	seal_mat.emission_enabled = true
	seal_mat.emission = Color(0.82, 0.14, 0.14)
	seal_mat.emission_energy_multiplier = 1.2

	# 2 trụ gỗ + Bảng thông báo + Mái ngói che mưa
	_add_box(Vector3(0.20, 2.2, 0.20), Vector3(-1.05, 1.1, 0.0), wood_mat)
	_add_box(Vector3(0.20, 2.2, 0.20), Vector3(1.05, 1.1, 0.0), wood_mat)
	_add_box(Vector3(2.25, 1.25, 0.14), Vector3(0.0, 1.45, 0.0), wood_mat)
	_add_box(Vector3(2.70, 0.22, 0.95), Vector3(0.0, 2.25, 0.0), roof_mat)

	# 3 tờ cáo thị giấy gió dán trên bảng kèm ấn triện đỏ
	for px: float in [-0.62, 0.0, 0.62]:
		_add_box(Vector3(0.46, 0.62, 0.05), Vector3(px, 1.46, 0.09), paper_mat)
		_add_box(Vector3(0.14, 0.14, 0.06), Vector3(px, 1.70, 0.11), seal_mat)

	var title_lbl := Label3D.new()
	WuxiaFontTheme.style_label_3d(title_lbl)
	title_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_lbl.pixel_size = 0.0085
	title_lbl.font_size = 28
	title_lbl.outline_size = 8
	title_lbl.position = Vector3(0.0, 2.75, 0.0)
	title_lbl.modulate = Color(1.0, 0.86, 0.36)
	title_lbl.text = "BẢNG TRUY NÃ & TỦ KHĂN CHOÀNG"
	add_child(title_lbl)

	_prompt_label = Label3D.new()
	WuxiaFontTheme.style_label_3d(_prompt_label)
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.pixel_size = 0.009
	_prompt_label.font_size = 30
	_prompt_label.outline_size = 9
	_prompt_label.position = Vector3(0.0, 3.15, 0.0)
	_prompt_label.modulate = Color(0.55, 0.98, 1.0)
	_prompt_label.text = "[E] Xem Nhiệm Vụ Dân Làng"
	_prompt_label.visible = false
	add_child(_prompt_label)

	body_entered.connect(func(b: Node) -> void:
		if b and b.is_in_group("player"):
			_player_near = true
			_prompt_label.visible = true
	)
	body_exited.connect(func(b: Node) -> void:
		if b and b.is_in_group("player"):
			_player_near = false
			_prompt_label.visible = false
	)


func _physics_process(delta: float) -> void:
	_time += delta * 3.0
	if _player_near and _prompt_label:
		_prompt_label.position.y = 3.15 + sin(_time) * 0.09
		if Input.is_action_just_pressed("interact") and not get_tree().paused:
			AudioManager.play_sfx("pickup", 0.9)
			board_interacted.emit()


func _add_box(sz: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
