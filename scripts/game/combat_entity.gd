extends Node2D
class_name CombatEntity

signal died(entity: CombatEntity)
signal hit_received(entity: CombatEntity, packet: Dictionary, outcome: Dictionary)

var combat_root: Node = null
var faction: String = "neutral"
var entity_name: String = "Entity"
var element_id: String = "thermal"
var ailment_id: String = "burn"
var max_health: float = 100.0
var health: float = 100.0
var max_shield: float = 0.0
var shield: float = 0.0
var move_speed: float = 150.0
var base_damage: float = 12.0
var aggression: float = 1.0
var radius: float = 18.0
var tint: Color = Color.WHITE
var accent_color: Color = Color("8ad8ff")
var status_resistance: float = 0.0
var active_ailments: Dictionary = {}
var ailment_meters: Dictionary = {}
var invulnerable_time: float = 0.0
var alive: bool = true

func _db() -> Node:
	return get_node("/root/GameDB")

func _rules() -> Node:
	return get_node("/root/CombatRules")

func setup_base(config: Dictionary) -> void:
	entity_name = str(config.get("entity_name", entity_name))
	faction = str(config.get("faction", faction))
	element_id = str(config.get("element_id", element_id))
	ailment_id = str(config.get("ailment_id", ailment_id))
	max_health = float(config.get("max_health", max_health))
	health = max_health
	max_shield = float(config.get("max_shield", max_shield))
	shield = max_shield
	move_speed = float(config.get("move_speed", move_speed))
	base_damage = float(config.get("base_damage", base_damage))
	aggression = float(config.get("aggression", aggression))
	radius = float(config.get("radius", radius))
	tint = config.get("tint", tint)
	accent_color = config.get("accent_color", accent_color)
	status_resistance = float(config.get("status_resistance", status_resistance))
	combat_root = config.get("combat_root", combat_root)

func tick_entity(delta: float) -> void:
	if not alive:
		return
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	_process_ailments(delta)
	queue_redraw()

func receive_hit(packet: Dictionary) -> Dictionary:
	if not alive or invulnerable_time > 0.0:
		return {"applied": false, "damage": 0.0}
	var defense_mult = get_incoming_damage_multiplier()
	var resolved = _rules().resolve_damage(
		float(packet.get("damage", 0.0)) * defense_mult,
		str(packet.get("element_id", "")),
		element_id,
		float(packet.get("difficulty_mult", 1.0)),
		float(packet.get("mitigation", 0.0))
	)
	var damage = float(resolved.get("damage", 0.0))
	var absorbed = minf(shield, damage)
	shield -= absorbed
	health -= maxf(0.0, damage - absorbed)
	if packet.has("ailment"):
		_apply_ailment_packet(packet.get("ailment", {}))
	var outcome = {
		"applied": true,
		"damage": damage,
		"shield_absorbed": absorbed,
		"remaining_health": health,
		"remaining_shield": shield,
		"element_mult": float(resolved.get("multiplier", 1.0))
	}
	hit_received.emit(self, packet, outcome)
	if health <= 0.0:
		health = 0.0
		alive = false
		died.emit(self)
	return outcome

func direct_damage(amount: float, source_label: String = "hazard") -> void:
	if not alive:
		return
	receive_hit({
		"damage": amount,
		"element_id": "",
		"source": source_label
	})

func clear_ailments() -> void:
	active_ailments.clear()
	ailment_meters.clear()

func get_speed_multiplier() -> float:
	if active_ailments.has("freeze"):
		return 0.5
	if active_ailments.has("shock"):
		return 0.88
	return 1.0

func get_outgoing_damage_multiplier() -> float:
	return 0.82 if active_ailments.has("shock") else 1.0

func get_incoming_damage_multiplier() -> float:
	return 1.18 if active_ailments.has("rupture") else 1.0

func get_status_summary() -> String:
	if active_ailments.is_empty():
		return "Clear"
	var labels: Array[String] = []
	for ailment_id_key in active_ailments.keys():
		var entry: Dictionary = active_ailments[ailment_id_key]
		labels.append("%s x%s" % [String(ailment_id_key).capitalize(), int(entry.get("stacks", 1))])
	labels.sort()
	return ", ".join(labels)

func _apply_ailment_packet(packet: Dictionary) -> void:
	var ailment_id_key = str(packet.get("ailment_id", ""))
	if ailment_id_key == "":
		return
	var buildup = float(packet.get("buildup", 0.0))
	var meter = float(ailment_meters.get(ailment_id_key, 0.0))
	meter += buildup
	ailment_meters[ailment_id_key] = meter
	if meter < 100.0:
		return
	ailment_meters[ailment_id_key] = meter - 100.0
	var ailment = _db().get_ailment(ailment_id_key)
	if ailment == null:
		return
	var current: Dictionary = active_ailments.get(ailment_id_key, {})
	var next_stacks = mini(int(current.get("stacks", 0)) + 1, int(packet.get("max_stacks", ailment.max_stacks)))
	active_ailments[ailment_id_key] = {
		"time_left": maxf(float(packet.get("duration", ailment.base_duration)), float(current.get("time_left", 0.0))),
		"tick_timer": ailment.tick_interval,
		"stacks": max(1, next_stacks),
		"potency": maxf(float(packet.get("potency", ailment.potency)), float(current.get("potency", 0.0)))
	}

func _process_ailments(delta: float) -> void:
	if active_ailments.is_empty():
		return
	var expired: Array[String] = []
	for ailment_id_key in active_ailments.keys():
		var entry: Dictionary = active_ailments[ailment_id_key]
		entry["time_left"] = float(entry.get("time_left", 0.0)) - delta
		entry["tick_timer"] = float(entry.get("tick_timer", 0.0)) - delta
		if float(entry.get("tick_timer", 0.0)) <= 0.0:
			var ailment = _db().get_ailment(ailment_id_key)
			if ailment:
				entry["tick_timer"] = ailment.tick_interval
				var potency = float(entry.get("potency", 1.0)) * float(entry.get("stacks", 1))
				var tick_damage = _rules().get_status_tick_damage(ailment_id_key, max_health, potency)
				if tick_damage > 0.0:
					direct_damage(tick_damage, ailment_id_key)
		active_ailments[ailment_id_key] = entry
		if float(entry.get("time_left", 0.0)) <= 0.0:
			expired.append(ailment_id_key)
	for ailment_id_key in expired:
		active_ailments.erase(ailment_id_key)

func _draw() -> void:
	if not alive:
		return
	var shadow = Color(0, 0, 0, 0.25)
	draw_circle(Vector2(4, 4), radius + 1.0, shadow)
	draw_circle(Vector2.ZERO, radius, tint)
	draw_circle(Vector2.ZERO, radius * 0.55, accent_color)
	if max_shield > 0.0 and shield > 0.0:
		var shield_ratio = clampf(shield / max_shield, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius + 5.0, -PI * 0.5, -PI * 0.5 + TAU * shield_ratio, 32, Color("80d8ff"), 3.0)
	var health_ratio = clampf(health / max_health, 0.0, 1.0)
	draw_arc(Vector2.ZERO, radius + 10.0, -PI * 0.5, -PI * 0.5 + TAU * health_ratio, 32, Color("ff6f6f"), 4.0)
	if not active_ailments.is_empty():
		var ailment_id_key = str(active_ailments.keys()[0])
		var ailment = _db().get_ailment(ailment_id_key)
		var ailment_color = ailment.color if ailment else Color.WHITE
		draw_circle(Vector2.ZERO, radius * 0.22, ailment_color)
