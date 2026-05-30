class_name MockDataGenerator
extends RefCounted

static func simulate_friend_room_cpus(
	room_code: String,
	day_idx: int,
	mock_moves: Dictionary,
	mock_participants: Array,
	player_move: Dictionary,
	opponent_profiles: Dictionary
) -> void:
	
	if not mock_moves.has(day_idx):
		mock_moves[day_idx] = []
		
	var existing_cpus = {}
	for m in mock_moves[day_idx]:
		var uid = m.get("user_id", "")
		if uid.begins_with("cpu_"):
			existing_cpus[uid] = m
		
	for p in mock_participants:
		var uid = p["user_id"]
		if uid != "player":
			if not existing_cpus.has(uid):
				var simulated_score = randi_range(25, 55)
				var declared = simulated_score + (randi_range(5, 15) if randf() < 0.5 else 0)
				var cpu_move = {
					"room_code": room_code,
					"user_id": uid,
					"username": p["username"],
					"day_idx": day_idx,
					"actual_score": simulated_score,
					"declared_score": declared,
					"hours_history": [{"draws": 4, "used_items": [], "bursted": false, "score": simulated_score}],
					"doubts_made": [],
					"doubts_submitted": true
				}
				mock_moves[day_idx].append(cpu_move)
				existing_cpus[uid] = cpu_move
			
	# If doubts are submitted, evaluate and generate CPU doubts
	if player_move.get("doubts_submitted", false):
		var participants = []
		participants.append({
			"id": "player",
			"declared_score": player_move["declared_score"],
			"hours": player_move["hours_history"]
		})
		for uid in existing_cpus.keys():
			var m = existing_cpus[uid]
			participants.append({
				"id": uid,
				"declared_score": m["declared_score"],
				"hours": m["hours_history"]
			})
			
		for uid in existing_cpus.keys():
			var m = existing_cpus[uid]
			
			# Find matching slot key in profiles
			var profile_slot_key = ""
			for k in opponent_profiles.keys():
				if opponent_profiles[k].get("id") == uid:
					profile_slot_key = k
					break
			if profile_slot_key == "":
				if opponent_profiles.has(uid):
					profile_slot_key = uid
				else:
					profile_slot_key = opponent_profiles.keys()[0] if opponent_profiles.size() > 0 else "cpu_sato"
					
			var cpu_doubts = AIManager.make_cpu_doubts(profile_slot_key, participants)
			var mapped_doubts = []
			for target_id in cpu_doubts:
				if target_id == "player":
					mapped_doubts.append("player")
				else:
					mapped_doubts.append(target_id)
			m["doubts_made"] = mapped_doubts
			m["doubts_submitted"] = true
