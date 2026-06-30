extends Control

const ChickenRacePhaseClass = preload("res://src/ui/phases/ChickenRacePhase.gd")
const ReportPhaseClass = preload("res://src/ui/phases/ReportPhase.gd")
const DailyLikesPhaseClass = preload("res://src/ui/phases/DailyLikesPhase.gd")
const DayTransitionPhaseClass = preload("res://src/ui/phases/DayTransitionPhase.gd")
const WaitingPhaseClass = preload("res://src/ui/phases/WaitingPhase.gd")

var session: GameSession
var active_phase_node: PhaseBase

var bg_color_rect: ColorRect
var phase_layer: Control

func _ready() -> void:
	bg_color_rect = ColorRect.new()
	bg_color_rect.color = Color(1, 1, 1, 1.0) # Base white just in case
	bg_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color_rect)
	
	var bg_tex = TextureRect.new()
	if ResourceLoader.exists("res://assets/机の背景画像-ノート無し.png"):
		bg_tex.texture = load("res://assets/机の背景画像-ノート無し.png")
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_tex)
	
	phase_layer = Control.new()
	phase_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(phase_layer)
	
	var header_margin = MarginContainer.new()
	header_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_margin.add_theme_constant_override("margin_right", 20)
	header_margin.add_theme_constant_override("margin_top", 20)
	add_child(header_margin)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_END
	header_hbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_theme_constant_override("separation", 15)
	header_margin.add_child(header_hbox)
	
	var hist_btn = Button.new()
	hist_btn.text = "点数履歴"
	hist_btn.add_theme_font_override("font", DeskTheme.get_font())
	hist_btn.pressed.connect(func():
		DeskTheme.animate_click(hist_btn, Vector2.ONE, 0.08)
		HistoryModal.create_and_show(self, session)
	)
	header_hbox.add_child(hist_btn)
	
	var opt_btn = Button.new()
	opt_btn.text = "設定/ルール"
	opt_btn.add_theme_font_override("font", DeskTheme.get_font())
	opt_btn.pressed.connect(func():
		DeskTheme.animate_click(opt_btn, Vector2.ONE, 0.08)
		SettingsModal.create_and_show(self)
	)
	header_hbox.add_child(opt_btn)
	
	var update_header_size = func():
		var viewport_size = get_viewport_rect().size
		var is_port = false
		var rs_scale = 1.0
		if has_node("/root/ResponsiveScaler"):
			var rs = get_node("/root/ResponsiveScaler")
			is_port = rs.is_portrait()
			rs_scale = rs.get_scale()
		else:
			is_port = viewport_size.x < 600
			
		header_hbox.scale = Vector2.ONE
		
		# 画面横幅の約8%〜15%を基準にする
		var ratio = 0.15 if is_port else 0.08
		var btn_w = max(100.0, viewport_size.x * ratio)
		var btn_h = btn_w * 0.35
		var fsize = max(14.0, btn_h * 0.45)
		
		hist_btn.custom_minimum_size = Vector2(btn_w, btn_h)
		hist_btn.add_theme_font_size_override("font_size", int(fsize))
		opt_btn.custom_minimum_size = Vector2(btn_w, btn_h)
		opt_btn.add_theme_font_size_override("font_size", int(fsize))
		
		header_margin.add_theme_constant_override("margin_right", int(20 * rs_scale))
		header_margin.add_theme_constant_override("margin_top", int(20 * rs_scale))
		header_hbox.add_theme_constant_override("separation", int(10 * rs_scale))
		
	get_tree().root.size_changed.connect(update_header_size)
	
	# Need to wait for next frame so header_hbox.size is calculated before setting pivot
	var timer = get_tree().create_timer(0.01)
	timer.timeout.connect(update_header_size)
	
	session = GameSession.new()
	session.start_session()
	
	change_phase(Constants.PHASE_CHICKEN_RACE)

func change_phase(phase_type: String, setup_data: Dictionary = {}) -> void:
	var old_node = active_phase_node
	active_phase_node = null
	
	var target_state = GameSession.SessionPhaseState.LOBBY
	match phase_type:
		Constants.PHASE_CHICKEN_RACE:
			target_state = GameSession.SessionPhaseState.STUDY
		Constants.PHASE_REPORT:
			target_state = GameSession.SessionPhaseState.REPORT
		Constants.PHASE_WAITING:
			target_state = GameSession.SessionPhaseState.WAIT_OTHERS
		Constants.PHASE_DAILY_LIKES:
			target_state = GameSession.SessionPhaseState.DOUBT
		Constants.PHASE_DAY_TRANSITION:
			target_state = GameSession.SessionPhaseState.READY
	if session:
		session.change_state(target_state)

	match phase_type:
		Constants.PHASE_CHICKEN_RACE:
			active_phase_node = ChickenRacePhaseClass.new()
		Constants.PHASE_REPORT:
			active_phase_node = ReportPhaseClass.new()
		Constants.PHASE_DAILY_LIKES:
			active_phase_node = DailyLikesPhaseClass.new()
		Constants.PHASE_DAY_TRANSITION:
			active_phase_node = DayTransitionPhaseClass.new()
		Constants.PHASE_WAITING:
			active_phase_node = WaitingPhaseClass.new()
			
	if active_phase_node:
		active_phase_node.phase_finished.connect(_on_phase_finished.bind(phase_type))
		phase_layer.add_child(active_phase_node)
		active_phase_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		active_phase_node.setup(session, setup_data)
		
		if old_node and old_node.is_inside_tree():
			var tween = create_tween().bind_node(old_node).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(old_node, "modulate:a", 0.0, 0.3)
			tween.tween_callback(func(): old_node.queue_free())
			
			active_phase_node.modulate.a = 0.0
			var in_tween = create_tween().bind_node(active_phase_node).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			in_tween.tween_property(active_phase_node, "modulate:a", 1.0, 0.3).set_delay(0.3)

func _on_phase_finished(result_data: Dictionary, phase_type: String) -> void:
	if result_data.has("next_phase") and result_data["next_phase"] != "":
		change_phase(result_data["next_phase"], result_data)
		return
		
	match phase_type:
		Constants.PHASE_CHICKEN_RACE:
			if session.player_hours_history_today.size() >= session.max_hours_today:
				change_phase(Constants.PHASE_REPORT, {"actual_score": result_data.get("actual_score", 0)})
			else:
				session.current_hour += 1
				change_phase(Constants.PHASE_CHICKEN_RACE)
		Constants.PHASE_REPORT:
			if Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
				var my_id = str(multiplayer.get_unique_id()) if multiplayer.has_multiplayer_peer() else "player"

				var mid_move = {
					"user_id": my_id,
					"username": Global.player_name if Global.player_name != "" else "あなた",
					"day": session.current_day,
					"actual_score": session.player_actual_score_today,
					"declared_score": session.player_declared_score_today,
					"hours_history": session.player_hours_history_today.duplicate(),
					"doubts_made": [],
					"doubts_submitted": false,
					"phase": "mid_day",
					"emote": session.player_emote_today,
					"client_nonce": "%s-%d-mid" % [Global.friend_room_code, session.current_day]
				}
				MatchState.submit_player_action.rpc("declare", mid_move)
				change_phase(Constants.PHASE_WAITING, {"day": session.current_day, "final_wait": false})
			else:
				var setup = result_data.duplicate()
				setup["from_report"] = true
				change_phase(Constants.PHASE_DAILY_LIKES, setup)
				
		Constants.PHASE_DAILY_LIKES:
			session.end_day()
			
			if Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
				if session.current_day > Constants.MAX_DAYS:
					change_phase(Constants.PHASE_WAITING, {"day": Constants.MAX_DAYS, "final_wait": true})
				else:
					change_phase(Constants.PHASE_DAY_TRANSITION)
			else:
				if session.is_game_over():
					Global.active_showdown_results = session.calculate_final_showdown()
					Global.change_scene_with_fade(get_tree(), "res://ResultScene.tscn")
				else:
					change_phase(Constants.PHASE_DAY_TRANSITION)
					
		Constants.PHASE_WAITING:
			var moves = result_data.get("moves", [])
			var prev_moves = result_data.get("prev_moves", [])
			var is_final = result_data.get("final_wait", false)
			
			if is_final or (session.current_day > Constants.MAX_DAYS and moves.size() > 0):
				session.evaluate_friend_day_moves(Constants.MAX_DAYS, moves)
				Global.active_showdown_results = session.calculate_final_showdown()
				Global.change_scene_with_fade(get_tree(), "res://ResultScene.tscn")
			else:
				var target_day = result_data.get("day", session.current_day)
				if target_day > 1 and prev_moves.size() > 0:
					session.evaluate_friend_day_moves(target_day - 1, prev_moves)
					
				session.evaluate_friend_day_moves(target_day, moves)
				change_phase(Constants.PHASE_DAILY_LIKES)

		Constants.PHASE_DAY_TRANSITION:
			change_phase(Constants.PHASE_CHICKEN_RACE)
