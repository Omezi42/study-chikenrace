class_name StudyDeck
extends RefCounted

const CardDataScript = preload("res://scripts/data/CardData.gd")
const GameBalanceScript = preload("res://scripts/core/GameBalance.gd")

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
	
	# 全カードがアイテム：Loadout（1～10枚枠）に設定されたアイテムをその枚数分生成
	for i in range(1, 11):
		var item_type = Global.current_loadout[i]
		for _j in range(i):
			deck.append(CardDataScript.new(item_type, i))
	
	deck.shuffle()

func add_item_card(item_type: int, number: int = -1) -> void:
	# 数字はロードアウト枠が決定（引いたときその数字分だけ得点）
	if number < 1:
		number = GameBalanceScript.loadout_number_for_item(item_type)
	# デッキインフレ対策：同じ数字の既存のカードを1枚削除してから追加
	var _removed = remove_card_by_number(number)
	deck.append(CardDataScript.new(item_type, number))
	deck.shuffle()

func remove_card_by_number(number: int) -> bool:
	# 山札（deck）から指定した数字のカードを1枚探し、削除する（種類は問わない）
	for i in range(deck.size()):
		if deck[i].number == number:
			deck.remove_at(i)
			return true
	# 山札に見つからなければ捨て札（used_cards）も探す
	for i in range(used_cards.size()):
		if used_cards[i].number == number:
			used_cards.remove_at(i)
			return true
	return false

func remove_target_card(target_item_type: int, target_number: int) -> bool:
	# 山札（deck）から指定したカードを1枚探し、削除する
	for i in range(deck.size()):
		if deck[i].number == target_number and deck[i].item_type == target_item_type:
			deck.remove_at(i)
			return true
	# 山札に見つからなければ捨て札（used_cards）も探す
	for i in range(used_cards.size()):
		if used_cards[i].number == target_number and used_cards[i].item_type == target_item_type:
			used_cards.remove_at(i)
			return true
	return false

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

# その日の現在のスコアを計算（全カードがスコア対象）
func calculate_scores() -> Dictionary:
	var total = 0
	var double_next = false
	
	var last_subject = Enums.Subject.NONE
	var current_combo = 0
	var collected_subjects = {}
	
	for c in drawn_cards:
		if not c.is_active:
			continue
		
		# 教科の取得
		var subj = Enums.ITEM_SUBJECT_MAP.get(c.item_type, Enums.Subject.NONE)
		if subj != Enums.Subject.NONE:
			collected_subjects[subj] = true
			if subj == last_subject:
				current_combo += 1
			else:
				current_combo = 1
			last_subject = subj
		else:
			current_combo = 0
			last_subject = Enums.Subject.NONE
		
		# 連続コンボボーナス (同じ教科が連続した場合、2連続目で+10, 3連続目で+20...)
		var combo_bonus = 0
		if current_combo > 1:
			combo_bonus = (current_combo - 1) * GameBalanceScript.COMBO_BONUS_PER_STACK
		
		# 引いたカードの「数字」＋教科コンボのみ加算（即時+15等は廃止）
		var score_to_add = c.number + combo_bonus
		if double_next:
			score_to_add *= 2
			double_next = false
		total += score_to_add
		
		if c.item_type == Enums.ItemType.RED_SHEET:
			double_next = true
			
	# 5教科コンプリートボーナス判定
	var is_five_subjects_complete = false
	if collected_subjects.has(Enums.Subject.JAPANESE) and collected_subjects.has(Enums.Subject.MATH) and collected_subjects.has(Enums.Subject.ENGLISH) and collected_subjects.has(Enums.Subject.SCIENCE) and collected_subjects.has(Enums.Subject.SOCIAL_STUDIES):
		is_five_subjects_complete = true
		total += GameBalanceScript.FIVE_SUBJECTS_BONUS
	
	return { "total": total, "combo": current_combo, "five_subjects": is_five_subjects_complete }


# ストップ時の最終スコア計算（付箋ボーナス等の適用）
func finalize_score() -> int:
	var score_dict = calculate_scores()
	var final_score = score_dict["total"]
	if sticky_note_bonus_active:
		final_score += GameBalanceScript.STOP_BONUS_STICKY_NOTE
	for c in drawn_cards:
		if c.is_active and c.item_type == Enums.ItemType.RULER:
			final_score += GameBalanceScript.STOP_BONUS_RULER
			break
	return final_score
