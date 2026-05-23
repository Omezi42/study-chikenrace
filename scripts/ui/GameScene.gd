class_name GameScene
extends Control

const GameSessionScript = preload("res://scripts/core/GameSession.gd")
const BackendManagerScript = preload("res://scripts/core/BackendManager.gd")
const GameContextScript = preload("res://scripts/ui/context/GameContext.gd")
const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")
const BagBuilderPhaseScript = preload("res://scripts/ui/phases/BagBuilderPhase.gd")
const ChickenRacePhaseScript = preload("res://scripts/ui/phases/ChickenRacePhase.gd")
const ReportPhaseScript = preload("res://scripts/ui/phases/ReportPhase.gd")
const DayTransitionPhaseScript = preload("res://scripts/ui/phases/DayTransitionPhase.gd")
const DailyLikesPhaseScript = preload("res://scripts/ui/phases/DailyLikesPhase.gd")

var game_session
var audio_manager: AudioManager
var backend_manager
var game_context: RefCounted
var current_phase: RefCounted = null

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
	return NotebookBuilderScript.create()

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
	ui_root.name = "UIRoot"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)
	
	screen_content = Control.new()
	screen_content.name = "ScreenContent"
	screen_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(screen_content)
	
	# コンテクストの初期化
	game_context = GameContextScript.new()
	game_context.setup(self)
	# 既存の変数への参照を同期
	game_context.bag_assignments = bag_assignments
	game_context.bag_ui_elements = bag_ui_elements
	
	# バックエンドデータの初期ロード開始
	backend_manager.load_daily_scores()
	_show_loading()

func _process(delta):
	# 1. 視差効果（Parallax Drift - Sprint 3）の算出とカメラシェイクの適用
	var viewport = get_viewport()
	var shake_offset = Vector2.ZERO
	if is_instance_valid(game_context):
		shake_offset = game_context.camera_shake_offset
		
	if viewport:
		var mouse_pos = viewport.get_mouse_position()
		var screen_size = viewport.get_visible_rect().size
		if screen_size.x > 0 and screen_size.y > 0:
			# 画面中心からのマウス位置比率 (-0.5 〜 0.5)
			var ratio_x = (mouse_pos.x / screen_size.x) - 0.5
			var ratio_y = (mouse_pos.y / screen_size.y) - 0.5
			# 最大移動幅は15ピクセルで、高級感のある緩やかな動きに設定
			var target_parallax = Vector2(-ratio_x * 15.0, -ratio_y * 15.0)
			# 慣性スムーズ移動 (Lerp)
			var cur_p = get_meta("current_parallax", Vector2.ZERO)
			cur_p = cur_p.lerp(target_parallax, clamp(4.5 * delta, 0.0, 1.0))
			set_meta("current_parallax", cur_p)
			
			# 視差効果とシェイクを合成
			ui_root.position = cur_p + shake_offset
		else:
			ui_root.position = shake_offset
	else:
		ui_root.position = shake_offset

func _input(event):
	if current_phase and current_phase.has_method("_input"):
		current_phase._input(event)

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
	# データロードが完了したら最初の1日を開始
	_start_new_day_setup()

func _start_new_day_setup():
	# セッションがなければ新規作成
	if not is_instance_valid(game_session):
		game_session = GameSessionScript.new()
		add_child(game_session)
		game_context.game_session = game_session
		game_session.setup_session()
	else:
		# 既存セッションを新しい日向けにリセット
		game_session.start_new_day()
		
	_start_phase_bag_builder()

func _clear_screen():
	for child in screen_content.get_children():
		child.queue_free()
	if is_instance_valid(vignette_overlay):
		vignette_overlay.queue_free()

func _on_chikista_tab_pressed(tab_idx: int, scroll_container: ScrollContainer):
	SmartphoneBuilderScript.on_chikista_tab_pressed(game_context, tab_idx, scroll_container)

func _build_timeline_feed(feed_v: VBoxContainer):
	SmartphoneBuilderScript._build_timeline_feed(game_context, feed_v)

func _build_analysis_tab(feed_v: VBoxContainer):
	SmartphoneBuilderScript._build_analysis_tab(game_context, feed_v)

func _build_goals_tab(feed_v: VBoxContainer):
	SmartphoneBuilderScript._build_goals_tab(game_context, feed_v)

func _create_smartphone_mockup(_parent: Control, is_centered: bool = true) -> VBoxContainer:
	return SmartphoneBuilderScript.create_mockup(game_context, is_centered)

func _start_phase_bag_builder():
	var phase = BagBuilderPhaseScript.new(game_context)
	current_phase = phase
	phase.phase_completed.connect(_on_bag_builder_completed)
	phase.start()

func _on_bag_builder_completed():
	_animate_page_turn(_start_phase_chicken_race)

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
	
	# 右寄せされたノート（中心が150px右にシフト）に完全同期して配置
	paper_cover.position = Vector2(view.x / 2.0 + 150.0, (view.y - 920.0) / 2.0)
	paper_cover.pivot_offset = Vector2(0, 460) # 背表紙（左端）を支点にしてめくる
	paper_cover.scale = Vector2(1.0, 1.0)
	
	ui_root.add_child(paper_cover)
	if audio_manager: audio_manager.play_se("place") # ササッという紙音
	
	var tw = paper_cover.create_tween()
	# 1. ページを閉じる (Xスケール 1 -> 0)
	tw.tween_property(paper_cover, "scale:x", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		callback.call() # 背後で画面をロード・切り替え
		# ピボットを逆側（右端）にして展開する（同じく150px右にシフトした位置から展開）
		paper_cover.position = Vector2(view.x / 2.0 + 150.0 - 690.0, (view.y - 920.0) / 2.0)
		paper_cover.pivot_offset = Vector2(690, 460)
	)
	# 2. ページを開く (Xスケール 0 -> 1)
	tw.tween_property(paper_cover, "scale:x", 1.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(paper_cover.queue_free)

func _show_toast(msg: String, color: Color = DeskTheme.COLOR_INK):
	ToastOverlayScript.show_toast(ui_root, msg, color)
# ----------------------------------------------------
# 3. 【チキンレース】HUDノート ＆ 机の上プレイエリア
# ----------------------------------------------------
func _start_phase_chicken_race():
	var phase = ChickenRacePhaseScript.new(game_context)
	current_phase = phase
	phase.phase_completed.connect(_on_chicken_race_completed)
	phase.start()

func _on_chicken_race_completed(_scores_data: Dictionary):
	if is_instance_valid(game_session) and game_session.current_hour < 3:
		# 3時間目未満なら次の時間へ
		game_session.current_hour += 1
		# 次の時間の準備（アイテム選択）へループ
		_animate_page_turn(_start_phase_bag_builder)
	else:
		# 3時間がすべて終了したら学習報告へ
		_show_report_screen(_scores_data)

func _show_report_screen(scores: Dictionary):
	var phase = ReportPhaseScript.new(game_context)
	current_phase = phase
	phase.phase_completed.connect(_on_report_completed)
	phase.start(scores)

func _on_report_completed():
	_show_daily_likes()

func _show_daily_likes():
	var phase = DailyLikesPhaseScript.new(game_context)
	current_phase = phase
	phase.phase_completed.connect(_on_daily_likes_completed)
	phase.start()

func _on_daily_likes_completed():
	_show_day_transition()

func _show_day_transition():
	var phase = DayTransitionPhaseScript.new(game_context)
	current_phase = phase
	phase.phase_completed.connect(_on_day_transition_completed)
	phase.start()

func _on_day_transition_completed():
	_start_new_day_setup()
