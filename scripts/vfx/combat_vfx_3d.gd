class_name CombatVFX3D
extends RefCounted
## Bộ hiệu ứng hình ảnh chiến đấu 3D HD-2D (Combat Juice & VFX):
## - Tàn Ảnh Khinh Công (Dash Afterimage Ghost Trail) màu ngọc bích mờ dần sau lưng Nữ Kiếm Khách.
## - Tia Lửa Va Chạm 3D (Hit Sparks) bay văng theo hướng chém + đèn chớp sáng ngắn hắt xuống nền đá.
## - Bụi Chân (Footstep Dust) nhẹ khi chạy/né.
## - Vòng Sóng Xung Kích Phản Đòn (Perfect Parry Flash) & Vỡ Khiên Phá Giáp (BREAK Shockwave).


## Tạo 1 Tàn Ảnh Khinh Công (Ghost Afterimage) tại vị trí nhân vật khi Dash (L)
static func spawn_afterimage(parent: Node, world_pos: Vector3, tex: Texture2D, flip_h: bool, pixel_sz: float, tint: Color = Color(0.38, 0.94, 0.92, 0.65)) -> void:
	if parent == null or not is_instance_valid(parent) or tex == null:
		return
	var ghost := Sprite3D.new()
	ghost.texture = tex
	ghost.flip_h = flip_h
	ghost.pixel_size = pixel_sz
	ghost.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	ghost.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ghost.shaded = false
	ghost.modulate = tint
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ghost)
	ghost.global_position = world_pos

	var tw := ghost.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "scale", Vector3(1.12, 1.04, 1.0), 0.30)
	tw.chain().tween_callback(ghost.queue_free)


## Bắn tóe 8-12 tia lửa va chạm 3D theo hướng đòn đánh kèm 1 tia chớp sáng hắt xuống đường đá!
static func spawn_hit_sparks(parent: Node, world_pos: Vector3, hit_dir: Vector3, spark_col: Color = Color(1.0, 0.84, 0.32), count: int = 8) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var base_dir := hit_dir.normalized() if hit_dir.length_squared() > 0.01 else Vector3.RIGHT
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = spark_col
	mat.emission_enabled = true
	mat.emission = spark_col
	mat.emission_energy_multiplier = 4.2

	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.07, 0.34)

	for i in range(count):
		var sp := MeshInstance3D.new()
		sp.mesh = bm
		sp.material_override = mat
		parent.add_child(sp)
		sp.global_position = world_pos + Vector3(0.0, 0.85, 0.0)

		var spread_dir := (base_dir + Vector3(randf_range(-0.9, 0.9), randf_range(0.25, 1.1), randf_range(-0.9, 0.9))).normalized()
		var target_pos := sp.global_position + spread_dir * randf_range(1.1, 2.5)
		sp.look_at(target_pos, Vector3.UP)

		var tw := sp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sp, "global_position", target_pos, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(sp, "scale", Vector3(0.1, 0.1, 0.1), 0.24)
		tw.chain().tween_callback(sp.queue_free)

	# Chớp sáng ngắn hắt xuống nền đá khi chém trúng
	_spawn_flash_light(parent, world_pos + Vector3(0.0, 0.9, 0.0), spark_col, 3.2, 5.2, 0.14)


## Vòng sóng xung kích 3D (dùng cho Perfect Parry ánh vàng, Phá Giáp BREAK ánh đỏ cam, Tuyệt Kỹ K ánh ngọc bích)
static func spawn_shockwave_ring(parent: Node, world_pos: Vector3, ring_col: Color, start_scale: float = 0.5, end_scale: float = 3.8, duration: float = 0.32) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.72
	tm.outer_radius = 1.0
	ring.mesh = tm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = ring_col
	mat.emission_enabled = true
	mat.emission = ring_col
	mat.emission_energy_multiplier = 4.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat

	parent.add_child(ring)
	ring.global_position = world_pos + Vector3(0.0, 0.45, 0.0)
	ring.scale = Vector3(start_scale, 0.35, start_scale)

	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(end_scale, 0.08, end_scale), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration)
	tw.chain().tween_callback(ring.queue_free)

	_spawn_flash_light(parent, world_pos + Vector3(0.0, 1.0, 0.0), ring_col, 4.5, 8.0, duration * 0.7)


## Cụm bụi chân pixel mờ nhỏ khi chạy nhanh hoặc khởi phát Khinh Công
static func spawn_footstep_dust(parent: Node, world_pos: Vector3, dust_col: Color = Color(0.84, 0.80, 0.72, 0.55)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = dust_col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.24

	for i in range(3):
		var puff := MeshInstance3D.new()
		puff.mesh = sm
		puff.material_override = mat
		parent.add_child(puff)
		puff.global_position = world_pos + Vector3(randf_range(-0.25, 0.25), 0.12, randf_range(-0.25, 0.25))
		var dst := puff.global_position + Vector3(randf_range(-0.45, 0.45), randf_range(0.28, 0.55), randf_range(-0.45, 0.45))

		var tw := puff.create_tween()
		tw.set_parallel(true)
		tw.tween_property(puff, "global_position", dst, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "scale", Vector3(1.6, 1.6, 1.6), 0.32)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.32)
		tw.chain().tween_callback(puff.queue_free)


static func _spawn_flash_light(parent: Node, pos: Vector3, col: Color, energy: float, rng: float, dur: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = energy
	light.omni_range = rng
	light.shadow_enabled = false
	parent.add_child(light)
	light.global_position = pos

	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, dur)
	tw.tween_callback(light.queue_free)


## 4 HIỆU ỨNG KỸ NĂNG ĐẶC TRƯNG THEO SKIN (chuẩn 4 ô cuối ảnh mẫu):
## - "crimson_arc": Trảm Nguyệt Hỏa Viêm Đỏ (Kiếm Khách / Ninja / Miko / Ác Ma)
## - "azure_dragon": Thanh Long Linh Ba xoáy nước lam rực (Tiên Nhân / Vocaloid / Hồ Ly)
## - "purple_butterflies": Vòng Bướm Tím Huyền Ảo bung tỏa (Ma Nữ)
## - "golden_pillars": Thiên Trụ Hoàng Kim 6 cột sáng trời giáng (Thiên Sứ / Hoàng Đế)
static func spawn_skin_skill_vfx(parent: Node, world_pos: Vector3, facing_dir: Vector3, style: String, accent_col: Color) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var base_dir := facing_dir.normalized() if facing_dir.length_squared() > 0.01 else Vector3.RIGHT
	match style:
		"azure_dragon":
			# 10 linh châu rồng xanh uốn lượn vòng cung dâng cao quanh nhân vật!
			var col := Color(0.28, 0.72, 1.0)
			spawn_shockwave_ring(parent, world_pos, col, 0.7, 4.6, 0.42)
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(0.55, 0.90, 1.0, 0.92)
			mat.emission_enabled = true
			mat.emission = col
			mat.emission_energy_multiplier = 4.6
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			for i in range(10):
				var t: float = float(i) / 9.0
				var orb := MeshInstance3D.new()
				var sm := SphereMesh.new()
				var r: float = lerpf(0.38, 0.14, t)
				sm.radius = r
				sm.height = r * 2.0
				orb.mesh = sm
				orb.material_override = mat
				parent.add_child(orb)
				var ang0: float = t * PI * 1.4
				var start_p := world_pos + Vector3(cos(ang0) * 1.4, 0.5 + t * 1.4, sin(ang0) * 1.4)
				var ang1: float = ang0 + PI * 0.85
				var end_p := world_pos + Vector3(cos(ang1) * 3.4, 1.4 + t * 1.8, sin(ang1) * 3.4)
				orb.global_position = start_p
				var tw := orb.create_tween()
				tw.set_parallel(true)
				tw.tween_property(orb, "global_position", end_p, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tw.tween_property(orb, "scale", Vector3.ONE * 0.12, 0.44)
				tw.chain().tween_callback(orb.queue_free)
			_spawn_flash_light(parent, world_pos + Vector3(0.0, 1.5, 0.0), col, 4.5, 9.0, 0.42)

		"purple_butterflies":
			# 12 cánh bướm tím phát sáng bay bung thành vòng ma pháp quanh Ma Nữ!
			var col := Color(0.80, 0.36, 1.0)
			spawn_shockwave_ring(parent, world_pos, col, 0.6, 4.4, 0.45)
			var btex := PixelArtGenerator.get_prop_texture("butterfly")
			for i in range(12):
				var ang: float = (TAU / 12.0) * float(i)
				var sp := Sprite3D.new()
				sp.texture = btex
				sp.pixel_size = 0.055
				sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				sp.shaded = false
				sp.modulate = Color(0.92, 0.54, 1.0, 1.0) if (i % 2 == 0) else Color(0.70, 0.30, 1.0, 1.0)
				sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				parent.add_child(sp)
				sp.global_position = world_pos + Vector3(cos(ang) * 0.85, 0.75 + (i % 3) * 0.35, sin(ang) * 0.85)
				var dst := world_pos + Vector3(cos(ang + 0.55) * 3.8, 1.7 + randf_range(0.0, 1.1), sin(ang + 0.55) * 3.8)
				var tw := sp.create_tween()
				tw.set_parallel(true)
				tw.tween_property(sp, "global_position", dst, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(sp, "modulate:a", 0.0, 0.55)
				tw.tween_property(sp, "scale", Vector3.ONE * 1.45, 0.55)
				tw.chain().tween_callback(sp.queue_free)
			_spawn_flash_light(parent, world_pos + Vector3(0.0, 1.3, 0.0), col, 4.4, 8.5, 0.45)

		"golden_pillars":
			# 6 CỘT SÁNG HOÀNG KIM BẮN THẲNG LÊN TRỜI QUANH THIÊN SỨ / HOÀNG ĐẾ!
			var col := Color(1.0, 0.86, 0.30)
			spawn_shockwave_ring(parent, world_pos, col, 0.65, 4.8, 0.45)
			spawn_shockwave_ring(parent, world_pos + Vector3(0, 0.4, 0), Color(1.0, 0.96, 0.68), 0.45, 3.4, 0.36)
			for i in range(6):
				var ang: float = (TAU / 6.0) * float(i)
				var pil := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.28
				cm.bottom_radius = 0.42
				cm.height = 5.4
				pil.mesh = cm
				var pmat := StandardMaterial3D.new()
				pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				pmat.albedo_color = Color(1.0, 0.90, 0.42, 0.78)
				pmat.emission_enabled = true
				pmat.emission = col
				pmat.emission_energy_multiplier = 4.5
				pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				pil.material_override = pmat
				parent.add_child(pil)
				pil.global_position = world_pos + Vector3(cos(ang) * 2.15, 2.7, sin(ang) * 2.15)
				pil.scale = Vector3(1.0, 0.08, 1.0)
				var tw := pil.create_tween()
				tw.tween_property(pil, "scale", Vector3(1.15, 1.0, 1.15), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.chain().tween_property(pmat, "albedo_color:a", 0.0, 0.38)
				tw.parallel().tween_property(pil, "scale", Vector3(0.22, 1.25, 0.22), 0.38)
				tw.chain().tween_callback(pil.queue_free)
			_spawn_flash_light(parent, world_pos + Vector3(0.0, 2.2, 0.0), col, 5.2, 10.5, 0.48)

		_: # "crimson_arc" — Trảm Nguyệt Hỏa Viêm Đỏ rực quét hình bán nguyệt trước mặt Kiếm Khách!
			var col := accent_col
			spawn_shockwave_ring(parent, world_pos, col, 0.6, 4.3, 0.36)
			spawn_hit_sparks(parent, world_pos + base_dir * 1.4, base_dir, Color(1.0, 0.42, 0.18), 14)
			var slash := Sprite3D.new()
			slash.texture = PixelArtGenerator.get_prop_texture("slash_arc")
			slash.pixel_size = 0.085
			slash.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			slash.shaded = false
			slash.modulate = Color(1.0, 0.32, 0.18, 0.96)
			slash.rotation_degrees = Vector3(72.0, 0.0, 0.0)
			parent.add_child(slash)
			slash.global_position = world_pos + Vector3(base_dir.x * 1.15, 0.95, base_dir.z * 1.15)
			slash.flip_h = base_dir.x < 0.0
			slash.scale = Vector3.ONE * 1.65
			var tw := slash.create_tween()
			tw.set_parallel(true)
			tw.tween_property(slash, "scale", Vector3.ONE * 3.1, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(slash, "modulate:a", 0.0, 0.28)
			tw.chain().tween_callback(slash.queue_free)
			_spawn_flash_light(parent, world_pos + Vector3(0.0, 1.1, 0.0), col, 4.6, 8.8, 0.32)
