class_name WaitingPhase
extends PhaseBase

# UI Controls
var phone_panel: PanelContainer
var status_lbl: Label
var members_vbox: VBoxContainer
var loading_rect: ColorRect

# Polling configuration
var poll_timer: Timer
var target_day: int = 1
var is_final_reveal_wait: bool = false # True if waiting for final day 5 showdown doubts

func _on_setup(setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(1500, 850)
	size = Vector2(1500, 850)
	
	target_day = setup_data.get("day", session.current_day)
	is_final_reveal_wait = setup_data.get("final_wait", false)
	
	# Layout: Centered smartphone container
	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(main_hbox)
	
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
	
	var app_vbox = VBoxContainer.new()
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
	status_lbl.text = "友達が今日の勉強を\n終えるのを待っています..." if not is_final_reveal_wait else "最終ダウト投票結果の\n同期を待っています..."
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
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
	list_title.text = "👥 ルーム進捗状況 (Day %d)" % target_day
	list_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
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
		
	# Setup polling timer
	poll_timer = Timer.new()
	poll_timer.wait_time = 3.0
	poll_timer.autostart = true
	poll_timer.timeout.connect(_on_poll_timeout)
	add_child(poll_timer)
	
	# Visual entrance slide in
	DeskTheme.animate_entrance(phone_panel, Vector2.ZERO, Vector2(0, 300), 0.5)
	
	# Initial poll immediately
	_on_poll_timeout()

func _exit_tree() -> void:
	# Clean up signal connection
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if bm.day_moves_polled.is_connected(_on_day_moves_polled):
			bm.day_moves_polled.disconnect(_on_day_moves_polled)

func _on_poll_timeout() -> void:
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.poll_day_moves(Global.friend_room_code, target_day)
		
		# Pulsate loading indicator color slightly
		var pulse = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(loading_rect, "modulate:a", 0.4, 0.25)
		pulse.tween_property(loading_rect, "modulate:a", 1.0, 0.25)

func _on_day_moves_polled(success: bool, moves: Array) -> void:
	if not success:
		return
		
	update_members_ui(moves)
	
	# Determine my active ID
	var my_id = "player"
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if bm.logged_in_uuid != "":
			my_id = bm.logged_in_uuid
			
	# Gather all user IDs that have submitted moves
	var submitted_user_ids = {}
	var doubts_submitted_ids = {}
	for m in moves:
		var uid = m.get("user_id", "")
		if uid == "player" and my_id != "player":
			uid = my_id
		submitted_user_ids[uid] = true
		if m.get("doubts_submitted", false):
			doubts_submitted_ids[uid] = true
			
	# Check each participant in our room
	var all_done = true
	for member in Global.friend_member_list:
		var uid = member.get("user_id", "")
		if uid == "player" and my_id != "player":
			uid = my_id
			
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
		
	# Determine my active ID
	var my_id = "player"
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if bm.logged_in_uuid != "":
			my_id = bm.logged_in_uuid
			
	# Gather submitted list
	var submitted_ids = {}
	var doubts_submitted_ids = {}
	for m in submitted_moves:
		var uid = m.get("user_id", "")
		if uid == "player" and my_id != "player":
			uid = my_id
		submitted_ids[uid] = true
		if m.get("doubts_submitted", false):
			doubts_submitted_ids[uid] = true
			
	# Render each member
	for member in Global.friend_member_list:
		var uid = member.get("user_id", "")
		if uid == "player" and my_id != "player":
			uid = my_id
			
		var name_str = member.get("username", "メンバー")
		
		# Determine status
		var is_submitted = submitted_ids.has(uid) or uid.begins_with("cpu_")
		var is_doubts_done = doubts_submitted_ids.has(uid) or uid.begins_with("cpu_")
		
		var status_text = "待ち"
		var status_color = Color(DeskTheme.COLOR_INK, 0.4)
		
		if not is_final_reveal_wait:
			if is_submitted:
				status_text = "完了 ✓"
				status_color = DeskTheme.COLOR_GREEN
		else:
			if is_doubts_done:
				status_text = "完了 ✓"
				status_color = DeskTheme.COLOR_GREEN
			elif is_submitted:
				status_text = "投票中..."
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
		name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		hbox.add_child(name_lbl)
		
		var stat_lbl = Label.new()
		stat_lbl.text = status_text
		stat_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		stat_lbl.add_theme_font_size_override("font_size", 18)
		stat_lbl.add_theme_color_override("font_color", status_color)
		hbox.add_child(stat_lbl)
