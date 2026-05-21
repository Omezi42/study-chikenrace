# scripts/ui/phases/ChickenRacePhase.gd
class_name ChickenRacePhase
extends RefCounted

const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")
const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")

signal phase_completed(scores_data: Dictionary)

var ctx: RefCounted

# UI要素
var active_notebook: Control
var hud_notebook: Control
var status_label: Label
var hud_gauges: Dictionary = {}
var item_count_labels: Dictionary = {}
var play_desk: Control
var card_container: Control
var burst_warning_banner: Panel
var next_burst_label: Label
var button_box: HBoxContainer
var drawn_card_nodes: Array = []
var history_box: HBoxContainer
var heartbeat_tween: Tween
var camera_shake_offset: Vector2 = Vector2.ZERO
var vignette_node: Control
var vignette_tween: Tween
var rival_sim_states: Dictionary = {}
var current_hour: int = 1
var hour_label: Control

func _init(context: RefCounted):
	self.ctx = context

func start():
	_show_race_screen()

func _show_race_screen():
	for child in ctx.screen_content.get_children():
		child.queue_free()
	drawn_card_nodes.clear()
	heartbeat_tween = null
	camera_shake_offset = Vector2.ZERO
	
	rival_sim_states = {
		"たかし": {"score": 0, "cards": 0, "status": "active", "style": "gambler"},
		"さやか": {"score": 0, "cards": 0, "status": "active", "style": "safe"},
		"けんじ": {"score": 0, "cards": 0, "status": "active", "style": "normal"}
	}
	
	var notebook = NotebookBuilderScript.create()
	active_notebook = notebook
	notebook.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notebook.offset_left = 420.0
	notebook.offset_top = 80.0
	notebook.offset_right = -120.0
	notebook.offset_bottom = -80.0
	ctx.screen_content.add_child(notebook)
	
	SmartphoneBuilderScript.build_standard_smartphone(ctx)
	
	hud_notebook = notebook.find_child("LeftContent", true, false) as MarginContainer
	var hud_v = VBoxContainer.new()
	hud_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_v.add_theme_constant_override("separation", 20)
	DeskTheme.apply_font(hud_v)
	hud_notebook.add_child(hud_v)
	
	var display_hour = 1
	if is_instance_valid(ctx) and ctx.game_session:
		display_hour = ctx.game_session.current_hour
		
	hour_label = DeskTheme.create_floating_badge("%d時間目" % display_hour, DeskTheme.COLOR_ACCENT_GOLD, 20)
	hud_v.add_child(hour_label)
	
	hud_v.add_child(DeskTheme.create_label("[ 本日の学習ノート ]", 32, DeskTheme.COLOR_INK, true))
	
	var stance_lbl = DeskTheme.create_label("今日のスタンス: " + ctx.current_daily_stance, 16, DeskTheme.COLOR_SAFE, true)
	hud_v.add_child(stance_lbl)
	
	# 単一総合スコア表示
	var score_v = VBoxContainer.new()
	score_v.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_v.add_child(score_v)
	
	var score_title = DeskTheme.create_label("現在の獲得点数", 20, DeskTheme.COLOR_MUTED, true)
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_v.add_child(score_title)
	
	status_label = DeskTheme.create_label("0", 64, DeskTheme.COLOR_BLUFF_RED, true)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_v.add_child(status_label)
	
	# 総合スコアバー
	var score_bar = DeskTheme.create_gauge_bar(0.0, 100.0, DeskTheme.COLOR_ACCENT_GOLD, Vector2(300, 24))
	score_v.add_child(score_bar)
	hud_gauges["total_score_bar"] = score_bar
	
	var buff_label = DeskTheme.create_label("", 16, DeskTheme.COLOR_SAFE, true)
	buff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_v.add_child(buff_label)
	hud_gauges["buff_label"] = buff_label
	
	var right_margin = notebook.find_child("RightContent", true, false) as MarginContainer
	var right_v = VBoxContainer.new()
	right_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_v.add_theme_constant_override("separation", 16)
	right_margin.add_child(right_v)
	
	play_desk = Control.new()
	play_desk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_v.add_child(play_desk)
	
	var card_info_h = HBoxContainer.new()
	card_info_h.alignment = BoxContainer.ALIGNMENT_CENTER
	card_info_h.add_theme_constant_override("separation", 24)
	right_v.add_child(card_info_h)
	
	history_box = HBoxContainer.new()
	history_box.alignment = BoxContainer.ALIGNMENT_CENTER
	history_box.add_theme_constant_override("separation", 6)
	right_v.add_child(history_box)
	
	var drawn_count_lbl = DeskTheme.create_label("引いたカード: 0枚", 14, DeskTheme.COLOR_INK, true)
	card_info_h.add_child(drawn_count_lbl)
	hud_gauges["drawn_count"] = drawn_count_lbl
	
	var deck_stack_container = HBoxContainer.new()
	deck_stack_container.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_stack_container.add_theme_constant_override("separation", 10)
	card_info_h.add_child(deck_stack_container)
	
	var deck_stack = Control.new()
	deck_stack.custom_minimum_size = Vector2(40, 55)
	deck_stack_container.add_child(deck_stack)
	hud_gauges["deck_stack"] = deck_stack
	
	var remain_lbl = DeskTheme.create_label("残り山札: --枚", 14, DeskTheme.COLOR_MUTED, true)
	deck_stack_container.add_child(remain_lbl)
	hud_gauges["remain_count"] = remain_lbl
	
	card_container = Control.new()
	card_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_desk.add_child(card_container)
	
	burst_warning_banner = Panel.new()
	burst_warning_banner.custom_minimum_size = Vector2(0, 42)
	burst_warning_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var banner_style = StyleBoxFlat.new()
	banner_style.bg_color = DeskTheme.COLOR_SAFE
	banner_style.corner_radius_top_left = 10; banner_style.corner_radius_top_right = 10
	banner_style.corner_radius_bottom_left = 10; banner_style.corner_radius_bottom_right = 10
	burst_warning_banner.add_theme_stylebox_override("panel", banner_style)
	right_v.add_child(burst_warning_banner)
	
	var banner_h = HBoxContainer.new()
	banner_h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner_h.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_h.add_theme_constant_override("separation", 16)
	burst_warning_banner.add_child(banner_h)
	
	var banner_v = VBoxContainer.new()
	banner_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner_v.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_v.add_theme_constant_override("separation", 4)
	DeskTheme.apply_font(banner_v)
	banner_h.add_child(banner_v)
	
	var sleep_title = DeskTheme.create_label("睡魔度", 13, Color.WHITE, true)
	banner_v.add_child(sleep_title)
	
	var sleep_gauge = DeskTheme.create_gauge_bar(0.0, 100.0, DeskTheme.COLOR_SAFE, Vector2(240, 10))
	banner_v.add_child(sleep_gauge)
	hud_gauges["sleep_gauge"] = sleep_gauge
	hud_gauges["sleep_title"] = sleep_title
	
	var led_indicator = Panel.new()
	led_indicator.custom_minimum_size = Vector2(16, 16)
	led_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var led_style = StyleBoxFlat.new()
	led_style.bg_color = Color("8cff8c")
	led_style.corner_radius_top_left = 8; led_style.corner_radius_top_right = 8
	led_style.corner_radius_bottom_left = 8; led_style.corner_radius_bottom_right = 8
	led_indicator.add_theme_stylebox_override("panel", led_style)
	banner_h.add_child(led_indicator)
	hud_gauges["sleep_led"] = led_indicator
	
	next_burst_label = DeskTheme.create_label("安全レベル: 脳内すっきり、まだ引ける！", 15, DeskTheme.COLOR_SAFE, true)
	next_burst_label.add_theme_constant_override("outline_size", 4)
	next_burst_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.95))
	right_v.add_child(next_burst_label)
	
	button_box = HBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 32)
	right_v.add_child(button_box)
	
	var draw_btn = DeskTheme.create_button("カードを引く", Vector2(240, 72), DeskTheme.COLOR_SAFE, Color("2d928a"))
	draw_btn.pressed.connect(_on_draw_pressed)
	button_box.add_child(draw_btn)
	
	var stop_btn = DeskTheme.create_button("勉強を切り上げる", Vector2(240, 72), DeskTheme.COLOR_BURST, Color("bd4f4f"))
	stop_btn.pressed.connect(_on_stop_pressed)
	button_box.add_child(stop_btn)
	
	vignette_node = Panel.new()
	vignette_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v_style = StyleBoxFlat.new()
	v_style.bg_color = Color(0, 0, 0, 0)
	v_style.draw_center = false
	v_style.border_width_left = 120; v_style.border_width_right = 120
	v_style.border_width_top = 120; v_style.border_width_bottom = 120
	v_style.border_color = Color(0, 0, 0, 0.6)
	v_style.shadow_color = Color(0, 0, 0, 0.8)
	v_style.shadow_size = 180
	v_style.shadow_offset = Vector2.ZERO
	vignette_node.add_theme_stylebox_override("panel", v_style)
	ctx.screen_content.add_child(vignette_node)
	vignette_node.modulate.a = 0.0
	
	DeskTheme.animate_entrance(notebook)
	_update_race_hud()

func _update_race_hud():
	var score = ctx.game_session.accumulated_score + ctx.game_session.current_score
	status_label.text = str(score)
	
	if hud_gauges.has("total_score_bar"):
		var data = hud_gauges["total_score_bar"]
		var ratio = clamp(float(score) / 200.0, 0.0, 1.0) # 最大200点想定
		var fill = data.get_child(0)
		var tw = fill.create_tween()
		tw.tween_property(fill, "offset_right", max(4.0, data.custom_minimum_size.x * ratio), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	var deck = ctx.game_session.deck
	# 旧アイテムインジケーターは廃止し、バフ状態をラベル等で表示する
	if hud_gauges.has("buff_label"):
		var buff_text = ""
		if deck.has_energy_drink_shield: buff_text += "[エナドリシールド] "
		if deck.next_card_double_score: buff_text += "[次カード2倍] "
		if deck.sticky_note_bonus_active: buff_text += "[付箋ボーナス予約] "
		if deck.cheat_sheet_count > 0: buff_text += "[カンペ ×%d] " % deck.cheat_sheet_count
		hud_gauges["buff_label"].text = buff_text
	
	var drawn_num = drawn_card_nodes.size()
	if hud_gauges.has("drawn_count"):
		hud_gauges["drawn_count"].text = "引いたカード: %d枚" % drawn_num
	if hud_gauges.has("remain_count"):
		hud_gauges["remain_count"].text = "山札: %d枚" % deck.deck.size()
		
	if is_instance_valid(history_box):
		for child in history_box.get_children():
			child.queue_free()
		for card in deck.drawn_cards:
			if not card.is_active: continue
			var badge = PanelContainer.new()
			var bg = StyleBoxFlat.new()
			bg.corner_radius_top_left = 6; bg.corner_radius_top_right = 6
			bg.corner_radius_bottom_left = 6; bg.corner_radius_bottom_right = 6
			bg.content_margin_left = 8; bg.content_margin_right = 8
			bg.content_margin_top = 2; bg.content_margin_bottom = 2
			
			var label_text = ""
			var label_color = Color.WHITE
			if card.item_type == Enums.ItemType.NORMAL:
				bg.bg_color = DeskTheme.COLOR_INK
				label_text = "+%d" % card.number
			else:
				bg.bg_color = Color("495057")
				label_text = "ア(%d)" % card.number
				
			badge.add_theme_stylebox_override("panel", bg)
			var lbl = DeskTheme.create_label(label_text, 12, label_color, true)
			badge.add_child(lbl)
			history_box.add_child(badge)
		
	_update_deck_stack_visual(deck.deck.size())
	
	var deck_cards = deck.deck
	var conflict_count = 0
	var total_deck = deck_cards.size()
	for c in deck_cards:
		for dc in deck.drawn_cards:
			if dc.is_active and dc.number == c.number:
				conflict_count += 1
				break
	var burst_prob = 0
	if total_deck > 0:
		burst_prob = int((float(conflict_count) / float(total_deck)) * 100.0)
		
	var style: StyleBoxFlat = burst_warning_banner.get_theme_stylebox("panel")
	var gauge_color = DeskTheme.COLOR_SAFE
	
	if hud_gauges.has("sleep_led"):
		var led = hud_gauges["sleep_led"] as Panel
		if is_instance_valid(led):
			if led.has_meta("led_tween"):
				var lt = led.get_meta("led_tween") as Tween
				if lt and lt.is_valid(): lt.kill()
			led.modulate.a = 1.0
	
	var led_color = Color("8cff8c")
	var led_pulse = false
	var led_pulse_speed = 0.25
	
	if burst_prob >= 50:
		style.bg_color = DeskTheme.COLOR_BLUFF_RED
		gauge_color = DeskTheme.COLOR_BLUFF_RED
		next_burst_label.text = "警告: 限界寸前！いつ寝落ちしてもおかしくない！"
		next_burst_label.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
		if hud_gauges.has("sleep_title"): hud_gauges["sleep_title"].text = "睡魔度: 限界寸前！"
		led_color = DeskTheme.COLOR_BLUFF_RED
		led_pulse = true
		led_pulse_speed = 0.15
	elif burst_prob >= 25:
		style.bg_color = DeskTheme.COLOR_ACCENT_GOLD
		gauge_color = DeskTheme.COLOR_ACCENT_GOLD
		next_burst_label.text = "注意: 限界が近い... そろそろ引き際か？"
		next_burst_label.add_theme_color_override("font_color", Color("a87d00"))
		if hud_gauges.has("sleep_title"): hud_gauges["sleep_title"].text = "睡魔度: 眠気あり"
		led_color = DeskTheme.COLOR_ACCENT_GOLD
		led_pulse = true
		led_pulse_speed = 0.40
	else:
		style.bg_color = DeskTheme.COLOR_SAFE
		gauge_color = DeskTheme.COLOR_SAFE
		next_burst_label.text = "安全レベル: まだ睡魔は感じない！"
		next_burst_label.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)
		if hud_gauges.has("sleep_title"): hud_gauges["sleep_title"].text = "睡魔度: 安全"
		led_color = Color("8cff8c")
		
	if hud_gauges.has("sleep_led"):
		var led = hud_gauges["sleep_led"] as Panel
		if is_instance_valid(led):
			var led_style = StyleBoxFlat.new()
			led_style.bg_color = led_color
			led_style.corner_radius_top_left = 8; led_style.corner_radius_top_right = 8
			led_style.corner_radius_bottom_left = 8; led_style.corner_radius_bottom_right = 8
			led.add_theme_stylebox_override("panel", led_style)
			if led_pulse:
				var lt = led.create_tween().set_loops()
				lt.tween_property(led, "modulate:a", 0.15, led_pulse_speed).set_trans(Tween.TRANS_SINE)
				lt.tween_property(led, "modulate:a", 1.0, led_pulse_speed).set_trans(Tween.TRANS_SINE)
				led.set_meta("led_tween", lt)
	
	if hud_gauges.has("sleep_gauge"):
		var sg = hud_gauges["sleep_gauge"]
		var sg_fill = sg.get_child(0)
		var sg_ratio = clamp(float(burst_prob) / 100.0, 0.0, 1.0)
		var sg_tw = sg_fill.create_tween()
		sg_tw.tween_property(sg_fill, "offset_right", max(4.0, 280.0 * sg_ratio), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var sg_style = sg_fill.get_theme_stylebox("panel").duplicate()
		sg_style.bg_color = gauge_color
		sg_fill.add_theme_stylebox_override("panel", sg_style)
	
	if heartbeat_tween != null:
		heartbeat_tween.kill()
		heartbeat_tween = null
	if vignette_tween != null:
		vignette_tween.kill()
		vignette_tween = null
	
	if burst_prob >= 80:
		if is_instance_valid(active_notebook):
			active_notebook.pivot_offset = active_notebook.size / 2.0
			heartbeat_tween = active_notebook.create_tween().set_loops()
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.02, 1.02), 0.07).set_trans(Tween.TRANS_CUBIC)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_CUBIC)
			heartbeat_tween.tween_interval(0.06)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.015, 1.015), 0.07).set_trans(Tween.TRANS_CUBIC)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_CUBIC)
			heartbeat_tween.tween_interval(0.70)
			
		if is_instance_valid(vignette_node):
			vignette_node.modulate.a = 0.5
			vignette_tween = vignette_node.create_tween().set_loops()
			vignette_tween.tween_property(vignette_node, "modulate:a", 0.85, 0.07).set_trans(Tween.TRANS_CUBIC)
			vignette_tween.tween_property(vignette_node, "modulate:a", 0.5, 0.08).set_trans(Tween.TRANS_CUBIC)
			vignette_tween.tween_interval(0.06)
			vignette_tween.tween_property(vignette_node, "modulate:a", 0.75, 0.07).set_trans(Tween.TRANS_CUBIC)
			vignette_tween.tween_property(vignette_node, "modulate:a", 0.5, 0.08).set_trans(Tween.TRANS_CUBIC)
			vignette_tween.tween_interval(0.70)
	else:
		if is_instance_valid(active_notebook):
			active_notebook.create_tween().tween_property(active_notebook, "scale", Vector2.ONE, 0.15)
		if is_instance_valid(vignette_node):
			vignette_node.create_tween().tween_property(vignette_node, "modulate:a", 0.0, 0.25)
		next_burst_label.scale = Vector2.ONE

func _set_action_buttons_enabled(enabled: bool):
	if is_instance_valid(button_box):
		for child in button_box.get_children():
			if child is Button: child.disabled = not enabled

func _on_draw_pressed():
	_set_action_buttons_enabled(false)
	var res = ctx.game_session.draw_card()
	var card = res["card"]
	if card == null:
		_set_action_buttons_enabled(true)
		return
	if ctx.audio_manager: ctx.audio_manager.play_se("draw")
	
	var card_node: Control
	if card.item_type == Enums.ItemType.NORMAL:
		card_node = DeskTheme.create_subject_card_large(0, card.number)
	else:
		card_node = DeskTheme.create_item_card_large(card.item_type)
		# TODO: アイテムカードの数字が見えるようにDeskThemeも後で修正する
	card_node.set_meta("card_data", card)
	
	var back_tex = TextureRect.new()
	back_tex.name = "BackTex"
	back_tex.texture = DeskTheme.CARD_BACK
	back_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_node.add_child(back_tex)
	
	card_container.add_child(card_node)
	drawn_card_nodes.append(card_node)
	
	var num_cards = drawn_card_nodes.size()
	var card_scale_factor = 1.0 if num_cards <= 5 else max(0.65, 1.0 - (num_cards - 5) * 0.05)
	var card_sz = Vector2(190, 260) * card_scale_factor
	
	var view_size = ctx.screen_content.get_viewport_rect().size
	var start_pos = Vector2(view_size.x * 0.85, view_size.y * 0.25)
	
	card_node.position = start_pos - card_container.global_position
	card_node.rotation_degrees = -45.0
	card_node.scale = Vector2(0.2, 0.2)
	card_node.modulate.a = 0.0
	card_node.pivot_offset = Vector2(190, 260) / 2.0
	
	await _rearrange_drawn_cards(true)
	if ctx.audio_manager: ctx.audio_manager.play_se("place")
	
	_update_race_hud()

	if card.item_type != Enums.ItemType.NORMAL:
		ctx.game_session.apply_item_effect(card.item_type)
		_update_race_hud()
		
		if card.item_type == Enums.ItemType.THICK_BOOK:
			ToastOverlayScript.show_toast(ctx.ui_root, "分厚い参考書！追加で2枚引く！", Color("845ef7"))
			await ctx.screen_content.get_tree().create_timer(0.6).timeout
			_on_draw_pressed()
			await ctx.screen_content.get_tree().create_timer(0.6).timeout
			_on_draw_pressed()
			return
			
		elif card.item_type == Enums.ItemType.ERASER:
			ToastOverlayScript.show_toast(ctx.ui_root, "消しゴム！最新のカードを無効化", Color("adb5bd"))
			_refresh_drawn_cards_visuals()
			
	if res["burst"]:
		await _trigger_burst_sequence()
		return
	elif res["prevented"]:
		ToastOverlayScript.show_toast(ctx.ui_root, "エナドリ効果！バーストを回避！", Color("fcc419"))
		_update_race_hud()
	
	if not res["burst"] and not res["prevented"]:
		var combo_num = drawn_card_nodes.size()
		if combo_num >= 2:
			var combo_badge = DeskTheme.create_floating_badge("%d COMBO!" % combo_num, DeskTheme.COLOR_SAFE, 20)
			combo_badge.global_position = card_node.global_position + Vector2(card_sz.x / 2.0 - combo_badge.size.x / 2.0, -35.0)
			play_desk.add_child(combo_badge)
			var b_tw = combo_badge.create_tween()
			b_tw.tween_property(combo_badge, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_CUBIC)
			b_tw.tween_property(combo_badge, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)
			b_tw.tween_interval(0.8)
			b_tw.tween_property(combo_badge, "modulate:a", 0.0, 0.25)
			b_tw.tween_callback(combo_badge.queue_free)
	_step_rival_simulation()
	_set_action_buttons_enabled(true)

func _refresh_drawn_cards_visuals():
	for node in drawn_card_nodes:
		if is_instance_valid(node):
			var data = node.get_meta("card_data")
			if data and not data.is_active:
				node.modulate.a = 0.3 # 無効化されたカードをグレーアウト

func _rearrange_drawn_cards(animate: bool = true):
	var num_cards = drawn_card_nodes.size()
	if num_cards == 0: return
	
	var desk_sz = play_desk.size
	if desk_sz.x < 100 or desk_sz.y < 100: desk_sz = Vector2(600, 460)
	var center = desk_sz / 2.0
	center.x += 60.0
	
	var card_spacing = 52.0 if num_cards <= 5 else max(38.0, 240.0 / float(num_cards))
	var card_scale_factor = 1.0 if num_cards <= 5 else max(0.65, 1.0 - (num_cards - 5) * 0.05)
	var card_sz = Vector2(190, 260) * card_scale_factor
	
	var last_tween: Tween = null
	for i in range(num_cards):
		var node = drawn_card_nodes[i]
		if not is_instance_valid(node): continue
		var item_offset_x = (i * card_spacing) - (card_spacing * float(num_cards - 1)) / 2.0
		var item_offset_y = -abs(item_offset_x) * 0.08
		var target_pos = center + Vector2(item_offset_x, item_offset_y) - card_sz / 2.0
		var target_rot = (i - (num_cards - 1) / 2.0) * (20.0 / max(float(num_cards), 1.0))
		target_rot = clamp(target_rot, -12.0, 12.0)
		
		node.pivot_offset = Vector2(190, 260) / 2.0
		
		if animate:
			var tw = node.create_tween().set_parallel(true)
			last_tween = tw
			var has_back = node.has_node("BackTex")
			if i == num_cards - 1 and has_back:
				var back_node = node.get_node("BackTex")
				tw.tween_property(node, "position", target_pos, 0.35).set_trans(Tween.TRANS_CUBIC)
				tw.tween_property(node, "rotation_degrees", target_rot, 0.35).set_trans(Tween.TRANS_BACK)
				tw.tween_property(node, "modulate:a", 1.0, 0.15)
				var flip_tw = node.create_tween()
				flip_tw.tween_property(node, "scale", Vector2(0.0, card_scale_factor * 1.2), 0.18).set_trans(Tween.TRANS_SINE)
				flip_tw.tween_callback(func(): if is_instance_valid(back_node): back_node.hide())
				flip_tw.tween_property(node, "scale", Vector2(card_scale_factor, card_scale_factor), 0.15).set_trans(Tween.TRANS_SINE)
			else:
				tw.tween_property(node, "position", target_pos, 0.28).set_trans(Tween.TRANS_CUBIC)
				tw.tween_property(node, "scale", Vector2(card_scale_factor, card_scale_factor), 0.28).set_trans(Tween.TRANS_CUBIC)
				tw.tween_property(node, "rotation_degrees", target_rot, 0.28).set_trans(Tween.TRANS_CUBIC)
		else:
			node.position = target_pos
			node.scale = Vector2(card_scale_factor, card_scale_factor)
			node.rotation_degrees = target_rot
			
	if last_tween and last_tween.is_valid():
		await last_tween.finished

func _trigger_eraser_evasion_sequence(new_card_node: Control, _weight: int):
	if ctx.audio_manager: ctx.audio_manager.play_se("combo")
	drawn_card_nodes.erase(new_card_node)
	new_card_node.queue_free()
	_rearrange_drawn_cards(true)
	_update_race_hud()
	_set_action_buttons_enabled(true)

func _trigger_burst_sequence():
	if ctx.audio_manager: ctx.audio_manager.play_se("burst")
	if is_instance_valid(button_box): button_box.hide()
	
	var banner = DeskTheme.create_floating_badge("【 寝落ち（バースト）！】", DeskTheme.COLOR_BLUFF_RED, 28)
	banner.anchor_left = 0.5; banner.anchor_top = 0.5; banner.anchor_right = 0.5; banner.anchor_bottom = 0.5
	banner.offset_left = -300; banner.offset_top = -140; banner.offset_right = 300; banner.offset_bottom = -60
	ctx.screen_content.add_child(banner)
	banner.scale = Vector2(4.0, 4.0)
	banner.modulate.a = 0.0
	banner.pivot_offset = banner.size / 2.0
	
	var banner_tw = banner.create_tween().set_parallel(true)
	banner_tw.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	banner_tw.tween_property(banner, "modulate:a", 1.0, 0.1)
	
	await ctx.screen_content.get_tree().create_timer(1.0).timeout
	
	ctx.game_session.burst_period()
	if is_instance_valid(banner): banner.queue_free()
	
	var final_score = ctx.game_session.stop_and_report()
	phase_completed.emit({"score": final_score})

func _on_stop_pressed():
	if ctx.audio_manager: ctx.audio_manager.play_se("click")
	var gained = ctx.game_session.current_score
	ctx.game_session.stop_period()
	
	var display_hour = ctx.game_session.current_hour if ctx.game_session else 1
	ToastOverlayScript.show_toast(ctx.ui_root, "%d時間目の勉強を切り上げ、+%d点獲得！" % [display_hour, gained], Color("81c784"))
	
	var final_score = ctx.game_session.stop_and_report()
	phase_completed.emit({"score": final_score})

func _reset_for_new_hour():
	for node in drawn_card_nodes:
		if is_instance_valid(node): node.queue_free()
	drawn_card_nodes.clear()
	
	if is_instance_valid(hour_label):
		var badge_lbl = hour_label.find_child("BadgeLabel", true, false)
		if badge_lbl: badge_lbl.text = "%d時間目" % current_hour
		
	ToastOverlayScript.show_toast(ctx.ui_root, "%d時間目の勉強が始まりました！" % current_hour, DeskTheme.COLOR_SAFE)
	if is_instance_valid(button_box): button_box.show()
	_update_race_hud()
	_set_action_buttons_enabled(true)

func _are_buttons_enabled() -> bool:
	if is_instance_valid(button_box) and button_box.get_child_count() > 0:
		var btn = button_box.get_child(0) as Button
		if is_instance_valid(btn): return not btn.disabled
	return false

func _input(event: InputEvent):
	if not _are_buttons_enabled(): return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_SPACE:
			ctx.ui_root.get_viewport().set_input_as_handled()
			_on_draw_pressed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			ctx.ui_root.get_viewport().set_input_as_handled()
			_on_stop_pressed()

func _step_rival_simulation():
	if not is_instance_valid(ctx) or not ctx.game_session or not ctx.game_session.ai_manager:
		return
		
	# 演出としてたまにライバルの進捗をトーストで通知する
	var daily_res = ctx.game_session.ai_manager.get_daily_results()
	var names = daily_res.keys()
	if names.is_empty(): return
	
	var r_name = names[randi() % names.size()]
	var status = daily_res[r_name].get("status", "playing")
	
	if randf() < 0.15:
		if status == "burst":
			ToastOverlayScript.show_toast(ctx.ui_root, "%s から寝息が聞こえる..." % r_name, Color("ff8787"))
		elif status == "stopped":
			ToastOverlayScript.show_toast(ctx.ui_root, "%s はペンを置いたようだ。" % r_name, DeskTheme.COLOR_SAFE)

func _update_item_indicators(item_type: int, remaining: int) -> void:
	var container = item_count_labels.get(item_type) as HBoxContainer
	if not is_instance_valid(container): return
	var dots = container.get_children()
	for idx in range(dots.size()):
		var dot = dots[idx] as Panel
		if not is_instance_valid(dot): continue
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.corner_radius_top_left = 7; style.corner_radius_top_right = 7
		style.corner_radius_bottom_left = 7; style.corner_radius_bottom_right = 7
		if idx < remaining:
			style.bg_color = DeskTheme.COLOR_SAFE if item_type == 1 else Color("4a7de0") if item_type == 2 else DeskTheme.COLOR_ACCENT_GOLD
		else:
			style.bg_color = Color("c8c4bc", 0.35)
		dot.add_theme_stylebox_override("panel", style)

func _update_deck_stack_visual(remaining: int) -> void:
	var stack = hud_gauges.get("deck_stack") as Control
	if not is_instance_valid(stack): return
	for child in stack.get_children(): child.queue_free()
	if remaining > 0:
		var layers = 1
		if remaining >= 10: layers = 3
		elif remaining >= 5: layers = 2
		for i in range(layers):
			var card_img = TextureRect.new()
			card_img.texture = DeskTheme.CARD_BACK
			card_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			card_img.size = Vector2(40, 55)
			card_img.position = Vector2(-i * 1.5, -i * 2.5)
			stack.add_child(card_img)
