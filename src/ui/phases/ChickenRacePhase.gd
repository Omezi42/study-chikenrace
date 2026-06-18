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
var ui_scene_node: Control

# Deck count sticky note (Loop 11)
var deck_sticky: PanelContainer
var deck_count_lbl: Label
var deck_warning_lbl: Label
var active_compass_sticky: PanelContainer = null

# Decision Panel (Phase 2)
var decision_panel: DecisionPanel

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
var current_max_burst_prob: float = 0.0

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
	
	_init_notebook_ui()
	call_deferred("_rescale_notebook")

var _rescaling: bool = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rescale_notebook()

func _rescale_notebook() -> void:
	if _rescaling:
		return
	_rescaling = true
	# 親からのサイズではなく、自分自身（FULL_RECT設定により親と同じサイズになっている）のサイズを基準にする
	var parent_size = size
	if parent_size == Vector2.ZERO or not ui_scene_node:
		_rescaling = false
		return
	
	# アスペクト比を1.7647 (1500/850) に保つための計算
	var scale_x = parent_size.x / 1500.0
	var scale_y = parent_size.y / 850.0
	var final_scale = min(scale_x, scale_y)
	final_scale = clamp(final_scale, 0.4, 1.0)
	
	# ui_scene_node 自身（内部のレイアウト）をスケールする
	ui_scene_node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui_scene_node.size = Vector2(1500, 850)
	ui_scene_node.pivot_offset = Vector2.ZERO
	ui_scene_node.scale = Vector2(final_scale, final_scale)
	
	# スケール後の実サイズに基づいて中央に配置
	var scaled_size = Vector2(1500, 850) * final_scale
	ui_scene_node.position = (parent_size - scaled_size) / 2.0
	
	_rescaling = false

func _init_notebook_ui() -> void:
	if not session:
		return
		
	if session.current_hour == 1:
		session.player_deck.reset_for_next_day()
	
	if has_node("/root/BackendManager"):
		var bm = get_node_or_null("/root/BackendManager")
		if bm and not bm.connection_lost.is_connected(_on_connection_lost):
			bm.connection_lost.connect(_on_connection_lost)
	
	# TSCNシーンのインスタンス化
	ui_scene_node = load("res://src/ui/phases/ChickenRacePhase.tscn").instantiate()
	add_child(ui_scene_node)
	ui_scene_node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui_scene_node.size = Vector2(1500, 850)
	
	# コントロールのバインド
	left_page = ui_scene_node.get_node_or_null("MainHBox/LeftPage")
	header_left = ui_scene_node.get_node_or_null("MainHBox/LeftPage/LeftVBox/LeftMargin/LeftInnerVBox/HeaderLabel")
	actual_score_label = ui_scene_node.get_node_or_null("MainHBox/LeftPage/LeftVBox/LeftMargin/LeftInnerVBox/ActualScoreLabel")
	draw_history_container = ui_scene_node.get_node_or_null("MainHBox/LeftPage/LeftVBox/LeftMargin/LeftInnerVBox/DrawHistoryContainer")
	card_detail_box = ui_scene_node.get_node_or_null("MainHBox/LeftPage/LeftVBox/LeftMargin/LeftInnerVBox/CardDetailBox")
	
	right_page = ui_scene_node.get_node_or_null("MainHBox/RightPage")
	var stats_hbox = ui_scene_node.get_node_or_null("MainHBox/RightPage/RightVBox/RightMargin/RightInnerVBox/StatsHBox")
	if stats_hbox:
		stats_hbox.visible = false # 旧バースト率表示は隠す
		led_indicator = stats_hbox.get_node_or_null("LedIndicator")
		burst_prob_label = stats_hbox.get_node_or_null("BurstProbLabel")
	
	hand_container = ui_scene_node.get_node_or_null("MainHBox/RightPage/RightVBox/RightMargin/RightInnerVBox/HandContainer")
	draw_btn = ui_scene_node.get_node_or_null("MainHBox/RightPage/RightVBox/RightMargin/RightInnerVBox/ActionButtons/DrawButton")
	stop_btn = ui_scene_node.get_node_or_null("MainHBox/RightPage/RightVBox/RightMargin/RightInnerVBox/ActionButtons/StopButton")
	
	decision_panel = DecisionPanel.new()
	var right_inner_vbox = ui_scene_node.get_node_or_null("MainHBox/RightPage/RightVBox/RightMargin/RightInnerVBox")
	if right_inner_vbox:
		right_inner_vbox.add_child(decision_panel)
		right_inner_vbox.move_child(decision_panel, 0) # 一番上に配置
	
	# スタイルの動的適用
	left_page.add_theme_stylebox_override("panel", DeskTheme.create_left_page_style())
	right_page.add_theme_stylebox_override("panel", DeskTheme.create_right_page_style())
	
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = DeskTheme.COLOR_CRAFT
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
	
	active_effects_hbox = HBoxContainer.new()
	active_effects_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	active_effects_hbox.add_theme_constant_override("separation", 8)
	if right_inner_vbox:
		right_inner_vbox.add_child(active_effects_hbox)
		right_inner_vbox.move_child(active_effects_hbox, 2)
	
	alert_banner = ColorRect.new()
	alert_banner.custom_minimum_size = Vector2(650, 50)
	alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.0)
	alert_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if right_inner_vbox:
		right_inner_vbox.add_child(alert_banner)
	
	alert_label = Label.new()
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_override("font", DeskTheme.get_font())
	alert_label.add_theme_font_size_override("font_size", 22)
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	alert_banner.add_child(alert_label)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# ボタンへのシグナル接続とスタイル適用
	draw_btn.pressed.connect(_on_draw_pressed)
	stop_btn.pressed.connect(_on_stop_pressed)
	Global.apply_white_button_style(draw_btn)
	Global.apply_white_button_style(stop_btn)
	
	draw_btn.mouse_entered.connect(func():
		if engine:
			var prob = engine.deck.get_burst_probability()
			if prob >= 0.7:
				# 緊張による手の震えを再現する微細なシェイク
				DeskTheme.shake_control(draw_btn, 3.0 * (prob * 2.0), 0.3, 12)
	)
	
	apply_deck_startup_items()
	init_cpu_simulation_states()
	update_ui()
	_update_member_badge_ui("player")
	
	# Apply notebook visual details like ZukanScene
	if left_page:
		DeskTheme.add_ruled_lines(left_page)
	if right_page:
		DeskTheme.add_ruled_lines(right_page)
	var main_hbox = ui_scene_node.get_node_or_null("MainHBox")
	if main_hbox:
		DeskTheme.add_spiral_binding(main_hbox, 850.0)
	
	# 自動テスト実行中はチュートリアルをスキップ
	var is_test = false
	if OS.has_feature("web"):
		var test_val = JavaScriptBridge.eval("window.is_antigravity_test")
		if test_val != null and test_val:
			is_test = true
	if is_test:
		Global.is_tutorial_mode = false

	if Global.is_tutorial_mode and session.current_day == 1 and session.current_hour == 1:
		session.max_hours_today = 3
		tutorial = ChickenRaceTutorial.new(self)
		tutorial.start()

func apply_deck_startup_items() -> void:
	engine.apply_deck_startup_items(Global.is_tutorial_mode)


func update_ui() -> void:
	smartphone_presenter.update_ui()
	ChickenRaceAnimations.update_compass_sticky(self)
	_update_decision_panel()

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
				# expected delta = (avg_safe_score) * safe_prob + (-score) * prob
				expected_val = (avg_safe_score * safe_prob) - (score * prob)
			
	decision_panel.update_info(score, prob, deck_count, hand_count, expected_val)


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
	hand_container.add_child(card_ui)
	
	# Calculate the correct target layout positions for all hand cards
	arrange_hand_fan()
	
	# Record target position and apply animation offset
	var target_pos = card_ui.position
	card_ui.position.y -= 180
	
	# Play draw sound
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
		
	# Clear active peek sticky & compass sticky if exists on next draw
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
	if active_compass_sticky:
		active_compass_sticky.queue_free()
		active_compass_sticky = null
	if session.player_deck.compass_active:
		session.player_deck.compass_active = false
		
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
		
	var prob = engine.deck.get_burst_probability()
	if prob > current_max_burst_prob:
		current_max_burst_prob = prob
		
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
				
			# テンション演出（危険域に達した時の緊張感）
			if engine.deck.get_burst_probability() >= 0.4:
				DeskTheme.shake_control(self, 6.0, 0.3)
				if has_node("/root/AudioManager"):
					var am = get_node_or_null("/root/AudioManager")
					if am: am.play_se(AudioManager.SE_PLACE) # SE_TENSIONの代用
					
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
	ChickenRaceAnimations.show_peek_sticky(self, peeked)

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
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_se(AudioManager.SE_BURST)
	
	# Clear peek sticky on burst
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
	if active_compass_sticky:
		active_compass_sticky.queue_free()
		active_compass_sticky = null
	
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
			
	ChickenRaceAnimations.play_burst_animation(self, duplicate_values)
	
	var timer = get_tree().create_timer(1.2 / speed_mult)
	timer.timeout.connect(func():
		var final_score = engine.calculate_hand_score()
		var total_used = []
		total_used.append_array(engine.active_used_items)
		total_used.append_array(session.player_deck.activated_items)
		var reaction = CardData.get_reaction_text(current_max_burst_prob)
		session.add_player_hour_result(session.player_deck.hand.size(), total_used, true, final_score, reaction)
		
		finish_hour_and_transition(final_score, true)
	)

func _spawn_zzz_scribbles() -> void:
	pass

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
	if active_compass_sticky:
		active_compass_sticky.queue_free()
		active_compass_sticky = null
		
	# Click animation
	DeskTheme.animate_click(stop_btn, Vector2.ONE, 0.08)
	
	# ドラマティックストップ演出（提出スタンプ表示）
	var stamp = Label.new()
	stamp.text = "提出！"
	stamp.add_theme_font_override("font", DeskTheme.get_font())
	stamp.add_theme_font_size_override("font_size", 100)
	stamp.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	stamp.rotation_degrees = -15
	var vp_size = get_viewport_rect().size
	stamp.position = Vector2(vp_size.x * 0.4, vp_size.y * 0.4)
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
		# Save points
		var final_score = engine.calculate_hand_score()
		var total_used = []
		total_used.append_array(engine.active_used_items)
		total_used.append_array(session.player_deck.activated_items)
		var reaction = CardData.get_reaction_text(current_max_burst_prob)
		session.add_player_hour_result(session.player_deck.hand.size(), total_used, false, final_score, reaction)
		
		fast_forward_cpus_to_end()
		_update_member_badge_ui("player")
		
		finish_hour_and_transition(final_score, false)
	)


func finish_hour_and_transition(final_score: int, is_burst: bool) -> void:
	show_hour_result_popup(final_score, is_burst)
	
	session.player_deck.reset_for_next_hour()
	update_ui()
	
	if tutorial:
		tutorial.cleanup()
		
	# Clear active peek sticky if exists
	if active_peek_sticky:
		active_peek_sticky.queue_free()
		active_peek_sticky = null
	if active_compass_sticky:
		active_compass_sticky.queue_free()
		active_compass_sticky = null
		
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
	current_max_burst_prob = 0.0
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
	
	if Global.is_tutorial_mode and tutorial:
		if session.current_hour == 2:
			tutorial.start_hour_2()
		elif session.current_hour == 3:
			tutorial.start_hour_3()

func show_hour_result_popup(score: int, is_burst: bool) -> void:
	ChickenRaceAnimations.show_hour_result_popup(self, score, is_burst)

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
		active_list.append({"name": "消しゴム効果", "color": DeskTheme.COLOR_ROLE_DEFENSE, "desc": "次の1枚のみ眠気回避"})
		
	if deck.red_sheet_active:
		active_list.append({"name": "赤シート", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "被り時にバースト無効"})
		
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
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_se(AudioManager.SE_PLACE)
	
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

func _exit_tree() -> void:
	if is_instance_valid(hovered_card_tween):
		hovered_card_tween.kill()
