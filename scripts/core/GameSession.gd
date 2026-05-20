class_name GameSession
extends Node

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")

var deck
var current_score: int = 0
var subject_scores: Dictionary = {}
var accumulated_subject_scores: Dictionary = {}
var ruler_bonuses: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
var has_five_subj_comp_today: bool = false

func _init():
	deck = StudyDeckScript.new()
	for s in range(5):
		subject_scores[s] = 0
		accumulated_subject_scores[s] = 0

func setup_session(weights: Dictionary):
	# ノイズシステム廃止につき、ノイズ数は常に0でデッキを構築
	deck.build_deck(weights, 0)
	has_five_subj_comp_today = false
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
	
	# 5教科コンプリートチェック
	var subjs = {}
	for c in deck.drawn_cards:
		if c.item_type == 0: # 教科カードのみ対象
			subjs[c.subject] = true
	if subjs.size() == 5:
		has_five_subj_comp_today = true
	
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
	# 総合倍率 = 日付倍率（1.0 + 0.1 * play_count）+ 5教科コンプ倍率（five_subj_bonus_multiplier - 1.0）
	var day_mult = 1.0 + 0.1 * Global.play_count
	var comp_mult = Global.five_subj_bonus_multiplier - 1.0
	var total_mult = day_mult + comp_mult
	
	# 各教科の獲得得点を倍率補正（切り捨て）して報告用データを作成
	var final_scores = {}
	for s in range(5):
		var raw_score = accumulated_subject_scores[s]
		final_scores[s] = int(floor(float(raw_score) * total_mult))
	return final_scores

