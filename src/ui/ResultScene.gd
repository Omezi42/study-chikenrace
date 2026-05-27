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

# Score details from session
var showdown_data: Dictionary
var current_step_day: int = 1
var is_revealing: bool = true

# Participant list for results
var participants: Array = []

func _ready() -> void:
	# Blackboard background
	var bg_color = ColorRect.new()
	bg_color.color = Color("1e3d2f") # Blackboard Green
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	# Load blackboard texture if exists
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if FileAccess.file_exists("res://assets/黒板.png"):
		bg_tex.texture = load("res://assets/黒板.png")
	add_child(bg_tex)
	
	# Main layout: Blackboard at center top, report card overlay later
	blackboard_panel = PanelContainer.new()
	blackboard_panel.custom_minimum_size = Vector2(1600, 850)
	
	var board_style = StyleBoxFlat.new()
	board_style.bg_color = Color(0.08, 0.22, 0.15, 0.9)
	board_style.border_color = Color("5d4037") # Wooden blackboard frame
	board_style.border_width_left = 16
	board_style.border_width_right = 16
	board_style.border_width_top = 16
	board_style.border_width_bottom = 16
	board_style.corner_radius_top_left = 6
	board_style.corner_radius_top_right = 6
	board_style.corner_radius_bottom_left = 6
	board_style.corner_radius_bottom_right = 6
	blackboard_panel.add_theme_stylebox_override("panel", board_style)
	add_child(blackboard_panel)
	blackboard_panel.position = Vector2((1920 - 1600) / 2.0, (1080 - 850) / 2.0)
	
	var board_margin = MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 30)
	board_margin.add_theme_constant_override("margin_right", 30)
	board_margin.add_theme_constant_override("margin_top", 30)
	board_margin.add_theme_constant_override("margin_bottom", 30)
	blackboard_panel.add_child(board_margin)
	
	blackboard_vbox = VBoxContainer.new()
	blackboard_vbox.add_theme_constant_override("separation", 20)
	board_margin.add_child(blackboard_vbox)
	
	# Blackboard Header
	scorecard_label = Label.new()
	scorecard_label.text = "学末テスト 答え合わせ黒板"
	scorecard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scorecard_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	scorecard_label.add_theme_font_size_override("font_size", 48)
	scorecard_label.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
	blackboard_vbox.add_child(scorecard_label)
	
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
		
	# Report Card Overlay Panel (Notebook spread, hidden initially)
	report_notebook = PanelContainer.new()
	report_notebook.custom_minimum_size = Vector2(1450, 780)
	report_notebook.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(report_notebook)
	report_notebook.position = Vector2((1920 - 1450) / 2.0, (1080 - 780) / 2.0)
	report_notebook.visible = false
	
	var note_hbox = HBoxContainer.new()
	note_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	note_hbox.add_theme_constant_override("separation", 60)
	report_notebook.add_child(note_hbox)
	
	# Left Page - Report details
	var left_p = MarginContainer.new()
	left_p.add_theme_constant_override("margin_left", 25)
	left_p.add_theme_constant_override("margin_right", 25)
	left_p.add_theme_constant_override("margin_top", 25)
	left_p.add_theme_constant_override("margin_bottom", 25)
	note_hbox.add_child(left_p)
	
	report_left_page = VBoxContainer.new()
	report_left_page.custom_minimum_size = Vector2(600, 680)
	report_left_page.add_theme_constant_override("separation", 20)
	left_p.add_child(report_left_page)
	
	# Right Page - Rankings leaderboard
	var right_p = MarginContainer.new()
	right_p.add_theme_constant_override("margin_left", 25)
	right_p.add_theme_constant_override("margin_right", 25)
	right_p.add_theme_constant_override("margin_top", 25)
	right_p.add_theme_constant_override("margin_bottom", 25)
	note_hbox.add_child(right_p)
	
	report_right_page = VBoxContainer.new()
	report_right_page.custom_minimum_size = Vector2(600, 680)
	report_right_page.add_theme_constant_override("separation", 20)
	right_p.add_child(report_right_page)
	
	# Start daily reveal animation loop
	is_revealing = true
	current_step_day = 1
	reveal_next_day_showdown()

func reveal_next_day_showdown() -> void:
	if current_step_day > 5:
		# Reveal complete! Trigger report card overlay
		is_revealing = false
		trigger_report_card()
		return
		
	# Clear older elements so we only show the current day's reveal
	for child in blackboard_vbox.get_children():
		if child != scorecard_label:
			child.queue_free()
			
	# Day Title
	var day_lbl = Label.new()
	day_lbl.text = "【 第 %d 日目：申告点 ➔ 実点 答え合わせ 】" % current_step_day
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	day_lbl.add_theme_font_size_override("font_size", 28)
	day_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
	blackboard_vbox.add_child(day_lbl)
	
	# Cards HBox Container
	var cards_hbox = HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", 35)
	blackboard_vbox.add_child(cards_hbox)
	
	var day_details = showdown_data["details"][current_step_day]
	var any_exposed = false
	
	# Render 4 Cards
	for p_id in day_details.keys():
		var info = day_details[p_id]
		var is_exposed = info["is_doubt_exposed"]
		var actual = info["actual"]
		var declared = info["declared"]
		var name_str = "あなた"
		if p_id != "player":
			if Global.opponent_profiles.has(p_id):
				name_str = Global.opponent_profiles[p_id]["name"]
			elif AIManager.CPU_OPPONENTS.has(p_id):
				name_str = AIManager.CPU_OPPONENTS[p_id]["name"]
			else:
				name_str = "ライバル"
			
		# Chalk Card Panel
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(320, 260)
		card.pivot_offset = Vector2(160, 130)
		cards_hbox.add_child(card)
		
		# Base chalk card style (semi-transparent dark green, like chalk writing)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.22, 0.15, 0.85)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		
		# Set card border colors based on honesty
		if declared > actual:
			if is_exposed:
				style.border_color = Color("ff6b6b", 0.8) # Sakura/red chalk
				any_exposed = true
			else:
				style.border_color = Color("ffe066", 0.8) # Yellow chalk
		else:
			style.border_color = Color("80e680", 0.8) # Green chalk
			
		card.add_theme_stylebox_override("panel", style)
		
		# Inner Margin
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_bottom", 20)
		card.add_child(margin)
		
		# VBox content
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 10)
		margin.add_child(vbox)
		
		# Name Label
		var name_lbl = Label.new()
		name_lbl.text = name_str
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		name_lbl.add_theme_font_size_override("font_size", 26)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(name_lbl)
		
		# Chalk line separator
		var line = ColorRect.new()
		line.color = Color(1.0, 1.0, 1.0, 0.25)
		line.custom_minimum_size = Vector2(0, 2)
		vbox.add_child(line)
		
		# Declared Score
		var decl_lbl = Label.new()
		decl_lbl.text = "申告: %d 点" % declared
		decl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		decl_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		decl_lbl.add_theme_font_size_override("font_size", 22)
		decl_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		vbox.add_child(decl_lbl)
		
		# Actual Score
		var act_lbl = Label.new()
		act_lbl.text = "実点: %d 点" % actual
		act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		act_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		act_lbl.add_theme_font_size_override("font_size", 22)
		act_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
		vbox.add_child(act_lbl)
		
		# Stamp/Badge container
		var stamp_container = CenterContainer.new()
		vbox.add_child(stamp_container)
		
		# Rubber stamp badge label
		var stamp_lbl = Label.new()
		stamp_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		stamp_lbl.add_theme_font_size_override("font_size", 18)
		
		var stamp_style = StyleBoxFlat.new()
		stamp_style.bg_color = Color(0.08, 0.22, 0.15, 0.0) # Transparent bg
		stamp_style.border_width_left = 2
		stamp_style.border_width_right = 2
		stamp_style.border_width_top = 2
		stamp_style.border_width_bottom = 2
		stamp_style.corner_radius_top_left = 4
		stamp_style.corner_radius_top_right = 4
		stamp_style.corner_radius_bottom_left = 4
		stamp_style.corner_radius_bottom_right = 4
		stamp_style.content_margin_left = 12
		stamp_style.content_margin_right = 12
		stamp_style.content_margin_top = 4
		stamp_style.content_margin_bottom = 4
		
		if declared > actual:
			if is_exposed:
				stamp_lbl.text = " 嘘バレ！ "
				stamp_lbl.add_theme_color_override("font_color", Color("ff6b6b"))
				stamp_style.border_color = Color("ff6b6b")
			else:
				stamp_lbl.text = " セーフ "
				stamp_lbl.add_theme_color_override("font_color", Color("ffe066"))
				stamp_style.border_color = Color("ffe066")
		else:
			stamp_lbl.text = " 正直 "
			stamp_lbl.add_theme_color_override("font_color", Color("80e680"))
			stamp_style.border_color = Color("80e680")
			
		stamp_lbl.add_theme_stylebox_override("normal", stamp_style)
		stamp_container.add_child(stamp_lbl)
		
		# Entrance scale pop animation for cards
		card.scale = Vector2.ZERO
		var c_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		c_tween.tween_property(card, "scale", Vector2.ONE, 0.25)
		
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
			x_tween.tween_method(func(val: Vector2): line1.set_point_position(1, val), Vector2(15, 15), Vector2(305, 245), 0.3).set_delay(0.3)
			x_tween.tween_method(func(val: Vector2): line2.set_point_position(1, val), Vector2(305, 15), Vector2(15, 245), 0.3).set_delay(0.45)
			
	# Camera shake for dramatic exposure if anyone was caught lying
	if any_exposed:
		var shake_timer = get_tree().create_timer(0.4)
		shake_timer.timeout.connect(func():
			DeskTheme.shake_control(blackboard_panel, 12.0, 0.35)
		)
	else:
		DeskTheme.shake_control(blackboard_panel, 4.0, 0.2)
		
	# Go to next day after delay
	var timer = get_tree().create_timer(1.8)
	timer.timeout.connect(func():
		current_step_day += 1
		reveal_next_day_showdown()
	)

func trigger_report_card() -> void:
	blackboard_panel.visible = false
	report_notebook.visible = true
	
	# Slide notebook down from top with swing and bounce
	var target_pos = report_notebook.position
	DeskTheme.animate_entrance(report_notebook, target_pos, Vector2(0, -400), 0.6)
	
	# Build Left Page (Player scorecard)
	var rank_title = Label.new()
	rank_title.text = "学末最終成績通知表"
	rank_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	rank_title.add_theme_font_size_override("font_size", 32)
	rank_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	report_left_page.add_child(rank_title)
	
	var my_score = showdown_data["final_scores"]["player"]
	var score_lbl = Label.new()
	score_lbl.text = "総合得点: " + str(my_score) + " 点"
	score_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	score_lbl.add_theme_font_size_override("font_size", 54)
	score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	report_left_page.add_child(score_lbl)
	
	# Calculate Deviation Value if playing national mode
	if Global.game_mode == "national":
		var change = 0.0
		var my_rank = showdown_data["my_rank"]
		if my_rank == 1:
			change = randf_range(3.2, 4.8) + max(0.0, (60.0 - Global.deviation_value) * 0.15)
		elif my_rank == 2:
			change = randf_range(0.8, 1.6) + (55.0 - Global.deviation_value) * 0.05
		elif my_rank == 3:
			change = -randf_range(0.8, 1.6) - (Global.deviation_value - 45.0) * 0.05
		elif my_rank == 4:
			change = -randf_range(3.2, 4.8) - max(0.0, (Global.deviation_value - 40.0) * 0.15)
		
		change = clamp(change, -8.0, 8.0)
		var old_deviation = Global.deviation_value
		var new_deviation = clamp(old_deviation + change, 30.0, 90.0)
		Global.deviation_value = snapped(new_deviation, 0.1)
		if Global.deviation_value > Global.max_deviation_value:
			Global.max_deviation_value = Global.deviation_value
		Global.save_game()
		
		var deviation_change_lbl = Label.new()
		deviation_change_lbl.text = "全国統一模試 偏差値: %.1f (前回: %.1f)\n" % [Global.deviation_value, old_deviation]
		if change >= 0:
			deviation_change_lbl.text += "➔ 偏差値が %.1f アップしました！ 📈" % change
			deviation_change_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BONUS)
		else:
			deviation_change_lbl.text += "➔ 偏差値が %.1f ダウンしました... 📉" % abs(change)
			deviation_change_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		deviation_change_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		deviation_change_lbl.add_theme_font_size_override("font_size", 22)
		report_left_page.add_child(deviation_change_lbl)
	
	# Breakdown stats
	var breakdown = Label.new()
	breakdown.text = "・レベルボーナス：+" + str(showdown_data["level_bonus"]) + "点\n" + \
					"・獲得したコイン：+" + str(showdown_data["coins_earned"]) + "枚\n" + \
					"・完全犯罪ボーナス：+" + str(showdown_data["perfect_bonus"]) + "枚"
	breakdown.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	breakdown.add_theme_font_size_override("font_size", 22)
	breakdown.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	report_left_page.add_child(breakdown)
	
	var title_lbl = Label.new()
	title_lbl.text = "獲得した称号:\n【 " + showdown_data["title"] + " 】"
	title_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color("3f51b5"))
	report_left_page.add_child(title_lbl)
	
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
	lead_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	lead_title.add_theme_font_size_override("font_size", 32)
	lead_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	report_right_page.add_child(lead_title)
	
	var ranks = showdown_data["rankings"]
	for r_idx in range(ranks.size()):
		var r = ranks[r_idx]
		
		var medal = ""
		match r_idx:
			0: medal = "🥇 1位: "
			1: medal = "🥈 2位: "
			2: medal = "🥉 3位: "
			_: medal = "   4位: "
			
		var r_lbl = Label.new()
		r_lbl.text = medal + r["name"] + " (" + str(r["score"]) + "点, 寝落ち " + str(r["bursts"]) + "回)"
		r_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		r_lbl.add_theme_font_size_override("font_size", 22)
		
		if r["id"] == "player":
			r_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		else:
			r_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			
		report_right_page.add_child(r_lbl)
		
	# Actions HBox
	var act_hbox = HBoxContainer.new()
	act_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	act_hbox.add_theme_constant_override("separation", 30)
	report_right_page.add_child(act_hbox)
	
	share_btn = Button.new()
	share_btn.text = "𝕏 で結果を自慢"
	share_btn.custom_minimum_size = Vector2(260, 65)
	share_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	share_btn.add_theme_font_size_override("font_size", 22)
	share_btn.pressed.connect(_on_share_pressed)
	act_hbox.add_child(share_btn)
	
	restart_btn = Button.new()
	restart_btn.text = "タイトルに戻る"
	restart_btn.custom_minimum_size = Vector2(260, 65)
	restart_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	restart_btn.add_theme_font_size_override("font_size", 22)
	restart_btn.pressed.connect(_on_restart_pressed)
	act_hbox.add_child(restart_btn)

func _on_share_pressed() -> void:
	DeskTheme.animate_click(share_btn, Vector2.ONE, 0.08)
	var my_score = showdown_data["final_scores"]["player"]
	var text_to_tweet = "『テスト勉強チキンレース』で称号【" + showdown_data["title"] + "】を獲得！最終スコア：" + str(my_score) + "点！ #テスト勉強チキンレース"
	var escaped_text = text_to_tweet.uri_encode()
	OS.shell_open("https://twitter.com/intent/tweet?text=" + escaped_text)

func _on_restart_pressed() -> void:
	DeskTheme.animate_click(restart_btn, Vector2.ONE, 0.08)
	
	# Clear active results in global
	Global.set("active_showdown_results", {})
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)
