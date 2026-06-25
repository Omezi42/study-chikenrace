class_name AIManager
extends RefCounted

# AI Personality Constants
const TYPE_CAUTIOUS = AIProfile.TYPE_CAUTIOUS      # 慎重
const TYPE_AGGRESSIVE = AIProfile.TYPE_AGGRESSIVE  # テンポ押し
const TYPE_BLUFFER = AIProfile.TYPE_BLUFFER        # ブラフ寄り
const TYPE_HIGHROLLER = AIProfile.TYPE_HIGHROLLER  # ハイロール

# Reference to CPU Definitions
const CPU_OPPONENTS = AIProfile.CPU_OPPONENTS

static func get_cpu_info(actual_id: String) -> Dictionary:
	return AIProfile.get_cpu_info(actual_id)

static func get_cpu_name(actual_id: String) -> String:
	return AIProfile.get_cpu_name(actual_id)

static func simulate_cpu_day(cpu_id: String, day_idx: int) -> Dictionary:
	return AIStrategyManager.simulate_cpu_day(cpu_id, day_idx)



static func calculate_cpu_bluff(cpu_id: String, actual_score: int, day_idx: int = 1) -> int:
	return AIBluffLogic.calculate_cpu_bluff(cpu_id, actual_score, day_idx)

static func select_cpu_emote(cpu_id: String, bluff_amount: int, actual_score: int) -> String:
	return AIBluffLogic.select_cpu_emote(cpu_id, bluff_amount, actual_score)

static func make_cpu_doubts(cpu_id: String, participants: Array[Dictionary]) -> Array[String]:
	return AIDoubtLogic.make_cpu_doubts(cpu_id, participants)

static func evaluate_suspiciousness(declared_score: int, hours: Array) -> float:
	return AIRiskEvaluator.evaluate_suspiciousness(declared_score, hours)

static func evaluate_suspiciousness_with_emote(declared_score: int, hours: Array, emote: String) -> float:
	return AIRiskEvaluator.evaluate_suspiciousness_with_emote(declared_score, hours, emote)

static func generate_character_comment(char_id: String, declared_score: int, actual_score: int, hours: Array) -> String:
	return AIBluffLogic.generate_character_comment(char_id, declared_score, actual_score, hours)
