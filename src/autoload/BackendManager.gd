extends Node

var _supabase_url: String = ""
var _supabase_key: String = ""

# ─────────────────────────────────────────────────────────
# HTTP Object Pool（WebGL向けメモリ最適化）
# 毎回 HTTPRequest.new() / queue_free() するのではなく、
# 起動時に生成したプール内のノードを使い回し、GCスパイクを防ぐ。
# ─────────────────────────────────────────────────────────
const POOL_SIZE = 6
var _http_pool: Array[HTTPRequest] = []
var _pool_callbacks: Dictionary = {}   # HTTPRequest インスタンス -> Callable

func _init() -> void:
	_supabase_url = OS.get_environment("SUPABASE_URL")
	if _supabase_url == "":
		_supabase_url = ProjectSettings.get_setting("backend/supabase_url", "https://lhzxandvkgnafshdtrov.supabase.co")
		
	_supabase_key = OS.get_environment("SUPABASE_KEY")
	if _supabase_key == "":
		_supabase_key = ProjectSettings.get_setting("backend/supabase_key", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxoenhhbmR2a2duYWZzaGR0cm92Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NzEzMzMsImV4cCI6MjA5NDI0NzMzM30.dof6q-gDq9qJE32MxWfTD76PBvdgAr6X3EQ1do291sk")

func _ready() -> void:
	# プール内にHTTPRequestノードを事前生成する
	for i in range(POOL_SIZE):
		var req = HTTPRequest.new()
		req.name = "HttpPoolNode_%d" % i
		add_child(req)
		req.request_completed.connect(_on_pool_request_completed.bind(req))
		_http_pool.append(req)

# プール内で接続待機中（アイドル）のノードを取得する
func _get_available_request() -> HTTPRequest:
	for req in _http_pool:
		if req.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			return req
	# プールが枯渇した場合（全ノード使用中）は一時的なノードを生成する
	# 通常の3秒ポーリングではこのパスには到達しない
	var fallback = HTTPRequest.new()
	add_child(fallback)
	fallback.request_completed.connect(_on_pool_request_completed.bind(fallback))
	_http_pool.append(fallback)
	push_warning("[BackendManager] HTTP pool exhausted, growing pool to %d." % _http_pool.size())
	return fallback

func _on_pool_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, req: HTTPRequest) -> void:
	if _pool_callbacks.has(req):
		var cb: Callable = _pool_callbacks[req]
		_pool_callbacks.erase(req)
		cb.call(result, response_code, headers, body)

func _get_supabase_url() -> String:
	return _supabase_url

func _get_supabase_key() -> String:
	return _supabase_key

signal auth_completed(success: bool, error_message: String)
signal save_completed(success: bool)
signal load_completed(success: bool, data: Dictionary)
signal daily_scores_loaded(success: bool, scores_array: Array)

signal room_created(success: bool, room_code: String)
signal room_joined(success: bool, participants: Array)
signal room_polled(status: String, current_day: int, participants: Array)
signal day_moves_polled(success: bool, moves: Array)

var logged_in_uuid: String = ""
var auth_token: String = ""

# Offline/Mock state for friend rooms
var is_mock_room: bool = false
var mock_room_code: String = ""
var mock_participants: Array = []
var mock_room_status: String = "waiting"
var mock_current_day: int = 1
var mock_moves: Dictionary = {} # DayIdx -> Array of moves

# API Headers
func _get_headers(auth_required: bool = false) -> Array[String]:
	var headers: Array[String] = [
		"apikey: " + _get_supabase_key(),
		"Content-Type: application/json"
	]
	if auth_required and auth_token != "":
		headers.append("Authorization: Bearer " + auth_token)
	else:
		headers.append("Authorization: Bearer " + _get_supabase_key())
	return headers

# ─────────────────────────────────────────────────────────
# Helper to perform HTTP request using the object pool
# ─────────────────────────────────────────────────────────
# 最大リトライ回数
const MAX_RETRIES = 3

func _send_request(url: String, method: HTTPClient.Method, body_str: String, auth_required: bool, callback: Callable, retry_count: int = 0) -> void:
	var req = _get_available_request()
	if req == null:
		if retry_count < MAX_RETRIES:
			var timer = get_tree().create_timer(1.0)
			timer.timeout.connect(func():
				_send_request(url, method, body_str, auth_required, callback, retry_count + 1)
			)
		else:
			callback.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
		return
	
	var wrapped_callback = func(result: int, response_code: int, headers: PackedStringArray, body_data: PackedByteArray):
		var is_network_error = result != HTTPRequest.RESULT_SUCCESS
		var is_server_error = response_code >= 500 and response_code < 600
		
		if (is_network_error or is_server_error) and retry_count < MAX_RETRIES:
			push_warning("[BackendManager] Request failed (result: %d, HTTP: %d). Retrying (%d/%d)..." % [result, response_code, retry_count + 1, MAX_RETRIES])
			var timer = get_tree().create_timer(1.0)
			timer.timeout.connect(func():
				_send_request(url, method, body_str, auth_required, callback, retry_count + 1)
			)
		else:
			callback.call(result, response_code, headers, body_data)
			
	_pool_callbacks[req] = wrapped_callback
	var err = req.request(url, _get_headers(auth_required), method, body_str)
	if err != OK:
		_pool_callbacks.erase(req)
		if retry_count < MAX_RETRIES:
			var timer = get_tree().create_timer(1.0)
			timer.timeout.connect(func():
				_send_request(url, method, body_str, auth_required, callback, retry_count + 1)
			)
		else:
			callback.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())

# 1. Sign Up (ユーザー登録)
func signup_user(user_id: String, password: String) -> void:
	var safe_email = user_id.to_utf8_buffer().hex_encode() + "@chikenrace.com"
	var url = _get_supabase_url() + "/auth/v1/signup"
	var body = {
		"email": safe_email,
		"password": password
	}
	
	_send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), false, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201):
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("access_token"):
					auth_token = data["access_token"]
					if data.has("user") and data["user"] is Dictionary:
						logged_in_uuid = data["user"].get("id", "")
					
					auth_completed.emit(true, "")
					return
			auth_completed.emit(true, "") # Sometimes signup returns info without immediate token depending on config
		else:
			var err_msg = "接続エラー"
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					if data.has("msg"):
						err_msg = data["msg"]
					elif data.has("message"):
						err_msg = data["message"]
					elif data.has("error_description"):
						err_msg = data["error_description"]
					elif data.has("error"):
						err_msg = data["error"]
			
			if err_msg == "接続エラー" and response_code != 0:
				err_msg += " (HTTP " + str(response_code) + ")"
			auth_completed.emit(false, err_msg)
	)

# 2. Login (ログイン)
func login_user(user_id: String, password: String) -> void:
	var safe_email = user_id.to_utf8_buffer().hex_encode() + "@chikenrace.com"
	var url = _get_supabase_url() + "/auth/v1/token?grant_type=password"
	var body = {
		"email": safe_email,
		"password": password
	}
	
	_send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), false, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("access_token"):
					auth_token = data["access_token"]
					if data.has("user") and data["user"] is Dictionary:
						logged_in_uuid = data["user"].get("id", "")
					auth_completed.emit(true, "")
					return
			auth_completed.emit(false, "データ解析エラー")
		else:
			var err_msg = "IDまたはパスワードが違います"
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					if data.has("error_description"):
						err_msg = data["error_description"]
					elif data.has("msg"):
						err_msg = data["msg"]
					elif data.has("message"):
						err_msg = data["message"]
			
			if err_msg == "IDまたはパスワードが違います" and response_code != 0:
				if response_code >= 500:
					err_msg = "サーバーエラー (HTTP " + str(response_code) + ")"
			auth_completed.emit(false, err_msg)
	)

# 3. Cloud Save (クラウドセーブ)
func save_cloud_data(data_dict: Dictionary) -> void:
	if auth_token == "" or logged_in_uuid == "":
		save_completed.emit(false)
		return
		
	# We UPSERT to the 'saves' table
	var url = _get_supabase_url() + "/rest/v1/saves"
	var body = {
		"user_id": logged_in_uuid,
		"data": data_dict
	}
	
	var req = _get_available_request()
	if req == null:
		save_completed.emit(false)
		return
		
	_pool_callbacks[req] = func(result: int, response_code: int, headers: PackedStringArray, body_data: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
			save_completed.emit(true)
		else:
			save_completed.emit(false)
	
	var custom_headers = _get_headers(true)
	custom_headers.append("Prefer: resolution=merge-duplicates")
	req.request(url, custom_headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# 4. Cloud Load (クラウドロード)
func load_cloud_data() -> void:
	if auth_token == "" or logged_in_uuid == "":
		load_completed.emit(false, {})
		return
		
	var url = _get_supabase_url() + "/rest/v1/saves?user_id=eq." + logged_in_uuid + "&select=data"
	
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					var save_entry = data[0]
					if save_entry is Dictionary and save_entry.has("data"):
						load_completed.emit(true, save_entry["data"])
						return
			load_completed.emit(false, {})
		else:
			load_completed.emit(false, {})
	)

# 5. Upload Daily Score & Ghost Record
func upload_daily_record(day_idx: int, score: int, record: Dictionary) -> void:
	if auth_token == "" or logged_in_uuid == "":
		return
	
	# クライアント側でも上限チェックを行い、異常値を送信しない（多層防御）
	var safe_score = clampi(score, 0, 9999)
		
	var url = _get_supabase_url() + "/rest/v1/daily_scores"
	var body = {
		"user_id": logged_in_uuid,
		"username": Global.player_name,
		"day_idx": day_idx,
		"score": safe_score,
		"record": record,
		"season": Global.current_season
	}
	
	# Send to database
	_send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		pass # Silent upload
	)

# 6. Fetch Daily Scores & Ghost Records (for current day)
func fetch_daily_records(day_idx: int) -> void:
	# Select columns, filter by day index and season, exclude the player themselves, sort by score descending, limit to 5
	var url = _get_supabase_url() + "/rest/v1/daily_scores?day_idx=eq." + str(day_idx) + "&season=eq." + str(Global.current_season) + "&select=username,score,record&order=score.desc&limit=6"
	if logged_in_uuid != "":
		url += "&user_id=neq." + logged_in_uuid
		
	_send_request(url, HTTPClient.METHOD_GET, "", false, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					daily_scores_loaded.emit(true, data)
					return
			daily_scores_loaded.emit(false, [])
		else:
			daily_scores_loaded.emit(false, [])
	)

# 7. Generate Simulated CPU Daily Ghost (Offline/Fallback)
func generate_simulated_ghosts(day_idx: int) -> Array:
	var ghosts = []
	var cpu_names = ["慎重な優等生", "エナドリ狂人", "ブラフの達人", "逆転狙いの浪人生"]
	cpu_names.shuffle()
	
	for i in range(3):
		var cpu_name = cpu_names[i]
		# Generate a simulated deck profile
		var simulated_score = 0
		var hours_history = []
		
		# Simulating 1 hour for daily (since daily is 1 hour per day in the match history)
		# Actually, daily has 3 hours per day, let's simulate 3 hours of study for this CPU
		var bursted_count = 0
		for h in range(3):
			var draws = randi_range(3, 8)
			var bursted = randf() < 0.15 + (draws * 0.08) # higher draws -> higher burst probability
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
		# Chance of bluffing
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

# --- FRIEND ROOM MULTIPLAYER API & OFFLINE MOCKS ---

# 1. Create Room
func create_friend_room() -> void:
	is_mock_room = false
	var code = str(randi_range(1000, 9999))
	var host_name = Global.player_name if Global.player_name != "" else "あなた"
	
	if auth_token == "" or logged_in_uuid == "":
		_enable_mock_room(code, host_name)
		room_created.emit(true, code)
		return
		
	var url = _get_supabase_url() + "/rest/v1/friend_rooms"
	var body = {
		"room_code": code,
		"status": "waiting",
		"current_day": 1,
		"participants": [{"user_id": logged_in_uuid, "username": host_name}],
		"host_id": logged_in_uuid
	}
	
	_send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
			room_created.emit(true, code)
		else:
			# Offline fallback
			_enable_mock_room(code, host_name)
			room_created.emit(true, code)
	)

func _enable_mock_room(code: String, host_name: String) -> void:
	is_mock_room = true
	mock_room_code = code
	mock_room_status = "waiting"
	mock_current_day = 1
	mock_participants = [{"user_id": "player", "username": host_name}]
	mock_moves.clear()
	
	# Simulate 2 friends joining after a short delay (during lobby polling)
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		if is_mock_room and mock_room_status == "waiting":
			mock_participants.append({"user_id": "cpu_sato", "username": "佐藤くん (CPU)"})
			mock_participants.append({"user_id": "cpu_suzuki", "username": "鈴木さん (CPU)"})
	)

# 2. Join Room (RPC版 - アトミックなルーム参加でレースコンディションを防ぐ)
func join_friend_room(room_code: String) -> void:
	is_mock_room = false
	var user_name = Global.player_name if Global.player_name != "" else "あなた"
	
	if auth_token == "" or logged_in_uuid == "":
		_join_mock_room(room_code, user_name)
		return
	
	# RPC経由でサーバー側でアトミックに参加処理を行う
	# GET→PATCHパターン（旧来の実装）はレースコンディションの危険があるため廃止
	var rpc_url = _get_supabase_url() + "/rest/v1/rpc/join_friend_room_safe"
	var rpc_body = {
		"p_room_code": room_code,
		"p_user_id": logged_in_uuid,
		"p_username": user_name
	}
	
	_send_request(rpc_url, HTTPClient.METHOD_POST, JSON.stringify(rpc_body), true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					if data.has("error"):
						var error_code = data["error"]
						if error_code == "room_full":
							room_joined.emit(false, [])
						else:
							# ルームが見つからない場合はモックにフォールバック
							_join_mock_room(room_code, user_name)
					elif data.has("participants"):
						var parts = data["participants"]
						if parts is Array:
							room_joined.emit(true, parts)
							return
		# 通信エラー時はモックにフォールバック
		_join_mock_room(room_code, user_name)
	)

func _join_mock_room(room_code: String, user_name: String) -> void:
	is_mock_room = true
	mock_room_code = room_code
	mock_room_status = "waiting"
	mock_current_day = 1
	mock_participants = [
		{"user_id": "cpu_sato", "username": "ホスト友達 (CPU)"},
		{"user_id": "player", "username": user_name},
		{"user_id": "cpu_suzuki", "username": "鈴木さん (CPU)"}
	]
	mock_moves.clear()
	room_joined.emit(true, mock_participants)

# 3. Start Game
func start_friend_game(room_code: String) -> void:
	if is_mock_room:
		mock_room_status = "playing"
		# Auto-fill remaining slot to make it exactly 4 participants
		if mock_participants.size() < 4:
			mock_participants.append({"user_id": "cpu_takahashi", "username": "高橋くん (CPU)"})
		return
		
	var url = _get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	
	# Determine CPU fill names
	var current_parts = []
	for p in mock_participants:
		current_parts.append(p)
		
	# Fetch current participants to be sure, then patch
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					var room = data[0]
					var parts = room.get("participants", [])
					
					# Fill up to 4 participants with CPUs
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
					_send_request(url, HTTPClient.METHOD_PATCH, JSON.stringify(patch_body), true, func(r_res, r_code, r_headers, r_body):
						pass # Status updated successfully
					)
	)

# 4. Upload Friend Move
func upload_friend_move(room_code: String, day_idx: int, move_data: Dictionary) -> void:
	if is_mock_room:
		if not mock_moves.has(day_idx):
			mock_moves[day_idx] = []
		
		# 1. Update/Insert player move
		var player_move = null
		for m in mock_moves[day_idx]:
			if m.get("user_id") == "player":
				player_move = m
				break
				
		var my_move = {
			"room_code": room_code,
			"user_id": "player",
			"username": Global.player_name if Global.player_name != "" else "あなた",
			"day_idx": day_idx,
			"actual_score": move_data.get("actual_score", 0),
			"declared_score": move_data.get("declared_score", 0),
			"hours_history": move_data.get("hours_history", []),
			"doubts_made": move_data.get("doubts_made", []),
			"doubts_submitted": move_data.get("doubts_submitted", false)
		}
		
		if player_move:
			player_move.clear()
			for k in my_move.keys():
				player_move[k] = my_move[k]
		else:
			mock_moves[day_idx].append(my_move)
			
		MockDataGenerator.simulate_friend_room_cpus(
			room_code, day_idx, mock_moves, mock_participants, my_move, Global.opponent_profiles
		)
		return
		
	# クライアント側でもスコアの上限チェック（多層防御）
	var safe_actual = clampi(move_data.get("actual_score", 0), 0, 9999)
	var safe_declared = clampi(move_data.get("declared_score", 0), 0, 9999)
	
	var url = _get_supabase_url() + "/rest/v1/friend_room_moves"
	var body = {
		"room_code": room_code,
		"user_id": logged_in_uuid,
		"username": Global.player_name,
		"day_idx": day_idx,
		"actual_score": safe_actual,
		"declared_score": safe_declared,
		"hours_history": move_data.get("hours_history", []),
		"doubts_made": move_data.get("doubts_made", []),
		"doubts_submitted": move_data.get("doubts_submitted", false)
	}
	
	var req = _get_available_request()
	if req == null:
		return
	_pool_callbacks[req] = func(result: int, response_code: int, headers: PackedStringArray, body_data: PackedByteArray):
		pass # Silent upload
	
	var custom_headers = _get_headers(true)
	custom_headers.append("Prefer: resolution=merge-duplicates")
	req.request(url, custom_headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# 5. Poll Room Status
func poll_room_status(room_code: String) -> void:
	if is_mock_room:
		room_polled.emit(mock_room_status, mock_current_day, mock_participants)
		return
		
	var url = _get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					var room = data[0]
					var status = room.get("status", "waiting")
					var day = room.get("current_day", 1)
					var parts = room.get("participants", [])
					
					# Sync internal list
					mock_participants = parts
					mock_room_status = status
					mock_current_day = day
					
					room_polled.emit(status, day, parts)
					return
			room_polled.emit("waiting", 1, [])
		else:
			# Mock Fallback
			room_polled.emit(mock_room_status, mock_current_day, mock_participants)
	)

# 6. Poll Day Moves (to check if everyone has played)
func poll_day_moves(room_code: String, day_idx: int) -> void:
	if is_mock_room:
		var day_data = mock_moves.get(day_idx, [])
		day_moves_polled.emit(true, day_data)
		return
		
	var url = _get_supabase_url() + "/rest/v1/friend_room_moves?room_code=eq." + room_code + "&day_idx=eq." + str(day_idx)
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array:
					day_moves_polled.emit(true, data)
					return
			day_moves_polled.emit(false, [])
		else:
			# Mock Fallback
			var day_data = mock_moves.get(day_idx, [])
			day_moves_polled.emit(true, day_data)
	)

# 7. Advance Friend Room Day (Host only triggers this when day moves are complete)
func advance_friend_room_day(room_code: String, next_day: int) -> void:
	if is_mock_room:
		mock_current_day = next_day
		return
		
	var url = _get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	var body = {"current_day": next_day}
	_send_request(url, HTTPClient.METHOD_PATCH, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		pass # Day index updated successfully
	)
