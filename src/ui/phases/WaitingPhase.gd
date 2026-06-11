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

	# Connect to Backend polling signals
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.day_moves_polled.connect(_on_day_moves_polled)
		bm.connection_lost.connect(_on_connection_lost)
		bm.reconnect_succeeded.connect(_on_reconnect_succeeded)

	# Setup polling timer
	poll_timer = Timer.new()
	poll_timer.wait_time = current_poll_interval
	poll_timer.one_shot = true
	poll_timer.timeout.connect(_on_poll_timeout)
	add_child(poll_timer)


	# Initial poll immediately
	_on_poll_timeout()

func _exit_tree() -> void:
	# Clean up signal connection
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if bm.day_moves_polled.is_connected(_on_day_moves_polled):
			bm.day_moves_polled.disconnect(_on_day_moves_polled)
		if bm.connection_lost.is_connected(_on_connection_lost):
			bm.connection_lost.disconnect(_on_connection_lost)
		if bm.reconnect_succeeded.is_connected(_on_reconnect_succeeded):
			bm.reconnect_succeeded.disconnect(_on_reconnect_succeeded)

func _on_poll_timeout() -> void:
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.poll_day_moves(Global.friend_room_code, target_day)

		# Pulsate loading indicator color slightly
		var pulse = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(loading_rect, "modulate:a", 0.4, 0.25)
		pulse.tween_property(loading_rect, "modulate:a", 1.0, 0.25)

		total_poll_time += current_poll_interval
		if total_poll_time >= 90.0:
			poll_timer.stop()
			status_lbl.text = "Polling timed out."
			status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
			_show_timeout_fallback_button()
			return

		# Back off the polling interval gradually.
		current_poll_interval = min(current_poll_interval * 1.5, max_poll_interval)
		poll_timer.wait_time = current_poll_interval
		poll_timer.start()

func _on_day_moves_polled(success: bool, moves: Array) -> void:
	if not success:
		return
	if not (moves is Array):
		return

	last_polled_moves = moves

	# 提出状況が変化（提出した他プレイヤーが増加）していた場合、ポーリング間隔を3.0秒に即時リセット
	var current_submits = moves.size()
	if current_submits > last_submitted_count:
		current_poll_interval = 3.0
		poll_timer.stop()
		poll_timer.wait_time = current_poll_interval
		poll_timer.start()

	last_submitted_count = current_submits
	update_members_ui(moves)

	# Gather all user IDs that have submitted moves
	var submitted_user_ids = {}
	var doubts_submitted_ids = {}
	for m in moves:
		if not (m is Dictionary):
			continue
		var uid = _resolve_player_id(m.get("user_id", ""))
		submitted_user_ids[uid] = true
		if m.get("doubts_submitted", false):
			doubts_submitted_ids[uid] = true

	# Check each participant in our room
	var all_done = true
	for member in Global.friend_member_list:
		var uid = _resolve_player_id(member.get("user_id", ""))
		var is_cpu = uid.begins_with("cpu_")

		# 1. Check if study moves are submitted
		var has_moves = submitted_user_ids.has(uid) or is_cpu
		if not has_moves:
			all_done = false
			break

		# 2. If waiting for final showdown doubts, check if doubts are submitted
		if is_final_reveal_wait:
			var has_doubts = doubts_submitted_ids.has(uid) or is_cpu
			if not has_doubts:
				all_done = false
				break

	if all_done:
		poll_timer.stop()
		if has_node("/root/BackendManager"):
			var bm = get_node("/root/BackendManager")
			if bm.day_moves_polled.is_connected(_on_day_moves_polled):
				bm.day_moves_polled.disconnect(_on_day_moves_polled)

			# If I am host, advance the database day state for this room (except for final reveal)
			if Global.friend_is_host and not is_final_reveal_wait:
				bm.advance_friend_room_day(Global.friend_room_code, target_day + 1)

			if target_day > 1 and not is_final_reveal_wait:
				var temp_callable = func(success_prev: bool, prev_moves: Array):
					_transition_out(moves, prev_moves)
				bm.day_moves_polled.connect(temp_callable, CONNECT_ONE_SHOT)
				bm.poll_day_moves(Global.friend_room_code, target_day - 1)
			else:
				_transition_out(moves, [])
		else:
			_transition_out(moves, [])

func _transition_out(moves: Array, prev_moves: Array) -> void:
	var tween = create_tween().bind_node(phone_panel).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(phone_panel, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(func():
		finish_phase({"moves": moves, "prev_moves": prev_moves})
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
		if m.get("doubts_submitted", false):
			doubts_submitted_ids[uid] = true

	# Render each member
	for member in Global.friend_member_list:
		var uid = _resolve_player_id(member.get("user_id", ""))

		var name_str = member.get("username", "メンバー")

		# Determine status
		var is_submitted = submitted_ids.has(uid) or uid.begins_with("cpu_")
		var is_doubts_done = doubts_submitted_ids.has(uid) or uid.begins_with("cpu_")
		var status_text = "Waiting"
		var status_color = Color(DeskTheme.COLOR_INK, 0.4)

		if not is_final_reveal_wait:
			if is_submitted:
				status_text = "Done"
				status_color = DeskTheme.COLOR_GREEN
		else:
			if is_doubts_done:
				status_text = "Done"
				status_color = DeskTheme.COLOR_GREEN
			elif is_submitted:
				status_text = "Reviewing..."
				status_color = Color("ff9100") # orange

		WaitingUIBuilder.build_member_row(self, name_str, status_text, status_color)

func _show_timeout_fallback_button() -> void:
	WaitingUIBuilder.show_timeout_fallback_buttons(self)

func _on_switch_to_cpu_pressed() -> void:
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.is_mock_room = true
		bm.mock_room_code = Global.friend_room_code
		bm.mock_room_status = "playing"
		bm.mock_current_day = target_day
		bm.mock_participants = Global.friend_member_list.duplicate(true)
		
		if not bm.mock_moves.has(target_day):
			bm.mock_moves[target_day] = []
		for m in last_polled_moves:
			bm.mock_moves[target_day].append(m.duplicate(true))
	
	_on_force_progress_pressed(last_polled_moves)

func _on_force_progress_pressed(current_moves: Array) -> void:
	poll_timer.stop()
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if bm.day_moves_polled.is_connected(_on_day_moves_polled):
			bm.day_moves_polled.disconnect(_on_day_moves_polled)

	# Fill in missing members with dummy moves when force progressing.
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
				"doubts_submitted": true
			}
			simulated_moves.append(dummy_move)

	if Global.friend_is_host and not is_final_reveal_wait and has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.advance_friend_room_day(Global.friend_room_code, target_day + 1)

	if target_day > 1 and not is_final_reveal_wait and has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		var temp_callable = func(success_prev: bool, prev_moves: Array):
			_transition_out(simulated_moves, prev_moves)
		bm.day_moves_polled.connect(temp_callable, CONNECT_ONE_SHOT)
		bm.poll_day_moves(Global.friend_room_code, target_day - 1)
	else:
		_transition_out(simulated_moves, [])

func _resolve_player_id(uid: String) -> String:
	var my_id = "player"
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if bm.logged_in_uuid != "":
			my_id = bm.logged_in_uuid

	if uid == "player" and my_id != "player":
		return my_id
	return uid

func _on_connection_lost() -> void:
	if not is_inside_tree():
		return
	status_lbl.text = "接続が切断されました。\n自動再接続中..."
	status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	poll_timer.stop()
	if has_node("/root/BackendManager"):
		get_node("/root/BackendManager").attempt_reconnect()

func _on_reconnect_succeeded() -> void:
	if not is_inside_tree():
		return
	status_lbl.text = "接続復旧しました。\n同期を再開しています..."
	status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	
	# ポーリング間隔をリセットして再開
	current_poll_interval = 3.0
	poll_timer.wait_time = current_poll_interval
	poll_timer.start()
