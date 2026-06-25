# -*- coding: utf-8 -*-
class_name ScoreEvaluator
extends RefCounted

# Score calculator class separated from GameSession.
# Collects final showdown calculation logic to avoid GameSession becoming a God Object.
# All methods are static and do not require instantiation.

# Final score result structure:
# {
#   "final_scores": Dictionary,  # player_id -> int
#   "rankings": Array,           # [{id, name, score, bursts}, ...]
#   "my_rank": int,
#   "coins_earned": int,
#   "perfect_bonus": int,
#   "level_bonus": int,
#   "title": String,
#   "details": Dictionary        # day_idx -> {player_id -> details_dict}
# }

static func calculate_final_showdown(session: GameSession) -> Dictionary:
	var final_scores := { "player": 0 }
	var max_days := Constants.MAX_DAYS
	
	# 参加者IDを動的に収集する
	for day_idx in range(1, max_days + 1):
		if session.match_history.has(day_idx):
			var day_data: Dictionary = session.match_history[day_idx]
			for p_id in day_data.keys():
				final_scores[str(p_id)] = 0
				
	var showdown_details: Dictionary = {}
	
	var total_bursts := {}
	for p_id in final_scores.keys():
		total_bursts[p_id] = 0
	
	var doubt_success_count := 0       # Player's successful doubt count
	var player_lies_count := 0
	var player_caught_lies_count := 0
	
	# === Step 1: Base scores & exposure checks for each day ===
	for day_idx in range(1, max_days + 1):
		if not session.match_history.has(day_idx):
			continue
		var day_data: Dictionary = session.match_history[day_idx]
		showdown_details[day_idx] = {}
		
		for p_id in final_scores.keys():
			if not day_data.has(p_id):
				continue
			var p: Dictionary = day_data[p_id]
			var actual: int = p["actual_score"]
			var declared: int = p["declared_score"]
			var is_liar: bool = declared > actual
			
			
			# Count burst occurrences
			for h in p.get("hours", []):
				if h.get("bursted", false):
					total_bursts[p_id] += 1
					
			var base_score := declared
			var adjustment := 0
			var doubts_on_me: Array = p.get("doubts_received", [])
			var exposed_by_doubt: bool = doubts_on_me.size() > 0 and is_liar
			
			# System auto-exposure if liar is not doubted by other players (pre-calculated during day end)
			var auto_exposed: bool = p.get("auto_exposed", false)
			var final_exposed: bool = p.get("is_doubt_exposed", false)
			
			if is_liar:
				if p_id == "player":
					player_lies_count += 1
					if final_exposed:
						player_caught_lies_count += 1
						
				if final_exposed:
					var penalty := declared - actual
					adjustment -= penalty						
				p["is_doubt_exposed"] = final_exposed
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
	
	# === Step 2: Doubt bonuses & penalties ===
	for day_idx in range(1, max_days + 1):
		if not session.match_history.has(day_idx):
			continue
		var day_data: Dictionary = session.match_history[day_idx]
		
		# Daily failure penalty base: Day1=15, Day2=18, ..., Day5=27 (by default config)
		var penalty_base: int = BalanceConfig.get_value("exposure.fail_penalty_base", 15)
		var penalty_per_day: int = BalanceConfig.get_value("exposure.fail_penalty_per_day", 3)
		var base_fail_penalty := penalty_base + (day_idx - 1) * penalty_per_day
		
		for p_id in final_scores.keys():
			if not day_data.has(p_id):
				continue
			var p: Dictionary = day_data[p_id]
			
			for target_id in p.get("doubts_made", []):
				if not day_data.has(target_id):
					continue
				var target: Dictionary = day_data[target_id]
				var target_lied: bool = target["declared_score"] > target["actual_score"]
				
				var doubter_adj := 0
				if target_lied:
					var bluff: int = target["declared_score"] - target["actual_score"]
					var adjusted_bluff = int(round(bluff * 0.75))
					doubter_adj += adjusted_bluff + 6
					if p_id == "player":
						doubt_success_count += 1
				else:
					var penalty := base_fail_penalty
					doubter_adj -= penalty
					
				final_scores[p_id] += doubter_adj
				
				# Log detailed adjustments
				if showdown_details.has(day_idx) and showdown_details[day_idx].has(p_id):
					showdown_details[day_idx][p_id]["adjustment"] += doubter_adj
	
	# Item logic removed
	
	# === Step 5: Ranking Calculations ===
	var rank_list: Array = []
	for p_id in final_scores.keys():
		var name := "あなた"
		if p_id == "player" and Global.player_name != "":
			name = Global.player_name
		elif p_id != "player":
			if Global.opponent_profiles.has(p_id):
				name = Global.opponent_profiles[p_id].get("name", p_id)
			elif AIManager.CPU_OPPONENTS.has(p_id):
				name = AIManager.CPU_OPPONENTS[p_id].get("name", p_id)
			else:
				name = p_id
			
		rank_list.append({
			"id": p_id,
			"name": name,
			"score": final_scores[p_id],
			"bursts": total_bursts[p_id]
		})
		
	# Tie breaker: Higher score, then lower bursts
	rank_list.sort_custom(func(a, b):
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		return a["bursts"] < b["bursts"]
	)
	
	var my_rank := 1
	for idx in range(rank_list.size()):
		if rank_list[idx]["id"] == "player":
			my_rank = idx + 1
			break
			
	# === Step 6: Level/Coin logic removed ===
	return {
		"final_scores": final_scores,
		"rankings": rank_list,
		"my_rank": my_rank,
		"details": showdown_details
	}
 


static func get_streak_bonus(streak: int) -> int:
	match streak:
		2: return 3
		3: return 7
		4: return 12
		_: return 12 + (streak - 4) * 5

