class_name GameContext
extends RefCounted
## 共有状態とヘルパーを集約したコンテクストクラス。
## ゲームの各フェーズで共有されるデータと参照を保持します。

# メインとなるシーン参照
var game_scene: Control

# マネージャ類
var game_session
var audio_manager: AudioManager
var backend_manager

# UIルートノード
var ui_root: Control
var screen_content: Control

# カバン構築用の状態
var bag_assignments: Dictionary = {}
var bag_ui_elements: Dictionary = {}
var selected_bag_subject: int = 8
var selected_bag_slot: int = -1

# ビネット / UI状態
var vignette_overlay: Panel
var chikista_active_tab: int = 0
var active_notebook: PanelContainer
var heartbeat_tween: Tween

# ドラッグ＆ドロップ状態
var is_dragging: bool = false
var drag_data: Dictionary = {}
var drag_preview: Control = null
var hovered_slot_subject: int = -1
var hovered_slot_idx: int = -1

# チキンレース状態
var play_desk: Control
var card_container: Control
var drawn_card_nodes: Array = []
var status_label: Label
var hud_notebook: Control
var subject_gauges: Dictionary = {}
var item_count_labels: Dictionary = {}
var burst_warning_banner: Panel
var next_burst_label: Label
var button_box: HBoxContainer
var camera_shake_offset: Vector2 = Vector2.ZERO

func setup(scene: Control) -> void:
	game_scene = scene
	ui_root = scene.get_node_or_null("UIRoot")
	if not ui_root:
		ui_root = scene
	screen_content = scene.get_node_or_null("UIRoot/ScreenContent")
	if not screen_content:
		screen_content = scene.get_node_or_null("ScreenContent")
	if not screen_content:
		screen_content = scene
		
	if "audio_manager" in scene and scene.audio_manager != null:
		audio_manager = scene.audio_manager
	else:
		audio_manager = scene.get_node_or_null("/root/AudioManager")
		
	if "backend_manager" in scene and scene.backend_manager != null:
		backend_manager = scene.backend_manager
	else:
		backend_manager = scene.get_node_or_null("/root/BackendManager")
	
	# カバンデータの初期化 (デフォルトが空なら初期化)
	for s in range(5):
		if not bag_assignments.has(s):
			bag_assignments[s] = [null, null]
