# -*- coding: utf-8 -*-
extends Node

signal mission_completed(mission_id: String, reward_coins: int)

const MISSION_POOL: Array[Dictionary] = [
	{"id": "doubt_success_1", "desc": "ダウトを1回成功させる", "target": 1, "type": "doubt_success", "reward": 15},
	{"id": "doubt_success_3", "desc": "ダウトを3回成功させる", "target": 3, "type": "doubt_success", "reward": 40},
	{"id": "no_burst", "desc": "1試合バーストせずにクリアする", "target": 1, "type": "no_burst", "reward": 25},
	{"id": "play_2", "desc": "2試合プレイする", "target": 2, "type": "play_count", "reward": 20},
	{"id": "perfect_crime", "desc": "パーフェクトクライムを達成する", "target": 1, "type": "perfect_crime", "reward": 50},
	{"id": "score_150", "desc": "合計150点以上を取る", "target": 150, "type": "min_score", "reward": 30},
	{"id": "win_first", "desc": "1位を取る", "target": 1, "type": "rank_first", "reward": 35},
]

func _ready() -> void:
	# Globalのロードが終わった後に呼び出すため、少し待つかGlobalから明示的に初期化されるようにする
	call_deferred("_check_and_refresh_missions")

func _check_and_refresh_missions() -> void:
	if not "last_mission_date" in Global:
		return
	var today = Time.get_date_string_from_system()
	if today != Global.last_mission_date:
		_generate_daily_missions(today)

func _generate_daily_missions(date_str: String) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(date_str)
	
	var pool = MISSION_POOL.duplicate()
	Global.today_missions.clear()
	Global.mission_progress.clear()
	
	# 3つのミッションをランダム選出
	for i in range(min(3, pool.size())):
		var idx = rng.randi() % pool.size()
		Global.today_missions.append(pool[idx])
		Global.mission_progress[pool[idx]["id"]] = 0
		pool.remove_at(idx)
	
	Global.last_mission_date = date_str
	Global.save_game()

func report_event(event_type: String, value: int = 1) -> void:
	_check_and_refresh_missions()
	
	for mission in Global.today_missions:
		if mission["type"] == event_type:
			var mid = mission["id"]
			var current = Global.mission_progress.get(mid, 0)
			var target = mission["target"]
			if current >= target:
				continue  # 既に達成済み
			
			var new_val = min(current + value, target)
			Global.mission_progress[mid] = new_val
			
			if new_val >= target:
				Global.coins += mission["reward"]
				Global.save_game()
				mission_completed.emit(mid, mission["reward"])
				# UI通知用にシグナルを送信
				if has_node("/root/UIHelper"):
					get_node("/root/UIHelper").show_toast("ミッションクリア！: " + mission["desc"] + " (+ " + str(mission["reward"]) + "コイン)")

func get_missions_display() -> Array[Dictionary]:
	_check_and_refresh_missions()
	var result: Array[Dictionary] = []
	for mission in Global.today_missions:
		var mid = mission["id"]
		result.append({
			"desc": mission["desc"],
			"progress": Global.mission_progress.get(mid, 0),
			"target": mission["target"],
			"reward": mission["reward"],
			"completed": Global.mission_progress.get(mid, 0) >= mission["target"]
		})
	return result
