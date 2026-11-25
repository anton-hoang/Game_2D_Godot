extends Node
## SaveManager (Autoload): Lưu và tải tiến trình người chơi bằng ConfigFile.
## Dữ liệu lưu tại user://save_data.cfg gồm:
## - Màn đã mở, vàng, nâng cấp, kỷ lục hạng S/A/B/C.
## - Nhiệm vụ Bảng Truy Nã (Quest Board): tiến độ, nhận thưởng, danh hiệu & màu khăn choàng mở khóa!

signal data_changed
signal quest_completed_notify(quest_title: String, reward_summary: String)
signal cosmetic_changed
signal inventory_changed

const SAVE_PATH := "user://save_data.cfg"

## Kho Dữ Liệu 8 Món Binh Khí thuộc 4 Hệ Vũ Khí (Kiếm, Đao, Cung Tên, Gậy Phép)
## Mỗi hệ có animation tấn công riêng + chỉ số + phẩm chất (Thường / Hiếm / Sử Thi / Huyền Thoại)
const WEAPON_CATALOG: Dictionary = {
	"sword_basic": {
		"name": "Thanh Phong Cổ Kiếm", "type": "sword", "rarity": "Thường",
		"color": Color(0.75, 0.92, 1.0), "dmg": 0.0, "speed": 1.0, "price": 0,
		"desc": "Kiếm cổ cân bằng, Tam Liên Trảm linh hoạt. Tuyệt kỹ: Kiếm Khí Xung Kích 360°.",
	},
	"sword_jade": {
		"name": "Bích Ngọc Long Kiếm", "type": "sword", "rarity": "Sử Thi",
		"color": Color(0.32, 0.96, 0.72), "dmg": 14.0, "speed": 1.12, "price": 135,
		"desc": "Thần kiếm ngọc bích sắc bén (+14 Công lực, ra đòn nhanh). Tuyệt kỹ: Kiếm Khí Xung Kích.",
	},
	"saber_iron": {
		"name": "Huyết Nguyệt Đại Đao", "type": "saber", "rarity": "Hiếm",
		"color": Color(1.0, 0.42, 0.28), "dmg": 9.0, "speed": 0.88, "price": 85,
		"desc": "Đại đao uy lực chém quét tầm rộng & đẩy lùi cực mạnh. Tuyệt kỹ: Bá Vương Trảm Phá.",
	},
	"saber_dragon": {
		"name": "Thanh Long Yển Nguyệt Đao", "type": "saber", "rarity": "Huyền Thoại",
		"color": Color(1.0, 0.80, 0.22), "dmg": 20.0, "speed": 0.94, "price": 210,
		"desc": "Thần đao trấn quốc (+20 Công lực, quét càn quái diện rộng). Tuyệt kỹ: Long Quyển Trảm.",
	},
	"bow_bamboo": {
		"name": "Trúc Lâm Trường Cung", "type": "bow", "rarity": "Hiếm",
		"color": Color(0.62, 0.95, 0.42), "dmg": 6.0, "speed": 1.18, "price": 90,
		"desc": "Cung tên tầm xa bắn liên hoàn 3 mũi tên xuyên gió. Tuyệt kỹ: Loạn Tiễn Hình Quạt (7 tên).",
	},
	"bow_phoenix": {
		"name": "Phượng Hoàng Hỏa Cung", "type": "bow", "rarity": "Huyền Thoại",
		"color": Color(1.0, 0.54, 0.20), "dmg": 16.0, "speed": 1.25, "price": 195,
		"desc": "Thần cung bắn tiễn rực lửa (+16 Công lực). Tuyệt kỹ: Phượng Vũ Cửu Tiễn (7 tên nổ).",
	},
	"staff_jade": {
		"name": "Linh Hạc Pháp Trượng", "type": "staff", "rarity": "Hiếm",
		"color": Color(0.55, 0.72, 1.0), "dmg": 8.0, "speed": 1.02, "price": 105,
		"desc": "Gậy phép phóng cầu linh lực truy đuổi mục tiêu. Tuyệt kỹ: Bát Quái Linh Châu 8 hướng.",
	},
	"staff_celestial": {
		"name": "Thái Cực Tiên Trượng", "type": "staff", "rarity": "Huyền Thoại",
		"color": Color(0.86, 0.56, 1.0), "dmg": 18.0, "speed": 1.08, "price": 220,
		"desc": "Tiên trượng tối thượng (+18 Công lực, cầu phép nổ lan). Tuyệt kỹ: Cửu Thiên Pháp Hoàn.",
	},
}

## CHIÊU CUỐI (ULTIMATE SKILL — PHÍM [U] / [R]) ĐẶC TRƯNG RIÊNG CHO TỪNG HỆ VŨ KHÍ!
const WEAPON_ULTIMATES: Dictionary = {
	"sword": {
		"name": "VẠN KIẾM QUY TÔNG",
		"subtitle": "Chiêu Cuối Kiếm — 16 Linh Kiếm Từ Trời Giáng Xuyên Giáp!",
		"color": Color(0.38, 0.96, 0.88),
		"desc": "Triệu hồi 16 thanh Linh Kiếm khổng lồ lơ lửng trên không rồi phóng cắm liên hoàn xuống đầu toàn bộ kẻ địch, gây sát thương chí mạng diện rộng & phá giáp!",
	},
	"saber": {
		"name": "BÁ VƯƠNG PHÁ THIÊN TRẢM",
		"subtitle": "Chiêu Cuối Đại Đao — 3 Đợt Đao Khí Hỏa Viêm Chẻ Đất!",
		"color": Color(1.0, 0.44, 0.16),
		"desc": "Vung đại đao chém ra 3 luồng Đao Khí Bán Nguyệt khổng lồ càn quét 13m phía trước kèm chuỗi nổ dung nham, hất văng quái & phá tan 3 tầng Khiên Giáp!",
	},
	"bow": {
		"name": "CỬU THIÊN HỎA VŨ TIỄN",
		"subtitle": "Chiêu Cuối Cung Tên — Mưa 24 Thần Tiễn Phượng Hoàng Rực Lửa!",
		"color": Color(1.0, 0.72, 0.24),
		"desc": "Bắn tiễn lên chín tầng mây gọi xuống cơn mưa 24 mũi Thần Tiễn rực lửa oanh tạc liên hoàn khắp chiến trường phía trước với sát thương chí mạng!",
	},
	"staff": {
		"name": "THÁI CỰC THIÊN LÔI TRẬN",
		"subtitle": "Chiêu Cuối Gậy Phép — Đại Pháp Trận Hút Quái & 9 Cột Thiên Lôi!",
		"color": Color(0.76, 0.48, 1.0),
		"desc": "Khắc Đại Pháp Trận Bát Quái 3D khổng lồ hút kẻ địch vào tâm, liên tiếp giáng 9 cột Thiên Lôi Tinh Quang rồi kích nổ Siêu Tân Tinh!",
	},
}

## Các vật phẩm tiêu hao cất trong Rương Đồ (có thể nhặt từ quái hoặc mua ở Thương Nhân)
const ITEM_CATALOG: Dictionary = {
	"hp_potion": {"name": "Hồi Xuân Đan", "price": 25, "desc": "Hồi ngay +75 Sinh Lực (HP)"},
	"mp_potion": {"name": "Tụ Khí Tán", "price": 25, "desc": "Hồi ngay +65 Chân Khí (MP)"},
	"elixir_power": {"name": "Long Hổ Thần Đan", "price": 55, "desc": "Hồi đầy 100% Sinh Lực & Chân Khí + Tạo Khiên 4s"},
}

## ============================================================================
## KHO 10 SKIN ANIME CHIBI ĐẶC SẮC CHUẨN ẢNH MẪU:
## 5 Skin Thường (mặc bình thường + dáng tóc/phụ kiện & nhịp animation riêng):
##   1. Kiếm Khách (mặc định — Chiến Giáp Huyền Bí)   2. Tiên Nhân   3. Ninja   4. Miko   5. Vocaloid
## 5 Skin Hiếm / Sử Thi / Huyền Thoại (có Hiệu Ứng Hào Quang 3D + Kỹ năng đặc trưng riêng!):
##   6. Hồ Ly (Hiếm ★)   7. Ma Nữ (Hiếm ★)   8. Ác Ma (Sử Thi ★★)   9. Thiên Sứ (Sử Thi ★★)   10. Hoàng Đế (Huyền Thoại ★★★)
## ============================================================================
const SKIN_CATALOG: Dictionary = {
	"skin_default": {
		"name": "Kiếm Khách", "rarity": "Thường", "tier": "common", "has_vfx": false,
		"tag_color": Color(0.95, 0.36, 0.30), "vfx_color": Color(1.0, 0.28, 0.18), "skill_vfx": "crimson_arc",
		"hair_d": Color(0.08, 0.07, 0.11), "hair_m": Color(0.15, 0.13, 0.20), "hair_h": Color(0.32, 0.28, 0.40),
		"robe": Color(0.96, 0.94, 0.92), "coat_d": Color(0.14, 0.11, 0.16), "coat_m": Color(0.84, 0.16, 0.18),
		"eye": Color(0.95, 0.18, 0.20), "desc": "Chiến Giáp Huyền Bí — Tóc đen xoăn, mắt đỏ, dải lụa đỏ & kiếm lửa rực cháy.",
	},
	"skin_immortal": {
		"name": "Tiên Nhân", "rarity": "Thường", "tier": "common", "has_vfx": false,
		"tag_color": Color(0.45, 0.78, 1.0), "vfx_color": Color(0.28, 0.68, 1.0), "skill_vfx": "azure_dragon",
		"hair_d": Color(0.08, 0.10, 0.18), "hair_m": Color(0.16, 0.20, 0.32), "hair_h": Color(0.36, 0.45, 0.66),
		"robe": Color(0.94, 0.97, 1.0), "coat_d": Color(0.12, 0.28, 0.56), "coat_m": Color(0.24, 0.54, 0.90),
		"eye": Color(0.30, 0.76, 1.0), "desc": "Tiên Nhân đạo bào trắng lam thanh thoát, tóc buộc cao bay nhẹ trong gió.",
	},
	"skin_ninja": {
		"name": "Ninja", "rarity": "Thường", "tier": "common", "has_vfx": false,
		"tag_color": Color(1.0, 0.62, 0.18), "vfx_color": Color(1.0, 0.52, 0.12), "skill_vfx": "crimson_arc",
		"hair_d": Color(0.76, 0.52, 0.10), "hair_m": Color(0.98, 0.80, 0.22), "hair_h": Color(1.0, 0.94, 0.52),
		"robe": Color(0.16, 0.16, 0.22), "coat_d": Color(0.78, 0.34, 0.08), "coat_m": Color(0.98, 0.52, 0.14),
		"eye": Color(0.22, 0.72, 1.0), "desc": "Nhẫn Giả tóc vàng dựng, băng trán thép, áo khoác cam đen tốc độ siêu nhanh.",
	},
	"skin_miko": {
		"name": "Miko", "rarity": "Thường", "tier": "common", "has_vfx": false,
		"tag_color": Color(1.0, 0.44, 0.48), "vfx_color": Color(1.0, 0.36, 0.42), "skill_vfx": "crimson_arc",
		"hair_d": Color(0.14, 0.08, 0.10), "hair_m": Color(0.24, 0.14, 0.16), "hair_h": Color(0.46, 0.28, 0.32),
		"robe": Color(0.98, 0.96, 0.95), "coat_d": Color(0.68, 0.10, 0.16), "coat_m": Color(0.92, 0.20, 0.26),
		"eye": Color(0.92, 0.24, 0.30), "desc": "Vu Nữ Thần Xã áo trắng hakama đỏ, đeo mặt nạ cáo Kitsune bên mái tóc.",
	},
	"skin_vocaloid": {
		"name": "Vocaloid", "rarity": "Thường", "tier": "common", "has_vfx": false,
		"tag_color": Color(0.32, 0.94, 0.96), "vfx_color": Color(0.28, 0.92, 1.0), "skill_vfx": "azure_dragon",
		"hair_d": Color(0.10, 0.56, 0.64), "hair_m": Color(0.24, 0.86, 0.90), "hair_h": Color(0.66, 0.98, 1.0),
		"robe": Color(0.92, 0.97, 1.0), "coat_d": Color(0.16, 0.20, 0.28), "coat_m": Color(0.22, 0.76, 0.86),
		"eye": Color(0.22, 0.90, 0.95), "desc": "Ca Sĩ Ảo tóc 2 bím dài xanh ngọc bồng bềnh nhún nhảy theo nhịp chạy.",
	},

	# --- 5 SKIN HIẾM / SỬ THI / HUYỀN THOẠI (CÓ HIỆU ỨNG HÀO QUANG 3D + KỸ NĂNG ĐẶC BIỆT!) ---
	"skin_fox": {
		"name": "Hồ Ly", "rarity": "Hiếm ★", "tier": "rare", "has_vfx": true,
		"tag_color": Color(0.48, 0.88, 1.0), "vfx_color": Color(0.35, 0.82, 1.0), "skill_vfx": "azure_dragon",
		"hair_d": Color(0.62, 0.68, 0.82), "hair_m": Color(0.92, 0.95, 1.0), "hair_h": Color(1.0, 1.0, 1.0),
		"robe": Color(0.96, 0.98, 1.0), "coat_d": Color(0.18, 0.38, 0.72), "coat_m": Color(0.36, 0.66, 0.96),
		"eye": Color(0.32, 0.78, 1.0), "desc": "[HIỆU ỨNG] Cửu Vĩ Bạch Hồ có tai cáo & đuôi bông vẫy thật + Hào quang lam tuyết!",
	},
	"skin_witch": {
		"name": "Ma Nữ", "rarity": "Hiếm ★", "tier": "rare", "has_vfx": true,
		"tag_color": Color(0.78, 0.44, 1.0), "vfx_color": Color(0.76, 0.34, 1.0), "skill_vfx": "purple_butterflies",
		"hair_d": Color(0.16, 0.08, 0.28), "hair_m": Color(0.34, 0.18, 0.58), "hair_h": Color(0.64, 0.42, 0.90),
		"robe": Color(0.24, 0.12, 0.38), "coat_d": Color(0.38, 0.14, 0.64), "coat_m": Color(0.66, 0.30, 0.96),
		"eye": Color(0.86, 0.42, 1.0), "desc": "[HIỆU ỨNG] Ma Nữ Bướm Tím tỏa đàn bướm huyền ảo & kỹ năng Vòng Bướm Tím!",
	},
	"skin_demon": {
		"name": "Ác Ma", "rarity": "Sử Thi ★★", "tier": "epic", "has_vfx": true,
		"tag_color": Color(0.98, 0.24, 0.36), "vfx_color": Color(0.98, 0.18, 0.32), "skill_vfx": "crimson_arc",
		"hair_d": Color(0.56, 0.56, 0.64), "hair_m": Color(0.86, 0.88, 0.94), "hair_h": Color(1.0, 1.0, 1.0),
		"robe": Color(0.14, 0.09, 0.15), "coat_d": Color(0.34, 0.06, 0.12), "coat_m": Color(0.84, 0.12, 0.24),
		"eye": Color(1.0, 0.20, 0.28), "desc": "[HIỆU ỨNG] Chúa Tể Ác Ma tóc bạc, đôi cánh dơi vỗ nhịp & sóng hắc viêm đỏ rực!",
	},
	"skin_angel": {
		"name": "Thiên Sứ", "rarity": "Sử Thi ★★", "tier": "epic", "has_vfx": true,
		"tag_color": Color(1.0, 0.92, 0.62), "vfx_color": Color(1.0, 0.92, 0.56), "skill_vfx": "golden_pillars",
		"hair_d": Color(0.68, 0.72, 0.84), "hair_m": Color(0.94, 0.96, 1.0), "hair_h": Color(1.0, 1.0, 1.0),
		"robe": Color(1.0, 0.99, 0.95), "coat_d": Color(0.82, 0.66, 0.26), "coat_m": Color(1.0, 0.88, 0.44),
		"eye": Color(0.46, 0.84, 1.0), "desc": "[HIỆU ỨNG] Thiên Sứ có Vòng Hào Quang trên đầu, đôi cánh trắng vỗ bay & Cột Sáng Thánh!",
	},
	"skin_emperor": {
		"name": "Hoàng Đế", "rarity": "Huyền Thoại ★★★", "tier": "legendary", "has_vfx": true,
		"tag_color": Color(1.0, 0.82, 0.22), "vfx_color": Color(1.0, 0.82, 0.22), "skill_vfx": "golden_pillars",
		"hair_d": Color(0.08, 0.07, 0.10), "hair_m": Color(0.16, 0.14, 0.20), "hair_h": Color(0.36, 0.30, 0.24),
		"robe": Color(0.12, 0.10, 0.14), "coat_d": Color(0.68, 0.46, 0.08), "coat_m": Color(1.0, 0.80, 0.20),
		"eye": Color(1.0, 0.84, 0.22), "desc": "[HIỆU ỨNG TỐI THƯỢNG] Hoàng Đế Long Bào đen vàng, vương miện & Kim Long uốn lượn + Thiên Trụ Hoàng Kim!",
	},
}

const GACHA_COST_SINGLE := 40
const GACHA_COST_MULTI := 180 # Quay 5 lần (giảm giá + chắc chắn ra ít nhất 1 Skin Hiếm có hiệu ứng!)
const PET_GACHA_COST := 50    # Quay Gacha Linh Thú (Cơ hội nhận Tiểu Thanh Long ★★ & Phượng Hoàng Lửa ★★★!)

## ============================================================================
## KHO 4 LINH THÚ ĐỒNG HÀNH — CÓ TIẾN HÓA CẤP 1 -> 2 -> 3 & KỸ NĂNG CHỦ ĐỘNG [F / V]!
## ============================================================================
const PET_CATALOG: Dictionary = {
	"fox": {
		"name": "Tiểu Hồ Ly", "rarity": "Hiếm ★", "tier": "rare",
		"color": Color(1.0, 0.56, 0.76), "default_owned": true,
		"evo_names": ["Tiểu Hồ Ly", "Tam Vĩ Linh Hồ", "Cửu Vĩ Thiên Hồ"],
		"skill_name": "Hồ Ly Hộ Thuẫn",
		"skill_desc": "Tạo Khiên Hộ Thân 5s + Hồi HP & phóng 3 cầu hồ hỏa truy đuổi!",
		"dmg_mult": [0.68, 1.00, 1.42],
		"bolt_cd": [2.25, 1.80, 1.40],
	},
	"crane": {
		"name": "Tiên Hạc", "rarity": "Hiếm ★", "tier": "rare",
		"color": Color(0.38, 0.96, 0.88), "default_owned": true,
		"evo_names": ["Tiên Hạc Trắng", "Bích Ngọc Linh Hạc", "Cửu Thiên Thần Hạc"],
		"skill_name": "Tiên Vũ Hồi Xuân",
		"skill_desc": "Hồi ngay +35% Sinh Lực, +35 Chân Khí & tung sóng gió đẩy lùi quái!",
		"dmg_mult": [0.70, 1.02, 1.45],
		"bolt_cd": [2.10, 1.65, 1.30],
	},
	"dragon": {
		"name": "Tiểu Thanh Long", "rarity": "Sử Thi ★★", "tier": "epic",
		"color": Color(0.30, 0.84, 1.0), "default_owned": false,
		"evo_names": ["Tiểu Thanh Long", "Bích Lôi Giao Long", "Thiên Long Băng Vương"],
		"skill_name": "Long Tức Băng Phong",
		"skill_desc": "Phóng 5 tia Long Tức Băng Lam nổ lan, làm chậm quái & phá Khiên Giáp!",
		"dmg_mult": [0.88, 1.30, 1.82],
		"bolt_cd": [1.90, 1.50, 1.15],
	},
	"phoenix": {
		"name": "Phượng Hoàng Lửa", "rarity": "Huyền Thoại ★★★", "tier": "legendary",
		"color": Color(1.0, 0.54, 0.16), "default_owned": false,
		"evo_names": ["Tiểu Hỏa Phượng", "Xích Diệm Loan Phượng", "Bất Tử Chu Tước"],
		"skill_name": "Niết Bàn Hỏa Vũ",
		"skill_desc": "Bùng nổ vòng lửa Phượng Hoàng 360° + Hồi 25% HP! [Nội tại: Hồi sinh 1 lần/màn!]",
		"dmg_mult": [0.98, 1.45, 2.05],
		"bolt_cd": [1.80, 1.40, 1.10],
	},
}

## 4 nhiệm vụ phụ dân làng trên Bảng Truy Nã (Bounty Board)
const QUEST_DEFINITIONS: Dictionary = {
	"goblin_slayer": {
		"title": "Diệt Trừ Yêu Ma (Vô Thương)",
		"desc": "Tiêu diệt 15 Goblin Trinh Sát liên tiếp mà không bị mất máu",
		"target": 15,
		"gold": 120,
		"unlock_title": "Vô Ảnh Kiếm Khách",
		"unlock_scarf": "crimson",
		"scarf_label": "Khăn Chu Sa Đỏ Rực",
	},
	"treasure_hunter": {
		"title": "Tầm Bảo Trong Làng Cổ",
		"desc": "Bước vào bên trong 3 ngôi nhà gỗ ở Làng Windferry và mở đủ 3 Rương Báu",
		"target": 3,
		"gold": 100,
		"unlock_title": "Thiên Hạ Tầm Bảo",
		"unlock_scarf": "gold",
		"scarf_label": "Khăn Hoàng Kim Đế Vương",
	},
	"river_tactician": {
		"title": "Thủy Chiến Làng Cổ",
		"desc": "Đánh bay 5 kẻ địch rơi xuống suối nước / hồ nước bằng đòn đẩy lùi",
		"target": 5,
		"gold": 150,
		"unlock_title": "Bích Thủy Quân Sư",
		"unlock_scarf": "jade",
		"scarf_label": "Khăn Ngọc Bích Thần Phong",
	},
	"crate_breaker": {
		"title": "Thu Dọn Đường Phố",
		"desc": "Chém vỡ 10 thùng rượu gỗ hoặc hòm hàng ven đường",
		"target": 10,
		"gold": 80,
		"unlock_title": "Hiệp Sĩ Phong Trần",
		"unlock_scarf": "purple",
		"scarf_label": "Khăn Tử Vi Huyền Ảo",
	},
}

## Bảng màu các loại Khăn Choàng mở khóa cho nhân vật chính
const SCARF_PALETTES: Dictionary = {
	"blue": {"name": "Khăn Lam Cổ Điển", "dark": Color(0.10, 0.34, 0.48), "mid": Color(0.18, 0.52, 0.68), "hi": Color(0.38, 0.74, 0.86)},
	"crimson": {"name": "Khăn Chu Sa Đỏ Rực", "dark": Color(0.48, 0.08, 0.10), "mid": Color(0.82, 0.16, 0.18), "hi": Color(1.0, 0.46, 0.38)},
	"gold": {"name": "Khăn Hoàng Kim", "dark": Color(0.56, 0.38, 0.08), "mid": Color(0.92, 0.72, 0.18), "hi": Color(1.0, 0.92, 0.52)},
	"jade": {"name": "Khăn Ngọc Bích", "dark": Color(0.08, 0.40, 0.32), "mid": Color(0.16, 0.72, 0.56), "hi": Color(0.48, 0.96, 0.80)},
	"purple": {"name": "Khăn Tử Vi Huyền Ảo", "dark": Color(0.30, 0.12, 0.46), "mid": Color(0.58, 0.24, 0.82), "hi": Color(0.84, 0.56, 1.0)},
}

var unlocked_stage: int = 1
var gold: int = 0
var upgrades: Dictionary = {
	"attack": 0, # Mỗi cấp +4 sát thương
	"max_hp": 0, # Mỗi cấp +25 máu tối đa
	"speed": 0,  # Mỗi cấp +0.45 tốc độ di chuyển
}
var stage_records: Dictionary = {} # stage_id -> { "rank": "S", "score": 1200, "time": 45.2 }

# Dữ liệu Nhiệm vụ & Trang bị ngoại hình (Danh hiệu + Màu khăn choàng)
var quest_progress: Dictionary = {
	"goblin_slayer": 0,
	"treasure_hunter": 0,
	"river_tactician": 0,
	"crate_breaker": 0,
}
var quest_claimed: Dictionary = {}
var unlocked_titles: Array = ["Lữ Khách Windferry"]
var equipped_title: String = "Lữ Khách Windferry"
var unlocked_scarves: Array = ["blue"]
var equipped_scarf: String = "blue"
var equipped_pet: String = "fox" # "fox" | "crane" | "dragon" | "phoenix"
var owned_pets: Array = ["fox", "crane"]
var pet_levels: Dictionary = {"fox": 1, "crane": 1, "dragon": 1, "phoenix": 1}
var demon_souls: int = 3 # Hồn Yêu rơi từ Boss/Tank dùng để Tiến Hóa Linh Thú!
var pet_gacha_pity: int = 0 # Bảo hiểm: Quay 4 lần chắc chắn nổ Rồng hoặc Phượng Hoàng!
var owned_skins: Array = ["skin_default"]
var equipped_skin: String = "skin_default"
var gacha_pity: int = 0 # Bảo hiểm: Quay đủ 5 lần chắc chắn nổ Skin Hiếm trở lên!

# Rương đồ (Inventory): Danh sách vũ khí sở hữu + vũ khí đang trang bị + vật phẩm tiêu hao
var owned_weapons: Array = ["sword_basic"]
var equipped_weapon: String = "sword_basic"
var bag_items: Dictionary = {
	"hp_potion": 2,
	"mp_potion": 1,
	"elixir_power": 0,
}


func _ready() -> void:
	load_game()


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_stage", unlocked_stage)
	cfg.set_value("progress", "gold", gold)
	cfg.set_value("upgrades", "attack", upgrades.get("attack", 0))
	cfg.set_value("upgrades", "max_hp", upgrades.get("max_hp", 0))
	cfg.set_value("upgrades", "speed", upgrades.get("speed", 0))
	cfg.set_value("records", "stage_records", stage_records)
	cfg.set_value("quests", "progress", quest_progress)
	cfg.set_value("quests", "claimed", quest_claimed)
	cfg.set_value("cosmetics", "unlocked_titles", unlocked_titles)
	cfg.set_value("cosmetics", "equipped_title", equipped_title)
	cfg.set_value("cosmetics", "unlocked_scarves", unlocked_scarves)
	cfg.set_value("cosmetics", "equipped_scarf", equipped_scarf)
	cfg.set_value("cosmetics", "equipped_pet", equipped_pet)
	cfg.set_value("cosmetics", "owned_pets", owned_pets)
	cfg.set_value("cosmetics", "pet_levels", pet_levels)
	cfg.set_value("cosmetics", "demon_souls", demon_souls)
	cfg.set_value("cosmetics", "pet_gacha_pity", pet_gacha_pity)
	cfg.set_value("cosmetics", "owned_skins", owned_skins)
	cfg.set_value("cosmetics", "equipped_skin", equipped_skin)
	cfg.set_value("cosmetics", "gacha_pity", gacha_pity)
	cfg.set_value("inventory", "owned_weapons", owned_weapons)
	cfg.set_value("inventory", "equipped_weapon", equipped_weapon)
	cfg.set_value("inventory", "bag_items", bag_items)
	cfg.save(SAVE_PATH)
	data_changed.emit()


func load_game() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return
	unlocked_stage = int(cfg.get_value("progress", "unlocked_stage", 1))
	gold = int(cfg.get_value("progress", "gold", 0))
	upgrades["attack"] = int(cfg.get_value("upgrades", "attack", 0))
	upgrades["max_hp"] = int(cfg.get_value("upgrades", "max_hp", 0))
	upgrades["speed"] = int(cfg.get_value("upgrades", "speed", 0))
	stage_records = cfg.get_value("records", "stage_records", {})
	var saved_q: Dictionary = cfg.get_value("quests", "progress", {})
	for qk in quest_progress.keys():
		if saved_q.has(qk):
			quest_progress[qk] = int(saved_q[qk])
	quest_claimed = cfg.get_value("quests", "claimed", {})
	unlocked_titles = cfg.get_value("cosmetics", "unlocked_titles", ["Lữ Khách Windferry"])
	equipped_title = str(cfg.get_value("cosmetics", "equipped_title", "Lữ Khách Windferry"))
	unlocked_scarves = cfg.get_value("cosmetics", "unlocked_scarves", ["blue"])
	equipped_scarf = str(cfg.get_value("cosmetics", "equipped_scarf", "blue"))
	equipped_pet = str(cfg.get_value("cosmetics", "equipped_pet", "fox"))
	var raw_pets: Array = cfg.get_value("cosmetics", "owned_pets", ["fox", "crane"])
	owned_pets = []
	for pid_v in raw_pets:
		var pid: String = str(pid_v)
		if PET_CATALOG.has(pid) and not owned_pets.has(pid):
			owned_pets.append(pid)
	for def_p: String in ["fox", "crane"]:
		if not owned_pets.has(def_p):
			owned_pets.append(def_p)
	if not owned_pets.has(equipped_pet):
		equipped_pet = "fox"
	var saved_plv: Dictionary = cfg.get_value("cosmetics", "pet_levels", {})
	for pk in pet_levels.keys():
		if saved_plv.has(pk):
			pet_levels[pk] = clampi(int(saved_plv[pk]), 1, 3)
	demon_souls = maxi(0, int(cfg.get_value("cosmetics", "demon_souls", 3)))
	pet_gacha_pity = int(cfg.get_value("cosmetics", "pet_gacha_pity", 0))
	var raw_skins: Array = cfg.get_value("cosmetics", "owned_skins", ["skin_default"])
	owned_skins = []
	for sid_v in raw_skins:
		var sid: String = str(sid_v)
		if SKIN_CATALOG.has(sid) and not owned_skins.has(sid):
			owned_skins.append(sid)
	if not owned_skins.has("skin_default"):
		owned_skins.insert(0, "skin_default")
	equipped_skin = str(cfg.get_value("cosmetics", "equipped_skin", "skin_default"))
	if not SKIN_CATALOG.has(equipped_skin):
		equipped_skin = "skin_default"
	gacha_pity = int(cfg.get_value("cosmetics", "gacha_pity", 0))
	owned_weapons = cfg.get_value("inventory", "owned_weapons", ["sword_basic"])
	equipped_weapon = str(cfg.get_value("inventory", "equipped_weapon", "sword_basic"))
	if not WEAPON_CATALOG.has(equipped_weapon):
		equipped_weapon = "sword_basic"
	var saved_bag: Dictionary = cfg.get_value("inventory", "bag_items", {})
	for ik in bag_items.keys():
		if saved_bag.has(ik):
			bag_items[ik] = int(saved_bag[ik])
	data_changed.emit()


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	save_game()


func record_stage_clear(stage_id: int, score: int, clear_time: float, rank: String, max_stages: int = 5) -> void:
	if stage_id >= unlocked_stage and stage_id < max_stages:
		unlocked_stage = stage_id + 1
	var key := str(stage_id)
	var prev: Dictionary = stage_records.get(key, {})
	var prev_score: int = int(prev.get("score", -1))
	if score > prev_score:
		stage_records[key] = {
			"rank": rank,
			"score": score,
			"time": clear_time,
		}
	save_game()


## Cập nhật tiến độ nhiệm vụ phụ trên Bảng Truy Nã
func advance_quest(quest_id: String, delta: int = 1) -> void:
	if not QUEST_DEFINITIONS.has(quest_id) or bool(quest_claimed.get(quest_id, false)):
		return
	var target: int = int(QUEST_DEFINITIONS[quest_id]["target"])
	var prev_val: int = int(quest_progress.get(quest_id, 0))
	var new_val := mini(target, prev_val + delta)
	if new_val != prev_val:
		quest_progress[quest_id] = new_val
		save_game()
		if prev_val < target and new_val >= target:
			var qd: Dictionary = QUEST_DEFINITIONS[quest_id]
			quest_completed_notify.emit(str(qd["title"]), "Về Bảng Truy Nã Làng Windferry để lĩnh thưởng!")


## Reset chuỗi không mất máu cho nhiệm vụ Diệt 15 Goblin vô thương (nếu chưa xong)
func reset_no_damage_goblin_streak() -> void:
	if bool(quest_claimed.get("goblin_slayer", false)):
		return
	var target: int = int(QUEST_DEFINITIONS["goblin_slayer"]["target"])
	var cur: int = int(quest_progress.get("goblin_slayer", 0))
	if cur > 0 and cur < target:
		quest_progress["goblin_slayer"] = 0
		save_game()


## Nhận thưởng nhiệm vụ trên Bảng Truy Nã (Vàng + Mở khóa Danh hiệu + Màu khăn choàng mới)
func claim_quest_reward(quest_id: String) -> bool:
	if not QUEST_DEFINITIONS.has(quest_id) or bool(quest_claimed.get(quest_id, false)):
		return false
	var qd: Dictionary = QUEST_DEFINITIONS[quest_id]
	if int(quest_progress.get(quest_id, 0)) < int(qd["target"]):
		return false

	quest_claimed[quest_id] = true
	gold += int(qd["gold"])
	var new_title := str(qd["unlock_title"])
	if not unlocked_titles.has(new_title):
		unlocked_titles.append(new_title)
	equipped_title = new_title

	var new_scarf := str(qd["unlock_scarf"])
	if not unlocked_scarves.has(new_scarf):
		unlocked_scarves.append(new_scarf)
	equipped_scarf = new_scarf

	save_game()
	cosmetic_changed.emit()
	return true


func equip_scarf(scarf_id: String) -> void:
	if unlocked_scarves.has(scarf_id):
		equipped_scarf = scarf_id
		save_game()
		cosmetic_changed.emit()


func get_equipped_skin_data() -> Dictionary:
	return SKIN_CATALOG.get(equipped_skin, SKIN_CATALOG["skin_default"])


func equip_skin(skin_id: String) -> void:
	if owned_skins.has(skin_id) and SKIN_CATALOG.has(skin_id):
		equipped_skin = skin_id
		save_game()
		cosmetic_changed.emit()


## Quay Gacha Trang Phục (count = 1 hoặc 5):
## Tỉ lệ: 52% Thường | 28% Hiếm ★ | 14% Sử Thi ★★ | 6% Huyền Thoại ★★★ (có bảo hiểm Pity mỗi 5 lần chắc chắn nổ Skin có VFX!)
## Nếu quay trúng Skin đã sở hữu -> hoàn lại Ngân Lượng (15 Lượng skin thường / 45 Lượng skin hiếm)!
func roll_skin_gacha(count: int = 1) -> Array[Dictionary]:
	var cost: int = GACHA_COST_SINGLE if count == 1 else GACHA_COST_MULTI
	if gold < cost:
		return []
	gold -= cost

	var common_pool: Array[String] = ["skin_default", "skin_immortal", "skin_ninja", "skin_miko", "skin_vocaloid"]
	var rare_pool: Array[String] = ["skin_fox", "skin_witch"]
	var epic_pool: Array[String] = ["skin_demon", "skin_angel"]
	var legend_pool: Array[String] = ["skin_emperor"]

	var results: Array[Dictionary] = []
	var guaranteed_vfx_given := false

	for i in range(count):
		gacha_pity += 1
		var chosen_id: String = "skin_immortal"
		var force_high: bool = (gacha_pity >= 5) or (count >= 5 and i == count - 1 and not guaranteed_vfx_given)

		var r := randf()
		if force_high:
			if r < 0.18:
				chosen_id = legend_pool[0]
			elif r < 0.52:
				chosen_id = epic_pool[randi() % epic_pool.size()]
			else:
				chosen_id = rare_pool[randi() % rare_pool.size()]
		else:
			if r < 0.06:
				chosen_id = legend_pool[0]
			elif r < 0.20:
				chosen_id = epic_pool[randi() % epic_pool.size()]
			elif r < 0.48:
				chosen_id = rare_pool[randi() % rare_pool.size()]
			else:
				chosen_id = common_pool[randi() % common_pool.size()]

		var sdata: Dictionary = SKIN_CATALOG[chosen_id]
		if bool(sdata["has_vfx"]):
			gacha_pity = 0
			guaranteed_vfx_given = true

		var is_new: bool = not owned_skins.has(chosen_id)
		var refund: int = 0
		if is_new:
			owned_skins.append(chosen_id)
		else:
			refund = 45 if bool(sdata["has_vfx"]) else 15
			gold += refund

		results.append({
			"id": chosen_id,
			"name": str(sdata["name"]),
			"rarity": str(sdata["rarity"]),
			"has_vfx": bool(sdata["has_vfx"]),
			"tag_color": sdata["tag_color"],
			"is_new": is_new,
			"refund": refund,
		})

	save_game()
	cosmetic_changed.emit()
	return results


func equip_pet(pet_id: String) -> void:
	if owned_pets.has(pet_id) and PET_CATALOG.has(pet_id):
		equipped_pet = pet_id
		save_game()
		cosmetic_changed.emit()


func add_demon_souls(amount: int) -> void:
	demon_souls = maxi(0, demon_souls + amount)
	save_game()


func get_pet_level(pet_id: String) -> int:
	return clampi(int(pet_levels.get(pet_id, 1)), 1, 3)


func get_pet_display_name(pet_id: String) -> String:
	var pd: Dictionary = PET_CATALOG.get(pet_id, PET_CATALOG["fox"])
	var names: Array = pd.get("evo_names", ["Linh Thú"])
	var lv_idx: int = clampi(get_pet_level(pet_id) - 1, 0, names.size() - 1)
	return str(names[lv_idx])


func get_pet_evolve_costs(pet_id: String) -> Dictionary:
	var lv: int = get_pet_level(pet_id)
	if lv >= 3:
		return {"maxed": true, "gold": 0, "souls": 0}
	return {"maxed": false, "gold": 80 if lv == 1 else 160, "souls": 3 if lv == 1 else 6}


## Tiến hóa Linh Thú từ Cấp 1 -> Cấp 2 -> Cấp 3 bằng Vàng HOẶC Hồn Yêu rơi từ Boss!
func evolve_pet(pet_id: String, use_souls: bool = false) -> bool:
	if not owned_pets.has(pet_id) or not PET_CATALOG.has(pet_id):
		return false
	var cur_lv: int = get_pet_level(pet_id)
	if cur_lv >= 3:
		return false
	var costs: Dictionary = get_pet_evolve_costs(pet_id)
	if use_souls:
		var sc: int = int(costs["souls"])
		if demon_souls < sc:
			return false
		demon_souls -= sc
	else:
		var gc: int = int(costs["gold"])
		if gold < gc:
			return false
		gold -= gc
	pet_levels[pet_id] = cur_lv + 1
	save_game()
	cosmetic_changed.emit()
	return true


## Quay Gacha Linh Thú (50 Lượng/lượt): Cơ hội nhận Tiểu Thanh Long ★★, Phượng Hoàng Lửa ★★★ hoặc Hồn Yêu Tiến Hóa!
func roll_pet_gacha() -> Dictionary:
	if gold < PET_GACHA_COST:
		return {}
	gold -= PET_GACHA_COST
	pet_gacha_pity += 1

	var unowned_rare: Array[String] = []
	for pid: String in ["dragon", "phoenix"]:
		if not owned_pets.has(pid):
			unowned_rare.append(pid)

	var force_pet: bool = (pet_gacha_pity >= 4)
	var r: float = randf()
	var result: Dictionary = {}

	if force_pet or r < 0.52:
		var chosen: String = "dragon"
		if force_pet and unowned_rare.size() > 0:
			chosen = unowned_rare[randi() % unowned_rare.size()]
		else:
			chosen = "phoenix" if (r < 0.20) else "dragon"
		pet_gacha_pity = 0
		var pd: Dictionary = PET_CATALOG[chosen]
		var is_new: bool = not owned_pets.has(chosen)
		var bonus_souls: int = 0
		if is_new:
			owned_pets.append(chosen)
			equipped_pet = chosen
		else:
			bonus_souls = 4 if chosen == "phoenix" else 3
			demon_souls += bonus_souls
		result = {
			"kind": "pet", "id": chosen, "name": str(pd["name"]),
			"rarity": str(pd["rarity"]), "color": pd["color"],
			"is_new": is_new, "bonus_souls": bonus_souls,
		}
	else:
		var gained_souls: int = 2 + (randi() % 3) # 2 - 4 Hồn Yêu
		demon_souls += gained_souls
		result = {
			"kind": "souls", "id": "demon_souls", "name": "Hồn Yêu Tiến Hóa x%d" % gained_souls,
			"rarity": "Nguyên Liệu Hiếm", "color": Color(0.76, 0.48, 1.0),
			"is_new": false, "bonus_souls": gained_souls,
		}

	save_game()
	cosmetic_changed.emit()
	return result


func equip_title(title_str: String) -> void:
	if unlocked_titles.has(title_str):
		equipped_title = title_str
		save_game()
		cosmetic_changed.emit()


func get_upgrade_cost(stat_key: String) -> int:
	var lv: int = int(upgrades.get(stat_key, 0))
	return 30 + lv * 25


func buy_upgrade(stat_key: String) -> bool:
	if not upgrades.has(stat_key):
		return false
	var cost := get_upgrade_cost(stat_key)
	if gold < cost:
		return false
	gold -= cost
	upgrades[stat_key] = int(upgrades[stat_key]) + 1
	save_game()
	return true


func get_equipped_weapon_data() -> Dictionary:
	return WEAPON_CATALOG.get(equipped_weapon, WEAPON_CATALOG["sword_basic"])


func get_equipped_weapon_type() -> String:
	return str(get_equipped_weapon_data().get("type", "sword"))


func get_equipped_weapon_ultimate() -> Dictionary:
	var wtype: String = get_equipped_weapon_type()
	return WEAPON_ULTIMATES.get(wtype, WEAPON_ULTIMATES["sword"])


## Thêm vũ khí vào Rương Đồ (khi nhặt từ quái hoặc mua từ Cửa hàng). Nếu đã có sẵn thì quy đổi thành Vàng!
func add_weapon_to_inventory(weapon_id: String) -> bool:
	if not WEAPON_CATALOG.has(weapon_id):
		return false
	if owned_weapons.has(weapon_id):
		return false
	owned_weapons.append(weapon_id)
	save_game()
	inventory_changed.emit()
	return true


func equip_weapon(weapon_id: String) -> void:
	if owned_weapons.has(weapon_id) and WEAPON_CATALOG.has(weapon_id):
		equipped_weapon = weapon_id
		save_game()
		inventory_changed.emit()
		cosmetic_changed.emit()


func buy_weapon(weapon_id: String) -> bool:
	if not WEAPON_CATALOG.has(weapon_id) or owned_weapons.has(weapon_id):
		return false
	var price: int = int(WEAPON_CATALOG[weapon_id]["price"])
	if gold < price:
		return false
	gold -= price
	owned_weapons.append(weapon_id)
	equipped_weapon = weapon_id
	save_game()
	inventory_changed.emit()
	cosmetic_changed.emit()
	return true


func add_bag_item(item_id: String, count: int = 1) -> void:
	if not ITEM_CATALOG.has(item_id):
		return
	bag_items[item_id] = int(bag_items.get(item_id, 0)) + count
	save_game()
	inventory_changed.emit()


func buy_bag_item(item_id: String) -> bool:
	if not ITEM_CATALOG.has(item_id):
		return false
	var price: int = int(ITEM_CATALOG[item_id]["price"])
	if gold < price:
		return false
	gold -= price
	bag_items[item_id] = int(bag_items.get(item_id, 0)) + 1
	save_game()
	inventory_changed.emit()
	return true


func consume_bag_item(item_id: String) -> bool:
	var cur: int = int(bag_items.get(item_id, 0))
	if cur <= 0:
		return false
	bag_items[item_id] = cur - 1
	save_game()
	inventory_changed.emit()
	return true


## Chọn ngẫu nhiên 1 vũ khí để rơi ra khi tiêu diệt quái / Boss
func pick_random_weapon_drop(stage_id: int, is_boss: bool = false) -> String:
	var pool: Array[String] = ["saber_iron", "bow_bamboo", "staff_jade"]
	if stage_id >= 3 or is_boss:
		pool.append("sword_jade")
	if stage_id >= 4 or is_boss:
		pool.append("saber_dragon")
		pool.append("bow_phoenix")
		pool.append("staff_celestial")
	# Ưu tiên rơi vũ khí người chơi chưa sở hữu
	var unowned: Array[String] = []
	for wid in pool:
		if not owned_weapons.has(wid):
			unowned.append(wid)
	if unowned.size() > 0:
		return unowned[randi() % unowned.size()]
	return pool[randi() % pool.size()]


func get_bonus_attack() -> float:
	return float(upgrades.get("attack", 0)) * 4.0 + float(get_equipped_weapon_data().get("dmg", 0.0))


func get_bonus_max_hp() -> float:
	return float(upgrades.get("max_hp", 0)) * 25.0


func get_bonus_speed() -> float:
	return float(upgrades.get("speed", 0)) * 0.45


func reset_save() -> void:
	unlocked_stage = 1
	gold = 0
	upgrades = {"attack": 0, "max_hp": 0, "speed": 0}
	stage_records = {}
	quest_progress = {"goblin_slayer": 0, "treasure_hunter": 0, "river_tactician": 0, "crate_breaker": 0}
	quest_claimed = {}
	unlocked_titles = ["Lữ Khách Windferry"]
	equipped_title = "Lữ Khách Windferry"
	unlocked_scarves = ["blue"]
	equipped_scarf = "blue"
	equipped_pet = "fox"
	owned_pets = ["fox", "crane"]
	pet_levels = {"fox": 1, "crane": 1, "dragon": 1, "phoenix": 1}
	demon_souls = 3
	pet_gacha_pity = 0
	owned_skins = ["skin_default"]
	equipped_skin = "skin_default"
	gacha_pity = 0
	owned_weapons = ["sword_basic"]
	equipped_weapon = "sword_basic"
	bag_items = {"hp_potion": 2, "mp_potion": 1, "elixir_power": 0}
	save_game()
	cosmetic_changed.emit()
	inventory_changed.emit()
