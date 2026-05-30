class_name ReportPhase
extends PhaseBase

# UI Controls
var actual_info_label: Label
var report_slider: HSlider
var declared_score_label: Label
var warning_panel: PanelContainer
var warning_text: Label
var submit_btn: Button
var phone_panel: PanelContainer

# Daily state
var actual_score: int = 0
var max_bluff_limit: int = 24

func _on_setup(setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(550, 780)
	size = Vector2(550, 780)
	actual_score = setup_data.get("actual_score", 0)
	
	# Determine player's active bluff limit based on slotted items
	max_bluff_limit = 24
	for slot in Global.current_deck.keys():
		var item = Global.current_deck[slot]
		if item == "item_cheat_sheet":
			max_bluff_limit += 16
		elif item == "item_copy_answer":
			max_bluff_limit += 25
			
	# SMARTPHONE CONTAINER (Phone UI Frame) - Centered
	phone_panel = PanelContainer.new()
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
	add_child(phone_panel)
	fit_control_to_viewport(phone_panel, Vector2(550, 780), Vector2(72, 72), 0.76, true)
	
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
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_vbox.add_child(title)
	
	# Honest actual score display
	var actual_hbox = HBoxContainer.new()
	actual_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_child(actual_hbox)
	
	var actual_title = Label.new()
	actual_title.text = "実際の実点（正直）： "
	actual_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	actual_title.add_theme_font_size_override("font_size", 18)
	actual_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	actual_hbox.add_child(actual_title)
	
	var actual_val = Label.new()
	actual_val.text = str(actual_score) + " 点"
	actual_val.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	actual_val.add_theme_font_size_override("font_size", 22)
	actual_val.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	actual_hbox.add_child(actual_val)
	
	# Declared Score header
	var decl_title = Label.new()
	decl_title.text = "投稿する申告点数："
	decl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decl_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	decl_title.add_theme_font_size_override("font_size", 18)
	decl_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	card_vbox.add_child(decl_title)
	
	declared_score_label = Label.new()
	declared_score_label.text = str(actual_score) + "点"
	declared_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	declared_score_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	declared_score_label.add_theme_font_size_override("font_size", 54)
	declared_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	card_vbox.add_child(declared_score_label)
	
	# Slider inside card
	report_slider = HSlider.new()
	report_slider.min_value = actual_score
	report_slider.max_value = actual_score + max_bluff_limit
	report_slider.value = actual_score
	report_slider.step = 1
	report_slider.custom_minimum_size = Vector2(400, 45)
	report_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	report_slider.value_changed.connect(_on_slider_changed)
	card_vbox.add_child(report_slider)
	
	# Warning Panel inside card
	warning_panel = PanelContainer.new()
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
	
	var warn_margin = MarginContainer.new()
	warn_margin.add_theme_constant_override("margin_left", 12)
	warn_margin.add_theme_constant_override("margin_right", 12)
	warn_margin.add_theme_constant_override("margin_top", 8)
	warn_margin.add_theme_constant_override("margin_bottom", 8)
	warning_panel.add_child(warn_margin)
	
	warning_text = Label.new()
	warning_text.text = "⚠️ 申告が実点を超えています！ダウトされる危険性があります。"
	warning_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_text.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	warning_text.add_theme_font_size_override("font_size", 14)
	warning_text.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	warn_margin.add_child(warning_text)
	
	warning_panel.visible = false
	
	# Submit button inside phone app (under the card)
	submit_btn = Button.new()
	submit_btn.text = "タイムラインに投稿"
	submit_btn.custom_minimum_size = Vector2(400, 60)
	submit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	submit_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	submit_btn.add_theme_font_size_override("font_size", 22)
	submit_btn.pressed.connect(_on_submit_pressed)
	
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
	
	if Global.is_tutorial_mode and session.current_day == 1:
		show_tutorial_dialog(
			"チキスタ投稿フェーズです！\n\n一日の終わりに勉強成果を勉強SNS『チキスタ』に投稿します。実際より高い点数を申告してブラフ（嘘）をつくこともできます！\n\nスライダーを少し右に動かして、実点（%d点）より高い点数を申告してみましょう！" % actual_score,
		)

func _on_slider_changed(val: float) -> void:
	var rounded_val = int(val)
	declared_score_label.text = str(rounded_val) + "点"
	
	if rounded_val > actual_score:
		declared_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		warning_panel.visible = true
		DeskTheme.animate_click(declared_score_label, Vector2.ONE, 0.06)
	else:
		declared_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		warning_panel.visible = false

func _on_submit_pressed() -> void:
	DeskTheme.animate_click(submit_btn, Vector2.ONE, 0.08)
	submit_btn.disabled = true
	report_slider.editable = false
	
	var final_declared = int(report_slider.value)
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_se(AudioManager.SE_PLACE)
		session.submit_player_declaration(final_declared)
		finish_phase({
			"declared_score": final_declared
		})
	)
