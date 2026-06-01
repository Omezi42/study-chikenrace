class_name LeaderboardModal
extends CanvasLayer

static func create_and_show(parent: Node) -> LeaderboardModal:
	var modal = LeaderboardModal.new()
	parent.add_child(modal)
	return modal

func _ready() -> void:
	layer = 100
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	var board = PanelContainer.new()
	board.custom_minimum_size = Vector2(500, 680)
	board.pivot_offset = Vector2(250, 340)
	
	var board_style = StyleBoxFlat.new()
	board_style.bg_color = Color("1e3d2f") # Blackboard green
	board_style.border_color = Color("8d6e63") # Wooden frame brown
	board_style.border_width_left = 10
	board_style.border_width_right = 10
	board_style.border_width_top = 10
	board_style.border_width_bottom = 10
	board_style.corner_radius_top_left = 6
	board_style.corner_radius_top_right = 6
	board_style.corner_radius_bottom_left = 6
	board_style.corner_radius_bottom_right = 6
	board_style.shadow_color = Color(0, 0, 0, 0.3)
	board_style.shadow_size = 12
	board_style.shadow_offset = Vector2(5, 5)
	board.add_theme_stylebox_override("panel", board_style)
	add_child(board)
	
	var viewport_size = get_viewport().get_visible_rect().size
	board.position = viewport_size * 0.5 - board.pivot_offset
	
	var board_margin = MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 20)
	board_margin.add_theme_constant_override("margin_right", 20)
	board_margin.add_theme_constant_override("margin_top", 20)
	board_margin.add_theme_constant_override("margin_bottom", 20)
	board.add_child(board_margin)
	
	var board_vbox = VBoxContainer.new()
	board_vbox.add_theme_constant_override("separation", 12)
	board_margin.add_child(board_vbox)
	
	var board_title = Label.new()
	board_title.text = "全国統一模試ランキング 🏆"
	board_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	board_title.add_theme_font_size_override("font_size", 24)
	board_title.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
	board_vbox.add_child(board_title)
	
	var leaderboard_scroll = ScrollContainer.new()
	leaderboard_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_vbox.add_child(leaderboard_scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	leaderboard_scroll.add_child(list_vbox)
	
	var leaderboard = get_mock_exam_leaderboard()
	for idx in range(leaderboard.size()):
		var entry = leaderboard[idx]
		
		var entry_hbox = HBoxContainer.new()
		list_vbox.add_child(entry_hbox)
		
		var rank_lbl = Label.new()
		rank_lbl.text = "%d位 " % (idx + 1)
		rank_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		rank_lbl.add_theme_font_size_override("font_size", 18)
		if idx == 0:
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
		else:
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		entry_hbox.add_child(rank_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = entry["name"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		name_lbl.add_theme_font_size_override("font_size", 18)
		if entry.get("is_player", false):
			name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		else:
			name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		entry_hbox.add_child(name_lbl)
		
		var score_lbl = Label.new()
		score_lbl.text = "%d点" % entry["score"]
		score_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		score_lbl.add_theme_font_size_override("font_size", 18)
		score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		entry_hbox.add_child(score_lbl)
		
	var close_btn = Button.new()
	close_btn.text = "閉じる ✖"
	close_btn.custom_minimum_size = Vector2(160, 45)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	close_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(close_btn)
	board_vbox.add_child(close_btn)
	
	close_btn.pressed.connect(func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var out_tween = create_tween().bind_node(board).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(board, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			queue_free()
		)
	)
	
	# Entrance Animation
	board.scale = Vector2.ZERO
	var tween = create_tween().bind_node(board).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(board, "scale", Vector2.ONE, 0.3)

func get_mock_exam_leaderboard() -> Array:
	var default_leaderboard = [
		{"name": "伝説のガリ勉 (偏差値 74)", "score": 240},
		{"name": "エナドリ極振りの狂人 (偏差値 69)", "score": 215},
		{"name": "佐藤くん (本気) (偏差値 65)", "score": 195},
		{"name": "絶対合格マン (偏差値 62)", "score": 178},
		{"name": "脳筋野球部 (偏差値 58)", "score": 158},
		{"name": "鈴木さん (本番) (偏差値 54)", "score": 142},
		{"name": "一夜漬けの達人 (偏差値 50)", "score": 120}
	]
	
	var player_best = Global.best_score
	var player_inserted = false
	var name_to_use = Global.player_name if Global.player_name != "" else "あなた"
	var player_lbl = "%s (偏差値 %.1f)" % [name_to_use, Global.max_deviation_value]
	
	var final_list = []
	for entry in default_leaderboard:
		if player_best > entry["score"] and not player_inserted:
			final_list.append({"name": player_lbl + " (あなた)", "score": player_best, "is_player": true})
			player_inserted = true
		final_list.append(entry)
		
	if not player_inserted:
		var placed = false
		for i in range(final_list.size()):
			if player_best > final_list[i]["score"]:
				final_list.insert(i, {"name": player_lbl + " (あなた)", "score": player_best, "is_player": true})
				placed = true
				break
		if not placed:
			final_list.append({"name": player_lbl + " (あなた)", "score": player_best, "is_player": true})
			
	return final_list.slice(0, 7)
