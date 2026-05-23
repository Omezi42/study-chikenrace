class_name AIManager
extends RefCounted

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")
const GameBalanceScript = preload("res://scripts/core/GameBalance.gd")
const ItemLibraryScript = preload("res://scripts/core/ItemLibrary.gd")

var rivals = [
	{"name": "慎重な優等生", "style": "safe"},
	{"name": "押し切る秀才", "style": "tempo"},
	{"name": "空気を読む策士", "style": "bluffer"},
	{"name": "一発狙いの夜型", "style": "highroll"}
]

var rival_states = {}
var daily_results = {}


func _init():
	_init_rival_states()


func _init_rival_states():
	rival_states.clear()
	var pool = rivals.duplicate()
	pool.shuffle()
	var count = clamp(Global.match_rival_count, 1, pool.size())
	var active_rivals = pool.slice(0, count)
	
	for r in active_rivals:
		rival_states[r.name] = {
			"deck": StudyDeckScript.new(),
			"score_history": [],
			"total_score": 0,
			"style": r.style
		}
		rival_states[r.name]["deck"].build_initial_deck()



func start_new_day():
	daily_results.clear()
	for r_name in rival_states:
		var state = rival_states[r_name]
		state["deck"].reset_for_next_day()

		var style = state["style"]
		var chosen = _choose_item_for_style(style)
		state["deck"].add_item_card(chosen.type)

		daily_results[r_name] = {
			"actual_score": 0,
			"reported_score": 0,
			"is_lying": false,
			"is_burst": false,
			"status": "playing"
		}


func simulate_daily_action() -> void:
	for r_name in rival_states:
		var state = rival_states[r_name]
		var deck = state["deck"]
		var style = state["style"]
		var res = daily_results[r_name]

		var mood = randf_range(-0.03, 0.05)
		var current_day = Global.score_history.size() + 1
		var is_trailing = state["total_score"] < Global.total_score
		var desperation = 0.0
		if is_trailing and current_day >= 3:
			desperation = 0.06

		var max_draws = 20
		var is_burst = false
		for _i in range(max_draws):
			var burst_prob = deck.current_burst_probability()
			var threshold = _risk_threshold(style, deck, mood, desperation)
			if burst_prob > threshold:
				break

			var draw_res = deck.draw()
			var card = draw_res["card"]
			if card == null:
				break
			if draw_res["burst"]:
				is_burst = true
				break
			_apply_ai_item_effect(deck, card.item_type)

		var final_score = 0
		if not is_burst:
			final_score = deck.finalize_score()

		res["actual_score"] = final_score
		res["is_burst"] = is_burst
		res["status"] = "burst" if is_burst else "stopped"

		var bluff = _plan_bluff(style, deck, final_score, is_burst, current_day, is_trailing)
		res["reported_score"] = final_score + bluff.amount
		res["is_lying"] = bluff.is_lying
		res["cheat_sheet_count"] = deck.cheat_sheet_count
		res["answer_key_count"] = deck.answer_key_count
		res["study_group_chat_count"] = deck.study_group_chat_count
		res["noise_canceling_count"] = deck.noise_canceling_count
		res["votes"] = []

		state["total_score"] += res["actual_score"]
		state["score_history"].append(res.duplicate())
		deck.used_cards.append_array(deck.drawn_cards)
		deck.drawn_cards.clear()


func _risk_threshold(style: String, deck, mood: float, desperation: float) -> float:
	var base_threshold = 0.18
	match style:
		"safe":
			base_threshold = 0.11
		"tempo":
			base_threshold = 0.22
		"bluffer":
			base_threshold = 0.18
		"highroll":
			base_threshold = 0.30
	base_threshold += mood + desperation
	base_threshold -= deck.drawn_cards.size() * 0.004
	base_threshold += deck.burst_shield_charges * 0.08
	return clamp(base_threshold, 0.04, 0.72)


func _apply_ai_item_effect(deck, item_type: int) -> void:
	match item_type:
		Enums.ItemType.ERASER:
			for j in range(deck.drawn_cards.size() - 1, -1, -1):
				var c = deck.drawn_cards[j]
				if c.item_type != Enums.ItemType.ERASER and c.is_active:
					c.is_active = false
					break
		Enums.ItemType.ENERGY_DRINK:
			deck.burst_shield_charges += 1
		Enums.ItemType.STICKY_NOTE:
			deck.sticky_note_bonus_active = true
		Enums.ItemType.CHEAT_SHEET:
			deck.cheat_sheet_count += 1
		Enums.ItemType.FLASH_CARD:
			deck.flash_card_count += 1
		Enums.ItemType.ANSWER_KEY, Enums.ItemType.ALL_NIGHTER:
			deck.answer_key_count += 1
		Enums.ItemType.TIMER:
			deck.timer_count += 1
		Enums.ItemType.STUDY_GROUP_CHAT, Enums.ItemType.MEMO_APP:
			deck.study_group_chat_count += 1
		Enums.ItemType.PRACTICE_TEST:
			deck.reserve_best_of_four()
		Enums.ItemType.CAFE_LATTE:
			deck.latte_charges += 2
		Enums.ItemType.NOISE_CANCELING:
			deck.noise_canceling_count += 1
		Enums.ItemType.SEAT_CUSHION:
			deck.seat_cushion_count += 1
		Enums.ItemType.BLUE_PEN:
			deck.blue_pen_charges += 2
		Enums.ItemType.CRAM_SCHOOL:
			deck.cram_school_count += 1
		Enums.ItemType.WORD_BOOK:
			_ai_word_book(deck)
		Enums.ItemType.THICK_BOOK:
			pass


func _ai_word_book(deck) -> void:
	var look_count = min(3, deck.deck.size())
	var cards = []
	for _i in range(look_count):
		cards.append(deck.deck.pop_back())
	for c in cards:
		if deck._check_burst(c):
			deck.deck.push_front(c)
		else:
			deck.deck.push_back(c)


func _plan_bluff(style: String, deck, final_score: int, is_burst: bool, current_day: int, is_trailing: bool) -> Dictionary:
	var max_bluff = GameBalanceScript.max_bluff_cap(deck.cheat_sheet_count)
	var lie_chance = 0.05
	var bluff_floor = 0
	var bluff_ceiling = max_bluff

	match style:
		"safe":
			lie_chance = 0.08
			bluff_ceiling = int(round(max_bluff * 0.45))
		"tempo":
			lie_chance = 0.16
			bluff_ceiling = int(round(max_bluff * 0.60))
		"bluffer":
			lie_chance = 0.38
			bluff_floor = int(round(max_bluff * 0.25))
		"highroll":
			lie_chance = 0.24 if not is_burst else 0.52
			bluff_floor = int(round(max_bluff * 0.20)) if is_burst else 0

	if is_trailing:
		lie_chance += 0.10
	if current_day >= 4:
		lie_chance += 0.05
	if deck.answer_key_count > 0:
		lie_chance += 0.05

	var is_lying = randf() < clamp(lie_chance, 0.0, 0.9)
	if not is_lying:
		return {"is_lying": false, "amount": 0}

	var amount = randi_range(bluff_floor, maxi(bluff_floor, bluff_ceiling))
	if is_burst:
		amount = maxi(amount, int(round(max_bluff * 0.4)))
	amount = mini(amount, max_bluff)
	return {"is_lying": amount > 0, "amount": amount}


func _choose_item_for_style(style: String) -> Dictionary:
	var candidates: Array = []
	match style:
		"safe":
			candidates = [
				Enums.ItemType.ERASER, Enums.ItemType.WORD_BOOK, Enums.ItemType.ENERGY_DRINK,
				Enums.ItemType.STICKY_NOTE, Enums.ItemType.TIMER, Enums.ItemType.NOISE_CANCELING
			]
		"tempo":
			candidates = [
				Enums.ItemType.COMPASS, Enums.ItemType.RED_SHEET, Enums.ItemType.CAFE_LATTE,
				Enums.ItemType.FLASH_CARD, Enums.ItemType.THICK_BOOK, Enums.ItemType.BLUE_PEN
			]
		"bluffer":
			candidates = [
				Enums.ItemType.CHEAT_SHEET, Enums.ItemType.ANSWER_KEY, Enums.ItemType.STUDY_GROUP_CHAT,
				Enums.ItemType.MEMO_APP, Enums.ItemType.ALL_NIGHTER, Enums.ItemType.WORD_BOOK
			]
		"highroll":
			candidates = [
				Enums.ItemType.THICK_BOOK, Enums.ItemType.RED_SHEET, Enums.ItemType.ALL_NIGHTER,
				Enums.ItemType.PRACTICE_TEST, Enums.ItemType.CRAM_SCHOOL, Enums.ItemType.ENERGY_DRINK
			]
		_:
			candidates = ItemLibraryScript.STARTER_POOL

	if randf() < 0.18:
		var mixed = ItemLibraryScript.STARTER_POOL + ItemLibraryScript.ADVANCED_POOL
		return {"type": mixed[randi() % mixed.size()]}
	return {"type": candidates[randi() % candidates.size()]}


func get_daily_results() -> Dictionary:
	return daily_results


func get_rival_state(name: String) -> Dictionary:
	if rival_states.has(name):
		return rival_states[name]
	return {}


func simulate_ai_votes(day: int) -> void:
	var all_players = [Global.player_name]
	for r in rival_states:
		all_players.append(r)
		
	for r_name in rival_states:
		var voter_state = rival_states[r_name]
		var style = voter_state["style"]
		var res = daily_results[r_name]
		var votes = []
		
		var targets = []
		for p in all_players:
			if p != r_name:
				targets.append(p)
				
		var targets_with_weight = []
		for t in targets:
			var weight = 1.0
			if t == Global.player_name:
				var player_reported = Global.last_reported_score
				var player_actual = Global.last_actual_score
				var player_diff = player_reported - player_actual
				weight += float(player_diff) * 0.05
			else:
				var t_res = daily_results.get(t)
				if t_res:
					var t_reported = t_res["reported_score"]
					var t_actual = t_res["actual_score"]
					var t_diff = t_reported - t_actual
					weight += float(t_diff) * 0.05
					
					var t_state = rival_states[t]
					if t_state["style"] == "bluffer":
						weight += 0.2
					elif t_state["style"] == "highroll":
						weight += 0.1
						
			targets_with_weight.append({"name": t, "weight": weight})
			
		targets_with_weight.sort_custom(func(a, b): return a["weight"] > b["weight"])
		
		var vote_prob = 0.5
		match style:
			"safe": vote_prob = 0.4
			"tempo": vote_prob = 0.6
			"bluffer": vote_prob = 0.8
			"highroll": vote_prob = 0.7
			
		for target_info in targets_with_weight:
			if votes.size() >= 3:
				break
			if randf() < vote_prob * target_info["weight"]:
				votes.append(target_info["name"])
				
		res["votes"] = votes
		
	# Global.score_history にAIの投票結果を書き戻す
	if day <= Global.score_history.size():
		var history_entry = Global.score_history[day - 1]
		var rivals_in_history = history_entry.get("rivals", [])
		for r_entry in rivals_in_history:
			var r_name = r_entry.get("name")
			if daily_results.has(r_name):
				r_entry["votes"] = daily_results[r_name].get("votes", [])
		Global.save_data()

