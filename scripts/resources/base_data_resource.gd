extends Resource
class_name BaseDataResource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var summary: String = ""

func get_label() -> String:
	return display_name if display_name != "" else id.capitalize()

