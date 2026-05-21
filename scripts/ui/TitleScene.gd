class_name TitleScene
extends Control

var audio_manager: AudioManager

func _ready():
	DeskTheme.decorate_scene(self, 0.16)
	audio_manager = AudioManager.new()
	add_child(audio_manager)

	# --- 散らばる文房具などの背景装飾（おもちゃ感） ---
	_add_scattered_decorations()
	
	if Global.player_name != "":
		_create_id_card()

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	DeskTheme.apply_font(vbox)
	add_child(vbox)

	vbox.add_child(DeskTheme.create_floating_badge("放課後の机の上で駆け引きする7日間", DeskTheme.COLOR_MUTED, 18))
	

	
	# タイトルロゴ
	var title_lbl = DeskTheme.create_label("テスト勉強\nチキンレース", 80, DeskTheme.COLOR_INK, true)
	# 文字に白いアウトライン（縁取り）をつける
	title_lbl.add_theme_constant_override("outline_size", 16)
	title_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	vbox.add_child(title_lbl)
	
	var sub_lbl = DeskTheme.create_label("ブラフで焦らせて、引きで勝つ。", 30, DeskTheme.COLOR_INK, true)
	sub_lbl.add_theme_constant_override("outline_size", 10)
	sub_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	vbox.add_child(sub_lbl)

	var start_btn = DeskTheme.create_button("ゲームを始める", Vector2(320, 76), DeskTheme.COLOR_SAFE, Color("0e5057"), false, 24)
	start_btn.pressed.connect(_on_start_pressed)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.pivot_offset = Vector2(160, 38)
	vbox.add_child(start_btn)
	
	# ぽよぽよTween
	var tw = start_btn.create_tween().set_loops()
	tw.tween_property(start_btn, "scale", Vector2(1.05, 1.05), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(start_btn, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var help_btn = DeskTheme.create_button("遊び方を見る", Vector2(240, 56), Color("5f6f81"), Color("445261"), false, 18)
	help_btn.pressed.connect(_show_tutorial)
	help_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(help_btn)

func _add_scattered_decorations():
	var view = get_viewport_rect().size
	if view.x < 100 or view.y < 100:
		view = Vector2(1920.0, 1080.0)
		
	var decorations = [
		{"type": "item", "val": 1, "pos": Vector2(view.x * 0.08, view.y * 0.14), "rot": -15},
		{"type": "item", "val": 2, "pos": Vector2(view.x * 0.10, view.y * 0.80), "rot": 45},
		{"type": "item", "val": 3, "pos": Vector2(view.x * 0.85, view.y * 0.14), "rot": 10},
		{"type": "card", "subj": 2, "pos": Vector2(view.x * 0.82, view.y * 0.70), "rot": -25},
		{"type": "card", "subj": 0, "pos": Vector2(view.x * 0.03, view.y * 0.50), "rot": 30}
	]
	
	for d in decorations:
		var node: Control
		if d.type == "item":
			node = TextureRect.new()
			node.texture = DeskTheme.item_texture(d.val)
			node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			node.custom_minimum_size = Vector2(80, 80)
			node.size = Vector2(80, 80)
		elif d.type == "card":
			node = DeskTheme.create_subject_card_large(d.subj, 10)
			node.scale = Vector2(0.6, 0.6)
			
		node.position = d.pos
		node.rotation_degrees = d.rot
		add_child(node)
		# 順番を調整して奥に配置
		move_child(node, 0)

func _create_id_card():
	var id_panel = PanelContainer.new()
	id_panel.custom_minimum_size = Vector2(280, 140)
	var id_style = StyleBoxFlat.new()
	id_style.bg_color = Color("fdfdfd")
	id_style.border_width_left = 6; id_style.border_color = DeskTheme.COLOR_SAFE
	id_style.corner_radius_top_right = 12; id_style.corner_radius_bottom_right = 12
	id_style.content_margin_left = 16; id_style.content_margin_top = 16
	id_style.shadow_color = DeskTheme.COLOR_SHADOW; id_style.shadow_size = 8
	id_panel.add_theme_stylebox_override("panel", id_style)
	
	id_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	# 1280x720想定の右下マージン
	id_panel.offset_left = -320; id_panel.offset_top = -180
	id_panel.offset_right = -40; id_panel.offset_bottom = -40
	add_child(id_panel)
	
	var id_vbox = VBoxContainer.new()
	id_vbox.add_theme_constant_override("separation", 8)
	id_panel.add_child(id_vbox)
	
	id_vbox.add_child(DeskTheme.create_label("【生徒手帳】", 14, DeskTheme.COLOR_MUTED, true))
	id_vbox.add_child(DeskTheme.create_label(Global.player_name, 22, DeskTheme.COLOR_INK, true))
	id_vbox.add_child(DeskTheme.create_label("CPU戦 自己ベスト:", 14, DeskTheme.COLOR_MUTED))
	
	var rank_str = "%s 級 (%d点)" % [Global.best_rank_cpu, Global.high_score_cpu]
	if Global.best_rank_cpu == "未プレイ":
		rank_str = "未プレイ"
	var rank_color = DeskTheme.COLOR_ACCENT_GOLD if Global.best_rank_cpu in ["S", "A"] else DeskTheme.COLOR_INK
	id_vbox.add_child(DeskTheme.create_label(rank_str, 18, rank_color, true))

func _on_start_pressed():
	if audio_manager: audio_manager.play_se("click")
	
	# 連打防止
	for c in get_children():
		if c is VBoxContainer:
			for cc in c.get_children():
				if cc is Button: cc.disabled = true
	
	if not Global.has_seen_tutorial:
		_show_tutorial(true)
		return
	_show_mode_select()

func _show_mode_select():
	var _overlay: ColorRect
	_overlay = DeskTheme.create_dialog_overlay(self, "プレイモード選択", func(vbox: VBoxContainer):
		vbox.add_theme_constant_override("separation", 28)
		
		# 1週間対戦（準備中）
		var global_v = VBoxContainer.new()
		global_v.alignment = BoxContainer.ALIGNMENT_CENTER
		global_v.add_theme_constant_override("separation", 6)
		vbox.add_child(global_v)
		
		var global_btn = DeskTheme.create_button("全世界のライバルと対戦 (近日公開！)", Vector2(400, 60), DeskTheme.COLOR_MUTED, DeskTheme.COLOR_MUTED, false, 20)
		global_btn.disabled = true
		global_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		global_v.add_child(global_btn)
		global_v.add_child(DeskTheme.create_label("※オンライン非同期対戦で全国のライバルとランキングを競います。", 16, DeskTheme.COLOR_CHALK_WHITE, true))
		
		# ひとりで遊ぶ（CPU戦）- アクティブ！
		var cpu_v = VBoxContainer.new()
		cpu_v.alignment = BoxContainer.ALIGNMENT_CENTER
		cpu_v.add_theme_constant_override("separation", 6)
		vbox.add_child(cpu_v)
		
		var cpu_btn = DeskTheme.create_button("ひとりで遊ぶ（CPU戦）", Vector2(400, 64), DeskTheme.COLOR_SAFE, Color("0e5057"), false, 22)
		cpu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cpu_btn.pressed.connect(func():
			if audio_manager: audio_manager.play_se("click")
			Global.current_play_mode = 1
			_start_game()
		)
		cpu_v.add_child(cpu_btn)
		cpu_v.add_child(DeskTheme.create_label("※通信なしでサクッと快適にテスト勉強を進められます。", 16, DeskTheme.COLOR_CHALK_WHITE, true))
		
		# 友達と遊ぶ（準備中）
		var room_v = VBoxContainer.new()
		room_v.alignment = BoxContainer.ALIGNMENT_CENTER
		room_v.add_theme_constant_override("separation", 6)
		vbox.add_child(room_v)
		
		var room_btn = DeskTheme.create_button("友達と対戦 (準備中)", Vector2(400, 60), DeskTheme.COLOR_MUTED, DeskTheme.COLOR_MUTED, false, 20)
		room_btn.disabled = true
		room_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		room_v.add_child(room_btn)
		room_v.add_child(DeskTheme.create_label("※合言葉を共有して友達同士で直接チキンレース対戦！", 16, DeskTheme.COLOR_CHALK_WHITE, true))
		
		# ダイアログを閉じるボタン
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		vbox.add_child(spacer)
		
		var close_btn = DeskTheme.create_button("閉じる", Vector2(200, 56), Color("bd4f4f"), Color("8a3939"), false, 18)
		close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		close_btn.pressed.connect(func():
			if audio_manager: audio_manager.play_se("click")
			var node = vbox
			while node and not node is ColorRect: node = node.get_parent()
			if node: node.queue_free()
		)
		vbox.add_child(close_btn)
	, Vector2(1320, 920))

func _start_game():
	# 新規セッション開始時に状態を完全初期化
	Global.play_count = 0
	Global.total_score = 0
	Global.cpu_data = []
	Global.last_reported_score = 0
	Global.last_actual_score = 0
	Global.score_history.clear()
	Global.accumulated_votes.clear()
	Global.save_data()
	
	var target = "res://Profile.tscn" if Global.player_name == "" else "res://Main.tscn"
	SceneTransition.fade_to_scene(target)


func _show_tutorial(start_after: bool = false):
	if audio_manager: audio_manager.play_se("click")
	
	# パッケージビルド（PCK/Web書き出し）でも安全にアセットをロードできるようにResourceLoaderのみでチェック
	var get_slide_img = func(path: String):
		if ResourceLoader.exists(path):
			return load(path)
		return null
	
	var slides = [
		{"img": get_slide_img.call("res://assets/tutorial/slide1.png"), "text": "1. まずは5つの教科に、手持ちの「学習付箋（1〜10）」を\n2枚ずつ計画ノートの『計画スロット』へ貼って学習計画を行います。"},
		{"img": get_slide_img.call("res://assets/tutorial/slide2.png"), "text": "2. 本日の勉強は1時間目〜6時間目の【計6回】のチキンレースです。\nドローしたカードは1日中そのまま引き継がれます（カウンティング要素！）。"},
		{"img": get_slide_img.call("res://assets/tutorial/slide3.png"), "text": "3. 進行中の時間目に場と同じ数字を引くと、その時間目は寝落ち（バースト）！\nバーストした時間目の獲得点数は0点になりますが、山札はそのまま引き継がれます。"},
		{"img": get_slide_img.call("res://assets/tutorial/slide4.png"), "text": "4. 勉強後、チキスタ（スマホ）で「嘘の成績（盛った点数）」を\nスライダーで報告できます。嘘がバレなければそのまま高得点をキープ！"},
		{"img": get_slide_img.call("res://assets/tutorial/slide5.png"), "text": "5. 翌朝、嘘をライバルに見破られると大ペナルティ（盛ったスコアの2倍がマイナス）！\n逆に正直者で応援スタンプを貰えると【＋5点】！極限の心理戦を勝ち抜きましょう！"},
		{"img": null, "text": "💡 必勝ワンポイントアドバイス！\nカードは1日を通じて引き継がれるため、すでに場に出たカード（カウンティング）を\n記憶しておけば、残りの時間目でバーストする確率を完璧に予測できます！"}
	]
	
	var state = {"page": 0}
	
	DeskTheme.create_dialog_overlay(self, "遊び方", func(vbox: VBoxContainer):
		var img_rect = TextureRect.new()
		img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img_rect.custom_minimum_size = Vector2(640, 360) # アスペクト比16:9を維持しつつ少し縮小して枠内に収める
		img_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(img_rect)
		
		# 画像がロードできない場合のオシャレなノート風プレースホルダー
		var placeholder = PanelContainer.new()
		placeholder.custom_minimum_size = Vector2(640, 360) # 画像サイズと完全に同期
		placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.94, 0.9) # 温かいノート紙風
		style.border_width_left = 2; style.border_width_right = 2
		style.border_width_top = 2; style.border_width_bottom = 2
		style.border_color = DeskTheme.COLOR_MUTED
		style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
		placeholder.add_theme_stylebox_override("panel", style)
		vbox.add_child(placeholder)
		
		var placeholder_v = VBoxContainer.new()
		placeholder_v.alignment = BoxContainer.ALIGNMENT_CENTER
		placeholder_v.add_theme_constant_override("separation", 8)
		placeholder.add_child(placeholder_v)
		
		placeholder_v.add_child(DeskTheme.create_label("【学習解説スライド】", 26, DeskTheme.COLOR_INK, true))
		placeholder_v.add_child(DeskTheme.create_label("※画像アセットを配置すると表示されます。\nこのままゲームを開始しても全く問題ありません！", 18, DeskTheme.COLOR_MUTED, true))
		
		var lbl = DeskTheme.create_label("", 24, DeskTheme.COLOR_CHALK_WHITE, true)
		lbl.custom_minimum_size = Vector2(0, 100)
		vbox.add_child(lbl)
		
		var btn_hbox = HBoxContainer.new()
		btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_hbox.add_theme_constant_override("separation", 32)
		vbox.add_child(btn_hbox)
		
		var prev_btn = DeskTheme.create_button("＜ 前の解説へ", Vector2(240, 64), Color("5f6f81"), Color("445261"), false, 22)
		var next_btn = DeskTheme.create_button("次へ ＞", Vector2(240, 64), DeskTheme.COLOR_SAFE, Color("0e5057"), false, 22)
		btn_hbox.add_child(prev_btn)
		btn_hbox.add_child(next_btn)
		
		var update_ui = func():
			var page = state["page"]
			var slide_img = slides[page]["img"]
			if slide_img != null:
				img_rect.texture = slide_img
				img_rect.visible = true
				placeholder.visible = false
			else:
				img_rect.visible = false
				placeholder.visible = true
				
			lbl.text = slides[page]["text"]
			prev_btn.disabled = (page == 0)
			next_btn.text = "次へ ＞" if page < slides.size() - 1 else ("ゲーム開始！" if start_after else "解説を閉じる")
			
		prev_btn.pressed.connect(func():
			if audio_manager: audio_manager.play_se("click")
			state["page"] -= 1
			update_ui.call()
		)
		
		next_btn.pressed.connect(func():
			if audio_manager: audio_manager.play_se("click")
			if state["page"] < slides.size() - 1:
				state["page"] += 1
				update_ui.call()
			else:
				Global.has_seen_tutorial = true; Global.save_data()
				var node = vbox
				while node and not node is ColorRect: node = node.get_parent()
				if node: node.queue_free()
				if start_after: _show_mode_select()
		)
		
		update_ui.call()
	, Vector2(1480, 1000))
