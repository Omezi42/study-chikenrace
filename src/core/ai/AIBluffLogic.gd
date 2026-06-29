class_name AIBluffLogic
extends RefCounted

static func calculate_cpu_bluff(cpu_id: String, actual_score: int, day_idx: int = 1) -> int:
	var actual_id = cpu_id
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("id"):
		actual_id = Global.opponent_profiles[cpu_id]["id"]
	var cpu_info = AIProfile._get_cpu_info(actual_id)
	var cpu_type = cpu_info["type"]
	var deck_config = cpu_info["deck"]
	
	var base_bluff_limit = 24
	var standing = AIStrategyManager._evaluate_cpu_standing(cpu_id, day_idx)
	var is_losing = standing["is_losing"]
	var is_winning = standing["is_winning"]


	if is_losing:
		base_bluff_limit += 8
	elif is_winning:
		base_bluff_limit = max(base_bluff_limit - 6, 8)
		
	if actual_score == 0:
		base_bluff_limit = min(base_bluff_limit, 14)
		
	var bluff_amount = 0
	
	var bluff_chance_mod = Global.cpu_rng.randf_range(0.85, 1.15)
	if is_losing:
		bluff_chance_mod *= 1.3
	elif is_winning:
		bluff_chance_mod *= 0.6
		
	match cpu_type:
		AIProfile.TYPE_CAUTIOUS:
			if Global.cpu_rng.randf() < 0.15 * bluff_chance_mod:
				bluff_amount = int(round(Global.cpu_rng.randi_range(1, 6) * Global.cpu_rng.randf_range(0.85, 1.15)))
		AIProfile.TYPE_AGGRESSIVE:
			if Global.cpu_rng.randf() < 0.45 * bluff_chance_mod:
				bluff_amount = int(round(Global.cpu_rng.randi_range(5, 15) * Global.cpu_rng.randf_range(0.85, 1.15)))
		AIProfile.TYPE_BLUFFER:
			if Global.cpu_rng.randf() < 0.85 * bluff_chance_mod:
				bluff_amount = int(round(Global.cpu_rng.randi_range(10, base_bluff_limit) * Global.cpu_rng.randf_range(0.85, 1.15)))
		AIProfile.TYPE_HIGHROLLER:
			if Global.cpu_rng.randf() < 0.40 * bluff_chance_mod:
				bluff_amount = int(round(Global.cpu_rng.randi_range(12, base_bluff_limit) * Global.cpu_rng.randf_range(0.85, 1.15)))
				
	bluff_amount = clamp(bluff_amount, 0, base_bluff_limit)
	return actual_score + bluff_amount

static func select_cpu_emote(cpu_id: String, bluff_amount: int, actual_score: int) -> String:
	var actual_id = cpu_id
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("id"):
		actual_id = Global.opponent_profiles[cpu_id]["id"]
	var cpu_info = AIProfile._get_cpu_info(actual_id)
	var cpu_type = cpu_info["type"]
	
	if bluff_amount == 0:
		if actual_score >= 35 and (cpu_type == AIProfile.TYPE_HIGHROLLER or cpu_type == AIProfile.TYPE_AGGRESSIVE or cpu_type == AIProfile.TYPE_BLUFFER):
			if Global.cpu_rng.randf() < 0.4:
				return "confident"
		return "normal"
		
	var roll = Global.cpu_rng.randf()
	match cpu_type:
		AIProfile.TYPE_CAUTIOUS:
			return "anxious" if roll < 0.65 else "normal"
		AIProfile.TYPE_BLUFFER:
			if roll < 0.45: return "confident"
			elif roll < 0.90: return "normal"
			else: return "anxious"
		AIProfile.TYPE_HIGHROLLER:
			if roll < 0.60: return "confident"
			elif roll < 0.90: return "normal"
			else: return "anxious"
		AIProfile.TYPE_AGGRESSIVE:
			if bluff_amount >= 12:
				return "anxious" if roll < 0.55 else "normal"
			else:
				if roll < 0.15: return "confident"
				elif roll < 0.65: return "normal"
				else: return "anxious"
	return "normal"

static func generate_character_comment(char_id: String, declared_score: int, actual_score: int, hours: Array) -> String:
	var bursted_count = 0
	for h in hours:
		if h.get("bursted", false):
			bursted_count += 1
			
	var bluff_amount = declared_score - actual_score
	
	if char_id == "player":
		if bursted_count >= 2: return "今日はたくさん寝落ちしてしまった……。でも諦めない！"
		elif bursted_count == 1: return "途中でうたた寝しちゃったけど、なんとかリカバリーできたかな。"
		elif bluff_amount >= 15: return "今日の勉強は手応えバツグン！完璧に理解した気がする！"
		elif bluff_amount > 0: return "よし、今日もいい感じで勉強が進んだぞ。明日も頑張ろう！"
		else: return "今日の勉強成果です。正直にコツコツ積み重ねていきます！"
			
	match char_id:
		"cpu_sato":
			if bursted_count >= 2: return "まさか自分がこれほど寝落ちしてしまうとは……。時間配分を根本から見直さなければいけません。"
			elif bursted_count == 1: return "不覚にも途中で集中を切らしてしまいました。明日はしっかりと立て直します。"
			elif bluff_amount > 0: return "少しだけ予想を上乗せして報告してしまいました……。明日、その分しっかりと学習して挽回します。"
			elif declared_score >= 30: return "本日は効率的に学習を進めることができました。このペースを明日も維持できるよう努めます。"
			else: return "安全第一で進めましたが、少々慎重になりすぎたかもしれません。明日はもう少し進捗を出します。"
		"cpu_suzuki":
			if bursted_count >= 2: return "ヤバい、マジで寝落ちしまくった〜笑 でもまあ、結果オーライっしょ！"
			elif bursted_count == 1: return "うわ、途中で寝ちゃってウケる。でも申告点は盛っといたから無問題☆"
			elif bluff_amount >= 15: return "今日の勉強マジで神がかってた！超絶天才なんですけど〜！みんなついてこれる？"
			elif bluff_amount > 0: return "今回のテスト対策完璧すぎ！これはマジで高得点狙えちゃうね〜☆"
			else: return "まあ、ぼちぼち頑張ったって感じ？明日も適当にゆるーくやるわ〜。"
		"cpu_takahashi":
			if bursted_count >= 2: return "ああっ！エナドリの効果が切れて爆死したッ！だが俺の魂はまだ燃え尽きちゃいない！"
			elif bursted_count == 1: return "うおおおお！机の上で完全に力尽きた……！だがこの悔しさをバネに明日は本気出す！"
			elif bluff_amount > 0: return "俺のポテンシャルはこんなもんじゃないぜ！明日はさらに限界を突破してやる！"
			elif declared_score >= 30: return "エナドリ注入！限界突破だ！俺の頭脳が今、最高に滾っているッ！"
			else: return "まだまだ走り足りねえ！ここからが俺の本番だぜ！明日のドローを見てろよ！"
		"cpu_tanaka":
			if bursted_count >= 2: return "うわああ、引くのを我慢できずにバースト連発した……！次は絶対ストップするぞ！"
			elif bursted_count == 1: return "攻めすぎた！まさかバーストするとは……明日こそは絶対にリベンジだ！"
			elif declared_score >= 30: return "引きが良くてかなり勉強できたぞ！この勢いで明日も全力で突っ走る！"
			else: return "ちょっと守りに入りすぎたかな？明日はもっとドローを攻めていくぞ！"
		"cpu_watanabe":
			if bursted_count >= 2: return "静かな図書室で、ついうたた寝をしてしまいました……。深く反省しています。"
			elif bursted_count == 1: return "読書に集中しすぎて、いつの間にか寝てしまいました……気をつけないと。"
			elif declared_score >= 30: return "今日はとても良い参考書に出会えました。勉強も静かに、しっかり進められて満足です。"
			else: return "自分のペースで、着実に勉強を進めることができました。明日もコツコツ頑張ります。"
		"cpu_ito":
			if bursted_count >= 2: return "うわっ、気がついたら寝てたわ！でも頭の中はフル回転してたから実質セーフ！"
			elif bursted_count == 1: return "寝ちゃったのはファンサービス的な演出！本当はめっちゃ勉強進んだから問題なし！"
			elif bluff_amount >= 15: return "今日も神ドロー連発で完璧に理解したわ！これは100点間違いなしだな！"
			elif bluff_amount > 0: return "調子良すぎてヤバい！明日はさらにすごい点数出しちゃうかもなー！"
			else: return "まあまあ勉強したぜ。明日の俺の超絶大活躍に期待してて！"
		_:
			if bursted_count >= 1: return "今日は途中で力尽きてしまいました……。明日はもっと頑張ります！"
			else: return "今日の勉強はこれくらいで報告します！明日も競い合いましょう！"
