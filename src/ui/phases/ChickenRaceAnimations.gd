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
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("ffebee") if is_burst else Color("e8f5e9")
	style.border_color = DeskTheme.COLOR_TENSION if is_burst else DeskTheme.COLOR_GREEN
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 3)
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

static func play_burst_animation(phase: ChickenRacePhase, duplicate_values: Array) -> void:
	var speed_mult = phase.speed_mult
	DeskTheme.shake_control(phase, 15.0, 0.5)
	phase.led_indicator.color = DeskTheme.COLOR_TENSION
	phase.burst_prob_label.text = "寝落ちしました！(バースト)"
	phase.actual_score_label.text = "0点"
	
	for child in phase.hand_container.get_children():
		if child is CardVisual:
			var card_val = child.card_data.get("value", 0)
			if card_val in duplicate_values:
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
				var base_pos = child.position
				var tween = phase.create_tween().bind_node(child).set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				var base_scale = child.scale
				tween.tween_property(child, "scale", base_scale * 1.15, 0.3 / speed_mult)
				tween.tween_property(child, "position:y", base_pos.y - 25.0, 0.25 / speed_mult)
	
	_spawn_zzz_scribbles(phase)

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
	if phase.active_peek_sticky:
		phase.active_peek_sticky.queue_free()
		phase.active_peek_sticky = null
		
	var active_peek_sticky = PanelContainer.new()
	active_peek_sticky.custom_minimum_size = Vector2(300, 160)
	active_peek_sticky.pivot_offset = Vector2(150, 80)
	active_peek_sticky.rotation_degrees = randf_range(-3.0, 3.0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_HIGHLIGHTER
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.15)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 3)
	active_peek_sticky.add_theme_stylebox_override("panel", style)
	
	phase.add_child(active_peek_sticky)
	var sticky_viewport_size = phase.get_viewport_rect().size
	active_peek_sticky.position = Vector2(
		max(sticky_viewport_size.x - active_peek_sticky.custom_minimum_size.x - 40.0, 0.0),
		max(sticky_viewport_size.y - active_peek_sticky.custom_minimum_size.y - 60.0, 0.0)
	)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	active_peek_sticky.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "のぞき見メモ"
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(list_vbox)
	
	var player_deck = phase.session.player_deck
	var is_compass_active = player_deck.compass_active
	var hand_values = []
	for c in player_deck.hand:
		hand_values.append(c["value"])
		
	for idx in range(peeked.size()):
		var card = peeked[idx]
		var card_lbl = Label.new()
		var text_str = "・%d枚目： %s (%d 点)" % [idx + 1, card["name"], card["value"]]
		
		card_lbl.add_theme_font_override("font", DeskTheme.get_font())
		card_lbl.add_theme_font_size_override("font_size", 16)
		
		var is_overlap = is_compass_active and card["value"] in hand_values
		if is_overlap:
			text_str += " [被り]！"
			card_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		else:
			card_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
			
		card_lbl.text = text_str
		list_vbox.add_child(card_lbl)
		
	phase.set_mouse_filter_recursive(active_peek_sticky, Control.MOUSE_FILTER_IGNORE)
	active_peek_sticky.scale = Vector2(0.5, 0.5)
	var tween = phase.create_tween().bind_node(active_peek_sticky).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(active_peek_sticky, "scale", Vector2.ONE, 0.3 / phase.speed_mult)
	
	phase.active_peek_sticky = active_peek_sticky

static func update_compass_sticky(phase: ChickenRacePhase) -> void:
	var deck = phase.session.player_deck
	if not deck.compass_active:
		if phase.active_compass_sticky:
			phase.active_compass_sticky.queue_free()
			phase.active_compass_sticky = null
		return

	if not phase.active_compass_sticky:
		var active_compass_sticky = PanelContainer.new()
		active_compass_sticky.custom_minimum_size = Vector2(280, 150)
		active_compass_sticky.pivot_offset = Vector2(140, 75)
		active_compass_sticky.rotation_degrees = -2.0
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color("e0f7fa") # 明るい水色系
		style.border_color = DeskTheme.COLOR_ROLE_PREP
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.shadow_color = Color(0, 0, 0, 0.15)
		style.shadow_size = 6
		style.shadow_offset = Vector2(3, 3)
		active_compass_sticky.add_theme_stylebox_override("panel", style)
		
		phase.add_child(active_compass_sticky)
		var sticky_viewport_size = phase.get_viewport_rect().size
		active_compass_sticky.position = Vector2(
			max(sticky_viewport_size.x - active_compass_sticky.custom_minimum_size.x - 40.0, 0.0),
			max(sticky_viewport_size.y - active_compass_sticky.custom_minimum_size.y - 60.0, 0.0)
		)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		active_compass_sticky.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		margin.add_child(vbox)
		
		var title = Label.new()
		title.text = "コンパスの探知メモ"
		title.add_theme_font_override("font", DeskTheme.get_font())
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(title)
		
		var list_vbox = VBoxContainer.new()
		list_vbox.name = "ListVBox"
		list_vbox.add_theme_constant_override("separation", 3)
		vbox.add_child(list_vbox)
		
		phase.active_compass_sticky = active_compass_sticky
		phase.set_mouse_filter_recursive(active_compass_sticky, Control.MOUSE_FILTER_IGNORE)
		
		# 出現演出
		active_compass_sticky.scale = Vector2(0.5, 0.5)
		var tween_appear = phase.create_tween().bind_node(active_compass_sticky).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_appear.tween_property(active_compass_sticky, "scale", Vector2.ONE, 0.3 / phase.speed_mult)

	# 更新
	var list_vbox = phase.active_compass_sticky.find_child("ListVBox", true, false)
	if list_vbox:
		for child in list_vbox.get_children():
			child.queue_free()
			
		var indices = deck.activate_compass_indices()
		
		var desc_lbl = Label.new()
		desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		
		if indices.size() > 0:
			desc_lbl.text = "山札に眠る「コンパス」の位置："
			list_vbox.add_child(desc_lbl)
			
			var idx_lbl = Label.new()
			idx_lbl.add_theme_font_override("font", DeskTheme.get_font())
			idx_lbl.add_theme_font_size_override("font_size", 15)
			idx_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_ROLE_PREP)
			var idx_strs = []
			for idx in indices:
				idx_strs.append("・上から %d 枚目" % idx)
			idx_lbl.text = "\n".join(idx_strs)
			list_vbox.add_child(idx_lbl)
		else:
			desc_lbl.text = "探知結果：\n山札に「コンパス」カードは\nありません。"
			list_vbox.add_child(desc_lbl)
