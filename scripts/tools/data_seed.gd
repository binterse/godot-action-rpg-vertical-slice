extends SceneTree

const StatusAilmentResource = preload("res://scripts/resources/status_ailment_resource.gd")
const ElementResource = preload("res://scripts/resources/element_resource.gd")
const DifficultyResource = preload("res://scripts/resources/difficulty_resource.gd")
const HabitatResource = preload("res://scripts/resources/habitat_resource.gd")
const LootEntryResource = preload("res://scripts/resources/loot_entry_resource.gd")
const AttackResource = preload("res://scripts/resources/attack_resource.gd")
const EnemyFamilyResource = preload("res://scripts/resources/enemy_family_resource.gd")
const EnemyMutationResource = preload("res://scripts/resources/enemy_mutation_resource.gd")
const EnemyVariantResource = preload("res://scripts/resources/enemy_variant_resource.gd")
const EncounterTemplateResource = preload("res://scripts/resources/encounter_template_resource.gd")
const PlayerLoadoutResource = preload("res://scripts/resources/player_loadout_resource.gd")
const UiThemeResource = preload("res://scripts/resources/ui_theme_resource.gd")

const DATA_DIRS := [
	"res://data/elements",
	"res://data/ailments",
	"res://data/difficulties",
	"res://data/habitats",
	"res://data/attacks",
	"res://data/enemy_families",
	"res://data/enemy_mutations",
	"res://data/enemy_variants",
	"res://data/encounters",
	"res://data/player",
	"res://data/loot",
	"res://data/ui"
]

var habitat_ids: PackedStringArray = PackedStringArray()

func _init() -> void:
	var exit_code := _generate()
	quit(exit_code)

func _generate() -> int:
	for dir_path in DATA_DIRS:
		_prepare_directory(dir_path)
	_generate_ailments()
	var elements := _generate_elements()
	var difficulties := _generate_difficulties()
	var habitats := _generate_habitats()
	_generate_loot()
	_generate_attacks(elements)
	var families := _generate_families(elements)
	var mutations := _generate_mutations()
	_generate_variants(families, mutations)
	_generate_player_loadout()
	_generate_ui_theme()
	_generate_encounters(habitats, difficulties)
	return 0

func _prepare_directory(dir_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	_clear_tres_files(dir_path)

func _clear_tres_files(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full_path := dir_path.path_join(name)
		if dir.current_is_dir():
			_clear_tres_files(full_path)
		elif name.ends_with(".tres") or name.ends_with(".res"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(full_path))
	dir.list_dir_end()

func _save_resource(resource: Resource, path: String) -> void:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Failed to save %s (%s)" % [path, error])

func _generate_ailments() -> Dictionary:
	var definitions := [
		{"id": "burn", "name": "Burn", "kind": "dot", "color": Color("ff8a63"), "duration": 4.0, "stacks": 3, "tick": 1.0, "potency": 1.0, "summary": "Applies sustained thermal damage over time."},
		{"id": "freeze", "name": "Freeze", "kind": "slow", "color": Color("84d8ff"), "duration": 2.8, "stacks": 1, "tick": 0.8, "potency": 1.0, "summary": "Locks movement and slows attack tempo."},
		{"id": "shock", "name": "Shock", "kind": "disrupt", "color": Color("ffe77a"), "duration": 3.4, "stacks": 2, "tick": 1.2, "potency": 0.9, "summary": "Disrupts output and causes periodic damage spikes."},
		{"id": "rupture", "name": "Rupture", "kind": "vulnerable", "color": Color("96f57d"), "duration": 4.6, "stacks": 3, "tick": 1.0, "potency": 1.0, "summary": "Destabilizes armor and amplifies incoming damage."}
	]
	var resources := {}
	for entry in definitions:
		var resource = StatusAilmentResource.new()
		resource.id = entry.id
		resource.display_name = entry.name
		resource.summary = entry.summary
		resource.effect_kind = entry.kind
		resource.color = entry.color
		resource.base_duration = entry.duration
		resource.max_stacks = entry.stacks
		resource.tick_interval = entry.tick
		resource.potency = entry.potency
		var path := "res://data/ailments/%s.tres" % entry.id
		_save_resource(resource, path)
		resources[entry.id] = resource
	return resources

func _generate_elements() -> Dictionary:
	var definitions := [
		{"id": "thermal", "name": "Thermal", "color": Color("ff8a63"), "status": "burn", "strong": "cryo", "weak": "void", "summary": "Aggressive heat damage with reliable burn pressure."},
		{"id": "cryo", "name": "Cryo", "color": Color("88e1ff"), "status": "freeze", "strong": "corrosive", "weak": "thermal", "summary": "Slowing precision damage with strong control tools."},
		{"id": "volt", "name": "Volt", "color": Color("ffe774"), "status": "shock", "strong": "void", "weak": "corrosive", "summary": "Fast disruptive output that punishes unstable targets."},
		{"id": "corrosive", "name": "Corrosive", "color": Color("8ef58b"), "status": "rupture", "strong": "volt", "weak": "cryo", "summary": "Attrition damage that strips defenses over time."},
		{"id": "void", "name": "Void", "color": Color("b38dff"), "status": "shock", "strong": "thermal", "weak": "volt", "summary": "Exotic anomaly energy with volatile overload effects."}
	]
	var resources := {}
	for entry in definitions:
		var resource = ElementResource.new()
		resource.id = entry.id
		resource.display_name = entry.name
		resource.summary = entry.summary
		resource.color = entry.color
		resource.status_id = entry.status
		resource.strong_against_id = entry.strong
		resource.weak_against_id = entry.weak
		_save_resource(resource, "res://data/elements/%s.tres" % entry.id)
		resources[entry.id] = resource
	return resources

func _generate_difficulties() -> Dictionary:
	var definitions := [
		{"id": "story", "name": "Story", "health": 0.78, "damage": 0.75, "speed": 0.9, "aggro": 0.85, "spawn": 0.9, "ailment": 0.8, "recovery": 1.3},
		{"id": "ranger", "name": "Ranger", "health": 1.0, "damage": 1.0, "speed": 1.0, "aggro": 1.0, "spawn": 1.0, "ailment": 1.0, "recovery": 1.0},
		{"id": "operative", "name": "Operative", "health": 1.18, "damage": 1.12, "speed": 1.05, "aggro": 1.08, "spawn": 1.15, "ailment": 1.08, "recovery": 0.94},
		{"id": "veteran", "name": "Veteran", "health": 1.34, "damage": 1.24, "speed": 1.1, "aggro": 1.16, "spawn": 1.28, "ailment": 1.16, "recovery": 0.88},
		{"id": "mythic", "name": "Mythic", "health": 1.54, "damage": 1.38, "speed": 1.16, "aggro": 1.26, "spawn": 1.42, "ailment": 1.28, "recovery": 0.82},
		{"id": "cataclysm", "name": "Cataclysm", "health": 1.78, "damage": 1.55, "speed": 1.22, "aggro": 1.36, "spawn": 1.58, "ailment": 1.38, "recovery": 0.78}
	]
	var resources := {}
	for entry in definitions:
		var resource = DifficultyResource.new()
		resource.id = entry.id
		resource.display_name = entry.name
		resource.summary = "%s tuning for enemy pressure, aggression, and ailment strength." % entry.name
		resource.enemy_health_mult = entry.health
		resource.enemy_damage_mult = entry.damage
		resource.enemy_speed_mult = entry.speed
		resource.aggression_mult = entry.aggro
		resource.spawn_pressure_mult = entry.spawn
		resource.ailment_potency_mult = entry.ailment
		resource.player_recovery_mult = entry.recovery
		_save_resource(resource, "res://data/difficulties/%s.tres" % entry.id)
		resources[entry.id] = resource
	return resources

func _generate_habitats() -> Dictionary:
	var definitions := [
		{"id": "orbital_wreckage", "name": "Orbital Wreckage", "summary": "Debris-ringed hull plates and intermittent vacuum surges.", "primary": Color("25405e"), "secondary": Color("6de2ff"), "ambient": Color("08101b"), "element": "void", "ailment": "shock", "damage": 7.0, "interval": 3.8, "role": "ranged", "bias": {"ranged": 1.0, "void": 0.9}},
		{"id": "dune_sea", "name": "Dune Sea", "summary": "Wind-cut dunes, searing sightlines, and drifting heat distortion.", "primary": Color("5a3b20"), "secondary": Color("f9b35b"), "ambient": Color("1b1207"), "element": "thermal", "ailment": "burn", "damage": 8.0, "interval": 3.2, "role": "skirmisher", "bias": {"skirmisher": 1.0, "thermal": 0.8}},
		{"id": "cryo_tundra", "name": "Cryo Tundra", "summary": "Glacial flats with whiteout gusts and brittle ice shelves.", "primary": Color("17354b"), "secondary": Color("8fe8ff"), "ambient": Color("07131d"), "element": "cryo", "ailment": "freeze", "damage": 6.0, "interval": 3.6, "role": "ranged", "bias": {"ranged": 0.8, "cryo": 1.1}},
		{"id": "fungal_jungle", "name": "Fungal Jungle", "summary": "Bioluminescent growths hide ambush lanes and corrosive spores.", "primary": Color("163724"), "secondary": Color("7df7ab"), "ambient": Color("06110a"), "element": "corrosive", "ailment": "rupture", "damage": 7.5, "interval": 3.4, "role": "skirmisher", "bias": {"skirmisher": 1.0, "corrosive": 0.9}},
		{"id": "magma_foundry", "name": "Magma Foundry", "summary": "Molten channels and ruptured industrial vents flood the arena with heat.", "primary": Color("4f1d14"), "secondary": Color("ff8a63"), "ambient": Color("150806"), "element": "thermal", "ailment": "burn", "damage": 9.0, "interval": 2.9, "role": "bruiser", "bias": {"bruiser": 1.1, "thermal": 1.0}},
		{"id": "toxic_marsh", "name": "Toxic Marsh", "summary": "Viscous pools and chemical haze punish lingering movement.", "primary": Color("274126"), "secondary": Color("9cee62"), "ambient": Color("091108"), "element": "corrosive", "ailment": "rupture", "damage": 8.5, "interval": 3.3, "role": "bruiser", "bias": {"bruiser": 0.8, "corrosive": 1.1}},
		{"id": "crystal_cavern", "name": "Crystal Cavern", "summary": "Resonant mineral shafts amplify energy discharge and ricochet fire.", "primary": Color("261f4c"), "secondary": Color("9cc6ff"), "ambient": Color("090818"), "element": "volt", "ailment": "shock", "damage": 7.0, "interval": 3.5, "role": "ranged", "bias": {"ranged": 1.1, "volt": 0.9}},
		{"id": "flooded_dome", "name": "Flooded Dome", "summary": "Broken sea labs with rising water and unstable conduits.", "primary": Color("13395b"), "secondary": Color("61c6ff"), "ambient": Color("051018"), "element": "volt", "ailment": "shock", "damage": 7.8, "interval": 3.1, "role": "ranged", "bias": {"ranged": 0.9, "volt": 1.0}},
		{"id": "megacity_ruins", "name": "Megacity Ruins", "summary": "Collapsed transit lanes and neon ghost-signage create dense crossfire.", "primary": Color("202536"), "secondary": Color("ffd86f"), "ambient": Color("0a0c12"), "element": "void", "ailment": "shock", "damage": 8.2, "interval": 3.0, "role": "skirmisher", "bias": {"skirmisher": 0.9, "void": 0.8}},
		{"id": "biotech_lab", "name": "Biotech Lab", "summary": "Sterile chambers bloom into weaponized growth at a moment's notice.", "primary": Color("14312f"), "secondary": Color("7cf0d0"), "ambient": Color("07100f"), "element": "corrosive", "ailment": "rupture", "damage": 7.6, "interval": 3.2, "role": "skirmisher", "bias": {"skirmisher": 0.7, "corrosive": 1.0}},
		{"id": "irradiated_wasteland", "name": "Irradiated Wasteland", "summary": "Storm-battered badlands with unstable anomalies and fractured cover.", "primary": Color("3a3922"), "secondary": Color("d5d472"), "ambient": Color("110f06"), "element": "volt", "ailment": "shock", "damage": 8.8, "interval": 2.8, "role": "bruiser", "bias": {"bruiser": 0.9, "volt": 0.8}},
		{"id": "alien_relic_vault", "name": "Alien Relic Vault", "summary": "Ancient geometry bends sightlines and releases void-charged pulses.", "primary": Color("28194a"), "secondary": Color("b38dff"), "ambient": Color("090411"), "element": "void", "ailment": "shock", "damage": 9.2, "interval": 2.7, "role": "bruiser", "bias": {"bruiser": 1.0, "void": 1.1}}
	]
	var resources := {}
	habitat_ids.clear()
	for entry in definitions:
		var resource = HabitatResource.new()
		resource.id = entry.id
		resource.display_name = entry.name
		resource.summary = entry.summary
		resource.palette_primary = entry.primary
		resource.palette_secondary = entry.secondary
		resource.ambient_color = entry.ambient
		resource.hazard_element_id = entry.element
		resource.hazard_ailment_id = entry.ailment
		resource.hazard_damage = entry.damage
		resource.hazard_interval = entry.interval
		resource.spawn_bias_role = entry.role
		resource.enemy_weight_bias = entry.bias
		_save_resource(resource, "res://data/habitats/%s.tres" % entry.id)
		habitat_ids.append(entry.id)
		resources[entry.id] = resource
	return resources

func _generate_loot() -> Dictionary:
	var definitions := [
		{"id": "scrap_bundle", "name": "Scrap Bundle", "currency": "credits", "amount": 24, "rarity": "common", "color": Color("d0dde8")},
		{"id": "thermal_core", "name": "Thermal Core", "currency": "thermal_parts", "amount": 10, "rarity": "special", "color": Color("ff8a63")},
		{"id": "cryo_core", "name": "Cryo Core", "currency": "cryo_parts", "amount": 10, "rarity": "special", "color": Color("88e1ff")},
		{"id": "volt_cell", "name": "Volt Cell", "currency": "volt_parts", "amount": 10, "rarity": "special", "color": Color("ffe774")},
		{"id": "corrosive_resin", "name": "Corrosive Resin", "currency": "corrosive_parts", "amount": 10, "rarity": "special", "color": Color("8ef58b")},
		{"id": "void_shard", "name": "Void Shard", "currency": "void_parts", "amount": 10, "rarity": "special", "color": Color("b38dff")}
	]
	var resources := {}
	for entry in definitions:
		var resource = LootEntryResource.new()
		resource.id = entry.id
		resource.display_name = entry.name
		resource.summary = "%s used for prototype reward readouts." % entry.name
		resource.currency_id = entry.currency
		resource.amount = entry.amount
		resource.rarity = entry.rarity
		resource.display_color = entry.color
		_save_resource(resource, "res://data/loot/%s.tres" % entry.id)
		resources[entry.id] = resource
	return resources

func _generate_attacks(elements: Dictionary) -> Dictionary:
	var resources := {}
	var role_stats := {
		"skirmisher": {"style": "melee", "range": 78.0, "cooldown": 1.0, "damage": 16.0, "speed": 0.0, "radius": 12.0},
		"ranged": {"style": "ranged", "range": 300.0, "cooldown": 1.2, "damage": 14.0, "speed": 420.0, "radius": 8.0},
		"bruiser": {"style": "melee", "range": 96.0, "cooldown": 1.45, "damage": 22.0, "speed": 0.0, "radius": 16.0}
	}
	for element_id in elements.keys():
		var element = elements[element_id]
		for role in role_stats.keys():
			var base: Dictionary = role_stats[role]
			var attack = AttackResource.new()
			attack.id = "%s_%s_attack" % [element_id, role]
			attack.display_name = "%s %s" % [element.display_name, role.capitalize()]
			attack.summary = "%s package for %s enemies." % [element.display_name, role]
			attack.style = base.style
			attack.element_id = element_id
			attack.base_damage = float(base.damage) + (2.0 if element_id == "thermal" else 0.0) + (1.0 if element_id == "void" else 0.0)
			attack.attack_range = base.range
			attack.cooldown = float(base.cooldown) - (0.08 if role == "skirmisher" and element_id == "volt" else 0.0)
			attack.projectile_speed = base.speed
			attack.ailment_buildup = 18.0 if role != "bruiser" else 24.0
			attack.radius = base.radius
			_save_resource(attack, "res://data/attacks/%s.tres" % attack.id)
			resources[attack.id] = attack
	var player_attacks := [
		{"id": "player_light_attack", "name": "Plasma Cutter", "style": "melee", "range": 92.0, "damage": 18.0, "cooldown": 0.28, "speed": 0.0, "buildup": 20.0, "radius": 14.0},
		{"id": "player_heavy_attack", "name": "Grav Hammer", "style": "melee", "range": 128.0, "damage": 34.0, "cooldown": 0.86, "speed": 0.0, "buildup": 34.0, "radius": 18.0},
		{"id": "player_tech_attack", "name": "Tech Lance", "style": "ranged", "range": 360.0, "damage": 24.0, "cooldown": 0.68, "speed": 520.0, "buildup": 22.0, "radius": 9.0}
	]
	for entry in player_attacks:
		var attack = AttackResource.new()
		attack.id = entry.id
		attack.display_name = entry.name
		attack.summary = "Player combat ability."
		attack.style = entry.style
		attack.base_damage = entry.damage
		attack.attack_range = entry.range
		attack.cooldown = entry.cooldown
		attack.projectile_speed = entry.speed
		attack.ailment_buildup = entry.buildup
		attack.radius = entry.radius
		_save_resource(attack, "res://data/attacks/%s.tres" % attack.id)
		resources[attack.id] = attack
	return resources

func _generate_families(elements: Dictionary) -> Dictionary:
	var resources := {}
	var role_bases := {
		"skirmisher": {"health": 72.0, "shield": 18.0, "speed": 166.0, "damage": 12.0, "aggression": 1.22},
		"ranged": {"health": 64.0, "shield": 28.0, "speed": 132.0, "damage": 14.0, "aggression": 1.08},
		"bruiser": {"health": 118.0, "shield": 36.0, "speed": 102.0, "damage": 18.0, "aggression": 0.96}
	}
	for element_id in elements.keys():
		var element = elements[element_id]
		for role in role_bases.keys():
			var stats: Dictionary = role_bases[role]
			var family = EnemyFamilyResource.new()
			family.id = "%s_%s" % [element_id, role]
			family.display_name = "%s %s" % [element.display_name, role.capitalize()]
			family.summary = "%s family tuned for %s behavior." % [element.display_name, role]
			family.role = role
			family.element_id = element_id
			family.ailment_id = element.status_id
			family.base_health = stats.health + (8.0 if element_id == "corrosive" else 0.0) + (10.0 if element_id == "void" and role == "bruiser" else 0.0)
			family.base_shield = stats.shield + (10.0 if element_id == "void" else 0.0) + (6.0 if element_id == "cryo" else 0.0)
			family.base_speed = stats.speed + (18.0 if element_id == "volt" else 0.0) - (8.0 if element_id == "cryo" and role == "bruiser" else 0.0)
			family.base_damage = stats.damage + (2.0 if element_id == "thermal" else 0.0)
			family.aggression = stats.aggression + (0.08 if element_id == "volt" else 0.0)
			family.default_attack_ids = PackedStringArray(["%s_%s_attack" % [element_id, role]])
			family.palette_color = element.color
			_save_resource(family, "res://data/enemy_families/%s.tres" % family.id)
			resources[family.id] = family
	return resources

func _generate_mutations() -> Dictionary:
	var resources := {}
	var habitat_definitions := [
		{"id": "wreckborn", "name": "Wreckborn", "prefix": "Wreckborn", "suffix": "", "health": 1.0, "damage": 1.02, "speed": 0.98, "aggro": 1.04, "ailment": 1.08, "tags": ["orbital_wreckage"], "shift": Color("8bd3ff")},
		{"id": "sandscoured", "name": "Sandscoured", "prefix": "Sandscoured", "suffix": "", "health": 0.98, "damage": 1.06, "speed": 1.08, "aggro": 1.08, "ailment": 1.0, "tags": ["dune_sea"], "shift": Color("f6b45f")},
		{"id": "frostbitten", "name": "Frostbitten", "prefix": "Frostbitten", "suffix": "", "health": 1.06, "damage": 0.98, "speed": 0.94, "aggro": 0.96, "ailment": 1.14, "tags": ["cryo_tundra"], "shift": Color("8fe8ff")},
		{"id": "mycoclad", "name": "Mycoclad", "prefix": "Mycoclad", "suffix": "", "health": 1.02, "damage": 1.04, "speed": 1.02, "aggro": 1.06, "ailment": 1.08, "tags": ["fungal_jungle"], "shift": Color("79f6a8")},
		{"id": "slagforged", "name": "Slagforged", "prefix": "Slagforged", "suffix": "", "health": 1.1, "damage": 1.08, "speed": 0.94, "aggro": 1.02, "ailment": 1.06, "tags": ["magma_foundry"], "shift": Color("ff8a63")},
		{"id": "bogslick", "name": "Bogslick", "prefix": "Bogslick", "suffix": "", "health": 1.08, "damage": 1.0, "speed": 0.98, "aggro": 0.98, "ailment": 1.12, "tags": ["toxic_marsh"], "shift": Color("9cee62")},
		{"id": "facetide", "name": "Facetide", "prefix": "Facetide", "suffix": "", "health": 0.98, "damage": 1.08, "speed": 1.03, "aggro": 1.02, "ailment": 1.12, "tags": ["crystal_cavern"], "shift": Color("9cc6ff")},
		{"id": "drowned", "name": "Drowned", "prefix": "Drowned", "suffix": "", "health": 1.04, "damage": 1.0, "speed": 0.96, "aggro": 1.0, "ailment": 1.1, "tags": ["flooded_dome"], "shift": Color("61c6ff")},
		{"id": "neon_ghost", "name": "Neon Ghost", "prefix": "Neon", "suffix": "Ghost", "health": 0.96, "damage": 1.1, "speed": 1.1, "aggro": 1.14, "ailment": 1.0, "tags": ["megacity_ruins"], "shift": Color("ffd86f")},
		{"id": "biocrafted", "name": "Biocrafted", "prefix": "Biocrafted", "suffix": "", "health": 1.04, "damage": 1.02, "speed": 1.0, "aggro": 1.06, "ailment": 1.12, "tags": ["biotech_lab"], "shift": Color("7cf0d0")},
		{"id": "radscarred", "name": "Radscarred", "prefix": "Radscarred", "suffix": "", "health": 1.06, "damage": 1.07, "speed": 1.04, "aggro": 1.1, "ailment": 1.08, "tags": ["irradiated_wasteland"], "shift": Color("d5d472")},
		{"id": "relicbound", "name": "Relicbound", "prefix": "Relicbound", "suffix": "", "health": 1.08, "damage": 1.08, "speed": 0.98, "aggro": 1.08, "ailment": 1.14, "tags": ["alien_relic_vault"], "shift": Color("b38dff")}
	]
	var advanced_definitions := [
		{"id": "assault_doctrine", "name": "Assault Doctrine", "prefix": "Assault", "suffix": "", "health": 1.08, "damage": 1.12, "speed": 1.08, "aggro": 1.16, "ailment": 1.0, "tags": habitat_ids, "shift": Color("ffbb7c")},
		{"id": "phase_tuned", "name": "Phase Tuned", "prefix": "Phase", "suffix": "", "health": 0.96, "damage": 1.08, "speed": 1.16, "aggro": 1.12, "ailment": 1.08, "tags": habitat_ids, "shift": Color("8fb6ff")},
		{"id": "siege_frame", "name": "Siege Frame", "prefix": "Siege", "suffix": "", "health": 1.18, "damage": 1.16, "speed": 0.9, "aggro": 1.02, "ailment": 1.06, "tags": habitat_ids, "shift": Color("ff9668")},
		{"id": "regen_lattice", "name": "Regen Lattice", "prefix": "Regen", "suffix": "Lattice", "health": 1.12, "damage": 0.98, "speed": 1.0, "aggro": 1.0, "ailment": 1.14, "tags": habitat_ids, "shift": Color("8cf6cb")},
		{"id": "umbra_shroud", "name": "Umbra Shroud", "prefix": "Umbra", "suffix": "", "health": 1.0, "damage": 1.14, "speed": 1.1, "aggro": 1.18, "ailment": 1.12, "tags": habitat_ids, "shift": Color("c3a1ff")}
	]
	for entry in habitat_definitions + advanced_definitions:
		var resource = EnemyMutationResource.new()
		resource.id = entry.id
		resource.display_name = entry.name
		resource.summary = "%s modifier package." % entry.name
		resource.category = "habitat" if entry.id in [
			"wreckborn", "sandscoured", "frostbitten", "mycoclad", "slagforged", "bogslick", "facetide", "drowned", "neon_ghost", "biocrafted", "radscarred", "relicbound"
		] else "advanced"
		resource.prefix = entry.prefix
		resource.suffix = entry.suffix
		resource.bonus_health = entry.health
		resource.bonus_damage = entry.damage
		resource.bonus_speed = entry.speed
		resource.aggression_bonus = entry.aggro
		resource.ailment_bonus = entry.ailment
		resource.habitat_tags = PackedStringArray(entry.tags)
		resource.palette_shift = entry.shift
		_save_resource(resource, "res://data/enemy_mutations/%s.tres" % resource.id)
		resources[resource.id] = resource
	return resources

func _generate_variants(families: Dictionary, mutations: Dictionary) -> void:
	var created := 0
	for family_id in families.keys():
		var family = families[family_id]
		var element_loot_map: Dictionary = {
			"thermal": "thermal_core",
			"cryo": "cryo_core",
			"volt": "volt_cell",
			"corrosive": "corrosive_resin",
			"void": "void_shard"
		}
		var element_loot_id: String = str(element_loot_map.get(family.element_id, "scrap_bundle"))
		for mutation_id in mutations.keys():
			var mutation = mutations[mutation_id]
			var variant = EnemyVariantResource.new()
			variant.id = "%s__%s" % [family.id, mutation.id]
			var name_parts: Array[String] = []
			if mutation.prefix != "":
				name_parts.append(mutation.prefix)
			name_parts.append(family.display_name)
			if mutation.suffix != "":
				name_parts.append(mutation.suffix)
			variant.display_name = " ".join(name_parts)
			variant.summary = "%s adapted for %s conditions." % [family.display_name, mutation.display_name]
			variant.family = family
			variant.mutation = mutation
			variant.role = family.role
			variant.element_id = family.element_id
			variant.ailment_id = family.ailment_id
			var stat_tweak := 1.0 + float((hash(variant.id) % 11) - 5) * 0.01
			variant.base_health = family.base_health * mutation.bonus_health * stat_tweak
			variant.base_shield = family.base_shield * lerpf(0.95, 1.15, mutation.bonus_health - 0.9)
			variant.base_speed = family.base_speed * mutation.bonus_speed
			variant.base_damage = family.base_damage * mutation.bonus_damage * stat_tweak
			variant.aggression = family.aggression * mutation.aggression_bonus
			variant.attack_ids = family.default_attack_ids
			variant.habitat_tags = mutation.habitat_tags
			variant.palette_primary = family.palette_color.lerp(mutation.palette_shift, 0.33)
			variant.palette_secondary = mutation.palette_shift.lerp(Color.WHITE, 0.24)
			variant.loot_ids = PackedStringArray(["scrap_bundle", element_loot_id])
			variant.difficulty_bias = {"mythic": 1.06 if mutation.category == "advanced" else 1.0, "cataclysm": 1.12 if mutation.category == "advanced" else 1.04}
			_save_resource(variant, "res://data/enemy_variants/%s.tres" % variant.id)
			created += 1
	if created != 255:
		push_error("Expected 255 variants, generated %s" % created)

func _generate_player_loadout() -> void:
	var loadout = PlayerLoadoutResource.new()
	loadout.id = "default_loadout"
	loadout.display_name = "Field Vanguard"
	loadout.summary = "Balanced prototype loadout for the combat slice."
	loadout.max_health = 190.0
	loadout.max_shield = 90.0
	loadout.move_speed = 270.0
	loadout.dodge_speed = 640.0
	loadout.dodge_duration = 0.22
	loadout.light_attack_id = "player_light_attack"
	loadout.heavy_attack_id = "player_heavy_attack"
	loadout.tech_attack_id = "player_tech_attack"
	loadout.affinity_element_id = "thermal"
	loadout.status_resistance = 0.18
	loadout.shield_regen_delay = 2.8
	_save_resource(loadout, "res://data/player/default_loadout.tres")

func _generate_ui_theme() -> void:
	var theme = UiThemeResource.new()
	theme.id = "default_theme"
	theme.display_name = "Command Slate"
	theme.summary = "Placeholder sci-fi UI colors for menus and HUD."
	theme.accent = Color("6de2ff")
	theme.accent_alt = Color("ffce6b")
	theme.background = Color("08101b")
	theme.panel = Color("112238")
	theme.warning = Color("ff7a66")
	theme.success = Color("82f7a8")
	theme.text_primary = Color("e6f1ff")
	_save_resource(theme, "res://data/ui/default_theme.tres")

func _generate_encounters(habitats: Dictionary, difficulties: Dictionary) -> void:
	for habitat_id in habitats.keys():
		var habitat = habitats[habitat_id]
		var allowed_enemy_ids: PackedStringArray = PackedStringArray()
		var variant_dir := DirAccess.open("res://data/enemy_variants")
		if variant_dir:
			variant_dir.list_dir_begin()
			while true:
				var name := variant_dir.get_next()
				if name == "":
					break
				if name.ends_with(".tres"):
					var resource = load("res://data/enemy_variants/%s" % name)
					if resource and habitat_id in resource.habitat_tags:
						allowed_enemy_ids.append(resource.id)
			variant_dir.list_dir_end()
		allowed_enemy_ids.sort()
		for difficulty_id in difficulties.keys():
			var difficulty = difficulties[difficulty_id]
			var encounter = EncounterTemplateResource.new()
			encounter.id = "%s__%s" % [habitat_id, difficulty_id]
			encounter.display_name = "%s %s Sweep" % [habitat.display_name, difficulty.display_name]
			encounter.summary = "Wave encounter for %s on %s." % [habitat.display_name, difficulty.display_name]
			encounter.habitat = habitat
			encounter.difficulty = difficulty
			encounter.allowed_enemy_ids = allowed_enemy_ids
			var difficulty_rank := ["story", "ranger", "operative", "veteran", "mythic", "cataclysm"].find(difficulty_id)
			encounter.wave_count = 3 + int(floor(difficulty_rank / 2.0))
			encounter.base_wave_size = 2 + difficulty_rank / 2
			encounter.reward_credits = 120 + difficulty_rank * 70 + habitats.keys().find(habitat_id) * 15
			encounter.champion_chance = 0.05 + float(difficulty_rank) * 0.05
			encounter.boss_enemy_id = _pick_boss_enemy(allowed_enemy_ids, habitat.hazard_element_id)
			_save_resource(encounter, "res://data/encounters/%s.tres" % encounter.id)

func _pick_boss_enemy(enemy_ids: PackedStringArray, preferred_element_id: String) -> String:
	for enemy_id in enemy_ids:
		var resource = load("res://data/enemy_variants/%s.tres" % enemy_id)
		if resource and resource.role == "bruiser" and resource.element_id == preferred_element_id:
			return resource.id
	return enemy_ids[0] if enemy_ids.size() > 0 else ""
