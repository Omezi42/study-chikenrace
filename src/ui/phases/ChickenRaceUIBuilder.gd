class_name ChickenRaceUIBuilder
extends RefCounted

static func build_ui(phase: ChickenRacePhase) -> void:
	var session = phase.session
	
	# Layout setup (2 pages: Left and Right touching at separation 0)
	var main_hbox = HBoxContainer.new()
	main_hbox.custom_minimum_size = Vector2(1500, 850)
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 0)
	phase.add_child(main_hbox)
	
	# LEFT PAGE (Notebook Stats)
	var left_page = PanelContainer.new()
	left_page.custom_minimum_size = Vector2(650, 850)
	left_page.add_theme_stylebox_override("panel", DeskTheme.create_left_page_style())
	main_hbox.add_child(left_page)
	phase.left_page = left_page
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 25)
	left_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_page.add_child(left_vbox)
	
	var left_margin = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 30)
	left_margin.add_theme_constant_override("margin_right", 30)
	left_margin.add_theme_constant_override("margin_top", 30)
	left_margin.add_theme_constant_override("margin_bottom", 30)
	left_vbox.add_child(left_margin)
	
	var left_inner_vbox = VBoxContainer.new()
	left_inner_vbox.add_theme_constant_override("separation", 20)
	left_margin.add_child(left_inner_vbox)
	
	var header_left = Label.new()
	header_left.text = "自習ノート - %d時限目" % session.current_hour
	header_left.add_theme_font_override("font", DeskTheme.get_font())
	header_left.add_theme_font_size_override("font_size", 32)
	header_left.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	left_inner_vbox.add_child(header_left)
	phase.header_left = header_left
	
	# 同室のメンバーの名前一覧を表示する個別付箋風UI
	var room_members_hbox = HBoxContainer.new()
	room_members_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	room_members_hbox.add_theme_constant_override("separation", 12)
	left_inner_vbox.add_child(room_members_hbox)
	
	phase.member_panels.clear()
	phase.member_labels.clear()
	
	var members = []
	var player_disp_name = Global.player_name if Global.player_name != "" else "あなた"
	members.append({"id": "player", "name": player_disp_name, "icon": "[自分]", "color": Color("fff9c4"), "angle": 0.8})
	
	var colors = [Color("bbdefb"), Color("f8bbd0"), Color("c8e6c9")]
	var angles = [-1.5, 1.2, -0.6]
	var color_idx = 0
	
	for opp_id in Global.opponent_profiles.keys():
		var opp = Global.opponent_profiles[opp_id]
		var opp_name = opp.get("name", "ライバル")
		var col = colors[color_idx % colors.size()]
		var ang = angles[color_idx % angles.size()]
		members.append({"id": opp_id, "name": opp_name, "icon": "[他]", "color": col, "angle": ang})
		color_idx += 1
		
	for member in members:
		var note_label = Label.new()
		note_label.text = member["icon"] + " " + member["name"] + "\n勉強: 0枚"
		note_label.add_theme_font_override("font", DeskTheme.get_font())
		note_label.add_theme_font_size_override("font_size", 14)
		note_label.add_theme_color_override("font_color", Color("263238"))
		
		var note_style = StyleBoxFlat.new()
		note_style.bg_color = member["color"]
		note_style.border_color = Color(DeskTheme.COLOR_INK, 0.15)
		note_style.border_width_left = 1
		note_style.border_width_right = 1
		note_style.border_width_top = 1
		note_style.border_width_bottom = 1
		note_style.corner_radius_top_left = 2
		note_style.corner_radius_top_right = 2
		note_style.corner_radius_bottom_left = 2
		note_style.corner_radius_bottom_right = 2
		note_style.content_margin_left = 8
		note_style.content_margin_right = 8
		note_style.content_margin_top = 4
		note_style.content_margin_bottom = 4
		note_style.shadow_color = Color(0, 0, 0, 0.08)
		note_style.shadow_size = 2
		note_style.shadow_offset = Vector2(1, 1.5)
		
		var note_panel = PanelContainer.new()
		note_panel.add_theme_stylebox_override("panel", note_style)
		note_panel.add_child(note_label)
		note_panel.rotation_degrees = member["angle"]
		note_panel.pivot_offset = Vector2(50, 15)
		room_members_hbox.add_child(note_panel)
		
		phase.member_panels[member["id"]] = note_panel
		phase.member_labels[member["id"]] = note_label
	
	var score_title = Label.new()
	score_title.text = "現在の勉強成果（実点）"
	score_title.add_theme_font_override("font", DeskTheme.get_font())
	score_title.add_theme_font_size_override("font_size", 22)
	score_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	left_inner_vbox.add_child(score_title)
	
	var actual_score_label = Label.new()
	actual_score_label.text = "0点"
	actual_score_label.add_theme_font_override("font", DeskTheme.get_font())
	actual_score_label.add_theme_font_size_override("font_size", 84)
	actual_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	left_inner_vbox.add_child(actual_score_label)
	phase.actual_score_label = actual_score_label
	
	var history_title = Label.new()
	history_title.text = "勉強履歴"
	history_title.add_theme_font_override("font", DeskTheme.get_font())
	history_title.add_theme_font_size_override("font_size", 22)
	history_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	left_inner_vbox.add_child(history_title)
	
	var draw_history_container = HBoxContainer.new()
	draw_history_container.add_theme_constant_override("separation", 12)
	left_inner_vbox.add_child(draw_history_container)
	phase.draw_history_container = draw_history_container
	
	var card_detail_box = PanelContainer.new()
	card_detail_box.custom_minimum_size = Vector2(400, 140)
	card_detail_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_detail_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_detail_box.visible = true
	
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = DeskTheme.COLOR_CRAFT
	detail_style.border_color = Color(DeskTheme.COLOR_INK, 0.5)
	detail_style.border_width_left = 2
	detail_style.border_width_right = 2
	detail_style.border_width_top = 2
	detail_style.border_width_bottom = 2
	detail_style.corner_radius_top_left = 6
	detail_style.corner_radius_top_right = 6
	detail_style.corner_radius_bottom_left = 6
	detail_style.corner_radius_bottom_right = 6
	detail_style.content_margin_left = 15
	detail_style.content_margin_right = 15
	detail_style.content_margin_top = 10
	detail_style.content_margin_bottom = 10
	detail_style.shadow_color = Color(0, 0, 0, 0.2)
	detail_style.shadow_size = 4
	detail_style.shadow_offset = Vector2(2, 2)
	card_detail_box.add_theme_stylebox_override("panel", detail_style)
	left_inner_vbox.add_child(card_detail_box)
	phase.card_detail_box = card_detail_box
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 6)
	card_detail_box.add_child(detail_vbox)
	
	var detail_header_hbox = HBoxContainer.new()
	detail_header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	detail_header_hbox.add_theme_constant_override("separation", 10)
	detail_vbox.add_child(detail_header_hbox)
	
	var detail_title_label = Label.new()
	detail_title_label.text = "カード説明"
	detail_title_label.add_theme_font_override("font", DeskTheme.get_font())
	detail_title_label.add_theme_font_size_override("font_size", 20)
	detail_title_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_header_hbox.add_child(detail_title_label)
	phase.detail_title_label = detail_title_label
	
	var detail_role_label = Label.new()
	detail_role_label.text = ""
	detail_role_label.add_theme_font_override("font", DeskTheme.get_font())
	detail_role_label.add_theme_font_size_override("font_size", 16)
	detail_header_hbox.add_child(detail_role_label)
	phase.detail_role_label = detail_role_label
	
	var detail_desc_label = Label.new()
	detail_desc_label.text = "カードをクリックすると効果の説明が表示されます。"
	detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_label.add_theme_font_override("font", DeskTheme.get_font())
	detail_desc_label.add_theme_font_size_override("font_size", 14)
	detail_desc_label.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	detail_desc_label.custom_minimum_size = Vector2(360, 50)
	detail_vbox.add_child(detail_desc_label)
	phase.detail_desc_label = detail_desc_label
	
	# RIGHT PAGE (Desk Self-study Area)
	var right_page = PanelContainer.new()
	right_page.custom_minimum_size = Vector2(730, 850)
	right_page.add_theme_stylebox_override("panel", DeskTheme.create_right_page_style())
	main_hbox.add_child(right_page)
	phase.right_page = right_page
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 25)
	right_page.add_child(right_vbox)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 30)
	right_margin.add_theme_constant_override("margin_right", 30)
	right_margin.add_theme_constant_override("margin_top", 30)
	right_margin.add_theme_constant_override("margin_bottom", 30)
	right_vbox.add_child(right_margin)
	
	var right_inner_vbox = VBoxContainer.new()
	right_inner_vbox.add_theme_constant_override("separation", 25)
	right_margin.add_child(right_inner_vbox)
	
	var status_hbox = HBoxContainer.new()
	status_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	right_inner_vbox.add_child(status_hbox)
	
	var led_indicator = ColorRect.new()
	led_indicator.custom_minimum_size = Vector2(24, 24)
	led_indicator.color = DeskTheme.COLOR_GREEN
	status_hbox.add_child(led_indicator)
	phase.led_indicator = led_indicator
	
	var burst_prob_label = Label.new()
	burst_prob_label.text = "眠気：安全 (0%)"
	burst_prob_label.add_theme_font_override("font", DeskTheme.get_font())
	burst_prob_label.add_theme_font_size_override("font_size", 22)
	burst_prob_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	status_hbox.add_child(burst_prob_label)
	phase.burst_prob_label = burst_prob_label
	
	var active_effects_hbox = HBoxContainer.new()
	active_effects_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	active_effects_hbox.add_theme_constant_override("separation", 8)
	right_inner_vbox.add_child(active_effects_hbox)
	phase.active_effects_hbox = active_effects_hbox
	
	var hand_container = Control.new()
	hand_container.custom_minimum_size = Vector2(650, 360)
	hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_inner_vbox.add_child(hand_container)
	phase.hand_container = hand_container
	
	var alert_banner = ColorRect.new()
	alert_banner.custom_minimum_size = Vector2(650, 50)
	alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.0)
	alert_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_inner_vbox.add_child(alert_banner)
	phase.alert_banner = alert_banner
	
	var alert_label = Label.new()
	alert_label.text = "寝落ち注意！"
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_override("font", DeskTheme.get_font())
	alert_label.add_theme_font_size_override("font_size", 20)
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_banner.add_child(alert_label)
	phase.alert_label = alert_label
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	right_inner_vbox.add_child(btn_hbox)
	
	var draw_btn = Button.new()
	draw_btn.text = "勉強カードを引く"
	draw_btn.custom_minimum_size = Vector2(260, 65)
	draw_btn.pivot_offset = Vector2(130, 32.5)
	draw_btn.z_index = 2
	draw_btn.add_theme_font_override("font", DeskTheme.get_font())
	draw_btn.add_theme_font_size_override("font_size", 24)
	draw_btn.pressed.connect(phase._on_draw_pressed)
	draw_btn.mouse_entered.connect(func():
		phase._clear_hovered_card()
		DeskTheme.animate_hover(draw_btn, true, Vector2.ONE, 0.1)
	)
	draw_btn.mouse_exited.connect(func():
		DeskTheme.animate_hover(draw_btn, false, Vector2.ONE, 0.1)
	)
	DeskTheme.apply_white_button_style(draw_btn)
	btn_hbox.add_child(draw_btn)
	phase.draw_btn = draw_btn
	
	var stop_btn = Button.new()
	stop_btn.text = "休憩する"
	stop_btn.custom_minimum_size = Vector2(260, 65)
	stop_btn.pivot_offset = Vector2(130, 32.5)
	stop_btn.z_index = 2
	stop_btn.add_theme_font_override("font", DeskTheme.get_font())
	stop_btn.add_theme_font_size_override("font_size", 24)
	stop_btn.pressed.connect(phase._on_stop_pressed)
	stop_btn.mouse_entered.connect(func():
		phase._clear_hovered_card()
		DeskTheme.animate_hover(stop_btn, true, Vector2.ONE, 0.1)
	)
	stop_btn.mouse_exited.connect(func():
		DeskTheme.animate_hover(stop_btn, false, Vector2.ONE, 0.1)
	)
	DeskTheme.apply_white_button_style(stop_btn)
	btn_hbox.add_child(stop_btn)
	phase.stop_btn = stop_btn
	
	DeskTheme.add_ruled_lines(left_page)
	DeskTheme.add_ruled_lines(right_page)
	DeskTheme.add_spiral_binding(main_hbox, 850.0)
	
	var viewport_size = phase.get_viewport_rect().size
	main_hbox.pivot_offset = main_hbox.custom_minimum_size * 0.5
	main_hbox.position = viewport_size * 0.5 - main_hbox.pivot_offset
	
	var right_free_control = Control.new()
	right_free_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_page.add_child(right_free_control)
	
	var deck_sticky = PanelContainer.new()
	deck_sticky.custom_minimum_size = Vector2(100, 75)
	deck_sticky.size = Vector2(100, 75)
	deck_sticky.position = Vector2(580, 20)
	deck_sticky.rotation_degrees = 5.0
	deck_sticky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_free_control.add_child(deck_sticky)
	phase.deck_sticky = deck_sticky
	
	var sticky_style = DeskTheme.create_sticky_note_style("yellow")
	deck_sticky.add_theme_stylebox_override("panel", sticky_style)
	
	var sticky_vbox = VBoxContainer.new()
	sticky_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sticky_vbox.add_theme_constant_override("separation", 2)
	deck_sticky.add_child(sticky_vbox)
	
	var deck_title_lbl = Label.new()
	deck_title_lbl.text = "山札残り"
	deck_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deck_title_lbl.add_theme_font_size_override("font_size", 14)
	deck_title_lbl.add_theme_color_override("font_color", Color("37474f"))
	sticky_vbox.add_child(deck_title_lbl)
	
	var deck_count_lbl = Label.new()
	deck_count_lbl.text = "0枚"
	deck_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_count_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deck_count_lbl.add_theme_font_size_override("font_size", 20)
	deck_count_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	sticky_vbox.add_child(deck_count_lbl)
	phase.deck_count_lbl = deck_count_lbl
	
	var deck_warning_lbl = Label.new()
	deck_warning_lbl.text = "残少!!"
	deck_warning_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_warning_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deck_warning_lbl.add_theme_font_size_override("font_size", 12)
	deck_warning_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	deck_warning_lbl.visible = false
	sticky_vbox.add_child(deck_warning_lbl)
	phase.deck_warning_lbl = deck_warning_lbl
	
	var opt_btn = Button.new()
	opt_btn.text = "設定/ルール"
	opt_btn.custom_minimum_size = Vector2(140, 45)
	opt_btn.add_theme_font_override("font", DeskTheme.get_font())
	opt_btn.add_theme_font_size_override("font_size", 18)
	opt_btn.pressed.connect(func():
		DeskTheme.animate_click(opt_btn, Vector2.ONE, 0.08)
		SettingsModal.create_and_show(phase)
	)
	phase.add_child(opt_btn)
	var opt_viewport_size = phase.get_viewport_rect().size
	opt_btn.position = Vector2(max(opt_viewport_size.x - opt_btn.custom_minimum_size.x - 20.0, 0.0), 20)
