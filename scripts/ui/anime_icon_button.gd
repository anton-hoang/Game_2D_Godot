class_name AnimeIconButton
extends Control
## Nút tròn viền vàng chạm khắc phong cách Tiên Hiệp / Anime Fantasy RPG:
## - Dùng cho hàng 5 nút góc trên phải (Vòng Quay, Linh Thú, Tháp Vô Tận, Nhiệm Vụ, Cài Đặt)
##   và hàng 5 nút lớn góc dưới phải (Nhân Vật, Túi Đồ, Kỹ Năng, Danh Hiệu, Cửa Hàng).
## - Tự vẽ huy hiệu sắc nét bên trong + viền kim loại kép + chấm đỏ thông báo + nhãn viền đen phía dưới!

signal pressed

var icon_kind: String = "bag"
var label_text: String = "Túi Đồ"
var orb_radius: float = 24.0
var show_red_dot: bool = false
var badge_text: String = ""
var portrait_texture: Texture2D = null

var _hovered: bool = false
var _pressed_down: bool = false
var _lbl: Label
var _portrait_rect: TextureRect


func _init(kind: String = "bag", title: String = "Túi Đồ", diameter: float = 48.0, has_dot: bool = false) -> void:
	icon_kind = kind
	label_text = title
	orb_radius = diameter * 0.5
	show_red_dot = has_dot
	custom_minimum_size = Vector2(diameter + 14.0, diameter + 22.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	if icon_kind == "hero":
		_portrait_rect = TextureRect.new()
		var p_sz: float = orb_radius * 1.48
		_portrait_rect.position = Vector2((custom_minimum_size.x - p_sz) * 0.5, orb_radius - p_sz * 0.5 + 2.0)
		_portrait_rect.size = Vector2(p_sz, p_sz)
		_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if portrait_texture:
			_portrait_rect.texture = portrait_texture
		add_child(_portrait_rect)

	_lbl = Label.new()
	_lbl.position = Vector2(-6.0, orb_radius * 2.0 + 3.0)
	_lbl.custom_minimum_size = Vector2(custom_minimum_size.x + 12.0, 18.0)
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl.add_theme_font_size_override("font_size", 11 if orb_radius <= 24.0 else 12)
	_lbl.add_theme_constant_override("outline_size", 4)
	_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.05, 0.96))
	_lbl.modulate = Color(1.0, 0.95, 0.80)
	_lbl.text = label_text
	_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lbl)

	mouse_entered.connect(func() -> void:
		_hovered = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hovered = false
		_pressed_down = false
		queue_redraw()
	)


func set_portrait(tex: Texture2D) -> void:
	portrait_texture = tex
	if _portrait_rect:
		_portrait_rect.texture = tex


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressed_down = true
				queue_redraw()
			else:
				if _pressed_down:
					_pressed_down = false
					queue_redraw()
					AudioManager.play_sfx("pickup", 0.95)
					pressed.emit()


func _draw() -> void:
	var cx: float = size.x * 0.5
	var cy: float = orb_radius + 2.0
	var c := Vector2(cx, cy)
	var r: float = orb_radius * (0.94 if _pressed_down else (1.04 if _hovered else 1.0))

	# 1. Đổ bóng & hào quang nhẹ khi di chuột
	draw_circle(c + Vector2(0, 2.5), r + 2.5, Color(0.0, 0.0, 0.0, 0.52))
	if _hovered:
		draw_circle(c, r + 5.0, Color(1.0, 0.84, 0.40, 0.28))

	# 2. Nền tròn pha lê nâu-đỏ cổ điển & viền kim loại vàng đồng kép
	var bg_col: Color = Color(0.24, 0.11, 0.10, 0.96) if not _hovered else Color(0.32, 0.15, 0.13, 0.98)
	if icon_kind == "skill":
		bg_col = Color(0.11, 0.16, 0.30, 0.96) if not _hovered else Color(0.16, 0.24, 0.42, 0.98)
	elif icon_kind == "pet":
		bg_col = Color(0.18, 0.12, 0.28, 0.96) if not _hovered else Color(0.26, 0.16, 0.38, 0.98)
	elif icon_kind == "settings":
		bg_col = Color(0.16, 0.13, 0.14, 0.96)

	draw_circle(c, r, bg_col)
	# Phản quang kính mềm nửa trên
	draw_arc(c + Vector2(0, -r * 0.12), r * 0.72, PI * 1.15, PI * 1.85, 20, Color(1.0, 0.96, 0.86, 0.24), 4.0, true)

	# 3. Vẽ biểu tượng huy hiệu sắc nét bên trong nút tròn
	_draw_emblem(c, r * 0.62)

	# 4. Viền kim loại vàng đồng chạm khắc kép
	draw_arc(c, r + 1.0, 0.0, TAU, 44, Color(0.16, 0.09, 0.05, 0.96), 3.6, true)
	draw_arc(c, r, 0.0, TAU, 44, Color(0.96, 0.80, 0.38, 0.98) if not _hovered else Color(1.0, 0.92, 0.58, 1.0), 2.2, true)
	draw_arc(c, r - 2.4, 0.0, TAU, 44, Color(0.62, 0.44, 0.18, 0.75), 1.0, true)

	# 5. Chấm đỏ thông báo nhỏ góc phải trên
	if show_red_dot:
		var dot_p := c + Vector2(r * 0.70, -r * 0.70)
		draw_circle(dot_p, 5.2, Color(1.0, 0.92, 0.65, 0.95))
		draw_circle(dot_p, 4.0, Color(0.92, 0.14, 0.16, 1.0))


func _draw_emblem(c: Vector2, s: float) -> void:
	var gold := Color(0.98, 0.84, 0.40)
	var cream := Color(0.98, 0.93, 0.80)
	var crimson := Color(0.86, 0.18, 0.20)
	var cyan := Color(0.38, 0.86, 1.0)

	match icon_kind:
		"gift":
			# Hộp quà sơn son thắt nơ vàng (Vòng Quay / Phúc Lợi)
			draw_rect(Rect2(c.x - s * 0.72, c.y - s * 0.35, s * 1.44, s * 1.10), crimson)
			draw_rect(Rect2(c.x - s * 0.82, c.y - s * 0.62, s * 1.64, s * 0.36), crimson.lightened(0.12))
			draw_rect(Rect2(c.x - s * 0.16, c.y - s * 0.62, s * 0.32, s * 1.37), gold)
			draw_circle(c + Vector2(-s * 0.28, -s * 0.75), s * 0.24, gold)
			draw_circle(c + Vector2(s * 0.28, -s * 0.75), s * 0.24, gold)
		"pet":
			# Linh châu & dấu chân Linh Thú phát sáng xanh-tím
			draw_circle(c + Vector2(0, s * 0.18), s * 0.46, Color(0.74, 0.54, 1.0))
			draw_circle(c + Vector2(0, s * 0.18), s * 0.28, Color(0.95, 0.88, 1.0))
			for off: Vector2 in [Vector2(-s * 0.48, -s * 0.34), Vector2(0, -s * 0.56), Vector2(s * 0.48, -s * 0.34)]:
				draw_circle(c + off, s * 0.22, gold)
		"tower":
			# Ngôi sao vàng 5 cánh & đỉnh Tháp Cổ
			var pts := PackedVector2Array()
			for i in range(10):
				var ang: float = -PI * 0.5 + float(i) * PI / 5.0
				var rad: float = s * (0.92 if i % 2 == 0 else 0.42)
				pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
			draw_colored_polygon(pts, gold)
			draw_circle(c, s * 0.24, crimson)
		"quest":
			# Cuộn thư Nhiệm Vụ giấy kem & ấn triện đỏ
			draw_rect(Rect2(c.x - s * 0.60, c.y - s * 0.66, s * 1.20, s * 1.32), cream)
			draw_rect(Rect2(c.x - s * 0.74, c.y - s * 0.78, s * 1.48, s * 0.22), gold)
			draw_rect(Rect2(c.x - s * 0.74, c.y + s * 0.56, s * 1.48, s * 0.22), gold)
			for ly: float in [-0.30, 0.0, 0.30]:
				draw_line(c + Vector2(-s * 0.36, s * ly), c + Vector2(s * 0.36, s * ly), Color(0.38, 0.24, 0.14), 1.8)
			draw_circle(c + Vector2(s * 0.26, s * 0.28), s * 0.20, crimson)
		"settings":
			# Bánh răng vàng cổ điển
			for i in range(8):
				var ang: float = float(i) * TAU / 8.0
				var tp := c + Vector2(cos(ang), sin(ang)) * (s * 0.70)
				draw_circle(tp, s * 0.22, gold)
			draw_circle(c, s * 0.58, gold)
			draw_circle(c, s * 0.26, Color(0.16, 0.13, 0.14))
		"bag":
			# Túi gấm đỏ thắt dây vàng (Túi Đồ [I])
			draw_circle(c + Vector2(0, s * 0.20), s * 0.68, crimson)
			draw_rect(Rect2(c.x - s * 0.42, c.y - s * 0.74, s * 0.84, s * 0.36), crimson.lightened(0.14))
			draw_rect(Rect2(c.x - s * 0.48, c.y - s * 0.40, s * 0.96, s * 0.18), gold)
			draw_circle(c + Vector2(0, s * 0.22), s * 0.24, gold)
		"skill":
			# Bí kíp võ công xanh lam nạm sao vàng (Kỹ Năng [U/F])
			draw_rect(Rect2(c.x - s * 0.64, c.y - s * 0.72, s * 1.28, s * 1.44), Color(0.14, 0.34, 0.66))
			draw_rect(Rect2(c.x - s * 0.64, c.y - s * 0.72, s * 0.26, s * 1.44), Color(0.08, 0.18, 0.40))
			draw_rect(Rect2(c.x - s * 0.50, c.y - s * 0.58, s * 1.00, s * 1.16), cyan, false, 1.6)
			var star := PackedVector2Array([
				c + Vector2(0.1 * s, -s * 0.38),
				c + Vector2(0.42 * s, 0.0),
				c + Vector2(0.1 * s, s * 0.38),
				c + Vector2(-0.22 * s, 0.0),
			])
			draw_colored_polygon(star, gold)
		"guild":
			# Cờ hiệu đỏ vàng Bang Hội / Danh Hiệu
			draw_rect(Rect2(c.x - s * 0.68, c.y - s * 0.72, s * 1.36, s * 0.18), gold)
			var flag := PackedVector2Array([
				c + Vector2(-s * 0.50, -s * 0.54),
				c + Vector2(s * 0.50, -s * 0.54),
				c + Vector2(s * 0.50, s * 0.42),
				c + Vector2(0.0, s * 0.76),
				c + Vector2(-s * 0.50, s * 0.42),
			])
			draw_colored_polygon(flag, crimson)
			draw_circle(c + Vector2(0, -s * 0.04), s * 0.26, gold)
		"shop":
			# Sạp mái hiên sọc đỏ kem Cửa Hàng
			draw_rect(Rect2(c.x - s * 0.62, c.y - s * 0.12, s * 1.24, s * 0.82), Color(0.42, 0.24, 0.14))
			draw_rect(Rect2(c.x - s * 0.46, c.y + s * 0.08, s * 0.92, s * 0.44), cream)
			for i in range(4):
				var sx: float = c.x - s * 0.76 + float(i) * (s * 0.38)
				draw_rect(Rect2(sx, c.y - s * 0.64, s * 0.38, s * 0.52), crimson if i % 2 == 0 else cream)
		"hero":
			# Khung chân dung nhân vật đã dùng TextureRect ở trên
			pass
