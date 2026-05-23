class_name GameSession
extends Node

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")

var deck
var current_score: int = 0
var accumulated_score: int = 0
var current_combo: int = 0
var is_five_subjects_complete: bool = false
var hidden_bonus_score: int = 0
var current_hour: int = 1

var ai_manager: RefCounted


func _init():
	deck = StudyDeckScript.new()
	ai_manager = load("res://scripts/core/AIManager.gd").new()
	accumulated_score = 0
	hidden_bonus_score = 0
	current_hour = 1


func setup_session():
	deck.build_initial_deck()
	current_score = 0
	accumulated_score = 0
	hidden_bonus_score = 0
	sync_scores()


func start_new_day():
	deck.reset_for_next_day()
	current_hour = 1
	ai_manager.start_new_day()
	ai_manager.simulate_daily_action()
	sync_scores()


func draw_card() -> Dictionary:
	var result = deck.draw()
	if result["card"] != null:
		Global.increment_item_usage(result["card"].item_type)
	sync_scores()
	return result


func draw_best_of_two() -> Dictionary:
	var result = deck.draw_best_of_two()
	if result["card"] != null:
		Global.increment_item_usage(result["card"].item_type)
	sync_scores()
	return result


func apply_item_effect(item_type: int) -> void:
	match item_type:
		Enums.ItemType.ERASER:
			_erase_latest_active_card()
		Enums.ItemType.ENERGY_DRINK:
			deck.burst_shield_charges += 1
			deck.has_energy_drink_shield = true
		Enums.ItemType.WORD_BOOK:
			_apply_word_book_effect()
		Enums.ItemType.THICK_BOOK:
			pass
		Enums.ItemType.STICKY_NOTE:
			deck.sticky_note_bonus_active = true
		Enums.ItemType.RED_SHEET:
			deck.next_card_double_score = true
		Enums.ItemType.CHEAT_SHEET:
			deck.cheat_sheet_count += 1
		Enums.ItemType.FLASH_CARD:
			deck.flash_card_count += 1
		Enums.ItemType.LUCKY_CHARM:
			pass
		Enums.ItemType.ALL_NIGHTER:
			deck.answer_key_count += 1
		Enums.ItemType.ANSWER_KEY:
			deck.answer_key_count += 1
		Enums.ItemType.TIMER:
			deck.timer_count += 1
		Enums.ItemType.STUDY_GROUP_CHAT:
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
		Enums.ItemType.MEMO_APP:
			deck.study_group_chat_count += 1
	sync_scores()


func _erase_latest_active_card() -> void:
	for i in range(deck.drawn_cards.size() - 1, -1, -1):
		var c = deck.drawn_cards[i]
		if c.item_type != Enums.ItemType.ERASER and c.is_active:
			c.is_active = false
			break


func _apply_word_book_effect() -> void:
	var look_count = min(3, deck.deck.size())
	if look_count <= 0:
		return

	var cards_to_check = []
	for _i in range(look_count):
		cards_to_check.append(deck.deck.pop_back())

	var safe_cards = []
	var danger_cards = []
	for c in cards_to_check:
		if deck._check_burst(c):
			danger_cards.append(c)
		else:
			safe_cards.append(c)

	for dc in danger_cards:
		deck.deck.push_front(dc)
	for sc in safe_cards:
		deck.deck.push_back(sc)


func sync_scores() -> void:
	var calc = deck.calculate_scores()
	current_score = calc["total"]
	current_combo = calc["combo"]
	is_five_subjects_complete = calc["five_subjects"]


func stop_period() -> void:
	var final_period_score = deck.finalize_score()
	accumulated_score += final_period_score
	current_score = 0

	deck.used_cards.append_array(deck.drawn_cards)
	deck.drawn_cards.clear()
	deck.burst_shield_charges = 0
	deck.has_energy_drink_shield = false
	deck.next_card_multiplier = 1.0
	deck.next_card_double_score = false
	deck.sticky_note_bonus_active = false
	deck.flash_card_count = 0
	deck.answer_key_count = 0
	deck.study_group_chat_count = 0
	deck.noise_canceling_count = 0
	deck.cram_school_count = 0
	deck.latte_charges = 0
	deck.blue_pen_charges = 0
	deck.seat_cushion_count = 0
	deck.timer_count = 0
	sync_scores()


func burst_period() -> void:
	current_score = 0
	deck.used_cards.append_array(deck.drawn_cards)
	deck.drawn_cards.clear()
	deck.burst_shield_charges = 0
	deck.has_energy_drink_shield = false
	deck.next_card_multiplier = 1.0
	deck.next_card_double_score = false
	deck.sticky_note_bonus_active = false
	deck.flash_card_count = 0
	deck.answer_key_count = 0
	deck.study_group_chat_count = 0
	deck.noise_canceling_count = 0
	deck.cram_school_count = 0
	deck.latte_charges = 0
	deck.blue_pen_charges = 0
	deck.seat_cushion_count = 0
	deck.timer_count = 0
	sync_scores()


func stop_and_report() -> int:
	return accumulated_score
