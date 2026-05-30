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
	var final_scores := {
		"player": 0,
		"cpu_sato": 0,
		"cpu_suzuki": 0,
		"cpu_takahashi": 0
	}
	
	# Detailed adjustment logs for blackboard rendering
	var showdown_details: Dictionary = {}
	
	# Total bursted hours (Tie-breaker: lower bursts rank higher)
	var total_bursts := {
		"player": 0,
		"cpu_sato": 0,
		"cpu_suzuki": 0,
		"cpu_takahashi": 0
	}
	
	var doubt_success_count := 0       # Player's successful doubt count
	var player_lies_count := 0
	var player_caught_lies_count := 0
	
	var max_days := Constants.MAX_DAYS
	
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
			var deck_config: Dictionary = _get_deck_config(p_id)
			
			# Count burst occurrences
			for h in p.get("hours", []):
				if h.get("bursted", false):
					total_bursts[p_id] += 1
					
			var base_score := declared
			var adjustment := 0
			var doubts_on_me: Array = p.get("doubts_received", [])
			var exposed_by_doubt: bool = doubts_on_me.size() > 0 and is_liar
			
			# System auto-exposure if liar is not doubted by other players
			var auto_exposed := false
			if is_liar and not exposed_by_doubt:
				var bluff_amount := declared - actual
				# Exponential exposure chance: pow(bluff / 40.0, 2.0)
				var exposure_chance: float = pow(float(bluff_amount) / 40.0, 2.0)
				if randf() < exposure_chance:
					auto_exposed = true
					
			var final_exposed: bool = exposed_by_doubt or auto_exposed
			
			if is_liar:
				if p_id == "player":
					player_lies_count += 1
					if final_exposed:
						player_caught_lies_count += 1
						
				if final_exposed:
					var penalty := declared - actual
					# double penalty if item_copy_answer is slotted
					if _has_item(deck_config, "item_copy_answer"):
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
	
	# === Step 2: Doubt bonuses & penalties ===
	for day_idx in range(1, max_days + 1):
		if not session.match_history.has(day_idx):
			continue
		var day_data: Dictionary = session.match_history[day_idx]
		
		# Daily failure penalty base: Day1=10, Day2=12, ..., Day5=18
		var base_fail_penalty := 10 + (day_idx - 1) * 2
		
		for p_id in final_scores.keys():
			if not day_data.has(p_id):
				continue
			var p: Dictionary = day_data[p_id]
			var deck_config: Dictionary = _get_deck_config(p_id)
			
			var cushion_active := _has_item(deck_config, "item_cushion")
			var earplug_reduction := 10 if _has_item(deck_config, "item_earplugs") else 0
			var chat_bonus := 6 if _has_item(deck_config, "item_study_chat") else 0
			
			for target_id in p.get("doubts_made", []):
				if not day_data.has(target_id):
					continue
				var target: Dictionary = day_data[target_id]
				var target_lied: bool = target["declared_score"] > target["actual_score"]
				
				var doubter_adj := 0
				if target_lied:
					var bluff: int = target["declared_score"] - target["actual_score"]
					doubter_adj += bluff + 6 + chat_bonus
					if p_id == "player":
						doubt_success_count += 1
				else:
					var penalty := base_fail_penalty
					if cushion_active:
						penalty = int(round(penalty * 0.5))
					penalty = max(penalty - earplug_reduction, 0)
					doubter_adj -= penalty
					
				final_scores[p_id] += doubter_adj
				
				# Log detailed adjustments
				if showdown_details.has(day_idx) and showdown_details[day_idx].has(p_id):
					showdown_details[day_idx][p_id]["adjustment"] += doubter_adj
	
	# === Step 3: Player Level Bonus ===
	var level_bonus := Global.get_total_level_bonus()
	final_scores["player"] += level_bonus
	
	# === Step 4: Item Star level bonuses ===
	var star_bonus := _calculate_star_bonus_for_player()
	final_scores["player"] += star_bonus
	
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
			
	# === Step 6: Coin Rewards ===
	var coins_earned := 0
	match my_rank:
		1: coins_earned = 100
		2: coins_earned = 50
		3: coins_earned = 20
		4: coins_earned = 10
		
	# Perfect Crime Bonus (lied at least once and never got caught)
	var perfect_bonus := 0
	if player_lies_count > 0 and player_caught_lies_count == 0:
		perfect_bonus = 50
		
	Global.coins += coins_earned + perfect_bonus
	
	# Update best score
	if final_scores["player"] > Global.best_score:
		Global.best_score = final_scores["player"]
		
	Global.play_count += 1
	
	# === Step 7: Title Determination ===
	var title := _determine_title(
		final_scores["player"], my_rank, total_bursts["player"],
		player_lies_count, player_caught_lies_count, doubt_success_count,
		Global.game_mode
	)
	
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
		"star_bonus": star_bonus,
		"title": title,
		"details": showdown_details
	}

# === Private Helpers ===

# Get active item deck for the participant
static func _get_deck_config(p_id: String) -> Dictionary:
	if p_id == "player":
		return Global.current_deck
	# Resolve real ID via opponent profiles for CPU
	if Global.opponent_profiles.has(p_id):
		var opp_id: String = Global.opponent_profiles[p_id].get("id", p_id)
		if AIManager.CPU_OPPONENTS.has(opp_id):
			return AIManager.CPU_OPPONENTS[opp_id]["deck"]
	if AIManager.CPU_OPPONENTS.has(p_id):
		return AIManager.CPU_OPPONENTS[p_id]["deck"]
	return {}

# Check if item_id is inside the deck config
static func _has_item(deck_config: Dictionary, item_id: String) -> bool:
	return item_id in deck_config.values()

# Calculate star level point bonuses for player
static func _calculate_star_bonus_for_player() -> int:
	var bonus := 0
	for item_id in Global.current_deck.values():
		var stars := Global.get_item_stars(item_id)
		# Star level bonuses: Star 1=0, Star 2=1, Star 3=2, Star 4=4, Star 5=7
		match stars:
			2: bonus += 1
			3: bonus += 2
			4: bonus += 4
			5: bonus += 7
	return bonus

# Determine title unlocked based on match criteria.
# Uses a table-driven approach: each entry is checked in order, first match wins.
# This makes the priority explicit and safe to reorder or extend.
static func _determine_title(
	score: int, my_rank: int, bursts: int,
	lies_count: int, caught_lies: int, doubt_successes: int,
	game_mode: String = ""
) -> String:
	var is_cram := (game_mode == Constants.MODE_CRAM)
	var max_days := Constants.MAX_DAYS
	
	# Title rules table with explicit priorities (higher priority value wins)
	var rules: Array[Dictionary] = [
		{"title": Constants.TITLE_DEV_GOD,            "priority": 100, "check": func(): return Global.deviation_value >= 70.0},
		{"title": Constants.TITLE_CRAM_GENIUS,         "priority": 95,  "check": func(): return is_cram and score >= 150 and my_rank == 1},
		{"title": Constants.TITLE_SAFE_CHAMP,          "priority": 90,  "check": func(): return bursts == 0 and my_rank == 1},
		{"title": Constants.TITLE_STORM,               "priority": 85,  "check": func(): return bursts >= 3},
		{"title": Constants.TITLE_SNIPER,              "priority": 80,  "check": func(): return lies_count == 0 and doubt_successes >= 2},
		{"title": Constants.TITLE_POKER_FACE,          "priority": 75,  "check": func(): return lies_count >= max_days and caught_lies == 0},
		{"title": Constants.TITLE_STATIONERY_MASTER,   "priority": 70,  "check": func(): return Global.unlocked_items.size() >= 24},
		{"title": Constants.TITLE_WOLF_BOY,            "priority": 65,  "check": func(): return caught_lies >= 3},
		{"title": Constants.TITLE_LIE_DETECTOR,        "priority": 60,  "check": func(): return doubt_successes >= 3},
		{"title": Constants.TITLE_CHARISMA,            "priority": 55,  "check": func(): return lies_count >= 2 and caught_lies == 0 and score >= (150 if is_cram else 200)},
		{"title": Constants.TITLE_TODAI,               "priority": 50,  "check": func(): return score >= (200 if is_cram else 300)},
		{"title": Constants.TITLE_RED_FAIL,            "priority": 45,  "check": func(): return score <= 50},
		{"title": Constants.TITLE_CRAM_HONEST,         "priority": 40,  "check": func(): return lies_count == 0 and score >= (120 if is_cram else 180)},
		{"title": Constants.TITLE_SAFETY_FIRST,        "priority": 35,  "check": func(): return bursts == 0},
		{"title": Constants.TITLE_EASY_TARGET,         "priority": 30,  "check": func(): return doubt_successes == 0 and caught_lies > 0},
		{"title": Constants.TITLE_GLASS_HEART,         "priority": 25,  "check": func(): return lies_count >= 2 and caught_lies == lies_count},
		{"title": Constants.TITLE_EXCELLENT,           "priority": 20,  "check": func(): return my_rank == 1},
		{"title": Constants.TITLE_UNDERACHIEVER,       "priority": 15,  "check": func(): return my_rank == 4},
	]
	
	# Sort rules by priority descending
	rules.sort_custom(func(a, b): return a["priority"] > b["priority"])
	
	for rule in rules:
		if rule["check"].call():
			return rule["title"]
	
	return Constants.TITLE_AVERAGE

