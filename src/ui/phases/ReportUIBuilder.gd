class_name ReportUIBuilder
extends RefCounted

static func build_layout(phase: ReportPhase) -> void:
	_build_smartphone_ui(phase)

static func _build_smartphone_ui(phase: ReportPhase) -> void:
	var target_parent = phase

	# SMARTPHONE CONTAINER (Phone UI Frame) - Modern Bezel-less Design
	var phone_panel = PanelContainer.new()
	phone_panel.custom_minimum_size = Vector2(420, 840)
	phone_panel.size = Vector2(420, 840)
	phone_panel.pivot_offset = Vector2(210, 420)
	phone_panel.clip_contents = true
	
	var phone_style = StyleBoxFlat.new()
	phone_style.bg_color = Color("#1a1a1a") # Realistic phone body (dark bezel)
	phone_style.border_color = Color("#2e2e2e") # Subtle bezel edge
	phone_style.border_width_left = 6
	phone_style.border_width_right = 6
	phone_style.border_width_top = 6
	phone_style.border_width_bottom = 6
	phone_style.corner_radius_top_left = 40
	phone_style.corner_radius_top_right = 40
	phone_style.corner_radius_bottom_left = 40
	phone_style.corner_radius_bottom_right = 40
	phone_panel.add_theme_stylebox_override("panel", phone_style)
	target_parent.add_child(phone_panel)
	
	phone_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	phone_panel.position = Vector2(750, 120)
	phase.phone_panel = phone_panel
	
	# SCREEN CONTAINER (液晶画面)
	var screen_container = PanelContainer.new()
	screen_container.name = "ScreenContainer"
	screen_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_container.clip_contents = true
	var screen_bg = StyleBoxFlat.new()
	screen_bg.bg_color = Color("#ffffff") # 白背景
	screen_bg.corner_radius_top_left = 34
	screen_bg.corner_radius_top_right = 34
	screen_bg.corner_radius_bottom_left = 34
	screen_bg.corner_radius_bottom_right = 34
	screen_container.add_theme_stylebox_override("panel", screen_bg)
	phone_panel.add_child(screen_container)

	# Notch / Dynamic Island
	var notch = Panel.new()
	notch.custom_minimum_size = Vector2(120, 24)
	notch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	notch.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var notch_style = StyleBoxFlat.new()
	notch_style.bg_color = Color("#111111")
	notch_style.corner_radius_bottom_left = 12
	notch_style.corner_radius_bottom_right = 12
	notch.add_theme_stylebox_override("panel", notch_style)
	phone_panel.add_child(notch)
	
	var phone_vbox = VBoxContainer.new()
	phone_vbox.add_theme_constant_override("separation", 0)
	screen_container.add_child(phone_vbox)
	
	# Status bar margin
	var status_margin = MarginContainer.new()
	status_margin.add_theme_constant_override("margin_top", 10)
	status_margin.add_theme_constant_override("margin_left", 24)
	status_margin.add_theme_constant_override("margin_right", 24)
	phone_vbox.add_child(status_margin)
	
	var status_bar = HBoxContainer.new()
	status_margin.add_child(status_bar)

	var time_lbl = Label.new()
	time_lbl.text = "16:00"
	time_lbl.add_theme_font_size_override("font_size", 14)
	time_lbl.add_theme_color_override("font_color", Color("#333333"))
	status_bar.add_child(time_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_bar.add_child(spacer)
	
	var app_name = Label.new()
	app_name.text = "チキスタ"
	app_name.add_theme_font_size_override("font_size", 14)
	app_name.add_theme_color_override("font_color", Color("#999999"))
	status_bar.add_child(app_name)
	
	# Header (New Post)
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_top", 20)
	header_margin.add_theme_constant_override("margin_bottom", 10)
	phone_vbox.add_child(header_margin)
	
	var header_title = Label.new()
	header_title.text = "新規投稿"
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_title.add_theme_font_override("font", DeskTheme.get_font())
	header_title.add_theme_font_size_override("font_size", 24)
	header_title.add_theme_color_override("font_color", Color("#000000"))
	header_margin.add_child(header_title)
	
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color("#e0e0e0")
	phone_vbox.add_child(sep)
	
	# App content
	var app_margin = MarginContainer.new()
	app_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_margin.add_theme_constant_override("margin_left", 20)
	app_margin.add_theme_constant_override("margin_right", 20)
	app_margin.add_theme_constant_override("margin_top", 30)
	app_margin.add_theme_constant_override("margin_bottom", 30)
	phone_vbox.add_child(app_margin)
	
	var app_vbox = VBoxContainer.new()
	app_vbox.add_theme_constant_override("separation", 30)
	app_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	app_margin.add_child(app_vbox)
	
	# Score Display Area
	var score_vbox = VBoxContainer.new()
	score_vbox.add_theme_constant_override("separation", 8)
	app_vbox.add_child(score_vbox)
	
	var decl_title = Label.new()
	decl_title.text = "シェアする点数"
	decl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decl_title.add_theme_font_override("font", DeskTheme.get_font())
	decl_title.add_theme_font_size_override("font_size", 16)
	decl_title.add_theme_color_override("font_color", Color("#999999"))
	score_vbox.add_child(decl_title)
	
	var declared_score_label = Label.new()
	declared_score_label.text = str(phase.actual_score) + "点"
	declared_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	declared_score_label.add_theme_font_override("font", DeskTheme.get_font())
	declared_score_label.add_theme_font_size_override("font_size", 80)
	# Studyplus-style: default orange accent for honest score
	declared_score_label.add_theme_color_override("font_color", Color("#ff8c00")) 
	score_vbox.add_child(declared_score_label)
	phase.declared_score_label = declared_score_label
	
	# Actual score hint
	var actual_hbox = HBoxContainer.new()
	actual_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	score_vbox.add_child(actual_hbox)
	
	var actual_val = Label.new()
	actual_val.text = "実際の点数: " + str(phase.actual_score)
	actual_val.add_theme_font_override("font", DeskTheme.get_font())
	actual_val.add_theme_font_size_override("font_size", 16)
	actual_val.add_theme_color_override("font_color", Color("#aaaaaa"))
	actual_hbox.add_child(actual_val)
	
	# Modern Slider
	var slider_vbox = VBoxContainer.new()
	app_vbox.add_child(slider_vbox)
	
	var report_slider = HSlider.new()
	report_slider.min_value = phase.actual_score
	report_slider.max_value = phase.actual_score + phase.max_bluff_limit
	report_slider.value = phase.actual_score
	report_slider.step = 1
	report_slider.custom_minimum_size = Vector2(340, 40)
	report_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color = Color("#e8e8e8") # Studyplus-style light gray track
	slider_bg.corner_radius_top_left = 20
	slider_bg.corner_radius_top_right = 20
	slider_bg.corner_radius_bottom_left = 20
	slider_bg.corner_radius_bottom_right = 20
	slider_bg.expand_margin_top = 10
	slider_bg.expand_margin_bottom = 10
	report_slider.add_theme_stylebox_override("slider", slider_bg)
	# Orange fill for slider
	var slider_fill = StyleBoxFlat.new()
	slider_fill.bg_color = Color("#ff8c00")
	slider_fill.corner_radius_top_left = 20
	slider_fill.corner_radius_top_right = 20
	slider_fill.corner_radius_bottom_left = 20
	slider_fill.corner_radius_bottom_right = 20
	slider_fill.expand_margin_top = 10
	slider_fill.expand_margin_bottom = 10
	report_slider.add_theme_stylebox_override("grabber_area", slider_fill)
	
	var grabber_icon = _create_modern_grabber()
	report_slider.add_theme_icon_override("grabber", grabber_icon)
	report_slider.add_theme_icon_override("grabber_highlight", grabber_icon)
	
	report_slider.value_changed.connect(phase._on_slider_changed)
	slider_vbox.add_child(report_slider)
	phase.report_slider = report_slider
	
	# Emote Selection
	var emote_vbox = VBoxContainer.new()
	emote_vbox.add_theme_constant_override("separation", 12)
	app_vbox.add_child(emote_vbox)
	
	var emote_title = Label.new()
	emote_title.text = "今の気分"
	emote_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emote_title.add_theme_font_override("font", DeskTheme.get_font())
	emote_title.add_theme_font_size_override("font_size", 14)
	emote_title.add_theme_color_override("font_color", Color("#999999"))
	emote_vbox.add_child(emote_title)
	
	var emote_hbox = HBoxContainer.new()
	emote_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	emote_hbox.add_theme_constant_override("separation", 16)
	emote_vbox.add_child(emote_hbox)
	
	var emotes = [
		{"key": "normal", "text": "ふつう"},
		{"key": "confident", "text": "自信あり"},
		{"key": "anxious", "text": "不安"}
	]
	
	var emote_buttons = []
	var emote_btn_style_normal = StyleBoxFlat.new()
	emote_btn_style_normal.bg_color = Color("#f5f5f5") # Studyplus-style light pill button
	emote_btn_style_normal.border_color = Color("#e0e0e0")
	emote_btn_style_normal.border_width_left = 1
	emote_btn_style_normal.border_width_right = 1
	emote_btn_style_normal.border_width_top = 1
	emote_btn_style_normal.border_width_bottom = 1
	emote_btn_style_normal.corner_radius_top_left = 20
	emote_btn_style_normal.corner_radius_top_right = 20
	emote_btn_style_normal.corner_radius_bottom_left = 20
	emote_btn_style_normal.corner_radius_bottom_right = 20
	emote_btn_style_normal.content_margin_left = 16
	emote_btn_style_normal.content_margin_right = 16
	emote_btn_style_normal.content_margin_top = 10
	emote_btn_style_normal.content_margin_bottom = 10
	
	var emote_btn_style_selected = emote_btn_style_normal.duplicate()
	emote_btn_style_selected.bg_color = Color("#ff8c00") # Studyplus-style orange selected
	emote_btn_style_selected.border_color = Color("#e07800")

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
				btn.add_theme_color_override("font_color", Color("#444444"))

	for e in emotes:
		var btn = Button.new()
		btn.text = e["text"]
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", 14)
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
	
	# Warning Panel
	var warning_panel = PanelContainer.new()
	var warn_style = StyleBoxFlat.new()
	warn_style.bg_color = Color("#fff3e0") # Studyplus-style warm orange warning bg
	warn_style.border_color = Color("#ff8c00")
	warn_style.border_width_left = 3
	warn_style.border_width_right = 1
	warn_style.border_width_top = 1
	warn_style.border_width_bottom = 1
	warn_style.corner_radius_top_left = 12
	warn_style.corner_radius_top_right = 12
	warn_style.corner_radius_bottom_left = 12
	warn_style.corner_radius_bottom_right = 12
	warning_panel.add_theme_stylebox_override("panel", warn_style)
	app_vbox.add_child(warning_panel)
	phase.warning_panel = warning_panel
	
	var warn_margin = MarginContainer.new()
	warn_margin.add_theme_constant_override("margin_left", 16)
	warn_margin.add_theme_constant_override("margin_right", 16)
	warn_margin.add_theme_constant_override("margin_top", 12)
	warn_margin.add_theme_constant_override("margin_bottom", 12)
	warning_panel.add_child(warn_margin)
	
	var warning_text = Label.new()
	warning_text.text = "申告が実点を超えています。ダウトされる危険性があります！"
	warning_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_text.add_theme_font_override("font", DeskTheme.get_font())
	warning_text.add_theme_font_size_override("font_size", 13)
	warning_text.add_theme_color_override("font_color", Color("#e65100"))
	warn_margin.add_child(warning_text)
	phase.warning_text = warning_text
	
	warning_panel.visible = false
	
	# Submit button
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_vbox.add_child(spacer2)

	var submit_btn = Button.new()
	submit_btn.text = "フィードにシェア"
	submit_btn.custom_minimum_size = Vector2(340, 56)
	submit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	submit_btn.add_theme_font_override("font", DeskTheme.get_font())
	submit_btn.add_theme_font_size_override("font_size", 18)
	
	var submit_style = StyleBoxFlat.new()
	submit_style.bg_color = Color("#ff8c00") # Studyplus-style orange CTA button
	submit_style.shadow_color = Color("#e07800", 0.4)
	submit_style.shadow_size = 6
	submit_style.shadow_offset = Vector2(0, 3)
	submit_style.corner_radius_top_left = 28
	submit_style.corner_radius_top_right = 28
	submit_style.corner_radius_bottom_left = 28
	submit_style.corner_radius_bottom_right = 28
	submit_btn.add_theme_stylebox_override("normal", submit_style)
	submit_btn.add_theme_stylebox_override("hover", submit_style)
	submit_btn.add_theme_stylebox_override("pressed", submit_style)
	submit_btn.add_theme_color_override("font_color", Color.WHITE)
	
	submit_btn.pressed.connect(phase._on_submit_pressed)
	phase.submit_btn = submit_btn
	
	app_vbox.add_child(submit_btn)
	
	# Entrance slide-in
	DeskTheme.animate_entrance(phone_panel, phone_panel.position, Vector2(0, 300), 0.5)

static func _create_modern_grabber() -> ImageTexture:
	var img = Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	# Draw a white circle
	for x in range(32):
		for y in range(32):
			var dist = Vector2(x - 16, y - 16).length()
			if dist <= 14:
				img.set_pixel(x, y, Color.WHITE)
			elif dist <= 16:
				img.set_pixel(x, y, Color(1, 1, 1, 1.0 - (dist - 14)/2.0))
	return ImageTexture.create_from_image(img)

static func show_stamp_animation(phase: ReportPhase) -> void:
	# Change from stamp to modern "Posted" checkmark popup
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(160, 160)
	
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color("#ffffff") # Studyplus-style white popup
	p_style.border_color = Color("#ff8c00")
	p_style.border_width_left = 2
	p_style.border_width_right = 2
	p_style.border_width_top = 2
	p_style.border_width_bottom = 2
	p_style.corner_radius_top_left = 24
	p_style.corner_radius_top_right = 24
	p_style.corner_radius_bottom_left = 24
	p_style.corner_radius_bottom_right = 24
	p_style.shadow_color = Color(0, 0, 0, 0.18)
	p_style.shadow_size = 16
	p_style.shadow_offset = Vector2(0, 6)
	popup.add_theme_stylebox_override("panel", p_style)
	phase.phone_panel.add_child(popup)
	
	popup.pivot_offset = Vector2(80, 80)
	popup.position = Vector2(210 - 80, 420 - 80)
	
	var p_vbox = VBoxContainer.new()
	p_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	p_vbox.add_theme_constant_override("separation", 10)
	popup.add_child(p_vbox)
	
	var check = Label.new()
	check.text = "OK"
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check.add_theme_font_size_override("font_size", 64)
	check.add_theme_color_override("font_color", Color("#ff8c00")) # Orange checkmark
	p_vbox.add_child(check)
	
	var lbl = Label.new()
	lbl.text = "シェア完了"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", DeskTheme.get_font())
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color("#1a1a1a"))
	p_vbox.add_child(lbl)
	
	popup.scale = Vector2(0.8, 0.8)
	popup.modulate.a = 0.0
	
	var tween = phase.create_tween()
	tween.parallel().tween_property(popup, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "modulate:a", 1.0, 0.2)
	
	if phase.has_node("/root/AudioManager"):
		phase.get_node("/root/AudioManager").play_se(AudioManager.SE_PLACE)

