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
		
	if Global.is_tutorial_mode:
		var hour = session.current_hour if session else 1
		var step = deck.hand.size()
		var val = 1
		match hour:
			1:
				match step:
					0: val = 5
					1: val = 4
					_: val = 1
			2:
				match step:
					0: val = 6
					1: val = 3
					2: val = 4
					_: val = 1
			3:
				match step:
					0: val = 7
					1: val = 7 # 意図的にバーストさせる
					_: val = 7
					
		var tut_card = {
			"value": val,
			"name": str(val) + "のカード"
		}
		deck.hand.append(tut_card)
		return tut_card
		
	var card = deck.draw_card()
	if card.is_empty():
		return {}
		
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
