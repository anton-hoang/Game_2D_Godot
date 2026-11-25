class_name DamageNumber3D
extends Node3D
## Hiển thị số sát thương / hồi máu bay lên trong không gian 3D (Billboard Label3D).

static func spawn(parent: Node, world_pos: Vector3, amount: int, is_critical: bool = false, is_heal: bool = false, custom_text: String = "") -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.pixel_size = 0.011 if not is_critical else 0.015
	lbl.font_size = 38 if not is_critical else 48
	lbl.outline_size = 10
	lbl.text = custom_text if custom_text != "" else ( ("+" if is_heal else "") + str(amount) + ("!" if is_critical else "") )

	if is_heal:
		lbl.modulate = Color(0.35, 1.0, 0.48)
	elif is_critical:
		lbl.modulate = Color(1.0, 0.85, 0.20)
	else:
		lbl.modulate = Color(1.0, 0.96, 0.90)
	lbl.outline_modulate = Color(0.08, 0.05, 0.12)

	parent.add_child(lbl)
	lbl.global_position = world_pos + Vector3(randf_range(-0.35, 0.35), 1.35, randf_range(-0.2, 0.2))

	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y + 1.25, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.65).set_delay(0.18)
	tw.chain().tween_callback(lbl.queue_free)
