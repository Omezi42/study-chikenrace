class_name GameSession
extends RefCounted

enum SessionPhaseState {
	LOBBY,
	READY,
	STUDY,
	REPORT,
	WAIT_OTHERS,
	DOUBT,
	FINAL_REVEAL,
	RESULT,
	ERROR
}

signal state_changed(new_state: SessionPhaseState)

var current_state: SessionPhaseState = SessionPhaseState.LOBBY

var current_day: int = 1
var current_hour: int = 1
var max_hours_today: int = 3

var player_deck: StudyDeck

var player_actual_score_today: int = 0
var player_declared_score_today: int = 0
var player_hours_history_today: Array[Dictionary] = []
var player_doubts_made_today: Array[String] = []
var player_emote_today: String = "normal"

var match_history: Dictionary = {}

func change_state(new_state: SessionPhaseState) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(current_state)

func start_session() -> void:
	current_day = 1
	current_hour = 1
	max_hours_today = 3
	player_actual_score_today = 0
	player_declared_score_today = 0
	player_hours_history_today.clear()
	player_doubts_made_today.clear()
	player_emote_today = "normal"
	match_history.clear()

	player_deck = StudyDeck.new()
	player_deck.initialize_deck()

	if Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		current_day = max(Global.friend_current_day, 1)
		var new_history = {}
		var dup = Global.friend_match_history.duplicate(true)
		for k in dup.keys():
			var typed_k = int(str(k)) if str(k).is_valid_int() else k
			new_history[typed_k] = Global.normalize_day_record(dup[k])
		match_history = new_history
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
		var decl = AIManager.calculate_cpu_bluff(cpu_id, sim["actual_score"], day_idx)
		var cpu_emote = AIManager.select_cpu_emote(cpu_id, decl - sim["actual_score"], sim["actual_score"])
		day_data[cpu_id] = {
			"id": cpu_id,
			"name": Global.opponent_profiles[cpu_id].get("name", "ライバル"),
			"actual_score": sim["actual_score"],
			"declared_score": decl,
			"hours": sim["hours"],
			"doubts_made": [],
			"doubts_received": [],
			"is_doubt_exposed": false,
			"auto_exposed": false,
			"emote": cpu_emote
		}

func add_player_hour_result(draws: int, bursted: bool, score: int, reaction: String = "") -> void:
	player_hours_history_today.append({
		"draws": draws,
		"bursted": bursted,
		"score": score,
		"reaction": reaction
	})
	player_actual_score_today += score

func submit_player_declaration(declared_score: int, emote: String = "normal") -> void:
	player_declared_score_today = declared_score
	player_emote_today = emote
	
	if Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		var my_id = str(MatchState.multiplayer.get_unique_id()) if MatchState.multiplayer.has_multiplayer_peer() else "player"
		
		var my_move = {
			"user_id": my_id,
			"username": Global.player_name if Global.player_name != "" else "あなた",
			"day": current_day,
			"actual_score": player_actual_score_today,
			"declared_score": player_declared_score_today,
			"hours_history": player_hours_history_today.duplicate(true),
			"emote": player_emote_today,
			"phase": "declare",
			"doubts_submitted": false
		}
		MatchState.submit_player_action.rpc("declare", my_move)

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
	day_data["player"]["emote"] = player_emote_today

	var participants: Array[Dictionary] = []
	for p_id in day_data.keys():
		var p = Global.normalize_participant_record(day_data[p_id], str(p_id))
		day_data[p_id] = p
		var hours_typed: Array[Dictionary] = []
		for h in p["hours"]:
			hours_typed.append(h as Dictionary)
		participants.append({
			"id": p_id,
			"declared_score": p["declared_score"],
			"hours": hours_typed,
			"emote": p.get("emote", "normal")
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

	for p_id in day_data.keys():
		var p = day_data[p_id]
		if not (p is Dictionary):
			continue
		var is_liar = p.get("declared_score", 0) > p.get("actual_score", 0)
		var exposed_by_doubt = p.get("doubts_received", []).size() > 0 and is_liar
		if exposed_by_doubt:
			p["is_doubt_exposed"] = true

func _save_and_upload_day() -> void:
	if not match_history.has(current_day):
		return
	var day_data: Dictionary = match_history[current_day]

	if Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		Global.friend_match_history = match_history.duplicate(true)
		Global.save_game()

		var my_id = str(MatchState.multiplayer.get_unique_id()) if MatchState.multiplayer.has_multiplayer_peer() else "player"

		var global_doubts = []
		for target_slot in player_doubts_made_today:
			if day_data.has(target_slot) and day_data[target_slot] is Dictionary:
				var uid_val = str(day_data[target_slot].get("id", target_slot))
				global_doubts.append(uid_val)
			else:
				global_doubts.append(target_slot)

		var my_move = {
			"user_id": my_id,
			"username": Global.player_name if Global.player_name != "" else "あなた",
			"day": current_day,
			"actual_score": player_actual_score_today,
			"declared_score": player_declared_score_today,
			"hours_history": player_hours_history_today.duplicate(true),
			"doubts_made": global_doubts,
			"doubts_submitted": true,
			"phase": "doubts",
			"emote": player_emote_today,
			"client_nonce": "%s-%d-%d" % [Global.friend_room_code, current_day, Time.get_unix_time_from_system()]
		}
		MatchState.submit_player_action.rpc("doubts", my_move)

func _advance_to_next_day() -> void:
	_reset_daily_variables()
	if current_day <= Constants.MAX_DAYS:
		_prepare_opponents_for_day(current_day)

func _reset_daily_variables() -> void:
	current_day += 1
	current_hour = 1
	player_actual_score_today = 0
	player_declared_score_today = 0
	player_hours_history_today.clear()
	player_doubts_made_today.clear()
	player_emote_today = "normal"

	if Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		Global.friend_current_day = current_day
	Global.save_game()

func _prepare_opponents_for_day(day_idx: int) -> void:
	simulate_cpus_for_day(day_idx)

func calculate_final_showdown() -> Dictionary:
	return ScoreEvaluator.calculate_final_showdown(self)

func evaluate_friend_day_moves(day_idx: int, moves: Array) -> void:
	if not match_history.has(day_idx):
		match_history[day_idx] = {}
	var day_data: Dictionary = match_history[day_idx]

	var my_uuid = str(MatchState.multiplayer.get_unique_id()) if MatchState.multiplayer.has_multiplayer_peer() else "player"
	var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
	var slot_idx = 0

	for m in moves:
		if not (m is Dictionary):
			continue
		var uid = str(m.get("user_id", ""))
		if uid == my_uuid or uid == "player":
			if m.get("declared_score", 0) > 0 or m.get("actual_score", 0) > 0:
				var my_rec = Global.normalize_participant_record(m, "player", Global.player_name)
				my_rec["id"] = my_uuid
				day_data["player"] = my_rec
			continue

		var slot_name = ""
		for s in Global.opponent_profiles.keys():
			if str(Global.opponent_profiles[s].get("id", s)) == uid:
				slot_name = s
				break

		if slot_name == "":
			if slot_idx < slots.size():
				slot_name = slots[slot_idx]
				slot_idx += 1
			else:
				continue

		var uname = str(m.get("username", "プレイヤー"))
		if slot_name != "" and uname != "" and Global.opponent_profiles.has(slot_name):
			Global.opponent_profiles[slot_name]["name"] = uname

		var p_rec = Global.normalize_participant_record(m, uid, uname)
		p_rec["id"] = uid
		day_data[slot_name] = p_rec

	if not day_data.has("player"):
		var my_name = Global.player_name if Global.player_name != "" else "あなた"
		var my_rec = Global.get_default_participant_record("player", my_name)
		my_rec["actual_score"] = player_actual_score_today
		my_rec["declared_score"] = player_declared_score_today
		my_rec["hours"] = player_hours_history_today.duplicate(true)
		my_rec["doubts_made"] = player_doubts_made_today.duplicate(true)
		my_rec["emote"] = player_emote_today
		my_rec["id"] = my_uuid
		day_data["player"] = my_rec
	else:
		if day_data["player"] is Dictionary:
			day_data["player"]["id"] = my_uuid
			if player_doubts_made_today.size() > 0:
				day_data["player"]["doubts_made"] = player_doubts_made_today.duplicate(true)

	var uid_to_slot = {}
	for s_key in day_data.keys():
		if day_data[s_key] is Dictionary:
			var u = str(day_data[s_key].get("id", ""))
			if u != "":
				uid_to_slot[u] = s_key
	uid_to_slot["player"] = "player"
	uid_to_slot[my_uuid] = "player"

	for p_id in day_data.keys():
		var p = day_data[p_id]
		if not (p is Dictionary):
			continue
		p["doubts_received"] = []

	for p_id in day_data.keys():
		var p = day_data[p_id]
		if not (p is Dictionary):
			continue
		var raw_doubts = p.get("doubts_made", [])
		if not (raw_doubts is Array):
			raw_doubts = []
		var mapped_doubts = []
		for target_uid in raw_doubts:
			var t_str = str(target_uid)
			var t_slot = uid_to_slot.get(t_str, "")
			if t_slot == "" and day_data.has(t_str):
				t_slot = t_str
			if t_slot != "":
				mapped_doubts.append(t_slot)
				if day_data.has(t_slot) and day_data[t_slot] is Dictionary:
					day_data[t_slot]["doubts_received"].append(p_id)
		p["doubts_made"] = mapped_doubts

	for p_id in day_data.keys():
		var p = day_data[p_id]
		if not (p is Dictionary):
			continue
		var is_liar = p.get("declared_score", 0) > p.get("actual_score", 0)
		if is_liar and p.get("doubts_received", []).size() > 0:
			p["is_doubt_exposed"] = true

	Global.friend_match_history = match_history.duplicate(true)
	Global.save_game()

func is_game_over() -> bool:
	return current_day > Constants.MAX_DAYS

func advance_friend_day() -> void:
	_reset_daily_variables()
