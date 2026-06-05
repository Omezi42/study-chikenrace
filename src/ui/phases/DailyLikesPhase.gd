class_name DailyLikesPhase
extends PhaseBase

# UI Controls
var phone_panel: PanelContainer
var timeline_list: VBoxContainer
var next_day_btn: Button
var remaining_doubts_label: Label
var scroll_container: ScrollContainer
var target_scroll_y: float = 0.0
var scroll_tween: Tween

# Detail Inspection Modal
var detail_modal: PanelContainer
var detail_title: Label
var detail_body: Label
var detail_scroll: ScrollContainer
var detail_log_vbox: VBoxContainer
var detail_ellipsis: Label
var close_detail_btn: Button

# Daily state
var participants_data: Array = []
var local_doubts_count: int = 3 # 3 doubt votes per day max
var active_timeline_tweens: Array[Tween] = []
var likes_skip_btn: Button


func _on_setup(_setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(1500, 850)
	var max_doubts = 3
	local_doubts_count = max_doubts - session.player_doubts_made_today.size()
	
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if not bm.connection_lost.is_connected(_on_connection_lost):
			bm.connection_lost.connect(_on_connection_lost)
	
	# Layout setup: Left is Phone, Right is controls & inspection
	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 60)
	add_child(main_hbox)
	fit_control_to_viewport(main_hbox, Vector2(1500, 850), Vector2(72, 72), 0.72, true)
	
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
	status_bar.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
	status_bar.add_theme_color_override("font_color", Color.WHITE)
	phone_vbox.add_child(status_bar)
	
	var scroll = ScrollContainer.new()
	scroll_container = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.gui_input.connect(_on_scroll_input)
	phone_vbox.add_child(scroll)
	
	timeline_list = VBoxContainer.new()
	timeline_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_list.add_theme_constant_override("separation", 18)
	scroll.add_child(timeline_list)
	
	# RIGHT COLUMN: Inspection and Progress
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_LARGE)
	main_hbox.add_child(right_vbox)
	
	# remaining_doubts_label creation removed (Loop 20)
	
	# Detail Modal Wrapper (to isolate detail_modal from VBoxContainer positioning during shakes)
	var detail_wrapper = Control.new()
	detail_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_wrapper.custom_minimum_size = Vector2(0, 420) # Fixed size
	right_vbox.add_child(detail_wrapper)
	
	detail_modal = PanelContainer.new()
	detail_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	detail_wrapper.add_child(detail_modal)
	
	var detail_margin = MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_SMALL)
	detail_margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_SMALL)
	detail_margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_SMALL)
	detail_margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_SMALL)
	detail_modal.add_child(detail_margin)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 12)
	detail_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_margin.add_child(detail_vbox)
	
	detail_title = Label.new()
	detail_title.text = "ライバル詳細ログ"
	detail_title.add_theme_font_override("font", DeskTheme.get_font())
	detail_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
	detail_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_vbox.add_child(detail_title)
	
	detail_body = Label.new()
	detail_body.text = "タイムラインの「詳細確認」を押すと、ライバルが今日引いたドロー数と使用したアイテムのログがここに表示されます。"
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.add_theme_font_override("font", DeskTheme.get_font())
	detail_body.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	detail_body.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	detail_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_body.custom_minimum_size = Vector2(0, 200)
	detail_vbox.add_child(detail_body)
	
	# Scroll for logs
	detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.scroll_started.connect(_update_ellipsis_visibility)
	detail_scroll.scroll_ended.connect(_update_ellipsis_visibility)
	detail_scroll.get_v_scroll_bar().value_changed.connect(func(_val): _update_ellipsis_visibility())
	detail_vbox.add_child(detail_scroll)
	
	detail_log_vbox = VBoxContainer.new()
	detail_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_log_vbox.add_theme_constant_override("separation", 14)
	detail_scroll.add_child(detail_log_vbox)
	
	# Ellipsis indicating overflow
	detail_ellipsis = Label.new()
	detail_ellipsis.text = "…（下にスクロールできます）"
	detail_ellipsis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_ellipsis.add_theme_font_override("font", DeskTheme.get_font())
	detail_ellipsis.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
	detail_ellipsis.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	detail_ellipsis.visible = false
	detail_vbox.add_child(detail_ellipsis)
	
	# Skip Timeline Animation Button
	likes_skip_btn = Button.new()
	likes_skip_btn.text = "タイムライン演出スキップ >>"
	likes_skip_btn.custom_minimum_size = Vector2(360, 50)
	likes_skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	likes_skip_btn.add_theme_font_override("font", DeskTheme.get_font())
	likes_skip_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	DeskTheme.apply_white_button_style(likes_skip_btn)
	likes_skip_btn.pressed.connect(func():
		likes_skip_btn.visible = false
		for tw in active_timeline_tweens:
			if is_instance_valid(tw) and tw.is_running():
				tw.kill()
		active_timeline_tweens.clear()
		for card in timeline_list.get_children():
			if is_instance_valid(card):
				card.modulate.a = 1.0
				card.custom_minimum_size = Vector2(480, 185)
	)
	right_vbox.add_child(likes_skip_btn)
	
	# Next day button
	next_day_btn = Button.new()
	var is_last_day = false
	if Global.game_mode == Constants.MODE_OVERNIGHT:
		is_last_day = true
	else:
		is_last_day = session.current_day >= Constants.MAX_DAYS
		
	if is_last_day:
		next_day_btn.text = "結果発表へ進む"
	else:
		next_day_btn.text = "明日の勉強へ進む"
		
	next_day_btn.custom_minimum_size = Vector2(360, 65)
	next_day_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_day_btn.add_theme_font_override("font", DeskTheme.get_font())
	next_day_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	DeskTheme.apply_white_button_style(next_day_btn)
	next_day_btn.pressed.connect(_on_next_day_pressed)
	right_vbox.add_child(next_day_btn)

	
	# Fetch participants data
	collect_participants()
	populate_timeline()
	update_remaining_votes()
	
	# Entrance slide in on main_hbox instead of self
	DeskTheme.animate_entrance(main_hbox, main_hbox.position, Vector2(0, 300), 0.5)
	
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
		"avatar_color": DeskTheme.COLOR_GREEN,
		"emote": session.player_emote_today
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
			
		if actual_profile_id.begins_with("cpu_"):
			var cpu_meta = AIManager.get_cpu_info(actual_profile_id)
			if cpu_meta.get("type", "") == AIManager.TYPE_BLUFFER:
				color_val = DeskTheme.COLOR_TENSION
			elif cpu_meta.get("type", "") == AIManager.TYPE_CAUTIOUS:
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
			"avatar_color": color_val,
			"emote": opp.get("emote", "normal")
		})
		
	# Sort participants by declared score descending for timeline rank
	participants_data.sort_custom(func(a, b): return a["declared_score"] > b["declared_score"])

func populate_timeline() -> void:
	for child in timeline_list.get_children():
		child.queue_free()
		
	active_timeline_tweens.clear()
	if likes_skip_btn:
		likes_skip_btn.visible = participants_data.size() > 0
		
	for idx in range(participants_data.size()):
		var p = participants_data[idx]
		
		# Timeline Post Card
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(480, 185)
		card.pivot_offset = Vector2(240, 92)
		
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
		card.clip_contents = true
		
		# Set initial state for animate-in (Loop 19)
		card.modulate.a = 0.0
		var target_height = 185.0
		card.custom_minimum_size = Vector2(480, 0)
		
		timeline_list.add_child(card)
		
		var tween = card.create_tween().set_parallel(true)
		active_timeline_tweens.append(tween)
		var delay = idx * 0.12
		
		tween.tween_property(card, "custom_minimum_size:y", target_height, 0.35)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)
			
		tween.tween_property(card, "modulate:a", 1.0, 0.28)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)
			
		if idx == participants_data.size() - 1:
			tween.chain().tween_callback(func():
				if is_instance_valid(likes_skip_btn):
					likes_skip_btn.visible = false
			)

		
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
		
		# Header (Name & Reaction if CPU)
		var header_hbox = HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		text_vbox.add_child(header_hbox)
		
		var name_lbl = Label.new()
		name_lbl.text = p["name"]
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		header_hbox.add_child(name_lbl)
		
		# 表情バッジの追加
		var emote_key = p.get("emote", "normal")
		var emote_badge = Label.new()
		
		var badge_style = StyleBoxFlat.new()
		badge_style.content_margin_left = 6
		badge_style.content_margin_right = 6
		badge_style.content_margin_top = 2
		badge_style.content_margin_bottom = 2
		badge_style.corner_radius_top_left = 4
		badge_style.corner_radius_top_right = 4
		badge_style.corner_radius_bottom_left = 4
		badge_style.corner_radius_bottom_right = 4
		
		match emote_key:
			"normal":
				emote_badge.text = "[普通]"
				badge_style.bg_color = Color("eceff1")
				emote_badge.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			"confident":
				emote_badge.text = "[自信あり]"
				badge_style.bg_color = Color("e8f5e9")
				emote_badge.add_theme_color_override("font_color", Color("2e7d32"))
			"anxious":
				emote_badge.text = "[不安]"
				badge_style.bg_color = Color("ffebee")
				emote_badge.add_theme_color_override("font_color", Color("c62828"))
				
		emote_badge.add_theme_stylebox_override("normal", badge_style)
		emote_badge.add_theme_font_override("font", DeskTheme.get_font())
		emote_badge.add_theme_font_size_override("font_size", 13)
		header_hbox.add_child(emote_badge)
		
		# 履歴バッジ（累積ドロー数とバースト有無）は詳細ログがあるためタイムラインからは削除

		
		# Headerにトグルボタンを追加
		var toggle_btn = Button.new()
		toggle_btn.text = " ▲ "
		toggle_btn.flat = true
		toggle_btn.add_theme_font_override("font", DeskTheme.get_font())
		toggle_btn.add_theme_font_size_override("font_size", 14)
		header_hbox.add_child(toggle_btn)
		
		var collapsible_container = VBoxContainer.new()
		collapsible_container.add_theme_constant_override("separation", 6)
		text_vbox.add_child(collapsible_container)
		
		# Body (Declared score text)
		var decl_lbl = Label.new()
		decl_lbl.text = "今日の勉強報告：" + str(p["declared_score"]) + " 点！"
		decl_lbl.add_theme_font_override("font", DeskTheme.get_font())
		decl_lbl.add_theme_font_size_override("font_size", 18)
		decl_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
		collapsible_container.add_child(decl_lbl)
		
		# Post actions HBox
		var act_hbox = HBoxContainer.new()
		act_hbox.alignment = BoxContainer.ALIGNMENT_END
		act_hbox.add_theme_constant_override("separation", 10)
		collapsible_container.add_child(act_hbox)
		
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
			
		toggle_btn.pressed.connect(func():
			collapsible_container.visible = not collapsible_container.visible
			if collapsible_container.visible:
				toggle_btn.text = " ▲ "
				card.custom_minimum_size.y = 185
			else:
				toggle_btn.text = " ▼ "
				card.custom_minimum_size.y = 75
		)

func update_remaining_votes() -> void:
	pass

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
		hour_lbl.add_theme_font_override("font", DeskTheme.get_font())
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
		var count_text = "(%d枚ドロー)" % h["draws"]
		var text_color = Color(DeskTheme.COLOR_INK, 0.6)
		
		if p["id"] == "player":
			if h.get("bursted", false):
				count_text += " [寝落ち (0点)]"
				text_color = DeskTheme.COLOR_TENSION
			else:
				count_text += " [実点: %d点]" % h.get("score", 0)
				text_color = DeskTheme.COLOR_GREEN
		else:
			# Hide rival burst status to preserve bluffing gameplay (Loop 20)
			text_color = DeskTheme.COLOR_INK
				
		count_lbl.text = count_text
		count_lbl.add_theme_font_override("font", DeskTheme.get_font())
		count_lbl.add_theme_font_size_override("font_size", 16)
		count_lbl.add_theme_color_override("font_color", text_color)
		row.add_child(count_lbl)
		
		# Used items badge container
		if h["used_items"].size() > 0:
			var items_hbox = HBoxContainer.new()
			items_hbox.add_theme_constant_override("separation", 8)
			row.add_child(items_hbox)
			
			for item_id in h["used_items"]:
				var item = CardData.ITEMS.get(item_id, {"name": "不明", "role": CardData.ROLE_PREP})
				
				# Render items as simple illustration icons (Loop 20)
				var img_path = CardData.get_item_image_path(item_id)
				var tex_rect = TextureRect.new()
				tex_rect.custom_minimum_size = Vector2(32, 32)
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				
				if img_path != "" and ResourceLoader.exists(img_path):
					tex_rect.texture = load(img_path)
					
				var role_name = CardData.get_role_name(item["role"])
				tex_rect.tooltip_text = "【%s】(%s)\n%s" % [item["name"], role_name, item.get("description", "")]
				
				var badge = PanelContainer.new()
				var b_style = StyleBoxFlat.new()
				b_style.bg_color = Color.WHITE
				b_style.border_color = CardData.get_role_color(item["role"])
				b_style.border_width_left = 1.5
				b_style.border_width_right = 1.5
				b_style.border_width_top = 1.5
				b_style.border_width_bottom = 1.5
				b_style.corner_radius_top_left = 6
				b_style.corner_radius_top_right = 6
				b_style.corner_radius_bottom_left = 6
				b_style.corner_radius_bottom_right = 6
				b_style.content_margin_left = 2
				b_style.content_margin_right = 2
				b_style.content_margin_top = 2
				b_style.content_margin_bottom = 2
				badge.add_theme_stylebox_override("panel", b_style)
				
				badge.add_child(tex_rect)
				items_hbox.add_child(badge)
				
	# Shake modal container slightly to draw attention
	DeskTheme.shake_control(detail_modal, 4.0, 0.2)
	
	# Update ellipsis visibility after layout pass
	await get_tree().process_frame
	_update_ellipsis_visibility()

func _update_ellipsis_visibility() -> void:
	if not is_instance_valid(detail_scroll) or not is_instance_valid(detail_ellipsis):
		return
	var v_scroll = detail_scroll.get_v_scroll_bar()
	if v_scroll and v_scroll.visible:
		# Check if we can scroll down further
		var max_scroll = v_scroll.max_value - v_scroll.page
		if v_scroll.value < max_scroll - 2: # small tolerance
			detail_ellipsis.visible = true
			return
	detail_ellipsis.visible = false

func _get_target_deck(p_id: String) -> Dictionary:
	if Global.opponent_profiles.has(p_id):
		var opp_id = Global.opponent_profiles[p_id].get("id", p_id)
		if AIManager.CPU_OPPONENTS.has(opp_id):
			return AIManager.CPU_OPPONENTS[opp_id].get("deck", {})
	if AIManager.CPU_OPPONENTS.has(p_id):
		return AIManager.CPU_OPPONENTS[p_id].get("deck", {})
	return {}

func _on_doubt_pressed(target_id: String, card_node: Control, btn: Button) -> void:
	if local_doubts_count <= 0:
		return
		
	# Confirm doubt
	session.add_player_doubt(target_id)
	local_doubts_count -= 1
	update_remaining_votes()
	
	# Instant doubt outcome validation
	var is_bluff = false
	var opp_name = "ライバル"
	var declared_score = 0
	var actual_score = 0
	
	var day_data = session.match_history.get(session.current_day, {})
	if day_data.has(target_id):
		var opp = day_data[target_id]
		opp_name = opp.get("name", opp.get("username", "ライバル"))
		declared_score = int(opp.get("declared_score", 0))
		actual_score = int(opp.get("actual_score", 0))
		is_bluff = declared_score != actual_score
		
	# 得失点および内訳の算出
	var my_score_change = 0
	var opp_score_change = 0
	var my_details = ""
	var opp_details = ""
	
	if is_bluff:
		# 成功時：自分にボーナス、相手に減点
		var bluff = declared_score - actual_score
		var adjusted_bluff = int(round(bluff * 0.75))
		var chat_bonus = 6 if "item_study_chat" in Global.current_deck.values() else 0
		my_score_change = adjusted_bluff + 6 + chat_bonus
		
		my_details = "・基本ボーナス: +%d 点\n・嘘暴きボーナス: +%d 点 (差分の75%%)" % [6 + chat_bonus, adjusted_bluff]
		
		var opp_deck = _get_target_deck(target_id)
		var opp_has_copy = "item_copy_answer" in opp_deck.values()
		var penalty = declared_score - actual_score
		
		if opp_has_copy:
			var extra_penalty = int(penalty * 0.3)
			opp_score_change = -(penalty + extra_penalty)
			opp_details = "・嘘つきペナルティ: -%d 点\n・カンニングのデメリット: -%d 点\n(ペナルティが30%%増加)" % [penalty, extra_penalty]
		else:
			opp_score_change = -penalty
			opp_details = "・嘘つきペナルティ: -%d 点" % penalty
			
		btn.text = "ダウト成功！"
		btn.add_theme_color_override("font_disabled_color", DeskTheme.COLOR_GREEN)
		Global.total_doubt_successes += 1
	else:
		# 失敗時：自分に減点、相手はノーダメージ
		var base_fail_penalty = 10 + (session.current_day - 1) * 2
		var cushion_active = "item_cushion" in Global.current_deck.values()
		var earplug_reduction = 10 if "item_earplugs" in Global.current_deck.values() else 0
		
		var penalty = base_fail_penalty
		my_details = "・お手つきペナルティ: -%d 点" % base_fail_penalty
		if cushion_active:
			penalty = int(round(penalty * 0.5))
			my_details += "\n・クッション効果: ペナルティ半減"
		if earplug_reduction > 0:
			penalty = max(penalty - earplug_reduction, 0)
			my_details += "\n・耳栓効果: ペナルティ軽減 -10 点"
			
		my_score_change = -penalty
		opp_score_change = 0
		opp_details = "・正直に勉強していました。\n・ペナルティはありません。"
		
		btn.text = "ダウト失敗..."
		btn.add_theme_color_override("font_disabled_color", DeskTheme.COLOR_TENSION)
		Global.total_doubt_failures += 1
		
	Global.save_game()
	btn.disabled = true
	
	# Shake card & phone
	DeskTheme.shake_control(card_node, 10.0, 0.4)
	DeskTheme.shake_control(phone_panel, 8.0, 0.35)
	
	# リッチな結果表示モーダルの呼び出し
	show_doubt_result_modal(
		opp_name, 
		is_bluff, 
		declared_score, 
		actual_score, 
		my_score_change, 
		opp_score_change, 
		my_details, 
		opp_details
	)

func show_doubt_result_modal(
	opp_name: String, 
	is_bluff: bool, 
	declared_score: int, 
	actual_score: int, 
	my_score_change: int, 
	opp_score_change: int,
	my_details: String,
	opp_details: String
) -> void:
	var scene_tree = get_tree()
	if not scene_tree or not scene_tree.root:
		return
		
	# CanvasLayer (最前面に表示)
	var canvas = CanvasLayer.new()
	canvas.layer = 160
	scene_tree.root.add_child(canvas)
	
	# 暗い背景 overlay
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6) # 半透明の黒
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	
	# メインのダイアログパネル
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(750, 500)
	modal.pivot_offset = Vector2(375, 250)
	
	var base_style = DeskTheme.create_craft_panel()
	# 成功時と失敗時でボーダー（枠）の色を変える
	if is_bluff:
		base_style.border_color = DeskTheme.COLOR_GREEN # 緑のボーダー
	else:
		base_style.border_color = DeskTheme.COLOR_TENSION # 赤のボーダー
	base_style.border_width_left = 6
	base_style.border_width_right = 6
	base_style.border_width_top = 6
	base_style.border_width_bottom = 6
	modal.add_theme_stylebox_override("panel", base_style)
	canvas.add_child(modal)
	
	# 画面中央に配置
	var viewport_size = scene_tree.root.get_viewport().get_visible_rect().size
	var screen_w = viewport_size.x if viewport_size.x > 0 else 1920
	var screen_h = viewport_size.y if viewport_size.y > 0 else 1080
	modal.position = Vector2((screen_w - 750) / 2.0, (screen_h - 500) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# --- ヘッダー（タイトル） ---
	var title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 36)
	
	if is_bluff:
		title_lbl.text = "ダウト成功！"
		title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	else:
		title_lbl.text = "ダウト失敗..."
		title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	vbox.add_child(title_lbl)
	
	# --- 説明文 ---
	var desc_lbl = Label.new()
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
	desc_lbl.add_theme_font_size_override("font_size", 18)
	desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	
	if is_bluff:
		desc_lbl.text = "%s は勉強報告で嘘をついていた！\n【申告】 %d 点  ➡  【実際】 %d 点" % [opp_name, declared_score, actual_score]
	else:
		desc_lbl.text = "%s は正直に勉強していた！\n【申告】 %d 点  ➡  【実際】 %d 点" % [opp_name, declared_score, actual_score]
	vbox.add_child(desc_lbl)
	
	# --- 影響カードエリア（横並び HBox） ---
	var cards_hbox = HBoxContainer.new()
	cards_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(cards_hbox)
	
	# 1. あなたのカード
	var my_card = PanelContainer.new()
	my_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var my_style = StyleBoxFlat.new()
	if is_bluff:
		my_style.bg_color = Color("e8f5e9") # 薄い緑
		my_style.border_color = Color("81c784")
	else:
		my_style.bg_color = Color("ffebee") # 薄い赤
		my_style.border_color = Color("e57373")
	my_style.border_width_left = 2
	my_style.border_width_right = 2
	my_style.border_width_top = 2
	my_style.border_width_bottom = 2
	my_style.corner_radius_top_left = 8
	my_style.corner_radius_top_right = 8
	my_style.corner_radius_bottom_left = 8
	my_style.corner_radius_bottom_right = 8
	my_card.add_theme_stylebox_override("panel", my_style)
	cards_hbox.add_child(my_card)
	
	var my_margin = MarginContainer.new()
	my_margin.add_theme_constant_override("margin_left", 15)
	my_margin.add_theme_constant_override("margin_right", 15)
	my_margin.add_theme_constant_override("margin_top", 15)
	my_margin.add_theme_constant_override("margin_bottom", 15)
	my_card.add_child(my_margin)
	
	var my_vbox = VBoxContainer.new()
	my_vbox.add_theme_constant_override("separation", 8)
	my_margin.add_child(my_vbox)
	
	var my_title = Label.new()
	my_title.text = "あなたへの影響"
	my_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_title.add_theme_font_override("font", DeskTheme.get_font())
	my_title.add_theme_font_size_override("font_size", 16)
	my_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	my_vbox.add_child(my_title)
	
	var my_diff_lbl = Label.new()
	my_diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_diff_lbl.add_theme_font_override("font", DeskTheme.get_font())
	my_diff_lbl.add_theme_font_size_override("font_size", 32)
	
	if my_score_change >= 0:
		my_diff_lbl.text = "+%d 点" % my_score_change
		my_diff_lbl.add_theme_color_override("font_color", Color("2e7d32")) # 濃い緑
	else:
		my_diff_lbl.text = "%d 点" % my_score_change
		my_diff_lbl.add_theme_color_override("font_color", Color("c62828")) # 濃い赤
	my_vbox.add_child(my_diff_lbl)
	
	var my_detail_lbl = Label.new()
	my_detail_lbl.text = my_details
	my_detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	my_detail_lbl.add_theme_font_override("font", DeskTheme.get_font())
	my_detail_lbl.add_theme_font_size_override("font_size", 13)
	my_detail_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	my_vbox.add_child(my_detail_lbl)
	
	# 2. 相手のカード
	var opp_card = PanelContainer.new()
	opp_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opp_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var opp_style = StyleBoxFlat.new()
	if is_bluff:
		opp_style.bg_color = Color("ffebee") # 薄い赤 (ダメージ)
		opp_style.border_color = Color("e57373")
	else:
		opp_style.bg_color = Color("eceff1") # グレー (影響なし)
		opp_style.border_color = Color("b0bec5")
	opp_style.border_width_left = 2
	opp_style.border_width_right = 2
	opp_style.border_width_top = 2
	opp_style.border_width_bottom = 2
	opp_style.corner_radius_top_left = 8
	opp_style.corner_radius_top_right = 8
	opp_style.corner_radius_bottom_left = 8
	opp_style.corner_radius_bottom_right = 8
	opp_card.add_theme_stylebox_override("panel", opp_style)
	cards_hbox.add_child(opp_card)
	
	var opp_margin = MarginContainer.new()
	opp_margin.add_theme_constant_override("margin_left", 15)
	opp_margin.add_theme_constant_override("margin_right", 15)
	opp_margin.add_theme_constant_override("margin_top", 15)
	opp_margin.add_theme_constant_override("margin_bottom", 15)
	opp_card.add_child(opp_margin)
	
	var opp_vbox = VBoxContainer.new()
	opp_vbox.add_theme_constant_override("separation", 8)
	opp_margin.add_child(opp_vbox)
	
	var opp_title = Label.new()
	opp_title.text = opp_name + " への影響"
	opp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_title.add_theme_font_override("font", DeskTheme.get_font())
	opp_title.add_theme_font_size_override("font_size", 16)
	opp_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	opp_vbox.add_child(opp_title)
	
	var opp_diff_lbl = Label.new()
	opp_diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_diff_lbl.add_theme_font_override("font", DeskTheme.get_font())
	opp_diff_lbl.add_theme_font_size_override("font_size", 32)
	
	if opp_score_change < 0:
		opp_diff_lbl.text = "%d 点" % opp_score_change
		opp_diff_lbl.add_theme_color_override("font_color", Color("c62828")) # 濃い赤
	else:
		opp_diff_lbl.text = "±0 点"
		opp_diff_lbl.add_theme_color_override("font_color", Color("455a64")) # グレー
	opp_vbox.add_child(opp_diff_lbl)
	
	var opp_detail_lbl = Label.new()
	opp_detail_lbl.text = opp_details
	opp_detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opp_detail_lbl.add_theme_font_override("font", DeskTheme.get_font())
	opp_detail_lbl.add_theme_font_size_override("font_size", 13)
	opp_detail_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	opp_vbox.add_child(opp_detail_lbl)
	
	# --- 確認ボタン（閉じる） ---
	var close_btn = Button.new()
	close_btn.text = "タイムラインに戻る"
	close_btn.custom_minimum_size = Vector2(250, 50)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 18)
	DeskTheme.apply_white_button_style(close_btn)
	vbox.add_child(close_btn)
	
	close_btn.pressed.connect(func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var t = scene_tree.create_timer(0.12)
		t.timeout.connect(func():
			# 閉じるアニメーション（ふわっと消える）
			var fade_tween = scene_tree.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fade_tween.tween_property(modal, "scale", Vector2(0.8, 0.8), 0.2)
			fade_tween.tween_property(modal, "modulate:a", 0.0, 0.2)
			fade_tween.tween_property(bg, "color:a", 0.0, 0.2)
			fade_tween.chain().tween_callback(func():
				canvas.queue_free()
			)
		)
	)
	
	# 効果音の再生
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		if is_bluff:
			audio.play_se(AudioManager.SE_COMBO)
		else:
			audio.play_se(AudioManager.SE_BURST)
			
	# 入場アニメーション
	modal.scale = Vector2.ZERO
	var tween = scene_tree.create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.35)

func _on_next_day_pressed() -> void:
	next_day_btn.disabled = true
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
	modal.size = Vector2(650, 400)
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
	var viewport_size = get_viewport_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
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
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	vbox.add_child(title)
	
	var body = Label.new()
	body.text = "お疲れ様でした！『テスト勉強チキンレース』の基本的な遊び方（自習、持ち込みアイテム設定、チキスタへの投稿、嘘とダウトの見極め）をマスターしました。\n\n本番の5日制マッチで、他のライバルたちを実力とブラフで圧倒し、第一志望合格（偏差値アップ）を勝ち取りましょう！"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", DeskTheme.get_font())
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(body)
	
	var btn = Button.new()
	btn.text = "タイトル画面に戻る"
	btn.custom_minimum_size = Vector2(240, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", DeskTheme.get_font())
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


func _on_connection_lost() -> void:
	if not is_inside_tree():
		return
	next_day_btn.disabled = true
	ConnectionErrorModal.create_and_show(self)

func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_scroll_y = max(target_scroll_y - 80, 0)
			_animate_scroll()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var max_scroll = max(0, timeline_list.size.y - scroll_container.size.y)
			target_scroll_y = min(target_scroll_y + 80, max_scroll)
			_animate_scroll()
			accept_event()

func _animate_scroll() -> void:
	if not is_instance_valid(scroll_container) or not is_inside_tree():
		return
	if is_instance_valid(scroll_tween):
		scroll_tween.kill()
	scroll_tween = create_tween()
	scroll_tween.tween_property(scroll_container, "scroll_vertical", int(target_scroll_y), 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)


