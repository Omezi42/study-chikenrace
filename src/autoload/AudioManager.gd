extends Node

# Audio assets preloaded
const BGM_MAIN = "res://assets/bgm_main.mp3"
const BGM_TITLE = "res://assets/bgm_title.wav"
const BGM_GAME = "res://assets/コミカルマリンバ.mp3"
const BGM_TENSE = "res://assets/bgm_tense.mp3"
const BGM_RESULT = "res://assets/Sunrise.mp3"

const SE_CLICK = "res://assets/se_click.wav"
const SE_DRAW = "res://assets/se_draw.wav"
const SE_PLACE = "res://assets/se_place.wav"
const SE_COMBO = "res://assets/se_combo.wav"
const SE_BURST = "res://assets/se_burst.wav"
const SE_SUCCESS = "res://assets/se_combo.wav"

const SE_HOVER = "res://assets/se_hover.wav"
const SE_WHOOSH = "res://assets/se_whoosh.wav"
const SE_TENSION = "res://assets/se_tension.wav"
const SE_FANFARE = "res://assets/se_fanfare.wav"
const SE_DRUMROLL = "res://assets/se_drumroll.ogg"

var bgm_player: AudioStreamPlayer
var bgm_player2: AudioStreamPlayer # For crossfading
var active_bgm_player: AudioStreamPlayer
var se_players: Array[AudioStreamPlayer] = []
var max_se_channels: int = 16

var ui_players: Array[AudioStreamPlayer] = []
var max_ui_channels: int = 8

# Resource caching dictionary
var _cached_streams: Dictionary = {}

var bgm_bus_idx: int
var se_bus_idx: int
var ui_bus_idx: int
var master_bus_idx: int

var current_bgm_path: String = ""

# Sound settings (0.0 to 1.0)
var bgm_volume: float = 0.5:
	set(val):
		var new_val = clamp(val, 0.0, 1.0)
		if bgm_volume != new_val:
			bgm_volume = new_val
			_update_bus_volumes()
			if has_node("/root/Global") and is_inside_tree():
				var global = get_node("/root/Global")
				global.bgm_volume = bgm_volume
				
var se_volume: float = 0.5:
	set(val):
		var new_val = clamp(val, 0.0, 1.0)
		if se_volume != new_val:
			se_volume = new_val
			_update_bus_volumes()
			if has_node("/root/Global") and is_inside_tree():
				var global = get_node("/root/Global")
				global.se_volume = se_volume
				
var is_muted: bool = false:
	set(val):
		if is_muted != val:
			is_muted = val
			_update_bus_volumes()
			if has_node("/root/Global") and is_inside_tree():
				var global = get_node("/root/Global")
				global.is_muted = is_muted

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep playing audio during pauses
	
	bgm_bus_idx = AudioServer.get_bus_index("BGM")
	se_bus_idx = AudioServer.get_bus_index("SE")
	ui_bus_idx = AudioServer.get_bus_index("UI")
	master_bus_idx = AudioServer.get_bus_index("Master")
	
	# Load volumes from Global first if they exist
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		bgm_volume = global.bgm_volume
		se_volume = global.se_volume
		is_muted = global.is_muted
		
	_update_bus_volumes()
	
	# Cache main streams to avoid runtime loading lag
	var streams_to_cache = [BGM_MAIN, BGM_TITLE, BGM_GAME, BGM_TENSE, BGM_RESULT, SE_CLICK, SE_DRAW, SE_PLACE, SE_COMBO, SE_BURST, SE_HOVER, SE_WHOOSH, SE_TENSION, SE_FANFARE, SE_DRUMROLL, SE_SUCCESS]
	for path in streams_to_cache:
		if ResourceLoader.exists(path):
			_cached_streams[path] = load(path)
	
	# Initialize BGM Players (two for crossfading)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
	add_child(bgm_player)
	
	bgm_player2 = AudioStreamPlayer.new()
	bgm_player2.bus = "BGM"
	add_child(bgm_player2)
	active_bgm_player = bgm_player
	
	# Initialize SE Players pool
	for i in range(max_se_channels):
		var p = AudioStreamPlayer.new()
		p.bus = "SE"
		add_child(p)
		se_players.append(p)
		
	# Initialize UI Players pool
	for i in range(max_ui_channels):
		var p = AudioStreamPlayer.new()
		p.bus = "UI"
		add_child(p)
		ui_players.append(p)

func play_bgm(stream_path: String, crossfade_duration: float = 1.0) -> void:
	if current_bgm_path == stream_path and active_bgm_player.playing:
		return
		
	var stream: AudioStream = null
	if _cached_streams.has(stream_path):
		stream = _cached_streams[stream_path]
	elif ResourceLoader.exists(stream_path):
		stream = load(stream_path)
		_cached_streams[stream_path] = stream
		
	if not stream:
		return
		
	current_bgm_path = stream_path
	
	# Select the next player
	var next_player = bgm_player2 if active_bgm_player == bgm_player else bgm_player
	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()
	
	if crossfade_duration > 0 and active_bgm_player.playing:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(active_bgm_player, "volume_db", -80.0, crossfade_duration)
		tween.tween_property(next_player, "volume_db", 0.0, crossfade_duration)
		tween.chain().tween_callback(active_bgm_player.stop)
	else:
		active_bgm_player.stop()
		next_player.volume_db = 0.0
		
	active_bgm_player = next_player

func stop_bgm(fade_out_duration: float = 1.0) -> void:
	if fade_out_duration > 0 and active_bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(active_bgm_player, "volume_db", -80.0, fade_out_duration)
		tween.tween_callback(active_bgm_player.stop)
	else:
		active_bgm_player.stop()
	current_bgm_path = ""

func play_se(stream_path: String, random_pitch_variance: float = 0.0, volume_db_offset: float = 0.0) -> void:
	var stream: AudioStream = null
	if _cached_streams.has(stream_path):
		stream = _cached_streams[stream_path]
	elif ResourceLoader.exists(stream_path):
		stream = load(stream_path)
		_cached_streams[stream_path] = stream
		
	if not stream:
		return
		
	var player: AudioStreamPlayer = null
	for p in se_players:
		if not p.playing:
			player = p
			break
			
	if not player:
		player = se_players[0]
		
	player.stream = stream
	player.volume_db = volume_db_offset
	
	if random_pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-random_pitch_variance, random_pitch_variance)
	else:
		player.pitch_scale = 1.0
		
	player.play()

func play_ui(stream_path: String, random_pitch_variance: float = 0.0) -> void:
	var stream: AudioStream = null
	if _cached_streams.has(stream_path):
		stream = _cached_streams[stream_path]
	elif ResourceLoader.exists(stream_path):
		stream = load(stream_path)
		_cached_streams[stream_path] = stream
		
	if not stream:
		return
		
	var player: AudioStreamPlayer = null
	for p in ui_players:
		if not p.playing:
			player = p
			break
			
	if not player:
		player = ui_players[0]
		
	player.stream = stream
	if random_pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-random_pitch_variance, random_pitch_variance)
	else:
		player.pitch_scale = 1.0
		
	player.play()

func set_bgm_pitch(pitch: float) -> void:
	active_bgm_player.pitch_scale = pitch

func play_ui_hover() -> void:
	play_ui(SE_HOVER, 0.1)

func _update_bus_volumes() -> void:
	if is_muted:
		AudioServer.set_bus_mute(master_bus_idx, true)
	else:
		AudioServer.set_bus_mute(master_bus_idx, false)
		AudioServer.set_bus_volume_db(bgm_bus_idx, linear_to_db(bgm_volume))
		AudioServer.set_bus_volume_db(se_bus_idx, linear_to_db(se_volume * (10.0 / 7.0)))
		AudioServer.set_bus_volume_db(ui_bus_idx, linear_to_db(se_volume * (10.0 / 7.0))) # share volume setting with SE for now

func linear_to_db(linear_value: float) -> float:
	if linear_value <= 0.0001:
		return -80.0
	return 20.0 * log(linear_value) / log(10.0)
