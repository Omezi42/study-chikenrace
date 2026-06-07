class_name TimelineUI
extends VBoxContainer

var active_timeline_tweens: Array[Tween] = []

func populate_timeline(participants_data: Array, session: GameSession, inspect_callback: Callable, doubt_callback: Callable, skip_btn: Button) -> void:
	for child in get_children():
		child.queue_free()
		
	active_timeline_tweens.clear()
	if skip_btn:
		skip_btn.visible = participants_data.size() > 0
		
	for idx in range(participants_data.size()):
		var p = participants_data[idx]
		
		# Timeline Post Card
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(480, 195)
		card.pivot_offset = Vector2(240, 97)
		
		# Rank border styling
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = DeskTheme.COLOR_CRAFT
		card_style.corner_radius_top_left = 6
		card_style.corner_radius_top_right = 6
		card_style.corner_radius_bottom_left = 6
		card_style.corner_radius_bottom_right = 6
		card_style.border_width_left = 4
		card_style.border_width_right = 1
		card_style.border_width_top = 1
		card_style.border_width_bottom = 1
		
		# Rank indicators
		if idx == 0:
			card_style.border_color = Color("ffd700") # Gold
		elif idx == 1:
			card_style.border_color = Color("c0c0c0") # Silver
		elif idx == 2:
			card_style.border_color = Color("cd7f32") # Bronze
		else:
			card_style.border_color = Color("37474f")
			
		card.add_theme_stylebox_override("panel", card_style)
		card.clip_contents = true
		
		card.modulate.a = 0.0
		var target_height = 195.0
		card.custom_minimum_size = Vector2(480, 0)
		
		add_child(card)
		
		var tween = card.create_tween().set_parallel(true)
		active_timeline_tweens.append(tween)
		var delay = idx * 0.12
		
		tween.tween_property(card, "custom_minimum_size:y", target_height, 0.35)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)
			
		tween.tween_property(card, "modulate:a", 1.0, 0.28)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)
			
		if idx == participants_data.size() - 1:
			tween.chain().tween_callback(func():
				if is_instance_valid(skip_btn):
					skip_btn.visible = false
			)
		
		var card_margin = MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 12)
		card_margin.add_theme_constant_override("margin_right", 12)
		card_margin.add_theme_constant_override("margin_top", 12)
		card_margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(card_margin)
		
		var card_hbox = HBoxContainer.new()
		card_hbox.add_theme_constant_override("separation", 15)
		card_margin.add_child(card_hbox)
		
		# Avatar Circle
		var avatar = ColorRect.new()
		avatar.custom_minimum_size = Vector2(48, 48)
		avatar.color = p["avatar_color"]
		card_hbox.add_child(avatar)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 6)
		card_hbox.add_child(text_vbox)
		
		# Header (Name & Reaction if CPU)
		var header_hbox = HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		text_vbox.add_child(header_hbox)
		
		var name_lbl = Label.new()
		name_lbl.text = p["name"]
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		header_hbox.add_child(name_lbl)
		
		# 表情バッジの追加
		var emote_key = p.get("emote", "normal")
		var emote_badge = Label.new()
		
		var badge_style = StyleBoxFlat.new()
		badge_style.content_margin_left = 6
		badge_style.content_margin_right = 6
		badge_style.content_margin_top = 2
		badge_style.content_margin_bottom = 2
		badge_style.corner_radius_top_left = 4
		badge_style.corner_radius_top_right = 4
		badge_style.corner_radius_bottom_left = 4
		badge_style.corner_radius_bottom_right = 4
		
		match emote_key:
			"normal":
				emote_badge.text = "[普通]"
				badge_style.bg_color = Color("eceff1")
				emote_badge.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			"confident":
				emote_badge.text = "[自信あり]"
				badge_style.bg_color = Color("e8f5e9")
				emote_badge.add_theme_color_override("font_color", Color("2e7d32"))
			"anxious":
				emote_badge.text = "[不安]"
				badge_style.bg_color = Color("ffebee")
				emote_badge.add_theme_color_override("font_color", Color("c62828"))
				
		emote_badge.add_theme_stylebox_override("normal", badge_style)
		emote_badge.add_theme_font_override("font", DeskTheme.get_font())
		emote_badge.add_theme_font_size_override("font_size", 13)
		header_hbox.add_child(emote_badge)
		
		# Headerにトグルボタンを追加
		var toggle_btn = Button.new()
		toggle_btn.text = " ▲ "
		toggle_btn.flat = true
		toggle_btn.add_theme_font_override("font", DeskTheme.get_font())
		toggle_btn.add_theme_font_size_override("font_size", 14)
		header_hbox.add_child(toggle_btn)
		
		var collapsible_container = VBoxContainer.new()
		collapsible_container.add_theme_constant_override("separation", 6)
		text_vbox.add_child(collapsible_container)
		
		# Body (Declared score text)
		var decl_lbl = Label.new()
		decl_lbl.text = "今日の勉強報告：" + str(p["declared_score"]) + " 点！"
		decl_lbl.add_theme_font_override("font", DeskTheme.get_font())
		decl_lbl.add_theme_font_size_override("font_size", 18)
		decl_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
		collapsible_container.add_child(decl_lbl)
		
		# Post actions HBox
		var act_hbox = HBoxContainer.new()
		act_hbox.alignment = BoxContainer.ALIGNMENT_END
		act_hbox.add_theme_constant_override("separation", 10)
		collapsible_container.add_child(act_hbox)
		
		# Detail Inspect Button
		var inspect_btn = Button.new()
		inspect_btn.text = "詳細確認"
		inspect_btn.custom_minimum_size = Vector2(120, 42)
		inspect_btn.add_theme_font_size_override("font_size", 16)
		DeskTheme.apply_white_button_style(inspect_btn)
		inspect_btn.pressed.connect(func(): inspect_callback.call(p))
		act_hbox.add_child(inspect_btn)
		
		# Doubt Button
		if p["id"] != "player":
			var doubt_btn = Button.new()
			doubt_btn.text = "ダウト!"
			doubt_btn.custom_minimum_size = Vector2(120, 42)
			doubt_btn.add_theme_font_size_override("font_size", 16)
			DeskTheme.apply_white_button_style(doubt_btn)
			doubt_btn.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
			doubt_btn.add_theme_color_override("font_disabled_color", DeskTheme.COLOR_TENSION)
			
			if p["id"] in session.player_doubts_made_today:
				doubt_btn.text = "ダウト済"
				doubt_btn.disabled = true
				
			doubt_btn.pressed.connect(func(): doubt_callback.call(p["id"], card, doubt_btn))
			act_hbox.add_child(doubt_btn)
			
		toggle_btn.pressed.connect(func():
			collapsible_container.visible = not collapsible_container.visible
			if collapsible_container.visible:
				toggle_btn.text = " ▲ "
				card.custom_minimum_size.y = 195
			else:
				toggle_btn.text = " ▼ "
				card.custom_minimum_size.y = 75
		)

func skip_animations() -> void:
	for tw in active_timeline_tweens:
		if is_instance_valid(tw) and tw.is_running():
			tw.kill()
	active_timeline_tweens.clear()
	for card in get_children():
		if is_instance_valid(card):
			card.modulate.a = 1.0
			card.custom_minimum_size = Vector2(480, 195)
