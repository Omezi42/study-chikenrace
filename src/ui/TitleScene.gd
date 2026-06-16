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
var ranking_btn: Button
var opt_btn: Button

# Notebook Inner Nodes for Reload
var name_lbl: Label
var lvl_lbl: Label
var coin_lbl: Label
var deviation_lbl: Label
var rank_lbl: Label
var mission_vbox: VBoxContainer
var recent_results_hbox: HBoxContainer

var bg_color: ColorRect
var bg_tex: TextureRect
var notebook_container: AspectRatioContainer
var notebook: PanelContainer

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
	
	# 1. Background Mahogany base
	bg_color = ColorRect.new()
	bg_color.color = DeskTheme.COLOR_MAHOGANY
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	# 2. Desk Background Image
	bg_tex = TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/机の背景画像-ノート無し.png"):
		bg_tex.texture = load("res://assets/机の背景画像-ノート無し.png")
	bg_tex.modulate = Color(1.0, 1.0, 1.0, 0.85) # slightly dim for contrast
	add_child(bg_tex)
	
	# 3. Setup Notebook UI
	_setup_notebook()
	
	# 4. Setup Desk Items (Sticky notes & stationery around the notebook)
	_setup_desk_items()
	
	# 5. Profile / Login Button (Top Right)
	_setup_profile_button()
	
	# Initial UI update
	_reload_all_data()
	
	# Responsive Layout Adjustment
	_reflow_layout()
	
	# Setup Listeners
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.auth_completed.connect(func(success: bool, err: String):
			_update_profile_btn_text()
			_reload_all_data()
		)

func _setup_notebook() -> void:
	notebook_container = AspectRatioContainer.new()
	notebook_container.ratio = 1.45 # Notebook Aspect Ratio
	notebook_container.stretch_mode = AspectRatioContainer.STRETCH_FIT
	notebook_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	notebook_container.custom_minimum_size = Vector2(960, 660)
	add_child(notebook_container)
	
	notebook = PanelContainer.new()
	var book_style = StyleBoxFlat.new()
	book_style.bg_color = Color("f5efe6") # Matte beige notebook paper
	book_style.corner_radius_top_left = 12
	book_style.corner_radius_bottom_left = 12
	book_style.corner_radius_top_right = 12
	book_style.corner_radius_bottom_right = 12
	book_style.shadow_color = Color(0, 0, 0, 0.35)
	book_style.shadow_size = 18
	book_style.shadow_offset = Vector2(8, 8)
	book_style.border_width_left = 2
	book_style.border_width_right = 2
	book_style.border_width_top = 2
	book_style.border_width_bottom = 4
	book_style.border_color = Color("d2c4b1")
	notebook.add_theme_stylebox_override("panel", book_style)
	notebook_container.add_child(notebook)
	
	# Inner HBox to split into Left Page, Binding, and Right Page
	var notebook_hbox = HBoxContainer.new()
	notebook_hbox.add_theme_constant_override("separation", 0)
	notebook.add_child(notebook_hbox)
	
	# --- LEFT PAGE ---
	var left_page = MarginContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.add_theme_constant_override("margin_left", 35)
	left_page.add_theme_constant_override("margin_right", 25)
	left_page.add_theme_constant_override("margin_top", 35)
	left_page.add_theme_constant_override("margin_bottom", 35)
	notebook_hbox.add_child(left_page)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 24)
	left_page.add_child(left_vbox)
	
	# Profile Header (Sticker style)
	var prof_header = PanelContainer.new()
	var prof_hdr_style = StyleBoxFlat.new()
	prof_hdr_style.bg_color = Color("3a6b5c") # Sage green sticker
	prof_hdr_style.corner_radius_top_left = 6
	prof_hdr_style.corner_radius_top_right = 6
	prof_hdr_style.corner_radius_bottom_left = 6
	prof_hdr_style.corner_radius_bottom_right = 6
	prof_hdr_style.content_margin_left = 15
	prof_hdr_style.content_margin_right = 15
	prof_hdr_style.content_margin_top = 5
	prof_hdr_style.content_margin_bottom = 5
	prof_header.add_theme_stylebox_override("panel", prof_hdr_style)
	
	var prof_hdr_lbl = Label.new()
	prof_hdr_lbl.text = "STUDENT PROFILE"
	prof_hdr_lbl.add_theme_font_override("font", DeskTheme.get_font())
	prof_hdr_lbl.add_theme_font_size_override("font_size", 20)
	prof_hdr_lbl.add_theme_color_override("font_color", Color.WHITE)
	prof_header.add_child(prof_hdr_lbl)
	left_vbox.add_child(prof_header)
	
	# Name & Level Panel
	var info_panel = PanelContainer.new()
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = Color("faf6f0")
	info_style.border_width_left = 4
	info_style.border_color = Color("3a6b5c") # Match sage green
	info_style.content_margin_left = 15
	info_style.content_margin_right = 15
	info_style.content_margin_top = 10
	info_style.content_margin_bottom = 10
	info_panel.add_theme_stylebox_override("panel", info_style)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 8)
	
	name_lbl = Label.new()
	name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	info_vbox.add_child(name_lbl)
	
	lvl_lbl = Label.new()
	lvl_lbl.add_theme_font_override("font", DeskTheme.get_font())
	lvl_lbl.add_theme_font_size_override("font_size", 22)
	lvl_lbl.add_theme_color_override("font_color", Color("6d5c4b"))
	info_vbox.add_child(lvl_lbl)
	
	info_panel.add_child(info_vbox)
	left_vbox.add_child(info_panel)
	
	# Stats block
	var stats_panel = PanelContainer.new()
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color("faf6f0")
	stats_style.corner_radius_top_left = 8
	stats_style.corner_radius_top_right = 8
	stats_style.corner_radius_bottom_left = 8
	stats_style.corner_radius_bottom_right = 8
	stats_style.content_margin_left = 15
	stats_style.content_margin_right = 15
	stats_style.content_margin_top = 12
	stats_style.content_margin_bottom = 12
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 6)
	
	deviation_lbl = Label.new()
	deviation_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deviation_lbl.add_theme_font_size_override("font_size", 24)
	deviation_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	stats_vbox.add_child(deviation_lbl)
	
	rank_lbl = Label.new()
	rank_lbl.add_theme_font_override("font", DeskTheme.get_font())
	rank_lbl.add_theme_font_size_override("font_size", 24)
	rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	stats_vbox.add_child(rank_lbl)
	
	stats_panel.add_child(stats_vbox)
	left_vbox.add_child(stats_panel)
	
	# Recent Results (WIN/LOSE badges)
	var recent_vbox = VBoxContainer.new()
	recent_vbox.add_theme_constant_override("separation", 12)
	
	var recent_title = Label.new()
	recent_title.text = "最近の成績"
	recent_title.add_theme_font_override("font", DeskTheme.get_font())
	recent_title.add_theme_font_size_override("font_size", 22)
	recent_title.add_theme_color_override("font_color", Color("5d4d3d"))
	recent_vbox.add_child(recent_title)
	
	recent_results_hbox = HBoxContainer.new()
	recent_results_hbox.add_theme_constant_override("separation", 10)
	recent_vbox.add_child(recent_results_hbox)
	
	left_vbox.add_child(recent_vbox)
	
	# --- BINDING / SPINE ---
	# A central spine to represent the binding of a book
	var spine = Control.new()
	spine.custom_minimum_size = Vector2(24, 0)
	spine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notebook_hbox.add_child(spine)
	
	# Draw binding rings/spine styling on top
	var spine_rect = ColorRect.new()
	spine_rect.color = Color("c0b3a0") # spine shadow
	spine_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spine.add_child(spine_rect)
	
	# Add vertical line
	var spine_line = ColorRect.new()
	spine_line.color = Color("9f907c")
	spine_line.custom_minimum_size = Vector2(2, 0)
	spine_line.set_anchors_and_offsets_preset(Control.PRESET_CENTER_Y)
	spine_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spine.add_child(spine_line)
	
	# --- RIGHT PAGE ---
	var right_page = MarginContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.add_theme_constant_override("margin_left", 25)
	right_page.add_theme_constant_override("margin_right", 35)
	right_page.add_theme_constant_override("margin_top", 35)
	right_page.add_theme_constant_override("margin_bottom", 35)
	notebook_hbox.add_child(right_page)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 20)
	right_page.add_child(right_vbox)
	
	# Top HBox for Daily Mission Title & Coins Count
	var right_top_hbox = HBoxContainer.new()
	right_vbox.add_child(right_top_hbox)
	
	var mission_title = Label.new()
	mission_title.text = "今日の課題"
	mission_title.add_theme_font_override("font", DeskTheme.get_font())
	mission_title.add_theme_font_size_override("font_size", 28)
	mission_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	mission_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_top_hbox.add_child(mission_title)
	
	# Coin Chip Design
	var coin_panel = PanelContainer.new()
	var coin_style = StyleBoxFlat.new()
	coin_style.bg_color = Color("fff9c4") # Light yellow
	coin_style.corner_radius_top_left = 15
	coin_style.corner_radius_top_right = 15
	coin_style.corner_radius_bottom_left = 15
	coin_style.corner_radius_bottom_right = 15
	coin_style.content_margin_left = 12
	coin_style.content_margin_right = 12
	coin_style.content_margin_top = 4
	coin_style.content_margin_bottom = 4
	coin_style.border_width_bottom = 2
	coin_style.border_color = Color("fbc02d")
	coin_panel.add_theme_stylebox_override("panel", coin_style)
	
	coin_lbl = Label.new()
	coin_lbl.add_theme_font_override("font", DeskTheme.get_font())
	coin_lbl.add_theme_font_size_override("font_size", 22)
	coin_lbl.add_theme_color_override("font_color", Color("f57c00"))
	coin_panel.add_child(coin_lbl)
	right_top_hbox.add_child(coin_panel)
	
	# Mission VBox
	mission_vbox = VBoxContainer.new()
	mission_vbox.add_theme_constant_override("separation", 10)
	mission_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(mission_vbox)
	
	# Quick Start Button / Study Start
	var start_margin = MarginContainer.new()
	start_margin.add_theme_constant_override("margin_top", 15)
	start_margin.add_theme_constant_override("margin_bottom", 5)
	
	quick_start_btn = Button.new()
	quick_start_btn.text = "✏️ 勉強開始"
	quick_start_btn.custom_minimum_size = Vector2(300, 75)
	quick_start_btn.add_theme_font_override("font", DeskTheme.get_font())
	quick_start_btn.add_theme_font_size_override("font_size", 36)
	Global.apply_white_button_style(quick_start_btn)
	quick_start_btn.pressed.connect(_on_quick_start_pressed)
	
	# Style Override for a more premium look
	var q_style_normal = quick_start_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	q_style_normal.bg_color = Color("e57373") # premium red study button
	q_style_normal.border_color = Color("d32f2f")
	q_style_normal.border_width_bottom = 5
	q_style_normal.shadow_color = Color(0, 0, 0, 0.25)
	q_style_normal.shadow_size = 8
	
	var q_style_hover = q_style_normal.duplicate() as StyleBoxFlat
	q_style_hover.bg_color = Color("ef5350")
	
	var q_style_pressed = q_style_normal.duplicate() as StyleBoxFlat
	q_style_pressed.bg_color = Color("c62828")
	q_style_pressed.border_width_bottom = 1
	
	quick_start_btn.add_theme_stylebox_override("normal", q_style_normal)
	quick_start_btn.add_theme_stylebox_override("hover", q_style_hover)
	quick_start_btn.add_theme_stylebox_override("pressed", q_style_pressed)
	quick_start_btn.add_theme_color_override("font_color", Color.WHITE)
	quick_start_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	quick_start_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	
	start_margin.add_child(quick_start_btn)
	right_vbox.add_child(start_margin)
	
	# Pulse animation for study button
	quick_start_btn.pivot_offset = Vector2(150, 37.5)
	var quick_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	quick_tween.tween_property(quick_start_btn, "scale", Vector2(1.04, 1.04), 0.6)
	quick_tween.tween_property(quick_start_btn, "scale", Vector2.ONE, 0.6)

func _setup_desk_items() -> void:
	# Container for all desk objects (Sticky notes, etc.)
	var items_node = Control.new()
	items_node.name = "DeskItems"
	items_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	items_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(items_node)
	
	# Create Buttons styled as stationery or sticky notes
	loadout_btn = _create_desk_item("デッキ編成", Vector2(160, 90), Color("42a5f5"), 5.0)
	loadout_btn.pressed.connect(_on_loadout_pressed)
	items_node.add_child(loadout_btn)
	
	zukan_btn = _create_desk_item("アイテム図鑑", Vector2(160, 90), Color("ef5350"), -6.0)
	zukan_btn.pressed.connect(_on_zukan_pressed)
	items_node.add_child(zukan_btn)
	
	gacha_btn = _create_desk_item("購買部ガチャ", Vector2(180, 80), Color("26a69a"), 8.0)
	gacha_btn.pressed.connect(_on_gacha_pressed)
	items_node.add_child(gacha_btn)
	
	ranking_btn = _create_desk_item("ランキング", Vector2(70, 220), Color("ffca28"), -2.0)
	ranking_btn.pressed.connect(func():
		LeaderboardModal.create_and_show(self)
	)
	var rank_item_lbl = ranking_btn.get_child(0) as Label
	rank_item_lbl.rotation_degrees = 90
	rank_item_lbl.pivot_offset = Vector2(35, 110)
	items_node.add_child(ranking_btn)
	
	tutorial_btn = _create_desk_item("あそびかた", Vector2(140, 70), Color("8d6e63"), 12.0)
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	items_node.add_child(tutorial_btn)
	
	start_btn = _create_desk_item("モード選択", Vector2(140, 70), Color("78909c"), -10.0)
	start_btn.pressed.connect(_on_start_pressed)
	items_node.add_child(start_btn)
	
	opt_btn = _create_desk_item("設定", Vector2(110, 60), Color("ab47bc"), 4.0)
	opt_btn.pressed.connect(func():
		SettingsModal.create_and_show(self)
	)
	items_node.add_child(opt_btn)
	
	# Setup hover & micro-interactions for all desk items
	for child in items_node.get_children():
		if child is Button:
			child.set_meta("original_rotation", child.rotation_degrees)
			child.mouse_entered.connect(func():
				var tween = child.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween.tween_property(child, "scale", Vector2(1.12, 1.12), 0.15)
				tween.parallel().tween_property(child, "rotation_degrees", child.rotation_degrees + randf_range(-4, 4), 0.15)
			)
			child.mouse_exited.connect(func():
				var tween = child.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween.tween_property(child, "scale", Vector2.ONE, 0.2)
				var orig_rot = child.get_meta("original_rotation", 0.0)
				tween.parallel().tween_property(child, "rotation_degrees", orig_rot, 0.2)
			)

func _setup_profile_button() -> void:
	profile_btn = Button.new()
	_update_profile_btn_text()
	profile_btn.custom_minimum_size = Vector2(180, 45)
	profile_btn.add_theme_font_override("font", DeskTheme.get_font())
	profile_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	Global.apply_white_button_style(profile_btn)
	profile_btn.pressed.connect(func():
		profile_btn.release_focus()
		DeskTheme.animate_click(profile_btn, Vector2.ONE, 0.08)
		if Global.logged_in_user_id != "":
			ProfileIdCardModal.create_and_show(self, profile_btn, func():
				_update_profile_btn_text()
				_reload_all_data()
			)
		else:
			LoginModal.create_and_show(self, profile_btn, func():
				_update_profile_btn_text()
				_reload_all_data()
			)
	)
	add_child(profile_btn)

func _reload_all_data() -> void:
	# Update Profile Info
	var p_name = Global.player_name if Global.player_name != "" else "ゲストプレイヤー"
	name_lbl.text = p_name
	lvl_lbl.text = "Lv. %d" % PlayerState.player_level
	deviation_lbl.text = "偏差値: %.1f" % PlayerState.deviation_value
	rank_lbl.text = "学年順位: %d 位 / 500人" % PlayerState.get_grade_rank()
	
	# Update Coins
	coin_lbl.text = "🪙 %d" % Global.coins
	
	# Update Recent Results Badges
	for child in recent_results_hbox.get_children():
		child.queue_free()
		
	var results = PlayerState.recent_results
	# Ensure up to 5 elements
	for i in range(min(5, results.size())):
		var res_str = results[i]
		var badge = PanelContainer.new()
		badge.custom_minimum_size = Vector2(48, 48)
		
		var b_style = StyleBoxFlat.new()
		b_style.corner_radius_top_left = 24
		b_style.corner_radius_top_right = 24
		b_style.corner_radius_bottom_left = 24
		b_style.corner_radius_bottom_right = 24
		b_style.shadow_color = Color(0, 0, 0, 0.15)
		b_style.shadow_size = 3
		
		if res_str == "WIN":
			b_style.bg_color = Color("e53935") # Vibrant red win badge
		else:
			b_style.bg_color = Color("78909c") # Slate grey lose badge
			
		badge.add_theme_stylebox_override("panel", b_style)
		
		var lbl = Label.new()
		lbl.text = res_str
		lbl.add_theme_font_override("font", DeskTheme.get_font())
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.add_child(lbl)
		
		recent_results_hbox.add_child(badge)
		
	# Update Daily Missions
	for child in mission_vbox.get_children():
		child.queue_free()
		
	if has_node("/root/DailyMissionManager"):
		var missions = get_node("/root/DailyMissionManager").get_missions_display()
		for m in missions:
			var hbox = HBoxContainer.new()
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_theme_constant_override("separation", 15)
			
			var checkbox = CheckBox.new()
			checkbox.button_pressed = m["completed"]
			checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			checkbox.add_theme_color_override("font_disabled_color", DeskTheme.COLOR_INK)
			checkbox.disabled = true
			hbox.add_child(checkbox)
			
			var desc_lbl = Label.new()
			var comp_str = "[達成]" if m["completed"] else "(%d/%d)" % [m["progress"], m["target"]]
			desc_lbl.text = "%s %s" % [m["desc"], comp_str]
			desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
			desc_lbl.add_theme_font_size_override("font_size", 20)
			desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(desc_lbl)
			
			var reward_lbl = Label.new()
			reward_lbl.text = "🪙%d" % m["reward"]
			reward_lbl.add_theme_font_override("font", DeskTheme.get_font())
			reward_lbl.add_theme_font_size_override("font_size", 18)
			reward_lbl.add_theme_color_override("font_color", Color("f57c00"))
			hbox.add_child(reward_lbl)
			
			mission_vbox.add_child(hbox)

func _create_desk_item(btn_text: String, min_size: Vector2, item_color: Color, rot: float) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = min_size
	btn.size = min_size
	btn.rotation_degrees = rot
	btn.pivot_offset = min_size / 2.0
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = item_color
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	style_normal.shadow_color = Color(0, 0, 0, 0.22)
	style_normal.shadow_size = 6
	style_normal.shadow_offset = Vector2(3, 4)
	style_normal.border_color = item_color.darkened(0.18)
	style_normal.border_width_bottom = 3
	style_normal.border_width_right = 1
	
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = item_color.lightened(0.12)
	style_hover.shadow_size = 10
	style_hover.shadow_offset = Vector2(5, 7)
	
	var style_pressed = style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = item_color.darkened(0.12)
	style_pressed.border_width_bottom = 1
	style_pressed.shadow_size = 2
	style_pressed.shadow_offset = Vector2(1, 2)
	
	var style_focus = StyleBoxEmpty.new()
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_focus)
	
	var lbl = Label.new()
	lbl.text = btn_text
	lbl.add_theme_font_override("font", DeskTheme.get_font())
	lbl.add_theme_font_size_override("font_size", int(min_size.y * 0.32))
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
	
	btn.pressed.connect(func():
		btn.release_focus()
	)
	
	return btn

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reflow_layout()

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

func _update_profile_btn_text() -> void:
	if not is_instance_valid(profile_btn):
		return
	if Global.logged_in_user_id != "":
		var display_name = Global.player_name if Global.player_name != "" else Global.logged_in_user_id
		profile_btn.text = display_name
	else:
		profile_btn.text = "ログイン / 登録"

func _reflow_layout() -> void:
	var vp = get_viewport_rect().size
	
	# Profile Button positioning
	if is_instance_valid(profile_btn):
		profile_btn.position = Vector2(max(vp.x - profile_btn.custom_minimum_size.x - 24.0, 24.0), 24.0)
		
	# Desk items repositioning based on viewport size
	var desk_items = get_node_or_null("DeskItems")
	if not is_instance_valid(desk_items):
		return
		
	# Find notebook bounds to place items neatly around it
	var nb_size = notebook_container.size
	var nb_pos = (vp - nb_size) / 2.0
	
	# Reposition items dynamically around the notebook
	# Loadout (Blue Notebook / Memo pad) - bottom left
	if is_instance_valid(loadout_btn):
		loadout_btn.position = nb_pos + Vector2(-120, nb_size.y - 70)
		
	# Zukan (Red Notebook) - top left
	if is_instance_valid(zukan_btn):
		zukan_btn.position = nb_pos + Vector2(-120, 40)
		
	# Gacha (Pencil Case) - bottom right
	if is_instance_valid(gacha_btn):
		gacha_btn.position = nb_pos + Vector2(nb_size.x - 60, nb_size.y - 60)
		
	# Ranking (Ruler) - right side of notebook
	if is_instance_valid(ranking_btn):
		ranking_btn.position = nb_pos + Vector2(nb_size.x + 50, (nb_size.y - 220) / 2)
		
	# Tutorial / How to play - top right
	if is_instance_valid(tutorial_btn):
		tutorial_btn.position = nb_pos + Vector2(nb_size.x - 40, -40)
		
	# Mode Selection - top center/left
	if is_instance_valid(start_btn):
		start_btn.position = nb_pos + Vector2(150, -45)
		
	# Settings - bottom left edge
	if is_instance_valid(opt_btn):
		opt_btn.position = Vector2(24.0, vp.y - opt_btn.custom_minimum_size.y - 24.0)

func _on_quick_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	DeskTheme.animate_click(quick_start_btn, Vector2.ONE, 0.08)
	
	if Global.player_name == "":
		Global.player_name = "プレイヤー"
		
	Global.game_mode = Constants.MODE_OVERNIGHT
	Global.opponent_profiles = {
		"cpu_sato": {"name": "佐藤くん", "deviation": 51.5},
		"cpu_suzuki": {"name": "鈴木さん", "deviation": 48.0},
		"cpu_takahashi": {"name": "高橋くん", "deviation": 54.2}
	}
	
	if not PlayerState.is_tutorial_completed:
		Global.is_tutorial_mode = true
	else:
		Global.is_tutorial_mode = false
	
	# Scene transition page flip style animation
	if notebook:
		var page_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		notebook.pivot_offset = Vector2(0, notebook.size.y / 2)
		page_tween.tween_property(notebook, "scale:x", 0.0, 0.4)
		page_tween.parallel().tween_property(notebook, "modulate:a", 0.0, 0.4)
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
				_update_profile_btn_text()
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

func show_friend_lobby_selection_modal() -> void:
	FriendLobbyModal.create_selection_modal(self)
