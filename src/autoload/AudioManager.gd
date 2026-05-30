extends Node

# Audio assets preloaded
const BGM_MAIN = "res://assets/bgm_main.mp3"
const SE_CLICK = "res://assets/se_click.wav"
const SE_DRAW = "res://assets/se_draw.wav"
const SE_PLACE = "res://assets/se_place.wav"
const SE_COMBO = "res://assets/se_combo.wav"
const SE_BURST = "res://assets/se_burst.wav"

var bgm_player: AudioStreamPlayer
var se_players: Array[AudioStreamPlayer] = []
var max_se_channels: int = 8

# Sound settings (0.0 to 1.0)
var bgm_volume: float = 0.5:
	set(val):
		var new_val = clamp(val, 0.0, 1.0)
		if bgm_volume != new_val:
			bgm_volume = new_val
			_update_bgm_volume()
			if has_node("/root/Global") and is_inside_tree():
				var global = get_node("/root/Global")
				global.bgm_volume = bgm_volume
				global.save_game()
var se_volume: float = 0.5:
	set(val):
		var new_val = clamp(val, 0.0, 1.0)
		if se_volume != new_val:
			se_volume = new_val
			if has_node("/root/Global") and is_inside_tree():
				var global = get_node("/root/Global")
				global.se_volume = se_volume
				global.save_game()
var is_muted: bool = false:
	set(val):
		if is_muted != val:
			is_muted = val
			_update_bgm_volume()
			if has_node("/root/Global") and is_inside_tree():
				var global = get_node("/root/Global")
				global.is_muted = is_muted
				global.save_game()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep playing audio during pauses
	
	# Load volumes from Global first if they exist
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		# Set properties directly without causing save_game loop during ready
		bgm_volume = global.bgm_volume
		se_volume = global.se_volume
		is_muted = global.is_muted
	
	# Initialize BGM Player
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	# Initialize SE Players pool
	for i in range(max_se_channels):
		var p = AudioStreamPlayer.new()
		add_child(p)
		se_players.append(p)

func play_bgm(stream_path: String) -> void:
	if not ResourceLoader.exists(stream_path):
		return
		
	var stream = load(stream_path)
	if bgm_player.stream == stream and bgm_player.playing:
		return
		
	bgm_player.stream = stream
	_update_bgm_volume()
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func play_se(stream_path: String) -> void:
	if not ResourceLoader.exists(stream_path):
		return
		
	var stream = load(stream_path)
	
	# Find an available player in the pool
	var player: AudioStreamPlayer = null
	for p in se_players:
		if not p.playing:
			player = p
			break
			
	# If all playing, steal the oldest one
	if not player:
		player = se_players[0]
		
	player.stream = stream
	player.volume_db = linear_to_db(se_volume) if not is_muted else -80.0
	player.play()

func _update_bgm_volume() -> void:
	if not bgm_player:
		return
	if is_muted:
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = linear_to_db(bgm_volume)

# Helper function to convert 0.0-1.0 slider to db
func linear_to_db(linear_value: float) -> float:
	if linear_value <= 0.0001:
		return -80.0
	return 20.0 * log(linear_value) / log(10.0)
