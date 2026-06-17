class_name TitleScene
extends Control

# UI Elements
var quick_start_btn: Button
var next_page_btn: Button # Renamed tab button
var prev_page_btn: Button # Back to title page index tab button
var profile_btn: Button
var ranking_btn: Button

# Left Page switcher containers
var left_content_container: Control
var profile_info_container: Control
var study_stats_container: Control # custom layout for secondary menu left page

# Page containers for Right Page
var right_content_container: Control
var study_menu_container: Control
var secondary_menu_container: Control # Renamed
var is_secondary_mode: bool = false
var quick_tween: Tween

# Notebook Inner Nodes for Reload
var name_lbl: Label
var coin_lbl: Label
var deviation_lbl: Label

# Daily Quest UI Nodes
var quest_vbox: VBoxContainer

# Overnight Info UI Nodes
var target_dev_lbl: Label
var deck_icons_grid: GridContainer
var top_right_btn_hbox: HBoxContainer
var title_preset_buttons: Array[Button] = []

var bg_color: ColorRect
var bg_tex: TextureRect
var notebook_container: Control
var notebook: PanelContainer

var bgm_started: bool = false
var is_transitioning: bool = false

const NATIONAL_NAMES = [
	"東大理三志望", "早慶合格マシーン", "徹夜明けの浪人生", "定期テストの神", 
	"赤点回避の守護神", "進研ゼミの覇者", "赤門くぐり隊", "偏差値70の天才",
	"単語帳と友達", "エナドリ中毒者", "短期集中のプロ", "授業中居眠りマン",
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
	
	# 4. Setup Desk Items (Empty or custom environment details)
	_setup_desk_items()
	
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
	notebook_container = Control.new()
	notebook_container.custom_minimum_size = Vector2(1500, 850)
	notebook_container.size = Vector2(1500, 850)
	add_child(notebook_container)
	
	notebook = PanelContainer.new()
	notebook.custom_minimum_size = Vector2(1500, 850)
	notebook.size = Vector2(1500, 850)
	var book_style = StyleBoxEmpty.new() # Background is drawn by left and right pages
	notebook.add_theme_stylebox_override("panel", book_style)
	notebook_container.add_child(notebook)
	
	# Notebook top-right exterior buttons (Settings & Tutorial)
	var system_menu_margin = MarginContainer.new()
	system_menu_margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	system_menu_margin.anchor_left = 1.0
	system_menu_margin.anchor_top = 0.0
	system_menu_margin.anchor_right = 1.0
	system_menu_margin.anchor_bottom = 0.0
	system_menu_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	system_menu_margin.grow_vertical = Control.GROW_DIRECTION_END
	system_menu_margin.add_theme_constant_override("margin_top", 20)
	system_menu_margin.add_theme_constant_override("margin_right", 20)
	add_child(system_menu_margin)
	
	top_right_btn_hbox = HBoxContainer.new()
	top_right_btn_hbox.add_theme_constant_override("separation", 12)
	top_right_btn_hbox.visible = true
	system_menu_margin.add_child(top_right_btn_hbox)
	
	# Inner HBox to split into Left Page, Binding, and Right Page
	var notebook_hbox = HBoxContainer.new()
	notebook_hbox.add_theme_constant_override("separation", 0)
	notebook.add_child(notebook_hbox)
	
	# --- LEFT PAGE (Student Profile & Progress / Switchable) ---
	var left_page_container = PanelContainer.new()
	left_page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page_container.custom_minimum_size = Vector2(750, 850)
	left_page_container.add_theme_stylebox_override("panel", DeskTheme.create_left_page_style())
	notebook_hbox.add_child(left_page_container)
	
	# Left content switcher container
	left_content_container = Control.new()
	left_content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_page_container.add_child(left_content_container)
	
	# --- Left View 1: Profile & Progress ---
	profile_info_container = MarginContainer.new()
	profile_info_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile_info_container.offset_left = 55
	profile_info_container.offset_right = -55
	profile_info_container.offset_top = 55
	profile_info_container.offset_bottom = -55
	left_content_container.add_child(profile_info_container)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 28)
	profile_info_container.add_child(left_vbox)
	
	# Profile Header (Sticker style)
	var prof_header = PanelContainer.new()
	prof_header.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var prof_hdr_style = StyleBoxFlat.new()
	prof_hdr_style.bg_color = Color("3a6b5c") # Sage green sticker
	prof_hdr_style.corner_radius_top_left = 9
	prof_hdr_style.corner_radius_top_right = 9
	prof_hdr_style.corner_radius_bottom_left = 9
	prof_hdr_style.corner_radius_bottom_right = 9
	prof_hdr_style.content_margin_left = 30
	prof_hdr_style.content_margin_right = 30
	prof_hdr_style.content_margin_top = 9
	prof_hdr_style.content_margin_bottom = 9
	prof_header.add_theme_stylebox_override("panel", prof_hdr_style)
	
	var prof_hdr_lbl = Label.new()
	prof_hdr_lbl.text = "学生証"
	prof_hdr_lbl.add_theme_font_override("font", DeskTheme.get_font())
	prof_hdr_lbl.add_theme_font_size_override("font_size", 31)
	prof_hdr_lbl.add_theme_color_override("font_color", Color.WHITE)
	prof_header.add_child(prof_hdr_lbl)
	left_vbox.add_child(prof_header)
	
	# Student Identity Panel
	var info_panel = PanelContainer.new()
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = Color("faf6f0")
	info_style.border_width_left = 6
	info_style.border_color = Color("3a6b5c")
	info_style.content_margin_left = 23
	info_style.content_margin_right = 23
	info_style.content_margin_top = 15
	info_style.content_margin_bottom = 15
	info_panel.add_theme_stylebox_override("panel", info_style)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 9)
	
	name_lbl = Label.new()
	name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	name_lbl.add_theme_font_size_override("font_size", 44)
	name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	info_vbox.add_child(name_lbl)
	
	profile_btn = Button.new()
	_update_profile_btn_text()
	profile_btn.custom_minimum_size = Vector2(280, 56)
	profile_btn.add_theme_font_override("font", DeskTheme.get_font())
	profile_btn.add_theme_font_size_override("font_size", 22)
	Global.apply_white_button_style(profile_btn)
	if ResourceLoader.exists("res://assets/icons/user.svg"):
		profile_btn.icon = load("res://assets/icons/user.svg")
		profile_btn.expand_icon = true
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
	info_vbox.add_child(profile_btn)
	
	info_panel.add_child(info_vbox)
	left_vbox.add_child(info_panel)
	
	# Academic Stats panel
	var stats_panel = PanelContainer.new()
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color("faf6f0")
	stats_style.corner_radius_top_left = 12
	stats_style.corner_radius_top_right = 12
	stats_style.corner_radius_bottom_left = 12
	stats_style.corner_radius_bottom_right = 12
	stats_style.content_margin_left = 23
	stats_style.content_margin_right = 23
	stats_style.content_margin_top = 18
	stats_style.content_margin_bottom = 18
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 12)
	
	var dev_rank_hbox = HBoxContainer.new()
	dev_rank_hbox.add_theme_constant_override("separation", 30)
	stats_vbox.add_child(dev_rank_hbox)
	
	var dev_rank_vbox = VBoxContainer.new()
	dev_rank_vbox.add_theme_constant_override("separation", 6)
	dev_rank_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dev_rank_hbox.add_child(dev_rank_vbox)
	
	deviation_lbl = Label.new()
	deviation_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deviation_lbl.add_theme_font_size_override("font_size", 34)
	deviation_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	dev_rank_vbox.add_child(deviation_lbl)
	
	# rank_lbl 関連は削除
	
	ranking_btn = Button.new()
	ranking_btn.text = " ランキング"
	ranking_btn.custom_minimum_size = Vector2(160, 56)
	ranking_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ranking_btn.add_theme_font_override("font", DeskTheme.get_font())
	ranking_btn.add_theme_font_size_override("font_size", 22)
	Global.apply_white_button_style(ranking_btn)
	if ResourceLoader.exists("res://assets/icons/trophy.svg"):
		ranking_btn.icon = load("res://assets/icons/trophy.svg")
		ranking_btn.expand_icon = true
	ranking_btn.pressed.connect(func():
		ranking_btn.release_focus()
		LeaderboardModal.create_and_show(self)
	)
	dev_rank_hbox.add_child(ranking_btn)
	
	stats_panel.add_child(stats_vbox)
	left_vbox.add_child(stats_panel)
	
	# Daily Quests UI
	var quest_vbox_main = VBoxContainer.new()
	quest_vbox_main.add_theme_constant_override("separation", 9)
	
	var quest_header_hbox = HBoxContainer.new()
	quest_header_hbox.add_theme_constant_override("separation", 15)
	quest_vbox_main.add_child(quest_header_hbox)
	
	var quest_title = Label.new()
	quest_title.text = "今日の課題"
	quest_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_title.add_theme_font_override("font", DeskTheme.get_font())
	quest_title.add_theme_font_size_override("font_size", 28)
	quest_title.add_theme_color_override("font_color", Color("5d4d3d"))
	quest_header_hbox.add_child(quest_title)
	
	# コイン表示（右ページから移動）
	var coin_panel = PanelContainer.new()
	var coin_style = StyleBoxFlat.new()
	coin_style.bg_color = Color("fff9c4")
	coin_style.corner_radius_top_left = 18
	coin_style.corner_radius_top_right = 18
	coin_style.corner_radius_bottom_left = 18
	coin_style.corner_radius_bottom_right = 18
	coin_style.content_margin_left = 14
	coin_style.content_margin_right = 14
	coin_style.content_margin_top = 4
	coin_style.content_margin_bottom = 4
	coin_style.border_width_bottom = 2
	coin_style.border_color = Color("fbc02d")
	coin_panel.add_theme_stylebox_override("panel", coin_style)
	
	coin_lbl = Label.new()
	coin_lbl.add_theme_font_override("font", DeskTheme.get_font())
	coin_lbl.add_theme_font_size_override("font_size", 20)
	coin_lbl.add_theme_color_override("font_color", Color("f57c00"))
	coin_panel.add_child(coin_lbl)
	quest_header_hbox.add_child(coin_panel)
	
	var quest_paper = PanelContainer.new()
	var qp_style = StyleBoxFlat.new()
	qp_style.bg_color = Color("faf6f0")
	qp_style.corner_radius_top_left = 9
	qp_style.corner_radius_top_right = 9
	qp_style.corner_radius_bottom_left = 9
	qp_style.corner_radius_bottom_right = 9
	qp_style.content_margin_left = 23
	qp_style.content_margin_right = 23
	qp_style.content_margin_top = 15
	qp_style.content_margin_bottom = 15
	quest_paper.add_theme_stylebox_override("panel", qp_style)
	quest_vbox_main.add_child(quest_paper)
	
	quest_vbox = VBoxContainer.new()
	quest_vbox.add_theme_constant_override("separation", 8)
	quest_paper.add_child(quest_vbox)
	
	left_vbox.add_child(quest_vbox_main)
	
	# --- Left View 2: Study Stats & Encyclopedia (For Secondary Menu) ---
	study_stats_container = MarginContainer.new()
	study_stats_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	study_stats_container.offset_left = 55
	study_stats_container.offset_right = -55
	study_stats_container.offset_top = 55
	study_stats_container.offset_bottom = -55
	study_stats_container.visible = false
	left_content_container.add_child(study_stats_container)
	
	var stats_left_vbox = VBoxContainer.new()
	stats_left_vbox.add_theme_constant_override("separation", 18)
	study_stats_container.add_child(stats_left_vbox)

	# Spine
	DeskTheme.add_spiral_binding(notebook_hbox, 850.0)
	DeskTheme.add_ruled_lines(left_page_container)
	
	# Index tab button to go BACK (placed on notebook_container to avoid layout parent stretching)
	prev_page_btn = PageFlipButton.new()
	prev_page_btn.is_next = false
	prev_page_btn.custom_minimum_size = Vector2(100, 100)
	prev_page_btn.size = Vector2(100, 100)
	prev_page_btn.visible = false # Hidden initially
	prev_page_btn.pressed.connect(func():
		_turn_page_anim(false)
	)
	notebook_container.add_child(prev_page_btn)
	
	# --- RIGHT PAGE (Play Main Area: One-night test) ---
	var right_page_container = PanelContainer.new()
	right_page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page_container.custom_minimum_size = Vector2(750, 850)
	right_page_container.add_theme_stylebox_override("panel", DeskTheme.create_right_page_style())
	notebook_hbox.add_child(right_page_container)
	DeskTheme.add_ruled_lines(right_page_container)
	
	# Right page switcher container
	right_content_container = Control.new()
	right_content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_page_container.add_child(right_content_container)
	
	# --- 1. Study Menu View ---
	study_menu_container = VBoxContainer.new()
	study_menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	study_menu_container.offset_left = 55
	study_menu_container.offset_right = -55
	study_menu_container.offset_top = 55
	study_menu_container.offset_bottom = -55
	study_menu_container.add_theme_constant_override("separation", 25)
	right_content_container.add_child(study_menu_container)
	
	# Main One-night Test Card (Header and coin display removed/moved)
	
	# Main One-night Test Card
	var cram_card = PanelContainer.new()
	cram_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("faf6f0")
	card_style.border_width_left = 5
	card_style.border_width_right = 5
	card_style.border_width_top = 5
	card_style.border_width_bottom = 5
	card_style.border_color = Color("d7ccc8") # cardboard soft borders
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.content_margin_left = 32
	card_style.content_margin_right = 32
	card_style.content_margin_top = 28
	card_style.content_margin_bottom = 28
	cram_card.add_theme_stylebox_override("panel", card_style)
	study_menu_container.add_child(cram_card)
	
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 18)
	cram_card.add_child(card_vbox)
	
	var c_title = Label.new()
	c_title.text = "ランダムマッチ"
	c_title.add_theme_font_override("font", DeskTheme.get_font())
	c_title.add_theme_font_size_override("font_size", 34)
	c_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_vbox.add_child(c_title)
	
	var c_desc = Label.new()
	c_desc.text = "オンラインで全国のプレイヤーと対戦！マッチングにより自動で集まった4人で心理戦を繰り広げます。"
	c_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c_desc.add_theme_font_override("font", DeskTheme.get_font())
	c_desc.add_theme_font_size_override("font_size", 22)
	c_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	card_vbox.add_child(c_desc)
	
	# Recent Results inside this card (目標偏差値と成功報酬は非表示化)
	var recent_vbox = VBoxContainer.new()
	recent_vbox.add_theme_constant_override("separation", 6)
	card_vbox.add_child(recent_vbox)
	
	var recent_header_hbox = HBoxContainer.new()
	recent_header_hbox.add_theme_constant_override("separation", 15)
	recent_vbox.add_child(recent_header_hbox)
	
	var recent_title = Label.new()
	recent_title.text = "現在のカバンの中身:"
	recent_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recent_title.add_theme_font_override("font", DeskTheme.get_font())
	recent_title.add_theme_font_size_override("font_size", 20)
	recent_title.add_theme_color_override("font_color", Color("7d6c5d"))
	recent_header_hbox.add_child(recent_title)
	
	var preset_hbox = HBoxContainer.new()
	preset_hbox.add_theme_constant_override("separation", 6)
	recent_header_hbox.add_child(preset_hbox)
	
	title_preset_buttons.clear()
	for i in range(1, 4):
		var p_btn = Button.new()
		p_btn.text = Global.deck_preset_names.get(str(i), "P%d" % i)
		p_btn.custom_minimum_size = Vector2(70, 32)
		p_btn.add_theme_font_override("font", DeskTheme.get_font())
		p_btn.add_theme_font_size_override("font_size", 14)
		Global.apply_white_button_style(p_btn)
		p_btn.pressed.connect(func():
			p_btn.release_focus()
			DeskTheme.animate_click(p_btn, Vector2.ONE, 0.08)
			_load_preset_on_title(i)
		)
		preset_hbox.add_child(p_btn)
		title_preset_buttons.append(p_btn)
	
	deck_icons_grid = GridContainer.new()
	deck_icons_grid.columns = 5
	deck_icons_grid.add_theme_constant_override("h_separation", 12)
	deck_icons_grid.add_theme_constant_override("v_separation", 10)
	recent_vbox.add_child(deck_icons_grid)
	
	# Start Button (Giant Red Button)
	var start_margin = MarginContainer.new()
	start_margin.add_theme_constant_override("margin_top", 8)
	
	quick_start_btn = Button.new()
	quick_start_btn.custom_minimum_size = Vector2(470, 110)
	quick_start_btn.add_theme_font_override("font", DeskTheme.get_font())
	quick_start_btn.add_theme_font_size_override("font_size", 47)
	Global.apply_white_button_style(quick_start_btn)
	
	# HBoxContainerをボタン内に作成して中央配置にする
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_hbox.add_theme_constant_override("separation", 15)
	quick_start_btn.add_child(btn_hbox)
	
	# 大きめの鉛筆アイコン
	if ResourceLoader.exists("res://assets/pencil_icon.png"):
		var icon_rect = TextureRect.new()
		icon_rect.texture = load("res://assets/pencil_icon.png")
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(80, 80)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_hbox.add_child(icon_rect)
		
	# 勉強開始テキスト
	var btn_label = Label.new()
	btn_label.text = "勉強開始"
	btn_label.add_theme_font_override("font", DeskTheme.get_font())
	btn_label.add_theme_font_size_override("font_size", 47)
	btn_label.add_theme_color_override("font_color", Color.WHITE)
	btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_hbox.add_child(btn_label)
	
	quick_start_btn.pressed.connect(_on_quick_start_pressed)
	
	var q_style_normal = quick_start_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	q_style_normal.bg_color = Color("e57373")
	q_style_normal.border_color = Color("d32f2f")
	q_style_normal.border_width_bottom = 8
	q_style_normal.shadow_color = Color(0, 0, 0, 0.22)
	q_style_normal.shadow_size = 9
	
	var q_style_hover = q_style_normal.duplicate() as StyleBoxFlat
	q_style_hover.bg_color = Color("ef5350")
	
	var q_style_pressed = q_style_normal.duplicate() as StyleBoxFlat
	q_style_pressed.bg_color = Color("c62828")
	q_style_pressed.border_width_bottom = 2
	
	quick_start_btn.add_theme_stylebox_override("normal", q_style_normal)
	quick_start_btn.add_theme_stylebox_override("hover", q_style_hover)
	quick_start_btn.add_theme_stylebox_override("pressed", q_style_pressed)
	quick_start_btn.add_theme_color_override("font_color", Color.WHITE)
	quick_start_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	quick_start_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	
	start_margin.add_child(quick_start_btn)
	study_menu_container.add_child(start_margin)
	
	# Pulse animation
	quick_start_btn.pivot_offset = Vector2(235, 55)
	quick_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	quick_tween.tween_property(quick_start_btn, "scale", Vector2(1.03, 1.03), 0.7)
	quick_tween.tween_property(quick_start_btn, "scale", Vector2.ONE, 0.7)
	
	# --- 2. Secondary Menu View ---
	secondary_menu_container = VBoxContainer.new()
	secondary_menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	secondary_menu_container.offset_left = 55
	secondary_menu_container.offset_right = -55
	secondary_menu_container.offset_top = 55
	secondary_menu_container.offset_bottom = -55
	secondary_menu_container.add_theme_constant_override("separation", 16)
	secondary_menu_container.visible = false # Hidden initially
	right_content_container.add_child(secondary_menu_container)
	
	_setup_secondary_menu_nodes()
	
	# Index tab button to go NEXT (designed as a hand-drawn arrow button)
	next_page_btn = PageFlipButton.new()
	next_page_btn.is_next = true
	next_page_btn.custom_minimum_size = Vector2(100, 100)
	next_page_btn.size = Vector2(100, 100)
	next_page_btn.pressed.connect(func():
		_turn_page_anim(true)
	)
	notebook_container.add_child(next_page_btn)

func _setup_secondary_menu_nodes() -> void:
	# --- LEFT PAGE: Main Action Items ---
	var left_vbox = study_stats_container.get_child(0) as VBoxContainer
	
	var left_title_vbox = VBoxContainer.new()
	left_title_vbox.add_theme_constant_override("separation", 2)
	left_vbox.add_child(left_title_vbox)
	
	var l_title = Label.new()
	l_title.text = "テストモードの選択"
	l_title.add_theme_font_override("font", DeskTheme.get_font())
	l_title.add_theme_font_size_override("font_size", 32)
	l_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	left_title_vbox.add_child(l_title)
	
	var l_subtitle = Label.new()
	l_subtitle.text = "— 挑戦するモードを選んで勉強を開始しよう —"
	l_subtitle.add_theme_font_override("font", DeskTheme.get_font())
	l_subtitle.add_theme_font_size_override("font_size", 15)
	l_subtitle.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	left_title_vbox.add_child(l_subtitle)
	
	# Medium buttons for balanced fitting of 4 items
	_add_menu_button(
		left_vbox,
		"ランダムマッチ",
		"オンラインで全国のプレイヤーと対戦！マッチングにより自動で集まった4人で心理戦を繰り広げます。",
		"medium",
		func():
			if not has_node("/root/BackendManager"):
				return
			var bm = get_node("/root/BackendManager")
			if bm.auth_token == "" or bm.logged_in_uuid == "":
				ModeSelectionModal._show_login_warning(self, null, NATIONAL_NAMES, show_friend_lobby_selection_modal)
				return
			Global.game_mode = Constants.MODE_RANDOM
			ModeSelectionModal._show_matching_lobby(self, null, bm, NATIONAL_NAMES, show_friend_lobby_selection_modal),
		"res://assets/icons/trophy.svg",
		Color("fb923c") # Orange
	)
	
	_add_menu_button(
		left_vbox,
		"フレンド戦",
		"合言葉を決めて友達と合流！最大4人のプレイヤーで3日間の心理戦をリアルタイムに対戦しよう。",
		"medium",
		func():
			show_friend_lobby_selection_modal(),
		"res://assets/icons/user.svg",
		Color("4ade80") # Green
	)
	
	_add_menu_button(
		left_vbox,
		"模試",
		"実力テストに挑戦！CPUライバルたちと3日間の偏差値競争を行い、合格・進級を目指そう。",
		"medium",
		func():
			Global.game_mode = Constants.MODE_NATIONAL
			ModeSelectionModal._show_difficulty_selection(self, null, show_friend_lobby_selection_modal, NATIONAL_NAMES),
		"res://assets/icons/calendar.svg",
		Color("60a5fa") # Blue
	)
	
	# --- RIGHT PAGE: Loadout, Shop, Encyclopedia ---
	var right_title_vbox = VBoxContainer.new()
	right_title_vbox.add_theme_constant_override("separation", 2)
	secondary_menu_container.add_child(right_title_vbox)
	
	var r_title = Label.new()
	r_title.text = "鞄整理と購買部"
	r_title.add_theme_font_override("font", DeskTheme.get_font())
	r_title.add_theme_font_size_override("font_size", 32)
	r_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	right_title_vbox.add_child(r_title)
	
	var r_subtitle = Label.new()
	r_subtitle.text = "— 文房具の調整と補充 —"
	r_subtitle.add_theme_font_override("font", DeskTheme.get_font())
	r_subtitle.add_theme_font_size_override("font_size", 15)
	r_subtitle.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	right_title_vbox.add_child(r_subtitle)
	
	# Loadout is highlighted as a large button
	_add_menu_button(
		secondary_menu_container,
		"カバン整理 (デッキ編成)",
		"デッキをのぞき見る『単語帳』や、寝落ちを防ぐ『消しゴム』など便利なアイテムをカバンに詰め込もう！",
		"large",
		func():
			Global.change_scene_with_fade(get_tree(), "res://LoadoutScene.tscn"),
		"res://assets/icons/backpack.svg",
		Color("facc15") # Yellow
	)
	
	_add_menu_button(
		secondary_menu_container,
		"購買部ガチャ",
		"貯めたコインを使って、新しい効果を持った便利な文房具アイテムをアンロック！",
		"medium",
		func():
			Global.change_scene_with_fade(get_tree(), "res://GachaScene.tscn"),
		"res://assets/icons/shopping-cart.svg",
		Color("c084fc") # Purple
	)
	
	_add_menu_button(
		secondary_menu_container,
		"アイテム図鑑",
		"解放した文房具の効果や、使い込んで獲得した星レベルを確認しよう！",
		"medium",
		func():
			Global.change_scene_with_fade(get_tree(), "res://ZukanScene.tscn"),
		"res://assets/icons/book-open.svg",
		Color("2dd4bf") # Teal
	)
	
	# --- EXTERIOR BUTTONS (Relocated to top_right_btn_hbox) ---
	_add_system_button(
		top_right_btn_hbox,
		"あそびかた",
		func():
			Global.is_tutorial_mode = true
			Global.game_mode = Constants.MODE_CPU
			Global.opponent_profiles = {
				"cpu_sato": {"name": "佐藤くん", "deviation": 51.5},
				"cpu_suzuki": {"name": "鈴木さん", "deviation": 48.0},
				"cpu_takahashi": {"name": "高橋くん", "deviation": 54.2}
			}
			if Global.player_name == "":
				Global.player_name = "プレイヤー"
			Global.change_scene_with_fade(get_tree(), "res://Main.tscn"),
		"res://assets/icons/help-circle.svg"
	)
	
	_add_system_button(
		top_right_btn_hbox,
		"音量・システム設定",
		func():
			SettingsModal.create_and_show(self),
		"res://assets/icons/settings.svg"
	)

func _add_menu_button(parent: Node, title_text: String, desc_text: String, tier: String, callback: Callable, icon_path: String = "", theme_color: Color = Color.WHITE) -> void:
	var height = 75
	var title_size = 18
	var desc_size = 12
	if tier == "large":
		height = 145
		title_size = 25
		desc_size = 15
	elif tier == "medium":
		height = 105
		title_size = 20
		desc_size = 13
	else: # small
		height = 80
		title_size = 16
		desc_size = 11
		
	# 外枠用のコンテナ (カラフルな装飾枠)
	var outer_panel = PanelContainer.new()
	outer_panel.custom_minimum_size = Vector2(0, height)
	outer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var outer_style = StyleBoxFlat.new()
	if theme_color != Color.WHITE:
		outer_style.bg_color = theme_color
	else:
		outer_style.bg_color = Color("d7ccc8") # デフォルトは落ち着いたブラウン
	outer_style.corner_radius_top_left = 9
	outer_style.corner_radius_top_right = 9
	outer_style.corner_radius_bottom_left = 9
	outer_style.corner_radius_bottom_right = 9
	outer_panel.add_theme_stylebox_override("panel", outer_style)
	
	parent.add_child(outer_panel)

	# マージンを設定して、外枠の色が枠線と影（立体）のように見えるようにする
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 3)
	margin_container.add_theme_constant_override("margin_right", 3)
	margin_container.add_theme_constant_override("margin_top", 3)
	margin_container.add_theme_constant_override("margin_bottom", 7 if tier == "large" else 5)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_panel.add_child(margin_container)

	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_container.add_child(btn)
	
	Global.apply_white_button_style(btn)
	
	# Layout Container for Icon + Text
	var layout_hbox = HBoxContainer.new()
	layout_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	layout_hbox.add_theme_constant_override("separation", 16)
	layout_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(layout_hbox)
	
	# Add spacing at the left
	var left_spacer = Control.new()
	left_spacer.custom_minimum_size = Vector2(4, 0)
	layout_hbox.add_child(left_spacer)
	
	# Icon setup
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon_rect = TextureRect.new()
		icon_rect.texture = load(icon_path)
		var icon_size = 48 if tier == "large" else (36 if tier == "medium" else 28)
		icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Modulate to ink color to match styling nicely
		icon_rect.modulate = DeskTheme.COLOR_INK
		
		layout_hbox.add_child(icon_rect)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_theme_constant_override("separation", 4)
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_hbox.add_child(inner_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title_text
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", title_size)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	inner_vbox.add_child(title_lbl)
	
	if desc_text != "":
		var desc_lbl = Label.new()
		desc_lbl.text = desc_text
		desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
		desc_lbl.add_theme_font_size_override("font_size", desc_size)
		desc_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.55))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner_vbox.add_child(desc_lbl)
	
	btn.pressed.connect(func():
		btn.release_focus()
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		var timer = get_tree().create_timer(0.08)
		timer.timeout.connect(callback)
	)

func _turn_page_anim(to_secondary: bool) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Play sound SE
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.play_se(audio.SE_CLICK)
	
	var turn_duration = 0.5
	
	# Set pivot to the spine (center binding of notebook layout)
	right_content_container.pivot_offset = Vector2(0, right_content_container.size.y / 2.0)
	left_content_container.pivot_offset = Vector2(left_content_container.size.x, left_content_container.size.y / 2.0)
	
	# Animate folding both pages simultaneously
	var fold_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fold_tween.tween_property(right_content_container, "scale:x", 0.0, turn_duration * 0.5)
	fold_tween.tween_property(right_content_container, "modulate:a", 0.0, turn_duration * 0.5)
	
	fold_tween.tween_property(left_content_container, "scale:x", 0.0, turn_duration * 0.5)
	fold_tween.tween_property(left_content_container, "modulate:a", 0.0, turn_duration * 0.5)
	
	await fold_tween.finished
	
	# Mid-flip swap of content
	is_secondary_mode = to_secondary
	
	# Right page contents switch
	study_menu_container.visible = not to_secondary
	secondary_menu_container.visible = to_secondary
	next_page_btn.visible = not to_secondary
	
	# Left page contents switch
	profile_info_container.visible = not to_secondary
	study_stats_container.visible = to_secondary
	prev_page_btn.visible = to_secondary
	
	# Notebook exterior buttons (always visible)
	pass
	
	# Update left page statistics with random progress visualization on flip (Removed as sticky note was deleted)
	
	# Animate unfolding the page
	var unfold_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	unfold_tween.tween_property(right_content_container, "scale:x", 1.0, turn_duration * 0.5)
	unfold_tween.tween_property(right_content_container, "modulate:a", 1.0, turn_duration * 0.5)
	
	unfold_tween.tween_property(left_content_container, "scale:x", 1.0, turn_duration * 0.5)
	unfold_tween.tween_property(left_content_container, "modulate:a", 1.0, turn_duration * 0.5)
	
	await unfold_tween.finished
	is_transitioning = false

func _setup_desk_items() -> void:
	# Empty placeholder since old floating blue note is removed
	pass

func _reload_all_data() -> void:
	# Update Profile Info
	var p_name = Global.player_name if Global.player_name != "" else "ゲストプレイヤー"
	name_lbl.text = p_name
	
	deviation_lbl.text = "偏差値: %.1f" % PlayerState.deviation_value
	
	# Update Coins
	coin_lbl.text = "%d コイン" % Global.coins
	
	# Update Daily Quests List
	_update_daily_quests()
		
	# Update Target Deviation (ラベル非表示化に伴い安全にガード)
	if is_instance_valid(target_dev_lbl):
		var current_dev = PlayerState.deviation_value
		var target_dev = snapped(current_dev + 2.0, 0.1)
		target_dev_lbl.text = "目標偏差値: %.1f" % target_dev
	
	# Update Deck Icons
	for child in deck_icons_grid.get_children():
		child.queue_free()
		
	var deck = Global.current_deck
	for i in range(1, 11):
		var item_id = deck.get(i, "")
		
		# VBoxContainer to group Slot Number + Icon Slot
		var slot_vbox = VBoxContainer.new()
		slot_vbox.add_theme_constant_override("separation", 2)
		slot_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Slot number label
		var num_lbl = Label.new()
		num_lbl.text = str(i)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_override("font", DeskTheme.get_font())
		num_lbl.add_theme_font_size_override("font_size", 16)
		num_lbl.add_theme_color_override("font_color", Color("7d6c5d"))
		slot_vbox.add_child(num_lbl)
		
		var icon_container = PanelContainer.new()
		icon_container.custom_minimum_size = Vector2(52, 52)
		icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		var c_style = StyleBoxFlat.new()
		c_style.bg_color = DeskTheme.COLOR_CRAFT
		c_style.corner_radius_top_left = 6
		c_style.corner_radius_top_right = 6
		c_style.corner_radius_bottom_left = 6
		c_style.corner_radius_bottom_right = 6
		c_style.border_width_left = 2
		c_style.border_width_right = 2
		c_style.border_width_top = 2
		c_style.border_width_bottom = 2
		c_style.border_color = Color(DeskTheme.COLOR_INK, 0.25)
		icon_container.add_theme_stylebox_override("panel", c_style)
		
		if item_id != "":
			var img_path = CardData.get_item_image_path(item_id)
			var item_name = ""
			var item_desc = ""
			var item_role = ""
			if CardData.ITEMS.has(item_id):
				var info = CardData.ITEMS[item_id]
				item_name = info.get("name", "")
				item_desc = info.get("description", "")
				item_role = CardData.get_role_name(info.get("role", ""))
			
			icon_container.tooltip_text = "%s\n【%s】\n%s" % [item_name, item_role, item_desc]
			
			if img_path != "":
				var img_rect = TextureRect.new()
				img_rect.texture = load(img_path)
				img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				img_rect.custom_minimum_size = Vector2(36, 36)
				var margin = MarginContainer.new()
				margin.add_theme_constant_override("margin_left", 6)
				margin.add_theme_constant_override("margin_right", 6)
				margin.add_theme_constant_override("margin_top", 6)
				margin.add_theme_constant_override("margin_bottom", 6)
				margin.add_child(img_rect)
				icon_container.add_child(margin)
		else:
			icon_container.tooltip_text = "未編成"
			var lbl = Label.new()
			lbl.text = "+"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_override("font", DeskTheme.get_font())
			lbl.add_theme_font_size_override("font_size", 20)
			lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.3))
			icon_container.add_child(lbl)
			
		slot_vbox.add_child(icon_container)
		deck_icons_grid.add_child(slot_vbox)
	
	_update_preset_buttons_highlight()

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
		profile_btn.text = "アカウント: %s" % display_name
	else:
		profile_btn.text = "オンラインログイン / 登録"

func _reflow_layout() -> void:
	var vp = get_viewport_rect().size
	
	if not is_instance_valid(notebook_container):
		return
		
	# アスペクト比を1.7647 (1500/850) に保つための計算
	var scale_x = vp.x / 1500.0
	var scale_y = vp.y / 850.0
	var final_scale = min(scale_x, scale_y)
	final_scale = clamp(final_scale, 0.4, 1.0)
	
	notebook_container.size = Vector2(1500, 850)
	notebook_container.pivot_offset = Vector2.ZERO
	notebook_container.scale = Vector2(final_scale, final_scale)
	
	var scaled_size = Vector2(1500, 850) * final_scale
	var nb_pos = (vp - scaled_size) / 2.0
	notebook_container.position = nb_pos
	
	# Layout index tab buttons on the side edges
	# next_page_btn (Next) goes on the right edge of the notebook (width 1500)
	if is_instance_valid(next_page_btn):
		next_page_btn.position = Vector2(1500 - 30, 850 / 2.0 - 50)
	# prev_page_btn (Prev) goes on the left edge of the notebook (left edge is 0)
	if is_instance_valid(prev_page_btn):
		prev_page_btn.position = Vector2(-70, 850 / 2.0 - 50)

func _on_quick_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	DeskTheme.animate_click(quick_start_btn, Vector2.ONE, 0.08)
	
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		is_transitioning = false
		if not has_node("/root/BackendManager"):
			return
		var bm = get_node("/root/BackendManager")
		if bm.auth_token == "" or bm.logged_in_uuid == "":
			ModeSelectionModal._show_login_warning(self, null, NATIONAL_NAMES, show_friend_lobby_selection_modal)
			return
			
		Global.game_mode = Constants.MODE_RANDOM
		ModeSelectionModal._show_matching_lobby(self, null, bm, NATIONAL_NAMES, show_friend_lobby_selection_modal)
	)

func show_mode_selection_modal() -> void:
	ModeSelectionModal.create_and_show(self, show_friend_lobby_selection_modal, NATIONAL_NAMES)

func show_friend_lobby_selection_modal() -> void:
	FriendLobbyModal.create_selection_modal(self)

func _add_system_button(parent: Node, tooltip_text: String, callback: Callable, icon_path: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(88, 88)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.tooltip_text = tooltip_text
	btn.focus_mode = Control.FOCUS_NONE
	
	# Round glass-morphism style Box
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	normal_style.draw_center = true
	normal_style.corner_radius_top_left = 44
	normal_style.corner_radius_top_right = 44
	normal_style.corner_radius_bottom_left = 44
	normal_style.corner_radius_bottom_right = 44
	normal_style.shadow_color = Color(0, 0, 0, 0.1)
	normal_style.shadow_size = 6
	normal_style.shadow_offset = Vector2(0, 3)
	normal_style.border_width_left = 3
	normal_style.border_width_top = 3
	normal_style.border_width_right = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = Color("e5e7eb")
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color("fff7ed") # warm peach glow
	hover_style.shadow_size = 9
	hover_style.shadow_offset = Vector2(0, 4)
	hover_style.border_color = Color("f97316") # orange border on hover
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color("ea580c") # dark orange press
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 1)
	pressed_style.border_color = Color("ea580c")
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.pivot_offset = Vector2(44, 44)
	
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var margin_container = MarginContainer.new()
		margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin_container.add_theme_constant_override("margin_left", 24)
		margin_container.add_theme_constant_override("margin_top", 24)
		margin_container.add_theme_constant_override("margin_right", 24)
		margin_container.add_theme_constant_override("margin_bottom", 24)
		margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(margin_container)
		
		var icon_rect = TextureRect.new()
		icon_rect.texture = load(icon_path)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_rect.modulate = Color("4b5563") # neutral gray
		margin_container.add_child(icon_rect)
		
		btn.mouse_entered.connect(func():
			var tween = btn.create_tween().set_parallel(true)
			tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.1)
			tween.tween_property(icon_rect, "modulate", Color("ea580c"), 0.1)
		)
		btn.mouse_exited.connect(func():
			var tween = btn.create_tween().set_parallel(true)
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
			tween.tween_property(icon_rect, "modulate", Color("4b5563"), 0.1)
		)
		btn.button_down.connect(func():
			icon_rect.modulate = Color("ffffff")
		)
		btn.button_up.connect(func():
			icon_rect.modulate = Color("ea580c")
		)
	
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _update_daily_quests() -> void:
	if not is_instance_valid(quest_vbox):
		return
		
	# 既存のラベルをクリア
	for child in quest_vbox.get_children():
		child.queue_free()
		
	# DailyMissionManager から今日のクエスト一覧を取得
	var missions = []
	if has_node("/root/DailyMissionManager"):
		missions = get_node("/root/DailyMissionManager").get_missions_display()
		
	for mission in missions:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		
		var status_lbl = Label.new()
		status_lbl.add_theme_font_override("font", DeskTheme.get_font())
		status_lbl.add_theme_font_size_override("font_size", 22)
		if mission["completed"]:
			status_lbl.text = "【済】"
			status_lbl.add_theme_color_override("font_color", Color("388e3c")) # 緑
		else:
			status_lbl.text = "【  】"
			status_lbl.add_theme_color_override("font_color", Color("757575")) # 灰色
		hbox.add_child(status_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
		desc_lbl.add_theme_font_size_override("font_size", 22)
		
		var progress_str = ""
		if not mission["completed"]:
			progress_str = " (%d/%d)" % [mission["progress"], mission["target"]]
			
		desc_lbl.text = "%s%s  (+%d🪙)" % [mission["desc"], progress_str, mission["reward"]]
		
		if mission["completed"]:
			desc_lbl.add_theme_color_override("font_color", Color("388e3c"))
		else:
			desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			
		hbox.add_child(desc_lbl)
		quest_vbox.add_child(hbox)

func _load_preset_on_title(preset_idx: int) -> void:
	var key = str(preset_idx)
	var preset = Global.deck_presets.get(key, {})
	if preset.is_empty():
		preset = {
			"1": "item_sticky_note",
			"2": "item_eraser",
			"3": "item_ruler",
			"4": "item_wordbook",
			"5": "item_mech_pencil",
			"6": "item_memo_cards",
			"7": "item_highlighter",
			"8": "item_blue_pen",
			"9": "item_cushion",
			"10": "item_memo_app"
		}
	Global.current_deck.clear()
	for k in preset.keys():
		Global.current_deck[int(k)] = preset[k]
	Global.selected_preset_idx = preset_idx
	Global.validate_current_deck()
	Global.save_game()
	_reload_all_data()
	
	var preset_name = Global.deck_preset_names.get(str(preset_idx), "P%d" % preset_idx)
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.play_se(audio.SE_CLICK)
	DeskTheme.show_toast(self, "%s を読み込みました！" % preset_name, 1.2, Color("#4a90e2"))

func _update_preset_buttons_highlight() -> void:
	for i in range(title_preset_buttons.size()):
		var btn = title_preset_buttons[i]
		var idx = i + 1
		btn.text = Global.deck_preset_names.get(str(idx), "P%d" % idx)
		if idx == Global.selected_preset_idx:
			var active_style = StyleBoxFlat.new()
			active_style.bg_color = Color("#eddcc9") # highlight paper color
			active_style.border_color = DeskTheme.COLOR_INK
			active_style.border_width_left = 2
			active_style.border_width_right = 2
			active_style.border_width_top = 2
			active_style.border_width_bottom = 2
			active_style.corner_radius_top_left = 6
			active_style.corner_radius_top_right = 6
			active_style.corner_radius_bottom_left = 6
			active_style.corner_radius_bottom_right = 6
			btn.add_theme_stylebox_override("normal", active_style)
			btn.add_theme_stylebox_override("hover", active_style)
			btn.add_theme_stylebox_override("pressed", active_style)
		else:
			Global.apply_white_button_style(btn)
