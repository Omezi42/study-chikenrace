# MatchState.gd
extends Node


var game_mode: String = "national"
var active_showdown_results: Dictionary = {}
var current_match_actions: Dictionary = {}

signal player_action_received(player_id: int, action: String, data: Dictionary)
signal game_state_synced(state: Dictionary)

@rpc("any_peer", "call_local")
func submit_player_action(action: String, data: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
		
	var day = data.get("day", 1)
	if not current_match_actions.has(day):
		current_match_actions[day] = {}
	if not current_match_actions[day].has(sender_id):
		current_match_actions[day][sender_id] = {}
		
	current_match_actions[day][sender_id][action] = data
		
	player_action_received.emit(sender_id, action, data)

@rpc("authority", "call_remote")
func sync_game_state(state: Dictionary) -> void:
	game_state_synced.emit(state)


var opponent_profiles: Dictionary = {
	"cpu_sato": {
		"id": "cpu_sato",
		"name": "佐藤くん"
	},
	"cpu_suzuki": {
		"id": "cpu_suzuki",
		"name": "鈴木さん"
	},
	"cpu_takahashi": {
		"id": "cpu_takahashi",
		"name": "高橋くん"
	}
}

func reset_match() -> void:
	active_showdown_results.clear()
	current_match_actions.clear()

func save_data_to_dict() -> Dictionary:
	return {
		"game_mode": game_mode,
		"opponent_profiles": opponent_profiles.duplicate(true)
	}

func load_data_from_dict(data: Dictionary) -> void:
	if "game_mode" in data: game_mode = str(data["game_mode"])
	if "opponent_profiles" in data and data["opponent_profiles"] is Dictionary:
		opponent_profiles = data["opponent_profiles"].duplicate(true)
