class_name ResultBoardUI
extends RefCounted

static func build_background(scene: ResultScene) -> void:
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("214b3b")
	scene.root_layer.add_child(bg)

	var board_frame = ColorRect.new()
	board_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_frame.color = Color("7a5633")
	board_frame.modulate.a = 0.95
	scene.root_layer.add_child(board_frame)
	scene.board_frame = board_frame

	var board_inner = ColorRect.new()
	board_inner.color = Color("1f4d3a")
	board_inner.modulate.a = 0.98
	scene.root_layer.add_child(board_inner)
	scene.board_inner = board_inner

	var grain = ColorRect.new()
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.color = Color(0.95, 0.85, 0.65, 0.06)
	scene.root_layer.add_child(grain)

	var vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.03, 0.02, 0.01, 0.22)
	scene.root_layer.add_child(vignette)

static func build_blackboard(scene: ResultScene) -> void:
	var blackboard_panel = PanelContainer.new()
	blackboard_panel.custom_minimum_size = Vector2(1480, 760)
	
	var board_style = StyleBoxFlat.new()
	board_style.bg_color = Color("f7f2e8")
	board_style.border_color = Color("b59d7a")
	board_style.border_width_left = 5
	board_style.border_width_right = 5
	board_style.border_width_top = 5
	board_style.border_width_bottom = 5
	board_style.corner_radius_top_left = 14
	board_style.corner_radius_top_right = 14
	board_style.corner_radius_bottom_left = 14
	board_style.corner_radius_bottom_right = 14
	board_style.shadow_color = Color(0, 0, 0, 0.18)
	board_style.shadow_size = 16
	board_style.shadow_offset = Vector2(6, 8)
	blackboard_panel.add_theme_stylebox_override("panel", board_style)
	scene.root_layer.add_child(blackboard_panel)
	blackboard_panel.pivot_offset = blackboard_panel.custom_minimum_size * 0.5
	blackboard_panel.position = scene.get_viewport_rect().size * 0.5 - blackboard_panel.custom_minimum_size * 0.5
	scene.blackboard_panel = blackboard_panel
	
	var board_margin = MarginContainer.new()
	board_margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_DEFAULT)
	board_margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_DEFAULT)
	blackboard_panel.add_child(board_margin)
	
	var blackboard_vbox = VBoxContainer.new()
	blackboard_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL)
	board_margin.add_child(blackboard_vbox)
	scene.blackboard_vbox = blackboard_vbox
	
	var scorecard_label = Label.new()
	scorecard_label.text = "学末最終成績通知表"
	scorecard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scorecard_label.add_theme_font_override("font", DeskTheme.get_font())
	scorecard_label.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE_LARGE)
	scorecard_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	blackboard_vbox.add_child(scorecard_label)
	scene.scorecard_label = scorecard_label

	var chart_title = Label.new()
	chart_title.text = "累計獲得点数"
	chart_title.add_theme_font_override("font", DeskTheme.get_font())
	chart_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	chart_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	blackboard_vbox.add_child(chart_title)
	scene.chart_title = chart_title

	var day_chart_area = Control.new()
	day_chart_area.custom_minimum_size = Vector2(1320, 180)
	blackboard_vbox.add_child(day_chart_area)
	scene.day_chart_area = day_chart_area
