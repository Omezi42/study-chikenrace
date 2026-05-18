class_name GameSession
extends Node

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")

var deck
var current_score: int = 0
var subject_scores: Dictionary = {}

func _init():
	deck = StudyDeckScript.new()
	for s in range(5): subject_scores[s] = 0

func setup_session(weights: Dictionary):
	# ノイズシステム廃止につき、ノイズ数は常に0でデッキを構築
	deck.build_deck(weights, 0)

func draw_card() -> Dictionary:
	var result = deck.draw()
	if not result["burst"] and result["card"]:
		var card = result["card"]
		if card.item_type == 0: # SUBJECT
			subject_scores[card.subject] += card.weight
			current_score = deck.calculate_scores()["total"]
	return result

func stop_and_report() -> Dictionary:
	var final = deck.calculate_scores()
	return final["subjects"]

