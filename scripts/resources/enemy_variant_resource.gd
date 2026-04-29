extends "res://scripts/resources/base_data_resource.gd"
class_name EnemyVariantResource

@export var family: Resource
@export var mutation: Resource
@export var role: String = ""
@export var element_id: String = ""
@export var ailment_id: String = ""
@export var base_health: float = 40.0
@export var base_shield: float = 0.0
@export var base_speed: float = 120.0
@export var base_damage: float = 10.0
@export var aggression: float = 1.0
@export var attack_ids: PackedStringArray = PackedStringArray()
@export var habitat_tags: PackedStringArray = PackedStringArray()
@export var palette_primary: Color = Color.WHITE
@export var palette_secondary: Color = Color.GRAY
@export var loot_ids: PackedStringArray = PackedStringArray()
@export var difficulty_bias: Dictionary = {}
