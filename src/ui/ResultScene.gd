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
	add_child(root_layer)
	_build_scripted_background()

	# Main layout: Blackboard at center top, report card overlay later
	blackboard_panel = PanelContainer.new()
	blackboard_panel.custom_minimum_size = Vector2(1480, 760)
	
	var board_style = StyleBoxFlat.new()
	board_style.bg_color = Color("f7f2e8")
	board_style.border_color = Color("b59d7a")
	board_style.border_width_left = 5
	board_style.border_width_right = 5
	board_style.border_width_top = 5
	board_style.border_width_bottom = 5
	board_style.corner_radius_top_left = 14
	board_style.corner_radius_top_right = 14
	board_style.corner_radius_bottom_left = 14
	board_style.corner_radius_bottom_right = 14
	board_style.shadow_color = Color(0, 0, 0, 0.18)
	board_style.shadow_size = 16
	board_style.shadow_offset = Vector2(6, 8)
	blackboard_panel.add_theme_stylebox_override("panel", board_style)
	root_layer.add_child(blackboard_panel)
	blackboard_panel.pivot_offset = blackboard_panel.custom_minimum_size * 0.5
	blackboard_panel.position = get_viewport_rect().size * 0.5 - blackboard_panel.custom_minimum_size * 0.5
	
	var board_margin = MarginContainer.new()
	board_margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_DEFAULT)
	board_margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_DEFAULT)
	blackboard_panel.add_child(board_margin)
	
	blackboard_vbox = VBoxContainer.new()
	blackboard_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL)
	board_margin.add_child(blackboard_vbox)
	
	# Result Header
	scorecard_label = Label.new()
	scorecard_label.text = "学末最終成績通知表"
	scorecard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scorecard_label.add_theme_font_override("font", DeskTheme.get_font())
	scorecard_label.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE_LARGE)
	scorecard_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	blackboard_vbox.add_child(scorecard_label)

	# Title for cumulative score chart
	chart_title = Label.new()
	chart_title.text = "累計獲得点数"
	chart_title.add_theme_font_override("font", DeskTheme.get_font())
	chart_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	chart_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	blackboard_vbox.add_child(chart_title)

	day_chart_area = Control.new()
	day_chart_area.custom_minimum_size = Vector2(1320, 180)
	blackboard_vbox.add_child(day_chart_area)
	_build_day_chart_shell()
	
	# Instantiate dummy session data or retrieve from active session
	var raw_results = Global.get("active_showdown_results")
	if raw_results and not raw_results.is_empty():
		showdown_data = raw_results
	else:
		# Fallback simulation for testing/standalone play
		var dummy_session = GameSession.new()
		dummy_session.start_session(Global.current_deck)
		for day in range(1, 6):
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
		
	# Report Card Overlay Panel (Notebook spread, hidden initially)
	report_notebook = PanelContainer.new()
	report_notebook.custom_minimum_size = Vector2(1450, 780)
	report_notebook.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	root_layer.add_child(report_notebook)
	report_notebook.pivot_offset = report_notebook.custom_minimum_size * 0.5
	report_notebook.position = get_viewport_rect().size * 0.5 - report_notebook.custom_minimum_size * 0.5
	report_notebook.visible = false
	
	var note_hbox = HBoxContainer.new()
	note_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	note_hbox.add_theme_constant_override("separation", 60)
	report_notebook.add_child(note_hbox)
	
	# Left Page - Report details
	var left_p = MarginContainer.new()
	left_p.add_theme_constant_override("margin_left", DeskTheme.MARGIN_MEDIUM)
	left_p.add_theme_constant_override("margin_right", DeskTheme.MARGIN_MEDIUM)
	left_p.add_theme_constant_override("margin_top", DeskTheme.MARGIN_MEDIUM)
	left_p.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_MEDIUM)
	note_hbox.add_child(left_p)
	
	report_left_page = VBoxContainer.new()
	report_left_page.custom_minimum_size = Vector2(600, 680)
	report_left_page.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL)
	left_p.add_child(report_left_page)
	
	# Right Page - Rankings leaderboard
	var right_p = MarginContainer.new()
	right_p.add_theme_constant_override("margin_left", DeskTheme.MARGIN_MEDIUM)
	right_p.add_theme_constant_override("margin_right", DeskTheme.MARGIN_MEDIUM)
	right_p.add_theme_constant_override("margin_top", DeskTheme.MARGIN_MEDIUM)
	right_p.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_MEDIUM)
	note_hbox.add_child(right_p)
	
	report_right_page = VBoxContainer.new()
	report_right_page.custom_minimum_size = Vector2(600, 680)
	report_right_page.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL)
	right_p.add_child(report_right_page)
	
	# Skip button at bottom right
	skip_btn = Button.new()
	skip_btn.text = "結果へスキップ >>"
	skip_btn.custom_minimum_size = Vector2(240, 60)
	skip_btn.add_theme_font_override("font", DeskTheme.get_font())
	skip_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	skip_btn.pressed.connect(_on_skip_pressed)
	
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color(DeskTheme.COLOR_MAHOGANY, 0.8)
	skip_style.corner_radius_top_left = 6
	skip_style.corner_radius_top_right = 6
	skip_style.corner_radius_bottom_left = 6
	skip_style.corner_radius_bottom_right = 6
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	skip_btn.add_theme_stylebox_override("hover", skip_style)
	skip_btn.add_theme_stylebox_override("pressed", skip_style)
	
	root_layer.add_child(skip_btn)
	_reflow_layout()
	
	# Start daily reveal animation loop
	is_revealing = true
	current_step_day = 1
	reveal_next_day_showdown()

func _build_scripted_background() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("214b3b")
	root_layer.add_child(bg)

	board_frame = ColorRect.new()
	board_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_frame.color = Color("7a5633")
	board_frame.modulate.a = 0.95
	root_layer.add_child(board_frame)

	board_inner = ColorRect.new()
	board_inner.color = Color("1f4d3a")
	board_inner.modulate.a = 0.98
	root_layer.add_child(board_inner)

	var grain = ColorRect.new()
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.color = Color(0.95, 0.85, 0.65, 0.06)
	root_layer.add_child(grain)

	var vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.03, 0.02, 0.01, 0.22)
	root_layer.add_child(vignette)

func _reflow_layout() -> void:
	if not is_inside_tree():
		return
	var vp_size = get_viewport_rect().size
	if is_instance_valid(blackboard_panel):
		blackboard_panel.position = vp_size * 0.5 - blackboard_panel.custom_minimum_size * 0.5
	if is_instance_valid(report_notebook):
		report_notebook.position = vp_size * 0.5 - report_notebook.custom_minimum_size * 0.5
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
		var name_str = "ライバル"
		if p_id != "player":
			if Global.opponent_profiles.has(p_id):
				name_str = Global.opponent_profiles[p_id].get("name", "ライバル")
			else:
				name_str = AIManager.get_cpu_name(p_id)
			
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
		name_lbl.text = _get_participant_name(p_id)
		name_lbl.custom_minimum_size = Vector2(120, 0)
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		hbox.add_child(name_lbl)
		
		var bar_wrap = PanelContainer.new()
		bar_wrap.custom_minimum_size = Vector2(1000, 22)
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
		fill.color = Color("6bbf59") if p_id == "player" else Color("3f51b5")
		fill.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		fill.size = Vector2(1, 22)
		bar_wrap.add_child(fill)
		
		var score_lbl = Label.new()
		score_lbl.name = "score_lbl"
		score_lbl.text = "0 点"
		score_lbl.custom_minimum_size = Vector2(80, 0)
		score_lbl.add_theme_font_override("font", DeskTheme.get_font())
		score_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
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
		return "あなた"
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
	
	blackboard_panel.visible = false
	report_notebook.visible = true
	
	# Slide notebook down from top with swing and bounce
	var target_pos = report_notebook.position
	DeskTheme.animate_entrance(report_notebook, target_pos, Vector2(0, -400), 0.6)
	
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
	
	# Breakdown stats
	var breakdown = Label.new()
	var star_bonus_val = showdown_data.get("star_bonus", 0)
	var star_text = ""
	if star_bonus_val > 0:
		star_text = "\n・★アイテム育成ボーナス：+" + str(star_bonus_val) + "点"
	breakdown.text = "・レベルボーナス：+" + str(showdown_data["level_bonus"]) + "点" + star_text
	breakdown.add_theme_font_override("font", DeskTheme.get_font())
	breakdown.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	breakdown.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	report_left_page.add_child(breakdown)
	
	# Coin earning rollup section (Loop 12)
	var coin_hbox = HBoxContainer.new()
	coin_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	coin_hbox.add_theme_constant_override("separation", 2)
	report_left_page.add_child(coin_hbox)
	
	var coin_icon = Label.new()
	coin_icon.text = "・獲得したコイン："
	coin_icon.add_theme_font_override("font", DeskTheme.get_font())
	coin_icon.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	coin_icon.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	coin_hbox.add_child(coin_icon)
	
	var coin_val_lbl = Label.new()
	coin_val_lbl.text = "+0枚"
	coin_val_lbl.add_theme_font_override("font", DeskTheme.get_font())
	coin_val_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	coin_val_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	coin_hbox.add_child(coin_val_lbl)
	
	var target_coins = showdown_data["coins_earned"] + showdown_data["perfect_bonus"]
	if target_coins > 0:
		var tween = create_tween()
		var update_coin_func = func(current_val: int):
			if is_instance_valid(coin_val_lbl):
				coin_val_lbl.text = "+" + str(current_val) + "枚"
				if showdown_data["perfect_bonus"] > 0:
					coin_val_lbl.text += " (内 完全犯罪ボーナス: +%d枚)" % showdown_data["perfect_bonus"]
				
				var prev_val = coin_val_lbl.get_meta("last_val", 0)
				if current_val != prev_val:
					coin_val_lbl.set_meta("last_val", current_val)
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_se(AudioManager.SE_CLICK)
						
		tween.tween_method(update_coin_func, 0, target_coins, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		coin_val_lbl.text = "+0枚"
	
	# 称号スタンプ風UI & アニメーション演出
	var title_container = VBoxContainer.new()
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	title_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	report_left_page.add_child(title_container)
	
	var title_desc = Label.new()
	title_desc.text = "獲得した称号"
	title_desc.add_theme_font_override("font", DeskTheme.get_font())
	title_desc.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	title_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	title_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title_desc)
	
	var stamp_style = DeskTheme.create_stamp_style(Color("c62828"), Color(1, 0.9, 0.9, 0.3))
	
	var stamp_panel = PanelContainer.new()
	stamp_panel.add_theme_stylebox_override("panel", stamp_style)
	stamp_panel.pivot_offset = Vector2(100, 25)
	stamp_panel.rotation_degrees = -6.0
	title_container.add_child(stamp_panel)
	
	var title_lbl = Label.new()
	title_lbl.text = "【 " + showdown_data["title"] + " 】"
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color("c62828"))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_panel.add_child(title_lbl)
	
	stamp_panel.scale = Vector2(3.0, 3.0)
	stamp_panel.modulate.a = 0.0
	
	var s_tween = create_tween()
	s_tween.tween_interval(0.4)
	
	s_tween.tween_property(stamp_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	s_tween.parallel().tween_property(stamp_panel, "modulate.a", 1.0, 0.2)
	
	s_tween.tween_callback(func():
		DeskTheme.shake_control(stamp_panel, 8.0, 0.25)
	)
	
	# If S-grade (250+ points), stamp a huge hanamaru (花丸スタンプ)
	if my_score >= 250:
		var hanamaru = TextureRect.new()
		hanamaru.custom_minimum_size = Vector2(180, 180)
		hanamaru.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if FileAccess.file_exists("res://assets/はなまるスタンプ.png"):
			hanamaru.texture = load("res://assets/はなまるスタンプ.png")
		report_left_page.add_child(hanamaru)
		
		# Hanamaru stamp landing bounce and screen shake
		hanamaru.scale = Vector2(4.0, 4.0)
		var h_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		h_tween.tween_property(hanamaru, "scale", Vector2.ONE, 0.4)
		h_tween.tween_callback(func():
			DeskTheme.shake_control(report_notebook, 14.0, 0.3)
		)
		
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
	graph_area.add_theme_constant_override("separation", DeskTheme.MARGIN_TINY)
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

		var bar_name = Label.new()
		bar_name.text = "%s" % r["name"]
		bar_name.add_theme_font_override("font", DeskTheme.get_font())
		bar_name.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
		bar_name.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.9))
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

		var bar_fill = ColorRect.new()
		bar_fill.color = Color("6bbf59") if r["id"] == "player" else Color("3f51b5")
		bar_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bar_fill.size = Vector2(1, 22)
		bar_back.add_child(bar_fill)

		var score_ratio = float(r["score"]) / float(max_score)
		var target_width = int(520 * score_ratio)
		var bar_tween = create_tween().bind_node(bar_fill).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bar_tween.tween_property(bar_fill, "size:x", max(8, target_width), 0.7 + 0.08 * r_idx)
		bar_tween.tween_callback(func():
			if r["id"] == "player":
				DeskTheme.shake_control(report_notebook, 6.0, 0.12)
		)

	# Actions HBox
	var act_hbox = HBoxContainer.new()
	act_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	act_hbox.add_theme_constant_override("separation", DeskTheme.MARGIN_DEFAULT)
	report_right_page.add_child(act_hbox)
	
	share_btn = Button.new()
	share_btn.text = "Xでシェア"
	share_btn.custom_minimum_size = Vector2(260, 65)
	share_btn.add_theme_font_override("font", DeskTheme.get_font())
	share_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	Global.apply_white_button_style(share_btn)
	share_btn.pressed.connect(_on_share_pressed)
	act_hbox.add_child(share_btn)
	
	restart_btn = Button.new()
	restart_btn.text = "タイトルへ"
	restart_btn.custom_minimum_size = Vector2(260, 65)
	restart_btn.add_theme_font_override("font", DeskTheme.get_font())
	restart_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	Global.apply_white_button_style(restart_btn)
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

func _calculate_deviation() -> void:
	if Global.game_mode == Constants.MODE_RANDOM:
		if not showdown_data.has("deviation_change"):
			# フォールバック処理 (テストコード実行時など)
			var change = 0.0
			var my_rank = showdown_data.get("my_rank", 3)
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
		Global.save_game()
		
		# サーバーへのスコア/レートアップロード
		if has_node("/root/BackendManager"):
			var bm = get_node("/root/BackendManager")
			bm.upload_random_match_result(
				showdown_data.get("final_scores", {}).get("player", 0),
				showdown_data.get("my_rank", 3),
				new_deviation,
				Global.get_deviation_league(new_deviation)
			)
	else:
		old_deviation = Global.deviation_value
		new_deviation = Global.deviation_value
		deviation_change = 0.0

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
