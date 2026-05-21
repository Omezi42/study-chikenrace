class_name AIManager
extends RefCounted

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")

var rivals = [
	{"name": "慎重な優等生", "style": "safe"},
	{"name": "ギャンブラー", "style": "gambler"},
	{"name": "ブラフの達人", "style": "bluffer"}
]

# 各ライバルの状態と履歴を保持
var rival_states = {}
# その日のライバルごとの結果
var daily_results = {}

func _init():
	_init_rival_states()

func _init_rival_states():
	rival_states.clear()
	for r in rivals:
		rival_states[r.name] = {
			"deck": StudyDeckScript.new(),
			"score_history": [],
			"total_score": 0,
			"style": r.style
		}
		rival_states[r.name]["deck"].build_initial_deck()

func start_new_day():
	daily_results.clear()
	for r_name in rival_states:
		var state = rival_states[r_name]
		state["deck"].reset_for_next_day()
		
		# AIのデッキビルド (ランダムにアイテムを1つ追加)
		# 実際はプレイスタイルに合わせて選ぶとより良いが、ここでは簡易的にランダム
		var items = [
			{ "type": Enums.ItemType.ERASER, "number": 2 },
			{ "type": Enums.ItemType.ENERGY_DRINK, "number": 7 },
			{ "type": Enums.ItemType.WORD_BOOK, "number": 4 },
			{ "type": Enums.ItemType.RED_SHEET, "number": 8 },
			{ "type": Enums.ItemType.THICK_BOOK, "number": 10 },
			{ "type": Enums.ItemType.STICKY_NOTE, "number": 1 },
			{ "type": Enums.ItemType.CHEAT_SHEET, "number": 5 }
		]
		var chosen = items[randi() % items.size()]
		state["deck"].add_item_card(chosen.type, chosen.number)
		
		daily_results[r_name] = {
			"actual_score": 0,
			"reported_score": 0,
			"is_lying": false,
			"is_burst": false,
			"status": "playing" # playing, stopped, burst
		}

# 指定された時間のシミュレーションを一気に実行（時間割ごとではなく、1日分をまとめて回す簡易実装とする）
# UI側での表現の都合上、1手ずつ進めるのではなく、1日の終わりに結果を出力する想定。
# ただし、演出のために1手ずつ進められるように generator 的な関数にするか、
# あるいは一括で計算して結果だけ保持するか。今回は一括計算し、UI側には結果のみを提示する形にする。
func simulate_daily_action() -> void:
	for r_name in rival_states:
		var state = rival_states[r_name]
		var deck = state["deck"]
		var style = state["style"]
		var res = daily_results[r_name]
		
		var current_score = 0
		var is_burst = false
		
		# 簡易的なチキンレースシミュレーション（時間割ごとの区切りを無視して1日分のドローを行う）
		var max_draws = 20
		for i in range(max_draws):
			# リスク評価
			var burst_prob = _calculate_burst_probability(deck)
			var threshold = 0.20
			
			if style == "safe":
				threshold = 0.10
			elif style == "gambler":
				threshold = 0.35
			elif style == "bluffer":
				threshold = 0.25
				
			if burst_prob > threshold:
				# ストップ
				break
				
			# ドロー実行
			var draw_res = deck.draw()
			var card = draw_res["card"]
			
			if card == null:
				break # 山札切れ
				
			if draw_res["burst"]:
				is_burst = true
				break
				
			# アイテム効果の適用（CPUは自動で効果を発動）
			if card.item_type == Enums.ItemType.ERASER:
				# 最新の通常カード無効化
				for j in range(deck.drawn_cards.size() - 1, -1, -1):
					var c = deck.drawn_cards[j]
					if c.item_type == Enums.ItemType.NORMAL and c.is_active:
						c.is_active = false
						break
			elif card.item_type == Enums.ItemType.ENERGY_DRINK:
				deck.has_energy_drink_shield = true
			elif card.item_type == Enums.ItemType.STICKY_NOTE:
				deck.sticky_note_bonus_active = true
			elif card.item_type == Enums.ItemType.CHEAT_SHEET:
				deck.cheat_sheet_count += 1
			# WORD_BOOK, THICK_BOOK, RED_SHEETはdeckのcalculate_scores等で処理される前提、
			# あるいはAIでは簡略化のため処理を省く
				
		var final_score = 0
		if not is_burst:
			final_score = deck.finalize_score()
		
		res["actual_score"] = final_score
		res["is_burst"] = is_burst
		res["status"] = "burst" if is_burst else "stopped"
		
		# ブラフの決定
		var reported = final_score
		var is_lying = false
		var bluff_amount = 0
		var max_bluff = 50 + (deck.cheat_sheet_count * 50)
		
		if style == "safe":
			# ほとんど嘘をつかない（10%の確率で少し盛る）
			if randf() < 0.10:
				bluff_amount = randi_range(5, 15)
				is_lying = true
		elif style == "gambler":
			# バーストした時は高確率でMAXまで盛る
			if is_burst and randf() < 0.70:
				bluff_amount = randi_range(max_bluff / 2, max_bluff)
				is_lying = true
			elif randf() < 0.30:
				bluff_amount = randi_range(10, 30)
				is_lying = true
		elif style == "bluffer":
			# 頻繁に盛る
			if randf() < 0.60:
				bluff_amount = randi_range(10, max_bluff)
				is_lying = true
				
		bluff_amount = min(bluff_amount, max_bluff)
		res["reported_score"] = final_score + bluff_amount
		res["is_lying"] = is_lying
		
		state["total_score"] += res["actual_score"]
		state["score_history"].append(res.duplicate())
		
		# 捨て札に移動
		deck.used_cards.append_array(deck.drawn_cards)
		deck.drawn_cards.clear()

func _calculate_burst_probability(deck: RefCounted) -> float:
	var deck_cards = deck.deck
	var drawn_cards = deck.drawn_cards
	var total_deck = deck_cards.size()
	if total_deck == 0:
		return 0.0
		
	var conflict_count = 0
	for c in deck_cards:
		for dc in drawn_cards:
			if dc.is_active and dc.number == c.number:
				conflict_count += 1
				break
				
	return float(conflict_count) / float(total_deck)

func get_daily_results() -> Dictionary:
	return daily_results

func get_rival_state(name: String) -> Dictionary:
	if rival_states.has(name):
		return rival_states[name]
	return {}
