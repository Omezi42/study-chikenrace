class_name SmartphoneBuilder
extends RefCounted
## スマートフォンのUIモックアップおよび「チキスタ」アプリ画面を生成・管理するファクトリクラス。

const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")
const GameBalanceScript = preload("res://scripts/core/GameBalance.gd")

static func create_mockup(ctx: RefCounted, is_centered: bool = true) -> VBoxContainer:
	var phone = PanelContainer.new()
	phone.custom_minimum_size = Vector2(400, 840)
	phone.size = Vector2(400, 840)
	
	# アンカー競合を回避し、常に安定したピクセル座標で配置・Tweenする設計 (左に寄せて配置)
	phone.anchor_left = 0.0; phone.anchor_top = 0.0; phone.anchor_right = 0.0; phone.anchor_bottom = 0.0
	if is_centered:
		phone.position = Vector2(700, 120)
		phone.rotation_degrees = 0.0
		phone.scale = Vector2(1.4, 1.4)
	else:
		phone.position = Vector2(32, 300)
		phone.rotation_degrees = -1.2
		phone.scale = Vector2(0.8, 0.8)
		
	phone.pivot_offset = Vector2(200, 420)
	if is_centered:
		phone.z_index = 11
	
	var dim_overlay = ColorRect.new()
	dim_overlay.color = Color(0, 0, 0, 0.65)
	dim_overlay.custom_minimum_size = Vector2(1920, 1080)
	dim_overlay.visible = is_centered
	dim_overlay.modulate.a = 1.0 if is_centered else 0.0
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if is_centered else Control.MOUSE_FILTER_IGNORE
	if is_centered:
		dim_overlay.z_index = 10
	
	var pickup_overlay = Button.new()
	pickup_overlay.name = "PickupOverlay"
	pickup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pickup_overlay.flat = true
	pickup_overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if is_centered: pickup_overlay.hide()
	
	phone.set_meta("is_picked_up", is_centered)
	var default_orig_pos = Vector2(32, 300) if not is_centered else Vector2(700, 120)
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
		
		# z_index を 0 にリセット
		dim_overlay.z_index = 0
		phone.z_index = 0
		
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
		
		# 最前面にするため z_index を設定
		dim_overlay.z_index = 10
		phone.z_index = 11
		
		# レイヤーを最前面に移動してノート等に隠れないようにする
		if dim_overlay.get_parent():
			dim_overlay.get_parent().move_child(dim_overlay, -1)
		if phone.get_parent():
			phone.get_parent().move_child(phone, -1)
		
		dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		dim_overlay.modulate.a = 0.0
		dim_overlay.show()
		var tw_dim = dim_overlay.create_tween()
		tw_dim.tween_property(dim_overlay, "modulate:a", 1.0, 0.2)
		
		var tw = phone.create_tween().set_parallel(true)
		var target_scale = 1.4
		var target_pos = Vector2(700, 120)
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
	
	# スマホ画面全体の液晶エリア (重ね合わせ可能にして丸角内でクリッピングするため Control にする)
	var screen_area = Control.new()
	screen_area.name = "ScreenArea"
	screen_area.clip_contents = true # 液晶領域の外側にはみ出さないようにクリッピング！
	screen_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	phone.add_child(screen_area)
	
	# スマホ画面コンテンツ
	var app_container = VBoxContainer.new()
	app_container.name = "AppContainer"
	app_container.add_theme_constant_override("separation", 0)
	app_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # 液晶エリアいっぱいに広げる
	DeskTheme.apply_font(app_container)
	screen_area.add_child(app_container)
	
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
	var tips_msg = DeskTheme.create_label("アイコンをタップで詳細プロフ！ライバルに【👍】を押して『いいね！』しましょう！怪しい報告をいいねで見破れば最終日にボーナス、冤罪はペナルティ！", 12, DeskTheme.COLOR_INK)
	tips_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_v.add_child(tips_msg)
	
	# 💡 1日3回投票権のUI表示
	var vote_count = ctx.backend_manager.get_daily_vote_count()
	var vote_info_panel = PanelContainer.new()
	var vi_style = StyleBoxFlat.new()
	vi_style.bg_color = Color("fff3bf")
	vi_style.border_width_left = 3
	vi_style.border_color = Color("f59f00")
	vi_style.corner_radius_top_left = 4; vi_style.corner_radius_top_right = 8
	vi_style.corner_radius_bottom_left = 4; vi_style.corner_radius_bottom_right = 8
	vi_style.content_margin_left = 12; vi_style.content_margin_right = 12
	vi_style.content_margin_top = 8; vi_style.content_margin_bottom = 8
	vote_info_panel.add_theme_stylebox_override("panel", vi_style)
	cards_v.add_child(vote_info_panel)
	
	var vote_info_hbox = HBoxContainer.new()
	vote_info_panel.add_child(vote_info_hbox)
	
	var votes_left_lbl = DeskTheme.create_label("本日のいいね投票権 (👍): %d / 3" % (3 - vote_count), 14, Color("d9480f"), true)
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
			"4. タイムラインで、相手の嘘と思われる報告に【👍いいね！】を押す！(1日最大3回まで)\n\n" + \
			"※明日（2日目）の学習記録がここにリアルタイムで表示されるようになります！本日はまず自分の学習計画を立てて勉強を始めましょう！"
		
		var body_lbl = DeskTheme.create_label(body, 12, DeskTheme.COLOR_INK)
		body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		guide_v.add_child(body_lbl)
		return
		
	var timelines = []
	if is_instance_valid(ctx.game_session) and ctx.game_session.ai_manager:
		var ai_res = ctx.game_session.ai_manager.get_daily_results()
		for r_name in ai_res:
			var res = ai_res[r_name]
			timelines.append({
				"name": r_name,
				"total_score": res["reported_score"],
				"actual_score": res["actual_score"],
				"is_bluffing": res["is_lying"]
			})
	
	timelines.sort_custom(func(a, b): return a["total_score"] > b["total_score"])

	if timelines.size() == 0:
		cards_v.add_child(DeskTheme.create_label("タイムラインが空です。", 14, DeskTheme.COLOR_MUTED, true))
	
	var rank_idx = 1
	for entry in timelines:
		var rival_name = entry["name"]
		var total_score = entry["total_score"]
		var rival_actual = entry.get("actual_score", total_score)
		var is_bluffing = entry["is_bluffing"]
		
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color("ffffff")
		card_style.corner_radius_top_left = 10; card_style.corner_radius_top_right = 10
		card_style.corner_radius_bottom_left = 10; card_style.corner_radius_bottom_right = 10
		card_style.content_margin_left = 12; card_style.content_margin_right = 12
		card_style.content_margin_top = 10; card_style.content_margin_bottom = 10
		card_style.shadow_color = Color(0,0,0, 0.08)
		card_style.shadow_size = 4
		card.add_theme_stylebox_override("panel", card_style)
		cards_v.add_child(card)
		
		var card_h = HBoxContainer.new()
		card_h.add_theme_constant_override("separation", 10)
		card_h.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(card_h)
		
		# 順位
		var rank_color = DeskTheme.COLOR_INK
		if rank_idx == 1: rank_color = DeskTheme.COLOR_ACCENT_GOLD
		elif rank_idx == 2: rank_color = Color("a0aab2")
		elif rank_idx == 3: rank_color = Color("cd7f32")
		var rank_str = "1位" if rank_idx == 1 else str(rank_idx)
		var rank_lbl = DeskTheme.create_label(rank_str, 18, rank_color, true)
		rank_lbl.custom_minimum_size = Vector2(34, 0)
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
		

		
		# 不自然さ警告チェック
		var is_suspicious = false
		var already_voted = ctx.backend_manager.has_voted_rival(rival_name, -1)
		var prev_total_sum = 0
		var prev_days_count = 0
		
		if is_instance_valid(ctx.game_session) and ctx.game_session.ai_manager:
			var state = ctx.game_session.ai_manager.get_rival_state(rival_name)
			if state and state.has("score_history"):
				var hist = state["score_history"]
				for i in range(hist.size() - 1):
					prev_total_sum += hist[i]["reported_score"]
					prev_days_count += 1
					
		if prev_days_count > 0:
			var avg_total = float(prev_total_sum) / float(prev_days_count)
			if total_score >= avg_total + 20.0:
				is_suspicious = true
		
		if is_suspicious and not already_voted:
			var warn_lbl = DeskTheme.create_label("⚠️ ", 14, DeskTheme.COLOR_BLUFF_RED, true)
			warn_lbl.tooltip_text = "報告値が過去の平均よりも大幅に高いため、嘘の可能性があります！"
			card_h.add_child(warn_lbl)
		
		# いいね（ダウト）ボタン
		var like_wrap = Control.new()
		like_wrap.custom_minimum_size = Vector2(80, 34)
		card_h.add_child(like_wrap)
		
		var is_btn_active = not already_voted and vote_count < 3
		var btn_text = "👍済" if already_voted else "👍いいね！"
		var like_btn = DeskTheme.create_button(btn_text, Vector2(80, 34), Color("3897f0") if is_btn_active else Color("dbe4eb"), Color("1070c0") if is_btn_active else Color("a0b0c0"), false, 13)
		like_btn.disabled = not is_btn_active
		if not is_btn_active:
			if already_voted:
				like_btn.add_theme_color_override("font_disabled_color", Color("868e96"))
			else:
				like_btn.add_theme_color_override("font_disabled_color", Color("adb5bd"))
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
			var stamp_lbl = DeskTheme.create_label("👍 いいね！", 10, Color.WHITE, true)
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
			ToastOverlayScript.show_toast(
				ctx.ui_root,
				"%s にいいね！しました" % rival_name,
				DeskTheme.COLOR_SAFE
			)
			like_btn.disabled = true
			var style_v = like_btn.get_theme_stylebox("normal").duplicate()
			style_v.bg_color = Color("a0c0e0")
			like_btn.add_theme_stylebox_override("normal", style_v)
			
			# ===== Sprint 5: 強化されたダウト投票演出 (Sprint 1 Polish) =====
			# 1. ボタンのバウンスアニメーション（より大きく）
			var btn_tw = like_btn.create_tween()
			btn_tw.tween_property(like_btn, "scale", Vector2(1.35, 1.35), 0.06).set_trans(Tween.TRANS_CUBIC)
			btn_tw.tween_property(like_btn, "scale", Vector2(0.9, 0.9), 0.05).set_trans(Tween.TRANS_CUBIC)
			btn_tw.tween_property(like_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
			
			# 2. フラッシュオーバーレイ効果
			var flash = ColorRect.new()
			flash.color = Color(0.2, 0.6, 1.0, 0.4)
			flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(flash)
			var flash_tw = flash.create_tween()
			flash_tw.tween_property(flash, "color:a", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC)
			flash_tw.tween_callback(flash.queue_free)
			
			# 3. ドラマチックなスタンプ（巨大→叩きつけ）
			var stamp = create_stamp.call()
			stamp_container.add_child(stamp)
			stamp.pivot_offset = Vector2(20, 10)
			stamp.scale = Vector2(4.0, 4.0)
			stamp.modulate.a = 0.0
			stamp.rotation = randf_range(-0.2, 0.2)
			
			var stamp_tw = stamp.create_tween().set_parallel(true)
			stamp_tw.tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			stamp_tw.tween_property(stamp, "modulate:a", 1.0, 0.06)
			
			# 4. カード全体の揺れ（インパクト感）
			var card_orig_pos = card.position
			var shake_tw = card.create_tween().set_loops(3)
			shake_tw.tween_callback(func(): card.position = card_orig_pos + Vector2(randf_range(-4, 4), randf_range(-3, 3)))
			shake_tw.tween_interval(0.04)
			shake_tw.finished.connect(func(): card.position = card_orig_pos)
			
			# 5. スマホ全体の物理バイブ振動 (Sprint 1)
			var phone = ctx.bag_ui_elements.get("report_page") as Control
			if is_instance_valid(phone):
				var phone_orig_pos = phone.position
				var phone_shake = phone.create_tween().set_loops(4)
				phone_shake.tween_callback(func(): phone.position = phone_orig_pos + Vector2(randf_range(-6, 6), randf_range(-5, 5)))
				phone_shake.tween_interval(0.04)
				phone_shake.finished.connect(func(): phone.position = phone_orig_pos)
			
			# 5. 紙吹雪パーティクル
			var particles = CPUParticles2D.new()
			particles.position = like_btn.global_position + Vector2(40, 17)
			particles.emitting = true
			particles.one_shot = true
			particles.amount = 30
			particles.lifetime = 1.2
			particles.explosiveness = 0.9
			particles.direction = Vector2(0, -1)
			particles.spread = 60.0
			particles.gravity = Vector2(0, 200.0)
			particles.initial_velocity_min = 100.0
			particles.initial_velocity_max = 220.0
			particles.scale_amount_min = 3.0
			particles.scale_amount_max = 7.0
			var grad = Gradient.new()
			grad.set_offsets(PackedFloat32Array([0.0, 0.33, 0.66, 1.0]))
			grad.set_colors(PackedColorArray([Color("74c0fc"), Color("3897f0"), Color("ffd43b"), Color("ff6b6b")]))
			particles.color_ramp = grad
			particles.angular_velocity_min = -120.0
			particles.angular_velocity_max = 120.0
			ctx.screen_content.add_child(particles)
			var p_timer = ctx.screen_content.get_tree().create_timer(1.5)
			p_timer.timeout.connect(particles.queue_free)
			
			if ctx.audio_manager:
				ctx.audio_manager.play_se('place')
				
			# 投票バッジと他ボタンの無効化処理
			var new_count = ctx.backend_manager.get_daily_vote_count()
			votes_left_lbl.text = "本日のいいね投票権 (👍): %d / 3" % (3 - new_count)
			
			if new_count >= 3:
				for btn in active_like_buttons:
					if is_instance_valid(btn) and not btn.disabled:
						btn.disabled = true
						var style_d = btn.get_theme_stylebox("normal").duplicate()
						style_d.bg_color = Color("a0c0e0")
						btn.add_theme_stylebox_override("normal", style_d)
		)

static func _show_profile_view(ctx: RefCounted, rival_name: String, app_container: Control) -> void:
	var screen_area = app_container.get_parent()
	var prof_panel = PanelContainer.new()
	prof_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("f5f5f5")
	prof_panel.add_theme_stylebox_override("panel", bg_style)
	screen_area.add_child(prof_panel)
	
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
	var hist_arr = []
	if is_instance_valid(ctx.game_session) and ctx.game_session.ai_manager:
		var state = ctx.game_session.ai_manager.get_rival_state(rival_name)
		if state and state.has("score_history"):
			hist_arr = state["score_history"]
			
	var total_sc = 0
	for h in hist_arr: total_sc += h.get("actual_score", 0)
	
	var max_sc = 0
	for h in hist_arr:
		var sc = h.get("actual_score", 0)
		if sc > max_sc: max_sc = sc
			
	var stats_configs = [
		{"val": str(hist_arr.size()) + "日", "lbl": "継続"},
		{"val": str(total_sc) + "点", "lbl": "累計スコア"},
		{"val": str(max_sc) + "点", "lbl": "最高記録"}
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
		
		var l_lbl = DeskTheme.create_label(cfg["lbl"], 12, DeskTheme.COLOR_MUTED)
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
	
	var bio_lbl = DeskTheme.create_label(bio_text, 13, DeskTheme.COLOR_INK)
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
	
	bc_v.add_child(DeskTheme.create_label("🧠 チキスタAI行動分析", 15, DeskTheme.COLOR_INK, true))
	
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
	
	bh.add_child(DeskTheme.create_label("ブラフ傾向:", 13, DeskTheme.COLOR_INK))
	bh.add_child(DeskTheme.create_label(bluff_title, 14, bluff_color, true))
	
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
	
	var desc_lbl = DeskTheme.create_label(bluff_desc, 12, DeskTheme.COLOR_MUTED)
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
	
	chart_v.add_child(DeskTheme.create_label("📈 過去の学習スコア推移", 16, DeskTheme.COLOR_INK, true))
	
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
		
		var s_lbl = DeskTheme.create_label(str(score), 13, DeskTheme.COLOR_MUTED)
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
		
		var d_lbl = DeskTheme.create_label("D"+str(h_data["day"]), 13, DeskTheme.COLOR_INK)
		d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_v.add_child(d_lbl)
	
	# シンプルな累計スコアサマリーカード
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
	sc_m.add_theme_constant_override("margin_bottom", 24)
	sc_m.add_child(subj_card)
	scroll_v.add_child(sc_m)
	
	var sc_v = VBoxContainer.new()
	sc_v.add_theme_constant_override("separation", 8)
	subj_card.add_child(sc_v)
	
	sc_v.add_child(DeskTheme.create_label("総獲得スコア", 15, DeskTheme.COLOR_INK, true))
	
	var s_h = HBoxContainer.new()
	s_h.add_theme_constant_override("separation", 6)
	sc_v.add_child(s_h)
	
	s_h.add_child(DeskTheme.create_label("総合", 13, DeskTheme.COLOR_SAFE, true))
	s_h.add_child(DeskTheme.create_label("%d点" % total_sc, 13, DeskTheme.COLOR_INK))
	
	var bar = DeskTheme.create_gauge_bar(total_sc, 1000.0, DeskTheme.COLOR_SAFE, Vector2(100, 6))
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
	
	var content_v = VBoxContainer.new()
	content_v.add_theme_constant_override("separation", 10)
	cv.add_child(content_v)
	
	var all_data = {}
	if is_instance_valid(ctx) and ctx.backend_manager:
		all_data = ctx.backend_manager.get_all_player_daily_scores()
	
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
		
		var is_self = (player_name == Global.player_name)
		var name_color = DeskTheme.COLOR_SAFE if is_self else DeskTheme.COLOR_INK
		var name_suffix = " (あなた)" if is_self else ""
		card_v.add_child(DeskTheme.create_label(player_name + name_suffix, 14, name_color, true))
		
		var cumulative = 0
		for day_entry in days:
			cumulative += day_entry.get("total", 0)
		
		var cum_lbl = DeskTheme.create_label("累計: %d点" % cumulative, 12, DeskTheme.COLOR_SAFE, true)
		card_v.add_child(cum_lbl)
		
		var days_h = HBoxContainer.new()
		days_h.add_theme_constant_override("separation", 4)
		days_h.alignment = BoxContainer.ALIGNMENT_CENTER
		card_v.add_child(days_h)
		
		for day_entry in days:
			var d = day_entry.get("day", 0)
			var score_val = day_entry.get("total", 0)
			
			var day_cell = VBoxContainer.new()
			day_cell.add_theme_constant_override("separation", 1)
			day_cell.alignment = BoxContainer.ALIGNMENT_CENTER
			days_h.add_child(day_cell)
			
			var score_color = DeskTheme.COLOR_SAFE if score_val > 0 else DeskTheme.COLOR_MUTED
			var s_lbl = DeskTheme.create_label(str(score_val), 11, score_color, score_val > 0)
			s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s_lbl.custom_minimum_size = Vector2(32, 0)
			day_cell.add_child(s_lbl)
			
			var d_lbl = DeskTheme.create_label("D%d" % d, 9, DeskTheme.COLOR_MUTED)
			d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			day_cell.add_child(d_lbl)
		
		var bar = DeskTheme.create_gauge_bar(cumulative, 1000.0, DeskTheme.COLOR_SAFE, Vector2(260, 8))
		card_v.add_child(bar)


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
