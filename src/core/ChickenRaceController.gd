class_name ChickenRaceController
extends RefCounted

signal card_drawn(card: Dictionary)
signal card_draw_failed(reason: String)
signal burst_triggered(score: int)
signal stop_triggered(score: int)
signal next_hour_started(hour: int)
signal phase_completed(score: int)

var session: GameSession
var engine: ChickenRaceEngine

func _init(p_session: GameSession, p_engine: ChickenRaceEngine) -> void:
	session = p_session
	engine = p_engine

func request_draw() -> void:
	var card = engine.draw_card()
	if card.is_empty():
		emit_signal("card_draw_failed", "山札が空になりました！休憩（ストップ）しましょう。")
		return
	emit_signal("card_drawn", card)

func request_stop(draw_times: Array = []) -> void:
	var final_score = engine.calculate_hand_score()
	var total_used = []
	total_used.append_array(engine.active_used_items)
	total_used.append_array(session.player_deck.activated_items)
	session.add_player_hour_result(session.player_deck.hand.size(), total_used, false, final_score)
	emit_signal("stop_triggered", final_score)

func evaluate_burst(draw_times: Array = []) -> void:
	if engine.check_burst():
		var final_score = engine.calculate_hand_score()
		var total_used = []
		total_used.append_array(engine.active_used_items)
		total_used.append_array(session.player_deck.activated_items)
		session.add_player_hour_result(session.player_deck.hand.size(), total_used, true, final_score)
		emit_signal("burst_triggered", final_score)

func advance_hour() -> void:
	session.player_deck.reset_for_next_hour()
	
	if session.player_hours_history_today.size() >= session.max_hours_today:
		emit_signal("phase_completed", session.player_actual_score_today)
	else:
		session.current_hour += 1
		engine.reset_for_hour()
		emit_signal("next_hour_started", session.current_hour)
