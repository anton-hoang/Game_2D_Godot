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
