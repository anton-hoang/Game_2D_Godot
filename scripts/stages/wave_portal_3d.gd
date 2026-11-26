class_name WavePortal3D
extends Area3D
## Cổng Dịch Chuyển Ma Pháp Cổ Trang (phong cách cổng ✦ Đi Bản Đồ ✦ trong ảnh mẫu):
## - Khung cổng gỗ chạm 2 trụ + xà ngang mái cong nhẹ + biển gỗ viền vàng gắn gọn trên thanh ngang (không bao giờ bị tràn màn hình!).
## - 2 đèn lồng vàng ấm treo 2 bên trụ cổng.
## - Màn sáng ma pháp dọc bán trong suốt + 2 vòng pháp trận xoay trên mặt đất phát sáng dịu (không chói trắng).

signal portal_entered

var _outer_ring: MeshInstance3D
var _inner_ring: MeshInstance3D
var _vortex_mesh: MeshInstance3D
var _core_orb: MeshInstance3D
var _pillar_light: OmniLight3D
var _label_3d: Label3D
var _time: float = 0.0
var _active: bool = false
var _portal_color: Color = Color(0.26, 0.72, 1.0)


func _ready() -> void:
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.55
	cyl.height = 2.8
	col.shape = cyl
	col.position = Vector3(0.0, 1.4, 0.0)
	add_child(col)

	_build_archway_frame()
	_build_arcane_vortex()

	body_entered.connect(_on_body_entered)
	set_portal_active(false)


func _build_archway_frame() -> void:
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.26, 0.14, 0.09)
	wood_mat.roughness = 0.78

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.78, 0.34)
	gold_mat.metallic = 0.65
	gold_mat.roughness = 0.35

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.42, 0.40, 0.50)
	stone_mat.roughness = 0.85

	var plaque_mat := StandardMaterial3D.new()
	plaque_mat.albedo_color = Color(0.16, 0.09, 0.07)
	plaque_mat.roughness = 0.65

	# 2 Đế đá & 2 Trụ gỗ chạm dựng 2 bên màn dịch chuyển
	for sx: float in [-1.45, 1.45]:
		_add_box(Vector3(0.48, 0.36, 0.48), Vector3(sx, 0.18, 0.0), stone_mat)
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.12
		cm.bottom_radius = 0.14
		cm.height = 2.85
		post.mesh = cm
		post.position = Vector3(sx, 1.58, 0.0)
		post.material_override = wood_mat
		add_child(post)

		# Tay treo đèn lồng giấy vàng ấm 2 bên ngoài trụ cổng
		var arm_x: float = sx + (0.34 if sx > 0.0 else -0.34)
		_add_box(Vector3(0.60, 0.10, 0.10), Vector3(sx + (0.20 if sx > 0.0 else -0.20), 2.55, 0.0), wood_mat)
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color(1.0, 0.84, 0.40)
		lmat.emission_enabled = true
		lmat.emission = Color(1.0, 0.62, 0.20)
		lmat.emission_energy_multiplier = 1.65
		var lant := MeshInstance3D.new()
		var lcm := CylinderMesh.new()
		lcm.top_radius = 0.14
		lcm.bottom_radius = 0.14
		lcm.height = 0.42
		lant.mesh = lcm
		lant.position = Vector3(arm_x, 2.22, 0.0)
		lant.material_override = lmat
		add_child(lant)
		_add_box(Vector3(0.32, 0.07, 0.32), Vector3(arm_x, 2.45, 0.0), wood_mat)
		_add_box(Vector3(0.28, 0.07, 0.28), Vector3(arm_x, 1.98, 0.0), wood_mat)

	# Xà ngang 2 tầng + 2 đầu xà vểnh nhẹ kiểu cổng cổ trang
	_add_box(Vector3(3.65, 0.18, 0.24), Vector3(0.0, 2.75, 0.0), wood_mat)
	_add_box(Vector3(4.15, 0.20, 0.34), Vector3(0.0, 3.05, 0.0), wood_mat)
	for ux: float in [-2.18, 2.18]:
		var tip := _add_box(Vector3(0.45, 0.16, 0.34), Vector3(ux, 3.16, 0.0), wood_mat)
		tip.rotation_degrees.z = -22.0 if ux < 0.0 else 22.0

	# Biển gỗ viền vàng gọn đẹp gắn ngay trên đỉnh cổng ("✦ Đi Bản Đồ ✦")
	_add_box(Vector3(2.55, 0.66, 0.14), Vector3(0.0, 3.02, 0.20), gold_mat)
	_add_box(Vector3(2.38, 0.52, 0.17), Vector3(0.0, 3.02, 0.22), plaque_mat)

	_label_3d = Label3D.new()
	WuxiaFontTheme.style_label_3d(_label_3d)
	_label_3d.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_label_3d.position = Vector3(0.0, 3.02, 0.34)
	_label_3d.pixel_size = 0.0085
	_label_3d.font_size = 24
	_label_3d.outline_size = 7
	_label_3d.modulate = Color(1.0, 0.90, 0.48)
	_label_3d.text = "✦ Đi Bản Đồ ✦"
	add_child(_label_3d)


func _build_arcane_vortex() -> void:
	# Vòng pháp trận ngoài & trong xoay ngược chiều trên mặt đá (giữ emission dịu để không bị chói trắng)
	_outer_ring = MeshInstance3D.new()
	var t_out := TorusMesh.new()
	t_out.inner_radius = 1.28
	t_out.outer_radius = 1.46
	_outer_ring.mesh = t_out
	_outer_ring.position = Vector3(0.0, 0.08, 0.0)
	add_child(_outer_ring)

	_inner_ring = MeshInstance3D.new()
	var t_in := TorusMesh.new()
	t_in.inner_radius = 0.78
	t_in.outer_radius = 0.94
	_inner_ring.mesh = t_in
	_inner_ring.position = Vector3(0.0, 0.10, 0.0)
	add_child(_inner_ring)

	# Màn năng lượng ma pháp thẳng đứng trong suốt ánh xanh lam lung linh giống ảnh mẫu!
	_vortex_mesh = MeshInstance3D.new()
	var vcyl := CylinderMesh.new()
	vcyl.top_radius = 1.05
	vcyl.bottom_radius = 1.15
	vcyl.height = 2.55
	_vortex_mesh.mesh = vcyl
	_vortex_mesh.position = Vector3(0.0, 1.32, 0.0)
	add_child(_vortex_mesh)

	# Viên tinh thể sáng giữa màn cổng ma pháp
	_core_orb = MeshInstance3D.new()
	var orb := SphereMesh.new()
	orb.radius = 0.24
	orb.height = 0.48
	_core_orb.mesh = orb
	_core_orb.position = Vector3(0.0, 1.40, 0.0)
	add_child(_core_orb)

	_pillar_light = OmniLight3D.new()
	_pillar_light.position = Vector3(0.0, 1.45, 0.4)
	_pillar_light.light_energy = 2.2
	_pillar_light.omni_range = 6.2
	_pillar_light.shadow_enabled = false
	add_child(_pillar_light)

	_apply_portal_color(_portal_color)


func _apply_portal_color(col: Color) -> void:
	_portal_color = col

	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(col.r, col.g, col.b, 0.90)
	ring_mat.emission_enabled = true
	ring_mat.emission = col
	ring_mat.emission_energy_multiplier = 1.35
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if _outer_ring:
		_outer_ring.material_override = ring_mat
	if _inner_ring:
		_inner_ring.material_override = ring_mat

	var vmat := StandardMaterial3D.new()
	vmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vmat.albedo_color = Color(col.r, col.g, col.b, 0.34)
	vmat.emission_enabled = true
	vmat.emission = col.lightened(0.15)
	vmat.emission_energy_multiplier = 1.20
	vmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if _vortex_mesh:
		_vortex_mesh.material_override = vmat

	var omat := StandardMaterial3D.new()
	omat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	omat.albedo_color = Color(0.92, 0.97, 1.0, 0.92)
	omat.emission_enabled = true
	omat.emission = col.lightened(0.40)
	omat.emission_energy_multiplier = 1.55
	omat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if _core_orb:
		_core_orb.material_override = omat

	if _pillar_light:
		_pillar_light.light_color = col


func set_portal_style(title_text: String, portal_color: Color, label_col: Color = Color(1.0, 0.90, 0.48)) -> void:
	_apply_portal_color(portal_color)
	if _label_3d:
		_label_3d.text = title_text
		_label_3d.modulate = label_col


func set_portal_active(active: bool, next_wave_num: int = 2, is_boss_wave: bool = false) -> void:
	_active = active
	visible = active
	monitoring = active
	if active:
		AudioManager.play_sfx("gate")
		if is_boss_wave:
			set_portal_style("✦ CỔNG BOSS ✦", Color(0.96, 0.28, 0.42), Color(1.0, 0.72, 0.56))
		else:
			set_portal_style("✦ SANG ĐỢT %d ✦" % next_wave_num, Color(0.26, 0.74, 1.0), Color(0.86, 0.96, 1.0))


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_time += delta * 2.4
	if _outer_ring:
		_outer_ring.rotation.y += delta * 1.1
		_outer_ring.scale = Vector3.ONE * (1.0 + sin(_time) * 0.04)
	if _inner_ring:
		_inner_ring.rotation.y -= delta * 1.8
	if _vortex_mesh:
		_vortex_mesh.rotation.y += delta * 1.4
		var sc: float = 0.96 + sin(_time * 1.6) * 0.04
		_vortex_mesh.scale = Vector3(sc, 1.0, sc)
	if _core_orb:
		_core_orb.position.y = 1.40 + sin(_time * 1.8) * 0.14
		var os: float = 0.92 + sin(_time * 2.4) * 0.14
		_core_orb.scale = Vector3.ONE * os


func _add_box(sz: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	return mi


func _on_body_entered(body: Node) -> void:
	if not _active or body == null or not body.is_in_group("player"):
		return
	set_portal_active(false)
	if body.has_method("heal"):
		body.heal(18.0)
	if body.has_method("add_energy"):
		body.add_energy(25.0)
	portal_entered.emit()
