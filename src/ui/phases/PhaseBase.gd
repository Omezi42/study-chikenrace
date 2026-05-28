class_name PhaseBase
extends Control

signal phase_finished(data: Dictionary)

var session: GameSession

# Virtual initialization method
func setup(p_session: GameSession, setup_data: Dictionary = {}) -> void:
	session = p_session
	_on_setup(setup_data)

# To be overridden by subclasses
func _on_setup(_setup_data: Dictionary) -> void:
	pass

# Helper to emit phase finished signal
func finish_phase(result_data: Dictionary = {}, next_phase: String = "") -> void:
	if next_phase != "":
		result_data["next_phase"] = next_phase
	phase_finished.emit(result_data)

func show_tutorial_dialog(text: String, pos: Vector2 = Vector2(700, 50), next_callback: Callable = Callable()) -> PanelContainer:
	var dialog = PanelContainer.new()
	dialog.custom_minimum_size = Vector2(520, 220)
	dialog.size = Vector2(520, 220)
	dialog.position = pos
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("fff59d") # 明るい付箋イエロー
	style.border_color = Color("fbc02d") # 濃いイエロー
	style.border_width_left = 8
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 12
	style.shadow_offset = Vector2(4, 4)
	dialog.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	dialog.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "💡 チュートリアルガイド"
	header.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(header)
	
	var body = Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(body)
	
	if next_callback.is_valid():
		var btn = Button.new()
		btn.text = "次へ ▶"
		btn.custom_minimum_size = Vector2(100, 36)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func():
			DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
			var out_tween = create_tween().bind_node(dialog)
			out_tween.tween_property(dialog, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			out_tween.tween_callback(func():
				dialog.queue_free()
				next_callback.call()
			)
		)
		vbox.add_child(btn)
		
	add_child(dialog)
	
	dialog.scale = Vector2.ZERO
	dialog.pivot_offset = Vector2(260, 110)
	var tween = create_tween().bind_node(dialog).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dialog, "scale", Vector2.ONE, 0.3)
	
	return dialog
