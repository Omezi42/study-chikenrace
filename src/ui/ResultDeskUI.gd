class_name ResultDeskUI
extends RefCounted

static func build_desk_background(scene: ResultScene) -> void:
	# Wood desk background
	var desk_bg = ColorRect.new()
	desk_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desk_bg.color = Color("b58b66") # Warm wood base color
	scene.root_layer.add_child(desk_bg)
	
	# Wood grain
	var grain = ColorRect.new()
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.color = Color(0.2, 0.1, 0.05, 0.05)
	scene.root_layer.add_child(grain)
	
	# Vignette
	var vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.02, 0.01, 0.0, 0.2)
	scene.root_layer.add_child(vignette)

static func build_mini_scoreboard(scene: ResultScene) -> void:
	var board_panel = PanelContainer.new()
	board_panel.custom_minimum_size = Vector2(1000, 100)
	board_panel.pivot_offset = Vector2(500, 50)
	
	# Create a mini blackboard or corkboard style
	var style = StyleBoxFlat.new()
	style.bg_color = Color("1e3d2f") # Blackboard green
	style.border_color = Color("5c3f25") # Wood frame
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	board_panel.add_theme_stylebox_override("panel", style)
	
	scene.root_layer.add_child(board_panel)
	
	var vp_size = scene.get_viewport_rect().size
	if vp_size.x == 0: vp_size = Vector2(1920, 1080)
	board_panel.position = Vector2(vp_size.x / 2.0 - 500, -150) # Start hidden above
	scene.mini_scoreboard_panel = board_panel
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	board_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "累計獲得点数"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
	vbox.add_child(title)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 60)
	vbox.add_child(hbox)
	scene.mini_scoreboard_hbox = hbox

static func build_test_papers_container(scene: ResultScene) -> void:
	var container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.root_layer.add_child(container)
	scene.papers_container = container

static func build_report_envelope_container(scene: ResultScene) -> void:
	var container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.root_layer.add_child(container)
	scene.report_container = container

static func build_actions_container(scene: ResultScene) -> void:
	var container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.root_layer.add_child(container)
	scene.actions_container = container
