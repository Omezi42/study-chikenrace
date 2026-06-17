class_name TitleScene
extends Control

# 状態管理
enum State { TITLE, HOME }
var current_state: State = State.TITLE
var current_page: int = 1
var is_transitioning: bool = false
var bgm_started: bool = false

# カスタムコンポーネント
var title_logo: TitleLogo
var player_id_card: PlayerIdCard
var mode_button_group: ModeButtonGroup
var deck_preview: DeckPreview

# UIノード参照
var bg_color: ColorRect
var bg_tex: TextureRect
var title_container: Control
var click_to_start_lbl: Label

var notebook_container: Control
var notebook: PanelContainer
var left_content_container: Control
var right_content_container: Control

# ページ別コンテナ
var left_p1_container: VBoxContainer
var left_p2_container: VBoxContainer
var right_p1_container: VBoxContainer
var right_p2_container: VBoxContainer

# ページめくりボタン
var next_page_btn: PageFlipButton
var prev_page_btn: PageFlipButton

# その他

var top_right_btn_hbox: HBoxContainer

const NATIONAL_NAMES = [
	"東大理三志望", "早慶合格マシーン", "徹夜明けの浪人生", "定期テストの神", 
	"赤点回避の守護神", "進研ゼミの覇者", "赤門くぐり隊", "偏差値70の天才",
	"単語帳と友達", "エナドリ中毒者", "短期集中のプロ", "授業中居眠りマン",
	"ガリ勉強眼鏡", "天才肌の帰国子女", "数学オリンピック選手"
]

func _ready() -> void:
	Global.is_tutorial_mode = false
	
	# 1. デスク背景
	bg_color = ColorRect.new()
	bg_color.color = DeskTheme.COLOR_MAHOGANY
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	bg_tex = TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/机の背景画像-ノート無し.png"):
		bg_tex.texture = load("res://assets/机の背景画像-ノート無し.png")
	bg_tex.modulate = Color(1.0, 1.0, 1.0, 0.85)
	add_child(bg_tex)
	
	# 2. ノートブックUIのセットアップ (最初は非表示)
	_setup_notebook()
	notebook_container.visible = false
	notebook_container.modulate.a = 0.0
	
	# 3. タイトル画面 (Splash) のセットアップ
	_setup_title_screen()
	
	# 4. データリロード
	_reload_all_data()
	
	# リサイズイベント接続
	_reflow_layout()
	
	# Listeners
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		bm.auth_completed.connect(func(success: bool, err: String):
			_reload_all_data()
		)

func _setup_title_screen() -> void:
	title_container = Control.new()
	title_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(title_container)
	
	# タイトルロゴ (初期位置は画面中央)
	title_logo = TitleLogo.new()
	title_logo.scale = Vector2(1.6, 1.6)
	title_container.add_child(title_logo)
	
	# 「画面をクリックしてスタート」案内
	click_to_start_lbl = Label.new()
	click_to_start_lbl.text = "画面をクリックしてスタート"
	click_to_start_lbl.add_theme_font_override("font", DeskTheme.get_font())
	click_to_start_lbl.add_theme_font_size_override("font_size", 24)
	click_to_start_lbl.add_theme_color_override("font_color", Color("5d4d3d"))
	click_to_start_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(click_to_start_lbl)
	
	# ガイドの点滅アニメーション
	var tween = create_tween().bind_node(click_to_start_lbl).set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(click_to_start_lbl, "modulate:a", 0.3, 0.8)
	tween.tween_property(click_to_start_lbl, "modulate:a", 1.0, 0.8)

func _setup_notebook() -> void:
	notebook_container = Control.new()
	notebook_container.custom_minimum_size = Vector2(1500, 850)
	notebook_container.size = Vector2(1500, 850)
	add_child(notebook_container)
	
	notebook = PanelContainer.new()
	notebook.custom_minimum_size = Vector2(1500, 850)
	notebook.size = Vector2(1500, 850)
	var book_style = StyleBoxEmpty.new()
	notebook.add_theme_stylebox_override("panel", book_style)
	notebook_container.add_child(notebook)
	
	# 右上のシステムメニュー
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
	system_menu_margin.add_child(top_right_btn_hbox)
	
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
	
	# ノート内部
	var notebook_hbox = HBoxContainer.new()
	notebook_hbox.add_theme_constant_override("separation", 0)
	notebook.add_child(notebook_hbox)
	
	# --- LEFT PAGE ---
	var left_page_container = PanelContainer.new()
	left_page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page_container.custom_minimum_size = Vector2(750, 850)
	left_page_container.add_theme_stylebox_override("panel", DeskTheme.create_left_page_style())
	notebook_hbox.add_child(left_page_container)
	DeskTheme.add_ruled_lines(left_page_container)
	
	left_content_container = Control.new()
	left_content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_page_container.add_child(left_content_container)
	
	# Left Page 1 (Main Hub)
	left_p1_container = VBoxContainer.new()
	left_p1_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_p1_container.offset_left = 60
	left_p1_container.offset_right = -60
	left_p1_container.offset_top = 45
	left_p1_container.offset_bottom = -45
	left_p1_container.add_theme_constant_override("separation", 24)
	left_content_container.add_child(left_p1_container)
	
	var logo_spacer = Control.new()
	logo_spacer.custom_minimum_size = Vector2(500, 80)
	left_p1_container.add_child(logo_spacer)
	
	player_id_card = PlayerIdCard.new()
	player_id_card.profile_pressed.connect(_on_profile_card_pressed)
	left_p1_container.add_child(player_id_card)
	
	# 左ページ下部にスペーサーを入れて学生証をより中央に配置
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_p1_container.add_child(bottom_spacer)
	
	# Left Page 2 (Study Stats)
	left_p2_container = VBoxContainer.new()
	left_p2_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_p2_container.offset_left = 60
	left_p2_container.offset_right = -60
	left_p2_container.offset_top = 55
	left_p2_container.offset_bottom = -55
	left_p2_container.add_theme_constant_override("separation", 20)
	left_p2_container.visible = false
	left_content_container.add_child(left_p2_container)
	
	_setup_stats_page(left_p2_container)
	
	# --- BINDING (Spine) ---
	DeskTheme.add_spiral_binding(notebook_hbox, 850.0)
	
	# --- RIGHT PAGE ---
	var right_page_container = PanelContainer.new()
	right_page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page_container.custom_minimum_size = Vector2(750, 850)
	right_page_container.add_theme_stylebox_override("panel", DeskTheme.create_right_page_style())
	notebook_hbox.add_child(right_page_container)
	DeskTheme.add_ruled_lines(right_page_container)
	
	right_content_container = Control.new()
	right_content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_page_container.add_child(right_content_container)
	
	# Right Page 1 (Deck & Main Action)
	right_p1_container = VBoxContainer.new()
	right_p1_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_p1_container.offset_left = 60
	right_p1_container.offset_right = -60
	right_p1_container.offset_top = 45
	right_p1_container.offset_bottom = -45
	right_p1_container.add_theme_constant_override("separation", 25)
	right_content_container.add_child(right_p1_container)
	
	# 対戦モード選択を右ページ上部に配置
	mode_button_group = ModeButtonGroup.new()
	mode_button_group.exam_pressed.connect(func(): show_mode_selection_modal())
	mode_button_group.friend_pressed.connect(func(): show_friend_lobby_selection_modal())
	mode_button_group.random_pressed.connect(func(): _on_quick_start_pressed())
	right_p1_container.add_child(mode_button_group)
	
	# デッキプレビュー（残りスペースを最大限使用）
	deck_preview = DeckPreview.new()
	deck_preview.preset_selected.connect(_load_preset_on_title)
	right_p1_container.add_child(deck_preview)
	
	# Right Page 2 (Submenus)
	right_p2_container = VBoxContainer.new()
	right_p2_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_p2_container.offset_left = 60
	right_p2_container.offset_right = -60
	right_p2_container.offset_top = 55
	right_p2_container.offset_bottom = -55
	right_p2_container.add_theme_constant_override("separation", 18)
	right_p2_container.visible = false
	right_content_container.add_child(right_p2_container)
	
	_setup_submenu_page(right_p2_container)
	
	# ページめくりボタン
	next_page_btn = PageFlipButton.new()
	next_page_btn.is_next = true
	next_page_btn.custom_minimum_size = Vector2(100, 100)
	next_page_btn.size = Vector2(100, 100)
	next_page_btn.pressed.connect(func(): _turn_page_anim(true))
	notebook_container.add_child(next_page_btn)
	
	prev_page_btn = PageFlipButton.new()
	prev_page_btn.is_next = false
	prev_page_btn.custom_minimum_size = Vector2(100, 100)
	prev_page_btn.size = Vector2(100, 100)
	prev_page_btn.visible = false
	prev_page_btn.pressed.connect(func(): _turn_page_anim(false))
	notebook_container.add_child(prev_page_btn)

func _setup_stats_page(parent: VBoxContainer) -> void:
	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 2)
	parent.add_child(title_vbox)
	
	var title = Label.new()
	title.text = "学習履歴と戦績"
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "— 今までの勉強とチキンレースの成果 —"
	subtitle.add_theme_font_override("font", DeskTheme.get_font())
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	title_vbox.add_child(subtitle)
	
	var paper = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("faf6f0")
	style.border_width_left = 4
	style.border_color = Color("8d6e63")
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	paper.add_theme_stylebox_override("panel", style)
	parent.add_child(paper)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 15)
	paper.add_child(stats_vbox)
	
	_add_stat_row(stats_vbox, "最高到達偏差値", "%.1f" % max(PlayerState.deviation_value, 60.0))
	_add_stat_row(stats_vbox, "これまでの試験回数", "%d 回" % (Global.coins / 50 + 3))
	_add_stat_row(stats_vbox, "総獲得コイン", "%d" % (Global.coins + 350))
	_add_stat_row(stats_vbox, "得意な戦法", "徹夜の一夜漬け")
	_add_stat_row(stats_vbox, "お気に入りアイテム", "青ペン")

func _add_stat_row(parent: VBoxContainer, item: String, val: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(hbox)
	
	var lbl_item = Label.new()
	lbl_item.text = "・ " + item
	lbl_item.add_theme_font_override("font", DeskTheme.get_font())
	lbl_item.add_theme_font_size_override("font_size", 20)
	lbl_item.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	lbl_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl_item)
	
	var lbl_val = Label.new()
	lbl_val.text = val
	lbl_val.add_theme_font_override("font", DeskTheme.get_font())
	lbl_val.add_theme_font_size_override("font_size", 22)
	lbl_val.add_theme_color_override("font_color", Color("c2185b"))
	hbox.add_child(lbl_val)

func _setup_submenu_page(parent: VBoxContainer) -> void:
	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 2)
	parent.add_child(title_vbox)
	
	var title = Label.new()
	title.text = "鞄整理と購買部"
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "— 文房具の調整と補充 —"
	subtitle.add_theme_font_override("font", DeskTheme.get_font())
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	title_vbox.add_child(subtitle)
	
	_add_menu_button(
		parent,
		"カバン整理 (デッキ編成)",
		"『単語帳』や『消しゴム』など便利なアイテムをカバンに詰め込もう！",
		"large",
		func():
			Global.change_scene_with_fade(get_tree(), "res://LoadoutScene.tscn"),
		"res://assets/icons/backpack.svg",
		Color("facc15")
	)
	
	_add_menu_button(
		parent,
		"購買部ガチャ",
		"貯めたコインを使って、新しい効果を持った便利な文房具アイテムをアンロック！",
		"medium",
		func():
			Global.change_scene_with_fade(get_tree(), "res://GachaScene.tscn"),
		"res://assets/icons/shopping-cart.svg",
		Color("c084fc")
	)
	
	_add_menu_button(
		parent,
		"アイテム図鑑",
		"解放した文房具の効果や、使い込んで獲得した星レベルを確認しよう！",
		"medium",
		func():
			Global.change_scene_with_fade(get_tree(), "res://ZukanScene.tscn"),
		"res://assets/icons/book-open.svg",
		Color("2dd4bf")
	)

func _input(event: InputEvent) -> void:
	if current_state == State.TITLE and (event is InputEventMouseButton or event is InputEventKey):
		if event.pressed:
			_transition_to_home()
			
	if not bgm_started and (event is InputEventMouseButton or event is InputEventKey):
		if event.pressed:
			start_bgm()

func _transition_to_home() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.play_se(audio.SE_CLICK)
		
	var fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(click_to_start_lbl, "modulate:a", 0.0, 0.4)
	
	var design_size = Vector2(1920, 1080)
	var screen_size = get_viewport_rect().size
	var scale_factor = clamp(min(screen_size.x / design_size.x, screen_size.y / design_size.y), 0.5, 1.25)
	
	var notebook_target_pos = (screen_size - Vector2(1500, 850) * scale_factor) / 2.0
	# left_p1_container内のlogo_spacerの中心位置
	var logo_target_gpos = notebook_target_pos + Vector2(60 + 250, 45 + 110) * scale_factor
	
	var logo_tween = create_tween().bind_node(title_logo).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	logo_tween.tween_property(title_logo, "global_position", logo_target_gpos - title_logo.pivot_offset * scale_factor, 0.5)
	logo_tween.tween_property(title_logo, "scale", Vector2(0.8 * scale_factor, 0.8 * scale_factor), 0.5)
	
	notebook_container.visible = true
	DeskTheme.animate_entrance(notebook_container, notebook_target_pos, Vector2(0, 400), 0.5)
	
	await logo_tween.finished
	
	title_logo.get_parent().remove_child(title_logo)
	left_p1_container.add_child(title_logo)
	left_p1_container.move_child(title_logo, 0)
	
	title_logo.scale = Vector2.ONE
	title_logo.position = Vector2.ZERO
	
	title_container.queue_free()
	
	current_state = State.HOME
	is_transitioning = false

func _turn_page_anim(to_secondary: bool) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.play_se(audio.SE_CLICK)
	
	var turn_duration = 0.5
	
	right_content_container.pivot_offset = Vector2(0, right_content_container.size.y / 2.0)
	left_content_container.pivot_offset = Vector2(left_content_container.size.x, left_content_container.size.y / 2.0)
	
	var fold_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fold_tween.tween_property(right_content_container, "scale:x", 0.0, turn_duration * 0.5)
	fold_tween.tween_property(right_content_container, "modulate:a", 0.0, turn_duration * 0.5)
	fold_tween.tween_property(left_content_container, "scale:x", 0.0, turn_duration * 0.5)
	fold_tween.tween_property(left_content_container, "modulate:a", 0.0, turn_duration * 0.5)
	
	await fold_tween.finished
	
	current_page = 2 if to_secondary else 1
	
	left_p1_container.visible = not to_secondary
	left_p2_container.visible = to_secondary
	right_p1_container.visible = not to_secondary
	right_p2_container.visible = to_secondary
	
	next_page_btn.visible = not to_secondary
	prev_page_btn.visible = to_secondary
	
	var unfold_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	unfold_tween.tween_property(right_content_container, "scale:x", 1.0, turn_duration * 0.5)
	unfold_tween.tween_property(right_content_container, "modulate:a", 1.0, turn_duration * 0.5)
	unfold_tween.tween_property(left_content_container, "scale:x", 1.0, turn_duration * 0.5)
	unfold_tween.tween_property(left_content_container, "modulate:a", 1.0, turn_duration * 0.5)
	
	await unfold_tween.finished
	is_transitioning = false

func _reload_all_data() -> void:
	var name_to_use = Global.player_name
	if name_to_use == "" and Global.logged_in_user_id != "":
		name_to_use = Global.logged_in_user_id
	if name_to_use == "":
		name_to_use = "名無しの学生"
		
	var deviation = PlayerState.deviation_value
	var coins = Global.coins
	var logged_in = Global.logged_in_user_id != ""
	
	player_id_card.update_data(name_to_use, deviation, coins, logged_in)
	deck_preview.update_deck(Global.current_deck, Global.selected_preset_idx, Global.deck_preset_names)

func _on_profile_card_pressed() -> void:
	if Global.logged_in_user_id != "":
		ProfileIdCardModal.create_and_show(self, player_id_card.profile_btn, func():
			_reload_all_data()
		)
	else:
		LoginModal.create_and_show(self, player_id_card.profile_btn, func():
			_reload_all_data()
		)

func start_bgm() -> void:
	if bgm_started:
		return
	bgm_started = true
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_MAIN)

func _reflow_layout() -> void:
	var screen_size = get_viewport_rect().size
	var design_size = Vector2(1920, 1080)
	var scale_factor = clamp(min(screen_size.x / design_size.x, screen_size.y / design_size.y), 0.5, 1.25)
	
	if current_state == State.TITLE:
		if is_instance_valid(title_logo):
			title_logo.scale = Vector2(2.5 * scale_factor, 2.5 * scale_factor)
			title_logo.pivot_offset = title_logo.custom_minimum_size / 2.0
			title_logo.position = screen_size / 2.0 - title_logo.pivot_offset
		if is_instance_valid(click_to_start_lbl):
			click_to_start_lbl.size = Vector2(screen_size.x, 50)
			click_to_start_lbl.position = Vector2(0, screen_size.y / 2.0 + 200)
	else:
		if is_instance_valid(notebook_container):
			notebook_container.scale = Vector2(scale_factor, scale_factor)
			notebook_container.pivot_offset = notebook_container.custom_minimum_size / 2.0
			notebook_container.position = (screen_size - notebook_container.size * scale_factor) / 2.0
			
			if is_instance_valid(next_page_btn):
				next_page_btn.position = Vector2(1500 - 30, 850 - 100 - 20)
			if is_instance_valid(prev_page_btn):
				prev_page_btn.position = Vector2(-70, 850 - 100 - 20)
				
	if is_instance_valid(top_right_btn_hbox):
		var margin_container = top_right_btn_hbox.get_parent()
		if is_instance_valid(margin_container):
			margin_container.position = Vector2(0, 0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reflow_layout()

func _on_quick_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if is_instance_valid(mode_button_group) and is_instance_valid(mode_button_group.random_btn):
		DeskTheme.animate_click(mode_button_group.random_btn, Vector2.ONE, 0.08)
	
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
	btn.custom_minimum_size = Vector2(64, 64)
	btn.tooltip_text = tooltip_text
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("faf6f0")
	normal_style.corner_radius_top_left = 32
	normal_style.corner_radius_top_right = 32
	normal_style.corner_radius_bottom_left = 32
	normal_style.corner_radius_bottom_right = 32
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 4
	normal_style.border_color = Color("d7ccc8")
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color("fff9c4")
	hover_style.border_color = DeskTheme.COLOR_TENSION
	
	var pressed_style = normal_style.duplicate()
	pressed_style.border_width_bottom = 2
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	if ResourceLoader.exists(icon_path):
		var tex = load(icon_path)
		btn.icon = tex
		btn.expand_icon = true
		
	btn.mouse_entered.connect(func(): DeskTheme.animate_hover(btn, true, Vector2.ONE, 0.1))
	btn.mouse_exited.connect(func(): DeskTheme.animate_hover(btn, false, Vector2.ONE, 0.1))
	btn.pressed.connect(func():
		btn.release_focus()
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		callback.call()
	)
	
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	parent.add_child(btn)
	return btn

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
	else:
		height = 80
		title_size = 16
		desc_size = 11
		
	var outer_panel = PanelContainer.new()
	outer_panel.custom_minimum_size = Vector2(0, height)
	outer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var outer_style = StyleBoxFlat.new()
	if theme_color != Color.WHITE:
		outer_style.bg_color = theme_color
	else:
		outer_style.bg_color = Color("d7ccc8")
	outer_style.corner_radius_top_left = 9
	outer_style.corner_radius_top_right = 9
	outer_style.corner_radius_bottom_left = 9
	outer_style.corner_radius_bottom_right = 9
	outer_panel.add_theme_stylebox_override("panel", outer_style)
	
	parent.add_child(outer_panel)

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
	
	var layout_hbox = HBoxContainer.new()
	layout_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	layout_hbox.add_theme_constant_override("separation", 16)
	layout_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(layout_hbox)
	
	var left_spacer = Control.new()
	left_spacer.custom_minimum_size = Vector2(4, 0)
	layout_hbox.add_child(left_spacer)
	
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon_rect = TextureRect.new()
		icon_rect.texture = load(icon_path)
		var icon_size = 48 if tier == "large" else (36 if tier == "medium" else 28)
		icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
		DeskTheme.animate_click(outer_panel, Vector2.ONE, 0.08)
		var timer = get_tree().create_timer(0.08)
		timer.timeout.connect(callback)
	)

	btn.mouse_entered.connect(func(): DeskTheme.animate_hover(outer_panel, true))
	btn.mouse_exited.connect(func(): DeskTheme.animate_hover(outer_panel, false))
	outer_panel.pivot_offset = outer_panel.custom_minimum_size / 2.0

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
