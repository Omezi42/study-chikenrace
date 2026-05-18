class_name GameScene
extends Control

const GameSessionScript = preload("res://scripts/core/GameSession.gd")
const BackendManagerScript = preload("res://scripts/core/BackendManager.gd")

var game_session
var audio_manager: AudioManager
var backend_manager
var game_context: GameContext

var ui_root: Control
var screen_content: Control

# カバン構築用の変数
var bag_assignments: Dictionary = {} # subj -> [w1, w2]
var bag_ui_elements: Dictionary = {}
var vignette_overlay: Panel
var chikista_active_tab: int = 0
var active_notebook: PanelContainer
var heartbeat_tween: Tween
var camera_shake_offset: Vector2 = Vector2.ZERO

func _create_double_page_notebook() -> PanelContainer:
	return NotebookBuilder.create()

func _ready():
	# 各種マネージャーのインスタンス化
	audio_manager = AudioManager.new()
	add_child(audio_manager)
	
	backend_manager = BackendManagerScript.new()
	add_child(backend_manager)
	backend_manager.scores_loaded.connect(_on_scores_loaded)
	
	# 背景とベースUIの構築
	DeskTheme.decorate_scene(self)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)
	
	screen_content = Control.new()
	screen_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(screen_content)
	
	# コンテクストの初期化
	game_context = GameContext.new()
	game_context.setup(self)
	# 既存の変数への参照を同期
	game_context.bag_assignments = bag_assignments
	game_context.bag_ui_elements = bag_ui_elements
	
	# バックエンドデータの初期ロード開始
	backend_manager.load_scores()
	_show_loading()

func _process(_delta):
	# カメラシェイクの適用
	if ui_root:
		ui_root.position = camera_shake_offset
		


func _show_loading():
	_clear_screen()
	var loading_lbl = DeskTheme.create_label("データを読み込み中...", 24, DeskTheme.COLOR_INK, true)
	loading_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	screen_content.add_child(loading_lbl)
	
	# ボヨヨンアニメーション
	var tw = loading_lbl.create_tween().set_loops()
	tw.tween_property(loading_lbl, "position:y", loading_lbl.position.y - 15, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(loading_lbl, "position:y", loading_lbl.position.y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_scores_loaded(_scores = []):
	# データロードが完了したらカバン構築フェーズを開始
	_start_phase_bag_builder()

func _clear_screen():
	for child in screen_content.get_children():
		child.queue_free()
	drawn_card_nodes.clear()
	if is_instance_valid(vignette_overlay):
		vignette_overlay.queue_free()

func _on_chikista_tab_pressed(tab_idx: int, scroll_container: ScrollContainer):
	SmartphoneBuilder.on_chikista_tab_pressed(game_context, tab_idx, scroll_container)

func _build_timeline_feed(feed_v: VBoxContainer):
	SmartphoneBuilder._build_timeline_feed(game_context, feed_v)

func _build_analysis_tab(feed_v: VBoxContainer):
	SmartphoneBuilder._build_analysis_tab(game_context, feed_v)

func _build_goals_tab(feed_v: VBoxContainer):
	SmartphoneBuilder._build_goals_tab(game_context, feed_v)

func _create_smartphone_mockup(parent: Control, is_centered: bool = true) -> VBoxContainer:
	return SmartphoneBuilder.create_mockup(game_context, is_centered)

func _start_phase_bag_builder():
	var phase = BagBuilderPhase.new(game_context)
	phase.phase_completed.connect(_on_bag_builder_completed)
	phase.start()

func _on_bag_builder_completed():
	_on_start_race_pressed()

func _on_start_race_pressed():
	if audio_manager: audio_manager.play_se("click")
	var weights = {}
	var placed_count = 0
	for s in range(5):
		weights[s] = []
		for v in bag_assignments[s]:
			if v != null:
				weights[s].append(v)
				placed_count += 1
	if placed_count < 10:
		_show_toast("すべてのポケットに付箋を入れてね！", DeskTheme.COLOR_BLUFF_RED)
		return
	# 古いセッションノードのメモリクリーンアップ
	if is_instance_valid(game_session):
		game_session.queue_free()
	# セッション開始
	game_session = GameSessionScript.new()
	add_child(game_session)
	game_session.setup_session(weights)
	_animate_page_turn(_show_race_screen)

func _animate_page_turn(callback: Callable):
	# おもちゃ感あふれるノートの「ページめくり」トランジション
	var view = get_viewport_rect().size
	if view.x < 100 or view.y < 100:
		view = Vector2(1920.0, 1080.0)
		
	# 一時的なめくり用紙カバー（片ページ分）を生成
	var paper_cover = Panel.new()
	paper_cover.custom_minimum_size = Vector2(690, 920)
	paper_cover.size = Vector2(690, 920)
	var pc_style = StyleBoxFlat.new()
	pc_style.bg_color = Color("fdfbf7") # ノート用紙と同じベージュ
	pc_style.corner_radius_top_left = 8; pc_style.corner_radius_top_right = 8
	pc_style.corner_radius_bottom_left = 8; pc_style.corner_radius_bottom_right = 8
	pc_style.shadow_color = Color(0, 0, 0, 0.18)
	pc_style.shadow_size = 12
	paper_cover.add_theme_stylebox_override("panel", pc_style)
	
	# ビューポート中央に配置
	paper_cover.position = Vector2(view.x / 2.0, (view.y - 920.0) / 2.0)
	paper_cover.pivot_offset = Vector2(0, 460) # 背表紙（左端）を支点にしてめくる
	paper_cover.scale = Vector2(1.0, 1.0)
	
	ui_root.add_child(paper_cover)
	if audio_manager: audio_manager.play_se("place") # ササッという紙音
	
	var tw = paper_cover.create_tween()
	# 1. ページを閉じる (Xスケール 1 -> 0)
	tw.tween_property(paper_cover, "scale:x", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		callback.call() # 背後で画面をロード・切り替え
		# ピボットを逆側（右端）にして展開する
		paper_cover.position = Vector2(view.x / 2.0 - 690.0, (view.y - 920.0) / 2.0)
		paper_cover.pivot_offset = Vector2(690, 460)
	)
	# 2. ページを開く (Xスケール 0 -> 1)
	tw.tween_property(paper_cover, "scale:x", 1.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(paper_cover.queue_free)

func _show_toast(msg: String, color: Color = DeskTheme.COLOR_INK):
	ToastOverlay.show_toast(ui_root, msg, color)
# ----------------------------------------------------
# 3. 【チキンレース】HUDノート ＆ 机の上プレイエリア
# ----------------------------------------------------
func _start_phase_chicken_race():
	var phase = ChickenRacePhase.new(game_context)
	phase.phase_completed.connect(_on_chicken_race_completed)
	phase.start()

func _on_chicken_race_completed(_scores_data: Dictionary):
	var final_scores = game_session.get_today_results()
	_show_report_screen(final_scores)

func _show_report_screen(scores: Dictionary):
	var phase = ReportPhase.new(game_context)
	phase.phase_completed.connect(_on_report_completed)
	phase.start(scores)

func _on_report_completed():
	_show_day_transition()

func _show_day_transition():
	var phase = DayTransitionPhase.new(game_context)
	phase.phase_completed.connect(_on_day_transition_completed)
	phase.start()

func _on_day_transition_completed():
	_start_phase_bag_builder()

func _show_blackboard_progress():
	var phase = BlackboardPhase.new(game_context)
	phase.phase_completed.connect(_on_blackboard_completed)
	phase.start()

func _on_blackboard_completed():
	backend_manager.load_daily_scores()
	_show_loading()

