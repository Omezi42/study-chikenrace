class_name TitleScene
extends Control

# UI Elements
var start_btn: Button
var quick_start_btn: Button
var loadout_btn: Button
var zukan_btn: Button
var gacha_btn: Button
var tutorial_btn: Button
var profile_btn: Button

# Tutorial Slide Viewer Elements

var bgm_started: bool = false
var is_transitioning: bool = false

const NATIONAL_NAMES = [
	"東大理三志望", "早慶合格マシーン", "徹夜明けの浪人生", "定期テストの神", 
	"赤点回避の守護神", "進研ゼミの覇者", "赤門くぐり隊", "偏差値70の天才",
	"単語帳と友達", "エナドリ中毒者", "一夜漬けのプロ", "授業中居眠りマン",
	"ガリ勉強眼鏡", "天才肌の帰国子女", "数学オリンピック選手"
]

func _ready() -> void:
	Global.is_tutorial_mode = false
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
	
	# Notebook Cover Panel
	var notebook_cover = PanelContainer.new()
	notebook_cover.custom_minimum_size = Vector2(900, 750)
	notebook_cover.pivot_offset = Vector2(450, 375)
	
	var cover_style = StyleBoxFlat.new()
	cover_style.bg_color = Color("2b3c5a") # Navy blue notebook cover
	cover_style.border_color = Color("1a2538")
	cover_style.border_width_left = 60 # Thick binding on the left
	cover_style.border_width_right = 4
	cover_style.border_width_top = 4
	cover_style.border_width_bottom = 4
	cover_style.corner_radius_top_right = 16
	cover_style.corner_radius_bottom_right = 16
	cover_style.shadow_color = Color(0, 0, 0, 0.4)
	cover_style.shadow_size = 20
	cover_style.shadow_offset = Vector2(10, 10)
	notebook_cover.add_theme_stylebox_override("panel", cover_style)
	center_container.add_child(notebook_cover)
	
	# Dashboard Container inside cover
	var dashboard_vbox = VBoxContainer.new()
	dashboard_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	dashboard_vbox.add_theme_constant_override("separation", 30)
	notebook_cover.add_child(dashboard_vbox)
	
	# Player Info (Name and Level)
	var player_info_lbl = Label.new()
	var p_name = Global.player_name if Global.player_name != "" else "ゲストプレイヤー"
	player_info_lbl.text = "%s  Lv.%d" % [p_name, PlayerState.player_level]
	player_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_info_lbl.add_theme_font_override("font", DeskTheme.get_font())
	player_info_lbl.add_theme_font_size_override("font_size", 48)
	player_info_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	dashboard_vbox.add_child(player_info_lbl)
	
	# Season / Exam Info
	var exam_info_lbl = Label.new()
	exam_info_lbl.text = "【 %s 】\n試験まであと %d 日" % [Global.get_season_name(), Global.get_season_remaining_days()]
	exam_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exam_info_lbl.add_theme_font_override("font", DeskTheme.get_font())
	exam_info_lbl.add_theme_font_size_override("font_size", 40)
	exam_info_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	dashboard_vbox.add_child(exam_info_lbl)
	
	# Stats Info
	var stats_lbl = Label.new()
	stats_lbl.text = "偏差値: %.1f    学年順位: %d 位" % [PlayerState.deviation_value, PlayerState.get_grade_rank()]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_override("font", DeskTheme.get_font())
	stats_lbl.add_theme_font_size_override("font_size", 36)
	stats_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	dashboard_vbox.add_child(stats_lbl)
	
	# Daily Missions Section
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	dashboard_vbox.add_child(spacer)
	
	var mission_title = Label.new()
	mission_title.text = "── 今日の課題 ──"
	mission_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_title.add_theme_font_override("font", DeskTheme.get_font())
	mission_title.add_theme_font_size_override("font_size", 32)
	mission_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	dashboard_vbox.add_child(mission_title)
	
	var mission_vbox = VBoxContainer.new()
	mission_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mission_vbox.add_theme_constant_override("separation", 10)
	dashboard_vbox.add_child(mission_vbox)
	
	if has_node("/root/DailyMissionManager"):
		var missions = get_node("/root/DailyMissionManager").get_missions_display()
		for m in missions:
			var hbox = HBoxContainer.new()
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_theme_constant_override("separation", 20)
			
			var checkbox = CheckBox.new()
			checkbox.button_pressed = m["completed"]
			checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			checkbox.add_theme_color_override("font_disabled_color", DeskTheme.COLOR_INK)
			checkbox.disabled = true # Cannot manually toggle
			hbox.add_child(checkbox)
			
			var desc_lbl = Label.new()
			var comp_str = "[達成]" if m["completed"] else "(%d/%d)" % [m["progress"], m["target"]]
			desc_lbl.text = "%s %s" % [m["desc"], comp_str]
			desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
			desc_lbl.add_theme_font_size_override("font_size", 28)
			desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			hbox.add_child(desc_lbl)
			
			var reward_lbl = Label.new()
			reward_lbl.text = "報酬: 🪙 %d" % m["reward"]
			reward_lbl.add_theme_font_override("font", DeskTheme.get_font())
			reward_lbl.add_theme_font_size_override("font_size", 24)
			reward_lbl.add_theme_color_override("font_color", Color("f57c00")) # Orange for coins
			hbox.add_child(reward_lbl)
			
			mission_vbox.add_child(hbox)

	
	# Study Start Button in Dashboard
	var start_spacer = Control.new()
	start_spacer.custom_minimum_size = Vector2(0, 30)
	dashboard_vbox.add_child(start_spacer)
	
	quick_start_btn = Button.new()
	quick_start_btn.text = "✏️ 勉強開始"
	quick_start_btn.custom_minimum_size = Vector2(320, 80)
	quick_start_btn.add_theme_font_override("font", DeskTheme.get_font())
	quick_start_btn.add_theme_font_size_override("font_size", 48)
	Global.apply_white_button_style(quick_start_btn)
	quick_start_btn.pressed.connect(_on_quick_start_pressed)
	
	var start_btn_margin = MarginContainer.new()
	start_btn_margin.add_theme_constant_override("margin_top", 10)
	start_btn_margin.add_theme_constant_override("margin_bottom", 10)
	start_btn_margin.add_child(quick_start_btn)
	dashboard_vbox.add_child(start_btn_margin)
	
	# Loop scale animation for Quick Start Button
	quick_start_btn.pivot_offset = Vector2(160, 40)
	var quick_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	quick_tween.tween_property(quick_start_btn, "scale", Vector2(1.05, 1.05), 0.5)
	quick_tween.tween_property(quick_start_btn, "scale", Vector2.ONE, 0.5)
	
	# Seasonal Flavor Text (季節イベント表示)
	var month = Time.get_datetime_dict_from_system()["month"]
	var seasonal_text = ""
	match month:
		12, 1, 2: seasonal_text = "⛄ 冬期講習 頑張ろう！"
		3, 4, 5: seasonal_text = "🌸 新学期スタート"
		6, 7, 8: seasonal_text = "🍉 夏を制する者は受験を制す"
		9, 10, 11: seasonal_text = "🍂 読書の秋・勉強の秋"
	
	var season_flavor_lbl = Label.new()
	season_flavor_lbl.text = seasonal_text
	season_flavor_lbl.add_theme_font_override("font", DeskTheme.get_font())
	season_flavor_lbl.add_theme_font_size_override("font_size", 24)
	season_flavor_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	# Position at bottom right of the notebook
	season_flavor_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	season_flavor_lbl.position = Vector2(600, 680)
	notebook_cover.add_child(season_flavor_lbl)
	
	# Desk Items (Replaces Sticky Notes)
	var desk_items_container = Control.new()
	desk_items_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desk_items_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desk_items_container)
	
	# Instead of right-aligned VBox, place items freely around the desk
	# We use buttons styled as objects
	
	# Loadout (Blue Notebook) - Bottom Left
	loadout_btn = _create_desk_item("デッキ編成", Vector2(200, 140), Color("42a5f5"), Vector2(150, 800), -5)
	loadout_btn.pressed.connect(_on_loadout_pressed)
	desk_items_container.add_child(loadout_btn)
	
	# Zukan (Red Notebook / Wordbook) - Top Left
	zukan_btn = _create_desk_item("アイテム図鑑", Vector2(180, 120), Color("ef5350"), Vector2(250, 150), 8)
	zukan_btn.pressed.connect(_on_zukan_pressed)
	desk_items_container.add_child(zukan_btn)
	
	# Gacha (Pencil Case) - Bottom Right
	gacha_btn = _create_desk_item("購買部ガチャ", Vector2(300, 100), Color("78909c"), Vector2(1450, 820), 12)
	gacha_btn.pressed.connect(_on_gacha_pressed)
	desk_items_container.add_child(gacha_btn)
	
	# Ranking (Ruler) - Right edge
	var ranking_btn = _create_desk_item("ランキング", Vector2(80, 400), Color("fff59d"), Vector2(1750, 400), -2)
	ranking_btn.pressed.connect(func():
		LeaderboardModal.create_and_show(self)
	)
	# Rotate text for ruler
	var rank_lbl = ranking_btn.get_child(0) as Label
	rank_lbl.rotation_degrees = 90
	rank_lbl.pivot_offset = Vector2(40, 200)
	desk_items_container.add_child(ranking_btn)
	
	# Tutorial / Mode / Settings as smaller items (Erasers, sticky notes)
	tutorial_btn = _create_desk_item("あそびかた", Vector2(120, 60), Color("bcaaa4"), Vector2(1650, 150), 15)
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	desk_items_container.add_child(tutorial_btn)
	
	start_btn = _create_desk_item("モード選択", Vector2(120, 60), Color("80d8ff"), Vector2(1600, 250), -10)
	start_btn.pressed.connect(_on_start_pressed)
	desk_items_container.add_child(start_btn)
	
	var opt_btn = _create_desk_item("設定", Vector2(100, 50), Color("e1bee7"), Vector2(150, 950), 0)
	opt_btn.pressed.connect(func():
		SettingsModal.create_and_show(self)
	)
	desk_items_container.add_child(opt_btn)

	
	# Setup hover animations for all desk items
	for child in desk_items_container.get_children():
		if child is Button:
			child.set_meta("original_rotation", child.rotation_degrees)
			child.mouse_entered.connect(func():
				var tween = child.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween.tween_property(child, "scale", Vector2(1.1, 1.1), 0.15)
				tween.parallel().tween_property(child, "rotation_degrees", child.rotation_degrees + randf_range(-5, 5), 0.15)
			)
			child.mouse_exited.connect(func():
				var tween = child.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween.tween_property(child, "scale", Vector2.ONE, 0.2)
				var orig_rot = child.get_meta("original_rotation", 0.0)
				tween.parallel().tween_property(child, "rotation_degrees", orig_rot, 0.2)
			)

	
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

func _on_quick_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	DeskTheme.animate_click(quick_start_btn, Vector2.ONE, 0.08)
	
	# Default player name if not entered
	if Global.player_name == "":
		Global.player_name = "プレイヤー"
		
	# Overnight cram study mode setup (3-minute gameplay)
	Global.game_mode = Constants.MODE_OVERNIGHT
	Global.opponent_profiles = {
		"cpu_sato": {"name": "佐藤くん", "deviation": 51.5},
		"cpu_suzuki": {"name": "鈴木さん", "deviation": 48.0},
		"cpu_takahashi": {"name": "高橋くん", "deviation": 54.2}
	}
	
	# If tutorial is not completed, force tutorial mode
	if not PlayerState.is_tutorial_completed:
		Global.is_tutorial_mode = true
	else:
		Global.is_tutorial_mode = false
	
	# Page Flip Animation before changing scene
	# We assume notebook_cover is child(2) inside center_container, we can search for it
	var cover = get_node_or_null("CenterContainer/PanelContainer")
	if not cover:
		# Fallback if path is incorrect: search children
		for c in get_children():
			if c is CenterContainer and c.get_child_count() > 0:
				cover = c.get_child(0)
				break
				
	if cover:
		var page_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		# ページめくり風：X軸方向のスケールを0にする
		cover.pivot_offset = Vector2(0, cover.size.y / 2) # 左端基準でめくる
		page_tween.tween_property(cover, "scale:x", 0.0, 0.4)
		page_tween.parallel().tween_property(cover, "modulate:a", 0.0, 0.4)
		await page_tween.finished
		
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
	)

func _on_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	DeskTheme.animate_click(start_btn, Vector2.ONE, 0.08)
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		show_mode_selection_modal()
		is_transitioning = false
	)

func _on_loadout_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	DeskTheme.animate_click(loadout_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://LoadoutScene.tscn")
	)

func _on_zukan_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	DeskTheme.animate_click(zukan_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://ZukanScene.tscn")
	)

func _on_gacha_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	DeskTheme.animate_click(gacha_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://GachaScene.tscn")
	)

func _on_tutorial_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
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
			is_transitioning = false
			ProfileIdCardModal.create_and_show(self, profile_btn, func():
				_update_profile_btn_text(profile_btn)
				if Global.player_name != "":
					Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
			)
		else:
			Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
	)

func show_mode_selection_modal() -> void:
	ModeSelectionModal.create_and_show(self, show_friend_lobby_selection_modal, NATIONAL_NAMES)

func show_tutorial_modal() -> void:
	var modal = TutorialModal.new()
	add_child(modal)

func _create_desk_item(btn_text: String, min_size: Vector2, item_color: Color, pos: Vector2, rot: float) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = min_size
	btn.size = min_size
	btn.position = pos
	btn.rotation_degrees = rot
	btn.pivot_offset = min_size / 2.0
	
	# Normal item style (like a notebook, pencil case, ruler)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = item_color
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.shadow_color = Color(0, 0, 0, 0.3)
	style_normal.shadow_size = 6
	style_normal.shadow_offset = Vector2(3, 3)
	
	# Add some edge details
	style_normal.border_color = item_color.darkened(0.2)
	style_normal.border_width_bottom = 4
	style_normal.border_width_right = 2
	
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = item_color.lightened(0.1)
	style_hover.shadow_size = 12
	style_hover.shadow_offset = Vector2(6, 6)
	
	var style_pressed = style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = item_color.darkened(0.1)
	style_pressed.shadow_size = 2
	style_pressed.shadow_offset = Vector2(1, 1)
	
	var style_focus = StyleBoxEmpty.new()
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_focus)
	
	var lbl = Label.new()
	lbl.text = btn_text
	lbl.add_theme_font_override("font", DeskTheme.get_font())
	# Dynamic font size based on height to fit inside the object
	lbl.add_theme_font_size_override("font_size", int(min_size.y * 0.4))
	lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK if item_color.get_luminance() > 0.5 else Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
	
	# We handle hover animations dynamically in the caller to save state, or here if needed.
	btn.pressed.connect(func():
		btn.release_focus()
	)
	
	return btn

func show_friend_lobby_selection_modal() -> void:
	FriendLobbyModal.create_selection_modal(self)

func _update_profile_btn_text(btn: Button) -> void:
	if Global.logged_in_user_id != "":
		var display_name = Global.player_name if Global.player_name != "" else Global.logged_in_user_id
		btn.text = display_name
	else:
		btn.text = "ログイン / 登録"



func _reflow_profile_button() -> void:
	if not is_instance_valid(profile_btn):
		return
	var vp = get_viewport_rect().size
	profile_btn.position = Vector2(max(vp.x - profile_btn.custom_minimum_size.x - 24.0, 24.0), 24.0)



