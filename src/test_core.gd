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
	
	return pass_a and pass_b and pass_c

# Test 3: AI Simulation functions
func test_ai_simulation() -> bool:
	print("\n--- Test 3: AI Day Simulation & Bluff Decision ---")
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
	Global.game_mode = "cpu"
	Global.validate_opponent_profiles()
	
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
