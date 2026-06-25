class_name HistoryModal
extends CanvasLayer

var session: GameSession

static func create_and_show(parent_node: Node, game_session: GameSession) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = HistoryModal.new()
	canvas.session = game_session
	parent_node.add_child(canvas)

func _ready() -> void:
	layer = 102 # 設定モーダルより少し上、または同等
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.45)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(700, 620)
	modal.pivot_offset = Vector2(350, 310)
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(modal)
	
	var viewport_size = get_viewport().get_visible_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 25)
	modal.add_child(margin)
	
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(root_vbox)
	
	# Title
	var title = Label.new()
	title.text = "📜 スコア・行動履歴"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	root_vbox.add_child(title)
	
	# Scroll area for history content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = Color(0, 0, 0, 0.03)
	scroll_style.corner_radius_top_left = 8
	scroll_style.corner_radius_top_right = 8
	scroll_style.corner_radius_bottom_left = 8
	scroll_style.corner_radius_bottom_right = 8
	scroll_style.content_margin_left = 15
	scroll_style.content_margin_right = 15
	scroll_style.content_margin_top = 15
	scroll_style.content_margin_bottom = 15
	scroll.add_theme_stylebox_override("panel", scroll_style)
	root_vbox.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 25)
	scroll.add_child(content_vbox)
	
	if session:
		_build_today_section(content_vbox)
		_build_past_days_section(content_vbox)
	else:
		var err_lbl = Label.new()
		err_lbl.text = "履歴データを読み込めませんでした。"
		err_lbl.add_theme_font_override("font", DeskTheme.get_font())
		err_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		content_vbox.add_child(err_lbl)
		
	# Close Button
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(bottom_hbox)
	
	var close_btn = Button.new()
	close_btn.text = " × 閉じる "
	close_btn.custom_minimum_size = Vector2(220, 45)
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 18)
	DeskTheme.apply_white_button_style(close_btn)
	close_btn.pressed.connect(func():
		close_btn.release_focus()
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			queue_free()
		)
	)
	bottom_hbox.add_child(close_btn)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)

func _build_today_section(container: VBoxContainer) -> void:
	var sec_vbox = VBoxContainer.new()
	sec_vbox.add_theme_constant_override("separation", 8)
	container.add_child(sec_vbox)
	
	var header = Label.new()
	header.text = "■ 本日の時限履歴 (第%d日目)" % session.current_day
	header.add_theme_font_override("font", DeskTheme.get_font())
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	sec_vbox.add_child(header)
	
	var history = session.player_hours_history_today
	if history.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "まだ本日の授業（チキンレース）を行っていません。"
		empty_lbl.add_theme_font_override("font", DeskTheme.get_font())
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color("78909c"))
		sec_vbox.add_child(empty_lbl)
	else:
		for i in range(history.size()):
			var record = history[i]
			var hour_idx = i + 1
			var draws = record.get("draws", 0)
			var bursted = record.get("bursted", false)
			var score = record.get("score", 0)
			
			var row_lbl = Label.new()
			var status_str = "バースト！ (0点)" if bursted else "+%d点" % score
			row_lbl.text = "  %d時限目 : %d枚引いた ── %s" % [hour_idx, draws, status_str]
			row_lbl.add_theme_font_override("font", DeskTheme.get_font())
			row_lbl.add_theme_font_size_override("font_size", 16)
			if bursted:
				row_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
			else:
				row_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			sec_vbox.add_child(row_lbl)
			
	var total_lbl = Label.new()
	total_lbl.text = "▶ 本日の獲得合計点 : %d点" % session.player_actual_score_today
	total_lbl.add_theme_font_override("font", DeskTheme.get_font())
	total_lbl.add_theme_font_size_override("font_size", 18)
	total_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	sec_vbox.add_child(total_lbl)

func _build_past_days_section(container: VBoxContainer) -> void:
	var match_hist = session.match_history
	var past_days: Array[int] = []
	for d in match_hist.keys():
		var day_int = int(str(d))
		if day_int < session.current_day and match_hist[d] is Dictionary and not match_hist[d].is_empty():
			past_days.append(day_int)
			
	past_days.sort()
	
	if past_days.is_empty():
		return
		
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	container.add_child(sep)
	
	var sec_vbox = VBoxContainer.new()
	sec_vbox.add_theme_constant_override("separation", 15)
	container.add_child(sec_vbox)
	
	var header = Label.new()
	header.text = "■ これまでのスコア履歴"
	header.add_theme_font_override("font", DeskTheme.get_font())
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	sec_vbox.add_child(header)
	
	for d in past_days:
		var day_data: Dictionary = match_hist[d]
		var day_vbox = VBoxContainer.new()
		day_vbox.add_theme_constant_override("separation", 6)
		sec_vbox.add_child(day_vbox)
		
		var day_lbl = Label.new()
		day_lbl.text = "【 第%d日目の成績 】" % d
		day_lbl.add_theme_font_override("font", DeskTheme.get_font())
		day_lbl.add_theme_font_size_override("font_size", 18)
		day_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		day_vbox.add_child(day_lbl)
		
		# Sort players: player first, then others
		var p_keys = day_data.keys()
		var sorted_keys = []
		if "player" in p_keys:
			sorted_keys.append("player")
		for k in p_keys:
			if k != "player":
				sorted_keys.append(k)
				
		for k in sorted_keys:
			var rec = day_data[k]
			var p_name = "あなた"
			var act_score = 0
			var dec_score = 0
			var exposed = false
			
			if rec is Dictionary:
				p_name = rec.get("name", str(k))
				if k == "player" and (p_name == "" or p_name == "player"):
					p_name = Global.player_name if Global.player_name != "" else "あなた"
				act_score = int(rec.get("actual_score", 0))
				dec_score = int(rec.get("declared_score", 0))
				exposed = bool(rec.get("is_doubt_exposed", false))
			elif rec is ParticipantRecord:
				p_name = rec.name
				if k == "player" and (p_name == "" or p_name == "player"):
					p_name = Global.player_name if Global.player_name != "" else "あなた"
				act_score = rec.actual_score
				dec_score = rec.declared_score
				exposed = rec.is_doubt_exposed
				
			var row = Label.new()
			if k == "player":
				var bluff_str = ""
				if dec_score != act_score:
					bluff_str = " (申告: %d点%s)" % [dec_score, " / ダウト看破！" if exposed else ""]
				row.text = "  ・ %s : 確定 %d点%s" % [p_name, act_score, bluff_str]
				row.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
			else:
				row.text = "  ・ %s : 申告 %d点" % [p_name, dec_score]
				row.add_theme_color_override("font_color", Color("455a64"))
			row.add_theme_font_override("font", DeskTheme.get_font())
			row.add_theme_font_size_override("font_size", 15)
			day_vbox.add_child(row)
