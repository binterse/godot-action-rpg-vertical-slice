extends "res://scripts/game/combat_entity.gd"

var loadout
var dodge_timer: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_direction: Vector2 = Vector2.RIGHT
var attack_cooldowns: Dictionary = {}
var shield_regen_timer: float = 0.0
var cleanse_cooldown: float = 0.0

func _run_state() -> Node:
	return get_node("/root/RunState")

func configure(loadout_resource, root: Node) -> void:
	loadout = loadout_resource
	var element = _db().get_element(_run_state().player_element_id)
	var primary = element.color if element else Color("6de2ff")
	setup_base({
		"entity_name": "Vanguard Operative",
		"faction": "player",
		"element_id": _run_state().player_element_id,
		"ailment_id": element.status_id if element else "burn",
		"max_health": loadout.max_health,
		"max_shield": loadout.max_shield,
		"move_speed": loadout.move_speed,
		"base_damage": 18.0,
		"aggression": 1.0,
		"radius": 20.0,
		"tint": primary,
		"accent_color": primary.lerp(Color.WHITE, 0.45),
		"status_resistance": loadout.status_resistance,
		"combat_root": root
	})

func _process(delta: float) -> void:
	if combat_root and combat_root.has_method("is_game_paused") and combat_root.is_game_paused():
		queue_redraw()
		return
	tick_entity(delta)
	if not alive:
		return
	_update_timers(delta)
	_handle_movement(delta)
	_handle_actions()
	_handle_shield_regen(delta)

func receive_hit(packet: Dictionary) -> Dictionary:
	var result = super.receive_hit(packet)
	if bool(result.get("applied", false)):
		shield_regen_timer = loadout.shield_regen_delay
	return result

func _update_timers(delta: float) -> void:
	dodge_timer = maxf(0.0, dodge_timer - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	cleanse_cooldown = maxf(0.0, cleanse_cooldown - delta)
	for attack_id in attack_cooldowns.keys():
		attack_cooldowns[attack_id] = maxf(0.0, float(attack_cooldowns[attack_id]) - delta)

func _handle_movement(delta: float) -> void:
	if dodge_timer > 0.0:
		position += dodge_direction * loadout.dodge_speed * delta
		invulnerable_time = maxf(invulnerable_time, 0.05)
		if combat_root:
			position = combat_root.clamp_position(position, radius)
		return
	var input_vector := Vector2.ZERO
	input_vector.x = (1.0 if Input.is_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
	input_vector.y = (1.0 if Input.is_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) else 0.0)
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	if input_vector.length_squared() > 0.0:
		dodge_direction = input_vector.normalized()
	position += input_vector * move_speed * get_speed_multiplier() * delta
	if combat_root:
		position = combat_root.clamp_position(position, radius)

func _handle_actions() -> void:
	if Input.is_key_pressed(KEY_SPACE) and dodge_cooldown <= 0.0 and dodge_timer <= 0.0:
		dodge_timer = loadout.dodge_duration
		dodge_cooldown = 0.9
		invulnerable_time = loadout.dodge_duration
		if dodge_direction == Vector2.ZERO:
			dodge_direction = Vector2.RIGHT
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_trigger_attack(loadout.light_attack_id)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_trigger_attack(loadout.heavy_attack_id)
	if Input.is_key_pressed(KEY_E):
		_trigger_attack(loadout.tech_attack_id)
	if Input.is_key_pressed(KEY_C) and cleanse_cooldown <= 0.0 and shield >= 12.0:
		shield -= 12.0
		clear_ailments()
		cleanse_cooldown = 8.0

func _handle_shield_regen(delta: float) -> void:
	shield_regen_timer = maxf(0.0, shield_regen_timer - delta)
	if shield_regen_timer <= 0.0 and shield < max_shield:
		shield = minf(max_shield, shield + 18.0 * delta)

func _trigger_attack(attack_id: String) -> void:
	if attack_id == "":
		return
	if float(attack_cooldowns.get(attack_id, 0.0)) > 0.0:
		return
	var attack = _db().get_attack(attack_id)
	if attack == null or combat_root == null:
		return
	var direction = combat_root.get_aim_direction(global_position)
	attack_cooldowns[attack_id] = attack.cooldown
	combat_root.execute_attack(self, attack, direction, element_id, get_outgoing_damage_multiplier())
