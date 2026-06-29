class_name AIDoubtLogic
extends RefCounted

static func _analyze_player_bluff_history(session: GameSession, day_idx: int) -> Dictionary:
	var total_lies := 0
	var total_days_checked := 0
	var avg_bluff_amount := 0.0
	
	if not session:
		return {
			"lie_rate": 0.0,
			"avg_bluff": 0.0,
			"sample_size": 0
		}
	
	for d in range(1, day_idx):
		if not session.match_history.has(d):
			continue
		var day_data = session.match_history[d]
		if not day_data.has("player"):
			continue
		total_days_checked += 1
		var p = day_data["player"]
		var actual = p.get("actual_score", 0)
		var declared = p.get("declared_score", 0)
		if declared > actual:
			total_lies += 1
			avg_bluff_amount += (declared - actual)
	
	if total_lies > 0:
		avg_bluff_amount /= total_lies
	
	var lie_rate = float(total_lies) / max(total_days_checked, 1)
	return {
		"lie_rate": lie_rate,
		"avg_bluff": avg_bluff_amount,
		"sample_size": total_days_checked
	}

static func make_cpu_doubts(cpu_id: String, participants: Array[Dictionary]) -> Array[String]:
	var actual_id = cpu_id
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("id"):
		actual_id = Global.opponent_profiles[cpu_id]["id"]
	var cpu_info = AIProfile._get_cpu_info(actual_id)
	var cpu_type = cpu_info["type"]
	var doubts: Array[String] = []
	

	var main_loop = Engine.get_main_loop()
	var session = null
	if main_loop is SceneTree:
		var root = main_loop.root
		var gamescene = root.get_node_or_null("GameScene")
		if gamescene and gamescene.get("session"):
			session = gamescene.get("session")
		else:
			for child in root.get_children():
				if child.has_method("get") and child.get("session") is GameSession:
					session = child.get("session")
					break
	
	var day_idx = 1
	if session:
		day_idx = session.current_day
		
	var history = _analyze_player_bluff_history(session, day_idx)
	
	# Evaluate EV based doubt for each opponent
	var suspect_list = []
	for p in participants:
		if p["id"] == cpu_id:
			continue
			
		var suspiciousness = AIRiskEvaluator.evaluate_suspiciousness_with_emote(p["declared_score"], p["hours"] as Array[Dictionary], p.get("emote", "normal"))
		
		# ---- ユーザー要望: 実際に相手が嘘をついているときほど少しだけダウトされやすくする（直感補正） ----
		var is_actually_lying = false
		if p.has("actual_score") and p["declared_score"] > p["actual_score"]:
			is_actually_lying = true
		
		if is_actually_lying:
			# 少しだけダウトされやすくする（直感補正）
			var intuition_bonus = 0.05
			suspiciousness = clamp(suspiciousness + intuition_bonus, 0.0, 1.0)
		# ------------------------------------------------------------------------------------------
			
		# EV Calculation
		# ダウト失敗ペナルティ
		var penalty_base: int = 15
		var bc = Engine.get_main_loop().root.get_node_or_null("BalanceConfig")
		if bc:
			penalty_base = bc.get_value("exposure.fail_penalty_base", 15)
			var penalty_per_day = bc.get_value("exposure.fail_penalty_per_day", 3)
			penalty_base += (day_idx - 1) * penalty_per_day
		else:
			penalty_base += (day_idx - 1) * 3
			
		# 推定盛り幅
		var estimated_bluff = 15.0
		if p["id"] == "player" and history["sample_size"] > 0 and history["avg_bluff"] > 0:
			estimated_bluff = history["avg_bluff"]
		
		var success_bonus = estimated_bluff * 0.75 + 6.0
		var prob_lying = suspiciousness
		var prob_truth = 1.0 - suspiciousness
		
		var expected_value = (prob_lying * success_bonus) - (prob_truth * penalty_base)
		
		# 性格に基づくEV閾値
		var ev_threshold = 0.0
		match cpu_type:
			AIProfile.TYPE_CAUTIOUS: ev_threshold = 3.0   # 期待値が+3以上じゃないとダウトしない
			AIProfile.TYPE_AGGRESSIVE: ev_threshold = -2.0 # 多少マイナスでも攻める
			AIProfile.TYPE_BLUFFER: ev_threshold = 0.0    # プラマイ0でGO
			AIProfile.TYPE_HIGHROLLER: ev_threshold = -5.0 # リスクを恐れない
			
		if Global.game_mode == Constants.MODE_CPU:
			match Global.cpu_difficulty:
				"easy": ev_threshold += 6.0
				"hard": ev_threshold -= 6.0
			

		suspect_list.append({
			"id": p["id"],
			"ev": expected_value,
			"threshold": ev_threshold,
			"suspiciousness": suspiciousness
		})
		
	suspect_list.sort_custom(func(a, b): return a["ev"] > b["ev"])
	
	var max_doubts = 3
	var bc2 = Engine.get_main_loop().root.get_node_or_null("BalanceConfig")
	if bc2:
		var cfg_max = bc2.get_value("doubt.max_doubts_per_day")
		if cfg_max != null:
			max_doubts = int(cfg_max)
	
	for s in suspect_list:
		if doubts.size() >= max_doubts:
			break
		if s["ev"] >= s["threshold"]:
			doubts.append(s["id"])
			
	return doubts
