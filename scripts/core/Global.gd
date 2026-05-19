extends Node

var player_name: String = ""
var total_score: int = 0
var play_count: int = 0
var has_seen_tutorial: bool = false
var current_play_mode: int = 2 # 0: ROOM, 1: CPU, 2: GLOBAL

var daily_noises: Dictionary = {
	0: 0, 1: 0, 2: 0, 3: 0, 4: 0
}

# CPUモード用のステートとローカルハイスコア
var cpu_data: Array = []
var high_score_cpu: int = 0
var best_rank_cpu: String = "未プレイ"

# メタゲーム（王座ボーナスといいね）用ステート
var last_reported_scores: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
var last_actual_scores: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
var last_top_subjects: Array = []

# スコア履歴（日別推移・プレイヤー別集計用）
# [{"day": 1, "total": 42, "subjects": {0: 10, ...}, "rivals": [{"name": "...", "score": 30, "subjects": {...}}]}]
var score_history: Array = []

# タイムラインでのライバルへのいいね（投票）履歴の永続化
# キー: "day_【Day数】_【ライバル名】_【教科ID】" -> true
var accumulated_votes: Dictionary = {}

const SAVE_PATH = "user://savegame.json"

func _ready():
	load_data()

func save_data():
	var data = {
		"player_name": player_name,
		"total_score": total_score,
		"play_count": play_count,
		"has_seen_tutorial": has_seen_tutorial,
		"daily_noises": daily_noises,
		"high_score_cpu": high_score_cpu,
		"best_rank_cpu": best_rank_cpu,
		"last_reported_scores": last_reported_scores,
		"last_actual_scores": last_actual_scores,
		"last_top_subjects": last_top_subjects,
		"score_history": score_history,
		"accumulated_votes": accumulated_votes
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data))

func load_data():
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			player_name = data.get("player_name", "")
			total_score = data.get("total_score", 0)
			play_count = data.get("play_count", 0)
			has_seen_tutorial = data.get("has_seen_tutorial", false)
			var noises = data.get("daily_noises", {})
			for k in noises: daily_noises[int(k)] = noises[k]
			high_score_cpu = data.get("high_score_cpu", 0)
			best_rank_cpu = data.get("best_rank_cpu", "未プレイ")
			var last_rep = data.get("last_reported_scores", {})
			for k in last_rep: last_reported_scores[int(k)] = last_rep[k]
			var last_act = data.get("last_actual_scores", {})
			for k in last_act: last_actual_scores[int(k)] = last_act[k]
			last_top_subjects = data.get("last_top_subjects", [])
			score_history = data.get("score_history", [])
			accumulated_votes = data.get("accumulated_votes", {})


func unlock_achievement(_id: String, _title: String):
	print("Achievement Unlocked: ", _title)
