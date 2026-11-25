class_name PixelArtGenerator
extends RefCounted
## Bộ sinh Sprite Pixel Art HD-2D độ phân giải cao (32x40 -> 64x64) có đổ bóng 3-4 lớp màu,
## viền màu ấm (colored outline), điểm sáng tóc/áo giáp, và phụ kiện chi tiết kiểu Octopath Traveler.
## Khi có asset thật (PNG/SpriteFrames), chỉ cần gán vào custom_sprite_frames của Player / EnemyStats.

static var _cache: Dictionary = {}


static func get_player_sprite_frames(scarf_id: String = "blue", weapon_type: String = "sword", skin_id: String = "skin_default") -> SpriteFrames:
	var key := "player_frames_anime_v2_" + scarf_id + "_" + weapon_type + "_" + skin_id
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# Nhịp animation riêng cho từng skin (Ninja chạy cực nhanh, Thiên Sứ/Tiên Nhân bay lượn nhẹ nhàng, Kiếm Khách/Ác Ma chém dứt khoát)
	var idle_fps: float = 5.5
	var run_fps: float = 11.5
	var atk_fps: float = 15.5
	match skin_id:
		"skin_ninja":
			idle_fps = 6.5
			run_fps = 14.5
			atk_fps = 17.0
		"skin_vocaloid":
			idle_fps = 6.5
			run_fps = 12.8
			atk_fps = 16.0
		"skin_angel", "skin_immortal", "skin_witch":
			idle_fps = 5.5
			run_fps = 10.5
			atk_fps = 15.0
		"skin_demon", "skin_default":
			idle_fps = 6.0
			run_fps = 12.2
			atk_fps = 16.5
		"skin_emperor":
			idle_fps = 6.0
			run_fps = 11.2
			atk_fps = 16.0

	var sk: Dictionary = SaveManager.SKIN_CATALOG.get(skin_id, SaveManager.SKIN_CATALOG["skin_default"])
	var vcol: Color = sk.get("vfx_color", Color(0.68, 0.96, 1.0))
	var dash_tint: Color = Color.WHITE.lerp(vcol, 0.38)
	var fin_tint: Color = Color.WHITE.lerp(vcol, 0.22)

	_add_anim(frames, "idle", idle_fps, true, [
		_make_hero_frame(0, false, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(1, false, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(2, false, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(3, false, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "run", run_fps, true, [
		_make_hero_frame(0, true, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(1, true, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(2, true, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(3, true, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "dash", 15.0, false, [
		_make_hero_frame(1, true, false, dash_tint, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(2, true, false, dash_tint, 0, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "attack_1", atk_fps, false, [
		_make_hero_frame(0, false, true, Color.WHITE, 1, scarf_id, weapon_type, skin_id),
		_make_hero_frame(1, false, true, Color.WHITE, 2, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "attack_2", atk_fps, false, [
		_make_hero_frame(1, false, true, Color.WHITE, 2, scarf_id, weapon_type, skin_id),
		_make_hero_frame(2, false, true, Color.WHITE, 3, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "attack_3", atk_fps, false, [
		_make_hero_frame(2, false, true, fin_tint, 3, scarf_id, weapon_type, skin_id),
		_make_hero_frame(3, false, true, fin_tint, 4, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "special", 13.5, false, [
		_make_hero_frame(1, false, true, dash_tint, 3, scarf_id, weapon_type, skin_id),
		_make_hero_frame(3, false, true, dash_tint, 4, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "hurt", 8.0, false, [
		_make_hero_frame(1, false, false, Color(1.0, 0.42, 0.42), 0, scarf_id, weapon_type, skin_id),
	])

	_cache[key] = frames
	return frames


static func get_enemy_sprite_frames(archetype: String, tint: Color = Color.WHITE) -> SpriteFrames:
	var key := "enemy_hd_" + archetype + "_" + tint.to_html()
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	_add_anim(frames, "idle", 4.5, true, [
		_make_enemy_frame(archetype, 0, false, tint),
		_make_enemy_frame(archetype, 1, false, tint),
	])
	_add_anim(frames, "move", 9.0, true, [
		_make_enemy_frame(archetype, 0, false, tint),
		_make_enemy_frame(archetype, 1, false, tint),
		_make_enemy_frame(archetype, 2, false, tint),
		_make_enemy_frame(archetype, 1, false, tint),
	])
	_add_anim(frames, "attack", 11.0, false, [
		_make_enemy_frame(archetype, 1, true, tint),
		_make_enemy_frame(archetype, 2, true, tint),
	])
	_add_anim(frames, "hurt", 8.0, false, [
		_make_enemy_frame(archetype, 1, false, Color(1.0, 0.38, 0.38)),
	])
	_add_anim(frames, "die", 6.0, false, [
		_make_enemy_frame(archetype, 2, false, Color(0.42, 0.40, 0.48, 0.72)),
	])

	_cache[key] = frames
	return frames


static func get_pet_sprite_frames(pet_type: String = "fox") -> SpriteFrames:
	var key := "pet_frames_" + pet_type
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_anim(frames, "float", 6.5, true, [
		_make_pet_frame(pet_type, 0),
		_make_pet_frame(pet_type, 1),
		_make_pet_frame(pet_type, 2),
		_make_pet_frame(pet_type, 1),
	])
	_cache[key] = frames
	return frames


static func get_hero_portrait_texture(scarf_id: String = "blue", skin_id: String = "skin_default") -> ImageTexture:
	var key := "hero_portrait_" + scarf_id + "_" + skin_id
	if _cache.has(key):
		return _cache[key]
	var tex := ImageTexture.create_from_image(_make_hero_portrait_image(scarf_id, skin_id))
	_cache[key] = tex
	return tex


static func get_npc_sprite_texture(npc_role: String) -> ImageTexture:
	var key := "npc_sprite_" + npc_role
	if _cache.has(key):
		return _cache[key]
	var tex := ImageTexture.create_from_image(_make_npc_image(npc_role))
	_cache[key] = tex
	return tex


static func get_npc_portrait_texture(npc_role: String) -> ImageTexture:
	var key := "npc_portrait_" + npc_role
	if _cache.has(key):
		return _cache[key]
	var tex := ImageTexture.create_from_image(_make_npc_portrait_image(npc_role))
	_cache[key] = tex
	return tex


static func get_weapon_icon_texture(weapon_id: String) -> ImageTexture:
	var key := "icon_weapon_" + weapon_id
	if _cache.has(key):
		return _cache[key]
	var tex := ImageTexture.create_from_image(_make_weapon_icon_image(weapon_id))
	_cache[key] = tex
	return tex


static func get_bag_item_icon_texture(item_id: String) -> ImageTexture:
	var key := "icon_bag_" + item_id
	if _cache.has(key):
		return _cache[key]
	var tex := ImageTexture.create_from_image(_make_bag_item_icon_image(item_id))
	_cache[key] = tex
	return tex


static func get_prop_texture(prop_type: String) -> ImageTexture:
	var key := "prop_hd_" + prop_type
	if _cache.has(key):
		return _cache[key]
	var img: Image
	match prop_type:
		"tree":
			img = _make_tree_image("green")
		"tree_autumn":
			img = _make_tree_image("autumn")
		"sakura":
			img = _make_tree_image("sakura")
		"pine":
			img = _make_pine_image()
		"bush":
			img = _make_bush_image()
		"grass_tuft":
			img = _make_grass_tuft_image()
		"flower_cluster":
			img = _make_flower_cluster_image()
		"butterfly":
			img = _make_butterfly_image()
		"pickup_hp":
			img = _make_icon_image(Color(0.96, 0.20, 0.30), Color(1.0, 0.78, 0.82), "heart")
		"pickup_mp":
			img = _make_icon_image(Color(0.18, 0.68, 1.0), Color(0.78, 0.96, 1.0), "crystal")
		"pickup_gold":
			img = _make_icon_image(Color(1.0, 0.82, 0.16), Color(1.0, 0.98, 0.70), "coin")
		"pickup_weapon":
			img = _make_icon_image(Color(0.88, 0.48, 1.0), Color(1.0, 0.94, 0.65), "weapon")
		"pickup_potion":
			img = _make_icon_image(Color(0.24, 0.86, 0.56), Color(0.85, 1.0, 0.92), "heart")
		"slash_arc":
			img = _make_slash_image()
		_:
			img = _make_bush_image()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _add_anim(frames: SpriteFrames, anim_name: String, fps: float, loop: bool, textures: Array) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for tex in textures:
		frames.add_frame(anim_name, tex)


## Nhân vật chính phong cách ANIME CHIBI ĐẶC SẮC (48x52 pixel) — 10 SKIN CHUẨN ẢNH MẪU, MỖI SKIN CÓ ANIMATION RIÊNG!
## 1. Kiếm Khách (skin_default): Tóc đen xoăn dựng, mắt đỏ sắc, giáp đen-đỏ viền vàng, khăn lụa đỏ bay phấp phới & kiếm lửa đỏ rực.
## 2. Tiên Nhân (skin_immortal): Tóc đen dài búi cao, đạo bào trắng lam, chuyển động lơ lửng thanh thoát.
## 3. Ninja (skin_ninja): Tóc vàng dựng, băng trán thép, áo khoác cam-đen, dáng chạy chúi người cực nhanh.
## 4. Miko (skin_miko): Tóc đen dài, mặt nạ cáo Kitsune đeo nghiêng bên đầu, áo trắng hakama đỏ.
## 5. Vocaloid (skin_vocaloid): Tóc 2 bím siêu dài xanh ngọc nhún nhảy lệch pha theo từng bước, trang phục idol hiện đại.
## 6. Hồ Ly (skin_fox): Tóc trắng, đôi tai cáo bông lớn, 3 chiếc đuôi bạch hồ vẫy mượt mà phía sau, kimono trắng-lam.
## 7. Ma Nữ (skin_witch): Tóc tím đậm dài, váy ma nữ tím vàng & đàn bướm tím phát sáng bay lượn quanh người theo từng frame.
## 8. Ác Ma (skin_demon): Tóc bạc dựng, mắt đỏ rực, đôi cánh dơi hắc ám vỗ lên xuống theo từng bước.
## 9. Thiên Sứ (skin_angel): Tóc trắng, vòng hào quang vàng lơ lửng trên đầu, đôi cánh lông vũ trắng vỗ bay nhẹ nhàng.
## 10. Hoàng Đế (skin_emperor): Tóc đen đội vương miện hoàng kim, long bào đen vàng & Kim Long uốn lượn phía sau lưng theo từng frame!
static func _make_hero_frame(step: int, running: bool, attacking: bool, modulate_col: Color = Color.WHITE, sword_pose: int = 0, scarf_id: String = "blue", weapon_type: String = "sword", skin_id: String = "skin_default") -> ImageTexture:
	var w: int = 48
	var h: int = 52
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Nhịp chuyển động cơ thể riêng theo từng Skin!
	var is_floating: bool = (skin_id == "skin_angel" or skin_id == "skin_immortal" or skin_id == "skin_witch")
	var bob: int = 0
	if is_floating:
		# Bay lơ lửng nhịp nhàng (0 -> -1 -> -2 -> -1)
		bob = -1 if (step == 1 or step == 3) else (-2 if step == 2 else 0)
	elif skin_id == "skin_vocaloid" or skin_id == "skin_fox":
		# Nhún nhảy sinh động
		bob = -1 if (step == 1 or step == 3) else 0
	else:
		bob = 1 if (step % 2 == 1) else 0

	var lean: int = 0
	if running:
		lean = 3 if skin_id == "skin_ninja" else 1
	var flow: int = -1 if (step == 0) else (0 if (step == 1 or step == 3) else 1)
	var wing_phase: int = -3 if (step == 0) else (0 if (step == 1 or step == 3) else 3)

	var outline := Color(0.10, 0.07, 0.14)
	var sk: Dictionary = SaveManager.SKIN_CATALOG.get(skin_id, SaveManager.SKIN_CATALOG["skin_default"])
	var hair_d: Color = sk["hair_d"]
	var hair_m: Color = sk["hair_m"]
	var hair_h: Color = sk["hair_h"]
	var hair_spec: Color = hair_h.lightened(0.32)
	var skin_c := Color(0.99, 0.89, 0.81)
	var skin_shade := Color(0.88, 0.72, 0.64)
	var blush := Color(0.96, 0.58, 0.62)
	var eye_iris: Color = sk["eye"]

	var robe_white: Color = sk["robe"]
	var robe_shade: Color = robe_white.darkened(0.16)
	var coat_d: Color = sk["coat_d"]
	var coat_m: Color = sk["coat_m"]
	var coat_h: Color = coat_m.lightened(0.22)
	var vfx_col: Color = sk.get("vfx_color", Color(1.0, 0.35, 0.25))
	var gold := Color(0.99, 0.82, 0.28)
	var gold_d := Color(0.72, 0.50, 0.14)
	var boot_d := Color(0.14, 0.11, 0.18)

	# Khăn/dải lụa: Kiếm Khách mặc định ưu tiên dải đỏ rực chuẩn ảnh mẫu (trừ khi người chơi đổi khăn khác ở Bảng Truy Nã)
	var sp: Dictionary = SaveManager.SCARF_PALETTES.get(scarf_id, SaveManager.SCARF_PALETTES["blue"])
	var ribbon_d: Color = Color(0.56, 0.08, 0.12) if (skin_id == "skin_default" and scarf_id == "blue") else (sp["dark"] as Color)
	var ribbon_m: Color = Color(0.90, 0.16, 0.20) if (skin_id == "skin_default" and scarf_id == "blue") else (sp["mid"] as Color)
	var ribbon_h: Color = Color(1.0, 0.44, 0.36) if (skin_id == "skin_default" and scarf_id == "blue") else (sp["hi"] as Color)

	var cx: int = 23 + lean
	var cy_head: int = 16 + bob

	# =========================================================================
	# LỚP 1 (PHÍA SAU LƯNG): Cánh, Đuôi Hồ Ly, Kim Long Hoàng Đế, Tóc Dài, Dải Lụa
	# =========================================================================
	match skin_id:
		"skin_default":
			# Dải lụa đỏ rực tung bay 2 nhánh đầy khí thế sau lưng Chiến Giáp Kiếm Khách!
			var sx: int = cx - 10 - (3 if running else 0)
			_fill_rect(img, sx, 19 + bob + flow, 10, 4, ribbon_d)
			_fill_rect(img, sx + 1, 19 + bob + flow, 8, 2, ribbon_m)
			_fill_rect(img, sx - 5, 22 + bob - flow, 8, 3, ribbon_m)
			_fill_rect(img, sx - 4, 22 + bob - flow, 6, 1, ribbon_h)
			_fill_rect(img, sx - 3, 27 + bob + flow, 9, 3, ribbon_d)
			_fill_rect(img, sx - 2, 27 + bob + flow, 7, 2, ribbon_m)

		"skin_fox":
			# 3 CHIẾC ĐUÔI CỬU VĨ BẠCH HỒ BỒNG BỀNH VẪY THEO TỪNG FRAME!
			var wag: int = -2 if step == 0 else (2 if step == 2 else 0)
			var tx: int = cx - 12 - (2 if running else 0)
			var fur_w := Color(0.99, 0.99, 1.0)
			var fur_s := Color(0.76, 0.85, 0.96)
			# Đuôi trên
			_fill_circle(img, tx + 2, 24 + bob + wag, 5, fur_w)
			_fill_circle(img, tx - 1, 21 + bob + wag, 4, fur_w)
			_fill_circle(img, tx + 3, 25 + bob + wag, 3, fur_s)
			# Đuôi giữa
			_fill_circle(img, tx - 2, 31 + bob - wag, 5, fur_w)
			_fill_circle(img, tx - 4, 30 + bob - wag, 3, fur_s)
			# Đuôi dưới
			_fill_circle(img, tx + 3, 35 + bob + wag, 4, fur_w)
			_fill_circle(img, tx + 1, 36 + bob + wag, 3, fur_s)

		"skin_angel":
			# ĐÔI CÁNH THIÊN SỨ LÔNG VŨ TRẮNG KHỔNG LỒ VỖ NHỊP NHÀNG (wing_phase)!
			var wing_w := Color(0.99, 0.99, 1.0)
			var wing_s := Color(0.84, 0.88, 0.96)
			var wy: int = 20 + bob + wing_phase
			# Cánh trái
			_fill_rect(img, cx - 18, wy, 12, 6, wing_w)
			_fill_rect(img, cx - 20, wy + 2, 8, 5, wing_w)
			_fill_rect(img, cx - 16, wy + 6, 10, 5, wing_s)
			_fill_rect(img, cx - 13, wy + 10, 7, 4, wing_w)
			# Cánh phải
			_fill_rect(img, cx + 6, wy, 12, 6, wing_w)
			_fill_rect(img, cx + 12, wy + 2, 8, 5, wing_w)
			_fill_rect(img, cx + 6, wy + 6, 10, 5, wing_s)
			_fill_rect(img, cx + 6, wy + 10, 7, 4, wing_w)

		"skin_demon":
			# ĐÔI CÁNH DƠI ÁC MA ĐEN-ĐỎ VỖ MẠNH MẼ THEO TỪNG FRAME!
			var bat_d := Color(0.14, 0.05, 0.10)
			var bat_m := Color(0.56, 0.08, 0.16)
			var bat_hi := Color(0.90, 0.16, 0.26)
			var wy: int = 19 + bob + wing_phase
			# Cánh dơi trái
			_fill_rect(img, cx - 19, wy, 13, 3, bat_d)
			_fill_rect(img, cx - 18, wy + 3, 12, 6, bat_m)
			_fill_rect(img, cx - 20, wy + 1, 3, 7, bat_d)
			_fill_rect(img, cx - 14, wy + 8, 4, 4, bat_hi)
			_fill_rect(img, cx - 19, wy + 7, 3, 4, bat_d)
			# Cánh dơi phải
			_fill_rect(img, cx + 6, wy, 13, 3, bat_d)
			_fill_rect(img, cx + 6, wy + 3, 12, 6, bat_m)
			_fill_rect(img, cx + 17, wy + 1, 3, 7, bat_d)
			_fill_rect(img, cx + 10, wy + 8, 4, 4, bat_hi)
			_fill_rect(img, cx + 16, wy + 7, 3, 4, bat_d)

		"skin_emperor":
			# KIM LONG HOÀNG KIM UỐN LƯỢN PHÍA SAU LƯNG HOÀNG ĐẾ THEO TỪNG FRAME!
			var dw: int = -2 if step == 0 else (2 if step == 2 else 0)
			var dr_glow := Color(1.0, 0.92, 0.42)
			var dr_gold := Color(0.96, 0.72, 0.14)
			var dr_dark := Color(0.68, 0.42, 0.06)
			# Thân rồng cong hình chữ S sau lưng
			_fill_circle(img, cx - 13, 16 + bob + dw, 4, dr_gold)
			_fill_circle(img, cx - 13, 15 + bob + dw, 2, dr_glow)
			_fill_circle(img, cx - 10, 11 + bob - dw, 3, dr_gold)
			_fill_circle(img, cx + 12, 14 + bob - dw, 4, dr_gold)
			_fill_circle(img, cx + 14, 12 + bob - dw, 3, dr_glow) # Đầu rồng vàng phía trên bên phải!
			img.set_pixel(cx + 15, 11 + bob - dw, Color(1.0, 0.22, 0.16)) # Mắt rồng đỏ rực
			_fill_circle(img, cx + 13, 21 + bob + dw, 4, dr_dark)
			_fill_circle(img, cx + 11, 27 + bob - dw, 4, dr_gold)
			_fill_circle(img, cx - 14, 24 + bob - dw, 4, dr_dark)
			_fill_circle(img, cx - 12, 31 + bob + dw, 3, dr_glow)

		"skin_vocaloid":
			# HAI BÍM TÓC XANH NGỌC SIÊU DÀI NHÚN NHẢY LỆCH PHA ĐẶC TRƯNG VOCALOID!
			var bounce_l: int = -2 if (step == 0 or step == 1) else 2
			var bounce_r: int = -bounce_l
			# Bím trái dài uốn lượn
			_fill_rect(img, cx - 16, 15 + bob + bounce_l, 7, 15, hair_d)
			_fill_rect(img, cx - 15, 16 + bob + bounce_l, 5, 13, hair_m)
			_fill_rect(img, cx - 14, 17 + bob + bounce_l, 2, 8, hair_h)
			_fill_rect(img, cx - 18, 28 + bob + bounce_l, 6, 10, hair_m)
			_fill_rect(img, cx - 17, 30 + bob + bounce_l, 3, 7, hair_h)
			# Bím phải dài uốn lượn
			_fill_rect(img, cx + 9, 15 + bob + bounce_r, 7, 15, hair_d)
			_fill_rect(img, cx + 10, 16 + bob + bounce_r, 5, 13, hair_m)
			_fill_rect(img, cx + 11, 17 + bob + bounce_r, 2, 8, hair_h)
			_fill_rect(img, cx + 12, 28 + bob + bounce_r, 6, 10, hair_m)
			_fill_rect(img, cx + 13, 30 + bob + bounce_r, 3, 7, hair_h)
			# Cặp nơ buộc 2 bên tóc
			_fill_rect(img, cx - 11, 12 + bob, 4, 3, Color(0.12, 0.14, 0.22))
			_fill_rect(img, cx + 7, 12 + bob, 4, 3, Color(0.12, 0.14, 0.22))

		"skin_immortal", "skin_miko", "skin_witch":
			# Tóc dài buông xõa bay nhẹ trong gió sau lưng
			var sway_h: int = flow - (2 if running else 0)
			_fill_rect(img, cx - 10 + sway_h, 19 + bob, 20, 17, hair_d)
			_fill_rect(img, cx - 8 + sway_h, 20 + bob, 16, 14, hair_m)
			_fill_rect(img, cx - 11 + sway_h, 30 + bob, 6, 7, hair_d)
			_fill_rect(img, cx + 5 + sway_h, 30 + bob, 6, 7, hair_d)

		"skin_ninja":
			# Đuôi băng trán Ninja tung bay cực gắt phía sau đầu
			var nx: int = cx - 12 - (3 if running else 0)
			_fill_rect(img, nx, 13 + bob + flow, 7, 2, Color(0.16, 0.18, 0.26))
			_fill_rect(img, nx - 4, 15 + bob - flow, 6, 2, Color(0.16, 0.18, 0.26))

	# =========================================================================
	# LỚP 2: ĐẦU, TÓC ANIME ĐẶC TRƯNG TỪNG SKIN & PHỤ KIỆN ĐỈNH ĐẦU
	# =========================================================================
	_fill_circle(img, cx, cy_head, 9, hair_d)
	_fill_circle(img, cx, cy_head - 1, 8, hair_m)

	# Tạo dáng tóc & phụ kiện đầu riêng cho 10 Skin!
	match skin_id:
		"skin_default":
			# Tóc đen xoăn dựng kiểu anime (nhiều lọn tóc nhọn tỉa phóng khoáng)
			_fill_rect(img, cx - 10, cy_head - 6, 4, 4, hair_d)
			_fill_rect(img, cx - 6, cy_head - 11, 4, 4, hair_d)
			_fill_rect(img, cx - 1, cy_head - 12, 4, 5, hair_m)
			_fill_rect(img, cx + 4, cy_head - 10, 4, 4, hair_d)
			_fill_rect(img, cx + 7, cy_head - 6, 4, 4, hair_d)
		"skin_ninja":
			# Tóc vàng dựng nhọn đặc trưng + Băng trán thép sáng loáng!
			_fill_rect(img, cx - 9, cy_head - 8, 4, 4, hair_m)
			_fill_rect(img, cx - 5, cy_head - 12, 4, 5, hair_h)
			_fill_rect(img, cx, cy_head - 13, 4, 6, hair_h)
			_fill_rect(img, cx + 5, cy_head - 11, 4, 5, hair_m)
			_fill_rect(img, cx + 8, cy_head - 7, 3, 4, hair_m)
			# Băng trán vải đen + miếng thép bạc ở giữa trán
			_fill_rect(img, cx - 8, cy_head - 5, 16, 3, Color(0.14, 0.16, 0.24))
			_fill_rect(img, cx - 4, cy_head - 5, 8, 3, Color(0.82, 0.88, 0.96))
			_fill_rect(img, cx - 2, cy_head - 4, 4, 1, Color(0.32, 0.38, 0.48))
		"skin_fox":
			# ĐÔI TAI CÁO BẠCH HỒ CAO NHỌN LÔNG BỒNG BỀNH
			var ear_in := Color(0.88, 0.72, 0.84)
			_fill_rect(img, cx - 9, cy_head - 13, 5, 7, hair_h)
			_fill_rect(img, cx - 8, cy_head - 15, 3, 3, hair_m)
			_fill_rect(img, cx - 8, cy_head - 12, 3, 5, ear_in)
			_fill_rect(img, cx + 4, cy_head - 13, 5, 7, hair_h)
			_fill_rect(img, cx + 5, cy_head - 15, 3, 3, hair_m)
			_fill_rect(img, cx + 5, cy_head - 12, 3, 5, ear_in)
		"skin_angel":
			# VÒNG HÀO QUANG VÀNG LƠ LỬNG TRÊN ĐẦU (bob riêng biệt!)
			var halo_y: int = cy_head - 13 + (1 if (step % 2 == 1) else 0)
			_fill_rect(img, cx - 7, halo_y, 14, 2, Color(1.0, 0.90, 0.36))
			_fill_rect(img, cx - 5, halo_y - 1, 10, 1, Color(1.0, 0.98, 0.78))
			_fill_rect(img, cx - 5, halo_y + 2, 10, 1, Color(0.95, 0.74, 0.18))
		"skin_immortal":
			# Búi tóc Tiên Nhân đỉnh đầu cài trâm bạc lam
			_fill_circle(img, cx, cy_head - 10, 4, hair_d)
			_fill_circle(img, cx, cy_head - 10, 3, hair_m)
			_fill_rect(img, cx - 6, cy_head - 11, 12, 2, Color(0.76, 0.92, 1.0))
			_fill_rect(img, cx - 7, cy_head - 12, 2, 3, Color(0.32, 0.74, 1.0))
		"skin_demon":
			# Tóc bạc dựng gai góc + cặp sừng ác ma nhỏ đỏ đen
			_fill_rect(img, cx - 8, cy_head - 10, 4, 4, hair_m)
			_fill_rect(img, cx - 2, cy_head - 12, 5, 5, hair_h)
			_fill_rect(img, cx + 4, cy_head - 10, 4, 4, hair_m)
			_fill_rect(img, cx - 9, cy_head - 12, 3, 4, Color(0.75, 0.10, 0.18))
			_fill_rect(img, cx + 6, cy_head - 12, 3, 4, Color(0.75, 0.10, 0.18))
		"skin_miko":
			# MẶT NẠ CÁO KITSUNE TRẮNG VIỀN ĐỎ ĐEO NGHIÊNG BÊN MÁI TÓC!
			_fill_circle(img, cx + 6, cy_head - 7, 5, Color(0.99, 0.98, 0.96))
			_fill_rect(img, cx + 3, cy_head - 13, 2, 3, Color(0.99, 0.98, 0.96)) # Tai mặt nạ trái
			_fill_rect(img, cx + 8, cy_head - 12, 2, 3, Color(0.99, 0.98, 0.96)) # Tai mặt nạ phải
			_fill_rect(img, cx + 4, cy_head - 8, 2, 1, Color(0.92, 0.14, 0.18))  # Họa tiết đỏ mặt nạ
			_fill_rect(img, cx + 7, cy_head - 7, 2, 1, Color(0.92, 0.14, 0.18))
			img.set_pixel(cx + 6, cy_head - 5, Color(0.92, 0.14, 0.18))
			# Nơ đỏ nhỏ bên trái tóc
			_fill_rect(img, cx - 8, cy_head - 7, 4, 3, Color(0.92, 0.16, 0.22))
		"skin_emperor":
			# VƯƠNG MIỆN LONG ĐẾ HOÀNG KIM TRÊN ĐỈNH ĐẦU!
			_fill_rect(img, cx - 6, cy_head - 11, 12, 4, gold_d)
			_fill_rect(img, cx - 5, cy_head - 12, 10, 3, gold)
			_fill_rect(img, cx - 6, cy_head - 14, 2, 3, gold)
			_fill_rect(img, cx - 1, cy_head - 15, 3, 4, Color(1.0, 0.94, 0.56))
			_fill_rect(img, cx + 4, cy_head - 14, 2, 3, gold)
			img.set_pixel(cx, cy_head - 12, Color(0.98, 0.18, 0.20)) # Viên hồng ngọc giữa vương miện
		"skin_witch":
			# Cài tóc hoa tím vàng huyền bí
			_fill_rect(img, cx - 7, cy_head - 9, 4, 3, Color(0.76, 0.36, 1.0))
			_fill_rect(img, cx - 6, cy_head - 8, 2, 1, gold)

	# Vầng sáng ngang đỉnh tóc chuẩn Anime
	if skin_id != "skin_ninja":
		_fill_rect(img, cx - 5, cy_head - 6, 10, 2, hair_h)
		_fill_rect(img, cx - 3, cy_head - 6, 5, 1, hair_spec)

	# =========================================================================
	# LỚP 3: KHUÔN MẶT ANIME CHIBI THANH TÚ (Mắt to long lanh có tròng màu & chấm sáng)
	# =========================================================================
	_fill_rect(img, cx - 5, cy_head - 2, 11, 9, skin_c)
	_fill_rect(img, cx - 5, cy_head - 2, 11, 1, skin_shade)
	_fill_rect(img, cx - 4, cy_head + 6, 9, 1, skin_shade)
	# Tóc mai rủ 2 bên má & mái tỉa nhọn kiểu anime
	_fill_rect(img, cx - 7, cy_head - 3, 3, 12, hair_d)
	_fill_rect(img, cx - 6, cy_head - 3, 2, 10, hair_m)
	_fill_rect(img, cx + 5, cy_head - 3, 3, 10, hair_d)
	_fill_rect(img, cx - 5, cy_head - 4, 11, 3, hair_m)
	img.set_pixel(cx - 2, cy_head - 1, hair_d)
	img.set_pixel(cx + 2, cy_head - 1, hair_d)
	# Cặp mắt anime sắc nét 3x3px
	_fill_rect(img, cx - 4, cy_head + 1, 3, 3, outline)
	_fill_rect(img, cx + 2, cy_head + 1, 3, 3, outline)
	_fill_rect(img, cx - 3, cy_head + 2, 2, 2, eye_iris)
	_fill_rect(img, cx + 2, cy_head + 2, 2, 2, eye_iris)
	img.set_pixel(cx - 4, cy_head + 1, Color.WHITE)
	img.set_pixel(cx + 2, cy_head + 1, Color.WHITE)
	# Má hồng nhẹ
	_fill_rect(img, cx - 5, cy_head + 4, 2, 1, blush)
	img.set_pixel(cx + 5, cy_head + 4, blush)

	# =========================================================================
	# LỚP 4: TRANG PHỤC & GIÁP CHIBI RIÊNG BIỆT CHO TỪNG SKIN
	# =========================================================================
	var ty: int = 25 + bob
	var skirt_fl: int = 2 if running else 0
	match skin_id:
		"skin_default":
			# CHIẾN GIÁP HUYỀN BÍ (Giáp vai đen viền vàng, khăn lụa đỏ vòng cổ, áo choàng trắng-đỏ xẻ tà)
			_fill_rect(img, cx - 7, ty - 2, 15, 3, ribbon_d)
			_fill_rect(img, cx - 6, ty - 2, 13, 2, ribbon_m)
			_fill_rect(img, cx - 8, ty, 17, 10, coat_d)
			_fill_rect(img, cx - 5, ty + 1, 11, 9, robe_white)
			# Giáp vai đen viền vàng kim nổi bật
			_fill_rect(img, cx - 9, ty, 5, 6, coat_d)
			_fill_rect(img, cx - 9, ty, 5, 1, gold)
			_fill_rect(img, cx + 5, ty, 5, 6, coat_d)
			_fill_rect(img, cx + 5, ty, 5, 1, gold)
			# Thắt lưng đỏ vàng + Tà áo trắng viền đỏ bay phấp phới
			_fill_rect(img, cx - 7, ty + 6, 15, 2, coat_m)
			_fill_rect(img, cx - 2, ty + 6, 5, 2, gold)
			_fill_rect(img, cx - 8 - skirt_fl, ty + 8, 17 + skirt_fl * 2, 8, robe_white)
			_fill_rect(img, cx - 8 - skirt_fl, ty + 14, 17 + skirt_fl * 2, 2, coat_m)
			_fill_rect(img, cx - 1, ty + 9, 3, 7, coat_d) # Đường xẻ tà giữa

		"skin_ninja":
			# Áo khoác Ninja cam-đen kéo khóa + quần đen gọn gàng tốc độ!
			_fill_rect(img, cx - 7, ty - 1, 15, 11, coat_m)
			_fill_rect(img, cx - 7, ty - 1, 15, 3, robe_white) # Cổ áo cao đen
			_fill_rect(img, cx - 1, ty + 2, 3, 8, robe_white)  # Khóa kéo đen giữa ngực
			_fill_rect(img, cx - 8, ty + 1, 3, 8, coat_d)
			_fill_rect(img, cx + 6, ty + 1, 3, 8, coat_d)
			_fill_rect(img, cx - 7, ty + 9, 15, 5, robe_white)
			_fill_rect(img, cx - 7, ty + 8, 15, 2, Color(0.95, 0.95, 0.95)) # Đai băng quấn eo

		"skin_miko":
			# Áo trắng thần xã (Haori) tay rộng + Váy Hakama đỏ rực
			_fill_rect(img, cx - 8, ty, 17, 8, robe_white)
			_fill_rect(img, cx - 3, ty, 7, 3, coat_m) # Cổ đỏ
			_fill_rect(img, cx - 10, ty + 1, 4, 8, robe_white) # Tay áo rộng trái
			_fill_rect(img, cx + 7, ty + 1, 4, 8, robe_white)  # Tay áo rộng phải
			_fill_rect(img, cx - 8 - skirt_fl, ty + 7, 17 + skirt_fl * 2, 10, coat_m)
			_fill_rect(img, cx - 7 - skirt_fl, ty + 7, 15 + skirt_fl * 2, 2, coat_d)
			_fill_rect(img, cx - 2, ty + 7, 5, 4, Color(0.99, 0.95, 0.88)) # Nơ trắng trước hakama

		"skin_vocaloid":
			# Trang phục Idol Vocaloid: áo sơ mi trắng cà vạt xanh ngọc + váy xếp ly đen viền xanh
			_fill_rect(img, cx - 6, ty, 13, 8, robe_white)
			_fill_rect(img, cx - 1, ty + 1, 3, 7, coat_m) # Cà vạt xanh ngọc nổi bật
			_fill_rect(img, cx - 8, ty + 2, 3, 6, coat_d) # Ống tay đen viền cyan
			_fill_rect(img, cx + 6, ty + 2, 3, 6, coat_d)
			_fill_rect(img, cx - 8 - skirt_fl, ty + 8, 17 + skirt_fl * 2, 6, coat_d)
			_fill_rect(img, cx - 8 - skirt_fl, ty + 13, 17 + skirt_fl * 2, 2, coat_m)

		"skin_emperor":
			# LONG BÀO HOÀNG ĐẾ ĐEN VÀNG CỰC OAI NGHIÊM
			_fill_rect(img, cx - 8, ty - 1, 17, 17, robe_white)
			_fill_rect(img, cx - 9, ty, 5, 5, gold) # Giáp vai rồng vàng
			_fill_rect(img, cx + 5, ty, 5, 5, gold)
			_fill_rect(img, cx - 4, ty, 9, 16, coat_d)
			_fill_rect(img, cx - 2, ty + 1, 5, 14, coat_m) # Dải rồng vàng dọc thân
			_fill_rect(img, cx - 8, ty + 7, 17, 2, gold)   # Đai ngọc hoàng kim
			_fill_rect(img, cx - 8 - skirt_fl, ty + 14, 17 + skirt_fl * 2, 2, gold)

		_:
			# Tiên Nhân / Hồ Ly / Ma Nữ / Ác Ma / Thiên Sứ (Áo choàng & váy cổ trang nhiều tầng)
			_fill_rect(img, cx - 7, ty - 1, 15, 2, coat_m)
			_fill_rect(img, cx - 7, ty + 1, 15, 13, robe_shade)
			_fill_rect(img, cx - 6, ty + 1, 13, 12, robe_white)
			_fill_rect(img, cx - 9, ty + 1, 5, 10, coat_d)
			_fill_rect(img, cx - 8, ty + 1, 4, 9, coat_m)
			_fill_rect(img, cx + 5, ty + 1, 5, 10, coat_m)
			_fill_rect(img, cx - 7, ty + 7, 15, 2, coat_d)
			_fill_rect(img, cx - 6, ty + 7, 13, 1, gold)
			_fill_rect(img, cx - 8 - skirt_fl, ty + 11, 17 + skirt_fl * 2, 6, robe_white)
			_fill_rect(img, cx - 8 - skirt_fl, ty + 15, 17 + skirt_fl * 2, 2, coat_m)
			_fill_rect(img, cx - 8 - skirt_fl, ty + 14, 17 + skirt_fl * 2, 1, gold_d)

	# =========================================================================
	# LỚP 5: ĐÔI CHÂN / HÀI CHUYỂN ĐỘNG THEO TỪNG SKIN (Thiên Sứ/Tiên Nhân bay nhẹ)
	# =========================================================================
	var foot_y: int = 41 + (bob if is_floating else 0)
	var left_dy: int = -2 if (running and step == 0) else 0
	var right_dy: int = -2 if (running and step == 2) else 0
	var left_dx: int = -2 if (running and step == 0) else (1 if (running and step == 2) else 0)
	var right_dx: int = -left_dx
	if is_floating and not running:
		left_dy = -1
		right_dy = 0
	var boot_trim: Color = coat_m if skin_id != "skin_emperor" else gold
	_fill_rect(img, cx - 6 + left_dx, foot_y + left_dy, 4, 6, boot_d)
	_fill_rect(img, cx - 5 + left_dx, foot_y + 4 + left_dy, 3, 2, boot_trim)
	_fill_rect(img, cx + 2 + right_dx, foot_y + right_dy, 4, 6, boot_d)
	_fill_rect(img, cx + 3 + right_dx, foot_y + 4 + right_dy, 3, 2, boot_trim)

	# =========================================================================
	# LỚP 6: VŨ KHÍ + HIỆU ỨNG KIẾM LỬA / LINH KHÍ THEO SKIN & HỆ VŨ KHÍ
	# =========================================================================
	_draw_hero_weapon_pose(img, weapon_type, attacking, sword_pose, bob + 3, lean + 2, gold, vfx_col, skin_id)

	# =========================================================================
	# LỚP 7 (TRƯỚC MẶT): BƯỚM TÍM MA NỮ BAY LƯỢN QUANH NGƯỜI THEO TỪNG FRAME!
	# =========================================================================
	if skin_id == "skin_witch":
		var b_col := Color(0.86, 0.48, 1.0)
		var b_hi := Color(1.0, 0.88, 1.0)
		var bx1: int = 7 + (step * 2)
		var by1: int = 13 + (2 if (step % 2 == 1) else -2)
		var bx2: int = 39 - (step * 2)
		var by2: int = 24 + (-2 if (step % 2 == 1) else 2)
		var bx3: int = 11 + ((3 - step) * 2)
		var by3: int = 36 + flow
		# Vẽ 3 chú bướm tím mini vỗ cánh
		for b_pos: Vector2i in [Vector2i(bx1, by1), Vector2i(bx2, by2), Vector2i(bx3, by3)]:
			_fill_rect(img, b_pos.x - 2, b_pos.y - 1, 2, 2, b_col)
			_fill_rect(img, b_pos.x + 1, b_pos.y - 1, 2, 2, b_col)
			img.set_pixel(clampi(b_pos.x, 0, w - 1), clampi(b_pos.y, 0, h - 1), b_hi)

	_apply_clean_outline(img, outline)
	if modulate_col != Color.WHITE:
		_tint_image(img, modulate_col)

	return ImageTexture.create_from_image(img)


## Vẽ tạo hình và các khung hình tấn công riêng cho 4 loại vũ khí cổ trang + Hào quang lưỡi kiếm theo Skin!
## - Kiếm Khách mặc định cầm thanh KIẾM LỬA ĐỎ RỰC ngay cả khi đứng/chạy giống hệt ảnh mẫu!
static func _draw_hero_weapon_pose(img: Image, weapon_type: String, attacking: bool, pose: int, bob: int, lean: int, gold: Color, accent_col: Color, skin_id: String = "skin_default") -> void:
	var steel_d := Color(0.46, 0.66, 0.80)
	var steel_m := Color(0.84, 0.95, 1.0)
	var steel_hi := Color(1.0, 1.0, 1.0)
	var wood_c := Color(0.48, 0.28, 0.14)
	var is_flame_hero: bool = (skin_id == "skin_default" or skin_id == "skin_demon")

	match weapon_type:
		"saber":
			var saber_glow: Color = accent_col if is_flame_hero else Color(1.0, 0.44, 0.22)
			if attacking:
				if pose == 1:
					_fill_rect(img, 26, 6 + bob, 6, 18, saber_glow)
					_fill_rect(img, 28, 7 + bob, 3, 16, steel_hi)
					_fill_rect(img, 25, 24 + bob, 8, 3, gold)
				elif pose == 2:
					_fill_rect(img, 27, 22 + bob, 18, 6, saber_glow)
					_fill_rect(img, 28, 23 + bob, 16, 3, steel_hi)
					_fill_rect(img, 25, 22 + bob, 3, 7, gold)
				else:
					_fill_rect(img, 24, 11 + bob, 22, 18, Color(saber_glow.r, saber_glow.g, saber_glow.b, 0.82))
					_fill_rect(img, 27, 16 + bob, 18, 8, Color(1.0, 0.94, 0.72))
					_fill_rect(img, 24, 18 + bob, 4, 7, gold)
			else:
				_fill_rect(img, 8 + lean, 18 + bob, 4, 14, steel_d)
				_fill_rect(img, 9 + lean, 19 + bob, 2, 12, steel_m)
				_fill_rect(img, 7 + lean, 31 + bob, 6, 2, gold)
				_fill_rect(img, 9 + lean, 33 + bob, 2, 4, accent_col)

		"bow":
			var bow_col := Color(0.68, 0.44, 0.18)
			var arrow_glow: Color = accent_col if pose >= 3 else Color(0.65, 1.0, 0.48)
			if attacking:
				_fill_rect(img, 32, 14 + bob, 3, 5, bow_col)
				_fill_rect(img, 34, 19 + bob, 3, 11, bow_col)
				_fill_rect(img, 32, 30 + bob, 3, 5, bow_col)
				_fill_rect(img, 29, 16 + bob, 1, 17, Color(0.95, 0.92, 0.85))
				var arrow_x: int = 27 if pose == 1 else (30 if pose == 2 else 32)
				_fill_rect(img, arrow_x, 23 + bob, 14, 3, arrow_glow)
				_fill_rect(img, arrow_x + 2, 24 + bob, 11, 1, Color.WHITE)
				if pose >= 3:
					_fill_circle(img, 38, 24 + bob, 4, Color(1.0, 0.88, 0.35, 0.8))
			else:
				_fill_rect(img, 9 + lean, 16 + bob, 2, 16, bow_col)
				_fill_rect(img, 11 + lean, 14 + bob, 3, 3, gold)
				_fill_rect(img, 11 + lean, 31 + bob, 3, 3, gold)

		"staff":
			var orb_col: Color = accent_col
			if attacking:
				var tilt_x: int = 32 if pose == 1 else 34
				_fill_rect(img, tilt_x, 12 + bob, 3, 26, wood_c)
				_fill_rect(img, tilt_x - 2, 9 + bob, 7, 3, gold)
				_fill_circle(img, tilt_x + 1, 8 + bob, 5 if pose >= 3 else 4, orb_col)
				_fill_circle(img, tilt_x + 1, 8 + bob, 2, Color.WHITE)
				if pose >= 2:
					_fill_circle(img, 40, 16 + bob, 4, orb_col)
					_fill_circle(img, 40, 16 + bob, 2, Color.WHITE)
			else:
				_fill_rect(img, 10 + lean, 14 + bob, 3, 25, wood_c)
				_fill_rect(img, 9 + lean, 12 + bob, 5, 2, gold)
				_fill_circle(img, 11 + lean, 10 + bob, 3, orb_col)
				img.set_pixel(11 + lean, 9 + bob, Color.WHITE)

		_: # "sword" — Thanh Kiếm Cổ Trang (với hiệu ứng Kiếm Lửa Đỏ rực chuẩn ảnh mẫu cho Kiếm Khách!)
			var blade_edge: Color = Color(1.0, 0.24, 0.16) if is_flame_hero else steel_d
			var blade_core: Color = Color(1.0, 0.78, 0.36) if is_flame_hero else steel_m
			if attacking:
				if pose == 1:
					_fill_rect(img, 30, 9 + bob, 4, 18, blade_edge)
					_fill_rect(img, 31, 10 + bob, 2, 16, blade_core)
					_fill_rect(img, 32, 11 + bob, 1, 12, steel_hi)
					_fill_rect(img, 28, 26 + bob, 7, 2, gold)
				elif pose == 2:
					_fill_rect(img, 29, 23 + bob, 17, 5, blade_edge)
					_fill_rect(img, 30, 24 + bob, 15, 3, blade_core)
					_fill_rect(img, 31, 25 + bob, 12, 1, steel_hi)
					_fill_rect(img, 27, 23 + bob, 2, 6, gold)
				elif pose == 3:
					_fill_rect(img, 28, 18 + bob, 18, 6, accent_col)
					_fill_rect(img, 30, 19 + bob, 15, 3, steel_hi)
					_fill_rect(img, 26, 20 + bob, 2, 5, gold)
				else:
					_fill_rect(img, 26, 11 + bob, 20, 17, Color(accent_col.r, accent_col.g, accent_col.b, 0.80))
					_fill_rect(img, 28, 16 + bob, 17, 6, steel_hi)
					_fill_rect(img, 26, 18 + bob, 3, 6, gold)
			else:
				if is_flame_hero:
					# Kiếm lửa đỏ cầm sẵn bên tay phải hệt như nhân vật Kiếm Khách trong ảnh mẫu!
					_fill_rect(img, 31 + lean, 31 + bob, 3, 2, gold)
					_fill_rect(img, 33 + lean, 32 + bob, 4, 3, blade_edge)
					_fill_rect(img, 36 + lean, 34 + bob, 5, 3, blade_edge)
					_fill_rect(img, 34 + lean, 33 + bob, 5, 2, blade_core)
					_fill_rect(img, 39 + lean, 36 + bob, 4, 2, Color(1.0, 0.92, 0.65))
				else:
					_fill_rect(img, 10 + lean, 31 + bob, 5, 3, Color(0.14, 0.12, 0.18))
					_fill_rect(img, 7 + lean, 33 + bob, 5, 2, Color(0.14, 0.12, 0.18))
					_fill_rect(img, 13 + lean, 29 + bob, 3, 3, gold)
					_fill_rect(img, 11 + lean, 34 + bob, 2, 4, accent_col)


## 7 LOẠI QUÁI ANIME CHIBI + 5 BOSS HUYỀN THOẠI (chuẩn ảnh mẫu Chronicles of Windferry!)
static func _make_enemy_frame(archetype: String, step: int, attacking: bool, tint: Color) -> ImageTexture:
	# Ánh xạ tương thích cho các archetype cũ nếu còn được gọi
	var vid: String = archetype
	match archetype:
		"melee": vid = "bandit"
		"ranged": vid = "ghost"
		"charger": vid = "wolf"
		"tank": vid = "warrior"
		"boss": vid = "boss_darklord"

	var is_boss: bool = vid.begins_with("boss_")
	var is_heavy: bool = (vid == "warrior" or vid == "golem")
	var w: int = 72 if is_boss else (52 if is_heavy else 44)
	var h: int = 74 if is_boss else (54 if is_heavy else 46)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bob: int = 1 if (step % 2 == 1) else 0
	var wing_dy: int = -3 if (step == 0) else (3 if (step == 2) else 0)
	var sway: int = -1 if (step == 0) else (1 if (step == 2) else 0)
	var outline := Color(0.09, 0.06, 0.14)
	var gold := Color(0.99, 0.82, 0.28)
	var skin_c := Color(0.99, 0.89, 0.81)

	match vid:
		# =====================================================================
		# 7 LOẠI QUÁI ANIME ĐA DẠNG (HÀNG TRÊN ẢNH MẪU)
		# =====================================================================
		"slime":
			# 1. TINH LINH SLIME: Giọt nước lam trong suốt long lanh + 2 slime mini bay 2 bên + nhún đàn hồi!
			var sq: int = 2 if (step == 1) else (-1 if (step == 2) else 0)
			var b_d := Color(0.14, 0.42, 0.90) * tint
			var b_m := Color(0.32, 0.68, 1.0) * tint
			var b_h := Color(0.72, 0.92, 1.0) * tint
			# 2 bé slime mini bay nhảy 2 bên
			_fill_circle(img, 7, 30 - bob, 4, b_m)
			img.set_pixel(6, 29 - bob, Color.WHITE)
			_fill_circle(img, 36, 28 + bob, 4, b_m)
			img.set_pixel(35, 27 + bob, Color.WHITE)
			# Đỉnh giọt nước uốn cong
			_fill_rect(img, 20 + sway, 10 + sq, 4, 7, b_m)
			_fill_rect(img, 22 + sway, 8 + sq, 3, 4, b_h)
			# Thân slime tròn múp đàn hồi
			_fill_circle(img, 22, 27 + sq, 12, b_d)
			_fill_circle(img, 22, 26 + sq, 10, b_m)
			_fill_rect(img, 14, 20 + sq, 7, 4, b_h)
			_fill_rect(img, 15, 19 + sq, 3, 2, Color.WHITE)
			# Mắt anime dễ thương long lanh & nụ cười
			_fill_rect(img, 16, 25 + sq, 3, 4, Color(0.08, 0.14, 0.34))
			_fill_rect(img, 25, 25 + sq, 3, 4, Color(0.08, 0.14, 0.34))
			img.set_pixel(17, 25 + sq, Color.WHITE)
			img.set_pixel(26, 25 + sq, Color.WHITE)
			_fill_rect(img, 20, 29 + sq, 4, 2, Color(0.95, 0.56, 0.72))
			if attacking:
				_fill_circle(img, 22, 27 + sq, 13, Color(0.55, 0.88, 1.0, 0.35))

		"wolf":
			# 2. SÓI MA: Bạch lang yêu khí lam rực, mắt xanh phát sáng, đuôi lửa lam vẫy mạnh khi lao húc!
			var fur_w := Color(0.94, 0.96, 1.0) * tint
			var fur_s := Color(0.68, 0.78, 0.92) * tint
			var dark_b := Color(0.16, 0.24, 0.54) * tint
			var flame_b := Color(0.32, 0.78, 1.0)
			var stride: int = 2 if (step == 0) else (-2 if (step == 2) else 0)
			# Đuôi lửa lam bồng bềnh sau lưng
			_fill_circle(img, 7, 22 + bob + sway, 6, flame_b)
			_fill_circle(img, 9, 24 + bob + sway, 4, fur_w)
			# Thân sói thon gọn linh hoạt
			_fill_rect(img, 10, 21 + bob, 20, 10, fur_w)
			_fill_rect(img, 10, 21 + bob, 16, 4, dark_b)
			_fill_rect(img, 12, 28 + bob, 16, 3, fur_s)
			# Đầu sói & bờm trắng + đôi tai dựng nhọn
			_fill_circle(img, 28, 18 + bob, 7, fur_w)
			_fill_rect(img, 22, 9 + bob, 4, 6, dark_b)
			_fill_rect(img, 23, 10 + bob, 2, 4, fur_w)
			_fill_rect(img, 28, 9 + bob, 4, 6, dark_b)
			_fill_rect(img, 29, 10 + bob, 2, 4, fur_w)
			_fill_rect(img, 32, 18 + bob, 6, 4, fur_w) # Mõm sói
			_fill_rect(img, 29, 16 + bob, 3, 2, flame_b if not attacking else Color(1.0, 0.35, 0.25))
			# 4 chân sói phi nhanh
			_fill_rect(img, 11 + stride, 30, 4, 10, fur_s)
			_fill_rect(img, 17 - stride, 31, 4, 9, dark_b)
			_fill_rect(img, 25 - stride, 30, 4, 10, fur_w)
			_fill_rect(img, 30 + stride, 31, 4, 9, dark_b)

		"bandit":
			# 3. ĐẠO TẶC: Nón lá tre rộng vành, khăn đỏ, áo xanh lam & SONG KIẾM sắc bén!
			var hat_d := Color(0.62, 0.42, 0.16) * tint
			var hat_m := Color(0.86, 0.64, 0.28) * tint
			var hat_h := Color(0.98, 0.84, 0.48) * tint
			var tunic := Color(0.16, 0.22, 0.44) * tint
			var scarf := Color(0.84, 0.16, 0.20)
			# Nón lá tre chóp nhọn rộng vành đặc trưng
			_fill_rect(img, 17, 6 + bob, 10, 3, hat_h)
			_fill_rect(img, 12, 9 + bob, 20, 3, hat_m)
			_fill_rect(img, 7, 12 + bob, 30, 4, hat_d)
			_fill_rect(img, 9, 12 + bob, 26, 2, hat_m)
			# Mặt chibi & khăn cổ đỏ
			_fill_rect(img, 16, 16 + bob, 12, 7, skin_c)
			_fill_rect(img, 18, 18 + bob, 2, 2, outline)
			_fill_rect(img, 24, 18 + bob, 2, 2, outline)
			_fill_rect(img, 15, 22 + bob, 14, 3, scarf)
			# Áo võ phục xanh lam + đai vàng
			_fill_rect(img, 14, 25 + bob, 16, 11, tunic)
			_fill_rect(img, 14, 31 + bob, 16, 2, gold)
			# Chân
			var l_dy: int = -2 if (step == 0) else 0
			var r_dy: int = -2 if (step == 2) else 0
			_fill_rect(img, 15, 36 + l_dy, 5, 7, Color(0.14, 0.12, 0.20))
			_fill_rect(img, 24, 36 + r_dy, 5, 7, Color(0.14, 0.12, 0.20))
			# Song kiếm vung hai bên!
			var sw_col := Color(0.86, 0.94, 1.0) if not attacking else Color(1.0, 0.84, 0.35)
			_fill_rect(img, 3, 25 + bob - (4 if attacking else 0), 11, 3, sw_col)
			_fill_rect(img, 30, 25 + bob - (4 if attacking else 0), 11, 3, sw_col)
			_fill_rect(img, 12, 24 + bob, 2, 5, gold)
			_fill_rect(img, 30, 24 + bob, 2, 5, gold)

		"ghost":
			# 4. BÓNG MA: Thiếu nữ ma mị tóc tím dài lơ lửng + lửa ma tím & bùa chú bay quanh!
			var fl: int = -2 if (step == 1) else (-1 if (step == 2) else 0)
			var hair_p := Color(0.20, 0.08, 0.36) * tint
			var robe_l := Color(0.84, 0.72, 0.98) * tint
			var robe_p := Color(0.52, 0.22, 0.82) * tint
			var fire_p := Color(0.82, 0.34, 1.0) if not attacking else Color(1.0, 0.42, 0.85)
			# 3 Ngọn lửa ma tím & lá bùa bay quanh
			_fill_circle(img, 7, 17 + fl + sway, 4, fire_p)
			_fill_circle(img, 37, 20 + fl - sway, 4, fire_p)
			_fill_rect(img, 34, 30 + fl, 4, 6, Color(0.98, 0.92, 0.74))
			img.set_pixel(35, 32 + fl, Color(0.88, 0.18, 0.22))
			# Tóc tím dài buông xõa
			_fill_rect(img, 12, 13 + fl, 20, 22, hair_p)
			_fill_circle(img, 22, 14 + fl, 8, hair_p)
			# Mặt anime bí ẩn mắt tím phát sáng
			_fill_rect(img, 17, 13 + fl, 10, 7, Color(0.96, 0.92, 0.98))
			_fill_rect(img, 18, 16 + fl, 2, 2, fire_p)
			_fill_rect(img, 24, 16 + fl, 2, 2, fire_p)
			# Kimono ma mị lơ lửng
			_fill_rect(img, 14, 21 + fl, 16, 15, robe_l)
			_fill_rect(img, 11, 22 + fl, 5, 9, robe_p)
			_fill_rect(img, 28, 22 + fl, 5, 9, robe_p)
			_fill_rect(img, 15, 28 + fl, 14, 3, robe_p)
			_fill_rect(img, 16, 36 + fl, 12, 4, Color(0.68, 0.36, 0.96, 0.65))

		"kitsune":
			# 5. HỒ LY: Bạch hồ yêu có tai cáo đỏ trắng, vòng hào quang vàng & 3 đuôi bông vẫy!
			var fur_w := Color(0.98, 0.96, 0.98) * tint
			var fur_s := Color(0.84, 0.78, 0.86) * tint
			var red_m := Color(0.90, 0.18, 0.22)
			var wag: int = -2 if (step == 0) else (2 if (step == 2) else 0)
			# 3 đuôi hồ ly khổng lồ chóp đỏ vẫy phía sau
			_fill_circle(img, 9, 17 + bob + wag, 6, fur_w)
			_fill_circle(img, 6, 14 + bob + wag, 3, red_m)
			_fill_circle(img, 8, 26 + bob - wag, 6, fur_w)
			_fill_circle(img, 6, 28 + bob - wag, 3, fur_s)
			_fill_circle(img, 14, 22 + bob + wag, 5, fur_w)
			# Vòng hào quang vàng nhỏ sau đầu
			_fill_rect(img, 21, 5 + bob, 12, 2, gold)
			# Đầu cáo trắng + tai lớn viền đỏ
			_fill_circle(img, 27, 16 + bob, 7, fur_w)
			_fill_rect(img, 21, 6 + bob, 4, 7, fur_w)
			_fill_rect(img, 22, 7 + bob, 2, 5, red_m)
			_fill_rect(img, 29, 6 + bob, 4, 7, fur_w)
			_fill_rect(img, 30, 7 + bob, 2, 5, red_m)
			_fill_rect(img, 26, 15 + bob, 2, 2, Color(1.0, 0.62, 0.16))
			_fill_rect(img, 31, 15 + bob, 2, 2, Color(1.0, 0.62, 0.16))
			# Thân yêu hồ + khăn đỏ chuông vàng + 4 chân mảnh
			_fill_rect(img, 18, 22 + bob, 14, 9, fur_w)
			_fill_rect(img, 22, 22 + bob, 10, 3, red_m)
			_fill_rect(img, 28, 24 + bob, 3, 3, gold)
			_fill_rect(img, 19, 31, 3, 10, fur_s)
			_fill_rect(img, 28, 31, 3, 10, fur_w)
			_fill_rect(img, 19, 39, 3, 2, red_m)
			_fill_rect(img, 28, 39, 3, 2, red_m)

		"warrior":
			# 6. CHIẾN BINH (52x54 — Tank có 3 Khiên): Giáp Samurai đen-đỏ-vàng, mũ sừng, thương dài & Đại Khiên Đỏ!
			var arm_d := Color(0.14, 0.11, 0.18) * tint
			var arm_r := Color(0.76, 0.14, 0.18) * tint
			var flame := Color(1.0, 0.36, 0.22)
			# Mũ chiến binh có sừng vàng
			_fill_rect(img, 15, 4 + bob, 3, 7, gold)
			_fill_rect(img, 32, 4 + bob, 3, 7, gold)
			_fill_rect(img, 16, 9 + bob, 18, 9, arm_d)
			_fill_rect(img, 17, 10 + bob, 16, 3, arm_r)
			_fill_rect(img, 19, 14 + bob, 12, 6, skin_c)
			_fill_rect(img, 21, 16 + bob, 2, 2, Color(0.95, 0.18, 0.22))
			_fill_rect(img, 27, 16 + bob, 2, 2, Color(0.95, 0.18, 0.22))
			# Thân chiến giáp đen đỏ viền vàng rực
			_fill_rect(img, 12, 20 + bob, 26, 20, arm_d)
			_fill_rect(img, 14, 21 + bob, 22, 16, arm_r)
			_fill_rect(img, 12, 20 + bob, 26, 3, gold)
			_fill_rect(img, 14, 31 + bob, 22, 3, gold)
			# Ngọn thương rực sáng bên trái
			_fill_rect(img, 6, 8 + bob - (4 if attacking else 0), 3, 36, Color(0.42, 0.24, 0.14))
			_fill_rect(img, 5, 3 + bob - (4 if attacking else 0), 5, 8, flame)
			# ĐẠI KHIÊN THẬP TỰ ĐỎ VÀNG khổng lồ bên phải
			_fill_rect(img, 34, 18 + bob, 13, 24, arm_d)
			_fill_rect(img, 35, 19 + bob, 11, 22, arm_r)
			_fill_rect(img, 39, 20 + bob, 3, 20, gold)
			_fill_rect(img, 35, 28 + bob, 11, 3, gold)
			# Đôi chân bọc giáp
			_fill_rect(img, 15, 40, 8, 10, arm_d)
			_fill_rect(img, 27, 40, 8, 10, arm_d)
			_fill_rect(img, 16, 46, 7, 3, arm_r)
			_fill_rect(img, 28, 46, 7, 3, arm_r)

		"golem":
			# 7. THỦ VỆ ĐÁ (52x54 — Tank 4 Khiên): Golem đá cổ đại phủ rêu xanh & Lõi Cổ Ngữ Ngọc Lam phát sáng!
			var st_d := Color(0.42, 0.44, 0.46) * tint
			var st_m := Color(0.66, 0.68, 0.68) * tint
			var st_h := Color(0.84, 0.86, 0.84) * tint
			var moss := Color(0.28, 0.56, 0.26)
			var rune := Color(0.28, 0.95, 0.96) if not attacking else Color(1.0, 0.84, 0.28)
			# Đầu khối đá + mắt cổ ngữ xanh ngọc
			_fill_rect(img, 19, 6 + bob, 14, 10, st_m)
			_fill_rect(img, 20, 6 + bob, 12, 3, moss)
			_fill_rect(img, 22, 11 + bob, 3, 2, rune)
			_fill_rect(img, 27, 11 + bob, 3, 2, rune)
			# Vai đá khổng lồ & thân cổ thạch có Lõi Rune Ngọc Lam ở ngực
			_fill_rect(img, 5, 15 + bob, 13, 18, st_d)
			_fill_rect(img, 6, 16 + bob, 11, 15, st_m)
			_fill_rect(img, 7, 15 + bob, 8, 3, moss)
			_fill_circle(img, 11, 24 + bob, 3, rune)
			_fill_rect(img, 34, 15 + bob, 13, 18, st_d)
			_fill_rect(img, 35, 16 + bob, 11, 15, st_m)
			_fill_rect(img, 36, 15 + bob, 8, 3, moss)
			_fill_circle(img, 40, 24 + bob, 3, rune)
			_fill_rect(img, 16, 16 + bob, 20, 22, st_d)
			_fill_rect(img, 18, 17 + bob, 16, 19, st_m)
			_fill_rect(img, 19, 17 + bob, 10, 4, st_h)
			_fill_circle(img, 26, 25 + bob, 4, rune)
			_fill_circle(img, 26, 25 + bob, 2, Color.WHITE)
			# Đôi chân đá nặng nề
			_fill_rect(img, 13, 38, 11, 12, st_d)
			_fill_rect(img, 28, 38, 11, 12, st_d)
			_fill_rect(img, 15, 39, 7, 5, st_m)
			_fill_rect(img, 30, 39, 7, 5, st_m)

		# =====================================================================
		# 5 BOSS HUYỀN THOẠI (MỖI MÀN 1 CON BOSS ĐẶC TRƯNG — 72x74 PIXEL!)
		# =====================================================================
		"boss_kitsune":
			# BOSS MÀN 1: HỒ LY YÊU VƯƠNG (Cửu Vĩ Hồ Hoàng Kim — 5 đuôi lớn xòe quạt + Vòng mặt trời!)
			var fur_w := Color(0.99, 0.97, 0.98) * tint
			var red_c := Color(0.92, 0.16, 0.22)
			var aura_g := Color(1.0, 0.82, 0.28)
			# 5 chiếc đuôi khổng lồ xòe quạt đằng sau!
			for ti in range(5):
				var tx: int = 12 + ti * 12
				var ty: int = 24 + absi(ti - 2) * 5 + wing_dy
				_fill_circle(img, tx, ty, 9, fur_w)
				_fill_circle(img, tx, ty - 5, 5, red_c)
			# Vòng mặt trời hoàng kim sau lưng
			_fill_circle(img, 36, 22 + bob, 14, Color(1.0, 0.84, 0.28, 0.45))
			_fill_rect(img, 24, 7 + bob, 24, 3, aura_g)
			# Đầu yêu hồ vương & đôi tai lớn uy nghi
			_fill_circle(img, 36, 23 + bob, 10, fur_w)
			_fill_rect(img, 26, 10 + bob, 6, 10, fur_w)
			_fill_rect(img, 28, 12 + bob, 3, 7, red_c)
			_fill_rect(img, 40, 10 + bob, 6, 10, fur_w)
			_fill_rect(img, 41, 12 + bob, 3, 7, red_c)
			_fill_rect(img, 31, 22 + bob, 4, 3, Color(1.0, 0.25, 0.20))
			_fill_rect(img, 38, 22 + bob, 4, 3, Color(1.0, 0.25, 0.20))
			# Chiến bào đỏ trắng hoàng kim
			_fill_rect(img, 22, 33 + bob, 28, 28, fur_w)
			_fill_rect(img, 20, 34 + bob, 10, 22, red_c)
			_fill_rect(img, 42, 34 + bob, 10, 22, red_c)
			_fill_rect(img, 24, 43 + bob, 24, 4, aura_g)
			_fill_rect(img, 25, 60, 8, 10, red_c)
			_fill_rect(img, 39, 60, 8, 10, red_c)

		"boss_dragon":
			# BOSS MÀN 2: LONG VƯƠNG THẦN (Bạch Long Thần Thủy uốn lượn trong sóng biển xanh biếc — Ảnh mẫu #2!)
			var dr_w := Color(0.95, 0.98, 1.0) * tint
			var dr_b := Color(0.24, 0.62, 0.98) * tint
			var dr_d := Color(0.10, 0.30, 0.68) * tint
			var wave := Color(0.45, 0.88, 1.0)
			# Vòng sóng nước biển xanh lam xoáy tròn quanh thân rồng!
			_fill_circle(img, 18, 52 + bob, 13, dr_b)
			_fill_circle(img, 54, 52 - bob, 13, dr_b)
			_fill_circle(img, 36, 58 + bob, 16, wave)
			_fill_circle(img, 36, 61 + bob, 12, dr_d)
			# Thân Bạch Long uốn lượn hình chữ S hùng vĩ!
			_fill_circle(img, 17, 36 + wing_dy, 10, dr_w)
			_fill_circle(img, 17, 36 + wing_dy, 6, dr_b)
			_fill_circle(img, 26, 46 + bob, 10, dr_w)
			_fill_circle(img, 44, 44 - bob, 10, dr_w)
			_fill_circle(img, 52, 30 - wing_dy, 9, dr_w)
			_fill_circle(img, 42, 20 + bob, 10, dr_w)
			# Bờm rồng xanh trắng tung bay + Sừng rồng hoàng kim!
			_fill_rect(img, 28, 5 + bob, 4, 12, gold)
			_fill_rect(img, 42, 5 + bob, 4, 12, gold)
			_fill_rect(img, 24, 8 + bob, 5, 4, gold)
			_fill_rect(img, 45, 8 + bob, 5, 4, gold)
			_fill_circle(img, 36, 20 + bob, 11, dr_w)
			_fill_rect(img, 22, 16 + bob, 10, 8, dr_b) # Bờm trái
			_fill_rect(img, 44, 16 + bob, 10, 8, dr_b) # Bờm phải
			# Mõm rồng & đôi mắt Thiên Long rực sáng + râu rồng!
			_fill_rect(img, 28, 22 + bob, 16, 8, dr_w)
			_fill_rect(img, 30, 19 + bob, 4, 3, Color(0.28, 0.96, 1.0) if not attacking else Color(1.0, 0.95, 0.35))
			_fill_rect(img, 39, 19 + bob, 4, 3, Color(0.28, 0.96, 1.0) if not attacking else Color(1.0, 0.95, 0.35))
			_fill_rect(img, 18, 27 + bob + sway, 10, 2, wave)
			_fill_rect(img, 44, 27 + bob - sway, 10, 2, wave)

		"boss_darklord":
			# BOSS MÀN 3: MA VƯƠNG HẮC ÁM (Tóc bạc dài, đôi cánh dơi hắc ám tím đen khổng lồ, lửa tím — Ảnh mẫu #1!)
			var arm_d := Color(0.11, 0.08, 0.18) * tint
			var arm_p := Color(0.32, 0.14, 0.48) * tint
			var flame_p := Color(0.76, 0.28, 1.0) if not attacking else Color(1.0, 0.42, 0.92)
			var hair_w := Color(0.92, 0.90, 0.98)
			# Đôi cánh dơi hắc ám khổng lồ vỗ mạnh (wing_dy)!
			_fill_rect(img, 2, 16 + wing_dy, 24, 7, arm_d)
			_fill_rect(img, 4, 22 + wing_dy, 22, 18, arm_p)
			_fill_rect(img, 2, 20 + wing_dy, 5, 22, arm_d)
			_fill_rect(img, 46, 16 + wing_dy, 24, 7, arm_d)
			_fill_rect(img, 46, 22 + wing_dy, 22, 18, arm_p)
			_fill_rect(img, 65, 20 + wing_dy, 5, 22, arm_d)
			# Ngọn lửa tím hắc ám cuộn dưới chân
			_fill_circle(img, 16, 56 + bob, 7, flame_p)
			_fill_circle(img, 56, 56 - bob, 7, flame_p)
			# Sừng ác ma + Tóc bạc dài + Mặt lạnh lùng mắt tím đỏ
			_fill_rect(img, 27, 5 + bob, 4, 9, arm_d)
			_fill_rect(img, 41, 5 + bob, 4, 9, arm_d)
			_fill_circle(img, 36, 19 + bob, 10, hair_w)
			_fill_rect(img, 30, 17 + bob, 12, 9, skin_c)
			_fill_rect(img, 32, 20 + bob, 3, 2, flame_p)
			_fill_rect(img, 38, 20 + bob, 3, 2, flame_p)
			# Chiến giáp hắc ám viền vàng đỏ + Lưỡi hái xích hắc viêm!
			_fill_rect(img, 23, 27 + bob, 26, 28, arm_d)
			_fill_rect(img, 26, 28 + bob, 20, 22, arm_p)
			_fill_rect(img, 22, 27 + bob, 28, 4, gold)
			_fill_circle(img, 36, 36 + bob, 4, flame_p)
			_fill_rect(img, 25, 55, 9, 14, arm_d)
			_fill_rect(img, 38, 55, 9, 14, arm_d)
			# Lưỡi hái / Ma kiếm tím rực bên tay phải
			_fill_rect(img, 54, 14 + bob + (6 if attacking else 0), 6, 42, flame_p)
			_fill_rect(img, 56, 16 + bob + (6 if attacking else 0), 2, 38, Color.WHITE)

		"boss_archmage":
			# BOSS MÀN 4: PHÁP SƯ VĨNH HẰNG (Áo trắng hoàng kim, Vòng Thánh Cổ Ngữ khổng lồ & 4 Thần Kiếm bay — Ảnh mẫu #3!)
			var robe_w := Color(0.99, 0.98, 0.96) * tint
			var gold_hi := Color(1.0, 0.92, 0.44)
			var fl: int = -2 if (step == 1) else (-1 if (step == 2) else 0)
			# VÒNG PHÁP TRẬN HOÀNG KIM KHỔNG LỒ ĐẰNG SAU LƯNG!
			_fill_circle(img, 36, 30 + fl, 24, Color(1.0, 0.84, 0.26, 0.25))
			_fill_rect(img, 14, 29 + fl, 44, 2, gold)
			_fill_rect(img, 35, 8 + fl, 2, 44, gold)
			# 4 Quả cầu tinh tú & 4 Thần Kiếm Hoàng Kim lơ lửng 2 bên!
			_fill_circle(img, 12, 18 + fl + sway, 4, gold_hi)
			_fill_circle(img, 60, 18 + fl - sway, 4, gold_hi)
			_fill_rect(img, 9, 30 + fl + sway, 4, 24, gold_hi if attacking else gold)
			_fill_rect(img, 7, 36 + fl + sway, 8, 2, Color.WHITE)
			_fill_rect(img, 59, 30 + fl - sway, 4, 24, gold_hi if attacking else gold)
			_fill_rect(img, 57, 36 + fl - sway, 8, 2, Color.WHITE)
			# Tóc trắng dài + Vương miện vàng + Mặt thánh nữ
			_fill_rect(img, 24, 18 + fl, 24, 34, Color(0.90, 0.92, 0.98))
			_fill_circle(img, 36, 21 + fl, 10, Color(0.96, 0.97, 1.0))
			_fill_rect(img, 29, 9 + fl, 14, 4, gold)
			_fill_rect(img, 34, 6 + fl, 4, 5, gold_hi)
			_fill_rect(img, 30, 19 + fl, 12, 9, skin_c)
			_fill_rect(img, 32, 22 + fl, 3, 2, Color(0.32, 0.78, 1.0))
			_fill_rect(img, 38, 22 + fl, 3, 2, Color(0.32, 0.78, 1.0))
			# Pháp bào trắng-vàng thánh khiết lơ lửng
			_fill_rect(img, 24, 29 + fl, 24, 30, robe_w)
			_fill_rect(img, 26, 30 + fl, 20, 4, gold)
			_fill_rect(img, 33, 30 + fl, 6, 28, gold_hi)
			_fill_rect(img, 22, 54 + fl, 28, 5, gold)

		_: # "boss_emperor" — BOSS MÀN 5: THIÊN MA CUỒNG ĐẾ (Cánh rồng lửa đỏ khổng lồ, tóc trắng, Đại Ma Kiếm Lửa — Ảnh mẫu #4!)
			var arm_d := Color(0.12, 0.06, 0.09) * tint
			var crim_d := Color(0.56, 0.06, 0.12) * tint
			var crim_m := Color(0.96, 0.18, 0.22)
			var fire_h := Color(1.0, 0.78, 0.26)
			var hair_w := Color(0.95, 0.94, 0.98)
			# ĐÔI CÁNH THIÊN MA ĐỎ RỰC KHỔNG LỒ VỖ MẠNH!
			_fill_rect(img, 1, 13 + wing_dy, 26, 7, arm_d)
			_fill_rect(img, 3, 20 + wing_dy, 24, 20, crim_d)
			_fill_rect(img, 6, 24 + wing_dy, 16, 12, crim_m)
			_fill_rect(img, 45, 13 + wing_dy, 26, 7, arm_d)
			_fill_rect(img, 45, 20 + wing_dy, 24, 20, crim_d)
			_fill_rect(img, 50, 24 + wing_dy, 16, 12, crim_m)
			# Vương miện hỏa ma + Tóc bạc tung bay + Mắt đỏ huyết nguyệt
			_fill_rect(img, 27, 4 + bob, 4, 10, crim_m)
			_fill_rect(img, 41, 4 + bob, 4, 10, crim_m)
			_fill_rect(img, 33, 2 + bob, 6, 9, fire_h)
			_fill_circle(img, 36, 18 + bob, 10, hair_w)
			_fill_rect(img, 30, 16 + bob, 12, 9, skin_c)
			_fill_rect(img, 32, 19 + bob, 3, 2, crim_m)
			_fill_rect(img, 38, 19 + bob, 3, 2, crim_m)
			# Hoàng giáp Ma Đế đen-đỏ-vàng + lõi hỏa ngục
			_fill_rect(img, 21, 26 + bob, 30, 30, arm_d)
			_fill_rect(img, 24, 28 + bob, 24, 24, crim_d)
			_fill_rect(img, 20, 26 + bob, 32, 4, gold)
			_fill_circle(img, 36, 36 + bob, 5, crim_m)
			_fill_circle(img, 36, 36 + bob, 2, fire_h)
			_fill_rect(img, 24, 55, 9, 14, arm_d)
			_fill_rect(img, 39, 55, 9, 14, arm_d)
			# ĐẠI MA KIẾM HỎA NGỤC KHỔNG LỒ CHÁY RỰC LỬA ĐỎ!
			var sy: int = 8 + bob + (8 if attacking else 0)
			_fill_rect(img, 53, sy, 10, 44, crim_m)
			_fill_rect(img, 55, sy + 2, 6, 40, fire_h)
			_fill_rect(img, 57, sy + 4, 2, 34, Color.WHITE)
			_fill_rect(img, 50, sy + 42, 16, 4, gold)

	_apply_clean_outline(img, outline)
	return ImageTexture.create_from_image(img)


## Cây cổ thụ tán rộng nhiều tầng mềm mại (hỗ trợ lá xanh, lá thu vàng cam & Hoa Anh Đào hồng pastel!)
static func _make_tree_image(style: String) -> Image:
	var w: int = 80
	var h: int = 96
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var trunk_d := Color(0.20, 0.12, 0.10)
	var trunk_m := Color(0.32, 0.20, 0.16)
	var trunk_h := Color(0.45, 0.30, 0.22)

	var l1 := Color(0.09, 0.22, 0.16)
	var l2 := Color(0.16, 0.36, 0.24)
	var l3 := Color(0.28, 0.52, 0.32)
	var l4 := Color(0.46, 0.70, 0.42)
	if style == "autumn":
		l1 = Color(0.42, 0.15, 0.10)
		l2 = Color(0.68, 0.28, 0.12)
		l3 = Color(0.90, 0.50, 0.18)
		l4 = Color(1.0, 0.78, 0.34)
	elif style == "sakura":
		l1 = Color(0.62, 0.28, 0.44)
		l2 = Color(0.86, 0.48, 0.64)
		l3 = Color(0.98, 0.70, 0.80)
		l4 = Color(1.0, 0.90, 0.94)

	# Thân cây cổ thụ uốn lượn mềm mại & rễ bạnh tự nhiên
	_fill_rect(img, 33, 52, 14, 39, trunk_d)
	_fill_rect(img, 35, 54, 8, 35, trunk_m)
	_fill_rect(img, 36, 56, 4, 28, trunk_h)
	_fill_rect(img, 24, 84, 32, 8, trunk_d)
	_fill_rect(img, 28, 82, 24, 6, trunk_m)
	_fill_rect(img, 22, 42, 11, 14, trunk_d)
	_fill_rect(img, 47, 42, 11, 14, trunk_d)

	# Tán lá nhiều tầng bồng bềnh mềm mại (painterly cloud clusters)
	_fill_circle(img, 40, 35, 29, l1)
	_fill_circle(img, 22, 42, 19, l1)
	_fill_circle(img, 58, 42, 19, l1)
	_fill_circle(img, 40, 30, 24, l2)
	_fill_circle(img, 24, 38, 16, l2)
	_fill_circle(img, 56, 38, 16, l2)
	_fill_circle(img, 35, 24, 17, l3)
	_fill_circle(img, 50, 29, 14, l3)
	_fill_circle(img, 25, 32, 12, l3)
	_fill_circle(img, 34, 18, 11, l4)
	_fill_circle(img, 48, 22, 9, l4)
	_fill_circle(img, 24, 27, 7, l4)
	# Điểm sáng cánh hoa rơi rải quanh tán cây Anh Đào
	if style == "sakura":
		for pp: Vector2i in [Vector2i(12, 56), Vector2i(66, 52), Vector2i(18, 66), Vector2i(62, 68), Vector2i(46, 58)]:
			_fill_circle(img, pp.x, pp.y, 2, l4)
	return img


## Cây thông rừng núi hậu cảnh HD-2D
static func _make_pine_image() -> Image:
	var w := 48
	var h := 76
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_rect(img, 21, 56, 6, 18, Color(0.20, 0.13, 0.09))
	var c1 := Color(0.07, 0.16, 0.15)
	var c2 := Color(0.12, 0.25, 0.22)
	var c3 := Color(0.19, 0.36, 0.30)
	for tier in range(4):
		var top_y := 6 + tier * 13
		var half_w := 7 + tier * 5
		for dy in range(18):
			var span := int(float(dy) / 18.0 * float(half_w)) + 2
			_fill_rect(img, 24 - span, top_y + dy, span * 2, 1, c1)
			if dy < 13:
				_fill_rect(img, 24 - int(span * 0.8), top_y + dy, int(span * 1.4), 1, c2)
			if dy < 7:
				_fill_rect(img, 24 - int(span * 0.5), top_y + dy, span, 1, c3)
	return img


## Bụi cây dày ven tường đá & hoa dại li ti
static func _make_bush_image() -> Image:
	var w := 36
	var h := 24
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_circle(img, 18, 15, 11, Color(0.09, 0.21, 0.13))
	_fill_circle(img, 10, 17, 8, Color(0.10, 0.23, 0.14))
	_fill_circle(img, 26, 17, 8, Color(0.10, 0.23, 0.14))
	_fill_circle(img, 18, 13, 8, Color(0.18, 0.36, 0.20))
	_fill_circle(img, 12, 15, 6, Color(0.18, 0.36, 0.20))
	_fill_circle(img, 24, 15, 6, Color(0.18, 0.36, 0.20))
	_fill_circle(img, 17, 10, 5, Color(0.30, 0.50, 0.26))
	# Điểm xuyết hoa nhỏ vàng & cam ấm
	_fill_rect(img, 11, 12, 2, 2, Color(0.98, 0.80, 0.32))
	_fill_rect(img, 22, 13, 2, 2, Color(0.96, 0.55, 0.38))
	_fill_rect(img, 17, 15, 2, 2, Color(0.92, 0.90, 0.72))
	return img


## Bụi cỏ cao tiền cảnh (Foreground grass) tạo chiều sâu Tilt-Shift giống ảnh Windferry
static func _make_grass_tuft_image() -> Image:
	var w := 24
	var h := 20
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var g1 := Color(0.10, 0.24, 0.14)
	var g2 := Color(0.18, 0.38, 0.20)
	var g3 := Color(0.30, 0.54, 0.28)
	for bx: int in [4, 8, 12, 16, 19]:
		var bh: int = 10 + (bx * 3) % 7
		for dy in range(bh):
			var sway: int = int(float(dy) * (0.22 if bx > 11 else -0.22))
			var col := g1 if dy < 4 else (g2 if dy < bh - 3 else g3)
			_fill_rect(img, bx + sway, 19 - dy, 2, 1, col)
	return img


## Khóm hoa sáng ven bờ suối
static func _make_flower_cluster_image() -> Image:
	var img := _make_grass_tuft_image()
	_fill_rect(img, 6, 7, 3, 3, Color(0.98, 0.84, 0.36))
	_fill_rect(img, 13, 5, 3, 3, Color(0.55, 0.82, 1.0))
	_fill_rect(img, 18, 9, 3, 3, Color(0.98, 0.58, 0.68))
	return img


## Vẽ Sprite Pixel Art Linh Thú Đồng Hành (24x24):
## - "fox": Tiểu Hồ Ly Bạch Tuyết 3 đuôi có chuông đỏ cổ trang & ấn đỏ trên trán (cực dễ thương!)
## - "crane": Tiên Hạc Trắng vỗ cánh thanh thoát, chóp cánh đen, đỉnh đầu đỏ son & hào quang ngọc bích.
static func _make_pet_frame(pet_type: String, step: int) -> ImageTexture:
	var w := 26
	var h := 26
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline := Color(0.14, 0.09, 0.16)
	var bob: int = 1 if step == 1 else (2 if step == 2 else 0)

	if pet_type == "crane":
		# Tiên Hạc Cổ Trang vỗ cánh
		var white := Color(0.98, 0.98, 1.0)
		var shade := Color(0.78, 0.86, 0.94)
		var wing_tip := Color(0.16, 0.18, 0.24)
		var crown := Color(0.92, 0.18, 0.22)
		var beak := Color(0.98, 0.78, 0.24)
		var wing_y: int = 6 if step == 0 else (11 if step == 1 else 15)

		# Đôi cánh vỗ theo nhịp 3 frame
		_fill_rect(img, 3, wing_y, 9, 5, white)
		_fill_rect(img, 2, wing_y + 2, 4, 3, wing_tip)
		_fill_rect(img, 14, wing_y, 9, 5, white)
		_fill_rect(img, 20, wing_y + 2, 4, 3, wing_tip)
		# Thân hạc mảnh mai & đuôi đen
		_fill_circle(img, 13, 14 + (bob / 2), 4, white)
		_fill_rect(img, 8, 15, 5, 3, shade)
		_fill_rect(img, 5, 16, 4, 3, wing_tip)
		# Cổ vươn cao, đầu trắng + chỏm đỏ son + mỏ vàng
		_fill_rect(img, 15, 7, 3, 7, white)
		_fill_circle(img, 17, 6, 3, white)
		_fill_rect(img, 16, 3, 3, 2, crown)
		_fill_rect(img, 20, 6, 4, 2, beak)
		img.set_pixel(18, 6, outline)
	else:
		# Tiểu Hồ Ly Bạch Tuyết (Chibi Hồ Ly bay lơ lửng với đuôi bông lớn & chuông đỏ)
		var fur_w := Color(0.99, 0.97, 0.95)
		var fur_s := Color(0.86, 0.80, 0.84)
		var ear_in := Color(1.0, 0.62, 0.68)
		var red_acc := Color(0.92, 0.18, 0.22)
		var gold := Color(0.98, 0.82, 0.26)

		# Chiếc đuôi bông khổng lồ vẫy phía sau (chóp đuôi phớt đỏ hồng)
		var tail_dy: int = -1 if step == 0 else (1 if step == 2 else 0)
		_fill_circle(img, 7, 15 + tail_dy, 5, fur_w)
		_fill_circle(img, 5, 13 + tail_dy, 3, red_acc)
		_fill_circle(img, 7, 16 + tail_dy, 3, fur_s)

		# Thân nhỏ nhắn & 4 chân thu gọn lơ lửng
		_fill_circle(img, 13, 16 + (bob / 2), 4, fur_w)
		_fill_rect(img, 11, 18 + (bob / 2), 6, 2, fur_s)
		# Dải ruy băng đỏ & chuông vàng cổ
		_fill_rect(img, 12, 13 + (bob / 2), 6, 2, red_acc)
		_fill_rect(img, 15, 14 + (bob / 2), 2, 2, gold)

		# Đầu tròn cáo chibi + 2 tai nhọn lớn
		_fill_circle(img, 16, 10 + (bob / 2), 5, fur_w)
		# Tai nhọn
		_fill_rect(img, 12, 3 + (bob / 2), 3, 4, fur_w)
		_fill_rect(img, 13, 4 + (bob / 2), 2, 3, ear_in)
		_fill_rect(img, 18, 3 + (bob / 2), 3, 4, fur_w)
		_fill_rect(img, 18, 4 + (bob / 2), 2, 3, ear_in)
		# Ấn đỏ cổ trang trên trán & cặp mắt long lanh
		img.set_pixel(16, 7 + (bob / 2), red_acc)
		_fill_rect(img, 15, 10 + (bob / 2), 2, 2, outline)
		_fill_rect(img, 19, 10 + (bob / 2), 2, 2, outline)
		img.set_pixel(15, 10 + (bob / 2), Color.WHITE)
		img.set_pixel(19, 10 + (bob / 2), Color.WHITE)

	_apply_clean_outline(img, outline)
	return ImageTexture.create_from_image(img)


## Bươm bướm sáng bay quanh nhân vật & đèn đường giống trong ảnh Windferry
static func _make_butterfly_image() -> Image:
	var img := Image.create(12, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var wing := Color(0.82, 0.92, 1.0)
	var tip := Color(0.48, 0.72, 1.0)
	_fill_rect(img, 1, 2, 4, 4, wing)
	_fill_rect(img, 7, 2, 4, 4, wing)
	_fill_rect(img, 2, 6, 3, 3, tip)
	_fill_rect(img, 7, 6, 3, 3, tip)
	_fill_rect(img, 5, 3, 2, 5, Color(0.16, 0.14, 0.22))
	return img


## Chân dung 10 Skin Anime Chibi 48x48 (hiển thị cực nét trên HUD, Vòng Quay Gacha & Tủ Đồ 5x2!)
static func _make_hero_portrait_image(scarf_id: String = "blue", skin_id: String = "skin_default") -> Image:
	var w: int = 48
	var h: int = 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var sk: Dictionary = SaveManager.SKIN_CATALOG.get(skin_id, SaveManager.SKIN_CATALOG["skin_default"])
	var has_vfx: bool = bool(sk.get("has_vfx", false))
	var vcol: Color = sk.get("vfx_color", Color(0.95, 0.35, 0.25))
	var border_col: Color = sk["tag_color"] if has_vfx else Color(0.88, 0.70, 0.32)
	var bg_col: Color = Color(0.11, 0.08, 0.14).lerp(vcol.darkened(0.68), 0.45)
	img.fill(bg_col)

	# Hào quang nền phía sau nhân vật theo chủ đề skin
	if has_vfx or skin_id == "skin_default":
		_fill_circle(img, 24, 24, 18, Color(vcol.r, vcol.g, vcol.b, 0.24))
		_fill_circle(img, 24, 24, 13, Color(vcol.r, vcol.g, vcol.b, 0.22))

	# Khung viền cổ trang vàng đồng (hoặc ánh sắc hiếm của skin)
	_fill_rect(img, 0, 0, w, 2, border_col)
	_fill_rect(img, 0, h - 2, w, 2, border_col)
	_fill_rect(img, 0, 0, 2, h, border_col)
	_fill_rect(img, w - 2, 0, 2, h, border_col)
	_fill_rect(img, 3, 3, w - 6, 1, sk["coat_m"])
	_fill_rect(img, 3, h - 4, w - 6, 1, sk["coat_m"])

	var hair_d: Color = sk["hair_d"]
	var hair_m: Color = sk["hair_m"]
	var hair_h: Color = sk["hair_h"]
	var gold := Color(0.99, 0.82, 0.28)
	var sp: Dictionary = SaveManager.SCARF_PALETTES.get(scarf_id, SaveManager.SCARF_PALETTES["blue"])
	var col_mid: Color = Color(0.90, 0.16, 0.20) if (skin_id == "skin_default" and scarf_id == "blue") else (sp["mid"] as Color)
	var col_hi: Color = Color(1.0, 0.44, 0.36) if (skin_id == "skin_default" and scarf_id == "blue") else (sp["hi"] as Color)

	# Phụ kiện phía sau vai/đầu (Cánh Thiên Sứ, Cánh Ác Ma, 2 Bím Tóc Vocaloid, Bướm Ma Nữ, Rồng Hoàng Đế)
	match skin_id:
		"skin_vocaloid":
			_fill_rect(img, 4, 16, 8, 26, hair_d)
			_fill_rect(img, 5, 17, 6, 24, hair_m)
			_fill_rect(img, 6, 19, 3, 14, hair_h)
			_fill_rect(img, 36, 16, 8, 26, hair_d)
			_fill_rect(img, 37, 17, 6, 24, hair_m)
			_fill_rect(img, 38, 19, 3, 14, hair_h)
		"skin_angel":
			_fill_rect(img, 3, 24, 11, 14, Color(0.98, 0.98, 1.0))
			_fill_rect(img, 34, 24, 11, 14, Color(0.98, 0.98, 1.0))
		"skin_demon":
			_fill_rect(img, 3, 22, 11, 14, Color(0.28, 0.05, 0.10))
			_fill_rect(img, 34, 22, 11, 14, Color(0.28, 0.05, 0.10))
			_fill_rect(img, 5, 25, 7, 8, Color(0.75, 0.10, 0.20))
			_fill_rect(img, 36, 25, 7, 8, Color(0.75, 0.10, 0.20))
		"skin_emperor":
			_fill_circle(img, 9, 14, 5, Color(0.96, 0.72, 0.14))
			_fill_circle(img, 39, 16, 5, Color(0.96, 0.72, 0.14))
			_fill_circle(img, 39, 15, 3, Color(1.0, 0.94, 0.48))
			img.set_pixel(40, 14, Color(1.0, 0.20, 0.16))
		"skin_witch":
			_fill_rect(img, 6, 10, 4, 3, Color(0.86, 0.44, 1.0))
			_fill_rect(img, 38, 13, 4, 3, Color(0.86, 0.44, 1.0))
			_fill_rect(img, 7, 30, 4, 3, Color(0.76, 0.34, 1.0))

	# Thân áo & cổ áo chuẩn từng Skin
	_fill_rect(img, 8, 35, 32, 11, sk["coat_m"])
	_fill_rect(img, 16, 35, 16, 11, sk["robe"])
	if skin_id == "skin_default":
		_fill_rect(img, 11, 32, 26, 5, col_mid)
		_fill_rect(img, 15, 32, 18, 2, col_hi)
		_fill_rect(img, 8, 35, 8, 2, gold)
		_fill_rect(img, 32, 35, 8, 2, gold)
	elif skin_id == "skin_emperor":
		_fill_rect(img, 8, 35, 32, 11, sk["robe"])
		_fill_rect(img, 18, 35, 12, 11, gold)
		_fill_rect(img, 10, 34, 8, 3, gold)
		_fill_rect(img, 30, 34, 8, 3, gold)
	elif skin_id == "skin_vocaloid":
		_fill_rect(img, 12, 35, 24, 11, sk["robe"])
		_fill_rect(img, 22, 35, 4, 10, sk["coat_m"])
	else:
		_fill_rect(img, 13, 33, 22, 4, sk["coat_d"])
		_fill_rect(img, 17, 33, 14, 2, sk["coat_m"])

	# Đầu & Tóc nền
	_fill_circle(img, 24, 23, 12, hair_d)
	_fill_circle(img, 24, 22, 10, hair_m)

	# Phụ kiện đỉnh đầu đặc trưng từng Skin!
	match skin_id:
		"skin_default":
			_fill_rect(img, 12, 12, 5, 5, hair_d)
			_fill_rect(img, 17, 8, 5, 5, hair_m)
			_fill_rect(img, 23, 7, 5, 6, hair_m)
			_fill_rect(img, 29, 9, 5, 5, hair_d)
			_fill_rect(img, 33, 13, 4, 5, hair_d)
		"skin_immortal":
			_fill_circle(img, 24, 9, 5, hair_d)
			_fill_rect(img, 15, 8, 18, 2, Color(0.75, 0.92, 1.0))
		"skin_ninja":
			_fill_rect(img, 13, 10, 5, 5, hair_m)
			_fill_rect(img, 18, 6, 5, 6, hair_h)
			_fill_rect(img, 24, 5, 5, 7, hair_h)
			_fill_rect(img, 30, 8, 5, 6, hair_m)
			# Băng trán thép
			_fill_rect(img, 13, 14, 22, 4, Color(0.14, 0.16, 0.24))
			_fill_rect(img, 18, 14, 12, 4, Color(0.84, 0.90, 0.98))
			_fill_rect(img, 20, 15, 8, 1, Color(0.32, 0.38, 0.48))
		"skin_fox":
			# Tai cáo trắng to dựng đứng!
			var ear_in := Color(0.90, 0.72, 0.84)
			_fill_rect(img, 11, 5, 7, 10, hair_h)
			_fill_rect(img, 13, 7, 4, 7, ear_in)
			_fill_rect(img, 30, 5, 7, 10, hair_h)
			_fill_rect(img, 31, 7, 4, 7, ear_in)
		"skin_angel":
			# Vòng hào quang vàng tỏa sáng phía trên!
			_fill_rect(img, 14, 5, 20, 3, Color(1.0, 0.90, 0.36))
			_fill_rect(img, 17, 4, 14, 1, Color(1.0, 0.99, 0.80))
		"skin_demon":
			_fill_rect(img, 12, 8, 4, 6, Color(0.78, 0.10, 0.18))
			_fill_rect(img, 32, 8, 4, 6, Color(0.78, 0.10, 0.18))
			_fill_rect(img, 19, 8, 10, 5, hair_h)
		"skin_miko":
			# Mặt nạ cáo Kitsune đeo nghiêng trên góc phải đầu!
			_fill_circle(img, 33, 12, 6, Color(0.99, 0.98, 0.96))
			_fill_rect(img, 29, 5, 3, 4, Color(0.99, 0.98, 0.96))
			_fill_rect(img, 35, 6, 3, 4, Color(0.99, 0.98, 0.96))
			_fill_rect(img, 30, 11, 3, 2, Color(0.92, 0.14, 0.18))
			_fill_rect(img, 34, 12, 3, 2, Color(0.92, 0.14, 0.18))
		"skin_emperor":
			# Vương miện Hoàng Đế rực vàng!
			_fill_rect(img, 15, 7, 18, 5, Color(0.72, 0.50, 0.12))
			_fill_rect(img, 16, 6, 16, 4, gold)
			_fill_rect(img, 22, 4, 4, 5, Color(1.0, 0.96, 0.62))
			_fill_rect(img, 23, 7, 2, 2, Color(0.98, 0.16, 0.20))

	if skin_id != "skin_ninja":
		_fill_rect(img, 16, 13, 16, 2, hair_h)
		_fill_rect(img, 20, 13, 8, 1, hair_h.lightened(0.32))

	# Khuôn mặt anime thanh tú, cặp mắt sắc nét theo màu Skin
	_fill_rect(img, 16, 18, 16, 14, Color(0.99, 0.89, 0.81))
	_fill_rect(img, 13, 17, 4, 17, hair_d)
	_fill_rect(img, 31, 17, 4, 17, hair_d)
	_fill_rect(img, 16, 17, 16, 3, hair_m)
	_fill_rect(img, 18, 22, 4, 4, Color(0.10, 0.08, 0.14))
	_fill_rect(img, 26, 22, 4, 4, Color(0.10, 0.08, 0.14))
	_fill_rect(img, 19, 23, 3, 3, sk["eye"])
	_fill_rect(img, 27, 23, 3, 3, sk["eye"])
	img.set_pixel(19, 22, Color.WHITE)
	img.set_pixel(27, 22, Color.WHITE)
	_fill_rect(img, 17, 27, 3, 2, Color(0.96, 0.58, 0.62))
	_fill_rect(img, 28, 27, 3, 2, Color(0.96, 0.58, 0.62))
	return img


## Vẽ Sprite NPC HD-2D đứng trong làng (Thợ Rèn, Chủ Quán Trọ, Thương Nhân)
static func _make_npc_image(role: String) -> Image:
	var w := 36
	var h := 42
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline := Color(0.10, 0.07, 0.13)
	var skin := Color(0.95, 0.80, 0.68)

	match role:
		"blacksmith":
			# Thợ Rèn Gorn: Râu quai nón nâu rậm, tạp dề da đen, búa rèn lớn
			_fill_circle(img, 18, 12, 6, Color(0.36, 0.22, 0.14))
			_fill_rect(img, 13, 11, 10, 7, skin)
			_fill_rect(img, 12, 15, 12, 6, Color(0.32, 0.18, 0.12)) # Râu quai nón
			_fill_rect(img, 15, 13, 2, 2, outline)
			_fill_rect(img, 20, 13, 2, 2, outline)
			_fill_rect(img, 10, 20, 16, 13, Color(0.68, 0.24, 0.18)) # Áo đỏ thợ rèn
			_fill_rect(img, 12, 22, 12, 11, Color(0.24, 0.17, 0.13)) # Tạp dề da
			_fill_rect(img, 12, 33, 5, 6, Color(0.18, 0.18, 0.24))
			_fill_rect(img, 19, 33, 5, 6, Color(0.18, 0.18, 0.24))
			# Búa rèn cầm tay
			_fill_rect(img, 26, 17, 3, 14, Color(0.45, 0.28, 0.16))
			_fill_rect(img, 23, 13, 9, 5, Color(0.55, 0.60, 0.68))
		"innkeeper":
			# Chủ Quán Trọ Mira: Tóc vàng búi cao, khăn đội trắng, váy xanh lục ấm áp
			_fill_circle(img, 18, 11, 7, Color(0.88, 0.66, 0.24))
			_fill_rect(img, 13, 6, 10, 3, Color(0.96, 0.94, 0.90)) # Mũ vải trắng
			_fill_rect(img, 13, 11, 10, 7, skin)
			_fill_rect(img, 15, 13, 2, 2, outline)
			_fill_rect(img, 19, 13, 2, 2, outline)
			img.set_pixel(14, 16, Color(0.95, 0.62, 0.58))
			img.set_pixel(21, 16, Color(0.95, 0.62, 0.58))
			_fill_rect(img, 11, 19, 14, 15, Color(0.22, 0.52, 0.34)) # Váy xanh lục
			_fill_rect(img, 13, 21, 10, 12, Color(0.95, 0.92, 0.85)) # Tạp dề trắng
			_fill_rect(img, 13, 34, 4, 5, Color(0.35, 0.20, 0.12))
			_fill_rect(img, 19, 34, 4, 5, Color(0.35, 0.20, 0.12))
		"tailor":
			# Cẩm Y Tiên Cô (Chủ Tụ Bảo Các Gacha Trang Phục): Tóc cài hoa đào, áo lụa hồng vàng quý phái
			_fill_circle(img, 18, 11, 7, Color(0.20, 0.12, 0.24))
			_fill_rect(img, 11, 6, 4, 4, Color(1.0, 0.56, 0.74))
			_fill_rect(img, 22, 6, 4, 4, Color(0.98, 0.82, 0.28))
			_fill_rect(img, 13, 11, 10, 7, skin)
			_fill_rect(img, 15, 13, 2, 2, outline)
			_fill_rect(img, 19, 13, 2, 2, outline)
			img.set_pixel(14, 16, Color(0.96, 0.58, 0.64))
			img.set_pixel(21, 16, Color(0.96, 0.58, 0.64))
			_fill_rect(img, 10, 19, 16, 16, Color(0.86, 0.34, 0.56))
			_fill_rect(img, 14, 20, 8, 15, Color(1.0, 0.88, 0.60))
			_fill_rect(img, 12, 35, 12, 4, Color(0.54, 0.16, 0.34))
		_: # "merchant"
			# Thương Nhân Aurelius: Mũ lông tím, áo choàng quý tộc xanh lam viền vàng, túi vàng
			_fill_rect(img, 10, 8, 16, 3, Color(0.42, 0.20, 0.58))
			_fill_rect(img, 13, 4, 10, 5, Color(0.52, 0.26, 0.68))
			_fill_rect(img, 22, 3, 4, 5, Color(0.98, 0.82, 0.26)) # Lông vũ vàng
			_fill_rect(img, 13, 11, 10, 7, skin)
			_fill_rect(img, 15, 13, 2, 2, outline)
			_fill_rect(img, 19, 13, 2, 2, outline)
			_fill_rect(img, 15, 16, 6, 2, Color(0.26, 0.18, 0.14)) # Ria mép
			_fill_rect(img, 10, 19, 16, 14, Color(0.18, 0.34, 0.62))
			_fill_rect(img, 16, 19, 4, 14, Color(0.96, 0.78, 0.24))
			_fill_rect(img, 12, 33, 5, 6, Color(0.22, 0.16, 0.14))
			_fill_rect(img, 19, 33, 5, 6, Color(0.22, 0.16, 0.14))
			# Túi vàng lớn bên hông
			_fill_circle(img, 27, 27, 4, Color(0.96, 0.78, 0.22))

	_apply_clean_outline(img, outline)
	return img


## Chân dung cận cảnh 48x48 cho Hộp thoại Dialogue Portrait kiểu JRPG cổ điển
static func _make_npc_portrait_image(role: String) -> Image:
	var w := 48
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bg_col := Color(0.22, 0.12, 0.10) if role == "blacksmith" else (Color(0.12, 0.24, 0.18) if role == "innkeeper" else Color(0.14, 0.16, 0.30))
	img.fill(bg_col)
	# Viền khung chân dung màu vàng cổ điển
	_fill_rect(img, 0, 0, w, 2, Color(0.88, 0.72, 0.36))
	_fill_rect(img, 0, h - 2, w, 2, Color(0.88, 0.72, 0.36))
	_fill_rect(img, 0, 0, 2, h, Color(0.88, 0.72, 0.36))
	_fill_rect(img, w - 2, 0, 2, h, Color(0.88, 0.72, 0.36))

	var skin := Color(0.96, 0.81, 0.69)
	var outline := Color(0.10, 0.08, 0.14)

	match role:
		"blacksmith":
			_fill_rect(img, 8, 32, 32, 14, Color(0.68, 0.24, 0.18))
			_fill_rect(img, 13, 35, 22, 11, Color(0.24, 0.17, 0.13))
			_fill_circle(img, 24, 21, 13, Color(0.36, 0.22, 0.14))
			_fill_rect(img, 14, 14, 20, 15, skin)
			_fill_rect(img, 12, 24, 24, 10, Color(0.30, 0.16, 0.10))
			_fill_rect(img, 17, 19, 3, 3, outline)
			_fill_rect(img, 28, 19, 3, 3, outline)
			img.set_pixel(17, 19, Color.WHITE)
			img.set_pixel(28, 19, Color.WHITE)
		"innkeeper":
			_fill_rect(img, 9, 33, 30, 13, Color(0.22, 0.52, 0.34))
			_fill_rect(img, 16, 35, 16, 11, Color(0.95, 0.92, 0.85))
			_fill_circle(img, 24, 20, 13, Color(0.88, 0.66, 0.24))
			_fill_rect(img, 14, 7, 20, 5, Color(0.96, 0.94, 0.90))
			_fill_rect(img, 14, 15, 20, 15, skin)
			_fill_rect(img, 17, 20, 3, 4, outline)
			_fill_rect(img, 28, 20, 3, 4, outline)
			img.set_pixel(17, 20, Color.WHITE)
			img.set_pixel(28, 20, Color.WHITE)
			_fill_rect(img, 15, 25, 3, 2, Color(0.95, 0.60, 0.58))
			_fill_rect(img, 30, 25, 3, 2, Color(0.95, 0.60, 0.58))
		"tailor":
			_fill_rect(img, 8, 33, 32, 13, Color(0.86, 0.34, 0.56))
			_fill_rect(img, 18, 34, 12, 12, Color(1.0, 0.88, 0.60))
			_fill_circle(img, 24, 20, 13, Color(0.20, 0.12, 0.24))
			_fill_rect(img, 10, 10, 6, 5, Color(1.0, 0.56, 0.74))
			_fill_rect(img, 32, 10, 6, 5, Color(0.98, 0.82, 0.28))
			_fill_rect(img, 14, 15, 20, 15, skin)
			_fill_rect(img, 17, 20, 3, 4, outline)
			_fill_rect(img, 28, 20, 3, 4, outline)
			img.set_pixel(17, 20, Color.WHITE)
			img.set_pixel(28, 20, Color.WHITE)
			_fill_rect(img, 15, 25, 3, 2, Color(0.96, 0.58, 0.64))
			_fill_rect(img, 30, 25, 3, 2, Color(0.96, 0.58, 0.64))
		_:
			_fill_rect(img, 8, 32, 32, 14, Color(0.18, 0.34, 0.62))
			_fill_rect(img, 20, 32, 8, 14, Color(0.96, 0.78, 0.24))
			_fill_rect(img, 10, 12, 28, 5, Color(0.42, 0.20, 0.58))
			_fill_rect(img, 14, 5, 20, 8, Color(0.52, 0.26, 0.68))
			_fill_rect(img, 32, 4, 6, 8, Color(0.98, 0.82, 0.26))
			_fill_rect(img, 14, 17, 20, 14, skin)
			_fill_rect(img, 17, 21, 3, 3, outline)
			_fill_rect(img, 28, 21, 3, 3, outline)
			img.set_pixel(17, 21, Color.WHITE)
			img.set_pixel(28, 21, Color.WHITE)
			_fill_rect(img, 18, 26, 12, 3, Color(0.26, 0.18, 0.14))
	return img


## Vẽ Icon 32x32 sắc nét cho từng món Binh Khí (Kiếm, Đại Đao, Cung Tên, Gậy Phép) hiển thị trong ô lưới 7x7!
static func _make_weapon_icon_image(weapon_id: String) -> Image:
	var w := 32
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var wd: Dictionary = SaveManager.WEAPON_CATALOG.get(weapon_id, SaveManager.WEAPON_CATALOG["sword_basic"])
	var w_type: String = str(wd.get("type", "sword"))
	var accent: Color = wd.get("color", Color(0.8, 0.92, 1.0))
	var outline := Color(0.10, 0.06, 0.10)
	var gold := Color(0.98, 0.80, 0.28)
	var wood := Color(0.46, 0.26, 0.12)

	match w_type:
		"sword":
			# Thanh Kiếm chéo 45 độ phát sáng ánh ngọc / thép
			for i in range(18):
				_fill_rect(img, 9 + i, 22 - i, 3, 3, accent)
				_fill_rect(img, 10 + i, 21 - i, 1, 2, Color.WHITE)
			_fill_rect(img, 6, 20, 8, 3, gold)
			_fill_rect(img, 9, 17, 3, 8, gold)
			_fill_rect(img, 4, 24, 5, 4, wood)
			_fill_rect(img, 3, 27, 3, 3, gold)
		"saber":
			# Đại Đao bản rộng cong sắc bén kèm tua rua đỏ
			for i in range(16):
				var curve: int = int(float(i * i) / 48.0)
				_fill_rect(img, 10 + i, 21 - i + curve, 5, 4, accent)
				_fill_rect(img, 12 + i, 20 - i + curve, 2, 2, Color.WHITE)
			_fill_rect(img, 7, 21, 7, 3, gold)
			_fill_rect(img, 4, 23, 5, 5, wood)
			_fill_rect(img, 3, 26, 3, 4, Color(0.90, 0.18, 0.20))
		"bow":
			# Trường Cung cong giương sẵn mũi tên phát sáng
			for i in range(18):
				var bx: int = 8 + int(sin(float(i) / 17.0 * PI) * 8.0)
				_fill_rect(img, bx, 6 + i, 3, 3, wood)
			_fill_rect(img, 8, 7, 1, 18, Color(0.92, 0.88, 0.80))
			# Mũi tên ngang rực sáng
			_fill_rect(img, 8, 15, 19, 2, accent)
			_fill_rect(img, 24, 13, 4, 6, Color.WHITE)
			_fill_rect(img, 6, 13, 4, 6, Color(0.92, 0.24, 0.24))
		"staff":
			# Tiên Trượng / Gậy Phép cổ trang có vòng vàng & linh châu phát sáng
			for i in range(20):
				_fill_rect(img, 5 + i, 25 - i, 3, 2, wood)
			_fill_circle(img, 23, 8, 6, gold)
			_fill_circle(img, 23, 8, 4, accent)
			_fill_circle(img, 22, 7, 2, Color.WHITE)

	_apply_clean_outline(img, outline)
	return img


## Vẽ Icon 32x32 cho 3 loại Đan Dược (Hồi Xuân Đan ngọc lục, Tụ Khí Tán bình lam, Long Hổ Thần Đan cầu vàng)
static func _make_bag_item_icon_image(item_id: String) -> Image:
	var w := 32
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline := Color(0.10, 0.06, 0.10)
	var gold := Color(0.96, 0.78, 0.26)

	match item_id:
		"hp_potion":
			# Viên Hồi Xuân Đan ngọc lục phát sáng đặt trên đế gỗ cổ trang (giống ảnh mẫu!)
			_fill_rect(img, 9, 23, 14, 4, Color(0.46, 0.24, 0.12))
			_fill_rect(img, 11, 22, 10, 2, gold)
			_fill_circle(img, 16, 14, 8, Color(0.18, 0.76, 0.36))
			_fill_circle(img, 15, 13, 6, Color(0.42, 0.96, 0.56))
			_fill_circle(img, 13, 11, 3, Color(0.88, 1.0, 0.92))
		"mp_potion":
			# Bình Tụ Khí Tán thủy tinh xanh lam lấp lánh (giống ảnh mẫu!)
			_fill_rect(img, 13, 5, 6, 4, Color(0.68, 0.46, 0.22)) # Nút bần
			_fill_rect(img, 12, 9, 8, 4, Color(0.75, 0.90, 1.0))
			_fill_rect(img, 9, 13, 14, 14, Color(0.14, 0.52, 0.92))
			_fill_rect(img, 11, 15, 10, 10, Color(0.32, 0.76, 1.0))
			_fill_rect(img, 11, 15, 3, 6, Color(0.85, 0.96, 1.0))
		_:
			# Long Hổ Thần Đan: Quả cầu hoàng kim tỏa hào quang trên đài sen
			_fill_rect(img, 8, 24, 16, 4, Color(0.54, 0.22, 0.12))
			_fill_rect(img, 10, 22, 12, 3, gold)
			_fill_circle(img, 16, 14, 8, Color(0.92, 0.62, 0.12))
			_fill_circle(img, 16, 13, 6, Color(1.0, 0.86, 0.30))
			_fill_circle(img, 14, 11, 3, Color(1.0, 0.98, 0.85))

	_apply_clean_outline(img, outline)
	return img


static func _make_icon_image(main_col: Color, hi_col: Color, shape: String) -> Image:
	var img := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_circle(img, 10, 10, 7, Color(0.08, 0.06, 0.12))
	_fill_circle(img, 10, 10, 6, main_col)
	if shape == "heart":
		_fill_rect(img, 7, 7, 5, 5, hi_col)
	elif shape == "crystal":
		_fill_rect(img, 9, 5, 2, 10, hi_col)
		_fill_rect(img, 7, 8, 6, 4, hi_col)
	else:
		_fill_rect(img, 8, 6, 4, 8, hi_col)
	return img


static func _make_slash_image() -> Image:
	var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(40):
		for x in range(40):
			var dx := x - 20.0
			var dy := y - 20.0
			var r := sqrt(dx * dx + dy * dy)
			if r >= 11.0 and r <= 18.5 and dx > -5.0:
				var alpha := clampf(1.0 - absf(r - 15.0) / 3.8, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.88, 0.96, 1.0, alpha))
	return img


## Tự động vẽ đường viền mảnh 1px bên ngoài sprite để nhân vật & quái rõ nét trên nền 3D
static func _apply_clean_outline(img: Image, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var copy := img.duplicate() as Image
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if copy.get_pixel(x, y).a < 0.05:
				var has_neighbor := (
					copy.get_pixel(x - 1, y).a > 0.5
					or copy.get_pixel(x + 1, y).a > 0.5
					or copy.get_pixel(x, y - 1).a > 0.5
					or copy.get_pixel(x, y + 1).a > 0.5
				)
				if has_neighbor:
					img.set_pixel(x, y, col)


static func _fill_rect(img: Image, rx: int, ry: int, rw: int, rh: int, col: Color) -> void:
	var max_x := mini(img.get_width(), rx + rw)
	var max_y := mini(img.get_height(), ry + rh)
	var start_x := maxi(0, rx)
	var start_y := maxi(0, ry)
	for y in range(start_y, max_y):
		for x in range(start_x, max_x):
			img.set_pixel(x, y, col)


static func _fill_circle(img: Image, cx: int, cy: int, radius: int, col: Color) -> void:
	var r2 := radius * radius
	for y in range(maxi(0, cy - radius), mini(img.get_height(), cy + radius + 1)):
		for x in range(maxi(0, cx - radius), mini(img.get_width(), cx + radius + 1)):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r2:
				img.set_pixel(x, y, col)


static func _tint_image(img: Image, col: Color) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a > 0.01:
				img.set_pixel(x, y, Color(
					clampf(c.r * col.r, 0.0, 1.0),
					clampf(c.g * col.g, 0.0, 1.0),
					clampf(c.b * col.b, 0.0, 1.0),
					c.a * col.a
				))
