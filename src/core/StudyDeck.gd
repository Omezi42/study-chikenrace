class_name StudyDeck
extends RefCounted

var cards: Array[Dictionary] = []
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []

# Active temporary effects for the current hour
var next_draw_bonus_points: int = 0
var eraser_charges: int = 0
var highlighter_active: bool = false
var blue_pen_active: bool = false
var red_sheet_active: bool = false
var energy_drink_active: bool = false

# Available subjects for random assignment
const VALID_SUBJECTS = [
	CardData.SUBJECT_MATH,
	CardData.SUBJECT_ENGLISH,
	CardData.SUBJECT_JAPANESE,
	CardData.SUBJECT_SCIENCE,
	CardData.SUBJECT_SOCIAL
]

# Initialize the 55-card deck based on a slots configuration (1-10)
func initialize_deck(deck_config: Dictionary) -> void:
	cards.clear()
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	
	# For each slot N (1 to 10), insert N copies of the card
	for slot_idx in range(1, 11):
		var item_id = deck_config.get(slot_idx, "")
		if item_id == "" or not item_id in CardData.ITEMS:
			# Fallback to sticky note
			item_id = "item_sticky_note"
			
		var item_info = CardData.ITEMS[item_id]
		var item_subject = item_info["subject"]
		
		# Generate slot_idx cards
		for c_idx in range(slot_idx):
			var final_subject = item_subject
			# If the item doesn't have a locked subject, assign one randomly
			if final_subject == CardData.SUBJECT_NONE:
				final_subject = VALID_SUBJECTS[randi() % VALID_SUBJECTS.size()]
				
			var card = {
				"value": slot_idx,
				"subject": final_subject,
				"item_id": item_id,
				"name": item_info["name"]
			}
			cards.append(card)
			
	# Copy to draw pile and shuffle
	draw_pile = cards.duplicate()
	shuffle_draw_pile()
	
	if Global.is_tutorial_mode:
		var tutorial_cards = [
			{
				"value": 5,
				"subject": CardData.SUBJECT_SCIENCE,
				"item_id": "item_eraser",
				"name": "消しゴム"
			},
			{
				"value": 8,
				"subject": CardData.SUBJECT_ENGLISH,
				"item_id": "item_wordbook",
				"name": "単語帳"
			},
			{
				"value": 3,
				"subject": CardData.SUBJECT_MATH,
				"item_id": "item_ruler",
				"name": "定規"
			},
			{
				"value": 5,
				"subject": CardData.SUBJECT_MATH,
				"item_id": "item_sticky_note",
				"name": "付箋"
			}
		]
		var filtered: Array[Dictionary] = []
		for card in draw_pile:
			if card["value"] in [3, 5, 8]:
				continue
			filtered.append(card)
		filtered.append_array(tutorial_cards)
		draw_pile = filtered
	
	# Reset status effects
	reset_status_effects()

# Shuffle the draw pile
func shuffle_draw_pile() -> void:
	# Fisher-Yates shuffle
	var n = draw_pile.size()
	for i in range(n - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = temp

# Draw the top card
func draw_card() -> Dictionary:
	if draw_pile.size() == 0:
		if discard_pile.size() > 0:
			# Recycle discard pile
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			shuffle_draw_pile()
		else:
			return {} # No cards available

	var card = draw_pile.pop_back()
	
	# Apply Red Sheet (赤シート) effect if active
	# Safe draw: if card causes a burst, discard it and draw another (one time)
	if red_sheet_active and would_card_burst(card):
		red_sheet_active = false
		discard_pile.append(card)
		return draw_card() # Recursive draw
		
	# Apply Eraser (消しゴム) charges
	if would_card_burst(card) and eraser_charges > 0:
		eraser_charges -= 1
		# Put back to draw pile, shuffle, and draw again
		draw_pile.append(card)
		shuffle_draw_pile()
		return draw_card()
		
	# Apply Mech Pencil (シャーペン) points bonus (+3 points to next drawn cards)
	if next_draw_bonus_points > 0:
		card["bonus_points"] = 3
		next_draw_bonus_points -= 1
	else:
		card["bonus_points"] = 0
		
	hand.append(card)
	return card

# Helper: check if a card would burst the current hand
func would_card_burst(card: Dictionary) -> bool:
	if card.get("value", 0) == 0:
		return false
	for c in hand:
		if c["value"] == card["value"]:
			return true
	return false

# Check if hand currently contains a duplicate value
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

# Returns the probability of bursting on the next draw (0.0 to 1.0)
func get_burst_probability() -> float:
	if draw_pile.size() == 0 and discard_pile.size() == 0:
		return 0.0
		
	# Calculate how many cards in the draw/discard piles would cause a burst
	var hand_values = []
	for card in hand:
		hand_values.append(card["value"])
		
	var total_cards = draw_pile.size() + discard_pile.size()
	var burst_cards = 0
	
	# Check draw pile
	for card in draw_pile:
		if card["value"] in hand_values:
			burst_cards += 1
			
	# Check discard pile
	for card in discard_pile:
		if card["value"] in hand_values:
			burst_cards += 1
			
	return float(burst_cards) / float(total_cards)

# Calculate scores, combos, and five-subject bonuses
func calculate_hand_score() -> Dictionary:
	var subtotal = 0
	var wildcard_count = 0
	var subjects_in_hand = {}
	
	# Sum values and apply modifiers
	for card in hand:
		var val = card["value"]
		var bonus = card.get("bonus_points", 0)
		var item_id = card["item_id"]
		var subject = card["subject"]
		
		# Blue Pen (青ペン) multiplies Japanese/English card values by 1.5
		var multiplier = 1.0
		if blue_pen_active and (subject == CardData.SUBJECT_JAPANESE or subject == CardData.SUBJECT_ENGLISH):
			multiplier = 1.5
			
		subtotal += int(round((val + bonus) * multiplier))
		
		# Cram School Print (塾プリント) is a wildcard subject
		if item_id == "item_cram_school_print":
			wildcard_count += 1
		else:
			subjects_in_hand[subject] = true
			
	# Calculate consecutive subject combo bonus
	var combo_bonus = 0
	var current_combo_streak = 1
	var last_subject = ""
	
	for i in range(hand.size()):
		var subject = hand[i]["subject"]
		var item_id = hand[i]["item_id"]
		
		if i > 0:
			# Wildcard only matches the previous subject to keep combo alive
			if item_id == "item_cram_school_print":
				current_combo_streak += 1
				# Do NOT update last_subject, so it acts as the previous subject
				continue
			elif last_subject == "" or subject == last_subject:
				current_combo_streak += 1
			else:
				# Resolve previous streak
				if current_combo_streak >= 2:
					combo_bonus += get_streak_bonus(current_combo_streak)
				current_combo_streak = 1
				
		last_subject = subject
		
	# Catch trailing streak
	if current_combo_streak >= 2:
		combo_bonus += get_streak_bonus(current_combo_streak)
		
	# Apply Highlighter (蛍光ペン) 1.5x multiplier on combo bonus
	if highlighter_active:
		combo_bonus = int(round(combo_bonus * 1.5))
		
	# Calculate 5-subject bonus (needs all 5 distinct subjects)
	# Wildcards can fill any missing subjects
	var distinct_subjects = subjects_in_hand.size()
	var needed_for_five = 5 - distinct_subjects
	var has_five_subjects = wildcard_count >= needed_for_five
	
	var five_subjects_bonus = 0
	if has_five_subjects:
		# five_subjects_bonus = round(subtotal * 0.22) bounded [10, 28]
		five_subjects_bonus = int(round(subtotal * 0.22))
		five_subjects_bonus = clamp(five_subjects_bonus, 10, 28)
		
	var total_score = subtotal + combo_bonus + five_subjects_bonus
	
	# Apply Energy Drink (エナジードリンク) multiplier (doubles total score)
	if energy_drink_active:
		total_score *= 2
		
	return {
		"subtotal": subtotal,
		"combo_bonus": combo_bonus,
		"five_subjects_bonus": five_subjects_bonus,
		"total_score": total_score
	}

func get_streak_bonus(streak: int) -> int:
	match streak:
		2: return 3
		3: return 7
		4: return 12
		_: return 12 + (streak - 4) * 5

# Reset status effects
func reset_status_effects() -> void:
	next_draw_bonus_points = 0
	eraser_charges = 0
	highlighter_active = false
	blue_pen_active = false
	red_sheet_active = false
	energy_drink_active = false

# End of period: recycle hand
func reset_for_next_hour() -> void:
	discard_pile.append_array(hand)
	hand.clear()
	reset_status_effects()

# Deletion card mechanic: remove a specific card value from the deck
func delete_card_value(val: int) -> bool:
	var removed = false
	
	# Remove from cards list
	for i in range(cards.size() - 1, -1, -1):
		if cards[i]["value"] == val:
			cards.remove_at(i)
			removed = true
			break
			
	# Sync draw pile
	for i in range(draw_pile.size() - 1, -1, -1):
		if draw_pile[i]["value"] == val:
			draw_pile.remove_at(i)
			break
			
	return removed

# --- Active Item Triggers ---

func activate_sticky_note() -> String:
	if draw_pile.size() == 0:
		return ""
	var chosen_sub = VALID_SUBJECTS[randi() % VALID_SUBJECTS.size()]
	for i in range(draw_pile.size() - 1, -1, -1):
		if draw_pile[i]["subject"] == chosen_sub:
			var card = draw_pile[i]
			draw_pile.remove_at(i)
			draw_pile.append(card)
			break
	return chosen_sub

func peek_cards(count: int) -> Array:
	var peeked: Array = []
	var n = draw_pile.size()
	for i in range(1, count + 1):
		if n - i >= 0:
			peeked.append(draw_pile[n - i])
	return peeked

func activate_memo_cards(hand_idx: int) -> bool:
	if hand.size() > 0 and draw_pile.size() > 0 and hand_idx >= 0 and hand_idx < hand.size():
		var hand_card = hand[hand_idx]
		var deck_card = draw_pile.pop_back()
		hand[hand_idx] = deck_card
		draw_pile.append(hand_card)
		return true
	return false

# Memo App: draw 2 cards without auto discarding
func activate_memo_app_draw() -> Array:
	var drawn_cards: Array = []
	for i in range(2):
		var c = draw_card()
		if not c.is_empty():
			drawn_cards.append(c)
	return drawn_cards

# Memo App: discard a specific card by index
func activate_memo_app_discard(hand_idx: int) -> Dictionary:
	if hand.size() > 0 and hand_idx >= 0 and hand_idx < hand.size():
		var discarded = hand[hand_idx]
		hand.remove_at(hand_idx)
		discard_pile.append(discarded)
		return discarded
	return {}

func activate_compass() -> int:
	var hand_values = []
	for c in hand:
		hand_values.append(c["value"])
	var count = 0
	for c in draw_pile:
		if c["value"] in hand_values:
			count += 1
	return count

func activate_thick_book() -> void:
	for i in range(3):
		var card = {
			"value": 15,
			"subject": VALID_SUBJECTS[randi() % VALID_SUBJECTS.size()],
			"item_id": "item_thick_book",
			"name": "高得点講義"
		}
		draw_pile.append(card)
	shuffle_draw_pile()

func activate_night_note() -> void:
	if hand.size() > 0:
		var rand_card = hand[randi() % hand.size()]
		var dup_card = rand_card.duplicate()
		draw_pile.append(dup_card)
		shuffle_draw_pile()

func activate_expected_questions() -> String:
	if draw_pile.size() == 0:
		return ""
	var chosen_sub = VALID_SUBJECTS[randi() % VALID_SUBJECTS.size()]
	var matches = []
	for i in range(draw_pile.size() - 1, -1, -1):
		if draw_pile[i]["subject"] == chosen_sub:
			matches.append(draw_pile[i])
			draw_pile.remove_at(i)
			if matches.size() == 3:
				break
	for card in matches:
		draw_pile.append(card)
	return chosen_sub

func activate_cafe_latte() -> Dictionary:
	if draw_pile.size() == 0 and discard_pile.size() == 0:
		return {}
	var card = draw_pile.pop_back()
	var attempts = 0
	while would_card_burst(card) and attempts < 10:
		discard_pile.append(card)
		if draw_pile.size() == 0:
			if discard_pile.size() > 0:
				draw_pile = discard_pile.duplicate()
				discard_pile.clear()
				shuffle_draw_pile()
			else:
				break
		card = draw_pile.pop_back()
		attempts += 1
	hand.append(card)
	return card

func activate_forget_notebook() -> int:
	var lowest_val = 99
	for c in cards:
		if c["value"] < lowest_val and c["value"] > 0:
			lowest_val = c["value"]
	if lowest_val != 99:
		delete_card_value(lowest_val)
		return lowest_val
	return 0
