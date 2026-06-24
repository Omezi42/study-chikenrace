extends Node

var signaling: WebRTCSignaling
var webrtc_multiplayer: WebRTCMultiplayerService

func _ready() -> void:
	signaling = WebRTCSignaling.new()
	add_child(signaling)
	
	webrtc_multiplayer = WebRTCMultiplayerService.new(self, signaling)
	add_child(webrtc_multiplayer)

func get_uuid() -> String:
	# Local anonymous UUID generator for WebRTC
	var id = str(randi_range(1000000, 9999999))
	return id
