class_name FriendLobbyModal
extends RefCounted

static func create_selection_modal(parent: Node) -> void:
	var vp_size = parent.get_viewport_rect().size
	var is_portrait = vp_size.y > vp_size.x
	var fit_s = clamp(min(vp_size.x / 540.0, vp_size.y / 960.0), 0.8, 3.0)
	var width = min(480.0, (vp_size.x * 0.95) / fit_s)
	var height = min(360.0, (max(vp_size.y, 600.0) * 0.9) / fit_s)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var sel_modal = PanelContainer.new()
	sel_modal.custom_minimum_size = Vector2(width, height)
	sel_modal.pivot_offset = Vector2(width / 2.0, height / 2.0)
	sel_modal.resized.connect(func(): sel_modal.pivot_offset = sel_modal.size * 0.5)
	sel_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	center.add_child(sel_modal)
	sel_modal.tree_exiting.connect(func(): if is_instance_valid(center): center.queue_free())
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sel_modal.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "友達対戦ロビー"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(26))
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	# Create Room Button
	var create_btn = Button.new()
	create_btn.text = "新しいルームを作る"
	create_btn.custom_minimum_size = Vector2(min(360.0, width - 80.0), 60)
	create_btn.add_theme_font_override("font", DeskTheme.get_font())
	create_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
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
	join_input.custom_minimum_size = Vector2(min(240.0, width - 160.0), 45)
	join_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	join_input.add_theme_font_override("font", DeskTheme.get_font())
	join_input.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	join_hbox.add_child(join_input)
	
	var join_btn = Button.new()
	join_btn.text = "入室"
	join_btn.custom_minimum_size = Vector2(100, 45)
	join_btn.add_theme_font_override("font", DeskTheme.get_font())
	join_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	Global.apply_white_button_style(join_btn)
	join_hbox.add_child(join_btn)
	
	# Close Button
	var cancel_btn = Button.new()
	cancel_btn.text = "閉じる"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_override("font", DeskTheme.get_font())
	cancel_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	Global.apply_white_button_style(cancel_btn)
	vbox.add_child(cancel_btn)
	
	# Logic Bindings
	var wrm = parent.get_node_or_null("/root/WebRTCManager")
	var pending_cbs = {}
	
	create_btn.pressed.connect(func():
		create_btn.release_focus()
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
				UIHelper.show_toast("サーバーに接続できませんでした。インターネット接続を確認してください。")
				
		if wrm:
			pending_cbs["created"] = on_created
			wrm.webrtc_multiplayer.room_created.connect(on_created, CONNECT_ONE_SHOT)
			wrm.webrtc_multiplayer.create_room()
		else:
			# Mock Fallback
			on_created.call(true, "4278")
	)
	
	join_btn.pressed.connect(func():
		join_btn.release_focus()
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
				UIHelper.show_toast("ルームに参加できませんでした。コードやサーバー状態を確認してください。")
				
		if wrm:
			pending_cbs["joined"] = on_joined
			wrm.webrtc_multiplayer.room_joined.connect(on_joined, CONNECT_ONE_SHOT)
			wrm.webrtc_multiplayer.join_room(code)
		else:
			# Mock Fallback
			on_joined.call(true, [])
	)
	
	sel_modal.tree_exiting.connect(func():
		if wrm and wrm.webrtc_multiplayer:
			if pending_cbs.has("created") and wrm.webrtc_multiplayer.room_created.is_connected(pending_cbs["created"]):
				wrm.webrtc_multiplayer.room_created.disconnect(pending_cbs["created"])
			if pending_cbs.has("joined") and wrm.webrtc_multiplayer.room_joined.is_connected(pending_cbs["joined"]):
				wrm.webrtc_multiplayer.room_joined.disconnect(pending_cbs["joined"])
	)
	
	cancel_btn.pressed.connect(func():
		cancel_btn.release_focus()
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		sel_modal.queue_free()
	)
	
	sel_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(sel_modal).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(sel_modal, "scale", Vector2.ONE * fit_s, 0.3)

static func show_lobby(parent: Node, room_code: String, is_host: bool) -> void:
	Global.game_mode = Constants.MODE_FRIEND
	var vp_size = parent.get_viewport_rect().size
	var is_portrait = vp_size.y > vp_size.x
	var fit_s = clamp(min(vp_size.x / 540.0, vp_size.y / 960.0), 0.8, 3.0)
	var width = min(480.0, (vp_size.x * 0.95) / fit_s)
	var height = min(500.0, (max(vp_size.y, 600.0) * 0.9) / fit_s)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var lobby_modal = PanelContainer.new()
	lobby_modal.custom_minimum_size = Vector2(width, height)
	lobby_modal.pivot_offset = Vector2(width / 2.0, height / 2.0)
	lobby_modal.resized.connect(func(): lobby_modal.pivot_offset = lobby_modal.size * 0.5)
	lobby_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	center.add_child(lobby_modal)
	lobby_modal.tree_exiting.connect(func(): if is_instance_valid(center): center.queue_free())
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lobby_modal.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	var wrm = parent.get_node_or_null("/root/WebRTCManager")
	var is_mock = false
	
	var title = Label.new()
	if is_mock:
		title.text = "ロビー：オフライン\n(CPU合流待ち)"
		title.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	else:
		title.text = "ロビー：友達の合流待ち\n(人数確認中)"
		title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(26))
	vbox.add_child(title)
	
	# Room Code display
	var code_lbl = Label.new()
	code_lbl.text = "ルームコード: " + room_code
	code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_lbl.add_theme_font_override("font", DeskTheme.get_font())
	code_lbl.add_theme_font_size_override("font_size", 36 if width > 350 else 28)
	code_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	vbox.add_child(code_lbl)
	
	var copy_btn = Button.new()
	copy_btn.text = "招待文をコピー"
	copy_btn.custom_minimum_size = Vector2(min(220.0, width - 80.0), 45)
	copy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	copy_btn.add_theme_font_override("font", DeskTheme.get_font())
	copy_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	Global.apply_white_button_style(copy_btn)
	vbox.add_child(copy_btn)
	
	copy_btn.pressed.connect(func():
		copy_btn.release_focus()
		DeskTheme.animate_click(copy_btn, Vector2.ONE, 0.08)
		var invite_text = "チキスタ対戦ルーム【%s】に招待されています！\n下記URLからゲームを開いて、フレンド対戦ロビーからコードを入力して参加してね！\nhttps://unityroom.com/games/studychickenrace" % room_code
		if OS.has_feature("web"):
			var js_code = """
			var text = "%s";
			function fallbackCopyTextToClipboard(text) {
				var textArea = document.createElement("textarea");
				textArea.value = text;
				textArea.style.top = "0";
				textArea.style.left = "0";
				textArea.style.position = "fixed";
				document.body.appendChild(textArea);
				textArea.focus();
				textArea.select();
				try { document.execCommand('copy'); } catch (err) { }
				document.body.removeChild(textArea);
			}
			if (navigator.clipboard && window.isSecureContext) {
				navigator.clipboard.writeText(text).catch(function(e){
					fallbackCopyTextToClipboard(text);
				});
			} else {
				fallbackCopyTextToClipboard(text);
			}
			"""
			var safe_text = invite_text.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
			JavaScriptBridge.eval(js_code % safe_text)
		else:
			DisplayServer.clipboard_set(invite_text)
		var orig_text = copy_btn.text
		copy_btn.text = "コピーしました！"
		copy_btn.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		var tw = copy_btn.create_tween()
		tw.tween_interval(1.5)
		tw.tween_callback(func():
			copy_btn.text = orig_text
			copy_btn.remove_theme_color_override("font_color")
		)
	)
	
	var hint_lbl = Label.new()
	if is_mock:
		hint_lbl.text = "注: 接続エラーまたは未ログインのため、\nCPU対戦となります"
		hint_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	else:
		hint_lbl.text = "（友達にこのコードを教えて\n入室させてね！）"
		hint_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_override("font", DeskTheme.get_font())
	hint_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(14))
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
		start_btn_lobby.text = "自習を開始する！"
		start_btn_lobby.custom_minimum_size = Vector2(min(260.0, width - 80.0), 50)
		start_btn_lobby.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		start_btn_lobby.add_theme_font_override("font", DeskTheme.get_font())
		start_btn_lobby.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
		start_btn_lobby.disabled = true # Enabled when 2+ players join
		Global.apply_white_button_style(start_btn_lobby)
		vbox.add_child(start_btn_lobby)
	else:
		waiting_lbl.text = "ホストがゲームを開始するのを\n待っています..."
		waiting_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting_lbl.add_theme_font_override("font", DeskTheme.get_font())
		waiting_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
		waiting_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(waiting_lbl)
		
	# Exit Button
	var exit_btn = Button.new()
	exit_btn.text = "ロビーを出る"
	exit_btn.custom_minimum_size = Vector2(min(160.0, width - 80.0), 45)
	exit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Global.apply_white_button_style(exit_btn)
	exit_btn.add_theme_font_override("font", DeskTheme.get_font())
	exit_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	vbox.add_child(exit_btn)
	# Polling Logic via SceneTree timers
	var is_polling_active = true
	var cbs = {}
	
	cbs.start_game_transition = func(final_participants: Array, game_seed: int = 0):
		randomize()
		Global.cpu_rng.randomize()
		AudioManager.play_se(AudioManager.SE_CLICK)
		DisplayServer.window_request_attention()
		is_polling_active = false
		if cbs.has("cleanup_signals"):
			cbs.cleanup_signals.call()
		Global.game_mode = Constants.MODE_FRIEND
		Global.friend_room_code = room_code
		Global.friend_is_host = is_host
		Global.friend_member_list.assign(final_participants)
		Global.friend_current_day = 1
		Global.friend_match_history.clear()
		MatchState.current_match_actions.clear()
		MatchState.current_synced_state.clear()
		Global.save_game()
		
		# Set slots for opponent profiles
		var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
		var slot_idx = 0
		var my_id = str(parent.multiplayer.get_unique_id()) if parent.multiplayer.has_multiplayer_peer() else "player"
		
		Global.opponent_profiles.clear()
		for p in final_participants:
			var uid = p.get("user_id", "")
			if uid != my_id and slot_idx < 3:
				var slot = slots[slot_idx]
				Global.opponent_profiles[slot] = {
					"id": uid,
					"name": p.get("username", "プレイヤー")
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
				"name": profile["name"] + " (CPU)"
			}
			slot_idx += 1
			
		Global.save_game()
		
		# Go to Profile (if name blank) or Main game
		var fade_timer = parent.get_tree().create_timer(0.2)
		fade_timer.timeout.connect(func():
			if is_instance_valid(lobby_modal):
				lobby_modal.queue_free()
			if Global.player_name == "":
				Global.change_scene_with_fade(parent.get_tree(), "res://Profile.tscn")
			else:
				Global.change_scene_with_fade(parent.get_tree(), "res://Main.tscn")
		)
		
	cbs.on_polled = func():
		if not is_polling_active:
			return
		
		var parts = []
		if wrm and wrm.webrtc_multiplayer:
			parts = wrm.webrtc_multiplayer._participants
			
		# Update participant list display
		for child in list_vbox.get_children():
			child.queue_free()
			
		for p in parts:
			var name_lbl = Label.new()
			name_lbl.text = "- " + p.get("username", "プレイヤー")
			if p.get("user_id") == (str(parent.multiplayer.get_unique_id()) if parent.multiplayer.has_multiplayer_peer() else "player"):
				name_lbl.text += " (あなた)"
				name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
			else:
				name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.add_theme_font_override("font", DeskTheme.get_font())
			name_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
			list_vbox.add_child(name_lbl)
			
		# If host, enable start button if we have at least 2 players
		if is_host:
			var all_connected = true
			if wrm and wrm.webrtc_multiplayer:
				var my_id = str(parent.multiplayer.get_unique_id()) if parent.multiplayer.has_multiplayer_peer() else "player"
				for p in parts:
					var uid = p.get("user_id", "")
					if uid != my_id and uid != "player":
						if not parent.multiplayer.get_peers().has(int(uid)):
							all_connected = false
							break
			
			start_btn_lobby.disabled = (parts.size() < 2 or not all_connected)
			if parts.size() >= 2 and not all_connected:
				start_btn_lobby.text = "接続を確立中..."
			elif parts.size() >= 2:
				start_btn_lobby.text = "自習を開始する！"
			else:
				start_btn_lobby.text = "友達を待っています..."

	cbs.on_game_state_synced = func(state: Dictionary):
		if state.get("action", "") == "start_game":
			is_polling_active = false
			cbs.start_game_transition.call(state.get("participants", []), state.get("seed", 0))

	cbs.on_player_connected_cb = func(id): cbs.on_polled.call()
	cbs.on_player_disconnected_cb = func(id): cbs.on_polled.call()
	cbs.on_room_joined_cb = func(success, parts): cbs.on_polled.call()

	cbs.cleanup_signals = func():
		if wrm and wrm.webrtc_multiplayer:
			if wrm.webrtc_multiplayer.player_connected.is_connected(cbs.on_player_connected_cb):
				wrm.webrtc_multiplayer.player_connected.disconnect(cbs.on_player_connected_cb)
			if wrm.webrtc_multiplayer.player_disconnected.is_connected(cbs.on_player_disconnected_cb):
				wrm.webrtc_multiplayer.player_disconnected.disconnect(cbs.on_player_disconnected_cb)
			if wrm.webrtc_multiplayer.room_joined.is_connected(cbs.on_room_joined_cb):
				wrm.webrtc_multiplayer.room_joined.disconnect(cbs.on_room_joined_cb)
		if MatchState.game_state_synced.is_connected(cbs.on_game_state_synced):
			MatchState.game_state_synced.disconnect(cbs.on_game_state_synced)
		if parent.multiplayer.peer_connected.is_connected(cbs.on_player_connected_cb):
			parent.multiplayer.peer_connected.disconnect(cbs.on_player_connected_cb)
		if parent.multiplayer.peer_disconnected.is_connected(cbs.on_player_disconnected_cb):
			parent.multiplayer.peer_disconnected.disconnect(cbs.on_player_disconnected_cb)

	lobby_modal.tree_exiting.connect(func(): cbs.cleanup_signals.call())

	if wrm and wrm.webrtc_multiplayer:
		wrm.webrtc_multiplayer.player_connected.connect(cbs.on_player_connected_cb)
		wrm.webrtc_multiplayer.player_disconnected.connect(cbs.on_player_disconnected_cb)
		wrm.webrtc_multiplayer.room_joined.connect(cbs.on_room_joined_cb)
		MatchState.game_state_synced.connect(cbs.on_game_state_synced)
		
		parent.multiplayer.peer_connected.connect(cbs.on_player_connected_cb)
		parent.multiplayer.peer_disconnected.connect(cbs.on_player_disconnected_cb)
		
		if MatchState.current_synced_state.get("action", "") == "start_game":
			cbs.on_game_state_synced.call(MatchState.current_synced_state)
		else:
			cbs.on_polled.call()
	else:
		# Offline fallback
		var mock_parts = [{"user_id": "player", "username": Global.player_name if Global.player_name != "" else "あなた"}]
		# Mock logic is ignored for brevity
		
	if is_host:
		start_btn_lobby.pressed.connect(func():
			start_btn_lobby.release_focus()
			DeskTheme.animate_click(start_btn_lobby, Vector2.ONE, 0.08)
			start_btn_lobby.disabled = true
			
			if wrm and wrm.webrtc_multiplayer:
				var parts = wrm.webrtc_multiplayer._participants
				var game_seed = randi()
				MatchState.sync_game_state.rpc({"action": "start_game", "participants": parts, "seed": game_seed})
				cbs.start_game_transition.call(parts, game_seed)
			else:
				var final_parts = [
					{"user_id": "player", "username": Global.player_name if Global.player_name != "" else "あなた"},
					{"user_id": "cpu_sato", "username": "佐藤くん (CPU)"}
				]
				cbs.start_game_transition.call(final_parts, randi())
		)
		
	exit_btn.pressed.connect(func():
		exit_btn.release_focus()
		DeskTheme.animate_click(exit_btn, Vector2.ONE, 0.08)
		is_polling_active = false
		cbs.cleanup_signals.call()
		if wrm:
			wrm.webrtc_multiplayer.disconnect_room()
		lobby_modal.queue_free()
	)
	
	lobby_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(lobby_modal).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(lobby_modal, "scale", Vector2.ONE * fit_s, 0.3)
