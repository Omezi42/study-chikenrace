class_name ModeSelectionModal
extends RefCounted

static func create_and_show(parent: Node, on_friend_match_pressed: Callable, national_names_pool: Array) -> PanelContainer:
	var mode_modal = PanelContainer.new()
	mode_modal.custom_minimum_size = Vector2(720, 720)
	mode_modal.pivot_offset = Vector2(360, 360)
	
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
		Global.game_mode = Constants.MODE_NATIONAL
		_show_difficulty_selection(parent, mode_modal, on_friend_match_pressed, national_names_pool)
	)
	
	# ── Connect: 🤝 フレンド戦 ──
	friend_btn.pressed.connect(func():
		DeskTheme.animate_click(friend_btn, Vector2.ONE, 0.08)
		mode_modal.queue_free()
		if on_friend_match_pressed.is_valid():
			on_friend_match_pressed.call()
	)
	
	random_btn.pressed.connect(func():
		DeskTheme.animate_click(random_btn, Vector2.ONE, 0.08)
		if not parent.has_node("/root/BackendManager"):
			return
		var bm = parent.get_node("/root/BackendManager")
		if bm.auth_token == "" or bm.logged_in_uuid == "":
			_show_login_warning(parent, mode_modal, national_names_pool, on_friend_match_pressed)
			return
			
		Global.game_mode = Constants.MODE_RANDOM
		_show_matching_lobby(parent, mode_modal, bm, national_names_pool, on_friend_match_pressed)
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
	if mode_modal != null and is_instance_valid(mode_modal):
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
			btn_title.text = "[未開放] " + cls["name"] + " (必要偏差値: %.1f)" % cls["req"]
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
				
				var start_game = func():
					diff_modal.queue_free()
					if Global.player_name == "":
						Global.change_scene_with_fade(parent.get_tree(), "res://Profile.tscn")
					else:
						Global.change_scene_with_fade(parent.get_tree(), "res://Main.tscn")

				var timer = parent.get_tree().create_timer(0.2)
				timer.timeout.connect(func():
					var select_modal_script = load("res://src/ui/modals/DeckSelectionModal.gd")
					if select_modal_script:
						select_modal_script.create_and_show(parent, start_game)
					else:
						start_game.call()
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
		if mode_modal != null and is_instance_valid(mode_modal):
			ModeSelectionModal.create_and_show(parent, on_friend_match_pressed, national_names_pool)
	)
	
	# Entrance animation
	diff_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(diff_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(diff_modal, "scale", Vector2.ONE, 0.3)

static func _show_login_warning(parent: Node, mode_modal: PanelContainer, national_names_pool: Array, on_friend_match_pressed: Callable) -> void:
	if mode_modal != null and is_instance_valid(mode_modal):
		mode_modal.queue_free()
	
	var warning = PanelContainer.new()
	warning.custom_minimum_size = Vector2(600, 360)
	warning.pivot_offset = Vector2(300, 180)
	warning.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	parent.add_child(warning)
	warning.position = parent.get_viewport_rect().size * 0.5 - warning.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	warning.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "ログインが必要です"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	vbox.add_child(title)
	
	var body = Label.new()
	body.text = "全国ランダムマッチ（オンライン対人戦）をプレイするには、アカウント登録およびログインが必要です。\n\nログイン画面に移動しますか？"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", DeskTheme.get_font())
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(body)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var yes_btn = Button.new()
	yes_btn.text = "ログイン画面へ"
	yes_btn.custom_minimum_size = Vector2(180, 45)
	yes_btn.add_theme_font_override("font", DeskTheme.get_font())
	yes_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(yes_btn)
	btn_hbox.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "戻る"
	no_btn.custom_minimum_size = Vector2(180, 45)
	no_btn.add_theme_font_override("font", DeskTheme.get_font())
	no_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(no_btn)
	btn_hbox.add_child(no_btn)
	
	yes_btn.pressed.connect(func():
		DeskTheme.animate_click(yes_btn, Vector2.ONE, 0.08)
		warning.queue_free()
		Global.change_scene_with_fade(parent.get_tree(), "res://Profile.tscn")
	)
	
	no_btn.pressed.connect(func():
		DeskTheme.animate_click(no_btn, Vector2.ONE, 0.08)
		warning.queue_free()
		if mode_modal != null and is_instance_valid(mode_modal):
			ModeSelectionModal.create_and_show(parent, on_friend_match_pressed, national_names_pool)
	)

static func _show_matching_lobby(parent: Node, mode_modal: PanelContainer, bm: Node, national_names_pool: Array, on_friend_match_pressed: Callable) -> void:
	if mode_modal != null and is_instance_valid(mode_modal):
		mode_modal.queue_free()
	
	var lobby = PanelContainer.new()
	lobby.custom_minimum_size = Vector2(650, 480)
	lobby.pivot_offset = Vector2(325, 240)
	lobby.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	parent.add_child(lobby)
	lobby.position = parent.get_viewport_rect().size * 0.5 - lobby.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	lobby.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "全国ランダムマッチ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var status_lbl = Label.new()
	status_lbl.text = "マッチングサーバーに接続中..."
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_override("font", DeskTheme.get_font())
	status_lbl.add_theme_font_size_override("font_size", 18)
	status_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	vbox.add_child(status_lbl)
	
	var members_vbox = VBoxContainer.new()
	members_vbox.add_theme_constant_override("separation", 8)
	members_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(members_vbox)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "マッチングをキャンセル"
	cancel_btn.custom_minimum_size = Vector2(240, 50)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.add_theme_font_override("font", DeskTheme.get_font())
	cancel_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(cancel_btn)
	vbox.add_child(cancel_btn)
	
	# ポーリング用のタイマー
	var poll_timer = Timer.new()
	poll_timer.wait_time = 2.0
	poll_timer.autostart = false
	lobby.add_child(poll_timer)
	
	var on_status_changed: Callable
	var on_room_polled: Callable
	
	var clean_up_lobby = func():
		poll_timer.stop()
		if bm.random_match_status_updated.is_connected(on_status_changed):
			bm.random_match_status_updated.disconnect(on_status_changed)
		if bm.room_polled.is_connected(on_room_polled):
			bm.room_polled.disconnect(on_room_polled)
		lobby.queue_free()
		
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		if Global.friend_room_code != "":
			bm.leave_or_delete_random_room(Global.friend_room_code)
		Global.friend_room_code = ""
		clean_up_lobby.call()
		if mode_modal != null and is_instance_valid(mode_modal):
			ModeSelectionModal.create_and_show(parent, on_friend_match_pressed, national_names_pool)
	)
	
	on_status_changed = func(status: String, message: String):
		if not is_instance_valid(status_lbl):
			return
		status_lbl.text = message
		if status == "waiting_for_players" or status == "matched":
			poll_timer.start()
			
	bm.random_match_status_updated.connect(on_status_changed)
	
	on_room_polled = func(status: String, day: int, participants: Array):
		if not is_instance_valid(lobby):
			return
		for child in members_vbox.get_children():
			child.queue_free()
			
		status_lbl.text = "対戦相手を待っています... (%d/4人)" % participants.size()
		
		for p in participants:
			var p_lbl = Label.new()
			p_lbl.text = "・%s" % p.get("username", "ライバル")
			p_lbl.add_theme_font_override("font", DeskTheme.get_font())
			p_lbl.add_theme_font_size_override("font_size", 16)
			p_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			members_vbox.add_child(p_lbl)
			
		if participants.size() >= 4 or status == "playing":
			poll_timer.stop()
			status_lbl.text = "マッチング完了！ゲームを開始します..."
			
			bm.fetch_participants_deviation(participants)
			
			Global.game_mode = Constants.MODE_RANDOM
			Global.friend_room_code = Global.friend_room_code
			Global.friend_member_list = participants
			Global.friend_is_host = bm.is_current_room_host()
			Global.save_game()
			
			Global.opponent_profiles.clear()
			var idx = 0
			var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
			for p in participants:
				var uid = p.get("user_id", "")
				if uid != bm.logged_in_uuid:
					if idx < slots.size():
						var slot_id = slots[idx]
						Global.opponent_profiles[slot_id] = {
							"id": uid,
							"name": p.get("username", "ライバル"),
							"deviation": 50.0
						}
						idx += 1
					
			var timer = parent.get_tree().create_timer(1.2)
			timer.timeout.connect(func():
				clean_up_lobby.call()
				Global.change_scene_with_fade(parent.get_tree(), "res://Main.tscn")
			)
			
	bm.room_polled.connect(on_room_polled)
	
	poll_timer.timeout.connect(func():
		if Global.friend_room_code != "":
			bm.poll_room_status(Global.friend_room_code)
	)
	
	bm.join_or_create_random_match()
