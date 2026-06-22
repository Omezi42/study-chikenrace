class_name RealtimeLobbyService
extends RefCounted

var bm: Node

var ws_peer: WebSocketPeer = null
var ws_connected: bool = false
var ws_room_code: String = ""
var ws_heartbeat_timer: float = 0.0
var ws_reconnect_timer: float = 0.0
const WS_HEARTBEAT_INTERVAL = 30.0
const WS_RECONNECT_INTERVAL = 5.0

var is_reconnecting: bool = false
var reconnect_attempts: int = 0

func _init(backend_manager: Node) -> void:
	bm = backend_manager

func process(delta: float) -> void:
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
	if bm.is_mock_room or room_code == "":
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
	var raw_url = bm._get_supabase_url()
	if raw_url.is_empty() or raw_url == "https://your-project.supabase.co":
		return
	var ws_url = raw_url.replace("https://", "wss://").replace("http://", "ws://") + "/realtime/v1/websocket?apikey=" + bm._get_supabase_key() + "&vsn=1.0.0"
	var err = ws_peer.connect_to_url(ws_url)
	if err != OK:
		push_warning("[Realtime] WebSocket connection failed to start: %d" % err)

func _on_ws_connected() -> void:
	ws_connected = true
	ws_heartbeat_timer = 0.0
	var join_msg = {
		"topic": "realtime:public",
		"event": "phx_join",
		"payload": {
			"config": {
				"postgres_changes": [
					{
						"event": "*",
						"schema": "public",
						"table": "friend_rooms"
					},
					{
						"event": "*",
						"schema": "public",
						"table": "friend_room_moves"
					}
				]
			}
		},
		"ref": "1"
	}
	ws_peer.send_text(JSON.stringify(join_msg))
	push_warning("[Realtime] WebSocket lobby connected and listening to changes.")

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
				var table = payload.get("table", "")
				var record = payload.get("data", {})
				if record.get("room_code") == ws_room_code:
					if table == "friend_rooms":
						bm.poll_room_status(ws_room_code)
					elif table == "friend_room_moves":
						var day = int(record.get("day_idx", 0))
						bm.poll_day_moves(ws_room_code, day)

func attempt_reconnect() -> void:
	if is_reconnecting:
		return
	is_reconnecting = true
	reconnect_attempts = 0
	_reconnect_loop()

func _reconnect_loop() -> void:
	if bm.auth_token == "" or bm.logged_in_uuid == "":
		is_reconnecting = false
		bm.reconnect_failed.emit()
		return
		
	reconnect_attempts += 1
	var backoff = min(pow(2, reconnect_attempts), 30.0) 
	
	var url = bm._get_supabase_url() + "/auth/v1/user"
	bm._send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			bm.consecutive_network_errors = 0
			is_reconnecting = false
			bm.reconnect_succeeded.emit()
			if Global.friend_room_code != "":
				bm.poll_room_status(Global.friend_room_code)
		else:
			if bm.is_inside_tree():
				var timer = bm.get_tree().create_timer(backoff)
				timer.timeout.connect(_reconnect_loop)
			else:
				is_reconnecting = false
	)
