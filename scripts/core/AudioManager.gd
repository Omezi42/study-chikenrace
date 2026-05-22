class_name AudioManager
extends Node

var bgm_player: AudioStreamPlayer

# Sprint 8: SE再生プール（複数SEの同時再生をサポート）
var se_pool: Array[AudioStreamPlayer] = []
var se_pool_size: int = 4
var se_pool_index: int = 0

var bgm_stream: AudioStream
var se_draw: AudioStream
var se_burst: AudioStream
var se_click: AudioStream
var se_place: AudioStream
var se_combo: AudioStream

func _ready():
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.volume_db = -10.0
	
	# Sprint 8: SEプール初期化（4つのプレイヤーを用意して同時再生対応）
	for i in range(se_pool_size):
		var sp = AudioStreamPlayer.new()
		add_child(sp)
		se_pool.append(sp)
	
	if ResourceLoader.exists("res://assets/bgm_main.wav"):
		bgm_stream = load("res://assets/bgm_main.wav")
		bgm_player.stream = bgm_stream
		bgm_player.play()
		
	if ResourceLoader.exists("res://assets/se_draw.wav"):
		se_draw = load("res://assets/se_draw.wav")
	if ResourceLoader.exists("res://assets/se_burst.wav"):
		se_burst = load("res://assets/se_burst.wav")
	if ResourceLoader.exists("res://assets/se_click.wav"):
		se_click = load("res://assets/se_click.wav")
	if ResourceLoader.exists("res://assets/se_place.wav"):
		se_place = load("res://assets/se_place.wav")
	if ResourceLoader.exists("res://assets/se_combo.wav"):
		se_combo = load("res://assets/se_combo.wav")

func play_se(type: String):
	var stream: AudioStream = null
	var pitch = 1.0
	var vol = 0.0
	match type:
		"draw": stream = se_draw
		"burst":
			stream = se_burst
			pitch = 1.3 # ピッチをコミカルな高さにして怖さを緩和
			vol = -5.0 # 音量を下げてマイルドにする
		"click": stream = se_click
		"place": 
			stream = se_place
			pitch = randf_range(0.9, 1.1)
		"hover": stream = se_click
		"combo": 
			stream = se_combo if se_combo else se_place
			pitch = randf_range(1.1, 1.3)
	
	if stream:
		# Sprint 8: プールから空いてるプレイヤーを選ぶ（ラウンドロビン）
		var player = se_pool[se_pool_index]
		se_pool_index = (se_pool_index + 1) % se_pool_size
		player.stream = stream
		player.pitch_scale = pitch
		player.volume_db = vol
		player.play()
