class_name TitleScene
extends Control

# UI Elements
var start_btn: Button
var loadout_btn: Button
var zukan_btn: Button
var gacha_btn: Button
var tutorial_btn: Button
var profile_btn: Button

# Tutorial Slide Viewer Elements

var bgm_started: bool = false

const NATIONAL_NAMES = [
	"東大理三志望", "早慶合格マシーン", "徹夜明けの浪人生", "定期テストの神", 
	"赤点回避の守護神", "進研ゼミの覇者", "赤門くぐり隊", "偏差値70の天才",
	"単語帳と友達", "エナドリ中毒者", "一夜漬けのプロ", "授業中居眠りマン",
	"ガリ勉強眼鏡", "天才肌の帰国子女", "数学オリンピック選手"
]

func _ready() -> void:
	# Mahogany background
	var bg_color = ColorRect.new()
	bg_color.color = DeskTheme.COLOR_MAHOGANY
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	# Load desk background if exists
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/机の背景画像-ノート無し.png"):
		bg_tex.texture = load("res://assets/机の背景画像-ノート無し.png")
	bg_tex.modulate = Color.WHITE
	add_child(bg_tex)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	var center_vbox = VBoxContainer.new()
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", 36)
	center_container.add_child(center_vbox)
	
	# Title Logo Container (Larger & Static)
	var logo_container = Control.new()
	logo_container.custom_minimum_size = Vector2(950, 300)
	logo_container.pivot_offset = Vector2(475, 150)
	center_vbox.add_child(logo_container)
	
	var logo_center = CenterContainer.new()
	logo_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_container.add_child(logo_center)
	
	var logo_vbox = VBoxContainer.new()
	logo_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_vbox.add_theme_constant_override("separation", -10)
	logo_vbox.pivot_offset = Vector2(475, 150)
	logo_center.add_child(logo_vbox)
	
	# Top Text with Highlighter
	var top_text_container = Control.new()
	top_text_container.custom_minimum_size = Vector2(500, 90)
	logo_vbox.add_child(top_text_container)
	
	var top_lbl = Label.new()
	top_lbl.text = "テスト勉強"
	top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	top_lbl.add_theme_font_size_override("font_size", 76)
	top_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	top_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_text_container.add_child(top_lbl)
	
	var highlighter = ColorRect.new()
	highlighter.color = DeskTheme.COLOR_HIGHLIGHTER
	highlighter.custom_minimum_size = Vector2(380, 30)
	highlighter.position = Vector2(160, 52) # Shifted another 100px right (60 -> 160)
	highlighter.rotation_degrees = -2.0
	highlighter.scale.x = 0.0 # Will animate on start
	highlighter.pivot_offset = Vector2(0, 15)
	highlighter.show_behind_parent = true
	top_lbl.add_child(highlighter)
	
	# Bottom Text with Tension Color
	var bottom_lbl = Label.new()
	bottom_lbl.text = "チキンレース"
	bottom_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	bottom_lbl.add_theme_font_size_override("font_size", 114)
	bottom_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	bottom_lbl.add_theme_constant_override("outline_size", 8)
	bottom_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	logo_vbox.add_child(bottom_lbl)

	
	# Logo Animations
	# 1. Highlighter reveal (スライド出現演出のみ有効)
	var hl_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hl_tween.tween_property(highlighter, "scale:x", 1.0, 0.6).set_delay(0.3)
	
	# 2. Hand-drawn jitter (ゆらゆら) - Disabled
	# 3. Heartbeat pulse - Disabled
	
	# Buttons VBox
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.add_theme_constant_override("separation", 18)
	center_vbox.add_child(btn_vbox)
	
	start_btn = _create_menu_button("ゲーム開始", Vector2(360, 70), 26)
	start_btn.pivot_offset = Vector2(180, 35)
	start_btn.pressed.connect(_on_start_pressed)
	btn_vbox.add_child(start_btn)
	
	# Loop scale animation for Start Button
	var start_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	start_tween.tween_property(start_btn, "scale", Vector2(1.05, 1.05), 0.6)
	start_tween.tween_property(start_btn, "scale", Vector2.ONE, 0.6)
	
	var row_hbox = HBoxContainer.new()
	row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	row_hbox.add_theme_constant_override("separation", 20)
	btn_vbox.add_child(row_hbox)
	
	loadout_btn = _create_menu_button("デッキ編成", Vector2(160, 50), 18)
	loadout_btn.pressed.connect(_on_loadout_pressed)
	row_hbox.add_child(loadout_btn)
	
	zukan_btn = _create_menu_button("アイテム図鑑", Vector2(160, 50), 18)
	zukan_btn.pressed.connect(_on_zukan_pressed)
	row_hbox.add_child(zukan_btn)
	
	gacha_btn = _create_menu_button("購買部ガチャ", Vector2(160, 50), 18)
	gacha_btn.pressed.connect(_on_gacha_pressed)
	row_hbox.add_child(gacha_btn)
	
	var row_hbox2 = HBoxContainer.new()
	row_hbox2.alignment = BoxContainer.ALIGNMENT_CENTER
	row_hbox2.add_theme_constant_override("separation", 20)
	btn_vbox.add_child(row_hbox2)
	
	tutorial_btn = _create_menu_button("あそびかた", Vector2(160, 50), 18)
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	row_hbox2.add_child(tutorial_btn)
	
	var ranking_btn = _create_menu_button("🏆 ランキング", Vector2(160, 50), 18)
	ranking_btn.pressed.connect(show_leaderboard_modal)
	row_hbox2.add_child(ranking_btn)
	
	var opt_btn = _create_menu_button("⚙️ 設定", Vector2(160, 50), 18)
	opt_btn.pressed.connect(func():
		DeskTheme.show_settings(self)
	)
	row_hbox2.add_child(opt_btn)
	
	# 👤 Profile/Login button on top right of the desk
	# 👤 Profile/Login button on top right of the desk
	profile_btn = Button.new()
	_update_profile_btn_text(profile_btn)
	profile_btn.custom_minimum_size = Vector2(180, 45)
	profile_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	profile_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(profile_btn)
	profile_btn.pressed.connect(func():
		DeskTheme.animate_click(profile_btn, Vector2.ONE, 0.08)
		if Global.logged_in_user_id != "":
			show_profile_id_card_modal(profile_btn)
		else:
			show_login_modal(profile_btn)
	)
	add_child(profile_btn)
	_reflow_profile_button()
	
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.auth_completed.connect(func(success: bool, err: String):
			_update_profile_btn_text(profile_btn)
		)
	
	# BGM will be deferred until first user interaction (WebGL Audio Autoplay Policy safety)
	# The _input callback will automatically resume AudioContext and trigger BGM play.

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reflow_profile_button()

func _input(event: InputEvent) -> void:
	if not bgm_started and (event is InputEventMouseButton or event is InputEventKey):
		if event.pressed:
			start_bgm()

func start_bgm() -> void:
	if bgm_started:
		return
	bgm_started = true
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_MAIN)

func _on_start_pressed() -> void:
	DeskTheme.animate_click(start_btn, Vector2.ONE, 0.08)
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		show_mode_selection_modal()
	)

func _on_loadout_pressed() -> void:
	DeskTheme.animate_click(loadout_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://LoadoutScene.tscn")
	)

func _on_zukan_pressed() -> void:
	DeskTheme.animate_click(zukan_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://ZukanScene.tscn")
	)

func _on_gacha_pressed() -> void:
	DeskTheme.animate_click(gacha_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://GachaScene.tscn")
	)

func _on_tutorial_pressed() -> void:
	DeskTheme.animate_click(tutorial_btn, Vector2.ONE, 0.08)
	Global.is_tutorial_mode = true
	Global.game_mode = Constants.MODE_CPU
	Global.opponent_profiles = {
		"cpu_sato": {"name": "佐藤くん", "deviation": 51.5},
		"cpu_suzuki": {"name": "鈴木さん", "deviation": 48.0},
		"cpu_takahashi": {"name": "高橋くん", "deviation": 54.2}
	}
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		if Global.player_name == "":
			Global.change_scene_with_fade(get_tree(), "res://Profile.tscn")
		else:
			Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
	)

func show_mode_selection_modal() -> void:
	ModeSelectionModal.create_and_show(self, show_friend_lobby_selection_modal, NATIONAL_NAMES)

func show_tutorial_modal() -> void:
	var modal = TutorialModal.new()
	add_child(modal)

func _create_menu_button(btn_text: String, min_size: Vector2, font_size: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = min_size
	
	# Normal stylebox (handdrawn craft note look, now white background)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.WHITE
	style_normal.border_color = DeskTheme.COLOR_INK
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 3
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	style_normal.shadow_color = Color(0.12, 0.08, 0.05, 0.22)
	style_normal.shadow_size = 4
	style_normal.shadow_offset = Vector2(2, 2)
	
	# Hover stylebox (slightly brighter highlight)
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color("fffde7")
	style_hover.border_width_left = 4
	style_hover.border_width_right = 4
	style_hover.border_width_top = 4
	style_hover.border_width_bottom = 4
	style_hover.shadow_size = 6
	style_hover.shadow_offset = Vector2(3, 3)
	
	# Pressed stylebox (pushed down)
	var style_pressed = style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = Color("e8e4db")
	style_pressed.shadow_size = 1
	style_pressed.shadow_offset = Vector2(1, 1)

	var style_focus = StyleBoxEmpty.new()
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_focus)
	
	var lbl = Label.new()
	lbl.text = btn_text
	lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
	
	# Connect micro-animations
	btn.mouse_entered.connect(func():
		DeskTheme.animate_hover(btn, true, Vector2.ONE, 0.12)
	)
	btn.mouse_exited.connect(func():
		DeskTheme.animate_hover(btn, false, Vector2.ONE, 0.12)
	)
	
	return btn
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

func show_login_modal(login_btn_ref: Button) -> void:
	var login_modal = PanelContainer.new()
	login_modal.custom_minimum_size = Vector2(500, 440)
	login_modal.pivot_offset = Vector2(250, 220)
	
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
	login_modal.add_theme_stylebox_override("panel", style)
	
	add_child(login_modal)
	login_modal.position = get_viewport_rect().size * 0.5 - login_modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	login_modal.add_child(margin)
	
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
	var on_auth = func(success: bool, err_msg: String):
		register_btn.disabled = false
		log_in_btn.disabled = false
		if success:
			status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
			status_lbl.text = "接続成功！"
			
			Global.logged_in_user_id = id_input.text.strip_edges()
			Global.logged_in_password = pw_input.text
			if Global.player_name == "":
				Global.player_name = Global.logged_in_user_id
			Global.save_game()
			
			if bm:
				bm.load_cloud_data()
				
			var close_timer = get_tree().create_timer(0.6)
			close_timer.timeout.connect(func():
				_update_profile_btn_text(login_btn_ref)
				login_modal.queue_free()
			)
		else:
			status_lbl.add_theme_color_override("font_color", Color("d32f2f"))
			status_lbl.text = err_msg
			
	if bm:
		bm.auth_completed.connect(on_auth)
		
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
			on_auth.call(true, "")
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
			on_auth.call(true, "")
	)
	
	cancel_btn.pressed.connect(func():
		if bm and bm.auth_completed.is_connected(on_auth):
			bm.auth_completed.disconnect(on_auth)
		login_modal.queue_free()
	)
	
	login_modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(login_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(login_modal, "scale", Vector2.ONE, 0.3)

func show_friend_lobby_selection_modal() -> void:
	FriendLobbyModal.create_selection_modal(self)

func _update_profile_btn_text(btn: Button) -> void:
	if Global.logged_in_user_id != "":
		var display_name = Global.player_name if Global.player_name != "" else Global.logged_in_user_id
		btn.text = "👤 " + display_name
	else:
		btn.text = "👤 ログイン / 登録"

func show_leaderboard_modal() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg_overlay)
	
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
	canvas.add_child(board)
	board.position = get_viewport_rect().size * 0.5 - board.pivot_offset - pivot_offset
	
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
			canvas.queue_free()
		)
	)
	
	# Entrance Animation
	board.scale = Vector2.ZERO
	var tween = create_tween().bind_node(board).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(board, "scale", Vector2.ONE, 0.3)

func show_profile_id_card_modal(profile_btn_ref: Button) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(460, 360)
	modal.pivot_offset = Vector2(230, 180)
	
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
	canvas.add_child(modal)
	modal.position = get_viewport_rect().size * 0.5 - modal.pivot_offset - pivot_offset
	
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
	header.text = "生徒手帳 ID CARD 👤"
	header.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color("1a237e"))
	vbox.add_child(header)
	
	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(name_hbox)
	
	var name_title = Label.new()
	name_title.text = "氏名: "
	name_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	name_title.add_theme_font_size_override("font_size", 18)
	name_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	name_hbox.add_child(name_title)
	
	var name_lbl = Label.new()
	name_lbl.text = Global.player_name if Global.player_name != "" else "（未登録）"
	name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	name_hbox.add_child(name_lbl)
	
	var name_input = LineEdit.new()
	name_input.text = Global.player_name
	name_input.custom_minimum_size = Vector2(200, 36)
	name_input.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	name_input.add_theme_font_size_override("font_size", 16)
	name_input.visible = false
	name_hbox.add_child(name_input)
	
	var edit_btn = Button.new()
	edit_btn.text = "✏️ 変更"
	edit_btn.custom_minimum_size = Vector2(80, 32)
	edit_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	edit_btn.add_theme_font_size_override("font_size", 14)
	Global.apply_white_button_style(edit_btn)
	name_hbox.add_child(edit_btn)
	
	var save_btn = Button.new()
	save_btn.text = "💾 保存"
	save_btn.custom_minimum_size = Vector2(80, 32)
	save_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	save_btn.add_theme_font_size_override("font_size", 14)
	Global.apply_white_button_style(save_btn)
	save_btn.visible = false
	name_hbox.add_child(save_btn)
	
	edit_btn.pressed.connect(func():
		DeskTheme.animate_click(edit_btn, Vector2.ONE, 0.08)
		name_lbl.visible = false
		edit_btn.visible = false
		name_input.visible = true
		save_btn.visible = true
		name_input.grab_focus()
	)
	
	save_btn.pressed.connect(func():
		DeskTheme.animate_click(save_btn, Vector2.ONE, 0.08)
		var new_name = name_input.text.strip_edges()
		if new_name != "":
			Global.player_name = new_name
			Global.save_game()
			name_lbl.text = new_name
			_update_profile_btn_text(profile_btn_ref)
		
		name_lbl.visible = true
		edit_btn.visible = true
		name_input.visible = false
		save_btn.visible = false
	)
	
	var deviation_lbl = Label.new()
	deviation_lbl.text = "全国偏差値: %.1f (最高: %.1f)" % [Global.deviation_value, Global.max_deviation_value]
	deviation_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	deviation_lbl.add_theme_font_size_override("font_size", 18)
	deviation_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(deviation_lbl)
	
	var coin_lbl = Label.new()
	coin_lbl.text = "所持コイン: " + str(Global.coins) + " 枚"
	coin_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	coin_lbl.add_theme_font_size_override("font_size", 18)
	coin_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(coin_lbl)
	
	var record_lbl = Label.new()
	record_lbl.text = "最高スコア: " + str(Global.best_score) + " 点"
	record_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	record_lbl.add_theme_font_size_override("font_size", 18)
	record_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(record_lbl)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(DeskTheme.COLOR_INK, 0.15)
	vbox.add_child(divider)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var logout_btn = Button.new()
	logout_btn.text = "👤 ログアウト"
	logout_btn.custom_minimum_size = Vector2(160, 45)
	logout_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	logout_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(logout_btn)
	logout_btn.add_theme_color_override("font_color", Color("d32f2f"))
	btn_hbox.add_child(logout_btn)
	
	logout_btn.pressed.connect(func():
		DeskTheme.animate_click(logout_btn, Vector2.ONE, 0.08)
		Global.logged_in_user_id = ""
		Global.logged_in_password = ""
		var bm_node = get_node_or_null("/root/BackendManager")
		if bm_node:
			bm_node.auth_token = ""
			bm_node.logged_in_uuid = ""
		Global.save_game()
		_update_profile_btn_text(profile_btn_ref)
		canvas.queue_free()
	)
	
	var close_btn = Button.new()
	close_btn.text = "閉じる ✖"
	close_btn.custom_minimum_size = Vector2(160, 45)
	close_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	close_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(close_btn)
	btn_hbox.add_child(close_btn)
	
	close_btn.pressed.connect(func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			canvas.queue_free()
		)
	)
	
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)

func _reflow_profile_button() -> void:
	if not is_instance_valid(profile_btn):
		return
	var vp = get_viewport_rect().size
	profile_btn.position = Vector2(max(vp.x - profile_btn.custom_minimum_size.x - 24.0, 24.0), 24.0)
