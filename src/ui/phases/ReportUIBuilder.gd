class_name ReportUIBuilder
extends RefCounted

static func build_layout(phase: ReportPhase) -> void:
	# SMARTPHONE CONTAINER (Phone UI Frame) - Centered
	var phone_panel = PanelContainer.new()
	phone_panel.custom_minimum_size = Vector2(550, 780)
	phone_panel.size = Vector2(550, 780)
	phone_panel.pivot_offset = Vector2(275, 390)
	
	var phone_style = StyleBoxFlat.new()
	phone_style.bg_color = DeskTheme.COLOR_INK
	phone_style.border_color = Color("37474f")
	phone_style.border_width_left = 16
	phone_style.border_width_right = 16
	phone_style.border_width_top = 32
	phone_style.border_width_bottom = 32
	phone_style.corner_radius_top_left = 28
	phone_style.corner_radius_top_right = 28
	phone_style.corner_radius_bottom_left = 28
	phone_style.corner_radius_bottom_right = 28
	phone_panel.add_theme_stylebox_override("panel", phone_style)
	phase.add_child(phone_panel)
	phase.phone_panel = phone_panel
	phase.fit_control_to_viewport(phone_panel, Vector2(550, 780), Vector2(72, 72), 0.76, true)
	
	# Inside Phone VBox
	var phone_vbox = VBoxContainer.new()
	phone_vbox.add_theme_constant_override("separation", 10)
	phone_panel.add_child(phone_vbox)
	
	# Status bar
	var status_bar = Label.new()
	status_bar.text = "16:00  |  チキスタ投稿"
	status_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_bar.add_theme_font_size_override("font_size", 16)
	status_bar.add_theme_color_override("font_color", Color.WHITE)
	phone_vbox.add_child(status_bar)
	
	# App content (Margin Container for padding inside phone screen)
	var app_margin = MarginContainer.new()
	app_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_margin.add_theme_constant_override("margin_left", 20)
	app_margin.add_theme_constant_override("margin_right", 20)
	app_margin.add_theme_constant_override("margin_top", 15)
	app_margin.add_theme_constant_override("margin_bottom", 15)
	phone_vbox.add_child(app_margin)
	
	# App Main Body VBox
	var app_vbox = VBoxContainer.new()
	app_vbox.add_theme_constant_override("separation", 24)
	app_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	app_margin.add_child(app_vbox)
	
	# Post Card container
	var post_card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = DeskTheme.COLOR_CRAFT
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.border_color = Color("cfd8dc")
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	post_card.add_theme_stylebox_override("panel", card_style)
	app_vbox.add_child(post_card)
	
	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 20)
	card_margin.add_theme_constant_override("margin_right", 20)
	card_margin.add_theme_constant_override("margin_top", 20)
	card_margin.add_theme_constant_override("margin_bottom", 20)
	post_card.add_child(card_margin)
	
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 18)
	card_margin.add_child(card_vbox)
	
	# App Title inside Card
	var title = Label.new()
	title.text = "今日の勉強報告"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_vbox.add_child(title)
	
	# Honest actual score display
	var actual_hbox = HBoxContainer.new()
	actual_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_child(actual_hbox)
	
	var actual_title = Label.new()
	actual_title.text = "実際の実点（正直）： "
	actual_title.add_theme_font_override("font", DeskTheme.get_font())
	actual_title.add_theme_font_size_override("font_size", 18)
	actual_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	actual_hbox.add_child(actual_title)
	
	var actual_val = Label.new()
	actual_val.text = str(phase.actual_score) + " 点"
	actual_val.add_theme_font_override("font", DeskTheme.get_font())
	actual_val.add_theme_font_size_override("font_size", 22)
	actual_val.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	actual_hbox.add_child(actual_val)
	
	# Declared Score header
	var decl_title = Label.new()
	decl_title.text = "投稿する申告点数："
	decl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decl_title.add_theme_font_override("font", DeskTheme.get_font())
	decl_title.add_theme_font_size_override("font_size", 18)
	decl_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	card_vbox.add_child(decl_title)
	
	var declared_score_label = Label.new()
	declared_score_label.text = str(phase.actual_score) + "点"
	declared_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	declared_score_label.add_theme_font_override("font", DeskTheme.get_font())
	declared_score_label.add_theme_font_size_override("font_size", 54)
	declared_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	card_vbox.add_child(declared_score_label)
	phase.declared_score_label = declared_score_label
	
	# Slider inside card
	var report_slider = HSlider.new()
	report_slider.min_value = phase.actual_score
	report_slider.max_value = phase.actual_score + phase.max_bluff_limit
	report_slider.value = phase.actual_score
	report_slider.step = 1
	report_slider.custom_minimum_size = Vector2(400, 45)
	report_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	report_slider.value_changed.connect(phase._on_slider_changed)
	card_vbox.add_child(report_slider)
	phase.report_slider = report_slider

	# Emote Selection HBox inside card
	var emote_title = Label.new()
	emote_title.text = "表情（ポーカーフェイス）："
	emote_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emote_title.add_theme_font_override("font", DeskTheme.get_font())
	emote_title.add_theme_font_size_override("font_size", 16)
	emote_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	card_vbox.add_child(emote_title)

	var emote_hbox = HBoxContainer.new()
	emote_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	emote_hbox.add_theme_constant_override("separation", 16)
	card_vbox.add_child(emote_hbox)

	var emotes = [
		{"key": "normal", "text": "[普通]"},
		{"key": "confident", "text": "[自信あり]"},
		{"key": "anxious", "text": "[不安]"}
	]
	
	var emote_buttons = []

	var emote_btn_style_normal = StyleBoxFlat.new()
	emote_btn_style_normal.bg_color = Color("eceff1")
	emote_btn_style_normal.corner_radius_top_left = 6
	emote_btn_style_normal.corner_radius_top_right = 6
	emote_btn_style_normal.corner_radius_bottom_left = 6
	emote_btn_style_normal.corner_radius_bottom_right = 6
	emote_btn_style_normal.content_margin_left = 12
	emote_btn_style_normal.content_margin_right = 12
	emote_btn_style_normal.content_margin_top = 6
	emote_btn_style_normal.content_margin_bottom = 6

	var emote_btn_style_selected = StyleBoxFlat.new()
	emote_btn_style_selected.bg_color = Color("1e88e5") # Active blue
	emote_btn_style_selected.corner_radius_top_left = 6
	emote_btn_style_selected.corner_radius_top_right = 6
	emote_btn_style_selected.corner_radius_bottom_left = 6
	emote_btn_style_selected.corner_radius_bottom_right = 6
	emote_btn_style_selected.content_margin_left = 12
	emote_btn_style_selected.content_margin_right = 12
	emote_btn_style_selected.content_margin_top = 6
	emote_btn_style_selected.content_margin_bottom = 6

	var update_emote_buttons = func():
		for btn_data in emote_buttons:
			var btn = btn_data["btn"]
			var key = btn_data["key"]
			if key == phase.selected_emote:
				btn.add_theme_stylebox_override("normal", emote_btn_style_selected)
				btn.add_theme_stylebox_override("hover", emote_btn_style_selected)
				btn.add_theme_stylebox_override("pressed", emote_btn_style_selected)
				btn.add_theme_color_override("font_color", Color.WHITE)
			else:
				btn.add_theme_stylebox_override("normal", emote_btn_style_normal)
				btn.add_theme_stylebox_override("hover", emote_btn_style_normal)
				btn.add_theme_stylebox_override("pressed", emote_btn_style_normal)
				btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)

	for e in emotes:
		var btn = Button.new()
		btn.text = e["text"]
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", 16)
		emote_hbox.add_child(btn)
		
		var key = e["key"]
		btn.pressed.connect(func():
			phase.selected_emote = key
			update_emote_buttons.call()
			if phase.has_node("/root/AudioManager"):
				phase.get_node("/root/AudioManager").play_se(AudioManager.SE_CLICK)
		)
		emote_buttons.append({"key": key, "btn": btn})
		
	update_emote_buttons.call()
	
	# Warning Panel inside card
	var warning_panel = PanelContainer.new()
	var warn_style = StyleBoxFlat.new()
	warn_style.bg_color = Color(DeskTheme.COLOR_TENSION, 0.1)
	warn_style.border_color = DeskTheme.COLOR_TENSION
	warn_style.border_width_left = 2
	warn_style.border_width_right = 2
	warn_style.border_width_top = 2
	warn_style.border_width_bottom = 2
	warn_style.corner_radius_top_left = 6
	warn_style.corner_radius_top_right = 6
	warn_style.corner_radius_bottom_left = 6
	warn_style.corner_radius_bottom_right = 6
	warning_panel.add_theme_stylebox_override("panel", warn_style)
	card_vbox.add_child(warning_panel)
	phase.warning_panel = warning_panel
	
	var warn_margin = MarginContainer.new()
	warn_margin.add_theme_constant_override("margin_left", 12)
	warn_margin.add_theme_constant_override("margin_right", 12)
	warn_margin.add_theme_constant_override("margin_top", 8)
	warn_margin.add_theme_constant_override("margin_bottom", 8)
	warning_panel.add_child(warn_margin)
	
	var warning_text = Label.new()
	warning_text.text = "[注意] 申告が実点を超えています！ダウトされる危険性があります。"
	warning_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_text.add_theme_font_override("font", DeskTheme.get_font())
	warning_text.add_theme_font_size_override("font_size", 14)
	warning_text.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	warn_margin.add_child(warning_text)
	phase.warning_text = warning_text
	
	warning_panel.visible = false
	
	# Submit button inside phone app (under the card)
	var submit_btn = Button.new()
	submit_btn.text = "タイムラインに投稿"
	submit_btn.custom_minimum_size = Vector2(400, 60)
	submit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	submit_btn.add_theme_font_override("font", DeskTheme.get_font())
	submit_btn.add_theme_font_size_override("font_size", 22)
	submit_btn.pressed.connect(phase._on_submit_pressed)
	phase.submit_btn = submit_btn
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color("1e88e5") # Blue app button
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	submit_btn.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover = btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color("1565c0")
	submit_btn.add_theme_stylebox_override("hover", btn_hover)
	submit_btn.add_theme_stylebox_override("pressed", btn_hover)
	
	app_vbox.add_child(submit_btn)
	
	# Entrance slide-in on phone_panel
	DeskTheme.animate_entrance(phone_panel, phone_panel.position, Vector2(0, 300), 0.5)

static func show_stamp_animation(phase: ReportPhase) -> void:
	var stamp = PanelContainer.new()
	stamp.custom_minimum_size = Vector2(160, 90)
	stamp.size = Vector2(160, 90)
	phase.phone_panel.add_child(stamp)
	
	stamp.pivot_offset = Vector2(80, 45)
	stamp.position = Vector2(275 - 80, 390 - 45)
	stamp.rotation_degrees = -15.0
	
	var stamp_style = StyleBoxFlat.new()
	stamp_style.bg_color = Color(1.0, 0.9, 0.9, 0.85) # Semi-transparent light red
	stamp_style.border_color = Color("d32f2f") # Red stamp ink
	stamp_style.border_width_left = 4
	stamp_style.border_width_right = 4
	stamp_style.border_width_top = 4
	stamp_style.border_width_bottom = 4
	stamp_style.corner_radius_top_left = 8
	stamp_style.corner_radius_top_right = 8
	stamp_style.corner_radius_bottom_left = 8
	stamp_style.corner_radius_bottom_right = 8
	stamp.add_theme_stylebox_override("panel", stamp_style)
	
	var stamp_vbox = VBoxContainer.new()
	stamp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stamp_vbox.add_theme_constant_override("separation", 2)
	stamp.add_child(stamp_vbox)
	
	var stamp_circle = Label.new()
	stamp_circle.text = "[提出済]"
	stamp_circle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_circle.add_theme_font_override("font", DeskTheme.get_font())
	stamp_circle.add_theme_font_size_override("font_size", 22)
	stamp_circle.add_theme_color_override("font_color", Color("d32f2f"))
	stamp_vbox.add_child(stamp_circle)
	
	var stamp_date = Label.new()
	stamp_date.text = "合格印"
	stamp_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_date.add_theme_font_override("font", DeskTheme.get_font())
	stamp_date.add_theme_font_size_override("font_size", 14)
	stamp_date.add_theme_color_override("font_color", Color("d32f2f", 0.7))
	stamp_vbox.add_child(stamp_date)
	
	# Scale animation
	stamp.scale = Vector2(2.5, 2.5)
	stamp.modulate.a = 0.0
	
	var tween = phase.create_tween()
	tween.parallel().tween_property(stamp, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(stamp, "modulate:a", 1.0, 0.15)
	
	# Sound effect and screen shake
	if phase.has_node("/root/AudioManager"):
		phase.get_node("/root/AudioManager").play_se(AudioManager.SE_PLACE)
	
	DeskTheme.shake_control(phase.phone_panel, 8.0, 0.15)
