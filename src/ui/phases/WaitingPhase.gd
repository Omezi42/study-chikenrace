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

	# Layout: Centered smartphone container
	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(main_hbox)
	fit_control_to_viewport(main_hbox, Vector2(1500, 850), Vector2(72, 72), 0.72, true)

	# SMARTPHONE PANEL
	phone_panel = PanelContainer.new()
	phone_panel.custom_minimum_size = Vector2(550, 780)
	phone_panel.pivot_offset = Vector2(275, 390)

	var phone_style = StyleBoxFlat.new()
	phone_style.bg_color = DeskTheme.COLOR_INK
	phone_style.border_color = Color("37474f")
	phone_style.border_width_left = 16
	phone_style.border_width_right = 16
	phone_style.border_width_top = 32
	phone_style.border_width_bottom = 32
	phone_style.corner_radius_top_left = 28
	phone_style.corner_radius_top_right = 28
	phone_style.corner_radius_bottom_left = 28
	phone_style.corner_radius_bottom_right = 28
	phone_panel.add_theme_stylebox_override("panel", phone_style)
	main_hbox.add_child(phone_panel)

	var phone_vbox = VBoxContainer.new()
	phone_vbox.add_theme_constant_override("separation", 24)
	phone_panel.add_child(phone_vbox)

	# Status bar
	var status_bar = Label.new()
	status_bar.text = "16:30  |  チキスタ同期中"
	status_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_bar.add_theme_font_size_override("font_size", 16)
	status_bar.add_theme_color_override("font_color", Color.WHITE)
	phone_vbox.add_child(status_bar)

	# Card inside phone (Mocking app screen)
	var app_card = PanelContainer.new()
	app_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var app_style = StyleBoxFlat.new()
	app_style.bg_color = DeskTheme.COLOR_CRAFT
	app_style.corner_radius_top_left = 8
	app_style.corner_radius_top_right = 8
	app_style.corner_radius_bottom_left = 8
	app_style.corner_radius_bottom_right = 8
	app_card.add_theme_stylebox_override("panel", app_style)
	phone_vbox.add_child(app_card)

	var app_margin = MarginContainer.new()
	app_margin.add_theme_constant_override("margin_left", 24)
	app_margin.add_theme_constant_override("margin_right", 24)
	app_margin.add_theme_constant_override("margin_top", 30)
	app_margin.add_theme_constant_override("margin_bottom", 30)
	app_card.add_child(app_margin)

	app_vbox = VBoxContainer.new()
	app_vbox.add_theme_constant_override("separation", 28)
	app_margin.add_child(app_vbox)

	# Icon indicator (Rotating study-gear/sync icon or pulsating text)
	var indicator_container = CenterContainer.new()
	indicator_container.custom_minimum_size = Vector2(0, 100)
	app_vbox.add_child(indicator_container)

	loading_rect = ColorRect.new()
	loading_rect.color = DeskTheme.COLOR_INK
	loading_rect.custom_minimum_size = Vector2(40, 40)
	loading_rect.pivot_offset = Vector2(20, 20)
	indicator_container.add_child(loading_rect)

	# Rotating animation for loading indicator
	var rot_tween = create_tween().set_loops().set_trans(Tween.TRANS_LINEAR)
	rot_tween.tween_property(loading_rect, "rotation_degrees", 360.0, 1.8)

	# Status message
	status_lbl = Label.new()
	status_lbl.text = "Waiting for everyone to finish..." if not is_final_reveal_wait else "Waiting for final showdown results..."
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_override("font", DeskTheme.get_font())
	status_lbl.add_theme_font_size_override("font_size", 24)
	status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	app_vbox.add_child(status_lbl)

	# Separation line
	var line_ctrl = Control.new()
	line_ctrl.custom_minimum_size = Vector2(0, 2)
	var line_rect = ColorRect.new()
	line_rect.color = Color(DeskTheme.COLOR_INK, 0.15)
	line_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line_ctrl.add_child(line_rect)
	app_vbox.add_child(line_ctrl)

	# Title for list
	var list_title = Label.new()
	list_title.text = "Room Members (Day %d)" % target_day
	list_title.add_theme_font_override("font", DeskTheme.get_font())
	list_title.add_theme_font_size_override("font_size", 20)
	list_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	app_vbox.add_child(list_title)

	# Members list Container
	members_vbox = VBoxContainer.new()
	members_vbox.add_theme_constant_override("separation", 14)
	app_vbox.add_child(members_vbox)

	# Init list with current lobby members
	update_members_ui([])

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

	# Visual entrance slide in
	DeskTheme.animate_entrance(phone_panel, phone_panel.position, Vector2(0, 300), 0.5)

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

		# Row Panel
		var row = PanelContainer.new()
		var row_style = StyleBoxFlat.new()
		row_style.bg_color = Color.WHITE
		row_style.corner_radius_top_left = 6
		row_style.corner_radius_top_right = 6
		row_style.corner_radius_bottom_left = 6
		row_style.corner_radius_bottom_right = 6
		row_style.content_margin_left = 12
		row_style.content_margin_right = 12
		row_style.content_margin_top = 8
		row_style.content_margin_bottom = 8
		row_style.border_color = Color(DeskTheme.COLOR_INK, 0.1)
		row_style.border_width_bottom = 2
		row.add_theme_stylebox_override("panel", row_style)
		members_vbox.add_child(row)

		var hbox = HBoxContainer.new()
		row.add_child(hbox)

		var name_lbl = Label.new()
		name_lbl.text = name_str
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		hbox.add_child(name_lbl)

		var stat_lbl = Label.new()
		stat_lbl.text = status_text
		stat_lbl.add_theme_font_override("font", DeskTheme.get_font())
		stat_lbl.add_theme_font_size_override("font_size", 18)
		stat_lbl.add_theme_color_override("font_color", status_color)
		hbox.add_child(stat_lbl)

func _show_timeout_fallback_button() -> void:
	var btn_name = "TimeoutFallbackButton"
	if app_vbox.has_node(btn_name):
		return

	if Global.friend_is_host:
		var force_btn = Button.new()
		force_btn.name = "ForceProgressButton"
		force_btn.text = "強制進行 (未提出は0点)"
		force_btn.custom_minimum_size = Vector2(280, 50)
		force_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		force_btn.add_theme_font_override("font", DeskTheme.get_font())
		force_btn.add_theme_font_size_override("font_size", 18)
		Global.apply_white_button_style(force_btn)
		force_btn.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		force_btn.pressed.connect(func():
			_on_force_progress_pressed(last_polled_moves)
		)
		app_vbox.add_child(force_btn)
	else:
		var cpu_switch_btn = Button.new()
		cpu_switch_btn.name = "CpuSwitchButton"
		cpu_switch_btn.text = "CPU代替戦で続行"
		cpu_switch_btn.custom_minimum_size = Vector2(280, 50)
		cpu_switch_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cpu_switch_btn.add_theme_font_override("font", DeskTheme.get_font())
		cpu_switch_btn.add_theme_font_size_override("font_size", 18)
		Global.apply_white_button_style(cpu_switch_btn)
		cpu_switch_btn.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		cpu_switch_btn.pressed.connect(func():
			_on_switch_to_cpu_pressed()
		)
		app_vbox.add_child(cpu_switch_btn)

	var fallback_btn = Button.new()
	fallback_btn.name = btn_name
	fallback_btn.text = "タイトルに戻る"
	fallback_btn.custom_minimum_size = Vector2(280, 50)
	fallback_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fallback_btn.add_theme_font_override("font", DeskTheme.get_font())
	fallback_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(fallback_btn)
	fallback_btn.pressed.connect(func():
		if has_node("/root/BackendManager"):
			var bm = get_node("/root/BackendManager")
			if bm.day_moves_polled.is_connected(_on_day_moves_polled):
				bm.day_moves_polled.disconnect(_on_day_moves_polled)
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)
	app_vbox.add_child(fallback_btn)

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
