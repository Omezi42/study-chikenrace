class_name SmartphoneBuilder
extends RefCounted
## スマートフォンのUIモックアップおよび「チキスタ」アプリ画面を生成・管理するファクトリクラス。

static func create_mockup(ctx: GameContext, is_centered: bool = true) -> VBoxContainer:
	var phone = PanelContainer.new()
	phone.custom_minimum_size = Vector2(400, 840)
	phone.size = Vector2(400, 840)
	
	# アンカー競合を回避し、常に安定したピクセル座標で配置・Tweenする設計
	phone.anchor_left = 0.0; phone.anchor_top = 0.0; phone.anchor_right = 0.0; phone.anchor_bottom = 0.0
	if is_centered:
		phone.position = Vector2(760, 120)
		phone.rotation_degrees = 0.0
		phone.scale = Vector2(1.4, 1.4)
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
	var orig_pos = Vector2(88, 300) if not is_centered else Vector2(760, 120)
	var orig_rot = phone.rotation_degrees
	
	var put_down = func():
		if not phone.get_meta("is_picked_up", false): return
		phone.set_meta("is_picked_up", false)
		pickup_overlay.show()
		if ctx.audio_manager: ctx.audio_manager.play_se("place")
		var tw = phone.create_tween().set_parallel(true)
		tw.tween_property(phone, "position", orig_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(phone, "rotation_degrees", orig_rot, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(phone, "scale", Vector2(1.4, 1.4) if is_centered else Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		var tw_dim = dim_overlay.create_tween()
		tw_dim.tween_property(dim_overlay, "modulate:a", 0.0, 0.2)
		tw_dim.tween_callback(func(): dim_overlay.hide())
		
	var pick_up = func():
		if phone.get_meta("is_picked_up", false): return
		phone.set_meta("is_picked_up", true)
		pickup_overlay.hide()
		if ctx.audio_manager: ctx.audio_manager.play_se("draw")
		
		dim_overlay.modulate.a = 0.0
		dim_overlay.show()
		var tw_dim = dim_overlay.create_tween()
		tw_dim.tween_property(dim_overlay, "modulate:a", 1.0, 0.2)
		
		var tw = phone.create_tween().set_parallel(true)
		var target_scale = 1.4
		var target_pos = Vector2(760, 120)
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
	phone_style.bg_color = Color("202225")
	phone_style.corner_radius_top_left = 36; phone_style.corner_radius_top_right = 36
	phone_style.corner_radius_bottom_left = 36; phone_style.corner_radius_bottom_right = 36
	phone_style.border_width_left = 14; phone_style.border_width_top = 40
	phone_style.border_width_right = 14; phone_style.border_width_bottom = 40
	phone_style.border_color = Color("0f1011")
	phone_style.shadow_color = Color(0, 0, 0, 0.45)
	phone_style.shadow_size = 28
	phone_style.shadow_offset = Vector2(12, 20)
	phone.add_theme_stylebox_override("panel", phone_style)
	
	ctx.screen_content.add_child(dim_overlay)
	dim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_overlay.size = Vector2(1920, 1080)
	dim_overlay.position = Vector2.ZERO
	
	ctx.screen_content.add_child(phone)
	ctx.bag_ui_elements["report_page"] = phone
	
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
	
	# リアルなスマホステータスバー
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
	
	phone.add_child(pickup_overlay)
	DeskTheme.animate_entrance(phone)
	return app_container

static func on_chikista_tab_pressed(ctx: GameContext, tab_idx: int, scroll_container: ScrollContainer) -> void:
	if ctx.chikista_active_tab == tab_idx: return
	if ctx.audio_manager: ctx.audio_manager.play_se("click")
	ctx.chikista_active_tab = tab_idx
	
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
			_build_timeline_feed(ctx, feed_v)
		elif tab_idx == 1:
			_build_analysis_tab(ctx, feed_v)
		elif tab_idx == 2:
			_build_goals_tab(ctx, feed_v)
	)
	tw.tween_property(scroll_container, "modulate:a", 1.0, 0.1)

static func _build_timeline_feed(ctx: GameContext, feed_v: VBoxContainer) -> void:
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
	
	var tips_banner = PanelContainer.new()
	var tips_style = StyleBoxFlat.new()
	tips_style.bg_color = Color("e8f4fd")
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
	
	var timelines = ctx.backend_manager.get_timeline_feeds()
	
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
		var scores = entry["scores"]
		var actuals = entry.get("actual_scores", {})
		
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color("ffffff")
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
		
		var user_h = HBoxContainer.new()
		user_h.add_theme_constant_override("separation", 12)
		card_v.add_child(user_h)
		
		var rank_color = DeskTheme.COLOR_INK
		if rank_idx == 1: rank_color = DeskTheme.COLOR_ACCENT_GOLD
		elif rank_idx == 2: rank_color = Color("a0aab2")
		elif rank_idx == 3: rank_color = Color("cd7f32")
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
		
		var is_bluffing = false
		for s in range(5):
			var reported_val = scores.get(s, 0)
			var actual_val = actuals.get(s, reported_val)
			
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
			
		var like_h = HBoxContainer.new()
		like_h.alignment = BoxContainer.ALIGNMENT_CENTER
		body_v.add_child(like_h)
		
		var already_voted = ctx.backend_manager.has_voted_rival(rival_name, -1)
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
			if ctx.backend_manager.has_voted_rival(rival_name, -1): return
			ctx.backend_manager.vote_rival(rival_name, -1)
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
			
			if ctx.audio_manager:
				ctx.audio_manager.play_se('place')
			
			if is_bluffing:
				ToastOverlay.show_toast(ctx.ui_root, '💢 いいね！で見破りのプレッシャーを送った！', DeskTheme.COLOR_BLUFF_RED)
			else:
				ToastOverlay.show_toast(ctx.ui_root, '👍 いいね！で正直な努力を応援！\n(相手に正直ボーナス！)', DeskTheme.COLOR_SAFE)
		)

static func _build_analysis_tab(ctx: GameContext, feed_v: VBoxContainer) -> void:
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
		if is_instance_valid(ctx.game_session):
			score = ctx.game_session.subject_scores[s]
			
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

static func _build_goals_tab(ctx: GameContext, feed_v: VBoxContainer) -> void:
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
