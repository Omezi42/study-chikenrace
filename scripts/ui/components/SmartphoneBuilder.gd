class_name SmartphoneBuilder
extends RefCounted
## スマートフォンのUIモックアップおよび「チキスタ」アプリ画面を生成・管理するファクトリクラス。

const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")

static func create_mockup(ctx: RefCounted, is_centered: bool = true) -> VBoxContainer:
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
	
	var dim_overlay = ColorRect.new()
	dim_overlay.color = Color(0, 0, 0, 0.65)
	dim_overlay.custom_minimum_size = Vector2(1920, 1080)
	dim_overlay.visible = is_centered
	dim_overlay.modulate.a = 1.0 if is_centered else 0.0
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if is_centered else Control.MOUSE_FILTER_IGNORE
	
	var pickup_overlay = Button.new()
	pickup_overlay.name = "PickupOverlay"
	pickup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pickup_overlay.flat = true
	pickup_overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if is_centered: pickup_overlay.hide()
	
	phone.set_meta("is_picked_up", is_centered)
	var default_orig_pos = Vector2(88, 300) if not is_centered else Vector2(760, 120)
	var orig_pos = phone.get_meta("orig_pos", default_orig_pos)
	var orig_rot = phone.rotation_degrees
	
	var put_down = func():
		if phone.get_meta("lock_zoom", false): return # ズームがロックされている場合は無視
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
		tw_dim.tween_callback(func():
			dim_overlay.hide()
			dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		)
		
	var pick_up = func():
		if phone.get_meta("is_picked_up", false): return
		phone.set_meta("is_picked_up", true)
		pickup_overlay.hide()
		if ctx.audio_manager: ctx.audio_manager.play_se("draw")
		
		dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
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

	dim_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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

static func build_standard_smartphone(ctx: RefCounted) -> VBoxContainer:
	var app_container = create_mockup(ctx, false)
	
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
	
	app_header_h.add_child(DeskTheme.create_label("チキスタ !", 18, DeskTheme.COLOR_SAFE, true))
	
	var app_scroll = ScrollContainer.new()
	app_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app_container.add_child(app_scroll)
	
	var feed_v = VBoxContainer.new()
	feed_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_v.add_theme_constant_override("separation", 10)
	app_scroll.add_child(feed_v)
	ctx.chikista_active_tab = 0
	_build_timeline_feed(ctx, feed_v)
	
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
	
	var tabs_info = [{"text": "タイムライン", "idx": 0}, {"text": "学習分析", "idx": 1}, {"text": "目標", "idx": 2}]
	for tab in tabs_info:
		var tab_btn = Button.new()
		tab_btn.text = tab["text"]
		tab_btn.custom_minimum_size = Vector2(110, 48)
		tab_btn.add_theme_font_override("font", DeskTheme.DEFAULT_FONT)
		tab_btn.add_theme_font_size_override("font_size", 13)
		tab_btn.add_theme_color_override("font_color", DeskTheme.COLOR_MUTED)
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
		b_pressed.corner_radius_top_left = 8; b_pressed.corner_radius_bottom_left = 8
		tab_btn.add_theme_stylebox_override("pressed", b_pressed)
		tab_btn.pressed.connect(on_chikista_tab_pressed.bind(ctx, tab["idx"], app_scroll))
		app_footer_h.add_child(tab_btn)
		
	return app_container

static func on_chikista_tab_pressed(ctx: RefCounted, tab_idx: int, scroll_container: ScrollContainer) -> void:
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

static func _build_timeline_feed(ctx: RefCounted, feed_v: VBoxContainer) -> void:
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 8)
	margin_c.add_theme_constant_override("margin_top", 8)
	margin_c.add_theme_constant_override("margin_right", 8)
	margin_c.add_theme_constant_override("margin_bottom", 8)
	feed_v.add_child(margin_c)
	
	var cards_v = VBoxContainer.new()
	cards_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_v.add_theme_constant_override("separation", 6)
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
	
	tips_v.add_child(DeskTheme.create_label("[チキスタ運営事務局]", 14, Color("1da1f2"), true))
	var tips_msg = DeskTheme.create_label("アイコンをタップで詳細プロフ！ライバルに【👍】を突きつけてダウト(嘘告発)しましょう！嘘を暴けばボーナス、冤罪はペナルティ！", 12, DeskTheme.COLOR_INK)
	tips_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_v.add_child(tips_msg)
	
	# 💡 1日3回投票権のUI表示
	var vote_count = ctx.backend_manager.get_daily_vote_count()
	var vote_info_panel = PanelContainer.new()
	var vi_style = StyleBoxFlat.new()
	vi_style.bg_color = Color("fff9db") # 警告イエロー
	vi_style.border_width_bottom = 2
	vi_style.border_color = Color("ffe066")
	vi_style.corner_radius_top_left = 8; vi_style.corner_radius_top_right = 8
	vi_style.corner_radius_bottom_left = 8; vi_style.corner_radius_bottom_right = 8
	vi_style.content_margin_left = 8; vi_style.content_margin_right = 8
	vi_style.content_margin_top = 4; vi_style.content_margin_bottom = 4
	vote_info_panel.add_theme_stylebox_override("panel", vi_style)
	cards_v.add_child(vote_info_panel)
	
	var vote_info_hbox = HBoxContainer.new()
	vote_info_panel.add_child(vote_info_hbox)
	
	var votes_left_lbl = DeskTheme.create_label("本日のダウト投票権 (👍): %d / 3" % (3 - vote_count), 13, Color("f59f00"), true)
	vote_info_hbox.add_child(votes_left_lbl)
	
	var active_like_buttons = []
	
	if Global.play_count == 0:
		vote_info_panel.hide() # 1日目は非表示
		var guide_card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color("ffffff")
		card_style.corner_radius_top_left = 10; card_style.corner_radius_top_right = 10
		card_style.corner_radius_bottom_left = 10; card_style.corner_radius_bottom_right = 10
		card_style.content_margin_left = 12; card_style.content_margin_right = 12
		card_style.content_margin_top = 12; card_style.content_margin_bottom = 12
		card_style.shadow_color = Color(0,0,0, 0.05)
		card_style.shadow_size = 4
		guide_card.add_theme_stylebox_override("panel", card_style)
		cards_v.add_child(guide_card)
		
		var guide_v = VBoxContainer.new()
		guide_v.add_theme_constant_override("separation", 10)
		guide_card.add_child(guide_v)
		
		guide_v.add_child(DeskTheme.create_label("[ チキスタ！ご利用ガイド (1日目) ]", 15, DeskTheme.COLOR_SAFE, true))
		
		var body = "チキスタへようこそ！ここは全国のライバルたちの学習報告が流れる非同期SNSです。\n\n" + \
			"【基本の流れ】\n" + \
			"1. ノートで計画を立てて付箋を貼る\n" + \
			"2. ドローで限界まで勉強（チキンレース）\n" + \
			"3. 結果を報告（実力以上の大ボラ報告も可能！）\n" + \
			"4. 翌朝、相手の嘘と思われる報告に【👍 (ダウト)】を押す！(1日最大3回まで)\n\n" + \
			"※明日（2日目）の朝からライバルの学習記録がここにリアルタイムで表示されるようになります！本日はまず自分の学習計画を立てて勉強を始めましょう！"
		
		var body_lbl = DeskTheme.create_label(body, 12, DeskTheme.COLOR_INK)
		body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		guide_v.add_child(body_lbl)
		return
		
	var timelines = ctx.backend_manager.get_timeline_feeds()
	timelines.sort_custom(func(a, b):
		var sum_a = 0
		for s in a["scores"]: sum_a += a["scores"][s]
		var sum_b = 0
		for s in b["scores"]: sum_b += b["scores"][s]
		return sum_a > sum_b
	)
	if timelines.size() == 0:
		cards_v.add_child(DeskTheme.create_label("タイムラインが空です。", 14, DeskTheme.COLOR_MUTED, true))
	
	var rank_idx = 1
	for entry in timelines:
		var rival_name = entry["name"]
		var scores = entry["scores"]
		var actuals = entry.get("actual_scores", {})
		var total_score = 0
		var is_bluffing = false
		for s in range(5):
			var r_val = scores.get(str(s), scores.get(s, 0))
			total_score += r_val
			var a_val = actuals.get(str(s), actuals.get(s, r_val))
			if r_val > a_val: is_bluffing = true
		
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color("ffffff")
		card_style.corner_radius_top_left = 8; card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_left = 8; card_style.corner_radius_bottom_right = 8
		card_style.content_margin_left = 8; card_style.content_margin_right = 8
		card_style.content_margin_top = 8; card_style.content_margin_bottom = 8
		card_style.shadow_color = Color(0,0,0, 0.05)
		card_style.shadow_size = 2
		card.add_theme_stylebox_override("panel", card_style)
		cards_v.add_child(card)
		
		var card_h = HBoxContainer.new()
		card_h.add_theme_constant_override("separation", 8)
		card_h.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(card_h)
		
		# 順位
		var rank_color = DeskTheme.COLOR_INK
		if rank_idx == 1: rank_color = DeskTheme.COLOR_ACCENT_GOLD
		elif rank_idx == 2: rank_color = Color("a0aab2")
		elif rank_idx == 3: rank_color = Color("cd7f32")
		var rank_str = "1位" if rank_idx == 1 else str(rank_idx)
		var rank_lbl = DeskTheme.create_label(rank_str, 16, rank_color, true)
		rank_lbl.custom_minimum_size = Vector2(30, 0)
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_h.add_child(rank_lbl)
		rank_idx += 1
		
		# プロフィールボタン (アイコン＋名前)
		var prof_btn = Button.new()
		prof_btn.flat = true
		prof_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		prof_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var prof_style = StyleBoxEmpty.new()
		prof_btn.add_theme_stylebox_override("normal", prof_style)
		prof_btn.add_theme_stylebox_override("hover", prof_style)
		prof_btn.add_theme_stylebox_override("pressed", prof_style)
		prof_btn.add_theme_stylebox_override("focus", prof_style)
		card_h.add_child(prof_btn)
		
		var prof_h = HBoxContainer.new()
		prof_h.add_theme_constant_override("separation", 6)
		prof_btn.add_child(prof_h)
		
		var avatar = ColorRect.new()
		avatar.custom_minimum_size = Vector2(32, 32)
		var av_style = StyleBoxFlat.new()
		av_style.bg_color = DeskTheme.COLOR_NOTE_DARK
		av_style.corner_radius_top_left = 16; av_style.corner_radius_top_right = 16
		av_style.corner_radius_bottom_left = 16; av_style.corner_radius_bottom_right = 16
		avatar.add_theme_stylebox_override("panel", av_style)
		prof_h.add_child(avatar)
		var av_lbl = DeskTheme.create_label(rival_name.left(1), 16, Color.WHITE, true)
		av_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		avatar.add_child(av_lbl)
		
		var name_lbl = DeskTheme.create_label(rival_name, 14, DeskTheme.COLOR_INK, true)
		prof_h.add_child(name_lbl)
		
		# 名前の幅に合わせてボタンサイズを調整
		prof_btn.custom_minimum_size = Vector2(32 + 6 + 90, 32)
		
		prof_btn.pressed.connect(func():
			if ctx.audio_manager: ctx.audio_manager.play_se("click")
			_show_profile_view(ctx, rival_name, feed_v.get_parent().get_parent())
		)
		
		# スペーサー
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_h.add_child(spacer)
		
		# 合計スコア
		var score_lbl = DeskTheme.create_label("%d点" % total_score, 14, DeskTheme.COLOR_INK, true)
		card_h.add_child(score_lbl)
		
		# デイリー教科1位バッジ（そのプレイヤーがトップの教科数を表示）
		var top_subj_count = 0
		var tops = ctx.backend_manager.get_subject_top_scores()
		for ts in range(5):
			if tops[ts]["name"] == rival_name:
				top_subj_count += 1
		if top_subj_count > 0:
			var badge = PanelContainer.new()
			var badge_style = StyleBoxFlat.new()
			badge_style.bg_color = DeskTheme.COLOR_ACCENT_GOLD
			badge_style.corner_radius_top_left = 6; badge_style.corner_radius_top_right = 6
			badge_style.corner_radius_bottom_left = 6; badge_style.corner_radius_bottom_right = 6
			badge_style.content_margin_left = 4; badge_style.content_margin_right = 4
			badge_style.content_margin_top = 1; badge_style.content_margin_bottom = 1
			badge.add_theme_stylebox_override("panel", badge_style)
			badge.add_child(DeskTheme.create_label("[*]x%d" % top_subj_count, 9, Color.WHITE, true))
			card_h.add_child(badge)
		
		# 不自然さ警告チェック
		var is_suspicious = false
		var already_voted = ctx.backend_manager.has_voted_rival(rival_name, -1)
		var past_days = ctx.backend_manager.get_all_player_daily_scores().get(rival_name, [])
		var prev_total_sum = 0
		var prev_days_count = 0
		for d_entry in past_days:
			var d_num = d_entry.get("day", 0)
			if d_num < Global.play_count + 1:
				var subjs = d_entry.get("subjects", {})
				var day_sum = 0
				for s in subjs:
					day_sum += int(subjs[s])
				prev_total_sum += day_sum
				prev_days_count += 1
		if prev_days_count > 0:
			var avg_total = float(prev_total_sum) / float(prev_days_count)
			if total_score >= avg_total + 20.0:
				is_suspicious = true
		
		if is_suspicious and not already_voted:
			var warn_lbl = DeskTheme.create_label("⚠️ ", 14, DeskTheme.COLOR_BLUFF_RED, true)
			warn_lbl.tooltip_text = "報告値が過去の平均よりも大幅に高いため、嘘の可能性があります！"
			card_h.add_child(warn_lbl)
		
		# いいねボタン
		var like_wrap = Control.new()
		like_wrap.custom_minimum_size = Vector2(64, 32)
		card_h.add_child(like_wrap)
		
		var is_btn_active = not already_voted and vote_count < 3
		var like_btn = DeskTheme.create_button("いいね", Vector2(64, 32), Color("3897f0") if is_btn_active else Color("a0c0e0"), Color("1070c0") if is_btn_active else Color("90b0d0"), false, 12)
		like_btn.disabled = not is_btn_active
		like_btn.set_meta("rival_name", rival_name)
		active_like_buttons.append(like_btn)
		like_wrap.add_child(like_btn)
		
		var stamp_container = Control.new()
		stamp_container.custom_minimum_size = Vector2(0, 0)
		like_wrap.add_child(stamp_container)
		
		var create_stamp = func():
			var stamp = PanelContainer.new()
			var stamp_style = StyleBoxFlat.new()
			stamp_style.bg_color = Color("3897f0")
			stamp_style.border_width_left = 2; stamp_style.border_width_right = 2
			stamp_style.border_width_top = 2; stamp_style.border_width_bottom = 3
			stamp_style.border_color = Color("1070c0")
			stamp_style.corner_radius_top_left = 4; stamp_style.corner_radius_top_right = 4
			stamp_style.corner_radius_bottom_left = 4; stamp_style.corner_radius_bottom_right = 4
			stamp_style.content_margin_left = 6; stamp_style.content_margin_right = 6
			stamp_style.content_margin_top = 2; stamp_style.content_margin_bottom = 2
			stamp.add_theme_stylebox_override("panel", stamp_style)
			var stamp_lbl = DeskTheme.create_label("👍 ダウト", 10, Color.WHITE, true)
			stamp.add_child(stamp_lbl)
			stamp.position = Vector2(0, -15)
			return stamp
			
		if already_voted:
			var stamp = create_stamp.call()
			stamp.rotation = randf_range(-0.1, 0.1)
			stamp_container.add_child(stamp)
			
		like_btn.pressed.connect(func():
			if ctx.backend_manager.has_voted_rival(rival_name, -1): return
			if ctx.backend_manager.get_daily_vote_count() >= 3: return
			
			ctx.backend_manager.vote_rival(rival_name, -1)
			like_btn.disabled = true
			var style_v = like_btn.get_theme_stylebox("normal").duplicate()
			style_v.bg_color = Color("a0c0e0")
			like_btn.add_theme_stylebox_override("normal", style_v)
			
			var btn_tw = like_btn.create_tween()
			btn_tw.tween_property(like_btn, "scale", Vector2(1.1, 1.1), 0.06).set_trans(Tween.TRANS_CUBIC)
			btn_tw.tween_property(like_btn, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_BACK)
			
			var stamp = create_stamp.call()
			stamp_container.add_child(stamp)
			stamp.pivot_offset = Vector2(20, 10)
			stamp.scale = Vector2(2.5, 2.5)
			stamp.modulate.a = 0.0
			stamp.rotation = randf_range(-0.15, 0.15)
			
			var stamp_tw = stamp.create_tween().set_parallel(true)
			stamp_tw.tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			stamp_tw.tween_property(stamp, "modulate:a", 1.0, 0.1)
			
			if ctx.audio_manager:
				ctx.audio_manager.play_se('place')
				
			# 投票バッジと他ボタンの無効化処理
			var new_count = ctx.backend_manager.get_daily_vote_count()
			votes_left_lbl.text = "本日のダウト投票権 (👍): %d / 3" % (3 - new_count)
			
			if new_count >= 3:
				for btn in active_like_buttons:
					if is_instance_valid(btn) and not btn.disabled:
						btn.disabled = true
						var style_d = btn.get_theme_stylebox("normal").duplicate()
						style_d.bg_color = Color("a0c0e0")
						btn.add_theme_stylebox_override("normal", style_d)
		)

static func _show_profile_view(ctx: RefCounted, rival_name: String, app_container: Control) -> void:
	var phone = app_container.get_parent()
	var prof_panel = PanelContainer.new()
	prof_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("f5f5f5")
	prof_panel.add_theme_stylebox_override("panel", bg_style)
	phone.add_child(prof_panel)
	
	# 右からスライドイン
	prof_panel.position.x = 400
	var in_tw = prof_panel.create_tween()
	in_tw.tween_property(prof_panel, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var prof_v = VBoxContainer.new()
	prof_v.add_theme_constant_override("separation", 0)
	prof_panel.add_child(prof_v)
	
	# Header (固定)
	var header_p = PanelContainer.new()
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color.WHITE
	h_style.content_margin_left = 12; h_style.content_margin_right = 12
	h_style.content_margin_top = 12; h_style.content_margin_bottom = 12
	h_style.shadow_color = Color(0,0,0, 0.05); h_style.shadow_size = 2
	header_p.add_theme_stylebox_override("panel", h_style)
	prof_v.add_child(header_p)
	
	var h_h = HBoxContainer.new()
	h_h.add_theme_constant_override("separation", 16)
	h_h.alignment = BoxContainer.ALIGNMENT_BEGIN
	header_p.add_child(h_h)
	
	var back_btn = DeskTheme.create_button("← 戻る", Vector2(80, 36), Color("e0e0e0"), Color("c0c0c0"), true, 14)
	back_btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		var out_tw = prof_panel.create_tween()
		out_tw.tween_property(prof_panel, "position:x", 400.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		out_tw.tween_callback(prof_panel.queue_free)
	)
	h_h.add_child(back_btn)
	
	var title = DeskTheme.create_label("プロフィール", 18, DeskTheme.COLOR_INK, true)
	h_h.add_child(title)
	
	# 縦スクロールコンテナを追加して画面はみ出しを防ぐ！
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	prof_v.add_child(scroll)
	
	var scroll_v = VBoxContainer.new()
	scroll_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_v.add_theme_constant_override("separation", 16)
	scroll.add_child(scroll_v)
	
	# Profile Info (SNS風)
	var info_m = MarginContainer.new()
	info_m.add_theme_constant_override("margin_left", 16)
	info_m.add_theme_constant_override("margin_top", 16)
	info_m.add_theme_constant_override("margin_right", 16)
	info_m.add_theme_constant_override("margin_bottom", 8)
	scroll_v.add_child(info_m)
	
	var info_v = VBoxContainer.new()
	info_v.add_theme_constant_override("separation", 12)
	info_m.add_child(info_v)
	
	# 上段: アバター ＋ 3列のスタッツ情報 (Instagram/Studyplusレイアウト)
	var upper_h = HBoxContainer.new()
	upper_h.add_theme_constant_override("separation", 16)
	upper_h.alignment = BoxContainer.ALIGNMENT_CENTER
	info_v.add_child(upper_h)
	
	# 丸型アバター
	var avatar = PanelContainer.new()
	avatar.custom_minimum_size = Vector2(74, 74)
	var av_style = StyleBoxFlat.new()
	av_style.bg_color = DeskTheme.COLOR_NOTE_DARK
	av_style.corner_radius_top_left = 37; av_style.corner_radius_top_right = 37
	av_style.corner_radius_bottom_left = 37; av_style.corner_radius_bottom_right = 37
	avatar.add_theme_stylebox_override("panel", av_style)
	upper_h.add_child(avatar)
	
	var av_lbl = DeskTheme.create_label(rival_name.left(1), 32, Color.WHITE, true)
	av_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(av_lbl)
	
	# スタッツ表示
	var stats_h = HBoxContainer.new()
	stats_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_h.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_h.add_theme_constant_override("separation", 12)
	upper_h.add_child(stats_h)
	
	# 各種スタッツデータ計算
	var hist_arr = ctx.backend_manager.get_rival_history(rival_name)
	var total_sc = 0
	for h in hist_arr: total_sc += h["score"]
	
	var tops = ctx.backend_manager.get_subject_top_scores()
	var first_places = 0
	for s in range(5):
		if tops[s]["name"] == rival_name and tops[s]["score"] > 0:
			first_places += 1
			
	var stats_configs = [
		{"val": str(hist_arr.size()) + "日", "lbl": "継続"},
		{"val": str(total_sc) + "点", "lbl": "累計スコア"},
		{"val": str(first_places) + "教科", "lbl": "現在1位"}
	]
	
	for cfg in stats_configs:
		var col = VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 2)
		stats_h.add_child(col)
		
		var v_lbl = DeskTheme.create_label(cfg["val"], 16, DeskTheme.COLOR_INK, true)
		v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(v_lbl)
		
		var l_lbl = DeskTheme.create_label(cfg["lbl"], 10, DeskTheme.COLOR_MUTED)
		l_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l_lbl)
		
	# 下段: 名前と自己紹介（バイオ）
	var bio_v = VBoxContainer.new()
	bio_v.add_theme_constant_override("separation", 4)
	info_v.add_child(bio_v)
	
	var name_lbl = DeskTheme.create_label(rival_name, 18, DeskTheme.COLOR_INK, true)
	bio_v.add_child(name_lbl)
	
	# 自己紹介テキストの決定
	var bio_text = ""
	if rival_name == "慎重な優等生":
		bio_text = "毎日コツコツが一番の近道。確実に進捗を出して計画的に合格を目指します。寝落ち（バースト）は絶対に避ける主義です。"
	elif rival_name == "ギャンブラー":
		bio_text = "人生すべてチキンレース！一攫千金を狙って爆速で勉強中！寝落ち（バースト）は友達、怖くないぜ！"
	elif rival_name == "ブラフの達人":
		bio_text = "報告された数字だけが全てじゃない。心理戦を制する者が試験を制する。私の本気をいつ見抜けるかな？"
	else:
		bio_text = "マイペースに勉強中。コツコツ頑張ります！"
		
	var bio_p = PanelContainer.new()
	var bp_style = StyleBoxFlat.new()
	bp_style.bg_color = Color("fafafa")
	bp_style.content_margin_left = 10; bp_style.content_margin_right = 10
	bp_style.content_margin_top = 8; bp_style.content_margin_bottom = 8
	bp_style.border_width_left = 3
	bp_style.border_color = Color("1c7ed6") # 左側にSNS風アクセント線
	bp_style.corner_radius_top_right = 6; bp_style.corner_radius_bottom_right = 6
	bio_p.add_theme_stylebox_override("panel", bp_style)
	bio_v.add_child(bio_p)
	
	var bio_lbl = DeskTheme.create_label(bio_text, 11, DeskTheme.COLOR_INK)
	bio_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bio_p.add_child(bio_lbl)
	
	# 🧠 AI心理分析カード（嘘の傾向）
	var bluff_card = PanelContainer.new()
	var bc_style = StyleBoxFlat.new()
	bc_style.bg_color = Color.WHITE
	bc_style.corner_radius_top_left = 12; bc_style.corner_radius_top_right = 12
	bc_style.corner_radius_bottom_left = 12; bc_style.corner_radius_bottom_right = 12
	bc_style.content_margin_left = 14; bc_style.content_margin_right = 14
	bc_style.content_margin_top = 12; bc_style.content_margin_bottom = 12
	bluff_card.add_theme_stylebox_override("panel", bc_style)
	
	var bc_m = MarginContainer.new()
	bc_m.add_theme_constant_override("margin_left", 16)
	bc_m.add_theme_constant_override("margin_right", 16)
	bc_m.add_theme_constant_override("margin_top", 4)
	bc_m.add_theme_constant_override("margin_bottom", 4)
	bc_m.add_child(bluff_card)
	scroll_v.add_child(bc_m)
	
	var bc_v = VBoxContainer.new()
	bc_v.add_theme_constant_override("separation", 8)
	bluff_card.add_child(bc_v)
	
	bc_v.add_child(DeskTheme.create_label("🧠 チキスタAI行動分析", 13, DeskTheme.COLOR_MUTED, true))
	
	var bluff_title = ""
	var bluff_rate = 0.0
	var bluff_color = Color.GREEN
	var bluff_desc = ""
	
	if rival_name == "慎重な優等生":
		bluff_title = "極めて誠実・堅実"
		bluff_rate = 0.05
		bluff_color = DeskTheme.COLOR_SAFE
		bluff_desc = "ほとんど嘘の報告を行いません。報告値は信頼できますが、たまに保険で小さく盛る程度です。"
	elif rival_name == "ギャンブラー":
		bluff_title = "ギャンブル報告（中〜高ブラフ）"
		bluff_rate = 0.55
		bluff_color = DeskTheme.COLOR_ACCENT_GOLD
		bluff_desc = "バーストしていない日は大きく盛る傾向があります。本日の気分で報告点数が乱高下します。"
	elif rival_name == "ブラフの達人":
		bluff_title = "変幻自在・危険度高"
		bluff_rate = 0.85
		bluff_color = DeskTheme.COLOR_BLUFF_RED
		bluff_desc = "巧妙に嘘を織り交ぜ、こちらの出方を窺っています。彼らの報告を鵜呑みにするのは極めて危険です。"
	else:
		bluff_title = "自己分析結果"
		bluff_rate = 0.3
		bluff_color = Color("1c7ed6")
		bluff_desc = "あなた自身のこれまでの行動履歴に基づき、システムが誠実な学習活動を推奨しています。"
		
	var bh = HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	bc_v.add_child(bh)
	
	bh.add_child(DeskTheme.create_label("ブラフ傾向:", 11, DeskTheme.COLOR_INK))
	bh.add_child(DeskTheme.create_label(bluff_title, 12, bluff_color, true))
	
	var indicator_bg = PanelContainer.new()
	indicator_bg.custom_minimum_size = Vector2(0, 16)
	indicator_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ind_bg_style = StyleBoxFlat.new()
	ind_bg_style.bg_color = Color("f0f0f0")
	ind_bg_style.corner_radius_top_left = 8; ind_bg_style.corner_radius_top_right = 8
	ind_bg_style.corner_radius_bottom_left = 8; ind_bg_style.corner_radius_bottom_right = 8
	indicator_bg.add_theme_stylebox_override("panel", ind_bg_style)
	bc_v.add_child(indicator_bg)
	
	var indicator_val = PanelContainer.new()
	indicator_val.custom_minimum_size = Vector2(0, 16)
	indicator_val.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var ind_val_style = StyleBoxFlat.new()
	ind_val_style.bg_color = bluff_color
	ind_val_style.corner_radius_top_left = 8; ind_val_style.corner_radius_bottom_left = 8
	if bluff_rate >= 0.95:
		ind_val_style.corner_radius_top_right = 8; ind_val_style.corner_radius_bottom_right = 8
	indicator_val.add_theme_stylebox_override("panel", ind_val_style)
	indicator_bg.add_child(indicator_val)
	indicator_val.custom_minimum_size.x = max(16, 260.0 * bluff_rate)
	
	var desc_lbl = DeskTheme.create_label(bluff_desc, 10, DeskTheme.COLOR_MUTED)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bc_v.add_child(desc_lbl)
	
	# History Chart
	var chart_p = PanelContainer.new()
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color.WHITE
	c_style.corner_radius_top_left = 12; c_style.corner_radius_top_right = 12
	c_style.corner_radius_bottom_left = 12; c_style.corner_radius_bottom_right = 12
	c_style.content_margin_left = 16; c_style.content_margin_right = 16
	c_style.content_margin_top = 16; c_style.content_margin_bottom = 16
	chart_p.add_theme_stylebox_override("panel", c_style)
	
	var chart_m = MarginContainer.new()
	chart_m.add_theme_constant_override("margin_left", 16)
	chart_m.add_theme_constant_override("margin_right", 16)
	chart_m.add_child(chart_p)
	scroll_v.add_child(chart_m)
	
	var chart_v = VBoxContainer.new()
	chart_v.add_theme_constant_override("separation", 16)
	chart_p.add_child(chart_v)
	
	chart_v.add_child(DeskTheme.create_label("📈 過去の学習スコア推移", 15, DeskTheme.COLOR_INK, true))
	
	var bars_h = HBoxContainer.new()
	bars_h.alignment = BoxContainer.ALIGNMENT_CENTER
	bars_h.add_theme_constant_override("separation", 16)
	chart_v.add_child(bars_h)
	
	for h_data in hist_arr:
		var day_v = VBoxContainer.new()
		day_v.alignment = BoxContainer.ALIGNMENT_END
		day_v.add_theme_constant_override("separation", 6)
		bars_h.add_child(day_v)
		
		var score = h_data["score"]
		var h_val = clamp(score, 0, 100) * 1.5
		
		var s_lbl = DeskTheme.create_label(str(score), 12, DeskTheme.COLOR_MUTED)
		s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_v.add_child(s_lbl)
		
		var bar_wrap = Control.new()
		bar_wrap.custom_minimum_size = Vector2(24, 150)
		day_v.add_child(bar_wrap)
		
		var bg_bar = ColorRect.new()
		bg_bar.color = Color("f0f0f0")
		bg_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bar_wrap.add_child(bg_bar)
		
		var val_bar = ColorRect.new()
		val_bar.color = DeskTheme.COLOR_SAFE if score > 0 else DeskTheme.COLOR_BLUFF_RED
		val_bar.custom_minimum_size = Vector2(24, h_val)
		val_bar.anchor_top = 1.0; val_bar.anchor_bottom = 1.0
		val_bar.offset_top = -h_val
		bar_wrap.add_child(val_bar)
		
		var d_lbl = DeskTheme.create_label("D"+str(h_data["day"]), 12, DeskTheme.COLOR_INK)
		d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_v.add_child(d_lbl)
	
	# 教科別累計スコアの内訳カード
	var subj_card = PanelContainer.new()
	var sc_style = StyleBoxFlat.new()
	sc_style.bg_color = Color.WHITE
	sc_style.corner_radius_top_left = 12; sc_style.corner_radius_top_right = 12
	sc_style.corner_radius_bottom_left = 12; sc_style.corner_radius_bottom_right = 12
	sc_style.content_margin_left = 12; sc_style.content_margin_right = 12
	sc_style.content_margin_top = 12; sc_style.content_margin_bottom = 12
	subj_card.add_theme_stylebox_override("panel", sc_style)
	
	var sc_m = MarginContainer.new()
	sc_m.add_theme_constant_override("margin_left", 16)
	sc_m.add_theme_constant_override("margin_right", 16)
	sc_m.add_theme_constant_override("margin_top", 0)
	sc_m.add_theme_constant_override("margin_bottom", 24) # 最下部にマージンを持たせてスクロールに余裕を作る
	sc_m.add_child(subj_card)
	scroll_v.add_child(sc_m)
	
	var sc_v = VBoxContainer.new()
	sc_v.add_theme_constant_override("separation", 8)
	subj_card.add_child(sc_v)
	
	sc_v.add_child(DeskTheme.create_label("教科別スコア内訳", 14, DeskTheme.COLOR_INK, true))
	
	var all_data = ctx.backend_manager.get_all_player_daily_scores()
	var player_data = all_data.get(rival_name, [])
	
	# 美しいレーダーチャート
	var radar_height = 140.0
	var radar_control = Control.new()
	radar_control.custom_minimum_size = Vector2(0, radar_height)
	radar_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc_v.add_child(radar_control)
	
	var subj_scores = []
	for s in range(5):
		var subj_total = 0
		for d_entry in player_data:
			var subjs = d_entry.get("subjects", {})
			subj_total += int(subjs.get(s, subjs.get(str(s), 0)))
		subj_scores.append(subj_total)
	
	radar_control.draw.connect(func():
		var center = Vector2(radar_control.size.x / 2.0, radar_height / 2.0)
		var max_radius = 50.0
		var num_points = 5
		
		# 1. 五角形グリッド（同心円）
		var grid_steps = 4
		for step in range(1, grid_steps + 1):
			var r = max_radius * (float(step) / float(grid_steps))
			var grid_points = PackedVector2Array()
			for i in range(num_points + 1):
				var angle = i * 2.0 * PI / float(num_points) - PI / 2.0
				grid_points.append(center + Vector2(cos(angle), sin(angle)) * r)
			radar_control.draw_polyline(grid_points, Color("e0e0e0"), 1.0)
			
		# 2. 中心から頂点への放射線
		for i in range(num_points):
			var angle = i * 2.0 * PI / float(num_points) - PI / 2.0
			var outer_point = center + Vector2(cos(angle), sin(angle)) * max_radius
			radar_control.draw_line(center, outer_point, Color("e0e0e0"), 1.0)
			
		# 3. プレイヤーデータのプロットポリゴン
		var plot_points = PackedVector2Array()
		for i in range(num_points):
			var score = subj_scores[i]
			var ratio = clamp(float(score) / 140.0, 0.08, 1.0)
			var r = max_radius * ratio
			var angle = i * 2.0 * PI / float(num_points) - PI / 2.0
			plot_points.append(center + Vector2(cos(angle), sin(angle)) * r)
		
		var fill_color = Color("1c7ed6", 0.35) if rival_name != Global.player_name else Color("2b8a3e", 0.35)
		var line_color = Color("1c7ed6", 0.8) if rival_name != Global.player_name else Color("2b8a3e", 0.8)
		
		var closed_points = PackedVector2Array(plot_points)
		closed_points.append(plot_points[0])
		radar_control.draw_polygon(plot_points, PackedColorArray([fill_color]))
		radar_control.draw_polyline(closed_points, line_color, 2.0)
		
		for pt in plot_points:
			radar_control.draw_circle(pt, 3.5, line_color)
	)
	
	for s in range(5):
		var subj_total = 0
		for d_entry in player_data:
			var subjs = d_entry.get("subjects", {})
			subj_total += int(subjs.get(s, subjs.get(str(s), 0)))
		
		var s_h = HBoxContainer.new()
		s_h.add_theme_constant_override("separation", 6)
		sc_v.add_child(s_h)
		
		s_h.add_child(DeskTheme.create_label(DeskTheme.subject_name(s), 11, DeskTheme.subject_color(s), true))
		s_h.add_child(DeskTheme.create_label("%d点" % subj_total, 11, DeskTheme.COLOR_INK))
		
		# 1位バッジ
		if tops[s]["name"] == rival_name and tops[s]["score"] > 0:
			var crown_lbl = DeskTheme.create_label("[*]1位", 9, DeskTheme.COLOR_ACCENT_GOLD, true)
			s_h.add_child(crown_lbl)
		
		var bar = DeskTheme.create_gauge_bar(subj_total, 140.0, DeskTheme.subject_color(s), Vector2(100, 6))
		s_h.add_child(bar)

static func _build_analysis_tab(ctx: RefCounted, feed_v: VBoxContainer) -> void:
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 8)
	margin_c.add_theme_constant_override("margin_top", 8)
	margin_c.add_theme_constant_override("margin_right", 8)
	margin_c.add_theme_constant_override("margin_bottom", 8)
	feed_v.add_child(margin_c)
	
	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 10)
	margin_c.add_child(cv)
	
	cv.add_child(DeskTheme.create_label("[ 全プレイヤー学習履歴 ]", 15, DeskTheme.COLOR_INK, true))
	
	# 教科選択タブ
	var tab_state = {"active": 0}
	var tab_h = HBoxContainer.new()
	tab_h.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_h.add_theme_constant_override("separation", 4)
	cv.add_child(tab_h)
	
	var content_scroll = ScrollContainer.new()
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.custom_minimum_size = Vector2(0, 400)
	cv.add_child(content_scroll)
	
	var content_v = VBoxContainer.new()
	content_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_v.add_theme_constant_override("separation", 8)
	content_scroll.add_child(content_v)
	
	var all_data = ctx.backend_manager.get_all_player_daily_scores()
	
	var build_subject_view = func(subj_idx: int):
		for ch in content_v.get_children():
			ch.queue_free()
		
		# 各プレイヤーごとのカード
		for player_name in all_data:
			var days = all_data[player_name]
			
			var card = PanelContainer.new()
			var card_style = StyleBoxFlat.new()
			card_style.bg_color = Color("ffffff")
			card_style.corner_radius_top_left = 10; card_style.corner_radius_top_right = 10
			card_style.corner_radius_bottom_left = 10; card_style.corner_radius_bottom_right = 10
			card_style.content_margin_left = 10; card_style.content_margin_right = 10
			card_style.content_margin_top = 8; card_style.content_margin_bottom = 8
			card_style.shadow_color = Color(0, 0, 0, 0.05)
			card_style.shadow_size = 3
			card.add_theme_stylebox_override("panel", card_style)
			content_v.add_child(card)
			
			var card_v = VBoxContainer.new()
			card_v.add_theme_constant_override("separation", 6)
			card.add_child(card_v)
			
			# プレイヤー名ヘッダー
			var is_self = (player_name == Global.player_name)
			var name_color = DeskTheme.COLOR_SAFE if is_self else DeskTheme.COLOR_INK
			var name_suffix = " (あなた)" if is_self else ""
			card_v.add_child(DeskTheme.create_label(player_name + name_suffix, 14, name_color, true))
			
			# 累計スコア
			var cumulative = 0
			for day_entry in days:
				var subjs = day_entry.get("subjects", {})
				cumulative += int(subjs.get(subj_idx, subjs.get(str(subj_idx), 0)))
			
			var cum_lbl = DeskTheme.create_label("累計: %d点" % cumulative, 12, DeskTheme.subject_color(subj_idx), true)
			card_v.add_child(cum_lbl)
			
			# 日別スコア行
			var days_h = HBoxContainer.new()
			days_h.add_theme_constant_override("separation", 4)
			days_h.alignment = BoxContainer.ALIGNMENT_CENTER
			card_v.add_child(days_h)
			
			for day_entry in days:
				var d = day_entry.get("day", 0)
				var subjs = day_entry.get("subjects", {})
				var score_val = int(subjs.get(subj_idx, subjs.get(str(subj_idx), 0)))
				
				var day_cell = VBoxContainer.new()
				day_cell.add_theme_constant_override("separation", 1)
				day_cell.alignment = BoxContainer.ALIGNMENT_CENTER
				days_h.add_child(day_cell)
				
				# デイリー1位チェック
				var is_daily_top = false
				var best_score_that_day = 0
				for pn in all_data:
					for de in all_data[pn]:
						if de.get("day", 0) == d:
							var ps = de.get("subjects", {})
							var pv = int(ps.get(subj_idx, ps.get(str(subj_idx), 0)))
							if pv > best_score_that_day:
								best_score_that_day = pv
				if score_val > 0 and score_val >= best_score_that_day:
					is_daily_top = true
				
				# 王冠マーク (デイリー1位)
				if is_daily_top and score_val > 0:
					var crown = DeskTheme.create_label("[*]", 9, DeskTheme.COLOR_ACCENT_GOLD, true)
					crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					day_cell.add_child(crown)
				else:
					var spacer = Control.new()
					spacer.custom_minimum_size = Vector2(0, 12)
					day_cell.add_child(spacer)
				
				# スコア値
				var score_color = DeskTheme.subject_color(subj_idx) if score_val > 0 else DeskTheme.COLOR_MUTED
				var s_lbl = DeskTheme.create_label(str(score_val), 11, score_color, score_val > 0)
				s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				s_lbl.custom_minimum_size = Vector2(32, 0)
				day_cell.add_child(s_lbl)
				
				# Day番号
				var d_lbl = DeskTheme.create_label("D%d" % d, 9, DeskTheme.COLOR_MUTED)
				d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				day_cell.add_child(d_lbl)
			
			# 累計バー
			var bar = DeskTheme.create_gauge_bar(cumulative, 140.0, DeskTheme.subject_color(subj_idx), Vector2(260, 8))
			card_v.add_child(bar)
	
	# 教科タブボタンを作成
	for s in range(5):
		var tab_btn = Button.new()
		tab_btn.text = DeskTheme.subject_name(s).left(1)
		tab_btn.custom_minimum_size = Vector2(52, 36)
		tab_btn.add_theme_font_override("font", DeskTheme.DEFAULT_FONT)
		tab_btn.add_theme_font_size_override("font_size", 13)
		
		var tb_style = StyleBoxFlat.new()
		tb_style.bg_color = DeskTheme.subject_color(s).lightened(0.6) if s != 0 else DeskTheme.subject_color(s).lightened(0.3)
		tb_style.corner_radius_top_left = 8; tb_style.corner_radius_top_right = 8
		tb_style.corner_radius_bottom_left = 8; tb_style.corner_radius_bottom_right = 8
		tab_btn.add_theme_stylebox_override("normal", tb_style)
		
		var tb_hover = tb_style.duplicate()
		tb_hover.bg_color = DeskTheme.subject_color(s).lightened(0.3)
		tab_btn.add_theme_stylebox_override("hover", tb_hover)
		
		tab_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		tab_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		tab_btn.pressed.connect(func():
			tab_state["active"] = s
			build_subject_view.call(s)
			# タブのアクティブ状態を視覚更新
			for i in range(tab_h.get_child_count()):
				var btn = tab_h.get_child(i)
				var st = btn.get_theme_stylebox("normal").duplicate()
				st.bg_color = DeskTheme.subject_color(i).lightened(0.3 if i == s else 0.6)
				btn.add_theme_stylebox_override("normal", st)
		)
		tab_h.add_child(tab_btn)
	
	# 初期表示: 教科0（国語）
	build_subject_view.call(0)

static func _build_goals_tab(_ctx: RefCounted, feed_v: VBoxContainer) -> void:
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 8)
	margin_c.add_theme_constant_override("margin_top", 8)
	margin_c.add_theme_constant_override("margin_right", 8)
	margin_c.add_theme_constant_override("margin_bottom", 8)
	feed_v.add_child(margin_c)
	
	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 12)
	margin_c.add_child(cv)
	
	cv.add_child(DeskTheme.create_label("[ 目標と獲得バッジ ]", 15, DeskTheme.COLOR_INK, true))
	
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
	
	iv.add_child(DeskTheme.create_label("[ テスト勉強中学 学生証 ]", 12, Color.WHITE, true))
	
	var det = HBoxContainer.new()
	det.add_theme_constant_override("separation", 12)
	iv.add_child(det)
	
	var photo = ColorRect.new()
	photo.custom_minimum_size = Vector2(40, 50)
	photo.color = Color.WHITE
	det.add_child(photo)
	
	var photo_lbl = DeskTheme.create_label("[写真]", 12, Color.BLACK, true)
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
	
	cv.add_child(DeskTheme.create_label("[ 獲得バッジ ]", 12, DeskTheme.COLOR_MUTED))
	
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
