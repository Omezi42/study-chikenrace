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
var cram_school_print_active: bool = false
var timer_active: bool = false
var compass_active: bool = false
var amulet_active: bool = false

# Initialize the 55-card deck based on a slots configuration (1-10)
func initialize_deck(deck_config: Dictionary) -> void:
	cards.clear()
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	
	# For each slot N (1 to 10), insert N copies of the card
	var max_slots = 10
	if Global.game_mode == Constants.MODE_OVERNIGHT:
		max_slots = 8 # 一夜漬けモード時は36枚のミニデッキでバースト高確率化
		
	for slot_idx in range(1, max_slots + 1):
		var item_id = deck_config.get(slot_idx, "")
		if item_id == "" or not item_id in CardData.ITEMS:
			# Fallback to sticky note
			item_id = "item_sticky_note"
			
		var item_info = CardData.ITEMS[item_id]
		
		# Generate slot_idx cards
		for c_idx in range(slot_idx):
			var card = {
				"value": slot_idx,
				"item_id": item_id,
				"name": item_info["name"]
			}
			cards.append(card)
			
	# Copy to draw pile and shuffle
	draw_pile = cards.duplicate()
	shuffle_draw_pile()
	
	if Global.is_tutorial_mode:
		draw_pile.clear()
		var tutorial_cards = [
			{
				"value": 3,
				"item_id": "item_ruler",
				"name": "定規"
			},
			{
				"value": 3,
				"item_id": "item_ruler",
				"name": "定規"
			},
			{
				"value": 5,
				"item_id": "item_sticky_note",
				"name": "付箋"
			},
			{
				"value": 8,
				"item_id": "item_wordbook",
				"name": "単語帳"
			}
		]
		cards.clear()
		for card in tutorial_cards:
			cards.append(card)
			draw_pile.append(card)
	
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
func draw_card(max_depth: int = 5) -> Dictionary:
	if max_depth <= 0:
		return {} # Recursion guard
		
	if draw_pile.size() == 0:
		if discard_pile.size() > 0:
			# Recycle discard pile
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			shuffle_draw_pile()
		else:
			return {} # No cards available

	var original_card = draw_pile.pop_back()
	var card = original_card.duplicate()
	
	# Apply Red Sheet (赤シート) effect if active
	# Safe draw: if card causes a burst, discard it and draw another (one time)
	if red_sheet_active and would_card_burst(card):
		red_sheet_active = false
		discard_pile.append(original_card)
		return draw_card(max_depth - 1) # Recursive draw
		
	# Apply Eraser (消しゴム) charges
	if would_card_burst(card) and eraser_charges > 0:
		eraser_charges -= 1
		# Put back to draw pile, shuffle, and draw again
		draw_pile.append(original_card)
		shuffle_draw_pile()
		return draw_card(max_depth - 1)
		
	# Apply Mech Pencil (シャーペン) points bonus (+3 points to next drawn cards)
	if next_draw_bonus_points > 0:
		card["bonus_points"] = 3
		next_draw_bonus_points -= 1
	else:
		card["bonus_points"] = 0
		
	if card.get("item_id", "") == "item_amulet":
		amulet_active = true
		
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

# Get burst chance for energy drink (10% per card drawn after 3, first 3 cards are safe)
func get_energy_drink_burst_chance() -> float:
	var draw_count = hand.size()
	return max(0.0, float(draw_count - 3) * 0.10)

# Calculate scores with new simplified mechanics
func calculate_hand_score() -> Dictionary:
	var subtotal = 0
	
	# Sum values and apply modifiers
	for card in hand:
		var val = card["value"]
		var bonus = card.get("bonus_points", 0)
		subtotal += val + bonus
		
	# Apply Highlighter (蛍光ペン) multiplier: +1 point to each card drawn
	if highlighter_active:
		subtotal += hand.size() * 1
		
	# Apply Blue Pen (青ペン) multiplier: +2 points to each card drawn
	if blue_pen_active:
		subtotal += hand.size() * 2
		
	var total_score = subtotal
	
	# Apply Cram School Print (塾プリント) static bonus
	if cram_school_print_active:
		total_score += 10
	
	# Apply Energy Drink (エナジードリンク) multiplier (doubles total score)
	if energy_drink_active:
		total_score *= 2
		
	return {
		"subtotal": subtotal,
		"total_score": total_score
	}

# Reset status effects
func reset_status_effects() -> void:
	next_draw_bonus_points = 0
	eraser_charges = 0
	highlighter_active = false
	blue_pen_active = false
	red_sheet_active = false
	energy_drink_active = false
	cram_school_print_active = false
	timer_active = false
	compass_active = false
	amulet_active = false

# End of period (hour): Move hand to discard pile, keep draw and discard piles as is for day-long counting
func reset_for_next_hour() -> void:
	for card in hand:
		discard_pile.append(card.duplicate())
	hand.clear()
	reset_status_effects()

# Start of new day: completely reset deck to initial state (recycle all cards, shuffle draw pile)
func reset_for_next_day() -> void:
	hand.clear()
	discard_pile.clear()
	draw_pile = cards.duplicate()
	if not Global.is_tutorial_mode:
		shuffle_draw_pile()
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

func peek_cards(count: int) -> Array[Dictionary]:
	var peeked: Array[Dictionary] = []
	var n = draw_pile.size()
	for i in range(1, count + 1):
		if n - i >= 0:
			peeked.append(draw_pile[n - i])
	return peeked

func activate_memo_cards(hand_idx: int) -> bool:
	if hand.size() > 0 and draw_pile.size() > 0 and hand_idx >= 0 and hand_idx < hand.size():
		var hand_card = hand[hand_idx]
		var deck_card_raw = draw_pile.pop_back()
		
		var deck_card = deck_card_raw.duplicate()
		# Apply Mech Pencil (シャーペン) points bonus (+3 points to next drawn cards)
		if next_draw_bonus_points > 0:
			deck_card["bonus_points"] = 3
			next_draw_bonus_points -= 1
		else:
			deck_card["bonus_points"] = 0
			
		if deck_card.get("item_id", "") == "item_amulet":
			amulet_active = true
			
		hand[hand_idx] = deck_card
		draw_pile.append(hand_card)
		return true
	return false

# Memo App: draw 2 cards without auto discarding
func activate_memo_app_draw() -> Array[Dictionary]:
	var drawn_cards: Array[Dictionary] = []
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

func activate_compass_indices() -> Array[int]:
	var hand_values = []
	for c in hand:
		hand_values.append(c["value"])
	var indices: Array[int] = []
	var n = draw_pile.size()
	for i in range(n):
		var card = draw_pile[n - 1 - i]
		if card["value"] in hand_values:
			indices.append(i + 1)
	return indices

func activate_thick_book() -> void:
	for i in range(3):
		var card = {
			"value": 15,
			"item_id": "item_thick_book",
			"name": "高得点講義"
		}
		_safe_add_to_draw_pile(card)
	shuffle_draw_pile()

func activate_night_note() -> void:
	if hand.size() > 0:
		var rand_card = hand[randi() % hand.size()]
		var dup_card = {
			"value": rand_card["value"],
			"item_id": rand_card.get("item_id", ""),
			"name": rand_card.get("name", "")
		}
		_safe_add_to_draw_pile(dup_card)
		shuffle_draw_pile()

func _safe_add_to_draw_pile(card: Dictionary) -> void:
	draw_pile.append(card)



func activate_cafe_latte() -> Dictionary:
	if draw_pile.size() == 0 and discard_pile.size() == 0:
		return {}
		
	var hand_values = []
	for c in hand:
		hand_values.append(c["value"])
		
	var safe_card_index_in_draw = -1
	for i in range(draw_pile.size()):
		if not draw_pile[i]["value"] in hand_values:
			safe_card_index_in_draw = i
			break
			
	# If not found in draw pile, check if we can recycle discard pile to find one
	if safe_card_index_in_draw == -1:
		var safe_in_discard = false
		for c in discard_pile:
			if not c["value"] in hand_values:
				safe_in_discard = true
				break
		if safe_in_discard:
			# Recycle discard pile and shuffle
			draw_pile.append_array(discard_pile.duplicate())
			discard_pile.clear()
			shuffle_draw_pile()
			# Re-scan draw pile
			for i in range(draw_pile.size()):
				if not draw_pile[i]["value"] in hand_values:
					safe_card_index_in_draw = i
					break
					
	# If still no safe card exists, return empty dictionary
	if safe_card_index_in_draw == -1:
		return {}
		
	# Extract the safe card
	var card = draw_pile[safe_card_index_in_draw]
	draw_pile.remove_at(safe_card_index_in_draw)
	
	var card_clone = card.duplicate()
	
	# Apply Mech Pencil (シャーペン) points bonus (+3 points to next drawn cards)
	if next_draw_bonus_points > 0:
		card_clone["bonus_points"] = 3
		next_draw_bonus_points -= 1
	else:
		card_clone["bonus_points"] = 0
		
	if card_clone.get("item_id", "") == "item_amulet":
		amulet_active = true
		
	# Add to hand
	hand.append(card_clone)
	return card_clone

# Forget Notebook: Discard the lowest value card in the hand to discard pile.
func activate_forget_notebook() -> int:
	if hand.size() == 0:
		return 0
	var lowest_idx = 0
	var lowest_val = 99
	for i in range(hand.size()):
		if hand[i]["value"] < lowest_val:
			lowest_val = hand[i]["value"]
			lowest_idx = i
	if lowest_val != 99:
		var discarded = hand[lowest_idx]
		hand.remove_at(lowest_idx)
		discard_pile.append(discarded)
		return lowest_val
	return 0
