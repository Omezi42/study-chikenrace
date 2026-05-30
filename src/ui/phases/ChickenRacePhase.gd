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

# Card explanation panel
var card_detail_box: PanelContainer
var detail_title_label: Label
var detail_role_label: Label
var detail_desc_label: Label

# Standings phone side-panel
var standing_phone: Control
var phone_toggle_btn: Button
var is_phone_open: bool = false
var active_effects_hbox: HBoxContainer

# Active local variables
var current_hand_cards: Array[Dictionary] = []
var is_animating: bool = false
var has_bursted: bool = false
var active_used_items: Array[String] = []
var active_peek_sticky: PanelContainer = null
var is_selecting_card: bool = false
var card_selection_mode_active: String = ""
var tutorial_step: int = 0
var tutorial_dialog_node: PanelContainer = null
var hovered_card_ui: Button = null
var hovered_card_tween: Tween = null

func _on_setup(setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(1500, 850)
	size = Vector2(1500, 850)
	active_used_items.clear()
	has_bursted = false
	is_animating = false
	current_hand_cards.clear()
	is_phone_open = false
	is_selecting_card = false
	card_selection_mode_active = ""
	
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
	
	var header_left = Label.new()
	header_left.text = "自習ノート - %d時限目" % session.current_hour
	header_left.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	header_left.add_theme_font_size_override("font_size", 32)
	header_left.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	left_inner_vbox.add_child(header_left)
	
	var score_title = Label.new()
	score_title.text = "現在の勉強成果（実点）"
	score_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	score_title.add_theme_font_size_override("font_size", 22)
	score_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	left_inner_vbox.add_child(score_title)
	
	actual_score_label = Label.new()
	actual_score_label.text = "0点"
	actual_score_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	actual_score_label.add_theme_font_size_override("font_size", 84)
	actual_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	left_inner_vbox.add_child(actual_score_label)
	
	var history_title = Label.new()
	history_title.text = "勉強履歴"
	history_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	history_title.add_theme_font_size_override("font_size", 22)
	history_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	left_inner_vbox.add_child(history_title)
	
	draw_history_container = HBoxContainer.new()
	draw_history_container.add_theme_constant_override("separation", 12)
	left_inner_vbox.add_child(draw_history_container)
	
	# Card details panel as floating tooltip
	card_detail_box = PanelContainer.new()
	card_detail_box.custom_minimum_size = Vector2(400, 140)
	card_detail_box.z_index = 100 # Ensure it draws on top
	card_detail_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_detail_box.visible = false
	
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
	
	# Add to self instead of left_inner_vbox
	add_child(card_detail_box)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 6)
	card_detail_box.add_child(detail_vbox)
	
	var detail_header_hbox = HBoxContainer.new()
	detail_header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	detail_header_hbox.add_theme_constant_override("separation", 10)
	detail_vbox.add_child(detail_header_hbox)
	
	detail_title_label = Label.new()
	detail_title_label.text = "カード説明"
	detail_title_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	detail_title_label.add_theme_font_size_override("font_size", 20)
	detail_title_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_header_hbox.add_child(detail_title_label)
	
	detail_role_label = Label.new()
	detail_role_label.text = ""
	detail_role_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	detail_role_label.add_theme_font_size_override("font_size", 16)
	detail_header_hbox.add_child(detail_role_label)
	
	detail_desc_label = Label.new()
	detail_desc_label.text = "カードをクリックすると効果の説明が表示されます。"
	detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
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
	burst_prob_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
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
	right_inner_vbox.add_child(hand_container)
	
	# Alert Warning Banner (Vignette simulation)
	alert_banner = ColorRect.new()
	alert_banner.custom_minimum_size = Vector2(650, 50)
	alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.0) # Hidden initially
	right_inner_vbox.add_child(alert_banner)
	
	alert_label = Label.new()
	alert_label.text = "寝落ち注意！"
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	alert_label.add_theme_font_size_override("font_size", 20)
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alert_banner.add_child(alert_label)
	
	# Buttons HBox
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	right_inner_vbox.add_child(btn_hbox)
	
	draw_btn = Button.new()
	draw_btn.text = "勉強カードを引く"
	draw_btn.custom_minimum_size = Vector2(260, 65)
	draw_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	draw_btn.add_theme_font_size_override("font_size", 24)
	draw_btn.pressed.connect(_on_draw_pressed)
	draw_btn.mouse_entered.connect(_clear_hovered_card)
	btn_hbox.add_child(draw_btn)
	
	stop_btn = Button.new()
	stop_btn.text = "休憩する"
	stop_btn.custom_minimum_size = Vector2(260, 65)
	stop_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	stop_btn.add_theme_font_size_override("font_size", 24)
	stop_btn.pressed.connect(_on_stop_pressed)
	stop_btn.mouse_entered.connect(_clear_hovered_card)
	btn_hbox.add_child(stop_btn)
	
	# Notebook decoration
	DeskTheme.add_ruled_lines(left_page)
	DeskTheme.add_ruled_lines(right_page)
	DeskTheme.add_spiral_binding(main_hbox, 750.0)
	
	# Keep the notebook centered within the phase viewport.
	var viewport_size = get_viewport_rect().size
	main_hbox.pivot_offset = main_hbox.custom_minimum_size * 0.5
	main_hbox.position = viewport_size * 0.5 - main_hbox.pivot_offset

	# Standings phone UI setup: sliding smartphone Control container
	standing_phone = Control.new()
	standing_phone.custom_minimum_size = Vector2(300, 520)
	standing_phone.size = Vector2(300, 520)
	standing_phone.clip_contents = false # Allow toggle button outside bounds
	add_child(standing_phone)
	standing_phone.position = Vector2(-260, max(viewport_size.y * 0.175, 120.0))
	
	var phone_style = StyleBoxFlat.new()
	phone_style.bg_color = DeskTheme.COLOR_INK
	phone_style.border_color = Color("37474f")
	phone_style.border_width_left = 8
	phone_style.border_width_right = 8
	phone_style.border_width_top = 16
	phone_style.border_width_bottom = 16
	phone_style.corner_radius_top_left = 18
	phone_style.corner_radius_top_right = 18
	phone_style.corner_radius_bottom_left = 18
	phone_style.corner_radius_bottom_right = 18
	phone_style.shadow_color = Color(0, 0, 0, 0.25)
	phone_style.shadow_size = 10
	phone_style.shadow_offset = Vector2(3, 3)
	
	var phone_body = PanelContainer.new()
	phone_body.custom_minimum_size = Vector2(260, 520)
	phone_body.size = Vector2(260, 520)
	phone_body.position = Vector2.ZERO
	phone_body.add_theme_stylebox_override("panel", phone_style)
	standing_phone.add_child(phone_body)
	
	# Standings phone toggle button: tab positioned on the right edge of phone body
	phone_toggle_btn = Button.new()
	phone_toggle_btn.text = "📱\n順\n位\n表"
	phone_toggle_btn.custom_minimum_size = Vector2(40, 120)
	phone_toggle_btn.position = Vector2(260, 180)
	phone_toggle_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	phone_toggle_btn.add_theme_font_size_override("font_size", 16)
	phone_toggle_btn.pressed.connect(_on_phone_toggle_pressed)
	
	var tab_style = StyleBoxFlat.new()
	tab_style.bg_color = DeskTheme.COLOR_INK
	tab_style.corner_radius_top_left = 8
	tab_style.corner_radius_bottom_left = 8
	tab_style.corner_radius_top_right = 0
	tab_style.corner_radius_bottom_right = 0
	phone_toggle_btn.add_theme_stylebox_override("normal", tab_style)
	phone_toggle_btn.add_theme_stylebox_override("hover", tab_style)
	phone_toggle_btn.add_theme_stylebox_override("pressed", tab_style)
	phone_toggle_btn.add_theme_stylebox_override("focus", tab_style)
	standing_phone.add_child(phone_toggle_btn)
	
	var phone_vbox = VBoxContainer.new()
	phone_vbox.add_theme_constant_override("separation", 10)
	phone_body.add_child(phone_vbox)
	
	var phone_header = Label.new()
	phone_header.text = "チキスタ - 暫定順位"
	phone_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phone_header.add_theme_font_size_override("font_size", 16)
	phone_header.add_theme_color_override("font_color", Color.WHITE)
	phone_vbox.add_child(phone_header)
	
	var phone_margin = MarginContainer.new()
	phone_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone_margin.add_theme_constant_override("margin_left", 12)
	phone_margin.add_theme_constant_override("margin_right", 12)
	phone_margin.add_theme_constant_override("margin_top", 10)
	phone_margin.add_theme_constant_override("margin_bottom", 10)
	phone_vbox.add_child(phone_margin)
	
	var standings_list = VBoxContainer.new()
	standings_list.name = "StandingsList"
	standings_list.add_theme_constant_override("separation", 10)
	phone_margin.add_child(standings_list)
	
	update_yesterday_standings_ui()
	
	# Check if player deck contains items to auto-apply at hour start
	apply_deck_startup_items()
	update_ui()
	
	# ⚙️ Settings / Rules Button
	var opt_btn = Button.new()
	opt_btn.text = "⚙️ 設定/ルール"
	opt_btn.custom_minimum_size = Vector2(140, 45)
	opt_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	opt_btn.add_theme_font_size_override("font_size", 18)
	opt_btn.pressed.connect(func():
		DeskTheme.animate_click(opt_btn, Vector2.ONE, 0.08)
		DeskTheme.show_settings(self)
	)
	add_child(opt_btn)
	var opt_viewport_size = get_viewport_rect().size
	opt_btn.position = Vector2(max(opt_viewport_size.x - opt_btn.custom_minimum_size.x - 20.0, 0.0), 20)
	
	if Global.is_tutorial_mode and session.current_day == 1 and session.current_hour == 1:
		tutorial_step = 0
		stop_btn.disabled = true # Cannot stop yet
		draw_btn.disabled = true # Must read description first
		tutorial_dialog_node = show_tutorial_dialog(
			"自習フェーズ（勉強チキンレース）へようこそ！\n\nここでは山札からカードを引き、勉強成果（実点）を高めます。まずは、点数を大きく伸ばす『教科』と『コンボ』の仕様を学びましょう！",
			Vector2(get_viewport_rect().size.x * 0.30, get_viewport_rect().size.y * 0.12),
			func():
				tutorial_dialog_node = show_tutorial_dialog(
					"【教科とコンボボーナス】\nカードには5つの教科（国・英・数・理・社）があります。\n・同教科を連続で引くと『コンボ』となり得点ボーナス加算！\n・5教科をすべて手札に揃えると、合計点の22%（10〜28点）が加算される『5教科ボーナス』が発生します！",
					Vector2(get_viewport_rect().size.x * 0.30, get_viewport_rect().size.y * 0.12),
					func():
						tutorial_dialog_node = show_tutorial_dialog(
							"【仕込みアイテム：付箋】\n初期カードの『付箋』は、次のドローで特定の教科を確定で出現させる効果（山札にあれば）を持ちます。教科コンボや5教科ボーナスを狙うのに非常に強力です！\n\nそれでは、実際に『勉強カードを引く』を押して1枚引いてみましょう！",
							Vector2(get_viewport_rect().size.x * 0.30, get_viewport_rect().size.y * 0.12)
						)
						draw_btn.disabled = false
				)
		)

func apply_deck_startup_items() -> void:
	# Simulate activating Eraser or Red Sheet if slotted
	for slot_idx in Global.current_deck.keys():
		var item = Global.current_deck[slot_idx]
		if item == "item_eraser" and (Global.is_tutorial_mode or randf() < 0.5):
			session.player_deck.eraser_charges = 1
			if not "item_eraser" in active_used_items:
				active_used_items.append("item_eraser")
		elif item == "item_red_sheet" and randf() < 0.3:
			session.player_deck.red_sheet_active = true
			active_used_items.append("item_red_sheet")
		elif item == "item_mech_pencil" and randf() < 0.4:
			session.player_deck.next_draw_bonus_points = 2
			active_used_items.append("item_mech_pencil")

func update_ui() -> void:
	var score_info = session.player_deck.calculate_hand_score()
	actual_score_label.text = str(score_info["total_score"]) + "点"
	
	# Update burst probability & LED
	var prob = session.player_deck.get_burst_probability()
	var pct = int(prob * 100)
	
	if pct == 0:
		burst_prob_label.text = "眠気：安全 (0%)"
		led_indicator.color = DeskTheme.COLOR_GREEN
		alert_banner.color.a = 0.0
	elif pct < 45:
		burst_prob_label.text = "眠気：眠くなってきた (" + str(pct) + "%)"
		led_indicator.color = Color.YELLOW
		alert_banner.color.a = 0.0
	elif pct < 80:
		burst_prob_label.text = "眠気：限界に近い！ (" + str(pct) + "%)"
		led_indicator.color = Color.ORANGE
		alert_banner.color.a = 0.3
		alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.3)
	else:
		burst_prob_label.text = "眠気：意識が飛びそう！！ (" + str(pct) + "%)"
		led_indicator.color = DeskTheme.COLOR_TENSION
		alert_banner.color.a = 0.8
		alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.8)
		DeskTheme.pulse_vignette(alert_banner, Color(DeskTheme.COLOR_TENSION), prob)
		
	update_active_effects_ui()

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
	badge_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
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
		
	DeskTheme.animate_card_flip(card_ui, 0.35, func():
		if card_vbox:
			card_vbox.visible = true
	)
	
	# Re-arrange fan hand layout
	arrange_hand_fan()
	
	# Wait for animation to finish
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(func():
		is_animating = false
		
		# Play combo sound if last two cards share a non-none subject
		if session.player_deck.hand.size() > 1:
			var last = session.player_deck.hand[session.player_deck.hand.size() - 1]
			var prev = session.player_deck.hand[session.player_deck.hand.size() - 2]
			if last["subject"] != CardData.SUBJECT_NONE and last["subject"] == prev["subject"]:
				if has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_se(AudioManager.SE_COMBO)
					
		if on_complete.is_valid():
			on_complete.call()
	)

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
	var card = session.player_deck.draw_card()
	if card.is_empty():
		is_animating = false
		draw_btn.disabled = false
		stop_btn.disabled = false
		return
		
	perform_animated_draw(card, func():
		activate_item_effect(card)
		show_card_detail(card)
		
		# Short delay to allow selection mode to trigger before evaluating standard burst
		var delay_timer = get_tree().create_timer(0.1)
		delay_timer.timeout.connect(func():
			if is_selecting_card:
				return
				
			# Check burst
			if session.player_deck.check_burst():
				trigger_burst_sequence()
			else:
				update_ui()
				if not has_bursted:
					if Global.is_tutorial_mode and session.current_day == 1 and session.current_hour == 1:
						advance_tutorial_step()
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
	title.text = "のぞき見メモ ✍️"
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(list_vbox)
	
	for idx in range(peeked.size()):
		var card = peeked[idx]
		var sub_jp = "なし"
		match card["subject"]:
			CardData.SUBJECT_MATH: sub_jp = "数学"
			CardData.SUBJECT_ENGLISH: sub_jp = "英語"
			CardData.SUBJECT_JAPANESE: sub_jp = "国語"
			CardData.SUBJECT_SCIENCE: sub_jp = "理科"
			CardData.SUBJECT_SOCIAL: sub_jp = "社会"
			
		var card_lbl = Label.new()
		card_lbl.text = "・%d枚目： %s (%d 点)" % [idx + 1, sub_jp, card["value"]]
		card_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		card_lbl.add_theme_font_size_override("font_size", 16)
		card_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
		list_vbox.add_child(card_lbl)
		
	# Disable mouse filter recursively so it never blocks clicks
	set_mouse_filter_recursive(active_peek_sticky, Control.MOUSE_FILTER_IGNORE)
	
	active_peek_sticky.scale = Vector2(0.5, 0.5)
	var tween = create_tween().bind_node(active_peek_sticky).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(active_peek_sticky, "scale", Vector2.ONE, 0.3)

func repopulate_hand_visuals() -> void:
	for child in hand_container.get_children():
		child.queue_free()
		
	current_hand_cards.clear()
	var idx = 0
	for card in session.player_deck.hand:
		current_hand_cards.append(card)
		var card_ui = create_card_visual(card)
		card_ui.set_meta("hand_index", idx)
		hand_container.add_child(card_ui)
		idx += 1
		
	arrange_hand_fan()
	update_active_effects_ui()

func arrange_hand_fan() -> void:
	var children = hand_container.get_children()
	var count = children.size()
	if count == 0:
		return
		
	var max_arc = 24.0 # degrees
	var step_angle = max_arc / max(1, count - 1)
	var radius = 350.0
	
	var center_x = hand_container.custom_minimum_size.x / 2.0
	var base_y = 180.0
	
	for idx in range(count):
		var child = children[idx] as Control
		var angle_offset = -max_arc / 2.0 + idx * step_angle
		if count == 1:
			angle_offset = 0.0
			
		var rad = deg_to_rad(angle_offset)
		var offset_x = radius * sin(rad)
		var offset_y = -radius * (1.0 - cos(rad))
		
		var scale_mult = 1.0
		if count > 5:
			scale_mult = clamp(1.0 - (count - 5) * 0.08, 0.65, 1.0)
		child.set_meta("fan_scale", scale_mult)
		child.set_meta("fan_rotation", angle_offset)
		child.set_meta("fan_position", Vector2(center_x + offset_x - (child.custom_minimum_size.x * scale_mult) / 2.0, base_y + offset_y))
		child.scale = Vector2.ONE * scale_mult
		child.rotation_degrees = angle_offset
		child.position = child.get_meta("fan_position", Vector2(center_x, base_y))

func trigger_burst_sequence() -> void:
	has_bursted = true
	draw_btn.disabled = true
	stop_btn.disabled = true
	
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
	
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		var has_amulet = false
		for slot in Global.current_deck.keys():
			if Global.current_deck[slot] == "item_amulet":
				has_amulet = true
				break
				
		var final_score = 0
		if has_amulet:
			var score_info = session.player_deck.calculate_hand_score()
			final_score = int(round(score_info["total_score"] * 0.5))
			
		session.add_player_hour_result(current_hand_cards.size(), active_used_items, true, final_score)
		
		finish_hour_and_transition()
	)

func _on_stop_pressed() -> void:
	if is_animating or has_bursted:
		return
		
	# Clear peek sticky on stop
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
		
	# Click animation
	DeskTheme.animate_click(stop_btn, Vector2.ONE, 0.08)
	
	# Save points
	var score_info = session.player_deck.calculate_hand_score()
	var final_score = score_info["total_score"]
	
	session.add_player_hour_result(hand_container.get_child_count(), active_used_items, false, final_score)
	
	finish_hour_and_transition()

func finish_hour_and_transition() -> void:
	session.player_deck.reset_for_next_hour()
	
	# Clear active peek sticky if exists
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
		
	# Exit the phase immediately to return flow to GameScene.gd
	# GameScene will handle the loop, returning to BagBuilder (Card Addition) if remaining periods exist
	finish_phase({
		"actual_score": session.player_actual_score_today
	})

func show_card_detail(card: Dictionary) -> void:
	var item_info = CardData.ITEMS.get(card["item_id"], null)
	if item_info:
		detail_title_label.text = "【" + item_info["name"] + "】"
		detail_role_label.text = "系統: " + CardData.get_role_name(item_info["role"])
		detail_role_label.add_theme_color_override("font_color", CardData.get_role_color(item_info["role"]))
		detail_desc_label.text = item_info["description"]
	else:
		detail_title_label.text = "カード説明"
		detail_role_label.text = ""
		detail_desc_label.text = "カードをクリックすると効果の説明が表示されます。"
		
	# Show tooltip
	card_detail_box.visible = true
	
func _process(delta: float) -> void:
	if card_detail_box and card_detail_box.visible:
		var mouse_pos = get_global_mouse_position()
		# Offset slightly so the mouse cursor doesn't block the tooltip
		card_detail_box.position = mouse_pos + Vector2(20, -100)
		# Clamp to screen to avoid going offscreen
		var tooltip_viewport_size = get_viewport_rect().size
		card_detail_box.position.x = clamp(card_detail_box.position.x, 0, max(tooltip_viewport_size.x - card_detail_box.size.x, 0.0))
		card_detail_box.position.y = clamp(card_detail_box.position.y, 0, max(tooltip_viewport_size.y - card_detail_box.size.y, 0.0))

func set_mouse_filter_recursive(node: Node, filter: int) -> void:
	if node is Control:
		node.mouse_filter = filter
	for child in node.get_children():
		set_mouse_filter_recursive(child, filter)

func _on_phone_toggle_pressed() -> void:
	DeskTheme.animate_click(phone_toggle_btn, Vector2.ONE, 0.08)
	is_phone_open = not is_phone_open
	
	var target_x = 0.0 if is_phone_open else -260.0
	var tween = create_tween().bind_node(standing_phone).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(standing_phone, "position:x", target_x, 0.4)
	
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
		active_list.append({"name": "蛍光ペン", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "コンボ得点1.5倍"})
		
	if deck.blue_pen_active:
		active_list.append({"name": "青ペン", "color": DeskTheme.COLOR_ROLE_PREP, "desc": "国・英得点1.5倍"})
		
	if deck.energy_drink_active:
		active_list.append({"name": "エナジードリンク", "color": DeskTheme.COLOR_TENSION, "desc": "得点2倍（バースト注意）"})
		
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
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 1)
		badge.add_child(vbox)
		
		var title_lbl = Label.new()
		title_lbl.text = eff["name"]
		title_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		title_lbl.add_theme_font_size_override("font_size", 10)
		title_lbl.add_theme_color_override("font_color", eff["color"])
		vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = eff["desc"]
		desc_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(desc_lbl)
		
		active_effects_hbox.add_child(badge)

func update_yesterday_standings_ui() -> void:
	var standings_list = standing_phone.find_child("StandingsList", true, false) as VBoxContainer
	if not standings_list:
		return
		
	for child in standings_list.get_children():
		child.queue_free()
		
	var standings = get_yesterday_standings()
	
	# Day subtext
	var day_lbl = Label.new()
	day_lbl.text = "Day %d (本日) 朝時点の総得点" % session.current_day
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	day_lbl.add_theme_font_size_override("font_size", 14)
	day_lbl.add_theme_color_override("font_color", Color("90a4ae"))
	standings_list.add_child(day_lbl)
	
	for idx in range(standings.size()):
		var p = standings[idx]
		
		var card = PanelContainer.new()
		var c_style = StyleBoxFlat.new()
		c_style.bg_color = DeskTheme.COLOR_CRAFT
		c_style.corner_radius_top_left = 6
		c_style.corner_radius_top_right = 6
		c_style.corner_radius_bottom_left = 6
		c_style.corner_radius_bottom_right = 6
		c_style.content_margin_left = 8
		c_style.content_margin_right = 8
		c_style.content_margin_top = 6
		c_style.content_margin_bottom = 6
		
		if p["id"] == "player":
			c_style.border_color = DeskTheme.COLOR_GREEN
			c_style.border_width_left = 3
		else:
			c_style.border_color = Color("cfd8dc")
			c_style.border_width_left = 1
			
		card.add_theme_stylebox_override("panel", c_style)
		standings_list.add_child(card)
		
		var hbox = HBoxContainer.new()
		card.add_child(hbox)
		
		var rank_lbl = Label.new()
		rank_lbl.text = "%d位 " % (idx + 1)
		rank_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		rank_lbl.add_theme_font_size_override("font_size", 16)
		if idx == 0:
			rank_lbl.add_theme_color_override("font_color", Color("ffd700"))
		else:
			rank_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		hbox.add_child(rank_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = p["name"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		hbox.add_child(name_lbl)
		
		var score_lbl = Label.new()
		score_lbl.text = "%d点" % p["score"]
		score_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		score_lbl.add_theme_font_size_override("font_size", 16)
		score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		hbox.add_child(score_lbl)
		
	# target clue text
	var clue = Label.new()
	clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clue.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	clue.add_theme_font_size_override("font_size", 13)
	clue.add_theme_color_override("font_color", Color.WHITE)
	
	var player_rank = 1
	var top_score = standings[0]["score"]
	var player_score = 0
	for idx in range(standings.size()):
		if standings[idx]["id"] == "player":
			player_rank = idx + 1
			player_score = standings[idx]["score"]
			
	if player_rank == 1:
		clue.text = "現在1位！この調子で差を広げよう！"
		clue.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	else:
		var diff = top_score - player_score
		clue.text = "首位の %s まであと %d点！勉強を進めて追い抜こう！" % [standings[0]["name"], diff]
		clue.add_theme_color_override("font_color", DeskTheme.COLOR_HIGHLIGHTER)
		
	standings_list.add_child(clue)

func get_yesterday_standings() -> Array:
	var standings = []
	var scores = {
		"player": 0,
		"cpu_sato": 0,
		"cpu_suzuki": 0,
		"cpu_takahashi": 0
	}
	
	var yesterday_day = session.current_day - 1
	if yesterday_day < 1:
		for key in scores.keys():
			var name = "あなた"
			if key == "player" and Global.player_name != "":
				name = Global.player_name
			elif key != "player":
				# ScoreEvaluator のヘルパーで安全にID解決
				var deck_cfg = ScoreEvaluator._get_deck_config(key)
				if Global.opponent_profiles.has(key):
					name = Global.opponent_profiles[key].get("name", key)
				elif AIManager.CPU_OPPONENTS.has(key):
					name = AIManager.CPU_OPPONENTS[key].get("name", key)
			standings.append({"id": key, "name": name, "score": 0})
		return standings
		
	for day_idx in range(1, yesterday_day + 1):
		var day_data = session.match_history.get(day_idx, null)
		if not day_data:
			continue
			
		for p_id in scores.keys():
			var p = day_data.get(p_id, null)
			if not p:
				continue
			var actual = p["actual_score"]
			var declared = p["declared_score"]
			var is_liar = declared > actual
			var base_score = declared
			var adjustment = 0
			
			var doubts_on_me = p.get("doubts_received", [])
			var is_doubt_exposed = p.get("is_doubt_exposed", false)
			var auto_exposed = p.get("auto_exposed", false)
			var final_exposed = is_doubt_exposed or auto_exposed
			
			if is_liar and final_exposed:
				var penalty = declared - actual
				# ScoreEvaluator のヘルパーで安全にデッキ設定を取得
				var deck_config = ScoreEvaluator._get_deck_config(p_id)
				if ScoreEvaluator._has_item(deck_config, "item_copy_answer"):
					adjustment -= penalty * 2
				else:
					adjustment -= penalty
					
			scores[p_id] += base_score + adjustment
			
		var base_fail_penalty = 10 + (day_idx - 1) * 2
		for p_id in scores.keys():
			var p = day_data.get(p_id, null)
			if not p:
				continue
			var deck_config = ScoreEvaluator._get_deck_config(p_id)
			
			var cushion_active = ScoreEvaluator._has_item(deck_config, "item_cushion")
			var earplug_reduction = 10 if ScoreEvaluator._has_item(deck_config, "item_earplugs") else 0
			var chat_bonus = 6 if ScoreEvaluator._has_item(deck_config, "item_study_chat") else 0
				
			for target_id in p.get("doubts_made", []):
				var target = day_data.get(target_id, null)
				if not target:
					continue
				var target_actual = target["actual_score"]
				var target_declared = target["declared_score"]
				var target_lied = target_declared > target_actual
				
				var doubter_adj = 0
				if target_lied:
					var bluff = target_declared - target_actual
					doubter_adj += bluff + 6 + chat_bonus
				else:
					var penalty = base_fail_penalty
					if cushion_active:
						penalty = int(round(penalty * 0.5))
					penalty = max(penalty - earplug_reduction, 0)
					doubter_adj -= penalty
				scores[p_id] += doubter_adj
				
	scores["player"] += Global.get_total_level_bonus()
	# 星レベルボーナスもスタンディングに反映
	scores["player"] += ScoreEvaluator._calculate_star_bonus_for_player()
	
	for key in scores.keys():
		var name = "あなた"
		if key == "player" and Global.player_name != "":
			name = Global.player_name
		elif key != "player":
			if Global.opponent_profiles.has(key):
				name = Global.opponent_profiles[key].get("name", key)
			elif AIManager.CPU_OPPONENTS.has(key):
				name = AIManager.CPU_OPPONENTS[key].get("name", key)
		standings.append({
			"id": key,
			"name": name,
			"score": scores[key]
		})
		
	standings.sort_custom(func(a, b): return a["score"] > b["score"])
	return standings

func start_card_selection(mode: String, guide_text: String) -> void:
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
	tween.tween_property(alert_banner, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 手札の見た目を再配置し、各カードのホバーエフェクトが効くようにする
	arrange_hand_fan()

func _on_card_ui_pressed(card: Dictionary, card_ui: Button) -> void:
	if is_selecting_card:
		var hand_idx = card_ui.get_meta("hand_index", -1)
		if hand_idx != -1:
			_on_card_selected_from_hand(hand_idx, card)
	else:
		show_card_detail(card)

func _on_card_ui_mouse_entered(card: Dictionary, card_ui: Button) -> void:
	if hovered_card_ui and hovered_card_ui != card_ui:
		_clear_hovered_card()
	hovered_card_ui = card_ui
	if not is_selecting_card:
		show_card_detail(card)
	
	# Set high z_index to draw on top of other cards without altering tree order
	card_ui.z_index = 10
	if is_instance_valid(hovered_card_tween):
		hovered_card_tween.kill()
	
	var tween = create_tween().bind_node(card_ui).set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hovered_card_tween = tween
	var scale_mult = 1.15 if is_selecting_card else 1.12
	var base_scale = float(card_ui.get_meta("fan_scale", 1.0))
	var base_pos = card_ui.get_meta("fan_position", card_ui.position)
	var base_rot = float(card_ui.get_meta("fan_rotation", card_ui.rotation_degrees))
	tween.tween_property(card_ui, "scale", Vector2.ONE * (base_scale * scale_mult), 0.15)
	
	var lift_y = -30 if is_selecting_card else -20
	tween.tween_property(card_ui, "position", base_pos + Vector2(0, lift_y), 0.15)
	tween.tween_property(card_ui, "rotation_degrees", base_rot, 0.15)
	
	if is_selecting_card:
		card_ui.modulate = Color(1.2, 1.2, 1.2, 1.0) # slightly brighter highlight

func _on_card_ui_mouse_exited(card_ui: Button) -> void:
	if hovered_card_ui == card_ui:
		hovered_card_ui = null
	if card_detail_box:
		card_detail_box.visible = false
	
	_reset_hovered_card(card_ui)
	# arrange_hand_fan restores the canonical hand layout after hover exits
	arrange_hand_fan()

func _reset_hovered_card(card_ui: Button) -> void:
	if not card_ui:
		return
	card_ui.z_index = 0
	card_ui.modulate = Color.WHITE
	card_ui.scale = Vector2.ONE * float(card_ui.get_meta("fan_scale", 1.0))
	card_ui.rotation_degrees = float(card_ui.get_meta("fan_rotation", 0.0))
	card_ui.position = card_ui.get_meta("fan_position", card_ui.position)

func _clear_hovered_card() -> void:
	if is_instance_valid(hovered_card_tween):
		hovered_card_tween.kill()
	hovered_card_tween = null
	if hovered_card_ui:
		_reset_hovered_card(hovered_card_ui)
		hovered_card_ui = null
	if card_detail_box:
		card_detail_box.visible = false
	arrange_hand_fan()

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

func advance_tutorial_step() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
		
	tutorial_step += 1
	
	match tutorial_step:
		1:
			stop_btn.disabled = true
			draw_btn.disabled = false
			tutorial_dialog_node = show_tutorial_dialog(
				"カードを引きました！カードの左上には『教科アイコン』、中央には大きく『点数（数字）』が書かれています。\n\nもう1枚引いてみましょう！",
				Vector2(get_viewport_rect().size.x * 0.30, get_viewport_rect().size.y * 0.12)
			)
		2:
			stop_btn.disabled = true
			draw_btn.disabled = false
			tutorial_dialog_node = show_tutorial_dialog(
				"2枚目を引きました！もし手札に同じ数字のカードが重なると「寝落ち（バースト）」してこの時限の点数は0点になります。\n右上の「眠気」パーセントがバーストする確率です。安全第一で、もう1枚引いてみましょう！",
				Vector2(get_viewport_rect().size.x * 0.30, get_viewport_rect().size.y * 0.12)
			)
		3:
			draw_btn.disabled = true # これ以上ドローさせない
			stop_btn.disabled = false # 休憩を有効化
			tutorial_dialog_node = show_tutorial_dialog(
				"3枚目を引きました！同じ教科を連続して引くと「コンボボーナス」が入ります！\n眠気も上がってきたので、ここらで『休憩する』を押して自習を終え、本日の成果（点数）を確定させましょう！",
				Vector2(get_viewport_rect().size.x * 0.30, get_viewport_rect().size.y * 0.12)
			)
