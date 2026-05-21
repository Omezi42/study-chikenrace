extends Node

var player_name: String = ""
var total_score: int = 0
var play_count: int = 0
var has_seen_tutorial: bool = false
var current_play_mode: int = 2 # 0: ROOM, 1: CPU, 2: GLOBAL

# CPUモード用のステートとローカルハイスコア
var cpu_data: Array = []
var high_score_cpu: int = 0
var best_rank_cpu: String = "未プレイ"

# メタゲーム（いいね・嘘判定）用ステート
var last_reported_score: int = 0
var last_actual_score: int = 0

# スコア履歴（日別推移・プレイヤー別集計用）
# [{"day": 1, "total": 42, "actual_score": 42, "reported_score": 42, "rivals": [{"name": "...", "score": 30}]}]
var score_history: Array = []

# タイムラインでのライバルへのいいね（投票）履歴の永続化
# キー: "day_【Day数】_【ライバル名】" -> true
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
		"high_score_cpu": high_score_cpu,
		"best_rank_cpu": best_rank_cpu,
		"last_reported_score": last_reported_score,
		"last_actual_score": last_actual_score,
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
			high_score_cpu = data.get("high_score_cpu", 0)
			best_rank_cpu = data.get("best_rank_cpu", "未プレイ")
			last_reported_score = data.get("last_reported_score", 0)
			last_actual_score = data.get("last_actual_score", 0)
			score_history = data.get("score_history", [])
			accumulated_votes = data.get("accumulated_votes", {})

func unlock_achievement(_id: String, _title: String):
	print("Achievement Unlocked: ", _title)
