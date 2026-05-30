class_name GameSession
extends RefCounted

var current_day: int = 1
var current_hour: int = 1
var max_hours_today: int = 3

# Active player deck
var player_deck: StudyDeck

# Player stats for the current day
var player_actual_score_today: int = 0
var player_declared_score_today: int = 0
var player_hours_history_today: Array = [] # Array of dictionaries: {"draws": int, "used_items": Array, "bursted": bool, "score": int}
var player_doubts_made_today: Array[String] = []

# Daily matching records: Day Index (1-5) -> Dictionary of participant results
# {
#   "player": {"actual_score": int, "declared_score": int, "hours": Array, "doubts_made": Array, "doubts_received": Array},
#   "cpu_sato": ...
# }
var match_history: Dictionary = {}

func start_session(deck_config: Dictionary) -> void:
	current_hour = 1
	max_hours_today = 3
	player_actual_score_today = 0
	player_declared_score_today = 0
	player_hours_history_today.clear()
	player_doubts_made_today.clear()
	match_history.clear()
	
	player_deck = StudyDeck.new()
	player_deck.initialize_deck(deck_config)
	
	if Global.game_mode == Constants.MODE_CRAM:
		current_day = Global.daily_current_day
		max_hours_today = 1 # 一夜漬けモードは1時限のみ
		
		# Restore match_history from Global.daily_my_records and daily_opponent_ghosts
		for d in range(1, current_day + 1):
			var day_data = {}
			match_history[d] = day_data
			
			var day_str = str(d)
			if Global.daily_my_records.has(day_str):
				var r = Global.daily_my_records[day_str]
				day_data["player"] = {
					"id": "player",
					"name": r.get("name", "あなた"),
					"actual_score": int(r.get("actual_score", 0)),
					"declared_score": int(r.get("declared_score", 0)),
					"hours": r.get("hours", []),
					"doubts_made": r.get("doubts_made", []),
					"doubts_received": r.get("doubts_received", []),
					"is_doubt_exposed": bool(r.get("is_doubt_exposed", false)),
					"auto_exposed": bool(r.get("auto_exposed", false))
				}
				
			if Global.daily_opponent_ghosts.has(day_str):
				var ghosts = Global.daily_opponent_ghosts[day_str]
				var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
				for i in range(min(ghosts.size(), 3)):
					var slot = slots[i]
					var g = ghosts[i]
					var rec = g.get("record", {})
					day_data[slot] = {
						"id": g.get("user_id", "cpu_" + str(i)),
						"name": g.get("username", "プレイヤー"),
						"actual_score": int(rec.get("actual_score", 0)),
						"declared_score": int(rec.get("declared_score", 0)),
						"hours": rec.get("hours", []),
						"doubts_made": rec.get("doubts_made", []),
						"doubts_received": rec.get("doubts_received", []),
						"is_doubt_exposed": bool(rec.get("is_doubt_exposed", false)),
						"auto_exposed": bool(rec.get("auto_exposed", false))
					}
	elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		current_day = Global.friend_current_day
		match_history = Global.friend_match_history.duplicate(true)
		if not match_history.has(current_day):
			match_history[current_day] = {}
	else:
		current_day = 1
		simulate_cpus_for_day(1)

# Simulates the daily play and declarations of the 3 CPUs
func simulate_cpus_for_day(day_idx: int) -> void:
	var day_data = {}
	if match_history.has(day_idx):
		day_data = match_history[day_idx]
	else:
		match_history[day_idx] = day_data
		
	for cpu_id in Global.opponent_profiles.keys():
		var sim = AIManager.simulate_cpu_day(cpu_id, day_idx)
		var decl = AIManager.calculate_cpu_bluff(cpu_id, sim["actual_score"])
		
		day_data[cpu_id] = {
			"id": cpu_id,
			"name": Global.opponent_profiles[cpu_id].get("name", "ライバル"),
			"actual_score": sim["actual_score"],
			"declared_score": decl,
			"hours": sim["hours"],
			"doubts_made": [],
			"doubts_received": [],
			"is_doubt_exposed": false,
			"auto_exposed": false
		}

# Set player actual values from their manualチキンレース session
func add_player_hour_result(draws: int, used_items: Array, bursted: bool, score: int) -> void:
	player_hours_history_today.append({
		"draws": draws,
		"used_items": used_items,
		"bursted": bursted,
		"score": score
	})
	player_actual_score_today += score

# Submit player's declared score
func submit_player_declaration(declared_score: int) -> void:
	player_declared_score_today = declared_score

# Record player's doubt
func add_player_doubt(target_id: String) -> void:
	if not target_id in player_doubts_made_today and player_doubts_made_today.size() < 3:
		player_doubts_made_today.append(target_id)

# Process AI doubts and package the day results
func end_day() -> void:
	_finalize_day_data()
	_save_and_upload_day()
	_advance_to_next_day()

# --- end_day() helper 1: Package player data + process AI doubts ---
func _finalize_day_data() -> void:
	var day_data = match_history[current_day]
	
	# Package player data
	day_data["player"] = {
		"id": "player",
		"name": Global.player_name if Global.player_name != "" else "あなた",
		"actual_score": player_actual_score_today,
		"declared_score": player_declared_score_today,
		"hours": player_hours_history_today.duplicate(),
		"doubts_made": player_doubts_made_today.duplicate(),
		"doubts_received": [],
		"is_doubt_exposed": false,
		"auto_exposed": false
	}
	
	# Build participant list for AI to evaluate
	var participants = []
	for p_id in day_data.keys():
		var p = day_data[p_id]
		participants.append({
			"id": p_id,
			"declared_score": p["declared_score"],
			"hours": p["hours"]
		})
		
	# Execute AI doubts (Only applicable in CPU and Cram modes where opponents are AI)
	if Global.game_mode not in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		for cpu_id in Global.opponent_profiles.keys():
			if day_data.has(cpu_id):
				var cpu_doubts = AIManager.make_cpu_doubts(cpu_id, participants)
				day_data[cpu_id]["doubts_made"] = cpu_doubts
				
				# Record doubts received
				for target_id in cpu_doubts:
					if day_data.has(target_id):
						day_data[target_id]["doubts_received"].append(cpu_id)
				
	# Record doubts player received
	for target_id in player_doubts_made_today:
		if day_data.has(target_id):
			day_data[target_id]["doubts_received"].append("player")
			
	# Update item usage counts in Global
	for hour in player_hours_history_today:
		for item in hour["used_items"]:
			Global.add_item_usage(item, 1)

# --- end_day() helper 2: Mode-specific save & upload ---
func _save_and_upload_day() -> void:
	var day_data = match_history[current_day]
	
	if Global.game_mode == Constants.MODE_CRAM:
		Global.daily_my_records[str(current_day)] = day_data["player"].duplicate()
		Global.daily_last_played_date = Time.get_date_string_from_system()
		
		# Async upload
		var bm = _get_backend_manager()
		if bm and Global.logged_in_user_id != "":
			bm.upload_daily_record(current_day, day_data["player"]["actual_score"], day_data["player"])
			
		Global.save_game()
	elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		# Save this day's my record locally in match_history
		Global.friend_match_history = match_history.duplicate(true)
		Global.save_game()
		
		# Upload move to server
		var bm = _get_backend_manager()
		if bm:
			var my_move = {
				"actual_score": player_actual_score_today,
				"declared_score": player_declared_score_today,
				"hours_history": player_hours_history_today.duplicate(),
				"doubts_made": player_doubts_made_today.duplicate(),
				"doubts_submitted": true
			}
			bm.upload_friend_move(Global.friend_room_code, current_day, my_move)

# --- end_day() helper 3: Advance day, reset state, prepare next day ---
func _advance_to_next_day() -> void:
	_reset_daily_variables()
	_calculate_max_hours()
	if current_day <= Constants.MAX_DAYS:
		_prepare_opponents_for_day(current_day)

func _reset_daily_variables() -> void:
	# Advance to next day and reset today's active variables
	current_day += 1
	current_hour = 1
	player_actual_score_today = 0
	player_declared_score_today = 0
	player_hours_history_today.clear()
	player_doubts_made_today.clear()
	
	# Synchronize current day changes to Global singleton state dynamically based on mode
	if Global.game_mode == Constants.MODE_CRAM:
		Global.daily_current_day = current_day
	elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		Global.friend_current_day = current_day
	Global.save_game()

func _calculate_max_hours() -> void:
	# Check if Night Note (徹夜ノート) is slotted in player deck for max hours
	max_hours_today = 3
	if Global.game_mode == Constants.MODE_CRAM:
		max_hours_today = 1
		
	for slot in Global.current_deck.keys():
		if Global.current_deck[slot] == "item_night_note":
			max_hours_today += 1
			break

func _prepare_opponents_for_day(day_idx: int) -> void:
	if Global.game_mode == Constants.MODE_CRAM:
		# Pre-populate simulated ghosts for next day if they aren't generated yet (just in case)
		var next_day_str = str(day_idx)
		if not Global.daily_opponent_ghosts.has(next_day_str):
			var bm = _get_backend_manager()
			var dummy_ghosts = []
			if bm:
				dummy_ghosts = bm.generate_simulated_ghosts(day_idx)
			else:
				dummy_ghosts = [
					{"username": "佐藤くん", "score": 40, "record": {"actual_score": 40, "declared_score": 45, "hours": []}},
					{"username": "鈴木さん", "score": 48, "record": {"actual_score": 48, "declared_score": 48, "hours": []}},
					{"username": "高橋くん", "score": 38, "record": {"actual_score": 38, "declared_score": 45, "hours": []}}
				]
			Global.daily_opponent_ghosts[next_day_str] = dummy_ghosts
			Global.save_game()
	elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		pass # Skip CPU simulation, they are loaded asynchronously from friend room moves.
	else:
		simulate_cpus_for_day(day_idx)

# Helper to safely get BackendManager node from the scene tree
func _get_backend_manager():
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop.root.get_node_or_null("BackendManager")
	return null

# Final calculation at the end of Day 5 (Showdown)
# ロジックは ScoreEvaluator に委譲し、GameSession は肥大化しない（SRP遵守）
func calculate_final_showdown() -> Dictionary:
	return ScoreEvaluator.calculate_final_showdown(self)

func evaluate_friend_day_moves(day_idx: int, moves: Array) -> void:
	if not match_history.has(day_idx):
		match_history[day_idx] = {}
	var day_data = match_history[day_idx]
	
	var my_uuid = ""
	var bm = null
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		bm = main_loop.root.get_node_or_null("BackendManager")
	if bm and bm.logged_in_uuid != "":
		my_uuid = bm.logged_in_uuid
	else:
		my_uuid = "player"
		
	var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
	var slot_idx = 0
	
	for m in moves:
		var uid = m.get("user_id", "")
		if uid == my_uuid or uid == "player":
			continue
			
		var slot_name = ""
		for s in Global.opponent_profiles.keys():
			if Global.opponent_profiles[s].get("id", s) == uid:
				slot_name = s
				break
				
		if slot_name == "":
			if slot_idx < slots.size():
				slot_name = slots[slot_idx]
				slot_idx += 1
			else:
				continue
				
		day_data[slot_name] = {
			"id": uid,
			"name": m.get("username", "プレイヤー"),
			"actual_score": int(m.get("actual_score", 0)),
			"declared_score": int(m.get("declared_score", 0)),
			"hours": m.get("hours_history", []),
			"doubts_made": m.get("doubts_made", []),
			"doubts_received": [],
			"is_doubt_exposed": false,
			"auto_exposed": false
		}
		
	# Process doubts received
	for p_id in day_data.keys():
		var p = day_data[p_id]
		for target_uid in p["doubts_made"]:
			if target_uid == my_uuid or target_uid == "player":
				day_data["player"]["doubts_received"].append(p_id)
			else:
				for s in day_data.keys():
					if day_data[s]["id"] == target_uid:
						day_data[s]["doubts_received"].append(p_id)
						
	# Evaluate lies exposure
	for p_id in day_data.keys():
		var p = day_data[p_id]
		var is_liar = p["declared_score"] > p["actual_score"]
		if is_liar and p["doubts_received"].size() > 0:
			p["is_doubt_exposed"] = true
			
		if is_liar and not p["is_doubt_exposed"]:
			var diff = p["declared_score"] - p["actual_score"]
			var auto_prob = clamp((diff - 5) * 0.03, 0.05, 0.9)
			if randf() < auto_prob:
				p["auto_exposed"] = true
				p["is_doubt_exposed"] = true
				
	Global.friend_match_history = match_history.duplicate(true)
	Global.save_game()

func is_game_over() -> bool:
	return current_day > Constants.MAX_DAYS

func advance_friend_day() -> void:
	# Share common day-advancing reset logic and synchronization
	_reset_daily_variables()
