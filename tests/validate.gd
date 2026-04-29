extends SceneTree

func _init() -> void:
	var errors: PackedStringArray = PackedStringArray()
	var db_script = load("res://scripts/autoload/game_db.gd")
	var db = db_script.new()
	root.add_child(db)
	db.load_all()
	var validation = db.validate_database()
	if not bool(validation.get("ok", false)):
		for error_text in validation.get("errors", PackedStringArray()):
			errors.append(str(error_text))
	if load("res://scenes/TitleScreen.tscn") == null:
		errors.append("TitleScreen scene failed to load")
	if load("res://scenes/CombatScene.tscn") == null:
		errors.append("CombatScene scene failed to load")
	if load("res://scenes/Player.tscn") == null:
		errors.append("Player scene failed to load")
	if load("res://scenes/Enemy.tscn") == null:
		errors.append("Enemy scene failed to load")
	for habitat in db.sorted_values(db.habitats):
		for difficulty in db.sorted_values(db.difficulties):
			var encounter_ids = db.get_matching_encounter_ids(habitat.id, difficulty.id)
			if encounter_ids.is_empty():
				errors.append("Missing encounter for %s / %s" % [habitat.id, difficulty.id])
	if errors.is_empty():
		print("Validation passed")
		quit(0)
		return
	for error_text in errors:
		push_error(error_text)
		print(error_text)
	quit(1)
