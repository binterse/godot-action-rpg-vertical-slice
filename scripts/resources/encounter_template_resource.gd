extends "res://scripts/resources/base_data_resource.gd"
class_name EncounterTemplateResource

@export var habitat: Resource
@export var difficulty: Resource
@export var allowed_enemy_ids: PackedStringArray = PackedStringArray()
@export var wave_count: int = 3
@export var base_wave_size: int = 3
@export var reward_credits: int = 100
@export var champion_chance: float = 0.0
@export var boss_enemy_id: String = ""
