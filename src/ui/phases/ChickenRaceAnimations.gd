class_name ChickenRaceAnimations
extends RefCounted

static func animate_draw_card(phase: ChickenRacePhase, card: Dictionary, card_ui: Control, on_complete: Callable) -> void:
	var speed_mult = phase.speed_mult
	
	# Animate Card Flip
	card_ui.scale = Vector2.ONE
	var card_vbox = card_ui.get_vbox() if card_ui is CardVisual else card_ui.get_child(0)
	if card_vbox:
		card_vbox.visible = false
		
	DeskTheme.animate_card_flip(card_ui, 0.35 / speed_mult, func():
		if card_vbox:
			card_vbox.visible = true
	)
	
	var timer = phase.get_tree().create_timer(0.4 / speed_mult)
	timer.timeout.connect(func():
		if on_complete.is_valid():
			on_complete.call()
	)

static func show_hour_result_popup(phase: ChickenRacePhase, score: int, is_burst: bool) -> void:
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(320, 100)
	popup.pivot_offset = Vector2(160, 50)
	
	var style = DeskTheme.create_sticky_note_style("red" if is_burst else "green")
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	popup.add_child(vbox)
	
	var main_lbl = Label.new()
	if is_burst:
		main_lbl.text = "寝落ちした！"
		main_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	else:
		main_lbl.text = "休憩（ストップ）"
		main_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	main_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_lbl.add_theme_font_override("font", DeskTheme.get_font())
	main_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(main_lbl)
	
	var score_lbl = Label.new()
	score_lbl.text = "確定得点: +%d点" % score
	score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_override("font", DeskTheme.get_font())
	score_lbl.add_theme_font_size_override("font_size", 26)
	vbox.add_child(score_lbl)
	
	phase.add_child(popup)
	
	var viewport_size = phase.get_viewport_rect().size
	popup.position = (viewport_size - popup.custom_minimum_size) / 2.0
	popup.scale = Vector2.ZERO
	
	var speed_mult = phase.speed_mult
	var tween = phase.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.3 / speed_mult)
	
	var timer = phase.get_tree().create_timer(1.2 / speed_mult)
	timer.timeout.connect(func():
		if is_instance_valid(popup):
			var fade_tween = phase.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fade_tween.tween_property(popup, "scale", Vector2(0.8, 0.8), 0.3 / speed_mult)
			fade_tween.tween_property(popup, "modulate:a", 0.0, 0.25 / speed_mult)
			fade_tween.chain().tween_callback(popup.queue_free)
	)

static func play_burst_animation(phase: ChickenRacePhase, duplicate_values: Array, on_complete: Callable = Callable()) -> void:
	var speed_mult = phase.speed_mult
	
	# ストップモーション演出
	var dark_bg = ColorRect.new()
	dark_bg.color = Color(0, 0, 0, 0.0)
	dark_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dark_bg.z_index = 50
	phase.add_child(dark_bg)
	
	var sm_tween = phase.create_tween()
	sm_tween.tween_property(dark_bg, "color:a", 0.6, 0.1)
	
	# 重複したカードを強調表示
	for child in phase.hand_container.get_children():
		if child is CardVisual:
			var card_val = child.card_data.get("value", 0)
			if card_val in duplicate_values:
				child.z_index = 51
				var style = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
				if style:
					style.border_color = Color("ff1744")
					style.border_width_left = 6
					style.border_width_right = 6
					style.border_width_top = 6
					style.border_width_bottom = 6
					child.add_theme_stylebox_override("normal", style)
					child.add_theme_stylebox_override("hover", style)
					child.add_theme_stylebox_override("pressed", style)
				child.modulate = Color("ff8a80")
				var tween = phase.create_tween().bind_node(child).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				tween.tween_property(child, "scale", child.scale * 1.2, 0.2)
	
	var timer = phase.get_tree().create_timer(1.2 / speed_mult)
	timer.timeout.connect(func():
		if is_instance_valid(dark_bg):
			dark_bg.queue_free()
		
		# ド派手なバースト演出
		DeskTheme.shake_control(phase, 30.0, 0.8)
		
		var flash = ColorRect.new()
		flash.color = Color(1.0, 0.0, 0.0, 0.8)
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flash.z_index = 100
		phase.add_child(flash)
		var flash_tween = phase.create_tween()
		flash_tween.tween_property(flash, "modulate:a", 0.0, 0.6 / speed_mult)
		flash_tween.tween_callback(flash.queue_free)
		
		if phase.has_node("/root/AudioManager"):
			phase.get_node("/root/AudioManager").play_se(AudioManager.SE_BURST, 0.0, -5.0)
		
		# テキスト表示
		phase.alert_banner.color.a = 0.5
		phase.alert_banner.z_index = 90
		phase.alert_label.text = "バースト！"
		phase.actual_score_label.text = "0点"
		
		phase.alert_label.scale = Vector2(0.1, 0.1)
		phase.alert_label.pivot_offset = phase.alert_label.size / 2.0
		var alert_tween = phase.create_tween()
		alert_tween.tween_property(phase.alert_label, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		alert_tween.tween_property(phase.alert_label, "scale", Vector2(1.0, 1.0), 0.2)
		
		# カードはじけ飛び演出
		for child in phase.hand_container.get_children():
			if child is CardVisual:
				child.z_index = 80
				var center = phase.hand_container.size / 2.0
				var dir = (child.position - center).normalized()
				if dir.length() < 0.1:
					dir = Vector2(randf_range(-1, 1), randf_range(-1, -0.5)).normalized()
				
				dir.y -= 1.5
				dir = dir.normalized()
				
				var throw_power = randf_range(600, 1200)
				var target_pos = child.position + dir * throw_power
				var target_rot = child.rotation_degrees + randf_range(-360, 360)
				
				var tween = phase.create_tween().bind_node(child).set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tween.tween_property(child, "position", target_pos, 0.7 / speed_mult)
				tween.tween_property(child, "rotation_degrees", target_rot, 0.7 / speed_mult)
				tween.tween_property(child, "modulate:a", 0.0, 0.7 / speed_mult)
		
		_spawn_zzz_scribbles(phase)
		
		var fade_out_timer = phase.get_tree().create_timer(1.4 / speed_mult)
		fade_out_timer.timeout.connect(func():
			if is_instance_valid(phase):
				var fade_tween = phase.create_tween().set_parallel(true)
				fade_tween.tween_property(phase.alert_banner, "color:a", 0.0, 0.4 / speed_mult)
				fade_tween.tween_property(phase.alert_label, "modulate:a", 0.0, 0.4 / speed_mult)
		)
		
		var end_timer = phase.get_tree().create_timer(1.8 / speed_mult)
		end_timer.timeout.connect(func():
			if is_instance_valid(phase):
				phase.alert_label.text = ""
				phase.alert_label.modulate.a = 1.0
			if on_complete.is_valid():
				on_complete.call()
		)
	)

static func _spawn_zzz_scribbles(phase: ChickenRacePhase) -> void:
	var speed_mult = phase.speed_mult
	var z_lbl = Label.new()
	z_lbl.text = "Zzz..."
	z_lbl.add_theme_font_override("font", DeskTheme.get_font())
	z_lbl.add_theme_font_size_override("font_size", 48)
	z_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	z_lbl.rotation_degrees = -8.0
	z_lbl.pivot_offset = Vector2(50, 20)
	z_lbl.scale = Vector2.ZERO
	
	if is_instance_valid(phase.hand_container):
		phase.hand_container.add_child(z_lbl)
		z_lbl.position = Vector2(250, 130)
		
		var tween = phase.create_tween()
		tween.tween_property(z_lbl, "scale", Vector2(1.2, 1.2), 0.45 / speed_mult).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var target_y = z_lbl.position.y - 60.0
		tween.parallel().tween_property(z_lbl, "position:y", target_y, 1.2 / speed_mult).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(z_lbl, "modulate:a", 0.0, 0.4 / speed_mult)
		tween.tween_callback(z_lbl.queue_free)

static func show_peek_sticky(phase: ChickenRacePhase, peeked: Array) -> void:
	pass

static func update_compass_sticky(phase: ChickenRacePhase) -> void:
	pass
