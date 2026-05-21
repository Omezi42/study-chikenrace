class_name BackendManager
extends Node

const SUPABASE_URL = "https://lhzxandvkgnafshdtrov.supabase.co/rest/v1/scores"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxoenhhbmR2a2duYWZzaGR0cm92Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NzEzMzMsImV4cCI6MjA5NDI0NzMzM30.dof6q-gDq9qJE32MxWfTD76PBvdgAr6X3EQ1do291sk"

signal scores_loaded(scores_array: Array)

var http_request: HTTPRequest

# プレイヤーがライバルに送ったいいね！の投票履歴
# キー: "ライバル名" -> true
var _voted_rivals: Dictionary = {}

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func load_daily_scores():
	clear_daily_votes()
	if Global.current_play_mode == 1:
		call_deferred("_simulate_mock")
		return
		
	var headers = ["apikey: " + SUPABASE_KEY, "Authorization: Bearer " + SUPABASE_KEY]
	var url = SUPABASE_URL + "?select=name,score&order=score.desc&limit=20"
	http_request.request(url, headers)

func submit_score(p_name: String, data_dict: Dictionary):
	if Global.current_play_mode == 1: return
	
	var total = data_dict.get("score", 0)
	
	var data = { "name": p_name, "score": total }
	var headers = [
		"apikey: " + SUPABASE_KEY, "Authorization: Bearer " + SUPABASE_KEY,
		"Content-Type: application/json", "Prefer: return=minimal"
	]
	var req = HTTPRequest.new()
	add_child(req)
	req.request(SUPABASE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(data))

var current_scores = []

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			current_scores = data
			scores_loaded.emit(current_scores)
			return
	_simulate_mock()

func _simulate_mock():
	var mocks = []
	var day = Global.play_count + 1 # 1〜7
	var day_mult = 1.0 + 0.1 * (day - 1)
	
	# 1. 慎重な優等生 (毎日+50前後を堅実に稼ぐ)
	var steady_score = int(floor(float(day * 50) * day_mult))
	mocks.append({"name": "慎重な優等生", "score": steady_score})
	
	# 2. ギャンブラー (特定日は0点になるが、それ以外は一気に稼ぐ)
	var g_score = 0
	for d in range(1, day + 1):
		var d_mult = 1.0 + 0.1 * (d - 1)
		# Day3, Day6はバーストしてその日の稼ぎが0になる想定
		if d != 3 and d != 6:
			g_score += int(floor(60.0 * d_mult))
	mocks.append({"name": "ギャンブラー", "score": g_score})
	
	# 3. ブラフの達人 (少し強引に稼ぐ)
	var b_score = int(floor(float(day * 40) * day_mult))
	mocks.append({"name": "ブラフの達人", "score": b_score})
	
	current_scores = mocks
	scores_loaded.emit(mocks)

func get_current_rankings() -> Array:
	var rankings = []
	for s in current_scores:
		rankings.append({"name": s["name"], "score": s["score"]})
	return rankings

func vote_rival(rival_name: String, _dummy: int = -1) -> void:
	var key = "%s" % [rival_name]
	_voted_rivals[key] = true
	print("Voted for rival: ", key)
	
	# Globalの永続化辞書にも保存 (Dayベース)
	var g_key = "day_%d_%s" % [Global.play_count + 1, rival_name]
	Global.accumulated_votes[g_key] = true
	Global.save_data()

func has_voted_rival(rival_name: String, _dummy: int = -1) -> bool:
	var key = "%s" % [rival_name]
	if _voted_rivals.get(key, false): return true
	
	var g_key = "day_%d_%s" % [Global.play_count + 1, rival_name]
	return Global.accumulated_votes.get(g_key, false)

func clear_daily_votes() -> void:
	_voted_rivals.clear()
	print("Daily votes cleared.")

func get_daily_vote_count() -> int:
	return _voted_rivals.size()

func get_all_player_daily_scores() -> Dictionary:
	var result = {}
	var day = Global.play_count
	if day <= 0: day = 1
	
	var steady_days = []
	for d in range(1, day + 1):
		steady_days.append({"day": d, "total": d * 50})
	result["慎重な優等生"] = steady_days
	
	var gambler_days = []
	for d in range(1, day + 1):
		var s = 60 if d != 3 and d != 6 else 0
		gambler_days.append({"day": d, "total": s})
	result["ギャンブラー"] = gambler_days
	
	var bluffer_days = []
	for d in range(1, day + 1):
		bluffer_days.append({"day": d, "total": 40})
	result["ブラフの達人"] = bluffer_days
	
	var player_days = []
	for entry in Global.score_history:
		player_days.append({"day": entry.get("day", 0), "total": entry.get("total", 0)})
	if player_days.size() > 0:
		result[Global.player_name] = player_days
	
	return result
