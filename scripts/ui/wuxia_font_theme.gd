class_name WuxiaFontTheme
extends RefCounted
## Bộ Font Chữ & Giao Diện Cổ Trang Tiếng Việt Sắc Nét (SystemFont có dấu chuẩn + đổ bóng / viền chữ):
## - Dùng họ chữ Serif cổ điển (Cambria / Palatino Linotype / Georgia / Times New Roman / Segoe UI)
##   hỗ trợ đầy đủ 100% dấu tiếng Việt sắc nét, sang trọng chuẩn phong cách Kiếm Hiệp HD-2D.
## - Dùng chung cho cả UI 2D (HUD, Menu, Rương Đồ, Shop, Gacha) lẫn chữ nổi 3D (Label3D NPC, Bảng hiệu, Sát thương).

static var _body_font: SystemFont
static var _title_font: SystemFont
static var _label3d_font: SystemFont
static var _ui_theme: Theme


## Font nội dung chính (SemiBold Serif cổ trang sắc nét, rõ dấu tiếng Việt ở mọi kích cỡ)
static func get_body_font() -> SystemFont:
	if _body_font == null:
		_body_font = SystemFont.new()
		_body_font.font_names = PackedStringArray(["Cambria", "Georgia", "Palatino Linotype", "Times New Roman", "Segoe UI", "Tahoma"])
		_body_font.font_weight = 600
		_body_font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
		_body_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_body_font.hinting = TextServer.HINTING_NORMAL
	return _body_font


## Font tiêu đề lớn / Banner / Chiêu Cuối / Nút bấm (Bold Serif uy nghiêm kiểu thư pháp kiếm hiệp)
static func get_title_font() -> SystemFont:
	if _title_font == null:
		_title_font = SystemFont.new()
		_title_font.font_names = PackedStringArray(["Palatino Linotype", "Cambria", "Georgia", "Times New Roman", "Segoe UI"])
		_title_font.font_weight = 800
		_title_font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
		_title_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_title_font.hinting = TextServer.HINTING_NORMAL
	return _title_font


## Font tối ưu cho Label3D trong không gian 3D (Bảng hiệu quán, tên NPC, số sát thương chí mạng)
static func get_label3d_font() -> SystemFont:
	if _label3d_font == null:
		_label3d_font = SystemFont.new()
		_label3d_font.font_names = PackedStringArray(["Cambria", "Georgia", "Times New Roman", "Segoe UI"])
		_label3d_font.font_weight = 700
		_label3d_font.multichannel_signed_distance_field = true
	return _label3d_font


## Tạo Theme chuẩn Cổ Trang áp dụng đồng bộ cho toàn bộ Control UI
static func get_ui_theme() -> Theme:
	if _ui_theme != null:
		return _ui_theme
	var th := Theme.new()
	var body_f := get_body_font()
	var title_f := get_title_font()

	th.default_font = body_f
	th.default_font_size = 15

	# Nhãn chữ (Label): có viền mảnh + bóng đổ nhẹ giúp đọc cực rõ trên mọi nền cảnh đêm/lửa
	th.set_font("font", "Label", body_f)
	th.set_font_size("font_size", "Label", 15)
	th.set_color("font_shadow_color", "Label", Color(0.03, 0.01, 0.01, 0.85))
	th.set_color("font_outline_color", "Label", Color(0.06, 0.03, 0.02, 0.80))
	th.set_constant("shadow_offset_x", "Label", 1)
	th.set_constant("shadow_offset_y", "Label", 2)
	th.set_constant("outline_size", "Label", 2)
	th.set_constant("shadow_outline_size", "Label", 2)

	# Nút bấm (Button): dùng font tiêu đề đậm, có viền sắc nét nổi bật
	th.set_font("font", "Button", title_f)
	th.set_font_size("font_size", "Button", 15)
	th.set_color("font_outline_color", "Button", Color(0.05, 0.02, 0.01, 0.85))
	th.set_constant("outline_size", "Button", 2)

	# RichTextLabel (nếu có)
	th.set_font("normal_font", "RichTextLabel", body_f)
	th.set_font("bold_font", "RichTextLabel", title_f)

	_ui_theme = th
	return _ui_theme


## Áp style chữ thư pháp mực nâu lên nền giấy gió sáng (bỏ viền đen để chữ mực sắc thanh thoát)
static func apply_parchment_ink_style(lbl: Label) -> void:
	if lbl == null:
		return
	lbl.add_theme_font_override("font", get_title_font())
	lbl.add_theme_constant_override("outline_size", 0)
	lbl.add_theme_color_override("font_shadow_color", Color(1.0, 0.96, 0.86, 0.55))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 1)


## Áp font tiêu đề uy nghiêm + viền dày cho Banner / Tên Boss / Chiêu Cuối
static func apply_headline_style(lbl: Label, size_px: int = 24) -> void:
	if lbl == null:
		return
	lbl.add_theme_font_override("font", get_title_font())
	lbl.add_theme_font_size_override("font_size", size_px)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.02, 0.94))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)


## Áp font 3D sắc nét cho mọi Label3D (Tên NPC, Bảng hiệu làng, Rương báu, Sát thương bay lên)
static func style_label_3d(lbl: Label3D) -> void:
	if lbl == null:
		return
	lbl.font = get_label3d_font()
	lbl.outline_size = maxi(lbl.outline_size, 8)
	lbl.outline_modulate = Color(0.07, 0.04, 0.03)
