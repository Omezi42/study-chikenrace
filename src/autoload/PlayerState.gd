# PlayerState.gd
extends Node

signal data_changed

var player_name: String = ""

func save_data_to_dict() -> Dictionary:
	return {
		"player_name": player_name
	}

func load_data_from_dict(data: Dictionary) -> void:
	if "player_name" in data: player_name = str(data["player_name"])
	data_changed.emit()
