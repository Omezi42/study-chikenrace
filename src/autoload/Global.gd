extends Node

const SAVE_PATH = "user://savegame.json"

# Player Progression & Saved Stats
var player_name: String = ""
var coins: int = 100
var best_score: int = 0
var play_count: int = 0
var is_tutorial_mode: bool = false
var bgm_volume: float = 0.5
var se_volume: float = 0.5
var is_muted: bool = false

# Active Game Mode ("cpu", "national", "daily", or "friend")
var game_mode: String = "cpu"

# Friend Match Room State
var friend_room_code: String = ""
var friend_is_host: bool = false
var friend_member_list: Array = []
var friend_current_day: int = 1
var friend_match_history: Dictionary = {}

# Cloud Session Info
var logged_in_user_id: String = ""
var logged_in_password: String = ""

# Daily Exam State
var daily_current_day: int = 1
var daily_last_played_date: String = ""
var daily_opponent_ghosts: Dictionary = {}  # DayIndex -> Array of ghosts
var daily_my_records: Dictionary = {}       # DayIndex -> My record dict
var daily_fixed_deck: Dictionary = {}       # Generated fixed deck (1-10 -> ItemId)

# Deviation Values (偏差値)
var deviation_value: float = 50.0
var max_deviation_value: float = 50.0

# Opponent profiles for the active match
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

# Cards unlocked by player (default 10 starting items)
var unlocked_items: Array[String] = [
	"item_sticky_note",
	"item_eraser",
	"item_ruler",
	"item_wordbook",
	"item_mech_pencil",
	"item_memo_cards",
	"item_highlighter",
	"item_blue_pen",
	"item_cushion",
	"item_memo_app"
]

# Track usage of items (ID -> usage count)
var item_usage_counts: Dictionary = {}

# Current Deck (which items are slotted into 1 to 10 slots)
# Defaults to mapping slots 1-10 to our 10 starting items
var current_deck: Dictionary = {
	1: "item_sticky_note",
	2: "item_eraser",
	3: "item_ruler",
	4: "item_wordbook",
	5: "item_mech_pencil",
	6: "item_memo_cards",
	7: "item_highlighter",
	8: "item_blue_pen",
	9: "item_cushion",
	10: "item_memo_app"
}

# Unlocked titles
var unlocked_titles: Array[String] = []

# Showdown results to pass between scenes
var active_showdown_results: Dictionary = {}

func _ready() -> void:
	load_game()
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.load_completed.connect(_on_cloud_load_completed)
	if logged_in_user_id != "" and logged_in_password != "":
		call_deferred("_auto_login")

# Save Game state to local storage JSON
func save_game() -> void:
	var save_dict = {
		"player_name": player_name,
		"coins": coins,
		"best_score": best_score,
		"play_count": play_count,
		"unlocked_items": unlocked_items,
		"item_usage_counts": item_usage_counts,
		"unlocked_titles": unlocked_titles,
		"deviation_value": deviation_value,
		"max_deviation_value": max_deviation_value,
		"game_mode": game_mode,
		"opponent_profiles": opponent_profiles,
		"bgm_volume": bgm_volume,
		"se_volume": se_volume,
		"is_muted": is_muted,
		# Save deck as string keys because JSON dictionary keys are always strings
		"current_deck": get_deck_as_string_keys(),
		"logged_in_user_id": logged_in_user_id,
		"logged_in_password": logged_in_password,
		"daily_current_day": daily_current_day,
		"daily_last_played_date": daily_last_played_date,
		"daily_opponent_ghosts": daily_opponent_ghosts,
		"daily_my_records": daily_my_records,
		"daily_fixed_deck": get_daily_fixed_deck_as_string_keys(),
		"friend_room_code": friend_room_code,
		"friend_is_host": friend_is_host,
		"friend_member_list": friend_member_list,
		"friend_current_day": friend_current_day,
		"friend_match_history": friend_match_history
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict)
		file.store_string(json_string)
		file.close()
		
	# Silent cloud save if logged in
	if logged_in_user_id != "" and has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if bm.auth_token != "":
			bm.save_cloud_data(save_dict)

# Load Game state from local storage JSON
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.get_data()
			if data is Dictionary:
				if "player_name" in data: player_name = data["player_name"]
				if "coins" in data: coins = int(data["coins"])
				if "best_score" in data: best_score = int(data["best_score"])
				if "play_count" in data: play_count = int(data["play_count"])
				if "deviation_value" in data: deviation_value = float(data["deviation_value"])
				if "max_deviation_value" in data: max_deviation_value = float(data["max_deviation_value"])
				if "game_mode" in data: game_mode = str(data["game_mode"])
				if "opponent_profiles" in data: opponent_profiles = data["opponent_profiles"]
				
				if "unlocked_items" in data:
					unlocked_items.clear()
					for item in data["unlocked_items"]:
						unlocked_items.append(str(item))
						
				if "item_usage_counts" in data:
					item_usage_counts = data["item_usage_counts"]
					
				if "unlocked_titles" in data:
					unlocked_titles.clear()
					for title in data["unlocked_titles"]:
						unlocked_titles.append(str(title))
						
				if "current_deck" in data:
					var deck_data = data["current_deck"]
					for key in deck_data.keys():
						current_deck[int(key)] = str(deck_data[key])
						
				if "bgm_volume" in data: bgm_volume = float(data["bgm_volume"])
				if "se_volume" in data: se_volume = float(data["se_volume"])
				if "is_muted" in data: is_muted = bool(data["is_muted"])
				
				# Load Cloud & Daily data
				if "logged_in_user_id" in data: logged_in_user_id = str(data["logged_in_user_id"])
				if "logged_in_password" in data: logged_in_password = str(data["logged_in_password"])
				if "daily_current_day" in data: daily_current_day = int(data["daily_current_day"])
				if "daily_last_played_date" in data: daily_last_played_date = str(data["daily_last_played_date"])
				if "daily_opponent_ghosts" in data: daily_opponent_ghosts = data["daily_opponent_ghosts"]
				if "daily_my_records" in data: daily_my_records = data["daily_my_records"]
				if "daily_fixed_deck" in data:
					var fd_data = data["daily_fixed_deck"]
					daily_fixed_deck.clear()
					for k in fd_data.keys():
						daily_fixed_deck[int(k)] = str(fd_data[k])
						
				if "friend_room_code" in data: friend_room_code = str(data["friend_room_code"])
				if "friend_is_host" in data: friend_is_host = bool(data["friend_is_host"])
				if "friend_member_list" in data: friend_member_list = data["friend_member_list"]
				if "friend_current_day" in data: friend_current_day = int(data["friend_current_day"])
				if "friend_match_history" in data: friend_match_history = data["friend_match_history"]
						
		# Ensure all 10 slots are populated in case of load anomalies
		validate_current_deck()
		validate_opponent_profiles()
		
		# Apply loaded volumes to AudioManager if available
		if has_node("/root/AudioManager"):
			var audio = get_node("/root/AudioManager")
			audio.bgm_volume = bgm_volume
			audio.se_volume = se_volume
			audio.is_muted = is_muted

func get_deck_as_string_keys() -> Dictionary:
	var string_deck = {}
	for key in current_deck.keys():
		string_deck[str(key)] = current_deck[key]
	return string_deck

func validate_current_deck() -> void:
	var assigned: Array[String] = []
	for i in range(1, 11):
		var item = current_deck.get(i, "")
		if item == "" or not item in unlocked_items or item in assigned:
			# Find an unlocked item that isn't assigned yet
			var found = false
			for u_item in unlocked_items:
				if not u_item in assigned:
					current_deck[i] = u_item
					assigned.append(u_item)
					found = true
					break
			if not found:
				current_deck[i] = "item_sticky_note"
				assigned.append("item_sticky_note")
		else:
			assigned.append(item)

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
				"name": "佐藤くん",
				"deviation": 50.0
			}
			continue
		if not opponent_profiles[key].has("id"):
			opponent_profiles[key]["id"] = default_ids.get(key, "cpu_sato")

# Select 3 random CPU opponents from the pool of 6, and assign them to active match slots
func select_random_opponents() -> void:
	var pool_keys = AIManager.CPU_OPPONENTS.keys().duplicate()
	pool_keys.shuffle()
	
	var selected_keys = pool_keys.slice(0, 3)
	var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
	for i in range(3):
		var target_slot = slots[i]
		var source_key = selected_keys[i]
		var profile = AIManager.CPU_OPPONENTS[source_key]
		
		opponent_profiles[target_slot] = {
			"id": source_key,
			"name": profile["name"],
			"deviation": clamp(deviation_value + randf_range(-6.0, 6.0), 35.0, 80.0)
		}
	save_game()

# Metagame Mechanics

# Unlock an item (Gacha)
func unlock_item(item_id: String) -> bool:
	if not item_id in unlocked_items:
		unlocked_items.append(item_id)
		save_game()
		return true # Newly unlocked
	return false # Already unlocked

# Add item usage (both during play and on Gacha duplicate)
func add_item_usage(item_id: String, amount: int = 1) -> void:
	if not item_id in item_usage_counts:
		item_usage_counts[item_id] = 0
	item_usage_counts[item_id] = int(item_usage_counts[item_id]) + amount
	save_game()

# Star progression:
# ★1: 5回、★2: 30回、★3: 100回、★4: 500回、★5: 3000回
func get_item_stars(item_id: String) -> int:
	var usage = int(item_usage_counts.get(item_id, 0))
	if usage >= 3000:
		return 5
	elif usage >= 500:
		return 4
	elif usage >= 100:
		return 3
	elif usage >= 30:
		return 2
	elif usage >= 5:
		return 1
	return 0

# Get Star requirements text
func get_star_requirement(star_num: int) -> int:
	match star_num:
		1: return 5
		2: return 30
		3: return 100
		4: return 500
		5: return 3000
	return 0

# Returns total stars across all unlocked items
func get_total_stars() -> int:
	var total = 0
	for item_id in unlocked_items:
		total += get_item_stars(item_id)
	return total

# Truncated level bonus score (total stars * 0.1, truncated to integer)
func get_total_level_bonus() -> int:
	var total_stars = get_total_stars()
	return int(floor(total_stars * 0.1))

# Global helper to perform smooth scene changes with a paper fade overlay
func change_scene_with_fade(tree: SceneTree, target_scene_path: String, duration: float = 0.35) -> void:
	# Create CanvasLayer to overlay transition
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	tree.root.add_child(canvas)
	
	var fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color("eddcc9") # Bright paper color
	fade_rect.modulate.a = 0.0
	canvas.add_child(fade_rect)
	
	# Fade out current scene
	var tween = tree.create_tween().bind_node(fade_rect)
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	tween.tween_callback(func():
		# Change scene
		tree.change_scene_to_file(target_scene_path)
		
		# Fade in new scene
		var tween_in = tree.create_tween().bind_node(fade_rect)
		tween_in.tween_property(fade_rect, "modulate:a", 0.0, duration)
		tween_in.tween_callback(func():
			canvas.queue_free()
		)
	)

func _auto_login() -> void:
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.login_user(logged_in_user_id, logged_in_password)

func _on_cloud_load_completed(success: bool, cloud_data: Dictionary) -> void:
	if success and cloud_data.size() > 0:
		if "player_name" in cloud_data: player_name = cloud_data["player_name"]
		if "coins" in cloud_data: coins = int(cloud_data["coins"])
		if "best_score" in cloud_data: best_score = int(cloud_data["best_score"])
		if "play_count" in cloud_data: play_count = int(cloud_data["play_count"])
		if "deviation_value" in cloud_data: deviation_value = float(cloud_data["deviation_value"])
		if "max_deviation_value" in cloud_data: max_deviation_value = float(cloud_data["max_deviation_value"])
		
		if "unlocked_items" in cloud_data:
			unlocked_items.clear()
			for item in cloud_data["unlocked_items"]:
				unlocked_items.append(str(item))
				
		if "item_usage_counts" in cloud_data:
			item_usage_counts = cloud_data["item_usage_counts"]
			
		if "unlocked_titles" in cloud_data:
			unlocked_titles.clear()
			for title in cloud_data["unlocked_titles"]:
				unlocked_titles.append(str(title))
				
		if "current_deck" in cloud_data:
			var deck_data = cloud_data["current_deck"]
			for key in deck_data.keys():
				current_deck[int(key)] = str(deck_data[key])
				
		if "daily_current_day" in cloud_data: daily_current_day = int(cloud_data["daily_current_day"])
		if "daily_last_played_date" in cloud_data: daily_last_played_date = str(cloud_data["daily_last_played_date"])
		if "daily_opponent_ghosts" in cloud_data: daily_opponent_ghosts = cloud_data["daily_opponent_ghosts"]
		if "daily_my_records" in cloud_data: daily_my_records = cloud_data["daily_my_records"]
		if "daily_fixed_deck" in cloud_data:
			var fd_data = cloud_data["daily_fixed_deck"]
			daily_fixed_deck.clear()
			for k in fd_data.keys():
				daily_fixed_deck[int(k)] = str(fd_data[k])
				
		validate_current_deck()
		save_game()

func get_daily_fixed_deck_as_string_keys() -> Dictionary:
	var string_deck = {}
	for key in daily_fixed_deck.keys():
		string_deck[str(key)] = daily_fixed_deck[key]
	return string_deck

func generate_daily_fixed_deck(date_str: String) -> Dictionary:
	var seed_val = hash(date_str)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	var all_items = []
	if ResourceLoader.exists("res://src/data/CardData.gd"):
		var card_data_script = load("res://src/data/CardData.gd")
		var inst = card_data_script.new()
		if inst and "ITEMS" in inst:
			all_items = inst.ITEMS.keys().duplicate()
		inst.queue_free()
	
	if all_items.size() < 10:
		all_items = unlocked_items.duplicate()
		
	all_items.sort()
	
	var shuffled = []
	var pool = all_items.duplicate()
	while pool.size() > 0:
		var idx = rng.randi() % pool.size()
		shuffled.append(pool[idx])
		pool.remove_at(idx)
		
	var deck = {}
	for i in range(1, 11):
		deck[i] = shuffled[i - 1]
		
	return deck
