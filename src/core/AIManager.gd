class_name AIManager
extends RefCounted

# AI Personality Constants
const TYPE_CAUTIOUS = "cautious"      # 慎重
const TYPE_AGGRESSIVE = "aggressive"  # テンポ押し
const TYPE_BLUFFER = "bluffer"        # ブラフ寄り
const TYPE_HIGHROLLER = "highroller"  # ハイロール

# Define our 3 fixed CPU opponents
const CPU_OPPONENTS = {
	"cpu_sato": {
		"name": "佐藤くん",
		"type": TYPE_CAUTIOUS,
		"avatar": "res://assets/split/subject_math.png", # Fallback avatar
		"bio": "数学が得意な真面目男子。嘘を嫌い、石橋を叩いて渡るプレイスタイル。",
		"bluff_tendency": "誠実",
		# Deck slotted items (mostly prep/defense)
		"deck": {
			1: "item_eraser",
			2: "item_ruler",
			3: "item_wordbook",
			4: "item_cushion",
			5: "item_memo_cards",
			6: "item_memo_app",
			7: "item_earplugs",
			8: "item_sticky_note",
			9: "item_blue_pen",
			10: "item_highlighter"
		}
	},
	"cpu_suzuki": {
		"name": "鈴木さん",
		"type": TYPE_BLUFFER,
		"avatar": "res://assets/split/subject_english.png",
		"bio": "いつもスマホをいじっているギャル。涼しい顔で大嘘をかましてくる。",
		"bluff_tendency": "変幻自在",
		# Deck slotted items (mostly bluff/prep)
		"deck": {
			1: "item_cheat_sheet",
			2: "item_copy_answer",
			3: "item_sticky_note",
			4: "item_eraser",
			5: "item_ruler",
			6: "item_timer",
			7: "item_study_chat",
			8: "item_memo_app",
			9: "item_highlighter",
			10: "item_wordbook"
		}
	},
	"cpu_takahashi": {
		"name": "高橋くん",
		"type": TYPE_HIGHROLLER,
		"avatar": "res://assets/split/subject_science.png",
		"bio": "エナドリ中毒の熱血野球部員。バースト上等で限界突破を狙う。",
		"bluff_tendency": "中〜高",
		# Deck slotted items (mostly push/prep)
		"deck": {
			1: "item_energy_drink",
			2: "item_red_sheet",
			3: "item_thick_book",
			4: "item_night_note",
			5: "item_mech_pencil",
			6: "item_highlighter",
			7: "item_eraser",
			8: "item_ruler",
			9: "item_sticky_note",
			10: "item_cram_school_print"
		}
	},
	"cpu_tanaka": {
		"name": "田中くん",
		"type": TYPE_AGGRESSIVE,
		"avatar": "res://assets/split/subject_science.png",
		"bio": "野球部所属の熱血漢。直感で引き続ける傾向があるが、ブラフは下手。",
		"bluff_tendency": "低〜中",
		"deck": {
			1: "item_energy_drink",
			2: "item_mech_pencil",
			3: "item_highlighter",
			4: "item_eraser",
			5: "item_thick_book",
			6: "item_night_note",
			7: "item_cushion",
			8: "item_ruler",
			9: "item_blue_pen",
			10: "item_sticky_note"
		}
	},
	"cpu_watanabe": {
		"name": "渡辺さん",
		"type": TYPE_CAUTIOUS,
		"avatar": "res://assets/split/subject_japanese.png",
		"bio": "図書委員の真面目な女子。リスクを徹底的に避け、ほぼ正直に申告する。",
		"bluff_tendency": "極めて誠実",
		"deck": {
			1: "item_eraser",
			2: "item_ruler",
			3: "item_wordbook",
			4: "item_cushion",
			5: "item_memo_cards",
			6: "item_memo_app",
			7: "item_earplugs",
			8: "item_amulet",
			9: "item_timer",
			10: "item_cram_school_print"
		}
	},
	"cpu_ito": {
		"name": "伊藤くん",
		"type": TYPE_BLUFFER,
		"avatar": "res://assets/split/subject_english.png",
		"bio": "お調子者のゲーマー男子。手札がボロボロでも、平気で大嘘を申告する。",
		"bluff_tendency": "大嘘つき",
		"deck": {
			1: "item_cheat_sheet",
			2: "item_copy_answer",
			3: "item_study_chat",
			4: "item_eraser",
			5: "item_ruler",
			6: "item_timer",
			7: "item_memo_app",
			8: "item_wordbook",
			9: "item_highlighter",
			10: "item_blue_pen"
		}
	}
}

# Safely retrieve CPU info with fallback for unknown IDs (e.g. ghost data "cpu_0")
static func _get_cpu_info(actual_id: String) -> Dictionary:
	if CPU_OPPONENTS.has(actual_id):
		return CPU_OPPONENTS[actual_id]
	# Fallback: determine personality type from ID hash
	var types = [TYPE_CAUTIOUS, TYPE_AGGRESSIVE, TYPE_BLUFFER, TYPE_HIGHROLLER]
	var h = abs(actual_id.hash())
	var type_idx = h % types.size()
	var fallback_keys = CPU_OPPONENTS.keys()
	var deck_idx = h % fallback_keys.size()
	var base = CPU_OPPONENTS[fallback_keys[deck_idx]]
	return {
		"name": actual_id,
		"type": types[type_idx],
		"avatar": base.get("avatar", ""),
		"bio": "",
		"bluff_tendency": "不明",
		"deck": base["deck"].duplicate()
	}

# Simulate the Chicken Race for one CPU opponent for the entire day (3 periods)
# Returns a dictionary of day results:
# {
#   "actual_score": int,
#   "hours": [
#      {"draws": int, "used_items": Array, "bursted": bool, "score": int},
#      ...
#   ]
# }
static func simulate_cpu_day(cpu_id: String, day_idx: int) -> Dictionary:
	var actual_id = cpu_id
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("id"):
		actual_id = Global.opponent_profiles[cpu_id]["id"]
	var cpu_info = _get_cpu_info(actual_id)
	var cpu_type = cpu_info["type"]
	var deck_config = cpu_info["deck"]
	
	# Instantiate CPU's simulated deck
	var deck = StudyDeck.new()
	deck.initialize_deck(deck_config)
	
	# CPU deck inflation simulation (No longer adding cards due to BagBuilder removal)
	deck.shuffle_draw_pile()
	
	# Risk tolerances for drawing (stop drawing if burst probability is higher than this)
	var risk_tolerance = 0.25
	match cpu_type:
		TYPE_CAUTIOUS: risk_tolerance = 0.15
		TYPE_AGGRESSIVE: risk_tolerance = 0.38
		TYPE_BLUFFER: risk_tolerance = 0.24
		TYPE_HIGHROLLER: risk_tolerance = 0.48
		
	var deviation = 50.0
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("deviation"):
		deviation = Global.opponent_profiles[cpu_id]["deviation"]
	var dev_factor = clamp(deviation / 50.0, 0.7, 1.3)
	
	# Apply ±15% fluctuation to risk tolerance, adjusted by deviation
	risk_tolerance *= randf_range(0.85, 1.15) * dev_factor
	
	# 状況評価: 後半戦で負けているか、勝っているか
	var is_losing = day_idx >= 3 and deviation < 48.0
	var is_winning = day_idx >= 3 and deviation >= 53.0
	if is_losing:
		risk_tolerance *= 1.25
	elif is_winning:
		risk_tolerance *= 0.85
		
	var hours_result: Array[Dictionary] = []
	var total_actual_score = 0
	
	# 3 periods/hours per day
	var total_periods = 3
	# Check if CPU uses Night Note (徹夜ノート) which gives a 4th period
	var has_night_note = false
	for slot_idx in deck_config.keys():
		if deck_config[slot_idx] == "item_night_note":
			has_night_note = true
			break
			
	if has_night_note and randf() < 0.3: # 30% chance CPU pulls an all-nighter
		total_periods = 4
		
	for h in range(total_periods):
		deck.reset_status_effects()
		
		# AI Decides to activate items before starting draw
		var used_items: Array[String] = []
		decide_and_apply_cpu_items(deck, deck_config, used_items, day_idx, cpu_id)
		
		var draw_count = 0
		var bursted = false
		
		# Chicken race loop
		while true:
			var burst_prob = deck.get_burst_probability()
			
			# カフェラテの動的割り込み発動
			if "item_cafe_latte" in deck_config.values() and not "item_cafe_latte" in used_items:
				if burst_prob >= 0.4 and randf() < 0.75:
					used_items.append("item_cafe_latte")
					var card = deck.activate_cafe_latte()
					if not card.is_empty():
						draw_count += 1
						continue
			
			# Decide to draw or stop
			# Always draw the first 2 cards safely (burst probability is usually 0 initially)
			# Absolute safety guard: If burst probability is extremely high (>= 75%) and CPU has no active protection (eraser/red sheet), stop drawing.
			var has_protection = deck.eraser_charges > 0 or deck.red_sheet_active
			if draw_count >= 2:
				if burst_prob >= 0.75 and not has_protection:
					break # Stop drawing to prevent near-certain suicide
				if burst_prob >= risk_tolerance:
					break # Stop drawing based on personality risk tolerance
				
			# Check energy drink side effect (25% burst on draw)
			if deck.energy_drink_active and draw_count > 0 and randf() < 0.25:
				bursted = true
				break
				
			var card = deck.draw_card()
			if card.is_empty():
				break # Deck empty
				
			draw_count += 1
			
			# Check for burst
			if deck.check_burst():
				bursted = true
				break
				
		var period_score = 0
		if bursted:
			# Apply Amulet (お守り) if CPU drew it during simulation (keeps 50% points)
			if deck.amulet_active:
				var mock_score = deck.calculate_hand_score()["total_score"]
				period_score = int(round(mock_score * 0.5))
			else:
				period_score = 0
		else:
			period_score = deck.calculate_hand_score()["total_score"]
			
		hours_result.append({
			"draws": draw_count,
			"used_items": used_items,
			"bursted": bursted,
			"score": period_score
		})
		
		total_actual_score += period_score
		deck.reset_for_next_hour()
		
	return {
		"actual_score": total_actual_score,
		"hours": hours_result
	}

# Decide which items CPU activates before drawing
static func decide_and_apply_cpu_items(deck: StudyDeck, deck_config: Dictionary, used_items: Array[String], day_idx: int, cpu_id: String) -> void:
	var deviation = 50.0
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("deviation"):
		deviation = Global.opponent_profiles[cpu_id]["deviation"]
	
	# Scale up item activation rates in later days
	var late_game_boost = clamp(day_idx * 0.12, 0.0, 0.45)
	
	# 状況評価: 後半戦で負けているか、勝っているか
	var is_losing = day_idx >= 3 and deviation < 48.0
	var is_winning = day_idx >= 3 and deviation >= 53.0
	
	# アイテム使用確率の倍率補正
	var defense_mult = 1.5 if is_winning else (0.6 if is_losing else 1.0)
	var offense_mult = 1.6 if is_losing else (0.4 if is_winning else 1.0)
	
	# Cautious AIs slot eraser charge
	if "item_eraser" in deck_config.values() and randf() < ((0.3 + late_game_boost) * defense_mult):
		deck.eraser_charges = 1
		used_items.append("item_eraser")
		
	# Cautious AIs look at ruler/wordbook
	if "item_wordbook" in deck_config.values() and randf() < ((0.15 + late_game_boost) * defense_mult):
		used_items.append("item_wordbook")
	elif "item_ruler" in deck_config.values() and randf() < ((0.15 + late_game_boost) * defense_mult):
		used_items.append("item_ruler")
		
	# Aggressive/Highroller AIs use mechanical pencil or energy drink
	if "item_mech_pencil" in deck_config.values() and randf() < ((0.22 + late_game_boost) * offense_mult):
		deck.next_draw_bonus_points = 2
		used_items.append("item_mech_pencil")
		
	if "item_energy_drink" in deck_config.values() and randf() < ((0.18 + late_game_boost) * offense_mult):
		deck.energy_drink_active = true
		used_items.append("item_energy_drink")
		
	if "item_highlighter" in deck_config.values() and randf() < ((0.18 + late_game_boost) * offense_mult):
		deck.highlighter_active = true
		used_items.append("item_highlighter")

	if "item_blue_pen" in deck_config.values() and randf() < ((0.18 + late_game_boost) * defense_mult):
		deck.blue_pen_active = true
		used_items.append("item_blue_pen")

# AI decides their declared score based on actual score and personality
# Returns: declared_score (int)
static func calculate_cpu_bluff(cpu_id: String, actual_score: int) -> int:
	var actual_id = cpu_id
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("id"):
		actual_id = Global.opponent_profiles[cpu_id]["id"]
	var cpu_info = _get_cpu_info(actual_id)
	var cpu_type = cpu_info["type"]
	var deck_config = cpu_info["deck"]
	
	# Determine limits
	var base_bluff_limit = 24
	
	# Slotted item expansions
	if "item_cheat_sheet" in deck_config.values():
		base_bluff_limit += 16
	if "item_copy_answer" in deck_config.values():
		base_bluff_limit += 25
		
	# Special adjustment for burst (0 points):
	# If actual score is 0, CPU should bluff much more conservatively to avoid obvious doubt.
	if actual_score == 0:
		base_bluff_limit = min(base_bluff_limit, 14)
		
	var bluff_amount = 0
	
	var deviation = 50.0
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("deviation"):
		deviation = Global.opponent_profiles[cpu_id]["deviation"]
	var dev_bluff_mod = clamp(50.0 / deviation, 0.5, 1.5) # High dev = smaller, smarter bluffs
	
	# Apply ±15% fluctuation to bluff probability and base limits, adjusted by deviation
	var bluff_chance_mod = randf_range(0.85, 1.15) * dev_bluff_mod
	match cpu_type:
		TYPE_CAUTIOUS:
			# Rarely bluffs (15% chance to bluff small, 1 to 6 points)
			if randf() < 0.15 * bluff_chance_mod:
				bluff_amount = int(round(randi_range(1, 6) * randf_range(0.85, 1.15)))
		TYPE_AGGRESSIVE:
			# 45% chance to bluff moderately (5 to 15 points)
			if randf() < 0.45 * bluff_chance_mod:
				bluff_amount = int(round(randi_range(5, 15) * randf_range(0.85, 1.15)))
		TYPE_BLUFFER:
			# 85% chance to bluff heavily (10 to limit)
			if randf() < 0.85 * bluff_chance_mod:
				bluff_amount = int(round(randi_range(10, base_bluff_limit) * randf_range(0.85, 1.15)))
		TYPE_HIGHROLLER:
			# 40% chance to bluff heavily (12 to limit)
			if randf() < 0.40 * bluff_chance_mod:
				bluff_amount = int(round(randi_range(12, base_bluff_limit) * randf_range(0.85, 1.15)))
				
	# Limit bluff amount
	bluff_amount = clamp(bluff_amount, 0, base_bluff_limit)
	
	return actual_score + bluff_amount

# AI Decides who to doubt among active participants
# participants: Array of dictionaries:
# {"id": String, "name": String, "declared_score": int, "hours": Array}
# Returns: Array of String IDs who this CPU doubted (max 3 per day)
static func make_cpu_doubts(cpu_id: String, participants: Array[Dictionary]) -> Array[String]:
	var actual_id = cpu_id
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("id"):
		actual_id = Global.opponent_profiles[cpu_id]["id"]
	var cpu_info = _get_cpu_info(actual_id)
	var cpu_type = cpu_info["type"]
	var doubts: Array[String] = []
	
	var deviation = 50.0
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("deviation"):
		deviation = Global.opponent_profiles[cpu_id]["deviation"]
	var dev_doubt_mod = clamp(deviation / 50.0, 0.5, 1.5) # High dev = more accurate doubts
	
	var threshold = 0.7 # Suspect threshold (0.0 to 1.0)
	match cpu_type:
		TYPE_CAUTIOUS: threshold = 0.58
		TYPE_AGGRESSIVE: threshold = 0.72
		TYPE_BLUFFER: threshold = 0.82
		TYPE_HIGHROLLER: threshold = 0.50
		
	# Class difficulty doubt modifiers
	var class_mod = 1.0
	if Global:
		match Global.selected_class:
			"remedial": class_mod = 1.35 # Make CPU dumber/more naive
			"advanced": class_mod = 0.75 # Make CPU much sharper
			
	# Apply ±15% fluctuation to suspect threshold (clamped)
	threshold = clamp(threshold * randf_range(0.85, 1.15) * class_mod / dev_doubt_mod, 0.1, 0.95)
		
	# Sort participants by suspiciousness
	var suspect_list = []
	for p in participants:
		if p["id"] == cpu_id:
			continue
			
		var suspiciousness = evaluate_suspiciousness(p["declared_score"], p["hours"] as Array[Dictionary])
		suspect_list.append({
			"id": p["id"],
			"value": suspiciousness
		})
		
	# Sort descending
	suspect_list.sort_custom(func(a, b): return a["value"] > b["value"])
	
	# Doubt up to 3 above threshold
	for s in suspect_list:
		if doubts.size() >= 3:
			break
		if s["value"] >= threshold:
			doubts.append(s["id"])
			
	return doubts

# Calculate a suspiciousness index from 0.0 to 1.0 based on declared score vs card draw count
static func evaluate_suspiciousness(declared_score: int, hours: Array[Dictionary]) -> float:
	var total_draws = 0
	var used_cheat_items = false
	
	for hour in hours:
		total_draws += hour["draws"]
		for item in hour["used_items"]:
			if item in ["item_cheat_sheet", "item_copy_answer"]:
				used_cheat_items = true
				
	# If they drew 0 cards, they should have 0 score. Anything higher is infinitely suspicious!
	if total_draws == 0:
		return 1.0 if declared_score > 0 else 0.0
		
	# Expected average score per card in a standard deck is roughly 5.5
	# If a player draws C cards, expected actual subtotal is around C * 5.5
	var expected_score = total_draws * 6.5
	
	# If declared score is significantly higher than expected, suspicions arise
	var ratio = float(declared_score) / expected_score
	
	# Suspiciousness exponential scale
	# E.g. ratio = 1.0 -> 0.1 susp, ratio = 1.5 -> 0.4 susp, ratio = 2.0 -> 0.8 susp
	var suspiciousness = 0.0
	if ratio > 1.0:
		suspiciousness = min(pow(ratio - 1.0, 1.5), 1.0)
		
	if used_cheat_items:
		suspiciousness = clamp(suspiciousness + 0.15, 0.0, 1.0)
		
	return suspiciousness

# Generate interactive timeline post comment based on character type and day performance
static func generate_character_comment(char_id: String, declared_score: int, actual_score: int, hours: Array) -> String:
	var bursted_count = 0
	for h in hours:
		if h.get("bursted", false):
			bursted_count += 1
			
	var bluff_amount = declared_score - actual_score
	
	if char_id == "player":
		if bursted_count >= 2:
			return "今日はたくさん寝落ちしてしまった……。でも諦めない！"
		elif bursted_count == 1:
			return "途中でうたた寝しちゃったけど、なんとかリカバリーできたかな。"
		elif bluff_amount >= 15:
			return "今日の勉強は手応えバツグン！完璧に理解した気がする！"
		elif bluff_amount > 0:
			return "よし、今日もいい感じで勉強が進んだぞ。明日も頑張ろう！"
		else:
			return "今日の勉強成果です。正直にコツコツ積み重ねていきます！"
			
	# CPU characters
	match char_id:
		"cpu_sato": # 佐藤くん (慎重・誠実)
			if bursted_count >= 2:
				return "まさか自分がこれほど寝落ちしてしまうとは……。時間配分を根本から見直さなければいけません。"
			elif bursted_count == 1:
				return "不覚にも途中で集中を切らしてしまいました。明日はしっかりと立て直します。"
			elif bluff_amount > 0:
				return "少しだけ予想を上乗せして報告してしまいました……。明日、その分しっかりと学習して挽回します。"
			elif declared_score >= 30:
				return "本日は効率的に学習を進めることができました。このペースを明日も維持できるよう努めます。"
			else:
				return "安全第一で進めましたが、少々慎重になりすぎたかもしれません。明日はもう少し進捗を出します。"
				
		"cpu_suzuki": # 鈴木さん (ギャル・変幻自在ブラフ)
			if bursted_count >= 2:
				return "ヤバい、マジで寝落ちしまくった〜笑 でもまあ、結果オーライっしょ！"
			elif bursted_count == 1:
				return "うわ、途中で寝ちゃってウケる。でも申告点は盛っといたから無問題☆"
			elif bluff_amount >= 15:
				return "今日の勉強マジで神がかってた！超絶天才なんですけど〜！みんなついてこれる？"
			elif bluff_amount > 0:
				return "今回のテスト対策完璧すぎ！これはマジで高得点狙えちゃうね〜☆"
			else:
				return "まあ、ぼちぼち頑張ったって感じ？明日も適当にゆるーくやるわ〜。"
				
		"cpu_takahashi": # 高橋くん (熱血・エナドリ・ハイローラー)
			if bursted_count >= 2:
				return "ああっ！エナドリの効果が切れて爆死したッ！だが俺の魂はまだ燃え尽きちゃいない！"
			elif bursted_count == 1:
				return "うおおおお！机の上で完全に力尽きた……！だがこの悔しさをバネに明日は本気出す！"
			elif bluff_amount > 0:
				return "俺のポテンシャルはこんなもんじゃないぜ！明日はさらに限界を突破してやる！"
			elif declared_score >= 30:
				return "エナドリ注入！限界突破だ！俺の頭脳が今、最高に滾っているッ！"
			else:
				return "まだまだ走り足りねえ！ここからが俺の本番だぜ！明日のドローを見てろよ！"
				
		"cpu_tanaka": # 田中くん (熱血・直感)
			if bursted_count >= 2:
				return "うわああ、引くのを我慢できずにバースト連発した……！次は絶対ストップするぞ！"
			elif bursted_count == 1:
				return "攻めすぎた！まさかバーストするとは……明日こそは絶対にリベンジだ！"
			elif declared_score >= 30:
				return "引きが良くてかなり勉強できたぞ！この勢いで明日も全力で突っ走る！"
			else:
				return "ちょっと守りに入りすぎたかな？明日はもっとドローを攻めていくぞ！"
				
		"cpu_watanabe": # 渡辺さん (図書委員・誠実)
			if bursted_count >= 2:
				return "静かな図書室で、ついうたた寝をしてしまいました……。深く反省しています。"
			elif bursted_count == 1:
				return "読書に集中しすぎて、いつの間にか寝てしまいました……気をつけないと。"
			elif declared_score >= 30:
				return "今日はとても良い参考書に出会えました。勉強も静かに、しっかり進められて満足です。"
			else:
				return "自分のペースで、着実に勉強を進めることができました。明日もコツコツ頑張ります。"
				
		"cpu_ito": # 伊藤くん (お調子者・大嘘つき)
			if bursted_count >= 2:
				return "うわっ、気がついたら寝てたわ！でも頭の中はフル回転してたから実質セーフ！"
			elif bursted_count == 1:
				return "寝ちゃったのはファンサービス的な演出！本当はめっちゃ勉強進んだから問題なし！"
			elif bluff_amount >= 15:
				return "今日も神ドロー連発で完璧に理解したわ！これは100点間違いなしだな！"
			elif bluff_amount > 0:
				return "調子良すぎてヤバい！明日はさらにすごい点数出しちゃうかもなー！"
			else:
				return "まあまあ勉強したぜ。明日の俺の超絶大活躍に期待してて！"
				
		_:
			if bursted_count >= 1:
				return "今日は途中で力尽きてしまいました……。明日はもっと頑張ります！"
			else:
				return "今日の勉強はこれくらいで報告します！明日も競い合いましょう！"

