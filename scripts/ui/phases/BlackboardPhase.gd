# scripts/ui/phases/BlackboardPhase.gd
class_name BlackboardPhase
extends RefCounted
const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")


signal phase_completed()

var ctx: RefCounted

# UI参照保持
var active_tab_state = {"active": 0}

func _init(context: RefCounted):
	self.ctx = context

func start():
	_show_blackboard_progress()

func _show_blackboard_progress():
	for child in ctx.screen_content.get_children():
		child.queue_free()
	
	# 背景に見開きノートを置く（ふせんフェーズと同じ世界観を維持）
	var notebook = NotebookBuilderScript.create()
	notebook.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notebook.offset_left = 420.0
	notebook.offset_top = 80.0
	notebook.offset_right = -120.0
	notebook.offset_bottom = -80.0
	ctx.screen_content.add_child(notebook)
	ctx.active_notebook = notebook
	
	# 左側の机の上エリア（スマホ置き場）
	var left_area = Control.new()
	left_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_area.anchor_right = 0.3 # 画面左側30%
	ctx.screen_content.add_child(left_area)
	
	var app_container = SmartphoneBuilderScript.create_mockup(ctx, false)
	
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
	active_tab_state["active"] = default_tab
	
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
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		active_tab_state["active"] = 0
		update_tabs.call()
	)
	tab_feed_btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		active_tab_state["active"] = 1
		update_tabs.call()
	)
	to_feed_btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
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
	
	var tops = ctx.backend_manager.get_subject_top_scores()
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
			
			# 3. いいね（投票）の極小丸型ボタン (他人かつ有効な相手のみ)
			if top["name"] != Global.player_name and top["name"] != "なし" and top["name"] != "誰もいない":
				var already_voted = ctx.backend_manager.has_voted_rival(top["name"], s)
				
				# いいねボタン (👍)
				var like_btn = Button.new()
				like_btn.custom_minimum_size = Vector2(32, 32)
				like_btn.size = Vector2(32, 32)
				
				var lb_normal = StyleBoxFlat.new()
				lb_normal.bg_color = Color("f0f4f8") if not already_voted else Color("dbe3eb")
				lb_normal.border_width_left = 1.0; lb_normal.border_width_right = 1.0
				lb_normal.border_width_top = 1.0; lb_normal.border_width_bottom = 1.0
				lb_normal.border_color = Color("8fa4b8") if not already_voted else Color("a6b8c7")
				lb_normal.corner_radius_top_left = 16; lb_normal.corner_radius_top_right = 16
				lb_normal.corner_radius_bottom_left = 16; lb_normal.corner_radius_bottom_right = 16
				like_btn.add_theme_stylebox_override("normal", lb_normal)
				like_btn.add_theme_stylebox_override("hover", lb_normal)
				
				var lb_disabled = StyleBoxFlat.new()
				lb_disabled.bg_color = Color("dbe3eb")
				lb_disabled.corner_radius_top_left = 16; lb_disabled.corner_radius_top_right = 16
				lb_disabled.corner_radius_bottom_left = 16; lb_disabled.corner_radius_bottom_right = 16
				like_btn.add_theme_stylebox_override("disabled", lb_disabled)
				
				like_btn.text = "👍"
				like_btn.add_theme_color_override("font_color", Color("1c7ed6"))
				like_btn.add_theme_color_override("font_disabled_color", Color("748ffc"))
				like_btn.add_theme_font_size_override("font_size", 12)
				like_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				like_btn.disabled = already_voted
				
				like_btn.pressed.connect(func():
					if state["liked"] or ctx.backend_manager.has_voted_rival(top["name"], s): return
					state["liked"] = true
					ctx.backend_manager.vote_rival(top["name"], s)
					
					if ctx.audio_manager: ctx.audio_manager.play_se("place")
					like_btn.disabled = true
					
					# 中立的で楽しげなトーストを表示
					ToastOverlayScript.show_toast(ctx.ui_root, "%s の報告に『いいね』しました！\n（嘘を見破れたかは最終日の通知表で公開！）" % top["name"], DeskTheme.COLOR_SAFE)
				)
				c_h.add_child(like_btn)
				
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
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		phase_completed.emit()
	)
	footer_h.add_child(next_btn)