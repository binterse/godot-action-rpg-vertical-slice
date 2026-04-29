extends Node

func get_element_multiplier(attack_element_id: String, defender_element_id: String) -> float:
	var element = GameDB.get_element(attack_element_id)
	if element == null or defender_element_id == "":
		return 1.0
	if element.strong_against_id == defender_element_id:
		return 1.0 + element.damage_bonus
	if element.weak_against_id == defender_element_id:
		return 1.0 - element.weakness_penalty
	return 1.0

func resolve_damage(base_damage: float, attack_element_id: String, defender_element_id: String, difficulty_mult: float = 1.0, mitigation: float = 0.0) -> Dictionary:
	var multiplier = get_element_multiplier(attack_element_id, defender_element_id)
	var value = maxf(1.0, base_damage * multiplier * difficulty_mult * (1.0 - mitigation))
	return {
		"damage": value,
		"multiplier": multiplier
	}

func build_ailment_packet(attack_element_id: String, buildup: float, source_power: float, resistance: float = 0.0) -> Dictionary:
	var element = GameDB.get_element(attack_element_id)
	if element == null or element.status_id == "" or buildup <= 0.0:
		return {}
	var ailment = GameDB.get_ailment(element.status_id)
	if ailment == null:
		return {}
	return {
		"ailment_id": ailment.id,
		"buildup": buildup * source_power * (1.0 - resistance),
		"duration": ailment.base_duration,
		"potency": ailment.potency * source_power,
		"max_stacks": ailment.max_stacks
	}

func get_spawn_budget(encounter) -> int:
	if encounter == null or encounter.difficulty == null:
		return 3
	return maxi(2, int(round(encounter.base_wave_size * encounter.difficulty.spawn_pressure_mult)))

func get_scaled_enemy_stats(variant, difficulty, habitat) -> Dictionary:
	var health: float = variant.base_health
	var shield: float = variant.base_shield
	var speed: float = variant.base_speed
	var damage: float = variant.base_damage
	var aggression: float = variant.aggression
	if difficulty:
		health *= difficulty.enemy_health_mult
		shield *= lerpf(1.0, difficulty.enemy_health_mult, 0.65)
		speed *= difficulty.enemy_speed_mult
		damage *= difficulty.enemy_damage_mult
		aggression *= difficulty.aggression_mult
	if habitat:
		health *= 1.0 + float(habitat.enemy_weight_bias.get(variant.role, 0.0)) * 0.08
		damage *= 1.0 + float(habitat.enemy_weight_bias.get(variant.element_id, 0.0)) * 0.05
	return {
		"health": health,
		"shield": shield,
		"speed": speed,
		"damage": damage,
		"aggression": aggression
	}

func get_status_tick_damage(ailment_id: String, max_health: float, potency: float) -> float:
	match ailment_id:
		"burn":
			return maxf(2.0, max_health * 0.018 * potency)
		"shock":
			return maxf(1.0, max_health * 0.012 * potency)
		"rupture":
			return maxf(2.0, max_health * 0.015 * potency)
		_:
			return 0.0
