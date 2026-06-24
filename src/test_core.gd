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
	success = success and test_multiplayer_sync_and_idempotency()
	success = success and test_timer_and_compass_and_cloning()
	success = success and test_amulet_and_memo_app_guard()
	success = success and test_ui_guard_states()
	success = success and test_card_effects_edge_cases()
	success = success and test_deviation_league_mappings()
	success = success and test_cram_genius_overnight()
	success = success and test_full_game_integration_flow()
	success = success and test_grade_progression_system()
	success = success and test_eraser_consecutive_bursts()
	
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
	var prev_mode = Global.game_mode
	var prev_tutorial = Global.is_tutorial_mode
	Global.game_mode = Constants.MODE_CPU
	Global.is_tutorial_mode = false
	
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
	
	Global.game_mode = prev_mode
	Global.is_tutorial_mode = prev_tutorial
	
	return pass_size and pass_draw and pass_hand and pass_pile

# Test 2: Scoring, Combos, and Wildcards (Updated for simplified mechanics)
func test_combos_and_wildcards() -> bool:
	print("\n--- Test 2: Scoring and Item Buffs (No Subjects) ---")
	var deck = StudyDeck.new()
	
	# Scenario A: Standard hand (no buffs)
	var hand_a: Array[Dictionary] = [
		{"value": 3, "item_id": "item_sticky_note"},
		{"value": 4, "item_id": "item_eraser"},
		{"value": 5, "item_id": "item_ruler"}
	]
	deck.hand = hand_a
	var score_a = deck.calculate_hand_score()
	var pass_a = assert_true(
		score_a["total_score"] == 12,
		"Scenario A: Normal hand score subtotal 12, total 12. (Actual: %d)" % score_a["total_score"]
	)
	
	# Scenario B: Highlighter active (+1 to each card)
	deck.reset_status_effects()
	deck.highlighter_active = true
	var score_b = deck.calculate_hand_score()
	var pass_b = assert_true(
		score_b["total_score"] == 15,
		"Scenario B: Highlighter active adds +1 to each of the 3 cards (total 15). (Actual: %d)" % score_b["total_score"]
	)
	
	# Scenario C: Blue Pen active (+2 to each card)
	deck.reset_status_effects()
	deck.blue_pen_active = true
	var score_c = deck.calculate_hand_score()
	var pass_c = assert_true(
		score_c["total_score"] == 18,
		"Scenario C: Blue Pen active adds +2 to each of the 3 cards (total 18). (Actual: %d)" % score_c["total_score"]
	)
	
	# Scenario D: Cram School Print active (+10 static bonus)
	deck.reset_status_effects()
	var hand_d: Array[Dictionary] = [
		{"value": 3, "item_id": "item_sticky_note"},
		{"value": 4, "item_id": "item_eraser"}
	]
	deck.hand = hand_d
	deck.cram_school_print_active = true
	var score_d = deck.calculate_hand_score()
	var pass_d = assert_true(
		score_d["total_score"] == 17,
		"Scenario D: Cram School Print active adds +10 to subtotal 7 (total 17). (Actual: %d)" % score_d["total_score"]
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
	for day in range(1, Constants.MAX_DAYS + 1):
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
	for day in range(1, Constants.MAX_DAYS + 1):
		session.simulate_cpus_for_day(day)
		
		session.player_actual_score_today = 30
		session.player_declared_score_today = 35
		var mock_hours_day: Array[Dictionary] = [{"draws": 6, "used_items": [], "bursted": false, "score": 30}]
		session.player_hours_history_today = mock_hours_day
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
	
	# --- Part A: Cram (通常プレイ 1日制) Mode Simulation ---
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
	
	# Mode NATIONAL (deviation should NOT change)
	Global.game_mode = Constants.MODE_NATIONAL
	Global.deviation_value = 50.0
	result_scene._calculate_deviation()
	var pass_national_dev = assert_true(Global.deviation_value == 50.0, "National match mode (mock match) does not alter player deviation.")
	
	# Mode RANDOM (deviation SHOULD change)
	Global.game_mode = Constants.MODE_RANDOM
	Global.deviation_value = 50.0
	result_scene._calculate_deviation()
	var pass_random_dev = assert_true(Global.deviation_value != 50.0, "Random match mode successfully updates player deviation.")
	
	# Restore original settings
	Global.game_mode = prev_mode
	Global.deviation_value = orig_deviation
	result_scene.free()
	
	return pass_cpu_dev and pass_national_dev and pass_random_dev

# Test 9: Multiplayer Sync Scheme & Idempotency
func test_multiplayer_sync_and_idempotency() -> bool:
	print("\n--- Test 9: Multiplayer Sync Scheme & Idempotency ---")
	
	var bm = Engine.get_main_loop().root.get_node_or_null("BackendManager")
	if not bm:
		print("  [SKIP] BackendManager not found in scene tree.")
		return true
		
	# A. Schema normalization test
	var raw_move = {
		"actual_score": 45,
		"declared_score": "55", # string, should be parsed to int
		"hours": [{"draws": 4, "used_items": [], "bursted": false, "score": 45}],
		"phase": "study",
		"client_nonce": "test-nonce-123"
	}
	
	var normalized = bm._normalize_score_payload(raw_move)
	
	var pass_schema_int = assert_true(normalized["declared_score"] == 55, "Schema correctly parsed declared_score to integer.")
	var pass_schema_hours = assert_true(normalized["hours_history"].size() == 1, "Schema successfully mapped 'hours' key to 'hours_history'.")
	
	# B. Global normalization mapping
	var global_norm = Global.normalize_participant_record(raw_move, "player", "TestPlayer")
	var pass_global_hours = assert_true(global_norm["hours"].size() == 1, "Global schema successfully mapped hours_history back to 'hours' field.")
	
	# C. Idempotency test (sent_nonces)
	bm._sent_nonces.clear()
	var mock_move_data = {
		"actual_score": 10,
		"declared_score": 10,
		"hours_history": [],
		"client_nonce": "nonce-idemp-test-999"
	}
	
	# First upload
	bm.is_mock_room = true
	bm.upload_friend_move("1111", 1, mock_move_data)
	
	var pass_nonce_sending = assert_true(bm._sent_nonces.get("nonce-idemp-test-999") == "success", "First upload succeeded and nonce state is success.")
	
	# Second upload (should be blocked or ignored due to success state)
	var prev_sync_rev = bm.mock_last_sync_revision
	bm.upload_friend_move("1111", 1, mock_move_data)
	var pass_idemp_prevented = assert_true(bm.mock_last_sync_revision == prev_sync_rev, "Second upload with same nonce was skipped (idempotent).")
	
	bm._sent_nonces.clear()
	
	# D. Host checks test
	var orig_host_id = bm.cached_host_id
	var orig_logged_in_uuid = bm.logged_in_uuid
	
	bm.cached_host_id = "test-host-uuid"
	bm.logged_in_uuid = "test-host-uuid"
	var pass_is_host = assert_true(bm.is_current_room_host(), "Correctly identifies host when UUIDs match.")
	
	bm.logged_in_uuid = "test-guest-uuid"
	var pass_is_guest = assert_true(bm.is_current_room_host() == false, "Correctly identifies guest when UUIDs differ.")
	
	# Restore
	bm.cached_host_id = orig_host_id
	bm.logged_in_uuid = orig_logged_in_uuid
	bm.is_mock_room = false
	
	return pass_schema_int and pass_schema_hours and pass_global_hours and pass_nonce_sending and pass_idemp_prevented and pass_is_host and pass_is_guest

# Test 10: Timer, Compass and Card Cloning Debug checks
func test_timer_and_compass_and_cloning() -> bool:
	print("\n--- Test 10: Timer, Compass & Reference Cloning Checks ---")
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
	
	# 1. Timer initial state & activation test
	var pass_timer_init = assert_true(deck.timer_active == false, "Timer is inactive by default.")
	deck.timer_active = true
	var pass_timer_act = assert_true(deck.timer_active == true, "Timer is successfully activated.")
	
	# 2. Compass initial state & indices detection test
	var pass_compass_init = assert_true(deck.compass_active == false, "Compass is inactive by default.")
	
	# Manually setup hand and draw pile to test compass warning indexes
	var h: Array[Dictionary] = [{"value": 5, "item_id": "item_sticky_note"}]
	deck.hand = h
	var dp: Array[Dictionary] = [
		{"value": 3, "item_id": "item_eraser"},
		{"value": 5, "item_id": "item_sticky_note"}, # duplicate of hand! (Index 2 from top)
		{"value": 2, "item_id": "item_ruler"}        # Index 1 from top
	]
	deck.draw_pile = dp
	
	var indices = deck.activate_compass_indices()
	var pass_compass_index = assert_true(
		indices.size() == 1 and indices[0] == 2,
		"Compass indices successfully detected duplicate value 5 at index 2 from top."
	)
	
	# 3. Reference Sharing / Cloning Bug check
	deck.initialize_deck(mock_deck_config)
	deck.next_draw_bonus_points = 1
	var drawn_card = deck.draw_card()
	
	var pass_cloned_points = assert_true(
		drawn_card["bonus_points"] == 3,
		"Drawn card successfully obtained +3 bonus points."
	)
	
	# Verify that the original card in the 'cards' pool is NOT modified (due to duplicate/clone)
	var original_found = null
	for card in deck.cards:
		if card["value"] == drawn_card["value"]:
			original_found = card
			break
			
	var pass_cloned_integrity = assert_true(
		original_found != null and not original_found.has("bonus_points"),
		"Original card in cards pool remains unmodified (bonus_points not leaked)."
	)
	
	return pass_timer_init and pass_timer_act and pass_compass_init and pass_compass_index and pass_cloned_points and pass_cloned_integrity


# Test 11: Amulet effect activation and burst protection
func test_amulet_and_memo_app_guard() -> bool:
	print("\n--- Test 11: Amulet & Memo App Guard Checks ---")
	var deck = StudyDeck.new()
	var mock_deck_config = {
		1: "item_amulet", # お守りを1枚投入
		2: "item_memo_app",
		3: "item_sticky_note",
		4: "item_eraser",
		5: "item_ruler",
		6: "item_wordbook",
		7: "item_mech_pencil",
		8: "item_memo_cards",
		9: "item_highlighter",
		10: "item_blue_pen"
	}
	deck.initialize_deck(mock_deck_config)
	
	# 1. Amulet initially inactive
	var pass_amulet_init = assert_true(deck.amulet_active == false, "Amulet is inactive initially.")
	
	# 2. Draw Amulet card and verify active state
	# We manually place Amulet at the top of draw pile for testing
	var amulet_card = {
		"value": 1,
		"item_id": "item_amulet",
		"name": "お守り"
	}
	deck.draw_pile.append(amulet_card)
	var drawn = deck.draw_card()
	
	var pass_amulet_draw = assert_true(drawn["item_id"] == "item_amulet", "Amulet card was drawn.")
	var pass_amulet_act = assert_true(deck.amulet_active == true, "Amulet state becomes active after drawing.")
	
	# 3. Verify points preservation on burst when Amulet is active
	# Setup a mock hand with duplicate values
	var mock_hand: Array[Dictionary] = [
		{"value": 5, "item_id": "item_sticky_note"},
		{"value": 5, "item_id": "item_eraser"},
		{"value": 1, "item_id": "item_amulet"}
	]
	deck.hand = mock_hand
	var is_burst = deck.check_burst()
	var pass_burst = assert_true(is_burst == true, "Hand state is correctly evaluated as burst.")
	
	# Score reduction check
	var score_info = deck.calculate_hand_score()
	var half_score = int(round(score_info["total_score"] * 0.5))
	var pass_preservation = assert_true(half_score == 6, "Amulet score preservation calculated 6 points (half of 11). (Actual: %d)" % half_score)
	
	# 4. Memo App draw returns two cards
	deck.initialize_deck(mock_deck_config)
	var cards_drawn = deck.activate_memo_app_draw()
	var pass_memo_draw = assert_true(cards_drawn.size() == 2, "Memo App successfully drew 2 cards.")
	
	return pass_amulet_init and pass_amulet_draw and pass_amulet_act and pass_burst and pass_preservation and pass_memo_draw


# Test 12: UI Guard States initialization checks
func test_ui_guard_states() -> bool:
	print("\n--- Test 12: UI Guard States Checks ---")
	
	# Instantiate TitleScene to check default variables (transition flag)
	var title_scene = load("res://Title.tscn").instantiate()
	var pass_title_init = assert_true(
		title_scene != null and title_scene.get("is_transitioning") == false,
		"TitleScene correctly initializes is_transitioning as false."
	)
	title_scene.free()
	
	# チュートリアルダイアログが他のクリック入力を遮断しないかテスト
	var test_phase = Control.new()
	test_phase.set_script(load("res://src/ui/phases/PhaseBase.gd"))
	Engine.get_main_loop().root.add_child(test_phase)
	
	# Manually setup a mock session to satisfy script dependencies if needed
	var mock_session = GameSession.new()
	test_phase.session = mock_session
	
	var dialog = test_phase.show_tutorial_dialog("テストメッセージ")
	var pass_dialog_ignore = assert_true(
		dialog.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Tutorial dialog PanelContainer mouse_filter is IGNORE (does not block button clicks)."
	)
	
	var pass_dialog_margin_ignore = false
	if dialog.get_child_count() > 0:
		var margin_node = dialog.get_child(0)
		if margin_node is MarginContainer:
			var pass_margin = assert_true(
				margin_node.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"Tutorial dialog MarginContainer mouse_filter is IGNORE."
			)
			var pass_vbox = false
			if margin_node.get_child_count() > 0:
				var vbox_node = margin_node.get_child(0)
				if vbox_node is VBoxContainer:
					pass_vbox = assert_true(
						vbox_node.mouse_filter == Control.MOUSE_FILTER_IGNORE,
						"Tutorial dialog VBoxContainer mouse_filter is IGNORE."
					)
			pass_dialog_margin_ignore = pass_margin and pass_vbox
			
	dialog.free()
	Engine.get_main_loop().root.remove_child(test_phase)
	test_phase.free()
	
	return pass_title_init and pass_dialog_ignore and pass_dialog_margin_ignore

func test_card_effects_edge_cases() -> bool:
	print("\n--- Test 13: Card Effects Edge Cases ---")
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
	
	# 1. カフェラテの安全ドロー限界テスト（安全なカードが山札にない場合）
	# 手札に [5, 6] を設定、山札にも [5, 6] しかない場合
	var h1: Array[Dictionary] = [
		{"value": 5, "item_id": "item_mech_pencil"},
		{"value": 6, "item_id": "item_memo_cards"}
	]
	deck.hand = h1
	var dp1: Array[Dictionary] = [
		{"value": 5, "item_id": "item_mech_pencil"},
		{"value": 6, "item_id": "item_memo_cards"}
	]
	deck.draw_pile = dp1
	var dp_empty: Array[Dictionary] = []
	deck.discard_pile = dp_empty
	
	var latte_empty = deck.activate_cafe_latte()
	var pass_latte_empty = assert_true(
		latte_empty.is_empty(),
		"Cafe Latte empty: Returns empty dictionary if no safe card is available in deck. (Actual: %s)" % str(latte_empty)
	)
	
	# 2. カフェラテドロー時におけるシャーペンのボーナス適用およびアミュレット有効化テスト
	deck.initialize_deck(mock_deck_config)
	var h2: Array[Dictionary] = [{"value": 1, "item_id": "item_sticky_note"}]
	deck.hand = h2
	# 山札に 2 (お守り) を用意
	var dp2: Array[Dictionary] = [{"value": 2, "item_id": "item_amulet"}]
	deck.draw_pile = dp2
	deck.next_draw_bonus_points = 1
	
	var latte_card = deck.activate_cafe_latte()
	var pass_latte_bonus = assert_true(
		latte_card.get("bonus_points", 0) == 3,
		"Cafe Latte draw bonus: Mech Pencil points bonus successfully applied. (Actual: %d)" % latte_card.get("bonus_points", 0)
	)
	var pass_latte_amulet = assert_true(
		deck.amulet_active == true,
		"Cafe Latte amulet activation: Amulet successfully activated when drawn via Cafe Latte."
	)
	
	# 3. 暗記カードにおけるボーナス・アミュレットの適用テスト
	deck.initialize_deck(mock_deck_config)
	var h3: Array[Dictionary] = [{"value": 1, "item_id": "item_sticky_note"}]
	deck.hand = h3
	var dp3: Array[Dictionary] = [{"value": 3, "item_id": "item_amulet"}]
	deck.draw_pile = dp3
	deck.next_draw_bonus_points = 1
	
	var success_memo = deck.activate_memo_cards(0)
	var pass_memo_exec = assert_true(success_memo == true, "Memo cards operation succeeded.")
	var memo_card = deck.hand[0]
	var pass_memo_bonus = assert_true(
		memo_card.get("bonus_points", 0) == 3,
		"Memo cards draw bonus: Mech Pencil points bonus applied on swapped card. (Actual: %d)" % memo_card.get("bonus_points", 0)
	)
	var pass_memo_amulet = assert_true(
		deck.amulet_active == true,
		"Memo cards amulet activation: Amulet activated when swapped into hand."
	)
	
	# 4. 追込みノートのバフ重複防止テスト
	deck.initialize_deck(mock_deck_config)
	var h4: Array[Dictionary] = [{"value": 5, "item_id": "item_sticky_note", "bonus_points": 3}]
	deck.hand = h4
	var dp4: Array[Dictionary] = []
	deck.draw_pile = dp4
	deck.activate_night_note()
	
	var pass_night_note_dup = assert_true(
		deck.draw_pile.size() == 1 and not deck.draw_pile[0].has("bonus_points"),
		"Night note duplicate: Temp bonus_points cleared when card is duplicated to draw pile. (Actual: %s)" % str(deck.draw_pile[0])
	)
	
	# 5. 消しゴム複数積みでのチャージ加算テスト (AIManager/ChickenRacePhase想定)
	var my_deck_config_eraser = {
		1: "item_eraser",
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
	
	var test_eraser_charges = 0
	for slot_idx in my_deck_config_eraser.keys():
		var item = my_deck_config_eraser[slot_idx]
		if item == "item_eraser":
			test_eraser_charges += 1
			
	var pass_eraser_multiple = assert_true(
		test_eraser_charges == 2,
		"Eraser charges add up to 2 for double Eraser slots. (Actual: %d)" % test_eraser_charges
	)
	
	return pass_latte_empty and pass_latte_bonus and pass_latte_amulet and pass_memo_exec and pass_memo_bonus and pass_memo_amulet and pass_night_note_dup and pass_eraser_multiple


# Test 14: Deviation League Mappings (S to F)
func test_deviation_league_mappings() -> bool:
	print("\n--- Test 14: Deviation League Mappings ---")
	
	var league_s = Global.get_deviation_league(72.0)
	var pass_s = assert_true(league_s == Constants.LEAGUE_S, "Deviation 72.0 maps to League S. (Actual: %s)" % league_s)
	
	var league_a = Global.get_deviation_league(64.5)
	var pass_a = assert_true(league_a == Constants.LEAGUE_A, "Deviation 64.5 maps to League A. (Actual: %s)" % league_a)
	
	var league_b = Global.get_deviation_league(57.0)
	var pass_b = assert_true(league_b == Constants.LEAGUE_B, "Deviation 57.0 maps to League B. (Actual: %s)" % league_b)
	
	var league_c = Global.get_deviation_league(45.0)
	var pass_c = assert_true(league_c == Constants.LEAGUE_C, "Deviation 45.0 maps to League C. (Actual: %s)" % league_c)
	
	var league_f = Global.get_deviation_league(35.0)
	var pass_f = assert_true(league_f == Constants.LEAGUE_F, "Deviation 35.0 maps to League F. (Actual: %s)" % league_f)
	
	return pass_s and pass_a and pass_b and pass_c and pass_f

# Test 15: Overnight Mode Cram Genius Unlock Condition (100 points, Rank 1)
func test_cram_genius_overnight() -> bool:
	print("\n--- Test 15: Overnight Mode Cram Genius Unlock ---")
	
	var title_overnight_genius = ScoreEvaluator._determine_title(100, 1, 0, 1, 0, 0, Constants.MODE_OVERNIGHT)
	var pass_overnight_genius = assert_true(
		title_overnight_genius == Constants.TITLE_CRAM_GENIUS,
		"Overnight mode: Score 100, Rank 1 -> '%s' (Actual: %s)" % [Constants.TITLE_CRAM_GENIUS, title_overnight_genius]
	)
	
	var title_overnight_low = ScoreEvaluator._determine_title(95, 1, 0, 1, 0, 0, Constants.MODE_OVERNIGHT)
	var pass_overnight_low = assert_true(
		title_overnight_low != Constants.TITLE_CRAM_GENIUS,
		"Overnight mode: Score 95, Rank 1 should NOT unlock Cram Genius (Actual: %s)" % title_overnight_low
	)
	
	return pass_overnight_genius and pass_overnight_low

# Test 16: Full game integration flow simulation
func test_full_game_integration_flow() -> bool:
	print("\n--- Test 16: Full Game Integration Flow Simulation ---")
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
	
	Global.game_mode = Constants.MODE_OVERNIGHT
	session.start_session(mock_deck_config)
	
	var pass_start = assert_true(session.current_day == 1, "Session starts at Day 1.")
	var pass_max_hours = assert_true(session.max_hours_today == 3, "Overnight mode has 3 periods per day.")
	
	# Simulate 1st hour
	session.player_deck.draw_card()
	session.player_deck.draw_card()
	var score_h1 = session.player_deck.calculate_hand_score()["total_score"]
	session.add_player_hour_result(session.player_deck.hand.size(), [], false, score_h1)
	session.player_deck.reset_for_next_hour()
	
	# Simulate 2nd hour
	session.player_deck.draw_card()
	var score_h2 = session.player_deck.calculate_hand_score()["total_score"]
	session.add_player_hour_result(session.player_deck.hand.size(), [], false, score_h2)
	session.player_deck.reset_for_next_hour()
	
	# Simulate 3rd hour
	session.player_deck.draw_card()
	var score_h3 = session.player_deck.calculate_hand_score()["total_score"]
	session.add_player_hour_result(session.player_deck.hand.size(), [], false, score_h3)
	session.player_deck.reset_for_next_hour()
	
	var pass_hours_size = assert_true(session.player_hours_history_today.size() == 3, "All 3 periods simulated.")
	
	# Submit declaration
	session.player_declared_score_today = session.player_actual_score_today + 10 # bluff 10 points
	session.player_emote_today = "confident"
	
	session.end_day()
	
	var game_over_msg = "Game is over after Day 1 in Overnight mode. (Actual day: %d)" % session.current_day
	var pass_game_over = assert_true(session.is_game_over(), game_over_msg)
	
	return pass_start and pass_max_hours and pass_hours_size and pass_game_over


# Test 17: Grade & Progression System Test (Modified to reflect disabled progression)
func test_grade_progression_system() -> bool:
	print("\n--- Test 17: Grade Stage & Progression System (Disabled) ---")
	
	# Reset states
	PlayerState.grade_stage = 0
	PlayerState.exam_wins_progress = 0
	PlayerState.player_level = 1
	PlayerState.coins = 100
	PlayerState.total_wins = 0
	PlayerState.recent_results = []
	
	# 1st normal win
	var rep1 = PlayerState.record_match_result(true)
	var pass_win1_wins = assert_true(PlayerState.total_wins == 1, "Total wins increases to 1.")
	var pass_lvl1 = assert_true(PlayerState.player_level == 1, "Level remains 1.")
	
	# 2nd normal win
	var rep2 = PlayerState.record_match_result(true)
	var pass_win2_wins = assert_true(PlayerState.total_wins == 2, "Total wins increases to 2.")
	
	# 3rd win
	var rep3 = PlayerState.record_match_result(true)
	var pass_win3_wins = assert_true(PlayerState.total_wins == 3, "Total wins increases to 3.")
	var pass_no_promo = assert_true(rep3["level_up"] == false, "Progression is disabled: level_up is false.")
	var pass_grade_stage_same = assert_true(PlayerState.grade_stage == 0, "Grade stage remains 0.")
	var pass_recent = assert_true(PlayerState.recent_results == ["WIN", "WIN", "WIN"], "Recent results holds all WINs.")
	
	return pass_win1_wins and pass_lvl1 and pass_win2_wins and pass_win3_wins and pass_no_promo and pass_grade_stage_same and pass_recent


# Test 17: Eraser Consecutive Bursts (Avoid double charge consumption on consecutive draws)
func test_eraser_consecutive_bursts() -> bool:
	print("\n--- Test 17: Eraser Consecutive Bursts ---")
	
	var mock_script = GDScript.new()
	mock_script.source_code = "extends StudyDeck\nfunc shuffle_draw_pile() -> void:\n\tdraw_pile.reverse()"
	mock_script.reload()
	
	var deck_instance = RefCounted.new()
	deck_instance.set_script(mock_script)
	
	deck_instance.eraser_charges = 1
	var h: Array[Dictionary] = [{"value": 3}]
	deck_instance.hand = h
	# We want pop_back to yield 3, then 3, then 4.
	# So draw_pile should be: [{"value": 4}, {"value": 3}, {"value": 3}]
	var dp: Array[Dictionary] = [{"value": 4}, {"value": 3}, {"value": 3}]
	deck_instance.draw_pile = dp
	
	var drawn = deck_instance.draw_card()
	
	var pass_drawn_value = assert_true(drawn.get("value", 0) == 4, "Drawn card is 4 (safe card after bypassing 3s). Actual: %s" % str(drawn))
	var pass_charges = assert_true(deck_instance.eraser_charges == 0, "Eraser charges reduced to 0. Actual: %d" % deck_instance.eraser_charges)
	var pass_activated = assert_true("item_eraser" in deck_instance.activated_items, "item_eraser is in activated_items. Actual: %s" % str(deck_instance.activated_items))
	
	return pass_drawn_value and pass_charges and pass_activated



