class_name AIManager
extends RefCounted

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")
const GameBalanceScript = preload("res://scripts/core/GameBalance.gd")

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
		
		# AIのデッキビルド: プレイスタイルに応じたアイテム選択
		var style = state["style"]
		var chosen = _choose_item_for_style(style)
		state["deck"].add_item_card(chosen.type)
		
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
		
		# その日の気分（日次モチベーション/リスク許容度のゆらぎ）
		var mood = randf_range(-0.04, 0.04)
		var current_day = Global.score_history.size() + 1
		var is_trailing = state["total_score"] < Global.total_score
		
		# 負けている後半戦なら、リスク許容度が上昇（desperation）
		var desperation = 0.0
		if is_trailing and current_day >= 3:
			desperation = 0.08
		
		# 簡易的なチキンレースシミュレーション（時間割ごとの区切りを無視して1日分のドローを行う）
		var max_draws = 20
		for i in range(max_draws):
			# リスク評価
			var burst_prob = _calculate_burst_probability(deck)
			var base_threshold = 0.20
			
			if style == "safe":
				base_threshold = 0.10 + randf_range(-0.02, 0.02)
			elif style == "gambler":
				base_threshold = 0.35 + randf_range(-0.06, 0.06)
			elif style == "bluffer":
				base_threshold = 0.25 + randf_range(-0.04, 0.04)
				
			var threshold = base_threshold + mood + desperation
			
			# 精神的プレッシャー（カードを引けば引くほど安全マージンを取りたくなる）
			threshold -= deck.drawn_cards.size() * 0.005
			
			# エナジードリンクがあるなら大幅に強気になる
			if deck.has_energy_drink_shield:
				threshold += 0.15
				
			# しきい値を適切な範囲にクランプ（0.02以下になると何も引かずにやめてしまうのを防ぐ）
			threshold = clamp(threshold, 0.02, 0.85)
			
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
				# 最新のアクティブなカードを無効化（消しゴム自身は除く）
				for j in range(deck.drawn_cards.size() - 1, -1, -1):
					var c = deck.drawn_cards[j]
					if c.item_type != Enums.ItemType.ERASER and c.is_active:
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
		var max_bluff = GameBalanceScript.max_bluff_cap(deck.cheat_sheet_count)
		
		# 心理戦・状況に応じたブラフ確率の補正
		var lie_prob_modifier = 0.0
		var bluff_amt_modifier = 1.0
		
		if is_trailing and current_day >= 3:
			# 負けていて後半戦の場合、焦りからブラフ率がアップし、金額も大きくなる
			lie_prob_modifier = 0.15
			bluff_amt_modifier = 1.25
		
		if style == "safe":
			# ほとんど嘘をつかない（10% + 補正の確率で少し盛る）
			if randf() < (0.10 + lie_prob_modifier):
				bluff_amount = randi_range(5, int(15 * bluff_amt_modifier))
				is_lying = true
		elif style == "gambler":
			# バーストした時は高確率でMAXまで盛る
			if is_burst and randf() < (0.70 + lie_prob_modifier):
				bluff_amount = randi_range(int(max_bluff / 2), int(max_bluff * bluff_amt_modifier))
				is_lying = true
			elif randf() < (0.30 + lie_prob_modifier):
				bluff_amount = randi_range(10, int(30 * bluff_amt_modifier))
				is_lying = true
		elif style == "bluffer":
			# 頻繁に盛る
			if randf() < (0.60 + lie_prob_modifier):
				bluff_amount = randi_range(10, int(max_bluff * bluff_amt_modifier))
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

# プレイスタイルに応じたアイテム選択
# safe: 防御系アイテム（消しゴム、エナジードリンク、付箋）を優先
# gambler: 攻撃系アイテム（分厚い参考書、定規、赤シート）を優先
# bluffer: ブラフ支援アイテム（カンペ、コンパス、シャーペン）を優先
# 全スタイルに20%の確率でランダム選択を混ぜて意外性を出す
func _choose_item_for_style(style: String) -> Dictionary:
	var pick_type: int
	if randf() < 0.20:
		var all_types = [
			Enums.ItemType.ERASER, Enums.ItemType.ENERGY_DRINK, Enums.ItemType.WORD_BOOK,
			Enums.ItemType.RED_SHEET, Enums.ItemType.THICK_BOOK, Enums.ItemType.STICKY_NOTE,
			Enums.ItemType.CHEAT_SHEET, Enums.ItemType.COMPASS, Enums.ItemType.MECHANICAL_PENCIL,
			Enums.ItemType.RULER
		]
		pick_type = all_types[randi() % all_types.size()]
	elif style == "safe":
		var preferred = [
			Enums.ItemType.ERASER, Enums.ItemType.ENERGY_DRINK,
			Enums.ItemType.STICKY_NOTE, Enums.ItemType.WORD_BOOK
		]
		pick_type = preferred[randi() % preferred.size()]
	elif style == "gambler":
		var preferred = [
			Enums.ItemType.THICK_BOOK, Enums.ItemType.RULER,
			Enums.ItemType.RED_SHEET, Enums.ItemType.ENERGY_DRINK
		]
		pick_type = preferred[randi() % preferred.size()]
	elif style == "bluffer":
		var preferred = [
			Enums.ItemType.CHEAT_SHEET, Enums.ItemType.COMPASS,
			Enums.ItemType.MECHANICAL_PENCIL, Enums.ItemType.RED_SHEET
		]
		pick_type = preferred[randi() % preferred.size()]
	else:
		pick_type = Enums.ItemType.ERASER if randf() < 0.5 else Enums.ItemType.RULER
	return {"type": pick_type}

func get_daily_results() -> Dictionary:
	return daily_results

func get_rival_state(name: String) -> Dictionary:
	if rival_states.has(name):
		return rival_states[name]
	return {}
