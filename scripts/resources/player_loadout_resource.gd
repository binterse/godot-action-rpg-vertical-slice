extends "res://scripts/resources/base_data_resource.gd"
class_name PlayerLoadoutResource

@export var max_health: float = 180.0
@export var max_shield: float = 80.0
@export var move_speed: float = 260.0
@export var dodge_speed: float = 600.0
@export var dodge_duration: float = 0.25
@export var light_attack_id: String = ""
@export var heavy_attack_id: String = ""
@export var tech_attack_id: String = ""
@export var affinity_element_id: String = "thermal"
@export var status_resistance: float = 0.15
@export var shield_regen_delay: float = 3.0
