class_name MatchmakingService
extends RefCounted

var bm: Node

func _init(backend_manager: Node) -> void:
	bm = backend_manager

func create_friend_room() -> void:
	Global.show_loading("ルーム作成中...")
	bm.is_mock_room = false
	var code = str(randi_range(1000, 9999))
	var host_name = Global.player_name if Global.player_name != "" else "あなた"

	if bm.auth_token == "" or bm.logged_in_uuid == "":
		_enable_mock_room(code, host_name)
		Global.hide_loading()
		bm.room_created.emit(true, code)
		return

	var url = bm._get_supabase_url() + "/rest/v1/friend_rooms"
	var body = {
		"room_code": code,
		"status": "waiting",
		"current_day": 1,
		"participants": [{"user_id": bm.logged_in_uuid, "username": host_name}],
		"host_id": bm.logged_in_uuid
	}

	bm._send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		Global.hide_loading()
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
			bm.room_created.emit(true, code)
		else:
			_enable_mock_room(code, host_name)
			bm.room_created.emit(true, code)
			if bm.is_inside_tree() and ClassDB.class_exists("DeskTheme"):
				var DeskTheme = ClassDB.instantiate("DeskTheme")
				if DeskTheme and DeskTheme.has_method("show_toast"):
					DeskTheme.show_toast(bm, "接続失敗。オフライン(CPU戦)で開始します。")
	)

func _enable_mock_room(code: String, host_name: String) -> void:
	bm.is_mock_room = true
	bm.mock_room_code = code
	bm.mock_room_status = "waiting"
	bm.mock_current_day = 1
	bm.mock_participants = [{"user_id": "player", "username": host_name}]
	bm.mock_moves.clear()

	var timer = bm.get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		if bm.is_mock_room and bm.mock_room_status == "waiting":
			bm.mock_participants.append({"user_id": "cpu_sato", "username": "佐藤くん (CPU)"})
			bm.mock_participants.append({"user_id": "cpu_suzuki", "username": "鈴木さん (CPU)"})
	)

func join_friend_room(room_code: String) -> void:
	Global.show_loading("ルーム参加中...")
	bm.is_mock_room = false
	var user_name = Global.player_name if Global.player_name != "" else "あなた"

	if bm.auth_token == "" or bm.logged_in_uuid == "":
		_join_mock_room(room_code, user_name)
		Global.hide_loading()
		return

	var rpc_url = bm._get_supabase_url() + "/rest/v1/rpc/join_friend_room_safe"
	var rpc_body = {
		"p_room_code": room_code,
		"p_user_id": bm.logged_in_uuid,
		"p_username": user_name
	}

	bm._send_request(rpc_url, HTTPClient.METHOD_POST, JSON.stringify(rpc_body), true, func(result, response_code, headers, body_data):
		Global.hide_loading()
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					if data.has("error"):
						var error_code = data["error"]
						if error_code == "room_full":
							bm.room_joined.emit(false, [])
						else:
							_join_mock_room(room_code, user_name)
					elif data.has("participants"):
						var parts = data["participants"]
						if parts is Array:
							bm.room_joined.emit(true, parts)
							return
		_join_mock_room(room_code, user_name)
		if bm.is_inside_tree() and ClassDB.class_exists("DeskTheme"):
			var DeskTheme = ClassDB.instantiate("DeskTheme")
			if DeskTheme and DeskTheme.has_method("show_toast"):
				DeskTheme.show_toast(bm, "接続失敗。オフライン(CPU戦)として参加します。")
	)

func _join_mock_room(room_code: String, user_name: String) -> void:
	bm.is_mock_room = true
	bm.mock_room_code = room_code
	bm.mock_room_status = "waiting"
	bm.mock_current_day = 1
	bm.mock_participants = [
		{"user_id": "cpu_sato", "username": "ホスト友達 (CPU)"},
		{"user_id": "player", "username": user_name},
		{"user_id": "cpu_suzuki", "username": "鈴木さん (CPU)"}
	]
	bm.mock_moves.clear()
	bm.room_joined.emit(true, bm.mock_participants)

func start_friend_game(room_code: String) -> void:
	if bm.is_mock_room:
		bm.mock_room_status = "playing"
		if bm.mock_participants.size() < 4:
			bm.mock_participants.append({"user_id": "cpu_takahashi", "username": "高橋くん (CPU)"})
		return

	var url = bm._get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	bm._send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					var room = data[0]
					var parts = room.get("participants", [])

					var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi", "cpu_tanaka"]
					var slot_idx = 0
					while parts.size() < 4 and slot_idx < slots.size():
						var cpu_id = slots[slot_idx]
						var cpu_profile = AIManager.CPU_OPPONENTS.get(cpu_id, {"name": "CPU"})
						parts.append({"user_id": cpu_id, "username": cpu_profile["name"] + " (CPU)"})
						slot_idx += 1

					var patch_body = {
						"status": "playing",
						"participants": parts
					}
					bm._send_request(url, HTTPClient.METHOD_PATCH, JSON.stringify(patch_body), true, func(r_res, r_code, r_headers, r_body):
						pass 
					)
	)

func upload_friend_move(room_code: String, day_idx: int, move_data: Dictionary) -> void:
	var body = bm._build_friend_move_payload(room_code, day_idx, move_data)
	var nonce = body.get("client_nonce", "")
	
	if nonce != "":
		if bm._sent_nonces.get(nonce, "") == "success":
			return
		elif bm._sent_nonces.get(nonce, "") == "sending":
			return
		bm._sent_nonces[nonce] = "sending"

	if bm.is_mock_room:
		if not bm.mock_moves.has(day_idx):
			bm.mock_moves[day_idx] = []

		var player_move = null
		for m in bm.mock_moves[day_idx]:
			if m.get("user_id") == "player":
				player_move = m
				break

		var my_move = {
			"room_code": room_code,
			"user_id": "player",
			"username": Global.player_name if Global.player_name != "" else "Player",
			"day_idx": day_idx,
			"actual_score": body.get("actual_score", 0),
			"declared_score": body.get("declared_score", 0),
			"hours_history": body.get("hours_history", []),
			"doubts_made": body.get("doubts_made", []),
			"doubts_submitted": body.get("doubts_submitted", false),
			"phase": str(body.get("phase", "")),
			"revision": bm.mock_last_sync_revision + 1,
			"submitted_at": body.get("submitted_at", ""),
			"client_nonce": nonce
		}

		if player_move:
			player_move.clear()
			for k in my_move.keys():
				player_move[k] = my_move[k]
		else:
			bm.mock_moves[day_idx].append(my_move)

		bm.mock_last_sync_revision += 1
		if ClassDB.class_exists("MockDataGenerator"):
			var MockDataGenerator = ClassDB.instantiate("MockDataGenerator")
			if MockDataGenerator and MockDataGenerator.has_method("simulate_friend_room_cpus"):
				MockDataGenerator.simulate_friend_room_cpus(
					room_code, day_idx, bm.mock_moves, bm.mock_participants, my_move, Global.opponent_profiles
				)
		if nonce != "":
			bm._sent_nonces[nonce] = "success"
		return

	var url = bm._get_supabase_url() + "/rest/v1/friend_room_moves"
	var req = bm._get_available_request()
	if req == null:
		if nonce != "":
			bm._sent_nonces[nonce] = "failed"
		return
		
	bm._pool_callbacks[req] = func(result: int, response_code: int, headers: PackedStringArray, body_data: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
			if nonce != "":
				bm._sent_nonces[nonce] = "success"
		else:
			if nonce != "":
				bm._sent_nonces[nonce] = "failed"
			if bm.is_inside_tree() and ClassDB.class_exists("DeskTheme"):
				var DeskTheme = ClassDB.instantiate("DeskTheme")
				if DeskTheme and DeskTheme.has_method("show_toast"):
					DeskTheme.show_toast(bm, "Failed to send friend-room data.")

	var custom_headers = bm._get_headers(true)
	custom_headers.append("Prefer: resolution=merge-duplicates")
	req.request(url, custom_headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func poll_room_status(room_code: String) -> void:
	if bm.is_mock_room:
		bm.cached_room_status = bm.mock_room_status
		bm.cached_current_day = bm.mock_current_day
		bm.cached_participants = bm.mock_participants
		bm.cached_last_sync_revision = bm.mock_last_sync_revision
		bm.room_polled.emit(bm.mock_room_status, bm.mock_current_day, bm.mock_participants)
		return
	var url = bm._get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	bm._send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			bm.consecutive_network_errors = 0
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					var room = data[0]
					var status = room.get("status", "waiting")
					var day = room.get("current_day", 1)
					var parts = room.get("participants", [])
					var last_revision = int(room.get("last_sync_revision", 0))
					
					bm.cached_room_status = status
					bm.cached_current_day = day
					bm.cached_participants = parts
					bm.cached_last_sync_revision = last_revision
					bm.cached_host_id = room.get("host_id", "")
					
					bm.mock_participants = parts
					bm.mock_room_status = status
					bm.mock_current_day = day
					bm.mock_last_sync_revision = last_revision
					
					if Global.game_mode == Constants.MODE_RANDOM and status == "waiting":
						if parts.size() >= 4:
							var host_id = room.get("host_id", "")
							if host_id == bm.logged_in_uuid:
								start_friend_game(room_code)
								
					bm.room_polled.emit(status, day, parts)
					return
			bm.room_polled.emit("waiting", 1, [])
		else:
			bm.consecutive_network_errors += 1
			if bm.consecutive_network_errors >= 3:
				bm.connection_lost.emit()
			bm.room_polled.emit(bm.mock_room_status, bm.mock_current_day, bm.mock_participants)
	)

func poll_day_moves(room_code: String, day_idx: int) -> void:
	if bm.is_mock_room:
		var day_data = bm.mock_moves.get(day_idx, [])
		var normalized_day_data = []
		for m in day_data:
			normalized_day_data.append(bm._normalize_score_payload(m))
		bm.cached_day_moves[day_idx] = normalized_day_data
		bm.day_moves_polled.emit(true, normalized_day_data)
		return
	var url = bm._get_supabase_url() + "/rest/v1/friend_room_moves?room_code=eq." + room_code + "&day_idx=eq." + str(day_idx)
	bm._send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			bm.consecutive_network_errors = 0
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array:
					var normalized_moves = []
					for m in data:
						normalized_moves.append(bm._normalize_score_payload(m))
					bm.cached_day_moves[day_idx] = normalized_moves
					bm.day_moves_polled.emit(true, normalized_moves)
					return
			bm.day_moves_polled.emit(false, [])
		else:
			bm.consecutive_network_errors += 1
			if bm.consecutive_network_errors >= 3:
				bm.connection_lost.emit()
			var day_data = bm.mock_moves.get(day_idx, [])
			var normalized_day_data = []
			for m in day_data:
				normalized_day_data.append(bm._normalize_score_payload(m))
			bm.cached_day_moves[day_idx] = normalized_day_data
			bm.day_moves_polled.emit(true, normalized_day_data)
	)

func advance_friend_room_day(room_code: String, next_day: int) -> void:
	if bm.is_mock_room:
		bm.mock_current_day = next_day
		bm.mock_last_sync_revision += 1
		bm.cached_current_day = next_day
		bm.cached_last_sync_revision = bm.mock_last_sync_revision
		return
	var url = bm._get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	var body = {
		"current_day": next_day,
		"last_sync_revision": bm.mock_last_sync_revision + 1
	}
	bm._send_request(url, HTTPClient.METHOD_PATCH, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 204):
			bm.mock_current_day = next_day
			bm.mock_last_sync_revision += 1
			bm.cached_current_day = next_day
			bm.cached_last_sync_revision = bm.mock_last_sync_revision
	)

func join_or_create_random_match() -> void:
	bm.is_mock_room = false
	var user_name = Global.player_name if Global.player_name != "" else "あなた"
	
	if bm.auth_token == "" or bm.logged_in_uuid == "":
		bm.random_match_status_updated.emit("error", "オンライン対戦を行うにはログインが必要です。")
		return

	bm.random_match_status_updated.emit("searching", "対戦ルームを検索中...")
	
	var league = Global.get_deviation_league(Global.deviation_value)
	var search_prefix = "RAND_" + league + "_"
	
	var url = bm._get_supabase_url() + "/rest/v1/friend_rooms?status=eq.waiting&room_code=like." + search_prefix + "%"
	bm._send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var rooms = json.get_data()
				if rooms is Array and rooms.size() > 0:
					var target_room = rooms[0]
					var room_code = target_room.get("room_code", "")
					bm.random_match_status_updated.emit("joining", "対戦ルームにジョイン中...")
					
					var rpc_url = bm._get_supabase_url() + "/rest/v1/rpc/join_friend_room_safe"
					var rpc_body = {
						"p_room_code": room_code,
						"p_user_id": bm.logged_in_uuid,
						"p_username": user_name
					}
					bm._send_request(rpc_url, HTTPClient.METHOD_POST, JSON.stringify(rpc_body), true, func(r_res, r_code, r_headers, r_body):
						if r_res == HTTPRequest.RESULT_SUCCESS and r_code == 200:
							var r_json = JSON.new()
							if r_json.parse(r_body.get_string_from_utf8()) == OK:
								var data = r_json.get_data()
								if data is Dictionary and not data.has("error"):
									var parts = data.get("participants", [])
									Global.friend_room_code = room_code
									Global.friend_current_day = 1
									Global.friend_match_history.clear()
									bm.random_match_status_updated.emit("matched", "マッチング成立！")
									bm.room_joined.emit(true, parts)
									return
						_create_random_match_room(user_name)
					)
					return
		
		_create_random_match_room(user_name)
	)

func _create_random_match_room(user_name: String) -> void:
	bm.random_match_status_updated.emit("creating", "対戦ルームを作成中...")
	
	var league = Global.get_deviation_league(Global.deviation_value)
	var room_code = "RAND_" + league + "_" + str(randi_range(100000, 999999))
	var url = bm._get_supabase_url() + "/rest/v1/friend_rooms"
	var body = {
		"room_code": room_code,
		"status": "waiting",
		"current_day": 1,
		"participants": [{"user_id": bm.logged_in_uuid, "username": user_name}],
		"host_id": bm.logged_in_uuid
	}
	
	bm._send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
			Global.friend_room_code = room_code
			Global.friend_current_day = 1
			Global.friend_match_history.clear()
			bm.random_match_status_updated.emit("waiting_for_players", "他のプレイヤーを待っています...")
			bm.room_created.emit(true, room_code)
		else:
			var err_body = body_data.get_string_from_utf8() if body_data is PackedByteArray else ""
			push_error("[BackendManager] Create room failed! result: %d, code: %d, body: %s" % [result, response_code, err_body])
			bm.random_match_status_updated.emit("error", "対戦ルームの作成に失敗しました。")
	)

func generate_simulated_ghosts(day_idx: int) -> Array:
	var ghosts = []
	var cpu_names = ["慎重な優等生", "エナドリ狂人", "ブラフの達人", "逆転狙いの浪人生"]
	cpu_names.shuffle()

	for i in range(3):
		var cpu_name = cpu_names[i]
		var simulated_score = 0
		var hours_history = []

		var bursted_count = 0
		for h in range(3):
			var draws = randi_range(3, 8)
			var bursted = randf() < 0.15 + (draws * 0.08)
			var hour_score = 0
			if not bursted:
				hour_score = draws * randi_range(2, 4)
			else:
				bursted_count += 1

			simulated_score += hour_score
			hours_history.append({
				"draws": draws,
				"used_items": [],
				"bursted": bursted,
				"score": hour_score
			})

		var declared_score = simulated_score
		if randf() < 0.6:
			var bluff_amount = randi_range(5, 20)
			declared_score += bluff_amount

		ghosts.append({
			"username": cpu_name,
			"score": simulated_score,
			"record": {
				"actual_score": simulated_score,
				"declared_score": declared_score,
				"hours": hours_history,
				"doubts_made": [],
				"doubts_received": [],
				"is_doubt_exposed": false,
				"auto_exposed": false
			}
		})
	return ghosts

func leave_or_delete_random_room(room_code: String) -> void:
	if bm.auth_token == "" or bm.logged_in_uuid == "":
		return
	
	# If we are the host of this room, we delete it.
	# RLS policy restricts DELETE permission to the host of the room.
	var url = bm._get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	bm._send_request(url, HTTPClient.METHOD_DELETE, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 204):
			print("[BackendManager] Successfully deleted canceled room: ", room_code)
		else:
			print("[BackendManager] Failed to delete room on cancel, HTTP status: ", response_code)
	)
