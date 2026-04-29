extends "res://scripts/resources/base_data_resource.gd"
class_name EnemyMutationResource

@export var category: String = "habitat"
@export var prefix: String = ""
@export var suffix: String = ""
@export var bonus_health: float = 1.0
@export var bonus_damage: float = 1.0
@export var bonus_speed: float = 1.0
@export var aggression_bonus: float = 1.0
@export var ailment_bonus: float = 1.0
@export var habitat_tags: PackedStringArray = PackedStringArray()
@export var palette_shift: Color = Color.WHITE
