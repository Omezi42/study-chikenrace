class_name TitleScene
extends Control

# UI Elements
var start_btn: Button
var loadout_btn: Button
var zukan_btn: Button
var gacha_btn: Button
var tutorial_btn: Button
var name_lbl_id: Label
var deviation_lbl_id: Label
var coin_lbl_id: Label
var record_lbl: Label

# Tutorial Slide Viewer Elements
var tutorial_modal: PanelContainer
var tutorial_slide_tex: TextureRect
var tutorial_page_lbl: Label
var tutorial_back_btn: Button
var tutorial_next_btn: Button
var tutorial_desc_lbl: Label
var current_tutorial_page: int = 1
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
	
	# Title Logo Container (Animated)
	var logo_container = Control.new()
	logo_container.custom_minimum_size = Vector2(800, 240)
	logo_container.pivot_offset = Vector2(400, 120)
	center_vbox.add_child(logo_container)
	
	var logo_center = CenterContainer.new()
	logo_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_container.add_child(logo_center)
	
	var logo_vbox = VBoxContainer.new()
	logo_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_vbox.add_theme_constant_override("separation", -10)
	logo_vbox.pivot_offset = Vector2(400, 120)
	logo_center.add_child(logo_vbox)
	
	# Top Text with Highlighter
	var top_text_container = Control.new()
	top_text_container.custom_minimum_size = Vector2(400, 70)
	logo_vbox.add_child(top_text_container)
	
	var highlighter = ColorRect.new()
	highlighter.color = DeskTheme.COLOR_HIGHLIGHTER
	highlighter.custom_minimum_size = Vector2(380, 24)
	highlighter.position = Vector2(10, 45)
	highlighter.rotation_degrees = -2.0
	highlighter.scale.x = 0.0 # Will animate
	highlighter.pivot_offset = Vector2(0, 12)
	top_text_container.add_child(highlighter)
	
	var top_lbl = Label.new()
	top_lbl.text = "テスト勉強"
	top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	top_lbl.add_theme_font_size_override("font_size", 64)
	top_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	top_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_text_container.add_child(top_lbl)
	
	# Bottom Text with Tension Color
	var bottom_lbl = Label.new()
	bottom_lbl.text = "チキンレース"
	bottom_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	bottom_lbl.add_theme_font_size_override("font_size", 96)
	bottom_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	bottom_lbl.add_theme_constant_override("outline_size", 8)
	bottom_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	logo_vbox.add_child(bottom_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "――ブラフで焦らせて、引きで勝つ。――"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	sub_lbl.add_theme_font_size_override("font_size", 24)
	sub_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	logo_vbox.add_child(sub_lbl)
	
	# Logo Animations
	# 1. Highlighter reveal
	var hl_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hl_tween.tween_property(highlighter, "scale:x", 1.0, 0.6).set_delay(0.3)
	
	# 2. Hand-drawn jitter (ゆらゆら)
	var jitter_timer = Timer.new()
	jitter_timer.wait_time = 0.15
	jitter_timer.autostart = true
	jitter_timer.timeout.connect(func():
		var target_rot = randf_range(-0.8, 0.8)
		var target_scale = Vector2(randf_range(0.985, 1.015), randf_range(0.985, 1.015))
		if is_inside_tree():
			var j_tween = create_tween().set_parallel(true)
			j_tween.tween_property(logo_vbox, "rotation_degrees", target_rot, 0.08)
			j_tween.tween_property(logo_vbox, "scale", target_scale, 0.08)
	)
	logo_container.add_child(jitter_timer)
	
	# 3. Heartbeat pulse
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(logo_container, "scale", Vector2(1.04, 1.04), 0.07).set_delay(1.2)
	pulse_tween.tween_property(logo_container, "scale", Vector2(1.02, 1.02), 0.05)
	pulse_tween.tween_property(logo_container, "scale", Vector2.ONE, 0.2)
	
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
	
	tutorial_btn = _create_menu_button("あそびかた", Vector2(160, 50), 18)
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	row_hbox.add_child(tutorial_btn)
	
	# NATIONAL MOCK EXAM BLACKBOARD (全国模試ランキング) - Left side
	var board = PanelContainer.new()
	board.custom_minimum_size = Vector2(480, 620)
	board.position = Vector2(80, 180)
	board.rotation_degrees = 1.0 # Slightly tilted
	
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
	board_style.shadow_color = Color(0, 0, 0, 0.2)
	board_style.shadow_size = 8
	board_style.shadow_offset = Vector2(4, 4)
	board.add_theme_stylebox_override("panel", board_style)
	add_child(board)
	
	var board_margin = MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 15)
	board_margin.add_theme_constant_override("margin_right", 15)
	board_margin.add_theme_constant_override("margin_top", 15)
	board_margin.add_theme_constant_override("margin_bottom", 15)
	board.add_child(board_margin)
	
	var board_vbox = VBoxContainer.new()
	board_vbox.add_theme_constant_override("separation", 10)
	board_margin.add_child(board_vbox)
	
	var board_title = Label.new()
	board_title.text = "全国統一模試ランキング 🏆"
	board_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	board_title.add_theme_font_size_override("font_size", 22)
	board_title.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
	board_vbox.add_child(board_title)
	
	var leaderboard = get_mock_exam_leaderboard()
	for idx in range(leaderboard.size()):
		var entry = leaderboard[idx]
		
		var entry_hbox = HBoxContainer.new()
		board_vbox.add_child(entry_hbox)
		
		var rank_lbl = Label.new()
		rank_lbl.text = "%d位 " % (idx + 1)
		rank_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		rank_lbl.add_theme_font_size_override("font_size", 16)
		if idx == 0:
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
		else:
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		entry_hbox.add_child(rank_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = entry["name"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		name_lbl.add_theme_font_size_override("font_size", 16)
		if entry.get("is_player", false):
			name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		else:
			name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		entry_hbox.add_child(name_lbl)
		
		var score_lbl = Label.new()
		score_lbl.text = "%d点" % entry["score"]
		score_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		score_lbl.add_theme_font_size_override("font_size", 16)
		score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_WHITE)
		entry_hbox.add_child(score_lbl)
	
	# STUDENT HANDBOOK ID CARD (生徒手帳)
	var id_card = PanelContainer.new()
	id_card.custom_minimum_size = Vector2(380, 240)
	id_card.position = Vector2(1920 - 430, 1080 - 290)
	id_card.rotation_degrees = -3.0 # Slightly tilted
	
	var id_style = StyleBoxFlat.new()
	id_style.bg_color = DeskTheme.COLOR_CRAFT
	id_style.border_color = Color("1a237e") # Student ID Blue
	id_style.border_width_left = 16 # binding border
	id_style.border_width_right = 3
	id_style.border_width_top = 3
	id_style.border_width_bottom = 3
	id_style.corner_radius_top_left = 8
	id_style.corner_radius_top_right = 8
	id_style.corner_radius_bottom_left = 8
	id_style.corner_radius_bottom_right = 8
	id_style.shadow_color = Color(0, 0, 0, 0.15)
	id_style.shadow_size = 5
	id_style.shadow_offset = Vector2(2, 2)
	id_card.add_theme_stylebox_override("panel", id_style)
	add_child(id_card)
	
	var id_margin = MarginContainer.new()
	id_margin.add_theme_constant_override("margin_left", 16)
	id_margin.add_theme_constant_override("margin_right", 16)
	id_margin.add_theme_constant_override("margin_top", 16)
	id_margin.add_theme_constant_override("margin_bottom", 16)
	id_card.add_child(id_margin)
	
	var id_vbox = VBoxContainer.new()
	id_vbox.add_theme_constant_override("separation", 10)
	id_margin.add_child(id_vbox)
	
	var id_header = Label.new()
	id_header.text = "生徒手帳 ID CARD"
	id_header.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	id_header.add_theme_font_size_override("font_size", 20)
	id_header.add_theme_color_override("font_color", Color("1a237e"))
	id_vbox.add_child(id_header)
	
	name_lbl_id = Label.new()
	name_lbl_id.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	name_lbl_id.add_theme_font_size_override("font_size", 16)
	name_lbl_id.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	id_vbox.add_child(name_lbl_id)
	
	deviation_lbl_id = Label.new()
	deviation_lbl_id.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	deviation_lbl_id.add_theme_font_size_override("font_size", 16)
	deviation_lbl_id.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	id_vbox.add_child(deviation_lbl_id)
	
	coin_lbl_id = Label.new()
	coin_lbl_id.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	coin_lbl_id.add_theme_font_size_override("font_size", 16)
	coin_lbl_id.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	id_vbox.add_child(coin_lbl_id)
	
	record_lbl = Label.new()
	record_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	record_lbl.add_theme_font_size_override("font_size", 16)
	record_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	id_vbox.add_child(record_lbl)
	
	_update_id_card_display()
	
	# 👤 Account Login/Logout button on top right of the desk
	var login_btn = Button.new()
	_update_login_btn_text(login_btn)
	login_btn.custom_minimum_size = Vector2(140, 45)
	login_btn.position = Vector2(1610, 40)
	login_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	login_btn.add_theme_font_size_override("font_size", 18)
	login_btn.pressed.connect(func():
		DeskTheme.animate_click(login_btn, Vector2.ONE, 0.08)
		if Global.logged_in_user_id != "":
			_logout_user(login_btn)
		else:
			show_login_modal(login_btn)
	)
	add_child(login_btn)
	
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.auth_completed.connect(func(success: bool, err: String):
			_update_login_btn_text(login_btn)
			_update_id_card_display()
		)
	
	# BGM will be deferred until first user interaction (WebGL Audio Autoplay Policy safety)
	# The _input callback will automatically resume AudioContext and trigger BGM play.
		
	# ⚙️ Option Settings floating button on top right of the desk
	var opt_btn = Button.new()
	opt_btn.text = "⚙️ 設定"
	opt_btn.custom_minimum_size = Vector2(110, 45)
	opt_btn.position = Vector2(1770, 40)
	opt_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	opt_btn.add_theme_font_size_override("font_size", 18)
	opt_btn.pressed.connect(func():
		DeskTheme.animate_click(opt_btn, Vector2.ONE, 0.08)
		DeskTheme.show_settings(self)
	)
	add_child(opt_btn)

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
	Global.game_mode = "cpu"
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
	var mode_modal = PanelContainer.new()
	mode_modal.custom_minimum_size = Vector2(720, 740)
	mode_modal.pivot_offset = Vector2(360, 370)
	
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
	
	add_child(mode_modal)
	mode_modal.position = Vector2((1920 - 720) / 2.0, (1080 - 740) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	mode_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "挑戦する自習モードを選択 📝"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_vbox)
	
	# CPU Mode Button
	var cpu_btn = Button.new()
	cpu_btn.custom_minimum_size = Vector2(660, 100)
	
	var cpu_inner = VBoxContainer.new()
	cpu_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	cpu_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cpu_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cpu_btn.add_child(cpu_inner)
	
	var cpu_title = Label.new()
	cpu_title.text = "🏫 校内自習 (CPU練習戦)"
	cpu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cpu_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	cpu_title.add_theme_font_size_override("font_size", 22)
	cpu_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	cpu_inner.add_child(cpu_title)
	
	var cpu_desc = Label.new()
	cpu_desc.text = "クラスメイト（佐藤・鈴木・高橋）と対戦する基本モード。偏差値は変動しません。"
	cpu_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cpu_desc.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	cpu_desc.add_theme_font_size_override("font_size", 14)
	cpu_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	cpu_inner.add_child(cpu_desc)
	
	btn_vbox.add_child(cpu_btn)
	
	# National Mode Button
	var national_btn = Button.new()
	national_btn.custom_minimum_size = Vector2(660, 100)
	
	var nat_inner = VBoxContainer.new()
	nat_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	nat_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nat_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	national_btn.add_child(nat_inner)
	
	var nat_title = Label.new()
	nat_title.text = "🏆 全国統一模試 (オンライン非同期戦)"
	nat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nat_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	nat_title.add_theme_font_size_override("font_size", 22)
	nat_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	nat_inner.add_child(nat_title)
	
	var nat_desc = Label.new()
	nat_desc.text = "全国のライバルのゴーストデータと競う本気モード。結果に応じて『偏差値』が変動！"
	nat_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nat_desc.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	nat_desc.add_theme_font_size_override("font_size", 14)
	nat_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	nat_inner.add_child(nat_desc)
	
	btn_vbox.add_child(national_btn)
	
	# Daily Exam Button
	var daily_btn = Button.new()
	daily_btn.custom_minimum_size = Vector2(660, 100)
	
	var daily_inner = VBoxContainer.new()
	daily_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	daily_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	daily_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daily_btn.add_child(daily_inner)
	
	var daily_title = Label.new()
	daily_title.text = "☕ 一夜漬けモード (1日1時限・全3日間)"
	daily_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	daily_title.add_theme_font_size_override("font_size", 22)
	daily_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	daily_inner.add_child(daily_title)
	
	var today_str = Time.get_date_string_from_system()
	
	var daily_desc = Label.new()
	daily_desc.text = "毎日変わる固定デッキで勝負！テンポ良く3日間（3分）でサクッと遊べます。"
	daily_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	daily_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_desc.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	daily_desc.add_theme_font_size_override("font_size", 14)
	daily_inner.add_child(daily_desc)
	
	btn_vbox.add_child(daily_btn)
	
	# Connect daily button
	daily_btn.pressed.connect(func():
		DeskTheme.animate_click(daily_btn, Vector2.ONE, 0.08)
		Global.game_mode = "cram"
		Global.daily_current_day = 1 # Reset to day 1 every time we start cram mode
		
		# Generate today's fixed deck
		Global.daily_fixed_deck = Global.generate_daily_fixed_deck(today_str)
		Global.current_deck = Global.daily_fixed_deck.duplicate()
		
		var day_idx = Global.daily_current_day
		
		daily_title.text = "マッチング中..."
		daily_btn.disabled = true
		
		var start_daily_match = func(ghosts: Array):
			var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
			Global.opponent_profiles.clear()
			for i in range(3):
				var slot = slots[i]
				var g = ghosts[i]
				Global.opponent_profiles[slot] = {
					"id": g.get("user_id", "cpu_" + str(i)),
					"name": g.get("username", "プレイヤー"),
					"deviation": clamp(Global.deviation_value + randf_range(-5.0, 5.0), 35.0, 80.0)
				}
				
			# Cram mode starts at Day 1 and finishes in one sitting.
			Global.daily_my_records.clear()
			Global.daily_opponent_ghosts.clear()
			
			var next_day_str = str(day_idx)
			Global.daily_opponent_ghosts[next_day_str] = ghosts
			Global.save_game()
			
			var timer = get_tree().create_timer(0.5)
			timer.timeout.connect(func():
				mode_modal.queue_free()
				if Global.player_name == "":
					Global.change_scene_with_fade(get_tree(), "res://Profile.tscn")
				else:
					Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
			)
			
		var bm_node = get_node_or_null("/root/BackendManager")
		if bm_node and Global.logged_in_user_id != "":
			var on_daily_loaded = Callable()
			on_daily_loaded = func(success: bool, records: Array):
				if bm_node.daily_scores_loaded.is_connected(on_daily_loaded):
					bm_node.daily_scores_loaded.disconnect(on_daily_loaded)
					
				var final_ghosts = []
				if success and records.size() >= 3:
					final_ghosts = records.slice(0, 3)
				else:
					final_ghosts = bm_node.generate_simulated_ghosts(day_idx)
				start_daily_match.call(final_ghosts)
				
			bm_node.daily_scores_loaded.connect(on_daily_loaded)
			bm_node.fetch_daily_records(day_idx)
		else:
			var dummy_ghosts = []
			if bm_node:
				dummy_ghosts = bm_node.generate_simulated_ghosts(day_idx)
			else:
				dummy_ghosts = [
					{"username": "佐藤くん", "score": 45, "record": {"actual_score": 45, "declared_score": 50, "hours": []}},
					{"username": "鈴木さん", "score": 52, "record": {"actual_score": 52, "declared_score": 52, "hours": []}},
					{"username": "高橋くん", "score": 40, "record": {"actual_score": 40, "declared_score": 55, "hours": []}}
				]
			start_daily_match.call(dummy_ghosts)
	)
	
	# Friend Match Button
	var friend_btn = Button.new()
	friend_btn.custom_minimum_size = Vector2(660, 100)
	
	var friend_inner = VBoxContainer.new()
	friend_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	friend_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	friend_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	friend_btn.add_child(friend_inner)
	
	var friend_title = Label.new()
	friend_title.text = "友達対戦 (ルーム非同期戦)"
	friend_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friend_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	friend_title.add_theme_font_size_override("font_size", 22)
	friend_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	friend_inner.add_child(friend_title)
	
	var friend_desc = Label.new()
	friend_desc.text = "ルームコードを共有して友達と対戦！日ごとに全員の自習完了を待って進行する非同期戦。"
	friend_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friend_desc.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	friend_desc.add_theme_font_size_override("font_size", 14)
	friend_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	friend_inner.add_child(friend_desc)
	
	btn_vbox.add_child(friend_btn)
	
	friend_btn.pressed.connect(func():
		DeskTheme.animate_click(friend_btn, Vector2.ONE, 0.08)
		mode_modal.queue_free()
		show_friend_lobby_selection_modal()
	)
	
	# Cancel Button
	var cancel_btn = Button.new()
	cancel_btn.text = "戻る ✖"
	cancel_btn.custom_minimum_size = Vector2(160, 45)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	cancel_btn.add_theme_font_size_override("font_size", 18)
	vbox.add_child(cancel_btn)
	
	# Connect signals
	cpu_btn.pressed.connect(func():
		DeskTheme.animate_click(cpu_btn, Vector2.ONE, 0.08)
		Global.game_mode = "cpu"
		# Select 3 random CPU opponents
		Global.select_random_opponents()
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func():
			mode_modal.queue_free()
			if Global.player_name == "":
				Global.change_scene_with_fade(get_tree(), "res://Profile.tscn")
			else:
				Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
		)
	)
	
	national_btn.pressed.connect(func():
		DeskTheme.animate_click(national_btn, Vector2.ONE, 0.08)
		Global.game_mode = "national"
		# Generate random profiles with random CPU ID mappings for simulation
		var pool = NATIONAL_NAMES.duplicate()
		pool.shuffle()
		var cpu_pool_keys = AIManager.CPU_OPPONENTS.keys().duplicate()
		cpu_pool_keys.shuffle()
		
		Global.opponent_profiles = {
			"cpu_sato": {
				"id": cpu_pool_keys[0],
				"name": pool[0],
				"deviation": clamp(Global.deviation_value + randf_range(-5.0, 5.0), 35.0, 80.0)
			},
			"cpu_suzuki": {
				"id": cpu_pool_keys[1],
				"name": pool[1],
				"deviation": clamp(Global.deviation_value + randf_range(-3.0, 3.0), 35.0, 80.0)
			},
			"cpu_takahashi": {
				"id": cpu_pool_keys[2],
				"name": pool[2],
				"deviation": clamp(Global.deviation_value + randf_range(-8.0, 8.0), 35.0, 80.0)
			}
		}
		Global.save_game()
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func():
			mode_modal.queue_free()
			if Global.player_name == "":
				Global.change_scene_with_fade(get_tree(), "res://Profile.tscn")
			else:
				Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
		)
	)
	
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		var tween = create_tween().bind_node(mode_modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(mode_modal, "scale", Vector2.ZERO, 0.2)
		tween.chain().tween_callback(func():
			mode_modal.queue_free()
		)
	)
	
	# Entrance animation
	mode_modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(mode_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mode_modal, "scale", Vector2.ONE, 0.3)

func show_tutorial_modal() -> void:
	current_tutorial_page = 1
	
	tutorial_modal = PanelContainer.new()
	tutorial_modal.custom_minimum_size = Vector2(1000, 770)
	tutorial_modal.pivot_offset = Vector2(500, 385)
	
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
	tutorial_modal.add_theme_stylebox_override("panel", style)
	
	add_child(tutorial_modal)
	tutorial_modal.position = Vector2((1920 - 1000) / 2.0, (1080 - 770) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	tutorial_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Title
	var header_title = Label.new()
	header_title.text = "テスト勉強チキンレースのあそびかた 📝"
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	header_title.add_theme_font_size_override("font_size", 24)
	header_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(header_title)
	
	# Texture Rect for slide
	tutorial_slide_tex = TextureRect.new()
	tutorial_slide_tex.custom_minimum_size = Vector2(960, 520)
	tutorial_slide_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(tutorial_slide_tex)
	
	# Description Label below slide
	tutorial_desc_lbl = Label.new()
	tutorial_desc_lbl.custom_minimum_size = Vector2(960, 80)
	tutorial_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_desc_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	tutorial_desc_lbl.add_theme_font_size_override("font_size", 18)
	tutorial_desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(tutorial_desc_lbl)
	
	# Bottom Nav HBox
	var nav_hbox = HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(nav_hbox)
	
	tutorial_back_btn = Button.new()
	tutorial_back_btn.text = "◀ 前へ"
	tutorial_back_btn.custom_minimum_size = Vector2(120, 45)
	tutorial_back_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	tutorial_back_btn.add_theme_font_size_override("font_size", 18)
	tutorial_back_btn.pressed.connect(_on_tutorial_back_pressed)
	nav_hbox.add_child(tutorial_back_btn)
	
	tutorial_page_lbl = Label.new()
	tutorial_page_lbl.text = "1 / 5"
	tutorial_page_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	tutorial_page_lbl.add_theme_font_size_override("font_size", 20)
	tutorial_page_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	nav_hbox.add_child(tutorial_page_lbl)
	
	tutorial_next_btn = Button.new()
	tutorial_next_btn.text = "次へ ▶"
	tutorial_next_btn.custom_minimum_size = Vector2(120, 45)
	tutorial_next_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	tutorial_next_btn.add_theme_font_size_override("font_size", 18)
	tutorial_next_btn.pressed.connect(_on_tutorial_next_pressed)
	nav_hbox.add_child(tutorial_next_btn)
	
	update_tutorial_slide()
	
	tutorial_modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(tutorial_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tutorial_modal, "scale", Vector2.ONE, 0.3)

func update_tutorial_slide() -> void:
	var path = "res://assets/tutorial/slide%d.png" % current_tutorial_page
	if ResourceLoader.exists(path):
		tutorial_slide_tex.texture = load(path)
	tutorial_page_lbl.text = "%d / 5" % current_tutorial_page
	tutorial_back_btn.disabled = (current_tutorial_page == 1)
	if current_tutorial_page == 5:
		tutorial_next_btn.text = "閉じる ✖"
	else:
		tutorial_next_btn.text = "次へ ▶"
		
	# Update description text
	match current_tutorial_page:
		1:
			tutorial_desc_lbl.text = "【① ゲームの基本ルール】\n『テスト勉強チキンレース』は、実点と申告点を競い合う5日間の勉強チキンレースゲームです。毎日3時限（または4時限）の自習を行い、カードを引いて勉強成果（実点）を高めます。"
		2:
			tutorial_desc_lbl.text = "【② 自習ノートと眠気（バースト）】\n山札からカードを引いて点数を積み上げます。ただし、手札と同じ数字のカードを引くと「寝落ち（バースト）」となり、その時限の点数はすべて0点になります！適度なところで「休憩する」を押して点数を確保しましょう。"
		3:
			tutorial_desc_lbl.text = "【③ アイテムの活用とコンボボーナス】\n各カードには様々な効果があります。消しゴムでバーストを無効化したり、シャーペンで点数をアップできます。また、同じ教科を連続で引くと「コンボ」、5教科すべて揃えると「5教科ボーナス」が発生します！"
		4:
			tutorial_desc_lbl.text = "【④ チキスタへの投稿と『嘘（ブラフ）』】\n一日の終わりに、今日の点数を勉強SNS『チキスタ』に投稿します。実際の点数より高く「嘘（ブラフ）」の点数を申告してライバルを焦らせることができます。ただし、盛りすぎるとダウトされる危険性が高まります！"
		5:
			tutorial_desc_lbl.text = "【⑤ 最終答え合わせと勝敗】\n5日目の終了後、全員の「実点」「申告点」「ダウト結果」が黒板で大公開されます！ダウトに成功すれば相手の盛り点をもらえ、失敗すればペナルティを受けます。最終的に最も点数の高い人が合格（優勝）です！"

func _on_tutorial_back_pressed() -> void:
	DeskTheme.animate_click(tutorial_back_btn, Vector2.ONE, 0.08)
	if current_tutorial_page > 1:
		current_tutorial_page -= 1
		update_tutorial_slide()

func _on_tutorial_next_pressed() -> void:
	DeskTheme.animate_click(tutorial_next_btn, Vector2.ONE, 0.08)
	if current_tutorial_page < 5:
		current_tutorial_page += 1
		update_tutorial_slide()
	else:
		var tween = create_tween().bind_node(tutorial_modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(tutorial_modal, "scale", Vector2.ZERO, 0.2)
		tween.chain().tween_callback(func():
			tutorial_modal.queue_free()
		)

func _create_menu_button(btn_text: String, min_size: Vector2, font_size: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = min_size
	
	# Normal stylebox (handdrawn craft note look)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = DeskTheme.COLOR_CRAFT
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

func _update_login_btn_text(btn: Button) -> void:
	if Global.logged_in_user_id != "":
		btn.text = "👤 ログアウト"
	else:
		btn.text = "👤 ログイン"

func _update_id_card_display() -> void:
	if name_lbl_id:
		var display_name = Global.player_name
		if display_name == "":
			if Global.logged_in_user_id != "":
				display_name = Global.logged_in_user_id
			else:
				display_name = "（未登録）"
		name_lbl_id.text = "氏名: " + display_name
		
	if deviation_lbl_id:
		deviation_lbl_id.text = "全国偏差値: %.1f (最高: %.1f)" % [Global.deviation_value, Global.max_deviation_value]
	if coin_lbl_id:
		coin_lbl_id.text = "所持コイン: " + str(Global.coins) + " 枚"
	if record_lbl:
		record_lbl.text = "最高スコア: " + str(Global.best_score) + " 点"

func _logout_user(btn: Button) -> void:
	Global.logged_in_user_id = ""
	Global.logged_in_password = ""
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.auth_token = ""
		bm.logged_in_uuid = ""
	Global.save_game()
	_update_login_btn_text(btn)
	_update_id_card_display()

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
	login_modal.position = Vector2((1920 - 500) / 2.0, (1080 - 440) / 2.0)
	
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
	btn_hbox.add_child(register_btn)
	
	var log_in_btn = Button.new()
	log_in_btn.text = "ログイン"
	log_in_btn.custom_minimum_size = Vector2(120, 45)
	log_in_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	log_in_btn.add_theme_font_size_override("font_size", 16)
	btn_hbox.add_child(log_in_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "閉じる"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	cancel_btn.add_theme_font_size_override("font_size", 16)
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
				_update_login_btn_text(login_btn_ref)
				_update_id_card_display()
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
	var sel_modal = PanelContainer.new()
	sel_modal.custom_minimum_size = Vector2(500, 360)
	sel_modal.pivot_offset = Vector2(250, 180)
	sel_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(sel_modal)
	sel_modal.position = Vector2((1920 - 500) / 2.0, (1080 - 360) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	sel_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "友達対戦ロビー"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	# Create Room Button
	var create_btn = Button.new()
	create_btn.text = "新しいルームを作る"
	create_btn.custom_minimum_size = Vector2(400, 60)
	create_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	create_btn.add_theme_font_size_override("font_size", 18)
	vbox.add_child(create_btn)
	
	# Join Room Section
	var join_hbox = HBoxContainer.new()
	join_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	join_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(join_hbox)
	
	var join_input = LineEdit.new()
	join_input.placeholder_text = "4桁のコードを入力"
	join_input.max_length = 4
	join_input.custom_minimum_size = Vector2(240, 45)
	join_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	join_input.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	join_input.add_theme_font_size_override("font_size", 16)
	join_hbox.add_child(join_input)
	
	var join_btn = Button.new()
	join_btn.text = "入室"
	join_btn.custom_minimum_size = Vector2(100, 45)
	join_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	join_btn.add_theme_font_size_override("font_size", 16)
	join_hbox.add_child(join_btn)
	
	# Close Button
	var cancel_btn = Button.new()
	cancel_btn.text = "閉じる"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	cancel_btn.add_theme_font_size_override("font_size", 16)
	vbox.add_child(cancel_btn)
	
	# Logic Bindings
	var bm = get_node_or_null("/root/BackendManager")
	
	create_btn.pressed.connect(func():
		DeskTheme.animate_click(create_btn, Vector2.ONE, 0.08)
		create_btn.disabled = true
		join_btn.disabled = true
		
		var on_created = func(success: bool, code: String):
			if success:
				sel_modal.queue_free()
				show_friend_lobby(code, true)
			else:
				create_btn.disabled = false
				join_btn.disabled = false
				
		if bm:
			bm.room_created.connect(on_created, CONNECT_ONE_SHOT)
			bm.create_friend_room()
		else:
			# Mock Fallback
			on_created.call(true, "4278")
	)
	
	join_btn.pressed.connect(func():
		var code = join_input.text.strip_edges()
		if code.length() != 4:
			return
		DeskTheme.animate_click(join_btn, Vector2.ONE, 0.08)
		create_btn.disabled = true
		join_btn.disabled = true
		
		var on_joined = func(success: bool, parts: Array):
			if success:
				sel_modal.queue_free()
				show_friend_lobby(code, false)
			else:
				create_btn.disabled = false
				join_btn.disabled = false
				
		if bm:
			bm.room_joined.connect(on_joined, CONNECT_ONE_SHOT)
			bm.join_friend_room(code)
		else:
			# Mock Fallback
			on_joined.call(true, [])
	)
	
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		sel_modal.queue_free()
	)
	
	sel_modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(sel_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sel_modal, "scale", Vector2.ONE, 0.3)

func show_friend_lobby(room_code: String, is_host: bool) -> void:
	var lobby_modal = PanelContainer.new()
	lobby_modal.custom_minimum_size = Vector2(600, 500)
	lobby_modal.pivot_offset = Vector2(300, 250)
	lobby_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(lobby_modal)
	lobby_modal.position = Vector2((1920 - 600) / 2.0, (1080 - 500) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	lobby_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "ロビー：友達の合流待ち (人数確認中)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	# Room Code display
	var code_lbl = Label.new()
	code_lbl.text = "ルームコード: " + room_code
	code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	code_lbl.add_theme_font_size_override("font_size", 36)
	code_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	vbox.add_child(code_lbl)
	
	var hint_lbl = Label.new()
	hint_lbl.text = "（友達にこのコードを教えて入室させてね！）"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	hint_lbl.add_theme_font_size_override("font_size", 14)
	hint_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	vbox.add_child(hint_lbl)
	
	# Participant List VBox
	var list_vbox = VBoxContainer.new()
	list_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	list_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(list_vbox)
	
	# Host Start Button (or Guest waiting label)
	var start_btn_lobby = Button.new()
	var waiting_lbl = Label.new()
	
	if is_host:
		start_btn_lobby.text = "自習を開始する！ ✏️"
		start_btn_lobby.custom_minimum_size = Vector2(260, 50)
		start_btn_lobby.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		start_btn_lobby.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		start_btn_lobby.add_theme_font_size_override("font_size", 18)
		start_btn_lobby.disabled = true # Enabled when 2+ players join
		vbox.add_child(start_btn_lobby)
	else:
		waiting_lbl.text = "ホストがゲームを開始するのを待っています..."
		waiting_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		waiting_lbl.add_theme_font_size_override("font_size", 16)
		waiting_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(waiting_lbl)
		
	# Exit Button
	var exit_btn = Button.new()
	exit_btn.text = "ロビーを出る ✖"
	exit_btn.custom_minimum_size = Vector2(160, 45)
	exit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exit_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	exit_btn.add_theme_font_size_override("font_size", 16)
	vbox.add_child(exit_btn)
	
	# Polling Logic via SceneTree timers
	var is_polling_active = true
	var bm = get_node_or_null("/root/BackendManager")
	
	var start_game_transition = func(final_participants: Array):
		is_polling_active = false
		Global.game_mode = "friend"
		Global.friend_room_code = room_code
		Global.friend_is_host = is_host
		Global.friend_member_list = final_participants
		Global.save_game()
		
		# Set slots for opponent profiles
		var slots = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
		var slot_idx = 0
		var my_id = bm.logged_in_uuid if (bm and bm.logged_in_uuid != "") else "player"
		
		Global.opponent_profiles.clear()
		for p in final_participants:
			var uid = p.get("user_id", "")
			if uid != my_id and slot_idx < 3:
				var slot = slots[slot_idx]
				Global.opponent_profiles[slot] = {
					"id": uid,
					"name": p.get("username", "プレイヤー"),
					"deviation": clamp(Global.deviation_value + randf_range(-5.0, 5.0), 35.0, 80.0)
				}
				slot_idx += 1
				
		# Fill any remaining slot with CPU default
		while slot_idx < 3:
			var slot = slots[slot_idx]
			var default_ids = ["cpu_sato", "cpu_suzuki", "cpu_takahashi"]
			var def_id = default_ids[slot_idx]
			var profile = AIManager.CPU_OPPONENTS.get(def_id, {"name": "CPU"})
			Global.opponent_profiles[slot] = {
				"id": def_id,
				"name": profile["name"] + " (CPU)",
				"deviation": 50.0
			}
			slot_idx += 1
			
		Global.save_game()
		
		# Go to Profile (if name blank) or Main game
		var fade_timer = get_tree().create_timer(0.2)
		fade_timer.timeout.connect(func():
			lobby_modal.queue_free()
			if Global.player_name == "":
				Global.change_scene_with_fade(get_tree(), "res://Profile.tscn")
			else:
				Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
		)
		
	var on_polled = Callable()
	on_polled = func(status: String, day: int, parts: Array):
		if not is_polling_active:
			return
			
		# Update participant list display
		for child in list_vbox.get_children():
			child.queue_free()
			
		for p in parts:
			var name_lbl = Label.new()
			name_lbl.text = "● " + p.get("username", "プレイヤー")
			if p.get("user_id") == (bm.logged_in_uuid if (bm and bm.logged_in_uuid != "") else "player"):
				name_lbl.text += " (あなた)"
				name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
			else:
				name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
			name_lbl.add_theme_font_size_override("font_size", 18)
			list_vbox.add_child(name_lbl)
			
		# If host, enable start button if we have at least 2 players
		if is_host:
			start_btn_lobby.disabled = (parts.size() < 2)
			
		# If guest, check if status changed to playing
		if not is_host and status == "playing":
			# Wait a split second to make sure parts contains CPUs if filled
			var fetch_timer = get_tree().create_timer(0.5)
			fetch_timer.timeout.connect(func():
				start_game_transition.call(parts)
			)
			return
			
		# Triggers next poll after 2 seconds
		if is_polling_active:
			var poll_timer = get_tree().create_timer(2.0)
			poll_timer.timeout.connect(func():
				if bm and is_polling_active:
					bm.poll_room_status(room_code)
			)
			
	if bm:
		bm.room_polled.connect(on_polled)
		bm.poll_room_status(room_code)
	else:
		# Offline fallback polling emulator
		var mock_parts = [{"user_id": "player", "username": Global.player_name if Global.player_name != "" else "あなた"}]
		on_polled.call("waiting", 1, mock_parts)
		
		# Offline simulated CPU joining lobby after 2 seconds
		var join_timer = get_tree().create_timer(2.0)
		join_timer.timeout.connect(func():
			if is_polling_active:
				mock_parts.append({"user_id": "cpu_sato", "username": "佐藤くん (CPU)"})
				mock_parts.append({"user_id": "cpu_suzuki", "username": "鈴木さん (CPU)"})
				on_polled.call("waiting", 1, mock_parts)
		)
		
	if is_host:
		start_btn_lobby.pressed.connect(func():
			DeskTheme.animate_click(start_btn_lobby, Vector2.ONE, 0.08)
			if bm:
				# Set status to playing and fill remaining slots
				bm.start_friend_game(room_code)
				# Quick fetch final list to transition
				var trans_timer = get_tree().create_timer(0.5)
				trans_timer.timeout.connect(func():
					start_game_transition.call(bm.mock_participants if bm.is_mock_room else bm.mock_participants)
				)
			else:
				# Offline mock start
				var final_parts = [
					{"user_id": "player", "username": Global.player_name if Global.player_name != "" else "あなた"},
					{"user_id": "cpu_sato", "username": "佐藤くん (CPU)"},
					{"user_id": "cpu_suzuki", "username": "鈴木さん (CPU)"},
					{"user_id": "cpu_takahashi", "username": "高橋くん (CPU)"}
				]
				start_game_transition.call(final_parts)
		)
		
	exit_btn.pressed.connect(func():
		DeskTheme.animate_click(exit_btn, Vector2.ONE, 0.08)
		is_polling_active = false
		if bm and bm.room_polled.is_connected(on_polled):
			bm.room_polled.disconnect(on_polled)
		lobby_modal.queue_free()
	)
	
	lobby_modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(lobby_modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(lobby_modal, "scale", Vector2.ONE, 0.3)
