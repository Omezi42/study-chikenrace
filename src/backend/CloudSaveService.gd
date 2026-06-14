class_name CloudSaveService
extends RefCounted

var bm: Node

func _init(backend_manager: Node) -> void:
	bm = backend_manager

func save_cloud_data(data_dict: Dictionary) -> void:
	if bm.auth_token == "" or bm.logged_in_uuid == "":
		bm.save_completed.emit(false)
		return

	var url = bm._get_supabase_url() + "/rest/v1/saves"
	var body = {
		"user_id": bm.logged_in_uuid,
		"data": data_dict
	}

	var req = bm._get_available_request()
	if req == null:
		bm.save_completed.emit(false)
		return

	bm._pool_callbacks[req] = func(result: int, response_code: int, headers: PackedStringArray, body_data: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
			bm.save_completed.emit(true)
		else:
			bm.save_completed.emit(false)
			if bm.is_inside_tree():
				DeskTheme.show_toast(bm, "クラウドセーブ失敗。ローカルに保存します。")

	var custom_headers = bm._get_headers(true)
	custom_headers.append("Prefer: resolution=merge-duplicates")
	req.request(url, custom_headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func load_cloud_data() -> void:
	if bm.auth_token == "" or bm.logged_in_uuid == "":
		bm.load_completed.emit(false, {})
		return

	Global.show_loading("クラウドロード中...")
	var url = bm._get_supabase_url() + "/rest/v1/saves?user_id=eq." + bm.logged_in_uuid + "&select=data"

	bm._send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		Global.hide_loading()
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					var save_entry = data[0]
					if save_entry is Dictionary and save_entry.has("data"):
						var cloud_data = save_entry["data"]
						if cloud_data is Dictionary:
							var cloud_time = float(cloud_data.get("last_updated_at", 0.0))
							var local_time = float(Global.last_updated_at)
							if local_time > cloud_time:
								if bm.is_inside_tree():
									DeskTheme.show_toast(bm, "ローカルのほうが新しいため、クラウドを同期中...", 2.0, DeskTheme.COLOR_GREEN)
								var sync_data = Global.get_save_data_dict_for_sync()
								save_cloud_data(sync_data.duplicate(true))
								bm.load_completed.emit(true, sync_data.duplicate(true))
								return
						bm.load_completed.emit(true, cloud_data)
						return
			bm.load_completed.emit(false, {})
		else:
			bm.load_completed.emit(false, {})
			if bm.is_inside_tree():
				DeskTheme.show_toast(bm, "クラウドロード失敗。ローカルデータを使用します。")
	)

func upload_daily_record(day_idx: int, score: int, record: Dictionary) -> void:
	if bm.auth_token == "" or bm.logged_in_uuid == "":
		return

	var safe_score = clampi(score, 0, 9999)
	var url = bm._get_supabase_url() + "/rest/v1/daily_scores"
	var body = {
		"user_id": bm.logged_in_uuid,
		"username": Global.player_name,
		"day_idx": day_idx,
		"score": safe_score,
		"record": record,
		"season": Global.current_season
	}

	bm._send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
			if bm.is_inside_tree():
				DeskTheme.show_toast(bm, "今日のスコアの保存に失敗しました。")
	)

func fetch_daily_records(day_idx: int) -> void:
	var url = bm._get_supabase_url() + "/rest/v1/daily_scores?day_idx=eq." + str(day_idx) + "&season=eq." + str(Global.current_season) + "&select=username,score,record&order=score.desc&limit=6"
	if bm.logged_in_uuid != "":
		url += "&user_id=neq." + bm.logged_in_uuid

	bm._send_request(url, HTTPClient.METHOD_GET, "", false, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					bm.daily_scores_loaded.emit(true, data)
					return
			bm.daily_scores_loaded.emit(false, [])
		else:
			bm.daily_scores_loaded.emit(false, [])
	)

func fetch_participants_deviation(participants: Array) -> void:
	if bm.auth_token == "" or bm.logged_in_uuid == "":
		return
		
	var uuids = []
	for p in participants:
		var uid = p.get("user_id", "")
		if uid != "" and uid != bm.logged_in_uuid:
			uuids.append(uid)
			
	if uuids.is_empty():
		return
		
	var uuid_str = ""
	for i in range(uuids.size()):
		if i > 0:
			uuid_str += ","
		uuid_str += uuids[i]
		
	var url = bm._get_supabase_url() + "/rest/v1/saves?user_id=in.(" + uuid_str + ")"
	bm._send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var saves_arr = json.get_data()
				if saves_arr is Array:
					for save in saves_arr:
						var uid = save.get("user_id", "")
						var data = save.get("data", {})
						if typeof(data) == TYPE_STRING:
							var p_json = JSON.new()
							if p_json.parse(data) == OK:
								data = p_json.get_data()
						var dev_val = 50.0
						if data is Dictionary and data.has("deviation_value"):
							dev_val = float(data["deviation_value"])
						
						for opp_id in Global.opponent_profiles.keys():
							if Global.opponent_profiles[opp_id].get("id", "") == uid or opp_id == uid:
								Global.opponent_profiles[opp_id]["deviation"] = dev_val
	)

func upload_random_match_result(score: int, rank: int, deviation: float, league: String) -> void:
	if bm.auth_token == "" or bm.logged_in_uuid == "":
		return
	var url = bm._get_supabase_url() + "/rest/v1/random_match_ratings"
	var body = {
		"user_id": bm.logged_in_uuid,
		"score": score,
		"rank": rank,
		"deviation": deviation,
		"league": league
	}
	bm._send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		pass
	)
