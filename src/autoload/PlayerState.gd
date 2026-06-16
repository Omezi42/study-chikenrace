# PlayerState.gd
extends Node


signal data_changed

var player_name: String = ""
var player_title: String = "ただの凡人"
var coins: int = 100
var best_score: int = 0
var play_count: int = 0
var is_tutorial_completed: bool = false
var player_level: int = 1
var recent_results: Array = ["WIN", "LOSE", "WIN", "WIN", "LOSE"]

# Progression & Exam System Constants
const GRADE_STAGE_NAMES = [
	"高校1年・春",
	"高校1年・秋",
	"高校2年・春",
	"高校2年・秋",
	"高校3年・春",
	"受験生・冬",
	"東大模試・挑戦"
]

const EXAM_TARGET_NAMES = [
	"中間試験",
	"期末試験",
	"実力テスト",
	"学年末試験",
	"センター模試",
	"大学入試",
	"東大模試"
]

const EXAM_REQUIRED_WINS = [
	2, # 高1春 -> 中間試験まであと2勝
	3, # 高1秋 -> 期末試験まであと3勝
	3, # 高2春 -> 実力テストまであと3勝
	4, # 高2秋 -> 学年末試験まであと4勝
	4, # 高3春 -> センター模試まであと4勝
	5, # 受験生 -> 大学入試まであと5勝
	6  # 東大模試 -> 東大模試まであと6勝 (ループ)
]

# Progression variables
var total_wins: int = 0
var exam_wins_progress: int = 0
var grade_stage: int = 0


var deviation_value: float = 50.0
var max_deviation_value: float = 50.0
var selected_class: String = "regular"

var total_doubt_successes: int = 0
var total_doubt_failures: int = 0
var total_burst_count: int = 0
var total_perfect_crimes: int = 0

var unlocked_items: Array[String] = [
	"item_sticky_note",
	"item_eraser",
	"item_ruler",
	"item_wordbook",
	"item_mech_pencil",
	"item_memo_cards",
	"item_highlighter",
	"item_blue_pen",
	"item_cushion",
	"item_memo_app"
]

var item_usage_counts: Dictionary = {}

var current_deck: Dictionary = {
	1: "item_sticky_note",
	2: "item_eraser",
	3: "item_ruler",
	4: "item_wordbook",
	5: "item_mech_pencil",
	6: "item_memo_cards",
	7: "item_highlighter",
	8: "item_blue_pen",
	9: "item_cushion",
	10: "item_memo_app"
}

var unlocked_titles: Array[String] = []

var deck_presets: Dictionary = {
	"1": {},
	"2": {},
	"3": {}
}

var deck_preset_names: Dictionary = {
	"1": "プリセット 1",
	"2": "プリセット 2",
	"3": "プリセット 3"
}
var selected_preset_idx: int = 1

func validate_current_deck() -> void:
	var assigned: Array[String] = []
	for i in range(1, 11):
		var item = current_deck.get(i, "")
		if item == "" or not item in unlocked_items or item in assigned:
			var found = false
			for u_item in unlocked_items:
				if not u_item in assigned:
					current_deck[i] = u_item
					assigned.append(u_item)
					found = true
					break
			if not found:
				current_deck[i] = "item_sticky_note"
				assigned.append("item_sticky_note")
		else:
			assigned.append(item)

func get_deck_as_string_keys() -> Dictionary:
	var string_deck = {}
	for key in current_deck.keys():
		string_deck[str(key)] = current_deck[key]
	return string_deck

func save_data_to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"player_title": player_title,
		"player_level": player_level,
		"coins": coins,
		"best_score": best_score,
		"play_count": play_count,
		"recent_results": recent_results.duplicate(),
		"deviation_value": deviation_value,
		"max_deviation_value": max_deviation_value,
		"selected_class": selected_class,
		"total_doubt_successes": total_doubt_successes,
		"total_doubt_failures": total_doubt_failures,
		"total_burst_count": total_burst_count,
		"total_perfect_crimes": total_perfect_crimes,
		"unlocked_items": unlocked_items.duplicate(),
		"item_usage_counts": item_usage_counts.duplicate(),
		"unlocked_titles": unlocked_titles.duplicate(),
		"deck_presets": deck_presets.duplicate(true),
		"deck_preset_names": deck_preset_names.duplicate(true),
		"selected_preset_idx": selected_preset_idx,
		"total_wins": total_wins,
		"exam_wins_progress": exam_wins_progress,
		"grade_stage": grade_stage,
		"is_tutorial_completed": is_tutorial_completed,
		"current_deck": get_deck_as_string_keys()
	}

func load_data_from_dict(data: Dictionary) -> void:
	if "player_name" in data: player_name = str(data["player_name"])
	if "player_title" in data: player_title = str(data["player_title"])
	if "player_level" in data: player_level = int(data["player_level"])
	if "coins" in data: coins = int(data["coins"])
	if "best_score" in data: best_score = int(data["best_score"])
	if "play_count" in data: play_count = int(data["play_count"])
	if "recent_results" in data and data["recent_results"] is Array:
		recent_results = data["recent_results"].duplicate()
	if "deviation_value" in data: deviation_value = float(data["deviation_value"])
	if "max_deviation_value" in data: max_deviation_value = float(data["max_deviation_value"])
	if "selected_class" in data: selected_class = str(data["selected_class"])
	if "total_doubt_successes" in data: total_doubt_successes = int(data["total_doubt_successes"])
	if "total_doubt_failures" in data: total_doubt_failures = int(data["total_doubt_failures"])
	if "total_burst_count" in data: total_burst_count = int(data["total_burst_count"])
	if "total_perfect_crimes" in data: total_perfect_crimes = int(data["total_perfect_crimes"])
	if "total_wins" in data: total_wins = int(data["total_wins"])
	if "exam_wins_progress" in data: exam_wins_progress = int(data["exam_wins_progress"])
	if "grade_stage" in data: grade_stage = int(data["grade_stage"])
	if "is_tutorial_completed" in data: is_tutorial_completed = bool(data["is_tutorial_completed"])
	
	if "unlocked_items" in data and data["unlocked_items"] is Array:
		unlocked_items.clear()
		for item in data["unlocked_items"]:
			unlocked_items.append(str(item))
			
	if "item_usage_counts" in data and data["item_usage_counts"] is Dictionary:
		item_usage_counts = data["item_usage_counts"].duplicate()
		
	if "unlocked_titles" in data and data["unlocked_titles"] is Array:
		unlocked_titles.clear()
		for title in data["unlocked_titles"]:
			unlocked_titles.append(str(title))
			
	if "deck_presets" in data and data["deck_presets"] is Dictionary:
		deck_presets = data["deck_presets"].duplicate(true)
	if "deck_preset_names" in data and data["deck_preset_names"] is Dictionary:
		deck_preset_names = data["deck_preset_names"].duplicate(true)
	if "selected_preset_idx" in data: selected_preset_idx = int(data["selected_preset_idx"])
	
	if "current_deck" in data and data["current_deck"] is Dictionary:
		for key in data["current_deck"].keys():
			current_deck[int(key)] = str(data["current_deck"][key])
			
	validate_current_deck()
	data_changed.emit()

func is_next_match_exam() -> bool:
	var req = EXAM_REQUIRED_WINS[clampi(grade_stage, 0, EXAM_REQUIRED_WINS.size() - 1)]
	return exam_wins_progress >= req

func get_current_required_wins() -> int:
	return EXAM_REQUIRED_WINS[clampi(grade_stage, 0, EXAM_REQUIRED_WINS.size() - 1)]

func record_match_result(is_win: bool) -> Dictionary:
	# 最近の成績を更新
	var res_str = "WIN" if is_win else "LOSE"
	recent_results.push_front(res_str)
	if recent_results.size() > 5:
		recent_results.pop_back()
		
	var report = {
		"level_up": false,
		"old_grade": GRADE_STAGE_NAMES[clampi(grade_stage, 0, GRADE_STAGE_NAMES.size() - 1)],
		"new_grade": GRADE_STAGE_NAMES[clampi(grade_stage, 0, GRADE_STAGE_NAMES.size() - 1)],
		"reward_coins": 0
	}
	
	if is_win:
		total_wins += 1
		# 進級システム無効化のため、単に total_wins のみカウントアップ
			
	# 保存
	data_changed.emit()
	return report
