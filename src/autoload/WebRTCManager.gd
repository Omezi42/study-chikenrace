extends Node

signal connection_lost
signal reconnect_succeeded
signal reconnect_failed

var signaling: WebRTCSignaling
var webrtc_multiplayer: WebRTCMultiplayerService

func _ready() -> void:
	signaling = WebRTCSignaling.new()
	signaling.name = "WebRTCSignaling"
	add_child(signaling)
	
	webrtc_multiplayer = WebRTCMultiplayerService.new(self, signaling)
	webrtc_multiplayer.name = "WebRTCMultiplayerService"
	add_child(webrtc_multiplayer)
	
	signaling.disconnected_from_server.connect(func(): connection_lost.emit())
	multiplayer.server_disconnected.connect(func(): connection_lost.emit())

func get_uuid() -> String:
	# Local anonymous UUID generator for WebRTC
	var id = str(randi_range(1000000, 9999999))
	return id

func disconnect_room() -> void:
	if webrtc_multiplayer:
		webrtc_multiplayer.disconnect_room()

