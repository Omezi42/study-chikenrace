class_name GameSession
extends RefCounted

var current_day: int = 1
var current_hour: int = 1
var max_hours_today: int = 3

var player_deck: StudyDeck

var player_actual_score_today: int = 0
var player_declared_score_today: int = 0
var player_hours_history_today: Array = []
var player_doubts_made_today: Array[String] = []

var match_history: Dictionary = {}

func start_session(deck_config: Dictionary) -> void:
	current_day = 1
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
		current_day = max(Global.daily_current_day, 1)
		max_hours_today = 1
		for d in range(1, current_day + 1):
			match_history[d] = {}
			var day_str = str(d)
			if Global.daily_my_records.has(day_str):
				match_history[d]["player"] = Global.normalize_participant_record(Global.daily_my_records[day_str], "player", Global.player_name)
			if Global.daily_opponent_ghosts.has(day_str):
				var ghosts = Global.daily_opponent_ghosts[day_str]
				var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
				for i in range(min(ghosts.size(), slots.size())):
					var g = ghosts[i]
					match_history[d][slots[i]] = Global.normalize_participant_record(
						g.get("record", {}),
						str(g.get("user_id", slots[i])),
						str(g.get("username", "繝励Ξ繧､繝､繝ｼ"))
					)
	elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		current_day = max(Global.friend_current_day, 1)
		match_history = Global.friend_match_history.duplicate(true)
		for k in match_history.keys():
			match_history[k] = Global.normalize_day_record(match_history[k])
		if not match_history.has(current_day):
			match_history[current_day] = {}
	else:
		current_day = 1
		simulate_cpus_for_day(1)

func simulate_cpus_for_day(day_idx: int) -> void:
	var day_data: Dictionary = match_history.get(day_idx, {})
	match_history[day_idx] = day_data

	for cpu_id in Global.opponent_profiles.keys():
		var sim = AIManager.simulate_cpu_day(cpu_id, day_idx)
		var decl = AIManager.calculate_cpu_bluff(cpu_id, sim["actual_score"])
		day_data[cpu_id] = {
			"id": cpu_id,
			"name": Global.opponent_profiles[cpu_id].get("name", "繝ｩ繧､繝舌Ν"),
			"actual_score": sim["actual_score"],
			"declared_score": decl,
			"hours": sim["hours"],
			"doubts_made": [],
			"doubts_received": [],
			"is_doubt_exposed": false,
			"auto_exposed": false
		}

func add_player_hour_result(draws: int, used_items: Array, bursted: bool, score: int) -> void:
	player_hours_history_today.append({
		"draws": draws,
		"used_items": used_items,
		"bursted": bursted,
		"score": score
	})
	player_actual_score_today += score

func submit_player_declaration(declared_score: int) -> void:
	player_declared_score_today = declared_score

func add_player_doubt(target_id: String) -> void:
	if not target_id in player_doubts_made_today and player_doubts_made_today.size() < 3:
		player_doubts_made_today.append(target_id)

func end_day() -> void:
	_finalize_day_data()
	_save_and_upload_day()
	_advance_to_next_day()

func _finalize_day_data() -> void:
	if not match_history.has(current_day):
		match_history[current_day] = {}
	var day_data: Dictionary = match_history[current_day]

	day_data["player"] = Global.get_default_participant_record("player", Global.player_name)
	day_data["player"]["actual_score"] = player_actual_score_today
	day_data["player"]["declared_score"] = player_declared_score_today
	day_data["player"]["hours"] = player_hours_history_today.duplicate(true)
	day_data["player"]["doubts_made"] = player_doubts_made_today.duplicate(true)

	var participants: Array = []
	for p_id in day_data.keys():
		var p = Global.normalize_participant_record(day_data[p_id], str(p_id))
		day_data[p_id] = p
		participants.append({
			"id": p_id,
			"declared_score": p["declared_score"],
			"hours": p["hours"]
		})

	if Global.game_mode not in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		for cpu_id in Global.opponent_profiles.keys():
			if day_data.has(cpu_id):
				var cpu_doubts = AIManager.make_cpu_doubts(cpu_id, participants)
				day_data[cpu_id]["doubts_made"] = cpu_doubts
				for target_id in cpu_doubts:
					if day_data.has(target_id) and day_data[target_id] is Dictionary:
						day_data[target_id]["doubts_received"].append(cpu_id)

	for target_id in player_doubts_made_today:
		if day_data.has(target_id) and day_data[target_id] is Dictionary:
			day_data[target_id]["doubts_received"].append("player")

	for hour in player_hours_history_today:
		for item in hour.get("used_items", []):
			Global.add_item_usage(str(item), 1)

func _save_and_upload_day() -> void:
	if not match_history.has(current_day):
		return
	var day_data: Dictionary = match_history[current_day]

	if Global.game_mode == Constants.MODE_CRAM:
		Global.daily_my_records[str(current_day)] = Global.normalize_participant_record(day_data.get("player", {}), "player", Global.player_name)
		Global.daily_last_played_date = Time.get_date_string_from_system()

		var bm = _get_backend_manager()
		if bm and Global.logged_in_user_id != "":
			bm.upload_daily_record(current_day, day_data["player"]["actual_score"], day_data["player"])

		Global.save_game()
	elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		Global.friend_match_history = match_history.duplicate(true)
		Global.save_game()

		var bm = _get_backend_manager()
		if bm:
			var my_move = {
				"actual_score": player_actual_score_today,
				"declared_score": player_declared_score_today,
				"hours_history": player_hours_history_today.duplicate(true),
				"doubts_made": player_doubts_made_today.duplicate(true),
				"doubts_submitted": true
			}
			bm.upload_friend_move(Global.friend_room_code, current_day, my_move)

func _advance_to_next_day() -> void:
	_reset_daily_variables()
	_calculate_max_hours()
	if current_day <= Constants.MAX_DAYS:
		_prepare_opponents_for_day(current_day)

func _reset_daily_variables() -> void:
	current_day += 1
	current_hour = 1
	player_actual_score_today = 0
	player_declared_score_today = 0
	player_hours_history_today.clear()
	player_doubts_made_today.clear()

	if Global.game_mode == Constants.MODE_CRAM:
		Global.daily_current_day = current_day
	elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		Global.friend_current_day = current_day
	Global.save_game()

func _calculate_max_hours() -> void:
	max_hours_today = 3
	if Global.game_mode == Constants.MODE_CRAM:
		max_hours_today = 1

	for slot in Global.current_deck.keys():
		if Global.current_deck[slot] == "item_night_note":
			max_hours_today += 1
			break

func _prepare_opponents_for_day(day_idx: int) -> void:
	if Global.game_mode == Constants.MODE_CRAM:
		var next_day_str = str(day_idx)
		if not Global.daily_opponent_ghosts.has(next_day_str):
			var bm = _get_backend_manager()
			var dummy_ghosts = []
			if bm:
				dummy_ghosts = bm.generate_simulated_ghosts(day_idx)
			else:
				dummy_ghosts = [
					{"username": "菴占陸縺上ｓ", "score": 40, "record": {"actual_score": 40, "declared_score": 45, "hours": []}},
					{"username": "驤ｴ譛ｨ縺輔ｓ", "score": 48, "record": {"actual_score": 48, "declared_score": 48, "hours": []}},
					{"username": "鬮俶ｩ九￥繧・", "score": 38, "record": {"actual_score": 38, "declared_score": 45, "hours": []}}
				]
			Global.daily_opponent_ghosts[next_day_str] = dummy_ghosts
			Global.save_game()
	elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		pass
	else:
		simulate_cpus_for_day(day_idx)

func _get_backend_manager():
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop.root.get_node_or_null("BackendManager")
	return null

func calculate_final_showdown() -> Dictionary:
	return ScoreEvaluator.calculate_final_showdown(self)

func evaluate_friend_day_moves(day_idx: int, moves: Array) -> void:
	if not match_history.has(day_idx):
		match_history[day_idx] = {}
	var day_data: Dictionary = match_history[day_idx]

	var my_uuid = "player"
	var bm = _get_backend_manager()
	if bm and bm.logged_in_uuid != "":
		my_uuid = bm.logged_in_uuid

	var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
	var slot_idx = 0

	for m in moves:
		if not (m is Dictionary):
			continue
		var uid = str(m.get("user_id", ""))
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

		day_data[slot_name] = Global.normalize_participant_record(m, uid, str(m.get("username", "繝励Ξ繧､繝､繝ｼ")))

	if not day_data.has("player"):
		day_data["player"] = Global.get_default_participant_record("player", Global.player_name)

	for p_id in day_data.keys():
		var p = day_data[p_id]
		if not (p is Dictionary):
			continue
		if not p.has("doubts_made"):
			p["doubts_made"] = []
		if not p.has("doubts_received"):
			p["doubts_received"] = []
		for target_uid in p["doubts_made"]:
			if target_uid == my_uuid or target_uid == "player":
				day_data["player"]["doubts_received"].append(p_id)
			else:
				for s in day_data.keys():
					if day_data[s] is Dictionary and day_data[s].get("id", "") == target_uid:
						day_data[s]["doubts_received"].append(p_id)

	for p_id in day_data.keys():
		var p = day_data[p_id]
		if not (p is Dictionary):
			continue
		var is_liar = p.get("declared_score", 0) > p.get("actual_score", 0)
		if is_liar and p.get("doubts_received", []).size() > 0:
			p["is_doubt_exposed"] = true

		if is_liar and not p.get("is_doubt_exposed", false):
			var diff = int(p.get("declared_score", 0)) - int(p.get("actual_score", 0))
			var auto_prob = ScoreEvaluator.get_auto_exposure_chance(diff)
			if randf() < auto_prob:
				p["auto_exposed"] = true
				p["is_doubt_exposed"] = true

	Global.friend_match_history = match_history.duplicate(true)
	Global.save_game()

func is_game_over() -> bool:
	return current_day > Constants.MAX_DAYS

func advance_friend_day() -> void:
	_reset_daily_variables()
