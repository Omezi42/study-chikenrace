class_name ResultScene
extends Control

var showdown_data: Dictionary
var current_step_day: int = 1
var is_revealing: bool = true
var _active_score_labels: Dictionary = {}
var _cumulative_scores: Dictionary = {}

var root_layer: Control
var main_vbox: VBoxContainer
var top_panel: PanelContainer
var score_hbox: HBoxContainer
var scroll_container: ScrollContainer
var days_vbox: VBoxContainer
var actions_container: MarginContainer

var skip_btn: Button
var share_btn: Button
var restart_btn: Button

var _main_scroll_margin: MarginContainer
var _active_report_margin: MarginContainer
var _details_modal_margin: MarginContainer
var _details_day_grids: Array = []

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	root_layer = Control.new()
	root_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_layer)
	
	_build_background()
	_build_main_layout()
	
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
	
	create_tween().tween_callback(func(): reveal_next_day_showdown()).set_delay(0.5)

func _build_background() -> void:
	var desk_bg = ColorRect.new()
	desk_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desk_bg.color = Color("b58b66")
	root_layer.add_child(desk_bg)
	
	var vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.02, 0.01, 0.0, 0.2)
	root_layer.add_child(vignette)

func _on_viewport_size_changed() -> void:
	var vp_size = get_viewport_rect().size
	if vp_size.x == 0:
		vp_size = Vector2(1500, 850)
	var is_port = vp_size.x < vp_size.y or vp_size.x < 800
	
	if is_instance_valid(main_vbox):
		var base_w = 540.0 if is_port else 1150.0
		var base_h = 960.0 if is_port else 700.0
		var s = clamp(min(vp_size.x / base_w, vp_size.y / base_h), 0.5, 3.0)
		main_vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		main_vbox.pivot_offset = Vector2.ZERO
		main_vbox.scale = Vector2.ONE * s
		var actual_size = vp_size / s
		main_vbox.custom_minimum_size = actual_size
		main_vbox.size = actual_size
		
	if is_instance_valid(_main_scroll_margin):
		if is_port:
			_main_scroll_margin.add_theme_constant_override("margin_left", 20)
			_main_scroll_margin.add_theme_constant_override("margin_right", 20)
		else:
			var w_margin = max(20, int((vp_size.x - 850) / 2.0))
			_main_scroll_margin.add_theme_constant_override("margin_left", w_margin)
			_main_scroll_margin.add_theme_constant_override("margin_right", w_margin)
			
	if is_instance_valid(_active_report_margin):
		var base_w = 540.0 if is_port else 1150.0
		var base_h = 960.0 if is_port else 700.0
		var s = clamp(min(vp_size.x / base_w, vp_size.y / base_h), 0.5, 3.0)
		_active_report_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_active_report_margin.pivot_offset = Vector2.ZERO
		_active_report_margin.scale = Vector2.ONE * s
		var actual_size = vp_size / s
		_active_report_margin.custom_minimum_size = actual_size
		_active_report_margin.size = actual_size

		if is_port:
			_active_report_margin.add_theme_constant_override("margin_left", 20)
			_active_report_margin.add_theme_constant_override("margin_right", 20)
		else:
			var w_margin = max(20, int((actual_size.x - 800) / 2.0))
			_active_report_margin.add_theme_constant_override("margin_left", w_margin)
			_active_report_margin.add_theme_constant_override("margin_right", w_margin)
			
	if is_instance_valid(_details_modal_margin):
		var base_w = 540.0 if is_port else 1150.0
		var base_h = 960.0 if is_port else 700.0
		var s = clamp(min(vp_size.x / base_w, vp_size.y / base_h), 0.5, 3.0)
		_details_modal_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_details_modal_margin.pivot_offset = Vector2.ZERO
		_details_modal_margin.scale = Vector2.ONE * s
		var actual_size = vp_size / s
		_details_modal_margin.custom_minimum_size = actual_size
		_details_modal_margin.size = actual_size

		if is_port:
			_details_modal_margin.add_theme_constant_override("margin_left", 15)
			_details_modal_margin.add_theme_constant_override("margin_right", 15)
			_details_modal_margin.add_theme_constant_override("margin_top", 30)
			_details_modal_margin.add_theme_constant_override("margin_bottom", 30)
			for g in _details_day_grids:
				if is_instance_valid(g): g.columns = 1
		else:
			var w_margin = max(20, int((actual_size.x - 1050) / 2.0))
			var h_margin = max(30, int((actual_size.y - 750) / 2.0))
			_details_modal_margin.add_theme_constant_override("margin_left", w_margin)
			_details_modal_margin.add_theme_constant_override("margin_right", w_margin)
			_details_modal_margin.add_theme_constant_override("margin_top", h_margin)
			_details_modal_margin.add_theme_constant_override("margin_bottom", h_margin)
			for g in _details_day_grids:
				if is_instance_valid(g): g.columns = 2

func _build_main_layout() -> void:
	main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_layer.add_child(main_vbox)
	
	# Top Panel
	top_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("1e3d2f")
	style.border_color = Color("5c3f25")
	style.border_width_bottom = 6
	top_panel.add_theme_stylebox_override("panel", style)
	main_vbox.add_child(top_panel)
	
	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 15)
	top_margin.add_theme_constant_override("margin_right", 15)
	top_margin.add_theme_constant_override("margin_top", 15)
	top_margin.add_theme_constant_override("margin_bottom", 15)
	top_panel.add_child(top_margin)
	
	var top_vbox = VBoxContainer.new()
	top_margin.add_child(top_vbox)
	
	var title = Label.new()
	title.text = "累計獲得点数"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
	top_vbox.add_child(title)
	
	score_hbox = HBoxContainer.new()
	score_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	score_hbox.add_theme_constant_override("separation", 20)
	top_vbox.add_child(score_hbox)
	
	# Scrollable Middle
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll_container)
	
	_main_scroll_margin = MarginContainer.new()
	_main_scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_scroll_margin.add_theme_constant_override("margin_top", 20)
	_main_scroll_margin.add_theme_constant_override("margin_bottom", 120)
	scroll_container.add_child(_main_scroll_margin)
	
	days_vbox = VBoxContainer.new()
	days_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	days_vbox.add_theme_constant_override("separation", 30)
	_main_scroll_margin.add_child(days_vbox)
	
	_on_viewport_size_changed()
	
	actions_container = MarginContainer.new()
	actions_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	actions_container.add_theme_constant_override("margin_left", 20)
	actions_container.add_theme_constant_override("margin_right", 20)
	actions_container.add_theme_constant_override("margin_bottom", 20)
	actions_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root_layer.add_child(actions_container)

func _init_mini_scoreboard() -> void:
	var final_scores_keys = showdown_data.get("final_scores", {"player": 0}).keys()
	var keys = final_scores_keys.duplicate()
	keys.sort()
	if keys.has("player"):
		keys.erase("player")
		keys.insert(0, "player")
		
	for p_id in keys:
		_cumulative_scores[p_id] = 0
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		score_hbox.add_child(vbox)
		
		var name_lbl = Label.new()
		var bar_color = DeskTheme.COLOR_GREEN if p_id == "player" else Color("3f51b5")
		name_lbl.text = _get_participant_name(p_id)
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", bar_color)
		vbox.add_child(name_lbl)
		
		var score_lbl = Label.new()
		score_lbl.text = "0"
		score_lbl.add_theme_font_override("font", DeskTheme.get_font())
		score_lbl.add_theme_font_size_override("font_size", 24)
		score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		vbox.add_child(score_lbl)
		_active_score_labels[p_id] = score_lbl

func _create_skip_button() -> void:
	skip_btn = Button.new()
	skip_btn.text = "結果へスキップ >>"
	skip_btn.custom_minimum_size = Vector2(180, 50)
	skip_btn.add_theme_font_override("font", DeskTheme.get_font())
	skip_btn.add_theme_font_size_override("font_size", 16)
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
	
	var m = MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_bottom", 20)
	m.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	var h = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	m.add_child(h)
	h.add_child(skip_btn)
	
	root_layer.add_child(m)
	skip_btn.set_meta("parent_margin", m)

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
		
	var day_details = showdown_data["details"][current_step_day]
	
	var day_panel = PanelContainer.new()
	var d_style = StyleBoxFlat.new()
	d_style.bg_color = Color(1,1,1,0.95)
	d_style.corner_radius_top_left = 12
	d_style.corner_radius_top_right = 12
	d_style.corner_radius_bottom_left = 12
	d_style.corner_radius_bottom_right = 12
	d_style.shadow_color = Color(0,0,0,0.1)
	d_style.shadow_size = 6
	day_panel.add_theme_stylebox_override("panel", d_style)
	day_panel.modulate.a = 0
	days_vbox.add_child(day_panel)
	
	var d_margin = MarginContainer.new()
	d_margin.add_theme_constant_override("margin_left", 15)
	d_margin.add_theme_constant_override("margin_right", 15)
	d_margin.add_theme_constant_override("margin_top", 15)
	d_margin.add_theme_constant_override("margin_bottom", 15)
	day_panel.add_child(d_margin)
	
	var d_vbox = VBoxContainer.new()
	d_vbox.add_theme_constant_override("separation", 10)
	d_margin.add_child(d_vbox)
	
	var title = Label.new()
	title.text = "■ 第 %d 日目" % current_step_day
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	d_vbox.add_child(title)
	
	var line = ColorRect.new()
	line.custom_minimum_size.y = 2
	line.color = Color("#dddddd")
	d_vbox.add_child(line)
	
	var any_exposed = false
	var keys = day_details.keys()
	var sorted_keys = keys.duplicate()
	if sorted_keys.has("player"):
		sorted_keys.erase("player")
		sorted_keys.insert(0, "player")
		
	for p_id in sorted_keys:
		var info = day_details[p_id]
		var is_exposed = info["is_doubt_exposed"]
		var actual = info["actual"]
		var declared = info["declared"]
		var earned = info.get("base", 0) + info.get("adjustment", 0)
		
		_cumulative_scores[p_id] += earned
		var target_score = _cumulative_scores[p_id]
		
		var p_hbox = HBoxContainer.new()
		p_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d_vbox.add_child(p_hbox)
		
		var n_lbl = Label.new()
		n_lbl.text = _get_participant_name(p_id)
		n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n_lbl.add_theme_font_override("font", DeskTheme.get_font())
		n_lbl.add_theme_font_size_override("font_size", 16)
		n_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN if p_id == "player" else DeskTheme.COLOR_INK)
		p_hbox.add_child(n_lbl)
		
		var score_lbl = Label.new()
		score_lbl.text = "%d点 → %d点" % [declared, actual]
		score_lbl.add_theme_font_override("font", DeskTheme.get_font())
		score_lbl.add_theme_font_size_override("font_size", 14)
		score_lbl.add_theme_color_override("font_color", Color("b8860b") if declared > actual else Color("2e7d32"))
		p_hbox.add_child(score_lbl)
		
		var stamp_lbl = Label.new()
		stamp_lbl.add_theme_font_override("font", DeskTheme.get_font())
		stamp_lbl.add_theme_font_size_override("font_size", 14)
		if declared > actual:
			if is_exposed:
				stamp_lbl.text = "[嘘バレ]"
				stamp_lbl.add_theme_color_override("font_color", Color("ff6b6b"))
				any_exposed = true
			else:
				stamp_lbl.text = "[セーフ]"
				stamp_lbl.add_theme_color_override("font_color", Color("e0b84c"))
		else:
			stamp_lbl.text = "[正直]"
			stamp_lbl.add_theme_color_override("font_color", Color("6bbf59"))
		p_hbox.add_child(stamp_lbl)
		
		if _active_score_labels.has(p_id):
			var s_lbl = _active_score_labels[p_id]
			var old_score = target_score - earned
			var inc_tween = create_tween()
			inc_tween.tween_method(func(val: int):
				s_lbl.text = "%d" % val
			, old_score, target_score, 0.4).set_delay(0.5)

	var p_tween = create_tween()
	p_tween.tween_property(day_panel, "modulate:a", 1.0, 0.3)
	
	p_tween.tween_callback(func():
		var max_scroll = scroll_container.get_v_scroll_bar().max_value
		create_tween().tween_property(scroll_container, "scroll_vertical", max_scroll, 0.3)
	).set_delay(0.1)

	if any_exposed:
		create_tween().tween_callback(func():
			if is_instance_valid(self): DeskTheme.shake_control(root_layer, 5.0, 0.2)
		).set_delay(0.5)
		
	create_tween().tween_callback(func():
		if not is_instance_valid(self) or not is_inside_tree(): return
		if is_revealing:
			current_step_day += 1
			reveal_next_day_showdown()
	).set_delay(1.5)

func _on_skip_pressed() -> void:
	if not is_revealing or skip_btn.disabled: return
	is_revealing = false
	skip_btn.disabled = true
	DeskTheme.animate_click(skip_btn, Vector2.ONE, 0.08)
	
	var final_scores = showdown_data.get("final_scores", {})
	for p_id in final_scores.keys():
		if _active_score_labels.has(p_id):
			_active_score_labels[p_id].text = "%d" % final_scores[p_id]
			
	create_tween().tween_callback(func(): trigger_report_card()).set_delay(0.1)

func trigger_report_card() -> void:
	if is_instance_valid(skip_btn):
		if skip_btn.has_meta("parent_margin"):
			skip_btn.get_meta("parent_margin").queue_free()
		else:
			skip_btn.queue_free()
	_show_final_report()

func _show_final_report() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_RESULT)
		
	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0,0,0,0.6)
	overlay.modulate.a = 0
	root_layer.add_child(overlay)
	
	var tw_bg = create_tween()
	tw_bg.tween_property(overlay, "modulate:a", 1.0, 0.3)
	
	_active_report_margin = MarginContainer.new()
	_active_report_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(_active_report_margin)

	var s_container = ScrollContainer.new()
	s_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_active_report_margin.add_child(s_container)
	
	var report_margin = MarginContainer.new()
	report_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_margin.add_theme_constant_override("margin_top", 40)
	report_margin.add_theme_constant_override("margin_bottom", 40)
	s_container.add_child(report_margin)
	
	var report = PanelContainer.new()
	report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var r_style = StyleBoxFlat.new()
	r_style.bg_color = Color("fffdf8")
	r_style.border_color = Color("b59d7a")
	r_style.border_width_left = 4
	r_style.border_width_right = 4
	r_style.border_width_top = 4
	r_style.border_width_bottom = 4
	r_style.corner_radius_top_left = 8
	r_style.corner_radius_top_right = 8
	r_style.corner_radius_bottom_left = 8
	r_style.corner_radius_bottom_right = 8
	report.add_theme_stylebox_override("panel", r_style)
	report_margin.add_child(report)
	
	_on_viewport_size_changed()
	
	var p_margin = MarginContainer.new()
	p_margin.add_theme_constant_override("margin_left", 20)
	p_margin.add_theme_constant_override("margin_right", 20)
	p_margin.add_theme_constant_override("margin_top", 30)
	p_margin.add_theme_constant_override("margin_bottom", 30)
	report.add_child(p_margin)
	
	var r_vbox = VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 20)
	p_margin.add_child(r_vbox)
	
	var title = Label.new()
	title.text = "学末成績通知表"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	r_vbox.add_child(title)
	
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 4)
	line.color = DeskTheme.COLOR_INK
	r_vbox.add_child(line)
	
	var rank_container = VBoxContainer.new()
	rank_container.add_theme_constant_override("separation", 15)
	r_vbox.add_child(rank_container)
	
	var ranks = showdown_data.get("rankings", []).duplicate()
	ranks.sort_custom(func(a, b):
		if a["score"] != b["score"]: return a["score"] > b["score"]
		if a["bursts"] != b["bursts"]: return a["bursts"] < b["bursts"]
		return a["id"] < b["id"]
	)
	
	var delay = 0.5
	for i in range(ranks.size() - 1, -1, -1):
		var r = ranks[i]
		var rank_lbl = Label.new()
		rank_lbl.text = "%d位: %s (%d点)" % [i + 1, r["name"], r["score"]]
		rank_lbl.add_theme_font_override("font", DeskTheme.get_font())
		rank_lbl.add_theme_font_size_override("font_size", 20)
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if r["id"] == "player":
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		else:
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			
		rank_container.add_child(rank_lbl)
		rank_container.move_child(rank_lbl, 0)
		
		rank_lbl.modulate.a = 0.0
		var r_tween = create_tween()
		r_tween.tween_property(rank_lbl, "modulate:a", 1.0, 0.3).set_delay(delay)
		
		create_tween().tween_callback(func():
			if has_node("/root/AudioManager"):
				if i == 0: get_node("/root/AudioManager").play_se(AudioManager.SE_FANFARE, 0.0, -10.0)
				else: get_node("/root/AudioManager").play_se(AudioManager.SE_PLACE)
		).set_delay(delay)
		
		delay += 0.8
		
	var t_tween = create_tween()
	t_tween.tween_callback(func(): _show_advice_and_stamp(r_vbox, overlay)).set_delay(delay)

func _show_advice_and_stamp(parent_vbox: Control, overlay: Control) -> void:
	var advice_box = PanelContainer.new()
	var a_style = DeskTheme.create_sticky_note_style("yellow")
	advice_box.add_theme_stylebox_override("panel", a_style)
	
	var advice_lbl = Label.new()
	advice_lbl.text = "【担任からの一言】\nお疲れ様！次もこの調子で頑張ろう！"
	advice_lbl.add_theme_font_override("font", DeskTheme.get_font())
	advice_lbl.add_theme_font_size_override("font_size", 16)
	advice_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	advice_box.add_child(advice_lbl)
	
	parent_vbox.add_child(advice_box)
	
	advice_box.scale = Vector2(0.1, 0.1)
	advice_box.rotation_degrees = -5
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(advice_box, "scale", Vector2.ONE, 0.4)
	
	var my_score = showdown_data.get("final_scores", {}).get("player", 0)
	if my_score >= 250:
		var hanamaru = TextureRect.new()
		hanamaru.custom_minimum_size = Vector2(150, 150)
		hanamaru.size = Vector2(150, 150)
		hanamaru.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		if FileAccess.file_exists("res://assets/はなまるスタンプ.png"):
			hanamaru.texture = load("res://assets/はなまるスタンプ.png")
		
		overlay.add_child(hanamaru)
		var vp_size = get_viewport_rect().size
		hanamaru.position = Vector2(vp_size.x / 2.0, vp_size.y / 2.0 + 50)
		hanamaru.pivot_offset = Vector2(75, 75)
		hanamaru.scale = Vector2(4.0, 4.0)
		hanamaru.modulate.a = 0.0
		
		var h_tween = create_tween().set_parallel(true)
		h_tween.tween_property(hanamaru, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(0.5)
		h_tween.tween_property(hanamaru, "modulate:a", 1.0, 0.2).set_delay(0.5)
		h_tween.chain().tween_callback(func():
			DeskTheme.shake_control(root_layer, 8.0, 0.4)
			_spawn_confetti()
		)
		
	create_tween().tween_callback(func(): _show_actions(parent_vbox)).set_delay(1.5)

func _show_actions(parent_container: Control) -> void:
	var acts_vbox = VBoxContainer.new()
	acts_vbox.add_theme_constant_override("separation", 15)
	
	var acts_margin = MarginContainer.new()
	acts_margin.add_theme_constant_override("margin_top", 20)
	acts_margin.add_theme_constant_override("margin_bottom", 20)
	acts_margin.add_child(acts_vbox)
	parent_container.add_child(acts_margin)
	
	share_btn = Button.new()
	share_btn.text = "Xでシェア"
	_setup_stationery_btn(share_btn, "blue")
	share_btn.pressed.connect(_on_share_pressed)
	acts_vbox.add_child(share_btn)
	
	var details_btn = Button.new()
	details_btn.text = "詳細を見る"
	_setup_stationery_btn(details_btn, "yellow")
	details_btn.pressed.connect(_show_details_modal)
	acts_vbox.add_child(details_btn)
	
	restart_btn = Button.new()
	if Global.game_mode == Constants.MODE_FRIEND:
		restart_btn.text = "ルームへ戻る"
	else:
		restart_btn.text = "タイトルへ"
	_setup_stationery_btn(restart_btn, "orange")
	restart_btn.pressed.connect(_on_restart_pressed)
	acts_vbox.add_child(restart_btn)
	
	acts_margin.modulate.a = 0.0
	create_tween().tween_property(acts_margin, "modulate:a", 1.0, 0.5)

func _setup_stationery_btn(btn: Button, color_type: String) -> void:
	btn.custom_minimum_size = Vector2(0, 55)
	btn.add_theme_font_override("font", DeskTheme.get_font())
	btn.add_theme_font_size_override("font_size", 16)
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

func _on_restart_pressed() -> void:
	if restart_btn.disabled: return
	restart_btn.disabled = true
	DeskTheme.animate_click(restart_btn, Vector2.ONE, 0.08)
	Global.set("active_showdown_results", {})
	
	if Global.game_mode == Constants.MODE_FRIEND:
		Global.return_to_friend_lobby = true
	else:
		if get_tree().root.has_node("WebRTCManager"):
			get_tree().root.get_node("WebRTCManager").disconnect_room()
			
	create_tween().tween_callback(func(): Global.change_scene_with_fade(get_tree(), "res://Title.tscn")).set_delay(0.2)

func _spawn_confetti() -> void:
	var vp_size = get_viewport_rect().size
	var confetti = CPUParticles2D.new()
	confetti.position = Vector2(vp_size.x / 2.0, -20.0)
	confetti.emitting = true
	confetti.amount = 100
	confetti.lifetime = 4.0
	confetti.one_shot = false
	confetti.explosiveness = 0.1
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(vp_size.x / 2.0, 10.0)
	confetti.direction = Vector2(0, 1)
	confetti.spread = 15.0
	confetti.gravity = Vector2(0, 180)
	confetti.initial_velocity_min = 60.0
	confetti.initial_velocity_max = 120.0
	confetti.angular_velocity_min = -120.0
	confetti.angular_velocity_max = 120.0
	confetti.scale_amount_min = 5.0
	confetti.scale_amount_max = 10.0
	confetti.color = Color("ff3333")
	confetti.hue_variation_min = -1.0
	confetti.hue_variation_max = 1.0
	root_layer.add_child(confetti)
	create_tween().tween_callback(func():
		if is_instance_valid(confetti):
			confetti.emitting = false
			create_tween().tween_callback(func(): if is_instance_valid(confetti): confetti.queue_free()).set_delay(confetti.lifetime)
	).set_delay(6.0)

func _show_details_modal() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_se(AudioManager.SE_WHOOSH)
		
	var modal_bg = ColorRect.new()
	modal_bg.color = Color(0,0,0,0.8)
	modal_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal_bg)
	
	_details_modal_margin = MarginContainer.new()
	_details_modal_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_bg.add_child(_details_modal_margin)
	
	_details_day_grids.clear()
	
	var panel = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color("#ffffff")
	p_style.corner_radius_top_left = 12
	p_style.corner_radius_top_right = 12
	p_style.corner_radius_bottom_left = 12
	p_style.corner_radius_bottom_right = 12
	p_style.shadow_color = Color(0,0,0,0.3)
	p_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", p_style)
	_details_modal_margin.add_child(panel)
	
	var main_vbox = VBoxContainer.new()
	panel.add_child(main_vbox)
	
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 15)
	header_margin.add_theme_constant_override("margin_right", 15)
	header_margin.add_theme_constant_override("margin_top", 15)
	header_margin.add_theme_constant_override("margin_bottom", 10)
	main_vbox.add_child(header_margin)
	
	var header_hbox = HBoxContainer.new()
	header_margin.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "詳細レポート"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	header_hbox.add_child(title)
	
	var close_icon = Button.new()
	close_icon.text = "×"
	close_icon.flat = true
	close_icon.add_theme_font_override("font", DeskTheme.get_font())
	close_icon.add_theme_font_size_override("font_size", 24)
	close_icon.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	header_hbox.add_child(close_icon)
	
	var line = ColorRect.new()
	line.custom_minimum_size.y = 2
	line.color = Color("#dddddd")
	main_vbox.add_child(line)
	
	var tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tab_style = StyleBoxFlat.new()
	tab_style.bg_color = Color.TRANSPARENT
	tab_container.add_theme_stylebox_override("panel", tab_style)
	tab_container.add_theme_font_override("font", DeskTheme.get_font())
	tab_container.add_theme_font_size_override("font_size", 14)
	
	var t_sel = StyleBoxFlat.new()
	t_sel.bg_color = Color.TRANSPARENT
	t_sel.border_width_bottom = 3
	t_sel.border_color = DeskTheme.COLOR_INK
	t_sel.content_margin_left = 12
	t_sel.content_margin_right = 12
	t_sel.content_margin_top = 8
	t_sel.content_margin_bottom = 8
	tab_container.add_theme_stylebox_override("tab_selected", t_sel)
	
	var t_unsel = StyleBoxFlat.new()
	t_unsel.bg_color = Color.TRANSPARENT
	t_unsel.border_width_bottom = 3
	t_unsel.border_color = Color.TRANSPARENT
	t_unsel.content_margin_left = 12
	t_unsel.content_margin_right = 12
	t_unsel.content_margin_top = 8
	t_unsel.content_margin_bottom = 8
	tab_container.add_theme_stylebox_override("tab_unselected", t_unsel)
	tab_container.add_theme_color_override("font_selected_color", DeskTheme.COLOR_INK)
	tab_container.add_theme_color_override("font_unselected_color", Color.GRAY)
	main_vbox.add_child(tab_container)
	
	var details = showdown_data.get("details", {})
	for day in range(1, Constants.MAX_DAYS + 1):
		if not details.has(day): continue
		var day_data = details[day]
		
		var d_scroll = ScrollContainer.new()
		d_scroll.name = "%d日目" % day
		d_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tab_container.add_child(d_scroll)
		
		var d_margin = MarginContainer.new()
		d_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d_margin.add_theme_constant_override("margin_left", 15)
		d_margin.add_theme_constant_override("margin_right", 15)
		d_margin.add_theme_constant_override("margin_top", 15)
		d_margin.add_theme_constant_override("margin_bottom", 15)
		d_scroll.add_child(d_margin)
		
		var grid = GridContainer.new()
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 20)
		grid.add_theme_constant_override("v_separation", 20)
		d_margin.add_child(grid)
		_details_day_grids.append(grid)
		
		var sorted_keys = day_data.keys()
		if sorted_keys.has("player"):
			sorted_keys.erase("player")
			sorted_keys.insert(0, "player")
			
		for p_id in sorted_keys:
			var info = day_data[p_id]
			var card = PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var c_style = StyleBoxFlat.new()
			c_style.bg_color = Color("#f8f8f8")
			c_style.corner_radius_top_left = 10
			c_style.corner_radius_top_right = 10
			c_style.corner_radius_bottom_left = 10
			c_style.corner_radius_bottom_right = 10
			c_style.border_width_top = 6
			c_style.border_color = DeskTheme.COLOR_GREEN if p_id == "player" else DeskTheme.COLOR_MAHOGANY
			c_style.shadow_color = Color(0,0,0,0.05)
			c_style.shadow_size = 4
			c_style.shadow_offset = Vector2(0, 2)
			card.add_theme_stylebox_override("panel", c_style)
			grid.add_child(card)
			
			var c_margin = MarginContainer.new()
			c_margin.add_theme_constant_override("margin_left", 18)
			c_margin.add_theme_constant_override("margin_right", 18)
			c_margin.add_theme_constant_override("margin_top", 15)
			c_margin.add_theme_constant_override("margin_bottom", 18)
			card.add_child(c_margin)
			
			var c_vbox = VBoxContainer.new()
			c_vbox.add_theme_constant_override("separation", 10)
			c_margin.add_child(c_vbox)
			
			var card_header = HBoxContainer.new()
			c_vbox.add_child(card_header)
			
			var n_lbl = Label.new()
			var prefix = "プレイヤー: " if p_id == "player" else "ライバル: "
			n_lbl.text = prefix + _get_participant_name(p_id)
			n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n_lbl.add_theme_font_override("font", DeskTheme.get_font())
			n_lbl.add_theme_font_size_override("font_size", 18)
			n_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			card_header.add_child(n_lbl)
			
			var badge = Label.new()
			badge.add_theme_font_override("font", DeskTheme.get_font())
			badge.add_theme_font_size_override("font_size", 12)
			var b_style = StyleBoxFlat.new()
			b_style.corner_radius_top_left = 4
			b_style.corner_radius_top_right = 4
			b_style.corner_radius_bottom_left = 4
			b_style.corner_radius_bottom_right = 4
			b_style.content_margin_left = 6
			b_style.content_margin_right = 6
			b_style.content_margin_top = 2
			b_style.content_margin_bottom = 2
			
			var declared = info.get("declared", 0)
			var actual = info.get("actual", 0)
			if declared > actual:
				if info.get("is_doubt_exposed", false):
					badge.text = "嘘バレ！"
					b_style.bg_color = Color("ff6b6b")
				else:
					badge.text = "嘘成功 (回避)"
					b_style.bg_color = Color("e0b84c")
			else:
				badge.text = "正直"
				b_style.bg_color = Color("6bbf59")
				
			badge.add_theme_stylebox_override("normal", b_style)
			badge.add_theme_color_override("font_color", Color.WHITE)
			card_header.add_child(badge)
			
			var sep = ColorRect.new()
			sep.custom_minimum_size.y = 1
			sep.color = Color("#dddddd")
			c_vbox.add_child(sep)
			
			var score_hbox = HBoxContainer.new()
			c_vbox.add_child(score_hbox)
			
			var score_lbl = Label.new()
			score_lbl.text = "申告: %d点 / 実点: %d点" % [declared, actual]
			score_lbl.add_theme_font_override("font", DeskTheme.get_font())
			score_lbl.add_theme_font_size_override("font_size", 16)
			score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			score_hbox.add_child(score_lbl)
			
			var bluff_amount = info.get("bluff_amount", 0)
			if bluff_amount > 0:
				var bluff_lbl = Label.new()
				bluff_lbl.text = " (嘘: +%d点)" % bluff_amount
				bluff_lbl.add_theme_font_override("font", DeskTheme.get_font())
				bluff_lbl.add_theme_font_size_override("font_size", 15)
				bluff_lbl.add_theme_color_override("font_color", Color("e53935"))
				score_hbox.add_child(bluff_lbl)
				
			var doubts_made = info.get("doubts_made", [])
			if doubts_made.size() > 0:
				var m_lbl = Label.new()
				var target_names = []
				for t in doubts_made: target_names.append(_get_participant_name(t))
				m_lbl.text = "・ダウトした相手: " + ", ".join(target_names)
				m_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				m_lbl.add_theme_font_override("font", DeskTheme.get_font())
				m_lbl.add_theme_font_size_override("font_size", 14)
				m_lbl.add_theme_color_override("font_color", Color("1e88e5"))
				c_vbox.add_child(m_lbl)
				
			var doubts_received = info.get("doubts_received", [])
			if doubts_received.size() > 0:
				var r_lbl = Label.new()
				var sender_names = []
				for s in doubts_received: sender_names.append(_get_participant_name(s))
				r_lbl.text = "・ダウトされた相手: " + ", ".join(sender_names)
				if info.get("is_doubt_exposed", false):
					r_lbl.text += " [嘘バレ]"
					r_lbl.add_theme_color_override("font_color", Color("e53935"))
				else:
					r_lbl.text += " [回避]"
					r_lbl.add_theme_color_override("font_color", Color("43a047"))
				r_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				r_lbl.add_theme_font_override("font", DeskTheme.get_font())
				r_lbl.add_theme_font_size_override("font_size", 14)
				c_vbox.add_child(r_lbl)
				
	var bottom_margin = MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 15)
	bottom_margin.add_theme_constant_override("margin_right", 15)
	bottom_margin.add_theme_constant_override("margin_top", 10)
	bottom_margin.add_theme_constant_override("margin_bottom", 15)
	main_vbox.add_child(bottom_margin)
	
	var close_btn = Button.new()
	close_btn.text = "閉じる"
	_setup_stationery_btn(close_btn, "white")
	close_btn.custom_minimum_size = Vector2(0, 50)
	bottom_margin.add_child(close_btn)
	
	var close_func = func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_se(AudioManager.SE_CLICK)
		panel.pivot_offset = panel.size / 2.0
		create_tween().tween_property(panel, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		create_tween().tween_property(modal_bg, "modulate:a", 0.0, 0.2).set_delay(0.1).finished.connect(func(): modal_bg.queue_free())
		
	close_btn.pressed.connect(close_func)
	close_icon.pressed.connect(close_func)
	
	_on_viewport_size_changed()
	
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.2)
	
	modal_bg.modulate.a = 0
	create_tween().tween_property(modal_bg, "modulate:a", 1.0, 0.2)
