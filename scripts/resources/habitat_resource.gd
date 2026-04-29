extends "res://scripts/resources/base_data_resource.gd"
class_name HabitatResource

@export var palette_primary: Color = Color.WHITE
@export var palette_secondary: Color = Color.GRAY
@export var ambient_color: Color = Color.BLACK
@export var hazard_element_id: String = ""
@export var hazard_ailment_id: String = ""
@export var hazard_damage: float = 0.0
@export var hazard_interval: float = 3.0
@export var spawn_bias_role: String = ""
@export var enemy_weight_bias: Dictionary = {}
