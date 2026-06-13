extends Node

var _supabase_url: String = ""
var _supabase_key: String = ""

const POOL_SIZE = 6
var _http_pool: Array[HTTPRequest] = []
var _pool_callbacks: Dictionary = {}

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
signal reconnect_succeeded()
signal reconnect_failed()

var logged_in_uuid: String = ""
var auth_token: String = ""
var consecutive_network_errors: int = 0
var _sent_nonces: Dictionary = {}

var cached_room_status: String = "waiting"
var cached_current_day: int = 1
var cached_participants: Array = []
var cached_last_sync_revision: int = 0
var cached_host_id: String = ""
var cached_day_moves: Dictionary = {}

var is_mock_room: bool = false
var mock_room_code: String = ""
var mock_participants: Array = []
var mock_room_status: String = "waiting"
var mock_current_day: int = 1
var mock_last_sync_revision: int = 0
var mock_moves: Dictionary = {}

var auth_service: AuthService
var cloud_save_service: CloudSaveService
var matchmaking_service: MatchmakingService
var realtime_lobby_service: RealtimeLobbyService

func _init() -> void:
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
			
	auth_service = AuthService.new(self)
	cloud_save_service = CloudSaveService.new(self)
	matchmaking_service = MatchmakingService.new(self)
	realtime_lobby_service = RealtimeLobbyService.new(self)

func _ready() -> void:
	for i in range(POOL_SIZE):
		var req = HTTPRequest.new()
		req.name = "HttpPoolNode_%d" % i
		add_child(req)
		req.request_completed.connect(_on_pool_request_completed.bind(req))
		_http_pool.append(req)

func _process(delta: float) -> void:
	realtime_lobby_service.process(delta)

func is_current_room_host() -> bool:
	return logged_in_uuid != "" and logged_in_uuid == cached_host_id

func _get_available_request() -> HTTPRequest:
	for req in _http_pool:
		if req.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			return req
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
	
	var raw_hours = d.get("hours_history", d.get("hours", []))
	if not (raw_hours is Array):
		raw_hours = []
		
	var raw_doubts = d.get("doubts_made", [])
	if not (raw_doubts is Array):
		raw_doubts = []

	var norm_doubts = []
	for db in raw_doubts:
		norm_doubts.append(str(db))

	var resolved_name = str(d.get("username", d.get("name", d.get("player_name", ""))))
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

# --- Delegated Methods ---

func signup_user(user_id: String, password: String) -> void:
	auth_service.signup_user(user_id, password)

func login_user(user_id: String, password: String) -> void:
	auth_service.login_user(user_id, password)

func verify_token(token: String, uuid: String) -> void:
	auth_service.verify_token(token, uuid)

func save_cloud_data(data_dict: Dictionary) -> void:
	cloud_save_service.save_cloud_data(data_dict)

func load_cloud_data() -> void:
	cloud_save_service.load_cloud_data()

func upload_daily_record(day_idx: int, score: int, record: Dictionary) -> void:
	cloud_save_service.upload_daily_record(day_idx, score, record)

func fetch_daily_records(day_idx: int) -> void:
	cloud_save_service.fetch_daily_records(day_idx)

func create_friend_room() -> void:
	matchmaking_service.create_friend_room()

func join_friend_room(room_code: String) -> void:
	matchmaking_service.join_friend_room(room_code)

func start_friend_game(room_code: String) -> void:
	matchmaking_service.start_friend_game(room_code)

func upload_friend_move(room_code: String, day_idx: int, move_data: Dictionary) -> void:
	matchmaking_service.upload_friend_move(room_code, day_idx, move_data)

func poll_room_status(room_code: String) -> void:
	matchmaking_service.poll_room_status(room_code)

func poll_day_moves(room_code: String, day_idx: int) -> void:
	matchmaking_service.poll_day_moves(room_code, day_idx)

func advance_friend_room_day(room_code: String, next_day: int) -> void:
	matchmaking_service.advance_friend_room_day(room_code, next_day)

func join_or_create_random_match() -> void:
	matchmaking_service.join_or_create_random_match()

func fetch_participants_deviation(participants: Array) -> void:
	cloud_save_service.fetch_participants_deviation(participants)

func upload_random_match_result(score: int, rank: int, deviation: float, league: String) -> void:
	cloud_save_service.upload_random_match_result(score, rank, deviation, league)

func generate_simulated_ghosts(day_idx: int) -> Array:
	return matchmaking_service.generate_simulated_ghosts(day_idx)

func connect_realtime_lobby(room_code: String) -> void:
	realtime_lobby_service.connect_realtime_lobby(room_code)

func disconnect_realtime_lobby() -> void:
	realtime_lobby_service.disconnect_realtime_lobby()

func attempt_reconnect() -> void:
	realtime_lobby_service.attempt_reconnect()

func leave_or_delete_random_room(room_code: String) -> void:
	matchmaking_service.leave_or_delete_random_room(room_code)
