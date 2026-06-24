class_name ChickenRaceEngine
extends RefCounted

var session: GameSession
var deck: StudyDeck

var hand_cards: Array[Dictionary] = []
var has_bursted: bool = false

func setup(p_session: GameSession) -> void:
	session = p_session
	deck = p_session.player_deck
	reset_for_hour()

func reset_for_hour() -> void:
	hand_cards.clear()
	has_bursted = false

func draw_card() -> Dictionary:
	if has_bursted:
		return {}
		
	var card = deck.draw_card()
	if card.is_empty():
		return {}
		
	hand_cards.append(card)
	return card

func apply_deck_startup_items(is_tutorial: bool) -> void:
	pass

func check_burst() -> bool:
	if has_bursted:
		return true
			
	if deck.check_burst():
		has_bursted = true
		
	return has_bursted

func calculate_hand_score() -> int:
	if has_bursted:
		return 0
	return deck.calculate_hand_score()["total_score"]
