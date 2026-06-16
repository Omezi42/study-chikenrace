class_name AIRiskEvaluator
extends RefCounted

static func evaluate_suspiciousness(declared_score: int, hours: Array[Dictionary]) -> float:
	var total_draws = 0
	var used_cheat_items = false
	
	for hour in hours:
		total_draws += hour.get("draws", 0)
		for item in hour.get("used_items", []):
			if item in ["item_cheat_sheet", "item_copy_answer"]:
				used_cheat_items = true
				
	if total_draws == 0:
		return 1.0 if declared_score > 0 else 0.0
		
	var expected_score = total_draws * 6.5
	var ratio = float(declared_score) / expected_score
	
	var suspiciousness = 0.0
	if ratio > 1.0:
		suspiciousness = min(pow(ratio - 1.0, 1.5), 1.0)
		
	if used_cheat_items:
		suspiciousness = clamp(suspiciousness + 0.15, 0.0, 1.0)
		
	return suspiciousness

static func evaluate_suspiciousness_with_emote(declared_score: int, hours: Array[Dictionary], emote: String) -> float:
	var susp = evaluate_suspiciousness(declared_score, hours)
	
	match emote:
		"anxious":
			susp = clamp(susp + 0.20, 0.0, 1.0)
		"confident":
			if declared_score >= 50:
				susp = clamp(susp + 0.10, 0.0, 1.0)
			elif declared_score < 40:
				susp = clamp(susp - 0.15, 0.0, 1.0)
		"normal":
			pass
			
	return susp
