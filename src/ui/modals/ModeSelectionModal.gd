class_name ModeSelectionModal
extends RefCounted

static func create_and_show(parent: Node, on_friend_match_pressed: Callable, national_names_pool: Array) -> PanelContainer:
	var mode_modal = PanelContainer.new()
	mode_modal.custom_minimum_size = Vector2(720, 620)
	mode_modal.pivot_offset = Vector2(360, 310)
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_CRAFT
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 15
	style.shadow_offset = Vector2(6, 6)
	mode_modal.add_theme_stylebox_override("panel", style)
	
	parent.add_child(mode_modal)
	mode_modal.position = parent.get_viewport_rect().size * 0.5 - mode_modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	mode_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = Localization.get_text("MODE_SELECTION_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_vbox)
	
	# ── 📝 模試 (National Mode) ──
	var national_btn = Button.new()
	national_btn.custom_minimum_size = Vector2(660, 100)
	Global.apply_white_button_style(national_btn)
	
	var nat_inner = VBoxContainer.new()
	nat_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	nat_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nat_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	national_btn.add_child(nat_inner)
	
	var nat_title = Label.new()
	nat_title.text = Localization.get_text("MODE_NATIONAL_TITLE")
	nat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nat_title.add_theme_font_override("font", DeskTheme.get_font())
	nat_title.add_theme_font_size_override("font_size", 22)
	nat_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	nat_inner.add_child(nat_title)
	
	var nat_desc = Label.new()
	nat_desc.text = Localization.get_text("MODE_NATIONAL_DESC")
	nat_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nat_desc.add_theme_font_override("font", DeskTheme.get_font())
	nat_desc.add_theme_font_size_override("font_size", 14)
	nat_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	nat_inner.add_child(nat_desc)
	
	btn_vbox.add_child(national_btn)
	
	# ── 🤝 フレンド戦 (Friend Mode) ──
	var friend_btn = Button.new()
	friend_btn.custom_minimum_size = Vector2(660, 100)
	Global.apply_white_button_style(friend_btn)
	
	var friend_inner = VBoxContainer.new()
	friend_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	friend_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	friend_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	friend_btn.add_child(friend_inner)
	
	var friend_title_lbl = Label.new()
	friend_title_lbl.text = Localization.get_text("MODE_FRIEND_TITLE")
	friend_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friend_title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	friend_title_lbl.add_theme_font_size_override("font_size", 22)
	friend_title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	friend_inner.add_child(friend_title_lbl)
	
	var friend_desc = Label.new()
	friend_desc.text = Localization.get_text("MODE_FRIEND_DESC")
	friend_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friend_desc.add_theme_font_override("font", DeskTheme.get_font())
	friend_desc.add_theme_font_size_override("font_size", 14)
	friend_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	friend_inner.add_child(friend_desc)
	
	btn_vbox.add_child(friend_btn)
	
	# ── 🎲 ランダムマッチ (Random Match Mode) ──
	var random_btn = Button.new()
	random_btn.custom_minimum_size = Vector2(660, 100)
	Global.apply_white_button_style(random_btn)
	
	var random_inner = VBoxContainer.new()
	random_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	random_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	random_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	random_btn.add_child(random_inner)
	
	var random_title_lbl = Label.new()
	random_title_lbl.text = Localization.get_text("MODE_RANDOM_TITLE")
	random_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	random_title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	random_title_lbl.add_theme_font_size_override("font_size", 22)
	random_title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	random_inner.add_child(random_title_lbl)
	
	var random_desc = Label.new()
	random_desc.text = Localization.get_text("MODE_RANDOM_DESC")
	random_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	random_desc.add_theme_font_override("font", DeskTheme.get_font())
	random_desc.add_theme_font_size_override("font_size", 14)
	random_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	random_inner.add_child(random_desc)
	
	btn_vbox.add_child(random_btn)
	
	# Cancel Button
	var cancel_btn = Button.new()
	cancel_btn.text = Localization.get_text("CANCEL_BUTTON")
	cancel_btn.custom_minimum_size = Vector2(160, 45)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.add_theme_font_override("font", DeskTheme.get_font())
	cancel_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(cancel_btn)
	vbox.add_child(cancel_btn)
	
	# ── Connect: 📝 模試 ──
	national_btn.pressed.connect(func():
		DeskTheme.animate_click(national_btn, Vector2.ONE, 0.08)
		_show_difficulty_selection(parent, mode_modal, on_friend_match_pressed, national_names_pool)
	)
	
	# ── Connect: 🤝 フレンド戦 ──
	friend_btn.pressed.connect(func():
		DeskTheme.animate_click(friend_btn, Vector2.ONE, 0.08)
		mode_modal.queue_free()
		if on_friend_match_pressed.is_valid():
			on_friend_match_pressed.call()
	)
	
	# ── Connect: 🎲 ランダムマッチ ──
	random_btn.pressed.connect(func():
		DeskTheme.animate_click(random_btn, Vector2.ONE, 0.08)
		Global.game_mode = Constants.MODE_RANDOM
		
		# Generate random opponents
		var pool = national_names_pool.duplicate()
		pool.shuffle()
		var cpu_pool_keys = AIManager.CPU_OPPONENTS.keys().duplicate()
		cpu_pool_keys.shuffle()
		
		Global.opponent_profiles = {
			"cpu_sato": {
				"id": cpu_pool_keys[0],
				"name": pool[0],
				"deviation": clamp(Global.deviation_value + randf_range(-5.0, 5.0), 35.0, 80.0)
			},
			"cpu_suzuki": {
				"id": cpu_pool_keys[1],
				"name": pool[1],
				"deviation": clamp(Global.deviation_value + randf_range(-3.0, 3.0), 35.0, 80.0)
			},
			"cpu_takahashi": {
				"id": cpu_pool_keys[2],
				"name": pool[2],
				"deviation": clamp(Global.deviation_value + randf_range(-8.0, 8.0), 35.0, 80.0)
			}
		}
		
		random_title_lbl.text = Localization.get_text("MATCHING_STATUS")
		random_btn.disabled = true
		
		# Simulate matching delay for UX
		var timer = parent.get_tree().create_timer(1.2)
		timer.timeout.connect(func():
			Global.save_game()
			mode_modal.queue_free()
			if Global.player_name == "":
				Global.change_scene_with_fade(parent.get_tree(), "res://Profile.tscn")
			else:
				Global.change_scene_with_fade(parent.get_tree(), "res://Main.tscn")
		)
	)
	
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		if parent.get_tree() != null:
			var tween = parent.get_tree().create_tween().bind_node(mode_modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(mode_modal, "scale", Vector2.ZERO, 0.2)
			tween.chain().tween_callback(func():
				mode_modal.queue_free()
			)
	)
	
	# Entrance animation
	mode_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(mode_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(mode_modal, "scale", Vector2.ONE, 0.3)
		
	return mode_modal

static func _show_difficulty_selection(parent: Node, mode_modal: PanelContainer, on_friend_match_pressed: Callable, national_names_pool: Array) -> void:
	var parent_tree = parent
	mode_modal.queue_free()
	
	var diff_modal = PanelContainer.new()
	diff_modal.custom_minimum_size = Vector2(720, 620)
	diff_modal.pivot_offset = Vector2(360, 310)
	diff_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	parent.add_child(diff_modal)
	diff_modal.position = parent.get_viewport_rect().size * 0.5 - diff_modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	diff_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "模試のクラス選択"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var my_dev_lbl = Label.new()
	my_dev_lbl.text = "現在のあなたの偏差値: %.1f" % Global.deviation_value
	my_dev_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_dev_lbl.add_theme_font_override("font", DeskTheme.get_font())
	my_dev_lbl.add_theme_font_size_override("font_size", 16)
	my_dev_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	vbox.add_child(my_dev_lbl)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_vbox)
	
	# クラスの定義
	var classes = [
		{"id": "remedial", "name": "補習室", "desc": "ダウト警戒度が非常に低い初心者クラス。基本を学ぶのに最適。", "req": 0.0},
		{"id": "regular", "name": "一般クラス", "desc": "通常の強さのCPUと対戦する標準クラス。推奨偏差値：50以上", "req": 50.0},
		{"id": "advanced", "name": "特進クラス", "desc": "CPUが期待値計算で的確にダウトを撃つ高難易度クラス。推奨偏差値：60以上", "req": 60.0}
	]
	
	for cls in classes:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(660, 90)
		Global.apply_white_button_style(btn)
		
		var unlocked = Global.deviation_value >= cls["req"]
		
		var inner = VBoxContainer.new()
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(inner)
		
		var btn_title = Label.new()
		if unlocked:
			btn_title.text = cls["name"]
		else:
			btn_title.text = "🔒 " + cls["name"] + " (必要偏差値: %.1f)" % cls["req"]
		btn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_title.add_theme_font_override("font", DeskTheme.get_font())
		btn_title.add_theme_font_size_override("font_size", 20)
		btn_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK if unlocked else Color(DeskTheme.COLOR_INK, 0.4))
		inner.add_child(btn_title)
		
		var btn_desc = Label.new()
		btn_desc.text = cls["desc"]
		btn_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_desc.add_theme_font_override("font", DeskTheme.get_font())
		btn_desc.add_theme_font_size_override("font_size", 12)
		btn_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5) if unlocked else Color(DeskTheme.COLOR_INK, 0.3))
		inner.add_child(btn_desc)
		
		btn_vbox.add_child(btn)
		
		if not unlocked:
			btn.disabled = true
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			btn.pressed.connect(func():
				DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
				Global.selected_class = cls["id"]
				
				# 対戦相手の偏差値をクラスに合わせて調整
				var dev_min = 35.0
				var dev_max = 50.0
				if cls["id"] == "regular":
					dev_min = 48.0
					dev_max = 58.0
				elif cls["id"] == "advanced":
					dev_min = 58.0
					dev_max = 80.0
				
				Global.game_mode = Constants.MODE_NATIONAL
				var pool = national_names_pool.duplicate()
				pool.shuffle()
				var cpu_pool_keys = AIManager.CPU_OPPONENTS.keys().duplicate()
				cpu_pool_keys.shuffle()
				
				Global.opponent_profiles = {
					"cpu_sato": {
						"id": cpu_pool_keys[0],
						"name": pool[0],
						"deviation": clamp(randf_range(dev_min, dev_max), 35.0, 80.0)
					},
					"cpu_suzuki": {
						"id": cpu_pool_keys[1],
						"name": pool[1],
						"deviation": clamp(randf_range(dev_min, dev_max), 35.0, 80.0)
					},
					"cpu_takahashi": {
						"id": cpu_pool_keys[2],
						"name": pool[2],
						"deviation": clamp(randf_range(dev_min, dev_max), 35.0, 80.0)
					}
				}
				Global.save_game()
				
				var timer = parent.get_tree().create_timer(0.2)
				timer.timeout.connect(func():
					diff_modal.queue_free()
					if Global.player_name == "":
						Global.change_scene_with_fade(parent.get_tree(), "res://Profile.tscn")
					else:
						Global.change_scene_with_fade(parent.get_tree(), "res://Main.tscn")
				)
			)
			
	# Back Button
	var back_btn = Button.new()
	back_btn.text = "戻る"
	back_btn.custom_minimum_size = Vector2(160, 45)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_override("font", DeskTheme.get_font())
	back_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(back_btn)
	vbox.add_child(back_btn)
	
	back_btn.pressed.connect(func():
		DeskTheme.animate_click(back_btn, Vector2.ONE, 0.08)
		diff_modal.queue_free()
		ModeSelectionModal.create_and_show(parent, on_friend_match_pressed, national_names_pool)
	)
	
	# Entrance animation
	diff_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(diff_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(diff_modal, "scale", Vector2.ONE, 0.3)
