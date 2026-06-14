# MatchState.gd
extends Node

var game_mode: String = "national"
var active_showdown_results: Dictionary = {}

var opponent_profiles: Dictionary = {
	"cpu_sato": {
		"id": "cpu_sato",
		"name": "佐藤くん",
		"deviation": 51.5
	},
	"cpu_suzuki": {
		"id": "cpu_suzuki",
		"name": "鈴木さん",
		"deviation": 48.0
	},
	"cpu_takahashi": {
		"id": "cpu_takahashi",
		"name": "高橋くん",
		"deviation": 54.2
	}
}

func reset_match() -> void:
	active_showdown_results.clear()

func save_data_to_dict() -> Dictionary:
	return {
		"game_mode": game_mode,
		"opponent_profiles": opponent_profiles.duplicate(true)
	}

func load_data_from_dict(data: Dictionary) -> void:
	if "game_mode" in data: game_mode = str(data["game_mode"])
	if "opponent_profiles" in data and data["opponent_profiles"] is Dictionary:
		opponent_profiles = data["opponent_profiles"].duplicate(true)
