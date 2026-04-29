extends Node

const DATA_ROOT := "res://data"
const ELEMENT_SCRIPT := "res://scripts/resources/element_resource.gd"
const AILMENT_SCRIPT := "res://scripts/resources/status_ailment_resource.gd"
const DIFFICULTY_SCRIPT := "res://scripts/resources/difficulty_resource.gd"
const HABITAT_SCRIPT := "res://scripts/resources/habitat_resource.gd"
const ATTACK_SCRIPT := "res://scripts/resources/attack_resource.gd"
const FAMILY_SCRIPT := "res://scripts/resources/enemy_family_resource.gd"
const MUTATION_SCRIPT := "res://scripts/resources/enemy_mutation_resource.gd"
const VARIANT_SCRIPT := "res://scripts/resources/enemy_variant_resource.gd"
const ENCOUNTER_SCRIPT := "res://scripts/resources/encounter_template_resource.gd"
const PLAYER_LOADOUT_SCRIPT := "res://scripts/resources/player_loadout_resource.gd"
const LOOT_SCRIPT := "res://scripts/resources/loot_entry_resource.gd"
const UI_THEME_SCRIPT := "res://scripts/resources/ui_theme_resource.gd"

var elements: Dictionary = {}
var ailments: Dictionary = {}
var difficulties: Dictionary = {}
var habitats: Dictionary = {}
var attacks: Dictionary = {}
var enemy_families: Dictionary = {}
var enemy_mutations: Dictionary = {}
var enemy_variants: Dictionary = {}
var encounters: Dictionary = {}
var player_loadouts: Dictionary = {}
var loot_entries: Dictionary = {}
var ui_themes: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	elements.clear()
	ailments.clear()
	difficulties.clear()
	habitats.clear()
	attacks.clear()
	enemy_families.clear()
	enemy_mutations.clear()
	enemy_variants.clear()
	encounters.clear()
	player_loadouts.clear()
	loot_entries.clear()
	ui_themes.clear()
	_scan_dir(DATA_ROOT)

func _scan_dir(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name = dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full_path = path.path_join(name)
		if dir.current_is_dir():
			_scan_dir(full_path)
		elif name.ends_with(".tres") or name.ends_with(".res"):
			var resource = load(full_path)
			if resource:
				_register_resource(resource)
	dir.list_dir_end()

func _register_resource(resource: Resource) -> void:
	var script = resource.get_script()
	if script == null:
		return
	var script_path = String(script.resource_path)
	if script_path == ELEMENT_SCRIPT:
		elements[resource.id] = resource
	elif script_path == AILMENT_SCRIPT:
		ailments[resource.id] = resource
	elif script_path == DIFFICULTY_SCRIPT:
		difficulties[resource.id] = resource
	elif script_path == HABITAT_SCRIPT:
		habitats[resource.id] = resource
	elif script_path == ATTACK_SCRIPT:
		attacks[resource.id] = resource
	elif script_path == FAMILY_SCRIPT:
		enemy_families[resource.id] = resource
	elif script_path == MUTATION_SCRIPT:
		enemy_mutations[resource.id] = resource
	elif script_path == VARIANT_SCRIPT:
		enemy_variants[resource.id] = resource
	elif script_path == ENCOUNTER_SCRIPT:
		encounters[resource.id] = resource
	elif script_path == PLAYER_LOADOUT_SCRIPT:
		player_loadouts[resource.id] = resource
	elif script_path == LOOT_SCRIPT:
		loot_entries[resource.id] = resource
	elif script_path == UI_THEME_SCRIPT:
		ui_themes[resource.id] = resource

func get_element(id: String):
	return elements.get(id)

func get_ailment(id: String):
	return ailments.get(id)

func get_difficulty(id: String):
	return difficulties.get(id)

func get_habitat(id: String):
	return habitats.get(id)

func get_attack(id: String):
	return attacks.get(id)

func get_enemy_variant(id: String):
	return enemy_variants.get(id)

func get_encounter(id: String):
	return encounters.get(id)

func get_default_loadout():
	if player_loadouts.has("default_loadout"):
		return player_loadouts["default_loadout"]
	return null

func get_default_theme():
	if ui_themes.has("default_theme"):
		return ui_themes["default_theme"]
	return null

func sorted_values(source: Dictionary) -> Array:
	var keys = source.keys()
	keys.sort()
	var values: Array = []
	for key in keys:
		values.append(source[key])
	return values

func get_habitat_enemy_ids(habitat_id: String) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for enemy_id in enemy_variants.keys():
		var variant = enemy_variants[enemy_id]
		if variant and habitat_id in variant.habitat_tags:
			ids.append(enemy_id)
	return ids

func get_matching_encounter_ids(habitat_id: String, difficulty_id: String) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for encounter_id in encounters.keys():
		var encounter = encounters[encounter_id]
		if encounter and encounter.habitat and encounter.difficulty and encounter.habitat.id == habitat_id and encounter.difficulty.id == difficulty_id:
			ids.append(encounter_id)
	return ids

func validate_database() -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	if elements.size() != 5:
		errors.append("Expected 5 elements, found %s" % elements.size())
	if ailments.size() != 4:
		errors.append("Expected 4 ailments, found %s" % ailments.size())
	if difficulties.size() != 6:
		errors.append("Expected 6 difficulties, found %s" % difficulties.size())
	if habitats.size() != 12:
		errors.append("Expected 12 habitats, found %s" % habitats.size())
	if enemy_variants.size() != 255:
		errors.append("Expected 255 enemy variants, found %s" % enemy_variants.size())
	for enemy_id in enemy_variants.keys():
		var variant = enemy_variants[enemy_id]
		if variant == null:
			errors.append("Null enemy variant for key %s" % enemy_id)
			continue
		if variant.family == null or variant.mutation == null:
			errors.append("Enemy %s missing family or mutation reference" % enemy_id)
		if variant.attack_ids.is_empty():
			errors.append("Enemy %s has no attacks" % enemy_id)
		if variant.habitat_tags.is_empty():
			errors.append("Enemy %s has no habitat tags" % enemy_id)
		for attack_id in variant.attack_ids:
			if not attacks.has(attack_id):
				errors.append("Enemy %s references missing attack %s" % [enemy_id, attack_id])
	return {
		"ok": errors.is_empty(),
		"errors": errors
	}
