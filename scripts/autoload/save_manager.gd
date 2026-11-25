extends Node
## SaveManager (Autoload): Lưu và tải tiến trình người chơi bằng ConfigFile.
## Dữ liệu lưu tại user://save_data.cfg gồm:
## - Màn đã mở, vàng, nâng cấp, kỷ lục hạng S/A/B/C.
## - Nhiệm vụ Bảng Truy Nã (Quest Board): tiến độ, nhận thưởng, danh hiệu & màu khăn choàng mở khóa!

signal data_changed
signal quest_completed_notify(quest_title: String, reward_summary: String)
signal cosmetic_changed

const SAVE_PATH := "user://save_data.cfg"

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


func get_bonus_attack() -> float:
	return float(upgrades.get("attack", 0)) * 4.0


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
	save_game()
	cosmetic_changed.emit()
