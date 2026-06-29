class_name StudyDeck
extends RefCounted

var cards: Array[Dictionary] = []
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []

func initialize_deck() -> void:
	cards.clear()
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	
	var max_slots = 10
	for slot_idx in range(1, max_slots + 1):
		for c_idx in range(slot_idx):
			var card = {
				"value": slot_idx,
				"name": str(slot_idx) + "のカード"
			}
			cards.append(card)
			
	draw_pile = cards.duplicate()
	shuffle_draw_pile()

func shuffle_draw_pile(rng: RandomNumberGenerator = null) -> void:
	var n = draw_pile.size()
	for i in range(n - 1, 0, -1):
		var j = 0
		if rng:
			j = rng.randi() % (i + 1)
		else:
			j = randi() % (i + 1)
		var temp = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = temp

func draw_card() -> Dictionary:
	if draw_pile.size() == 0:
		if discard_pile.size() > 0:
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			shuffle_draw_pile()
		else:
			return {}

	var card = draw_pile.pop_back()
	hand.append(card)
	return card

func would_card_burst(card: Dictionary) -> bool:
	if card.get("value", 0) == 0:
		return false
	for c in hand:
		if c["value"] == card["value"]:
			return true
	return false

func check_burst() -> bool:
	var values = []
	for card in hand:
		var val = card.get("value", 0)
		if val == 0:
			continue
		if val in values:
			return true
		values.append(val)
	return false

func get_burst_probability() -> float:
	if draw_pile.size() == 0 and discard_pile.size() == 0:
		return 0.0
		
	var hand_values = []
	for card in hand:
		hand_values.append(card["value"])
		
	var target_pile = draw_pile
	if draw_pile.size() == 0:
		target_pile = discard_pile
		
	var total_cards = target_pile.size()
	var burst_cards = 0
	
	for card in target_pile:
		if card["value"] in hand_values:
			burst_cards += 1
			
	return float(burst_cards) / float(total_cards)

func calculate_hand_score() -> Dictionary:
	var subtotal = 0
	for card in hand:
		subtotal += card["value"]
		
	return {
		"subtotal": subtotal,
		"total_score": subtotal
	}

func reset_for_next_hour() -> void:
	for card in hand:
		discard_pile.append(card.duplicate())
	hand.clear()

func reset_for_next_day(rng: RandomNumberGenerator = null) -> void:
	hand.clear()
	discard_pile.clear()
	draw_pile = cards.duplicate()
	shuffle_draw_pile(rng)
