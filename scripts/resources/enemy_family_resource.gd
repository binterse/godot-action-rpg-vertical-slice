extends "res://scripts/resources/base_data_resource.gd"
class_name EnemyFamilyResource

@export var role: String = ""
@export var element_id: String = ""
@export var ailment_id: String = ""
@export var base_health: float = 40.0
@export var base_shield: float = 0.0
@export var base_speed: float = 120.0
@export var base_damage: float = 10.0
@export var aggression: float = 1.0
@export var default_attack_ids: PackedStringArray = PackedStringArray()
@export var palette_color: Color = Color.WHITE
