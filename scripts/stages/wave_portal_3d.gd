class_name WavePortal3D
extends Area3D
## Cổng ánh sáng mở ra khi người chơi tiêu diệt hết một đợt quái (Wave).
## Khi người chơi bước vào cổng, đợt quái tiếp theo sẽ bắt đầu (và hồi nhẹ máu/năng lượng).

signal portal_entered

var _ring_mesh: MeshInstance3D
var _label_3d: Label3D
var _time: float = 0.0
var _active: bool = false


func _ready() -> void:
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.45
	cyl.height = 2.5
	col.shape = cyl
	col.position = Vector3(0.0, 1.25, 0.0)
	add_child(col)

	_ring_mesh = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.35
	_ring_mesh.mesh = torus
	_ring_mesh.position = Vector3(0.0, 0.15, 0.0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.92, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.85, 1.0)
	mat.emission_energy_multiplier = 3.2
	_ring_mesh.material_override = mat
	add_child(_ring_mesh)

	var pillar_light := OmniLight3D.new()
	pillar_light.position = Vector3(0.0, 1.5, 0.0)
	pillar_light.light_color = Color(0.35, 0.92, 1.0)
	pillar_light.light_energy = 2.8
	pillar_light.omni_range = 6.5
	add_child(pillar_light)

	_label_3d = Label3D.new()
	WuxiaFontTheme.style_label_3d(_label_3d)
	_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_3d.position = Vector3(0.0, 2.35, 0.0)
	_label_3d.pixel_size = 0.011
	_label_3d.font_size = 34
	_label_3d.outline_size = 10
	_label_3d.modulate = Color(0.55, 0.98, 1.0)
	_label_3d.text = "CỔNG ĐỢT TIẾP THEO\n(Bước vào để tiếp tục)"
	add_child(_label_3d)

	body_entered.connect(_on_body_entered)
	set_portal_active(false)


func set_portal_active(active: bool, next_wave_num: int = 2, is_boss_wave: bool = false) -> void:
	_active = active
	visible = active
	monitoring = active
	if active:
		AudioManager.play_sfx("gate")
		if is_boss_wave:
			_label_3d.text = "CỔNG BOSS CUỐI CHƯƠNG!\n(Bước vào khi đã sẵn sàng)"
			_label_3d.modulate = Color(1.0, 0.45, 0.45)
		else:
			_label_3d.text = "CỔNG SANG ĐỢT " + str(next_wave_num) + "\n(Bước vào để mở đợt tiếp)"
			_label_3d.modulate = Color(0.55, 0.98, 1.0)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_time += delta * 2.5
	if _ring_mesh:
		_ring_mesh.rotation.y += delta * 1.8
		_ring_mesh.scale = Vector3.ONE * (1.0 + sin(_time) * 0.06)
	if _label_3d:
		_label_3d.position.y = 2.35 + sin(_time * 1.4) * 0.14


func _on_body_entered(body: Node) -> void:
	if not _active or body == null or not body.is_in_group("player"):
		return
	set_portal_active(false)
	if body.has_method("heal"):
		body.heal(18.0)
	if body.has_method("add_energy"):
		body.add_energy(25.0)
	portal_entered.emit()
