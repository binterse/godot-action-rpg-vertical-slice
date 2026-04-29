extends "res://scripts/game/combat_entity.gd"

var variant
var difficulty
var habitat
var attack_cooldowns: Dictionary = {}
var movement_seed: float = randf_range(0.0, TAU)
var champion: bool = false

func configure(variant_resource, difficulty_resource, habitat_resource, root: Node, is_champion: bool = false) -> void:
	variant = variant_resource
	difficulty = difficulty_resource
	habitat = habitat_resource
	champion = is_champion
	var scaled = _rules().get_scaled_enemy_stats(variant, difficulty, habitat)
	var radius_value := 18.0
	if variant.role == "bruiser":
		radius_value = 24.0
	elif variant.role == "ranged":
		radius_value = 16.0
	if champion:
		scaled["health"] = float(scaled.get("health", 0.0)) * 1.45
		scaled["damage"] = float(scaled.get("damage", 0.0)) * 1.2
		scaled["speed"] = float(scaled.get("speed", 0.0)) * 1.05
		scaled["aggression"] = float(scaled.get("aggression", 0.0)) * 1.1
	setup_base({
		"entity_name": variant.display_name + (" Prime" if champion else ""),
		"faction": "enemy",
		"element_id": variant.element_id,
		"ailment_id": variant.ailment_id,
		"max_health": float(scaled.get("health", 0.0)),
		"max_shield": float(scaled.get("shield", 0.0)),
		"move_speed": float(scaled.get("speed", 0.0)),
		"base_damage": float(scaled.get("damage", 0.0)),
		"aggression": float(scaled.get("aggression", 1.0)),
		"radius": radius_value,
		"tint": variant.palette_primary,
		"accent_color": variant.palette_secondary,
		"combat_root": root
	})
	status_resistance = 0.08 if champion else 0.0

func _process(delta: float) -> void:
	if combat_root and combat_root.has_method("is_game_paused") and combat_root.is_game_paused():
		queue_redraw()
		return
	tick_entity(delta)
	if not alive or combat_root == null:
		return
	for attack_id in attack_cooldowns.keys():
		attack_cooldowns[attack_id] = maxf(0.0, float(attack_cooldowns[attack_id]) - delta)
	var player = combat_root.player
	if player == null or not player.alive:
		return
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized() if distance > 0.001 else Vector2.RIGHT
	var move_vector = direction
	match variant.role:
		"ranged":
			if distance < 190.0:
				move_vector = -direction
			elif distance < 280.0:
				move_vector = Vector2(direction.y, -direction.x) * sin(Time.get_ticks_msec() * 0.003 + movement_seed)
		"skirmisher":
			move_vector = direction + Vector2(-direction.y, direction.x) * 0.65 * sin(float(Time.get_ticks_msec()) * 0.004 + movement_seed)
		_:
			move_vector = direction
	position += move_vector.normalized() * move_speed * get_speed_multiplier() * delta
	position = combat_root.clamp_position(position, radius)
	var attack = _get_ready_attack(distance)
	if attack:
		attack_cooldowns[attack.id] = attack.cooldown / maxf(0.45, aggression)
		combat_root.execute_attack(self, attack, direction, element_id, get_outgoing_damage_multiplier())

func _get_ready_attack(distance_to_player: float):
	for attack_id in variant.attack_ids:
		if float(attack_cooldowns.get(attack_id, 0.0)) > 0.0:
			continue
		var attack = _db().get_attack(attack_id)
		if attack == null:
			continue
		var tolerance = 32.0 if attack.style == "ranged" else 18.0
		if distance_to_player <= attack.attack_range + tolerance:
			return attack
	return null
