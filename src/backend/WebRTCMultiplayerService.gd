class_name WebRTCMultiplayerService
extends Node

signal room_created(success: bool, code: String)
signal room_joined(success: bool, participants: Array)
signal player_connected(id: int)
signal player_disconnected(id: int)

var bm: Node
var signaling: WebRTCSignaling
var webrtc_peer: WebRTCMultiplayerPeer

var _pending_room_code: String = ""
var _is_host: bool = false
var _participants: Array = []

func _init(backend_manager: Node, sig: WebRTCSignaling) -> void:
	bm = backend_manager
	signaling = sig
	
	signaling.connected_to_server.connect(_on_signaling_connected)
	signaling.disconnected_from_server.connect(_on_signaling_disconnected)
	signaling.peer_connected.connect(_on_peer_connected)
	signaling.peer_disconnected.connect(_on_peer_disconnected)
	signaling.offer_received.connect(_on_offer_received)
	signaling.answer_received.connect(_on_answer_received)
	signaling.ice_candidate_received.connect(_on_ice_candidate_received)
	signaling.room_joined.connect(_on_random_room_joined)

func create_room() -> void:
	Global.show_loading("ルーム作成中...")
	_is_host = true
	var code = str(randi_range(1000, 9999))
	_pending_room_code = code
	
	# Node.js signaling server URL. For production, change to WSS.
	var server_url = ProjectSettings.get_setting("backend/signaling_url", "")
	if server_url == "":
		if OS.has_feature("web"):
			server_url = "wss://chicken-race-signaling.onrender.com" # 本番用URL
		else:
			server_url = "ws://localhost:9080"
			
	signaling.connect_to_room(server_url, code)

func join_room(code: String) -> void:
	Global.show_loading("ルーム参加中...")
	_is_host = false
	_pending_room_code = code
	var server_url = ProjectSettings.get_setting("backend/signaling_url", "")
	if server_url == "":
		if OS.has_feature("web"):
			server_url = "wss://chicken-race-signaling.onrender.com" # 本番用URL
		else:
			server_url = "ws://localhost:9080"
			
	signaling.connect_to_room(server_url, code)

func join_random_room() -> void:
	_is_host = false # Default to false, updated dynamically if we receive ID 1
	var server_url = ProjectSettings.get_setting("backend/signaling_url", "")
	if server_url == "":
		if OS.has_feature("web"):
			server_url = "wss://chicken-race-signaling.onrender.com" # 本番用URL
		else:
			server_url = "ws://localhost:9080"
			
	signaling.connect_random(server_url)

func disconnect_room() -> void:
	signaling.disconnect_from_room()
	if bm and bm.multiplayer and bm.multiplayer.peer_connected.is_connected(_on_webrtc_peer_connected):
		bm.multiplayer.peer_connected.disconnect(_on_webrtc_peer_connected)
	if webrtc_peer:
		webrtc_peer.close()
	bm.multiplayer.multiplayer_peer = null
	_participants.clear()

func _on_signaling_connected(my_id: int) -> void:
	webrtc_peer = WebRTCMultiplayerPeer.new()
	webrtc_peer.create_mesh(my_id)
	bm.multiplayer.multiplayer_peer = webrtc_peer
	
	if not bm.multiplayer.peer_connected.is_connected(_on_webrtc_peer_connected):
		bm.multiplayer.peer_connected.connect(_on_webrtc_peer_connected)
	
	_is_host = (my_id == 1)
	
	var user_name = Global.player_name if Global.player_name != "" else "あなた"
	_participants.clear()
	_participants.append({"user_id": str(my_id), "username": user_name})
	
	Global.hide_loading()
	if _is_host and signaling.room_code != "":
		room_created.emit(true, signaling.room_code)
	else:
		# If guest, we consider it joined but wait for peers. 
		room_joined.emit(true, _participants)

func _on_random_room_joined(data: Dictionary) -> void:
	print("WebRTC Signaling joined random room: ", data)
	_pending_room_code = data.get("room_code", "")
	_is_host = data.get("is_host", false)
	# For random match, signaling server handles the rest (making offers/answers)

@rpc("any_peer", "call_remote", "reliable")
func sync_player_info(username: String) -> void:
	var sender_id = bm.multiplayer.get_remote_sender_id()
	var found = false
	for i in range(_participants.size()):
		if _participants[i].get("user_id", "") == str(sender_id):
			_participants[i]["username"] = username
			found = true
			break
	if not found:
		_participants.append({"user_id": str(sender_id), "username": username})
	room_joined.emit(true, _participants)

func _on_webrtc_peer_connected(id: int) -> void:
	var my_name = Global.player_name if Global.player_name != "" else "あなた"
	sync_player_info.rpc_id(id, my_name)

func _on_signaling_disconnected() -> void:
	pass

func _on_peer_connected(id: int) -> void:
	var pc = WebRTCPeerConnection.new()
	pc.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	
	pc.session_description_created.connect(_on_session_description_created.bind(id))
	pc.ice_candidate_created.connect(_on_ice_candidate_created.bind(id))
	
	webrtc_peer.add_peer(pc, id)
	
	if id < webrtc_peer.get_unique_id():
		# The other peer has lower ID (likely host), wait for offer
		pass
	else:
		# We have lower ID (likely host), create offer
		pc.create_offer()
		
	# Update participants info. In a real game, you might RPC names over.
	_participants.append({"user_id": str(id), "username": "プレイヤー " + str(id)})
	player_connected.emit(id)
	
	var my_name = Global.player_name if Global.player_name != "" else "あなた"
	sync_player_info.rpc_id(id, my_name)
	
	# If we are guest and a peer connected, emit room_joined with updated participants if needed
	if not _is_host:
		room_joined.emit(true, _participants)

func _on_peer_disconnected(id: int) -> void:
	if webrtc_peer and webrtc_peer.has_peer(id):
		webrtc_peer.remove_peer(id)
	
	for i in range(_participants.size() - 1, -1, -1):
		if _participants[i]["user_id"] == str(id):
			_participants.remove_at(i)
	
	player_disconnected.emit(id)

func _on_session_description_created(type: String, sdp: String, id: int) -> void:
	var peer_dict = webrtc_peer.get_peer(id)
	if peer_dict and peer_dict.has("connection"):
		var pc = peer_dict["connection"] as WebRTCPeerConnection
		pc.set_local_description(type, sdp)
		if type == "offer":
			signaling.send_offer(id, sdp)
		else:
			signaling.send_answer(id, sdp)

func _on_ice_candidate_created(media: String, index: int, name: String, id: int) -> void:
	signaling.send_candidate(id, media, index, name)

func _on_offer_received(id: int, offer: String) -> void:
	var peer_dict = webrtc_peer.get_peer(id)
	if peer_dict and peer_dict.has("connection"):
		var pc = peer_dict["connection"] as WebRTCPeerConnection
		pc.set_remote_description("offer", offer)

func _on_answer_received(id: int, answer: String) -> void:
	var peer_dict = webrtc_peer.get_peer(id)
	if peer_dict and peer_dict.has("connection"):
		var pc = peer_dict["connection"] as WebRTCPeerConnection
		pc.set_remote_description("answer", answer)

func _on_ice_candidate_received(id: int, media: String, index: int, name: String) -> void:
	var peer_dict = webrtc_peer.get_peer(id)
	if peer_dict and peer_dict.has("connection"):
		var pc = peer_dict["connection"] as WebRTCPeerConnection
		pc.add_ice_candidate(media, index, name)
