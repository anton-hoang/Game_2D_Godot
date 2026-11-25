class_name StageData
extends Resource
## Resource StageData quản lý dữ liệu từng màn chơi (danh sách wave, loại quái, số lượng, thời điểm ánh sáng, nhạc).
## Để thêm màn mới, chỉ cần tạo file .tres mới trong res://resources/stage_data/ hoặc thêm vào StageDatabase.

@export var stage_id: int = 1
@export var stage_name: String = "Màn 1: Hoàng Hôn Làng Windferry"
@export var stage_subtitle: String = "Đội tuần tra Goblin xuất hiện ven suối"
@export_enum("golden_hour", "blue_night", "midnight", "rainy_night", "crimson_eclipse") var time_of_day: String = "golden_hour"
@export var target_clear_time: float = 85.0
## Danh sách các đợt quái (Wave). Mỗi phần tử là Dictionary dạng: {"melee": 3, "ranged": 1}
@export var waves: Array[Dictionary] = []
