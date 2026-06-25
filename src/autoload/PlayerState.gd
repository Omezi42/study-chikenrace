# PlayerState.gd
extends Node

signal data_changed

var player_name: String = ""
var is_tutorial_completed: bool = false

func save_data_to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"is_tutorial_completed": is_tutorial_completed
	}

func load_data_from_dict(data: Dictionary) -> void:
	if "player_name" in data: player_name = str(data["player_name"])
	if "is_tutorial_completed" in data: is_tutorial_completed = bool(data["is_tutorial_completed"])
	data_changed.emit()
