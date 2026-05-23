class_name GameBalance
extends RefCounted

const BLUFF_CAP_BASE := 24
const BLUFF_CAP_PER_CHEAT_SHEET := 16
const BLUFF_EXPOSURE_REDUCTION_PER_CHEAT_SHEET := 0.06
const BLUFF_EXPOSURE_BONUS_PER_ANSWER_KEY := 0.12

const DOUBT_SUCCESS_EXTRA := 6
const DOUBT_FAIL_PENALTY_BASE := 10
const DOUBT_FAIL_PENALTY_PER_DAY := 2
const MAX_DOUBT_VOTES_PER_DAY := 3

const PLAYER_LIE_EXPOSED_EXTRA := 10

const STOP_BONUS_RULER := 8
const STOP_BONUS_STICKY_NOTE := 18
const STOP_BONUS_TIMER := 6
const STOP_BONUS_SEAT_CUSHION := 8

const DRAW_BONUS_COMPASS := 6
const DRAW_BONUS_MECHANICAL_PENCIL := 3
const DRAW_BONUS_ALL_NIGHTER := 12
const DRAW_BONUS_CAFE_LATTE := 4
const HIGHLIGHTER_BONUS := 5

const COMBO_BONUS_PER_STACK := 8
const FLASH_CARD_COMBO_BOOST := 4
const BLUE_PEN_CHAIN_BONUS := 6

const RED_SHEET_MULTIPLIER := 2.0
const FIVE_SUBJECTS_MULTIPLIER := 0.22
const FIVE_SUBJECTS_MIN_BONUS := 10
const FIVE_SUBJECTS_MAX_BONUS := 28
const CRAM_SCHOOL_FIVE_SUBJECTS_BONUS := 6


static func max_bluff_cap(cheat_sheet_count: int) -> int:
	return BLUFF_CAP_BASE + cheat_sheet_count * BLUFF_CAP_PER_CHEAT_SHEET


static func calculate_exposure_rate(bluff_amount: int, max_bluff_cap_val: int, cheat_sheet_count: int = 0, answer_key_count: int = 0) -> float:
	var ratio := 0.0
	if max_bluff_cap_val > 0:
		ratio = float(bluff_amount) / float(max_bluff_cap_val)
	var base_rate := 0.10 + ratio * 0.55
	var reduction := cheat_sheet_count * BLUFF_EXPOSURE_REDUCTION_PER_CHEAT_SHEET
	var penalty := answer_key_count * BLUFF_EXPOSURE_BONUS_PER_ANSWER_KEY
	return clampf(base_rate - reduction + penalty, 0.05, 0.85)



static func bluff_exposure_reduction(cheat_sheet_count: int) -> float:
	return min(0.24, cheat_sheet_count * BLUFF_EXPOSURE_REDUCTION_PER_CHEAT_SHEET)


static func loadout_number_for_item(item_type: int) -> int:
	for slot in range(1, 11):
		if Global.current_loadout.get(slot, -1) == item_type:
			return slot
	match item_type:
		Enums.ItemType.FLASH_CARD: return 4
		Enums.ItemType.LUCKY_CHARM: return 2
		Enums.ItemType.ALL_NIGHTER: return 9
		Enums.ItemType.ANSWER_KEY: return 6
		Enums.ItemType.HIGHLIGHTER: return 3
		Enums.ItemType.TIMER: return 5
		Enums.ItemType.STUDY_GROUP_CHAT: return 7
		Enums.ItemType.PRACTICE_TEST: return 8
		Enums.ItemType.CAFE_LATTE: return 2
		Enums.ItemType.NOISE_CANCELING: return 1
		Enums.ItemType.SEAT_CUSHION: return 3
		Enums.ItemType.BLUE_PEN: return 6
		Enums.ItemType.CRAM_SCHOOL: return 8
		Enums.ItemType.MEMO_APP: return 5
	return ((maxi(1, item_type) - 1) % 10) + 1


static func doubt_success_reward(lie_amount: int, group_chat_count: int = 0) -> int:
	return maxi(0, lie_amount) + DOUBT_SUCCESS_EXTRA + group_chat_count * 2


static func doubt_fail_penalty(day_number: int, noise_canceling_count: int = 0) -> int:
	var raw := DOUBT_FAIL_PENALTY_BASE + maxi(0, day_number - 1) * DOUBT_FAIL_PENALTY_PER_DAY
	return maxi(4, raw - noise_canceling_count * 2)


static func player_lie_exposed_penalty(lie_amount: int, answer_key_count: int = 0) -> int:
	return maxi(0, lie_amount) + PLAYER_LIE_EXPOSED_EXTRA + answer_key_count * 4


static func five_subjects_bonus(subtotal: int, cram_school_count: int = 0) -> int:
	var scaled := int(round(float(subtotal) * FIVE_SUBJECTS_MULTIPLIER))
	var bounded := clampi(scaled, FIVE_SUBJECTS_MIN_BONUS, FIVE_SUBJECTS_MAX_BONUS)
	return bounded + cram_school_count * CRAM_SCHOOL_FIVE_SUBJECTS_BONUS


static func apply_doubt_vote(game_session, rival_reported: int, rival_actual: int, is_lying_flag: bool) -> Dictionary:
	var lie := maxi(0, rival_reported - rival_actual)
	var is_lying := is_lying_flag or lie > 0
	if not is_instance_valid(game_session):
		return {"success": false, "delta": 0, "lie": lie}
	if is_lying:
		var delta := doubt_success_reward(lie, game_session.deck.study_group_chat_count)
		game_session.hidden_bonus_score += delta
		return {"success": true, "delta": delta, "lie": lie}
	var penalty := doubt_fail_penalty(Global.play_count + 1, game_session.deck.noise_canceling_count)
	game_session.hidden_bonus_score -= penalty
	return {"success": false, "delta": -penalty, "lie": 0}
