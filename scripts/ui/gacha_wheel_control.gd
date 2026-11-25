class_name GachaWheelControl
extends Control
## Vòng Quay Gacha 10 Ô Trang Phục Cổ Trang (Spinning Wheel):
## - Vẽ vòng tròn chia 10 cung màu theo phẩm chất (Thường / Hiếm / Sử Thi / Huyền Thoại).
## - Hiển thị trực tiếp hình ảnh chân dung của cả 10 bộ Trang Phục nằm quanh vành vòng quay!
## - Hiệu ứng quay thật mượt mà nhiều vòng giảm tốc (Ease-Out Cubic), phát tiếng lạch cạch mỗi khi kim vàng quét qua ô,
##   dừng chính xác ngay ô trang phục vừa trúng kèm vòng sáng chúc mừng!

signal spin_finished(result_data: Dictionary)

var skin_ids: Array[String] = []
var wheel_angle: float = 0.0
var is_spinning: bool = false
var _last_slice_idx: int = -1
var _highlight_slice: int = -1
var _portraits: Array[Texture2D] = []


func _ready() -> void:
	custom_minimum_size = Vector2(360, 360)
	_reload_slices()


func _reload_slices() -> void:
	skin_ids.clear()
	_portraits.clear()
	for sid in SaveManager.SKIN_CATALOG.keys():
		var s_key: String = str(sid)
		skin_ids.append(s_key)
		_portraits.append(PixelArtGenerator.get_hero_portrait_texture(SaveManager.equipped_scarf, s_key))
	queue_redraw()


## Bắt đầu quay vòng quay Gacha dừng chính xác tại skin_id trúng thưởng!
func start_spin_to(result_data: Dictionary) -> void:
	if is_spinning or skin_ids.is_empty():
		return
	var target_id: String = str(result_data.get("id", "skin_default"))
	var target_idx: int = skin_ids.find(target_id)
	if target_idx < 0:
		target_idx = 0

	is_spinning = true
	_highlight_slice = -1
	var count := skin_ids.size()
	var slice_angle := TAU / float(count)

	# Kim chỉ đặt cố định ở đỉnh trên cùng (-PI / 2). Tính góc xoay đích sao cho giữa ô target_idx dừng ngay dưới kim!
	var slice_center := (float(target_idx) + 0.5) * slice_angle
	var desired_mod := fposmod(-PI * 0.5 - slice_center, TAU)
	var cur_mod := fposmod(wheel_angle, TAU)
	var delta_angle := fposmod(desired_mod - cur_mod, TAU)
	var final_angle := wheel_angle + TAU * 5.0 + delta_angle + randf_range(-slice_angle * 0.25, slice_angle * 0.25)

	var tw := create_tween()
	tw.tween_method(_set_wheel_angle, wheel_angle, final_angle, 3.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		is_spinning = false
		_highlight_slice = target_idx
		queue_redraw()
		AudioManager.play_sfx("victory" if bool(result_data.get("has_vfx", false)) else "pickup", 1.25)
		spin_finished.emit(result_data)
	)


func _set_wheel_angle(val: float) -> void:
	wheel_angle = val
	if skin_ids.size() > 0:
		var slice_angle := TAU / float(skin_ids.size())
		var rel := fposmod(-PI * 0.5 - wheel_angle, TAU)
		var cur_idx := int(rel / slice_angle) % skin_ids.size()
		if cur_idx != _last_slice_idx:
			_last_slice_idx = cur_idx
			AudioManager.play_sfx("dash", 1.65)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.44
	if radius < 20.0 or skin_ids.is_empty():
		return

	# 1. Vành ngoài cổ trang sơn son thếp vàng + bóng đổ
	draw_circle(center + Vector2(0, 4), radius + 12.0, Color(0.02, 0.01, 0.02, 0.65))
	draw_circle(center, radius + 10.0, Color(0.88, 0.68, 0.26))
	draw_circle(center, radius + 5.0, Color(0.32, 0.10, 0.10))

	# 2. Vẽ 10 cung màu của Vòng Quay Trang Phục
	var count := skin_ids.size()
	var slice_angle := TAU / float(count)
	for i in range(count):
		var a0 := wheel_angle + float(i) * slice_angle
		var a1 := a0 + slice_angle
		var sk: Dictionary = SaveManager.SKIN_CATALOG[skin_ids[i]]
		var has_vfx: bool = bool(sk["has_vfx"])
		var tier: String = str(sk["tier"])

		var fill_col := Color(0.24, 0.17, 0.14) if (i % 2 == 0) else Color(0.18, 0.13, 0.11)
		if tier == "legendary":
			fill_col = Color(0.68, 0.48, 0.10)
		elif tier == "epic":
			fill_col = Color(0.46, 0.18, 0.34)
		elif tier == "rare":
			fill_col = Color(0.16, 0.34, 0.48)
		if i == _highlight_slice:
			fill_col = fill_col.lightened(0.35)

		_draw_pie_slice(center, radius, a0, a1, fill_col)
		# Đường phân ô viền vàng mảnh
		draw_line(center, center + Vector2(cos(a0), sin(a0)) * radius, Color(0.92, 0.74, 0.34, 0.9), 2.0, true)

		# Đèn chấm vàng viền quanh vòng quay
		var mid_a := (a0 + a1) * 0.5
		var rim_dot := center + Vector2(cos(mid_a), sin(mid_a)) * (radius + 6.5)
		draw_circle(rim_dot, 3.0, Color(1.0, 0.92, 0.55) if has_vfx else Color(0.75, 0.56, 0.25))

		# Vẽ trực tiếp hình ảnh chân dung bộ Trang Phục vào giữa từng ô cung!
		if i < _portraits.size() and _portraits[i]:
			var icon_pos := center + Vector2(cos(mid_a), sin(mid_a)) * (radius * 0.67)
			var icon_sz := Vector2(36, 36)
			var rect := Rect2(icon_pos - icon_sz * 0.5, icon_sz)
			draw_rect(rect.grow(2.0), sk["tag_color"], true)
			draw_texture_rect(_portraits[i], rect, false)

	# 3. Trục tâm bát giác sơn son vàng kim
	draw_circle(center, 28.0, Color(0.92, 0.74, 0.30))
	draw_circle(center, 23.0, Color(0.56, 0.10, 0.12))
	draw_circle(center, 16.0, Color(0.98, 0.84, 0.38))
	draw_circle(center, 12.0, Color(0.20, 0.07, 0.07))

	# 4. Kim chỉ vàng rực cố định ở đỉnh 12 giờ chỉ xuống ô trúng thưởng!
	var ptr_top := center + Vector2(0.0, -radius - 20.0)
	var ptr_pts := PackedVector2Array([
		ptr_top + Vector2(-14.0, 0.0),
		ptr_top + Vector2(14.0, 0.0),
		ptr_top + Vector2(0.0, 30.0),
	])
	draw_colored_polygon(ptr_pts, Color(1.0, 0.84, 0.26))
	draw_polyline(PackedVector2Array([ptr_pts[0], ptr_pts[1], ptr_pts[2], ptr_pts[0]]), Color(0.55, 0.10, 0.10), 2.5, true)


func _draw_pie_slice(center: Vector2, radius: float, a0: float, a1: float, col: Color) -> void:
	var pts := PackedVector2Array()
	pts.append(center)
	var segs := 10
	for s in range(segs + 1):
		var a := lerpf(a0, a1, float(s) / float(segs))
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(pts, col)
