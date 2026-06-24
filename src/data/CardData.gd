class_name CardData
extends RefCounted

static func get_reaction_text(prob: float) -> String:
	if prob <= 0.15:
		return "落ち着いている"
	elif prob <= 0.40:
		return "少し緊張している..."
	elif prob <= 0.70:
		return "冷や汗をかいている..."
	else:
		return "手が震えている！"
