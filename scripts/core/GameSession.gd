class_name GameSession
extends Node

const StudyDeckScript = preload("res://scripts/core/StudyDeck.gd")

var deck
var current_score: int = 0
var accumulated_score: int = 0

# 役・コンボ状態
var current_combo: int = 0
var is_five_subjects_complete: bool = false

# ダウトなどの隠匿された得点を管理する変数
var hidden_bonus_score: int = 0
var current_hour: int = 1


var ai_manager: RefCounted

func _init():
	deck = StudyDeckScript.new()
	ai_manager = load("res://scripts/core/AIManager.gd").new()
	accumulated_score = 0
	hidden_bonus_score = 0
	current_hour = 1

func setup_session():
	deck.build_initial_deck()
	current_score = 0
	accumulated_score = 0
	hidden_bonus_score = 0

func start_new_day():
	# 日の初めに山札・手札・捨て札をすべてシャッフルし直す
	deck.reset_for_next_day()
	current_hour = 1
	ai_manager.start_new_day()
	ai_manager.simulate_daily_action()

func draw_card() -> Dictionary:
	var result = deck.draw()
	if result["card"] != null:
		Global.increment_item_usage(result["card"].item_type)
	sync_scores()
	return result

func apply_item_effect(item_type: int) -> void:
	if item_type == Enums.ItemType.ERASER:
		# 最新のアクティブなカードを1枚無効化する（消しゴム自身は除く）
		for i in range(deck.drawn_cards.size() - 1, -1, -1):
			var c = deck.drawn_cards[i]
			if c.item_type != Enums.ItemType.ERASER and c.is_active:
				c.is_active = false
				break
	elif item_type == Enums.ItemType.ENERGY_DRINK:
		deck.has_energy_drink_shield = true
	elif item_type == Enums.ItemType.WORD_BOOK:
		# 山札の上3枚を見て、バースト原因となるカードがあれば一番下へ送る簡易実装
		_apply_word_book_effect()
	elif item_type == Enums.ItemType.THICK_BOOK:
		# 強制2枚ドローはフェーズ側で呼び出すためここではフラグ等の処理は不要
		pass
	elif item_type == Enums.ItemType.STICKY_NOTE:
		deck.sticky_note_bonus_active = true
	elif item_type == Enums.ItemType.CHEAT_SHEET:
		deck.cheat_sheet_count += 1
		
	sync_scores()

func _apply_word_book_effect() -> void:
	var look_count = min(3, deck.deck.size())
	if look_count <= 0: return
	
	var cards_to_check = []
	for i in range(look_count):
		cards_to_check.append(deck.deck.pop_back())
	
	var safe_cards = []
	var danger_cards = []
	
	for c in cards_to_check:
		var will_burst = false
		for drawn in deck.drawn_cards:
			if drawn.is_active and drawn.number == c.number:
				will_burst = true
				break
		if will_burst:
			danger_cards.append(c)
		else:
			safe_cards.append(c)
			
	# 安全なカードを上（末尾）に戻し、危険なカードを下（先頭）に送る
	for dc in danger_cards:
		deck.deck.push_front(dc)
	for sc in safe_cards:
		deck.deck.push_back(sc)

func sync_scores() -> void:
	var calc = deck.calculate_scores()
	current_score = calc["total"]
	current_combo = calc["combo"]
	is_five_subjects_complete = calc["five_subjects"]

func stop_period() -> void:
	# その時間目の獲得点数を本日の累計に加算（付箋ボーナスなどもここで）
	var final_period_score = deck.finalize_score()
	accumulated_score += final_period_score
	current_score = 0
	
	# 次の時間目のためにリセット（手札を捨て札へ）
	deck.used_cards.append_array(deck.drawn_cards)
	deck.drawn_cards.clear()
	deck.has_energy_drink_shield = false
	deck.next_card_double_score = false
	deck.sticky_note_bonus_active = false
	# cheat_sheet_count は日の終わりまで持ち越すためリセットしない
	
	sync_scores()

func burst_period() -> void:
	# その時間目の獲得点数は0として、次の時間目のためにリセット
	current_score = 0
	deck.used_cards.append_array(deck.drawn_cards)
	deck.drawn_cards.clear()
	deck.has_energy_drink_shield = false
	deck.next_card_double_score = false
	deck.sticky_note_bonus_active = false
	
	sync_scores()

func stop_and_report() -> int:
	# 総合倍率などは廃止、純粋な累積スコアを返す
	return accumulated_score
