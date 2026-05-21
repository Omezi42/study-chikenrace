class_name StudyDeck
extends RefCounted

const CardDataScript = preload("res://scripts/data/CardData.gd")

var deck: Array = []
var drawn_cards: Array = []
var used_cards: Array = [] # 捨て札。日をまたぐ際に山札に戻る。

# アイテムによる状態バフ
var has_energy_drink_shield: bool = false
var next_card_double_score: bool = false
var sticky_note_bonus_active: bool = false
var cheat_sheet_count: int = 0

func reset_for_next_day() -> void:
	# 新しい日（準備フェーズ直前）に呼ばれ、手札・捨て札すべてを山札に戻してシャッフルする
	deck.append_array(drawn_cards)
	deck.append_array(used_cards)
	drawn_cards.clear()
	used_cards.clear()
	
	# バフ状態のリセット
	has_energy_drink_shield = false
	next_card_double_score = false
	sticky_note_bonus_active = false
	cheat_sheet_count = 0
	
	for c in deck:
		c.is_active = true # 無効化状態をリセット
	
	deck.shuffle()

func build_initial_deck() -> void:
	deck.clear()
	drawn_cards.clear()
	used_cards.clear()
	CardDataScript.next_id = 0
	
	has_energy_drink_shield = false
	next_card_double_score = false
	sticky_note_bonus_active = false
	cheat_sheet_count = 0
	
	# 通常カード: 1〜10まで、その数字と同じ枚数だけ
	for i in range(1, 11):
		for _j in range(i):
			deck.append(CardDataScript.new(Enums.ItemType.NORMAL, i))
			
	deck.shuffle()

func add_item_card(item_type: int, number: int) -> void:
	deck.append(CardDataScript.new(item_type, number))
	deck.shuffle()

# ドロー処理の戻り値は、引いたカードの情報やバースト状態を返す
func draw() -> Dictionary:
	if deck.is_empty():
		if not used_cards.is_empty():
			# 捨て札を山札に戻してリシャッフル
			deck = used_cards.duplicate()
			used_cards.clear()
			for c in deck:
				c.is_active = true
			deck.shuffle()
		else:
			return { "card": null, "burst": false, "prevented": false }
			
	var card = deck.pop_back()
	
	# バースト判定
	var is_burst = _check_burst(card)
	var prevented = false
	
	if is_burst:
		if has_energy_drink_shield:
			has_energy_drink_shield = false
			is_burst = false
			prevented = true
			drawn_cards.append(card)
		else:
			# 本当のバースト時は引いたカード自体は場に出す（バースト原因として表示）
			drawn_cards.append(card)
	else:
		drawn_cards.append(card)
	
	return { "card": card, "burst": is_burst, "prevented": prevented }

func _check_burst(card) -> bool:
	# アイテム、通常カード問わず number が一致すればバースト
	for c in drawn_cards:
		if c.is_active and c.number == card.number:
			return true
	return false

# その日の現在のスコアを計算
func calculate_scores() -> Dictionary:
	var total = 0
	var double_next = false
	
	for c in drawn_cards:
		if not c.is_active:
			continue
			
		if c.item_type == Enums.ItemType.NORMAL:
			var score_to_add = c.number
			if double_next:
				score_to_add *= 2
				double_next = false
			total += score_to_add
		elif c.item_type == Enums.ItemType.RED_SHEET:
			double_next = true
			
	return { "total": total }

# ストップ時の最終スコア計算（付箋ボーナス等の適用）
func finalize_score() -> int:
	var score_dict = calculate_scores()
	var final_score = score_dict["total"]
	if sticky_note_bonus_active:
		final_score += 30
	return final_score
