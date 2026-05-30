class_name FriendLobbyModal
extends RefCounted

static func create_selection_modal(parent: Node) -> void:
	var sel_modal = PanelContainer.new()
	sel_modal.custom_minimum_size = Vector2(500, 360)
	sel_modal.pivot_offset = Vector2(250, 180)
	sel_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	parent.add_child(sel_modal)
	sel_modal.position = parent.get_viewport_rect().size * 0.5 - sel_modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	sel_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "友達対戦ロビー"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	# Create Room Button
	var create_btn = Button.new()
	create_btn.text = "新しいルームを作る"
	create_btn.custom_minimum_size = Vector2(400, 60)
	create_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	create_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(create_btn)
	vbox.add_child(create_btn)
	
	# Join Room Section
	var join_hbox = HBoxContainer.new()
	join_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	join_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(join_hbox)
	
	var join_input = LineEdit.new()
	join_input.placeholder_text = "4桁のコードを入力"
	join_input.max_length = 4
	join_input.custom_minimum_size = Vector2(240, 45)
	join_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	join_input.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	join_input.add_theme_font_size_override("font_size", 16)
	join_hbox.add_child(join_input)
	
	var join_btn = Button.new()
	join_btn.text = "入室"
	join_btn.custom_minimum_size = Vector2(100, 45)
	join_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	join_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(join_btn)
	join_hbox.add_child(join_btn)
	
	# Close Button
	var cancel_btn = Button.new()
	cancel_btn.text = "閉じる"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	cancel_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(cancel_btn)
	vbox.add_child(cancel_btn)
	
	# Logic Bindings
	var bm = parent.get_node_or_null("/root/BackendManager")
	
	create_btn.pressed.connect(func():
		DeskTheme.animate_click(create_btn, Vector2.ONE, 0.08)
		create_btn.disabled = true
		join_btn.disabled = true
		
		var on_created = func(success: bool, code: String):
			if success:
				sel_modal.queue_free()
				show_lobby(parent, code, true)
			else:
				create_btn.disabled = false
				join_btn.disabled = false
				
		if bm:
			bm.room_created.connect(on_created, CONNECT_ONE_SHOT)
			bm.create_friend_room()
		else:
			# Mock Fallback
			on_created.call(true, "4278")
	)
	
	join_btn.pressed.connect(func():
		var code = join_input.text.strip_edges()
		if code.length() != 4:
			return
		DeskTheme.animate_click(join_btn, Vector2.ONE, 0.08)
		create_btn.disabled = true
		join_btn.disabled = true
		
		var on_joined = func(success: bool, parts: Array):
			if success:
				sel_modal.queue_free()
				show_lobby(parent, code, false)
			else:
				create_btn.disabled = false
				join_btn.disabled = false
				
		if bm:
			bm.room_joined.connect(on_joined, CONNECT_ONE_SHOT)
			bm.join_friend_room(code)
		else:
			# Mock Fallback
			on_joined.call(true, [])
	)
	
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		sel_modal.queue_free()
	)
	
	sel_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(sel_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sel_modal, "scale", Vector2.ONE, 0.3)

static func show_lobby(parent: Node, room_code: String, is_host: bool) -> void:
	var lobby_modal = PanelContainer.new()
	lobby_modal.custom_minimum_size = Vector2(600, 500)
	lobby_modal.pivot_offset = Vector2(300, 250)
	lobby_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	parent.add_child(lobby_modal)
	lobby_modal.position = parent.get_viewport_rect().size * 0.5 - lobby_modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	lobby_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "ロビー：友達の合流待ち (人数確認中)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	# Room Code display
	var code_lbl = Label.new()
	code_lbl.text = "ルームコード: " + room_code
	code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	code_lbl.add_theme_font_size_override("font_size", 36)
	code_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	vbox.add_child(code_lbl)
	
	var hint_lbl = Label.new()
	hint_lbl.text = "（友達にこのコードを教えて入室させてね！）"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	hint_lbl.add_theme_font_size_override("font_size", 14)
	hint_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	vbox.add_child(hint_lbl)
	
	# Participant List VBox
	var list_vbox = VBoxContainer.new()
	list_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	list_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(list_vbox)
	
	# Host Start Button (or Guest waiting label)
	var start_btn_lobby = Button.new()
	var waiting_lbl = Label.new()
	
	if is_host:
		start_btn_lobby.text = "自習を開始する！ ✏️"
		start_btn_lobby.custom_minimum_size = Vector2(260, 50)
		start_btn_lobby.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		start_btn_lobby.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		start_btn_lobby.add_theme_font_size_override("font_size", 18)
		start_btn_lobby.disabled = true # Enabled when 2+ players join
		Global.apply_white_button_style(start_btn_lobby)
		vbox.add_child(start_btn_lobby)
	else:
		waiting_lbl.text = "ホストがゲームを開始するのを待っています..."
		waiting_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		waiting_lbl.add_theme_font_size_override("font_size", 16)
		waiting_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(waiting_lbl)
		
	# Exit Button
	var exit_btn = Button.new()
	exit_btn.text = "ロビーを出る ✖"
	exit_btn.custom_minimum_size = Vector2(160, 45)
	exit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Global.apply_white_button_style(exit_btn)
	exit_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	exit_btn.add_theme_font_size_override("font_size", 16)
	vbox.add_child(exit_btn)
	
	# Polling Logic via SceneTree timers
	var is_polling_active = true
	var bm = parent.get_node_or_null("/root/BackendManager")
	
	var start_game_transition = func(final_participants: Array):
		is_polling_active = false
		Global.game_mode = Constants.MODE_FRIEND
		Global.friend_room_code = room_code
		Global.friend_is_host = is_host
		Global.friend_member_list = final_participants
		Global.save_game()
		
		# Set slots for opponent profiles
		var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
		var slot_idx = 0
		var my_id = bm.logged_in_uuid if (bm and bm.logged_in_uuid != "") else "player"
		
		Global.opponent_profiles.clear()
		for p in final_participants:
			var uid = p.get("user_id", "")
			if uid != my_id and slot_idx < 3:
				var slot = slots[slot_idx]
				Global.opponent_profiles[slot] = {
					"id": uid,
					"name": p.get("username", "プレイヤー"),
					"deviation": clamp(Global.deviation_value + randf_range(-5.0, 5.0), 35.0, 80.0)
				}
				slot_idx += 1
				
		# Fill any remaining slot with CPU default
		while slot_idx < 3:
			var slot = slots[slot_idx]
			var default_ids = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
			var def_id = default_ids[slot_idx]
			var profile = AIManager.CPU_OPPONENTS.get(def_id, {"name": "CPU"})
			Global.opponent_profiles[slot] = {
				"id": def_id,
				"name": profile["name"] + " (CPU)",
				"deviation": 50.0
			}
			slot_idx += 1
			
		Global.save_game()
		
		# Go to Profile (if name blank) or Main game
		var fade_timer = parent.get_tree().create_timer(0.2)
		fade_timer.timeout.connect(func():
			lobby_modal.queue_free()
			if Global.player_name == "":
				Global.change_scene_with_fade(parent.get_tree(), "res://Profile.tscn")
			else:
				Global.change_scene_with_fade(parent.get_tree(), "res://Main.tscn")
		)
		
	var on_polled = Callable()
	on_polled = func(status: String, day: int, parts: Array):
		if not is_polling_active:
			return
			
		# Update participant list display
		for child in list_vbox.get_children():
			child.queue_free()
			
		for p in parts:
			var name_lbl = Label.new()
			name_lbl.text = "● " + p.get("username", "プレイヤー")
			if p.get("user_id") == (bm.logged_in_uuid if (bm and bm.logged_in_uuid != "") else "player"):
				name_lbl.text += " (あなた)"
				name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
			else:
				name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
			name_lbl.add_theme_font_size_override("font_size", 18)
			list_vbox.add_child(name_lbl)
			
		# If host, enable start button if we have at least 2 players
		if is_host:
			start_btn_lobby.disabled = (parts.size() < 2)
			
		# If guest, check if status changed to playing
		if not is_host and status == "playing":
			# Wait a split second to make sure parts contains CPUs if filled
			var fetch_timer = parent.get_tree().create_timer(0.5)
			fetch_timer.timeout.connect(func():
				start_game_transition.call(parts)
			)
			return
			
		# Triggers next poll after 2 seconds
		if is_polling_active:
			var poll_timer = parent.get_tree().create_timer(2.0)
			poll_timer.timeout.connect(func():
				if bm and is_polling_active:
					bm.poll_room_status(room_code)
			)
			
	if bm:
		bm.room_polled.connect(on_polled)
		bm.poll_room_status(room_code)
	else:
		# Offline fallback polling emulator
		var mock_parts = [{"user_id": "player", "username": Global.player_name if Global.player_name != "" else "あなた"}]
		on_polled.call("waiting", 1, mock_parts)
		
		# Offline simulated CPU joining lobby after 2 seconds
		var join_timer = parent.get_tree().create_timer(2.0)
		join_timer.timeout.connect(func():
			if is_polling_active:
				mock_parts.append({"user_id": "cpu_sato", "username": "佐藤くん (CPU)"})
				mock_parts.append({"user_id": "cpu_suzuki", "username": "鈴木さん (CPU)"})
				on_polled.call("waiting", 1, mock_parts)
		)
		
	if is_host:
		start_btn_lobby.pressed.connect(func():
			DeskTheme.animate_click(start_btn_lobby, Vector2.ONE, 0.08)
			if bm:
				# Set status to playing and fill remaining slots
				bm.start_friend_game(room_code)
				# Quick fetch final list to transition
				var trans_timer = parent.get_tree().create_timer(0.5)
				trans_timer.timeout.connect(func():
					start_game_transition.call(bm.mock_participants if bm.is_mock_room else bm.mock_participants)
				)
			else:
				# Offline mock start
				var final_parts = [
					{"user_id": "player", "username": Global.player_name if Global.player_name != "" else "あなた"},
					{"user_id": "cpu_sato", "username": "佐藤くん (CPU)"},
					{"user_id": "cpu_suzuki", "username": "鈴木さん (CPU)"},
					{"user_id": "cpu_takahashi", "username": "高橋くん (CPU)"}
				]
				start_game_transition.call(final_parts)
		)
		
	exit_btn.pressed.connect(func():
		DeskTheme.animate_click(exit_btn, Vector2.ONE, 0.08)
		is_polling_active = false
		if bm and bm.room_polled.is_connected(on_polled):
			bm.room_polled.disconnect(on_polled)
		lobby_modal.queue_free()
	)
	
	lobby_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(lobby_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(lobby_modal, "scale", Vector2.ONE, 0.3)
