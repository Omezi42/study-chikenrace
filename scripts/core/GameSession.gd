class_name GameSession
extends Node

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")

var deck
var current_score: int = 0
var subject_scores: Dictionary = {}
var ruler_bonuses: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}

func _init():
	deck = StudyDeckScript.new()
	for s in range(5): subject_scores[s] = 0

func setup_session(weights: Dictionary):
	# ノイズシステム廃止につき、ノイズ数は常に0でデッキを構築
	deck.build_deck(weights, 0)

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
	for s in range(5):
		subject_scores[s] = calc["subjects"][s] + ruler_bonuses[s]
		# 定規分のスコアを全体スコアにも加算
		current_score += ruler_bonuses[s]

func stop_and_report() -> Dictionary:
	sync_scores()
	return subject_scores

