extends Control

var habitat_select: OptionButton
var difficulty_select: OptionButton
var element_select: OptionButton
var preview_label: Label
var result_label: Label
var validation_label: Label

func _db() -> Node:
	return get_node("/root/GameDB")

func _run_state() -> Node:
	return get_node("/root/RunState")

func _ready() -> void:
	_db().load_all()
	_build_ui()
	_populate_options()
	_refresh_preview()
	_maybe_auto_start()

func _build_ui() -> void:
	var theme_resource = _db().get_default_theme()
	var background := ColorRect.new()
	background.color = theme_resource.background if theme_resource else Color("09111d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 64)
	frame.add_theme_constant_override("margin_top", 42)
	frame.add_theme_constant_override("margin_right", 64)
	frame.add_theme_constant_override("margin_bottom", 42)
	add_child(frame)

	var layout := HBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 28)
	frame.add_child(layout)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(680, 760)
	layout.add_child(left_panel)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 16)
	left_panel.add_child(left_box)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(280, 120)
	var badge_text := Label.new()
	badge_text.text = "VX-12\nTACTICAL GRID"
	badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_text.add_theme_font_size_override("font_size", 22)
	badge.add_child(badge_text)
	left_box.add_child(badge)

	var title := Label.new()
	title.text = "STRIDSYSTEM"
	title.add_theme_font_size_override("font_size", 42)
	left_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Portable sci-fi action RPG combat slice built from structured resources."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 18)
	left_box.add_child(subtitle)

	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(result_label)

	validation_label = Label.new()
	validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(validation_label)

	var controls := Label.new()
	controls.text = "Controls in combat: WASD move, Space dodge, LMB light, RMB heavy, E tech shot, C cleanse, Esc pause."
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(controls)

	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(520, 760)
	layout.add_child(right_panel)
	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 14)
	right_panel.add_child(right_box)

	var selector_title := Label.new()
	selector_title.text = "Deployment Console"
	selector_title.add_theme_font_size_override("font_size", 28)
	right_box.add_child(selector_title)

	habitat_select = _build_selector(right_box, "Habitat")
	difficulty_select = _build_selector(right_box, "Difficulty")
	element_select = _build_selector(right_box, "Player Element")

	preview_label = Label.new()
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.custom_minimum_size = Vector2(440, 220)
	right_box.add_child(preview_label)

	var start_button := Button.new()
	start_button.text = "Launch Encounter"
	start_button.custom_minimum_size = Vector2(0, 54)
	start_button.pressed.connect(_on_start_pressed)
	right_box.add_child(start_button)

func _build_selector(parent: VBoxContainer, label_text: String) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var selector := OptionButton.new()
	selector.item_selected.connect(_refresh_preview)
	parent.add_child(selector)
	return selector

func _populate_options() -> void:
	for habitat in _db().sorted_values(_db().habitats):
		habitat_select.add_item(habitat.display_name)
		habitat_select.set_item_metadata(habitat_select.item_count - 1, habitat.id)
	for difficulty in _db().sorted_values(_db().difficulties):
		difficulty_select.add_item(difficulty.display_name)
		difficulty_select.set_item_metadata(difficulty_select.item_count - 1, difficulty.id)
	for element in _db().sorted_values(_db().elements):
		element_select.add_item(element.display_name)
		element_select.set_item_metadata(element_select.item_count - 1, element.id)
	var validation = _db().validate_database()
	habitat_select.select(0)
	difficulty_select.select(1 if difficulty_select.item_count > 1 else 0)
	element_select.select(4 if element_select.item_count > 4 else 0)
	if bool(validation.get("ok", false)):
		validation_label.text = "Database check: 5 elements, 4 ailments, 6 difficulties, 12 habitats, 255 enemy variants online."
	else:
		validation_label.text = "Database issues: %s" % ", ".join(validation.get("errors", PackedStringArray()))
	if _run_state().last_result != "":
		result_label.text = "Previous run: %s (%s credits)" % [_run_state().last_result, _run_state().last_reward]

func _refresh_preview(_index: int = 0) -> void:
	if habitat_select.item_count == 0 or difficulty_select.item_count == 0 or element_select.item_count == 0:
		return
	var habitat_id = str(habitat_select.get_item_metadata(habitat_select.selected))
	var difficulty_id = str(difficulty_select.get_item_metadata(difficulty_select.selected))
	var element_id = str(element_select.get_item_metadata(element_select.selected))
	var habitat = _db().get_habitat(habitat_id)
	var difficulty = _db().get_difficulty(difficulty_id)
	var element = _db().get_element(element_id)
	var habitat_enemy_count = _db().get_habitat_enemy_ids(habitat_id).size()
	preview_label.text = "%s\n\n%s\n\nThreat level: %s\nPlayer affinity: %s\nHabitat-compatible enemies: %s\nHazard: %s / %s" % [
		habitat.display_name,
		habitat.summary,
		difficulty.display_name,
		element.display_name,
		habitat_enemy_count,
		habitat.hazard_element_id.capitalize(),
		habitat.hazard_ailment_id.capitalize()
	]

func _on_start_pressed() -> void:
	_run_state().configure_run(
		str(habitat_select.get_item_metadata(habitat_select.selected)),
		str(difficulty_select.get_item_metadata(difficulty_select.selected)),
		str(element_select.get_item_metadata(element_select.selected))
	)
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _maybe_auto_start() -> void:
	if "--auto-start-combat" not in OS.get_cmdline_args():
		return
	_run_state().configure_run("orbital_wreckage", "ranger", "thermal")
	call_deferred("_launch_auto_combat")

func _launch_auto_combat() -> void:
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
