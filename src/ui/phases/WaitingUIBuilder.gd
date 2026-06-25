class_name WaitingUIBuilder
extends RefCounted

static func build_layout(phase: WaitingPhase) -> void:
	# Layout: Centered smartphone container
	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	phase.add_child(main_hbox)
	phase.fit_control_to_viewport(main_hbox, Vector2(1500, 850), Vector2(72, 72), 0.72, true)

	# SMARTPHONE PANEL
	var phone_panel = PanelContainer.new()
	phone_panel.custom_minimum_size = Vector2(550, 780)
	phone_panel.pivot_offset = Vector2(275, 390)

	var phone_style = StyleBoxFlat.new()
	phone_style.bg_color = DeskTheme.COLOR_INK # Dark phone body (realistic bezel)
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
	main_hbox.add_child(phone_panel)
	phase.phone_panel = phone_panel

	var phone_vbox = VBoxContainer.new()
	phone_vbox.add_theme_constant_override("separation", 24)
	phone_panel.add_child(phone_vbox)

	# Status bar
	var status_bar = Label.new()
	status_bar.text = "16:30  |  チキスタ同期中"
	status_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_bar.add_theme_font_size_override("font_size", 16)
	status_bar.add_theme_color_override("font_color", Color("#cccccc")) # Light text on dark phone body
	phone_vbox.add_child(status_bar)

	# Card inside phone (Studyplus-style light app screen)
	var app_card = PanelContainer.new()
	app_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var app_style = StyleBoxFlat.new()
	app_style.bg_color = Color("#ffffff") # Studyplus-style white app screen
	app_style.corner_radius_top_left = 8
	app_style.corner_radius_top_right = 8
	app_style.corner_radius_bottom_left = 8
	app_style.corner_radius_bottom_right = 8
	app_card.add_theme_stylebox_override("panel", app_style)
	phone_vbox.add_child(app_card)

	var app_margin = MarginContainer.new()
	app_margin.add_theme_constant_override("margin_left", 24)
	app_margin.add_theme_constant_override("margin_right", 24)
	app_margin.add_theme_constant_override("margin_top", 30)
	app_margin.add_theme_constant_override("margin_bottom", 30)
	app_card.add_child(app_margin)

	var app_vbox = VBoxContainer.new()
	app_vbox.add_theme_constant_override("separation", 28)
	app_margin.add_child(app_vbox)
	phase.app_vbox = app_vbox

	# Icon indicator (Rotating study-gear/sync icon or pulsating text)
	var indicator_container = CenterContainer.new()
	indicator_container.custom_minimum_size = Vector2(0, 100)
	app_vbox.add_child(indicator_container)

	var loading_rect = ColorRect.new()
	loading_rect.color = Color("#ff8c00") # Studyplus-style orange loading spinner
	loading_rect.custom_minimum_size = Vector2(40, 40)
	loading_rect.pivot_offset = Vector2(20, 20)
	indicator_container.add_child(loading_rect)
	phase.loading_rect = loading_rect

	# Rotating animation for loading indicator
	var rot_tween = phase.create_tween().set_loops().set_trans(Tween.TRANS_LINEAR)
	rot_tween.tween_property(loading_rect, "rotation_degrees", 360.0, 1.8)

	# Status message
	var status_lbl = Label.new()
	status_lbl.text = "他のメンバーの報告を待っています..." if not phase.is_final_reveal_wait else "最終結果を集計しています..."
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_override("font", DeskTheme.get_font())
	status_lbl.add_theme_font_size_override("font_size", 24)
	status_lbl.add_theme_color_override("font_color", Color("#333333")) # Studyplus-style dark ink on white
	app_vbox.add_child(status_lbl)
	phase.status_lbl = status_lbl

	# Separation line
	var line_ctrl = Control.new()
	line_ctrl.custom_minimum_size = Vector2(0, 2)
	var line_rect = ColorRect.new()
	line_rect.color = Color("#e0e0e0") # Studyplus-style light separator
	line_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line_ctrl.add_child(line_rect)
	app_vbox.add_child(line_ctrl)

	# Title for list
	var list_title = Label.new()
	list_title.text = "ルームメンバー (Day %d)" % phase.target_day
	list_title.add_theme_font_override("font", DeskTheme.get_font())
	list_title.add_theme_font_size_override("font_size", 20)
	list_title.add_theme_color_override("font_color", Color("#999999")) # Studyplus-style muted label
	app_vbox.add_child(list_title)

	# Members list Container
	var members_vbox = VBoxContainer.new()
	members_vbox.add_theme_constant_override("separation", 14)
	app_vbox.add_child(members_vbox)
	phase.members_vbox = members_vbox

	# Visual entrance slide in
	DeskTheme.animate_entrance(phone_panel, phone_panel.position, Vector2(0, 300), 0.5)

static func build_member_row(phase: WaitingPhase, name_str: String, status_text: String, status_color: Color) -> void:
	var row = PanelContainer.new()
	var row_style = StyleBoxFlat.new()
	row_style.bg_color = Color.WHITE
	row_style.corner_radius_top_left = 6
	row_style.corner_radius_top_right = 6
	row_style.corner_radius_bottom_left = 6
	row_style.corner_radius_bottom_right = 6
	row_style.content_margin_left = 12
	row_style.content_margin_right = 12
	row_style.content_margin_top = 8
	row_style.content_margin_bottom = 8
	row_style.border_color = Color(DeskTheme.COLOR_INK, 0.1)
	row_style.border_width_bottom = 2
	row.add_theme_stylebox_override("panel", row_style)
	phase.members_vbox.add_child(row)

	var hbox = HBoxContainer.new()
	row.add_child(hbox)

	var name_lbl = Label.new()
	name_lbl.text = name_str
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	hbox.add_child(name_lbl)

	var stat_lbl = Label.new()
	stat_lbl.text = status_text
	stat_lbl.add_theme_font_override("font", DeskTheme.get_font())
	stat_lbl.add_theme_font_size_override("font_size", 18)
	stat_lbl.add_theme_color_override("font_color", status_color)
	hbox.add_child(stat_lbl)

static func show_timeout_fallback_buttons(phase: WaitingPhase) -> void:
	var btn_name = "TimeoutFallbackButton"
	if phase.app_vbox.has_node(btn_name):
		return

	if Global.friend_is_host:
		var force_btn = Button.new()
		force_btn.name = "ForceProgressButton"
		force_btn.text = "強制進行 (未提出は0点)"
		force_btn.custom_minimum_size = Vector2(280, 50)
		force_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		force_btn.add_theme_font_override("font", DeskTheme.get_font())
		force_btn.add_theme_font_size_override("font_size", 18)
		Global.apply_white_button_style(force_btn)
		force_btn.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		force_btn.pressed.connect(func():
			phase._on_force_progress_pressed(phase.last_polled_moves)
		)
		phase.app_vbox.add_child(force_btn)
	else:
		var cpu_switch_btn = Button.new()
		cpu_switch_btn.name = "CpuSwitchButton"
		cpu_switch_btn.text = "CPU代替戦で続行"
		cpu_switch_btn.custom_minimum_size = Vector2(280, 50)
		cpu_switch_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cpu_switch_btn.add_theme_font_override("font", DeskTheme.get_font())
		cpu_switch_btn.add_theme_font_size_override("font_size", 18)
		Global.apply_white_button_style(cpu_switch_btn)
		cpu_switch_btn.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		cpu_switch_btn.pressed.connect(func():
			phase._on_switch_to_cpu_pressed()
		)
		phase.app_vbox.add_child(cpu_switch_btn)

	var fallback_btn = Button.new()
	fallback_btn.name = btn_name
	fallback_btn.text = "タイトルに戻る"
	fallback_btn.custom_minimum_size = Vector2(280, 50)
	fallback_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fallback_btn.add_theme_font_override("font", DeskTheme.get_font())
	fallback_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(fallback_btn)
	fallback_btn.pressed.connect(func():
		var tree = phase.get_tree()
		if tree and tree.root.has_node("WebRTCManager"):
			tree.root.get_node("WebRTCManager").disconnect_room()
		Global.change_scene_with_fade(tree, "res://Title.tscn")
	)
	phase.app_vbox.add_child(fallback_btn)
