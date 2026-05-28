class_name DailyLikesPhase
extends PhaseBase

# UI Controls
var phone_panel: PanelContainer
var timeline_list: VBoxContainer
var next_day_btn: Button
var remaining_doubts_label: Label

# Detail Inspection Modal
var detail_modal: PanelContainer
var detail_title: Label
var detail_body: Label
var detail_log_vbox: VBoxContainer
var close_detail_btn: Button

# Daily state
var participants_data: Array = []
var local_doubts_count: int = 3 # 3 doubt votes per day max

func _on_setup(_setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(1500, 850)
	var max_doubts = 1 if Global.game_mode == "cram" else 3
	local_doubts_count = max_doubts - session.player_doubts_made_today.size()
	
	# Layout setup: Left is Phone, Right is controls & inspection
	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 60)
	add_child(main_hbox)
	
	# SMARTPHONE CONTAINER (Phone UI Frame)
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
	
	# Inside Phone: Timeline layout scroll
	var phone_vbox = VBoxContainer.new()
	phone_panel.add_child(phone_vbox)
	
	# Status bar
	var status_bar = Label.new()
	status_bar.text = "16:00  |  チキスタ"
	status_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_bar.add_theme_font_size_override("font_size", 16)
	status_bar.add_theme_color_override("font_color", Color.WHITE)
	phone_vbox.add_child(status_bar)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	phone_vbox.add_child(scroll)
	
	timeline_list = VBoxContainer.new()
	timeline_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_list.add_theme_constant_override("separation", 18)
	scroll.add_child(timeline_list)
	
	# RIGHT COLUMN: Inspection and Progress
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(750, 780)
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 35)
	main_hbox.add_child(right_vbox)
	
	remaining_doubts_label = Label.new()
	remaining_doubts_label.text = "今日のダウト投票可能数：3回"
	remaining_doubts_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	remaining_doubts_label.add_theme_font_size_override("font_size", 28)
	remaining_doubts_label.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	right_vbox.add_child(remaining_doubts_label)
	
	# Detail Modal Wrapper (to isolate detail_modal from VBoxContainer positioning during shakes)
	var detail_wrapper = Control.new()
	detail_wrapper.custom_minimum_size = Vector2(650, 360)
	right_vbox.add_child(detail_wrapper)
	
	detail_modal = PanelContainer.new()
	detail_modal.custom_minimum_size = Vector2(650, 360)
	detail_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	detail_wrapper.add_child(detail_modal)
	
	var detail_margin = MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 20)
	detail_margin.add_theme_constant_override("margin_right", 20)
	detail_margin.add_theme_constant_override("margin_top", 20)
	detail_margin.add_theme_constant_override("margin_bottom", 20)
	detail_modal.add_child(detail_margin)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 12)
	detail_margin.add_child(detail_vbox)
	
	detail_title = Label.new()
	detail_title.text = "ライバル詳細ログ"
	detail_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	detail_title.add_theme_font_size_override("font_size", 26)
	detail_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_vbox.add_child(detail_title)
	
	detail_body = Label.new()
	detail_body.text = "タイムラインの「詳細確認」を押すと、ライバルが今日引いたドロー数と使用したアイテムのログがここに表示されます。"
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	detail_body.add_theme_font_size_override("font_size", 20)
	detail_body.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	detail_body.custom_minimum_size = Vector2(580, 200)
	detail_vbox.add_child(detail_body)
	
	detail_log_vbox = VBoxContainer.new()
	detail_log_vbox.add_theme_constant_override("separation", 14)
	detail_vbox.add_child(detail_log_vbox)
	
	# Next day button
	next_day_btn = Button.new()
	next_day_btn.text = "明日の勉強へ進む"
	next_day_btn.custom_minimum_size = Vector2(360, 65)
	next_day_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	next_day_btn.add_theme_font_size_override("font_size", 24)
	next_day_btn.pressed.connect(_on_next_day_pressed)
	right_vbox.add_child(next_day_btn)
	
	# Fetch participants data
	collect_participants()
	populate_timeline()
	update_remaining_votes()
	
	# Entrance slide in on main_hbox instead of self
	DeskTheme.animate_entrance(main_hbox, Vector2.ZERO, Vector2(0, 300), 0.5)
	
	if Global.is_tutorial_mode and session.current_day == 1:
		next_day_btn.text = "チュートリアルを完了する"
		show_tutorial_dialog(
			"チキスタ投票・ダウトフェーズです！\n\nライバルの投稿をチェックしましょう。ドロー枚数に対して申告点が高すぎるライバルはブラフの可能性があります！\n\n『詳細確認』でログを調べ、怪しいライバルには『ダウト』を宣言しましょう！成功すれば盛り点分のボーナスを獲得できます。\n確認したらボタンを押してチュートリアルを完了しましょう！",
			Vector2(780, 20)
		)

func collect_participants() -> void:
	participants_data.clear()
	var day_data = session.match_history[session.current_day]
	
	# Collect player
	var player_name_val = Global.player_name if Global.player_name != "" else "あなた"
	participants_data.append({
		"id": "player",
		"name": player_name_val,
		"declared_score": session.player_declared_score_today,
		"actual_score": session.player_actual_score_today,
		"hours": session.player_hours_history_today,
		"avatar_color": DeskTheme.COLOR_GREEN
	})
	
	# Collect rivals (CPUs and other players)
	for opp_id in day_data.keys():
		if opp_id == "player":
			continue
			
		var opp = day_data[opp_id]
		var color_val = DeskTheme.COLOR_MAHOGANY
		var opp_name = opp.get("name", opp.get("username", "ライバル"))
		
		# Determine avatar color if it is a registered CPU
		var actual_profile_id = opp_id
		if Global.opponent_profiles.has(opp_id):
			actual_profile_id = Global.opponent_profiles[opp_id].get("id", opp_id)
			
		if AIManager.CPU_OPPONENTS.has(actual_profile_id):
			var cpu_meta = AIManager.CPU_OPPONENTS[actual_profile_id]
			if cpu_meta["type"] == AIManager.TYPE_BLUFFER:
				color_val = DeskTheme.COLOR_TENSION
			elif cpu_meta["type"] == AIManager.TYPE_CAUTIOUS:
				color_val = DeskTheme.COLOR_ROLE_PREP
		else:
			# For actual human friends, use blue Pen color as a distinct avatar color
			color_val = Color("2979ff") 
			
		participants_data.append({
			"id": opp_id,
			"name": opp_name,
			"declared_score": int(opp.get("declared_score", 0)),
			"actual_score": int(opp.get("actual_score", 0)),
			"hours": opp.get("hours", opp.get("hours_history", [])),
			"avatar_color": color_val
		})
		
	# Sort participants by declared score descending for timeline rank
	participants_data.sort_custom(func(a, b): return a["declared_score"] > b["declared_score"])

func populate_timeline() -> void:
	for child in timeline_list.get_children():
		child.queue_free()
		
	for idx in range(participants_data.size()):
		var p = participants_data[idx]
		
		# Timeline Post Card
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(480, 130)
		card.pivot_offset = Vector2(240, 65)
		
		# Rank border styling
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = DeskTheme.COLOR_CRAFT
		card_style.corner_radius_top_left = 6
		card_style.corner_radius_top_right = 6
		card_style.corner_radius_bottom_left = 6
		card_style.corner_radius_bottom_right = 6
		card_style.border_width_left = 4
		card_style.border_width_right = 1
		card_style.border_width_top = 1
		card_style.border_width_bottom = 1
		
		# Rank indicators
		if idx == 0:
			card_style.border_color = Color("ffd700") # Gold
		elif idx == 1:
			card_style.border_color = Color("c0c0c0") # Silver
		elif idx == 2:
			card_style.border_color = Color("cd7f32") # Bronze
		else:
			card_style.border_color = Color("37474f")
			
		card.add_theme_stylebox_override("panel", card_style)
		timeline_list.add_child(card)
		
		var card_margin = MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 12)
		card_margin.add_theme_constant_override("margin_right", 12)
		card_margin.add_theme_constant_override("margin_top", 12)
		card_margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(card_margin)
		
		var card_hbox = HBoxContainer.new()
		card_hbox.add_theme_constant_override("separation", 15)
		card_margin.add_child(card_hbox)
		
		# Avatar Circle
		var avatar = ColorRect.new()
		avatar.custom_minimum_size = Vector2(48, 48)
		avatar.color = p["avatar_color"]
		card_hbox.add_child(avatar)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 6)
		card_hbox.add_child(text_vbox)
		
		# Header (Name)
		var name_lbl = Label.new()
		name_lbl.text = p["name"]
		name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		text_vbox.add_child(name_lbl)
		
		# Body (Declared score text)
		var decl_lbl = Label.new()
		decl_lbl.text = "今日の勉強報告：" + str(p["declared_score"]) + " 点！"
		decl_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		decl_lbl.add_theme_font_size_override("font_size", 18)
		decl_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
		text_vbox.add_child(decl_lbl)
		
		# Post actions HBox
		var act_hbox = HBoxContainer.new()
		act_hbox.alignment = BoxContainer.ALIGNMENT_END
		act_hbox.add_theme_constant_override("separation", 10)
		text_vbox.add_child(act_hbox)
		
		# Detail Inspect Button
		var inspect_btn = Button.new()
		inspect_btn.text = "詳細確認"
		inspect_btn.add_theme_font_size_override("font_size", 14)
		inspect_btn.pressed.connect(_on_inspect_pressed.bind(p))
		act_hbox.add_child(inspect_btn)
		
		# Doubt Button (only visible for CPU rivals, not player itself)
		if p["id"] != "player":
			var doubt_btn = Button.new()
			doubt_btn.text = "ダウト!"
			doubt_btn.add_theme_font_size_override("font_size", 14)
			doubt_btn.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
			
			# Check if already doubted today
			if p["id"] in session.player_doubts_made_today:
				doubt_btn.text = "ダウト済"
				doubt_btn.disabled = true
				
			doubt_btn.pressed.connect(_on_doubt_pressed.bind(p["id"], card, doubt_btn))
			act_hbox.add_child(doubt_btn)

func update_remaining_votes() -> void:
	var max_doubts = 1 if Global.game_mode == "cram" else 3
	remaining_doubts_label.text = "残りダウト可能回数: " + str(local_doubts_count) + "回 (最大" + str(max_doubts) + "回)"

func _on_inspect_pressed(p: Dictionary) -> void:
	# Populate detail modal title
	detail_title.text = p["name"] + " の勉強時間割ログ"
	
	# Hide initial generic explanation text
	detail_body.visible = false
	
	# Clear old visual logs
	for child in detail_log_vbox.get_children():
		child.queue_free()
		
	# Populate visual logs hour-by-hour
	for h_idx in range(p["hours"].size()):
		var h = p["hours"][h_idx]
		
		# Row container
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 15)
		detail_log_vbox.add_child(row)
		
		# Hour badge
		var hour_lbl = Label.new()
		hour_lbl.text = " %d時限目 " % (h_idx + 1)
		hour_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		hour_lbl.add_theme_font_size_override("font_size", 16)
		hour_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		
		var hour_style = StyleBoxFlat.new()
		hour_style.bg_color = Color(DeskTheme.COLOR_MAHOGANY, 0.08)
		hour_style.border_color = Color(DeskTheme.COLOR_INK, 0.3)
		hour_style.border_width_left = 1
		hour_style.border_width_right = 1
		hour_style.border_width_top = 1
		hour_style.border_width_bottom = 1
		hour_style.corner_radius_top_left = 4
		hour_style.corner_radius_top_right = 4
		hour_style.corner_radius_bottom_left = 4
		hour_style.corner_radius_bottom_right = 4
		hour_style.content_margin_left = 6
		hour_lbl.add_theme_stylebox_override("normal", hour_style)
		row.add_child(hour_lbl)
		
		# Miniature cards drawing container
		var cards_hbox = HBoxContainer.new()
		cards_hbox.add_theme_constant_override("separation", 3)
		row.add_child(cards_hbox)
		
		# Render miniature cards representing draws
		for c_i in range(h["draws"]):
			var mini_card = PanelContainer.new()
			mini_card.custom_minimum_size = Vector2(16, 22)
			
			var m_style = StyleBoxFlat.new()
			m_style.bg_color = DeskTheme.COLOR_CRAFT
			m_style.border_color = DeskTheme.COLOR_INK
			m_style.border_width_left = 1
			m_style.border_width_right = 1
			m_style.border_width_top = 1
			m_style.border_width_bottom = 1
			m_style.corner_radius_top_left = 2
			m_style.corner_radius_top_right = 2
			m_style.corner_radius_bottom_left = 2
			m_style.corner_radius_bottom_right = 2
			mini_card.add_theme_stylebox_override("panel", m_style)
			cards_hbox.add_child(mini_card)
			
		# Text fallback for cards count
		var count_lbl = Label.new()
		count_lbl.text = "(%d枚ドロー)" % h["draws"]
		count_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		count_lbl.add_theme_font_size_override("font_size", 16)
		count_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
		row.add_child(count_lbl)
		
		# Used items badge container
		if h["used_items"].size() > 0:
			var items_hbox = HBoxContainer.new()
			items_hbox.add_theme_constant_override("separation", 8)
			row.add_child(items_hbox)
			
			for item_id in h["used_items"]:
				var item = CardData.ITEMS.get(item_id, {"name": "不明", "role": CardData.ROLE_PREP})
				
				# Role details
				var symbol = "⚙️"
				match item["role"]:
					CardData.ROLE_DEFENSE:
						symbol = "🛡️"
					CardData.ROLE_PUSH:
						symbol = "🔥"
					CardData.ROLE_BLUFF:
						symbol = "💬"
						
				# Badge Panel Container
				var badge = PanelContainer.new()
				var b_style = StyleBoxFlat.new()
				b_style.bg_color = Color.WHITE
				b_style.border_color = CardData.get_role_color(item["role"])
				b_style.border_width_left = 2
				b_style.border_width_right = 2
				b_style.border_width_top = 2
				b_style.border_width_bottom = 2
				b_style.corner_radius_top_left = 10
				b_style.corner_radius_top_right = 10
				b_style.corner_radius_bottom_left = 10
				b_style.corner_radius_bottom_right = 10
				b_style.content_margin_left = 8
				b_style.content_margin_right = 8
				b_style.content_margin_top = 2
				b_style.content_margin_bottom = 2
				badge.add_theme_stylebox_override("panel", b_style)
				items_hbox.add_child(badge)
				
				var badge_lbl = Label.new()
				badge_lbl.text = "%s %s" % [symbol, item["name"]]
				badge_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
				badge_lbl.add_theme_font_size_override("font_size", 14)
				badge_lbl.add_theme_color_override("font_color", CardData.get_role_color(item["role"]))
				badge.add_child(badge_lbl)
				
	# Shake modal container slightly to draw attention
	DeskTheme.shake_control(detail_modal, 4.0, 0.2)

func _on_doubt_pressed(target_id: String, card_node: Control, btn: Button) -> void:
	if local_doubts_count <= 0:
		return
		
	# Confirm doubt
	session.add_player_doubt(target_id)
	local_doubts_count -= 1
	update_remaining_votes()
	
	# Visual Juiciness: Stamp landing zoom, card shake, smartphone shake
	btn.text = "ダウト済"
	btn.disabled = true
	
	# Shake card
	DeskTheme.shake_control(card_node, 10.0, 0.4)
	# Shake phone
	DeskTheme.shake_control(phone_panel, 8.0, 0.35)

func _on_next_day_pressed() -> void:
	DeskTheme.animate_click(next_day_btn, Vector2.ONE, 0.08)
	
	var timer = get_tree().create_timer(0.25)
	timer.timeout.connect(func():
		if Global.is_tutorial_mode:
			show_tutorial_finish_modal()
		else:
			finish_phase({
				"doubts_made": session.player_doubts_made_today
			})
	)

func show_tutorial_finish_modal() -> void:
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(650, 400)
	modal.pivot_offset = Vector2(325, 200)
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_CRAFT
	style.border_color = DeskTheme.COLOR_GREEN
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 20
	style.shadow_offset = Vector2(5, 5)
	modal.add_theme_stylebox_override("panel", style)
	
	add_child(modal)
	modal.position = Vector2((1500 - 650) / 2.0, (850 - 400) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "チュートリアル完了！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	vbox.add_child(title)
	
	var body = Label.new()
	body.text = "お疲れ様でした！『テスト勉強チキンレース』の基本的な遊び方（自習、カバン整理、チキスタへの投稿、嘘とダウトの見極め）をマスターしました。\n\n本番の5日制マッチで、他のライバルたちを実力とブラフで圧倒し、第一志望合格（偏差値アップ）を勝ち取りましょう！"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(body)
	
	var btn = Button.new()
	btn.text = "タイトル画面に戻る"
	btn.custom_minimum_size = Vector2(240, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func():
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		Global.is_tutorial_mode = false
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func():
			Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
		)
	)
	vbox.add_child(btn)
	
	# Entry Animation
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
