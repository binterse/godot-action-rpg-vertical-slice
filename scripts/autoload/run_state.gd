extends Node

var selected_habitat_id: String = "orbital_wreckage"
var selected_difficulty_id: String = "ranger"
var selected_encounter_id: String = ""
var player_element_id: String = "thermal"
var last_result: String = ""
var last_reward: int = 0

func reset_outcome() -> void:
	last_result = ""
	last_reward = 0

func configure_run(habitat_id: String, difficulty_id: String, player_element: String) -> void:
	selected_habitat_id = habitat_id
	selected_difficulty_id = difficulty_id
	player_element_id = player_element
	reset_outcome()
	var encounter_ids = GameDB.get_matching_encounter_ids(habitat_id, difficulty_id)
	selected_encounter_id = encounter_ids[0] if encounter_ids.size() > 0 else ""

func get_selected_encounter():
	if selected_encounter_id == "":
		var encounter_ids = GameDB.get_matching_encounter_ids(selected_habitat_id, selected_difficulty_id)
		selected_encounter_id = encounter_ids[0] if encounter_ids.size() > 0 else ""
	return GameDB.get_encounter(selected_encounter_id)
