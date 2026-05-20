class_name BackendManager
extends Node

const SUPABASE_URL = "https://lhzxandvkgnafshdtrov.supabase.co/rest/v1/scores"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxoenhhbmR2a2duYWZzaGR0cm92Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NzEzMzMsImV4cCI6MjA5NDI0NzMzM30.dof6q-gDq9qJE32MxWfTD76PBvdgAr6X3EQ1do291sk"

signal scores_loaded(scores_array: Array)

var http_request: HTTPRequest

# プレイヤーがライバルに送ったいいね！の投票履歴
# キー: "ライバル名_教科インデックス" -> true
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
	var url = SUPABASE_URL + "?select=name,score,subjects_json&order=score.desc&limit=20"
	http_request.request(url, headers)

func submit_score(p_name: String, subject_dict: Dictionary):
	if Global.current_play_mode == 1: return
	
	var total = 0
	var str_dict = {}
	for k in subject_dict:
		total += subject_dict[k]
		str_dict[str(k)] = subject_dict[k]
	
	var data = { "name": p_name, "score": total, "subjects_json": JSON.stringify(str_dict) }
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
			for record in current_scores:
				if record.has("subjects_json") and record["subjects_json"]:
					var sj = JSON.new()
					if sj.parse(record["subjects_json"]) == OK: record["subjects"] = sj.get_data()
			scores_loaded.emit(current_scores)
			return
	_simulate_mock()

func _simulate_mock():
	var mocks = []
	var day = Global.play_count + 1 # 1〜7
	
	# 1. 慎重な優等生 (毎日+10前後を堅実に稼ぐ)
	var steady_subjs = {}
	var steady_total = 0
	for i in range(5):
		var s_score = day * 10
		steady_subjs[str(i)] = s_score
		steady_total += s_score
	mocks.append({"name": "慎重な優等生", "score": steady_total, "subjects": steady_subjs})
	
	# 2. ギャンブラー (特定2教科に特化して+30稼ぐが、たまにバーストして0になる)
	var gambler_subjs = {"1": 0, "2": 0}
	var g_total = 0
	for d in range(1, day + 1):
		# Day3, Day6はバーストしてその日の稼ぎが0になる想定
		if d != 3: gambler_subjs["1"] += 30
		if d != 6: gambler_subjs["2"] += 30
	g_total = gambler_subjs["1"] + gambler_subjs["2"]
	mocks.append({"name": "ギャンブラー", "score": g_total, "subjects": gambler_subjs})
	
	# 3. ブラフの達人 (3教科を少し強引に稼ぐ)
	var bluffer_subjs = {"0": day * 15, "3": day * 20, "4": day * 5}
	var b_total = bluffer_subjs["0"] + bluffer_subjs["3"] + bluffer_subjs["4"]
	mocks.append({"name": "ブラフの達人", "score": b_total, "subjects": bluffer_subjs})
	
	current_scores = mocks
	scores_loaded.emit(mocks)

func get_top_player_for_subject(subject: int) -> Dictionary:
	var best_name = "誰もいない"
	var best_score = 0
	var s_str = str(subject)
	for s in current_scores:
		if s.has("subjects") and s["subjects"].has(s_str):
			var val = int(s["subjects"][s_str])
			if val > best_score:
				best_score = val; best_name = s["name"]
				
	# プレイヤー自身の前日スコアと比較
	if Global.last_reported_scores.has(subject):
		var p_val = Global.last_reported_scores[subject]
		# 引き分けはプレイヤー優先（後出し有利）
		if p_val >= best_score and p_val > 0:
			best_score = p_val
			best_name = Global.player_name
			
	return {"name": best_name, "score": best_score}

func load_scores():
	load_daily_scores()

func get_subject_top_scores() -> Dictionary:
	var result = {}
	for s in range(5):
		var top = get_top_player_for_subject(s)
		result[s] = {"name": top["name"] if top["score"] > 0 else "なし", "score": top["score"]}
	return result

func get_timeline_feeds() -> Array:
	var feeds = []
	var day = Global.play_count + 1
	
	# 1. 慎重な優等生 (正直に報告)
	var steady_actuals = {}
	var steady_reports = {}
	for i in range(5):
		var s_score = day * 10
		steady_actuals[str(i)] = s_score
		# 正直者なので、実際スコアと同じスコアを報告
		steady_reports[str(i)] = s_score
	feeds.append({
		"name": "慎重な優等生",
		"scores": steady_reports,
		"actual_scores": steady_actuals
	})
	
	# 2. ギャンブラー (Day3, Day6にバーストして 0点 なのに 20点上限で盛る！)
	var gambler_actuals = {"1": 0, "2": 0}
	var gambler_reports = {"1": 0, "2": 0}
	for d in range(1, day + 1):
		if d != 3: gambler_actuals["1"] += 30
		if d != 6: gambler_actuals["2"] += 30
		
	# 報告スコア：Day3, Day6などでバーストして本当は 0点 なのに 15〜20点 と盛って報告！
	gambler_reports["1"] = gambler_actuals["1"]
	gambler_reports["2"] = gambler_actuals["2"]
	if day >= 3:
		# Day3でバーストした「1」(数学) を18点と盛って嘘をつく！
		gambler_reports["1"] = max(gambler_reports["1"], 18)
	if day >= 6:
		# Day6でバーストした「2」(英語) を20点と盛って嘘をつく！
		gambler_reports["2"] = max(gambler_reports["2"], 20)
		
	# 他の教科（0, 3, 4）はCPU2は勉強していないので 0点
	for i in ["0", "3", "4"]:
		gambler_actuals[i] = 0
		gambler_reports[i] = 0
		
	feeds.append({
		"name": "ギャンブラー",
		"scores": gambler_reports,
		"actual_scores": gambler_actuals
	})
	
	# 3. ブラフの達人 (常に嘘を盛るか、過少報告で裏をかく！)
	var bluffer_actuals = {"0": day * 15, "3": day * 20, "4": day * 5}
	var bluffer_reports = {}
	for i in ["0", "3", "4"]:
		var act = bluffer_actuals[i]
		# ブラフの達人なので、スコアを盛る(20点上限)
		bluffer_reports[i] = min(act + 5, 20)
	# 他の教科（1, 2）は 0点
	for i in ["1", "2"]:
		bluffer_actuals[i] = 0
		bluffer_reports[i] = 0
		
	feeds.append({
		"name": "ブラフの達人",
		"scores": bluffer_reports,
		"actual_scores": bluffer_actuals
	})
	
	return feeds

func vote_rival(rival_name: String, _subject: int = -1) -> void:
	var key = "%s" % [rival_name]
	_voted_rivals[key] = true
	print("Voted for rival: ", key)
	
	# Globalの永続化辞書にも保存 (Dayベース)
	var g_key = "day_%d_%s" % [Global.play_count + 1, rival_name]
	Global.accumulated_votes[g_key] = true
	Global.save_data()

func has_voted_rival(rival_name: String, _subject: int = -1) -> bool:
	# まずローカル（本日分）でチェック
	var key = "%s" % [rival_name]
	if _voted_rivals.get(key, false): return true
	
	# 次にGlobalの永続データでチェック
	var g_key = "day_%d_%s" % [Global.play_count + 1, rival_name]
	return Global.accumulated_votes.get(g_key, false)

func clear_daily_votes() -> void:
	_voted_rivals.clear()
	print("Daily votes cleared.")

func get_rival_history(rival_name: String) -> Array:
	var history = []
	var day = Global.play_count + 1
	for d in range(1, day + 1):
		var daily_score = 0
		if rival_name == "慎重な優等生":
			daily_score = 50
		elif rival_name == "ギャンブラー":
			daily_score = 0 if (d == 3 or d == 6) else 60
		elif rival_name == "ブラフの達人":
			daily_score = 40
		else:
			daily_score = randi_range(10, 50)
		history.append({"day": d, "score": daily_score})
	return history

## 全プレイヤーの日別・教科別スコアを返す（スタチキ「学習分析」タブ用）
## 戻り値形式: { "プレイヤー名": [ { "day": 1, "subjects": {0: 10, 1: 5, ...}, "total": 50 }, ... ] }
func get_all_player_daily_scores() -> Dictionary:
	var result = {}
	var day = Global.play_count
	if day <= 0: day = 1
	
	# --- CPUモック: 慎重な優等生 ---
	var steady_days = []
	for d in range(1, day + 1):
		var subjs = {}
		for i in range(5):
			subjs[i] = d * 10  # 累計ではなくその日の報告スコア=10点/日
		var total = 0
		for v in subjs.values(): total += v
		steady_days.append({"day": d, "subjects": subjs, "total": total})
	result["慎重な優等生"] = steady_days
	
	# --- CPUモック: ギャンブラー ---
	var gambler_days = []
	for d in range(1, day + 1):
		var subjs = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
		if d != 3: subjs[1] = 30  # 数学
		if d != 6: subjs[2] = 30  # 英語
		var total = 0
		for v in subjs.values(): total += v
		gambler_days.append({"day": d, "subjects": subjs, "total": total})
	result["ギャンブラー"] = gambler_days
	
	# --- CPUモック: ブラフの達人 ---
	var bluffer_days = []
	for d in range(1, day + 1):
		var subjs = {0: 15, 1: 0, 2: 0, 3: 20, 4: 5}  # その日の報告スコア
		var total = 0
		for v in subjs.values(): total += v
		bluffer_days.append({"day": d, "subjects": subjs, "total": total})
	result["ブラフの達人"] = bluffer_days
	
	# --- プレイヤー自身（Global.score_historyから復元） ---
	var player_days = []
	for entry in Global.score_history:
		var subjs = {}
		for k in entry.get("subjects", {}):
			subjs[int(k)] = entry["subjects"][k]
		player_days.append({"day": entry.get("day", 0), "subjects": subjs, "total": entry.get("total", 0)})
	if player_days.size() > 0:
		result[Global.player_name] = player_days
	
	return result

func get_daily_vote_count() -> int:
	return _voted_rivals.size()


