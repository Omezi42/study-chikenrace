class_name SettingsModal
extends CanvasLayer

static func create_and_show(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = SettingsModal.new()
	parent_node.add_child(canvas)

func _ready() -> void:
	layer = 101
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	var viewport_size = get_viewport().get_visible_rect().size
	var fit_s = clamp(min(viewport_size.x / 540.0, viewport_size.y / 960.0), 0.8, 3.0)
	var target_w = min(500.0, (viewport_size.x * 0.95) / fit_s)
	var target_h = min(620.0, (viewport_size.y * 0.95) / fit_s)
	modal.custom_minimum_size = Vector2(target_w, target_h)
	modal.pivot_offset = Vector2(target_w * 0.5, target_h * 0.5)
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(modal)
	
	modal.position = (viewport_size - Vector2(target_w, target_h)) * 0.5
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	modal.add_child(margin)
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "設定・ルール"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(26))
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	# Rulebook Button
	var rule_btn = Button.new()
	rule_btn.text = "あそびかた・ルールを確認する"
	rule_btn.custom_minimum_size = Vector2(0, 48)
	rule_btn.add_theme_font_override("font", DeskTheme.get_font())
	rule_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	rule_btn.add_theme_color_override("font_color", Color("1b5e20"))
	DeskTheme.apply_white_button_style(rule_btn)
	rule_btn.pressed.connect(func():
		rule_btn.release_focus()
		DeskTheme.animate_click(rule_btn, Vector2.ONE, 0.08)
		if get_parent():
			RulebookModal.create_and_show(get_parent())
	)
	vbox.add_child(rule_btn)
	
	# Player Name
	var name_vbox = VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 5)
	vbox.add_child(name_vbox)
	
	var name_label = Label.new()
	name_label.text = "プレイヤーネーム"
	name_label.add_theme_font_override("font", DeskTheme.get_font())
	name_label.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	name_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	name_vbox.add_child(name_label)
	
	var name_input = LineEdit.new()
	name_input.text = Global.player_name
	name_input.placeholder_text = "名前を入力 (例: あなた)"
	name_input.custom_minimum_size = Vector2(0, 45)
	name_input.add_theme_font_override("font", DeskTheme.get_font())
	name_input.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	var line_style = StyleBoxFlat.new()
	line_style.bg_color = Color("faf6f0")
	line_style.border_color = Color("d7ccc8")
	line_style.border_width_bottom = 2
	line_style.content_margin_left = 10
	name_input.add_theme_stylebox_override("normal", line_style)
	name_input.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	name_vbox.add_child(name_input)
	
	name_input.text_changed.connect(func(new_text):
		Global.player_name = new_text
		Global.save_game()
	)
	
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Mute Checkbox
	var mute_checkbox = CheckBox.new()
	mute_checkbox.text = " 全音声をミュート（消音）"
	mute_checkbox.button_pressed = SettingsState.is_muted
	mute_checkbox.add_theme_font_override("font", DeskTheme.get_font())
	mute_checkbox.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	mute_checkbox.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	mute_checkbox.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)
	mute_checkbox.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
	mute_checkbox.add_theme_color_override("font_focus_color", DeskTheme.COLOR_INK)
	vbox.add_child(mute_checkbox)
	
	mute_checkbox.toggled.connect(func(toggled_on):
		SettingsState.is_muted = toggled_on
		SettingsState.apply_settings()
		Global.save_game()
	)

	# BGM Volume
	var bgm_vbox = VBoxContainer.new()
	bgm_vbox.add_theme_constant_override("separation", 5)
	vbox.add_child(bgm_vbox)
	
	var bgm_label = Label.new()
	bgm_label.text = "BGM 音量"
	bgm_label.add_theme_font_override("font", DeskTheme.get_font())
	bgm_label.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	bgm_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	bgm_vbox.add_child(bgm_label)
	
	var bgm_slider = HSlider.new()
	bgm_slider.min_value = 0.0
	bgm_slider.max_value = 1.0
	bgm_slider.step = 0.05
	bgm_slider.value = SettingsState.bgm_volume
	bgm_slider.custom_minimum_size = Vector2(min(300.0, viewport_size.x * 0.7), 30)
	bgm_vbox.add_child(bgm_slider)
	
	bgm_slider.value_changed.connect(func(val):
		SettingsState.bgm_volume = val
		if SettingsState.is_muted and val > 0.0:
			SettingsState.is_muted = false
			mute_checkbox.set_pressed_no_signal(false)
		SettingsState.apply_settings()
		Global.save_game()
	)
	
	# SE Volume
	var se_vbox = VBoxContainer.new()
	se_vbox.add_theme_constant_override("separation", 5)
	vbox.add_child(se_vbox)
	
	var se_label = Label.new()
	se_label.text = "SE 音量"
	se_label.add_theme_font_override("font", DeskTheme.get_font())
	se_label.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	se_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	se_vbox.add_child(se_label)
	
	var se_slider = HSlider.new()
	se_slider.min_value = 0.0
	se_slider.max_value = 1.0
	se_slider.step = 0.05
	se_slider.value = SettingsState.se_volume
	se_slider.custom_minimum_size = Vector2(min(300.0, viewport_size.x * 0.7), 30)
	se_vbox.add_child(se_slider)
	
	se_slider.value_changed.connect(func(val):
		SettingsState.se_volume = val
		if SettingsState.is_muted and val > 0.0:
			SettingsState.is_muted = false
			mute_checkbox.set_pressed_no_signal(false)
		SettingsState.apply_settings()
		Global.save_game()
	)
	# Bottom Buttons
	var bottom_box
	if viewport_size.x < 450:
		bottom_box = VBoxContainer.new()
		bottom_box.add_theme_constant_override("separation", 15)
	else:
		bottom_box = HBoxContainer.new()
		bottom_box.add_theme_constant_override("separation", 20)
	bottom_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bottom_box)
	
	# Check if we are in game (not on the Title screen)
	var is_in_game = false
	var parent_node = get_parent()
	if parent_node and parent_node.get_tree() and parent_node.get_tree().current_scene:
		if not (parent_node.get_tree().current_scene is TitleScene):
			is_in_game = true
			
	if is_in_game:
		var return_btn = Button.new()
		return_btn.text = "タイトルへ戻る"
		return_btn.custom_minimum_size = Vector2(min(200.0, target_w - 60.0), 45)
		return_btn.add_theme_font_override("font", DeskTheme.get_font())
		return_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
		DeskTheme.apply_white_button_style(return_btn)
		return_btn.pressed.connect(func():
			return_btn.release_focus()
			DeskTheme.animate_click(return_btn, Vector2.ONE, 0.08)
			show_confirm_dialog(parent_node, "本当にタイトルへ戻りますか？\n（進行状況は破棄されます）", func():
				# Close settings and change scene
				queue_free()
				if parent_node.get_tree().root.has_node("WebRTCManager"):
					parent_node.get_tree().root.get_node("WebRTCManager").disconnect_room()
				if parent_node.get_tree().root.has_node("Global"):
					parent_node.get_tree().root.get_node("Global").change_scene_with_fade(parent_node.get_tree(), "res://Title.tscn")
			)
		)
		bottom_box.add_child(return_btn)
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = " 閉じる "
	close_btn.custom_minimum_size = Vector2(min(200.0, target_w - 60.0), 45)
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	DeskTheme.apply_white_button_style(close_btn)
	close_btn.pressed.connect(func():
		close_btn.release_focus()
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		if has_node("/root/Global"):
			get_node("/root/Global").save_game()
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			queue_free()
		)
	)
	bottom_box.add_child(close_btn)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	fit_s = clamp(min(get_viewport().get_visible_rect().size.x / 540.0, get_viewport().get_visible_rect().size.y / 960.0), 0.8, 3.0)
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE * fit_s, 0.3)

func show_confirm_dialog(parent_node: Node, text: String, on_confirm: Callable) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = CanvasLayer.new()
	canvas.layer = 105 # Higher than settings
	parent_node.add_child(canvas)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.5)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	var viewport_size = get_viewport().get_visible_rect().size
	var fit_s = clamp(min(viewport_size.x / 540.0, viewport_size.y / 960.0), 0.8, 3.0)
	var target_w = min(400.0, (viewport_size.x * 0.95) / fit_s)
	var target_h = min(200.0, (viewport_size.y * 0.95) / fit_s)
	modal.custom_minimum_size = Vector2(target_w, target_h)
	modal.pivot_offset = Vector2(target_w * 0.5, target_h * 0.5)
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	canvas.add_child(modal)
	
	modal.position = (viewport_size - Vector2(target_w, target_h)) * 0.5
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 20)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DeskTheme.get_font())
	label.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(label)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_hbox)
	
	var yes_btn = Button.new()
	yes_btn.text = "はい"
	yes_btn.custom_minimum_size = Vector2(120, 45)
	yes_btn.add_theme_font_override("font", DeskTheme.get_font())
	yes_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	DeskTheme.apply_white_button_style(yes_btn)
	yes_btn.add_theme_color_override("font_color", Color("d32f2f"))
	btn_hbox.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "いいえ"
	no_btn.custom_minimum_size = Vector2(120, 45)
	no_btn.add_theme_font_override("font", DeskTheme.get_font())
	no_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	DeskTheme.apply_white_button_style(no_btn)
	btn_hbox.add_child(no_btn)
	
	yes_btn.pressed.connect(func():
		yes_btn.release_focus()
		DeskTheme.animate_click(yes_btn, Vector2.ONE, 0.08)
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			canvas.queue_free()
			if on_confirm.is_valid():
				on_confirm.call()
		)
	)
	
	no_btn.pressed.connect(func():
		no_btn.release_focus()
		DeskTheme.animate_click(no_btn, Vector2.ONE, 0.08)
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			canvas.queue_free()
		)
	)
	
	modal.scale = Vector2.ZERO
	fit_s = clamp(min(get_viewport().get_visible_rect().size.x / 540.0, get_viewport().get_visible_rect().size.y / 960.0), 0.8, 3.0)
	var anim_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(modal, "scale", Vector2.ONE * fit_s, 0.3)
