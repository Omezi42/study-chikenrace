class_name ChickenRacePhase
extends PhaseBase

const CardVisual = preload("res://src/ui/CardVisual.gd")

var actual_score_label: Label
var draw_history_container: HBoxContainer
var hand_container: Control
var draw_btn: Button
var stop_btn: Button
var decision_panel: DecisionPanel
var alert_banner: ColorRect
var alert_label: Label

var engine: ChickenRaceEngine
var current_hand_cards: Array:
	get: return engine.hand_cards if engine else []
var has_bursted: bool:
	get: return engine.has_bursted if engine else false
	set(val):
		if engine: engine.has_bursted = val

var current_max_burst_prob: float = 0.0

enum RaceState { SETUP, IDLE, ANIMATING, BURSTED, STOPPED }
var current_state: RaceState = RaceState.SETUP

var is_animating: bool:
	get: return current_state == RaceState.ANIMATING
	set(val):
		if val:
			current_state = RaceState.ANIMATING
		else:
			if current_state == RaceState.ANIMATING:
				current_state = RaceState.IDLE
				draw_btn.disabled = false
				stop_btn.disabled = false

var speed_mult: float = 1.0
var hand_presenter: ChickenRaceHandPresenter
var cpu_presenter: ChickenRaceCPUPresenter
var smartphone_presenter: ChickenRaceSmartphonePresenter

func _on_setup(setup_data: Dictionary) -> void:
	speed_mult = 1.0
	engine = ChickenRaceEngine.new()
	engine.setup(session)
	
	hand_presenter = ChickenRaceHandPresenter.new(self)
	cpu_presenter = ChickenRaceCPUPresenter.new(self)
	smartphone_presenter = ChickenRaceSmartphonePresenter.new(self)
	
	_build_ui()
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_GAME, 1.0)
		
	update_ui()
	is_animating = false

func _build_ui() -> void:
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 30)
	add_child(main_vbox)
	
	# Score and Info
	actual_score_label = Label.new()
	actual_score_label.add_theme_font_override("font", DeskTheme.get_font())
	actual_score_label.add_theme_font_size_override("font_size", 64)
	actual_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	actual_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actual_score_label.text = "0点"
	main_vbox.add_child(actual_score_label)
	
	# Decision Panel (Expected value, etc)
	decision_panel = DecisionPanel.new()
	decision_panel.custom_minimum_size = Vector2(400, 100)
	decision_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(decision_panel)
	
	# Hand Container
	hand_container = Control.new()
	hand_container.custom_minimum_size = Vector2(800, 250)
	hand_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(hand_container)
	
	# Draw History
	draw_history_container = HBoxContainer.new()
	draw_history_container.alignment = BoxContainer.ALIGNMENT_CENTER
	draw_history_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(draw_history_container)
	
	# Actions
	var action_hbox = HBoxContainer.new()
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_hbox.add_theme_constant_override("separation", 40)
	main_vbox.add_child(action_hbox)
	
	draw_btn = Button.new()
	draw_btn.text = "カードを引く"
	draw_btn.custom_minimum_size = Vector2(200, 80)
	draw_btn.add_theme_font_override("font", DeskTheme.get_font())
	draw_btn.add_theme_font_size_override("font_size", 24)
	Global.apply_white_button_style(draw_btn)
	draw_btn.pressed.connect(_on_draw_pressed)
	action_hbox.add_child(draw_btn)
	
	stop_btn = Button.new()
	stop_btn.text = "ストップ"
	stop_btn.custom_minimum_size = Vector2(200, 80)
	stop_btn.add_theme_font_override("font", DeskTheme.get_font())
	stop_btn.add_theme_font_size_override("font_size", 24)
	Global.apply_white_button_style(stop_btn)
	stop_btn.pressed.connect(_on_stop_pressed)
	action_hbox.add_child(stop_btn)
	
	alert_banner = ColorRect.new()
	alert_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.0)
	alert_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(alert_banner)
	
	alert_label = Label.new()
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_override("font", DeskTheme.get_font())
	alert_label.add_theme_font_size_override("font_size", 80)
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	alert_label.text = ""
	alert_banner.add_child(alert_label)

func update_ui() -> void:
	smartphone_presenter.update_ui()
	_update_decision_panel()
	actual_score_label.text = str(engine.calculate_hand_score()) + "点"

func _update_decision_panel() -> void:
	if not is_instance_valid(decision_panel):
		return
	var score = engine.calculate_hand_score() if engine else 0
	var prob = engine.deck.get_burst_probability() if engine else 0.0
	var deck_count = engine.deck.draw_pile.size() if engine else 0
	var hand_count = session.player_deck.hand.size()
	
	var expected_val = 0.0
	if engine:
		var target_pile = engine.deck.draw_pile
		if target_pile.size() == 0:
			target_pile = engine.deck.discard_pile
			
		if target_pile.size() > 0:
			var safe_points_sum = 0
			var safe_count = 0
			for c in target_pile:
				if not engine.deck.would_card_burst(c):
					safe_points_sum += c.get("value", 0)
					safe_count += 1
			if safe_count > 0:
				var safe_prob = 1.0 - prob
				var avg_safe_score = float(safe_points_sum) / safe_count
				expected_val = (avg_safe_score * safe_prob) - (score * prob)
			
	decision_panel.update_info(score, prob, deck_count, hand_count, expected_val)

func perform_animated_draw(card: Dictionary, on_complete: Callable = Callable()) -> void:
	is_animating = true
	current_hand_cards.append(card)
	
	var card_badge = Button.new()
	card_badge.custom_minimum_size = Vector2(48, 60)
	card_badge.text = str(card["value"])
	card_badge.add_theme_font_override("font", DeskTheme.get_font())
	Global.apply_white_button_style(card_badge)
	draw_history_container.add_child(card_badge)
	
	var card_ui = CardVisual.create(card)
	card_ui.z_index = 20
	hand_container.add_child(card_ui)
	
	arrange_hand_fan()
	
	var target_pos = card_ui.position
	card_ui.position.y -= 180
	
	if has_node("/root/AudioManager"):
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_se(AudioManager.SE_DRAW)
		
	ChickenRaceAnimations.animate_draw_card(self, card, card_ui, func():
		card_ui.position = target_pos
		card_ui.z_index = 0
		arrange_hand_fan()
		is_animating = false
		if on_complete.is_valid():
			on_complete.call()
	)

func arrange_hand_fan() -> void:
	hand_presenter.arrange_hand_fan()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE:
			if not draw_btn.disabled and not is_animating and not has_bursted:
				get_viewport().set_input_as_handled()
				_on_draw_pressed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_S:
			if not stop_btn.disabled and not is_animating and not has_bursted:
				get_viewport().set_input_as_handled()
				_on_stop_pressed()

func _on_draw_pressed() -> void:
	if is_animating or has_bursted:
		return
		
	is_animating = true
	draw_btn.disabled = true
	stop_btn.disabled = true
	
	var card = engine.draw_card()
	if card.is_empty():
		is_animating = false
		DeskTheme.show_toast(self, "山札が空になりました！ストップしましょう。")
		return
		
	var prob = engine.deck.get_burst_probability()
	if prob > current_max_burst_prob:
		current_max_burst_prob = prob
		
	advance_cpu_simulations()
	smartphone_presenter.update_member_badge_ui("player")
		
	perform_animated_draw(card, func():
		if engine.check_burst():
			trigger_burst_sequence()
		else:
			update_ui()
	)

func trigger_burst_sequence() -> void:
	has_bursted = true
	draw_btn.disabled = true
	stop_btn.disabled = true
	
	fast_forward_cpus_to_end()
	smartphone_presenter.update_member_badge_ui("player")
	
	if has_node("/root/AudioManager"):
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_se(AudioManager.SE_BURST, 0.0, -8.0)
	
	DeskTheme.shake_control(self, 15.0, 0.5)
	
	var tween = create_tween().bind_node(alert_banner)
	tween.tween_property(alert_banner, "color:a", 0.5, 0.1)
	alert_label.text = "BURST!"
	
	actual_score_label.text = "0点"
	
	var value_counts = {}
	for c in session.player_deck.hand:
		var val = c.get("value", 0)
		if val != 0:
			value_counts[val] = value_counts.get(val, 0) + 1
			
	var duplicate_values = []
	for val in value_counts.keys():
		if value_counts[val] > 1:
			duplicate_values.append(val)
			
	ChickenRaceAnimations.play_burst_animation(self, duplicate_values)
	
	var timer = get_tree().create_timer(1.2 / speed_mult)
	timer.timeout.connect(func():
		var final_score = engine.calculate_hand_score()
		var reaction = CardData.get_reaction_text(current_max_burst_prob)
		session.add_player_hour_result(session.player_deck.hand.size(), true, final_score, reaction)
		finish_hour_and_transition(final_score, true)
	)

func _on_stop_pressed() -> void:
	if is_animating or has_bursted or stop_btn.disabled:
		return
		
	is_animating = true
	draw_btn.disabled = true
	stop_btn.disabled = true
	
	DeskTheme.animate_click(stop_btn, Vector2.ONE, 0.08)
	
	var stamp = Label.new()
	stamp.text = "STOP"
	stamp.add_theme_font_override("font", DeskTheme.get_font())
	stamp.add_theme_font_size_override("font_size", 100)
	stamp.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	stamp.rotation_degrees = -15
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp.custom_minimum_size = Vector2(600, 150)
	stamp.pivot_offset = Vector2(300, 75)
	
	var vp_size = get_viewport_rect().size
	stamp.position = vp_size / 2 - stamp.pivot_offset
	stamp.z_index = 100
	add_child(stamp)
	
	var stamp_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stamp.scale = Vector2(3.0, 3.0)
	stamp.modulate.a = 0.0
	stamp_tween.tween_property(stamp, "scale", Vector2.ONE, 0.3)
	stamp_tween.parallel().tween_property(stamp, "modulate:a", 1.0, 0.2)
	DeskTheme.shake_control(self, 10.0, 0.4)
	
	if has_node("/root/AudioManager"):
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_se(AudioManager.SE_PLACE)
	
	var wait_timer = get_tree().create_timer(1.0 / speed_mult)
	wait_timer.timeout.connect(func():
		if is_instance_valid(stamp):
			stamp.queue_free()
		var final_score = engine.calculate_hand_score()
		var reaction = CardData.get_reaction_text(current_max_burst_prob)
		session.add_player_hour_result(session.player_deck.hand.size(), false, final_score, reaction)
		
		fast_forward_cpus_to_end()
		smartphone_presenter.update_member_badge_ui("player")
		
		finish_hour_and_transition(final_score, false)
	)

func finish_hour_and_transition(final_score: int, is_burst: bool) -> void:
	ChickenRaceAnimations.show_hour_result_popup(self, final_score, is_burst)
	
	session.player_deck.reset_for_next_hour()
	update_ui()
	
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
	current_max_burst_prob = 0.0
	engine.reset_for_hour()
	
	for child in hand_container.get_children():
		child.queue_free()
	for child in draw_history_container.get_children():
		child.queue_free()
		
	update_ui()
	
	draw_btn.disabled = false
	stop_btn.disabled = false
	
	alert_banner.color.a = 0.0
	alert_label.text = ""
	
	DeskTheme.show_toast(self, "第 %d 時限目の勉強を開始します！" % session.current_hour)

# CPU simulations are handled by CPUPresenter
func advance_cpu_simulations() -> void:
	cpu_presenter.advance_cpu_simulations()

func fast_forward_cpus_to_end() -> void:
	cpu_presenter.fast_forward_cpus_to_end()

func get_cpu_sim_states() -> Dictionary:
	return cpu_presenter.cpu_sim_states if cpu_presenter else {}
