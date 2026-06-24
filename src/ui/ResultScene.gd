# -*- coding: utf-8 -*-
class_name ResultScene
extends Control

# UI Elements
var blackboard_panel: PanelContainer
var blackboard_vbox: VBoxContainer
var scorecard_label: Label
var report_notebook: PanelContainer
var report_left_page: VBoxContainer
var report_right_page: VBoxContainer
var share_btn: Button
var restart_btn: Button
var play_again_btn: Button
var skip_btn: Button
var root_layer: Control
var board_frame: ColorRect
var board_inner: ColorRect
var graph_area: VBoxContainer
var day_chart_area: Control
var chart_title: Label
var day_bar_rows: Dictionary = {}

# Score details from session
var showdown_data: Dictionary
var current_step_day: int = 1
var is_revealing: bool = true
var old_deviation: float = 50.0
var new_deviation: float = 50.0
var deviation_change: float = 0.0
var _active_score_labels: Dictionary = {}
var _anim_line1: Line2D
var _anim_line2: Line2D

# Participant list for results
var participants: Array = []

func _ready() -> void:
	# Root layer for all result UI.
	root_layer = Control.new()
	root_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_layer)
	ResultBoardUI.build_background(self)
	ResultBoardUI.build_blackboard(self)
	_build_day_chart_shell()
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_RESULT)
	
	if Global.is_tutorial_mode:
		PlayerState.is_tutorial_completed = true
	
	# Instantiate dummy session data or retrieve from active session
	var raw_results = Global.get("active_showdown_results")
	if raw_results and not raw_results.is_empty():
		showdown_data = raw_results
	else:
		# Fallback simulation for testing/standalone play
		var dummy_session = GameSession.new()
		var starting_deck = Global.current_deck
		if Global.game_mode == Constants.MODE_OVERNIGHT:
			starting_deck = Global.get_cram_season_deck()
		dummy_session.start_session(starting_deck)
		for day in range(1, Constants.MAX_DAYS + 1):
			dummy_session.current_day = day
			dummy_session.player_actual_score_today = randi_range(30, 60)
			dummy_session.player_declared_score_today = dummy_session.player_actual_score_today + (10 if randf() < 0.5 else 0)
			dummy_session.player_hours_history_today = [{"draws": 4, "used_items": [], "bursted": false, "score": dummy_session.player_actual_score_today}]
		dummy_session.end_day()
		showdown_data = dummy_session.calculate_final_showdown()
	
	if not showdown_data.has("details"):
		showdown_data["details"] = {}
	if not showdown_data.has("rankings"):
		showdown_data["rankings"] = []
	if not showdown_data.has("final_scores"):
		showdown_data["final_scores"] = {"player": 0}
		
	# Calculate deviation changes before proceeding
	_calculate_deviation()
	Global.evaluate_achievements()
		
	ResultReportUI.build_report_notebook(self)
	
	_reflow_layout()
	
	# Start daily reveal animation loop
	is_revealing = true
	current_step_day = 1
	reveal_next_day_showdown()



func _reflow_layout() -> void:
	if not is_inside_tree():
		return
	var vp_size = get_viewport_rect().size
	if is_instance_valid(blackboard_panel):
		blackboard_panel.position = vp_size * 0.5 - blackboard_panel.custom_minimum_size * 0.5
	if is_instance_valid(report_notebook):
		var max_w = min(1300.0, vp_size.x - 100.0)
		var max_h = min(510.0, vp_size.y - 150.0)
		report_notebook.custom_minimum_size = Vector2(max_w, max_h)
		report_notebook.size = Vector2(max_w, max_h)
		
		if is_instance_valid(report_left_page):
			report_left_page.custom_minimum_size = Vector2((max_w - 100.0) * 0.5, 0)
		if is_instance_valid(report_right_page):
			report_right_page.custom_minimum_size = Vector2((max_w - 100.0) * 0.5, 0)
			
		report_notebook.position = vp_size * 0.5 - report_notebook.size * 0.5
		report_notebook.position.y += 10.0
	if is_instance_valid(skip_btn):
		skip_btn.position = vp_size - skip_btn.custom_minimum_size - Vector2(24, 24)
	if is_instance_valid(board_inner):
		board_inner.position = Vector2(42, 42)
		board_inner.size = vp_size - Vector2(84, 84)

func reveal_next_day_showdown() -> void:
	if not showdown_data.has("details"):
		showdown_data["details"] = {}
		
	if current_step_day > showdown_data.get("details", {}).size():
		# Reveal complete! Trigger report card overlay or deviation animation
		if is_revealing:
			is_revealing = false
			if Global.game_mode == Constants.MODE_RANDOM:
				_play_chalk_deviation_animation()
			else:
				trigger_report_card()
		return
		
	# Clear older elements so we only show the current day's reveal
	for child in blackboard_vbox.get_children():
		if child != scorecard_label and child != chart_title and child != day_chart_area:
			child.queue_free()
			
	_update_day_chart(current_step_day)
	# Day Title
	var day_lbl = Label.new()
	day_lbl.text = "第 %d 日目" % current_step_day
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl.add_theme_font_override("font", DeskTheme.get_font())
	day_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
	day_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	blackboard_vbox.add_child(day_lbl)
	
	# Cards HBox Container
	var cards_hbox = HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", DeskTheme.MARGIN_LARGE)
	blackboard_vbox.add_child(cards_hbox)
	
	var day_details = showdown_data["details"][current_step_day]
	var any_exposed = false
	
	# Render 4 Cards
	for p_id in day_details.keys():
		var info = day_details[p_id]
		var is_exposed = info["is_doubt_exposed"]
		var actual = info["actual"]
		var declared = info["declared"]
		var name_str = _get_participant_name(p_id)
			
		# Chalk Card Panel
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(320, 260)
		card.pivot_offset = Vector2(160, 130)
		cards_hbox.add_child(card)
		
		# Base card style (light paper card)
		var style = StyleBoxFlat.new()
		style.bg_color = Color("fffdf8")
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.shadow_color = Color(0, 0, 0, 0.12)
		style.shadow_size = 8
		style.shadow_offset = Vector2(3, 4)
		
		# Set card border colors based on honesty
		if declared > actual:
			if is_exposed:
				style.border_color = Color("ff6b6b")
				any_exposed = true
			else:
				style.border_color = Color("e0b84c")
		else:
			style.border_color = Color("6bbf59")
			
		card.add_theme_stylebox_override("panel", style)
		
		# Inner Margin
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_SMALL)
		margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_SMALL)
		margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_SMALL)
		margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_SMALL)
		card.add_child(margin)
		
		# VBox content
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_TINY)
		margin.add_child(vbox)
		
		# Name Label (Richer Ink color for readability on light paper)
		var name_lbl = Label.new()
		name_lbl.text = name_str
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(name_lbl)
		
		# Chalk line separator
		var line = ColorRect.new()
		line.color = Color(0.12, 0.08, 0.05, 0.15) # ink line for contrast
		line.custom_minimum_size = Vector2(0, 2)
		vbox.add_child(line)
		
		# Declared Score
		var decl_lbl = Label.new()
		decl_lbl.text = "申告: %d 点" % declared
		decl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		decl_lbl.add_theme_font_override("font", DeskTheme.get_font())
		decl_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		decl_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
		vbox.add_child(decl_lbl)
		
		# Actual Score
		var act_lbl = Label.new()
		act_lbl.text = "実点: %d 点" % actual
		act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		act_lbl.add_theme_font_override("font", DeskTheme.get_font())
		act_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		# Clear coloring: gold for bluffing, deep green for honest
		if declared > actual:
			act_lbl.add_theme_color_override("font_color", Color("b8860b")) # Darker gold
		else:
			act_lbl.add_theme_color_override("font_color", Color("2e7d32")) # Forest green
		vbox.add_child(act_lbl)
		
		# Stamp/Badge container
		var stamp_container = CenterContainer.new()
		vbox.add_child(stamp_container)
		
		# Rubber stamp badge label
		var stamp_lbl = Label.new()
		stamp_lbl.add_theme_font_override("font", DeskTheme.get_font())
		stamp_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
		
		var border_color = Color("6bbf59")
		if declared > actual:
			if is_exposed:
				stamp_lbl.text = " 嘘バレ！ "
				stamp_lbl.add_theme_color_override("font_color", Color("ff6b6b"))
				border_color = Color("ff6b6b")
			else:
				stamp_lbl.text = " セーフ "
				stamp_lbl.add_theme_color_override("font_color", Color("e0b84c"))
				border_color = Color("e0b84c")
		else:
			stamp_lbl.text = " 正直 "
			stamp_lbl.add_theme_color_override("font_color", Color("6bbf59"))
			border_color = Color("6bbf59")
			
		var stamp_style = DeskTheme.create_stamp_style(border_color)
		stamp_lbl.add_theme_stylebox_override("normal", stamp_style)
		stamp_container.add_child(stamp_lbl)
		
		# Entrance scale pop animation for cards
		card.scale = Vector2.ZERO
		var c_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		c_tween.tween_property(card, "scale", Vector2.ONE, 0.18)
		
		# If exposed: Draw a bold red 'X' Line2D scaling overlay on the panel
		if declared > actual and is_exposed:
			var overlay = Control.new()
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			card.add_child(overlay)
			
			var line1 = Line2D.new()
			line1.width = 10.0
			line1.default_color = Color("ff3333", 0.9) # Chalk red ink
			line1.points = PackedVector2Array([Vector2(15, 15), Vector2(15, 15)])
			overlay.add_child(line1)
			
			var line2 = Line2D.new()
			line2.width = 10.0
			line2.default_color = Color("ff3333", 0.9)
			line2.points = PackedVector2Array([Vector2(305, 15), Vector2(305, 15)])
			overlay.add_child(line2)
			
			# Animate drawing the cross lines dynamically after the card pops in
			var x_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			x_tween.tween_method(func(val: Vector2): line1.set_point_position(1, val), Vector2(15, 15), Vector2(305, 245), 0.2).set_delay(0.15)
			x_tween.tween_method(func(val: Vector2): line2.set_point_position(1, val), Vector2(305, 15), Vector2(15, 245), 0.2).set_delay(0.25)
			
	# Camera shake for dramatic exposure if anyone was caught lying
	if any_exposed:
		var shake_timer = get_tree().create_timer(0.3)
		shake_timer.timeout.connect(func():
			DeskTheme.shake_control(blackboard_panel, 8.0, 0.25)
		)
	else:
		DeskTheme.shake_control(blackboard_panel, 2.5, 0.15)
		
	# Go to next day after delay
	var timer = get_tree().create_timer(1.1)
	timer.timeout.connect(func():
		if not is_instance_valid(self) or not is_inside_tree():
			return
		if is_revealing:
			current_step_day += 1
			reveal_next_day_showdown()
	)

func _build_day_chart_shell() -> void:
	for child in day_chart_area.get_children():
		child.queue_free()
	day_bar_rows.clear()
	
	var start_y = 0.0
	var spacing = 12.0
	var row_height = 30.0
	
	var idx = 0
	var final_scores_keys = showdown_data.get("final_scores", {"player": 0}).keys()
	for p_id in final_scores_keys:
		var row = Control.new()
		row.custom_minimum_size = Vector2(1320, row_height)
		row.size = Vector2(1320, row_height)
		row.position = Vector2(0, start_y + idx * (row_height + spacing))
		day_chart_area.add_child(row)
		day_bar_rows[p_id] = row
		
		var hbox = HBoxContainer.new()
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hbox.add_theme_constant_override("separation", DeskTheme.MARGIN_TINY)
		row.add_child(hbox)
		
		var name_lbl = Label.new()
		var bar_color = Color("6bbf59") if p_id == "player" else Color("3f51b5")
		name_lbl.text = "● " + _get_participant_name(p_id)
		name_lbl.custom_minimum_size = Vector2(150, 0)
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
		name_lbl.add_theme_color_override("font_color", bar_color)
		hbox.add_child(name_lbl)
		
		var bar_wrap = PanelContainer.new()
		bar_wrap.custom_minimum_size = Vector2(970, 22)
		var style = StyleBoxFlat.new()
		style.bg_color = Color("efe7d8")
		style.border_color = Color("b59d7a")
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		bar_wrap.add_theme_stylebox_override("panel", style)
		hbox.add_child(bar_wrap)
		
		var fill = ColorRect.new()
		fill.name = "fill"
		fill.color = bar_color
		fill.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		fill.size = Vector2(1, 22)
		bar_wrap.add_child(fill)
		
		var score_lbl = Label.new()
		score_lbl.name = "score_lbl"
		score_lbl.text = "0 点"
		score_lbl.custom_minimum_size = Vector2(80, 0)
		score_lbl.add_theme_font_override("font", DeskTheme.get_font())
		score_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
		score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		hbox.add_child(score_lbl)
		
		_active_score_labels[p_id] = score_lbl
		
		idx += 1

func _update_day_chart(day_idx: int) -> void:
	if not showdown_data.has("details"):
		return
	var cumulative := {}
	var final_scores_keys = showdown_data.get("final_scores", {"player": 0}).keys()
	for p_id in final_scores_keys:
		cumulative[p_id] = 0
	for d in range(1, day_idx + 1):
		if not showdown_data["details"].has(d):
			continue
		var day_data: Dictionary = showdown_data["details"][d]
		for p_id in cumulative.keys():
			if day_data.has(p_id):
				cumulative[p_id] += int(day_data[p_id].get("base", 0)) + int(day_data[p_id].get("adjustment", 0))
				
	var sort_arr := []
	for p_id in cumulative.keys():
		sort_arr.append({"id": p_id, "score": cumulative[p_id]})
	
	# Stable Sorting (Alphabetical fallback for tie-breaker)
	sort_arr.sort_custom(func(a, b):
		if a["score"] == b["score"]:
			return a["id"] < b["id"]
		return a["score"] > b["score"]
	)
	
	var max_score := 1
	for p_id in cumulative.keys():
		max_score = max(max_score, cumulative[p_id])
		
	var row_height = 30.0
	var spacing = 12.0
	var start_y = 0.0
	
	for rank in range(sort_arr.size()):
		var item = sort_arr[rank]
		var p_id = item["id"]
		var score = item["score"]
		
		var row: Control = day_bar_rows.get(p_id)
		if not row:
			continue
			
		var target_y = start_y + rank * (row_height + spacing)
		var pos_tween = create_tween().bind_node(row).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pos_tween.tween_property(row, "position:y", target_y, 0.6)
		
		var hbox = row.get_child(0)
		var bar_wrap = hbox.get_child(1)
		var fill = bar_wrap.get_node("fill")
		var target_width = int(1000.0 * float(score) / float(max_score))
		var bar_tween = create_tween().bind_node(fill).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bar_tween.tween_property(fill, "size:x", max(8, target_width), 0.55)
		
		var score_lbl: Label = _active_score_labels.get(p_id)
		if score_lbl:
			var current_score_text = score_lbl.text.replace(" 点", "")
			var start_score = int(current_score_text)
			var count_tween = create_tween().set_trans(Tween.TRANS_LINEAR)
			var callable: Callable
			match p_id:
				"player": callable = _set_score_player
				"cpu_sato": callable = _set_score_sato
				"cpu_suzuki": callable = _set_score_suzuki
				"cpu_takahashi": callable = _set_score_takahashi
				_:
					callable = func(val: float):
						if _active_score_labels.has(p_id) and is_instance_valid(_active_score_labels[p_id]):
							_active_score_labels[p_id].text = "%d 点" % int(val)
			if callable:
				count_tween.tween_method(callable, start_score, score, 0.5)

func _get_participant_name(p_id: String) -> String:
	if p_id == "player":
		return Global.player_name if Global.player_name != "" else "あなた"
	if Global.opponent_profiles.has(p_id):
		return Global.opponent_profiles[p_id].get("name", p_id)
	return AIManager.get_cpu_name(p_id)

func _on_skip_pressed() -> void:
	if not is_revealing or skip_btn.disabled:
		return
	is_revealing = false
	skip_btn.disabled = true
	skip_btn.release_focus()
	DeskTheme.animate_click(skip_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		trigger_report_card()
	)

func trigger_report_card() -> void:
	if is_instance_valid(skip_btn):
		skip_btn.queue_free()
	
	var anim_actions = []
	
	# Smoothly fade out and slide down the blackboard panel
	var exit_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(blackboard_panel, "modulate:a", 0.0, 0.3)
	exit_tween.tween_property(blackboard_panel, "position:y", blackboard_panel.position.y + 150.0, 0.3)
	
	exit_tween.chain().tween_callback(func():
		blackboard_panel.visible = false
		
		if is_instance_valid(report_notebook):
			report_notebook.visible = true
			var target_pos = report_notebook.position
			DeskTheme.animate_entrance(report_notebook, target_pos, Vector2(0, -400), 0.6)
			
			# Run the graph reveal animation when it lands on the desk (0.6 seconds later)
			var land_timer = get_tree().create_timer(0.6)
			land_timer.timeout.connect(func():
				# Start graph animations concurrently
				for action in anim_actions:
					action.call()
					
				# Wait for the step-by-step graph animation to finish (approx 1.9s)
				var end_timer = get_tree().create_timer(1.9)
				end_timer.timeout.connect(func():
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_se(AudioManager.SE_FANFARE, 0.0, -10.0)
						get_node("/root/AudioManager").play_bgm(AudioManager.BGM_RESULT)
					
					# Spawn confetti if 1st place
					var my_rank = showdown_data.get("my_rank", 3)
					if my_rank == 1:
						_spawn_confetti()
				)
			)
	)
	
	# Build Left Page (Player scorecard)
	var rank_title = Label.new()
	rank_title.text = "学末最終成績通知表"
	rank_title.add_theme_font_override("font", DeskTheme.get_font())
	rank_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE)
	rank_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	report_left_page.add_child(rank_title)
	
	var my_score = showdown_data["final_scores"]["player"]
	var score_lbl = Label.new()
	score_lbl.text = "総合得点: " + str(my_score) + " 点"
	score_lbl.add_theme_font_override("font", DeskTheme.get_font())
	score_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_GIANT)
	score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	report_left_page.add_child(score_lbl)
	
	# Display Deviation Value if playing random match
	if Global.game_mode == Constants.MODE_RANDOM:
		var deviation_change_lbl = Label.new()
		var old_league = showdown_data.get("old_league", "")
		var new_league = showdown_data.get("new_league", "")
		
		var league_text = "全国ランダムマッチ 偏差値: %.1f (前回: %.1f)\n" % [new_deviation, old_deviation]
		league_text += "所属リーグ: %s" % Global.get_deviation_league_name(new_league)
		
		if old_league != new_league and old_league != "":
			if showdown_data.get("league_upgraded", false):
				league_text += " 【昇格！】"
			elif showdown_data.get("league_downgraded", false):
				league_text += " 【降格...】"
		
		league_text += "\n"
		if deviation_change >= 0:
			league_text += "→ 偏差値が %.1f アップしました！" % deviation_change
			deviation_change_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BONUS)
		else:
			league_text += "→ 偏差値が %.1f ダウンしました..." % abs(deviation_change)
			deviation_change_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
			
		deviation_change_lbl.text = league_text
		deviation_change_lbl.add_theme_font_override("font", DeskTheme.get_font())
		deviation_change_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		report_left_page.add_child(deviation_change_lbl)
	
	# Coins, levels, and star bonuses removed.
	
	# 称号スタンプ風UI & アニメーション演出
	var title_container = VBoxContainer.new()
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	title_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	report_left_page.add_child(title_container)
	
	var title_desc = Label.new()
	var is_title_new = showdown_data.get("is_title_new", false)
	if is_title_new:
		title_desc.text = "【 新称号獲得！ 】"
	else:
		title_desc.text = "現在の称号"
	title_desc.add_theme_font_override("font", DeskTheme.get_font())
	title_desc.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	if is_title_new:
		title_desc.add_theme_color_override("font_color", Color("c62828"))
	else:
		title_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	title_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title_desc)
	
	var stamp_color = Color("c62828") if is_title_new else Color("455a64")
	var stamp_bg = Color(1, 0.9, 0.9, 0.3) if is_title_new else Color(0.9, 0.9, 1.0, 0.3)
	var stamp_style = DeskTheme.create_stamp_style(stamp_color, stamp_bg)
	
	var stamp_panel = PanelContainer.new()
	stamp_panel.add_theme_stylebox_override("panel", stamp_style)
	stamp_panel.pivot_offset = Vector2(100, 25)
	stamp_panel.rotation_degrees = -6.0
	title_container.add_child(stamp_panel)
	
	var title_lbl = Label.new()
	title_lbl.text = "【 " + showdown_data["title"] + " 】"
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", stamp_color)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_panel.add_child(title_lbl)
	
	var s_tween = create_tween().set_parallel(true)
	if is_title_new:
		stamp_panel.scale = Vector2(3.0, 3.0)
		stamp_panel.modulate.a = 0.0
		s_tween.tween_property(stamp_panel, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		s_tween.tween_property(stamp_panel, "modulate:a", 1.0, 0.15)
	else:
		stamp_panel.scale = Vector2(1.0, 1.0)
		stamp_panel.modulate.a = 0.0
		s_tween.tween_property(stamp_panel, "modulate:a", 1.0, 0.25)
	# If S-grade (250+ points), stamp a huge hanamaru (花丸スタンプ)
	if my_score >= 250:
		var hanamaru_parent = Control.new()
		hanamaru_parent.name = "HanamaruParent"
		hanamaru_parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		report_notebook.add_child(hanamaru_parent)
		
		var hanamaru = TextureRect.new()
		hanamaru.custom_minimum_size = Vector2(300, 300)
		hanamaru.size = Vector2(300, 300)
		hanamaru.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hanamaru.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hanamaru.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if FileAccess.file_exists("res://assets/はなまるスタンプ.png"):
			hanamaru.texture = load("res://assets/はなまるスタンプ.png")
		hanamaru_parent.add_child(hanamaru)
		
		# Center bottom on the left page (under advice box)
		# Left page is around X=50 to X=650, Y=0 to Y=600.
		# Setting X=150, Y=320 puts the 300x300 stamp perfectly in the lower half of the left page.
		hanamaru.position = Vector2(150, 320)
		hanamaru.pivot_offset = Vector2(150, 150)
		
		# Hanamaru stamp landing bounce and screen shake
		hanamaru.scale = Vector2(3.0, 3.0)
		hanamaru.modulate.a = 0.0
		var h_tween = create_tween().set_parallel(true)
		h_tween.tween_property(hanamaru, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		h_tween.tween_property(hanamaru, "modulate:a", 1.0, 0.15)
		h_tween.chain().tween_callback(func():
			DeskTheme.shake_control(report_notebook, 5.0, 0.25)
		)
		
	# 担任からの評価（リテンション向上用フィードバック）
	var advice_box = PanelContainer.new()
	var advice_style = StyleBoxFlat.new()
	advice_style.bg_color = Color("fffdf8")
	advice_style.border_color = DeskTheme.COLOR_INK
	advice_style.border_width_left = 2
	advice_style.border_width_right = 2
	advice_style.border_width_top = 2
	advice_style.border_width_bottom = 2
	advice_style.corner_radius_top_left = 4
	advice_style.corner_radius_top_right = 4
	advice_style.corner_radius_bottom_left = 4
	advice_style.corner_radius_bottom_right = 4
	advice_style.content_margin_left = 10
	advice_style.content_margin_right = 10
	advice_style.content_margin_top = 6
	advice_style.content_margin_bottom = 6
	advice_box.add_theme_stylebox_override("panel", advice_style)
	report_left_page.add_child(advice_box)
	
	var advice_lbl = Label.new()
	var advice_text = "【担任からの評価】\n"
	var t = showdown_data.get("title", "")
	if "正直" in t or "堅実" in t or t == Constants.TITLE_SAFE_CHAMP or t == Constants.TITLE_CRAM_HONEST:
		advice_text += "堅実な勉強態度が素晴らしいです。"
	elif "嵐" in t or t == Constants.TITLE_STORM:
		advice_text += "無理しすぎです。休むことも覚えましょう。"
	elif "オオカミ" in t or t == Constants.TITLE_WOLF_BOY:
		advice_text += "嘘が多すぎます。次は正直に申告しましょう。"
	elif "スナイパー" in t or "探知機" in t or t == Constants.TITLE_SNIPER or t == Constants.TITLE_LIE_DETECTOR:
		advice_text += "相手の嘘を見抜く洞察力が見事でした！"
	elif t == Constants.TITLE_RED_FAIL or t == Constants.TITLE_UNDERACHIEVER:
		advice_text += "今回は残念でしたが、次の勉強で挽回しましょう！"
	elif t == Constants.TITLE_DEV_GOD or t == Constants.TITLE_CRAM_GENIUS:
		advice_text += "言うことなしの完璧な成績です！"
	else:
		advice_text += "本日の勉強お疲れ様でした！次もこの調子で頑張りましょう！"
		
	advice_lbl.text = advice_text
	advice_lbl.add_theme_font_override("font", DeskTheme.get_font())
	advice_lbl.add_theme_font_size_override("font_size", 14)
	advice_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	advice_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advice_box.add_child(advice_lbl)
		
	# Build Right Page (Leaderboard rankings)
	var lead_title = Label.new()
	lead_title.text = "学級ランキング（成績順）"
	lead_title.add_theme_font_override("font", DeskTheme.get_font())
	lead_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE)
	lead_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	report_right_page.add_child(lead_title)

	var player_name_lbl = Label.new()
	var display_name = Global.player_name if Global.player_name != "" else "あなた"
	player_name_lbl.text = "プレイヤー: %s" % display_name
	player_name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	player_name_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	player_name_lbl.add_theme_color_override("font_color", Color("3f51b5"))
	report_right_page.add_child(player_name_lbl)

	graph_area = VBoxContainer.new()
	graph_area.add_theme_constant_override("separation", 8)
	report_right_page.add_child(graph_area)

	# Stable rankings sort (Higher score, then lower bursts, then alphabetical ID)
	var ranks = showdown_data["rankings"].duplicate()
	ranks.sort_custom(func(a, b):
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		if a["bursts"] != b["bursts"]:
			return a["bursts"] < b["bursts"]
		return a["id"] < b["id"]
	)
	
	var max_score = 1
	for rr in ranks:
		max_score = max(max_score, int(rr["score"]))
	for r_idx in range(ranks.size()):
		var r = ranks[r_idx]
		
		# WebGL-friendly text rank labels replacing colored medal emojis to prevent character corruption
		var medal = ""
		match r_idx:
			0: medal = "[ 1位 ] "
			1: medal = "[ 2位 ] "
			2: medal = "[ 3位 ] "
			_: medal = "[ 4位 ] "
			
		var r_lbl = Label.new()
		r_lbl.text = medal + r["name"] + " [ " + str(r["score"]) + "点 / バースト " + str(r["bursts"]) + "回 ]"
		r_lbl.add_theme_font_override("font", DeskTheme.get_font())
		r_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		
		if r["id"] == "player":
			r_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		else:
			r_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		
		report_right_page.add_child(r_lbl)

		var bar_row = VBoxContainer.new()
		bar_row.add_theme_constant_override("separation", 4)
		graph_area.add_child(bar_row)

		var bar_color = Color("6bbf59") if r["id"] == "player" else Color("3f51b5")
		var bar_name = Label.new()
		bar_name.text = "● %s" % r["name"]
		bar_name.add_theme_font_override("font", DeskTheme.get_font())
		bar_name.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
		bar_name.add_theme_color_override("font_color", bar_color)
		bar_row.add_child(bar_name)

		var bar_back = PanelContainer.new()
		bar_back.custom_minimum_size = Vector2(520, 22)
		var bar_back_style = StyleBoxFlat.new()
		bar_back_style.bg_color = Color("efe7d8")
		bar_back_style.border_color = Color("b59d7a")
		bar_back_style.border_width_left = 2
		bar_back_style.border_width_right = 2
		bar_back_style.border_width_top = 2
		bar_back_style.border_width_bottom = 2
		bar_back_style.corner_radius_top_left = 8
		bar_back_style.corner_radius_top_right = 8
		bar_back_style.corner_radius_bottom_left = 8
		bar_back_style.corner_radius_bottom_right = 8
		bar_back.add_theme_stylebox_override("panel", bar_back_style)
		bar_row.add_child(bar_back)

		# 段階的な累積スコアの計算
		var score_history: Array[int] = []
		var cum_score = 0
		for day in range(1, Constants.MAX_DAYS + 1):
			if showdown_data.get("details", {}).has(day):
				var day_details = showdown_data["details"][day]
				if day_details.has(r["id"]):
					cum_score += int(day_details[r["id"]].get("base", 0)) + int(day_details[r["id"]].get("adjustment", 0))
			score_history.append(cum_score)
		
		# 最終日の累積値を最終得点と強制的に一致させ、それ以前のスコアがそれを超えないようにする
		var final_score_val = int(r["score"])
		score_history[Constants.MAX_DAYS - 1] = final_score_val
		for i in range(Constants.MAX_DAYS - 1):
			if score_history[i] > final_score_val:
				score_history[i] = final_score_val

		var bar_fill = ColorRect.new()
		bar_fill.color = Color("6bbf59") if r["id"] == "player" else Color("3f51b5")
		bar_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bar_fill.size = Vector2(8, 22)
		bar_back.add_child(bar_fill)

		# Register animation step actions
		var anim_action = func():
			var bar_tween = create_tween().bind_node(bar_fill).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			for d_idx in range(5):
				var step_score = score_history[d_idx]
				var step_ratio = float(step_score) / float(max_score)
				var step_width = max(8, int(520 * step_ratio))
				bar_tween.tween_property(bar_fill, "size:x", step_width, 0.3)
				if d_idx < 4:
					bar_tween.tween_interval(0.1)
			bar_tween.tween_callback(func():
				if r["id"] == "player":
					DeskTheme.shake_control(report_notebook, 6.0, 0.12)
			)
		anim_actions.append(anim_action)

	# Actions HBox
	var act_hbox = HBoxContainer.new()
	act_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	act_hbox.add_theme_constant_override("separation", DeskTheme.MARGIN_DEFAULT)
	report_right_page.add_child(act_hbox)
	
	# Eraser button style helper function inside scope
	var apply_eraser_style = func(btn: Button) -> void:
		var eraser_normal = StyleBoxFlat.new()
		eraser_normal.bg_color = Color("2e3b32") # Dark green plastic/wood top
		eraser_normal.border_color = Color("eceff1") # White/gray felt pad
		eraser_normal.border_width_left = 2
		eraser_normal.border_width_right = 2
		eraser_normal.border_width_top = 2
		eraser_normal.border_width_bottom = 12 # Thick felt pad at the bottom
		eraser_normal.corner_radius_top_left = 6
		eraser_normal.corner_radius_top_right = 6
		eraser_normal.corner_radius_bottom_left = 4
		eraser_normal.corner_radius_bottom_right = 4
		eraser_normal.shadow_color = Color(0, 0, 0, 0.3)
		eraser_normal.shadow_size = 6
		eraser_normal.shadow_offset = Vector2(2, 4)
		
		var eraser_hover = eraser_normal.duplicate() as StyleBoxFlat
		eraser_hover.bg_color = Color("3e4b42")
		eraser_hover.border_color = Color("ffffff")
		eraser_hover.border_width_bottom = 15 # Lifted up
		eraser_hover.shadow_size = 10
		eraser_hover.shadow_offset = Vector2(3, 6)
		
		var eraser_pressed = eraser_normal.duplicate() as StyleBoxFlat
		eraser_pressed.bg_color = Color("1e2b22")
		eraser_pressed.border_width_bottom = 3 # Squished felt pad
		eraser_pressed.shadow_size = 2
		eraser_pressed.shadow_offset = Vector2(1, 1)
		
		btn.add_theme_stylebox_override("normal", eraser_normal)
		btn.add_theme_stylebox_override("hover", eraser_hover)
		btn.add_theme_stylebox_override("pressed", eraser_pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_color_override("font_color", Color("eceff1"))
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color("cfd8dc"))
		
		# Set pivot to center for nice scaling animations
		btn.pivot_offset = btn.custom_minimum_size * 0.5
		
		# Connect hover animations for tactile feel
		btn.mouse_entered.connect(func():
			if not btn.disabled:
				var tween = btn.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.15)
				# Slide up slightly to feel 3D
				tween.tween_property(btn, "position:y", -4.0, 0.15)
				if Engine.get_main_loop().root.has_node("AudioManager"):
					var audio = Engine.get_main_loop().root.get_node("AudioManager")
					audio.play_se(audio.SE_CLICK)
		)
		btn.mouse_exited.connect(func():
			if not btn.disabled:
				var tween = btn.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(btn, "scale", Vector2.ONE, 0.15)
				tween.tween_property(btn, "position:y", 0.0, 0.15)
		)
		btn.button_down.connect(func():
			if not btn.disabled:
				var tween = btn.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)
				tween.tween_property(btn, "position:y", 4.0, 0.08)
		)
		btn.button_up.connect(func():
			if not btn.disabled:
				var tween = btn.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(btn, "scale", Vector2.ONE, 0.15)
				tween.tween_property(btn, "position:y", 0.0, 0.15)
		)
	
	share_btn = Button.new()
	share_btn.add_to_group("important_button")
	share_btn.text = "Xでシェア"
	share_btn.custom_minimum_size = Vector2(220, 65)
	share_btn.add_theme_font_override("font", DeskTheme.get_font())
	share_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	apply_eraser_style.call(share_btn)
	share_btn.pressed.connect(_on_share_pressed)
	act_hbox.add_child(share_btn)
	
	play_again_btn = Button.new()
	play_again_btn.add_to_group("important_button")
	play_again_btn.text = "もう1回遊ぶ"
	play_again_btn.custom_minimum_size = Vector2(220, 65)
	play_again_btn.add_theme_font_override("font", DeskTheme.get_font())
	play_again_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	apply_eraser_style.call(play_again_btn)
	play_again_btn.pressed.connect(_on_play_again_pressed)
	act_hbox.add_child(play_again_btn)
	
	restart_btn = Button.new()
	restart_btn.add_to_group("important_button")
	restart_btn.text = "タイトルへ"
	restart_btn.custom_minimum_size = Vector2(220, 65)
	restart_btn.add_theme_font_override("font", DeskTheme.get_font())
	restart_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	apply_eraser_style.call(restart_btn)
	restart_btn.pressed.connect(_on_restart_pressed)
	act_hbox.add_child(restart_btn)

func _on_share_pressed() -> void:
	if share_btn.disabled:
		return
	share_btn.disabled = true
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(share_btn):
			share_btn.disabled = false
	)
	share_btn.release_focus()
	DeskTheme.animate_click(share_btn, Vector2.ONE, 0.08)
	
	# シェア画像の生成と保存/共有の実行
	ShareCardGenerator.generate_and_copy_share_image(self, showdown_data)
	
	var my_score = showdown_data["final_scores"]["player"]
	var text_to_tweet = "『テスト勉強チキンレース』で称号【" + showdown_data["title"] + "】を獲得！最終スコア：" + str(my_score) + "点！ #テスト勉強チキンレース"
	var escaped_text = text_to_tweet.uri_encode()
	OS.shell_open("https://twitter.com/intent/tweet?text=" + escaped_text)

func _on_restart_pressed() -> void:
	if restart_btn.disabled:
		return
	restart_btn.disabled = true
	restart_btn.release_focus()
	DeskTheme.animate_click(restart_btn, Vector2.ONE, 0.08)
	
	# Clear active results in global
	Global.set("active_showdown_results", {})
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)

func _on_play_again_pressed() -> void:
	if play_again_btn.disabled:
		return
	play_again_btn.disabled = true
	play_again_btn.release_focus()
	DeskTheme.animate_click(play_again_btn, Vector2.ONE, 0.08)
	
	# Clear active results in global
	Global.set("active_showdown_results", {})
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
	)

func _calculate_deviation() -> void:
	# Calculate player win/lose rank
	var my_rank = 3
	if showdown_data.has("my_rank"):
		my_rank = showdown_data["my_rank"]
	else:
		var ranks_temp = showdown_data.get("rankings", []).duplicate()
		ranks_temp.sort_custom(func(a, b):
			if a["score"] != b["score"]:
				return a["score"] > b["score"]
			if a["bursts"] != b["bursts"]:
				return a["bursts"] < b["bursts"]
			return a["id"] < b["id"]
		)
		for r_idx in range(ranks_temp.size()):
			if ranks_temp[r_idx]["id"] == "player":
				my_rank = r_idx + 1
				break
		showdown_data["my_rank"] = my_rank
				
	var is_player_win = (my_rank == 1)
	
	# Record match result (updates recent results, wins, and triggers grade promotion if applicable)
	var prog_report = PlayerState.record_match_result(is_player_win)
	showdown_data["prog_report"] = prog_report
	
	if Global.game_mode == Constants.MODE_RANDOM:
		if not showdown_data.has("deviation_change"):
			# フォールバック処理 (テストコード実行時など)
			var change = 0.0
			if my_rank == 1:
				change = randf_range(3.2, 4.8) + max(0.0, (60.0 - Global.deviation_value) * 0.15)
			elif my_rank == 2:
				change = randf_range(0.8, 1.6) + (55.0 - Global.deviation_value) * 0.05
			elif my_rank == 3:
				change = -randf_range(0.8, 1.6) - (Global.deviation_value - 45.0) * 0.05
			elif my_rank == 4:
				change = -randf_range(3.2, 4.8) - max(0.0, (Global.deviation_value - 40.0) * 0.15)
			
			change = clamp(change, -8.0, 8.0)
			var old_dev = Global.deviation_value
			var new_dev = clamp(old_dev + change, 30.0, 90.0)
			
			showdown_data["old_deviation"] = old_dev
			showdown_data["new_deviation"] = new_dev
			showdown_data["deviation_change"] = new_dev - old_dev
			showdown_data["old_league"] = Global.get_deviation_league(old_dev)
			showdown_data["new_league"] = Global.get_deviation_league(new_dev)
			showdown_data["league_upgraded"] = false
			showdown_data["league_downgraded"] = false

		old_deviation = showdown_data.get("old_deviation", Global.deviation_value)
		new_deviation = showdown_data.get("new_deviation", Global.deviation_value)
		deviation_change = showdown_data.get("deviation_change", 0.0)
		
		Global.deviation_value = snapped(new_deviation, 0.1)
		if Global.deviation_value > Global.max_deviation_value:
			Global.max_deviation_value = Global.deviation_value
		
		# サーバーへのスコア/レートアップロード
		var root = Engine.get_main_loop().root
		if root and root.has_node("BackendManager"):
			var bm = root.get_node("BackendManager")
			bm.upload_random_match_result(
				showdown_data.get("final_scores", {}).get("player", 0),
				my_rank,
				new_deviation,
				Global.get_deviation_league(new_deviation)
			)
	else:
		old_deviation = Global.deviation_value
		new_deviation = Global.deviation_value
		deviation_change = 0.0
		
	# Always save game at the end of showdown calculations
	Global.save_game()

func _play_chalk_deviation_animation() -> void:
	if is_instance_valid(skip_btn):
		skip_btn.queue_free()
		
	var fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for child in blackboard_vbox.get_children():
		if child != scorecard_label:
			fade_tween.tween_property(child, "modulate:a", 0.0, 0.4)
			
	await fade_tween.finished
	
	for child in blackboard_vbox.get_children():
		if child != scorecard_label:
			child.queue_free()
			
	var chalk_container = VBoxContainer.new()
	chalk_container.alignment = BoxContainer.ALIGNMENT_CENTER
	chalk_container.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM)
	blackboard_vbox.add_child(chalk_container)
	
	var title_lbl = Label.new()
	title_lbl.text = "今回の偏差値判定"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE_LARGE)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
	chalk_container.add_child(title_lbl)
	
	var val_hbox = HBoxContainer.new()
	val_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	val_hbox.add_theme_constant_override("separation", DeskTheme.MARGIN_LARGE)
	chalk_container.add_child(val_hbox)
	
	var old_val_box = Control.new()
	old_val_box.custom_minimum_size = Vector2(180, 80)
	val_hbox.add_child(old_val_box)
	
	var old_lbl = Label.new()
	old_lbl.text = "%.1f" % old_deviation
	old_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	old_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	old_lbl.add_theme_font_override("font", DeskTheme.get_font())
	old_lbl.add_theme_font_size_override("font_size", 64)
	old_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
	old_val_box.add_child(old_lbl)
	
	var arrow_lbl = Label.new()
	arrow_lbl.text = "→"
	arrow_lbl.add_theme_font_override("font", DeskTheme.get_font())
	arrow_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_GIANT)
	arrow_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
	val_hbox.add_child(arrow_lbl)
	
	var new_lbl = Label.new()
	new_lbl.text = "%.1f" % new_deviation
	new_lbl.add_theme_font_override("font", DeskTheme.get_font())
	new_lbl.add_theme_font_size_override("font_size", 72)
	
	if deviation_change >= 0:
		new_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
	else:
		new_lbl.add_theme_color_override("font_color", Color("ff6b6b"))
	val_hbox.add_child(new_lbl)
	
	new_lbl.pivot_offset = Vector2(40, 40)
	new_lbl.scale = Vector2.ZERO
	
	var change_lbl = Label.new()
	if deviation_change >= 0:
		change_lbl.text = "+%.1f アップ！" % deviation_change
		change_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
	else:
		change_lbl.text = "-%.1f ダウン..." % abs(deviation_change)
		change_lbl.add_theme_color_override("font_color", Color("ff6b6b"))
	change_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	change_lbl.add_theme_font_override("font", DeskTheme.get_font())
	change_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SUBTITLE)
	change_lbl.modulate.a = 0.0
	chalk_container.add_child(change_lbl)
	
	var line1 = Line2D.new()
	line1.width = 6.0
	line1.default_color = Color("ff4444", 0.9)
	line1.points = PackedVector2Array([Vector2(-10, 20), Vector2(-10, 20)])
	old_val_box.add_child(line1)
	
	var line2 = Line2D.new()
	line2.width = 6.0
	line2.default_color = Color("ff4444", 0.9)
	line2.points = PackedVector2Array([Vector2(-10, 45), Vector2(-10, 45)])
	old_val_box.add_child(line2)
	
	_anim_line1 = line1
	_anim_line2 = line2
	
	DeskTheme.shake_control(blackboard_panel, 2.0, 0.15)
	
	var timer_anim = get_tree().create_timer(0.8)
	await timer_anim.timeout
	if not is_instance_valid(self) or not is_inside_tree(): return
	
	var draw_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	draw_tween.tween_method(_set_line1_point, Vector2(-10, 20), Vector2(190, 60), 0.3)
	draw_tween.tween_method(_set_line2_point, Vector2(-10, 45), Vector2(190, 85), 0.3).set_delay(0.1)
	
	await draw_tween.finished
	if not is_instance_valid(self) or not is_inside_tree(): return
	DeskTheme.shake_control(blackboard_panel, 4.0, 0.2)
	
	var timer_pop = get_tree().create_timer(0.4)
	await timer_pop.timeout
	if not is_instance_valid(self) or not is_inside_tree(): return
	
	var pop_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(new_lbl, "scale", Vector2.ONE, 0.4)
	pop_tween.parallel().tween_property(change_lbl, "modulate:a", 1.0, 0.3).set_delay(0.15)
	
	await pop_tween.finished
	if not is_instance_valid(self) or not is_inside_tree(): return
	DeskTheme.shake_control(blackboard_panel, 6.0, 0.25)
	
	var timer_end = get_tree().create_timer(2.2)
	await timer_end.timeout
	if not is_instance_valid(self) or not is_inside_tree(): return
	
	var out_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	out_tween.tween_property(chalk_container, "modulate:a", 0.0, 0.4)
	await out_tween.finished
	if not is_instance_valid(self) or not is_inside_tree(): return
	
	trigger_report_card()

func _set_score_player(val: float) -> void:
	if _active_score_labels.has("player") and is_instance_valid(_active_score_labels["player"]):
		_active_score_labels["player"].text = "%d 点" % int(val)

func _set_score_sato(val: float) -> void:
	if _active_score_labels.has("cpu_sato") and is_instance_valid(_active_score_labels["cpu_sato"]):
		_active_score_labels["cpu_sato"].text = "%d 点" % int(val)

func _set_score_suzuki(val: float) -> void:
	if _active_score_labels.has("cpu_suzuki") and is_instance_valid(_active_score_labels["cpu_suzuki"]):
		_active_score_labels["cpu_suzuki"].text = "%d 点" % int(val)

func _set_score_takahashi(val: float) -> void:
	if _active_score_labels.has("cpu_takahashi") and is_instance_valid(_active_score_labels["cpu_takahashi"]):
		_active_score_labels["cpu_takahashi"].text = "%d 点" % int(val)

func _set_line1_point(val: Vector2) -> void:
	if is_instance_valid(_anim_line1):
		_anim_line1.set_point_position(1, val)

func _set_line2_point(val: Vector2) -> void:
	if is_instance_valid(_anim_line2):
		_anim_line2.set_point_position(1, val)


func _spawn_confetti() -> void:
	var vp_size = get_viewport_rect().size
	
	var confetti = CPUParticles2D.new()
	confetti.name = "ConfettiParticles"
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
	
	confetti.color = Color("ff3333") # Base vivid red for nice hue shifting
	confetti.hue_variation_min = -1.0
	confetti.hue_variation_max = 1.0
	
	root_layer.add_child(confetti)
	
	# Stop emitting after 8 seconds and queue_free after lifetime (5.0 seconds) to ensure clean removal
	var stop_timer = get_tree().create_timer(8.0)
	stop_timer.timeout.connect(func():
		if is_instance_valid(confetti):
			confetti.emitting = false
			var free_timer = get_tree().create_timer(confetti.lifetime)
			free_timer.timeout.connect(func():
				if is_instance_valid(confetti):
					confetti.queue_free()
			)
	)
