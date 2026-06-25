class_name AIStrategyManager
extends RefCounted

static func _evaluate_cpu_standing(cpu_id: String, day_idx: int) -> Dictionary:
	var rank = 2
	var is_losing = false
	var is_winning = false
	
	var main_loop = Engine.get_main_loop()
	if not main_loop is SceneTree:
		return {"rank": rank, "is_losing": is_losing, "is_winning": is_winning}
		
	var root = main_loop.root
	var gamescene = root.get_node_or_null("GameScene")
	var session = null
	if gamescene and gamescene.get("session"):
		session = gamescene.get("session")
	
	if not session:
		for child in root.get_children():
			if child.has_method("get") and child.get("session") is GameSession:
				session = child.get("session")
				break
				
	if session and session is GameSession and day_idx > 1:
		var total_scores = {}
		var participants = ["player"]
		for o_id in Global.opponent_profiles.keys():
			participants.append(o_id)
			
		for p in participants:
			total_scores[p] = 0
			
		for d in range(1, day_idx):
			if session.match_history.has(d):
				var day_data = session.match_history[d]
				for p in participants:
					if day_data.has(p) and day_data[p] is Dictionary:
						total_scores[p] += day_data[p].get("actual_score", 0)
						
		var sorted = total_scores.keys()
		sorted.sort_custom(func(a, b):
			return total_scores[a] > total_scores[b]
		)
		
		var my_idx = sorted.find(cpu_id)
		if my_idx != -1:
			rank = my_idx + 1
			if rank == 4:
				is_losing = true
			elif rank == 1:
				is_winning = true
				
	return {"rank": rank, "is_losing": is_losing, "is_winning": is_winning}

static func simulate_cpu_day(cpu_id: String, day_idx: int) -> Dictionary:
	var actual_id = cpu_id
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("id"):
		actual_id = Global.opponent_profiles[cpu_id]["id"]
	var cpu_info = AIProfile._get_cpu_info(actual_id)
	var cpu_type = cpu_info["type"]
	
	var deck = StudyDeck.new()
	deck.initialize_deck()
	deck.shuffle_draw_pile()
	
	var risk_tolerance = 0.25
	match cpu_type:
		AIProfile.TYPE_CAUTIOUS: risk_tolerance = 0.15
		AIProfile.TYPE_AGGRESSIVE: risk_tolerance = 0.38
		AIProfile.TYPE_BLUFFER: risk_tolerance = 0.24
		AIProfile.TYPE_HIGHROLLER: risk_tolerance = 0.48
		
	var deviation = 50.0
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("deviation"):
		deviation = Global.opponent_profiles[cpu_id]["deviation"]
	var dev_factor = clamp(deviation / 50.0, 0.7, 1.3)
	
	risk_tolerance *= randf_range(0.85, 1.15) * dev_factor
	
	var standing = _evaluate_cpu_standing(cpu_id, day_idx)
	var is_losing = standing["is_losing"]
	var is_winning = standing["is_winning"]
	if is_losing:
		risk_tolerance *= 1.35
	elif is_winning:
		risk_tolerance *= 0.75
		
	var hours_result: Array[Dictionary] = []
	var total_actual_score = 0
	
	var total_periods = 3
		
	for h in range(total_periods):
		deck.reset_status_effects()
		var draw_count = 0
		var bursted = false
		var max_burst_prob = 0.0
		
		while true:
			var burst_prob = deck.get_burst_probability()
			if burst_prob > max_burst_prob:
				max_burst_prob = burst_prob
			
			if draw_count >= 2:
				if burst_prob >= risk_tolerance:
					break
				
			var card = deck.draw_card()
			if card.is_empty():
				break
				
			draw_count += 1
			
			if deck.check_burst():
				bursted = true
				break
				
		var period_score = 0
		if bursted:
			period_score = 0
		else:
			period_score = deck.calculate_hand_score()["total_score"]
					
		hours_result.append({
			"draws": deck.hand.size(),
			"bursted": bursted,
			"score": period_score,
			"reaction": CardData.get_reaction_text(max_burst_prob)
		})
		
		total_actual_score += period_score
		deck.reset_for_next_hour()
		
	return {
		"actual_score": total_actual_score,
		"hours": hours_result
	}
