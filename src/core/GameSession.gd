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
	
	if Global.game_mode == "cram":
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
	elif Global.game_mode == "friend":
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
			"name": Global.opponent_profiles[cpu_id]["name"],
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
		
	# Execute AI doubts
	for cpu_id in Global.opponent_profiles.keys():
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
			
	# Save daily progression in Global if cram mode
	if Global.game_mode == "cram":
		Global.daily_my_records[str(current_day)] = day_data["player"].duplicate()
		Global.daily_current_day = current_day + 1
		Global.daily_last_played_date = Time.get_date_string_from_system()
		
		# Async upload
		var bm = null
		var main_loop = Engine.get_main_loop()
		if main_loop is SceneTree:
			bm = main_loop.root.get_node_or_null("BackendManager")
		if bm and Global.logged_in_user_id != "":
			bm.upload_daily_record(current_day, day_data["player"]["actual_score"], day_data["player"])
			
		Global.save_game()
	elif Global.game_mode == "friend":
		# Save this day's my record locally in match_history
		Global.friend_match_history = match_history.duplicate(true)
		Global.save_game()
		
		# Upload move to server
		var bm = null
		var main_loop = Engine.get_main_loop()
		if main_loop is SceneTree:
			bm = main_loop.root.get_node_or_null("BackendManager")
		if bm:
			var my_move = {
				"actual_score": player_actual_score_today,
				"declared_score": player_declared_score_today,
				"hours_history": player_hours_history_today.duplicate(),
				"doubts_made": player_doubts_made_today.duplicate(),
				"doubts_submitted": true
			}
			bm.upload_friend_move(Global.friend_room_code, current_day, my_move)
			
	# Advance to next day and reset today's active variables
	current_day += 1
	current_hour = 1
	player_actual_score_today = 0
	player_declared_score_today = 0
	player_hours_history_today.clear()
	player_doubts_made_today.clear()
		
	# Check if Night Note (徹夜ノート) is slotted in player deck for max hours
	max_hours_today = 3
	if Global.game_mode == "cram":
		max_hours_today = 1
		
	for slot in Global.current_deck.keys():
		if Global.current_deck[slot] == "item_night_note":
			max_hours_today += 1
			break
			
	var max_days_total = 3 if Global.game_mode == "cram" else 5
	# Pre-simulate cpus if game continues
	if current_day <= max_days_total:
		if Global.game_mode == "cram":
			# Pre-populate simulated ghosts for next day if they aren't generated yet (just in case)
			var next_day_str = str(current_day)
			if not Global.daily_opponent_ghosts.has(next_day_str):
				var bm = null
				var main_loop = Engine.get_main_loop()
				if main_loop is SceneTree:
					bm = main_loop.root.get_node_or_null("BackendManager")
				var dummy_ghosts = []
				if bm:
					dummy_ghosts = bm.generate_simulated_ghosts(current_day)
				else:
					dummy_ghosts = [
						{"username": "佐藤くん", "score": 40, "record": {"actual_score": 40, "declared_score": 45, "hours": []}},
						{"username": "鈴木さん", "score": 48, "record": {"actual_score": 48, "declared_score": 48, "hours": []}},
						{"username": "高橋くん", "score": 38, "record": {"actual_score": 38, "declared_score": 45, "hours": []}}
					]
				Global.daily_opponent_ghosts[next_day_str] = dummy_ghosts
				Global.save_game()
		elif Global.game_mode == "friend":
			pass # Skip CPU simulation, they are loaded asynchronously from friend room moves.
		else:
			simulate_cpus_for_day(current_day)

# Final calculation at the end of Day 5 (Showdown)
func calculate_final_showdown() -> Dictionary:
	var final_scores = {
		"player": 0,
		"cpu_sato": 0,
		"cpu_suzuki": 0,
		"cpu_takahashi": 0
	}
	
	# Tracks details of adjustments for visual display on the chalkboard
	var showdown_details = {} # DayIdx -> {PlayerId -> Details}
	
	# Detailed track of total bursts per player (for tie-breaker: fewer bursts is better)
	var total_bursts = {
		"player": 0,
		"cpu_sato": 0,
		"cpu_suzuki": 0,
		"cpu_takahashi": 0
	}
	
	var doubt_success_count = 0 # Player's successful doubts
	var player_lies_count = 0
	var player_caught_lies_count = 0
	
	for day_idx in range(1, 6):
		var day_data = match_history[day_idx]
		showdown_details[day_idx] = {}
		
		for p_id in final_scores.keys():
			var p = day_data[p_id]
			var actual = p["actual_score"]
			var declared = p["declared_score"]
			var is_liar = declared > actual
			var deck_config = {}
			
			if p_id == "player":
				deck_config = Global.current_deck
			else:
				var opp_id = p_id
				if Global.opponent_profiles.has(p_id):
					opp_id = Global.opponent_profiles[p_id].get("id", p_id)
				if AIManager.CPU_OPPONENTS.has(opp_id):
					deck_config = AIManager.CPU_OPPONENTS[opp_id]["deck"]
				else:
					deck_config = {}
				
			# Count bursts
			for h in p["hours"]:
				if h["bursted"]:
					total_bursts[p_id] += 1
					
			var base_score = declared
			var adjustment = 0
			var doubts_on_me = p["doubts_received"]
			var exposed_by_doubt = doubts_on_me.size() > 0 and is_liar
			
			var auto_exposed = false
			# If they lied but nobody doubted, apply system auto-exposure curve
			if is_liar and not exposed_by_doubt:
				var bluff_amount = declared - actual
				# Exponential exposure chance: pow(bluff / 40.0, 2.0)
				var exposure_chance = pow(float(bluff_amount) / 40.0, 2.0)
				if randf() < exposure_chance:
					auto_exposed = true
					
			var final_exposed = exposed_by_doubt or auto_exposed
			
			if is_liar:
				if p_id == "player":
					player_lies_count += 1
					if final_exposed:
						player_caught_lies_count += 1
						
				if final_exposed:
					# Caught! Declared score is reduced to actual score
					var penalty = declared - actual
					
					# Double penalty if they used Copy Answer (解答写し)
					var has_copy_answer = false
					for slot in deck_config.keys():
						if deck_config[slot] == "item_copy_answer":
							has_copy_answer = true
							break
							
					if has_copy_answer:
						adjustment -= penalty * 2
					else:
						adjustment -= penalty
						
					p["is_doubt_exposed"] = true
					p["auto_exposed"] = auto_exposed
					
			showdown_details[day_idx][p_id] = {
				"base": base_score,
				"adjustment": adjustment,
				"doubts_received": doubts_on_me.duplicate(),
				"auto_exposed": auto_exposed,
				"is_doubt_exposed": final_exposed,
				"actual": actual,
				"declared": declared,
				"bluff_amount": declared - actual if is_liar else 0
			}
			
			final_scores[p_id] += base_score + adjustment

	# Now process Doubter bonuses and penalties
	for day_idx in range(1, 6):
		var day_data = match_history[day_idx]
		
		# Doubt failure penalties by day index: Day 1: 10, Day 2: 12, ..., Day 5: 18
		var base_fail_penalty = 10 + (day_idx - 1) * 2
		
		for p_id in final_scores.keys():
			var p = day_data[p_id]
			var deck_config = {}
			
			if p_id == "player":
				deck_config = Global.current_deck
			else:
				deck_config = AIManager.CPU_OPPONENTS[Global.opponent_profiles[p_id]["id"]]["deck"]
				
			# Items that mitigate doubt failure
			var cushion_active = false
			var earplug_reduction = 0
			var chat_bonus = 0
			
			for slot in deck_config.keys():
				var item = deck_config[slot]
				if item == "item_cushion":
					cushion_active = true
				elif item == "item_earplugs":
					earplug_reduction = 10
				elif item == "item_study_chat":
					chat_bonus = 6
					
			for target_id in p["doubts_made"]:
				var target = day_data[target_id]
				var target_actual = target["actual_score"]
				var target_declared = target["declared_score"]
				var target_lied = target_declared > target_actual
				
				var doubter_adj = 0
				
				if target_lied:
					# Success! Get bluff amount + 6
					var bluff = target_declared - target_actual
					doubter_adj += bluff + 6 + chat_bonus
					
					if p_id == "player":
						doubt_success_count += 1
				else:
					# Failure! Deduct points
					var penalty = base_fail_penalty
					if cushion_active:
						penalty = int(round(penalty * 0.5))
					penalty = max(penalty - earplug_reduction, 0)
					
					doubter_adj -= penalty
					
				final_scores[p_id] += doubter_adj
				
				# Log doubter adjustments in showdown details
				if not showdown_details[day_idx].has(p_id):
					showdown_details[day_idx][p_id] = {"base": p["declared_score"], "adjustment": 0, "doubts_received": [], "is_doubt_exposed": false, "auto_exposed": false, "actual": p["actual_score"], "declared": p["declared_score"], "bluff_amount": 0}
				showdown_details[day_idx][p_id]["adjustment"] += doubter_adj

	# Add level bonus points to player final score
	var level_bonus = Global.get_total_level_bonus()
	final_scores["player"] += level_bonus

	# Rank participants
	var rank_list = []
	for p_id in final_scores.keys():
		var name = "あなた"
		if p_id == "player" and Global.player_name != "":
			name = Global.player_name
		elif p_id != "player":
			name = Global.opponent_profiles[p_id]["name"]
			
		rank_list.append({
			"id": p_id,
			"name": name,
			"score": final_scores[p_id],
			"bursts": total_bursts[p_id]
		})
		
	# Sorting with tie-breaker: score descending, then bursts ascending (fewer bursts is better)
	rank_list.sort_custom(func(a, b):
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		return a["bursts"] < b["bursts"]
	)
	
	# Determine rank details
	var my_rank = 1
	for idx in range(rank_list.size()):
		if rank_list[idx]["id"] == "player":
			my_rank = idx + 1
			break
			
	# Coins awarded based on ranking
	var coins_earned = 0
	match my_rank:
		1: coins_earned = 100
		2: coins_earned = 50
		3: coins_earned = 20
		4: coins_earned = 10
		
	# Earn coins bonus if perfect game
	var perfect_bonus = 0
	if player_lies_count > 0 and player_caught_lies_count == 0:
		perfect_bonus = 50 # Complete crime bonus
		
	Global.coins += coins_earned + perfect_bonus
	
	# Update best score
	if final_scores["player"] > Global.best_score:
		Global.best_score = final_scores["player"]
		
	Global.play_count += 1
	
	# Determine title (Top-down priority)
	var bursts = total_bursts["player"]
	var score = final_scores["player"]
	var is_cram = Global.game_mode == "cram"
	var max_days = 3 if is_cram else 5
	var title = "ただの凡人"
	
	if Global.deviation_value >= 70.0:
		title = "偏差値70の神"
	elif is_cram and score >= 150 and my_rank == 1:
		title = "一夜漬けの天才"
	elif bursts == 0 and my_rank == 1:
		title = "石橋を叩いて渡る覇者"
	elif bursts >= 3:
		title = "暴風警報発令中"
	elif player_lies_count == 0 and doubt_success_count >= 2:
		title = "沈黙のスナイパー"
	elif player_lies_count >= max_days and player_caught_lies_count == 0:
		title = "完璧なるポーカーフェイス"
	elif Global.unlocked_items.size() >= 24:
		title = "文房具マスター"
	elif player_caught_lies_count >= 3:
		title = "オオカミ少年"
	elif doubt_success_count >= 3:
		title = "人間嘘発見器"
	elif player_lies_count >= 2 and player_caught_lies_count == 0 and score >= (150 if is_cram else 200):
		title = "完全犯罪のカリスマ"
	elif score >= (200 if is_cram else 300):
		title = "東大レベル"
	elif score <= 50:
		title = "赤点回避失敗"
	elif bursts == 0:
		title = "安全第一"
	elif doubt_success_count == 0 and player_caught_lies_count > 0:
		title = "お人好しなカモ"
	elif player_lies_count == 0 and score >= (120 if is_cram else 180):
		title = "清廉潔白なガリ勉"
	elif player_lies_count >= 2 and player_caught_lies_count == player_lies_count:
		title = "ガラスのハート"
	elif my_rank == 1:
		title = "クラスの優等生"
	elif my_rank == 4:
		title = "クラスの落ちこぼれ"
		
	if not title in Global.unlocked_titles:
		Global.unlocked_titles.append(title)
		
	Global.save_game()
	
	return {
		"final_scores": final_scores,
		"rankings": rank_list,
		"my_rank": my_rank,
		"coins_earned": coins_earned,
		"perfect_bonus": perfect_bonus,
		"level_bonus": level_bonus,
		"title": title,
		"details": showdown_details
	}

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
			if Global.opponent_profiles[s]["id"] == uid:
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
	var max_days = 3 if Global.game_mode == "cram" else 5
	return current_day > max_days

func advance_friend_day() -> void:
	current_day += 1
	current_hour = 1
	player_actual_score_today = 0
	player_declared_score_today = 0
	player_hours_history_today.clear()
	player_doubts_made_today.clear()
	
	Global.friend_current_day = current_day
	Global.save_game()
