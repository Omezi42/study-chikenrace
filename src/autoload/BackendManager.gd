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
	# Git管理外の設定ファイルからSupabaseキーを安全に読み込む (P0セキュリティ対策)
	var config_loaded = false
	if FileAccess.file_exists("res://supabase_config.json"):
		var file = FileAccess.open("res://supabase_config.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					_supabase_url = str(data.get("supabase_url", ""))
					_supabase_key = str(data.get("supabase_key", ""))
					config_loaded = true
			file.close()
			
	if not config_loaded:
		_supabase_url = OS.get_environment("SUPABASE_URL")
		if _supabase_url == "":
			_supabase_url = ProjectSettings.get_setting("backend/supabase_url", "https://your-project.supabase.co")

		_supabase_key = OS.get_environment("SUPABASE_KEY")
		if _supabase_key == "":
			_supabase_key = ProjectSettings.get_setting("backend/supabase_key", "your-supabase-key")

func _ready() -> void:
	# プール内にHTTPRequestノードを事前生成する
	for i in range(POOL_SIZE):
		var req = HTTPRequest.new()
		req.name = "HttpPoolNode_%d" % i
		add_child(req)
		req.request_completed.connect(_on_pool_request_completed.bind(req))
		_http_pool.append(req)

func _process(delta: float) -> void:
	if ws_peer:
		ws_peer.poll()
		var state = ws_peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if not ws_connected:
				_on_ws_connected()
			_process_ws_packets()
			ws_heartbeat_timer += delta
			if ws_heartbeat_timer >= WS_HEARTBEAT_INTERVAL:
				_send_ws_heartbeat()
		elif state == WebSocketPeer.STATE_CLOSED:
			if ws_connected:
				_on_ws_disconnected()
			if ws_room_code != "":
				ws_reconnect_timer += delta
				if ws_reconnect_timer >= WS_RECONNECT_INTERVAL:
					_reconnect_ws()

func connect_realtime_lobby(room_code: String) -> void:
	if is_mock_room or room_code == "":
		return
	ws_room_code = room_code
	_reconnect_ws()

func disconnect_realtime_lobby() -> void:
	ws_room_code = ""
	if ws_peer:
		ws_peer.close()
	ws_connected = false

func _reconnect_ws() -> void:
	ws_reconnect_timer = 0.0
	ws_peer = WebSocketPeer.new()
	var raw_url = _get_supabase_url()
	if raw_url.is_empty() or raw_url == "https://your-project.supabase.co":
		return
	var ws_url = raw_url.replace("https://", "wss://").replace("http://", "ws://") + "/realtime/v1/websocket?apikey=" + _get_supabase_key() + "&vsn=1.0.0"
	var err = ws_peer.connect_to_url(ws_url)
	if err != OK:
		push_warning("[Realtime] WebSocket connection failed to start: %d" % err)

func _on_ws_connected() -> void:
	ws_connected = true
	ws_heartbeat_timer = 0.0
	# realtime:public:friend_rooms に Join してルーム変更を監視
	var join_msg = {
		"topic": "realtime:public:friend_rooms",
		"event": "phx_join",
		"payload": {},
		"ref": "1"
	}
	ws_peer.send_text(JSON.stringify(join_msg))
	push_warning("[Realtime] WebSocket lobby connected and listening.")

func _on_ws_disconnected() -> void:
	ws_connected = false
	push_warning("[Realtime] WebSocket disconnected.")

func _send_ws_heartbeat() -> void:
	ws_heartbeat_timer = 0.0
	var msg = {
		"topic": "phoenix",
		"event": "heartbeat",
		"payload": {},
		"ref": "hb"
	}
	ws_peer.send_text(JSON.stringify(msg))

func _process_ws_packets() -> void:
	while ws_peer.get_available_packet_count() > 0:
		var packet = ws_peer.get_packet()
		var text = packet.get_string_from_utf8()
		var json = JSON.new()
		if json.parse(text) == OK:
			var msg = json.get_data()
			if msg is Dictionary and msg.get("event") == "postgres_changes":
				var payload = msg.get("payload", {})
				var record = payload.get("data", {})
				if record.get("room_code") == ws_room_code:
					# 変更があったためルーム情報を即時再取得する
					poll_room_status(ws_room_code)

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

func _validate_response(result: int, response_code: int, body_data: PackedByteArray, context: String) -> Variant:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("[%s] Request failed with network error (result: %d)" % [context, result])
		return null
	if response_code < 200 or response_code >= 300:
		push_warning("[%s] Request failed with HTTP %d" % [context, response_code])
		return null
	var body_str = body_data.get_string_from_utf8()
	if body_str.is_empty():
		return {}
	var json = JSON.new()
	if json.parse(body_str) != OK:
		push_warning("[%s] Failed to parse JSON: %s" % [context, json.get_error_message()])
		return null
	return json.get_data()


signal auth_completed(success: bool, error_message: String)
signal save_completed(success: bool)
signal load_completed(success: bool, data: Dictionary)
signal daily_scores_loaded(success: bool, scores_array: Array)
signal random_match_status_updated(status: String, message: String)

signal room_created(success: bool, room_code: String)
signal room_joined(success: bool, participants: Array)
signal room_polled(status: String, current_day: int, participants: Array)
signal day_moves_polled(success: bool, moves: Array)
signal connection_lost()

var logged_in_uuid: String = ""
var auth_token: String = ""
var consecutive_network_errors: int = 0
var _sent_nonces: Dictionary = {} # client_nonce (String) -> status (String)

# WebSocket Realtime variables
var ws_peer: WebSocketPeer = null
var ws_connected: bool = false
var ws_room_code: String = ""
var ws_heartbeat_timer: float = 0.0
var ws_reconnect_timer: float = 0.0
const WS_HEARTBEAT_INTERVAL = 30.0
const WS_RECONNECT_INTERVAL = 5.0

# Active/Polled Room state cache (for connection recovery & state machine)
var cached_room_status: String = "waiting"
var cached_current_day: int = 1
var cached_participants: Array = []
var cached_last_sync_revision: int = 0
var cached_host_id: String = ""
var cached_day_moves: Dictionary = {} # DayIdx -> Array of normalized moves

func is_current_room_host() -> bool:
	return logged_in_uuid != "" and logged_in_uuid == cached_host_id

# Offline/Mock state for friend rooms
var is_mock_room: bool = false
var mock_room_code: String = ""
var mock_participants: Array = []
var mock_room_status: String = "waiting"
var mock_current_day: int = 1
var mock_last_sync_revision: int = 0
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

func _normalize_score_payload(move_data: Variant) -> Dictionary:
	var d: Dictionary = {}
	if move_data is Dictionary:
		d = move_data
		if d.has("record") and d["record"] is Dictionary:
			var rec = d["record"]
			for k in rec.keys():
				if not d.has(k) or d[k] == null or (d[k] is String and d[k] == ""):
					d[k] = rec[k]
	
	# hours_history と hours の互換性
	var raw_hours = d.get("hours_history", d.get("hours", []))
	if not (raw_hours is Array):
		raw_hours = []
		
	# doubts_made の配列化
	var raw_doubts = d.get("doubts_made", [])
	if not (raw_doubts is Array):
		raw_doubts = []

	var norm_doubts = []
	for db in raw_doubts:
		norm_doubts.append(str(db))

	# username / name / player の表記揺れ
	var resolved_name = str(d.get("username", d.get("name", d.get("player_name", ""))))
	
	# user_id / id
	var resolved_uid = str(d.get("user_id", d.get("id", "")))

	return {
		"room_code": str(d.get("room_code", "")),
		"user_id": resolved_uid,
		"username": resolved_name,
		"day_idx": int(d.get("day_idx", d.get("day", 0))),
		"actual_score": clampi(int(d.get("actual_score", 0)), 0, 9999),
		"declared_score": clampi(int(d.get("declared_score", 0)), 0, 9999),
		"hours_history": raw_hours,
		"doubts_made": norm_doubts,
		"doubts_submitted": bool(d.get("doubts_submitted", false)),
		"phase": str(d.get("phase", "")),
		"revision": int(d.get("revision", 0)),
		"submitted_at": str(d.get("submitted_at", "")),
		"client_nonce": str(d.get("client_nonce", ""))
	}

func _build_friend_move_payload(room_code: String, day_idx: int, move_data: Dictionary) -> Dictionary:
	var normalized = _normalize_score_payload(move_data)
	normalized["room_code"] = room_code
	if normalized["user_id"] == "":
		normalized["user_id"] = logged_in_uuid
	if normalized["username"] == "":
		normalized["username"] = Global.player_name if Global.player_name != "" else "Player"
	if normalized["day_idx"] <= 0:
		normalized["day_idx"] = day_idx
	if normalized["submitted_at"] == "":
		normalized["submitted_at"] = Time.get_datetime_string_from_system(true)
	if normalized["client_nonce"] == "":
		normalized["client_nonce"] = "%s-%s-%d-%s" % [
			room_code,
			normalized["user_id"],
			normalized["day_idx"],
			normalized["phase"]
		]
	return normalized

# ─────────────────────────────────────────────────────────
# Helper to perform HTTP request using the object pool
# ─────────────────────────────────────────────────────────
# 最大リトライ回数
const MAX_RETRIES = 3

func _send_request(url: String, method: HTTPClient.Method, body_str: String, auth_required: bool, callback: Callable, _deprecated_retry: int = 0) -> void:
	_do_send_request_with_retry(url, method, body_str, auth_required, callback)

func _do_send_request_with_retry(url: String, method: HTTPClient.Method, body_str: String, auth_required: bool, callback: Callable) -> void:
	for retry_count in range(MAX_RETRIES + 1):
		var req = _get_available_request()
		if req == null:
			if retry_count < MAX_RETRIES:
				await get_tree().create_timer(1.0).timeout
				continue
			else:
				callback.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
				return

		var completed_state = {"done": false, "data": []}

		var wrapped_callback = func(result: int, response_code: int, headers: PackedStringArray, body_data: PackedByteArray):
			completed_state["done"] = true
			completed_state["data"] = [result, response_code, headers, body_data]

		_pool_callbacks[req] = wrapped_callback
		var err = req.request(url, _get_headers(auth_required), method, body_str)
		if err != OK:
			_pool_callbacks.erase(req)
			if retry_count < MAX_RETRIES:
				await get_tree().create_timer(1.0).timeout
				continue
			else:
				callback.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
				return

		while not completed_state["done"]:
			await get_tree().process_frame

		var res = completed_state["data"][0]
		var res_code = completed_state["data"][1]
		var res_headers = completed_state["data"][2]
		var res_body = completed_state["data"][3]

		var is_network_error = res != HTTPRequest.RESULT_SUCCESS
		var is_server_error = res_code >= 500 and res_code < 600

		if (is_network_error or is_server_error) and retry_count < MAX_RETRIES:
			push_warning("[BackendManager] Request failed (result: %d, HTTP: %d). Retrying (%d/%d)..." % [res, res_code, retry_count + 1, MAX_RETRIES])
			await get_tree().create_timer(1.0).timeout
			continue
		else:
			callback.call(res, res_code, res_headers, res_body)
			return

# 1. Sign Up (ユーザー登録)
func signup_user(user_id: String, password: String) -> void:
	Global.show_loading("新規登録中...")
	var safe_email = user_id.to_utf8_buffer().hex_encode() + "@chikenrace.com"
	var url = _get_supabase_url() + "/auth/v1/signup"
	var body = {
		"email": safe_email,
		"password": password
	}

	_send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), false, func(result, response_code, headers, body_data):
		Global.hide_loading()
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
	Global.show_loading("ログイン中...")
	var safe_email = user_id.to_utf8_buffer().hex_encode() + "@chikenrace.com"
	var url = _get_supabase_url() + "/auth/v1/token?grant_type=password"
	var body = {
		"email": safe_email,
		"password": password
	}

	_send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), false, func(result, response_code, headers, body_data):
		Global.hide_loading()
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

# 2.5 Token Verification (セッション検証)
func verify_token(token: String, uuid: String) -> void:
	if token == "" or uuid == "":
		auth_completed.emit(false, "トークンが無効です")
		return

	Global.show_loading("セッション復旧中...")
	auth_token = token
	logged_in_uuid = uuid
	var url = _get_supabase_url() + "/auth/v1/user"

	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		Global.hide_loading()
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			auth_completed.emit(true, "")
		else:
			auth_token = ""
			logged_in_uuid = ""
			auth_completed.emit(false, "セッション期限切れ")
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
			if is_inside_tree():
				DeskTheme.show_toast(self, "クラウドセーブ失敗。ローカルに保存します。")

	var custom_headers = _get_headers(true)
	custom_headers.append("Prefer: resolution=merge-duplicates")
	req.request(url, custom_headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# 4. Cloud Load (クラウドロード)
func load_cloud_data() -> void:
	if auth_token == "" or logged_in_uuid == "":
		load_completed.emit(false, {})
		return

	Global.show_loading("クラウドロード中...")
	var url = _get_supabase_url() + "/rest/v1/saves?user_id=eq." + logged_in_uuid + "&select=data"

	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		Global.hide_loading()
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
			if is_inside_tree():
				DeskTheme.show_toast(self, "クラウドロード失敗。ローカルデータを使用します。")
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
		if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
			if is_inside_tree():
				DeskTheme.show_toast(self, "今日のスコアの保存に失敗しました。")
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
	Global.show_loading("ルーム作成中...")
	is_mock_room = false
	var code = str(randi_range(1000, 9999))
	var host_name = Global.player_name if Global.player_name != "" else "あなた"

	if auth_token == "" or logged_in_uuid == "":
		_enable_mock_room(code, host_name)
		Global.hide_loading()
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
		Global.hide_loading()
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
			room_created.emit(true, code)
		else:
			# Offline fallback
			_enable_mock_room(code, host_name)
			room_created.emit(true, code)
			if is_inside_tree():
				DeskTheme.show_toast(self, "接続失敗。オフライン(CPU戦)で開始します。")
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
	Global.show_loading("ルーム参加中...")
	is_mock_room = false
	var user_name = Global.player_name if Global.player_name != "" else "あなた"

	if auth_token == "" or logged_in_uuid == "":
		_join_mock_room(room_code, user_name)
		Global.hide_loading()
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
		Global.hide_loading()
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
		if is_inside_tree():
			DeskTheme.show_toast(self, "接続失敗。オフライン(CPU戦)として参加します。")
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
	var body = _build_friend_move_payload(room_code, day_idx, move_data)
	var nonce = body.get("client_nonce", "")
	
	if nonce != "":
		if _sent_nonces.get(nonce, "") == "success":
			return
		elif _sent_nonces.get(nonce, "") == "sending":
			return
		_sent_nonces[nonce] = "sending"

	if is_mock_room:
		if not mock_moves.has(day_idx):
			mock_moves[day_idx] = []

		var player_move = null
		for m in mock_moves[day_idx]:
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
			"revision": mock_last_sync_revision + 1,
			"submitted_at": body.get("submitted_at", ""),
			"client_nonce": nonce
		}

		if player_move:
			player_move.clear()
			for k in my_move.keys():
				player_move[k] = my_move[k]
		else:
			mock_moves[day_idx].append(my_move)

		mock_last_sync_revision += 1
		MockDataGenerator.simulate_friend_room_cpus(
			room_code, day_idx, mock_moves, mock_participants, my_move, Global.opponent_profiles
		)
		if nonce != "":
			_sent_nonces[nonce] = "success"
		return

	var url = _get_supabase_url() + "/rest/v1/friend_room_moves"
	var req = _get_available_request()
	if req == null:
		if nonce != "":
			_sent_nonces[nonce] = "failed"
		return
		
	_pool_callbacks[req] = func(result: int, response_code: int, headers: PackedStringArray, body_data: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
			if nonce != "":
				_sent_nonces[nonce] = "success"
		else:
			if nonce != "":
				_sent_nonces[nonce] = "failed"
			if is_inside_tree():
				DeskTheme.show_toast(self, "Failed to send friend-room data.")

	var custom_headers = _get_headers(true)
	custom_headers.append("Prefer: resolution=merge-duplicates")
	req.request(url, custom_headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# 5. Poll Room Status
func poll_room_status(room_code: String) -> void:
	if is_mock_room:
		cached_room_status = mock_room_status
		cached_current_day = mock_current_day
		cached_participants = mock_participants
		cached_last_sync_revision = mock_last_sync_revision
		room_polled.emit(mock_room_status, mock_current_day, mock_participants)
		return
	var url = _get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			consecutive_network_errors = 0
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and data.size() > 0:
					var room = data[0]
					var status = room.get("status", "waiting")
					var day = room.get("current_day", 1)
					var parts = room.get("participants", [])
					var last_revision = int(room.get("last_sync_revision", 0))
					
					cached_room_status = status
					cached_current_day = day
					cached_participants = parts
					cached_last_sync_revision = last_revision
					cached_host_id = room.get("host_id", "")
					
					mock_participants = parts
					mock_room_status = status
					mock_current_day = day
					mock_last_sync_revision = last_revision
					
					if Global.game_mode == Constants.MODE_RANDOM and status == "waiting":
						if parts.size() >= 4:
							var host_id = room.get("host_id", "")
							if host_id == logged_in_uuid:
								start_friend_game(room_code)
								
					room_polled.emit(status, day, parts)
					return
			room_polled.emit("waiting", 1, [])
		else:
			consecutive_network_errors += 1
			if consecutive_network_errors >= 3:
				connection_lost.emit()
			room_polled.emit(mock_room_status, mock_current_day, mock_participants)
	)

# 6. Poll Day Moves (to check if everyone has played)
func poll_day_moves(room_code: String, day_idx: int) -> void:
	if is_mock_room:
		var day_data = mock_moves.get(day_idx, [])
		var normalized_day_data = []
		for m in day_data:
			normalized_day_data.append(_normalize_score_payload(m))
		cached_day_moves[day_idx] = normalized_day_data
		day_moves_polled.emit(true, normalized_day_data)
		return
	var url = _get_supabase_url() + "/rest/v1/friend_room_moves?room_code=eq." + room_code + "&day_idx=eq." + str(day_idx)
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			consecutive_network_errors = 0
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array:
					var normalized_moves = []
					for m in data:
						normalized_moves.append(_normalize_score_payload(m))
					cached_day_moves[day_idx] = normalized_moves
					day_moves_polled.emit(true, normalized_moves)
					return
			day_moves_polled.emit(false, [])
		else:
			consecutive_network_errors += 1
			if consecutive_network_errors >= 3:
				connection_lost.emit()
			var day_data = mock_moves.get(day_idx, [])
			var normalized_day_data = []
			for m in day_data:
				normalized_day_data.append(_normalize_score_payload(m))
			cached_day_moves[day_idx] = normalized_day_data
			day_moves_polled.emit(true, normalized_day_data)
	)

# 7. Advance Friend Room Day (Host only triggers this when day moves are complete)
func advance_friend_room_day(room_code: String, next_day: int) -> void:
	if is_mock_room:
		mock_current_day = next_day
		mock_last_sync_revision += 1
		cached_current_day = next_day
		cached_last_sync_revision = mock_last_sync_revision
		return
	var url = _get_supabase_url() + "/rest/v1/friend_rooms?room_code=eq." + room_code
	var body = {
		"current_day": next_day,
		"last_sync_revision": mock_last_sync_revision + 1
	}
	_send_request(url, HTTPClient.METHOD_PATCH, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 204):
			mock_current_day = next_day
			mock_last_sync_revision += 1
			cached_current_day = next_day
			cached_last_sync_revision = mock_last_sync_revision
	)

# ─────────────────────────────────────────────────────────
# 再接続と復旧ロジック (指数バックオフ)
# ─────────────────────────────────────────────────────────
signal reconnect_succeeded()
signal reconnect_failed()

var is_reconnecting: bool = false
var reconnect_attempts: int = 0

func attempt_reconnect() -> void:
	if is_reconnecting:
		return
	is_reconnecting = true
	reconnect_attempts = 0
	_reconnect_loop()

func _reconnect_loop() -> void:
	if auth_token == "" or logged_in_uuid == "":
		is_reconnecting = false
		reconnect_failed.emit()
		return
		
	reconnect_attempts += 1
	var backoff = min(pow(2, reconnect_attempts), 30.0) # 最大30秒
	
	var url = _get_supabase_url() + "/auth/v1/user"
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			consecutive_network_errors = 0
			is_reconnecting = false
			reconnect_succeeded.emit()
			if Global.friend_room_code != "":
				poll_room_status(Global.friend_room_code)
		else:
			if is_inside_tree():
				var timer = get_tree().create_timer(backoff)
				timer.timeout.connect(_reconnect_loop)
			else:
				is_reconnecting = false
	)

func join_or_create_random_match() -> void:
	is_mock_room = false
	var user_name = Global.player_name if Global.player_name != "" else "あなた"
	
	if auth_token == "" or logged_in_uuid == "":
		random_match_status_updated.emit("error", "オンライン対戦を行うにはログインが必要です。")
		return

	random_match_status_updated.emit("searching", "対戦ルームを検索中...")
	
	# 偏差値リーグに応じたプレフィックス（例: "RAND_A_"）でルームを探す
	var league = Global.get_deviation_league(Global.deviation_value)
	var search_prefix = "RAND_" + league + "_"
	
	var url = _get_supabase_url() + "/rest/v1/friend_rooms?status=eq.waiting&room_code=like." + search_prefix + "*"
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var rooms = json.get_data()
				if rooms is Array and rooms.size() > 0:
					# 見つかった最初のルームにジョインを試みる
					var target_room = rooms[0]
					var room_code = target_room.get("room_code", "")
					random_match_status_updated.emit("joining", "対戦ルームにジョイン中...")
					
					var rpc_url = _get_supabase_url() + "/rest/v1/rpc/join_friend_room_safe"
					var rpc_body = {
						"p_room_code": room_code,
						"p_user_id": logged_in_uuid,
						"p_username": user_name
					}
					_send_request(rpc_url, HTTPClient.METHOD_POST, JSON.stringify(rpc_body), true, func(r_res, r_code, r_headers, r_body):
						if r_res == HTTPRequest.RESULT_SUCCESS and r_code == 200:
							var r_json = JSON.new()
							if r_json.parse(r_body.get_string_from_utf8()) == OK:
								var data = r_json.get_data()
								if data is Dictionary and not data.has("error"):
									var parts = data.get("participants", [])
									Global.friend_room_code = room_code
									Global.friend_current_day = 1
									Global.friend_match_history.clear()
									random_match_status_updated.emit("matched", "マッチング成立！")
									room_joined.emit(true, parts)
									return
						# ジョイン失敗したら新規作成
						_create_random_match_room(user_name)
					)
					return
		
		# 待機ルームが見つからなかった場合、またはジョインに失敗した場合は自分がホストになってルームを新規作成する
		_create_random_match_room(user_name)
	)

func _create_random_match_room(user_name: String) -> void:
	random_match_status_updated.emit("creating", "対戦ルームを作成中...")
	
	var league = Global.get_deviation_league(Global.deviation_value)
	var room_code = "RAND_" + league + "_" + str(randi_range(100000, 999999))
	var url = _get_supabase_url() + "/rest/v1/friend_rooms"
	var body = {
		"room_code": room_code,
		"status": "waiting",
		"current_day": 1,
		"participants": [{"user_id": logged_in_uuid, "username": user_name}],
		"host_id": logged_in_uuid
	}
	
	_send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
			Global.friend_room_code = room_code
			Global.friend_current_day = 1
			Global.friend_match_history.clear()
			random_match_status_updated.emit("waiting_for_players", "他のプレイヤーを待っています...")
			room_created.emit(true, room_code)
		else:
			random_match_status_updated.emit("error", "対戦ルームの作成に失敗しました。")
	)

func fetch_participants_deviation(participants: Array) -> void:
	if auth_token == "" or logged_in_uuid == "":
		return
		
	var uuids = []
	for p in participants:
		var uid = p.get("user_id", "")
		if uid != "" and uid != logged_in_uuid:
			uuids.append(uid)
			
	if uuids.is_empty():
		return
		
	var uuid_str = ""
	for i in range(uuids.size()):
		if i > 0:
			uuid_str += ","
		uuid_str += uuids[i]
		
	var url = _get_supabase_url() + "/rest/v1/saves?user_id=in.(" + uuid_str + ")"
	_send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
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
	if auth_token == "" or logged_in_uuid == "":
		return
	var url = _get_supabase_url() + "/rest/v1/random_match_ratings"
	var body = {
		"user_id": logged_in_uuid,
		"score": score,
		"rank": rank,
		"deviation": deviation,
		"league": league
	}
	_send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), true, func(result, response_code, headers, body_data):
		pass
	)

