class_name WebRTCSignaling
extends Node

signal connected_to_server(id: int)
signal disconnected_from_server()
signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal offer_received(id: int, offer: String)
signal answer_received(id: int, answer: String)
signal ice_candidate_received(id: int, media: String, index: int, name: String)

var ws: WebSocketPeer = WebSocketPeer.new()
var is_connected_to_server: bool = false
var server_url: String = "ws://localhost:9080"
var room_code: String = ""

func _process(_delta: float) -> void:
	ws.poll()
	var state = ws.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected_to_server:
			pass # We wait for the 'id' message to consider fully connected
		
		while ws.get_available_packet_count() > 0:
			var packet = ws.get_packet()
			var msg_str = packet.get_string_from_utf8()
			_handle_message(msg_str)
			
	elif state == WebSocketPeer.STATE_CLOSED:
		if is_connected_to_server:
			is_connected_to_server = false
			disconnected_from_server.emit()

func connect_to_room(url: String, code: String) -> Error:
	server_url = url
	room_code = code
	var err = ws.connect_to_url(server_url)
	if err == OK:
		# Connection started. We must wait until STATE_OPEN to send 'join'.
		# Since _process polls, we'll wait for STATE_OPEN then send join manually or do it here if it's instant.
		# WebSocketPeer.connect_to_url doesn't open immediately, so we must send join in _process or a coroutine.
		_send_join_when_ready()
	return err

func _send_join_when_ready() -> void:
	while ws.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		await get_tree().process_frame
		ws.poll()
	
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var msg = {"type": "join", "room": room_code}
		ws.send_text(JSON.stringify(msg))

func disconnect_from_room() -> void:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var msg = {"type": "leave"}
		ws.send_text(JSON.stringify(msg))
	ws.close()
	is_connected_to_server = false

func send_offer(id: int, offer: String) -> void:
	var msg = {
		"type": "message",
		"id": id,
		"data": {"type": "offer", "sdp": offer}
	}
	ws.send_text(JSON.stringify(msg))

func send_answer(id: int, answer: String) -> void:
	var msg = {
		"type": "message",
		"id": id,
		"data": {"type": "answer", "sdp": answer}
	}
	ws.send_text(JSON.stringify(msg))

func send_candidate(id: int, media: String, index: int, name: String) -> void:
	var msg = {
		"type": "message",
		"id": id,
		"data": {
			"type": "candidate",
			"media": media,
			"index": index,
			"name": name
		}
	}
	ws.send_text(JSON.stringify(msg))

func _handle_message(msg_str: String) -> void:
	var json = JSON.new()
	if json.parse(msg_str) != OK:
		return
	var msg = json.data
	if not msg is Dictionary:
		return
		
	var type = msg.get("type", "")
	match type:
		"id":
			is_connected_to_server = true
			var my_id = int(msg.get("id", 0))
			connected_to_server.emit(my_id)
		"peer_connected":
			var peer_id = int(msg.get("id", 0))
			peer_connected.emit(peer_id)
		"peer_disconnected":
			var peer_id = int(msg.get("id", 0))
			peer_disconnected.emit(peer_id)
		"message":
			var sender_id = int(msg.get("id", 0))
			var data = msg.get("data", {})
			if data is Dictionary:
				var data_type = data.get("type", "")
				if data_type == "offer":
					offer_received.emit(sender_id, data.get("sdp", ""))
				elif data_type == "answer":
					answer_received.emit(sender_id, data.get("sdp", ""))
				elif data_type == "candidate":
					ice_candidate_received.emit(
						sender_id,
						data.get("media", ""),
						int(data.get("index", 0)),
						data.get("name", "")
					)
