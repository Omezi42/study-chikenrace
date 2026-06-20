class_name ResultReportUI
extends RefCounted

static func build_report_notebook(scene: ResultScene) -> void:
	var report_notebook = PanelContainer.new()
	report_notebook.custom_minimum_size = Vector2(1400, 500)
	report_notebook.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	scene.root_layer.add_child(report_notebook)
	report_notebook.pivot_offset = report_notebook.custom_minimum_size * 0.5
	report_notebook.position = scene.get_viewport_rect().size * 0.5 - report_notebook.custom_minimum_size * 0.5
	report_notebook.visible = false
	scene.report_notebook = report_notebook
	
	var note_hbox = HBoxContainer.new()
	note_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	note_hbox.add_theme_constant_override("separation", 40)
	report_notebook.add_child(note_hbox)
	
	var left_p = MarginContainer.new()
	left_p.add_theme_constant_override("margin_left", DeskTheme.MARGIN_SMALL)
	left_p.add_theme_constant_override("margin_right", DeskTheme.MARGIN_SMALL)
	left_p.add_theme_constant_override("margin_top", 10)
	left_p.add_theme_constant_override("margin_bottom", 10)
	note_hbox.add_child(left_p)
	
	var report_left_page = VBoxContainer.new()
	report_left_page.custom_minimum_size = Vector2(580, 0)
	report_left_page.add_theme_constant_override("separation", 8)
	left_p.add_child(report_left_page)
	scene.report_left_page = report_left_page
	
	var right_p = MarginContainer.new()
	right_p.add_theme_constant_override("margin_left", DeskTheme.MARGIN_SMALL)
	right_p.add_theme_constant_override("margin_right", DeskTheme.MARGIN_SMALL)
	right_p.add_theme_constant_override("margin_top", 10)
	right_p.add_theme_constant_override("margin_bottom", 10)
	note_hbox.add_child(right_p)
	
	var report_right_page = VBoxContainer.new()
	report_right_page.custom_minimum_size = Vector2(580, 0)
	report_right_page.add_theme_constant_override("separation", 8)
	right_p.add_child(report_right_page)
	scene.report_right_page = report_right_page
	
	var skip_btn = Button.new()
	skip_btn.add_to_group("important_button")
	skip_btn.text = "結果へスキップ >>"
	skip_btn.custom_minimum_size = Vector2(240, 60)
	skip_btn.add_theme_font_override("font", DeskTheme.get_font())
	skip_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	skip_btn.pressed.connect(scene._on_skip_pressed)
	
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color(DeskTheme.COLOR_MAHOGANY, 0.8)
	skip_style.corner_radius_top_left = 6
	skip_style.corner_radius_top_right = 6
	skip_style.corner_radius_bottom_left = 6
	skip_style.corner_radius_bottom_right = 6
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	skip_btn.add_theme_stylebox_override("hover", skip_style)
	skip_btn.add_theme_stylebox_override("pressed", skip_style)
	
	scene.root_layer.add_child(skip_btn)
	scene.skip_btn = skip_btn
