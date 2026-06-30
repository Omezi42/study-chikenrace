class_name ModeSelectionModal
extends RefCounted

static func create_and_show(parent: Node, on_friend_match_pressed: Callable, national_names_pool: Array) -> PanelContainer:
	var vp_size = parent.get_viewport_rect().size
	var is_portrait = vp_size.y > vp_size.x
	var fit_s = clamp(min(vp_size.x / 540.0, vp_size.y / 960.0), 0.8, 3.0)
	var width = min(480.0, (vp_size.x * 0.95) / fit_s)
	var height = min(720.0, (max(vp_size.y, 600.0) * 0.9) / fit_s)
	var mode_modal = PanelContainer.new()
	mode_modal.custom_minimum_size = Vector2(width, height)
	mode_modal.pivot_offset = Vector2(width / 2.0, height / 2.0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_CRAFT
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 15
	style.shadow_offset = Vector2(6, 6)
	mode_modal.add_theme_stylebox_override("panel", style)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	center.add_child(mode_modal)
	mode_modal.resized.connect(func(): mode_modal.pivot_offset = mode_modal.size * 0.5)
	mode_modal.tree_exiting.connect(func(): if is_instance_valid(center): center.queue_free())
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mode_modal.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = Localization.get_text("MODE_SELECTION_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(28))
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_vbox)
	
	# -- 模試 (National Mode) --
	var national_btn = Button.new()
	national_btn.custom_minimum_size = Vector2(min(440.0, width - 40.0), 100)
	Global.apply_white_button_style(national_btn)
	
	var nat_inner = VBoxContainer.new()
	nat_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	nat_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nat_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	national_btn.add_child(nat_inner)
	
	var nat_title = Label.new()
	nat_title.text = Localization.get_text("MODE_NATIONAL_TITLE")
	nat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nat_title.add_theme_font_override("font", DeskTheme.get_font())
	nat_title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(22))
	nat_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	nat_inner.add_child(nat_title)
	
	var nat_desc = Label.new()
	nat_desc.text = Localization.get_text("MODE_NATIONAL_DESC")
	nat_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nat_desc.add_theme_font_override("font", DeskTheme.get_font())
	nat_desc.add_theme_font_size_override("font_size", DeskTheme.scaled_font(14))
	nat_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	nat_inner.add_child(nat_desc)
	
	btn_vbox.add_child(national_btn)
	
	# -- フレンド戦 (Friend Mode) --
	var friend_btn = Button.new()
	friend_btn.custom_minimum_size = Vector2(min(440.0, width - 40.0), 100)
	Global.apply_white_button_style(friend_btn)
	
	var friend_inner = VBoxContainer.new()
	friend_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	friend_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	friend_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	friend_btn.add_child(friend_inner)
	
	var friend_title_lbl = Label.new()
	friend_title_lbl.text = Localization.get_text("MODE_FRIEND_TITLE")
	friend_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friend_title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	friend_title_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(22))
	friend_title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	friend_inner.add_child(friend_title_lbl)
	
	var friend_desc = Label.new()
	friend_desc.text = Localization.get_text("MODE_FRIEND_DESC")
	friend_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friend_desc.add_theme_font_override("font", DeskTheme.get_font())
	friend_desc.add_theme_font_size_override("font_size", DeskTheme.scaled_font(14))
	friend_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	friend_inner.add_child(friend_desc)
	
	btn_vbox.add_child(friend_btn)
	
	# -- ランダムマッチ (Random Match Mode) --
	var random_btn = Button.new()
	random_btn.custom_minimum_size = Vector2(min(440.0, width - 40.0), 100)
	Global.apply_white_button_style(random_btn)
	
	var random_inner = VBoxContainer.new()
	random_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	random_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	random_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	random_btn.add_child(random_inner)
	
	var random_title_lbl = Label.new()
	random_title_lbl.text = Localization.get_text("MODE_RANDOM_TITLE")
	random_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	random_title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	random_title_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(22))
	random_title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	random_inner.add_child(random_title_lbl)
	
	var random_desc = Label.new()
	random_desc.text = Localization.get_text("MODE_RANDOM_DESC")
	random_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	random_desc.add_theme_font_override("font", DeskTheme.get_font())
	random_desc.add_theme_font_size_override("font_size", DeskTheme.scaled_font(14))
	random_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	random_inner.add_child(random_desc)
	
	var online_status = Label.new()
	online_status.text = "（リアルタイム状況を確認中...）"
	online_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_status.add_theme_font_override("font", DeskTheme.get_font())
	online_status.add_theme_font_size_override("font_size", DeskTheme.scaled_font(13))
	online_status.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	random_inner.add_child(online_status)
	
	_fetch_server_status(parent, func(online: int, waiting: int):
		if is_instance_valid(online_status):
			online_status.text = "（現在オンライン: %d人 / マッチング待機中: %d人）" % [online, waiting]
	)
	
	btn_vbox.add_child(random_btn)
	
	# Cancel Button
	var cancel_btn = Button.new()
	cancel_btn.text = Localization.get_text("CANCEL_BUTTON")
	cancel_btn.custom_minimum_size = Vector2(160, 45)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.add_theme_font_override("font", DeskTheme.get_font())
	cancel_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	Global.apply_white_button_style(cancel_btn)
	vbox.add_child(cancel_btn)
	
	# -- Connect: 模試 --
	national_btn.pressed.connect(func():
		DeskTheme.animate_click(national_btn, Vector2.ONE, 0.08)
		Global.game_mode = Constants.MODE_NATIONAL
		show_difficulty_selection(parent, mode_modal, on_friend_match_pressed, national_names_pool)
	)
	
	# -- Connect: フレンド戦 --
	friend_btn.pressed.connect(func():
		DeskTheme.animate_click(friend_btn, Vector2.ONE, 0.08)
		mode_modal.queue_free()
		if on_friend_match_pressed.is_valid():
			on_friend_match_pressed.call()
	)
	
	random_btn.pressed.connect(func():
		DeskTheme.animate_click(random_btn, Vector2.ONE, 0.08)
		if not parent.has_node("/root/WebRTCManager"):
			return
		var wrm = parent.get_node("/root/WebRTCManager")
		Global.game_mode = Constants.MODE_RANDOM
		_show_matching_lobby(parent, mode_modal, wrm, national_names_pool, on_friend_match_pressed)
	)
	
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		if parent.get_tree() != null:
			var tween = parent.get_tree().create_tween().bind_node(mode_modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(mode_modal, "scale", Vector2.ZERO, 0.2)
			tween.chain().tween_callback(func():
				mode_modal.queue_free()
			)
	)
	
	# Entrance animation
	mode_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(mode_modal).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(mode_modal, "scale", Vector2.ONE * fit_s, 0.3)
		
	return mode_modal

static func show_difficulty_selection(parent: Node, mode_modal: PanelContainer, on_friend_match_pressed: Callable, national_names_pool: Array) -> void:
	var parent_tree = parent
	if mode_modal != null and is_instance_valid(mode_modal):
		mode_modal.queue_free()
	
	var vp_size = parent.get_viewport_rect().size
	var is_portrait = vp_size.y > vp_size.x
	var fit_s = clamp(min(vp_size.x / 540.0, vp_size.y / 960.0), 0.8, 3.0)
	var width = min(480.0, (vp_size.x * 0.95) / fit_s)
	var height = min(680.0, (max(vp_size.y, 600.0) * 0.9) / fit_s)
	var diff_modal = PanelContainer.new()
	diff_modal.custom_minimum_size = Vector2(width, height)
	diff_modal.pivot_offset = Vector2(width / 2.0, height / 2.0)
	diff_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	center.add_child(diff_modal)
	diff_modal.resized.connect(func(): diff_modal.pivot_offset = diff_modal.size * 0.5)
	diff_modal.tree_exiting.connect(func(): if is_instance_valid(center): center.queue_free())
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	diff_modal.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "模試のクラス選択"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(28))
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var my_dev_lbl = Label.new()
	my_dev_lbl.text = "現在のあなたの偏差値: %.1f" % Global.deviation_value
	my_dev_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_dev_lbl.add_theme_font_override("font", DeskTheme.get_font())
	my_dev_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
	my_dev_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	vbox.add_child(my_dev_lbl)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_vbox)
	
	# クラスの定義
	var classes = [
		{"id": "remedial", "name": "補習室", "desc": "ダウト警戒度が非常に低い初心者クラス。基本を学ぶのに最適。", "req": 0.0},
		{"id": "regular", "name": "一般クラス", "desc": "通常の強さのCPUと対戦する標準クラス。推奨偏差値：50以上", "req": 50.0},
		{"id": "advanced", "name": "特進クラス", "desc": "CPUが期待値計算で的確にダウトを撃つ高難易度クラス。推奨偏差値：60以上", "req": 60.0}
	]
	
	for cls in classes:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(min(440.0, width - 40.0), 90)
		Global.apply_white_button_style(btn)
		
		var unlocked = Global.deviation_value >= cls["req"]
		
		var inner = VBoxContainer.new()
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(inner)
		
		var btn_title = Label.new()
		if unlocked:
			btn_title.text = cls["name"]
		else:
			btn_title.text = "[未開放] " + cls["name"] + " (必要偏差値: %.1f)" % cls["req"]
		btn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_title.add_theme_font_override("font", DeskTheme.get_font())
		btn_title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(20))
		btn_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK if unlocked else Color(DeskTheme.COLOR_INK, 0.4))
		inner.add_child(btn_title)
		
		var btn_desc = Label.new()
		btn_desc.text = cls["desc"]
		btn_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_desc.add_theme_font_override("font", DeskTheme.get_font())
		btn_desc.add_theme_font_size_override("font_size", DeskTheme.scaled_font(12))
		btn_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5) if unlocked else Color(DeskTheme.COLOR_INK, 0.3))
		inner.add_child(btn_desc)
		
		btn_vbox.add_child(btn)
		
		if not unlocked:
			btn.disabled = true
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			btn.pressed.connect(func():
				DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
				Global.selected_class = cls["id"]
				
				# 対戦相手の偏差値をクラスに合わせて調整
				var dev_min = 35.0
				var dev_max = 50.0
				if cls["id"] == "regular":
					dev_min = 48.0
					dev_max = 58.0
				elif cls["id"] == "advanced":
					dev_min = 58.0
					dev_max = 80.0
				
				var pool = national_names_pool.duplicate()
				pool.shuffle()
				var cpu_pool_keys = AIManager.CPU_OPPONENTS.keys().duplicate()
				cpu_pool_keys.shuffle()
				
				Global.opponent_profiles = {
					"cpu_sato": {
						"id": cpu_pool_keys[0],
						"name": pool[0]
					},
					"cpu_suzuki": {
						"id": cpu_pool_keys[1],
						"name": pool[1]
					},
					"cpu_takahashi": {
						"id": cpu_pool_keys[2],
						"name": pool[2]
					}
				}
				Global.save_game()
				
				var start_game = func():
					diff_modal.queue_free()
					if Global.player_name == "":
						Global.change_scene_with_fade(parent.get_tree(), "res://Profile.tscn")
					else:
						Global.change_scene_with_fade(parent.get_tree(), "res://Main.tscn")

				var timer = parent.get_tree().create_timer(0.2)
				timer.timeout.connect(func():
					start_game.call()
				)
			)
			
	# Back Button
	var back_btn = Button.new()
	back_btn.text = "戻る"
	back_btn.custom_minimum_size = Vector2(160, 45)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_override("font", DeskTheme.get_font())
	back_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	Global.apply_white_button_style(back_btn)
	vbox.add_child(back_btn)
	
	back_btn.pressed.connect(func():
		DeskTheme.animate_click(back_btn, Vector2.ONE, 0.08)
		diff_modal.queue_free()
		if mode_modal != null and is_instance_valid(mode_modal):
			ModeSelectionModal.create_and_show(parent, on_friend_match_pressed, national_names_pool)
	)
	
	# Entrance animation
	diff_modal.scale = Vector2.ZERO
	if parent.get_tree() != null:
		var tween = parent.get_tree().create_tween().bind_node(diff_modal).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(diff_modal, "scale", Vector2.ONE * fit_s, 0.3)



static func _show_matching_lobby(parent: Node, mode_modal: PanelContainer, bm: Node, national_names_pool: Array, on_friend_match_pressed: Callable) -> void:
	var from_mode_selection = (mode_modal != null and is_instance_valid(mode_modal))
	if from_mode_selection:
		mode_modal.queue_free()
	
	var vp_size = parent.get_viewport_rect().size
	var is_portrait = vp_size.y > vp_size.x
	var fit_s = clamp(min(vp_size.x / 540.0, vp_size.y / 960.0), 0.8, 3.0)
	var width = min(480.0, (vp_size.x * 0.95) / fit_s)
	var height = min(460.0, (max(vp_size.y, 600.0) * 0.9) / fit_s)
	var lobby = PanelContainer.new()
	lobby.custom_minimum_size = Vector2(width, height)
	lobby.pivot_offset = Vector2(width / 2.0, height / 2.0)
	lobby.scale = Vector2.ONE * fit_s
	lobby.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	center.add_child(lobby)
	lobby.resized.connect(func(): lobby.pivot_offset = lobby.size * 0.5)
	lobby.tree_exiting.connect(func(): if is_instance_valid(center): center.queue_free())
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lobby.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "全国ランダムマッチ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(28))
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var status_lbl = Label.new()
	status_lbl.text = "マッチングサーバーに接続中..."
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_override("font", DeskTheme.get_font())
	status_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	status_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	vbox.add_child(status_lbl)
	
	var online_lbl = Label.new()
	online_lbl.text = "オンライン接続状況を確認中..."
	online_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_lbl.add_theme_font_override("font", DeskTheme.get_font())
	online_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(14))
	online_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	vbox.add_child(online_lbl)
	
	_fetch_server_status(parent, func(online: int, waiting: int):
		if is_instance_valid(online_lbl):
			online_lbl.text = "現在オンラインユーザー数: %d人 (待機中: %d人)" % [online, waiting]
	)
	

	
	var members_vbox = VBoxContainer.new()
	members_vbox.add_theme_constant_override("separation", 8)
	members_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(members_vbox)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "マッチングをキャンセル"
	cancel_btn.custom_minimum_size = Vector2(240, 50)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.add_theme_font_override("font", DeskTheme.get_font())
	cancel_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	Global.apply_white_button_style(cancel_btn)
	vbox.add_child(cancel_btn)
	
	# ポーリング用のタイマー
	var poll_timer = Timer.new()
	poll_timer.wait_time = 2.0
	poll_timer.autostart = false
	lobby.add_child(poll_timer)
	
	var cbs = {}
	
	var disconnect_cbs_func = func(): pass # Reassigned below to capture all signals
	
	lobby.tree_exiting.connect(func(): disconnect_cbs_func.call())
	
	var clean_up_lobby = func():
		if is_instance_valid(poll_timer):
			poll_timer.stop()
		disconnect_cbs_func.call()
		if is_instance_valid(lobby):
			lobby.queue_free()
		
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		bm.webrtc_multiplayer.disconnect_room()
		Global.friend_room_code = ""
		clean_up_lobby.call()
		if from_mode_selection:
			ModeSelectionModal.create_and_show(parent, on_friend_match_pressed, national_names_pool)
	)
	
	var _is_starting_game = false
	

	
	var start_game_func = func():
		if _is_starting_game:
			return
		_is_starting_game = true
		AudioManager.play_se(AudioManager.SE_CLICK)
		DisplayServer.window_request_attention()

			
		var participants = bm.webrtc_multiplayer._participants
		if participants.size() < 4:
			status_lbl.text = "対戦相手が見つからなかったため、CPUを追加して開始します..."
		else:
			status_lbl.text = "マッチング完了！ゲームを開始します..."
		
		Global.game_mode = Constants.MODE_RANDOM
		Global.friend_member_list.assign(participants)
		Global.friend_is_host = bm.webrtc_multiplayer._is_host
		Global.friend_current_day = 1
		Global.friend_match_history.clear()
		MatchState.current_match_actions.clear()
		Global.save_game()
		
		Global.opponent_profiles.clear()
		var my_id = str(parent.multiplayer.get_unique_id()) if parent.multiplayer.has_multiplayer_peer() else "player"
		var idx = 0
		var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
		for p in participants:
			var uid = p.get("user_id", "")
			if uid != my_id:
				if idx < slots.size():
					var slot_id = slots[idx]
					Global.opponent_profiles[slot_id] = {
						"id": uid,
						"name": p.get("username", "ライバル")
					}
					idx += 1
					
		while idx < 3:
			var slot_id = slots[idx]
			var default_ids = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
			var def_id = default_ids[idx]
			var profile = AIManager.CPU_OPPONENTS.get(def_id, {"name": "CPU"})
			Global.opponent_profiles[slot_id] = {
				"id": def_id,
				"name": profile["name"] + " (CPU)"
			}
			idx += 1
			
		if participants.size() < 4 and is_instance_valid(members_vbox):
			for s_id in slots:
				if Global.opponent_profiles.has(s_id):
					var prof = Global.opponent_profiles[s_id]
					if str(prof.get("id", "")).begins_with("cpu_"):
						var cpu_lbl = Label.new()
						cpu_lbl.text = "・%s" % prof.get("name", "CPU")
						cpu_lbl.add_theme_font_override("font", DeskTheme.get_font())
						cpu_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
						cpu_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
						members_vbox.add_child(cpu_lbl)
				
		var timer = Timer.new()
		timer.wait_time = 2.2 if participants.size() < 4 else 1.2
		timer.one_shot = true
		if is_instance_valid(lobby):
			lobby.add_child(timer)
			timer.timeout.connect(func():
				var tree = parent.get_tree()
				clean_up_lobby.call()
				if is_instance_valid(tree):
					Global.change_scene_with_fade(tree, "res://Main.tscn")
			)
			timer.start()
	

	
	var update_participants_display = func():
		if not is_instance_valid(lobby) or not is_instance_valid(status_lbl):
			return
		
		var participants = bm.webrtc_multiplayer._participants
		var target_count = bm.webrtc_multiplayer.target_match_count
		
		for child in members_vbox.get_children():
			child.queue_free()
			
		status_lbl.text = "対戦相手を待っています... (%d/%d人)" % [participants.size(), target_count]
		
		for p in participants:
			var p_lbl = Label.new()
			p_lbl.text = "・%s" % p.get("username", "ライバル")
			p_lbl.add_theme_font_override("font", DeskTheme.get_font())
			p_lbl.add_theme_font_size_override("font_size", DeskTheme.scaled_font(16))
			p_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			members_vbox.add_child(p_lbl)
			
		if participants.size() >= target_count and not _is_starting_game:
			var all_connected = true
			var my_id = str(parent.multiplayer.get_unique_id()) if parent.multiplayer.has_multiplayer_peer() else "player"
			for p in participants:
				var uid = p.get("user_id", "")
				if uid != my_id and uid != "player":
					if not parent.multiplayer.get_peers().has(int(uid)):
						all_connected = false
						break
			if all_connected:
				start_game_func.call()

	cbs["room_joined"] = func(success: bool, participants: Array):
		if not is_instance_valid(status_lbl):
			return
		if success:
			update_participants_display.call()
			
	bm.webrtc_multiplayer.room_joined.connect(cbs["room_joined"])
	
	cbs["player_connected"] = func(id: int):
		update_participants_display.call()
				
	bm.webrtc_multiplayer.player_connected.connect(cbs["player_connected"])
	parent.multiplayer.peer_connected.connect(cbs["player_connected"])
	
	cbs["player_disconnected"] = func(id: int):
		update_participants_display.call()
				
	bm.webrtc_multiplayer.player_disconnected.connect(cbs["player_disconnected"])
	parent.multiplayer.peer_disconnected.connect(cbs["player_disconnected"])
	
	disconnect_cbs_func = func():
		if cbs.has("room_joined") and bm.webrtc_multiplayer.room_joined.is_connected(cbs["room_joined"]):
			bm.webrtc_multiplayer.room_joined.disconnect(cbs["room_joined"])
		if cbs.has("player_connected") and bm.webrtc_multiplayer.player_connected.is_connected(cbs["player_connected"]):
			bm.webrtc_multiplayer.player_connected.disconnect(cbs["player_connected"])
		if cbs.has("player_disconnected") and bm.webrtc_multiplayer.player_disconnected.is_connected(cbs["player_disconnected"]):
			bm.webrtc_multiplayer.player_disconnected.disconnect(cbs["player_disconnected"])
		if cbs.has("player_connected") and parent.multiplayer.peer_connected.is_connected(cbs["player_connected"]):
			parent.multiplayer.peer_connected.disconnect(cbs["player_connected"])
		if cbs.has("player_disconnected") and parent.multiplayer.peer_disconnected.is_connected(cbs["player_disconnected"]):
			parent.multiplayer.peer_disconnected.disconnect(cbs["player_disconnected"])
	
	Global.game_mode = Constants.MODE_RANDOM
	bm.webrtc_multiplayer.join_random_room()

static func _fetch_server_status(parent: Node, on_success: Callable) -> void:
	var ws_url = ProjectSettings.get_setting("backend/signaling_url", "")
	if ws_url == "":
		ws_url = "wss://study-chikenrace.onrender.com"
			
	var http_url = ws_url.replace("wss://", "https://").replace("ws://", "http://") + "/api/status"
	
	var http_req = HTTPRequest.new()
	parent.add_child(http_req)
	
	http_req.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json is Dictionary:
				var online = int(json.get("online_users", 1))
				var waiting = int(json.get("waiting_users", 0))
				on_success.call(online, waiting)
		http_req.queue_free()
	)
	
	var err = http_req.request(http_url)
	if err != OK:
		http_req.queue_free()
