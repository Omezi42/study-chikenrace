# UI Elements
var quick_start_btn: Button
var research_note_btn: Button # This will now be the next page index tab button
var prev_page_btn: Button # Back to title page index tab button
var profile_btn: Button
var ranking_btn: Button

# Page containers for Right Page
var right_content_container: Control
var study_menu_container: Control
var research_menu_container: Control
var is_research_mode: bool = false
var quick_tween: Tween

# Notebook Inner Nodes for Reload
var name_lbl: Label
var grade_lbl: Label
var coin_lbl: Label
var deviation_lbl: Label
var rank_lbl: Label

# Progression UI Nodes
var exam_progress_lbl: Label
var exam_status_lbl: Label

# Overnight Info UI Nodes
var target_dev_lbl: Label
var recent_results_hbox: HBoxContainer

var bg_color: ColorRect
var bg_tex: TextureRect
var notebook_container: Control
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
	
	# Inner HBox to split into Left Page, Binding, and Right Page
	var notebook_hbox = HBoxContainer.new()
	notebook_hbox.add_theme_constant_override("separation", 0)
	notebook.add_child(notebook_hbox)
	
	# --- LEFT PAGE (Student Profile & Progress) ---
	var left_page_container = PanelContainer.new()
	left_page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page_container.custom_minimum_size = Vector2(750, 850)
	left_page_container.add_theme_stylebox_override("panel", DeskTheme.create_left_page_style())
	notebook_hbox.add_child(left_page_container)
	
	var left_page = MarginContainer.new()
	left_page.add_theme_constant_override("margin_left", 55)
	left_page.add_theme_constant_override("margin_right", 55)
	left_page.add_theme_constant_override("margin_top", 55)
	left_page.add_theme_constant_override("margin_bottom", 55)
	left_page_container.add_child(left_page)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 28)
	left_page.add_child(left_vbox)
	
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
	prof_hdr_lbl.text = "模試受験票 (学生証)"
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
	
	grade_lbl = Label.new()
	grade_lbl.add_theme_font_override("font", DeskTheme.get_font())
	grade_lbl.add_theme_font_size_override("font_size", 34)
	grade_lbl.add_theme_color_override("font_color", Color("6d5c4b"))
	info_vbox.add_child(grade_lbl)
	
	profile_btn = Button.new()
	_update_profile_btn_text()
	profile_btn.custom_minimum_size = Vector2(280, 56)
	profile_btn.add_theme_font_override("font", DeskTheme.get_font())
	profile_btn.add_theme_font_size_override("font_size", 22)
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
	
	rank_lbl = Label.new()
	rank_lbl.add_theme_font_override("font", DeskTheme.get_font())
	rank_lbl.add_theme_font_size_override("font_size", 25)
	rank_lbl.add_theme_color_override("font_color", Color("6d5c4b"))
	dev_rank_vbox.add_child(rank_lbl)
	
	ranking_btn = Button.new()
	ranking_btn.text = "ランキング"
	ranking_btn.custom_minimum_size = Vector2(160, 56)
	ranking_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ranking_btn.add_theme_font_override("font", DeskTheme.get_font())
	ranking_btn.add_theme_font_size_override("font_size", 22)
	Global.apply_white_button_style(ranking_btn)
	ranking_btn.pressed.connect(func():
		ranking_btn.release_focus()
		LeaderboardModal.create_and_show(self)
	)
	dev_rank_hbox.add_child(ranking_btn)
	
	stats_panel.add_child(stats_vbox)
	left_vbox.add_child(stats_panel)
	
	# Progression / Exam Gate UI (手書きノート風に)
	var prog_vbox = VBoxContainer.new()
	prog_vbox.add_theme_constant_override("separation", 9)
	
	var prog_title = Label.new()
	prog_title.text = "学級進級プロセス"
	prog_title.add_theme_font_override("font", DeskTheme.get_font())
	prog_title.add_theme_font_size_override("font_size", 28)
	prog_title.add_theme_color_override("font_color", Color("5d4d3d"))
	prog_vbox.add_child(prog_title)
	
	var prog_paper = PanelContainer.new()
	var pp_style = StyleBoxFlat.new()
	pp_style.bg_color = Color("faf6f0")
	pp_style.corner_radius_top_left = 9
	pp_style.corner_radius_top_right = 9
	pp_style.corner_radius_bottom_left = 9
	pp_style.corner_radius_bottom_right = 9
	pp_style.content_margin_left = 23
	pp_style.content_margin_right = 23
	pp_style.content_margin_top = 15
	pp_style.content_margin_bottom = 15
	prog_paper.add_theme_stylebox_override("panel", pp_style)
	prog_vbox.add_child(prog_paper)
	
	var inner_prog_vbox = VBoxContainer.new()
	inner_prog_vbox.add_theme_constant_override("separation", 6)
	prog_paper.add_child(inner_prog_vbox)
	
	exam_progress_lbl = Label.new()
	exam_progress_lbl.add_theme_font_override("font", DeskTheme.get_font())
	exam_progress_lbl.add_theme_font_size_override("font_size", 32)
	exam_progress_lbl.add_theme_color_override("font_color", Color("1b5e20")) # Dark green for progress
	inner_prog_vbox.add_child(exam_progress_lbl)
	
	exam_status_lbl = Label.new()
	exam_status_lbl.add_theme_font_override("font", DeskTheme.get_font())
	exam_status_lbl.add_theme_font_size_override("font_size", 23)
	exam_status_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	inner_prog_vbox.add_child(exam_status_lbl)
	
	left_vbox.add_child(prog_vbox)
	
	# Spine
	DeskTheme.add_spiral_binding(notebook_hbox, 850.0)
	DeskTheme.add_ruled_lines(left_page_container)
	
	# Index tab button to go BACK (left side of left page container)
	prev_page_btn = Button.new()
	prev_page_btn.text = "◀ タイトル"
	prev_page_btn.custom_minimum_size = Vector2(50, 160)
	prev_page_btn.size = Vector2(50, 160)
	prev_page_btn.add_theme_font_override("font", DeskTheme.get_font())
	prev_page_btn.add_theme_font_size_override("font_size", 20)
	prev_page_btn.visible = false # Hidden initially
	var tab_style_prev = DeskTheme.create_sticky_note_style("yellow")
	tab_style_prev.corner_radius_top_left = 12
	tab_style_prev.corner_radius_bottom_left = 12
	tab_style_prev.corner_radius_top_right = 0
	tab_style_prev.corner_radius_bottom_right = 0
	tab_style_prev.content_margin_left = 10
	tab_style_prev.content_margin_right = 10
	prev_page_btn.add_theme_stylebox_override("normal", tab_style_prev)
	prev_page_btn.add_theme_stylebox_override("hover", tab_style_prev.duplicate())
	prev_page_btn.add_theme_stylebox_override("pressed", tab_style_prev.duplicate())
	prev_page_btn.pressed.connect(func():
		_turn_page_anim(false)
	)
	left_page_container.add_child(prev_page_btn)
	
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
	
	# Header with coin
	var right_top_hbox = HBoxContainer.new()
	study_menu_container.add_child(right_top_hbox)
	
	var section_title = Label.new()
	section_title.text = "今夜のテスト対策"
	section_title.add_theme_font_override("font", DeskTheme.get_font())
	section_title.add_theme_font_size_override("font_size", 40)
	section_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	section_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_top_hbox.add_child(section_title)
	
	var coin_panel = PanelContainer.new()
	var coin_style = StyleBoxFlat.new()
	coin_style.bg_color = Color("fff9c4")
	coin_style.corner_radius_top_left = 23
	coin_style.corner_radius_top_right = 23
	coin_style.corner_radius_bottom_left = 23
	coin_style.corner_radius_bottom_right = 23
	coin_style.content_margin_left = 18
	coin_style.content_margin_right = 18
	coin_style.content_margin_top = 6
	coin_style.content_margin_bottom = 6
	coin_style.border_width_bottom = 3
	coin_style.border_color = Color("fbc02d")
	coin_panel.add_theme_stylebox_override("panel", coin_style)
	
	coin_lbl = Label.new()
	coin_lbl.add_theme_font_override("font", DeskTheme.get_font())
	coin_lbl.add_theme_font_size_override("font_size", 28)
	coin_lbl.add_theme_color_override("font_color", Color("f57c00"))
	coin_panel.add_child(coin_lbl)
	right_top_hbox.add_child(coin_panel)
	
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
	c_title.text = "📖 一夜漬けテスト"
	c_title.add_theme_font_override("font", DeskTheme.get_font())
	c_title.add_theme_font_size_override("font_size", 34)
	c_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_vbox.add_child(c_title)
	
	var c_desc = Label.new()
	c_desc.text = "制限時間: 3分\nカードを引いて勉強を進めるスピーディーなチキンレーステスト！順位に応じて偏差値が判定されます。"
	c_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c_desc.add_theme_font_override("font", DeskTheme.get_font())
	c_desc.add_theme_font_size_override("font_size", 22)
	c_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	card_vbox.add_child(c_desc)
	
	# Target Deviation / Rewards
	var details_hbox = HBoxContainer.new()
	details_hbox.add_theme_constant_override("separation", 40)
	card_vbox.add_child(details_hbox)
	
	target_dev_lbl = Label.new()
	target_dev_lbl.add_theme_font_override("font", DeskTheme.get_font())
	target_dev_lbl.add_theme_font_size_override("font_size", 24)
	target_dev_lbl.add_theme_color_override("font_color", Color("2e7d32"))
	details_hbox.add_child(target_dev_lbl)
	
	var reward_lbl = Label.new()
	reward_lbl.text = "成功報酬: 100 コイン"
	reward_lbl.add_theme_font_override("font", DeskTheme.get_font())
	reward_lbl.add_theme_font_size_override("font_size", 24)
	reward_lbl.add_theme_color_override("font_color", Color("e65100"))
	details_hbox.add_child(reward_lbl)
	
	# Recent Results inside this card
	var recent_vbox = VBoxContainer.new()
	recent_vbox.add_theme_constant_override("separation", 6)
	card_vbox.add_child(recent_vbox)
	
	var recent_title = Label.new()
	recent_title.text = "最近の成績履歴:"
	recent_title.add_theme_font_override("font", DeskTheme.get_font())
	recent_title.add_theme_font_size_override("font_size", 20)
	recent_title.add_theme_color_override("font_color", Color("7d6c5d"))
	recent_vbox.add_child(recent_title)
	
	recent_results_hbox = HBoxContainer.new()
	recent_results_hbox.add_theme_constant_override("separation", 12)
	recent_vbox.add_child(recent_results_hbox)
	
	# Start Button (Giant Red Button)
	var start_margin = MarginContainer.new()
	start_margin.add_theme_constant_override("margin_top", 8)
	
	quick_start_btn = Button.new()
	quick_start_btn.text = "勉強開始"
	quick_start_btn.custom_minimum_size = Vector2(470, 110)
	quick_start_btn.add_theme_font_override("font", DeskTheme.get_font())
	quick_start_btn.add_theme_font_size_override("font_size", 47)
	Global.apply_white_button_style(quick_start_btn)
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
	
	# --- 2. Research Note View ---
	research_menu_container = VBoxContainer.new()
	research_menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	research_menu_container.offset_left = 55
	research_menu_container.offset_right = -55
	research_menu_container.offset_top = 55
	research_menu_container.offset_bottom = -55
	research_menu_container.add_theme_constant_override("separation", 16)
	research_menu_container.visible = false # Hidden initially
	right_content_container.add_child(research_menu_container)
	
	_setup_research_menu_nodes()
	
	# Index tab button to go NEXT (right side of right page container)
	research_note_btn = Button.new()
	research_note_btn.text = "研究ノート ▶"
	research_note_btn.custom_minimum_size = Vector2(50, 160)
	research_note_btn.size = Vector2(50, 160)
	research_note_btn.add_theme_font_override("font", DeskTheme.get_font())
	research_note_btn.add_theme_font_size_override("font_size", 20)
	var tab_style_next = DeskTheme.create_sticky_note_style("blue")
	tab_style_next.corner_radius_top_left = 0
	tab_style_next.corner_radius_bottom_left = 0
	tab_style_next.corner_radius_top_right = 12
	tab_style_next.corner_radius_bottom_right = 12
	tab_style_next.content_margin_left = 10
	tab_style_next.content_margin_right = 10
	research_note_btn.add_theme_stylebox_override("normal", tab_style_next)
	research_note_btn.add_theme_stylebox_override("hover", tab_style_next.duplicate())
	research_note_btn.add_theme_stylebox_override("pressed", tab_style_next.duplicate())
	research_note_btn.pressed.connect(func():
		_turn_page_anim(true)
	)
	right_page_container.add_child(research_note_btn)

func _setup_research_menu_nodes() -> void:
	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 2)
	research_menu_container.add_child(title_vbox)
	
	var r_title = Label.new()
	r_title.text = "📖 研究ノート"
	r_title.add_theme_font_override("font", DeskTheme.get_font())
	r_title.add_theme_font_size_override("font_size", 34)
	r_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_vbox.add_child(r_title)
	
	var r_subtitle = Label.new()
	r_subtitle.text = "— 上級者向けメニュー —"
	r_subtitle.add_theme_font_override("font", DeskTheme.get_font())
	r_subtitle.add_theme_font_size_override("font_size", 16)
	r_subtitle.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	title_vbox.add_child(r_subtitle)
	
	# ScrollContainer for list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	research_menu_container.add_child(scroll)
	
	var r_buttons_vbox = VBoxContainer.new()
	r_buttons_vbox.add_theme_constant_override("separation", 10)
	r_buttons_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(r_buttons_vbox)
	
	_add_menu_button(
		r_buttons_vbox,
		"📚 5日間モード (じっくり対戦)",
		"3時限×5日間の授業を戦い抜き、ライバルの嘘を見破る心理戦モード",
		func():
			show_mode_selection_modal()
	)
	_add_menu_button(
		r_buttons_vbox,
		"🎒 カバン整理 (デッキ編成)",
		"手札をのぞき見る『単語帳』や、寝落ちを防ぐ『消しゴム』などデッキをカスタマイズ",
		func():
			Global.change_scene_with_fade(get_tree(), "res://LoadoutScene.tscn")
	)
	_add_menu_button(
		r_buttons_vbox,
		"🪙 購買部ガチャ",
		"コインを使って、新しい効果を持った便利な文房具アイテムをアンロック",
		func():
			Global.change_scene_with_fade(get_tree(), "res://GachaScene.tscn")
	)
	_add_menu_button(
		r_buttons_vbox,
		"📖 アイテム図鑑",
		"解放した文房具の効果や、使い込んで獲得した星レベル（育成状況）を確認",
		func():
			Global.change_scene_with_fade(get_tree(), "res://ZukanScene.tscn")
	)
	_add_menu_button(
		r_buttons_vbox,
		"❓ あそびかた (チュートリアル)",
		"佐藤くんが勉強チキンレースの基本から『ブラフとダウト』のコツまで解説する練習試合",
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
			Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
	)
	_add_menu_button(
		r_buttons_vbox,
		"⚙️ 音量・システム設定",
		"BGMやSEの音量調整、ミュート切り替え、手書きフォントの設定",
		func():
			SettingsModal.create_and_show(self)
	)

func _add_menu_button(parent: Node, title_text: String, desc_text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 68)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Global.apply_white_button_style(btn)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_theme_constant_override("separation", 2)
	inner_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title_text
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	inner_vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc_text
	desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.55))
	inner_vbox.add_child(desc_lbl)
	
	btn.pressed.connect(func():
		btn.release_focus()
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		var timer = get_tree().create_timer(0.08)
		timer.timeout.connect(callback)
	)
	
	parent.add_child(btn)

func _turn_page_anim(to_research: bool) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Play sound SE
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.play_se(audio.SE_CLICK)
	
	var turn_duration = 0.5
	
	# Set pivot to the spine (left side of right page container)
	right_content_container.pivot_offset = Vector2(0, right_content_container.size.y / 2.0)
	
	# Animate folding the page
	var fold_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fold_tween.tween_property(right_content_container, "scale:x", 0.0, turn_duration * 0.5)
	fold_tween.tween_property(right_content_container, "modulate:a", 0.0, turn_duration * 0.5)
	
	# Suffix-like slight rotation during fold to resemble actual page turn 
	fold_tween.tween_property(right_content_container, "skew:y", 0.05 if to_research else -0.05, turn_duration * 0.5)
	
	await fold_tween.finished
	
	# Mid-flip swap of content
	is_research_mode = to_research
	study_menu_container.visible = not to_research
	research_menu_container.visible = to_research
	research_note_btn.visible = not to_research
	prev_page_btn.visible = to_research
	
	# Animate unfolding the page
	var unfold_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	unfold_tween.tween_property(right_content_container, "scale:x", 1.0, turn_duration * 0.5)
	unfold_tween.tween_property(right_content_container, "modulate:a", 1.0, turn_duration * 0.5)
	unfold_tween.tween_property(right_content_container, "skew:y", 0.0, turn_duration * 0.5)
	
	await unfold_tween.finished
	is_transitioning = false

func _setup_desk_items() -> void:
	# Empty placeholder since old floating blue note is removed
	pass

func _reload_all_data() -> void:
	# Update Profile Info
	var p_name = Global.player_name if Global.player_name != "" else "ゲストプレイヤー"
	name_lbl.text = p_name
	
	var g_stage = clampi(PlayerState.grade_stage, 0, PlayerState.GRADE_STAGE_NAMES.size() - 1)
	grade_lbl.text = "学年: %s" % PlayerState.GRADE_STAGE_NAMES[g_stage]
	deviation_lbl.text = "偏差値: %.1f" % PlayerState.deviation_value
	rank_lbl.text = "学年順位: %d 位 (500人中)" % PlayerState.get_grade_rank()
	
	# Update Coins
	coin_lbl.text = "🪙%d" % Global.coins
	
	# Update Progression / Exam System
	var req_wins = PlayerState.get_current_required_wins()
	var wins = PlayerState.exam_wins_progress
	var exam_name = PlayerState.EXAM_TARGET_NAMES[clampi(PlayerState.grade_stage, 0, PlayerState.EXAM_TARGET_NAMES.size() - 1)]
	
	var progress_bar = ""
	for idx in range(req_wins):
		if idx < wins:
			progress_bar += "■"
		else:
			progress_bar += "□"
	
	exam_progress_lbl.text = progress_bar
	
	var remains = max(0, req_wins - wins)
	if remains == 0:
		exam_status_lbl.text = "★ 次は %s （試験イベント戦）！" % exam_name
		exam_progress_lbl.add_theme_color_override("font_color", Color("c62828")) # Alert red
	else:
		exam_status_lbl.text = "あと %d 勝で %s" % [remains, exam_name]
		exam_progress_lbl.add_theme_color_override("font_color", Color("1b5e20")) # standard green
		
	# Update Target Deviation
	var current_dev = PlayerState.deviation_value
	var target_dev = snapped(current_dev + 2.0, 0.1)
	target_dev_lbl.text = "目標偏差値: %.1f" % target_dev
	
	# Update Recent Results Badges
	for child in recent_results_hbox.get_children():
		child.queue_free()
		
	var results = PlayerState.recent_results
	for i in range(min(5, results.size())):
		var res_str = results[i]
		var badge = PanelContainer.new()
		badge.custom_minimum_size = Vector2(62, 62)
		
		var b_style = StyleBoxFlat.new()
		b_style.corner_radius_top_left = 31
		b_style.corner_radius_top_right = 31
		b_style.corner_radius_bottom_left = 31
		b_style.corner_radius_bottom_right = 31
		b_style.shadow_color = Color(0, 0, 0, 0.15)
		b_style.shadow_size = 3
		
		if res_str == "WIN":
			b_style.bg_color = Color("e53935") # win
		else:
			b_style.bg_color = Color("78909c") # lose
			
		badge.add_theme_stylebox_override("panel", b_style)
		
		var lbl = Label.new()
		lbl.text = res_str
		lbl.add_theme_font_override("font", DeskTheme.get_font())
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.add_child(lbl)
		
		recent_results_hbox.add_child(badge)

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
	# research_note_btn (Next) goes on the right edge of the right page
	if is_instance_valid(research_note_btn):
		research_note_btn.position = Vector2(750 - 5, 850 / 2.0 - 80) # overlapping slightly onto the border
	# prev_page_btn (Prev) goes on the left edge of the left page
	if is_instance_valid(prev_page_btn):
		prev_page_btn.position = Vector2(-50 + 5, 850 / 2.0 - 80)

func _on_quick_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	DeskTheme.animate_click(quick_start_btn, Vector2.ONE, 0.08)
	
	if Global.player_name == "":
		Global.player_name = "プレイヤー"
		
	# Check if this next match is an Exam match
	if PlayerState.is_next_match_exam():
		# Special event match: set a global flag so result screen triggers stage up
		Global.set("is_exam_match", true)
	else:
		Global.set("is_exam_match", false)
		
	Global.game_mode = Constants.MODE_OVERNIGHT
	Global.opponent_profiles = {
		"cpu_sato": {"name": "佐藤くん", "deviation": clamp(PlayerState.deviation_value + randf_range(-2, 2), 35, 85)},
		"cpu_suzuki": {"name": "鈴木さん", "deviation": clamp(PlayerState.deviation_value + randf_range(-3, 1), 35, 85)},
		"cpu_takahashi": {"name": "高橋くん", "deviation": clamp(PlayerState.deviation_value + randf_range(-1, 3), 35, 85)}
	}
	
	if not PlayerState.is_tutorial_completed:
		Global.is_tutorial_mode = true
	else:
		Global.is_tutorial_mode = false
	
	# Page flip animation
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

func show_mode_selection_modal() -> void:
	ModeSelectionModal.create_and_show(self, show_friend_lobby_selection_modal, NATIONAL_NAMES)

func show_friend_lobby_selection_modal() -> void:
	FriendLobbyModal.create_selection_modal(self)
