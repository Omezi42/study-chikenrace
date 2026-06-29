class_name WebRTCSignaling
extends Node

signal connected_to_server(id: int)
signal disconnected_from_server()
signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal offer_received(id: int, offer: String)
signal answer_received(id: int, answer: String)
signal ice_candidate_received(id: int, media: String, index: int, name: String)
signal room_joined(data: Dictionary)

var ws: WebSocketPeer = WebSocketPeer.new()
var is_connected_to_server: bool = false
var server_url: String = "wss://5fcad032-394f-44f2-a5f9-87a3c1e6ae51-dev.e1-us-east-azure.choreoapis.dev/chikenrace/signaling-server-rc/v1.0/"
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
	if ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws.close()
		ws = WebSocketPeer.new()
	is_connected_to_server = false
	ws.supported_protocols = ["ws"]
	ws.set_handshake_headers(PackedStringArray([
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
		"Origin: https://5fcad032-394f-44f2-a5f9-87a3c1e6ae51-dev.e1-us-east-azure.choreoapis.dev"
	]))
	var err = ws.connect_to_url(server_url)
	if err == OK:
		_send_join_when_ready(ws, "join")
	else:
		call_deferred("emit_signal", "disconnected_from_server")
	return err

func connect_random(url: String) -> Error:
	server_url = url
	room_code = ""
	if ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws.close()
		ws = WebSocketPeer.new()
	is_connected_to_server = false
	ws.supported_protocols = ["ws"]
	ws.set_handshake_headers(PackedStringArray([
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
		"Origin: https://5fcad032-394f-44f2-a5f9-87a3c1e6ae51-dev.e1-us-east-azure.choreoapis.dev"
	]))
	var err = ws.connect_to_url(server_url)
	if err == OK:
		_send_join_when_ready(ws, "random_join")
	else:
		call_deferred("emit_signal", "disconnected_from_server")
	return err

func _send_join_when_ready(peer: WebSocketPeer, join_type: String) -> void:
	var timeout = 45.0 # Increased timeout for free tier server spin-up
	var elapsed = 0.0
	while peer.get_ready_state() == WebSocketPeer.STATE_CONNECTING and elapsed < timeout:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		peer.poll()
	
	if peer != ws:
		return
		
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var msg = {"type": join_type}
		if join_type == "join":
			msg["room"] = room_code
		peer.send_text(JSON.stringify(msg))
	else:
		disconnected_from_server.emit()

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
		"room_joined":
			room_code = msg.get("room", "")
			room_joined.emit(msg)
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
