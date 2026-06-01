class_name LoginModal
extends PanelContainer

static func create_and_show(parent: Node, login_btn_ref: Button, on_success_callback: Callable) -> LoginModal:
	var modal = LoginModal.new()
	modal.setup(login_btn_ref, on_success_callback)
	parent.add_child(modal)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var tween = modal.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
	return modal

var login_btn: Button
var success_callback: Callable

func setup(btn: Button, callback: Callable) -> void:
	login_btn = btn
	success_callback = callback
	
	custom_minimum_size = Vector2(500, 440)
	pivot_offset = Vector2(250, 220)
	
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
	add_theme_stylebox_override("panel", style)
	
	# Viewport center position calculation
	position = get_viewport_rect().size * 0.5 - pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "👤 アカウント接続"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var id_vbox = VBoxContainer.new()
	id_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(id_vbox)
	
	var id_lbl = Label.new()
	id_lbl.text = "ユーザーID (英数字)"
	id_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	id_lbl.add_theme_font_size_override("font_size", 14)
	id_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	id_vbox.add_child(id_lbl)
	
	var id_input = LineEdit.new()
	id_input.placeholder_text = "例: testuser123"
	id_input.custom_minimum_size = Vector2(0, 40)
	id_input.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	id_input.add_theme_font_size_override("font_size", 16)
	id_vbox.add_child(id_input)
	
	var pw_vbox = VBoxContainer.new()
	pw_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(pw_vbox)
	
	var pw_lbl = Label.new()
	pw_lbl.text = "パスワード (6文字以上)"
	pw_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	pw_lbl.add_theme_font_size_override("font_size", 14)
	pw_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	pw_vbox.add_child(pw_lbl)
	
	var pw_input = LineEdit.new()
	pw_input.secret = true
	pw_input.placeholder_text = "パスワード"
	pw_input.custom_minimum_size = Vector2(0, 40)
	pw_input.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	pw_input.add_theme_font_size_override("font_size", 16)
	pw_vbox.add_child(pw_input)
	
	var status_lbl = Label.new()
	status_lbl.text = ""
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	status_lbl.add_theme_font_size_override("font_size", 14)
	status_lbl.add_theme_color_override("font_color", Color("d32f2f"))
	vbox.add_child(status_lbl)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_hbox)
	
	var register_btn = Button.new()
	register_btn.text = "新規登録"
	register_btn.custom_minimum_size = Vector2(120, 45)
	register_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	register_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(register_btn)
	btn_hbox.add_child(register_btn)
	
	var log_in_btn = Button.new()
	log_in_btn.text = "ログイン"
	log_in_btn.custom_minimum_size = Vector2(120, 45)
	log_in_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	log_in_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(log_in_btn)
	btn_hbox.add_child(log_in_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "閉じる"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	cancel_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(cancel_btn)
	btn_hbox.add_child(cancel_btn)
	
	var bm = get_node_or_null("/root/BackendManager")
	
	var on_auth_ref = [null]
	on_auth_ref[0] = func(success: bool, err_msg: String):
		register_btn.disabled = false
		log_in_btn.disabled = false
		if success:
			status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
			status_lbl.text = "接続成功！"
			
			Global.logged_in_user_id = id_input.text.strip_edges()
			if Global.player_name == "":
				Global.player_name = Global.logged_in_user_id
			Global.save_game()
			
			if bm:
				bm.load_cloud_data()
				
			var close_timer = get_tree().create_timer(0.6)
			close_timer.timeout.connect(func():
				if success_callback.is_valid():
					success_callback.call()
				queue_free()
			)
		else:
			status_lbl.add_theme_color_override("font_color", Color("d32f2f"))
			status_lbl.text = err_msg
			
	if bm:
		bm.auth_completed.connect(on_auth_ref[0])
		
	register_btn.pressed.connect(func():
		var uid = id_input.text.strip_edges()
		var pw = pw_input.text
		if uid.length() < 3 or pw.length() < 6:
			status_lbl.text = "IDは3文字以上、パスワードは6文字以上必要です"
			return
		register_btn.disabled = true
		log_in_btn.disabled = true
		status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		status_lbl.text = "登録中..."
		if bm:
			bm.signup_user(uid, pw)
		else:
			on_auth_ref[0].call(true, "")
	)
	
	log_in_btn.pressed.connect(func():
		var uid = id_input.text.strip_edges()
		var pw = pw_input.text
		if uid.length() < 3 or pw.length() < 6:
			status_lbl.text = "IDは3文字以上、パスワードは6文字以上必要です"
			return
		register_btn.disabled = true
		log_in_btn.disabled = true
		status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		status_lbl.text = "ログイン中..."
		if bm:
			bm.login_user(uid, pw)
		else:
			on_auth_ref[0].call(true, "")
	)
	
	cancel_btn.pressed.connect(func():
		if bm and bm.auth_completed.is_connected(on_auth_ref[0]):
			bm.auth_completed.disconnect(on_auth_ref[0])
		queue_free()
	)
