# scripts/ui/phases/ChickenRacePhase.gd
class_name ChickenRacePhase
extends RefCounted

const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")

signal phase_completed(scores_data: Dictionary)

var ctx: RefCounted

# UI要素
var active_notebook: Control
var hud_notebook: Control
var status_label: Label
var subject_gauges: Dictionary = {}
var item_count_labels: Dictionary = {}
var play_desk: Control
var card_container: Control
var burst_warning_banner: Panel
var next_burst_label: Label
var button_box: HBoxContainer
var drawn_card_nodes: Array = []
var heartbeat_tween: Tween
var camera_shake_offset: Vector2 = Vector2.ZERO
var vignette_node: Control
var vignette_tween: Tween
var rival_sim_states: Dictionary = {}

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
	hud_v.add_theme_constant_override("separation", 14)
	DeskTheme.apply_font(hud_v)
	hud_notebook.add_child(hud_v)
	
	hud_v.add_child(DeskTheme.create_label("[ 本日の学習ノート ]", 32, DeskTheme.COLOR_INK, true))
	
	var score_h = HBoxContainer.new()
	score_h.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_v.add_child(score_h)
	score_h.add_child(DeskTheme.create_label("合計点: ", 22, DeskTheme.COLOR_INK, true))
	status_label = DeskTheme.create_label("0", 54, DeskTheme.COLOR_BLUFF_RED, true)
	score_h.add_child(status_label)
	
	subject_gauges.clear()
	for s in range(5):
		var s_row = HBoxContainer.new()
		s_row.add_theme_constant_override("separation", 12)
		hud_v.add_child(s_row)
		
		var mini_icon = DeskTheme.create_icon_rect(DeskTheme.subject_texture(s), Vector2(36, 36))
		s_row.add_child(mini_icon)
		
		var name_lbl = DeskTheme.create_label(DeskTheme.subject_name(s), 18, DeskTheme.subject_color(s), true)
		name_lbl.custom_minimum_size = Vector2(56, 0)
		s_row.add_child(name_lbl)
		
		var bar = DeskTheme.create_gauge_bar(0.0, 20.0, DeskTheme.subject_color(s), Vector2(200, 22))
		s_row.add_child(bar)
		
		var val_lbl = DeskTheme.create_label("0点", 18, DeskTheme.COLOR_INK, true)
		s_row.add_child(val_lbl)
		subject_gauges[s] = {"bar": bar, "label": val_lbl}
		
	var items_v = VBoxContainer.new()
	items_v.add_theme_constant_override("separation", 12)
	hud_v.add_child(items_v)
	item_count_labels.clear()
	for type in range(1, 4):
		var item_h = HBoxContainer.new()
		item_h.add_theme_constant_override("separation", 12)
		items_v.add_child(item_h)
		var item_tex = DeskTheme.item_texture(type)
		if item_tex:
			var icon = DeskTheme.create_icon_rect(item_tex, Vector2(32, 32))
			item_h.add_child(icon)
		var name_lbl = DeskTheme.create_label("消しゴム(回避)" if type == 1 else "ペン(+1倍)" if type == 2 else "定規(+5点)", 18, DeskTheme.COLOR_INK, true)
		item_h.add_child(name_lbl)
		var count_lbl = DeskTheme.create_label("残り:2枚", 16, DeskTheme.COLOR_MUTED, true)
		item_h.add_child(count_lbl)
		item_count_labels[type] = count_lbl
		
	var hud_rival_note = DeskTheme.create_sticky_note(Color("f0f8ff"), Vector2(360, 180), -1.0)
	hud_v.add_child(hud_rival_note)
	var hr_v = VBoxContainer.new()
	hr_v.add_theme_constant_override("separation", 8)
	hud_rival_note.add_child(hr_v)
	
	if Global.play_count == 0:
		hr_v.add_child(DeskTheme.create_label("[ 1日目の目標 ]", 18, Color("2b5a9e"), true))
		var msg = "まずは各教科を満遍なく勉強して、本日の学習報告（初投稿）を完了させよう！寝落ちに気をつけて！"
		var lbl = DeskTheme.create_label(msg, 14, DeskTheme.COLOR_INK, true)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hr_v.add_child(lbl)
	else:
		hr_v.add_child(DeskTheme.create_label("[ ライバル暫定トップ ]", 18, Color("2b5a9e"), true))
		var top_scores = ctx.backend_manager.get_subject_top_scores()
		var top_str = ""
		for s in range(5):
			var top_info = top_scores[s]
			top_str += "%s:%d点  " % [DeskTheme.subject_name(s), top_info["score"]]
		var lbl = DeskTheme.create_label(top_str, 15, DeskTheme.COLOR_INK, true)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hr_v.add_child(lbl)
	
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
	
	# カード情報バー（引いた枚数・残り山札）
	var card_info_h = HBoxContainer.new()
	card_info_h.alignment = BoxContainer.ALIGNMENT_CENTER
	card_info_h.add_theme_constant_override("separation", 24)
	right_v.add_child(card_info_h)
	
	var drawn_count_lbl = DeskTheme.create_label("引いたカード: 0枚", 14, DeskTheme.COLOR_INK, true)
	card_info_h.add_child(drawn_count_lbl)
	subject_gauges["drawn_count"] = drawn_count_lbl
	
	var remain_lbl = DeskTheme.create_label("残り山札: --枚", 14, DeskTheme.COLOR_MUTED, true)
	card_info_h.add_child(remain_lbl)
	subject_gauges["remain_count"] = remain_lbl
	
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
	
	var banner_v = VBoxContainer.new()
	banner_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner_v.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_v.add_theme_constant_override("separation", 4)
	DeskTheme.apply_font(banner_v)
	burst_warning_banner.add_child(banner_v)
	
	var sleep_title = DeskTheme.create_label("睡魔度", 13, Color.WHITE, true)
	banner_v.add_child(sleep_title)
	
	var sleep_gauge = DeskTheme.create_gauge_bar(0.0, 100.0, DeskTheme.COLOR_SAFE, Vector2(280, 10))
	banner_v.add_child(sleep_gauge)
	subject_gauges["sleep_gauge"] = sleep_gauge
	subject_gauges["sleep_title"] = sleep_title
	
	next_burst_label = DeskTheme.create_label("安全レベル: 脳内すっきり、まだ引ける！", 13, DeskTheme.COLOR_SAFE, true)
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
	
	# Vignette (睡魔エフェクト) の追加
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
	status_label.text = str(ctx.game_session.current_score)
	for s in range(5):
		var score = ctx.game_session.subject_scores[s]
		var data = subject_gauges[s]
		var ratio = clamp(float(score) / 20.0, 0.0, 1.0)
		var fill = data["bar"].get_child(0)
		var tw = fill.create_tween()
		tw.tween_property(fill, "offset_right", max(4.0, data["bar"].custom_minimum_size.x * ratio), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		data["label"].text = "%d点" % score
		
	var deck = ctx.game_session.deck
	var num_erasers = deck.remaining_erasers
	var num_pens = 2
	var num_rulers = 2
	for c in deck.drawn_cards:
		if c.item_type == 2: num_pens -= 1
		elif c.item_type == 3: num_rulers -= 1
	item_count_labels[1].text = "残り:%d枚" % num_erasers
	item_count_labels[2].text = "残り:%d枚" % max(0, num_pens)
	item_count_labels[3].text = "残り:%d枚" % max(0, num_rulers)
	
	# カード枚数＆残り山札の更新
	var drawn_num = drawn_card_nodes.size()
	if subject_gauges.has("drawn_count"):
		subject_gauges["drawn_count"].text = "引いたカード: %d枚" % drawn_num
	if subject_gauges.has("remain_count"):
		subject_gauges["remain_count"].text = "残り山札: %d枚" % deck.deck.size()
	
	var deck_cards = deck.deck
	var conflict_count = 0
	var total_deck = deck_cards.size()
	for c in deck_cards:
		if c.item_type == 0:
			for dc in deck.drawn_cards:
				if dc.item_type == 0 and dc.weight == c.weight:
					conflict_count += 1
					break
	var burst_prob = 0
	if total_deck > 0:
		burst_prob = int((float(conflict_count) / float(total_deck)) * 100.0)
		
	# 睡魔ゲージのビジュアル更新
	var style: StyleBoxFlat = burst_warning_banner.get_theme_stylebox("panel")
	var gauge_color = DeskTheme.COLOR_SAFE
	if burst_prob >= 50:
		style.bg_color = DeskTheme.COLOR_BLUFF_RED
		gauge_color = DeskTheme.COLOR_BLUFF_RED
		next_burst_label.text = "警告: 限界寸前！いつ寝落ちしてもおかしくない！"
		next_burst_label.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
		if subject_gauges.has("sleep_title"):
			subject_gauges["sleep_title"].text = "睡魔度 (%d%%) - 限界!" % burst_prob
	elif burst_prob >= 25:
		style.bg_color = DeskTheme.COLOR_ACCENT_GOLD
		gauge_color = DeskTheme.COLOR_ACCENT_GOLD
		next_burst_label.text = "注意: 限界が近い... そろそろ引き際か？"
		next_burst_label.add_theme_color_override("font_color", Color("a87d00"))
		if subject_gauges.has("sleep_title"):
			subject_gauges["sleep_title"].text = "睡魔度 (%d%%) - 眠気" % burst_prob
	else:
		style.bg_color = DeskTheme.COLOR_SAFE
		gauge_color = DeskTheme.COLOR_SAFE
		next_burst_label.text = "安全レベル: まだ睡魔は感じない！"
		next_burst_label.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)
		if subject_gauges.has("sleep_title"):
			subject_gauges["sleep_title"].text = "睡魔度 (%d%%)" % burst_prob
	
	# 睡魔ゲージバーの塗りを更新
	if subject_gauges.has("sleep_gauge"):
		var sg = subject_gauges["sleep_gauge"]
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
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.02, 1.02), 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			heartbeat_tween.tween_interval(0.06)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.015, 1.015), 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			heartbeat_tween.tween_property(active_notebook, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			heartbeat_tween.tween_interval(0.70)
			
		if is_instance_valid(vignette_node):
			vignette_node.modulate.a = 0.5
			vignette_tween = vignette_node.create_tween().set_loops()
			vignette_tween.tween_property(vignette_node, "modulate:a", 0.85, 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			vignette_tween.tween_property(vignette_node, "modulate:a", 0.5, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			vignette_tween.tween_interval(0.06)
			vignette_tween.tween_property(vignette_node, "modulate:a", 0.75, 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			vignette_tween.tween_property(vignette_node, "modulate:a", 0.5, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			vignette_tween.tween_interval(0.70)
			
		next_burst_label.pivot_offset = next_burst_label.size / 2.0
		var lbl_tw = next_burst_label.create_tween()
		lbl_tw.tween_property(next_burst_label, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_SINE)
		lbl_tw.tween_property(next_burst_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_SINE)
		lbl_tw.set_loops()
	else:
		if is_instance_valid(active_notebook):
			var tw_reset = active_notebook.create_tween()
			tw_reset.tween_property(active_notebook, "scale", Vector2.ONE, 0.15)
			
		if is_instance_valid(vignette_node):
			vignette_tween = vignette_node.create_tween()
			var target_alpha = 0.0
			if burst_prob >= 50:
				target_alpha = 0.4
			elif burst_prob >= 25:
				target_alpha = 0.15
			vignette_tween.tween_property(vignette_node, "modulate:a", target_alpha, 0.25).set_trans(Tween.TRANS_SINE)
			
		next_burst_label.scale = Vector2.ONE

func _set_action_buttons_enabled(enabled: bool):
	if is_instance_valid(button_box):
		for child in button_box.get_children():
			if child is Button:
				child.disabled = not enabled

func _on_draw_pressed():
	_set_action_buttons_enabled(false)
	var res = ctx.game_session.draw_card()
	var card = res["card"]
	if card == null:
		_set_action_buttons_enabled(true)
		return
	if ctx.audio_manager: ctx.audio_manager.play_se("draw")
	
	var card_node: Control
	if card.item_type == 0:
		card_node = DeskTheme.create_subject_card_large(card.subject, card.weight)
	else:
		card_node = DeskTheme.create_item_card_large(card.item_type)
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
	var start_pos = Vector2(view_size.x / 2.0, view_size.y) - card_sz / 2.0
	if is_instance_valid(button_box) and button_box.get_child_count() > 0:
		var draw_btn = button_box.get_child(0) as Button
		if is_instance_valid(draw_btn):
			start_pos = draw_btn.global_position + draw_btn.size / 2.0 - card_sz / 2.0
	
	card_node.position = start_pos - card_container.global_position
	card_node.rotation_degrees = -45.0
	card_node.scale = Vector2(0.2, 0.2)
	card_node.modulate.a = 0.0
	card_node.pivot_offset = Vector2(190, 260) / 2.0
	
	# 場にあるすべてのカードを並び替えて整列させる
	await _rearrange_drawn_cards(true)
	if ctx.audio_manager: ctx.audio_manager.play_se("place")
	
	_update_race_hud()

	if card.item_type == 3:
		_trigger_ruler_effect(card_node)
		return
	
	if res["burst"]:
		await _trigger_burst_sequence()
		return
	elif res["erased"]:
		await _trigger_eraser_evasion_sequence(card_node, card.weight)
	
	if not res["burst"] and not res["erased"]:
		var combo_num = drawn_card_nodes.size()
		if combo_num >= 2:
			var combo_badge = DeskTheme.create_floating_badge("%d COMBO!" % combo_num, DeskTheme.subject_color(card.subject) if card.item_type == 0 else DeskTheme.COLOR_SAFE, 20)
			combo_badge.global_position = card_node.global_position + Vector2(card_sz.x / 2.0 - combo_badge.size.x / 2.0, -35.0)
			play_desk.add_child(combo_badge)
			combo_badge.pivot_offset = combo_badge.size / 2.0
			combo_badge.scale = Vector2(0.1, 0.1)
			var b_tw = combo_badge.create_tween()
			b_tw.tween_property(combo_badge, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			b_tw.parallel().tween_property(combo_badge, "rotation_degrees", randf_range(-12.0, 12.0), 0.12)
			b_tw.tween_property(combo_badge, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)
			b_tw.tween_interval(0.8)
			b_tw.tween_property(combo_badge, "modulate:a", 0.0, 0.25)
			b_tw.tween_callback(combo_badge.queue_free)
	_step_rival_simulation()
	_set_action_buttons_enabled(true)

func _rearrange_drawn_cards(animate: bool = true):
	var num_cards = drawn_card_nodes.size()
	if num_cards == 0: return
	
	var desk_sz = play_desk.size
	if desk_sz.x < 100 or desk_sz.y < 100:
		desk_sz = Vector2(600, 460)
	var center = desk_sz / 2.0
	center.x += 60.0
	
	var card_spacing = 38.0 if num_cards <= 5 else max(18.0, 180.0 / float(num_cards))
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
				tw.tween_property(node, "position", target_pos, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tw.tween_property(node, "rotation_degrees", target_rot, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(node, "modulate:a", 1.0, 0.15)
				
				var flip_tw = node.create_tween()
				flip_tw.tween_property(node, "scale", Vector2(0.0, card_scale_factor * 1.2), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				flip_tw.tween_callback(func():
					if is_instance_valid(back_node): back_node.hide()
				)
				flip_tw.tween_property(node, "scale", Vector2(card_scale_factor, card_scale_factor), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			else:
				tw.tween_property(node, "position", target_pos, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tw.tween_property(node, "scale", Vector2(card_scale_factor, card_scale_factor), 0.28).set_trans(Tween.TRANS_CUBIC)
				tw.tween_property(node, "rotation_degrees", target_rot, 0.28).set_trans(Tween.TRANS_CUBIC)
		else:
			node.position = target_pos
			node.scale = Vector2(card_scale_factor, card_scale_factor)
			node.rotation_degrees = target_rot
			
	if last_tween and last_tween.is_valid():
		await last_tween.finished

func _trigger_ruler_effect(card_node: Control):
	if ctx.audio_manager: ctx.audio_manager.play_se("combo")
	var bounce = card_node.create_tween()
	bounce.tween_property(card_node, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_CUBIC)
	bounce.tween_property(card_node, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	button_box.hide()
	var overlay
	overlay = DeskTheme.create_dialog_overlay(ctx.screen_content, "📏 定規でスコア補強！", func(vbox: VBoxContainer):
		# 目盛りを視認性の良い明るい木目調に変更
		var ticks_top = DeskTheme.create_label("| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |", 12, Color("ebd4be"), true)
		ticks_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(ticks_top)
		vbox.move_child(ticks_top, 0)
		
		# 黒板上の説明テキストをチョークホワイトに変更
		vbox.add_child(DeskTheme.create_label("好きな教科を1つ選んでスコアを「＋5点」補強できます。", 16, DeskTheme.COLOR_CHALK_WHITE, true))
		
		var grid = GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 12)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER # グリッドを中央寄せ！
		vbox.add_child(grid)
		
		for s in range(5):
			var btn = DeskTheme.create_button(DeskTheme.subject_name(s), Vector2(110, 56), DeskTheme.subject_color(s), DeskTheme.subject_color(s).darkened(0.1))
			btn.pivot_offset = Vector2(55, 28)
			btn.pressed.connect(func():
				if ctx.audio_manager: ctx.audio_manager.play_se("place")
				var btn_tw = btn.create_tween()
				btn_tw.tween_property(btn, "scale", Vector2(0.85, 0.85), 0.08)
				btn_tw.chain().tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
				await btn_tw.finished
				
				# GameSessionの同期メソッドを使用！
				ctx.game_session.apply_ruler_bonus(s)
				_update_race_hud()
				
				var node = vbox
				while node and not node is ColorRect: node = node.get_parent()
				if node: node.queue_free()
				button_box.show()
				_set_action_buttons_enabled(true)
			)
			grid.add_child(btn)
			
		var ticks_bottom = DeskTheme.create_label("| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |", 12, Color("ebd4be"), true)
		ticks_bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(ticks_bottom)
	)
	
	var ruler_panel = overlay.get_child(0) as PanelContainer
	if is_instance_valid(ruler_panel):
		var ruler_style = StyleBoxFlat.new()
		ruler_style.bg_color = Color("dfd5b8")
		ruler_style.border_width_left = 6; ruler_style.border_width_right = 6
		ruler_style.border_width_top = 18; ruler_style.border_width_bottom = 18
		ruler_style.border_color = Color("8c6d4f")
		ruler_style.corner_radius_top_left = 8; ruler_style.corner_radius_top_right = 8
		ruler_style.corner_radius_bottom_left = 8; ruler_style.corner_radius_bottom_right = 8
		ruler_panel.add_theme_stylebox_override("panel", ruler_style)

func _trigger_eraser_evasion_sequence(new_card_node: Control, _weight: int):
	if ctx.audio_manager: ctx.audio_manager.play_se("combo")
	
	var eraser_img = TextureRect.new()
	eraser_img.texture = DeskTheme.ITEM_ERASER
	eraser_img.custom_minimum_size = Vector2(80, 80)
	eraser_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	eraser_img.position = new_card_node.position + new_card_node.size / 2.0 - Vector2(40, 40)
	eraser_img.pivot_offset = Vector2(40, 40)
	play_desk.add_child(eraser_img)
	
	var particle_count = 6
	var particles = []
	for p_i in range(particle_count):
		var part = ColorRect.new()
		part.color = Color("ffffff")
		part.custom_minimum_size = Vector2(randf_range(4, 8), randf_range(2, 4))
		part.position = new_card_node.position + new_card_node.size / 2.0 + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		part.pivot_offset = part.custom_minimum_size / 2.0
		part.rotation_degrees = randf_range(0, 360)
		part.modulate.a = 0.0
		play_desk.add_child(part)
		particles.append(part)
	
	var slide_tw = eraser_img.create_tween()
	var part_tw = ctx.screen_content.create_tween().set_parallel(true)
	var orig_x = eraser_img.position.x
	
	for w in range(3):
		slide_tw.tween_property(eraser_img, "position:x", orig_x - 24, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		slide_tw.tween_property(eraser_img, "rotation_degrees", 12.0, 0.07)
		slide_tw.tween_callback(func(): if ctx.audio_manager: ctx.audio_manager.play_se("click"))
		
		slide_tw.tween_property(eraser_img, "position:x", orig_x + 24, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		slide_tw.tween_property(eraser_img, "rotation_degrees", -12.0, 0.07)
		slide_tw.tween_callback(func(): if ctx.audio_manager: ctx.audio_manager.play_se("click"))
		
	slide_tw.set_parallel(true)
	slide_tw.tween_property(new_card_node, "modulate:a", 0.3, 0.42)
	
	for p_idx in range(particle_count):
		var part = particles[p_idx]
		part_tw.tween_property(part, "modulate:a", 1.0, 0.1)
		part_tw.tween_property(part, "position", part.position + Vector2(randf_range(-60, 60), randf_range(-30, 60)), 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		part_tw.tween_property(part, "rotation_degrees", part.rotation_degrees + randf_range(-90, 90), 0.42)
		part_tw.tween_property(part, "scale", Vector2(0.1, 0.1), 0.42).set_delay(0.2)
		
	await slide_tw.finished
	
	for part in particles:
		part.queue_free()
		
	var disappear = ctx.screen_content.create_tween().set_parallel(true)
	disappear.tween_property(new_card_node, "modulate:a", 0.0, 0.2)
	disappear.tween_property(new_card_node, "scale", Vector2(0.2, 0.2), 0.2)
	disappear.tween_property(eraser_img, "modulate:a", 0.0, 0.15)
	await disappear.finished
	
	drawn_card_nodes.erase(new_card_node)
	new_card_node.queue_free()
	eraser_img.queue_free()
	
	_rearrange_drawn_cards(true)
	_update_race_hud()

func _trigger_burst_sequence():
	if ctx.audio_manager: ctx.audio_manager.play_se("burst")
	if is_instance_valid(button_box):
		button_box.hide()
	
	var shake = ctx.screen_content.create_tween().set_loops(8)
	shake.tween_callback(func(): camera_shake_offset = Vector2(randf_range(-14, 14), randf_range(-14, 14)))
	shake.tween_interval(0.04)
	
	var has_cards = false
	for node in drawn_card_nodes:
		if is_instance_valid(node):
			has_cards = true
			break
			
	if is_instance_valid(hud_notebook) or has_cards:
		var hop_tw = ctx.screen_content.create_tween().set_parallel(true)
		if is_instance_valid(hud_notebook):
			hud_notebook.pivot_offset = hud_notebook.size / 2.0
			hop_tw.tween_property(hud_notebook, "position:y", hud_notebook.position.y - 25, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			hop_tw.tween_property(hud_notebook, "rotation_degrees", -2.0, 0.1)
		for node in drawn_card_nodes:
			if is_instance_valid(node):
				node.pivot_offset = node.size / 2.0
				hop_tw.tween_property(node, "position:y", node.position.y - 35, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				hop_tw.tween_property(node, "rotation_degrees", node.rotation_degrees + randf_range(-15, 15), 0.12)
				
		hop_tw.chain().set_parallel(true)
		if is_instance_valid(hud_notebook):
			hop_tw.tween_property(hud_notebook, "position:y", hud_notebook.position.y, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			hop_tw.tween_property(hud_notebook, "rotation_degrees", 0.0, 0.18)
		for node in drawn_card_nodes:
			if is_instance_valid(node):
				var orig_y = node.position.y
				hop_tw.tween_property(node, "position:y", orig_y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			
	if has_cards:
		var fade_black = ctx.screen_content.create_tween().set_parallel(true)
		for node in drawn_card_nodes:
			if is_instance_valid(node):
				fade_black.tween_property(node, "modulate", Color(0.25, 0.25, 0.45, 0.8), 0.4)
			
	var banner = DeskTheme.create_floating_badge("【 寝落ち（バースト）！】", DeskTheme.COLOR_BLUFF_RED, 28)
	banner.anchor_left = 0.5; banner.anchor_top = 0.5; banner.anchor_right = 0.5; banner.anchor_bottom = 0.5
	banner.offset_left = -300; banner.offset_top = -140; banner.offset_right = 300; banner.offset_bottom = -60
	if is_instance_valid(play_desk):
		play_desk.add_child(banner)
	else:
		ctx.screen_content.add_child(banner)
	banner.scale = Vector2(4.0, 4.0)
	banner.modulate.a = 0.0
	banner.pivot_offset = banner.size / 2.0
	
	var banner_tw = banner.create_tween()
	banner_tw.set_parallel(true)
	banner_tw.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	banner_tw.tween_property(banner, "modulate:a", 1.0, 0.1)
	banner_tw.tween_property(banner, "rotation_degrees", randf_range(-8.0, 8.0), 0.15)
	
	banner_tw.chain().tween_callback(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("place")
	)
	
	await ctx.screen_content.get_tree().create_timer(0.45).timeout
	camera_shake_offset = Vector2.ZERO
		
	var empty_scores = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	ctx.game_session.current_score = 0
	
	var dialog = PanelContainer.new()
	dialog.custom_minimum_size = Vector2(600, 280)
	dialog.anchor_left = 0.5; dialog.anchor_top = 0.5; dialog.anchor_right = 0.5; dialog.anchor_bottom = 0.5
	dialog.offset_left = -300; dialog.offset_top = -20; dialog.offset_right = 300; dialog.offset_bottom = 260
	
	var dialog_style = StyleBoxFlat.new()
	dialog_style.bg_color = Color("1e1610")
	dialog_style.border_width_left = 4; dialog_style.border_width_right = 4
	dialog_style.border_width_top = 4; dialog_style.border_width_bottom = 6
	dialog_style.border_color = DeskTheme.COLOR_BLUFF_RED
	dialog_style.corner_radius_top_left = 16; dialog_style.corner_radius_top_right = 16
	dialog_style.corner_radius_bottom_left = 16; dialog_style.corner_radius_bottom_right = 16
	dialog_style.shadow_color = Color(0, 0, 0, 0.6)
	dialog_style.shadow_size = 20
	dialog.add_theme_stylebox_override("panel", dialog_style)
	
	if is_instance_valid(play_desk):
		play_desk.add_child(dialog)
	else:
		ctx.screen_content.add_child(dialog)
		
	var dv = VBoxContainer.new()
	dv.add_theme_constant_override("separation", 16)
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dialog.add_child(dv)
	
	dv.add_child(DeskTheme.create_label("💤 睡魔に敗れて寝落ちした！", 22, DeskTheme.COLOR_BLUFF_RED, true))
	
	var msg = DeskTheme.create_label("勉強した記憶がすべて夢の彼方へ消え去ってしまった...\n(本日の獲得点数は すべて「0点」になります)", 14, Color("dfd5cb"))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(msg)
	
	var wake_btn = DeskTheme.create_button("【 🛏️ 目をこすって起きる (通知表へ進む) ➔ 】", Vector2(400, 56), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
	wake_btn.add_theme_font_size_override("font_size", 16)
	dv.add_child(wake_btn)
	
	wake_btn.pivot_offset = Vector2(200, 28)
	var pulse_tw = wake_btn.create_tween().set_loops()
	pulse_tw.tween_property(wake_btn, "scale", Vector2(1.04, 1.04), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse_tw.tween_property(wake_btn, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	wake_btn.pressed.connect(func():
		pulse_tw.kill()
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		dialog.queue_free()
		phase_completed.emit(empty_scores)
	)

func _on_stop_pressed():
	if ctx.audio_manager: ctx.audio_manager.play_se("click")
	var stamp = hud_notebook.create_tween()
	stamp.tween_property(hud_notebook, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_CUBIC)
	stamp.tween_property(hud_notebook, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)
	if ctx.audio_manager: ctx.audio_manager.play_se("combo")
	await stamp.finished
	var scores = ctx.game_session.stop_and_report()
	phase_completed.emit(scores)

func _are_buttons_enabled() -> bool:
	if is_instance_valid(button_box) and button_box.get_child_count() > 0:
		var btn = button_box.get_child(0) as Button
		if is_instance_valid(btn):
			return not btn.disabled
	return false

func _input(event: InputEvent):
	if not _are_buttons_enabled():
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_SPACE:
			ctx.ui_root.get_viewport().set_input_as_handled()
			_on_draw_pressed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			ctx.ui_root.get_viewport().set_input_as_handled()
			_on_stop_pressed()

func _step_rival_simulation():
	# 全員終了している場合は何も行わない
	var all_done = true
	for r_name in rival_sim_states:
		if rival_sim_states[r_name]["status"] == "active":
			all_done = false
			break
	if all_done:
		return

	var active_rivals = []
	for r_name in rival_sim_states:
		if rival_sim_states[r_name]["status"] == "active":
			active_rivals.append(r_name)
	
	if active_rivals.is_empty(): return
	
	# シャッフルしてランダムな相手を選ぶ
	active_rivals.shuffle()
	
	# 同時に行動するのは最大2人
	var action_count = randi() % 2 + 1
	action_count = min(action_count, active_rivals.size())
	
	for i in range(action_count):
		var r_name = active_rivals[i]
		var state = rival_sim_states[r_name]
		var draw_prob = 0.8
		var style = state["style"]
		
		# スタイルに応じた行動確率
		if style == "safe":
			if state["cards"] >= 3: draw_prob = 0.15
			elif state["cards"] >= 2: draw_prob = 0.45
		elif style == "gambler":
			if state["cards"] >= 5: draw_prob = 0.2
			elif state["cards"] >= 3: draw_prob = 0.75
		else:
			if state["cards"] >= 4: draw_prob = 0.1
			elif state["cards"] >= 3: draw_prob = 0.35
			elif state["cards"] >= 2: draw_prob = 0.65
			
		var r_val = randf()
		if r_val < draw_prob:
			# ドロー！
			state["cards"] += 1
			var add_score = randi_range(6, 12)
			state["score"] += add_score
			
			# バースト確率チェック
			var burst_prob = 0.0
			if state["cards"] >= 5: burst_prob = 0.6
			elif state["cards"] >= 4: burst_prob = 0.3
			elif state["cards"] >= 3: burst_prob = 0.1
			
			if randf() < burst_prob:
				state["status"] = "burst"
				var burst_msg = "【ライバル】%s が寝落ちした！(バースト)" % r_name
				ToastOverlayScript.show_toast(ctx.ui_root, burst_msg, DeskTheme.COLOR_BLUFF_RED)
			else:
				var draw_msg = "【ライバル】%s がカードを引いた！\n(計%d枚 / 予測%d点)" % [r_name, state["cards"], state["score"]]
				ToastOverlayScript.show_toast(ctx.ui_root, draw_msg, Color("a5d6a7"))
		else:
			# ストップ
			state["status"] = "stopped"
			var stop_msg = "【ライバル】%s が勉強を切り上げた！\n(報告予測: %d点)" % [r_name, state["score"]]
			ToastOverlayScript.show_toast(ctx.ui_root, stop_msg, Color("90caf9"))
