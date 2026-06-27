class_name WaitingPhase
extends PhaseBase

# UI Controls
var phone_panel: PanelContainer
var status_lbl: Label
var members_vbox: VBoxContainer
var loading_rect: ColorRect
var app_vbox: VBoxContainer

# Polling configuration
var poll_timer: Timer
var target_day: int = 1
var is_final_reveal_wait: bool = false # True if waiting for final day 5 showdown doubts
var current_poll_interval: float = 3.0
var max_poll_interval: float = 12.0
var last_submitted_count: int = 0
var total_poll_time: float = 0.0
var last_polled_moves: Array = []

func _on_setup(setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(1500, 850)
	size = Vector2(1500, 850)

	target_day = setup_data.get("day", session.current_day)
	is_final_reveal_wait = setup_data.get("final_wait", false)

	WaitingUIBuilder.build_layout(self)

	# Connect to MatchState signals
	MatchState.player_action_received.connect(_on_player_action_received)

	# Setup simple fallback/UI update timer (no backend polling, just pulsing the UI)
	poll_timer = Timer.new()
	poll_timer.wait_time = 1.0
	poll_timer.timeout.connect(_on_poll_timeout)
	add_child(poll_timer)
	poll_timer.start()
	
	if has_node("/root/WebRTCManager"):
		var wm = get_node_or_null("/root/WebRTCManager")
		if wm and wm.has_signal("connection_lost") and not wm.connection_lost.is_connected(_on_connection_lost):
			wm.connection_lost.connect(_on_connection_lost)
		if wm and wm.webrtc_multiplayer and wm.webrtc_multiplayer.has_signal("player_disconnected"):
			if not wm.webrtc_multiplayer.player_disconnected.is_connected(_on_peer_disconnected):
				wm.webrtc_multiplayer.player_disconnected.connect(_on_peer_disconnected)

	# Check immediately
	_check_all_actions()

func _exit_tree() -> void:
	if MatchState.player_action_received.is_connected(_on_player_action_received):
		MatchState.player_action_received.disconnect(_on_player_action_received)
	if has_node("/root/WebRTCManager"):
		var wm = get_node_or_null("/root/WebRTCManager")
		if wm and wm.webrtc_multiplayer and wm.webrtc_multiplayer.has_signal("player_disconnected"):
			if wm.webrtc_multiplayer.player_disconnected.is_connected(_on_peer_disconnected):
				wm.webrtc_multiplayer.player_disconnected.disconnect(_on_peer_disconnected)

func _on_peer_disconnected(_id: int) -> void:
	_check_all_actions()

func _on_poll_timeout() -> void:
	# Pulsate loading indicator color slightly
	var pulse = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(loading_rect, "modulate:a", 0.4, 0.4)
	pulse.tween_property(loading_rect, "modulate:a", 1.0, 0.4)
	
	total_poll_time += 1.0
	if total_poll_time >= 90.0:
		poll_timer.stop()
		status_lbl.text = "同期タイムアウト"
		status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		_show_timeout_fallback_button()
		return

func _on_player_action_received(player_id: int, action: String, data: Dictionary) -> void:
	if data.get("day", 1) == target_day:
		_check_all_actions()

func _check_all_actions() -> void:
	var actions = MatchState.current_match_actions.get(target_day, {})
	var prev_actions = MatchState.current_match_actions.get(target_day - 1, {}) if target_day > 1 else {}
	
	var moves = []
	for p_id in actions.keys():
		if is_final_reveal_wait:
			if actions[p_id].has("doubts"):
				moves.append(actions[p_id]["doubts"])
			elif actions[p_id].has("declare"):
				moves.append(actions[p_id]["declare"])
		else:
			if actions[p_id].has("declare"):
				moves.append(actions[p_id]["declare"])
			elif actions[p_id].has("doubts"):
				moves.append(actions[p_id]["doubts"])

	var prev_moves = []
	for p_id in prev_actions.keys():
		if prev_actions[p_id].has("doubts"):
			prev_moves.append(prev_actions[p_id]["doubts"])
		elif prev_actions[p_id].has("declare"):
			prev_moves.append(prev_actions[p_id]["declare"])

	last_polled_moves = moves
	update_members_ui(moves)

	# Gather all user IDs that have submitted moves
	var submitted_user_ids = {}
	var doubts_submitted_ids = {}
	for m in moves:
		var uid = _resolve_player_id(m.get("user_id", ""))
		submitted_user_ids[uid] = true
		if m.get("doubts_submitted", false) or m.get("phase", "") == "doubts":
			doubts_submitted_ids[uid] = true

	var all_done = true
	if Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
		var active_uids = {}
		if multiplayer.has_multiplayer_peer():
			active_uids[str(multiplayer.get_unique_id())] = true
			for p_id in multiplayer.get_peers():
				active_uids[str(p_id)] = true
		if has_node("/root/WebRTCManager"):
			var wm = get_node_or_null("/root/WebRTCManager")
			if wm and wm.webrtc_multiplayer:
				for p in wm.webrtc_multiplayer._participants:
					active_uids[str(p.get("user_id", ""))] = true

		for member in Global.friend_member_list:
			var uid = _resolve_player_id(member.get("user_id", ""))
			var is_cpu = uid.begins_with("cpu_")
			var is_connected = active_uids.has(uid) or is_cpu

			var has_moves = submitted_user_ids.has(uid) or is_cpu or not is_connected
			if not has_moves:
				all_done = false
				break

			if is_final_reveal_wait:
				var has_doubts = doubts_submitted_ids.has(uid) or is_cpu or not is_connected
				if not has_doubts:
					all_done = false
					break
	else:
		# Random matchmaking fallback if needed, or singleplayer mock
		pass

	if all_done:
		poll_timer.stop()
		var final_moves = _fill_missing_moves(moves)
		# Add a slight delay before transitioning
		var t = get_tree().create_timer(0.5)
		t.timeout.connect(func():
			_transition_out(final_moves, prev_moves)
		)

func _transition_out(moves: Array, prev_moves: Array) -> void:
	var tween = create_tween().bind_node(phone_panel).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(phone_panel, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(func():
		finish_phase({"moves": moves, "prev_moves": prev_moves, "final_wait": is_final_reveal_wait, "day": target_day})
	)

func update_members_ui(submitted_moves: Array) -> void:
	# Clear old list
	for child in members_vbox.get_children():
		child.queue_free()

	# Gather submitted list
	var submitted_ids = {}
	var doubts_submitted_ids = {}
	for m in submitted_moves:
		if not (m is Dictionary):
			continue
		var uid = _resolve_player_id(m.get("user_id", ""))
		submitted_ids[uid] = true
		if m.get("doubts_submitted", false) or m.get("phase", "") == "doubts":
			doubts_submitted_ids[uid] = true

	# Render each member
	for member in Global.friend_member_list:
		var uid = _resolve_player_id(member.get("user_id", ""))

		var name_str = member.get("username", "メンバー")

		# Determine status
		var is_submitted = submitted_ids.has(uid) or uid.begins_with("cpu_")
		var is_doubts_done = doubts_submitted_ids.has(uid) or uid.begins_with("cpu_")
		var status_text = "報告まち"
		var status_color = Color(DeskTheme.COLOR_INK, 0.4)

		if not is_final_reveal_wait:
			if is_submitted:
				status_text = "報告完了"
				status_color = DeskTheme.COLOR_GREEN
		else:
			if is_doubts_done:
				status_text = "ダウト申告済"
				status_color = DeskTheme.COLOR_GREEN
			elif is_submitted:
				status_text = "ダウト検討中..."
				status_color = Color("ff9100") # orange

		WaitingUIBuilder.build_member_row(self, name_str, status_text, status_color)

func _show_timeout_fallback_button() -> void:
	WaitingUIBuilder.show_timeout_fallback_buttons(self)

func _on_switch_to_cpu_pressed() -> void:
	_on_force_progress_pressed(last_polled_moves)

func _fill_missing_moves(current_moves: Array) -> Array:
	var simulated_moves = current_moves.duplicate(true)
	var submitted_ids = {}
	for m in simulated_moves:
		var uid = _resolve_player_id(m.get("user_id", ""))
		submitted_ids[uid] = true

	for member in Global.friend_member_list:
		if not (member is Dictionary):
			continue
		var uid = _resolve_player_id(member.get("user_id", ""))
		if not submitted_ids.has(uid):
			var username_str = member.get("username", "Member")
			var dummy_move = {
				"user_id": uid,
				"username": username_str,
				"actual_score": 0,
				"declared_score": 0,
				"hours_history": [{"draws": 0, "used_items": [], "bursted": true, "score": 0}],
				"doubts_made": [],
				"doubts_submitted": is_final_reveal_wait,
				"phase": "doubts" if is_final_reveal_wait else "mid_day"
			}
			simulated_moves.append(dummy_move)
	return simulated_moves

func _on_force_progress_pressed(current_moves: Array) -> void:
	poll_timer.stop()

	var simulated_moves = _fill_missing_moves(current_moves)

	var prev_actions = MatchState.current_match_actions.get(target_day - 1, {}) if target_day > 1 else {}
	var prev_moves = []
	for p_id in prev_actions.keys():
		if prev_actions[p_id].has("doubts"):
			prev_moves.append(prev_actions[p_id]["doubts"])
		elif prev_actions[p_id].has("declare"):
			prev_moves.append(prev_actions[p_id]["declare"])

	_transition_out(simulated_moves, prev_moves)

func _resolve_player_id(uid: String) -> String:
	var my_id = "player"
	if multiplayer.has_multiplayer_peer():
		my_id = str(multiplayer.get_unique_id())

	if uid == "player" and my_id != "player":
		return my_id
	return uid

func _on_connection_lost() -> void:
	if not is_inside_tree():
		return
	status_lbl.text = "通信エラー発生"
	status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	_show_timeout_fallback_button()
