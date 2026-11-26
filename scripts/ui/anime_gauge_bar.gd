class_name AnimeGaugeBar
extends Control
## Thanh Máu / Chân Khí / Chiêu Cuối / Boss phong cách ANIME ARPG hiện đại:
## - Dáng vát nghiêng khí động học (Skewed Parallelogram) sắc sảo kiểu Genshin / Granblue / Anime RPG.
## - Phối màu chuyển sắc (Gradient 2 đầu) + Dải phản quang kính bóng (Glossy Specular Band) ở nửa trên.
## - Vệt sáng năng lượng lướt nhẹ theo thời gian + Vệt máu trễ trắng vàng (Smooth Damage Trail) tự động!
## - Vạch chia khắc 20% tinh tế & điểm chớp sáng ngay mũi thanh máu.

var max_value: float = 100.0:
	set(v):
		max_value = maxf(1.0, v)
		queue_redraw()

var value: float = 100.0:
	set(v):
		var clamped := clampf(v, 0.0, max_value)
		if not _initialized:
			_initialized = true
			_trail_value = clamped
		elif clamped > _trail_value:
			_trail_value = clamped
		value = clamped
		queue_redraw()

var color_left: Color = Color(0.86, 0.14, 0.26)
var color_right: Color = Color(1.0, 0.38, 0.48)
var trail_color: Color = Color(1.0, 0.92, 0.56, 0.95)
var border_color: Color = Color(0.96, 0.82, 0.46, 0.95)
var bg_color: Color = Color(0.06, 0.05, 0.10, 0.88)
var skew_px: float = 10.0
var show_ticks: bool = true
var pulse_when_full: bool = false
var pulse_when_low: bool = false

var _trail_value: float = 100.0
var _initialized: bool = false
var _anim_time: float = 0.0


func _init(
	c_left: Color = Color(0.86, 0.14, 0.26),
	c_right: Color = Color(1.0, 0.38, 0.48),
	b_col: Color = Color(0.96, 0.82, 0.46, 0.95),
	bar_h: int = 22,
	slant: float = 10.0
) -> void:
	color_left = c_left
	color_right = c_right
	border_color = b_col
	skew_px = slant
	custom_minimum_size = Vector2(280, bar_h)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_anim_time += delta
	if _trail_value > value:
		_trail_value = move_toward(_trail_value, value, max_value * 0.48 * delta)
	elif _trail_value < value:
		_trail_value = value
	queue_redraw()


func _make_skew_poly(x0: float, y0: float, w: float, h: float, sk: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(x0 + sk, y0),
		Vector2(x0 + sk + w, y0),
		Vector2(x0 + w, y0 + h),
		Vector2(x0, y0 + h),
	])


func _draw_gradient_skew(x0: float, y0: float, w: float, h: float, sk: float, c0: Color, c1: Color) -> void:
	if w <= 0.5 or h <= 0.5:
		return
	var pts := _make_skew_poly(x0, y0, w, h, sk)
	var cols := PackedColorArray([c0, c1, c1.darkened(0.10), c0.darkened(0.10)])
	draw_polygon(pts, cols)


func _draw() -> void:
	var total_w: float = size.x
	var total_h: float = size.y
	if total_w <= skew_px + 4.0 or total_h <= 4.0:
		return

	var sk: float = minf(skew_px, total_h * 0.75)
	var usable_w: float = total_w - sk - 4.0
	var x_base: float = 2.0
	var y_base: float = 2.0
	var inner_h: float = total_h - 4.0

	var cur_ratio: float = clampf(value / maxf(1.0, max_value), 0.0, 1.0)
	var tr_ratio: float = clampf(_trail_value / maxf(1.0, max_value), 0.0, 1.0)

	# 1. Đổ bóng mềm phía dưới thanh Anime
	var shadow_pts := _make_skew_poly(x_base + 2.0, y_base + 3.0, usable_w, inner_h, sk)
	draw_colored_polygon(shadow_pts, Color(0.0, 0.0, 0.0, 0.52))

	# 2. Nền tối pha lê mở (Glassmorphic Dark Backdrop)
	var bg_pts := _make_skew_poly(x_base, y_base, usable_w, inner_h, sk)
	draw_colored_polygon(bg_pts, bg_color)

	# 3. Lớp vệt máu trễ trắng-vàng (Damage Trail trượt mượt khi trúng đòn)
	if tr_ratio > cur_ratio + 0.004:
		var tw: float = usable_w * tr_ratio
		var t_pts := _make_skew_poly(x_base + 1.5, y_base + 1.5, maxf(1.0, tw - 3.0), inner_h - 3.0, sk * 0.86)
		draw_colored_polygon(t_pts, trail_color)

	# 4. Phần thanh máu / năng lượng chính (Gradient chuyển sắc + hiệu ứng nháy nguy hiểm / đầy nộ)
	if cur_ratio > 0.003:
		var fw: float = maxf(2.0, usable_w * cur_ratio - 3.0)
		var c0: Color = color_left
		var c1: Color = color_right
		if pulse_when_low and cur_ratio < 0.30:
			var p_low: float = 0.5 + 0.5 * sin(_anim_time * 9.0)
			c0 = c0.lerp(Color(1.0, 0.15, 0.15), p_low * 0.5)
			c1 = c1.lerp(Color(1.0, 0.72, 0.32), p_low * 0.6)
		elif pulse_when_full and cur_ratio >= 0.995:
			var p_full: float = 0.5 + 0.5 * sin(_anim_time * 5.5)
			c0 = c0.lightened(p_full * 0.16)
			c1 = c1.lightened(p_full * 0.24)

		var sk_in: float = sk * 0.86
		_draw_gradient_skew(x_base + 1.5, y_base + 1.5, fw, inner_h - 3.0, sk_in, c0, c1)

		# 5. Dải phản quang kính bóng Anime ở 40% cạnh trên (Glossy Anime Specular Highlight)
		var gloss_h: float = maxf(2.0, (inner_h - 3.0) * 0.40)
		var gloss_pts := _make_skew_poly(x_base + 1.5 + sk_in * 0.55, y_base + 1.5, fw, gloss_h, sk_in * 0.42)
		draw_colored_polygon(gloss_pts, Color(1.0, 1.0, 1.0, 0.27))

		# 6. Luồng sáng lướt nhẹ dọc thanh (Subtle Shimmer Sweep)
		if fw > 28.0:
			var sweep_t: float = fposmod(_anim_time * 0.55, 1.35)
			if sweep_t <= 1.0:
				var sw_w: float = minf(26.0, fw * 0.25)
				var sw_x: float = x_base + 1.5 + (fw - sw_w) * sweep_t
				var sw_pts := _make_skew_poly(sw_x, y_base + 1.5, sw_w, inner_h - 3.0, sk_in)
				draw_colored_polygon(sw_pts, Color(1.0, 1.0, 1.0, 0.16))

		# 7. Vệt tia sáng sắc nét ngay đầu mũi thanh (Leading-Edge Spark)
		if cur_ratio < 0.992:
			var tip_top := Vector2(x_base + 1.5 + sk_in + fw, y_base + 1.5)
			var tip_bot := Vector2(x_base + 1.5 + fw, y_base + inner_h - 1.5)
			draw_line(tip_top, tip_bot, Color(1.0, 0.98, 0.88, 0.95), 2.2, true)

	# 8. Vạch khắc chia 20% tinh tế chuẩn thanh máu Anime RPG
	if show_ticks and usable_w > 90.0:
		for ti in range(1, 5):
			var tx_top: float = x_base + sk + usable_w * (float(ti) * 0.20)
			draw_line(Vector2(tx_top, y_base + 1.0), Vector2(tx_top - sk * 0.32, y_base + inner_h * 0.34), Color(0.05, 0.04, 0.08, 0.45), 1.3, true)

	# 9. Khung viền kép sắc sảo (Viền đen mảnh bên ngoài + Viền kim loại sáng bên trong)
	var out_pts := PackedVector2Array([bg_pts[0], bg_pts[1], bg_pts[2], bg_pts[3], bg_pts[0]])
	draw_polyline(out_pts, Color(0.04, 0.03, 0.07, 0.92), 3.0, true)
	draw_polyline(out_pts, border_color, 1.6, true)
