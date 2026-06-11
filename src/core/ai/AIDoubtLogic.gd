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
	
	var deviation = 50.0
	if Global and Global.opponent_profiles.has(cpu_id) and Global.opponent_profiles[cpu_id].has("deviation"):
		deviation = Global.opponent_profiles[cpu_id]["deviation"]
	var dev_doubt_mod = clamp(deviation / 50.0, 0.5, 1.5)
	
	var threshold = 0.7
	var bc = Engine.get_main_loop().root.get_node_or_null("BalanceConfig")
	if bc:
		var cfg_threshold = bc.get_value("doubt.threshold." + cpu_type)
		if cfg_threshold != null:
			threshold = float(cfg_threshold)
	else:
		match cpu_type:
			AIProfile.TYPE_CAUTIOUS: threshold = 0.58
			AIProfile.TYPE_AGGRESSIVE: threshold = 0.72
			AIProfile.TYPE_BLUFFER: threshold = 0.82
			AIProfile.TYPE_HIGHROLLER: threshold = 0.50
		
	var class_mod = 1.0
	if Global:
		if Global.game_mode == Constants.MODE_RANDOM:
			var league = Global.get_deviation_league(Global.deviation_value)
			if bc:
				var cfg_class_mod = bc.get_value("doubt.league_mod." + league)
				if cfg_class_mod != null:
					class_mod = float(cfg_class_mod)
			else:
				match league:
					Constants.LEAGUE_S: class_mod = 0.65
					Constants.LEAGUE_A: class_mod = 0.8
					Constants.LEAGUE_B: class_mod = 1.0
					Constants.LEAGUE_C: class_mod = 1.2
					Constants.LEAGUE_F: class_mod = 1.45
		else:
			if bc:
				var cfg_class_mod = bc.get_value("doubt.class_mod." + Global.selected_class)
				if cfg_class_mod != null:
					class_mod = float(cfg_class_mod)
			else:
				match Global.selected_class:
					"remedial": class_mod = 1.35
					"advanced": class_mod = 0.75
			
	threshold = clamp(threshold * randf_range(0.85, 1.15) * class_mod / dev_doubt_mod, 0.1, 0.95)
	
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
	if history["sample_size"] >= 1:
		if history["lie_rate"] > 0.5:
			threshold *= 0.8
		elif history["lie_rate"] < 0.2 and history["sample_size"] >= 2:
			threshold *= 1.2
		
	var suspect_list = []
	for p in participants:
		if p["id"] == cpu_id:
			continue
			
		var suspiciousness = AIRiskEvaluator.evaluate_suspiciousness_with_emote(p["declared_score"], p["hours"] as Array[Dictionary], p.get("emote", "normal"))
		suspect_list.append({
			"id": p["id"],
			"value": suspiciousness
		})
		
	suspect_list.sort_custom(func(a, b): return a["value"] > b["value"])
	
	var max_doubts = 3
	if bc:
		var cfg_max = bc.get_value("doubt.max_doubts_per_day")
		if cfg_max != null:
			max_doubts = int(cfg_max)
	
	for s in suspect_list:
		if doubts.size() >= max_doubts:
			break
		if s["value"] >= threshold:
			doubts.append(s["id"])
			
	return doubts
