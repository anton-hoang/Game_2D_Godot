class_name PixelArtGenerator
extends RefCounted
## Bộ sinh Sprite Pixel Art HD-2D độ phân giải cao (32x40 -> 64x64) có đổ bóng 3-4 lớp màu,
## viền màu ấm (colored outline), điểm sáng tóc/áo giáp, và phụ kiện chi tiết kiểu Octopath Traveler.
## Khi có asset thật (PNG/SpriteFrames), chỉ cần gán vào custom_sprite_frames của Player / EnemyStats.

static var _cache: Dictionary = {}


static func get_player_sprite_frames(scarf_id: String = "blue", weapon_type: String = "sword", skin_id: String = "skin_default") -> SpriteFrames:
	var key := "player_frames_hd_" + scarf_id + "_" + weapon_type + "_" + skin_id
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	_add_anim(frames, "idle", 4.5, true, [
		_make_hero_frame(0, false, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(1, false, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(2, false, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(1, false, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "run", 11.0, true, [
		_make_hero_frame(0, true, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(1, true, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(2, true, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
		_make_hero_frame(3, true, false, Color.WHITE, 0, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "dash", 14.0, false, [
		_make_hero_frame(2, true, false, Color(0.68, 0.96, 1.0), 0, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "attack_1", 15.0, false, [
		_make_hero_frame(0, false, true, Color.WHITE, 1, scarf_id, weapon_type, skin_id),
		_make_hero_frame(1, false, true, Color.WHITE, 2, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "attack_2", 15.0, false, [
		_make_hero_frame(1, false, true, Color.WHITE, 2, scarf_id, weapon_type, skin_id),
		_make_hero_frame(2, false, true, Color.WHITE, 3, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "attack_3", 15.0, false, [
		_make_hero_frame(2, false, true, Color(1.0, 0.94, 0.72), 4, scarf_id, weapon_type, skin_id),
	])
	_add_anim(frames, "special", 13.0, false, [
		_make_hero_frame(2, false, true, Color(0.55, 0.92, 1.0), 4, scarf_id, weapon_type, skin_id),
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


static func get_prop_texture(prop_type: String) -> ImageTexture:
	var key := "prop_hd_" + prop_type
	if _cache.has(key):
		return _cache[key]
	var img: Image
	match prop_type:
		"tree":
			img = _make_tree_image(false)
		"tree_autumn":
			img = _make_tree_image(true)
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


## Nhân vật chính phong cách ANIME CỔ TRANG / KIẾM HIỆP (44x48 pixel — Nữ Kiếm Khách Hán Phục):
## - Tóc đen huyền dài buộc đuôi ngựa cao bồng bềnh, trâm ngọc vàng + dải lụa bay phấp phới theo bước chạy.
## - Mắt anime to tròn long lanh ánh ngọc bích, má hồng nhẹ.
## - Hán phục cổ trang cổ giao lĩnh trắng ngà phối áo khoác lụa đỏ son viền vàng kim, dải lụa/khăn choàng đổi màu theo trang bị mở khóa.
## - Tay áo rộng (quảng tụ) thướt tha, thắt lưng ngọc bội và thanh Cổ Kiếm ánh ngọc đeo hông / vung kiếm khí thủy mặc!
static func _make_hero_frame(step: int, running: bool, attacking: bool, modulate_col: Color = Color.WHITE, sword_pose: int = 0, scarf_id: String = "blue", weapon_type: String = "sword", skin_id: String = "skin_default") -> ImageTexture:
	var w := 44
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bob: int = 1 if (step % 2 == 1) else 0
	var lean: int = 1 if running else 0
	var flow: int = (step % 2) * 2 - 1 # Nhịp bay lụa & tóc (-1 / +1)
	var outline := Color(0.11, 0.08, 0.14)

	# Lấy bảng màu theo 1 trong 10 bộ Trang Phục Gacha (Thường / Hiếm / Sử Thi / Huyền Thoại)
	var sk: Dictionary = SaveManager.SKIN_CATALOG.get(skin_id, SaveManager.SKIN_CATALOG["skin_default"])
	var hair_d: Color = sk["hair_d"]
	var hair_m: Color = sk["hair_m"]
	var hair_h: Color = sk["hair_h"]
	var hair_spec: Color = hair_h.lightened(0.32)
	var skin := Color(0.99, 0.89, 0.81)
	var skin_shade := Color(0.88, 0.72, 0.64)
	var blush := Color(0.96, 0.60, 0.62)
	var eye_iris: Color = sk["eye"]

	var robe_white: Color = sk["robe"]
	var robe_shade: Color = robe_white.darkened(0.15)
	var crimson_d: Color = sk["coat_d"]
	var crimson_m: Color = sk["coat_m"]
	var crimson_h: Color = crimson_m.lightened(0.22)
	var gold := Color(0.98, 0.82, 0.30)
	var gold_d := Color(0.72, 0.52, 0.16)
	var boot_d := Color(0.18, 0.14, 0.20)

	# Dải lụa cổ trang / Phi bạch (đổi màu linh hoạt theo Khăn Choàng mở khóa từ Bảng Truy Nã!)
	var sp: Dictionary = SaveManager.SCARF_PALETTES.get(scarf_id, SaveManager.SCARF_PALETTES["blue"])
	var ribbon_d: Color = sp["dark"]
	var ribbon_m: Color = sp["mid"]
	var ribbon_h: Color = sp["hi"]

	# 1. Đuôi tóc dài buộc cao (High Ponytail) & Dải lụa Phi Bạch tung bay phía sau
	var tail_x: int = 8 - (3 if running else 0)
	_fill_rect(img, tail_x, 12 + bob + flow, 8, 5, hair_d)
	_fill_rect(img, tail_x - 3, 16 + bob + flow, 7, 8, hair_d)
	_fill_rect(img, tail_x - 2, 16 + bob + flow, 4, 6, hair_m)
	_fill_rect(img, tail_x - 5, 22 + bob + flow, 5, 6, hair_d)
	# Dải lụa phi bạch uốn lượn mềm mại phía sau lưng
	_fill_rect(img, tail_x - 2, 23 + bob - flow, 10, 3, ribbon_d)
	_fill_rect(img, tail_x - 1, 23 + bob - flow, 8, 2, ribbon_m)
	_fill_rect(img, tail_x - 5, 26 + bob - flow, 6, 3, ribbon_m)
	_fill_rect(img, tail_x - 4, 26 + bob - flow, 4, 1, ribbon_h)

	# 2. Búi tóc đỉnh đầu + Trâm cài vàng ngọc bích + Dải ruy băng tóc
	_fill_circle(img, 18 + lean, 6 + bob, 4, hair_d)
	_fill_circle(img, 18 + lean, 6 + bob, 3, hair_m)
	_fill_rect(img, 13 + lean, 5 + bob, 11, 2, gold) # Trâm cài ngang
	_fill_rect(img, 11 + lean, 4 + bob, 3, 3, ribbon_h) # Hạt ngọc đầu trâm
	_fill_rect(img, 12 + lean, 8 + bob, 4, 3, ribbon_m) # Nơ lụa buộc tóc

	# 3. Đầu & Mái tóc Anime Cổ Trang bồng bềnh có vầng sáng ngang đỉnh tóc
	_fill_circle(img, 21 + lean, 14 + bob, 8, hair_d)
	_fill_circle(img, 21 + lean, 13 + bob, 7, hair_m)
	_fill_rect(img, 16 + lean, 8 + bob, 10, 2, hair_h)
	_fill_rect(img, 18 + lean, 8 + bob, 5, 1, hair_spec) # Vầng sáng tóc đặc trưng anime

	# 4. Khuôn mặt Anime thanh tú (mắt lớn có tròng ngọc bích & chấm sáng long lanh)
	_fill_rect(img, 18 + lean, 13 + bob, 10, 8, skin)
	_fill_rect(img, 18 + lean, 13 + bob, 10, 1, skin_shade)
	_fill_rect(img, 19 + lean, 20 + bob, 8, 1, skin_shade)
	# Hai lọn tóc mai dài rủ hai bên má đặc trưng cổ trang
	_fill_rect(img, 16 + lean, 12 + bob, 3, 12, hair_d)
	_fill_rect(img, 17 + lean, 12 + bob, 2, 10, hair_m)
	_fill_rect(img, 26 + lean, 12 + bob, 3, 9, hair_d)
	# Tóc mái tỉa nhọn kiểu anime
	_fill_rect(img, 18 + lean, 11 + bob, 10, 3, hair_m)
	img.set_pixel(21 + lean, 14 + bob, hair_d)
	img.set_pixel(25 + lean, 14 + bob, hair_d)
	# Cặp mắt anime 3px chi tiết (mi đen + tròng ngọc + chấm sáng trắng)
	_fill_rect(img, 20 + lean, 15 + bob, 3, 3, outline)
	_fill_rect(img, 25 + lean, 15 + bob, 3, 3, outline)
	_fill_rect(img, 21 + lean, 16 + bob, 2, 2, eye_iris)
	_fill_rect(img, 25 + lean, 16 + bob, 2, 2, eye_iris)
	img.set_pixel(20 + lean, 15 + bob, Color.WHITE)
	img.set_pixel(25 + lean, 15 + bob, Color.WHITE)
	# Má hồng nhẹ
	_fill_rect(img, 19 + lean, 18 + bob, 2, 1, blush)
	img.set_pixel(27 + lean, 18 + bob, blush)

	# 5. Cổ áo Hán phục giao lĩnh chữ Y + Khăn lụa vòng cổ
	_fill_rect(img, 16 + lean, 21 + bob, 13, 3, ribbon_d)
	_fill_rect(img, 17 + lean, 21 + bob, 11, 2, ribbon_m)
	_fill_rect(img, 19 + lean, 21 + bob, 7, 1, ribbon_h)

	# 6. Thân Hán phục trắng ngà - đỏ son viền vàng + Tay áo rộng (Quảng tụ) + Vạt váy thướt tha
	_fill_rect(img, 15 + lean, 24 + bob, 14, 14, robe_shade)
	_fill_rect(img, 16 + lean, 24 + bob, 12, 13, robe_white)
	# Áo khoác lụa đỏ son viền vàng khoác ngoài hai bên vai
	_fill_rect(img, 14 + lean, 24 + bob, 5, 11, crimson_d)
	_fill_rect(img, 15 + lean, 24 + bob, 4, 10, crimson_m)
	_fill_rect(img, 16 + lean, 24 + bob, 2, 6, crimson_h)
	_fill_rect(img, 24 + lean, 24 + bob, 5, 10, crimson_m)
	# Viền cổ áo chữ V đỏ vàng
	_fill_rect(img, 19 + lean, 24 + bob, 2, 4, crimson_m)
	_fill_rect(img, 22 + lean, 24 + bob, 2, 4, crimson_m)
	# Đai lưng lụa + Ngọc bội vàng treo giữa eo
	_fill_rect(img, 15 + lean, 30 + bob, 14, 2, crimson_d)
	_fill_rect(img, 16 + lean, 30 + bob, 12, 1, gold)
	_fill_rect(img, 20 + lean, 31 + bob, 3, 5, ribbon_m) # Dải ngọc bội rủ xuống vạt váy
	_fill_rect(img, 21 + lean, 32 + bob, 1, 2, gold)
	# Chân váy xòe chuyển động nhẹ khi chạy + viền hoa văn đỏ vàng
	var skirt_fl: int = 1 if running else 0
	_fill_rect(img, 14 + lean - skirt_fl, 35 + bob, 16 + skirt_fl * 2, 5, robe_white)
	_fill_rect(img, 14 + lean - skirt_fl, 38 + bob, 16 + skirt_fl * 2, 2, crimson_m)
	_fill_rect(img, 14 + lean - skirt_fl, 37 + bob, 16 + skirt_fl * 2, 1, gold_d)

	# 7. Đôi hài vải thêu cổ trang bước uyển chuyển
	var left_dy: int = -2 if (running and step == 0) else 0
	var right_dy: int = -2 if (running and step == 2) else 0
	var left_dx: int = -1 if (running and step == 0) else (1 if (running and step == 2) else 0)
	var right_dx: int = -left_dx
	_fill_rect(img, 16 + lean + left_dx, 40 + left_dy, 4, 5, boot_d)
	_fill_rect(img, 17 + lean + left_dx, 43 + left_dy, 3, 2, crimson_m)
	_fill_rect(img, 23 + lean + right_dx, 40 + right_dy, 4, 5, boot_d)
	_fill_rect(img, 24 + lean + right_dx, 43 + right_dy, 3, 2, crimson_m)

	# 8. Vẽ Vũ Khí & Animation tấn công riêng biệt cho 4 hệ: KIẾM / ĐAO / CUNG TÊN / GẬY PHÉP!
	_draw_hero_weapon_pose(img, weapon_type, attacking, sword_pose, bob, lean, gold, crimson_m)

	_apply_clean_outline(img, outline)
	if modulate_col != Color.WHITE:
		_tint_image(img, modulate_col)

	return ImageTexture.create_from_image(img)


## Vẽ tạo hình và các khung hình tấn công riêng cho 4 loại vũ khí cổ trang:
## - "sword" (Kiếm): Đâm lên -> Chém ngang -> Kiếm khí ngọc bích.
## - "saber" (Đại Đao): Giơ đại đao bản rộng cong -> Bổ chẻ rực lửa -> Quét bán nguyệt đỏ vàng.
## - "bow" (Cung Tên): Giương cánh cung cong -> Kéo dây tên sáng -> Bắn luồng tiễn rực sáng.
## - "staff" (Gậy Phép): Gậy ngọc có vòng tròn thái cực/hạt châu phát sáng, giơ cao tụ pháp lực & phóng cầu phép!
static func _draw_hero_weapon_pose(img: Image, weapon_type: String, attacking: bool, pose: int, bob: int, lean: int, gold: Color, crimson: Color) -> void:
	var steel_d := Color(0.46, 0.66, 0.80)
	var steel_m := Color(0.84, 0.95, 1.0)
	var steel_hi := Color(1.0, 1.0, 1.0)
	var wood_c := Color(0.48, 0.28, 0.14)

	match weapon_type:
		"saber":
			# ĐẠI ĐAO BẢN RỘNG CONG UY LỰC (Ánh đỏ lửa - vàng kim)
			var saber_glow := Color(1.0, 0.44, 0.22)
			if attacking:
				if pose == 1: # Giơ cao đại đao chém bổ xuống
					_fill_rect(img, 24, 6 + bob, 6, 18, saber_glow)
					_fill_rect(img, 26, 7 + bob, 3, 16, steel_hi)
					_fill_rect(img, 23, 24 + bob, 8, 3, gold)
				elif pose == 2: # Quét ngang đại đao bản rộng
					_fill_rect(img, 25, 22 + bob, 17, 6, saber_glow)
					_fill_rect(img, 26, 23 + bob, 15, 3, steel_hi)
					_fill_rect(img, 23, 22 + bob, 3, 7, gold)
				else: # Bổ chẻ Bá Vương Trảm rực cam vàng
					_fill_rect(img, 22, 11 + bob, 20, 18, Color(1.0, 0.52, 0.18, 0.78))
					_fill_rect(img, 25, 16 + bob, 17, 8, Color(1.0, 0.94, 0.72))
					_fill_rect(img, 22, 18 + bob, 4, 7, gold)
			else:
				# Đại đao vác sau lưng với chuôi vàng & tua rua đỏ
				_fill_rect(img, 8 + lean, 18 + bob, 4, 14, steel_d)
				_fill_rect(img, 9 + lean, 19 + bob, 2, 12, steel_m)
				_fill_rect(img, 7 + lean, 31 + bob, 6, 2, gold)
				_fill_rect(img, 9 + lean, 33 + bob, 2, 4, crimson)

		"bow":
			# TRƯỜNG CUNG CỔ TRANG (Giương cung kéo dây bắn tên sáng)
			var bow_col := Color(0.68, 0.44, 0.18)
			var arrow_glow := Color(0.65, 1.0, 0.48) if pose < 4 else Color(1.0, 0.65, 0.22)
			if attacking:
				# Thân cung cong đặt phía trước tay phải
				_fill_rect(img, 30, 14 + bob, 3, 5, bow_col)
				_fill_rect(img, 32, 19 + bob, 3, 11, bow_col)
				_fill_rect(img, 30, 30 + bob, 3, 5, bow_col)
				# Dây cung căng & Mũi tên phát sáng chuẩn bị/đang phóng
				_fill_rect(img, 27, 16 + bob, 1, 17, Color(0.95, 0.92, 0.85))
				var arrow_x: int = 25 if pose == 1 else (28 if pose == 2 else 30)
				_fill_rect(img, arrow_x, 23 + bob, 13, 3, arrow_glow)
				_fill_rect(img, arrow_x + 2, 24 + bob, 11, 1, Color.WHITE)
				if pose >= 3:
					_fill_circle(img, 36, 24 + bob, 4, Color(1.0, 0.88, 0.35, 0.8))
			else:
				# Cung đeo chéo sau lưng
				_fill_rect(img, 9 + lean, 16 + bob, 2, 16, bow_col)
				_fill_rect(img, 11 + lean, 14 + bob, 3, 3, gold)
				_fill_rect(img, 11 + lean, 31 + bob, 3, 3, gold)

		"staff":
			# GẬY PHÉP / TIÊN TRƯỢNG CỔ TRANG (Đỉnh gắn vòng Thái Cực & Linh Châu phát sáng)
			var orb_col := Color(0.45, 0.82, 1.0) if pose < 4 else Color(0.88, 0.46, 1.0)
			if attacking:
				# Giơ cao gậy phép về phía trước tụ linh khí
				var tilt_x: int = 30 if pose == 1 else 32
				_fill_rect(img, tilt_x, 12 + bob, 3, 26, wood_c)
				_fill_rect(img, tilt_x - 2, 9 + bob, 7, 3, gold)
				_fill_circle(img, tilt_x + 1, 8 + bob, 5 if pose >= 3 else 4, orb_col)
				_fill_circle(img, tilt_x + 1, 8 + bob, 2, Color.WHITE)
				if pose >= 2:
					# Vòng pháp trận sáng lóe trước đầu trượng
					_fill_circle(img, 38, 16 + bob, 4, orb_col)
					_fill_circle(img, 38, 16 + bob, 2, Color.WHITE)
			else:
				# Cầm gậy phép dựng đứng bên cạnh với linh châu sáng dịu
				_fill_rect(img, 10 + lean, 14 + bob, 3, 25, wood_c)
				_fill_rect(img, 9 + lean, 12 + bob, 5, 2, gold)
				_fill_circle(img, 11 + lean, 10 + bob, 3, orb_col)
				img.set_pixel(11 + lean, 9 + bob, Color.WHITE)

		_: # "sword" (Thanh Phong Cổ Kiếm mặc định)
			if attacking:
				if pose == 1:
					_fill_rect(img, 28, 10 + bob, 3, 17, steel_d)
					_fill_rect(img, 29, 10 + bob, 2, 16, steel_m)
					_fill_rect(img, 30, 11 + bob, 1, 12, steel_hi)
					_fill_rect(img, 26, 26 + bob, 7, 2, gold)
				elif pose == 2:
					_fill_rect(img, 27, 24 + bob, 15, 4, steel_d)
					_fill_rect(img, 28, 24 + bob, 14, 2, steel_m)
					_fill_rect(img, 29, 24 + bob, 12, 1, steel_hi)
					_fill_rect(img, 25, 23 + bob, 2, 6, gold)
				elif pose == 3:
					_fill_rect(img, 26, 18 + bob, 16, 6, steel_m)
					_fill_rect(img, 28, 19 + bob, 14, 3, steel_hi)
					_fill_rect(img, 24, 20 + bob, 2, 5, gold)
				else:
					_fill_rect(img, 24, 12 + bob, 18, 15, Color(0.42, 0.95, 0.88, 0.75))
					_fill_rect(img, 26, 16 + bob, 16, 6, steel_hi)
					_fill_rect(img, 24, 18 + bob, 3, 6, gold)
			else:
				_fill_rect(img, 10 + lean, 31 + bob, 5, 3, Color(0.14, 0.12, 0.18))
				_fill_rect(img, 7 + lean, 33 + bob, 5, 2, Color(0.14, 0.12, 0.18))
				_fill_rect(img, 13 + lean, 29 + bob, 3, 3, gold)
				_fill_rect(img, 11 + lean, 34 + bob, 2, 4, crimson)


## Quái vật & Boss HD-2D độ phân giải cao có đổ bóng nhiều sắc độ và viền sắc nét
static func _make_enemy_frame(archetype: String, step: int, attacking: bool, tint: Color) -> ImageTexture:
	var is_boss := archetype == "boss"
	var is_tank := archetype == "tank"
	var w := 60 if is_boss else (44 if is_tank else 36)
	var h := 62 if is_boss else (46 if is_tank else 38)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bob := 1 if (step % 2 == 1) else 0
	var outline := Color(0.09, 0.06, 0.12)

	match archetype:
		"melee":
			# Goblin Chiến Binh đội mũ sắt gỉ, khăn đỏ, cầm đoản đao sắc
			var skin_d := Color(0.22, 0.42, 0.18) * tint
			var skin_m := Color(0.36, 0.62, 0.28) * tint
			var skin_h := Color(0.54, 0.78, 0.38) * tint
			var armor_d := Color(0.30, 0.20, 0.16) * tint
			var armor_m := Color(0.48, 0.33, 0.24) * tint
			var steel := Color(0.56, 0.60, 0.68)
			var eye := Color(1.0, 0.25, 0.18)

			# Tai nhọn dài đặc trưng
			_fill_rect(img, 5, 11 + bob, 6, 3, skin_m)
			_fill_rect(img, 25, 11 + bob, 6, 3, skin_d)
			# Đầu + Mũ sắt chóp nhọn
			_fill_circle(img, 18, 13 + bob, 6, skin_m)
			_fill_rect(img, 14, 9 + bob, 6, 3, skin_h)
			_fill_rect(img, 11, 6 + bob, 14, 5, steel)
			_fill_rect(img, 15, 3 + bob, 6, 4, steel.darkened(0.2))
			# Mắt đỏ phát sáng & răng nanh
			_fill_rect(img, 14, 13 + bob, 2, 2, eye)
			_fill_rect(img, 20, 13 + bob, 2, 2, eye)
			img.set_pixel(16, 17 + bob, Color.WHITE)
			img.set_pixel(19, 17 + bob, Color.WHITE)
			# Khăn cổ đỏ & Giáp da đinh tán
			_fill_rect(img, 11, 19 + bob, 14, 3, Color(0.75, 0.18, 0.18))
			_fill_rect(img, 10, 22 + bob, 16, 9, armor_d)
			_fill_rect(img, 12, 22 + bob, 12, 7, armor_m)
			_fill_rect(img, 10, 27 + bob, 16, 2, Color(0.2, 0.12, 0.08))
			# Chân
			var l_off := -1 if step == 0 else 0
			var r_off := -1 if step == 2 else 0
			_fill_rect(img, 11, 31 + l_off, 5, 5, armor_d)
			_fill_rect(img, 20, 31 + r_off, 5, 5, armor_d)
			# Đoản đao răng cưa
			if attacking:
				_fill_rect(img, 25, 18 + bob, 9, 4, Color(0.88, 0.92, 1.0))
				_fill_rect(img, 24, 17 + bob, 2, 6, Color(0.85, 0.68, 0.22))
			else:
				_fill_rect(img, 26, 20 + bob, 3, 9, steel)

		"ranged":
			# Đại Pháp Sư Hắc Ám: Mũ phù thủy chóp cong, áo choàng tím viền vàng, cầu pha lê lơ lửng
			var robe_d := Color(0.22, 0.11, 0.38) * tint
			var robe_m := Color(0.38, 0.20, 0.62) * tint
			var robe_h := Color(0.56, 0.34, 0.82) * tint
			var gold := Color(0.95, 0.76, 0.24)
			var orb_col := Color(0.28, 0.92, 1.0) if not attacking else Color(1.0, 0.35, 0.85)

			# Mũ phù thủy cong mềm
			_fill_rect(img, 14, 2 + bob, 7, 3, robe_h)
			_fill_rect(img, 12, 5 + bob, 10, 4, robe_m)
			_fill_rect(img, 10, 9 + bob, 15, 3, robe_d)
			_fill_rect(img, 7, 11 + bob, 21, 3, robe_m)
			_fill_rect(img, 10, 10 + bob, 15, 2, gold)
			# Mặt tối bí ẩn + cặp mắt phép sáng rực
			_fill_rect(img, 12, 14 + bob, 11, 6, Color(0.06, 0.04, 0.10))
			_fill_rect(img, 14, 16 + bob, 2, 2, orb_col)
			_fill_rect(img, 19, 16 + bob, 2, 2, orb_col)
			# Áo choàng lơ lửng có hoa văn vàng
			_fill_rect(img, 10, 20 + bob, 15, 14, robe_d)
			_fill_rect(img, 11, 20 + bob, 12, 12, robe_m)
			_fill_rect(img, 12, 20 + bob, 4, 10, robe_h)
			_fill_rect(img, 16, 20 + bob, 3, 14, gold)
			# Trượng gỗ cổ & quả cầu phép tỏa sáng
			_fill_rect(img, 27, 10 + bob, 3, 24, Color(0.42, 0.26, 0.14))
			_fill_circle(img, 28, 8 + bob, 4, orb_col)
			_fill_circle(img, 27, 7 + bob, 2, Color.WHITE)

		"charger":
			# Chiến Thú Bờm Lửa (Bò mộng bóng tối sừng ngà, bờm lửa cam, mắt rực)
			var fur_d := Color(0.48, 0.14, 0.12) * tint
			var fur_m := Color(0.76, 0.26, 0.16) * tint
			var fur_h := Color(0.95, 0.46, 0.22) * tint
			var mane := Color(1.0, 0.72, 0.20)
			var horn := Color(0.96, 0.92, 0.80)

			# Bờm lửa sau lưng
			_fill_circle(img, 14, 14 + bob, 7, mane)
			# Thân cơ bắp lực lưỡng
			_fill_rect(img, 7, 13 + bob, 21, 14, fur_d)
			_fill_rect(img, 8, 12 + bob, 19, 12, fur_m)
			_fill_rect(img, 10, 12 + bob, 13, 4, fur_h)
			# Cặp sừng nhọn húc về trước
			_fill_rect(img, 25, 9 + bob, 7, 3, horn)
			_fill_rect(img, 28, 7 + bob, 5, 3, Color.WHITE)
			_fill_rect(img, 5, 10 + bob, 5, 3, horn.darkened(0.15))
			# Mắt giận dữ
			_fill_rect(img, 22, 16 + bob, 3, 2, Color(1.0, 0.95, 0.2))
			# 4 chân móng guốc mạnh mẽ
			var stride := 2 if (step == 0) else (-2 if step == 2 else 0)
			_fill_rect(img, 8 + stride, 27, 5, 8, fur_d)
			_fill_rect(img, 21 - stride, 27, 5, 8, fur_d)
			_fill_rect(img, 8 + stride, 33, 5, 3, Color(0.18, 0.14, 0.16))
			_fill_rect(img, 21 - stride, 33, 5, 3, Color(0.18, 0.14, 0.16))

		"tank":
			# Hộ Vệ Giáp Sắt Khổng Lồ (Mũ trụ có khe lửa, giáp vai gai, đại khiên thập tự vàng)
			var steel_d := Color(0.20, 0.24, 0.30) * tint
			var steel_m := Color(0.42, 0.48, 0.58) * tint
			var steel_h := Color(0.68, 0.75, 0.84) * tint
			var gold := Color(0.92, 0.72, 0.22)
			var visor := Color(1.0, 0.48, 0.12)

			# Lông mũ trụ đỏ
			_fill_rect(img, 18, 2 + bob, 8, 5, Color(0.82, 0.16, 0.20))
			# Mũ trụ thép
			_fill_rect(img, 13, 6 + bob, 18, 10, steel_d)
			_fill_rect(img, 15, 7 + bob, 14, 8, steel_m)
			_fill_rect(img, 16, 7 + bob, 6, 3, steel_h)
			_fill_rect(img, 16, 11 + bob, 12, 2, visor)
			# Cầu vai khổng lồ & Thân giáp tấm
			_fill_rect(img, 6, 15 + bob, 31, 10, steel_d)
			_fill_rect(img, 7, 16 + bob, 10, 8, steel_m)
			_fill_rect(img, 26, 16 + bob, 10, 8, steel_m)
			_fill_rect(img, 8, 16 + bob, 5, 3, steel_h)
			_fill_rect(img, 11, 18 + bob, 22, 16, steel_d)
			_fill_rect(img, 13, 19 + bob, 18, 13, steel_m)
			_fill_rect(img, 19, 19 + bob, 6, 13, gold)
			# Đại khiên bảo vệ bên hông
			_fill_rect(img, 31, 14 + bob, 10, 21, steel_d)
			_fill_rect(img, 32, 15 + bob, 8, 19, Color(0.28, 0.34, 0.44))
			_fill_rect(img, 35, 16 + bob, 2, 17, gold)
			_fill_rect(img, 32, 23 + bob, 8, 2, gold)
			# Chân trụ bọc thép
			_fill_rect(img, 12, 34, 8, 9, steel_d)
			_fill_rect(img, 24, 34, 8, 9, steel_d)
			_fill_rect(img, 13, 35, 5, 4, steel_h)

		"boss":
			# BOSS CHÚA TỂ HẮC ÁM MALAKOR (60x62): Vương miện sừng vàng, áo choàng đỏ rách,
			# giáp hắc thạch phát sáng lõi tim đỏ rực, và thanh Ma Kiếm Khổng Lồ rực lửa.
			var armor_d := Color(0.14, 0.10, 0.22) * tint
			var armor_m := Color(0.28, 0.20, 0.40) * tint
			var armor_h := Color(0.46, 0.36, 0.62) * tint
			var cape_d := Color(0.42, 0.06, 0.12) * tint
			var cape_m := Color(0.74, 0.12, 0.20) * tint
			var gold := Color(0.98, 0.80, 0.26)
			var core := Color(1.0, 0.24, 0.38) if not attacking else Color(1.0, 0.90, 0.28)

			# Áo choàng đế vương rộng tung bay phía sau
			_fill_rect(img, 7, 15 + bob, 42, 36, cape_d)
			_fill_rect(img, 9, 17 + bob, 38, 32, cape_m)
			_fill_rect(img, 11, 19 + bob, 6, 26, Color(0.90, 0.22, 0.28))

			# Vương miện sừng ác quỷ bằng vàng
			_fill_rect(img, 17, 4 + bob, 4, 10, gold)
			_fill_rect(img, 35, 4 + bob, 4, 10, gold)
			_fill_rect(img, 25, 2 + bob, 6, 8, gold)
			_fill_rect(img, 20, 8 + bob, 16, 6, gold.darkened(0.15))

			# Đầu giáp hắc ám + cặp mắt rực sáng
			_fill_rect(img, 19, 12 + bob, 18, 12, armor_d)
			_fill_rect(img, 21, 13 + bob, 14, 9, armor_m)
			_fill_rect(img, 22, 16 + bob, 4, 3, core)
			_fill_rect(img, 30, 16 + bob, 4, 3, core)

			# Cầu vai gai lớn + Giáp ngực có Lõi năng lượng Ma Thạch
			_fill_rect(img, 10, 21 + bob, 36, 11, armor_d)
			_fill_rect(img, 11, 22 + bob, 12, 9, armor_m)
			_fill_rect(img, 33, 22 + bob, 12, 9, armor_m)
			_fill_rect(img, 12, 22 + bob, 7, 3, armor_h)
			_fill_rect(img, 15, 24 + bob, 26, 22, armor_d)
			_fill_rect(img, 17, 25 + bob, 22, 19, armor_m)
			# Lõi năng lượng ngực phát sáng rực
			_fill_circle(img, 28, 33 + bob, 5, core)
			_fill_circle(img, 28, 33 + bob, 2, Color.WHITE)
			# Đai lưng hoàng kim
			_fill_rect(img, 16, 41 + bob, 24, 3, gold)

			# Thanh Đại Ma Kiếm khổng lồ bên tay phải
			var sword_y := 6 + bob if not attacking else 14 + bob
			_fill_rect(img, 46, sword_y, 8, 36, core if attacking else Color(0.45, 0.52, 0.68))
			_fill_rect(img, 48, sword_y + 2, 4, 32, Color(1.0, 0.94, 0.85) if attacking else Color(0.84, 0.90, 1.0))
			_fill_rect(img, 43, sword_y + 34, 14, 4, gold)

			# Chân chiến giáp
			_fill_rect(img, 17, 46, 9, 12, armor_d)
			_fill_rect(img, 30, 46, 9, 12, armor_d)
			_fill_rect(img, 18, 47, 5, 5, armor_h)
			_fill_rect(img, 31, 47, 5, 5, armor_h)

	_apply_clean_outline(img, outline)
	return ImageTexture.create_from_image(img)


## Cây cổ thụ tán rộng nhiều tầng sáng tối (hỗ trợ cả bản lá xanh đêm & lá thu vàng)
static func _make_tree_image(autumn: bool) -> Image:
	var w := 64
	var h := 80
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var trunk_d := Color(0.18, 0.11, 0.08)
	var trunk_m := Color(0.30, 0.19, 0.13)
	var trunk_h := Color(0.42, 0.28, 0.18)

	var l1 := Color(0.08, 0.19, 0.13) if not autumn else Color(0.36, 0.14, 0.09)
	var l2 := Color(0.14, 0.30, 0.19) if not autumn else Color(0.58, 0.26, 0.12)
	var l3 := Color(0.22, 0.44, 0.25) if not autumn else Color(0.82, 0.46, 0.16)
	var l4 := Color(0.35, 0.58, 0.32) if not autumn else Color(0.95, 0.70, 0.24)

	# Thân cây cổ thụ xù xì & rễ bạnh
	_fill_rect(img, 26, 42, 12, 34, trunk_d)
	_fill_rect(img, 28, 44, 7, 30, trunk_m)
	_fill_rect(img, 29, 45, 3, 26, trunk_h)
	_fill_rect(img, 20, 70, 24, 6, trunk_d)
	_fill_rect(img, 23, 68, 18, 5, trunk_m)
	# Nhánh cây vươn chữ Y như cây cổ thụ lớn giữa làng trong ảnh mẫu
	_fill_rect(img, 18, 34, 8, 12, trunk_d)
	_fill_rect(img, 38, 34, 8, 12, trunk_d)

	# Tán lá nhiều tầng (Layered foliage clusters)
	_fill_circle(img, 32, 28, 23, l1)
	_fill_circle(img, 18, 34, 15, l1)
	_fill_circle(img, 46, 34, 15, l1)
	_fill_circle(img, 32, 24, 19, l2)
	_fill_circle(img, 20, 30, 12, l2)
	_fill_circle(img, 44, 30, 12, l2)
	_fill_circle(img, 29, 19, 13, l3)
	_fill_circle(img, 40, 23, 10, l3)
	_fill_circle(img, 21, 25, 9, l3)
	_fill_circle(img, 28, 14, 8, l4)
	_fill_circle(img, 38, 18, 6, l4)
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


## Chân dung Nữ Kiếm Khách Anime Cổ Trang 48x48 (tự động đổi theo 10 Trang Phục Gacha & Màu Khăn Choàng)
static func _make_hero_portrait_image(scarf_id: String = "blue", skin_id: String = "skin_default") -> Image:
	var w := 48
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var sk: Dictionary = SaveManager.SKIN_CATALOG.get(skin_id, SaveManager.SKIN_CATALOG["skin_default"])
	var border_col: Color = sk["tag_color"] if bool(sk["has_vfx"]) else Color(0.88, 0.70, 0.32)
	img.fill(Color(0.14, 0.08, 0.11))
	# Khung viền cổ trang vàng đồng (hoặc ánh sắc hiếm của skin)
	_fill_rect(img, 0, 0, w, 2, border_col)
	_fill_rect(img, 0, h - 2, w, 2, border_col)
	_fill_rect(img, 0, 0, 2, h, border_col)
	_fill_rect(img, w - 2, 0, 2, h, border_col)
	_fill_rect(img, 3, 3, w - 6, 1, sk["coat_m"])
	_fill_rect(img, 3, h - 4, w - 6, 1, sk["coat_m"])

	var sp: Dictionary = SaveManager.SCARF_PALETTES.get(scarf_id, SaveManager.SCARF_PALETTES["blue"])
	# Hán phục theo bộ Trang Phục đang mặc
	_fill_rect(img, 8, 34, 32, 12, sk["coat_m"])
	_fill_rect(img, 16, 34, 16, 12, sk["robe"])
	_fill_rect(img, 12, 31, 24, 5, sp["mid"])
	_fill_rect(img, 16, 31, 16, 2, sp["hi"])

	# Búi tóc đỉnh đầu + Trâm cài vàng & ngọc
	_fill_circle(img, 24, 8, 5, sk["hair_d"])
	_fill_rect(img, 14, 7, 20, 2, Color(0.98, 0.82, 0.30))
	_fill_rect(img, 12, 6, 4, 4, sp["hi"])

	# Mái tóc bồng bềnh theo màu Skin
	_fill_circle(img, 24, 21, 13, sk["hair_d"])
	_fill_circle(img, 24, 20, 11, sk["hair_m"])
	_fill_rect(img, 16, 11, 16, 2, sk["hair_h"])
	_fill_rect(img, 20, 11, 8, 1, (sk["hair_h"] as Color).lightened(0.32))

	# Khuôn mặt anime thanh tú, 2 lọn tóc mai dài, cặp mắt theo màu Skin
	_fill_rect(img, 16, 16, 16, 14, Color(0.99, 0.89, 0.81))
	_fill_rect(img, 13, 15, 4, 18, sk["hair_d"])
	_fill_rect(img, 31, 15, 4, 18, sk["hair_d"])
	_fill_rect(img, 18, 20, 4, 4, Color(0.10, 0.08, 0.14))
	_fill_rect(img, 26, 20, 4, 4, Color(0.10, 0.08, 0.14))
	_fill_rect(img, 19, 21, 3, 3, sk["eye"])
	_fill_rect(img, 27, 21, 3, 3, sk["eye"])
	img.set_pixel(19, 20, Color.WHITE)
	img.set_pixel(27, 20, Color.WHITE)
	_fill_rect(img, 17, 25, 3, 2, Color(0.96, 0.60, 0.62))
	_fill_rect(img, 28, 25, 3, 2, Color(0.96, 0.60, 0.62))
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
