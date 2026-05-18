class_name StudyDeck
extends RefCounted

const CardDataScript = preload("res://scripts/data/CardData.gd")

var deck: Array = []
var drawn_cards: Array = []
var remaining_erasers: int = 0
var ruler_bonuses: Dictionary = {}

func _init():
	for s in range(5): ruler_bonuses[s] = 0

func build_deck(weights: Dictionary, noise_count: int = 0) -> void:
	deck.clear()
	drawn_cards.clear()
	remaining_erasers = 0
	for s in ruler_bonuses.keys(): ruler_bonuses[s] = 0
	
	for subj in weights.keys():
		var w_list = weights[subj]
		for w in w_list:
			for i in range(w):
				deck.append(CardDataScript.new(0, subj, w))
	
	for i in range(2):
		deck.append(CardDataScript.new(1)) # ERASER
		deck.append(CardDataScript.new(2)) # PEN
		deck.append(CardDataScript.new(3)) # RULER
	
	for i in range(noise_count):
		deck.append(CardDataScript.new(4)) # NOISE
	
	deck.shuffle()


func draw() -> Dictionary:
	if deck.is_empty(): return { "card": null, "burst": false, "erased": false }
	var card = deck.pop_back()
	
	if card.item_type == 1: # ERASER
		remaining_erasers += 1
		drawn_cards.append(card)
		return { "card": card, "burst": false, "erased": false }
		
	var is_burst = _check_burst(card)
	if is_burst and remaining_erasers > 0:
		remaining_erasers -= 1
		_remove_conflicting_card(card.weight)
		return { "card": card, "burst": false, "erased": true }
		
	drawn_cards.append(card)
	return { "card": card, "burst": is_burst, "erased": false }

func _check_burst(card) -> bool:
	if card.item_type != 0: return false # SUBJECT
	for c in drawn_cards:
		if c.item_type == 0 and c.weight == card.weight: return true
	return false

func _remove_conflicting_card(weight: int) -> void:
	for i in range(drawn_cards.size() - 1, -1, -1):
		var c = drawn_cards[i]
		if c.item_type == 0 and c.weight == weight:
			drawn_cards.remove_at(i)
			break

func calculate_scores() -> Dictionary:
	var total = 0
	var subject_scores = { 0:0, 1:0, 2:0, 3:0, 4:0 }
	var pen_count = 0
	var noise_count = 0
	
	for c in drawn_cards:
		if c.item_type == 0:
			subject_scores[c.subject] += c.weight
			total += c.weight
		elif c.item_type == 2: pen_count += 1 # PEN
		elif c.item_type == 4: noise_count += 1 # NOISE
	
	if pen_count > 0: total += drawn_cards.size() * pen_count
	total -= noise_count * 5 
	return { "total": max(0, total), "subjects": subject_scores }

func is_full_combo() -> bool:
	var drawn_subjects = []
	for c in drawn_cards:
		if c.item_type == 0:
			if not drawn_subjects.has(c.subject): drawn_subjects.append(c.subject)
	return drawn_subjects.size() == 5
