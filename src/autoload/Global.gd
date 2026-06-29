extends Node

var cpu_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var show_title_splash: bool = true

var player_name: String:
	get: return PlayerState.player_name
	set(val): PlayerState.player_name = val

var bgm_volume: float:
	get: return SettingsState.bgm_volume
	set(val): SettingsState.bgm_volume = val
var se_volume: float:
	get: return SettingsState.se_volume
	set(val): SettingsState.se_volume = val
var is_muted: bool:
	get: return SettingsState.is_muted
	set(val): SettingsState.is_muted = val

var game_mode: String:
	get: return MatchState.game_mode
	set(val): MatchState.game_mode = val

var friend_room_code: String = ""
var friend_is_host: bool = false
var friend_member_list: Array[Dictionary] = []
var friend_current_day: int = 1
var friend_match_history: Dictionary = {}
var return_to_friend_lobby: bool = false

var cpu_difficulty: String = "normal"

var is_tutorial_mode: bool = false

var total_doubt_successes: int = 0
var total_doubt_failures: int = 0
var opponent_profiles: Dictionary:
	get: return MatchState.opponent_profiles
	set(val): MatchState.opponent_profiles = val

var active_showdown_results: Dictionary:
	get: return MatchState.active_showdown_results
	set(val): MatchState.active_showdown_results = val

func _ready() -> void:
	cpu_rng.randomize()
	load_game()
	
	if OS.has_feature("web"):
		var js_window = JavaScriptBridge.get_interface("window")
		if js_window:
			var test_val = js_window.is_antigravity_test
			if test_val != null and test_val:
				pass

	var network_ui = load("res://src/ui/NetworkStatusUI.gd").new()
	add_child(network_ui)

const SIMPLE_SAVE_FIELDS = [
	"player_name", "bgm_volume", "se_volume", "is_muted",
	"game_mode", "friend_room_code", "friend_is_host", "friend_member_list",
	"total_doubt_successes", "total_doubt_failures"
]

func save_game() -> void:
	var save_dict = {}
	
	var player_data = PlayerState.save_data_to_dict()
	var settings_data = SettingsState.save_data_to_dict()
	var match_data = MatchState.save_data_to_dict()
	
	for k in player_data.keys():
		save_dict[k] = player_data[k]
	for k in settings_data.keys():
		save_dict[k] = settings_data[k]
	for k in match_data.keys():
		save_dict[k] = match_data[k]
		
	for field in SIMPLE_SAVE_FIELDS:
		if not field in save_dict:
			var val = get(field)
			if val is Array or val is Dictionary:
				save_dict[field] = val.duplicate(true)
			else:
				save_dict[field] = val
				
	save_dict["save_version"] = Constants.SAVE_VERSION
	
	validate_opponent_profiles()
	
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game(save_dict)

func load_game() -> void:
	var loaded_data = {}
	if has_node("/root/SaveManager"):
		loaded_data = get_node("/root/SaveManager").load_game()
		
	if loaded_data.is_empty():
		save_game()
		return
		
	var data = loaded_data
	
	PlayerState.load_data_from_dict(data)
	SettingsState.load_data_from_dict(data)
	MatchState.load_data_from_dict(data)
	
	for field in SIMPLE_SAVE_FIELDS:
		if field in data and not field in ["player_name", "bgm_volume", "se_volume", "is_muted", "game_mode", "opponent_profiles"]:
			var val = data[field]
			var current_val = get(field)
			if current_val is int:
				set(field, int(val))
			elif current_val is float:
				set(field, float(val))
			elif current_val is bool:
				set(field, bool(val))
			elif current_val is Array:
				current_val.clear()
				if val is Array:
					for item in val:
						current_val.append(item)
			else:
				set(field, val)
				
	validate_opponent_profiles()
	
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.bgm_volume = SettingsState.bgm_volume
		audio.se_volume = SettingsState.se_volume
		audio.is_muted = SettingsState.is_muted

func validate_opponent_profiles() -> void:
	var default_ids = {
		"cpu_sato": "cpu_sato",
		"cpu_suzuki": "cpu_suzuki",
		"cpu_takahashi": "cpu_takahashi"
	}
	for key in opponent_profiles.keys():
		if not opponent_profiles[key] is Dictionary:
			opponent_profiles[key] = {
				"id": default_ids.get(key, "cpu_sato"),
				"name": "佐藤くん"
			}
			continue
		if not opponent_profiles[key].has("id"):
			opponent_profiles[key]["id"] = default_ids.get(key, "cpu_sato")
		if not opponent_profiles[key].has("name") or str(opponent_profiles[key]["name"]) == "":
			opponent_profiles[key]["name"] = AIManager.get_cpu_name(opponent_profiles[key]["id"])

func get_default_participant_record(participant_id: String, display_name: String = "") -> Dictionary:
	var name_to_use = display_name
	if name_to_use == "":
		if participant_id == "player":
			name_to_use = player_name if player_name != "" else "あなた"
		elif opponent_profiles.has(participant_id):
			name_to_use = opponent_profiles[participant_id].get("name", "ライバル")
		else:
			name_to_use = AIManager.get_cpu_name(participant_id)

	return {
		"id": participant_id,
		"name": name_to_use,
		"actual_score": 0,
		"declared_score": 0,
		"hours": [],
		"doubts_made": [],
		"doubts_received": [],
		"is_doubt_exposed": false,
		"auto_exposed": false
	}

func normalize_participant_record(record: Variant, participant_id: String, display_name: String = "") -> Dictionary:
	var norm = get_default_participant_record(participant_id, display_name)
	if not (record is Dictionary):
		return norm
	
	var d = record
	if d.has("record") and d["record"] is Dictionary:
		var rec = d["record"]
		for k in rec.keys():
			if not d.has(k) or d[k] == null or (d[k] is String and d[k] == ""):
				d[k] = rec[k]

	var raw_hours = d.get("hours_history", d.get("hours", []))
	if not (raw_hours is Array):
		raw_hours = []

	var raw_doubts = d.get("doubts_made", [])
	if not (raw_doubts is Array):
		raw_doubts = []
	var norm_doubts = []
	for db in raw_doubts:
		norm_doubts.append(str(db))

	var raw_received = d.get("doubts_received", [])
	if not (raw_received is Array):
		raw_received = []
	var norm_received = []
	for dr in raw_received:
		norm_received.append(str(dr))

	var resolved_name = str(d.get("username", d.get("name", d.get("player_name", norm["name"]))))
	var resolved_uid = str(d.get("user_id", d.get("id", participant_id)))

	return {
		"id": resolved_uid,
		"name": resolved_name,
		"actual_score": clampi(int(d.get("actual_score", 0)), 0, 9999),
		"declared_score": clampi(int(d.get("declared_score", 0)), 0, 9999),
		"hours": raw_hours,
		"doubts_made": norm_doubts,
		"doubts_received": norm_received,
		"is_doubt_exposed": bool(d.get("is_doubt_exposed", false)),
		"auto_exposed": bool(d.get("auto_exposed", false)),
		"emote": str(d.get("emote", "normal"))
	}

func normalize_day_record(day_record: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if not (day_record is Dictionary):
		return normalized
	for p_id in day_record.keys():
		normalized[str(p_id)] = normalize_participant_record(day_record[p_id], str(p_id))
	return normalized

func select_random_opponents() -> void:
	var pool_keys = AIManager.CPU_OPPONENTS.keys().duplicate()
	pool_keys.shuffle()
	
	var selected_keys = pool_keys.slice(0, 3)
	var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
	for i in range(3):
		var target_slot = slots[i]
		var source_key = selected_keys[i]
		var profile = AIManager.get_cpu_info(source_key)
		
		opponent_profiles[target_slot] = {
			"id": source_key,
			"name": profile.get("name", source_key)
		}
	save_game()

func change_scene_with_fade(tree: SceneTree, target_scene_path: String, duration: float = 0.35) -> void:
	if has_node("/root/UIHelper"):
		get_node("/root/UIHelper").change_scene_with_fade(tree, target_scene_path, duration)

func apply_white_button_style(btn: Button) -> void:
	if has_node("/root/UIHelper"):
		get_node("/root/UIHelper").apply_white_button_style(btn)

func show_loading(text: String = "通信中...") -> void:
	if has_node("/root/UIHelper"):
		get_node("/root/UIHelper").show_loading(text)

func hide_loading() -> void:
	if has_node("/root/UIHelper"):
		get_node("/root/UIHelper").hide_loading()

func show_tutorial_dialog(parent: Control, text: String, pos: Vector2 = Vector2.ZERO, next_callback: Callable = Callable()) -> Node:
	if has_node("/root/UIHelper"):
		return get_node("/root/UIHelper").show_tutorial_dialog(parent, text, pos, next_callback)
	return null
