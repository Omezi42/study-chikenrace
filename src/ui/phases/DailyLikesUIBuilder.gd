class_name DailyLikesUIBuilder
extends RefCounted

static func build_layout(phase: DailyLikesPhase, setup_data: Dictionary = {}) -> void:
	var phone_target = phase.smartphone_pane if is_instance_valid(phase.smartphone_pane) else phase
	var notebook_target = phase
	
	# SMARTPHONE CONTAINER (Try to reuse the one passed from ReportPhase)
	var phone_panel = setup_data.get("phone_panel", null) if setup_data else null
	var is_reused = is_instance_valid(phone_panel)
	
	if is_reused:
		# Reparent to phone_target (smartphone_pane)
		if phone_panel.get_parent():
			phone_panel.get_parent().remove_child(phone_panel)
		phone_target.add_child(phone_panel)
		
		# Clear contents of the reused phone panel
		for child in phone_panel.get_children():
			child.queue_free()
			
		# Reset size and layout anchors/offsets to match left placement exactly and prevent leaks
		phone_panel.anchor_left = 0.0
		phone_panel.anchor_right = 0.0
		phone_panel.anchor_top = 0.0
		phone_panel.anchor_bottom = 0.0
		phone_panel.offset_left = 120
		phone_panel.offset_right = 540
		phone_panel.offset_top = 140
		phone_panel.offset_bottom = 940
		phone_panel.custom_minimum_size = Vector2(420, 800)
		phone_panel.size = Vector2(420, 800)
		phone_panel.position = Vector2(120, 140)
		phone_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		# Fallback: Create new phone panel if not reused
		phone_panel = PanelContainer.new()
		phone_panel.anchor_left = 0.0
		phone_panel.anchor_right = 0.0
		phone_panel.anchor_top = 0.0
		phone_panel.anchor_bottom = 0.0
		phone_panel.offset_left = 120
		phone_panel.offset_right = 540
		phone_panel.offset_top = 140
		phone_panel.offset_bottom = 940
		phone_panel.custom_minimum_size = Vector2(420, 800)
		phone_panel.size = Vector2(420, 800)
		phone_panel.position = Vector2(120, 140)
		phone_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var phone_style = StyleBoxFlat.new()
		phone_style.bg_color = DeskTheme.COLOR_INK
		phone_style.border_color = Color("37474f")
		phone_style.border_width_left = 12
		phone_style.border_width_right = 12
		phone_style.border_width_top = 32
		phone_style.border_width_bottom = 32
		phone_style.corner_radius_top_left = 28
		phone_style.corner_radius_top_right = 28
		phone_style.corner_radius_bottom_left = 28
		phone_style.corner_radius_bottom_right = 28
		phone_panel.add_theme_stylebox_override("panel", phone_style)
		phone_target.add_child(phone_panel)
		
	phase.phone_panel = phone_panel
	
	var phone_vbox = VBoxContainer.new()
	phone_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	phone_panel.add_child(phone_vbox)
	
	# Status bar
	var status_bar = Label.new()
	status_bar.text = "16:00  |  チキスタ"
	status_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_bar.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
	status_bar.add_theme_color_override("font_color", Color.WHITE)
	phone_vbox.add_child(status_bar)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.gui_input.connect(phase._on_scroll_input)
	phone_vbox.add_child(scroll)
	phase.scroll_container = scroll
	
	var timeline_list = VBoxContainer.new()
	timeline_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_list.add_theme_constant_override("separation", 18)
	scroll.add_child(timeline_list)
	phase.timeline_list = timeline_list
	
	# RIGHT COLUMN (NOTEBOOK) - Shifted to the right of the phone UI
	var right_vbox = VBoxContainer.new()
	right_vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	right_vbox.position = Vector2(790, 200)
	right_vbox.size = Vector2(780, 740)
	right_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	right_vbox.size_flags_horizontal = Control.SIZE_FILL
	right_vbox.size_flags_vertical = Control.SIZE_FILL
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 24)
	notebook_target.add_child(right_vbox)
	
	var detail_modal = PanelContainer.new()
	detail_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_modal.custom_minimum_size = Vector2(780, 600)
	detail_modal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	right_vbox.add_child(detail_modal)
	phase.detail_modal = detail_modal
	
	var detail_margin = MarginContainer.new()
	detail_margin.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_SMALL)
	detail_margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_SMALL)
	detail_margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_SMALL)
	detail_margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_SMALL)
	detail_modal.add_child(detail_margin)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 12)
	detail_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_margin.add_child(detail_vbox)
	
	var detail_title = Label.new()
	detail_title.text = "ライバル詳細ログ"
	detail_title.add_theme_font_override("font", DeskTheme.get_font())
	detail_title.add_theme_font_size_override("font_size", 24)
	detail_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_vbox.add_child(detail_title)
	phase.detail_title = detail_title
	
	var detail_body = Label.new()
	detail_body.text = "タイムラインの「詳細確認」を押すと、ライバルが今日引いたドロー数と使用したアイテムのログがここに表示されます。"
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.add_theme_font_override("font", DeskTheme.get_font())
	detail_body.add_theme_font_size_override("font_size", 18)
	detail_body.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	detail_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_body.custom_minimum_size = Vector2(0, 80)
	detail_vbox.add_child(detail_body)
	phase.detail_body = detail_body
	
	var detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.scroll_started.connect(phase._update_ellipsis_visibility)
	detail_scroll.scroll_ended.connect(phase._update_ellipsis_visibility)
	detail_scroll.get_v_scroll_bar().value_changed.connect(func(_val): phase._update_ellipsis_visibility())
	detail_vbox.add_child(detail_scroll)
	phase.detail_scroll = detail_scroll
	
	var detail_log_vbox = VBoxContainer.new()
	detail_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_log_vbox.add_theme_constant_override("separation", 14)
	detail_scroll.add_child(detail_log_vbox)
	phase.detail_log_vbox = detail_log_vbox
	
	var detail_ellipsis = Label.new()
	detail_ellipsis.text = "…（下にスクロールできます）"
	detail_ellipsis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_ellipsis.add_theme_font_override("font", DeskTheme.get_font())
	detail_ellipsis.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
	detail_ellipsis.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	detail_ellipsis.visible = false
	detail_vbox.add_child(detail_ellipsis)
	phase.detail_ellipsis = detail_ellipsis
	
	var likes_skip_btn = Button.new()
	likes_skip_btn.text = "タイムライン演出スキップ >>"
	likes_skip_btn.custom_minimum_size = Vector2(360, 50)
	likes_skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	likes_skip_btn.add_theme_font_override("font", DeskTheme.get_font())
	likes_skip_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	DeskTheme.apply_white_button_style(likes_skip_btn)
	likes_skip_btn.pressed.connect(func():
		likes_skip_btn.visible = false
		for tw in phase.active_timeline_tweens:
			if is_instance_valid(tw) and tw.is_running():
				tw.kill()
		phase.active_timeline_tweens.clear()
		for card in phase.timeline_list.get_children():
			if is_instance_valid(card):
				card.modulate.a = 1.0
				card.custom_minimum_size = Vector2(480, 185)
	)
	right_vbox.add_child(likes_skip_btn)
	phase.likes_skip_btn = likes_skip_btn
	
	var next_day_btn = Button.new()
	var is_last_day = phase.session.current_day >= Constants.MAX_DAYS
		
	if is_last_day:
		next_day_btn.text = "結果発表へ進む"
	else:
		next_day_btn.text = "明日の勉強へ進む"
		
	next_day_btn.custom_minimum_size = Vector2(360, 65)
	next_day_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_day_btn.add_theme_font_override("font", DeskTheme.get_font())
	next_day_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	DeskTheme.apply_white_button_style(next_day_btn)
	next_day_btn.pressed.connect(phase._on_next_day_pressed)
	right_vbox.add_child(next_day_btn)
	phase.next_day_btn = next_day_btn
	

static func build_timeline_card(phase: DailyLikesPhase, p: Dictionary, idx: int) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(480, 185)
	card.pivot_offset = Vector2(240, 92)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = DeskTheme.COLOR_CRAFT
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6
	card_style.corner_radius_bottom_right = 6
	card_style.border_width_left = 4
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	
	var is_suspicious = false
	var suspiciousness = 0.0
	if p["id"] != "player":
		suspiciousness = AIManager.evaluate_suspiciousness_with_emote(p["declared_score"], p["hours"], p.get("emote", "normal"))
		if suspiciousness > 0.65:
			is_suspicious = true
	
	if is_suspicious:
		card_style.border_color = DeskTheme.COLOR_TENSION
		card_style.border_width_left = 6
		card_style.border_width_right = 6
		card_style.border_width_top = 6
		card_style.border_width_bottom = 6
		# Background slightly reddish
		card_style.bg_color = Color("ffebee")
	else:
		if idx == 0:
			card_style.border_color = Color("ffd700")
		elif idx == 1:
			card_style.border_color = Color("c0c0c0")
		elif idx == 2:
			card_style.border_color = Color("cd7f32")
		else:
			card_style.border_color = Color("37474f")
		
	card.add_theme_stylebox_override("panel", card_style)
	card.clip_contents = true
	
	card.modulate.a = 0.0
	card.custom_minimum_size = Vector2(480, 0)
	
	if is_suspicious:
		DeskTheme.pulse_vignette(card, Color.WHITE, suspiciousness)
	
	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 12)
	card_margin.add_theme_constant_override("margin_right", 12)
	card_margin.add_theme_constant_override("margin_top", 12)
	card_margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(card_margin)
	
	var card_hbox = HBoxContainer.new()
	card_hbox.add_theme_constant_override("separation", 15)
	card_margin.add_child(card_hbox)
	
	var avatar = ColorRect.new()
	avatar.custom_minimum_size = Vector2(48, 48)
	avatar.color = p["avatar_color"]
	card_hbox.add_child(avatar)
	
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 6)
	card_hbox.add_child(text_vbox)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	text_vbox.add_child(header_hbox)
	
	var name_lbl = Label.new()
	if is_suspicious:
		name_lbl.text = p["name"] + " (怪しい...)"
	else:
		name_lbl.text = p["name"]
	name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	header_hbox.add_child(name_lbl)
	
	var emote_key = p.get("emote", "normal")
	var emote_badge = Label.new()
	
	var badge_style = StyleBoxFlat.new()
	badge_style.content_margin_left = 6
	badge_style.content_margin_right = 6
	badge_style.content_margin_top = 2
	badge_style.content_margin_bottom = 2
	badge_style.corner_radius_top_left = 4
	badge_style.corner_radius_top_right = 4
	badge_style.corner_radius_bottom_left = 4
	badge_style.corner_radius_bottom_right = 4
	
	match emote_key:
		"normal":
			emote_badge.text = "[普通]"
			badge_style.bg_color = Color("eceff1")
			emote_badge.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		"confident":
			emote_badge.text = "[自信あり]"
			badge_style.bg_color = Color("e8f5e9")
			emote_badge.add_theme_color_override("font_color", Color("2e7d32"))
		"anxious":
			emote_badge.text = "[不安]"
			badge_style.bg_color = Color("ffebee")
			emote_badge.add_theme_color_override("font_color", Color("c62828"))
			
	emote_badge.add_theme_stylebox_override("normal", badge_style)
	emote_badge.add_theme_font_override("font", DeskTheme.get_font())
	emote_badge.add_theme_font_size_override("font_size", 13)
	header_hbox.add_child(emote_badge)
	
	var toggle_btn = Button.new()
	toggle_btn.text = " ▲ "
	toggle_btn.flat = true
	toggle_btn.add_theme_font_override("font", DeskTheme.get_font())
	toggle_btn.add_theme_font_size_override("font_size", 14)
	header_hbox.add_child(toggle_btn)
	
	var collapsible_container = VBoxContainer.new()
	collapsible_container.add_theme_constant_override("separation", 6)
	text_vbox.add_child(collapsible_container)
	
	var decl_lbl = Label.new()
	decl_lbl.text = "今日の勉強報告：" + str(p["declared_score"]) + " 点！"
	decl_lbl.add_theme_font_override("font", DeskTheme.get_font())
	decl_lbl.add_theme_font_size_override("font_size", 18)
	decl_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
	collapsible_container.add_child(decl_lbl)
	
	var act_hbox = HBoxContainer.new()
	act_hbox.alignment = BoxContainer.ALIGNMENT_END
	act_hbox.add_theme_constant_override("separation", 10)
	collapsible_container.add_child(act_hbox)
	
	var inspect_btn = Button.new()
	inspect_btn.text = "詳細確認"
	inspect_btn.add_theme_font_size_override("font_size", 14)
	inspect_btn.pressed.connect(phase._on_inspect_pressed.bind(p))
	act_hbox.add_child(inspect_btn)
	
	if p["id"] != "player":
		var doubt_btn = Button.new()
		doubt_btn.name = "DoubtButton"
		doubt_btn.text = "ダウト!"
		doubt_btn.add_theme_font_size_override("font_size", 14)
		doubt_btn.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		
		if p["id"] in phase.session.player_doubts_made_today:
			doubt_btn.text = "ダウト済"
			doubt_btn.disabled = true
			
		doubt_btn.pressed.connect(phase._on_doubt_pressed.bind(p["id"], card, doubt_btn))
		act_hbox.add_child(doubt_btn)
		
	toggle_btn.pressed.connect(func():
		collapsible_container.visible = not collapsible_container.visible
		if collapsible_container.visible:
			toggle_btn.text = " ▲ "
			card.custom_minimum_size.y = 185
		else:
			toggle_btn.text = " ▼ "
			card.custom_minimum_size.y = 75
	)
	
	return card

static func populate_inspect_modal(phase: DailyLikesPhase, p: Dictionary) -> void:
	phase.detail_title.text = "【推理カード】 " + p["name"]
	phase.detail_body.visible = false
	
	for child in phase.detail_log_vbox.get_children():
		child.queue_free()
		
	# 1. 相手のサマリー情報のカード化
	var summary_card = PanelContainer.new()
	var summary_style = DeskTheme.create_craft_panel()
	summary_style.bg_color = Color("eceff1")
	summary_card.add_theme_stylebox_override("panel", summary_style)
	phase.detail_log_vbox.add_child(summary_card)
	
	var summary_margin = MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", 15)
	summary_margin.add_theme_constant_override("margin_right", 15)
	summary_margin.add_theme_constant_override("margin_top", 15)
	summary_margin.add_theme_constant_override("margin_bottom", 15)
	summary_card.add_child(summary_margin)
	
	var summary_vbox = VBoxContainer.new()
	summary_vbox.add_theme_constant_override("separation", 10)
	summary_margin.add_child(summary_vbox)
	
	# サマリー情報の集計
	var total_draws = 0
	for h in p["hours"]:
		total_draws += h.get("draws", 0)
	var bluff_rate = 0.0
	if p["id"] != "player":
		bluff_rate = AIManager.evaluate_suspiciousness_with_emote(p["declared_score"], p["hours"], p.get("emote", "normal")) * 100.0
		
	var info_grid = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 30)
	info_grid.add_theme_constant_override("v_separation", 10)
	summary_vbox.add_child(info_grid)
	
	var labels = [
		["申告:", str(p["declared_score"]) + " 点"],
		["引いた合計枚数:", str(total_draws) + " 枚"]
	]
	
	if p["id"] != "player":
		labels.append(["過去傾向:", "ブラフ率 約" + str(int(bluff_rate)) + "%"])
		
	for pair in labels:
		var lbl_title = Label.new()
		lbl_title.text = pair[0]
		lbl_title.add_theme_font_override("font", DeskTheme.get_font())
		lbl_title.add_theme_font_size_override("font_size", 18)
		lbl_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
		info_grid.add_child(lbl_title)
		
		var lbl_val = Label.new()
		lbl_val.text = pair[1]
		lbl_val.add_theme_font_override("font", DeskTheme.get_font())
		lbl_val.add_theme_font_size_override("font_size", 22)
		if "ブラフ率" in pair[0] and bluff_rate > 65.0:
			lbl_val.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		else:
			lbl_val.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		info_grid.add_child(lbl_val)
	
	if p["id"] != "player":
		var doubt_btn = Button.new()
		doubt_btn.name = "DetailDoubtButton"
		doubt_btn.text = "ダウト！"
		doubt_btn.custom_minimum_size = Vector2(0, 50)
		doubt_btn.add_theme_font_override("font", DeskTheme.get_font())
		doubt_btn.add_theme_font_size_override("font_size", 24)
		doubt_btn.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		DeskTheme.apply_white_button_style(doubt_btn)
		
		if p["id"] in phase.session.player_doubts_made_today:
			doubt_btn.text = "ダウト済"
			doubt_btn.disabled = true
			
		# カードUI上のダウトボタン押下処理 (timeline_card引数にはnullを渡すが、UI構築時点での引数としては適宜対応)
		# 既存の_on_doubt_pressedは引数として(target_id, card_node, btn)を取る
		# timeline_card側ではなく、このモーダルから呼ばれた場合はcard_nodeはsummary_cardにする
		doubt_btn.pressed.connect(phase._on_doubt_pressed.bind(p["id"], summary_card, doubt_btn))
		summary_vbox.add_child(doubt_btn)
		
	var separator = ColorRect.new()
	separator.custom_minimum_size = Vector2(0, 2)
	separator.color = Color(DeskTheme.COLOR_INK, 0.2)
	phase.detail_log_vbox.add_child(separator)
		
	for h_idx in range(p["hours"].size()):
		var h = p["hours"][h_idx]
		
		var row = VBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		phase.detail_log_vbox.add_child(row)
		
		# 1行目: 時限ラベルと枚数・状態テキスト
		var line1 = HBoxContainer.new()
		line1.alignment = BoxContainer.ALIGNMENT_BEGIN
		line1.add_theme_constant_override("separation", 10)
		row.add_child(line1)
		
		var hour_lbl = Label.new()
		hour_lbl.text = " %d時限目 " % (h_idx + 1)
		hour_lbl.add_theme_font_override("font", DeskTheme.get_font())
		hour_lbl.add_theme_font_size_override("font_size", 18)
		hour_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		hour_lbl.add_theme_constant_override("outline_size", 3)
		hour_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
		
		var hour_style = StyleBoxFlat.new()
		hour_style.bg_color = Color(DeskTheme.COLOR_MAHOGANY, 0.08)
		hour_style.border_color = Color(DeskTheme.COLOR_INK, 0.3)
		hour_style.border_width_left = 1
		hour_style.border_width_right = 1
		hour_style.border_width_top = 1
		hour_style.border_width_bottom = 1
		hour_style.corner_radius_top_left = 4
		hour_style.corner_radius_top_right = 4
		hour_style.corner_radius_bottom_left = 4
		hour_style.corner_radius_bottom_right = 4
		hour_style.content_margin_left = 6
		hour_lbl.add_theme_stylebox_override("normal", hour_style)
		line1.add_child(hour_lbl)
		
		var count_lbl = Label.new()
		var count_text = "(%d枚ドロー)" % h.get("draws", 0)
		var text_color = Color(DeskTheme.COLOR_INK, 0.8) # Sightly higher contrast ink
		var status_icon_tex: Texture = null
		
		if p["id"] == "player":
			if h.get("bursted", false):
				count_text = "寝落ち [0点] (%d枚)" % h.get("draws", 0)
				text_color = DeskTheme.COLOR_TENSION
				status_icon_tex = load("res://assets/sleep_icon.png")
			else:
				count_text = "実点: %d点 (%d枚)" % [h.get("score", 0), h.get("draws", 0)]
				text_color = DeskTheme.COLOR_GREEN
				status_icon_tex = load("res://assets/pencil_icon.png")
		else:
			text_color = DeskTheme.COLOR_INK
				
		count_lbl.text = count_text
		count_lbl.add_theme_font_override("font", DeskTheme.get_font())
		count_lbl.add_theme_font_size_override("font_size", 18)
		count_lbl.add_theme_color_override("font_color", text_color)
		count_lbl.add_theme_constant_override("outline_size", 3)
		count_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
		
		if status_icon_tex:
			var stat_rect = TextureRect.new()
			stat_rect.texture = status_icon_tex
			stat_rect.custom_minimum_size = Vector2(20, 20)
			stat_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			stat_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			line1.add_child(stat_rect)
			
		line1.add_child(count_lbl)
		
		if h.has("reaction") and h["reaction"] != "":
			var react_lbl = Label.new()
			react_lbl.text = " [%s]" % h["reaction"]
			react_lbl.add_theme_font_override("font", DeskTheme.get_font())
			react_lbl.add_theme_font_size_override("font_size", 16)
			react_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
			react_lbl.add_theme_constant_override("outline_size", 2)
			react_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
			line1.add_child(react_lbl)
		
		# 2行目: ドローしたカードと使用したアイテム (少しインデントを入れる)
		var line2_margin = MarginContainer.new()
		line2_margin.add_theme_constant_override("margin_left", 15)
		row.add_child(line2_margin)
		
		var line2 = HBoxContainer.new()
		line2.alignment = BoxContainer.ALIGNMENT_BEGIN
		line2.add_theme_constant_override("separation", 15)
		line2_margin.add_child(line2)
		
		var cards_hbox = HBoxContainer.new()
		cards_hbox.add_theme_constant_override("separation", 3)
		line2.add_child(cards_hbox)
		
		for c_i in range(h.get("draws", 0)):
			var mini_card = PanelContainer.new()
			mini_card.custom_minimum_size = Vector2(18, 24)
			
			var m_style = StyleBoxFlat.new()
			m_style.bg_color = DeskTheme.COLOR_CRAFT
			m_style.border_color = DeskTheme.COLOR_INK
			m_style.border_width_left = 1
			m_style.border_width_right = 1
			m_style.border_width_top = 1
			m_style.border_width_bottom = 1
			m_style.corner_radius_top_left = 2
			m_style.corner_radius_top_right = 2
			m_style.corner_radius_bottom_left = 2
			m_style.corner_radius_bottom_right = 2
			mini_card.add_theme_stylebox_override("panel", m_style)
			
			# Mini card is now blank as requested (suit symbol removed)
			pass
			
			cards_hbox.add_child(mini_card)
			
		pass
				
	DeskTheme.shake_control(phase.detail_modal, 4.0, 0.2)

static func show_doubt_result_modal(
	phase: DailyLikesPhase,
	opp_name: String, 
	is_bluff: bool, 
	declared_score: int, 
	actual_score: int, 
	my_score_change: int, 
	opp_score_change: int,
	my_details: String,
	opp_details: String
) -> void:
	var scene_tree = phase.get_tree()
	if not scene_tree or not scene_tree.root:
		return
		
	var canvas = CanvasLayer.new()
	canvas.layer = 160
	scene_tree.root.add_child(canvas)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(750, 500)
	modal.pivot_offset = Vector2(375, 250)
	
	var base_style = DeskTheme.create_craft_panel()
	if is_bluff:
		base_style.border_color = DeskTheme.COLOR_GREEN
	else:
		base_style.border_color = DeskTheme.COLOR_TENSION
	base_style.border_width_left = 6
	base_style.border_width_right = 6
	base_style.border_width_top = 6
	base_style.border_width_bottom = 6
	modal.add_theme_stylebox_override("panel", base_style)
	canvas.add_child(modal)
	
	var viewport_size = scene_tree.root.get_viewport().get_visible_rect().size
	var screen_w = viewport_size.x if viewport_size.x > 0 else 1920
	var screen_h = viewport_size.y if viewport_size.y > 0 else 1080
	modal.position = Vector2((screen_w - 750) / 2.0, (screen_h - 500) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 36)
	
	if is_bluff:
		title_lbl.text = "ダウト成功！"
		title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	else:
		title_lbl.text = "ダウト失敗..."
		title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
	desc_lbl.add_theme_font_size_override("font_size", 18)
	desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	
	if is_bluff:
		desc_lbl.text = "%s は勉強報告で嘘をついていた！\n【申告】 %d 点  ➡  【実際】 %d 点" % [opp_name, declared_score, actual_score]
	else:
		desc_lbl.text = "%s は正直に勉強していた！\n【申告】 %d 点  ➡  【実際】 %d 点" % [opp_name, declared_score, actual_score]
	vbox.add_child(desc_lbl)
	
	var cards_hbox = HBoxContainer.new()
	cards_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(cards_hbox)
	
	var my_card = PanelContainer.new()
	my_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var my_style = StyleBoxFlat.new()
	if is_bluff:
		my_style.bg_color = Color("e8f5e9")
		my_style.border_color = Color("81c784")
	else:
		my_style.bg_color = Color("ffebee")
		my_style.border_color = Color("e57373")
	my_style.border_width_left = 2
	my_style.border_width_right = 2
	my_style.border_width_top = 2
	my_style.border_width_bottom = 2
	my_style.corner_radius_top_left = 8
	my_style.corner_radius_top_right = 8
	my_style.corner_radius_bottom_left = 8
	my_style.corner_radius_bottom_right = 8
	my_card.add_theme_stylebox_override("panel", my_style)
	cards_hbox.add_child(my_card)
	
	var my_margin = MarginContainer.new()
	my_margin.add_theme_constant_override("margin_left", 15)
	my_margin.add_theme_constant_override("margin_right", 15)
	my_margin.add_theme_constant_override("margin_top", 15)
	my_margin.add_theme_constant_override("margin_bottom", 15)
	my_card.add_child(my_margin)
	
	var my_vbox = VBoxContainer.new()
	my_vbox.add_theme_constant_override("separation", 8)
	my_margin.add_child(my_vbox)
	
	var my_title = Label.new()
	my_title.text = "あなたへの影響"
	my_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_title.add_theme_font_override("font", DeskTheme.get_font())
	my_title.add_theme_font_size_override("font_size", 16)
	my_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	my_vbox.add_child(my_title)
	
	var my_diff_lbl = Label.new()
	my_diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_diff_lbl.add_theme_font_override("font", DeskTheme.get_font())
	my_diff_lbl.add_theme_font_size_override("font_size", 32)
	
	if my_score_change >= 0:
		my_diff_lbl.text = "+%d 点" % my_score_change
		my_diff_lbl.add_theme_color_override("font_color", Color("2e7d32"))
	else:
		my_diff_lbl.text = "%d 点" % my_score_change
		my_diff_lbl.add_theme_color_override("font_color", Color("c62828"))
	my_vbox.add_child(my_diff_lbl)
	
	var my_detail_lbl = Label.new()
	my_detail_lbl.text = my_details
	my_detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	my_detail_lbl.add_theme_font_override("font", DeskTheme.get_font())
	my_detail_lbl.add_theme_font_size_override("font_size", 13)
	my_detail_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	my_vbox.add_child(my_detail_lbl)
	
	var opp_card = PanelContainer.new()
	opp_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opp_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var opp_style = StyleBoxFlat.new()
	if is_bluff:
		opp_style.bg_color = Color("ffebee")
		opp_style.border_color = Color("e57373")
	else:
		opp_style.bg_color = Color("eceff1")
		opp_style.border_color = Color("b0bec5")
	opp_style.border_width_left = 2
	opp_style.border_width_right = 2
	opp_style.border_width_top = 2
	opp_style.border_width_bottom = 2
	opp_style.corner_radius_top_left = 8
	opp_style.corner_radius_top_right = 8
	opp_style.corner_radius_bottom_left = 8
	opp_style.corner_radius_bottom_right = 8
	opp_card.add_theme_stylebox_override("panel", opp_style)
	cards_hbox.add_child(opp_card)
	
	var opp_margin = MarginContainer.new()
	opp_margin.add_theme_constant_override("margin_left", 15)
	opp_margin.add_theme_constant_override("margin_right", 15)
	opp_margin.add_theme_constant_override("margin_top", 15)
	opp_margin.add_theme_constant_override("margin_bottom", 15)
	opp_card.add_child(opp_margin)
	
	var opp_vbox = VBoxContainer.new()
	opp_vbox.add_theme_constant_override("separation", 8)
	opp_margin.add_child(opp_vbox)
	
	var opp_title = Label.new()
	opp_title.text = opp_name + " への影響"
	opp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_title.add_theme_font_override("font", DeskTheme.get_font())
	opp_title.add_theme_font_size_override("font_size", 16)
	opp_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	opp_vbox.add_child(opp_title)
	
	var opp_diff_lbl = Label.new()
	opp_diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_diff_lbl.add_theme_font_override("font", DeskTheme.get_font())
	opp_diff_lbl.add_theme_font_size_override("font_size", 32)
	
	if opp_score_change < 0:
		opp_diff_lbl.text = "%d 点" % opp_score_change
		opp_diff_lbl.add_theme_color_override("font_color", Color("c62828"))
	else:
		opp_diff_lbl.text = "±0 点"
		opp_diff_lbl.add_theme_color_override("font_color", Color("455a64"))
	opp_vbox.add_child(opp_diff_lbl)
	
	var opp_detail_lbl = Label.new()
	opp_detail_lbl.text = opp_details
	opp_detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opp_detail_lbl.add_theme_font_override("font", DeskTheme.get_font())
	opp_detail_lbl.add_theme_font_size_override("font_size", 13)
	opp_detail_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	opp_vbox.add_child(opp_detail_lbl)
	
	var close_btn = Button.new()
	close_btn.text = "タイムラインに戻る"
	close_btn.custom_minimum_size = Vector2(250, 50)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 18)
	DeskTheme.apply_white_button_style(close_btn)
	vbox.add_child(close_btn)
	
	close_btn.pressed.connect(func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var t = scene_tree.create_timer(0.12)
		t.timeout.connect(func():
			var fade_tween = scene_tree.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fade_tween.tween_property(modal, "scale", Vector2(0.8, 0.8), 0.2)
			fade_tween.tween_property(modal, "modulate:a", 0.0, 0.2)
			fade_tween.tween_property(bg, "color:a", 0.0, 0.2)
			fade_tween.chain().tween_callback(func():
				canvas.queue_free()
				if phase.has_method("_on_doubt_modal_closed"):
					phase._on_doubt_modal_closed()
			)
		)
	)
	
	if phase.has_node("/root/AudioManager"):
		var audio = phase.get_node("/root/AudioManager")
		if is_bluff:
			audio.play_se(AudioManager.SE_COMBO)
		else:
			audio.play_se(AudioManager.SE_BURST, 0.0, -8.0)
			
	modal.scale = Vector2.ZERO
	var tween = scene_tree.create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.35)

static func show_tutorial_finish_modal(phase: DailyLikesPhase) -> void:
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(650, 400)
	modal.size = Vector2(650, 400)
	modal.pivot_offset = Vector2(325, 200)
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_CRAFT
	style.border_color = DeskTheme.COLOR_GREEN
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 20
	style.shadow_offset = Vector2(5, 5)
	modal.add_theme_stylebox_override("panel", style)
	
	phase.add_child(modal)
	var viewport_size = phase.get_viewport_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "チュートリアル完了！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	vbox.add_child(title)
	
	var body = Label.new()
	body.text = "お疲れ様でした！『テスト勉強チキンレース』の基本的な遊び方（自習、持ち込みアイテム設定、チキスタへの投稿、嘘とダウトの見極め）をマスターしました。\n\n模試やマッチングで、他のライバルたちを実力とブラフで圧倒し、第一志望合格（偏差値アップ）を勝ち取りましょう！"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", DeskTheme.get_font())
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(body)
	
	var btn = Button.new()
	btn.text = "タイトル画面に戻る"
	btn.custom_minimum_size = Vector2(240, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", DeskTheme.get_font())
	btn.add_theme_font_size_override("font_size", 20)
	DeskTheme.apply_white_button_style(btn)
	btn.pressed.connect(func():
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		PlayerState.is_tutorial_completed = true
		Global.save_game()
		Global.is_tutorial_mode = false
		var timer = phase.get_tree().create_timer(0.2)
		timer.timeout.connect(func():
			Global.change_scene_with_fade(phase.get_tree(), "res://Title.tscn")
		)
	)
	vbox.add_child(btn)
	
	modal.scale = Vector2.ZERO
	var tween = phase.create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
