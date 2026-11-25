class_name EnemyStats
extends Resource
## Resource lưu thông số của 7 loại quái vật anime & 5 Boss Huyền Thoại (Mỗi màn 1 Boss riêng!).

@export var enemy_name: String = "Đạo Tặc"
@export var boss_subtitle: String = ""
@export_enum("melee", "ranged", "charger", "tank", "boss") var archetype: String = "melee"
@export var visual_id: String = "bandit" # slime | wolf | bandit | ghost | warrior | kitsune | golem | boss_kitsune | boss_dragon | boss_darklord | boss_archmage | boss_emperor
@export var max_hp: float = 55.0
@export var move_speed: float = 3.4
@export var attack_damage: float = 14.0
@export var attack_range: float = 1.65
@export var attack_cooldown: float = 1.25
@export var detection_range: float = 18.0
@export var knockback_resistance: float = 0.0
@export var shield_points: int = 0
@export var score_value: int = 100
@export var gold_drop: int = 8
@export var sprite_tint: Color = Color.WHITE
@export var aura_color: Color = Color(0.56, 0.80, 1.0)
@export var projectile_color: Color = Color(0.65, 0.30, 1.0)
@export var sprite_scale: float = 1.0
@export var custom_sprite_frames: SpriteFrames
