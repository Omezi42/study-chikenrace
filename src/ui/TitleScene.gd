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
	center_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_LARGE)
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
	top_lbl.add_theme_font_override("font", DeskTheme.get_font())
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
	bottom_lbl.add_theme_font_override("font", DeskTheme.get_font())
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
	btn_vbox.add_theme_constant_override("separation", DeskTheme.FONT_SIZE_SMALL)
	center_vbox.add_child(btn_vbox)
	
	start_btn = _create_menu_button("ゲーム開始", Vector2(360, 70), DeskTheme.FONT_SIZE_LARGE)
	start_btn.pivot_offset = Vector2(180, 35)
	start_btn.pressed.connect(_on_start_pressed)
	btn_vbox.add_child(start_btn)
	
	# Loop scale animation for Start Button
	var start_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	start_tween.tween_property(start_btn, "scale", Vector2(1.05, 1.05), 0.6)
	start_tween.tween_property(start_btn, "scale", Vector2.ONE, 0.6)
	
	var row_hbox = HBoxContainer.new()
	row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	row_hbox.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL)
	btn_vbox.add_child(row_hbox)
	
	loadout_btn = _create_menu_button("デッキ編成", Vector2(160, 50), DeskTheme.FONT_SIZE_SMALL)
	loadout_btn.pressed.connect(_on_loadout_pressed)
	row_hbox.add_child(loadout_btn)
	
	zukan_btn = _create_menu_button("アイテム図鑑", Vector2(160, 50), DeskTheme.FONT_SIZE_SMALL)
	zukan_btn.pressed.connect(_on_zukan_pressed)
	row_hbox.add_child(zukan_btn)
	
	gacha_btn = _create_menu_button("購買部ガチャ", Vector2(160, 50), DeskTheme.FONT_SIZE_SMALL)
	gacha_btn.pressed.connect(_on_gacha_pressed)
	row_hbox.add_child(gacha_btn)
	
	var row_hbox2 = HBoxContainer.new()
	row_hbox2.alignment = BoxContainer.ALIGNMENT_CENTER
	row_hbox2.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL)
	btn_vbox.add_child(row_hbox2)
	
	tutorial_btn = _create_menu_button("あそびかた", Vector2(160, 50), DeskTheme.FONT_SIZE_SMALL)
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	row_hbox2.add_child(tutorial_btn)
	
	var ranking_btn = _create_menu_button("🏆 ランキング", Vector2(160, 50), DeskTheme.FONT_SIZE_SMALL)
	ranking_btn.pressed.connect(func():
		LeaderboardModal.create_and_show(self)
	)
	row_hbox2.add_child(ranking_btn)
	
	var opt_btn = _create_menu_button("⚙️ 設定", Vector2(160, 50), DeskTheme.FONT_SIZE_SMALL)
	opt_btn.pressed.connect(func():
		SettingsModal.create_and_show(self)
	)
	row_hbox2.add_child(opt_btn)
	
	# 👤 Profile/Login button on top right of the desk
	profile_btn = Button.new()
	_update_profile_btn_text(profile_btn)
	profile_btn.custom_minimum_size = Vector2(180, 45)
	profile_btn.add_theme_font_override("font", DeskTheme.get_font())
	profile_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	Global.apply_white_button_style(profile_btn)
	profile_btn.pressed.connect(func():
		profile_btn.release_focus()
		DeskTheme.animate_click(profile_btn, Vector2.ONE, 0.08)
		if Global.logged_in_user_id != "":
			ProfileIdCardModal.create_and_show(self, profile_btn, func():
				_update_profile_btn_text(profile_btn)
			)
		else:
			LoginModal.create_and_show(self, profile_btn, func():
				_update_profile_btn_text(profile_btn)
			)
	)
	add_child(profile_btn)
	
	# Title Background Stationery (Pencil & Eraser) with micro-interactions (Loop 16)
	var pencil = Control.new()
	pencil.custom_minimum_size = Vector2(40, 240)
	pencil.size = Vector2(40, 240)
	pencil.position = Vector2(180, 480)
	pencil.rotation_degrees = 35.0
	pencil.pivot_offset = Vector2(20, 120)
	add_child(pencil)
	
	var p_body = PanelContainer.new()
	p_body.custom_minimum_size = Vector2(20, 180)
	p_body.size = Vector2(20, 180)
	p_body.position = Vector2(10, 0)
	var p_body_style = StyleBoxFlat.new()
	p_body_style.bg_color = Color("ffca28") # Yellow pencil body
	p_body_style.border_color = DeskTheme.COLOR_INK
	p_body_style.border_width_left = 2
	p_body_style.border_width_right = 2
	p_body_style.border_width_top = 2
	p_body_style.border_width_bottom = 2
	p_body_style.corner_radius_top_left = 2
	p_body_style.corner_radius_top_right = 2
	p_body.add_theme_stylebox_override("panel", p_body_style)
	pencil.add_child(p_body)
	
	var p_tip = PanelContainer.new()
	p_tip.custom_minimum_size = Vector2(20, 25)
	p_tip.size = Vector2(20, 25)
	p_tip.position = Vector2(10, 180)
	var p_tip_style = StyleBoxFlat.new()
	p_tip_style.bg_color = Color("ffe082") # Wood tip
	p_tip_style.border_color = DeskTheme.COLOR_INK
	p_tip_style.border_width_left = 2
	p_tip_style.border_width_right = 2
	p_tip_style.border_width_bottom = 2
	p_tip_style.corner_radius_bottom_left = 10
	p_tip_style.corner_radius_bottom_right = 10
	p_tip.add_theme_stylebox_override("panel", p_tip_style)
	pencil.add_child(p_tip)
	
	var p_lead = ColorRect.new()
	p_lead.color = DeskTheme.COLOR_INK
	p_lead.custom_minimum_size = Vector2(6, 6)
	p_lead.size = Vector2(6, 6)
	p_lead.position = Vector2(10 - 3, 25 - 6)
	p_tip.add_child(p_lead)
	
	# Eraser Setup
	var eraser = Control.new()
	eraser.custom_minimum_size = Vector2(100, 60)
	eraser.size = Vector2(100, 60)
	eraser.position = Vector2(1280, 530)
	eraser.rotation_degrees = -15.0
	eraser.pivot_offset = Vector2(50, 30)
	add_child(eraser)
	
	var e_body = PanelContainer.new()
	e_body.custom_minimum_size = Vector2(85, 45)
	e_body.size = Vector2(85, 45)
	e_body.position = Vector2(7, 7)
	var e_body_style = StyleBoxFlat.new()
	e_body_style.bg_color = Color.WHITE
	e_body_style.border_color = DeskTheme.COLOR_INK
	e_body_style.border_width_left = 2
	e_body_style.border_width_right = 2
	e_body_style.border_width_top = 2
	e_body_style.border_width_bottom = 2
	e_body_style.corner_radius_top_left = 4
	e_body_style.corner_radius_top_right = 4
	e_body_style.corner_radius_bottom_left = 4
	e_body_style.corner_radius_bottom_right = 4
	e_body.add_theme_stylebox_override("panel", e_body_style)
	eraser.add_child(e_body)
	
	var e_sleeve = PanelContainer.new()
	e_sleeve.custom_minimum_size = Vector2(50, 45)
	e_sleeve.size = Vector2(50, 45)
	e_sleeve.position = Vector2(35, 7) # Covers the right half
	var e_sleeve_style = StyleBoxFlat.new()
	e_sleeve_style.bg_color = Color("1565c0") # Blue sleeve
	e_sleeve_style.border_color = DeskTheme.COLOR_INK
	e_sleeve_style.border_width_left = 2
	e_sleeve_style.border_width_right = 2
	e_sleeve_style.border_width_top = 2
	e_sleeve_style.border_width_bottom = 2
	e_sleeve_style.corner_radius_top_right = 4
	e_sleeve_style.corner_radius_bottom_right = 4
	e_sleeve.add_theme_stylebox_override("panel", e_sleeve_style)
	eraser.add_child(e_sleeve)
	
	# Setup micro-interactions (jitter rot animation on hover)
	var setup_stationery_hover = func(ctrl: Control, base_rot: float):
		ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
		var active_tween: Tween = null
		
		ctrl.mouse_entered.connect(func():
			if active_tween:
				active_tween.kill()
			active_tween = ctrl.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			active_tween.tween_property(ctrl, "rotation_degrees", base_rot + 3.0, 0.05)
			active_tween.tween_property(ctrl, "rotation_degrees", base_rot - 3.0, 0.05)
			
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_se(AudioManager.SE_CLICK)
		)
		
		ctrl.mouse_exited.connect(func():
			if active_tween:
				active_tween.kill()
				active_tween = null
			var reset_tween = ctrl.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			reset_tween.tween_property(ctrl, "rotation_degrees", base_rot, 0.15)
		)
		
	setup_stationery_hover.call(pencil, 35.0)
	setup_stationery_hover.call(eraser, -15.0)
	
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
	lbl.add_theme_font_override("font", DeskTheme.get_font())
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
	btn.pressed.connect(func():
		btn.release_focus()
	)
	
	return btn

func show_friend_lobby_selection_modal() -> void:
	FriendLobbyModal.create_selection_modal(self)

func _update_profile_btn_text(btn: Button) -> void:
	if Global.logged_in_user_id != "":
		var display_name = Global.player_name if Global.player_name != "" else Global.logged_in_user_id
		btn.text = "👤 " + display_name
	else:
		btn.text = "👤 ログイン / 登録"



func _reflow_profile_button() -> void:
	if not is_instance_valid(profile_btn):
		return
	var vp = get_viewport_rect().size
	profile_btn.position = Vector2(max(vp.x - profile_btn.custom_minimum_size.x - 24.0, 24.0), 24.0)
