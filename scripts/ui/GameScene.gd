class_name GameScene
extends Control

const GameSessionScript = preload("res://scripts/core/GameSession.gd")
const BackendManagerScript = preload("res://scripts/core/BackendManager.gd")

var game_session
var audio_manager: AudioManager
var backend_manager

var ui_root: Control
var screen_content: Control

# カバン構築用の変数
var bag_assignments: Dictionary = {} # subj -> [w1, w2]
var bag_ui_elements: Dictionary = {}
var selected_bag_subject: int = 8
var selected_bag_slot: int = -1

# 瞼の代わりに周辺ビネット/睡魔警告ビネット
var vignette_overlay: Panel
var chikista_active_tab: int = 0
var active_notebook: PanelContainer
var heartbeat_tween: Tween


# ドラッグ＆ドロップ用変数
var is_dragging: bool = false
var drag_data: Dictionary = {}
var drag_preview: Control = null
var hovered_slot_subject: int = -1
var hovered_slot_idx: int = -1

# チキンレース用の変数
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

func _create_double_page_notebook() -> PanelContainer:
	var root = PanelContainer.new()
	root.custom_minimum_size = Vector2(1260, 920)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var root_style = StyleBoxEmpty.new()
	root.add_theme_stylebox_override("panel", root_style)
	
	# ドロップシャドウ用の巨大パネル
	var shadow = Panel.new()
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left = 12; shadow.offset_top = 16; shadow.offset_right = -12; shadow.offset_bottom = -16
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.06, 0.04, 0.02, 0.24)
	shadow_style.corner_radius_top_left = 24; shadow_style.corner_radius_top_right = 24
	shadow_style.corner_radius_bottom_left = 24; shadow_style.corner_radius_bottom_right = 24
	shadow_style.shadow_color = Color(0, 0, 0, 0.2)
	shadow_style.shadow_size = 20
	shadow.add_theme_stylebox_override("panel", shadow_style)
	root.add_child(shadow)
	
	# ノート見開き外枠（表紙の厚み部分、少しはみ出る茶色の革）
	var cover = Panel.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cover_style = StyleBoxFlat.new()
	cover_style.bg_color = Color("8c6d4f") # 温かみのある革バインダーの茶色
	cover_style.corner_radius_top_left = 20; cover_style.corner_radius_top_right = 20
	cover_style.corner_radius_bottom_left = 20; cover_style.corner_radius_bottom_right = 20
	cover_style.border_width_left = 4; cover_style.border_width_right = 4
	cover_style.border_width_top = 4; cover_style.border_width_bottom = 4
	cover_style.border_color = Color("5c4033")
	cover.add_theme_stylebox_override("panel", cover_style)
	root.add_child(cover)
	
	# ノート本体の見開き用紙（HBoxContainer）
	var pages_hbox = HBoxContainer.new()
	pages_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages_hbox.add_theme_constant_override("separation", 0)
	pages_hbox.offset_left = 10; pages_hbox.offset_top = 10; pages_hbox.offset_right = -10; pages_hbox.offset_bottom = -10
	root.add_child(pages_hbox)
	
	# 左ページ (用紙)
	var left_page = PanelContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lp_style = StyleBoxFlat.new()
	lp_style.bg_color = Color("fdfbf7") # キャンパスノートの温かみのある白（僅かに黄み）
	lp_style.corner_radius_top_left = 16; lp_style.corner_radius_bottom_left = 16
	left_page.add_theme_stylebox_override("panel", lp_style)
	pages_hbox.add_child(left_page)
	
	# 左ページ罫線描画用のコンテナ
	var left_lines = Control.new()
	left_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_page.add_child(left_lines)
	
	# 左ページに情緒ある手書き落書きを追加
	var doodle_left_coffee = CozyDoodleNode.new(0, Color("8c6d4f", 0.07)) # 薄いコーヒー染み
	doodle_left_coffee.position = Vector2(10, 720) # 左下
	left_lines.add_child(doodle_left_coffee)
	
	var doodle_left_star = CozyDoodleNode.new(1, Color("5c5340", 0.12)) # 手書きの星と渦
	doodle_left_star.position = Vector2(500, 40) # 右上
	left_lines.add_child(doodle_left_star)
	
	# 赤い縦のマージン線
	var left_red_line = ColorRect.new()
	left_red_line.color = Color("ffcccc", 0.7)
	left_red_line.custom_minimum_size = Vector2(1.5, 0)
	left_red_line.anchor_bottom = 1.0
	left_red_line.offset_left = 54
	left_lines.add_child(left_red_line)
	# 青い横罫線
	for i in range(1, 23):
		var y = i * 38 + 18
		var line = ColorRect.new()
		line.color = Color("e0eaf5", 0.6) # 薄い水色罫線
		line.custom_minimum_size = Vector2(0, 1)
		line.anchor_right = 1.0
		line.offset_top = y
		left_lines.add_child(line)
		
	var left_margin = MarginContainer.new()
	left_margin.name = "LeftContent"
	left_margin.add_theme_constant_override("margin_left", 64)
	left_margin.add_theme_constant_override("margin_top", 32)
	left_margin.add_theme_constant_override("margin_right", 24)
	left_margin.add_theme_constant_override("margin_bottom", 24)
	left_page.add_child(left_margin)
	
	# 中央バインダー / リング
	var spine = Control.new()
	spine.custom_minimum_size = Vector2(48, 0)
	spine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages_hbox.add_child(spine)
	
	# 背表紙の黒いスリット影
	var spine_shadow = ColorRect.new()
	spine_shadow.color = Color("0f0c08", 0.15)
	spine_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spine.add_child(spine_shadow)
	
	# リアルなスチールリングを縦に並べる
	var rings_v = VBoxContainer.new()
	rings_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rings_v.alignment = BoxContainer.ALIGNMENT_CENTER
	rings_v.add_theme_constant_override("separation", 28)
	spine.add_child(rings_v)
	for r in range(18):
		var ring = Panel.new()
		ring.custom_minimum_size = Vector2(28, 12)
		ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var ring_style = StyleBoxFlat.new()
		ring_style.bg_color = Color("b0b8c0") # スチールシルバー
		ring_style.border_width_left = 1; ring_style.border_width_right = 1
		ring_style.border_width_top = 2; ring_style.border_width_bottom = 2
		ring_style.border_color = Color("404850") # リングの影
		ring_style.corner_radius_top_left = 6; ring_style.corner_radius_top_right = 6
		ring_style.corner_radius_bottom_left = 6; ring_style.corner_radius_bottom_right = 6
		ring_style.shadow_color = Color(1, 1, 1, 0.4)
		ring_style.shadow_size = 2
		ring.add_theme_stylebox_override("panel", ring_style)
		rings_v.add_child(ring)
		
	# 右ページ (用紙)
	var right_page = PanelContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rp_style = StyleBoxFlat.new()
	rp_style.bg_color = Color("fdfbf7")
	rp_style.corner_radius_top_right = 16; rp_style.corner_radius_bottom_right = 16
	right_page.add_theme_stylebox_override("panel", rp_style)
	pages_hbox.add_child(right_page)
	
	# 右ページ罫線
	var right_lines = Control.new()
	right_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_page.add_child(right_lines)
	
	# 右ページに手書き落書きを追加
	var doodle_right_spiral = CozyDoodleNode.new(2, Color("4b5c70", 0.12)) # 手書きのうずまき
	doodle_right_spiral.position = Vector2(40, 80) # 左上
	right_lines.add_child(doodle_right_spiral)
	
	var doodle_right_tally = CozyDoodleNode.new(3, Color("b24c4c", 0.14)) # 赤ペンで書いた「正」の字（勉強の記録感）
	doodle_right_tally.position = Vector2(540, 750) # 右下
	right_lines.add_child(doodle_right_tally)
	
	# 赤い縦のマージン線
	var right_red_line = ColorRect.new()
	right_red_line.color = Color("ffcccc", 0.7)
	right_red_line.custom_minimum_size = Vector2(1.5, 0)
	right_red_line.anchor_bottom = 1.0
	right_red_line.offset_left = 54
	right_lines.add_child(right_red_line)
	# 青い横罫線
	for i in range(1, 23):
		var y = i * 38 + 18
		var line = ColorRect.new()
		line.color = Color("e0eaf5", 0.6)
		line.custom_minimum_size = Vector2(0, 1)
		line.anchor_right = 1.0
		line.offset_top = y
		right_lines.add_child(line)
		
	var right_margin = MarginContainer.new()
	right_margin.name = "RightContent"
	right_margin.add_theme_constant_override("margin_left", 64)
	right_margin.add_theme_constant_override("margin_top", 32)
	right_margin.add_theme_constant_override("margin_right", 24)
	right_margin.add_theme_constant_override("margin_bottom", 24)
	right_page.add_child(right_margin)
	
	return root

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
	
	# バックエンドデータの初期ロード開始
	backend_manager.load_scores()
	_show_loading()

func _process(_delta):
	# カメラシェイクの適用
	if ui_root:
		ui_root.position = camera_shake_offset
		
	# ドラッグプレビューの追従とスロットホバー判定の更新
	if is_dragging and is_instance_valid(drag_preview):
		drag_preview.global_position = get_global_mouse_position() - Vector2(55, 55)
		_update_drag_hover()

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
	# データロードが完了したらメインハブ（カバン構築画面）を表示
	_show_bag_builder()

func _clear_screen():
	for child in screen_content.get_children():
		child.queue_free()
	drawn_card_nodes.clear()
	if is_instance_valid(vignette_overlay):
		vignette_overlay.queue_free()

func _on_chikista_tab_pressed(tab_idx: int, scroll_container: ScrollContainer):
	if chikista_active_tab == tab_idx: return
	if audio_manager: audio_manager.play_se("click")
	chikista_active_tab = tab_idx
	
	var tw = scroll_container.create_tween()
	tw.tween_property(scroll_container, "modulate:a", 0.0, 0.08)
	tw.tween_callback(func():
		for child in scroll_container.get_children():
			child.queue_free()
		var feed_v = VBoxContainer.new()
		feed_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		feed_v.add_theme_constant_override("separation", 10)
		scroll_container.add_child(feed_v)
		
		if tab_idx == 0:
			_build_timeline_feed(feed_v)
		elif tab_idx == 1:
			_build_analysis_tab(feed_v)
		elif tab_idx == 2:
			_build_goals_tab(feed_v)
	)
	tw.tween_property(scroll_container, "modulate:a", 1.0, 0.1)

func _build_timeline_feed(feed_v: VBoxContainer):
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 8)
	margin_c.add_theme_constant_override("margin_top", 8)
	margin_c.add_theme_constant_override("margin_right", 8)
	margin_c.add_theme_constant_override("margin_bottom", 8)
	feed_v.add_child(margin_c)
	
	var cards_v = VBoxContainer.new()
	cards_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_v.add_theme_constant_override("separation", 10)
	margin_c.add_child(cards_v)
	
	# 📢 チキスタ公式お知らせTIPSバナー (オンボーディング強化)
	var tips_banner = PanelContainer.new()
	var tips_style = StyleBoxFlat.new()
	tips_style.bg_color = Color("e8f4fd") # アプリ風の水色トーン
	tips_style.corner_radius_top_left = 10; tips_style.corner_radius_top_right = 10
	tips_style.corner_radius_bottom_left = 10; tips_style.corner_radius_bottom_right = 10
	tips_style.content_margin_left = 10; tips_style.content_margin_right = 10
	tips_style.content_margin_top = 8; tips_style.content_margin_bottom = 8
	tips_banner.add_theme_stylebox_override("panel", tips_style)
	cards_v.add_child(tips_banner)
	
	var tips_v = VBoxContainer.new()
	tips_v.add_theme_constant_override("separation", 4)
	tips_banner.add_child(tips_v)
	
	tips_v.add_child(DeskTheme.create_label("📢 チキスタ運営事務局", 16, Color("1da1f2"), true))
	var tips_msg = DeskTheme.create_label("ライバルの勉強報告に【👍 いいね！】を送ってプレッシャーを与えましょう！もし相手が嘘の報告（ブラフ）をしていたら、翌朝に比例ペナルティ（減点）で大ダメージを喰らわせられます！", 14, DeskTheme.COLOR_INK)
	tips_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_v.add_child(tips_msg)
	
	# ライバルたちの昨日の報告タイムライン生成
	var timelines = backend_manager.get_timeline_feeds()
	
	# ランキング化（合計スコアが高い順に降順ソート）
	timelines.sort_custom(func(a, b):
		var sum_a = 0
		for s in a["scores"]: sum_a += a["scores"][s]
		var sum_b = 0
		for s in b["scores"]: sum_b += b["scores"][s]
		return sum_a > sum_b
	)
	if timelines.size() == 0:
		cards_v.add_child(DeskTheme.create_label("タイムラインが空です。\nライバルの登校を待っています...", 16, DeskTheme.COLOR_MUTED, true))
	
	var rank_idx = 1
	for entry in timelines:
		var rival_name = entry["name"]
		var scores = entry["scores"] # Dictionary of s -> reported score
		var actuals = entry.get("actual_scores", {})
		
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color("ffffff") # 白いフィードカード
		card_style.corner_radius_top_left = 12; card_style.corner_radius_top_right = 12
		card_style.corner_radius_bottom_left = 12; card_style.corner_radius_bottom_right = 12
		card_style.content_margin_left = 16; card_style.content_margin_right = 16
		card_style.content_margin_top = 16; card_style.content_margin_bottom = 16
		card_style.shadow_color = Color(0,0,0, 0.05)
		card_style.shadow_size = 4
		card.add_theme_stylebox_override("panel", card_style)
		cards_v.add_child(card)
		
		var card_v = VBoxContainer.new()
		card_v.add_theme_constant_override("separation", 10)
		card.add_child(card_v)
		
		# ヘッダー (アバターと名前と順位)
		var user_h = HBoxContainer.new()
		user_h.add_theme_constant_override("separation", 12)
		card_v.add_child(user_h)
		
		var rank_color = DeskTheme.COLOR_INK
		if rank_idx == 1: rank_color = DeskTheme.COLOR_ACCENT_GOLD
		elif rank_idx == 2: rank_color = Color("a0aab2") # 銀
		elif rank_idx == 3: rank_color = Color("cd7f32") # 銅
		var rank_str = "👑 1位" if rank_idx == 1 else "%d位" % rank_idx
		var rank_lbl = DeskTheme.create_label(rank_str, 16, rank_color, true)
		rank_lbl.custom_minimum_size = Vector2(50, 0)
		user_h.add_child(rank_lbl)
		rank_idx += 1
		
		var avatar = ColorRect.new()
		avatar.custom_minimum_size = Vector2(40, 40)
		var av_style = StyleBoxFlat.new()
		av_style.bg_color = DeskTheme.COLOR_NOTE_DARK
		av_style.corner_radius_top_left = 20; av_style.corner_radius_top_right = 20
		av_style.corner_radius_bottom_left = 20; av_style.corner_radius_bottom_right = 20
		avatar.add_theme_stylebox_override("panel", av_style)
		user_h.add_child(avatar)
		var av_lbl = DeskTheme.create_label(rival_name.left(1), 18, Color.WHITE, true)
		av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		av_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		avatar.add_child(av_lbl)
		
		user_h.add_child(DeskTheme.create_label(rival_name, 18, DeskTheme.COLOR_INK, true))
		
		var body_v = VBoxContainer.new()
		body_v.add_theme_constant_override("separation", 8)
		card_v.add_child(body_v)
		
		# 各教科の報告
		var is_bluffing = false
		for s in range(5):
			var reported_val = scores.get(s, 0)
			var actual_val = actuals.get(s, reported_val) # なければ報告値と同じとする
			
			if reported_val > actual_val:
				is_bluffing = true
			
			var s_row = HBoxContainer.new()
			s_row.alignment = BoxContainer.ALIGNMENT_BEGIN
			body_v.add_child(s_row)
			
			var name_h = HBoxContainer.new()
			name_h.add_theme_constant_override("separation", 6)
			s_row.add_child(name_h)
			name_h.add_child(DeskTheme.create_icon_rect(DeskTheme.subject_texture(s), Vector2(24, 24)))
			name_h.add_child(DeskTheme.create_label("%s: %d点" % [DeskTheme.subject_name(s), reported_val], 15, DeskTheme.COLOR_INK))
			
		# 全体いいね！ボタン (すでに投票済なら disabled)
		var like_h = HBoxContainer.new()
		like_h.alignment = BoxContainer.ALIGNMENT_CENTER
		body_v.add_child(like_h)
		
		var already_voted = backend_manager.has_voted_rival(rival_name, -1)
		var like_btn = DeskTheme.create_button(
			"👍 全体いいね！済" if already_voted else "👍 報告全体にいいね！", 
			Vector2(220, 40), 
			Color("3897f0") if not already_voted else Color("a0c0e0"), 
			Color("1070c0") if not already_voted else Color("90b0d0"),
			false,
			14
		)
		like_btn.disabled = already_voted
		like_h.add_child(like_btn)
		
		# スタンプ用のコンテナ
		var stamp_container = Control.new()
		stamp_container.custom_minimum_size = Vector2(70, 24)
		like_h.add_child(stamp_container)
		
		var create_stamp = func(bluff: bool):
			var stamp = PanelContainer.new()
			var stamp_style = StyleBoxFlat.new()
			stamp_style.bg_color = Color("ff6b6b" if bluff else "4dabf7")
			stamp_style.border_width_left = 2; stamp_style.border_width_right = 2
			stamp_style.border_width_top = 2; stamp_style.border_width_bottom = 3
			stamp_style.border_color = Color("c92a2a" if bluff else "1c7ed6")
			stamp_style.corner_radius_top_left = 4; stamp_style.corner_radius_top_right = 4
			stamp_style.corner_radius_bottom_left = 4; stamp_style.corner_radius_bottom_right = 4
			stamp_style.content_margin_left = 8; stamp_style.content_margin_right = 8
			stamp_style.content_margin_top = 3; stamp_style.content_margin_bottom = 3
			stamp.add_theme_stylebox_override("panel", stamp_style)
			var stamp_lbl = DeskTheme.create_label("👍 疑い！" if bluff else "👍 応援！", 12, Color.WHITE, true)
			stamp.add_child(stamp_lbl)
			return stamp
			
		if already_voted:
			var stamp = create_stamp.call(is_bluffing)
			stamp.rotation = randf_range(-0.1, 0.1)
			stamp_container.add_child(stamp)
			
		like_btn.pressed.connect(func():
			if backend_manager.has_voted_rival(rival_name, -1): return
			backend_manager.vote_rival(rival_name, -1)
			like_btn.disabled = true
			like_btn.text = "👍 全体いいね！済"
			var style_v = like_btn.get_theme_stylebox("normal").duplicate()
			style_v.bg_color = Color("a0c0e0")
			like_btn.add_theme_stylebox_override("normal", style_v)
			
			var btn_tw = like_btn.create_tween()
			btn_tw.tween_property(like_btn, "scale", Vector2(1.05, 1.05), 0.06).set_trans(Tween.TRANS_CUBIC)
			btn_tw.tween_property(like_btn, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_BACK)
			
			var stamp = create_stamp.call(is_bluffing)
			stamp_container.add_child(stamp)
			stamp.pivot_offset = Vector2(30, 10)
			stamp.scale = Vector2(3.0, 3.0)
			stamp.modulate.a = 0.0
			stamp.rotation = randf_range(-0.15, 0.15)
			
			var stamp_tw = stamp.create_tween().set_parallel(true)
			stamp_tw.tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			stamp_tw.tween_property(stamp, "modulate:a", 1.0, 0.1)
			
			if audio_manager:
				audio_manager.play_se('place')
			
			if is_bluffing:
				_show_toast('💢 いいね！で見破りのプレッシャーを送った！', DeskTheme.COLOR_BLUFF_RED)
			else:
				_show_toast('👍 いいね！で正直な努力を応援！\n(相手に正直ボーナス！)', DeskTheme.COLOR_SAFE)
		)

func _build_analysis_tab(feed_v: VBoxContainer):
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 8)
	margin_c.add_theme_constant_override("margin_top", 8)
	margin_c.add_theme_constant_override("margin_right", 8)
	margin_c.add_theme_constant_override("margin_bottom", 8)
	feed_v.add_child(margin_c)
	
	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 12)
	margin_c.add_child(cv)
	
	cv.add_child(DeskTheme.create_label("📊 週次学習成果分析", 15, DeskTheme.COLOR_INK, true))
	
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("ffffff")
	card_style.corner_radius_top_left = 12; card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12; card_style.corner_radius_bottom_right = 12
	card_style.content_margin_left = 12; card_style.content_margin_right = 12
	card_style.content_margin_top = 12; card_style.content_margin_bottom = 12
	card_style.shadow_color = Color(0,0,0, 0.05)
	card_style.shadow_size = 4
	card.add_theme_stylebox_override("panel", card_style)
	cv.add_child(card)
	
	var list_v = VBoxContainer.new()
	list_v.add_theme_constant_override("separation", 10)
	card.add_child(list_v)
	
	list_v.add_child(DeskTheme.create_label("📈 教科別進捗 (目標20点)", 12, DeskTheme.COLOR_MUTED))
	
	for s in range(5):
		var score = randi_range(6, 18)
		if is_instance_valid(game_session):
			score = game_session.subject_scores[s]
			
		var row = VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		list_v.add_child(row)
		
		var info = HBoxContainer.new()
		row.add_child(info)
		info.add_child(DeskTheme.create_icon_rect(DeskTheme.subject_texture(s), Vector2(16, 16)))
		info.add_child(DeskTheme.create_label(DeskTheme.subject_name(s) + ": ", 11, DeskTheme.COLOR_INK))
		info.add_child(DeskTheme.create_label(str(score) + "点", 11, DeskTheme.subject_color(s), true))
		
		var progress = DeskTheme.create_gauge_bar(score, 20.0, DeskTheme.subject_color(s), Vector2(260, 10))
		row.add_child(progress)

func _build_goals_tab(feed_v: VBoxContainer):
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 8)
	margin_c.add_theme_constant_override("margin_top", 8)
	margin_c.add_theme_constant_override("margin_right", 8)
	margin_c.add_theme_constant_override("margin_bottom", 8)
	feed_v.add_child(margin_c)
	
	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 12)
	margin_c.add_child(cv)
	
	cv.add_child(DeskTheme.create_label("🎯 目標と獲得バッジ", 15, DeskTheme.COLOR_INK, true))
	
	# 学生証風UI
	var id_card = PanelContainer.new()
	var id_style = StyleBoxFlat.new()
	id_style.bg_color = Color("2b5c8f")
	id_style.corner_radius_top_left = 12; id_style.corner_radius_top_right = 12
	id_style.corner_radius_bottom_left = 12; id_style.corner_radius_bottom_right = 12
	id_style.content_margin_left = 14; id_style.content_margin_right = 14
	id_style.content_margin_top = 14; id_style.content_margin_bottom = 14
	id_card.add_theme_stylebox_override("panel", id_style)
	cv.add_child(id_card)
	
	var iv = VBoxContainer.new()
	iv.add_theme_constant_override("separation", 8)
	id_card.add_child(iv)
	
	iv.add_child(DeskTheme.create_label("🏫 テスト勉強中学 学生証", 12, Color.WHITE, true))
	
	var det = HBoxContainer.new()
	det.add_theme_constant_override("separation", 12)
	iv.add_child(det)
	
	var photo = ColorRect.new()
	photo.custom_minimum_size = Vector2(40, 50)
	photo.color = Color.WHITE
	det.add_child(photo)
	
	var photo_lbl = DeskTheme.create_label("🧑‍🎓", 20, Color.BLACK, true)
	photo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	photo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	photo_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	photo.add_child(photo_lbl)
	
	var info = VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	det.add_child(info)
	info.add_child(DeskTheme.create_label("氏名: プレイヤー", 12, Color.WHITE))
	info.add_child(DeskTheme.create_label("学籍番号: No.2026-0518", 10, Color("a0c0e0")))
	info.add_child(DeskTheme.create_label("総合スコア: %d 点" % Global.total_score, 11, DeskTheme.COLOR_ACCENT_GOLD, true))
	
	# バッジグリッド
	cv.add_child(DeskTheme.create_label("🏆 獲得バッジ", 12, DeskTheme.COLOR_MUTED))
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	cv.add_child(grid)
	
	var badges = [
		{"name": "チキン王", "unlocked": Global.total_score > 50, "tint": Color("ffd700")},
		{"name": "正直者", "unlocked": true, "tint": Color("4ecdc4")},
		{"name": "大ホラ吹き", "unlocked": false, "tint": Color("ff6b6b")},
		{"name": "謙虚な紳士", "unlocked": Global.total_score > 30, "tint": Color("a29bfe")},
		{"name": "寝落ち達人", "unlocked": true, "tint": Color("74b9ff")},
	]
	
	for b in badges:
		var badge_panel = PanelContainer.new()
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = b["tint"] if b["unlocked"] else Color("dfe6e9")
		b_style.corner_radius_top_left = 8; b_style.corner_radius_top_right = 8
		b_style.corner_radius_bottom_left = 8; b_style.corner_radius_bottom_right = 8
		b_style.content_margin_left = 6; b_style.content_margin_right = 6
		b_style.content_margin_top = 4; b_style.content_margin_bottom = 4
		badge_panel.add_theme_stylebox_override("panel", b_style)
		grid.add_child(badge_panel)
		
		var b_lbl = DeskTheme.create_label(b["name"], 9, Color.WHITE if b["unlocked"] else Color("636e72"), true)
		badge_panel.add_child(b_lbl)

func _create_smartphone_mockup(parent: Control, is_centered: bool = true) -> VBoxContainer:
	var phone = PanelContainer.new()
	phone.custom_minimum_size = Vector2(400, 840)
	phone.size = Vector2(400, 840)
	
	# アンカー競合を回避し、常に安定したピクセル座標で配置・Tweenする設計
	phone.anchor_left = 0.0; phone.anchor_top = 0.0; phone.anchor_right = 0.0; phone.anchor_bottom = 0.0
	if is_centered:
		phone.position = Vector2(760, 70)
		phone.rotation_degrees = 0.0
		phone.scale = Vector2(1.32, 1.32)
	else:
		phone.position = Vector2(88, 300)
		phone.rotation_degrees = -1.2
		phone.scale = Vector2(0.8, 0.8)
		
	phone.pivot_offset = Vector2(200, 420)
	phone.z_index = 100
	
	var dim_overlay = Button.new()
	dim_overlay.flat = true
	dim_overlay.custom_minimum_size = Vector2(1920, 1080)
	dim_overlay.visible = false
	dim_overlay.z_index = 99
	
	var dim_style = StyleBoxFlat.new()
	dim_style.bg_color = Color(0, 0, 0, 0.65)
	dim_overlay.add_theme_stylebox_override("normal", dim_style)
	dim_overlay.add_theme_stylebox_override("hover", dim_style)
	dim_overlay.add_theme_stylebox_override("pressed", dim_style)
	dim_overlay.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var pickup_overlay = Button.new()
	pickup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pickup_overlay.flat = true
	pickup_overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pickup_overlay.z_index = 101
	if is_centered: pickup_overlay.hide()
	
	phone.set_meta("is_picked_up", is_centered)
	var orig_pos = Vector2(88, 300) if not is_centered else Vector2(760, 70)
	var orig_rot = phone.rotation_degrees
	
	var put_down = func():
		if not phone.get_meta("is_picked_up", false): return
		phone.set_meta("is_picked_up", false)
		pickup_overlay.show()
		if audio_manager: audio_manager.play_se("place")
		var tw = phone.create_tween().set_parallel(true)
		tw.tween_property(phone, "position", orig_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(phone, "rotation_degrees", orig_rot, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(phone, "scale", Vector2(1.32, 1.32) if is_centered else Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		var tw_dim = dim_overlay.create_tween()
		tw_dim.tween_property(dim_overlay, "modulate:a", 0.0, 0.2)
		tw_dim.tween_callback(func(): dim_overlay.hide())
		
	var pick_up = func():
		if phone.get_meta("is_picked_up", false): return
		phone.set_meta("is_picked_up", true)
		pickup_overlay.hide()
		if audio_manager: audio_manager.play_se("draw")
		
		dim_overlay.modulate.a = 0.0
		dim_overlay.show()
		var tw_dim = dim_overlay.create_tween()
		tw_dim.tween_property(dim_overlay, "modulate:a", 1.0, 0.2)
		
		var tw = phone.create_tween().set_parallel(true)
		# スマホの拡大率をさらに上げ、適度な余白で全体を美しく収める最適サイズ（1.32倍/Y=70px）
		var target_scale = 1.32
		var target_pos = Vector2(760, 70)
		tw.tween_property(phone, "position", target_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(phone, "rotation_degrees", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(phone, "scale", Vector2(target_scale, target_scale), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	dim_overlay.pressed.connect(func():
		put_down.call()
	)
	
	pickup_overlay.pressed.connect(func():
		pick_up.call()
	)
		
	# スマホ本体の黒ベゼルスタイル
	var phone_style = StyleBoxFlat.new()
	phone_style.bg_color = Color("202225") # 高級感あるダークブラック
	phone_style.corner_radius_top_left = 36; phone_style.corner_radius_top_right = 36
	phone_style.corner_radius_bottom_left = 36; phone_style.corner_radius_bottom_right = 36
	phone_style.border_width_left = 14; phone_style.border_width_top = 40
	phone_style.border_width_right = 14; phone_style.border_width_bottom = 40
	phone_style.border_color = Color("0f1011") # ベゼル枠
	phone_style.shadow_color = Color(0, 0, 0, 0.45)
	phone_style.shadow_size = 28
	phone_style.shadow_offset = Vector2(12, 20)
	phone.add_theme_stylebox_override("panel", phone_style)
	screen_content.add_child(dim_overlay)
	# add_child された後に anchors と size / position を確実に再計算して画面全体をカバーさせる（Godotの重要なお作法）
	dim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_overlay.size = Vector2(1920, 1080)
	dim_overlay.position = Vector2.ZERO
	
	screen_content.add_child(phone)
	
	bag_ui_elements["report_page"] = phone # 提出済スタンプをスマホの上に押すために保持
	
	# スマホ上部ノッチ
	var notch = Panel.new()
	notch.custom_minimum_size = Vector2(100, 18)
	notch.anchor_left = 0.5; notch.anchor_right = 0.5
	notch.offset_left = -50; notch.offset_top = -32; notch.offset_right = 50; notch.offset_bottom = -14
	var notch_style = StyleBoxFlat.new()
	notch_style.bg_color = Color("0a0a0b")
	notch_style.corner_radius_bottom_left = 10; notch_style.corner_radius_bottom_right = 10
	notch.add_theme_stylebox_override("panel", notch_style)
	phone.add_child(notch)
	
	# スマホ画面コンテンツ
	var app_container = VBoxContainer.new()
	app_container.add_theme_constant_override("separation", 0)
	DeskTheme.apply_font(app_container)
	phone.add_child(app_container)
	
	# 0. リアルなスマホステータスバー
	var status_bar = PanelContainer.new()
	status_bar.custom_minimum_size = Vector2(0, 22)
	var sb_style = StyleBoxFlat.new()
	sb_style.bg_color = Color("ffffff")
	sb_style.content_margin_left = 16; sb_style.content_margin_right = 16
	status_bar.add_theme_stylebox_override("panel", sb_style)
	app_container.add_child(status_bar)
	
	var sb_hbox = HBoxContainer.new()
	sb_hbox.alignment = BoxContainer.ALIGNMENT_END
	status_bar.add_child(sb_hbox)
	
	var time_lbl = DeskTheme.create_label("16:40 ", 10, DeskTheme.COLOR_MUTED)
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sb_hbox.add_child(time_lbl)
	
	var status_info = DeskTheme.create_label("LTE   [ 98% ]", 10, DeskTheme.COLOR_MUTED)
	sb_hbox.add_child(status_info)
	
	# スマホ本体のタップ判定ボタンのみをスマホの一番手前に追加
	phone.add_child(pickup_overlay)
	
	DeskTheme.animate_entrance(phone)
	return app_container

func _show_bag_builder():
	_clear_screen()
	
	bag_assignments.clear()
	for s in range(5):
		bag_assignments[s] = [null, null]
	
	# メインの横分割コンテナ (左: チキスタスマホ / 右: リングノート)
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 40)
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_left = 40; main_hbox.offset_top = 40; main_hbox.offset_right = -40; main_hbox.offset_bottom = -40
	screen_content.add_child(main_hbox)
	
	# ==========================================
	# 左側: 教室 of 机に置かれた「スマートフォン (チキスタアプリ)」
	# ==========================================
	var phone_container = Control.new()
	phone_container.custom_minimum_size = Vector2(400, 0)
	phone_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(phone_container)
	
	var app_container = _create_smartphone_mockup(phone_container, false)
	
	# 1. アプリヘッダー
	var app_header = PanelContainer.new()
	app_header.custom_minimum_size = Vector2(0, 52)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("ffffff")
	header_style.border_width_bottom = 2
	header_style.border_color = Color("e1e4e6")
	app_header.add_theme_stylebox_override("panel", header_style)
	app_container.add_child(app_header)
	
	var app_header_h = HBoxContainer.new()
	app_header_h.add_theme_constant_override("separation", 8)
	app_header_h.alignment = BoxContainer.ALIGNMENT_CENTER
	app_header.add_child(app_header_h)
	
	var app_icon = ColorRect.new()
	app_icon.custom_minimum_size = Vector2(28, 28)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = DeskTheme.COLOR_SAFE
	icon_style.corner_radius_top_left = 8; icon_style.corner_radius_top_right = 8
	icon_style.corner_radius_bottom_left = 8; icon_style.corner_radius_bottom_right = 8
	app_icon.add_theme_stylebox_override("panel", icon_style)
	app_header_h.add_child(app_icon)
	
	var app_icon_lbl = DeskTheme.create_label("S", 14, Color.WHITE)
	app_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app_icon.add_child(app_icon_lbl)
	
	var app_title = DeskTheme.create_label("チキスタ !", 18, DeskTheme.COLOR_SAFE, true)
	app_header_h.add_child(app_title)
	
	# 2. アプリ内メインスクロールエリア
	var app_scroll = ScrollContainer.new()
	app_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app_container.add_child(app_scroll)
	
	# 初期のタイムライン表示
	var feed_v = VBoxContainer.new()
	feed_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_v.add_theme_constant_override("separation", 10)
	app_scroll.add_child(feed_v)
	chikista_active_tab = 0
	_build_timeline_feed(feed_v)
	
	# 3. ボトムナビゲーションバー (大拡張)
	var app_footer = PanelContainer.new()
	app_footer.custom_minimum_size = Vector2(0, 60)
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = Color("f8f9fa")
	footer_style.border_width_top = 2
	footer_style.border_color = Color("e1e4e6")
	app_footer.add_theme_stylebox_override("panel", footer_style)
	app_container.add_child(app_footer)
	
	var app_footer_h = HBoxContainer.new()
	app_footer_h.alignment = BoxContainer.ALIGNMENT_CENTER
	app_footer_h.add_theme_constant_override("separation", 16)
	app_footer.add_child(app_footer_h)
	
	var tabs_info = [
		{"text": "タイムライン", "idx": 0},
		{"text": "学習分析", "idx": 1},
		{"text": "目標", "idx": 2}
	]
	
	for tab in tabs_info:
		var tab_btn = Button.new()
		tab_btn.text = tab["text"]
		tab_btn.custom_minimum_size = Vector2(110, 48)
		tab_btn.add_theme_font_override("font", DeskTheme.DEFAULT_FONT)
		tab_btn.add_theme_font_size_override("font_size", 13)
		tab_btn.add_theme_color_override("font_color", DeskTheme.COLOR_MUTED)
		
		# クリーンでシンプルなボタンスタイル
		var b_normal = StyleBoxFlat.new()
		b_normal.bg_color = Color(0,0,0,0)
		b_normal.corner_radius_top_left = 8; b_normal.corner_radius_top_right = 8
		b_normal.corner_radius_bottom_left = 8; b_normal.corner_radius_bottom_right = 8
		tab_btn.add_theme_stylebox_override("normal", b_normal)
		
		var b_hover = StyleBoxFlat.new()
		b_hover.bg_color = Color(0.9, 0.9, 0.92, 0.5)
		b_hover.corner_radius_top_left = 8; b_hover.corner_radius_top_right = 8
		b_hover.corner_radius_bottom_left = 8; b_hover.corner_radius_bottom_right = 8
		tab_btn.add_theme_stylebox_override("hover", b_hover)
		
		var b_pressed = StyleBoxFlat.new()
		b_pressed.bg_color = Color(0.85, 0.85, 0.88)
		b_pressed.corner_radius_top_left = 8; b_pressed.corner_radius_top_right = 8
		b_pressed.corner_radius_bottom_left = 8; b_pressed.corner_radius_bottom_right = 8
		tab_btn.add_theme_stylebox_override("pressed", b_pressed)
		
		tab_btn.pressed.connect(_on_chikista_tab_pressed.bind(tab["idx"], app_scroll))
		app_footer_h.add_child(tab_btn)
		
	# ==========================================
	# 右側: カバン構築用 見開きリングノートUI
	# ==========================================
	var note_panel = _create_double_page_notebook()
	active_notebook = note_panel
	main_hbox.add_child(note_panel)
	
	var left_margin = note_panel.find_child("LeftContent", true, false) as MarginContainer
	var right_margin = note_panel.find_child("RightContent", true, false) as MarginContainer
	
	# ---------------- Left Page Content ----------------
	var left_content = VBoxContainer.new()
	left_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_content.add_theme_constant_override("separation", 24)
	left_margin.add_child(left_content)
	
	# カレンダーと手書きヘッダー
	var cal_h = HBoxContainer.new()
	cal_h.add_theme_constant_override("separation", 16)
	left_content.add_child(cal_h)
	
	var cal_note = TextureRect.new()
	cal_note.texture = DeskTheme.CALENDAR_TEXTURE
	cal_note.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cal_note.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cal_note.custom_minimum_size = Vector2(90, 90)
	cal_note.rotation_degrees = -4.0
	cal_h.add_child(cal_note)
	
	var cal_v = VBoxContainer.new()
	cal_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cal_v.alignment = BoxContainer.ALIGNMENT_CENTER
	cal_v.position.y += 8
	cal_note.add_child(cal_v)
	cal_v.add_child(DeskTheme.create_label("Day", 15, DeskTheme.COLOR_MUTED, true))
	cal_v.add_child(DeskTheme.create_label(str(Global.play_count + 1), 38, Color("d94040"), true))
	
	var title_lbl = DeskTheme.create_label("📖 今週の学習計画ノート", 34, DeskTheme.COLOR_INK, true)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cal_h.add_child(title_lbl)
	
	# カバンスロットリスト（ ruled line layout ）
	var pockets_v = VBoxContainer.new()
	pockets_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pockets_v.add_theme_constant_override("separation", 26)
	left_content.add_child(pockets_v)
	
	bag_ui_elements["slots"] = {}
	for s in range(5):
		var pocket_h = HBoxContainer.new()
		pocket_h.add_theme_constant_override("separation", 16)
		pockets_v.add_child(pocket_h)
		
		# 教科チップ（巨大化して視認性をアップ！）
		var p_header = DeskTheme.create_stat_chip(DeskTheme.subject_name(s), DeskTheme.subject_color(s), 18)
		p_header.custom_minimum_size = Vector2(92, 44)
		pocket_h.add_child(p_header)
		
		var icon = DeskTheme.create_icon_rect(DeskTheme.subject_texture(s), Vector2(44, 44))
		pocket_h.add_child(icon)
		
		# 手書き風の罫線スロット（左ページいっぱいに大きく表示！）
		var slot_btns = []
		for i in range(2):
			var slot_btn = Button.new()
			slot_btn.custom_minimum_size = Vector2(150, 88)
			
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color("ffffff", 0.8)
			btn_style.border_width_left = 2; btn_style.border_width_right = 2
			btn_style.border_width_top = 2; btn_style.border_width_bottom = 4
			btn_style.border_color = DeskTheme.COLOR_MUTED
			btn_style.corner_radius_top_left = 8; btn_style.corner_radius_top_right = 8
			btn_style.corner_radius_bottom_left = 8; btn_style.corner_radius_bottom_right = 8
			slot_btn.add_theme_stylebox_override("normal", btn_style)
			slot_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			slot_btn.add_theme_font_size_override("font_size", 32)
			slot_btn.add_theme_font_override("font", DeskTheme.DEFAULT_FONT)
			
			slot_btn.pressed.connect(_on_bag_slot_pressed.bind(s, i))
			slot_btn.gui_input.connect(_on_slot_gui_input.bind(s, i))
			pocket_h.add_child(slot_btn)
			slot_btns.append(slot_btn)
			
			# ホバー時のボヨヨン拡大
			slot_btn.pivot_offset = Vector2(75, 44)
			slot_btn.mouse_entered.connect(func():
				slot_btn.pivot_offset = slot_btn.size / 2.0
				var tw = slot_btn.create_tween()
				tw.tween_property(slot_btn, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			)
			slot_btn.mouse_exited.connect(func():
				var tw = slot_btn.create_tween()
				tw.tween_property(slot_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			)
			
		bag_ui_elements["slots"][s] = slot_btns
		
	# ---------------- Right Page Content ----------------
	var right_content = VBoxContainer.new()
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_content.add_theme_constant_override("separation", 20)
	right_margin.add_child(right_content)
	
	# 右ページヘッダー
	var rp_header = VBoxContainer.new()
	rp_header.add_theme_constant_override("separation", 6)
	right_content.add_child(rp_header)
	
	rp_header.add_child(DeskTheme.create_label("📌 数字付箋パレット", 32, DeskTheme.COLOR_INK, true))
	rp_header.add_child(DeskTheme.create_label("付箋をタップ（またはドラッグ）して左ページのスロットに貼ろう！", 16, DeskTheme.COLOR_MUTED, true))
	
	# カラフルな付箋パレットトレイ (GridContainer)
	var grid_center = CenterContainer.new()
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_content.add_child(grid_center)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	grid_center.add_child(grid)
	
	bag_ui_elements["weights"] = {}
	var postit_colors = [
		Color("ffd43b"), # 鮮やかなネオンイエロー
		Color("ff6b6b"), # 鮮やかなパステルレッド
		Color("339af0"), # 鮮やかなスカイブルー
		Color("51cf66"), # 鮮やかなライムグリーン
		Color("cc5de8"), # 鮮やかなパープル
		Color("ff922b"), # 鮮やかなネオンオレンジ
		Color("f06595"), # 鮮やかなピンク
		Color("20c997"), # 鮮やかなミントグリーン
		Color("5c7cfa"), # 鮮やかなロイヤルブルー
		Color("845ef7")  # 鮮やかなバイオレット
	]
	
	for w in range(1, 11):
		var btn = Button.new()
		btn.text = str(w)
		btn.custom_minimum_size = Vector2(110, 110)
		btn.add_theme_font_override("font", DeskTheme.DEFAULT_FONT)
		btn.add_theme_font_size_override("font_size", 42)
		btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		btn.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
		btn.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)
		btn.add_theme_color_override("font_disabled_color", Color("868e96"))
		
		# 付箋（Post-it）風のStyleBoxFlat
		var sticky_style = StyleBoxFlat.new()
		var postit_col = postit_colors[w - 1]
		sticky_style.bg_color = postit_col
		sticky_style.corner_radius_top_left = 2; sticky_style.corner_radius_top_right = 2
		sticky_style.corner_radius_bottom_left = 6; sticky_style.corner_radius_bottom_right = 6
		sticky_style.shadow_color = Color(0, 0, 0, 0.16)
		sticky_style.shadow_size = 6
		sticky_style.shadow_offset = Vector2(2, 4)
		btn.add_theme_stylebox_override("normal", sticky_style)
		
		# ホバー/プレススタイル
		var sticky_hov = sticky_style.duplicate()
		sticky_hov.bg_color = postit_col.lightened(0.06)
		sticky_hov.shadow_size = 10
		btn.add_theme_stylebox_override("hover", sticky_hov)
		
		var sticky_prs = sticky_style.duplicate()
		sticky_prs.bg_color = postit_col.darkened(0.06)
		sticky_prs.shadow_size = 3
		btn.add_theme_stylebox_override("pressed", sticky_prs)
		
		btn.pressed.connect(_on_bag_weight_pressed.bind(w))
		btn.gui_input.connect(_on_weight_gui_input.bind(w))
		grid.add_child(btn)
		
		# 傾きをランダムにして机の上に貼られたリアル感を出す！
		btn.pivot_offset = Vector2(55, 55)
		btn.rotation_degrees = randf_range(-6.0, 6.0)
		
		bag_ui_elements["weights"][w] = btn
		
		# 付箋のプルプルおもちゃホバーリアクション
		btn.mouse_entered.connect(func():
			if btn.disabled: return
			btn.pivot_offset = btn.size / 2.0
			var random_rot = randf_range(-0.06, 0.06)
			var tw = btn.create_tween().set_parallel(true)
			tw.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.08).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(btn, "rotation", random_rot, 0.1).set_trans(Tween.TRANS_BACK)
		)
		btn.mouse_exited.connect(func():
			var tw = btn.create_tween().set_parallel(true)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(btn, "rotation", deg_to_rad(btn.rotation_degrees), 0.1).set_trans(Tween.TRANS_CUBIC)
		)
		
	# 右ページ下部の開始ボタン（ハンコ風スタンプ）
	var footer_center = CenterContainer.new()
	right_content.add_child(footer_center)
	var start_btn = DeskTheme.create_button("チキンレース開始！", Vector2(280, 64), DeskTheme.COLOR_SAFE, Color("2d928a"))
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.pressed.connect(_on_start_race_pressed)
	footer_center.add_child(start_btn)
	
	bag_ui_elements["start_btn"] = start_btn
	bag_ui_elements["was_all_placed"] = false
	bag_ui_elements["bonus_given"] = false
	
	DeskTheme.animate_entrance(note_panel)
	selected_bag_subject = 8
	selected_bag_slot = -1
	_update_bag_ui()
	
	get_tree().create_timer(0.5).timeout.connect(_trigger_daily_likes_sequence)

func _on_bag_slot_pressed(subject: int, slot: int):
	if audio_manager: audio_manager.play_se("click")
	selected_bag_subject = subject
	selected_bag_slot = slot
	_update_bag_ui()
func _on_bag_weight_pressed(weight: int):
	# 重複割り当ての自動除去
	_remove_weight_from_assignments(weight)
	var target_subject = selected_bag_subject
	var target_slot = selected_bag_slot
	if target_subject != 8 and target_slot != -1:
		# スロットが選択されている場合、そこへ配置
		bag_assignments[target_subject][target_slot] = weight
		# ノートがポヨンと跳ねるTweenアニメーション
		var slot_btn = bag_ui_elements["slots"][target_subject][target_slot] as Control
		slot_btn.pivot_offset = slot_btn.size / 2.0
		var tw = slot_btn.create_tween()
		tw.tween_property(slot_btn, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(slot_btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK)
		selected_bag_subject = 8
		selected_bag_slot = -1
	else:
		# スロット未選択の場合、空いている最初のスロットにオートアサイン！
		var assigned = false
		for s in range(5):
			for i in range(2):
				if bag_assignments[s][i] == null:
					bag_assignments[s][i] = weight
					assigned = true
					# 自動配置されたスロットを極上ボヨヨンTween！
					var slot_btn = bag_ui_elements["slots"][s][i] as Control
					slot_btn.pivot_offset = slot_btn.size / 2.0
					var tw = slot_btn.create_tween()
					tw.tween_property(slot_btn, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_CUBIC)
					tw.tween_property(slot_btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BOUNCE)
					break
			if assigned: break
	if audio_manager: audio_manager.play_se("place")
	_update_bag_ui()
# ====================================================
# ドラッグ＆ドロップ (D&D) 操作ロジック
# ====================================================
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_threshold: float = 10.0
var has_dragged: bool = false
func _on_weight_gui_input(event: InputEvent, weight: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start_pos = event.global_position
			drag_data = { "type": "weight", "value": weight, "source": "tray" }
			has_dragged = false
		else:
			if is_dragging:
				_end_drag()
			elif drag_data.size() > 0:
				# ドラッグ閾値未満なら通常のタップとして機能させる
				_on_bag_weight_pressed(weight)
				drag_data.clear()
	elif event is InputEventMouseMotion and drag_data.size() > 0 and not is_dragging:
		if event.global_position.distance_to(drag_start_pos) > drag_threshold:
			_start_drag(drag_data["value"], "tray")
func _on_slot_gui_input(event: InputEvent, subject: int, slot: int):
	var current_weight = bag_assignments[subject][slot]
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start_pos = event.global_position
			if current_weight != null:
				drag_data = { "type": "weight", "value": current_weight, "source": "slot", "subject": subject, "slot": slot }
			else:
				drag_data.clear()
			has_dragged = false
		else:
			if is_dragging:
				_end_drag()
			elif drag_data.size() > 0:
				# 通常のタップ処理
				_on_bag_slot_pressed(subject, slot)
				drag_data.clear()
	elif event is InputEventMouseMotion and drag_data.size() > 0 and not is_dragging:
		if event.global_position.distance_to(drag_start_pos) > drag_threshold:
			_start_drag(drag_data["value"], "slot", drag_data["subject"], drag_data["slot"])
func _start_drag(value: int, source: String, subject: int = -1, slot: int = -1):
	is_dragging = true
	has_dragged = true
	if audio_manager: audio_manager.play_se("click")
	
	var postit_colors = [
		Color("ffd43b"), # 鮮やかなネオンイエロー
		Color("ff6b6b"), # 鮮やかなパステルレッド
		Color("339af0"), # 鮮やかなスカイブルー
		Color("51cf66"), # 鮮やかなライムグリーン
		Color("cc5de8"), # 鮮やかなパープル
		Color("ff922b"), # 鮮やかなネオンオレンジ
		Color("f06595"), # 鮮やかなピンク
		Color("20c997"), # 鮮やかなミントグリーン
		Color("5c7cfa"), # 鮮やかなロイヤルブルー
		Color("845ef7")  # 鮮やかなバイオレット
	]
	var postit_col = postit_colors[value - 1]
	
	# ドラッグプレビュー用付箋の生成 (手書き風リアルサイズ・カラー同期)
	drag_preview = PanelContainer.new()
	drag_preview.custom_minimum_size = Vector2(110, 110)
	drag_preview.size = Vector2(110, 110)
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(postit_col.r, postit_col.g, postit_col.b, 0.82) # カラー同期＋心地よい半透明
	style.corner_radius_top_left = 2; style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 12
	style.shadow_offset = Vector2(4, 8)
	drag_preview.add_theme_stylebox_override("panel", style)
	
	var lbl = DeskTheme.create_label(str(value), 42, DeskTheme.COLOR_INK, true)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_preview.add_child(lbl)
	
	screen_content.add_child(drag_preview)
	drag_preview.global_position = get_global_mouse_position() - Vector2(55, 55)
	# ドラッグ元の付箋をプレビュー中は非表示にするか半透明にする
	if source == "slot" and subject != -1 and slot != -1:
		bag_ui_elements["slots"][subject][slot].modulate = Color(1, 1, 1, 0.3)
	elif source == "tray":
		bag_ui_elements["weights"][value].modulate = Color(1, 1, 1, 0.3)
func _update_drag_hover():
	var mouse_pos = get_global_mouse_position()
	var found_subject = -1
	var found_slot = -1
	# 全スロットとの当たり判定
	for s in range(5):
		for i in range(2):
			var slot_btn = bag_ui_elements["slots"][s][i] as Button
			if slot_btn.get_global_rect().has_point(mouse_pos):
				found_subject = s
				found_slot = i
				break
		if found_subject != -1: break
	# ハイライトの更新
	if found_subject != hovered_slot_subject or found_slot != hovered_slot_idx:
		# 古いハイライトを解除
		if hovered_slot_subject != -1 and hovered_slot_idx != -1:
			var old_btn = bag_ui_elements["slots"][hovered_slot_subject][hovered_slot_idx] as Button
			var style = old_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			style.border_color = DeskTheme.COLOR_MUTED
			style.border_width_bottom = 4
			old_btn.add_theme_stylebox_override("normal", style)
		hovered_slot_subject = found_subject
		hovered_slot_idx = found_slot
		# 新しいハイライトを適用 (机でサッカー風ゴールドハイライト)
		if hovered_slot_subject != -1 and hovered_slot_idx != -1:
			var new_btn = bag_ui_elements["slots"][hovered_slot_subject][hovered_slot_idx] as Button
			var style = new_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			style.border_color = DeskTheme.COLOR_ACCENT_GOLD
			style.border_width_bottom = 6 # 枠を少し太くしてアピール
			new_btn.add_theme_stylebox_override("normal", style)
			if audio_manager: audio_manager.play_se("place")
func _end_drag():
	is_dragging = false
	if is_instance_valid(drag_preview):
		drag_preview.queue_free()
	# ドラッグ元のモジュレーションを元に戻す
	if drag_data.get("source") == "slot":
		var s = drag_data["subject"]
		var idx = drag_data["slot"]
		bag_ui_elements["slots"][s][idx].modulate = Color.WHITE
	elif drag_data.get("source") == "tray":
		var val = drag_data["value"]
		bag_ui_elements["weights"][val].modulate = Color.WHITE
	# マウス位置のスロット判定を最終更新
	_update_drag_hover()
	var value = drag_data.get("value", 0)
	var source = drag_data.get("source", "")
	if hovered_slot_subject != -1 and hovered_slot_idx != -1:
		# スロット上にドロップされた場合
		var dest_subject = hovered_slot_subject
		var dest_slot = hovered_slot_idx
		var dest_current_val = bag_assignments[dest_subject][dest_slot]
		if source == "tray":
			# トレイからスロットへの配置 (重複を取り除いた上で配置)
			_remove_weight_from_assignments(value)
			bag_assignments[dest_subject][dest_slot] = value
			# ボヨヨンTween
			var btn = bag_ui_elements["slots"][dest_subject][dest_slot] as Control
			btn.pivot_offset = btn.size / 2.0
			var tw = btn.create_tween()
			tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
		elif source == "slot":
			var src_subject = drag_data["subject"]
			var src_slot = drag_data["slot"]
			if src_subject == dest_subject and src_slot == dest_slot:
				# 同一スロットへのドロップは何もしない
				pass
			else:
				# スロット間でのスワップ（交換）
				bag_assignments[src_subject][src_slot] = dest_current_val
				bag_assignments[dest_subject][dest_slot] = value
				# 両方のスロットをボヨヨンTween
				for btn in [bag_ui_elements["slots"][src_subject][src_slot], bag_ui_elements["slots"][dest_subject][dest_slot]]:
					btn.pivot_offset = btn.size / 2.0
					var tw = btn.create_tween()
					tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_CUBIC)
					tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
		if audio_manager: audio_manager.play_se("place")
	else:
		# スロット外にドロップされた場合
		if source == "slot":
			# スロットからドラッグされていたら、そのスロットから剥がしてトレイに戻す
			var src_subject = drag_data["subject"]
			var src_slot = drag_data["slot"]
			bag_assignments[src_subject][src_slot] = null
			if audio_manager: audio_manager.play_se("click")
	# ハイライトをすべて通常状態にリセット
	if hovered_slot_subject != -1 and hovered_slot_idx != -1:
		var btn = bag_ui_elements["slots"][hovered_slot_subject][hovered_slot_idx] as Button
		var style = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.border_color = DeskTheme.COLOR_MUTED
		style.border_width_bottom = 4
		btn.add_theme_stylebox_override("normal", style)
	hovered_slot_subject = -1
	hovered_slot_idx = -1
	drag_data.clear()
	_update_bag_ui()
func _remove_weight_from_assignments(weight: int):
	for s in range(5):
		for i in range(2):
			if bag_assignments[s][i] == weight:
				bag_assignments[s][i] = null
func _update_bag_ui():
	var placed = 0
	var assigned_weights = []
	var postit_colors = [
		Color("ffd43b"), # 鮮やかなネオンイエロー
		Color("ff6b6b"), # 鮮やかなパステルレッド
		Color("339af0"), # 鮮やかなスカイブルー
		Color("51cf66"), # 鮮やかなライムグリーン
		Color("cc5de8"), # 鮮やかなパープル
		Color("ff922b"), # 鮮やかなネオンオレンジ
		Color("f06595"), # 鮮やかなピンク
		Color("20c997"), # 鮮やかなミントグリーン
		Color("5c7cfa"), # 鮮やかなロイヤルブルー
		Color("845ef7")  # 鮮やかなバイオレット
	]
	
	# 教科スロット付箋の更新
	for s in range(5):
		for i in range(2):
			var btn = bag_ui_elements["slots"][s][i]
			var val = bag_assignments[s][i]
			var is_selected = (s == selected_bag_subject and i == selected_bag_slot)
			var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()
			
			if val != null:
				placed += 1
				btn.text = str(val)
				assigned_weights.append(val)
				
				# 配置済み：ふせんの色に変化し、3Dシャドウを適用！
				var postit_col = postit_colors[val - 1]
				style.bg_color = postit_col
				style.border_color = postit_col.darkened(0.15)
				style.border_width_left = 1; style.border_width_right = 1
				style.border_width_top = 1; style.border_width_bottom = 3
				style.corner_radius_top_left = 2; style.corner_radius_top_right = 2
				style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
				style.shadow_color = Color(0, 0, 0, 0.16)
				style.shadow_size = 5
				style.shadow_offset = Vector2(2, 4)
				btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			else:
				# 空きスロット：フラットで罫線に馴染む placeholder デザイン
				style.shadow_size = 0
				style.shadow_offset = Vector2.ZERO
				style.border_width_left = 2; style.border_width_right = 2
				style.border_width_top = 2; style.border_width_bottom = 4
				style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
				style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
				
				if is_selected:
					style.border_color = DeskTheme.COLOR_BLUFF_RED
					style.bg_color = Color("fff0f0", 0.6)
				else:
					style.border_color = DeskTheme.COLOR_MUTED
					style.bg_color = Color("ffffff", 0.2)
					
				btn.text = "空き"
				btn.add_theme_color_override("font_color", DeskTheme.COLOR_MUTED)
				
			btn.add_theme_stylebox_override("normal", style)
	# 数字付箋パレットのグレーアウト処理
	for w in range(1, 11):
		var btn = bag_ui_elements["weights"][w]
		if assigned_weights.has(w):
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 0.7)
		else:
			btn.disabled = false
			btn.modulate = Color.WHITE
	# チキンレース開始ボタンのアニメーション（すべて配置された時）
	var is_all_placed = (placed >= 10)
	if not bag_ui_elements.has("was_all_placed"):
		bag_ui_elements["was_all_placed"] = false
	if is_all_placed and not bag_ui_elements["was_all_placed"]:
		var target_btn = bag_ui_elements["start_btn"]
		target_btn.pivot_offset = target_btn.size / 2.0
		var tw = target_btn.create_tween()
		tw.tween_property(target_btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(target_btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if audio_manager: audio_manager.play_se("combo")
	bag_ui_elements["was_all_placed"] = is_all_placed
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
	var toast = DeskTheme.create_floating_badge(msg, color, 16)
	var view_size = get_viewport_rect().size
	toast.position = Vector2(view_size.x / 2.0 - toast.size.x / 2.0, view_size.y / 2.0)
	ui_root.add_child(toast)
	var tw = toast.create_tween()
	tw.tween_property(toast, "position:y", toast.position.y - 50, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.3)
	tw.tween_callback(toast.queue_free)
# ----------------------------------------------------
# 3. 【チキンレース】HUDノート ＆ 机の上プレイエリア
# ----------------------------------------------------
func _show_race_screen():
	_clear_screen()
	
	# 周辺ビネット（睡魔の霧）を生成して最前面に表示するため保持
	vignette_overlay = Panel.new()
	vignette_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vignette_style = StyleBoxFlat.new()
	vignette_style.bg_color = Color(0, 0, 0, 0) # 透明
	vignette_style.border_width_left = 180
	vignette_style.border_width_right = 180
	vignette_style.border_width_top = 180
	vignette_style.border_width_bottom = 180
	vignette_style.border_color = Color("0a0a10") # 濃紺（意識混濁の霧）
	vignette_style.shadow_color = Color("0a0a10", 0.95)
	vignette_style.shadow_size = 260
	vignette_overlay.add_theme_stylebox_override("panel", vignette_style)
	vignette_overlay.modulate.a = 0.0 # 初期はすっきり
	ui_root.add_child(vignette_overlay)

	# 見開きノートの生成
	var notebook = _create_double_page_notebook()
	active_notebook = notebook
	notebook.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notebook.offset_left = (1920.0 - 1380.0) / 2.0
	notebook.offset_top = (1080.0 - 920.0) / 2.0
	notebook.offset_right = -notebook.offset_left
	notebook.offset_bottom = -notebook.offset_top
	screen_content.add_child(notebook)

	# 左ページ: 学習状況HUD (MarginContainer "LeftContent")
	hud_notebook = notebook.find_child("LeftContent", true, false) as MarginContainer
	var hud_v = VBoxContainer.new()
	hud_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_v.add_theme_constant_override("separation", 14)
	DeskTheme.apply_font(hud_v)
	hud_notebook.add_child(hud_v)
	
	hud_v.add_child(DeskTheme.create_label("📖 本日の学習ノート", 32, DeskTheme.COLOR_INK, true))
	
	# スコアラベル（巨大化！）
	var score_h = HBoxContainer.new()
	score_h.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_v.add_child(score_h)
	score_h.add_child(DeskTheme.create_label("合計点: ", 22, DeskTheme.COLOR_INK, true))
	status_label = DeskTheme.create_label("0", 54, DeskTheme.COLOR_BLUFF_RED, true)
	score_h.add_child(status_label)
	
	# 各教科の進捗ミニゲージ（サイズ＆フォント拡大！）
	subject_gauges.clear()
	for s in range(5):
		var s_row = HBoxContainer.new()
		s_row.add_theme_constant_override("separation", 12)
		hud_v.add_child(s_row)
		
		# ミニアイコンの拡大
		var mini_icon = DeskTheme.create_icon_rect(DeskTheme.subject_texture(s), Vector2(36, 36))
		s_row.add_child(mini_icon)
		
		var name_lbl = DeskTheme.create_label(DeskTheme.subject_name(s), 18, DeskTheme.subject_color(s), true)
		name_lbl.custom_minimum_size = Vector2(56, 0)
		s_row.add_child(name_lbl)
		
		# ミニバーの太幅化
		var bar = DeskTheme.create_gauge_bar(0.0, 20.0, DeskTheme.subject_color(s), Vector2(200, 22))
		s_row.add_child(bar)
		
		var val_lbl = DeskTheme.create_label("0点", 18, DeskTheme.COLOR_INK, true)
		s_row.add_child(val_lbl)
		subject_gauges[s] = {"bar": bar, "label": val_lbl}
		
	# お助け文房具カウント（サイズ拡大！）
	var items_v = VBoxContainer.new()
	items_v.add_theme_constant_override("separation", 12)
	hud_v.add_child(items_v)
	item_count_labels.clear()
	for type in range(1, 4):
		var item_h = HBoxContainer.new()
		item_h.add_theme_constant_override("separation", 12)
		items_v.add_child(item_h)
		
		var item_tex = DeskTheme.item_texture(type)
		if item_tex:
			var icon = DeskTheme.create_icon_rect(item_tex, Vector2(32, 32))
			item_h.add_child(icon)
			
		var name_lbl = DeskTheme.create_label("消しゴム(回避)" if type == 1 else "ペン(+1倍)" if type == 2 else "定規(+5点)", 18, DeskTheme.COLOR_INK, true)
		item_h.add_child(name_lbl)
		
		var count_lbl = DeskTheme.create_label("残り:2枚", 16, DeskTheme.COLOR_MUTED, true)
		item_h.add_child(count_lbl)
		item_count_labels[type] = count_lbl
		
	# HUD下部のライバル成績付箋 (チキンレース中に常時見える！サイズ＆フォント拡大！)
	var hud_rival_note = DeskTheme.create_sticky_note(Color("f0f8ff"), Vector2(360, 180), -1.0)
	hud_v.add_child(hud_rival_note)
	var hr_v = VBoxContainer.new()
	hr_v.add_theme_constant_override("separation", 8)
	hud_rival_note.add_child(hr_v)
	hr_v.add_child(DeskTheme.create_label("📌 ライバル暫定トップ", 18, Color("2b5a9e"), true))
	
	var top_scores = backend_manager.get_subject_top_scores()
	var top_str = ""
	for s in range(5):
		var top_info = top_scores[s]
		top_str += "%s:%d点  " % [DeskTheme.subject_name(s), top_info["score"]]
	hr_v.add_child(DeskTheme.create_label(top_str, 15, DeskTheme.COLOR_INK, true))

	# 右ページ: 木の机の上プレイエリア (MarginContainer "RightContent")
	var right_margin = notebook.find_child("RightContent", true, false) as MarginContainer
	var right_v = VBoxContainer.new()
	right_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_v.add_theme_constant_override("separation", 16)
	right_margin.add_child(right_v)

	# 机の上プレイエリア
	play_desk = Control.new()
	play_desk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_v.add_child(play_desk)
	
	# カードコンテナ
	card_container = Control.new()
	card_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_desk.add_child(card_container)
	
	# リアルタイム危険度表示（睡魔計）
	burst_warning_banner = Panel.new()
	burst_warning_banner.custom_minimum_size = Vector2(0, 52)
	var banner_style = StyleBoxFlat.new()
	banner_style.bg_color = DeskTheme.COLOR_SAFE
	banner_style.corner_radius_top_left = 12; banner_style.corner_radius_top_right = 12
	banner_style.corner_radius_bottom_left = 12; banner_style.corner_radius_bottom_right = 12
	burst_warning_banner.add_theme_stylebox_override("panel", banner_style)
	right_v.add_child(burst_warning_banner)
	
	var banner_h = HBoxContainer.new()
	banner_h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner_h.alignment = BoxContainer.ALIGNMENT_CENTER
	DeskTheme.apply_font(banner_h)
	burst_warning_banner.add_child(banner_h)
	
	var warning_lbl = DeskTheme.create_label("睡魔度: 0%", 18, Color.WHITE, true)
	banner_h.add_child(warning_lbl)
	
	next_burst_label = DeskTheme.create_label("安全レベル: 脳内すっきり、まだ引ける！", 14, DeskTheme.COLOR_SAFE, true)
	right_v.add_child(next_burst_label)
	
	# 操作ボタン
	button_box = HBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 32)
	right_v.add_child(button_box)
	
	var draw_btn = DeskTheme.create_button("カードを引く (ドロー)", Vector2(260, 76), DeskTheme.COLOR_SAFE, Color("2d928a"))
	draw_btn.pressed.connect(_on_draw_pressed)
	button_box.add_child(draw_btn)
	
	var stop_btn = DeskTheme.create_button("ここで勉強終了 (ストップ)", Vector2(260, 76), DeskTheme.COLOR_BURST, Color("bd4f4f"))
	stop_btn.pressed.connect(_on_stop_pressed)
	button_box.add_child(stop_btn)

	DeskTheme.animate_entrance(notebook)
	_update_race_hud()

func _update_race_hud():
	# 合計スコア
	status_label.text = str(game_session.current_score)
	# 教科スコアと進捗ゲージの同期
	for s in range(5):
		var score = game_session.subject_scores[s]
		var data = subject_gauges[s]
		var ratio = clamp(float(score) / 20.0, 0.0, 1.0)
		var fill = data["bar"].get_child(1)
		# ゲージ伸縮のなめらかTween
		var tw = fill.create_tween()
		tw.tween_property(fill, "offset_right", max(4.0, data["bar"].custom_minimum_size.x * ratio), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		data["label"].text = "%d点" % score
		
	# お助けアイテムの残数更新 (StudyDeckの状態と同期)
	var deck = game_session.deck
	var num_erasers = deck.remaining_erasers
	# デッキ内のペン、定規の総数を数える
	var num_pens = 2
	var num_rulers = 2
	for c in deck.drawn_cards:
		if c.item_type == 2: num_pens -= 1
		elif c.item_type == 3: num_rulers -= 1
	item_count_labels[1].text = "残り:%d枚" % num_erasers
	item_count_labels[2].text = "残り:%d枚" % max(0, num_pens)
	item_count_labels[3].text = "残り:%d枚" % max(0, num_rulers)
	
	# バースト確率のリアルタイム計算とビジュアル警告
	var deck_cards = deck.deck
	var conflict_count = 0
	var total_deck = deck_cards.size()
	for c in deck_cards:
		if c.item_type == 0: # SUBJECT
			for dc in deck.drawn_cards:
				if dc.item_type == 0 and dc.weight == c.weight:
					conflict_count += 1
					break
	var burst_prob = 0
	if total_deck > 0:
		burst_prob = int((float(conflict_count) / float(total_deck)) * 100.0)
		
	# 確率数値を感覚的な瞼の重さ（睡魔ゲージ）および実際のパーセント表示と融合
	var sleep_icon = "🟩 睡魔度: [██          ] すっきり！"
	var style: StyleBoxFlat = burst_warning_banner.get_theme_stylebox("panel")
	if burst_prob >= 50:
		style.bg_color = DeskTheme.COLOR_BLUFF_RED
		sleep_icon = "🟥 瞼の重さ: [██████████] 寝落ち寸前！ 💢"
		next_burst_label.text = "警告: 限界寸前！いつ寝落ち(バースト)してもおかしくない！"
		next_burst_label.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
	elif burst_prob >= 25:
		style.bg_color = DeskTheme.COLOR_ACCENT_GOLD
		sleep_icon = "🟨 瞼の重さ: [█████     ] 睡魔が襲ってきた... 💤"
		next_burst_label.text = "注意: 限界が近い... そろそろ引き際か？"
		next_burst_label.add_theme_color_override("font_color", Color("a87d00"))
	else:
		style.bg_color = DeskTheme.COLOR_SAFE
		sleep_icon = "🟩 睡魔度: [██          ] 脳内すっきり、まだ引ける！"
		next_burst_label.text = "安全レベル: まだ睡魔は感じない！"
		next_burst_label.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)
	burst_warning_banner.get_child(0).get_child(0).text = sleep_icon
	
	# 以前の鼓動 Tween を安全に破棄
	if heartbeat_tween != null:
		heartbeat_tween.kill()
		heartbeat_tween = null
	
	# 周辺ビネット（睡魔の霧）の画面暗転は 100% 廃止！
	if is_instance_valid(vignette_overlay):
		vignette_overlay.modulate.a = 0.0
		
	if burst_prob >= 80:
		# 臨界点：心臓の鼓動 (Thumping)
		if is_instance_valid(active_notebook):
			active_notebook.pivot_offset = active_notebook.size / 2.0
			heartbeat_tween = active_notebook.create_tween().set_loops()
			
			# ドックン (Thump 1)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.02, 1.02), 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			
			# わずかな間
			heartbeat_tween.tween_interval(0.06)
			
			# ドックン (Thump 2)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.015, 1.015), 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			
			# 次の鼓動までのディレイ (緊張感あふれる 0.70秒間隔)
			heartbeat_tween.tween_interval(0.70)
			
		# 睡魔警告ラベルも連動してスリリングな明滅・拡大縮小をする
		next_burst_label.pivot_offset = next_burst_label.size / 2.0
		var lbl_tw = next_burst_label.create_tween()
		lbl_tw.tween_property(next_burst_label, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_SINE)
		lbl_tw.tween_property(next_burst_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_SINE)
		lbl_tw.set_loops()
	else:
		# 通常時はノートのスケールを標準に戻す
		if is_instance_valid(active_notebook):
			var tw_reset = active_notebook.create_tween()
			tw_reset.tween_property(active_notebook, "scale", Vector2.ONE, 0.15)
		next_burst_label.scale = Vector2.ONE
func _set_action_buttons_enabled(enabled: bool):
	if is_instance_valid(button_box):
		for child in button_box.get_children():
			if child is Button:
				child.disabled = not enabled
func _on_draw_pressed():
	# ドロー処理中は二重クリックを防ぐためにボタンを完全に無効化！
	_set_action_buttons_enabled(false)
	var res = game_session.draw_card()
	var card = res["card"]
	if card == null:
		_set_action_buttons_enabled(true)
		return
	if audio_manager: audio_manager.play_se("draw")
	# カードビジュアルの生成
	var card_node: Control
	if card.item_type == 0: # SUBJECT
		card_node = DeskTheme.create_subject_card_large(card.subject, card.weight)
	else: # お助け文房具 or ノイズ
		card_node = DeskTheme.create_item_card_large(card.item_type)
	# 裏面テクスチャを追加して初期状態は裏向きにする
	var back_tex = TextureRect.new()
	back_tex.texture = DeskTheme.CARD_BACK
	back_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_node.add_child(back_tex)
	# 机の上へ配置するTweenアニメーション (おもちゃ感・フリップ)
	card_container.add_child(card_node)
	drawn_card_nodes.append(card_node)
	# 机の上のランダム配置座標を計算 (少し重なり合いながら散らばる)
	var num_cards = drawn_card_nodes.size()
	var desk_sz = play_desk.size
	if desk_sz.x < 100 or desk_sz.y < 100:
		desk_sz = Vector2(600, 460)
	var center = desk_sz / 2.0
	# 左側のノート（320px）から十分に離れた右側の空いているエリア（プレイエリア）にカードを並べる！
	center.x += 60.0 # 右側に少しシフト
	var offset_x = (num_cards - 1) * 36.0 - 180.0
	var card_sz = Vector2(190, 260)
	var target_pos = center + Vector2(offset_x, randf_range(-40.0, 40.0)) - card_sz / 2.0
	# ドローボタン（山札ボタン）の位置をドラッグ開始元（初期位置）に特定
	var view_size = get_viewport_rect().size
	var start_pos = Vector2(view_size.x / 2.0, view_size.y) - card_sz / 2.0
	if is_instance_valid(button_box) and button_box.get_child_count() > 0:
		var draw_btn = button_box.get_child(0) as Button
		if is_instance_valid(draw_btn):
			start_pos = draw_btn.global_position + draw_btn.size / 2.0 - card_sz / 2.0
	
	# ローカル座標に変換して初期位置を設定（座標系ズレの完全解消！）
	card_node.position = start_pos - card_container.global_position
	card_node.rotation_degrees = -45.0 # 引き抜く前の傾きを大げさにする
	card_node.scale = Vector2(0.2, 0.2) # 山札に収まっている小ささ
	card_node.modulate.a = 0.0
	card_node.pivot_offset = card_sz / 2.0
	if audio_manager: audio_manager.play_se("draw")
	# 3D風フリップ＆物理スライド移動アニメーション
	var tw = card_node.create_tween()
	tw.set_parallel(true)
	# 山札から整列位置までシュッと滑り出るスライド (positionをTween！)
	tw.tween_property(card_node, "position", target_pos, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_node, "rotation_degrees", randf_range(-10.0, 10.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_node, "modulate:a", 1.0, 0.15)
	# 横スケールを 0 にして裏面を潰す（めくりの半分 ＆ フリップのために少し持ち上がって大きくなる）
	tw.tween_property(card_node, "scale", Vector2(0.0, 1.3), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		back_tex.hide() # ここで裏面を隠し、表面を露出
	)
	# 表面を広げつつ、全体のスケールを1.0にする（めくり完了 ＆ ボヨヨンと弾む）
	tw.tween_property(card_node, "scale", Vector2(1.0, 1.0), 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if audio_manager: audio_manager.play_se("place")
	await tw.finished
	_update_race_hud()
	# お助け定規の効果発動
	if card.item_type == 3: # RULER
		_trigger_ruler_effect(card_node)
		# 定規ダイアログが閉じた際に再活性化されるためここでは return
		return
	# バースト検知時の演出
	if res["burst"]:
		await _trigger_burst_sequence()
		# バースト時はそのまま成績表へ遷移するため非活性のままでよい
		return
	elif res["erased"]:
		await _trigger_eraser_evasion_sequence(card_node, card.weight)
	# 正常にカードを引けた場合、コンボ数をカウントして小気味よいボヨヨンホップ演出！
	if not res["burst"] and not res["erased"]:
		var combo_num = drawn_card_nodes.size()
		if combo_num >= 2:
			var combo_badge = DeskTheme.create_floating_badge("%d COMBO!" % combo_num, DeskTheme.subject_color(card.subject) if card.item_type == 0 else DeskTheme.COLOR_SAFE, 20)
			# ドローされたカードの少し上に配置
			combo_badge.global_position = target_pos + Vector2(card_sz.x / 2.0 - combo_badge.size.x / 2.0, -35.0)
			play_desk.add_child(combo_badge)
			combo_badge.pivot_offset = combo_badge.size / 2.0
			combo_badge.scale = Vector2(0.1, 0.1)
			var b_tw = combo_badge.create_tween()
			b_tw.tween_property(combo_badge, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			b_tw.parallel().tween_property(combo_badge, "rotation_degrees", randf_range(-12.0, 12.0), 0.12)
			b_tw.tween_property(combo_badge, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)
			b_tw.tween_interval(0.8)
			b_tw.tween_property(combo_badge, "modulate:a", 0.0, 0.25)
			b_tw.tween_callback(combo_badge.queue_free)
	# 正常に終了したため、ボタンを再有効化！
	_set_action_buttons_enabled(true)
# --- 定規の効果発動時のダイアログ ---
func _trigger_ruler_effect(card_node: Control):
	if audio_manager: audio_manager.play_se("combo")
	# 机の上で定規カードが跳ねる演出
	var bounce = card_node.create_tween()
	bounce.tween_property(card_node, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_CUBIC)
	bounce.tween_property(card_node, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	button_box.hide()
	var overlay
	overlay = DeskTheme.create_dialog_overlay(self, "📏 定規でスコア補強！", func(vbox: VBoxContainer):
		# 定規の上部目盛り
		var ticks_top = DeskTheme.create_label("| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |", 12, Color("5c4033"), true)
		ticks_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(ticks_top)
		vbox.move_child(ticks_top, 0) # 最上部へ移動
		
		vbox.add_child(DeskTheme.create_label("好きな教科を1つ選んでスコアを「＋5点」補強できます。", 15, DeskTheme.COLOR_INK, true))
		
		var grid = GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 12)
		vbox.add_child(grid)
		
		for s in range(5):
			var btn = DeskTheme.create_button(DeskTheme.subject_name(s), Vector2(110, 56), DeskTheme.subject_color(s), DeskTheme.subject_color(s).darkened(0.1))
			btn.pivot_offset = Vector2(55, 28)
			btn.pressed.connect(func():
				if audio_manager: audio_manager.play_se("place")
				
				# ボタンのハンコ押し物理Tween
				var btn_tw = btn.create_tween()
				btn_tw.tween_property(btn, "scale", Vector2(0.85, 0.85), 0.08)
				btn_tw.chain().tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
				
				await btn_tw.finished
				# スコア加算
				game_session.subject_scores[s] += 5
				game_session.current_score += 5
				_update_race_hud()
				
				# ダイアログ除去
				var node = vbox
				while node and not node is ColorRect: node = node.get_parent()
				if node: node.queue_free()
				button_box.show()
				_set_action_buttons_enabled(true) # ドローボタンを再活性化！
			)
			grid.add_child(btn)
			
		# 定規の下部目盛り
		var ticks_bottom = DeskTheme.create_label("| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |", 12, Color("5c4033"), true)
		ticks_bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(ticks_bottom)
	)
	# 定規風の背景スタイルをパネルに適用
	var ruler_panel = overlay.get_child(0) as PanelContainer
	if is_instance_valid(ruler_panel):
		var ruler_style = StyleBoxFlat.new()
		ruler_style.bg_color = Color("dfd5b8") # 木製竹定規の温かいベージュ
		ruler_style.border_width_left = 6; ruler_style.border_width_right = 6
		ruler_style.border_width_top = 18; ruler_style.border_width_bottom = 18
		ruler_style.border_color = Color("8c6d4f") # 定規の縁取り
		ruler_style.corner_radius_top_left = 8; ruler_style.corner_radius_top_right = 8
		ruler_style.corner_radius_bottom_left = 8; ruler_style.corner_radius_bottom_right = 8
		ruler_panel.add_theme_stylebox_override("panel", ruler_style)

# --- 消しゴムでバースト回避された際のアニメーション ---
func _trigger_eraser_evasion_sequence(new_card_node: Control, weight: int):
	if audio_manager: audio_manager.play_se("combo")
	# 被っている古いカードを探す
	var conflicting_node: Control = null
	for node in drawn_card_nodes:
		if node != new_card_node and node.has_node("Content"):
			var lbl = node.get_child(0).get_child(0) as Label
			if lbl and lbl.text == str(weight):
				conflicting_node = node
				break
	# 消しゴムがゴシゴシ被りカードを消す演出
	if conflicting_node:
		var eraser_img = TextureRect.new()
		eraser_img.texture = DeskTheme.ITEM_ERASER
		eraser_img.custom_minimum_size = Vector2(80, 80)
		eraser_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		eraser_img.position = conflicting_node.position + conflicting_node.size / 2.0 - Vector2(40, 40)
		eraser_img.pivot_offset = Vector2(40, 40)
		play_desk.add_child(eraser_img)
		
		# 消しゴムのカス（パーティクル）をProceduralに生成しておもちゃ感を演出！
		var particle_count = 6
		var particles = []
		for p_i in range(particle_count):
			var part = ColorRect.new()
			part.color = Color("ffffff") # 白い消しゴムのカス
			part.custom_minimum_size = Vector2(randf_range(4, 8), randf_range(2, 4))
			part.position = conflicting_node.position + conflicting_node.size / 2.0 + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			part.pivot_offset = part.custom_minimum_size / 2.0
			part.rotation_degrees = randf_range(0, 360)
			part.modulate.a = 0.0
			play_desk.add_child(part)
			particles.append(part)
		
		# 3往復のゴシゴシ摩擦アニメーション
		var slide_tw = eraser_img.create_tween()
		var part_tw = create_tween().set_parallel(true)
		var orig_x = eraser_img.position.x
		
		for w in range(3):
			slide_tw.tween_property(eraser_img, "position:x", orig_x - 24, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			slide_tw.tween_property(eraser_img, "rotation_degrees", 12.0, 0.07)
			slide_tw.tween_callback(func(): if audio_manager: audio_manager.play_se("click"))
			
			slide_tw.tween_property(eraser_img, "position:x", orig_x + 24, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			slide_tw.tween_property(eraser_img, "rotation_degrees", -12.0, 0.07)
			slide_tw.tween_callback(func(): if audio_manager: audio_manager.play_se("click"))
			
		# ゴシゴシ中にカードの文字がだんだん消えてかすれていく
		slide_tw.set_parallel(true)
		slide_tw.tween_property(conflicting_node, "modulate:a", 0.3, 0.42)
		slide_tw.tween_property(new_card_node, "modulate:a", 0.3, 0.42)
		
		# カスがぴょこぴょこと外側に飛び散る
		for p_idx in range(particle_count):
			var part = particles[p_idx]
			part_tw.tween_property(part, "modulate:a", 1.0, 0.1)
			part_tw.tween_property(part, "position", part.position + Vector2(randf_range(-60, 60), randf_range(-30, 60)), 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			part_tw.tween_property(part, "rotation_degrees", part.rotation_degrees + randf_range(-90, 90), 0.42)
			part_tw.tween_property(part, "scale", Vector2(0.1, 0.1), 0.42).set_delay(0.2)
			
		await slide_tw.finished
		
		# カスを綺麗にクリーンアップ
		for part in particles:
			part.queue_free()
			
		# 古いカードと新しいカード、消しゴムをフェードアウト消去
		var disappear = create_tween().set_parallel(true)
		disappear.tween_property(conflicting_node, "modulate:a", 0.0, 0.2)
		disappear.tween_property(conflicting_node, "scale", Vector2(0.2, 0.2), 0.2)
		disappear.tween_property(new_card_node, "modulate:a", 0.0, 0.2)
		disappear.tween_property(new_card_node, "scale", Vector2(0.2, 0.2), 0.2)
		disappear.tween_property(eraser_img, "modulate:a", 0.0, 0.15)
		await disappear.finished
		
		drawn_card_nodes.erase(conflicting_node)
		drawn_card_nodes.erase(new_card_node)
		conflicting_node.queue_free()
		new_card_node.queue_free()
		eraser_img.queue_free()
		_update_race_hud()

# --- バースト（寝落ち）シーケンス ---
func _trigger_burst_sequence():
	if audio_manager: audio_manager.play_se("burst")
	if is_instance_valid(button_box):
		button_box.hide()
	
	# 周辺ビネット（睡魔の霧）を画面全体に広げて完全に暗転させる
	if is_instance_valid(vignette_overlay):
		var tw_vig = vignette_overlay.create_tween()
		tw_vig.tween_property(vignette_overlay, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	# カメラシェイク
	var shake = create_tween().set_loops(8)
	shake.tween_callback(func(): camera_shake_offset = Vector2(randf_range(-14, 14), randf_range(-14, 14)))
	shake.tween_interval(0.04)
	
	# 机の上の衝撃による「文房具ホップ」アニメーション
	var hop_tw = create_tween().set_parallel(true)
	if is_instance_valid(hud_notebook):
		hud_notebook.pivot_offset = hud_notebook.size / 2.0
		hop_tw.tween_property(hud_notebook, "position:y", hud_notebook.position.y - 25, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		hop_tw.tween_property(hud_notebook, "rotation_degrees", -2.0, 0.1)
	for node in drawn_card_nodes:
		if is_instance_valid(node):
			node.pivot_offset = node.size / 2.0
			hop_tw.tween_property(node, "position:y", node.position.y - 35, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			hop_tw.tween_property(node, "rotation_degrees", node.rotation_degrees + randf_range(-15, 15), 0.12)
			
	# 落下バウンド
	hop_tw.chain().set_parallel(true)
	if is_instance_valid(hud_notebook):
		hop_tw.tween_property(hud_notebook, "position:y", hud_notebook.position.y, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		hop_tw.tween_property(hud_notebook, "rotation_degrees", 0.0, 0.18)
	for node in drawn_card_nodes:
		if is_instance_valid(node):
			var orig_y = node.position.y
			hop_tw.tween_property(node, "position:y", orig_y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			
	# カードが青黒く染まる
	var fade_black = create_tween().set_parallel(true)
	for node in drawn_card_nodes:
		if is_instance_valid(node):
			fade_black.tween_property(node, "modulate", Color(0.25, 0.25, 0.45, 0.8), 0.4)
			
	# 寝落ちスタンプ
	var banner = DeskTheme.create_floating_badge("【 寝落ち（バースト）！】", DeskTheme.COLOR_BLUFF_RED, 28)
	banner.anchor_left = 0.5; banner.anchor_top = 0.5; banner.anchor_right = 0.5; banner.anchor_bottom = 0.5
	banner.offset_left = -300; banner.offset_top = -140; banner.offset_right = 300; banner.offset_bottom = -60
	if is_instance_valid(play_desk):
		play_desk.add_child(banner)
	else:
		screen_content.add_child(banner)
	banner.scale = Vector2(4.0, 4.0)
	banner.modulate.a = 0.0
	banner.pivot_offset = banner.size / 2.0
	
	var banner_tw = banner.create_tween()
	banner_tw.set_parallel(true)
	banner_tw.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	banner_tw.tween_property(banner, "modulate:a", 1.0, 0.1)
	banner_tw.tween_property(banner, "rotation_degrees", randf_range(-8.0, 8.0), 0.15)
	
	banner_tw.chain().tween_callback(func():
		if audio_manager: audio_manager.play_se("place")
	)
	
	await fade_black.finished
	await shake.finished
	await hop_tw.finished
	camera_shake_offset = Vector2.ZERO
	if banner_tw.is_running():
		await banner_tw.finished
		
	# バースト時の強制停止データ
	var empty_scores = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	game_session.current_score = 0
	
	# ==========================================
	# 寝落ち（バースト）した時の明確なダイアログと起きるボタンの表示
	# ==========================================
	var dialog = PanelContainer.new()
	dialog.custom_minimum_size = Vector2(600, 280)
	dialog.anchor_left = 0.5; dialog.anchor_top = 0.5; dialog.anchor_right = 0.5; dialog.anchor_bottom = 0.5
	dialog.offset_left = -300; dialog.offset_top = -20; dialog.offset_right = 300; dialog.offset_bottom = 260
	
	var dialog_style = StyleBoxFlat.new()
	dialog_style.bg_color = Color("1e1610") # 黒板・革バインダーのような深みのある色
	dialog_style.border_width_left = 4; dialog_style.border_width_right = 4
	dialog_style.border_width_top = 4; dialog_style.border_width_bottom = 6
	dialog_style.border_color = DeskTheme.COLOR_BLUFF_RED
	dialog_style.corner_radius_top_left = 16; dialog_style.corner_radius_top_right = 16
	dialog_style.corner_radius_bottom_left = 16; dialog_style.corner_radius_bottom_right = 16
	dialog_style.shadow_color = Color(0, 0, 0, 0.6)
	dialog_style.shadow_size = 20
	dialog.add_theme_stylebox_override("panel", dialog_style)
	
	if is_instance_valid(play_desk):
		play_desk.add_child(dialog)
	else:
		screen_content.add_child(dialog)
		
	var dv = VBoxContainer.new()
	dv.add_theme_constant_override("separation", 16)
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dialog.add_child(dv)
	
	dv.add_child(DeskTheme.create_label("💤 睡魔に敗れて寝落ちした！", 22, DeskTheme.COLOR_BLUFF_RED, true))
	
	var msg = DeskTheme.create_label("勉強した記憶がすべて夢の彼方へ消え去ってしまった...\n(本日の獲得点数は すべて「0点」になります)", 14, Color("dfd5cb"))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(msg)
	
	var wake_btn = DeskTheme.create_button("【 🛏️ 目をこすって起きる (通知表へ進む) ➔ 】", Vector2(400, 56), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
	wake_btn.add_theme_font_size_override("font_size", 16)
	dv.add_child(wake_btn)
	
	# ボタンの脈動（パルス）アニメーション
	wake_btn.pivot_offset = Vector2(200, 28)
	var pulse_tw = wake_btn.create_tween().set_loops()
	pulse_tw.tween_property(wake_btn, "scale", Vector2(1.04, 1.04), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse_tw.tween_property(wake_btn, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	wake_btn.pressed.connect(func():
		pulse_tw.kill()
		if audio_manager: audio_manager.play_se("click")
		dialog.queue_free()
		_show_report_screen(empty_scores)
	)

func _on_stop_pressed():
	if audio_manager: audio_manager.play_se("click")
	# ストップ時はハンコを「ドンッ！」と押すような Tween を HUD に与える
	var stamp = hud_notebook.create_tween()
	stamp.tween_property(hud_notebook, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_CUBIC)
	stamp.tween_property(hud_notebook, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)
	if audio_manager: audio_manager.play_se("combo")
	await stamp.finished
	var scores = game_session.stop_and_report()
	_show_report_screen(scores)
# ----------------------------------------------------
# 4. 【学習報告（嘘のスライダー）】嘘つき成績表
# ----------------------------------------------------
func _show_report_screen(scores: Dictionary):
	_clear_screen()
	
	# 背景に見開きノートを置く（ふせんフェーズと同じ世界観を維持）
	var notebook = _create_double_page_notebook()
	notebook.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notebook.offset_left = (1920.0 - 1380.0) / 2.0
	notebook.offset_top = (1080.0 - 920.0) / 2.0
	notebook.offset_right = -notebook.offset_left
	notebook.offset_bottom = -notebook.offset_top
	screen_content.add_child(notebook)
	
	# 左側の机の上エリア（スマホ置き場）
	var left_area = Control.new()
	left_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_area.anchor_right = 0.3 # 画面左側30%
	screen_content.add_child(left_area)
	
	var app_container = _create_smartphone_mockup(left_area, false)
	# 1. アプリヘッダー (Studyplus風)
	var app_header = PanelContainer.new()
	app_header.custom_minimum_size = Vector2(0, 52)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("ffffff") # 白クリーンなヘッダー
	header_style.border_width_bottom = 2
	header_style.border_color = Color("e1e4e6")
	app_header.add_theme_stylebox_override("panel", header_style)
	app_container.add_child(app_header)
	var app_header_h = HBoxContainer.new()
	app_header_h.add_theme_constant_override("separation", 8)
	app_header_h.alignment = BoxContainer.ALIGNMENT_CENTER
	app_header.add_child(app_header_h)
	var app_icon = ColorRect.new()
	app_icon.custom_minimum_size = Vector2(26, 26)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = DeskTheme.COLOR_SAFE
	icon_style.corner_radius_top_left = 6; icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_left = 6; icon_style.corner_radius_bottom_right = 6
	app_icon.add_theme_stylebox_override("panel", icon_style)
	app_header_h.add_child(app_icon)
	var app_icon_lbl = DeskTheme.create_label("S", 13, Color.WHITE)
	app_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app_icon.add_child(app_icon_lbl)
	var app_title = DeskTheme.create_label("チキスタ !", 16, DeskTheme.COLOR_SAFE, true)
	app_header_h.add_child(app_title)
	# アプリ内メインスクロールエリア
	var app_scroll = ScrollContainer.new()
	app_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app_container.add_child(app_scroll)
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 12)
	app_scroll.add_child(scroll_vbox)
	# パディング用 MarginContainer
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 12)
	margin_c.add_theme_constant_override("margin_top", 12)
	margin_c.add_theme_constant_override("margin_right", 12)
	margin_c.add_theme_constant_override("margin_bottom", 12)
	scroll_vbox.add_child(margin_c)
	var content_v = VBoxContainer.new()
	content_v.add_theme_constant_override("separation", 12)
	margin_c.add_child(content_v)
	# 報告画面タイトル＆説明カード
	var title_card = PanelContainer.new()
	var tc_style = StyleBoxFlat.new()
	tc_style.bg_color = Color("f8f9fa")
	tc_style.corner_radius_top_left = 12; tc_style.corner_radius_top_right = 12
	tc_style.corner_radius_bottom_left = 12; tc_style.corner_radius_bottom_right = 12
	title_card.add_theme_stylebox_override("panel", tc_style)
	content_v.add_child(title_card)
	var tm = MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 10); tm.add_theme_constant_override("margin_right", 10)
	tm.add_theme_constant_override("margin_top", 8); tm.add_theme_constant_override("margin_bottom", 8)
	title_card.add_child(tm)
	var title_v = VBoxContainer.new()
	title_v.add_theme_constant_override("separation", 2)
	tm.add_child(title_v)
	title_v.add_child(DeskTheme.create_label("📊 本日の学習報告（成績発表）", 18, DeskTheme.COLOR_INK, true))
	title_v.add_child(DeskTheme.create_label("スライダーを動かして勉強時間を報告しよう！\n(嘘を盛るリスク・謙虚にするボーナスあり)", 13, DeskTheme.COLOR_MUTED, true))
	# スライダーリストカード
	var list_card = PanelContainer.new()
	var lc_style = StyleBoxFlat.new()
	lc_style.bg_color = Color.WHITE
	lc_style.corner_radius_top_left = 16; lc_style.corner_radius_top_right = 16
	lc_style.corner_radius_bottom_left = 16; lc_style.corner_radius_bottom_right = 16
	lc_style.border_width_bottom = 2
	lc_style.border_color = Color("e6e8eb")
	list_card.add_theme_stylebox_override("panel", lc_style)
	content_v.add_child(list_card)
	var lm = MarginContainer.new()
	lm.add_theme_constant_override("margin_left", 8); lm.add_theme_constant_override("margin_right", 8)
	lm.add_theme_constant_override("margin_top", 12); lm.add_theme_constant_override("margin_bottom", 12)
	list_card.add_child(lm)
	var list_v = VBoxContainer.new()
	list_v.add_theme_constant_override("separation", 16)
	lm.add_child(list_v)
	var reported_scores = {}
	var slider_labels = {}
	for s in range(5):
		var actual_val = scores[s]
		reported_scores[s] = actual_val
		var s_row = HBoxContainer.new()
		s_row.add_theme_constant_override("separation", 6)
		list_v.add_child(s_row)
		# 教科名
		var name_lbl = DeskTheme.create_label(DeskTheme.subject_name(s), 16, DeskTheme.subject_color(s), true)
		name_lbl.custom_minimum_size = Vector2(48, 0)
		s_row.add_child(name_lbl)
		# 実際スコア
		var actual_lbl = DeskTheme.create_label("実際:%d" % actual_val, 13, Color("4a7de0"))
		actual_lbl.custom_minimum_size = Vector2(56, 0)
		s_row.add_child(actual_lbl)
		# ➖➕付きスライダー
		var slider_h = HBoxContainer.new()
		slider_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider_h.add_theme_constant_override("separation", 4)
		s_row.add_child(slider_h)
		# ➖ボタン (クリックでボヨヨン ＆ ホバーぷっくり)
		var minus_btn = DeskTheme.create_button("➖", Vector2(32, 32), Color("e9edf2"), Color("b8c4d1"), true)
		minus_btn.add_theme_font_size_override("font_size", 11)
		minus_btn.pivot_offset = Vector2(16, 16)
		slider_h.add_child(minus_btn)
		
		minus_btn.mouse_entered.connect(func():
			minus_btn.pivot_offset = minus_btn.size / 2.0
			var tw = minus_btn.create_tween()
			tw.tween_property(minus_btn, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			if audio_manager: audio_manager.play_se("click")
		)
		minus_btn.mouse_exited.connect(func():
			var tw = minus_btn.create_tween()
			tw.tween_property(minus_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		)
		
		# 木製定規風スライダー (過少申告不可: min は実際のスコア)
		var slider = HSlider.new()
		slider.min_value = actual_val
		slider.max_value = 20
		slider.value = actual_val
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# 消しゴム風つまみのカスタムテーマ適用
		var eraser_style = StyleBoxFlat.new()
		eraser_style.bg_color = DeskTheme.COLOR_BLUFF_RED # 消しゴムの赤
		eraser_style.corner_radius_top_left = 5; eraser_style.corner_radius_top_right = 5
		eraser_style.corner_radius_bottom_left = 5; eraser_style.corner_radius_bottom_right = 5
		eraser_style.expand_margin_top = 6; eraser_style.expand_margin_bottom = 6
		eraser_style.expand_margin_left = 9; eraser_style.expand_margin_right = 9
		slider.add_theme_stylebox_override("grabber", eraser_style)
		slider.add_theme_stylebox_override("grabber_highlight", eraser_style)
		var ruler_bg = StyleBoxFlat.new()
		ruler_bg.bg_color = Color("dfd5b8") # 木製定規の温かいベージュ
		ruler_bg.corner_radius_top_left = 3; ruler_bg.corner_radius_top_right = 3
		ruler_bg.corner_radius_bottom_left = 3; ruler_bg.corner_radius_bottom_right = 3
		ruler_bg.expand_margin_top = 2; ruler_bg.expand_margin_bottom = 2
		slider.add_theme_stylebox_override("slider", ruler_bg)
		slider_h.add_child(slider)
		
		# ➕ボタン (クリックでボヨヨン ＆ ホバーぷっくり)
		var plus_btn = DeskTheme.create_button("➕", Vector2(32, 32), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
		plus_btn.add_theme_font_size_override("font_size", 11)
		plus_btn.pivot_offset = Vector2(16, 16)
		slider_h.add_child(plus_btn)
		
		plus_btn.mouse_entered.connect(func():
			plus_btn.pivot_offset = plus_btn.size / 2.0
			var tw = plus_btn.create_tween()
			tw.tween_property(plus_btn, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			if audio_manager: audio_manager.play_se("click")
		)
		plus_btn.mouse_exited.connect(func():
			var tw = plus_btn.create_tween()
			tw.tween_property(plus_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		)
		# 報告スコアラベル
		var report_lbl = DeskTheme.create_label("正直: %d点" % actual_val, 15, DeskTheme.COLOR_INK, true)
		report_lbl.custom_minimum_size = Vector2(80, 0)
		s_row.add_child(report_lbl)
		slider_labels[s] = report_lbl
		# 前回の値を保持して整数値の変化だけを検知する
		var last_val = { "val": actual_val }
		# ➕➖物理ボタンの連動
		minus_btn.pressed.connect(func():
			if slider.value > slider.min_value:
				slider.value -= 1
				var m_tw = minus_btn.create_tween()
				m_tw.tween_property(minus_btn, "scale", Vector2(0.85, 0.85), 0.04)
				m_tw.tween_property(minus_btn, "scale", Vector2(1.0, 1.0), 0.07).set_trans(Tween.TRANS_BACK)
		)
		plus_btn.pressed.connect(func():
			if slider.value < slider.max_value:
				slider.value += 1
				var p_tw = plus_btn.create_tween()
				p_tw.tween_property(plus_btn, "scale", Vector2(0.85, 0.85), 0.04)
				p_tw.tween_property(plus_btn, "scale", Vector2(1.0, 1.0), 0.07).set_trans(Tween.TRANS_BACK)
		)
		# スライダー入力のリアルタイム変更イベント
		slider.value_changed.connect(func(val):
			var i_val = int(val)
			if i_val == last_val["val"]:
				return # 値が変わっていなければスキップ
			last_val["val"] = i_val
			reported_scores[s] = i_val
			
			# スライダー自体の物理ダイヤル振動フィードバック
			var s_tw = slider.create_tween()
			s_tw.tween_property(slider, "position:y", slider.position.y - 1.5, 0.03)
			s_tw.tween_property(slider, "position:y", slider.position.y, 0.05).set_trans(Tween.TRANS_BACK)
			if audio_manager: audio_manager.play_se("place") # カチッというダイヤル音代わり
			
			var lbl = slider_labels[s] as Label
			lbl.pivot_offset = lbl.size / 2.0
			var tw = lbl.create_tween()
			if i_val > actual_val:
				lbl.text = "盛った: %d点" % i_val
				lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
				# 嘘を盛れば盛るほど、ラベルが大きく膨らみ、赤ペンが強調される
				tw.tween_property(lbl, "scale", Vector2(1.22, 1.22), 0.08).set_trans(Tween.TRANS_CUBIC)
				tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
				if audio_manager:
					audio_manager.play_se("click")
			else:
				lbl.text = "正直: %d点" % i_val
				lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
				tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.08)
				if audio_manager:
					audio_manager.play_se("click")
			_update_report_warning(scores, reported_scores)
		)
	# 💡 動的警告通知カード（Studyplus風）
	var warning_card = PanelContainer.new()
	warning_card.custom_minimum_size = Vector2(0, 100)
	var wc_style = StyleBoxFlat.new()
	wc_style.bg_color = Color("f1f8ff") # 初期は正直（水色系）
	wc_style.corner_radius_top_left = 16; wc_style.corner_radius_top_right = 16
	wc_style.corner_radius_bottom_left = 16; wc_style.corner_radius_bottom_right = 16
	wc_style.border_width_bottom = 2
	wc_style.border_color = Color("d0e1fd")
	warning_card.add_theme_stylebox_override("panel", wc_style)
	content_v.add_child(warning_card)
	bag_ui_elements["warning_card_style"] = wc_style # リアルタイムに背景と枠線をTweenで変えるために保持
	bag_ui_elements["warning_card"] = warning_card # スケールTweenのために保持
	var wm = MarginContainer.new()
	wm.add_theme_constant_override("margin_left", 12); wm.add_theme_constant_override("margin_right", 12)
	wm.add_theme_constant_override("margin_top", 10); wm.add_theme_constant_override("margin_bottom", 10)
	warning_card.add_child(wm)
	var warning_v = VBoxContainer.new()
	warning_v.alignment = BoxContainer.ALIGNMENT_CENTER
	warning_v.add_theme_constant_override("separation", 6)
	wm.add_child(warning_v)
	var warning_title = DeskTheme.create_label("[ 報告ステータス ]", 15, Color("2b5c8f"), true)
	warning_v.add_child(warning_title)
	bag_ui_elements["noise_warning_title"] = warning_title
	var warning_desc = DeskTheme.create_label("正直な報告です！\n(応援されたら＋5点！)", 16, DeskTheme.COLOR_INK, true)
	warning_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_v.add_child(warning_desc)
	bag_ui_elements["noise_warning"] = warning_desc
	var warning_hint = DeskTheme.create_label("※嘘がバレると盛った差分の2倍減点！謙虚なら応援で大ボーナス！", 12, DeskTheme.COLOR_MUTED, true)
	warning_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_v.add_child(warning_hint)
	# フッター（固定の提出ボタン）
	var footer = PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 80)
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = Color("ffffff") # 白背景
	footer_style.border_width_top = 2
	footer_style.border_color = Color("e1e4e6")
	footer.add_theme_stylebox_override("panel", footer_style)
	app_container.add_child(footer)
	var fm = MarginContainer.new()
	fm.add_theme_constant_override("margin_left", 16); fm.add_theme_constant_override("margin_right", 16)
	fm.add_theme_constant_override("margin_top", 10); fm.add_theme_constant_override("margin_bottom", 10)
	footer.add_child(fm)
	var submit_btn = DeskTheme.create_button("学習報告をチキスタに投稿", Vector2(0, 52), DeskTheme.COLOR_SAFE, Color("2d928a"))
	submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_btn.pressed.connect(func(): _submit_final(scores, reported_scores))
	fm.add_child(submit_btn)
	
	# 投稿ボタンホバーバウンド (極上インタラクション)
	submit_btn.pivot_offset = submit_btn.size / 2.0
	submit_btn.mouse_entered.connect(func():
		submit_btn.pivot_offset = submit_btn.size / 2.0
		var tw = submit_btn.create_tween()
		tw.tween_property(submit_btn, "scale", Vector2(1.06, 1.06), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if audio_manager: audio_manager.play_se("click")
	)
	submit_btn.mouse_exited.connect(func():
		var tw = submit_btn.create_tween()
		tw.tween_property(submit_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	_update_report_warning(scores, reported_scores)
func _update_report_warning(actual: Dictionary, reported: Dictionary):
	var lie_diff_total = 0
	
	for s in actual:
		if reported[s] > actual[s]:
			lie_diff_total += (reported[s] - actual[s])
			
	var warning_lbl = bag_ui_elements["noise_warning"] as Label
	var warning_title = bag_ui_elements["noise_warning_title"] as Label
	var wc_style = bag_ui_elements["warning_card_style"] as StyleBoxFlat
	var card = bag_ui_elements["warning_card"] as Control
	card.pivot_offset = card.size / 2.0
	var tw = card.create_tween().set_parallel(true)
	
	if lie_diff_total > 0:
		var penalty = lie_diff_total * 2
		warning_title.text = "[ 嘘つきリスク警告！ ]"
		warning_title.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
		warning_lbl.text = "報告に嘘(盛り)が混ざっています！\n見破られた場合の減点: 最大 −%d点！" % penalty
		warning_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
		tw.tween_property(wc_style, "bg_color", Color("fff5f5"), 0.15)
		tw.tween_property(wc_style, "border_color", Color("ffd5d5"), 0.15)
		var scale_tw = card.create_tween()
		scale_tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.08).set_trans(Tween.TRANS_CUBIC)
		scale_tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_BACK)
	else:
		warning_title.text = "[ 報告ステータス: 正真 ]"
		warning_title.add_theme_color_override("font_color", Color("2b5c8f"))
		warning_lbl.text = "正直な報告です！\n(応援されたら＋10点！)"
		warning_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		tw.tween_property(wc_style, "bg_color", Color("f1f8ff"), 0.15)
		tw.tween_property(wc_style, "border_color", Color("d0e1fd"), 0.15)
# ----------------------------------------------------
# 5. スコア送信 ＆ 日付変更 / 最終リザルト
# ----------------------------------------------------
func _submit_final(actual: Dictionary, reported: Dictionary):
	# 提出済スタンプをスマホの上にドンッ！と押す物理おもちゃ演出
	var page_panel = bag_ui_elements.get("report_page") # これはスマホ本体 (phone)
	if is_instance_valid(page_panel):
		var stamp_badge = DeskTheme.create_app_stamp("提出済", DeskTheme.COLOR_BLUFF_RED, 26)
		# スマホの画面中央に配置
		stamp_badge.position = page_panel.size / 2.0 - stamp_badge.size / 2.0
		page_panel.add_child(stamp_badge)
		stamp_badge.pivot_offset = stamp_badge.size / 2.0
		stamp_badge.scale = Vector2(4.0, 4.0) # 巨大スケールから
		stamp_badge.modulate.a = 0.0
		var s_tw = stamp_badge.create_tween()
		s_tw.set_parallel(true)
		s_tw.tween_property(stamp_badge, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		s_tw.tween_property(stamp_badge, "modulate:a", 1.0, 0.08)
		s_tw.tween_property(stamp_badge, "rotation_degrees", randf_range(-16.0, -8.0), 0.15) # わずかに左傾き
		# スマホ本体そのものを衝撃でポヨンとホップ＆バウンドさせる物理衝撃演出！
		var p_tw = page_panel.create_tween()
		page_panel.pivot_offset = page_panel.size / 2.0
		var orig_y = page_panel.position.y
		p_tw.tween_property(page_panel, "position:y", orig_y - 20, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		p_tw.chain().tween_property(page_panel, "position:y", orig_y, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		if audio_manager: audio_manager.play_se("place")
		await s_tw.finished
		await p_tw.finished
		# 余韻
		await get_tree().create_timer(0.5).timeout
	else:
		if audio_manager: audio_manager.play_se("click")
	# ノイズシステム廃止のため daily_noises は常に0でリセット
	# 実際と報告のスコア記録を保存
	for s in actual:
		Global.daily_noises[s] = 0
		Global.last_actual_scores[s] = actual[s]
		Global.last_reported_scores[s] = reported[s]
	# 前日のトップ教科を保存
	Global.last_top_subjects.clear()
	var tops = backend_manager.get_subject_top_scores()
	for s in tops.keys():
		if tops[s]["name"] == Global.player_name:
			Global.last_top_subjects.append(s)
	# 【新ルール】報告した点数（嘘含む）の合計がそのまま実際の点数として数えられ、合計スコアに加算される
	var reported_total = 0
	for s in reported:
		reported_total += reported[s]
	Global.total_score += reported_total
	Global.play_count += 1
	# スコア履歴にスナップショットを記録（報告スコアベースで記録）
	var day_entry = {
		"day": Global.play_count,
		"total": Global.total_score,
		"subjects": {},
		"rivals": []
	}
	for s in reported:
		day_entry["subjects"][s] = reported[s]
	for rival in backend_manager.current_scores:
		day_entry["rivals"].append({"name": rival.get("name", "???"), "score": rival.get("score", 0)})
	Global.score_history.append(day_entry)
	Global.save_data()
	# Supabaseサーバーへ提出
	backend_manager.submit_score(Global.player_name, reported)
	# 7日間プレイ完了で最終シーズンリザルトへ
	if Global.play_count >= 7:
		SceneTransition.fade_to_scene("res://ResultScene.tscn")
	else:
		_show_day_transition()
func _show_day_transition():
	_clear_screen()
	# 暗転フェードとカレンダーパネルの生成
	var overlay = ColorRect.new()
	overlay.color = Color("1e1c19") # 木製デスクに合うダークブラウン
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_content.add_child(overlay)
	var cal_panel = PanelContainer.new()
	cal_panel.custom_minimum_size = Vector2(320, 360)
	var cal_style = StyleBoxFlat.new()
	cal_style.bg_color = Color("faf8f5") # 紙の白
	cal_style.border_width_left = 6; cal_style.border_width_right = 6
	cal_style.border_width_top = 24; cal_style.border_width_bottom = 8 # 日めくり金具の赤を上部に
	cal_style.border_color = Color("c93d3d") # 金具の赤
	cal_style.corner_radius_top_left = 12; cal_style.corner_radius_top_right = 12
	cal_style.corner_radius_bottom_left = 12; cal_style.corner_radius_bottom_right = 12
	cal_style.shadow_color = Color(0, 0, 0, 0.3)
	cal_style.shadow_size = 16
	cal_panel.add_theme_stylebox_override("panel", cal_style)
	cal_panel.anchor_left = 0.5; cal_panel.anchor_top = 0.5; cal_panel.anchor_right = 0.5; cal_panel.anchor_bottom = 0.5
	cal_panel.offset_left = -160; cal_panel.offset_top = -180; cal_panel.offset_right = 160; cal_panel.offset_bottom = 180
	overlay.add_child(cal_panel)
	var cal_v = VBoxContainer.new()
	cal_v.alignment = BoxContainer.ALIGNMENT_CENTER
	cal_v.add_theme_constant_override("separation", 16)
	DeskTheme.apply_font(cal_v)
	cal_panel.add_child(cal_v)
	cal_v.add_child(DeskTheme.create_label("Day", 24, DeskTheme.COLOR_MUTED, true))
	# 前の日付を表示
	var day_lbl = DeskTheme.create_label(str(Global.play_count), 96, Color("d94040"), true)
	day_lbl.add_theme_font_size_override("font_size", 96)
	cal_v.add_child(day_lbl)
	cal_v.add_child(DeskTheme.create_label("放課後のテスト勉強が終了しました...", 14, DeskTheme.COLOR_MUTED, true))
	# ぽよんと登場
	cal_panel.pivot_offset = cal_panel.size / 2.0
	cal_panel.scale = Vector2(0.3, 0.3)
	var tw = cal_panel.create_tween()
	tw.tween_property(cal_panel, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if audio_manager: audio_manager.play_se("place")
	await tw.finished
	await get_tree().create_timer(0.6).timeout
	# カレンダーめくりアニメーション
	if audio_manager: audio_manager.play_se("draw") # ペラッ音
	var rip_tw = cal_panel.create_tween()
	rip_tw.set_parallel(true)
	# 破れて右上にシュルシュルと飛んで消える！
	rip_tw.tween_property(cal_panel, "position", cal_panel.position + Vector2(300, -500), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	rip_tw.tween_property(cal_panel, "rotation_degrees", 45.0, 0.45).set_trans(Tween.TRANS_SINE)
	rip_tw.tween_property(cal_panel, "scale", Vector2(0.2, 0.2), 0.45)
	await rip_tw.finished
	# 新しい日付のカレンダーが現れる！
	var new_cal = cal_panel.duplicate() as PanelContainer
	overlay.add_child(new_cal)
	var new_v = new_cal.get_child(0) as VBoxContainer
	var new_day_lbl = new_v.get_child(1) as Label
	new_day_lbl.text = str(Global.play_count + 1)
	new_cal.position = overlay.size / 2.0 - new_cal.custom_minimum_size / 2.0
	new_cal.pivot_offset = new_cal.custom_minimum_size / 2.0
	new_cal.scale = Vector2(0.2, 0.2)
	new_cal.rotation_degrees = -30.0
	var new_tw = new_cal.create_tween()
	new_tw.set_parallel(true)
	new_tw.tween_property(new_cal, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	new_tw.tween_property(new_cal, "rotation_degrees", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	if audio_manager: audio_manager.play_se("combo")
	await new_tw.finished
	await get_tree().create_timer(0.8).timeout
	# 暗転を解除してカバン構築画面へ
	var fade_tw = overlay.create_tween()
	fade_tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	await fade_tw.finished
	overlay.queue_free()
	_show_bag_builder()
func _show_blackboard_progress():
	_clear_screen()
	
	# 背景に見開きノートを置く（ふせんフェーズと同じ世界観を維持）
	var notebook = _create_double_page_notebook()
	notebook.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notebook.offset_left = (1920.0 - 1380.0) / 2.0
	notebook.offset_top = (1080.0 - 920.0) / 2.0
	notebook.offset_right = -notebook.offset_left
	notebook.offset_bottom = -notebook.offset_top
	screen_content.add_child(notebook)
	
	# 左側の机の上エリア（スマホ置き場）
	var left_area = Control.new()
	left_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_area.anchor_right = 0.3 # 画面左側30%
	screen_content.add_child(left_area)
	
	var app_container = _create_smartphone_mockup(left_area, false)
	# 1. アプリヘッダー (Studyplus風)
	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 56)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("ffffff") # 白クリーンなヘッダー
	header_style.border_width_bottom = 2
	header_style.border_color = Color("e1e4e6")
	header.add_theme_stylebox_override("panel", header_style)
	app_container.add_child(header)
	var header_h = HBoxContainer.new()
	header_h.add_theme_constant_override("separation", 10)
	header_h.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(header_h)
	# チキスタアプリアイコン (ニワトリ＆鉛筆のデフォルメアバター)
	var app_icon = ColorRect.new()
	app_icon.custom_minimum_size = Vector2(32, 32)
	app_icon.color = DeskTheme.COLOR_SAFE
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = DeskTheme.COLOR_SAFE
	icon_style.corner_radius_top_left = 8; icon_style.corner_radius_top_right = 8
	icon_style.corner_radius_bottom_left = 8; icon_style.corner_radius_bottom_right = 8
	app_icon.add_theme_stylebox_override("panel", icon_style)
	header_h.add_child(app_icon)
	var app_icon_lbl = DeskTheme.create_label("S", 18, Color.WHITE)
	app_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app_icon.add_child(app_icon_lbl)
	var header_title = DeskTheme.create_label("チキスタ !", 22, DeskTheme.COLOR_SAFE, true)
	header_h.add_child(header_title)
	# ==========================================
	# 1.5 タブ切り替えボタンの配置 (Day 1 は解説タブを開く)
	# ==========================================
	var tab_hbox = HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 16)
	var margin_tab = MarginContainer.new()
	margin_tab.add_theme_constant_override("margin_top", 10)
	margin_tab.add_theme_constant_override("margin_bottom", 4)
	margin_tab.add_child(tab_hbox)
	app_container.add_child(margin_tab)
	
	var default_tab = 0 if Global.play_count == 0 else 1
	var active_tab_state = {"active": default_tab}
	
	var tab_rules_btn = DeskTheme.create_button("解説", Vector2(160, 42), Color.WHITE, DeskTheme.COLOR_MUTED)
	var tab_feed_btn = DeskTheme.create_button("タイムライン", Vector2(180, 42), Color.WHITE, DeskTheme.COLOR_MUTED)
	tab_rules_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	tab_feed_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	tab_hbox.add_child(tab_rules_btn)
	tab_hbox.add_child(tab_feed_btn)
	
	# ==========================================
	# 2-A. アプリ内メインスクロールエリア (解説画面)
	# ==========================================
	var rules_scroll = ScrollContainer.new()
	rules_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app_container.add_child(rules_scroll)
	
	var rules_view = VBoxContainer.new()
	rules_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_view.add_theme_constant_override("separation", 16)
	rules_scroll.add_child(rules_view)
	
	var rules_margin = MarginContainer.new()
	rules_margin.add_theme_constant_override("margin_left", 16)
	rules_margin.add_theme_constant_override("margin_right", 16)
	rules_margin.add_theme_constant_override("margin_top", 16)
	rules_margin.add_theme_constant_override("margin_bottom", 16)
	rules_view.add_child(rules_margin)
	
	var rules_content_v = VBoxContainer.new()
	rules_content_v.add_theme_constant_override("separation", 16)
	rules_margin.add_child(rules_content_v)
	
	var rules_card = PanelContainer.new()
	var rules_card_style = StyleBoxFlat.new()
	rules_card_style.bg_color = Color.WHITE
	rules_card_style.corner_radius_top_left = 16; rules_card_style.corner_radius_top_right = 16
	rules_card_style.corner_radius_bottom_left = 16; rules_card_style.corner_radius_bottom_right = 16
	rules_card_style.border_width_bottom = 4
	rules_card_style.border_color = Color("e6e8eb")
	rules_card_style.content_margin_left = 16; rules_card_style.content_margin_right = 16
	rules_card_style.content_margin_top = 16; rules_card_style.content_margin_bottom = 16
	rules_card.add_theme_stylebox_override("panel", rules_card_style)
	rules_content_v.add_child(rules_card)
	
	var explain_v = VBoxContainer.new()
	explain_v.add_theme_constant_override("separation", 12)
	rules_card.add_child(explain_v)
	
	explain_v.add_child(DeskTheme.create_label("朝の会の遊び方", 18, DeskTheme.COLOR_SAFE, true))
	
	var desc = DeskTheme.create_label("ここではライバル達の勉強報告（点数）がタイムラインに流れてきます！\n嘘を見破るか、正直者を応援するかの心理戦です！", 14, DeskTheme.COLOR_INK, true)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explain_v.add_child(desc)
	
	explain_v.add_child(HSeparator.new())
	
	var rule1 = DeskTheme.create_label("指摘する (疑う)", 16, DeskTheme.COLOR_BLUFF_RED, true)
	explain_v.add_child(rule1)
	var desc1 = DeskTheme.create_label("・相手がバーストしたのに『嘘の点数』を盛って報告していると思ったら、「指摘」をタップ！\n・見事見破れば相手に大ダメージ(マイナス点)！", 14, DeskTheme.COLOR_INK, true)
	desc1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explain_v.add_child(desc1)
	
	var rule2 = DeskTheme.create_label("応援する", 16, DeskTheme.COLOR_SAFE, true)
	explain_v.add_child(rule2)
	var desc2 = DeskTheme.create_label("・相手が『正直な点数』を報告していると思ったら「応援」をタップ！\n・応援された正直者はプラスの応援ボーナスを獲得！", 14, DeskTheme.COLOR_INK, true)
	desc2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explain_v.add_child(desc2)
	
	var to_feed_btn = DeskTheme.create_button("タイムラインを見る", Vector2(280, 52), DeskTheme.COLOR_SAFE, Color("1e7b85"))
	to_feed_btn.add_theme_font_size_override("font_size", 16)
	rules_content_v.add_child(to_feed_btn)
	
	# ==========================================
	# 2-B. アプリ内メインスクロールエリア (タイムライン)
	# ==========================================
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app_container.add_child(scroll)
	
	var update_tabs = func():
		if active_tab_state["active"] == 0:
			tab_rules_btn.modulate = Color.WHITE
			tab_feed_btn.modulate = Color(0.7, 0.75, 0.8)
			rules_scroll.show()
			scroll.hide()
		else:
			tab_rules_btn.modulate = Color(0.7, 0.75, 0.8)
			tab_feed_btn.modulate = Color.WHITE
			rules_scroll.hide()
			scroll.show()
			
	update_tabs.call()
			
	tab_rules_btn.pressed.connect(func():
		if audio_manager: audio_manager.play_se("click")
		active_tab_state["active"] = 0
		update_tabs.call()
	)
	tab_feed_btn.pressed.connect(func():
		if audio_manager: audio_manager.play_se("click")
		active_tab_state["active"] = 1
		update_tabs.call()
	)
	to_feed_btn.pressed.connect(func():
		if audio_manager: audio_manager.play_se("click")
		active_tab_state["active"] = 1
		update_tabs.call()
	)
	var feed_v = VBoxContainer.new()
	feed_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_v.add_theme_constant_override("separation", 14)
	scroll.add_child(feed_v)
	# フィード内のパディング用マージン
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 12)
	margin_c.add_theme_constant_override("margin_top", 12)
	margin_c.add_theme_constant_override("margin_right", 12)
	margin_c.add_theme_constant_override("margin_bottom", 12)
	feed_v.add_child(margin_c)
	var card_v = VBoxContainer.new()
	card_v.add_theme_constant_override("separation", 14)
	margin_c.add_child(card_v)
	# 今日の進捗サマリー (プロシージャル統計表示)
	var stats_card = PanelContainer.new()
	stats_card.custom_minimum_size = Vector2(0, 110)
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color("f1f3f5")
	stats_style.corner_radius_top_left = 12; stats_style.corner_radius_top_right = 12
	stats_style.corner_radius_bottom_left = 12; stats_style.corner_radius_bottom_right = 12
	stats_card.add_theme_stylebox_override("panel", stats_style)
	card_v.add_child(stats_card)
	var stats_h = HBoxContainer.new()
	stats_h.add_theme_constant_override("separation", 12)
	stats_h.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_card.add_child(stats_h)
	stats_h.add_child(DeskTheme.create_label("[ 本日の全教科勉強進捗 ]", 14, DeskTheme.COLOR_INK, true))
	# 5連ミニ進捗バーによる分布可視化
	var stats_bar_v = VBoxContainer.new()
	stats_bar_v.add_theme_constant_override("separation", 4)
	stats_h.add_child(stats_bar_v)
	var tops = backend_manager.get_subject_top_scores()
	for s in range(5):
		var sb_h = HBoxContainer.new()
		sb_h.add_theme_constant_override("separation", 6)
		stats_bar_v.add_child(sb_h)
		var s_lbl = DeskTheme.create_label(DeskTheme.subject_name(s), 13, DeskTheme.subject_color(s), true)
		sb_h.add_child(s_lbl)
		var s_bar = DeskTheme.create_gauge_bar(0.0, 20.0, DeskTheme.subject_color(s), Vector2(140, 10))
		var s_fill = s_bar.get_child(1)
		s_fill.offset_right = max(4.0, 140.0 * clamp(float(tops[s]["score"]) / 20.0, 0.0, 1.0))
		sb_h.add_child(s_bar)
	# フィードカード (各教科のトップ成績 ＝ ライバルの勉強投稿)
	# 💡 一日目は「まだ誰も勉強を投稿していない」ため、タイムラインを非表示にして応援/順位UIも見せない温かいウエルカムガイドを表示
	if Global.play_count == 0:
		var welcome_card = PanelContainer.new()
		welcome_card.custom_minimum_size = Vector2(0, 240)
		var wc_style = StyleBoxFlat.new()
		wc_style.bg_color = Color("f8f9fa")
		wc_style.corner_radius_top_left = 16; wc_style.corner_radius_top_right = 16
		wc_style.corner_radius_bottom_left = 16; wc_style.corner_radius_bottom_right = 16
		wc_style.border_width_bottom = 3; wc_style.border_color = Color("e6e8eb")
		wc_style.content_margin_left = 16; wc_style.content_margin_right = 16
		wc_style.content_margin_top = 20; wc_style.content_margin_bottom = 20
		welcome_card.add_theme_stylebox_override("panel", wc_style)
		card_v.add_child(welcome_card)
		
		var welcome_v = VBoxContainer.new()
		welcome_v.add_theme_constant_override("separation", 16)
		welcome_card.add_child(welcome_v)
		
		var welcome_title = DeskTheme.create_label("[ タイムラインのお知らせ ]", 16, DeskTheme.COLOR_SAFE, true)
		welcome_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		welcome_v.add_child(welcome_title)
		
		var welcome_desc = DeskTheme.create_label("タイムラインは【明日（2日目）の朝の会】から動き出します！\n\nライバル達は、あなたが今日の学習を報告するのを待っています。\n学習計画ノートにふせんを貼って、チキスタで本日の学習報告を投稿しましょう！", 14, DeskTheme.COLOR_INK, true)
		welcome_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		welcome_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		welcome_v.add_child(welcome_desc)
	else:
		var state = {"liked": false}
		for s in range(5):
			var top = tops[s]
			var card = PanelContainer.new()
			card.custom_minimum_size = Vector2(0, 52)
			var card_style = StyleBoxFlat.new()
			card_style.bg_color = Color.WHITE # 清潔なStudyplus風白カード
			card_style.corner_radius_top_left = 10; card_style.corner_radius_top_right = 10
			card_style.corner_radius_bottom_left = 10; card_style.corner_radius_bottom_right = 10
			card_style.border_width_bottom = 2
			card_style.border_color = Color("eef0f2")
			card.add_theme_stylebox_override("panel", card_style)
			card_v.add_child(card)
			
			var c_h = HBoxContainer.new()
			c_h.add_theme_constant_override("separation", 10)
			var card_margin = MarginContainer.new()
			card_margin.add_theme_constant_override("margin_left", 8)
			card_margin.add_theme_constant_override("margin_right", 8)
			card_margin.add_theme_constant_override("margin_top", 6)
			card_margin.add_theme_constant_override("margin_bottom", 6)
			card.add_child(card_margin)
			card_margin.add_child(c_h)
			
			# 1. 丸型ミニカラーバッジアバター
			var avatar = PanelContainer.new()
			avatar.custom_minimum_size = Vector2(28, 28)
			var avatar_style = StyleBoxFlat.new()
			avatar_style.bg_color = DeskTheme.subject_color(s)
			avatar_style.corner_radius_top_left = 14; avatar_style.corner_radius_top_right = 14
			avatar_style.corner_radius_bottom_left = 14; avatar_style.corner_radius_bottom_right = 14
			avatar.add_theme_stylebox_override("panel", avatar_style)
			c_h.add_child(avatar)
			
			var av_lbl = DeskTheme.create_label(top["name"].left(1) if top["name"] != "なし" else "-", 12, Color.WHITE, true)
			av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			av_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			avatar.add_child(av_lbl)
			
			# 2. 教科名・名前・点数の一行まとめテキスト
			var text_content = "%s: %s (%d点)" % [DeskTheme.subject_name(s), top["name"], top["score"]]
			if top["name"] == "なし" or top["name"] == "誰もいない":
				text_content = "%s: 待機中..." % DeskTheme.subject_name(s)
			var details_lbl = DeskTheme.create_label(text_content, 13, DeskTheme.COLOR_INK, true)
			details_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			details_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			c_h.add_child(details_lbl)
			
			# 3. 疑う と 応援 の極小丸型ボタン (他人かつ有効な相手のみ)
			if top["name"] != Global.player_name and top["name"] != "なし" and top["name"] != "誰もいない":
				# 疑うボタン (小丸)
				var like_btn = Button.new()
				like_btn.custom_minimum_size = Vector2(30, 30)
				like_btn.size = Vector2(30, 30)
				var lb_normal = StyleBoxFlat.new()
				lb_normal.bg_color = Color("fff0f0")
				lb_normal.border_width_left = 1.0; lb_normal.border_width_right = 1.0
				lb_normal.border_width_top = 1.0; lb_normal.border_width_bottom = 1.0
				lb_normal.border_color = Color("ad3b3b")
				lb_normal.corner_radius_top_left = 15; lb_normal.corner_radius_top_right = 15
				lb_normal.corner_radius_bottom_left = 15; lb_normal.corner_radius_bottom_right = 15
				like_btn.add_theme_stylebox_override("normal", lb_normal)
				like_btn.add_theme_stylebox_override("hover", lb_normal)
				
				var lb_disabled = StyleBoxFlat.new()
				lb_disabled.bg_color = Color("ad3b3b")
				lb_disabled.corner_radius_top_left = 15; lb_disabled.corner_radius_top_right = 15
				lb_disabled.corner_radius_bottom_left = 15; lb_disabled.corner_radius_bottom_right = 15
				like_btn.add_theme_stylebox_override("disabled", lb_disabled)
				
				like_btn.text = "疑"
				like_btn.add_theme_color_override("font_color", Color("ad3b3b"))
				like_btn.add_theme_color_override("font_disabled_color", Color.WHITE)
				like_btn.add_theme_font_size_override("font_size", 11)
				like_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				
				like_btn.pressed.connect(func():
					if state["liked"]: return
					state["liked"] = true
					if audio_manager: audio_manager.play_se("place")
					like_btn.disabled = true
					# 相手が嘘をついているか判定
					var is_bluff = randf() < 0.6 if top["score"] >= 16 else randf() < 0.2
					if top["name"] == "ブラフの達人": is_bluff = true
					if top["name"] == "慎重な優等生": is_bluff = false
					if is_bluff:
						_show_toast("相手は嘘を報告していた！\nプレッシャーで翌日のペナルティが倍増！", DeskTheme.COLOR_BLUFF_RED)
					else:
						_show_toast("相手は正直に勉強していた！\nペナルティは発生しなかった。", DeskTheme.COLOR_SAFE)
				)
				c_h.add_child(like_btn)
				
				# 応援ボタン (小丸)
				var cheer_btn = Button.new()
				cheer_btn.custom_minimum_size = Vector2(30, 30)
				cheer_btn.size = Vector2(30, 30)
				var cb_normal = StyleBoxFlat.new()
				cb_normal.bg_color = Color("f0fffb")
				cb_normal.border_width_left = 1.0; cb_normal.border_width_right = 1.0
				cb_normal.border_width_top = 1.0; cb_normal.border_width_bottom = 1.0
				cb_normal.border_color = Color("1e7b85")
				cb_normal.corner_radius_top_left = 15; cb_normal.corner_radius_top_right = 15
				cb_normal.corner_radius_bottom_left = 15; cb_normal.corner_radius_bottom_right = 15
				cheer_btn.add_theme_stylebox_override("normal", cb_normal)
				cheer_btn.add_theme_stylebox_override("hover", cb_normal)
				
				var cb_disabled = StyleBoxFlat.new()
				cb_disabled.bg_color = Color("1e7b85")
				cb_disabled.corner_radius_top_left = 15; cb_disabled.corner_radius_top_right = 15
				cb_disabled.corner_radius_bottom_left = 15; cb_disabled.corner_radius_bottom_right = 15
				cheer_btn.add_theme_stylebox_override("disabled", cb_disabled)
				
				cheer_btn.text = "応"
				cheer_btn.add_theme_color_override("font_color", Color("1e7b85"))
				cheer_btn.add_theme_color_override("font_disabled_color", Color.WHITE)
				cheer_btn.add_theme_font_size_override("font_size", 11)
				cheer_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				
				cheer_btn.pressed.connect(func():
					if state["liked"]: return
					state["liked"] = true
					if audio_manager: audio_manager.play_se("combo")
					cheer_btn.disabled = true
					_show_toast("%s を心から応援した！\nタイムラインに温かい拍手が送られました。" % top["name"], DeskTheme.COLOR_SAFE)
				)
				c_h.add_child(cheer_btn)
	# 3. アプリフッター (翌日の勉強へ進むボタン)
	var footer = PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 72)
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = Color("ffffff")
	footer_style.border_width_top = 2
	footer_style.border_color = Color("e1e4e6")
	footer.add_theme_stylebox_override("panel", footer_style)
	app_container.add_child(footer)
	var footer_h = HBoxContainer.new()
	footer_h.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(footer_h)
	var next_btn = DeskTheme.create_button("明日の学習へ進む", Vector2(280, 52), DeskTheme.COLOR_SAFE, Color("2d928a"))
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.pressed.connect(func():
		if audio_manager: audio_manager.play_se("click")
		backend_manager.load_daily_scores()
		_show_loading()
	)
	footer_h.add_child(next_btn)
# ----------------------------------------------------
# 6. 【翌日朝の会】「いいね」結果発表スタンプ演出シーケンス
# ----------------------------------------------------
func _trigger_daily_likes_sequence():
	if Global.play_count == 0:
		return
	if bag_ui_elements.get("bonus_given_done", false):
		return
	bag_ui_elements["bonus_given_done"] = true
	# A. 前日の王座（日次トップ）配当の付与
	if Global.last_top_subjects.size() > 0:
		var bonus_earned = 0
		var bonus_text = ""
		for s in Global.last_top_subjects:
			bonus_earned += 5
			bonus_text += " " + DeskTheme.subject_name(s)
		if bonus_earned > 0:
			Global.total_score += bonus_earned
			_show_toast("日次トップ配当＋%d点！ (王座: %s)" % [bonus_earned, bonus_text], DeskTheme.COLOR_ACCENT_GOLD)
			if audio_manager: audio_manager.play_se("combo")
			await get_tree().create_timer(1.2).timeout
	# B. 全体報告に対する「いいね」被弾判定（1回の大きなスタンプ！）
	var score_changed = false
	var lie_diff_total = 0
	var modest_diff_total = 0
	
	for s in range(5):
		var actual = Global.last_actual_scores.get(s, 0)
		var reported = Global.last_reported_scores.get(s, 0)
		if reported > actual: lie_diff_total += (reported - actual)
		elif reported < actual: modest_diff_total += (actual - reported)
		
	# ターゲット（ノートパネル全体を揺らす）
	var note_panel_node = null
	for c in screen_content.get_children():
		if c is HBoxContainer:
			for gc in c.get_children():
				if gc is PanelContainer and gc.size_flags_horizontal == Control.SIZE_EXPAND_FILL:
					note_panel_node = gc
					break
			if note_panel_node != null: break
	if note_panel_node == null: note_panel_node = screen_content
	if note_panel_node == null: note_panel_node = screen_content
	
	await get_tree().create_timer(0.5).timeout
	
	if lie_diff_total > 0:
		# 1. 嘘報告だった場合の「見破り」判定（50%の確率）
		if randf() < 0.5:
			score_changed = true
			var penalty = lie_diff_total * 2
			Global.total_score = max(0, Global.total_score - penalty)
			
			var stamp = DeskTheme.create_app_stamp("疑 [!]", DeskTheme.COLOR_BLUFF_RED, 28)
			stamp.position = note_panel_node.size / 2.0 - stamp.size / 2.0
			note_panel_node.add_child(stamp)
			stamp.pivot_offset = stamp.size / 2.0
			stamp.scale = Vector2(4.0, 4.0)
			stamp.modulate.a = 0.0
			var tw = stamp.create_tween().set_parallel(true)
			tw.tween_property(stamp, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_property(stamp, "modulate:a", 1.0, 0.08)
			tw.tween_property(stamp, "rotation_degrees", randf_range(-15.0, 15.0), 0.15)
			if audio_manager: audio_manager.play_se("burst")
			_show_toast("【見破り】嘘の報告がバレた！\n(偽造合計%d点 × 2) −%d点！" % [lie_diff_total, penalty], DeskTheme.COLOR_BLUFF_RED)
			
			var s_tw = note_panel_node.create_tween()
			s_tw.tween_property(note_panel_node, "position:y", note_panel_node.position.y + 8, 0.06)
			s_tw.tween_property(note_panel_node, "position:y", note_panel_node.position.y - 8, 0.06)
			s_tw.tween_property(note_panel_node, "position:y", note_panel_node.position.y, 0.06)
	elif modest_diff_total > 0:
		# 3. 謙虚報告だった場合の「応援」判定（50%の確率）
		if randf() < 0.5:
			score_changed = true
			var modest_bonus = 10 + modest_diff_total * 3
			Global.total_score += modest_bonus
			
			var stamp = DeskTheme.create_app_stamp("応援 [OK]", DeskTheme.COLOR_SAFE, 28)
			stamp.position = note_panel_node.size / 2.0 - stamp.size / 2.0
			note_panel_node.add_child(stamp)
			stamp.pivot_offset = stamp.size / 2.0
			stamp.scale = Vector2(4.0, 4.0)
			stamp.modulate.a = 0.0
			var tw = stamp.create_tween().set_parallel(true)
			tw.tween_property(stamp, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_property(stamp, "modulate:a", 1.0, 0.08)
			tw.tween_property(stamp, "rotation_degrees", randf_range(-15.0, 15.0), 0.15)
			if audio_manager: audio_manager.play_se("combo")
			_show_toast("【謙虚応援】控えめな報告にいいね！\nボーナス (基本10＋差分%d点×3): ＋%d点！" % [modest_diff_total, modest_bonus], DeskTheme.COLOR_SAFE)
			
			var s_tw = note_panel_node.create_tween()
			s_tw.tween_property(note_panel_node, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_CUBIC)
			s_tw.tween_property(note_panel_node, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
	else:
		# 2. 正直報告だった場合の「応援」判定（50%の確率）
		if randf() < 0.5:
			score_changed = true
			Global.total_score += 10 # 正直ボーナスを少し強化
			
			var stamp = DeskTheme.create_app_stamp("応援 [OK]", DeskTheme.COLOR_SAFE, 28)
			stamp.position = note_panel_node.size / 2.0 - stamp.size / 2.0
			note_panel_node.add_child(stamp)
			stamp.pivot_offset = stamp.size / 2.0
			stamp.scale = Vector2(4.0, 4.0)
			stamp.modulate.a = 0.0
			var tw = stamp.create_tween().set_parallel(true)
			tw.tween_property(stamp, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_property(stamp, "modulate:a", 1.0, 0.08)
			tw.tween_property(stamp, "rotation_degrees", randf_range(-15.0, 15.0), 0.15)
			if audio_manager: audio_manager.play_se("combo")
			_show_toast("【応援】正直な努力にいいね！ ＋10点！", DeskTheme.COLOR_SAFE)
			
			var s_tw = note_panel_node.create_tween()
			s_tw.tween_property(note_panel_node, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_CUBIC)
			s_tw.tween_property(note_panel_node, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
	# 変化があった場合のみHUD（合計スコア）を再更新し、データを即保存
	if score_changed:
		_update_bag_ui()

		Global.save_data()

# =====================================================================
# 手書き落書き・コーヒーの輪染みを描画するプロシージャル・カスタム描画ノード
# =====================================================================
class CozyDoodleNode extends Control:
	var doodle_type: int = 0 # 0: coffee ring, 1: stars, 2: spiral, 3: tally marks
	var color: Color = Color(0.5, 0.45, 0.4, 0.15)
	
	func _init(type: int, col: Color = Color(0.5, 0.45, 0.4, 0.15)):
		self.doodle_type = type
		self.color = col
		self.mouse_filter = Control.MOUSE_FILTER_IGNORE
		self.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
	func _draw():
		match doodle_type:
			0: # Coffee ring stain (輪染み)
				var center = Vector2(80, 80)
				var radius = 45.0
				# 二重の薄い茶色の輪っかを描画
				draw_arc(center, radius, 0, TAU, 64, color, 1.5, true)
				draw_arc(center, radius + 1.5, 0.2, TAU - 0.5, 64, color * 0.8, 0.8, true)
				# 輪染みの垂れたシミをいくつかドットで描画
				draw_circle(center + Vector2(radius + 4, 10), 1.8, color * 1.2)
				draw_circle(center + Vector2(radius - 8, 38), 2.2, color * 1.0)
			1: # Hand-drawn Star (⭐)
				var center = Vector2(40, 40)
				var points = []
				var r_outer = 16.0
				var r_inner = 7.0
				for i in range(10):
					var angle = i * PI / 5.0 - PI / 2.0
					var r = r_outer if i % 2 == 0 else r_inner
					points.append(center + Vector2(cos(angle), sin(angle)) * r)
				# 連続する線で手書きの星を描く
				for i in range(10):
					draw_line(points[i], points[(i + 1) % 10], color * 1.5, 1.2, true)
				# ちいさいうずまきやハッシュマークも添える
				draw_arc(center + Vector2(25, -15), 5.0, 0, PI * 1.5, 16, color, 1.0, true)
			2: # Spiral doodle (落書きうずまき)
				var center = Vector2(50, 50)
				var last_p = center
				var num_rotations = 4.0
				var max_radius = 24.0
				for step in range(1, 100):
					var t = float(step) / 100.0
					var angle = t * num_rotations * TAU
					var r = t * max_radius
					var p = center + Vector2(cos(angle), sin(angle)) * r
					draw_line(last_p, p, color * 1.3, 1.0, true)
					last_p = p
			3: # Tally marks (正の字)
				var base = Vector2(20, 20)
				var sz = 24.0
				# 正の字を手書き風に歪ませて描く
				# 1画目: 横線
				draw_line(base + Vector2(0, sz*0.2), base + Vector2(sz, sz*0.2), color * 1.6, 1.5, true)
				# 2画目: 縦線
				draw_line(base + Vector2(sz*0.4, sz*0.2), base + Vector2(sz*0.4, sz*0.8), color * 1.6, 1.5, true)
				# 3画目: 横線（中）
				draw_line(base + Vector2(sz*0.4, sz*0.5), base + Vector2(sz*0.8, sz*0.5), color * 1.6, 1.5, true)
				# 4画目: 縦線（右）
				draw_line(base + Vector2(sz*0.8, sz*0.5), base + Vector2(sz*0.8, sz*0.8), color * 1.6, 1.5, true)
				# 5画目: 横線（下）
				draw_line(base + Vector2(sz*0.2, sz*0.8), base + Vector2(sz*0.9, sz*0.8), color * 1.6, 1.5, true)
