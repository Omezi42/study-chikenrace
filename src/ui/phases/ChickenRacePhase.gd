class_name ChickenRacePhase
extends PhaseBase

const CardVisual = preload("res://src/ui/CardVisual.gd")
const ItemEffects = preload("res://src/core/ItemEffects.gd")

# UI Controls
var actual_score_label: Label
var draw_history_container: HBoxContainer
var hand_container: Control
var burst_prob_label: Label
var led_indicator: ColorRect
var alert_banner: ColorRect
var alert_label: Label
var draw_btn: Button
var stop_btn: Button
var left_page: PanelContainer
var right_page: PanelContainer
var header_left: Label

# Deck count sticky note (Loop 11)
var deck_sticky: PanelContainer
var deck_count_lbl: Label
var deck_warning_lbl: Label

# Card explanation panel
var card_detail_box: PanelContainer
var detail_title_label: Label
var detail_role_label: Label
var detail_desc_label: Label

var active_effects_hbox: HBoxContainer

# Dynamic member tracking UI
var member_panels: Dictionary = {} # player_id -> PanelContainer
var member_labels: Dictionary = {} # player_id -> Label
var cpu_sim_states: Dictionary = {} # opp_id -> { "current_draws": int, "max_draws": int, "bursted": bool, "status": String }

# Active local variables
var engine: ChickenRaceEngine
var current_hand_cards: Array:
	get: return engine.hand_cards if engine else []
var has_bursted: bool:
	get: return engine.has_bursted if engine else false
	set(val):
		if engine: engine.has_bursted = val
var active_used_items: Array:
	get: return engine.active_used_items if engine else []
var active_peek_sticky: PanelContainer = null

enum RaceState {
	SETUP,
	IDLE,
	ANIMATING,
	CARD_SELECTION,
	BURSTED,
	STOPPED,
	COMPLETED
}
var current_state: RaceState = RaceState.SETUP:
	set(val):
		current_state = val
		_on_state_changed()

var is_animating: bool:
	get: return current_state == RaceState.ANIMATING
	set(val):
		if val:
			current_state = RaceState.ANIMATING
		else:
			if current_state == RaceState.ANIMATING:
				current_state = RaceState.IDLE

var is_selecting_card: bool:
	get: return current_state == RaceState.CARD_SELECTION
	set(val):
		if val:
			current_state = RaceState.CARD_SELECTION
		else:
			if current_state == RaceState.CARD_SELECTION:
				current_state = RaceState.IDLE

func _on_state_changed() -> void:
	if is_instance_valid(draw_btn) and is_instance_valid(stop_btn):
		match current_state:
			RaceState.IDLE:
				draw_btn.disabled = false
				stop_btn.disabled = false
			_:
				draw_btn.disabled = true
				stop_btn.disabled = true

var card_selection_mode_active: String = ""
var tutorial: ChickenRaceTutorial = null
var hovered_card_ui: Button = null
var hovered_card_tween: Tween = null
var speed_mult: float = 1.0
var hand_presenter: ChickenRaceHandPresenter
var cpu_presenter: ChickenRaceCPUPresenter
var smartphone_presenter: ChickenRaceSmartphonePresenter

func _on_setup(setup_data: Dictionary) -> void:
	speed_mult = 1.8 if Global.game_mode == Constants.MODE_OVERNIGHT else 1.0
	engine = ChickenRaceEngine.new()
	engine.setup(session)
	
	hand_presenter = ChickenRaceHandPresenter.new(self)
	cpu_presenter = ChickenRaceCPUPresenter.new(self)
	smartphone_presenter = ChickenRaceSmartphonePresenter.new(self)
	custom_minimum_size = Vector2(1500, 850)
	size = Vector2(1500, 850)
	current_state = RaceState.IDLE
	card_selection_mode_active = ""

	
	if session.current_hour == 1:
		session.player_deck.reset_for_next_day()
	
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if not bm.connection_lost.is_connected(_on_connection_lost):
			bm.connection_lost.connect(_on_connection_lost)
	
	# Layout setup (2 pages: Left and Right touching at separation 0)
	var main_hbox = HBoxContainer.new()
	main_hbox.custom_minimum_size = Vector2(1500, 850)
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 0)
	add_child(main_hbox)
	
	# LEFT PAGE (Notebook Stats)
	left_page = PanelContainer.new()
	left_page.custom_minimum_size = Vector2(650, 750)
	left_page.add_theme_stylebox_override("panel", DeskTheme.create_left_page_style())
	main_hbox.add_child(left_page)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 25)
	left_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_page.add_child(left_vbox)
	
	# Margin Container inside Left Page
	var left_margin = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 30)
	left_margin.add_theme_constant_override("margin_right", 30)
	left_margin.add_theme_constant_override("margin_top", 30)
	left_margin.add_theme_constant_override("margin_bottom", 30)
	left_vbox.add_child(left_margin)
	
	var left_inner_vbox = VBoxContainer.new()
	left_inner_vbox.add_theme_constant_override("separation", 20)
	left_margin.add_child(left_inner_vbox)
	
	header_left = Label.new()
	header_left.text = "自習ノート - %d時限目" % session.current_hour
	header_left.add_theme_font_override("font", DeskTheme.get_font())
	header_left.add_theme_font_size_override("font_size", 32)
	header_left.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	left_inner_vbox.add_child(header_left)
	
	# 同室のメンバーの名前一覧を表示する個別付箋風UI
	var room_members_hbox = HBoxContainer.new()
	room_members_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	room_members_hbox.add_theme_constant_override("separation", 12)
	left_inner_vbox.add_child(room_members_hbox)
	
	member_panels.clear()
	member_labels.clear()
	
	var members = []
	var player_disp_name = Global.player_name if Global.player_name != "" else "あなた"
	members.append({"id": "player", "name": player_disp_name, "icon": "[自分]", "color": Color("fff9c4"), "angle": 0.8}) # 淡い黄
	
	var colors = [Color("bbdefb"), Color("f8bbd0"), Color("c8e6c9")] # 淡い青、淡いピンク、淡い緑
	var angles = [-1.5, 1.2, -0.6]
	var color_idx = 0
	
	for opp_id in Global.opponent_profiles.keys():
		var opp = Global.opponent_profiles[opp_id]
		var opp_name = opp.get("name", "ライバル")
		var col = colors[color_idx % colors.size()]
		var ang = angles[color_idx % angles.size()]
		members.append({"id": opp_id, "name": opp_name, "icon": "[他]", "color": col, "angle": ang})
		color_idx += 1
		
	for member in members:
		var note_label = Label.new()
		note_label.text = member["icon"] + " " + member["name"] + "\n勉強: 0枚"
		note_label.add_theme_font_override("font", DeskTheme.get_font())
		note_label.add_theme_font_size_override("font_size", 14)
		note_label.add_theme_color_override("font_color", Color("263238"))
		
		var note_style = StyleBoxFlat.new()
		note_style.bg_color = member["color"]
		note_style.border_color = Color(DeskTheme.COLOR_INK, 0.15)
		note_style.border_width_left = 1
		note_style.border_width_right = 1
		note_style.border_width_top = 1
		note_style.border_width_bottom = 1
		note_style.corner_radius_top_left = 2
		note_style.corner_radius_top_right = 2
		note_style.corner_radius_bottom_left = 2
		note_style.corner_radius_bottom_right = 2
		note_style.content_margin_left = 8
		note_style.content_margin_right = 8
		note_style.content_margin_top = 4
		note_style.content_margin_bottom = 4
		note_style.shadow_color = Color(0, 0, 0, 0.08)
		note_style.shadow_size = 2
		note_style.shadow_offset = Vector2(1, 1.5)
		
		var note_panel = PanelContainer.new()
		note_panel.add_theme_stylebox_override("panel", note_style)
		note_panel.add_child(note_label)
		note_panel.rotation_degrees = member["angle"]
		note_panel.pivot_offset = Vector2(50, 15)
		room_members_hbox.add_child(note_panel)
		
		member_panels[member["id"]] = note_panel
		member_labels[member["id"]] = note_label
	
	var score_title = Label.new()
	score_title.text = "現在の勉強成果（実点）"
	score_title.add_theme_font_override("font", DeskTheme.get_font())
	score_title.add_theme_font_size_override("font_size", 22)
	score_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	left_inner_vbox.add_child(score_title)
	
	actual_score_label = Label.new()
	actual_score_label.text = "0点"
	actual_score_label.add_theme_font_override("font", DeskTheme.get_font())
	actual_score_label.add_theme_font_size_override("font_size", 84)
	actual_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	left_inner_vbox.add_child(actual_score_label)
	
	var history_title = Label.new()
	history_title.text = "勉強履歴"
	history_title.add_theme_font_override("font", DeskTheme.get_font())
	history_title.add_theme_font_size_override("font_size", 22)
	history_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	left_inner_vbox.add_child(history_title)
	
	draw_history_container = HBoxContainer.new()
	draw_history_container.add_theme_constant_override("separation", 12)
	left_inner_vbox.add_child(draw_history_container)
	
	# Card details panel statically placed on left page
	card_detail_box = PanelContainer.new()
	card_detail_box.custom_minimum_size = Vector2(400, 140)
	card_detail_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_detail_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_detail_box.visible = true
	
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = DeskTheme.COLOR_CRAFT # Use craft color for tooltip
	detail_style.border_color = Color(DeskTheme.COLOR_INK, 0.5)
	detail_style.border_width_left = 2
	detail_style.border_width_right = 2
	detail_style.border_width_top = 2
	detail_style.border_width_bottom = 2
	detail_style.corner_radius_top_left = 6
	detail_style.corner_radius_top_right = 6
	detail_style.corner_radius_bottom_left = 6
	detail_style.corner_radius_bottom_right = 6
	detail_style.content_margin_left = 15
	detail_style.content_margin_right = 15
	detail_style.content_margin_top = 10
	detail_style.content_margin_bottom = 10
	detail_style.shadow_color = Color(0, 0, 0, 0.2)
	detail_style.shadow_size = 4
	detail_style.shadow_offset = Vector2(2, 2)
	card_detail_box.add_theme_stylebox_override("panel", detail_style)
	
	# Add to left_inner_vbox to place it statically on the left page
	left_inner_vbox.add_child(card_detail_box)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 6)
	card_detail_box.add_child(detail_vbox)
	
	var detail_header_hbox = HBoxContainer.new()
	detail_header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	detail_header_hbox.add_theme_constant_override("separation", 10)
	detail_vbox.add_child(detail_header_hbox)
	
	detail_title_label = Label.new()
	detail_title_label.text = "カード説明"
	detail_title_label.add_theme_font_override("font", DeskTheme.get_font())
	detail_title_label.add_theme_font_size_override("font_size", 20)
	detail_title_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_header_hbox.add_child(detail_title_label)
	
	detail_role_label = Label.new()
	detail_role_label.text = ""
	detail_role_label.add_theme_font_override("font", DeskTheme.get_font())
	detail_role_label.add_theme_font_size_override("font_size", 16)
	detail_header_hbox.add_child(detail_role_label)
	
	detail_desc_label = Label.new()
	detail_desc_label.text = "カードをクリックすると効果の説明が表示されます。"
	detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_label.add_theme_font_override("font", DeskTheme.get_font())
	detail_desc_label.add_theme_font_size_override("font_size", 14)
	detail_desc_label.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	detail_desc_label.custom_minimum_size = Vector2(360, 50)
	detail_vbox.add_child(detail_desc_label)
	
	# RIGHT PAGE (Desk Self-study Area)
	right_page = PanelContainer.new()
	right_page.custom_minimum_size = Vector2(730, 750)
	right_page.add_theme_stylebox_override("panel", DeskTheme.create_right_page_style())
	main_hbox.add_child(right_page)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 25)
	right_page.add_child(right_vbox)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 30)
	right_margin.add_theme_constant_override("margin_right", 30)
	right_margin.add_theme_constant_override("margin_top", 30)
	right_margin.add_theme_constant_override("margin_bottom", 30)
	right_vbox.add_child(right_margin)
	
	var right_inner_vbox = VBoxContainer.new()
	right_inner_vbox.add_theme_constant_override("separation", 25)
	right_margin.add_child(right_inner_vbox)
	
	# LED Indicator & Alert Status
	var status_hbox = HBoxContainer.new()
	status_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	right_inner_vbox.add_child(status_hbox)
	
	led_indicator = ColorRect.new()
	led_indicator.custom_minimum_size = Vector2(24, 24)
	led_indicator.color = DeskTheme.COLOR_GREEN
	status_hbox.add_child(led_indicator)
	
	burst_prob_label = Label.new()
	burst_prob_label.text = "眠気：安全 (0%)"
	burst_prob_label.add_theme_font_override("font", DeskTheme.get_font())
	burst_prob_label.add_theme_font_size_override("font_size", 22)
	burst_prob_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	status_hbox.add_child(burst_prob_label)
	
	active_effects_hbox = HBoxContainer.new()
	active_effects_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	active_effects_hbox.add_theme_constant_override("separation", 8)
	right_inner_vbox.add_child(active_effects_hbox)
	
	# Cards hand container (dynamic placements)
	hand_container = Control.new()
	hand_container.custom_minimum_size = Vector2(650, 360)
	hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_inner_vbox.add_child(hand_container)
	
	# Alert Warning Banner (Vignette simulation)
	alert_banner = ColorRect.new()
	alert_banner.custom_minimum_size = Vector2(650, 50)
	alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.0) # Hidden initially
	alert_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_inner_vbox.add_child(alert_banner)
	
	alert_label = Label.new()
	alert_label.text = "寝落ち注意！"
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_override("font", DeskTheme.get_font())
	alert_label.add_theme_font_size_override("font_size", 20)
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_banner.add_child(alert_label)
	
	# Buttons HBox
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	right_inner_vbox.add_child(btn_hbox)
	
	draw_btn = Button.new()
	draw_btn.text = "勉強カードを引く"
	draw_btn.custom_minimum_size = Vector2(260, 65)
	draw_btn.pivot_offset = Vector2(130, 32.5)
	draw_btn.z_index = 2
	draw_btn.add_theme_font_override("font", DeskTheme.get_font())
	draw_btn.add_theme_font_size_override("font_size", 24)
	draw_btn.pressed.connect(_on_draw_pressed)
	draw_btn.mouse_entered.connect(func():
		_clear_hovered_card()
		DeskTheme.animate_hover(draw_btn, true, Vector2.ONE, 0.1)
	)
	draw_btn.mouse_exited.connect(func():
		DeskTheme.animate_hover(draw_btn, false, Vector2.ONE, 0.1)
	)
	DeskTheme.apply_white_button_style(draw_btn)
	btn_hbox.add_child(draw_btn)
	
	stop_btn = Button.new()
	stop_btn.text = "休憩する"
	stop_btn.custom_minimum_size = Vector2(260, 65)
	stop_btn.pivot_offset = Vector2(130, 32.5)
	stop_btn.z_index = 2
	stop_btn.add_theme_font_override("font", DeskTheme.get_font())
	stop_btn.add_theme_font_size_override("font_size", 24)
	stop_btn.pressed.connect(_on_stop_pressed)
	stop_btn.mouse_entered.connect(func():
		_clear_hovered_card()
		DeskTheme.animate_hover(stop_btn, true, Vector2.ONE, 0.1)
	)
	stop_btn.mouse_exited.connect(func():
		DeskTheme.animate_hover(stop_btn, false, Vector2.ONE, 0.1)
	)
	DeskTheme.apply_white_button_style(stop_btn)
	btn_hbox.add_child(stop_btn)
	
	# Notebook decoration
	DeskTheme.add_ruled_lines(left_page)
	DeskTheme.add_ruled_lines(right_page)
	DeskTheme.add_spiral_binding(main_hbox, 750.0)
	
	# Keep the notebook centered within the phase viewport.
	var viewport_size = get_viewport_rect().size
	main_hbox.pivot_offset = main_hbox.custom_minimum_size * 0.5
	# Center the notebook in the viewport
	main_hbox.position = viewport_size * 0.5 - main_hbox.pivot_offset
	
	# Deck count sticky note on the top-right corner of the right page (Loop 11)
	var right_free_control = Control.new()
	right_free_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_page.add_child(right_free_control)
	
	deck_sticky = PanelContainer.new()
	deck_sticky.custom_minimum_size = Vector2(100, 75)
	deck_sticky.size = Vector2(100, 75)
	deck_sticky.position = Vector2(580, 20)
	deck_sticky.rotation_degrees = 5.0
	deck_sticky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_free_control.add_child(deck_sticky)
	
	var sticky_style = DeskTheme.create_sticky_note_style("yellow")
	deck_sticky.add_theme_stylebox_override("panel", sticky_style)
	
	var sticky_vbox = VBoxContainer.new()
	sticky_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sticky_vbox.add_theme_constant_override("separation", 2)
	deck_sticky.add_child(sticky_vbox)
	
	var deck_title_lbl = Label.new()
	deck_title_lbl.text = "山札残り"
	deck_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deck_title_lbl.add_theme_font_size_override("font_size", 14)
	deck_title_lbl.add_theme_color_override("font_color", Color("37474f"))
	sticky_vbox.add_child(deck_title_lbl)
	
	deck_count_lbl = Label.new()
	deck_count_lbl.text = "0枚"
	deck_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_count_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deck_count_lbl.add_theme_font_size_override("font_size", 20)
	deck_count_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	sticky_vbox.add_child(deck_count_lbl)
	
	deck_warning_lbl = Label.new()
	deck_warning_lbl.text = "残少!!"
	deck_warning_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_warning_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deck_warning_lbl.add_theme_font_size_override("font_size", 12)
	deck_warning_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	deck_warning_lbl.visible = false
	sticky_vbox.add_child(deck_warning_lbl)
	
	# Check if player deck contains items to auto-apply at hour start
	apply_deck_startup_items()
	init_cpu_simulation_states()
	update_ui()
	_update_member_badge_ui("player")
	
	# Settings / Rules Button
	var opt_btn = Button.new()
	opt_btn.text = "設定/ルール"
	opt_btn.custom_minimum_size = Vector2(140, 45)
	opt_btn.add_theme_font_override("font", DeskTheme.get_font())
	opt_btn.add_theme_font_size_override("font_size", 18)
	opt_btn.pressed.connect(func():
		DeskTheme.animate_click(opt_btn, Vector2.ONE, 0.08)
		SettingsModal.create_and_show(self)
	)
	add_child(opt_btn)
	var opt_viewport_size = get_viewport_rect().size
	opt_btn.position = Vector2(max(opt_viewport_size.x - opt_btn.custom_minimum_size.x - 20.0, 0.0), 20)
	
	# 自動テスト実行中はチュートリアルをスキップ
	var is_test = false
	if OS.has_feature("web"):
		var test_val = JavaScriptBridge.eval("window.is_antigravity_test")
		if test_val != null and test_val:
			is_test = true
	if is_test:
		Global.is_tutorial_mode = false

	if Global.is_tutorial_mode and session.current_day == 1 and session.current_hour == 1:
		tutorial = ChickenRaceTutorial.new(self)
		tutorial.start()

func apply_deck_startup_items() -> void:
	engine.apply_deck_startup_items(Global.is_tutorial_mode)


func update_ui() -> void:
	smartphone_presenter.update_ui()

func perform_animated_draw(card: Dictionary, on_complete: Callable = Callable()) -> void:
	is_animating = true
	
	current_hand_cards.append(card)
	
	# Draw history visualization badge as a clickable Button
	var card_badge = Button.new()
	card_badge.custom_minimum_size = Vector2(48, 60)
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = DeskTheme.COLOR_CRAFT
	badge_style.border_color = DeskTheme.COLOR_INK
	badge_style.border_width_left = 1
	badge_style.border_width_right = 1
	badge_style.border_width_top = 1
	badge_style.border_width_bottom = 1
	card_badge.add_theme_stylebox_override("normal", badge_style)
	card_badge.add_theme_stylebox_override("hover", badge_style)
	card_badge.add_theme_stylebox_override("pressed", badge_style)
	card_badge.add_theme_stylebox_override("focus", badge_style)
	
	var badge_label = Label.new()
	badge_label.text = str(card["value"])
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_override("font", DeskTheme.get_font())
	badge_label.add_theme_font_size_override("font_size", 18)
	badge_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_badge.add_child(badge_label)
	
	card_badge.pressed.connect(func(): show_card_detail(card))
	card_badge.mouse_entered.connect(func(): show_card_detail(card))
	
	draw_history_container.add_child(card_badge)
	
	# Create upgraded visual card layout
	var card_ui = create_card_visual(card)
	var hand_idx = session.player_deck.hand.find(card)
	card_ui.set_meta("hand_index", hand_idx)
	card_ui.z_index = 20
	card_ui.position.y -= 180
	hand_container.add_child(card_ui)
	
	# Play draw sound
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_se(AudioManager.SE_DRAW)
		
	# Animate Card Flip
	card_ui.scale = Vector2.ONE
	var card_vbox = card_ui.get_vbox() if card_ui is CardVisual else card_ui.get_child(0)
	if card_vbox:
		card_vbox.visible = false
		
	DeskTheme.animate_card_flip(card_ui, 0.35 / speed_mult, func():
		if card_vbox:
			card_vbox.visible = true
	)
	
	# Re-arrange fan hand layout
	arrange_hand_fan()
	
	# Wait for animation to finish
	var timer = get_tree().create_timer(0.4 / speed_mult)
	timer.timeout.connect(func():
		is_animating = false
		if on_complete.is_valid():
			on_complete.call()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE:
			if is_instance_valid(draw_btn) and not draw_btn.disabled and not is_animating and not has_bursted:
				get_viewport().set_input_as_handled()
				_on_draw_pressed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_S:
			if is_instance_valid(stop_btn) and not stop_btn.disabled and not is_animating and not has_bursted:
				get_viewport().set_input_as_handled()
				_on_stop_pressed()

func _on_draw_pressed() -> void:
	if is_animating or has_bursted:
		return
		
	# Clear active peek sticky if exists on next draw
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
		
	is_animating = true
	draw_btn.disabled = true
	stop_btn.disabled = true
	
	# Perform deck draw
	var card = engine.draw_card()
	if card.is_empty():
		is_animating = false
		draw_btn.disabled = false
		stop_btn.disabled = false
		DeskTheme.show_toast(self, "山札が空になりました！休憩（ストップ）しましょう。")
		return
		
	# Advance CPU simulation states
	advance_cpu_simulations()
	_update_member_badge_ui("player")
		
	perform_animated_draw(card, func():
		activate_item_effect(card)
		show_card_detail(card)
		
		# Short delay to allow selection mode to trigger before evaluating standard burst
		var delay_timer = get_tree().create_timer(0.1 / speed_mult)
		delay_timer.timeout.connect(func():
			if is_selecting_card or has_bursted:
				return
				
			# Check burst (including energy drink side effect) via engine
			if engine.check_burst():
				trigger_burst_sequence()
			else:
				update_ui()
				if not has_bursted:
					if tutorial:
						tutorial.advance_step()
					else:
						draw_btn.disabled = false
						stop_btn.disabled = false
		)
	)


func create_card_visual(card: Dictionary) -> Button:
	# UIの生成ロジックは CardVisual コンポーネントに委譲する（UIコードの保守性向上）
	var card_ui = CardVisual.create(card)
	card_ui.pressed.connect(func(): _on_card_ui_pressed(card, card_ui))
	card_ui.mouse_entered.connect(func(): _on_card_ui_mouse_entered(card, card_ui))
	card_ui.mouse_exited.connect(func(): _on_card_ui_mouse_exited(card_ui))
	return card_ui

func activate_item_effect(card: Dictionary) -> void:
	var item_id = card.get("item_id", "")
	if item_id == "":
		return
		
	# Register active item
	if not item_id in active_used_items:
		active_used_items.append(item_id)
		
	var deck = session.player_deck
	
	# Strategyパターンを使用して個別の効果クラスを実行（OCP遵守）
	ItemEffects.execute_effect(item_id, self, deck, card)

func show_peek_sticky(peeked: Array) -> void:
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
		
	active_peek_sticky = PanelContainer.new()
	active_peek_sticky.custom_minimum_size = Vector2(300, 160)
	active_peek_sticky.pivot_offset = Vector2(150, 80)
	active_peek_sticky.rotation_degrees = randf_range(-3.0, 3.0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_HIGHLIGHTER # Yellow sticky note
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.15)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 3)
	active_peek_sticky.add_theme_stylebox_override("panel", style)
	
	add_child(active_peek_sticky) # Add directly to self (root Phase control)
	# Position at the right desk wood background area (outside the notebook)
	var sticky_viewport_size = get_viewport_rect().size
	active_peek_sticky.position = Vector2(
		max(sticky_viewport_size.x - active_peek_sticky.custom_minimum_size.x - 40.0, 0.0),
		max(sticky_viewport_size.y - active_peek_sticky.custom_minimum_size.y - 60.0, 0.0)
	)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	active_peek_sticky.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "のぞき見メモ"
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(list_vbox)
	
	var player_deck = session.player_deck
	var is_compass_active = player_deck.compass_active
	var hand_values = []
	for c in player_deck.hand:
		hand_values.append(c["value"])
		
	for idx in range(peeked.size()):
		var card = peeked[idx]
		var card_lbl = Label.new()
		var text_str = "・%d枚目： %s (%d 点)" % [idx + 1, card["name"], card["value"]]
		
		card_lbl.add_theme_font_override("font", DeskTheme.get_font())
		card_lbl.add_theme_font_size_override("font_size", 16)
		
		var is_overlap = is_compass_active and card["value"] in hand_values
		if is_overlap:
			text_str += " [被り]！"
			card_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
		else:
			card_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
			
		card_lbl.text = text_str
		list_vbox.add_child(card_lbl)
		
	# Disable mouse filter recursively so it never blocks clicks
	set_mouse_filter_recursive(active_peek_sticky, Control.MOUSE_FILTER_IGNORE)
	
	active_peek_sticky.scale = Vector2(0.5, 0.5)
	var tween = create_tween().bind_node(active_peek_sticky).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(active_peek_sticky, "scale", Vector2.ONE, 0.3 / speed_mult)

func repopulate_hand_visuals() -> void:
	hand_presenter.repopulate_hand_visuals()

func arrange_hand_fan() -> void:
	hand_presenter.arrange_hand_fan()

func trigger_burst_sequence() -> void:
	has_bursted = true
	draw_btn.disabled = true
	stop_btn.disabled = true
	
	fast_forward_cpus_to_end()
	_update_member_badge_ui("player")
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_se(AudioManager.SE_BURST)
	
	# Clear peek sticky on burst
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
	
	# Trigger Shake & red flash vignette
	DeskTheme.shake_control(self, 15.0, 0.5)
	led_indicator.color = DeskTheme.COLOR_TENSION
	burst_prob_label.text = "寝落ちしました！(バースト)"
	actual_score_label.text = "0点"
	
	# Find duplicate card values in hand to highlight them (UX Improvement)
	var value_counts = {}
	for c in session.player_deck.hand:
		var val = c.get("value", 0)
		if val != 0:
			value_counts[val] = value_counts.get(val, 0) + 1
			
	var duplicate_values = []
	for val in value_counts.keys():
		if value_counts[val] > 1:
			duplicate_values.append(val)
			
	# Highlight duplicate card visuals
	for child in hand_container.get_children():
		if child is CardVisual:
			var card_val = child.card_data.get("value", 0)
			if card_val in duplicate_values:
				var style = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
				if style:
					style.border_color = Color("ff1744") # Vivid red
					style.border_width_left = 6
					style.border_width_right = 6
					style.border_width_top = 6
					style.border_width_bottom = 6
					child.add_theme_stylebox_override("normal", style)
					child.add_theme_stylebox_override("hover", style)
					child.add_theme_stylebox_override("pressed", style)
					
				child.modulate = Color("ff8a80")
				
				var base_pos = child.position
				var tween = create_tween().bind_node(child).set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				var base_scale = child.scale
				tween.tween_property(child, "scale", base_scale * 1.15, 0.3 / speed_mult)
				tween.tween_property(child, "position:y", base_pos.y - 25.0, 0.25 / speed_mult)
	
	# 落書き「Zzz...」エフェクトの追加 (Loop 13)
	_spawn_zzz_scribbles()
	
	var timer = get_tree().create_timer(1.2 / speed_mult)
	timer.timeout.connect(func():
		var final_score = engine.calculate_hand_score()
		session.add_player_hour_result(session.player_deck.hand.size(), engine.active_used_items, true, final_score)
		
		finish_hour_and_transition(final_score, true)
	)


func _spawn_zzz_scribbles() -> void:
	# Spawn a single animated Zzz label on burst (Loop 13)
	var z_lbl = Label.new()
	z_lbl.text = "Zzz..."
	z_lbl.add_theme_font_override("font", DeskTheme.get_font())
	z_lbl.add_theme_font_size_override("font_size", 48)
	z_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	z_lbl.rotation_degrees = -8.0
	z_lbl.pivot_offset = Vector2(50, 20)
	z_lbl.scale = Vector2.ZERO
	
	if is_instance_valid(hand_container):
		hand_container.add_child(z_lbl)
		z_lbl.position = Vector2(250, 130)
		
		var tween = create_tween()
		tween.tween_property(z_lbl, "scale", Vector2(1.2, 1.2), 0.45 / speed_mult).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		var target_y = z_lbl.position.y - 60.0
		tween.parallel().tween_property(z_lbl, "position:y", target_y, 1.2 / speed_mult).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		tween.tween_property(z_lbl, "modulate:a", 0.0, 0.4 / speed_mult)
		tween.tween_callback(z_lbl.queue_free)

func _on_stop_pressed() -> void:
	if is_animating or has_bursted or stop_btn.disabled:
		return
		
	# 即座に入力をロックして二重入力を防ぐ
	is_animating = true
	draw_btn.disabled = true
	stop_btn.disabled = true
	
	# Clear peek sticky on stop
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
		
	# Click animation
	DeskTheme.animate_click(stop_btn, Vector2.ONE, 0.08)
	
	# Save points
	var final_score = engine.calculate_hand_score()
	session.add_player_hour_result(session.player_deck.hand.size(), engine.active_used_items, false, final_score)
	
	fast_forward_cpus_to_end()
	_update_member_badge_ui("player")
	
	finish_hour_and_transition(final_score, false)


func finish_hour_and_transition(final_score: int, is_burst: bool) -> void:
	show_hour_result_popup(final_score, is_burst)
	
	session.player_deck.reset_for_next_hour()
	
	if tutorial:
		tutorial.cleanup()
		
	# Clear active peek sticky if exists
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
		
	draw_btn.disabled = true
	stop_btn.disabled = true
	
	# Wait 1.6s then transition or reset seamlessly (1.2s -> 1.6s)
	var timer = get_tree().create_timer(1.6 / speed_mult)
	timer.timeout.connect(func():
		if not is_instance_valid(self) or not is_inside_tree():
			return
		if session.player_hours_history_today.size() >= session.max_hours_today:
			finish_phase({
				"actual_score": session.player_actual_score_today
			})
		else:
			session.current_hour += 1
			reset_phase_for_next_hour()
	)

func reset_phase_for_next_hour() -> void:
	is_animating = false
	engine.reset_for_hour()

	
	# Clear hand and history containers
	for child in hand_container.get_children():
		child.queue_free()
	for child in draw_history_container.get_children():
		child.queue_free()
		
	# Re-apply deck startup items
	apply_deck_startup_items()
	
	# Update UI elements
	update_ui()
	
	# Re-enable buttons
	draw_btn.disabled = false
	stop_btn.disabled = false
	
	# Hide alert banner
	alert_banner.color.a = 0.0
	
	DeskTheme.show_toast(self, "第 %d 時限目の勉強を開始します！" % session.current_hour)

func show_hour_result_popup(score: int, is_burst: bool) -> void:
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(320, 100)
	popup.pivot_offset = Vector2(160, 50)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("ffebee") if is_burst else Color("e8f5e9")
	style.border_color = DeskTheme.COLOR_TENSION if is_burst else DeskTheme.COLOR_GREEN
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 3)
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	popup.add_child(vbox)
	
	var main_lbl = Label.new()
	if is_burst:
		main_lbl.text = "寝落ちした！"
		main_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	else:
		main_lbl.text = "休憩（ストップ）"
		main_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	main_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_lbl.add_theme_font_override("font", DeskTheme.get_font())
	main_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(main_lbl)
	
	var score_lbl = Label.new()
	score_lbl.text = "確定得点: +%d点" % score
	score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_override("font", DeskTheme.get_font())
	score_lbl.add_theme_font_size_override("font_size", 26)
	vbox.add_child(score_lbl)
	
	add_child(popup)
	
	var viewport_size = get_viewport_rect().size
	popup.position = (viewport_size - popup.custom_minimum_size) / 2.0
	popup.scale = Vector2.ZERO
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.3 / speed_mult)
	
	var timer = get_tree().create_timer(1.2 / speed_mult)
	timer.timeout.connect(func():
		if is_instance_valid(popup):
			var fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fade_tween.tween_property(popup, "scale", Vector2(0.8, 0.8), 0.3 / speed_mult)
			fade_tween.tween_property(popup, "modulate:a", 0.0, 0.25 / speed_mult)
			fade_tween.chain().tween_callback(popup.queue_free)
	)

func show_card_detail(card: Dictionary) -> void:
	var item_id = card.get("item_id", "")
	var item_info = CardData.ITEMS.get(item_id, null)
	if item_info:
		detail_title_label.text = "【" + item_info["name"] + "】"
		detail_role_label.text = "系統: " + CardData.get_role_name(item_info["role"])
		detail_role_label.add_theme_color_override("font_color", CardData.get_role_color(item_info["role"]))
		detail_desc_label.text = item_info["description"]
	else:
		detail_title_label.text = "カード説明"
		detail_role_label.text = ""
		detail_desc_label.text = "カードをクリックすると効果の説明が表示されます。"

func set_mouse_filter_recursive(node: Node, filter: int) -> void:
	if node is Control:
		node.mouse_filter = filter
	for child in node.get_children():
		set_mouse_filter_recursive(child, filter)

# (Deleted _on_phone_toggle_pressed)
	
func update_active_effects_ui() -> void:
	if not active_effects_hbox:
		return
		
	for child in active_effects_hbox.get_children():
		child.queue_free()
		
	var deck = session.player_deck
	var active_list = []
	
	if deck.eraser_charges > 0:
		active_list.append({"name": "消しゴムチャージ", "color": DeskTheme.COLOR_ROLE_DEFENSE, "desc": "眠気回避残: %d回" % deck.eraser_charges})
		
	if deck.red_sheet_active:
		active_list.append({"name": "赤シート", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "被り時に自動破棄"})
		
	if deck.next_draw_bonus_points > 0:
		active_list.append({"name": "シャーペン", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "ドロー得点+3点残: %d枚" % deck.next_draw_bonus_points})
		
	if deck.highlighter_active:
		active_list.append({"name": "蛍光ペン", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "ドロー得点+1点（全カード）"})
		
	if deck.blue_pen_active:
		active_list.append({"name": "青ペン", "color": DeskTheme.COLOR_ROLE_PREP, "desc": "ドロー得点+2点（全カード）"})
		
	if deck.energy_drink_active:
		active_list.append({"name": "エナジードリンク", "color": DeskTheme.COLOR_TENSION, "desc": "得点2倍（ドロー時25%寝落ち）"})
		
	if deck.timer_active:
		active_list.append({"name": "タイマー", "color": DeskTheme.COLOR_ROLE_PREP, "desc": "眠気確率%を表示中"})
		
	if deck.compass_active:
		active_list.append({"name": "コンパス", "color": DeskTheme.COLOR_ROLE_PREP, "desc": "山札の被りカードを探知中"})
		
	if deck.amulet_active:
		active_list.append({"name": "お守り", "color": DeskTheme.COLOR_ROLE_DEFENSE, "desc": "寝落ち時に得点の50%キープ"})
		
	if deck.cram_school_print_active:
		active_list.append({"name": "塾プリント", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "時限の最終得点＋10点"})
		
	for eff in active_list:
		var badge = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = DeskTheme.COLOR_CRAFT
		style.border_color = eff["color"]
		style.border_width_left = 3
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		badge.add_theme_stylebox_override("panel", style)
		
		var lbl = Label.new()
		lbl.text = eff["name"]
		lbl.add_theme_font_override("font", DeskTheme.get_font())
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		badge.add_child(lbl)
		
		badge.tooltip_text = eff["desc"]
		active_effects_hbox.add_child(badge)
func start_card_selection(mode: String, guide_text: String) -> void:
	if session.player_deck.hand.size() == 0:
		update_ui()
		draw_btn.disabled = false
		stop_btn.disabled = false
		return
		
	is_selecting_card = true
	card_selection_mode_active = mode
	
	draw_btn.disabled = true
	stop_btn.disabled = true
	
	# アラートバナーに案内を表示する
	alert_banner.color = Color("fbc02d", 0.95) # Premium yellow
	alert_label.text = guide_text
	
	# 案内を強調表示するためのバナーアニメーション
	alert_banner.scale = Vector2(1.0, 0.2)
	var tween = create_tween().bind_node(alert_banner)
	tween.tween_property(alert_banner, "scale", Vector2.ONE, 0.2 / speed_mult).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 手札の見た目を再配置し、各カードのホバーエフェクトが効くようにする
	arrange_hand_fan()
	
	# 自動テスト実行中は自動で手札から最初のカードを選択する
	var is_test = false
	if OS.has_feature("web"):
		var test_val = JavaScriptBridge.eval("window.is_antigravity_test")
		if test_val != null and test_val:
			is_test = true
	if is_test:
		var t = get_tree().create_timer(0.8 / speed_mult)
		t.timeout.connect(func():
			if not is_instance_valid(self) or not is_inside_tree():
				return
			if not is_selecting_card:
				return
			if session.player_deck.hand.size() > 0:
				var hand_idx = 0
				var card = session.player_deck.hand[hand_idx]
				_on_card_selected_from_hand(hand_idx, card)
		)

func _on_card_ui_pressed(card: Dictionary, card_ui: Button) -> void:
	hand_presenter._on_card_ui_pressed(card, card_ui)

func _on_card_ui_mouse_entered(card: Dictionary, card_ui: Button) -> void:
	hand_presenter._on_card_ui_mouse_entered(card, card_ui)

func _on_card_ui_mouse_exited(card_ui: Button) -> void:
	hand_presenter._on_card_ui_mouse_exited(card_ui)

func _reset_hovered_card(card_ui: Button) -> void:
	hand_presenter._reset_hovered_card(card_ui)

func _clear_hovered_card() -> void:
	hand_presenter._clear_hovered_card()

func _on_card_selected_from_hand(hand_idx: int, card: Dictionary) -> void:
	is_selecting_card = false
	var mode = card_selection_mode_active
	card_selection_mode_active = ""
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_se(AudioManager.SE_PLACE)
	
	alert_banner.color.a = 0.0
	alert_label.text = ""
	
	var deck = session.player_deck
	if mode == "memo_cards":
		var success = deck.activate_memo_cards(hand_idx)
		if success:
			DeskTheme.show_toast(self, "暗記カードの効果！選択したカードを山札トップと交換した！")
	elif mode == "memo_app":
		var discarded = deck.activate_memo_app_discard(hand_idx)
		if not discarded.is_empty():
			DeskTheme.show_toast(self, "メモアプリの効果！【%s (%d点)】を手札から捨てた！" % [discarded["name"], discarded["value"]])
			
	repopulate_hand_visuals()
	
	# 保留していたバースト判定とUI更新を行う
	if deck.check_burst():
		trigger_burst_sequence()
	else:
		update_ui()
		if not has_bursted:
			draw_btn.disabled = false
			stop_btn.disabled = false

func _on_connection_lost() -> void:
	if not is_inside_tree():
		return
	draw_btn.disabled = true
	stop_btn.disabled = true
	ConnectionErrorModal.create_and_show(self)

func init_cpu_simulation_states() -> void:
	cpu_presenter.init_cpu_simulation_states()

func advance_cpu_simulations() -> void:
	cpu_presenter.advance_cpu_simulations()

func fast_forward_cpus_to_end() -> void:
	cpu_presenter.fast_forward_cpus_to_end()

func _update_member_badge_ui(member_id: String) -> void:
	cpu_presenter._update_member_badge_ui(member_id)
