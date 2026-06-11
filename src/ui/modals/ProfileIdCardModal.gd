class_name ProfileIdCardModal
extends CanvasLayer

static func create_and_show(parent: Node, profile_btn_ref: Button, on_update_callback: Callable) -> ProfileIdCardModal:
	var modal = ProfileIdCardModal.new()
	modal.setup(profile_btn_ref, on_update_callback)
	parent.add_child(modal)
	return modal

var profile_btn: Button
var update_callback: Callable

func setup(btn: Button, callback: Callable) -> void:
	profile_btn = btn
	update_callback = callback

func _ready() -> void:
	layer = 100
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(460, 520)
	modal.pivot_offset = Vector2(230, 260)
	
	var id_style = StyleBoxFlat.new()
	id_style.bg_color = DeskTheme.COLOR_CRAFT
	id_style.border_color = Color("1a237e") # Student ID Blue
	id_style.border_width_left = 20 # binding border
	id_style.border_width_right = 4
	id_style.border_width_top = 4
	id_style.border_width_bottom = 4
	id_style.corner_radius_top_left = 12
	id_style.corner_radius_top_right = 12
	id_style.corner_radius_bottom_left = 12
	id_style.corner_radius_bottom_right = 12
	id_style.shadow_color = Color(0, 0, 0, 0.3)
	id_style.shadow_size = 15
	id_style.shadow_offset = Vector2(6, 6)
	modal.add_theme_stylebox_override("panel", id_style)
	add_child(modal)
	
	var viewport_size = get_viewport().get_visible_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "生徒手帳 ID CARD"
	header.add_theme_font_override("font", DeskTheme.get_font())
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color("1a237e"))
	vbox.add_child(header)
	
	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(name_hbox)
	
	var name_title = Label.new()
	name_title.text = "氏名: "
	name_title.add_theme_font_override("font", DeskTheme.get_font())
	name_title.add_theme_font_size_override("font_size", 18)
	name_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	name_hbox.add_child(name_title)
	
	var name_lbl = Label.new()
	name_lbl.text = Global.player_name if Global.player_name != "" else "（未登録）"
	name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	name_hbox.add_child(name_lbl)
	
	var name_input = LineEdit.new()
	name_input.text = Global.player_name
	name_input.custom_minimum_size = Vector2(200, 36)
	name_input.add_theme_font_override("font", DeskTheme.get_font())
	name_input.add_theme_font_size_override("font_size", 16)
	name_input.visible = false
	name_hbox.add_child(name_input)
	
	var edit_btn = Button.new()
	edit_btn.text = "変更"
	edit_btn.custom_minimum_size = Vector2(80, 32)
	edit_btn.add_theme_font_override("font", DeskTheme.get_font())
	edit_btn.add_theme_font_size_override("font_size", 14)
	Global.apply_white_button_style(edit_btn)
	name_hbox.add_child(edit_btn)
	
	var save_btn = Button.new()
	save_btn.text = "保存"
	save_btn.custom_minimum_size = Vector2(80, 32)
	save_btn.add_theme_font_override("font", DeskTheme.get_font())
	save_btn.add_theme_font_size_override("font_size", 14)
	Global.apply_white_button_style(save_btn)
	save_btn.visible = false
	name_hbox.add_child(save_btn)
	
	edit_btn.pressed.connect(func():
		edit_btn.release_focus()
		DeskTheme.animate_click(edit_btn, Vector2.ONE, 0.08)
		name_lbl.visible = false
		edit_btn.visible = false
		name_input.visible = true
		save_btn.visible = true
		name_input.grab_focus()
	)
	
	save_btn.pressed.connect(func():
		save_btn.release_focus()
		DeskTheme.animate_click(save_btn, Vector2.ONE, 0.08)
		var new_name = name_input.text.strip_edges()
		if new_name != "":
			Global.player_name = new_name
			Global.save_game()
			name_lbl.text = new_name
			if update_callback.is_valid():
				update_callback.call()
		
		name_lbl.visible = true
		edit_btn.visible = true
		name_input.visible = false
		save_btn.visible = false
	)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(title_hbox)
	
	var title_lbl_desc = Label.new()
	title_lbl_desc.text = "現在の称号: "
	title_lbl_desc.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl_desc.add_theme_font_size_override("font_size", 16)
	title_lbl_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	title_hbox.add_child(title_lbl_desc)
	
	var title_badge_style = StyleBoxFlat.new()
	title_badge_style.bg_color = Color("e0f2f1") # 淡いティール
	title_badge_style.border_color = Color("004d40") # 濃いティール
	title_badge_style.border_width_left = 1
	title_badge_style.border_width_right = 1
	title_badge_style.border_width_top = 1
	title_badge_style.border_width_bottom = 1
	title_badge_style.corner_radius_top_left = 4
	title_badge_style.corner_radius_top_right = 4
	title_badge_style.corner_radius_bottom_left = 4
	title_badge_style.corner_radius_bottom_right = 4
	title_badge_style.content_margin_left = 8
	title_badge_style.content_margin_right = 8
	title_badge_style.content_margin_top = 2
	title_badge_style.content_margin_bottom = 2
	
	var title_badge_panel = PanelContainer.new()
	title_badge_panel.add_theme_stylebox_override("panel", title_badge_style)
	title_hbox.add_child(title_badge_panel)
	
	var title_dropdown = OptionButton.new()
	title_dropdown.custom_minimum_size = Vector2(180, 32)
	title_dropdown.add_theme_font_override("font", DeskTheme.get_font())
	title_dropdown.add_theme_font_size_override("font_size", 14)
	
	var all_titles = Global.unlocked_titles.duplicate()
	if not "ただの凡人" in all_titles:
		all_titles.insert(0, "ただの凡人")
		
	var selected_id = 0
	for i in range(all_titles.size()):
		var t = all_titles[i]
		title_dropdown.add_item(t, i)
		if t == Global.player_title:
			selected_id = i
			
	title_dropdown.select(selected_id)
	title_dropdown.item_selected.connect(func(index: int):
		Global.player_title = title_dropdown.get_item_text(index)
		Global.save_game()
	)
	
	title_badge_panel.add_child(title_dropdown)
	
	var deviation_lbl = Label.new()
	deviation_lbl.text = "全国偏差値: %.1f (最高: %.1f)" % [Global.deviation_value, Global.max_deviation_value]
	deviation_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deviation_lbl.add_theme_font_size_override("font_size", 18)
	deviation_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(deviation_lbl)
	
	var coin_lbl = Label.new()
	coin_lbl.text = "所持コイン: " + str(Global.coins) + " 枚"
	coin_lbl.add_theme_font_override("font", DeskTheme.get_font())
	coin_lbl.add_theme_font_size_override("font_size", 18)
	coin_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(coin_lbl)
	
	var record_lbl = Label.new()
	record_lbl.text = "最高スコア: " + str(Global.best_score) + " 点"
	record_lbl.add_theme_font_override("font", DeskTheme.get_font())
	record_lbl.add_theme_font_size_override("font_size", 18)
	record_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(record_lbl)
	
	# --- 累計学習データセクション ---
	var divider_stats = ColorRect.new()
	divider_stats.custom_minimum_size = Vector2(0, 1)
	divider_stats.color = Color(DeskTheme.COLOR_INK, 0.1)
	vbox.add_child(divider_stats)

	var stats_title = Label.new()
	stats_title.text = "累計学習データ"
	stats_title.add_theme_font_override("font", DeskTheme.get_font())
	stats_title.add_theme_font_size_override("font_size", 16)
	stats_title.add_theme_color_override("font_color", Color("1a237e"))
	vbox.add_child(stats_title)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 30)
	stats_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(stats_grid)

	var total_doubts = Global.total_doubt_successes + Global.total_doubt_failures
	var doubt_rate_str = "0.0%"
	if total_doubts > 0:
		doubt_rate_str = "%.1f%% (%d/%d)" % [
			float(Global.total_doubt_successes) / total_doubts * 100.0,
			Global.total_doubt_successes,
			total_doubts
		]

	var stats_data = [
		["累計プレイ回数:", str(Global.play_count) + " 回"],
		["ダウト成功率:", doubt_rate_str],
		["累計バースト数:", str(Global.total_burst_count) + " 回"],
		["完全犯罪達成:", str(Global.total_perfect_crimes) + " 回"]
	]

	for item in stats_data:
		var lbl_t = Label.new()
		lbl_t.text = item[0]
		lbl_t.add_theme_font_override("font", DeskTheme.get_font())
		lbl_t.add_theme_font_size_override("font_size", 16)
		lbl_t.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
		stats_grid.add_child(lbl_t)

		var lbl_v = Label.new()
		lbl_v.text = item[1]
		lbl_v.add_theme_font_override("font", DeskTheme.get_font())
		lbl_v.add_theme_font_size_override("font_size", 16)
		lbl_v.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		stats_grid.add_child(lbl_v)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(DeskTheme.COLOR_INK, 0.15)
	vbox.add_child(divider)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var logout_btn = Button.new()
	logout_btn.text = "ログアウト"
	logout_btn.custom_minimum_size = Vector2(160, 45)
	logout_btn.add_theme_font_override("font", DeskTheme.get_font())
	logout_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(logout_btn)
	logout_btn.add_theme_color_override("font_color", Color("d32f2f"))
	btn_hbox.add_child(logout_btn)
	
	logout_btn.pressed.connect(func():
		logout_btn.release_focus()
		DeskTheme.animate_click(logout_btn, Vector2.ONE, 0.08)
		Global.logged_in_user_id = ""
		Global.auth_token = ""
		var bm_node = get_node_or_null("/root/BackendManager")
		if bm_node:
			bm_node.auth_token = ""
			bm_node.logged_in_uuid = ""
		Global.save_game()
		if update_callback.is_valid():
			update_callback.call()
		queue_free()
	)
	
	var close_btn = Button.new()
	close_btn.text = "閉じる ×"
	close_btn.custom_minimum_size = Vector2(160, 45)
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(close_btn)
	btn_hbox.add_child(close_btn)
	
	close_btn.pressed.connect(func():
		close_btn.release_focus()
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			queue_free()
		)
	)
	
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
