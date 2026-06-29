class_name DayTransitionPhase
extends PhaseBase

# UI Controls
var calendar_panel: PanelContainer
var day_label: Label

func _on_setup(_setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(800, 550)
	size = Vector2(800, 550)
	
	# Programmatic Calendar styling
	calendar_panel = PanelContainer.new()
	calendar_panel.custom_minimum_size = Vector2(400, 400)
	calendar_panel.size = Vector2(400, 400)
	calendar_panel.pivot_offset = Vector2(200, 200)
	
	# Red metal binding top, white page below
	var cal_style = StyleBoxFlat.new()
	cal_style.bg_color = Color.WHITE
	cal_style.border_color = Color("c62828") # Dark red binding
	cal_style.border_width_top = 54
	cal_style.border_width_left = 4
	cal_style.border_width_right = 4
	cal_style.border_width_bottom = 4
	cal_style.corner_radius_top_left = 12
	cal_style.corner_radius_top_right = 12
	cal_style.corner_radius_bottom_left = 6
	cal_style.corner_radius_bottom_right = 6
	cal_style.shadow_color = Color(0, 0, 0, 0.2)
	cal_style.shadow_size = 10
	cal_style.shadow_offset = Vector2(4, 4)
	
	calendar_panel.add_theme_stylebox_override("panel", cal_style)
	add_child(calendar_panel)
	
	var cal_vbox = VBoxContainer.new()
	cal_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	calendar_panel.add_child(cal_vbox)
	
	var header = Label.new()
	header.text = "学期末まで"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_override("font", DeskTheme.get_font())
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color.GRAY)
	cal_vbox.add_child(header)
	
	day_label = Label.new()
	day_label.text = "Day " + str(session.current_day)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.add_theme_font_override("font", DeskTheme.get_font())
	day_label.add_theme_font_size_override("font_size", 84)
	day_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	cal_vbox.add_child(day_label)
	
	var footer = Label.new()
	footer.text = "あしたの勉強"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_override("font", DeskTheme.get_font())
	footer.add_theme_font_size_override("font_size", 22)
	footer.add_theme_color_override("font_color", Color.GRAY)
	cal_vbox.add_child(footer)
	
	if has_node("/root/ResponsiveScaler"):
		var rs = get_node("/root/ResponsiveScaler")
		if not rs.scale_changed.is_connected(_on_scale_changed):
			rs.scale_changed.connect(_on_scale_changed)
	_update_responsive_layout()
	
	calendar_panel.scale = Vector2.ZERO # Start hidden
	
	# Delay calendar tear animation by a tiny fraction so layout settles
	var timer = get_tree().create_timer(0.05)
	timer.timeout.connect(animate_calendar_transition)

func _on_scale_changed(_new_scale: float) -> void:
	_update_responsive_layout()

func _get_target_scale() -> float:
	if has_node("/root/ResponsiveScaler"):
		var rs = get_node("/root/ResponsiveScaler")
		if rs.is_portrait():
			return rs.fit_scale_for_size(Vector2(450, 450), Vector2(30, 30), 0.35)
	return 1.0

func _update_responsive_layout() -> void:
	if is_instance_valid(calendar_panel):
		var s = _get_target_scale()
		var size_half = calendar_panel.custom_minimum_size * 0.5
		if size_half == Vector2.ZERO:
			size_half = Vector2(225, 225)
		calendar_panel.pivot_offset = size_half
		if calendar_panel.scale != Vector2.ZERO:
			calendar_panel.scale = Vector2.ONE * s
		var viewport_size = get_viewport_rect().size
		if viewport_size.x == 0:
			viewport_size = Vector2(1500, 850)
		calendar_panel.position = (viewport_size - calendar_panel.custom_minimum_size) * 0.5

func animate_calendar_transition() -> void:
	calendar_panel.scale = Vector2.ZERO
	var target_s = _get_target_scale()
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(calendar_panel, "scale", Vector2.ONE * target_s, 0.55)
	
	tween.chain().tween_interval(0.55) # Wait briefly
	
	# Start tearing page
	tween.chain().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Paper flies to top-right
	var target_pos = calendar_panel.position + Vector2(400, -400)
	tween.tween_property(calendar_panel, "position", target_pos, 0.6)
	tween.tween_property(calendar_panel, "rotation_degrees", 45.0, 0.6)
	tween.tween_property(calendar_panel, "scale", Vector2(0.2, 0.2), 0.6)
	tween.tween_property(calendar_panel, "modulate:a", 0.0, 0.4)
	
	# Callback to close phase
	tween.chain().tween_callback(func():
		finish_phase({
			"next_day": session.current_day
		})
	)
