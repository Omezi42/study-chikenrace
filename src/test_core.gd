# -*- coding: utf-8 -*-
extends Node

func _ready() -> void:
	print("==================================================")
	print("     Study Chicken Race - Core Unit Tests         ")
	print("==================================================")
	
	var success = true
	success = success and test_deck_initialization()
	success = success and test_combos_and_wildcards()
	success = success and test_ai_simulation()
	success = success and test_session_showdown()
	success = success and test_title_determination()
	success = success and test_game_session_states()
	success = success and test_scenario_modes()
	success = success and test_metadata_and_integrity()
	
	print("==================================================")
	if success:
		print("  RESULT: ALL TESTS PASSED SUCCESSFULLY! (GREEN)")
	else:
		print("  RESULT: TEST FAILURE ENCOUNTERED! (RED)")
	print("==================================================")
	
	# Quit Godot engine with appropriate code (0 for success, 1 for failure)
	get_tree().quit(0 if success else 1)

# Helper assertion function
func assert_true(condition: bool, msg: String) -> bool:
	if condition:
		print("  [PASS] " + msg)
		return true
	else:
		print("  [FAIL] " + msg)
		return false

# Test 1: Deck Size & Shuffling
func test_deck_initialization() -> bool:
	print("\n--- Test 1: Deck Initialization & Operations ---")
	var deck = StudyDeck.new()
	var mock_deck_config = {
		1: "item_sticky_note",
		2: "item_eraser",
		3: "item_ruler",
		4: "item_wordbook",
		5: "item_mech_pencil",
		6: "item_memo_cards",
		7: "item_highlighter",
		8: "item_blue_pen",
		9: "item_cushion",
		10: "item_memo_app"
	}
	deck.initialize_deck(mock_deck_config)
	
	var pass_size = assert_true(deck.cards.size() == 55, "Standard deck contains exactly 55 cards.")
	
	# Draw test
	var first_card = deck.draw_card()
	var pass_draw = assert_true(not first_card.is_empty(), "Successfully drawn card.")
	var pass_hand = assert_true(deck.hand.size() == 1, "Hand contains 1 card after draw.")
	var pass_pile = assert_true(deck.draw_pile.size() == 54, "Draw pile decreases to 54 cards.")
	
	return pass_size and pass_draw and pass_hand and pass_pile

# Test 2: Combo & wildcards calculations
func test_combos_and_wildcards() -> bool:
	print("\n--- Test 2: Scoring, Combos, and Wildcards ---")
	var deck = StudyDeck.new()
	
	# Scenario A: Standard hand (no combos, distinct subjects)
	# 3 of math, 4 of english, 5 of japanese
	var hand_a: Array[Dictionary] = [
		{"value": 3, "subject": CardData.SUBJECT_MATH, "item_id": "item_sticky_note"},
		{"value": 4, "subject": CardData.SUBJECT_ENGLISH, "item_id": "item_eraser"},
		{"value": 5, "subject": CardData.SUBJECT_JAPANESE, "item_id": "item_ruler"}
	]
	deck.hand = hand_a
	var score_a = deck.calculate_hand_score()
	var pass_a = assert_true(
		score_a["subtotal"] == 12 and score_a["combo_bonus"] == 0 and score_a["five_subjects_bonus"] == 0,
		"Scenario A: Normal hand score subtotal 12, combo 0, five-subject 0."
	)
	
	# Scenario B: Consecutive subject combos
	# 3 of math, 4 of math (combo of 2), 5 of english
	var hand_b: Array[Dictionary] = [
		{"value": 3, "subject": CardData.SUBJECT_MATH, "item_id": "item_sticky_note"},
		{"value": 4, "subject": CardData.SUBJECT_MATH, "item_id": "item_eraser"},
		{"value": 5, "subject": CardData.SUBJECT_ENGLISH, "item_id": "item_ruler"}
	]
	deck.hand = hand_b
	var score_b = deck.calculate_hand_score()
	var pass_b = assert_true(
		score_b["subtotal"] == 12 and score_b["combo_bonus"] == 3,
		"Scenario B: Consecutive combo of 2 maths yields +3 bonus points."
	)
	
	# Scenario C: 5-subject bonus with Wildcard Cram School Print
	# Math, English, Japanese, Science + Wildcard. Subtotal = 25
	var hand_c: Array[Dictionary] = [
		{"value": 3, "subject": CardData.SUBJECT_MATH, "item_id": "item_sticky_note"},
		{"value": 4, "subject": CardData.SUBJECT_ENGLISH, "item_id": "item_eraser"},
		{"value": 5, "subject": CardData.SUBJECT_JAPANESE, "item_id": "item_ruler"},
		{"value": 6, "subject": CardData.SUBJECT_SCIENCE, "item_id": "item_wordbook"},
		{"value": 7, "subject": CardData.SUBJECT_NONE, "item_id": "item_cram_school_print"}
	]
	deck.hand = hand_c
	var score_c = deck.calculate_hand_score()
	var pass_c = assert_true(
		score_c["five_subjects_bonus"] == 10,
		"Scenario C: Wildcard completes 5-subject set, yielding bounded +10 points bonus."
	)
	
	# Scenario D: Long consecutive subject combo capped at 25
	# 8 consecutive math cards (streak = 8)
	var hand_d: Array[Dictionary] = []
	for i in range(8):
		hand_d.append({"value": 3, "subject": CardData.SUBJECT_MATH, "item_id": "item_sticky_note"})
	deck.hand = hand_d
	var score_d = deck.calculate_hand_score()
	var pass_d = assert_true(
		score_d["combo_bonus"] == 25,
		"Scenario D: 8 consecutive subjects yields combo bonus capped at 25 points. (Actual: %d)" % score_d["combo_bonus"]
	)
	
	return pass_a and pass_b and pass_c and pass_d

# Test 3: AI Simulation functions
func test_ai_simulation() -> bool:
	print("\n--- Test 3: AI Day Simulation & Bluff Decision ---")
	Global.opponent_profiles.clear()
	var sim = AIManager.simulate_cpu_day("cpu_sato", 1)
	var pass_sim = assert_true(
		sim.has("actual_score") and sim.has("hours") and sim["hours"].size() >= 3,
		"Simulate Cautious CPU day returns actual score and hours log."
	)
	
	var declared = AIManager.calculate_cpu_bluff("cpu_sato", sim["actual_score"])
	var pass_bluff = assert_true(
		declared >= sim["actual_score"] and declared <= sim["actual_score"] + 24,
		"Bluff generator does not exceed Cautious limits."
	)
	
	return pass_sim and pass_bluff

# Test 4: Game Session showdown evaluation
func test_session_showdown() -> bool:
	print("\n--- Test 4: Game Session Showdown Logic ---")
	Global.game_mode = Constants.MODE_CPU
	Global.opponent_profiles = {
		"cpu_sato": {"id": "cpu_sato", "name": "佐藤くん"},
		"cpu_suzuki": {"id": "cpu_suzuki", "name": "鈴木さん"},
		"cpu_takahashi": {"id": "cpu_takahashi", "name": "高橋くん"}
	}
	
	var session = GameSession.new()
	var mock_deck_config = {
		1: "item_sticky_note",
		2: "item_eraser",
		3: "item_ruler",
		4: "item_wordbook",
		5: "item_mech_pencil",
		6: "item_memo_cards",
		7: "item_highlighter",
		8: "item_blue_pen",
		9: "item_cushion",
		10: "item_memo_app"
	}
	session.start_session(mock_deck_config)
	
	# Simulate days 1 to 5 manually for testing
	for day in range(1, 6):
		session.current_day = day
		session.player_actual_score_today = 50
		session.player_declared_score_today = 60 # Player bluffs by +10
		
		var mock_hours: Array[Dictionary] = [{"draws": 6, "used_items": [], "bursted": false, "score": 50}]
		session.player_hours_history_today = mock_hours
		var mock_doubts: Array[String] = ["cpu_suzuki"]
		session.player_doubts_made_today = mock_doubts
		
		# end_day will simulate AI, register doubts, and advance day index
		session.end_day()
		
	var showdown = session.calculate_final_showdown()
	
	var pass_results = assert_true(
		showdown.has("final_scores") and showdown.has("rankings") and showdown.has("title"),
		"Showdown evaluation successfully computes final scores, rankings, and titles."
	)
	
	var pass_rank = assert_true(showdown["rankings"].size() == 4, "Rankings contains exactly 4 players.")
	
	return pass_results and pass_rank

# Test 5: Title Determination & Cram Mode conditions
func test_title_determination() -> bool:
	print("\n--- Test 5: Title Determination & Cram Mode ---")
	
	var orig_coins = Global.coins
	var orig_play_count = Global.play_count
	var orig_deviation = Global.deviation_value
	var orig_items = Global.unlocked_items.duplicate()
	
	# Reset global states for clean testing environment
	Global.coins = 100
	Global.play_count = 0
	Global.deviation_value = 50.0
	Global.unlocked_items = []
	
	# Cram Mode test
	var title_cram_genius = ScoreEvaluator._determine_title(150, 1, 0, 1, 0, 0, Constants.MODE_CRAM)
	var pass_cram_genius = assert_true(
		title_cram_genius == Constants.TITLE_CRAM_GENIUS,
		"Cram mode: Score 150, Rank 1 -> '%s' (Actual: %s)" % [Constants.TITLE_CRAM_GENIUS, title_cram_genius]
	)
	
	var title_normal_gold = ScoreEvaluator._determine_title(150, 1, 0, 1, 0, 0, Constants.MODE_NATIONAL)
	var pass_normal_gold = assert_true(
		title_normal_gold != Constants.TITLE_CRAM_GENIUS,
		"Normal mode: Score 150, Rank 1 should NOT be '%s' (Actual: %s)" % [Constants.TITLE_CRAM_GENIUS, title_normal_gold]
	)
	
	# Score bounds for Cram vs Normal
	var title_cram_honest = ScoreEvaluator._determine_title(120, 2, 0, 0, 0, 0, Constants.MODE_CRAM)
	var pass_cram_honest = assert_true(
		title_cram_honest == Constants.TITLE_CRAM_HONEST,
		"Cram mode: Score 120, honest -> '%s' (Actual: %s)" % [Constants.TITLE_CRAM_HONEST, title_cram_honest]
	)
	
	var title_normal_honest = ScoreEvaluator._determine_title(120, 2, 0, 0, 0, 0, Constants.MODE_NATIONAL)
	var pass_normal_honest = assert_true(
		title_normal_honest != Constants.TITLE_CRAM_HONEST,
		"Normal mode: Score 120, honest should NOT be '%s' (Actual: %s)" % [Constants.TITLE_CRAM_HONEST, title_normal_honest]
	)
	
	# 偏差値70の境界値テスト
	Global.deviation_value = 70.0
	var title_god_bound = ScoreEvaluator._determine_title(50, 4, 0, 0, 0, 0, Constants.MODE_NATIONAL)
	var pass_god_bound = assert_true(
		title_god_bound == Constants.TITLE_DEV_GOD,
		"Deviation boundary 70.0 -> '%s' (Actual: %s)" % [Constants.TITLE_DEV_GOD, title_god_bound]
	)
	Global.deviation_value = 50.0
	
	# 赤点回避失敗の境界値テスト
	var title_red_fail = ScoreEvaluator._determine_title(50, 3, 1, 0, 0, 0, Constants.MODE_NATIONAL)
	var pass_red_fail = assert_true(
		title_red_fail == Constants.TITLE_RED_FAIL,
		"Score boundary 50 -> '%s' (Actual: %s)" % [Constants.TITLE_RED_FAIL, title_red_fail]
	)
	
	# 暴風警報発令中（バースト3回）の境界値テスト
	var title_storm = ScoreEvaluator._determine_title(100, 2, 3, 0, 0, 0, Constants.MODE_NATIONAL)
	var pass_storm = assert_true(
		title_storm == Constants.TITLE_STORM,
		"Burst boundary 3 -> '%s' (Actual: %s)" % [Constants.TITLE_STORM, title_storm]
	)
	
	# 石橋を叩いて渡る覇者（バースト0、1位）のテスト
	var title_bridge = ScoreEvaluator._determine_title(160, 1, 0, 1, 0, 0, Constants.MODE_NATIONAL)
	var pass_bridge = assert_true(
		title_bridge == Constants.TITLE_SAFE_CHAMP,
		"Burst 0, Rank 1 -> '%s' (Actual: %s)" % [Constants.TITLE_SAFE_CHAMP, title_bridge]
	)
	
	# Priority conflict test:
	# A player with score=180, rank=2, burst=0, lies=0 satisfies both:
	# - Constants.TITLE_CRAM_HONEST ("清廉潔白なガリ勉" - score >= 180, lies == 0)
	# - Constants.TITLE_SAFETY_FIRST ("安全第一" - burst == 0)
	# We verify that TITLE_CRAM_HONEST takes priority (evaluated first in the title rules table).
	var title_conflict = ScoreEvaluator._determine_title(180, 2, 0, 0, 0, 0, Constants.MODE_NATIONAL)
	var pass_conflict = assert_true(
		title_conflict == Constants.TITLE_CRAM_HONEST,
		"Conflict test: Should prioritize '%s' (Cram Honest) over 'Safety First' (Actual: %s)" % [Constants.TITLE_CRAM_HONEST, title_conflict]
	)
	
	# 新規追加称号のテスト
	
	# 1. 文房具財閥 (TITLE_RICH_STUDENT): coins >= 500, my_rank == 1, bursts >= 1 (to bypass TITLE_SAFE_CHAMP)
	Global.coins = 500
	var title_rich = ScoreEvaluator._determine_title(150, 1, 1, 1, 0, 0, Constants.MODE_NATIONAL)
	var pass_rich = assert_true(
		title_rich == Constants.TITLE_RICH_STUDENT,
		"Rich student test: coins >= 500 -> '%s' (Actual: %s)" % [Constants.TITLE_RICH_STUDENT, title_rich]
	)
	Global.coins = 100
	
	# 2. 破産寸前のカモ (TITLE_DEBT_KING): coins <= 10, my_rank == 4
	Global.coins = 5
	var title_debt = ScoreEvaluator._determine_title(80, 4, 1, 1, 0, 1, Constants.MODE_NATIONAL)
	var pass_debt = assert_true(
		title_debt == Constants.TITLE_DEBT_KING,
		"Debt king test: coins <= 10, rank 4 -> '%s' (Actual: %s)" % [Constants.TITLE_DEBT_KING, title_debt]
	)
	Global.coins = 100
	
	# 3. 鉄壁 of ガリ勉 (TITLE_OVERACHIEVER): lies_count == 0, score >= 200, bursts >= 1 (to bypass TITLE_SAFE_CHAMP)
	var title_overachiever = ScoreEvaluator._determine_title(200, 1, 1, 0, 0, 0, Constants.MODE_NATIONAL)
	var pass_overachiever = assert_true(
		title_overachiever == Constants.TITLE_OVERACHIEVER,
		"Overachiever test: lies 0, score 200 -> '%s' (Actual: %s)" % [Constants.TITLE_OVERACHIEVER, title_overachiever]
	)
	
	# 4. 崖っぷちの勇者 (TITLE_CHIKEN_HERO): bursts <= 1, score >= 250, bursts >= 1 (to bypass TITLE_SAFE_CHAMP)
	var title_chicken_hero = ScoreEvaluator._determine_title(250, 1, 1, 2, 0, 0, Constants.MODE_NATIONAL)
	var pass_chicken_hero = assert_true(
		title_chicken_hero == Constants.TITLE_CHIKEN_HERO,
		"Chicken hero test: bursts <= 1, score 250 -> '%s' (Actual: %s)" % [Constants.TITLE_CHIKEN_HERO, title_chicken_hero]
	)
	
	# 5. 速読の鬼 (TITLE_SPEED_RUNNER): play_count >= 50, bursts >= 1
	Global.play_count = 55
	var title_speed = ScoreEvaluator._determine_title(100, 2, 1, 1, 0, 0, Constants.MODE_NATIONAL)
	var pass_speed = assert_true(
		title_speed == Constants.TITLE_SPEED_RUNNER,
		"Speed runner test: play_count >= 50 -> '%s' (Actual: %s)" % [Constants.TITLE_SPEED_RUNNER, title_speed]
	)
	Global.play_count = 0
	
	# 6. 疑惑の追跡者 (TITLE_DOUBT_SPAMMER): doubt_successes >= 4, bursts >= 1
	var title_doubt_spammer = ScoreEvaluator._determine_title(100, 2, 1, 1, 0, 4, Constants.MODE_NATIONAL)
	var pass_doubt_spammer = assert_true(
		title_doubt_spammer == Constants.TITLE_DOUBT_SPAMMER,
		"Doubt spammer test: doubt_successes >= 4 -> '%s' (Actual: %s)" % [Constants.TITLE_DOUBT_SPAMMER, title_doubt_spammer]
	)
	
	# 7. 幸運のセブン (TITLE_LUCKY_SEVEN): score % 10 == 7, my_rank == 1, bursts >= 1 (to bypass TITLE_SAFE_CHAMP)
	var title_lucky = ScoreEvaluator._determine_title(157, 1, 1, 1, 0, 0, Constants.MODE_NATIONAL)
	var pass_lucky = assert_true(
		title_lucky == Constants.TITLE_LUCKY_SEVEN,
		"Lucky seven test: score ends in 7, rank 1 -> '%s' (Actual: %s)" % [Constants.TITLE_LUCKY_SEVEN, title_lucky]
	)
	
	# Restore original global values
	Global.coins = orig_coins
	Global.play_count = orig_play_count
	Global.deviation_value = orig_deviation
	Global.unlocked_items = orig_items
	
	return pass_cram_genius and pass_normal_gold and pass_cram_honest and pass_normal_honest and pass_god_bound and pass_red_fail and pass_storm and pass_bridge and pass_conflict and pass_rich and pass_debt and pass_overachiever and pass_chicken_hero and pass_speed and pass_doubt_spammer and pass_lucky

# Test 6: Game Session State & Transition Integrity
func test_game_session_states() -> bool:
	print("\n--- Test 6: Game Session State Transition ---")
	var session = GameSession.new()
	var mock_deck_config = {
		1: "item_sticky_note",
		2: "item_eraser",
		3: "item_ruler",
		4: "item_wordbook",
		5: "item_mech_pencil",
		6: "item_memo_cards",
		7: "item_highlighter",
		8: "item_blue_pen",
		9: "item_cushion",
		10: "item_memo_app"
	}
	
	var prev_mode = Global.game_mode
	Global.game_mode = Constants.MODE_NATIONAL
	
	session.start_session(mock_deck_config)
	
	var pass_start = assert_true(session.current_day == 1, "Session starts at day 1.")
	var pass_history_exists = assert_true(session.match_history.has(1), "Match history contains day 1 initialization.")
	
	# Progress days 1 to 5
	var pass_transitions = true
	for day in range(1, 6):
		session.simulate_cpus_for_day(day)
		
		session.player_actual_score_today = 30
		session.player_declared_score_today = 35
		session.player_hours_history_today = [{"draws": 6, "used_items": [], "bursted": false, "score": 30}]
		var mock_doubts: Array[String] = ["cpu_suzuki"]
		session.player_doubts_made_today = mock_doubts
		session.current_hour = 3
		session.end_day()
		
		# Verify daily reset of active variables after end_day
		pass_transitions = pass_transitions and assert_true(
			session.player_actual_score_today == 0,
			"Day %d reset: player_actual_score_today is 0." % day
		)
		pass_transitions = pass_transitions and assert_true(
			session.player_declared_score_today == 0,
			"Day %d reset: player_declared_score_today is 0." % day
		)
		pass_transitions = pass_transitions and assert_true(
			session.player_hours_history_today.size() == 0,
			"Day %d reset: player_hours_history_today is empty." % day
		)
		pass_transitions = pass_transitions and assert_true(
			session.player_doubts_made_today.size() == 0,
			"Day %d reset: player_doubts_made_today is empty." % day
		)
		pass_transitions = pass_transitions and assert_true(
			session.current_hour == 1,
			"Day %d reset: current_hour is 1." % day
		)
		
		var expected_next = day + 1
		pass_transitions = pass_transitions and assert_true(
			session.current_day == expected_next,
			"Day %d transitioned to Day %d." % [day, expected_next]
		)
		pass_transitions = pass_transitions and assert_true(
			session.match_history.has(day) and session.match_history[day].has("player"),
			"History recorded for player on day %d." % day
		)
	
	# Execute final showdown
	var showdown = session.calculate_final_showdown()
	var pass_showdown = assert_true(
		showdown.has("final_scores") and showdown.has("rankings") and showdown.has("title"),
		"Final showdown computed successfully after 5 days."
	)
	
	Global.game_mode = prev_mode
	
	return pass_start and pass_history_exists and pass_transitions and pass_showdown

# Test 7: GameSession Cram / Friend / Random scenario mode integration
func test_scenario_modes() -> bool:
	print("\n--- Test 7: Scenario Modes (Cram & Friend/Random) ---")
	var mock_deck_config = {
		1: "item_sticky_note",
		2: "item_eraser",
		3: "item_ruler",
		4: "item_wordbook",
		5: "item_mech_pencil",
		6: "item_memo_cards",
		7: "item_highlighter",
		8: "item_blue_pen",
		9: "item_cushion",
		10: "item_memo_app"
	}
	
	# Save original Global variables to restore after test
	var orig_game_mode = Global.game_mode
	var orig_daily_current_day = Global.daily_current_day
	var orig_daily_my_records = Global.daily_my_records.duplicate(true)
	var orig_friend_current_day = Global.friend_current_day
	var orig_friend_match_history = Global.friend_match_history.duplicate(true)
	
	# --- Part A: Cram (一夜漬け) Mode Simulation ---
	Global.game_mode = Constants.MODE_CRAM
	Global.daily_current_day = 3
	Global.daily_my_records = {
		"1": {"id": "player", "actual_score": 40, "declared_score": 45, "hours": []},
		"2": {"id": "player", "actual_score": 50, "declared_score": 55, "hours": []}
	}
	
	var session_cram = GameSession.new()
	session_cram.start_session(mock_deck_config)
	
	var pass_cram_day = assert_true(session_cram.current_day == 3, "Cram mode starts at Global.daily_current_day (Day 3).")
	var pass_cram_hours = assert_true(session_cram.max_hours_today == 1, "Cram mode restricts max daily hours to 1.")
	
	# Simulate playing Day 3
	session_cram.player_actual_score_today = 30
	session_cram.player_declared_score_today = 32
	session_cram.end_day()
	
	var pass_cram_history = assert_true(
		Global.daily_my_records.has("3") and int(Global.daily_my_records["3"]["actual_score"]) == 30,
		"Cram end_day successfully saved player record for Day 3 into Global."
	)
	var pass_cram_next_day = assert_true(
		Global.daily_current_day == 4 and session_cram.current_day == 4,
		"Cram current day successfully incremented to 4 in both Global and session."
	)
	
	# --- Part B: Friend (フレンド) / Random Mode Simulation ---
	var bm = Engine.get_main_loop().root.get_node_or_null("BackendManager")
	var orig_mock = false
	if bm:
		orig_mock = bm.is_mock_room
		bm.is_mock_room = true
		
	Global.game_mode = Constants.MODE_FRIEND
	Global.friend_current_day = 2
	Global.friend_match_history = {
		1: {"player": {"id": "player", "actual_score": 35, "declared_score": 40, "hours": []}}
	}
	
	var session_friend = GameSession.new()
	session_friend.start_session(mock_deck_config)
	
	var pass_friend_day = assert_true(session_friend.current_day == 2, "Friend mode starts at Global.friend_current_day (Day 2).")
	var pass_friend_history_load = assert_true(
		session_friend.match_history.has(1) and int(session_friend.match_history[1]["player"]["actual_score"]) == 35,
		"Friend mode start_session successfully loaded existing match_history from Global."
	)
	
	# Simulate playing Day 2
	session_friend.player_actual_score_today = 45
	session_friend.player_declared_score_today = 48
	session_friend.end_day()
	
	var pass_friend_history_save = assert_true(
		Global.friend_match_history.has(2) and int(Global.friend_match_history[2]["player"]["actual_score"]) == 45,
		"Friend end_day successfully saved Day 2 match history back to Global."
	)
	
	# Restore original Global variables
	if bm:
		bm.is_mock_room = orig_mock
		
	Global.game_mode = orig_game_mode
	Global.daily_current_day = orig_daily_current_day
	Global.daily_my_records = orig_daily_my_records
	Global.friend_current_day = orig_friend_current_day
	Global.friend_match_history = orig_friend_match_history
	
	return pass_cram_day and pass_cram_hours and pass_cram_history and pass_cram_next_day and pass_friend_day and pass_friend_history_load and pass_friend_history_save

func test_metadata_and_integrity() -> bool:
	print("\n--- Test 8: Metadata & Integration Integrity ---")
	
	# A. Verify BagBuilder generate_choices() only uses unlocked items
	var orig_unlocked = Global.unlocked_items.duplicate()
	Global.unlocked_items = ["item_sticky_note", "item_eraser", "item_ruler"]
	
	var bag_builder = BagBuilderPhase.new()
	bag_builder.card_options.clear()
	bag_builder.generate_choices()
	
	var pass_bag = true
	for card in bag_builder.card_options:
		if not card["id"] in Global.unlocked_items:
			pass_bag = false
			break
	var pass_bag_assert = assert_true(pass_bag, "BagBuilder choice generation strictly respects Global.unlocked_items pool.")
	bag_builder.free()
	Global.unlocked_items = orig_unlocked
	
	# B. Verify deviation change is restricted to MODE_RANDOM in ResultScene
	var result_scene = ResultScene.new()
	result_scene.showdown_data = {
		"final_scores": {"player": 100},
		"rankings": [],
		"level_bonus": 0,
		"coins_earned": 0,
		"perfect_bonus": 0,
		"title": "平均的な学生",
		"details": {}
	}
	
	# Mock deviation calculations for modes
	var prev_mode = Global.game_mode
	var orig_deviation = Global.deviation_value
	
	# Mode CPU (deviation should NOT change)
	Global.game_mode = Constants.MODE_CPU
	Global.deviation_value = 50.0
	result_scene._calculate_deviation()
	var pass_cpu_dev = assert_true(Global.deviation_value == 50.0, "CPU mode does not alter player deviation.")
	
	# Mode RANDOM (deviation SHOULD change)
	Global.game_mode = Constants.MODE_RANDOM
	Global.deviation_value = 50.0
	result_scene._calculate_deviation()
	var pass_random_dev = assert_true(Global.deviation_value != 50.0, "Random match mode successfully updates player deviation.")
	
	# Restore original settings
	Global.game_mode = prev_mode
	Global.deviation_value = orig_deviation
	result_scene.free()
	
	return pass_bag_assert and pass_cpu_dev and pass_random_dev

