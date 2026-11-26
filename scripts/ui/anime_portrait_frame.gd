class_name AnimePortraitFrame
extends Control
## Khung Chân Dung Nhân Vật Phong Cách ANIME ARPG:
## - Vòng pháp trận kép ánh kim + hào quang phát sáng theo màu Skin đang mặc.
## - 4 Viên ngọc thoi (Diamond Crest) đính 4 hướng chuẩn giao diện Anime Fantasy.

var accent_color: Color = Color(1.0, 0.38, 0.32):
	set(v):
		accent_color = v
		queue_redraw()

var _pulse_t: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(104, 104)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_pulse_t += delta * 2.6
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r: float = minf(size.x, size.y) * 0.44
	var pulse: float = 0.5 + 0.5 * sin(_pulse_t)

	# 1. Quầng hào quang Anime mềm phía sau khung avatar
	draw_circle(c + Vector2(0, 3), r + 7.0, Color(0.0, 0.0, 0.0, 0.55))
	draw_circle(c, r + 6.5, Color(accent_color.r, accent_color.g, accent_color.b, 0.22 + pulse * 0.12))

	# 2. Nền tròn pha lê tối + vành kim loại vàng trắng kép
	draw_circle(c, r + 3.5, Color(0.98, 0.84, 0.44, 0.98))
	draw_circle(c, r + 1.2, Color(0.10, 0.08, 0.16, 0.98))
	draw_arc(c, r - 2.0, 0.0, TAU, 48, Color(accent_color.r, accent_color.g, accent_color.b, 0.78), 2.0, true)

	# 3. 4 Viên ngọc hình thoi (Anime Diamond Gems) ở 4 góc Đông - Tây - Nam - Bắc
	var dirs: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	for d: Vector2 in dirs:
		var gp: Vector2 = c + d * (r + 3.0)
		var gem := PackedVector2Array([
			gp + Vector2(0, -5.0),
			gp + Vector2(5.0, 0),
			gp + Vector2(0, 5.0),
			gp + Vector2(-5.0, 0),
		])
		draw_colored_polygon(gem, Color(1.0, 0.92, 0.56))
		draw_colored_polygon(PackedVector2Array([
			gp + Vector2(0, -2.8),
			gp + Vector2(2.8, 0),
			gp + Vector2(0, 2.8),
			gp + Vector2(-2.8, 0),
		]), accent_color.lightened(0.20))
