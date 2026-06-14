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
	var deck_config = cpu_info["deck"]
	
	if Global and (Global.game_mode == Constants.MODE_CRAM or Global.game_mode == Constants.MODE_OVERNIGHT):
		deck_config = Global.get_cram_season_deck()
	
	var deck = StudyDeck.new()
	deck.initialize_deck(deck_config)
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
	
	if Global and Global.game_mode == Constants.MODE_RANDOM:
		var league = Global.get_deviation_league(Global.deviation_value)
		match league:
			Constants.LEAGUE_S: dev_factor *= 1.15
			Constants.LEAGUE_A: dev_factor *= 1.05
			Constants.LEAGUE_B: dev_factor *= 1.0
			Constants.LEAGUE_C: dev_factor *= 0.9
			Constants.LEAGUE_F: dev_factor *= 0.8
	
	risk_tolerance *= randf_range(0.85, 1.15) * dev_factor
	
	var has_energy_drink = "item_energy_drink" in deck_config.values()
	var has_insurance = ("item_eraser" in deck_config.values() or 
						 "item_red_sheet" in deck_config.values() or 
						 "item_amulet" in deck_config.values())
	if has_energy_drink and has_insurance:
		risk_tolerance *= 1.3
	
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
	var has_night_note = false
	for slot_idx in deck_config.keys():
		if deck_config[slot_idx] == "item_night_note":
			has_night_note = true
			break
			
	if has_night_note and randf() < 0.3:
		total_periods = 4
		
	for h in range(total_periods):
		deck.reset_status_effects()
		var used_items: Array[String] = []
		var potential_items: Array[String] = []
		decide_and_apply_cpu_items(deck, deck_config, potential_items, day_idx, cpu_id)
		
		var draw_count = 0
		var bursted = false
		var max_burst_prob = 0.0
		
		while true:
			var burst_prob = deck.get_burst_probability()
			if burst_prob > max_burst_prob:
				max_burst_prob = burst_prob
			
			if "item_cafe_latte" in deck_config.values() and not "item_cafe_latte" in used_items:
				if burst_prob >= 0.4 and randf() < 0.75:
					used_items.append("item_cafe_latte")
					var card = deck.activate_cafe_latte()
					if not card.is_empty():
						draw_count += 1
						_apply_drawn_item_effects_cpu(card, deck, used_items)
						continue
			
			var has_protection = deck.eraser_charges > 0 or deck.red_sheet_active
			if draw_count >= 2:
				if burst_prob >= 0.75 and not has_protection:
					break
				if burst_prob >= risk_tolerance:
					break
				
			if deck.energy_drink_active and draw_count > 0 and randf() < 0.25:
				bursted = true
				break
				
			var card = deck.draw_card()
			if card.is_empty():
				break
				
			draw_count += 1
			_apply_drawn_item_effects_cpu(card, deck, used_items)
			
			if deck.check_burst():
				bursted = true
				break
				
		var period_score = 0
		if bursted:
			if deck.amulet_active:
				var mock_score = deck.calculate_hand_score()["total_score"]
				period_score = int(round(mock_score * 0.5))
				if not "item_amulet" in used_items:
					used_items.append("item_amulet")
			else:
				period_score = 0
		else:
			period_score = deck.calculate_hand_score()["total_score"]
			
		# Merge potential_items and deck.activated_items
		if deck.hand.size() > 0:
			var hand_item_ids = []
			for card in deck.hand:
				if card.has("item_id"):
					hand_item_ids.append(card["item_id"])
					
			for item in potential_items:
				if not item in used_items:
					if item == "item_eraser" and not "item_eraser" in deck.activated_items:
						continue
					if item == "item_red_sheet" and not "item_red_sheet" in deck.activated_items:
						continue
					if item == "item_amulet":
						continue
					
					# Passives are allowed, but draw-activated items must be in hand
					var is_passive = item in ["item_cushion", "item_earplugs", "item_study_chat", "item_cheat_sheet", "item_copy_answer", "item_night_note"]
					if not is_passive and not item in hand_item_ids:
						continue
						
					used_items.append(item)
			
			for item in deck.activated_items:
				if not item in used_items:
					used_items.append(item)
					
		hours_result.append({
			"draws": deck.hand.size(),
			"used_items": used_items,
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

static func decide_and_apply_cpu_items(deck: StudyDeck, deck_config: Dictionary, potential_items: Array[String], day_idx: int, cpu_id: String) -> void:
	var deviation = 50.0
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("deviation"):
		deviation = Global.opponent_profiles[cpu_id]["deviation"]
	
	var late_game_boost = clamp(day_idx * 0.12, 0.0, 0.45)
	var is_losing = day_idx >= 3 and deviation < 48.0
	var is_winning = day_idx >= 3 and deviation >= 53.0
	
	var defense_mult = 1.5 if is_winning else (0.6 if is_losing else 1.0)
	var offense_mult = 1.6 if is_losing else (0.4 if is_winning else 1.0)
	
	if "item_eraser" in deck_config.values() and randf() < ((0.3 + late_game_boost) * defense_mult):
		deck.eraser_charges = 1
		potential_items.append("item_eraser")
		
	if "item_wordbook" in deck_config.values() and randf() < ((0.15 + late_game_boost) * defense_mult):
		potential_items.append("item_wordbook")
	elif "item_ruler" in deck_config.values() and randf() < ((0.15 + late_game_boost) * defense_mult):
		potential_items.append("item_ruler")
		
	if "item_mech_pencil" in deck_config.values() and randf() < ((0.22 + late_game_boost) * offense_mult):
		deck.next_draw_bonus_points = 2
		potential_items.append("item_mech_pencil")
		
	if "item_energy_drink" in deck_config.values() and randf() < ((0.18 + late_game_boost) * offense_mult):
		deck.energy_drink_active = true
		potential_items.append("item_energy_drink")
		
	if "item_highlighter" in deck_config.values() and randf() < ((0.18 + late_game_boost) * offense_mult):
		deck.highlighter_active = true
		potential_items.append("item_highlighter")
 
	if "item_blue_pen" in deck_config.values() and randf() < ((0.18 + late_game_boost) * defense_mult):
		deck.blue_pen_active = true
		potential_items.append("item_blue_pen")
 
	if "item_amulet" in deck_config.values() and randf() < ((0.25 + late_game_boost) * defense_mult):
		deck.amulet_active = true
		potential_items.append("item_amulet")
 
	if "item_cram_school_print" in deck_config.values() and randf() < ((0.3 + late_game_boost) * offense_mult):
		deck.cram_school_print_active = true
		potential_items.append("item_cram_school_print")
 
	if "item_red_sheet" in deck_config.values() and randf() < ((0.35 + late_game_boost) * defense_mult):
		deck.red_sheet_active = true
		potential_items.append("item_red_sheet")
 
	if "item_thick_book" in deck_config.values() and randf() < ((0.3 + late_game_boost) * offense_mult):
		deck.activate_thick_book()
		potential_items.append("item_thick_book")
 
	if "item_sticky_note" in deck_config.values() and randf() < ((0.4 + late_game_boost) * offense_mult):
		deck.next_draw_bonus_points = max(deck.next_draw_bonus_points, 1)
		potential_items.append("item_sticky_note")
 
	if "item_expected_questions" in deck_config.values() and randf() < ((0.35 + late_game_boost) * offense_mult):
		deck.next_draw_bonus_points = 3
		potential_items.append("item_expected_questions")
 
	if "item_compass" in deck_config.values() and randf() < ((0.25 + late_game_boost) * defense_mult):
		deck.compass_active = true
		potential_items.append("item_compass")
 
	if "item_timer" in deck_config.values() and randf() < (0.25 + late_game_boost):
		deck.timer_active = true
		potential_items.append("item_timer")
 
	if "item_cushion" in deck_config.values() and randf() < 0.2:
		potential_items.append("item_cushion")
 
	if "item_earplugs" in deck_config.values() and randf() < 0.2:
		potential_items.append("item_earplugs")
 
	if "item_study_chat" in deck_config.values() and randf() < 0.25:
		potential_items.append("item_study_chat")
 
	if "item_cheat_sheet" in deck_config.values() and randf() < 0.3:
		potential_items.append("item_cheat_sheet")
 
	if "item_copy_answer" in deck_config.values() and randf() < 0.25:
		potential_items.append("item_copy_answer")
 
	if "item_forget_notebook" in deck_config.values() and deck.hand.size() > 0 and randf() < ((0.3 + late_game_boost) * defense_mult):
		deck.activate_forget_notebook()
		potential_items.append("item_forget_notebook")
 
	if "item_memo_cards" in deck_config.values() and deck.hand.size() > 0 and deck.draw_pile.size() > 0 and randf() < (0.3 + late_game_boost):
		deck.activate_memo_cards(0)
		potential_items.append("item_memo_cards")
 
	if "item_memo_app" in deck_config.values() and randf() < ((0.3 + late_game_boost) * defense_mult):
		deck.activate_memo_app_draw()
		deck.activate_memo_app_discard(0)
		potential_items.append("item_memo_app")

static func _apply_drawn_item_effects_cpu(card: Dictionary, deck: StudyDeck, used_items: Array[String]) -> void:
	var item_id = card.get("item_id", "")
	if item_id == "" or item_id in used_items:
		return
		
	used_items.append(item_id)
	
	match item_id:
		"item_highlighter":
			deck.highlighter_active = true
		"item_blue_pen":
			deck.blue_pen_active = true
		"item_energy_drink":
			deck.energy_drink_active = true
		"item_cram_school_print":
			deck.cram_school_print_active = true
		"item_timer":
			deck.timer_active = true
		"item_compass":
			deck.compass_active = true
		"item_thick_book":
			deck.activate_thick_book()
		"item_sticky_note":
			deck.next_draw_bonus_points = max(deck.next_draw_bonus_points, 1)
		"item_expected_questions":
			deck.next_draw_bonus_points = 3
		"item_forget_notebook":
			deck.activate_forget_notebook()
		"item_memo_cards":
			deck.activate_memo_cards(0)
		"item_memo_app":
			var extra_cards = deck.activate_memo_app_draw()
			for c in extra_cards:
				_apply_drawn_item_effects_cpu(c, deck, used_items)
			deck.activate_memo_app_discard(0)
