class_name GameSession
extends Node

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")

var deck
var current_score: int = 0
var subject_scores: Dictionary = {}
var accumulated_subject_scores: Dictionary = {}
var ruler_bonuses: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}

func _init():
	deck = StudyDeckScript.new()
	for s in range(5):
		subject_scores[s] = 0
		accumulated_subject_scores[s] = 0

func setup_session(weights: Dictionary):
	# ノイズシステム廃止につき、ノイズ数は常に0でデッキを構築
	deck.build_deck(weights, 0)
	for s in range(5):
		subject_scores[s] = 0
		accumulated_subject_scores[s] = 0

func draw_card() -> Dictionary:
	var result = deck.draw()
	sync_scores()
	return result

func apply_ruler_bonus(subject: int) -> void:
	ruler_bonuses[subject] += 5
	sync_scores()

func sync_scores() -> void:
	var calc = deck.calculate_scores()
	current_score = calc["total"]
	var bonus_sum = 0
	for s in range(5):
		subject_scores[s] = calc["subjects"][s] + ruler_bonuses[s]
		bonus_sum += ruler_bonuses[s]
	# 定規分のスコアを全体スコアにも加算
	current_score += bonus_sum

func stop_period() -> void:
	# その時間目の獲得点数を本日の累計に加算
	sync_scores()
	for s in range(5):
		accumulated_subject_scores[s] += subject_scores[s]
	
	# 次の時間目のためにリセット
	deck.reset_for_next_hour()
	for s in range(5):
		ruler_bonuses[s] = 0
	sync_scores()

func burst_period() -> void:
	# その時間目の獲得点数は0として、次の時間目のためにリセット
	deck.reset_for_next_hour()
	for s in range(5):
		ruler_bonuses[s] = 0
	sync_scores()

func stop_and_report() -> Dictionary:
	# 最終的な1日の累計スコアを報告
	return accumulated_subject_scores

