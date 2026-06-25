class_name ResultScene
extends Control

const ResultDeskUI = preload("res://src/ui/ResultDeskUI.gd")

var root_layer: Control
var mini_scoreboard_panel: PanelContainer
var mini_scoreboard_hbox: HBoxContainer
var papers_container: Control
var report_container: Control
var actions_container: Control

var showdown_data: Dictionary
var current_step_day: int = 1
var is_revealing: bool = true
var _active_score_labels: Dictionary = {}
var _cumulative_scores: Dictionary = {}

var skip_btn: Button
var share_btn: Button
var play_again_btn: Button
var restart_btn: Button

func _ready() -> void:
	root_layer = Control.new()
	root_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_layer)
	
	ResultDeskUI.build_desk_background(self)
	ResultDeskUI.build_mini_scoreboard(self)
	ResultDeskUI.build_test_papers_container(self)
	ResultDeskUI.build_report_envelope_container(self)
	ResultDeskUI.build_actions_container(self)
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_RESULT)
	
	if Global.is_tutorial_mode:
		PlayerState.is_tutorial_completed = true
	
	var raw_results = Global.get("active_showdown_results")
	if raw_results and not raw_results.is_empty():
		showdown_data = raw_results
	else:
		var dummy_session = GameSession.new()
		dummy_session.start_session()
		for day in range(1, Constants.MAX_DAYS + 1):
			dummy_session.current_day = day
			dummy_session.player_actual_score_today = randi_range(30, 60)
			dummy_session.player_declared_score_today = dummy_session.player_actual_score_today + (10 if randf() < 0.5 else 0)
			dummy_session.player_hours_history_today = [{"draws": 4, "used_items": [], "bursted": false, "score": dummy_session.player_actual_score_today}]
		dummy_session.end_day()
		showdown_data = dummy_session.calculate_final_showdown()
	
	if not showdown_data.has("details"): showdown_data["details"] = {}
	if not showdown_data.has("rankings"): showdown_data["rankings"] = []
	if not showdown_data.has("final_scores"): showdown_data["final_scores"] = {"player": 0}
	
	_init_mini_scoreboard()
	_create_skip_button()
	
	is_revealing = true
	current_step_day = 1
	
	# Slide down the mini scoreboard
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mini_scoreboard_panel, "position:y", 20.0, 0.6)
	tween.tween_callback(func(): reveal_next_day_showdown())

func _init_mini_scoreboard() -> void:
	var final_scores_keys = showdown_data.get("final_scores", {"player": 0}).keys()
	# Sort keys just to be deterministic (Player first, then CPUs)
	var keys = final_scores_keys.duplicate()
	keys.sort()
	if keys.has("player"):
		keys.erase("player")
		keys.insert(0, "player")
		
	for p_id in keys:
		_cumulative_scores[p_id] = 0
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		mini_scoreboard_hbox.add_child(vbox)
		
		var name_lbl = Label.new()
		var bar_color = DeskTheme.COLOR_GREEN if p_id == "player" else Color("3f51b5")
		name_lbl.text = _get_participant_name(p_id)
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
		name_lbl.add_theme_color_override("font_color", bar_color)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)
		
		var score_lbl = Label.new()
		score_lbl.text = "0 点"
		score_lbl.add_theme_font_override("font", DeskTheme.get_font())
		score_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
		score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(score_lbl)
		
		_active_score_labels[p_id] = score_lbl

func _create_skip_button() -> void:
	skip_btn = Button.new()
	skip_btn.text = "結果へスキップ >>"
	skip_btn.custom_minimum_size = Vector2(240, 60)
	skip_btn.add_theme_font_override("font", DeskTheme.get_font())
	skip_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	skip_btn.pressed.connect(_on_skip_pressed)
	
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color(DeskTheme.COLOR_INK, 0.8)
	skip_style.corner_radius_top_left = 6
	skip_style.corner_radius_top_right = 6
	skip_style.corner_radius_bottom_left = 6
	skip_style.corner_radius_bottom_right = 6
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	skip_btn.add_theme_stylebox_override("hover", skip_style)
	skip_btn.add_theme_stylebox_override("pressed", skip_style)
	
	root_layer.add_child(skip_btn)
	var vp_size = get_viewport_rect().size
	skip_btn.position = Vector2(vp_size.x - 264, vp_size.y - 84)

func _get_participant_name(p_id: String) -> String:
	if p_id == "player":
		return Global.player_name if Global.player_name != "" else "あなた"
	if Global.opponent_profiles.has(p_id):
		return Global.opponent_profiles[p_id].get("name", p_id)
	return AIManager.get_cpu_name(p_id)

func reveal_next_day_showdown() -> void:
	if not is_revealing: return
	
	if current_step_day > showdown_data.get("details", {}).size():
		is_revealing = false
		trigger_report_card()
		return
		
	# Clear previous papers
	for child in papers_container.get_children():
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(child, "position:y", child.position.y + 600, 0.3)
		tween.tween_property(child, "modulate:a", 0.0, 0.3)
		tween.parallel()
		tween.tween_callback(func(): if is_instance_valid(child): child.queue_free()).set_delay(0.3)
		
	var day_details = showdown_data["details"][current_step_day]
	var vp_size = get_viewport_rect().size
	var center = vp_size / 2.0
	
	var day_lbl = Label.new()
	day_lbl.text = "第 %d 日目" % current_step_day
	day_lbl.add_theme_font_override("font", DeskTheme.get_font())
	day_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE_LARGE)
	day_lbl.add_theme_color_override("font_color", Color.WHITE)
	day_lbl.position = Vector2(center.x - 100, center.y - 300)
	day_lbl.modulate.a = 0
	papers_container.add_child(day_lbl)
	
	var d_tween = create_tween()
	d_tween.tween_property(day_lbl, "modulate:a", 1.0, 0.2)
	d_tween.tween_property(day_lbl, "modulate:a", 0.0, 0.2).set_delay(1.0)
	d_tween.tween_callback(func(): if is_instance_valid(day_lbl): day_lbl.queue_free()).set_delay(1.2)
	
	var keys = day_details.keys()
	var any_exposed = false
	
	# Layout papers in a 2x2 grid
	var positions = [
		Vector2(center.x - 350, center.y - 120),
		Vector2(center.x + 50, center.y - 120),
		Vector2(center.x - 350, center.y + 150),
		Vector2(center.x + 50, center.y + 150)
	]
	
	var p_idx = 0
	for p_id in keys:
		var info = day_details[p_id]
		var is_exposed = info["is_doubt_exposed"]
		var actual = info["actual"]
		var declared = info["declared"]
		var earned = info.get("base", 0) + info.get("adjustment", 0)
		
		# Update cumulative
		_cumulative_scores[p_id] += earned
		var target_score = _cumulative_scores[p_id]
		
		var paper = PanelContainer.new()
		paper.custom_minimum_size = Vector2(300, 220)
		paper.pivot_offset = Vector2(150, 110)
		
		var style = DeskTheme.create_white_panel()
		paper.add_theme_stylebox_override("panel", style)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		paper.add_child(vbox)
		
		var n_lbl = Label.new()
		n_lbl.text = _get_participant_name(p_id)
		n_lbl.add_theme_font_override("font", DeskTheme.get_font())
		n_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		n_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(n_lbl)
		
		var line = ColorRect.new()
		line.custom_minimum_size = Vector2(0, 2)
		line.color = Color(0,0,0,0.2)
		vbox.add_child(line)
		
		var d_lbl = Label.new()
		d_lbl.text = "申告: %d 点" % declared
		d_lbl.add_theme_font_override("font", DeskTheme.get_font())
		d_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		d_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(d_lbl)
		
		var a_lbl = Label.new()
		a_lbl.text = "実点: %d 点" % actual
		a_lbl.add_theme_font_override("font", DeskTheme.get_font())
		a_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		a_lbl.add_theme_color_override("font_color", Color("b8860b") if declared > actual else Color("2e7d32"))
		a_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(a_lbl)
		
		var stamp_container = Control.new()
		stamp_container.custom_minimum_size = Vector2(0, 50)
		vbox.add_child(stamp_container)
		
		var stamp = Label.new()
		stamp.add_theme_font_override("font", DeskTheme.get_font())
		stamp.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stamp.custom_minimum_size = Vector2(100, 40)
		
		var border_color = Color("6bbf59")
		if declared > actual:
			if is_exposed:
				stamp.text = "嘘バレ！"
				stamp.add_theme_color_override("font_color", Color("ff6b6b"))
				border_color = Color("ff6b6b")
				any_exposed = true
			else:
				stamp.text = "セーフ"
				stamp.add_theme_color_override("font_color", Color("e0b84c"))
				border_color = Color("e0b84c")
		else:
			stamp.text = "正直"
			stamp.add_theme_color_override("font_color", Color("6bbf59"))
			
		stamp.add_theme_stylebox_override("normal", DeskTheme.create_stamp_style(border_color))
		
		stamp.pivot_offset = Vector2(50, 20)
		stamp.scale = Vector2(3.0, 3.0)
		stamp.modulate.a = 0.0
		stamp.position = Vector2(100, 5) # centered roughly
		stamp.rotation_degrees = randf_range(-15, 15)
		stamp_container.add_child(stamp)
		
		papers_container.add_child(paper)
		var pos = positions[p_idx] if p_idx < positions.size() else center
		paper.position = pos + Vector2(0, 500) # Start below
		paper.rotation_degrees = randf_range(-5, 5)
		
		# Animate paper sliding in
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(paper, "position:y", pos.y, 0.4).set_delay(p_idx * 0.1)
		
		# Animate stamp
		var s_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		s_tween.tween_property(stamp, "scale", Vector2.ONE, 0.3).set_delay(0.5 + p_idx * 0.1)
		s_tween.tween_property(stamp, "modulate:a", 1.0, 0.1).set_delay(0.5 + p_idx * 0.1)
		
		if declared > actual and is_exposed:
			s_tween.chain().tween_callback(func():
				DeskTheme.shake_control(paper, 5.0, 0.2)
				var cross1 = Line2D.new()
				cross1.width = 6
				cross1.default_color = Color("ff3333")
				cross1.points = PackedVector2Array([Vector2(20, 20), Vector2(280, 200)])
				paper.add_child(cross1)
				var cross2 = Line2D.new()
				cross2.width = 6
				cross2.default_color = Color("ff3333")
				cross2.points = PackedVector2Array([Vector2(280, 20), Vector2(20, 200)])
				paper.add_child(cross2)
			)
			
		# Animate scoreboard increment
		if _active_score_labels.has(p_id):
			var score_lbl = _active_score_labels[p_id]
			var old_score = target_score - earned
			var inc_tween = create_tween()
			inc_tween.tween_method(func(val: int):
				score_lbl.text = "%d 点" % val
			, old_score, target_score, 0.4).set_delay(0.8)
			
		p_idx += 1
		
	if any_exposed:
		create_tween().tween_callback(func():
			if is_instance_valid(self): DeskTheme.shake_control(root_layer, 6.0, 0.25)
		).set_delay(0.8)
		
	create_tween().tween_callback(func():
		if not is_instance_valid(self) or not is_inside_tree(): return
		if is_revealing:
			current_step_day += 1
			reveal_next_day_showdown()
	).set_delay(2.0)

func _on_skip_pressed() -> void:
	if not is_revealing or skip_btn.disabled: return
	is_revealing = false
	skip_btn.disabled = true
	DeskTheme.animate_click(skip_btn, Vector2.ONE, 0.08)
	
	# Instantly update mini scoreboard to final
	var final_scores = showdown_data.get("final_scores", {})
	for p_id in final_scores.keys():
		if _active_score_labels.has(p_id):
			_active_score_labels[p_id].text = "%d 点" % final_scores[p_id]
			
	create_tween().tween_callback(func(): trigger_report_card()).set_delay(0.1)

func trigger_report_card() -> void:
	if is_instance_valid(skip_btn):
		skip_btn.queue_free()
		
	# Clear papers and mini scoreboard
	var out_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for child in papers_container.get_children():
		out_tween.tween_property(child, "position:y", child.position.y + 600, 0.4)
		out_tween.tween_property(child, "modulate:a", 0.0, 0.4)
	if is_instance_valid(mini_scoreboard_panel):
		out_tween.tween_property(mini_scoreboard_panel, "position:y", -200.0, 0.4)
		out_tween.tween_property(mini_scoreboard_panel, "modulate:a", 0.0, 0.4)
		
	out_tween.chain().tween_callback(func(): _show_final_report())

func _show_final_report() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_se(AudioManager.SE_FANFARE, 0.0, -10.0)
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_RESULT)
	
	var vp_size = get_viewport_rect().size
	
	# The heavy Report Card
	var report = PanelContainer.new()
	report.custom_minimum_size = Vector2(800, 600)
	report.pivot_offset = Vector2(400, 300)
	
	var r_style = StyleBoxFlat.new()
	r_style.bg_color = Color("fffdf8") # high quality paper
	r_style.border_color = Color("b59d7a")
	r_style.border_width_left = 4
	r_style.border_width_right = 4
	r_style.border_width_top = 4
	r_style.border_width_bottom = 4
	r_style.shadow_color = Color(0, 0, 0, 0.2)
	r_style.shadow_size = 20
	r_style.shadow_offset = Vector2(0, 10)
	report.add_theme_stylebox_override("panel", r_style)
	
	report.position = Vector2(vp_size.x/2 - 400, -700) # Start high up
	report_container.add_child(report)
	
	var r_margin = MarginContainer.new()
	r_margin.add_theme_constant_override("margin_left", 40)
	r_margin.add_theme_constant_override("margin_right", 40)
	r_margin.add_theme_constant_override("margin_top", 40)
	r_margin.add_theme_constant_override("margin_bottom", 40)
	report.add_child(r_margin)
	
	var r_vbox = VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 20)
	r_margin.add_child(r_vbox)
	
	var title = Label.new()
	title.text = "学末成績通知表"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_GIANT)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	r_vbox.add_child(title)
	
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 4)
	line.color = DeskTheme.COLOR_INK
	r_vbox.add_child(line)
	
	var rank_container = VBoxContainer.new()
	rank_container.add_theme_constant_override("separation", 15)
	r_vbox.add_child(rank_container)
	
	# Drop animation
	var d_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	d_tween.tween_property(report, "position:y", vp_size.y/2 - 300, 0.6)
	d_tween.tween_callback(func(): DeskTheme.shake_control(root_layer, 8.0, 0.3))
	
	# Reveal ranks 4th -> 1st
	var ranks = showdown_data.get("rankings", []).duplicate()
	ranks.sort_custom(func(a, b):
		if a["score"] != b["score"]: return a["score"] > b["score"]
		if a["bursts"] != b["bursts"]: return a["bursts"] < b["bursts"]
		return a["id"] < b["id"]
	)
	
	var delay = 1.0
	var rank_idx = ranks.size()
	for i in range(ranks.size() - 1, -1, -1):
		var r = ranks[i]
		var rank_lbl = Label.new()
		rank_lbl.text = "[ %d位 ] %s : %d 点" % [i + 1, r["name"], r["score"]]
		rank_lbl.add_theme_font_override("font", DeskTheme.get_font())
		rank_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE)
		
		if r["id"] == "player":
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		else:
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			
		rank_container.add_child(rank_lbl)
		rank_container.move_child(rank_lbl, 0) # prepend so 1st is at top
		
		rank_lbl.modulate.a = 0.0
		rank_lbl.position.x = -50
		
		var r_tween = create_tween().set_parallel(true)
		r_tween.tween_property(rank_lbl, "modulate:a", 1.0, 0.3).set_delay(delay)
		r_tween.tween_property(rank_lbl, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
		
		# If it's the player, do a little emphasis
		if r["id"] == "player":
			r_tween.chain().tween_callback(func():
				DeskTheme.shake_control(rank_lbl, 4.0, 0.2)
			)
			
		delay += 0.8
		
	# Show teacher advice and stamp after ranks
	var t_tween = create_tween()
	t_tween.tween_callback(func(): _show_advice_and_stamp(r_vbox)).set_delay(delay)

func _show_advice_and_stamp(parent_vbox: Control) -> void:
	var advice_box = PanelContainer.new()
	var a_style = DeskTheme.create_sticky_note_style("yellow")
	advice_box.add_theme_stylebox_override("panel", a_style)
	
	var advice_lbl = Label.new()
	advice_lbl.text = "【担任からの一言】\nお疲れ様！次もこの調子で頑張ろう！"
	advice_lbl.add_theme_font_override("font", DeskTheme.get_font())
	advice_lbl.add_theme_font_size_override("font_size", 18)
	advice_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	advice_box.add_child(advice_lbl)
	
	parent_vbox.add_child(advice_box)
	
	advice_box.scale = Vector2(0.1, 0.1)
	advice_box.rotation_degrees = -10
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(advice_box, "scale", Vector2.ONE, 0.4)
	
	var my_score = showdown_data.get("final_scores", {}).get("player", 0)
	if my_score >= 250:
		var hanamaru = TextureRect.new()
		hanamaru.custom_minimum_size = Vector2(300, 300)
		hanamaru.size = Vector2(300, 300)
		hanamaru.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		if FileAccess.file_exists("res://assets/はなまるスタンプ.png"):
			hanamaru.texture = load("res://assets/はなまるスタンプ.png")
		
		report_container.add_child(hanamaru)
		hanamaru.position = Vector2(get_viewport_rect().size.x/2 + 100, get_viewport_rect().size.y/2 - 100)
		hanamaru.pivot_offset = Vector2(150, 150)
		hanamaru.scale = Vector2(4.0, 4.0)
		hanamaru.modulate.a = 0.0
		
		var h_tween = create_tween().set_parallel(true)
		h_tween.tween_property(hanamaru, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(0.5)
		h_tween.tween_property(hanamaru, "modulate:a", 1.0, 0.2).set_delay(0.5)
		h_tween.chain().tween_callback(func():
			DeskTheme.shake_control(root_layer, 10.0, 0.4)
			_spawn_confetti()
		)
		
	create_tween().tween_callback(func(): _show_actions()).set_delay(1.5)

func _show_actions() -> void:
	var act_hbox = HBoxContainer.new()
	act_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	act_hbox.add_theme_constant_override("separation", 40)
	
	share_btn = Button.new()
	share_btn.text = "Xでシェア"
	_setup_stationery_btn(share_btn, "blue")
	share_btn.pressed.connect(_on_share_pressed)
	act_hbox.add_child(share_btn)
	
	play_again_btn = Button.new()
	play_again_btn.text = "もう1回遊ぶ"
	_setup_stationery_btn(play_again_btn, "green")
	play_again_btn.pressed.connect(_on_play_again_pressed)
	act_hbox.add_child(play_again_btn)
	
	restart_btn = Button.new()
	restart_btn.text = "タイトルへ"
	_setup_stationery_btn(restart_btn, "orange")
	restart_btn.pressed.connect(_on_restart_pressed)
	act_hbox.add_child(restart_btn)
	
	actions_container.add_child(act_hbox)
	
	var vp_size = get_viewport_rect().size
	act_hbox.position = Vector2(0, vp_size.y - 140)
	act_hbox.size.x = vp_size.x
	act_hbox.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(act_hbox, "modulate:a", 1.0, 0.5)

func _setup_stationery_btn(btn: Button, color_type: String) -> void:
	btn.custom_minimum_size = Vector2(220, 65)
	btn.add_theme_font_override("font", DeskTheme.get_font())
	btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	
	var style = DeskTheme.create_sticky_note_style(color_type)
	btn.add_theme_stylebox_override("normal", style)
	
	var h_style = style.duplicate()
	h_style.bg_color = h_style.bg_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", h_style)
	
	var p_style = style.duplicate()
	p_style.bg_color = p_style.bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", p_style)

func _on_share_pressed() -> void:
	if share_btn.disabled: return
	share_btn.disabled = true
	DeskTheme.animate_click(share_btn, Vector2.ONE, 0.08)
	ShareCardGenerator.generate_and_copy_share_image(self, showdown_data)
	create_tween().tween_callback(func(): if is_instance_valid(share_btn): share_btn.disabled = false).set_delay(3.0)

func _on_play_again_pressed() -> void:
	if play_again_btn.disabled: return
	play_again_btn.disabled = true
	DeskTheme.animate_click(play_again_btn, Vector2.ONE, 0.08)
	Global.set("active_showdown_results", {})
	create_tween().tween_callback(func(): Global.change_scene_with_fade(get_tree(), "res://Main.tscn")).set_delay(0.2)

func _on_restart_pressed() -> void:
	if restart_btn.disabled: return
	restart_btn.disabled = true
	DeskTheme.animate_click(restart_btn, Vector2.ONE, 0.08)
	Global.set("active_showdown_results", {})
	if get_tree().root.has_node("WebRTCManager"):
		get_tree().root.get_node("WebRTCManager").disconnect_room()
	create_tween().tween_callback(func(): Global.change_scene_with_fade(get_tree(), "res://Title.tscn")).set_delay(0.2)

func _spawn_confetti() -> void:
	var vp_size = get_viewport_rect().size
	var confetti = CPUParticles2D.new()
	confetti.position = Vector2(vp_size.x / 2.0, -20.0)
	confetti.emitting = true
	confetti.amount = 150
	confetti.lifetime = 5.0
	confetti.one_shot = false
	confetti.explosiveness = 0.1
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(vp_size.x / 2.0, 10.0)
	confetti.direction = Vector2(0, 1)
	confetti.spread = 15.0
	confetti.gravity = Vector2(0, 180)
	confetti.initial_velocity_min = 60.0
	confetti.initial_velocity_max = 150.0
	confetti.angular_velocity_min = -120.0
	confetti.angular_velocity_max = 120.0
	confetti.scale_amount_min = 6.0
	confetti.scale_amount_max = 14.0
	confetti.color = Color("ff3333")
	confetti.hue_variation_min = -1.0
	confetti.hue_variation_max = 1.0
	root_layer.add_child(confetti)
	create_tween().tween_callback(func():
		if is_instance_valid(confetti):
			confetti.emitting = false
			create_tween().tween_callback(func(): if is_instance_valid(confetti): confetti.queue_free()).set_delay(confetti.lifetime)
	).set_delay(8.0)
