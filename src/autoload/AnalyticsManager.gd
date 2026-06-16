extends Node

# 分析用イベントログを管理するクラス
# ゲーム内の各種行動や結果を記録し、後で送信・分析するための基盤

var _current_session_events: Array = []
var _session_id: String = ""

func _ready() -> void:
	# セッションIDの生成 (簡易的)
	_session_id = str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	print("[AnalyticsManager] Initialized session: ", _session_id)

# イベントの記録
func log_event(action: String, data: Dictionary = {}) -> void:
	var event_data: Dictionary = {
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": _session_id,
		"action": action
	}
	# 追加データの結合
	for key in data:
		event_data[key] = data[key]
		
	_current_session_events.append(event_data)
	
	# デバッグ用に出力
	print("[Analytics] Logged: ", action, " | Data: ", data)

# 記録された全イベントの取得（送信などに使用）
func get_events() -> Array:
	return _current_session_events

# セッションリセット
func reset_session() -> void:
	_current_session_events.clear()
	_session_id = str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	print("[AnalyticsManager] Reset session: ", _session_id)

# ユーティリティメソッド（各種アクション用）

func log_draw_card(day: int, hour: int, draw_count: int, burst_probability: float) -> void:
	log_event("draw_card", {
		"day": day,
		"hour": hour,
		"draw_count": draw_count,
		"burst_probability": burst_probability
	})

func log_stop_draw(day: int, hour: int, draw_count: int, score: int) -> void:
	log_event("stop_draw", {
		"day": day,
		"hour": hour,
		"draw_count": draw_count,
		"score": score
	})

func log_burst(day: int, hour: int, draw_count: int) -> void:
	log_event("burst", {
		"day": day,
		"hour": hour,
		"draw_count": draw_count
	})

func log_declare_score(day: int, hour: int, declared_score: int, actual_score: int, bluff_amount: int) -> void:
	log_event("declare_score", {
		"day": day,
		"hour": hour,
		"declared_score": declared_score,
		"actual_score": actual_score,
		"bluff_amount": bluff_amount
	})

func log_doubt(day: int, target_player_id: String, success: bool) -> void:
	log_event("doubt", {
		"day": day,
		"target_player": target_player_id,
		"success": success
	})

func log_day_finish(day: int, current_rank: int, total_score: int) -> void:
	log_event("day_finish", {
		"day": day,
		"rank": current_rank,
		"total_score": total_score
	})

func log_game_finish(final_rank: int, total_score: int) -> void:
	log_event("game_finish", {
		"final_rank": final_rank,
		"total_score": total_score
	})
