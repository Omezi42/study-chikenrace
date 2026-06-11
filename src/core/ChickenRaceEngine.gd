class_name ChickenRaceEngine
extends RefCounted

# Decouples core chicken race gameplay logic from the UI presenter (ChickenRacePhase).
# Manages hand, draw actions, burst validation, and item effect applications.

var session: GameSession
var deck: StudyDeck

var hand_cards: Array[Dictionary] = []
var active_used_items: Array[String] = []
var has_bursted: bool = false

func setup(p_session: GameSession) -> void:
	session = p_session
	deck = p_session.player_deck
	reset_for_hour()

func reset_for_hour() -> void:
	hand_cards.clear()
	active_used_items.clear()
	has_bursted = false

# Perform draw action. Returns the drawn card, or an empty Dictionary if empty.
func draw_card() -> Dictionary:
	if has_bursted:
		return {}
		
	var card = deck.draw_card()
	if card.is_empty():
		return {}
		
	hand_cards.append(card)
	
	var item_id: String = str(card.get("item_id", ""))
	if item_id != "" and not item_id in active_used_items:
		active_used_items.append(item_id)
		
	return card

# Apply startup deck items.
func apply_deck_startup_items(is_tutorial: bool) -> void:
	for slot_idx in Global.current_deck.keys():
		var item = Global.current_deck[slot_idx]
		if item == "item_eraser" and (is_tutorial or randf() < 0.5):
			deck.eraser_charges += 1
			if not "item_eraser" in active_used_items:
				active_used_items.append("item_eraser")
		elif item == "item_red_sheet" and randf() < 0.3:
			deck.red_sheet_active = true
			if not "item_red_sheet" in active_used_items:
				active_used_items.append("item_red_sheet")
		elif item == "item_mech_pencil" and randf() < 0.4:
			deck.next_draw_bonus_points += 2
			if not "item_mech_pencil" in active_used_items:
				active_used_items.append("item_mech_pencil")

# Checks for burst status, considering energy drink side effects.
func check_burst() -> bool:
	if has_bursted:
		return true
		
	# Energy drink side effect
	var is_energy_burst = false
	if deck.energy_drink_active and deck.hand.size() > 1:
		var burst_chance = deck.get_energy_drink_burst_chance()
		if burst_chance > 0 and randf() < burst_chance:
			is_energy_burst = true
			
	if is_energy_burst or deck.check_burst():
		has_bursted = true
		
	return has_bursted

func calculate_hand_score() -> int:
	if has_bursted:
		var has_amulet = deck.amulet_active
		if has_amulet:
			var score_info = deck.calculate_hand_score()
			return int(round(score_info["total_score"] * 0.5))
		return 0
	return deck.calculate_hand_score()["total_score"]
