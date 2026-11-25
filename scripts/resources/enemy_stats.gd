class_name EnemyStats
extends Resource
## Resource lưu thông số của từng loại quái vật (Cận chiến, Tầm xa, Lao tới, Tank, Boss).
## Có thể tạo file .tres trong res://resources/enemy_stats/ để chỉnh sửa trực tiếp trên Inspector.

@export var enemy_name: String = "Goblin Scout"
@export_enum("melee", "ranged", "charger", "tank", "boss") var archetype: String = "melee"
@export var max_hp: float = 55.0
@export var move_speed: float = 3.4
@export var attack_damage: float = 14.0
@export var attack_range: float = 1.65
@export var attack_cooldown: float = 1.25
@export var detection_range: float = 18.0
@export var knockback_resistance: float = 0.0 # 0.0 -> dễ bị đẩy lùi, 0.85 -> Tank/Boss khó bị đẩy
@export var score_value: int = 100
@export var gold_drop: int = 8
@export var sprite_tint: Color = Color.WHITE
@export var sprite_scale: float = 1.0
## PLACEHOLDER: Gán SpriteFrames thật của quái vào đây nếu không dùng PixelArtGenerator
@export var custom_sprite_frames: SpriteFrames
