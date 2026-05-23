class_name StudyDeck
extends RefCounted

const CardDataScript = preload("res://scripts/data/CardData.gd")
const GameBalanceScript = preload("res://scripts/core/GameBalance.gd")

var deck: Array = []
var drawn_cards: Array = []
var used_cards: Array = []

var burst_shield_charges: int = 0
var next_card_multiplier: float = 1.0
var has_energy_drink_shield: bool = false
var next_card_double_score: bool = false
var sticky_note_bonus_active: bool = false
var cheat_sheet_count: int = 0
var flash_card_count: int = 0
var answer_key_count: int = 0
var study_group_chat_count: int = 0
var noise_canceling_count: int = 0
var cram_school_count: int = 0
var latte_charges: int = 0
var blue_pen_charges: int = 0
var seat_cushion_count: int = 0
var timer_count: int = 0


func reset_for_next_day() -> void:
	deck.append_array(drawn_cards)
	deck.append_array(used_cards)
	drawn_cards.clear()
	used_cards.clear()

	burst_shield_charges = 0
	next_card_multiplier = 1.0
	has_energy_drink_shield = false
	next_card_double_score = false
	sticky_note_bonus_active = false
	cheat_sheet_count = 0
	flash_card_count = 0
	answer_key_count = 0
	study_group_chat_count = 0
	noise_canceling_count = 0
	cram_school_count = 0
	latte_charges = 0
	blue_pen_charges = 0
	seat_cushion_count = 0
	timer_count = 0

	for c in deck:
		c.is_active = true

	deck.shuffle()


func build_initial_deck() -> void:
	deck.clear()
	drawn_cards.clear()
	used_cards.clear()
	CardDataScript.next_id = 0

	for i in range(1, 11):
		var item_type = Global.current_loadout.get(i, Enums.ItemType.STICKY_NOTE)
		for _j in range(i):
			deck.append(CardDataScript.new(item_type, i))

	reset_for_next_day()


func add_item_card(item_type: int, number: int = -1) -> void:
	if number < 1:
		number = GameBalanceScript.loadout_number_for_item(item_type)
	var _removed = remove_card_by_number(number)
	deck.append(CardDataScript.new(item_type, number))
	deck.shuffle()


func remove_card_by_number(number: int) -> bool:
	for i in range(deck.size()):
		if deck[i].number == number:
			deck.remove_at(i)
			return true
	for i in range(used_cards.size()):
		if used_cards[i].number == number:
			used_cards.remove_at(i)
			return true
	return false


func remove_target_card(target_item_type: int, target_number: int) -> bool:
	for i in range(deck.size()):
		if deck[i].number == target_number and deck[i].item_type == target_item_type:
			deck.remove_at(i)
			return true
	for i in range(used_cards.size()):
		if used_cards[i].number == target_number and used_cards[i].item_type == target_item_type:
			used_cards.remove_at(i)
			return true
	return false


func draw() -> Dictionary:
	if deck.is_empty():
		if not used_cards.is_empty():
			deck = used_cards.duplicate()
			used_cards.clear()
			for c in deck:
				c.is_active = true
			deck.shuffle()
		else:
			return {"card": null, "burst": false, "prevented": false}

	var card = deck.pop_back()
	var is_burst = _check_burst(card)
	var prevented = false

	if is_burst:
		if burst_shield_charges > 0:
			burst_shield_charges -= 1
			has_energy_drink_shield = burst_shield_charges > 0
			is_burst = false
			prevented = true
			drawn_cards.append(card)
		else:
			drawn_cards.append(card)
	else:
		drawn_cards.append(card)

	return {"card": card, "burst": is_burst, "prevented": prevented}


func draw_best_of_two() -> Dictionary:
	var peeked: Array = []
	for _i in range(min(2, deck.size())):
		peeked.append(deck.pop_back())
	if peeked.is_empty():
		return {"card": null, "burst": false, "prevented": false}

	var chosen = peeked[0]
	if peeked.size() == 2:
		var first_burst = _check_burst(peeked[0])
		var second_burst = _check_burst(peeked[1])
		if first_burst and not second_burst:
			chosen = peeked[1]
		elif first_burst == second_burst and peeked[1].number > peeked[0].number:
			chosen = peeked[1]

	for card in peeked:
		if card == chosen:
			continue
		deck.push_front(card)

	var is_burst = _check_burst(chosen)
	var prevented = false
	if is_burst and burst_shield_charges > 0:
		burst_shield_charges -= 1
		is_burst = false
		prevented = true
	drawn_cards.append(chosen)
	return {"card": chosen, "burst": is_burst, "prevented": prevented}


func reserve_best_of_four() -> void:
	var look_count: int = mini(4, deck.size())
	if look_count <= 1:
		return
	var candidates: Array = []
	for _i in range(look_count):
		candidates.append(deck.pop_back())

	candidates.sort_custom(func(a: CardData, b: CardData) -> bool:
		var a_burst: bool = _check_burst(a)
		var b_burst: bool = _check_burst(b)
		if a_burst != b_burst:
			return not a_burst and b_burst
		return a.number > b.number
	)

	var chosen = candidates.pop_front()
	deck.push_back(chosen)
	for c in candidates:
		deck.push_front(c)


func _check_burst(card: CardData) -> bool:
	for c in drawn_cards:
		if c.is_active and c.number == card.number:
			return true
	return false


func active_cards() -> Array:
	var cards: Array = []
	for c in drawn_cards:
		if c.is_active:
			cards.append(c)
	return cards


func current_burst_probability() -> float:
	var total_deck = deck.size()
	if total_deck == 0:
		return 0.0
	var conflict_count = 0
	for c in deck:
		for dc in drawn_cards:
			if dc.is_active and dc.number == c.number:
				conflict_count += 1
				break
	return float(conflict_count) / float(total_deck)


func calculate_scores() -> Dictionary:
	var total = 0
	var current_combo = 0
	var last_subject = Enums.Subject.NONE
	var collected_subjects := {}
	var blue_pen_ready = blue_pen_charges
	var pending_multiplier = next_card_multiplier

	for c in drawn_cards:
		if not c.is_active:
			continue

		var subject = Enums.ITEM_SUBJECT_MAP.get(c.item_type, Enums.Subject.NONE)
		if subject != Enums.Subject.NONE:
			collected_subjects[subject] = true
			if subject == last_subject:
				current_combo += 1
			else:
				current_combo = 1
			last_subject = subject
		else:
			current_combo = 0
			last_subject = Enums.Subject.NONE

		var combo_bonus = 0
		if current_combo > 1:
			combo_bonus = (current_combo - 1) * (GameBalanceScript.COMBO_BONUS_PER_STACK + flash_card_count * GameBalanceScript.FLASH_CARD_COMBO_BOOST)

		var score_to_add = c.number + combo_bonus

		match c.item_type:
			Enums.ItemType.COMPASS:
				score_to_add += GameBalanceScript.DRAW_BONUS_COMPASS
			Enums.ItemType.MECHANICAL_PENCIL:
				score_to_add += GameBalanceScript.DRAW_BONUS_MECHANICAL_PENCIL
			Enums.ItemType.ALL_NIGHTER:
				score_to_add += GameBalanceScript.DRAW_BONUS_ALL_NIGHTER
			Enums.ItemType.CAFE_LATTE:
				if latte_charges > 0:
					score_to_add += GameBalanceScript.DRAW_BONUS_CAFE_LATTE
			Enums.ItemType.HIGHLIGHTER:
				if _is_smallest_active_number(c.number):
					score_to_add += GameBalanceScript.HIGHLIGHTER_BONUS

		if blue_pen_ready > 0 and subject != Enums.Subject.NONE:
			score_to_add += GameBalanceScript.BLUE_PEN_CHAIN_BONUS
			blue_pen_ready -= 1

		if pending_multiplier > 1.0:
			score_to_add = int(round(float(score_to_add) * pending_multiplier))
			pending_multiplier = 1.0

		total += score_to_add

		if c.item_type == Enums.ItemType.RED_SHEET:
			pending_multiplier = GameBalanceScript.RED_SHEET_MULTIPLIER

	var is_five_subjects_complete = false
	if collected_subjects.has(Enums.Subject.JAPANESE) and collected_subjects.has(Enums.Subject.MATH) and collected_subjects.has(Enums.Subject.ENGLISH) and collected_subjects.has(Enums.Subject.SCIENCE) and collected_subjects.has(Enums.Subject.SOCIAL_STUDIES):
		is_five_subjects_complete = true
		total += GameBalanceScript.five_subjects_bonus(total, cram_school_count)

	return {"total": total, "combo": current_combo, "five_subjects": is_five_subjects_complete}


func _is_smallest_active_number(number: int) -> bool:
	var smallest := 999
	for c in drawn_cards:
		if c.is_active:
			smallest = mini(smallest, c.number)
	return number == smallest


func finalize_score() -> int:
	var score_dict = calculate_scores()
	var final_score = score_dict["total"]
	if sticky_note_bonus_active:
		final_score += GameBalanceScript.STOP_BONUS_STICKY_NOTE
	if seat_cushion_count > 0:
		final_score += seat_cushion_count * GameBalanceScript.STOP_BONUS_SEAT_CUSHION
	if timer_count > 0:
		var tension_bonus = int(round(current_burst_probability() * 100.0 / 20.0)) * GameBalanceScript.STOP_BONUS_TIMER
		final_score += mini(timer_count * GameBalanceScript.STOP_BONUS_TIMER, tension_bonus)
	for c in drawn_cards:
		if c.is_active and c.item_type == Enums.ItemType.RULER:
			final_score += GameBalanceScript.STOP_BONUS_RULER
			break
	return final_score
