extends Node

var _preloaded_font = preload("res://assets/hgrsmp.ttf")

# Player Progression & Saved Stats
var player_name: String = ""
var player_title: String = "ただの凡人"
var coins: int = 100
var best_score: int = 0
var play_count: int = 0
var is_tutorial_mode: bool = false
var bgm_volume: float = 0.5
var se_volume: float = 0.5
var is_muted: bool = false
var deck_presets: Dictionary = {
	"1": {},
	"2": {},
	"3": {}
}
var deck_preset_names: Dictionary = {
	"1": "プリセット 1",
	"2": "プリセット 2",
	"3": "プリセット 3"
}
var selected_preset_idx: int = 1

# Accumulated Lifetime Stats
var total_doubt_successes: int = 0
var total_doubt_failures: int = 0
var total_burst_count: int = 0
var total_perfect_crimes: int = 0

# Active Game Mode ("cpu", "national", "daily", or "friend")
var game_mode: String = Constants.MODE_NATIONAL

# Friend Match Room State
var friend_room_code: String = ""
var friend_is_host: bool = false
var friend_member_list: Array[Dictionary] = []
var friend_current_day: int = 1
var friend_match_history: Dictionary = {}

# Cloud Session Info
var logged_in_user_id: String = ""
var auth_token: String = ""

# Daily Exam State
var daily_current_day: int = 1
var daily_last_played_date: String = ""
var daily_opponent_ghosts: Dictionary = {}  # DayIndex -> Array of ghosts
var daily_my_records: Dictionary = {}       # DayIndex -> My record dict
var daily_fixed_deck: Dictionary = {}       # Generated fixed deck (1-10 -> ItemId)
var current_season: int = 1                 # 1シーズン=2週間
var today_missions: Array[Dictionary] = []
var mission_progress: Dictionary = {}
var last_mission_date: String = ""

# Deviation Values (偏差値)
var deviation_value: float = 50.0
var max_deviation_value: float = 50.0
var selected_class: String = "regular" # "remedial", "regular", "advanced"
var last_updated_at: float = 0.0

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
	
	# 自動テスト時、初回起動のチュートリアル強制遷移を回避するために play_count を 1 に補正する
	if OS.has_feature("web"):
		var js_window = JavaScriptBridge.get_interface("window")
		if js_window:
			var test_val = js_window.is_antigravity_test
			if test_val != null and test_val:
				if play_count == 0:
					play_count = 1

	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.load_completed.connect(_on_cloud_load_completed)
		bm.auth_completed.connect(_on_auth_completed)
	if logged_in_user_id != "" and auth_token != "":
		call_deferred("_auto_login")
		
	# Check for season reset
	_check_season_reset()
	
	# Instantiate NetworkStatusUI
	var network_ui = load("res://src/ui/NetworkStatusUI.gd").new()
	add_child(network_ui)

# Save Game state to local storage JSON
const SIMPLE_SAVE_FIELDS = [
	"player_name", "player_title", "coins", "best_score", "play_count", 
	"unlocked_items", "item_usage_counts", "unlocked_titles", 
	"deviation_value", "max_deviation_value", "selected_class", "game_mode", 
	"opponent_profiles", "bgm_volume", "se_volume", "is_muted",
	"logged_in_user_id", "auth_token", "daily_current_day",
	"daily_last_played_date", "daily_opponent_ghosts", "daily_my_records",
	"friend_room_code", "friend_is_host", "friend_member_list",
	"friend_current_day", "friend_match_history",
	"total_doubt_successes", "total_doubt_failures", "total_burst_count", "total_perfect_crimes",
	"deck_presets", "deck_preset_names", "selected_preset_idx",
	"today_missions", "mission_progress", "last_mission_date", "current_season",
	"last_updated_at"
]

const OBFUSCATION_KEY = "anti_gravity_chicken_race_key"

func _obfuscate_string(input: String) -> String:
	if input == "":
		return ""
	var result = PackedByteArray()
	var key_bytes = OBFUSCATION_KEY.to_utf8_buffer()
	var input_bytes = input.to_utf8_buffer()
	for i in range(input_bytes.size()):
		result.append(input_bytes[i] ^ key_bytes[i % key_bytes.size()])
	return Marshalls.raw_to_base64(result)

func _deobfuscate_string(input: String) -> String:
	if input == "":
		return ""
	var encrypted_bytes = Marshalls.base64_to_raw(input)
	if encrypted_bytes.size() == 0:
		return ""
	var result = PackedByteArray()
	var key_bytes = OBFUSCATION_KEY.to_utf8_buffer()
	for i in range(encrypted_bytes.size()):
		result.append(encrypted_bytes[i] ^ key_bytes[i % key_bytes.size()])
	return result.get_string_from_utf8()

func get_save_data_dict_for_sync() -> Dictionary:
	var save_dict = {}
	for field in SIMPLE_SAVE_FIELDS:
		if field == "auth_token":
			save_dict[field] = auth_token # Keep un-obfuscated for cloud sync context if needed, but for sync, it should match SIMPLE_SAVE_FIELDS
		else:
			save_dict[field] = get(field)
	save_dict["current_deck"] = get_deck_as_string_keys()
	save_dict["daily_fixed_deck"] = get_daily_fixed_deck_as_string_keys()
	save_dict["save_version"] = Constants.SAVE_VERSION
	return save_dict

# Save Game state to local storage JSON
func save_game() -> void:
	last_updated_at = Time.get_unix_time_from_system()
	var save_dict = {}
	for field in SIMPLE_SAVE_FIELDS:
		if field == "auth_token":
			save_dict[field] = _obfuscate_string(auth_token)
		else:
			save_dict[field] = get(field)
		
	# Save deck as string keys because JSON dictionary keys are always strings
	save_dict["current_deck"] = get_deck_as_string_keys()
	save_dict["daily_fixed_deck"] = get_daily_fixed_deck_as_string_keys()
	save_dict["save_version"] = Constants.SAVE_VERSION
	validate_current_deck()
	validate_opponent_profiles()
	
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game(save_dict)

# Load Game state from local storage JSON
func load_game() -> void:
	var loaded_data = {}
	if has_node("/root/SaveManager"):
		loaded_data = get_node("/root/SaveManager").load_game(Callable(self, "_validate_loaded_data_keys"))
		
	if loaded_data.is_empty():
		push_error("セーブファイルの読み込みに失敗しました。デフォルト値で初期化します。")
		save_game()
		return
		
	var data = loaded_data
	var from_version = int(data.get("save_version", 0))
	if from_version < Constants.SAVE_VERSION:
		_migrate_save_data(data, from_version)
		
	for field in SIMPLE_SAVE_FIELDS:
		if field in data:
			var val = data[field]
			if field == "auth_token":
				val = _deobfuscate_string(str(val))
			var current_val = get(field)
			if current_val is int:
				set(field, int(val))
			elif current_val is float:
				set(field, float(val))
			elif current_val is bool:
				set(field, bool(val))
			else:
				set(field, val)
				
	if "current_deck" in data:
		var deck_data = data["current_deck"]
		if deck_data is Dictionary:
			for key in deck_data.keys():
				current_deck[int(key)] = str(deck_data[key])
			
	if "daily_fixed_deck" in data:
		var fd_data = data["daily_fixed_deck"]
		daily_fixed_deck.clear()
		if fd_data is Dictionary:
			for k in fd_data.keys():
				daily_fixed_deck[int(k)] = str(fd_data[k])
			
	# Ensure all 10 slots are populated in case of load anomalies
	validate_current_deck()
	validate_opponent_profiles()
	
	# Apply loaded volumes to AudioManager if available
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.bgm_volume = bgm_volume
		audio.se_volume = se_volume
		audio.is_muted = is_muted

# Validate essential keys in loaded save data
func _validate_loaded_data_keys(data: Dictionary) -> bool:
	var essential_keys = ["coins", "unlocked_items", "current_deck"]
	for k in essential_keys:
		if not data.has(k):
			return false
	return true


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
		if not opponent_profiles[key].has("name") or str(opponent_profiles[key]["name"]) == "":
			opponent_profiles[key]["name"] = AIManager.get_cpu_name(opponent_profiles[key]["id"])
		if not opponent_profiles[key].has("deviation"):
			opponent_profiles[key]["deviation"] = 50.0

func get_default_participant_record(participant_id: String, display_name: String = "") -> Dictionary:
	var name_to_use = display_name
	if name_to_use == "":
		if participant_id == "player":
			name_to_use = player_name if player_name != "" else Localization.JP_YOU
		elif opponent_profiles.has(participant_id):
			name_to_use = opponent_profiles[participant_id].get("name", Localization.JP_RIVAL)
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

	# hours_history と hours の互換性
	var raw_hours = d.get("hours_history", d.get("hours", []))
	if not (raw_hours is Array):
		raw_hours = []

	# doubts_made の配列化
	var raw_doubts = d.get("doubts_made", [])
	if not (raw_doubts is Array):
		raw_doubts = []
	var norm_doubts = []
	for db in raw_doubts:
		norm_doubts.append(str(db))

	# doubts_received の配列化
	var raw_received = d.get("doubts_received", [])
	if not (raw_received is Array):
		raw_received = []
	var norm_received = []
	for dr in raw_received:
		norm_received.append(str(dr))

	# username / name / player の表記揺れ
	var resolved_name = str(d.get("username", d.get("name", d.get("player_name", norm["name"]))))
	
	# user_id / id
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

# Select 3 random CPU opponents from the pool of 6, and assign them to active match slots
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
			"name": profile.get("name", source_key),
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

# アイテム単体の星レベルによる得点倍率ボーナスを返す（1.0 = ボーナスなし）
# ★2以上のアイテムはそのアイテム使用時の効果値が微増する。
# リプレイ性（アイテムを育てたくなる動機）を向上させる。
func get_item_star_bonus_multiplier(item_id: String) -> float:
	var stars = get_item_stars(item_id)
	match stars:
		0, 1: return 1.0    # ボーナスなし
		2:    return 1.05   # +5%
		3:    return 1.10   # +10%
		4:    return 1.18   # +18%
		5:    return 1.30   # +30% (マスターレベル)
	return 1.0

# 星レベルの表示テキスト（UI向け）
func get_item_star_bonus_text(item_id: String) -> String:
	var stars = get_item_stars(item_id)
	match stars:
		0, 1: return ""
		2:    return "★2: 効果値 +5%"
		3:    return "★3: 効果値 +10%"
		4:    return "★4: 効果値 +18%"
		5:    return "★5: 効果値 +30% 【マスター】"
	return ""

# プレイヤーの偏差値に応じたリーグ分類を取得
func get_deviation_league(dev_val: float = -1.0) -> String:
	var val = dev_val if dev_val >= 0 else deviation_value
	if has_node("/root/DeviationManager"):
		return get_node("/root/DeviationManager").get_deviation_league(val)
	return Constants.LEAGUE_C

# 所属リーグの日本語表示名を取得
func get_deviation_league_name(league: String = "") -> String:
	var target_league = league
	if target_league == "":
		target_league = get_deviation_league()
	if has_node("/root/DeviationManager"):
		return get_node("/root/DeviationManager").get_deviation_league_name(target_league)
	return "C級（凡人）"

# Global helper to perform smooth scene changes with a paper fade overlay
func change_scene_with_fade(tree: SceneTree, target_scene_path: String, duration: float = 0.35) -> void:
	if has_node("/root/UIHelper"):
		get_node("/root/UIHelper").change_scene_with_fade(tree, target_scene_path, duration)

func _auto_login() -> void:
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.verify_token(auth_token, logged_in_user_id)

func _on_auth_completed(success: bool, error_message: String) -> void:
	if success:
		if has_node("/root/BackendManager"):
			var bm = get_node("/root/BackendManager")
			auth_token = bm.auth_token
			logged_in_user_id = bm.logged_in_uuid
			bm.load_cloud_data()
		save_game()
	else:
		auth_token = ""
		logged_in_user_id = ""
		save_game()

func _on_cloud_load_completed(success: bool, cloud_data: Dictionary) -> void:
	if success and cloud_data.size() > 0:
		if "player_name" in cloud_data: player_name = str(cloud_data["player_name"])
		if "player_title" in cloud_data: player_title = str(cloud_data["player_title"])
		if "coins" in cloud_data: coins = max(0, int(cloud_data["coins"]))
		if "best_score" in cloud_data: best_score = max(0, int(cloud_data["best_score"]))
		if "play_count" in cloud_data: play_count = max(0, int(cloud_data["play_count"]))
		if "deviation_value" in cloud_data: deviation_value = clampf(float(cloud_data["deviation_value"]), 30.0, 90.0)
		if "max_deviation_value" in cloud_data: max_deviation_value = clampf(float(cloud_data["max_deviation_value"]), 30.0, 90.0)
		
		if "unlocked_items" in cloud_data:
			unlocked_items.clear()
			if cloud_data["unlocked_items"] is Array:
				for item in cloud_data["unlocked_items"]:
					unlocked_items.append(str(item))
				
		if "item_usage_counts" in cloud_data:
			item_usage_counts = cloud_data["item_usage_counts"] if cloud_data["item_usage_counts"] is Dictionary else {}
			
		if "unlocked_titles" in cloud_data:
			unlocked_titles.clear()
			if cloud_data["unlocked_titles"] is Array:
				for title in cloud_data["unlocked_titles"]:
					unlocked_titles.append(str(title))
				
		if "current_deck" in cloud_data:
			var deck_data = cloud_data["current_deck"]
			if deck_data is Dictionary:
				for key in deck_data.keys():
					current_deck[int(key)] = str(deck_data[key])
				
		if "daily_current_day" in cloud_data: daily_current_day = int(cloud_data["daily_current_day"])
		if "daily_last_played_date" in cloud_data: daily_last_played_date = str(cloud_data["daily_last_played_date"])
		if "daily_opponent_ghosts" in cloud_data:
			daily_opponent_ghosts = cloud_data["daily_opponent_ghosts"] if cloud_data["daily_opponent_ghosts"] is Dictionary else {}
		if "daily_my_records" in cloud_data:
			daily_my_records = cloud_data["daily_my_records"] if cloud_data["daily_my_records"] is Dictionary else {}
		if "daily_fixed_deck" in cloud_data:
			var fd_data = cloud_data["daily_fixed_deck"]
			daily_fixed_deck.clear()
			if fd_data is Dictionary:
				for k in fd_data.keys():
					daily_fixed_deck[int(k)] = str(fd_data[k])
				
		validate_current_deck()
		validate_opponent_profiles()
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
		if i - 1 < shuffled.size():
			deck[i] = shuffled[i - 1]
		else:
			deck[i] = "item_red_sheet" # フォールバックアイテム
		
	return deck

func apply_white_button_style(btn: Button) -> void:
	if has_node("/root/UIHelper"):
		get_node("/root/UIHelper").apply_white_button_style(btn)

func _migrate_save_data(data: Dictionary, from_version: int) -> void:
	var current_v = from_version
	while current_v < Constants.SAVE_VERSION:
		match current_v:
			1:
				if not data.has("deck_presets"):
					data["deck_presets"] = {
						"1": get_deck_as_string_keys(),
						"2": get_deck_as_string_keys(),
						"3": get_deck_as_string_keys()
					}
					data["selected_preset_idx"] = 1
				if not data.has("deck_preset_names"):
					data["deck_preset_names"] = {
						"1": "プリセット 1",
						"2": "プリセット 2",
						"3": "プリセット 3"
					}
				current_v = 2
	data["save_version"] = Constants.SAVE_VERSION

# --- Loading overlay UI wrappers ---
func show_loading(text: String = "通信中...") -> void:
	if has_node("/root/UIHelper"):
		get_node("/root/UIHelper").show_loading(text)

func hide_loading() -> void:
	if has_node("/root/UIHelper"):
		get_node("/root/UIHelper").hide_loading()

func show_tutorial_dialog(parent: Control, text: String, pos: Vector2 = Vector2(700, 50), next_callback: Callable = Callable()) -> PanelContainer:
	if has_node("/root/UIHelper"):
		return get_node("/root/UIHelper").show_tutorial_dialog(parent, text, pos, next_callback)
	return null

func _check_season_reset() -> void:
	var unix_time = Time.get_unix_time_from_system()
	var calculated_season = int(unix_time / (Constants.SEASON_DURATION_DAYS * 86400)) + 1
	if calculated_season != current_season:
		var old_season = current_season
		current_season = calculated_season
		
		# シーズン報酬の付与
		var reward_coins = _calculate_season_reward()
		coins += reward_coins
		
		# 模試データのリセット
		daily_current_day = 1
		daily_last_played_date = ""
		daily_opponent_ghosts.clear()
		daily_my_records.clear()
		daily_fixed_deck.clear()
		save_game()
		
		if has_node("/root/UIHelper"):
			get_node("/root/UIHelper").show_toast(get_season_name(old_season) + "終了！シーズン報酬獲得: " + str(reward_coins) + "コイン")

func get_season_name(season_num: int = -1) -> String:
	if season_num <= 0:
		season_num = current_season
	
	var item_names = []
	for key in CardData.ITEMS:
		item_names.append(CardData.ITEMS[key]["name"])
	
	if item_names.size() == 0:
		return "シーズン " + str(season_num)
	
	var idx = (season_num - 1) % item_names.size()
	return item_names[idx] + "シーズン"

func _calculate_season_reward() -> int:
	var league = get_deviation_league(deviation_value)
	if has_node("/root/BalanceConfig"):
		var cfg_reward = get_node("/root/BalanceConfig").get_value("rewards.season_reward." + league)
		if cfg_reward != null:
			return int(cfg_reward)
	match league:
		Constants.LEAGUE_S: return 200
		Constants.LEAGUE_A: return 100
		Constants.LEAGUE_B: return 50
		Constants.LEAGUE_C: return 25
		Constants.LEAGUE_F: return 10
	return 10

func get_season_remaining_days() -> int:
	var unix_time = Time.get_unix_time_from_system()
	var current_season_start = (current_season - 1) * Constants.SEASON_DURATION_DAYS * 86400
	var next_season_start = current_season * Constants.SEASON_DURATION_DAYS * 86400
	var remaining_seconds = next_season_start - unix_time
	return max(0, int(remaining_seconds / 86400))

func get_cram_season_deck(season_num: int = -1) -> Dictionary:
	if season_num <= 0:
		season_num = current_season
	
	var all_items = CardData.ITEMS.keys()
	all_items.sort()
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("cram_season_" + str(season_num))
	
	var selected_items = []
	var pool = all_items.duplicate()
	
	for i in range(8):
		if pool.size() == 0:
			break
		var idx = rng.randi() % pool.size()
		selected_items.append(pool[idx])
		pool.remove_at(idx)
		
	var deck = {}
	for i in range(selected_items.size()):
		deck[i + 1] = selected_items[i]
	return deck

func evaluate_achievements() -> void:
	var newly_unlocked = []
	
	var check_title = func(title_id: String, condition: bool):
		if condition and not title_id in unlocked_titles:
			unlocked_titles.append(title_id)
			newly_unlocked.append(title_id)
			
	check_title.call("ただの凡人", true) # Default
	check_title.call("見破り名人", total_doubt_successes >= 10)
	check_title.call("名探偵", total_doubt_successes >= 50)
	check_title.call("チキンキング", total_burst_count >= 5)
	check_title.call("完全犯罪者", total_perfect_crimes >= 1)
	check_title.call("ルパン", total_perfect_crimes >= 5)
	check_title.call("勉強の鬼", play_count >= 20)
	check_title.call("廃人ゲーマー", play_count >= 50)
	check_title.call("全国ランカー", max_deviation_value >= 65.0)
	check_title.call("天才", max_deviation_value >= 70.0)
	check_title.call("神", max_deviation_value >= 80.0)
	
	if newly_unlocked.size() > 0:
		save_game()
		if has_node("/root/UIHelper"):
			for t in newly_unlocked:
				get_node("/root/UIHelper").show_toast("称号「" + t + "」を獲得！", 3.0, DeskTheme.COLOR_GREEN)
