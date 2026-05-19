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
		b_pressed.corner_radius_top_left = 8; b_pressed.corner_radius_top_right = 8
		b_pressed.corner_radius_bottom_left = 8; b_pressed.corner_radius_bottom_right = 8
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
	var tips_msg = DeskTheme.create_label("アイコンをタップで詳細プロフ！ライバルに【いいね】を送ってプレッシャーを与えましょう！嘘の報告を暴けば大ダメージ！", 12, DeskTheme.COLOR_INK)
	tips_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_v.add_child(tips_msg)
	
	if Global.play_count == 0:
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
			"4. 翌朝、報告に対するいいねや見破りが発生！\n\n" + \
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
		
		# いいねボタン
		var like_wrap = Control.new()
		like_wrap.custom_minimum_size = Vector2(64, 32)
		card_h.add_child(like_wrap)
		
		var already_voted = ctx.backend_manager.has_voted_rival(rival_name, -1)
		var like_btn = DeskTheme.create_button("いいね", Vector2(64, 32), Color("3897f0") if not already_voted else Color("a0c0e0"), Color("1070c0") if not already_voted else Color("90b0d0"), false, 12)
		like_btn.disabled = already_voted
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
			var stamp_lbl = DeskTheme.create_label("👍 いいね", 10, Color.WHITE, true)
			stamp.add_child(stamp_lbl)
			stamp.position = Vector2(0, -15)
			return stamp
			
		if already_voted:
			var stamp = create_stamp.call()
			stamp.rotation = randf_range(-0.1, 0.1)
			stamp_container.add_child(stamp)
			
		like_btn.pressed.connect(func():
			if ctx.backend_manager.has_voted_rival(rival_name, -1): return
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
	
	# Header
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
	
	# Profile Info
	var info_m = MarginContainer.new()
	info_m.add_theme_constant_override("margin_left", 20)
	info_m.add_theme_constant_override("margin_top", 24)
	info_m.add_theme_constant_override("margin_right", 20)
	info_m.add_theme_constant_override("margin_bottom", 24)
	prof_v.add_child(info_m)
	
	var info_v = VBoxContainer.new()
	info_v.alignment = BoxContainer.ALIGNMENT_CENTER
	info_v.add_theme_constant_override("separation", 12)
	info_m.add_child(info_v)
	
	var avatar = ColorRect.new()
	avatar.custom_minimum_size = Vector2(80, 80)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var av_style = StyleBoxFlat.new()
	av_style.bg_color = DeskTheme.COLOR_NOTE_DARK
	av_style.corner_radius_top_left = 40; av_style.corner_radius_top_right = 40
	av_style.corner_radius_bottom_left = 40; av_style.corner_radius_bottom_right = 40
	avatar.add_theme_stylebox_override("panel", av_style)
	info_v.add_child(avatar)
	
	var av_lbl = DeskTheme.create_label(rival_name.left(1), 36, Color.WHITE, true)
	av_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(av_lbl)
	
	var name_lbl = DeskTheme.create_label(rival_name, 22, DeskTheme.COLOR_INK, true)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_v.add_child(name_lbl)
	
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
	prof_v.add_child(chart_m)
	
	var chart_v = VBoxContainer.new()
	chart_v.add_theme_constant_override("separation", 16)
	chart_p.add_child(chart_v)
	
	chart_v.add_child(DeskTheme.create_label("📈 過去の学習スコア推移", 16, DeskTheme.COLOR_INK, true))
	
	var hist_arr = ctx.backend_manager.get_rival_history(rival_name)
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

static func _build_analysis_tab(ctx: RefCounted, feed_v: VBoxContainer) -> void:
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 8)
	margin_c.add_theme_constant_override("margin_top", 8)
	margin_c.add_theme_constant_override("margin_right", 8)
	margin_c.add_theme_constant_override("margin_bottom", 8)
	feed_v.add_child(margin_c)
	
	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 12)
	margin_c.add_child(cv)
	
	cv.add_child(DeskTheme.create_label("[ 週次学習成果分析 ]", 15, DeskTheme.COLOR_INK, true))
	
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
	
	list_v.add_child(DeskTheme.create_label("[ 教科別進捗 (目標20点) ]", 12, DeskTheme.COLOR_MUTED))
	
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
