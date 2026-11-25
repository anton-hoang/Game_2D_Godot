extends Node
## SaveManager (Autoload): Lưu và tải tiến trình người chơi bằng ConfigFile.
## Dữ liệu lưu tại user://save_data.cfg gồm: màn đã mở, vàng, cấp độ nâng cấp, kỷ lục điểm/hạng.

signal data_changed

const SAVE_PATH := "user://save_data.cfg"

var unlocked_stage: int = 1
var gold: int = 0
var upgrades: Dictionary = {
	"attack": 0, # Mỗi cấp +4 sát thương
	"max_hp": 0, # Mỗi cấp +25 máu tối đa
	"speed": 0,  # Mỗi cấp +0.45 tốc độ di chuyển
}
var stage_records: Dictionary = {} # stage_id -> { "rank": "S", "score": 1200, "time": 45.2 }


func _ready() -> void:
	load_game()


## Lưu toàn bộ tiến trình vào user://save_data.cfg
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_stage", unlocked_stage)
	cfg.set_value("progress", "gold", gold)
	cfg.set_value("upgrades", "attack", upgrades.get("attack", 0))
	cfg.set_value("upgrades", "max_hp", upgrades.get("max_hp", 0))
	cfg.set_value("upgrades", "speed", upgrades.get("speed", 0))
	cfg.set_value("records", "stage_records", stage_records)
	cfg.save(SAVE_PATH)
	data_changed.emit()


## Tải dữ liệu đã lưu (nếu chưa có file sẽ dùng giá trị mặc định)
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
	data_changed.emit()


## Cộng hoặc trừ vàng và tự động lưu
func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	save_game()


## Mở khóa màn chơi mới và lưu kỷ lục màn vừa qua
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


## Giá vàng cho mỗi lần nâng cấp tiếp theo
func get_upgrade_cost(stat_key: String) -> int:
	var lv: int = int(upgrades.get(stat_key, 0))
	return 30 + lv * 25


## Thực hiện mua nâng cấp bằng vàng
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


## Tính chỉ số cộng thêm cho Player
func get_bonus_attack() -> float:
	return float(upgrades.get("attack", 0)) * 4.0


func get_bonus_max_hp() -> float:
	return float(upgrades.get("max_hp", 0)) * 25.0


func get_bonus_speed() -> float:
	return float(upgrades.get("speed", 0)) * 0.45


## Xóa dữ liệu lưu để chơi lại từ đầu
func reset_save() -> void:
	unlocked_stage = 1
	gold = 0
	upgrades = {"attack": 0, "max_hp": 0, "speed": 0}
	stage_records = {}
	save_game()
