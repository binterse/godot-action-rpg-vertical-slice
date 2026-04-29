extends Node2D

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")

var encounter
var habitat
var difficulty
var player
var enemies: Array = []
var projectiles: Array = []
var ui_layer: CanvasLayer
var hud_panel: PanelContainer
var overlay_panel: PanelContainer
var header_label: Label
var stats_label: Label
var target_label: Label
var objective_label: Label
var hint_label: Label
var overlay_title: Label
var overlay_body: Label
var overlay_backdrop: ColorRect
var resume_button: Button
var retry_button: Button
var menu_button: Button
var paused: bool = false
var finished: bool = false
var wave_index: int = 0
var spawn_timer: float = 0.8
var hazard_zones: Array[Dictionary] = []
var background_points: Array[Vector2] = []
var rng := RandomNumberGenerator.new()
var arena_rect := Rect2(Vector2(90, 110), Vector2(1420, 700))

func _db() -> Node:
	return get_node("/root/GameDB")

func _run_state() -> Node:
	return get_node("/root/RunState")

func _rules() -> Node:
	return get_node("/root/CombatRules")

func _ready() -> void:
	rng.seed = hash("%s|%s" % [_run_state().selected_habitat_id, _run_state().selected_difficulty_id])
	encounter = _run_state().get_selected_encounter()
	if encounter == null:
		push_error("No encounter selected")
		get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
		return
	habitat = encounter.habitat
	difficulty = encounter.difficulty
	_build_ui()
	_generate_background_points()
	_generate_hazards()
	_spawn_player()
	queue_redraw()

func is_game_paused() -> bool:
	return paused or finished

func clamp_position(input_position: Vector2, margin: float = 20.0) -> Vector2:
	return Vector2(
		clampf(input_position.x, arena_rect.position.x + margin, arena_rect.end.x - margin),
		clampf(input_position.y, arena_rect.position.y + margin, arena_rect.end.y - margin)
	)

func get_aim_direction(from_position: Vector2) -> Vector2:
	var direction := get_global_mouse_position() - from_position
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if finished:
			return
		paused = not paused
		_update_overlay(paused, "Paused", "Encounter diagnostics suspended.")

func _process(delta: float) -> void:
	if paused:
		return
	if player == null:
		return
	_update_hazards(delta)
	_cleanup_lists()
	if not finished:
		if enemies.is_empty():
			if wave_index < encounter.wave_count:
				spawn_timer -= delta
				if spawn_timer <= 0.0:
					wave_index += 1
					_spawn_wave(wave_index)
					spawn_timer = 1.25
			else:
				_finish_run(true)
	_update_ui()
	queue_redraw()

func execute_attack(source, attack, direction: Vector2, attack_element_id: String, source_damage_mult: float) -> void:
	if source == null or attack == null:
		return
	var total_damage = (source.base_damage + attack.base_damage) * source_damage_mult
	var ailment = _rules().build_ailment_packet(attack_element_id, attack.ailment_buildup, difficulty.ailment_potency_mult if source.faction == "enemy" else 1.0)
	var packet = {
		"damage": total_damage,
		"element_id": attack_element_id,
		"source": source.entity_name,
		"ailment": ailment,
		"mitigation": 0.0
	}
	if attack.style == "ranged":
		var projectile = PROJECTILE_SCENE.instantiate()
		add_child(projectile)
		var launch_direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
		projectile.setup(self, source.faction, source.global_position + launch_direction * (source.radius + 14.0), launch_direction * attack.projectile_speed, attack.radius, packet, source.tint)
		projectiles.append(projectile)
		return
	var targets: Array = []
	if source.faction == "player":
		targets = enemies.duplicate()
	else:
		targets = [player]
	for target in targets:
		if target == null or not target.alive:
			continue
		var distance = source.global_position.distance_to(target.global_position)
		if distance <= attack.attack_range + target.radius:
			target.receive_hit(packet)

func resolve_projectile(projectile) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	if not arena_rect.grow(36.0).has_point(projectile.global_position):
		projectile.queue_free()
		return
	var targets: Array = [player] if projectile.owner_faction == "enemy" else enemies
	for target in targets:
		if target == null or not target.alive:
			continue
		if projectile.global_position.distance_to(target.global_position) <= projectile.radius + target.radius:
			target.receive_hit(projectile.damage_packet)
			projectile.queue_free()
			return

func _spawn_player() -> void:
	var loadout = _db().get_default_loadout()
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = arena_rect.get_center()
	player.configure(loadout, self)
	player.died.connect(_on_player_died)

func _spawn_wave(number: int) -> void:
	var budget = _rules().get_spawn_budget(encounter) + number - 1
	var candidates = encounter.allowed_enemy_ids
	if candidates.is_empty():
		return
	for index in range(budget):
		var enemy_id = _pick_enemy_id(candidates, number, index)
		var variant = _db().get_enemy_variant(enemy_id)
		if variant == null:
			continue
		var enemy = ENEMY_SCENE.instantiate()
		add_child(enemy)
		var spawn_position = _pick_spawn_position(index)
		enemy.global_position = spawn_position
		var champion = index == budget - 1 and rng.randf() < encounter.champion_chance + float(number - 1) * 0.05
		enemy.configure(variant, difficulty, habitat, self, champion)
		enemy.died.connect(_on_enemy_died)
		enemies.append(enemy)
	objective_label.text = "Wave %s / %s deployed" % [number, encounter.wave_count]

func _pick_enemy_id(candidates: PackedStringArray, wave_number: int, slot_index: int) -> String:
	var best_weight = -1.0
	var best_id = candidates[0]
	for candidate_id in candidates:
		var variant = _db().get_enemy_variant(candidate_id)
		if variant == null:
			continue
		var weight = 1.0 + rng.randf() * 0.35
		if variant.role == habitat.spawn_bias_role:
			weight += 0.45
		if variant.element_id == habitat.hazard_element_id:
			weight += 0.25
		if wave_number >= encounter.wave_count and variant.role == "bruiser":
			weight += 0.35
		if slot_index % 2 == 0 and variant.role == "ranged":
			weight += 0.1
		if weight > best_weight:
			best_weight = weight
			best_id = candidate_id
	return best_id

func _pick_spawn_position(index: int) -> Vector2:
	var edge = index % 4
	match edge:
		0:
			return Vector2(rng.randf_range(arena_rect.position.x + 30.0, arena_rect.end.x - 30.0), arena_rect.position.y + 30.0)
		1:
			return Vector2(arena_rect.end.x - 30.0, rng.randf_range(arena_rect.position.y + 30.0, arena_rect.end.y - 30.0))
		2:
			return Vector2(rng.randf_range(arena_rect.position.x + 30.0, arena_rect.end.x - 30.0), arena_rect.end.y - 30.0)
		_:
			return Vector2(arena_rect.position.x + 30.0, rng.randf_range(arena_rect.position.y + 30.0, arena_rect.end.y - 30.0))

func _generate_hazards() -> void:
	hazard_zones.clear()
	for i in range(3):
		hazard_zones.append({
			"position": Vector2(
				rng.randf_range(arena_rect.position.x + 160.0, arena_rect.end.x - 160.0),
				rng.randf_range(arena_rect.position.y + 110.0, arena_rect.end.y - 110.0)
			),
			"radius": rng.randf_range(50.0, 90.0),
			"timer": habitat.hazard_interval + i * 0.4
		})

func _update_hazards(delta: float) -> void:
	for zone in hazard_zones:
		zone["timer"] = float(zone.get("timer", 0.0)) - delta
		if float(zone.get("timer", 0.0)) > 0.0:
			continue
		zone["timer"] = habitat.hazard_interval
		var ailment_packet = _rules().build_ailment_packet(habitat.hazard_element_id, 48.0, difficulty.ailment_potency_mult)
		var packet = {
			"damage": habitat.hazard_damage * difficulty.enemy_damage_mult,
			"element_id": habitat.hazard_element_id,
			"source": habitat.display_name,
			"ailment": ailment_packet
		}
		var zone_position = zone.get("position", Vector2.ZERO)
		var zone_radius = float(zone.get("radius", 0.0))
		if player and player.alive and player.global_position.distance_to(zone_position) <= zone_radius + player.radius:
			player.receive_hit(packet)
		for enemy in enemies:
			if enemy and enemy.alive and enemy.global_position.distance_to(zone_position) <= zone_radius + enemy.radius:
				enemy.receive_hit(packet)

func _cleanup_lists() -> void:
	var remaining_enemies: Array = []
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.alive:
			remaining_enemies.append(enemy)
	enemies = remaining_enemies
	var remaining_projectiles: Array = []
	for projectile in projectiles:
		if projectile and is_instance_valid(projectile):
			remaining_projectiles.append(projectile)
	projectiles = remaining_projectiles

func _on_player_died(_entity) -> void:
	_finish_run(false)

func _on_enemy_died(enemy) -> void:
	objective_label.text = "%s neutralized" % enemy.entity_name

func _finish_run(victory: bool) -> void:
	if finished:
		return
	finished = true
	paused = false
	_run_state().last_result = "Victory" if victory else "Defeat"
	_run_state().last_reward = encounter.reward_credits if victory else 0
	_update_overlay(true, _run_state().last_result, "Reward: %s credits\nHabitat: %s\nDifficulty: %s" % [_run_state().last_reward, habitat.display_name, difficulty.display_name])

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	hud_panel = PanelContainer.new()
	hud_panel.position = Vector2(18, 18)
	hud_panel.size = Vector2(420, 180)
	ui_layer.add_child(hud_panel)
	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 6)
	hud_panel.add_child(hud_box)

	header_label = Label.new()
	header_label.add_theme_font_size_override("font_size", 26)
	hud_box.add_child(header_label)

	stats_label = Label.new()
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_box.add_child(stats_label)

	target_label = Label.new()
	target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_box.add_child(target_label)

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_box.add_child(objective_label)

	hint_label = Label.new()
	hint_label.position = Vector2(1120, 18)
	hint_label.size = Vector2(360, 130)
	hint_label.text = "WASD move\nSpace dodge\nLMB light / RMB heavy\nE tech shot / C cleanse / Esc pause"
	ui_layer.add_child(hint_label)

	var status_badge := PanelContainer.new()
	status_badge.position = Vector2(1260, 130)
	status_badge.size = Vector2(210, 210)
	var badge_box := VBoxContainer.new()
	badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
	status_badge.add_child(badge_box)
	var badge_title := Label.new()
	badge_title.text = "Arena Telemetry"
	badge_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_box.add_child(badge_title)
	var badge_text := Label.new()
	badge_text.text = "Hazards active\nElemental flux\nWave pressure online"
	badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_box.add_child(badge_text)
	ui_layer.add_child(status_badge)

	overlay_backdrop = ColorRect.new()
	overlay_backdrop.color = Color(0.01, 0.02, 0.05, 0.76)
	overlay_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_backdrop.visible = false
	ui_layer.add_child(overlay_backdrop)

	overlay_panel = PanelContainer.new()
	overlay_panel.visible = false
	overlay_panel.position = Vector2(520, 220)
	overlay_panel.size = Vector2(560, 300)
	ui_layer.add_child(overlay_panel)
	var overlay_box := VBoxContainer.new()
	overlay_box.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_box.add_theme_constant_override("separation", 12)
	overlay_panel.add_child(overlay_box)

	overlay_title = Label.new()
	overlay_title.add_theme_font_size_override("font_size", 32)
	overlay_box.add_child(overlay_title)
	overlay_body = Label.new()
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_box.add_child(overlay_body)

	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.pressed.connect(func() -> void:
		paused = false
		_update_overlay(false)
	)
	overlay_box.add_child(resume_button)

	retry_button = Button.new()
	retry_button.text = "Retry Encounter"
	retry_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
	)
	overlay_box.add_child(retry_button)

	menu_button = Button.new()
	menu_button.text = "Return to Title"
	menu_button.pressed.connect(func() -> void:
		_run_state().selected_encounter_id = ""
		get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
	)
	overlay_box.add_child(menu_button)

	_update_ui()

func _update_overlay(visible: bool, title_text: String = "", body_text: String = "") -> void:
	overlay_backdrop.visible = visible
	overlay_panel.visible = visible
	overlay_title.text = title_text
	overlay_body.text = body_text
	resume_button.visible = paused and not finished

func _update_ui() -> void:
	if player == null:
		return
	var nearest = _get_nearest_enemy()
	header_label.text = "%s | %s | Wave %s/%s" % [habitat.display_name, difficulty.display_name, wave_index, encounter.wave_count]
	stats_label.text = "HP %.0f/%.0f  SH %.0f/%.0f\nAffinity: %s  Status: %s" % [
		player.health,
		player.max_health,
		player.shield,
		player.max_shield,
		player.element_id.capitalize(),
		player.get_status_summary()
	]
	if nearest:
		target_label.text = "Nearest target: %s\nHP %.0f  SH %.0f  Status: %s" % [
			nearest.entity_name,
			nearest.health,
			nearest.shield,
			nearest.get_status_summary()
		]
	else:
		target_label.text = "Nearest target: none"
	if not finished and not paused:
		objective_label.text = "Survive %s waves. Active enemies: %s" % [encounter.wave_count, enemies.size()]

func _get_nearest_enemy():
	var nearest = null
	var nearest_distance = INF
	for enemy in enemies:
		if enemy == null or not enemy.alive:
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func _generate_background_points() -> void:
	background_points.clear()
	for _i in range(28):
		background_points.append(Vector2(
			rng.randf_range(arena_rect.position.x + 20.0, arena_rect.end.x - 20.0),
			rng.randf_range(arena_rect.position.y + 20.0, arena_rect.end.y - 20.0)
		))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), habitat.ambient_color)
	draw_rect(arena_rect, habitat.palette_primary.darkened(0.72), true)
	draw_rect(arena_rect.grow(8.0), habitat.palette_secondary.darkened(0.32), false, 4.0)
	for point in background_points:
		draw_circle(point, 3.0, habitat.palette_secondary)
	for zone in hazard_zones:
		var zone_position = zone.get("position", Vector2.ZERO)
		var zone_radius = float(zone.get("radius", 0.0))
		draw_circle(zone_position, zone_radius, habitat.palette_secondary.darkened(0.2))
		draw_arc(zone_position, zone_radius, 0.0, TAU, 42, habitat.palette_primary.lightened(0.25), 4.0)
