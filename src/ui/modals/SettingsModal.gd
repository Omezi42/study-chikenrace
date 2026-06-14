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
	modal.custom_minimum_size = Vector2(500, 520)
	modal.pivot_offset = Vector2(250, 260)
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(modal)
	
	var viewport_size = get_viewport().get_visible_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "オプション設定"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var audio = get_node("/root/AudioManager")
	
	# BGM Volume
	var bgm_vbox = VBoxContainer.new()
	bgm_vbox.add_theme_constant_override("separation", 5)
	vbox.add_child(bgm_vbox)
	
	var bgm_label = Label.new()
	bgm_label.text = "BGM 音量: %d%%" % int(audio.bgm_volume * 100)
	bgm_label.add_theme_font_override("font", DeskTheme.get_font())
	bgm_label.add_theme_font_size_override("font_size", 16)
	bgm_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	bgm_vbox.add_child(bgm_label)
	
	var bgm_slider = HSlider.new()
	bgm_slider.min_value = 0.0
	bgm_slider.max_value = 1.0
	bgm_slider.step = 0.05
	bgm_slider.value = audio.bgm_volume
	bgm_vbox.add_child(bgm_slider)
	bgm_slider.value_changed.connect(func(val):
		audio.bgm_volume = val
		bgm_label.text = "BGM 音量: %d%%" % int(val * 100)
	)
	
	# SE Volume
	var se_vbox = VBoxContainer.new()
	se_vbox.add_theme_constant_override("separation", 5)
	vbox.add_child(se_vbox)
	
	var se_label = Label.new()
	se_label.text = "SE 音量: %d%%" % int(audio.se_volume * 100)
	se_label.add_theme_font_override("font", DeskTheme.get_font())
	se_label.add_theme_font_size_override("font_size", 16)
	se_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	se_vbox.add_child(se_label)
	
	var se_slider = HSlider.new()
	se_slider.min_value = 0.0
	se_slider.max_value = 1.0
	se_slider.step = 0.05
	se_slider.value = audio.se_volume
	se_vbox.add_child(se_slider)
	se_slider.value_changed.connect(func(val):
		audio.se_volume = val
		se_label.text = "SE 音量: %d%%" % int(val * 100)
	)
	
	# Mute Checkbox HBox
	var mute_hbox = HBoxContainer.new()
	mute_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(mute_hbox)
	
	var mute_label = Label.new()
	mute_label.text = "すべての音声をミュートする: "
	mute_label.add_theme_font_override("font", DeskTheme.get_font())
	mute_label.add_theme_font_size_override("font_size", 16)
	mute_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	mute_hbox.add_child(mute_label)
	
	var mute_check = CheckButton.new()
	mute_check.button_pressed = audio.is_muted
	mute_check.toggled.connect(func(pressed):
		audio.is_muted = pressed
	)
	mute_hbox.add_child(mute_check)
	
	# Font Switch Checkbox HBox
	var font_hbox = HBoxContainer.new()
	font_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(font_hbox)
	
	var font_label = Label.new()
	font_label.text = "手書き風フォントを使用する: "
	font_label.add_theme_font_override("font", DeskTheme.get_font())
	font_label.add_theme_font_size_override("font_size", 16)
	font_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	font_hbox.add_child(font_label)
	
	var font_check = CheckButton.new()
	var global_singleton = get_node_or_null("/root/Global")
	font_check.button_pressed = global_singleton.use_handwriting_font if global_singleton else true
	font_check.toggled.connect(func(pressed):
		if global_singleton:
			global_singleton.use_handwriting_font = pressed
			global_singleton.save_game()
			if has_node("/root/UIHelper"):
				get_node("/root/UIHelper").refresh_typography()
	)
	font_hbox.add_child(font_check)
	
	# Rules button inside Settings
	var rule_btn = Button.new()
	rule_btn.text = "ルールブックを閲覧"
	rule_btn.custom_minimum_size = Vector2(300, 45)
	rule_btn.add_theme_font_override("font", DeskTheme.get_font())
	rule_btn.add_theme_font_size_override("font_size", 16)
	DeskTheme.apply_white_button_style(rule_btn)
	rule_btn.pressed.connect(func():
		rule_btn.release_focus()
		DeskTheme.animate_click(rule_btn, Vector2.ONE, 0.08)
		RulebookModal.create_and_show(get_parent())
	)
	vbox.add_child(rule_btn)
	

	# Bottom Buttons HBox
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(bottom_hbox)
	
	# Check if we are in game (not on the Title screen)
	var is_in_game = false
	var parent_node = get_parent()
	if parent_node and parent_node.get_tree() and parent_node.get_tree().current_scene:
		if not (parent_node.get_tree().current_scene is TitleScene):
			is_in_game = true
			
	if is_in_game:
		var return_btn = Button.new()
		return_btn.text = "タイトルへ戻る"
		return_btn.custom_minimum_size = Vector2(200, 45)
		return_btn.add_theme_font_override("font", DeskTheme.get_font())
		return_btn.add_theme_font_size_override("font_size", 18)
		DeskTheme.apply_white_button_style(return_btn)
		return_btn.pressed.connect(func():
			return_btn.release_focus()
			DeskTheme.animate_click(return_btn, Vector2.ONE, 0.08)
			show_confirm_dialog(parent_node, "本当にタイトルへ戻りますか？\n（進行状況は破棄されます）", func():
				# Close settings and change scene
				queue_free()
				if parent_node.get_tree().root.has_node("Global"):
					parent_node.get_tree().root.get_node("Global").change_scene_with_fade(parent_node.get_tree(), "res://Title.tscn")
			)
		)
		bottom_hbox.add_child(return_btn)
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = " × 閉じる "
	close_btn.custom_minimum_size = Vector2(200, 45)
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 18)
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
	bottom_hbox.add_child(close_btn)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)

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
	modal.custom_minimum_size = Vector2(400, 200)
	modal.pivot_offset = Vector2(200, 100)
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	canvas.add_child(modal)
	
	var viewport_size = get_viewport().get_visible_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
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
	label.add_theme_font_size_override("font_size", 18)
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
	yes_btn.add_theme_font_size_override("font_size", 18)
	DeskTheme.apply_white_button_style(yes_btn)
	yes_btn.add_theme_color_override("font_color", Color("d32f2f"))
	btn_hbox.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "いいえ"
	no_btn.custom_minimum_size = Vector2(120, 45)
	no_btn.add_theme_font_override("font", DeskTheme.get_font())
	no_btn.add_theme_font_size_override("font_size", 18)
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
	var anim_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
