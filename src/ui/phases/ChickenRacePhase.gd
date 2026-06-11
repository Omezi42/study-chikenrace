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
	
	ChickenRaceUIBuilder.build_ui(self)
	
	apply_deck_startup_items()
	init_cpu_simulation_states()
	update_ui()
	_update_member_badge_ui("player")
	
	# 自動テスト実行中はチュートリアルをスキップ
	var is_test = false
	if OS.has_feature("web"):
		var test_val = JavaScriptBridge.eval("window.is_antigravity_test")
		if test_val != null and test_val:
			is_test = true
	if is_test:
		Global.is_tutorial_mode = false

	if Global.is_tutorial_mode and session.current_day == 1 and session.current_hour == 1:
		session.max_hours_today = 2
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
	hand_container.add_child(card_ui)
	
	# Calculate the correct target layout positions for all hand cards
	arrange_hand_fan()
	
	# Record target position and apply animation offset
	var target_pos = card_ui.position
	card_ui.position.y -= 180
	
	# Play draw sound
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_se(AudioManager.SE_DRAW)
		
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
			
	ChickenRaceAnimations.play_burst_animation(self, duplicate_values)
	
	var timer = get_tree().create_timer(1.2 / speed_mult)
	timer.timeout.connect(func():
		var final_score = engine.calculate_hand_score()
		session.add_player_hour_result(session.player_deck.hand.size(), engine.active_used_items, true, final_score)
		
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
	
	if Global.is_tutorial_mode and tutorial and session.current_hour == 2:
		tutorial.start_hour_2()

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
