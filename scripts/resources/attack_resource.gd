extends "res://scripts/resources/base_data_resource.gd"
class_name AttackResource

@export var style: String = "melee"
@export var element_id: String = ""
@export var base_damage: float = 10.0
@export var attack_range: float = 64.0
@export var cooldown: float = 0.6
@export var windup: float = 0.1
@export var projectile_speed: float = 0.0
@export var ailment_buildup: float = 12.0
@export var radius: float = 12.0
@export var knockback: float = 100.0
